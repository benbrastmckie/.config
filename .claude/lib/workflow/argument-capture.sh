#!/usr/bin/env bash
# argument-capture.sh - Reusable two-step argument capture for slash commands
#
# Version: 1.0.0
# Last Modified: 2025-11-17
#
# This library implements the two-step argument capture pattern to avoid positional
# parameter issues with shell expansion. It provides reusable functions that reduce
# per-command code from 15-25 lines to 3-5 lines.
#
# The pattern uses two bash blocks:
# - Part 1: Captures user input to a temp file via explicit substitution
# - Part 2: Reads from that file, eliminating shell expansion issues with special characters
#
# Source guard: Prevent multiple sourcing within same bash process
if [ -n "${ARGUMENT_CAPTURE_SOURCED:-}" ]; then
  return 0
fi
ARGUMENT_CAPTURE_SOURCED=1
export ARGUMENT_CAPTURE_VERSION="1.0.0"
#
# Key Features:
# - Timestamp-based filenames for concurrent execution safety
# - Legacy filename fallback for backward compatibility
# - Clear error messages with diagnostics
# - EXIT trap integration for cleanup
# - Minimal code per command (3-5 lines instead of 15-25)
#
# Usage:
#   # Part 1 bash block (with explicit substitution by Claude):
#   source .claude/lib/workflow/argument-capture.sh
#   capture_argument_part1 "research-plan" "YOUR_FEATURE_DESCRIPTION_HERE"
#
#   # Part 2 bash block:
#   source .claude/lib/workflow/argument-capture.sh
#   capture_argument_part2 "research-plan" "FEATURE_DESCRIPTION" || exit 1
#
#   # Optional cleanup (if EXIT trap not used):
#   cleanup_argument_files "research-plan"
#
# Canonical Reference: /coordinate command (lines 18-92) for two-step pattern
#
# Dependencies:
# - date with %N support (nanoseconds for unique filenames)
#
# Author: Claude Code
# Created: 2025-11-17 (Spec 760 Phase 1)

# Note: Don't use set -e here as it can cause issues when sourced
# Let the calling script control error handling
set -uo pipefail

# Detect CLAUDE_PROJECT_DIR if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Capture argument Part 1 - Write argument to temp file
#
# Creates a temp file with the user's argument and a path file pointing to it.
# The path file allows Part 2 to find the correct temp file even with concurrent
# executions (timestamp-based filenames).
#
# Args:
#   $1 - command_name: Name of the command (used for filename prefix)
#   $2 - placeholder_text: Placeholder that Claude replaces with actual argument
#                          (will be written to temp file if not substituted)
#
# Side Effects:
#   - Creates ~/.claude/tmp/{command_name}_arg_{timestamp}.txt
#   - Creates ~/.claude/tmp/{command_name}_arg_path.txt
#   - Prints confirmation message
#
# Example:
#   capture_argument_part1 "research-plan" "YOUR_FEATURE_DESCRIPTION_HERE"
#   # Output: Argument captured to /home/user/.claude/tmp/research-plan_arg_1731859200123456789.txt
capture_argument_part1() {
  local command_name="${1:-command}"
  local argument_text="${2:-}"

  # Create tmp directory if it doesn't exist
  mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true

  # Use timestamp-based filename for concurrent execution safety
  local timestamp=$(date +%s%N)
  local temp_file="${HOME}/.claude/tmp/${command_name}_arg_${timestamp}.txt"
  local path_file="${HOME}/.claude/tmp/${command_name}_arg_path.txt"

  # Write argument to temp file
  echo "$argument_text" > "$temp_file"

  # Save temp file path for Part 2 to read
  echo "$temp_file" > "$path_file"

  echo "Argument captured to $temp_file"
}

# Capture argument Part 2 - Read argument from temp file
#
# Reads the argument from the temp file created by Part 1 and exports it
# as the specified variable name.
#
# Args:
#   $1 - command_name: Name of the command (used to find temp files)
#   $2 - variable_name: Name of the variable to export with the captured value
#
# Returns:
#   0 if successful (argument read and exported)
#   1 if failed (temp file not found or empty)
#
# Side Effects:
#   - Exports the variable with the captured argument value
#   - Prints error messages on failure
#
# Example:
#   capture_argument_part2 "research-plan" "FEATURE_DESCRIPTION" || exit 1
#   echo "Description: $FEATURE_DESCRIPTION"
capture_argument_part2() {
  local command_name="${1:-command}"
  local variable_name="${2:-CAPTURED_ARG}"

  local path_file="${HOME}/.claude/tmp/${command_name}_arg_path.txt"
  local temp_file=""

  # Try to read path file first (concurrent execution safe)
  if [ -f "$path_file" ]; then
    temp_file=$(cat "$path_file" 2>/dev/null || echo "")
  fi

  # Fallback to legacy fixed filename for backward compatibility
  if [ -z "$temp_file" ] || [ ! -f "$temp_file" ]; then
    local legacy_file="${HOME}/.claude/tmp/${command_name}_arg.txt"
    if [ -f "$legacy_file" ]; then
      temp_file="$legacy_file"
    fi
  fi

  # Check if temp file exists
  if [ -z "$temp_file" ] || [ ! -f "$temp_file" ]; then
    echo "ERROR: Argument file not found for command '$command_name'"
    echo "This usually means Part 1 (argument capture) didn't execute."
    echo ""
    echo "Expected path file: $path_file"
    echo "Expected legacy file: ${HOME}/.claude/tmp/${command_name}_arg.txt"
    echo ""
    echo "Usage: /${command_name} \"<your argument>\""
    return 1
  fi

  # Read argument from temp file
  local captured_value
  captured_value=$(cat "$temp_file" 2>/dev/null || echo "")

  # Validate argument is not empty
  if [ -z "$captured_value" ]; then
    echo "ERROR: Argument is empty"
    echo "File exists but contains no content: $temp_file"
    echo ""
    echo "Usage: /${command_name} \"<your argument>\""
    return 1
  fi

  # Export the variable with the captured value
  export "$variable_name"="$captured_value"

  return 0
}

# Cleanup argument files
#
# Removes temp files created by capture_argument_part1.
# Call this manually if EXIT trap is not used.
#
# Args:
#   $1 - command_name: Name of the command (used to find temp files)
#
# Side Effects:
#   - Removes path file and referenced temp file
#   - Removes legacy temp file if it exists
#
# Example:
#   cleanup_argument_files "research-plan"
cleanup_argument_files() {
  local command_name="${1:-command}"

  local path_file="${HOME}/.claude/tmp/${command_name}_arg_path.txt"
  local legacy_file="${HOME}/.claude/tmp/${command_name}_arg.txt"

  # Remove temp file referenced by path file
  if [ -f "$path_file" ]; then
    local temp_file
    temp_file=$(cat "$path_file" 2>/dev/null || echo "")
    if [ -n "$temp_file" ] && [ -f "$temp_file" ]; then
      rm -f "$temp_file"
    fi
    rm -f "$path_file"
  fi

  # Remove legacy temp file if it exists
  if [ -f "$legacy_file" ]; then
    rm -f "$legacy_file"
  fi
}
