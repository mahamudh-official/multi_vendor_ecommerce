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


from datetime import datetime, timezone


def _parse_flexible_date(val: Optional[str]) -> Optional[datetime]:
    if not val:
        return None
    s = val.strip().replace(" ", "+")
    try:
        dt = datetime.fromisoformat(s)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        try:
            dt = datetime.strptime(s, "%Y-%m-%d")
            return dt.replace(tzinfo=timezone.utc)
        except Exception:
            return None


@order_router.get(
    "",
    response_model=OrderListResponse,
    summary="List customer orders with filtering, date range, search, and sorting",
)
async def list_orders(
    status: Optional[OrderStatus] = Query(None, description="Filter by order status"),
    from_date: Optional[str] = Query(None, description="Filter orders created on or after date (ISO or YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="Filter orders created on or before date (ISO or YYYY-MM-DD)"),
    search: Optional[str] = Query(None, description="Search by order number"),
    sort: str = Query("newest", description="Sort order: newest, oldest"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=50, description="Items per page"),
    current_user: User = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
) -> OrderListResponse:
    parsed_from = _parse_flexible_date(from_date)
    parsed_to = _parse_flexible_date(to_date)
    return await service.get_customer_orders(
        user=current_user,
        status=status,
        from_date=parsed_from,
        to_date=parsed_to,
        search=search,
        sort=sort,
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

