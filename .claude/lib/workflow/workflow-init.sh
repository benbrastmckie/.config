#!/usr/bin/env bash
# workflow-init.sh - Consolidated initialization library for workflow commands
#
# Version: 1.0.0
# Created: 2025-11-18
#
# This library consolidates common initialization patterns to reduce bash block count
# in workflow commands (research.md, build.md, plan.md, etc.).
#
# Design Goals:
# - Reduce bash blocks from 6-11 to 2-3 per command
# - Suppress verbose output during initialization
# - Single summary line per operation
# - Consistent state persistence pattern across all commands
#
# Usage:
#   source .claude/lib/workflow/workflow-init.sh
#
#   # One-time initialization (Block 1)
#   result=$(init_workflow "command_name" "workflow description" "workflow_type" [complexity])
#
#   # Load workflow context in subsequent blocks
#   load_workflow_context "command_name"
#
# Performance:
# - Combines 4-5 initialization operations into single function call
# - Suppresses library sourcing output (2>/dev/null pattern)
# - Single summary line output per block

# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_INIT_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_INIT_SOURCED=1
export WORKFLOW_INIT_VERSION="1.0.0"

set -uo pipefail

# Debug log location for suppressed output
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"

# ==============================================================================
# Helper Function: Suppress Library Sourcing
# ==============================================================================

# _source_lib: Source a library with output suppression
#
# Args:
#   $1 - library_name: Name of library file (e.g., "state-persistence.sh")
#   $2 - required: "required" if library must exist, "optional" if not
#
# Returns:
#   0 on success, 1 on failure for required libraries
#
_source_lib() {
  local library_name="$1"
  local required="${2:-required}"
  local lib_path="${CLAUDE_PROJECT_DIR}/.claude/lib/${library_name}"

  if [ -f "$lib_path" ]; then
    # Suppress output and errors during sourcing
    source "$lib_path" 2>/dev/null || {
      if [ "$required" = "required" ]; then
        echo "ERROR: Failed to source $library_name" >> "$DEBUG_LOG"
        return 1
      fi
    }
    return 0
  else
    if [ "$required" = "required" ]; then
      echo "ERROR: Required library not found: $lib_path" >> "$DEBUG_LOG"
      return 1
    fi
    return 0
  fi
}

# ==============================================================================
# Core Function: init_workflow
# ==============================================================================

