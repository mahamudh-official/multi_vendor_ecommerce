import uuid
from decimal import Decimal
from typing import Optional

from app.modules.payments.providers.base import (
    PaymentProvider,
    ProviderCancelResult,
    ProviderIntentResult,
    ProviderProcessResult,
)


class MockPaymentProvider(PaymentProvider):
    """
    Mock payment provider for sandbox/portfolio demonstration and automated testing.
    Processes payments deterministically without charging real money or requiring credentials.
    """

    @property
    def provider_name(self) -> str:
        return "mock"

    async def create_intent(
        self,
        order_id: uuid.UUID,
        amount: Decimal,
        currency: str,
        user_id: uuid.UUID,
    ) -> ProviderIntentResult:
        provider_payment_id = f"mock_pi_{uuid.uuid4().hex[:16]}"
        return ProviderIntentResult(
            provider_payment_id=provider_payment_id,
            amount=amount,
            currency=currency,
            status="pending",
            client_secret=f"mock_secret_{uuid.uuid4().hex[:24]}",
        )

    async def process_payment(
        self,
        provider_payment_id: str,
        amount: Decimal,
        simulate_failure: bool = False,
    ) -> ProviderProcessResult:
        if simulate_failure:
            return ProviderProcessResult(
                success=False,
                provider_payment_id=provider_payment_id,
                error_message="Simulated payment failure (insufficient test funds / declined).",
            )

        txn_id = f"mock_txn_{uuid.uuid4().hex[:12]}"
        return ProviderProcessResult(
            success=True,
            provider_payment_id=provider_payment_id,
            transaction_id=txn_id,
        )

    async def cancel_payment(
        self,
        provider_payment_id: str,
    ) -> ProviderCancelResult:
        return ProviderCancelResult(
            success=True,
            provider_payment_id=provider_payment_id,
        )

