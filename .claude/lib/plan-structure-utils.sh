#!/usr/bin/env bash
# Plan Structure Detection and Navigation
# Provides functions for detecting and navigating progressive plan structures
# Usage: Source this file to use structure navigation functions

set -e

# Source error handling from parse-plan-core if needed
if ! declare -f error > /dev/null 2>&1; then
  error() {
    echo "Error: $*" >&2
    exit 1
  }
fi

# Detect structure level for progressive plans (0=single file, 1=phase files, 2=stage files)
# Usage: detect_structure_level <plan_path>
detect_structure_level() {
  local plan_path="$1"

  # If plan is a single file (not in directory) -> Level 0
  if [[ "$plan_path" == *.md ]] && [[ -f "$plan_path" ]]; then
    local plan_dir=$(dirname "$plan_path")
    local plan_base=$(basename "$plan_path" .md)

    # Check if directory exists for this plan
    if [[ -d "$plan_dir/$plan_base" ]]; then
      # Plan has been expanded to directory
      plan_path="$plan_dir/$plan_base"
    else
      # Pure single file - Level 0
      echo "0"
      return 0
    fi
  fi

  # If path is a directory, check for phase/stage expansions
  if [[ -d "$plan_path" ]]; then
    local plan_name=$(basename "$plan_path")

    # Check for phase directories (indicates Level 2)
    if find "$plan_path" -maxdepth 1 -type d -name "phase_*" | grep -q .; then
      echo "2"
      return 0
    fi

    # Check for phase files (indicates Level 1)
    if find "$plan_path" -maxdepth 1 -type f -name "phase_*.md" | grep -q .; then
      echo "1"
      return 0
    fi

    # Directory exists but no expansions found - check metadata
    local overview="$plan_path/$plan_name.md"
    if [[ -f "$overview" ]]; then
      if grep -q "^- \*\*Structure Level\*\*: 2" "$overview" 2>/dev/null; then
        echo "2"
        return 0
      elif grep -q "^- \*\*Structure Level\*\*: 1" "$overview" 2>/dev/null; then
        echo "1"
        return 0
      elif grep -q "^- \*\*Structure Level\*\*: 0" "$overview" 2>/dev/null; then
        echo "0"
        return 0
      fi
    fi

    # Fallback: directory exists but unclear - assume Level 0
    echo "0"
    return 0
  fi

  error "Invalid plan path: $plan_path"
}

