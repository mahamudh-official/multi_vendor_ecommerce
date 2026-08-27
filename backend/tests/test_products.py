"""
Backend test suite for Product API endpoints.
Covers product creation, ownership authorization, detail lookup, validation,
filtering, searching, sorting, and pagination.
"""
import uuid
from decimal import Decimal
import pytest
from httpx import AsyncClient

from app.modules.auth.models import UserRole
from tests.test_categories import create_test_user


@pytest.fixture
async def sample_category(client: AsyncClient) -> str:
    """Create a sample active category and return its ID."""
    _, admin_token = await create_test_user(UserRole.admin)
    res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Category {uuid.uuid4().hex[:6]}"},
    )
    return res.json()["id"]


@pytest.mark.asyncio
async def test_seller_creates_product(client: AsyncClient, sample_category: str):
    """9. Authenticated seller creates product listing."""
    _, seller_token = await create_test_user(UserRole.seller)

    res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": "Wireless Noise Cancelling Headphones",
            "description": "Premium sound quality",
            "price": "199.99",
            "compare_at_price": "249.99",
            "stock_quantity": 50,
            "sku": f"SKU-{uuid.uuid4().hex[:8]}",
            "category_id": sample_category,
            "image_url": "https://example.com/headphones.jpg",
            "images": ["https://example.com/h1.jpg", "https://example.com/h2.jpg"],
            "is_featured": True,
        },
    )
    assert res.status_code == 201
    data = res.json()
    assert data["name"] == "Wireless Noise Cancelling Headphones"
    assert data["slug"] == "wireless-noise-cancelling-headphones"
    assert float(data["price"]) == 199.99
    assert float(data["compare_at_price"]) == 249.99
    assert data["stock_quantity"] == 50
    assert len(data["images"]) == 2
    assert "seller" in data
    assert "id" in data["seller"]
    assert "full_name" in data["seller"]
    assert "email" not in data["seller"]  # Privacy check


@pytest.mark.asyncio
async def test_customer_cannot_create_product(client: AsyncClient, sample_category: str):
    """10. Customer cannot create a product (403 Forbidden)."""
    _, customer_token = await create_test_user(UserRole.customer)

    res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={
            "name": "Customer Product Attempt",
            "price": "49.99",
            "category_id": sample_category,
        },
    )
    assert res.status_code == 403


@pytest.mark.asyncio
async def test_public_product_list_and_details(client: AsyncClient, sample_category: str):
    """7 & 8. Public product listing and product details."""
    _, seller_token = await create_test_user(UserRole.seller)
    create_res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": "Smart Fitness Watch",
            "description": "Track health and workouts",
            "price": "89.50",
            "stock_quantity": 25,
            "category_id": sample_category,
        },
    )
    product_id = create_res.json()["id"]

    # 7. Public list
    list_res = await client.get("/api/v1/products")
    assert list_res.status_code == 200
    list_data = list_res.json()
    assert "items" in list_data
    assert "total" in list_data
    assert any(p["id"] == product_id for p in list_data["items"])

    # 8. Product details
    detail_res = await client.get(f"/api/v1/products/{product_id}")
    assert detail_res.status_code == 200
    detail_data = detail_res.json()
    assert detail_data["name"] == "Smart Fitness Watch"
    assert detail_data["category"]["id"] == sample_category


@pytest.mark.asyncio
async def test_seller_edits_own_product(client: AsyncClient, sample_category: str):
    """12. Seller can edit their own product."""
    _, seller_token = await create_test_user(UserRole.seller)
    create_res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": "Original Title",
            "price": "30.00",
            "category_id": sample_category,
        },
    )
    product_id = create_res.json()["id"]

    update_res = await client.patch(
        f"/api/v1/products/{product_id}",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": "Updated Title",
            "price": "35.50",
            "stock_quantity": 100,
        },
    )
    assert update_res.status_code == 200
    data = update_res.json()
    assert data["name"] == "Updated Title"
    assert float(data["price"]) == 35.50
    assert data["stock_quantity"] == 100


@pytest.mark.asyncio
async def test_seller_cannot_edit_another_sellers_product(client: AsyncClient, sample_category: str):
    """11. Seller cannot edit a product belonging to another seller (403 Forbidden)."""
    _, seller_1_token = await create_test_user(UserRole.seller)
    _, seller_2_token = await create_test_user(UserRole.seller)

    # Seller 1 creates product
    create_res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_1_token}"},
        json={"name": "Seller 1 Product", "price": "50.00", "category_id": sample_category},
    )
    product_id = create_res.json()["id"]

    # Seller 2 attempts to edit Seller 1's product
    update_res = await client.patch(
        f"/api/v1/products/{product_id}",
        headers={"Authorization": f"Bearer {seller_2_token}"},
        json={"name": "Hacked Title"},
    )
    assert update_res.status_code == 403


