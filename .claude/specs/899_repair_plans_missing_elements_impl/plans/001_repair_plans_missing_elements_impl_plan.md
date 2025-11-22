# Build Iteration Infrastructure Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Revised**: 2025-11-21
- **Feature**: Build iteration loop infrastructure with context monitoring and checkpoint integration
- **Scope**: Implement missing iteration infrastructure for /build command - excludes obsolete command-init.sh (Phase 1 from Plan 885) and already-implemented features
- **Estimated Phases**: 5
- **Estimated Hours**: 17
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 104.5
- **Research Reports**:
  - [Missing Elements Analysis](/home/benjamin/.config/.claude/specs/899_repair_plans_missing_elements_impl/reports/001_missing_elements_analysis.md)
  - [Repair Plans Relevance Review](/home/benjamin/.config/.claude/specs/898_repair_plans_relevance_review/reports/001_repair_plans_relevance_analysis.md)
  - [Original Unified Repair Plan](/home/benjamin/.config/.claude/specs/885_repair_plans_research_analysis/plans/001_repair_plans_research_analysis_plan.md)

## Overview

This focused plan implements the **remaining critical infrastructure** for /build iteration support, based on comprehensive analysis of Plan 885 that identified which elements are still relevant and missing. The research determined that 70% of the original plan is either already implemented or unnecessary, leaving three core features requiring implementation.

### Key Objectives

1. **Enable Large Plan Support**: Transform /build from single-shot to persistent iteration loop supporting 40+ phase plans
2. **Implement Context Safety**: Add context monitoring and graceful halt at 90% threshold to prevent overflow
3. **Complete Checkpoint Integration**: Add iteration-specific fields to checkpoint schema for resumption
4. **Document Iteration Patterns**: Update existing documentation with new persistence behavior

### Excluded from This Plan (With Rationale)

| Original Phase | Reason for Exclusion |
|----------------|---------------------|
| Phase 1: command-init.sh | **Root cause misdiagnosed** - Exit code 127 errors are from subprocess boundaries, not sourcing failures. Three-tier sourcing in build.md (lines 78-93) works correctly. |
| Phase 2: Exit Code Pattern Audit | **Low value** - Pattern works correctly, not causing production errors |
| Phase 3: Test Script Validation | **Low value** - Minor cleanup, not blocking |
| Phase 4: Topic Naming Diagnostics | **Already implemented** - Agent errors now logged with context via validate_agent_output functions |
| Phase 8: State Transition Diagnostics | **Already implemented** - sm_transition() has validation in workflow-state-machine.sh (lines 603-664) |

### Research Synthesis

Research analysis revealed critical implementation gaps and clarifications:

**Agent Infrastructure Ready**: The implementer-coordinator agent already supports:
- `continuation_context` parameter (line 32)
- `iteration` parameter (line 33)
- `work_remaining` return field (lines 170, 200, 401)

**Implementation Gap**: /build command does NOT:
- Pass continuation_context or iteration to agent
- Parse work_remaining from agent output
- Implement iteration loop
- Check context thresholds
- Detect stuck states

**Checkpoint Schema**: Version 2.1 exists but iteration fields are NOT utilized:
- `iteration`, `work_remaining`, `last_work_remaining`, `halt_reason` fields present in schema but not populated

## Success Criteria

- [ ] /build successfully completes 12-phase plan in 2-3 iterations
- [ ] /build gracefully halts at 90% context threshold and creates resumption checkpoint
- [ ] Stuck detection prevents infinite loops (work_remaining unchanged for 2 iterations)
- [ ] Checkpoint v2.1 iteration fields are populated and validated on load
- [ ] Resumption from iteration checkpoint restores correct state
- [ ] All new iteration logic has unit and integration tests
- [ ] Documentation updated with persistent workflow patterns and examples
- [ ] All bash blocks follow mandatory three-tier sourcing pattern (validated by `check-library-sourcing.sh`)
- [ ] Tests use proper isolation (CLAUDE_TEST_MODE=1, temp CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR)
- [ ] Pre-commit validation passes: `bash .claude/scripts/validate-all-standards.sh --sourcing --suppression --conditionals`

## Technical Design

### Architecture Overview

