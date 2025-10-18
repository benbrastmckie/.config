# Stage 3: Dependency Mapping Implementation

## Metadata
- **Stage Number**: 3
- **Parent Phase**: phase_5_discovery_infrastructure.md
- **Phase Number**: 5
- **Objective**: Create dependency-mapper.sh with advanced graph algorithms for circular dependency detection, transitive analysis, and impact assessment
- **Complexity**: High (8/10)
- **Status**: PENDING
- **Estimated Tasks**: 5
- **Estimated Time**: 8-10 hours

## Overview

### Critical Need

The .claude/ infrastructure refactoring involves restructuring 44+ utilities, 25+ commands, and agent templates. Without dependency mapping, we face:

- **Hidden breaking changes**: Modifying a low-level utility breaks downstream commands without warning
- **Circular dependency risks**: Utilities inadvertently create dependency cycles during refactoring
- **Manual impact analysis**: Time-consuming manual tracing of "what uses this function?"
- **Incomplete testing**: Missing test coverage for affected components after changes

### Current Limitations

The current codebase has:
- No automated dependency tracking between utilities
- No circular dependency detection (bash allows sourcing cycles until stack overflow)
- Manual impact analysis requiring grep searches across multiple directories
- No visibility into transitive dependencies (A uses B uses C, change C affects A)

### Target Capabilities

This stage implements `dependency-mapper.sh` providing:

1. **Automated dependency graph construction** - Parse all utilities, commands, agents to build complete dependency map
2. **Circular dependency detection** - DFS-based cycle detection with path reconstruction
3. **Transitive dependency analysis** - Compute full dependency closure for impact assessment
4. **Multi-level impact analysis** - Track ripple effects across utilities → commands → agents
5. **Visualization and reporting** - Generate ASCII graphs, JSON exports, and impact summaries

## Task 3.1: Advanced Dependency Graph Construction

### Graph Data Structure Design

**Adjacency List Representation**:

```bash
# Global associative arrays for graph representation
declare -gA GRAPH_NODES      # node_id -> metadata JSON
declare -gA GRAPH_EDGES      # "from_id|to_id" -> edge metadata JSON
declare -gA GRAPH_ADJACENCY  # node_id -> space-separated list of target node_ids
declare -gA GRAPH_REVERSE    # node_id -> space-separated list of source node_ids (reverse edges)

# Node metadata structure (stored as JSON string):
# {
#   "id": "lib/base-utils.sh",
#   "type": "utility|command|agent",
#   "path": "/absolute/path/to/file.sh",
#   "functions": ["func1", "func2"],
#   "line_count": 250,
#   "public_api": ["exported_func1", "exported_func2"]
# }

# Edge metadata structure:
# {
#   "type": "direct_source|function_call|dynamic_source",
#   "context": "line 15: source /path/to/file.sh",
#   "confidence": "high|medium|low"
# }
```

**Implementation**:

```bash
#!/bin/bash
# dependency-mapper.sh - Graph construction and analysis

# Add node to graph
add_node() {
  local node_id="$1"
  local node_type="$2"
  local abs_path="$3"

  if [[ -n "${GRAPH_NODES[$node_id]}" ]]; then
    return 0  # Already exists
  fi

  # Extract functions from file
  local functions
  functions=$(grep -oP '^\s*\K[a-zA-Z_][a-zA-Z0-9_]*(?=\(\)\s*\{)' "$abs_path" 2>/dev/null | tr '\n' ',' | sed 's/,$//')

  local line_count
  line_count=$(wc -l < "$abs_path" 2>/dev/null || echo 0)

  # Identify public API (functions not prefixed with _)
  local public_api
  public_api=$(echo "$functions" | tr ',' '\n' | grep -v '^_' | tr '\n' ',' | sed 's/,$//')

  # Store as JSON
  GRAPH_NODES[$node_id]=$(jq -n \
    --arg id "$node_id" \
    --arg type "$node_type" \
    --arg path "$abs_path" \
    --arg funcs "$functions" \
    --arg pub "$public_api" \
    --arg lines "$line_count" \
    '{id: $id, type: $type, path: $path, functions: ($funcs | split(",")), line_count: ($lines | tonumber), public_api: ($pub | split(","))}')

  GRAPH_ADJACENCY[$node_id]=""
  GRAPH_REVERSE[$node_id]=""
}

# Add edge to graph
add_edge() {
  local from_id="$1"
  local to_id="$2"
  local edge_type="$3"
  local context="$4"
  local confidence="${5:-high}"

  local edge_key="${from_id}|${to_id}"

  # Store edge metadata
  GRAPH_EDGES[$edge_key]=$(jq -n \
    --arg type "$edge_type" \
    --arg ctx "$context" \
    --arg conf "$confidence" \
    '{type: $type, context: $ctx, confidence: $conf}')

  # Update adjacency lists
  if [[ -z "${GRAPH_ADJACENCY[$from_id]}" ]]; then
    GRAPH_ADJACENCY[$from_id]="$to_id"
  else
    # Avoid duplicates
    if [[ ! " ${GRAPH_ADJACENCY[$from_id]} " =~ " ${to_id} " ]]; then
      GRAPH_ADJACENCY[$from_id]+=" $to_id"
    fi
  fi

  # Update reverse adjacency
  if [[ -z "${GRAPH_REVERSE[$to_id]}" ]]; then
    GRAPH_REVERSE[$to_id]="$from_id"
  else
    if [[ ! " ${GRAPH_REVERSE[$to_id]} " =~ " ${from_id} " ]]; then
      GRAPH_REVERSE[$to_id]+=" $from_id"
    fi
  fi
}
```

