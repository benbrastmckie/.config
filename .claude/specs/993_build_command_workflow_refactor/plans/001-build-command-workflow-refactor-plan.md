# Build Command Workflow Refactor - Implementation Plan

## Metadata
- **Date**: 2025-12-01 (Revised)
- **Feature**: Refactor /build command into /implement and /test commands
- **Scope**: Split monolithic full-implementation workflow into separate implementation-only and test/debug workflows with summary-based handoff
- **Estimated Phases**: 7
- **Estimated Hours**: 45-62 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 245.0
- **Structure Level**: 0
- **Research Reports**:
  - [Build Command Analysis](/home/benjamin/.config/.claude/specs/993_build_command_workflow_refactor/reports/001-build-command-analysis.md)
  - [Implement-Test Integration Patterns](/home/benjamin/.config/.claude/specs/993_build_command_workflow_refactor/reports/002-implement-test-integration.md)

## Overview

The current /build command (1913 lines) implements a monolithic workflow combining implementation, testing, and debugging phases. This plan refactors it into two specialized commands that follow the architectural patterns established by the /plan command (1504 lines, 100% standards-compliant):

**New Commands**:
1. **/implement**: Implementation-only workflow (Blocks 1a-1d from /build)
   - Argument capture and state machine initialization
   - Implementer-coordinator delegation with hard barrier pattern
   - Test writing during Testing phases (tests written, not executed)
   - Summary creation with Testing Strategy section
   - Summary verification and iteration management
   - Phase checkbox updates
   - Terminal state: IMPLEMENT (with option to continue to COMPLETE)

2. **/test**: Test execution and debug workflow (Blocks 2-4 from /build)
   - Summary-based handoff: --file flag or auto-discovery from plan
   - Coverage loop: Iterate test execution until ≥80% coverage AND all tests pass
   - Test-executor delegation with refactored hard barrier (3-block split)
   - Loop exit conditions: success, stuck (2 iterations without progress), max iterations (5)
   - Conditional debug-analyst delegation on test failures or loop exit
   - Test result parsing and state-driven transitions
   - Terminal state: COMPLETE

**Key Benefits**:
- Separation of concerns (test writing in /implement, test execution in /test)
- Summary-based handoff (decoupled state between commands)
- Coverage loop (automatic iteration to quality threshold)
- Independent execution (run tests without reimplementing)
- Improved modularity and maintainability
- Standards compliance (100% alignment with command-authoring.md)
- Context reduction (users choose workflow scope)

## Research Summary

### Report 1: Build Command Analysis (001-build-command-analysis.md)

1. **Current /build Structure** (1913 lines, 7 blocks):
   - Block 1a-1d: Implementation phase (argument capture → implementer-coordinator → verification → phase update)
   - Block 2: Testing phase (test-executor delegation, result parsing)
   - Block 3: Debug phase (conditional debug-analyst delegation)
   - Block 4: Completion (finalization, summary, cleanup)
   - Natural separation point: Between Block 1d and Block 2a (IMPLEMENT → TEST state boundary)

2. **/plan Command Reference** (1504 lines, 5 blocks, 100% compliant):
   - Identical patterns for argument capture (2-block, `set +H`, three-tier sourcing)
   - State machine integration (sm_init, sm_transition with fail-fast)
   - Hard barrier pattern (path pre-calculation → agent invocation → verification)
   - Error logging integration (ensure_error_log_exists, setup_bash_error_trap)
   - Provides architectural blueprint for new commands

3. **Agent Delegation Analysis**:
   - implementer-coordinator: Already hard barrier compliant (no changes needed)
   - test-executor: Requires hard barrier refactor (split Block 2a into 3 blocks)
   - debug-analyst: Conditional delegation, no hard barrier needed

4. **State Machine Requirements**:
   - New transitions: `[implement]="test,complete"` (allow implement-only completion)
   - New workflow types: "implement-only" (terminal: IMPLEMENT), "test-and-debug" (terminal: COMPLETE)
   - Terminal state configuration per command scope

5. **Standards Compliance Gaps** in /build:
   - Test-executor missing "CRITICAL BARRIER" label
   - Block 2a combines setup + execution (should be 3 blocks: setup → execute → verify)
   - Some validation failures lack log_command_error integration

### Report 2: Implement-Test Integration Patterns (002-implement-test-integration.md)

1. **Summary-Based Handoff**:
   - implementer-coordinator already returns summary_path in IMPLEMENTATION_COMPLETE signal
   - Summary format supports Testing Strategy section (test requirements, coverage target)
   - /test should accept --file flag for explicit summary path
   - Auto-discovery pattern: find latest summary from plan's topic directory

2. **Test Writing Responsibility**:
   - Tests should be written DURING /implement (by implementation-executor in Testing phases)
   - /test focuses on execution only (run tests, not write them)
   - Summary documents what tests exist and how to run them
   - Clear handoff: /implement writes, /test runs

3. **Test Execution Loops**:
   - /test should implement coverage loop (iterate until threshold met)
   - Loop configuration: COVERAGE_THRESHOLD (80% default), MAX_TEST_ITERATIONS (5 default)
   - Exit conditions: success (all passed + coverage≥threshold), stuck (no progress 2 iterations), max iterations
   - Each iteration creates separate artifact (audit trail)

4. **Testing Strategy Section Enhancement**:
   - Summary must include: Test Files Created, Test Execution Requirements, Coverage Target
   - /test extracts test command, framework, expected tests from summary
   - Enables context-aware test execution

5. **Documentation Standards Needed**:
   - Create implement-test-workflow.md guide (workflow architecture, patterns, examples)
   - Update testing-protocols.md (test writing responsibility, coverage loops)
   - Update command-authoring.md (summary-based handoff pattern)
   - Update output-formatting.md (Testing Strategy section format)

## Success Criteria

- [ ] /implement command created with 100% command-authoring.md compliance
- [ ] /test command created with 100% command-authoring.md compliance
- [ ] Both commands emit proper completion signals (IMPLEMENTATION_COMPLETE, TEST_COMPLETE)
- [ ] State machine supports implement-only and test-and-debug workflow types
- [ ] Test-executor refactored to 3-block hard barrier pattern
- [ ] /implement → /test workflow integration tested end-to-end with summary-based handoff
- [ ] /implement writes tests during implementation (Testing phases)
- [ ] /implement summaries include Testing Strategy section with test requirements
- [ ] /test accepts --file flag for summary path and auto-discovers summaries from plan
- [ ] /test runs coverage loop until ≥80% coverage AND all tests pass
- [ ] Coverage loop implements exit conditions (success, stuck, max iterations)
- [ ] All unit tests pass for both commands (argument capture, state transitions, agent delegation)
- [ ] Integration tests verify implement → test workflow with coverage loop
- [ ] Documentation complete (implement-test workflow guide, command guides, standards updates)
- [ ] Error logging integration verified via /errors command

