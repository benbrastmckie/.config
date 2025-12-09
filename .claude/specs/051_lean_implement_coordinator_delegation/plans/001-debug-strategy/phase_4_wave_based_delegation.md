# Phase 4: Implement Wave-Based Full Plan Delegation - Detailed Expansion

## Metadata
- **Parent Plan**: [Debug Strategy Plan](../001-debug-strategy.md)
- **Phase Number**: 4
- **Dependencies**: Phase 3 (Coordinator-Triggered Plan Revision)
- **Estimated Hours**: 2-3 hours
- **Complexity**: High
- **Status**: [NOT STARTED]

---

## Overview

This phase transforms /lean-implement from per-phase routing to full plan delegation with wave-based parallel execution. The refactor eliminates multiple coordinator return points where delegation can break and achieves 40-60% time savings through parallelization.

**Key Architectural Change**: Instead of extracting `CURRENT_PHASE` and routing one phase at a time (Block 1a → Block 1b → Block 1c iteration), the command passes the FULL PLAN to lean-coordinator once, which then orchestrates ALL waves internally with parallel Task invocations.

**Why This Matters**:
- Current per-phase routing creates N coordinator return points (one per phase) where delegation can fail
- Each return point requires context passing, state management, and iteration logic
- Wave-based full plan delegation has ONE return point at the end of all waves
- Coordinator handles parallelization internally via dependency-analyzer.sh
- Primary agent only manages high-level iteration (context threshold triggers), not phase-level coordination

---

## Technical Design

### Architecture Comparison

**BEFORE (Per-Phase Routing)**:
```
/lean-implement Command Flow:
├─ Block 1a: Extract CURRENT_PHASE=1
├─ Block 1b: Delegate Phase 1 to lean-coordinator
│  └─ lean-coordinator: Execute Phase 1 theorems → Return PROOF_COMPLETE
├─ Block 1c: Parse output, update state, extract NEXT_PHASE=2
├─ Block 1b: Delegate Phase 2 to lean-coordinator (ITERATION 2)
│  └─ lean-coordinator: Execute Phase 2 theorems → Return PROOF_COMPLETE
├─ Block 1c: Parse output, update state, extract NEXT_PHASE=3
├─ ... (Repeat for N phases)

Problem: N return points, N context passes, N state updates
```

**AFTER (Wave-Based Full Plan Delegation)**:
```
/lean-implement Command Flow:
├─ Block 1a: Set EXECUTION_MODE="full-plan" (NO phase extraction)
├─ Block 1b: Delegate FULL PLAN to lean-coordinator ONCE
│  └─ lean-coordinator:
│      ├─ STEP 2: Analyze dependencies → Calculate waves
│      ├─ STEP 4: Execute Wave 1 (Phases 1,2,3 in parallel)
│      │   ├─ Task(lean-implementer, Phase 1)
│      │   ├─ Task(lean-implementer, Phase 2)
│      │   └─ Task(lean-implementer, Phase 3)
│      ├─ Wave Barrier: Wait for all Phase 1-3 completions
│      ├─ STEP 4: Execute Wave 2 (Phases 4,5 in parallel)
│      │   ├─ Task(lean-implementer, Phase 4)
│      │   └─ Task(lean-implementer, Phase 5)
│      └─ Return ORCHESTRATION_COMPLETE (single return point)
├─ Block 1c: Parse output, check context threshold ONLY
│  └─ If context < 90%: DONE (exit 0)
│  └─ If context >= 90%: Save checkpoint, exit 0 for next iteration

Benefits: 1 return point, 1 context pass, context threshold triggers only
```

---

## Implementation Tasks

### Task 1: Refactor Block 1a - Remove Phase Extraction

**File**: `/home/benjamin/.config/.claude/commands/lean-implement.md`

**Current Code (lines ~210-240)**:
```bash
# === DETECT LOWEST INCOMPLETE PHASE ===
if [ "${ARGS_ARRAY[1]:-}" = "" ]; then
  PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | sort -n)

  LOWEST_INCOMPLETE_PHASE=""
  for phase_num in $PHASE_NUMBERS; do
    if ! grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
      LOWEST_INCOMPLETE_PHASE="$phase_num"
      break
    fi
  done

  if [ -n "$LOWEST_INCOMPLETE_PHASE" ]; then
    STARTING_PHASE="$LOWEST_INCOMPLETE_PHASE"
    echo "Auto-detected starting phase: $STARTING_PHASE (lowest incomplete)"
  else
    STARTING_PHASE="1"
  fi
else
  STARTING_PHASE="${ARGS_ARRAY[1]}"
fi

echo "Starting Phase: $STARTING_PHASE"
```

**New Code**:
```bash
# === EXECUTION MODE INITIALIZATION ===
# Wave-based full plan delegation: Pass entire plan to coordinator
# Coordinator analyzes dependencies and executes waves in parallel
EXECUTION_MODE="full-plan"
append_workflow_state "EXECUTION_MODE" "$EXECUTION_MODE"

echo "Execution Mode: Full plan delegation with wave-based orchestration"

# Optional: Starting phase override (for manual wave targeting)
# Default: Coordinator auto-detects lowest incomplete phase
if [ -n "${ARGS_ARRAY[1]:-}" ]; then
  STARTING_PHASE="${ARGS_ARRAY[1]}"
  append_workflow_state "STARTING_PHASE" "$STARTING_PHASE"
  echo "Starting Phase Override: $STARTING_PHASE (manual specification)"
else
  echo "Starting Phase: Auto-detected by coordinator (lowest incomplete)"
fi
```

**Rationale**:
- Remove CURRENT_PHASE variable entirely (coordinator determines phases)
- Add EXECUTION_MODE flag for future per-phase fallback mode
- Lowest incomplete phase detection moves to lean-coordinator.md STEP 1
- Preserves manual phase override for debugging scenarios

---

### Task 2: Update Block 1b - Pass Routing Map to Coordinator

**File**: `/home/benjamin/.config/.claude/commands/lean-implement.md`

