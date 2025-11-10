# Manual Testing Procedure for Coordinate Command Fixes

## Purpose

This document provides manual testing procedures to verify the fixes for Spec 641 typo and Bash tool preprocessing issues.

**Why Manual Testing**: The coordinate command is designed to be invoked through Claude Code's slash command system, not as a standalone script. Automated integration tests would require mocking the entire Claude Code invocation environment, which is complex and brittle.

## Prerequisites

- Coordinate command fixes applied (Phase 1 and Phase 2 complete)
- Claude Code CLI available
- Project at /home/benjamin/.config

## Test 1: Simple 2-Topic Workflow

**Objective**: Verify no bad substitution errors and REPORT_PATH variables serialize correctly

**Steps**:
1. Invoke coordinate with a simple workflow:
   ```
   /coordinate "research and plan improvements to testing documentation"
   ```

2. Monitor output for errors:
   - ✓ No "bad substitution" errors
   - ✓ No "${\!var_name}" syntax in error messages
   - ✓ Verification checkpoint passes

3. Check state file after initialization:
   ```bash
   cat ~/.claude/tmp/workflow_coordinate_*.sh | grep REPORT_PATH
   ```

   Expected output:
   ```
   REPORT_PATH_0="/path/to/report0.md"
   REPORT_PATH_1="/path/to/report1.md"
   ```

4. Verify workflow completes:
   - ✓ Research phase completes
   - ✓ Planning phase completes
   - ✓ Completion summary displays

**Success Criteria**:
- No errors during execution
- REPORT_PATH variables present in state file
- Workflow completes to terminal state

## Test 2: Complex 4-Topic Workflow (Hierarchical)

**Objective**: Verify hierarchical research supervision works correctly

**Steps**:
1. Invoke coordinate with complex workflow:
   ```
   /coordinate "research comprehensive system architecture with multiple components"
   ```

2. Verify hierarchical supervision triggered:
   - ✓ "Using hierarchical research supervision (≥4 topics)" message
   - ✓ No bad substitution errors
   - ✓ All 4+ REPORT_PATH variables in state file

3. Check state file:
   ```bash
   cat ~/.claude/tmp/workflow_coordinate_*.sh | grep -c REPORT_PATH
   ```

   Expected: 4 or more matches

**Success Criteria**:
- Hierarchical supervision message appears
- All REPORT_PATH variables serialized
- No errors during execution

## Test 3: CLAUDE_PROJECT_DIR Detection

**Objective**: Verify project root detection works correctly (typo fix)

**Steps**:
1. Start coordinate workflow from subdirectory:
   ```bash
   cd ~/.config/.claude/tests
   # Then invoke /coordinate from Claude Code
   ```

2. Check state file for correct CLAUDE_PROJECT_DIR:
   ```bash
   cat ~/.claude/tmp/workflow_coordinate_*.sh | grep CLAUDE_PROJECT_DIR
   ```

   Expected:
   ```
   export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
   ```

   Should NOT be:
   ```
   export CLAUDE_PROJECT_DIR="/home/benjamin/.config/.claude/tests"
   ```

**Success Criteria**:
- CLAUDE_PROJECT_DIR set to project root, not current directory
- Libraries sourced correctly (no "file not found" errors)

## Test 4: Verification Checkpoint

**Objective**: Verify the verification checkpoint catches issues

**Steps**:
1. Run normal coordinate workflow (Test 1)

2. Observe verification checkpoint output:
   ```
   MANDATORY VERIFICATION: State File Persistence
   Checking 2 REPORT_PATH variables...

     ✓ REPORT_PATHS_COUNT variable saved
     ✓ REPORT_PATH_0 saved
     ✓ REPORT_PATH_1 saved

   State file verification:
     - Path: /home/benjamin/.claude/tmp/workflow_coordinate_*.sh
     - Size: [size] bytes
     - Variables expected: 3
     - Verification failures: 0

   ✓ All 3 variables verified in state file
   ```

**Success Criteria**:
- All verification checks pass (✓)
- 0 verification failures
- Checkpoint completes without errors

## Test 5: Regression Verification

**Objective**: Ensure fixes don't break existing functionality

