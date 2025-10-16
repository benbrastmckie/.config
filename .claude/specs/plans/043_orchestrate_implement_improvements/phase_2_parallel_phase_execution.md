# Phase 2: Parallel Phase Execution - Detailed Specification

## Metadata
- **Parent Plan**: /home/benjamin/.config/.claude/specs/plans/043_orchestrate_implement_improvements.md
- **Phase Number**: 2
- **Complexity**: 7/10 (Medium-High)
- **Duration**: 2-3 sessions
- **Objective**: Enable 40-60% performance improvement via wave-based parallel execution
- **Date Created**: 2025-10-12

## Overview

This phase transforms /implement from sequential execution to wave-based parallel execution, achieving 40-60% performance gains by executing independent phases concurrently. The implementation leverages the existing, battle-tested `parse-phase-dependencies.sh` utility for wave generation and adds inline parallel agent invocation logic to /implement.

### Key Strategy
- **Reuse wave generation**: parse-phase-dependencies.sh already implements Kahn's algorithm
- **Inline aggregation**: Simple result collection doesn't justify separate utility
- **Max 3 concurrent phases**: Prevents resource exhaustion
- **Fail-fast behavior**: Stop wave on first failure, preserve partial progress

### Expected Performance Gains

**Sequential Execution (Current)**:
```
Phase 1: 3 minutes
Phase 2: 3 minutes (depends on Phase 1)
Phase 3: 3 minutes (depends on Phase 1)
Phase 4: 3 minutes (depends on Phases 2 and 3)
Total: 12 minutes
```

**Parallel Execution (After Phase 2)**:
```
Wave 1: Phase 1 (3 minutes)
Wave 2: Phases 2 and 3 in parallel (3 minutes)
Wave 3: Phase 4 (3 minutes)
Total: 9 minutes (25% reduction)
```

---

## 1. Architecture Section (~80-100 lines)

### 1.1 Wave-Based Execution Model

The parallel execution model organizes phases into "waves" where each wave contains phases that can execute concurrently. Waves execute sequentially, with all phases in a wave completing before the next wave begins.

**Wave Generation Algorithm (parse-phase-dependencies.sh)**:
```bash
# Kahn's topological sort algorithm
# Input: Phase dependencies from plan file
# Output: WAVE_1:1 WAVE_2:2 3 WAVE_3:4

# Example plan with dependencies:
### Phase 1: Setup
dependencies: []

### Phase 2: Feature A
dependencies: [1]

### Phase 3: Feature B
dependencies: [1]

### Phase 4: Integration
dependencies: [2, 3]

# Wave generation output:
WAVE_1:1        # No dependencies, can run first
WAVE_2:2 3      # Both depend only on Phase 1, run in parallel
WAVE_3:4        # Depends on Phases 2 and 3, run after Wave 2
```

**Wave Execution Rules**:
1. **Sequential waves**: Wave N+1 starts only after Wave N completes
2. **Parallel phases**: All phases in a wave start simultaneously
3. **Fail-fast**: Any phase failure stops the entire wave
4. **Max concurrency**: Split waves with >3 phases into sub-waves

### 1.2 State Machine for Wave Progression

The wave execution state machine tracks progress through waves and handles transitions.

```
┌──────────────────────┐
│   WAVE_INIT          │  Parse dependencies, generate waves
│                      │  Load checkpoint (if resuming)
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│   WAVE_START         │  Select next wave, log wave info
│                      │  Check phase count (<= 3)
└──────────┬───────────┘
           │
           ↓
    ┌──────────────────┐
    │  Single Phase?   │
    └──────┬──────┬────┘
           │Yes   │No
           ↓      ↓
    ┌──────────┐ ┌──────────────────┐
    │SEQUENTIAL│ │  PARALLEL_EXEC   │  Invoke multiple agents
    │   EXEC   │ │                  │  Wait for completion
    └─────┬────┘ └──────────┬───────┘
          │                 │
          ↓                 ↓
    ┌──────────────────────┐
    │   WAVE_AGGREGATE     │  Collect results, check failures
    │                      │  Aggregate test outputs
    └──────────┬───────────┘
               │
        ┌──────┴──────┐
        │  Failures?  │
        └──┬───────┬──┘
          No      Yes
           │       │
           ↓       ↓
    ┌──────────┐ ┌──────────────────┐
    │WAVE_TEST │ │  WAVE_FAILURE    │  Save checkpoint
    │          │ │                  │  Report partial progress
    └────┬─────┘ └──────────────────┘
         │              │
         ↓              │
    ┌──────────┐        │
    │Failures? │        │
    └──┬───┬───┘        │
      No  Yes           │
       │   └────────────┘
       ↓
    ┌──────────────────┐
    │  WAVE_COMMIT     │  Git commit all changes
    │                  │  Update plan markers
    └──────────┬───────┘
               │
        ┌──────┴──────┐
        │ More Waves? │
        └──┬───────┬──┘
          Yes     No
           │       │
           │       ↓
           │  ┌──────────────────┐
           │  │  COMPLETE        │  Final summary
           │  └──────────────────┘
           │
           └──────┐
                  │
                  ↓ (loop to WAVE_START)
```

### 1.3 Checkpoint Schema Extensions for Wave Tracking

The checkpoint schema extends to track wave-level state for proper resumption.

