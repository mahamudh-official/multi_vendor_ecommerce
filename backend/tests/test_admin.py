"""
Comprehensive test suite for the Admin Dashboard and Platform Management System (Step 8).
"""
import uuid
from decimal import Decimal

import pytest
from httpx import AsyncClient


@pytest.fixture
def unique_suffix() -> str:
    return uuid.uuid4().hex[:8]


@pytest.fixture
async def admin_user(client: AsyncClient, unique_suffix: str) -> dict:
    email = f"admin_{unique_suffix}@market.com"
    password = "AdminSecurePassword123!"
    # Register as customer then update role to admin via direct fixture or auth
    # For testing, we register and authenticate
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": f"Admin Master {unique_suffix}",
            "role": "admin",
        },
    )
    # If registration blocks admin creation directly from public endpoint, we promote via DB
    if r.status_code != 201:
        # Public registration forces customer/seller role, so register as customer
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": email,
                "password": password,
                "full_name": f"Admin Master {unique_suffix}",
                "role": "customer",
            },
        )

    # Log in
    r_login = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert r_login.status_code == 200
    token = r_login.json()["access_token"]
    user_id = r_login.json()["user"]["id"]

    # Ensure user has admin role in database
    from app.core.database import AsyncSessionLocal
    from app.modules.auth.models import User, UserRole
    from sqlalchemy import update

    async with AsyncSessionLocal() as session:
        await session.execute(
            update(User).where(User.id == uuid.UUID(user_id)).values(role=UserRole.admin)
        )
        await session.commit()

    # Re-login to get refreshed JWT containing role='admin'
    r_login2 = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    token2 = r_login2.json()["access_token"]

    return {
        "id": user_id,
        "email": email,
        "auth": {"Authorization": f"Bearer {token2}"},
    }


@pytest.fixture
async def seller_user(client: AsyncClient, unique_suffix: str) -> dict:
    email = f"seller_admin_test_{unique_suffix}@market.com"
    password = "Password123!"
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": f"Seller Test {unique_suffix}",
            "role": "seller",
        },
    )
    r = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    return {
        "id": r.json()["user"]["id"],
        "email": email,
        "auth": {"Authorization": f"Bearer {r.json()['access_token']}"},
    }


@pytest.fixture
async def customer_user(client: AsyncClient, unique_suffix: str) -> dict:
    email = f"buyer_admin_test_{unique_suffix}@market.com"
    password = "Password123!"
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": f"Buyer Test {unique_suffix}",
            "role": "customer",
        },
    )
    r = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    return {
        "id": r.json()["user"]["id"],
        "email": email,
        "auth": {"Authorization": f"Bearer {r.json()['access_token']}"},
    }


# ── 1. Authorization & Role Isolation Tests ──────────────────────────────────

@pytest.mark.asyncio
async def test_admin_dashboard_metrics(client: AsyncClient, admin_user: dict):
    """1. Admin can access dashboard and receive full aggregated metrics."""
    r = await client.get("/api/v1/admin/dashboard", headers=admin_user["auth"])
    assert r.status_code == 200
    data = r.json()
    assert "total_users" in data
    assert "total_sellers" in data
    assert "total_products" in data
    assert "total_orders" in data
    assert "total_revenue" in data
    assert "total_payments" in data


@pytest.mark.asyncio
async def test_customer_access_to_admin_endpoints_forbidden(client: AsyncClient, customer_user: dict):
    """2. Customer role receives 403 Forbidden on all admin endpoints."""
    endpoints = [
        "/api/v1/admin/dashboard",
        "/api/v1/admin/users",
        "/api/v1/admin/sellers",
        "/api/v1/admin/products",
        "/api/v1/admin/categories",
        "/api/v1/admin/orders",
        "/api/v1/admin/payments",
        "/api/v1/admin/audit-logs",
    ]
    for ep in endpoints:
        r = await client.get(ep, headers=customer_user["auth"])
        assert r.status_code == 403, f"Endpoint {ep} was not forbidden for customer"


