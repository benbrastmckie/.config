# Comprehensive Analysis: 13 Failing Test Suites

**Research Date**: 2025-11-27
**Current Pass Rate**: 88.5% (100/113 suites)
**Target Pass Rate**: 100% (113/113 suites)
**Gap**: 13 failing test suites

## Executive Summary

This report provides detailed analysis of the 13 failing test suites blocking achievement of 100% test pass rate. Tests fall into three primary categories:

1. **Incomplete Test Implementations** (5 tests): Tests with setup but no assertions
2. **Test Infrastructure Issues** (6 tests): Wrong paths, missing dependencies, sourcing errors
3. **Actual Code Bugs** (2 tests): Real functionality issues requiring fixes

**Priority Assessment**:
- **Critical (fix immediately)**: 6 tests (infrastructure + actual bugs)
- **High (fix within sprint)**: 5 tests (incomplete implementations)
- **Medium (technical debt)**: 2 tests (compliance/validation tests)

---

## Category 1: Incomplete Test Implementations (5 Tests)

### Test 1: test_revise_error_recovery

**File**: `/home/benjamin/.config/.claude/tests/commands/test_revise_error_recovery.sh`

**Current Status**: FAILED (setup only, no actual execution)

**Analysis**:
- **Purpose**: Tests `/revise` command error recovery and verification blocks (Block 4c fail-fast, error logging, recovery instructions)
- **Implementation**: Test creates mock scenarios and verifies error message formats, but doesn't execute actual `/revise` command
- **Issue**: All 13 tests are simulation-only (no real command execution or agent invocation)
- **Lines**: 213 lines of mock tests checking string patterns

**Root Cause**: Test was designed as unit test for error handling patterns, not integration test. It verifies:
- Error message format (lines 69-80)
- Recovery message format (lines 104-119)
- Checkpoint reporting format (lines 193-209)

**Fix Approach**:
1. **Option A (Quick)**: Mark as unit test, move to `/tests/unit/commands/`
2. **Option B (Comprehensive)**: Add integration tests that actually invoke `/revise` with mock research-specialist failures

**Effort**: Low (1-2 hours)
**Impact**: Low (validates error handling patterns, not actual functionality)
**Priority**: Medium

---

### Test 2: test_revise_long_prompt

**File**: `/home/benjamin/.config/.claude/tests/commands/test_revise_long_prompt.sh`

**Current Status**: FAILED (setup only, no assertions)

**Analysis**:
- **Purpose**: Tests `/revise` --file flag with long revision prompt files
- **Implementation**: Creates 83-line prompt file, validates structure, but doesn't execute `/revise`
- **Issue**: Tests only validate mock prompt file creation (lines 44-185), no actual command execution

**Root Cause**: Test validates input preparation, not command behavior. All 6 tests check:
- Prompt file existence (line 85)
- Prompt content parsing (lines 95-135)
- --file flag parsing (lines 158-184)

**Fix Approach**:
1. Add actual `/revise --file` execution with mock plan
2. Verify plan revision occurs correctly
3. Test large prompt handling (>1000 lines)

**Effort**: Medium (3-4 hours)
**Impact**: Medium (validates important --file flag functionality)
**Priority**: High

---

### Test 3: test_revise_preserve_completed

**File**: `/home/benjamin/.config/.claude/tests/commands/test_revise_preserve_completed.sh`

**Current Status**: FAILED (manual simulation, no command execution)

**Analysis**:
- **Purpose**: Verify `/revise` preserves `[COMPLETE]` markers on already-finished phases
- **Implementation**: Manually simulates plan revision by writing new plan content (lines 62-90)
- **Issue**: Doesn't invoke plan-architect agent or `/revise` command

**Root Cause**: Test manually writes revised plan instead of letting plan-architect do it. Critical test for data integrity, but not testing actual code path.

**Current Test Flow**:
```bash
# Line 30: Create plan with [COMPLETE] markers
cat > "$TEST_PLAN" <<'EOF'
### Phase 1: Setup [COMPLETE]
- [x] Task 1 done
### Phase 3: Testing
- [ ] Task 1 pending
EOF

# Line 62: Manually write "revised" plan (simulating plan-architect)
cat > "$TEST_PLAN" <<'EOF'
### Phase 1: Setup [COMPLETE]  # Still there
- [x] Task 1 done
### Phase 3.5: Error Handling  # New phase
EOF

# Lines 92-138: Verify [COMPLETE] preserved
```

