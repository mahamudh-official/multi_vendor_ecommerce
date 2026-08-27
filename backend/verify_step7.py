import asyncio
import httpx
import uuid
from decimal import Decimal

BASE_URL = "http://localhost:8000/api/v1"

async def run_step7_verification():
    print("==================================================")
    print("🚀 STARTING STEP 7 END-TO-END VERIFICATION")
    print("==================================================")

    async with httpx.AsyncClient(base_url=BASE_URL, timeout=30.0) as client:
        unique = uuid.uuid4().hex[:6]

        # 1. Register Seller A and Seller B
        seller_a_email = f"seller_a_{unique}@market.com"
        seller_b_email = f"seller_b_{unique}@market.com"
        buyer_email = f"buyer_{unique}@market.com"
        password = "Password123!"

        await client.post("/auth/register", json={
            "email": seller_a_email, "password": password, "full_name": "Seller Alpha", "role": "seller"
        })
        res_a = await client.post("/auth/login", json={"email": seller_a_email, "password": password})
        token_a = res_a.json()["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        await client.post("/auth/register", json={
            "email": seller_b_email, "password": password, "full_name": "Seller Beta", "role": "seller"
        })
        res_b = await client.post("/auth/login", json={"email": seller_b_email, "password": password})
        token_b = res_b.json()["access_token"]
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # 2. Register Buyer
        await client.post("/auth/register", json={
            "email": buyer_email, "password": password, "full_name": "Buyer Bob", "role": "customer"
        })
        res_buyer = await client.post("/auth/login", json={"email": buyer_email, "password": password})
        token_buyer = res_buyer.json()["access_token"]
        headers_buyer = {"Authorization": f"Bearer {token_buyer}"}

        print("✅ Registered and authenticated Seller A, Seller B, and Customer.")

        # 3. Create Products for Seller A and Seller B
        r_cat = await client.get("/categories")
        cat_id = (r_cat.json() if isinstance(r_cat.json(), list) else r_cat.json().get("items", []))[0]["id"]

        # Seller A product (stock=6, so buying 1 will reduce stock to 5 and trigger LOW_STOCK alert)
        r_p1 = await client.post("/seller/products", headers=headers_a, json={
            "name": f"Mechanical Keyboard {unique}",
            "price": 100.00,
            "stock_quantity": 6,
            "category_id": cat_id,
        })
        p1_id = r_p1.json()["id"]

        # Seller B product (stock=20)
        r_p2 = await client.post("/seller/products", headers=headers_b, json={
            "name": f"Wireless Mouse {unique}",
            "price": 50.00,
            "stock_quantity": 20,
            "category_id": cat_id,
        })
        p2_id = r_p2.json()["id"]
        print("✅ Created products for Seller A and Seller B.")

        # 4. Customer adds both to cart
        await client.post("/cart/items", headers=headers_buyer, json={"product_id": p1_id, "quantity": 1})
        await client.post("/cart/items", headers=headers_buyer, json={"product_id": p2_id, "quantity": 2})

        # 5. Customer checks out
        r_checkout = await client.post("/orders/checkout", headers=headers_buyer, json={
            "shipping_address": {
                "full_name": "Buyer Bob",
                "phone": "+1-555-0100",
                "address_line1": "456 Market Ave",
                "city": "Austin",
                "state": "TX",
                "postal_code": "78701",
                "country": "USA",
            },
            "idempotency_key": f"order_idemp_{unique}",
        })
        assert r_checkout.status_code == 201
        order = r_checkout.json()
        order_id = order["id"]
        print(f"✅ Multi-vendor order created: #{order['order_number']}, Total: ${order['total_amount']}")

        # 6. Verify Notifications dispatched:
        # Customer should have ORDER_CREATED
        r_buyer_notifs = await client.get("/notifications", headers=headers_buyer)
        buyer_items = r_buyer_notifs.json()["items"]
        assert any(n["type"] == "order_created" for n in buyer_items)
        print("✅ Customer received 'order_created' notification.")

        # Seller A should have SELLER_ORDER_CREATED and LOW_STOCK (stock reduced from 6 to 5)
        r_a_notifs = await client.get("/notifications", headers=headers_a)
        a_items = r_a_notifs.json()["items"]
        assert any(n["type"] == "seller_order_created" for n in a_items)
        assert any(n["type"] == "low_stock" for n in a_items)
        print("✅ Seller A received isolated 'seller_order_created' and 'low_stock' notifications.")

        # Seller B should have SELLER_ORDER_CREATED but NOT low_stock (stock 20->18)
        r_b_notifs = await client.get("/notifications", headers=headers_b)
        b_items = r_b_notifs.json()["items"]
        assert any(n["type"] == "seller_order_created" for n in b_items)
        assert not any(n["type"] == "low_stock" for n in b_items)
        print("✅ Seller B received isolated 'seller_order_created' notification only.")

        # 7. Customer creates Payment Intent
        r_intent = await client.post(f"/payments/orders/{order_id}/create", headers=headers_buyer)
        assert r_intent.status_code == 201
        intent_data = r_intent.json()
        payment_id = intent_data["payment_id"]
        print(f"✅ Payment Intent created: ID={payment_id}, Amount=${intent_data['amount']}, Status={intent_data['status']}")

        # 8. Seller attempts to process payment -> Forbidden (403)
        r_unauth = await client.post(f"/payments/{payment_id}/process", headers=headers_a, json={"simulate_failure": False})
        assert r_unauth.status_code == 403
        print("✅ Seller payment modification blocked with 403 Forbidden.")

        # 9. Customer processes payment successfully
        r_process = await client.post(f"/payments/{payment_id}/process", headers=headers_buyer, json={"simulate_failure": False})
        assert r_process.status_code == 200
        process_data = r_process.json()
        assert process_data["success"] is True
        assert process_data["payment"]["status"] == "succeeded"
        print(f"✅ Payment processed successfully. Txn ID: {process_data['transaction_id']}")

        # 10. Verify Idempotent payment processing
        r_reprocess = await client.post(f"/payments/{payment_id}/process", headers=headers_buyer, json={"simulate_failure": False})
        assert r_reprocess.status_code == 200
        assert r_reprocess.json()["success"] is True
        print("✅ Payment re-processing is strictly idempotent.")

        # 11. Customer should have PAYMENT_SUCCEEDED notification
        r_buyer_notifs2 = await client.get("/notifications", headers=headers_buyer)
        buyer_items2 = r_buyer_notifs2.json()["items"]
        assert any(n["type"] == "payment_succeeded" for n in buyer_items2)
        print("✅ Customer received 'payment_succeeded' notification.")

        # 12. Notification Read and Unread lifecycle
        r_unread_count = await client.get("/notifications/unread-count", headers=headers_buyer)
        unread_before = r_unread_count.json()["unread_count"]
        assert unread_before > 0

        # Mark single read
        first_id = buyer_items2[0]["id"]
        await client.post(f"/notifications/{first_id}/read", headers=headers_buyer)

        # Mark all read
        r_read_all = await client.post("/notifications/read-all", headers=headers_buyer)
        assert r_read_all.status_code == 200

        r_unread_count_after = await client.get("/notifications/unread-count", headers=headers_buyer)
        assert r_unread_count_after.json()["unread_count"] == 0
        print("✅ Notifications marked as read; unread count accurately verified as 0.")

        print("==================================================")
        print("🎉 ALL STEP 7 INTEGRATION VERIFICATIONS PASSED!")
        print("==================================================")

if __name__ == "__main__":
    asyncio.run(run_step7_verification())
