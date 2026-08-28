"""
Business logic service for Product Reviews and Ratings.
"""
from __future__ import annotations

import math
import uuid
from typing import Optional

from app.common.exceptions.handlers import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
)
from app.modules.audit.service import AuditService
from app.modules.auth.models import User, UserRole
from app.modules.products.repository import ProductRepository
from app.modules.reviews.models import Review
from app.modules.reviews.repository import ReviewRepository
from app.modules.reviews.schemas import (
    AdminReviewRead,
    AdminReviewStatusUpdate,
    PaginatedReviewsResponse,
    RatingDistribution,
    ReviewCreate,
    ReviewRead,
    ReviewUpdate,
    ReviewUserSummary,
)


class ReviewService:
    """Service handling verified review creation, listing, ownership security, and moderation."""

    def __init__(
        self,
        review_repo: ReviewRepository,
        product_repo: ProductRepository,
        audit_service: Optional[AuditService] = None,
    ) -> None:
        self.review_repo = review_repo
        self.product_repo = product_repo
        self.audit_service = audit_service

    def _to_review_read(self, review: Review) -> ReviewRead:
        """Convert ORM Review entity to safe public ReviewRead schema."""
        user_summary = ReviewUserSummary(
            id=review.user.id if review.user else review.user_id,
            full_name=review.user.full_name if review.user else "Verified Customer",
        )
        product_name = review.product.name if review.product else None
        return ReviewRead(
            id=review.id,
            product_id=review.product_id,
            product_name=product_name,
            user=user_summary,
            order_item_id=review.order_item_id,
            rating=review.rating,
            title=review.title,
            comment=review.comment,
            is_verified_purchase=review.is_verified_purchase,
            created_at=review.created_at,
            updated_at=review.updated_at,
        )

    def _to_admin_review_read(self, review: Review) -> AdminReviewRead:
        """Convert ORM Review entity to AdminReviewRead schema."""
        return AdminReviewRead(
            id=review.id,
            product_id=review.product_id,
            product_name=review.product.name if review.product else None,
            user_id=review.user_id,
            user_name=review.user.full_name if review.user else "Unknown User",
            order_item_id=review.order_item_id,
            rating=review.rating,
            title=review.title,
            comment=review.comment,
            is_verified_purchase=review.is_verified_purchase,
            is_approved=review.is_approved,
            created_at=review.created_at,
            updated_at=review.updated_at,
        )

    async def create_review(
        self,
        user: User,
        product_id: uuid.UUID,
        request: ReviewCreate,
    ) -> ReviewRead:
        """
        Create a verified purchase review.
        Enforces that the user has a delivered order for this product
        that has not yet been reviewed.
        """
        product = await self.product_repo.get_by_id(product_id)
        if product is None:
            raise NotFoundException(detail="Product not found.")

        # Locate eligible delivered OrderItem
        order_item = await self.review_repo.get_eligible_delivered_order_item(
            user_id=user.id,
            product_id=product_id,
        )
        if order_item is None:
            raise ForbiddenException(
                detail="You can only review products from completed, delivered purchases.",
            )

        review = await self.review_repo.create(
            product_id=product_id,
            user_id=user.id,
            order_item_id=order_item.id,
            rating=request.rating,
            title=request.title,
            comment=request.comment,
            is_verified_purchase=True,
            is_approved=True,
        )

        review.user = user
        review.product = product
        return self._to_review_read(review)

    async def list_product_reviews(
        self,
        product_id: uuid.UUID,
        page: int = 1,
        page_size: int = 10,
        rating: Optional[int] = None,
        verified_only: Optional[bool] = None,
    ) -> PaginatedReviewsResponse:
        """List approved reviews with rating distribution for a product."""
        page = max(1, page)
        page_size = min(max(1, page_size), 50)

        reviews, total = await self.review_repo.list_product_reviews(
            product_id=product_id,
            page=page,
            page_size=page_size,
            rating=rating,
            verified_only=verified_only,
            include_unapproved=False,
        )

        avg_rating, review_count, distribution = await self.review_repo.get_rating_distribution_and_stats(
            product_id=product_id,
        )

        total_pages = math.ceil(total / page_size) if total > 0 else 0
        has_next = page < total_pages
        has_previous = page > 1 and total_pages > 0

        rating_dist = RatingDistribution(
            one_star=distribution.get(1, 0),
            two_star=distribution.get(2, 0),
            three_star=distribution.get(3, 0),
            four_star=distribution.get(4, 0),
            five_star=distribution.get(5, 0),
        )

        return PaginatedReviewsResponse(
            items=[self._to_review_read(r) for r in reviews],
            page=page,
            page_size=page_size,
            total=total,
            total_pages=total_pages,
            has_next=has_next,
            has_previous=has_previous,
            average_rating=avg_rating,
            review_count=review_count,
            rating_distribution=rating_dist,
        )

    async def list_user_reviews(
        self,
        user: User,
        page: int = 1,
        page_size: int = 10,
    ) -> PaginatedReviewsResponse:
        """List all reviews written by the authenticated user."""
        page = max(1, page)
        page_size = min(max(1, page_size), 50)

        reviews, total = await self.review_repo.list_user_reviews(
            user_id=user.id,
            page=page,
            page_size=page_size,
        )

        total_pages = math.ceil(total / page_size) if total > 0 else 0
        has_next = page < total_pages
        has_previous = page > 1 and total_pages > 0

        return PaginatedReviewsResponse(
            items=[self._to_review_read(r) for r in reviews],
            page=page,
            page_size=page_size,
            total=total,
            total_pages=total_pages,
            has_next=has_next,
            has_previous=has_previous,
            average_rating=0.0,
            review_count=total,
            rating_distribution=RatingDistribution(),
        )

    async def update_review(
        self,
        user: User,
        review_id: uuid.UUID,
        request: ReviewUpdate,
    ) -> ReviewRead:
        """Update review content (Owner only)."""
        review = await self.review_repo.get_by_id(review_id)
        if review is None:
            raise NotFoundException(detail="Review not found.")

        if review.user_id != user.id:
            raise ForbiddenException(detail="You do not have permission to edit this review.")

        update_data = request.model_dump(exclude_unset=True)
        updated = await self.review_repo.update(review, update_data)
        return self._to_review_read(updated)

    async def delete_review(
        self,
        user: User,
        review_id: uuid.UUID,
    ) -> None:
        """Delete a review (Owner or Admin)."""
        review = await self.review_repo.get_by_id(review_id)
        if review is None:
            raise NotFoundException(detail="Review not found.")

        if review.user_id != user.id and user.role != UserRole.admin:
            raise ForbiddenException(detail="You do not have permission to delete this review.")

        await self.review_repo.delete(review)

    async def admin_list_reviews(
        self,
        page: int = 1,
        page_size: int = 20,
        is_approved: Optional[bool] = None,
        product_id: Optional[uuid.UUID] = None,
        user_id: Optional[uuid.UUID] = None,
    ) -> tuple[list[AdminReviewRead], int, int]:
        """Admin listing of reviews."""
        page = max(1, page)
        page_size = min(max(1, page_size), 50)

        reviews, total = await self.review_repo.list_admin_reviews(
            page=page,
            page_size=page_size,
            is_approved=is_approved,
            product_id=product_id,
            user_id=user_id,
        )
        total_pages = math.ceil(total / page_size) if total > 0 else 0
        return [self._to_admin_review_read(r) for r in reviews], total, total_pages

    async def admin_moderate_review(
        self,
        admin_user: User,
        review_id: uuid.UUID,
        request: AdminReviewStatusUpdate,
        ip_address: Optional[str] = None,
    ) -> AdminReviewRead:
        """Admin moderate review approval status and create immutable audit log."""
        review = await self.review_repo.get_by_id(review_id)
        if review is None:
            raise NotFoundException(detail="Review not found.")

        updated = await self.review_repo.update(review, {"is_approved": request.is_approved})

        if self.audit_service:
            action = "review_approved" if request.is_approved else "review_rejected"
            await self.audit_service.log_action(
                admin_user_id=admin_user.id,
                action=action,
                entity_type="review",
                entity_id=str(review_id),
                metadata={
                    "product_id": str(review.product_id),
                    "user_id": str(review.user_id),
                    "is_approved": request.is_approved,
                    "rating": review.rating,
                },
            )
            await self.review_repo.session.commit()

        return self._to_admin_review_read(updated)
