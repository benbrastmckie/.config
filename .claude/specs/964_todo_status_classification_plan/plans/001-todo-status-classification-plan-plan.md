# /todo Command Status Classification Fix - Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Fix /todo command to properly classify plan statuses using hard barrier subagent delegation pattern
- **Scope**: Refactor /todo command Block 2 to use hard barrier pattern (2a/2b/2c), remove fallback logic, add state machine integration
- **Estimated Phases**: 6
- **Estimated Hours**: 12
- **Complexity**: Medium
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 78.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [/todo Command Status Classification Failure - Research Report](/home/benjamin/.config/.claude/specs/964_todo_status_classification_plan/reports/001-todo-status-classification-research.md)

## Overview

The /todo command currently fails to properly classify plan statuses because Block 2 uses pseudo-code Task invocation instead of the hard barrier subagent delegation pattern. This allows Claude to bypass the todo-analyzer agent and use fallback logic that directly processes plans, resulting in incorrect status classification (e.g., Plan 961 with Status: [COMPLETE] remaining in "In Progress" section).

This plan implements the hard barrier pattern by:
1. Refactoring Block 2 into 2a (Setup), 2b (Execute), 2c (Verify) structure
2. Removing fallback logic from Block 3 that bypasses agent delegation
3. Adding state machine integration with state transitions
4. Adding comprehensive error logging for all failure points
5. Updating documentation to include /todo in hard barrier compliance list

## Research Summary

Key findings from research report:

**Root Cause**: Block 2 uses pseudo-code Task invocation that can be bypassed (lines 207-252 in todo.md)

**Missing Elements**:
- Block 2a: Setup with state transitions, variable persistence, checkpoint reporting
- Block 2b: Execute with proper Task tool invocation (not pseudo-code guidance)
- Block 2c: Verify with fail-fast artifact checks and error logging

**Fallback Logic Problem**: Block 3 (lines 292-308) contains fallback that bypasses agent delegation when CLASSIFIED_PLANS is empty, violating hard barrier requirement that delegation cannot be bypassed

**State Machine Integration**: Missing state transitions to enforce progression through states

**Evidence**: Plan 961 has Status: [COMPLETE] and all phases marked [COMPLETE] but TODO.md shows it in "In Progress" section, indicating last /todo run bypassed proper agent invocation

## Success Criteria

- [ ] Block 2 split into 2a (Setup), 2b (Execute), 2c (Verify) sub-blocks
- [ ] Block 2a includes state transition, variable persistence, checkpoint
- [ ] Block 2b uses proper Task tool invocation (not pseudo-code)
- [ ] Block 2c includes fail-fast verification with error logging
- [ ] Fallback logic removed from Block 3 (lines 292-308 deleted)
- [ ] State machine integration added (sm_init, sm_transition calls)
- [ ] All error points use log_command_error with recovery instructions
- [ ] /todo added to hard-barrier-subagent-delegation.md compliance list
- [ ] Test with Plans 961 and 962 shows correct classification to Completed section
- [ ] All existing tests pass with refactored command structure

## Technical Design

### Architecture Changes

**Current Structure** (4 blocks):
```
Block 1: Setup and Discovery (BASH)
Block 2: Status Classification (PSEUDO-CODE TASK)
Block 3: Generate TODO.md (BASH with fallback)
Block 4: Write TODO.md File (BASH)
```

**New Structure** (6 blocks):
```
Block 1: Setup and Discovery (BASH)
Block 2a: Status Classification Setup (BASH)
  - State transition: INIT → CLASSIFY
  - Variable persistence
  - Checkpoint reporting
Block 2b: Status Classification Execution (TASK)
  - CRITICAL BARRIER label
  - Task tool invocation to todo-analyzer
  - No fallback possible
Block 2c: Status Classification Verification (BASH)
  - Fail-fast artifact checks
  - Error logging with recovery hints
  - Checkpoint reporting
Block 3: Generate TODO.md (BASH, no fallback)
Block 4: Write TODO.md File (BASH)
```

### State Machine States

```
INIT → DISCOVER → CLASSIFY → GENERATE → COMPLETE
```

**State Transitions**:
- After Block 1: `sm_init` with workflow metadata
- Before Block 2b: `sm_transition "CLASSIFY"`
- Before Block 3: `sm_transition "GENERATE"`
- Before Block 4: `sm_transition "COMPLETE"`

### Variable Persistence

