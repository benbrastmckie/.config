# Implementation Plan: /lean-implement Workflow Type Fix

**Date**: 2025-12-04
**Feature**: Fix /lean-implement command workflow type to use valid state machine enum
**Status**: [COMPLETE]
**Estimated Hours**: 1-2 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**: [Workflow Type Integration Analysis](/home/benjamin/.config/.claude/specs/049_lean_implement_workflow_fix/reports/001-workflow-type-integration-analysis.md)

---

## Overview

The `/lean-implement` command currently uses `WORKFLOW_TYPE="lean-implement-hybrid"`, which is not a valid workflow type enum in `workflow-state-machine.sh`. This causes state machine initialization to fail with an enum validation error.

### Root Cause

From research analysis (Section 1.2):
- Line 245 in `/home/benjamin/.config/.claude/commands/lean-implement.md` sets invalid workflow type
- `sm_init()` validation at `workflow-state-machine.sh:471-479` rejects custom types
- Valid types: `research-only`, `research-and-plan`, `research-and-revise`, `full-implementation`, `debug-only`, `implement-only`, `test-and-debug`

### Solution Approach

Use existing `implement-only` workflow type instead of custom `lean-implement-hybrid` type. This is the recommended solution because:

1. **Semantic Equivalence**: Both `/implement` and `/lean-implement` execute implementation without testing
2. **Infrastructure Alignment**: `implement-only` already maps to `STATE_IMPLEMENT` terminal state (Section 7.1)
3. **Minimal Change**: 2-line fix vs multi-file state machine modification
4. **Best Practice Compliance**: Use existing types when functionally equivalent (Section 6.2)
5. **Maintenance Reduction**: No new enum value propagation required

The hybrid routing logic (lean-coordinator vs implementer-coordinator) is an implementation detail of the command, not a workflow scope distinction that requires a separate state machine type.

### Success Criteria

- [ ] State machine initialization succeeds with `implement-only` workflow type
- [ ] State transition `initialize → implement` completes successfully
- [ ] Phase classification still routes Lean phases to lean-coordinator
- [ ] Phase classification still routes software phases to implementer-coordinator
- [ ] Terminal state reached: `STATE_IMPLEMENT`
- [ ] Completion summary displays correctly
- [ ] No regression in existing commands (`/implement`, `/debug`, etc.)

---

## Phase 1: Update Command Workflow Type [COMPLETE]

**Objective**: Replace invalid `lean-implement-hybrid` workflow type with valid `implement-only` type in lean-implement.md

**Dependencies**: None

**Complexity**: Low - Single constant replacement in one file

### Tasks

- [ ] Update workflow type constant (line 245)
  - File: `/home/benjamin/.config/.claude/commands/lean-implement.md`
  - Change: `WORKFLOW_TYPE="lean-implement-hybrid"` → `WORKFLOW_TYPE="implement-only"`
  - Validation: Grep for `WORKFLOW_TYPE=` to confirm update

- [ ] Update documentation comment (line 24)
  - File: `/home/benjamin/.config/.claude/commands/lean-implement.md`
  - Change: `**Workflow Type**: lean-implement-hybrid` → `**Workflow Type**: implement-only`
  - Validation: Grep for `Workflow Type:` to confirm update

### Validation

```bash
# Verify both changes applied
grep -n "WORKFLOW_TYPE\|Workflow Type" /home/benjamin/.config/.claude/commands/lean-implement.md

# Expected output:
#   24:**Workflow Type**: implement-only
#   245:WORKFLOW_TYPE="implement-only"
```

### Success Criteria

- [ ] Line 245 contains `WORKFLOW_TYPE="implement-only"`
- [ ] Line 24 contains `**Workflow Type**: implement-only`
- [ ] No other references to `lean-implement-hybrid` remain in file
- [ ] File syntax remains valid markdown

---

## Phase 2: Validate State Machine Integration [COMPLETE]

**Objective**: Verify state machine accepts `implement-only` workflow type and initializes correctly

**Dependencies**: Phase 1

**Complexity**: Low - Unit testing of state machine functions

### Tasks

- [ ] Test state machine initialization
  - Create minimal test script sourcing `workflow-state-machine.sh`
  - Call `sm_init()` with `implement-only` workflow type
  - Verify exit code is 0 (success)
  - Verify `WORKFLOW_SCOPE` exported as `implement-only`

- [ ] Verify terminal state mapping
  - After `sm_init()`, check `TERMINAL_STATE` variable
  - Expected value: `STATE_IMPLEMENT` (from Section 2.2 line 96-98)
  - Confirms workflow will terminate at implementation without testing

- [ ] Test state transition flow
  - Verify `initialize → implement` transition allowed
  - Transition table (Section 5.1) permits this transition
  - Call `sm_transition "$STATE_IMPLEMENT" "test message"`
  - Verify exit code is 0 and state persisted to state file

