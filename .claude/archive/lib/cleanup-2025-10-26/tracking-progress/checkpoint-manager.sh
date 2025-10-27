#!/usr/bin/env bash
# .claude/lib/checkpoint-manager.sh
# Checkpoint management for resumable wave-based implementation
#
# This utility provides:
# 1. Checkpoint creation when context window approaches limit
# 2. Checkpoint restoration for /resume-implement
# 3. Plan file updates with checkpoint markers
# 4. Checkpoint validation and cleanup
#
# Usage:
#  source .claude/lib/checkpoint-manager.sh
#  create_implementation_checkpoint "$topic_path" "$phase_id" "$phase_file" ...
#  restore_checkpoint "$checkpoint_file"

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Checkpoint directory
CHECKPOINT_DIR="${HOME}/.config/.claude/data/checkpoints"

# Context thresholds
CHECKPOINT_THRESHOLD=70  # Create checkpoint at 70% context usage
MAX_CONTEXT_TOKENS=200000

# ============================================================================
# CHECKPOINT CREATION
# ============================================================================

# Create checkpoint for phase execution
# Input: topic_path, phase_id, phase_file, tasks_completed, tasks_total, current_task, current_task_index
# Output: Checkpoint file path
create_implementation_checkpoint() {
  local topic_path="$1"
  local phase_id="$2"
  local phase_file="$3"
  local tasks_completed="$4"
  local tasks_total="$5"
  local current_task="$6"
  local current_task_index="${7:-0}"

  # Create checkpoint directory if needed
  mkdir -p "$CHECKPOINT_DIR"

  # Generate checkpoint ID
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local topic_num
  topic_num=$(basename "$topic_path" | sed -E 's/([0-9]{3}).*/\1/')
  local checkpoint_id="${topic_num}_${phase_id}_${timestamp}"
  local checkpoint_file="$CHECKPOINT_DIR/${checkpoint_id}.json"

  # Extract remaining tasks from phase file
  local remaining_tasks
  remaining_tasks=$(extract_remaining_tasks "$phase_file" "$current_task_index")

  # Get plan path (parent of phase file or phase file itself)
  local plan_path
  if [[ "$phase_file" == */phase_*.md ]]; then
    # Level 1: Phase file, find main plan
    plan_path=$(find "$(dirname "$(dirname "$phase_file")")" -maxdepth 1 -name "*.md" | head -1)
  else
    # Level 0: Inline plan
    plan_path="$phase_file"
  fi

  # Calculate context usage (estimated)
  local context_tokens=${CONTEXT_TOKENS:-0}
  local context_percent=$((context_tokens * 100 / MAX_CONTEXT_TOKENS))

  # Create checkpoint JSON
  cat > "$checkpoint_file" <<EOF
{
  "checkpoint_id": "$checkpoint_id",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "plan_path": "$plan_path",
  "topic_path": "$topic_path",
  "phase_id": "$phase_id",
  "phase_file": "$phase_file",
  "progress": {
    "tasks_total": $tasks_total,
    "tasks_completed": $tasks_completed,
    "current_task_index": $current_task_index,
    "current_task": "$current_task",
    "tasks_remaining": $remaining_tasks
  },
  "plan_state": {
    "completed_tasks": $(extract_completed_tasks "$phase_file")
  },
  "context_usage": {
    "tokens_used": $context_tokens,
    "max_tokens": $MAX_CONTEXT_TOKENS,
    "percentage": $context_percent
  },
  "version": "1.0"
}
EOF

  echo "$checkpoint_file"
}

# Extract remaining tasks from phase file
# Input: phase_file, current_task_index
# Output: JSON array of remaining task strings
extract_remaining_tasks() {
  local phase_file="$1"
  local current_index="${2:-0}"

  if [[ ! -f "$phase_file" ]]; then
    echo "[]"
    return 0
  fi

  # Extract all uncompleted tasks
  local remaining_tasks
  remaining_tasks=$(grep -E '^\s*-\s*\[\s*\]' "$phase_file" | tail -n +$((current_index + 1)) || true)

  if [[ -z "$remaining_tasks" ]]; then
    echo "[]"
    return 0
  fi

  # Convert to JSON array
  echo "$remaining_tasks" | jq -R -s -c 'split("\n") | map(select(length > 0))'
}

