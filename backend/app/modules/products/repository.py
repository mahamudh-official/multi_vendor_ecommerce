"""
Data access repositories for Category and Product database operations.
"""
from __future__ import annotations

import re
import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import Numeric, cast, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import OrderItem
from app.modules.products.models import Category, Product, ProductImage
from app.modules.reviews.models import Review


class CategoryRepository:
    """Async database operations for Category entity."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_active(self) -> list[Category]:
        """Fetch all active categories ordered by name."""
        stmt = select(Category).where(Category.is_active.is_(True)).order_by(Category.name.asc())
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, category_id: uuid.UUID) -> Category | None:
        """Find category by UUID primary key."""
        stmt = select(Category).where(Category.id == category_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_slug(self, slug: str) -> Category | None:
        """Find category by unique slug."""
        stmt = select(Category).where(Category.slug == slug)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def create(
        self,
        name: str,
        slug: str,
        description: Optional[str] = None,
        image_url: Optional[str] = None,
        is_active: bool = True,
    ) -> Category:
        """Create and persist a new category."""
        category = Category(
            name=name.strip(),
            slug=slug,
            description=description,
            image_url=image_url,
            is_active=is_active,
        )
        self.session.add(category)
        await self.session.commit()
        await self.session.refresh(category)
        return category

    async def update(self, category: Category, update_data: dict) -> Category:
        """Update category attributes."""
        for key, value in update_data.items():
            if hasattr(category, key) and value is not None:
                setattr(category, key, value)
        await self.session.commit()
        await self.session.refresh(category)
        return category

    async def delete(self, category: Category) -> None:
        """Soft-deactivate a category."""
        category.is_active = False
        await self.session.commit()


class ProductRepository:
    """Async database operations for Product entity."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_id(
        self,
        product_id: uuid.UUID,
        include_inactive: bool = False,
    ) -> Product | None:
        """Find product by UUID primary key with eager loaded relationships and rating stats."""
        # Query product with eager relations
        stmt = (
            select(Product)
            .where(Product.id == product_id)
            .options(
                selectinload(Product.images),
            )
        )
        if not include_inactive:
            stmt = stmt.where(Product.is_active.is_(True))
        result = await self.session.execute(stmt)
        product = result.scalar_one_or_none()
        if product is None:
            return None

        # Fetch aggregate rating info for this single product
        rating_stmt = (
            select(
                func.coalesce(func.round(cast(func.avg(Review.rating), Numeric), 2), 0.0),
                func.count(Review.id),
            )
            .where(Review.product_id == product_id, Review.is_approved.is_(True))
        )
        rating_res = await self.session.execute(rating_stmt)
        avg_rating, count = rating_res.one()
        product.average_rating = float(avg_rating or 0.0)
        product.review_count = int(count or 0)
        return product

    async def get_by_slug(self, slug: str) -> Product | None:
        """Find product by unique slug."""
        stmt = select(Product).where(Product.slug == slug)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_sku(self, sku: str) -> Product | None:
        """Find product by unique SKU."""
        stmt = select(Product).where(Product.sku == sku)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list_products(
        self,
        page: int = 1,
        page_size: int = 20,
        search: Optional[str] = None,
        category_id: Optional[uuid.UUID] = None,
        seller_id: Optional[uuid.UUID] = None,
        min_price: Optional[Decimal] = None,
        max_price: Optional[Decimal] = None,
        min_rating: Optional[float] = None,
        in_stock: Optional[bool] = None,
        is_featured: Optional[bool] = None,
        sort: str = "newest",
        include_inactive: bool = False,
    ) -> tuple[list[Product], int]:
        """
        Query paginated products with advanced filtering, full search, single-query rating aggregation, and sorting.
        Returns (products_list, total_count).
        """
        # Subquery for approved review ratings per product
        rating_subq = (
            select(
                Review.product_id,
                func.coalesce(func.round(cast(func.avg(Review.rating), Numeric), 2), 0.0).label("avg_rating"),
                func.count(Review.id).label("review_count"),
            )
            .where(Review.is_approved.is_(True))
            .group_by(Review.product_id)
            .subquery()
        )

        # Subquery for popularity (real completed purchase quantity)
        sales_subq = (
            select(
                OrderItem.product_id,
                func.coalesce(func.sum(OrderItem.quantity), 0).label("total_sold"),
            )
            .group_by(OrderItem.product_id)
            .subquery()
        )

        # Base statement selecting Product and aggregate rating columns
        stmt = (
            select(
                Product,
                func.coalesce(rating_subq.c.avg_rating, 0.0).label("avg_rating"),
                func.coalesce(rating_subq.c.review_count, 0).label("review_count"),
                func.coalesce(sales_subq.c.total_sold, 0).label("total_sold"),
            )
            .outerjoin(rating_subq, Product.id == rating_subq.c.product_id)
            .outerjoin(sales_subq, Product.id == sales_subq.c.product_id)
            .options(selectinload(Product.images))
        )

        if not include_inactive:
            stmt = stmt.where(Product.is_active.is_(True))

        if category_id is not None:
            stmt = stmt.where(Product.category_id == category_id)

        if seller_id is not None:
            stmt = stmt.where(Product.seller_id == seller_id)

        if is_featured is not None:
            stmt = stmt.where(Product.is_featured.is_(is_featured))

        if in_stock is True:
            stmt = stmt.where(Product.stock_quantity > 0)

        if min_price is not None:
            stmt = stmt.where(Product.price >= min_price)

        if max_price is not None:
            stmt = stmt.where(Product.price <= max_price)

        if min_rating is not None and min_rating > 0:
            stmt = stmt.where(func.coalesce(rating_subq.c.avg_rating, 0.0) >= min_rating)

        if search and search.strip():
            term = f"%{search.strip().lower()}%"
            stmt = stmt.where(
                or_(
                    func.lower(Product.name).ilike(term),
                    func.lower(Product.sku).ilike(term),
                    func.lower(Product.description).ilike(term),
                )
            )

        # Count total matching rows
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_count = (await self.session.execute(count_stmt)).scalar_one()

        # Apply sorting
        if sort in ("price_low", "price_asc"):
            stmt = stmt.order_by(Product.price.asc(), Product.id.asc())
        elif sort in ("price_high", "price_desc"):
            stmt = stmt.order_by(Product.price.desc(), Product.id.asc())
        elif sort == "oldest":
            stmt = stmt.order_by(Product.created_at.asc(), Product.id.asc())
        elif sort == "rating_high":
            stmt = stmt.order_by(func.coalesce(rating_subq.c.avg_rating, 0.0).desc(), func.coalesce(rating_subq.c.review_count, 0).desc(), Product.created_at.desc())
        elif sort == "rating_low":
            stmt = stmt.order_by(func.coalesce(rating_subq.c.avg_rating, 0.0).asc(), Product.created_at.desc())
        elif sort == "popular":
            stmt = stmt.order_by(func.coalesce(sales_subq.c.total_sold, 0).desc(), func.coalesce(rating_subq.c.review_count, 0).desc(), Product.created_at.desc())
        elif sort == "featured":
            stmt = stmt.order_by(Product.is_featured.desc(), Product.created_at.desc())
        else:  # newest default
            stmt = stmt.order_by(Product.created_at.desc(), Product.id.asc())

        # Apply pagination
        offset = (page - 1) * page_size
        stmt = stmt.offset(offset).limit(page_size)

        result = await self.session.execute(stmt)
        rows = result.all()
        products: list[Product] = []
        for row in rows:
            prod = row[0]
            prod.average_rating = float(row[1] or 0.0)
            prod.review_count = int(row[2] or 0)
            products.append(prod)

        return products, total_count

    async def create(
        self,
        seller_id: uuid.UUID,
        category_id: uuid.UUID,
        name: str,
        slug: str,
        price: Decimal,
        description: Optional[str] = None,
        compare_at_price: Optional[Decimal] = None,
        stock_quantity: int = 0,
        sku: Optional[str] = None,
        image_url: Optional[str] = None,
        is_featured: bool = False,
        images: Optional[list[str]] = None,
    ) -> Product:
        """Create and persist a new Product listing with optional auxiliary images."""
        product = Product(
            seller_id=seller_id,
            category_id=category_id,
            name=name.strip(),
            slug=slug,
            description=description,
            price=price,
            compare_at_price=compare_at_price,
            stock_quantity=stock_quantity,
            sku=sku.strip() if sku else None,
            image_url=image_url,
            is_featured=is_featured,
            is_active=True,
        )
        self.session.add(product)
        await self.session.flush()

        if images:
            for idx, img_url in enumerate(images):
                if img_url and img_url.strip():
                    img = ProductImage(
                        product_id=product.id,
                        image_url=img_url.strip(),
                        sort_order=idx,
                    )
                    self.session.add(img)

        await self.session.commit()
        await self.session.refresh(product)
        product.average_rating = 0.0
        product.review_count = 0
        return product

    async def update(
        self,
        product: Product,
        update_data: dict,
        images: Optional[list[str]] = None,
    ) -> Product:
        """Update product attributes and optional image gallery."""
        for key, value in update_data.items():
            if hasattr(product, key) and value is not None:
                setattr(product, key, value)

        if images is not None:
            for old_img in product.images:
                await self.session.delete(old_img)

            for idx, img_url in enumerate(images):
                if img_url and img_url.strip():
                    img = ProductImage(
                        product_id=product.id,
                        image_url=img_url.strip(),
                        sort_order=idx,
                    )
                    self.session.add(img)

        await self.session.commit()
        await self.session.refresh(product)
        return product

    async def soft_delete(self, product: Product) -> None:
        """Soft-deactivate a product listing."""
        product.is_active = False
        await self.session.commit()
