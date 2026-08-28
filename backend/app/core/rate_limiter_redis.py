"""
Redis-backed sliding window rate limiting for FastAPI.
"""
import logging
import time
from typing import Optional

from fastapi import HTTPException, status
import redis.asyncio as aioredis

from app.core.config import get_settings

logger = logging.getLogger("app.rate_limiter")

# Lua script for atomic sliding window rate limiting using sorted sets
LUA_SLIDING_WINDOW = """
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
local clear_before = now - window

-- Remove expired elements
redis.call('ZREMRANGEBYSCORE', key, '-inf', clear_before)

-- Count remaining elements
local current_requests = redis.call('ZCARD', key)

if current_requests < limit then
    -- Allowed: record timestamp and set TTL
    redis.call('ZADD', key, now, now)
    redis.call('EXPIRE', key, window)
    return {1, 0}
else
    -- Exceeded: calculate retry after based on the oldest element in the set
    local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
    if #oldest >= 2 then
        local oldest_time = tonumber(oldest[2])
        local retry_after = oldest_time + window - now
        return {0, math.max(1, math.ceil(retry_after))}
    else
        return {0, window}
    end
end
"""


class RedisRateLimiter:
    """
    Sliding window Redis-backed rate limiter.
    Uses Lua script execution to guarantee atomicity and thread safety.
    """

    def __init__(self, redis_url: str) -> None:
        self.redis_url = redis_url
        self.pool = aioredis.ConnectionPool.from_url(redis_url, decode_responses=True)
        self.client = aioredis.Redis(connection_pool=self.pool)
        self._script = None

    async def init(self) -> None:
        """Registers the Lua script in Redis."""
        self._script = self.client.register_script(LUA_SLIDING_WINDOW)

    async def check_rate_limit(
        self,
        key: str,
        max_requests: int,
        window_seconds: int = 60,
    ) -> None:
        """
        Check if request is allowed.
        Raises HTTP 429 Too Many Requests if limit is exceeded.
        """
        if self._script is None:
            await self.init()

        now = time.time()
        try:
            allowed, retry_after = await self._script(
                keys=[key],
                args=[str(now), str(window_seconds), str(max_requests)]
            )
            if not allowed:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Rate limit exceeded. Maximum {max_requests} requests per {window_seconds}s.",
                    headers={"Retry-After": str(retry_after)},
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error("Redis rate limiter connection error: %s", e)
            settings = get_settings()
            # Production environment fail-closed behavior for security
            if settings.environment.lower() != "development":
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Rate limiting check failed. Service temporarily unavailable.",
                )
            else:
                # Local development allows fallback or logs error
                raise e

    async def close(self) -> None:
        """Close connection pools."""
        try:
            if hasattr(self.client, "aclose"):
                await self.client.aclose()
            else:
                await self.client.close()
            await self.pool.disconnect()
        except Exception:
            pass


_redis_limiter: Optional[RedisRateLimiter] = None


def get_redis_rate_limiter() -> Optional[RedisRateLimiter]:
    """Returns the singleton RedisRateLimiter instance if REDIS_URL is configured."""
    global _redis_limiter
    if _redis_limiter is None:
        settings = get_settings()
        if settings.redis_url:
            _redis_limiter = RedisRateLimiter(settings.redis_url)
    return _redis_limiter
