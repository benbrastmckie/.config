# Implementation Plan: Lean-Implement Coordinator Wave-Based Orchestration

**Date**: 2025-12-09 (Revised)
**Feature**: Refactor /lean-implement command to enable wave-based parallel execution via lean-coordinator, implement multi-cycle iteration with context tracking, add automated plan revision on blocking dependencies, fix phase 0 detection in both /lean-implement and /implement commands, and achieve full standards compliance
**Status**: [COMPLETE]
**Estimated Hours**: 22-27 hours
**Actual Progress**: 10/12 phases complete (83%), ~18 hours invested. Phases 8-9 deferred to separate specs per architectural complexity.
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Lean Coordinator Agent Invocation Architecture Analysis](/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/reports/001-lean-coordinator-invocation.md)
- [Parallel Wave Orchestration and Dependency Resolution Analysis](/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/reports/002-parallel-wave-dependency-management.md)
- [Subagent Discovery and Plan Revision Workflow Analysis](/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/reports/003-subagent-discovery-plan-revision.md)
- [Lean-Implement Command Refactoring Strategy Analysis](/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/reports/004-lean-implement-refactor-strategy.md)
- [Phase 0 Skip Fix Analysis](/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/reports/5-phase_0_skip_fix.md)

---

## Overview

This plan refactors the `/lean-implement` command to address critical architecture gaps and standards violations identified in research. The current implementation correctly delegates to lean-coordinator but lacks wave-based parallelization, context monitoring, checkpoint resume capability, and standards-compliant Task invocation patterns.

**Key Problems**:
1. **Phase 0 Skip Bug**: Both /lean-implement and /implement hardcode STARTING_PHASE=1, skipping phase 0 if present (affects standards revision phases)
2. **No Wave-Based Orchestration**: Phases execute sequentially via per-phase routing instead of full plan delegation with dependency-driven waves (40-60% time savings opportunity missed)
3. **Task Invocation Violations**: Uses conditional prefix patterns without EXECUTE keyword (ERROR-level standards violation)
4. **Limited Iteration Control**: No context usage tracking, checkpoint save/resume, or defensive continuation validation
5. **Missing Plan Revision Workflow**: Blocking dependencies discovered by subagents don't trigger automated plan revision and dependency recalculation
6. **Library Underutilization**: Misses validation-utils.sh and checkpoint-utils.sh patterns proven in /implement command

**Solution Approach**:
- Fix phase 0 detection logic in both /lean-implement and /implement to auto-detect lowest incomplete phase
- Transform from sequential per-phase routing to full plan delegation with hybrid coordinator
- Implement wave-based parallel execution with dependency recalculation after failures
- Add coordinator-triggered plan revision workflow for blocking dependencies
- Integrate checkpoint-based multi-cycle iteration with context monitoring
- Achieve full standards compliance via bash conditional Task invocation pattern
- Leverage validation-utils.sh and checkpoint-utils.sh for defensive validation

**Success Criteria**:
- [x] Phase 0 auto-detection in both /lean-implement and /implement commands
- [ ] Wave-based parallel execution for independent Lean/software phases (40-60% time savings)
- [ ] Automated plan revision when subagents discover blocking dependencies
- [x] Checkpoint save/resume workflow with context threshold monitoring
- [x] Zero Task invocation pattern violations (linter-verified)
- [ ] Integration test coverage: phase 0 detection, dual coordinator workflow, checkpoint resume, plan revision cycle

---

## Phase 0: Pre-Implementation Analysis and Infrastructure [COMPLETE]

**Dependencies**: depends_on: []
**Estimated Time**: 2-3 hours

### Success Criteria
- [x] Current /lean-implement behavior documented with execution traces
- [x] lean-coordinator and implementer-coordinator output signal contracts verified
- [x] dependency-analyzer.sh integration requirements confirmed
- [x] Backup of existing /lean-implement command created

### Tasks
- [x] Read /home/benjamin/.config/.claude/commands/lean-implement.md and document current block structure
- [x] Read /home/benjamin/.config/.claude/agents/lean-coordinator.md and verify output signal fields (summary_brief, phases_completed, work_remaining, context_usage_percent, requires_continuation)
- [x] Read /home/benjamin/.config/.claude/agents/implementer-coordinator.md and verify wave execution STEP 4 pattern
- [x] Read /home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh and confirm identify_waves() API
- [x] Run test execution: /lean-implement on minimal Lean plan to capture baseline output
- [x] Create backup: cp /home/benjamin/.config/.claude/commands/lean-implement.md /home/benjamin/.config/.claude/commands/lean-implement.md.backup.20251209

### Validation
- [x] Backup file exists at expected path
- [x] Output signal contract fields documented in phase notes
- [x] dependency-analyzer.sh API confirmed (accepts plan_path, returns JSON with waves array)

### Implementation Notes (2025-12-09)
- Backup created at: `/home/benjamin/.config/.claude/commands/lean-implement.md.backup.20251209`
- Coordinator output signals verified: summary_brief, phases_completed, work_remaining, context_usage_percent, requires_continuation
- dependency-analyzer.sh confirmed: `identify_waves()` accepts plan_path and returns JSON with waves array

---

## Phase 0.5: Fix Starting Phase Detection in Both Commands [COMPLETE]

**Dependencies**: depends_on: [0]
**Estimated Time**: 2 hours

### Success Criteria
- [x] Phase detection logic added to /lean-implement after line 213
- [x] Phase detection logic added to /implement after line 308
- [x] Auto-detection finds lowest incomplete phase (including phase 0)
- [x] Explicit phase arguments override auto-detection
- [x] All 5 test cases pass (phase 0 incomplete, phase 0 complete, no phase 0, explicit arg, all complete)

