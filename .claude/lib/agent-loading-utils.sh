#!/usr/bin/env bash
# Agent Loading Utilities
# Utilities for behavioral injection pattern in command/agent workflows
#
# Functions:
#   - load_agent_behavioral_prompt() - Load agent behavioral file and strip frontmatter
#   - get_next_artifact_number() - Calculate next NNN artifact number in directory
#   - verify_artifact_or_recover() - Verify artifact exists with path recovery
#
# Usage:
#   source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"

# ============================================================================
# Function: load_agent_behavioral_prompt
# ============================================================================
#
# Load agent behavioral prompt file and strip YAML frontmatter
#
# Agent behavioral files may contain YAML frontmatter (between --- markers)
# for metadata. This function strips the frontmatter and returns only the
# behavioral instructions that should be injected into agent prompts.
#
# Arguments:
#   $1 - agent_name (without .md extension, e.g., "plan-architect")
#
# Returns:
#   Behavioral prompt content (stdout)
#   Exit code 0 on success, 1 on error
#
# Example:
#   AGENT_PROMPT=$(load_agent_behavioral_prompt "plan-architect")
#   if [ $? -ne 0 ]; then
#     echo "Error loading agent behavioral prompt"
#     exit 1
#   fi
#
# Implementation Notes:
#   - Looks for agent file in ${CLAUDE_PROJECT_DIR}/.claude/agents/
#   - Strips YAML frontmatter between first and second --- markers
#   - Preserves all content after second --- marker
#   - Returns error if agent file not found
#
load_agent_behavioral_prompt() {
  local agent_name="$1"

  if [ -z "$agent_name" ]; then
    echo "Error: agent_name required" >&2
    echo "Usage: load_agent_behavioral_prompt <agent-name>" >&2
    return 1
  fi

  local agent_file="${CLAUDE_PROJECT_DIR}/.claude/agents/${agent_name}.md"

  if [[ ! -f "$agent_file" ]]; then
    echo "Error: Agent file not found: $agent_file" >&2
    return 1
  fi

  # Strip YAML frontmatter (between first and second --- markers)
  # Strategy:
  # 1. Check if first line is ---
  # 2. If yes, skip lines until we find the closing ---
  # 3. Print everything after the closing ---

  # Check if file has frontmatter
  if head -1 "$agent_file" | grep -q "^---$"; then
    # File has frontmatter, strip it
    # Use awk to skip everything between first and second ---
    awk 'BEGIN {in_frontmatter=0; found_first=0}
         /^---$/ {
           if (!found_first) {
             in_frontmatter=1
             found_first=1
             next
           } else if (in_frontmatter) {
             in_frontmatter=0
             next
           }
         }
         !in_frontmatter && found_first {print}' "$agent_file"
  else
    # No frontmatter, return entire file
    cat "$agent_file"
  fi

  return 0
}

