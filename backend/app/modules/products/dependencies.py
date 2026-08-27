"""
FastAPI dependencies for Category and Product modules.
"""
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.products.repository import CategoryRepository, ProductRepository
from app.modules.products.service import CategoryService, ProductService


def get_category_repository(session: AsyncSession = Depends(get_db)) -> CategoryRepository:
    """Dependency providing a CategoryRepository bound to request DB session."""
    return CategoryRepository(session)


def get_product_repository(session: AsyncSession = Depends(get_db)) -> ProductRepository:
    """Dependency providing a ProductRepository bound to request DB session."""
    return ProductRepository(session)


def get_category_service(
    category_repo: CategoryRepository = Depends(get_category_repository),
) -> CategoryService:
    """Dependency providing a CategoryService."""
    return CategoryService(category_repo)


def get_product_service(
    product_repo: ProductRepository = Depends(get_product_repository),
    category_repo: CategoryRepository = Depends(get_category_repository),
) -> ProductService:
    """Dependency providing a ProductService."""
    return ProductService(product_repo, category_repo)

