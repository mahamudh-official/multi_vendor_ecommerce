"""
Integration tests for Order History Filtering, Search, and Sorting (Step 10).
"""
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest
from httpx import AsyncClient

from tests.conftest import TestingSessionLocal
from app.core.security import create_access_token
from app.modules.auth.models import User, UserRole
from app.modules.auth.service import hash_password
from app.modules.orders.models import Order, OrderItem, OrderStatus, PaymentStatus


async def create_user(role: UserRole = UserRole.customer) -> tuple[User, str]:
    email = f"order_user_{uuid.uuid4().hex[:8]}@example.com"
    async with TestingSessionLocal() as session:
        user = User(
            id=uuid.uuid4(),
            full_name="Order Filter Customer",
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


@pytest.mark.asyncio
async def test_order_history_status_and_number_filtering(client: AsyncClient):
    customer, token = await create_user(UserRole.customer)
    headers = {"Authorization": f"Bearer {token}"}

    async with TestingSessionLocal() as session:
        # Create 3 orders with different statuses and created_at timestamps
        now = datetime.now(timezone.utc)
        num1 = f"ORD-ALPHA-{uuid.uuid4().hex[:6]}"
        num2 = f"ORD-BETA-{uuid.uuid4().hex[:6]}"
        num3 = f"ORD-GAMMA-{uuid.uuid4().hex[:6]}"
        o1 = Order(
            user_id=customer.id,
            order_number=num1,
            status=OrderStatus.DELIVERED,
            payment_status=PaymentStatus.PAID,
            subtotal=Decimal("100.00"),
            total_amount=Decimal("100.00"),
            shipping_full_name="Customer",
            shipping_phone="+123456789",
            shipping_address_line1="123 St",
            shipping_city="City",
            shipping_state="CA",
            shipping_postal_code="94105",
            shipping_country="US",
            created_at=now - timedelta(days=5),
        )
        o2 = Order(
            user_id=customer.id,
            order_number=num2,
            status=OrderStatus.PENDING,
            payment_status=PaymentStatus.PENDING,
            subtotal=Decimal("50.00"),
            total_amount=Decimal("50.00"),
            shipping_full_name="Customer",
            shipping_phone="+123456789",
            shipping_address_line1="123 St",
            shipping_city="City",
            shipping_state="CA",
            shipping_postal_code="94105",
            shipping_country="US",
            created_at=now - timedelta(days=2),
        )
        o3 = Order(
            user_id=customer.id,
            order_number=num3,
            status=OrderStatus.CANCELLED,
            payment_status=PaymentStatus.FAILED,
            subtotal=Decimal("75.00"),
            total_amount=Decimal("75.00"),
            shipping_full_name="Customer",
            shipping_phone="+123456789",
            shipping_address_line1="123 St",
            shipping_city="City",
            shipping_state="CA",
            shipping_postal_code="94105",
            shipping_country="US",
            created_at=now,
        )
        session.add_all([o1, o2, o3])
        await session.commit()

    # 1. Status filter: DELIVERED
    deliv_res = await client.get("/api/v1/orders?status=delivered", headers=headers)
    assert deliv_res.status_code == 200
    deliv_items = deliv_res.json()["items"]
    assert len(deliv_items) == 1
    assert deliv_items[0]["order_number"] == num1

    # 2. Search by order number: "BETA"
    search_res = await client.get("/api/v1/orders?search=BETA", headers=headers)
    assert search_res.status_code == 200
    search_items = search_res.json()["items"]
    assert len(search_items) == 1
    assert search_items[0]["order_number"] == num2

    # 3. Sort oldest
    sort_res = await client.get("/api/v1/orders?sort=oldest", headers=headers)
    assert sort_res.status_code == 200
    sort_items = sort_res.json()["items"]
    assert len(sort_items) == 3
    assert sort_items[0]["order_number"] == num1  # Oldest first
    assert sort_items[2]["order_number"] == num3  # Newest last

    # 4. Date range filtering (orders from 3 days ago to now)
    from_date_str = (now - timedelta(days=3)).isoformat()
    date_res = await client.get(f"/api/v1/orders?from_date={from_date_str}", headers=headers)
    assert date_res.status_code == 200
    date_items = date_res.json()["items"]
    assert len(date_items) == 2  # o2 and o3
