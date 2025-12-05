# Implementation Plan: /implement Iteration Loop Continuation Fix

## Metadata

- **Date**: 2025-12-05
- **Feature**: Add defensive validation to /implement iteration loop to enforce mandatory continuation when work remains
- **Status**: [COMPLETE]
- **Estimated Hours**: 3-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Research Report](../reports/001-implement-iteration-continuation-fix-analysis.md)

---

## Problem Summary

The /implement command's iteration loop (Block 1c, lines 853-895) has a critical bug where it trusts the implementer-coordinator agent's `requires_continuation` signal without validating against `work_remaining`. This allows the agent to return `requires_continuation: false` even when `work_remaining` contains incomplete phases, causing the workflow to halt prematurely.

**Root Cause**: Naive trust of agent signals without defensive validation.

**Impact**: Large plans with multiple phases may halt after a single iteration despite incomplete work, requiring manual re-invocation of `/implement`.

---

## Solution Strategy

Add defensive validation in Block 1c that overrides the agent's `requires_continuation` signal when `work_remaining` is non-empty. This enforces the contract invariant: **If work remains, continuation is mandatory.**

The fix includes:
1. Helper function to check if `work_remaining` is truly empty
2. Defensive override logic that validates agent signal against actual work
3. Error logging for agent contract violations
4. Updated agent contract documentation
5. Test coverage for validation scenarios

---

### Phase 1: Add Defensive Validation to /implement Block 1c [COMPLETE]

**Objective**: Add helper function and defensive validation logic to Block 1c that overrides `requires_continuation` when work remains.

**Success Criteria**:
- [x] Helper function `is_work_remaining_empty()` added to Block 1c
- [x] Defensive validation section added after line 851 (WORK_REMAINING format conversion)
- [x] Validation overrides `REQUIRES_CONTINUATION` to "true" when work_remaining is non-empty
- [x] Error logged to errors.jsonl with type `validation_error` on override
- [x] Continuation check comment updated to reflect validation

**Tasks**:
- [x] Add `is_work_remaining_empty()` helper function to Block 1c
  - Function checks for empty string, "0", "[]", and whitespace-only
  - Returns 0 (true) if empty, 1 (false) if work remains
  - Implements defensive pattern from research report (lines 242-261)

- [x] Add defensive validation section after line 851 in Block 1c
  - Insert between WORK_REMAINING format conversion and continuation check
  - Check if work remains using `is_work_remaining_empty()`
  - If work remains and `REQUIRES_CONTINUATION != "true"`, override to "true"
  - Log warning message with work_remaining value
  - Log validation_error to errors.jsonl using `log_command_error`
  - If no work remains, accept agent signal without override

- [x] Update continuation check comment (line 854)
  - Change from "Trust the implementer-coordinator's requires_continuation signal"
  - To "Trust the implementer-coordinator's requires_continuation signal (now validated)"

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/implement.md` (Block 1c, lines 852-895)

**Implementation Notes**:
- Follow defensive programming pattern from research report section "Proposed Solution"
- Use error logging pattern from error-handling.sh library
- Preserve existing continuation logic flow (no behavior changes for compliant agents)
- Override is silent (no workflow halt) but logged for diagnostics

---

### Phase 2: Update Agent Contract Documentation [COMPLETE]

**Objective**: Document the `work_remaining` / `requires_continuation` invariant in implementer-coordinator.md to prevent future agent bugs.

**Success Criteria**:
- [x] "Return Signal Contract" section added to implementer-coordinator.md
- [x] Invariant relationship between `work_remaining` and `requires_continuation` documented
- [x] Defensive orchestrator behavior documented (override logic)
- [x] Implementation note added for agent developers
- [x] Contract violation table added with validity indicators

**Tasks**:
- [x] Add "Return Signal Contract" section after line 567 in implementer-coordinator.md
  - Document CRITICAL INVARIANT table (from research report lines 410-416)
  - Explain valid and invalid signal combinations
  - Document defensive orchestrator override behavior
  - Add implementation note: "Always set requires_continuation=true when work_remaining contains phase identifiers"

- [x] Update "Output Format" section (lines 542-567)
  - Add reference to new "Return Signal Contract" section
  - Emphasize that contract invariant is enforced by orchestrator
  - Note that violations trigger validation_error log entry

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (after line 567)

**Implementation Notes**:
- Use table format from research report (lines 410-416)
- Emphasize that override is defensive (prevents workflow halt)
- Link to /errors command for diagnostics

---

### Phase 3: Add Test Coverage for Defensive Validation [COMPLETE]

**Objective**: Create test cases that validate the defensive validation logic handles all scenarios correctly.

**Success Criteria**:
- [x] Test file created: `.claude/tests/commands/test_implement_defensive_validation.sh`
- [x] Unit test for `is_work_remaining_empty()` function (5 test cases)
- [x] Integration test for defensive override scenario (agent bug injection)
- [x] Test validates error logging to errors.jsonl
- [x] Test validates workflow continuation despite agent bug

**Tasks**:
- [x] Create test file: `.claude/tests/commands/test_implement_defensive_validation.sh`
  - Follow testing-protocols.md structure
  - Source required libraries (error-handling.sh, test-utils.sh)
  - Set up test fixtures (plan files, state files)

- [x] Add unit test: `test_is_work_remaining_empty()`
  - Test Case 1: Empty string "" → returns 0 (empty)
  - Test Case 2: Literal "0" → returns 0 (empty)
  - Test Case 3: Empty array "[]" → returns 0 (empty)
  - Test Case 4: Whitespace "   " → returns 0 (empty)
  - Test Case 5: Work remains "Phase_4 Phase_5" → returns 1 (not empty)

- [x] Add integration test: `test_defensive_override_agent_bug()`
  - Setup: Create 10-phase plan
  - Mock: Agent returns `requires_continuation: false` with `work_remaining: Phase_4 Phase_5 Phase_6`
  - Execute: Invoke /implement (single iteration)
  - Assert: REQUIRES_CONTINUATION overridden to "true"
  - Assert: validation_error logged to errors.jsonl
  - Assert: Workflow continues to next iteration (not halted)

- [x] Add integration test: `test_no_override_when_agent_correct()`
  - Setup: Create 5-phase plan
  - Mock: Agent returns `requires_continuation: true` with `work_remaining: Phase_4 Phase_5`
  - Execute: Invoke /implement (single iteration)
  - Assert: No override occurs (REQUIRES_CONTINUATION remains "true")
  - Assert: No validation_error logged
  - Assert: Workflow continues normally

**Files Created**:
- `/home/benjamin/.config/.claude/tests/commands/test_implement_defensive_validation.sh`

**Implementation Notes**:
- Use mocking pattern from existing /implement tests
- Verify error log entries using jq queries
- Test both override and no-override scenarios
- Follow test isolation standards (cleanup after each test)

---

### Phase 4: Update Documentation [COMPLETE]

**Objective**: Document the defensive validation behavior in user-facing guides and troubleshooting documentation.

**Success Criteria**:
- [x] Implement command guide updated with defensive validation section
- [x] Troubleshooting section added for continuation override scenarios
- [x] Error catalog updated with new validation_error type

**Tasks**:
- [x] Update `.claude/docs/guides/commands/implement-command-guide.md`
  - Add "Defensive Validation" section under "Iteration Management"
  - Explain work_remaining validation and override behavior
  - Document that overrides are logged but don't halt workflow
  - Add example of override warning message

- [x] Update `.claude/docs/troubleshooting/implement-command-errors.md` (create if not exists)
  - Add "Why did my workflow continue despite agent returning false?" section
  - Explain defensive override logic
  - Show how to diagnose agent bugs using `/errors --type validation_error`
  - Provide example error log entry

- [x] Update `.claude/docs/reference/standards/error-handling.md`
  - Add validation_error type to error catalog
  - Document continuation override use case
  - Add example log entry for agent contract violation

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md`
- `/home/benjamin/.config/.claude/docs/troubleshooting/implement-command-errors.md` (create if needed)
- `/home/benjamin/.config/.claude/docs/reference/standards/error-handling.md`

