"""
Integration tests for Seller Analytics & Multi-Vendor Metric Isolation (Step 10).
"""
import uuid
from decimal import Decimal

import pytest
from httpx import AsyncClient

from tests.conftest import TestingSessionLocal
from app.core.security import create_access_token
from app.modules.auth.models import User, UserRole
from app.modules.auth.service import hash_password
from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus, PaymentStatus
from app.modules.products.models import Category, Product


async def create_user(role: UserRole = UserRole.seller) -> tuple[User, str]:
    email = f"seller_{uuid.uuid4().hex[:8]}@example.com"
    async with TestingSessionLocal() as session:
        user = User(
            id=uuid.uuid4(),
            full_name="Analytics Seller",
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


@pytest.fixture
async def analytics_setup() -> dict:
    seller_a, token_a = await create_user(UserRole.seller)
    seller_b, token_b = await create_user(UserRole.seller)
    customer, cust_token = await create_user(UserRole.customer)

    async with TestingSessionLocal() as session:
        cat = Category(
            name=f"Electronics {uuid.uuid4().hex[:6]}",
            slug=f"elec-{uuid.uuid4().hex[:8]}",
            is_active=True,
        )
        session.add(cat)
        await session.commit()
        await session.refresh(cat)

        # Seller A product
        p_a = Product(
            seller_id=seller_a.id,
            category_id=cat.id,
            name="Seller A Premium Camera",
            slug=f"seller-a-cam-{uuid.uuid4().hex[:8]}",
            sku=f"SKU-CAM-A-{uuid.uuid4().hex[:8]}",
            price=Decimal("500.00"),
            stock_quantity=5,
            is_active=True,
        )
        # Seller B product
        p_b = Product(
            seller_id=seller_b.id,
            category_id=cat.id,
            name="Seller B Lens Kit",
            slug=f"seller-b-lens-{uuid.uuid4().hex[:8]}",
            sku=f"SKU-LENS-B-{uuid.uuid4().hex[:8]}",
            price=Decimal("250.00"),
            stock_quantity=20,
            is_active=True,
        )
        session.add_all([p_a, p_b])
        await session.commit()
        await session.refresh(p_a)
        await session.refresh(p_b)

        # Valid paid order for Seller A ($500 x 2 = $1000)
        order_paid = Order(
            user_id=customer.id,
            order_number=f"ORD-PAID-{uuid.uuid4().hex[:6]}",
            status=OrderStatus.CONFIRMED,
            payment_status=PaymentStatus.PAID,
            subtotal=Decimal("1000.00"),
            total_amount=Decimal("1000.00"),
            shipping_full_name="Customer",
            shipping_phone="+123456789",
            shipping_address_line1="123 St",
            shipping_city="City",
            shipping_state="CA",
            shipping_postal_code="94105",
            shipping_country="US",
        )
        session.add(order_paid)
        await session.flush()

        item_a1 = OrderItem(
            order_id=order_paid.id,
            product_id=p_a.id,
            seller_id=seller_a.id,
            product_name=p_a.name,
            product_sku=p_a.sku,
            unit_price=Decimal("500.00"),
            quantity=2,
            line_total=Decimal("1000.00"),
            fulfillment_status=FulfillmentStatus.CONFIRMED,
        )
        session.add(item_a1)

        # Cancelled order for Seller A ($500) -> MUST NOT COUNT in revenue
        order_cancelled = Order(
            user_id=customer.id,
            order_number=f"ORD-CANC-{uuid.uuid4().hex[:6]}",
            status=OrderStatus.CANCELLED,
            payment_status=PaymentStatus.FAILED,
            subtotal=Decimal("500.00"),
            total_amount=Decimal("500.00"),
            shipping_full_name="Customer",
            shipping_phone="+123456789",
            shipping_address_line1="123 St",
            shipping_city="City",
            shipping_state="CA",
            shipping_postal_code="94105",
            shipping_country="US",
        )
        session.add(order_cancelled)
        await session.flush()

        item_a2 = OrderItem(
            order_id=order_cancelled.id,
            product_id=p_a.id,
            seller_id=seller_a.id,
            product_name=p_a.name,
            product_sku=p_a.sku,
            unit_price=Decimal("500.00"),
            quantity=1,
            line_total=Decimal("500.00"),
            fulfillment_status=FulfillmentStatus.CANCELLED,
        )
        session.add(item_a2)

        # Paid order for Seller B ($250 x 3 = $750)
        order_b = Order(
            user_id=customer.id,
            order_number=f"ORD-B-{uuid.uuid4().hex[:6]}",
            status=OrderStatus.DELIVERED,
            payment_status=PaymentStatus.PAID,
            subtotal=Decimal("750.00"),
            total_amount=Decimal("750.00"),
            shipping_full_name="Customer",
            shipping_phone="+123456789",
            shipping_address_line1="123 St",
            shipping_city="City",
            shipping_state="CA",
            shipping_postal_code="94105",
            shipping_country="US",
        )
        session.add(order_b)
        await session.flush()

        item_b = OrderItem(
            order_id=order_b.id,
            product_id=p_b.id,
            seller_id=seller_b.id,
            product_name=p_b.name,
            product_sku=p_b.sku,
            unit_price=Decimal("250.00"),
            quantity=3,
            line_total=Decimal("750.00"),
            fulfillment_status=FulfillmentStatus.DELIVERED,
        )
        session.add(item_b)

        await session.commit()

    return {
        "seller_a": seller_a,
        "token_a": token_a,
        "seller_b": seller_b,
        "token_b": token_b,
        "cust_token": cust_token,
    }


@pytest.mark.asyncio
async def test_seller_analytics_overview_and_multi_vendor_isolation(
    client: AsyncClient, analytics_setup: dict
):
    token_a = analytics_setup["token_a"]
    token_b = analytics_setup["token_b"]
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # 1. Check Seller A Overview
    res_a = await client.get("/api/v1/seller/analytics/overview", headers=headers_a)
    assert res_a.status_code == 200
    data_a = res_a.json()
    assert Decimal(str(data_a["total_revenue"])) == Decimal("1000.00")
    assert data_a["total_orders"] == 1
    assert data_a["total_items_sold"] == 2
    assert Decimal(str(data_a["average_order_value"])) == Decimal("1000.00")
    assert data_a["pending_fulfillment_count"] == 1
    assert data_a["delivered_order_count"] == 0

    # 2. Check Seller B Overview (Strictly isolated from Seller A)
    res_b = await client.get("/api/v1/seller/analytics/overview", headers=headers_b)
    assert res_b.status_code == 200
    data_b = res_b.json()
    assert Decimal(str(data_b["total_revenue"])) == Decimal("750.00")
    assert data_b["total_orders"] == 1
    assert data_b["total_items_sold"] == 3
    assert Decimal(str(data_b["average_order_value"])) == Decimal("750.00")
    assert data_b["delivered_order_count"] == 1


@pytest.mark.asyncio
async def test_seller_sales_timeline_analytics(
    client: AsyncClient, analytics_setup: dict
):
    headers_a = {"Authorization": f"Bearer {analytics_setup['token_a']}"}

    # Daily aggregation
    res_daily = await client.get("/api/v1/seller/analytics/sales?period=daily", headers=headers_a)
    assert res_daily.status_code == 200
    daily_data = res_daily.json()
    assert daily_data["period_type"] == "daily"
    assert len(daily_data["items"]) >= 1
    assert Decimal(str(daily_data["items"][0]["revenue"])) == Decimal("1000.00")

    # Monthly aggregation
    res_monthly = await client.get("/api/v1/seller/analytics/sales?period=monthly", headers=headers_a)
    assert res_monthly.status_code == 200
    assert res_monthly.json()["period_type"] == "monthly"

    # Invalid period rejected
    res_inv = await client.get("/api/v1/seller/analytics/sales?period=hourly", headers=headers_a)
    assert res_inv.status_code == 400


@pytest.mark.asyncio
async def test_seller_product_analytics_ranking(
    client: AsyncClient, analytics_setup: dict
):
    headers_a = {"Authorization": f"Bearer {analytics_setup['token_a']}"}

    res = await client.get("/api/v1/seller/analytics/products?limit=5", headers=headers_a)
    assert res.status_code == 200
    prods = res.json()["items"]
    assert len(prods) == 1
    assert prods[0]["product_name"] == "Seller A Premium Camera"
    assert Decimal(str(prods[0]["revenue"])) == Decimal("1000.00")
    assert prods[0]["quantity_sold"] == 2


@pytest.mark.asyncio
async def test_customer_cannot_access_seller_analytics(
    client: AsyncClient, analytics_setup: dict
):
    cust_headers = {"Authorization": f"Bearer {analytics_setup['cust_token']}"}

    res = await client.get("/api/v1/seller/analytics/overview", headers=cust_headers)
    assert res.status_code == 403