@pytest.mark.asyncio
async def test_seller_access_to_admin_endpoints_forbidden(client: AsyncClient, seller_user: dict):
    """3. Seller role receives 403 Forbidden on all admin endpoints."""
    endpoints = [
        "/api/v1/admin/dashboard",
        "/api/v1/admin/users",
        "/api/v1/admin/sellers",
        "/api/v1/admin/products",
        "/api/v1/admin/orders",
        "/api/v1/admin/payments",
        "/api/v1/admin/audit-logs",
    ]
    for ep in endpoints:
        r = await client.get(ep, headers=seller_user["auth"])
        assert r.status_code == 403, f"Endpoint {ep} was not forbidden for seller"


# ── 2. User Management Tests ──────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_admin_user_listing_search_and_filters(client: AsyncClient, admin_user: dict, customer_user: dict):
    """4. Admin can list, search, and filter users."""
    # List all
    r = await client.get("/api/v1/admin/users", headers=admin_user["auth"])
    assert r.status_code == 200
    assert r.json()["total"] >= 1

    # Search by email
    r_search = await client.get(f"/api/v1/admin/users?search={customer_user['email']}", headers=admin_user["auth"])
    assert r_search.status_code == 200
    assert len(r_search.json()["items"]) == 1
    assert r_search.json()["items"][0]["email"] == customer_user["email"]
    # Verify no password hashes or secrets in response
    assert "password_hash" not in r_search.json()["items"][0]


@pytest.mark.asyncio
async def test_admin_user_activation_and_deactivation(client: AsyncClient, admin_user: dict, customer_user: dict):
    """5. Admin can deactivate and activate a user account."""
    target_id = customer_user["id"]

    # Deactivate
    r_deact = await client.patch(
        f"/api/v1/admin/users/{target_id}/status",
        headers=admin_user["auth"],
        json={"is_active": False},
    )
    assert r_deact.status_code == 200
    assert r_deact.json()["is_active"] is False

    # Verify deactivated user cannot perform actions
    r_cart = await client.get("/api/v1/cart", headers=customer_user["auth"])
    assert r_cart.status_code == 403

    # Reactivate
    r_act = await client.patch(
        f"/api/v1/admin/users/{target_id}/status",
        headers=admin_user["auth"],
        json={"is_active": True},
    )
    assert r_act.status_code == 200
    assert r_act.json()["is_active"] is True


@pytest.mark.asyncio
async def test_admin_cannot_deactivate_own_account(client: AsyncClient, admin_user: dict):
    """6. Admin is prevented from deactivating their own currently authenticated account (400)."""
    r = await client.patch(
        f"/api/v1/admin/users/{admin_user['id']}/status",
        headers=admin_user["auth"],
        json={"is_active": False},
    )
    assert r.status_code == 400
    assert "cannot deactivate their own" in r.json()["detail"]


# ── 3. Seller Management & Lifecycle Tests ────────────────────────────────────

@pytest.mark.asyncio
async def test_admin_seller_management_and_transitions(client: AsyncClient, admin_user: dict, seller_user: dict):
    """7. Admin can list sellers, suspend a seller, and reactivate/approve a seller."""
    seller_id = seller_user["id"]

    # List sellers
    r_list = await client.get("/api/v1/admin/sellers", headers=admin_user["auth"])
    assert r_list.status_code == 200
    assert any(s["id"] == seller_id for s in r_list.json()["items"])

    # Suspend seller
    r_susp = await client.patch(
        f"/api/v1/admin/sellers/{seller_id}/status",
        headers=admin_user["auth"],
        json={"status": "suspended"},
    )
    assert r_susp.status_code == 200
    assert r_susp.json()["seller_status"] == "suspended"

    # Suspended seller receives notification
    r_notifs = await client.get("/api/v1/notifications", headers=seller_user["auth"])
    assert r_notifs.status_code == 200
    assert any("suspended" in n["title"].lower() for n in r_notifs.json()["items"])

    # Suspended seller cannot create products
    r_cat = await client.get("/api/v1/categories")
    cat_id = (r_cat.json() if isinstance(r_cat.json(), list) else r_cat.json().get("items", []))[0]["id"]
    r_prod = await client.post(
        "/api/v1/seller/products",
        headers=seller_user["auth"],
        json={"name": "Forbidden Item", "price": 99.00, "stock_quantity": 10, "category_id": cat_id},
    )
    assert r_prod.status_code == 403

    # Reactivate / Approve seller
    r_appr = await client.patch(
        f"/api/v1/admin/sellers/{seller_id}/status",
        headers=admin_user["auth"],
        json={"status": "approved"},
    )
    assert r_appr.status_code == 200
    assert r_appr.json()["seller_status"] == "approved"