### Dependency Extraction Algorithms

**Algorithm 1: Extract Direct Source Statements**

```bash
# Extract all source statements from a file
extract_source_dependencies() {
  local file_path="$1"
  local base_dir="$2"  # .claude/ root

  # Pattern 1: source /absolute/path/file.sh
  # Pattern 2: source ./relative/path/file.sh
  # Pattern 3: source "$VAR/file.sh" (dynamic)
  # Pattern 4: . /path/file.sh (dot notation)

  local source_pattern='^\s*(source|\.) +([^#\n]+)'

  while IFS= read -r line_num; do
    local line
    line=$(sed -n "${line_num}p" "$file_path")

    # Extract sourced file path
    local sourced_file
    sourced_file=$(echo "$line" | sed -E 's/^\s*(source|\.)\s+//' | sed 's/#.*//' | tr -d '"' | tr -d "'")

    # Classify dependency type
    local dep_type="direct_source"
    local confidence="high"

    if [[ "$sourced_file" =~ \$\{ || "$sourced_file" =~ \$ ]]; then
      dep_type="dynamic_source"
      confidence="medium"

      # Try to resolve common variables
      if [[ "$sourced_file" =~ \$\{CLAUDE_LIB_DIR\} ]]; then
        sourced_file="${sourced_file//\$\{CLAUDE_LIB_DIR\}/$base_dir/lib}"
        confidence="high"
      elif [[ "$sourced_file" =~ \$CLAUDE_LIB_DIR ]]; then
        sourced_file="${sourced_file//\$CLAUDE_LIB_DIR/$base_dir/lib}"
        confidence="high"
      fi
    fi

    # Resolve to absolute path
    if [[ "$sourced_file" =~ ^/ ]]; then
      # Already absolute
      :
    elif [[ "$sourced_file" =~ ^\. ]]; then
      # Relative to current file
      local file_dir
      file_dir=$(dirname "$file_path")
      sourced_file=$(realpath -m "$file_dir/$sourced_file" 2>/dev/null || echo "$file_dir/$sourced_file")
    else
      # Relative to base_dir
      sourced_file=$(realpath -m "$base_dir/$sourced_file" 2>/dev/null || echo "$base_dir/$sourced_file")
    fi

    # Convert to relative path from base_dir for node_id
    local node_id
    node_id=$(realpath --relative-to="$base_dir" "$sourced_file" 2>/dev/null || echo "$sourced_file")

    echo "$node_id|$dep_type|line $line_num: $line|$confidence"
  done < <(grep -n -E "$source_pattern" "$file_path" | cut -d: -f1)
}
```

**Algorithm 2: Extract Function Call Dependencies**

```bash
# Extract indirect dependencies via function calls
extract_function_call_dependencies() {
  local file_path="$1"
  local base_dir="$2"

  # Build map of function -> defining file
  local -A function_map
  while IFS='|' read -r func_name func_file; do
    function_map[$func_name]="$func_file"
  done < <(build_function_map "$base_dir")

  # Find all function calls in file
  local func_pattern='[a-zA-Z_][a-zA-Z0-9_]*\s*\('

  while IFS= read -r line_num; do
    local line
    line=$(sed -n "${line_num}p" "$file_path")

    # Extract function name
    local func_name
    func_name=$(echo "$line" | grep -oP '[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()' | head -1)

    # Skip bash builtins and common commands
    if [[ "$func_name" =~ ^(echo|printf|read|test|cd|source|export|local|declare)$ ]]; then
      continue
    fi

    # Check if function is defined in another file
    if [[ -n "${function_map[$func_name]}" ]]; then
      local target_file="${function_map[$func_name]}"
      local node_id
      node_id=$(realpath --relative-to="$base_dir" "$target_file" 2>/dev/null || echo "$target_file")

      echo "$node_id|function_call|line $line_num: calls $func_name()|medium"
    fi
  done < <(grep -n "$func_pattern" "$file_path" | cut -d: -f1)
}

# Build comprehensive function -> file mapping
build_function_map() {
  local base_dir="$1"

  # Scan all .sh files for function definitions
  while IFS= read -r file; do
    while IFS= read -r func; do
      echo "$func|$file"
    done < <(grep -oP '^\s*\K[a-zA-Z_][a-zA-Z0-9_]*(?=\(\)\s*\{)' "$file")
  done < <(find "$base_dir" -type f -name "*.sh")
}
```

### Graph Building Process

**Complete Graph Construction Algorithm**:

```bash
build_dependency_graph() {
  local base_dir="${1:-.claude}"
  base_dir=$(realpath "$base_dir")

  echo "Building dependency graph for $base_dir..." >&2

  # Phase 1: Node discovery (scan all files)
  local -a all_files
  mapfile -t all_files < <(find "$base_dir" -type f -name "*.sh" -o -name "*.md" | sort)

  echo "Found ${#all_files[@]} files to analyze" >&2

  local processed=0
  for file in "${all_files[@]}"; do
    local node_id
    node_id=$(realpath --relative-to="$base_dir" "$file")

    # Classify file type
    local node_type="utility"
    if [[ "$file" =~ /commands/ ]]; then
      node_type="command"
    elif [[ "$file" =~ /agents/ ]]; then
      node_type="agent"
    elif [[ "$file" =~ /templates/ ]]; then
      node_type="template"
    fi

    add_node "$node_id" "$node_type" "$file"

    ((processed++))
    if ((processed % 10 == 0)); then
      echo "  Processed $processed/${#all_files[@]} files..." >&2
    fi
  done

  echo "Phase 1 complete: ${#GRAPH_NODES[@]} nodes created" >&2

  # Phase 2: Edge discovery (extract dependencies)
  processed=0
  for file in "${all_files[@]}"; do
    local from_id
    from_id=$(realpath --relative-to="$base_dir" "$file")

    # Extract direct source dependencies
    while IFS='|' read -r to_id edge_type context confidence; do
      if [[ -n "$to_id" ]]; then
        # Ensure target node exists
        if [[ -z "${GRAPH_NODES[$to_id]}" ]]; then
          local target_path
          target_path=$(realpath -m "$base_dir/$to_id")
          if [[ -f "$target_path" ]]; then
            add_node "$to_id" "utility" "$target_path"
          else
            # Missing dependency - create phantom node
            add_node "$to_id" "missing" "$target_path"
          fi
        fi

        add_edge "$from_id" "$to_id" "$edge_type" "$context" "$confidence"
      fi
    done < <(extract_source_dependencies "$file" "$base_dir")

    # Extract function call dependencies (if bash file)
    if [[ "$file" =~ \.sh$ ]]; then
      while IFS='|' read -r to_id edge_type context confidence; do
        if [[ -n "$to_id" ]]; then
          add_edge "$from_id" "$to_id" "$edge_type" "$context" "$confidence"
        fi
      done < <(extract_function_call_dependencies "$file" "$base_dir")
    fi

    ((processed++))
    if ((processed % 10 == 0)); then
      echo "  Analyzed $processed/${#all_files[@]} files for dependencies..." >&2
    fi
  done

  echo "Phase 2 complete: ${#GRAPH_EDGES[@]} edges created" >&2
  echo "Graph construction complete" >&2
}
```

**Complexity Analysis**:
- **Time Complexity**: O(N × M) where N = number of files, M = average file size in lines
- **Space Complexity**: O(N + E) where N = nodes, E = edges (typically E ≈ 2-3N for .claude/)
- **Expected Performance**: ~44 utilities + 25 commands = 69 files × 200 lines avg = 13,800 line scans in <5 seconds

**Optimization Strategies**:
- Cache function map (build once, reuse for all files)
- Parallel processing with GNU parallel for large codebases (>100 files)
- Skip binary files and large generated files
- Use fast grep patterns instead of line-by-line parsing

## Task 3.2: Circular Dependency Detection Algorithm

### Depth-First Search with Cycle Detection

**Algorithm: Three-Color DFS**

```bash
# Color states
declare -gA NODE_COLOR  # white (unvisited), gray (in progress), black (complete)
declare -gA NODE_PARENT # Track parent for path reconstruction
declare -ga CYCLES      # Array of detected cycles

# Detect all circular dependencies in graph
detect_cycles() {
  echo "Detecting circular dependencies..." >&2

  # Initialize all nodes as white (unvisited)
  for node_id in "${!GRAPH_NODES[@]}"; do
    NODE_COLOR[$node_id]="white"
    NODE_PARENT[$node_id]=""
  done

  CYCLES=()

  # Visit each white node
  for node_id in "${!GRAPH_NODES[@]}"; do
    if [[ "${NODE_COLOR[$node_id]}" == "white" ]]; then
      dfs_visit "$node_id"
    fi
  done

  if ((${#CYCLES[@]} == 0)); then
    echo "No circular dependencies detected" >&2
    return 0
  else
    echo "Found ${#CYCLES[@]} circular dependencies" >&2
    return 1
  fi
}

# Recursive DFS visit
dfs_visit() {
  local node="$1"

  # Mark as gray (in progress)
  NODE_COLOR[$node]="gray"

  # Visit all neighbors
  local neighbors="${GRAPH_ADJACENCY[$node]}"
  for neighbor in $neighbors; do
    if [[ "${NODE_COLOR[$neighbor]}" == "white" ]]; then
      # Tree edge - continue DFS
      NODE_PARENT[$neighbor]="$node"
      dfs_visit "$neighbor"
    elif [[ "${NODE_COLOR[$neighbor]}" == "gray" ]]; then
      # Back edge - cycle detected!
      reconstruct_cycle "$node" "$neighbor"
    fi
    # Black nodes (already visited) - ignore
  done

  # Mark as black (complete)
  NODE_COLOR[$node]="black"
}

# Reconstruct cycle path when back edge found
reconstruct_cycle() {
  local from="$1"
  local to="$2"

  # Build path from 'to' back to 'from' using parent pointers
  local -a cycle_path=("$to")
  local current="$from"

  while [[ "$current" != "$to" && -n "$current" ]]; do
    cycle_path+=("$current")
    current="${NODE_PARENT[$current]}"
  done

  # Reverse to get forward cycle
  local -a reversed_cycle
  for ((i=${#cycle_path[@]}-1; i>=0; i--)); do
    reversed_cycle+=("${cycle_path[$i]}")
  done

  # Close the cycle
  reversed_cycle+=("$to")

  # Store cycle (JSON array)
  local cycle_json
  cycle_json=$(printf '%s\n' "${reversed_cycle[@]}" | jq -R . | jq -s .)
  CYCLES+=("$cycle_json")

  echo "  Cycle detected: ${reversed_cycle[*]}" >&2
}
```

### Iterative DFS (Stack-Based) Alternative

For very deep graphs, recursive DFS may hit stack limits. Iterative implementation:

```bash
# Iterative DFS using explicit stack
dfs_visit_iterative() {
  local start_node="$1"

  local -a stack=("$start_node")
  local -A stack_set
  stack_set[$start_node]=1

  while ((${#stack[@]} > 0)); do
    local node="${stack[-1]}"

    if [[ "${NODE_COLOR[$node]}" == "white" ]]; then
      NODE_COLOR[$node]="gray"
    fi

    # Find unvisited neighbor
    local found_white=false
    local neighbors="${GRAPH_ADJACENCY[$node]}"
    for neighbor in $neighbors; do
      if [[ "${NODE_COLOR[$neighbor]}" == "white" ]]; then
        # Tree edge
        NODE_PARENT[$neighbor]="$node"
        stack+=("$neighbor")
        stack_set[$neighbor]=1
        found_white=true
        break
      elif [[ -n "${stack_set[$neighbor]}" ]]; then
        # Back edge - cycle detected
        reconstruct_cycle "$node" "$neighbor"
      fi
    done

    if ! $found_white; then
      # No more white neighbors - backtrack
      NODE_COLOR[$node]="black"
      unset 'stack[-1]'
      unset "stack_set[$node]"
    fi
  done
}
```

### Edge Cases and Error Handling

**Edge Case 1: Self-Loops**

```bash
# Detect self-sourcing
detect_self_loops() {
  local -a self_loops

  for node_id in "${!GRAPH_ADJACENCY[@]}"; do
    local neighbors="${GRAPH_ADJACENCY[$node_id]}"
    if [[ " $neighbors " =~ " $node_id " ]]; then
      self_loops+=("$node_id")
      echo "WARNING: Self-loop detected in $node_id" >&2
    fi
  done

  if ((${#self_loops[@]} > 0)); then
    printf '%s\n' "${self_loops[@]}" | jq -R . | jq -s .
  else
    echo "[]"
  fi
}
```

**Edge Case 2: Missing Dependencies**

```bash
# Identify broken dependency chains
detect_missing_dependencies() {
  local -a missing

  for node_id in "${!GRAPH_NODES[@]}"; do
    local node_meta="${GRAPH_NODES[$node_id]}"
    local node_type
    node_type=$(echo "$node_meta" | jq -r '.type')

    if [[ "$node_type" == "missing" ]]; then
      missing+=("$node_id")

      # Find who references this missing file
      local referrers="${GRAPH_REVERSE[$node_id]}"
      echo "ERROR: Missing dependency $node_id referenced by: $referrers" >&2
    fi
  done

  if ((${#missing[@]} > 0)); then
    printf '%s\n' "${missing[@]}" | jq -R . | jq -s .
    return 1
  else
    echo "[]"
    return 0
  fi
}
```

**Edge Case 3: Dynamic Dependencies**

```bash
# Report dynamic dependencies that couldn't be resolved
report_dynamic_dependencies() {
  local -a dynamic_deps

  for edge_key in "${!GRAPH_EDGES[@]}"; do
    local edge_meta="${GRAPH_EDGES[$edge_key]}"
    local edge_type
    edge_type=$(echo "$edge_meta" | jq -r '.type')

    if [[ "$edge_type" == "dynamic_source" ]]; then
      local confidence
      confidence=$(echo "$edge_meta" | jq -r '.confidence')

      if [[ "$confidence" != "high" ]]; then
        dynamic_deps+=("$edge_key: $(echo "$edge_meta" | jq -r '.context')")
      fi
    fi
  done

  if ((${#dynamic_deps[@]} > 0)); then
    echo "WARNING: ${#dynamic_deps[@]} dynamic dependencies with uncertain resolution:" >&2
    printf '  %s\n' "${dynamic_deps[@]}" >&2
  fi
}
```

## Task 3.3: Transitive Dependency Analysis

### Forward Propagation (Who Depends on X)

```bash
# Compute all downstream dependents of a node (transitive closure)
compute_forward_dependencies() {
  local source_node="$1"
  local max_depth="${2:--1}"  # -1 = unlimited

  local -A visited
  local -A depth_map
  local -a queue=("$source_node")
  visited[$source_node]=1
  depth_map[$source_node]=0

  local -a all_dependents

  # BFS traversal
  while ((${#queue[@]} > 0)); do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")  # Dequeue

    local current_depth="${depth_map[$current]}"

    # Check depth limit
    if [[ "$max_depth" -ne -1 && "$current_depth" -ge "$max_depth" ]]; then
      continue
    fi

    # Get all nodes that depend on current (reverse edges)
    local dependents="${GRAPH_REVERSE[$current]}"
    for dependent in $dependents; do
      if [[ -z "${visited[$dependent]}" ]]; then
        visited[$dependent]=1
        depth_map[$dependent]=$((current_depth + 1))
        queue+=("$dependent")
        all_dependents+=("$dependent:$((current_depth + 1))")
      fi
    done
  done

  # Return as JSON with depth information
  if ((${#all_dependents[@]} > 0)); then
    local json_output="["
    for entry in "${all_dependents[@]}"; do
      local node="${entry%:*}"
      local depth="${entry#*:}"
      json_output+="{\"node\":\"$node\",\"depth\":$depth},"
    done
    json_output="${json_output%,}]"
    echo "$json_output"
  else
    echo "[]"
  fi
}
```

### Backward Propagation (What Does X Depend On)