# Check if plan has been expanded (has directory)
# Usage: is_plan_expanded <plan_path>
# Returns: "true" or "false"
is_plan_expanded() {
  local plan_path="$1"

  # If plan is a file
  if [[ "$plan_path" == *.md ]] && [[ -f "$plan_path" ]]; then
    local plan_dir=$(dirname "$plan_path")
    local plan_base=$(basename "$plan_path" .md)

    # Check if directory exists
    if [[ -d "$plan_dir/$plan_base" ]]; then
      echo "true"
      return 0
    else
      echo "false"
      return 0
    fi
  fi

  # If plan is already a directory path
  if [[ -d "$plan_path" ]]; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Get plan directory if expanded, empty string if not
# Usage: get_plan_directory <plan_path>
get_plan_directory() {
  local plan_path="$1"

  # If plan is a file
  if [[ "$plan_path" == *.md ]] && [[ -f "$plan_path" ]]; then
    local plan_dir=$(dirname "$plan_path")
    local plan_base=$(basename "$plan_path" .md)

    # Check if directory exists
    if [[ -d "$plan_dir/$plan_base" ]]; then
      echo "$plan_dir/$plan_base"
      return 0
    else
      echo ""
      return 1
    fi
  fi

  # If plan is already a directory
  if [[ -d "$plan_path" ]]; then
    echo "$plan_path"
    return 0
  fi

  echo ""
  return 1
}

# Check if specific phase is expanded (has file or directory)
# Usage: is_phase_expanded <plan_path> <phase_num>
# Returns: "true" or "false"
is_phase_expanded() {
  local plan_path="$1"
  local phase_num="$2"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    # Plan not expanded, so phases can't be expanded
    echo "false"
    return 0
  fi

  # Check for phase file
  if find "$plan_dir" -maxdepth 1 -type f -name "phase_${phase_num}_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  # Check for phase directory
  if find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Get phase file path if expanded, empty string if not
# Usage: get_phase_file <plan_path> <phase_num>
get_phase_file() {
  local plan_path="$1"
  local phase_num="$2"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    echo ""
    return 1
  fi

  # Check for phase directory first (takes precedence)
  local phase_dir=$(find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" 2>/dev/null | head -1)
  if [[ -n "$phase_dir" ]]; then
    # Phase is in directory - return phase file inside directory
    local phase_file=$(find "$phase_dir" -maxdepth 1 -type f -name "phase_${phase_num}_*.md" 2>/dev/null | head -1)
    if [[ -n "$phase_file" ]]; then
      echo "$phase_file"
      return 0
    fi
  fi

  # Check for phase file in plan directory
  local phase_file=$(find "$plan_dir" -maxdepth 1 -type f -name "phase_${phase_num}_*.md" 2>/dev/null | head -1)
  if [[ -n "$phase_file" ]]; then
    echo "$phase_file"
    return 0
  fi

  echo ""
  return 1
}

# Check if specific stage is expanded (has file)
# Usage: is_stage_expanded <plan_path> <phase_num> <stage_num>
# Returns: "true" or "false"
is_stage_expanded() {
  local plan_path="$1"
  local phase_num="$2"
  local stage_num="$3"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    echo "false"
    return 0
  fi

  # Get phase directory
  local phase_dir=$(find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" 2>/dev/null | head -1)
  if [[ -z "$phase_dir" ]]; then
    # Phase not in directory, so stages can't be expanded
    echo "false"
    return 0
  fi

  # Check for stage file in phase directory
  if find "$phase_dir" -maxdepth 1 -type f -name "stage_${stage_num}_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# List expanded phase numbers
# Usage: list_expanded_phases <plan_path>
# Returns: space-separated list of phase numbers
list_expanded_phases() {
  local plan_path="$1"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    # Plan not expanded
    echo ""
    return 0
  fi

  # Find all phase files and directories
  local phases=""

  # Phase files
  for file in "$plan_dir"/phase_*_*.md; do
    if [[ -f "$file" ]]; then
      local filename=$(basename "$file" .md)
      local phase_num=$(echo "$filename" | sed 's/^phase_\([0-9]*\)_.*/\1/')
      phases="$phases $phase_num"
    fi
  done

  # Phase directories
  for dir in "$plan_dir"/phase_*; do
    if [[ -d "$dir" ]]; then
      local dirname=$(basename "$dir")
      local phase_num=$(echo "$dirname" | sed 's/^phase_\([0-9]*\)_.*/\1/')
      # Avoid duplicates
      if [[ ! "$phases" =~ (^| )$phase_num( |$) ]]; then
        phases="$phases $phase_num"
      fi
    fi
  done

  # Sort and output
  echo "$phases" | tr ' ' '\n' | grep -v '^$' | sort -n | tr '\n' ' ' | sed 's/ $//'
}

# List expanded stage numbers for a phase
# Usage: list_expanded_stages <plan_path> <phase_num>
# Returns: space-separated list of stage numbers
list_expanded_stages() {
  local plan_path="$1"
  local phase_num="$2"

  local plan_dir=$(get_plan_directory "$plan_path")
  if [[ -z "$plan_dir" ]]; then
    echo ""
    return 0
  fi

  # Get phase directory
  local phase_dir=$(find "$plan_dir" -maxdepth 1 -type d -name "phase_${phase_num}_*" 2>/dev/null | head -1)
  if [[ -z "$phase_dir" ]]; then
    # Phase not in directory
    echo ""
    return 0
  fi

  # Find all stage files
  local stages=""
  for file in "$phase_dir"/stage_*_*.md; do
    if [[ -f "$file" ]]; then
      local filename=$(basename "$file" .md)
      local stage_num=$(echo "$filename" | sed 's/^stage_\([0-9]*\)_.*/\1/')
      stages="$stages $stage_num"
    fi
  done

  # Sort and output
  echo "$stages" | tr ' ' '\n' | grep -v '^$' | sort -n | tr '\n' ' ' | sed 's/ $//'
}

# Check if directory has any remaining phase files/directories
# Usage: has_remaining_phases <plan_dir>
# Returns: "true" or "false"
has_remaining_phases() {
  local plan_dir="$1"

  # Check for phase files (not the main plan)
  local plan_name=$(basename "$plan_dir")
  if find "$plan_dir" -maxdepth 1 -type f -name "phase_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  # Check for phase directories
  if find "$plan_dir" -maxdepth 1 -type d -name "phase_*" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Check if phase directory has any remaining stage files
# Usage: has_remaining_stages <phase_dir>
# Returns: "true" or "false"
has_remaining_stages() {
  local phase_dir="$1"

  if find "$phase_dir" -maxdepth 1 -type f -name "stage_*.md" | grep -q .; then
    echo "true"
    return 0
  fi

  echo "false"
  return 0
}

# Move plan file back to parent and delete directory (Level 1 → 0)
# Usage: cleanup_plan_directory <plan_dir>
cleanup_plan_directory() {
  local plan_dir="$1"
  local plan_name=$(basename "$plan_dir")
  local plan_file="$plan_dir/$plan_name.md"
  local parent_dir=$(dirname "$plan_dir")
  local target_file="$parent_dir/$plan_name.md"

  # Move plan file to parent
  mv "$plan_file" "$target_file"

  # Delete empty directory
  rmdir "$plan_dir"

  echo "$target_file"
}

# Move phase file back to parent and delete directory (Level 2 → 1)
# Usage: cleanup_phase_directory <phase_dir>
cleanup_phase_directory() {
  local phase_dir="$1"
  local phase_name=$(basename "$phase_dir")
  local phase_file="$phase_dir/$phase_name.md"
  local parent_dir=$(dirname "$phase_dir")
  local target_file="$parent_dir/$phase_name.md"

  # Move phase file to parent
  mv "$phase_file" "$target_file"

  # Delete empty directory
  rmdir "$phase_dir"

  echo "$target_file"
}

# Export functions for sourcing
export -f error
export -f detect_structure_level
export -f is_plan_expanded
export -f get_plan_directory
export -f is_phase_expanded
export -f get_phase_file
export -f is_stage_expanded
export -f list_expanded_phases
export -f list_expanded_stages
export -f has_remaining_phases
export -f has_remaining_stages
export -f cleanup_plan_directory
export -f cleanup_phase_directory
