#!/usr/bin/env bash
# topic-utils.sh - Topic directory management utilities for .claude/ system
#
# Purpose: Deterministic topic directory creation and management
# Used by: /supervise, /orchestrate, /report, /plan commands
#
# Functions:
#   get_next_topic_number(specs_root)     - Find max topic number and increment
#   sanitize_topic_name(raw_name)         - Convert workflow description to snake_case
#   create_topic_structure(topic_path)    - Create 6 subdirectories with verification
#   find_matching_topic(topic_desc)       - Search for existing related topics (optional)

set -euo pipefail

# Get the next sequential topic number in the specs directory
# Usage: get_next_topic_number "/path/to/specs"
# Returns: "001" for empty directory, or next number (e.g., "006" if max is 005)
get_next_topic_number() {
  local specs_root="$1"

  # Find all directories matching NNN_* pattern and extract numbers
  local max_num
  max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  # If no topics found, start at 001
  if [ -z "$max_num" ]; then
    echo "001"
  else
    # Increment the max number (use 10# to force decimal interpretation)
    printf "%03d" $((10#$max_num + 1))
  fi
}

# Sanitize a workflow description into a valid topic name
# Usage: sanitize_topic_name "Research: Authentication Patterns (2025)"
# Returns: "research_authentication_patterns_2025"
#
# Rules:
#   - Convert to lowercase
#   - Replace spaces with underscores
#   - Remove special characters (keep alphanumeric and underscores)
#   - Remove leading/trailing underscores
#   - Truncate to 50 characters
sanitize_topic_name() {
  local raw_name="$1"

  echo "$raw_name" | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' '_' | \
    sed 's/[^a-z0-9_]//g' | \
    sed 's/^_*//;s/_*$//' | \
    cut -c1-50
}

# Create the standard topic directory structure with verification
# Usage: create_topic_structure "/path/to/specs/082_topic_name"
# Creates: reports/, plans/, summaries/, debug/, scripts/, outputs/ subdirectories
# Returns: 0 on success, 1 on failure
#
# Verification: Checks that all 6 subdirectories exist after creation
create_topic_structure() {
  local topic_path="$1"

  # Create parent directory
  mkdir -p "$topic_path"

  # Create all 6 standard subdirectories
  mkdir -p "$topic_path"/{reports,plans,summaries,debug,scripts,outputs}

  # Verification checkpoint (required by Verification and Fallback pattern)
  local missing_dirs=()
  for subdir in reports plans summaries debug scripts outputs; do
    if [ ! -d "$topic_path/$subdir" ]; then
      missing_dirs+=("$subdir")
    fi
  done

  # If any directories are missing, report error and fail
  if [ ${#missing_dirs[@]} -gt 0 ]; then
    echo "ERROR: Failed to create subdirectories in $topic_path:" >&2
    for missing in "${missing_dirs[@]}"; do
      echo "  - $missing" >&2
    done
    return 1
  fi

  return 0
}

# Find existing topics that match a given description
# Usage: find_matching_topic "authentication patterns"
# Returns: List of matching topic directories (one per line)
#
# Optional function for future use (intelligent topic merging)
# Currently not used by /supervise Phase 0 optimization
find_matching_topic() {
  local topic_desc="$1"
  local specs_root="${2:-${CLAUDE_CONFIG}/.claude/specs}"

  # Extract keywords from description (split on spaces, lowercase)
  local keywords
  keywords=$(echo "$topic_desc" | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | sort -u)

  # Search for matching directory names
  local matches=()
  while IFS= read -r topic_dir; do
    local topic_name
    topic_name=$(basename "$topic_dir" | sed 's/^[0-9][0-9][0-9]_//')

    # Check if any keyword appears in topic name
    for keyword in $keywords; do
      if [[ "$topic_name" == *"$keyword"* ]]; then
        matches+=("$topic_dir")
        break
      fi
    done
  done < <(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null || true)

  # Return matches (if any)
  if [ ${#matches[@]} -gt 0 ]; then
    printf "%s\n" "${matches[@]}"
  fi
}

# Usage examples:
#
# Example 1: Get next topic number
#   NEXT_NUM=$(get_next_topic_number "/path/to/specs")
#   echo "Next topic: $NEXT_NUM"  # Output: "083"
#
# Example 2: Sanitize topic name
#   TOPIC_NAME=$(sanitize_topic_name "Research: OAuth2 Authentication")
#   echo "Sanitized: $TOPIC_NAME"  # Output: "research_oauth2_authentication"
#
# Example 3: Create topic structure
#   TOPIC_PATH="/path/to/specs/083_auth_research"
#   if create_topic_structure "$TOPIC_PATH"; then
#     echo "Topic structure created successfully"
#   else
#     echo "Failed to create topic structure" >&2
#     exit 1
#   fi
#
# Example 4: Find matching topics
#   MATCHES=$(find_matching_topic "authentication")
#   if [ -n "$MATCHES" ]; then
#     echo "Found existing topics:"
#     echo "$MATCHES"
#   fi
