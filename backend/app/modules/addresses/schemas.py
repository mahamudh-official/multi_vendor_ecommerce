"""
Pydantic v2 schemas for Customer Address Management.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class AddressBase(BaseModel):
    """Base address fields with validation."""
    full_name: str = Field(..., min_length=2, max_length=255, description="Recipient full name")
    phone: str = Field(..., min_length=5, max_length=32, description="Contact phone number")
    address_line_1: str = Field(..., min_length=3, max_length=255, description="Street address")
    address_line_2: Optional[str] = Field(None, max_length=255, description="Apartment, suite, unit, etc.")
    city: str = Field(..., min_length=2, max_length=100, description="City or locality")
    state: str = Field(..., min_length=2, max_length=100, description="State, province, or region")
    postal_code: str = Field(..., min_length=2, max_length=32, description="Postal or ZIP code")
    country: str = Field(..., min_length=2, max_length=100, description="Country name or ISO code")

    @field_validator(
        "full_name",
        "phone",
        "address_line_1",
        "city",
        "state",
        "postal_code",
        "country",
        mode="after",
    )
    @classmethod
    def not_empty_whitespace(cls, v: str) -> str:
        s = v.strip()
        if not s:
            raise ValueError("Field cannot be blank or whitespace-only")
        return s

    @field_validator("address_line_2", mode="after")
    @classmethod
    def clean_line_2(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            return s if s else None
        return None


class AddressCreate(AddressBase):
    """Payload for creating a new address."""
    is_default: bool = Field(default=False, description="Set as default delivery address")


class AddressUpdate(BaseModel):
    """Payload for updating an existing address."""
    model_config = ConfigDict(extra="forbid")

    full_name: Optional[str] = Field(None, min_length=2, max_length=255)
    phone: Optional[str] = Field(None, min_length=5, max_length=32)
    address_line_1: Optional[str] = Field(None, min_length=3, max_length=255)
    address_line_2: Optional[str] = Field(None, max_length=255)
    city: Optional[str] = Field(None, min_length=2, max_length=100)
    state: Optional[str] = Field(None, min_length=2, max_length=100)
    postal_code: Optional[str] = Field(None, min_length=2, max_length=32)
    country: Optional[str] = Field(None, min_length=2, max_length=100)
    is_default: Optional[bool] = None

    @field_validator(
        "full_name",
        "phone",
        "address_line_1",
        "city",
        "state",
        "postal_code",
        "country",
        mode="after",
    )
    @classmethod
    def clean_fields(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            if not s:
                raise ValueError("Field cannot be blank")
            return s
        return None


class AddressRead(AddressBase):
    """Client representation of a saved address."""
    id: uuid.UUID
    user_id: uuid.UUID
    is_default: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AddressListResponse(BaseModel):
    """List response of user's saved addresses."""
    items: List[AddressRead]
    total: int

