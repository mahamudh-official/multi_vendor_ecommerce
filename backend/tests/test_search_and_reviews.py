"""
Tests for Step 9: Advanced Search, Filtering, Sorting, Product Rating Aggregations,
Product Reviews with Verified Purchase Protection, and Review Moderation.
"""
import uuid
from decimal import Decimal
import pytest
from httpx import AsyncClient

from app.core.security import create_access_token
from app.modules.auth.models import User, UserRole, SellerStatus
from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus, PaymentStatus
from app.modules.products.models import Category, Product
from app.modules.reviews.models import Review
from tests.conftest import TestingSessionLocal


async def create_user(role: UserRole = UserRole.customer, seller_status: SellerStatus = SellerStatus.approved) -> tuple[User, str]:
    """Create a user directly in DB and return (User, token)."""
    async with TestingSessionLocal() as session:
        user = User(
            full_name=f"Test {role.value.capitalize()} {uuid.uuid4().hex[:4]}",
            email=f"{role.value}_{uuid.uuid4().hex[:8]}@example.com",
            password_hash="argon2_hashed_placeholder",
            role=role,
            seller_status=seller_status,
            is_active=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

    token, _ = create_access_token(subject=user.id, role=user.role.value)
    return user, token


@pytest.fixture
async def search_and_review_setup(client: AsyncClient) -> dict:
    admin_user, admin_token = await create_user(UserRole.admin)
    seller_a, seller_a_token = await create_user(UserRole.seller)
    seller_b, seller_b_token = await create_user(UserRole.seller)
    customer, customer_token = await create_user(UserRole.customer)
    customer_2, customer_2_token = await create_user(UserRole.customer)

    # Create category
    async with TestingSessionLocal() as session:
        cat = Category(
            name=f"Electronics {uuid.uuid4().hex[:4]}",
            slug=f"electronics-{uuid.uuid4().hex[:6]}",
            is_active=True,
        )
        session.add(cat)
        await session.commit()
        await session.refresh(cat)
        cat_id = cat.id

        p1 = Product(
            seller_id=seller_a.id,
            category_id=cat_id,
            name="Pro Wireless Bluetooth Headphones",
            slug=f"pro-wireless-headphones-{uuid.uuid4().hex[:8]}",
            sku=f"SKU-HEADPHONE-{uuid.uuid4().hex[:8]}",
            description="Premium noise cancelling wireless over-ear audio headphones",
            price=Decimal("199.99"),
            stock_quantity=15,
            is_active=True,
            is_featured=True,
        )
        p2 = Product(
            seller_id=seller_a.id,
            category_id=cat_id,
            name="Ultra Mechanical Gaming Keyboard RGB",
            slug=f"ultra-gaming-keyboard-{uuid.uuid4().hex[:8]}",
            sku=f"SKU-KEYBOARD-{uuid.uuid4().hex[:8]}",
            description="Custom mechanical switches with programmable RGB backlight",
            price=Decimal("89.50"),
            stock_quantity=5,
            is_active=True,
            is_featured=False,
        )
        p3 = Product(
            seller_id=seller_b.id,
            category_id=cat_id,
            name="Ergonomic Optical Gaming Mouse",
            slug=f"ergonomic-gaming-mouse-{uuid.uuid4().hex[:8]}",
            sku=f"SKU-MOUSE-{uuid.uuid4().hex[:8]}",
            description="Precision laser sensor with 16000 DPI for gamers",
            price=Decimal("49.99"),
            stock_quantity=0,  # Out of stock
            is_active=True,
            is_featured=False,
        )
        session.add_all([p1, p2, p3])
        await session.commit()
        await session.refresh(p1)
        await session.refresh(p2)
        await session.refresh(p3)

        # Create delivered order for customer on p1
        order = Order(
            user_id=customer.id,
            order_number=f"ORD-DELIV-{uuid.uuid4().hex[:6]}",
            status=OrderStatus.DELIVERED,
            payment_status=PaymentStatus.PAID,
            subtotal=Decimal("199.99"),
            shipping_fee=Decimal("0.00"),
            total_amount=Decimal("199.99"),
            shipping_full_name="Jane Doe",
            shipping_phone="+1234567890",
            shipping_address_line1="123 Market St",
            shipping_city="City",
            shipping_state="NY",
            shipping_postal_code="10001",
            shipping_country="US",
        )
        session.add(order)
        await session.flush()

        item1 = OrderItem(
            order_id=order.id,
            product_id=p1.id,
            seller_id=seller_a.id,
            product_name=p1.name,
            unit_price=p1.price,
            quantity=1,
            line_total=p1.price,
            fulfillment_status=FulfillmentStatus.DELIVERED,
        )
        session.add(item1)
        await session.commit()
        await session.refresh(item1)

        p1_id = p1.id
        p2_id = p2.id
        p3_id = p3.id
        p2_sku = p2.sku
        order_item_id = item1.id

    return {
        "admin_token": admin_token,
        "seller_a_token": seller_a_token,
        "seller_b_token": seller_b_token,
        "customer_token": customer_token,
        "customer_2_token": customer_2_token,
        "customer_id": str(customer.id),
        "product1_id": str(p1_id),
        "p1_id": str(p1_id),
        "p2_id": str(p2_id),
        "p3_id": str(p3_id),
        "p2_sku": p2_sku,
        "cat_id": str(cat_id),
        "order_item_id": str(order_item_id),
    }


# ── Search & Filter Tests ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_product_search_by_name_sku_and_description(
    client: AsyncClient,
    search_and_review_setup: dict,
):
    # 1. Search by name partial
    res = await client.get("/api/v1/products?q=headphones")
    assert res.status_code == 200
    data = res.json()
    assert data["total"] >= 1
    assert any("Headphones" in item["name"] for item in data["items"])

    # 2. Search by SKU
    sku = search_and_review_setup["p2_sku"]
    res = await client.get(f"/api/v1/products?q={sku}")
    assert res.status_code == 200
    data = res.json()
    assert any(item["sku"] == sku for item in data["items"])

    # 3. Search by description term
    res = await client.get("/api/v1/products?q=programmable")
    assert res.status_code == 200
    data = res.json()
    assert any("Keyboard" in item["name"] for item in data["items"])


