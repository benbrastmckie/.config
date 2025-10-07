#!/usr/bin/env bash
# Parse phase dependencies from plan file and generate execution waves
# Usage: parse-phase-dependencies.sh <plan-file>

set -euo pipefail

PLAN_FILE="${1:-}"

if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "Usage: parse-phase-dependencies.sh <plan-file>" >&2
  echo "Error: Plan file not found or not specified" >&2
  exit 1
fi

# Extract phase metadata (number, name, dependencies)
# Output format: phase_number|phase_name|dep1,dep2,dep3
extract_phases() {
  local in_phase=false
  local phase_num=""
  local phase_name=""
  local dependencies=""

  while IFS= read -r line; do
    # Detect phase header (### Phase N: Name)
    if [[ "$line" =~ ^###[[:space:]]+Phase[[:space:]]+([0-9]+):[[:space:]]*(.+)$ ]]; then
      # Output previous phase if exists
      if [ -n "$phase_num" ]; then
        echo "${phase_num}|${phase_name}|${dependencies}"
      fi

      # Start new phase
      phase_num="${BASH_REMATCH[1]}"
      phase_name="${BASH_REMATCH[2]}"
      dependencies=""
      in_phase=true

    # Detect dependencies line
    elif [[ "$in_phase" == "true" && "$line" =~ ^dependencies:[[:space:]]*\[([0-9,[:space:]]*)\] ]]; then
      dependencies="${BASH_REMATCH[1]}"
      # Clean up whitespace
      dependencies=$(echo "$dependencies" | tr -d ' ')

    # End of phase section (next ### or end of file)
    elif [[ "$line" =~ ^### && "$in_phase" == "true" && ! "$line" =~ ^###[[:space:]]+Phase ]]; then
      in_phase=false
    fi
  done < "$PLAN_FILE"

  # Output last phase
  if [ -n "$phase_num" ]; then
    echo "${phase_num}|${phase_name}|${dependencies}"
  fi
}

# Build adjacency list and compute in-degrees
# Input: phase_number|phase_name|dep1,dep2,dep3 (one per line)
# Output: Execution waves (phases grouped by dependency level)
build_execution_waves() {
  local -A in_degree
  local -A phase_names
  local -A dependencies
  local all_phases=()
  local input_data

  # Read all input into variable
  input_data=$(cat)

  # Parse input and build data structures
  while IFS='|' read -r num name deps; do
    all_phases+=("$num")
    phase_names["$num"]="$name"
    dependencies["$num"]="$deps"

    # Initialize in-degree
    in_degree["$num"]=0
  done <<< "$input_data"

  # Calculate in-degrees
  for num in "${all_phases[@]}"; do
    if [ -n "${dependencies[$num]}" ]; then
      IFS=',' read -ra dep_array <<< "${dependencies[$num]}"
      in_degree["$num"]="${#dep_array[@]}"
    fi
  done

  # Topological sort using Kahn's algorithm
  local wave=1
  local remaining=("${all_phases[@]}")

  while (( ${#remaining[@]} > 0 )); do
    local current_wave=()

    # Find all phases with in-degree 0
    for num in "${remaining[@]}"; do
      if [ "${in_degree[$num]}" -eq 0 ]; then
        current_wave+=("$num")
      fi
    done

    if (( ${#current_wave[@]} == 0 )); then
      echo "ERROR: Circular dependency detected!" >&2
      echo "Remaining phases: ${remaining[*]}" >&2
      exit 1
    fi

    # Output wave
    echo "WAVE_${wave}:${current_wave[*]}"

    # Remove current wave from remaining
    local new_remaining=()
    for num in "${remaining[@]}"; do
      local in_wave=false
      for wave_num in "${current_wave[@]}"; do
        if [ "$num" -eq "$wave_num" ]; then
          in_wave=true
          break
        fi
      done
      if [ "$in_wave" == "false" ]; then
        new_remaining+=("$num")
      fi
    done
    remaining=("${new_remaining[@]}")

    # Decrement in-degrees for phases that depended on current wave
    for removed_num in "${current_wave[@]}"; do
      for num in "${remaining[@]}"; do
        if [ -n "${dependencies[$num]}" ]; then
          # Check if $num depends on $removed_num
          IFS=',' read -ra dep_array <<< "${dependencies[$num]}"
          for dep in "${dep_array[@]}"; do
            if [ "$dep" -eq "$removed_num" ]; then
              in_degree["$num"]=$((in_degree[$num] - 1))
            fi
          done
        fi
      done
    done

    wave=$((wave + 1))
  done
}

# Validate dependencies
validate_dependencies() {
  local -A phase_exists
  local all_phases=()

  # First pass: collect all phase numbers
  while IFS='|' read -r num name deps; do
    phase_exists["$num"]=1
    all_phases+=("$num")
  done

  # Second pass: validate dependency references
  for num in "${all_phases[@]}"; do
    local deps="${dependencies[$num]:-}"
    if [ -n "$deps" ]; then
      IFS=',' read -ra dep_array <<< "$deps"
      for dep in "${dep_array[@]}"; do
        if [ -z "${phase_exists[$dep]:-}" ]; then
          echo "ERROR: Phase $num depends on non-existent Phase $dep" >&2
          return 1
        fi
        if [ "$dep" -eq "$num" ]; then
          echo "ERROR: Phase $num has self-dependency" >&2
          return 1
        fi
      done
    fi
  done

  return 0
}

# Main execution
phases=$(extract_phases)

if [ -z "$phases" ]; then
  echo "ERROR: No phases found in plan file" >&2
  exit 1
fi

# Validate and build waves
echo "$phases" | build_execution_waves
