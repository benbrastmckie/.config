# Research Report: Lean Command Parallel Subagent Orchestration Patterns

**Date**: 2025-12-03
**Research Type**: Architecture Analysis
**Complexity**: 3 (High)
**Topic**: Refactoring /lean command for parallel subagent orchestration with plan progress updates and persistence loops

---

## Executive Summary

This report analyzes the current single-agent /lean command architecture and documents patterns from /implement for parallel subagent orchestration, plan progress tracking, and persistence loops. The research reveals clear opportunities to apply the implementer-coordinator pattern to Lean theorem proving workflows, enabling parallel proof attempts and systematic progress tracking.

**Key Findings**:
1. Current /lean uses single lean-implementer agent with no parallelization
2. /implement demonstrates mature wave-based parallel execution pattern
3. checkbox-utils.sh provides comprehensive plan progress tracking functions
4. Persistence loop pattern enables large plan handling with context management
5. Lean workflow can parallelize at theorem-level (multiple theorems in parallel)

**Recommended Approach**: Introduce lean-coordinator agent using implementer-coordinator pattern with theorem-level task delegation to parallel lean-implementer instances.

---

## 1. Current /lean Command Architecture

### 1.1 Command Structure

**File**: `/home/benjamin/.config/.claude/commands/lean.md`

**Architecture**:
- **Block 1a**: Setup & Lean Project Detection (argument capture, validation, path setup)
- **Block 1b**: lean-implementer Invocation (HARD BARRIER - single Task invocation)
- **Block 1c**: Verification & Diagnostics (summary validation, metric parsing)
- **Block 2**: Completion & Summary (console output, cleanup)

**Key Characteristics**:
```yaml
Current Pattern:
  - Single lean-implementer agent invocation
  - No plan file support (Lean file paths only)
  - No parallel execution capability
  - Manual summary validation (find latest .md in summaries/)
  - No plan progress markers ([IN PROGRESS], [COMPLETE])
  - No persistence loop for large proof sessions
```

### 1.2 lean-implementer Agent Capabilities

**File**: `/home/benjamin/.config/.claude/agents/lean-implementer.md`

**Workflow**:
1. **STEP 1**: Identify Unproven Theorems (grep for `sorry` markers)
2. **STEP 2**: Extract Proof Goals (lean_goal MCP tool)
3. **STEP 3**: Search Applicable Theorems (lean_leansearch, lean_loogle, lean_local_search)
4. **STEP 4**: Generate Candidate Tactics (pattern-based generation)
5. **STEP 5**: Test Tactics (lean_multi_attempt parallel screening)
6. **STEP 6**: Apply Successful Tactics (Edit tool)
7. **STEP 7**: Verify Proof Completion (lean_build, lean_diagnostic_messages)
8. **STEP 8**: Create Proof Summary

**Limitations**:
- Sequential theorem processing (no parallel proof attempts across multiple theorems)
- No plan-based orchestration (operates on single Lean file only)
- No progress markers for individual theorems
- Context exhaustion handling not implemented

**MCP Tool Rate Limits**:
```yaml
Rate Limited Tools (3 requests/30s combined):
  - lean_leansearch (natural language search)
  - lean_loogle (type-based search)
  - lean_leanfinder (semantic Mathlib search)
  - lean_state_search (goal-based applicable theorem search)
  - lean_hammer_premise (premise search)

No Rate Limit:
  - lean_local_search (ripgrep wrapper, preferred)
  - lean_build, lean_diagnostic_messages
  - lean_goal, lean_multi_attempt
```

### 1.3 Current Invocation Pattern

**Block 1b Task Invocation** (lines 203-230):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Lean theorem proving for ${LEAN_FILE} with mandatory summary creation"
  prompt: "
    Input Contract:
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
    - max_attempts: ${MAX_ATTEMPTS}

    Execute proof development workflow for mode: ${MODE}

    Return: IMPLEMENTATION_COMPLETE: 1
    summary_path: /path/to/summary
    theorems_proven: [...]
    theorems_partial: [...]
    tactics_used: [...]
    mathlib_theorems: [...]
    diagnostics: []
  "
}
```

**Limitations**:
- No plan_path input (cannot work with structured implementation plans)
- No phase/theorem tracking infrastructure
- No work_remaining or context_exhausted signals
- No iteration or continuation_context parameters

---

## 2. Parallel Subagent Orchestration Patterns

### 2.1 Implementer-Coordinator Architecture

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Core Responsibilities**:
1. **Dependency Analysis**: Invoke dependency-analyzer to build execution structure
2. **Wave Orchestration**: Execute phases wave-by-wave with parallel executors
3. **Progress Monitoring**: Collect updates from all executors in real-time
4. **State Management**: Maintain implementation state across waves
5. **Failure Handling**: Detect failures, mark phases, continue independent work
6. **Result Aggregation**: Collect completion reports and metrics

### 2.2 Wave-Based Execution Pattern

**Workflow** (lines 248-447):

#### Step 1: Plan Structure Detection
```bash
# Detect structure level (0=inline, 1=phase files, 2=stage files)
plan_dir=$(dirname "$plan_path")/$(basename "$plan_path" .md)

if [ -d "$plan_dir" ]; then
  if ls "$plan_dir"/phase_*.md >/dev/null 2>&1; then
    if ls "$plan_dir"/phase_*/ >/dev/null 2>&1; then
      STRUCTURE_LEVEL=2  # Stage files exist
    else
      STRUCTURE_LEVEL=1  # Phase files only
    fi
  else
    STRUCTURE_LEVEL=0  # Inline plan
  fi
else
  STRUCTURE_LEVEL=0  # Inline plan
fi
```

#### Step 2: Dependency Analysis
```bash
# Invoke dependency-analyzer utility
bash /path/to/dependency-analyzer.sh "$plan_path" > dependency_analysis.json

