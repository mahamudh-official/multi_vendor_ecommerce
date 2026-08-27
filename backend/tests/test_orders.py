"""
Backend test suite for Order & Checkout API endpoints.
Covers atomic checkout, snapshots, stock safety, idempotency, listing, cancellation, and security.
"""
import uuid
from decimal import Decimal
import pytest
from httpx import AsyncClient

from app.modules.auth.models import UserRole
from tests.test_categories import create_test_user


@pytest.fixture
async def order_setup(client: AsyncClient) -> dict:
    """Helper fixture creating category, seller, product, and customer."""
    _, admin_token = await create_test_user(UserRole.admin)
    cat_res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Orders Category {uuid.uuid4().hex[:6]}"},
    )
    cat_id = cat_res.json()["id"]

    _, seller_token = await create_test_user(UserRole.seller)
    prod_res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": f"Studio Monitor Speaker {uuid.uuid4().hex[:4]}",
            "sku": f"SKU-{uuid.uuid4().hex[:6].upper()}",
            "price": "199.99",
            "stock_quantity": 5,
            "category_id": cat_id,
        },
    )
    prod_data = prod_res.json()

    _, customer_token = await create_test_user(UserRole.customer)

    return {
        "product_id": prod_data["id"],
        "product_name": prod_data["name"],
        "product_sku": prod_data["sku"],
        "price": Decimal("199.99"),
        "stock": 5,
        "seller_token": seller_token,
        "customer_token": customer_token,
    }


VALID_SHIPPING = {
    "full_name": "Jane Doe",
    "phone": "+1-555-0199",
    "address_line1": "123 Market Street",
    "address_line2": "Suite 400",
    "city": "San Francisco",
    "state": "CA",
    "postal_code": "94103",
    "country": "USA",
}


@pytest.mark.asyncio
async def test_empty_cart_checkout_rejected(client: AsyncClient):
    """1. Checkout with an empty cart must return 400 Bad Request."""
    _, customer_token = await create_test_user(UserRole.customer)

    res = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"shipping_address": VALID_SHIPPING},
    )
    assert res.status_code == 400
    assert "cart is empty" in res.json()["detail"].lower()


@pytest.mark.asyncio
async def test_successful_checkout_flow(client: AsyncClient, order_setup: dict):
    """
    2. Successful checkout:
       - creates Order with generated order_number
       - creates OrderItem with immutable snapshot
       - deducts product stock
       - clears cart
       - server calculates totals strictly
    """
    token = order_setup["customer_token"]
    prod_id = order_setup["product_id"]

    # 1. Add 2 items to cart
    add_res = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": prod_id, "quantity": 2},
    )
    assert add_res.status_code == 200

    # 2. Checkout
    checkout_res = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "shipping_address": VALID_SHIPPING,
            "customer_note": "Please leave at front desk.",
            "idempotency_key": f"key-{uuid.uuid4().hex}",
        },
    )
    assert checkout_res.status_code == 201
    order = checkout_res.json()

    assert "id" in order
    assert order["order_number"].startswith("ORD-")
    assert order["status"] == "pending"
    assert order["payment_status"] == "pending"
    assert float(order["subtotal"]) == 399.98
    assert float(order["total_amount"]) == 399.98  # Free shipping over $50
    assert order["shipping_full_name"] == "Jane Doe"
    assert order["customer_note"] == "Please leave at front desk."

    # Verify snapshot in OrderItem
    assert len(order["items"]) == 1
    item = order["items"][0]
    assert item["product_id"] == prod_id
    assert item["product_name"] == order_setup["product_name"]
    assert item["product_sku"] == order_setup["product_sku"]
    assert float(item["unit_price"]) == 199.99
    assert item["quantity"] == 2
    assert float(item["line_total"]) == 399.98

    # 3. Verify stock is reduced from 5 to 3
    prod_res = await client.get(f"/api/v1/products/{prod_id}")
    assert prod_res.json()["stock_quantity"] == 3

    # 4. Verify cart is now empty
    cart_res = await client.get("/api/v1/cart", headers={"Authorization": f"Bearer {token}"})
    assert cart_res.json()["items"] == []
    assert cart_res.json()["item_count"] == 0


@pytest.mark.asyncio
async def test_checkout_idempotency(client: AsyncClient, order_setup: dict):
    """3. Submitting the same idempotency_key returns identical order and does not double-decrement stock."""
    token = order_setup["customer_token"]
    prod_id = order_setup["product_id"]

    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": prod_id, "quantity": 1},
    )

    idempotency_key = f"idempotent-{uuid.uuid4().hex}"

    # First attempt
    res1 = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {token}"},
        json={"shipping_address": VALID_SHIPPING, "idempotency_key": idempotency_key},
    )
    assert res1.status_code == 201
    order1 = res1.json()

    # Second attempt with same idempotency key
    res2 = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {token}"},
        json={"shipping_address": VALID_SHIPPING, "idempotency_key": idempotency_key},
    )
    assert res2.status_code == 201
    order2 = res2.json()

    assert order1["id"] == order2["id"]
    assert order1["order_number"] == order2["order_number"]

    # Verify stock decremented only once (from 5 to 4)
    prod_res = await client.get(f"/api/v1/products/{prod_id}")
    assert prod_res.json()["stock_quantity"] == 4