**Fix Approach**:
1. Create actual revision scenario with plan-architect
2. Provide revision instructions via mock workflow context
3. Verify plan-architect uses Edit tool (not Write) to preserve markers
4. Alternative: Use Edit tool directly to simulate plan-architect behavior

**Effort**: Medium (4-5 hours, requires plan-architect behavioral testing)
**Impact**: High (critical for revision data integrity)
**Priority**: Critical

---

### Test 4: test_revise_small_plan

**File**: `/home/benjamin/.config/.claude/tests/commands/test_revise_small_plan.sh`

**Current Status**: FAILED (extensive setup, but manual simulation)

**Analysis**:
- **Purpose**: Full `/revise` workflow integration test (Setup → Research → Planning → Completion)
- **Implementation**: 434 lines with 12 test scenarios, but all manually simulated
- **Issue**: Simulates research reports, backup creation, plan revision without executing actual workflow

**Root Cause**: Integration test skeleton without actual integration. Creates:
- Mock research reports (lines 164-186)
- Mock backups (lines 199-212)
- Manually written "revised" plans (lines 216-283)

**Current Test Flow**:
```bash
# Test 4: Simulate research phase artifacts
cat > "${RESEARCH_DIR}/001_revision_analysis.md" <<'EOF'
# Revision Analysis: Error Handling
## Current State
Authentication flow lacks error handling for network failures
EOF

# Test 6: Simulate plan revision (manually written, not by plan-architect)
cat > "$TEST_PLAN" <<'EOF'
# Feature Implementation Plan
## Revision History
- **2025-11-26**: Revised based on error handling requirements
  - Added Phase 2.5: Error Handling Implementation
EOF
```

**Fix Approach**:
1. **Phase 1**: Execute actual `/revise` command with test plan
2. **Phase 2**: Mock research-specialist to return test reports
3. **Phase 3**: Mock plan-architect to create revised plan
4. **Phase 4**: Verify all 12 test scenarios against actual output

**Effort**: High (6-8 hours, full integration testing)
**Impact**: High (most comprehensive revision test)
**Priority**: Critical

---

### Test 5: test_plan_architect_revision_mode

**File**: `/home/benjamin/.config/.claude/tests/agents/test_plan_architect_revision_mode.sh`

**Current Status**: FAILED (agent metadata validation only)

**Analysis**:
- **Purpose**: Verify plan-architect agent supports revision mode (vs creation mode)
- **Implementation**: Reads plan-architect.md file, greps for keywords, creates mock plans
- **Issue**: Tests agent file metadata, not actual agent behavior

**Test Categories** (10 tests):
1. **Metadata Tests** (5 tests): Grep for "operation.mode", "Edit tool", "PLAN_REVISED"
2. **Fixture Tests** (3 tests): Create mock plans with `[COMPLETE]` markers
3. **Simulation Tests** (2 tests): Test workflow context format, revision history format

**Root Cause**: Tests infrastructure around revision mode, not revision mode itself. All tests pass/fail based on file content grep:
```bash
# Line 44: Test 1
if grep -q "operation.mode\|Operation Mode\|plan revision" "$PLAN_ARCHITECT"; then
  pass "plan-architect.md contains revision mode logic"
fi

# Line 60: Test 2
if grep -A 3 "allowed-tools:" "$PLAN_ARCHITECT" | grep -q "Edit"; then
  pass "plan-architect.md has Edit tool enabled"
fi
```

**Fix Approach**:
1. **Option A (Keep as metadata test)**: Move to `/tests/validation/agents/`
2. **Option B (Add behavioral test)**: Invoke plan-architect in revision mode, verify:
   - Uses Edit tool (not Write)
   - Preserves `[COMPLETE]` markers
   - Adds revision history entries
   - Returns `PLAN_REVISED` signal

**Effort**: Low for Option A (1 hour), Medium for Option B (4-5 hours)
**Impact**: Medium (validates agent configuration)
**Priority**: Medium

