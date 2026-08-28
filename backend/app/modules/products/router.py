"""
FastAPI routers for Categories and Products.
"""
import uuid
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, status

from app.modules.auth.dependencies import (
    get_current_active_user,
    require_role,
)
from app.modules.auth.models import User, UserRole
from app.modules.auth.schemas import MessageResponse
from app.modules.products.dependencies import (
    get_category_service,
    get_product_service,
)
from app.modules.products.schemas import (
    CategoryCreate,
    CategoryRead,
    CategoryUpdate,
    PaginatedProductsResponse,
    ProductCreate,
    ProductRead,
    ProductUpdate,
)
from app.modules.products.service import CategoryService, ProductService

router = APIRouter(tags=["Products & Categories"])


# ── Categories Router ──────────────────────────────────────────────────────

@router.get(
    "/categories",
    response_model=list[CategoryRead],
    status_code=status.HTTP_200_OK,
    summary="List all active categories",
)
async def list_categories(
    category_service: Annotated[CategoryService, Depends(get_category_service)],
) -> list[CategoryRead]:
    """Public endpoint to fetch all active marketplace categories."""
    return await category_service.list_categories()


@router.get(
    "/categories/{category_id}",
    response_model=CategoryRead,
    status_code=status.HTTP_200_OK,
    summary="Get category details by ID",
)
async def get_category(
    category_id: uuid.UUID,
    category_service: Annotated[CategoryService, Depends(get_category_service)],
) -> CategoryRead:
    """Public endpoint to fetch category details by UUID."""
    category = await category_service.get_category(category_id)
    return CategoryRead.model_validate(category)


@router.post(
    "/categories",
    response_model=CategoryRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new category (Admin only)",
)
async def create_category(
    request: CategoryCreate,
    category_service: Annotated[CategoryService, Depends(get_category_service)],
    admin_user: Annotated[User, Depends(require_role(UserRole.admin))],
) -> CategoryRead:
    """Create a new product category. Admin authorization required."""
    category = await category_service.create_category(request)
    return CategoryRead.model_validate(category)


@router.patch(
    "/categories/{category_id}",
    response_model=CategoryRead,
    status_code=status.HTTP_200_OK,
    summary="Update category (Admin only)",
)
async def update_category(
    category_id: uuid.UUID,
    request: CategoryUpdate,
    category_service: Annotated[CategoryService, Depends(get_category_service)],
    admin_user: Annotated[User, Depends(require_role(UserRole.admin))],
) -> CategoryRead:
    """Update category properties. Admin authorization required."""
    category = await category_service.update_category(category_id, request)
    return CategoryRead.model_validate(category)


@router.delete(
    "/categories/{category_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Deactivate category (Admin only)",
)
async def delete_category(
    category_id: uuid.UUID,
    category_service: Annotated[CategoryService, Depends(get_category_service)],
    admin_user: Annotated[User, Depends(require_role(UserRole.admin))],
) -> MessageResponse:
    """Deactivate category. Admin authorization required."""
    await category_service.delete_category(category_id)
    return MessageResponse(message="Category successfully deactivated.")


# ── Products Router ────────────────────────────────────────────────────────

@router.get(
    "/products",
    response_model=PaginatedProductsResponse,
    status_code=status.HTTP_200_OK,
    summary="Search, filter, and paginate marketplace products",
)
async def list_products(
    product_service: Annotated[ProductService, Depends(get_product_service)],
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=50, description="Items per page"),
    search: Optional[str] = Query(None, description="Search term in name, sku, or description"),
    q: Optional[str] = Query(None, description="Search query alias for search"),
    category_id: Optional[uuid.UUID] = Query(None, description="Filter by category UUID"),
    seller_id: Optional[uuid.UUID] = Query(None, description="Filter by seller UUID"),
    min_price: Optional[Decimal] = Query(None, description="Minimum price filter"),
    max_price: Optional[Decimal] = Query(None, description="Maximum price filter"),
    min_rating: Optional[float] = Query(None, description="Minimum average rating (1.0 - 5.0)"),
    in_stock: Optional[bool] = Query(None, description="Filter for products in stock"),
    is_featured: Optional[bool] = Query(None, description="Filter featured products"),
    sort: str = Query("newest", description="Sort order: newest, oldest, price_low, price_high, rating_high, rating_low, popular, featured"),
) -> PaginatedProductsResponse:
    """
    Public endpoint to query marketplace products with search, filtering, and sorting.
    """
    query_term = q if (q is not None and q.strip()) else search
    return await product_service.list_products(
        page=page,
        page_size=page_size,
        search=query_term,
        category_id=category_id,
        seller_id=seller_id,
        min_price=min_price,
        max_price=max_price,
        min_rating=min_rating,
        in_stock=in_stock,
        is_featured=is_featured,
        sort=sort,
        include_inactive=False,
    )


@router.get(
    "/products/{product_id}",
    response_model=ProductRead,
    status_code=status.HTTP_200_OK,
    summary="Get product details by ID",
)
async def get_product(
    product_id: uuid.UUID,
    product_service: Annotated[ProductService, Depends(get_product_service)],
) -> ProductRead:
    """Public endpoint to fetch comprehensive product details including image gallery and seller info."""
    product = await product_service.get_product(product_id)
    return ProductRead.model_validate(product)


@router.post(
    "/products",
    response_model=ProductRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create product listing (Seller only)",
)
async def create_product(
    request: ProductCreate,
    product_service: Annotated[ProductService, Depends(get_product_service)],
    seller_user: Annotated[User, Depends(require_role(UserRole.seller, UserRole.admin))],
) -> ProductRead:
    """
    Create a new product listing.
    The authenticated seller is automatically attached as product owner.
    """
    product = await product_service.create_product(seller_user, request)
    return ProductRead.model_validate(product)


@router.patch(
    "/products/{product_id}",
    response_model=ProductRead,
    status_code=status.HTTP_200_OK,
    summary="Update product listing (Owner seller or Admin only)",
)
async def update_product(
    product_id: uuid.UUID,
    request: ProductUpdate,
    product_service: Annotated[ProductService, Depends(get_product_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> ProductRead:
    """
    Update product attributes and images.
    Enforces that only the owning seller or an admin can modify the product.
    """
    product = await product_service.update_product(current_user, product_id, request)
    return ProductRead.model_validate(product)


@router.delete(
    "/products/{product_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Deactivate product (Owner seller or Admin only)",
)
async def delete_product(
    product_id: uuid.UUID,
    product_service: Annotated[ProductService, Depends(get_product_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> MessageResponse:
    """
    Soft-delete / deactivate a product listing.
    Enforces product ownership.
    """
    await product_service.delete_product(current_user, product_id)
    return MessageResponse(message="Product successfully deactivated.")

