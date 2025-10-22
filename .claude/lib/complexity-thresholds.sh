#!/bin/bash
# complexity-thresholds.sh
#
# Utility for extracting complexity thresholds from CLAUDE.md files
#
# This script searches for CLAUDE.md files (current directory upward to project root),
# extracts complexity threshold configuration, and supports subdirectory-specific overrides.
#
# Usage:
#   source .claude/lib/complexity-thresholds.sh
#   get_complexity_thresholds [starting_directory]
#
# Returns (via stdout):
#   EXPANSION_THRESHOLD=8.0
#   TASK_COUNT_THRESHOLD=10
#   FILE_REFERENCE_THRESHOLD=10
#   REPLAN_LIMIT=2
#   THRESHOLDS_SOURCE="/path/to/CLAUDE.md"

# Default threshold values (used when CLAUDE.md not found or values missing)
DEFAULT_EXPANSION_THRESHOLD=8.0
DEFAULT_TASK_COUNT_THRESHOLD=10
DEFAULT_FILE_REFERENCE_THRESHOLD=10
DEFAULT_REPLAN_LIMIT=2

# Threshold validation ranges
MIN_EXPANSION_THRESHOLD=0.0
MAX_EXPANSION_THRESHOLD=15.0
MIN_TASK_COUNT_THRESHOLD=1
MAX_TASK_COUNT_THRESHOLD=50
MIN_FILE_REFERENCE_THRESHOLD=1
MAX_FILE_REFERENCE_THRESHOLD=100
MIN_REPLAN_LIMIT=1
MAX_REPLAN_LIMIT=5

# Extract thresholds from CLAUDE.md file
#
# Args:
#   $1 - Path to CLAUDE.md file
#
# Returns:
#   Sets global variables: EXPANSION_THRESHOLD, TASK_COUNT_THRESHOLD, etc.
#   Returns 0 if section found, 1 if not found
extract_thresholds_from_file() {
  local claude_file="$1"

  if [ ! -f "$claude_file" ]; then
    return 1
  fi

  # Extract adaptive_planning_config section
  local section_content
  section_content=$(sed -n '/<!-- SECTION: adaptive_planning_config -->/,/<!-- END_SECTION: adaptive_planning_config -->/p' "$claude_file")

  if [ -z "$section_content" ]; then
    # Section not found
    return 1
  fi

  # Extract individual threshold values
  # Pattern: "- **Expansion Threshold**: 8.0" (only lines starting with "- **", not example text)

  local expansion_val
  expansion_val=$(echo "$section_content" | grep "^- \*\*Expansion Threshold\*\*:" | grep -oE '[0-9]+\.[0-9]+' | head -n 1)

  local task_count_val
  task_count_val=$(echo "$section_content" | grep "^- \*\*Task Count Threshold\*\*:" | grep -oE '[0-9]+' | head -n 1)

  local file_ref_val
  file_ref_val=$(echo "$section_content" | grep "^- \*\*File Reference Threshold\*\*:" | grep -oE '[0-9]+' | head -n 1)

  local replan_val
  replan_val=$(echo "$section_content" | grep "^- \*\*Replan Limit\*\*:" | grep -oE '[0-9]+' | head -n 1)

  # Set extracted values (only if found)
  [ -n "$expansion_val" ] && EXPANSION_THRESHOLD="$expansion_val"
  [ -n "$task_count_val" ] && TASK_COUNT_THRESHOLD="$task_count_val"
  [ -n "$file_ref_val" ] && FILE_REFERENCE_THRESHOLD="$file_ref_val"
  [ -n "$replan_val" ] && REPLAN_LIMIT="$replan_val"

  return 0
}

# Validate threshold value is within acceptable range
#
# Args:
#   $1 - Threshold name (for error messages)
#   $2 - Threshold value
#   $3 - Minimum valid value
#   $4 - Maximum valid value
#
# Returns:
#   0 if valid, 1 if invalid (prints warning to stderr)
validate_threshold() {
  local name="$1"
  local value="$2"
  local min="$3"
  local max="$4"

  # Handle floating-point comparison for expansion_threshold
  if [[ "$name" == "expansion_threshold" ]]; then
    # Use awk for floating-point comparison (no bc dependency)
    if awk -v val="$value" -v min="$min" -v max="$max" 'BEGIN { if (val < min || val > max) exit 1; exit 0 }'; then
      : # Valid
    else
      echo "WARNING: $name value $value is out of range [$min, $max], using default" >&2
      return 1
    fi
  else
    # Integer comparison
    if [ "$value" -lt "$min" ] || [ "$value" -gt "$max" ]; then
      echo "WARNING: $name value $value is out of range [$min, $max], using default" >&2
      return 1
    fi
  fi

  return 0
}