@pytest.mark.asyncio
async def test_seller_deactivates_own_product(client: AsyncClient, sample_category: str):
    """13. Seller can deactivate their own product (soft-delete)."""
    _, seller_token = await create_test_user(UserRole.seller)
    create_res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "To Be Deactivated", "price": "20.00", "category_id": sample_category},
    )
    product_id = create_res.json()["id"]

    del_res = await client.delete(
        f"/api/v1/products/{product_id}",
        headers={"Authorization": f"Bearer {seller_token}"},
    )
    assert del_res.status_code == 200

    # Inactive product must not appear in public listing
    list_res = await client.get("/api/v1/products")
    assert not any(p["id"] == product_id for p in list_res.json()["items"])


@pytest.mark.asyncio
async def test_invalid_category(client: AsyncClient):
    """14. Create product with non-existent category fails with 400."""
    _, seller_token = await create_test_user(UserRole.seller)
    fake_cat_id = str(uuid.uuid4())

    res = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={
            "name": "Invalid Category Product",
            "price": "20.00",
            "category_id": fake_cat_id,
        },
    )
    assert res.status_code == 400


@pytest.mark.asyncio
async def test_duplicate_sku(client: AsyncClient, sample_category: str):
    """15. Duplicate SKU returns 409 Conflict."""
    _, seller_token = await create_test_user(UserRole.seller)
    shared_sku = f"UNIQUE-SKU-{uuid.uuid4().hex[:6]}"

    # First product with SKU
    r1 = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "Prod 1", "price": "20.00", "sku": shared_sku, "category_id": sample_category},
    )
    assert r1.status_code == 201

    # Second product with same SKU
    r2 = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "Prod 2", "price": "25.00", "sku": shared_sku, "category_id": sample_category},
    )
    assert r2.status_code == 409


@pytest.mark.asyncio
async def test_invalid_price_and_stock(client: AsyncClient, sample_category: str):
    """16 & 17. Negative/zero price or negative stock returns 422."""
    _, seller_token = await create_test_user(UserRole.seller)

    # 16. Negative price
    res_price = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "Free Product", "price": "0.00", "category_id": sample_category},
    )
    assert res_price.status_code == 422

    # 17. Negative stock
    res_stock = await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "Negative Stock", "price": "10.00", "stock_quantity": -5, "category_id": sample_category},
    )
    assert res_stock.status_code == 422


@pytest.mark.asyncio
async def test_search_filter_sorting_and_pagination(client: AsyncClient, sample_category: str):
    """18, 19, 20, 21, 22. Search, filters, sort, and pagination."""
    _, seller_token = await create_test_user(UserRole.seller)

    # Create distinct products
    await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "Ergonomic Mechanical Keyboard", "price": "120.00", "is_featured": True, "category_id": sample_category},
    )
    await client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "Budget USB Mouse", "price": "15.00", "is_featured": False, "category_id": sample_category},
    )

    # 18. Pagination
    res_page = await client.get("/api/v1/products?page=1&page_size=1")
    assert res_page.status_code == 200
    assert len(res_page.json()["items"]) == 1

    # 19. Search
    res_search = await client.get("/api/v1/products?search=Keyboard")
    assert res_search.status_code == 200
    assert any("Keyboard" in p["name"] for p in res_search.json()["items"])

    # 20. Category filter
    res_cat = await client.get(f"/api/v1/products?category_id={sample_category}")
    assert res_cat.status_code == 200
    assert all(p["category"]["id"] == sample_category for p in res_cat.json()["items"])

    # 21. Price filter (min_price = 100)
    res_price = await client.get("/api/v1/products?min_price=100")
    assert res_price.status_code == 200
    assert all(float(p["price"]) >= 100.0 for p in res_price.json()["items"])

    # 22. Sorting (price_asc)
    res_sort = await client.get("/api/v1/products?sort=price_asc")
    assert res_sort.status_code == 200
    items = res_sort.json()["items"]
    if len(items) >= 2:
        assert float(items[0]["price"]) <= float(items[1]["price"])

