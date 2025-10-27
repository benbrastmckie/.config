#!/usr/bin/env bash
# backup-command-file.sh
# Create timestamped backups of command files before editing

set -euo pipefail

# Usage: backup-command-file.sh <file-path>
# Creates backup at <file-path>.backup-YYYYMMDD_HHMMSS

FILE_PATH="${1:-}"

if [[ -z "$FILE_PATH" ]]; then
  echo "ERROR: No file path specified"
  echo "Usage: $0 <file-path>"
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "ERROR: File not found: $FILE_PATH"
  exit 1
fi

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${FILE_PATH}.backup-${TIMESTAMP}"

# Create backup
echo "Creating backup of: $FILE_PATH"
cp "$FILE_PATH" "$BACKUP_PATH"

# Verify backup integrity
if [[ ! -f "$BACKUP_PATH" ]]; then
  echo "ERROR: Backup file was not created: $BACKUP_PATH"
  exit 1
fi

# Compare file sizes
ORIG_SIZE=$(wc -c < "$FILE_PATH")
BACKUP_SIZE=$(wc -c < "$BACKUP_PATH")

if [[ "$ORIG_SIZE" -ne "$BACKUP_SIZE" ]]; then
  echo "ERROR: Backup file size mismatch"
  echo "  Original: $ORIG_SIZE bytes"
  echo "  Backup: $BACKUP_SIZE bytes"
  exit 1
fi

# Compare checksums
ORIG_HASH=$(sha256sum "$FILE_PATH" | cut -d' ' -f1)
BACKUP_HASH=$(sha256sum "$BACKUP_PATH" | cut -d' ' -f1)

if [[ "$ORIG_HASH" != "$BACKUP_HASH" ]]; then
  echo "ERROR: Backup file checksum mismatch"
  echo "  Original: $ORIG_HASH"
  echo "  Backup: $BACKUP_HASH"
  exit 1
fi

echo "✓ Backup created successfully: $BACKUP_PATH"
echo "  Size: $BACKUP_SIZE bytes"
echo "  SHA256: $BACKUP_HASH"
echo ""
echo "BACKUP_PATH=$BACKUP_PATH"

# Log backup operation
LOG_FILE="${FILE_PATH%/*}/../logs/backup-operations.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date -Iseconds)] BACKUP: $FILE_PATH -> $BACKUP_PATH" >> "$LOG_FILE"

exit 0
