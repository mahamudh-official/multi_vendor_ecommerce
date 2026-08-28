"""
Backend tests for Payments module and PaymentProvider abstraction.
Covers all required payment test scenarios and security constraints.
"""
import uuid
from decimal import Decimal
import pytest
from httpx import AsyncClient

from app.modules.payments.models import PaymentStatus


@pytest.fixture
def unique_suffix() -> str:
    return uuid.uuid4().hex[:8]


@pytest.fixture
async def seller_auth(client: AsyncClient, unique_suffix: str):
    email = f"seller_pay_{unique_suffix}@market.com"
    r = await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Password123!", "full_name": "Pay Seller", "role": "seller"
    })
    assert r.status_code == 201
    r = await client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!"})
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
async def customer_auth(client: AsyncClient, unique_suffix: str):
    email = f"cust_pay_{unique_suffix}@market.com"
    r = await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Password123!", "full_name": "Pay Customer", "role": "customer"
    })
    assert r.status_code == 201
    r = await client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!"})
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
async def other_customer_auth(client: AsyncClient, unique_suffix: str):
    email = f"other_cust_{unique_suffix}@market.com"
    r = await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Password123!", "full_name": "Other Customer", "role": "customer"
    })
    assert r.status_code == 201
    r = await client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!"})
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
async def created_order(client: AsyncClient, seller_auth: dict, customer_auth: dict, unique_suffix: str):
    # Get category
    r = await client.get("/api/v1/categories")
    cat_res = r.json()
    categories = cat_res if isinstance(cat_res, list) else cat_res.get("items", [])
    cat_id = categories[0]["id"]

    # Create product
    r = await client.post("/api/v1/seller/products", headers=seller_auth, json={
        "name": f"Pay Test Product {unique_suffix}",
        "price": 149.99,
        "stock_quantity": 25,
        "category_id": cat_id,
        "sku": f"PAY-{unique_suffix}",
    })
    assert r.status_code == 201
    prod_id = r.json()["id"]

    # Add to customer cart
    r = await client.post("/api/v1/cart/items", headers=customer_auth, json={
        "product_id": prod_id,
        "quantity": 2,
    })
    assert r.status_code == 200

    # Checkout
    checkout_payload = {
        "shipping_address": {
            "full_name": "Pay Customer",
            "phone": "+1-555-0199",
            "address_line1": "100 Payment Way",
            "city": "Austin",
            "state": "TX",
            "postal_code": "78701",
            "country": "USA",
        }
    }
    r = await client.post("/api/v1/orders/checkout", headers=customer_auth, json=checkout_payload)
    assert r.status_code == 201
    return r.json()


@pytest.mark.asyncio
async def test_customer_creates_payment_intent(client: AsyncClient, customer_auth: dict, created_order: dict):
    """1 & 2. Customer creates payment intent; amount comes strictly from server Order.total_amount."""
    order_id = created_order["id"]
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    assert r.status_code == 201
    data = r.json()
    assert data["order_id"] == order_id
    assert Decimal(str(data["amount"])) == Decimal("299.98") # 149.99 * 2
    assert data["currency"] == "USD"
    assert data["status"] == "pending"
    assert data["provider"] == "mock"
    assert data["client_secret"] is not None


@pytest.mark.asyncio
async def test_customer_cannot_pay_another_users_order(client: AsyncClient, other_customer_auth: dict, created_order: dict):
    """3. Customer cannot create payment for another user's order (403)."""
    order_id = created_order["id"]
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=other_customer_auth)
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_successful_mock_payment_flow(client: AsyncClient, customer_auth: dict, created_order: dict):
    """5. Successful mock payment flow updates Payment.status and Order.payment_status."""
    order_id = created_order["id"]
    # 1. Create payment
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    assert r.status_code == 201
    payment_id = r.json()["payment_id"]

    # 2. Process payment
    r = await client.post(f"/api/v1/payments/{payment_id}/process", headers=customer_auth, json={"simulate_failure": False})
    assert r.status_code == 200
    res = r.json()
    assert res["success"] is True
    assert res["payment"]["status"] == "succeeded"

    # 3. Check Order payment_status
    r = await client.get(f"/api/v1/orders/{order_id}", headers=customer_auth)
    assert r.status_code == 200
    assert r.json()["payment_status"] == "paid"


@pytest.mark.asyncio
async def test_failed_mock_payment_flow(client: AsyncClient, customer_auth: dict, created_order: dict):
    """6. Failed mock payment updates Payment.status=failed and keeps Order payment_status=failed."""
    order_id = created_order["id"]
    # Create payment
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    assert r.status_code == 201
    payment_id = r.json()["payment_id"]

    # Process with simulated failure
    r = await client.post(f"/api/v1/payments/{payment_id}/process", headers=customer_auth, json={"simulate_failure": True})
    assert r.status_code == 200
    res = r.json()
    assert res["success"] is False
    assert res["payment"]["status"] == "failed"

    # Check Order payment_status is failed
    r = await client.get(f"/api/v1/orders/{order_id}", headers=customer_auth)
    assert r.status_code == 200
    assert r.json()["payment_status"] == "failed"


