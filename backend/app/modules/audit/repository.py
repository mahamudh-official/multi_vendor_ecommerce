"""
Repository for audit logs.
"""
import uuid
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.audit.models import AuditLog


class AuditLogRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        admin_user_id: Optional[uuid.UUID],
        action: str,
        entity_type: str,
        entity_id: str,
        metadata_json: Optional[Dict[str, Any]] = None,
    ) -> AuditLog:
        """Create an immutable audit log record."""
        audit_log = AuditLog(
            id=uuid.uuid4(),
            admin_user_id=admin_user_id,
            action=action,
            entity_type=entity_type,
            entity_id=str(entity_id),
            metadata_json=metadata_json or {},
        )
        self.session.add(audit_log)
        await self.session.flush()
        return audit_log

    async def list_logs(
        self,
        admin_user_id: Optional[uuid.UUID] = None,
        action: Optional[str] = None,
        entity_type: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[AuditLog], int]:
        """List audit logs with optional filters, sorted newest first."""
        stmt = select(AuditLog)

        if admin_user_id:
            stmt = stmt.where(AuditLog.admin_user_id == admin_user_id)
        if action:
            stmt = stmt.where(AuditLog.action == action)
        if entity_type:
            stmt = stmt.where(AuditLog.entity_type == entity_type)

        # Count total matching
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_res = await self.session.execute(count_stmt)
        total = total_res.scalar_one()

        # Paginate
        stmt = stmt.order_by(AuditLog.created_at.desc())
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.session.execute(stmt)
        return list(res.scalars().all()), total

