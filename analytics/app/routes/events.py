import datetime
import hashlib
import logging

from fastapi import APIRouter, BackgroundTasks, Depends, Request, Response
from sqlalchemy import select

from app.config import settings
from app.database import async_session_factory
from app.dependencies import verify_token
from app.models import Event, Visitor
from app.rate_limit import limiter
from app.schemas import EventIn

logger = logging.getLogger(__name__)

router = APIRouter()


def make_fingerprint(ip: str, ua: str, salt: str) -> str:
    """Daily-rotating visitor fingerprint. Same visitor gets different hash each day.
    Raw IP is NEVER stored -- only this hash."""
    daily = f"{salt}:{datetime.date.today().isoformat()}:{ip}:{ua}"
    return hashlib.sha256(daily.encode()).hexdigest()


async def _write_event(event: EventIn, ip: str, ua: str) -> None:
    """Background task: upsert visitor and insert event.

    CRITICAL: Creates its OWN async session because the request session
    is closed after the 202 response returns.
    """
    if async_session_factory is None:
        logger.error("Cannot write event -- database not configured")
        return

    try:
        async with async_session_factory() as db:
            fingerprint = make_fingerprint(ip, ua, settings.FINGERPRINT_SALT)

            # Upsert visitor
            result = await db.execute(
                select(Visitor).where(Visitor.fingerprint == fingerprint)
            )
            visitor = result.scalar_one_or_none()

            if visitor is not None:
                visitor.last_seen = datetime.datetime.now(datetime.timezone.utc)
                if event.referrer and not visitor.referrer:
                    visitor.referrer = event.referrer
            else:
                visitor = Visitor(
                    fingerprint=fingerprint,
                    referrer=event.referrer,
                )
                db.add(visitor)
                await db.flush()  # populate visitor.id

            # Insert event
            db.add(
                Event(
                    visitor_id=visitor.id,
                    site=event.site,
                    page=event.page,
                    event_name=event.event_name,
                    properties=event.properties,
                )
            )

            await db.commit()
    except Exception:
        logger.exception("Failed to write analytics event")


@router.post("/events", status_code=202)
@limiter.limit("100/minute")
async def ingest_event(
    request: Request,
    event: EventIn,
    background_tasks: BackgroundTasks,
    token: str = Depends(verify_token),
) -> Response:
    """Accept an analytics event and write it asynchronously.

    Returns 202 immediately -- the DB write happens in a background task.
    """
    ip = request.headers.get("x-real-ip") or (
        request.client.host if request.client else "unknown"
    )
    ua = request.headers.get("user-agent") or ""

    background_tasks.add_task(_write_event, event, ip, ua)

    return Response(status_code=202)
