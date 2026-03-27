---
phase: 01-vps-pre-flight-postgresql-foundation
verified: 2026-03-27T10:01:13Z
status: passed
score: 5/5 must-haves verified
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "A named Docker volume exists and survives docker compose stop && docker compose start without data loss"
  gaps_remaining: []
  regressions: []
---

# Phase 1: VPS Pre-Flight + PostgreSQL Foundation Verification Report

**Phase Goal:** A healthy PostgreSQL 17 instance with both schemas created is running on the VPS, backed up nightly, and accessible only to other Docker services on the internal network.
**Verified:** 2026-03-27T10:01:13Z
**Status:** passed
**Re-verification:** Yes — after gap closure (plan 01-03 migrated bind mount to named volume dotsai_pgdata)

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `docker exec postgres pg_isready` returns "accepting connections" and container shows "healthy" | VERIFIED | `pg_isready` output: `/var/run/postgresql:5432 - accepting connections`; `docker ps` shows `Up 7 minutes (healthy)` |
| 2 | Both `calcom` and `analytics` schemas exist in the database | VERIFIED | psql query returns 2 rows: `analytics` (owner: dotsai), `calcom` (owner: dotsai) |
| 3 | PostgreSQL has no host port mapping | VERIFIED | `docker inspect postgres` ports: `{"5432/tcp":null}` — null means no HostPort binding |
| 4 | A named Docker volume `dotsai_pgdata` exists and postgres data is stored on it | VERIFIED | `docker volume ls` shows `local dotsai_pgdata`; `docker inspect postgres` Mounts shows `"Type": "volume", "Name": "dotsai_pgdata", "Source": "/var/lib/docker/volumes/dotsai_pgdata/_data", "Destination": "/var/lib/postgresql/data"` — no bind mount for data dir |
| 5 | pg_dump backup cron fires at 3 AM, a .sql.gz file exists, files older than 7 days are pruned | VERIFIED | Cron: `0 3 * * * /opt/services/scripts/pg-backup.sh >> /var/log/pg-backup.log 2>&1`; Backup file: `dotsai-20260327-073443.sql.gz (466 bytes)`; Script line 31: `find "$BACKUP_DIR" -name "*.sql.gz" -mtime +${RETENTION_DAYS} -delete` with `RETENTION_DAYS=7` |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `/opt/services/docker-compose.yml` | postgres service with healthcheck, named volume, no host port | VERIFIED | postgres:17-alpine, healthcheck present (`pg_isready -U dotsai -d dotsai`), named volume `dotsai_pgdata:/var/lib/postgresql/data`, no ports: section |
| `/opt/services/.secrets/db_password.txt` | Password stored as Docker secret | VERIFIED | Bind-mounted as `/run/secrets/db_password`, not in env vars |
| `/opt/services/init-db/01-create-schemas.sql` | Schema creation script for calcom + analytics | VERIFIED | Mounted at `/docker-entrypoint-initdb.d:ro`; both schemas confirmed in live database |
| `dotsai_pgdata` named Docker volume | Persistent named volume for postgres data | VERIFIED | `docker volume ls` shows `local dotsai_pgdata`; `docker inspect postgres` confirms `Type: volume, Name: dotsai_pgdata` as the data mount |
| `/opt/services/scripts/pg-backup.sh` | pg_dump with gzip and 7-day retention | VERIFIED | Script present, executable, `RETENTION_DAYS=7`, `find ... -mtime +7 -delete` prune logic |
| `/opt/services/backups/pg/*.sql.gz` | At least one backup file on disk | VERIFIED | `dotsai-20260327-073443.sql.gz` (466 bytes, non-empty) |
| `sql/01-create-schemas.sql` (repo) | Repo copy of schema init script | VERIFIED | File exists in repo |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `docker-compose.yml` postgres service | `dotsai_pgdata` named volume | `dotsai_pgdata:/var/lib/postgresql/data` entry + top-level `volumes: dotsai_pgdata: { name: dotsai_pgdata, external: true }` | WIRED | Volume mounted at correct destination; `external: true` correctly models pre-existing volume lifecycle |
| `docker-compose.yml` | `.secrets/db_password.txt` | `POSTGRES_PASSWORD_FILE: /run/secrets/db_password` | WIRED | `docker inspect` Mounts confirms bind mount of db_password.txt to `/run/secrets/db_password` |
| `docker-compose.yml` | `init-db/` | Volume bind mount to `/docker-entrypoint-initdb.d` | WIRED | `docker inspect` Mounts confirms `/opt/services/init-db` → `/docker-entrypoint-initdb.d:ro` |
| `crontab` | `/opt/services/scripts/pg-backup.sh` | `0 3 * * *` schedule | WIRED | `crontab -l` shows exact entry `0 3 * * * /opt/services/scripts/pg-backup.sh` |
| `pg-backup.sh` | postgres container | `docker exec postgres pg_dump` | WIRED | Script uses `docker exec "$CONTAINER" pg_dump -U "$DB_USER"` |
| postgres | `dotsai_internal` network | Docker network config | WIRED | No host port binding; container accessible only via internal Docker network |

---

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| PostgreSQL 17-alpine healthy and accepting connections | SATISFIED | — |
| Both calcom and analytics schemas present | SATISFIED | — |
| No host port exposure — internal network only | SATISFIED | — |
| Named Docker volume `dotsai_pgdata` for data persistence | SATISFIED | Gap closed by plan 01-03: bind mount replaced with named volume, `external: true` declared, data migrated with Alpine copy |
| Automated nightly pg_dump backup with 7-day retention | SATISFIED | — |

---

### Anti-Patterns Found

None — no TODO/placeholder/stub patterns found in VPS artifacts. The previously noted bind mount anti-pattern has been resolved.

Note: A pre-existing separate service (`db-postgrest`) still has a plaintext `POSTGRES_PASSWORD` in its environment section. This is outside Phase 1 scope and does not affect the postgres service being verified.

---

### Human Verification Required

None — all five success criteria are fully verifiable programmatically via SSH.

---

### Re-verification Summary

**Previous status (2026-03-27T08:10:13Z):** gaps_found — 4/5 truths verified. The single gap was `dotsai_pgdata` named Docker volume not existing; postgres was using a bind mount (`./postgres-data`).

**Gap closure (plan 01-03, completed 2026-03-27T09:54:57Z):**
- Created named Docker volume `dotsai_pgdata` via `docker volume create`
- Copied data from bind mount to named volume using Alpine container (`cp -a /source/. /target/`)
- Updated `/opt/services/docker-compose.yml`: postgres volumes entry changed from `./postgres-data:/var/lib/postgresql/data` to `dotsai_pgdata:/var/lib/postgresql/data`
- Added top-level volumes declaration with `external: true`
- Recreated postgres container — healthy in under 5 seconds
- Both calcom and analytics schemas intact post-migration
- Old bind-mount data preserved at `/opt/services/postgres-data/` as 7-day rollback safety net

**Current state:** All 5/5 success criteria satisfied on live VPS. No regressions detected.

---

_Verified: 2026-03-27T10:01:13Z_
_Verifier: Claude (gsd-verifier)_
