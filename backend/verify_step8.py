"""
E2E Multi-Vendor Verification Script for Step 8: Admin Dashboard + Platform Management.
"""
import asyncio
import sys
import uuid
import httpx
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.modules.auth.models import User, UserRole

BASE_URL = "http://localhost:8000/api/v1"

def log(msg, success=True):
    icon = "[PASS]" if success else "[FAIL]"
    print(f"{icon} {msg}")

async def promote_user_to_admin(email: str):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if user:
            user.role = UserRole.admin
            await session.commit()

async def run_verification_async():
    client = httpx.AsyncClient(base_url=BASE_URL, timeout=30.0)

    print("==================================================")
    print("STEP 8: ADMIN DASHBOARD & PLATFORM MANAGEMENT E2E VERIFICATION")
    print("==================================================")

    uid = uuid.uuid4().hex[:6]
    admin_email = f"admin_{uid}@marketo.com"
    seller1_email = f"seller1_{uid}@marketo.com"
    seller2_email = f"seller2_{uid}@marketo.com"
    customer_email = f"customer_{uid}@marketo.com"
    password = "SecurePassword123!"

    # 1. Register users
    print("\n--- 1. Registering Test Accounts ---")
    r = await client.post("/auth/register", json={"email": admin_email, "password": password, "full_name": "Test Admin", "role": "customer"})
    assert r.status_code == 201, f"Admin reg failed: {r.text}"
    await promote_user_to_admin(admin_email)

    r = await client.post("/auth/login", json={"email": admin_email, "password": password})
    assert r.status_code == 200, f"Admin login failed: {r.text}"
    admin_token = r.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    log("Admin registered, promoted & token acquired")

    r = await client.post("/auth/register", json={"email": seller1_email, "password": password, "full_name": "Alpha Vendor", "role": "seller"})
    assert r.status_code == 201
    seller1_id = r.json()["id"]
    r = await client.post("/auth/login", json={"email": seller1_email, "password": password})
    assert r.status_code == 200
    seller1_token = r.json()["access_token"]
    seller1_headers = {"Authorization": f"Bearer {seller1_token}"}
    log("Seller 1 (Alpha) registered (seller_status=pending)")

    r = await client.post("/auth/register", json={"email": seller2_email, "password": password, "full_name": "Beta Store", "role": "seller"})
    assert r.status_code == 201
    seller2_id = r.json()["id"]
    r = await client.post("/auth/login", json={"email": seller2_email, "password": password})
    assert r.status_code == 200
    seller2_token = r.json()["access_token"]
    seller2_headers = {"Authorization": f"Bearer {seller2_token}"}
    log("Seller 2 (Beta) registered (seller_status=pending)")

    r = await client.post("/auth/register", json={"email": customer_email, "password": password, "full_name": "Test Customer", "role": "customer"})
    assert r.status_code == 201
    r = await client.post("/auth/login", json={"email": customer_email, "password": password})
    assert r.status_code == 200
    customer_token = r.json()["access_token"]
    customer_headers = {"Authorization": f"Bearer {customer_token}"}
    log("Customer registered & logged in")

    # 2. RBAC Security Tests
    print("\n--- 2. RBAC Security Tests (403 Forbidden for Non-Admins) ---")
    r = await client.get("/admin/dashboard", headers=customer_headers)
    assert r.status_code == 403, f"Customer should be 403, got {r.status_code}"
    log("Customer access to /admin/dashboard rejected with 403 Forbidden")

    r = await client.get("/admin/dashboard", headers=seller1_headers)
    assert r.status_code == 403, f"Seller should be 403, got {r.status_code}"
    log("Seller access to /admin/dashboard rejected with 403 Forbidden")

    r = await client.get("/admin/dashboard", headers=admin_headers)
    assert r.status_code == 200, f"Admin should be 200, got {r.status_code}"
    stats = r.json()
    assert "total_users" in stats and "total_revenue" in stats
    log(f"Admin dashboard stats retrieved successfully (total_users: {stats['total_users']}, revenue: {stats['total_revenue']})")

    # 3. User Management & Self-Deactivation Guard
    print("\n--- 3. User Management & Security Safeguards ---")
    r = await client.get("/admin/users", headers=admin_headers)
    assert r.status_code == 200
    users = r.json()["items"]
    assert len(users) >= 4
    log(f"Admin listed {len(users)} registered users")

    # Try deactivating self (admin)
    admin_id = next(u["id"] for u in users if u["email"] == admin_email)
    r = await client.patch(f"/admin/users/{admin_id}/status", json={"is_active": False}, headers=admin_headers)
    assert r.status_code == 400, f"Self-deactivation should fail with 400, got {r.status_code}"
    log("Admin self-deactivation prevented (400 Bad Request)")

    # Deactivate and Reactivate Customer
    cust_id = next(u["id"] for u in users if u["email"] == customer_email)
    r = await client.patch(f"/admin/users/{cust_id}/status", json={"is_active": False}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["is_active"] is False
    log("Customer successfully deactivated by admin")

    r = await client.patch(f"/admin/users/{cust_id}/status", json={"is_active": True}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["is_active"] is True
    log("Customer successfully reactivated by admin")

    # 4. Category Management & Safe Deletion
    print("\n--- 4. Category Management & Safe Deletion ---")
    r = await client.post("/admin/categories", json={"name": f"Admin Gadgets {uid}", "description": "High tech gadgets"}, headers=admin_headers)
    assert r.status_code == 201
    cat_id = r.json()["id"]
    log(f"Admin created category '{r.json()['name']}' (slug: {r.json()['slug']})")

    # 5. Seller Approval & Suspension Lifecycle
    print("\n--- 5. Seller Status Lifecycle & Moderation ---")
    r = await client.get("/admin/sellers", headers=admin_headers)
    assert r.status_code == 200
    sellers = r.json()["items"]
    log(f"Admin listed {len(sellers)} sellers")

    # Approve Seller 1 and Seller 2
    r = await client.patch(f"/admin/sellers/{seller1_id}/status", json={"status": "approved"}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["seller_status"] == "approved"
    log("Seller 1 approved by admin")

    r = await client.patch(f"/admin/sellers/{seller2_id}/status", json={"status": "approved"}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["seller_status"] == "approved"
    log("Seller 2 approved by admin")

    # Suspend Seller 2
    r = await client.patch(f"/admin/sellers/{seller2_id}/status", json={"status": "suspended"}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["seller_status"] == "suspended"
    log("Seller 2 suspended by admin")

    # Verify suspended seller cannot create product (403)
    r = await client.post("/seller/products", json={
        "name": "Suspended Item",
        "price": 50.0,
        "stock_quantity": 10,
        "category_id": cat_id
    }, headers=seller2_headers)
    assert r.status_code == 403, f"Suspended seller product creation should be 403, got {r.status_code}"
    log("Suspended seller product creation blocked with 403 Forbidden")

    # Reactivate Seller 2
    r = await client.patch(f"/admin/sellers/{seller2_id}/status", json={"status": "approved"}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["seller_status"] == "approved"
    log("Seller 2 reactivated by admin")

    # Seller 1 creates product in this category
    r = await client.post("/seller/products", json={
        "name": f"Ultra Smartphone {uid}",
        "price": 499.99,
        "stock_quantity": 3,  # low stock
        "category_id": cat_id
    }, headers=seller1_headers)
    assert r.status_code == 201
    prod1_id = r.json()["id"]
    log(f"Seller 1 created product '{r.json()['name']}' in category")

    # Try deleting category with attached product (must fail 400)
    r = await client.delete(f"/admin/categories/{cat_id}", headers=admin_headers)
    assert r.status_code == 400, f"Deleting non-empty category should fail with 400, got {r.status_code}"
    log("Deletion of category with attached products rejected (400 Bad Request)")

    # 6. Product Moderation
    print("\n--- 6. Product Moderation & Filters ---")
    r = await client.get("/admin/products?low_stock=true", headers=admin_headers)
    assert r.status_code == 200
    low_stock_prods = r.json()["items"]
    assert any(p["id"] == prod1_id for p in low_stock_prods)
    log(f"Low stock filter successfully identified product (stock: 3 <= 5)")

    # Deactivate product
    r = await client.patch(f"/admin/products/{prod1_id}/status", json={"is_active": False}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["is_active"] is False
    log("Admin deactivated product for moderation")

    # Verify public catalog excludes inactive product
    r = await client.get(f"/products/{prod1_id}")
    assert r.status_code == 404, f"Inactive product should not appear in public catalog, got {r.status_code}"
    log("Inactive product hidden from public catalog (404)")

    # Reactivate product
    r = await client.patch(f"/admin/products/{prod1_id}/status", json={"is_active": True}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["is_active"] is True
    log("Admin reactivated product")

    # 7. Multi-Vendor Order & Payment Flow Oversight
    print("\n--- 7. Order & Payment Platform Monitoring ---")
    # Customer adds to cart and checks out
    r = await client.post("/cart/items", json={"product_id": prod1_id, "quantity": 1}, headers=customer_headers)
    assert r.status_code == 200
    r = await client.post("/orders/checkout", json={
        "shipping_address": {
            "full_name": "Test Customer",
            "phone": "+1234567890",
            "address_line1": "123 Market St",
            "city": "Metropolis",
            "state": "NY",
            "postal_code": "10001",
            "country": "US"
        },
        "idempotency_key": f"order_step8_{uid}"
    }, headers=customer_headers)
    assert r.status_code == 201
    order = r.json()
    order_id = order["id"]
    log(f"Customer placed order {order['order_number']} (Total: ${order['total_amount']})")

    # Create payment intent and process payment
    r = await client.post(f"/payments/orders/{order_id}/create", headers=customer_headers)
    assert r.status_code == 201, f"Payment create failed: {r.text}"
    payment_id = r.json()["payment_id"]

    r = await client.post(f"/payments/{payment_id}/process", json={"simulate_failure": False}, headers=customer_headers)
    assert r.status_code == 200, f"Payment process failed: {r.text}"
    log("Payment processed successfully")

    # Admin inspects order
    r = await client.get(f"/admin/orders/{order_id}", headers=admin_headers)
    assert r.status_code == 200
    admin_order = r.json()
    assert admin_order["payment_status"] == "paid"
    assert len(admin_order["items"]) == 1
    log(f"Admin verified order snapshot & paid payment status (Item seller: {admin_order['items'][0]['seller_id']})")

    # Admin inspects payments
    r = await client.get("/admin/payments", headers=admin_headers)
    assert r.status_code == 200
    payments = r.json()["items"]
    assert any(p["id"] == payment_id for p in payments)
    log(f"Admin verified payment transaction record in monitoring feed")

    # 8. Immutable Audit Trail Verification
    print("\n--- 8. Immutable Audit Trail Verification ---")
    r = await client.get("/admin/audit-logs", headers=admin_headers)
    assert r.status_code == 200
    logs = r.json()["items"]
    assert len(logs) >= 5
    actions_found = [l["action"] for l in logs]
    log(f"Audit logs retrieved: {len(logs)} entries logged (actions: {set(actions_found)})")

    print("\n==================================================")
    print("ALL STEP 8 E2E PLATFORM MANAGEMENT TESTS PASSED PERFECTLY!")
    print("==================================================")

if __name__ == "__main__":
    asyncio.run(run_verification_async())