# Extract completed tasks from phase file
# Input: phase_file
# Output: JSON array of completed task strings
extract_completed_tasks() {
  local phase_file="$1"

  if [[ ! -f "$phase_file" ]]; then
    echo "[]"
    return 0
  fi

  # Extract all completed tasks
  local completed_tasks
  completed_tasks=$(grep -E '^\s*-\s*\[x\]' "$phase_file" || true)

  if [[ -z "$completed_tasks" ]]; then
    echo "[]"
    return 0
  fi

  # Convert to JSON array
  echo "$completed_tasks" | jq -R -s -c 'split("\n") | map(select(length > 0))'
}

# ============================================================================
# PLAN FILE UPDATES
# ============================================================================

# Update plan file with checkpoint marker
# Input: phase_file, checkpoint_file, tasks_completed, tasks_total
update_plan_with_checkpoint() {
  local phase_file="$1"
  local checkpoint_file="$2"
  local tasks_completed="$3"
  local tasks_total="$4"

  if [[ ! -f "$phase_file" ]]; then
    >&2 echo "ERROR: Phase file not found: $phase_file"
    return 1
  fi

  # Calculate progress percentage
  local progress_percent=$((tasks_completed * 100 / tasks_total))

  # Create checkpoint marker section
  local checkpoint_marker
  read -r -d '' checkpoint_marker <<EOF || true

---

## Checkpoint Status

**Status**: Paused (Checkpoint Created)
**Progress**: $tasks_completed/$tasks_total tasks complete ($progress_percent%)
**Checkpoint**: \`$checkpoint_file\`
**Resume Command**: \`/resume-implement $checkpoint_file\`
**Created**: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)

To resume implementation:
\`\`\`bash
/resume-implement $checkpoint_file
\`\`\`

---
EOF

  # Check if checkpoint marker already exists
  if grep -q "## Checkpoint Status" "$phase_file"; then
    # Update existing marker
    # Remove old checkpoint section
    sed -i '/^## Checkpoint Status$/,/^---$/d' "$phase_file"
  fi

  # Add checkpoint marker at end of file
  echo "$checkpoint_marker" >> "$phase_file"

  echo "Updated plan file with checkpoint marker: $phase_file"
}

# Update parent plans with checkpoint reference
# Input: phase_file, checkpoint_file
update_parent_plans_with_checkpoint() {
  local phase_file="$1"
  local checkpoint_file="$2"

  # Determine if this is a stage file (Level 2) or phase file (Level 1)
  if [[ "$phase_file" == */stage_*.md ]]; then
    # Level 2: Stage file, update phase file
    local phase_dir
    phase_dir=$(dirname "$phase_file")
    local parent_phase_file
    parent_phase_file=$(find "$phase_dir/.." -maxdepth 1 -name "phase_*.md" | head -1)

    if [[ -f "$parent_phase_file" ]]; then
      update_plan_with_checkpoint "$parent_phase_file" "$checkpoint_file" 0 1
    fi
  fi

  # Always update Level 0 main plan if it exists
  local main_plan
  if [[ "$phase_file" == */phase_*.md ]]; then
    main_plan=$(find "$(dirname "$(dirname "$phase_file")")" -maxdepth 1 -name "*.md" -not -name "phase_*.md" | head -1)
  else
    # Already at main plan level
    return 0
  fi

  if [[ -f "$main_plan" ]]; then
    # Add checkpoint note to main plan
    local checkpoint_note
    checkpoint_note="<!-- Checkpoint created: $(basename "$checkpoint_file") -->"

    if ! grep -q "Checkpoint created:" "$main_plan"; then
      echo "" >> "$main_plan"
      echo "$checkpoint_note" >> "$main_plan"
    fi
  fi
}

# ============================================================================
# CHECKPOINT RESTORATION
# ============================================================================

# Restore from checkpoint
# Input: checkpoint_file
# Output: Checkpoint data JSON
restore_checkpoint() {
  local checkpoint_file="$1"

  if [[ ! -f "$checkpoint_file" ]]; then
    >&2 echo "ERROR: Checkpoint file not found: $checkpoint_file"
    return 1
  fi

  # Validate checkpoint format
  if ! validate_checkpoint "$checkpoint_file"; then
    >&2 echo "ERROR: Invalid checkpoint format"
    return 1
  fi

  # Read checkpoint data
  local checkpoint_data
  checkpoint_data=$(cat "$checkpoint_file")

  # Extract key information
  local phase_id
  phase_id=$(echo "$checkpoint_data" | jq -r '.phase_id')
  local tasks_completed
  tasks_completed=$(echo "$checkpoint_data" | jq -r '.progress.tasks_completed')
  local tasks_total
  tasks_total=$(echo "$checkpoint_data" | jq -r '.progress.tasks_total')
  local remaining_count
  remaining_count=$(echo "$checkpoint_data" | jq '.progress.tasks_remaining | length')

  # Display restoration info
  echo "═══════════════════════════════════════════════════════════"
  echo "RESTORING FROM CHECKPOINT"
  echo "═══════════════════════════════════════════════════════════"
  echo "Checkpoint ID: $(basename "$checkpoint_file" .json)"
  echo "Phase: $phase_id"
  echo "Progress: $tasks_completed/$tasks_total tasks completed"
  echo "Remaining: $remaining_count tasks"
  echo "Created: $(echo "$checkpoint_data" | jq -r '.created_at')"
  echo "═══════════════════════════════════════════════════════════"

  # Return checkpoint data for executor
  echo "$checkpoint_data"
}

# Validate checkpoint format
# Input: checkpoint_file
# Output: 0 if valid, 1 if invalid
validate_checkpoint() {
  local checkpoint_file="$1"

  if [[ ! -f "$checkpoint_file" ]]; then
    return 1
  fi

  # Check if valid JSON
  if ! jq empty "$checkpoint_file" 2>/dev/null; then
    >&2 echo "ERROR: Checkpoint is not valid JSON"
    return 1
  fi

  # Check required fields
  local required_fields=(
    ".checkpoint_id"
    ".phase_id"
    ".phase_file"
    ".progress.tasks_completed"
    ".progress.tasks_total"
  )

  for field in "${required_fields[@]}"; do
    if ! echo "{}" | jq -e "$field" "$checkpoint_file" >/dev/null 2>&1; then
      >&2 echo "ERROR: Missing required field: $field"
      return 1
    fi
  done

  return 0
}

# ============================================================================
# CHECKPOINT MANAGEMENT
# ============================================================================

# List all checkpoints
# Input: topic_path (optional, filters by topic)
# Output: List of checkpoint files
list_checkpoints() {
  local topic_path="${1:-}"

  if [[ ! -d "$CHECKPOINT_DIR" ]]; then
    echo "No checkpoints found"
    return 0
  fi

  local checkpoints
  if [[ -n "$topic_path" ]]; then
    local topic_num
    topic_num=$(basename "$topic_path" | sed -E 's/([0-9]{3}).*/\1/')
    checkpoints=$(find "$CHECKPOINT_DIR" -name "${topic_num}_*.json" 2>/dev/null || true)
  else
    checkpoints=$(find "$CHECKPOINT_DIR" -name "*.json" 2>/dev/null || true)
  fi

  if [[ -z "$checkpoints" ]]; then
    echo "No checkpoints found"
    return 0
  fi

  echo "Available Checkpoints:"
  echo "═══════════════════════════════════════════════════════════"

  while IFS= read -r checkpoint; do
    local checkpoint_data
    checkpoint_data=$(cat "$checkpoint" 2>/dev/null || echo "{}")

    local checkpoint_id
    checkpoint_id=$(echo "$checkpoint_data" | jq -r '.checkpoint_id // "N/A"')
    local phase_id
    phase_id=$(echo "$checkpoint_data" | jq -r '.phase_id // "N/A"')
    local created_at
    created_at=$(echo "$checkpoint_data" | jq -r '.created_at // "N/A"')
    local tasks_completed
    tasks_completed=$(echo "$checkpoint_data" | jq -r '.progress.tasks_completed // 0')
    local tasks_total
    tasks_total=$(echo "$checkpoint_data" | jq -r '.progress.tasks_total // 0')

    echo "- ID: $checkpoint_id"
    echo "  Phase: $phase_id"
    echo "  Progress: $tasks_completed/$tasks_total tasks"
    echo "  Created: $created_at"
    echo "  File: $checkpoint"
    echo ""
  done <<< "$checkpoints"
}

# Clean up checkpoint after successful resume
# Input: checkpoint_file
cleanup_checkpoint() {
  local checkpoint_file="$1"

  if [[ -f "$checkpoint_file" ]]; then
    # Move to archive instead of deleting
    local archive_dir="$CHECKPOINT_DIR/archive"
    mkdir -p "$archive_dir"

    local checkpoint_name
    checkpoint_name=$(basename "$checkpoint_file")
    mv "$checkpoint_file" "$archive_dir/$checkpoint_name"

    echo "Checkpoint archived: $archive_dir/$checkpoint_name"
  fi
}

# Clean up old checkpoints (older than N days)
# Input: days (default: 30)
cleanup_old_checkpoints() {
  local days="${1:-30}"

  if [[ ! -d "$CHECKPOINT_DIR" ]]; then
    return 0
  fi

  echo "Cleaning up checkpoints older than $days days..."

  local count=0
  while IFS= read -r checkpoint; do
    rm -f "$checkpoint"
    ((count++))
  done < <(find "$CHECKPOINT_DIR" -name "*.json" -mtime +$days 2>/dev/null || true)

  echo "Removed $count old checkpoint(s)"
}

# ============================================================================
# CONTEXT MONITORING
# ============================================================================

# Check if checkpoint is needed based on context usage
# Input: current_tokens
# Output: 0 if checkpoint needed, 1 otherwise
should_create_checkpoint() {
  local current_tokens="${1:-0}"

  local usage_percent=$((current_tokens * 100 / MAX_CONTEXT_TOKENS))

  if [[ $usage_percent -ge $CHECKPOINT_THRESHOLD ]]; then
    return 0  # Should checkpoint
  else
    return 1  # No checkpoint needed
  fi
}

# Estimate current context usage (placeholder)
# Output: Estimated token count
estimate_context_usage() {
  # This is a placeholder - actual implementation would track real token usage
  # For now, return 0 or use environment variable if set
  echo "${CONTEXT_TOKENS:-0}"
}

# ============================================================================
# MAIN ENTRY POINT (for testing)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Test mode
  case "${1:-help}" in
    create)
      shift
      if [[ $# -lt 6 ]]; then
        echo "Usage: $0 create <topic_path> <phase_id> <phase_file> <tasks_completed> <tasks_total> <current_task>"
        exit 1
      fi
      create_implementation_checkpoint "$@"
      ;;
    restore)
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 restore <checkpoint_file>"
        exit 1
      fi
      restore_checkpoint "$2"
      ;;
    list)
      list_checkpoints "${2:-}"
      ;;
    cleanup)
      cleanup_old_checkpoints "${2:-30}"
      ;;
    validate)
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 validate <checkpoint_file>"
        exit 1
      fi
      if validate_checkpoint "$2"; then
        echo "✓ Checkpoint is valid"
      else
        echo "✗ Checkpoint is invalid"
        exit 1
      fi
      ;;
    *)
      echo "Checkpoint Manager for Wave-Based Implementation"
      echo ""
      echo "Usage: $0 <command> [options]"
      echo ""
      echo "Commands:"
      echo "  create <topic_path> <phase_id> <phase_file> <tasks_completed> <tasks_total> <current_task>"
      echo "      Create a new checkpoint"
      echo ""
      echo "  restore <checkpoint_file>"
      echo "      Restore from a checkpoint"
      echo ""
      echo "  list [topic_path]"
      echo "      List all checkpoints (optionally filtered by topic)"
      echo ""
      echo "  validate <checkpoint_file>"
      echo "      Validate checkpoint format"
      echo ""
      echo "  cleanup [days]"
      echo "      Remove checkpoints older than N days (default: 30)"
      echo ""
      echo "Or source this file to use the functions in your scripts"
      ;;
  esac
fi
