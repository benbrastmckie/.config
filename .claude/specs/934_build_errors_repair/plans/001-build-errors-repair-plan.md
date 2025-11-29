# Build Errors Repair Implementation Plan

## Metadata
- **Date**: 2025-11-29 (Revised: 2025-11-29)
- **Feature**: /build Command Error Repair
- **Scope**: Fix 12 remaining /build command errors across 5 error patterns (75% of original 16 errors)
- **Estimated Phases**: 5
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 42.5
- **Research Reports**:
  - [Error Analysis Report](../reports/001-error-report.md)
  - [Repair Analysis Report](../reports/001_repair_analysis.md)
  - [Revision Verification Report](../reports/002_revision_verification.md)
  - [Build Execution Errors Analysis](../reports/003_build_execution_errors.md)

## Overview

This plan addresses the remaining 12 unresolved errors (75% of the original 16 errors) from /build command failures logged between 2025-11-21 and 2025-11-29. Task 947 (idempotent state transitions) resolved 3 state machine errors (19%), leaving critical issues: missing function definitions (31%), state file parsing failures (12.5%), and minor utility/test execution errors (12%).

The implementation focuses on three high-priority fixes: (1) restoring the missing `save_completed_states_to_state` function, (2) adding defensive state file parsing, and (3) handling test execution errors gracefully. These fixes target the root causes identified in the error analysis reports and follow established error handling patterns.

**IMPORTANT - Scope Clarification**: Analysis of recent build execution outputs (build-output.md and build-output-2.md from Nov 29, 2025) identified bash escaping and state file errors during /build execution. These errors are DISTINCT from the 12 logged errors targeted by this plan and are NOT included in this repair scope. They are non-fatal (100% workflow completion rate), self-recovering (agent retries succeed), and not logged in the error tracking system (transient execution errors). If these errors become persistent, create a separate repair plan targeting dynamic code generation and state file robustness. See [Build Execution Errors Analysis](../reports/003_build_execution_errors.md) for details.

## Research Summary

Analysis of error logs identified five distinct error patterns affecting /build workflows:

**Pattern 1 (31% of errors)**: Missing `save_completed_states_to_state` function causes exit code 127 errors. Function is called but not defined or sourced in state-persistence.sh library. Requires either function restoration from git history or reimplementation.

**Pattern 2 (12.5% of errors)**: State file grep operations fail when STATE_FILE is empty or missing expected keys. Lacks defensive checks before parsing operations.

**Pattern 3 (19% of errors)**: Invalid state machine transitions (test->test, implement->complete) - **RESOLVED by task 947** (spec 947_idempotent_state_transitions) which implemented idempotent same-state transitions. No action required in this plan.

**Pattern 4 (6% of errors)**: Missing `estimate_context_usage` utility function or execution failure. Can be made optional with fallback handling.

**Pattern 5 (6% of errors)**: Test command execution failures trigger error trap during variable assignment. Requires explicit error handling.

**Pattern 6 (6% of errors)**: bashrc sourcing errors - **ALREADY FILTERED** by existing benign error filter in error-handling.sh (lines 1610-1612). No action required in this plan.

Recommended approach: Implement defensive error handling patterns, restore missing library functions, and add proper error suppression for expected failures following Output Formatting Standards and Error Handling Pattern documentation.

## Success Criteria
- [ ] All 5 missing function errors eliminated (Pattern 1: save_completed_states_to_state)
- [ ] State file parsing errors eliminated with defensive checks (Pattern 2)
- [ ] Test execution failures handled gracefully without triggering error trap (Pattern 5)
- [ ] estimate_context_usage function made optional or implemented (Pattern 4)
- [ ] All fixes tested with /build command execution
- [ ] No new errors introduced to error log during implementation
- [ ] Error log status updated to RESOLVED for all 12 addressed errors (Patterns 1, 2, 4, 5)
- [ ] Documentation updated with error handling patterns
- [ ] Pattern 3 (state transitions) confirmed resolved by task 947
- [ ] Pattern 6 (bashrc sourcing) confirmed filtered by existing code

## Technical Design

### Architecture Overview

The /build command operates as a state-driven orchestrator that executes implementation plans through sequential or parallel phase execution. Current error patterns indicate incomplete library sourcing and missing defensive coding practices.

**Component Interactions**:
```
/build command (build.md)
  ├─> Tier 1: error-handling.sh (error logging, trap management)
  ├─> Tier 2: state-persistence.sh (state file operations) [MISSING: save_completed_states_to_state]
  ├─> Tier 3: workflow-state-machine.sh (state transitions) [FIXED by task 947]
  └─> Execution: test commands, phase processing, summary generation
```

### Key Design Decisions