# Parse results
# - Extract dependency graph (nodes, edges)
# - Extract wave structure (wave_number, phases per wave)
# - Extract parallelization metrics (time savings estimate)
```

**dependency-analyzer.sh Output Structure**:
```json
{
  "dependency_graph": {
    "nodes": ["phase_1", "phase_2", "phase_3"],
    "edges": [
      {"from": "phase_1", "to": "phase_2"},
      {"from": "phase_1", "to": "phase_3"}
    ]
  },
  "waves": [
    {"wave_number": 1, "phases": ["phase_1"]},
    {"wave_number": 2, "phases": ["phase_2", "phase_3"]}
  ],
  "metrics": {
    "total_phases": 3,
    "parallel_phases": 2,
    "sequential_time": 15,
    "parallel_time": 9,
    "time_savings_percent": 40
  }
}
```

#### Step 3: Parallel Executor Invocation

**CRITICAL PATTERN**: Multiple Task invocations in single response (lines 264-330):

```markdown
I'm now invoking implementation-executor for Phase 2 and Phase 3 in parallel (Wave 2).

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 2 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /path/to/agents/implementation-executor.md

    You are executing Phase 2: Backend Implementation

    Input:
    - phase_file_path: /path/to/phase_2_backend.md
    - topic_path: /path/to/specs/027_auth
    - artifact_paths: {...}
    - wave_number: 2
    - phase_number: 2
    - continuation_context: $CONTINUATION_CONTEXT

    Execute all tasks in this phase, update plan file with progress,
    run tests, create git commit, report completion.

    Return structured PHASE_COMPLETE report with:
    - status, tasks_completed, tests_passing, commit_hash
    - context_exhausted: true|false
    - work_remaining: 0 or list of incomplete tasks
    - summary_path: path if summary generated
}

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 implementation"
  prompt: |
    [Similar structure for Phase 3]
}
```

**Key Pattern**: Back-to-back Task invocations without bash blocks between them triggers parallel execution.

#### Step 4: Progress Monitoring and Wave Synchronization

**Collection Pattern** (lines 332-396):
```yaml
After invoking all executors in wave:
  1. Collect Completion Reports from each executor
  2. Parse Results for each phase:
     - status: "completed" | "failed"
     - tasks_completed: N
     - tests_passing: true | false
     - commit_hash: "abc123"
     - checkpoint_path: "/path" (if created)
     - phase_marker_updated: true | false
  3. Validate Phase Markers (Optional - Block 1d recovery handles)
  4. Update Wave State
  5. Display Progress to user

Wave Synchronization:
  - Wait for ALL executors in wave to complete before proceeding
  - All executors MUST report completion (success or failure)
  - Aggregate results from all executors
  - Proceed to next wave only after synchronization
```

### 2.3 Parallelization Metrics

**Time Savings Calculation** (lines 450-454):
```python
sequential_time = sum(phase_durations)
parallel_time = sum(wave_durations)  # Max phase time per wave
time_savings = (sequential_time - parallel_time) / sequential_time * 100
```

**Example Wave Structures** (lines 630-657):

**Highly Parallel Plan** (40% time savings):
```
Wave 1: [Phase 1]
Wave 2: [Phase 2, Phase 3, Phase 4] (PARALLEL)
Wave 3: [Phase 5]

Time: 3 + 3 + 3 = 9 hours
Sequential: 3 + 3 + 3 + 3 + 3 = 15 hours
Savings: 40%
```

---

## 3. Plan Progress Update Mechanisms

### 3.1 checkbox-utils.sh Function Library

**File**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`

**Core Functions** (lines 8-21):

#### Phase Status Markers
```bash
# Add [IN PROGRESS] marker to phase heading
add_in_progress_marker <plan_path> <phase_num>

# Add [COMPLETE] marker to phase heading
add_complete_marker <plan_path> <phase_num>

# Add [NOT STARTED] markers to legacy plans
add_not_started_markers <plan_path>

# Remove any status marker from phase heading
remove_status_marker <plan_path> <phase_num>
```

#### Checkbox State Management
```bash
# Update a single checkbox with fuzzy matching
update_checkbox <file> <task_pattern> <new_state>

# Propagate checkbox update across hierarchy
propagate_checkbox_update <plan_path> <phase_num> <task_pattern> <new_state>

# Verify checkbox consistency across hierarchy
verify_checkbox_consistency <plan_path> <phase_num>
```

#### Phase Completion
```bash
# Mark all checkboxes in a phase as complete
mark_phase_complete <plan_path> <phase_num>

# Verify that a phase is fully complete
verify_phase_complete <plan_path> <phase_num>

# Check if all phases in a plan are marked complete
check_all_phases_complete <plan_path>
```

#### Plan Metadata
```bash
# Update plan metadata status field
update_plan_status <plan_path> <status>
# status: "NOT STARTED", "IN PROGRESS", "COMPLETE", "BLOCKED"
```

### 3.2 Phase Heading Status Markers

**Pattern** (lines 409-508):

**Status Transitions**:
```markdown
### Phase 1: Setup [NOT STARTED]
↓
### Phase 1: Setup [IN PROGRESS]
↓
### Phase 1: Setup [COMPLETE]
```

**Implementation - add_complete_marker** (lines 471-508):
```bash
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  # Validate phase completion before marking
  if ! verify_phase_complete "$plan_path" "$phase_num"; then
    error "Cannot mark Phase $phase_num complete - incomplete tasks remain"
    return 1
  fi

  # Remove any existing status marker first
  remove_status_marker "$plan_path" "$phase_num"

  # Add [COMPLETE] marker to phase heading
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^##+ Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase && !/\[COMPLETE\]/) {
        sub(/$/, " [COMPLETE]")
      }
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  mv "$temp_file" "$plan_path"
  return 0
}
```

**Key Features**:
- Validates all tasks complete before marking (verify_phase_complete)
- Idempotent (removes existing marker first)
- Works with both h2 (`## Phase`) and h3 (`### Phase`) headings
- Atomic file update (temp file + mv pattern)

