#!/usr/bin/env bash
# .claude/lib/plan/dependency-recalculation.sh
# Recalculates wave dependencies after partial completion or plan revision
#
# This utility provides functions to:
# 1. Identify phases ready for execution based on completed dependencies
# 2. Recalculate execution waves after partial completion
# 3. Support L0/L1/L2 plan structures (tier-agnostic)
#
# Usage:
#   source .claude/lib/plan/dependency-recalculation.sh
#   next_wave=$(recalculate_wave_dependencies "$plan_path" "$completed_phases")
#
# Functions:
#   - recalculate_wave_dependencies() - Returns space-separated list of next wave phases

set -euo pipefail

# Source guard
if [ -n "${DEPENDENCY_RECALC_SOURCED:-}" ]; then
  return 0
fi
export DEPENDENCY_RECALC_SOURCED=1

# Get script directory for sourcing dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# DEPENDENCY RECALCULATION
# ============================================================================

# Recalculate wave dependencies based on completed phases
# Returns space-separated list of phase numbers ready for execution
#
# Usage: recalculate_wave_dependencies <plan_path> <completed_phases>
#
# Arguments:
#   plan_path - Absolute path to plan file
#   completed_phases - Space-separated list of completed phase numbers
#
# Output:
#   Space-separated list of phase numbers whose dependencies are satisfied
#
# Example:
#   completed="1 2"
#   next_wave=$(recalculate_wave_dependencies "/path/to/plan.md" "$completed")
#   # Returns: "3 4" (phases that depend only on 1,2)
recalculate_wave_dependencies() {
  local plan_path="$1"
  local completed_phases="${2:-}"

  if [[ ! -f "$plan_path" ]]; then
    echo "ERROR: Plan file not found: $plan_path" >&2
    return 1
  fi

  # Source plan-core-bundle for phase parsing
  if [[ ! -f "$SCRIPT_DIR/plan-core-bundle.sh" ]]; then
    echo "ERROR: Cannot load plan-core-bundle.sh" >&2
    return 1
  fi
  source "$SCRIPT_DIR/plan-core-bundle.sh" 2>/dev/null

  # Detect plan structure level
  local structure_level
  structure_level=$(detect_structure_level "$plan_path")

  # Get all phase numbers based on structure level
  local all_phases=()
  case "$structure_level" in
    0)
      # L0: Inline plan - extract from main file
      all_phases=($(grep -oE "^##+ Phase ([0-9.]+)" "$plan_path" | grep -oE "[0-9.]+" | sort -V))
      ;;
    1|2)
      # L1/L2: Hierarchical plan - extract from phase files
      local plan_dir
      plan_dir="$(dirname "$plan_path")/$(basename "$plan_path" .md)"
      if [[ -d "$plan_dir" ]]; then
        all_phases=($(find "$plan_dir" -maxdepth 1 -name "phase_*.md" | sed -E 's/.*phase_([0-9.]+).*/\1/' | sort -V))
      fi
      ;;
  esac

  if [[ ${#all_phases[@]} -eq 0 ]]; then
    echo "" # No phases found
    return 0
  fi

  # Build dependency map and status map
  declare -A phase_deps
  declare -A phase_status

  for phase_num in "${all_phases[@]}"; do
    # Get dependencies for this phase
    local deps=""
    case "$structure_level" in
      0)
        # L0: Extract from main file
        deps=$(extract_phase_dependencies "$plan_path" "$phase_num")
        phase_status[$phase_num]=$(get_phase_status_inline "$plan_path" "$phase_num")
        ;;
      1|2)
        # L1/L2: Extract from phase file
        local phase_file="$plan_dir/phase_${phase_num}.md"
        if [[ -f "$phase_file" ]]; then
          deps=$(extract_phase_dependencies "$phase_file" "$phase_num")
          phase_status[$phase_num]=$(get_phase_status_inline "$phase_file" "$phase_num")
        fi
        ;;
    esac

    phase_deps[$phase_num]="$deps"
  done

  # Identify next wave: phases with all dependencies satisfied
  local next_wave=""
  for phase_num in "${all_phases[@]}"; do
    # Skip if already completed (either in completed_phases or has [COMPLETE] marker)
    local status="${phase_status[$phase_num]:-}"
    if [[ " $completed_phases " =~ " $phase_num " ]] || [[ "$status" == "COMPLETE" ]]; then
      continue
    fi

    # Check if all dependencies are satisfied
    local deps="${phase_deps[$phase_num]:-}"
    local deps_satisfied=true

    if [[ -n "$deps" ]]; then
      # Parse dependency list (handles formats: "1", "1,2", "1 2")
      local dep_array=(${deps//,/ })

      for dep in "${dep_array[@]}"; do
        # Clean up dependency (remove brackets, whitespace)
        dep=$(echo "$dep" | tr -d '[] ' | sed 's/phase_//')

        # Check if dependency is satisfied (in completed list or has COMPLETE status)
        if [[ -n "$dep" ]]; then
          local dep_status="${phase_status[$dep]:-}"
          if ! [[ " $completed_phases " =~ " $dep " ]] && [[ "$dep_status" != "COMPLETE" ]]; then
            deps_satisfied=false
            break
          fi
        fi
      done
    fi

    if [[ "$deps_satisfied" == "true" ]]; then
      next_wave="$next_wave $phase_num"
    fi
  done

  # Trim leading/trailing whitespace
  next_wave=$(echo "$next_wave" | xargs)

  echo "$next_wave"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Extract phase dependencies from a file
# Returns space-separated list of phase numbers
extract_phase_dependencies() {
  local file_path="$1"
  local phase_num="$2"

  if [[ ! -f "$file_path" ]]; then
    echo ""
    return 0
  fi

  # Extract the phase section first, then look for depends_on
  # This avoids matching dependencies from other phases
  local phase_content
  phase_content=$(awk -v phase="$phase_num" '
    /^##+ Phase / {
      # Extract phase number from heading (field 3, may have colon)
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase) {
        in_phase = 1
        next
      } else if (in_phase) {
        exit
      }
    }
    /^## / && in_phase && !/^##+ Phase / {
      exit
    }
    in_phase { print }
  ' "$file_path")

  if [[ -z "$phase_content" ]]; then
    echo ""
    return 0
  fi

  # Extract depends_on metadata from phase content
  # Handles formats:
  #   - **Dependencies**: depends_on: [1, 2]
  #   - **Dependencies**: depends_on: []
  #   - depends_on: [phase_1, phase_2]
  local deps_line
  deps_line=$(echo "$phase_content" | grep -i "depends_on:" | head -1 || echo "")

  if [[ -z "$deps_line" ]]; then
    echo ""
    return 0
  fi

  # Extract content between brackets
  local deps_raw
  deps_raw=$(echo "$deps_line" | sed 's/.*depends_on: *\[\(.*\)\].*/\1/')

  # Clean up: remove "phase_" prefix, commas, extra whitespace
  local deps_clean
  deps_clean=$(echo "$deps_raw" | sed 's/phase_//g' | tr ',' ' ' | xargs)

  echo "$deps_clean"
}

# Get phase status from inline markers
# Returns: "COMPLETE", "IN_PROGRESS", "NOT_STARTED", or ""
get_phase_status_inline() {
  local file_path="$1"
  local phase_num="$2"

  if [[ ! -f "$file_path" ]]; then
    echo ""
    return 0
  fi

  # Look for phase heading with status marker
  local phase_line
  phase_line=$(grep -E "^##+ Phase ${phase_num}[^0-9]" "$file_path" | head -1 || echo "")

  if [[ -z "$phase_line" ]]; then
    echo ""
    return 0
  fi

  if [[ "$phase_line" =~ \[COMPLETE\] ]]; then
    echo "COMPLETE"
  elif [[ "$phase_line" =~ \[IN.PROGRESS\] ]]; then
    echo "IN_PROGRESS"
  elif [[ "$phase_line" =~ \[NOT.STARTED\] ]]; then
    echo "NOT_STARTED"
  else
    echo ""
  fi
}

# ============================================================================
# MAIN ENTRY POINT (for standalone execution)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script executed directly (not sourced)
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <plan_path> <completed_phases>"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/plan.md '1 2 3'"
    echo ""
    echo "Returns space-separated list of phase numbers ready for execution"
    exit 1
  fi

  plan_path="$1"
  completed_phases="$2"

  next_wave=$(recalculate_wave_dependencies "$plan_path" "$completed_phases")
  echo "$next_wave"
fi
