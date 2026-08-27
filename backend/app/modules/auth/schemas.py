"""
Auth Pydantic v2 schemas — stub for Step 2.
"""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field

from app.modules.auth.models import UserRole


class UserBase(BaseModel):
    """Shared user fields."""
    email: EmailStr
    full_name: str = Field(..., min_length=1, max_length=255)


class UserCreate(UserBase):
    """Schema for user registration — Step 2."""
    password: str = Field(..., min_length=8, max_length=128)
    role: UserRole = UserRole.customer


class UserRead(UserBase):
    """Schema for returning user data to clients."""
    id: uuid.UUID
    role: UserRole
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    """JWT token pair response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class LoginRequest(BaseModel):
    """Credentials for login — Step 2."""
    email: EmailStr
    password: str
