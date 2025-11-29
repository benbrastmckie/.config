#!/usr/bin/env bash
# Barrier Utilities - Hard Barrier Pattern Support Functions
# Version: 1.0.0
#
# Provides helper functions for implementing hard barrier subagent delegation pattern.
# See: .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md

# Verify that a Task invocation produced expected artifacts
# Usage: verify_task_executed "agent-name" "/path/to/expected/artifact.md"
# Returns: 0 on success, 1 on failure (logs error)
verify_task_executed() {
  local agent_name="$1"
  local expected_artifact="$2"

  if [[ -z "$agent_name" ]] || [[ -z "$expected_artifact" ]]; then
    echo "ERROR: verify_task_executed requires agent_name and expected_artifact" >&2
    return 1
  fi

  # Check if artifact exists
  if [[ ! -e "$expected_artifact" ]]; then
    # Log error if error-handling library available
    if declare -f log_command_error >/dev/null 2>&1; then
      log_command_error "verification_error" \
        "Expected artifact not found: $expected_artifact" \
        "Agent $agent_name should have created this artifact"
    fi
    echo "ERROR: Task verification failed - $agent_name did not create $expected_artifact" >&2
    return 1
  fi

  # Check if artifact is a directory with content
  if [[ -d "$expected_artifact" ]]; then
    local file_count
    file_count=$(find "$expected_artifact" -type f 2>/dev/null | wc -l)
    if [[ "$file_count" -eq 0 ]]; then
      if declare -f log_command_error >/dev/null 2>&1; then
        log_command_error "verification_error" \
          "Artifact directory empty: $expected_artifact" \
          "Agent $agent_name created directory but no files"
      fi
      echo "ERROR: Task verification failed - $agent_name created empty directory" >&2
      return 1
    fi
  fi

  # Check if artifact is a file with content
  if [[ -f "$expected_artifact" ]]; then
    if [[ ! -s "$expected_artifact" ]]; then
      if declare -f log_command_error >/dev/null 2>&1; then
        log_command_error "verification_error" \
          "Artifact file empty: $expected_artifact" \
          "Agent $agent_name created empty file"
      fi
      echo "ERROR: Task verification failed - $agent_name created empty file" >&2
      return 1
    fi
  fi

  return 0
}

# Log checkpoint marker for barrier state tracking
# Usage: barrier_checkpoint "block_name" "status_message"
# Example: barrier_checkpoint "Block 4a" "Research setup complete"
barrier_checkpoint() {
  local block_name="$1"
  local status_message="$2"

  if [[ -z "$block_name" ]]; then
    echo "ERROR: barrier_checkpoint requires block_name" >&2
    return 1
  fi

  echo "[CHECKPOINT] ${block_name}: ${status_message}"
  return 0
}

# Detect if orchestrator bypassed Task invocation (heuristic)
# Usage: detect_bypass "/path/to/state/file" "expected_agent_name"
# Returns: 0 if bypass detected, 1 if delegation occurred
detect_bypass() {
  local state_file="$1"
  local expected_agent="$2"

  if [[ -z "$state_file" ]] || [[ ! -f "$state_file" ]]; then
    echo "WARNING: Cannot detect bypass - state file missing: $state_file" >&2
    return 1  # Assume delegation occurred if can't verify
  fi

  # Check if state file has agent invocation markers
  # (This is a heuristic - may need adjustment per command)
  if grep -q "AGENT_INVOKED=${expected_agent}" "$state_file" 2>/dev/null; then
    return 1  # Delegation occurred
  fi

  # Check for bypass indicators
  # (Orchestrator performed work directly)
  if grep -q "BYPASS_DETECTED=true" "$state_file" 2>/dev/null; then
    echo "WARNING: Bypass detected - orchestrator performed work directly" >&2
    return 0  # Bypass detected
  fi

  # Default: assume delegation occurred
  return 1
}

# Verify multiple artifacts exist (batch check)
# Usage: verify_artifacts_exist "agent-name" "/path/file1.md" "/path/file2.md" ...
# Returns: 0 if all exist, 1 if any missing
verify_artifacts_exist() {
  local agent_name="$1"
  shift  # Remove agent_name, leaving artifact paths

  if [[ -z "$agent_name" ]]; then
    echo "ERROR: verify_artifacts_exist requires agent_name" >&2
    return 1
  fi

  local missing_count=0
  local artifact

  for artifact in "$@"; do
    if [[ ! -e "$artifact" ]]; then
      echo "ERROR: Missing artifact: $artifact" >&2
      ((missing_count++))
    fi
  done

  if [[ "$missing_count" -gt 0 ]]; then
    if declare -f log_command_error >/dev/null 2>&1; then
      log_command_error "verification_error" \
        "Agent $agent_name missing $missing_count artifacts" \
        "Expected artifacts: $*"
    fi
    return 1
  fi

  return 0
}

# Verify artifact modified since backup
# Usage: verify_artifact_modified "/path/to/artifact.md" "/path/to/backup.md"
# Returns: 0 if modified, 1 if identical or not modified
verify_artifact_modified() {
  local artifact="$1"
  local backup="$2"

  if [[ -z "$artifact" ]] || [[ -z "$backup" ]]; then
    echo "ERROR: verify_artifact_modified requires artifact and backup paths" >&2
    return 1
  fi

  if [[ ! -f "$artifact" ]]; then
    echo "ERROR: Artifact not found: $artifact" >&2
    return 1
  fi

  if [[ ! -f "$backup" ]]; then
    echo "ERROR: Backup not found: $backup" >&2
    return 1
  fi

  # Timestamp check
  if [[ "$artifact" -nt "$backup" ]]; then
    return 0  # Modified (newer)
  fi

  # Content comparison (if timestamps identical)
  if diff -q "$artifact" "$backup" >/dev/null 2>&1; then
    if declare -f log_command_error >/dev/null 2>&1; then
      log_command_error "verification_error" \
        "Artifact not modified (identical to backup)" \
        "Artifact: $artifact, Backup: $backup"
    fi
    echo "ERROR: Artifact not modified - content identical to backup" >&2
    return 1
  fi

  return 0  # Modified (different content)
}

# Export functions for use in subshells
export -f verify_task_executed
export -f barrier_checkpoint
export -f detect_bypass
export -f verify_artifacts_exist
export -f verify_artifact_modified
