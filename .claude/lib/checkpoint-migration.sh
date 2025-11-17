#!/usr/bin/env bash
# checkpoint-migration.sh - Cross-command checkpoint compatibility and migration
#
# Version: 1.0.0
# Last Modified: 2025-11-17
#
# This utility handles checkpoint format versioning and enables cross-command resume
# (e.g., resume /build from /coordinate checkpoint). Provides migration functions
# for checkpoint schema evolution and backward compatibility validation.
#
# Usage:
#   source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-migration.sh"
#   migrate_checkpoint "$OLD_CHECKPOINT_PATH" "$NEW_FORMAT_VERSION"
#   validate_checkpoint_age "$CHECKPOINT_PATH" 7  # Max 7 days old
#
# Exit Codes:
#   0 - Migration successful or checkpoint valid
#   1 - Migration failed or checkpoint too old
#   2 - Invalid checkpoint format
#   3 - Checkpoint file not found

set -euo pipefail

# Source guard
if [ -n "${CHECKPOINT_MIGRATION_SOURCED:-}" ]; then
  return 0
fi
export CHECKPOINT_MIGRATION_SOURCED=1
export CHECKPOINT_MIGRATION_VERSION="1.0.0"

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
fi
export CLAUDE_PROJECT_DIR

# Source dependencies
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

# ==============================================================================
# Checkpoint Format Versions
# ==============================================================================

# Current checkpoint format version (semver)
readonly CHECKPOINT_FORMAT_VERSION="1.0.0"

# Checkpoint format changelog:
# v1.0.0 (2025-11-17): Initial format with workflow_type, plan_path, current_phase

# ==============================================================================
# Checkpoint Validation
# ==============================================================================

# Validate checkpoint age (prevent stale checkpoint resume)
# Args: $1 = checkpoint_path, $2 = max_age_days (default: 7)
# Returns: 0 if valid, 1 if too old, 3 if file not found
validate_checkpoint_age() {
  local checkpoint_path="$1"
  local max_age_days="${2:-7}"

  # Check if checkpoint exists
  if [ ! -f "$checkpoint_path" ]; then
    echo "ERROR: Checkpoint file not found: $checkpoint_path" >&2
    return 3
  fi

  # Get checkpoint modification time (seconds since epoch)
  local checkpoint_mtime=$(stat -c %Y "$checkpoint_path" 2>/dev/null || stat -f %m "$checkpoint_path" 2>/dev/null)
  local current_time=$(date +%s)
  local age_seconds=$((current_time - checkpoint_mtime))
  local age_days=$((age_seconds / 86400))

  if [ "$age_days" -gt "$max_age_days" ]; then
    echo "ERROR: Checkpoint too old (${age_days} days, max: ${max_age_days} days)" >&2
    echo "HINT: Checkpoint may be stale, consider starting fresh workflow" >&2
    return 1
  fi

  return 0
}

# Validate checkpoint format version
# Args: $1 = checkpoint_path
# Returns: 0 if valid, 2 if invalid format
validate_checkpoint_format() {
  local checkpoint_path="$1"

  # Check if checkpoint exists
  if [ ! -f "$checkpoint_path" ]; then
    echo "ERROR: Checkpoint file not found: $checkpoint_path" >&2
    return 3
  fi

  # Check if valid JSON
  if ! jq -e '.' "$checkpoint_path" >/dev/null 2>&1; then
    echo "ERROR: Checkpoint is not valid JSON: $checkpoint_path" >&2
    return 2
  fi

  # Check for required fields (v1.0.0 format)
  local required_fields=("workflow_description" "plan_path" "current_phase" "status")
  for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" "$checkpoint_path" >/dev/null 2>&1; then
      echo "ERROR: Checkpoint missing required field: $field" >&2
      return 2
    fi
  done

  return 0
}

# ==============================================================================
# Checkpoint Migration
# ==============================================================================

# Migrate checkpoint to current format version
# Args: $1 = checkpoint_path, $2 = target_format_version (default: current)
# Returns: 0 if successful, 1 if migration failed, 2 if invalid format
migrate_checkpoint() {
  local checkpoint_path="$1"
  local target_version="${2:-$CHECKPOINT_FORMAT_VERSION}"

  # Validate checkpoint exists
  if [ ! -f "$checkpoint_path" ]; then
    echo "ERROR: Checkpoint file not found: $checkpoint_path" >&2
    return 3
  fi

  # Validate source checkpoint format
  if ! validate_checkpoint_format "$checkpoint_path"; then
    echo "ERROR: Cannot migrate invalid checkpoint" >&2
    return 2
  fi

  # Extract current format version (default to 1.0.0 if not present)
  local source_version=$(jq -r '.format_version // "1.0.0"' "$checkpoint_path")

  # Check if migration needed
  if [ "$source_version" = "$target_version" ]; then
    echo "INFO: Checkpoint already at target version: $target_version" >&2
    return 0
  fi

  # Migration logic (placeholder for future versions)
  case "$source_version" in
    "1.0.0")
      case "$target_version" in
        "1.0.0")
          # No migration needed
          return 0
          ;;
        *)
          echo "ERROR: Unknown target format version: $target_version" >&2
          return 1
          ;;
      esac
      ;;
    *)
      echo "ERROR: Unknown source format version: $source_version" >&2
      return 1
      ;;
  esac
}

