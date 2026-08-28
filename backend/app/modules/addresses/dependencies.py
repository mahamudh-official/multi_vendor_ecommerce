"""
FastAPI dependencies for Addresses module.
"""
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.addresses.repository import AddressRepository
from app.modules.addresses.service import AddressService


def get_address_repository(session: AsyncSession = Depends(get_db)) -> AddressRepository:
    """Dependency providing AddressRepository bound to request DB session."""
    return AddressRepository(session)


def get_address_service(
    address_repo: AddressRepository = Depends(get_address_repository),
    session: AsyncSession = Depends(get_db),
) -> AddressService:
    """Dependency providing AddressService."""
    return AddressService(address_repo=address_repo, session=session)
