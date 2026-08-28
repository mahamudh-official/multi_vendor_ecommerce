"""
Business logic services for Categories and Products.
"""
from __future__ import annotations

import math
import re
import uuid
from decimal import Decimal
from typing import Optional

from app.common.exceptions.handlers import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
)
from app.modules.auth.models import User, UserRole
from app.modules.products.models import Category, Product
from app.modules.products.repository import CategoryRepository, ProductRepository
from app.modules.products.schemas import (
    CategoryCreate,
    CategoryRead,
    CategoryUpdate,
    PaginatedProductsResponse,
    ProductCreate,
    ProductRead,
    ProductUpdate,
)


def slugify(text: str) -> str:
    """Generate a clean URL-friendly slug from text."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    text = re.sub(r"^-+|-+$", "", text)
    return text or "item"


class CategoryService:
    """Business logic for product categories."""

    def __init__(self, repository: CategoryRepository) -> None:
        self.repository = repository

    async def list_categories(self) -> list[CategoryRead]:
        """Fetch all active categories."""
        categories = await self.repository.list_active()
        return [CategoryRead.model_validate(c) for c in categories]

    async def get_category(self, category_id: uuid.UUID) -> Category:
        """Find category by ID or raise NotFoundException."""
        category = await self.repository.get_by_id(category_id)
        if category is None or not category.is_active:
            raise NotFoundException(detail="Category not found.")
        return category

    async def create_category(self, request: CategoryCreate) -> Category:
        """Create a new category with a unique slug (admin only)."""
        base_slug = slugify(request.name)
        slug = base_slug
        counter = 2
        while await self.repository.get_by_slug(slug) is not None:
            slug = f"{base_slug}-{counter}"
            counter += 1

        return await self.repository.create(
            name=request.name,
            slug=slug,
            description=request.description,
            image_url=request.image_url,
            is_active=request.is_active,
        )

    async def update_category(
        self,
        category_id: uuid.UUID,
        request: CategoryUpdate,
    ) -> Category:
        """Update category attributes."""
        category = await self.get_category(category_id)
        update_data = request.model_dump(exclude_unset=True)

        if "name" in update_data and update_data["name"]:
            base_slug = slugify(update_data["name"])
            slug = base_slug
            counter = 2
            while True:
                existing = await self.repository.get_by_slug(slug)
                if existing is None or existing.id == category.id:
                    break
                slug = f"{base_slug}-{counter}"
                counter += 1
            update_data["slug"] = slug

        return await self.repository.update(category, update_data)

    async def delete_category(self, category_id: uuid.UUID) -> None:
        """Deactivate category."""
        category = await self.get_category(category_id)
        await self.repository.delete(category)


class ProductService:
    """Business logic for marketplace products."""

    def __init__(
        self,
        product_repo: ProductRepository,
        category_repo: CategoryRepository,
    ) -> None:
        self.product_repo = product_repo
        self.category_repo = category_repo

    async def _generate_unique_slug(self, name: str, current_id: Optional[uuid.UUID] = None) -> str:
        """Generate a collision-free URL-safe product slug."""
        base_slug = slugify(name)
        slug = base_slug
        counter = 2
        while True:
            existing = await self.product_repo.get_by_slug(slug)
            if existing is None or existing.id == current_id:
                return slug
            slug = f"{base_slug}-{counter}"
            counter += 1

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
    ) -> PaginatedProductsResponse:
        """Query paginated products with validation on sort, price ranges, and page bounds."""
        if page < 1:
            raise BadRequestException(detail="Page number must be at least 1.")
        if min_price is not None and min_price < 0:
            raise BadRequestException(detail="min_price cannot be negative.")
        if max_price is not None and max_price < 0:
            raise BadRequestException(detail="max_price cannot be negative.")
        if min_price is not None and max_price is not None and min_price > max_price:
            raise BadRequestException(detail="min_price cannot be greater than max_price.")
        if min_rating is not None and (min_rating < 1.0 or min_rating > 5.0):
            raise BadRequestException(detail="min_rating must be between 1.0 and 5.0.")

        page_size = min(max(1, page_size), 50)
        allowed_sorts = {
            "newest",
            "oldest",
            "price_low",
            "price_asc",
            "price_high",
            "price_desc",
            "rating_high",
            "rating_low",
            "popular",
            "featured",
        }
        if sort not in allowed_sorts:
            sort = "newest"

        products, total = await self.product_repo.list_products(
            page=page,
            page_size=page_size,
            search=search,
            category_id=category_id,
            seller_id=seller_id,
            min_price=min_price,
            max_price=max_price,
            min_rating=min_rating,
            in_stock=in_stock,
            is_featured=is_featured,
            sort=sort,
            include_inactive=include_inactive,
        )

        total_pages = math.ceil(total / page_size) if total > 0 else 0
        has_next = page < total_pages
        has_previous = page > 1 and total_pages > 0

        return PaginatedProductsResponse(
            items=[ProductRead.model_validate(p) for p in products],
            page=page,
            page_size=page_size,
            total=total,
            total_pages=total_pages,
            has_next=has_next,
            has_previous=has_previous,
        )

    async def get_product(
        self,
        product_id: uuid.UUID,
        include_inactive: bool = False,
    ) -> Product:
        """Find product by ID or raise NotFoundException."""
        product = await self.product_repo.get_by_id(
            product_id,
            include_inactive=include_inactive,
        )
        if product is None:
            raise NotFoundException(detail="Product not found.")
        return product

    async def create_product(
        self,
        seller: User,
        request: ProductCreate,
    ) -> Product:
        """
        Create a new product listing under the authenticated seller.
        Validates category existence and SKU uniqueness.
        """
        category = await self.category_repo.get_by_id(request.category_id)
        if category is None or not category.is_active:
            raise BadRequestException(detail="Selected category is not available.")

        if request.sku and request.sku.strip():
            existing_sku = await self.product_repo.get_by_sku(request.sku.strip())
            if existing_sku is not None:
                raise ConflictException(detail="A product with this SKU already exists.")

        slug = await self._generate_unique_slug(request.name)

        return await self.product_repo.create(
            seller_id=seller.id,
            category_id=request.category_id,
            name=request.name,
            slug=slug,
            description=request.description,
            price=request.price,
            compare_at_price=request.compare_at_price,
            stock_quantity=request.stock_quantity,
            sku=request.sku,
            image_url=request.image_url,
            is_featured=request.is_featured,
            images=request.images,
        )

    async def update_product(
        self,
        user: User,
        product_id: uuid.UUID,
        request: ProductUpdate,
    ) -> Product:
        """
        Update an existing product listing.
        Enforces product ownership (seller must own product, or user is admin).
        """
        product = await self.get_product(product_id, include_inactive=True)

        # Enforce authorization: only owning seller or admin can edit
        if product.seller_id != user.id and user.role != UserRole.admin:
            raise ForbiddenException(detail="You do not have permission to edit this product.")

        update_data = request.model_dump(exclude_unset=True)
        images = update_data.pop("images", None)

        # Validate category if changed
        if "category_id" in update_data and update_data["category_id"] is not None:
            cat = await self.category_repo.get_by_id(update_data["category_id"])
            if cat is None or not cat.is_active:
                raise BadRequestException(detail="Selected category is not available.")

        # Validate SKU uniqueness if changed
        if "sku" in update_data and update_data["sku"]:
            sku_check = await self.product_repo.get_by_sku(update_data["sku"].strip())
            if sku_check is not None and sku_check.id != product.id:
                raise ConflictException(detail="A product with this SKU already exists.")

        # Regenerate slug if name changed
        if "name" in update_data and update_data["name"]:
            update_data["slug"] = await self._generate_unique_slug(
                update_data["name"],
                current_id=product.id,
            )

        return await self.product_repo.update(product, update_data, images=images)

    async def delete_product(
        self,
        user: User,
        product_id: uuid.UUID,
    ) -> None:
        """
        Soft-delete / deactivate product.
        Enforces ownership check.
        """
        product = await self.get_product(product_id, include_inactive=True)

        if product.seller_id != user.id and user.role != UserRole.admin:
            raise ForbiddenException(detail="You do not have permission to delete this product.")

        await self.product_repo.soft_delete(product)

