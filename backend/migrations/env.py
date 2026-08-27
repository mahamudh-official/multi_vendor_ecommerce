"""
Alembic environment configuration for async SQLAlchemy 2.x.

Uses asyncpg as the async driver. Database URL is loaded from environment
variables (never hardcoded in this file or alembic.ini).
"""
import asyncio
import os
import sys
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import create_async_engine

# ── Make the backend package importable ───────────────────────────────────────
# Prepend the backend root to sys.path so `from app.xxx import ...` works.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# ── Import all models so Alembic detects them ─────────────────────────────────
# IMPORTANT: Every module containing ORM models must be imported here so
# that Alembic's autogenerate can discover table metadata.
from app.core.database import Base  # noqa: E402
from app.modules.auth import models as auth_models  # noqa: E402, F401
from app.modules.products import models as product_models  # noqa: E402, F401
from app.modules.cart import models as cart_models  # noqa: E402, F401
from app.modules.orders import models as order_models  # noqa: E402, F401

# ── Alembic Config ────────────────────────────────────────────────────────────
config = context.config

# ── Logging ───────────────────────────────────────────────────────────────────
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# ── Metadata ──────────────────────────────────────────────────────────────────
target_metadata = Base.metadata


# ── Database URL ──────────────────────────────────────────────────────────────
def get_url() -> str:
    """
    Read the database URL from the environment.

    Falls back to .env via python-dotenv if DATABASE_URL is not already set.
    """
    from dotenv import load_dotenv

    load_dotenv()
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError(
            "DATABASE_URL environment variable is not set. "
            "Copy backend/.env.example to backend/.env and fill in values."
        )
    return url


# ── Offline migrations (SQL script output) ───────────────────────────────────
def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (generates SQL without a live DB)."""
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


# ── Online migrations (async, against live DB) ────────────────────────────────
def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations using an async engine (asyncpg)."""
    connectable = create_async_engine(
        get_url(),
        poolclass=pool.NullPool,  # No pool for migration runs
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    """Entry point for online migrations."""
    asyncio.run(run_async_migrations())


# ── Entrypoint ────────────────────────────────────────────────────────────────
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
