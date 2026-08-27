"""
FastAPI routers for Shopping Cart and Wishlist endpoints.
"""
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.modules.auth.dependencies import get_current_active_user
from app.modules.auth.models import User
from app.modules.auth.schemas import MessageResponse
from app.modules.cart.dependencies import (
    get_cart_service,
    get_wishlist_service,
)
from app.modules.cart.schemas import (
    AddToCartRequest,
    CartRead,
    UpdateCartItemRequest,
    WishlistItemRead,
)
from app.modules.cart.service import CartService, WishlistService

cart_router = APIRouter(prefix="/cart", tags=["Shopping Cart"])
wishlist_router = APIRouter(prefix="/wishlist", tags=["Wishlist"])


# ── Cart Endpoints ─────────────────────────────────────────────────────────

@cart_router.get(
    "",
    response_model=CartRead,
    status_code=status.HTTP_200_OK,
    summary="Get current customer shopping cart",
)
async def get_cart(
    cart_service: Annotated[CartService, Depends(get_cart_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> CartRead:
    """Fetch or initialize the authenticated customer's shopping cart."""
    return await cart_service.get_cart(current_user)


@cart_router.post(
    "/items",
    response_model=CartRead,
    status_code=status.HTTP_200_OK,
    summary="Add product to shopping cart",
)
async def add_to_cart(
    request: AddToCartRequest,
    cart_service: Annotated[CartService, Depends(get_cart_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> CartRead:
    """Add a product to cart with server-side stock verification."""
    return await cart_service.add_to_cart(current_user, request)


@cart_router.patch(
    "/items/{item_id}",
    response_model=CartRead,
    status_code=status.HTTP_200_OK,
    summary="Update cart item quantity",
)
async def update_cart_item(
    item_id: uuid.UUID,
    request: UpdateCartItemRequest,
    cart_service: Annotated[CartService, Depends(get_cart_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> CartRead:
    """Update line item quantity with server-side stock verification."""
    return await cart_service.update_cart_item(current_user, item_id, request)


@cart_router.delete(
    "/items/{item_id}",
    response_model=CartRead,
    status_code=status.HTTP_200_OK,
    summary="Remove item from shopping cart",
)
async def remove_cart_item(
    item_id: uuid.UUID,
    cart_service: Annotated[CartService, Depends(get_cart_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> CartRead:
    """Remove a line item from customer cart."""
    return await cart_service.remove_cart_item(current_user, item_id)


@cart_router.delete(
    "",
    response_model=CartRead,
    status_code=status.HTTP_200_OK,
    summary="Clear all items from shopping cart",
)
async def clear_cart(
    cart_service: Annotated[CartService, Depends(get_cart_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> CartRead:
    """Empty all items from customer cart."""
    return await cart_service.clear_cart(current_user)


# ── Wishlist Endpoints ─────────────────────────────────────────────────────

@wishlist_router.get(
    "",
    response_model=list[WishlistItemRead],
    status_code=status.HTTP_200_OK,
    summary="Get customer wishlist items",
)
async def get_wishlist(
    wishlist_service: Annotated[WishlistService, Depends(get_wishlist_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> list[WishlistItemRead]:
    """List all products saved in the customer's wishlist."""
    return await wishlist_service.get_wishlist(current_user)


@wishlist_router.post(
    "/items/{product_id}",
    response_model=WishlistItemRead,
    status_code=status.HTTP_200_OK,
    summary="Add product to wishlist (Idempotent)",
)
async def add_to_wishlist(
    product_id: uuid.UUID,
    wishlist_service: Annotated[WishlistService, Depends(get_wishlist_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> WishlistItemRead:
    """Add product to customer wishlist. Idempotent if already added."""
    return await wishlist_service.add_to_wishlist(current_user, product_id)


@wishlist_router.delete(
    "/items/{product_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Remove product from wishlist",
)
async def remove_from_wishlist(
    product_id: uuid.UUID,
    wishlist_service: Annotated[WishlistService, Depends(get_wishlist_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> MessageResponse:
    """Remove product from customer wishlist."""
    await wishlist_service.remove_from_wishlist(current_user, product_id)
    return MessageResponse(message="Product removed from wishlist.")


@wishlist_router.delete(
    "",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Clear entire wishlist",
)
async def clear_wishlist(
    wishlist_service: Annotated[WishlistService, Depends(get_wishlist_service)],
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> MessageResponse:
    """Remove all items from customer wishlist."""
    await wishlist_service.clear_wishlist(current_user)
    return MessageResponse(message="Wishlist cleared.")