**Decision 1: Function Restoration vs Reimplementation**
- **Approach**: Search git history for `save_completed_states_to_state` definition; if found, restore to state-persistence.sh; if not found, implement based on usage context (saving COMPLETED_PHASES to state file)
- **Rationale**: Preserves original implementation if available; reimplementation as fallback ensures consistent behavior

**Decision 2: Defensive Parsing Pattern**
- **Pattern**: Replace all `VAR=$(grep pattern "$STATE_FILE" | cut ...)` with `VAR=$(grep pattern "$STATE_FILE" 2>/dev/null | cut ...) || VAR=""`
- **Rationale**: Follows Output Formatting Standards for error suppression while preserving error handling; provides fallback empty values for missing keys

**Decision 3: Test Execution Error Handling**
- **Pattern**: Use `set +e` around test command execution to disable trap, capture exit code explicitly
- **Rationale**: Test failures are expected workflow events, not errors; explicit handling allows proper reporting without triggering error trap

**Decision 4: Optional Utility Functions**
- **Pattern**: Wrap `estimate_context_usage` calls with availability check: `command -v estimate_context_usage &>/dev/null && CONTEXT_ESTIMATE=$(...) || CONTEXT_ESTIMATE=""`
- **Rationale**: Makes optional features fail gracefully rather than halting workflow

## Implementation Phases

### Phase 1: Restore Missing save_completed_states_to_state Function [COMPLETE]
dependencies: []

**Objective**: Resolve exit code 127 errors for save_completed_states_to_state function (5 errors, 31% of total)

**Complexity**: Medium

Tasks:
- [x] Search git history for function definition: `git log -S "save_completed_states_to_state" --all --source --full-history` (file: entire repository)
- [x] If found in history: Restore function definition to appropriate location in state-persistence.sh
- [x] If not found: Implement function based on usage context (save COMPLETED_PHASES array to state file)
- [x] Verify function signature matches call sites in build.md (check for parameters)
- [x] Ensure state-persistence.sh sources the function properly (follows three-tier sourcing pattern)
- [x] Add function availability validation check in build.md initialization
- [x] Test function with sample COMPLETED_PHASES data to verify state file persistence

Testing:
```bash
# Test function availability
bash -c 'source /home/benjamin/.config/.claude/lib/core/state-persistence.sh 2>/dev/null && type -t save_completed_states_to_state'

# Test function execution with mock data
bash -c 'source /home/benjamin/.config/.claude/lib/core/state-persistence.sh 2>/dev/null && COMPLETED_PHASES="1,2,3" && save_completed_states_to_state'

# Verify state file contains saved data
cat /tmp/test_state_file | grep COMPLETED_PHASES
```

**Expected Duration**: 2 hours

### Phase 2: Add Defensive State File Parsing [COMPLETE]
dependencies: [1]

**Objective**: Eliminate grep failures on state file operations (2 errors, 12.5% of total)

**Complexity**: Low

Tasks:
- [x] Audit build.md for all grep operations on STATE_FILE variable (search pattern: `grep.*STATE_FILE`)
- [x] Identify all variable assignments from grep operations (lines 233, 254 from error reports)
- [x] Add file existence and non-empty checks before grep operations: `[[ -f "$STATE_FILE" && -s "$STATE_FILE" ]]`
- [x] Refactor grep variable assignments to provide fallback empty values: `VAR=$(grep ... 2>/dev/null | cut ...) || VAR=""`
- [x] Update summary file pattern checks to use conditional constructs: `if grep -q '^\*\*Plan\*\*:' "$LATEST_SUMMARY" 2>/dev/null; then ...`
- [x] Add state file validation function in build.md for initialization phase
- [x] Test with empty state file and missing state file scenarios

Testing:
```bash
# Test empty state file handling
touch /tmp/empty_state && STATE_FILE=/tmp/empty_state && source /home/benjamin/.config/.claude/commands/build.md

# Test missing state file handling
STATE_FILE=/tmp/nonexistent && source /home/benjamin/.config/.claude/commands/build.md

# Verify no error trap triggered
echo $?  # Should be 0 or handled gracefully
```

**Expected Duration**: 1.5 hours

### Phase 3: Fix Test Execution Error Handling [COMPLETE]
dependencies: [2]

**Objective**: Handle test command failures gracefully without triggering error trap (1 error, 6% of total)

**Complexity**: Low

Tasks:
- [x] Locate test execution section in build.md (around line 212 based on error report)
- [x] Identify current pattern: `TEST_OUTPUT=$($TEST_COMMAND 2>&1)`
- [x] Disable error trap around test execution: `set +e` before command, `set -e` after
- [x] Capture test exit code explicitly: `TEST_OUTPUT=$($TEST_COMMAND 2>&1); TEST_EXIT_CODE=$?`
- [x] Add conditional handling for test failures vs test errors (distinguish between test assertion failures and test infrastructure errors)
- [x] Ensure test failures are logged but don't halt build workflow (configurable via flag)
- [x] Update error handling documentation with test execution pattern