---

## Category 2: Test Infrastructure Issues (6 Tests)

### Test 6: test_command_remediation

**File**: `/home/benjamin/.config/.claude/tests/features/commands/test_command_remediation.sh`

**Current Status**: FAILED (1/11 tests failed)

**Analysis**:
- **Purpose**: Integration tests for 4 remediation layers from Plan 864
- **Implementation**: 11 test functions validating preprocessing safety, library availability, state persistence, error visibility
- **Issue**: 1 test failing due to library sourcing path mismatch

**Test Breakdown**:
- **Layer 1 (Preprocessing Safety)**: 2 tests (PASSING)
- **Layer 2 (Library Availability)**: 2 tests (1 FAILING - function_availability_after_sourcing)
- **Layer 3 (State Persistence)**: 3 tests (PASSING)
- **Layer 4 (Error Visibility)**: 4 tests (PASSING)

**Root Cause**: Line 165 sources `state-persistence.sh`, but test expects functions from `error-handling.sh`:
```bash
# Line 165: Sources wrong library
source "$PROJECT_ROOT/lib/core/state-persistence.sh" 2>/dev/null

# Lines 171-184: Expects functions from error-handling.sh (not state-persistence.sh)
if ! command -v load_workflow_state &>/dev/null; then
  echo "  ERROR: load_workflow_state not available after sourcing"
  return 1
fi
```

**Fix Approach**:
1. Change line 165 to source both libraries:
   ```bash
   source "$PROJECT_ROOT/lib/core/state-persistence.sh" 2>/dev/null || return 1
   source "$PROJECT_ROOT/lib/core/error-handling.sh" 2>/dev/null || return 1
   ```
2. Or update test to only check state-persistence functions

**Effort**: Trivial (15 minutes)
**Impact**: High (blocks Plan 864 validation)
**Priority**: Critical

---

### Test 7: test_convert_docs_error_logging

**File**: `/home/benjamin/.config/.claude/tests/features/commands/test_convert_docs_error_logging.sh`

**Current Status**: FAILED (library sourcing error)

**Analysis**:
- **Purpose**: Test `/convert-docs` error logging integration
- **Implementation**: 7 tests for error logging availability, validation errors, log structure
- **Issue**: Test attempts to source `convert-core.sh`, which doesn't source `error-handling.sh` properly

**Test Flow**:
```bash
# Line 124: Attempt to source library
bash -c "source '${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh' 2>/dev/null"

# Line 142: Check ERROR_LOGGING_AVAILABLE variable
output=$(bash -c "
  export CLAUDE_PROJECT_DIR='${PROJECT_ROOT}'
  source '${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh' 2>/dev/null
  echo \$ERROR_LOGGING_AVAILABLE
")
# Expected: "true", but variable not set
```

**Root Cause**: `convert-core.sh` may not properly initialize `ERROR_LOGGING_AVAILABLE` variable when sourced in test context.

**Fix Approach**:
1. Check if `convert-core.sh` sources `error-handling.sh`
2. Verify `ERROR_LOGGING_AVAILABLE` is exported after sourcing
3. Add test setup to ensure `CLAUDE_PROJECT_DIR` is set before sourcing

**Effort**: Low (1-2 hours, library investigation)
**Impact**: Medium (validates convert-docs error integration)
**Priority**: High

---

### Test 8: test_compliance_remediation_phase7

**File**: `/home/benjamin/.config/.claude/tests/features/compliance/test_compliance_remediation_phase7.sh`

**Current Status**: FAILED (command path validation errors)

**Analysis**:
- **Purpose**: Comprehensive compliance verification for 6 remediation areas across 5 commands
- **Implementation**: 300 lines testing agent invocation, variable scope, verification blocks, checkpoints, error diagnostics, library versions
- **Issue**: Hardcoded paths don't match actual command locations

**Test Structure**:
- **Area 1**: Agent invocation patterns (13 instances)
- **Area 2**: Bash block variable scope (5 commands)
- **Area 3**: Execution enforcement markers (26 instances)
- **Area 4**: Checkpoint reporting (11 instances)
- **Area 5**: Error diagnostic enhancements (17 instances)
- **Area 6**: Library version requirements

