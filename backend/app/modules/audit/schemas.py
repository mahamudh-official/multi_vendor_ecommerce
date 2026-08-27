"""
Pydantic schemas for audit logs.
"""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict


class AuditLogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    admin_user_id: Optional[uuid.UUID] = None
    action: str
    entity_type: str
    entity_id: str
    metadata_json: Dict[str, Any] = {}
    created_at: datetime


class AuditLogListResponse(BaseModel):
    items: List[AuditLogRead]
    total: int
    page: int
    page_size: int

