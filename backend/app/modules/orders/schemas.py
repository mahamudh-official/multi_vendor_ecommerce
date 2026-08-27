import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.modules.orders.models import FulfillmentStatus, OrderStatus, PaymentStatus


class ShippingAddressInput(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: str = Field(..., min_length=5, max_length=32)
    address_line1: str = Field(..., min_length=3, max_length=255)
    address_line2: Optional[str] = Field(None, max_length=255)
    city: str = Field(..., min_length=2, max_length=100)
    state: str = Field(..., min_length=2, max_length=100)
    postal_code: str = Field(..., min_length=2, max_length=32)
    country: str = Field(..., min_length=2, max_length=100)

    @field_validator("full_name", "phone", "address_line1", "city", "state", "postal_code", "country")
    @classmethod
    def not_empty_whitespace(cls, v: str) -> str:
        v_str = v.strip()
        if not v_str:
            raise ValueError("Field cannot be blank")
        return v_str


class CheckoutRequest(BaseModel):
    shipping_address: ShippingAddressInput
    customer_note: Optional[str] = Field(None, max_length=1000)
    idempotency_key: Optional[str] = Field(None, max_length=128)


class OrderItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    seller_id: uuid.UUID
    product_name: str
    product_sku: Optional[str] = None
    product_image_url: Optional[str] = None
    unit_price: Decimal
    quantity: int
    line_total: Decimal
    fulfillment_status: FulfillmentStatus = FulfillmentStatus.PENDING
    created_at: datetime


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    order_number: str
    status: OrderStatus
    payment_status: PaymentStatus
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
    items: List[OrderItemRead]
    item_count: int
    created_at: datetime
    updated_at: datetime


class OrderListItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_number: str
    status: OrderStatus
    payment_status: PaymentStatus
    item_count: int
    total_amount: Decimal
    currency: str
    created_at: datetime


class OrderListResponse(BaseModel):
    items: List[OrderListItemRead]
    total: int
    page: int
    page_size: int
    pages: int


class OrderCancelResponse(BaseModel):
    id: uuid.UUID
    order_number: str
    status: OrderStatus
    message: str
