"""
Pydantic v2 schemas for Product Reviews and Ratings.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ReviewCreate(BaseModel):
    """Payload for submitting a verified purchase product review."""
    rating: int = Field(..., ge=1, le=5, description="Star rating from 1 to 5")
    title: Optional[str] = Field(None, max_length=255, description="Headline of the review")
    comment: Optional[str] = Field(None, max_length=5000, description="Detailed feedback text")

    @field_validator("title", mode="after")
    @classmethod
    def clean_title(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            return s if s else None
        return None

    @field_validator("comment", mode="after")
    @classmethod
    def clean_comment(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            return s if s else None
        return None


class ReviewUpdate(BaseModel):
    """Payload for updating an existing product review (Owner only)."""
    rating: Optional[int] = Field(None, ge=1, le=5, description="Updated star rating")
    title: Optional[str] = Field(None, max_length=255, description="Updated review title")
    comment: Optional[str] = Field(None, max_length=5000, description="Updated review comment")

    @field_validator("title", mode="after")
    @classmethod
    def clean_title(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            return s if s else None
        return None

    @field_validator("comment", mode="after")
    @classmethod
    def clean_comment(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            s = v.strip()
            return s if s else None
        return None


class ReviewUserSummary(BaseModel):
    """Safe user profile representation in review responses (no email/passwords)."""
    id: uuid.UUID
    full_name: str

    model_config = ConfigDict(from_attributes=True)


class ReviewRead(BaseModel):
    """Public review item representation."""
    id: uuid.UUID
    product_id: uuid.UUID
    product_name: Optional[str] = None
    user: ReviewUserSummary
    order_item_id: uuid.UUID
    rating: int
    title: Optional[str]
    comment: Optional[str]
    is_verified_purchase: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RatingDistribution(BaseModel):
    """Distribution of star ratings (counts for 1 to 5 stars)."""
    one_star: int = 0
    two_star: int = 0
    three_star: int = 0
    four_star: int = 0
    five_star: int = 0


class PaginatedReviewsResponse(BaseModel):
    """Envelope for paginated product reviews with rating summary & distribution."""
    items: List[ReviewRead]
    page: int
    page_size: int
    total: int
    total_pages: int
    has_next: bool
    has_previous: bool
    average_rating: float = 0.0
    review_count: int = 0
    rating_distribution: RatingDistribution = Field(default_factory=RatingDistribution)


class AdminReviewRead(BaseModel):
    """Admin review moderation representation."""
    id: uuid.UUID
    product_id: uuid.UUID
    product_name: Optional[str] = None
    user_id: uuid.UUID
    user_name: str
    order_item_id: uuid.UUID
    rating: int
    title: Optional[str]
    comment: Optional[str]
    is_verified_purchase: bool
    is_approved: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AdminReviewStatusUpdate(BaseModel):
    """Admin toggle for review approval status."""
    is_approved: bool

