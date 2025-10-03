#!/usr/bin/env bash
# Clean up old checkpoints based on age
# Usage: cleanup-checkpoints.sh [max-age-days]

set -euo pipefail

MAX_AGE_DAYS="${1:-7}"
CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/checkpoints"
FAILED_DIR="${CHECKPOINTS_DIR}/failed"

# Ensure directories exist
mkdir -p "$FAILED_DIR"

if [ ! -d "$CHECKPOINTS_DIR" ]; then
  echo "No checkpoints directory found"
  exit 0
fi

DELETED_COUNT=0
ARCHIVED_COUNT=0

echo "Cleaning up checkpoints older than $MAX_AGE_DAYS days..."
echo ""

# Find and process old checkpoints
for checkpoint in "$CHECKPOINTS_DIR"/*.json 2>/dev/null; do
  [ -f "$checkpoint" ] || continue

  # Get file age in days
  if [ "$(uname)" = "Darwin" ]; then
    # macOS
    FILE_AGE=$(( ( $(date +%s) - $(stat -f %m "$checkpoint") ) / 86400 ))
  else
    # Linux
    FILE_AGE=$(( ( $(date +%s) - $(stat -c %Y "$checkpoint") ) / 86400 ))
  fi

  if [ "$FILE_AGE" -ge "$MAX_AGE_DAYS" ]; then
    filename=$(basename "$checkpoint")

    # Check if checkpoint indicates failure
    if command -v jq &> /dev/null && jq empty "$checkpoint" 2>/dev/null; then
      STATUS=$(jq -r '.status // "unknown"' "$checkpoint")
      LAST_ERROR=$(jq -r '.last_error // null' "$checkpoint")

      if [ "$STATUS" = "failed" ] || [ "$LAST_ERROR" != "null" ]; then
        # Archive failed checkpoints
        echo "Archiving failed checkpoint: $filename (age: ${FILE_AGE}d)"
        mv "$checkpoint" "$FAILED_DIR/"
        ((ARCHIVED_COUNT++))
      else
        # Delete old successful/abandoned checkpoints
        echo "Deleting old checkpoint: $filename (age: ${FILE_AGE}d)"
        rm "$checkpoint"
        ((DELETED_COUNT++))
      fi
    else
      # Can't parse, default to deletion
      echo "Deleting old checkpoint: $filename (age: ${FILE_AGE}d)"
      rm "$checkpoint"
      ((DELETED_COUNT++))
    fi
  fi
done

# Clean old archived failures (>30 days)
FAILED_CLEANUP_AGE=30
for checkpoint in "$FAILED_DIR"/*.json 2>/dev/null; do
  [ -f "$checkpoint" ] || continue

  if [ "$(uname)" = "Darwin" ]; then
    FILE_AGE=$(( ( $(date +%s) - $(stat -f %m "$checkpoint") ) / 86400 ))
  else
    FILE_AGE=$(( ( $(date +%s) - $(stat -c %Y "$checkpoint") ) / 86400 ))
  fi

  if [ "$FILE_AGE" -ge "$FAILED_CLEANUP_AGE" ]; then
    filename=$(basename "$checkpoint")
    echo "Deleting old archived failure: $filename (age: ${FILE_AGE}d)"
    rm "$checkpoint"
    ((DELETED_COUNT++))
  fi
done

echo ""
echo "Cleanup complete:"
echo "  Deleted: $DELETED_COUNT"
echo "  Archived: $ARCHIVED_COUNT"
