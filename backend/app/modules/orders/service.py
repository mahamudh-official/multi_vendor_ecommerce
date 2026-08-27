import random
import string
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional, Tuple

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User, UserRole
from app.modules.cart.repository import CartRepository
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import NotificationService
from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus, PaymentStatus
from app.modules.orders.repository import OrderRepository
from app.modules.orders.schemas import (
    CheckoutRequest,
    OrderCancelResponse,
    OrderItemRead,
    OrderListItemRead,
    OrderListResponse,
    OrderRead,
)
from app.modules.products.models import Product
from app.modules.products.repository import ProductRepository


def generate_order_number() -> str:
    """Generates a human-friendly unique order number: ORD-YYYYMMDD-XXXXXX."""
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
    random_suffix = "".join(
        random.choices(string.ascii_uppercase + string.digits, k=6)
    )
    return f"ORD-{date_str}-{random_suffix}"


class OrderService:
    def __init__(
        self,
        order_repo: OrderRepository,
        cart_repo: CartRepository,
        product_repo: ProductRepository,
        session: AsyncSession,
        notification_service: Optional[NotificationService] = None,
    ) -> None:
        self.order_repo = order_repo
        self.cart_repo = cart_repo
        self.product_repo = product_repo
        self.session = session
        self.notification_service = notification_service

    async def checkout(
        self,
        user: User,
        data: CheckoutRequest,
    ) -> OrderRead:
        """
        Executes an atomic checkout:
        1. Verifies idempotency key to prevent double submissions.
        2. Validates cart has items.
        3. Atomically checks & decrements stock for every item.
        4. Re-reads authoritative product data for immutable snapshots.
        5. Computes totals strictly server-side using Decimal.
        6. Creates Order & OrderItem snapshot rows.
        7. Empties user's cart.
        8. Commits single transaction.
        """
        # ── 1. Idempotency Check ────────────────────────────────────────────
        if data.idempotency_key:
            existing_order = await self.order_repo.get_by_idempotency_key(
                user_id=user.id,
                idempotency_key=data.idempotency_key,
            )
            if existing_order:
                return self._to_order_read(existing_order)

        # ── 2. Load Cart ────────────────────────────────────────────────────
        cart = await self.cart_repo.get_or_create_cart(user.id)
        if not cart.items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Your cart is empty.",
            )

        # ── 3. Atomically Validate & Decrement Stock, Collect Snapshots ──────
        order_items_to_create: List[OrderItem] = []
        purchased_products: List[Tuple[Product, int]] = []
        subtotal = Decimal("0.00")
        shipping_addr = data.shipping_address

        try:
            for cart_item in cart.items:
                product = await self.product_repo.get_by_id(cart_item.product_id)
                if not product or not product.is_active:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="One or more products are no longer available.",
                    )

                # Atomic stock decrement with row-level condition
                success = await self.order_repo.atomic_decrement_stock(
                    product_id=cart_item.product_id,
                    quantity=cart_item.quantity,
                )
                if not success:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Not enough stock available for '{product.name}'.",
                    )

                purchased_products.append((product, cart_item.quantity))

                # Authoritative server-side price calculation
                unit_price = Decimal(str(product.price))
                line_total = (unit_price * Decimal(cart_item.quantity)).quantize(Decimal("0.01"))
                subtotal += line_total

                # Create OrderItem with immutable snapshot
                order_item = OrderItem(
                    product_id=product.id,
                    seller_id=product.seller_id,
                    product_name=product.name,
                    product_sku=product.sku or f"SKU-{product.id.hex[:8].upper()}",
                    product_image_url=product.image_url,
                    unit_price=unit_price,
                    quantity=cart_item.quantity,
                    line_total=line_total,
                )
                order_items_to_create.append(order_item)

            # ── 4. Calculate Authoritative Totals ───────────────────────────
            # Configured standard shipping fee ($5.00 for orders under $50, free otherwise)
            shipping_fee = Decimal("0.00") if subtotal >= Decimal("50.00") else Decimal("5.00")
            tax_amount = Decimal("0.00")
            discount_amount = Decimal("0.00")
            total_amount = (subtotal + shipping_fee + tax_amount - discount_amount).quantize(
                Decimal("0.01")
            )

            # ── 5. Generate Unique Order Number ─────────────────────────────
            order_number = generate_order_number()

            # ── 6. Create Order Entity ──────────────────────────────────────
            order = Order(
                user_id=user.id,
                order_number=order_number,
                status=OrderStatus.PENDING,
                payment_status=PaymentStatus.PENDING,
                subtotal=subtotal,
                shipping_fee=shipping_fee,
                discount_amount=discount_amount,
                tax_amount=tax_amount,
                total_amount=total_amount,
                currency="USD",
                shipping_full_name=shipping_addr.full_name,
                shipping_phone=shipping_addr.phone,
                shipping_address_line1=shipping_addr.address_line1,
                shipping_address_line2=shipping_addr.address_line2,
                shipping_city=shipping_addr.city,
                shipping_state=shipping_addr.state,
                shipping_postal_code=shipping_addr.postal_code,
                shipping_country=shipping_addr.country,
                customer_note=data.customer_note,
                idempotency_key=data.idempotency_key,
                items=order_items_to_create,
            )

            self.session.add(order)
            await self.session.flush()

            # ── 7. Clear User Cart ──────────────────────────────────────────
            await self.cart_repo.clear_cart(cart.id)

            # ── 8. Dispatch Notifications ───────────────────────────────────
            if self.notification_service:
                # Customer notification
                await self.notification_service.send_notification(
                    user_id=user.id,
                    type=NotificationType.ORDER_CREATED,
                    title="Order Placed Successfully",
                    message=f"Your order #{order.order_number} for ${order.total_amount:.2f} has been placed.",
                    data={
                        "order_id": str(order.id),
                        "order_number": order.order_number,
                        "total_amount": str(order.total_amount),
                    },
                )

                # Group order items by seller for isolated seller notifications
                seller_items_map = {}
                for item in order.items:
                    seller_items_map.setdefault(item.seller_id, []).append(item)

                for seller_id, s_items in seller_items_map.items():
                    s_count = sum(i.quantity for i in s_items)
                    s_subtotal = sum(i.line_total for i in s_items)
                    await self.notification_service.send_notification(
                        user_id=seller_id,
                        type=NotificationType.SELLER_ORDER_CREATED,
                        title="New Order Received",
                        message=f"You received a new order #{order.order_number} containing {s_count} item(s) (${s_subtotal:.2f}).",
                        data={
                            "order_id": str(order.id),
                            "order_number": order.order_number,
                            "seller_item_count": s_count,
                            "seller_subtotal": str(s_subtotal),
                        },
                    )

                # Check low stock warnings for products
                for product, qty in purchased_products:
                    remaining = product.stock_quantity - qty
                    if remaining <= 5:
                        await self.notification_service.send_notification(
                            user_id=product.seller_id,
                            type=NotificationType.LOW_STOCK,
                            title="Low Stock Warning",
                            message=f"Product '{product.name}' is low in stock ({remaining} remaining).",
                            data={
                                "product_id": str(product.id),
                                "product_name": product.name,
                                "stock_quantity": remaining,
                            },
                        )

            # ── 9. Commit All Changes ───────────────────────────────────────
            await self.session.commit()
            await self.session.refresh(order)

            return self._to_order_read(order)

        except Exception:
            await self.session.rollback()
            raise

    async def get_customer_orders(
        self,
        user: User,
        status: Optional[OrderStatus] = None,
        page: int = 1,
        page_size: int = 10,
    ) -> OrderListResponse:
        """Retrieves paginated orders for the authenticated customer."""
        orders, total, pages = await self.order_repo.list_orders(
            user_id=user.id,
            status=status,
            page=page,
            page_size=page_size,
        )

        items = [
            OrderListItemRead(
                id=o.id,
                order_number=o.order_number,
                status=o.status,
                payment_status=o.payment_status,
                item_count=len(o.items),
                total_amount=o.total_amount,
                currency=o.currency,
                created_at=o.created_at,
            )
            for o in orders
        ]

        return OrderListResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )

    async def get_order_details(
        self,
        user: User,
        order_id: uuid.UUID,
    ) -> OrderRead:
        """Retrieves order details enforcing customer ownership."""
        order = await self.order_repo.get_by_id_and_user(
            order_id=order_id,
            user_id=user.id,
        )
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found.",
            )
        return self._to_order_read(order)

    async def cancel_order(
        self,
        user: User,
        order_id: uuid.UUID,
    ) -> OrderCancelResponse:
        """
        Cancels an eligible order (pending or confirmed) and restores inventory.
        """
        order = await self.order_repo.get_by_id_and_user(
            order_id=order_id,
            user_id=user.id,
        )
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found.",
            )

        if order.status not in (OrderStatus.PENDING, OrderStatus.CONFIRMED):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"This order cannot be cancelled because it is already {order.status.value}.",
            )

        try:
            # Restore stock for each item in the order and set item fulfillment status
            for item in order.items:
                await self.order_repo.atomic_increment_stock(
                    product_id=item.product_id,
                    quantity=item.quantity,
                )
                item.fulfillment_status = FulfillmentStatus.CANCELLED

            order.status = OrderStatus.CANCELLED

            if self.notification_service:
                await self.notification_service.send_notification(
                    user_id=user.id,
                    type=NotificationType.ORDER_CANCELLED,
                    title="Order Cancelled",
                    message=f"Order #{order.order_number} has been cancelled successfully.",
                    data={
                        "order_id": str(order.id),
                        "order_number": order.order_number,
                    },
                )

            await self.session.commit()
            await self.session.refresh(order)

            return OrderCancelResponse(
                id=order.id,
                order_number=order.order_number,
                status=order.status,
                message="Order cancelled successfully and stock restored.",
            )
        except Exception:
            await self.session.rollback()
            raise

    async def get_seller_orders(
        self,
        seller: User,
        page: int = 1,
        page_size: int = 10,
    ) -> OrderListResponse:
        """Query orders containing seller's items (backend foundation)."""
        orders, total, pages = await self.order_repo.list_seller_orders(
            seller_id=seller.id,
            page=page,
            page_size=page_size,
        )
        items = [
            OrderListItemRead(
                id=o.id,
                order_number=o.order_number,
                status=o.status,
                payment_status=o.payment_status,
                item_count=len([i for i in o.items if i.seller_id == seller.id]),
                total_amount=o.total_amount,
                currency=o.currency,
                created_at=o.created_at,
            )
            for o in orders
        ]
        return OrderListResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )

    def _to_order_read(self, order: Order) -> OrderRead:
        item_reads = [
            OrderItemRead(
                id=item.id,
                product_id=item.product_id,
                seller_id=item.seller_id,
                product_name=item.product_name,
                product_sku=item.product_sku,
                product_image_url=item.product_image_url,
                unit_price=item.unit_price,
                quantity=item.quantity,
                line_total=item.line_total,
                fulfillment_status=item.fulfillment_status,
                created_at=item.created_at,
            )
            for item in order.items
        ]

        return OrderRead(
            id=order.id,
            user_id=order.user_id,
            order_number=order.order_number,
            status=order.status,
            payment_status=order.payment_status,
            subtotal=order.subtotal,
            shipping_fee=order.shipping_fee,
            discount_amount=order.discount_amount,
            tax_amount=order.tax_amount,
            total_amount=order.total_amount,
            currency=order.currency,
            shipping_full_name=order.shipping_full_name,
            shipping_phone=order.shipping_phone,
            shipping_address_line1=order.shipping_address_line1,
            shipping_address_line2=order.shipping_address_line2,
            shipping_city=order.shipping_city,
            shipping_state=order.shipping_state,
            shipping_postal_code=order.shipping_postal_code,
            shipping_country=order.shipping_country,
            customer_note=order.customer_note,
            items=item_reads,
            item_count=len(item_reads),
            created_at=order.created_at,
            updated_at=order.updated_at,
        )
