import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query, status

from app.modules.auth.dependencies import get_current_user
from app.modules.auth.models import User
from app.modules.orders.dependencies import get_order_service
from app.modules.orders.models import OrderStatus
from app.modules.orders.schemas import (
    CheckoutRequest,
    OrderCancelResponse,
    OrderListResponse,
    OrderRead,
)
from app.modules.orders.service import OrderService

order_router = APIRouter(prefix="/orders", tags=["Orders"])


@order_router.post(
    "/checkout",
    response_model=OrderRead,
    status_code=status.HTTP_201_CREATED,
    summary="Checkout and place an order",
)
async def checkout(
    data: CheckoutRequest,
    current_user: User = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
) -> OrderRead:
    return await service.checkout(user=current_user, data=data)


@order_router.get(
    "",
    response_model=OrderListResponse,
    summary="List customer orders",
)
async def list_orders(
    status: Optional[OrderStatus] = Query(None, description="Filter by order status"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=50, description="Items per page"),
    current_user: User = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
) -> OrderListResponse:
    return await service.get_customer_orders(
        user=current_user,
        status=status,
        page=page,
        page_size=page_size,
    )


@order_router.get(
    "/{order_id}",
    response_model=OrderRead,
    summary="Get order details",
)
async def get_order_details(
    order_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
) -> OrderRead:
    return await service.get_order_details(
        user=current_user,
        order_id=order_id,
    )


@order_router.post(
    "/{order_id}/cancel",
    response_model=OrderCancelResponse,
    summary="Cancel order and restore stock",
)
async def cancel_order(
    order_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
) -> OrderCancelResponse:
    return await service.cancel_order(
        user=current_user,
        order_id=order_id,
    )