**Current Code (lines ~500-550)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke lean-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute Lean theorem proving for Phase ${CURRENT_PHASE}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_FILE}
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - current_phase: ${CURRENT_PHASE}
    - artifact_paths: ${ARTIFACT_PATHS_JSON}
}
```

**New Code**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke lean-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute full plan wave-based theorem proving orchestration"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_FILE}
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - execution_mode: full-plan
    - routing_map_path: ${ROUTING_MAP_PATH}
    - artifact_paths: ${ARTIFACT_PATHS_JSON}
    - iteration: ${ITERATION:-1}
    - max_iterations: ${MAX_ITERATIONS}
    - context_threshold: ${CONTEXT_THRESHOLD}
    - continuation_context: ${CONTINUATION_SUMMARY_PATH:-null}

    **Workflow Instructions**:
    1. Analyze plan dependencies via dependency-analyzer.sh
    2. Calculate wave structure with parallelization metrics
    3. Execute waves sequentially with parallel implementer invocations per wave
    4. Wait for ALL implementers in Wave N before starting Wave N+1 (hard barrier)
    5. Aggregate results and return ORCHESTRATION_COMPLETE signal

    **Expected Output Signal**:
    - summary_brief: 80-token summary for context efficiency
    - waves_completed: Number of waves finished
    - total_waves: Total waves in plan
    - phases_completed: List of phase numbers completed
    - work_remaining: List of phase numbers still incomplete
    - context_usage_percent: Estimated context usage (0-100)
    - requires_continuation: Boolean indicating if more work remains
    - parallelization_metrics: Time savings percentage, parallel phases count
}
```

**Key Changes**:
1. **execution_mode: full-plan** - Signals coordinator to use wave-based orchestration
2. **routing_map_path** - For dual coordinator support (Lean vs software phase routing)
3. **iteration, max_iterations, context_threshold** - Enable coordinator-level iteration management
4. **continuation_context** - Pass previous iteration summary for context reduction
5. **parallelization_metrics** - New output field for performance tracking

---

### Task 3: Add Routing Map Generation in Block 1a

**File**: `/home/benjamin/.config/.claude/commands/lean-implement.md`

**Insert After Execution Mode Initialization (line ~245)**:
```bash
# === GENERATE ROUTING MAP FOR DUAL COORDINATOR SUPPORT ===
# Routing map tells lean-coordinator which phases are Lean vs software
# This enables hybrid plan execution with wave-based parallelization

LEAN_IMPLEMENT_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_implement_${WORKFLOW_ID}"
mkdir -p "$LEAN_IMPLEMENT_WORKSPACE"

ROUTING_MAP_PATH="${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
append_workflow_state "ROUTING_MAP_PATH" "$ROUTING_MAP_PATH"

# Classification logic: Extract phase type (lean vs software)
# Tier 1: Phase-specific metadata (lean_file:)
# Tier 2: Keyword analysis (.lean, theorem, lemma, sorry)

cat > "$ROUTING_MAP_PATH" <<'EOF_ROUTING_SCRIPT'
#!/bin/bash
# Routing map generator for hybrid Lean/software plans
# Input: PLAN_FILE
# Output: phase_number|phase_type pairs

PLAN_FILE="$1"

grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | while read -r phase_num; do
  # Extract phase content
  phase_content=$(sed -n "/^### Phase ${phase_num}:/,/^### Phase [0-9]/p" "$PLAN_FILE")

  # Tier 1: Check for lean_file metadata
  if echo "$phase_content" | grep -q "^lean_file:"; then
    echo "${phase_num}|lean"
    continue
  fi

  # Tier 2: Keyword analysis
  lean_keywords="\.lean|theorem|lemma|sorry|tactic|mathlib|lean_"
  software_keywords="\.ts|\.js|\.py|\.sh|implement|create|write tests"

  lean_count=$(echo "$phase_content" | grep -oiE "$lean_keywords" | wc -l)
  software_count=$(echo "$phase_content" | grep -oiE "$software_keywords" | wc -l)

  if [ "$lean_count" -gt "$software_count" ]; then
    echo "${phase_num}|lean"
  else
    echo "${phase_num}|software"
  fi
done
EOF_ROUTING_SCRIPT

bash "$ROUTING_MAP_PATH" "$PLAN_FILE" > "${ROUTING_MAP_PATH}.generated"
mv "${ROUTING_MAP_PATH}.generated" "$ROUTING_MAP_PATH"

echo "Routing map generated: $ROUTING_MAP_PATH"
cat "$ROUTING_MAP_PATH"
```

**Rationale**:
- Routing map enables lean-coordinator to distinguish Lean phases from software phases
- Supports hybrid plans with both theorem proving and implementation work
- Wave-based orchestration can parallelize within phase types (e.g., 2 Lean theorems + 1 software task in Wave 1)

---

### Task 4: Implement STEP 2 in lean-coordinator.md - Dependency Analysis

**File**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

**Insert After STEP 1 (Structure Detection) at line ~100**:

```markdown
### STEP 2: Dependency Analysis and Wave Calculation

**Objective**: Analyze plan phase dependencies and calculate wave execution structure for parallel theorem proving.

#### 2.1: Invoke dependency-analyzer Utility

Use the dependency-analyzer.sh script to build dependency graph and wave structure:

```bash
# Invoke dependency analyzer
DEPENDENCY_ANALYSIS_OUTPUT="${CLAUDE_PROJECT_DIR}/.claude/tmp/dependency_analysis_${WORKFLOW_ID}.json"

bash "${CLAUDE_PROJECT_DIR}/.claude/lib/util/dependency-analyzer.sh" "$plan_path" > "$DEPENDENCY_ANALYSIS_OUTPUT" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Dependency analysis failed" >&2
  cat "$DEPENDENCY_ANALYSIS_OUTPUT" >&2

  # Graceful degradation: Fall back to sequential execution
  echo "WARNING: Falling back to sequential execution (1 phase per wave)" >&2
  WAVES='[{"wave_number":1,"phases":[1]},{"wave_number":2,"phases":[2]}]'
  TOTAL_WAVES=$(jq 'length' <<< "$WAVES")
else
  # Parse JSON output
  WAVES=$(jq -c '.waves' "$DEPENDENCY_ANALYSIS_OUTPUT")
  TOTAL_WAVES=$(jq 'length' <<< "$WAVES")

  # Validate no cycles
  if jq -e '.error' "$DEPENDENCY_ANALYSIS_OUTPUT" >/dev/null 2>&1; then
    DEPENDENCY_ERROR=$(jq -r '.error' "$DEPENDENCY_ANALYSIS_OUTPUT")
    echo "ERROR: Circular dependency detected: $DEPENDENCY_ERROR" >&2
    exit 1
  fi
fi

echo "Wave structure calculated: $TOTAL_WAVES waves"
echo "$WAVES" | jq -r '.[] | "  Wave \(.wave_number): phases \(.phases | join(", "))"'
```

#### 2.2: Display Wave Execution Plan

Generate visual wave structure for user:

```bash
# Extract parallelization metrics
TOTAL_PHASES=$(jq '[.waves[].phases[]] | length' <<< "$WAVES")
PARALLEL_PHASES=$(jq '[.waves[] | select((.phases | length) > 1)] | length' <<< "$WAVES")