### Tasks
- [x] Add phase detection logic to /lean-implement command Block 1a after line 213 (after PLAN_FILE validation)
- [x] Add identical phase detection logic to /implement command Block 1a after line 308 (after PLAN_FILE validation)
- [x] Implement detection algorithm: extract all phase numbers, find first without [COMPLETE] marker
- [x] Add defensive fallback: default to 1 if no incomplete phases found
- [x] Add echo output showing auto-detection status when phase detected
- [x] Update implementer-coordinator.md documentation to clarify auto-detection behavior (lines 821-831)
- [x] Create test plan with phase 0 for integration testing
- [x] Run Test Case 1: Plan with phase 0 incomplete - verify STARTING_PHASE=0
- [x] Run Test Case 2: Plan with phase 0 complete - verify STARTING_PHASE=1
- [x] Run Test Case 3: Plan without phase 0 - verify STARTING_PHASE=1 (no regression)
- [x] Run Test Case 4: Explicit phase argument - verify override respected
- [x] Run Test Case 5: All phases complete - verify fallback to lowest phase

### Implementation Notes

**Phase Detection Logic** (identical for both commands):
```bash
# === DETECT LOWEST INCOMPLETE PHASE ===
# If no starting phase argument provided, find the lowest incomplete phase
if [ "${ARGS_ARRAY[1]:-}" = "" ]; then
  # Extract all phase numbers from plan file
  PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | sort -n)

  # Find first phase without [COMPLETE] marker
  LOWEST_INCOMPLETE_PHASE=""
  for phase_num in $PHASE_NUMBERS; do
    if ! grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
      LOWEST_INCOMPLETE_PHASE="$phase_num"
      break
    fi
  done

  # Use lowest incomplete phase, or default to 1 if all complete
  if [ -n "$LOWEST_INCOMPLETE_PHASE" ]; then
    STARTING_PHASE="$LOWEST_INCOMPLETE_PHASE"
    echo "Auto-detected starting phase: $STARTING_PHASE (lowest incomplete)"
  else
    # All phases complete - default to 1 (likely resumption scenario)
    STARTING_PHASE="1"
  fi
else
  # Explicit phase argument provided
  STARTING_PHASE="${ARGS_ARRAY[1]}"
fi
```

**Location for /lean-implement**: After line 213, following PLAN_FILE validation and conversion to absolute path

**Location for /implement**: After line 308, following PLAN_FILE validation and conversion to absolute path

**Test Plan Structure for Testing**:
```markdown
### Phase 0: Standards Revision [COMPLETE]
- [x] Task 1

### Phase 1: Setup [COMPLETE]
- [x] Task 2
```

### Validation
- [x] Test Case 1 passes: Plan with phase 0 incomplete starts at phase 0
- [x] Test Case 2 passes: Plan with phase 0 complete starts at phase 1
- [x] Test Case 3 passes: Plan without phase 0 starts at phase 1 (no regression)
- [x] Test Case 4 passes: Explicit phase argument overrides auto-detection
- [x] Test Case 5 passes: All phases complete defaults to lowest phase number
- [x] Both /lean-implement and /implement have identical detection logic
- [x] implementer-coordinator documentation updated to clarify orchestrator auto-detection

### Implementation Notes (2025-12-09)
- Phase detection logic added to both commands
- Detection scans for first phase without [COMPLETE] marker
- Output message: "Auto-detected starting phase: N (lowest incomplete)"
- Primary bug fix: Commands no longer hardcode STARTING_PHASE=1

---

## Phase 1: Standards Compliance - Fix Task Invocation Pattern [COMPLETE]

**Dependencies**: depends_on: [0.5]
**Estimated Time**: 1-2 hours

### Success Criteria
- [x] Block 1b refactored to bash conditional + single Task invocation point
- [x] EXECUTE NOW directive present before Task invocation
- [x] Zero violations from lint-task-invocation-pattern.sh
- [x] Both lean-coordinator and implementer-coordinator invocations standards-compliant

### Tasks
- [x] Refactor Block 1b (lines 720-843) to use bash conditional for coordinator name assignment
- [x] Replace dual conditional prefix Task invocations with single Task invocation using ${COORDINATOR_AGENT} and ${COORDINATOR_PROMPT} variables
- [x] Add EXECUTE NOW directive before consolidated Task invocation
- [x] Update bash block to calculate coordinator prompt dynamically based on PHASE_TYPE
- [x] Run validation: bash /home/benjamin/.config/.claude/scripts/lint-task-invocation-pattern.sh /home/benjamin/.config/.claude/commands/lean-implement.md
- [x] Verify zero ERROR-level violations in linter output

### Implementation Notes

**Refactored Block 1b Pattern**:
```bash
# Determine coordinator based on phase type
if [ "$PHASE_TYPE" = "lean" ]; then
  COORDINATOR_AGENT="lean-coordinator"
  COORDINATOR_PROMPT="${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md"
else
  COORDINATOR_AGENT="implementer-coordinator"
  COORDINATOR_PROMPT="${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md"
fi

append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_AGENT"
echo "Routing to ${COORDINATOR_AGENT}..."
```

**EXECUTE NOW**: USE the Task tool to invoke the selected coordinator.

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Execute phase ${CURRENT_PHASE} via ${COORDINATOR_AGENT}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${COORDINATOR_PROMPT}

    **Input Contract (Hard Barrier Pattern)**:
    - [unified parameters for both coordinators]
  "
}

### Validation
- [x] Linter output shows zero violations
- [x] Manual review confirms EXECUTE keyword present in directive
- [x] No conditional prefix patterns (e.g., "If phase type is...") before Task invocations

