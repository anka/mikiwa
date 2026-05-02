#!/usr/bin/env bash
# Mikiwa – Nightly Backup Script
# Runs daily via cron: 0 2 * * * /app/script/backup.sh
# Backups are encrypted with GPG and rotated after 14 days.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/mikiwa}"
DB_PATH="${DB_PATH:-/app/storage/production.sqlite3}"
STORAGE_PATH="${STORAGE_PATH:-/app/storage}"
GPG_RECIPIENT="${GPG_RECIPIENT:-backup@mikiwa.at}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=14

mkdir -p "$BACKUP_DIR"

# Database backup
DB_BACKUP="$BACKUP_DIR/db_${TIMESTAMP}.sqlite3.gz.gpg"
sqlite3 "$DB_PATH" ".backup /tmp/mikiwa_db_backup.sqlite3"
gzip -c /tmp/mikiwa_db_backup.sqlite3 | gpg --encrypt --recipient "$GPG_RECIPIENT" --output "$DB_BACKUP"
rm -f /tmp/mikiwa_db_backup.sqlite3
echo "DB backup: $DB_BACKUP"

# Storage backup
STORAGE_BACKUP="$BACKUP_DIR/storage_${TIMESTAMP}.tar.gz.gpg"
tar -czf - -C "$STORAGE_PATH" . | gpg --encrypt --recipient "$GPG_RECIPIENT" --output "$STORAGE_BACKUP"
echo "Storage backup: $STORAGE_BACKUP"

# Rotate backups older than RETENTION_DAYS
find "$BACKUP_DIR" -name "*.gpg" -mtime +"$RETENTION_DAYS" -delete
echo "Backup complete. Retained last $RETENTION_DAYS days."
