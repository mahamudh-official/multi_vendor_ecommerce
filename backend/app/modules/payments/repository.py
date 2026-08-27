import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.payments.models import Payment, PaymentStatus


class PaymentRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        order_id: uuid.UUID,
        user_id: uuid.UUID,
        amount: Decimal,
        currency: str,
        provider: str = "mock",
        provider_payment_id: Optional[str] = None,
        status: PaymentStatus = PaymentStatus.PENDING,
    ) -> Payment:
        payment = Payment(
            id=uuid.uuid4(),
            order_id=order_id,
            user_id=user_id,
            amount=amount,
            currency=currency,
            provider=provider,
            provider_payment_id=provider_payment_id,
            status=status,
        )
        self.session.add(payment)
        await self.session.flush()
        return payment

    async def get_by_id(self, payment_id: uuid.UUID) -> Optional[Payment]:
        stmt = select(Payment).where(Payment.id == payment_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_order_id(self, order_id: uuid.UUID) -> Optional[Payment]:
        stmt = select(Payment).where(Payment.order_id == order_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def update_status(
        self,
        payment_id: uuid.UUID,
        status: PaymentStatus,
        provider_payment_id: Optional[str] = None,
    ) -> Optional[Payment]:
        payment = await self.get_by_id(payment_id)
        if not payment:
            return None

        payment.status = status
        if provider_payment_id:
            payment.provider_payment_id = provider_payment_id

        await self.session.flush()
        return payment