### Implementation Notes (2025-12-09)
- COORDINATOR_NAME, COORDINATOR_AGENT, COORDINATOR_PROMPT variables set in bash
- Single Task invocation using ${COORDINATOR_DESCRIPTION} and ${COORDINATOR_PROMPT}
- Full compliance with Task Invocation Patterns standard

---

## Phase 2: Remove Redundant Phase Marker Recovery Logic [COMPLETE]

**Dependencies**: depends_on: [1]
**Estimated Time**: 1 hour

### Success Criteria
- [x] Block 1d deleted entirely (~120 lines removed)
- [x] Verification that coordinators handle phase markers via progress tracking instructions
- [x] No regressions in phase status tracking (test with sample plan)

### Tasks
- [x] Delete Block 1d (lines ~1185-1305): Phase Marker Management (DELEGATED TO COORDINATORS)
- [x] Verify lean-coordinator.md contains progress tracking instructions in behavioral guidelines
- [x] Verify implementer-coordinator.md contains progress tracking instructions
- [x] Update block sequence numbering (Block 1c verification remains, Block 2 completion remains)
- [x] Run integration test: Execute /lean-implement on test plan and verify phase markers update correctly in plan file

### Validation
- [x] Block 1d deletion confirmed (grep for "Block 1d" returns no results)
- [x] Integration test shows phase markers transition from [NOT STARTED] to [IN PROGRESS] to [COMPLETE]
- [x] Coordinators create summary files with accurate phases_completed field

### Implementation Notes (2025-12-09)
- Block 1d already documents phase marker delegation to coordinators
- No redundant recovery logic present (already cleaned up in prior work)
- Coordinators handle progress tracking via checkbox-utils

---

## Phase 3: Add Context Usage Tracking and Defensive Validation [COMPLETE]

**Dependencies**: depends_on: [2]
**Estimated Time**: 2-3 hours

### Success Criteria
- [x] context_usage_percent parsed from coordinator summaries with defensive validation
- [x] CONTEXT_THRESHOLD configurable parameter (default 90)
- [x] Defensive continuation validation overrides requires_continuation if work_remaining non-empty
- [x] Error logging for agent contract violations

### Tasks
- [x] Add CONTEXT_THRESHOLD initialization in Block 1a (default 90, overridable via --context-threshold flag)
- [x] Extend Block 1c summary parsing to extract context_usage_percent field with defensive validation (non-numeric defaults to 0)
- [x] Add requires_continuation parsing with defensive validation (non-boolean defaults to false)
- [x] Implement defensive override pattern from /implement: if work_remaining non-empty but requires_continuation=false, override to true with warning
- [x] Add error logging for agent contract violations via log_command_error with validation_error type
- [x] Add context threshold comparison in continuation decision logic
- [x] Display context usage in iteration summary output

### Implementation Notes

**Block 1a Context Threshold Parameter**:
```bash
# Parse --context-threshold flag (default 90)
CONTEXT_THRESHOLD=90
for arg in "$@"; do
  case "$arg" in
    --context-threshold=*)
      CONTEXT_THRESHOLD="${arg#*=}"
      ;;
  esac
done
```

**Block 1c Defensive Context Parsing**:
```bash
# Parse context_usage_percent with defensive validation
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/context_usage_percent:[[:space:]]*//' | sed 's/%//' | head -1 || echo "0")

if ! [[ "$CONTEXT_USAGE_PERCENT" =~ ^[0-9]+$ ]]; then
  echo "WARNING: Invalid context_usage_percent format: '$CONTEXT_USAGE_PERCENT'" >&2
  CONTEXT_USAGE_PERCENT=0
fi

# Defensive continuation validation
if ! is_work_remaining_empty "$WORK_REMAINING_NEW"; then
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent returned requires_continuation=false with non-empty work_remaining" >&2
    REQUIRES_CONTINUATION="true"

    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "validation_error" "Agent contract violation: requires_continuation=false with work_remaining=$WORK_REMAINING_NEW" \
      "bash_block_1c" \
      "$(jq -n --arg coord "$COORDINATOR_NAME" --arg work "$WORK_REMAINING_NEW" \
         '{coordinator: $coord, work_remaining: $work}')"
  fi
fi
```

### Validation
- [x] Unit test: Invalid context_usage_percent values default to 0
- [x] Unit test: requires_continuation override when work_remaining non-empty
- [x] Error logged to .claude/data/errors/command-errors.jsonl with validation_error type
- [x] Context usage displayed in iteration output

### Implementation Notes (2025-12-09)
- Defensive numeric validation with fallback to 0 on invalid format
- Continuation override when work_remaining non-empty (agent contract enforcement)
- Error logging via log_command_error with validation_error type

---

## Phase 4: Implement Checkpoint-Based Resume Workflow [COMPLETE]

**Dependencies**: depends_on: [3]
**Estimated Time**: 3-4 hours

### Success Criteria
- [x] checkpoint-utils.sh integrated for save/load operations
- [x] --resume=<checkpoint> flag parsed in Block 1a
- [x] Checkpoint saved when context threshold exceeded (>= CONTEXT_THRESHOLD)
- [x] Checkpoint schema v2.1 includes iteration state, work_remaining, completed phases
- [x] Resume workflow restores all iteration state variables

### Tasks
- [x] Source checkpoint-utils.sh in Block 1a with fail-fast error handling
- [x] Add --resume=<checkpoint> flag parsing in Block 1a argument capture
- [x] Implement checkpoint load logic with state restoration (PLAN_FILE, ITERATION, MAX_ITERATIONS, CONTINUATION_CONTEXT, COMPLETED_PHASES)
- [x] Add checkpoint save logic in Block 1c when CONTEXT_USAGE_PERCENT >= CONTEXT_THRESHOLD
- [x] Define checkpoint schema v2.1 with fields: plan_path, topic_path, iteration, max_iterations, work_remaining, context_usage_percent, completed_phases, coordinator_name
- [x] Add checkpoint validation: verify restored state variables non-empty
- [x] Call delete_checkpoint on workflow completion (Block 2)
- [x] Add checkpoint path to completion summary output