## Technical Design

### Architecture Overview

```
Current /build (1913 lines):
┌─────────────────────────────────────────────────────────────┐
│ Block 1a: Setup (496 lines)                                 │
│ Block 1b: Implementer-Coordinator (68 lines)                │
│ Block 1c: Implementation Verification (278 lines)           │
│ Block 1d: Phase Update (248 lines)                          │
├─────────────────────────────────────────────────────────────┤ ← Split Point
│ Block 2: Testing (488 lines)                                │
│ Block 3: Debug (24 lines)                                   │
│ Block 4: Completion (298 lines)                             │
└─────────────────────────────────────────────────────────────┘

New Commands:
┌──────────────────────────────────────────────────────────┐
│ /implement (estimated 700 lines)                         │
│ ├─ Block 1a: Implementation Setup                        │
│ ├─ Block 1b: Implementer-Coordinator [CRITICAL BARRIER]  │
│ ├─ Block 1c: Implementation Verification                 │
│ ├─ Block 1d: Phase Update                                │
│ └─ Block 2: Completion (simplified)                      │
│                                                            │
│ Terminal State: IMPLEMENT → COMPLETE                      │
│ Return Signal: IMPLEMENTATION_COMPLETE                    │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ /test (estimated 800 lines)                              │
│ ├─ Block 1: Setup (argument capture, state restoration)  │
│ ├─ Block 2: Test Path Pre-Calculation                    │
│ ├─ Block 3: Test Execution [CRITICAL BARRIER]            │
│ ├─ Block 4: Test Verification                            │
│ ├─ Block 5: Debug Phase [CONDITIONAL]                    │
│ └─ Block 6: Completion                                   │
│                                                            │
│ Terminal State: TEST → COMPLETE (or DEBUG → COMPLETE)    │
│ Return Signal: TEST_COMPLETE                             │
└──────────────────────────────────────────────────────────┘
```

### State Machine Changes

**Current Transitions** (workflow-state-machine.sh lines 56-65):
```bash
[implement]="test"  # MUST go through testing
```

**New Transitions**:
```bash
[implement]="test,complete"  # Allow implement-only completion
```

**New Workflow Types**:
```bash
case "$WORKFLOW_SCOPE" in
  implement-only)
    TERMINAL_STATE="$STATE_IMPLEMENT"
    ;;
  test-and-debug)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
  # ... existing cases ...
esac
```

### Hard Barrier Refactor: test-executor

**Current Structure** (build.md Block 2):
```
Block 2a: Setup + Execution (combined, lines 1104-1289)
Block 2: Verification (lines 1291-1586)
```

**Refactored Structure** (test.md Blocks 2-4):
```
Block 2: Test Path Pre-Calculation
  - Calculate TEST_OUTPUT_PATH
  - Validate path absolute
  - Persist via append_workflow_state
  - No agent invocation

Block 3: Test Execution [CRITICAL BARRIER]
  - Add "CRITICAL BARRIER" label
  - Invoke test-executor via Task tool
  - Behavioral injection with input contract
  - Expected return: TEST_COMPLETE signal

Block 4: Test Verification (Hard Barrier)
  - Restore TEST_OUTPUT_PATH from state
  - Verify artifact exists at pre-calculated path
  - Parse agent return signal (TEST_STATUS, NEXT_STATE)
  - State-driven transition (DEBUG vs COMPLETE)
  - log_command_error on verification failure
```

### State Persistence Strategy

**Problem**: /test needs access to /implement state across command boundaries.

**Solution**: Plan-based state file naming (persistent, not ephemeral).

**Implementation**:
```bash
# In /implement Block 1a:
STATE_FILE="${TOPIC_PATH}/.state/implement_state.sh"
ensure_artifact_directory "$(dirname "$STATE_FILE")"

# Persist critical variables:
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "IMPLEMENTATION_STATUS" "complete"

# In /test Block 1:
# Derive TOPIC_PATH from plan file argument
TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
STATE_FILE="${TOPIC_PATH}/.state/implement_state.sh"

# Validate state file exists
if [ ! -f "$STATE_FILE" ]; then
  log_command_error "validation_error" \
    "/test requires /implement state" \
    "Missing: $STATE_FILE. Run /implement first."
  exit 1
fi

# Load state
source "$STATE_FILE"
```

### Command Authoring Compliance

Both commands follow these patterns from command-authoring.md:

1. **Execution Directives** (Section 1):
   - Every bash block: `**EXECUTE NOW**: [description]`
   - Every Task invocation: Imperative instruction

2. **Subprocess Isolation** (Section 3):
   - `set +H` at start of every block
   - Three-tier library sourcing in every block
   - Return code verification for critical functions

3. **Argument Capture** (Section 6):
   - 2-block standardized pattern (Block 1a captures, validates immediately)
   - Temp file with timestamp: `{command}_arg_$(date +%s%N).txt`
   - Path file for recovery: `{command}_arg_path.txt`

4. **Hard Barrier Pattern** (hard-barrier-subagent-delegation.md):
   - Setup block: Path pre-calculation
   - Execute block: Agent invocation with "CRITICAL BARRIER" label
   - Verify block: Artifact existence check, log_command_error on failure

5. **Output Suppression** (Section 7):
   - Library sourcing: `2>/dev/null || { echo "ERROR: ..."; exit 1; }`
   - Directory operations: `2>/dev/null || true`
   - Single summary line per block

6. **Error Logging Integration**:
   - ensure_error_log_exists in Block 1a
   - setup_bash_error_trap in every block
   - log_command_error for all validation failures

### Coverage Loop Design

**Principle**: /test iterates test execution until coverage threshold met or loop exits.

**Configuration**:
- Coverage threshold: 80% (default, configurable via --coverage-threshold)
- Max iterations: 5 (default, configurable via --max-iterations)
- Stuck threshold: 2 iterations without progress

**Exit Conditions**:
1. **Success**: all_passed=true AND coverage≥threshold → NEXT_STATE=COMPLETE
2. **Stuck**: No coverage progress for 2 iterations → NEXT_STATE=DEBUG
3. **Max Iterations**: Iteration count ≥ max → NEXT_STATE=DEBUG

**Loop Flow**:
```
Block 2: Initialize (ITERATION=1, COVERAGE_THRESHOLD, MAX_TEST_ITERATIONS)
  ↓
Block 3: Invoke test-executor [CRITICAL BARRIER]
  ↓
Block 4: Verify results + Loop decision
  ↓
  ├─ Success → Block 6 (Completion)
  ├─ Stuck/Max → Block 5 (Debug)
  └─ Continue → Increment ITERATION, loop back to Block 2
```