### 3.3 Checkbox Hierarchy Propagation

**Progressive Plan Structure Support** (lines 84-137):

```bash
propagate_checkbox_update() {
  local plan_path="$1"
  local phase_num="$2"
  local task_pattern="$3"
  local new_state="$4"

  # Detect structure level (0/1/2)
  local structure_level=$(detect_structure_level "$plan_path")

  # Get plan directory if expanded
  local plan_dir=$(get_plan_directory "$plan_path")

  if [[ -z "$plan_dir" ]]; then
    # Level 0: Single file, update main plan only
    update_checkbox "$plan_path" "$task_pattern" "$new_state"
    return 0
  fi

  # Get main plan file
  local plan_name=$(basename "$plan_dir")
  local main_plan="$(dirname "$plan_dir")/$plan_name.md"

  # Get phase file if expanded (Level 1/2)
  local phase_file=$(get_phase_file "$plan_path" "$phase_num")

  if [[ -n "$phase_file" ]]; then
    # Update phase file
    update_checkbox "$phase_file" "$task_pattern" "$new_state"
  fi

  # Update main plan
  update_checkbox "$main_plan" "$task_pattern" "$new_state"

  return 0
}
```

**Hierarchy Levels**:
- **Level 0**: Single plan file (all phases inline)
- **Level 1**: Phase files (`plans/plan_name/phase_N.md`)
- **Level 2**: Stage files (`plans/plan_name/phase_N/stage_M.md`)

### 3.4 Integration Pattern in /implement

**Block 1a Setup** (lines 318-348):
```bash
# Source checkbox-utils
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh"

# Check for legacy plan and add [NOT STARTED] markers
if ! grep -qE "^### Phase [0-9]+:.*\[(NOT STARTED|IN PROGRESS|COMPLETE)\]" "$PLAN_FILE"; then
  echo "Legacy plan detected, adding [NOT STARTED] markers..."
  add_not_started_markers "$PLAN_FILE"
fi

# Mark the starting phase as [IN PROGRESS]
if add_in_progress_marker "$PLAN_FILE" "$STARTING_PHASE"; then
  echo "Marked Phase $STARTING_PHASE as [IN PROGRESS]"
fi

# Update plan metadata status to IN PROGRESS
if update_plan_status "$PLAN_FILE" "IN PROGRESS"; then
  echo "Plan metadata status updated to [IN PROGRESS]"
fi
```

**Block 1b Task Prompt** (lines 539-542):
```markdown
Progress Tracking Instructions:
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before starting each phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
- After completing each phase: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
```

**Block 1d Phase Marker Recovery** (lines 1044-1257):
```bash
# Count phases with [COMPLETE] marker
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE")
PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE")

if [ "$PHASES_WITH_MARKER" -ne "$TOTAL_PHASES" ]; then
  echo "⚠ Detecting phases missing [COMPLETE] marker..."

  # Recovery: Find phases with all checkboxes complete
  for phase_num in $(seq 1 "$TOTAL_PHASES"); do
    if grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
      continue  # Already marked
    fi

    # Check if all tasks complete
    if verify_phase_complete "$PLAN_FILE" "$phase_num"; then
      echo "Recovering Phase $phase_num..."

      # Mark all tasks complete (idempotent)
      mark_phase_complete "$PLAN_FILE" "$phase_num"

      # Add [COMPLETE] marker
      add_complete_marker "$PLAN_FILE" "$phase_num"
    fi
  done
fi
```

**Purpose**: Recovers missing [COMPLETE] markers if executors failed to update them. Ensures plan file reflects actual completion state.

---

## 4. Persistence Loop Pattern

### 4.1 Multi-Iteration Execution Architecture

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Block 1a: Iteration Variables** (lines 452-476):
```bash
# === ITERATION LOOP VARIABLES ===
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""
STUCK_COUNT=0

MAX_ITERATIONS=5  # Default, configurable via --max-iterations
CONTEXT_THRESHOLD=90  # Default 90%, configurable

# Persist iteration variables for cross-block accessibility
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"
append_workflow_state "CONTEXT_THRESHOLD" "$CONTEXT_THRESHOLD"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
append_workflow_state "LAST_WORK_REMAINING" "$LAST_WORK_REMAINING"
append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"

# Create implement workspace directory for iteration summaries
IMPLEMENT_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/implement_${WORKFLOW_ID}"
mkdir -p "$IMPLEMENT_WORKSPACE"
```

**Purpose**: Enables multi-iteration execution for large plans that exceed single bash block context window.

### 4.2 Context Estimation

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Context Estimation Function** (lines 143-189):
```bash
estimate_context_usage() {
  local completed_phases="$1"
  local remaining_phases="$2"
  local has_continuation="$3"

  # Defensive: Validate inputs are numeric
  if ! [[ "$completed_phases" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Invalid completed_phases, defaulting to 0" >&2
    completed_phases=0
  fi
  if ! [[ "$remaining_phases" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Invalid remaining_phases, defaulting to 1" >&2
    remaining_phases=1
  fi

  # Context cost model
  local base=20000  # Plan file + standards + system prompt
  local completed_cost=$((completed_phases * 15000))
  local remaining_cost=$((remaining_phases * 12000))
  local continuation_cost=0

  if [ "$has_continuation" = "true" ]; then
    continuation_cost=5000
  fi

  local total=$((base + completed_cost + remaining_cost + continuation_cost))

  # Sanity check (10k-300k tokens)
  if [ "$total" -lt 10000 ] || [ "$total" -gt 300000 ]; then
    echo "WARNING: Context estimate out of range, using conservative 50%" >&2
    echo 100000  # 50% of 200k context window
  else
    echo "$total"
  fi
}
```

