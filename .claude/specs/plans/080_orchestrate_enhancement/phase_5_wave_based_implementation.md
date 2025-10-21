# Phase 5: Wave-Based Implementation - [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md) Orchestration

## Metadata
- **Date**: 2025-10-21
- **Plan Level**: Level 1 (Phase Expansion)
- **Parent Plan**: [080_orchestrate_enhancement.md](../080_orchestrate_enhancement.md)
- **Phase Number**: 5
- **Complexity Score**: 10/10 (Maximum)
- **Expansion Reason**: Maximum complexity due to parallelism, state management, multi-agent coordination, and critical infrastructure role
- **Dependencies**: depends_on: [phase_4]
- **Estimated Duration**: 12-16 hours
- **Risk Level**: HIGH - Core orchestration infrastructure

## Overview

This phase implements wave-based [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md) with implementer-coordinator and implementation-executor agents to run independent phases concurrently. This is the most critical and complex phase of the /orchestrate enhancement, transforming sequential implementation into an intelligent [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md) system that can reduce implementation time by 40-60% for workflows with independent phases.

**Core Components**:
1. **dependency-analyzer Utility**: Builds dependency graphs and identifies execution waves
2. **implementer-coordinator Agent**: Orchestrates parallel wave execution and monitors progress
3. **implementation-executor Agent**: Executes individual phases/stages in parallel
4. **Progress Tracking System**: Real-time updates across plan hierarchy
5. **Checkpoint Management**: Context-aware checkpointing for resumable execution
6. **Wave Execution Engine**: Parallel task coordination with synchronization

**Key Innovation**: Unlike traditional sequential execution, this system analyzes phase dependencies and constructs execution "waves" where all phases in a wave WILL run simultaneously. This preserves correctness (dependent phases still run in order) while maximizing parallelism.

## Architecture

### Dependency Graph Construction

**Algorithm**: Topological Sort with Wave Identification

```yaml
Dependency Graph Structure:
 nodes:
  - phase_id: "phase_1"
   name: "Setup"
   dependencies: []
   blocks: ["phase_2", "phase_4"]
  - phase_id: "phase_2"
   name: "Backend Implementation"
   dependencies: ["phase_1"]
   blocks: ["phase_5"]
  - phase_id: "phase_3"
   name: "Frontend Implementation"
   dependencies: ["phase_1"]
   blocks: ["phase_5"]

 waves:
  - wave_number: 1
   phases: ["phase_1"]
   can_parallel: false
   estimated_duration: "2-3 hours"
  - wave_number: 2
   phases: ["phase_2", "phase_3"]
   can_parallel: true
   estimated_duration: "4-6 hours (parallel) vs 8-12 hours (sequential)"
   time_savings: "50%"
  - wave_number: 3
   phases: ["phase_5"]
   can_parallel: false
   estimated_duration: "2-3 hours"
```

**Wave Identification Rules**:
1. **Wave 1**: All phases with `dependencies: []` (no prerequisites)
2. **Wave N**: All phases whose dependencies are satisfied by waves 1 through N-1
3. **Parallelization**: Phases in the same wave WILL execute concurrently
4. **Synchronization**: Wave N+1 cannot start until all phases in Wave N complete

### State Management

**Implementation State Object** (maintained by implementer-coordinator):

```yaml
implementation_state:
 plan_path: "/path/to/specs/027_auth/plans/027_auth_implementation.md"
 topic_path: "/path/to/specs/027_auth"
 structure_level: 1 # 0: inline, 1: phase files, 2: stage files

 waves:
  - wave_number: 1
   status: "completed"
   start_time: "2025-10-21T10:00:00Z"
   end_time: "2025-10-21T12:30:00Z"
   phases:
    - phase_id: "phase_1"
     status: "completed"
     executor_id: "executor_1"
     tasks_completed: 10
     tasks_total: 10
     checkpoint_path: null
     commit_hash: "abc123"

  - wave_number: 2
   status: "in_progress"
   start_time: "2025-10-21T12:35:00Z"
   phases:
    - phase_id: "phase_2"
     status: "in_progress"
     executor_id: "executor_2"
     tasks_completed: 5
     tasks_total: 15
     current_task: "Implementing JWT token generation"
    - phase_id: "phase_3"
     status: "in_progress"
     executor_id: "executor_3"
     tasks_completed: 8
     tasks_total: 12
     current_task: "Building login component"

 metrics:
  total_phases: 5
  completed_phases: 1
  failed_phases: 0
  total_estimated_time: "16-24 hours (sequential)"
  parallel_estimated_time: "10-14 hours (40% savings)"
  actual_elapsed_time: "2.5 hours"
```

### [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md) Coordination

**Coordination Pattern**: Task Tool with Multiple Concurrent Invocations

```yaml
# implementer-coordinator invokes multiple executors in single response
 [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md) Example:
 Wave 2 Start:
  - Invoke executor_2 for phase_2 (Task tool invocation 1)
  - Invoke executor_3 for phase_3 (Task tool invocation 2)
  - Monitor both via Task tool responses
  - Wait for both to complete before Wave 3

 Synchronization:
  - All executors in wave must report completion
  - If any executor fails, mark failure but continue independent work
  - Collect progress from all executors
  - Aggregate results before proceeding to next wave
```

## Stage 1: Create dependency-analyzer Utility

**Objective**: Implement dependency graph construction and wave identification utility that parses plan files and builds execution structure.

**Complexity**: High (8/10)
**Estimated Duration**: 2-3 hours

### Tasks

#### 1.1: Create dependency-analyzer.sh Script

**File**: `.claude/lib/dependency-analyzer.sh`

**Core Functions**:

```bash
#!/usr/bin/env bash
# .claude/lib/dependency-analyzer.sh
# Builds dependency graphs and identifies execution waves from plan files

# Parse plan files to extract dependency metadata
# Input: plan_path (top-level plan file)
# Output: JSON dependency graph structure
parse_plan_dependencies() {
 local plan_path="$1"
 local structure_level
 local plan_dir
 local phases=()

 # Detect structure level (0=inline, 1=phase files, 2=stage files)
 structure_level=$(detect_structure_level "$plan_path")

 if [[ $structure_level -eq 0 ]]; then
  # Parse inline plan: extract dependency metadata from phase sections
  parse_inline_dependencies "$plan_path"
 elif [[ $structure_level -eq 1 ]]; then
  # Parse hierarchical plan: read all phase files
  plan_dir=$(dirname "$plan_path")/$(basename "$plan_path" .md)
  parse_hierarchical_dependencies "$plan_dir"
 elif [[ $structure_level -eq 2 ]]; then
  # Parse deep hierarchy: read phase files and stage files
  plan_dir=$(dirname "$plan_path")/$(basename "$plan_path" .md)
  parse_deep_dependencies "$plan_dir"
 fi
}

# Extract dependencies from phase/stage metadata
# Looks for: depends_on: [phase_1, phase_2]
extract_dependency_metadata() {
 local file_path="$1"
 local phase_id="$2"

 # Search for dependency metadata in various formats
 # Format 1: **Dependencies**: depends_on: [phase_1]
 # Format 2: - depends_on: [phase_1, phase_2]
 # Format 3: Dependencies: [phase_1]

 local dependencies
 dependencies=$(grep -i "depends_on:" "$file_path" | sed 's/.*depends_on:\s*\[\(.*\)\].*/\1/' | tr ',' '\n' | xargs)

 # Also check for "blocks" metadata (inverse dependencies)
 local blocks
 blocks=$(grep -i "blocks:" "$file_path" | sed 's/.*blocks:\s*\[\(.*\)\].*/\1/' | tr ',' '\n' | xargs)

 # Return JSON object
 cat <<EOF
{
 "phase_id": "$phase_id",
 "dependencies": [$(echo "$dependencies" | sed 's/ /, /g' | sed 's/\(phase_[0-9]*\)/"\1"/g')],
 "blocks": [$(echo "$blocks" | sed 's/ /, /g' | sed 's/\(phase_[0-9]*\)/"\1"/g')]
}
EOF
}

# Build dependency graph from parsed metadata
# Input: Array of phase dependency objects
# Output: Full dependency graph with topological sort
build_dependency_graph() {
 local -n phases_ref="$1"
 local graph=""
 local nodes=()
 local edges=()

 # Build adjacency list
 for phase in "${phases_ref[@]}"; do
  local phase_id=$(echo "$phase" | jq -r '.phase_id')
  local deps=$(echo "$phase" | jq -r '.dependencies[]')

  nodes+=("$phase_id")

  for dep in $deps; do
   edges+=("$dep -> $phase_id")
  done
 done

 # Perform topological sort (Kahn's algorithm)
 topological_sort "${nodes[@]}"
}

# Topological sort using Kahn's algorithm
# Input: Array of nodes with dependencies
# Output: Sorted array of nodes in execution order
topological_sort() {
 local -a nodes=("$@")
 local -A in_degree
 local -a sorted
 local -a queue

 # Calculate in-degree for each node
 for node in "${nodes[@]}"; do
  in_degree[$node]=0
 done

 for edge in "${edges[@]}"; do
  local target=$(echo "$edge" | cut -d' ' -f3)
  ((in_degree[$target]++))
 done

 # Add nodes with in-degree 0 to queue (Wave 1)
 for node in "${nodes[@]}"; do
  if [[ ${in_degree[$node]} -eq 0 ]]; then
   queue+=("$node")
  fi
 done

 # Process queue and build sorted array
 while [[ ${#queue[@]} -gt 0 ]]; do
  local current="${queue[0]}"
  queue=("${queue[@]:1}")
  sorted+=("$current")

  # Reduce in-degree for dependent nodes
  for edge in "${edges[@]}"; do
   local source=$(echo "$edge" | cut -d' ' -f1)
   local target=$(echo "$edge" | cut -d' ' -f3)

   if [[ "$source" == "$current" ]]; then
    ((in_degree[$target]--))
    if [[ ${in_degree[$target]} -eq 0 ]]; then
     queue+=("$target")
    fi
   fi
  done
 done

 # Return sorted array
 echo "${sorted[@]}"
}

# Identify execution waves from dependency graph
# Input: Dependency graph (topologically sorted)
# Output: Wave structure with parallelization opportunities
identify_waves() {
 local dependency_graph="$1"
 local waves=()
 local wave_number=1
 local remaining_phases

 remaining_phases=$(echo "$dependency_graph" | jq -r '.nodes[].phase_id')

 while [[ -n "$remaining_phases" ]]; do
  local wave_phases=()

  # Find all phases whose dependencies are satisfied
  for phase in $remaining_phases; do
   local deps=$(echo "$dependency_graph" | jq -r ".nodes[] | select(.phase_id == \"$phase\") | .dependencies[]")
   local deps_satisfied=true

   for dep in $deps; do
    # Check if dependency is in previous waves (completed)
    if echo "$remaining_phases" | grep -q "$dep"; then
     deps_satisfied=false
     break
    fi
   done

   if [[ "$deps_satisfied" == true ]]; then
    wave_phases+=("$phase")
   fi
  done

  # Create wave object
  waves+=("{\"wave_number\": $wave_number, \"phases\": [$(printf '\"%s\",' "${wave_phases[@]}" | sed 's/,$//')]}")

  # Remove wave phases from remaining
  for phase in "${wave_phases[@]}"; do
   remaining_phases=$(echo "$remaining_phases" | grep -v "$phase")
  done

  ((wave_number++))
 done

 # Return wave structure
 echo "[$(printf '%s,' "${waves[@]}" | sed 's/,$//')]"
}

# Calculate parallelization metrics
# Input: Wave structure
# Output: Estimated time savings and parallelization factor
calculate_parallelization_metrics() {
 local waves="$1"
 local total_phases=0
 local parallel_phases=0
 local sequential_time=0
 local parallel_time=0

 # Count phases per wave
 for wave in $(echo "$waves" | jq -c '.[]'); do
  local phase_count=$(echo "$wave" | jq '.phases | length')
  total_phases=$((total_phases + phase_count))

  if [[ $phase_count -gt 1 ]]; then
   parallel_phases=$((parallel_phases + phase_count - 1))
  fi

  # Estimate time (assume 2-4 hours per phase average)
  local wave_time=3 # hours (average)
  sequential_time=$((sequential_time + phase_count * wave_time))
  parallel_time=$((parallel_time + wave_time))
 done

 local time_savings=$((100 - (parallel_time * 100 / sequential_time)))

 cat <<EOF
{
 "total_phases": $total_phases,
 "parallel_phases": $parallel_phases,
 "sequential_estimated_time": "$sequential_time hours",
 "parallel_estimated_time": "$parallel_time hours",
 "time_savings_percentage": "$time_savings%"
}
EOF
}

# Main entry point
analyze_dependencies() {
 local plan_path="$1"

 # Parse dependencies
 local dependency_graph
 dependency_graph=$(parse_plan_dependencies "$plan_path")

 # Identify waves
 local waves
 waves=$(identify_waves "$dependency_graph")

 # Calculate metrics
 local metrics
 metrics=$(calculate_parallelization_metrics "$waves")

 # Return complete analysis
 cat <<EOF
{
 "dependency_graph": $dependency_graph,
 "waves": $waves,
 "metrics": $metrics
}
EOF
}
```

**Testing**:
```bash
# Test dependency analysis on simple plan (sequential)
bash .claude/lib/dependency-analyzer.sh specs/test_plan_sequential.md
# Expected: 1 phase per wave, 0% time savings

# Test dependency analysis on parallel plan
bash .claude/lib/dependency-analyzer.sh specs/test_plan_parallel.md
# Expected: Multiple phases in Wave 2+, 40-60% time savings

# Test with hierarchical plan (Level 1)
bash .claude/lib/dependency-analyzer.sh specs/027_auth/plans/027_auth_implementation.md
# Expected: Reads all phase files, builds graph, identifies waves
```

#### 1.2: Implement Cycle Detection

Prevent infinite loops from circular dependencies:

```bash
# Detect cycles in dependency graph using DFS
# Returns: true if cycle detected, false otherwise
detect_dependency_cycles() {
 local dependency_graph="$1"
 local -A visited
 local -A recursion_stack

 for node in $(echo "$dependency_graph" | jq -r '.nodes[].phase_id'); do
  if ! ${visited[$node]:-false}; then
   if detect_cycle_dfs "$node" "$dependency_graph"; then
    echo "ERROR: Circular dependency detected involving $node" >&2
    return 1
   fi
  fi
 done

 return 0
}

# DFS helper for cycle detection
detect_cycle_dfs() {
 local node="$1"
 local graph="$2"

 visited[$node]=true
 recursion_stack[$node]=true

 # Visit all dependencies
 local deps=$(echo "$graph" | jq -r ".nodes[] | select(.phase_id == \"$node\") | .dependencies[]")
 for dep in $deps; do
  if ! ${visited[$dep]:-false}; then
   if detect_cycle_dfs "$dep" "$graph"; then
    return 1
   fi
  elif ${recursion_stack[$dep]:-false}; then
   echo "ERROR: Cycle detected: $node -> $dep" >&2
   return 1
  fi
 done

 recursion_stack[$node]=false
 return 0
}
```

#### 1.3: Add Validation and Error Handling

```bash
# Validate dependency metadata format
validate_dependency_syntax() {
 local file_path="$1"

 # Check for malformed dependency declarations
 if grep -q "depends_on:" "$file_path"; then
  # Validate format: depends_on: [phase_1, phase_2]
  if ! grep "depends_on:" "$file_path" | grep -q "\[.*\]"; then
   echo "ERROR: Invalid depends_on format in $file_path (missing brackets)" >&2
   return 1
  fi
 fi

 # Check for unknown phase references
 local declared_phases=$(grep -E "^###?\s+Phase\s+[0-9]+" "$file_path" | sed 's/.*Phase\s\+\([0-9]\+\).*/phase_\1/')
 local referenced_phases=$(grep "depends_on:" "$file_path" | sed 's/.*depends_on:\s*\[\(.*\)\].*/\1/' | tr ',' '\n')

 for ref in $referenced_phases; do
  if ! echo "$declared_phases" | grep -q "$ref"; then
   echo "WARNING: Unknown phase reference: $ref in $file_path" >&2
  fi
 done

 return 0
}
```