**Iteration Artifacts**:
- Each iteration creates: `test_results_iter${ITERATION}_${timestamp}.md`
- Audit trail: Review all iterations to understand coverage improvement
- State persistence: ITERATION, PREVIOUS_COVERAGE, STUCK_COUNT

**Implementation**:
- Loop control in /test command (not test-executor agent)
- test-executor executes once per iteration (stateless)
- /test manages loop state, progress tracking, exit logic

## Implementation Phases

### Phase 0: Standards Documentation and State Machine Updates [COMPLETE]
dependencies: []

**Objective**: Create implement-test workflow documentation standards and update state machine to support implement-only and test-and-debug workflow types.

**Complexity**: Medium

**Divergence Summary**:
This plan proposes changes that extend existing standards:
- **Current Standard**: State machine supports research-only, research-and-plan, full-implementation, debug-only workflow types (workflow-state-machine.sh lines 443-513)
- **Proposed Change**: Add implement-only (terminal: IMPLEMENT) and test-and-debug (terminal: COMPLETE) workflow types
- **Conflict**: Current `[implement]="test"` transition enforces testing, preventing implement-only workflows

**Justification**:
1. **Limitation**: Current standards force full-implementation workflow (implement → test → complete), preventing users from running implementation or testing independently
2. **Benefit**: New workflow types enable:
   - Implementation without testing (faster iteration during development)
   - Testing without reimplementation (test-driven debugging)
   - Better separation of concerns (implementation vs testing)
   - Summary-based handoff between commands (decoupled state)
3. **Risk**: Minimal - new workflow types are additive (existing types unchanged)

**Tasks**:
- [x] Create implement-test workflow guide (file: /home/benjamin/.config/.claude/docs/guides/workflows/implement-test-workflow.md)
  - Document workflow architecture: /implement (write code+tests) → /test (execute tests)
  - Document summary-based handoff pattern (--file flag, auto-discovery)
  - Document test writing responsibility (tests written in /implement, not /test)
  - Document test execution loops (coverage threshold, exit conditions)
  - Document Testing Strategy section format for summaries
  - Include examples: sequential execution, manual handoff, test-only execution
- [x] Update testing-protocols.md (file: /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md)
  - Add "Test Writing Responsibility" section (tests written during implementation)
  - Add "Test Execution Loops" section (coverage loop pattern, exit conditions)
  - Add "Summary-Based Test Execution" section (Testing Strategy format)
- [x] Update command-authoring.md (file: /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md)
  - Add "Command Integration Patterns" section (summary-based handoff)
  - Document --file flag pattern for consuming summaries
  - Document auto-discovery pattern for latest summary
- [x] Update output-formatting.md (file: /home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md)
  - Add "Testing Strategy Section Format" requirements
  - Document required fields: test files, test command, coverage target, expected tests
  - Provide example Testing Strategy section
- [x] Update workflow-state-machine.sh STATE_TRANSITIONS table (file: /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh, line 56-65)
  - Change: `[implement]="test"` → `[implement]="test,complete"`
  - Justification: Allow /implement to complete without testing
- [x] Update workflow-state-machine.sh sm_init WORKFLOW_SCOPE cases (file: /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh, lines 443-513)
  - Add: `implement-only) TERMINAL_STATE="$STATE_IMPLEMENT" ;;`
  - Add: `test-and-debug) TERMINAL_STATE="$STATE_COMPLETE" ;;`
- [x] Update CLAUDE.md state_based_orchestration section with new workflow types
  - Document implement-only and test-and-debug workflows
  - Add usage examples for /implement and /test
  - Link to implement-test-workflow.md guide
- [x] Update command-reference.md with /implement and /test entries
  - Document workflow types and terminal states
  - Cross-reference state machine documentation
  - Cross-reference implement-test-workflow.md

**User Warning**:
⚠️ **IMPORTANT**: This plan proposes changes to project-wide state machine standards. Review Phase 0 carefully before proceeding with implementation. If standards changes are rejected, this plan will require revision.

**Testing**:
```bash
# Verify documentation created
test -f .claude/docs/guides/workflows/implement-test-workflow.md || echo "ERROR: Workflow guide not created"
grep -q "Test Writing Responsibility" .claude/docs/reference/standards/testing-protocols.md || echo "ERROR: testing-protocols.md not updated"
grep -q "Testing Strategy Section Format" .claude/docs/reference/standards/output-formatting.md || echo "ERROR: output-formatting.md not updated"

# Verify state machine transitions updated
source .claude/lib/workflow/workflow-state-machine.sh
sm_init "test" "implement" "implement-only" 3 "[]"
[ "$TERMINAL_STATE" = "implement" ] || echo "ERROR: Terminal state not set correctly"

# Verify transition allows implement → complete
sm_transition "$STATE_IMPLEMENT" "test" || echo "ERROR: implement → test transition failed"
sm_transition "$STATE_COMPLETE" "test" || echo "ERROR: implement → complete transition failed"

# Verify CLAUDE.md updated
grep -q "implement-only" .config/CLAUDE.md || echo "ERROR: CLAUDE.md not updated"
```

**Expected Duration**: 4-6 hours

### Phase 1: Create /implement Command Foundation [COMPLETE]
dependencies: [0]

**Objective**: Create /implement command file with argument capture, state machine initialization, and error logging integration following /plan command patterns.

**Complexity**: Medium

**Tasks**:
- [x] Create /home/benjamin/.config/.claude/commands/implement.md with frontmatter
  - allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
  - argument-hint: [plan-file] [starting-phase] [--dry-run] [--max-iterations=N]
  - description: "Implementation-only workflow - Execute plan phases without testing"
  - command-type: primary
  - dependent-agents: implementer-coordinator
  - library-requirements: workflow-state-machine.sh >=2.0.0, state-persistence.sh >=1.5.0
- [x] Implement Block 1a: Implementation Setup (preserve build.md lines 24-496 with modifications)
  - 2-block argument capture pattern (lines 34-56)
  - `set +H` preprocessing safety (line 39)
  - Three-tier library sourcing (lines 82-110): error-handling → state-persistence → workflow-state-machine
  - Pre-flight validation (lines 112-155)
  - Argument parsing: PLAN_FILE, STARTING_PHASE, DRY_RUN, MAX_ITERATIONS, CONTEXT_THRESHOLD (lines 157-198)
  - Checkpoint resumption logic (lines 204-250, v2.1 schema)
  - Plan file validation (lines 286-305)
  - sm_init with WORKFLOW_TYPE="implement-only", TERMINAL_STATE="$STATE_IMPLEMENT" (lines 354-420)
  - State transition to IMPLEMENT (lines 422-437)