```
+-------------------------------------------------------------+
|                     /build Command                           |
|  +---------------------------+                              |
|  | Iteration Loop Controller |                              |
|  | - MAX_ITERATIONS=5        |                              |
|  | - ITERATION counter       |                              |
|  | - CONTINUATION_CONTEXT    |                              |
|  | - work_remaining parser   |                              |
|  +-------------+-------------+                              |
|                |                                            |
+----------------v--------------------------------------------+
                 |
+----------------v--------------------------------------------+
|              Context Monitor                                 |
|  +---------------------------+                              |
|  | estimate_context_usage()  | <-- NEW FUNCTION             |
|  | - base: 20k tokens        |                              |
|  | - completed: 15k/phase    |                              |
|  | - remaining: 12k/phase    |                              |
|  +---------------------------+                              |
|  | 90% threshold check       |                              |
|  | save_resumption_chkpt()   |                              |
+-------------------------------------------------------------+
                 |
+----------------v--------------------------------------------+
|          Checkpoint v2.1 (Extended)                         |
|  +---------------------------+                              |
|  | iteration: 3              | <-- NEW FIELDS               |
|  | max_iterations: 5         |                              |
|  | work_remaining: [p8,p9]   |                              |
|  | last_work_remaining: ...  |                              |
|  | halt_reason: context      |                              |
|  +---------------------------+                              |
+-------------------------------------------------------------+
                 |
+----------------v--------------------------------------------+
|        Implementer-Coordinator Agent                        |
|  +---------------------------+                              |
|  | continuation_context      | <-- ALREADY SUPPORTED        |
|  | iteration                 |                              |
|  | work_remaining (output)   |                              |
|  +---------------------------+                              |
+-------------------------------------------------------------+
```

### Key Components

**1. Iteration Loop Controller (Phase 1)**
- MAX_ITERATIONS: Default 5, configurable via --max-iterations flag
- ITERATION counter: Tracks current iteration (1-based)
- CONTINUATION_CONTEXT: Path to previous iteration summary
- work_remaining parser: Extracts incomplete phases from agent output
- Graceful exit on completion (work_remaining empty) or stuck (unchanged for 2 iterations)

**2. Context Monitor (Phase 2)**
- estimate_context_usage(): Heuristic calculation
- Formula: `base(20k) + completed_phases(15k) + remaining_phases(12k) + continuation(5k)`
- 90% threshold check before each iteration
- save_resumption_checkpoint(): Creates checkpoint with iteration state

**3. Checkpoint v2.1 Integration (Phase 3)**
- Populate iteration fields during /build execution
- Validate iteration fields on checkpoint load
- Enable resumption from specific iteration

### Integration Points

**Existing Systems (No Changes)**:
- implementer-coordinator agent: Already supports continuation_context and iteration
- checkpoint-utils.sh: Schema v2.1 already defined
- workflow-state-machine.sh: State transitions work correctly

**Modified Systems**:
- /build command: Add iteration loop, context monitoring, work_remaining parsing
- checkpoint-utils.sh: Ensure iteration fields are populated and validated

## Implementation Phases

### Phase 1: /build Iteration Loop [COMPLETE]
dependencies: []

**Objective**: Transform /build from single-shot to persistent iteration loop supporting large plans

**Complexity**: High

**Tasks**:
- [x] Add MAX_ITERATIONS variable to `/home/benjamin/.config/.claude/commands/build.md` (default 5, configurable via --max-iterations flag)
- [x] Add ITERATION counter initialization (ITERATION=1) before main execution block
- [x] Add CONTINUATION_CONTEXT variable (null for first iteration)
- [x] Add LAST_WORK_REMAINING variable for stuck detection
- [x] Wrap implementer-coordinator invocation in while loop: `while [ $ITERATION -le $MAX_ITERATIONS ]; do`
- [x] Pass continuation_context and iteration parameters to implementer-coordinator agent
- [x] Parse work_remaining from agent output JSON using jq
- [x] Add completion exit condition: `if [ -z "$work_remaining" ]; then exit 0; fi`
- [x] Add stuck detection: compare work_remaining to LAST_WORK_REMAINING, exit error if unchanged for 2 iterations
- [x] Set CONTINUATION_CONTEXT to previous iteration summary path before next iteration
- [x] Increment ITERATION counter: `ITERATION=$((ITERATION + 1))`
- [x] Add max iterations exceeded error handling with log_command_error