**Steps**:
1. Run existing test suite:
   ```bash
   cd ~/.config/.claude/tests
   ./run_all_tests.sh
   ```

2. Verify all tests pass:
   - ✓ test_array_serialization.sh passes
   - ✓ test_history_expansion.sh passes
   - ✓ test_cross_block_function_availability.sh passes
   - ✓ No regressions in other tests

**Success Criteria**:
- All existing tests pass
- No new test failures introduced

## Common Issues and Troubleshooting

### Issue: Bad Substitution Error Still Occurs

**Symptoms**: Error message contains `${\!var_name}`

**Possible Causes**:
1. Phase 2 fix not applied correctly
2. Different location using indirect expansion

**Resolution**:
1. Verify Phase 2 commit applied: `git log --oneline | grep "work around Bash tool preprocessing"`
2. Search for remaining `${!var_name}` usage: `grep -n '${!var' .claude/commands/coordinate.md`
3. Replace with eval approach if found

### Issue: CLAUDE_PROJECT_DIR Wrong

**Symptoms**: "file not found" errors when sourcing libraries

**Possible Causes**:
1. Phase 1 typo fix not applied
2. Running from directory without .git

**Resolution**:
1. Verify Phase 1 commit applied: `git log --oneline | grep "correct CLAUDE_PROJECT_DIR typo"`
2. Check for remaining typos: `grep '2)/dev/null' .claude/commands/coordinate.md` (should return 0 matches)
3. Ensure running from git repository

### Issue: Verification Checkpoint Fails

**Symptoms**: "❌ CRITICAL: State file verification failed"

**Possible Causes**:
1. State file not writable
2. Disk space issues
3. Different bug in serialization

**Resolution**:
1. Check state file exists and is writable: `ls -la ~/.claude/tmp/workflow_coordinate_*.sh`
2. Check disk space: `df -h /tmp`
3. Review state file contents manually
4. Check error-handling.sh for handle_state_error function

## Test Results Template

Use this template to document test results:

```markdown
## Test Execution Results

**Date**: [YYYY-MM-DD]
**Tester**: [Name]
**Commit**: [git commit hash]

### Test 1: Simple 2-Topic Workflow
- [ ] No bad substitution errors
- [ ] REPORT_PATH variables in state file
- [ ] Workflow completed successfully
- [ ] Completion summary displayed

### Test 2: Complex 4-Topic Workflow
- [ ] Hierarchical supervision triggered
- [ ] 4+ REPORT_PATH variables serialized
- [ ] No errors during execution

### Test 3: CLAUDE_PROJECT_DIR Detection
- [ ] Project root detected correctly
- [ ] Libraries sourced successfully

### Test 4: Verification Checkpoint
- [ ] All checks passed
- [ ] 0 verification failures

### Test 5: Regression Verification
- [ ] All existing tests pass
- [ ] No new failures introduced

### Overall Result
- [ ] All tests passed
- [ ] Fixes working as expected
- [ ] Ready for production use
```

## Automated Testing Limitations

**Why We Don't Have Automated Integration Tests**:

1. **Invocation Environment**: Coordinate expects to be invoked via Claude Code's slash command system with specific tool allowances and context
2. **Bash Tool Dependency**: The preprocessing issue only occurs when running through Claude Code's Bash tool, not when running bash scripts directly
3. **State Management**: Coordinate uses GitHub Actions-style state files that depend on specific environment setup
4. **Agent Interaction**: Coordinate invokes Task tool to launch subagents, which requires Claude Code runtime

**Future Improvement Opportunities**:
- Create mock Claude Code environment for integration testing
- Develop standalone test harness that simulates slash command invocation
- Add instrumentation to coordinate for test mode
- Consider refactoring to make coordinate testable as standalone script

## References

- **Spec 641**: Original implementation (5 phases)
- **Spec 641 Phase 1 Regression**: Typo fix
- **Spec 641 Phase 2 Regression**: Bash tool preprocessing workaround
- **Research Report**: 003_typo_and_residual_errors_analysis.md
- **Implementation Plan**: 002_fix_typo_and_preprocessing_issues.md

---

**Document Created**: 2025-11-10
**Last Updated**: 2025-11-10
**Status**: Active testing procedure
