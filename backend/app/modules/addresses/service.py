"""
Business logic service for Customer Address Management.
"""
from __future__ import annotations

import uuid
from typing import List

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.addresses.models import Address
from app.modules.addresses.repository import AddressRepository
from app.modules.addresses.schemas import (
    AddressCreate,
    AddressListResponse,
    AddressRead,
    AddressUpdate,
)
from app.modules.auth.models import User


class AddressService:
    """Service handling delivery address CRUD, ownership protection, and default toggling."""

    def __init__(
        self,
        address_repo: AddressRepository,
        session: AsyncSession,
    ) -> None:
        self.address_repo = address_repo
        self.session = session

    async def list_addresses(self, user: User) -> AddressListResponse:
        """List all addresses belonging to the authenticated user."""
        addresses = await self.address_repo.list_by_user(user.id)
        return AddressListResponse(
            items=[AddressRead.model_validate(a) for a in addresses],
            total=len(addresses),
        )

    async def get_address(self, user: User, address_id: uuid.UUID) -> AddressRead:
        """Get single address enforcing ownership."""
        address = await self.address_repo.get_by_id_and_user(address_id, user.id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found.",
            )
        return AddressRead.model_validate(address)

    async def create_address(self, user: User, data: AddressCreate) -> AddressRead:
        """Create a new delivery address with single-default rule enforcement."""
        count = await self.address_repo.count_by_user(user.id)
        # First address automatically becomes default, or if requested default
        should_be_default = data.is_default or count == 0

        if should_be_default:
            await self.address_repo.unset_default_for_user(user.id)

        address = Address(
            id=uuid.uuid4(),
            user_id=user.id,
            full_name=data.full_name,
            phone=data.phone,
            address_line_1=data.address_line_1,
            address_line_2=data.address_line_2,
            city=data.city,
            state=data.state,
            postal_code=data.postal_code,
            country=data.country,
            is_default=should_be_default,
        )

        created = await self.address_repo.create(address)
        await self.session.commit()
        await self.session.refresh(created)
        return AddressRead.model_validate(created)

    async def update_address(
        self, user: User, address_id: uuid.UUID, data: AddressUpdate
    ) -> AddressRead:
        """Update address fields enforcing ownership."""
        address = await self.address_repo.get_by_id_and_user(address_id, user.id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found.",
            )

        update_dict = data.model_dump(exclude_unset=True)

        if update_dict.get("is_default") is True:
            await self.address_repo.unset_default_for_user(user.id, exclude_address_id=address.id)

        updated = await self.address_repo.update_fields(address, update_dict)
        await self.session.commit()
        await self.session.refresh(updated)
        return AddressRead.model_validate(updated)

    async def set_default_address(
        self, user: User, address_id: uuid.UUID
    ) -> AddressRead:
        """Set specified address as default and clear default on all others."""
        address = await self.address_repo.get_by_id_and_user(address_id, user.id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found.",
            )

        await self.address_repo.unset_default_for_user(user.id, exclude_address_id=address.id)
        address.is_default = True
        await self.session.commit()
        await self.session.refresh(address)
        return AddressRead.model_validate(address)

    async def delete_address(self, user: User, address_id: uuid.UUID) -> None:
        """Delete an address and promote the next address to default if needed."""
        address = await self.address_repo.get_by_id_and_user(address_id, user.id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found.",
            )

        was_default = address.is_default
        await self.address_repo.delete(address)

        if was_default:
            remaining = await self.address_repo.list_by_user(user.id)
            if remaining:
                remaining[0].is_default = True

        await self.session.commit()