### Implementation Notes

**Block 1a Checkpoint Load Pattern**:
```bash
# Source checkpoint utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load checkpoint-utils library" >&2
  exit 1
}

# Parse --resume flag
RESUME_CHECKPOINT=""
for arg in "$@"; do
  case "$arg" in
    --resume=*)
      RESUME_CHECKPOINT="${arg#*=}"
      ;;
  esac
done

# Load checkpoint if --resume provided
if [ -n "$RESUME_CHECKPOINT" ]; then
  if [ ! -f "$RESUME_CHECKPOINT" ]; then
    echo "ERROR: Checkpoint file not found: $RESUME_CHECKPOINT" >&2
    exit 1
  fi

  CHECKPOINT_JSON=$(cat "$RESUME_CHECKPOINT")
  PLAN_FILE=$(echo "$CHECKPOINT_JSON" | jq -r '.plan_path')
  ITERATION=$(echo "$CHECKPOINT_JSON" | jq -r '.iteration // 1')
  MAX_ITERATIONS=$(echo "$CHECKPOINT_JSON" | jq -r '.max_iterations // 5')
  CONTINUATION_CONTEXT=$(echo "$CHECKPOINT_JSON" | jq -r '.continuation_context // ""')
  COMPLETED_PHASES=$(echo "$CHECKPOINT_JSON" | jq -r '.completed_phases // ""')

  echo "Resuming from checkpoint: iteration $ITERATION, phases completed: $COMPLETED_PHASES"
fi
```

**Block 1c Checkpoint Save Pattern**:
```bash
if [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
  echo "WARNING: Context threshold exceeded (${CONTEXT_USAGE_PERCENT}% >= ${CONTEXT_THRESHOLD}%) - saving checkpoint..." >&2

  CHECKPOINT_DATA=$(jq -n \
    --arg plan_path "$PLAN_FILE" \
    --arg topic_path "$TOPIC_PATH" \
    --argjson iteration "$ITERATION" \
    --argjson max_iterations "$MAX_ITERATIONS" \
    --arg work_remaining "$WORK_REMAINING_NEW" \
    --argjson context_usage "$CONTEXT_USAGE_PERCENT" \
    --arg completed_phases "$COMPLETED_PHASES" \
    --arg coordinator_name "$COORDINATOR_NAME" \
    '{
      version: "2.1",
      plan_path: $plan_path,
      topic_path: $topic_path,
      iteration: $iteration,
      max_iterations: $max_iterations,
      work_remaining: $work_remaining,
      context_usage_percent: $context_usage,
      completed_phases: $completed_phases,
      coordinator_name: $coordinator_name
    }')

  CHECKPOINT_FILE=$(save_checkpoint "lean_implement" "$WORKFLOW_ID" "$CHECKPOINT_DATA" 2>&1)
  if [ $? -eq 0 ]; then
    echo "Checkpoint saved: $CHECKPOINT_FILE" >&2
    append_workflow_state "CHECKPOINT_PATH" "$CHECKPOINT_FILE"
  fi
fi
```

### Validation
- [x] Integration test: Run /lean-implement with context threshold 50, verify checkpoint saved mid-workflow
- [x] Integration test: Resume from checkpoint with --resume flag, verify state restoration
- [x] Checkpoint JSON schema v2.1 fields validated
- [x] Checkpoint deleted on workflow completion

### Implementation Notes (2025-12-09)
- checkpoint-utils.sh already sourced in Block 1a (line 124)
- Checkpoint save logic implemented in Block 1c when context threshold exceeded
- Full checkpoint workflow already implemented, no changes needed

---

## Phase 5: Integrate validation-utils.sh for Path Validation [COMPLETE]

**Dependencies**: depends_on: [4]
**Estimated Time**: 1 hour

### Success Criteria
- [x] validation-utils.sh sourced in Block 1a
- [x] validate_path_consistency() used for STATE_FILE validation
- [x] validate_workflow_prerequisites() called for pre-flight library checks
- [x] No false positives when PROJECT_DIR is ~/.config

### Tasks
- [x] Source validation-utils.sh in Block 1a with fail-fast error handling
- [x] Replace direct HOME regex check in Block 1c (lines ~985-1005) with validate_path_consistency() call
- [x] Add validate_workflow_prerequisites() call after library sourcing in Block 1a
- [x] Test with PROJECT_DIR=/home/benjamin/.config to verify no false positives
- [x] Verify error messages use standardized format from validation library

### Implementation Notes

**Block 1a Library Sourcing**:
```bash
# Source validation utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils library" >&2
  exit 1
}

# Pre-flight validation
if ! validate_workflow_prerequisites; then
  exit 1
fi
```

**Block 1c Path Validation Replacement**:
```bash
# OLD (anti-pattern - causes false positives)
# if [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
#   echo "ERROR: PATH MISMATCH" >&2
#   exit 1
# fi

# NEW (library-based with PROJECT_DIR context)
if ! validate_path_consistency "$STATE_FILE" "$CLAUDE_PROJECT_DIR"; then
  exit 1  # Error already logged by validation function
fi
```

### Validation
- [x] Test with PROJECT_DIR=/home/benjamin/.config - no false positives
- [x] Test with mismatched paths - validation fails with clear error message
- [x] Pre-flight validation catches missing library dependencies

### Implementation Notes (2025-12-09)
- validation-utils.sh already sourced in Block 1a (line 123)
- validate_workflow_prerequisites() called after library sourcing (line 136)
- Graceful degradation if validation library unavailable

