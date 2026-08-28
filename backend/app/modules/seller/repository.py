import math
import uuid
from decimal import Decimal
from typing import List, Optional, Tuple

from sqlalchemy import case, distinct, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus, PaymentStatus
from app.modules.products.models import Category, Product
from app.modules.reviews.models import Review
from app.modules.seller.constants import DEFAULT_LOW_STOCK_THRESHOLD
from app.modules.seller.schemas import (
    SellerAnalyticsOverview,
    SellerDashboardStats,
    SellerProductAnalyticsItem,
    SellerSalesPeriodItem,
)


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

    # ── Detailed Seller Analytics ───────────────────────────────────────────

    async def get_analytics_overview(
        self,
        seller_id: uuid.UUID,
        low_stock_threshold: int = DEFAULT_LOW_STOCK_THRESHOLD,
    ) -> SellerAnalyticsOverview:
        """
        Calculates authoritative seller KPI metrics:
        - Revenue & Items Sold: strictly from valid paid & non-cancelled orders
        - AOV: total_revenue / total_orders
        - Fulfillment counts: pending vs delivered
        - Products: active & low stock
        """
        # 1. Product counts
        prod_stmt = select(
            func.count(case((Product.is_active.is_(True), 1))).label("active"),
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
        active_prods, low_stock_prods = prod_res.one()

        # 2. Paid orders metrics (Revenue, Distinct Orders, Total Items Sold)
        paid_metrics_stmt = (
            select(
                func.coalesce(func.sum(OrderItem.line_total), Decimal("0.00")).label("total_revenue"),
                func.coalesce(func.sum(OrderItem.quantity), 0).label("total_items"),
                func.count(distinct(Order.id)).label("total_orders"),
            )
            .join(Order, OrderItem.order_id == Order.id)
            .where(
                OrderItem.seller_id == seller_id,
                Order.payment_status == PaymentStatus.PAID,
                Order.status != OrderStatus.CANCELLED,
            )
        )
        paid_res = await self.session.execute(paid_metrics_stmt)
        total_revenue, total_items, total_orders = paid_res.one()
        total_rev_dec = Decimal(str(total_revenue or "0.00"))
        tot_orders_int = int(total_orders or 0)
        tot_items_int = int(total_items or 0)

        aov = (
            Decimal(str(round(float(total_rev_dec) / tot_orders_int, 2)))
            if tot_orders_int > 0
            else Decimal("0.00")
        )

        # 3. Fulfillment status counts
        fulfill_stmt = (
            select(
                func.count(
                    case(
                        (
                            OrderItem.fulfillment_status.in_(
                                [
                                    FulfillmentStatus.PENDING,
                                    FulfillmentStatus.CONFIRMED,
                                    FulfillmentStatus.PROCESSING,
                                    FulfillmentStatus.SHIPPED,
                                ]
                            ),
                            1,
                        )
                    )
                ).label("pending_fulfill"),
                func.count(
                    case((OrderItem.fulfillment_status == FulfillmentStatus.DELIVERED, 1))
                ).label("delivered_fulfill"),
            )
            .join(Order, OrderItem.order_id == Order.id)
            .where(
                OrderItem.seller_id == seller_id,
                Order.payment_status == PaymentStatus.PAID,
                Order.status != OrderStatus.CANCELLED,
            )
        )
        fulfill_res = await self.session.execute(fulfill_stmt)
        pending_fulfill, delivered_fulfill = fulfill_res.one()

        return SellerAnalyticsOverview(
            total_revenue=total_rev_dec,
            total_orders=tot_orders_int,
            total_items_sold=tot_items_int,
            average_order_value=aov,
            active_products=int(active_prods or 0),
            low_stock_products=int(low_stock_prods or 0),
            pending_fulfillment_count=int(pending_fulfill or 0),
            delivered_order_count=int(delivered_fulfill or 0),
        )

    async def get_sales_analytics(
        self,
        seller_id: uuid.UUID,
        period: str = "daily",
    ) -> List[SellerSalesPeriodItem]:
        """
        Aggregates sales over time (daily, weekly, or monthly) for paid, non-cancelled orders.
        """
        if period == "weekly":
            period_expr = func.to_char(func.date_trunc("week", Order.created_at), "YYYY-\"W\"IW")
        elif period == "monthly":
            period_expr = func.to_char(func.date_trunc("month", Order.created_at), "YYYY-MM")
        else:
            period_expr = func.to_char(func.date_trunc("day", Order.created_at), "YYYY-MM-DD")

        stmt = (
            select(
                period_expr.label("period"),
                func.count(distinct(Order.id)).label("order_count"),
                func.sum(OrderItem.quantity).label("item_quantity"),
                func.sum(OrderItem.line_total).label("revenue"),
            )
            .join(Order, OrderItem.order_id == Order.id)
            .where(
                OrderItem.seller_id == seller_id,
                Order.payment_status == PaymentStatus.PAID,
                Order.status != OrderStatus.CANCELLED,
            )
            .group_by(period_expr)
            .order_by(period_expr.asc())
        )

        res = await self.session.execute(stmt)
        items = []
        for row in res.all():
            items.append(
                SellerSalesPeriodItem(
                    period=row.period,
                    order_count=int(row.order_count or 0),
                    item_quantity=int(row.item_quantity or 0),
                    revenue=Decimal(str(row.revenue or "0.00")),
                )
            )
        return items

    async def get_product_analytics(
        self,
        seller_id: uuid.UUID,
        limit: int = 10,
    ) -> List[SellerProductAnalyticsItem]:
        """
        Returns ranking of top-selling products by revenue for the seller with ratings and review counts.
        """
        # Subquery for approved reviews per product
        reviews_subq = (
            select(
                Review.product_id,
                func.coalesce(func.avg(Review.rating), 0.0).label("avg_rating"),
                func.count(Review.id).label("review_count"),
            )
            .where(Review.is_approved.is_(True))
            .group_by(Review.product_id)
            .subquery()
        )

        # Subquery for sales per product
        sales_subq = (
            select(
                OrderItem.product_id,
                func.sum(OrderItem.quantity).label("total_sold"),
                func.sum(OrderItem.line_total).label("total_revenue"),
            )
            .join(Order, OrderItem.order_id == Order.id)
            .where(
                OrderItem.seller_id == seller_id,
                Order.payment_status == PaymentStatus.PAID,
                Order.status != OrderStatus.CANCELLED,
            )
            .group_by(OrderItem.product_id)
            .subquery()
        )

        stmt = (
            select(
                Product.id.label("product_id"),
                Product.name.label("product_name"),
                Product.sku.label("sku"),
                Product.stock_quantity.label("current_stock"),
                func.coalesce(sales_subq.c.total_revenue, Decimal("0.00")).label("revenue"),
                func.coalesce(sales_subq.c.total_sold, 0).label("quantity_sold"),
                func.coalesce(reviews_subq.c.avg_rating, 0.0).label("avg_rating"),
                func.coalesce(reviews_subq.c.review_count, 0).label("review_count"),
            )
            .outerjoin(sales_subq, Product.id == sales_subq.c.product_id)
            .outerjoin(reviews_subq, Product.id == reviews_subq.c.product_id)
            .where(Product.seller_id == seller_id)
            .order_by(
                func.coalesce(sales_subq.c.total_revenue, Decimal("0.00")).desc(),
                func.coalesce(sales_subq.c.total_sold, 0).desc(),
                Product.name.asc(),
            )
            .limit(limit)
        )

        res = await self.session.execute(stmt)
        items = []
        for row in res.all():
            items.append(
                SellerProductAnalyticsItem(
                    product_id=row.product_id,
                    product_name=row.product_name,
                    sku=row.sku,
                    revenue=Decimal(str(row.revenue or "0.00")),
                    quantity_sold=int(row.quantity_sold or 0),
                    current_stock=int(row.current_stock or 0),
                    average_rating=round(float(row.avg_rating or 0.0), 2),
                    review_count=int(row.review_count or 0),
                )
            )
        return items

