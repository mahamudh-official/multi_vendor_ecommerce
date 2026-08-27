"""
Database connectivity tests.

These tests verify the SQLAlchemy engine can connect to the database.
They require a running PostgreSQL instance (available via docker compose).
Tests are skipped automatically if DATABASE_URL is not set or DB is unreachable.
"""
import os

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

DATABASE_URL = os.getenv("DATABASE_URL")


@pytest.mark.asyncio
@pytest.mark.skipif(
    not DATABASE_URL,
    reason="DATABASE_URL not set — skipping live database test.",
)
async def test_database_connection():
    """Verify async SQLAlchemy can connect and execute a simple query."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    try:
        async with engine.connect() as conn:
            result = await conn.execute(text("SELECT 1"))
            value = result.scalar()
        assert value == 1, f"Expected SELECT 1 to return 1, got {value}"
    finally:
        await engine.dispose()


@pytest.mark.asyncio
@pytest.mark.skipif(
    not DATABASE_URL,
    reason="DATABASE_URL not set — skipping live database test.",
)
async def test_users_table_exists():
    """
    Verify the users table exists after running alembic upgrade head.
    Requires DB to be running with migrations applied.
    """
    engine = create_async_engine(DATABASE_URL, echo=False)
    try:
        async with engine.connect() as conn:
            result = await conn.execute(
                text(
                    "SELECT EXISTS ("
                    "  SELECT FROM information_schema.tables "
                    "  WHERE table_schema = 'public' "
                    "  AND table_name = 'users'"
                    ")"
                )
            )
            exists = result.scalar()
        assert exists is True, "users table should exist after alembic upgrade head"
    finally:
        await engine.dispose()