**Implementation Pattern**:

**IMPORTANT**: This iteration loop runs in a bash block that requires the mandatory three-tier library sourcing pattern per [code-standards.md](../../docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern). Each bash block in Claude Code runs in a new subprocess - libraries sourced in previous blocks are NOT available.

```bash
# In build.md iteration loop bash block:
set +H  # CRITICAL: Disable history expansion

# === THREE-TIER LIBRARY SOURCING (MANDATORY) ===
# Tier 1: Bootstrap - Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi
export CLAUDE_PROJECT_DIR

# Tier 1: Critical Foundation Libraries (FAIL-FAST REQUIRED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2/3: Optional Libraries (graceful degradation allowed)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || true

# === LOAD WORKFLOW STATE (subprocess isolation) ===
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false
fi

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists
COMMAND_NAME="/build"
USER_ARGS="${PLAN_FILE:-unknown}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === ITERATION LOOP VARIABLES ===
MAX_ITERATIONS="${MAX_ITERATIONS:-5}"
ITERATION="${ITERATION:-1}"
CONTINUATION_CONTEXT="${CONTINUATION_CONTEXT:-}"
LAST_WORK_REMAINING="${LAST_WORK_REMAINING:-}"
STUCK_COUNT="${STUCK_COUNT:-0}"

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "=== Iteration $ITERATION/$MAX_ITERATIONS ===" >&2

  # Invoke implementer-coordinator with continuation parameters
  # (add continuation_context: $CONTINUATION_CONTEXT, iteration: $ITERATION to Task)

  # Parse work_remaining from agent output
  work_remaining=$(echo "$AGENT_OUTPUT" | jq -r '.work_remaining // [] | join(",")')

  # Check completion
  if [ -z "$work_remaining" ] || [ "$work_remaining" = "0" ]; then
    echo "Implementation complete" >&2
    exit 0
  fi

  # Check stuck state (unchanged for 2 iterations)
  if [ "$work_remaining" = "$LAST_WORK_REMAINING" ]; then
    STUCK_COUNT=$((STUCK_COUNT + 1))
    if [ $STUCK_COUNT -ge 2 ]; then
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "execution_error" \
        "Iteration stuck - work_remaining unchanged for 2 iterations" \
        "iteration_loop" \
        "$(jq -n --argjson iter "$ITERATION" --arg work "$work_remaining" '{iteration: $iter, work_remaining: $work}')"
      echo "ERROR: Stuck - work_remaining unchanged for 2 iterations" >&2
      exit 1
    fi
  else
    STUCK_COUNT=0
  fi

  # Persist state for next iteration (subprocess isolation)
  append_workflow_state "ITERATION" "$((ITERATION + 1))"
  append_workflow_state "LAST_WORK_REMAINING" "$work_remaining"
  append_workflow_state "CONTINUATION_CONTEXT" "${BUILD_WORKSPACE}/iteration_${ITERATION}_summary.md"

  # Prepare for next iteration
  LAST_WORK_REMAINING="$work_remaining"
  CONTINUATION_CONTEXT="${BUILD_WORKSPACE}/iteration_${ITERATION}_summary.md"
  ITERATION=$((ITERATION + 1))
done

log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "execution_error" \
  "Max iterations exceeded" \
  "iteration_loop" \
  "$(jq -n --argjson max "$MAX_ITERATIONS" '{max_iterations: $max}')"
echo "ERROR: Max iterations ($MAX_ITERATIONS) exceeded" >&2
exit 1
```

**Testing**:
```bash
# === TEST ISOLATION (REQUIRED per testing-protocols.md) ===
export CLAUDE_TEST_MODE=1
TEST_ROOT="/tmp/test_build_iteration_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
mkdir -p "$TEST_ROOT/.claude/tmp"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Test: Small plan completes in 1 iteration
# Create 2-phase plan, verify ITERATION=1 and work_remaining empty

# Test: Medium plan completes in 2-3 iterations
# Create 8-phase plan, verify ITERATION=2 or 3 and work_remaining empty

# Test: Max iterations exceeded
# Create plan with 100 phases, verify exit code 1 after 5 iterations

# Test: Stuck detection triggers after 2 unchanged iterations
# Mock agent output with unchanged work_remaining, verify exit code 1

# === PRE-COMMIT VALIDATION (REQUIRED before merge) ===
# Validate three-tier sourcing compliance
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/build.md

# Validate error suppression compliance
bash .claude/tests/utilities/lint_error_suppression.sh

# Validate preprocessing-safe conditionals
bash .claude/tests/utilities/lint_bash_conditionals.sh
```