# ============================================================================
# Function: get_next_artifact_number
# ============================================================================
#
# Calculate the next artifact number (NNN format) in a directory
#
# Scans directory for files matching pattern NNN_*.md and returns the next
# sequential number. Used to maintain consistent numbering across artifacts.
#
# Arguments:
#   $1 - artifact_dir (absolute path to directory containing artifacts)
#
# Returns:
#   Next artifact number in NNN format (e.g., "001", "042", "127")
#   Exit code 0 on success, 1 on error
#
# Example:
#   NEXT_NUM=$(get_next_artifact_number "/path/to/specs/042_auth/reports")
#   echo $NEXT_NUM  # Output: "001" (if directory empty) or "043" (if max is 042)
#
# Implementation Notes:
#   - Handles empty directories (returns "001")
#   - Finds maximum existing number and increments by 1
#   - Always returns 3-digit zero-padded number
#   - Ignores files that don't match NNN_*.md pattern
#
get_next_artifact_number() {
  local artifact_dir="$1"

  if [ -z "$artifact_dir" ]; then
    echo "Error: artifact_dir required" >&2
    echo "Usage: get_next_artifact_number <artifact-directory>" >&2
    return 1
  fi

  if [[ ! -d "$artifact_dir" ]]; then
    # Directory doesn't exist yet, start at 001
    printf "%03d" 1
    return 0
  fi

  # Find all files matching NNN_*.md pattern
  # Extract numbers, find maximum, increment by 1
  local max_num=0

  while IFS= read -r file; do
    # Extract number from filename (first 3 digits)
    local num=$(basename "$file" | grep -oE "^[0-9]{3}" || echo "0")

    # Force base-10 interpretation (remove leading zeros to avoid octal)
    num=$((10#$num))

    if [ "$num" -gt "$max_num" ]; then
      max_num=$num
    fi
  done < <(find "$artifact_dir" -maxdepth 1 -name "[0-9][0-9][0-9]_*.md" 2>/dev/null)

  # Increment and format as 3-digit zero-padded
  local next_num=$((max_num + 1))
  printf "%03d" "$next_num"

  return 0
}

# ============================================================================
# Function: verify_artifact_or_recover
# ============================================================================
#
# Verify artifact exists at expected path, with recovery for path mismatches
#
# Agents sometimes create artifacts at slightly different paths than expected.
# This function verifies the artifact exists and attempts recovery by searching
# for files with matching topic slugs.
#
# Arguments:
#   $1 - expected_path (absolute path where artifact should be)
#   $2 - topic_slug (search term for recovery, e.g., "authentication", "refactor")
#
# Returns:
#   Actual artifact path (stdout) - may differ from expected_path if recovered
#   Exit code 0 on success (found or recovered), 1 on failure (not found)
#
# Example:
#   ARTIFACT_PATH=$(verify_artifact_or_recover \
#     "/path/to/specs/042_auth/reports/042_security.md" \
#     "security")
#
#   if [ $? -eq 0 ]; then
#     echo "Artifact found at: $ARTIFACT_PATH"
#   else
#     echo "Artifact not found, cannot recover"
#     exit 1
#   fi
#
# Implementation Notes:
#   - First checks if file exists at expected path (fast path)
#   - If not found, searches parent directory for matching topic_slug
#   - Uses case-insensitive search for topic slug
#   - Returns first matching file if multiple found
#   - Prints recovery notice to stderr if path differs from expected
#
verify_artifact_or_recover() {
  local expected_path="$1"
  local topic_slug="$2"

  if [ -z "$expected_path" ] || [ -z "$topic_slug" ]; then
    echo "Error: expected_path and topic_slug required" >&2
    echo "Usage: verify_artifact_or_recover <expected-path> <topic-slug>" >&2
    return 1
  fi

  # Fast path: file exists at expected location
  if [[ -f "$expected_path" ]]; then
    echo "$expected_path"
    return 0
  fi

  # Recovery path: search for artifact with matching topic slug
  local artifact_dir=$(dirname "$expected_path")

  if [[ ! -d "$artifact_dir" ]]; then
    echo "Error: Artifact directory not found: $artifact_dir" >&2
    return 1
  fi

  # Search for files containing topic slug (case-insensitive)
  # Replace spaces with underscores for search
  local search_slug="${topic_slug// /_}"

  local actual_path=$(find "$artifact_dir" -maxdepth 1 -type f -iname "*${search_slug}*.md" 2>/dev/null | head -1)

  if [[ -n "$actual_path" ]]; then
    echo "RECOVERY: Expected artifact not found at: $expected_path" >&2
    echo "RECOVERY: Found artifact at: $actual_path" >&2
    echo "$actual_path"
    return 0
  fi

  # Recovery failed
  echo "Error: Artifact not found at expected path: $expected_path" >&2
  echo "Error: Recovery search for '$topic_slug' in $artifact_dir failed" >&2
  return 1
}

# ============================================================================
# Utility Validation
# ============================================================================

# Validate that base utilities are available
if ! declare -f error >/dev/null 2>&1; then
  echo "Error: base-utils.sh not properly sourced" >&2
  exit 1
fi
