"""
Data access repository for User accounts.
"""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import User, UserRole


class AuthRepository:
    """Async database operations for User model."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_email(self, email: str) -> User | None:
        """Find a user by normalized email address."""
        stmt = select(User).where(User.email == email.strip().lower())
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        """Find a user by UUID primary key."""
        stmt = select(User).where(User.id == user_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def create(
        self,
        full_name: str,
        email: str,
        password_hash: str,
        role: UserRole = UserRole.customer,
    ) -> User:
        """Create and persist a new User."""
        user = User(
            full_name=full_name.strip(),
            email=email.strip().lower(),
            password_hash=password_hash,
            role=role,
            is_active=True,
        )
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user

    async def update(self, user: User, update_data: dict) -> User:
        """Update and commit user profile fields."""
        for key, value in update_data.items():
            if hasattr(user, key):
                setattr(user, key, value)
        await self.session.commit()
        await self.session.refresh(user)
        return user