**Checkpoint Structure**:
```json
{
  "schema_version": "1.1",
  "checkpoint_id": "implement_plan_043_20251012_143022",
  "workflow_type": "implement",
  "project_name": "plan_043",
  "created_at": "2025-10-12T14:30:22Z",
  "updated_at": "2025-10-12T14:35:18Z",
  "status": "in_progress",
  "workflow_state": {
    "plan_path": "/home/benjamin/.config/.claude/specs/plans/043_plan.md",
    "total_phases": 5,
    "completed_phases": [1, 2, 3],
    "current_wave": 3,
    "total_waves": 4,
    "wave_structure": {
      "1": [1],
      "2": [2, 3],
      "3": [4],
      "4": [5]
    },
    "parallel_execution_enabled": true,
    "max_wave_parallelism": 3,
    "wave_results": {
      "1": {
        "phases": [1],
        "status": "completed",
        "duration_ms": 185000
      },
      "2": {
        "phases": [2, 3],
        "status": "completed",
        "duration_ms": 192000,
        "parallel": true,
        "phase_results": {
          "2": {"status": "success", "duration_ms": 187000},
          "3": {"status": "success", "duration_ms": 192000}
        }
      },
      "3": {
        "phases": [4],
        "status": "in_progress",
        "start_time": "2025-10-12T14:35:18Z"
      }
    }
  }
}
```

**New Fields**:
- `current_wave`: Current wave being executed (1-indexed)
- `total_waves`: Total number of waves in plan
- `wave_structure`: Map of wave number to phase numbers
- `parallel_execution_enabled`: Flag for --sequential override
- `max_wave_parallelism`: Max concurrent phases per wave
- `wave_results`: Detailed results for each completed/in-progress wave

### 1.4 Agent Coordination Pattern

Multiple agents are invoked simultaneously using **multiple Task tool calls in a single message**.

**Parallel Invocation Pattern**:
```bash
# DON'T: Sequential invocations (current implementation)
invoke_agent "code-writer" "Implement Phase 2"
wait_for_completion
invoke_agent "code-writer" "Implement Phase 3"
wait_for_completion

# DO: Parallel invocations in single message
# Claude Code will make multiple Task tool calls in one response
cat << 'EOF' > /tmp/wave_execution_prompt.txt
I need to execute Wave 2 with phases 2 and 3 in parallel:

Phase 2: Implement Feature A
- Create feature_a.lua module
- Add tests for feature_a
- No dependencies beyond Phase 1 (completed)

Phase 3: Implement Feature B
- Create feature_b.lua module
- Add tests for feature_b
- No dependencies beyond Phase 1 (completed)

Please invoke two code-writer agents in parallel using multiple Task tool calls:
1. Agent for Phase 2 with behavioral injection for complexity 6
2. Agent for Phase 3 with behavioral injection for complexity 6

Wait for both to complete before reporting results.
EOF
```

**Agent Behavioral Injection**:
```bash
# Construct agent instructions based on complexity
PHASE_2_COMPLEXITY=$(calculate_phase_complexity "Implement Feature A" "$PHASE_2_CONTENT")
PHASE_3_COMPLEXITY=$(calculate_phase_complexity "Implement Feature B" "$PHASE_3_CONTENT")

# Select thinking modes based on complexity
PHASE_2_THINKING=$(get_thinking_mode "$PHASE_2_COMPLEXITY")  # e.g., "think"
PHASE_3_THINKING=$(get_thinking_mode "$PHASE_3_COMPLEXITY")  # e.g., "think"

# Include in parallel invocation prompt
echo "Agent 1: Use '$PHASE_2_THINKING' mode for Phase 2 (complexity $PHASE_2_COMPLEXITY)"
echo "Agent 2: Use '$PHASE_3_THINKING' mode for Phase 3 (complexity $PHASE_3_COMPLEXITY)"
```

### 1.5 Result Aggregation Architecture

Results from parallel agents are aggregated into a unified structure for testing and commits.

**Aggregation Data Structure**:
```bash
# Result aggregation (simple bash associative arrays)
declare -A WAVE_RESULTS
declare -A PHASE_STATUS
declare -A PHASE_FILES_CHANGED
declare -A PHASE_TEST_OUTPUT

# Collect from each agent in wave
for phase_num in "${WAVE_PHASES[@]}"; do
  # Parse agent output (PROGRESS markers, file changes, test results)
  PHASE_STATUS[$phase_num]=$(parse_agent_status "$AGENT_OUTPUT_$phase_num")
  PHASE_FILES_CHANGED[$phase_num]=$(parse_files_changed "$AGENT_OUTPUT_$phase_num")
  PHASE_TEST_OUTPUT[$phase_num]=$(parse_test_output "$AGENT_OUTPUT_$phase_num")
done

# Aggregate into wave result
WAVE_STATUS="success"
for phase_num in "${WAVE_PHASES[@]}"; do
  if [[ "${PHASE_STATUS[$phase_num]}" != "success" ]]; then
    WAVE_STATUS="failure"
    FAILED_PHASE=$phase_num
    break
  fi
done

# Aggregate file changes (for git commit)
ALL_FILES_CHANGED=""
for phase_num in "${WAVE_PHASES[@]}"; do
  ALL_FILES_CHANGED+="${PHASE_FILES_CHANGED[$phase_num]}"$'\n'
done

# Aggregate test outputs (for display and error analysis)
COMBINED_TEST_OUTPUT=""
for phase_num in "${WAVE_PHASES[@]}"; do
  COMBINED_TEST_OUTPUT+="=== Phase $phase_num Test Results ==="$'\n'
  COMBINED_TEST_OUTPUT+="${PHASE_TEST_OUTPUT[$phase_num]}"$'\n\n'
done
```