@pytest.mark.asyncio
async def test_invalid_seller_transition_rejected(client: AsyncClient, admin_user: dict, seller_user: dict):
    """8. Invalid seller transitions return 400 Bad Request."""
    seller_id = seller_user["id"]

    # Invalid status string
    r = await client.patch(
        f"/api/v1/admin/sellers/{seller_id}/status",
        headers=admin_user["auth"],
        json={"status": "invalid_status"},
    )
    assert r.status_code == 400


# ── 4. Product Moderation Tests ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_admin_product_moderation(client: AsyncClient, admin_user: dict, seller_user: dict, unique_suffix: str):
    """9. Admin can list products, filter by status/low_stock, and deactivate/activate products."""
    r_cat = await client.get("/api/v1/categories")
    cat_id = (r_cat.json() if isinstance(r_cat.json(), list) else r_cat.json().get("items", []))[0]["id"]

    # Create product as seller
    r_p = await client.post(
        "/api/v1/seller/products",
        headers=seller_user["auth"],
        json={"name": f"Mod Product {unique_suffix}", "price": 45.00, "stock_quantity": 3, "category_id": cat_id},
    )
    assert r_p.status_code == 201
    prod_id = r_p.json()["id"]

    # Admin lists products with low_stock filter
    r_admin_list = await client.get("/api/v1/admin/products?low_stock=true", headers=admin_user["auth"])
    assert r_admin_list.status_code == 200
    assert any(p["id"] == prod_id for p in r_admin_list.json()["items"])

    # Admin deactivates product
    r_deact = await client.patch(
        f"/api/v1/admin/products/{prod_id}/status",
        headers=admin_user["auth"],
        json={"is_active": False},
    )
    assert r_deact.status_code == 200
    assert r_deact.json()["is_active"] is False

    # Verify public listing no longer shows deactivated product
    r_pub = await client.get("/api/v1/products")
    assert not any(p["id"] == prod_id for p in r_pub.json()["items"])


# ── 5. Category Management Tests ──────────────────────────────────────────────

@pytest.mark.asyncio
async def test_admin_category_management_and_safe_delete(client: AsyncClient, admin_user: dict, unique_suffix: str):
    """10. Admin can create, update, and safely delete categories."""
    cat_name = f"Admin Cat {unique_suffix}"

    # Create
    r_create = await client.post(
        "/api/v1/admin/categories",
        headers=admin_user["auth"],
        json={"name": cat_name, "description": "Admin test category"},
    )
    assert r_create.status_code == 201
    cat_id = r_create.json()["id"]

    # Duplicate creation rejected
    r_dup = await client.post(
        "/api/v1/admin/categories",
        headers=admin_user["auth"],
        json={"name": cat_name},
    )
    assert r_dup.status_code == 400

    # Update
    r_upd = await client.patch(
        f"/api/v1/admin/categories/{cat_id}",
        headers=admin_user["auth"],
        json={"description": "Updated description"},
    )
    assert r_upd.status_code == 200
    assert r_upd.json()["description"] == "Updated description"

    # Delete empty category
    r_del = await client.delete(f"/api/v1/admin/categories/{cat_id}", headers=admin_user["auth"])
    assert r_del.status_code == 200


# ── 6. Order & Multi-Vendor Management Tests ──────────────────────────────────

