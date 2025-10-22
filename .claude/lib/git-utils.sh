#!/bin/bash

# Git Utilities for standardized commit message generation
# Part of Phase 7: Progress Tracking implementation

# Generate standardized commit message using git-commit-helper agent logic
generate_commit_message() {
  local topic_number="$1"
  local completion_type="$2" # phase|stage|plan
  local phase_number="$3"
  local stage_number="$4"
  local name="$5"
  local feature_name="$6"

  # Validate required inputs
  if [ -z "$topic_number" ]; then
    echo "ERROR: topic_number required" >&2
    return 1
  fi

  if [[ ! "$completion_type" =~ ^(phase|stage|plan)$ ]]; then
    echo "ERROR: completion_type must be phase, stage, or plan" >&2
    return 1
  fi

  # Generate commit message based on completion type
  local commit_msg=""

  case "$completion_type" in
    stage)
      if [ -z "$phase_number" ] || [ -z "$stage_number" ] || [ -z "$name" ]; then
        echo "ERROR: stage completion requires phase_number, stage_number, and name" >&2
        return 1
      fi
      commit_msg="feat($topic_number): complete Phase $phase_number Stage $stage_number - $name"
      ;;
    phase)
      if [ -z "$phase_number" ] || [ -z "$name" ]; then
        echo "ERROR: phase completion requires phase_number and name" >&2
        return 1
      fi
      commit_msg="feat($topic_number): complete Phase $phase_number - $name"
      ;;
    plan)
      if [ -z "$feature_name" ]; then
        echo "ERROR: plan completion requires feature_name" >&2
        return 1
      fi
      commit_msg="feat($topic_number): complete $feature_name"
      ;;
    *)
      echo "ERROR: Invalid completion_type: $completion_type" >&2
      return 1
      ;;
  esac

  echo "$commit_msg"
}

# Test function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Testing git-commit-helper utility functions..."
  echo ""

  # Test stage completion
  MSG=$(generate_commit_message "027" "stage" 2 1 "Database Schema" "")
  echo "Stage: $MSG"
  # Expected: feat(027): complete Phase 2 Stage 1 - Database Schema

  # Test phase completion
  MSG=$(generate_commit_message "042" "phase" 3 "" "Backend Implementation" "")
  echo "Phase: $MSG"
  # Expected: feat(042): complete Phase 3 - Backend Implementation

  # Test plan completion
  MSG=$(generate_commit_message "080" "plan" "" "" "" "authentication system")
  echo "Plan: $MSG"
  # Expected: feat(080): complete authentication system

  echo ""
  echo "All tests completed!"
fi
