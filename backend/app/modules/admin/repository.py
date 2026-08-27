"""
Database repository for administrator operations and aggregated statistics.
"""
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import and_, distinct, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.auth.models import SellerStatus, User, UserRole
from app.modules.orders.models import FulfillmentStatus, Order, OrderItem, OrderStatus, PaymentStatus as OrderPaymentStatus
from app.modules.payments.models import Payment, PaymentStatus
from app.modules.products.models import Category, Product


class AdminRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ── Dashboard Statistics ──────────────────────────────────────────────────

    async def get_dashboard_metrics(self) -> Dict[str, Any]:
        """
        Executes optimized aggregate queries for all platform dashboard metrics.
        Revenue calculations strictly consider paid and non-cancelled orders.
        """
        now = datetime.now(timezone.utc)
        today_start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
        month_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)

        # 1. User Metrics
        u_stmt = select(
            func.count(User.id).label("total_users"),
            func.count(User.id).filter(User.role == UserRole.customer).label("total_customers"),
            func.count(User.id).filter(User.role == UserRole.seller).label("total_sellers"),
            func.count(User.id).filter(
                and_(User.role == UserRole.seller, User.seller_status == SellerStatus.approved.value, User.is_active.is_(True))
            ).label("active_sellers"),
            func.count(User.id).filter(
                and_(User.role == UserRole.seller, User.seller_status == SellerStatus.pending.value)
            ).label("pending_sellers"),
        )
        u_res = await self.session.execute(u_stmt)
        u_row = u_res.one()

        # 2. Product Metrics
        p_stmt = select(
            func.count(Product.id).label("total_products"),
            func.count(Product.id).filter(Product.is_active.is_(True)).label("active_products"),
            func.count(Product.id).filter(Product.is_active.is_(False)).label("inactive_products"),
            func.count(Product.id).filter(Product.stock_quantity <= 5).label("low_stock_products"),
        )
        p_res = await self.session.execute(p_stmt)
        p_row = p_res.one()

        # 3. Order Metrics & Paid Revenue
        # Paid orders predicate
        paid_predicate = and_(
            Order.payment_status == OrderPaymentStatus.PAID.value,
            Order.status != OrderStatus.CANCELLED,
        )

        o_stmt = select(
            func.count(Order.id).label("total_orders"),
            func.count(Order.id).filter(Order.status == OrderStatus.PENDING).label("pending_orders"),
            func.count(Order.id).filter(Order.status == OrderStatus.CONFIRMED).label("confirmed_orders"),
            func.count(Order.id).filter(Order.status == OrderStatus.PROCESSING).label("processing_orders"),
            func.count(Order.id).filter(Order.status == OrderStatus.SHIPPED).label("shipped_orders"),
            func.count(Order.id).filter(Order.status == OrderStatus.DELIVERED).label("delivered_orders"),
            func.count(Order.id).filter(Order.status == OrderStatus.CANCELLED).label("cancelled_orders"),
            func.coalesce(func.sum(Order.total_amount).filter(paid_predicate), 0).label("total_revenue"),
            func.coalesce(func.sum(Order.total_amount).filter(and_(paid_predicate, Order.created_at >= today_start)), 0).label("today_revenue"),
            func.coalesce(func.sum(Order.total_amount).filter(and_(paid_predicate, Order.created_at >= month_start)), 0).label("month_revenue"),
        )
        o_res = await self.session.execute(o_stmt)
        o_row = o_res.one()

        # 4. Payment Metrics
        pay_stmt = select(
            func.count(Payment.id).label("total_payments"),
            func.count(Payment.id).filter(Payment.status == PaymentStatus.SUCCEEDED).label("successful_payments"),
            func.count(Payment.id).filter(Payment.status == PaymentStatus.FAILED).label("failed_payments"),
        )
        pay_res = await self.session.execute(pay_stmt)
        pay_row = pay_res.one()

        return {
            "total_users": u_row.total_users,
            "total_customers": u_row.total_customers,
            "total_sellers": u_row.total_sellers,
            "active_sellers": u_row.active_sellers,
            "pending_sellers": u_row.pending_sellers,
            "total_products": p_row.total_products,
            "active_products": p_row.active_products,
            "inactive_products": p_row.inactive_products,
            "low_stock_products": p_row.low_stock_products,
            "total_orders": o_row.total_orders,
            "pending_orders": o_row.pending_orders,
            "confirmed_orders": o_row.confirmed_orders,
            "processing_orders": o_row.processing_orders,
            "shipped_orders": o_row.shipped_orders,
            "delivered_orders": o_row.delivered_orders,
            "cancelled_orders": o_row.cancelled_orders,
            "total_revenue": Decimal(str(o_row.total_revenue)),
            "today_revenue": Decimal(str(o_row.today_revenue)),
            "month_revenue": Decimal(str(o_row.month_revenue)),
            "total_payments": pay_row.total_payments,
            "successful_payments": pay_row.successful_payments,
            "failed_payments": pay_row.failed_payments,
        }

    # ── User Management ───────────────────────────────────────────────────────

    async def list_users(
        self,
        search: Optional[str] = None,
        role: Optional[str] = None,
        is_active: Optional[bool] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[User], int]:
        stmt = select(User)

        if search:
            search_clean = f"%{search.strip().lower()}%"
            stmt = stmt.where(
                or_(
                    func.lower(User.full_name).like(search_clean),
                    func.lower(User.email).like(search_clean),
                )
            )
        if role:
            stmt = stmt.where(User.role == role)
        if is_active is not None:
            stmt = stmt.where(User.is_active.is_(is_active))

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_res = await self.session.execute(count_stmt)
        total = total_res.scalar_one()

        stmt = stmt.order_by(User.created_at.desc())
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.session.execute(stmt)
        return list(res.scalars().all()), total

    async def get_user_by_id(self, user_id: uuid.UUID) -> Optional[User]:
        stmt = select(User).where(User.id == user_id)
        res = await self.session.execute(stmt)
        return res.scalar_one_or_none()

    # ── Seller Management ─────────────────────────────────────────────────────

    async def list_sellers(
        self,
        search: Optional[str] = None,
        seller_status: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[Dict[str, Any]], int]:
        """Fetch sellers with product count, order count, and revenue aggregations."""
        stmt = select(User).where(User.role == UserRole.seller)

        if search:
            search_clean = f"%{search.strip().lower()}%"
            stmt = stmt.where(
                or_(
                    func.lower(User.full_name).like(search_clean),
                    func.lower(User.email).like(search_clean),
                )
            )
        if seller_status:
            stmt = stmt.where(User.seller_status == seller_status)

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_res = await self.session.execute(count_stmt)
        total = total_res.scalar_one()

        stmt = stmt.order_by(User.created_at.desc())
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        sellers_res = await self.session.execute(stmt)
        sellers = list(sellers_res.scalars().all())

        seller_ids = [s.id for s in sellers]
        if not seller_ids:
            return [], total

        # Aggregate product count
        prod_count_stmt = (
            select(Product.seller_id, func.count(Product.id).label("prod_count"))
            .where(Product.seller_id.in_(seller_ids))
            .group_by(Product.seller_id)
        )
        prod_res = await self.session.execute(prod_count_stmt)
        prod_counts = {row.seller_id: row.prod_count for row in prod_res.all()}

        # Aggregate order count and revenue
        order_agg_stmt = (
            select(
                OrderItem.seller_id,
                func.count(distinct(OrderItem.order_id)).label("order_count"),
                func.coalesce(func.sum(OrderItem.line_total), 0).label("revenue"),
            )
            .join(Order, Order.id == OrderItem.order_id)
            .where(
                and_(
                    OrderItem.seller_id.in_(seller_ids),
                    Order.payment_status == OrderPaymentStatus.PAID.value,
                    Order.status != OrderStatus.CANCELLED,
                )
            )
            .group_by(OrderItem.seller_id)
        )
        order_res = await self.session.execute(order_agg_stmt)
        order_aggs = {row.seller_id: (row.order_count, Decimal(str(row.revenue))) for row in order_res.all()}

        seller_list = []
        for s in sellers:
            p_cnt = prod_counts.get(s.id, 0)
            o_cnt, rev = order_aggs.get(s.id, (0, Decimal("0.00")))
            seller_list.append({
                "id": s.id,
                "full_name": s.full_name,
                "email": s.email,
                "seller_status": s.seller_status or "approved",
                "is_active": s.is_active,
                "product_count": p_cnt,
                "order_count": o_cnt,
                "total_revenue": rev,
                "created_at": s.created_at,
            })

        return seller_list, total

    # ── Product Moderation ────────────────────────────────────────────────────

    async def list_products(
        self,
        seller_id: Optional[uuid.UUID] = None,
        category_id: Optional[uuid.UUID] = None,
        is_active: Optional[bool] = None,
        low_stock: Optional[bool] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[Product], int]:
        stmt = select(Product).options(
            selectinload(Product.seller),
            selectinload(Product.category),
        )

        if seller_id:
            stmt = stmt.where(Product.seller_id == seller_id)
        if category_id:
            stmt = stmt.where(Product.category_id == category_id)
        if is_active is not None:
            stmt = stmt.where(Product.is_active.is_(is_active))
        if low_stock:
            stmt = stmt.where(Product.stock_quantity <= 5)
        if search:
            search_clean = f"%{search.strip().lower()}%"
            stmt = stmt.where(
                or_(
                    func.lower(Product.name).like(search_clean),
                    func.lower(Product.description).like(search_clean),
                )
            )

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_res = await self.session.execute(count_stmt)
        total = total_res.scalar_one()

        stmt = stmt.order_by(Product.created_at.desc())
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.session.execute(stmt)
        return list(res.scalars().all()), total

    async def get_product_by_id(self, product_id: uuid.UUID) -> Optional[Product]:
        stmt = (
            select(Product)
            .options(
                selectinload(Product.seller),
                selectinload(Product.category),
            )
            .where(Product.id == product_id)
        )
        res = await self.session.execute(stmt)
        return res.scalar_one_or_none()

    # ── Category Management ───────────────────────────────────────────────────

    async def list_categories_with_product_count(self) -> List[Dict[str, Any]]:
        stmt = (
            select(
                Category,
                func.count(Product.id).label("product_count"),
            )
            .outerjoin(Product, Product.category_id == Category.id)
            .group_by(Category.id)
            .order_by(Category.name.asc())
        )
        res = await self.session.execute(stmt)
        categories = []
        for cat, p_count in res.all():
            categories.append({
                "id": cat.id,
                "name": cat.name,
                "slug": cat.slug,
                "description": cat.description,
                "image_url": cat.image_url,
                "is_active": cat.is_active,
                "product_count": p_count,
                "created_at": cat.created_at,
                "updated_at": cat.updated_at,
            })
        return categories

    async def get_category_by_id(self, category_id: uuid.UUID) -> Optional[Category]:
        stmt = select(Category).where(Category.id == category_id)
        res = await self.session.execute(stmt)
        return res.scalar_one_or_none()

    async def count_category_products(self, category_id: uuid.UUID) -> int:
        stmt = select(func.count(Product.id)).where(Product.category_id == category_id)
        res = await self.session.execute(stmt)
        return res.scalar_one()

    # ── Order Management ──────────────────────────────────────────────────────

    async def list_orders(
        self,
        status: Optional[str] = None,
        payment_status: Optional[str] = None,
        customer_id: Optional[uuid.UUID] = None,
        seller_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[Order], int]:
        stmt = select(Order).options(
            selectinload(Order.items),
            selectinload(Order.user),
        )

        if status:
            stmt = stmt.where(Order.status == status)
        if payment_status:
            stmt = stmt.where(Order.payment_status == payment_status)
        if customer_id:
            stmt = stmt.where(Order.user_id == customer_id)
        if seller_id:
            stmt = stmt.where(
                Order.id.in_(
                    select(OrderItem.order_id).where(OrderItem.seller_id == seller_id)
                )
            )

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_res = await self.session.execute(count_stmt)
        total = total_res.scalar_one()

        stmt = stmt.order_by(Order.created_at.desc())
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.session.execute(stmt)
        return list(res.scalars().all()), total

    async def get_order_by_id(self, order_id: uuid.UUID) -> Optional[Order]:
        stmt = (
            select(Order)
            .options(
                selectinload(Order.items),
                selectinload(Order.user),
            )
            .where(Order.id == order_id)
        )
        res = await self.session.execute(stmt)
        return res.scalar_one_or_none()

    # ── Payment Monitoring ────────────────────────────────────────────────────

    async def list_payments(
        self,
        status: Optional[str] = None,
        provider: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[Payment], int]:
        stmt = select(Payment).options(
            selectinload(Payment.order),
            selectinload(Payment.user),
        )

        if status:
            stmt = stmt.where(Payment.status == status)
        if provider:
            stmt = stmt.where(Payment.provider == provider)

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_res = await self.session.execute(count_stmt)
        total = total_res.scalar_one()

        stmt = stmt.order_by(Payment.created_at.desc())
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.session.execute(stmt)
        return list(res.scalars().all()), total

    async def get_payment_by_id(self, payment_id: uuid.UUID) -> Optional[Payment]:
        stmt = (
            select(Payment)
            .options(
                selectinload(Payment.order),
                selectinload(Payment.user),
            )
            .where(Payment.id == payment_id)
        )
        res = await self.session.execute(stmt)
        return res.scalar_one_or_none()

