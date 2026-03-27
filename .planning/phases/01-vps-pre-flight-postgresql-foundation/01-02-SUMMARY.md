---
phase: 01-vps-pre-flight-postgresql-foundation
plan: 02
subsystem: infra
tags: [postgres, pg_dump, cron, backup, docker, vps]

# Dependency graph
requires:
  - phase: 01-01
    provides: Healthy PostgreSQL with calcom/analytics schemas and dotsai_internal network
provides:
  - calcom and analytics schemas verified present
  - Data persistence proven via docker compose stop/start cycle
  - pg_dump backup script at /opt/services/scripts/pg-backup.sh with 7-day retention
  - Daily 3 AM cron job writing to /opt/services/backups/pg/
  - Database credentials logged to ~/Desktop/Vault/dotsai.in/
affects: [02-analytics-api, 03-calcom-self-hosted]

# Tech tracking
tech-stack:
  added: [pg_dump, cron]
  patterns: [gzip-compressed SQL backups, find-based retention pruning, set -euo pipefail bash scripts]

key-files:
  created:
    - /opt/services/scripts/pg-backup.sh
    - /opt/services/backups/pg/ (backup output directory)
    - ~/Desktop/Vault/dotsai.in/db_password.txt
    - ~/Desktop/Vault/dotsai.in/credentials.md
  modified:
    - /var/spool/cron/crontabs/root (cron entry added)

key-decisions:
  - "Used docker exec pg_dump (not pg_dumpall) — backs up dotsai database only, sufficient for current scope"
  - "7-day retention via find -mtime keeps ~7 backup files — adequate RPO with minimal storage growth"

patterns-established:
  - "Backup scripts: set -euo pipefail, verify non-empty output, prune in same run"
  - "Cron log: append stdout/stderr to /var/log/pg-backup.log for auditability"

# Metrics
duration: 8min
completed: 2026-03-27
---

# Phase 1 Plan 02: VPS Pre-Flight + PostgreSQL Foundation Summary

**pg_dump backup cron deployed with 7-day retention, volume persistence confirmed, and all Phase 1 success criteria met**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-27T07:10:00Z
- **Completed:** 2026-03-27T07:18:00Z
- **Tasks:** 2 of 2 (Task 1 auto, Task 2 human-verify checkpoint — approved)
- **Files modified:** 2 VPS files + 1 new VPS script + 2 local Vault files

## Accomplishments
- Verified both `calcom` and `analytics` schemas present in the dotsai database
- Proved data persistence: wrote row, stopped postgres container, started it, row survived
- Deployed `/opt/services/scripts/pg-backup.sh` — pg_dump with gzip compression and 7-day retention pruning
- Ran backup script manually — confirmed non-empty .sql.gz file written to /opt/services/backups/pg/
- Installed daily 3 AM cron (`0 3 * * *`) logging to /var/log/pg-backup.log
- Logged database credentials to ~/Desktop/Vault/dotsai.in/ per Desktop CLAUDE.md agent directive

## Task Commits

1. **Task 1: Verify schemas, test persistence, deploy backup cron** - `3b5673a` (feat)
2. **Task 2: Verify PostgreSQL foundation completeness** - checkpoint:human-verify — user approved with "next"

**Plan metadata:** pending (this commit)

## Files Created/Modified
- `/opt/services/scripts/pg-backup.sh` - pg_dump backup script: gzip output, non-empty check, 7-day retention via find
- `/opt/services/backups/pg/` - Contains at least one .sql.gz backup from manual test run
- `/var/spool/cron/crontabs/root` - cron entry: `0 3 * * * /opt/services/scripts/pg-backup.sh >> /var/log/pg-backup.log 2>&1`
- `~/Desktop/Vault/dotsai.in/db_password.txt` - Database password mirrored from VPS secret
- `~/Desktop/Vault/dotsai.in/credentials.md` - Connection string, schema info, security notes

## Decisions Made
1. **Used `docker exec pg_dump` (database-scoped)** — backs up the `dotsai` database only. pg_dumpall would include pg system tables and other databases irrelevant to this project. Single-database dump is simpler to restore.

2. **7-day retention** — matches ROADMAP requirement. Produces at most 7 files before pruning begins. Storage growth is bounded at ~7 × backup size.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — all steps completed as specified.

## User Setup Required

None — no external service configuration required.

## Phase 1 Verification Checklist

All five ROADMAP success criteria for Phase 1 satisfied:

- [x] `docker exec postgres pg_isready` returns "accepting connections" AND `docker ps` shows "healthy"
- [x] Both `calcom` and `analytics` schemas exist in the dotsai database
- [x] No HostPort entries in `docker inspect postgres` — internal-only access
- [x] Named volume `dotsai_pgdata` survives `docker compose stop && docker compose start`
- [x] pg_dump backup cron installed at 3 AM, .sql.gz exists on disk, 7-day prune configured

## Next Phase Readiness
- Phase 1 fully complete. VPS is ready for Phase 2 (FastAPI analytics API).
- PostgreSQL healthy at postgres:5432 on dotsai_internal network — analytics API can connect directly
- Schemas exist: `analytics` (ready for FastAPI tables), `calcom` (ready for Phase 3)
- **Open blockers for later phases:**
  - DNS A records for cal.dotsai.in, api.dotsai.in, meet.dotsai.in must point to 72.62.229.16 before certbot runs in Phases 2, 3, 5
  - Cal.com exact semver image tag — confirm on hub.docker.com before Phase 3
  - asyncpg 0.29.0 pin confidence MEDIUM — verify `create_async_engine` on fresh setup at start of Phase 2

## Self-Check: PASSED

- `/opt/services/scripts/pg-backup.sh` exists on VPS (deployed in Task 1)
- `/opt/services/backups/pg/` has at least one .sql.gz (confirmed in Task 1 verify)
- Cron entry present (confirmed in Task 1 verify)
- Task commit `3b5673a` exists in git log

---
*Phase: 01-vps-pre-flight-postgresql-foundation*
*Completed: 2026-03-27*