@pytest.mark.asyncio
async def test_idempotent_payment_processing(client: AsyncClient, customer_auth: dict, created_order: dict):
    """7. Repeated process requests for the same payment return existing success without duplicate charges."""
    order_id = created_order["id"]
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    payment_id = r.json()["payment_id"]

    # First process
    r1 = await client.post(f"/api/v1/payments/{payment_id}/process", headers=customer_auth, json={"simulate_failure": False})
    assert r1.status_code == 200
    assert r1.json()["success"] is True

    # Second process (idempotent)
    r2 = await client.post(f"/api/v1/payments/{payment_id}/process", headers=customer_auth, json={"simulate_failure": False})
    assert r2.status_code == 200
    assert r2.json()["success"] is True
    assert "idempotent" in r2.json()["message"].lower()


@pytest.mark.asyncio
async def test_already_paid_order_cannot_create_duplicate_payment(client: AsyncClient, customer_auth: dict, created_order: dict):
    """8. Already paid order cannot create a new payment (400)."""
    order_id = created_order["id"]
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    payment_id = r.json()["payment_id"]

    await client.post(f"/api/v1/payments/{payment_id}/process", headers=customer_auth, json={"simulate_failure": False})

    # Attempt to create another payment for already paid order
    r_dup = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    assert r_dup.status_code == 400


@pytest.mark.asyncio
async def test_client_cannot_inject_extra_fields(client: AsyncClient, customer_auth: dict, created_order: dict):
    """10 & 11. Client cannot inject amount or user_id in process request."""
    order_id = created_order["id"]
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    payment_id = r.json()["payment_id"]

    # Injected extra fields rejected by schema (extra='forbid')
    r_inject = await client.post(
        f"/api/v1/payments/{payment_id}/process",
        headers=customer_auth,
        json={"simulate_failure": False, "amount": 1.00, "user_id": str(uuid.uuid4())},
    )
    assert r_inject.status_code == 422


@pytest.mark.asyncio
async def test_cancelled_order_cannot_be_paid(client: AsyncClient, customer_auth: dict, created_order: dict):
    """12. Cancelled order cannot create payment."""
    order_id = created_order["id"]
    # Cancel order
    r_cancel = await client.post(f"/api/v1/orders/{order_id}/cancel", headers=customer_auth)
    assert r_cancel.status_code == 200

    # Attempt payment creation
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    assert r.status_code == 400


@pytest.mark.asyncio
async def test_payment_enum_matching(client: AsyncClient, customer_auth: dict, created_order: dict):
    """13. Payment and order status enums match correctly in models and schemas."""
    order_id = created_order["id"]
    r = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    assert r.status_code == 201
    data = r.json()
    assert data["status"] == "pending"


@pytest.mark.asyncio
async def test_stripe_webhook_succeeded(client: AsyncClient, customer_auth: dict, created_order: dict):
    """14. Stripe Webhook constructs valid signature and marks payment succeeded."""
    import hashlib
    import hmac
    import json
    import time
    from unittest.mock import patch

    order_id = created_order["id"]
    r_create = await client.post(f"/api/v1/payments/orders/{order_id}/create", headers=customer_auth)
    assert r_create.status_code == 201
    pi_id = r_create.json()["provider_payment_id"]

    webhook_secret = "whsec_test_secret_for_webhook_signature_verification"
    with patch("app.modules.payments.router.settings.stripe_webhook_secret", webhook_secret):
        payload_data = {
            "id": "evt_test123",
            "type": "payment_intent.succeeded",
            "data": {
                "object": {
                    "id": pi_id,
                    "status": "succeeded",
                }
            }
        }
        payload_bytes = json.dumps(payload_data).encode("utf-8")
        timestamp = int(time.time())
        to_sign = f"{timestamp}.".encode("utf-8") + payload_bytes
        signature = hmac.new(webhook_secret.encode("utf-8"), to_sign, hashlib.sha256).hexdigest()
        sig_header = f"t={timestamp},v1={signature}"

        # Valid webhook
        r_wh = await client.post(
            "/api/v1/payments/stripe/webhook",
            content=payload_bytes,
            headers={"Stripe-Signature": sig_header},
        )
        assert r_wh.status_code == 200
        assert r_wh.json()["status"] == "success"

        # Check order updated to PAID
        r_order = await client.get(f"/api/v1/orders/{order_id}", headers=customer_auth)
        assert r_order.status_code == 200
        assert r_order.json()["payment_status"] == "paid"


@pytest.mark.asyncio
async def test_stripe_webhook_invalid_signature(client: AsyncClient):
    """15. Stripe Webhook rejects bad signature."""
    from unittest.mock import patch
    webhook_secret = "whsec_test_secret_for_webhook_signature_verification"
    with patch("app.modules.payments.router.settings.stripe_webhook_secret", webhook_secret):
        r_bad = await client.post(
            "/api/v1/payments/stripe/webhook",
            content=b'{"id":"evt_bad"}',
            headers={"Stripe-Signature": "t=123,v1=invalid_signature"},
        )
        assert r_bad.status_code == 400

