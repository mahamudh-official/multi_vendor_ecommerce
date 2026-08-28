import asyncio
import time
import pytest
from unittest.mock import patch
from fastapi import HTTPException, Request
from app.core.config import get_settings
from app.core.rate_limiter import rate_limit
from app.core.rate_limiter_redis import RedisRateLimiter, get_redis_rate_limiter

# Redis connection URL for local test container
REDIS_TEST_URL = "redis://localhost:6379/0"


@pytest.fixture
async def redis_limiter():
    limiter = RedisRateLimiter(REDIS_TEST_URL)
    await limiter.init()
    yield limiter
    await limiter.close()


@pytest.mark.asyncio
async def test_redis_rate_limiter_sliding_window(redis_limiter):
    """Verify that RedisRateLimiter enforces limits, blocks, and handles Retry-After."""
    key = "test:sliding_window:client_ip"
    max_requests = 3
    window = 2

    # Clear any leftover keys from previous tests
    await redis_limiter.client.delete(key)

    # 1. First 3 requests should be allowed
    for _ in range(max_requests):
        await redis_limiter.check_rate_limit(key, max_requests, window)

    # 2. 4th request must be blocked with HTTP 429
    with pytest.raises(HTTPException) as exc_info:
        await redis_limiter.check_rate_limit(key, max_requests, window)
    
    assert exc_info.value.status_code == 429
    assert "Retry-After" in exc_info.value.headers
    retry_after = int(exc_info.value.headers["Retry-After"])
    assert retry_after > 0

    # 3. Wait for the window to expire, then requests should be allowed again
    await asyncio.sleep(window + 0.1)
    await redis_limiter.check_rate_limit(key, max_requests, window)


@pytest.mark.asyncio
async def test_redis_rate_limiter_fail_closed_in_production():
    """Verify that in production mode, Redis failures fail closed (HTTP 500)."""
    # Create a limiter pointing to a broken port
    broken_limiter = RedisRateLimiter("redis://localhost:9999/0")
    
    # Mock settings to return production environment
    with patch("app.core.rate_limiter_redis.get_settings") as mock_settings:
        from pydantic_settings import BaseSettings
        class MockSettings:
            environment = "production"
            redis_url = "redis://localhost:9999/0"
        
        mock_settings.return_value = MockSettings()

        with pytest.raises(HTTPException) as exc_info:
            await broken_limiter.check_rate_limit("test:fail_closed", 5, 60)
        
        assert exc_info.value.status_code == 500
        assert "Service temporarily unavailable" in exc_info.value.detail


@pytest.mark.asyncio
async def test_redis_rate_limiter_fallback_in_development():
    """Verify that in development mode, a connection failure in Redis raises the connection error (to trigger fallback)."""
    broken_limiter = RedisRateLimiter("redis://localhost:9999/0")
    
    with patch("app.core.rate_limiter_redis.get_settings") as mock_settings:
        class MockSettings:
            environment = "development"
            redis_url = "redis://localhost:9999/0"
            is_development = True
        
        mock_settings.return_value = MockSettings()

        # In development, the raw connection exception (e.g. ConnectionError) should propagate
        import redis
        with pytest.raises(redis.exceptions.ConnectionError):
            await broken_limiter.check_rate_limit("test:fallback", 5, 60)
