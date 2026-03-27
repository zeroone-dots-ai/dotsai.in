import hashlib
import hmac
import logging
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from fastapi import APIRouter, BackgroundTasks, HTTPException, Request

from app.config import settings
from app.database import async_session_factory
from app.models import Booking

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


def _verify_hmac(body: bytes, signature: str, secret: str) -> bool:
    """Verify Cal.com HMAC-SHA256 signature."""
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    # Strip optional "sha256=" prefix
    if signature.startswith("sha256="):
        signature = signature[7:]
    return hmac.compare_digest(expected, signature)


def _extract_field(payload: Dict[str, Any], *paths: str, default: Any = None) -> Any:
    """Try multiple dotted paths to extract a value from a nested dict."""
    for path in paths:
        obj = payload
        try:
            for key in path.split("."):
                obj = obj[key]
            return obj
        except (KeyError, TypeError, IndexError):
            continue
    return default


def _parse_datetime(value: Any) -> Optional[datetime]:
    """Parse an ISO datetime string to a timezone-aware datetime object."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    try:
        dt = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except (ValueError, TypeError):
        return None


async def _process_booking(body: Dict[str, Any]) -> None:
    """Background task: insert or update booking row."""
    if async_session_factory is None:
        logger.error("Cannot process booking -- database not configured")
        return

    trigger = body.get("triggerEvent", "")
    payload = body.get("payload", {})

    cal_booking_id = _extract_field(payload, "bookingId", "id")
    if cal_booking_id is None:
        logger.warning("No bookingId in webhook payload, skipping")
        return

    cal_booking_id = int(cal_booking_id)

    event_type = _extract_field(
        payload, "eventTitle", "type.slug"
    )
    attendee_name = _extract_field(
        payload, "responses.name.value", "attendeeName"
    )
    attendee_email = _extract_field(
        payload, "responses.email.value", "attendeeEmail"
    )
    start_time = _parse_datetime(_extract_field(payload, "startTime"))
    end_time = _parse_datetime(_extract_field(payload, "endTime"))

    try:
        async with async_session_factory() as db:
            from sqlalchemy import select

            # Look up existing booking
            result = await db.execute(
                select(Booking).where(Booking.cal_booking_id == cal_booking_id)
            )
            existing = result.scalar_one_or_none()

            if trigger == "BOOKING_CREATED":
                if existing is None:
                    booking = Booking(
                        cal_booking_id=cal_booking_id,
                        event_type=event_type,
                        attendee_name=attendee_name,
                        attendee_email=attendee_email,
                        start_time=start_time,
                        end_time=end_time,
                        status="created",
                        raw_payload=body,
                    )
                    db.add(booking)
                else:
                    # Idempotent: update existing row
                    existing.status = "created"
                    existing.raw_payload = body

            elif trigger == "BOOKING_CANCELLED":
                if existing is not None:
                    existing.status = "cancelled"
                    existing.raw_payload = body
                else:
                    # Insert with cancelled status (idempotent)
                    db.add(Booking(
                        cal_booking_id=cal_booking_id,
                        event_type=event_type,
                        attendee_name=attendee_name,
                        attendee_email=attendee_email,
                        start_time=start_time,
                        end_time=end_time,
                        status="cancelled",
                        raw_payload=body,
                    ))

            elif trigger == "BOOKING_RESCHEDULED":
                if existing is not None:
                    existing.status = "rescheduled"
                    existing.start_time = start_time
                    existing.end_time = end_time
                    existing.raw_payload = body
                else:
                    db.add(Booking(
                        cal_booking_id=cal_booking_id,
                        event_type=event_type,
                        attendee_name=attendee_name,
                        attendee_email=attendee_email,
                        start_time=start_time,
                        end_time=end_time,
                        status="rescheduled",
                        raw_payload=body,
                    ))

            else:
                logger.info("Unknown triggerEvent: %s, storing as-is", trigger)
                if existing is None:
                    db.add(Booking(
                        cal_booking_id=cal_booking_id,
                        event_type=event_type,
                        attendee_name=attendee_name,
                        attendee_email=attendee_email,
                        start_time=start_time,
                        end_time=end_time,
                        status=trigger.lower().replace("booking_", ""),
                        raw_payload=body,
                    ))

            await db.commit()
            logger.info("Processed %s for booking %d", trigger, cal_booking_id)

    except Exception:
        logger.exception("Failed to process Cal.com webhook")


@router.post("/calcom")
async def calcom_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
):
    """Receive Cal.com webhook events with HMAC-SHA256 verification."""
    # Read raw body for HMAC verification
    body_bytes = await request.body()

    # Check webhook secret is configured
    if not settings.CAL_WEBHOOK_SECRET:
        raise HTTPException(status_code=500, detail="webhook secret not configured")

    # Get signature header
    signature = request.headers.get("X-Cal-Signature-256", "")
    if not signature:
        raise HTTPException(status_code=403, detail="invalid signature")

    # Verify HMAC
    if not _verify_hmac(body_bytes, signature, settings.CAL_WEBHOOK_SECRET):
        raise HTTPException(status_code=403, detail="invalid signature")

    # Parse JSON
    body = await request.json()

    # Process in background
    background_tasks.add_task(_process_booking, body)

    return {"status": "ok"}
