#!/usr/bin/env bash
# rollback-command-file.sh
# Rollback a command file to a previous backup

set -euo pipefail

# Usage: rollback-command-file.sh <backup-file-path>
# Restores the backup to the original file location

BACKUP_PATH="${1:-}"

if [[ -z "$BACKUP_PATH" ]]; then
  echo "ERROR: No backup file specified"
  echo "Usage: $0 <backup-file-path>"
  echo ""
  echo "To list available backups:"
  echo "  ls -lt .claude/commands/*.backup-*"
  exit 1
fi

if [[ ! -f "$BACKUP_PATH" ]]; then
  echo "ERROR: Backup file not found: $BACKUP_PATH"
  exit 1
fi

# Extract original file path (remove .backup-TIMESTAMP suffix)
if [[ "$BACKUP_PATH" =~ (.*)\.backup-[0-9]{8}_[0-9]{6}$ ]]; then
  ORIG_PATH="${BASH_REMATCH[1]}"
else
  echo "ERROR: Invalid backup file name format: $BACKUP_PATH"
  echo "Expected format: <file>.backup-YYYYMMDD_HHMMSS"
  exit 1
fi

echo "Rollback plan:"
echo "  Backup file: $BACKUP_PATH"
echo "  Target file: $ORIG_PATH"
echo ""

# Verify backup integrity
BACKUP_SIZE=$(wc -c < "$BACKUP_PATH")
BACKUP_HASH=$(sha256sum "$BACKUP_PATH" | cut -d' ' -f1)
echo "Backup file verification:"
echo "  Size: $BACKUP_SIZE bytes"
echo "  SHA256: $BACKUP_HASH"
echo ""

# Create a backup of current state before rollback (safety net)
if [[ -f "$ORIG_PATH" ]]; then
  SAFETY_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  SAFETY_BACKUP="${ORIG_PATH}.pre-rollback-${SAFETY_TIMESTAMP}"
  echo "Creating safety backup of current state: $SAFETY_BACKUP"
  cp "$ORIG_PATH" "$SAFETY_BACKUP"
  echo ""
fi

# Perform rollback
echo "Restoring backup to: $ORIG_PATH"
cp "$BACKUP_PATH" "$ORIG_PATH"

# Verify rollback
RESTORED_SIZE=$(wc -c < "$ORIG_PATH")
RESTORED_HASH=$(sha256sum "$ORIG_PATH" | cut -d' ' -f1)

if [[ "$BACKUP_HASH" != "$RESTORED_HASH" ]]; then
  echo "ERROR: Rollback verification failed - checksum mismatch"
  echo "  Expected: $BACKUP_HASH"
  echo "  Got: $RESTORED_HASH"
  echo ""
  echo "Attempting to restore safety backup..."
  if [[ -f "$SAFETY_BACKUP" ]]; then
    cp "$SAFETY_BACKUP" "$ORIG_PATH"
    echo "Safety backup restored"
  fi
  exit 1
fi

echo "✓ Rollback completed successfully"
echo "  Restored: $ORIG_PATH"
echo "  Size: $RESTORED_SIZE bytes"
echo "  SHA256: $RESTORED_HASH"
echo ""

# Log rollback operation
LOG_FILE="${ORIG_PATH%/*}/../logs/backup-operations.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date -Iseconds)] ROLLBACK: $BACKUP_PATH -> $ORIG_PATH" >> "$LOG_FILE"

# Suggest verification steps
echo "Next steps:"
echo "1. Verify the rolled-back file: cat $ORIG_PATH | head -20"
echo "2. Test the command if applicable"
echo "3. Check diff against backup: diff $ORIG_PATH $BACKUP_PATH"

exit 0
