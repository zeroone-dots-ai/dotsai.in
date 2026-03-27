---
phase: 04-calcom-webhook
plan: 01
subsystem: api
tags: [fastapi, calcom, webhook, hmac, postgresql, alembic, asyncpg]

# Dependency graph
requires:
  - phase: 02-fastapi-analytics-api
    provides: FastAPI analytics service with models, config, database, events endpoint
provides:
  - analytics.bookings table with 10 columns
  - POST /webhooks/calcom endpoint with HMAC-SHA256 verification
  - Booking SQLAlchemy model
  - Alembic migration 002
  - CAL_WEBHOOK_SECRET generated and deployed
affects: [04-02-calcom-webhook-config]

# Tech tracking
tech-stack:
  added: []
  patterns: [hmac-sha256-webhook-verification, iso-datetime-parsing-for-asyncpg, background-task-upsert]

key-files:
  created:
    - analytics/app/routes/webhooks.py
    - analytics/alembic/versions/002_create_bookings_table.py
  modified:
    - analytics/app/models.py
    - analytics/app/config.py
    - analytics/app/main.py

key-decisions:
  - "ISO datetime strings parsed to datetime objects before DB insert -- asyncpg requires native datetime, not strings"
  - "Bot filter middleware NOT applied to /webhooks/ paths -- already scoped to POST /events only"
  - "HMAC verification uses raw body bytes, not parsed JSON -- ensures signature matches exact transmitted payload"

patterns-established:
  - "Webhook HMAC pattern: read raw bytes, verify signature, then parse JSON"
  - "Background task upsert: SELECT existing, then INSERT or UPDATE based on trigger event"
  - "Field extraction with fallback paths: _extract_field() tries multiple JSON paths for Cal.com payload variations"

# Metrics
duration: 8min
completed: 2026-03-28
---

# Phase 4 Plan 1: Cal.com Webhook Endpoint Summary

**HMAC-SHA256 verified POST /webhooks/calcom endpoint with Booking model, Alembic migration, and idempotent create/cancel/reschedule handling**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-27T21:02:59Z
- **Completed:** 2026-03-27T21:11:29Z
- **Tasks:** 1
- **Files modified:** 20

## Accomplishments
- Booking SQLAlchemy model with 10 columns (id, cal_booking_id, event_type, attendee_name, attendee_email, start_time, end_time, status, raw_payload, created_at) in analytics.bookings
- POST /webhooks/calcom endpoint with HMAC-SHA256 signature verification via X-Cal-Signature-256 header
- Idempotent handling of BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED events
- Alembic migration 002 with unique index on cal_booking_id, indexes on status and created_at
- CAL_WEBHOOK_SECRET generated and stored in /opt/services/.env.analytics on VPS
- Deployed to VPS, migration ran automatically on container startup

## Task Commits

Each task was committed atomically:

1. **Task 1: Booking model + Alembic migration + webhook endpoint** - `3d8a686` (feat)

## Files Created/Modified
- `analytics/app/routes/webhooks.py` - Cal.com webhook endpoint with HMAC verification and booking processing
- `analytics/app/models.py` - Added Booking SQLAlchemy model
- `analytics/app/config.py` - Added CAL_WEBHOOK_SECRET setting
- `analytics/app/main.py` - Wired webhooks router
- `analytics/alembic/versions/002_create_bookings_table.py` - Migration creating analytics.bookings table

## Decisions Made
- ISO datetime strings parsed to datetime objects before DB insert -- asyncpg requires native datetime, not strings
- Bot filter middleware already scoped to POST /events only -- no changes needed for /webhooks/ paths
- HMAC verification uses raw body bytes, not parsed JSON, ensuring signature matches exact transmitted payload
- Field extraction uses multiple fallback paths (_extract_field) to handle Cal.com payload structure variations

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed asyncpg datetime string rejection**
- **Found during:** Task 1 (webhook endpoint verification)
- **Issue:** asyncpg requires datetime.datetime objects, not ISO string like "2026-03-29T10:00:00Z". Background task failed with DataError on INSERT.
- **Fix:** Added _parse_datetime() helper that converts ISO strings (with Z or +00:00 suffix) to timezone-aware datetime objects before passing to SQLAlchemy.
- **Files modified:** analytics/app/routes/webhooks.py
- **Verification:** Valid HMAC POST returned 200 and row appeared in analytics.bookings with correct datetime values
- **Committed in:** 3d8a686 (included in task commit after fix)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential fix for correctness -- asyncpg strict typing requirement not anticipated in plan. No scope creep.

## Issues Encountered
None beyond the auto-fixed datetime bug above.

## User Setup Required
None - CAL_WEBHOOK_SECRET was auto-generated and deployed. Cal.com webhook URL configuration is covered in Plan 04-02.

## Next Phase Readiness
- Webhook endpoint live at api.dotsai.in/webhooks/calcom, ready for Cal.com configuration
- CAL_WEBHOOK_SECRET available in /opt/services/.env.analytics for Plan 04-02
- analytics.bookings table created and verified with all 10 columns

---
*Phase: 04-calcom-webhook*
*Completed: 2026-03-28*