**Defensive Error Handling**:
- Validates numeric inputs (defaults: 0 for completed, 1 for remaining)
- Wraps arithmetic in error handlers with conservative fallbacks
- Sanity checks final estimate (valid range: 10k-300k tokens)
- On failure: Returns 100,000 tokens (conservative 50% of 200k window)

### 4.3 Checkpoint Saving

**Checkpoint Format** (lines 196-230):
```bash
save_resumption_checkpoint() {
  local halt_reason="$1"
  local checkpoint_dir="${artifact_paths[checkpoints]}"
  mkdir -p "$checkpoint_dir"

  local checkpoint_file="${checkpoint_dir}/build_${workflow_id}_iteration_${iteration}.json"

  jq -n \
    --arg version "2.1" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg plan_path "$plan_path" \
    --arg topic_path "$topic_path" \
    --argjson iteration "$iteration" \
    --argjson max_iterations "$max_iterations" \
    --arg continuation_context "${continuation_context:-}" \
    --arg work_remaining "$work_remaining" \
    --argjson context_estimate "$context_estimate" \
    --arg halt_reason "$halt_reason" \
    '{
      version: $version,
      timestamp: $timestamp,
      plan_path: $plan_path,
      topic_path: $topic_path,
      iteration: $iteration,
      max_iterations: $max_iterations,
      continuation_context: $continuation_context,
      work_remaining: $work_remaining,
      context_estimate: $context_estimate,
      halt_reason: $halt_reason
    }' > "$checkpoint_file"

  echo "$checkpoint_file"
}
```

**Schema Version**: 2.1 (includes iteration fields)

**Checkpoint Fields**:
- `plan_path`: Absolute path to top-level plan file
- `topic_path`: Topic directory for artifact organization
- `iteration`: Current iteration number (1-indexed)
- `max_iterations`: Maximum iterations allowed
- `continuation_context`: Path to previous iteration summary
- `work_remaining`: Space-separated list of incomplete phases
- `context_estimate`: Estimated context usage in tokens
- `halt_reason`: Reason for checkpoint (e.g., "context_threshold", "stuck")

### 4.4 Stuck Detection

**Pattern** (lines 233-240):
```bash
# Track work_remaining across iterations
# If work_remaining unchanged for 2 consecutive iterations, set stuck_detected: true

if [ "$WORK_REMAINING" = "$LAST_WORK_REMAINING" ]; then
  STUCK_COUNT=$((STUCK_COUNT + 1))
  if [ "$STUCK_COUNT" -ge 2 ]; then
    STUCK_DETECTED="true"
  fi
fi
```

**Purpose**: Detects when implementation is not making progress (same work_remaining across multiple iterations). Parent workflow decides whether to continue or halt.

### 4.5 Iteration Loop Decision

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Block 1c Verification** (lines 784-896):
```bash
# === CHECK IMPLEMENTER-COORDINATOR OUTPUT ===
WORK_REMAINING="${AGENT_WORK_REMAINING:-}"
CONTEXT_EXHAUSTED="${AGENT_CONTEXT_EXHAUSTED:-false}"
CONTEXT_USAGE_PERCENT="${AGENT_CONTEXT_USAGE_PERCENT:-0}"
REQUIRES_CONTINUATION="${AGENT_REQUIRES_CONTINUATION:-false}"
STUCK_DETECTED="${AGENT_STUCK_DETECTED:-false}"

# === COMPLETION CHECK ===
if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  echo "Coordinator reports continuation required"

  # Prepare for next iteration
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.md"

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
  append_workflow_state "IMPLEMENTATION_STATUS" "continuing"

  # Save current summary
  if [ -n "$SUMMARY_PATH" ] && [ -f "$SUMMARY_PATH" ]; then
    cp "$SUMMARY_PATH" "$CONTINUATION_CONTEXT"
  fi
else
  # No continuation required - implementation complete or halted
  if [ -z "$WORK_REMAINING" ] || [ "$WORK_REMAINING" = "0" ]; then
    echo "Implementation complete - all phases done"
    append_workflow_state "IMPLEMENTATION_STATUS" "complete"
  elif [ "$STUCK_DETECTED" = "true" ]; then
    echo "Implementation halted - stuck detected"
    append_workflow_state "IMPLEMENTATION_STATUS" "stuck"
  else
    echo "Implementation halted - max iterations reached"
    append_workflow_state "IMPLEMENTATION_STATUS" "max_iterations"
  fi
fi
```

**Iteration Decision Flow**:
```
IMPLEMENTATION_STATUS = "continuing"
  ↓
Loop back to Block 1b (re-invoke coordinator with updated ITERATION)
  ↓
Load state, validate ITERATION, check max_iterations
  ↓
Task invocation with continuation_context and work_remaining
  ↓
Block 1c verification (check requires_continuation again)

IMPLEMENTATION_STATUS = "complete" | "stuck" | "max_iterations"
  ↓
Proceed to Block 1d (phase marker recovery)
```

### 4.6 Regaining Control After Subagent Return

**Pattern**: Bash blocks enforce hard barriers between Task invocations.

**Block 1b → Block 1c Flow**:
1. **Block 1b**: Task invocation (agent executes, returns signal)
2. **Command regains control**: Block 1c bash block starts
3. **Block 1c**: Validation and iteration check
4. **Decision**: If requires_continuation, bash block prepares state
5. **Iteration Decision Section**: Load state, validate, re-invoke Task
6. **Loop**: Back to Block 1b (new Task invocation with updated params)

**Key Mechanism**: State persistence across bash blocks (`append_workflow_state()`, `load_workflow_state()`) enables iteration loop without losing context.

---

## 5. State Machine Integration