- [x] Add error logging integration
  - ensure_error_log_exists (after library sourcing)
  - setup_bash_error_trap in Block 1a
  - log_command_error for validation failures (plan file, checkpoint schema, etc.)
- [x] Add checkpoint reporting (lines 487-495 from build.md)
  - Report checkpoint path, plan file, starting phase
  - Single summary line per block requirement

**Testing**:
```bash
# Test argument capture
/implement test-plan.md --dry-run
# Verify: DRY_RUN=true, PLAN_FILE set correctly

# Test state machine initialization
/implement test-plan.md
# Verify: WORKFLOW_TYPE="implement-only", CURRENT_STATE="implement"

# Test error logging
/implement nonexistent-plan.md
# Verify: Error logged to .claude/tests/logs/test-errors.jsonl
```

**Expected Duration**: 6-8 hours

### Phase 2: Implement Implementer-Coordinator Delegation [COMPLETE]
dependencies: [1]

**Objective**: Add implementer-coordinator hard barrier delegation (Blocks 1b-1c from /build) with full compliance to hard-barrier-subagent-delegation.md pattern.

**Complexity**: Medium

**Tasks**:
- [x] Implement Block 1b: Implementer-Coordinator Invocation (preserve build.md lines 498-566)
  - Hard barrier label: "CRITICAL BARRIER - Implementer-Coordinator Invocation"
  - Input contract specification: plan_path, topic_path, summaries_dir, artifact_paths, continuation_context, iteration
  - Iteration management: MAX_ITERATIONS, CONTEXT_THRESHOLD
  - Expected return signal: IMPLEMENTATION_COMPLETE with metadata
  - `set +H` and three-tier library sourcing
- [x] Implement Block 1c: Implementation Verification (preserve build.md lines 568-846)
  - Summaries directory existence validation (lines 671-686)
  - Summary file existence validation (lines 689-710)
  - Summary file size validation (lines 713-728, minimum 100 bytes)
  - log_command_error on verification failure (lines 692-699)
  - Iteration management: WORK_REMAINING, CONTEXT_EXHAUSTED, REQUIRES_CONTINUATION (lines 751-843)
  - Next iteration preparation: CONTINUATION_CONTEXT persistence (lines 809-826)
- [x] Add state persistence after verification
  - append_workflow_state "IMPLEMENTATION_STATUS" "complete"
  - append_workflow_state "ITERATION" "$ITERATION"
  - append_workflow_state "LATEST_SUMMARY" "$LATEST_SUMMARY"

**Testing**:
```bash
# Test implementer-coordinator delegation
/implement test-plan.md
# Verify: Summary file created in summaries/ directory
# Verify: Summary size ≥100 bytes

# Test hard barrier failure
# Remove summary file immediately after agent returns
# Verify: Block 1c exits with error, logs to error log

# Test iteration management
/implement complex-plan.md --max-iterations=2
# Verify: Multiple iterations if REQUIRES_CONTINUATION=true
```

**Expected Duration**: 6-8 hours

### Phase 3: Implement Phase Update and Completion [COMPLETE]
dependencies: [2]

**Objective**: Add phase checkbox update logic (Block 1d) and simplified completion block (Block 2) with proper state transitions, Testing Strategy section validation, and console summary.

**Complexity**: Medium

**Tasks**:
- [x] Implement Block 1d: Phase Update (preserve build.md lines 848-1096 with modifications)
  - `set +H` and three-tier library sourcing (lines 883-898)
  - Workflow state recovery: STATE_ID_FILE → WORKFLOW_ID → load_workflow_state (lines 902-948)
  - Completed phase extraction: `grep -c "^### Phase" "$PLAN_FILE"` (lines 964-966)
  - Checkbox-utils integration: mark_phase_complete, add_complete_marker (lines 979-1000)
  - Fallback spec-updater delegation if checkbox-utils fails (lines 1068-1096)
  - State persistence: append_workflow_state, save_completed_states_to_state (lines 1023-1045)
  - Plan status update: check_all_phases_complete → update_plan_status "COMPLETE" (lines 1056-1063)
- [x] Verify summary includes Testing Strategy section
  - Check for "## Testing Strategy" section in LATEST_SUMMARY
  - Warn if section missing (summary may be from old format)
  - Verify section includes: Test Files Created, Test Execution Requirements
  - Log warning if Testing Strategy incomplete (not error, allow continuation)
- [x] Implement Block 2: Completion (new, simplified from build.md Block 4)
  - `set +H` and three-tier library sourcing
  - State transition to COMPLETE: `sm_transition "$STATE_COMPLETE" "implementation complete (no testing)" || exit 1`
  - Console summary via summary-formatting.sh (4-section format: Summary/Phases/Artifacts/Next Steps)
  - IMPLEMENTATION_COMPLETE signal with metadata: summary_path, plan_path, next_command="/test $PLAN_FILE"
  - Checkpoint cleanup (lines 1899-1901)
  - State file preservation (do NOT cleanup - /test needs it)
- [x] Add console summary with /test next step
  - SUMMARY_TEXT: "Completed implementation of N phases (including test writing). Run /test to execute test suite."
  - NEXT_STEPS: "• Review implementation: cat $LATEST_SUMMARY\n  • Run tests: /test $PLAN_FILE\n  • Run tests with summary: /test --file $LATEST_SUMMARY"

**Testing**:
```bash
# Test phase update
/implement test-plan.md
# Verify: Plan phases marked [COMPLETE] via checkbox-utils

# Test completion signal
OUTPUT=$(/implement test-plan.md)
echo "$OUTPUT" | grep "IMPLEMENTATION_COMPLETE"
# Verify: Signal includes summary_path, plan_path, next_command

# Test state file persistence
/implement test-plan.md
STATE_FILE="${TOPIC_PATH}/.state/implement_state.sh"
[ -f "$STATE_FILE" ] || echo "ERROR: State file not preserved"
```

**Expected Duration**: 6-8 hours

### Phase 4: Create /test Command with Hard Barrier Refactor [COMPLETE]
dependencies: [0]

**Objective**: Create /test command with --file flag, summary auto-discovery, coverage loop initialization, and refactored test-executor hard barrier (3-block pattern: setup → execute → verify).

**Complexity**: High

**Tasks**:
- [x] Create /home/benjamin/.config/.claude/commands/test.md with frontmatter
  - allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
  - argument-hint: [plan-file] [--file <summary>] [--coverage-threshold=N] [--max-iterations=N]
  - description: "Test and debug workflow - Execute test suite with coverage loop"
  - command-type: primary
  - dependent-agents: test-executor, debug-analyst
  - library-requirements: workflow-state-machine.sh >=2.0.0, state-persistence.sh >=1.5.0