# ==============================================================================
# Cross-Command Resume
# ==============================================================================

# Map checkpoint from one command to another (e.g., /coordinate → /build)
# Args: $1 = source_command, $2 = target_command, $3 = checkpoint_path
# Returns: 0 if compatible, 1 if incompatible
map_checkpoint_cross_command() {
  local source_command="$1"
  local target_command="$2"
  local checkpoint_path="$3"

  # Validate checkpoint
  if ! validate_checkpoint_format "$checkpoint_path"; then
    return 2
  fi

  # Extract checkpoint workflow type
  local workflow_type=$(jq -r '.workflow_type // ""' "$checkpoint_path")

  # Cross-command compatibility matrix
  case "$source_command" in
    "coordinate")
      case "$target_command" in
        "build")
          # /coordinate → /build: Compatible if workflow_type allows implementation
          if [[ "$workflow_type" =~ ^(full-implementation|research-and-plan)$ ]]; then
            echo "INFO: Cross-command resume compatible: $source_command → $target_command" >&2
            return 0
          else
            echo "ERROR: Incompatible workflow type for cross-command resume: $workflow_type" >&2
            echo "HINT: /build requires full-implementation or research-and-plan workflow" >&2
            return 1
          fi
          ;;
        "research-report"|"research-plan"|"research-revise")
          echo "ERROR: Cannot resume research commands from /coordinate checkpoint" >&2
          echo "HINT: Research commands must start fresh (no resume)" >&2
          return 1
          ;;
        *)
          echo "ERROR: Unknown target command: $target_command" >&2
          return 1
          ;;
      esac
      ;;
    "build")
      # /build checkpoints are not resumable by other commands
      echo "ERROR: /build checkpoints cannot be resumed by other commands" >&2
      return 1
      ;;
    *)
      echo "ERROR: Unknown source command: $source_command" >&2
      return 1
      ;;
  esac
}

# Extract safe resume conditions from checkpoint
# Args: $1 = checkpoint_path
# Returns: 0 if safe to resume, 1 if unsafe
check_safe_resume_conditions() {
  local checkpoint_path="$1"

  # Validate checkpoint format
  if ! validate_checkpoint_format "$checkpoint_path"; then
    return 2
  fi

  # Validate checkpoint age (7 days max)
  if ! validate_checkpoint_age "$checkpoint_path" 7; then
    return 1
  fi

  # Check if checkpoint is in terminal state
  local status=$(jq -r '.status' "$checkpoint_path")
  if [ "$status" = "complete" ]; then
    echo "ERROR: Cannot resume from completed checkpoint" >&2
    return 1
  fi

  # Check if checkpoint has valid plan path
  local plan_path=$(jq -r '.plan_path' "$checkpoint_path")
  if [ ! -f "$plan_path" ]; then
    echo "ERROR: Plan file not found: $plan_path" >&2
    echo "HINT: Plan file may have been moved or deleted" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Checkpoint State Persistence Integration
# ==============================================================================

# Save checkpoint with format version
# Args: $1 = command_name, $2 = checkpoint_data_json
# Returns: 0 if successful, 1 if failed
save_versioned_checkpoint() {
  local command_name="$1"
  local checkpoint_data="$2"

  # Add format version to checkpoint data
  local versioned_data=$(echo "$checkpoint_data" | jq --arg version "$CHECKPOINT_FORMAT_VERSION" '. + {format_version: $version}')

  # Source checkpoint-utils.sh if not already sourced
  if ! declare -f save_checkpoint >/dev/null 2>&1; then
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"
  fi

  # Save checkpoint using checkpoint-utils.sh
  save_checkpoint "$command_name" "$versioned_data"
}

# Load checkpoint with format validation and migration
# Args: $1 = command_name
# Returns: checkpoint data JSON on stdout, exit code 0 if successful
load_versioned_checkpoint() {
  local command_name="$1"

  # Source checkpoint-utils.sh if not already sourced
  if ! declare -f load_checkpoint >/dev/null 2>&1; then
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"
  fi

  # Load checkpoint
  local checkpoint_data=$(load_checkpoint "$command_name" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    return $exit_code
  fi

  # Validate format
  local checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/checkpoint_${command_name}.json"
  if ! validate_checkpoint_format "$checkpoint_file"; then
    return 2
  fi

  # Migrate if needed
  migrate_checkpoint "$checkpoint_file" "$CHECKPOINT_FORMAT_VERSION"

  # Output checkpoint data
  echo "$checkpoint_data"
  return 0
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Display checkpoint compatibility matrix for debugging
show_checkpoint_compatibility() {
  cat <<'EOF'
=== Checkpoint Cross-Command Compatibility Matrix ===

Source Command → Target Command: Compatible Workflow Types
---------------------------------------------------------------
/coordinate → /build: full-implementation, research-and-plan
/coordinate → /research-*: INCOMPATIBLE (must start fresh)
/build → *: INCOMPATIBLE (not resumable)
/research-* → *: INCOMPATIBLE (not resumable)

Checkpoint Age Limit: 7 days
Checkpoint Format Version: 1.0.0
EOF
}
