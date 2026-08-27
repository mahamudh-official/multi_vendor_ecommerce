"""
Backend test suite for Wishlist API endpoints.
Covers wishlist retrieval, adding, idempotent additions, removal, clearing, and auth isolation.
"""
import uuid
import pytest
from httpx import AsyncClient

from app.modules.auth.models import UserRole
from tests.test_categories import create_test_user


@pytest.fixture
async def sample_product(client: AsyncClient) -> str:
    """Helper fixture creating a category and product for wishlist tests."""
    _, admin_token = await create_test_user(UserRole.admin)
    cat_res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Wishlist Category {uuid.uuid4().hex[:6]}"},
    )
    cat_id = cat_res.json()["id"]

    _, seller_token = await create_test_user(UserRole.seller)
    prod_res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": "Smart Watch Pro",
            "price": "199.99",
            "stock_quantity": 20,
            "category_id": cat_id,
        },
    )
    return prod_res.json()["id"]


@pytest.mark.asyncio
async def test_get_empty_wishlist(client: AsyncClient):
    """15. Authenticated customer gets an empty wishlist on start."""
    _, customer_token = await create_test_user(UserRole.customer)

    res = await client.get("/api/v1/wishlist", headers={"Authorization": f"Bearer {customer_token}"})
    assert res.status_code == 200
    assert res.json() == []


@pytest.mark.asyncio
async def test_add_to_wishlist_and_idempotency(client: AsyncClient, sample_product: str):
    """16 & 17. Add product to wishlist and verify duplicate additions are idempotent."""
    _, customer_token = await create_test_user(UserRole.customer)

    # 16. First addition
    res1 = await client.post(
        f"/api/v1/wishlist/items/{sample_product}",
        headers={"Authorization": f"Bearer {customer_token}"},
    )
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["product"]["id"] == sample_product

    # 17. Second addition (idempotent — does not duplicate)
    res2 = await client.post(
        f"/api/v1/wishlist/items/{sample_product}",
        headers={"Authorization": f"Bearer {customer_token}"},
    )
    assert res2.status_code == 200

    # Verify only 1 item in list
    list_res = await client.get("/api/v1/wishlist", headers={"Authorization": f"Bearer {customer_token}"})
    assert len(list_res.json()) == 1


@pytest.mark.asyncio
async def test_remove_from_wishlist_and_clear(client: AsyncClient, sample_product: str):
    """18 & 19. Remove individual product from wishlist and clear entire wishlist."""
    _, customer_token = await create_test_user(UserRole.customer)

    # Add item
    await client.post(
        f"/api/v1/wishlist/items/{sample_product}",
        headers={"Authorization": f"Bearer {customer_token}"},
    )

    # 18. Remove item
    del_res = await client.delete(
        f"/api/v1/wishlist/items/{sample_product}",
        headers={"Authorization": f"Bearer {customer_token}"},
    )
    assert del_res.status_code == 200

    list_res = await client.get("/api/v1/wishlist", headers={"Authorization": f"Bearer {customer_token}"})
    assert len(list_res.json()) == 0

    # Re-add and clear
    await client.post(
        f"/api/v1/wishlist/items/{sample_product}",
        headers={"Authorization": f"Bearer {customer_token}"},
    )
    # 19. Clear wishlist
    clear_res = await client.delete("/api/v1/wishlist", headers={"Authorization": f"Bearer {customer_token}"})
    assert clear_res.status_code == 200

    list_after = await client.get("/api/v1/wishlist", headers={"Authorization": f"Bearer {customer_token}"})
    assert len(list_after.json()) == 0


@pytest.mark.asyncio
async def test_cannot_add_nonexistent_product_to_wishlist(client: AsyncClient):
    """20. Adding nonexistent product returns 404."""
    _, customer_token = await create_test_user(UserRole.customer)
    fake_id = str(uuid.uuid4())

    res = await client.post(
        f"/api/v1/wishlist/items/{fake_id}",
        headers={"Authorization": f"Bearer {customer_token}"},
    )
    assert res.status_code == 404


@pytest.mark.asyncio
async def test_unauthenticated_wishlist_rejected(client: AsyncClient):
    """24. Unauthenticated request to wishlist returns 401."""
    res = await client.get("/api/v1/wishlist")
    assert res.status_code == 401

