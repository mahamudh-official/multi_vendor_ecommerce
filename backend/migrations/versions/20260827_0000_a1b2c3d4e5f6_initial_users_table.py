"""Initial migration: create users table.

Revision ID: a1b2c3d4e5f6
Revises:
Create Date: 2026-08-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# PostgreSQL native ENUM for user roles
user_role_enum = postgresql.ENUM('customer', 'seller', 'admin', name='userrole')


def upgrade() -> None:
    """Create userrole enum type and users table."""
    # 1. Explicitly create the enum type if not exists
    user_role_enum.create(op.get_bind(), checkfirst=True)

    # 2. Create users table referencing the existing enum type with create_type=False
    op.create_table(
        'users',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            nullable=False,
            server_default=sa.text('gen_random_uuid()'),
        ),
        sa.Column('full_name', sa.String(length=255), nullable=False),
        sa.Column('email', sa.String(length=320), nullable=False),
        sa.Column('password_hash', sa.String(length=1024), nullable=False),
        sa.Column(
            'role',
            postgresql.ENUM('customer', 'seller', 'admin', name='userrole', create_type=False),
            nullable=False,
            server_default='customer',
        ),
        sa.Column(
            'is_active',
            sa.Boolean(),
            nullable=False,
            server_default=sa.text('true'),
        ),
        sa.Column(
            'created_at',
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text('now()'),
        ),
        sa.Column(
            'updated_at',
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text('now()'),
        ),
        sa.PrimaryKeyConstraint('id'),
    )

    # Indexes for common queries
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)


def downgrade() -> None:
    """Drop users table and userrole enum type."""
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_table('users')
    user_role_enum.drop(op.get_bind(), checkfirst=True)
