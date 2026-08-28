import math
import uuid
from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import Order, OrderItem, OrderStatus
from app.modules.products.models import Product


class OrderRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_id(self, order_id: uuid.UUID) -> Optional[Order]:
        stmt = (
            select(Order)
            .where(Order.id == order_id)
            .options(selectinload(Order.items))
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_id_and_user(
        self,
        order_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> Optional[Order]:
        stmt = (
            select(Order)
            .where(Order.id == order_id, Order.user_id == user_id)
            .options(selectinload(Order.items))
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_idempotency_key(
        self,
        user_id: uuid.UUID,
        idempotency_key: str,
    ) -> Optional[Order]:
        stmt = (
            select(Order)
            .where(
                Order.user_id == user_id,
                Order.idempotency_key == idempotency_key,
            )
            .options(selectinload(Order.items))
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list_orders(
        self,
        user_id: uuid.UUID,
        status: Optional[OrderStatus] = None,
        from_date: Optional[datetime] = None,
        to_date: Optional[datetime] = None,
        search: Optional[str] = None,
        sort: str = "newest",
        page: int = 1,
        page_size: int = 10,
    ) -> Tuple[List[Order], int, int]:
        query = select(Order).where(Order.user_id == user_id)
        count_query = select(func.count(Order.id)).where(Order.user_id == user_id)

        if status is not None:
            query = query.where(Order.status == status)
            count_query = count_query.where(Order.status == status)

        if from_date is not None:
            query = query.where(Order.created_at >= from_date)
            count_query = count_query.where(Order.created_at >= from_date)

        if to_date is not None:
            query = query.where(Order.created_at <= to_date)
            count_query = count_query.where(Order.created_at <= to_date)

        if search:
            search_clean = f"%{search.strip()}%"
            query = query.where(Order.order_number.ilike(search_clean))
            count_query = count_query.where(Order.order_number.ilike(search_clean))

        total_res = await self.session.execute(count_query)
        total = total_res.scalar_one() or 0

        pages = max(1, math.ceil(total / page_size)) if total > 0 else 0
        offset = (page - 1) * page_size

        if sort == "oldest":
            query = query.order_by(Order.created_at.asc())
        else:
            query = query.order_by(Order.created_at.desc())

        query = (
            query.options(selectinload(Order.items))
            .offset(offset)
            .limit(page_size)
        )
        result = await self.session.execute(query)
        orders = list(result.scalars().all())
        return orders, total, pages

    async def list_seller_orders(
        self,
        seller_id: uuid.UUID,
        page: int = 1,
        page_size: int = 10,
    ) -> Tuple[List[Order], int, int]:
        # Orders containing at least one item from this seller
        subquery = (
            select(OrderItem.order_id)
            .where(OrderItem.seller_id == seller_id)
            .distinct()
        )
        query = select(Order).where(Order.id.in_(subquery))
        count_query = select(func.count(Order.id)).where(Order.id.in_(subquery))

        total_res = await self.session.execute(count_query)
        total = total_res.scalar_one() or 0

        pages = max(1, math.ceil(total / page_size))
        offset = (page - 1) * page_size

        query = (
            query.options(selectinload(Order.items))
            .order_by(Order.created_at.desc())
            .offset(offset)
            .limit(page_size)
        )
        result = await self.session.execute(query)
        orders = list(result.scalars().all())
        return orders, total, pages

    async def atomic_decrement_stock(
        self,
        product_id: uuid.UUID,
        quantity: int,
    ) -> bool:
        """
        Atomically decrements stock of an active product if stock >= quantity.
        Returns True if row was updated, False if insufficient stock or inactive.
        """
        stmt = (
            update(Product)
            .where(
                Product.id == product_id,
                Product.is_active.is_(True),
                Product.stock_quantity >= quantity,
            )
            .values(stock_quantity=Product.stock_quantity - quantity)
        )
        res = await self.session.execute(stmt)
        return (res.rowcount or 0) > 0

    async def atomic_increment_stock(
        self,
        product_id: uuid.UUID,
        quantity: int,
    ) -> None:
        """
        Atomically increments stock when an order is cancelled.
        """
        stmt = (
            update(Product)
            .where(Product.id == product_id)
            .values(stock_quantity=Product.stock_quantity + quantity)
        )
        await self.session.execute(stmt)

    async def create_order(self, order: Order) -> Order:
        self.session.add(order)
        await self.session.flush()
        await self.session.refresh(order)
        return order

