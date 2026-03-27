#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/opt/services/backups/pg"
CONTAINER="postgres"
DB_USER="dotsai"
DB_NAME="dotsai"
SCHEMAS="calcom analytics"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}-${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

# Build schema flags for pg_dump
SCHEMA_FLAGS=""
for s in $SCHEMAS; do
  SCHEMA_FLAGS="$SCHEMA_FLAGS --schema=$s"
done

# Dump specified schemas only, compress
docker exec "$CONTAINER" pg_dump -U "$DB_USER" $SCHEMA_FLAGS "$DB_NAME" | gzip > "$BACKUP_FILE"

# Verify non-empty
if [ ! -s "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file is empty" >&2
  exit 1
fi

# Prune old backups
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "OK: $(basename "$BACKUP_FILE") ($(du -h "$BACKUP_FILE" | cut -f1))"
