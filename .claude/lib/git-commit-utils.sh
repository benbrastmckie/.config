#!/usr/bin/env bash
# git-commit-utils.sh - Utility functions for generating standardized git commit messages
#
# Replaces git-commit-helper agent with zero-overhead function calls
# Follows project standards: no emojis, feat(NNN) prefix, Title Case names

# Generate standardized git commit message for phase/stage/plan completions
#
# Usage:
#   generate_commit_message <topic_number> <completion_type> <phase_number> <stage_number> <name> <feature_name>
#
# Arguments:
#   topic_number     - 3-digit topic number (001-999), required
#   completion_type  - "phase" | "stage" | "plan", required
#   phase_number     - Phase number (required for phase/stage, empty for plan)
#   stage_number     - Stage number (required for stage, empty for phase/plan)
#   name             - Phase/stage name (required for phase/stage, empty for plan)
#   feature_name     - Feature name (required for plan, empty for phase/stage)
#
# Returns:
#   Single-line commit message following project standards
#
# Examples:
#   # Stage completion
#   generate_commit_message "027" "stage" "2" "1" "Database Schema" ""
#   # Output: feat(027): complete Phase 2 Stage 1 - Database Schema
#
#   # Phase completion
#   generate_commit_message "042" "phase" "3" "" "Backend Implementation" ""
#   # Output: feat(042): complete Phase 3 - Backend Implementation
#
#   # Plan completion
#   generate_commit_message "080" "plan" "" "" "" "authentication system"
#   # Output: feat(080): complete authentication system
#
generate_commit_message() {
  local topic_number="$1"
  local completion_type="$2"
  local phase_number="$3"
  local stage_number="$4"
  local name="$5"
  local feature_name="$6"

  # Validation: topic_number required and 3-digit format
  if [[ -z "$topic_number" ]]; then
    echo "ERROR: topic_number required" >&2
    return 1
  fi

  if [[ ! "$topic_number" =~ ^[0-9]{3}$ ]]; then
    echo "ERROR: topic_number must be 3-digit format (001-999), got: $topic_number" >&2
    return 1
  fi

  # Validation: completion_type required
  if [[ -z "$completion_type" ]]; then
    echo "ERROR: completion_type required (phase|stage|plan)" >&2
    return 1
  fi

  if [[ ! "$completion_type" =~ ^(phase|stage|plan)$ ]]; then
    echo "ERROR: completion_type must be phase, stage, or plan, got: $completion_type" >&2
    return 1
  fi

  # Generate commit message based on completion type
  case "$completion_type" in
    stage)
      # Stage completion: feat(NNN): complete Phase N Stage M - [Stage Name]
      if [[ -z "$phase_number" ]]; then
        echo "ERROR: phase_number required for stage completion" >&2
        return 1
      fi
      if [[ -z "$stage_number" ]]; then
        echo "ERROR: stage_number required for stage completion" >&2
        return 1
      fi
      if [[ -z "$name" ]]; then
        echo "ERROR: name required for stage completion" >&2
        return 1
      fi
      echo "feat(${topic_number}): complete Phase ${phase_number} Stage ${stage_number} - ${name}"
      ;;

    phase)
      # Phase completion: feat(NNN): complete Phase N - [Phase Name]
      if [[ -z "$phase_number" ]]; then
        echo "ERROR: phase_number required for phase completion" >&2
        return 1
      fi
      if [[ -z "$name" ]]; then
        echo "ERROR: name required for phase completion" >&2
        return 1
      fi
      echo "feat(${topic_number}): complete Phase ${phase_number} - ${name}"
      ;;

    plan)
      # Plan completion: feat(NNN): complete [feature name]
      if [[ -z "$feature_name" ]]; then
        echo "ERROR: feature_name required for plan completion" >&2
        return 1
      fi
      echo "feat(${topic_number}): complete ${feature_name}"
      ;;
  esac

  return 0
}

# Validate commit message format
#
# Usage:
#   validate_commit_message <message>
#
# Returns:
#   0 if valid, 1 if invalid
#
validate_commit_message() {
  local message="$1"

  if [[ -z "$message" ]]; then
    echo "ERROR: commit message cannot be empty" >&2
    return 1
  fi

  # Check for forbidden emojis
  if [[ "$message" =~ [✓✗🎉] ]]; then
    echo "ERROR: commit message contains forbidden emojis" >&2
    return 1
  fi

  # Check for feat(NNN) prefix
  if [[ ! "$message" =~ ^feat\([0-9]{3}\): ]]; then
    echo "ERROR: commit message must start with feat(NNN): prefix" >&2
    return 1
  fi

  return 0
}