**Block 2a persists**:
- `DISCOVERED_PROJECTS` - path to projects JSON
- `CLASSIFIED_RESULTS` - path to classified results JSON
- `SPECS_ROOT` - specs directory path
- `WORKFLOW_ID` - workflow identifier

**Block 2c restores**:
```bash
source ~/.claude/data/state/todo_*.state 2>/dev/null || true
```

### Task Invocation Pattern

**Block 2b Task invocation**:
```markdown
Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Classify plan status for TODO.md organization"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/todo-analyzer.md

    Input:
    - plans_file: ${DISCOVERED_PROJECTS}
    - specs_root: ${SPECS_ROOT}

    For each plan in plans_file:
    1. Read the plan file via Read tool
    2. Extract metadata (title, status, description, phases)
    3. Classify status using algorithm in todo-analyzer.md
    4. Write results to: ${CLASSIFIED_RESULTS}

    Return format:
    PLANS_CLASSIFIED: ${CLASSIFIED_RESULTS}
    [
      {
        "plan_path": "/path/to/plan.md",
        "topic_name": "NNN_topic_name",
        "title": "Plan Title",
        "status": "completed|in_progress|not_started",
        "phases_complete": N,
        "phases_total": M,
        "section": "Completed|In Progress|Not Started"
      }
    ]
}
```

### Verification Strategy

**Block 2c checks**:
1. Classified results file exists
2. File size > 10 bytes (not empty)
3. JSON is valid (jq empty check)
4. Plan count > 0

**Error Recovery**:
- Log error via log_command_error
- Output recovery instructions: "Re-run /todo command, check todo-analyzer logs"
- Exit with code 1 (fail-fast)

## Implementation Phases

### Phase 1: Refactor Block 2 into Hard Barrier Pattern [COMPLETE]
dependencies: []

**Objective**: Split Block 2 into 2a (Setup), 2b (Execute), 2c (Verify) sub-blocks following hard barrier pattern

**Complexity**: Medium

Tasks:
- [x] Create Block 2a: Status Classification Setup (file: .claude/commands/todo.md, after Block 1)
  - Source workflow-state-machine.sh, state-persistence.sh, error-handling.sh
  - Add sm_transition "CLASSIFY" with fail-fast error handling
  - Pre-calculate DISCOVERED_PROJECTS and CLASSIFIED_RESULTS paths
  - Persist variables via append_workflow_state
  - Add checkpoint: "[CHECKPOINT] Setup complete - ready for todo-analyzer invocation"
- [x] Create Block 2b: Status Classification Execution (file: .claude/commands/todo.md, after Block 2a)
  - Add CRITICAL BARRIER label with verification warning
  - Add Task tool invocation to todo-analyzer agent (proper format, not pseudo-code)
  - Include behavioral injection: "Read and follow ALL instructions in: .claude/agents/todo-analyzer.md"
  - Specify DISCOVERED_PROJECTS input and CLASSIFIED_RESULTS output
  - Include expected return format in Task prompt
- [x] Create Block 2c: Status Classification Verification (file: .claude/commands/todo.md, after Block 2b)
  - Re-source error-handling.sh and state-persistence.sh (subprocess isolation)
  - Restore persisted variables via source ~/.claude/data/state/todo_*.state
  - Verify CLASSIFIED_RESULTS file exists (fail-fast if missing)
  - Verify file size > 10 bytes (fail-fast if empty)
  - Verify JSON is valid via jq empty check (fail-fast if invalid)
  - Count classified plans and persist count
  - Add checkpoint: "[CHECKPOINT] Verification complete - N plans classified"
- [x] Delete original Block 2 pseudo-code section (lines 207-252)
- [x] Update block numbering for subsequent blocks (Block 3 → Block 3, Block 4 → Block 4)

Testing:
```bash
# Verify block structure exists
grep -q "## Block 2a: Status Classification Setup" .claude/commands/todo.md
grep -q "## Block 2b: Status Classification Execution" .claude/commands/todo.md
grep -q "## Block 2c: Status Classification Verification" .claude/commands/todo.md

# Verify CRITICAL BARRIER label present
grep -q "CRITICAL BARRIER.*todo-analyzer" .claude/commands/todo.md

# Verify state transitions present
grep -q 'sm_transition "CLASSIFY"' .claude/commands/todo.md
```

**Expected Duration**: 3 hours

---

### Phase 2: Remove Fallback Logic from Block 3 [COMPLETE]
dependencies: [1]

