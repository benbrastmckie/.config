#!/usr/bin/env bash
# Shared checkpoint management utilities
# Provides functions for checkpoint save, load, validate, and migrate

set -euo pipefail

# ==============================================================================
# Checkpoint Schema
# ==============================================================================

# Schema version for checkpoint format
readonly CHECKPOINT_SCHEMA_VERSION="1.1"

# Checkpoint directory
readonly CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/checkpoints"

# ==============================================================================
# Core Functions
# ==============================================================================

# save_checkpoint: Save workflow checkpoint for resume capability
# Usage: save_checkpoint <workflow-type> <project-name> <state-json>
# Returns: Path to saved checkpoint file
# Example: save_checkpoint "implement" "auth_system" '{"phase":2}'
save_checkpoint() {
  local workflow_type="${1:-}"
  local project_name="${2:-}"
  local state_json="${3:-}"

  if [ -z "$workflow_type" ] || [ -z "$project_name" ]; then
    echo "Usage: save_checkpoint <workflow-type> <project-name> <state-json>" >&2
    return 1
  fi

  # Read state from stdin if not provided as argument
  if [ -z "$state_json" ]; then
    state_json=$(cat)
  fi

  # Ensure checkpoints directory exists
  mkdir -p "$CHECKPOINTS_DIR"

  local timestamp=$(date -u +%Y%m%d_%H%M%S)
  local checkpoint_id="${workflow_type}_${project_name}_${timestamp}"
  local checkpoint_file="${CHECKPOINTS_DIR}/${checkpoint_id}.json"
  local temp_file="${checkpoint_file}.tmp"

  # Build checkpoint data with schema
  local checkpoint_data
  if command -v jq &> /dev/null; then
    # Use jq for robust JSON handling
    checkpoint_data=$(jq -n \
      --arg version "$CHECKPOINT_SCHEMA_VERSION" \
      --arg id "$checkpoint_id" \
      --arg type "$workflow_type" \
      --arg project "$project_name" \
      --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --argjson state "$state_json" \
      '{
        schema_version: $version,
        checkpoint_id: $id,
        workflow_type: $type,
        project_name: $project,
        workflow_description: ($state.workflow_description // ""),
        created_at: $created,
        updated_at: $created,
        status: ($state.status // "in_progress"),
        current_phase: ($state.current_phase // 0),
        total_phases: ($state.total_phases // 0),
        completed_phases: ($state.completed_phases // []),
        workflow_state: $state,
        last_error: ($state.last_error // null),
        replanning_count: ($state.replanning_count // 0),
        last_replan_reason: ($state.last_replan_reason // null),
        replan_phase_counts: ($state.replan_phase_counts // {}),
        replan_history: ($state.replan_history // [])
      }')
  else
    # Fallback: Basic JSON construction without jq
    local created=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    checkpoint_data=$(cat <<EOF
{
  "schema_version": "$CHECKPOINT_SCHEMA_VERSION",
  "checkpoint_id": "$checkpoint_id",
  "workflow_type": "$workflow_type",
  "project_name": "$project_name",
  "workflow_description": "",
  "created_at": "$created",
  "updated_at": "$created",
  "status": "in_progress",
  "current_phase": 0,
  "total_phases": 0,
  "completed_phases": [],
  "workflow_state": $state_json,
  "last_error": null,
  "replanning_count": 0,
  "last_replan_reason": null,
  "replan_phase_counts": {},
  "replan_history": []
}
EOF
)
  fi

  # Atomic write: write to temp file then rename
  echo "$checkpoint_data" > "$temp_file"
  mv "$temp_file" "$checkpoint_file"

  # Output checkpoint path for caller
  echo "$checkpoint_file"
}

# restore_checkpoint: Load most recent checkpoint for workflow type
# Usage: restore_checkpoint <workflow-type> [project-name]
# Returns: Checkpoint JSON data
# Example: restore_checkpoint "implement" "auth_system"
restore_checkpoint() {
  local workflow_type="${1:-}"
  local project_name="${2:-}"

  if [ -z "$workflow_type" ]; then
    echo "Usage: restore_checkpoint <workflow-type> [project-name]" >&2
    return 1
  fi

  # Ensure checkpoints directory exists
  if [ ! -d "$CHECKPOINTS_DIR" ]; then
    echo "No checkpoints directory found" >&2
    return 1
  fi

  # Find most recent checkpoint matching workflow type and optional project name
  local pattern
  if [ -n "$project_name" ]; then
    pattern="${workflow_type}_${project_name}_*.json"
  else
    pattern="${workflow_type}_*.json"
  fi

  # Find most recent checkpoint (sort by filename which includes timestamp)
  local checkpoint_file
  checkpoint_file=$(ls -t "$CHECKPOINTS_DIR"/$pattern 2>/dev/null | head -1 || true)

  if [ -z "$checkpoint_file" ]; then
    echo "No checkpoint found for workflow type: $workflow_type" >&2
    return 1
  fi

  # Validate checkpoint file exists and is readable
  if [ ! -f "$checkpoint_file" ] || [ ! -r "$checkpoint_file" ]; then
    echo "Checkpoint file not readable: $checkpoint_file" >&2
    return 1
  fi

  # Validate JSON if jq available
  if command -v jq &> /dev/null; then
    if ! jq empty "$checkpoint_file" 2>/dev/null; then
      echo "Corrupted checkpoint (invalid JSON): $checkpoint_file" >&2
      echo "Delete with: rm \"$checkpoint_file\"" >&2
      return 1
    fi
  fi

  # Migrate checkpoint if needed
  migrate_checkpoint_format "$checkpoint_file"

  # Output checkpoint contents
  cat "$checkpoint_file"
}

# validate_checkpoint: Validate checkpoint structure and schema
# Usage: validate_checkpoint <checkpoint-file>
# Returns: 0 if valid, 1 if invalid
# Example: validate_checkpoint ".claude/checkpoints/implement_auth_*.json"
validate_checkpoint() {
  local checkpoint_file="${1:-}"

  if [ -z "$checkpoint_file" ]; then
    echo "Usage: validate_checkpoint <checkpoint-file>" >&2
    return 1
  fi

  if [ ! -f "$checkpoint_file" ]; then
    echo "Checkpoint file not found: $checkpoint_file" >&2
    return 1
  fi

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "Warning: jq not found, skipping validation" >&2
    return 0
  fi

  # Validate JSON structure
  if ! jq empty "$checkpoint_file" 2>/dev/null; then
    echo "Invalid JSON in checkpoint file" >&2
    return 1
  fi

  # Validate required fields
  local required_fields=(
    "checkpoint_id"
    "workflow_type"
    "project_name"
    "created_at"
    "status"
  )

  for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" "$checkpoint_file" >/dev/null 2>&1; then
      echo "Missing required field: $field" >&2
      return 1
    fi
  done

  return 0
}

# migrate_checkpoint_format: Migrate checkpoint to current schema version
# Usage: migrate_checkpoint_format <checkpoint-file>
# Returns: 0 if migrated or already current, 1 on error
# Example: migrate_checkpoint_format ".claude/checkpoints/implement_auth_*.json"
migrate_checkpoint_format() {
  local checkpoint_file="${1:-}"

  if [ -z "$checkpoint_file" ]; then
    echo "Usage: migrate_checkpoint_format <checkpoint-file>" >&2
    return 1
  fi

  if [ ! -f "$checkpoint_file" ]; then
    echo "Checkpoint file not found: $checkpoint_file" >&2
    return 1
  fi

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "Warning: jq not found, skipping migration" >&2
    return 0
  fi

  # Get current schema version from checkpoint
  local current_version
  current_version=$(jq -r '.schema_version // "1.0"' "$checkpoint_file")

  # No migration needed if already at current version
  if [ "$current_version" = "$CHECKPOINT_SCHEMA_VERSION" ]; then
    return 0
  fi

  # Backup original checkpoint
  local backup_file="${checkpoint_file}.backup"
  cp "$checkpoint_file" "$backup_file"

  # Migrate from 1.0 to 1.1 (add replanning fields)
  if [ "$current_version" = "1.0" ]; then
    jq '. + {
      schema_version: "'$CHECKPOINT_SCHEMA_VERSION'",
      replanning_count: (.replanning_count // 0),
      last_replan_reason: (.last_replan_reason // null),
      replan_phase_counts: (.replan_phase_counts // {}),
      replan_history: (.replan_history // [])
    }' "$checkpoint_file" > "${checkpoint_file}.migrated"

    # Replace original with migrated version
    mv "${checkpoint_file}.migrated" "$checkpoint_file"
  fi

  return 0
}

# checkpoint_get_field: Extract field value from checkpoint
# Usage: checkpoint_get_field <checkpoint-file> <field-path>
# Returns: Field value
# Example: checkpoint_get_field "checkpoint.json" ".current_phase"
checkpoint_get_field() {
  local checkpoint_file="${1:-}"
  local field_path="${2:-}"

  if [ -z "$checkpoint_file" ] || [ -z "$field_path" ]; then
    echo "Usage: checkpoint_get_field <checkpoint-file> <field-path>" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "Error: jq required for checkpoint_get_field" >&2
    return 1
  fi

  jq -r "$field_path // empty" "$checkpoint_file"
}

# checkpoint_set_field: Update field value in checkpoint
# Usage: checkpoint_set_field <checkpoint-file> <field-path> <value>
# Returns: 0 on success, 1 on error
# Example: checkpoint_set_field "checkpoint.json" ".current_phase" "3"
checkpoint_set_field() {
  local checkpoint_file="${1:-}"
  local field_path="${2:-}"
  local value="${3:-}"

  if [ -z "$checkpoint_file" ] || [ -z "$field_path" ]; then
    echo "Usage: checkpoint_set_field <checkpoint-file> <field-path> <value>" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "Error: jq required for checkpoint_set_field" >&2
    return 1
  fi

  # Update timestamp
  local updated=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Update field and timestamp
  local temp_file="${checkpoint_file}.tmp"
  jq --arg updated "$updated" \
     --arg value "$value" \
     "$field_path = \$value | .updated_at = \$updated" \
     "$checkpoint_file" > "$temp_file"

  mv "$temp_file" "$checkpoint_file"
}

# ==============================================================================
# Convenience Functions
# ==============================================================================

# checkpoint_increment_replan: Increment replan counters
# Usage: checkpoint_increment_replan <checkpoint-file> <phase-number> <reason>
# Returns: 0 on success
# Example: checkpoint_increment_replan "checkpoint.json" "3" "complexity threshold"
checkpoint_increment_replan() {
  local checkpoint_file="${1:-}"
  local phase_number="${2:-}"
  local reason="${3:-}"

  if [ -z "$checkpoint_file" ] || [ -z "$phase_number" ] || [ -z "$reason" ]; then
    echo "Usage: checkpoint_increment_replan <checkpoint-file> <phase> <reason>" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "Error: jq required for checkpoint_increment_replan" >&2
    return 1
  fi

  local updated=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local temp_file="${checkpoint_file}.tmp"

  # Increment counters and add to history
  jq --arg updated "$updated" \
     --arg phase "$phase_number" \
     --arg reason "$reason" \
     '.replanning_count += 1 |
      .last_replan_reason = $reason |
      .replan_phase_counts["phase_" + $phase] += 1 |
      .replan_history += [{
        phase: ($phase | tonumber),
        timestamp: $updated,
        reason: $reason
      }] |
      .updated_at = $updated' \
     "$checkpoint_file" > "$temp_file"

  mv "$temp_file" "$checkpoint_file"
}

# checkpoint_delete: Delete checkpoint file
# Usage: checkpoint_delete <workflow-type> <project-name>
# Returns: 0 on success
# Example: checkpoint_delete "implement" "auth_system"
checkpoint_delete() {
  local workflow_type="${1:-}"
  local project_name="${2:-}"

  if [ -z "$workflow_type" ] || [ -z "$project_name" ]; then
    echo "Usage: checkpoint_delete <workflow-type> <project-name>" >&2
    return 1
  fi

  local pattern="${workflow_type}_${project_name}_*.json"
  local checkpoint_files=$(ls "$CHECKPOINTS_DIR"/$pattern 2>/dev/null || true)

  if [ -z "$checkpoint_files" ]; then
    echo "No checkpoints found for: $workflow_type/$project_name" >&2
    return 1
  fi

  rm -f $checkpoint_files
  echo "Deleted checkpoints for: $workflow_type/$project_name"
}

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f save_checkpoint
  export -f restore_checkpoint
  export -f validate_checkpoint
  export -f migrate_checkpoint_format
  export -f checkpoint_get_field
  export -f checkpoint_set_field
  export -f checkpoint_increment_replan
  export -f checkpoint_delete
fi
