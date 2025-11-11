# Fix /coordinate Workflow Scope Persistence Bug

## Metadata
- **Date**: 2025-11-10
- **Feature**: Fix WORKFLOW_SCOPE variable persistence across bash subprocess boundaries
- **Scope**: .claude/lib/workflow-state-machine.sh, .claude/commands/coordinate.md
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Bug Report**: /home/benjamin/.config/.claude/specs/coordinage_implement.md

## Overview

The `/coordinate` command incorrectly proceeds to implementation phase for `research-and-plan` scoped workflows instead of stopping after the planning phase. This occurs because the `WORKFLOW_SCOPE` variable is reset to empty string when `workflow-state-machine.sh` is re-sourced in subsequent bash blocks, despite being correctly saved to the workflow state file.

### Root Cause Analysis

1. **Bash Block Subprocess Isolation**: Each bash block in coordinate.md executes in a new subprocess, losing all environment variables and source guards
2. **Variable Initialization Timing**: `workflow-state-machine.sh` initializes `WORKFLOW_SCOPE=""` at line 75 when sourced
3. **Load Order Issue**: Libraries are re-sourced BEFORE `load_workflow_state()` is called, causing the initialization to overwrite the intended value
4. **State File Correctness**: The workflow state file DOES contain the correct `WORKFLOW_SCOPE` value, but it gets overwritten after being loaded

### Impact

- **Severity**: High - Causes workflows to execute unintended phases
- **Scope**: All `/coordinate` invocations with `research-and-plan` or `research-only` scopes
- **Observed Behavior**: Plan creation succeeds, then /implement is incorrectly invoked
- **Expected Behavior**: Workflow should exit after planning phase with completion message

## Success Criteria

- [ ] `research-and-plan` workflows stop after planning phase
- [ ] `research-only` workflows stop after research phase
- [ ] `full-implementation` workflows continue through all phases (no regression)
- [ ] WORKFLOW_SCOPE variable persists correctly across all bash blocks
- [ ] State persistence tests pass (100% coverage)
- [ ] No changes to public API or command invocation syntax

## Technical Design

### Solution Architecture

**Option 1: Conditional Variable Initialization (Recommended)**
- Modify `workflow-state-machine.sh` to use conditional initialization: `WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"`
- This preserves any existing value while allowing initialization to empty string if unset
- Minimal change, preserves all existing behavior
- Aligns with bash-block-execution-model.md save-before-source pattern

**Option 2: Move load_workflow_state Before Library Sourcing**
- Reorder coordinate.md bash blocks to load state BEFORE re-sourcing libraries
- Requires sourcing state-persistence.sh first, then loading state, then other libraries
- More invasive changes to coordinate.md structure
- Risk of circular dependency issues

**Option 3: Remove Variable Initialization from Library**
- Only initialize variables in `sm_init()` function
- Requires auditing all call sites to ensure variables are initialized
- Higher risk of breaking existing workflows

**Selected Solution: Option 1 (Conditional Initialization)**

### Implementation Strategy

1. **Phase 1**: Add conditional initialization pattern to workflow-state-machine.sh
2. **Phase 2**: Add test coverage for state persistence across subprocess boundaries
3. **Phase 3**: Validate fix with actual /coordinate invocation
4. **Phase 4**: Document the bash subprocess isolation pattern for future reference

### Key Files Modified

- `.claude/lib/workflow-state-machine.sh` - Variable initialization (lines 75-77)
- `.claude/tests/test_state_machine_persistence.sh` - New test file
- `.claude/docs/concepts/bash-block-execution-model.md` - Documentation update

### Testing Strategy

1. **Unit Tests**: State persistence across mock subprocess boundaries
2. **Integration Tests**: Full /coordinate invocation with research-and-plan scope
3. **Regression Tests**: Ensure full-implementation workflows still work correctly

## Implementation Phases

### Phase 0: Preparation and Validation
dependencies: []

**Objective**: Verify the bug exists and understand current behavior

**Complexity**: Low

**Tasks**:
- [ ] Create test case reproducing the bug (.claude/tests/test_coordinate_scope_bug.sh)
- [ ] Verify WORKFLOW_SCOPE is correctly written to state file
- [ ] Verify WORKFLOW_SCOPE is incorrectly empty after library re-sourcing
- [ ] Document the exact sequence of events causing the bug
- [ ] Review bash-block-execution-model.md for subprocess isolation patterns

**Testing**:
```bash
# Manual reproduction
cd /home/benjamin/.config
/coordinate "research and design a simple feature"
# Expected: Should stop after planning
# Actual: Proceeds to implementation

# Verify state file contents
cat ~/.claude/tmp/workflow_coordinate_*.sh | grep WORKFLOW_SCOPE
# Should show: export WORKFLOW_SCOPE="research-and-plan"
```

**Success Criteria**:
- [ ] Bug reproduction test exists and fails as expected
- [ ] State file contents verified to be correct
- [ ] Documentation of bug mechanics complete