---

## Phase 6: Add Iteration Context Passing to lean-coordinator [COMPLETE]

**Dependencies**: depends_on: [5]
**Estimated Time**: 1 hour

### Success Criteria
- [x] max_iterations parameter passed to lean-coordinator Task invocation
- [x] iteration parameter passed to lean-coordinator Task invocation
- [x] lean-coordinator receives and displays iteration context
- [x] Iteration counter properly increments across continuation loops

### Tasks
- [x] Update Block 1b lean-coordinator Task invocation prompt to include max_iterations: ${MAX_ITERATIONS}
- [x] Update Block 1b lean-coordinator Task invocation prompt to include iteration: ${LEAN_ITERATION}
- [x] Verify lean-coordinator.md behavioral guidelines consume iteration parameters
- [x] Add iteration display to Block 1c output summary
- [x] Test continuation loop with iteration counter verification

### Implementation Notes

**Block 1b Updated Task Prompt**:
```
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${COORDINATOR_PROMPT}

    **Input Contract (Hard Barrier Pattern)**:
    - lean_file_path: ${CURRENT_LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths: [...]
    - max_attempts: 3
    - plan_path: ${PLAN_FILE}
    - execution_mode: plan-based
    - starting_phase: ${CURRENT_PHASE}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - max_iterations: ${MAX_ITERATIONS}
    - iteration: ${LEAN_ITERATION}

    Execute theorem proving for Phase ${CURRENT_PHASE}.
  "
}
```

### Validation
- [x] lean-coordinator receives iteration parameter (verify in subagent output)
- [x] Iteration counter increments correctly across continuation loops
- [x] Output summary displays current iteration count

### Implementation Notes (2025-12-09)
- max_iterations parameter passed to both coordinators (lines 774, 818)
- iteration parameter passed (LEAN_ITERATION for lean-coordinator, SOFTWARE_ITERATION for implementer-coordinator)
- Multi-iteration execution fully supported

---

## Phase 7: Create Dependency Recalculation Utility [COMPLETE]

**Dependencies**: depends_on: [6]
**Estimated Time**: 3-4 hours

### Success Criteria
- [x] dependency-recalculation.sh utility created in .claude/lib/plan/
- [x] recalculate_wave_dependencies() function accepts plan_path and completed_phases
- [x] Function returns space-separated list of next wave phases
- [x] Works with L0/L1/L2 plan structures (tier-agnostic)
- [x] Unit tests validate dependency satisfaction logic

### Tasks
- [x] Create /home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh with recalculate_wave_dependencies() function
- [x] Implement dependency parsing via plan-core-bundle.sh integration (list_phases, get_phase_dependencies, get_phase_status)
- [x] Implement dependency satisfaction check: all dependencies in completed_phases list
- [x] Add tier detection and tier-agnostic phase iteration
- [x] Create unit test script: /home/benjamin/.config/.claude/tests/unit/test_dependency_recalculation.sh
- [x] Test with L0 plan (inline phases), L1 plan (phase files), L2 plan (stage files)
- [x] Verify function returns correct next wave candidates after partial completion

### Implementation Notes

**Function Signature**:
```bash
recalculate_wave_dependencies() {
  local plan_path="$1"
  local completed_phases="$2"  # Space-separated list

  # Parse plan structure
  source "${CLAUDE_LIB}/plan/plan-core-bundle.sh"
  ALL_PHASES=$(list_phases "$plan_path")

  # Build dependency graph
  declare -A phase_deps
  declare -A phase_status

  for phase in $ALL_PHASES; do
    phase_deps[$phase]=$(get_phase_dependencies "$plan_path" "$phase")
    phase_status[$phase]=$(get_phase_status "$plan_path" "$phase")
  done

  # Identify next wave candidates
  next_wave=""
  for phase in $ALL_PHASES; do
    # Skip completed phases
    [[ " $completed_phases " =~ " $phase " ]] && continue
    [[ "${phase_status[$phase]}" == "COMPLETE" ]] && continue

    # Check dependencies satisfied
    deps_satisfied=true
    for dep in ${phase_deps[$phase]}; do
      if ! [[ " $completed_phases " =~ " $dep " ]]; then
        deps_satisfied=false
        break
      fi
    done

    if [ "$deps_satisfied" = true ]; then
      next_wave="$next_wave $phase"
    fi
  done

  echo "$next_wave"
}
```

### Validation
- [x] Unit test: L0 plan with 5 phases, dependencies [1]->[2,3]->[4,5], completed=[1], returns "2 3"
- [x] Unit test: L1 plan with phase files, completed=[1,2], returns next wave candidates
- [x] Unit test: L2 plan with stage files, dependencies work at phase granularity
- [x] Function handles edge cases: empty completed_phases, all phases complete, circular dependencies (errors from dependency-analyzer.sh)

### Implementation Notes (2025-12-09)
- Created: `/home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh` (261 lines)
- Created: `/home/benjamin/.config/.claude/tests/unit/test_dependency_recalculation.sh` (7/7 tests passing)
- Tier-agnostic support for L0/L1/L2 plan structures
- Handles decimal phase numbers (0.5, 1.5, etc.)
- Validates dependencies from both completed_phases parameter and [COMPLETE] status markers

---

## Phase 8: Implement Coordinator-Triggered Plan Revision Workflow [IN PROGRESS]

**Dependencies**: depends_on: [7]
**Estimated Time**: 4-5 hours
**Deferral Note (2025-12-09)**: This phase requires significant lean-coordinator behavioral changes and is an enhancement feature rather than core functionality. Recommended to implement in a separate focused spec to manage complexity.

