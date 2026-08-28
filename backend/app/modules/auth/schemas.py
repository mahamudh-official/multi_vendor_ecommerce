"""
Auth Pydantic v2 schemas for authentication endpoints.
"""
import uuid
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.modules.auth.models import UserRole


class UserBase(BaseModel):
    """Shared user fields."""
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)

    @field_validator("email", mode="after")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator("full_name", mode="after")
    @classmethod
    def normalize_name(cls, v: str) -> str:
        name = v.strip()
        if len(name) < 2:
            raise ValueError("Full name must be at least 2 characters")
        return name


class RegisterRequest(BaseModel):
    """Registration request payload."""
    full_name: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128, description="Minimum 8 characters")
    role: Literal[UserRole.customer, UserRole.seller] = UserRole.customer

    @field_validator("email", mode="after")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator("full_name", mode="after")
    @classmethod
    def normalize_name(cls, v: str) -> str:
        name = v.strip()
        if len(name) < 2:
            raise ValueError("Full name must be at least 2 characters")
        return name

    @field_validator("password", mode="after")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        if len(v) > 128:
            raise ValueError("Password cannot exceed 128 characters")
        return v


class LoginRequest(BaseModel):
    """Login credentials request payload."""
    email: EmailStr
    password: str = Field(..., min_length=1)

    @field_validator("email", mode="after")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()


class UserRead(UserBase):
    """Safe user representation returned to clients."""
    id: uuid.UUID
    role: UserRole
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    seller_status: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserProfileUpdate(BaseModel):
    """Safe profile update payload for authenticated users."""
    model_config = ConfigDict(extra="forbid")

    full_name: Optional[str] = Field(None, min_length=2, max_length=255)
    phone: Optional[str] = Field(None, min_length=5, max_length=32)
    avatar_url: Optional[str] = Field(None, max_length=1024)

    @field_validator("full_name", mode="after")
    @classmethod
    def clean_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            if len(s) < 2:
                raise ValueError("Full name must be at least 2 characters long")
            return s
        return None

    @field_validator("phone", mode="after")
    @classmethod
    def clean_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            return s if s else None
        return None


class TokenResponse(BaseModel):
    """Token response including user profile and token metadata."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserRead


class RefreshTokenRequest(BaseModel):
    """Token refresh request payload."""
    refresh_token: str = Field(..., min_length=1)


class RefreshTokenResponse(BaseModel):
    """New token returned on refresh."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class MessageResponse(BaseModel):
    """Generic status response."""
    message: str
