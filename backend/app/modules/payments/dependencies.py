from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.notifications.dependencies import get_notification_service
from app.modules.notifications.service import NotificationService
from app.modules.orders.dependencies import get_order_repository
from app.modules.orders.repository import OrderRepository
from app.modules.payments.providers.base import PaymentProvider
from app.modules.payments.providers.mock import MockPaymentProvider
from app.modules.payments.repository import PaymentRepository
from app.modules.payments.service import PaymentService


def get_payment_provider() -> PaymentProvider:
    """Returns the configured PaymentProvider instance (Mock for Step 7)."""
    return MockPaymentProvider()


def get_payment_repository(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> PaymentRepository:
    return PaymentRepository(session=session)


def get_payment_service(
    payment_repo: Annotated[PaymentRepository, Depends(get_payment_repository)],
    order_repo: Annotated[OrderRepository, Depends(get_order_repository)],
    notification_service: Annotated[NotificationService, Depends(get_notification_service)],
    provider: Annotated[PaymentProvider, Depends(get_payment_provider)],
    session: Annotated[AsyncSession, Depends(get_db)],
) -> PaymentService:
    return PaymentService(
        payment_repo=payment_repo,
        order_repo=order_repo,
        notification_service=notification_service,
        provider=provider,
        session=session,
    )

