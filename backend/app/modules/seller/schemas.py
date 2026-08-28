import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.modules.orders.models import FulfillmentStatus, OrderStatus, PaymentStatus


# ── Product Schemas ─────────────────────────────────────────────────────────

class SellerProductCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    description: Optional[str] = Field(None, max_length=5000)
    price: Decimal = Field(..., gt=Decimal("0.00"), decimal_places=2)
    stock_quantity: int = Field(..., ge=0)
    category_id: uuid.UUID
    sku: Optional[str] = Field(None, max_length=100)
    image_url: Optional[str] = Field(None, max_length=1024)
    is_active: bool = True

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        s = v.strip()
        if not s:
            raise ValueError("Product name cannot be empty")
        return s


class SellerProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=255)
    description: Optional[str] = Field(None, max_length=5000)
    price: Optional[Decimal] = Field(None, gt=Decimal("0.00"), decimal_places=2)
    stock_quantity: Optional[int] = Field(None, ge=0)
    category_id: Optional[uuid.UUID] = None
    sku: Optional[str] = Field(None, max_length=100)
    image_url: Optional[str] = Field(None, max_length=1024)
    is_active: Optional[bool] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            if not s:
                raise ValueError("Product name cannot be empty")
            return s
        return v


class SellerProductRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    seller_id: uuid.UUID
    category_id: uuid.UUID
    category_name: Optional[str] = None
    name: str
    slug: str
    description: Optional[str] = None
    price: Decimal
    stock_quantity: int
    sku: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool
    is_low_stock: bool = False
    created_at: datetime
    updated_at: datetime


class SellerProductListResponse(BaseModel):
    items: List[SellerProductRead]
    total: int
    page: int
    page_size: int
    pages: int


# ── Order & Fulfillment Schemas ─────────────────────────────────────────────

class SellerOrderItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_id: uuid.UUID
    product_id: uuid.UUID
    product_name: str
    product_sku: Optional[str] = None
    product_image_url: Optional[str] = None
    unit_price: Decimal
    quantity: int
    line_total: Decimal
    fulfillment_status: FulfillmentStatus
    created_at: datetime


class SellerOrderListItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_number: str
    status: OrderStatus
    payment_status: PaymentStatus
    seller_item_count: int
    seller_subtotal: Decimal
    currency: str = "USD"
    customer_name: str
    created_at: datetime


class SellerOrderListResponse(BaseModel):
    items: List[SellerOrderListItemRead]
    total: int
    page: int
    page_size: int
    pages: int


class SellerOrderDetailRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_number: str
    status: OrderStatus
    payment_status: PaymentStatus
    seller_item_count: int
    seller_subtotal: Decimal
    currency: str = "USD"
    customer_name: str
    shipping_city: str
    shipping_country: str
    items: List[SellerOrderItemRead]
    created_at: datetime


class SellerOrderStatusUpdateRequest(BaseModel):
    status: FulfillmentStatus


class SellerOrderStatusUpdateResponse(BaseModel):
    order_id: uuid.UUID
    updated_item_count: int
    fulfillment_status: FulfillmentStatus
    order_status: OrderStatus
    message: str


# ── Dashboard Summary Schemas ───────────────────────────────────────────────

class SellerDashboardStats(BaseModel):
    total_products: int
    active_products: int
    inactive_products: int
    low_stock_products: int
    total_orders: int
    pending_orders: int
    processing_orders: int
    shipped_orders: int
    delivered_orders: int
    total_sales_amount: Decimal


class SellerDashboardResponse(BaseModel):
    stats: SellerDashboardStats
    recent_orders: List[SellerOrderListItemRead]
    low_stock_products: List[SellerProductRead]


# ── Detailed Analytics Schemas ──────────────────────────────────────────────

class SellerAnalyticsOverview(BaseModel):
    total_revenue: Decimal
    total_orders: int
    total_items_sold: int
    average_order_value: Decimal
    active_products: int
    low_stock_products: int
    pending_fulfillment_count: int
    delivered_order_count: int


class SellerSalesPeriodItem(BaseModel):
    period: str
    order_count: int
    item_quantity: int
    revenue: Decimal


class SellerSalesAnalyticsResponse(BaseModel):
    period_type: str
    items: List[SellerSalesPeriodItem]


class SellerProductAnalyticsItem(BaseModel):
    product_id: uuid.UUID
    product_name: str
    sku: Optional[str] = None
    revenue: Decimal
    quantity_sold: int
    current_stock: int
    average_rating: float = 0.0
    review_count: int = 0


class SellerProductAnalyticsResponse(BaseModel):
    items: List[SellerProductAnalyticsItem]