---

## 2. Concrete Implementation Steps (~150-200 lines)

### Task 1: Integrate parse-phase-dependencies.sh into /implement command

**Step 1.1: Add dependency parsing before execution**

Location: `/home/benjamin/.config/.claude/commands/implement.md`

Insert after "Let me first locate the implementation plan" section (around line 122):

```bash
### Dependency Analysis and Wave Generation

# Parse plan dependencies using existing utility
WAVES_OUTPUT=$(.claude/lib/parse-phase-dependencies.sh "$PLAN_PATH")

if [[ $? -ne 0 ]]; then
  echo "ERROR: Dependency parsing failed. Check for circular dependencies."
  echo "$WAVES_OUTPUT"
  exit 1
fi

# Parse wave structure into array
declare -a WAVE_STRUCTURE
while IFS= read -r wave_line; do
  WAVE_STRUCTURE+=("$wave_line")
done <<< "$WAVES_OUTPUT"

# Example output: WAVE_STRUCTURE=("WAVE_1:1" "WAVE_2:2 3" "WAVE_3:4")
TOTAL_WAVES=${#WAVE_STRUCTURE[@]}

echo "Execution plan generated: $TOTAL_WAVES waves from dependency analysis"
for wave_line in "${WAVE_STRUCTURE[@]}"; do
  echo "  $wave_line"
done
```

**Step 1.2: Detect circular dependencies early**

The `parse-phase-dependencies.sh` script already handles this, but add user-friendly error handling:

```bash
# Error handling for dependency issues
if echo "$WAVES_OUTPUT" | grep -q "ERROR: Circular dependency"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Circular Dependency Detected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "The plan contains circular dependencies that prevent execution."
  echo "$WAVES_OUTPUT"
  echo ""
  echo "Fix the plan by:"
  echo "  1. Reviewing phase dependencies"
  echo "  2. Removing circular references"
  echo "  3. Ensuring dependency graph is acyclic"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi
```

**Step 1.3: Store wave structure in checkpoint state**

Update checkpoint save calls to include wave structure:

```bash
# Build checkpoint state with wave information
CHECKPOINT_STATE=$(jq -n \
  --arg plan_path "$PLAN_PATH" \
  --argjson total_phases "$TOTAL_PHASES" \
  --argjson completed_phases "$(printf '%s\n' "${COMPLETED_PHASES[@]}" | jq -R . | jq -s 'map(tonumber)')" \
  --argjson current_wave "$CURRENT_WAVE" \
  --argjson total_waves "$TOTAL_WAVES" \
  --argjson parallel_enabled "$PARALLEL_EXECUTION_ENABLED" \
  '{
    plan_path: $plan_path,
    total_phases: $total_phases,
    completed_phases: $completed_phases,
    current_wave: $current_wave,
    total_waves: $total_waves,
    wave_structure: {},
    parallel_execution_enabled: $parallel_enabled,
    max_wave_parallelism: 3
  }')

# Add wave structure mapping (wave number -> phase array)
for wave_idx in "${!WAVE_STRUCTURE[@]}"; do
  WAVE_NUM=$((wave_idx + 1))
  WAVE_PHASES=$(echo "${WAVE_STRUCTURE[$wave_idx]}" | cut -d':' -f2)
  CHECKPOINT_STATE=$(echo "$CHECKPOINT_STATE" | jq \
    --arg wave "$WAVE_NUM" \
    --arg phases "$WAVE_PHASES" \
    '.wave_structure[$wave] = ($phases | split(" ") | map(tonumber))')
done

# Save checkpoint with wave tracking
save_checkpoint "implement" "$PLAN_NAME" "$CHECKPOINT_STATE"
```

### Task 2: Add parallel agent invocation to /implement

**Step 2.1: Implement wave iteration logic**

Replace current sequential phase iteration with wave-based iteration:

```bash
# Wave-based execution loop (replaces sequential phase loop)
CURRENT_WAVE=1
for wave_line in "${WAVE_STRUCTURE[@]}"; do
  # Parse wave: "WAVE_2:2 3" -> wave_num=2, phases=[2, 3]
  WAVE_NUM=$(echo "$wave_line" | cut -d':' -f1 | sed 's/WAVE_//')
  WAVE_PHASES_STR=$(echo "$wave_line" | cut -d':' -f2)
  IFS=' ' read -ra WAVE_PHASES <<< "$WAVE_PHASES_STR"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Wave $WAVE_NUM: ${#WAVE_PHASES[@]} phase(s) - [${WAVE_PHASES[*]}]"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check if wave should run in parallel
  if [[ ${#WAVE_PHASES[@]} -eq 1 ]]; then
    # Single phase - sequential execution
    execute_phase_sequential "${WAVE_PHASES[0]}"
  else
    # Multiple phases - parallel execution
    execute_wave_parallel "${WAVE_PHASES[@]}"
  fi

  # Test wave results
  test_wave_results "$WAVE_NUM" "${WAVE_PHASES[@]}"

  # Commit wave changes
  commit_wave_changes "$WAVE_NUM" "${WAVE_PHASES[@]}"

  CURRENT_WAVE=$((CURRENT_WAVE + 1))
done
```

**Step 2.2: Implement parallel agent invocation**

Create function for parallel execution:

```bash
execute_wave_parallel() {
  local wave_phases=("$@")
  local phase_count=${#wave_phases[@]}

  echo "Executing $phase_count phases in parallel..."

  # Build parallel invocation prompt
  cat > /tmp/parallel_wave_prompt.txt << EOF
I need to execute phases ${wave_phases[*]} in parallel for this implementation plan.

Plan: $PLAN_PATH

Phases to execute concurrently:
EOF

  # Add each phase with complexity-based behavioral injection
  for phase_num in "${wave_phases[@]}"; do
    # Extract phase details
    PHASE_CONTENT=$(extract_phase_content "$PLAN_PATH" "$phase_num")
    PHASE_NAME=$(extract_phase_name "$PLAN_PATH" "$phase_num")
    PHASE_COMPLEXITY=$(calculate_phase_complexity "$PHASE_NAME" "$PHASE_CONTENT")
    THINKING_MODE=$(get_thinking_mode "$PHASE_COMPLEXITY")

    cat >> /tmp/parallel_wave_prompt.txt << EOF

Phase $phase_num: $PHASE_NAME
Complexity: $PHASE_COMPLEXITY/10
Thinking Mode: $THINKING_MODE
Tasks:
$PHASE_CONTENT

EOF
  done

  cat >> /tmp/parallel_wave_prompt.txt << EOF

Execute all phases using multiple Task tool invocations in a single message.
For each phase:
1. Invoke code-writer agent with appropriate thinking mode
2. Include PROGRESS: markers in agent instructions
3. Capture file changes and test outputs

Wait for all phases to complete and report:
- Success/failure status for each phase
- Files changed per phase
- Test results per phase
EOF

  # Invoke parallel execution via Task tool
  # Note: This happens through Claude Code's message processing
  # The command implementation sends the prompt and Claude Code responds
  # with multiple Task invocations

  echo "Invoking parallel agents for wave execution..."
  # Implementation note: This is where the /implement command would send
  # the prompt to Claude Code, which then invokes multiple Task tools
}
```

**Step 2.3: Wait for wave completion and collect results**

```bash
aggregate_wave_results() {
  local wave_num=$1
  shift
  local wave_phases=("$@")

  # Initialize result structures
  declare -A PHASE_STATUS
  declare -A PHASE_FILES
  declare -A PHASE_TEST_OUTPUT

  # Parse results from agent outputs
  # (In practice, this data comes from Task tool responses)
  for phase_num in "${wave_phases[@]}"; do
    # Check agent output file (created by Task tool)
    AGENT_OUTPUT_FILE="/tmp/phase_${phase_num}_output.txt"

    if [[ -f "$AGENT_OUTPUT_FILE" ]]; then
      # Parse PROGRESS markers for status
      if grep -q "PROGRESS: Phase $phase_num complete" "$AGENT_OUTPUT_FILE"; then
        PHASE_STATUS[$phase_num]="success"
      else
        PHASE_STATUS[$phase_num]="failure"
      fi

      # Extract files changed
      PHASE_FILES[$phase_num]=$(grep "^CHANGED:" "$AGENT_OUTPUT_FILE" | cut -d':' -f2-)

      # Extract test output
      PHASE_TEST_OUTPUT[$phase_num]=$(sed -n '/^TEST_OUTPUT_START/,/^TEST_OUTPUT_END/p' "$AGENT_OUTPUT_FILE")
    else
      PHASE_STATUS[$phase_num]="failure"
      echo "WARNING: No output file for Phase $phase_num"
    fi
  done

  # Check for failures (fail-fast)
  WAVE_STATUS="success"
  FAILED_PHASES=()
  for phase_num in "${wave_phases[@]}"; do
    if [[ "${PHASE_STATUS[$phase_num]}" != "success" ]]; then
      WAVE_STATUS="failure"
      FAILED_PHASES+=("$phase_num")
    fi
  done

  # Return aggregated results via global variables
  export WAVE_STATUS
  export PHASE_STATUS
  export PHASE_FILES
  export PHASE_TEST_OUTPUT
  export FAILED_PHASES
}
```

**Step 2.4: Handle fail-fast behavior**

```bash
# After aggregating results, check for failures
if [[ "$WAVE_STATUS" == "failure" ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Wave $WAVE_NUM Failed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Failed phases: ${FAILED_PHASES[*]}"
  echo ""

  # Display failed phase outputs
  for failed_phase in "${FAILED_PHASES[@]}"; do
    echo "Phase $failed_phase output:"
    echo "${PHASE_TEST_OUTPUT[$failed_phase]}"
    echo ""
  done

  # Save checkpoint with partial progress
  CHECKPOINT_STATE=$(build_checkpoint_state)
  CHECKPOINT_STATE=$(echo "$CHECKPOINT_STATE" | jq \
    --argjson wave "$WAVE_NUM" \
    --argjson failed "$(printf '%s\n' "${FAILED_PHASES[@]}" | jq -R . | jq -s 'map(tonumber)')" \
    '.wave_results["'"$WAVE_NUM"'"] = {
      status: "failed",
      failed_phases: $failed,
      partial_success: true
    }')
  save_checkpoint "implement" "$PLAN_NAME" "$CHECKPOINT_STATE"

  echo "Checkpoint saved. Resume with:"
  echo "  /implement $PLAN_PATH $WAVE_NUM"
  echo ""

  # Use error-utils.sh for recovery suggestions
  source .claude/lib/error-utils.sh
  ERROR_TYPE=$(classify_error "${PHASE_TEST_OUTPUT[$failed_phase]}")
  echo "$(suggest_recovery "$ERROR_TYPE" "${PHASE_TEST_OUTPUT[$failed_phase]}")"

  exit 1
fi
```

