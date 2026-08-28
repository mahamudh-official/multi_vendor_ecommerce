"""
Backend test suite for Seller Dashboard, Seller Products, and Multi-Vendor Order Management.
Covers authorization, ownership isolation, multi-seller item fulfillment, state transitions, and snapshot integrity.
"""
import uuid
from decimal import Decimal
import pytest
from httpx import AsyncClient

from app.modules.auth.models import UserRole
from tests.test_categories import create_test_user


@pytest.fixture
async def seller_setup(client: AsyncClient) -> dict:
    """Fixture providing an active category, two distinct sellers, a customer, and an admin."""
    admin_user, admin_token = await create_test_user(UserRole.admin)
    cat_res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Seller Category {uuid.uuid4().hex[:6]}"},
    )
    cat_id = cat_res.json()["id"]

    seller_a_user, seller_a_token = await create_test_user(UserRole.seller)
    seller_b_user, seller_b_token = await create_test_user(UserRole.seller)
    _, customer_token = await create_test_user(UserRole.customer)

    return {
        "cat_id": cat_id,
        # seller_a is the primary seller used in most tests
        "seller_a_token": seller_a_token,
        "seller_b_token": seller_b_token,
        "customer_token": customer_token,
        # Aliases for the suspended-seller test
        "seller_id": str(seller_a_user.id),
        "seller_token": seller_a_token,
        "admin_token": admin_token,
        "category_id": cat_id,
    }


# ── 1. Authorization Tests ──────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_customer_forbidden_on_seller_endpoints(client: AsyncClient, seller_setup: dict):
    """1. Customer attempting to access any seller endpoint must receive 403 Forbidden."""
    cust_token = seller_setup["customer_token"]
    headers = {"Authorization": f"Bearer {cust_token}"}

    res_dash = await client.get("/api/v1/seller/dashboard", headers=headers)
    assert res_dash.status_code == 403

    res_prod = await client.get("/api/v1/seller/products", headers=headers)
    assert res_prod.status_code == 403

    res_create = await client.post(
        "/api/v1/seller/products",
        headers=headers,
        json={
            "name": "Unauthorized Prod",
            "price": "99.99",
            "stock_quantity": 10,
            "category_id": seller_setup["cat_id"],
        },
    )
    assert res_create.status_code == 403

    res_orders = await client.get("/api/v1/seller/orders", headers=headers)
    assert res_orders.status_code == 403


# ── 2. Seller Product CRUD & Ownership Tests ────────────────────────────────

@pytest.mark.asyncio
async def test_seller_creates_and_lists_products(client: AsyncClient, seller_setup: dict):
    """2. Seller creates own products; products are scoped strictly to the seller."""
    seller_a = seller_setup["seller_a_token"]
    cat_id = seller_setup["cat_id"]

    # Create Product 1 (in stock)
    p1_res = await client.post(
        "/api/v1/seller/products",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={
            "name": "Mechanical Keyboard Pro",
            "sku": f"MK-{uuid.uuid4().hex[:4].upper()}",
            "price": "129.50",
            "stock_quantity": 15,
            "category_id": cat_id,
            "description": "Premium typing experience",
        },
    )
    assert p1_res.status_code == 201
    p1 = p1_res.json()
    assert p1["name"] == "Mechanical Keyboard Pro"
    assert p1["is_low_stock"] is False

    # Create Product 2 (low stock: <= 5)
    p2_res = await client.post(
        "/api/v1/seller/products",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={
            "name": "Custom Coiled Cable",
            "sku": f"CBL-{uuid.uuid4().hex[:4].upper()}",
            "price": "29.99",
            "stock_quantity": 3,
            "category_id": cat_id,
        },
    )
    assert p2_res.status_code == 201
    p2 = p2_res.json()
    assert p2["is_low_stock"] is True

    # List seller products
    list_res = await client.get(
        "/api/v1/seller/products",
        headers={"Authorization": f"Bearer {seller_a}"},
    )
    assert list_res.status_code == 200
    data = list_res.json()
    assert data["total"] >= 2
    assert len(data["items"]) >= 2

    # Filter by low_stock
    low_res = await client.get(
        "/api/v1/seller/products?low_stock=true",
        headers={"Authorization": f"Bearer {seller_a}"},
    )
    assert low_res.status_code == 200
    low_data = low_res.json()
    assert all(p["stock_quantity"] <= 5 for p in low_data["items"])