### 5.1 workflow-state-machine.sh Architecture

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Core States** (lines 46-54):
```bash
readonly STATE_INITIALIZE="initialize"       # Phase 0: Setup
readonly STATE_RESEARCH="research"           # Phase 1: Research topic
readonly STATE_PLAN="plan"                   # Phase 2: Create plan
readonly STATE_IMPLEMENT="implement"         # Phase 3: Execute implementation
readonly STATE_TEST="test"                   # Phase 4: Run test suite
readonly STATE_DEBUG="debug"                 # Phase 5: Debug failures
readonly STATE_DOCUMENT="document"           # Phase 6: Update documentation
readonly STATE_COMPLETE="complete"           # Phase 7: Finalization
```

**State Transition Table** (lines 61-70):
```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research,implement"
  [research]="plan,complete"
  [plan]="implement,complete,debug"
  [implement]="test,complete"
  [test]="debug,document,complete"
  [debug]="test,document,complete"
  [document]="complete"
  [complete]=""  # Terminal state
)
```

### 5.2 State Persistence Pattern

**COMPLETED_STATES Array** (lines 82, 150-262):
```bash
# Array of completed states (state history)
declare -ga COMPLETED_STATES=()

# Save to state file using indexed variables pattern
save_completed_states_to_state() {
  # Store count first
  append_workflow_state "COMPLETED_STATES_COUNT" "${#COMPLETED_STATES[@]}"

  # Store each state with indexed key
  for i in "${!COMPLETED_STATES[@]}"; do
    append_workflow_state "COMPLETED_STATE_${i}" "${COMPLETED_STATES[$i]}"
  done
}

# Load from state file
load_completed_states_from_state() {
  COMPLETED_STATES=()

  if [ -z "${COMPLETED_STATES_COUNT:-}" ]; then
    return 0  # No completed states yet
  fi

  # Reconstruct array from indexed variables
  for i in $(seq 0 $((COMPLETED_STATES_COUNT - 1))); do
    local var_name="COMPLETED_STATE_${i}"
    local value="${!var_name:-}"
    if [ -n "$value" ]; then
      COMPLETED_STATES+=("$value")
    fi
  done
}
```

**Purpose**: Persists completed workflow states across bash block boundaries. Enables state history tracking and validation.

### 5.3 State Transitions in /implement

**Block 1a** (lines 349-434):
```bash
# Initialize state machine
WORKFLOW_TYPE="implement-only"
TERMINAL_STATE="$STATE_IMPLEMENT"
COMMAND_NAME="implement"

WORKFLOW_ID="implement_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]"

# Transition to IMPLEMENT
sm_transition "$STATE_IMPLEMENT" "plan loaded, starting implementation"
```

**Block 2** (lines 1354-1370):
```bash
# Complete workflow
sm_transition "$STATE_COMPLETE" "implementation complete (no testing)"

# Persist state transitions
save_completed_states_to_state
```

**Key Features**:
- Atomic two-phase commit (pre + post checkpoints)
- Idempotent transitions (same-state transitions succeed immediately)
- State history tracking (COMPLETED_STATES array)
- Workflow scope integration (maps scope to terminal state)

---

## 6. Lean-Specific Considerations

### 6.1 Theorem-Level vs File-Level Parallelization

**Theorem-Level Parallelization** (Recommended):
```yaml
Approach:
  - Parse Lean file for all sorry markers
  - Extract theorem names and line numbers
  - Create "theorem tasks" analogous to phase tasks
  - Invoke multiple lean-implementer instances in parallel
  - Each instance handles one or more theorems

Advantages:
  - Rate limit distribution (3 requests/30s shared across agents)
  - Independent theorem proving (no dependencies between theorems)
  - Graceful failure handling (one theorem failure doesn't block others)
  - Progress tracking per theorem

Limitations:
  - MCP rate limits still apply (lean_leansearch, lean_loogle)
  - Prefer lean_local_search (no rate limit)
  - Coordinate search tool usage across agents
```

**File-Level Parallelization** (Alternative):
```yaml
Approach:
  - Lean project with multiple files
  - Parse lakefile for module dependencies
  - Invoke lean-implementer per file in parallel waves

Advantages:
  - True parallelization (separate files have no MCP conflicts)
  - lakefile dependency graph available

Limitations:
  - Less granular progress tracking
  - File dependencies may limit parallelization
```

**Recommendation**: Start with theorem-level parallelization within a single Lean file. This maps cleanly to the phase-based pattern used in /implement.

### 6.2 Plan Structure for Lean Workflows

**Proposed Plan Format**:
```markdown
# Lean Proof Implementation Plan

## Metadata
- **Date**: 2025-12-03
- **Feature**: Formalize TM modal axioms
- **Status**: [NOT STARTED]
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/user/.config/CLAUDE.md
- **Research Reports**: none

## Implementation Phases

### Phase 1: Prove K Axiom [NOT STARTED]

**Theorem**: `K_axiom`
**Location**: `ProofChecker/TM.lean:42`
**Goal**: `⊢ □(P → Q) → (□P → □Q)`

**Dependencies**: depends_on: []

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for modal logic theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build

### Phase 2: Prove Necessitation Rule [NOT STARTED]

**Theorem**: `necessitation`
**Location**: `ProofChecker/TM.lean:57`
**Goal**: `⊢ P → □P`

**Dependencies**: depends_on: [Phase 1]

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search for necessitation proofs in Mathlib
- [ ] Generate tactics using K_axiom result
- [ ] Test and apply tactics
- [ ] Verify compilation

### Phase 3: Prove T Axiom [NOT STARTED]

**Theorem**: `T_axiom`
**Location**: `ProofChecker/TM.lean:72`
**Goal**: `⊢ □P → P`

**Dependencies**: depends_on: []

**Tasks**:
- [ ] Extract proof goal
- [ ] Search Mathlib for reflexivity theorems
- [ ] Generate tactics
- [ ] Test and apply
- [ ] Verify compilation
```

**Key Features**:
- Phase = Theorem (1:1 mapping)
- Dependency syntax supports wave-based execution
- Tasks match lean-implementer workflow steps
- Progress markers ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])

