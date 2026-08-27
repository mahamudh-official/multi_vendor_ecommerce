"""Live Verification Script for Step 6: Multi-Vendor Seller Dashboard & Order Management."""

import asyncio
import uuid
from decimal import Decimal
from httpx import AsyncClient, ASGITransport
from app.main import app


async def run_live_verification():
    print("=" * 70)
    print("STEP 6 LIVE INTEGRATION VERIFICATION: MULTI-VENDOR SELLER PORTAL")
    print("=" * 70)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        unique_suffix = uuid.uuid4().hex[:8]

        # 1. Register Users: Seller 1, Seller 2, Customer
        print("\n[1] Registering test users...")
        seller1_email = f"seller1_{unique_suffix}@market.com"
        seller2_email = f"seller2_{unique_suffix}@market.com"
        customer_email = f"buyer_{unique_suffix}@market.com"
        password = "SecurePassword123!"

        # Register seller 1
        r = await client.post("/api/v1/auth/register", json={
            "email": seller1_email,
            "password": password,
            "full_name": "Seller One Tech",
            "role": "seller"
        })
        assert r.status_code == 201, f"Seller 1 registration failed: {r.text}"
        # Login seller 1
        r = await client.post("/api/v1/auth/login", json={"email": seller1_email, "password": password})
        assert r.status_code == 200
        seller1_token = r.json()["access_token"]
        seller1_auth = {"Authorization": f"Bearer {seller1_token}"}
        print("  ✓ Seller 1 registered & logged in")

        # Register seller 2
        r = await client.post("/api/v1/auth/register", json={
            "email": seller2_email,
            "password": password,
            "full_name": "Seller Two Fashion",
            "role": "seller"
        })
        assert r.status_code == 201, f"Seller 2 registration failed: {r.text}"
        # Login seller 2
        r = await client.post("/api/v1/auth/login", json={"email": seller2_email, "password": password})
        assert r.status_code == 200
        seller2_token = r.json()["access_token"]
        seller2_auth = {"Authorization": f"Bearer {seller2_token}"}
        print("  ✓ Seller 2 registered & logged in")

        # Register customer
        r = await client.post("/api/v1/auth/register", json={
            "email": customer_email,
            "password": password,
            "full_name": "Alice Shopper",
            "role": "customer"
        })
        assert r.status_code == 201, f"Customer registration failed: {r.text}"
        # Login customer
        r = await client.post("/api/v1/auth/login", json={"email": customer_email, "password": password})
        assert r.status_code == 200
        customer_token = r.json()["access_token"]
        customer_auth = {"Authorization": f"Bearer {customer_token}"}
        print("  ✓ Customer registered & logged in")

        # 2. Get Category for product creation
        r = await client.get("/api/v1/categories")
        res = r.json()
        categories = res if isinstance(res, list) else res.get("items", [])
        cat_id = categories[0]["id"]
        print(f"  ✓ Category obtained: {categories[0]['name']} ({cat_id})")

        # 3. Seller 1 creates Product 1A (normal stock) & Product 1B (low stock <= 5)
        print("\n[2] Seller 1 product catalog management...")
        r = await client.post("/api/v1/seller/products", headers=seller1_auth, json={
            "name": f"Mechanical Keyboard {unique_suffix}",
            "price": 120.50,
            "stock_quantity": 15,
            "category_id": cat_id,
            "sku": f"KB-{unique_suffix}",
            "description": "Premium RGB keyboard"
        })
        assert r.status_code == 201, f"Create Product 1A failed: {r.text}"
        prod1a = r.json()
        print(f"  ✓ Seller 1 created Product 1A: {prod1a['name']} ($120.50, stock: 15)")

        r = await client.post("/api/v1/seller/products", headers=seller1_auth, json={
            "name": f"USB-C Cable {unique_suffix}",
            "price": 15.00,
            "stock_quantity": 3, # Low stock <= 5
            "category_id": cat_id,
            "sku": f"CBL-{unique_suffix}",
            "description": "Braided cable"
        })
        assert r.status_code == 201
        prod1b = r.json()
        print(f"  ✓ Seller 1 created Product 1B (Low Stock): {prod1b['name']} ($15.00, stock: 3)")

        # 4. Seller 2 creates Product 2A
        print("\n[3] Seller 2 product catalog management...")
        r = await client.post("/api/v1/seller/products", headers=seller2_auth, json={
            "name": f"Silk Scarf {unique_suffix}",
            "price": 85.00,
            "stock_quantity": 20,
            "category_id": cat_id,
            "sku": f"SCF-{unique_suffix}",
            "description": "Pure silk scarf"
        })
        assert r.status_code == 201
        prod2a = r.json()
        print(f"  ✓ Seller 2 created Product 2A: {prod2a['name']} ($85.00, stock: 20)")

        # 5. Verify Seller Isolation in Product Management
        print("\n[4] Testing Seller Product Isolation...")
        # Seller 2 tries to update Seller 1's product -> 404
        r = await client.put(f"/api/v1/seller/products/{prod1a['id']}", headers=seller2_auth, json={
            "name": "Hacked Title"
        })
        assert r.status_code == 404, f"Seller 2 was able to access Seller 1 product: {r.status_code}"
        print("  ✓ Cross-seller product update blocked (404 Not Found)")

        # Customer tries to access seller dashboard -> 403
        r = await client.get("/api/v1/seller/dashboard", headers=customer_auth)
        assert r.status_code == 403, f"Customer was not blocked from seller dashboard: {r.status_code}"
        print("  ✓ Customer role access to seller portal blocked (403 Forbidden)")

        # 6. Customer builds Multi-Vendor Cart and Checks Out
        print("\n[5] Multi-Vendor Purchase (Customer buys Seller 1 + Seller 2 items)...")
        # Add 2 of Prod 1A ($120.50 * 2 = $241.00)
        r = await client.post("/api/v1/cart/items", headers=customer_auth, json={
            "product_id": prod1a["id"],
            "quantity": 2
        })
        assert r.status_code == 200

        # Add 1 of Prod 2A ($85.00 * 1 = $85.00)
        r = await client.post("/api/v1/cart/items", headers=customer_auth, json={
            "product_id": prod2a["id"],
            "quantity": 1
        })
        assert r.status_code == 200

        # Customer Checkout
        checkout_payload = {
            "shipping_address": {
                "full_name": "Alice Shopper",
                "phone": "+1-555-0100",
                "address_line1": "100 Market St",
                "city": "Austin",
                "state": "TX",
                "postal_code": "78701",
                "country": "USA"
            },
            "customer_note": "Please leave at front door"
        }
        r = await client.post("/api/v1/orders/checkout", headers=customer_auth, json=checkout_payload)
        assert r.status_code == 201, f"Checkout failed: {r.text}"
        order = r.json()
        order_id = order["id"]
        print(f"  ✓ Multi-vendor order placed: {order['order_number']} | Total: ${order['total_amount']}")
        assert Decimal(str(order["total_amount"])) == Decimal("326.00") # 241.00 + 85.00

        # 7. Verify Seller 1 Dashboard Aggregations
        print("\n[6] Verifying Seller 1 Dashboard Metrics...")
        r = await client.get("/api/v1/seller/dashboard", headers=seller1_auth)
        assert r.status_code == 200
        dash1 = r.json()
        stats1 = dash1["stats"]
        print(f"  • Total Products: {stats1['total_products']}")
        print(f"  • Low Stock Count: {stats1['low_stock_products']} (expected: 1)")
        print(f"  • Total Orders: {stats1['total_orders']} (expected: 1)")
        print(f"  • Pending Orders: {stats1['pending_orders']} (expected: 1)")
        print(f"  • Total Sales Amount: ${stats1['total_sales_amount']} (expected: 241.00)")
        assert stats1["total_products"] == 2
        assert stats1["low_stock_products"] == 1
        assert stats1["total_orders"] == 1
        assert Decimal(str(stats1["total_sales_amount"])) == Decimal("241.00")
        assert len(dash1["low_stock_products"]) == 1
        assert dash1["low_stock_products"][0]["id"] == prod1b["id"]
        print("  ✓ Seller 1 dashboard metrics verified with exact isolation!")

        # 8. Verify Seller Order Data Isolation
        print("\n[7] Verifying Strict Multi-Vendor Order Isolation...")
        # Seller 1 views order details
        r = await client.get(f"/api/v1/seller/orders/{order_id}", headers=seller1_auth)
        assert r.status_code == 200
        s1_order = r.json()
        print(f"  • Seller 1 sees {len(s1_order['items'])} item(s) in order:")
        for item in s1_order["items"]:
            print(f"    - {item['product_name']} | Qty: {item['quantity']} | Subtotal: ${item['line_total']}")
        assert len(s1_order["items"]) == 1
        assert s1_order["items"][0]["product_id"] == prod1a["id"]
        assert Decimal(str(s1_order["seller_subtotal"])) == Decimal("241.00")

        # Seller 2 views order details
        r = await client.get(f"/api/v1/seller/orders/{order_id}", headers=seller2_auth)
        assert r.status_code == 200
        s2_order = r.json()
        print(f"  • Seller 2 sees {len(s2_order['items'])} item(s) in order:")
        for item in s2_order["items"]:
            print(f"    - {item['product_name']} | Qty: {item['quantity']} | Subtotal: ${item['line_total']}")
        assert len(s2_order["items"]) == 1
        assert s2_order["items"][0]["product_id"] == prod2a["id"]
        assert Decimal(str(s2_order["seller_subtotal"])) == Decimal("85.00")
        print("  ✓ Strict Order Item Data Isolation Verified! Neither seller sees the other's products.")

        # 9. Test Independent Fulfillment Transitions & State Machine
        print("\n[8] Testing Fulfillment State Transitions & Overall Order Status...")
        # Seller 1 advances: pending -> confirmed
        r = await client.patch(f"/api/v1/seller/orders/{order_id}/status", headers=seller1_auth, json={"status": "confirmed"})
        assert r.status_code == 200
        print("  ✓ Seller 1 advanced item to 'confirmed'")

        # Seller 1 advances: confirmed -> processing
        r = await client.patch(f"/api/v1/seller/orders/{order_id}/status", headers=seller1_auth, json={"status": "processing"})
        assert r.status_code == 200
        print("  ✓ Seller 1 advanced item to 'processing'")

        # Seller 1 advances: processing -> shipped
        r = await client.patch(f"/api/v1/seller/orders/{order_id}/status", headers=seller1_auth, json={"status": "shipped"})
        assert r.status_code == 200
        print("  ✓ Seller 1 advanced item to 'shipped'")

        # Verify invalid transition: Seller 1 tries shipped -> pending
        r = await client.patch(f"/api/v1/seller/orders/{order_id}/status", headers=seller1_auth, json={"status": "pending"})
        assert r.status_code == 400
        print(f"  ✓ Invalid status jump correctly rejected (400 Bad Request): {r.json()['detail']}")

        # Check Seller 2's item: must still be 'pending'
        r = await client.get(f"/api/v1/seller/orders/{order_id}", headers=seller2_auth)
        s2_order = r.json()
        assert s2_order["items"][0]["fulfillment_status"] == "pending"
        print("  ✓ Seller 2 item independently remained 'pending'")

        # Seller 2 advances all the way to 'delivered'
        for next_st in ["confirmed", "processing", "shipped", "delivered"]:
            r = await client.patch(f"/api/v1/seller/orders/{order_id}/status", headers=seller2_auth, json={"status": next_st})
            assert r.status_code == 200
        print("  ✓ Seller 2 advanced item to 'delivered'")

        # Order overall status should NOT be delivered yet because Seller 1 is only 'shipped'
        r = await client.get(f"/api/v1/orders/{order_id}", headers=customer_auth)
        cust_order = r.json()
        print(f"  • Global Order Status with (Seller 1=shipped, Seller 2=delivered): {cust_order['status']}")
        assert cust_order["status"] == "shipped"

        # Seller 1 finishes delivery: shipped -> delivered
        r = await client.patch(f"/api/v1/seller/orders/{order_id}/status", headers=seller1_auth, json={"status": "delivered"})
        assert r.status_code == 200
        print("  ✓ Seller 1 advanced item to 'delivered'")

        # Now all items in order are delivered -> Global Order Status must be 'delivered'
        r = await client.get(f"/api/v1/orders/{order_id}", headers=customer_auth)
        cust_order = r.json()
        print(f"  • Global Order Status with ALL items delivered: {cust_order['status']}")
        assert cust_order["status"] == "delivered"
        print("  ✓ Global Order Status correctly harmonized to 'delivered'!")

        # 10. Soft-deactivation of product
        print("\n[9] Testing Seller Product Soft-Deactivation...")
        r = await client.delete(f"/api/v1/seller/products/{prod1a['id']}", headers=seller1_auth)
        assert r.status_code == 204
        # Verify product is inactive
        r = await client.get(f"/api/v1/seller/products/{prod1a['id']}", headers=seller1_auth)
        assert r.json()["is_active"] is False
        print("  ✓ Product successfully soft-deactivated (is_active=False)")

        # Historical order items remain intact with immutable snapshots
        r = await client.get(f"/api/v1/orders/{order_id}", headers=customer_auth)
        assert len(r.json()["items"]) == 2
        assert Decimal(str(r.json()["items"][0]["unit_price"])) == Decimal("120.50")
        print("  ✓ Historical order snapshots remain 100% intact and immutable!")

    print("\n" + "=" * 70)
    print("ALL STEP 6 LIVE INTEGRATION VERIFICATIONS PASSED PERFECTLY (10/10)!")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(run_live_verification())