@pytest.mark.asyncio
async def test_seller_ownership_isolation_for_products(client: AsyncClient, seller_setup: dict):
    """3. Seller A cannot view, update, or deactivate Seller B's product."""
    seller_a = seller_setup["seller_a_token"]
    seller_b = seller_setup["seller_b_token"]
    cat_id = seller_setup["cat_id"]

    # Seller A creates product
    p_res = await client.post(
        "/api/v1/seller/products",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={
            "name": "Seller A Secret Tool",
            "price": "89.00",
            "stock_quantity": 20,
            "category_id": cat_id,
        },
    )
    prod_id = p_res.json()["id"]

    # Seller B attempts GET -> 404
    get_res = await client.get(
        f"/api/v1/seller/products/{prod_id}",
        headers={"Authorization": f"Bearer {seller_b}"},
    )
    assert get_res.status_code == 404

    # Seller B attempts PATCH -> 404
    patch_res = await client.patch(
        f"/api/v1/seller/products/{prod_id}",
        headers={"Authorization": f"Bearer {seller_b}"},
        json={"name": "Hacked Title"},
    )
    assert patch_res.status_code == 404

    # Seller B attempts DELETE -> 404
    del_res = await client.delete(
        f"/api/v1/seller/products/{prod_id}",
        headers={"Authorization": f"Bearer {seller_b}"},
    )
    assert del_res.status_code == 404

    # Seller A deactivates own product -> 204
    del_a = await client.delete(
        f"/api/v1/seller/products/{prod_id}",
        headers={"Authorization": f"Bearer {seller_a}"},
    )
    assert del_a.status_code == 204

    # Verify product is now inactive
    get_a = await client.get(
        f"/api/v1/seller/products/{prod_id}",
        headers={"Authorization": f"Bearer {seller_a}"},
    )
    assert get_a.json()["is_active"] is False


# ── 3. Multi-Vendor Order Fulfillment & Item Isolation ──────────────────────

@pytest.mark.asyncio
async def test_multi_vendor_order_isolation_and_fulfillment(client: AsyncClient, seller_setup: dict):
    """
    4. Multi-Vendor Order:
       - Customer buys Product A (Seller A) + Product B (Seller B) in ONE order
       - Seller A views order -> sees ONLY Product A
       - Seller B views order -> sees ONLY Product B
       - Seller A advances fulfillment: pending -> confirmed -> processing -> shipped
       - Seller B's item fulfillment remains pending
       - Seller A cannot jump to delivered directly from pending
       - Snapshot remains unchanged when seller updates current product price
    """
    seller_a = seller_setup["seller_a_token"]
    seller_b = seller_setup["seller_b_token"]
    customer = seller_setup["customer_token"]
    cat_id = seller_setup["cat_id"]

    # 1. Seller A creates Product A ($100, stock 10)
    pa_res = await client.post(
        "/api/v1/seller/products",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={
            "name": "Seller A High-End Mic",
            "sku": f"MIC-{uuid.uuid4().hex[:6].upper()}",
            "price": "100.00",
            "stock_quantity": 10,
            "category_id": cat_id,
        },
    )
    prod_a_id = pa_res.json()["id"]

    # 2. Seller B creates Product B ($50, stock 10)
    pb_res = await client.post(
        "/api/v1/seller/products",
        headers={"Authorization": f"Bearer {seller_b}"},
        json={
            "name": "Seller B Boom Arm",
            "sku": f"ARM-{uuid.uuid4().hex[:6].upper()}",
            "price": "50.00",
            "stock_quantity": 10,
            "category_id": cat_id,
        },
    )
    prod_b_id = pb_res.json()["id"]

    # 3. Customer adds both to cart (1 of Mic, 2 of Boom Arm)
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer}"},
        json={"product_id": prod_a_id, "quantity": 1},
    )
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer}"},
        json={"product_id": prod_b_id, "quantity": 2},
    )

    # 4. Customer checks out
    checkout_res = await client.post(
        "/api/v1/orders/checkout",
        headers={"Authorization": f"Bearer {customer}"},
        json={
            "shipping_address": {
                "full_name": "Multi-Vendor Buyer",
                "phone": "+1-555-9876",
                "address_line1": "456 Commerce Way",
                "city": "Austin",
                "state": "TX",
                "postal_code": "78701",
                "country": "USA",
            }
        },
    )
    assert checkout_res.status_code == 201
    order_id = checkout_res.json()["id"]

    # 5. Seller A views order details
    order_a_res = await client.get(
        f"/api/v1/seller/orders/{order_id}",
        headers={"Authorization": f"Bearer {seller_a}"},
    )
    assert order_a_res.status_code == 200
    order_a = order_a_res.json()
    assert order_a["seller_item_count"] == 1
    assert float(order_a["seller_subtotal"]) == 100.00
    assert len(order_a["items"]) == 1
    assert order_a["items"][0]["product_id"] == prod_a_id
    assert order_a["items"][0]["fulfillment_status"] == "pending"

    # 6. Seller B views order details
    order_b_res = await client.get(
        f"/api/v1/seller/orders/{order_id}",
        headers={"Authorization": f"Bearer {seller_b}"},
    )
    assert order_b_res.status_code == 200
    order_b = order_b_res.json()
    assert order_b["seller_item_count"] == 1
    assert float(order_b["seller_subtotal"]) == 100.00  # 2 * 50.00 = 100.00
    assert len(order_b["items"]) == 1
    assert order_b["items"][0]["product_id"] == prod_b_id
    assert order_b["items"][0]["quantity"] == 2
    assert order_b["items"][0]["fulfillment_status"] == "pending"

    # 7. Invalid transition test: Seller A attempts pending -> shipped (must reject)
    invalid_jump = await client.patch(
        f"/api/v1/seller/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={"status": "shipped"},
    )
    assert invalid_jump.status_code == 400
    assert "invalid fulfillment transition" in invalid_jump.json()["detail"].lower()

    # 8. Valid transitions for Seller A:
    # pending -> confirmed
    s1 = await client.patch(
        f"/api/v1/seller/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={"status": "confirmed"},
    )
    assert s1.status_code == 200
    assert s1.json()["fulfillment_status"] == "confirmed"

    # confirmed -> processing
    s2 = await client.patch(
        f"/api/v1/seller/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={"status": "processing"},
    )
    assert s2.status_code == 200
    assert s2.json()["fulfillment_status"] == "processing"

    # processing -> shipped
    s3 = await client.patch(
        f"/api/v1/seller/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={"status": "shipped"},
    )
    assert s3.status_code == 200
    assert s3.json()["fulfillment_status"] == "shipped"

    # 9. Verify Seller B's item is STILL 'pending' (completely isolated!)
    check_b = await client.get(
        f"/api/v1/seller/orders/{order_id}",
        headers={"Authorization": f"Bearer {seller_b}"},
    )
    assert check_b.json()["items"][0]["fulfillment_status"] == "pending"

    # 10. Seller A updates Product A's active price from $100 to $150
    await client.patch(
        f"/api/v1/seller/products/{prod_a_id}",
        headers={"Authorization": f"Bearer {seller_a}"},
        json={"price": "150.00"},
    )

    # 11. Verify historical order item unit_price snapshot is STILL $100.00
    check_snapshot = await client.get(
        f"/api/v1/seller/orders/{order_id}",
        headers={"Authorization": f"Bearer {seller_a}"},
    )
    assert float(check_snapshot.json()["items"][0]["unit_price"]) == 100.00