### 6.3 MCP Tool Rate Limit Coordination

**Challenge**: External search tools share 3 requests/30s combined limit.

**Coordination Strategies**:

#### Strategy 1: Priority Queue (Simple)
```yaml
Pattern:
  - Coordinator tracks last_search_time globally
  - Agents check elapsed time before search tool invocation
  - If <10s since last search, use lean_local_search instead
  - Coordinate via shared state file or workspace directory

Implementation:
  - Coordinator creates rate_limit_state.txt
  - Agents write timestamp after each search tool call
  - Agents read before invoking search tools
```

#### Strategy 2: Agent-Level Rate Limit Awareness (Recommended)
```yaml
Pattern:
  - Pass rate_limit_budget to each agent in wave
  - Budget = 3 / num_agents_in_wave
  - Agent prioritizes lean_local_search (no limit)
  - Agent uses budget for critical theorems only

Example:
  Wave 2 has 3 agents
  Each agent gets 1 external search request
  Agents save external searches for difficult theorems
  Use lean_local_search for common patterns
```

#### Strategy 3: Sequential Fallback
```yaml
Pattern:
  - Coordinator invokes agents in waves
  - Within each wave, stagger agent start times by 10 seconds
  - Each agent has clean 10-second window for search tools

Implementation:
  - Wave 1: Agent A (0s), Agent B (10s), Agent C (20s)
  - Each agent completes search phase before next starts
  - Maintains parallelism for tactic generation/application
```

**Recommendation**: Use Strategy 2 (budget allocation) combined with prioritizing `lean_local_search`. This respects rate limits while maximizing parallelism.

### 6.4 Proof Progress Tracking

**Theorem Status Markers**:
```markdown
### Phase 1: Prove K Axiom [IN PROGRESS]

**Proof Status**: PARTIAL (3/5 tactics applied)
**Sorry Remaining**: 2
**Tactics Used**: exact, rw, simp
**Diagnostics**: 1 warning (unused variable)
```

**Checkpoint Content**:
```json
{
  "theorem": "K_axiom",
  "location": "ProofChecker/TM.lean:42",
  "status": "partial",
  "tactics_applied": ["exact Modal.K_intro", "rw [Modal.necessity]"],
  "tactics_remaining": ["simp", "exact Modal.K_elim"],
  "sorry_count": 2,
  "diagnostics": ["warning: unused variable 'h1'"]
}
```

**Integration with checkbox-utils.sh**:
```bash
# Before starting theorem
add_in_progress_marker "$PLAN_FILE" "$THEOREM_PHASE_NUM"

# After completing theorem (no sorry markers)
mark_phase_complete "$PLAN_FILE" "$THEOREM_PHASE_NUM"
add_complete_marker "$PLAN_FILE" "$THEOREM_PHASE_NUM"

# Update plan metadata
update_plan_status "$PLAN_FILE" "IN PROGRESS"
```

### 6.5 Verification Status Integration

**lean_build and lean_diagnostic_messages**:
```bash
# After each theorem completion
build_output=$(uvx --from lean-lsp-mcp lean-build "$LEAN_FILE")
diagnostics=$(uvx --from lean-lsp-mcp lean-diagnostic-messages "$LEAN_FILE")

error_count=$(echo "$diagnostics" | jq '[.diagnostics[] | select(.severity == "error")] | length')

if [ "$error_count" -eq 0 ]; then
  echo "Theorem $theorem_name verified successfully"
  add_complete_marker "$PLAN_FILE" "$phase_num"
else
  echo "Theorem $theorem_name verification failed: $error_count errors"
  # Keep [IN PROGRESS] marker or add [BLOCKED] marker
fi
```

**Integration Point**: After each wave completes, run `lean_build` once to verify all completed theorems compile together. This validates that parallel proof attempts don't introduce conflicts.

---

## 7. Synthesis and Recommendations

### 7.1 Proposed lean-coordinator Agent

**Role**: Orchestrate parallel theorem proving using wave-based execution pattern.

**Workflow**:
1. **STEP 1**: Parse Plan File or Lean File
   - If plan file: Parse phases (1 theorem per phase)
   - If Lean file: Extract all `sorry` markers and create implicit plan
   - Build theorem list with locations and dependencies

2. **STEP 2**: Dependency Analysis
   - Extract dependency metadata from plan (if available)
   - Build dependency graph using dependency-analyzer pattern
   - Identify execution waves (groups of independent theorems)

3. **STEP 3**: Wave Execution Loop
   - For each wave:
     - Invoke multiple lean-implementer agents in parallel
     - Pass theorem tasks to each agent
     - Coordinate MCP rate limits (budget allocation)
     - Collect completion reports from all agents

4. **STEP 4**: Progress Monitoring
   - Update plan file with phase markers ([IN PROGRESS] → [COMPLETE])
   - Aggregate proof results (theorems_proven, theorems_partial)
   - Track tactics_used and mathlib_theorems across agents

5. **STEP 5**: Verification
   - Run lean_build once per wave to verify compilation
   - Check lean_diagnostic_messages for errors
   - Report verification status

6. **STEP 6**: Result Aggregation
   - Create consolidated proof summary
   - Report time savings from parallelization
   - List remaining work (theorems with sorry markers)

### 7.2 Updated /lean Command Architecture

**Proposed Block Structure**:

#### Block 1a: Setup & Plan Detection
```bash
# Current: Lean file path only
# Proposed: Support both Lean file path and plan file path

if [[ "$LEAN_FILE" =~ \.md$ ]]; then
  # Plan file provided
  EXECUTION_MODE="plan-based"
  PLAN_FILE="$LEAN_FILE"
  LEAN_FILE=$(extract_lean_file_from_plan "$PLAN_FILE")
else
  # Lean file provided
  EXECUTION_MODE="file-based"
  # Create implicit plan (no file, in-memory structure)
  PLAN_DATA=$(create_implicit_plan_from_lean "$LEAN_FILE")
fi
```

