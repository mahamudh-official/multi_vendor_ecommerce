import uuid
from decimal import Decimal
from typing import Optional

import stripe

from app.core.config import get_settings
from app.modules.payments.providers.base import (
    PaymentProvider,
    ProviderCancelResult,
    ProviderIntentResult,
    ProviderProcessResult,
)


class StripeProvider(PaymentProvider):
    """
    Stripe payment provider wrapper implementing PaymentProvider ABC.
    Uses Stripe API to manage payment intents with idempotency and server authority.
    """

    def __init__(self) -> None:
        settings = get_settings()
        self.api_key = settings.stripe_secret_key
        if self.api_key:
            stripe.api_key = self.api_key

    @property
    def provider_name(self) -> str:
        return "stripe"

    def _ensure_initialized(self) -> None:
        if not self.api_key:
            raise RuntimeError("Stripe API key is not configured. Please set STRIPE_SECRET_KEY.")

    async def create_intent(
        self,
        order_id: uuid.UUID,
        amount: Decimal,
        currency: str,
        user_id: uuid.UUID,
    ) -> ProviderIntentResult:
        self._ensure_initialized()

        # Stripe expects amount in smallest currency unit (cents for USD)
        amount_cents = int(amount * 100)

        # Run block in thread pool if sync, stripe SDK is currently synchronous in python
        # We wrap it to prevent blocking the async loop
        import asyncio
        loop = asyncio.get_running_loop()

        def _call_stripe():
            return stripe.PaymentIntent.create(
                amount=amount_cents,
                currency=currency.lower(),
                metadata={
                    "order_id": str(order_id),
                    "user_id": str(user_id),
                },
                idempotency_key=f"intent_{order_id}",
            )

        intent = await loop.run_in_executor(None, _call_stripe)

        return ProviderIntentResult(
            provider_payment_id=intent.id,
            amount=amount,
            currency=currency,
            status=intent.status,
            client_secret=intent.client_secret,
        )

    async def process_payment(
        self,
        provider_payment_id: str,
        amount: Decimal,
        simulate_failure: bool = False,
    ) -> ProviderProcessResult:
        self._ensure_initialized()

        import asyncio
        loop = asyncio.get_running_loop()

        # In Stripe, payments are processed and confirmed asynchronously on the client-side
        # or via webhook. This method checks the status of the intent.
        def _retrieve():
            return stripe.PaymentIntent.retrieve(provider_payment_id)

        intent = await loop.run_in_executor(None, _retrieve)

        if intent.status == "succeeded":
            return ProviderProcessResult(
                success=True,
                provider_payment_id=provider_payment_id,
                transaction_id=intent.latest_charge,
            )
        else:
            error_message = (
                intent.last_payment_error.message
                if intent.last_payment_error
                else f"Payment status: {intent.status}"
            )
            return ProviderProcessResult(
                success=False,
                provider_payment_id=provider_payment_id,
                error_message=error_message,
            )

    async def cancel_payment(
        self,
        provider_payment_id: str,
    ) -> ProviderCancelResult:
        self._ensure_initialized()

        import asyncio
        loop = asyncio.get_running_loop()

        def _cancel():
            return stripe.PaymentIntent.cancel(provider_payment_id)

        try:
            await loop.run_in_executor(None, _cancel)
            return ProviderCancelResult(
                success=True,
                provider_payment_id=provider_payment_id,
            )
        except Exception as e:
            return ProviderCancelResult(
                success=False,
                provider_payment_id=provider_payment_id,
                error_message=str(e),
            )

