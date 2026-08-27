import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.modules.auth.dependencies import get_current_active_user
from app.modules.auth.models import User
from app.modules.notifications.dependencies import get_notification_service
from app.modules.notifications.schemas import (
    NotificationListResponse,
    NotificationReadAllResponse,
    NotificationRead,
    UnreadCountResponse,
)
from app.modules.notifications.service import NotificationService

notifications_router = APIRouter(prefix="/notifications", tags=["Notifications"])


@notifications_router.get(
    "",
    response_model=NotificationListResponse,
    status_code=status.HTTP_200_OK,
    summary="List current user's notifications",
)
async def list_notifications(
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[NotificationService, Depends(get_notification_service)],
    unread_only: bool = Query(False, description="Filter for unread notifications only"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
) -> NotificationListResponse:
    return await service.list_notifications(
        user=current_user,
        unread_only=unread_only,
        page=page,
        page_size=page_size,
    )


@notifications_router.get(
    "/unread-count",
    response_model=UnreadCountResponse,
    status_code=status.HTTP_200_OK,
    summary="Get unread notifications count for badge",
)
async def get_unread_count(
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[NotificationService, Depends(get_notification_service)],
) -> UnreadCountResponse:
    return await service.get_unread_count(user=current_user)


@notifications_router.post(
    "/{notification_id}/read",
    response_model=NotificationRead,
    status_code=status.HTTP_200_OK,
    summary="Mark a specific notification as read",
)
async def mark_notification_as_read(
    notification_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[NotificationService, Depends(get_notification_service)],
) -> NotificationRead:
    return await service.mark_as_read(
        user=current_user,
        notification_id=notification_id,
    )


@notifications_router.post(
    "/read-all",
    response_model=NotificationReadAllResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark all notifications as read",
)
async def mark_all_notifications_as_read(
    current_user: Annotated[User, Depends(get_current_active_user)],
    service: Annotated[NotificationService, Depends(get_notification_service)],
) -> NotificationReadAllResponse:
    return await service.mark_all_as_read(user=current_user)