### Task 3: Update /implement command for wave-based execution

**Step 3.1: Add --sequential flag**

Add flag parsing at command start:

```bash
# Parse command flags
PARALLEL_EXECUTION_ENABLED=true
for arg in "$@"; do
  case "$arg" in
    --sequential)
      PARALLEL_EXECUTION_ENABLED=false
      echo "Parallel execution disabled via --sequential flag"
      shift
      ;;
  esac
done

# If --sequential, skip wave generation and use traditional loop
if [[ "$PARALLEL_EXECUTION_ENABLED" == "false" ]]; then
  echo "Using sequential execution (no wave analysis)"
  # Fall back to traditional phase-by-phase loop
  for phase_num in $(seq 1 $TOTAL_PHASES); do
    execute_phase_sequential "$phase_num"
  done
else
  # Use wave-based execution (default)
  # ... (wave generation and execution logic)
fi
```

**Step 3.2: Update checkpoint save/restore for wave state**

Ensure checkpoints include wave tracking:

```bash
# When saving checkpoints during wave execution
save_wave_checkpoint() {
  local wave_num=$1
  local wave_status=$2
  local wave_phases=("${@:3}")

  # Update checkpoint with wave results
  CHECKPOINT_FILE=$(restore_checkpoint "implement" "$PLAN_NAME" | jq -r '.checkpoint_id')
  CHECKPOINT_PATH="${CHECKPOINTS_DIR}/${CHECKPOINT_FILE}.json"

  # Add wave result
  local wave_result=$(jq -n \
    --argjson phases "$(printf '%s\n' "${wave_phases[@]}" | jq -R . | jq -s 'map(tonumber)')" \
    --arg status "$wave_status" \
    --arg duration "$WAVE_DURATION_MS" \
    '{
      phases: $phases,
      status: $status,
      duration_ms: ($duration | tonumber),
      completed_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    }')

  # Update checkpoint file
  checkpoint_set_field "$CHECKPOINT_PATH" ".workflow_state.wave_results[\"$wave_num\"]" "$wave_result"
  checkpoint_set_field "$CHECKPOINT_PATH" ".workflow_state.current_wave" "$((wave_num + 1))"
}
```

**Step 3.3: Add parallel execution logging**

```bash
# Source adaptive planning logger
source .claude/lib/adaptive-planning-logger.sh

# Log wave execution start
log_wave_execution() {
  local wave_num=$1
  local phase_count=$2
  local is_parallel=$3

  local log_entry=$(jq -n \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson wave "$wave_num" \
    --argjson phases "$phase_count" \
    --arg parallel "$is_parallel" \
    '{
      timestamp: $timestamp,
      event: "wave_execution",
      wave_number: $wave,
      phase_count: $phases,
      execution_mode: (if $parallel == "true" then "parallel" else "sequential" end)
    }')

  echo "$log_entry" >> .claude/logs/adaptive-planning.log
}

# Log after each wave
log_wave_execution "$WAVE_NUM" "${#WAVE_PHASES[@]}" "$([ ${#WAVE_PHASES[@]} -gt 1 ] && echo true || echo false)"
```

### Task 4: Create comprehensive tests for parallel execution

**Test File 1**: `/home/benjamin/.config/.claude/tests/test_parallel_waves.sh`

```bash
#!/usr/bin/env bash
# Test wave generation and execution logic

set -euo pipefail

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test 1: Simple dependency chain
test_simple_chain() {
  cat > "$TEST_DIR/simple_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: []

### Phase 2: Build
dependencies: [1]

### Phase 3: Test
dependencies: [2]
EOF

  WAVES=$(.claude/lib/parse-phase-dependencies.sh "$TEST_DIR/simple_plan.md")

  [[ "$WAVES" == "WAVE_1:1"$'\n'"WAVE_2:2"$'\n'"WAVE_3:3" ]] || {
    echo "FAIL: Simple chain produced unexpected waves"
    echo "Got: $WAVES"
    return 1
  }

  echo "PASS: Simple chain"
}

# Test 2: Parallel phases
test_parallel_phases() {
  cat > "$TEST_DIR/parallel_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: []

### Phase 2: Feature A
dependencies: [1]

### Phase 3: Feature B
dependencies: [1]

### Phase 4: Integration
dependencies: [2, 3]
EOF

  WAVES=$(.claude/lib/parse-phase-dependencies.sh "$TEST_DIR/parallel_plan.md")

  # Wave 2 should contain phases 2 and 3
  echo "$WAVES" | grep -q "WAVE_2:2 3" || {
    echo "FAIL: Parallel phases not detected"
    echo "Got: $WAVES"
    return 1
  }

  echo "PASS: Parallel phases"
}

# Test 3: Circular dependency detection
test_circular_dependency() {
  cat > "$TEST_DIR/circular_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: [2]

### Phase 2: Build
dependencies: [1]
EOF

  WAVES=$(.claude/lib/parse-phase-dependencies.sh "$TEST_DIR/circular_plan.md" 2>&1 || true)

  echo "$WAVES" | grep -q "ERROR: Circular dependency" || {
    echo "FAIL: Circular dependency not detected"
    return 1
  }

  echo "PASS: Circular dependency detection"
}

# Run tests
echo "Testing wave generation..."
test_simple_chain
test_parallel_phases
test_circular_dependency
echo "All wave generation tests passed"
```

**Test File 2**: `/home/benjamin/.config/.claude/tests/test_parallel_agents.sh`