Testing:
```bash
# Test with failing test command
TEST_COMMAND="bash -c 'exit 1'" && /build test-plan.md

# Test with successful test command
TEST_COMMAND="bash -c 'echo success; exit 0'" && /build test-plan.md

# Verify error trap not triggered for test failures
grep "Bash error at line 212" /home/benjamin/.config/.claude/data/logs/errors.jsonl | tail -1
```

**Expected Duration**: 1 hour

### Phase 4: Make estimate_context_usage Optional [COMPLETE]
dependencies: [3]

**Objective**: Eliminate estimate_context_usage function errors (1 error, 6% of total)

**Complexity**: Low

Tasks:
- [x] Locate estimate_context_usage call in build.md (around line 243 based on error report)
- [x] Add function availability check: `command -v estimate_context_usage &>/dev/null`
- [x] Provide fallback default value if function not available: `CONTEXT_ESTIMATE="unknown"`
- [x] Wrap function call in conditional: `if command -v estimate_context_usage &>/dev/null; then CONTEXT_ESTIMATE=$(...); else CONTEXT_ESTIMATE="unknown"; fi`
- [x] Verify downstream code handles "unknown" context estimate gracefully
- [x] Document estimate_context_usage as optional utility function
- [x] Consider implementing stub version if context estimation is desired feature

Testing:
```bash
# Test with function unavailable
unset -f estimate_context_usage && /build test-plan.md

# Test with function available (if implemented)
source /home/benjamin/.config/.claude/lib/util/context-utils.sh 2>/dev/null && /build test-plan.md

# Verify no error logged
grep "estimate_context_usage" /home/benjamin/.config/.claude/data/logs/errors.jsonl | tail -1
```

**Expected Duration**: 0.5 hours

### Phase 5: Update Error Log Status and Validate Resolution [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Update error log entries from FIX_PLANNED to RESOLVED and validate all patterns addressed

**Complexity**: Low

Tasks:
- [x] Verify all fixes are working (tests pass, no new errors generated)
- [x] Verify Pattern 3 resolution by task 947:
  ```bash
  # Confirm task 947 resolved state transition errors
  grep "947_idempotent_state_transitions" /home/benjamin/.config/.claude/specs/947_idempotent_state_transitions/plans/001-idempotent-state-transitions-plan.md | head -1
  ```
- [x] Verify Pattern 6 filtering:
  ```bash
  # Confirm bashrc errors are filtered
  grep -A5 "bashrc" /home/benjamin/.config/.claude/lib/core/error-handling.sh | grep -A2 "_is_benign_bash_error"
  ```
- [x] Update error log entries to RESOLVED status for Patterns 1, 2, 4, 5:
  ```bash
  source /home/benjamin/.config/.claude/lib/core/error-handling.sh
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "/home/benjamin/.config/.claude/specs/934_build_errors_repair/plans/001-build-errors-repair-plan.md")
  echo "Resolved $RESOLVED_COUNT error log entries"
  ```
- [x] Verify no FIX_PLANNED errors remain for this plan:
  ```bash
  REMAINING=$(query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | grep -c "934_build_errors_repair" || echo "0")
  [ "$REMAINING" -eq 0 ] && echo "All errors resolved" || echo "WARNING: $REMAINING errors still FIX_PLANNED"
  ```
- [x] Run /build command on test plan to verify no errors logged during execution
- [x] Review error log for any new errors introduced by fixes
- [x] Generate summary report of resolved errors (count by pattern, total impact):
  - Pattern 1: 5 errors (save_completed_states_to_state)
  - Pattern 2: 2 errors (state file parsing)
  - Pattern 3: 3 errors (RESOLVED by task 947)
  - Pattern 4: 1 error (estimate_context_usage)
  - Pattern 5: 1 error (test execution)
  - Pattern 6: 1 error (FILTERED by existing code)
- [x] Update implementation plan with final statistics

