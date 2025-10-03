#!/usr/bin/env bash
# Load most recent checkpoint for workflow type
# Usage: load-checkpoint.sh <workflow-type> [project-name]

set -euo pipefail

WORKFLOW_TYPE="${1:-}"
PROJECT_NAME="${2:-}"

if [ -z "$WORKFLOW_TYPE" ]; then
  echo "Usage: load-checkpoint.sh <workflow-type> [project-name]" >&2
  echo "Example: load-checkpoint.sh orchestrate [auth_system]" >&2
  exit 1
fi

CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/checkpoints"

# Ensure checkpoints directory exists
if [ ! -d "$CHECKPOINTS_DIR" ]; then
  echo "No checkpoints directory found" >&2
  exit 1
fi

# Find most recent checkpoint matching workflow type and optional project name
if [ -n "$PROJECT_NAME" ]; then
  PATTERN="${WORKFLOW_TYPE}_${PROJECT_NAME}_*.json"
else
  PATTERN="${WORKFLOW_TYPE}_*.json"
fi

# Find most recent checkpoint (sort by filename which includes timestamp)
CHECKPOINT_FILE=$(ls -t "$CHECKPOINTS_DIR"/$PATTERN 2>/dev/null | head -1 || true)

if [ -z "$CHECKPOINT_FILE" ]; then
  echo "No checkpoint found for workflow type: $WORKFLOW_TYPE" >&2
  exit 1
fi

# Validate checkpoint file exists and is readable
if [ ! -f "$CHECKPOINT_FILE" ] || [ ! -r "$CHECKPOINT_FILE" ]; then
  echo "Checkpoint file not readable: $CHECKPOINT_FILE" >&2
  exit 1
fi

# Validate JSON if jq available
if command -v jq &> /dev/null; then
  if ! jq empty "$CHECKPOINT_FILE" 2>/dev/null; then
    echo "Corrupted checkpoint (invalid JSON): $CHECKPOINT_FILE" >&2
    echo "Delete with: rm \"$CHECKPOINT_FILE\"" >&2
    exit 1
  fi
fi

# Output checkpoint contents
cat "$CHECKPOINT_FILE"
