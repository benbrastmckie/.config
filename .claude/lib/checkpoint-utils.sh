#!/usr/bin/env bash
# Shared checkpoint management utilities
# Provides functions for checkpoint save, load, validate, and migrate
#
# Checkpoint Storage Locations:
# - .claude/checkpoints/ - Primary checkpoint storage (used by this utility)
#   - Workflow checkpoints (implement, orchestrate, etc.)
#   - parallel_ops/ - Temporary parallel operation checkpoints
# - .claude/data/checkpoints/ - Alternative persistent storage (legacy, not currently used)
#   - Kept for backward compatibility
#   - See .claude/data/checkpoints/README.md for historical documentation

set -euo pipefail

# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"
source "$SCRIPT_DIR/timestamp-utils.sh"

# ==============================================================================
# Checkpoint Schema
# ==============================================================================

# Schema version for checkpoint format
readonly CHECKPOINT_SCHEMA_VERSION="2.1"

# Checkpoint directory
readonly CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/checkpoints"

# Wave Tracking Fields (for parallel execution - Phase 2):
# When implementing parallel phase execution, the following fields should be
# included in the workflow_state JSON passed to save_checkpoint():
#
# - current_wave: Current wave number (1-indexed)
# - total_waves: Total number of waves in dependency graph
# - wave_structure: Map of wave number to phase numbers
#   Example: {"1": [1], "2": [2, 3], "3": [4]}
# - parallel_execution_enabled: Boolean flag for --sequential override
# - max_wave_parallelism: Maximum concurrent phases per wave (default: 3)
# - wave_results: Detailed results for each completed/in-progress wave
#   Example: {
#     "1": {"phases": [1], "status": "completed", "duration_ms": 185000},
#     "2": {"phases": [2, 3], "status": "in_progress", "parallel": true}
#   }
#
# These fields enable proper wave state tracking for checkpoint resume
# after wave failures, allowing retry of failed waves while preserving
# completed wave progress.

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
    # Capture plan file modification time if plan_path provided in state
    local plan_mtime=""
    local plan_path=$(echo "$state_json" | jq -r '.plan_path // empty')
    if [ -n "$plan_path" ] && [ -f "$plan_path" ]; then
      plan_mtime=$(stat -c %Y "$plan_path" 2>/dev/null || stat -f %m "$plan_path" 2>/dev/null || echo "")
    fi

    # Use jq for robust JSON handling
    checkpoint_data=$(jq -n \
      --arg version "$CHECKPOINT_SCHEMA_VERSION" \
      --arg id "$checkpoint_id" \
      --arg type "$workflow_type" \
      --arg project "$project_name" \
      --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg plan_mtime "$plan_mtime" \
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
        state_machine: ($state.state_machine // null),
        workflow_state: $state,
        phase_data: ($state.phase_data // {}),
        supervisor_state: ($state.supervisor_state // {}),
        error_state: ($state.error_state // {
          last_error: null,
          retry_count: 0,
          failed_state: null
        }),
        metadata: {
          checkpoint_id: $id,
          project_name: $project,
          created_at: $created,
          updated_at: $created
        },
        last_error: ($state.last_error // null),
        tests_passing: ($state.tests_passing // true),
        plan_modification_time: (if $plan_mtime != "" then ($plan_mtime | tonumber) else null end),
        replanning_count: ($state.replanning_count // 0),
        last_replan_reason: ($state.last_replan_reason // null),
        replan_phase_counts: ($state.replan_phase_counts // {}),
        replan_history: ($state.replan_history // []),
        debug_report_path: ($state.debug_report_path // null),
        user_last_choice: ($state.user_last_choice // null),
        debug_iteration_count: ($state.debug_iteration_count // 0),
        topic_directory: ($state.topic_directory // null),
        topic_number: ($state.topic_number // null),
        context_preservation: ($state.context_preservation // {
          pruning_log: [],
          artifact_metadata_cache: {},
          subagent_output_references: []
        }),
        template_source: ($state.template_source // null),
        template_variables: ($state.template_variables // null),
        spec_maintenance: ($state.spec_maintenance // {
          parent_plan_path: null,
          grandparent_plan_path: null,
          spec_updater_invocations: [],
          checkbox_propagation_log: []
        })
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
# Example: validate_checkpoint ".claude/data/checkpoints/implement_auth_*.json"
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
# Example: migrate_checkpoint_format ".claude/data/checkpoints/implement_auth_*.json"
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
      schema_version: "1.1",
      replanning_count: (.replanning_count // 0),
      last_replan_reason: (.last_replan_reason // null),
      replan_phase_counts: (.replan_phase_counts // {}),
      replan_history: (.replan_history // [])
    }' "$checkpoint_file" > "${checkpoint_file}.migrated"

    # Replace original with migrated version
    mv "${checkpoint_file}.migrated" "$checkpoint_file"
    current_version="1.1"
  fi

  # Migrate from 1.1 to 1.2 (add debug fields)
  if [ "$current_version" = "1.1" ]; then
    jq '. + {
      schema_version: "1.2",
      debug_report_path: (.debug_report_path // null),
      user_last_choice: (.user_last_choice // null),
      debug_iteration_count: (.debug_iteration_count // 0)
    }' "$checkpoint_file" > "${checkpoint_file}.migrated"

    # Replace original with migrated version
    mv "${checkpoint_file}.migrated" "$checkpoint_file"
    current_version="1.2"
  fi

  # Migrate from 1.2 to 1.3 (add topic, context preservation, template, and spec maintenance fields)
  if [ "$current_version" = "1.2" ]; then
    # Extract topic info from workflow_state if available
    local topic_dir=$(jq -r '.workflow_state.topic_directory // null' "$checkpoint_file")
    local topic_num=$(jq -r '.workflow_state.topic_number // null' "$checkpoint_file")

    jq '. + {
      schema_version: "1.3",
      topic_directory: (if .workflow_state.topic_directory then .workflow_state.topic_directory else null end),
      topic_number: (if .workflow_state.topic_number then .workflow_state.topic_number else null end),
      context_preservation: (.context_preservation // {
        pruning_log: [],
        artifact_metadata_cache: {},
        subagent_output_references: []
      }),
      template_source: (if .workflow_state.template_source then .workflow_state.template_source else null end),
      template_variables: (if .workflow_state.template_variables then .workflow_state.template_variables else null end),
      spec_maintenance: (.spec_maintenance // {
        parent_plan_path: null,
        grandparent_plan_path: null,
        spec_updater_invocations: [],
        checkbox_propagation_log: []
      })
    }' "$checkpoint_file" > "${checkpoint_file}.migrated"

    # Replace original with migrated version
    mv "${checkpoint_file}.migrated" "$checkpoint_file"
    current_version="1.3"
  fi

  # Migrate from 1.3 to 2.0 (add state machine as first-class citizen)
  if [ "$current_version" = "1.3" ]; then
    # Source state machine library for phase-to-state mapping
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$script_dir/workflow-state-machine.sh" ]; then
      source "$script_dir/workflow-state-machine.sh"
    fi

    # Extract workflow_type from checkpoint
    local workflow_type=$(jq -r '.workflow_type // "unknown"' "$checkpoint_file")

    # Map current_phase to state name
    local current_phase=$(jq -r '.current_phase // 0' "$checkpoint_file")
    local current_state=$(map_phase_to_state "$current_phase" 2>/dev/null || echo "initialize")

    # Map completed_phases to state names
    local completed_phases_json=$(jq -r '.completed_phases // []' "$checkpoint_file")
    local completed_states_json="[]"
    if [ "$completed_phases_json" != "[]" ]; then
      completed_states_json=$(echo "$completed_phases_json" | jq -r '.[]' | while read phase; do
        if [ -n "$phase" ]; then
          map_phase_to_state "$phase" 2>/dev/null || echo "initialize"
        fi
      done | jq -R . | jq -s .)
    fi

    # Detect workflow scope from workflow_description (default to full-implementation)
    local workflow_scope="full-implementation"
    local workflow_desc=$(jq -r '.workflow_description // ""' "$checkpoint_file")
    if [ -n "$workflow_desc" ]; then
      if echo "$workflow_desc" | grep -Eiq "^research" && ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
        workflow_scope="research-only"
      elif echo "$workflow_desc" | grep -Eiq "(research|analyze).*(to |and |for ).*(plan|planning)"; then
        workflow_scope="research-and-plan"
      elif echo "$workflow_desc" | grep -Eiq "(fix|debug|troubleshoot)"; then
        workflow_scope="debug-only"
      fi
    fi

    # Build state_machine section
    jq --arg current_state "$current_state" \
       --argjson completed_states "$completed_states_json" \
       --arg scope "$workflow_scope" \
       --arg workflow_desc "$workflow_desc" \
       --arg command "$workflow_type" \
       '. + {
         schema_version: "'$CHECKPOINT_SCHEMA_VERSION'",
         state_machine: {
           current_state: $current_state,
           completed_states: $completed_states,
           transition_table: {
             initialize: "research",
             research: "plan,complete",
             plan: "implement,complete",
             implement: "test",
             test: "debug,document",
             debug: "test,complete",
             document: "complete",
             complete: ""
           },
           workflow_config: {
             scope: $scope,
             description: $workflow_desc,
             command: $command
           }
         },
         phase_data: (.phase_data // {}),
         supervisor_state: (.supervisor_state // {}),
         error_state: {
           last_error: (.last_error // null),
           retry_count: 0,
           failed_state: null
         },
         metadata: {
           checkpoint_id: .checkpoint_id,
           project_name: .project_name,
           created_at: .created_at,
           updated_at: .updated_at
         }
       }' "$checkpoint_file" > "${checkpoint_file}.migrated"

    # Replace original with migrated version
    mv "${checkpoint_file}.migrated" "$checkpoint_file"
    current_version="2.0"
  fi

  # Migrate from 2.0 to 2.1 (add classification metadata section)
  # Spec 1763161992 Phase 2.5: LLM Classification Agent Integration
  if [ "$current_version" = "2.0" ]; then
    echo "Migrating checkpoint from v2.0 to v2.1 (adding classification metadata)" >&2

    # Extract existing workflow_config.scope
    local existing_scope=$(jq -r '.state_machine.workflow_config.scope // "full-implementation"' "$checkpoint_file")

    # Apply default classification metadata
    jq --arg scope "$existing_scope" '. + {
      schema_version: "2.1",
      state_machine: (.state_machine + {
        classification: {
          workflow_type: $scope,
          research_complexity: 2,
          research_topics: [],
          confidence: 0.0,
          reasoning: "Migrated from v2.0 (defaults applied, re-classification recommended)",
          classified_at: null
        }
      })
    }' "$checkpoint_file" > "${checkpoint_file}.migrated"

    # Verify migration succeeded
    if [ $? -eq 0 ] && [ -f "${checkpoint_file}.migrated" ]; then
      mv "${checkpoint_file}.migrated" "$checkpoint_file"
      current_version="2.1"
      echo "✓ Migration to v2.1 complete" >&2
    else
      echo "Failed to migrate checkpoint to v2.1" >&2
      # Restore from backup
      if [ -f "$backup_file" ]; then
        mv "$backup_file" "$checkpoint_file"
        echo "Restored checkpoint from backup" >&2
      fi
      return 1
    fi
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

# ==============================================================================
# Parallel Operation Checkpoint Functions (Phase 5)
# ==============================================================================

# save_parallel_operation_checkpoint: Save state before parallel operations
# Usage: save_parallel_operation_checkpoint <plan_path> <operation_type> <operations_json>
# Returns: Path to checkpoint file
# Example: save_parallel_operation_checkpoint "plan.md" "expand" '[{"item_id":"phase_1"}]'
save_parallel_operation_checkpoint() {
  local plan_path="${1:-}"
  local operation_type="${2:-}"
  local operations_json="${3:-}"

  if [[ -z "$plan_path" ]] || [[ -z "$operation_type" ]]; then
    echo "ERROR: save_parallel_operation_checkpoint requires plan_path and operation_type" >&2
    return 1
  fi

  # Extract plan name
  local plan_name
  if [[ -d "$plan_path" ]]; then
    plan_name=$(basename "$plan_path")
  else
    plan_name=$(basename "$plan_path" .md)
  fi

  # Create checkpoint directory for parallel operations
  local checkpoint_dir="${CHECKPOINTS_DIR}/parallel_ops"
  mkdir -p "$checkpoint_dir"

  local timestamp=$(date -u +%Y%m%d_%H%M%S)
  local checkpoint_id="parallel_${operation_type}_${plan_name}_${timestamp}"
  local checkpoint_file="${checkpoint_dir}/${checkpoint_id}.json"

  # Build checkpoint data
  local checkpoint_data
  checkpoint_data=$(jq -n \
    --arg id "$checkpoint_id" \
    --arg type "$operation_type" \
    --arg plan "$plan_path" \
    --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson operations "${operations_json:-[]}" \
    '{
      checkpoint_id: $id,
      operation_type: $type,
      plan_path: $plan,
      created_at: $created,
      operations: $operations,
      status: "pre_execution"
    }')

  echo "$checkpoint_data" > "$checkpoint_file"

  echo "$checkpoint_file"
}

# restore_from_checkpoint: Rollback to pre-operation state
# Usage: restore_from_checkpoint <checkpoint_file>
# Returns: JSON with checkpoint data
# Example: restore_from_checkpoint ".claude/checkpoints/parallel_ops/parallel_expand_*.json"
restore_from_checkpoint() {
  local checkpoint_file="${1:-}"

  if [[ -z "$checkpoint_file" ]]; then
    echo "ERROR: restore_from_checkpoint requires checkpoint_file" >&2
    return 1
  fi

  if [[ ! -f "$checkpoint_file" ]]; then
    echo "ERROR: Checkpoint file not found: $checkpoint_file" >&2
    return 1
  fi

  # Validate JSON
  if ! jq empty "$checkpoint_file" 2>/dev/null; then
    echo "ERROR: Invalid checkpoint JSON: $checkpoint_file" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Restoring from Checkpoint" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  local operation_type plan_path created_at
  operation_type=$(jq -r '.operation_type' "$checkpoint_file")
  plan_path=$(jq -r '.plan_path' "$checkpoint_file")
  created_at=$(jq -r '.created_at' "$checkpoint_file")

  echo "Operation: $operation_type" >&2
  echo "Plan: $plan_path" >&2
  echo "Checkpoint: $created_at" >&2
  echo "" >&2

  # Return checkpoint data
  cat "$checkpoint_file"

  return 0
}

# validate_checkpoint_integrity: Verify checkpoint consistency
# Usage: validate_checkpoint_integrity <checkpoint_file>
# Returns: JSON with validation result {valid: true/false, errors: [...]}
# Example: validate_checkpoint_integrity ".claude/checkpoints/parallel_ops/parallel_expand_*.json"
validate_checkpoint_integrity() {
  local checkpoint_file="${1:-}"

  if [[ -z "$checkpoint_file" ]]; then
    echo '{"valid":false,"errors":["Missing checkpoint_file argument"]}' >&2
    echo '{"valid":false,"errors":["Missing checkpoint_file argument"]}'
    return 1
  fi

  if [[ ! -f "$checkpoint_file" ]]; then
    local error_msg="Checkpoint file not found: $checkpoint_file"
    jq -n --arg error "$error_msg" '{"valid":false,"errors":[$error]}'
    return 1
  fi

  # Validate JSON structure
  if ! jq empty "$checkpoint_file" 2>/dev/null; then
    local error_msg="Checkpoint has invalid JSON"
    jq -n --arg error "$error_msg" '{"valid":false,"errors":[$error]}'
    return 1
  fi

  # Check required fields
  local required_fields=("checkpoint_id" "operation_type" "plan_path" "created_at")
  local missing_fields=()

  for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" "$checkpoint_file" >/dev/null 2>&1; then
      missing_fields+=("$field")
    fi
  done

  if [[ ${#missing_fields[@]} -gt 0 ]]; then
    local errors_json=$(printf '%s\n' "${missing_fields[@]}" | jq -R . | jq -s 'map("Missing required field: " + .)')
    jq -n --argjson errors "$errors_json" '{"valid":false,"errors":$errors}'
    return 1
  fi

  # Check plan path exists (warning only)
  local plan_path
  plan_path=$(jq -r '.plan_path' "$checkpoint_file")

  local warnings=()
  if [[ ! -f "$plan_path" ]] && [[ ! -d "$plan_path" ]]; then
    warnings+=("Plan path no longer exists: $plan_path")
  fi

  # Return success with any warnings
  if [[ ${#warnings[@]} -gt 0 ]]; then
    local warnings_json=$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)
    jq -n --argjson warnings "$warnings_json" '{"valid":true,"warnings":$warnings}'
  else
    echo '{"valid":true}'
  fi

  return 0
}

# ==============================================================================
# Smart Checkpoint Auto-Resume Functions (Phase 1)
# ==============================================================================

# check_safe_resume_conditions: Check if checkpoint can be auto-resumed without user prompt
# Usage: check_safe_resume_conditions <checkpoint-file>
# Returns: 0 if safe to auto-resume, 1 if interactive prompt needed
# Example: check_safe_resume_conditions ".claude/checkpoints/implement_*.json"
check_safe_resume_conditions() {
  local checkpoint_file="${1:-}"

  if [ -z "$checkpoint_file" ]; then
    echo "Usage: check_safe_resume_conditions <checkpoint-file>" >&2
    return 1
  fi

  if [ ! -f "$checkpoint_file" ]; then
    echo "Checkpoint file not found: $checkpoint_file" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "Warning: jq not found, cannot check resume conditions" >&2
    return 1
  fi

  # Extract checkpoint fields
  local tests_passing=$(jq -r 'if .tests_passing == null then "true" else (.tests_passing | tostring) end' "$checkpoint_file")
  local last_error=$(jq -r '.last_error // null' "$checkpoint_file")
  local status=$(jq -r '.status // "unknown"' "$checkpoint_file")
  local created_at=$(jq -r '.created_at // ""' "$checkpoint_file")
  local plan_modification_time=$(jq -r '.plan_modification_time // null' "$checkpoint_file")
  local plan_path=$(jq -r '.workflow_state.plan_path // ""' "$checkpoint_file")

  # Condition 1: Tests must be passing
  if [ "$tests_passing" != "true" ]; then
    return 1
  fi

  # Condition 2: No recent errors
  if [ "$last_error" != "null" ]; then
    return 1
  fi

  # Condition 3: Status must be in_progress
  if [ "$status" != "in_progress" ]; then
    return 1
  fi

  # Condition 4: Checkpoint age must be <= 7 days (within 7 day window)
  if [ -n "$created_at" ]; then
    local checkpoint_timestamp=$(date -d "$created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s 2>/dev/null || echo "0")
    local current_timestamp=$(date +%s)
    local age_seconds=$((current_timestamp - checkpoint_timestamp))
    local seven_days_seconds=$((7 * 24 * 60 * 60))
    # Add 1-hour buffer to handle timing precision and timezone edge cases
    local max_age_seconds=$((seven_days_seconds + 3600))

    if [ "$age_seconds" -gt "$max_age_seconds" ]; then
      return 1
    fi
  fi

  # Condition 5: Plan not modified since checkpoint (if plan_modification_time available)
  if [ "$plan_modification_time" != "null" ] && [ -n "$plan_path" ] && [ -f "$plan_path" ]; then
    local current_plan_mtime=$(stat -c %Y "$plan_path" 2>/dev/null || stat -f %m "$plan_path" 2>/dev/null || echo "0")
    if [ "$current_plan_mtime" != "$plan_modification_time" ]; then
      return 1
    fi
  fi

  # All conditions met - safe to auto-resume
  return 0
}

# get_skip_reason: Get human-readable reason why auto-resume was skipped
# Usage: get_skip_reason <checkpoint-file>
# Returns: String describing why auto-resume was skipped
# Example: get_skip_reason ".claude/checkpoints/implement_*.json"
get_skip_reason() {
  local checkpoint_file="${1:-}"

  if [ -z "$checkpoint_file" ]; then
    echo "Checkpoint file not provided"
    return 0
  fi

  if [ ! -f "$checkpoint_file" ]; then
    echo "Checkpoint file not found"
    return 0
  fi

  if ! command -v jq &> /dev/null; then
    echo "Unable to determine reason (jq not available)"
    return 0
  fi

  # Extract checkpoint fields
  local tests_passing=$(jq -r 'if .tests_passing == null then "true" else (.tests_passing | tostring) end' "$checkpoint_file")
  local last_error=$(jq -r '.last_error // null' "$checkpoint_file")
  local status=$(jq -r '.status // "unknown"' "$checkpoint_file")
  local created_at=$(jq -r '.created_at // ""' "$checkpoint_file")
  local plan_modification_time=$(jq -r '.plan_modification_time // null' "$checkpoint_file")
  local plan_path=$(jq -r '.workflow_state.plan_path // ""' "$checkpoint_file")

  # Check each condition and return first failure reason
  if [ "$tests_passing" != "true" ]; then
    echo "Tests failing in last run"
    return 0
  fi

  if [ "$last_error" != "null" ]; then
    echo "Last run had errors"
    return 0
  fi

  if [ "$status" != "in_progress" ]; then
    echo "Checkpoint status: $status (expected: in_progress)"
    return 0
  fi

  # Check checkpoint age
  if [ -n "$created_at" ]; then
    local checkpoint_timestamp=$(date -d "$created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s 2>/dev/null || echo "0")
    local current_timestamp=$(date +%s)
    local age_seconds=$((current_timestamp - checkpoint_timestamp))
    local seven_days_seconds=$((7 * 24 * 60 * 60))
    # Add 1-hour buffer to match check_safe_resume_conditions logic
    local max_age_seconds=$((seven_days_seconds + 3600))

    if [ "$age_seconds" -gt "$max_age_seconds" ]; then
      local age_days=$((age_seconds / 86400))
      echo "Checkpoint $age_days days old (max: 7 days)"
      return 0
    fi
  fi

  # Check plan modification
  if [ "$plan_modification_time" != "null" ] && [ -n "$plan_path" ] && [ -f "$plan_path" ]; then
    local current_plan_mtime=$(stat -c %Y "$plan_path" 2>/dev/null || stat -f %m "$plan_path" 2>/dev/null || echo "0")
    if [ "$current_plan_mtime" != "$plan_modification_time" ]; then
      echo "Plan file modified since checkpoint"
      return 0
    fi
  fi

  # All conditions passed (shouldn't reach here if used correctly)
  echo "All conditions met"
  return 0
}

# ==============================================================================
# State Machine Checkpoint Functions (v2.0)
# ==============================================================================

# save_state_machine_checkpoint: Save checkpoint with state machine data
# Usage: save_state_machine_checkpoint <workflow-type> <project-name> <state-machine-json>
# Returns: Path to saved checkpoint file
# Example: save_state_machine_checkpoint "coordinate" "auth" '{"current_state":"research",...}'
save_state_machine_checkpoint() {
  local workflow_type="${1:-}"
  local project_name="${2:-}"
  local state_machine_json="${3:-}"

  if [ -z "$workflow_type" ] || [ -z "$project_name" ]; then
    echo "Usage: save_state_machine_checkpoint <workflow-type> <project-name> <state-machine-json>" >&2
    return 1
  fi

  # Read state from stdin if not provided
  if [ -z "$state_machine_json" ]; then
    state_machine_json=$(cat)
  fi

  # Build workflow state with state_machine section
  local workflow_state
  workflow_state=$(jq -n \
    --argjson state_machine "$state_machine_json" \
    '{
      state_machine: $state_machine,
      workflow_description: ($state_machine.workflow_config.description // ""),
      current_phase: 0,
      total_phases: 0,
      completed_phases: [],
      phase_data: {},
      supervisor_state: {},
      error_state: {
        last_error: null,
        retry_count: 0,
        failed_state: null
      }
    }')

  # Call standard save_checkpoint with state machine data
  save_checkpoint "$workflow_type" "$project_name" "$workflow_state"
}

# load_state_machine_checkpoint: Load state machine from checkpoint
# Usage: load_state_machine_checkpoint <workflow-type> [project-name]
# Returns: State machine JSON section
# Example: state_machine=$(load_state_machine_checkpoint "coordinate" "auth")
load_state_machine_checkpoint() {
  local workflow_type="${1:-}"
  local project_name="${2:-}"

  if [ -z "$workflow_type" ]; then
    echo "Usage: load_state_machine_checkpoint <workflow-type> [project-name]" >&2
    return 1
  fi

  # Restore full checkpoint
  local checkpoint_json
  checkpoint_json=$(restore_checkpoint "$workflow_type" "$project_name")

  if [ $? -ne 0 ]; then
    return 1
  fi

  # Extract state_machine section
  if command -v jq &> /dev/null; then
    echo "$checkpoint_json" | jq '.state_machine // null'
  else
    echo "ERROR: jq required for state machine checkpoint loading" >&2
    return 1
  fi
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
  export -f save_parallel_operation_checkpoint
  export -f restore_from_checkpoint
  export -f validate_checkpoint_integrity
  export -f check_safe_resume_conditions
  export -f get_skip_reason
  export -f save_state_machine_checkpoint
  export -f load_state_machine_checkpoint
fi
