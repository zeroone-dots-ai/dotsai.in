# Phase 1: VPS Pre-Flight + PostgreSQL Foundation - Research

**Researched:** 2026-03-27
**Domain:** PostgreSQL 17 in Docker, VPS provisioning, backup automation
**Confidence:** HIGH

## Summary

This phase provisions the foundational database layer for the entire self-hosted hub. The core work is: audit VPS RAM, configure swap if needed, scaffold a Docker Compose file with a postgres:17 service (no host port, named volume, healthcheck), create two schemas (calcom + analytics) via init scripts, and set up automated pg_dump backups with 7-day retention.

PostgreSQL 17 in Docker is extremely well-documented and stable. The official `postgres:17` image handles initialization via `/docker-entrypoint-initdb.d/` scripts (SQL, shell, or gzipped SQL), runs as a non-root postgres user internally, and supports Docker secrets for password injection. The main risk areas are: forgetting that init scripts only run on an empty data directory, mounting volumes at the wrong path, and not setting `shm_size` which defaults to 64MB in Docker.

**Primary recommendation:** Use `postgres:17-alpine` for smaller image size, named Docker volume at `/var/lib/postgresql/data`, a single `.sql` init script that creates both schemas, and a host-level cron job running `docker exec` for pg_dump backups.

## Standard Stack

### Core
| Component | Version/Tag | Purpose | Why Standard |
|-----------|-------------|---------|--------------|
| PostgreSQL | `postgres:17-alpine` | Primary database for calcom + analytics | Official Docker image, Alpine variant ~80MB vs ~400MB Debian; PG17 is current stable |
| Docker Compose | v2 (compose.yaml) | Service orchestration | Already on VPS for nginx; standard for multi-container apps |
| pg_dump | Built into postgres:17 | Logical backup | Ships with the image, produces portable SQL dumps |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `fallocate` + `mkswap` | Swap file creation | If VPS has less than 3GB free RAM after `free -h` check |
| cron (host) | Scheduled pg_dump backups | Daily 3 AM backup + 7-day prune |
| `docker exec` | Run pg_dump inside container | Avoids installing pg_dump on host; version always matches |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| postgres:17-alpine | postgres:17 (Debian) | Debian is ~400MB vs ~80MB Alpine; only choose Debian if you need locale support beyond ICU or specific C libraries |
| Host cron + docker exec | Sidecar backup container (kartoza/docker-pg-backup) | Sidecar adds complexity; host cron is simpler for a single-database setup |
| Single database + schemas | Separate databases per app | Schemas in one DB allow cross-schema queries and simpler connection management; Cal.com supports `?schema=calcom` |

## Architecture Patterns

### Docker Compose Structure (on VPS)
```
/opt/services/
├── compose.yaml              # Main compose file — all services
├── .env                       # Environment variables (passwords, config)
├── init-db/
│   └── 01-create-schemas.sql  # Creates calcom + analytics schemas
└── backups/
    └── pg/                    # pg_dump output directory
```

### Pattern 1: Schema-per-Application in Single Database
**What:** One PostgreSQL database, multiple schemas (calcom, analytics). Each app connects with `?schema=<name>` or `SET search_path`.
**When to use:** When apps share a database server but need logical isolation.
**Example:**
```sql
-- /opt/services/init-db/01-create-schemas.sql
-- Source: PostgreSQL official docs + Cal.com documentation

-- Create schemas
CREATE SCHEMA IF NOT EXISTS calcom;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Create dedicated users with schema-specific access
CREATE USER calcom_user WITH PASSWORD :'CALCOM_DB_PASSWORD';
CREATE USER analytics_user WITH PASSWORD :'ANALYTICS_DB_PASSWORD';

-- Grant schema ownership
GRANT ALL ON SCHEMA calcom TO calcom_user;
GRANT ALL ON SCHEMA analytics TO analytics_user;

-- Set default search paths
ALTER USER calcom_user SET search_path TO calcom, public;
ALTER USER analytics_user SET search_path TO analytics, public;
```

### Pattern 2: Docker Compose Service with No Port Mapping
**What:** PostgreSQL service with no `ports:` section, only accessible via Docker internal network.
**When to use:** When the database should never be reachable from outside Docker.
**Example:**
```yaml
# Source: Docker Compose networking docs
services:
  postgres:
    image: postgres:17-alpine
    container_name: postgres
    restart: always
    shm_size: 256mb
    environment:
      POSTGRES_DB: dotsai
      POSTGRES_USER: dotsai_admin
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dotsai_admin -d dotsai"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s
    networks:
      - internal
    # NOTE: No "ports:" section — internal only

volumes:
  pgdata:
    name: dotsai_pgdata

secrets:
  db_password:
    file: ./.secrets/db_password.txt

networks:
  internal:
    name: dotsai_internal
```

