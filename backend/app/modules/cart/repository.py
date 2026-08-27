"""
Data access repositories for Cart, CartItem, and Wishlist operations.
"""
from __future__ import annotations

import uuid
from typing import Optional

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.cart.models import Cart, CartItem, WishlistItem
from app.modules.products.models import Product


class CartRepository:
    """Async database operations for Cart and CartItem entities."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_or_create_cart(self, user_id: uuid.UUID) -> Cart:
        """Fetch existing cart for user or create an active one."""
        self.session.expire_all()
        stmt = (
            select(Cart)
            .where(Cart.user_id == user_id)
            .options(
                selectinload(Cart.items).joinedload(CartItem.product),
            )
            .execution_options(populate_existing=True)
        )
        result = await self.session.execute(stmt)
        cart = result.scalar_one_or_none()

        if cart is None:
            cart = Cart(user_id=user_id)
            self.session.add(cart)
            await self.session.commit()
            # Re-fetch with relationships loaded
            return await self.get_or_create_cart(user_id)

        return cart

    async def get_cart_item(self, cart_id: uuid.UUID, item_id: uuid.UUID) -> Optional[CartItem]:
        """Fetch a specific line item in the cart with product loaded."""
        stmt = (
            select(CartItem)
            .where(CartItem.cart_id == cart_id, CartItem.id == item_id)
            .options(selectinload(CartItem.product))
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_cart_item_by_product(
        self,
        cart_id: uuid.UUID,
        product_id: uuid.UUID,
    ) -> Optional[CartItem]:
        """Check if a product is already in the cart."""
        stmt = (
            select(CartItem)
            .where(CartItem.cart_id == cart_id, CartItem.product_id == product_id)
            .options(selectinload(CartItem.product))
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def add_item(
        self,
        cart_id: uuid.UUID,
        product_id: uuid.UUID,
        quantity: int,
    ) -> CartItem:
        """Create and persist a new line item in cart."""
        item = CartItem(
            cart_id=cart_id,
            product_id=product_id,
            quantity=quantity,
        )
        self.session.add(item)
        await self.session.commit()
        await self.session.refresh(item)
        return item

    async def update_item_quantity(self, item: CartItem, quantity: int) -> CartItem:
        """Update line item quantity."""
        item.quantity = quantity
        await self.session.commit()
        await self.session.refresh(item)
        return item

    async def remove_item(self, item: CartItem) -> None:
        """Delete line item from cart."""
        await self.session.delete(item)
        await self.session.commit()

    async def clear_cart(self, cart_id: uuid.UUID) -> None:
        """Delete all items belonging to a cart."""
        stmt = delete(CartItem).where(CartItem.cart_id == cart_id)
        await self.session.execute(stmt)
        await self.session.commit()


class WishlistRepository:
    """Async database operations for WishlistItem entity."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_items(self, user_id: uuid.UUID) -> list[WishlistItem]:
        """Fetch all wishlist items for a user ordered by newest."""
        stmt = (
            select(WishlistItem)
            .where(WishlistItem.user_id == user_id)
            .options(selectinload(WishlistItem.product))
            .order_by(WishlistItem.created_at.desc())
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_item(self, user_id: uuid.UUID, product_id: uuid.UUID) -> Optional[WishlistItem]:
        """Check if user has product in wishlist."""
        stmt = (
            select(WishlistItem)
            .where(WishlistItem.user_id == user_id, WishlistItem.product_id == product_id)
            .options(selectinload(WishlistItem.product))
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def add_item(self, user_id: uuid.UUID, product_id: uuid.UUID) -> WishlistItem:
        """Add product to user's wishlist."""
        item = WishlistItem(user_id=user_id, product_id=product_id)
        self.session.add(item)
        await self.session.commit()
        await self.session.refresh(item)
        return item

    async def remove_item(self, item: WishlistItem) -> None:
        """Remove product item from wishlist."""
        await self.session.delete(item)
        await self.session.commit()

    async def clear_wishlist(self, user_id: uuid.UUID) -> None:
        """Delete all items in user's wishlist."""
        stmt = delete(WishlistItem).where(WishlistItem.user_id == user_id)
        await self.session.execute(stmt)
        await self.session.commit()