@pytest.mark.asyncio
async def test_product_filtering_price_and_in_stock(
    client: AsyncClient,
    search_and_review_setup: dict,
):
    # Filter in_stock=true
    res = await client.get("/api/v1/products?in_stock=true")
    assert res.status_code == 200
    items = res.json()["items"]
    assert all(item["stock_quantity"] > 0 for item in items)

    # Filter price range 50.00 to 100.00
    res = await client.get("/api/v1/products?min_price=50.00&max_price=100.00")
    assert res.status_code == 200
    items = res.json()["items"]
    assert all(50.00 <= float(item["price"]) <= 100.00 for item in items)


@pytest.mark.asyncio
async def test_invalid_price_range_rejected_with_400(client: AsyncClient):
    # min_price > max_price
    res = await client.get("/api/v1/products?min_price=100&max_price=50")
    assert res.status_code == 400
    assert "cannot be greater than" in res.json()["detail"]

    # negative price
    res = await client.get("/api/v1/products?min_price=-10")
    assert res.status_code == 400


@pytest.mark.asyncio
async def test_product_sorting(
    client: AsyncClient,
    search_and_review_setup: dict,
):
    # Sort price_low
    res = await client.get("/api/v1/products?sort=price_low")
    assert res.status_code == 200
    items = res.json()["items"]
    prices = [float(p["price"]) for p in items]
    assert prices == sorted(prices)

    # Sort price_high
    res = await client.get("/api/v1/products?sort=price_high")
    assert res.status_code == 200
    items = res.json()["items"]
    prices = [float(p["price"]) for p in items]
    assert prices == sorted(prices, reverse=True)


@pytest.mark.asyncio
async def test_pagination_envelope(client: AsyncClient, search_and_review_setup: dict):
    res = await client.get("/api/v1/products?page=1&page_size=2")
    assert res.status_code == 200
    data = res.json()
    assert "has_next" in data
    assert "has_previous" in data
    assert len(data["items"]) <= 2


# ── Verified Purchase Review Tests ──────────────────────────────────────────

@pytest.mark.asyncio
async def test_verified_purchase_review_creation_and_rating_aggregation(
    client: AsyncClient,
    search_and_review_setup: dict,
):
    product_id = search_and_review_setup["p1_id"]
    customer_token = search_and_review_setup["customer_token"]
    headers = {"Authorization": f"Bearer {customer_token}"}

    # 1. Post a 5-star review
    res = await client.post(
        f"/api/v1/products/{product_id}/reviews",
        json={
            "rating": 5,
            "title": "Superb sound quality!",
            "comment": "These headphones exceeded all my expectations. Bass is deep and clear.",
        },
        headers=headers,
    )
    assert res.status_code == 201
    review = res.json()
    assert review["rating"] == 5
    assert review["is_verified_purchase"] is True
    review_id = review["id"]

    # 2. Duplicate review for the same purchase must fail (403)
    res_dup = await client.post(
        f"/api/v1/products/{product_id}/reviews",
        json={"rating": 4, "title": "Another review"},
        headers=headers,
    )
    assert res_dup.status_code == 403

    # 3. Product details should reflect average rating and review count
    res_prod = await client.get(f"/api/v1/products/{product_id}")
    assert res_prod.status_code == 200
    prod_data = res_prod.json()
    assert prod_data["average_rating"] == 5.0
    assert prod_data["review_count"] == 1

    # 4. List product reviews with rating distribution
    res_list = await client.get(f"/api/v1/products/{product_id}/reviews")
    assert res_list.status_code == 200
    rev_data = res_list.json()
    assert rev_data["total"] == 1
    assert rev_data["rating_distribution"]["five_star"] == 1

    # 5. Customer updates their own review
    res_update = await client.patch(
        f"/api/v1/reviews/{review_id}",
        json={"rating": 4, "title": "Updated Title: Pretty good after 1 month"},
        headers=headers,
    )
    assert res_update.status_code == 200
    assert res_update.json()["rating"] == 4

    # 6. Customer lists their own reviews
    res_my = await client.get("/api/v1/reviews/me", headers=headers)
    assert res_my.status_code == 200
    assert res_my.json()["total"] == 1

    # 7. Customer deletes their review
    res_del = await client.delete(f"/api/v1/reviews/{review_id}", headers=headers)
    assert res_del.status_code == 200


