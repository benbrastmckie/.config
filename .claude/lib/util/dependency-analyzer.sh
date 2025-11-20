#!/usr/bin/env bash
# .claude/lib/util/dependency-analyzer.sh
# Builds dependency graphs and identifies execution waves from plan files
#
# This utility analyzes implementation plan files to:
# 1. Parse phase/stage dependency metadata
# 2. Build dependency graphs with topological sorting
# 3. Identify execution waves (groups of independent phases that can run in parallel)
# 4. Calculate parallelization metrics and time savings estimates
#
# Usage:
#  bash .claude/lib/util/dependency-analyzer.sh <plan_path>
#
# Output:
#  JSON structure with dependency graph, waves, and metrics

set -euo pipefail

# Source shared utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/shared-utilities.sh" ]]; then
  source "$SCRIPT_DIR/shared-utilities.sh"
fi

# ============================================================================
# PLAN STRUCTURE DETECTION
# ============================================================================

# Detect plan structure level (0=inline, 1=phase files, 2=stage files)
# Input: plan_path (top-level plan file)
# Output: structure level number
detect_structure_level() {
  local plan_path="$1"
  local plan_dir
  plan_dir=$(dirname "$plan_path")
  local plan_name
  plan_name=$(basename "$plan_path" .md)
  local plan_subdir="$plan_dir/$plan_name"

  # Check if plan directory exists
  if [[ ! -d "$plan_subdir" ]]; then
    echo "0" # Level 0: Inline plan
    return 0
  fi

  # Check for phase files
  if ls "$plan_subdir"/phase_*.md >/dev/null 2>&1; then
    # Check for stage subdirectories
    if ls "$plan_subdir"/phase_*/ >/dev/null 2>&1; then
      echo "2" # Level 2: Stage files exist
      return 0
    fi
    echo "1" # Level 1: Phase files exist
    return 0
  fi

  echo "0" # Default to Level 0
}

# ============================================================================
# DEPENDENCY PARSING
# ============================================================================

# Extract dependency metadata from a file
# Input: file_path, phase_id
# Output: JSON object with phase_id, dependencies, blocks
extract_dependency_metadata() {
  local file_path="$1"
  local phase_id="$2"

  if [[ ! -f "$file_path" ]]; then
    echo "{\"phase_id\":\"$phase_id\",\"dependencies\":[],\"blocks\":[]}"
    return 0
  fi

  # Search for dependency metadata in various formats
  # Format 1: **Dependencies**: depends_on: [phase_1]
  # Format 2: - depends_on: [phase_1, phase_2]
  # Format 3: Dependencies: depends_on: [phase_1]

  local dependencies=""
  local blocks=""

  # Extract depends_on - look for the pattern and extract content between brackets
  if grep -qi "depends_on:" "$file_path"; then
    # Extract content between brackets, handle multi-word phase names
    local deps_raw
    deps_raw=$(grep -i "depends_on:" "$file_path" | head -1 | sed -E 's/.*depends_on:\s*\[([^\]]*)\].*/\1/')
    # Clean up and split by comma
    if [[ -n "$deps_raw" && "$deps_raw" != *"depends_on"* ]]; then
      dependencies=$(echo "$deps_raw" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | paste -sd ',' -)
    fi
  fi

  # Extract blocks - look for the pattern and extract content between brackets
  if grep -qi "blocks:" "$file_path"; then
    local blocks_raw
    blocks_raw=$(grep -i "blocks:" "$file_path" | head -1 | sed -E 's/.*blocks:\s*\[([^\]]*)\].*/\1/')
    if [[ -n "$blocks_raw" && "$blocks_raw" != *"blocks"* ]]; then
      blocks=$(echo "$blocks_raw" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | paste -sd ',' -)
    fi
  fi

  # Convert to JSON array format
  local deps_json="[]"
  if [[ -n "$dependencies" ]]; then
    # Clean and quote each phase ID
    deps_json=$(echo "$dependencies" | awk -F',' '{
      printf "[";
      for(i=1;i<=NF;i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i);
        printf "\"%s\"", $i;
        if(i<NF) printf ",";
      }
      printf "]";
    }')
  fi

  local blocks_json="[]"
  if [[ -n "$blocks" ]]; then
    blocks_json=$(echo "$blocks" | awk -F',' '{
      printf "[";
      for(i=1;i<=NF;i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i);
        printf "\"%s\"", $i;
        if(i<NF) printf ",";
      }
      printf "]";
    }')
  fi

  # Return JSON object
  cat <<EOF
{"phase_id":"$phase_id","dependencies":$deps_json,"blocks":$blocks_json}
EOF
}

