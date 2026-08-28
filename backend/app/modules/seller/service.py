import re
import uuid
from decimal import Decimal
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import NotificationService
from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus
from app.modules.products.models import Category, Product, ProductImage
from app.modules.products.repository import CategoryRepository
from app.modules.seller.constants import DEFAULT_LOW_STOCK_THRESHOLD
from app.modules.seller.repository import SellerRepository
from app.modules.seller.schemas import (
    SellerAnalyticsOverview,
    SellerDashboardResponse,
    SellerOrderDetailRead,
    SellerOrderItemRead,
    SellerOrderListItemRead,
    SellerOrderListResponse,
    SellerOrderStatusUpdateResponse,
    SellerProductAnalyticsResponse,
    SellerProductCreate,
    SellerProductListResponse,
    SellerProductRead,
    SellerProductUpdate,
    SellerSalesAnalyticsResponse,
)


def _slugify(text: str) -> str:
    """Generate a URL-friendly slug from string."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return re.sub(r"^-+|-+$", "", text)


# Valid state machine transitions for seller item fulfillment
ALLOWED_TRANSITIONS = {
    FulfillmentStatus.PENDING: {FulfillmentStatus.CONFIRMED},
    FulfillmentStatus.CONFIRMED: {FulfillmentStatus.PROCESSING},
    FulfillmentStatus.PROCESSING: {FulfillmentStatus.SHIPPED},
    FulfillmentStatus.SHIPPED: {FulfillmentStatus.DELIVERED},
    FulfillmentStatus.DELIVERED: set(),
    FulfillmentStatus.CANCELLED: set(),
}


class SellerService:
    def __init__(
        self,
        seller_repo: SellerRepository,
        category_repo: CategoryRepository,
        session: AsyncSession,
        notification_service: Optional[NotificationService] = None,
    ) -> None:
        self.seller_repo = seller_repo
        self.category_repo = category_repo
        self.session = session
        self.notification_service = notification_service

    # ── Dashboard ───────────────────────────────────────────────────────────

    async def get_dashboard(
        self,
        seller: User,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerDashboardResponse:
        """Fetch dashboard statistics, recent orders, and low-stock products."""
        stats = await self.seller_repo.get_dashboard_stats(
            seller_id=seller.id,
            low_stock_threshold=low_stock_threshold,
        )

        recent_orders_raw, _, _ = await self.seller_repo.list_seller_orders(
            seller_id=seller.id,
            page=1,
            page_size=5,
        )
        recent_orders = [
            self._to_seller_order_list_item(order, count, subtotal)
            for order, count, subtotal in recent_orders_raw
        ]

        low_stock_raw, _, _ = await self.seller_repo.list_seller_products(
            seller_id=seller.id,
            low_stock=True,
            is_active=True,
            page=1,
            page_size=5,
            low_stock_threshold=low_stock_threshold,
        )
        low_stock_products = [
            self._to_seller_product_read(p, low_stock_threshold)
            for p in low_stock_raw
        ]

        return SellerDashboardResponse(
            stats=stats,
            recent_orders=recent_orders,
            low_stock_products=low_stock_products,
        )

    # ── Analytics ───────────────────────────────────────────────────────────

    async def get_analytics_overview(
        self,
        seller: User,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerAnalyticsOverview:
        """Fetch high-level seller revenue, order volume, and fulfillment KPIs."""
        return await self.seller_repo.get_analytics_overview(
            seller_id=seller.id,
            low_stock_threshold=low_stock_threshold,
        )

    async def get_sales_analytics(
        self,
        seller: User,
        period: str = "daily",
    ) -> SellerSalesAnalyticsResponse:
        """Fetch timeline sales aggregation for the seller."""
        normalized_period = period.lower().strip()
        if normalized_period not in ("daily", "weekly", "monthly"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid period. Must be one of: 'daily', 'weekly', 'monthly'.",
            )
        items = await self.seller_repo.get_sales_analytics(
            seller_id=seller.id,
            period=normalized_period,
        )
        return SellerSalesAnalyticsResponse(
            period_type=normalized_period,
            items=items,
        )

    async def get_product_analytics(
        self,
        seller: User,
        limit: int = 10,
    ) -> SellerProductAnalyticsResponse:
        """Fetch top-selling product ranking by revenue and units for the seller."""
        items = await self.seller_repo.get_product_analytics(
            seller_id=seller.id,
            limit=limit,
        )
        return SellerProductAnalyticsResponse(items=items)

    # ── Seller Products ─────────────────────────────────────────────────────

    async def list_products(
        self,
        seller: User,
        page: int = 1,
        page_size: int = 20,
        search: Optional[str] = None,
        category_id: Optional[uuid.UUID] = None,
        is_active: Optional[bool] = None,
        low_stock: Optional[bool] = None,
        sort: str = "newest",
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerProductListResponse:
        products, total, pages = await self.seller_repo.list_seller_products(
            seller_id=seller.id,
            page=page,
            page_size=page_size,
            search=search,
            category_id=category_id,
            is_active=is_active,
            low_stock=low_stock,
            sort=sort,
            low_stock_threshold=low_stock_threshold,
        )

        items = [
            self._to_seller_product_read(p, low_stock_threshold) for p in products
        ]

        return SellerProductListResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )

    async def get_product(
        self,
        seller: User,
        product_id: uuid.UUID,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerProductRead:
        product = await self.seller_repo.get_seller_product(
            seller_id=seller.id,
            product_id=product_id,
        )
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found.",
            )
        return self._to_seller_product_read(product, low_stock_threshold)

    async def create_product(
        self,
        seller: User,
        data: SellerProductCreate,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerProductRead:
        if seller.seller_status == "suspended":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Seller account is suspended. You cannot create products.",
            )

        # Validate Category
        category = await self.category_repo.get_by_id(data.category_id)
        if not category or not category.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid category.",
            )

        slug_base = _slugify(data.name)
        slug = f"{slug_base}-{uuid.uuid4().hex[:6]}"

        product = Product(
            seller_id=seller.id,
            category_id=data.category_id,
            name=data.name.strip(),
            slug=slug,
            description=data.description,
            price=data.price,
            stock_quantity=data.stock_quantity,
            sku=data.sku.strip() if data.sku else None,
            is_active=data.is_active,
        )

        if data.image_url:
            product.images.append(
                ProductImage(
                    image_url=data.image_url,
                    is_primary=True,
                    display_order=0,
                )
            )

        created_product = await self.seller_repo.create_product(product)
        await self.session.commit()
        return self._to_seller_product_read(created_product, low_stock_threshold)

    async def update_product(
        self,
        seller: User,
        product_id: uuid.UUID,
        data: SellerProductUpdate,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerProductRead:
        if seller.seller_status == "suspended":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Seller account is suspended. You cannot edit products.",
            )

        product = await self.seller_repo.get_seller_product(
            seller_id=seller.id,
            product_id=product_id,
        )
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found or you do not have permission to edit it.",
            )

        if data.category_id is not None and data.category_id != product.category_id:
            cat = await self.category_repo.get_by_id(data.category_id)
            if not cat or not cat.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid category.",
                )
            product.category_id = data.category_id

        if data.name is not None:
            product.name = data.name.strip()
        if data.description is not None:
            product.description = data.description
        if data.price is not None:
            product.price = data.price
        if data.stock_quantity is not None:
            product.stock_quantity = data.stock_quantity
        if data.sku is not None:
            product.sku = data.sku.strip() if data.sku else None
        if data.is_active is not None:
            product.is_active = data.is_active

        if data.image_url is not None:
            if product.images:
                product.images[0].image_url = data.image_url
            else:
                product.images.append(
                    ProductImage(
                        image_url=data.image_url,
                        is_primary=True,
                        display_order=0,
                    )
                )

        updated = await self.seller_repo.update_product(product)
        await self.session.commit()
        return self._to_seller_product_read(updated, low_stock_threshold)

    async def deactivate_product(
        self,
        seller: User,
        product_id: uuid.UUID,
    ) -> None:
        if seller.seller_status == "suspended":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Seller account is suspended. You cannot modify products.",
            )

        product = await self.seller_repo.get_seller_product(
            seller_id=seller.id,
            product_id=product_id,
        )
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found or you do not have permission to modify it.",
            )

        product.is_active = False
        await self.seller_repo.update_product(product)
        await self.session.commit()

    # ── Seller Orders ───────────────────────────────────────────────────────

    async def list_orders(
        self,
        seller: User,
        status_filter: Optional[OrderStatus] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 10,
    ) -> SellerOrderListResponse:
        orders_raw, total, pages = await self.seller_repo.list_seller_orders(
            seller_id=seller.id,
            status=status_filter,
            search=search,
            page=page,
            page_size=page_size,
        )

        items = [
            self._to_seller_order_list_item(order, count, subtotal)
            for order, count, subtotal in orders_raw
        ]

        return SellerOrderListResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )

    async def get_order_details(
        self,
        seller: User,
        order_id: uuid.UUID,
    ) -> SellerOrderDetailRead:
        result = await self.seller_repo.get_seller_order_with_items(
            seller_id=seller.id,
            order_id=order_id,
        )
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found or contains no items for this seller.",
            )

        order, items = result
        seller_subtotal = sum(i.line_total for i in items)
        customer_name = order.user.full_name if order.user else order.shipping_full_name

        item_reads = [
            SellerOrderItemRead(
                id=item.id,
                order_id=item.order_id,
                product_id=item.product_id,
                product_name=item.product_name,
                product_sku=item.product_sku,
                product_image_url=item.product_image_url,
                unit_price=item.unit_price,
                quantity=item.quantity,
                line_total=item.line_total,
                fulfillment_status=item.fulfillment_status,
                created_at=item.created_at,
            )
            for item in items
        ]

        return SellerOrderDetailRead(
            id=order.id,
            order_number=order.order_number,
            status=order.status,
            payment_status=order.payment_status,
            seller_item_count=len(items),
            seller_subtotal=Decimal(str(seller_subtotal)),
            currency=order.currency,
            customer_name=customer_name,
            shipping_city=order.shipping_city,
            shipping_country=order.shipping_country,
            items=item_reads,
            created_at=order.created_at,
        )

    async def update_order_fulfillment_status(
        self,
        seller: User,
        order_id: uuid.UUID,
        new_status: FulfillmentStatus,
    ) -> SellerOrderStatusUpdateResponse:
        """
        Validates state machine transitions and updates fulfillment_status
        for seller's items in the specified order.
        """
        if seller.seller_status == "suspended":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Seller account is suspended. You cannot update fulfillment status.",
            )

        result = await self.seller_repo.get_seller_order_with_items(
            seller_id=seller.id,
            order_id=order_id,
        )
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found or contains no items for this seller.",
            )

        order, items = result

        if order.status == OrderStatus.CANCELLED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot update fulfillment for a cancelled order.",
            )

        # Enforce transition rules per item
        for item in items:
            current_status = item.fulfillment_status
            allowed_next = ALLOWED_TRANSITIONS.get(current_status, set())
            if new_status not in allowed_next:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        f"Invalid fulfillment transition from '{current_status.value}' "
                        f"to '{new_status.value}'."
                    ),
                )

        try:
            # Update only seller's items
            updated_count = await self.seller_repo.update_seller_items_fulfillment(
                seller_id=seller.id,
                order_id=order_id,
                new_status=new_status,
            )

            # Harmonize top-level order status safely
            overall_status = await self.seller_repo.synchronize_overall_order_status(
                order_id=order_id
            )

            # Trigger fulfillment notification to customer
            if self.notification_service:
                status_type_map = {
                    FulfillmentStatus.CONFIRMED: (
                        NotificationType.ORDER_CONFIRMED,
                        "Order Confirmed",
                        f"Items from your order #{order.order_number} have been confirmed by the seller.",
                    ),
                    FulfillmentStatus.PROCESSING: (
                        NotificationType.ORDER_PROCESSING,
                        "Order Processing",
                        f"Items from your order #{order.order_number} are now being packed and processed.",
                    ),
                    FulfillmentStatus.SHIPPED: (
                        NotificationType.ORDER_SHIPPED,
                        "Order Shipped",
                        f"Items from your order #{order.order_number} have been shipped.",
                    ),
                    FulfillmentStatus.DELIVERED: (
                        NotificationType.ORDER_DELIVERED,
                        "Order Delivered",
                        f"Items from your order #{order.order_number} have been delivered.",
                    ),
                }
                if new_status in status_type_map:
                    n_type, n_title, n_msg = status_type_map[new_status]
                    await self.notification_service.send_notification(
                        user_id=order.user_id,
                        type=n_type,
                        title=n_title,
                        message=n_msg,
                        data={
                            "order_id": str(order.id),
                            "order_number": order.order_number,
                            "fulfillment_status": new_status.value,
                            "order_status": overall_status.value,
                        },
                    )

            await self.session.commit()

            return SellerOrderStatusUpdateResponse(
                order_id=order.id,
                updated_item_count=updated_count,
                fulfillment_status=new_status,
                order_status=overall_status,
                message=f"Successfully updated fulfillment status to {new_status.value}.",
            )
        except Exception:
            await self.session.rollback()
            raise

    # ── Private Mappers ─────────────────────────────────────────────────────

    def _to_seller_product_read(
        self,
        product: Product,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerProductRead:
        image_url = product.images[0].image_url if product.images else None
        category_name = product.category.name if product.category else None
        is_low_stock = product.is_active and product.stock_quantity <= low_stock_threshold

        return SellerProductRead(
            id=product.id,
            seller_id=product.seller_id,
            category_id=product.category_id,
            category_name=category_name,
            name=product.name,
            slug=product.slug,
            description=product.description,
            price=product.price,
            stock_quantity=product.stock_quantity,
            sku=product.sku,
            image_url=image_url,
            is_active=product.is_active,
            is_low_stock=is_low_stock,
            created_at=product.created_at,
            updated_at=product.updated_at,
        )

    def _to_seller_order_list_item(
        self,
        order: Order,
        seller_item_count: int,
        seller_subtotal: Decimal,
    ) -> SellerOrderListItemRead:
        customer_name = (
            order.user.full_name if order.user else order.shipping_full_name
        )

        return SellerOrderListItemRead(
            id=order.id,
            order_number=order.order_number,
            status=order.status,
            payment_status=order.payment_status,
            seller_item_count=seller_item_count,
            seller_subtotal=Decimal(str(seller_subtotal)),
            currency=order.currency,
            customer_name=customer_name,
            created_at=order.created_at,
        )