```bash
# Compute all upstream dependencies of a node
compute_backward_dependencies() {
  local target_node="$1"
  local max_depth="${2:--1}"

  local -A visited
  local -A depth_map
  local -a queue=("$target_node")
  visited[$target_node]=1
  depth_map[$target_node]=0

  local -a all_dependencies

  # BFS traversal (forward edges this time)
  while ((${#queue[@]} > 0)); do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")

    local current_depth="${depth_map[$current]}"

    if [[ "$max_depth" -ne -1 && "$current_depth" -ge "$max_depth" ]]; then
      continue
    fi

    # Get all nodes that current depends on
    local dependencies="${GRAPH_ADJACENCY[$current]}"
    for dependency in $dependencies; do
      if [[ -z "${visited[$dependency]}" ]]; then
        visited[$dependency]=1
        depth_map[$dependency]=$((current_depth + 1))
        queue+=("$dependency")
        all_dependencies+=("$dependency:$((current_depth + 1))")
      fi
    done
  done

  if ((${#all_dependencies[@]} > 0)); then
    local json_output="["
    for entry in "${all_dependencies[@]}"; do
      local node="${entry%:*}"
      local depth="${entry#*:}"
      json_output+="{\"node\":\"$node\",\"depth\":$depth},"
    done
    json_output="${json_output%,}]"
    echo "$json_output"
  else
    echo "[]"
  fi
}
```

### Critical Path Identification

```bash
# Find the longest dependency chain to a node
find_critical_path() {
  local target_node="$1"

  local -A distance
  local -A predecessor

  # Initialize distances
  for node in "${!GRAPH_NODES[@]}"; do
    distance[$node]=-1
  done

  # Find all nodes with no dependencies (sources)
  local -a source_nodes
  for node in "${!GRAPH_NODES[@]}"; do
    if [[ -z "${GRAPH_ADJACENCY[$node]}" || "${GRAPH_ADJACENCY[$node]}" == "" ]]; then
      source_nodes+=("$node")
      distance[$node]=0
    fi
  done

  # Topological sort with distance tracking
  local -a topo_order
  local -A visited

  for source in "${source_nodes[@]}"; do
    topo_sort_dfs "$source" visited topo_order
  done

  # Compute longest path
  for node in "${topo_order[@]}"; do
    local neighbors="${GRAPH_ADJACENCY[$node]}"
    for neighbor in $neighbors; do
      local new_dist=$((distance[$node] + 1))
      if ((new_dist > distance[$neighbor])); then
        distance[$neighbor]=$new_dist
        predecessor[$neighbor]="$node"
      fi
    done
  done

  # Reconstruct path to target
  local -a critical_path
  local current="$target_node"
  while [[ -n "$current" ]]; do
    critical_path=("$current" "${critical_path[@]}")
    current="${predecessor[$current]}"
  done

  printf '%s\n' "${critical_path[@]}" | jq -R . | jq -s .
}

topo_sort_dfs() {
  local node="$1"
  local -n visited_ref="$2"
  local -n order_ref="$3"

  if [[ -n "${visited_ref[$node]}" ]]; then
    return
  fi

  visited_ref[$node]=1

  local neighbors="${GRAPH_ADJACENCY[$node]}"
  for neighbor in $neighbors; do
    topo_sort_dfs "$neighbor" visited_ref order_ref
  done

  order_ref+=("$node")
}
```

### Impact Scoring Algorithm

```bash
# Calculate impact score for changing a node
calculate_impact_score() {
  local node="$1"

  # Get forward dependencies at each level
  local level1_deps
  level1_deps=$(compute_forward_dependencies "$node" 1)
  local level1_count
  level1_count=$(echo "$level1_deps" | jq 'length')

  local level2_deps
  level2_deps=$(compute_forward_dependencies "$node" 2)
  local level2_count
  level2_count=$(echo "$level2_deps" | jq '[.[] | select(.depth == 2)] | length')

  local level3_deps
  level3_deps=$(compute_forward_dependencies "$node" 3)
  local level3_count
  level3_count=$(echo "$level3_deps" | jq '[.[] | select(.depth == 3)] | length')

  # Weighted impact score (closer dependencies weighted higher)
  local impact_score=$((level1_count * 10 + level2_count * 5 + level3_count * 2))

  # Adjust for node type (utilities more critical than agents)
  local node_meta="${GRAPH_NODES[$node]}"
  local node_type
  node_type=$(echo "$node_meta" | jq -r '.type')

  case "$node_type" in
    utility)
      impact_score=$((impact_score * 15 / 10))  # 1.5x multiplier
      ;;
    command)
      impact_score=$((impact_score * 12 / 10))  # 1.2x multiplier
      ;;
  esac

  # Output detailed impact report
  jq -n \
    --arg node "$node" \
    --argjson score "$impact_score" \
    --argjson l1 "$level1_count" \
    --argjson l2 "$level2_count" \
    --argjson l3 "$level3_count" \
    --arg type "$node_type" \
    '{node: $node, impact_score: $score, direct_dependents: $l1, level2_dependents: $l2, level3_dependents: $l3, type: $type, risk_level: (if $score > 100 then "high" elif $score > 50 then "medium" else "low" end)}'
}
```

## Task 3.4: Advanced Impact Analysis Implementation

### Multi-Level Impact Tracking

