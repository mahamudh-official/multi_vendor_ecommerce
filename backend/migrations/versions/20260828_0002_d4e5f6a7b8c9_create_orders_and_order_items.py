"""Create orders and order_items tables with enums and snapshots.

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-08-28 00:35:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'd4e5f6a7b8c9'
down_revision: Union[str, None] = 'c3d4e5f6a7b8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Safe creation of PostgreSQL ENUM types ──────────────────────────────
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'orderstatus') THEN
                CREATE TYPE orderstatus AS ENUM (
                    'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
                );
            END IF;
        END
        $$;
        """
    )

    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'paymentstatus') THEN
                CREATE TYPE paymentstatus AS ENUM (
                    'pending', 'paid', 'failed', 'refunded'
                );
            END IF;
        END
        $$;
        """
    )

    order_status_enum = postgresql.ENUM(
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
        name='orderstatus',
        create_type=False,
    )

    payment_status_enum = postgresql.ENUM(
        'pending',
        'paid',
        'failed',
        'refunded',
        name='paymentstatus',
        create_type=False,
    )

    # ── Orders Table ────────────────────────────────────────────────────────
    op.create_table(
        'orders',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            nullable=False,
            server_default=sa.text('gen_random_uuid()'),
        ),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('order_number', sa.String(length=64), nullable=False),
        sa.Column('status', order_status_enum, nullable=False, server_default='pending'),
        sa.Column('payment_status', payment_status_enum, nullable=False, server_default='pending'),
        sa.Column('subtotal', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('shipping_fee', sa.Numeric(precision=10, scale=2), nullable=False, server_default='0.00'),
        sa.Column('discount_amount', sa.Numeric(precision=10, scale=2), nullable=False, server_default='0.00'),
        sa.Column('tax_amount', sa.Numeric(precision=10, scale=2), nullable=False, server_default='0.00'),
        sa.Column('total_amount', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('currency', sa.String(length=3), nullable=False, server_default='USD'),
        sa.Column('shipping_full_name', sa.String(length=255), nullable=False),
        sa.Column('shipping_phone', sa.String(length=32), nullable=False),
        sa.Column('shipping_address_line1', sa.String(length=255), nullable=False),
        sa.Column('shipping_address_line2', sa.String(length=255), nullable=True),
        sa.Column('shipping_city', sa.String(length=100), nullable=False),
        sa.Column('shipping_state', sa.String(length=100), nullable=False),
        sa.Column('shipping_postal_code', sa.String(length=32), nullable=False),
        sa.Column('shipping_country', sa.String(length=100), nullable=False),
        sa.Column('customer_note', sa.Text(), nullable=True),
        sa.Column('idempotency_key', sa.String(length=128), nullable=True),
        sa.Column(
            'created_at',
            sa.DateTime(timezone=True),
            server_default=sa.text('now()'),
            nullable=False,
        ),
        sa.Column(
            'updated_at',
            sa.DateTime(timezone=True),
            server_default=sa.text('now()'),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_orders_id'), 'orders', ['id'], unique=False)
    op.create_index(op.f('ix_orders_user_id'), 'orders', ['user_id'], unique=False)
    op.create_index(op.f('ix_orders_order_number'), 'orders', ['order_number'], unique=True)
    op.create_index(op.f('ix_orders_status'), 'orders', ['status'], unique=False)
    op.create_index(op.f('ix_orders_payment_status'), 'orders', ['payment_status'], unique=False)
    op.create_index(op.f('ix_orders_idempotency_key'), 'orders', ['idempotency_key'], unique=True)
    op.create_index(op.f('ix_orders_created_at'), 'orders', ['created_at'], unique=False)

    # ── Order Items Table ───────────────────────────────────────────────────
    op.create_table(
        'order_items',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            nullable=False,
            server_default=sa.text('gen_random_uuid()'),
        ),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('seller_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_name', sa.String(length=255), nullable=False),
        sa.Column('product_sku', sa.String(length=100), nullable=True),
        sa.Column('product_image_url', sa.String(length=1024), nullable=True),
        sa.Column('unit_price', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('line_total', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column(
            'created_at',
            sa.DateTime(timezone=True),
            server_default=sa.text('now()'),
            nullable=False,
        ),
        sa.CheckConstraint('quantity > 0', name='ck_order_item_quantity_positive'),
        sa.CheckConstraint('unit_price > 0', name='ck_order_item_unit_price_positive'),
        sa.CheckConstraint('line_total >= 0', name='ck_order_item_line_total_non_negative'),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['seller_id'], ['users.id'], ondelete='RESTRICT'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_order_items_id'), 'order_items', ['id'], unique=False)
    op.create_index(op.f('ix_order_items_order_id'), 'order_items', ['order_id'], unique=False)
    op.create_index(op.f('ix_order_items_product_id'), 'order_items', ['product_id'], unique=False)
    op.create_index(op.f('ix_order_items_seller_id'), 'order_items', ['seller_id'], unique=False)
    op.create_index('ix_order_items_order_seller', 'order_items', ['order_id', 'seller_id'], unique=False)


def downgrade() -> None:
    op.drop_table('order_items')
    op.drop_table('orders')
    op.execute("DROP TYPE IF EXISTS paymentstatus;")
    op.execute("DROP TYPE IF EXISTS orderstatus;")