```bash
#!/usr/bin/env bash
# Test parallel agent invocation patterns

set -euo pipefail

# Test parallel invocation result aggregation
test_result_aggregation() {
  # Simulate agent outputs
  mkdir -p /tmp/test_wave

  cat > /tmp/test_wave/phase_2_output.txt << 'EOF'
PROGRESS: Phase 2 starting
PROGRESS: Phase 2 complete
CHANGED: feature_a.lua
CHANGED: tests/feature_a_spec.lua
TEST_OUTPUT_START
All tests passed (3/3)
TEST_OUTPUT_END
EOF

  cat > /tmp/test_wave/phase_3_output.txt << 'EOF'
PROGRESS: Phase 3 starting
PROGRESS: Phase 3 complete
CHANGED: feature_b.lua
CHANGED: tests/feature_b_spec.lua
TEST_OUTPUT_START
All tests passed (2/2)
TEST_OUTPUT_END
EOF

  # Simulate aggregation
  declare -A PHASE_STATUS
  declare -A PHASE_FILES

  for phase_num in 2 3; do
    OUTPUT_FILE="/tmp/test_wave/phase_${phase_num}_output.txt"

    if grep -q "PROGRESS: Phase $phase_num complete" "$OUTPUT_FILE"; then
      PHASE_STATUS[$phase_num]="success"
    fi

    PHASE_FILES[$phase_num]=$(grep "^CHANGED:" "$OUTPUT_FILE" | cut -d':' -f2-)
  done

  # Verify aggregation
  [[ "${PHASE_STATUS[2]}" == "success" ]] || return 1
  [[ "${PHASE_STATUS[3]}" == "success" ]] || return 1
  [[ "${PHASE_FILES[2]}" =~ "feature_a.lua" ]] || return 1
  [[ "${PHASE_FILES[3]}" =~ "feature_b.lua" ]] || return 1

  echo "PASS: Result aggregation"
}

# Test failure handling
test_failure_handling() {
  mkdir -p /tmp/test_wave_fail

  cat > /tmp/test_wave_fail/phase_2_output.txt << 'EOF'
PROGRESS: Phase 2 starting
PROGRESS: Phase 2 complete
EOF

  cat > /tmp/test_wave_fail/phase_3_output.txt << 'EOF'
PROGRESS: Phase 3 starting
ERROR: Test failure
EOF

  # Simulate aggregation with failure
  declare -A PHASE_STATUS

  for phase_num in 2 3; do
    OUTPUT_FILE="/tmp/test_wave_fail/phase_${phase_num}_output.txt"

    if grep -q "PROGRESS: Phase $phase_num complete" "$OUTPUT_FILE"; then
      PHASE_STATUS[$phase_num]="success"
    else
      PHASE_STATUS[$phase_num]="failure"
    fi
  done

  # Verify fail-fast detection
  [[ "${PHASE_STATUS[2]}" == "success" ]] || return 1
  [[ "${PHASE_STATUS[3]}" == "failure" ]] || return 1

  echo "PASS: Failure handling"
}

# Run tests
echo "Testing parallel agent patterns..."
test_result_aggregation
test_failure_handling
echo "All parallel agent tests passed"
```

---

## 3. Testing Specifications (~60-80 lines)

### 3.1 Test Scenarios

**Scenario 1: Independent Phases Execute in Parallel**
- **Plan**: 3 phases with dependencies: [], [1], [1]
- **Expected**: Wave 1 (Phase 1), Wave 2 (Phases 2 and 3 in parallel)
- **Verification**: Check wave execution logs, verify timing improvements

**Scenario 2: Complex Dependency Graph**
- **Plan**: 5 phases with mixed dependencies
- **Expected**: Correct wave generation respecting all dependencies
- **Verification**: Ensure no phase executes before its dependencies complete

**Scenario 3: Partial Wave Failure**
- **Plan**: Wave with 3 phases, phase 2 fails
- **Expected**: Fail-fast behavior, checkpoint saved with partial progress
- **Verification**: Phases 1 and 3 marked success, phase 2 marked failure, checkpoint allows resume

**Scenario 4: Checkpoint Resume After Wave Failure**
- **Plan**: Resume from wave 2 after fixing failure
- **Expected**: Reload wave state, restart from failed wave
- **Verification**: Completed waves not re-executed, failed wave retried

**Scenario 5: Race Condition Handling**
- **Plan**: Two phases modifying same file (invalid plan)
- **Expected**: Detect conflict, report to user
- **Verification**: Error message suggests fixing plan dependencies

**Scenario 6: Sequential Override**
- **Plan**: Use --sequential flag
- **Expected**: Traditional phase-by-phase execution, no parallelization
- **Verification**: Waves not generated, execution is sequential

### 3.2 State Consistency Tests

**Test: Checkpoint Wave State Preservation**
```bash
test_checkpoint_wave_state() {
  # Create plan and execute first wave
  PLAN="test_parallel_plan.md"
  /implement "$PLAN"  # Will stop after wave 1 if we interrupt

  # Load checkpoint
  CHECKPOINT=$(restore_checkpoint "implement" "test_parallel_plan")

  # Verify wave structure preserved
  WAVE_STRUCTURE=$(echo "$CHECKPOINT" | jq -r '.workflow_state.wave_structure')
  [[ -n "$WAVE_STRUCTURE" ]] || return 1

  # Verify current wave tracked
  CURRENT_WAVE=$(echo "$CHECKPOINT" | jq -r '.workflow_state.current_wave')
  [[ "$CURRENT_WAVE" -eq 2 ]] || return 1

  echo "PASS: Checkpoint wave state"
}
```