```bash
# Generate comprehensive impact report
generate_impact_report() {
  local changed_node="$1"

  echo "=== Impact Analysis for: $changed_node ===" >&2
  echo >&2

  # Categorize impact by node type
  local -A impact_by_type
  impact_by_type[utility]=0
  impact_by_type[command]=0
  impact_by_type[agent]=0
  impact_by_type[template]=0

  # Get all affected nodes
  local all_affected
  all_affected=$(compute_forward_dependencies "$changed_node" -1)

  local total_affected
  total_affected=$(echo "$all_affected" | jq 'length')

  # Group by type and depth
  local depth1_by_type depth2_by_type depth3_by_type
  depth1_by_type=$(echo "$all_affected" | jq '[.[] | select(.depth == 1)]')
  depth2_by_type=$(echo "$all_affected" | jq '[.[] | select(.depth == 2)]')
  depth3_by_type=$(echo "$all_affected" | jq '[.[] | select(.depth == 3)]')

  # Count by type at each level
  local d1_utils d1_cmds d1_agents
  d1_utils=$(echo "$depth1_by_type" | jq '[.[] | select(.node | test("lib/"))] | length')
  d1_cmds=$(echo "$depth1_by_type" | jq '[.[] | select(.node | test("commands/"))] | length')
  d1_agents=$(echo "$depth1_by_type" | jq '[.[] | select(.node | test("agents/"))] | length')

  local d2_utils d2_cmds d2_agents
  d2_utils=$(echo "$depth2_by_type" | jq '[.[] | select(.node | test("lib/"))] | length')
  d2_cmds=$(echo "$depth2_by_type" | jq '[.[] | select(.node | test("commands/"))] | length')
  d2_agents=$(echo "$depth2_by_type" | jq '[.[] | select(.node | test("agents/"))] | length')

  local d3_utils d3_cmds d3_agents
  d3_utils=$(echo "$depth3_by_type" | jq '[.[] | select(.node | test("lib/"))] | length')
  d3_cmds=$(echo "$depth3_by_type" | jq '[.[] | select(.node | test("commands/"))] | length')
  d3_agents=$(echo "$depth3_by_type" | jq '[.[] | select(.node | test("agents/"))] | length')

  # Display impact tree
  echo "Change to $changed_node affects:" >&2
  echo "  → Level 1 (direct): $d1_utils utilities, $d1_cmds commands, $d1_agents agents" >&2
  echo "  → Level 2 (transitive): $d2_utils utilities, $d2_cmds commands, $d2_agents agents" >&2
  echo "  → Level 3 (extended): $d3_utils utilities, $d3_cmds commands, $d3_agents agents" >&2
  echo "Total reach: $total_affected components" >&2

  # Generate JSON report
  jq -n \
    --arg node "$changed_node" \
    --argjson total "$total_affected" \
    --argjson d1_utils "$d1_utils" \
    --argjson d1_cmds "$d1_cmds" \
    --argjson d1_agents "$d1_agents" \
    --argjson d2_utils "$d2_utils" \
    --argjson d2_cmds "$d2_cmds" \
    --argjson d2_agents "$d2_agents" \
    --argjson d3_utils "$d3_utils" \
    --argjson d3_cmds "$d3_cmds" \
    --argjson d3_agents "$d3_agents" \
    '{changed_node: $node, total_affected: $total, impact_by_level: [{level: 1, utilities: $d1_utils, commands: $d1_cmds, agents: $d1_agents}, {level: 2, utilities: $d2_utils, commands: $d2_cmds, agents: $d2_agents}, {level: 3, utilities: $d3_utils, commands: $d3_cmds, agents: $d3_agents}]}'
}
```

### Change Simulation

```bash
# Simulate removing a function from a utility
simulate_function_removal() {
  local utility_file="$1"
  local function_name="$2"

  echo "Simulating removal of $function_name from $utility_file..." >&2

  # Find all files that call this function
  local -a affected_files

  for node in "${!GRAPH_NODES[@]}"; do
    local node_meta="${GRAPH_NODES[$node]}"
    local node_path
    node_path=$(echo "$node_meta" | jq -r '.path')

    # Search for function calls
    if grep -q "${function_name}\s*(" "$node_path" 2>/dev/null; then
      affected_files+=("$node")
    fi
  done

  if ((${#affected_files[@]} > 0)); then
    echo "ERROR: Cannot safely remove $function_name - used by ${#affected_files[@]} files:" >&2
    printf '  - %s\n' "${affected_files[@]}" >&2

    printf '%s\n' "${affected_files[@]}" | jq -R . | jq -s '{function: $function_name, utility: $utility_file, breaking_change: true, affected_files: .}'
    return 1
  else
    echo "OK: $function_name appears safe to remove (no external callers found)" >&2
    jq -n --arg func "$function_name" --arg util "$utility_file" '{function: $func, utility: $util, breaking_change: false, affected_files: []}'
    return 0
  fi
}

# Simulate renaming a utility file
simulate_utility_rename() {
  local old_path="$1"
  local new_path="$2"

  # Find all source statements referencing old path
  local -a needs_update

  for edge_key in "${!GRAPH_EDGES[@]}"; do
    local to_node="${edge_key#*|}"
    if [[ "$to_node" == "$old_path" ]]; then
      local from_node="${edge_key%|*}"
      needs_update+=("$from_node")
    fi
  done

  echo "Renaming $old_path → $new_path requires updating ${#needs_update[@]} files" >&2
  printf '  - %s\n' "${needs_update[@]}" >&2

  printf '%s\n' "${needs_update[@]}" | jq -R . | jq -s --arg old "$old_path" --arg new "$new_path" '{old_path: $old, new_path: $new, files_to_update: .}'
}
```

### Visualization and Reporting