- [x] Implement Block 1: Setup (new, argument capture with --file flag and auto-discovery)
  - 2-block argument capture pattern
  - `set +H` and three-tier library sourcing
  - Argument parsing with --file flag (following debug.md pattern lines 111-152):
    - Parse --file flag: `if [[ "$BUILD_ARGS" =~ --file[[:space:]]+([^[:space:]]+) ]]; then SUMMARY_FILE="${BASH_REMATCH[1]}"; fi`
    - Validate summary file exists: `[ ! -f "$SUMMARY_FILE" ] && log_command_error && exit 1`
    - Extract PLAN_FILE from summary: `PLAN_FILE=$(grep "^- \*\*Plan\*\*:" "$SUMMARY_FILE" | sed 's/.*: //')`
    - Set TEST_CONTEXT="summary"
  - Auto-discovery pattern if --file not provided:
    - Require PLAN_FILE as first argument
    - Derive TOPIC_PATH: `dirname "$(dirname "$PLAN_FILE")"`
    - Find latest summary: `find "$SUMMARIES_DIR" -name "*.md" -type f -printf '%T@ %p\n' | sort -rn | head -1`
    - Set TEST_CONTEXT="auto-discovered" or "no-summary"
  - Parse --coverage-threshold flag (default: 80)
  - Parse --max-iterations flag (default: 5)
  - State file validation: `STATE_FILE="${TOPIC_PATH}/.state/implement_state.sh"`
  - Load implementation state via `source "$STATE_FILE"` (optional, warn if missing)
  - sm_init with WORKFLOW_TYPE="test-and-debug", TERMINAL_STATE="$STATE_COMPLETE"
- [x] Implement Block 2: Test Loop Initialization (new, coverage loop setup)
  - Initialize loop variables: ITERATION=1, PREVIOUS_COVERAGE=0, STUCK_COUNT=0
  - Set MAX_TEST_ITERATIONS from flag or default (5)
  - Set COVERAGE_THRESHOLD from flag or default (80)
  - Calculate initial TEST_OUTPUT_PATH: `${TOPIC_PATH}/outputs/test_results_iter${ITERATION}_$(date +%s).md`
  - Validate path absolute: `[[ "$TEST_OUTPUT_PATH" =~ ^/ ]]`
  - Persist via append_workflow_state "TEST_OUTPUT_PATH" "$TEST_OUTPUT_PATH"
  - Persist loop state: append_workflow_state "ITERATION" "$ITERATION"
  - State transition to TEST: `sm_transition "$STATE_TEST" "starting test phase" || exit 1`
  - Single summary line: "Test iteration $ITERATION/$MAX_TEST_ITERATIONS: $TEST_OUTPUT_PATH"
- [x] Implement Block 3: Test Execution [CRITICAL BARRIER] (refactored from build.md lines 1229-1289)
  - Add "CRITICAL BARRIER" label at block start
  - `set +H` and three-tier library sourcing
  - Task invocation: test-executor.md
  - Input contract: plan_path, topic_path, artifact_paths, test_config (with coverage_threshold), output_path
  - Expected return signal: TEST_COMPLETE with metadata (status, framework, test_command, counts, coverage, next_state)
- [x] Implement Block 4: Test Verification and Loop Decision (refactored from build.md lines 1291-1586)
  - `set +H` and three-tier library sourcing
  - Restore TEST_OUTPUT_PATH and loop state from STATE_FILE: `source "$STATE_FILE"`
  - HARD BARRIER verification: `[ -f "$TEST_OUTPUT_PATH" ] || exit 1`
  - log_command_error on artifact missing
  - Parse test results: TESTS_PASSED, TESTS_FAILED, COVERAGE (handle N/A coverage)
  - Check success criteria: ALL_PASSED (failed=0) AND COVERAGE_MET (coverage≥threshold)
  - Check progress: COVERAGE_DELTA, STUCK_COUNT (no progress for 2 iterations)
  - Loop decision logic:
    - Success: Break loop, set NEXT_STATE="COMPLETE"
    - Stuck: Break loop, set NEXT_STATE="DEBUG"
    - Max iterations: Break loop, set NEXT_STATE="DEBUG"
    - Continue: Increment ITERATION, generate IMPROVEMENT_HINTS, loop back to Block 2
  - State persistence: append_workflow_state "TEST_STATUS" "$TEST_STATUS"
  - State persistence: append_workflow_state "NEXT_STATE" "$NEXT_STATE"

**Testing**:
```bash
# Test --file flag parsing
/test --file /path/to/summary.md
# Verify: SUMMARY_FILE set, PLAN_FILE extracted from summary, TEST_CONTEXT="summary"

# Test auto-discovery
/implement test-plan.md
/test test-plan.md
# Verify: Latest summary auto-discovered, TEST_CONTEXT="auto-discovered"

# Test coverage loop initialization
/test test-plan.md --coverage-threshold 90 --max-iterations 10
# Verify: COVERAGE_THRESHOLD=90, MAX_TEST_ITERATIONS=10, ITERATION=1

# Test hard barrier
/test test-plan.md
# Delete test artifact after test-executor returns
# Verify: Block 4 fails with error, logs to error log

# Test path calculation per iteration
/test test-plan.md
# Verify: TEST_OUTPUT_PATH includes iteration number (test_results_iter1_*)
```

**Expected Duration**: 10-12 hours

### Phase 5: Implement Coverage Loop Execution and Conditional Debug [COMPLETE]
dependencies: [4]

**Objective**: Implement loop execution flow with proper exit conditions, conditional debug-analyst delegation (Block 5), and completion block (Block 6) with iteration-aware console summaries.

**Complexity**: High

**Tasks**:
- [x] Implement loop execution control flow
  - After Block 4 loop decision, implement branching:
    - If NEXT_STATE="COMPLETE": Proceed to Block 6 (skip debug)
    - If NEXT_STATE="DEBUG": Proceed to Block 5 (invoke debug)
    - If loop continues: Recalculate TEST_OUTPUT_PATH for next iteration, jump back to Block 2
  - Ensure loop terminates on success, stuck, or max iterations
  - Persist final iteration count: append_workflow_state "FINAL_ITERATION" "$ITERATION"
- [x] Implement Block 5: Debug Phase [CONDITIONAL] (preserve build.md lines 1588-1612)
  - Conditional check: `[ "$NEXT_STATE" = "DEBUG" ]`
  - `set +H` and three-tier library sourcing (only if condition met)
  - Task invocation: debug-analyst.md
  - Input contract: issue_description (coverage loop failure or test failures), failed_phase, test_command, exit_code, debug_directory
  - Enhanced issue description: Include iteration summary (iterations, coverage progress, stuck reason)
  - Expected return signal: DEBUG_COMPLETE
  - Skip block if NEXT_STATE != "DEBUG"