**Test: Wave Result Accuracy**
```bash
test_wave_result_accuracy() {
  # Execute wave with known timing
  START=$(date +%s%N)
  execute_wave_parallel 2 3
  END=$(date +%s%N)
  ACTUAL_DURATION=$(( (END - START) / 1000000 ))

  # Check checkpoint duration
  CHECKPOINT=$(restore_checkpoint "implement" "test")
  RECORDED_DURATION=$(echo "$CHECKPOINT" | jq -r '.workflow_state.wave_results["2"].duration_ms')

  # Allow 10% margin for overhead
  DIFF=$(( ACTUAL_DURATION - RECORDED_DURATION ))
  [[ $DIFF -lt $(( ACTUAL_DURATION / 10 )) ]] || return 1

  echo "PASS: Wave duration accuracy"
}
```

---

## 4. Risk Mitigation Patterns (~40-60 lines)

### 4.1 Race Condition Scenarios

**Risk**: Two phases modify the same file simultaneously

**Detection**:
```bash
# Before starting wave, analyze file dependencies
detect_file_conflicts() {
  local wave_phases=("$@")

  # Extract files modified by each phase (from phase tasks)
  declare -A PHASE_FILES
  for phase_num in "${wave_phases[@]}"; do
    PHASE_FILES[$phase_num]=$(extract_modified_files "$PLAN_PATH" "$phase_num")
  done

  # Check for overlaps
  for phase_a in "${wave_phases[@]}"; do
    for phase_b in "${wave_phases[@]}"; do
      if [[ $phase_a -lt $phase_b ]]; then
        OVERLAP=$(comm -12 <(echo "${PHASE_FILES[$phase_a]}" | tr ' ' '\n' | sort) \
                           <(echo "${PHASE_FILES[$phase_b]}" | tr ' ' '\n' | sort))
        if [[ -n "$OVERLAP" ]]; then
          echo "WARNING: Phases $phase_a and $phase_b both modify:"
          echo "$OVERLAP"
          echo "Consider adding dependency to prevent race condition"
          return 1
        fi
      fi
    done
  done

  return 0
}
```

**Mitigation**:
- Run file conflict detection before parallel execution
- If conflicts detected, offer to add dependencies or run sequentially
- Log conflicts for user review

### 4.2 Failure Handling Decision Trees

**Decision Tree: Wave Execution Failure**

```
Phase N fails during wave execution
    │
    ├─ Other phases still running?
    │   ├─ Yes: Wait for completion (collect all results)
    │   └─ No: Proceed to failure handling
    │
    └─ Collect failure information
        │
        ├─ Classify error (error-utils.sh)
        │   ├─ Transient: Suggest retry
        │   ├─ Permanent: Suggest debug
        │   └─ Fatal: User intervention
        │
        ├─ Save checkpoint with partial progress
        │   ├─ Mark successful phases complete
        │   ├─ Mark failed phase incomplete
        │   └─ Preserve wave state
        │
        └─ Present recovery options
            ├─ 1. Fix and retry failed phase
            ├─ 2. Run /debug for investigation
            └─ 3. Skip phase (with confirmation)
```

### 4.3 State Rollback Mechanisms

**Rollback Strategy**: Preserve partial progress, allow selective retry

```bash
rollback_failed_wave() {
  local wave_num=$1
  local failed_phases=("${@:2}")

  echo "Rolling back failed wave $wave_num..."

  # Keep successful phase results
  for phase_num in "${WAVE_PHASES[@]}"; do
    if [[ ! " ${failed_phases[*]} " =~ " ${phase_num} " ]]; then
      echo "Phase $phase_num succeeded - keeping changes"
      # Update plan to mark complete
      mark_phase_complete "$PLAN_PATH" "$phase_num"
    fi
  done

  # Reset failed phases to incomplete
  for failed_phase in "${failed_phases[@]}"; do
    echo "Phase $failed_phase failed - marking incomplete"
    mark_phase_incomplete "$PLAN_PATH" "$failed_phase"
  done

  # Save checkpoint allowing resume from this wave
  CHECKPOINT_STATE=$(build_checkpoint_state)
  CHECKPOINT_STATE=$(echo "$CHECKPOINT_STATE" | jq \
    --argjson wave "$wave_num" \
    '.workflow_state.current_wave = $wave')
  save_checkpoint "implement" "$PLAN_NAME" "$CHECKPOINT_STATE"

  echo "Resume with: /implement $PLAN_PATH"
}
```

### 4.4 Debugging Strategies for Parallel Execution

**Debug Output for Parallel Issues**:

```bash
debug_parallel_execution() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Parallel Execution Debug Information"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Wave: $WAVE_NUM"
  echo "Phases: ${WAVE_PHASES[*]}"
  echo "Execution mode: $([ ${#WAVE_PHASES[@]} -gt 1 ] && echo 'parallel' || echo 'sequential')"
  echo ""
  echo "Phase Results:"
  for phase_num in "${WAVE_PHASES[@]}"; do
    echo "  Phase $phase_num: ${PHASE_STATUS[$phase_num]}"
    if [[ "${PHASE_STATUS[$phase_num]}" == "failure" ]]; then
      echo "    Output file: /tmp/phase_${phase_num}_output.txt"
      echo "    Test output:"
      echo "${PHASE_TEST_OUTPUT[$phase_num]}" | head -20
    fi
  done
  echo ""
  echo "Checkpoint: $(find .claude/checkpoints -name 'implement_*' -type f | tail -1)"
  echo "Logs: .claude/logs/adaptive-planning.log"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
```

