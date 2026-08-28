import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_security_headers_present(client: AsyncClient):
    """Verify that all standard security headers are injected in all responses."""
    response = await client.get("/health")
    assert response.status_code == 200
    
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Referrer-Policy"] == "strict-origin-when-cross-origin"
    assert response.headers["Content-Security-Policy"] == "default-src 'none'; frame-ancestors 'none';"
    assert response.headers["X-XSS-Protection"] == "0"
    assert "X-Request-ID" in response.headers


@pytest.mark.asyncio
async def test_hsts_header_on_https_requests(client: AsyncClient):
    """Verify that HSTS headers are attached when requests are sent over HTTPS."""
    # We can simulate an HTTPS request by updating the base URL scheme of httpx client
    async with AsyncClient(transport=client._transport, base_url="https://test") as https_client:
        response = await https_client.get("/health")
        assert response.status_code == 200
        assert "Strict-Transport-Security" in response.headers
        assert "max-age=31536000" in response.headers["Strict-Transport-Security"]