- [x] Implement Block 6: Completion (adapted from build.md lines 1614-1912)
  - `set +H` and three-tier library sourcing
  - State restoration with recovery (lines 1667-1687)
  - Error logging context restoration (lines 1689-1707)
  - State validation: STATE_FILE, CURRENT_STATE checks (lines 1710-1773)
  - State transition to COMPLETE: `sm_transition "$STATE_COMPLETE" "test phase complete" || exit 1`
  - Console summary with iteration-aware messaging (success, stuck, max iterations)
  - TEST_COMPLETE signal with metadata: test_artifact_paths (all iterations), debug_report_path (if applicable), coverage, status
  - Checkpoint cleanup (lines 1899-1901)
  - State file cleanup (lines 1904-1909)
- [x] Add iteration-aware console summaries
  - Success: "All tests passed with ${COVERAGE}% coverage after ${ITERATION} iteration(s). Review: cat $TEST_OUTPUT_PATH"
  - Stuck: "Coverage loop stuck (no progress for 2 iterations). Final coverage: ${COVERAGE}%. Debug report: cat $DEBUG_REPORT_PATH"
  - Max iterations: "Max iterations (${MAX_TEST_ITERATIONS}) reached. Final coverage: ${COVERAGE}%. Debug report: cat $DEBUG_REPORT_PATH"
  - NEXT_STEPS: Conditional based on test status and iteration outcome

**Testing**:
```bash
# Test successful coverage loop (single iteration)
/implement test-plan.md
/test test-plan.md
# Verify: 1 iteration, coverage ≥80%, all passed, no debug, TEST_COMPLETE signal

# Test coverage loop with multiple iterations
/test test-plan-partial-coverage.md
# Verify: Multiple iterations (e.g., iter1: 60%, iter2: 85%), final success

# Test stuck detection
/test test-plan-stuck.md
# Verify: Coverage static for 2 iterations, debug-analyst invoked, stuck message in summary

# Test max iterations
/test test-plan-complex.md --max-iterations 3
# Verify: Stops after 3 iterations, debug-analyst invoked if not complete

# Test loop control flow
# Verify: Block 4 → Block 2 (continue) OR Block 4 → Block 5 (debug) OR Block 4 → Block 6 (success)

# Test iteration artifacts
/test test-plan.md
# Verify: Multiple test_results_iter*_*.md files created, audit trail preserved
```

**Expected Duration**: 8-10 hours

### Phase 6: Testing and Integration [COMPLETE]
dependencies: [3, 5]

**Objective**: Create comprehensive unit and integration tests for /implement and /test commands, verify end-to-end workflow with coverage loop, and validate error logging integration.

**Complexity**: High

**Tasks**:
- [x] Create unit tests for /implement (file: /home/benjamin/.config/.claude/tests/commands/test_implement_command.sh)
  - Test argument capture (plan file, flags)
  - Test state machine initialization (workflow type, terminal state)
  - Test implementer-coordinator delegation (hard barrier)
  - Test summary verification (file existence, size, Testing Strategy section)
  - Test iteration management (REQUIRES_CONTINUATION)
  - Test phase checkbox updates (mark_phase_complete)
  - Test IMPLEMENTATION_COMPLETE signal format (includes next_command)
  - Test checkpoint resumption
- [x] Create unit tests for /test (file: /home/benjamin/.config/.claude/tests/commands/test_test_command.sh)
  - Test --file flag parsing (summary file, plan extraction)
  - Test auto-discovery (latest summary from topic path)
  - Test --coverage-threshold and --max-iterations flags
  - Test coverage loop initialization (ITERATION, COVERAGE_THRESHOLD)
  - Test test-executor delegation (hard barrier)
  - Test hard barrier failure (missing artifact)
  - Test loop decision logic (success, stuck, max iterations)
  - Test conditional debug invocation (NEXT_STATE="DEBUG")
  - Test TEST_COMPLETE signal format (iteration-aware)
- [x] Create integration tests (file: /home/benjamin/.config/.claude/tests/integration/test_implement_test_workflow.sh)
  - Setup: Create test plan with implementation and Testing phases
  - Run /implement, capture summary path, verify Testing Strategy section
  - Verify tests written in Testing phase
  - Run /test with --file flag (explicit summary path)
  - Verify test execution, coverage loop (if needed), results captured
  - Test /test with auto-discovery (no --file flag)
  - Verify state transitions (IMPLEMENT → TEST → COMPLETE)
  - Cleanup: Remove test artifacts
- [x] Create coverage loop integration tests (file: /home/benjamin/.config/.claude/tests/integration/test_coverage_loop.sh)
  - Test single iteration success (coverage ≥80%, all passed)
  - Test multiple iterations to threshold (e.g., 60% → 85%)
  - Test stuck detection (coverage static for 2 iterations)
  - Test max iterations exit (5 iterations without meeting criteria)
  - Test iteration artifact preservation (test_results_iter*_*.md)
  - Test improvement hints generation (uncovered modules)
- [x] Verify error logging integration
  - Run /implement with invalid plan file
  - Verify error logged: `/errors --command /implement --since 1h`
  - Run /test without summary (--file not provided, no auto-discovery)
  - Verify graceful fallback or error logged
  - Run /test with invalid --file path
  - Verify error logged: `/errors --command /test --type validation_error`
  - Test hard barrier failures logged correctly
- [x] Test /implement → /test workflow with real plan
  - Use existing simple plan from specs/ directory
  - Run /implement, verify summary created with Testing Strategy
  - Run /test, verify tests executed with coverage loop
  - Verify state persistence, signals emitted correctly
  - Verify iteration artifacts if multiple iterations needed

**Testing**:
```bash
# Run unit tests
bash .claude/tests/commands/test_implement_command.sh
bash .claude/tests/commands/test_test_command.sh

# Run integration tests
bash .claude/tests/integration/test_implement_test_workflow.sh
bash .claude/tests/integration/test_coverage_loop.sh

# Verify error logging
/errors --command /implement --since 1h --summary
/errors --command /test --since 1h --summary

# End-to-end workflow test with coverage loop
/implement .claude/specs/042_auth/plans/001_simple_auth.md
/test .claude/specs/042_auth/plans/001_simple_auth.md
# Verify: Coverage loop iterations, final coverage ≥80%, TEST_COMPLETE signal

# Test --file flag
/test --file .claude/specs/042_auth/summaries/001-implementation-summary.md
# Verify: Summary loaded, plan extracted, tests executed
```

