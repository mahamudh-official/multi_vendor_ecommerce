"""
In-memory sliding window rate limiting for FastAPI endpoints.

Architectural Note:
This in-memory rate limiter provides zero-dependency protection against brute force
and abusive request bursts for single-worker or development/staging environments.
For multi-instance distributed deployments, a shared Redis-backed limiter is recommended.
"""
from __future__ import annotations

import asyncio
import time
from collections import defaultdict
from typing import Callable, DefaultDict, Dict, List

from fastapi import HTTPException, Request, status

from app.core.config import get_settings


class InMemoryRateLimiter:
    """
    Sliding window in-memory rate limiter.
    Stores timestamps of requests per client key and purges expired records.
    """

    def __init__(self) -> None:
        self._records: DefaultDict[str, List[float]] = defaultdict(list)
        self._lock = asyncio.Lock()
        self._last_cleanup = time.time()

    async def check_rate_limit(
        self,
        key: str,
        max_requests: int,
        window_seconds: int = 60,
    ) -> None:
        """
        Check if the key has exceeded max_requests within window_seconds.
        Raises HTTP 429 Too Many Requests with Retry-After header if limit is exceeded.
        """
        now = time.time()
        window_start = now - window_seconds

        async with self._lock:
            # 1. Periodic cleanup of stale keys (every 5 minutes)
            if now - self._last_cleanup > 300:
                self._cleanup_stale_records(window_start)
                self._last_cleanup = now

            # 2. Filter out timestamps older than the window
            timestamps = [t for t in self._records[key] if t > window_start]
            self._records[key] = timestamps

            # 3. Check limit
            if len(timestamps) >= max_requests:
                earliest = timestamps[0]
                retry_after = max(1, int(earliest + window_seconds - now))
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Rate limit exceeded. Maximum {max_requests} requests per {window_seconds}s.",
                    headers={"Retry-After": str(retry_after)},
                )

            # 4. Record new request
            self._records[key].append(now)

    def _cleanup_stale_records(self, cutoff: float) -> None:
        """Purge keys whose timestamps are all expired."""
        stale_keys = [
            k for k, v in self._records.items()
            if not v or v[-1] < cutoff
        ]
        for k in stale_keys:
            del self._records[k]

    def reset(self) -> None:
        """Clear all rate limit records (useful in test teardown)."""
        self._records.clear()


# Global in-memory rate limiter singleton
rate_limiter_instance = InMemoryRateLimiter()


def rate_limit(
    max_requests: int,
    window_seconds: int = 60,
    key_prefix: str = "",
) -> Callable:
    """
    FastAPI dependency factory enforcing rate limits by client IP and prefix.
    """

    async def dependency(request: Request) -> None:
        import sys

        settings = get_settings()
        # In test mode or when running under pytest, allow test suites to run unhindered unless explicitly testing rate limits
        if ("pytest" in sys.modules or settings.environment.lower() in ("test", "testing")) and not request.headers.get("X-Enforce-Rate-Limit"):
            return

        # Determine client key
        client_ip = request.client.host if request.client else "unknown"
        # Combine IP, prefix, and path for route-specific isolation
        key = f"{key_prefix}:{request.url.path}:{client_ip}"

        from app.core.rate_limiter_redis import get_redis_rate_limiter
        redis_limiter = get_redis_rate_limiter()

        if redis_limiter:
            try:
                await redis_limiter.check_rate_limit(
                    key=key,
                    max_requests=max_requests,
                    window_seconds=window_seconds,
                )
                return
            except Exception as e:
                if isinstance(e, HTTPException):
                    raise e
                # Fail open to in-memory fallback only in local development
                if settings.environment.lower() == "development":
                    import logging
                    logging.getLogger("app.rate_limiter").warning(
                        "Redis rate limiter down. Falling back to InMemoryRateLimiter in dev: %s", e
                    )
                else:
                    # Fail closed in staging/production for security-sensitive rate limiting
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail="Rate limiting check failed. Service temporarily unavailable.",
                    )

        await rate_limiter_instance.check_rate_limit(
            key=key,
            max_requests=max_requests,
            window_seconds=window_seconds,
        )

    return dependency
