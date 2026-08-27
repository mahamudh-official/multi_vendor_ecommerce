import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.modules.payments.models import PaymentStatus


class PaymentProcessRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # Optional test parameter for deterministic automated failure testing
    simulate_failure: bool = Field(
        default=False,
        description="Used exclusively for automated tests to simulate provider payment failure.",
    )


class PaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    currency: str
    status: PaymentStatus
    provider: str
    provider_payment_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class PaymentCreateResponse(BaseModel):
    payment_id: uuid.UUID
    order_id: uuid.UUID
    amount: Decimal
    currency: str
    status: PaymentStatus
    provider: str
    provider_payment_id: Optional[str] = None
    client_secret: Optional[str] = None


class PaymentProcessResponse(BaseModel):
    success: bool
    payment: PaymentRead
    message: str
    transaction_id: Optional[str] = None

