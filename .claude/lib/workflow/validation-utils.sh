#!/usr/bin/env bash
# Validation Utilities Library
# Provides reusable validation functions for command development
#
# Version: 1.0.0
# Last Modified: 2025-12-01
#
# This library implements common validation patterns to reduce duplication across commands:
# - Workflow prerequisites validation (required functions availability)
# - Agent artifact validation (file existence and minimum size)
# - Absolute path validation (path format and existence)
#
# Dependencies:
# - error-handling.sh: log_command_error() for error logging integration

# Source guard: Prevent multiple sourcing
if [ -n "${VALIDATION_UTILS_SOURCED:-}" ]; then
  return 0
fi
export VALIDATION_UTILS_SOURCED=1
export VALIDATION_UTILS_VERSION="1.0.0"

set -euo pipefail

# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/detect-project-dir.sh"

# Source error handling library for error logging integration
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  return 1
}

# ==============================================================================
# Workflow Prerequisites Validation
# ==============================================================================

# validate_workflow_prerequisites: Check for required workflow management functions
#
# Validates that critical workflow management functions are available in the current
# bash context. This prevents runtime failures when commands attempt to use
# workflow functions without proper library sourcing.
#
# Usage:
#   validate_workflow_prerequisites || exit 1
#
# Checks for:
#   - sm_init (state machine initialization)
#   - sm_transition (state transitions)
#   - append_workflow_state (state persistence)
#   - load_workflow_state (state loading)
#   - save_completed_states_to_state (state array persistence)
#
# Returns:
#   0 on success (all required functions available)
#   1 on failure (one or more functions missing)
#
# Logs:
#   validation_error to centralized error log on failure
validate_workflow_prerequisites() {
  local required_functions=(
    "sm_init"
    "sm_transition"
    "append_workflow_state"
    "load_workflow_state"
    "save_completed_states_to_state"
  )

  local missing_functions=()

  for func in "${required_functions[@]}"; do
    if ! declare -F "$func" >/dev/null 2>&1; then
      missing_functions+=("$func")
    fi
  done

  if [ ${#missing_functions[@]} -gt 0 ]; then
    local missing_list
    missing_list=$(printf "%s, " "${missing_functions[@]}")
    missing_list="${missing_list%, }"  # Remove trailing comma

    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "validation_error" \
          "Missing required workflow functions: $missing_list" \
          "validate_workflow_prerequisites" \
          "$(jq -n --arg funcs "$missing_list" '{missing_functions: $funcs}')"
      fi
    fi

    echo "ERROR: Missing required workflow functions: $missing_list" >&2
    echo "Ensure workflow-state-machine.sh and state-persistence.sh are sourced" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Agent Artifact Validation
# ==============================================================================

# validate_agent_artifact: Validate agent-produced artifact files with retry
#
# Checks that an agent-produced artifact exists and meets minimum size requirements.
# Includes retry logic with polling to handle agent completion timing.
# This prevents silent failures when agents fail to produce expected output files.
#
# Usage:
#   validate_agent_artifact "$REPORT_PATH" 100 "research report" || exit 1
#   validate_agent_artifact "$PLAN_PATH" 500 "implementation plan" || exit 1
#
# Parameters:
#   $1 - artifact_path: Absolute path to artifact file
#   $2 - min_size_bytes: Minimum expected file size in bytes (default: 10)
#   $3 - artifact_type: Human-readable artifact description (default: "artifact")
#   $4 - max_attempts: Maximum polling attempts (default: 10)
#
# Returns:
#   0 on success (file exists and meets size requirement)
#   1 on failure (file missing or too small after retries)
#
# Logs:
#   agent_error to centralized error log on failure
validate_agent_artifact() {
  local artifact_path="${1:-}"
  local min_size_bytes="${2:-10}"
  local artifact_type="${3:-artifact}"
  local max_attempts="${4:-10}"

  # Validate parameters
  if [ -z "$artifact_path" ]; then
    echo "ERROR: artifact_path parameter required" >&2
    return 1
  fi

  # Polling retry logic for agent artifact creation
  local attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if [ -f "$artifact_path" ]; then
      # File exists, break out of polling loop
      break
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  # Check file existence after polling
  if [ ! -f "$artifact_path" ]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "agent_error" \
          "Agent failed to create $artifact_type after ${max_attempts}s" \
          "validate_agent_artifact" \
          "$(jq -n --arg path "$artifact_path" --arg type "$artifact_type" \
            --argjson attempts "$max_attempts" \
            '{artifact_path: $path, artifact_type: $type, max_attempts: $attempts, error: "file_not_found"}')"
      fi
    fi

    echo "ERROR: Agent artifact not found after ${max_attempts}s: $artifact_path" >&2
    echo "Expected $artifact_type at this location" >&2
    return 1
  fi

  # Check file size
  local actual_size
  actual_size=$(stat -f%z "$artifact_path" 2>/dev/null || stat -c%s "$artifact_path" 2>/dev/null || echo 0)

  if [ "$actual_size" -lt "$min_size_bytes" ]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "agent_error" \
          "Agent produced undersized $artifact_type" \
          "validate_agent_artifact" \
          "$(jq -n --arg path "$artifact_path" --arg type "$artifact_type" \
            --argjson actual "$actual_size" --argjson min "$min_size_bytes" \
            '{artifact_path: $path, artifact_type: $type, actual_size: $actual, min_size: $min, error: "file_too_small"}')"
      fi
    fi

    echo "ERROR: Agent artifact too small: $artifact_path" >&2
    echo "Expected minimum $min_size_bytes bytes, got $actual_size bytes" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# State Restoration Validation
# ==============================================================================

# validate_state_restoration: Validate critical variables after state restoration
#
# Checks that critical workflow variables are non-empty after load_workflow_state.
# This detects state restoration failures early before they cause cascading errors.
#
# Usage:
#   load_workflow_state
#   validate_state_restoration "RESEARCH_DIR" "TOPIC_PATH" || exit 1
#
# Parameters:
#   $@ - var_names: List of variable names to validate
#
# Returns:
#   0 on success (all variables are non-empty)
#   1 on failure (one or more variables are empty or undefined)
#
# Logs:
#   state_error to centralized error log on failure
validate_state_restoration() {
  local var_names=("$@")
  local missing_vars=()

  # Validate at least one variable name provided
  if [ ${#var_names[@]} -eq 0 ]; then
    echo "ERROR: validate_state_restoration requires at least one variable name" >&2
    return 1
  fi

  # Check each variable
  for var_name in "${var_names[@]}"; do
    local var_value="${!var_name:-}"
    if [ -z "$var_value" ]; then
      missing_vars+=("$var_name")
    fi
  done

  # Report missing variables
  if [ ${#missing_vars[@]} -gt 0 ]; then
    local missing_list
    missing_list=$(printf "%s, " "${missing_vars[@]}")
    missing_list="${missing_list%, }"  # Remove trailing comma

    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "state_error" \
          "State restoration failed: missing variables: $missing_list" \
          "validate_state_restoration" \
          "$(jq -n --arg vars "$missing_list" '{missing_variables: $vars}')"
      fi
    fi

    echo "ERROR: State restoration failed - missing variables: $missing_list" >&2
    echo "Variables were not restored from state file" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Directory Variable Validation
# ==============================================================================

# validate_directory_var: Validate directory variable before use in find commands
#
# Checks that a directory variable is non-empty and the directory exists.
# This prevents find command failures from undefined or invalid directory paths.
#
# Usage:
#   validate_directory_var "RESEARCH_DIR" "research reports" || EXISTING_REPORTS=0
#
# Parameters:
#   $1 - var_name: Name of the directory variable to validate
#   $2 - purpose: Human-readable description of directory purpose
#
# Returns:
#   0 on success (variable is non-empty and directory exists)
#   1 on failure (variable is empty or directory doesn't exist)
#
# Logs:
#   file_error to centralized error log on failure
validate_directory_var() {
  local var_name="${1:-}"
  local purpose="${2:-directory}"

  # Validate parameters
  if [ -z "$var_name" ]; then
    echo "ERROR: var_name parameter required" >&2
    return 1
  fi

  # Get variable value
  local var_value="${!var_name:-}"

  # Check variable is non-empty
  if [ -z "$var_value" ]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "file_error" \
          "Directory variable is empty: $var_name" \
          "validate_directory_var" \
          "$(jq -n --arg var "$var_name" --arg desc "$purpose" \
            '{variable_name: $var, purpose: $desc, error: "variable_empty"}')"
      fi
    fi

    echo "ERROR: Directory variable is empty: $var_name (needed for $purpose)" >&2
    return 1
  fi

  # Check directory exists
  if [ ! -d "$var_value" ]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "file_error" \
          "Directory does not exist: $var_value" \
          "validate_directory_var" \
          "$(jq -n --arg var "$var_name" --arg path "$var_value" --arg desc "$purpose" \
            '{variable_name: $var, directory_path: $path, purpose: $desc, error: "directory_not_found"}')"
      fi
    fi

    echo "ERROR: Directory does not exist: $var_value (from $var_name, needed for $purpose)" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Path Validation
# ==============================================================================

# validate_absolute_path: Validate path format and optional existence
#
# Checks that a path is absolute (starts with /) and optionally validates
# that the path exists on the filesystem.
#
# Usage:
#   validate_absolute_path "$PLAN_FILE" true || exit 1  # Check existence
#   validate_absolute_path "$OUTPUT_DIR" false || exit 1  # Format only
#
# Parameters:
#   $1 - path: Path to validate
#   $2 - check_exists: Boolean (true/false) whether to check existence (default: false)
#
# Returns:
#   0 on success (path is absolute and exists if check_exists=true)
#   1 on failure (path is relative or doesn't exist)
#
# Logs:
#   validation_error to centralized error log on failure
validate_absolute_path() {
  local path="${1:-}"
  local check_exists="${2:-false}"

  # Validate parameters
  if [ -z "$path" ]; then
    echo "ERROR: path parameter required" >&2
    return 1
  fi

  # Check absolute path format
  if [[ ! "$path" =~ ^/ ]]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "validation_error" \
          "Path is not absolute" \
          "validate_absolute_path" \
          "$(jq -n --arg path "$path" '{path: $path, error: "not_absolute"}')"
      fi
    fi

    echo "ERROR: Path is not absolute: $path" >&2
    echo "Absolute paths must start with /" >&2
    return 1
  fi

  # Check existence if requested
  if [ "$check_exists" = "true" ]; then
    if [ ! -e "$path" ]; then
      # Log error if error logging context is available
      if declare -F log_command_error >/dev/null 2>&1; then
        if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
          log_command_error \
            "$COMMAND_NAME" \
            "$WORKFLOW_ID" \
            "${USER_ARGS:-}" \
            "validation_error" \
            "Path does not exist" \
            "validate_absolute_path" \
            "$(jq -n --arg path "$path" '{path: $path, error: "not_found"}')"
        fi
      fi

      echo "ERROR: Path does not exist: $path" >&2
      return 1
    fi
  fi

  return 0
}

# ==============================================================================
# Path Consistency Validation
# ==============================================================================

# validate_path_consistency: Validate STATE_FILE path is consistent with CLAUDE_PROJECT_DIR
#
# Validates that STATE_FILE path is consistent with CLAUDE_PROJECT_DIR, handling the
# case where PROJECT_DIR is legitimately under HOME (e.g., ~/.config).
#
# This function prevents false positive PATH MISMATCH errors that occur when:
# - CLAUDE_PROJECT_DIR is /home/user/.config (valid configuration)
# - STATE_FILE is /home/user/.config/.claude/tmp/... (correct path)
# - Old validation incorrectly flagged this as a mismatch
#
# Usage:
#   validate_path_consistency "$STATE_FILE" "$CLAUDE_PROJECT_DIR" || exit 1
#
# Parameters:
#   $1 - state_file: Path to the workflow state file
#   $2 - project_dir: CLAUDE_PROJECT_DIR value
#
# Returns:
#   0 on success (paths are consistent)
#   1 on failure (path mismatch detected)
#
# Logs:
#   state_error to centralized error log on failure
validate_path_consistency() {
  local state_file="${1:-}"
  local project_dir="${2:-}"

  # Validate parameters
  if [ -z "$state_file" ]; then
    echo "ERROR: state_file parameter required" >&2
    return 1
  fi

  if [ -z "$project_dir" ]; then
    echo "ERROR: project_dir parameter required" >&2
    return 1
  fi

  # If project dir is under HOME, state file under HOME is valid
  if [[ "$project_dir" =~ ^${HOME}/ ]]; then
    return 0
  fi

  # Otherwise, state file should use project dir, not HOME
  if [[ "$state_file" =~ ^${HOME}/ ]]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "state_error" \
          "PATH MISMATCH detected: STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR" \
          "validate_path_consistency" \
          "$(jq -n --arg state_file "$state_file" --arg home "$HOME" --arg project_dir "$project_dir" \
            '{state_file: $state_file, home: $home, project_dir: $project_dir, issue: "STATE_FILE must use CLAUDE_PROJECT_DIR"}')"
      fi
    fi

    echo "ERROR: PATH MISMATCH - STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR" >&2
    echo "  Current: $state_file" >&2
    echo "  Expected: ${project_dir}/.claude/tmp/..." >&2
    return 1
  fi

  return 0
}

# validate_state_variables: Validate critical variables after state restoration
#
# Checks that critical workflow variables are non-empty after sourcing a state file.
# This detects state restoration failures early before they cause cascading errors.
#
# Usage:
#   validate_state_variables WORKFLOW_DESCRIPTION TOPIC_PATH || exit 1
#
# Parameters:
#   $@ - variable_names: List of variable names to validate (checked via indirect reference)
#
# Returns:
#   0 on success (all variables are non-empty)
#   1 on failure (one or more variables are empty)
#
# Logs:
#   state_error to centralized error log on failure
validate_state_variables() {
  local variable_names=("$@")
  local missing_vars=()

  for var_name in "${variable_names[@]}"; do
    # Use indirect reference to check if variable is empty
    local var_value="${!var_name:-}"
    if [ -z "$var_value" ]; then
      missing_vars+=("$var_name")
    fi
  done

  if [ ${#missing_vars[@]} -gt 0 ]; then
    local missing_list
    missing_list=$(printf "%s, " "${missing_vars[@]}")
    missing_list="${missing_list%, }"  # Remove trailing comma

    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "state_error" \
          "State restoration incomplete: missing variables: $missing_list" \
          "validate_state_variables" \
          "$(jq -n --arg vars "$missing_list" '{missing_variables: $vars}')"
      fi
    fi

    echo "ERROR: State restoration incomplete: missing variables: $missing_list" >&2
    return 1
  fi

  return 0
}

# validate_project_directory: Validate CLAUDE_PROJECT_DIR detection
#
# Validates that CLAUDE_PROJECT_DIR is set and points to a valid project directory
# with a .claude subdirectory.
#
# Usage:
#   validate_project_directory || exit 1
#
# Parameters:
#   None (checks CLAUDE_PROJECT_DIR environment variable)
#
# Returns:
#   0 on success (valid project directory)
#   1 on failure (CLAUDE_PROJECT_DIR not set or invalid)
#
# Logs:
#   validation_error to centralized error log on failure
validate_project_directory() {
  # Check if CLAUDE_PROJECT_DIR is set
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "validation_error" \
          "CLAUDE_PROJECT_DIR not set" \
          "validate_project_directory" \
          "$(jq -n '{error: "CLAUDE_PROJECT_DIR_not_set"}')"
      fi
    fi

    echo "ERROR: CLAUDE_PROJECT_DIR not set" >&2
    echo "Cannot detect project directory" >&2
    return 1
  fi

  # Check if .claude directory exists
  if [ ! -d "${CLAUDE_PROJECT_DIR}/.claude" ]; then
    # Log error if error logging context is available
    if declare -F log_command_error >/dev/null 2>&1; then
      if [ -n "${COMMAND_NAME:-}" ] && [ -n "${WORKFLOW_ID:-}" ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "${USER_ARGS:-}" \
          "validation_error" \
          "Invalid project directory: .claude subdirectory not found" \
          "validate_project_directory" \
          "$(jq -n --arg dir "$CLAUDE_PROJECT_DIR" '{project_dir: $dir, error: ".claude_directory_not_found"}')"
      fi
    fi

    echo "ERROR: Invalid project directory: $CLAUDE_PROJECT_DIR" >&2
    echo ".claude subdirectory not found" >&2
    return 1
  fi

  return 0
}

# ==============================================================================
# Initialization
# ==============================================================================

# Library loaded successfully
return 0
