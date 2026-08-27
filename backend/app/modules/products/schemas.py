"""
Pydantic v2 schemas for Category and Product operations.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


# ── Category Schemas ───────────────────────────────────────────────────────

class CategoryBase(BaseModel):
    """Base category properties."""
    name: str = Field(..., min_length=2, max_length=255)
    description: Optional[str] = None
    image_url: Optional[str] = Field(None, max_length=1024)
    is_active: bool = True

    @field_validator("name", mode="after")
    @classmethod
    def strip_name(cls, v: str) -> str:
        name = v.strip()
        if len(name) < 2:
            raise ValueError("Category name must be at least 2 characters")
        return name


class CategoryCreate(CategoryBase):
    """Payload for creating a new category (admin only)."""
    pass


class CategoryUpdate(BaseModel):
    """Payload for updating an existing category."""
    name: Optional[str] = Field(None, min_length=2, max_length=255)
    description: Optional[str] = None
    image_url: Optional[str] = Field(None, max_length=1024)
    is_active: Optional[bool] = None

    @field_validator("name", mode="after")
    @classmethod
    def strip_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            name = v.strip()
            if len(name) < 2:
                raise ValueError("Category name must be at least 2 characters")
            return name
        return v


class CategoryRead(CategoryBase):
    """Category representation returned to clients."""
    id: uuid.UUID
    slug: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ── Product Helper Schemas ─────────────────────────────────────────────────

class SellerSummary(BaseModel):
    """Safe seller information exposed on public product endpoints."""
    id: uuid.UUID
    full_name: str

    model_config = ConfigDict(from_attributes=True)


class ProductImageRead(BaseModel):
    """Auxiliary product image details."""
    id: uuid.UUID
    image_url: str
    sort_order: int

    model_config = ConfigDict(from_attributes=True)


# ── Product Schemas ────────────────────────────────────────────────────────

class ProductCreate(BaseModel):
    """Payload for creating a new product listing (seller only)."""
    name: str = Field(..., min_length=2, max_length=255)
    description: Optional[str] = None
    price: Decimal = Field(..., gt=0, decimal_places=2, max_digits=10)
    compare_at_price: Optional[Decimal] = Field(None, gt=0, decimal_places=2, max_digits=10)
    stock_quantity: int = Field(0, ge=0)
    sku: Optional[str] = Field(None, max_length=100)
    category_id: uuid.UUID
    image_url: Optional[str] = Field(None, max_length=1024)
    images: list[str] = Field(default_factory=list)
    is_featured: bool = False

    @field_validator("name", mode="after")
    @classmethod
    def strip_name(cls, v: str) -> str:
        name = v.strip()
        if len(name) < 2:
            raise ValueError("Product name must be at least 2 characters")
        return name

    @model_validator(mode="after")
    def validate_compare_at_price(self) -> ProductCreate:
        if self.compare_at_price is not None and self.compare_at_price < self.price:
            raise ValueError("compare_at_price must be greater than or equal to price")
        return self


class ProductUpdate(BaseModel):
    """Payload for updating an existing product listing."""
    name: Optional[str] = Field(None, min_length=2, max_length=255)
    description: Optional[str] = None
    price: Optional[Decimal] = Field(None, gt=0, decimal_places=2, max_digits=10)
    compare_at_price: Optional[Decimal] = Field(None, gt=0, decimal_places=2, max_digits=10)
    stock_quantity: Optional[int] = Field(None, ge=0)
    sku: Optional[str] = Field(None, max_length=100)
    category_id: Optional[uuid.UUID] = None
    image_url: Optional[str] = Field(None, max_length=1024)
    images: Optional[list[str]] = None
    is_active: Optional[bool] = None
    is_featured: Optional[bool] = None

    @field_validator("name", mode="after")
    @classmethod
    def strip_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            name = v.strip()
            if len(name) < 2:
                raise ValueError("Product name must be at least 2 characters")
            return name
        return v

    @model_validator(mode="after")
    def validate_compare_at_price(self) -> ProductUpdate:
        if self.price is not None and self.compare_at_price is not None:
            if self.compare_at_price < self.price:
                raise ValueError("compare_at_price must be greater than or equal to price")
        return self


class ProductRead(BaseModel):
    """Safe product representation returned to clients."""
    id: uuid.UUID
    name: str
    slug: str
    description: Optional[str]
    price: Decimal
    compare_at_price: Optional[Decimal]
    stock_quantity: int
    sku: Optional[str]
    image_url: Optional[str]
    is_active: bool
    is_featured: bool
    category: CategoryRead
    seller: SellerSummary
    images: list[ProductImageRead] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PaginatedProductsResponse(BaseModel):
    """Paginated list envelope for product listings."""
    items: list[ProductRead]
    page: int
    page_size: int
    total: int
    total_pages: int

