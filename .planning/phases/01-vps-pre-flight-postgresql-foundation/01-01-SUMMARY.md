---
phase: 01-vps-pre-flight-postgresql-foundation
plan: 01
subsystem: infra
tags: [postgres, docker, docker-secrets, healthcheck, vps, compose]

# Dependency graph
requires: []
provides:
  - Healthy PostgreSQL 17-alpine container with Docker secrets
  - calcom and analytics schemas ready for Phase 2+3
  - dotsai_internal Docker network for inter-service communication
  - init-db volume mount for future schema migrations
affects: [01-02, 02-analytics-api, 03-calcom-self-hosted]

# Tech tracking
tech-stack:
  added: [docker-secrets, dotsai_internal-network]
  patterns: [POSTGRES_PASSWORD_FILE over POSTGRES_PASSWORD, internal-only networking]

key-files:
  created:
    - /opt/services/.secrets/db_password.txt
    - /opt/services/init-db/01-create-schemas.sql
    - /opt/services/backups/pg/ (directory)
    - /opt/services/scripts/ (directory)
    - sql/01-create-schemas.sql (repo copy)
  modified:
    - /opt/services/docker-compose.yml

key-decisions:
  - "Kept existing user 'dotsai' instead of plan's 'dotsai_admin' — 10+ services depend on it"
  - "Used existing password in Docker secrets instead of generating new one — avoids breaking all dependent services"
  - "Kept docker-compose.yml naming (not compose.yaml) — matches existing VPS convention"
  - "Added postgres to both 'services' and 'internal' networks — backward compatible with existing services"

patterns-established:
  - "Docker secrets: use POSTGRES_PASSWORD_FILE, never POSTGRES_PASSWORD in env"
  - "Internal networking: services that don't need host access use dotsai_internal"
  - "Schema init: SQL files in /opt/services/init-db/ for reproducible setup"

# Metrics
duration: 6min
completed: 2026-03-27
---

# Phase 1 Plan 01: VPS Pre-Flight + PostgreSQL Foundation Summary

**PostgreSQL 17-alpine secured with Docker secrets, internal-only networking, healthcheck, and calcom/analytics schemas created**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-27T07:01:10Z
- **Completed:** 2026-03-27T07:07:51Z
- **Tasks:** 2 of 2 (Task 1 auto, Task 2 human-verify checkpoint — approved)
- **Files modified:** 4 VPS files + 1 repo file

## Accomplishments
- Migrated postgres password from plaintext environment variable to Docker secrets (POSTGRES_PASSWORD_FILE)
- Removed host port mapping (127.0.0.1:5432) — postgres now accessible only via Docker internal network
- Added healthcheck (pg_isready), shm_size 256mb, restart always policy
- Created calcom and analytics schemas in existing database
- Added dotsai_internal network, connected both nginx and postgres to it
- Created init-db directory with schema creation script for future re-initialization
- Backed up existing compose file before modifications

## VPS Audit Results
- **RAM:** 31GB total, 24GB available (well above 3GB threshold)
- **Swap:** 8GB already configured (no action needed)
- **Docker Compose:** v5.0.2 (v2+ confirmed)
- **Running containers:** 80+ services
- **Existing postgres:** Already running postgres:17-alpine with data

## Task Commits

1. **Task 1: VPS audit, swap setup, and Docker Compose scaffold with postgres:17-alpine** - `8d9d4f7` (feat)
2. **Task 2: Verify VPS audit and PostgreSQL container health** - checkpoint:human-verify — user approved with "proceed"

## Files Created/Modified
- `/opt/services/docker-compose.yml` - Updated postgres service: secrets, healthcheck, no host port, internal network
- `/opt/services/.secrets/db_password.txt` - Database password stored securely (chmod 600)
- `/opt/services/init-db/01-create-schemas.sql` - Schema creation script for calcom + analytics
- `/opt/services/backups/pg/` - Directory for future PostgreSQL backups
- `/opt/services/scripts/` - Directory for future maintenance scripts
- `sql/01-create-schemas.sql` - Repo copy of schema init script