# init_workflow: One-time workflow initialization (consolidates Block 1 operations)
#
# This function combines multiple initialization steps:
# 1. CLAUDE_PROJECT_DIR detection (cached)
# 2. Library sourcing (state-persistence.sh, workflow-state-machine.sh, etc.)
# 3. WORKFLOW_ID generation and state file creation
# 4. State machine initialization via sm_init
# 5. EXIT trap cleanup registration
#
# Args:
#   $1 - command_name: Name of invoking command (e.g., "research", "build", "plan")
#   $2 - workflow_description: User-provided workflow description
#   $3 - workflow_type: Workflow scope (research-only, research-and-plan, full-implementation, etc.)
#   $4 - research_complexity: (Optional) Research complexity 1-4, default 2
#   $5 - research_topics_json: (Optional) JSON array of research topics, default "[]"
#   $6 - user_args: (Optional) Original user command arguments for error logging
#
# Environment Exports:
#   CLAUDE_PROJECT_DIR - Project root directory
#   WORKFLOW_ID - Unique workflow identifier
#   STATE_FILE - Path to workflow state file
#   WORKFLOW_DESCRIPTION - Sanitized workflow description
#   WORKFLOW_TYPE - Workflow scope
#   RESEARCH_COMPLEXITY - Research complexity (1-4)
#   USER_ARGS - Original user command arguments
#
# Returns:
#   0 on success with summary line on stdout
#   1 on failure with error message to stderr
#
# Example:
#   init_workflow "research" "authentication patterns" "research-only" 2 "[]" "auth patterns --complexity 3"
#   # Output: Setup complete: research_1700000000 (research-only, complexity: 2)
#
init_workflow() {
  local command_name="${1:-}"
  local workflow_description="${2:-}"
  local workflow_type="${3:-full-implementation}"
  local research_complexity="${4:-2}"
  local research_topics_json="${5:-[]}"
  local user_args="${6:-}"

  # Validate required arguments
  if [ -z "$command_name" ] || [ -z "$workflow_description" ]; then
    echo "ERROR: init_workflow requires command_name and workflow_description" >&2
    return 1
  fi

  # Ensure debug log directory exists
  mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null || true

  # Log initialization start
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] init_workflow: $command_name - $workflow_description" >> "$DEBUG_LOG"

  # ============================================================================
  # STEP 1: Detect CLAUDE_PROJECT_DIR (cached for performance)
  # ============================================================================

  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
      CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    else
      # Fallback: search upward for .claude/ directory
      local current_dir
      current_dir="$(pwd)"
      while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.claude" ]; then
          CLAUDE_PROJECT_DIR="$current_dir"
          break
        fi
        current_dir="$(dirname "$current_dir")"
      done
    fi
  fi

  if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
    echo "ERROR: Failed to detect project directory (no .claude/ found)" >&2
    echo "[$(date)] FATAL: Project directory detection failed" >> "$DEBUG_LOG"
    return 1
  fi

  export CLAUDE_PROJECT_DIR

  # ============================================================================
  # STEP 2: Source required libraries (with output suppression)
  # ============================================================================

  # Core libraries (required)
  _source_lib "core/state-persistence.sh" "required" || return 1
  _source_lib "workflow/workflow-state-machine.sh" "required" || return 1

  # Support libraries (required for full functionality)
  _source_lib "core/library-version-check.sh" "optional"
  _source_lib "core/error-handling.sh" "optional"
  _source_lib "core/unified-location-detection.sh" "optional"
  _source_lib "workflow/workflow-initialization.sh" "optional"

  # ============================================================================
  # STEP 3: Generate WORKFLOW_ID and initialize state
  # ============================================================================

  # Generate deterministic WORKFLOW_ID
  WORKFLOW_ID="${command_name}_$(date +%s)"

  # Create tmp directory and save state ID file for subprocess recovery
  mkdir -p "${HOME}/.claude/tmp" 2>/dev/null
  local state_id_file="${HOME}/.claude/tmp/${command_name}_state_id.txt"
  echo "$WORKFLOW_ID" > "$state_id_file"

  export WORKFLOW_ID

  # Initialize workflow state BEFORE sm_init (critical order)
  init_workflow_state "$WORKFLOW_ID" >/dev/null

  # ============================================================================
  # STEP 4: Initialize state machine
  # ============================================================================

  # sm_init: description, command_name, workflow_type, complexity, topics_json
  if ! sm_init \
    "$workflow_description" \
    "$command_name" \
    "$workflow_type" \
    "$research_complexity" \
    "$research_topics_json" >/dev/null 2>&1; then
    echo "ERROR: State machine initialization failed" >&2
    echo "[$(date)] FATAL: sm_init failed for $command_name" >> "$DEBUG_LOG"
    return 1
  fi

  # ============================================================================
  # STEP 5: Persist critical variables to state file
  # ============================================================================

  append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
  append_workflow_state "WORKFLOW_DESCRIPTION" "$workflow_description"
  append_workflow_state "WORKFLOW_TYPE" "$workflow_type"
  append_workflow_state "COMMAND_NAME" "$command_name"
  append_workflow_state "USER_ARGS" "$user_args"

  # Export variables for use in calling script
  export WORKFLOW_DESCRIPTION="$workflow_description"
  export WORKFLOW_TYPE="$workflow_type"
  export COMMAND_NAME="$command_name"
  export RESEARCH_COMPLEXITY="$research_complexity"
  export USER_ARGS="$user_args"

  # ============================================================================
  # Single summary line output
  # ============================================================================

  echo "Setup complete: $WORKFLOW_ID ($workflow_type, complexity: $research_complexity)"
  return 0
}

# ==============================================================================
# Core Function: load_workflow_context
# ==============================================================================