**Expected Duration**: 10-12 hours

### Phase 7: Documentation and Standards Integration [COMPLETE]
dependencies: [6]

**Objective**: Create comprehensive documentation for /implement and /test commands, document implement-test workflow patterns, and update all references in CLAUDE.md and docs/.

**Complexity**: Medium

**Tasks**:
- [x] Create /implement command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md)
  - Overview: Purpose (write code AND tests), workflow type, terminal state, prerequisites, output
  - Usage: Syntax, arguments, flags, examples
  - Workflow Architecture: Block structure, state transitions, agent delegation
  - Test Writing: How tests are written during Testing phases
  - Integration with /test: How to chain commands (summary-based handoff)
  - Checkpoint Resumption: How to resume interrupted workflows
  - Error Handling: Common errors, troubleshooting
  - Examples: Simple plan, complex plan with iterations, Testing phase examples
- [x] Create /test command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/test-command-guide.md)
  - Overview: Purpose (execute tests, not write), workflow type, terminal state, prerequisites, output
  - Usage: Syntax, arguments (--file, --coverage-threshold, --max-iterations), flags, examples
  - Workflow Architecture: Block structure, coverage loop, hard barrier refactor, conditional debug
  - Summary-Based Handoff: How --file flag works, auto-discovery pattern
  - Coverage Loop: How iteration works, exit conditions (success, stuck, max iterations)
  - Integration with /implement: How to use summary from /implement
  - Test Framework Detection: Auto-detection logic
  - Debug Workflow: When debug-analyst is invoked, iteration summary in debug report
  - Examples: Single iteration success, multiple iterations, stuck detection, --file usage
- [x] Verify implement-test workflow guide exists (created in Phase 0)
  - File: /home/benjamin/.config/.claude/docs/guides/workflows/implement-test-workflow.md
  - Verify sections: workflow architecture, test writing responsibility, coverage loops, summary handoff
  - Add examples from Phase 6 integration tests
- [x] Update command-reference.md (file: /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md)
  - Add /implement entry: Syntax, workflow type (implement-only), terminal state (IMPLEMENT), examples
  - Add /test entry: Syntax, workflow type (test-and-debug), terminal state (COMPLETE), examples
  - Cross-reference implement-test-workflow.md
  - Add note: "/build remains available but /implement + /test is preferred for new workflows"
- [x] Update CLAUDE.md project_commands section
  - Add /implement and /test to command list with descriptions
  - Link to implement-command-guide.md and test-command-guide.md
  - Link to implement-test-workflow.md for integration patterns
  - Add note: "/implement writes tests, /test executes them with coverage loop"
- [x] Update all documentation examples to use /implement + /test
  - Search docs/ for workflow examples
  - Add /implement + /test examples alongside /build where appropriate
  - Update workflow diagrams to show implement-test split
  - Update examples to show summary-based handoff pattern

**Testing**:
```bash
# Verify documentation exists
test -f .claude/docs/guides/commands/implement-command-guide.md
test -f .claude/docs/guides/commands/test-command-guide.md
test -f .claude/docs/guides/workflows/implement-test-workflow.md

# Verify command guides include key sections
grep -q "Test Writing" .claude/docs/guides/commands/implement-command-guide.md
grep -q "Coverage Loop" .claude/docs/guides/commands/test-command-guide.md
grep -q "Summary-Based Handoff" .claude/docs/guides/commands/test-command-guide.md

# Verify CLAUDE.md updated
grep -q "/implement" .config/CLAUDE.md
grep -q "/test" .config/CLAUDE.md
grep -q "implement-test-workflow" .config/CLAUDE.md

# Verify command-reference.md updated
grep -q "implement-only" .claude/docs/reference/standards/command-reference.md
grep -q "test-and-debug" .claude/docs/reference/standards/command-reference.md

# Verify examples updated
grep -r "/implement" .claude/docs/guides/ | wc -l
# Should show multiple examples
```

**Expected Duration**: 6-8 hours

## Testing Strategy

### Unit Testing Approach

**Test Coverage Requirements**:
- Argument capture: Validate all flags, plan file paths
- State machine: Verify workflow types, terminal states, transitions
- Hard barrier: Test artifact verification, error logging on failure
- Agent delegation: Mock agent returns, parse signals correctly
- Error cases: Invalid inputs, missing files, state restoration failures

**Test Frameworks**:
- Bash test framework: Existing .claude/tests/ patterns
- Assertion functions: Use existing test utilities
- Mock agents: Create mock return signals for delegation testing

**Test Organization**:
```
.claude/tests/commands/
├── test_implement_command.sh      # /implement unit tests
├── test_test_command.sh           # /test unit tests
└── test_build_status_update.sh    # Existing /build tests (preserve)

.claude/tests/integration/
├── test_implement_test_workflow.sh  # End-to-end workflow
└── test_build_command.sh            # Existing /build integration tests
```

### Integration Testing Approach

**Workflow Tests**:
1. **Happy Path**: /implement → /test (passing tests)
   - Setup: Create test plan with simple phases
   - Execute: Run /implement, verify summary
   - Execute: Run /test, verify tests pass
   - Verify: State persistence, signals, console summaries

2. **Failure Path**: /implement → /test (failing tests) → debug
   - Setup: Create test plan with intentional test failure
   - Execute: Run /implement, verify summary
   - Execute: Run /test, verify debug-analyst invoked
   - Verify: Debug report created, proper state transitions

3. **Iteration Path**: /implement (multiple iterations) → /test
   - Setup: Create complex plan requiring continuation
   - Execute: Run /implement with --max-iterations=3
   - Verify: Multiple iterations, CONTINUATION_CONTEXT preserved
   - Execute: Run /test after final iteration
   - Verify: Tests execute correctly

**State Persistence Tests**:
- Verify STATE_FILE created by /implement
- Verify STATE_FILE loaded by /test
- Verify state variables accessible across command boundary
- Verify state cleanup after /test completion

### Error Logging Validation

**Error Scenarios**:
- /implement with missing plan file → validation_error
- /test without /implement state → validation_error
- Hard barrier failure (missing artifact) → agent_error
- Test execution timeout → timeout_error
- Invalid checkpoint schema → parse_error

**Validation Commands**:
```bash
# View recent errors
/errors --since 1h --summary

# Query specific command errors
/errors --command /implement --type validation_error

# Analyze error patterns
/repair --command /implement --complexity 2
```

## Documentation Requirements

### Command Guides

**implement-command-guide.md**:
- Overview section: Purpose, workflow type, terminal state
- Usage section: Syntax, arguments, examples
- Architecture section: Block structure, state machine, agent delegation
- Integration section: How to chain with /test
- Troubleshooting section: Common errors, solutions

