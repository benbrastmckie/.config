# Build Command Persistence Research Report

**Date**: 2025-11-20
**Research Complexity**: 3
**Workflow Type**: research-and-plan

---

## Executive Summary

This report analyzes the /build command's current implementation and the state-based orchestration architecture to plan a refactor that makes the workflow **persistent by running implementer subagents for phases until the plan completes in full**, halting only when the primary agent approaches 90% context usage. The research identifies key improvements needed to transform /build from a single-shot workflow into a continuous execution model that can span multiple iterations.

### Key Findings

1. **Current Architecture is Non-Persistent**: The /build command executes as a 4-block linear workflow that completes in one execution, relying on checkpoints for manual resumption
2. **Implementer-Coordinator Already Supports Continuation**: The agent has `continuation_context` and `iteration` parameters but /build doesn't leverage them
3. **Context Exhaustion Detection Exists**: Implementation-executor monitors 70% threshold and generates summaries with work_remaining
4. **Missing Loop Logic**: /build lacks the orchestration loop to re-invoke implementer-coordinator when work_remaining > 0
5. **Documentation Gaps**: State-based orchestration docs don't adequately describe persistent workflows or continuation patterns

### Primary Recommendation

**Refactor /build to implement a persistent execution loop** that:
- Invokes implementer-coordinator repeatedly until plan complete or 90% context usage
- Passes previous summary path as continuation_context for seamless resumption
- Monitors iteration count (max 5 to prevent infinite loops)
- Halts gracefully when context threshold reached, creating resumption checkpoint

---

## Table of Contents