**Root Cause**: Lines 18-24 define hardcoded paths:
```bash
COMMAND_PATHS=(
  "${CLAUDE_PROJECT_DIR}/.claude/commands/build.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/debug.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/research.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/plan.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/revise.md"
)
```

Test expects all 5 commands to exist, but test environment may not have all of them, or paths may be incorrect.

**Fix Approach**:
1. Add file existence checks before running tests:
   ```bash
   for path in "${COMMAND_PATHS[@]}"; do
     if [[ ! -f "$path" ]]; then
       echo "ERROR: Command file not found: $path"
       exit 2
     fi
   done
   ```
2. Or make test skip missing commands gracefully

**Effort**: Low (1 hour)
**Impact**: Medium (validates compliance patterns)
**Priority**: High

---

### Test 9: test_research_err_trap

**File**: `/home/benjamin/.config/.claude/tests/features/specialized/test_research_err_trap.sh`

**Current Status**: FAILED (bash error trap tests)

**Analysis**:
- **Purpose**: Validate bash ERR trap error logging for 6 scenarios
- **Implementation**: 455 lines testing syntax errors, unbound variables, command not found, function not found, library sourcing failure, state file missing
- **Issue**: Tests expect error log entries that aren't being created

**Test Scenarios**:
1. **T1**: Syntax error capture (exit code 2) - EXPECTED TO FAIL
2. **T2**: Unbound variable capture - EXPECTED TO FAIL
3. **T3**: Command not found (exit 127) - EXPECTED TO FAIL
4. **T4**: Function not found - EXPECTED TO FAIL
5. **T5**: Library sourcing failure (known limitation) - EXPECTED TO FAIL
6. **T6**: State file missing (existing conditional check) - SHOULD PASS

**Root Cause**: Test runs in two modes:
- **baseline**: Expects 1/6 tests to pass (only T6, existing error handling)
- **with-traps**: Expects 5/6 tests to pass (all except T5, pre-trap error)

Test is failing because ERR trap setup is not implemented in `/research` command. Lines 120-159 create temporary test scripts with trap setup:
```bash
cat > "$test_file" << EOF
#!/usr/bin/env bash
source $PROJECT_ROOT/.claude/lib/core/error-handling.sh 2>/dev/null
setup_bash_error_trap "/test-t1" "test_t1_\$\$" "syntax test"

# Intentional syntax error
for i in 1 2 3
  echo \$i
done
EOF
```

**Fix Approach**:
1. **Option A**: Implement ERR trap in error-handling.sh and add to commands
2. **Option B**: Mark test as "feature not implemented" and skip
3. **Option C**: Remove test (ERR trap may not be desired behavior)

**Effort**: High for Option A (6-8 hours), Trivial for B/C (15 minutes)
**Impact**: Low (ERR trap is nice-to-have, not critical)
**Priority**: Low (mark as feature-not-implemented)

---

### Test 10: test_path_canonicalization_allocation

**File**: `/home/benjamin/.config/.claude/tests/integration/test_path_canonicalization_allocation.sh`

**Current Status**: FAILED (lock file test commented out)

**Analysis**:
- **Purpose**: Test path canonicalization in `allocate_and_create_topic()` for symlink handling
- **Implementation**: 2 tests (symlink allocation, single lock file)
- **Issue**: Test 2 (single_lock_file) is commented out due to test hang (line 77)

**Test Flow**:
```bash
# Lines 22-51: Test 1 - Allocate via symlink path uses same canonical path
test_symlink_allocation() {
  mkdir -p "$real_specs"
  ln -s "$real_specs" "$link_specs"

  # Allocate via real path
  result1=$(allocate_and_create_topic "$real_specs" "via_real" 2>&1)
  num1="${result1%|*}"

  # Allocate via symlink path
  result2=$(allocate_and_create_topic "$link_specs" "via_link" 2>&1)
  num2="${result2%|*}"

  # Should have sequential numbers
  if [[ $num2_int -eq $((num1_int + 1)) ]]; then
    pass "symlink_allocation"
  fi
}

# Lines 54-72: Test 2 - Single lock file exists (COMMENTED OUT)
test_single_lock_file() {
  allocate_and_create_topic "$test_specs" "first" >/dev/null 2>&1

  # Check for lock files (use ls instead of find to avoid hanging)
  lock_count=$(ls -1 "$test_specs"/.topic_number.lock 2>/dev/null | wc -l)

  if [[ $lock_count -eq 1 ]]; then
    pass "single_lock_file"
  fi
}
```