# Parse inline plan dependencies
# Input: plan_path
# Output: JSON array of phase dependency objects
parse_inline_dependencies() {
  local plan_path="$1"
  local phases=()
  local phase_sections

  # Extract phase sections (looking for ## Phase N or ### Phase N)
  phase_sections=$(grep -n "^##\+ Phase [0-9]" "$plan_path" | head -10)

  if [[ -z "$phase_sections" ]]; then
    echo "[]"
    return 0
  fi

  local phase_ids=()
  while IFS= read -r line; do
    local phase_num
    phase_num=$(echo "$line" | sed -E 's/.*Phase ([0-9]+).*/\1/')
    phase_ids+=("phase_$phase_num")
  done <<< "$phase_sections"

  # For each phase, extract dependency metadata
  local result="["
  local first=true
  for phase_id in "${phase_ids[@]}"; do
    local metadata
    metadata=$(extract_dependency_metadata "$plan_path" "$phase_id")
    if [[ "$first" == true ]]; then
      first=false
    else
      result+=","
    fi
    result+="$metadata"
  done
  result+="]"

  echo "$result"
}

# Parse hierarchical plan dependencies (Level 1: phase files)
# Input: plan_dir (directory containing phase_*.md files)
# Output: JSON array of phase dependency objects
parse_hierarchical_dependencies() {
  local plan_dir="$1"
  local phases=()

  if [[ ! -d "$plan_dir" ]]; then
    echo "[]"
    return 0
  fi

  # Find all phase files
  local phase_files
  phase_files=$(find "$plan_dir" -maxdepth 1 -name "phase_*.md" | sort)

  if [[ -z "$phase_files" ]]; then
    echo "[]"
    return 0
  fi

  local result="["
  local first=true
  while IFS= read -r phase_file; do
    local phase_num
    phase_num=$(basename "$phase_file" | sed -E 's/phase_([0-9]+).*/\1/')
    local phase_id="phase_$phase_num"

    local metadata
    metadata=$(extract_dependency_metadata "$phase_file" "$phase_id")

    if [[ "$first" == true ]]; then
      first=false
    else
      result+=","
    fi
    result+="$metadata"
  done <<< "$phase_files"
  result+="]"

  echo "$result"
}

# Parse deep hierarchical plan dependencies (Level 2: stage files)
# Input: plan_dir (directory containing phase_* subdirectories)
# Output: JSON array of phase dependency objects
parse_deep_dependencies() {
  local plan_dir="$1"

  # For Level 2, we analyze phase-level dependencies (not individual stages)
  # Stages within a phase are sequential
  parse_hierarchical_dependencies "$plan_dir"
}

# Parse plan dependencies (main entry point)
# Input: plan_path (top-level plan file)
# Output: JSON array of phase dependency objects
parse_plan_dependencies() {
  local plan_path="$1"
  local structure_level
  structure_level=$(detect_structure_level "$plan_path")

  local plan_dir
  plan_dir=$(dirname "$plan_path")
  local plan_name
  plan_name=$(basename "$plan_path" .md)
  local plan_subdir="$plan_dir/$plan_name"

  case "$structure_level" in
    0)
      parse_inline_dependencies "$plan_path"
      ;;
    1)
      parse_hierarchical_dependencies "$plan_subdir"
      ;;
    2)
      parse_deep_dependencies "$plan_subdir"
      ;;
    *)
      echo "[]"
      ;;
  esac
}

# ============================================================================
# DEPENDENCY GRAPH CONSTRUCTION
# ============================================================================

# Build dependency graph from parsed phase metadata
# Input: phases_json (JSON array of phase objects)
# Output: JSON dependency graph with nodes and edges
build_dependency_graph() {
  local phases_json="$1"

  # Use jq to build graph structure
  local graph
  graph=$(echo "$phases_json" | jq '{
    nodes: .,
    edges: [
      .[] |
      . as $phase |
      .dependencies[] |
      {from: ., to: $phase.phase_id}
    ]
  }')

  echo "$graph"
}

# ============================================================================
# TOPOLOGICAL SORT & WAVE IDENTIFICATION
# ============================================================================