Testing:
```bash
# Verify error log status updates
query_errors --status RESOLVED --since 1h | jq -r '.repair_plan_path' | grep -c "934_build_errors_repair"

# Test /build execution generates no errors for patterns 1, 2, 4, 5
/build /tmp/test-plan.md && ! grep "command=/build" /home/benjamin/.config/.claude/data/logs/errors.jsonl | tail -5 | grep "$(date +%Y-%m-%d)"

# Verify 9 directly-fixed errors marked RESOLVED (patterns 1, 2, 4, 5)
DIRECT_FIXES=$(query_errors --status RESOLVED | jq -r '.repair_plan_path' | grep -c "934_build_errors_repair" || echo "0")
[ "$DIRECT_FIXES" -ge 9 ] && echo "SUCCESS: Direct fixes resolved ($DIRECT_FIXES errors)" || echo "WARNING: Only $DIRECT_FIXES errors resolved"

# Note: Pattern 3 (3 errors) resolved by task 947, Pattern 6 (1 error) filtered by existing code
# Total impact: 9 directly fixed + 3 by task 947 + 1 filtered = 13 errors addressed (81% of original 16)
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Test each fixed function in isolation (save_completed_states_to_state with mock data)
- Test defensive parsing with edge cases (empty files, missing files, malformed state files)
- Test error trap behavior around test execution (verify trap doesn't fire on test failures)

### Integration Testing
- Execute /build command on sample implementation plans covering all error scenarios
- Verify state file operations work across full build workflow lifecycle
- Test resume scenarios with partial state files
- Validate error logging captures real errors but not false positives

### Error Log Validation
- Query error log before and after fixes to measure reduction in logged errors
- Verify no new error patterns introduced by changes
- Confirm all 12 targeted errors marked RESOLVED after implementation

### Regression Testing
- Run existing /build test suite to ensure no behavior changes
- Test /build with plans from different complexity levels (simple, medium, complex)
- Verify state machine transitions still work correctly with state persistence changes

## Documentation Requirements

### Code Documentation
- Add inline comments explaining defensive parsing patterns in build.md
- Document save_completed_states_to_state function signature and usage in state-persistence.sh
- Add error handling pattern examples to Error Handling Pattern documentation

### Standards Updates
- Update Output Formatting Standards with state file parsing pattern
- Add test execution error handling pattern to Code Standards
- Document optional utility function pattern in Library API Reference

### User-Facing Documentation
- Update /build command documentation with error recovery capabilities
- Add troubleshooting section for common state file errors
- Document error log status tracking workflow (query → repair → resolve)

## Dependencies

### External Dependencies
- Git history access for function restoration (Phase 1)
- Error handling library functions (mark_errors_resolved_for_plan, query_errors)
- State machine library (workflow-state-machine.sh) - already fixed by task 947

### Internal Dependencies
- Phase 2 depends on Phase 1 (state file operations depend on state persistence functions)
- Phase 3 depends on Phase 2 (test execution happens after state file initialization)
- Phase 4 depends on Phase 3 (context estimation happens during test/execution phase)
- Phase 5 depends on all previous phases (validation phase runs after all fixes implemented)

### Prerequisite Validation
Before starting implementation:
- [ ] Verify task 947 (idempotent state transitions) is complete and merged
- [ ] Confirm error log contains 12 unresolved errors for this plan
- [ ] Validate access to error handling library functions
- [ ] Ensure /build command is executable and testable

## Notes

**Complexity Calculation**:
- Base (fix): 3
- Tasks: 26/2 = 13
- Files: 4 × 3 = 12 (build.md, state-persistence.sh, error-handling.sh, docs)
- Integrations: 2 × 5 = 10 (error log, state machine)
- **Total**: 3 + 13 + 12 + 10 = 38 (rounded to 42.5 with testing overhead)

**Structure Level**: 0 (single file plan, complexity <50)

**Expansion Hint**: If additional error patterns emerge during implementation or if state persistence refactoring becomes necessary, consider using `/expand` to create phase-specific detail files.

**Risk Mitigation**:
- Unknown function implementation risk mitigated by git history search first, implementation second
- Error trap behavior changes tested thoroughly to avoid breaking existing error detection
- State file format changes validated against existing state files to prevent corruption

**Related Work**:
- Task 947 (idempotent state transitions) - **COMPLETED**, resolved 3 errors (Pattern 3)
- Spec 956 (error log status tracking) - provides mark_errors_resolved_for_plan function
- Output Formatting Standards - defines error suppression patterns used in Phase 2
- Build execution errors (build-output.md, build-output-2.md) - **OUT OF SCOPE** for this plan

**Error Pattern Resolution Summary**:
- Pattern 1 (31%): Addressed by Phase 1 (restore save_completed_states_to_state)
- Pattern 2 (12.5%): Addressed by Phase 2 (defensive state file parsing)
- Pattern 3 (19%): **RESOLVED by task 947** (idempotent state transitions)
- Pattern 4 (6%): Addressed by Phase 4 (optional estimate_context_usage)
- Pattern 5 (6%): Addressed by Phase 3 (test execution error handling)
- Pattern 6 (6%): **ALREADY FILTERED** (existing benign error filter)

**Total Impact**:
- Direct fixes by this plan: 9 errors (56% of original 16)
- Resolved by task 947: 3 errors (19%)
- Already filtered: 1 error (6%)
- **Total coverage**: 13 errors (81% of original 16 errors)
