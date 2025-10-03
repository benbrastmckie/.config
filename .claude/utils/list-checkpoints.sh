#!/usr/bin/env bash
# List all active checkpoints with details
# Usage: list-checkpoints.sh [workflow-type]

set -euo pipefail

WORKFLOW_TYPE="${1:-}"
CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/checkpoints"

# Ensure checkpoints directory exists
if [ ! -d "$CHECKPOINTS_DIR" ]; then
  echo "No checkpoints found"
  exit 0
fi

# Find checkpoints matching pattern
if [ -n "$WORKFLOW_TYPE" ]; then
  PATTERN="${WORKFLOW_TYPE}_*.json"
else
  PATTERN="*.json"
fi

CHECKPOINTS=$(ls -t "$CHECKPOINTS_DIR"/$PATTERN 2>/dev/null || true)

if [ -z "$CHECKPOINTS" ]; then
  echo "No checkpoints found"
  exit 0
fi

echo "Active Checkpoints:"
echo "=================="
echo ""

# List each checkpoint with details
for checkpoint in $CHECKPOINTS; do
  filename=$(basename "$checkpoint")

  if command -v jq &> /dev/null && jq empty "$checkpoint" 2>/dev/null; then
    # Extract details with jq
    WORKFLOW_TYPE=$(jq -r '.workflow_type // "unknown"' "$checkpoint")
    PROJECT_NAME=$(jq -r '.project_name // "unknown"' "$checkpoint")
    DESCRIPTION=$(jq -r '.workflow_description // ""' "$checkpoint")
    CREATED=$(jq -r '.created_at // ""' "$checkpoint")
    CURRENT_PHASE=$(jq -r '.current_phase // 0' "$checkpoint")
    TOTAL_PHASES=$(jq -r '.total_phases // 0' "$checkpoint")
    STATUS=$(jq -r '.status // "unknown"' "$checkpoint")

    echo "Checkpoint: $filename"
    echo "  Type: $WORKFLOW_TYPE"
    echo "  Project: $PROJECT_NAME"
    if [ -n "$DESCRIPTION" ]; then
      echo "  Description: $DESCRIPTION"
    fi
    echo "  Created: $CREATED"
    echo "  Progress: Phase $CURRENT_PHASE of $TOTAL_PHASES"
    echo "  Status: $STATUS"
    echo ""
  else
    # Fallback: just show filename and basic info
    echo "Checkpoint: $filename"
    echo "  (Details unavailable - jq not installed or corrupted checkpoint)"
    echo ""
  fi
done

echo "To resume a workflow, run the relevant command (e.g., /orchestrate or /implement)"
echo "To delete a checkpoint: rm \"$CHECKPOINTS_DIR/checkpoint_name.json\""