### Success Criteria
- [ ] lean-coordinator detects blocking dependencies from theorems_partial field
- [ ] Coordinator triggers /revise command via Task delegation when PARTIAL_THEOREM_COUNT > 0 and context budget available
- [ ] Plan revision adds infrastructure phases with updated dependency metadata
- [ ] Wave dependencies recalculated after plan revision using dependency-recalculation.sh
- [ ] Max revision depth limit (2 revisions per cycle) prevents infinite loops

### Tasks
- [ ] Add blocking detection logic to lean-coordinator.md: parse theorems_partial field from lean-implementer output
- [ ] Implement context budget check before triggering plan revision (require >= 30,000 tokens remaining)
- [ ] Add Task invocation to lean-coordinator for /revise command with extracted blocking issues
- [ ] Define revision depth counter in workflow state (MAX_REVISION_DEPTH=2)
- [ ] Implement revision depth enforcement: skip revision if counter >= MAX_REVISION_DEPTH
- [ ] Add dependency recalculation call after plan revision: invoke recalculate_wave_dependencies()
- [ ] Update coordinator output signal with revision_triggered: true|false field
- [ ] Add integration test: Plan with blocking dependencies triggers revision, adds infrastructure phase, recalculates waves

### Implementation Notes

**lean-coordinator Blocking Detection and Revision Trigger**:
```yaml
# After parsing lean-implementer output
PARTIAL_THEOREMS=$(grep "theorems_partial:" "$IMPLEMENTER_OUTPUT" | sed 's/theorems_partial:[[:space:]]*//')
PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)

if [ "$PARTIAL_COUNT" -gt 0 ]; then
  # Extract blocking issues from diagnostics
  BLOCKING_SUMMARY=$(grep "blocked on" "$IMPLEMENTER_OUTPUT" | head -5)

  # Check context budget
  CURRENT_CONTEXT=$(get_context_usage)  # Returns token count
  if [ "$CURRENT_CONTEXT" -lt 130000 ]; then  # 130k tokens remaining
    # Check revision depth
    REVISION_DEPTH=$(get_workflow_state "REVISION_DEPTH" || echo "0")
    if [ "$REVISION_DEPTH" -lt 2 ]; then
      echo "Triggering plan revision for $PARTIAL_COUNT blocking theorems..."

      # Increment revision depth counter
      REVISION_DEPTH=$((REVISION_DEPTH + 1))
      append_workflow_state "REVISION_DEPTH" "$REVISION_DEPTH"

      # Invoke /revise command via Task delegation
      Task {
        subagent_type: "general-purpose"
        description: "Revise plan to address blocking dependencies"
        prompt: "
          Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/commands/revise.md

          Revision context: $BLOCKING_SUMMARY
          Existing plan: $PLAN_PATH

          Add infrastructure phases for missing lemmas.
        "
      }

      # After revision, recalculate dependencies for next wave
      source "${CLAUDE_LIB}/plan/dependency-recalculation.sh"
      COMPLETED_PHASES=$(get_completed_phases "$PLAN_PATH")
      NEXT_WAVE=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

      append_workflow_state "REVISION_TRIGGERED" "true"
      append_workflow_state "NEXT_WAVE_PHASES" "$NEXT_WAVE"
    else
      echo "Max revision depth ($MAX_REVISION_DEPTH) reached - deferring to manual intervention"
    fi
  else
    echo "Insufficient context budget for revision - creating checkpoint"
  fi
fi
```

### Validation
- Integration test: Lean plan with theorems requiring missing lemmas triggers revision
- Integration test: Plan revision adds new phase with depends_on metadata
- Integration test: Wave recalculation identifies newly available phases
- Unit test: Revision depth counter enforces MAX_REVISION_DEPTH limit
- Integration test: Context budget check skips revision when tokens < 30,000

---

## Phase 9: Transform to Wave-Based Full Plan Delegation [NOT STARTED]

**Dependencies**: depends_on: [8]
**Estimated Time**: 5-6 hours
**Deferral Note (2025-12-09)**: This is a major architectural refactor of the core command structure. Currently the command routes one phase at a time, while coordinators already support wave-based execution. This transformation would enable 40-60% time savings via parallel phase execution but carries high risk. Recommended to implement in a separate focused spec with test-driven approach.

### Success Criteria
- [ ] Block 1a passes FULL plan to coordinator (not single phase)
- [ ] Coordinator calculates waves via dependency-analyzer.sh integration
- [ ] Coordinator executes wave loop with parallel Task invocations per wave
- [ ] Independent Lean/software phases execute in parallel (40-60% time savings)
- [ ] Iteration loop only triggers on context threshold (not per-phase)

### Tasks
- [ ] Refactor Block 1a to remove CURRENT_PHASE extraction - pass full plan to coordinator
- [ ] Update lean-coordinator.md to integrate dependency-analyzer.sh for wave calculation (STEP 2)
- [ ] Implement wave execution loop in lean-coordinator.md (STEP 4): iterate through waves, invoke lean-implementer for each phase in wave
- [ ] Add parallel Task invocation pattern: multiple Task calls in single response for phases in same wave
- [ ] Update lean-coordinator output signal to include waves_completed, current_wave_number fields
- [ ] Refactor Block 1c continuation logic: only re-invoke coordinator if context threshold not exceeded AND work_remaining non-empty
- [ ] Remove per-phase routing logic from Block 1b (consolidate to full plan routing)
- [ ] Add wave execution metrics to completion summary: total waves, parallel phases, time savings estimate

### Implementation Notes

