#!/usr/bin/env bash
# source-libraries-inline.sh - Three-tier library sourcing for Claude Code context
# Version: 1.0.0
#
# Provides standardized library sourcing that works in Claude Code's subprocess
# isolation model (each bash block runs in a new process). This utility must be
# sourced at the beginning of EVERY bash block.
#
# Usage:
#   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries-inline.sh" || exit 1
#   source_critical_libraries || exit 1
#   source_workflow_libraries  # Optional, graceful degradation
#
# Three-Tier Pattern:
#   Tier 1 (Critical Foundation): fail-fast required - state-persistence, workflow-state-machine, error-handling
#   Tier 2 (Workflow Support): graceful degradation - workflow-initialization, checkpoint-utils, etc.
#   Tier 3 (Command-Specific): optional - checkbox-utils, summary-formatting, etc.

# Source guard to prevent function redefinition warnings
if [ -n "${SOURCE_LIBRARIES_INLINE_SOURCED:-}" ]; then
  return 0 2>/dev/null || true
fi

# Detect CLAUDE_PROJECT_DIR if not already set
detect_claude_project_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}/.claude" ]; then
    return 0
  fi

  # Method 1: Git-based detection
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    if [ -d "${CLAUDE_PROJECT_DIR}/.claude" ]; then
      export CLAUDE_PROJECT_DIR
      return 0
    fi
  fi

  # Method 2: Directory walk
  local current_dir
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      export CLAUDE_PROJECT_DIR
      return 0
    fi
    current_dir="$(dirname "$current_dir")"
  done

  echo "ERROR: Cannot detect CLAUDE_PROJECT_DIR - no .claude directory found" >&2
  return 1
}

# Tier 1: Critical Foundation Libraries (fail-fast required)
# These libraries are essential for workflow state management and error logging
source_critical_libraries() {
  detect_claude_project_dir || return 1

  local lib_dir="${CLAUDE_PROJECT_DIR}/.claude/lib"

  # state-persistence.sh - State file management
  source "${lib_dir}/core/state-persistence.sh" 2>/dev/null || {
    echo "ERROR: Failed to source state-persistence.sh" >&2
    return 1
  }

  # workflow-state-machine.sh - State transitions and persistence
  source "${lib_dir}/workflow/workflow-state-machine.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-state-machine.sh" >&2
    return 1
  }

  # error-handling.sh - Error logging and trap management
  source "${lib_dir}/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Failed to source error-handling.sh" >&2
    return 1
  }

  # Verify critical functions are available
  if ! type append_workflow_state &>/dev/null; then
    echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
    # Log to centralized error log if log_command_error is available (error-handling.sh sourced)
    if type log_command_error &>/dev/null; then
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "dependency_error" \
        "append_workflow_state function not available after sourcing state-persistence.sh" \
        "source_critical_libraries" \
        '{"function": "append_workflow_state", "library": "state-persistence.sh"}'
    fi
    return 1
  fi

  if ! type save_completed_states_to_state &>/dev/null; then
    echo "ERROR: save_completed_states_to_state function not available after sourcing workflow-state-machine.sh" >&2
    # Log to centralized error log if log_command_error is available (error-handling.sh sourced)
    if type log_command_error &>/dev/null; then
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "dependency_error" \
        "save_completed_states_to_state function not available after sourcing workflow-state-machine.sh" \
        "source_critical_libraries" \
        '{"function": "save_completed_states_to_state", "library": "workflow-state-machine.sh"}'
    fi
    return 1
  fi

  return 0
}

# Tier 2: Workflow Support Libraries (graceful degradation)
# These libraries provide additional workflow features but aren't essential
source_workflow_libraries() {
  local lib_dir="${CLAUDE_PROJECT_DIR}/.claude/lib"

  source "${lib_dir}/workflow/workflow-initialization.sh" 2>/dev/null || true
  source "${lib_dir}/workflow/checkpoint-utils.sh" 2>/dev/null || true
  source "${lib_dir}/core/unified-location-detection.sh" 2>/dev/null || true
  source "${lib_dir}/core/unified-logger.sh" 2>/dev/null || true

  return 0
}

# Tier 3: Command-Specific Libraries (optional, caller provides list)
# Usage: source_command_libraries "plan/checkbox-utils.sh" "core/summary-formatting.sh"
source_command_libraries() {
  local lib_dir="${CLAUDE_PROJECT_DIR}/.claude/lib"

  for lib_path in "$@"; do
    source "${lib_dir}/${lib_path}" 2>/dev/null || true
  done

  return 0
}

# Combined sourcing function for common use case
# Sources Tier 1 with fail-fast, Tier 2 with graceful degradation
source_all_standard_libraries() {
  source_critical_libraries || return 1
  source_workflow_libraries
  return 0
}

# Mark as sourced
SOURCE_LIBRARIES_INLINE_SOURCED=1
export SOURCE_LIBRARIES_INLINE_SOURCED
