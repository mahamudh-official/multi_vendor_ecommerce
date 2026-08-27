import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, status

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

payments_router = APIRouter(prefix="/payments", tags=["Payments"])


@payments_router.post(
    "/orders/{order_id}/create",
    response_model=PaymentCreateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create or initialize payment for an order",
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