### Pattern 3: Host Cron for pg_dump Backup
**What:** A cron job on the host machine that runs pg_dump inside the running container.
**When to use:** Simple single-database backup without sidecar containers.
**Example:**
```bash
# /opt/services/scripts/pg-backup.sh
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/opt/services/backups/pg"
CONTAINER="postgres"
DB_USER="dotsai_admin"
DB_NAME="dotsai"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}-${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

# Dump all schemas, compress
docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

# Verify non-empty
if [ ! -s "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file is empty" >&2
  exit 1
fi

# Prune old backups
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "OK: $(basename "$BACKUP_FILE") ($(du -h "$BACKUP_FILE" | cut -f1))"
```

```bash
# Crontab entry (root)
0 3 * * * /opt/services/scripts/pg-backup.sh >> /var/log/pg-backup.log 2>&1
```

### Anti-Patterns to Avoid
- **Mounting at `/var/lib/postgresql` instead of `/var/lib/postgresql/data`:** Data will NOT persist across container recreation. The official docs explicitly warn about this.
- **Using `docker compose down -v` in production:** This destroys named volumes. Use `docker compose down` (without -v) or `docker compose stop`.
- **Putting passwords in compose.yaml directly:** Use Docker secrets or `.env` file with restricted permissions (chmod 600).
- **Running init scripts that assume empty DB:** Scripts in `/docker-entrypoint-initdb.d/` only execute when the data directory is empty (first run). Use `IF NOT EXISTS` clauses so they are idempotent if run manually later.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Database healthcheck | Custom TCP check script | `pg_isready` (built into postgres image) | Handles connection states, auth modes, proper exit codes |
| Backup rotation | Custom date-parsing cleanup script | `find -mtime +N -delete` | Battle-tested, handles edge cases |
| Schema creation | Manual psql after container starts | `/docker-entrypoint-initdb.d/` SQL script | Runs automatically on first boot, no manual step to forget |
| Password generation | Manual typing | `openssl rand -base64 32` | Cryptographically random, meets 24-char minimum |
| Swap setup | Manual dd + mkswap | `fallocate -l 2G /swapfile` | Faster than dd, standard on modern Linux |

**Key insight:** PostgreSQL's Docker image has an excellent init system. Almost everything needed for first-boot setup (schemas, users, permissions, extensions) can be declaratively placed in `/docker-entrypoint-initdb.d/` and it runs in alphabetical order.

## Common Pitfalls

### Pitfall 1: Init Scripts Silently Skipped on Non-Empty Volume
**What goes wrong:** You add/modify init scripts but they never execute because the data directory already has data from a previous run.
**Why it happens:** The official postgres image only runs `/docker-entrypoint-initdb.d/` scripts when the PGDATA directory is empty.
**How to avoid:** Use `CREATE SCHEMA IF NOT EXISTS` and `CREATE USER IF NOT EXISTS` in SQL scripts. For schema changes after first boot, connect manually with `docker exec -it postgres psql -U dotsai_admin -d dotsai`.
**Warning signs:** Container starts healthy but schemas/users are missing.

### Pitfall 2: Docker Default shm_size (64MB) Too Low
**What goes wrong:** PostgreSQL crashes or refuses to start with "could not resize shared memory segment" errors when shared_buffers exceeds 64MB.
**Why it happens:** Docker defaults shm_size to 64MB. PostgreSQL's shared_buffers default is 128MB.
**How to avoid:** Always set `shm_size: 256mb` (or higher) in compose.yaml. Must be >= shared_buffers setting.
**Warning signs:** Container restart loops, "No space left on device" in postgres logs referencing shared memory.

### Pitfall 3: Existing nginx Docker Network Isolation
**What goes wrong:** PostgreSQL container cannot communicate with existing nginx container, or new services can't reach postgres.
**Why it happens:** Docker Compose creates a default network per project. If nginx is in a different compose project, it's on a different network.
**How to avoid:** Define a shared external network that both the existing nginx compose and the new services compose use. Or consolidate into one compose.yaml.
**Warning signs:** Connection refused errors between containers despite both running.

