"""
FastAPI router for Product Reviews and Ratings.
"""
import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, status

from app.core.config import get_settings
from app.core.rate_limiter import rate_limit
from app.modules.auth.dependencies import get_current_active_user
from app.modules.auth.models import User
from app.modules.auth.schemas import MessageResponse
from app.modules.reviews.dependencies import get_review_service
from app.modules.reviews.schemas import (
    PaginatedReviewsResponse,
    ReviewCreate,
    ReviewRead,
    ReviewUpdate,
)
from app.modules.reviews.service import ReviewService

settings = get_settings()
reviews_router = APIRouter(tags=["Reviews"])


@reviews_router.post(
    "/products/{product_id}/reviews",
    response_model=ReviewRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a verified purchase review for a product",
    dependencies=[Depends(rate_limit(max_requests=settings.rate_limit_reviews_per_minute, window_seconds=60, key_prefix="reviews_create"))],
)
async def create_product_review(
    product_id: uuid.UUID,
    request: ReviewCreate,
    service: Annotated[ReviewService, Depends(get_review_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> ReviewRead:
    """
    Submit a review and rating for a product.
    Requires that the authenticated user purchased this product in a delivered order.
    """
    return await service.create_review(
        user=current_user,
        product_id=product_id,
        request=request,
    )


@reviews_router.get(
    "/products/{product_id}/reviews",
    response_model=PaginatedReviewsResponse,
    status_code=status.HTTP_200_OK,
    summary="List approved reviews and rating distribution for a product",
)
async def list_product_reviews(
    product_id: uuid.UUID,
    service: Annotated[ReviewService, Depends(get_review_service)],
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=50, description="Items per page"),
    rating: Optional[int] = Query(None, ge=1, le=5, description="Filter by star rating (1-5)"),
    verified_only: Optional[bool] = Query(None, description="Filter only verified purchases"),
) -> PaginatedReviewsResponse:
    """Public endpoint to fetch product reviews with aggregate rating stats."""
    return await service.list_product_reviews(
        product_id=product_id,
        page=page,
        page_size=page_size,
        rating=rating,
        verified_only=verified_only,
    )


@reviews_router.get(
    "/reviews/me",
    response_model=PaginatedReviewsResponse,
    status_code=status.HTTP_200_OK,
    summary="List all reviews submitted by current user",
)
async def list_my_reviews(
    service: Annotated[ReviewService, Depends(get_review_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=50, description="Items per page"),
) -> PaginatedReviewsResponse:
    """Customer endpoint to view all their submitted reviews."""
    return await service.list_user_reviews(
        user=current_user,
        page=page,
        page_size=page_size,
    )


@reviews_router.patch(
    "/reviews/{review_id}",
    response_model=ReviewRead,
    status_code=status.HTTP_200_OK,
    summary="Update a review (Owner only)",
)
async def update_review(
    review_id: uuid.UUID,
    request: ReviewUpdate,
    service: Annotated[ReviewService, Depends(get_review_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> ReviewRead:
    """Update title, comment, or star rating of an existing review."""
    return await service.update_review(
        user=current_user,
        review_id=review_id,
        request=request,
    )


@reviews_router.delete(
    "/reviews/{review_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete a review (Owner or Admin only)",
)
async def delete_review(
    review_id: uuid.UUID,
    service: Annotated[ReviewService, Depends(get_review_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> MessageResponse:
    """Delete review."""
    await service.delete_review(
        user=current_user,
        review_id=review_id,
    )
    return MessageResponse(message="Review successfully deleted.")

