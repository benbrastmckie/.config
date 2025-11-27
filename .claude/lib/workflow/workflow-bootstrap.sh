#!/usr/bin/env bash
# workflow-bootstrap.sh - Common initialization for all workflow commands
#
# Provides centralized initialization utilities for .claude/commands/ to eliminate
# duplicated boilerplate across 12 commands (276+ lines of duplication).
#
# Functions:
#   - bootstrap_workflow_env() - Detect project directory and export CLAUDE_PROJECT_DIR
#   - load_tier1_libraries() - Source critical foundation libraries with fail-fast
#
# Usage:
#   source "$CLAUDE_LIB/workflow/workflow-bootstrap.sh" 2>/dev/null || {
#     echo "ERROR: Cannot load workflow-bootstrap library" >&2
#     exit 1
#   }
#   bootstrap_workflow_env || exit 1
#   load_tier1_libraries || exit 1
#
# Source Guard: Prevent multiple sourcing
if [[ -n "${_WORKFLOW_BOOTSTRAP_LOADED:-}" ]]; then
  return 0
fi
_WORKFLOW_BOOTSTRAP_LOADED=1

# bootstrap_workflow_env: Detect project directory and export CLAUDE_PROJECT_DIR
#
# Detection Strategy:
# 1. Try git repository detection (most reliable)
# 2. Fallback to upward directory traversal looking for .claude/
# 3. Fail if no .claude/ directory found
#
# Returns: 0 on success, 1 on failure
# Exports: CLAUDE_PROJECT_DIR (absolute path)
bootstrap_workflow_env() {
  # Try git-based detection first
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    # Fallback to upward directory traversal
    local current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/.claude" ]; then
        CLAUDE_PROJECT_DIR="$current_dir"
        break
      fi
      current_dir="$(dirname "$current_dir")"
    done
  fi

  # Validate detection succeeded
  if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
    echo "ERROR: Failed to detect project directory" >&2
    echo "  Searched upward from: $(pwd)" >&2
    echo "  Looking for: .claude/ directory" >&2
    return 1
  fi

  # Export for use by commands and subprocesses
  export CLAUDE_PROJECT_DIR
  return 0
}

# load_tier1_libraries: Source critical foundation libraries with fail-fast
#
# Tier 1 Libraries (required for all commands):
# - core/state-persistence.sh - State management and suppression
# - workflow/workflow-state-machine.sh - State transitions
# - core/error-handling.sh - Centralized error logging
#
# These libraries MUST be sourced with fail-fast handlers per standards.
#
# Returns: 0 on success, 1 on failure
# Requires: CLAUDE_PROJECT_DIR must be set (call bootstrap_workflow_env first)
load_tier1_libraries() {
  if [ -z "$CLAUDE_PROJECT_DIR" ]; then
    echo "ERROR: CLAUDE_PROJECT_DIR not set - call bootstrap_workflow_env first" >&2
    return 1
  fi

  # Define Tier 1 libraries (order matters: state-persistence first)
  local libs=(
    "core/state-persistence.sh"
    "workflow/workflow-state-machine.sh"
    "core/error-handling.sh"
  )

  # Source each library with fail-fast error handling
  for lib in "${libs[@]}"; do
    local lib_path="${CLAUDE_PROJECT_DIR}/.claude/lib/$lib"

    # Suppress verbose output but preserve error detection
    if ! source "$lib_path" 2>/dev/null; then
      echo "ERROR: Failed to source $lib" >&2
      echo "  Expected path: $lib_path" >&2
      return 1
    fi
  done

  return 0
}

# Export functions for subprocess access
export -f bootstrap_workflow_env
export -f load_tier1_libraries