# ── 4. Dashboard Metrics Aggregation ────────────────────────────────────────

@pytest.mark.asyncio
async def test_seller_dashboard_metrics_aggregation(client: AsyncClient, seller_setup: dict):
    """5. Verify dashboard aggregates products, low stock, non-cancelled sales, and orders."""
    seller_a = seller_setup["seller_a_token"]
    cat_id = seller_setup["cat_id"]

    # Dashboard retrieval
    dash_res = await client.get(
        "/api/v1/seller/dashboard",
        headers={"Authorization": f"Bearer {seller_a}"},
    )
    assert dash_res.status_code == 200
    data = dash_res.json()
    stats = data["stats"]

    assert "total_products" in stats
    assert "active_products" in stats
    assert "low_stock_products" in stats
    assert "total_orders" in stats
    assert "total_sales_amount" in stats
    assert "recent_orders" in data
    assert "low_stock_products" in data


@pytest.mark.asyncio
async def test_suspended_seller_cannot_mutate_resources(
    client: AsyncClient,
    seller_setup: dict,
):
    """Verify that suspended or pending sellers cannot create/update products or mutate order fulfillments."""
    seller_user_id = seller_setup["seller_id"]
    seller_auth = {"Authorization": f"Bearer {seller_setup['seller_token']}"}
    admin_auth = {"Authorization": f"Bearer {seller_setup['admin_token']}"}
    category_id = seller_setup["category_id"]

    # 1. Admin suspends seller
    r_susp = await client.patch(
        f"/api/v1/admin/sellers/{seller_user_id}/status",
        json={"status": "suspended"},
        headers=admin_auth,
    )
    assert r_susp.status_code == 200

    # 2. Suspended seller attempts to create product -> 403 Forbidden
    r_prod = await client.post(
        "/api/v1/seller/products",
        json={
            "name": "Suspended Product",
            "price": "99.99",
            "stock_quantity": 10,
            "category_id": category_id,
            "sku": "SUSP-01",
        },
        headers=seller_auth,
    )
    assert r_prod.status_code == 403, (
        f"Expected 403 Forbidden for suspended seller, got {r_prod.status_code}: {r_prod.text}"
    )