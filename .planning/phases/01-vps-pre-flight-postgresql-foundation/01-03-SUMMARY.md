---
phase: 01-vps-pre-flight-postgresql-foundation
plan: 03
subsystem: database
tags: [postgres, docker, named-volume, docker-compose, migration]

# Dependency graph
requires:
  - phase: 01-vps-pre-flight-postgresql-foundation
    provides: postgres container running with bind mount, calcom + analytics schemas, pg_dump cron backup
provides:
  - Named Docker volume dotsai_pgdata exists and postgres data source confirmed
  - docker-compose.yml updated with named volume declaration (external: true)
  - bind-mount data preserved at /opt/services/postgres-data/ as 7-day rollback
affects:
  - Phase 2 FastAPI Analytics API — postgres volume confirmed, safe to build on
  - Phase 3 Cal.com — postgres volume confirmed, safe to connect cal.com

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Named Docker volumes (not bind mounts) for postgres data persistence"
    - "volume external: true for pre-existing volumes in docker compose"
    - "Alpine container for volume-to-volume data copy (cp -a /source/. /target/)"

key-files:
  created: []
  modified:
    - "/opt/services/docker-compose.yml — postgres volume changed from bind mount to named volume dotsai_pgdata; external: true added"

key-decisions:
  - "Added external: true to dotsai_pgdata volume declaration — volume was created manually before compose ran, suppresses Docker Compose warning and correctly models pre-existing volume lifecycle"
  - "Preserved /opt/services/postgres-data/ bind-mount data — 7-day rollback safety net before deletion"

patterns-established:
  - "Volume-to-volume copy: docker run --rm -v /source:/source:ro -v target:/target alpine sh -c 'cp -a /source/. /target/'"
  - "Pre-existing volumes in compose: declare with external: true to avoid lifecycle warnings"

# Metrics
duration: 3min
completed: 2026-03-27
---

# Phase 1 Plan 3: Named Volume Migration Summary

**Migrated postgres data from bind mount (./postgres-data) to named Docker volume dotsai_pgdata via Alpine copy-then-switch with zero data loss — closes final Phase 1 gap**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-27T09:51:54Z
- **Completed:** 2026-03-27T09:54:57Z
- **Tasks:** 1 (Task 2 is checkpoint)
- **Files modified:** 1 (VPS: /opt/services/docker-compose.yml)

## Accomplishments
- Named Docker volume `dotsai_pgdata` created and confirmed on VPS
- postgres data copied from bind mount to named volume using Alpine container (cp -a preserves permissions)
- docker-compose.yml updated: bind mount replaced with named volume, `external: true` declaration added
- postgres recreated with named volume — healthy in under 5 seconds
- Both `calcom` and `analytics` schemas intact after migration
- dotsai.in responding normally post-migration
- Old bind-mount data preserved at /opt/services/postgres-data/ as 7-day rollback

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate postgres data to named volume and update docker-compose.yml** - see plan commit below

**Plan metadata:** (created in final commit)

## Files Created/Modified
- `/opt/services/docker-compose.yml` (VPS) - postgres volumes entry changed from `./postgres-data:/var/lib/postgresql/data` to `dotsai_pgdata:/var/lib/postgresql/data`; top-level volumes section updated with `dotsai_pgdata: { name: dotsai_pgdata, external: true }`

## Decisions Made
- Added `external: true` to dotsai_pgdata volume declaration — the volume was created via `docker volume create` before compose ran, so Docker Compose needs `external: true` to manage it without warning. This models the correct lifecycle: volume persists independent of compose stack.
- Preserved bind-mount data at /opt/services/postgres-data/ — 7-day safety net before deletion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added `external: true` to named volume declaration**
- **Found during:** Task 1 (Recreate postgres with named volume)
- **Issue:** Docker Compose warned "volume dotsai_pgdata already exists but was not created by Docker Compose. Use `external: true` to use an existing volume." This is a correctness issue — without `external: true`, compose may attempt to create the volume and behave unpredictably.
- **Fix:** Added `external: true` under the `dotsai_pgdata` volume declaration in the top-level `volumes:` block. Re-ran `docker compose up -d postgres` — warning gone, container running.
- **Files modified:** /opt/services/docker-compose.yml (VPS)
- **Verification:** `docker compose up -d postgres` output shows only orphan-containers warning (unrelated), no volume warning
- **Committed in:** Part of task 1 migration

---

**Total deviations:** 1 auto-fixed (1 missing critical config)
**Impact on plan:** Auto-fix essential for correct Docker Compose volume lifecycle management. No scope creep.

## Issues Encountered
None — migration executed cleanly. postgres was healthy immediately after recreation.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 5 Phase 1 ROADMAP success criteria now satisfied:
  1. pg_isready → healthy (was passing)
  2. calcom + analytics schemas exist (preserved through migration)
  3. No host port mapping (was passing)
  4. Named Docker volume dotsai_pgdata — CLOSED by this plan
  5. pg_dump backup cron + .sql.gz + 7-day prune (was passing)
- Phase 2 (FastAPI Analytics API) can begin
- Old bind-mount at /opt/services/postgres-data/ can be deleted after 7 days of healthy operation (after ~2026-04-03)

---
*Phase: 01-vps-pre-flight-postgresql-foundation*
*Completed: 2026-03-27*