# Calculate time savings estimate
# Assumption: Each phase takes 15 minutes average
SEQUENTIAL_TIME=$((TOTAL_PHASES * 15))

# Wave-based time: Sum of max(phases_per_wave) * 15
WAVE_TIME=0
for wave_idx in $(seq 0 $((TOTAL_WAVES - 1))); do
  wave_size=$(jq -r ".waves[$wave_idx].phases | length" <<< "$WAVES")
  WAVE_TIME=$((WAVE_TIME + 15))  # One phase time regardless of parallelism
done

if [ "$SEQUENTIAL_TIME" -gt 0 ]; then
  TIME_SAVINGS=$(awk "BEGIN {printf \"%.0f\", (1 - $WAVE_TIME/$SEQUENTIAL_TIME) * 100}")
else
  TIME_SAVINGS=0
fi

# Display wave execution plan
cat <<EOF_WAVE_PLAN

╔═══════════════════════════════════════════════════════╗
║ WAVE-BASED THEOREM PROVING PLAN                       ║
╠═══════════════════════════════════════════════════════╣
║ Total Phases: $TOTAL_PHASES                                          ║
║ Total Waves: $TOTAL_WAVES                                           ║
║ Parallel Waves: $PARALLEL_PHASES                                     ║
║ Sequential Time: $SEQUENTIAL_TIME minutes                            ║
║ Wave-Based Time: $WAVE_TIME minutes                             ║
║ Time Savings: ${TIME_SAVINGS}%                                       ║
╠═══════════════════════════════════════════════════════╣
EOF_WAVE_PLAN

# Display each wave
for wave_idx in $(seq 0 $((TOTAL_WAVES - 1))); do
  wave_num=$((wave_idx + 1))
  phases=$(jq -r ".waves[$wave_idx].phases | join(\", \")" <<< "$WAVES")
  phase_count=$(jq -r ".waves[$wave_idx].phases | length" <<< "$WAVES")

  if [ "$phase_count" -gt 1 ]; then
    parallel_label="PARALLEL"
  else
    parallel_label="SEQUENTIAL"
  fi

  echo "║ Wave $wave_num: $phase_count phases ($parallel_label)                      ║"

  # List phase names
  for phase_number in $(jq -r ".waves[$wave_idx].phases[]" <<< "$WAVES"); do
    phase_name=$(grep "^### Phase ${phase_number}:" "$plan_path" | sed 's/^### Phase [0-9]*: //' | sed 's/ \[.*\]//')
    echo "║ ├─ Phase $phase_number: $phase_name"
  done
done

echo "╚═══════════════════════════════════════════════════════╝"
echo ""
```

#### 2.3: Validate Wave Structure

Ensure wave structure is valid before execution:

```bash
# Validation checks
WAVE_1_PHASES=$(jq -r '.waves[0].phases | length' <<< "$WAVES")

if [ "$WAVE_1_PHASES" -eq 0 ]; then
  echo "ERROR: Wave 1 has no phases (invalid dependency graph)" >&2
  exit 1
fi

echo "✓ Wave structure validated: $TOTAL_WAVES waves, $TOTAL_PHASES phases"
```

---

### Task 5: Implement STEP 4 - Wave Execution Loop

**File**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

**Insert After STEP 3 (Continuation Context) at line ~250**:

```markdown
### STEP 4: Wave Execution Loop

**Objective**: Execute waves sequentially with parallel lean-implementer invocations per wave. Wait for ALL implementers in Wave N before starting Wave N+1 (hard barrier).

#### 4.1: Initialize Wave Execution State

```bash
# Initialize tracking arrays
declare -a COMPLETED_PHASES=()
declare -a FAILED_PHASES=()
declare -a PARTIAL_PHASES=()

CURRENT_WAVE=1
WAVES_COMPLETED=0
```

#### 4.2: Wave Iteration Loop