#### Block 1b: lean-coordinator Invocation
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Orchestrate parallel theorem proving for ${LEAN_FILE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE}
    - plan_path: ${PLAN_FILE:-null}
    - execution_mode: ${EXECUTION_MODE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
    - max_attempts: ${MAX_ATTEMPTS}
    - mode: ${MODE}
    - iteration: ${ITERATION}
    - max_iterations: ${MAX_ITERATIONS}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}

    Execute wave-based parallel theorem proving workflow.

    Return: PROOF_COMPLETE: {THEOREM_COUNT}
    summary_path: /path/to/summary
    theorems_proven: [...]
    theorems_partial: [...]
    tactics_used: [...]
    mathlib_theorems: [...]
    diagnostics: []
    work_remaining: theorem_1 theorem_2 ...
    context_exhausted: true|false
    requires_continuation: true|false
  "
}
```

#### Block 1c: Verification & Iteration Check
```bash
# Similar to /implement Block 1c
# - Verify summary exists (hard barrier)
# - Parse coordinator output
# - Check work_remaining
# - Determine if iteration needed
# - Prepare continuation_context if required

if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  # Prepare next iteration
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${LEAN_WORKSPACE}/iteration_${ITERATION}_summary.md"
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"

  # Loop back to Block 1b (load state and re-invoke coordinator)
fi
```

#### Block 1d: Phase Marker Recovery (New)
```bash
# Similar to /implement Block 1d
# - Validate theorem phase markers
# - Recover missing [COMPLETE] markers
# - Verify checkbox consistency
# - Update plan metadata status
```

#### Block 2: Completion & Summary
```bash
# Similar to current Block 2
# - Display completion summary
# - Report parallelization metrics (time savings)
# - Emit PROOF_COMPLETE signal
# - Cleanup
```

### 7.3 lean-implementer Modifications

**Current**: Operates on entire Lean file (all sorry markers).

**Proposed**: Operate on specific theorem tasks assigned by coordinator.

**New Input Contract**:
```yaml
Input:
  - lean_file_path: /path/to/file.lean
  - theorem_tasks: [
      {
        theorem_name: "K_axiom",
        line_number: 42,
        phase_number: 1,
        dependencies: []
      },
      {
        theorem_name: "T_axiom",
        line_number: 72,
        phase_number: 3,
        dependencies: []
      }
    ]
  - plan_path: /path/to/plan.md (optional)
  - topic_path: /path/to/topic
  - artifact_paths: {...}
  - max_attempts: 3
  - rate_limit_budget: 1  # Number of external search requests allowed
```

**Modified Workflow**:
1. **STEP 1**: Process assigned theorem_tasks (not all sorry markers)
2. **STEP 3**: Respect rate_limit_budget (prioritize lean_local_search)
3. **STEP 6**: Update plan file with progress (if plan_path provided)
4. **STEP 8**: Create per-wave summary (not full-session summary)

**Return Signal**:
```yaml
THEOREM_BATCH_COMPLETE:
  theorems_completed: ["K_axiom", "T_axiom"]
  theorems_partial: []
  tactics_used: ["exact", "rw", "simp"]
  mathlib_theorems: ["Modal.K_intro", "Modal.necessity"]
  diagnostics: []
  context_exhausted: false
  work_remaining: 0
```

### 7.4 Migration Strategy

**Phase 1: Basic Plan Support**
- Add plan file detection to /lean Block 1a
- Modify lean-implementer to accept plan_path (optional)
- Add progress marker updates (add_in_progress_marker, add_complete_marker)
- No parallelization yet (single lean-implementer invocation)

**Phase 2: Introduce lean-coordinator**
- Create lean-coordinator agent (based on implementer-coordinator)
- Implement dependency analysis for Lean plans
- Add wave-based execution (sequential waves, parallel within wave)
- Integrate rate limit coordination

**Phase 3: Persistence Loop**
- Add iteration variables to /lean Block 1a
- Implement context estimation for Lean workflows
- Add checkpoint saving/loading
- Implement stuck detection

**Phase 4: Phase Marker Recovery**
- Add Block 1d to /lean command
- Integrate checkbox verification
- Ensure plan file reflects actual proof completion state

### 7.5 Testing Plan

**Unit Tests**:
- Theorem extraction from Lean files
- Dependency graph parsing from Lean plans
- Wave structure generation
- Rate limit budget allocation

**Integration Tests**:
- Single theorem proof (baseline)
- Multi-theorem proof with dependencies (sequential waves)
- Multi-theorem proof without dependencies (parallel wave)
- Large proof session (10+ theorems, persistence loop)

**MCP Rate Limit Tests**:
- Multiple agents respecting 3 requests/30s limit
- Graceful degradation to lean_local_search
- Rate limit backoff and retry

**Progress Tracking Tests**:
- Phase marker updates ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])
- Checkbox state propagation
- Phase marker recovery after agent failure

### 7.6 Performance Estimates

**Baseline** (Current /lean):
```yaml
10 theorems, sequential
Average 15 minutes per theorem
Total time: 150 minutes (2.5 hours)
```

**With Parallelization** (Proposed lean-coordinator):
```yaml
10 theorems, 2 waves (5 theorems per wave)
Wave 1: 5 theorems in parallel (15 minutes - longest theorem)
Wave 2: 5 theorems in parallel (15 minutes - longest theorem)
Total time: 30 minutes
Time savings: 80%

Constraints:
- MCP rate limit (3 requests/30s)
- Each agent gets 3/5 = 0.6 external searches
- Must prioritize lean_local_search
- Actual savings may be 60-70% due to coordination overhead
```

**Realistic Estimate**:
```yaml
10 theorems with dependencies
Wave 1: 2 theorems (foundation)
Wave 2: 5 theorems (independent, depend on Wave 1)
Wave 3: 3 theorems (depend on Wave 2)