**test-command-guide.md**:
- Overview section: Purpose, workflow type, terminal state
- Usage section: Syntax, arguments, examples
- Architecture section: Hard barrier refactor, conditional debug
- Integration section: How to use /implement state
- Troubleshooting section: Common errors, solutions

### Reference Updates

**command-reference.md**:
- Add /implement entry with syntax, workflow type, examples
- Add /test entry with syntax, workflow type, examples
- Update /build entry with deprecation notice, link to migration guide

**CLAUDE.md**:
- Update project_commands section with /implement and /test
- Add deprecation notice for /build
- Link to command guides

### Migration Documentation

**build-to-implement-test.md**:
- Workflow equivalence table
- Migration examples (simple, complex, with debugging)
- Checkpoint migration instructions
- Timeline (deprecation start, removal date)
- FAQ section

## Dependencies

### External Dependencies

**None** - This refactor uses existing libraries and patterns.

### Library Dependencies

**workflow-state-machine.sh** (≥2.0.0):
- sm_init: State machine initialization
- sm_transition: State validation and transitions
- save_completed_states_to_state: Array persistence

**state-persistence.sh** (≥1.5.0):
- append_workflow_state: Variable persistence
- load_workflow_state: State restoration
- ensure_artifact_directory: Directory creation

**error-handling.sh**:
- ensure_error_log_exists: Error log initialization
- setup_bash_error_trap: Bash error trap setup
- log_command_error: Structured error logging

**checkbox-utils.sh**:
- mark_phase_complete: Checkbox state updates
- add_complete_marker: Phase status markers

### Agent Dependencies

**implementer-coordinator.md**:
- Used by: /implement Block 1b
- Input contract: plan_path, topic_path, summaries_dir, artifact_paths, continuation_context, iteration
- Return signal: IMPLEMENTATION_COMPLETE with metadata

**test-executor.md**:
- Used by: /test Block 3
- Input contract: plan_path, topic_path, artifact_paths, test_config, output_path
- Return signal: TEST_COMPLETE with metadata (status, framework, next_state)

**debug-analyst.md**:
- Used by: /test Block 5 (conditional)
- Input contract: issue_description, failed_phase, test_command, exit_code, debug_directory
- Return signal: DEBUG_COMPLETE

### Prerequisite Phases

**Phase 0 must complete before Phases 1, 4** (state machine standards updated)
**Phases 1-3 create /implement** (must complete before Phase 6 integration testing)
**Phases 4-5 create /test** (must complete before Phase 6 integration testing)
**Phase 6 must complete before Phase 7** (verify functionality before documenting)

## Risk Mitigation

### High-Risk Items

**Coverage Loop Infinite Loops**:
- Risk: Loop never exits (test failures persist, coverage stuck)
- Mitigation: Max iterations (5), stuck detection (2 iterations), fail-fast to debug
- Validation: Integration test with intentional test failures and coverage stagnation

**Summary Auto-Discovery Failures**:
- Risk: No summary found, /test cannot extract context
- Mitigation: Graceful fallback (use plan only), clear error messages, warn if summary missing
- Validation: Test /test without prior /implement run, verify fallback behavior

**State Persistence Across Commands**:
- Risk: /test cannot access /implement state if state file not found
- Mitigation: State file optional (summary provides context), plan-based state file naming
- Validation: Integration test verifies state restoration and fallback

**Checkpoint Schema Changes**:
- Risk: Existing /build checkpoints incompatible with /implement
- Mitigation: Preserve checkpoint format, test resumption in Phase 6
- Fallback: Document manual checkpoint migration if needed

### Medium-Risk Items

**Test Writing Clarity**:
- Risk: Users unclear when to write tests (in /implement vs /test)
- Mitigation: Comprehensive documentation (implement-test-workflow.md), examples in guides
- Validation: User testing with new developers, clear docs in Phase 0

**Coverage Threshold Configuration**:
- Risk: Hardcoded 80% threshold not suitable for all projects
- Mitigation: Document override mechanisms (--coverage-threshold flag, plan metadata)
- Validation: Test --coverage-threshold flag, document in command guide

**Agent Contract Changes**:
- Risk: Agents expect full workflow context
- Mitigation: Agents already isolated via input contracts (no changes needed)
- Validation: Unit tests verify agent delegation with partial context

**Error Handling Gaps**:
- Risk: New error paths not logged
- Mitigation: Comprehensive log_command_error integration in every validation
- Validation: Use /errors command to verify all error types logged (Phase 6)

### Low-Risk Items

**Tool Access Changes**:
- Risk: Commands need different tool permissions
- Mitigation: Both commands use same tool set as /build (no changes)

**Buffer-Opener Hook**:
- Risk: Hook expects specific signal format
- Mitigation: Both commands emit same IMPLEMENTATION_COMPLETE format as /build
- Validation: Test buffer opens implementation summary

## Notes

### Phase 0 Justification [COMPLETE]

This plan includes Phase 0 because it proposes changes to the state machine's transition table and workflow type definitions, which are project-wide standards defined in workflow-state-machine.sh. The current standard enforces `[implement]="test"`, preventing implement-only workflows. The proposed change extends the transition table to `[implement]="test,complete"` and adds two new workflow types (implement-only, test-and-debug) to enable independent execution of implementation and testing workflows.

**Standards Sections Affected**:
- `state_based_orchestration` (CLAUDE.md): Documents workflow types and state transitions
- `command_reference` (command-reference.md): Lists command workflows and terminal states

**Documentation Priority**: Phase 0 creates comprehensive documentation standards (implement-test-workflow.md, testing-protocols.md updates) before implementation begins. This ensures clear guidance for test writing responsibility, coverage loops, and summary-based handoff patterns.

### Complexity Score Calculation

```
Score = Base(refactor) + Tasks/2 + Files*3 + Integrations*5
      = 5 + (45/2) + (4*3) + (3*5)
      = 5 + 22.5 + 12 + 15
      = 54.5
```

**Breakdown**:
- Base: 5 (refactor type)
- Tasks: 45 tasks across 7 phases (/2 = 22.5)
- Files: 4 files created/modified (implement.md, test.md, workflow-state-machine.sh, build.md)
- Integrations: 3 agent integrations (implementer-coordinator, test-executor, debug-analyst)

**Tier Selection**: Score 54.5 → Tier 1 (single file, 50-200 range borderline but plan is cohesive enough for single file)

### Expansion Hint

While this plan uses Level 0 (single file) structure, the complexity score (54.5) suggests some phases could benefit from expansion during implementation. Consider using `/expand phase 4` for the /test command creation phase (8 tasks, high complexity) if additional detail is needed during implementation.