---

## 5. Integration Examples (~30-50 lines)

### Before: Sequential Execution

```bash
# Current /implement command (simplified)
for phase_num in $(seq 1 $TOTAL_PHASES); do
  echo "Executing Phase $phase_num..."

  # Extract phase content
  PHASE_CONTENT=$(extract_phase "$PLAN_PATH" "$phase_num")

  # Determine agent based on complexity
  COMPLEXITY=$(calculate_phase_complexity "$PHASE_CONTENT")
  AGENT=$(select_agent "$COMPLEXITY")

  # Invoke agent sequentially
  invoke_agent "$AGENT" "$PHASE_CONTENT"

  # Wait for completion
  wait_for_agent

  # Run tests
  run_phase_tests "$phase_num"

  # Commit changes
  git commit -m "feat: implement Phase $phase_num"

  # Save checkpoint
  save_checkpoint "implement" "$PLAN_NAME" "$(build_checkpoint_state)"
done

# Total time: 5 phases × 3 minutes = 15 minutes
```

### After: Parallel Wave Execution

```bash
# New /implement command (simplified)

# Generate waves from dependencies
WAVES=$(.claude/lib/parse-phase-dependencies.sh "$PLAN_PATH")

for wave_line in "${WAVE_STRUCTURE[@]}"; do
  WAVE_NUM=$(echo "$wave_line" | cut -d':' -f1 | sed 's/WAVE_//')
  IFS=' ' read -ra WAVE_PHASES <<< "$(echo "$wave_line" | cut -d':' -f2)"

  echo "Executing Wave $WAVE_NUM with ${#WAVE_PHASES[@]} phase(s)..."

  if [[ ${#WAVE_PHASES[@]} -eq 1 ]]; then
    # Single phase - sequential
    execute_phase_sequential "${WAVE_PHASES[0]}"
  else
    # Multiple phases - parallel
    echo "Invoking ${#WAVE_PHASES[@]} agents in parallel..."

    # Build parallel prompt
    build_parallel_prompt "${WAVE_PHASES[@]}" > /tmp/parallel_wave.txt

    # Invoke all agents (Claude Code handles multiple Task tools)
    # (In practice, this sends the prompt and waits for response)

    # Aggregate results
    aggregate_wave_results "$WAVE_NUM" "${WAVE_PHASES[@]}"

    # Check for failures
    if [[ "$WAVE_STATUS" == "failure" ]]; then
      handle_wave_failure "$WAVE_NUM" "${FAILED_PHASES[@]}"
      exit 1
    fi
  fi

  # Test all phases in wave
  test_wave_results "$WAVE_NUM" "${WAVE_PHASES[@]}"

  # Commit wave changes
  commit_wave_changes "$WAVE_NUM" "${WAVE_PHASES[@]}"

  # Save checkpoint with wave state
  save_wave_checkpoint "$WAVE_NUM" "completed" "${WAVE_PHASES[@]}"
done

# Total time with parallel execution:
# Wave 1: Phase 1 (3 min)
# Wave 2: Phases 2, 3 in parallel (3 min max)
# Wave 3: Phase 4 (3 min)
# Wave 4: Phase 5 (3 min)
# Total: 12 minutes → 9 minutes with parallelization (25% reduction)
```

### Timing Analysis Example

```bash
# Measure performance improvement
measure_execution_time() {
  local plan=$1

  # Sequential execution
  echo "Testing sequential execution..."
  START_SEQ=$(date +%s)
  /implement "$plan" --sequential
  END_SEQ=$(date +%s)
  SEQUENTIAL_TIME=$((END_SEQ - START_SEQ))

  # Reset plan status
  reset_plan "$plan"

  # Parallel execution
  echo "Testing parallel execution..."
  START_PAR=$(date +%s)
  /implement "$plan"
  END_PAR=$(date +%s)
  PARALLEL_TIME=$((END_PAR - START_PAR))

  # Calculate improvement
  IMPROVEMENT=$(echo "scale=2; (($SEQUENTIAL_TIME - $PARALLEL_TIME) / $SEQUENTIAL_TIME) * 100" | bc)

  echo ""
  echo "Performance Results:"
  echo "  Sequential: ${SEQUENTIAL_TIME}s"
  echo "  Parallel:   ${PARALLEL_TIME}s"
  echo "  Improvement: ${IMPROVEMENT}%"
  echo ""
}
```

---

## Summary

This detailed specification provides:

1. **Comprehensive architecture** for wave-based parallel execution
2. **Concrete implementation steps** with actual code examples and file paths
3. **Thorough testing specifications** with specific test scenarios and code
4. **Risk mitigation patterns** covering race conditions, failures, and debugging
5. **Integration examples** showing before/after patterns and timing analysis

**Key Implementation Files**:
- `/home/benjamin/.config/.claude/commands/implement.md` (main integration point)
- `/home/benjamin/.config/.claude/lib/parse-phase-dependencies.sh` (existing, reused)
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (existing, extended)
- `/home/benjamin/.config/.claude/tests/test_parallel_waves.sh` (new test)
- `/home/benjamin/.config/.claude/tests/test_parallel_agents.sh` (new test)

**Expected Outcomes**:
- 40-60% performance improvement for plans with independent phases
- Robust error handling with fail-fast behavior
- State consistency via checkpoint extensions
- Comprehensive test coverage for parallel execution patterns
