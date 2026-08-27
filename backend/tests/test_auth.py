"""
Comprehensive backend tests for authentication and authorization.
Covers all 14 required authentication test scenarios.
"""
import uuid
import pytest
from httpx import AsyncClient

from app.core.security import create_access_token, create_refresh_token


@pytest.fixture
def unique_email() -> str:
    """Generate a unique email for test isolation."""
    return f"user_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient, unique_email: str):
    """1. Register success - creates customer user and returns 201."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Test Customer",
            "email": unique_email,
            "password": "Password123!",
            "role": "customer",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == unique_email.lower()
    assert data["full_name"] == "Test Customer"
    assert data["role"] == "customer"
    assert "password" not in data
    assert "password_hash" not in data
    assert "id" in data


@pytest.mark.asyncio
async def test_duplicate_email(client: AsyncClient, unique_email: str):
    """2. Duplicate email - registration rejects already registered email with 409."""
    # First registration
    r1 = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Initial User",
            "email": unique_email,
            "password": "Password123!",
            "role": "customer",
        },
    )
    assert r1.status_code == 201

    # Second registration with same email (case-insensitive test)
    r2 = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Duplicate User",
            "email": unique_email.upper(),
            "password": "Password123!",
            "role": "customer",
        },
    )
    assert r2.status_code == 409
    assert "already exists" in r2.json()["detail"].lower()


@pytest.mark.asyncio
async def test_invalid_email(client: AsyncClient):
    """3. Invalid email - rejects malformed email with 422."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Bad Email",
            "email": "not-an-email",
            "password": "Password123!",
            "role": "customer",
        },
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_weak_password(client: AsyncClient, unique_email: str):
    """4. Weak password - rejects password shorter than 8 characters with 422."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Short Password",
            "email": unique_email,
            "password": "short",
            "role": "customer",
        },
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, unique_email: str):
    """5. Login success - validates credentials and returns tokens + user."""
    # Register
    await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Login User",
            "email": unique_email,
            "password": "SecurePassword123!",
            "role": "seller",
        },
    )

    # Login
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": unique_email,
            "password": "SecurePassword123!",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0
    assert data["user"]["email"] == unique_email.lower()
    assert data["user"]["role"] == "seller"


@pytest.mark.asyncio
async def test_wrong_password(client: AsyncClient, unique_email: str):
    """6. Wrong password - returns 401 Unauthorized."""
    await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Test User",
            "email": unique_email,
            "password": "CorrectPassword123!",
        },
    )

    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": unique_email,
            "password": "WrongPassword999!",
        },
    )
    assert response.status_code == 401
    assert "invalid" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_unknown_email(client: AsyncClient):
    """7. Unknown email - returns 401 Unauthorized."""
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "nonexistent_email_12345@example.com",
            "password": "SomePassword123!",
        },
    )
    assert response.status_code == 401
    assert "invalid" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_me_without_token(client: AsyncClient):
    """8. /me without token - returns 401."""
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_with_valid_token(client: AsyncClient, unique_email: str):
    """9. /me with valid token - returns user profile."""
    # Register
    await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Profile User",
            "email": unique_email,
            "password": "Password123!",
            "role": "customer",
        },
    )
    # Login
    login_res = await client.post(
        "/api/v1/auth/login",
        json={"email": unique_email, "password": "Password123!"},
    )
    access_token = login_res.json()["access_token"]

    # Call /me
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == unique_email.lower()
    assert data["full_name"] == "Profile User"


@pytest.mark.asyncio
async def test_invalid_token(client: AsyncClient):
    """10. Invalid token - returns 401."""
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid.jwt.token"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_expired_or_invalid_refresh_token(client: AsyncClient):
    """11. Expired or invalid refresh token - returns 401."""
    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "invalid_refresh_token_string"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_success(client: AsyncClient, unique_email: str):
    """12. Refresh success - valid refresh token issues new access token."""
    await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Refresh User",
            "email": unique_email,
            "password": "Password123!",
        },
    )
    login_res = await client.post(
        "/api/v1/auth/login",
        json={"email": unique_email, "password": "Password123!"},
    )
    refresh_token = login_res.json()["refresh_token"]

    refresh_res = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_res.status_code == 200
    data = refresh_res.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0


@pytest.mark.asyncio
async def test_registration_cannot_create_admin(client: AsyncClient, unique_email: str):
    """13. Customer/Seller registration cannot create admin - rejected with 422."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Malicious Admin",
            "email": unique_email,
            "password": "Password123!",
            "role": "admin",
        },
    )
    # Pydantic schema only permits Literal['customer', 'seller']
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_logout_behavior(client: AsyncClient):
    """14. Logout behavior - returns 200 message."""
    response = await client.post("/api/v1/auth/logout")
    assert response.status_code == 200
    assert "logged out" in response.json()["message"].lower()

