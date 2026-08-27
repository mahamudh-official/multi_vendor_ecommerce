"""
FastAPI dependencies for administrator authorization and service injection.
"""
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.admin.repository import AdminRepository
from app.modules.admin.service import AdminService
from app.modules.audit.repository import AuditLogRepository
from app.modules.audit.service import AuditService
from app.modules.auth.dependencies import require_role
from app.modules.auth.models import User, UserRole
from app.modules.notifications.repository import NotificationRepository
from app.modules.notifications.service import NotificationService

# Reusable Admin-only role dependency
require_admin = require_role(UserRole.admin)


def get_audit_service(session: AsyncSession = Depends(get_db)) -> AuditService:
    repository = AuditLogRepository(session)
    return AuditService(repository)


def get_admin_service(
    session: AsyncSession = Depends(get_db),
    audit_service: AuditService = Depends(get_audit_service),
) -> AdminService:
    repository = AdminRepository(session)
    notification_repo = NotificationRepository(session)
    notification_service = NotificationService(notification_repo)
    return AdminService(
        repository=repository,
        audit_service=audit_service,
        notification_service=notification_service,
        session=session,
    )