**Completion Checklist**:
- [ ] dependency-analyzer.sh created with all functions
- [ ] Topological sort algorithm implemented (Kahn's algorithm)
- [ ] Wave identification working (groups independent phases)
- [ ] Cycle detection prevents infinite loops
- [ ] Validation catches malformed metadata
- [ ] Unit tests passing (sequential, parallel, hierarchical plans)
- [ ] Error handling for missing dependencies
- [ ] Performance: Analyzes 20-phase plan in <1 second

**Expected Output Example**:
```json
{
 "dependency_graph": {
  "nodes": [
   {"phase_id": "phase_1", "name": "Setup", "dependencies": [], "blocks": ["phase_2", "phase_3"]},
   {"phase_id": "phase_2", "name": "Backend", "dependencies": ["phase_1"], "blocks": ["phase_4"]},
   {"phase_id": "phase_3", "name": "Frontend", "dependencies": ["phase_1"], "blocks": ["phase_4"]}
  ]
 },
 "waves": [
  {"wave_number": 1, "phases": ["phase_1"]},
  {"wave_number": 2, "phases": ["phase_2", "phase_3"]},
  {"wave_number": 3, "phases": ["phase_4"]}
 ],
 "metrics": {
  "total_phases": 4,
  "parallel_phases": 1,
  "sequential_estimated_time": "12 hours",
  "parallel_estimated_time": "9 hours",
  "time_savings_percentage": "25%"
 }
}
```

---

## Stage 2: Create implementer-coordinator Agent

**Objective**: Implement orchestration agent that manages wave-based [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md), monitors multiple executors, and handles synchronization.

**Complexity**: Very High (9/10)
**Estimated Duration**: 3-4 hours

### Tasks

#### 2.1: Create implementer-coordinator.md Agent

**File**: `.claude/agents/implementer-coordinator.md`

**Agent Behavioral Specification**:

```markdown
# Implementer Coordinator Agent

## Role
YOU ARE the wave-based implementation coordinator responsible for orchestrating parallel phase execution using the dependency-analyzer utility and implementation-executor subagents.

## Core Responsibilities

1. **Dependency Analysis**: Invoke dependency-analyzer to build execution structure
2. **Wave Orchestration**: Execute phases wave-by-wave with parallel executors
3. **Progress Monitoring**: Collect updates from all executors in real-time
4. **State Management**: Maintain implementation state across waves
5. **Failure Handling**: Detect failures, mark phases, continue independent work
6. **Result Aggregation**: Collect completion reports and metrics

## Workflow

### Input Format
You WILL receive:
- **plan_path**: Absolute path to top-level plan file (Level 0)
- **topic_path**: Topic directory path for artifact organization
- **artifact_paths**: Pre-calculated paths for debug, outputs, checkpoints

### Phase 1: Plan Structure Detection

1. **Read Plan File**: Load top-level plan to check structure
2. **Detect Structure Level**:
  - Level 0: All phases inline in single file
  - Level 1: Phases in separate files (plan_dir/phase_N.md)
  - Level 2: Stages in separate files (plan_dir/phase_N/stage_M.md)
3. **Build File List**:
  - If Level 0: Single plan file
  - If Level 1: Read all phase_*.md files in plan directory
  - If Level 2: Read all phase and stage files recursively

### Phase 2: Dependency Analysis

1. **Invoke dependency-analyzer Utility**:
  ```bash
  bash .claude/lib/dependency-analyzer.sh "$plan_path" > dependency_analysis.json
  ```
2. **Parse Analysis Results**:
  - Extract dependency graph (nodes, edges)
  - Extract wave structure (wave_number, phases per wave)
  - Extract parallelization metrics (time savings estimate)
3. **Validate Dependency Graph**:
  - Check for cycles (circular dependencies)
  - Verify all phase references valid
  - Confirm at least 1 phase in Wave 1 (starting point)

### Phase 3: Wave Execution Loop

FOR EACH wave in wave structure:

1. **Wave Initialization**:
  - Log wave start: "Starting Wave {N}: {phase_count} phases"
  - Create wave state object
  - Initialize executor tracking

2. **Parallel Executor Invocation**:
  - For each phase in wave, invoke implementation-executor subagent
  - Use Task tool with multiple invocations in single response
  - Pass to each executor:
   - phase_file_path: Path to phase/stage plan file
   - topic_path: For debug reports, outputs
   - wave_number: Current wave
   - phase_number: Within plan

  Example:
  ```
  Task {
   subagent_type: "general-purpose"
   description: "Execute Phase 2 implementation in parallel"
   prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/implementation-executor.md

    You are executing Phase 2: Backend Implementation

    Input:
    - phase_file_path: /path/to/phase_2_backend.md
    - topic_path: /path/to/specs/027_auth
    - wave_number: 2
    - phase_number: 2

    Execute all tasks in this phase, update plan file with progress,
    run tests, create git commit, report completion.
  }

  Task {
   subagent_type: "general-purpose"
   description: "Execute Phase 3 implementation in parallel"
   prompt: |
    [Similar for Phase 3]
  }
  ```

3. **Progress Monitoring**:
  - Collect progress updates from each executor
  - Update wave state with task completion counts
  - Display real-time progress to user:
   ```
   Wave 2 Progress:
   ├─ Phase 2 (Backend): ████████░░░░░░░░░░ 40% (6/15 tasks)
   └─ Phase 3 (Frontend): ██████████████░░░░ 70% (7/10 tasks)
   ```

4. **Wave Synchronization**:
  - Wait for ALL executors in wave to complete
  - Collect completion reports from each executor
  - Aggregate results: successes, failures, checkpoints
  - Update implementation state

5. **Failure Handling**:
  - If any executor fails:
   - Mark phase as failed in state
   - Log failure details
   - Continue with independent phases (don't block Wave N+1 unless dependency)
   - Report failure to orchestrator for debugging decision

6. **Wave Completion**:
  - Log wave end: "Wave {N} complete: {success_count}/{total_count} phases succeeded"
  - Update plan hierarchy (mark wave phases complete)
  - Proceed to next wave

### Phase 4: Result Aggregation

After all waves complete:

1. **Collect Implementation Metrics**:
  - Total phases executed
  - Successful phases
  - Failed phases
  - Total elapsed time
  - Estimated time savings vs sequential
  - Git commits created

2. **Return Implementation Report**:
  ```yaml
  implementation_report:
   status: "completed" | "partial" | "failed"
   waves_executed: N
   total_phases: N
   successful_phases: N
   failed_phases: N
   elapsed_time: "X hours"
   estimated_sequential_time: "Y hours"
   time_savings: "Z%"
   git_commits: [list of commit hashes]
   checkpoints: [list of checkpoint paths if any]
   failed_phase_details: [list if failures occurred]
  ```

## Error Handling

### Context Window Constraints
- If any executor reports context pressure, it will create checkpoint
- Coordinator receives checkpoint path in progress update
- Log checkpoint for potential /resume-implement later
- Continue with other executors

### Executor Failures
- If executor fails (exception, timeout, error):
 - Mark phase as failed
 - Save executor error details
 - Check if failure blocks subsequent waves (dependency check)
 - If blocks: Halt remaining waves, return partial completion
 - If independent: Continue with remaining work

### Dependency Violations
- If executor reports missing dependency:
 - Log dependency violation error
 - Re-run dependency analysis to debug
 - Halt execution and return error

## Output Format

Return ONLY the implementation report in this format:

```
IMPLEMENTATION REPORT
Status: {completed|partial|failed}
Waves Executed: {N}
Total Phases: {N}
Successful: {N}
Failed: {N}
Elapsed Time: {X hours}
Time Savings: {Z%}
Git Commits: {count}
Checkpoints: {paths if any}
```

If failures:
```
FAILED PHASES:
- Phase {N}: {name} - {error summary}
- Phase {M}: {name} - {error summary}
```

## Notes

### Parallelization Strategy
- Maximize parallelism: All independent phases in same wave run concurrently
- Preserve correctness: Dependent phases always run after their dependencies
- Target: 40-60% time savings for typical workflows with 2-4 parallel phases

### State Management
- Maintain implementation_state object throughout execution
- Update after each task completion (from executor reports)
- Persist state to checkpoint if context constrained

### Context Efficiency
- Receive: Phase file paths + dependency graph (not full plan content)
- Executors return: Brief progress summaries (not full implementation details)
- Target: <20% context usage for entire implementation phase
```

#### 2.2: Implement Progress Aggregation

**Progress Update Handling**:

Executors send progress updates in this format:
```yaml
progress_update:
 phase_id: "phase_2"
 wave_number: 2
 executor_id: "executor_2"
 tasks_completed: 5
 tasks_total: 15
 percentage: 33
 current_task: "Implementing JWT token generation"
 status: "in_progress" | "completed" | "failed"
```

Coordinator aggregates and displays:
```
Wave 2 Progress (2/2 executors active):
├─ Phase 2: Backend Implementation
│ ├─ Status: In Progress (33%)
│ ├─ Tasks: 5/15 complete
│ └─ Current: Implementing JWT token generation
│
└─ Phase 3: Frontend Implementation
  ├─ Status: In Progress (70%)
  ├─ Tasks: 7/10 complete
  └─ Current: Building login component

Estimated Wave Completion: 45 minutes
```

#### 2.3: Add Wave Synchronization Logic

**Synchronization Checkpoints**:

1. **Before Wave Start**: Verify all previous waves completed
2. **During Wave**: Monitor all executors for completion signals
3. **Wave Completion**: Wait until all executors report done
4. **Failure Detection**: If any executor fails, decide continuation strategy

**Pseudo-code**:
```python
for wave in waves:
  # Wait for previous wave to complete
  if wave.wave_number > 1:
    wait_for_wave_completion(wave.wave_number - 1)

  # Start all executors in parallel
  executors = []
  for phase in wave.phases:
    executor = invoke_implementation_executor(phase)
    executors.append(executor)

  # Monitor until all complete
  while not all_executors_complete(executors):
    collect_progress_updates(executors)
    update_display()
    sleep(5) # Poll every 5 seconds

  # Aggregate results
  wave_results = collect_wave_results(executors)
  update_implementation_state(wave_results)

  # Check for blocking failures
  if has_blocking_failures(wave_results):
    halt_remaining_waves()
    return partial_completion_report()
```

**Completion Checklist**:
- [ ] implementer-coordinator.md created with complete behavioral spec
- [ ] Plan structure detection working (Level 0, 1, 2)
- [ ] Dependency analysis integration working (calls dependency-analyzer.sh)
- [ ] Wave execution loop implemented
- [ ] Parallel executor invocation working (multiple Task tool calls)
- [ ] Progress monitoring and aggregation working
- [ ] Wave synchronization ensures correctness
- [ ] Failure handling preserves independent work
- [ ] Result aggregation produces complete report
- [ ] Context usage <20% for coordination overhead

---

## Stage 3: Create implementation-executor Agent

**Objective**: Implement worker agent that executes individual phases/stages, updates plan hierarchy, runs tests, creates checkpoints, and reports progress.

**Complexity**: High (8/10)
**Estimated Duration**: 3-4 hours

### Tasks

#### 3.1: Create implementation-executor.md Agent

**File**: `.claude/agents/implementation-executor.md`

**Agent Behavioral Specification**:

```markdown
# Implementation Executor Agent

## Role
YOU ARE an implementation executor responsible for executing a single phase or stage of an implementation plan, updating progress in the plan hierarchy, running tests, and creating git commits.

## Core Responsibilities

1. **Task Execution**: Implement all tasks in assigned phase/stage sequentially
2. **Plan Updates**: Mark tasks complete and update plan hierarchy
3. **Testing**: Run tests after task batches and at phase completion
4. **Progress Reporting**: Send brief updates to coordinator
5. **Checkpoint Creation**: Save checkpoints if context constrained
6. **Git Commits**: Create commit after phase completion

## Workflow

### Input Format
You WILL receive:
- **phase_file_path**: Absolute path to phase/stage plan file
- **topic_path**: Topic directory for artifacts
- **wave_number**: Current wave (for logging)
- **phase_number**: Phase identifier

### Phase 1: Plan Reading and Setup

1. **Read Phase File**: Load phase/stage plan from file path
2. **Extract Tasks**: Parse all checkbox tasks from plan
3. **Identify Testing Requirements**: Extract test commands from plan
4. **Check Dependencies**: Verify dependencies satisfied (MUST be, coordinator checked)
5. **Initialize Progress Tracking**: Set up task counter, start time

### Phase 2: Task Execution Loop

FOR EACH task in phase:

1. **Execute Task**:
  - Implement the task (write code, update configs, etc.)
  - Follow project standards from CLAUDE.md
  - Use appropriate tools (Edit for existing files, Write for new files)

2. **Mark Task Complete**:
  - Update phase file: Change `- [ ]` to `- [x]` for completed task
  - Use Edit tool to update checkbox

3. **Update Plan Hierarchy** (every 3-5 tasks):
  - Propagate progress to parent plans:
   - If L2 (stage file): Update L1 phase file
   - If L1 (phase file): Update L0 main plan
  - Use spec-updater pattern for hierarchy updates

4. **Report Progress to Coordinator**:
  - Send brief progress update:
   ```yaml
   progress_update:
    phase_id: "phase_2"
    tasks_completed: 5
    tasks_total: 15
    percentage: 33
    current_task: "Implementing JWT token generation"
    status: "in_progress"
   ```

5. **Run Tests** (after every 3-5 tasks):
  - Execute test command from plan
  - If tests fail: Log failure, continue (don't block)
  - If tests pass: Continue to next task

### Phase 3: Phase Completion

After all tasks complete:

1. **Run Full Test Suite**:
  - Execute comprehensive tests for this phase
  - Capture test output
  - If tests fail: Report failure to coordinator

2. **Update Plan Hierarchy**:
  - Mark all tasks complete in phase file
  - Update parent plans with phase completion status
  - Propagate checkboxes through all levels

3. **Create Git Commit**:
  - Generate standardized commit message:
   - Format: `feat(NNN): complete Phase {N} - {phase_name}`
   - Example: `feat(027): complete Phase 2 - Backend Implementation`
  - Create commit with all modified files
  - Capture commit hash

4. **Return Completion Report**:
  ```yaml
  completion_report:
   phase_id: "phase_2"
   status: "completed" | "failed"
   tasks_completed: 15
   tasks_total: 15
   tests_passing: true | false
   test_failures: [list if any]
   commit_hash: "abc123"
   elapsed_time: "2.5 hours"
   checkpoint_path: null | "/path/to/checkpoint.json"
  ```

### Phase 4: Checkpoint Management (if needed)

If context window approaching limit:

1. **Create Checkpoint**:
  - Save current progress to `.claude/data/checkpoints/{topic}_{phase}.json`
  - Include: phase_id, tasks_completed, current_task, plan_state

2. **Update Plan Files**:
  - Mark partial progress in phase file
  - Update parent plans with checkpoint marker

3. **Return Checkpoint Report**:
  - Include checkpoint path in completion report
  - Coordinator WILL resume via /resume-implement

## Error Handling

### Test Failures
- If tests fail during task execution: Log and continue
- If tests fail at phase completion: Mark phase as failed, report to coordinator
- Coordinator will invoke debug loop if needed

### Task Execution Errors
- If task fails (exception, missing file, etc.):
 - Log error details
 - Mark task as failed in plan
 - Report error to coordinator
 - Halt execution (don't continue with remaining tasks)

### Dependency Errors
- If dependency missing (file not found, module not available):
 - Report dependency error to coordinator
 - Coordinator WILL have scheduled phases out of order
 - Halt execution

## Output Format

Return ONLY the completion report:

```
PHASE EXECUTION REPORT
Phase: {phase_id}
Status: {completed|failed}
Tasks: {N}/{M} complete
Tests: {passing|failing}
Commit: {hash}
Elapsed: {X hours}
```

If failed:
```
FAILURE DETAILS:
- Task: {task_name}
- Error: {error_summary}
- Test Output: {path_to_test_output}
```

## Notes

### Progress Granularity
- Update coordinator every 3-5 tasks (not every task)
- Reduces context overhead from progress updates
- Still provides reasonable real-time visibility

### Plan Hierarchy Updates
- Critical for wave-based execution visibility
- User WILL see progress across all levels (L0, L1, L2)
- Use spec-updater pattern to maintain consistency

### Checkpoint Strategy
- Only create checkpoint if context >70% full
- Prefer completing phase without checkpoint
- If checkpoint needed, ensure plan state saved properly
```

#### 3.2: Implement Hierarchical Plan Updates

**Checkbox Propagation Logic**:

```python
# Pseudo-code for hierarchical updates
def update_plan_hierarchy(level, file_path, task_id, status):
  # Update current level
  update_checkbox(file_path, task_id, status)

  # Propagate to parent
  if level == 2: # Stage file
    parent_path = get_parent_phase_file(file_path)
    update_checkbox(parent_path, f"Stage {stage_num}", "in_progress")
    update_plan_hierarchy(1, parent_path, f"Stage {stage_num}", status)

  elif level == 1: # Phase file
    parent_path = get_parent_plan_file(file_path)
    update_checkbox(parent_path, f"Phase {phase_num}", "in_progress")

  # Level 0 is top, no further propagation

# Example: Stage 1 task complete in Phase 2
update_plan_hierarchy(
  level=2,
  file_path="phase_2_backend/stage_1_database.md",
  task_id="Create users table",
  status="complete"
)

# Results in:
# - stage_1_database.md: [x] Create users table
# - phase_2_backend.md: [~] Stage 1: Database (in progress)
# - 027_auth_implementation.md: [~] Phase 2: Backend (in progress)
```

#### 3.3: Add Test Execution Integration

**Test Command Discovery**:

```bash
# Extract test command from phase file
extract_test_command() {
 local phase_file="$1"

 # Look for testing section in phase file
 # Format: ## Testing\n```bash\nnpm test\n```

 local test_cmd
 test_cmd=$(sed -n '/^## Testing/,/^```$/p' "$phase_file" | grep -v '```' | grep -v '^##' | head -1)

 if [[ -z "$test_cmd" ]]; then
  # Fallback: Use project-wide test command from CLAUDE.md
  test_cmd=$(grep -A5 "Testing Protocols" CLAUDE.md | grep "Test Command" | cut -d':' -f2 | xargs)
 fi

 echo "$test_cmd"
}

# Execute tests and capture output
run_phase_tests() {
 local phase_file="$1"
 local topic_path="$2"

 local test_cmd=$(extract_test_command "$phase_file")

 if [[ -z "$test_cmd" ]]; then
  echo "WARNING: No test command found, skipping tests"
  return 0
 fi

 # Run tests and capture output
 local test_output="$topic_path/outputs/test_phase_${phase_num}.txt"
 $test_cmd > "$test_output" 2>&1
 local test_exit_code=$?

 if [[ $test_exit_code -eq 0 ]]; then
  echo "✓ Tests passed"
  return 0
 else
  echo "✗ Tests failed (exit code: $test_exit_code)"
  echo "Test output: $test_output"
  return 1
 fi
}
```

**Completion Checklist**:
- [ ] implementation-executor.md created with complete behavioral spec
- [ ] Task execution loop working (reads tasks, executes, updates)
- [ ] Plan hierarchy updates working (L2→L1→L0 propagation)
- [ ] Progress reporting every 3-5 tasks
- [ ] Test execution after task batches
- [ ] Full test suite at phase completion
- [ ] Git commit creation with standardized message
- [ ] Checkpoint creation when context constrained
- [ ] Completion report generation
- [ ] Error handling for task failures, test failures, dependency errors

---

## Stage 4: Implement Progress Tracking

**Objective**: Implement real-time progress visualization and state management for wave-based execution.

**Complexity**: Medium (6/10)
**Estimated Duration**: 2-3 hours

### Tasks

#### 4.1: Create Progress Visualization System

**Progress Display Format**:

```
╔══════════════════════════════════════════════════════════════╗
║ WAVE-BASED IMPLEMENTATION PROGRESS             ║
╠══════════════════════════════════════════════════════════════╣
║ Plan: 027_auth_implementation.md              ║
║ Topic: specs/027_auth                    ║
║ Structure: Level 1 (4 phases in 3 waves)          ║
║ Estimated Sequential Time: 12 hours             ║
║ Estimated Parallel Time: 7 hours (42% savings)       ║
╠══════════════════════════════════════════════════════════════╣
║ Wave 1: Setup (1 phase)                   ║
║ ✓ Complete                         ║
║ ├─ Phase 1: Project Setup                  ║
║ │ └─ ████████████████████████████ 100% (10/10 tasks)    ║
║ │   Elapsed: 1.2 hours                  ║
║ │   Commit: abc123                    ║
╠══════════════════════════════════════════════════════════════╣
║ Wave 2: Implementation (2 phases, parallel)         ║
║ ⏳ In Progress (started 14:30, ~45 min remaining)      ║
║ ├─ Phase 2: Backend Implementation             ║
║ │ └─ ████████████░░░░░░░░░░░░░░░ 40% (6/15 tasks)     ║
║ │   Current: Implementing JWT token generation      ║
║ │   Tests: Passing                    ║
║ │                              ║
║ └─ Phase 3: Frontend Implementation             ║
║   └─ ██████████████████░░░░░░░░░ 70% (7/10 tasks)     ║
║    Current: Building login component           ║
║    Tests: Passing                    ║
╠══════════════════════════════════════════════════════════════╣
║ Wave 3: Integration (1 phase)                ║
║ ⏸ Waiting for Wave 2 completion              ║
║ └─ Phase 4: Integration Testing               ║
║   └─ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 0% (0/8 tasks)      ║
╚══════════════════════════════════════════════════════════════╝

Overall Progress: ██████████░░░░░░░░░░ 50% (23/43 total tasks)
Elapsed Time: 2.7 hours
Estimated Remaining: 4.3 hours
```

**Implementation**:

```bash
#!/usr/bin/env bash
# .claude/lib/progress-tracker.sh

# Display wave-based progress
display_wave_progress() {
 local implementation_state="$1"

 # Extract state variables
 local total_phases=$(echo "$implementation_state" | jq '.metrics.total_phases')
 local completed_phases=$(echo "$implementation_state" | jq '.metrics.completed_phases')
 local waves=$(echo "$implementation_state" | jq -c '.waves[]')

 # Header
 echo "╔══════════════════════════════════════════════════════════════╗"
 echo "║ WAVE-BASED IMPLEMENTATION PROGRESS             ║"
 echo "╠══════════════════════════════════════════════════════════════╣"

 # Wave-by-wave progress
 for wave in $waves; do
  local wave_num=$(echo "$wave" | jq '.wave_number')
  local wave_status=$(echo "$wave" | jq -r '.status')
  local phase_count=$(echo "$wave" | jq '.phases | length')

  # Wave header
  if [[ "$wave_status" == "completed" ]]; then
   echo "║ Wave $wave_num: ✓ Complete                  ║"
  elif [[ "$wave_status" == "in_progress" ]]; then
   echo "║ Wave $wave_num: ⏳ In Progress                ║"
  else
   echo "║ Wave $wave_num: ⏸ Waiting                  ║"
  fi

  # Phase progress bars
  local phases=$(echo "$wave" | jq -c '.phases[]')
  for phase in $phases; do
   local phase_id=$(echo "$phase" | jq -r '.phase_id')
   local tasks_done=$(echo "$phase" | jq '.tasks_completed')
   local tasks_total=$(echo "$phase" | jq '.tasks_total')
   local percent=$((tasks_done * 100 / tasks_total))

   # Progress bar
   local bar_length=30
   local filled=$((bar_length * percent / 100))
   local empty=$((bar_length - filled))
   local bar=$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))

   echo "║ ├─ $phase_id                       ║"
   echo "║ │ └─ $bar $percent% ($tasks_done/$tasks_total tasks)    ║"

   if [[ "$wave_status" == "in_progress" ]]; then
    local current=$(echo "$phase" | jq -r '.current_task')
    echo "║ │   Current: $current                 ║"
   fi
  done

  echo "╠══════════════════════════════════════════════════════════════╣"
 done

 # Footer
 echo "╚══════════════════════════════════════════════════════════════╝"
}

# Update progress display (called periodically)
update_progress_display() {
 local state_file="$1"

 # Clear screen and redraw
 clear
 display_wave_progress "$(cat "$state_file")"
}
```

#### 4.2: Implement State Persistence

**State File Format** (`.claude/data/states/implementation_state_{topic}.json`):

```json
{
 "plan_path": "/path/to/plan.md",
 "topic_path": "/path/to/specs/027_auth",
 "structure_level": 1,
 "start_time": "2025-10-21T14:00:00Z",
 "waves": [
  {
   "wave_number": 1,
   "status": "completed",
   "start_time": "2025-10-21T14:00:00Z",
   "end_time": "2025-10-21T15:12:00Z",
   "phases": [
    {
     "phase_id": "phase_1",
     "phase_name": "Project Setup",
     "status": "completed",
     "executor_id": "executor_1",
     "tasks_completed": 10,
     "tasks_total": 10,
     "commit_hash": "abc123"
    }
   ]
  },
  {
   "wave_number": 2,
   "status": "in_progress",
   "start_time": "2025-10-21T15:15:00Z",
   "phases": [
    {
     "phase_id": "phase_2",
     "status": "in_progress",
     "tasks_completed": 6,
     "tasks_total": 15,
     "current_task": "Implementing JWT token generation"
    },
    {
     "phase_id": "phase_3",
     "status": "in_progress",
     "tasks_completed": 7,
     "tasks_total": 10,
     "current_task": "Building login component"
    }
   ]
  }
 ],
 "metrics": {
  "total_phases": 4,
  "completed_phases": 1,
  "failed_phases": 0,
  "total_tasks": 43,
  "completed_tasks": 23
 }
}
```

**State Update Functions**:

```bash
# Update phase progress in state file
update_phase_progress() {
 local state_file="$1"
 local wave_num="$2"
 local phase_id="$3"
 local tasks_completed="$4"
 local current_task="$5"

 # Use jq to update state
 jq ".waves[$wave_num].phases[] |= if .phase_id == \"$phase_id\" then .tasks_completed = $tasks_completed | .current_task = \"$current_task\" else . end" "$state_file" > "${state_file}.tmp"
 mv "${state_file}.tmp" "$state_file"
}

# Mark wave complete
complete_wave() {
 local state_file="$1"
 local wave_num="$2"

 jq ".waves[$wave_num].status = \"completed\" | .waves[$wave_num].end_time = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$state_file" > "${state_file}.tmp"
 mv "${state_file}.tmp" "$state_file"
}
```

**Completion Checklist**:
- [ ] Progress visualization displays all waves and phases
- [ ] Real-time updates every 5-10 seconds
- [ ] Progress bars accurate (match task completion)
- [ ] State persistence working (JSON file updates)
- [ ] State restoration after coordinator restarts
- [ ] Unicode box-drawing renders correctly
- [ ] Progress display fits in 80-column terminal

---

## Stage 5: Implement Checkpoint Management

**Objective**: Implement context-aware checkpointing for resumable execution when context window approaches limits.

**Complexity**: Medium (7/10)
**Estimated Duration**: 2-3 hours

### Tasks

#### 5.1: Create Checkpoint Detection Logic

**Context Monitoring**:

```python
# Pseudo-code for context monitoring
class ContextMonitor:
  def __init__(self, max_tokens=200000):
    self.max_tokens = max_tokens
    self.current_tokens = 0
    self.checkpoint_threshold = 0.70 # 70% of max

  def update_token_count(self, new_tokens):
    self.current_tokens += new_tokens

  def should_checkpoint(self):
    usage_percent = self.current_tokens / self.max_tokens
    return usage_percent >= self.checkpoint_threshold

  def get_usage_percent(self):
    return (self.current_tokens / self.max_tokens) * 100

# In implementation-executor:
if context_monitor.should_checkpoint():
  create_checkpoint(phase_id, current_progress)
  return checkpoint_report()
```

#### 5.2: Implement Checkpoint Creation

**Checkpoint File Format** (`.claude/data/checkpoints/{topic}_{phase}.json`):

```json
{
 "checkpoint_id": "027_auth_phase_2_20251021_153045",
 "created_at": "2025-10-21T15:30:45Z",
 "plan_path": "/path/to/specs/027_auth/plans/027_auth_implementation.md",
 "topic_path": "/path/to/specs/027_auth",
 "phase_id": "phase_2",
 "phase_file": "/path/to/specs/027_auth/plans/027_auth_implementation/phase_2_backend.md",
 "wave_number": 2,
 "progress": {
  "tasks_total": 15,
  "tasks_completed": 6,
  "current_task_index": 6,
  "current_task": "Implementing JWT token generation",
  "tasks_remaining": [
   "Add JWT token validation",
   "Implement token refresh logic",
   "Add session management",
   "..."
  ]
 },
 "plan_state": {
  "completed_tasks": [
   "Create database schema",
   "Implement user model",
   "Add password hashing",
   "Create authentication middleware",
   "Implement login endpoint",
   "Add registration endpoint"
  ]
 },
 "test_results": {
  "last_run": "2025-10-21T15:25:00Z",
  "status": "passing",
  "failures": []
 },
 "context_usage": {
  "tokens_used": 140000,
  "max_tokens": 200000,
  "percentage": 70
 }
}
```

**Checkpoint Functions**:

```bash
#!/usr/bin/env bash
# .claude/lib/checkpoint-manager.sh

# Create checkpoint for phase execution
create_implementation_checkpoint() {
 local topic_path="$1"
 local phase_id="$2"
 local phase_file="$3"
 local tasks_completed="$4"
 local current_task="$5"

 # Generate checkpoint ID
 local timestamp=$(date +%Y%m%d_%H%M%S)
 local checkpoint_id="${topic_path##*/}_${phase_id}_${timestamp}"
 local checkpoint_file=".claude/data/checkpoints/${checkpoint_id}.json"

 # Extract remaining tasks from phase file
 local remaining_tasks=$(sed -n "${current_task_index},\$p" "$phase_file" | grep '^\s*-\s*\[.\]')

 # Create checkpoint JSON
 cat > "$checkpoint_file" <<EOF
{
 "checkpoint_id": "$checkpoint_id",
 "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
 "plan_path": "$plan_path",
 "topic_path": "$topic_path",
 "phase_id": "$phase_id",
 "phase_file": "$phase_file",
 "progress": {
  "tasks_completed": $tasks_completed,
  "current_task": "$current_task",
  "tasks_remaining": $(echo "$remaining_tasks" | jq -R -s -c 'split("\n")[:-1]')
 },
 "context_usage": {
  "tokens_used": $CURRENT_TOKENS,
  "percentage": $((CURRENT_TOKENS * 100 / MAX_TOKENS))
 }
}
EOF

 echo "$checkpoint_file"
}

# Restore from checkpoint
restore_checkpoint() {
 local checkpoint_file="$1"

 # Read checkpoint
 local phase_id=$(jq -r '.phase_id' "$checkpoint_file")
 local tasks_completed=$(jq -r '.progress.tasks_completed' "$checkpoint_file")
 local remaining_tasks=$(jq -r '.progress.tasks_remaining[]' "$checkpoint_file")

 echo "Restoring from checkpoint: $checkpoint_file"
 echo "Phase: $phase_id"
 echo "Progress: $tasks_completed tasks completed"
 echo "Remaining: $(echo "$remaining_tasks" | wc -l) tasks"

 # Return checkpoint data for executor
 cat "$checkpoint_file"
}
```

#### 5.3: Update Plan Files with Checkpoint Markers

When checkpoint created:
1. Update phase file with progress marker
2. Update parent plans with checkpoint reference
3. Add resume instructions

**Example Phase File Update**:

```markdown
### Phase 2: Backend Implementation

**Status**: Paused (Checkpoint Created)
**Progress**: 6/15 tasks complete (40%)
**Checkpoint**: `.claude/data/checkpoints/027_auth_phase_2_20251021_153045.json`
**Resume Command**: `/resume-implement .claude/data/checkpoints/027_auth_phase_2_20251021_153045.json`

#### Completed Tasks
- [x] Create database schema
- [x] Implement user model
- [x] Add password hashing
- [x] Create authentication middleware
- [x] Implement login endpoint
- [x] Add registration endpoint

#### Remaining Tasks
- [ ] Add JWT token validation
- [ ] Implement token refresh logic
- [ ] Add session management
- [ ] ...
```

**Completion Checklist**:
- [ ] Context monitoring detects 70% usage threshold
- [ ] Checkpoint creation captures complete state
- [ ] Checkpoint files include all progress data
- [ ] Plan files updated with checkpoint markers
- [ ] Checkpoint restoration working (via /resume-implement)
- [ ] Checkpoint cleanup after successful resume
- [ ] Error handling for checkpoint corruption

---

## Stage 6: Replace /implement in orchestrate.md

**Objective**: Replace direct /implement invocation with implementer-coordinator subagent invocation using Task tool.

**Complexity**: Medium (6/10)
**Estimated Duration**: 1-2 hours

### Tasks

#### 6.1: Remove SlashCommand Invocation

**Current orchestrate.md (Phase 3 - Implementation)**:

```markdown
<!-- BEFORE (Anti-pattern) -->
Phase 3: Implementation
- Invoke: SlashCommand("/implement {plan_path}")
- Wait for completion
- Check test results
```

**Updated orchestrate.md (Phase 3 - Wave-Based Implementation)**:

```markdown
<!-- AFTER (Correct pattern) -->
Phase 3: Wave-Based Implementation

Invoke implementer-coordinator subagent:

Task {
 subagent_type: "general-purpose"
 description: "Orchestrate wave-based implementation with [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md)"
 prompt: |
  Read and follow the behavioral guidelines from:
  .claude/agents/implementer-coordinator.md

  You are coordinating wave-based implementation for this workflow.

  Input:
  - plan_path: {plan_path from Phase 2}
  - topic_path: {topic_path from Phase 0}
  - artifact_paths: {from Phase 0 location-specialist}

  Your tasks:
  1. Analyze plan dependencies using dependency-analyzer utility
  2. Identify execution waves (parallel opportunities)
  3. Execute phases wave-by-wave with implementation-executor subagents
  4. Monitor progress and report status
  5. Handle failures and create checkpoints as needed
  6. Return implementation report with metrics

  Expected output:
  - implementation_report with waves executed, time savings, git commits
  - If failures: Failed phase details for debugging
  - If checkpoints: Checkpoint paths for potential resume
}

Extract from response:
- implementation_status: "completed" | "partial" | "failed"
- waves_executed: N
- successful_phases: N
- failed_phases: N
- time_savings_percentage: "X%"
- git_commits: [list]
- checkpoints: [list if any]
- failed_phase_details: [list if failures]

Display to user:
```
✓ Implementation Phase Complete

Waves Executed: {N}
Total Phases: {M}
Successful: {S}
Failed: {F}
Time Savings: {X%} (vs sequential execution)
Git Commits: {count}

{If failures: Proceeding to Debugging Phase}
{If successful: Proceeding to Testing Phase}
```
```

#### 6.2: Add [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) of Artifact Paths

Ensure implementer-coordinator receives:
- `plan_path`: From Phase 2 (planning)
- `topic_path`: From Phase 0 (location-specialist)
- `artifact_paths`: For debug reports, outputs, checkpoints

**Example Injection**:

```yaml
prompt: |
 ...
 Input:
 - plan_path: /home/user/specs/027_auth/plans/027_auth_implementation.md
 - topic_path: /home/user/specs/027_auth
 - artifact_paths:
   debug: /home/user/specs/027_auth/debug/
   outputs: /home/user/specs/027_auth/outputs/
   checkpoints: /home/user/.claude/data/checkpoints/
 ...
```

#### 6.3: Update Conditional Logic for Testing Phase

After implementation completes:
- If `implementation_status == "completed"`: Proceed to Testing Phase (Phase 4)
- If `implementation_status == "partial"`: Proceed to Testing Phase but note incomplete implementation
- If `implementation_status == "failed"`: Skip Testing, go directly to Debugging (Phase 5)

**Completion Checklist**:
- [ ] SlashCommand("/implement") removed from orchestrate.md
- [ ] Task tool invocation added for implementer-coordinator
- [ ] Artifact path context injected correctly
- [ ] Implementation report extraction working
- [ ] Conditional logic updated for testing/debugging flow
- [ ] User-facing output displays wave metrics
- [ ] No regression in orchestrate workflow

---

## Stage 7: Implement Parallel Wave Execution

**Objective**: Finalize and test end-to-end parallel wave execution with performance validation.

**Complexity**: High (8/10)
**Estimated Duration**: 2-3 hours

### Tasks

#### 7.1: End-to-End Integration Testing

**Test Scenario 1: Sequential Plan (No Parallelism)**

```bash
# Create test plan with sequential dependencies
cat > test_sequential_plan.md <<'EOF'
# Test Plan: Sequential Implementation

## Metadata
- Dependencies: All phases sequential

### Phase 1: Setup
**Dependencies**: depends_on: []
Tasks: 5

### Phase 2: Backend
**Dependencies**: depends_on: [phase_1]
Tasks: 10

### Phase 3: Frontend
**Dependencies**: depends_on: [phase_2]
Tasks: 8

### Phase 4: Testing
**Dependencies**: depends_on: [phase_3]
Tasks: 6
EOF

# Execute via /orchestrate
/orchestrate "Test sequential implementation workflow"

# Verify:
# - Wave 1: [phase_1]
# - Wave 2: [phase_2]
# - Wave 3: [phase_3]
# - Wave 4: [phase_4]
# - Time savings: 0% (no parallelism)
# - All phases execute correctly
```

**Test Scenario 2: Parallel Plan (40-60% Savings)**

```bash
# Create test plan with parallel opportunities
cat > test_parallel_plan.md <<'EOF'
# Test Plan: Parallel Implementation

## Metadata
- Dependencies: Mixed (some parallel, some sequential)

### Phase 1: Setup
**Dependencies**: depends_on: []
Tasks: 5

### Phase 2: Backend Implementation
**Dependencies**: depends_on: [phase_1]
Tasks: 15

### Phase 3: Frontend Implementation
**Dependencies**: depends_on: [phase_1]
Tasks: 12

### Phase 4: Documentation
**Dependencies**: depends_on: [phase_1]
Tasks: 8

### Phase 5: Integration Testing
**Dependencies**: depends_on: [phase_2, phase_3, phase_4]
Tasks: 10
EOF

# Execute via /orchestrate
/orchestrate "Test parallel implementation workflow"

# Verify:
# - Wave 1: [phase_1]
# - Wave 2: [phase_2, phase_3, phase_4] (PARALLEL)
# - Wave 3: [phase_5]
# - Time savings: 40-50% (Wave 2 runs 3 phases concurrently)
# - All phases execute correctly
# - No race conditions or dependency violations
```

#### 7.2: Performance Benchmarking

**Metrics to Measure**:

1. **Sequential Baseline**:
  - Total time if all phases run one-by-one
  - Calculate: sum of individual phase durations

2. **[[Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md)](../../../docs/concepts/patterns/parallel-execution.md)**:
  - Actual elapsed time with wave-based execution
  - Calculate: sum of wave durations (max phase time per wave)

3. **Time Savings**:
  - Formula: `(sequential_time - parallel_time) / sequential_time * 100`
  - Target: 40-60% for plans with 2-4 parallel phases

4. **Context Usage**:
  - Measure coordinator context overhead
  - Target: <20% for coordination, <30% total including executors

**Benchmark Script**:

```bash
#!/usr/bin/env bash
# .claude/tests/benchmark_wave_execution.sh

# Run benchmark on test plan
benchmark_wave_execution() {
 local plan_path="$1"

 echo "Benchmarking wave-based execution: $plan_path"

 # Analyze dependencies
 local analysis=$(bash .claude/lib/dependency-analyzer.sh "$plan_path")
 local sequential_time=$(echo "$analysis" | jq -r '.metrics.sequential_estimated_time')
 local parallel_time=$(echo "$analysis" | jq -r '.metrics.parallel_estimated_time')
 local time_savings=$(echo "$analysis" | jq -r '.metrics.time_savings_percentage')

 echo "Sequential Estimated: $sequential_time"
 echo "Parallel Estimated: $parallel_time"
 echo "Time Savings: $time_savings"

 # Execute implementation
 local start_time=$(date +%s)
 # ... invoke implementer-coordinator ...
 local end_time=$(date +%s)
 local actual_time=$((end_time - start_time))

 echo "Actual Elapsed: ${actual_time}s"

 # Calculate actual savings
 local sequential_seconds=$((sequential_time * 3600))
 local actual_savings=$(( (sequential_seconds - actual_time) * 100 / sequential_seconds ))

 echo "Actual Time Savings: ${actual_savings}%"

 # Validate
 if [[ $actual_savings -ge 40 && $actual_savings -le 60 ]]; then
  echo "✓ PASS: Time savings within target range (40-60%)"
 else
  echo "✗ FAIL: Time savings outside target range (actual: ${actual_savings}%)"
 fi
}

# Run benchmarks
benchmark_wave_execution "test_parallel_plan.md"
benchmark_wave_execution "test_sequential_plan.md"
benchmark_wave_execution "specs/027_auth/plans/027_auth_implementation.md"
```

#### 7.3: Failure Recovery Testing

**Test Scenario: Phase Failure in Wave**

```markdown
Test Case: Executor Failure Handling

Setup:
- Plan with 3 phases in Wave 2 (all parallel)
- Phase 2 will fail (intentional error)
- Phase 3 and Phase 4 are independent

Expected Behavior:
1. Wave 2 starts with 3 parallel executors
2. Phase 2 executor reports failure
3. Coordinator marks Phase 2 as failed
4. Phases 3 and 4 continue to completion
5. Wave 2 completes with 2/3 success
6. If Phase 5 depends on Phase 2: Halt
7. If Phase 5 independent: Continue to Wave 3

Verification:
- ✓ Failed phase logged
- ✓ Independent phases complete
- ✓ Dependent phases blocked
- ✓ Coordinator reports partial completion
- ✓ User sees clear failure details
```

**Test Scenario: Checkpoint Creation**

```markdown
Test Case: Context Window Pressure

Setup:
- Plan with very large phase (50+ tasks)
- Simulate context at 70% during execution

Expected Behavior:
1. Executor detects context threshold
2. Creates checkpoint mid-phase
3. Updates plan hierarchy with checkpoint marker
4. Returns checkpoint report to coordinator
5. Coordinator logs checkpoint path

Verification:
- ✓ Checkpoint file created
- ✓ Checkpoint contains correct progress
- ✓ Plan files updated with marker
- ✓ /resume-implement WILL restore from checkpoint
```

**Completion Checklist**:
- [ ] Sequential plan execution working (no parallelism)
- [ ] Parallel plan execution working (2-4 concurrent phases)
- [ ] Time savings 40-60% for parallel plans
- [ ] Context usage <30% throughout execution
- [ ] Failure handling preserves independent work
- [ ] Checkpoint creation working under context pressure
- [ ] Checkpoint restoration working (/resume-implement)
- [ ] All tests passing (unit + integration + benchmarks)
- [ ] Performance metrics meet targets

---

## Phase Completion Checklist

After all stages complete:

### Functional Requirements
- [ ] dependency-analyzer utility working (graph + waves)
- [ ] implementer-coordinator agent working (orchestration)
- [ ] implementation-executor agent working (phase execution)
- [ ] Progress tracking displays real-time updates
- [ ] Checkpoint management prevents context overflow
- [ ] orchestrate.md updated (no SlashCommand invocation)
- [ ] Parallel wave execution working (40-60% savings)

### Integration Requirements
- [ ] Wave execution integrates with /orchestrate workflow
- [ ] Artifact path injection working (coordinator → executors)
- [ ] Plan hierarchy updates working (L2 → L1 → L0)
- [ ] Git commits created per phase completion
- [ ] Test execution after each phase
- [ ] Failure handling invokes debugging when needed

### Testing Requirements
- [ ] Unit tests for dependency-analyzer (5+ test cases)
- [ ] Unit tests for checkpoint management (3+ scenarios)
- [ ] Integration test: Sequential plan (no parallelism)
- [ ] Integration test: Parallel plan (2-4 concurrent phases)
- [ ] Performance benchmark: 40-60% time savings validated
- [ ] Failure recovery test: Phase failure handling
- [ ] Context pressure test: Checkpoint creation

### Documentation Requirements
- [ ] dependency-analyzer.sh documented with usage examples
- [ ] implementer-coordinator.md has complete behavioral spec
- [ ] implementation-executor.md has complete behavioral spec
- [ ] Progress tracking documented (visualization format)
- [ ] Checkpoint format documented (JSON schema)
- [ ] orchestrate.md updated with wave execution phase

### Performance Requirements
- [ ] Time savings: 40-60% for parallel workflows (measured)
- [ ] Context usage: <20% for coordinator overhead
- [ ] Context usage: <30% total including executors
- [ ] Dependency analysis: <1s for 20-phase plan
- [ ] Progress updates: <10s latency

### Success Metrics
- [ ] **[[Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md)](../../../docs/concepts/patterns/parallel-execution.md)**: Multiple phases run concurrently (verified via logs)
- [ ] **Time Savings**: Measured improvement in parallel workflows (40-60%)
- [ ] **Correctness**: Dependencies respected (no premature execution)
- [ ] **Resilience**: Failures don't block independent work
- [ ] **Context Efficiency**: <30% usage maintained
- [ ] **User Experience**: Real-time progress visible and accurate

## Update Parent Plan

After phase completion:

1. **Mark Phase 5 complete** in main plan (080_orchestrate_enhancement.md)
2. **Update summary** with wave execution results
3. **Add cross-reference** to this expanded phase file
4. **Create git commit**:
  ```bash
  git add .claude/specs/plans/080_orchestrate_enhancement.md
  git add .claude/specs/plans/080_orchestrate_enhancement/phase_5_wave_based_implementation.md
  git add .claude/lib/dependency-analyzer.sh
  git add .claude/agents/implementer-coordinator.md
  git add .claude/agents/implementation-executor.md
  git add .claude/lib/progress-tracker.sh
  git add .claude/lib/checkpoint-manager.sh
  git add .claude/commands/orchestrate.md
  git commit -m "feat(080): complete Phase 5 - Wave-Based Implementation (Plan 080)"
  ```

## Notes

### Architectural Significance

This phase represents the **core innovation** of the /orchestrate enhancement:
- **Before**: Sequential execution (12 hours for 4 phases)
- **After**: Wave-based [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md) (7 hours for same 4 phases, 42% savings)

### Performance Considerations

**Context Optimization**:
- Coordinator receives: Dependency graph (not full plans) = 90% reduction
- Executors return: Progress summaries (not full output) = 95% reduction
- Target: <30% context usage maintained despite parallelism

**Synchronization Overhead**:
- Wave synchronization adds ~5-10% overhead
- Progress polling every 5-10 seconds
- Acceptable trade-off for 40-60% time savings

### Future Enhancements

Potential improvements for future phases:
1. **Adaptive Wave Sizing**: Adjust parallelism based on system resources
2. **Predictive Checkpointing**: Create checkpoints before context issues
3. **Cross-Workflow Wave Reuse**: Learn optimal wave structures from past workflows
4. **Dynamic Dependency Updates**: Allow phases to add dependencies during execution

### Risk Mitigation

**Highest Risks**:
1. **Race Conditions**: Multiple executors updating plan files → Use file locking
2. **Dependency Violations**: Phases starting before dependencies complete → Strict synchronization
3. **Context Explosion**: Too many parallel executors → Limit wave size to 4 phases max

**Mitigations Implemented**:
- Dependency analysis validation (cycle detection)
- Wave synchronization (wait for all executors)
- Context monitoring (checkpoint before overflow)
- Failure isolation (don't block independent work)
