"""Create audit_logs and seller_status

Revision ID: a7b8c9d0e1f2
Revises: f6a7b8c9d0e1
Create Date: 2026-08-28 05:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "a7b8c9d0e1f2"
down_revision: Union[str, None] = "f6a7b8c9d0e1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create seller_status_enum if not exists
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'seller_status_enum') THEN
                CREATE TYPE seller_status_enum AS ENUM ('pending', 'approved', 'suspended');
            END IF;
        END $$;
        """
    )

    # 2. Add seller_status column to users table if not present
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'users' AND column_name = 'seller_status'
            ) THEN
                ALTER TABLE users ADD COLUMN seller_status seller_status_enum DEFAULT 'pending'::seller_status_enum;
            END IF;
        END $$;
        """
    )

    # 3. Create audit_logs table if not present
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS audit_logs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            admin_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            action VARCHAR(100) NOT NULL,
            entity_type VARCHAR(100) NOT NULL,
            entity_id VARCHAR(100) NOT NULL,
            metadata_json JSONB NULL,
            ip_address VARCHAR(45) NULL,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
        );
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS ix_audit_logs_id ON audit_logs(id);")
    op.execute("CREATE INDEX IF NOT EXISTS ix_audit_logs_admin_user_id ON audit_logs(admin_user_id);")
    op.execute("CREATE INDEX IF NOT EXISTS ix_audit_logs_action ON audit_logs(action);")
    op.execute("CREATE INDEX IF NOT EXISTS ix_audit_logs_entity_type ON audit_logs(entity_type);")
    op.execute("CREATE INDEX IF NOT EXISTS ix_audit_logs_entity_id ON audit_logs(entity_id);")
    op.execute("CREATE INDEX IF NOT EXISTS ix_audit_logs_created_at ON audit_logs(created_at);")


def downgrade() -> None:
    op.drop_table("audit_logs")
    op.drop_column("users", "seller_status")
    op.execute("DROP TYPE IF EXISTS seller_status_enum;")

