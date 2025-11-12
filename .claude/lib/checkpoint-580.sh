#!/usr/bin/env bash
# Checkpoint helper for Plan 580 branch merge implementation
# Provides standardized checkpoint tracking across all phases

CHECKPOINT_FILE="/tmp/merge_checkpoints.txt"

# record_phase_completion - Record phase completion in checkpoint file
#
# Arguments:
#   $1 - phase_number (1-9)
#   $2 - phase_name (description)
#
# Returns:
#   0 - Success
#   1 - Invalid arguments
#
record_phase_completion() {
  local phase_number="$1"
  local phase_name="$2"

  if [ -z "$phase_number" ] || [ -z "$phase_name" ]; then
    echo "ERROR: record_phase_completion requires phase_number and phase_name" >&2
    return 1
  fi

  echo "Phase $phase_number: COMPLETE - $phase_name" >> "$CHECKPOINT_FILE"
  echo "  Timestamp: $(date -Iseconds)" >> "$CHECKPOINT_FILE"
  return 0
}

export -f record_phase_completion