**Implementation Notes**:
- Use clear, user-friendly language
- Emphasize that override is a feature (defensive programming)
- Link to /errors command for diagnostics
- Include example commands for troubleshooting

---

## Testing Strategy

### Unit Testing
- Test `is_work_remaining_empty()` function with all edge cases (empty, "0", "[]", whitespace, work remaining)
- Verify function returns correct exit codes (0 for empty, 1 for not empty)

### Integration Testing
- Test defensive override scenario (agent bug: work remains but requires_continuation=false)
- Test no-override scenario (agent correct: work remains and requires_continuation=true)
- Test completion scenario (no work remains and requires_continuation=false)
- Verify error logging for each scenario
- Verify workflow continuation behavior

### Manual Testing
- Create 10-phase test plan
- Run /implement with --max-iterations=2
- Verify defensive override occurs if agent returns incorrect signal
- Verify error log entry created
- Verify workflow completes all phases across iterations

---

## Rollback Plan

If defensive validation causes issues:

1. **Disable Override Logic**:
   - Comment out override section in Block 1c (lines 852-880)
   - Revert to naive trust of agent signal
   - Document reason for rollback

2. **Fix Agent Instead**:
   - Debug implementer-coordinator.md continuation logic
   - Ensure agent always sets requires_continuation=true when work_remaining is non-empty
   - Re-enable defensive validation after agent fix

3. **Add --strict Flag** (future enhancement):
   - Add flag to disable defensive overrides for debugging
   - Allow strict mode for testing agent contract compliance
   - Default behavior remains defensive (overrides enabled)

---

## Dependencies

- None (self-contained fix within /implement command)

---

## Risk Assessment

**Low Risk**: Defensive validation only overrides agent signal when work remains, ensuring workflow continuation. Compliant agents see no behavior change. Non-compliant agents get defensive override instead of workflow halt (user experience improvement).

**Potential Issues**:
- Override may mask agent bugs → Mitigation: Error logging ensures visibility
- False positives if work_remaining format is unexpected → Mitigation: Format conversion handles legacy formats

---

## Success Metrics

- [ ] All test cases pass (unit + integration)
- [ ] No workflow halts with incomplete work_remaining
- [ ] validation_error logs created on agent contract violations
- [ ] Documentation updated and reviewed
- [ ] Manual testing confirms defensive override works correctly

---

## Notes

This fix follows the defensive programming pattern established in the codebase (hard barrier validation, validation-utils.sh). The defensive override ensures workflow robustness without breaking existing functionality.

**Alternative Approaches Considered** (see research report):
1. Fix agent instead of orchestrator → Rejected (doesn't prevent future bugs)
2. Mandatory continuation until max_iterations → Rejected (agent loses early halt control)
3. Require both signals to agree → Rejected (halts workflow instead of continuing)

**Next Steps After Implementation**:
1. Monitor `/errors --type validation_error` for agent contract violations
2. If violations frequent, investigate implementer-coordinator continuation logic
3. Consider adding --strict flag for agent debugging (future enhancement)
