from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.cart.repository import CartRepository
from app.modules.notifications.dependencies import get_notification_service
from app.modules.notifications.service import NotificationService
from app.modules.orders.repository import OrderRepository
from app.modules.orders.service import OrderService
from app.modules.products.repository import ProductRepository


def get_order_repository(
    session: AsyncSession = Depends(get_db),
) -> OrderRepository:
    return OrderRepository(session)


def get_order_service(
    order_repo: OrderRepository = Depends(get_order_repository),
    notification_service: NotificationService = Depends(get_notification_service),
    session: AsyncSession = Depends(get_db),
) -> OrderService:
    cart_repo = CartRepository(session)
    product_repo = ProductRepository(session)
    return OrderService(
        order_repo=order_repo,
        cart_repo=cart_repo,
        product_repo=product_repo,
        session=session,
        notification_service=notification_service,
    )
