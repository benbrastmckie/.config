#!/bin/bash
set -e

BACKUP_DATE="${1:-$(date +%Y%m%d)}"
BACKUP_FILE=".claude/tmp/backups/link-fix-${BACKUP_DATE}/markdown-files.tar.gz"

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Rolling back to backup from $BACKUP_DATE"
echo "This will restore all markdown files to their backed-up state"
read -p "Continue? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  tar -xzf "$BACKUP_FILE" -C /
  echo "Rollback complete"
  git status
else
  echo "Rollback cancelled"
fi
