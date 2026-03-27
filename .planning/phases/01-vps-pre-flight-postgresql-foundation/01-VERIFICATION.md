---
phase: 01-vps-pre-flight-postgresql-foundation
verified: 2026-03-27T08:10:13Z
status: gaps_found
score: 4/5 must-haves verified
gaps:
  - truth: "A named Docker volume exists and survives docker compose stop && docker compose start without data loss"
    status: failed
    reason: "postgres uses a bind mount (./postgres-data → /opt/services/postgres-data) not a named Docker volume. The named volume dotsai_pgdata does not exist on the VPS. Data persistence works via the bind mount, but the ROADMAP success criterion specifies a named Docker volume."
    artifacts:
      - path: "/opt/services/docker-compose.yml"
        issue: "volumes section for postgres service uses './postgres-data:/var/lib/postgresql/data' (bind mount) instead of 'pgdata:/var/lib/postgresql/data' with a named volume declaration"
    missing:
      - "Add named volume declaration in docker-compose.yml: volumes: pgdata: name: dotsai_pgdata"
      - "Change postgres volumes entry from './postgres-data:/var/lib/postgresql/data' to 'pgdata:/var/lib/postgresql/data'"
      - "Migrate existing data: docker volume create dotsai_pgdata, then copy from bind mount path into the volume, then recreate the container"
---

# Phase 1: VPS Pre-Flight + PostgreSQL Foundation Verification Report

**Phase Goal:** A healthy PostgreSQL 17 instance with both schemas created is running on the VPS, backed up nightly, and accessible only to other Docker services on the internal network.
**Verified:** 2026-03-27T08:10:13Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `docker exec postgres pg_isready` returns "accepting connections" and container shows "healthy" | VERIFIED | `pg_isready` output: `/var/run/postgresql:5432 - accepting connections`; `docker ps` shows `Up 35 minutes (healthy)` |
| 2 | Both `calcom` and `analytics` schemas exist in the database | VERIFIED | psql query returns 2 rows: `analytics`, `calcom` |
| 3 | PostgreSQL has no host port mapping | VERIFIED | `docker inspect postgres` ports: `{"5432/tcp":null}` — null means no HostPort binding |
| 4 | A named Docker volume exists and survives stop/start without data loss | FAILED | `docker volume ls` shows no `dotsai_pgdata` volume. Container uses bind mount `./postgres-data` instead. Data does persist via the bind mount, but the ROADMAP criterion specifies a named Docker volume. |
| 5 | pg_dump backup cron fires at 3 AM, a .sql.gz file exists, files older than 7 days are pruned | VERIFIED | Cron: `0 3 * * * /opt/services/scripts/pg-backup.sh >> /var/log/pg-backup.log 2>&1`; Backup file: `dotsai-20260327-073443.sql.gz (466 bytes)`; Script contains `find "$BACKUP_DIR" -name "*.sql.gz" -mtime +${RETENTION_DAYS} -delete` |

**Score:** 4/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `/opt/services/docker-compose.yml` | postgres service with healthcheck, secrets, no host port | VERIFIED | postgres:17-alpine, healthcheck present, POSTGRES_PASSWORD_FILE used, no ports: section |
| `/opt/services/.secrets/db_password.txt` | Password stored as Docker secret | VERIFIED | Bind-mounted as `/run/secrets/db_password`, not in env vars |
| `/opt/services/init-db/01-create-schemas.sql` | Schema creation script for calcom + analytics | VERIFIED | File exists at bind-mount source; schemas confirmed in database |
| `dotsai_pgdata` named Docker volume | Persistent named volume for postgres data | MISSING | Volume does not exist; container uses bind mount `./postgres-data` instead |
| `/opt/services/scripts/pg-backup.sh` | pg_dump with gzip and 7-day retention | VERIFIED | Script present, executable, contains pg_dump, find-based pruning, set -euo pipefail |
| `/opt/services/backups/pg/*.sql.gz` | At least one backup file on disk | VERIFIED | `dotsai-20260327-073443.sql.gz` (466 bytes, non-empty) |
| `sql/01-create-schemas.sql` (repo) | Repo copy of schema init script | VERIFIED | File exists in repo at commit 8d9d4f7 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `docker-compose.yml` | `.secrets/db_password.txt` | `POSTGRES_PASSWORD_FILE: /run/secrets/db_password` | WIRED | `docker inspect` env shows `POSTGRES_PASSWORD_FILE=/run/secrets/db_password`; no plaintext password |
| `docker-compose.yml` | `init-db/` | Volume bind mount to `/docker-entrypoint-initdb.d` | WIRED | Container mounts `/opt/services/init-db:/docker-entrypoint-initdb.d:ro` |
| `crontab` | `/opt/services/scripts/pg-backup.sh` | `0 3 * * *` schedule | WIRED | `crontab -l` shows exact entry |
| `pg-backup.sh` | postgres container | `docker exec postgres pg_dump` | WIRED | Script uses `docker exec "$CONTAINER" pg_dump -U "$DB_USER"` |
| postgres | `dotsai_internal` network | Docker network config | WIRED | `docker inspect` shows connected to both `dotsai_internal` and `services_services` |

---

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| PostgreSQL 17-alpine healthy and accepting connections | SATISFIED | — |
| Both calcom and analytics schemas present | SATISFIED | — |
| No host port exposure — internal network only | SATISFIED | — |
| Named Docker volume for data persistence | BLOCKED | Bind mount used instead of named volume; `dotsai_pgdata` does not exist |
| Automated nightly pg_dump backup with 7-day retention | SATISFIED | — |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `/opt/services/docker-compose.yml` | postgres volumes | Bind mount `./postgres-data` instead of named volume | Warning | Data is persisted but bind mounts have less portability and visibility than named volumes; `docker volume ls` will not show it; ROADMAP criterion is technically unmet |

---

### Additional Security Observation

The compose file shows another service (`db-postgrest` or similar) with `POSTGRES_PASSWORD=6a0NxO3mjlcKrA7iYw7aVDnX7kyN9` in plaintext in its environment section. This is a pre-existing issue noted in the SUMMARY ("Other services still have plaintext passwords") and is outside Phase 1 scope, but worth flagging.

---

### Human Verification Required

None — all criteria are verifiable programmatically via SSH.

---

### Gaps Summary

One gap blocks full goal achievement per the ROADMAP success criteria:

**Named volume vs. bind mount.** The ROADMAP specifies "A named Docker volume exists and survives `docker compose stop && docker compose start`". The SUMMARY claims `dotsai_pgdata` volume was created, but inspection of the live VPS shows:
- `docker volume ls | grep pgdata` returns only `finance_pgdata` (a different service's volume)
- `docker inspect postgres` shows three bind mounts, none of which are named Docker volumes
- The postgres data directory is `/opt/services/postgres-data` on the host filesystem

Data persistence itself works (bind mounts survive container restarts), and no data has been lost. However, the criterion is specific: a **named Docker volume**. The practical risk is lower because the bind mount data is at a known, accessible path. But to satisfy the written success criterion and align with the SUMMARY's own claims, the compose file needs to be updated to use a proper named volume with a data migration step.

All other four success criteria are fully satisfied on the live VPS.

---

_Verified: 2026-03-27T08:10:13Z_
_Verifier: Claude (gsd-verifier)_
