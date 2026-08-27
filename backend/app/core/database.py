"""
Async SQLAlchemy 2.x database configuration.

Schema management is handled exclusively through Alembic migrations.
This module does NOT call Base.metadata.create_all().
"""
from collections.abc import AsyncGenerator
from typing import Annotated

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import get_settings

settings = get_settings()

# ── Engine ─────────────────────────────────────────────────────────────────
engine = create_async_engine(
    settings.database_url,
    echo=settings.is_development,  # SQL logging in dev only
    pool_pre_ping=True,            # Detect stale connections
    pool_size=10,
    max_overflow=20,
)

# ── Session factory ────────────────────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


# ── Declarative Base ───────────────────────────────────────────────────────
class Base(DeclarativeBase):
    """
    All ORM models must inherit from this base.
    Alembic's env.py imports this to detect model metadata.
    """
    pass


# ── FastAPI dependency ─────────────────────────────────────────────────────
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Yield an async database session for use in request handlers.
    The session is automatically closed after the request.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

