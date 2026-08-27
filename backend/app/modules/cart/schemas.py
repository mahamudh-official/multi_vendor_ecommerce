"""
Pydantic v2 schemas for Cart and Wishlist operations.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


# ── Product Summary for Cart & Wishlist ────────────────────────────────────

class CartItemProductRead(BaseModel):
    """Compact product summary embedded in cart & wishlist responses."""
    id: uuid.UUID
    name: str
    slug: str
    price: Decimal
    image_url: Optional[str] = None
    stock_quantity: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


# ── Cart Schemas ───────────────────────────────────────────────────────────

class AddToCartRequest(BaseModel):
    """Payload to add an item to the shopping cart."""
    product_id: uuid.UUID
    quantity: int = Field(1, ge=1, description="Quantity to add (must be at least 1)")


class UpdateCartItemRequest(BaseModel):
    """Payload to update an existing cart item's quantity."""
    quantity: int = Field(..., ge=1, description="New quantity (must be at least 1)")


class CartItemRead(BaseModel):
    """Line item in a shopping cart with calculated line total."""
    id: uuid.UUID
    product: CartItemProductRead
    quantity: int
    line_total: Decimal
    is_available: bool = True
    stock_warning: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class CartRead(BaseModel):
    """Complete customer cart with calculated subtotal and item count."""
    id: uuid.UUID
    items: list[CartItemRead] = Field(default_factory=list)
    item_count: int = 0
    subtotal: Decimal = Decimal("0.00")

    model_config = ConfigDict(from_attributes=True)


# ── Wishlist Schemas ───────────────────────────────────────────────────────

class WishlistItemRead(BaseModel):
    """Customer wishlist entry."""
    id: uuid.UUID
    product: CartItemProductRead
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

