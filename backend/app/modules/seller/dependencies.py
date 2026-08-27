from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.auth.dependencies import require_role
from app.modules.auth.models import User, UserRole
from app.modules.notifications.dependencies import get_notification_service
from app.modules.notifications.service import NotificationService
from app.modules.products.repository import CategoryRepository
from app.modules.seller.repository import SellerRepository
from app.modules.seller.service import SellerService


def get_seller_repository(
    session: AsyncSession = Depends(get_db),
) -> SellerRepository:
    return SellerRepository(session)


def get_seller_service(
    seller_repo: SellerRepository = Depends(get_seller_repository),
    notification_service: NotificationService = Depends(get_notification_service),
    session: AsyncSession = Depends(get_db),
) -> SellerService:
    category_repo = CategoryRepository(session)
    return SellerService(
        seller_repo=seller_repo,
        category_repo=category_repo,
        session=session,
        notification_service=notification_service,
    )


# Role dependency strictly requiring seller or admin role
require_seller_role = require_role(UserRole.seller, UserRole.admin)