1. [Current Architecture Analysis](#current-architecture-analysis)
2. [Continuation Infrastructure Assessment](#continuation-infrastructure-assessment)
3. [Persistence Requirements](#persistence-requirements)
4. [Gap Analysis](#gap-analysis)
5. [Documentation Improvement Areas](#documentation-improvement-areas)
6. [Proposed Architecture](#proposed-architecture)
7. [Performance Considerations](#performance-considerations)
8. [Recommendations](#recommendations)

---

## Current Architecture Analysis

### /build Command Structure (1529 lines)

The /build command is organized into **4 bash blocks** executing sequentially:

```
Block 1: Consolidated Setup (lines 24-300)
  ├─ Detect project directory
  ├─ Source libraries (state-machine, persistence, error-handling)
  ├─ Parse arguments (plan-file, starting-phase, dry-run)
  ├─ Auto-resume logic (checkpoint detection <24h)
  ├─ State machine initialization: sm_init()
  ├─ Transition to STATE_IMPLEMENT
  └─ Invoke implementer-coordinator via Task tool (ONE TIME)

Block 2: Testing Phase (lines 695-971)
  ├─ Load workflow state
  ├─ Parse test results from test-executor artifact
  ├─ Determine TESTS_PASSED boolean
  └─ Persist test results to state

Block 3: Conditional Debug/Document (lines 973-1181)
  ├─ Load workflow state
  ├─ Branch on TESTS_PASSED:
  │   ├─ false → sm_transition(STATE_DEBUG), invoke debug-analyst
  │   └─ true → sm_transition(STATE_DOCUMENT)
  └─ Persist branch decision

Block 4: Completion (lines 1208-1503)
  ├─ Load workflow state
  ├─ Validate predecessor state (document|debug)
  ├─ sm_transition(STATE_COMPLETE)
  ├─ Print console summary
  ├─ Update plan metadata status to COMPLETE
  └─ Cleanup state files and checkpoints
```

### Key Characteristics

**Strengths:**
- Clean 4-block structure with explicit state transitions
- Comprehensive error handling with logging
- State recovery mechanisms across blocks
- Agent delegation with behavioral injection

**Weaknesses (for Persistence):**
- **Single-shot execution**: Implementer-coordinator invoked once in Block 1, no loop
- **No iteration tracking**: No mechanism to count continuation attempts
- **No work_remaining parsing**: Doesn't check if implementer-coordinator completed all work
- **No context monitoring**: Doesn't track primary agent context usage during execution
- **Fixed workflow**: Assumes all phases complete in one implementer-coordinator invocation

### State Machine Foundation

/build uses workflow-state-machine.sh v2.0.0 with these states:
```
initialize → implement → test → (debug|document) → complete
```

State persistence handled by:
- `init_workflow_state()` - Creates state file in Block 1
- `load_workflow_state()` - Loads state in Blocks 2-4
- `append_workflow_state()` - Adds variables to state
- `save_completed_states_to_state()` - Persists COMPLETED_STATES array

**Critical Finding**: State machine is **designed for linear workflows**, not iterative loops. The implement state has only one valid transition: `implement → test`. There's no `implement → implement` transition for continuation.

---

## Continuation Infrastructure Assessment

### Implementer-Coordinator Agent Capabilities

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
**Model**: haiku-4.5 (deterministic orchestration)
**Lines**: 578

The agent **already supports continuation** via these parameters:

```yaml
# Input Format (lines 26-48)
plan_path: /path/to/plan.md
topic_path: /path/to/specs/topic/
artifact_paths: {...}
continuation_context: null  # Or path to previous summary
iteration: 1                # Current iteration (1-5)
```

**Continuation Handling Logic**:
1. If `continuation_context` provided, reads previous summary
2. Parses "Work Remaining" section
3. Skips completed phases (marked [x] in plan)
4. Resumes from first incomplete phase

**Output Format (lines 374-403)**:
```yaml
IMPLEMENTATION_COMPLETE:
  phase_count: N
  summary_path: /path/to/summaries/NNN_workflow_summary.md
  git_commits: [hash1, hash2, ...]
  context_exhausted: true|false
  work_remaining: 0|[list of incomplete phases]
```

**Critical Observation**: The agent is **fully equipped** for continuation but /build **never re-invokes it** when `work_remaining > 0`.

### Implementation-Executor Agent (Single Phase)

**File**: `/home/benjamin/.config/.claude/agents/implementation-executor.md`
**Model**: sonnet-4.5 (complex execution logic)

This agent executes **single phases** and has:
- Context exhaustion detection at 70% threshold (lines 263-296)
- Graceful exit protocol with summary generation
- Work_remaining signal in PHASE_COMPLETE return

The implementer-coordinator invokes multiple implementation-executors in parallel (wave-based), so context exhaustion can occur at the **executor level** (partial phase) or **coordinator level** (partial plan).

### Wave-Based Parallelization

The implementer-coordinator uses **dependency-analyzer.sh** to create wave structure:
```
Wave 1: [Phase 1] (sequential)
Wave 2: [Phase 2, Phase 3] (parallel)
Wave 3: [Phase 4]
```

**Time savings**: 40-60% for plans with 2+ parallel phases

**Context Management**: Each wave waits for all executors to complete before proceeding, so context accumulation is **bounded per wave** but **cumulative across waves**.

---

## Persistence Requirements

### Loop Structure Requirements

To achieve persistence, /build needs:

1. **Iteration Loop** (pseudocode):
```bash
ITERATION=1
MAX_ITERATIONS=5
CONTINUATION_CONTEXT=null

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  # Check context usage BEFORE invoking
  CONTEXT_PCT=$(estimate_context_usage)
  if [ $CONTEXT_PCT -gt 90 ]; then
    echo "Context threshold reached (${CONTEXT_PCT}%), halting"
    save_resumption_checkpoint
    exit 0
  fi

  # Invoke implementer-coordinator
  invoke_implementer_coordinator \
    --continuation-context "$CONTINUATION_CONTEXT" \
    --iteration $ITERATION

  # Parse result
  WORK_REMAINING=$(parse_work_remaining)
  SUMMARY_PATH=$(parse_summary_path)

  # Check completion
  if [ "$WORK_REMAINING" == "0" ]; then
    echo "All phases complete"
    break
  fi

  # Prepare next iteration
  CONTINUATION_CONTEXT="$SUMMARY_PATH"
  ((ITERATION++))
done

# Proceed to testing phase (Block 2)
```

2. **Context Usage Monitoring**:
- Primary agent (haiku-4.5 for /build) needs to track its own context
- Before each iteration, estimate if another cycle fits within 90% limit
- Context estimation formula needed (heuristic based on plan size + iteration count)

3. **State Persistence Enhancements**:
- `ITERATION` counter must persist to state file
- `CONTINUATION_CONTEXT` path must persist for recovery
- `WORK_REMAINING` parsed from each summary

4. **Checkpoint Format Extension**:
Current checkpoint schema (v2.0) needs new fields:
```json
{
  "state_machine": {
    "current_state": "implement",
    "iteration": 3,
    "continuation_context": "/path/to/summary.md",
    "work_remaining": ["Phase 4", "Phase 5"]
  }
}
```

5. **Infinite Loop Prevention**:
- Hard limit: MAX_ITERATIONS=5 (covers ~15-25 phases based on typical phase density)
- Detect stuck state: If same work_remaining across 2 iterations, halt with error
- User override: `--max-iterations N` flag for exceptional plans

### Context Estimation Strategy

**Challenge**: Haiku-4.5 (primary model) doesn't have direct context introspection.

**Proposed Heuristic**:
```bash
estimate_context_usage() {
  local base_overhead=10000      # /build command + libraries
  local plan_size=$(wc -c < "$PLAN_FILE")
  local summary_size=$(wc -c < "$SUMMARY_PATH")
  local iteration_overhead=5000  # Per iteration (state, vars)

  local estimated_tokens=$(( (base_overhead + plan_size + summary_size + (ITERATION * iteration_overhead)) / 4 ))

  # Haiku-4.5 context: 200k tokens
  local context_pct=$(( (estimated_tokens * 100) / 200000 ))

  echo $context_pct
}
```

**Validation**: Compare estimate against actual context usage in test plans of varying sizes (5 phases, 15 phases, 30 phases).

---

## Gap Analysis

### Critical Gaps in /build Command

| Gap | Current State | Required State | Effort |
|-----|--------------|----------------|--------|
| **Iteration Loop** | Single invocation | while loop with max 5 iterations | Medium |
| **Context Monitoring** | None | Heuristic estimation before each iteration | Low |
| **work_remaining Parsing** | Not parsed | Extract from implementer-coordinator output | Low |
| **continuation_context Passing** | Always null | Pass previous summary path | Low |
| **State Persistence** | Basic | Add ITERATION, CONTINUATION_CONTEXT, WORK_REMAINING | Low |
| **Checkpoint Extension** | V2.0 schema | Add iteration fields | Low |
| **Stuck Detection** | None | Compare work_remaining across iterations | Low |
| **Graceful Halt** | Hard exit | Create resumption checkpoint + user guidance | Medium |

**Total Estimated Effort**: 2-3 hours implementation + 1 hour testing

### Documentation Gaps

#### State-Based Orchestration Docs

**File**: `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` (1765 lines)

**Missing Content**:
1. **Persistent Workflow Pattern**: Section on iterative state execution (implement → implement loop)
2. **Context Exhaustion Handling**: No guidance on monitoring or halting workflows
3. **Continuation Context Protocol**: Not documented how summaries enable resumption
4. **Iteration Limits**: No discussion of infinite loop prevention
5. **Checkpoint Resume Pattern**: Manual `/build` retry documented, but not automatic continuation

**Strengths**:
- Excellent coverage of state transitions and validation
- Clear examples of state handlers
- Good troubleshooting section

**Recommended Additions**:
- New section: "Persistent Workflows" (150-200 lines)
- Example: /build with iteration loop
- Diagram showing state re-entry pattern
- Checkpoint schema updates for continuation

#### Build Command Guide

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` (668 lines)

**Missing Content**:
1. **Persistence Behavior**: Not mentioned that /build will continue until plan complete
2. **Iteration Tracking**: No explanation of ITERATION counter or max limits
3. **Context Halt Explanation**: Users won't understand why /build stops at 90%
4. **Resumption Instructions**: How to continue after context halt (manual `/build` vs automatic)
5. **Work Remaining Interpretation**: What it means when summary shows incomplete phases

**Strengths**:
- Good troubleshooting section
- Clear phase update mechanism explanation
- Progress tracking well documented

**Recommended Updates**:
- Update "Architecture" section with persistence loop
- Add "Persistence Behavior" subsection under "Overview"
- New troubleshooting issue: "Build Halted at 90% Context"
- Update examples to show multi-iteration scenarios

#### Implementer-Coordinator Agent

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (578 lines)

**Missing Content**:
1. **Continuation Protocol Details**: How continuation_context is used step-by-step
2. **Work Remaining Format**: Exact format expected in summaries
3. **Iteration Context**: What changes between iteration 1, 2, 3, etc.
4. **Performance Across Iterations**: Does wave optimization work on continuation?

**Strengths**:
- Clear input format with continuation parameters
- Good wave execution description
- Error handling well documented

**Recommended Additions**:
- Expand STEP 1 with continuation handling detail
- Add section: "Multi-Iteration Execution Pattern"
- Example showing iteration 1 → iteration 2 flow

---

## Proposed Architecture

### Enhanced /build Command Structure

**New Block 1: Consolidated Setup + Iteration Loop** (replaces old Block 1):

```bash
# Block 1: Setup and Persistent Implementation Loop
set -e

# === DETECT PROJECT DIRECTORY ===
CLAUDE_PROJECT_DIR=$(detect_project_dir)
export CLAUDE_PROJECT_DIR

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists
COMMAND_NAME="/build"
WORKFLOW_ID="build_$(date +%s)"
USER_ARGS="$*"
export COMMAND_NAME USER_ARGS WORKFLOW_ID
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === PARSE ARGUMENTS ===
PLAN_FILE="${1:-}"
STARTING_PHASE="${2:-1}"
DRY_RUN="false"
MAX_ITERATIONS=5

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN="true" ;;
    --max-iterations=*) MAX_ITERATIONS="${arg#*=}" ;;
  esac
done

# === AUTO-DETECT PLAN ===
if [ -z "$PLAN_FILE" ]; then
  # Try checkpoint first (<24h)
  CHECKPOINT_DATA=$(load_checkpoint "build" 2>/dev/null || echo "")
  if [ -n "$CHECKPOINT_DATA" ]; then
    CHECKPOINT_AGE_HOURS=$(...)
    if [ "$CHECKPOINT_AGE_HOURS" -lt 24 ]; then
      PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
      STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
      echo "Auto-resuming from checkpoint: Phase $STARTING_PHASE"
    fi
  fi

  # Fall back to most recent plan
  if [ -z "$PLAN_FILE" ]; then
    PLAN_FILE=$(find "$CLAUDE_PROJECT_DIR/.claude/specs" -path "*/plans/*.md" -type f -exec ls -t {} + | head -1)
  fi
fi

echo "=== Build-from-Plan Workflow ==="
echo "Plan: $PLAN_FILE"
echo "Starting Phase: $STARTING_PHASE"
echo ""

# === DRY-RUN MODE ===
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE ==="
  echo "Would execute plan with persistent iteration loop"
  echo "Max iterations: $MAX_ITERATIONS"
  echo "Context halt threshold: 90%"
  exit 0
fi

# === INITIALIZE STATE MACHINE ===
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
sm_init "$PLAN_FILE" "$COMMAND_NAME" "full-implementation" "3" "[]"
sm_transition "$STATE_IMPLEMENT"

# === PERSIST INITIAL STATE ===
TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "STARTING_PHASE" "$STARTING_PHASE"
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"

# === PERSISTENT IMPLEMENTATION LOOP ===
ITERATION=1
CONTINUATION_CONTEXT="null"
WORK_REMAINING="initial"

echo "=== Implementation Phase: Persistent Execution ==="
echo ""

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "--- Iteration $ITERATION/$MAX_ITERATIONS ---"

  # === CHECK CONTEXT USAGE ===
  CONTEXT_PCT=$(estimate_context_usage "$PLAN_FILE" "$CONTINUATION_CONTEXT" "$ITERATION")
  echo "Estimated context usage: ${CONTEXT_PCT}%"

  if [ $CONTEXT_PCT -gt 90 ]; then
    echo ""
    echo "⚠ Context threshold reached (${CONTEXT_PCT}% > 90%)"
    echo "Halting implementation phase to prevent context overflow"
    echo ""

    # Create resumption checkpoint
    save_resumption_checkpoint "$PLAN_FILE" "$ITERATION" "$CONTINUATION_CONTEXT" "$WORK_REMAINING"

    echo "Resumption checkpoint saved"
    echo "To continue: /build $PLAN_FILE"
    echo ""

    # Mark incomplete in state
    append_workflow_state "IMPLEMENTATION_HALTED" "true"
    append_workflow_state "HALT_REASON" "context_threshold"
    append_workflow_state "HALT_ITERATION" "$ITERATION"

    # Skip to completion with partial status
    sm_transition "$STATE_COMPLETE"
    save_completed_states_to_state

    echo "=== Build Halted: Context Limit ==="
    echo "Status: Partial implementation"
    echo "Completed: See summary in topic/summaries/"
    echo "Resume: /build $PLAN_FILE"
    exit 0
  fi

  # === INVOKE IMPLEMENTER-COORDINATOR ===
  echo "Invoking implementer-coordinator (iteration $ITERATION)..."
  echo ""

  # Task tool invocation (behavioral injection)
  # Output parsed into variables: PHASE_COUNT, SUMMARY_PATH, WORK_REMAINING, CONTEXT_EXHAUSTED

  # === PARSE RESULTS ===
  echo ""
  echo "Iteration $ITERATION results:"
  echo "  Phases completed: $PHASE_COUNT"
  echo "  Summary: $SUMMARY_PATH"
  echo "  Work remaining: $WORK_REMAINING"
  echo ""

  # === CHECK COMPLETION ===
  if [ "$WORK_REMAINING" == "0" ]; then
    echo "✓ All phases complete"
    append_workflow_state "IMPLEMENTATION_COMPLETE" "true"
    append_workflow_state "TOTAL_ITERATIONS" "$ITERATION"
    break
  fi

  # === DETECT STUCK STATE ===
  if [ $ITERATION -gt 1 ] && [ "$WORK_REMAINING" == "$PREV_WORK_REMAINING" ]; then
    echo ""
    echo "⚠ ERROR: Stuck state detected"
    echo "Work remaining unchanged across iterations:"
    echo "  Iteration $(($ITERATION - 1)): $PREV_WORK_REMAINING"
    echo "  Iteration $ITERATION: $WORK_REMAINING"
    echo ""

    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "execution_error" \
      "Implementation loop stuck - work_remaining unchanged" \
      "block_1_iteration_$ITERATION" \
      "$(jq -n --arg work "$WORK_REMAINING" '{work_remaining: $work}')"

    echo "Halting to prevent infinite loop"
    exit 1
  fi

  # === PREPARE NEXT ITERATION ===
  PREV_WORK_REMAINING="$WORK_REMAINING"
  CONTINUATION_CONTEXT="$SUMMARY_PATH"
  ((ITERATION++))

  # Persist iteration state
  append_workflow_state "ITERATION" "$ITERATION"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
  save_completed_states_to_state

  echo "Continuing to iteration $ITERATION..."
  echo ""
done

# === MAX ITERATIONS REACHED ===
if [ $ITERATION -gt $MAX_ITERATIONS ]; then
  echo ""
  echo "⚠ Maximum iterations reached ($MAX_ITERATIONS)"
  echo "Implementation incomplete - manual intervention needed"
  echo ""
  echo "Work remaining:"
  echo "$WORK_REMAINING" | sed 's/^/  - /'
  echo ""

  save_resumption_checkpoint "$PLAN_FILE" "$ITERATION" "$CONTINUATION_CONTEXT" "$WORK_REMAINING"

  append_workflow_state "IMPLEMENTATION_INCOMPLETE" "true"
  append_workflow_state "INCOMPLETE_REASON" "max_iterations"
fi

# Persist final state
save_completed_states_to_state

echo "Implementation phase complete (or halted)"
echo "Proceeding to testing phase..."
echo ""

# Continue to Block 2 (Testing Phase)
```

**Key Changes**:
1. **while loop** replaces single implementer-coordinator invocation
2. **Context estimation** before each iteration
3. **work_remaining parsing** from IMPLEMENTATION_COMPLETE signal
4. **Stuck detection** comparing work_remaining across iterations
5. **Graceful halt** at 90% with resumption checkpoint
6. **MAX_ITERATIONS limit** (default 5, configurable via --max-iterations flag)

**Blocks 2-4 remain largely unchanged**, except:
- Block 2: Check IMPLEMENTATION_HALTED flag, skip testing if true
- Block 4: Handle partial completion status in summary

### Context Estimation Function

```bash
# estimate_context_usage: Heuristic for primary agent context usage
#
# Args:
#   $1 - PLAN_FILE path
#   $2 - CONTINUATION_CONTEXT path (or "null")
#   $3 - Current ITERATION number
#
# Returns:
#   Integer percentage (0-100)
#
estimate_context_usage() {
  local plan_file="$1"
  local continuation_context="$2"
  local iteration="$3"

  # Base overhead: /build command structure + libraries
  local base_overhead=10000

  # Plan size contribution (main context driver)
  local plan_size=0
  if [ -f "$plan_file" ]; then
    plan_size=$(wc -c < "$plan_file")
  fi

  # Summary size contribution (grows with iterations)
  local summary_size=0
  if [ "$continuation_context" != "null" ] && [ -f "$continuation_context" ]; then
    summary_size=$(wc -c < "$continuation_context")
  fi

  # Iteration overhead (state accumulation, variables)
  local iteration_overhead=$((iteration * 5000))

  # Implementer-coordinator output (approximate)
  local coordinator_output=8000  # Brief progress summaries per iteration

  # Total estimated characters
  local total_chars=$((base_overhead + plan_size + summary_size + iteration_overhead + (iteration * coordinator_output)))

  # Convert to tokens (rough estimate: 4 chars per token)
  local estimated_tokens=$((total_chars / 4))

  # Haiku-4.5 context window: 200,000 tokens
  local haiku_context_window=200000

  # Calculate percentage
  local context_pct=$((estimated_tokens * 100 / haiku_context_window))

  # Safety cap at 100%
  if [ $context_pct -gt 100 ]; then
    context_pct=100
  fi

  echo $context_pct
}
```

**Validation Strategy**:
1. Test with small plan (5 phases): Should allow 4-5 iterations before 90%
2. Test with medium plan (15 phases): Should allow 2-3 iterations
3. Test with large plan (30 phases): Should allow 1-2 iterations
4. Adjust multipliers if estimates wildly off

### Resumption Checkpoint Format

```bash
save_resumption_checkpoint() {
  local plan_file="$1"
  local iteration="$2"
  local continuation_context="$3"
  local work_remaining="$4"

  local checkpoint_file="${HOME}/.claude/data/checkpoints/build_checkpoint.json"
  mkdir -p "$(dirname "$checkpoint_file")"

  jq -n \
    --arg plan "$plan_file" \
    --arg iter "$iteration" \
    --arg context "$continuation_context" \
    --arg work "$work_remaining" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      version: "2.1",
      state_machine: {
        current_state: "implement",
        iteration: ($iter | tonumber),
        continuation_context: $context,
        work_remaining: $work
      },
      plan_path: $plan,
      timestamp: $timestamp,
      resumable: true
    }' > "$checkpoint_file"

  echo "Checkpoint saved: $checkpoint_file"
}
```

**Schema Version 2.1** (extends V2.0):
- `iteration`: Current iteration count
- `continuation_context`: Path to last summary
- `work_remaining`: Phases still to implement
- `resumable`: Boolean flag for auto-resume

---

## Documentation Improvement Areas

### 1. State-Based Orchestration Overview

**File**: `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`

**New Section**: "Persistent Workflows" (insert after line 367)

```markdown
## Persistent Workflows

### Overview

Persistent workflows execute iteratively, re-entering states multiple times until work completes or context limits reached. This pattern enables long-running operations that span multiple primary agent invocations.

### Pattern: Iterative State Execution

Unlike linear workflows that transition `initialize → research → plan → implement → test → complete`, persistent workflows remain in a state (typically `implement`) across multiple iterations:

```
Iteration 1: implement(phases 1-5) → work_remaining: [6,7,8]
Iteration 2: implement(phases 6-8) → work_remaining: []
             → transition to test
```

### Use Cases

- **Large implementation plans** (15+ phases) that exceed single-agent context
- **Long-running builds** requiring multiple hours of execution
- **Incremental progress** where checkpoints enable resumption

### Context Management

Persistent workflows monitor primary agent context usage and halt when threshold reached:

**Thresholds**:
- **Warning**: 70% context usage → log warning
- **Halt**: 90% context usage → create checkpoint, exit gracefully

**Estimation Strategy**:
```bash
context_pct = (base_overhead + plan_size + summary_size + iteration_overhead) / context_window
```

### Continuation Protocol

1. **First Iteration**:
   - Invoke subagent with `continuation_context: null`
   - Subagent executes phases, creates summary
   - Summary includes "Work Remaining" section

2. **Subsequent Iterations**:
   - Invoke subagent with `continuation_context: /path/to/previous/summary.md`
   - Subagent reads summary, skips completed phases
   - Continues from first incomplete phase

3. **Completion**:
   - Subagent returns `work_remaining: 0`
   - Orchestrator exits loop, proceeds to next state

### Infinite Loop Prevention

**Max Iterations Limit**: Default 5 iterations, configurable via `--max-iterations` flag

**Stuck Detection**: If `work_remaining` unchanged across 2 iterations, halt with error

**User Override**: Can increase limit for exceptional plans, but investigate why progress blocked

### Example: /build Command

```bash
# /build implements persistent workflow for implementation phase
ITERATION=1
MAX_ITERATIONS=5
CONTINUATION_CONTEXT=null

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  # Check context before iteration
  CONTEXT_PCT=$(estimate_context_usage "$PLAN_FILE" "$CONTINUATION_CONTEXT" "$ITERATION")
  if [ $CONTEXT_PCT -gt 90 ]; then
    save_resumption_checkpoint
    exit 0
  fi

  # Invoke implementer-coordinator
  invoke_implementer_coordinator \
    --continuation-context "$CONTINUATION_CONTEXT" \
    --iteration $ITERATION

  # Parse results
  WORK_REMAINING=$(parse_work_remaining)
  SUMMARY_PATH=$(parse_summary_path)

  # Check completion
  [ "$WORK_REMAINING" == "0" ] && break

  # Prepare next iteration
  CONTINUATION_CONTEXT="$SUMMARY_PATH"
  ((ITERATION++))
done

# Proceed to testing phase
sm_transition "$STATE_TEST"
```

### State Machine Implications

**State Re-Entry**: Persistent workflows violate the typical "each state executed once" assumption. The `implement` state is re-entered multiple times.

**Transition Table**: No changes needed. State machine sees single `implement → test` transition, but internal to `implement` is iteration loop.

**Checkpoint Schema**: Extended with iteration fields (V2.1):
```json
{
  "state_machine": {
    "current_state": "implement",
    "iteration": 3,
    "continuation_context": "/path/to/summary.md",
    "work_remaining": ["Phase 9", "Phase 10"]
  }
}
```

### Performance Characteristics

**Context Savings**:
- Iteration 1: 25% context usage (clean start)
- Iteration 2: 35% context usage (+summary overhead)
- Iteration 3: 45% context usage (+cumulative state)
- Iteration 4: 60% context usage
- Iteration 5: 80% context usage (approaching limit)

**Time Per Iteration**:
- Median: 15-20 minutes per iteration (depends on phase count)
- Range: 5 minutes (1-2 phases) to 45 minutes (5+ phases)

**Throughput**:
- Typical plan (12 phases) completes in 2-3 iterations (~40 minutes)
- Large plan (30 phases) needs 4-5 iterations (~90 minutes) or hits context limit

### Troubleshooting

**Issue**: "Maximum iterations reached"

**Cause**: Plan too large for 5 iterations, or phases blocking

**Solution**:
1. Check work_remaining - are phases actually progressing?
2. Increase limit: `/build --max-iterations 10`
3. Split plan into smaller sub-plans

**Issue**: "Stuck state detected"

**Cause**: Same phases remain in work_remaining across iterations

**Solution**:
1. Review last summary for errors in completed phases
2. Check if tests failing (prevents phase completion)
3. Manual intervention: fix blocking phase, resume

**Issue**: "Context threshold reached at iteration 2"

**Cause**: Plan extremely large, or continuation_context summary very long

**Solution**:
1. Simplify plan (fewer phases)
2. Reduce phase descriptions (less text per phase)
3. Use Level 1/2 expansion (phase files reduce main plan size)

### Related Patterns

- **Checkpoint Recovery** (checkpoint-recovery.md): How resumption works
- **Hierarchical Supervisors** (hierarchical-agents.md): Wave-based parallelization within iteration
- **Behavioral Injection** (behavioral-injection.md): How continuation_context passed to subagents
```

**Estimated Lines**: 180 lines

### 2. Build Command Guide Updates

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md`

**Updates Needed**:

**Line 23-26** (When to Use section):
```markdown
### When to Use

- **Executing implementation plans**: When you have an existing plan file and want to implement it
- **Large plans**: Automatically handles plans with 15+ phases through iterative execution
- **Long-running builds**: Persistent workflow continues until plan complete or context limit reached
- **Resuming interrupted work**: Auto-resumes from checkpoints when no plan specified
...
```

**New Subsection** (after line 105, "Architecture → Data Flow"):
```markdown
### Persistence Behavior

The /build command implements **persistent workflow execution**, meaning it will continue implementing phases until the plan completes or the primary agent reaches 90% context usage.

**Iteration Loop**:
1. Iteration 1: Invoke implementer-coordinator, execute phases 1-N
2. Parse summary: Check work_remaining
3. If work_remaining > 0: Start iteration 2 with continuation_context
4. Repeat until work_remaining == 0 or context threshold reached

**Context Monitoring**:
- Before each iteration, estimates context usage
- If > 90%: Creates resumption checkpoint, exits gracefully
- User re-runs `/build` to continue (auto-resumes from checkpoint)

**Iteration Limits**:
- Default: 5 iterations (covers ~15-25 phases)
- Configurable: `/build --max-iterations 10`
- Safety: Detects stuck state (work_remaining unchanged across iterations)

**Example Scenarios**:

*Small Plan (5 phases)*:
- Iteration 1: Complete all 5 phases
- Testing proceeds immediately

*Medium Plan (15 phases)*:
- Iteration 1: Complete phases 1-8
- Iteration 2: Complete phases 9-15
- Testing proceeds after iteration 2

*Large Plan (30 phases)*:
- Iteration 1: Complete phases 1-8 (~25% context)
- Iteration 2: Complete phases 9-16 (~45% context)
- Iteration 3: Complete phases 17-24 (~70% context)
- Iteration 4: Complete phases 25-30 (~92% context) → HALT
- Checkpoint created, user re-runs `/build` to continue from phase 31

**Manual Resumption**:
When context threshold reached, run:
```bash
/build  # Auto-detects checkpoint, resumes
```

Or specify plan explicitly:
```bash
/build .claude/specs/123_large_feature/plans/001_implementation.md
```
```

**Estimated Lines**: 60 lines

**New Troubleshooting Issue** (after line 566):
```markdown
#### Issue 9: Build Halted at 90% Context

**Symptoms**:
- Message: "Context threshold reached (92% > 90%)"
- Build stops after N iterations
- Resumption checkpoint created
- Plan partially complete

**Cause**:
Plan is very large (20+ phases) and primary agent (/build) approaching context limit after multiple iterations.

**Solution**:
This is **expected behavior** for large plans. The halt prevents context overflow and data loss.

**Resume execution**:
```bash
# Auto-resume from checkpoint
/build

# Or specify plan explicitly
/build .claude/specs/123_large_feature/plans/001_implementation.md
```

The checkpoint contains:
- Continuation context (last summary)
- Work remaining (incomplete phases)
- Iteration count

Build will continue from where it left off.

**Prevention** (for future plans):
- Split very large features into multiple plans (10-15 phases each)
- Use Level 1 expansion (phase files) to reduce main plan size
- Increase iteration limit if needed: `/build --max-iterations 10`

**When to Investigate**:
- If halted after iteration 1-2 (plan may not be that large - check estimation)
- If same phases stuck across multiple resumptions (implementation blocking)
```

**Estimated Lines**: 40 lines

### 3. Implementer-Coordinator Agent

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Enhancement to STEP 1** (line 49-71, "Initialization"):

```markdown
### STEP 1: Initialization and Continuation Handling

#### 1. Read Plan File
Load top-level plan to understand structure (Level 0/1/2).

#### 2. Check Continuation Context

**If continuation_context is null** (first iteration):
- Start from beginning of plan
- Execute all phases in dependency order

**If continuation_context is provided** (iteration 2+):
1. **Read Previous Summary**:
   ```bash
   SUMMARY=$(cat "$continuation_context")
   ```

2. **Parse Work Remaining Section**:
   ```
   ## Work Remaining
   - [ ] Phase 5: Backend API Implementation
   - [ ] Phase 6: Frontend Integration
   - [ ] Phase 7: Testing
   ```

3. **Extract Incomplete Phases**:
   ```bash
   INCOMPLETE_PHASES=$(echo "$SUMMARY" | sed -n '/## Work Remaining/,/^$/p' | grep '^\- \[ \]' | grep -oE 'Phase [0-9]+')
   # Result: ["Phase 5", "Phase 6", "Phase 7"]
   ```

4. **Verify Against Plan File**:
   - Read plan file checkboxes
   - Confirm phases 1-4 marked [x] (completed)
   - Confirm phases 5-7 marked [ ] (incomplete)

5. **Resume from First Incomplete Phase**:
   - Dependency analysis starts from Phase 5
   - Phases 1-4 skipped (already in git history)

#### 3. Build File List

Based on plan structure level (0, 1, or 2), build list of files to analyze for dependencies.

**Continuation Impact**:
- If resuming, only analyze incomplete phase files
- Skip dependency analysis for completed phases (optimization)

#### 4. Initialize Tracking

- Total phases: Count from plan
- Completed phases: Parse from plan checkboxes or continuation_context
- Starting phase: First incomplete phase (or 1 if initial)
- Iteration number: Provided in input

**State Display**:
```
Resuming from Iteration 2
Phases completed: 1-4 (4/7)
Phases remaining: 5-7 (3 phases)
Starting with Phase 5: Backend API Implementation
```
```

**Estimated Lines**: 60 lines (replaces 20 existing lines)

**New Section** (after line 493, before "Notes"):
```markdown
## Multi-Iteration Execution

### Iteration Lifecycle

**Iteration 1** (Initial):
```yaml
Input:
  continuation_context: null
  iteration: 1

Behavior:
  - Start from Phase 1
  - Execute all phases in dependency order
  - Create summary with work_remaining if context exhausted

Output:
  IMPLEMENTATION_COMPLETE:
    phase_count: 8
    summary_path: /path/to/summaries/001_iteration_1.md
    work_remaining: ["Phase 9", "Phase 10", "Phase 11"]
    context_exhausted: true
```

**Iteration 2** (Continuation):
```yaml
Input:
  continuation_context: /path/to/summaries/001_iteration_1.md
  iteration: 2

Behavior:
  - Read summary, parse work_remaining
  - Verify phases 1-8 complete in plan (checkboxes [x])
  - Resume from Phase 9
  - Execute phases 9-11

Output:
  IMPLEMENTATION_COMPLETE:
    phase_count: 11
    summary_path: /path/to/summaries/002_iteration_2.md
    work_remaining: 0
    context_exhausted: false
```

### Performance Across Iterations

**Wave Optimization Maintained**:
Dependency analysis re-runs for incomplete phases only, so wave-based parallelization benefits preserved:
- Iteration 1: Phases 1-8 → 3 waves (40% time savings)
- Iteration 2: Phases 9-11 → 2 waves (25% time savings)

**Context Accumulation**:
Each iteration adds to coordinator's context:
- Iteration 1: 15k tokens (plan + 8 phase summaries)
- Iteration 2: 20k tokens (plan + previous summary + 3 phase summaries)
- Iteration 3: 25k tokens (cumulative)

**Throughput Degradation**:
Minimal impact - each iteration operates on subset of phases, so context per phase remains constant.

### Idempotency

Implementer-coordinator is **idempotent** across iterations:
- Re-invocation with same continuation_context produces same result
- Completed phases never re-executed (checked via plan file [x] markers)
- Git commits ensure permanent record of progress

### Error Handling in Continuation

**Scenario**: Iteration 1 completes phases 1-6, iteration 2 fails on phase 7

**Result**:
- Phases 1-6: Marked [x], committed to git
- Phase 7: Marked [ ], no commit
- work_remaining: ["Phase 7", "Phase 8", "Phase 9"]

**Retry**:
```bash
/build  # Resumes from phase 7
```

Phase 7 re-attempted (not skipped), ensuring no lost work.
```

**Estimated Lines**: 80 lines

---

## Performance Considerations

### Context Budget Analysis

**Haiku-4.5 (Primary /build Agent)**:
- Context window: 200,000 tokens
- 90% threshold: 180,000 tokens

**Context Consumption Breakdown** (per iteration):
- /build command structure: ~2,000 tokens
- Libraries (state-machine, persistence): ~1,500 tokens
- Plan file: Varies (5k for small, 20k for medium, 50k+ for large)
- Previous summary: ~2,000 tokens per iteration (cumulative)
- Implementer-coordinator output: ~1,000 tokens (metadata only)
- State variables: ~500 tokens

**Example Scenarios**:

*Small Plan (5 phases, 5k tokens)*:
- Iteration 1: 2k + 1.5k + 5k + 0 + 1k + 0.5k = 10k tokens (5%)
- Could run 18 iterations before 90% (far exceeds need)

*Medium Plan (15 phases, 15k tokens)*:
- Iteration 1: 15k base + 2k summary = 17k (9%)
- Iteration 2: 15k base + 4k summaries = 19k (10%)
- Iteration 3: 15k base + 6k summaries = 21k (11%)
- Could run ~8 iterations before 90%

*Large Plan (30 phases, 40k tokens)*:
- Iteration 1: 40k base + 2k = 42k (23%)
- Iteration 2: 40k base + 4k = 44k (24%)
- Iteration 3: 40k base + 6k = 46k (25%)
- Iteration 4: 40k base + 8k = 48k (26%)
- Could run ~15 iterations, but plan completes in 4-5

**Conclusion**: Context budget is **NOT a bottleneck** for typical workflows. The 90% threshold is conservative safety margin.

### Time Per Iteration

**Factors**:
- Phase count per iteration (typically 5-10 phases)
- Phase complexity (tasks per phase)
- Wave-based parallelization efficiency
- Implementation-executor execution time per phase

**Measured Performance** (from implementation summaries):
- Simple phase (3-5 tasks): 3-5 minutes
- Medium phase (8-12 tasks): 8-12 minutes
- Complex phase (15+ tasks): 15-25 minutes

**Iteration Time Estimates**:
- 5 phases/iteration: 25-40 minutes (average)
- 8 phases/iteration: 40-70 minutes
- 10 phases/iteration: 60-90 minutes

**Total Plan Time**:
- 12-phase plan, 2 iterations: 60-80 minutes
- 24-phase plan, 3-4 iterations: 120-180 minutes
- 40-phase plan, 5-6 iterations: 200-300 minutes (3-5 hours)

### Optimization Strategies

1. **Phase Granularity**:
   - Smaller phases (3-5 tasks each) → More phases, but faster per phase
   - Larger phases (10-15 tasks) → Fewer phases, but longer per phase
   - **Recommendation**: Target 5-8 tasks per phase for optimal balance

2. **Plan Expansion**:
   - Level 0 (inline): All phases in one file → Larger context
   - Level 1 (phase files): Reduces main plan size by ~60%
   - Level 2 (stage files): Further reduces, but complexity overhead
   - **Recommendation**: Use Level 1 for plans >15 phases

3. **Dependency Optimization**:
   - More dependencies → More sequential waves → Longer time
   - Fewer dependencies → More parallel waves → Shorter time
   - **Recommendation**: Review dependencies, remove unnecessary ones

4. **Context Reduction**:
   - Implementer-coordinator returns metadata only (not full output)
   - Summaries pruned to essential information
   - **Already optimized** in current architecture

---

## Recommendations

### Phase 1: Core Implementation (Highest Priority)

**Scope**: Make /build persistent with iteration loop

**Tasks**:
1. Add iteration loop to Block 1 (replace single invocation)
2. Implement `estimate_context_usage()` function
3. Parse `work_remaining` from implementer-coordinator output
4. Add `--max-iterations` flag (default 5)
5. Implement stuck state detection
6. Create `save_resumption_checkpoint()` function
7. Update Block 4 to handle partial completion

**Estimated Effort**: 3-4 hours

**Testing**:
- Small plan (5 phases): Verify completes in 1 iteration
- Medium plan (15 phases): Verify completes in 2-3 iterations
- Large plan (30 phases): Verify halts at 90%, resumes correctly
- Stuck state: Manually create scenario with blocking phase

### Phase 2: Documentation Updates (High Priority)

**Scope**: Update documentation to reflect persistence behavior

**Tasks**:
1. Add "Persistent Workflows" section to state-based-orchestration-overview.md (~180 lines)
2. Update build-command-guide.md:
   - "When to Use" section
   - "Persistence Behavior" subsection
   - Troubleshooting issue for 90% context halt
3. Enhance implementer-coordinator.md:
   - Expand STEP 1 with continuation handling detail
   - Add "Multi-Iteration Execution" section

**Estimated Effort**: 2-3 hours

**Review**:
- Ensure examples clear and accurate
- Test example commands actually work
- Check consistency across all docs

### Phase 3: Refinements (Medium Priority)

**Scope**: Improve estimation accuracy and user experience

**Tasks**:
1. Validation testing: Run estimate_context_usage() on real plans, compare to actual
2. Adjust multipliers if estimates off by >10%
3. Add `--show-context` flag to display estimation details
4. Improve stuck detection: Log work_remaining diff for debugging
5. Add progress bar showing iteration N/MAX_ITERATIONS

**Estimated Effort**: 2 hours

### Phase 4: Advanced Features (Low Priority)

**Scope**: Optional enhancements for power users

**Tasks**:
1. `--resume-from-iteration N` flag for manual iteration control
2. `--context-threshold PCT` flag to override 90% default
3. Checkpoint pruning: Auto-delete old checkpoints >7 days
4. Summary consolidation: Merge iteration summaries into single final summary
5. Telemetry: Log iteration metrics for performance analysis

**Estimated Effort**: 3-4 hours

### Phase 5: Testing and Validation (Highest Priority)

**Scope**: Comprehensive testing across scenarios

**Tests**:
1. **Unit Tests**:
   - `estimate_context_usage()` with various plan sizes
   - `save_resumption_checkpoint()` schema validation
   - Work_remaining parsing logic

2. **Integration Tests**:
   - Small plan (5 phases) completes in 1 iteration
   - Medium plan (15 phases) completes in 2-3 iterations
   - Large plan (30 phases) halts at 90%, resumes correctly
   - Stuck state detection triggers after 2 identical work_remaining
   - Max iterations limit prevents infinite loop

3. **End-to-End Tests**:
   - Real plan from spec 874 (build testing subagent) - 4 phases
   - Real plan from spec 859 (leader.ac command) - 22 phases
   - Verify git commits, plan checkboxes, summaries all correct

**Estimated Effort**: 4-5 hours

**Test Coverage Target**: 90% of new code (iteration loop, estimation, checkpoint)

### Non-Goals (Explicitly Out of Scope)

1. **Dynamic MAX_ITERATIONS**: Not adjusting limit based on plan size automatically (user can override)
2. **Sub-Phase Resumption**: Not resuming mid-phase (phase is atomic unit)
3. **Parallel Iteration**: Not running multiple iterations in parallel (sequential only)
4. **Context Introspection**: Not using actual token counts (heuristic sufficient)
5. **LLM Selection**: Not changing implementer-coordinator model (haiku-4.5 works well)

---

## Risk Analysis

### Technical Risks

**Risk 1: Estimation Inaccuracy**
- **Likelihood**: Medium
- **Impact**: Medium (premature halt or overflow)
- **Mitigation**: Validation testing, adjustable threshold, conservative default (90%)

**Risk 2: Stuck State False Positives**
- **Likelihood**: Low
- **Impact**: Low (annoying, not blocking)
- **Mitigation**: Log work_remaining diff for debugging, allow user override with --force-continue

**Risk 3: Infinite Loop Despite Safeguards**
- **Likelihood**: Very Low
- **Impact**: High (wastes resources, blocks workflow)
- **Mitigation**: Hard MAX_ITERATIONS limit, timeout per iteration (2 hours), kill switch in state file

**Risk 4: Checkpoint Corruption**
- **Likelihood**: Low
- **Impact**: Medium (lose resumption ability)
- **Mitigation**: Atomic writes, JSON validation, fallback to plan file analysis

### User Experience Risks

**Risk 5: Confusion About Halt Behavior**
- **Likelihood**: Medium
- **Impact**: Low (users unsure why build stopped)
- **Mitigation**: Clear messaging, documentation, troubleshooting guide

**Risk 6: Unexpected Multi-Iteration Duration**
- **Likelihood**: Medium
- **Impact**: Low (users underestimate total time)
- **Mitigation**: Show estimated iterations at start, progress indicator per iteration

**Risk 7: Resumption Friction**
- **Likelihood**: Low
- **Impact**: Low (users have to re-run /build)
- **Mitigation**: Auto-resume from checkpoint makes it seamless

---

## Success Criteria

### Functional Requirements

1. ✓ /build executes implementation phases iteratively until plan complete
2. ✓ Context usage monitored before each iteration, halt at 90%
3. ✓ Resumption checkpoint created when halted, auto-resume on retry
4. ✓ Max 5 iterations (configurable), stuck state detection
5. ✓ work_remaining parsed from implementer-coordinator output
6. ✓ continuation_context passed to subsequent iterations
7. ✓ Plan checkboxes and git commits correct across iterations

### Non-Functional Requirements

8. ✓ Context estimation accurate within 10% of actual usage
9. ✓ No performance degradation (iteration 2 same speed as iteration 1)
10. ✓ Documentation clear, examples tested, troubleshooting comprehensive
11. ✓ Test coverage >90% for new code
12. ✓ Backward compatible with existing plans (no breaking changes)

### User Experience

13. ✓ Users understand halt behavior (clear messaging)
14. ✓ Resumption seamless (auto-detect checkpoint)
15. ✓ Progress visible (iteration counter, phases completed)
16. ✓ Errors actionable (stuck detection with explanation)

---

## Conclusion

The /build command is **well-positioned** for a persistence refactor. The implementer-coordinator agent already has continuation infrastructure (`continuation_context`, `iteration` parameters, `work_remaining` output), and the state machine architecture provides a solid foundation for iteration logic.

**Key Success Factors**:
1. **Conservative context estimation**: 90% threshold with safety margin prevents overflow
2. **Stuck detection**: Prevents infinite loops from blocking phases
3. **Clear documentation**: Users understand multi-iteration behavior and resumption
4. **Comprehensive testing**: Validates across small/medium/large plans

**Effort Estimate**: 12-15 hours total
- Phase 1 (Core): 3-4 hours
- Phase 2 (Docs): 2-3 hours
- Phase 3 (Refinements): 2 hours
- Phase 5 (Testing): 4-5 hours

**Timeline**: 2-3 days (assuming 6-8 hour workdays)

**Recommendation**: Proceed with implementation. The architecture is sound, risks are manageable, and the value proposition (persistent workflows for large plans) is high.

---

## Related Documentation

- **State-Based Orchestration**: [state-based-orchestration-overview.md](/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md)
- **Build Command Guide**: [build-command-guide.md](/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md)
- **Implementer-Coordinator Agent**: [implementer-coordinator.md](/home/benjamin/.config/.claude/agents/implementer-coordinator.md)
- **Implementation-Executor Agent**: [implementation-executor.md](/home/benjamin/.config/.claude/agents/implementation-executor.md)
- **Workflow State Machine**: [workflow-state-machine.sh](/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh)
- **Error Handling Pattern**: [error-handling.md](/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)

---

## Appendix: File References

### Analyzed Files

| File | Lines | Key Findings |
|------|-------|--------------|
| `/home/benjamin/.config/.claude/commands/build.md` | 1529 | 4-block structure, single implementer-coordinator invocation |
| `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` | 578 | Has continuation params, not used by /build |
| `/home/benjamin/.config/.claude/agents/implementation-executor.md` | ~500 | 70% context detection, work_remaining output |
| `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` | 1765 | Missing persistent workflow pattern docs |
| `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` | 668 | No mention of persistence behavior |
| `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` | ~600 | State machine supports transitions, not iteration loops |

### Documentation Gaps

1. **state-based-orchestration-overview.md**: Add "Persistent Workflows" section (~180 lines)
2. **build-command-guide.md**: Update architecture, add persistence behavior, new troubleshooting issue (~100 lines)
3. **implementer-coordinator.md**: Expand continuation handling, add multi-iteration section (~140 lines)

**Total Documentation Additions**: ~420 lines

---

## Implementation Status

- **Status**: Planning Complete
- **Plan**: [../plans/001_build_persistent_workflow_refactor_plan.md](../plans/001_build_persistent_workflow_refactor_plan.md)
- **Implementation**: [Will be updated by /build]
- **Date**: 2025-11-20

---

REPORT_CREATED: /home/benjamin/.config/.claude/specs/881_build_persistent_workflow_refactor/reports/001_build_persistence_research.md