**Root Cause**: Line 77 comment indicates test causes hang:
```bash
# Skipping test_single_lock_file - causing test hang (lock file exists, verified manually)
```

Lock file may not be cleaned up properly, causing subsequent allocations to wait indefinitely.

**Fix Approach**:
1. Investigate lock cleanup in `allocate_and_create_topic()`
2. Add timeout to lock file acquisition (currently may wait forever)
3. Add test cleanup to remove lock files after test completion
4. Re-enable test with timeout protection

**Effort**: Medium (3-4 hours, lock mechanism review)
**Impact**: Medium (validates concurrent allocation safety)
**Priority**: High

---

### Test 11: test_system_wide_location

**File**: `/home/benjamin/.config/.claude/tests/integration/test_system_wide_location.sh`

**Current Status**: FAILED (comprehensive integration test)

**Analysis**:
- **Purpose**: Comprehensive integration tests for unified location detection (50+ tests across 4 groups)
- **Implementation**: 1656 lines testing isolated commands, command chaining, concurrent execution, backward compatibility
- **Issue**: Multiple test failures across groups

**Test Structure**:
- **Group 1**: Isolated command execution (25 tests) - /report, /plan, /orchestrate commands
- **Group 2**: Command chaining (10 tests) - /orchestrate → /report, /orchestrate → /plan
- **Group 3**: Concurrent execution (5 tests + stress test) - Parallel topic allocation
- **Group 4**: Backward compatibility (10 tests) - Legacy paths, git paths, env overrides

**Validation Gate**: Requires ≥95% pass rate (≥47/50 tests) to pass

**Root Cause Analysis**:
Test is too comprehensive and couples multiple concerns:
1. Unit tests (lazy creation, JSON structure)
2. Integration tests (command chaining)
3. Stress tests (100 iterations × 10 processes)
4. Compatibility tests (legacy paths)

Likely failing due to:
- Test environment isolation issues (uses `TEST_SPECS_ROOT` but may conflict with real specs)
- Timing issues in concurrent tests
- Missing jq dependency (many tests skip if jq unavailable)

**Fix Approach**:
1. **Immediate**: Run test with `--verbose` to identify specific failures
2. **Short-term**: Split into focused test suites:
   - `test_location_detection_unit.sh` (Group 1 tests)
   - `test_location_detection_integration.sh` (Group 2 tests)
   - `test_location_detection_concurrent.sh` (Group 3 tests)
   - `test_location_detection_compat.sh` (Group 4 tests)
3. **Long-term**: Add proper test isolation and cleanup

**Effort**: High (8-10 hours, test refactoring)
**Impact**: Critical (validates core location detection)
**Priority**: Critical

---

### Test 12: test_plan_progress_markers

**File**: `/home/benjamin/.config/.claude/tests/progressive/test_plan_progress_markers.sh`

**Current Status**: FAILED (checkbox-utils.sh sourcing error)

**Analysis**:
- **Purpose**: Test suite for plan progress marker functions (add_in_progress_marker, add_complete_marker, etc.)
- **Implementation**: 341 lines with 6 test functions testing marker lifecycle
- **Issue**: Line 26 sources `checkbox-utils.sh` but library may not exist or has errors

**Test Structure**:
```bash
# Line 26: Source library (fails silently)
(set +e; source "$CLAUDE_LIB/plan/checkbox-utils.sh") 2>/dev/null
source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || true

# Lines 94-136: Test remove_status_marker
# Lines 138-172: Test add_in_progress_marker
# Lines 174-208: Test add_complete_marker
# Lines 210-242: Test add_not_started_markers
# Lines 244-283: Test marker lifecycle
# Lines 285-302: Test edge cases
```

**Root Cause**: `checkbox-utils.sh` either:
1. Doesn't exist at expected path
2. Has sourcing errors (missing dependencies)
3. Functions not defined after sourcing

