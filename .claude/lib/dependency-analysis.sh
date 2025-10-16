#!/bin/bash
# Dependency Analysis Utilities
#
# This library provides dependency parsing and wave-based execution planning
# for orchestration workflows. It replaces the deprecated parse-phase-dependencies.sh
# utility with enhanced topological sorting and circular dependency detection.
#
# Functions:
#   parse_dependencies()           - Extract dependencies from phase metadata
#   calculate_execution_waves()    - Calculate execution waves using Kahn's algorithm
#   detect_circular_dependencies() - Detect circular dependencies in phase graph
#   validate_dependencies()        - Validate dependency references
#
# Usage:
#   source .claude/lib/dependency-analysis.sh
#   parse_dependencies "plan_file.md" "phase_number"
#   calculate_execution_waves "plan_file.md"

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh" || {
  echo "ERROR: Failed to source base-utils.sh" >&2
  exit 1
}

source "${SCRIPT_DIR}/plan-core-bundle.sh" || {
  error "Failed to source plan-core-bundle.sh"
  exit 1
}

# Parse dependencies from phase metadata
#
# Extracts the Dependencies field from a phase header and returns
# a space-separated list of phase numbers.
#
# Args:
#   $1 - Plan file path
#   $2 - Phase number
#
# Returns:
#   Space-separated list of phase numbers (e.g., "1 2 3")
#   Empty string if no dependencies or [] notation
#
# Dependency Syntax:
#   Dependencies: []        - No dependencies (independent phase)
#   Dependencies: [1]       - Depends on phase 1
#   Dependencies: [1, 2, 3] - Depends on phases 1, 2, and 3
#
# Example:
#   deps=$(parse_dependencies "plan.md" 3)
#   echo "Phase 3 depends on: $deps"
#
parse_dependencies() {
  local plan_file="$1"
  local phase_number="$2"

  if [[ ! -f "$plan_file" ]]; then
    error "Plan file not found: $plan_file"
    return 1
  fi

  # Extract phase content using plan-core-bundle.sh
  local phase_content
  phase_content=$(extract_phase_content "$plan_file" "$phase_number") || {
    error "Failed to extract phase $phase_number from $plan_file"
    return 1
  }

  # Look for Dependencies field in phase metadata
  # Format: **Dependencies**: [1, 2, 3] or Dependencies: []
  local deps_line
  deps_line=$(echo "$phase_content" | grep -m1 "^\*\*Dependencies\*\*:" | head -1)

  if [[ -z "$deps_line" ]]; then
    # No Dependencies field found - assume independent
    echo ""
    return 0
  fi

  # Extract dependency list from brackets
  local deps_raw
  deps_raw=$(echo "$deps_line" | sed -n 's/^\*\*Dependencies\*\*: *\[\(.*\)\]/\1/p')

  if [[ -z "$deps_raw" ]]; then
    # Empty brackets [] - no dependencies
    echo ""
    return 0
  fi

  # Convert comma-separated list to space-separated
  # Remove whitespace and convert commas to spaces
  local deps_clean
  deps_clean=$(echo "$deps_raw" | tr ',' ' ' | tr -s ' ')

  echo "$deps_clean"
}