**Objective**: Remove fallback code that bypasses agent delegation, enforce fail-fast behavior

**Complexity**: Low

Tasks:
- [x] Delete fallback logic from Block 3 (file: .claude/commands/todo.md, lines 293-308)
  - Remove "WARNING: No classified plans found from todo-analyzer" section
  - Remove "Using fallback: direct metadata extraction" code
  - Remove direct plan processing via todo-functions.sh
- [x] Update Block 3 to expect CLASSIFIED_RESULTS from Block 2c
  - Source state file to restore CLASSIFIED_RESULTS path
  - Read classified plans JSON directly
  - Fail-fast if CLASSIFIED_RESULTS missing or invalid
- [x] Add error logging for missing classified results
  - Use log_command_error with type "verification_error"
  - Include recovery instructions: "Re-run /todo command"
  - Exit with code 1 (fail-fast)

Testing:
```bash
# Verify fallback logic removed
! grep -q "fallback.*direct metadata" .claude/commands/todo.md

# Verify no direct plan processing in Block 3
! grep -q "extract_plan_metadata" .claude/commands/todo.md

# Verify fail-fast on missing results
grep -q "log_command_error.*verification_error" .claude/commands/todo.md
```

**Expected Duration**: 1 hour

---

### Phase 3: Add State Machine Integration [COMPLETE]
dependencies: [1]

**Objective**: Integrate workflow state machine with state transitions for progression enforcement

**Complexity**: Medium

Tasks:
- [x] Add state machine initialization after Block 1 (file: .claude/commands/todo.md, end of Block 1)
  - Call sm_init with workflow description, command name, scope
  - Format: `sm_init "$DESCRIPTION" "/todo" "utility" "1" "[]"`
  - Set WORKFLOW_SCOPE="utility" for TODO.md update workflow
- [x] Add state transitions throughout command
  - After Block 1: Transition to DISCOVER state (already in discovery phase)
  - Before Block 2b: sm_transition "CLASSIFY" (already added in Phase 1)
  - Before Block 3: sm_transition "GENERATE"
  - Before Block 4: sm_transition "COMPLETE"
- [x] Add state validation after each transition
  - Check sm_transition return code
  - Log error via log_command_error on failure
  - Exit with code 1 on state transition failure
- [x] Source workflow-state-machine.sh in Block 1 (file: .claude/commands/todo.md, library sourcing section)
  - Add to Tier 2 sourcing (workflow libraries)
  - Include fail-fast handler: `|| { echo "ERROR: Cannot load workflow-state-machine.sh"; exit 1; }`

Testing:
```bash
# Verify state machine sourcing
grep -q 'source.*workflow-state-machine.sh' .claude/commands/todo.md

# Verify sm_init call
grep -q 'sm_init.*"/todo"' .claude/commands/todo.md

# Verify state transitions
grep -c 'sm_transition' .claude/commands/todo.md  # Should be ≥3
```

**Expected Duration**: 2 hours

---

### Phase 4: Add Comprehensive Error Logging [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Replace all generic error messages with log_command_error calls, add recovery instructions

**Complexity**: Low

Tasks:
- [x] Update all error points in Block 1 (file: .claude/commands/todo.md)
  - Project directory detection failure: log_command_error "validation_error"
  - Specs directory not found: log_command_error "file_error"
  - Add recovery instructions for each error
- [x] Update all error points in Block 2a/2b/2c
  - State transition failure: log_command_error "state_error"
  - Classified results missing: log_command_error "verification_error"
  - Invalid JSON: log_command_error "verification_error"
- [x] Update all error points in Block 3
  - Missing classified results: log_command_error "verification_error"
  - Backup creation failure: log_command_error "file_error"
- [x] Update all error points in Block 4
  - Write failure: log_command_error "file_error"
- [x] Add error context JSON to all log_command_error calls
  - Include relevant paths, counts, states
  - Enable queryable debugging via /errors command

Testing:
```bash
# Count log_command_error calls (should be ≥8)
grep -c 'log_command_error' .claude/commands/todo.md

# Verify recovery instructions present
grep -c 'Recovery:' .claude/commands/todo.md  # Should be ≥6

# Verify error types used
grep 'log_command_error' .claude/commands/todo.md | grep -E 'validation_error|file_error|verification_error|state_error'
```

**Expected Duration**: 2 hours

---

### Phase 5: Update Documentation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Update documentation to reflect /todo command's hard barrier compliance