**Fix Approach**:
1. Verify `checkbox-utils.sh` exists: `ls -la /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`
2. Check library dependencies and add to source chain
3. Add error handling to detect sourcing failures:
   ```bash
   if ! source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null; then
     echo "ERROR: Failed to source checkbox-utils.sh"
     exit 2
   fi

   # Verify functions available
   if ! command -v add_in_progress_marker &>/dev/null; then
     echo "ERROR: Functions not available after sourcing"
     exit 2
   fi
   ```

**Effort**: Low (1-2 hours, library investigation)
**Impact**: High (validates plan progress tracking)
**Priority**: Critical

---

## Category 3: Actual Code Bugs (2 Tests)

### Test 13: test_command_topic_allocation

**File**: `/home/benjamin/.config/.claude/tests/topic-naming/test_command_topic_allocation.sh`

**Current Status**: FAILED (atomic allocation validation)

**Analysis**:
- **Purpose**: Integration test for atomic topic allocation across all commands (verify no duplicate topic numbers under concurrent load)
- **Implementation**: 412 lines with 12 tests validating library sourcing, function usage, concurrent allocation, error handling
- **Issue**: Commands may not be using atomic allocation correctly

**Test Structure**:
1. **Static Analysis** (5 tests): Verify commands source unified-location-detection.sh
2. **Documentation** (3 tests): Lock file cleanup, docs updated, migration guide
3. **Functional** (4 tests): Concurrent allocation, sequential numbering, stress test, permission handling

**Root Cause Analysis**:
Test validates that commands use `initialize_workflow_paths()` instead of unsafe count+increment pattern. Likely failures:

**Test 2 (function_usage)**: Commands missing `initialize_workflow_paths` call (lines 84-106)
```bash
for cmd in "plan.md" "debug.md" "research.md"; do
  if ! grep -q "initialize_workflow_paths" "$cmd_path"; then
    fail "$test_name - $cmd missing initialize_workflow_paths call"
  fi
done
```

**Test 6 (concurrent_library_allocation)**: Duplicate topic numbers under parallel load (lines 183-221)
```bash
# Launch 20 parallel processes
for i in {1..20}; do
  (allocate_and_create_topic "$test_root" "integration_test_$i" > /dev/null) &
done
wait

# Count directories (should be exactly 20)
count=$(ls -1d "$test_root"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)
if [ "$count" -ne 20 ]; then
  fail "$test_name - Expected 20 directories, got $count"
fi
```

**Fix Approach**:
1. **Verify migration status**: Check if all commands migrated to atomic allocation
   ```bash
   grep -r "initialize_workflow_paths" .claude/commands/
   grep -r "allocate_and_create_topic" .claude/commands/
   ```
2. **Fix unmigrated commands**: Update to use unified-location-detection.sh
3. **Test concurrent allocation**: Run Test 6 manually to verify lock mechanism works
4. **Investigate lock cleanup**: Ensure lock files don't cause hangs

**Effort**: Medium (4-6 hours, command migration verification)
**Impact**: Critical (prevents duplicate topic numbers in production)
**Priority**: Critical

---

## Test 14: test_no_empty_directories (Bonus - Not in Original List)

**File**: `/home/benjamin/.config/.claude/tests/validation/test_no_empty_directories.sh`

**Current Status**: FAILED (1 empty directory detected)

**Analysis**:
- **Purpose**: Validate no empty topic directories exist after test runs
- **Implementation**: Post-test validation, counts empty directories in specs/
- **Issue**: Test pollution - one test is creating empty directory

**Root Cause**: Test runner output shows:
```
════════════════════════════════════════════════
✓ NO POLLUTION DETECTED
════════════════════════════════════════════════
Post-test validation: 1 empty topic directories
```

One test is creating a topic directory but not cleaning it up properly.

**Fix Approach**:
1. Add cleanup to all failing tests
2. Run `find .claude/specs -type d -empty` to identify empty directory
3. Trace which test created it (check test timestamps)
4. Add proper cleanup to that test's teardown

**Effort**: Low (1 hour, cleanup investigation)
**Impact**: Low (test hygiene, not functionality)
**Priority**: Medium

---

## Prioritized Fix Plan