**Expected Duration**: 4 hours

### Phase 2: Context Monitoring and Graceful Halt [COMPLETE]
dependencies: [1]

**Objective**: Add context estimation heuristic and graceful halt at 90% threshold to prevent context overflow

**Complexity**: High

**Tasks**:
- [x] Create estimate_context_usage() function in `/home/benjamin/.config/.claude/commands/build.md`
  - Calculate base context: plan file size estimate + standards overhead
  - Add per-completed-phase estimate: 15000 tokens average
  - Add per-remaining-phase estimate: 12000 tokens average
  - Add continuation context cost: 5000 tokens if resuming
  - Return total estimated context usage
- [x] Add CONTEXT_THRESHOLD variable (default 0.90, configurable via --context-threshold flag)
- [x] Add MAX_CONTEXT constant (200000 tokens for Claude Sonnet)
- [x] Add context check before each iteration: `if [ $(estimate_context_usage) -ge $((MAX_CONTEXT * 90 / 100)) ]; then`
- [x] Create save_resumption_checkpoint() function
  - Generate checkpoint with iteration state
  - Save to `.claude/tmp/checkpoints/build_${WORKFLOW_ID}_iteration_${ITERATION}.json`
  - Use atomic write pattern (temp file + mv)
- [x] Call save_resumption_checkpoint() on context threshold halt
- [x] Log halt event with log_command_error (error_type="execution_error", message="Context threshold halt")
- [x] Exit with code 0 and display resumption instructions

**Context Estimation Formula**:
```bash
estimate_context_usage() {
  local completed_phases="$1"
  local remaining_phases="$2"
  local has_continuation="$3"

  local base=20000  # Plan file + standards + system prompt
  local completed_cost=$((completed_phases * 15000))
  local remaining_cost=$((remaining_phases * 12000))
  local continuation_cost=0

  if [ "$has_continuation" = "true" ]; then
    continuation_cost=5000
  fi

  echo $((base + completed_cost + remaining_cost + continuation_cost))
}
```

**Testing**:
```bash
# Test: Context estimation returns reasonable values
# estimate_context_usage 0 4 false -> expect ~68000
# estimate_context_usage 2 2 true -> expect ~79000

# Test: Graceful halt at 90% threshold
# Create large plan (30+ phases) with estimated context >180k
# Verify halt occurs before context overflow
# Verify checkpoint created with iteration state

# Test: Resumption from context halt checkpoint
# Load checkpoint, verify iteration and continuation_context restored
```

**Expected Duration**: 3 hours

### Phase 3: Checkpoint v2.1 Iteration Integration [COMPLETE]
dependencies: [1, 2]

**Objective**: Ensure checkpoint v2.1 iteration fields are populated during /build execution and validated on load

**Complexity**: Medium

**Tasks**:
- [x] Update save_resumption_checkpoint() to include all v2.1 iteration fields:
  - iteration (current iteration number)
  - max_iterations (configured limit)
  - continuation_context (path to previous summary)
  - work_remaining (list of incomplete phases)
  - last_work_remaining (for stuck detection comparison)
  - context_estimate (current estimated context usage)
  - halt_reason (context_threshold, max_iterations, stuck, completion)
- [x] Verify checkpoint-utils.sh load_checkpoint() handles iteration fields
- [x] Add validate_iteration_checkpoint() function to validate iteration-specific fields
  - Check iteration count <= max_iterations
  - Verify continuation_context file exists if not null
  - Validate work_remaining is valid JSON array
- [x] Call validate_iteration_checkpoint() before resuming from checkpoint
- [x] Add --resume flag support to /build for loading iteration checkpoint
- [x] Handle checkpoint validation errors gracefully (log error, suggest --force-restart)