## Decisions Made
1. **Kept existing user `dotsai` instead of `dotsai_admin`** — The plan specified `dotsai_admin` but the existing database has 10+ services connecting as `dotsai`. Changing would require simultaneous migration of all dependent services. The user name is less important than the security improvements (secrets, no host port).

2. **Used existing password in Docker secrets** — Generated a new 44-char password initially, but realized PostgreSQL only reads POSTGRES_PASSWORD_FILE on first initialization. Since data directory exists, stored the existing password in the secrets file instead. Password rotation deferred to avoid breaking dependent services.

3. **Kept `docker-compose.yml` naming** — Plan specified `compose.yaml` but VPS already uses `docker-compose.yml` with 80+ services. Renaming would be disruptive for no benefit.

4. **Dual-network strategy** — Added postgres to both `services` (existing) and `internal` (new dotsai_internal) networks. This keeps backward compatibility while establishing the new internal network pattern.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Adapted to existing PostgreSQL instead of fresh install**
- **Found during:** Task 1, Step 1 (VPS audit)
- **Issue:** Plan assumed no PostgreSQL existed. VPS already has postgres:17-alpine running with data, schemas, and 10+ dependent services
- **Fix:** Modified approach to secure existing postgres (add secrets, remove host port, add healthcheck) rather than creating from scratch. Created schemas directly via `psql` instead of relying on init-db (which only runs on first init)
- **Files modified:** /opt/services/docker-compose.yml
- **Verification:** postgres healthy, no host port, password in secrets, schemas exist
- **Committed in:** 8d9d4f7

**2. [Rule 1 - Bug] Fixed password exposure in docker inspect**
- **Found during:** Task 1, Step 1 (VPS audit)
- **Issue:** Existing postgres had password in plaintext via POSTGRES_PASSWORD environment variable, visible in `docker inspect`
- **Fix:** Migrated to POSTGRES_PASSWORD_FILE pointing to Docker secret
- **Files modified:** /opt/services/docker-compose.yml, /opt/services/.secrets/db_password.txt
- **Verification:** `docker inspect postgres --format="{{json .Config.Env}}"` shows POSTGRES_PASSWORD_FILE, not POSTGRES_PASSWORD
- **Committed in:** 8d9d4f7

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Adaptations were necessary due to existing infrastructure. All security objectives met. No scope creep.

## Issues Encountered
- Compose file had `frontend_default` network between `services` and end of networks section, causing the `internal` network insertion to require manual adjustment
- Nginx accidentally got `internal` network listed twice during patching -- fixed immediately
- `finance-nginx-1` container is in a restart loop (pre-existing issue, not caused by our changes)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PostgreSQL healthy and secured, ready for Plan 02 (schema verification + backup cron)
- calcom and analytics schemas exist, ready for Phase 3 (Cal.com self-hosted)
- dotsai_internal network ready for Phase 2 (analytics API)
- **Note:** Other services still have plaintext passwords in docker-compose.yml environment sections -- password rotation should be planned as a separate effort

## Verification Checklist
- [x] VPS has >= 3GB available RAM (24GB available)
- [x] Swap configured (8GB pre-existing)
- [x] Docker Compose v2+ available (v5.0.2)
- [x] PostgreSQL container is healthy
- [x] No host port mapping on postgres container
- [x] Password stored as Docker secret, not env var
- [x] calcom and analytics schemas exist
- [x] Existing nginx service and dotsai.in unaffected

## Self-Check: PASSED

All artifacts verified:
- Local: sql/01-create-schemas.sql, 01-01-SUMMARY.md
- Commit: 8d9d4f7 exists in git log
- VPS: .secrets/db_password.txt, init-db/01-create-schemas.sql, postgres container healthy

---
*Phase: 01-vps-pre-flight-postgresql-foundation*
*Completed: 2026-03-27*