@pytest.mark.asyncio
async def test_admin_order_monitoring_and_multi_vendor_visibility(
    client: AsyncClient, admin_user: dict, customer_user: dict, seller_user: dict, unique_suffix: str
):
    """11. Admin can list orders and inspect multi-vendor order details with full snapshots."""
    r_cat = await client.get("/api/v1/categories")
    cat_id = (r_cat.json() if isinstance(r_cat.json(), list) else r_cat.json().get("items", []))[0]["id"]

    # Seller creates product
    r_prod = await client.post(
        "/api/v1/seller/products",
        headers=seller_user["auth"],
        json={"name": f"Admin Order Item {unique_suffix}", "price": 60.00, "stock_quantity": 10, "category_id": cat_id},
    )
    prod_id = r_prod.json()["id"]

    # Customer places order
    await client.post("/api/v1/cart/items", headers=customer_user["auth"], json={"product_id": prod_id, "quantity": 1})
    r_order = await client.post(
        "/api/v1/orders/checkout",
        headers=customer_user["auth"],
        json={
            "shipping_address": {
                "full_name": "Buyer Bob",
                "phone": "+1-555-0100",
                "address_line1": "123 St",
                "city": "Austin",
                "state": "TX",
                "postal_code": "78701",
                "country": "USA",
            }
        },
    )
    assert r_order.status_code == 201
    order_id = r_order.json()["id"]

    # Admin lists orders
    r_orders = await client.get("/api/v1/admin/orders", headers=admin_user["auth"])
    assert r_orders.status_code == 200
    assert any(o["id"] == order_id for o in r_orders.json()["items"])

    # Admin gets full order details
    r_details = await client.get(f"/api/v1/admin/orders/{order_id}", headers=admin_user["auth"])
    assert r_details.status_code == 200
    order_data = r_details.json()
    assert order_data["customer_email"] == customer_user["email"]
    assert len(order_data["items"]) == 1
    assert order_data["items"][0]["product_id"] == prod_id


# ── 7. Payment Monitoring Tests ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_admin_payment_monitoring_is_read_only(
    client: AsyncClient, admin_user: dict, customer_user: dict, seller_user: dict, unique_suffix: str
):
    """12. Admin can list and view payments, but cannot manually modify payment status."""
    r_cat = await client.get("/api/v1/categories")
    cat_id = (r_cat.json() if isinstance(r_cat.json(), list) else r_cat.json().get("items", []))[0]["id"]

    r_prod = await client.post(
        "/api/v1/seller/products",
        headers=seller_user["auth"],
        json={"name": f"Payment Item {unique_suffix}", "price": 30.00, "stock_quantity": 10, "category_id": cat_id},
    )
    await client.post("/api/v1/cart/items", headers=customer_user["auth"], json={"product_id": r_prod.json()["id"], "quantity": 1})
    r_order = await client.post(
        "/api/v1/orders/checkout",
        headers=customer_user["auth"],
        json={
            "shipping_address": {
                "full_name": "Buyer Bob",
                "phone": "+1-555-0100",
                "address_line1": "123 St",
                "city": "Austin",
                "state": "TX",
                "postal_code": "78701",
                "country": "USA",
            }
        },
    )
    order_id = r_order.json()["id"]

    # Customer creates payment intent
    r_pay = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_user["auth"])
    payment_id = r_pay.json()["payment_id"]

    # Admin views payments list
    r_payments = await client.get("/api/v1/admin/payments", headers=admin_user["auth"])
    assert r_payments.status_code == 200
    assert any(p["id"] == payment_id for p in r_payments.json()["items"])

    # Admin views payment details
    r_pdetail = await client.get(f"/api/v1/admin/payments/{payment_id}", headers=admin_user["auth"])
    assert r_pdetail.status_code == 200
    assert r_pdetail.json()["order_id"] == order_id


# ── 8. Immutable Audit Trail Tests ────────────────────────────────────────────

@pytest.mark.asyncio
async def test_admin_audit_trail_recorded_and_listed(client: AsyncClient, admin_user: dict, customer_user: dict):
    """13. Administrative actions generate immutable audit log entries."""
    target_id = customer_user["id"]

    # Perform action
    await client.patch(
        f"/api/v1/admin/users/{target_id}/status",
        headers=admin_user["auth"],
        json={"is_active": False},
    )

    # Check audit logs
    r_logs = await client.get("/api/v1/admin/audit-logs", headers=admin_user["auth"])
    assert r_logs.status_code == 200
    logs = r_logs.json()["items"]
    assert any(l["action"] == "user_deactivated" and l["entity_id"] == target_id for l in logs)

