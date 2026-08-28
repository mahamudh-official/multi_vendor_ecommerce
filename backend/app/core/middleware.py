"""
Observability and Correlation ID Middleware for FastAPI.
"""
import logging
import time
import uuid
from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger("app.access")


class RequestCorrelationMiddleware(BaseHTTPMiddleware):
    """
    Middleware that ensures every HTTP request has a unique correlation ID (X-Request-ID).
    Measures processing duration and logs structured, non-sensitive access metrics.
    """

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # 1. Extract or generate Correlation ID
        req_id = request.headers.get("X-Request-ID")
        if not req_id or not req_id.strip():
            req_id = str(uuid.uuid4())
        else:
            req_id = req_id.strip()

        request.state.request_id = req_id

        # 2. Timing
        start_time = time.perf_counter()

        # 3. Process request
        try:
            response = await call_next(request)
        except Exception as exc:
            duration_ms = (time.perf_counter() - start_time) * 1000.0
            client_ip = request.client.host if request.client else "unknown"
            logger.error(
                "[%s] %s %s -> UNHANDLED EXCEPTION in %.2fms | client=%s | error=%s",
                req_id,
                request.method,
                request.url.path,
                duration_ms,
                client_ip,
                str(exc),
            )
            raise exc

        # 4. Compute duration and log safely
        duration_ms = (time.perf_counter() - start_time) * 1000.0
        client_ip = request.client.host if request.client else "unknown"

        logger.info(
            "[%s] %s %s -> %d in %.2fms | client=%s",
            req_id,
            request.method,
            request.url.path,
            response.status_code,
            duration_ms,
            client_ip,
        )

        # 5. Attach X-Request-ID header to response
        response.headers["X-Request-ID"] = req_id
        return response