# load_workflow_context: Load workflow state in subsequent bash blocks
#
# This function restores workflow context after subprocess isolation:
# 1. Sources required libraries (with suppression)
# 2. Loads WORKFLOW_ID from state ID file
# 3. Loads workflow state via load_workflow_state
#
# Args:
#   $1 - command_name: Name of invoking command (e.g., "research", "build", "plan")
#   $2 - required_vars: (Optional) Space-separated list of required state variables
#
# Environment Exports:
#   All variables from state file are exported
#   WORKFLOW_ID, STATE_FILE, CLAUDE_PROJECT_DIR guaranteed
#
# Returns:
#   0 on success with workflow context loaded
#   1 on failure (state file not found, required vars missing)
#
# Example:
#   load_workflow_context "research"
#   # Now WORKFLOW_ID, RESEARCH_DIR, TOPIC_PATH, etc. are available
#
load_workflow_context() {
  local command_name="${1:-}"

  # Validate required arguments
  if [ -z "$command_name" ]; then
    echo "ERROR: load_workflow_context requires command_name" >&2
    return 1
  fi

  # ============================================================================
  # STEP 1: Detect CLAUDE_PROJECT_DIR (if not already set)
  # ============================================================================

  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
      CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    else
      # Fallback: search upward for .claude/ directory
      local current_dir
      current_dir="$(pwd)"
      while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.claude" ]; then
          CLAUDE_PROJECT_DIR="$current_dir"
          break
        fi
        current_dir="$(dirname "$current_dir")"
      done
    fi
  fi

  if [ -z "$CLAUDE_PROJECT_DIR" ]; then
    echo "ERROR: CLAUDE_PROJECT_DIR not set and could not detect" >&2
    return 1
  fi

  export CLAUDE_PROJECT_DIR

  # ============================================================================
  # STEP 2: Source required libraries (with suppression)
  # ============================================================================

  _source_lib "core/state-persistence.sh" "required" || return 1
  _source_lib "workflow/workflow-state-machine.sh" "required" || return 1

  # ============================================================================
  # STEP 3: Load WORKFLOW_ID from state ID file
  # ============================================================================

  local state_id_file="${HOME}/.claude/tmp/${command_name}_state_id.txt"

  if [ ! -f "$state_id_file" ]; then
    echo "ERROR: WORKFLOW_ID file not found: $state_id_file" >&2
    echo "DIAGNOSTIC: init_workflow may not have executed" >&2
    return 1
  fi

  WORKFLOW_ID=$(cat "$state_id_file")
  export WORKFLOW_ID

  # ============================================================================
  # STEP 4: Load workflow state
  # ============================================================================

  # Load state with fail-fast validation (is_first_block=false)
  if ! load_workflow_state "$WORKFLOW_ID" false; then
    echo "ERROR: Failed to load workflow state for $WORKFLOW_ID" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Utility Function: finalize_workflow
# ==============================================================================

# finalize_workflow: Complete workflow and cleanup
#
# This function handles workflow completion:
# 1. Transitions state machine to complete state
# 2. Persists completed state
# 3. Outputs completion summary
#
# Args:
#   $1 - command_name: Name of invoking command
#   $2 - summary_info: (Optional) Additional summary information
#
# Returns:
#   0 on success
#   1 on failure
#
finalize_workflow() {
  local command_name="${1:-}"
  local summary_info="${2:-}"

  # Ensure state is loaded
  if [ -z "${WORKFLOW_ID:-}" ]; then
    load_workflow_context "$command_name" || return 1
  fi

  # Transition to complete state
  if ! sm_transition "$STATE_COMPLETE" 2>/dev/null; then
    echo "ERROR: State transition to COMPLETE failed" >&2
    return 1
  fi

  # Persist completed state
  save_completed_states_to_state 2>/dev/null || true

  # Output completion summary
  echo "Workflow complete: $WORKFLOW_ID"
  if [ -n "$summary_info" ]; then
    echo "$summary_info"
  fi

  return 0
}

# ==============================================================================
# Utility Function: workflow_error
# ==============================================================================

# workflow_error: Report workflow error with optional debug log reference
#
# Args:
#   $1 - error_message: Error message to display
#   $2 - diagnostic_info: (Optional) Additional diagnostic information
#
# Example:
#   workflow_error "Research phase failed" "Check agent logs"
#
workflow_error() {
  local error_message="${1:-Unknown error}"
  local diagnostic_info="${2:-}"

  echo "ERROR: $error_message" >&2

  if [ -n "$diagnostic_info" ]; then
    echo "DIAGNOSTIC: $diagnostic_info" >&2
  fi

  if [ -f "$DEBUG_LOG" ]; then
    echo "Debug log: $DEBUG_LOG" >&2
  fi

  return 1
}

# ==============================================================================
# Utility Function: get_error_context
# ==============================================================================

# get_error_context: Get current workflow context as JSON for error logging
#
# Returns JSON object with workflow context suitable for log_command_error().
# Uses current environment variables set by init_workflow/load_workflow_context.
#
# Returns:
#   JSON string with workflow context on stdout
#
# Example:
#   context=$(get_error_context)
#   log_command_error "/build" "$WORKFLOW_ID" "$USER_ARGS" "state_error" "msg" "bash_block" "$context"
#
get_error_context() {
  jq -n \
    --arg command_name "${COMMAND_NAME:-unknown}" \
    --arg workflow_id "${WORKFLOW_ID:-unknown}" \
    --arg user_args "${USER_ARGS:-}" \
    --arg current_state "${CURRENT_STATE:-unknown}" \
    --arg workflow_type "${WORKFLOW_TYPE:-unknown}" \
    --arg topic_path "${TOPIC_PATH:-}" \
    --arg state_file "${STATE_FILE:-}" \
    --arg workflow_description "${WORKFLOW_DESCRIPTION:-}" \
    '{
      command_name: $command_name,
      workflow_id: $workflow_id,
      user_args: $user_args,
      current_state: $current_state,
      workflow_type: $workflow_type,
      topic_path: $topic_path,
      state_file: $state_file,
      workflow_description: $workflow_description
    }'
}

# ==============================================================================
# Export Functions
# ==============================================================================

export -f init_workflow
export -f load_workflow_context
export -f finalize_workflow
export -f workflow_error
export -f get_error_context
