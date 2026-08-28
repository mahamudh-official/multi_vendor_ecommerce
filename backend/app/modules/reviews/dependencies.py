"""
FastAPI dependency injection providers for Reviews module.
"""
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.audit.dependencies import get_audit_service
from app.modules.audit.service import AuditService
from app.modules.products.dependencies import get_product_repository
from app.modules.products.repository import ProductRepository
from app.modules.reviews.repository import ReviewRepository
from app.modules.reviews.service import ReviewService


def get_review_repository(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> ReviewRepository:
    """Provide ReviewRepository instance scoped to current request session."""
    return ReviewRepository(session)


def get_review_service(
    review_repo: Annotated[ReviewRepository, Depends(get_review_repository)],
    product_repo: Annotated[ProductRepository, Depends(get_product_repository)],
    audit_service: Annotated[AuditService, Depends(get_audit_service)],
) -> ReviewService:
    """Provide ReviewService instance."""
    return ReviewService(
        review_repo=review_repo,
        product_repo=product_repo,
        audit_service=audit_service,
    )

