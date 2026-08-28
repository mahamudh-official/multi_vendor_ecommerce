import logging
import uuid
from decimal import Decimal
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User, UserRole
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import NotificationService
from app.modules.orders.models import Order, OrderStatus, PaymentStatus as OrderPaymentStatus
from app.modules.orders.repository import OrderRepository
from app.modules.payments.models import Payment, PaymentStatus
from app.modules.payments.providers.base import PaymentProvider
from app.modules.payments.repository import PaymentRepository
from app.modules.payments.schemas import (
    PaymentCreateResponse,
    PaymentProcessRequest,
    PaymentProcessResponse,
    PaymentRead,
)

logger = logging.getLogger("app.payments")


class PaymentService:
    def __init__(
        self,
        payment_repo: PaymentRepository,
        order_repo: OrderRepository,
        notification_service: NotificationService,
        provider: PaymentProvider,
        session: AsyncSession,
    ) -> None:
        self.payment_repo = payment_repo
        self.order_repo = order_repo
        self.notification_service = notification_service
        self.provider = provider
        self.session = session

    async def create_payment(
        self,
        user: User,
        order_id: uuid.UUID,
    ) -> PaymentCreateResponse:
        """
        Initiates a payment for an order:
        - Validates order ownership (only the customer who placed the order can pay).
        - Validates order is not cancelled and not already paid.
        - Derives amount strictly from Order.total_amount.
        - Creates/updates payment record and creates provider intent.
        """
        # Fetch order
        order = await self.order_repo.get_by_id(order_id)
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found.",
            )

        # Ownership check
        if order.user_id != user.id and user.role != UserRole.admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only create payments for your own orders.",
            )

        # Payable state validation
        if order.status == OrderStatus.CANCELLED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot create payment for a cancelled order.",
            )

        if order.payment_status == OrderPaymentStatus.PAID.value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This order has already been paid.",
            )

        # Check for existing payment
        existing_payment = await self.payment_repo.get_by_order_id(order_id)
        if existing_payment and existing_payment.status == PaymentStatus.SUCCEEDED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A successful payment already exists for this order.",
            )

        # Server-authoritative amount from order
        amount = order.total_amount
        currency = order.currency or "USD"

        # Create intent via provider abstraction
        intent = await self.provider.create_intent(
            order_id=order.id,
            amount=amount,
            currency=currency,
            user_id=user.id,
        )

        if existing_payment:
            existing_payment.amount = amount
            existing_payment.currency = currency
            existing_payment.provider = self.provider.provider_name
            existing_payment.provider_payment_id = intent.provider_payment_id
            existing_payment.status = PaymentStatus.PENDING
            await self.session.flush()
            payment = existing_payment
        else:
            payment = await self.payment_repo.create(
                order_id=order.id,
                user_id=user.id,
                amount=amount,
                currency=currency,
                provider=self.provider.provider_name,
                provider_payment_id=intent.provider_payment_id,
                status=PaymentStatus.PENDING,
            )

        await self.session.commit()
        await self.session.refresh(payment)

        return PaymentCreateResponse(
            payment_id=payment.id,
            order_id=order.id,
            amount=payment.amount,
            currency=payment.currency,
            status=payment.status,
            provider=payment.provider,
            provider_payment_id=payment.provider_payment_id,
            client_secret=intent.client_secret,
        )

    async def process_payment(
        self,
        user: User,
        payment_id: uuid.UUID,
        data: PaymentProcessRequest,
    ) -> PaymentProcessResponse:
        """
        Executes and confirms payment processing:
        - Enforces idempotency: multiple calls for succeeded payment return success without duplicate charges or notifications.
        - Processes payment via payment provider abstraction.
        - Updates Payment.status and Order.payment_status atomically.
        - Triggers customer notifications.
        """
        payment = await self.payment_repo.get_by_id(payment_id)
        if not payment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found.",
            )

        # Authorization: Customer must own the payment (or admin)
        if payment.user_id != user.id and user.role != UserRole.admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only process payments for your own orders.",
            )

        order = await self.order_repo.get_by_id(payment.order_id)
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated order not found.",
            )

        # ── Idempotency Check ────────────────────────────────────────────────
        if payment.status == PaymentStatus.SUCCEEDED and order.payment_status == OrderPaymentStatus.PAID.value:
            return PaymentProcessResponse(
                success=True,
                payment=PaymentRead.model_validate(payment),
                message="Payment was already processed successfully (idempotent response).",
                transaction_id=payment.provider_payment_id,
            )

        # Process with provider abstraction
        provider_res = await self.provider.process_payment(
            provider_payment_id=payment.provider_payment_id or f"mock_pi_{payment.id}",
            amount=payment.amount,
            simulate_failure=data.simulate_failure,
        )

        if provider_res.success:
            payment.status = PaymentStatus.SUCCEEDED
            order.payment_status = OrderPaymentStatus.PAID.value
            await self.session.flush()

            # Trigger notification
            await self.notification_service.send_notification(
                user_id=order.user_id,
                type=NotificationType.PAYMENT_SUCCEEDED,
                title="Payment Successful",
                message=f"Your payment of ${payment.amount:.2f} for Order #{order.order_number} was successfully processed.",
                data={
                    "order_id": str(order.id),
                    "order_number": order.order_number,
                    "payment_id": str(payment.id),
                    "amount": str(payment.amount),
                },
            )

            await self.session.commit()
            await self.session.refresh(payment)

            return PaymentProcessResponse(
                success=True,
                payment=PaymentRead.model_validate(payment),
                message="Payment processed successfully.",
                transaction_id=provider_res.transaction_id,
            )
        else:
            payment.status = PaymentStatus.FAILED
            order.payment_status = OrderPaymentStatus.FAILED.value
            await self.session.flush()

            # Trigger notification
            await self.notification_service.send_notification(
                user_id=order.user_id,
                type=NotificationType.PAYMENT_FAILED,
                title="Payment Failed",
                message=f"Payment of ${payment.amount:.2f} for Order #{order.order_number} failed. {provider_res.error_message or 'Please try again.'}",
                data={
                    "order_id": str(order.id),
                    "order_number": order.order_number,
                    "payment_id": str(payment.id),
                    "error": provider_res.error_message,
                },
            )

            await self.session.commit()
            await self.session.refresh(payment)

            return PaymentProcessResponse(
                success=False,
                payment=PaymentRead.model_validate(payment),
                message=provider_res.error_message or "Payment failed.",
            )

    async def get_payment(
        self,
        user: User,
        payment_id: uuid.UUID,
    ) -> PaymentRead:
        payment = await self.payment_repo.get_by_id(payment_id)
        if not payment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found.",
            )

        if payment.user_id != user.id and user.role != UserRole.admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only view your own payments.",
            )

        return PaymentRead.model_validate(payment)

    async def get_order_payment(
        self,
        user: User,
        order_id: uuid.UUID,
    ) -> PaymentRead:
        payment = await self.payment_repo.get_by_order_id(order_id)
        if not payment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No payment found for this order.",
            )

        if payment.user_id != user.id and user.role != UserRole.admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only view payments for your own orders.",
            )

        return PaymentRead.model_validate(payment)

    async def handle_stripe_webhook(
        self,
        payload: bytes,
        sig_header: str,
        webhook_secret: str,
    ) -> dict:
        """
        Verifies Stripe webhook signature and updates Payment + Order states atomically.
        Enforces idempotency to ensure event handlers don't repeat processes.
        """
        import stripe
        try:
            event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
        except ValueError:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid payload.")
        except stripe.error.SignatureVerificationError as e:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Signature verification failed: {e}")

        event_type = event["type"]
        data_object = event["data"]["object"]

        payment_intent_id = data_object.get("id")
        if not payment_intent_id:
            return {"status": "ignored", "reason": "No payment intent ID"}

        logger.info(
            "Received Stripe Webhook event=%s payment_intent_id=%s status=%s",
            event_type,
            payment_intent_id,
            data_object.get("status"),
        )

        if event_type in ("payment_intent.succeeded", "payment_intent.payment_failed"):
            payment = await self.payment_repo.get_by_provider_payment_id(payment_intent_id)
            if not payment:
                return {"status": "ignored", "reason": f"Payment record not found for provider_payment_id: {payment_intent_id}"}

            order = await self.order_repo.get_by_id(payment.order_id)
            if not order:
                return {"status": "ignored", "reason": "Order record not found"}

            if event_type == "payment_intent.succeeded":
                if payment.status == PaymentStatus.SUCCEEDED and order.payment_status == OrderPaymentStatus.PAID:
                    return {"status": "success", "message": "Idempotent: payment was already succeeded"}

                payment.status = PaymentStatus.SUCCEEDED
                order.payment_status = OrderPaymentStatus.PAID
                await self.session.flush()

                await self.notification_service.send_notification(
                    user_id=order.user_id,
                    type=NotificationType.PAYMENT_SUCCEEDED,
                    title="Payment Successful",
                    message=f"Your payment of ${payment.amount:.2f} for Order #{order.order_number} was successfully processed.",
                    data={
                        "order_id": str(order.id),
                        "order_number": order.order_number,
                        "payment_id": str(payment.id),
                        "amount": str(payment.amount),
                    },
                )

            elif event_type == "payment_intent.payment_failed":
                if payment.status == PaymentStatus.FAILED and order.payment_status == OrderPaymentStatus.FAILED:
                    return {"status": "success", "message": "Idempotent: payment was already failed"}

                payment.status = PaymentStatus.FAILED
                order.payment_status = OrderPaymentStatus.FAILED
                await self.session.flush()

                error_msg = data_object.get("last_payment_error", {}).get("message", "Payment failed.")
                await self.notification_service.send_notification(
                    user_id=order.user_id,
                    type=NotificationType.PAYMENT_FAILED,
                    title="Payment Failed",
                    message=f"Payment of ${payment.amount:.2f} for Order #{order.order_number} failed. {error_msg}",
                    data={
                        "order_id": str(order.id),
                        "order_number": order.order_number,
                        "payment_id": str(payment.id),
                        "error": error_msg,
                    },
                )

            await self.session.commit()
            return {"status": "success", "event": event_type}

        return {"status": "ignored", "reason": f"Unhandled event type: {event_type}"}

