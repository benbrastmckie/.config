#!/usr/bin/env bash
# source-libraries.sh - Standardized library sourcing for bash blocks
# Version: 1.0.0

# Source guard: Prevent multiple sourcing
if [ -n "${SOURCE_LIBRARIES_SOURCED:-}" ]; then
  return 0
fi
export SOURCE_LIBRARIES_SOURCED=1

# Block-specific library sourcing profiles
# Ensures all required libraries loaded per block type
source_libraries_for_block() {
  local block_type="$1"  # init, state, agent, verify
  local claude_dir="${CLAUDE_PROJECT_DIR:-.}"

  case "$block_type" in
    init)
      # Block 1a: Initial setup and state creation
      source "${claude_dir}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/library-version-check.sh" 2>/dev/null || return 1
      ;;

    state)
      # Block 1c: State loading and path initialization
      source "${claude_dir}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || return 1
      ;;

    verify)
      # Block 2/3: Verification and completion
      source "${claude_dir}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || return 1
      ;;

    *)
      echo "ERROR: Unknown block type: $block_type" >&2
      echo "Valid types: init, state, verify" >&2
      return 1
      ;;
  esac

  return 0
}

# Validate required functions are available after sourcing
validate_sourced_functions() {
  local block_type="$1"
  local missing_functions=()

  case "$block_type" in
    init)
      local required=("log_command_error" "init_workflow_state" "append_workflow_state" "initialize_state_machine")
      ;;
    state)
      local required=("log_command_error" "load_workflow_state" "append_workflow_state" "initialize_workflow_paths")
      ;;
    verify)
      local required=("log_command_error" "load_workflow_state" "transition_state")
      ;;
    *)
      return 1
      ;;
  esac

  for func in "${required[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      missing_functions+=("$func")
    fi
  done

  if [ ${#missing_functions[@]} -gt 0 ]; then
    echo "ERROR: Required functions not available after sourcing: ${missing_functions[*]}" >&2
    return 1
  fi

  return 0
}
