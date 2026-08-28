import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.core.config import get_settings
from app.core.rate_limiter import rate_limit
from app.modules.auth.dependencies import get_current_active_user
from app.modules.auth.models import User
from app.modules.payments.dependencies import get_payment_service
from app.modules.payments.schemas import (
    PaymentCreateResponse,
    PaymentProcessRequest,
    PaymentProcessResponse,
    PaymentRead,
)
from app.modules.payments.service import PaymentService

settings = get_settings()
payments_router = APIRouter(prefix="/payments", tags=["Payments"])


@payments_router.post(
    "/orders/{order_id}/create",
    response_model=PaymentCreateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create or initialize payment for an order",
    dependencies=[Depends(rate_limit(max_requests=settings.rate_limit_payments_per_minute, window_seconds=60, key_prefix="payments_create"))],
)
async def create_payment_intent(
    order_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[PaymentService, Depends(get_payment_service)],
) -> PaymentCreateResponse:
    return await service.create_payment(
        user=current_user,
        order_id=order_id,
    )


@payments_router.post(
    "/{payment_id}/process",
    response_model=PaymentProcessResponse,
    status_code=status.HTTP_200_OK,
    summary="Process and confirm payment (idempotent)",
    dependencies=[Depends(rate_limit(max_requests=settings.rate_limit_payments_per_minute, window_seconds=60, key_prefix="payments_process"))],
)
async def process_payment(
    payment_id: uuid.UUID,
    data: PaymentProcessRequest,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[PaymentService, Depends(get_payment_service)],
) -> PaymentProcessResponse:
    return await service.process_payment(
        user=current_user,
        payment_id=payment_id,
        data=data,
    )


@payments_router.get(
    "/{payment_id}",
    response_model=PaymentRead,
    status_code=status.HTTP_200_OK,
    summary="Get payment details by payment ID",
)
async def get_payment(
    payment_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[PaymentService, Depends(get_payment_service)],
) -> PaymentRead:
    return await service.get_payment(
        user=current_user,
        payment_id=payment_id,
    )


@payments_router.get(
    "/orders/{order_id}",
    response_model=PaymentRead,
    status_code=status.HTTP_200_OK,
    summary="Get payment details for a specific order",
)
async def get_order_payment(
    order_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[PaymentService, Depends(get_payment_service)],
) -> PaymentRead:
    return await service.get_order_payment(
        user=current_user,
        order_id=order_id,
    )


@payments_router.post(
    "/stripe/webhook",
    status_code=status.HTTP_200_OK,
    summary="Stripe payment event webhook listener",
)
async def stripe_webhook(
    request: Request,
    service: Annotated[PaymentService, Depends(get_payment_service)],
) -> dict:
    sig_header = request.headers.get("Stripe-Signature")
    if not sig_header:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing Stripe-Signature header.",
        )

    payload = await request.body()
    webhook_secret = settings.stripe_webhook_secret
    if not webhook_secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Stripe webhook secret is not configured.",
        )

    return await service.handle_stripe_webhook(
        payload=payload,
        sig_header=sig_header,
        webhook_secret=webhook_secret,
    )