### Phase 1: Critical Infrastructure Fixes (Est: 8-12 hours)

1. **test_command_remediation** (15 min) - Fix library sourcing path
2. **test_revise_preserve_completed** (4-5 hrs) - Add plan-architect integration
3. **test_revise_small_plan** (6-8 hrs) - Full integration test implementation
4. **test_system_wide_location** (8-10 hrs) - Split and fix comprehensive test
5. **test_plan_progress_markers** (1-2 hrs) - Fix checkbox-utils.sh sourcing
6. **test_command_topic_allocation** (4-6 hrs) - Verify atomic allocation migration

**Estimated Total**: 24-31 hours

### Phase 2: Test Implementation Completion (Est: 8-12 hours)

7. **test_convert_docs_error_logging** (1-2 hrs) - Fix library initialization
8. **test_compliance_remediation_phase7** (1 hr) - Add path existence checks
9. **test_path_canonicalization_allocation** (3-4 hrs) - Fix lock file cleanup
10. **test_revise_long_prompt** (3-4 hrs) - Add actual command execution
11. **test_no_empty_directories** (1 hr) - Add proper cleanup

**Estimated Total**: 9-12 hours

### Phase 3: Nice-to-Have Fixes (Est: 2-4 hours)

12. **test_plan_architect_revision_mode** (1 hr) - Move to validation tests
13. **test_research_err_trap** (15 min) - Mark as feature-not-implemented

**Estimated Total**: 1.25 hours

---

## Overall Summary

| Category | Tests | Total Effort | Priority |
|----------|-------|--------------|----------|
| Incomplete Implementations | 5 | 15-22 hrs | High |
| Infrastructure Issues | 6 | 16-23 hrs | Critical |
| Actual Code Bugs | 2 | 8-10 hrs | Critical |
| **TOTAL** | **13** | **39-55 hrs** | Mixed |

### Recommended Execution Order

**Week 1 (16 hours)**:
1. test_command_remediation (15 min) ← Quick win
2. test_plan_progress_markers (1-2 hrs) ← Quick win
3. test_convert_docs_error_logging (1-2 hrs) ← Quick win
4. test_compliance_remediation_phase7 (1 hr) ← Quick win
5. test_no_empty_directories (1 hr) ← Quick win
6. test_command_topic_allocation (4-6 hrs) ← Critical bug
7. test_path_canonicalization_allocation (3-4 hrs) ← Infrastructure

**Week 2 (16 hours)**:
8. test_system_wide_location (8-10 hrs) ← Largest test
9. test_revise_small_plan (6-8 hrs) ← Integration test

**Week 3 (8 hours)**:
10. test_revise_preserve_completed (4-5 hrs) ← Agent testing
11. test_revise_long_prompt (3-4 hrs) ← Command testing
12. test_plan_architect_revision_mode (1 hr) ← Cleanup
13. test_research_err_trap (15 min) ← Mark as skipped

### Success Criteria

- **Target**: 100% test pass rate (113/113 suites)
- **Current**: 88.5% (100/113 suites)
- **Gap**: 13 failing suites
- **Estimated Resolution**: 3-4 weeks (39-55 hours total effort)

### Risk Assessment

**Low Risk** (6 tests):
- test_command_remediation
- test_compliance_remediation_phase7
- test_convert_docs_error_logging
- test_plan_progress_markers
- test_no_empty_directories
- test_plan_architect_revision_mode

**Medium Risk** (5 tests):
- test_revise_long_prompt
- test_revise_preserve_completed
- test_path_canonicalization_allocation
- test_research_err_trap
- test_revise_error_recovery

**High Risk** (2 tests):
- test_system_wide_location (requires significant refactoring)
- test_command_topic_allocation (may reveal migration issues)

---

## Implementation Status

- **Status**: Planning Complete
- **Plan**: [../plans/001-fix-failing-test-suites-plan.md](../plans/001-fix-failing-test-suites-plan.md)
- **Implementation**: [Will be updated by /build command]
- **Date**: 2025-11-27

## Completion Signal

REPORT_CREATED: /home/benjamin/.config/.claude/specs/953_readme_docs_standards_audit/reports/001_failing_tests_analysis.md