```bash
# Generate ASCII dependency graph
generate_ascii_graph() {
  local root_node="$1"
  local max_depth="${2:-3}"

  echo "$root_node"
  print_tree "$root_node" "" "$max_depth" 0
}

print_tree() {
  local node="$1"
  local prefix="$2"
  local max_depth="$3"
  local current_depth="$4"

  if ((current_depth >= max_depth)); then
    return
  fi

  local children="${GRAPH_ADJACENCY[$node]}"
  local child_array=($children)
  local child_count=${#child_array[@]}

  for ((i=0; i<child_count; i++)); do
    local child="${child_array[$i]}"
    local is_last=$((i == child_count - 1))

    if $is_last; then
      echo "${prefix}└── $child"
      print_tree "$child" "${prefix}    " "$max_depth" $((current_depth + 1))
    else
      echo "${prefix}├── $child"
      print_tree "$child" "${prefix}│   " "$max_depth" $((current_depth + 1))
    fi
  done
}

# Export graph to JSON for external visualization
export_graph_json() {
  local output_file="$1"

  # Build nodes array
  local nodes_json="["
  for node_id in "${!GRAPH_NODES[@]}"; do
    nodes_json+="${GRAPH_NODES[$node_id]},"
  done
  nodes_json="${nodes_json%,}]"

  # Build edges array
  local edges_json="["
  for edge_key in "${!GRAPH_EDGES[@]}"; do
    local from="${edge_key%|*}"
    local to="${edge_key#*|}"
    local edge_meta="${GRAPH_EDGES[$edge_key]}"

    local edge_obj
    edge_obj=$(echo "$edge_meta" | jq --arg from "$from" --arg to "$to" '. + {from: $from, to: $to}')
    edges_json+="$edge_obj,"
  done
  edges_json="${edges_json%,}]"

  # Combine into graph object
  jq -n --argjson nodes "$nodes_json" --argjson edges "$edges_json" '{nodes: $nodes, edges: $edges}' > "$output_file"

  echo "Graph exported to $output_file" >&2
}

# Generate summary statistics
generate_graph_statistics() {
  local node_count=${#GRAPH_NODES[@]}
  local edge_count=${#GRAPH_EDGES[@]}

  # Calculate fan-in/fan-out
  local -A fan_in fan_out
  for node in "${!GRAPH_NODES[@]}"; do
    local out_degree=0
    local out_edges="${GRAPH_ADJACENCY[$node]}"
    if [[ -n "$out_edges" ]]; then
      out_degree=$(echo "$out_edges" | wc -w)
    fi
    fan_out[$node]=$out_degree

    local in_degree=0
    local in_edges="${GRAPH_REVERSE[$node]}"
    if [[ -n "$in_edges" ]]; then
      in_degree=$(echo "$in_edges" | wc -w)
    fi
    fan_in[$node]=$in_degree
  done

  # Find max fan-in/fan-out
  local max_fan_in=0 max_fan_in_node=""
  local max_fan_out=0 max_fan_out_node=""

  for node in "${!fan_in[@]}"; do
    if ((fan_in[$node] > max_fan_in)); then
      max_fan_in=${fan_in[$node]}
      max_fan_in_node="$node"
    fi
  done

  for node in "${!fan_out[@]}"; do
    if ((fan_out[$node] > max_fan_out)); then
      max_fan_out=${fan_out[$node]}
      max_fan_out_node="$node"
    fi
  done

  jq -n \
    --argjson nodes "$node_count" \
    --argjson edges "$edge_count" \
    --arg max_in_node "$max_fan_in_node" \
    --argjson max_in "$max_fan_in" \
    --arg max_out_node "$max_fan_out_node" \
    --argjson max_out "$max_fan_out" \
    '{node_count: $nodes, edge_count: $edges, max_fan_in: {node: $max_in_node, count: $max_in}, max_fan_out: {node: $max_out_node, count: $max_out}, avg_degree: (($edges * 2.0) / $nodes)}'
}
```

## Task 3.5: Testing and Validation

### Test Case Specifications

**Test 1: Linear Dependency Chain (A→B→C)**

```bash
test_linear_chain() {
  # Setup test graph
  add_node "A.sh" "utility" "/tmp/A.sh"
  add_node "B.sh" "utility" "/tmp/B.sh"
  add_node "C.sh" "utility" "/tmp/C.sh"

  add_edge "A.sh" "B.sh" "direct_source" "line 1: source B.sh" "high"
  add_edge "B.sh" "C.sh" "direct_source" "line 1: source C.sh" "high"

  # Test forward dependencies
  local result
  result=$(compute_forward_dependencies "C.sh" -1)
  local count
  count=$(echo "$result" | jq 'length')

  assert_equals "$count" "2" "C.sh should have 2 forward dependents (B, A)"

  # Test backward dependencies
  result=$(compute_backward_dependencies "A.sh" -1)
  count=$(echo "$result" | jq 'length')

  assert_equals "$count" "2" "A.sh should have 2 backward dependencies (B, C)"

  # Test no cycles
  detect_cycles
  assert_equals "$?" "0" "Linear chain should have no cycles"
}
```

**Test 2: Circular Dependency (A→B→C→A)**