### Validation

```bash
# Unit test script
cat > /tmp/test_sm_init.sh << 'EOF'
#!/bin/bash
source /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh 2>/dev/null

# Test initialization
sm_init "/tmp/test-plan.md" "/lean-implement" "implement-only" "1" "[]"
EXIT_CODE=$?

echo "Exit Code: $EXIT_CODE"
echo "Workflow Scope: $WORKFLOW_SCOPE"
echo "Terminal State: $TERMINAL_STATE"

# Expected output:
# Exit Code: 0
# Workflow Scope: implement-only
# Terminal State: implement
EOF

bash /tmp/test_sm_init.sh
```

### Success Criteria

- [ ] `sm_init()` returns exit code 0
- [ ] `WORKFLOW_SCOPE` set to `implement-only`
- [ ] `TERMINAL_STATE` set to `implement` (not `complete`)
- [ ] State transition `initialize → implement` succeeds
- [ ] No validation errors in state machine output

---

## Phase 3: Integration Testing with Test Plan [COMPLETE]

**Objective**: Execute `/lean-implement` command with test plan to verify end-to-end workflow

**Dependencies**: Phase 2

**Complexity**: Medium - Requires creating test plan with mixed Lean/software phases

### Tasks

- [ ] Create test plan file
  - Path: `/home/benjamin/.config/.claude/specs/049_lean_implement_workflow_fix/plans/test-hybrid-plan.md`
  - Include 2 phases: one Lean phase (with `lean_file:` metadata), one software phase
  - Use minimal task lists to reduce execution time
  - Follow plan metadata standard from Section 6.1

- [ ] Execute dry-run test
  - Command: `/lean-implement .claude/specs/049_lean_implement_workflow_fix/plans/test-hybrid-plan.md --dry-run`
  - Verify dry-run output shows correct mode and classification preview
  - Verify no errors during argument parsing and validation

- [ ] Execute full command test
  - Command: `/lean-implement .claude/specs/049_lean_implement_workflow_fix/plans/test-hybrid-plan.md`
  - Monitor Block 1a output for state machine initialization messages
  - Verify phase classification routes correctly (Lean → lean-coordinator, software → implementer-coordinator)
  - Verify completion summary displays (Section 6.3)

- [ ] Verify state persistence
  - Check state file created in `.claude/tmp/`
  - Verify `WORKFLOW_SCOPE` persisted as `implement-only`
  - Verify `CURRENT_STATE` reaches `STATE_IMPLEMENT` (terminal state)

### Validation

Expected console output sequence:
```
=== Hybrid Lean/Software Implementation Workflow ===
Plan File: /home/benjamin/.config/.claude/specs/049_lean_implement_workflow_fix/plans/test-hybrid-plan.md
...
Classification accepted: scope=implement-only, complexity=1, topics=0
State machine initialized: scope=implement-only, terminal=implement
...
=== Hybrid Implementation Complete ===
Summary: [summary text]
Phases: [phase completion status]
Artifacts: [generated artifacts]
```

### Success Criteria

- [ ] Dry-run completes without errors
- [ ] State machine initialization message shows `scope=implement-only`
- [ ] State machine initialization message shows `terminal=implement`
- [ ] Lean phase routes to lean-coordinator (verify in debug log or output)
- [ ] Software phase routes to implementer-coordinator (verify in debug log or output)
- [ ] Workflow terminates at `STATE_IMPLEMENT` (no test/debug phases attempted)
- [ ] Completion summary displays with correct 4-section format (Section 6.3)
- [ ] State file contains `WORKFLOW_SCOPE=implement-only` and `CURRENT_STATE=implement`

---

## Phase 4: Regression Testing [COMPLETE]

**Objective**: Ensure changes do not affect existing commands using `implement-only` workflow type

**Dependencies**: Phase 3

**Complexity**: Low - Verification of existing command behavior

### Tasks

- [ ] Test `/implement` command (uses `implement-only`)
  - Create minimal test plan with 1 implementation phase
  - Execute: `/implement <test-plan> --dry-run`
  - Verify state machine initialization succeeds
  - Verify workflow type accepted without errors

- [ ] Test `/debug` command (uses `debug-only`)
  - Create minimal issue description
  - Execute: `/debug "test issue" --dry-run`
  - Verify state machine initialization succeeds
  - Confirms other workflow types unaffected

- [ ] Verify state machine library unchanged
  - Run: `git status .claude/lib/workflow/workflow-state-machine.sh`
  - Expected: No modifications (file should be unmodified)
  - Confirms solution uses existing infrastructure without changes

### Validation