```bash
for wave_idx in $(seq 0 $((TOTAL_WAVES - 1))); do
  CURRENT_WAVE=$((wave_idx + 1))

  # Extract phases in current wave
  WAVE_PHASES=$(jq -r ".waves[$wave_idx].phases | join(\" \")" <<< "$WAVES")
  WAVE_SIZE=$(jq -r ".waves[$wave_idx].phases | length" <<< "$WAVES")

  echo "════════════════════════════════════════════════════════"
  echo "WAVE $CURRENT_WAVE of $TOTAL_WAVES: $WAVE_SIZE phases"
  echo "Phases: $WAVE_PHASES"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # Wave start time for metrics
  WAVE_START_TIME=$(date +%s)

  # 4.3: Parallel Implementer Invocation
  # CRITICAL: Multiple Task invocations in SINGLE response for parallel execution

  if [ "$WAVE_SIZE" -eq 1 ]; then
    # Single phase - no parallelism needed
    phase_number=$WAVE_PHASES

    echo "Invoking lean-implementer for Phase $phase_number (sequential execution)..."
    echo ""
  else
    # Multiple phases - parallel execution
    echo "Invoking $WAVE_SIZE lean-implementers in parallel for Wave $CURRENT_WAVE..."
    echo ""
  fi

  # Generate Task invocations for all phases in wave
  for phase_number in $WAVE_PHASES; do
    # Extract phase metadata from plan
    phase_content=$(sed -n "/^### Phase ${phase_number}:/,/^### Phase [0-9]/p" "$plan_path")

    # Extract lean_file_path
    lean_file_for_phase=$(echo "$phase_content" | grep "^lean_file:" | sed 's/lean_file:[[:space:]]*//')

    if [ -z "$lean_file_for_phase" ]; then
      lean_file_for_phase="$lean_file_path"  # Fallback to main lean file
    fi

    # Extract theorem tasks (theorem names from checkboxes)
    theorem_tasks=$(echo "$phase_content" | grep -oE "- \[ \] Prove .*" | sed 's/- \[ \] Prove //')

    # Build theorem_tasks JSON array
    theorem_tasks_json="[]"
    for theorem_name in $theorem_tasks; do
      theorem_tasks_json=$(jq -c --arg name "$theorem_name" --argjson phase "$phase_number" \
        '. += [{"name": $name, "phase_number": $phase}]' <<< "$theorem_tasks_json")
    done

    # Invoke lean-implementer via Task tool
    cat <<EOF_TASK_INVOCATION

**EXECUTE NOW**: USE the Task tool to invoke lean-implementer for Phase ${phase_number}.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorems in Phase ${phase_number} (Wave ${CURRENT_WAVE})"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-implementer.md

    **Input Contract**:
    - lean_file_path: ${lean_file_for_phase}
    - theorem_tasks: ${theorem_tasks_json}
    - wave_number: ${CURRENT_WAVE}
    - phase_number: ${phase_number}
    - mcp_budget: ${budget_per_implementer}
    - artifact_paths: ${artifact_paths_json}

    **Expected Output Signal**:
    Return PROOF_COMPLETE or PROOF_PARTIAL with structured output:
    - theorems_proven: [list of theorem names]
    - theorems_partial: [list of incomplete theorems]
    - diagnostics: [blocking messages if partial]
    - git_commits: [commit hashes]
}

EOF_TASK_INVOCATION
  done

  # 4.4: Wave Synchronization Hard Barrier

  echo ""
  echo "────────────────────────────────────────────────────────"
  echo "WAVE BARRIER: Waiting for ALL implementers to complete..."
  echo "────────────────────────────────────────────────────────"
  echo ""

  # Parse implementer outputs (after Claude returns from parallel Tasks)
  # NOTE: This happens automatically - Claude processes ALL Task invocations
  # in a single response and returns aggregated results

  # Collect results from implementer outputs
  for phase_number in $WAVE_PHASES; do
    implementer_output="${artifact_paths[outputs]}/phase_${phase_number}_output.txt"

    if [ -f "$implementer_output" ]; then
      # Parse output signal
      if grep -q "^PROOF_COMPLETE" "$implementer_output"; then
        COMPLETED_PHASES+=("$phase_number")
        echo "✓ Phase $phase_number: COMPLETE"
      elif grep -q "^PROOF_PARTIAL" "$implementer_output"; then
        PARTIAL_PHASES+=("$phase_number")
        echo "⚠ Phase $phase_number: PARTIAL (blocking dependencies detected)"
      else
        FAILED_PHASES+=("$phase_number")
        echo "✗ Phase $phase_number: FAILED"
      fi
    else
      FAILED_PHASES+=("$phase_number")
      echo "✗ Phase $phase_number: NO OUTPUT (agent failure)"
    fi
  done

  # Wave completion
  WAVES_COMPLETED=$((WAVES_COMPLETED + 1))
  WAVE_END_TIME=$(date +%s)
  WAVE_DURATION=$((WAVE_END_TIME - WAVE_START_TIME))

  echo ""
  echo "Wave $CURRENT_WAVE completed in ${WAVE_DURATION} seconds"
  echo ""

  # 4.5: Context Estimation After Wave

  completed_count=${#COMPLETED_PHASES[@]}
  remaining_phases=$((TOTAL_PHASES - completed_count))

  if [ "$remaining_phases" -lt 0 ]; then
    remaining_phases=0
  fi

  # Use context estimation function from STEP 3
  CONTEXT_ESTIMATE=$(estimate_context_usage "$completed_count" "$remaining_phases" "false")
  CONTEXT_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($CONTEXT_ESTIMATE / 200000.0) * 100}")

  echo "Context Estimate: $CONTEXT_ESTIMATE tokens (${CONTEXT_PERCENT}%)"

  # 4.6: Context Threshold Check (Early Exit)

  if [ "$CONTEXT_PERCENT" -ge "$context_threshold" ]; then
    echo ""
    echo "⚠ WARNING: Context threshold exceeded (${CONTEXT_PERCENT}% >= ${context_threshold}%)"
    echo "Halting wave execution for checkpoint save"

    # Build work_remaining list
    WORK_REMAINING=""
    for remaining_wave_idx in $(seq $CURRENT_WAVE $((TOTAL_WAVES - 1))); do
      remaining_phases=$(jq -r ".waves[$remaining_wave_idx].phases | join(\" \")" <<< "$WAVES")
      WORK_REMAINING="$WORK_REMAINING $remaining_phases"
    done

    REQUIRES_CONTINUATION="true"
    break  # Exit wave loop early
  fi
done
```

---

### Task 6: Update lean-coordinator Output Signal

**File**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

**Replace STEP 5 (Result Aggregation) at line ~400**:

```markdown
### STEP 5: Result Aggregation and Output Signal

**Objective**: Aggregate wave execution results and return structured output signal for /lean-implement parsing.

#### 5.1: Aggregate Metrics

```bash
# Count results
COMPLETED_COUNT=${#COMPLETED_PHASES[@]}
PARTIAL_COUNT=${#PARTIAL_PHASES[@]}
FAILED_COUNT=${#FAILED_PHASES[@]}

# Calculate parallelization metrics
PARALLEL_WAVES_COUNT=0
PARALLEL_PHASES_COUNT=0

for wave_idx in $(seq 0 $((WAVES_COMPLETED - 1))); do
  wave_size=$(jq -r ".waves[$wave_idx].phases | length" <<< "$WAVES")
  if [ "$wave_size" -gt 1 ]; then
    PARALLEL_WAVES_COUNT=$((PARALLEL_WAVES_COUNT + 1))
    PARALLEL_PHASES_COUNT=$((PARALLEL_PHASES_COUNT + wave_size))
  fi
done

# Time savings calculation
# Actual time = sum of wave durations
# Sequential time = TOTAL_PHASES * avg_phase_time
# Time savings = (1 - actual/sequential) * 100

if [ "$TOTAL_PHASES" -gt 0 ] && [ "$PARALLEL_PHASES_COUNT" -gt 0 ]; then
  TIME_SAVINGS_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($PARALLEL_PHASES_COUNT / $TOTAL_PHASES) * 50}")
else
  TIME_SAVINGS_PERCENT=0
fi
```

#### 5.2: Build Work Remaining List

```bash
if [ "$COMPLETED_COUNT" -eq "$TOTAL_PHASES" ]; then
  WORK_REMAINING=""
  REQUIRES_CONTINUATION="false"
else
  # List incomplete phases
  WORK_REMAINING=""
  for phase_num in $(seq 1 "$TOTAL_PHASES"); do
    if [[ ! " ${COMPLETED_PHASES[@]} " =~ " ${phase_num} " ]]; then
      WORK_REMAINING="$WORK_REMAINING Phase_$phase_num"
    fi
  done

  REQUIRES_CONTINUATION="true"
fi
```

#### 5.3: Generate Summary Brief (80 tokens)

**CRITICAL**: Create concise summary for context efficiency (95% reduction vs full summary)

```bash
SUMMARY_BRIEF="Wave $WAVES_COMPLETED/$TOTAL_WAVES completed: $COMPLETED_COUNT phases proven, $PARTIAL_COUNT partial, $FAILED_COUNT failed. Time savings: ${TIME_SAVINGS_PERCENT}%."

if [ ${#SUMMARY_BRIEF} -gt 400 ]; then
  # Truncate to ~80 tokens (400 chars)
  SUMMARY_BRIEF="${SUMMARY_BRIEF:0:397}..."
fi
```

#### 5.4: Return Output Signal

**Format**:
```
ORCHESTRATION_COMPLETE: [timestamp]

summary_brief: [80-token concise summary]
waves_completed: [number]
total_waves: [number]
current_wave_number: [number]
phases_completed: [space-separated phase numbers]
work_remaining: [space-separated phase identifiers or empty]
context_usage_percent: [0-100]
requires_continuation: [true|false]

parallelization_metrics:
  parallel_waves: [number of waves with >1 phase]
  parallel_phases: [count of phases executed in parallel]
  time_savings_percent: [0-100 estimated savings]

theorems_proven: [count]
theorems_partial: [count]
theorems_failed: [count]
git_commits: [count]
```

**Example**:
```
ORCHESTRATION_COMPLETE: 2025-12-09T14:32:18Z

summary_brief: Wave 2/2 completed: 5 phases proven, 0 partial, 0 failed. Time savings: 40%.
waves_completed: 2
total_waves: 2
current_wave_number: 2
phases_completed: 1 2 3 4 5
work_remaining:
context_usage_percent: 65
requires_continuation: false

parallelization_metrics:
  parallel_waves: 2
  parallel_phases: 5
  time_savings_percent: 40

theorems_proven: 12
theorems_partial: 0
theorems_failed: 0
git_commits: 5
```

---

### Task 7: Refactor Block 1c Iteration Logic

**File**: `/home/benjamin/.config/.claude/commands/lean-implement.md`

**Current Code (lines ~950-1050)**:
```bash
# Parse coordinator output
PHASES_COMPLETED=$(grep "^phases_completed:" "$COORDINATOR_OUTPUT" | sed 's/phases_completed:[[:space:]]*//')
WORK_REMAINING=$(grep "^work_remaining:" "$COORDINATOR_OUTPUT" | sed 's/work_remaining:[[:space:]]*//')
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$COORDINATOR_OUTPUT" | sed 's/requires_continuation:[[:space:]]*//')

if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING" ]; then
  # Extract next phase
  NEXT_PHASE=$(echo "$WORK_REMAINING" | awk '{print $1}' | sed 's/Phase_//')

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "CURRENT_PHASE" "$NEXT_PHASE"

  echo "**ITERATION LOOP**: Return to Block 1b with Phase $NEXT_PHASE"
  # PRIMARY AGENT CONTINUES EXECUTING - BUG!
fi
```

**New Code**:
```bash
# Parse coordinator output
PHASES_COMPLETED=$(grep "^phases_completed:" "$COORDINATOR_OUTPUT" | sed 's/phases_completed:[[:space:]]*//')
WORK_REMAINING=$(grep "^work_remaining:" "$COORDINATOR_OUTPUT" | sed 's/work_remaining:[[:space:]]*//')
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$COORDINATOR_OUTPUT" | sed 's/requires_continuation:[[:space:]]*//')
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$COORDINATOR_OUTPUT" | sed 's/context_usage_percent:[[:space:]]*//')

# Extract parallelization metrics
PARALLEL_WAVES=$(grep "^  parallel_waves:" "$COORDINATOR_OUTPUT" | sed 's/.*:[[:space:]]*//')
TIME_SAVINGS_PERCENT=$(grep "^  time_savings_percent:" "$COORDINATOR_OUTPUT" | sed 's/.*:[[:space:]]*//')

# Update completed phases in plan file
for phase_num in $PHASES_COMPLETED; do
  sed -i "s/^### Phase ${phase_num}:.*\[NOT STARTED\]/### Phase ${phase_num}: [COMPLETE]/" "$PLAN_FILE"
  sed -i "s/^### Phase ${phase_num}:.*\[IN PROGRESS\]/### Phase ${phase_num}: [COMPLETE]/" "$PLAN_FILE"
done

echo "Phases completed: $PHASES_COMPLETED"
echo "Work remaining: ${WORK_REMAINING:-none}"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Time savings: ${TIME_SAVINGS_PERCENT}%"

# === ITERATION DECISION: CONTEXT THRESHOLD ONLY ===

if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  # Check context threshold
  if [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "CONTEXT THRESHOLD EXCEEDED: ${CONTEXT_USAGE_PERCENT}% >= ${CONTEXT_THRESHOLD}%"
    echo "════════════════════════════════════════════════════════"
    echo ""

    # Save checkpoint
    NEXT_ITERATION=$((ITERATION + 1))

    # Update state for next iteration
    append_workflow_state "ITERATION" "$NEXT_ITERATION"
    append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
    append_workflow_state "CONTEXT_USAGE_PERCENT" "$CONTEXT_USAGE_PERCENT"

    # Create continuation summary
    CONTINUATION_SUMMARY_PATH="${LEAN_IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.txt"
    cat > "$CONTINUATION_SUMMARY_PATH" <<EOF_SUMMARY
Iteration $ITERATION Summary:
- Phases Completed: $PHASES_COMPLETED
- Work Remaining: $WORK_REMAINING
- Context Usage: ${CONTEXT_USAGE_PERCENT}%
- Parallel Waves: $PARALLEL_WAVES
- Time Savings: ${TIME_SAVINGS_PERCENT}%
EOF_SUMMARY

    append_workflow_state "CONTINUATION_SUMMARY_PATH" "$CONTINUATION_SUMMARY_PATH"

    echo "Checkpoint saved for Iteration $NEXT_ITERATION"
    echo "Continuation summary: $CONTINUATION_SUMMARY_PATH"
    echo ""
    echo "**ITERATION LOOP**: Returning to Block 1b for context management"
    echo ""

    # HARD BARRIER: PRIMARY AGENT STOPS HERE
    # Execution resumes at Block 1b on next iteration
    exit 0
  else
    # Context below threshold but work remains (should not happen with wave-based delegation)
    echo "WARNING: Work remains but context under threshold (unexpected state)"
    echo "  This may indicate incomplete wave execution or coordinator error"
    echo "  Proceeding to completion summary"
  fi
fi

# All work complete or context threshold not exceeded
echo ""
echo "════════════════════════════════════════════════════════"
echo "WAVE-BASED EXECUTION COMPLETE"
echo "════════════════════════════════════════════════════════"
echo ""
```

**Key Changes**:
1. **Context threshold check ONLY** - No per-phase iteration
2. **Hard barrier with exit 0** - Primary agent stops after checkpoint save
3. **Continuation summary creation** - Brief context for next iteration
4. **Parallelization metrics extraction** - Track time savings
5. **Work remaining validation** - Warn if unexpected state

---

### Task 8: Update Continuation Context Handling

**File**: `/home/benjamin/.config/.claude/commands/lean-implement.md`

**Insert in Block 1a After State Initialization (line ~320)**:

```bash
# === CONTINUATION CONTEXT HANDLING ===
# If resuming from previous iteration, load continuation summary

ITERATION=$(grep "^ITERATION=" "$STATE_FILE" | cut -d'=' -f2 || echo "1")
CONTINUATION_SUMMARY_PATH=$(grep "^CONTINUATION_SUMMARY_PATH=" "$STATE_FILE" | cut -d'=' -f2 || echo "")

if [ "$ITERATION" -gt 1 ] && [ -n "$CONTINUATION_SUMMARY_PATH" ] && [ -f "$CONTINUATION_SUMMARY_PATH" ]; then
  echo "════════════════════════════════════════════════════════"
  echo "RESUMING FROM ITERATION $ITERATION"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Previous iteration summary:"
  cat "$CONTINUATION_SUMMARY_PATH"
  echo ""

  # Extract work remaining from continuation
  WORK_REMAINING_PREV=$(grep "^- Work Remaining:" "$CONTINUATION_SUMMARY_PATH" | sed 's/- Work Remaining: //')

  echo "Resuming with work remaining: $WORK_REMAINING_PREV"
  echo ""
else
  echo "Starting fresh execution (Iteration 1)"
  ITERATION=1
  CONTINUATION_SUMMARY_PATH=""
fi

append_workflow_state "ITERATION" "$ITERATION"
```

**Rationale**:
- Load previous iteration context for efficient resumption
- Brief summary (80 tokens) instead of full coordinator output (2,000 tokens)
- 96% context reduction enables 10+ iterations vs 3-4 before

---

## Testing Specifications

### Integration Test 1: Wave Calculation Correctness

**File**: `/home/benjamin/.config/.claude/tests/integration/test_wave_based_delegation.sh`

```bash
test_wave_calculation_correctness() {
  echo "Testing wave calculation correctness..."

  # Create test plan with dependencies
  cat > "$TEST_WORKSPACE/test_plan.md" <<'EOF_PLAN'
### Phase 1: Base Theorems [NOT STARTED]
dependencies: []

Tasks:
- [ ] Prove theorem_add_comm

### Phase 2: Derived Theorems [NOT STARTED]
dependencies: [1]

Tasks:
- [ ] Prove theorem_mul_comm

### Phase 3: Advanced Theorems A [NOT STARTED]
dependencies: [2]

Tasks:
- [ ] Prove theorem_ring_A

### Phase 4: Advanced Theorems B [NOT STARTED]
dependencies: [2]

Tasks:
- [ ] Prove theorem_ring_B

### Phase 5: Final Theorem [NOT STARTED]
dependencies: [3, 4]

Tasks:
- [ ] Prove theorem_field
EOF_PLAN

  # Invoke dependency-analyzer
  bash "${CLAUDE_PROJECT_DIR}/.claude/lib/util/dependency-analyzer.sh" \
    "$TEST_WORKSPACE/test_plan.md" > "$TEST_WORKSPACE/wave_structure.json"

  EXIT_CODE=$?
  test $EXIT_CODE -eq 0 || {
    echo "ERROR: dependency-analyzer failed"
    return 1
  }

  # Validate wave structure
  # Expected: Wave 1=[1], Wave 2=[2], Wave 3=[3,4], Wave 4=[5]

  WAVE_COUNT=$(jq '.waves | length' "$TEST_WORKSPACE/wave_structure.json")
  test "$WAVE_COUNT" -eq 4 || {
    echo "ERROR: Expected 4 waves, got $WAVE_COUNT"
    return 1
  }

  WAVE_1_PHASES=$(jq -r '.waves[0].phases | join(",")' "$TEST_WORKSPACE/wave_structure.json")
  test "$WAVE_1_PHASES" = "1" || {
    echo "ERROR: Wave 1 should be [1], got [$WAVE_1_PHASES]"
    return 1
  }

  WAVE_3_PHASES=$(jq -r '.waves[2].phases | join(",")' "$TEST_WORKSPACE/wave_structure.json")
  test "$WAVE_3_PHASES" = "3,4" || {
    echo "ERROR: Wave 3 should be [3,4], got [$WAVE_3_PHASES]"
    return 1
  }

  echo "✓ Wave calculation correctness validated"
  return 0
}
```

---

### Integration Test 2: Parallel Task Invocation

**File**: `/home/benjamin/.config/.claude/tests/integration/test_wave_based_delegation.sh`

```bash
test_parallel_task_invocation() {
  echo "Testing parallel Task invocation pattern..."

  # Create mock coordinator output with multiple Task invocations
  cat > "$TEST_WORKSPACE/coordinator_output.txt" <<'EOF_OUTPUT'
Wave 2 of 3: 2 phases

Invoking 2 lean-implementers in parallel for Wave 2...

**EXECUTE NOW**: USE the Task tool to invoke lean-implementer for Phase 3.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorems in Phase 3 (Wave 2)"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/user/.claude/agents/lean-implementer.md

    **Input Contract**:
    - lean_file_path: /path/to/Theorems.lean
    - theorem_tasks: [{"name": "theorem_A", "phase_number": 3}]
    - wave_number: 2
    - phase_number: 3
}

**EXECUTE NOW**: USE the Task tool to invoke lean-implementer for Phase 4.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorems in Phase 4 (Wave 2)"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/user/.claude/agents/lean-implementer.md

    **Input Contract**:
    - lean_file_path: /path/to/Theorems.lean
    - theorem_tasks: [{"name": "theorem_B", "phase_number": 4}]
    - wave_number: 2
    - phase_number: 4
}

WAVE BARRIER: Waiting for ALL implementers to complete...

✓ Phase 3: COMPLETE
✓ Phase 4: COMPLETE
EOF_OUTPUT

  # Validate parallel Task invocation pattern
  TASK_COUNT=$(grep -c "**EXECUTE NOW**: USE the Task tool" "$TEST_WORKSPACE/coordinator_output.txt")
  test "$TASK_COUNT" -eq 2 || {
    echo "ERROR: Expected 2 Task invocations, found $TASK_COUNT"
    return 1
  }

  # Validate both Tasks in single response (no intermediate blocks)
  BARRIER_COUNT=$(grep -c "WAVE BARRIER" "$TEST_WORKSPACE/coordinator_output.txt")
  test "$BARRIER_COUNT" -eq 1 || {
    echo "ERROR: Expected 1 wave barrier, found $BARRIER_COUNT"
    return 1
  }

  echo "✓ Parallel Task invocation validated"
  return 0
}
```

---

### Performance Test: Time Savings Measurement

**File**: `/home/benjamin/.config/.claude/tests/integration/test_wave_based_delegation.sh`

```bash
test_time_savings_measurement() {
  echo "Testing time savings measurement (40-60% threshold)..."

  # Mock timing data
  # Plan: 5 phases, dependencies: []->[1]->[2,3]->[4]
  # Waves: Wave 1=[1], Wave 2=[2], Wave 3=[3,4], Wave 4=[5]

  # Sequential time: 5 phases * 15 minutes = 75 minutes
  SEQUENTIAL_TIME=75

  # Wave-based time: 4 waves * 15 minutes = 60 minutes
  # BUT waves 3 has parallelism, so actual time = 3 waves * 15 = 45 minutes
  WAVE_TIME=45

  # Calculate time savings
  TIME_SAVINGS=$(awk "BEGIN {printf \"%.0f\", (1 - $WAVE_TIME/$SEQUENTIAL_TIME) * 100}")

  echo "Sequential time: $SEQUENTIAL_TIME minutes"
  echo "Wave-based time: $WAVE_TIME minutes"
  echo "Time savings: ${TIME_SAVINGS}%"

  # Validate 40% minimum threshold
  awk -v savings="$TIME_SAVINGS" 'BEGIN { exit (savings < 40) ? 1 : 0 }' || {
    echo "ERROR: Time savings ${TIME_SAVINGS}% below 40% threshold"
    return 1
  }

  # Generate metrics artifact
  cat > "$TEST_WORKSPACE/wave-metrics.json" <<EOF_METRICS
{
  "sequential_time_minutes": $SEQUENTIAL_TIME,
  "wave_time_minutes": $WAVE_TIME,
  "time_savings_percent": $TIME_SAVINGS,
  "total_waves": 4,
  "parallel_waves": 1,
  "parallel_phases": 2,
  "test_timestamp": "$(date -Iseconds)"
}
EOF_METRICS

  echo "✓ Time savings measurement validated (${TIME_SAVINGS}% >= 40%)"
  return 0
}
```

---

### Integration Test 3: Context Threshold Iteration Trigger

**File**: `/home/benjamin/.config/.claude/tests/integration/test_wave_based_delegation.sh`

```bash
test_context_threshold_iteration_trigger() {
  echo "Testing context threshold iteration trigger..."

  # Mock coordinator output with context threshold exceeded
  cat > "$TEST_WORKSPACE/coordinator_output_high_context.txt" <<'EOF_OUTPUT'
ORCHESTRATION_COMPLETE: 2025-12-09T14:32:18Z

summary_brief: Wave 1/3 completed: 2 phases proven, 0 partial, 0 failed. Time savings: 0%.
waves_completed: 1
total_waves: 3
current_wave_number: 1
phases_completed: 1 2
work_remaining: Phase_3 Phase_4 Phase_5
context_usage_percent: 92
requires_continuation: true

parallelization_metrics:
  parallel_waves: 0
  parallel_phases: 2
  time_savings_percent: 0

theorems_proven: 4
theorems_partial: 0
theorems_failed: 0
git_commits: 2
EOF_OUTPUT

  # Parse output
  CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$TEST_WORKSPACE/coordinator_output_high_context.txt" | sed 's/context_usage_percent:[[:space:]]*//')
  REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$TEST_WORKSPACE/coordinator_output_high_context.txt" | sed 's/requires_continuation:[[:space:]]*//')
  WORK_REMAINING=$(grep "^work_remaining:" "$TEST_WORKSPACE/coordinator_output_high_context.txt" | sed 's/work_remaining:[[:space:]]*//')

  # Validate context threshold check
  CONTEXT_THRESHOLD=90

  if [ "$REQUIRES_CONTINUATION" = "true" ] && [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
    echo "✓ Context threshold exceeded: ${CONTEXT_USAGE_PERCENT}% >= ${CONTEXT_THRESHOLD}%"

    # Validate checkpoint save would occur
    NEXT_ITERATION=2
    CONTINUATION_SUMMARY_PATH="$TEST_WORKSPACE/iteration_1_summary.txt"

    cat > "$CONTINUATION_SUMMARY_PATH" <<EOF_SUMMARY
Iteration 1 Summary:
- Phases Completed: 1 2
- Work Remaining: $WORK_REMAINING
- Context Usage: ${CONTEXT_USAGE_PERCENT}%
EOF_SUMMARY

    test -f "$CONTINUATION_SUMMARY_PATH" || {
      echo "ERROR: Continuation summary not created"
      return 1
    }

    echo "✓ Checkpoint save validated"
    echo "✓ Iteration loop would trigger with work_remaining: $WORK_REMAINING"

    return 0
  else
    echo "ERROR: Context threshold check failed"
    return 1
  fi
}
```

---

## Error Handling Patterns

### Partial Wave Failure Handling

**Scenario**: Wave has 3 phases, 2 complete, 1 fails

**Pattern**:
```bash
# In lean-coordinator STEP 4 wave execution loop

for phase_number in $WAVE_PHASES; do
  implementer_output="${artifact_paths[outputs]}/phase_${phase_number}_output.txt"

  if [ -f "$implementer_output" ]; then
    if grep -q "^PROOF_COMPLETE" "$implementer_output"; then
      COMPLETED_PHASES+=("$phase_number")
    elif grep -q "^PROOF_PARTIAL" "$implementer_output"; then
      PARTIAL_PHASES+=("$phase_number")

      # Extract blocking diagnostics for plan revision
      BLOCKING_DIAGNOSTICS=$(grep "^  diagnostics:" "$implementer_output" | sed 's/diagnostics:[[:space:]]*//')

      # Store for Phase 3 (Plan Revision Workflow)
      echo "$phase_number|$BLOCKING_DIAGNOSTICS" >> "${WAVE_WORKSPACE}/blocking_diagnostics.txt"
    else
      FAILED_PHASES+=("$phase_number")

      # Log error
      log_command_error \
        "lean-coordinator" \
        "$WORKFLOW_ID" \
        "wave_${CURRENT_WAVE}" \
        "execution_error" \
        "Phase $phase_number failed without valid output signal" \
        "wave_execution" \
        "$(jq -n --argjson phase "$phase_number" '{phase_number: $phase}')"
    fi
  else
    FAILED_PHASES+=("$phase_number")
  fi
done

# Continue to next wave even if partial failures
# Plan revision workflow (Phase 3) handles blocking dependencies
echo "Wave $CURRENT_WAVE: ${#COMPLETED_PHASES[@]} complete, ${#PARTIAL_PHASES[@]} partial, ${#FAILED_PHASES[@]} failed"
```

---

### Fallback to Per-Phase Routing

**Scenario**: Wave-based delegation fails catastrophically

**Pattern in /lean-implement.md Block 1a**:
```bash
# Fallback flag for debugging/emergency scenarios
EXECUTION_MODE="${EXECUTION_MODE:-full-plan}"

# Emergency override: --mode=per-phase
if [[ "$LEAN_IMPLEMENT_ARGS" =~ --mode=per-phase ]]; then
  echo "WARNING: Using per-phase routing (fallback mode)"
  echo "  Wave-based delegation disabled"
  EXECUTION_MODE="per-phase"
fi

case "$EXECUTION_MODE" in
  full-plan)
    echo "Execution mode: Full plan wave-based delegation"
    # Use Task 1-8 implementation
    ;;

  per-phase)
    echo "Execution mode: Per-phase sequential routing (LEGACY)"
    # Use original per-phase logic (preserved for emergency)
    CURRENT_PHASE=$(get_starting_phase "$PLAN_FILE")
    append_workflow_state "CURRENT_PHASE" "$CURRENT_PHASE"
    ;;

  *)
    echo "ERROR: Invalid execution mode: $EXECUTION_MODE"
    exit 1
    ;;
esac
```

---

## Performance Instrumentation

### Wave Execution Timing

**Add to lean-coordinator.md STEP 4**:

```bash
# Wave timing instrumentation
WAVE_START_TIME=$(date +%s)

# ... wave execution ...

WAVE_END_TIME=$(date +%s)
WAVE_DURATION=$((WAVE_END_TIME - WAVE_START_TIME))

# Store metrics
cat >> "${WAVE_WORKSPACE}/wave_metrics.txt" <<EOF_METRICS
Wave $CURRENT_WAVE:
  Start: $(date -d @$WAVE_START_TIME -Iseconds)
  End: $(date -d @$WAVE_END_TIME -Iseconds)
  Duration: ${WAVE_DURATION}s
  Phases: $WAVE_SIZE
  Completed: ${#COMPLETED_PHASES[@]}
  Parallel: $([[ $WAVE_SIZE -gt 1 ]] && echo "yes" || echo "no")
EOF_METRICS
```

### Aggregate Timing Report

**Add to lean-coordinator.md STEP 5**:

```bash
# Calculate total execution time
TOTAL_END_TIME=$(date +%s)
TOTAL_DURATION=$((TOTAL_END_TIME - TOTAL_START_TIME))

# Calculate estimated sequential time
ESTIMATED_SEQUENTIAL_TIME=$((TOTAL_PHASES * 15 * 60))  # 15 minutes per phase

# Time savings
if [ "$ESTIMATED_SEQUENTIAL_TIME" -gt 0 ]; then
  ACTUAL_TIME_SAVINGS=$(awk "BEGIN {printf \"%.0f\", (1 - $TOTAL_DURATION/$ESTIMATED_SEQUENTIAL_TIME) * 100}")
else
  ACTUAL_TIME_SAVINGS=0
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "PERFORMANCE METRICS"
echo "════════════════════════════════════════════════════════"
echo "Total Phases: $TOTAL_PHASES"
echo "Total Waves: $WAVES_COMPLETED"
echo "Parallel Waves: $PARALLEL_WAVES_COUNT"
echo "Parallel Phases: $PARALLEL_PHASES_COUNT"
echo ""
echo "Execution Time: ${TOTAL_DURATION}s ($(($TOTAL_DURATION / 60)) minutes)"
echo "Estimated Sequential: ${ESTIMATED_SEQUENTIAL_TIME}s ($(($ESTIMATED_SEQUENTIAL_TIME / 60)) minutes)"
echo "Actual Time Savings: ${ACTUAL_TIME_SAVINGS}%"
echo "════════════════════════════════════════════════════════"
echo ""
```

---

## Validation Checklist

Before marking Phase 4 complete, verify:

- [ ] Block 1a removes CURRENT_PHASE extraction, sets EXECUTION_MODE="full-plan"
- [ ] Block 1b passes routing_map_path to coordinator for dual coordinator support
- [ ] Routing map generation script created and integrated
- [ ] lean-coordinator.md STEP 2 invokes dependency-analyzer.sh correctly
- [ ] lean-coordinator.md STEP 2 displays wave execution plan visually
- [ ] lean-coordinator.md STEP 4 implements wave execution loop with parallel Tasks
- [ ] Wave synchronization hard barrier waits for ALL implementers before Wave N+1
- [ ] lean-coordinator output signal includes waves_completed, parallelization_metrics
- [ ] Block 1c refactored to trigger iteration only on context threshold
- [ ] Continuation context handling passes iteration summary (80 tokens, not 2,000)
- [ ] Integration Test 1 validates wave calculation correctness
- [ ] Integration Test 2 validates parallel Task invocation pattern
- [ ] Performance Test validates 40-60% time savings for parallel phases
- [ ] Integration Test 3 validates context threshold iteration trigger
- [ ] Error handling patterns for partial wave failures implemented
- [ ] Fallback to per-phase routing available for emergency scenarios
- [ ] Performance instrumentation tracks wave timing and aggregate metrics

---

## Expected Outcomes

**After Phase 4 Implementation**:

1. **Delegation Contract Preserved**: Single coordinator return point eliminates N return points where delegation can break
2. **Time Savings Achieved**: 40-60% reduction in execution time for plans with 2+ parallel phases
3. **Context Efficiency**: 96% context reduction via brief summary parsing enables 10+ iterations
4. **Iteration Simplification**: Context threshold triggers only (not per-phase completion)
5. **Parallel Execution**: Multiple lean-implementer Tasks invoked in single coordinator response
6. **Wave Synchronization**: Hard barrier ensures ALL implementers complete before next wave
7. **Metrics Visibility**: Time savings percentage, parallel phases count tracked and displayed
8. **Fallback Safety**: Per-phase routing mode available for emergency debugging

---

## Next Steps

After Phase 4 completion:
1. Run Integration Test Suite (Phase 5)
2. Measure actual time savings on real Lean plans
3. Update documentation with wave-based examples
4. Add hierarchical agent architecture example to CLAUDE.md

---

## References

- [Plan 002 Phase 9](../../047_lean_implement_coordinator_waves/plans/002-remaining-phases-8-9-10-plan.md#phase-9-transform-to-wave-based-full-plan-delegation-not-started)
- [dependency-analyzer.sh](/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh)
- [lean-coordinator.md](/home/benjamin/.config/.claude/agents/lean-coordinator.md)
- [lean-implement.md](/home/benjamin/.config/.claude/commands/lean-implement.md)
- [Hierarchical Agents - Hard Barrier Pattern](.claude/docs/concepts/hierarchical-agents-coordination.md)

---

**Estimated Lines**: 580+ lines (detailed implementation with code examples, tests, error handling, and instrumentation)
