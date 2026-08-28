"""
Integration tests for Customer Profile and Delivery Address Management (Step 10).
"""
import uuid
from decimal import Decimal

import pytest
from httpx import AsyncClient

from tests.conftest import TestingSessionLocal
from app.core.security import create_access_token
from app.modules.auth.models import User, UserRole
from app.modules.auth.service import hash_password
from app.modules.orders.models import Order, OrderItem, OrderStatus, PaymentStatus
from app.modules.products.models import Category, Product


async def create_user(role: UserRole = UserRole.customer) -> tuple[User, str]:
    email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    async with TestingSessionLocal() as session:
        user = User(
            id=uuid.uuid4(),
            full_name="Test User",
            email=email,
            password_hash=hash_password("Password123!"),
            role=role,
            is_active=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

    token, _ = create_access_token(subject=user.id, role=user.role.value)
    return user, token


# ── Profile Tests ────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_and_update_profile(client: AsyncClient):
    user, token = await create_user(UserRole.customer)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Get profile
    get_res = await client.get("/api/v1/profile", headers=headers)
    assert get_res.status_code == 200
    profile = get_res.json()
    assert profile["email"] == user.email
    assert profile["full_name"] == "Test User"
    assert profile["role"] == "customer"

    # 2. Update allowed fields
    patch_res = await client.patch(
        "/api/v1/profile",
        json={
            "full_name": "Updated Full Name",
            "phone": "+14155551234",
            "avatar_url": "https://example.com/avatar.jpg",
        },
        headers=headers,
    )
    assert patch_res.status_code == 200
    updated = patch_res.json()
    assert updated["full_name"] == "Updated Full Name"
    assert updated["phone"] == "+14155551234"
    assert updated["avatar_url"] == "https://example.com/avatar.jpg"


@pytest.mark.asyncio
async def test_profile_rejects_privileged_field_modifications(client: AsyncClient):
    user, token = await create_user(UserRole.customer)
    headers = {"Authorization": f"Bearer {token}"}

    # Extra/privileged fields are forbidden by extra="forbid"
    patch_res = await client.patch(
        "/api/v1/profile",
        json={
            "role": "admin",
            "is_active": False,
            "email": "hacked@example.com",
            "seller_status": "approved",
        },
        headers=headers,
    )
    assert patch_res.status_code == 422  # Extra fields forbidden


# ── Address Tests ────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_address_lifecycle_and_default_switching(client: AsyncClient):
    user, token = await create_user(UserRole.customer)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create first address -> automatically default
    addr1_res = await client.post(
        "/api/v1/addresses",
        json={
            "full_name": "Jane Doe",
            "phone": "+14155551001",
            "address_line_1": "100 Market St",
            "city": "San Francisco",
            "state": "CA",
            "postal_code": "94105",
            "country": "US",
        },
        headers=headers,
    )
    assert addr1_res.status_code == 201
    addr1 = addr1_res.json()
    assert addr1["is_default"] is True
    addr1_id = addr1["id"]

    # 2. Create second address without is_default -> is_default is False
    addr2_res = await client.post(
        "/api/v1/addresses",
        json={
            "full_name": "Jane Doe Work",
            "phone": "+14155551002",
            "address_line_1": "500 Howard St",
            "city": "San Francisco",
            "state": "CA",
            "postal_code": "94105",
            "country": "US",
            "is_default": False,
        },
        headers=headers,
    )
    assert addr2_res.status_code == 201
    addr2 = addr2_res.json()
    assert addr2["is_default"] is False
    addr2_id = addr2["id"]

    # 3. List addresses -> contains 2 addresses, addr1 is default
    list_res = await client.get("/api/v1/addresses", headers=headers)
    assert list_res.status_code == 200
    items = list_res.json()["items"]
    assert len(items) == 2
    assert items[0]["id"] == addr1_id
    assert items[0]["is_default"] is True

    # 4. Set second address as default -> atomically removes default from first
    def_res = await client.patch(f"/api/v1/addresses/{addr2_id}/default", headers=headers)
    assert def_res.status_code == 200
    assert def_res.json()["is_default"] is True

    # Verify first address is now NOT default
    addr1_check = await client.get(f"/api/v1/addresses/{addr1_id}", headers=headers)
    assert addr1_check.json()["is_default"] is False

    # 5. Update address details
    patch_res = await client.patch(
        f"/api/v1/addresses/{addr1_id}",
        json={"address_line_2": "Suite 400"},
        headers=headers,
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["address_line_2"] == "Suite 400"

    # 6. Delete default address -> promotes remaining address to default
    del_res = await client.delete(f"/api/v1/addresses/{addr2_id}", headers=headers)
    assert del_res.status_code == 204

    # Verify addr1 is promoted back to default
    addr1_promoted = await client.get(f"/api/v1/addresses/{addr1_id}", headers=headers)
    assert addr1_promoted.json()["is_default"] is True


@pytest.mark.asyncio
async def test_cross_user_address_isolation(client: AsyncClient):
    user_a, token_a = await create_user(UserRole.customer)
    user_b, token_b = await create_user(UserRole.customer)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User A creates an address
    create_res = await client.post(
        "/api/v1/addresses",
        json={
            "full_name": "User A",
            "phone": "+14155550000",
            "address_line_1": "111 Private Lane",
            "city": "Oakland",
            "state": "CA",
            "postal_code": "94601",
            "country": "US",
        },
        headers=headers_a,
    )
    assert create_res.status_code == 201
    addr_id = create_res.json()["id"]

    # User B cannot access User A's address (404 Not Found)
    get_res = await client.get(f"/api/v1/addresses/{addr_id}", headers=headers_b)
    assert get_res.status_code == 404

    # User B cannot update User A's address
    patch_res = await client.patch(
        f"/api/v1/addresses/{addr_id}",
        json={"full_name": "Attacker"},
        headers=headers_b,
    )
    assert patch_res.status_code == 404

    # User B cannot delete User A's address
    del_res = await client.delete(f"/api/v1/addresses/{addr_id}", headers=headers_b)
    assert del_res.status_code == 404


@pytest.mark.asyncio
async def test_historical_order_shipping_snapshot_immutability(client: AsyncClient):
    customer, cust_token = await create_user(UserRole.customer)
    seller, seller_token = await create_user(UserRole.seller)
    cust_headers = {"Authorization": f"Bearer {cust_token}"}

    # 1. Create product and category
    async with TestingSessionLocal() as session:
        cat = Category(
            name=f"Home {uuid.uuid4().hex[:6]}",
            slug=f"home-{uuid.uuid4().hex[:8]}",
            is_active=True,
        )
        session.add(cat)
        await session.commit()
        await session.refresh(cat)

        prod = Product(
            seller_id=seller.id,
            category_id=cat.id,
            name="Smart Lamp",
            slug=f"smart-lamp-{uuid.uuid4().hex[:8]}",
            sku=f"SKU-LAMP-{uuid.uuid4().hex[:8]}",
            price=Decimal("45.00"),
            stock_quantity=10,
            is_active=True,
        )
        session.add(prod)
        await session.commit()
        await session.refresh(prod)
        prod_id = prod.id

    # 2. Customer saves an address
    addr_res = await client.post(
        "/api/v1/addresses",
        json={
            "full_name": "Original Recipient",
            "phone": "+15551234567",
            "address_line_1": "100 Original St",
            "city": "Original City",
            "state": "CA",
            "postal_code": "90001",
            "country": "US",
        },
        headers=cust_headers,
    )
    assert addr_res.status_code == 201
    addr_id = addr_res.json()["id"]

    # 3. Add to cart & checkout copying address
    await client.post(
        "/api/v1/cart/items",
        json={"product_id": str(prod_id), "quantity": 1},
        headers=cust_headers,
    )

    checkout_res = await client.post(
        "/api/v1/orders/checkout",
        json={
            "shipping_address": {
                "full_name": "Original Recipient",
                "phone": "+15551234567",
                "address_line1": "100 Original St",
                "city": "Original City",
                "state": "CA",
                "postal_code": "90001",
                "country": "US",
            }
        },
        headers=cust_headers,
    )
    assert checkout_res.status_code == 201
    order_id = checkout_res.json()["id"]
    assert checkout_res.json()["shipping_address_line1"] == "100 Original St"

    # 4. Customer mutates saved address later
    await client.patch(
        f"/api/v1/addresses/{addr_id}",
        json={
            "address_line_1": "999 Altered Lane",
            "city": "New City",
        },
        headers=cust_headers,
    )

    # 5. Verify historical order shipping snapshot has NOT changed
    order_res = await client.get(f"/api/v1/orders/{order_id}", headers=cust_headers)
    assert order_res.status_code == 200
    order_data = order_res.json()
    assert order_data["shipping_address_line1"] == "100 Original St"
    assert order_data["shipping_city"] == "Original City"

    # 6. Delete saved address completely
    await client.delete(f"/api/v1/addresses/{addr_id}", headers=cust_headers)

    # Verify historical order remains intact and accessible
    order_res_2 = await client.get(f"/api/v1/orders/{order_id}", headers=cust_headers)
    assert order_res_2.status_code == 200
    assert order_res_2.json()["shipping_address_line1"] == "100 Original St"