# Identify execution waves from dependency graph
# Uses topological sort (Kahn's algorithm) to build wave structure
# Input: dependency_graph (JSON object with nodes and edges)
# Output: JSON array of wave objects
identify_waves() {
  local dependency_graph="$1"

  # Extract all phase IDs
  local all_phases
  all_phases=$(echo "$dependency_graph" | jq -r '.nodes[].phase_id' | sort)

  if [[ -z "$all_phases" ]]; then
    echo "[]"
    return 0
  fi

  # Build in-degree map (count of incoming edges per node)
  declare -A in_degree
  for phase in $all_phases; do
    in_degree[$phase]=0
  done

  # Count incoming edges
  while IFS= read -r edge; do
    if [[ -n "$edge" ]]; then
      local to_phase
      to_phase=$(echo "$edge" | jq -r '.to')
      ((in_degree[$to_phase]++)) || true
    fi
  done < <(echo "$dependency_graph" | jq -c '.edges[]')

  # Wave identification (Kahn's algorithm)
  local waves="[]"
  local wave_number=1
  local remaining_phases=($all_phases)

  while [[ ${#remaining_phases[@]} -gt 0 ]]; do
    local wave_phases=()

    # Find all phases with in-degree 0 (no unsatisfied dependencies)
    for phase in "${remaining_phases[@]}"; do
      if [[ ${in_degree[$phase]} -eq 0 ]]; then
        wave_phases+=("$phase")
      fi
    done

    # Break if no phases can be added (circular dependency)
    if [[ ${#wave_phases[@]} -eq 0 ]]; then
      >&2 echo "ERROR: Circular dependency detected. Remaining phases: ${remaining_phases[*]}"
      break
    fi

    # Create wave object
    local wave_phases_json
    wave_phases_json=$(printf '%s\n' "${wave_phases[@]}" | jq -R . | jq -s .)
    local wave
    wave=$(jq -n \
      --argjson wave_num "$wave_number" \
      --argjson phases "$wave_phases_json" \
      '{wave_number: $wave_num, phases: $phases, can_parallel: ($phases | length > 1)}')

    # Add wave to result
    waves=$(echo "$waves" | jq ". += [$wave]")

    # Remove wave phases from remaining
    local new_remaining=()
    for phase in "${remaining_phases[@]}"; do
      local found=false
      for wave_phase in "${wave_phases[@]}"; do
        if [[ "$phase" == "$wave_phase" ]]; then
          found=true
          break
        fi
      done
      if [[ "$found" == false ]]; then
        new_remaining+=("$phase")
      fi
    done
    remaining_phases=("${new_remaining[@]}")

    # Reduce in-degree for phases that depended on completed wave
    for wave_phase in "${wave_phases[@]}"; do
      while IFS= read -r edge; do
        if [[ -n "$edge" ]]; then
          local from_phase
          from_phase=$(echo "$edge" | jq -r '.from')
          local to_phase
          to_phase=$(echo "$edge" | jq -r '.to')

          if [[ "$from_phase" == "$wave_phase" ]]; then
            ((in_degree[$to_phase]--)) || true
          fi
        fi
      done < <(echo "$dependency_graph" | jq -c '.edges[]')
    done

    ((wave_number++))
  done

  echo "$waves"
}

# ============================================================================
# CYCLE DETECTION
# ============================================================================

# Detect cycles in dependency graph using DFS
# Input: dependency_graph (JSON object)
# Output: 0 if no cycle, 1 if cycle detected
detect_dependency_cycles() {
  local dependency_graph="$1"

  # Extract edges
  local edges
  edges=$(echo "$dependency_graph" | jq -c '.edges[]')

  if [[ -z "$edges" ]]; then
    return 0 # No edges, no cycles
  fi

  # Build adjacency list
  declare -A adjacency
  local all_phases
  all_phases=$(echo "$dependency_graph" | jq -r '.nodes[].phase_id' | sort)

  for phase in $all_phases; do
    adjacency[$phase]=""
  done

  while IFS= read -r edge; do
    if [[ -n "$edge" ]]; then
      local from_phase
      from_phase=$(echo "$edge" | jq -r '.from')
      local to_phase
      to_phase=$(echo "$edge" | jq -r '.to')

      if [[ -v adjacency[$from_phase] && -n "${adjacency[$from_phase]}" ]]; then
        adjacency[$from_phase]+=" $to_phase"
      else
        adjacency[$from_phase]="$to_phase"
      fi
    fi
  done <<< "$edges"

  # DFS cycle detection
  declare -A visited
  declare -A rec_stack

  dfs_cycle_detect() {
    local node="$1"
    visited[$node]=1
    rec_stack[$node]=1

    # Visit all neighbors
    local neighbors="${adjacency[$node]}"
    if [[ -n "$neighbors" ]]; then
      for neighbor in $neighbors; do
        if [[ ! -v visited[$neighbor] ]]; then
          if dfs_cycle_detect "$neighbor"; then
            return 1 # Cycle found
          fi
        elif [[ -v rec_stack[$neighbor] && ${rec_stack[$neighbor]} -eq 1 ]]; then
          >&2 echo "ERROR: Cycle detected: $node -> $neighbor"
          return 1 # Cycle found
        fi
      done
    fi

    rec_stack[$node]=0
    return 0
  }

  # Check all nodes
  for phase in $all_phases; do
    if [[ ! -v visited[$phase] ]]; then
      if ! dfs_cycle_detect "$phase"; then
        return 1 # Cycle found
      fi
    fi
  done

  return 0 # No cycles
}

# ============================================================================
# PARALLELIZATION METRICS
# ============================================================================

# Calculate parallelization metrics from wave structure
# Input: waves (JSON array of wave objects)
# Output: JSON object with metrics
calculate_parallelization_metrics() {
  local waves="$1"

  # Count total and parallel phases
  local total_phases
  total_phases=$(echo "$waves" | jq '[.[].phases | length] | add // 0')

  local parallel_phases=0
  local wave_count
  wave_count=$(echo "$waves" | jq 'length')

  # Count phases in parallel waves
  for ((i=0; i<wave_count; i++)); do
    local phase_count
    phase_count=$(echo "$waves" | jq ".[$i].phases | length")
    if [[ $phase_count -gt 1 ]]; then
      parallel_phases=$((parallel_phases + phase_count - 1))
    fi
  done

  # Estimate time (assume 3 hours per phase average)
  local avg_phase_time=3
  local sequential_time=$((total_phases * avg_phase_time))
  local parallel_time=$((wave_count * avg_phase_time))

  # Calculate time savings
  local time_savings=0
  if [[ $sequential_time -gt 0 ]]; then
    time_savings=$(( (sequential_time - parallel_time) * 100 / sequential_time ))
  fi

  # Build metrics JSON
  jq -n \
    --argjson total "$total_phases" \
    --argjson parallel "$parallel_phases" \
    --argjson seq_time "$sequential_time" \
    --argjson par_time "$parallel_time" \
    --argjson savings "$time_savings" \
    '{
      total_phases: $total,
      parallel_phases: $parallel,
      sequential_estimated_time: "\($seq_time) hours",
      parallel_estimated_time: "\($par_time) hours",
      time_savings_percentage: "\($savings)%"
    }'
}

# ============================================================================
# VALIDATION
# ============================================================================

# Validate dependency metadata format
# Input: file_path
# Output: 0 if valid, 1 if invalid
validate_dependency_syntax() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    return 0 # File doesn't exist, nothing to validate
  fi

  # Check for malformed dependency declarations
  if grep -qi "depends_on:" "$file_path"; then
    # Validate format: depends_on: [phase_1, phase_2]
    if ! grep -i "depends_on:" "$file_path" | grep -q "\[.*\]"; then
      >&2 echo "ERROR: Invalid depends_on format in $file_path (missing brackets)"
      return 1
    fi
  fi

  # Check for malformed blocks declarations
  if grep -qi "blocks:" "$file_path"; then
    if ! grep -i "blocks:" "$file_path" | grep -q "\[.*\]"; then
      >&2 echo "ERROR: Invalid blocks format in $file_path (missing brackets)"
      return 1
    fi
  fi

  return 0
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

# Main analysis function
# Input: plan_path (path to top-level plan file)
# Output: Complete JSON analysis with dependency graph, waves, and metrics
analyze_dependencies() {
  local plan_path="$1"

  if [[ ! -f "$plan_path" ]]; then
    >&2 echo "ERROR: Plan file not found: $plan_path"
    echo "{\"error\":\"Plan file not found\"}"
    return 1
  fi

  # Validate syntax
  if ! validate_dependency_syntax "$plan_path"; then
    echo "{\"error\":\"Invalid dependency syntax\"}"
    return 1
  fi

  # Parse dependencies
  local phases_json
  phases_json=$(parse_plan_dependencies "$plan_path")

  # Build dependency graph
  local dependency_graph
  dependency_graph=$(build_dependency_graph "$phases_json")

  # Detect cycles
  if ! detect_dependency_cycles "$dependency_graph"; then
    echo "{\"error\":\"Circular dependency detected\"}"
    return 1
  fi

  # Identify waves
  local waves
  waves=$(identify_waves "$dependency_graph")

  # Calculate metrics
  local metrics
  metrics=$(calculate_parallelization_metrics "$waves")

  # Return complete analysis
  jq -n \
    --argjson graph "$dependency_graph" \
    --argjson waves "$waves" \
    --argjson metrics "$metrics" \
    '{
      dependency_graph: $graph,
      waves: $waves,
      metrics: $metrics
    }'
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

main() {
  if [[ $# -lt 1 ]]; then
    >&2 echo "Usage: $0 <plan_path>"
    >&2 echo "Analyzes plan dependencies and identifies execution waves"
    exit 1
  fi

  local plan_path="$1"
  analyze_dependencies "$plan_path"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