---

### Phase 1: Fix Variable Initialization
dependencies: [0]

**Objective**: Implement conditional initialization pattern in workflow-state-machine.sh

**Complexity**: Low

**Tasks**:
- [ ] Update WORKFLOW_SCOPE initialization to conditional pattern (line 75)
- [ ] Update WORKFLOW_DESCRIPTION initialization to conditional pattern (line 76)
- [ ] Update COMMAND_NAME initialization to conditional pattern (line 77)
- [ ] Update CURRENT_STATE to preserve existing value if already set (line 66)
- [ ] Update TERMINAL_STATE to preserve existing value if already set (line 72)
- [ ] Add comments explaining the subprocess isolation requirement
- [ ] Review all other variable initializations in the file

**File Changes**:
```bash
# Before (line 75):
WORKFLOW_SCOPE=""

# After (line 75):
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"  # Preserve value across subprocess boundaries
```

**Testing**:
```bash
# Test conditional initialization
WORKFLOW_SCOPE="test-value"
source .claude/lib/workflow-state-machine.sh
echo "$WORKFLOW_SCOPE"  # Should output: test-value (not empty)
```

**Success Criteria**:
- [ ] All 5 state machine variables use conditional initialization
- [ ] Source guard still prevents function re-definition
- [ ] No regressions in sm_init() behavior

---

### Phase 2: Add Comprehensive Test Coverage
dependencies: [1]

**Objective**: Create tests validating state persistence across subprocess boundaries

**Complexity**: Medium

**Tasks**:
- [ ] Create .claude/tests/test_state_machine_persistence.sh
- [ ] Test 1: WORKFLOW_SCOPE persists across subprocess boundary
- [ ] Test 2: WORKFLOW_DESCRIPTION persists across subprocess boundary
- [ ] Test 3: CURRENT_STATE persists across subprocess boundary
- [ ] Test 4: TERMINAL_STATE persists across subprocess boundary
- [ ] Test 5: research-and-plan scope detection and terminal state
- [ ] Test 6: research-only scope detection and terminal state
- [ ] Test 7: full-implementation scope detection and terminal state
- [ ] Test 8: State persistence with load_workflow_state()
- [ ] Add tests to .claude/tests/run_all_tests.sh

**File Structure**:
```bash
# .claude/tests/test_state_machine_persistence.sh
#!/bin/bash
# Test state machine variable persistence across subprocess boundaries

test_workflow_scope_persistence() {
  # Setup: Create state file with WORKFLOW_SCOPE
  # Execute: Source library in subprocess
  # Verify: WORKFLOW_SCOPE unchanged
}

test_research_and_plan_terminal_state() {
  # Setup: Initialize with research-and-plan scope
  # Execute: Verify TERMINAL_STATE = STATE_PLAN
  # Verify: Workflow stops after planning
}
```

**Testing**:
```bash
cd /home/benjamin/.config
bash .claude/tests/test_state_machine_persistence.sh
# Expected: All 8 tests pass
```

**Success Criteria**:
- [ ] All 8 persistence tests pass
- [ ] Tests execute in <2 seconds
- [ ] Tests included in run_all_tests.sh

---

### Phase 3: Integration Testing and Validation
dependencies: [1, 2]

**Objective**: Validate fix with real /coordinate invocations

**Complexity**: Medium

**Tasks**:
- [ ] Test research-only workflow (should stop after research)
- [ ] Test research-and-plan workflow (should stop after planning)
- [ ] Test full-implementation workflow (should complete all phases)
- [ ] Test debug-only workflow (should stop at debug)
- [ ] Verify workflow state files contain correct WORKFLOW_SCOPE
- [ ] Verify terminal state detection works correctly
- [ ] Verify no regressions in parallel research execution
- [ ] Test with workflow descriptions containing edge cases

**Test Cases**:
```bash
# Test 1: Research-only
/coordinate "research authentication patterns in the codebase"
# Expected: Stops after research, outputs completion message

# Test 2: Research-and-plan (the bug case)
/coordinate "research and design an archival system"
# Expected: Stops after planning, outputs plan path

# Test 3: Full-implementation
/coordinate "implement a simple utility function"
# Expected: Completes research → plan → implement → test → document

# Test 4: Debug-only
/coordinate "fix the login bug"
# Expected: Completes research → plan → debug
```

**Verification**:
```bash
# Check workflow scope was preserved
cat ~/.claude/tmp/workflow_coordinate_*.sh | grep WORKFLOW_SCOPE
# Should show correct scope for each test case

# Check terminal state was correct
cat ~/.claude/tmp/workflow_coordinate_*.sh | grep TERMINAL_STATE
# research-only: STATE_RESEARCH
# research-and-plan: STATE_PLAN
# full-implementation: STATE_COMPLETE
# debug-only: STATE_DEBUG
```

