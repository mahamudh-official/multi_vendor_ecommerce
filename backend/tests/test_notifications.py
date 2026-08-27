"""
Backend tests for Notifications module, triggers, and multi-vendor isolation.
"""
import uuid
import pytest
from httpx import AsyncClient


@pytest.fixture
def unique_suffix() -> str:
    return uuid.uuid4().hex[:8]


@pytest.fixture
async def seller_a(client: AsyncClient, unique_suffix: str):
    email = f"seller_a_{unique_suffix}@market.com"
    await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Password123!", "full_name": "Seller Alpha", "role": "seller"
    })
    r = await client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!"})
    return {"auth": {"Authorization": f"Bearer {r.json()['access_token']}"}, "email": email}


@pytest.fixture
async def seller_b(client: AsyncClient, unique_suffix: str):
    email = f"seller_b_{unique_suffix}@market.com"
    await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Password123!", "full_name": "Seller Beta", "role": "seller"
    })
    r = await client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!"})
    return {"auth": {"Authorization": f"Bearer {r.json()['access_token']}"}, "email": email}


@pytest.fixture
async def customer(client: AsyncClient, unique_suffix: str):
    email = f"buyer_notif_{unique_suffix}@market.com"
    await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Password123!", "full_name": "Notif Buyer", "role": "customer"
    })
    r = await client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!"})
    return {"auth": {"Authorization": f"Bearer {r.json()['access_token']}"}, "email": email}


@pytest.mark.asyncio
async def test_order_creation_triggers_customer_and_seller_notifications(
    client: AsyncClient, seller_a: dict, seller_b: dict, customer: dict, unique_suffix: str
):
    """Multi-vendor order creation sends isolated notifications to customer, Seller A, and Seller B."""
    # 1. Get category
    r = await client.get("/api/v1/categories")
    cat_res = r.json()
    categories = cat_res if isinstance(cat_res, list) else cat_res.get("items", [])
    cat_id = categories[0]["id"]

    # 2. Seller A creates Product A (stock 10)
    r = await client.post("/api/v1/seller/products", headers=seller_a["auth"], json={
        "name": f"Product A {unique_suffix}",
        "price": 50.00,
        "stock_quantity": 10,
        "category_id": cat_id,
        "sku": f"SKA-{unique_suffix}",
    })
    prod_a = r.json()

    # 3. Seller B creates Product B (stock 4 -> triggers low stock upon checkout)
    r = await client.post("/api/v1/seller/products", headers=seller_b["auth"], json={
        "name": f"Product B {unique_suffix}",
        "price": 75.00,
        "stock_quantity": 4,
        "category_id": cat_id,
        "sku": f"SKB-{unique_suffix}",
    })
    prod_b = r.json()

    # 4. Customer buys 1 of Prod A and 1 of Prod B
    await client.post("/api/v1/cart/items", headers=customer["auth"], json={"product_id": prod_a["id"], "quantity": 1})
    await client.post("/api/v1/cart/items", headers=customer["auth"], json={"product_id": prod_b["id"], "quantity": 1})

    checkout_payload = {
        "shipping_address": {
            "full_name": "Notif Buyer",
            "phone": "+1-555-0188",
            "address_line1": "77 Market Ave",
            "city": "Austin",
            "state": "TX",
            "postal_code": "78701",
            "country": "USA",
        }
    }
    r = await client.post("/api/v1/orders/checkout", headers=customer["auth"], json=checkout_payload)
    assert r.status_code == 201
    order = r.json()

    # 5. Verify Customer gets order_created notification
    r_cust = await client.get("/api/v1/notifications", headers=customer["auth"])
    assert r_cust.status_code == 200
    cust_notifs = r_cust.json()["items"]
    assert any(n["type"] == "order_created" for n in cust_notifs)

    # 6. Verify Seller A gets seller_order_created notification
    r_sa = await client.get("/api/v1/notifications", headers=seller_a["auth"])
    sa_notifs = r_sa.json()["items"]
    sa_order_notif = next(n for n in sa_notifs if n["type"] == "seller_order_created")
    assert sa_order_notif["data"]["seller_item_count"] == 1
    assert "50.00" in sa_order_notif["data"]["seller_subtotal"]

    # 7. Verify Seller B gets seller_order_created AND low_stock notification (stock became 3 <= 5)
    r_sb = await client.get("/api/v1/notifications", headers=seller_b["auth"])
    sb_notifs = r_sb.json()["items"]
    assert any(n["type"] == "seller_order_created" for n in sb_notifs)
    assert any(n["type"] == "low_stock" for n in sb_notifs)

    # 8. Verify Seller A cannot see Seller B's notifications
    assert not any(n["type"] == "low_stock" and n["data"].get("product_id") == prod_b["id"] for n in sa_notifs)


@pytest.mark.asyncio
async def test_notification_read_and_unread_count_lifecycle(client: AsyncClient, customer: dict, seller_a: dict, unique_suffix: str):
    """Tests mark_as_read, unread_count, and mark_all_as_read endpoints."""
    # Check initial unread count
    r = await client.get("/api/v1/notifications/unread-count", headers=customer["auth"])
    assert r.status_code == 200
    initial_unread = r.json()["unread_count"]

    # Trigger a notification
    r_cat = await client.get("/api/v1/categories")
    cat_id = (r_cat.json() if isinstance(r_cat.json(), list) else r_cat.json().get("items", []))[0]["id"]
    r_prod = await client.post("/api/v1/seller/products", headers=seller_a["auth"], json={
        "name": f"Book {unique_suffix}", "price": 20.00, "stock_quantity": 10, "category_id": cat_id
    })
    await client.post("/api/v1/cart/items", headers=customer["auth"], json={"product_id": r_prod.json()["id"], "quantity": 1})
    r_checkout = await client.post("/api/v1/orders/checkout", headers=customer["auth"], json={
        "shipping_address": {
            "full_name": "Test Customer",
            "phone": "+1-555-0100",
            "address_line1": "123 Main Street",
            "city": "Austin",
            "state": "TX",
            "postal_code": "78701",
            "country": "USA",
        }
    })
    assert r_checkout.status_code == 201

    # Get list of notifications
    r_list = await client.get("/api/v1/notifications", headers=customer["auth"])
    assert r_list.status_code == 200
    notifs = r_list.json()["items"]
    assert len(notifs) > 0
    first_notif = notifs[0]
    assert first_notif["is_read"] is False

    # Mark single notification as read
    r_read = await client.post(f"/api/v1/notifications/{first_notif['id']}/read", headers=customer["auth"])
    assert r_read.status_code == 200
    assert r_read.json()["is_read"] is True

    # Mark all as read
    r_all = await client.post("/api/v1/notifications/read-all", headers=customer["auth"])
    assert r_all.status_code == 200

    # Unread count should now be 0
    r_cnt = await client.get("/api/v1/notifications/unread-count", headers=customer["auth"])
    assert r_cnt.json()["unread_count"] == 0

