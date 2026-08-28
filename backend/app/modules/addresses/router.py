"""
FastAPI router for Customer Delivery Address endpoints.
"""
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.modules.addresses.dependencies import get_address_service
from app.modules.addresses.schemas import (
    AddressCreate,
    AddressListResponse,
    AddressRead,
    AddressUpdate,
)
from app.modules.addresses.service import AddressService
from app.modules.auth.dependencies import get_current_active_user
from app.modules.auth.models import User

router = APIRouter(prefix="/addresses", tags=["Addresses"])


@router.get(
    "",
    response_model=AddressListResponse,
    summary="List all delivery addresses for authenticated customer",
)
async def list_addresses(
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[AddressService, Depends(get_address_service)],
) -> AddressListResponse:
    return await service.list_addresses(user=current_user)


@router.post(
    "",
    response_model=AddressRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new delivery address",
)
async def create_address(
    data: AddressCreate,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[AddressService, Depends(get_address_service)],
) -> AddressRead:
    return await service.create_address(user=current_user, data=data)


@router.get(
    "/{address_id}",
    response_model=AddressRead,
    summary="Get details of a single saved address",
)
async def get_address(
    address_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[AddressService, Depends(get_address_service)],
) -> AddressRead:
    return await service.get_address(user=current_user, address_id=address_id)


@router.patch(
    "/{address_id}",
    response_model=AddressRead,
    summary="Update delivery address details",
)
async def update_address(
    address_id: uuid.UUID,
    data: AddressUpdate,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[AddressService, Depends(get_address_service)],
) -> AddressRead:
    return await service.update_address(
        user=current_user, address_id=address_id, data=data
    )


@router.delete(
    "/{address_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a saved delivery address",
)
async def delete_address(
    address_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[AddressService, Depends(get_address_service)],
) -> None:
    await service.delete_address(user=current_user, address_id=address_id)


@router.patch(
    "/{address_id}/default",
    response_model=AddressRead,
    summary="Set address as default delivery destination",
)
async def set_default_address(
    address_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[AddressService, Depends(get_address_service)],
) -> AddressRead:
    return await service.set_default_address(
        user=current_user, address_id=address_id
    )

