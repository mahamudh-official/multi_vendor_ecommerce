"""
Audit log service.
"""
import uuid
from typing import Any, Dict, Optional

from app.modules.audit.models import AuditLog
from app.modules.audit.repository import AuditLogRepository
from app.modules.audit.schemas import AuditLogListResponse, AuditLogRead


class AuditService:
    def __init__(self, repository: AuditLogRepository) -> None:
        self.repository = repository

    async def log_action(
        self,
        admin_user_id: Optional[uuid.UUID],
        action: str,
        entity_type: str,
        entity_id: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> AuditLog:
        """Create an immutable audit log."""
        return await self.repository.create(
            admin_user_id=admin_user_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            metadata_json=metadata,
        )

    async def list_audit_logs(
        self,
        admin_user_id: Optional[uuid.UUID] = None,
        action: Optional[str] = None,
        entity_type: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> AuditLogListResponse:
        """Fetch paginated audit logs with filtering."""
        items, total = await self.repository.list_logs(
            admin_user_id=admin_user_id,
            action=action,
            entity_type=entity_type,
            page=page,
            page_size=page_size,
        )
        return AuditLogListResponse(
            items=[AuditLogRead.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
        )

