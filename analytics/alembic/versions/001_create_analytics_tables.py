"""create analytics tables

Revision ID: d5f5aedb6ec5
Revises:
Create Date: 2026-03-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

# revision identifiers, used by Alembic.
revision: str = "d5f5aedb6ec5"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE SCHEMA IF NOT EXISTS analytics")

    op.create_table(
        "visitors",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("fingerprint", sa.String(64), nullable=False),
        sa.Column("country", sa.String(2), nullable=True),
        sa.Column("city", sa.String(128), nullable=True),
        sa.Column("referrer", sa.Text, nullable=True),
        sa.Column(
            "first_seen",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "last_seen",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        schema="analytics",
    )

    op.create_index(
        "ix_visitors_fingerprint",
        "visitors",
        ["fingerprint"],
        schema="analytics",
    )

    op.create_table(
        "events",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column(
            "timestamp",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "visitor_id",
            UUID(as_uuid=True),
            sa.ForeignKey("analytics.visitors.id"),
            nullable=False,
        ),
        sa.Column("site", sa.String(128), nullable=False),
        sa.Column("page", sa.Text, nullable=False),
        sa.Column("event_name", sa.String(64), nullable=False),
        sa.Column("properties", JSONB, server_default=sa.text("'{}'::jsonb")),
        schema="analytics",
    )

    op.create_index(
        "ix_events_event_name",
        "events",
        ["event_name"],
        schema="analytics",
    )

    op.create_index(
        "ix_events_site_timestamp",
        "events",
        ["site", "timestamp"],
        schema="analytics",
    )


def downgrade() -> None:
    op.drop_table("events", schema="analytics")
    op.drop_table("visitors", schema="analytics")
    op.execute("DROP SCHEMA IF EXISTS analytics CASCADE")
