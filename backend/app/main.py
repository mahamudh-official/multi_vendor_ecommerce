"""
FastAPI application entry point.
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.common.exceptions.handlers import register_exception_handlers
from app.core.config import get_settings
from app.core.database import AsyncSessionLocal, engine
from app.modules.addresses.router import router as addresses_router
from app.modules.admin.router import router as admin_router
from app.modules.auth.router import profile_router, router as auth_router
from app.modules.cart.router import cart_router, wishlist_router
from app.modules.notifications.router import notifications_router
from app.modules.orders.router import order_router
from app.modules.payments.router import payments_router
from app.modules.products.router import router as products_router
from app.modules.reviews.router import reviews_router
from app.modules.seller.router import seller_router

logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan handler.

    On startup: verify database connectivity (no schema creation — use Alembic).
    On shutdown: dispose database engine.
    """
    # ── Startup ────────────────────────────────────────────────────────────
    logger.info("Starting %s v%s", settings.app_name, settings.app_version)
    logger.info("Environment: %s", settings.environment)

    # Verify database connection only — do NOT create tables here.
    # Run `alembic upgrade head` to apply migrations.
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(text("SELECT 1"))
            row = result.scalar()
            if row == 1:
                logger.info("✅ Database connection verified.")
            else:
                logger.error("❌ Database connectivity check returned unexpected result.")
    except Exception as exc:  # noqa: BLE001
        logger.error("❌ Database connection failed: %s", exc)
        # Do not raise — let the app start anyway so /health can report status.

    yield

    # ── Shutdown ───────────────────────────────────────────────────────────
    logger.info("Shutting down — disposing database engine.")
    await engine.dispose()


# ── Application ────────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Production-quality multi-vendor marketplace REST API.",
    lifespan=lifespan,
    docs_url="/docs" if settings.is_development else None,
    redoc_url="/redoc" if settings.is_development else None,
)

# ── Middleware ─────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Exception Handlers ─────────────────────────────────────────────────────
register_exception_handlers(app)

# ── Routers ────────────────────────────────────────────────────────────────
app.include_router(auth_router, prefix="/api/v1")
app.include_router(profile_router, prefix="/api/v1")
app.include_router(addresses_router, prefix="/api/v1")
app.include_router(products_router, prefix="/api/v1")
app.include_router(reviews_router, prefix="/api/v1")
app.include_router(cart_router, prefix="/api/v1")
app.include_router(wishlist_router, prefix="/api/v1")
app.include_router(order_router, prefix="/api/v1")
app.include_router(seller_router, prefix="/api/v1")
app.include_router(payments_router, prefix="/api/v1")
app.include_router(notifications_router, prefix="/api/v1")
app.include_router(admin_router, prefix="/api/v1")


# ── Root & Health Check ───────────────────────────────────────────────────
@app.get("/", tags=["root"], summary="Welcome message")
async def root() -> dict:
    """Root welcome endpoint."""
    return {
        "message": f"Welcome to {settings.app_name} API",
        "version": settings.app_version,
        "docs": "/docs" if settings.is_development else None,
    }


@app.get("/health", tags=["health"], summary="Health check")
async def health_check() -> dict:
    """
    Verify the API is running.

    Returns:
        JSON with app name, version, and status.
    """
    return {
        "status": "ok",
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
    }