@pytest.mark.asyncio
async def test_insufficient_stock_rejected_at_checkout(client: AsyncClient, order_setup: dict):
    """4. If stock is depleted before checkout, checkout fails with 400 and rolls back."""
    customer1_token = order_setup["customer_token"]
    _, customer2_token = await create_test_user(UserRole.customer)
    prod_id = order_setup["product_id"]

    # Both customers add 4 items (available stock is 5)
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer1_token}"},
        json={"product_id": prod_id, "quantity": 4},
    )
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer2_token}"},
        json={"product_id": prod_id, "quantity": 4},
    )

    # Customer 1 checks out first -> succeeds (stock becomes 1)
    res1 = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {customer1_token}"},
        json={"shipping_address": VALID_SHIPPING},
    )
    assert res1.status_code == 201

    # Customer 2 attempts checkout (needs 4, only 1 left) -> fails
    res2 = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {customer2_token}"},
        json={"shipping_address": VALID_SHIPPING},
    )
    assert res2.status_code == 400
    assert "not enough stock" in res2.json()["detail"].lower()

    # Verify stock remains 1 (no negative stock!)
    prod_res = await client.get(f"/api/v1/products/{prod_id}")
    assert prod_res.json()["stock_quantity"] == 1


@pytest.mark.asyncio
async def test_customer_list_orders_and_pagination(client: AsyncClient, order_setup: dict):
    """5. Customer can list their own orders with pagination and status filters."""
    token = order_setup["customer_token"]
    prod_id = order_setup["product_id"]

    # Create order 1
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": prod_id, "quantity": 1},
    )
    await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {token}"},
        json={"shipping_address": VALID_SHIPPING},
    )

    # Create order 2
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": prod_id, "quantity": 1},
    )
    await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {token}"},
        json={"shipping_address": VALID_SHIPPING},
    )

    # List orders
    res = await client.get("/api/v1/orders", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    data = res.json()
    assert data["total"] >= 2
    assert len(data["items"]) >= 2
    assert "order_number" in data["items"][0]

    # Filter by status
    pending_res = await client.get(
        "/api/v1/orders?status=pending",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert pending_res.status_code == 200
    assert all(o["status"] == "pending" for o in pending_res.json()["items"])


@pytest.mark.asyncio
async def test_order_details_ownership_enforcement(client: AsyncClient, order_setup: dict):
    """6. A user cannot view another user's order details."""
    token1 = order_setup["customer_token"]
    _, token2 = await create_test_user(UserRole.customer)
    prod_id = order_setup["product_id"]

    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {token1}"},
        json={"product_id": prod_id, "quantity": 1},
    )
    order_res = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {token1}"},
        json={"shipping_address": VALID_SHIPPING},
    )
    order_id = order_res.json()["id"]

    # Owner can view
    owner_res = await client.get(
        f"/api/v1/orders/{order_id}",
        headers={"Authorization": f"Bearer {token1}"},
    )
    assert owner_res.status_code == 200
    assert owner_res.json()["id"] == order_id

    # Another user cannot view (404)
    other_res = await client.get(
        f"/api/v1/orders/{order_id}",
        headers={"Authorization": f"Bearer {token2}"},
    )
    assert other_res.status_code == 404


@pytest.mark.asyncio
async def test_cancel_order_and_restore_stock(client: AsyncClient, order_setup: dict):
    """7. Cancelling a pending order restores inventory stock."""
    token = order_setup["customer_token"]
    prod_id = order_setup["product_id"]

    # Stock starts at 5
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": prod_id, "quantity": 2},
    )
    checkout_res = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {token}"},
        json={"shipping_address": VALID_SHIPPING},
    )
    order_id = checkout_res.json()["id"]

    # Stock is now 3
    prod_res1 = await client.get(f"/api/v1/products/{prod_id}")
    assert prod_res1.json()["stock_quantity"] == 3

    # Cancel order
    cancel_res = await client.post(
        f"/api/v1/orders/{order_id}/cancel",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert cancel_res.status_code == 200
    assert cancel_res.json()["status"] == "cancelled"

    # Stock restored back to 5
    prod_res2 = await client.get(f"/api/v1/products/{prod_id}")
    assert prod_res2.json()["stock_quantity"] == 5

    # Cannot cancel again
    cancel_again = await client.post(
        f"/api/v1/orders/{order_id}/cancel",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert cancel_again.status_code == 400


@pytest.mark.asyncio
async def test_unauthenticated_checkout_rejected(client: AsyncClient):
    """8. Unauthenticated requests must be rejected with 401."""
    res = await client.post(
        "/api/v1/orders/checkout",
        json={"shipping_address": VALID_SHIPPING},
    )
    assert res.status_code == 401

    res_list = await client.get("/api/v1/orders")
    assert res_list.status_code == 401

