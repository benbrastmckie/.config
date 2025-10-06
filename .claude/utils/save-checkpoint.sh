#!/usr/bin/env bash
# Save workflow checkpoint for resume capability
# Usage: save-checkpoint.sh <workflow-type> <project-name> <state-json>

set -euo pipefail

WORKFLOW_TYPE="${1:-}"
PROJECT_NAME="${2:-}"
STATE_JSON="${3:-}"

if [ -z "$WORKFLOW_TYPE" ] || [ -z "$PROJECT_NAME" ]; then
  echo "Usage: save-checkpoint.sh <workflow-type> <project-name> <state-json>" >&2
  echo "Example: save-checkpoint.sh orchestrate auth_system '{\"phase\":2}'" >&2
  exit 1
fi

# Read state from stdin if not provided as argument
if [ -z "$STATE_JSON" ]; then
  STATE_JSON=$(cat)
fi

CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/checkpoints"
TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)
CHECKPOINT_ID="${WORKFLOW_TYPE}_${PROJECT_NAME}_${TIMESTAMP}"
CHECKPOINT_FILE="${CHECKPOINTS_DIR}/${CHECKPOINT_ID}.json"
TEMP_FILE="${CHECKPOINT_FILE}.tmp"

# Ensure checkpoints directory exists
mkdir -p "$CHECKPOINTS_DIR"

# Parse existing state or create new
if command -v jq &> /dev/null; then
  # Use jq for robust JSON handling
  CHECKPOINT_DATA=$(jq -n \
    --arg id "$CHECKPOINT_ID" \
    --arg type "$WORKFLOW_TYPE" \
    --arg project "$PROJECT_NAME" \
    --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson state "$STATE_JSON" \
    '{
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
  CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  CHECKPOINT_DATA=$(cat <<EOF
{
  "checkpoint_id": "$CHECKPOINT_ID",
  "workflow_type": "$WORKFLOW_TYPE",
  "project_name": "$PROJECT_NAME",
  "workflow_description": "",
  "created_at": "$CREATED",
  "updated_at": "$CREATED",
  "status": "in_progress",
  "current_phase": 0,
  "total_phases": 0,
  "completed_phases": [],
  "workflow_state": $STATE_JSON,
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
echo "$CHECKPOINT_DATA" > "$TEMP_FILE"
mv "$TEMP_FILE" "$CHECKPOINT_FILE"

# Output checkpoint path for caller
echo "$CHECKPOINT_FILE"
