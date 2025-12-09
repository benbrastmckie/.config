# Debug Strategy Plan: Lean-Implement Coordinator Delegation Failure

## Metadata
- **Date**: 2025-12-09 (Revised)
- **Feature**: Fix lean-implement coordinator delegation failure where primary agent performs direct implementation work instead of delegating to lean-coordinator subagents
- **Status**: [NOT STARTED]
- **Estimated Hours**: 7-10 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis: Coordinator Delegation Failure](../reports/001-root-cause-analysis.md)
- **Related Plans**:
  - [Plan 002: Remaining Phases 8-9-10](../../047_lean_implement_coordinator_waves/plans/002-remaining-phases-8-9-10-plan.md)
- **Complexity Score**: 52 (High)
- **Structure Level**: 1
- **Expanded Phases**: [3, 4]

---

## Overview

The `/lean-implement` command switches from coordinating lean-coordinator subagent delegation to performing direct proof work with the primary agent after the coordinator completes Phase 1 with partial success. This debug strategy addresses the root cause (missing hard barrier after Block 1c) and implements strategic fixes to prevent recurrence.

**Root Cause**: Missing `exit 0` enforcement after Block 1c iteration decision allows primary agent to continue execution and perform implementation work that should be delegated to coordinators.

**Evidence**: After lean-coordinator returns with partial success (4/5 theorems proven), the primary agent directly calls Read, lean_goal, lean_multi_attempt, and Edit tools—violating the delegation contract (lines 48-106 in lean-implement-output.md).

---

## Success Criteria
- [ ] Hard barrier enforced after Block 1c iteration decision when `requires_continuation=true`
- [ ] Delegation contract validation blocks primary agent implementation tool usage
- [ ] Integration test validates partial success triggers re-delegation (not primary agent takeover)
- [ ] Coordinator-triggered plan revision handles blocking dependencies (Phase 8 from Plan 002)
- [ ] Wave-based full plan delegation eliminates per-phase routing gaps (Phase 9 from Plan 002)
- [ ] Context exhaustion eliminated via wave-based full plan delegation
- [ ] 40-60% time savings achieved through parallel wave execution

---

## Technical Design

### Four-Tier Fix Strategy

**Tier 1: Immediate Fix (Hard Barrier Enforcement)**
- Add `exit 0` after iteration decision in Block 1c when continuation required
- Prevents primary agent from performing implementation work after coordinator return
- Enables clean iteration loop back to Block 1b for re-delegation

**Tier 2: Validation Layer (Delegation Contract)**
- Add tool usage audit in Block 1c to detect prohibited primary agent operations
- Blocks workflow if primary agent used Edit, lean_goal, lean_multi_attempt, or other implementation tools
- Provides early detection and clear error messaging for delegation violations

**Tier 3: Plan Revision Workflow (Phase 8 from Plan 002)**
- Add blocking detection to lean-coordinator (STEP 3.5) when `theorems_partial > 0`
- Trigger `/revise` via Task delegation to add missing infrastructure phases
- Recalculate wave dependencies after plan mutation
- Enforce MAX_REVISION_DEPTH=2 to prevent infinite revision loops

**Tier 4: Wave-Based Full Plan Delegation (Phase 9 from Plan 002)**
- Transform from per-phase routing to full plan delegation
- Eliminates multiple coordinator return points where delegation can break
- Achieves 40-60% time savings through parallel wave execution
- Requires Tier 3 for handling blocking dependencies discovered mid-execution

### Architecture Changes

**Block 1c Iteration Decision Logic (BEFORE)**:
```bash
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING_NEW" ]; then
  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  echo "**ITERATION LOOP**: Return to Block 1b with updated state"
  # PRIMARY AGENT CONTINUES EXECUTING - BUG!
fi
```

**Block 1c Iteration Decision Logic (AFTER)**:
```bash
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING_NEW" ]; then
  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING_NEW"

  echo "**ITERATION LOOP**: Returning to Block 1b for re-delegation"

  # HARD BARRIER: PRIMARY AGENT STOPS HERE
  # Execution resumes at Block 1b on next iteration
  exit 0
fi
```

---

## Implementation Phases

### Phase 1: Enforce Hard Barrier After Block 1c Iteration Decision [NOT STARTED]
dependencies: []

**Objective**: Add `exit 0` enforcement after iteration decision to prevent primary agent from continuing execution when coordinator returns with partial success.

**Complexity**: Low

**Tasks**:
- [ ] Locate Block 1c iteration decision logic in /lean-implement.md (line ~1161-1220)
- [ ] Add `exit 0` statement immediately after iteration decision when `requires_continuation=true`
- [ ] Add comment explaining hard barrier enforcement pattern
- [ ] Verify state variables (ITERATION, WORK_REMAINING) updated before exit
- [ ] Test iteration loop resumes at Block 1b (not Block 1c) on next invocation

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-iteration-loop.log", "phase1-validation.json"]