### Pitfall 4: VPS RAM Exhaustion with Docker + PostgreSQL
**What goes wrong:** OOM killer terminates postgres or other containers.
**Why it happens:** Small VPS (2-4GB RAM) with multiple Docker containers. PostgreSQL defaults (shared_buffers=128MB, work_mem=4MB * max_connections) can consume significant RAM.
**How to avoid:** Check `free -h` FIRST. Add 2GB swap if under 3GB available. Tune shared_buffers to 25% of available RAM (not total). Set max_connections low (20-50 for this use case). Set `deploy.resources.limits.memory` in compose.
**Warning signs:** High swap usage, slow queries, container restarts.

### Pitfall 5: Backup Script Fails Silently
**What goes wrong:** Cron job runs but produces empty or corrupt backup files, nobody notices for days.
**Why it happens:** docker exec fails (container not running), pipe to gzip swallows error, no alerting.
**How to avoid:** Use `set -euo pipefail` in script. Check backup file size after creation. Log to a file. Consider a simple health check (e.g., count backups in last 24h).
**Warning signs:** Backup directory has 0-byte .sql.gz files, or no recent files.

### Pitfall 6: Password in Environment Variable Visible via docker inspect
**What goes wrong:** `POSTGRES_PASSWORD` is visible in plaintext via `docker inspect postgres`.
**Why it happens:** Environment variables are stored in container metadata.
**How to avoid:** Use `POSTGRES_PASSWORD_FILE` with Docker secrets instead. Create a secrets file with restricted permissions.
**Warning signs:** Running `docker inspect postgres | grep PASSWORD` shows the password.

## Code Examples

### Complete compose.yaml for Phase 1
```yaml
# /opt/services/compose.yaml
# Source: Docker official postgres docs + Docker Compose networking docs

services:
  nginx:
    # ... existing nginx service ...
    networks:
      - internal
      - web

  postgres:
    image: postgres:17-alpine
    container_name: postgres
    restart: always
    shm_size: 256mb
    environment:
      POSTGRES_DB: dotsai
      POSTGRES_USER: dotsai_admin
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_INITDB_ARGS: "--data-checksums"
    secrets:
      - db_password
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dotsai_admin -d dotsai"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s
    networks:
      - internal
    # No ports: section — internal Docker network only

volumes:
  pgdata:
    name: dotsai_pgdata

secrets:
  db_password:
    file: ./.secrets/db_password.txt

networks:
  internal:
    name: dotsai_internal
  web:
    name: dotsai_web
```

### Schema Init Script
```sql
-- /opt/services/init-db/01-create-schemas.sql
-- Runs automatically on first container start (empty data dir only)
-- Uses IF NOT EXISTS for manual re-run safety

\set ON_ERROR_STOP on

-- Create application schemas
CREATE SCHEMA IF NOT EXISTS calcom;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Verify
DO $$
BEGIN
  ASSERT (SELECT COUNT(*) FROM information_schema.schemata
          WHERE schema_name IN ('calcom', 'analytics')) = 2,
         'Expected both calcom and analytics schemas to exist';
END $$;
```

### Swap Setup Commands (Hostinger VPS)
```bash
# Source: Hostinger official support docs
# Run as root on VPS

# Check current memory
free -h

# Create 2GB swap (only if under 3GB available)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Make persistent
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Optimize for production (prefer RAM, use swap as safety net)
echo 'vm.swappiness=10' >> /etc/sysctl.conf
sysctl -p

# Verify
swapon --show
free -h
```

### Password Generation
```bash
# Generate 32-char cryptographically random password
openssl rand -base64 32 > /opt/services/.secrets/db_password.txt
chmod 600 /opt/services/.secrets/db_password.txt
```

