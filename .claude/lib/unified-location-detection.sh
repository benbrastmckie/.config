#!/usr/bin/env bash
# unified-location-detection.sh
#
# Unified location detection library for Claude Code workflow commands
# Consolidates logic from detect-project-dir.sh, topic-utils.sh, and command-specific detection
#
# Commands using this library: /supervise, /orchestrate, /report, /plan
# Dependencies: None (pure bash, no external utilities except jq for JSON output)
#
# Usage:
#   source /path/to/unified-location-detection.sh
#   LOCATION_JSON=$(perform_location_detection "workflow description")
#   TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')

# Removed strict error mode to allow graceful handling of expected failures (e.g., ls with no matches)
# set -euo pipefail
set -eo pipefail

# ============================================================================
# SECTION 1: Project Root Detection
# ============================================================================

# detect_project_root()
# Purpose: Determine project root directory with git worktree support
# Returns: Absolute path to project root
# Precedence: CLAUDE_PROJECT_DIR env var > git root > current directory
#
# Usage:
#   PROJECT_ROOT=$(detect_project_root)
#
# Exit Codes:
#   0: Success (always, uses fallback if needed)
detect_project_root() {
  # Method 1: Respect existing environment variable (manual override)
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    echo "$CLAUDE_PROJECT_DIR"
    return 0
  fi

  # Method 2: Git repository root (handles worktrees correctly)
  if command -v git &>/dev/null; then
    if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
      git rev-parse --show-toplevel
      return 0
    fi
  fi

  # Method 3: Fallback to current directory
  pwd
  return 0
}

# ============================================================================
# SECTION 2: Specs Directory Detection
# ============================================================================

# detect_specs_directory(project_root)
# Purpose: Determine specs directory location (.claude/specs vs specs)
# Arguments:
#   $1: project_root - Absolute path to project root
# Returns: Absolute path to specs directory
# Precedence: .claude/specs (preferred) > specs (legacy) > create .claude/specs
#
# Usage:
#   SPECS_DIR=$(detect_specs_directory "$PROJECT_ROOT")
#
# Exit Codes:
#   0: Success (creates directory if needed)
#   1: Failed to create directory
detect_specs_directory() {
  local project_root="$1"

  # Method 1: Prefer .claude/specs (modern convention)
  if [ -d "${project_root}/.claude/specs" ]; then
    echo "${project_root}/.claude/specs"
    return 0
  fi

  # Method 2: Support specs (legacy convention)
  if [ -d "${project_root}/specs" ]; then
    echo "${project_root}/specs"
    return 0
  fi

  # Method 3: Create .claude/specs (default for new projects)
  local specs_dir="${project_root}/.claude/specs"
  mkdir -p "$specs_dir" || {
    echo "ERROR: Failed to create specs directory: $specs_dir" >&2
    return 1
  }

  echo "$specs_dir"
  return 0
}

# ============================================================================
# SECTION 3: Topic Number Calculation
# ============================================================================

