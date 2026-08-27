import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, status

from app.modules.auth.models import User
from app.modules.orders.models import OrderStatus
from app.modules.seller.dependencies import get_seller_service, require_seller_role
from app.modules.seller.schemas import (
    SellerDashboardResponse,
    SellerOrderDetailRead,
    SellerOrderListResponse,
    SellerOrderStatusUpdateRequest,
    SellerOrderStatusUpdateResponse,
    SellerProductCreate,
    SellerProductListResponse,
    SellerProductRead,
    SellerProductUpdate,
)
from app.modules.seller.service import SellerService

seller_router = APIRouter(prefix="/seller", tags=["Seller Dashboard & Orders"])


# ── Dashboard ───────────────────────────────────────────────────────────────

@seller_router.get(
    "/dashboard",
    response_model=SellerDashboardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get seller dashboard metrics and overview",
)
async def get_seller_dashboard(
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
) -> SellerDashboardResponse:
    return await service.get_dashboard(seller=current_seller)


# ── Seller Products ─────────────────────────────────────────────────────────

@seller_router.get(
    "/products",
    response_model=SellerProductListResponse,
    status_code=status.HTTP_200_OK,
    summary="List seller's own products with filtering and pagination",
)
async def list_seller_products(
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    search: Optional[str] = Query(None, description="Search term across name and SKU"),
    category_id: Optional[uuid.UUID] = Query(None, description="Filter by category"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    low_stock: Optional[bool] = Query(None, description="Filter low stock items"),
    sort: str = Query("newest", description="Sort order: newest, oldest, price_low, price_high, stock_low"),
) -> SellerProductListResponse:
    return await service.list_products(
        seller=current_seller,
        page=page,
        page_size=page_size,
        search=search,
        category_id=category_id,
        is_active=is_active,
        low_stock=low_stock,
        sort=sort,
    )


@seller_router.post(
    "/products",
    response_model=SellerProductRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new seller product listing",
)
async def create_seller_product(
    data: SellerProductCreate,
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
) -> SellerProductRead:
    return await service.create_product(seller=current_seller, data=data)


@seller_router.get(
    "/products/{product_id}",
    response_model=SellerProductRead,
    status_code=status.HTTP_200_OK,
    summary="Get seller's own product details",
)
async def get_seller_product(
    product_id: uuid.UUID,
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
) -> SellerProductRead:
    return await service.get_product(seller=current_seller, product_id=product_id)


@seller_router.patch(
    "/products/{product_id}",
    response_model=SellerProductRead,
    status_code=status.HTTP_200_OK,
    summary="Update seller's own product listing",
)
@seller_router.put(
    "/products/{product_id}",
    response_model=SellerProductRead,
    status_code=status.HTTP_200_OK,
    summary="Update seller's own product listing",
)
async def update_seller_product(
    product_id: uuid.UUID,
    data: SellerProductUpdate,
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
) -> SellerProductRead:
    return await service.update_product(
        seller=current_seller,
        product_id=product_id,
        data=data,
    )


@seller_router.delete(
    "/products/{product_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Deactivate seller's own product listing",
)
async def deactivate_seller_product(
    product_id: uuid.UUID,
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
) -> None:
    await service.deactivate_product(seller=current_seller, product_id=product_id)


# ── Seller Orders ───────────────────────────────────────────────────────────

@seller_router.get(
    "/orders",
    response_model=SellerOrderListResponse,
    status_code=status.HTTP_200_OK,
    summary="List orders containing products of the authenticated seller",
)
async def list_seller_orders(
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
    status_filter: Optional[OrderStatus] = Query(None, alias="status", description="Filter by order status"),
    search: Optional[str] = Query(None, description="Search by order number"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=50, description="Items per page"),
) -> SellerOrderListResponse:
    return await service.list_orders(
        seller=current_seller,
        status_filter=status_filter,
        search=search,
        page=page,
        page_size=page_size,
    )


@seller_router.get(
    "/orders/{order_id}",
    response_model=SellerOrderDetailRead,
    status_code=status.HTTP_200_OK,
    summary="Get seller order details with isolated seller items",
)
async def get_seller_order_details(
    order_id: uuid.UUID,
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
) -> SellerOrderDetailRead:
    return await service.get_order_details(
        seller=current_seller,
        order_id=order_id,
    )


@seller_router.patch(
    "/orders/{order_id}/status",
    response_model=SellerOrderStatusUpdateResponse,
    status_code=status.HTTP_200_OK,
    summary="Update fulfillment status for seller's items in order",
)
async def update_seller_order_status(
    order_id: uuid.UUID,
    data: SellerOrderStatusUpdateRequest,
    current_seller: Annotated[User, Depends(require_seller_role)],
    service: Annotated[SellerService, Depends(get_seller_service)],
) -> SellerOrderStatusUpdateResponse:
    return await service.update_order_fulfillment_status(
        seller=current_seller,
        order_id=order_id,
        new_status=data.status,
    )

