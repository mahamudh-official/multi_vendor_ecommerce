"""
Repository for Customer Address Management.
"""
from __future__ import annotations

import uuid
from typing import List, Optional

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.addresses.models import Address


class AddressRepository:
    """Encapsulates database operations for customer delivery addresses."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_by_user(self, user_id: uuid.UUID) -> List[Address]:
        """Fetch all addresses for a user, sorted default first, then newest."""
        stmt = (
            select(Address)
            .where(Address.user_id == user_id)
            .order_by(Address.is_default.desc(), Address.created_at.desc())
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id_and_user(
        self, address_id: uuid.UUID, user_id: uuid.UUID
    ) -> Optional[Address]:
        """Fetch address strictly verifying ownership."""
        stmt = select(Address).where(
            Address.id == address_id,
            Address.user_id == user_id,
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def count_by_user(self, user_id: uuid.UUID) -> int:
        """Count total addresses saved by a user."""
        stmt = select(func.count(Address.id)).where(Address.user_id == user_id)
        result = await self.session.execute(stmt)
        return result.scalar_one()

    async def unset_default_for_user(
        self, user_id: uuid.UUID, exclude_address_id: Optional[uuid.UUID] = None
    ) -> None:
        """Atomically unset is_default on all user addresses."""
        stmt = update(Address).where(Address.user_id == user_id)
        if exclude_address_id is not None:
            stmt = stmt.where(Address.id != exclude_address_id)
        stmt = stmt.values(is_default=False)
        await self.session.execute(stmt)

    async def create(self, address: Address) -> Address:
        """Insert address entity."""
        self.session.add(address)
        await self.session.flush()
        return address

    async def update_fields(self, address: Address, update_data: dict) -> Address:
        """Update address fields."""
        for key, value in update_data.items():
            if hasattr(address, key) and value is not None:
                setattr(address, key, value)
        await self.session.flush()
        return address

    async def delete(self, address: Address) -> None:
        """Delete address."""
        await self.session.delete(address)
        await self.session.flush()

