#!/usr/bin/env bash
# Online SQLite backup for Mikiwa. Runs daily via /etc/cron.d/mikiwa-backup.
# Uses `sqlite3 .backup` (requires the sqlite3 binary on the host) which is
# safe against concurrent writes.
# See docs/deployment.md §2.8.

set -euo pipefail

BACKUP_DIR=/home/mikiwa/backups
STORAGE_DIR=/home/mikiwa/storage
DATE=$(date +%F)
RETENTION_DAYS=14

mkdir -p "$BACKUP_DIR"

for db in production production_cache production_queue production_cable; do
    src="${STORAGE_DIR}/${db}.sqlite3"
    dst="${BACKUP_DIR}/${db}-${DATE}.sqlite3"

    if [ ! -f "$src" ]; then
        echo "skip: $src not found"
        continue
    fi

    sqlite3 "$src" ".backup '${dst}'"
    gzip -f "$dst"
    echo "backup: ${dst}.gz"
done

find "$BACKUP_DIR" -name "*.sqlite3.gz" -mtime "+${RETENTION_DAYS}" -delete
echo "retention: removed backups older than ${RETENTION_DAYS} days"