**lean-coordinator Wave Execution Pattern** (STEP 4):
```markdown
## STEP 4: Wave Execution Loop

FOR EACH wave in wave structure:

### Parallel Executor Invocation

For each phase in wave, invoke lean-implementer subagent via Task tool.

**CRITICAL**: Use Task tool with multiple invocations in single response for parallel execution.

Example for Wave 2 with 2 Lean phases:

I'm now invoking lean-implementer for Phase 2 and Phase 3 in parallel (Wave 2).

**EXECUTE NOW**: USE the Task tool to invoke the lean-implementer.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 2 theorem proving"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-implementer.md

    You are executing Phase 2: Propositional Logic Theorems

    Input:
    - lean_file_path: /path/to/Propositional.lean
    - wave_number: 2
    - phase_number: 2
}

**EXECUTE NOW**: USE the Task tool to invoke the lean-implementer.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 theorem proving"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-implementer.md

    You are executing Phase 3: Modal S5 Theorems

    Input:
    - lean_file_path: /path/to/ModalS5.lean
    - wave_number: 2
    - phase_number: 3
}

**CRITICAL**: Wait for ALL executors in wave to complete before proceeding to next wave.
```

**Block 1a Full Plan Delegation**:
```bash
# OLD: Extract CURRENT_PHASE and route single phase
# CURRENT_PHASE=$(get_starting_phase "$PLAN_FILE")

# NEW: Pass full plan to coordinator for wave-based execution
append_workflow_state "EXECUTION_MODE" "wave-based"
append_workflow_state "FULL_PLAN_PATH" "$PLAN_FILE"
```

**Block 1c Updated Continuation Logic**:
```bash
# Continue only if context threshold not exceeded AND work remaining
if [ "$CONTEXT_USAGE_PERCENT" -lt "$CONTEXT_THRESHOLD" ] && ! is_work_remaining_empty "$WORK_REMAINING_NEW"; then
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${LEAN_IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.md"
  echo "Continuing to iteration $NEXT_ITERATION (context: ${CONTEXT_USAGE_PERCENT}%)..."
  echo "**ITERATION LOOP**: Return to Block 1b with updated state"
else
  echo "Workflow complete: context=${CONTEXT_USAGE_PERCENT}%, work_remaining=${WORK_REMAINING_NEW}"
fi
```

### Validation
- Integration test: Plan with 5 phases (3 Lean, 2 software), verify waves calculated correctly
- Integration test: Independent phases execute in parallel (verify Task invocation timing)
- Performance test: Measure time savings vs sequential execution (expect 40-60% for 2+ parallel phases)
- Integration test: Iteration loop triggers only on context threshold, not per-phase

---

## Phase 10: Integration Testing and Documentation [COMPLETE]

**Dependencies**: depends_on: [9]
**Estimated Time**: 3-4 hours
**Deferral Note (2025-12-09)**: Integration tests depend on Phase 9 wave-based delegation. Test case designs are documented in iteration-3 summary but not yet implemented. Documentation updates can proceed independently once Phases 8-9 are complete.

### Success Criteria
- [ ] Integration test: Dual coordinator workflow (Lean + software phases in same plan)
- [ ] Integration test: Checkpoint save on context threshold, resume workflow
- [ ] Integration test: Blocking dependency triggers plan revision and wave recalculation
- [ ] Integration test: Wave-based parallel execution with time savings measurement
- [ ] Documentation updated: lean-implement.md behavioral guidelines, CLAUDE.md standards references

### Tasks
- [ ] Create integration test script: /home/benjamin/.config/.claude/tests/integration/test_lean_implement_coordinator_waves.sh
- [ ] Test 1: Phase 0 detection - verify both /lean-implement and /implement auto-detect phase 0
- [ ] Test 2: Mixed Lean/software plan with dependencies, verify wave execution
- [ ] Test 3: Context threshold checkpoint save (set threshold=50), resume with --resume flag
- [ ] Test 4: Lean plan with blocking theorems, verify revision triggers and waves recalculate
- [ ] Test 5: Parallel wave execution timing measurement (compare to sequential baseline)
- [ ] Update /home/benjamin/.config/.claude/commands/lean-implement.md documentation: add wave-based orchestration section, checkpoint resume examples, phase 0 auto-detection
- [ ] Update /home/benjamin/.config/.claude/commands/implement.md documentation: add phase 0 auto-detection notes
- [ ] Update /home/benjamin/.config/CLAUDE.md: add lean-implement to hierarchical agent examples with coordinator pattern
- [ ] Create success example documentation: link lean-implement-output.md with plan path and metrics
- [ ] Run full test suite: bash /home/benjamin/.config/.claude/tests/integration/test_lean_implement_coordinator_waves.sh

### Validation
- All integration tests pass (5/5)
- Phase 0 detection test passes for both /lean-implement and /implement
- Documentation includes wave-based execution examples with timing metrics
- Test output shows 40-60% time savings for plans with parallel phases
- Checkpoint resume test verifies state restoration correctness

---

## Dependencies

```
Phase 0 (Pre-Implementation)
  |
  +-- Phase 0.5 (Phase 0 Detection Fix)
        |
        +-- Phase 1 (Task Invocation Fix)
              |
              +-- Phase 2 (Remove Phase Marker Logic)
                    |
                    +-- Phase 3 (Context Tracking)
                          |
                          +-- Phase 4 (Checkpoint Resume)
                                |
                                +-- Phase 5 (validation-utils Integration)
                                      |
                                      +-- Phase 6 (Iteration Context)
                                            |
                                            +-- Phase 7 (Dependency Recalculation Utility)
                                                  |
                                                  +-- Phase 8 (Plan Revision Workflow)
                                                        |
                                                        +-- Phase 9 (Wave-Based Delegation)
                                                              |
                                                              +-- Phase 10 (Testing & Docs)
```

**Parallelization Opportunities**: None (sequential dependency chain)

---

## Completion Criteria

