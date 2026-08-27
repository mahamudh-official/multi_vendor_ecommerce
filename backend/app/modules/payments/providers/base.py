from abc import ABC, abstractmethod
from dataclasses import dataclass
from decimal import Decimal
from typing import Optional
import uuid


@dataclass(frozen=True)
class ProviderIntentResult:
    provider_payment_id: str
    amount: Decimal
    currency: str
    status: str
    client_secret: Optional[str] = None


@dataclass(frozen=True)
class ProviderProcessResult:
    success: bool
    provider_payment_id: str
    error_message: Optional[str] = None
    transaction_id: Optional[str] = None


@dataclass(frozen=True)
class ProviderCancelResult:
    success: bool
    provider_payment_id: str
    error_message: Optional[str] = None


class PaymentProvider(ABC):
    """Abstract interface for all payment providers (Mock, Stripe, SSLCommerz, etc.)."""

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Unique identifier name for this payment provider."""
        pass

    @abstractmethod
    async def create_intent(
        self,
        order_id: uuid.UUID,
        amount: Decimal,
        currency: str,
        user_id: uuid.UUID,
    ) -> ProviderIntentResult:
        """Creates a payment intent on the provider gateway."""
        pass

    @abstractmethod
    async def process_payment(
        self,
        provider_payment_id: str,
        amount: Decimal,
        simulate_failure: bool = False,
    ) -> ProviderProcessResult:
        """Processes and captures the payment."""
        pass

    @abstractmethod
    async def cancel_payment(
        self,
        provider_payment_id: str,
    ) -> ProviderCancelResult:
        """Cancels a pending payment intent."""
        pass