# Find CLAUDE.md files from starting directory upward to project root
#
# Args:
#   $1 - Starting directory (optional, defaults to current directory)
#
# Returns:
#   Array of CLAUDE.md file paths (from most specific to most general)
#   Outputs to stdout: one path per line
find_claude_md_files() {
  local start_dir="${1:-.}"
  local current_dir
  current_dir=$(cd "$start_dir" && pwd)
  local claude_files=()

  # Search upward until we reach root or find .git directory (project root)
  while [ "$current_dir" != "/" ]; do
    # Check for CLAUDE.md in current directory
    if [ -f "$current_dir/CLAUDE.md" ]; then
      claude_files+=("$current_dir/CLAUDE.md")
    fi

    # Stop at project root (.git directory)
    if [ -d "$current_dir/.git" ]; then
      break
    fi

    # Move up one directory
    current_dir=$(dirname "$current_dir")
  done

  # Output paths (most specific first)
  for file in "${claude_files[@]}"; do
    echo "$file"
  done
}

# Get complexity thresholds with subdirectory override support
#
# Args:
#   $1 - Starting directory (optional, defaults to current directory)
#
# Outputs to stdout:
#   EXPANSION_THRESHOLD=8.0
#   TASK_COUNT_THRESHOLD=10
#   FILE_REFERENCE_THRESHOLD=10
#   REPLAN_LIMIT=2
#   THRESHOLDS_SOURCE="/path/to/CLAUDE.md"
#
# Sets global variables with same names
get_complexity_thresholds() {
  local start_dir="${1:-.}"

  # Initialize with defaults
  EXPANSION_THRESHOLD="$DEFAULT_EXPANSION_THRESHOLD"
  TASK_COUNT_THRESHOLD="$DEFAULT_TASK_COUNT_THRESHOLD"
  FILE_REFERENCE_THRESHOLD="$DEFAULT_FILE_REFERENCE_THRESHOLD"
  REPLAN_LIMIT="$DEFAULT_REPLAN_LIMIT"
  THRESHOLDS_SOURCE="defaults"

  # Find all CLAUDE.md files in hierarchy (most specific to most general)
  local claude_files
  mapfile -t claude_files < <(find_claude_md_files "$start_dir")

  if [ ${#claude_files[@]} -eq 0 ]; then
    # No CLAUDE.md found, use defaults
    echo "# No CLAUDE.md found, using default thresholds" >&2
    THRESHOLDS_SOURCE="defaults"
  else
    # Process files from most general to most specific (reverse order)
    # This allows subdirectory overrides to take precedence
    local i
    for ((i=${#claude_files[@]}-1; i>=0; i--)); do
      local claude_file="${claude_files[$i]}"

      if extract_thresholds_from_file "$claude_file"; then
        THRESHOLDS_SOURCE="$claude_file"
        echo "# Loaded thresholds from: $claude_file" >&2
      fi
    done
  fi

  # Validate thresholds and revert to defaults if invalid
  if ! validate_threshold "expansion_threshold" "$EXPANSION_THRESHOLD" "$MIN_EXPANSION_THRESHOLD" "$MAX_EXPANSION_THRESHOLD"; then
    EXPANSION_THRESHOLD="$DEFAULT_EXPANSION_THRESHOLD"
  fi

  if ! validate_threshold "task_count_threshold" "$TASK_COUNT_THRESHOLD" "$MIN_TASK_COUNT_THRESHOLD" "$MAX_TASK_COUNT_THRESHOLD"; then
    TASK_COUNT_THRESHOLD="$DEFAULT_TASK_COUNT_THRESHOLD"
  fi

  if ! validate_threshold "file_reference_threshold" "$FILE_REFERENCE_THRESHOLD" "$MIN_FILE_REFERENCE_THRESHOLD" "$MAX_FILE_REFERENCE_THRESHOLD"; then
    FILE_REFERENCE_THRESHOLD="$DEFAULT_FILE_REFERENCE_THRESHOLD"
  fi

  if ! validate_threshold "replan_limit" "$REPLAN_LIMIT" "$MIN_REPLAN_LIMIT" "$MAX_REPLAN_LIMIT"; then
    REPLAN_LIMIT="$DEFAULT_REPLAN_LIMIT"
  fi

  # Output threshold values (for sourcing or eval)
  echo "EXPANSION_THRESHOLD=$EXPANSION_THRESHOLD"
  echo "TASK_COUNT_THRESHOLD=$TASK_COUNT_THRESHOLD"
  echo "FILE_REFERENCE_THRESHOLD=$FILE_REFERENCE_THRESHOLD"
  echo "REPLAN_LIMIT=$REPLAN_LIMIT"
  echo "THRESHOLDS_SOURCE=\"$THRESHOLDS_SOURCE\""
}

# Main execution when script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  # Script is being executed, not sourced
  get_complexity_thresholds "$@"
fi

# Usage Examples:
#
# Example 1: Source and call function
#   source .claude/lib/complexity-thresholds.sh
#   get_complexity_thresholds /path/to/project
#   echo "Expansion threshold: $EXPANSION_THRESHOLD"
#
# Example 2: Execute directly and capture output
#   thresholds=$(.claude/lib/complexity-thresholds.sh /path/to/project)
#   eval "$thresholds"
#   echo "Task count threshold: $TASK_COUNT_THRESHOLD"
#
# Example 3: Use in orchestrate.md
#   # Load thresholds
#   source ${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-thresholds.sh
#   get_complexity_thresholds "$(dirname "$IMPLEMENTATION_PLAN_PATH")"
#
#   # Thresholds now available:
#   echo "Using expansion threshold: $EXPANSION_THRESHOLD"
#   echo "Source: $THRESHOLDS_SOURCE"