# get_next_topic_number(specs_root)
# Purpose: Calculate next sequential topic number from existing topics
# Arguments:
#   $1: specs_root - Absolute path to specs directory
# Returns: Three-digit topic number (e.g., "001", "042", "137")
# Logic: Find max existing topic number, increment by 1
#
# Usage:
#   TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
#
# Exit Codes:
#   0: Success
get_next_topic_number() {
  local specs_root="$1"

  # Find maximum existing topic number
  local max_num
  max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  # Handle empty directory (first topic)
  if [ -z "$max_num" ]; then
    echo "001"
    return 0
  fi

  # Increment and format with leading zeros
  # Note: 10#$max_num forces base-10 interpretation (avoids octal issues)
  printf "%03d" $((10#$max_num + 1))
  return 0
}

# find_existing_topic(specs_root, topic_name_pattern)
# Purpose: Search for existing topic matching name pattern (optional reuse)
# Arguments:
#   $1: specs_root - Absolute path to specs directory
#   $2: topic_name_pattern - Regex pattern to match topic names
# Returns: Topic number if found, empty string if not found
# Logic: Search topic directory names for pattern match
#
# Usage:
#   EXISTING=$(find_existing_topic "$SPECS_ROOT" "auth.*patterns")
#   if [ -n "$EXISTING" ]; then
#     echo "Found existing topic: $EXISTING"
#   fi
#
# Exit Codes:
#   0: Success (whether found or not)
find_existing_topic() {
  local specs_root="$1"
  local pattern="$2"

  # Search existing topic names for pattern match
  local match
  match=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    grep -E "${specs_root}/[0-9]{3}_.*${pattern}" | \
    head -1 | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/')

  echo "$match"
  return 0
}

# ============================================================================
# SECTION 4: Topic Name Sanitization
# ============================================================================

# sanitize_topic_name(raw_name)
# Purpose: Convert workflow description to valid topic directory name
# Arguments:
#   $1: raw_name - Raw workflow description (user input)
# Returns: Sanitized topic name (snake_case, max 50 chars)
# Rules:
#   - Convert to lowercase
#   - Replace spaces with underscores
#   - Remove all non-alphanumeric except underscores
#   - Trim leading/trailing underscores
#   - Collapse multiple underscores
#   - Truncate to 50 characters
#
# Usage:
#   TOPIC_NAME=$(sanitize_topic_name "Research: Authentication Patterns")
#   # Result: "research_authentication_patterns"
#
# Exit Codes:
#   0: Success
sanitize_topic_name() {
  local raw_name="$1"

  echo "$raw_name" | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' '_' | \
    sed 's/[^a-z0-9_]//g' | \
    sed 's/^_*//;s/_*$//' | \
    sed 's/__*/_/g' | \
    cut -c1-50

  return 0
}

# ============================================================================
# SECTION 5: Topic Directory Structure Creation
# ============================================================================

# create_topic_structure(topic_path)
# Purpose: Create standard 6-subdirectory topic structure
# Arguments:
#   $1: topic_path - Absolute path to topic directory
# Returns: Nothing (exits on failure)
# Creates:
#   - reports/    - Research documentation
#   - plans/      - Implementation plans
#   - summaries/  - Workflow summaries
#   - debug/      - Debug reports and diagnostics
#   - scripts/    - Utility scripts
#   - outputs/    - Command outputs and logs
#
# Usage:
#   create_topic_structure "$TOPIC_PATH" || exit 1
#
# Exit Codes:
#   0: Success (all directories created)
#   1: Failure (directory creation failed)
create_topic_structure() {
  local topic_path="$1"

  # Create topic root and all subdirectories
  mkdir -p "$topic_path"/{reports,plans,summaries,debug,scripts,outputs} || {
    echo "ERROR: Failed to create topic directory structure: $topic_path" >&2
    return 1
  }

  # Verify all subdirectories created successfully (MANDATORY VERIFICATION per standards)
  for subdir in reports plans summaries debug scripts outputs; do
    if [ ! -d "$topic_path/$subdir" ]; then
      echo "ERROR: Subdirectory missing after creation: $topic_path/$subdir" >&2
      return 1
    fi
  done

  return 0
}

# ============================================================================
# SECTION 6: High-Level Location Detection Orchestration
# ============================================================================

# perform_location_detection(workflow_description, [force_new_topic])
# Purpose: Complete location detection workflow (orchestrates all functions)
# Arguments:
#   $1: workflow_description - User-provided workflow description
#   $2: force_new_topic - Optional flag ("true" to skip reuse check)
# Returns: JSON object with location context
# Output Format:
#   {
#     "topic_number": "082",
#     "topic_name": "auth_patterns_research",
#     "topic_path": "/path/to/specs/082_auth_patterns_research",
#     "artifact_paths": {
#       "reports": "/path/to/specs/082_auth_patterns_research/reports",
#       "plans": "/path/to/specs/082_auth_patterns_research/plans",
#       "summaries": "/path/to/specs/082_auth_patterns_research/summaries",
#       "debug": "/path/to/specs/082_auth_patterns_research/debug",
#       "scripts": "/path/to/specs/082_auth_patterns_research/scripts",
#       "outputs": "/path/to/specs/082_auth_patterns_research/outputs"
#     }
#   }
#
# Usage:
#   LOCATION_JSON=$(perform_location_detection "research authentication patterns")
#   TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
#
# Exit Codes:
#   0: Success
#   1: Failure (directory creation or detection failed)
perform_location_detection() {
  local workflow_description="$1"
  local force_new_topic="${2:-false}"

  # Step 1: Detect project root
  local project_root
  project_root=$(detect_project_root)

  # Step 2: Detect specs directory
  local specs_root
  specs_root=$(detect_specs_directory "$project_root") || return 1

  # Step 3: Sanitize workflow description to topic name
  local topic_name
  topic_name=$(sanitize_topic_name "$workflow_description")

  # Step 4: Check for existing topic (optional reuse)
  local topic_number
  if [ "$force_new_topic" = "false" ]; then
    local existing_topic
    existing_topic=$(find_existing_topic "$specs_root" "$topic_name")

    if [ -n "$existing_topic" ]; then
      # Existing topic found - could prompt user for reuse
      # For now, always create new topic (future enhancement)
      topic_number=$(get_next_topic_number "$specs_root")
    else
      topic_number=$(get_next_topic_number "$specs_root")
    fi
  else
    topic_number=$(get_next_topic_number "$specs_root")
  fi

  # Step 5: Construct topic path
  local topic_path="${specs_root}/${topic_number}_${topic_name}"

  # Step 6: Create directory structure
  create_topic_structure "$topic_path" || return 1

  # Step 7: Generate JSON output
  cat <<EOF
{
  "topic_number": "$topic_number",
  "topic_name": "$topic_name",
  "topic_path": "$topic_path",
  "artifact_paths": {
    "reports": "$topic_path/reports",
    "plans": "$topic_path/plans",
    "summaries": "$topic_path/summaries",
    "debug": "$topic_path/debug",
    "scripts": "$topic_path/scripts",
    "outputs": "$topic_path/outputs"
  }
}
EOF

  return 0
}

# ============================================================================
# SECTION 7: Legacy Compatibility Functions
# ============================================================================

# generate_legacy_location_context(location_json)
# Purpose: Convert JSON output to legacy YAML format for backward compatibility
# Arguments:
#   $1: location_json - JSON output from perform_location_detection()
# Returns: YAML-formatted location context (legacy format)
# Note: Maintained for 2 release cycles, then deprecated
#
# Usage:
#   LOCATION_YAML=$(generate_legacy_location_context "$LOCATION_JSON")
#
# Exit Codes:
#   0: Success
generate_legacy_location_context() {
  local location_json="$1"

  # Extract fields from JSON (fallback if jq not available)
  local topic_number topic_name topic_path
  if command -v jq &>/dev/null; then
    topic_number=$(echo "$location_json" | jq -r '.topic_number')
    topic_name=$(echo "$location_json" | jq -r '.topic_name')
    topic_path=$(echo "$location_json" | jq -r '.topic_path')
  else
    # Fallback: simple grep/sed extraction (less robust)
    topic_number=$(echo "$location_json" | grep -o '"topic_number": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    topic_name=$(echo "$location_json" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    topic_path=$(echo "$location_json" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  fi

  # Generate YAML format (legacy)
  cat <<EOF
topic_number: $topic_number
topic_name: $topic_name
topic_path: $topic_path
artifact_paths:
  reports: $topic_path/reports
  plans: $topic_path/plans
  summaries: $topic_path/summaries
  debug: $topic_path/debug
  scripts: $topic_path/scripts
  outputs: $topic_path/outputs
EOF

  return 0
}

# ============================================================================
# END OF LIBRARY
# ============================================================================
