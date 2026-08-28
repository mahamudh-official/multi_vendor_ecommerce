"""
Pydantic schemas for the admin dashboard and platform management.
"""
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


# ── Dashboard Statistics ──────────────────────────────────────────────────────

class AdminDashboardStats(BaseModel):
    # User metrics
    total_users: int = 0
    total_customers: int = 0
    total_sellers: int = 0
    active_sellers: int = 0
    pending_sellers: int = 0

    # Product metrics
    total_products: int = 0
    active_products: int = 0
    inactive_products: int = 0
    low_stock_products: int = 0

    # Order metrics
    total_orders: int = 0
    pending_orders: int = 0
    confirmed_orders: int = 0
    processing_orders: int = 0
    shipped_orders: int = 0
    delivered_orders: int = 0
    cancelled_orders: int = 0

    # Financial & revenue metrics (only paid/successful orders)
    total_revenue: Decimal = Decimal("0.00")
    today_revenue: Decimal = Decimal("0.00")
    month_revenue: Decimal = Decimal("0.00")

    # Payment metrics
    total_payments: int = 0
    successful_payments: int = 0
    failed_payments: int = 0


# ── User Management ───────────────────────────────────────────────────────────

class AdminUserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str
    email: str
    role: str
    seller_status: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime


class AdminUserUpdateStatus(BaseModel):
    is_active: bool


class AdminUserListResponse(BaseModel):
    items: List[AdminUserRead]
    total: int
    page: int
    page_size: int


# ── Seller Management ─────────────────────────────────────────────────────────

class AdminSellerRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str
    email: str
    seller_status: str
    is_active: bool
    product_count: int = 0
    order_count: int = 0
    total_revenue: Decimal = Decimal("0.00")
    created_at: datetime


class AdminSellerUpdateStatus(BaseModel):
    status: str = Field(..., description="Target seller status: 'approved' or 'suspended'")


class AdminSellerListResponse(BaseModel):
    items: List[AdminSellerRead]
    total: int
    page: int
    page_size: int


# ── Product Moderation ────────────────────────────────────────────────────────

class AdminProductRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    seller_id: uuid.UUID
    seller_name: Optional[str] = None
    category_id: uuid.UUID
    category_name: Optional[str] = None
    name: str
    slug: str
    description: Optional[str] = None
    price: Decimal
    compare_at_price: Optional[Decimal] = None
    stock_quantity: int
    sku: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool
    is_featured: bool
    created_at: datetime
    updated_at: datetime


class AdminProductUpdateStatus(BaseModel):
    is_active: bool


class AdminProductListResponse(BaseModel):
    items: List[AdminProductRead]
    total: int
    page: int
    page_size: int


# ── Category Management ───────────────────────────────────────────────────────

class AdminCategoryCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    slug: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool = True


class AdminCategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=255)
    slug: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None


class AdminCategoryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    slug: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool
    product_count: int = 0
    created_at: datetime
    updated_at: datetime


class AdminCategoryListResponse(BaseModel):
    items: List[AdminCategoryRead]
    total: int


# ── Review Moderation ─────────────────────────────────────────────────────────

class AdminReviewRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    product_name: Optional[str] = None
    user_id: uuid.UUID
    user_name: str
    order_item_id: uuid.UUID
    rating: int
    title: Optional[str] = None
    comment: Optional[str] = None
    is_verified_purchase: bool
    is_approved: bool
    created_at: datetime
    updated_at: datetime


class AdminReviewListResponse(BaseModel):
    items: List[AdminReviewRead]
    total: int
    page: int
    page_size: int
    total_pages: int


class AdminReviewStatusUpdate(BaseModel):
    is_approved: bool



# ── Order Management ──────────────────────────────────────────────────────────

class AdminOrderItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    seller_id: uuid.UUID
    seller_name: Optional[str] = None
    product_name: str
    product_sku: Optional[str] = None
    product_image_url: Optional[str] = None
    unit_price: Decimal
    quantity: int
    line_total: Decimal
    fulfillment_status: str


class AdminOrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    customer_email: Optional[str] = None
    customer_name: Optional[str] = None
    order_number: str
    status: str
    payment_status: str
    subtotal: Decimal
    shipping_fee: Decimal
    discount_amount: Decimal
    tax_amount: Decimal
    total_amount: Decimal
    currency: str
    shipping_full_name: str
    shipping_phone: str
    shipping_address_line1: str
    shipping_address_line2: Optional[str] = None
    shipping_city: str
    shipping_state: str
    shipping_postal_code: str
    shipping_country: str
    customer_note: Optional[str] = None
    created_at: datetime
    items: List[AdminOrderItemRead]
    seller_count: int = 0


class AdminOrderListResponse(BaseModel):
    items: List[AdminOrderRead]
    total: int
    page: int
    page_size: int


# ── Payment Monitoring ────────────────────────────────────────────────────────

class AdminPaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_id: uuid.UUID
    order_number: Optional[str] = None
    user_id: uuid.UUID
    customer_email: Optional[str] = None
    amount: Decimal
    currency: str
    status: str
    provider: str
    provider_payment_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class AdminPaymentListResponse(BaseModel):
    items: List[AdminPaymentRead]
    total: int
    page: int
    page_size: int

