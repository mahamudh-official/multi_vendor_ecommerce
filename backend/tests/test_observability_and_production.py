"""
Backend tests for Observability, Production Configuration, Correlation ID, and Rate Limiting.
"""
import uuid
import pytest
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError

from app.core.config import Settings
from app.core.rate_limiter import rate_limiter_instance
from app.main import app


@pytest.fixture(autouse=True)
def reset_rate_limiter():
    """Reset rate limiter state before each test."""
    rate_limiter_instance.reset()
    yield
    rate_limiter_instance.reset()


@pytest.mark.asyncio
async def test_health_liveness_endpoint():
    """1 & 2. GET /health returns 200 and status ok."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.get("/health")

    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert "version" in data
    assert "environment" in data


@pytest.mark.asyncio
async def test_ready_readiness_endpoint():
    """3. GET /ready executes DB query and returns 200 ready."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.get("/ready")

    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ready"
    assert data["database"] == "connected"


def test_production_weak_secret_rejected():
    """4. Production environment rejects default/insecure secrets."""
    with pytest.raises(ValidationError) as exc:
        Settings(
            database_url="postgresql+asyncpg://user:pass@localhost:5432/db",
            secret_key="change-this-secret-key-in-production-longer-than-32-chars",
            environment="production",
        )
    assert "Insecure default SECRET_KEY" in str(exc.value)


def test_production_short_secret_rejected():
    """5. Production environment rejects secrets shorter than 32 characters."""
    with pytest.raises(ValidationError) as exc:
        Settings(
            database_url="postgresql+asyncpg://user:pass@localhost:5432/db",
            secret_key="short-secret-key",
            environment="production",
        )
    assert "must be at least 32 characters" in str(exc.value)


def test_production_valid_secret_accepted():
    """6. Production environment accepts strong secrets >= 32 chars."""
    valid_key = "a" * 32
    s = Settings(
        database_url="postgresql://user:pass@localhost:5432/db",
        secret_key=valid_key,
        environment="production",
    )
    assert s.is_production is True
    assert s.database_url.startswith("postgresql+asyncpg://")


@pytest.mark.asyncio
async def test_request_id_generated_when_absent():
    """7. X-Request-ID is generated automatically when absent in request headers."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.get("/health")

    assert res.status_code == 200
    assert "x-request-id" in res.headers
    req_id = res.headers["x-request-id"]
    assert len(req_id) > 10


@pytest.mark.asyncio
async def test_request_id_propagated_when_supplied():
    """8. Supplied X-Request-ID header is echoed in the response."""
    custom_id = f"custom-req-{uuid.uuid4().hex}"
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.get("/health", headers={"X-Request-ID": custom_id})

    assert res.status_code == 200
    assert res.headers.get("x-request-id") == custom_id


@pytest.mark.asyncio
async def test_rate_limiter_blocks_and_sets_retry_after():
    """9 & 10. Rapid calls trigger 429 Too Many Requests with Retry-After header."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # Check rate limiting using in-memory rate limiter directly
        key = "test_key"
        # Allowed up to 3 calls
        for _ in range(3):
            await rate_limiter_instance.check_rate_limit(key=key, max_requests=3, window_seconds=60)

        # 4th call must raise 429
        with pytest.raises(Exception) as exc:
            await rate_limiter_instance.check_rate_limit(key=key, max_requests=3, window_seconds=60)

        err = exc.value
        assert hasattr(err, "status_code")
        assert err.status_code == 429
        assert "Retry-After" in err.headers

