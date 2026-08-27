"""
REST API router for platform administration.
Protected exclusively with the require_admin dependency.
"""
import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, status

from app.modules.admin.dependencies import get_admin_service, get_audit_service, require_admin
from app.modules.admin.schemas import (
    AdminCategoryCreate,
    AdminCategoryListResponse,
    AdminCategoryRead,
    AdminCategoryUpdate,
    AdminDashboardStats,
    AdminOrderListResponse,
    AdminOrderRead,
    AdminPaymentListResponse,
    AdminPaymentRead,
    AdminProductListResponse,
    AdminProductRead,
    AdminProductUpdateStatus,
    AdminSellerListResponse,
    AdminSellerRead,
    AdminSellerUpdateStatus,
    AdminUserListResponse,
    AdminUserRead,
    AdminUserUpdateStatus,
)
from app.modules.admin.service import AdminService
from app.modules.audit.schemas import AuditLogListResponse
from app.modules.audit.service import AuditService
from app.modules.auth.models import User

router = APIRouter(
    prefix="/admin",
    tags=["admin"],
    dependencies=[Depends(require_admin)],
)


# ── 1. Dashboard ─────────────────────────────────────────────────────────────

@router.get(
    "/dashboard",
    response_model=AdminDashboardStats,
    summary="Get aggregated platform dashboard metrics",
)
async def get_dashboard(
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminDashboardStats:
    return await service.get_dashboard_stats()


# ── 2. User Management ───────────────────────────────────────────────────────

@router.get(
    "/users",
    response_model=AdminUserListResponse,
    summary="List all users with pagination, search, and filters",
)
async def list_users(
    service: Annotated[AdminService, Depends(get_admin_service)],
    search: Optional[str] = Query(None, description="Search full name or email"),
    role: Optional[str] = Query(None, description="Filter by role: customer, seller, admin"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> AdminUserListResponse:
    return await service.list_users(
        search=search,
        role=role,
        is_active=is_active,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/users/{user_id}",
    response_model=AdminUserRead,
    summary="Get detailed user profile",
)
async def get_user(
    user_id: uuid.UUID,
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminUserRead:
    return await service.get_user_details(user_id)


@router.patch(
    "/users/{user_id}/status",
    response_model=AdminUserRead,
    summary="Activate or deactivate a user account",
)
async def update_user_status(
    user_id: uuid.UUID,
    data: AdminUserUpdateStatus,
    admin_user: Annotated[User, Depends(require_admin)],
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminUserRead:
    return await service.update_user_status(
        admin_user=admin_user,
        user_id=user_id,
        is_active=data.is_active,
    )


# ── 3. Seller Management ─────────────────────────────────────────────────────

@router.get(
    "/sellers",
    response_model=AdminSellerListResponse,
    summary="List all sellers with product/order metrics and status filter",
)
async def list_sellers(
    service: Annotated[AdminService, Depends(get_admin_service)],
    search: Optional[str] = Query(None, description="Search seller name or email"),
    seller_status: Optional[str] = Query(None, description="Filter: pending, approved, suspended"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> AdminSellerListResponse:
    return await service.list_sellers(
        search=search,
        seller_status=seller_status,
        page=page,
        page_size=page_size,
    )


@router.patch(
    "/sellers/{seller_id}/status",
    response_model=AdminSellerRead,
    summary="Approve or suspend a seller account",
)
async def update_seller_status(
    seller_id: uuid.UUID,
    data: AdminSellerUpdateStatus,
    admin_user: Annotated[User, Depends(require_admin)],
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminSellerRead:
    return await service.update_seller_status(
        admin_user=admin_user,
        seller_id=seller_id,
        target_status=data.status,
    )


# ── 4. Product Moderation ────────────────────────────────────────────────────

@router.get(
    "/products",
    response_model=AdminProductListResponse,
    summary="List all products for moderation with filters",
)
async def list_products(
    service: Annotated[AdminService, Depends(get_admin_service)],
    seller_id: Optional[uuid.UUID] = Query(None, description="Filter by seller"),
    category_id: Optional[uuid.UUID] = Query(None, description="Filter by category"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    low_stock: Optional[bool] = Query(None, description="Filter products with stock <= 5"),
    search: Optional[str] = Query(None, description="Search product name or description"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> AdminProductListResponse:
    return await service.list_products(
        seller_id=seller_id,
        category_id=category_id,
        is_active=is_active,
        low_stock=low_stock,
        search=search,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/products/{product_id}",
    response_model=AdminProductRead,
    summary="Get full product moderation details",
)
async def get_product(
    product_id: uuid.UUID,
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminProductRead:
    return await service.get_product_details(product_id)


@router.patch(
    "/products/{product_id}/status",
    response_model=AdminProductRead,
    summary="Activate or deactivate a product listing",
)
async def update_product_status(
    product_id: uuid.UUID,
    data: AdminProductUpdateStatus,
    admin_user: Annotated[User, Depends(require_admin)],
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminProductRead:
    return await service.update_product_status(
        admin_user=admin_user,
        product_id=product_id,
        is_active=data.is_active,
    )


# ── 5. Category Management ───────────────────────────────────────────────────

@router.get(
    "/categories",
    response_model=AdminCategoryListResponse,
    summary="List all categories with attached product counts",
)
async def list_categories(
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminCategoryListResponse:
    return await service.list_categories()


@router.post(
    "/categories",
    response_model=AdminCategoryRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new product category",
)
async def create_category(
    data: AdminCategoryCreate,
    admin_user: Annotated[User, Depends(require_admin)],
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminCategoryRead:
    return await service.create_category(admin_user=admin_user, data=data)


@router.patch(
    "/categories/{category_id}",
    response_model=AdminCategoryRead,
    summary="Update category details",
)
async def update_category(
    category_id: uuid.UUID,
    data: AdminCategoryUpdate,
    admin_user: Annotated[User, Depends(require_admin)],
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminCategoryRead:
    return await service.update_category(
        admin_user=admin_user,
        category_id=category_id,
        data=data,
    )


@router.delete(
    "/categories/{category_id}",
    summary="Delete an empty category safely",
)
async def delete_category(
    category_id: uuid.UUID,
    admin_user: Annotated[User, Depends(require_admin)],
    service: Annotated[AdminService, Depends(get_admin_service)],
):
    return await service.delete_category(
        admin_user=admin_user,
        category_id=category_id,
    )


# ── 6. Order Management ──────────────────────────────────────────────────────

@router.get(
    "/orders",
    response_model=AdminOrderListResponse,
    summary="List all marketplace orders with comprehensive filters",
)
async def list_orders(
    service: Annotated[AdminService, Depends(get_admin_service)],
    status: Optional[str] = Query(None, description="Order status"),
    payment_status: Optional[str] = Query(None, description="Payment status"),
    customer_id: Optional[uuid.UUID] = Query(None, description="Filter by customer"),
    seller_id: Optional[uuid.UUID] = Query(None, description="Filter by seller in multi-vendor order"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> AdminOrderListResponse:
    return await service.list_orders(
        status=status,
        payment_status=payment_status,
        customer_id=customer_id,
        seller_id=seller_id,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/orders/{order_id}",
    response_model=AdminOrderRead,
    summary="Get complete multi-vendor order snapshot details",
)
async def get_order(
    order_id: uuid.UUID,
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminOrderRead:
    return await service.get_order_details(order_id)


# ── 7. Payment Monitoring ────────────────────────────────────────────────────

@router.get(
    "/payments",
    response_model=AdminPaymentListResponse,
    summary="List payment gateway transaction records",
)
async def list_payments(
    service: Annotated[AdminService, Depends(get_admin_service)],
    status: Optional[str] = Query(None, description="Payment status: pending, succeeded, failed"),
    provider: Optional[str] = Query(None, description="Provider: mock, stripe, etc."),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> AdminPaymentListResponse:
    return await service.list_payments(
        status=status,
        provider=provider,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/payments/{payment_id}",
    response_model=AdminPaymentRead,
    summary="Get detailed payment gateway record",
)
async def get_payment(
    payment_id: uuid.UUID,
    service: Annotated[AdminService, Depends(get_admin_service)],
) -> AdminPaymentRead:
    return await service.get_payment_details(payment_id)


# ── 8. Audit Logs ────────────────────────────────────────────────────────────

@router.get(
    "/audit-logs",
    response_model=AuditLogListResponse,
    summary="View immutable platform audit trail",
)
async def list_audit_logs(
    audit_service: Annotated[AuditService, Depends(get_audit_service)],
    admin_user_id: Optional[uuid.UUID] = Query(None, description="Filter by admin user"),
    action: Optional[str] = Query(None, description="Filter by action name"),
    entity_type: Optional[str] = Query(None, description="Filter by entity type"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> AuditLogListResponse:
    return await audit_service.list_audit_logs(
        admin_user_id=admin_user_id,
        action=action,
        entity_type=entity_type,
        page=page,
        page_size=page_size,
    )

