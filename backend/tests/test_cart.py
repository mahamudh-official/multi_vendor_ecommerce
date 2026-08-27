"""
Backend test suite for Shopping Cart API endpoints.
Covers cart retrieval, add, quantity updates, stock checks, calculations, ownership, and deletions.
"""
import uuid
from decimal import Decimal
import pytest
from httpx import AsyncClient

from app.modules.auth.models import UserRole
from tests.test_categories import create_test_user


@pytest.fixture
async def sample_product(client: AsyncClient) -> dict:
    """Helper fixture providing an active sample category and product."""
    _, admin_token = await create_test_user(UserRole.admin)
    cat_res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Cart Category {uuid.uuid4().hex[:6]}"},
    )
    cat_id = cat_res.json()["id"]

    _, seller_token = await create_test_user(UserRole.seller)
    prod_res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": "Ergonomic Mechanical Keyboard",
            "price": "149.99",
            "stock_quantity": 10,
            "category_id": cat_id,
            "seller_token": seller_token,
        },
    )
    return {
        "id": prod_res.json()["id"],
        "price": Decimal("149.99"),
        "stock": 10,
        "seller_token": seller_token,
    }


@pytest.mark.asyncio
async def test_authenticated_customer_gets_empty_cart(client: AsyncClient):
    """1. Authenticated customer gets an empty cart on first retrieval."""
    _, customer_token = await create_test_user(UserRole.customer)

    res = await client.get("/api/v1/cart", headers={"Authorization": f"Bearer {customer_token}"})
    assert res.status_code == 200
    data = res.json()
    assert "id" in data
    assert data["items"] == []
    assert data["item_count"] == 0
    assert float(data["subtotal"]) == 0.0


@pytest.mark.asyncio
async def test_add_product_and_increase_quantity(client: AsyncClient, sample_product: dict):
    """2 & 3. Adding product to cart and adding same product increases quantity."""
    _, customer_token = await create_test_user(UserRole.customer)

    # 2. Add 2 items
    res1 = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": sample_product["id"], "quantity": 2},
    )
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["item_count"] == 2
    assert len(data1["items"]) == 1
    assert data1["items"][0]["quantity"] == 2
    assert float(data1["items"][0]["line_total"]) == 299.98
    assert float(data1["subtotal"]) == 299.98

    # 3. Add 3 more of the same product -> total 5
    res2 = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": sample_product["id"], "quantity": 3},
    )
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["item_count"] == 5
    assert len(data2["items"]) == 1
    assert data2["items"][0]["quantity"] == 5
    assert float(data2["subtotal"]) == round(149.99 * 5, 2)


@pytest.mark.asyncio
async def test_update_cart_item_quantity(client: AsyncClient, sample_product: dict):
    """4. Update cart item quantity with stock validation."""
    _, customer_token = await create_test_user(UserRole.customer)

    add_res = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": sample_product["id"], "quantity": 1},
    )
    item_id = add_res.json()["items"][0]["id"]

    # Update to 4
    update_res = await client.patch(
        f"/api/v1/cart/items/{item_id}",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"quantity": 4},
    )
    assert update_res.status_code == 200
    assert update_res.json()["items"][0]["quantity"] == 4
    assert update_res.json()["item_count"] == 4


@pytest.mark.asyncio
async def test_remove_item_and_clear_cart(client: AsyncClient, sample_product: dict):
    """5 & 6. Remove individual cart item and clear cart completely."""
    _, customer_token = await create_test_user(UserRole.customer)

    # Add item
    add_res = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": sample_product["id"], "quantity": 2},
    )
    item_id = add_res.json()["items"][0]["id"]

    # 5. Remove item
    del_res = await client.delete(
        f"/api/v1/cart/items/{item_id}",
        headers={"Authorization": f"Bearer {customer_token}"},
    )
    assert del_res.status_code == 200
    assert del_res.json()["items"] == []
    assert del_res.json()["item_count"] == 0

    # Re-add and clear
    await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": sample_product["id"], "quantity": 3},
    )
    # 6. Clear cart
    clear_res = await client.delete("/api/v1/cart", headers={"Authorization": f"Bearer {customer_token}"})
    assert clear_res.status_code == 200
    assert clear_res.json()["items"] == []


@pytest.mark.asyncio
async def test_cannot_add_inactive_or_nonexistent_product(client: AsyncClient, sample_product: dict):
    """7 & 8. Cannot add inactive or nonexistent products to cart."""
    _, customer_token = await create_test_user(UserRole.customer)

    # 8. Nonexistent product
    fake_id = str(uuid.uuid4())
    res_fake = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": fake_id, "quantity": 1},
    )
    assert res_fake.status_code == 404

    # 7. Inactive product (deactivate product first)
    await client.delete(
        f"/api/v1/products/{sample_product['id']}",
        headers={"Authorization": f"Bearer {sample_product['seller_token']}"},
    )
    res_inactive = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": sample_product["id"], "quantity": 1},
    )
    assert res_inactive.status_code == 400


@pytest.mark.asyncio
async def test_cannot_exceed_stock(client: AsyncClient, sample_product: dict):
    """9. Requested quantity cannot exceed available stock."""
    _, customer_token = await create_test_user(UserRole.customer)

    # Stock is 10, request 15
    res = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"product_id": sample_product["id"], "quantity": 15},
    )
    assert res.status_code == 400


@pytest.mark.asyncio
async def test_cannot_modify_another_users_cart_item(client: AsyncClient, sample_product: dict):
    """10. Customer cannot modify/delete another customer's cart item."""
    _, cust1_token = await create_test_user(UserRole.customer)
    _, cust2_token = await create_test_user(UserRole.customer)

    # Cust 1 adds item
    add_res = await client.post(
        "/api/v1/cart/items",
        headers={"Authorization": f"Bearer {cust1_token}"},
        json={"product_id": sample_product["id"], "quantity": 1},
    )
    item_id = add_res.json()["items"][0]["id"]

    # Cust 2 tries to delete Cust 1's item
    del_res = await client.delete(
        f"/api/v1/cart/items/{item_id}",
        headers={"Authorization": f"Bearer {cust2_token}"},
    )
    assert del_res.status_code == 404


@pytest.mark.asyncio
async def test_unauthenticated_cart_rejected(client: AsyncClient):
    """23. Unauthenticated request to cart endpoints returns 401."""
    res = await client.get("/api/v1/cart")
    assert res.status_code == 401

