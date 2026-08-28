"""
Data access repository for Product Reviews and Ratings.
"""
from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Dict, List, Optional, Tuple

from sqlalchemy import Numeric, and_, cast, func, not_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus
from app.modules.reviews.models import Review


class ReviewRepository:
    """Async database repository for Review entity."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_eligible_delivered_order_item(
        self,
        user_id: uuid.UUID,
        product_id: uuid.UUID,
    ) -> Optional[OrderItem]:
        """
        Find a delivered OrderItem belonging to the user for the specified product
        that has not already received a review.
        """
        # Subquery of already-reviewed order_item_ids
        reviewed_items_subq = select(Review.order_item_id)

        stmt = (
            select(OrderItem)
            .join(Order, OrderItem.order_id == Order.id)
            .where(
                Order.user_id == user_id,
                OrderItem.product_id == product_id,
                # Either order status is delivered or item fulfillment status is delivered
                (Order.status == OrderStatus.DELIVERED) | (OrderItem.fulfillment_status == FulfillmentStatus.DELIVERED),
                not_(OrderItem.id.in_(reviewed_items_subq)),
            )
            .order_by(OrderItem.created_at.desc())
            .limit(1)
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def create(
        self,
        product_id: uuid.UUID,
        user_id: uuid.UUID,
        order_item_id: uuid.UUID,
        rating: int,
        title: Optional[str] = None,
        comment: Optional[str] = None,
        is_verified_purchase: bool = True,
        is_approved: bool = True,
    ) -> Review:
        """Create and persist a new review."""
        review = Review(
            product_id=product_id,
            user_id=user_id,
            order_item_id=order_item_id,
            rating=rating,
            title=title,
            comment=comment,
            is_verified_purchase=is_verified_purchase,
            is_approved=is_approved,
        )
        self.session.add(review)
        await self.session.commit()
        await self.session.refresh(review)
        return review

    async def get_by_id(
        self,
        review_id: uuid.UUID,
    ) -> Optional[Review]:
        """Find review by ID."""
        stmt = (
            select(Review)
            .where(Review.id == review_id)
            .options(
                selectinload(Review.user),
                selectinload(Review.product),
            )
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list_product_reviews(
        self,
        product_id: uuid.UUID,
        page: int = 1,
        page_size: int = 10,
        rating: Optional[int] = None,
        verified_only: Optional[bool] = None,
        include_unapproved: bool = False,
    ) -> Tuple[List[Review], int]:
        """Query paginated reviews for a given product."""
        stmt = (
            select(Review)
            .where(Review.product_id == product_id)
            .options(
                selectinload(Review.user),
                selectinload(Review.product),
            )
        )

        if not include_unapproved:
            stmt = stmt.where(Review.is_approved.is_(True))

        if rating is not None and 1 <= rating <= 5:
            stmt = stmt.where(Review.rating == rating)

        if verified_only is True:
            stmt = stmt.where(Review.is_verified_purchase.is_(True))

        # Count total matching
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_count = (await self.session.execute(count_stmt)).scalar_one()

        # Order by newest
        stmt = stmt.order_by(Review.created_at.desc())

        # Paginate
        offset = (page - 1) * page_size
        stmt = stmt.offset(offset).limit(page_size)

        result = await self.session.execute(stmt)
        return list(result.scalars().all()), total_count

    async def get_rating_distribution_and_stats(
        self,
        product_id: uuid.UUID,
    ) -> Tuple[float, int, Dict[int, int]]:
        """
        Aggregate average rating, total review count, and star distribution counts for a product.
        """
        # Overall average & count
        stat_stmt = (
            select(
                func.coalesce(func.round(cast(func.avg(Review.rating), Numeric), 2), 0.0),
                func.count(Review.id),
            )
            .where(
                Review.product_id == product_id,
                Review.is_approved.is_(True),
            )
        )
        stat_res = await self.session.execute(stat_stmt)
        avg_rating, total_count = stat_res.one()

        # Star breakdown (1..5)
        dist_stmt = (
            select(Review.rating, func.count(Review.id))
            .where(
                Review.product_id == product_id,
                Review.is_approved.is_(True),
            )
            .group_by(Review.rating)
        )
        dist_res = await self.session.execute(dist_stmt)
        breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
        for star, count in dist_res.all():
            if star in breakdown:
                breakdown[star] = count

        return float(avg_rating or 0.0), int(total_count or 0), breakdown

    async def list_user_reviews(
        self,
        user_id: uuid.UUID,
        page: int = 1,
        page_size: int = 10,
    ) -> Tuple[List[Review], int]:
        """List reviews written by a specific user."""
        stmt = (
            select(Review)
            .where(Review.user_id == user_id)
            .options(
                selectinload(Review.user),
                selectinload(Review.product),
            )
        )

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_count = (await self.session.execute(count_stmt)).scalar_one()

        stmt = stmt.order_by(Review.created_at.desc())
        offset = (page - 1) * page_size
        stmt = stmt.offset(offset).limit(page_size)

        result = await self.session.execute(stmt)
        return list(result.scalars().all()), total_count

    async def update(
        self,
        review: Review,
        update_data: dict,
    ) -> Review:
        """Update review fields and commit."""
        for key, value in update_data.items():
            if hasattr(review, key) and value is not None:
                setattr(review, key, value)

        await self.session.commit()
        await self.session.refresh(review)
        return review

    async def delete(
        self,
        review: Review,
    ) -> None:
        """Physically delete a review."""
        await self.session.delete(review)
        await self.session.commit()

    async def list_admin_reviews(
        self,
        page: int = 1,
        page_size: int = 20,
        is_approved: Optional[bool] = None,
        product_id: Optional[uuid.UUID] = None,
        user_id: Optional[uuid.UUID] = None,
    ) -> Tuple[List[Review], int]:
        """Admin listing of reviews across the platform."""
        stmt = (
            select(Review)
            .options(
                selectinload(Review.user),
                selectinload(Review.product),
            )
        )

        if is_approved is not None:
            stmt = stmt.where(Review.is_approved.is_(is_approved))

        if product_id is not None:
            stmt = stmt.where(Review.product_id == product_id)

        if user_id is not None:
            stmt = stmt.where(Review.user_id == user_id)

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_count = (await self.session.execute(count_stmt)).scalar_one()

        stmt = stmt.order_by(Review.created_at.desc())
        offset = (page - 1) * page_size
        stmt = stmt.offset(offset).limit(page_size)

        result = await self.session.execute(stmt)
        return list(result.scalars().all()), total_count