# Calculate execution waves using Kahn's algorithm
#
# Performs topological sorting to group phases into execution waves.
# Phases in the same wave are independent and can execute in parallel.
#
# Args:
#   $1 - Plan file path
#
# Returns:
#   JSON array of waves, where each wave is an array of phase numbers
#   Example: [[1,2],[3,4],[5]]
#
# Algorithm:
#   1. Parse all phase dependencies
#   2. Build adjacency list and in-degree map
#   3. Use Kahn's algorithm for topological sort
#   4. Group phases with same topological level into waves
#   5. Detect circular dependencies (if any phases remain)
#
# Example:
#   waves=$(calculate_execution_waves "plan.md")
#   echo "Execution waves: $waves"
#
calculate_execution_waves() {
  local plan_file="$1"

  if [[ ! -f "$plan_file" ]]; then
    error "Plan file not found: $plan_file"
    return 1
  fi

  # Get total number of phases by counting phase headers
  local phase_count
  phase_count=$(grep -c "^### Phase [0-9]" "$plan_file" 2>/dev/null || echo "0")

  if [[ $phase_count -eq 0 ]]; then
    error "No phases found in plan file: $plan_file"
    return 1
  fi

  # Build dependency graph
  # in_degree[phase] = number of dependencies
  # adjacency[phase] = space-separated list of dependent phases
  declare -A in_degree
  declare -A adjacency

  # Initialize all phases
  for phase_num in $(seq 1 "$phase_count"); do
    in_degree[$phase_num]=0
    adjacency[$phase_num]=""
  done

  # Parse dependencies for each phase
  for phase_num in $(seq 1 "$phase_count"); do
    local deps
    deps=$(parse_dependencies "$plan_file" "$phase_num")

    if [[ -n "$deps" ]]; then
      # Count dependencies
      local dep_count
      dep_count=$(echo "$deps" | wc -w)
      in_degree[$phase_num]=$dep_count

      # Build adjacency list (reverse edges: from dependency to dependent)
      for dep in $deps; do
        if [[ -n "${adjacency[$dep]}" ]]; then
          adjacency[$dep]="${adjacency[$dep]} $phase_num"
        else
          adjacency[$dep]="$phase_num"
        fi
      done
    fi
  done

  # Kahn's algorithm for topological sort
  local -a waves
  local -a processed  # Track processed phases across waves
  local wave_index=0
  local remaining=$phase_count

  while [[ $remaining -gt 0 ]]; do
    # Find all phases with in_degree == 0 (current wave)
    local current_wave=""
    for phase_num in $(seq 1 "$phase_count"); do
      if [[ ${in_degree[$phase_num]} -eq 0 ]] && [[ ! " ${processed[@]} " =~ " ${phase_num} " ]]; then
        current_wave="$current_wave $phase_num"
      fi
    done

    # Remove leading/trailing whitespace
    current_wave=$(echo "$current_wave" | xargs)

    if [[ -z "$current_wave" ]]; then
      # No phases with in_degree 0 - circular dependency detected
      echo "ERROR: Circular dependency detected in plan: $plan_file" >&2

      # Report remaining phases
      local remaining_phases=""
      for phase_num in $(seq 1 "$phase_count"); do
        if [[ ! " ${processed[@]} " =~ " ${phase_num} " ]]; then
          remaining_phases="$remaining_phases $phase_num"
        fi
      done
      echo "ERROR: Phases involved in cycle: $remaining_phases" >&2
      return 1
    fi

    # Add current wave to output
    waves[$wave_index]="$current_wave"
    wave_index=$((wave_index + 1))

    # Mark phases as processed and update in_degrees
    for phase_num in $current_wave; do
      processed+=("$phase_num")
      remaining=$((remaining - 1))

      # Reduce in_degree for dependent phases
      local dependents="${adjacency[$phase_num]}"
      for dependent in $dependents; do
        in_degree[$dependent]=$((in_degree[$dependent] - 1))
      done
    done
  done

  # Convert waves array to JSON format
  local json_output="["
  for i in $(seq 0 $((wave_index - 1))); do
    if [[ $i -gt 0 ]]; then
      json_output="$json_output,"
    fi

    local wave="${waves[$i]}"
    local wave_json="["
    local first=true
    for phase in $wave; do
      if [[ $first == true ]]; then
        wave_json="$wave_json$phase"
        first=false
      else
        wave_json="$wave_json,$phase"
      fi
    done
    wave_json="$wave_json]"

    json_output="$json_output$wave_json"
  done
  json_output="$json_output]"

  echo "$json_output"
}

# Detect circular dependencies in phase graph
#
# Uses depth-first search to detect cycles in the dependency graph.
#
# Args:
#   $1 - Plan file path
#
# Returns:
#   0 if no circular dependencies
#   1 if circular dependencies detected
#
# Example:
#   if detect_circular_dependencies "plan.md"; then
#     echo "No circular dependencies"
#   else
#     echo "Circular dependencies detected"
#   fi
#
detect_circular_dependencies() {
  local plan_file="$1"

  if [[ ! -f "$plan_file" ]]; then
    error "Plan file not found: $plan_file"
    return 1
  fi

  # Use calculate_execution_waves to detect cycles
  # If it succeeds, no cycles exist
  local waves
  waves=$(calculate_execution_waves "$plan_file" 2>/dev/null)

  if [[ $? -eq 0 ]]; then
    return 0  # No circular dependencies
  else
    return 1  # Circular dependencies detected
  fi
}

# Validate dependency references
#
# Checks that all dependency references point to valid phase numbers
# and that phases don't depend on themselves.
#
# Args:
#   $1 - Plan file path
#
# Returns:
#   0 if all dependencies are valid
#   1 if invalid dependencies found
#
# Example:
#   if validate_dependencies "plan.md"; then
#     echo "All dependencies valid"
#   else
#     echo "Invalid dependencies found"
#   fi
#
validate_dependencies() {
  local plan_file="$1"

  if [[ ! -f "$plan_file" ]]; then
    error "Plan file not found: $plan_file"
    return 1
  fi

  # Get total number of phases by counting phase headers
  local phase_count
  phase_count=$(grep -c "^### Phase [0-9]" "$plan_file" 2>/dev/null || echo "0")

  if [[ $phase_count -eq 0 ]]; then
    error "No phases found in plan file: $plan_file"
    return 1
  fi

  local has_errors=false

  # Check each phase's dependencies
  for phase_num in $(seq 1 "$phase_count"); do
    local deps
    deps=$(parse_dependencies "$plan_file" "$phase_num")

    if [[ -n "$deps" ]]; then
      for dep in $deps; do
        # Check if dependency is a valid number
        if ! [[ "$dep" =~ ^[0-9]+$ ]]; then
          error "Phase $phase_num: Invalid dependency '$dep' (not a number)"
          has_errors=true
          continue
        fi

        # Check if dependency is in valid range
        if [[ $dep -lt 1 ]] || [[ $dep -gt $phase_count ]]; then
          error "Phase $phase_num: Invalid dependency $dep (out of range 1-$phase_count)"
          has_errors=true
          continue
        fi

        # Check for self-dependency
        if [[ $dep -eq $phase_num ]]; then
          error "Phase $phase_num: Cannot depend on itself"
          has_errors=true
          continue
        fi
      done
    fi
  done

  if [[ $has_errors == true ]]; then
    return 1
  fi

  return 0
}

# Export functions for external use
export -f parse_dependencies
export -f calculate_execution_waves
export -f detect_circular_dependencies
export -f validate_dependencies
