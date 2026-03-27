"""create bookings table

Revision ID: a1b2c3d4e5f6
Revises: d5f5aedb6ec5
Create Date: 2026-03-28

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB

# revision identifiers, used by Alembic.
revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = "d5f5aedb6ec5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "bookings",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("cal_booking_id", sa.Integer, nullable=False),
        sa.Column("event_type", sa.String(255), nullable=True),
        sa.Column("attendee_name", sa.String(255), nullable=True),
        sa.Column("attendee_email", sa.String(255), nullable=True),
        sa.Column("start_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("end_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="created"),
        sa.Column("raw_payload", JSONB, nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        schema="analytics",
    )

    op.create_index(
        "ix_bookings_cal_booking_id",
        "bookings",
        ["cal_booking_id"],
        unique=True,
        schema="analytics",
    )

    op.create_index(
        "ix_bookings_status",
        "bookings",
        ["status"],
        schema="analytics",
    )

    op.create_index(
        "ix_bookings_created_at",
        "bookings",
        ["created_at"],
        schema="analytics",
    )


def downgrade() -> None:
    op.drop_table("bookings", schema="analytics")