**Testing**:
```bash
# Unit Test: Verify exit enforcement
grep -A 5 "ITERATION LOOP" .claude/commands/lean-implement.md | grep -q "exit 0"
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Integration Test: Partial success re-delegation
# Setup: Mock coordinator returns work_remaining=Phase_2
# Expected: Command exits with code 0, ITERATION=2 in state file
# Expected: No primary agent Read/Edit/lean_goal tool calls after coordinator return
```

**Validation**:
- [ ] `exit 0` statement appears after iteration decision conditional
- [ ] State variables updated before exit (ITERATION, WORK_REMAINING)
- [ ] Integration test confirms no primary agent implementation work after exit

**Expected Duration**: 0.5 hours

---

### Phase 2: Add Delegation Contract Validation [NOT STARTED]
dependencies: [1]

**Objective**: Implement tool usage audit in Block 1c to detect and block primary agent implementation operations that violate the delegation contract.

**Complexity**: Medium

**Tasks**:
- [ ] Create validation function `validate_delegation_contract()` in lean-implement.md
- [ ] Parse workflow log for prohibited tool patterns: Edit, lean-lsp, lean_goal, lean_multi_attempt
- [ ] Add validation call in Block 1c after hard barrier verification (line ~962)
- [ ] Log delegation violations via log_command_error with validation_error type
- [ ] Include prohibited tool counts and categories in error details JSON
- [ ] Exit with code 1 if delegation contract violated
- [ ] Add allowed tool whitelist: Bash, Read (summary files only), Grep (logs only)

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["delegation-validation.log", "phase2-validation.json"]

**Testing**:
```bash
# Unit Test 1: Prohibited Tool Detection
# Inject mock Edit tool usage into workflow log
echo "● Edit(Logos/Core/Metalogic/DeductionTheorem.lean)" > test_workflow.log
RESULT=$(bash -c 'source .claude/commands/lean-implement.md; validate_delegation_contract test_workflow.log' 2>&1)
echo "$RESULT" | grep -q "Delegation contract violation"
test $? -eq 0 || exit 1

# Unit Test 2: Allowed Tool Acceptance
echo "● Bash(ls .claude/specs/047/summaries)" > test_workflow.log
echo "● Read(/path/to/summary.md)" >> test_workflow.log
RESULT=$(bash -c 'source .claude/commands/lean-implement.md; validate_delegation_contract test_workflow.log' 2>&1)
echo "$RESULT" | grep -q "Delegation contract validated"
test $? -eq 0 || exit 1

# Integration Test: Violation Detection After Coordinator Return
# Setup: Mock coordinator return + primary agent Edit call
# Expected: Validation fails, error logged, exit code 1
```

**Validation**:
- [ ] Validation function detects all prohibited tool categories
- [ ] Allowed tools (Bash orchestration, Read summary) pass validation
- [ ] Error logging includes structured data with tool usage counts
- [ ] Integration test confirms validation blocks workflow on violation

**Expected Duration**: 1 hour

---

### Phase 3: Implement Coordinator-Triggered Plan Revision (Phase 8 from Plan 002) [NOT STARTED]
dependencies: [1, 2]

**Objective**: Add automated plan revision workflow to lean-coordinator that detects blocking dependencies from lean-implementer output, invokes a specialized `lean-plan-updater` subagent via Task delegation, and recalculates wave dependencies after plan mutation.

**Complexity**: High
**Status**: PENDING

**Summary**: Creates lean-plan-updater agent for Lean-specific plan mutations, adds STEP 3.5 blocking detection to lean-coordinator, implements context budget checks and revision depth limiting (MAX_REVISION_DEPTH=2), and integrates dependency recalculation after plan changes.

For detailed tasks, implementation specifications, and testing, see [Phase 3 Details](phase_3_coordinator_plan_revision.md)

**Expected Duration**: 3-4 hours

---

### Phase 4: Implement Wave-Based Full Plan Delegation (Phase 9 from Plan 002) [NOT STARTED]
dependencies: [3]

**Objective**: Transform /lean-implement from per-phase routing to full plan delegation with wave-based parallel execution, eliminating multiple coordinator return points where delegation can break.

**Complexity**: High
**Status**: PENDING

**Summary**: Refactors Block 1a/1b/1c to use EXECUTION_MODE="full-plan", integrates dependency-analyzer.sh for wave calculation, implements parallel Task invocations per wave with synchronization barriers, and triggers iteration only on context threshold (not per-phase). Achieves 40-60% time savings and 96% context reduction.

For detailed tasks, implementation specifications, and testing, see [Phase 4 Details](phase_4_wave_based_delegation.md)

**Expected Duration**: 2-3 hours

---

