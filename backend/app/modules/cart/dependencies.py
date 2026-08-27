"""
FastAPI dependencies for Cart and Wishlist modules.
"""
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.cart.repository import CartRepository, WishlistRepository
from app.modules.cart.service import CartService, WishlistService
from app.modules.products.dependencies import get_product_repository
from app.modules.products.repository import ProductRepository


def get_cart_repository(session: AsyncSession = Depends(get_db)) -> CartRepository:
    """Dependency providing CartRepository bound to request DB session."""
    return CartRepository(session)


def get_wishlist_repository(session: AsyncSession = Depends(get_db)) -> WishlistRepository:
    """Dependency providing WishlistRepository bound to request DB session."""
    return WishlistRepository(session)


def get_cart_service(
    cart_repo: CartRepository = Depends(get_cart_repository),
    product_repo: ProductRepository = Depends(get_product_repository),
) -> CartService:
    """Dependency providing CartService."""
    return CartService(cart_repo, product_repo)


def get_wishlist_service(
    wishlist_repo: WishlistRepository = Depends(get_wishlist_repository),
    product_repo: ProductRepository = Depends(get_product_repository),
) -> WishlistService:
    """Dependency providing WishlistService."""
    return WishlistService(wishlist_repo, product_repo)