**Checkpoint v2.1 Schema with Iteration Fields**:
```json
{
  "version": "2.1",
  "timestamp": "2025-11-21T12:34:56Z",
  "plan_path": "/home/benjamin/.config/.claude/specs/042_auth/plans/001_user_auth.md",
  "iteration": 3,
  "max_iterations": 5,
  "continuation_context": "/home/benjamin/.config/.claude/tmp/build_12345/iteration_2_summary.md",
  "work_remaining": ["phase_8", "phase_9", "phase_10"],
  "last_work_remaining": ["phase_8", "phase_9", "phase_10", "phase_11"],
  "context_estimate": 185000,
  "halt_reason": "context_threshold"
}
```

**Testing**:
```bash
# Test: Checkpoint v2.1 write includes all iteration fields
# Create checkpoint during iteration 3, verify all fields present

# Test: Checkpoint load restores iteration state
# Load checkpoint with iteration=2, verify ITERATION=2 after load

# Test: Validation catches invalid checkpoints
# - iteration > max_iterations (should fail)
# - missing continuation_context file (should warn)
# - invalid work_remaining format (should fail)

# Test: --resume flag loads and validates checkpoint
# /build --resume /path/to/checkpoint.json
```

**Expected Duration**: 2.5 hours

### Phase 4: Documentation Updates [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Document persistent workflow patterns, iteration behavior, and troubleshooting guidance

**Complexity**: Medium

**Tasks**:
- [x] Add "Persistence Behavior" section to `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` (~100 lines)
  - How /build detects incomplete plans
  - Iteration loop execution flow
  - Context threshold halt and resumption
  - Max iterations exceeded handling
  - Stuck state detection and recovery
  - Troubleshooting common iteration issues
- [x] Add "Persistent Workflows" section to `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` (~100 lines)
  - Overview of iteration loop architecture
  - Context monitoring and graceful halt strategy
  - Checkpoint v2.1 iteration fields
  - Stuck detection logic and resolution
- [x] Add "Multi-Iteration Execution" examples to `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (~80 lines)
  - Iteration 1 (fresh start): continuation_context null, iteration 1
  - Iteration 2 (continuation): continuation_context set, iteration 2
  - Completion scenario: work_remaining empty
  - Halt scenario: context threshold reached
- [x] Update command reference in CLAUDE.md if needed (--max-iterations, --context-threshold, --resume flags)

**Testing**:
```bash
# Test: All markdown syntax valid
# markdownlint on updated files

# Test: All internal links work
# Extract markdown links, verify targets exist

# Test: Code examples are syntactically correct
# Extract bash blocks, run shellcheck
```

**Expected Duration**: 2.5 hours

### Phase 5: Testing and Validation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Ensure comprehensive test coverage for all new iteration functionality

**Complexity**: High

**Tasks**:
- [x] Create unit tests for estimate_context_usage() (`/home/benjamin/.config/.claude/tests/unit/test_context_estimation.sh`)
  - Test with varying plan sizes (2-phase, 10-phase, 30-phase)
  - Test with varying completion states (0%, 50%, 100%)
  - Test with and without continuation_context
- [x] Create unit tests for stuck detection logic (`/home/benjamin/.config/.claude/tests/unit/test_stuck_detection.sh`)
  - Test work_remaining unchanged for 2 iterations (should trigger stuck)
  - Test work_remaining reduced each iteration (should not trigger stuck)
  - Test work_remaining empty (should exit success)
- [x] Create unit tests for validate_iteration_checkpoint() (`/home/benjamin/.config/.claude/tests/unit/test_checkpoint_iteration.sh`)
  - Test valid checkpoint with all iteration fields
  - Test invalid iteration count (> max_iterations)
  - Test missing continuation_context file
  - Test invalid work_remaining format
- [x] Create integration tests for iteration loop (`/home/benjamin/.config/.claude/tests/integration/test_build_iteration.sh`)
  - Test 1-iteration plan (4 phases, completes in single iteration)
  - Test 2-iteration plan (8 phases, completes in 2 iterations)
  - Test context halt (30-phase plan simulation)
  - Test max iterations exceeded (mock many phases)
  - Test stuck detection trigger
  - Test resumption from checkpoint
- [x] Create E2E test with real multi-phase plan (`/home/benjamin/.config/.claude/tests/e2e/test_build_iteration_e2e.sh`)
  - Create 8-phase test plan
  - Run /build and verify completion or graceful halt
  - If halted, verify checkpoint created and resumption works
- [x] Update run_all_tests.sh to include new test suites
  - Add unit tests section for iteration
  - Add integration tests section for iteration
  - Add E2E tests section

**Test Coverage Targets**:
- Unit tests: >95% coverage for new functions
- Integration tests: All iteration scenarios covered
- E2E tests: At least 1 real plan test

**Testing**:
```bash
# Run all iteration-related tests
bash /home/benjamin/.config/.claude/tests/unit/test_context_estimation.sh
bash /home/benjamin/.config/.claude/tests/unit/test_stuck_detection.sh
bash /home/benjamin/.config/.claude/tests/unit/test_checkpoint_iteration.sh
bash /home/benjamin/.config/.claude/tests/integration/test_build_iteration.sh
bash /home/benjamin/.config/.claude/tests/e2e/test_build_iteration_e2e.sh