```bash
test_circular_dependency() {
  add_node "A.sh" "utility" "/tmp/A.sh"
  add_node "B.sh" "utility" "/tmp/B.sh"
  add_node "C.sh" "utility" "/tmp/C.sh"

  add_edge "A.sh" "B.sh" "direct_source" "line 1" "high"
  add_edge "B.sh" "C.sh" "direct_source" "line 1" "high"
  add_edge "C.sh" "A.sh" "direct_source" "line 1" "high"

  # Should detect cycle
  detect_cycles
  assert_equals "$?" "1" "Should detect circular dependency"
  assert_equals "${#CYCLES[@]}" "1" "Should find exactly 1 cycle"

  # Verify cycle path
  local cycle_path
  cycle_path=$(echo "${CYCLES[0]}" | jq -r '.[]' | tr '\n' ' ')
  assert_contains "$cycle_path" "A.sh" "Cycle should contain A.sh"
  assert_contains "$cycle_path" "B.sh" "Cycle should contain B.sh"
  assert_contains "$cycle_path" "C.sh" "Cycle should contain C.sh"
}
```

**Test 3: Diamond Dependency (A→B,C; B,C→D)**

```bash
test_diamond_dependency() {
  add_node "A.sh" "utility" "/tmp/A.sh"
  add_node "B.sh" "utility" "/tmp/B.sh"
  add_node "C.sh" "utility" "/tmp/C.sh"
  add_node "D.sh" "utility" "/tmp/D.sh"

  add_edge "A.sh" "B.sh" "direct_source" "line 1" "high"
  add_edge "A.sh" "C.sh" "direct_source" "line 2" "high"
  add_edge "B.sh" "D.sh" "direct_source" "line 1" "high"
  add_edge "C.sh" "D.sh" "direct_source" "line 1" "high"

  # Test transitive closure of D
  local result
  result=$(compute_forward_dependencies "D.sh" -1)
  local count
  count=$(echo "$result" | jq 'length')

  assert_equals "$count" "3" "D.sh should affect 3 nodes (B, C, A)"

  # Verify no cycles
  detect_cycles
  assert_equals "$?" "0" "Diamond should have no cycles"
}
```

**Test 4: Complex Graph with Multiple Cycles**

```bash
test_multiple_cycles() {
  # Cycle 1: A→B→A
  add_node "A.sh" "utility" "/tmp/A.sh"
  add_node "B.sh" "utility" "/tmp/B.sh"
  add_edge "A.sh" "B.sh" "direct_source" "line 1" "high"
  add_edge "B.sh" "A.sh" "direct_source" "line 1" "high"

  # Cycle 2: C→D→E→C
  add_node "C.sh" "utility" "/tmp/C.sh"
  add_node "D.sh" "utility" "/tmp/D.sh"
  add_node "E.sh" "utility" "/tmp/E.sh"
  add_edge "C.sh" "D.sh" "direct_source" "line 1" "high"
  add_edge "D.sh" "E.sh" "direct_source" "line 1" "high"
  add_edge "E.sh" "C.sh" "direct_source" "line 1" "high"

  detect_cycles
  assert_equals "${#CYCLES[@]}" "2" "Should detect 2 separate cycles"
}
```

**Test 5: Missing Dependencies**

```bash
test_missing_dependencies() {
  add_node "A.sh" "utility" "/tmp/A.sh"
  add_node "missing.sh" "missing" "/tmp/missing.sh"  # Phantom node

  add_edge "A.sh" "missing.sh" "direct_source" "line 1: source missing.sh" "high"

  local missing
  missing=$(detect_missing_dependencies)

  assert_not_equals "$missing" "[]" "Should detect missing dependency"
  assert_contains "$missing" "missing.sh" "Should identify missing.sh"
}
```

### Performance Benchmarks

```bash
# Benchmark graph construction
benchmark_graph_construction() {
  local start_time
  start_time=$(date +%s.%N)

  build_dependency_graph ".claude"

  local end_time
  end_time=$(date +%s.%N)
  local elapsed
  elapsed=$(echo "$end_time - $start_time" | bc)

  echo "Graph construction time: ${elapsed}s"
  assert_less_than "$elapsed" "10.0" "Construction must complete in <10s for 100 files"
}

# Benchmark cycle detection
benchmark_cycle_detection() {
  local start_time
  start_time=$(date +%s.%N)

  detect_cycles

  local end_time
  end_time=$(date +%s.%N)
  local elapsed
  elapsed=$(echo "$end_time - $start_time" | bc)

  echo "Cycle detection time: ${elapsed}s"
  assert_less_than "$elapsed" "5.0" "Cycle detection must complete in <5s"
}
```

## Success Criteria

### Functional Requirements

- ✓ **Dependency graph construction** - Successfully parses all .sh and .md files, extracts source dependencies and function calls
- ✓ **Circular dependency detection** - Detects 100% of cycles in test cases with correct path reconstruction
- ✓ **Transitive analysis accuracy** - Forward/backward propagation produces mathematically correct closures
- ✓ **Impact analysis completeness** - Identifies all affected components across utilities → commands → agents hierarchy
- ✓ **Edge case handling** - Gracefully handles self-loops, missing files, dynamic dependencies

### Performance Requirements

- Graph construction: <10 seconds for 100+ files
- Cycle detection: <5 seconds for any graph
- Transitive analysis: <2 seconds per query
- Memory usage: <100MB for typical .claude/ codebase

### Quality Requirements

- Zero false negatives in cycle detection (may have false positives for unresolvable dynamic deps)
- 100% test coverage for core algorithms (DFS, BFS, graph construction)
- Clear error messages for all edge cases
- JSON output format compatible with visualization tools (D3.js, Graphviz)

### Documentation Requirements

- Inline comments explaining algorithm complexity
- Usage examples for all public functions
- Architecture documentation explaining graph data structures
- Performance tuning guide for large codebases