**Complexity**: Low

Tasks:
- [x] Add /todo to hard barrier compliance list (file: .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
  - Add to "Commands Requiring Hard Barriers" section (line 493-502)
  - Format: `- /todo (todo-analyzer)`
  - Maintain alphabetical order
- [x] Update /todo command guide (file: .claude/docs/guides/commands/todo-command-guide.md)
  - Add "Hard Barrier Pattern" section documenting Block 2a/2b/2c structure
  - Explain why fallback logic was removed (architectural compliance)
  - Document state machine integration
  - Add troubleshooting section for verification failures
- [x] Update commands README (file: .claude/commands/README.md)
  - Add /todo to "Commands Using Hard Barriers" list
  - Link to hard-barrier-subagent-delegation.md pattern documentation

Testing:
```bash
# Verify /todo in compliance list
grep -q '/todo.*todo-analyzer' .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md

# Verify guide updated
grep -q 'Hard Barrier Pattern' .claude/docs/guides/commands/todo-command-guide.md

# Verify README updated
grep -q '/todo' .claude/commands/README.md
```

**Expected Duration**: 2 hours

---

### Phase 6: Testing and Validation [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Verify hard barrier pattern compliance and correct plan classification behavior

**Complexity**: Medium

Tasks:
- [x] Create hard barrier compliance test (file: .claude/tests/features/commands/test_todo_hard_barrier.sh)
  - Test 1: Verify Block 2b uses Task tool (not pseudo-code)
  - Test 2: Verify Block 2c exists (verification block)
  - Test 3: Verify no fallback logic in Block 3
  - Test 4: Verify state transitions present
  - Test 5: Verify CRITICAL BARRIER label exists
- [x] Test /todo command with completed plans (manual test)
  - Run: `/todo` command
  - Verify: Plans 961 and 962 (both Status: [COMPLETE]) appear in Completed section
  - Verify: No plans with Status: [COMPLETE] in In Progress section
  - Verify: TODO.md structure follows standards (sections, checkboxes, date grouping)
- [x] Test /todo command with mixed statuses (manual test)
  - Ensure plans with Status: [IN PROGRESS] appear in In Progress section
  - Ensure plans with Status: [NOT STARTED] appear in Not Started section
  - Verify: Backlog section preserved and manually curated entries retained
- [x] Run hard barrier compliance validator
  - Execute: `bash .claude/scripts/validate-hard-barrier-compliance.sh --command todo`
  - Verify: All compliance checks pass
  - Fix: Any reported violations
- [x] Run existing test suite
  - Execute: `bash .claude/tests/features/commands/test_*.sh`
  - Verify: No regressions in other commands
  - Fix: Any test failures

Testing:
```bash
# Run compliance validator
bash .claude/scripts/validate-hard-barrier-compliance.sh --command todo

# Run new test
bash .claude/tests/features/commands/test_todo_hard_barrier.sh

# Manual verification
/todo
grep -A5 "## Completed" .claude/TODO.md | grep "961_repair_spec_numbering"
```

**Expected Duration**: 2 hours

---

## Testing Strategy

### Unit Testing
- Hard barrier compliance test validates Block 2a/2b/2c structure
- State transition tests verify sm_init and sm_transition calls
- Error logging tests verify log_command_error integration
- Verification tests check fail-fast behavior on missing artifacts

### Integration Testing
- End-to-end /todo command execution with 100+ existing plans
- Verify Plans 961 and 962 correctly classified to Completed section
- Verify all status types correctly categorized (completed, in_progress, not_started, superseded, abandoned)
- Test --dry-run flag preserves hard barrier pattern

### Manual Validation
- Run /todo on current project state
- Review TODO.md output for correctness
- Verify no fallback logic used (via checkpoint markers)
- Verify todo-analyzer agent invoked (via agent completion signal)

### Regression Testing
- Run full test suite: `bash .claude/tests/features/commands/test_*.sh`
- Verify no impact on other commands using hard barriers
- Verify error logging integration works across all error types

## Documentation Requirements

### Updated Files
1. **hard-barrier-subagent-delegation.md**: Add /todo to compliance list
2. **todo-command-guide.md**: Document Block 2a/2b/2c structure and rationale
3. **commands/README.md**: List /todo in hard barrier commands section

### New Documentation
- Troubleshooting section in todo-command-guide.md for verification failures
- Architectural decision record (ADR) explaining fallback removal rationale

### Code Comments
- Block 2a: Comment explaining state transition purpose
- Block 2b: Comment explaining CRITICAL BARRIER enforcement
- Block 2c: Comment explaining fail-fast verification requirements

## Dependencies

### External Dependencies
- workflow-state-machine.sh library (state transitions)
- state-persistence.sh library (variable persistence)
- error-handling.sh library (error logging)
- todo-analyzer.md agent (status classification)
- todo-functions.sh library (metadata extraction utilities - used by agent only)

### Internal Dependencies
- Block 2b depends on Block 2a completing (variable persistence)
- Block 2c depends on Block 2b completing (artifact verification)
- Block 3 depends on Block 2c completing (classified results JSON)

### Phase Dependencies
- Phase 2 depends on Phase 1 (Block 3 needs refactored Block 2 structure)
- Phase 4 depends on Phases 1, 2, 3 (error logging needs all blocks finalized)
- Phase 5 depends on Phases 1-4 (documentation reflects final implementation)
- Phase 6 depends on Phases 1-5 (testing validates complete implementation)

## Risk Management

### Technical Risks

**Risk**: State persistence failure between blocks
- **Mitigation**: Add verification of state file existence in Block 2c
- **Fallback**: Log detailed error with state file path for debugging
- **Testing**: Unit test for append_workflow_state and source restoration

**Risk**: todo-analyzer agent timeout or failure
- **Mitigation**: Block 2c fail-fast with recovery instructions
- **Fallback**: Error log queryable via /errors command for analysis
- **Testing**: Manual test with intentional agent failure

**Risk**: Breaking existing /todo --clean functionality
- **Mitigation**: Keep clean mode logic separate (after Block 4)
- **Fallback**: Add integration test for --clean flag
- **Testing**: Test both default mode and --clean mode

### Process Risks

**Risk**: Incomplete fallback removal leaves bypass possible
- **Mitigation**: Grep verification test ensures no "fallback" strings remain
- **Testing**: Compliance validator checks for bypass patterns

**Risk**: Documentation inconsistency with implementation
- **Mitigation**: Phase 5 reviews all documentation against final code
- **Testing**: Manual review of guide examples against command blocks

## Rollback Strategy

If implementation causes issues:

1. **Rollback commits**: Git revert to previous working state
2. **Restore TODO.md backup**: Copy from TODO.md.backup if corrupted
3. **Re-run /todo with original code**: Generate fresh TODO.md
4. **Review error logs**: Use /errors command to analyze failures
5. **Create new plan**: Use /repair to address root cause

## Expected Outcomes

After implementing hard barrier pattern:

1. **100% Agent Delegation**: All status classification goes through todo-analyzer agent
2. **Consistent Classification**: Plans with Status: [COMPLETE] always move to Completed section
3. **Fail-Fast Behavior**: Missing agent outputs cause immediate failure with recovery instructions
4. **Observable Execution**: Checkpoint markers trace execution flow for debugging
5. **Error Tracking**: All failures logged to centralized error log for /errors and /repair queries
6. **Architectural Compliance**: /todo command follows same hard barrier pattern as /repair, /errors, /build
7. **Performance**: No regression in execution time (agent invocation already expected)
8. **Maintainability**: Clear block structure easier to understand and modify

## Completion Validation

Before marking plan as complete:

- [ ] All 6 phases completed with checkboxes marked
- [ ] Plans 961 and 962 correctly appear in Completed section of TODO.md
- [ ] Hard barrier compliance validator passes for /todo command
- [ ] All existing tests pass
- [ ] New hard barrier compliance test passes
- [ ] Documentation updated and reviewed
- [ ] No fallback logic remains in todo.md
- [ ] State machine integration verified via checkpoint markers
- [ ] Error logging integration verified via /errors query

## References

### Implementation Templates
- hard-barrier-subagent-delegation.md: Template 1 (Research Phase Delegation) and Template 2 (Plan Revision Delegation)
- workflow-state-machine.sh: State transition API and state enumeration
- error-handling.sh: log_command_error API and error types

### Compliant Examples
- /repair command (repair.md): Research-and-plan with hard barriers
- /errors command (errors.md): Dual-mode with hard barriers and error-analyst delegation
- /revise command (revise.md): Plan revision with hard barriers

### Documentation
- Hard Barrier Subagent Delegation Pattern: /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md
- Error Handling Pattern: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
- State-Based Orchestration: /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
- TODO Organization Standards: /home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md