**Success Criteria**:
- [ ] All 4 workflow scopes behave correctly
- [ ] No unintended phase transitions occur
- [ ] Workflow completion messages are appropriate
- [ ] State files show correct variable values

---

### Phase 4: Documentation and Cleanup
dependencies: [3]

**Objective**: Document the fix and update architectural documentation

**Complexity**: Low

**Tasks**:
- [ ] Update .claude/docs/concepts/bash-block-execution-model.md
- [ ] Add "Conditional Variable Initialization" pattern section
- [ ] Document when to use `VAR="${VAR:-}"` vs `VAR=""`
- [ ] Add this bug fix as a case study example
- [ ] Update workflow-state-machine.sh header comments
- [ ] Update coordinate-command-guide.md troubleshooting section
- [ ] Add entry to CHANGELOG or release notes
- [ ] Remove temporary debugging code if any

**Documentation Additions**:

**bash-block-execution-model.md**:
```markdown
## Pattern 7: Conditional Variable Initialization

**Problem**: Library variables initialized at file scope get reset when library is re-sourced in new subprocess.

**Solution**: Use conditional initialization to preserve existing values:
```bash
# Preserve value across subprocess boundaries
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
```

**Use Cases**:
- State machine variables that persist across bash blocks
- Configuration values loaded from state files
- Any variable that should survive library re-sourcing

**Case Study**: /coordinate WORKFLOW_SCOPE bug (Spec 653)
```

**Success Criteria**:
- [ ] bash-block-execution-model.md updated with new pattern
- [ ] coordinate-command-guide.md troubleshooting section updated
- [ ] Code comments explain the conditional initialization
- [ ] All temporary test files cleaned up

---

## Testing Strategy

### Unit Tests
- **Location**: `.claude/tests/test_state_machine_persistence.sh`
- **Coverage**: Variable persistence, scope detection, terminal state mapping
- **Execution Time**: <2 seconds
- **Pass Criteria**: 8/8 tests pass

### Integration Tests
- **Location**: Manual /coordinate invocations
- **Coverage**: All 4 workflow scopes (research-only, research-and-plan, full-implementation, debug-only)
- **Execution Time**: ~5 minutes for all 4 tests
- **Pass Criteria**: Each scope stops at correct terminal state

### Regression Tests
- **Location**: Existing `.claude/tests/test_state_management.sh`
- **Coverage**: Ensure no breakage of existing state machine functionality
- **Execution Time**: <5 seconds
- **Pass Criteria**: All existing tests still pass

## Risk Assessment

### Low Risk
- Variable initialization change is minimal and well-understood
- Conditional initialization is idiomatic bash pattern
- Source guard prevents function re-definition issues
- No public API changes

### Medium Risk
- Potential edge cases with nested subshell invocations
- Interaction with other state persistence mechanisms
- Timing issues if variables set after library sourcing

### Mitigation
- Comprehensive test coverage for all workflow scopes
- Manual testing with real /coordinate invocations
- Phased rollout with validation at each step
- Easy rollback (single line change)

## Dependencies

### Internal
- `.claude/lib/state-persistence.sh` - State file operations
- `.claude/lib/workflow-scope-detection.sh` - Scope detection logic
- `.claude/commands/coordinate.md` - Command invocation and bash blocks

### External
- None (pure bash implementation)

## Rollback Plan

If issues are discovered after deployment:

1. **Immediate Rollback**: Revert conditional initialization changes
   ```bash
   git revert <commit-sha>
   ```

2. **State File Cleanup**: Remove any corrupted state files
   ```bash
   rm ~/.claude/tmp/workflow_coordinate_*.sh
   ```

3. **Re-test**: Verify rollback resolves any issues
   ```bash
   bash .claude/tests/run_all_tests.sh
   ```

## Notes

### Alternative Solutions Considered

1. **Explicit State Reload After Library Sourcing**
   - Pros: Clear separation of concerns
   - Cons: Duplicate code in every bash block, performance overhead

2. **Single Library Sourcing with Function Re-export**
   - Pros: Avoid re-sourcing entirely
   - Cons: Conflicts with bash subprocess isolation model

3. **Environment Variable Persistence**
   - Pros: Simpler than file-based state
   - Cons: Doesn't work across subprocesses (Bash tool limitation)

### Future Improvements

1. **Automated Scope Detection Validation**: Add tests that parse workflow descriptions and verify correct scope detection
2. **State Debugging Tool**: Create utility to inspect workflow state files and diagnose persistence issues
3. **Performance Monitoring**: Track state file read/write overhead across large workflows

## References

- **bash-block-execution-model.md**: Subprocess isolation patterns and save-before-source pattern
- **coordinate-command-guide.md**: Full /coordinate architecture and usage
- **state-based-orchestration-overview.md**: State machine architecture
- **Bug Report**: /home/benjamin/.config/.claude/specs/coordinage_implement.md (console output showing the bug)