### Phase 5: Integration Testing and Validation [NOT STARTED]
dependencies: [4]

**Objective**: Create comprehensive integration test suite validating hard barrier enforcement, delegation contract validation, plan revision workflow, and wave-based full plan delegation workflows.

**Complexity**: Medium

**Reference**: See [Plan 002 Phase 10](../../047_lean_implement_coordinator_waves/plans/002-remaining-phases-8-9-10-plan.md#phase-10-integration-testing-and-documentation-not-started) for full technical design.

**Tasks**:
- [ ] Create test script: .claude/tests/integration/test_delegation_fix.sh
- [ ] Add test_partial_success_redelegation() function with mock coordinator output
- [ ] Add test_delegation_contract_violation() function with primary agent tool injection
- [ ] Add test_plan_revision_workflow() function with mock lean-implementer output containing theorems_partial field
- [ ] Add test_wave_based_timing() function with sequential vs parallel comparison
- [ ] Add test_context_threshold_checkpoint() function with CONTEXT_THRESHOLD=50 trigger
- [ ] Implement mock_coordinator_response() helper for realistic output without full execution
- [ ] Add timing measurement pattern using Bash SECONDS variable
- [ ] Generate test artifacts: delegation-validation.log, wave-metrics.json, test-execution.log
- [ ] Run full test suite and validate all tests pass

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-delegation-fix.log", "test-results.json", "coverage-report.txt"]

**Testing**:
```bash
# Execute integration test suite
bash .claude/tests/integration/test_delegation_fix.sh --verbose
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Validate test coverage
# Expected: 6 test functions, 18+ assertions, 100% pass rate
TEST_COUNT=$(grep -c "^test_" .claude/tests/integration/test_delegation_fix.sh)
test "$TEST_COUNT" -ge 6 || exit 1

# Verify test artifacts generated
test -f delegation-validation.log || exit 1
test -f wave-metrics.json || exit 1
jq -e '.time_savings_percent >= 40' wave-metrics.json || exit 1
```

**Validation**:
- [ ] All 6 integration tests pass (100% success rate)
- [ ] Partial success test confirms re-delegation (no primary agent implementation)
- [ ] Delegation contract test detects prohibited tool usage
- [ ] Plan revision test verifies infrastructure phase addition and wave recalculation
- [ ] Wave-based timing test measures 40-60% time savings
- [ ] Checkpoint resume test validates state restoration

**Expected Duration**: 1.5 hours

---

## Testing Strategy

### Overall Approach
Four-tier testing strategy aligning with fix tiers:

1. **Unit Tests**: Validate individual components (exit enforcement, tool detection, blocking detection, wave calculation)
2. **Integration Tests**: Validate end-to-end workflows (partial success re-delegation, contract validation, plan revision, wave execution)
3. **Performance Tests**: Measure time savings from wave-based parallelization (40-60% threshold)
4. **Regression Tests**: Ensure plan revision doesn't introduce circular dependencies or infinite loops

### Test Fixtures
- Mock coordinator output files with partial success signals
- Mock workflow logs with primary agent tool usage
- Mock lean-implementer output with theorems_partial and diagnostics fields
- Test plans with dependency graphs for wave calculation
- Timing baselines for sequential vs parallel execution

### Success Metrics
- 100% integration test pass rate (6/6 tests)
- Zero primary agent implementation tool calls after coordinator return
- Plan revision triggers correctly when theorems_partial > 0 and context budget >= 30k
- MAX_REVISION_DEPTH=2 enforced (no infinite revision loops)
- Context usage reduced by 95% via brief summary parsing
- Time savings 40-60% for plans with 2+ parallel phases

---

## Documentation Requirements

### Files to Update
1. **lean-implement.md**: Add hard barrier enforcement section, delegation contract validation
2. **lean-coordinator.md**: Add blocking detection (STEP 3.5), wave execution loop section, parallel Task invocation patterns
3. **CLAUDE.md hierarchical_agent_architecture**: Update lean-implement coordinator example with metrics
4. **.claude/docs/concepts/hierarchical-agents-examples.md**: Add Example 9 for delegation fix with before/after comparison

### Documentation Standards
- Non-interactive testing patterns only (no manual verification)
- Code examples with exit codes and validation assertions
- Performance metrics with timing instrumentation
- Before/after architecture diagrams showing delegation flow
- Plan revision workflow with MAX_REVISION_DEPTH documentation

---

## Dependencies

### External Dependencies
- dependency-analyzer.sh script exists (Phase 4 integration)
- dependency-recalculation.sh script exists (Phase 3 integration)
- log_command_error function available (error logging integration)
- workflow-state-machine.sh functions (state persistence)
- Hard barrier pattern standards (hierarchical-agents-coordination.md)

### New Artifacts to Create
- lean-plan-updater.md agent behavioral file (Phase 3) - specialized agent for Lean plan revision

### Prerequisites
- Plan 002 Phase 8 architectural context (plan revision workflow design)
- Plan 002 Phase 9 architectural context (wave-based delegation design)
- Root cause analysis report (delegation failure diagnostics)
- Existing integration test infrastructure (test_lean_implement_coordinator_waves.sh)

---

## Risk Analysis

### Risk 1: Hard Barrier Exit Breaks Iteration Resume (MEDIUM)
**Description**: Adding `exit 0` after iteration decision might break state restoration on resume
**Mitigation**:
- Verify state variables (ITERATION, WORK_REMAINING) updated before exit
- Test iteration loop resumes at Block 1b (not Block 1c) on next invocation
- Add integration test for multi-iteration workflows with partial success

### Risk 2: Delegation Contract False Positives (LOW)
**Description**: Validation might block legitimate primary agent tool usage (e.g., reading summary files)
**Mitigation**:
- Whitelist allowed tools: Bash orchestration, Read summary files, Grep logs
- Use precise regex patterns for prohibited tools (Edit, lean_goal, lean_multi_attempt)
- Add unit tests for both prohibited and allowed tool patterns

### Risk 3: Plan Revision Infinite Loop (HIGH)
**Description**: Plan revision could trigger repeatedly if blocking dependencies keep appearing
**Mitigation**:
- Enforce MAX_REVISION_DEPTH=2 limit with hard check before triggering /revise
- Log revision_limit_reached error when depth exceeded
- Defer revision to next iteration via checkpoint if context budget insufficient
- Validate plan structure after revision to detect circular dependencies

### Risk 4: Wave-Based Refactor Introduces New Bugs (HIGH)
**Description**: Phase 9 refactor changes coordinator input contract and iteration logic
**Mitigation**:
- Implement Phase 1-3 (hard barrier + validation + plan revision) first as safety net
- Test Phase 4 with mock coordinator responses before full integration
- Maintain per-phase routing as fallback mode (EXECUTION_MODE flag)
- Comprehensive integration test suite with timing instrumentation

---

## Rollback Plan

### If Hard Barrier Causes Issues
- Remove `exit 0` statement from Block 1c iteration decision
- Revert to echo-only pattern (original behavior)
- Investigate state restoration failures via debug logging

### If Delegation Contract Blocks Valid Work
- Adjust tool whitelist to include legitimate patterns
- Add exemption conditional for specific workflow states
- Review workflow logs to identify false positive patterns

### If Plan Revision Causes Issues
- Disable revision trigger by setting MAX_REVISION_DEPTH=0
- Restore plan from backup if circular dependencies introduced
- Log revision failures and defer to manual intervention
- Revert lean-coordinator.md STEP 3.5 changes
- If lean-plan-updater agent fails consistently, fall back to manual plan updates

### If Wave-Based Refactor Fails
- Revert Block 1a/1b/1c changes to per-phase routing
- Maintain hard barrier fix from Phase 1 (independent of Phase 4)
- Keep plan revision from Phase 3 (can work with per-phase routing)
- Defer wave-based execution to separate spec with more testing

---

## Completion Checklist

Before marking this plan complete, verify:
- [ ] Hard barrier enforced in Block 1c (exit 0 statement present)
- [ ] Delegation contract validation detects prohibited primary agent tool usage
- [ ] lean-plan-updater.md agent created with complete behavioral specification
- [ ] Coordinator-triggered plan revision implemented via lean-plan-updater (Phase 8 from Plan 002)
- [ ] Blocking detection extracts theorems_partial and diagnostics from lean-implementer output
- [ ] MAX_REVISION_DEPTH=2 enforced to prevent infinite revision loops
- [ ] Wave-based full plan delegation implemented (Phase 9 from Plan 002)
- [ ] Integration tests pass (100% success rate - 6 tests)
- [ ] Performance metrics show 40-60% time savings for parallel phases
- [ ] Documentation updated (lean-implement.md, lean-coordinator.md, CLAUDE.md)
- [ ] No primary agent implementation work after coordinator return (delegation contract validated)
- [ ] Context exhaustion eliminated via wave-based orchestration

---

## Phase Dependency Graph

```
Phase 1: Hard Barrier Enforcement
    |
    v
Phase 2: Delegation Contract Validation
    |
    v
Phase 3: Plan Revision Workflow (Phase 8 from Plan 002)
    |
    v
Phase 4: Wave-Based Full Plan Delegation (Phase 9 from Plan 002)
    |
    v
Phase 5: Integration Testing and Validation
```

**Note**: Phases 3 and 4 correspond to Phases 8 and 9 from the original Plan 002 (`002-remaining-phases-8-9-10-plan.md`). Phase 4 depends on Phase 3 because wave-based execution requires the plan revision infrastructure to handle blocking dependencies discovered mid-execution.
