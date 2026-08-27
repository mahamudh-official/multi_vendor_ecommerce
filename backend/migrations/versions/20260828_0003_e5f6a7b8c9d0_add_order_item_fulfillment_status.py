"""Add fulfillment_status enum and column to order_items table.

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-08-28 01:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'e5f6a7b8c9d0'
down_revision: Union[str, None] = 'd4e5f6a7b8c9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Safe creation of PostgreSQL ENUM type ───────────────────────────────
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fulfillmentstatus') THEN
                CREATE TYPE fulfillmentstatus AS ENUM (
                    'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
                );
            END IF;
        END
        $$;
        """
    )

    fulfillment_status_enum = postgresql.ENUM(
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
        name='fulfillmentstatus',
        create_type=False,
    )

    op.add_column(
        'order_items',
        sa.Column(
            'fulfillment_status',
            fulfillment_status_enum,
            nullable=False,
            server_default='pending',
        ),
    )
    op.create_index(
        op.f('ix_order_items_fulfillment_status'),
        'order_items',
        ['fulfillment_status'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f('ix_order_items_fulfillment_status'), table_name='order_items')
    op.drop_column('order_items', 'fulfillment_status')
    op.execute("DROP TYPE IF EXISTS fulfillmentstatus;")

