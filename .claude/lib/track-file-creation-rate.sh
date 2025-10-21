#!/bin/bash
# Track file creation rates for commands and agents
# Usage: ./track-file-creation-rate.sh <type> <name> <success_count> <total_runs>

set -euo pipefail

TYPE=$1  # "command" or "agent"
NAME=$2
SUCCESS_COUNT=$3
TOTAL_RUNS=$4

# Calculate success rate
SUCCESS_RATE=$((SUCCESS_COUNT * 100 / TOTAL_RUNS))

# Tracking file
TRACKING_FILE="/home/benjamin/.config/.claude/specs/plans/077_execution_enforcement_migration/077_migration_tracking.csv"

# Ensure tracking file exists with header
if [ ! -f "$TRACKING_FILE" ]; then
  mkdir -p "$(dirname "$TRACKING_FILE")"
  echo "Type,Name,Pre-Score,Post-Score,File Creation Rate,Success Count,Total Runs,Duration,Status,Date" > "$TRACKING_FILE"
fi

# Check if entry exists
if grep -q "^${TYPE},${NAME}," "$TRACKING_FILE"; then
  # Update existing entry with file creation rate
  sed -i "s|^${TYPE},${NAME},\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\)|${TYPE},${NAME},\1,\2,${SUCCESS_RATE}%,${SUCCESS_COUNT},${TOTAL_RUNS}|" "$TRACKING_FILE"
else
  # Add new entry
  echo "${TYPE},${NAME},N/A,N/A,${SUCCESS_RATE}%,${SUCCESS_COUNT},${TOTAL_RUNS},N/A,PENDING,$(date +%Y-%m-%d)" >> "$TRACKING_FILE"
fi

# Output result
echo "Tracked: ${TYPE}/${NAME} - ${SUCCESS_RATE}% (${SUCCESS_COUNT}/${TOTAL_RUNS})"

# Return success if 100%
[ $SUCCESS_COUNT -eq $TOTAL_RUNS ] && exit 0 || exit 1