```bash
# Test implement command
/implement /tmp/minimal-plan.md --dry-run
# Expected: Dry-run preview, no errors

# Test debug command
/debug "test regression check" --dry-run
# Expected: Dry-run preview, no errors

# Verify state machine unchanged
git status .claude/lib/workflow/workflow-state-machine.sh
# Expected: nothing to commit, working tree clean
```

### Success Criteria

- [ ] `/implement` command executes without errors
- [ ] `/debug` command executes without errors
- [ ] `workflow-state-machine.sh` file unmodified (verified via git status)
- [ ] All existing workflow types continue to work (`research-only`, `full-implementation`, etc.)
- [ ] No breaking changes introduced to state machine infrastructure

---

## Phase 5: Documentation Update [COMPLETE]

**Objective**: Update command guide documentation to reflect workflow type change

**Dependencies**: Phase 4

**Complexity**: Low - Single documentation file update

### Tasks

- [ ] Update lean-implement command guide
  - File: `/home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md`
  - Locate workflow type reference (estimated line 24 from Section 8.1)
  - Change: `lean-implement-hybrid` → `implement-only`
  - Add explanation: "Uses `implement-only` workflow type (implements without testing)"

- [ ] Verify documentation consistency
  - Grep for remaining `lean-implement-hybrid` references across `.claude/` directory
  - Expected: No matches (all references updated)
  - Confirms documentation fully updated

- [ ] Update command README if exists
  - Check: `/home/benjamin/.config/.claude/commands/README.md`
  - Update workflow type reference if `/lean-implement` is documented
  - Maintain consistency with command-reference.md

### Validation

```bash
# Search for old workflow type references
grep -r "lean-implement-hybrid" /home/benjamin/.config/.claude/

# Expected: No matches (or only in archived/historical files)

# Verify new workflow type documented
grep -n "implement-only" /home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md

# Expected: Line reference showing updated workflow type
```

### Success Criteria

- [ ] Command guide updated to reference `implement-only` workflow type
- [ ] Explanation added for why `implement-only` is used
- [ ] No remaining references to `lean-implement-hybrid` in active documentation
- [ ] Command README updated if applicable
- [ ] Documentation follows markdown formatting standards (Section 6.3)

---

## Phase 6: Error Logging Verification [COMPLETE]

**Objective**: Verify error logging integration works correctly with new workflow type

**Dependencies**: Phase 5

**Complexity**: Low - Verification of existing error logging infrastructure

### Tasks

- [ ] Verify error log structure
  - Check: Error log file exists at `~/.claude/data/error-log.jsonl`
  - Confirm error-handling.sh sourcing in lean-implement.md (lines 115-117)
  - Verify `ensure_error_log_exists` called during initialization (line 155)

- [ ] Test error logging with intentional failure
  - Modify test plan to trigger validation error (e.g., missing file reference)
  - Execute `/lean-implement` with invalid plan
  - Verify error logged with correct `workflow_type: implement-only`
  - Verify error includes `command: /lean-implement` and `workflow_id`

- [ ] Query errors with `/errors` command
  - Execute: `/errors --command /lean-implement --limit 5`
  - Verify recent test error appears in output
  - Verify workflow type field shows `implement-only` (not `lean-implement-hybrid`)

### Validation

```bash
# Trigger intentional error
/lean-implement /nonexistent/plan.md
# Expected: Error logged to error-log.jsonl

# Query error log
/errors --command /lean-implement --limit 1 --summary
# Expected: Recent error displayed with workflow_type=implement-only

# Verify error structure
tail -1 ~/.claude/data/error-log.jsonl | jq .
# Expected: JSON with workflow_type field containing "implement-only"
```

### Success Criteria

- [ ] Error logging functions correctly with `implement-only` workflow type
- [ ] Logged errors contain correct `command` field (`/lean-implement`)
- [ ] Logged errors contain correct `workflow_type` field (`implement-only`)
- [ ] `/errors` command can query `/lean-implement` errors
- [ ] Error log JSON structure follows error-handling.sh schema (Section 6.1)
- [ ] No error logging regressions introduced

---

## Risk Assessment

### Low Risk

**Rationale**:
- Single constant replacement in one file (2 lines changed)
- Uses existing infrastructure (`implement-only` already validated in state machine)
- No state machine library modifications required
- No agent contract changes
- Phase classification and routing logic independent of workflow type

### Potential Issues

1. **Test Coverage**: Limited existing test suite for `/lean-implement` command
   - **Mitigation**: Phase 3 creates comprehensive integration test plan
   - **Mitigation**: Phase 4 validates no regressions in existing commands

2. **Documentation Lag**: Risk of missing documentation references
   - **Mitigation**: Phase 5 includes grep-based search for all references
   - **Mitigation**: Pre-commit hooks enforce documentation standards

3. **Edge Cases**: Possible edge cases in phase routing not covered by test plan
   - **Mitigation**: Use real-world mixed Lean/software plan for integration testing
   - **Mitigation**: Monitor debug logs during Phase 3 execution