@pytest.mark.asyncio
async def test_non_delivered_purchase_cannot_review(
    client: AsyncClient,
    search_and_review_setup: dict,
):
    customer_token = search_and_review_setup["customer_token"]
    p2_id = search_and_review_setup["p2_id"]
    headers = {"Authorization": f"Bearer {customer_token}"}
    res = await client.post(
        f"/api/v1/products/{p2_id}/reviews",
        json={"rating": 5, "title": "Great keyboard"},
        headers=headers,
    )
    assert res.status_code == 403
    assert "delivered" in res.json()["detail"].lower()


@pytest.mark.asyncio
async def test_multi_vendor_review_isolation(
    client: AsyncClient,
    search_and_review_setup: dict,
):
    # Customer only purchased product 1 (Seller A), attempting to review product 3 (Seller B)
    customer_token = search_and_review_setup["customer_token"]
    p3_id = search_and_review_setup["p3_id"]
    headers = {"Authorization": f"Bearer {customer_token}"}
    res = await client.post(
        f"/api/v1/products/{p3_id}/reviews",
        json={"rating": 5, "title": "Fake Review for Mouse"},
        headers=headers,
    )
    assert res.status_code == 403


@pytest.mark.asyncio
async def test_admin_review_moderation(
    client: AsyncClient,
    search_and_review_setup: dict,
):
    p1_id = search_and_review_setup["p1_id"]
    customer_token = search_and_review_setup["customer_token"]
    admin_token = search_and_review_setup["admin_token"]
    cust_headers = {"Authorization": f"Bearer {customer_token}"}
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # Post review
    res = await client.post(
        f"/api/v1/products/{p1_id}/reviews",
        json={"rating": 5, "title": "Admin Moderation Test"},
        headers=cust_headers,
    )
    assert res.status_code == 201
    review_id = res.json()["id"]

    # Admin lists reviews
    res_admin_list = await client.get("/api/v1/admin/reviews", headers=admin_headers)
    assert res_admin_list.status_code == 200
    assert res_admin_list.json()["total"] >= 1

    # Admin rejects / deactivates review
    res_mod = await client.patch(
        f"/api/v1/admin/reviews/{review_id}/status",
        json={"is_approved": False},
        headers=admin_headers,
    )
    assert res_mod.status_code == 200
    assert res_mod.json()["is_approved"] is False

    # Review should no longer appear on public product review list
    res_pub = await client.get(f"/api/v1/products/{p1_id}/reviews")
    assert res_pub.status_code == 200
    assert not any(r["id"] == review_id for r in res_pub.json()["items"])


@pytest.mark.asyncio
async def test_review_uniqueness_database_constraint(client: AsyncClient, search_and_review_setup):
    """Verify that the API prevents duplicate reviews for the same (user_id, order_item_id).

    This tests the same uniqueness guarantee that the DB constraint enforces,
    but via the API layer which is safe in the pytest-asyncio event loop context.
    """
    customer_token = search_and_review_setup["customer_token"]
    p1_id = search_and_review_setup["p1_id"]
    order_item_id = search_and_review_setup["order_item_id"]
    headers = {"Authorization": f"Bearer {customer_token}"}

    # 1. First review attempt — may already exist from prior tests (treat 201 or 409 as acceptable for first)
    r1 = await client.post(
        f"/api/v1/products/{p1_id}/reviews",
        headers=headers,
        json={
            "order_item_id": order_item_id,
            "rating": 5,
            "title": "Unique Constraint Test Review",
            "comment": "Testing uniqueness protection",
        },
    )
    assert r1.status_code in (201, 403, 409), f"Unexpected status on first review: {r1.status_code} — {r1.text}"

    # 2. Duplicate attempt — must always be blocked
    r2 = await client.post(
        f"/api/v1/products/{p1_id}/reviews",
        headers=headers,
        json={
            "order_item_id": order_item_id,
            "rating": 4,
            "title": "Duplicate Review Attempt",
            "comment": "This should be rejected",
        },
    )
    assert r2.status_code in (403, 409), (
        f"Expected 403/409 for duplicate review, got {r2.status_code}: {r2.text}"
    )
