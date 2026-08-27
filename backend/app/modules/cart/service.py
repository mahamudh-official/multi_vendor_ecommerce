"""
Business logic services for Shopping Cart and Wishlist.
"""
from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Optional

from app.common.exceptions.handlers import (
    BadRequestException,
    NotFoundException,
)
from app.modules.auth.models import User
from app.modules.cart.models import Cart, CartItem
from app.modules.cart.repository import CartRepository, WishlistRepository
from app.modules.cart.schemas import (
    AddToCartRequest,
    CartItemProductRead,
    CartItemRead,
    CartRead,
    UpdateCartItemRequest,
    WishlistItemRead,
)
from app.modules.products.repository import ProductRepository


class CartService:
    """Business logic for customer cart operations and calculations."""

    def __init__(
        self,
        cart_repo: CartRepository,
        product_repo: ProductRepository,
    ) -> None:
        self.cart_repo = cart_repo
        self.product_repo = product_repo

    def _format_cart_response(self, cart: Cart) -> CartRead:
        """Calculate line totals, item count, and subtotal dynamically from current prices."""
        items_read: list[CartItemRead] = []
        total_items = 0
        subtotal = Decimal("0.00")

        for item in cart.items:
            product = item.product
            # Check active status & stock availability
            is_active = product.is_active
            is_available = is_active and product.stock_quantity >= item.quantity
            stock_warning = None

            if not is_active:
                stock_warning = "This product is no longer active."
            elif product.stock_quantity == 0:
                stock_warning = "This product is currently out of stock."
            elif product.stock_quantity < item.quantity:
                stock_warning = f"Only {product.stock_quantity} available in stock."

            price = Decimal(str(product.price))
            line_total = (price * Decimal(item.quantity)).quantize(Decimal("0.01"))

            if is_available:
                total_items += item.quantity
                subtotal += line_total

            items_read.append(
                CartItemRead(
                    id=item.id,
                    product=CartItemProductRead(
                        id=product.id,
                        name=product.name,
                        slug=product.slug,
                        price=price,
                        image_url=product.image_url,
                        stock_quantity=product.stock_quantity,
                        is_active=product.is_active,
                    ),
                    quantity=item.quantity,
                    line_total=line_total,
                    is_available=is_available,
                    stock_warning=stock_warning,
                )
            )

        return CartRead(
            id=cart.id,
            items=items_read,
            item_count=total_items,
            subtotal=subtotal.quantize(Decimal("0.01")),
        )

    async def get_cart(self, user: User) -> CartRead:
        """Fetch or initialize active customer cart."""
        cart = await self.cart_repo.get_or_create_cart(user.id)
        return self._format_cart_response(cart)

    async def add_to_cart(self, user: User, request: AddToCartRequest) -> CartRead:
        """
        Add product to customer cart.
        If product already exists in cart, increases its quantity.
        Validates product existence, active status, and available stock.
        """
        product = await self.product_repo.get_by_id(
            request.product_id,
            include_inactive=True,
        )
        if product is None:
            raise NotFoundException(detail="Product not found.")
        if not product.is_active:
            raise BadRequestException(detail="Product is no longer available.")
        if product.stock_quantity < request.quantity:
            raise BadRequestException(
                detail=f"Not enough stock available. Only {product.stock_quantity} remaining.",
            )

        cart = await self.cart_repo.get_or_create_cart(user.id)
        existing_item = await self.cart_repo.get_cart_item_by_product(
            cart.id,
            request.product_id,
        )

        if existing_item is not None:
            new_qty = existing_item.quantity + request.quantity
            if new_qty > product.stock_quantity:
                raise BadRequestException(
                    detail=f"Cannot add {request.quantity} more. Total would exceed available stock of {product.stock_quantity}.",
                )
            await self.cart_repo.update_item_quantity(existing_item, new_qty)
        else:
            await self.cart_repo.add_item(cart.id, request.product_id, request.quantity)

        # Reload cart with latest items
        cart = await self.cart_repo.get_or_create_cart(user.id)
        return self._format_cart_response(cart)

    async def update_cart_item(
        self,
        user: User,
        item_id: uuid.UUID,
        request: UpdateCartItemRequest,
    ) -> CartRead:
        """
        Update the quantity of an item in the customer's cart.
        Enforces item ownership and server-side stock verification.
        """
        cart = await self.cart_repo.get_or_create_cart(user.id)
        item = await self.cart_repo.get_cart_item(cart.id, item_id)
        if item is None:
            raise NotFoundException(detail="Cart item not found.")

        product = item.product
        if not product.is_active:
            raise BadRequestException(detail="Product is no longer available.")
        if request.quantity > product.stock_quantity:
            raise BadRequestException(
                detail=f"Requested quantity exceeds available stock of {product.stock_quantity}.",
            )

        await self.cart_repo.update_item_quantity(item, request.quantity)
        cart = await self.cart_repo.get_or_create_cart(user.id)
        return self._format_cart_response(cart)

    async def remove_cart_item(self, user: User, item_id: uuid.UUID) -> CartRead:
        """Remove a line item from customer's cart with ownership verification."""
        cart = await self.cart_repo.get_or_create_cart(user.id)
        item = await self.cart_repo.get_cart_item(cart.id, item_id)
        if item is None:
            raise NotFoundException(detail="Cart item not found.")

        await self.cart_repo.remove_item(item)
        cart = await self.cart_repo.get_or_create_cart(user.id)
        return self._format_cart_response(cart)

    async def clear_cart(self, user: User) -> CartRead:
        """Empty all line items from the customer's cart."""
        cart = await self.cart_repo.get_or_create_cart(user.id)
        await self.cart_repo.clear_cart(cart.id)
        cart = await self.cart_repo.get_or_create_cart(user.id)
        return self._format_cart_response(cart)


class WishlistService:
    """Business logic for customer wishlist operations."""

    def __init__(
        self,
        wishlist_repo: WishlistRepository,
        product_repo: ProductRepository,
    ) -> None:
        self.wishlist_repo = wishlist_repo
        self.product_repo = product_repo

    async def get_wishlist(self, user: User) -> list[WishlistItemRead]:
        """Fetch all wishlist items for the customer."""
        items = await self.wishlist_repo.list_items(user.id)
        return [
            WishlistItemRead(
                id=item.id,
                product=CartItemProductRead.model_validate(item.product),
                created_at=item.created_at,
            )
            for item in items
        ]

    async def add_to_wishlist(self, user: User, product_id: uuid.UUID) -> WishlistItemRead:
        """
        Add product to customer's wishlist.
        Idempotent: if already in wishlist, returns existing entry.
        """
        product = await self.product_repo.get_by_id(product_id, include_inactive=True)
        if product is None:
            raise NotFoundException(detail="Product not found.")

        existing = await self.wishlist_repo.get_item(user.id, product_id)
        if existing is not None:
            return WishlistItemRead(
                id=existing.id,
                product=CartItemProductRead.model_validate(existing.product),
                created_at=existing.created_at,
            )

        item = await self.wishlist_repo.add_item(user.id, product_id)
        return WishlistItemRead(
            id=item.id,
            product=CartItemProductRead.model_validate(product),
            created_at=item.created_at,
        )

    async def remove_from_wishlist(self, user: User, product_id: uuid.UUID) -> None:
        """Remove product from customer's wishlist."""
        item = await self.wishlist_repo.get_item(user.id, product_id)
        if item is not None:
            await self.wishlist_repo.remove_item(item)

    async def clear_wishlist(self, user: User) -> None:
        """Remove all products from customer's wishlist."""
        await self.wishlist_repo.clear_wishlist(user.id)