# Verify all tests pass
# Total expected: 25+ test cases
```

**Expected Duration**: 5 hours

## Testing Strategy

### Unit Testing
- **Target**: Individual functions (estimate_context_usage, validate_iteration_checkpoint, stuck detection)
- **Approach**: Isolated tests with known inputs and expected outputs
- **Coverage Goal**: >95% line coverage for new functions

### Integration Testing
- **Target**: Iteration loop with mocked agent responses
- **Approach**: End-to-end scenarios with controlled inputs
- **Coverage Goal**: All iteration paths tested (success, halt, stuck, max exceeded)

### E2E Testing
- **Target**: Complete workflow with real plan file
- **Approach**: Execute /build on actual multi-phase plan
- **Coverage Goal**: Real-world validation of iteration behavior

## Documentation Requirements

### New Documentation Sections
- **build-command-guide.md**: "Persistence Behavior" section (~100 lines)
- **state-based-orchestration-overview.md**: "Persistent Workflows" section (~100 lines)
- **implementer-coordinator.md**: "Multi-Iteration Execution" examples (~80 lines)

**Total New Documentation**: ~280 lines

### Updated Documentation
- **build.md**: Inline comments for iteration loop logic
- **CLAUDE.md**: Command reference update if needed

## Dependencies

### External Dependencies
None - all work is internal to .claude/ system

### Internal Dependencies (Already Exist)
- **implementer-coordinator.md**: Already supports continuation_context and iteration parameters
- **checkpoint-utils.sh**: Schema v2.1 already defined with iteration fields
- **error-handling.sh**: log_command_error function available
- **jq**: Required for JSON parsing (standard system utility)

### Phase Dependencies
- Phase 2 depends on Phase 1 (context monitoring needs iteration loop)
- Phase 3 depends on Phases 1, 2 (checkpoint integration needs loop + monitoring)
- Phase 4 depends on Phases 1, 2, 3 (documentation requires features complete)
- Phase 5 depends on all phases (testing validates all features)

**Execution Order** (sequential due to dependencies):
1. Phase 1: Iteration Loop (4 hours)
2. Phase 2: Context Monitoring (3 hours)
3. Phase 3: Checkpoint Integration (2.5 hours)
4. Phase 4: Documentation (2.5 hours)
5. Phase 5: Testing (5 hours)

**Total Duration**: 17 hours

## Risk Analysis

### Risk 1: Iteration Loop Introduces Infinite Loop
- **Likelihood**: Low (MAX_ITERATIONS and stuck detection prevent this)
- **Impact**: High (/build hangs indefinitely)
- **Mitigation**:
  - MAX_ITERATIONS hard limit (default 5)
  - Stuck detection after 2 unchanged iterations
  - Per-iteration timeout consideration
- **Rollback**: Revert to single invocation /build

### Risk 2: Context Estimation Inaccurate
- **Likelihood**: High (heuristic-based, not actual measurement)
- **Impact**: Medium (premature halt or context overflow)
- **Mitigation**:
  - Conservative 90% threshold (10% safety margin)
  - User override via --context-threshold flag
  - Calibration tests in Phase 5
- **Rollback**: Disable context monitoring, rely on MAX_ITERATIONS only

### Risk 3: Checkpoint Corruption During Iteration
- **Likelihood**: Low (atomic writes prevent most corruption)
- **Impact**: Medium (resumption fails)
- **Mitigation**:
  - Atomic write pattern (temp file + mv)
  - Validation on load
  - Graceful fallback to plan file analysis
- **Rollback**: Delete corrupt checkpoint, restart from beginning

### Risk 4: Agent Doesn't Return work_remaining Correctly
- **Likelihood**: Medium (depends on agent behavior)
- **Impact**: Medium (stuck detection may not work)
- **Mitigation**:
  - Agent already documents work_remaining return field
  - Validate JSON parsing with fallback
  - Log parsing errors for debugging
- **Rollback**: Treat empty work_remaining as completion

## Implementation Timeline

### Week 1: Core Implementation
- **Day 1-2**: Phase 1 (Iteration Loop) - 4 hours
- **Day 2-3**: Phase 2 (Context Monitoring) - 3 hours
- **Day 3**: Phase 3 (Checkpoint Integration) - 2.5 hours

### Week 2: Documentation and Testing
- **Day 4**: Phase 4 (Documentation) - 2.5 hours
- **Day 4-5**: Phase 5 (Testing) - 5 hours

**Total Duration**: 5 working days (17 hours)

## Conclusion

This focused plan delivers the **critical missing infrastructure** for /build iteration support while excluding the 70% of Plan 885 that is either already implemented or unnecessary. The research conclusively showed that:

1. **command-init.sh is NOT needed** - Exit code 127 errors are from subprocess boundaries, not sourcing
2. **Agent infrastructure is ready** - implementer-coordinator already supports iteration
3. **Only iteration loop is missing** - The gap is in /build, not supporting libraries

**Expected Outcomes**:
1. /build handles plans up to 40 phases (vs current ~10)
2. Graceful halt at 90% context prevents overflow
3. Stuck detection prevents infinite loops
4. Checkpoint resumption enables interrupted workflow recovery

**Key Success Factors**:
- Iteration loop must correctly parse agent work_remaining output
- Context estimation should be conservative (better to halt early than overflow)
- Documentation must include concrete examples
- All bash blocks must follow three-tier sourcing pattern

---

## Revision History

### Revision 1 (2025-11-21)

**Trigger**: Standards consistency analysis identified compliance gaps.

**Research Report**: [Repair Plans Standards Consistency Analysis](/home/benjamin/.config/.claude/specs/20251121_repair_plans_standards_consistency/reports/001_repair_plans_standards_consistency_analysis.md)

**Changes Made**:

1. **Added mandatory three-tier library sourcing pattern to Phase 1 implementation** (CRITICAL)
   - Updated implementation pattern (lines 177-294) to include full bootstrap and library sourcing
   - Added project directory detection
   - Added Tier 1 critical library sourcing with fail-fast handlers
   - Added Tier 2/3 optional library sourcing with graceful degradation
   - Added workflow state loading for subprocess isolation
   - Added error logging initialization with `ensure_error_log_exists`
   - Added bash error trap setup

2. **Added test isolation patterns to Phase 1 testing** (HIGH PRIORITY)
   - Added CLAUDE_TEST_MODE=1 environment variable
   - Added CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR temp directory setup
   - Added cleanup trap

3. **Added pre-commit validation steps to Phase 1 testing** (HIGH PRIORITY)
   - Added `check-library-sourcing.sh` validation
   - Added `lint_error_suppression.sh` validation
   - Added `lint_bash_conditionals.sh` validation

4. **Updated Success Criteria** (MEDIUM PRIORITY)
   - Added three-tier sourcing pattern compliance criterion
   - Added test isolation requirement
   - Added pre-commit validation requirement

5. **Updated error logging integration**
   - Changed `log_command_error` calls to use proper parameter format per error-handling.md
   - Added jq-based context JSON construction

6. **Added subprocess isolation state persistence**
   - Added `append_workflow_state` calls to persist iteration variables across bash blocks

**Compliance Status**: Plan now addresses all gaps identified in standards consistency analysis. Compliance level upgraded from MEDIUM to HIGH.