Sequential: 150 minutes
Parallel: 15 + 15 + 15 = 45 minutes
Time savings: 70%
```

---

## 8. Implementation Checklist

### 8.1 Core Infrastructure

- [ ] Create lean-coordinator agent
  - [ ] Plan structure detection
  - [ ] Dependency analysis integration
  - [ ] Wave-based execution loop
  - [ ] Progress monitoring and aggregation
  - [ ] Rate limit coordination
  - [ ] Result aggregation

- [ ] Modify lean-implementer agent
  - [ ] Accept theorem_tasks input (subset of theorems)
  - [ ] Add rate_limit_budget parameter
  - [ ] Add plan_path parameter (optional)
  - [ ] Update progress markers (if plan_path provided)
  - [ ] Return THEOREM_BATCH_COMPLETE signal

- [ ] Update /lean command
  - [ ] Add plan file detection (Block 1a)
  - [ ] Add lean-coordinator invocation (Block 1b)
  - [ ] Add iteration loop support (Block 1c)
  - [ ] Add phase marker recovery (Block 1d)
  - [ ] Update completion summary (Block 2)

### 8.2 Plan Format and Utilities

- [ ] Define Lean plan template
  - [ ] Theorem-based phase structure
  - [ ] Dependency syntax for theorems
  - [ ] Progress tracking sections

- [ ] Create plan generation utility
  - [ ] Parse Lean file for sorry markers
  - [ ] Extract theorem names and locations
  - [ ] Generate plan file from Lean file

- [ ] Integrate checkbox-utils.sh
  - [ ] Add progress marker updates in lean-implementer
  - [ ] Add phase marker recovery in /lean Block 1d

### 8.3 Iteration and Context Management

- [ ] Add iteration variables
  - [ ] ITERATION, MAX_ITERATIONS
  - [ ] CONTINUATION_CONTEXT, LAST_WORK_REMAINING
  - [ ] STUCK_COUNT

- [ ] Implement context estimation
  - [ ] Base cost (plan + standards)
  - [ ] Per-theorem cost model
  - [ ] Continuation context cost
  - [ ] Defensive validation

- [ ] Implement checkpoint saving
  - [ ] Schema v2.1 format
  - [ ] Save to checkpoints directory
  - [ ] Load on --resume flag

- [ ] Implement stuck detection
  - [ ] Track work_remaining across iterations
  - [ ] Set stuck_detected flag
  - [ ] Include in coordinator return signal

### 8.4 Testing and Validation

- [ ] Unit tests
  - [ ] Theorem extraction
  - [ ] Dependency parsing
  - [ ] Wave structure generation
  - [ ] Rate limit budget allocation

- [ ] Integration tests
  - [ ] Single theorem proof
  - [ ] Multi-theorem parallel proof
  - [ ] Large proof session (10+ theorems)
  - [ ] MCP rate limit compliance

- [ ] Progress tracking tests
  - [ ] Phase marker updates
  - [ ] Checkbox propagation
  - [ ] Phase marker recovery

---

## 9. References

### 9.1 Source Files Analyzed

1. `/home/benjamin/.config/.claude/commands/lean.md` - Current /lean command
2. `/home/benjamin/.config/.claude/agents/lean-implementer.md` - Lean theorem proving agent
3. `/home/benjamin/.config/.claude/commands/implement.md` - Implementation-only workflow command
4. `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Wave-based parallel coordinator
5. `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` - Plan progress utilities
6. `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` - State machine library
7. `/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh` - Dependency graph builder

### 9.2 Key Patterns Identified

1. **Wave-Based Execution**: Group independent phases (theorems) into waves, execute wave members in parallel
2. **Hard Barrier Pattern**: Bash block verification enforces artifact creation by subagents
3. **Progress Markers**: Status markers on phase headings ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])
4. **Checkbox Propagation**: Update checkboxes across plan hierarchy (Level 0/1/2)
5. **Persistence Loop**: Multi-iteration execution with context estimation and checkpoint saving
6. **Stuck Detection**: Track work_remaining across iterations to detect lack of progress
7. **State Machine Integration**: Formal state transitions with COMPLETED_STATES history
8. **Parallel Task Invocation**: Multiple Task calls in single message trigger parallel execution

### 9.3 Lean-Specific Insights

1. **MCP Rate Limits**: External search tools share 3 requests/30s combined limit
2. **lean_local_search**: No rate limit, should be prioritized for common patterns
3. **Theorem Independence**: Most theorems can be proven independently (enables parallelization)
4. **Verification Integration**: lean_build and lean_diagnostic_messages validate proof compilation
5. **Progress Tracking**: sorry count as completion metric, diagnostics for error detection

---

## 10. Conclusion

The research demonstrates clear architectural patterns from /implement that can be applied to /lean command refactoring. The implementer-coordinator pattern provides a proven approach for parallel subagent orchestration, while checkbox-utils.sh offers comprehensive plan progress tracking. The persistence loop pattern enables handling of large Lean proof sessions that exceed single-context windows.

**Key Success Factors**:
1. Theorem-level parallelization (1 theorem per phase, multiple phases per wave)
2. MCP rate limit coordination (budget allocation, prioritize lean_local_search)
3. Plan-based progress tracking (phase markers, checkbox updates, phase marker recovery)
4. Iteration loop support (context estimation, checkpoint saving, stuck detection)
5. Hard barrier enforcement (mandatory summary creation by subagents)

**Next Steps**:
1. Create implementation plan following Directory Protocols (`.claude/specs/028_lean_subagent_orchestration/plans/`)
2. Implement lean-coordinator agent (Phase 1)
3. Update /lean command with plan support (Phase 2)
4. Add iteration loop infrastructure (Phase 3)
5. Test with sample Lean projects (Phase 4)

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/028_lean_subagent_orchestration/reports/001-lean-orchestration-patterns.md
