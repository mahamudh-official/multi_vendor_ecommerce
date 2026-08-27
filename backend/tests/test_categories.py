"""
Backend test suite for Category API endpoints.
Covers list, details, admin creation, role restrictions, updates, and deactivation.
"""
import uuid
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.modules.auth.models import User, UserRole
from tests.conftest import TestingSessionLocal


async def create_test_user(role: UserRole = UserRole.customer) -> tuple[User, str]:
    """Create a user with specified role directly in DB and return (User, access_token)."""
    async with TestingSessionLocal() as session:
        user = User(
            full_name=f"Test {role.value.capitalize()}",
            email=f"{role.value}_{uuid.uuid4().hex[:8]}@example.com",
            password_hash="argon2_hashed_placeholder",
            role=role,
            is_active=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

    token, _ = create_access_token(subject=user.id, role=user.role.value)
    return user, token


@pytest.mark.asyncio
async def test_admin_create_category(client: AsyncClient):
    """3. Admin can create a category."""
    _, admin_token = await create_test_user(UserRole.admin)

    res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "name": f"Electronics {uuid.uuid4().hex[:4]}",
            "description": "Gadgets and tech",
            "image_url": "https://example.com/electronics.png",
        },
    )
    assert res.status_code == 201
    data = res.json()
    assert "id" in data
    assert "slug" in data
    assert data["name"].startswith("Electronics")


@pytest.mark.asyncio
async def test_non_admin_cannot_create_category(client: AsyncClient):
    """4. Customer or Seller cannot create a category (403 Forbidden)."""
    _, customer_token = await create_test_user(UserRole.customer)
    _, seller_token = await create_test_user(UserRole.seller)

    # Customer attempt
    res1 = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {customer_token}"},
        json={"name": "Hacked Category"},
    )
    assert res1.status_code == 403

    # Seller attempt
    res2 = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {seller_token}"},
        json={"name": "Seller Category"},
    )
    assert res2.status_code == 403


@pytest.mark.asyncio
async def test_list_categories(client: AsyncClient):
    """1. Public list of active categories."""
    _, admin_token = await create_test_user(UserRole.admin)
    cat_name = f"Home & Garden {uuid.uuid4().hex[:4]}"
    await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": cat_name},
    )

    res = await client.get("/api/v1/categories")
    assert res.status_code == 200
    data = res.json()
    assert isinstance(data, list)
    assert any(c["name"] == cat_name for c in data)


@pytest.mark.asyncio
async def test_category_details(client: AsyncClient):
    """2. Public fetch category details by UUID."""
    _, admin_token = await create_test_user(UserRole.admin)
    create_res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Fashion {uuid.uuid4().hex[:4]}", "description": "Apparel"},
    )
    cat_id = create_res.json()["id"]

    res = await client.get(f"/api/v1/categories/{cat_id}")
    assert res.status_code == 200
    data = res.json()
    assert data["id"] == cat_id
    assert "description" in data


@pytest.mark.asyncio
async def test_admin_update_category(client: AsyncClient):
    """5. Admin can update category."""
    _, admin_token = await create_test_user(UserRole.admin)
    create_res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Books {uuid.uuid4().hex[:4]}"},
    )
    cat_id = create_res.json()["id"]

    update_res = await client.patch(
        f"/api/v1/categories/{cat_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"description": "Updated book collection description"},
    )
    assert update_res.status_code == 200
    assert update_res.json()["description"] == "Updated book collection description"


@pytest.mark.asyncio
async def test_admin_delete_category(client: AsyncClient):
    """6. Admin can deactivate category."""
    _, admin_token = await create_test_user(UserRole.admin)
    create_res = await client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": f"Toys {uuid.uuid4().hex[:4]}"},
    )
    cat_id = create_res.json()["id"]

    del_res = await client.delete(
        f"/api/v1/categories/{cat_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert del_res.status_code == 200

    # Deactivated category should no longer appear in public list
    list_res = await client.get("/api/v1/categories")
    assert not any(c["id"] == cat_id for c in list_res.json())

