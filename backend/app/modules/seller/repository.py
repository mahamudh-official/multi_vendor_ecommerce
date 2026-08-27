import math
import uuid
from decimal import Decimal
from typing import List, Optional, Tuple

from sqlalchemy import case, distinct, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus
from app.modules.products.models import Category, Product
from app.modules.seller.constants import DEFAULT_LOW_STOCK_THRESHOLD
from app.modules.seller.schemas import SellerDashboardStats


class SellerRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ── Dashboard Queries ───────────────────────────────────────────────────

    async def get_dashboard_stats(
        self,
        seller_id: uuid.UUID,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerDashboardStats:
        """
        Executes database aggregations to compute authoritative metrics for the seller.
        Sales amount strictly aggregates line_total for seller's own items in non-cancelled orders.
        """
        # 1. Product stats
        prod_stmt = select(
            func.count(Product.id).label("total"),
            func.count(case((Product.is_active.is_(True), 1))).label("active"),
            func.count(case((Product.is_active.is_(False), 1))).label("inactive"),
            func.count(
                case(
                    (
                        (Product.is_active.is_(True))
                        & (Product.stock_quantity <= low_stock_threshold),
                        1,
                    )
                )
            ).label("low_stock"),
        ).where(Product.seller_id == seller_id)

        prod_res = await self.session.execute(prod_stmt)
        prod_row = prod_res.one()

        # 2. Sales sum for non-cancelled orders
        sales_stmt = (
            select(func.coalesce(func.sum(OrderItem.line_total), Decimal("0.00")))
            .join(Order, OrderItem.order_id == Order.id)
            .where(
                OrderItem.seller_id == seller_id,
                Order.status != OrderStatus.CANCELLED,
            )
        )
        sales_res = await self.session.execute(sales_stmt)
        total_sales = sales_res.scalar_one() or Decimal("0.00")

        # 3. Order counts
        # Subquery for distinct order IDs associated with this seller
        seller_orders_subq = (
            select(
                Order.id,
                Order.status,
            )
            .join(OrderItem, Order.id == OrderItem.order_id)
            .where(OrderItem.seller_id == seller_id)
            .distinct()
            .subquery()
        )

        order_stats_stmt = select(
            func.count(seller_orders_subq.c.id).label("total_orders"),
            func.count(
                case((seller_orders_subq.c.status == OrderStatus.PENDING, 1))
            ).label("pending_orders"),
            func.count(
                case((seller_orders_subq.c.status == OrderStatus.PROCESSING, 1))
            ).label("processing_orders"),
            func.count(
                case((seller_orders_subq.c.status == OrderStatus.SHIPPED, 1))
            ).label("shipped_orders"),
            func.count(
                case((seller_orders_subq.c.status == OrderStatus.DELIVERED, 1))
            ).label("delivered_orders"),
        )
        order_stats_res = await self.session.execute(order_stats_stmt)
        order_row = order_stats_res.one()

        return SellerDashboardStats(
            total_products=prod_row.total or 0,
            active_products=prod_row.active or 0,
            inactive_products=prod_row.inactive or 0,
            low_stock_products=prod_row.low_stock or 0,
            total_orders=order_row.total_orders or 0,
            pending_orders=order_row.pending_orders or 0,
            processing_orders=order_row.processing_orders or 0,
            shipped_orders=order_row.shipped_orders or 0,
            delivered_orders=order_row.delivered_orders or 0,
            total_sales_amount=Decimal(str(total_sales)),
        )

    # ── Seller Product Queries ──────────────────────────────────────────────

    async def list_seller_products(
        self,
        seller_id: uuid.UUID,
        page: int = 1,
        page_size: int = 20,
        search: Optional[str] = None,
        category_id: Optional[uuid.UUID] = None,
        is_active: Optional[bool] = None,
        low_stock: Optional[bool] = None,
        sort: str = "newest",
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> Tuple[List[Product], int, int]:
        query = (
            select(Product)
            .where(Product.seller_id == seller_id)
            .options(selectinload(Product.category), selectinload(Product.images))
        )
        count_query = (
            select(func.count(Product.id)).where(Product.seller_id == seller_id)
        )

        if search:
            search_pattern = f"%{search.strip()}%"
            filter_clause = or_(
                Product.name.ilike(search_pattern),
                Product.sku.ilike(search_pattern),
            )
            query = query.where(filter_clause)
            count_query = count_query.where(filter_clause)

        if category_id is not None:
            query = query.where(Product.category_id == category_id)
            count_query = count_query.where(Product.category_id == category_id)

        if is_active is not None:
            query = query.where(Product.is_active == is_active)
            count_query = count_query.where(Product.is_active == is_active)

        if low_stock is True:
            query = query.where(Product.stock_quantity <= low_stock_threshold)
            count_query = count_query.where(Product.stock_quantity <= low_stock_threshold)

        total_res = await self.session.execute(count_query)
        total = total_res.scalar_one() or 0
        pages = max(1, math.ceil(total / page_size))
        offset = (page - 1) * page_size

        # Sort order
        if sort == "oldest":
            query = query.order_by(Product.created_at.asc())
        elif sort == "price_low":
            query = query.order_by(Product.price.asc())
        elif sort == "price_high":
            query = query.order_by(Product.price.desc())
        elif sort == "stock_low":
            query = query.order_by(Product.stock_quantity.asc())
        else:
            query = query.order_by(Product.created_at.desc())

        query = query.offset(offset).limit(page_size)
        res = await self.session.execute(query)
        products = list(res.scalars().all())
        return products, total, pages

    async def get_seller_product(
        self,
        seller_id: uuid.UUID,
        product_id: uuid.UUID,
    ) -> Optional[Product]:
        query = (
            select(Product)
            .where(Product.id == product_id, Product.seller_id == seller_id)
            .options(selectinload(Product.category), selectinload(Product.images))
        )
        res = await self.session.execute(query)
        return res.scalar_one_or_none()

    async def create_product(self, product: Product) -> Product:
        self.session.add(product)
        await self.session.flush()
        await self.session.refresh(product, attribute_names=["category", "images"])
        return product

    async def update_product(self, product: Product) -> Product:
        await self.session.flush()
        await self.session.refresh(product, attribute_names=["category", "images"])
        return product

    # ── Seller Order Queries ────────────────────────────────────────────────

    async def list_seller_orders(
        self,
        seller_id: uuid.UUID,
        status: Optional[OrderStatus] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 10,
    ) -> Tuple[List[Tuple[Order, int, Decimal]], int, int]:
        """
        Returns orders containing items of this seller, along with:
        (Order, seller_item_count, seller_subtotal).
        """
        # Subquery to aggregate seller-specific counts and subtotals per order
        seller_agg_subq = (
            select(
                OrderItem.order_id.label("order_id"),
                func.count(OrderItem.id).label("seller_item_count"),
                func.sum(OrderItem.line_total).label("seller_subtotal"),
            )
            .where(OrderItem.seller_id == seller_id)
            .group_by(OrderItem.order_id)
            .subquery()
        )

        query = (
            select(
                Order,
                seller_agg_subq.c.seller_item_count,
                seller_agg_subq.c.seller_subtotal,
            )
            .join(seller_agg_subq, Order.id == seller_agg_subq.c.order_id)
            .options(selectinload(Order.user))
        )
        count_query = (
            select(func.count(Order.id))
            .join(seller_agg_subq, Order.id == seller_agg_subq.c.order_id)
        )

        if status is not None:
            query = query.where(Order.status == status)
            count_query = count_query.where(Order.status == status)

        if search:
            search_pat = f"%{search.strip()}%"
            query = query.where(Order.order_number.ilike(search_pat))
            count_query = count_query.where(Order.order_number.ilike(search_pat))

        total_res = await self.session.execute(count_query)
        total = total_res.scalar_one() or 0
        pages = max(1, math.ceil(total / page_size))
        offset = (page - 1) * page_size

        query = query.order_by(Order.created_at.desc()).offset(offset).limit(page_size)
        res = await self.session.execute(query)
        rows = list(res.all())
        # rows format: [(Order, count, subtotal), ...]
        return rows, total, pages

    async def get_seller_order_with_items(
        self,
        seller_id: uuid.UUID,
        order_id: uuid.UUID,
    ) -> Optional[Tuple[Order, List[OrderItem]]]:
        """
        Fetches the order and ONLY the items belonging to this seller.
        """
        order_query = (
            select(Order)
            .where(Order.id == order_id)
            .options(selectinload(Order.user))
        )
        order_res = await self.session.execute(order_query)
        order = order_res.scalar_one_or_none()
        if not order:
            return None

        # Fetch only seller's items
        items_query = (
            select(OrderItem)
            .where(OrderItem.order_id == order_id, OrderItem.seller_id == seller_id)
            .order_by(OrderItem.created_at.asc())
        )
        items_res = await self.session.execute(items_query)
        items = list(items_res.scalars().all())

        if not items:
            # Order exists, but contains NO items for this seller -> isolated 404
            return None

        return order, items

    async def update_seller_items_fulfillment(
        self,
        seller_id: uuid.UUID,
        order_id: uuid.UUID,
        new_status: FulfillmentStatus,
    ) -> int:
        """
        Updates fulfillment_status for all OrderItems of this seller in the given order.
        """
        stmt = (
            update(OrderItem)
            .where(OrderItem.order_id == order_id, OrderItem.seller_id == seller_id)
            .values(fulfillment_status=new_status)
        )
        res = await self.session.execute(stmt)
        return res.rowcount or 0

    async def synchronize_overall_order_status(self, order_id: uuid.UUID) -> OrderStatus:
        """
        Inspects all items in the order across all sellers, and computes
        the harmonized customer-facing Order.status.
        """
        order_query = (
            select(Order)
            .where(Order.id == order_id)
            .options(selectinload(Order.items))
        )
        order_res = await self.session.execute(order_query)
        order = order_res.scalar_one_or_none()
        if not order or order.status == OrderStatus.CANCELLED:
            return order.status if order else OrderStatus.PENDING

        item_statuses = [item.fulfillment_status for item in order.items]
        if not item_statuses:
            return order.status

        # Derivation logic:
        if all(s == FulfillmentStatus.DELIVERED for s in item_statuses):
            new_order_status = OrderStatus.DELIVERED
        elif any(s == FulfillmentStatus.SHIPPED for s in item_statuses) or all(
            s in (FulfillmentStatus.SHIPPED, FulfillmentStatus.DELIVERED) for s in item_statuses
        ):
            new_order_status = OrderStatus.SHIPPED
        elif any(s == FulfillmentStatus.PROCESSING for s in item_statuses) or all(
            s in (FulfillmentStatus.PROCESSING, FulfillmentStatus.SHIPPED, FulfillmentStatus.DELIVERED)
            for s in item_statuses
        ):
            new_order_status = OrderStatus.PROCESSING
        elif any(s == FulfillmentStatus.CONFIRMED for s in item_statuses):
            new_order_status = OrderStatus.CONFIRMED
        else:
            new_order_status = OrderStatus.PENDING

        order.status = new_order_status
        await self.session.flush()
        return new_order_status

