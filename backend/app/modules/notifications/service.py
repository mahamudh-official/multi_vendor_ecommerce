import uuid
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status

from app.modules.auth.models import User
from app.modules.notifications.models import Notification, NotificationType
from app.modules.notifications.repository import NotificationRepository
from app.modules.notifications.schemas import (
    NotificationListResponse,
    NotificationReadAllResponse,
    NotificationRead,
    UnreadCountResponse,
)


class NotificationService:
    def __init__(self, repository: NotificationRepository) -> None:
        self.repository = repository

    async def list_notifications(
        self,
        user: User,
        unread_only: bool = False,
        page: int = 1,
        page_size: int = 20,
    ) -> NotificationListResponse:
        items, total = await self.repository.list_by_user(
            user_id=user.id,
            unread_only=unread_only,
            page=page,
            page_size=page_size,
        )
        unread_count = await self.repository.count_unread(user_id=user.id)
        return NotificationListResponse(
            items=[NotificationRead.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            unread_count=unread_count,
        )

    async def get_unread_count(self, user: User) -> UnreadCountResponse:
        count = await self.repository.count_unread(user_id=user.id)
        return UnreadCountResponse(unread_count=count)

    async def mark_as_read(
        self,
        user: User,
        notification_id: uuid.UUID,
    ) -> NotificationRead:
        notification = await self.repository.mark_as_read(
            notification_id=notification_id,
            user_id=user.id,
        )
        if not notification:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found.",
            )
        await self.repository.session.commit()
        await self.repository.session.refresh(notification)
        return NotificationRead.model_validate(notification)

    async def mark_all_as_read(self, user: User) -> NotificationReadAllResponse:
        count = await self.repository.mark_all_as_read(user_id=user.id)
        await self.repository.session.commit()
        return NotificationReadAllResponse(
            marked_read_count=count,
            message=f"{count} notification(s) marked as read.",
        )

    # ── Notification Trigger Helpers ──────────────────────────────────────────

    async def send_notification(
        self,
        user_id: uuid.UUID,
        type: NotificationType,
        title: str,
        message: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> Notification:
        """Internal helper to dispatch an idempotent notification."""
        return await self.repository.create(
            user_id=user_id,
            type=type,
            title=title,
            message=message,
            data=data or {},
        )