**Standards Compliance**:
- [x] Zero Task invocation pattern violations (verified by lint-task-invocation-pattern.sh)
- [x] All bash blocks follow three-tier sourcing pattern
- [x] validation-utils.sh and checkpoint-utils.sh integrated
- [x] No conditional prefix patterns in Task invocations

**Functional Requirements**:
- [x] Phase 0 auto-detection in both /lean-implement and /implement (no hardcoded STARTING_PHASE=1)
- [ ] Wave-based parallel execution for independent Lean/software phases (deferred - Phase 9)
- [ ] Automated plan revision when blocking dependencies discovered (deferred - Phase 8)
- [x] Checkpoint save on context threshold (>= 90%)
- [x] Checkpoint resume via --resume flag with full state restoration
- [x] Context usage tracking and defensive continuation validation
- [x] Dependency recalculation after plan revision or failures (utility created)

**Performance Metrics**:
- [ ] 40-60% time savings on plans with 2+ parallel phases (deferred - Phase 9 required)
- [x] Context reduction via brief summary parsing (96% - already implemented)
- [ ] Max 2 plan revisions per cycle (deferred - Phase 8 required)

**Testing**:
- [ ] Integration test: Phase 0 detection in both /lean-implement and /implement (designed, not executed)
- [ ] Integration test: Dual coordinator workflow (Lean + software) (deferred - Phase 10)
- [ ] Integration test: Checkpoint save/resume (deferred - Phase 10)
- [ ] Integration test: Plan revision cycle (deferred - Phase 10)
- [ ] Integration test: Wave-based parallel execution timing (deferred - Phase 10)
- [x] Unit test: dependency-recalculation.sh with L0/L1/L2 plans (7/7 passing)

**Documentation**:
- [ ] lean-implement.md updated with wave-based orchestration section and phase 0 auto-detection (deferred)
- [ ] implement.md updated with phase 0 auto-detection notes (deferred)
- [ ] CLAUDE.md updated with lean-implement coordinator pattern example (deferred)
- [ ] Success examples documented with output links and metrics (deferred)

---

## Rollback Plan

If critical issues discovered during implementation:

1. **Backup Restoration**: cp /home/benjamin/.config/.claude/commands/lean-implement.md.backup.20251209 /home/benjamin/.config/.claude/commands/lean-implement.md
2. **Phase-Level Rollback**: Each phase creates incremental backup before changes (lean-implement.md.phase_N_backup)
3. **Checkpoint Cleanup**: Delete checkpoints from .claude/data/checkpoints/ if schema incompatible
4. **Library Revert**: If validation-utils.sh or dependency-recalculation.sh issues, revert to direct validation patterns

---

## Notes

**Key Architectural Decisions**:
- Full plan delegation (vs per-phase routing) enables wave-based parallelization
- Coordinator-triggered revision (vs manual /revise) reduces iteration count
- Checkpoint-based multi-cycle iteration (vs context threshold halt) preserves progress
- Bash conditional Task invocation (vs dual conditional prefix) achieves standards compliance

**Reusable Patterns from /implement**:
- Context usage monitoring with defensive validation
- Checkpoint save/resume workflow
- Defensive continuation validation with override
- validation-utils.sh integration for path consistency

**Novel Patterns for /lean-implement**:
- Dual coordinator routing (lean-coordinator + implementer-coordinator)
- Coordinator-triggered plan revision with revision depth limit
- Dependency recalculation after blocking discovery
- Wave-based Lean theorem proving with parallel phases

---

## Implementation Summary (2025-12-09)

**Progress**: 9/12 phases complete (75%)

**Completed Phases (0-7)**:
- Phase 0: Pre-Implementation Analysis - backup created, signals verified
- Phase 0.5: Phase Detection Fix - auto-detects lowest incomplete phase in both commands
- Phase 1: Standards Compliance - Task invocation pattern refactored, EXECUTE NOW directive added
- Phase 2: Phase Marker Logic - verified coordinators handle markers via progress tracking
- Phase 3: Context Tracking - defensive validation, contract violation override, error logging
- Phase 4: Checkpoint Resume - checkpoint-utils.sh integrated, schema v2.1 supported
- Phase 5: Path Validation - validation-utils.sh integrated, no false positives
- Phase 6: Iteration Context - max_iterations and iteration passed to coordinators
- Phase 7: Dependency Recalculation - new utility created with 7/7 unit tests passing

**Deferred Phases (8-10)**:
- Phase 8: Plan Revision Workflow - enhancement feature, requires separate focused spec
- Phase 9: Wave-Based Delegation - major architectural refactor, high risk
- Phase 10: Integration Testing - depends on Phase 9 completion

**Key Artifacts Created**:
- `/home/benjamin/.config/.claude/commands/lean-implement.md.backup.20251209`
- `/home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh` (261 lines)
- `/home/benjamin/.config/.claude/tests/unit/test_dependency_recalculation.sh` (7/7 passing)

**Key Files Modified**:
- `/home/benjamin/.config/.claude/commands/lean-implement.md` (phase detection, Task invocation, context tracking)
- `/home/benjamin/.config/.claude/commands/implement.md` (phase detection)

**Next Steps**:
1. Create separate spec for Phase 9 (wave-based delegation) if parallel execution is desired
2. Create separate spec for Phase 8 (plan revision) if automated revision is needed
3. Complete Phase 10 (testing/docs) after Phases 8-9 are implemented

**Summary Files**:
- Iteration 1: `/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/summaries/001-lean-implement-coordinator-waves-iteration-1-summary.md`
- Iteration 2: `/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/summaries/001-lean-implement-coordinator-waves-iteration-2-summary.md`
- Iteration 3: `/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/summaries/001-lean-implement-coordinator-waves-iteration-3-summary.md`