### Rollback Plan

If issues arise during testing:

```bash
# Revert line 245
sed -i 's/WORKFLOW_TYPE="implement-only"/WORKFLOW_TYPE="lean-implement-hybrid"/' \
  /home/benjamin/.config/.claude/commands/lean-implement.md

# Revert line 24
sed -i 's/\*\*Workflow Type\*\*: implement-only/**Workflow Type**: lean-implement-hybrid/' \
  /home/benjamin/.config/.claude/commands/lean-implement.md

# Then implement Alternative Solution (add lean-implement-hybrid to state machine)
```

Alternative solution documented in research report Section 8 (requires 8+ line changes across 3 files).

---

## Dependencies

### External Dependencies
- `workflow-state-machine.sh` v2.0.0+ (already satisfied, no changes needed)
- `error-handling.sh` v1.0.0+ (already sourced in lean-implement.md)
- `state-persistence.sh` v1.6.0+ (already sourced in lean-implement.md)

### Internal Dependencies
- Phase 2 depends on Phase 1 (requires updated workflow type)
- Phase 3 depends on Phase 2 (requires validated state machine integration)
- Phase 4 depends on Phase 3 (requires successful integration test)
- Phase 5 depends on Phase 4 (documentation updates after validation)
- Phase 6 depends on Phase 5 (error logging verification after complete fix)

### Parallel Execution Opportunities
- Phase 1 and Phase 2 validation scripts can be prepared in parallel
- Phase 4 regression tests can run in parallel (implement + debug tests independent)
- Phase 5 documentation updates can start after Phase 3 (don't need to wait for Phase 4)

---

## Testing Strategy

### Unit Tests
```bash
# Test 1: State machine accepts implement-only
source .claude/lib/workflow/workflow-state-machine.sh
sm_init "test-plan.md" "/lean-implement" "implement-only" "1" "[]"
echo $?  # Expected: 0

# Test 2: Terminal state mapping
echo $TERMINAL_STATE  # Expected: implement
```

### Integration Tests
```bash
# Test 3: Full command execution with test plan
/lean-implement .claude/specs/049_lean_implement_workflow_fix/plans/test-hybrid-plan.md --dry-run
# Expected: Classification accepted, scope=implement-only, terminal=implement

# Test 4: Real execution (non-dry-run)
/lean-implement .claude/specs/049_lean_implement_workflow_fix/plans/test-hybrid-plan.md
# Expected: Complete execution with correct coordinator routing
```

### Regression Tests
```bash
# Test 5: Existing implement-only command unaffected
/implement <plan-file> --dry-run
# Expected: Normal operation

# Test 6: Other workflow types unaffected
/debug "test issue" --dry-run
# Expected: Normal operation
```

### Test Data Requirements
- Minimal hybrid plan with 1 Lean phase + 1 software phase (created in Phase 3)
- Minimal implementation-only plan for regression test (standard format)
- Invalid plan for error logging test (nonexistent file reference)

---

## Completion Checklist

- [ ] All 6 phases completed successfully
- [ ] State machine initialization succeeds with `implement-only`
- [ ] Phase routing logic verified (Lean → lean-coordinator, software → implementer-coordinator)
- [ ] Terminal state reached: `STATE_IMPLEMENT`
- [ ] No regressions in existing commands (`/implement`, `/debug`)
- [ ] Documentation updated (command guide, README)
- [ ] Error logging verified with correct workflow type
- [ ] No remaining references to `lean-implement-hybrid`
- [ ] Test plan executed successfully
- [ ] `workflow-state-machine.sh` remains unmodified (verified via git status)

---

## References

### Research Documentation
- [Workflow Type Integration Analysis](/home/benjamin/.config/.claude/specs/049_lean_implement_workflow_fix/reports/001-workflow-type-integration-analysis.md) - Complete error analysis and solution recommendation

### Code Standards
- [Command Authoring](/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md) - State machine initialization patterns
- [State-Based Orchestration](/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md) - State machine architecture
- [Error Handling Pattern](/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md) - Error logging requirements

### Related Files
- `/home/benjamin/.config/.claude/commands/lean-implement.md` (lines 24, 245) - Primary modification target
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` (lines 471-479, 530-556) - Workflow type validation and terminal state mapping
- `/home/benjamin/.config/.claude/commands/implement.md` (line 350) - Reference implementation using `implement-only`
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md` - Documentation update target

### Decision Rationale
Research report Section 7 provides comprehensive justification for using `implement-only` over adding `lean-implement-hybrid` to state machine. Key points:
- Semantic equivalence (both implement without testing)
- Infrastructure alignment (same terminal state)
- Minimal change (2 lines vs 8+ lines)
- Best practice compliance (use existing types when functionally equivalent)
- Maintenance reduction (no enum propagation required)