### Volume Persistence Verification
```bash
# After docker compose up -d, verify data survives restart
docker exec postgres psql -U dotsai_admin -d dotsai -c "CREATE TABLE test_persist (id int);"
docker compose stop postgres
docker compose start postgres
docker exec postgres psql -U dotsai_admin -d dotsai -c "SELECT * FROM test_persist;"
# Should return empty table (not "relation does not exist")
docker exec postgres psql -U dotsai_admin -d dotsai -c "DROP TABLE test_persist;"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `POSTGRES_HOST_AUTH_METHOD=trust` | `scram-sha-256` (default since PG14) | PostgreSQL 14+ | No action needed — secure by default |
| `docker-compose.yml` (v2 format) | `compose.yaml` (Compose v2 CLI) | 2023 | Use `compose.yaml` filename, `docker compose` (no hyphen) command |
| Debian-based postgres images only | Alpine variants widely stable | 2022+ | `postgres:17-alpine` is ~80MB vs ~400MB, suitable for production |
| `PGDATA=/var/lib/postgresql/data` everywhere | PG18+ changes to version-specific paths | PostgreSQL 18 (future) | PG17 still uses `/var/lib/postgresql/data` — no change needed now |
| `POSTGRES_PASSWORD` env var | `POSTGRES_PASSWORD_FILE` with Docker secrets | Docker secrets GA | More secure — password not in `docker inspect` output |
| `docker-compose` (v1 Python) | `docker compose` (v2 Go plugin) | 2023 (v1 deprecated) | Use `docker compose` command on VPS |

**Deprecated/outdated:**
- `docker-compose` v1 (Python): End-of-life. Use `docker compose` v2.
- `md5` auth method: Superseded by `scram-sha-256` in PG14+. Don't set `POSTGRES_HOST_AUTH_METHOD=md5`.

## Open Questions

1. **Exact VPS RAM and existing Docker memory usage**
   - What we know: VPS is Hostinger at 72.62.229.16, nginx already runs in Docker
   - What's unclear: Total RAM, current usage, existing swap, what else is running
   - Recommendation: First task in Plan 01-01 must be `free -h` and `docker stats --no-stream` on VPS before any provisioning

2. **Existing Docker Compose structure on VPS**
   - What we know: nginx is running in Docker at `/opt/services/`
   - What's unclear: Whether there's an existing compose.yaml, what network nginx uses, whether it's a standalone `docker run` or compose-managed
   - Recommendation: SSH into VPS and inspect: `ls /opt/services/`, `docker network ls`, `docker ps`, `cat /opt/services/compose.yaml` (or docker-compose.yml)

3. **Docker Compose v2 availability on VPS**
   - What we know: Docker is installed (nginx runs in it)
   - What's unclear: Whether `docker compose` (v2) is available or only legacy `docker-compose` (v1)
   - Recommendation: Check with `docker compose version` on VPS. If v1 only, install compose v2 plugin first.

4. **Cal.com schema compatibility with shared database**
   - What we know: Cal.com uses Prisma ORM and supports `?schema=calcom` in DATABASE_URL
   - What's unclear: Whether Prisma migrations create the schema automatically or expect it to pre-exist
   - Recommendation: Create the schema in init script (safe either way). Cal.com Prisma will use it via search_path.

## Sources

### Primary (HIGH confidence)
- [Docker Library postgres README](https://github.com/docker-library/docs/blob/master/postgres/README.md) — Environment variables, init scripts, volume paths, secrets support, PGDATA behavior
- [Docker Compose networking docs](https://docs.docker.com/compose/how-tos/networking/) — Internal network isolation, service discovery
- [Docker Compose healthcheck docs](https://docs.docker.com/compose/how-tos/startup-order/) — depends_on with service_healthy condition
- [PostgreSQL wiki: Tuning Your PostgreSQL Server](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server) — shared_buffers, work_mem sizing

### Secondary (MEDIUM confidence)
- [Hostinger swap setup guide](https://www.hostinger.com/support/8124185-how-to-set-up-swap-on-hostinger-vps) — Verified swap commands for Hostinger KVM VPS
- [Docker blog: How to Use the Postgres Docker Official Image](https://www.docker.com/blog/how-to-use-the-postgres-docker-official-image/) — Best practices overview
- [sliplane.io: Best Practices for Running PostgreSQL in Docker](https://sliplane.io/blog/best-practices-for-postgres-in-docker) — Volume mounting, production tips
- [serversinc.io: Automated PostgreSQL Backups in Docker](https://serversinc.io/blog/automated-postgresql-backups-in-docker-complete-guide-with-pg-dump/) — pg_dump patterns

### Tertiary (LOW confidence)
- Cal.com schema= parameter support in DATABASE_URL — based on community reports, needs validation during Phase 3

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — postgres:17-alpine is the official image, extremely well-documented
- Architecture: HIGH — Docker Compose with named volumes and internal networks is standard practice with extensive official documentation
- Pitfalls: HIGH — well-known issues (shm_size, init script skipping, volume mount paths) documented in official issue trackers
- VPS state: LOW — cannot verify RAM, existing compose, Docker version without SSH access

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable domain, PostgreSQL 17 is current major release)
