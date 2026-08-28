"""
Dependencies for Audit module.
"""
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.audit.repository import AuditLogRepository
from app.modules.audit.service import AuditService


def get_audit_service(session: AsyncSession = Depends(get_db)) -> AuditService:
    repository = AuditLogRepository(session)
    return AuditService(repository)

