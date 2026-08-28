"""
FastAPI application entry point with Observability, OpenAPI Documentation, and Readiness Checks.
"""
import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.exceptions.handlers import register_exception_handlers
from app.core.config import get_settings
from app.core.database import AsyncSessionLocal, engine, get_db
from app.core.middleware import RequestCorrelationMiddleware
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

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("app.main")
settings = get_settings()

OPENAPI_TAGS = [
    {"name": "System", "description": "Liveness, readiness, and API root endpoints."},
    {"name": "Auth", "description": "Authentication, user registration, token management, and password reset."},
    {"name": "Profile", "description": "Customer and vendor profile retrieval and whitelisted updates."},
    {"name": "Addresses", "description": "Customer delivery address CRUD and default address management."},
    {"name": "Products", "description": "Public product browsing, search, filter, and pagination."},
    {"name": "Categories", "description": "Product taxonomy and category tree navigation."},
    {"name": "Cart", "description": "Customer shopping cart operations and stock reservations."},
    {"name": "Wishlist", "description": "Customer saved items and wishlist management."},
    {"name": "Orders", "description": "Order creation, checkout snapshots, and order history filtering."},
    {"name": "Seller", "description": "Seller product inventory, order fulfillment, and order status lifecycle."},
    {"name": "Analytics", "description": "Seller revenue, order volume, and top-selling product metrics."},
    {"name": "Payments", "description": "Payment intent creation, mock provider simulation, and webhook processing."},
    {"name": "Reviews", "description": "Verified-purchase product reviews, ratings, and moderation."},
    {"name": "Notifications", "description": "Real-time user notification feed and unread counters."},
    {"name": "Admin", "description": "Platform management, vendor approvals, product moderation, and audit logs."},
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan handler.
    On startup: verify database connectivity.
    On shutdown: dispose database engine.
    """
    logger.info("Starting %s v%s [Environment: %s]", settings.app_name, settings.app_version, settings.environment)

    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(text("SELECT 1"))
            row = result.scalar()
            if row == 1:
                logger.info("✅ PostgreSQL database connectivity verified.")
            else:
                logger.error("❌ Database connectivity check returned unexpected result.")
    except Exception as exc:  # noqa: BLE001
        logger.error("❌ Database connection failed at startup: %s", exc)

    yield

    logger.info("Shutting down — disposing database engine.")
    await engine.dispose()


# ── Application Instance ───────────────────────────────────────────────────
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Production-grade multi-vendor marketplace REST API with PostgreSQL, BLoC frontend, and Clean Architecture.",
    openapi_tags=OPENAPI_TAGS,
    lifespan=lifespan,
    docs_url="/docs" if settings.is_development else None,
    redoc_url="/redoc" if settings.is_development else None,
)

# ── Middleware ─────────────────────────────────────────────────────────────
app.add_middleware(RequestCorrelationMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID", "Retry-After"],
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


# ── System Endpoints ───────────────────────────────────────────────────────
@app.get("/", tags=["System"], summary="Welcome message and API root")
async def root() -> dict:
    """Root welcome endpoint providing API info and documentation link."""
    return {
        "message": f"Welcome to {settings.app_name} API",
        "version": settings.app_version,
        "environment": settings.environment,
        "docs": "/docs" if settings.is_development else None,
    }


@app.get("/health", tags=["System"], summary="Process liveness check")
async def health_check() -> dict:
    """
    Process liveness probe for container orchestrators (Kubernetes / Docker).
    Does NOT query the database.
    """
    return {
        "status": "ok",
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
    }


@app.get("/ready", tags=["System"], summary="PostgreSQL database readiness check")
async def readiness_check(session: AsyncSession = Depends(get_db)) -> dict:
    """
    Readiness probe verifying the application can execute database queries.
    Returns HTTP 200 when ready or HTTP 503 when the database is unavailable.
    """
    try:
        result = await asyncio.wait_for(session.execute(text("SELECT 1")), timeout=3.0)
        if result.scalar() == 1:
            return {
                "status": "ready",
                "database": "connected",
                "app": settings.app_name,
                "version": settings.app_version,
                "environment": settings.environment,
            }
        raise RuntimeError("Unexpected DB response")
    except Exception as exc:
        logger.error("Readiness check failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database connection unavailable",
        ) from exc
