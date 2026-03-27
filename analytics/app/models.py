import uuid
from typing import Optional

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Visitor(Base):
    __tablename__ = "visitors"
    __table_args__ = {"schema": "analytics"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    fingerprint: Mapped[str] = mapped_column(String(64), index=True)
    country: Mapped[Optional[str]] = mapped_column(String(2), nullable=True)
    city: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    referrer: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    first_seen: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    last_seen: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class Event(Base):
    __tablename__ = "events"
    __table_args__ = (
        Index("ix_events_event_name", "event_name"),
        Index("ix_events_site_timestamp", "site", "timestamp"),
        {"schema": "analytics"},
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    timestamp: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    visitor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("analytics.visitors.id")
    )
    site: Mapped[str] = mapped_column(String(128), nullable=False)
    page: Mapped[str] = mapped_column(Text, nullable=False)
    event_name: Mapped[str] = mapped_column(String(64), nullable=False)
    properties: Mapped[dict] = mapped_column(JSONB, default=dict, server_default="{}")
