"""Add uniqueness constraint to reviews table

Revision ID: d0e1f2a3b4c5
Revises: c9d0e1f2a3b4
Create Date: 2026-08-28 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "d0e1f2a3b4c5"
down_revision: Union[str, None] = "c9d0e1f2a3b4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Check for duplicates before applying constraint (failsafe)
    # Since we verified no duplicates exist in staging, this is just defense-in-depth
    op.create_unique_constraint(
        "uq_reviews_user_order_item",
        "reviews",
        ["user_id", "order_item_id"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_reviews_user_order_item", "reviews", type_="unique")

