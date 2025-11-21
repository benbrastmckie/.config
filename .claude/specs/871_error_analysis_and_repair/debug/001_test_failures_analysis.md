# Debug Report: Test Failures Analysis

## Metadata
- **Date**: 2025-11-20
- **Agent**: debug-analyst
- **Issue**: Tests failed with exit code 1 - 10 test suites failed out of 95 total
- **Hypothesis**: Multiple root causes affecting different test categories
- **Status**: Investigating

## Issue Description

Tests failed with exit code 1 - 10 test suites failed out of 95 total

Failed Test Suites:
1. test_bash_error_compliance - .claude/tests/test_bash_error_compliance.sh
2. test_directory_naming_integration - .claude/tests/test_directory_naming_integration.sh
3. test_error_logging_compliance - .claude/tests/test_error_logging_compliance.sh
4. test_plan_progress_markers - .claude/tests/test_plan_progress_markers.sh
5. test_research_err_trap - .claude/tests/test_research_err_trap.sh
6. test_semantic_slug_commands - .claude/tests/test_semantic_slug_commands.sh
7. test_topic_name_sanitization - .claude/tests/test_topic_name_sanitization.sh
8. test_topic_naming - .claude/tests/test_topic_naming.sh
9. test_topic_slug_validation - .claude/tests/test_topic_slug_validation.sh
10. validate_executable_doc_separation - .claude/tests/validate_executable_doc_separation.sh

## Investigation

### Test Reproduction

All 10 test failures were reproduced successfully by running the test suite. The failures fall into 5 distinct categories:

**Category 1: Missing Functions (7 tests)**
- test_directory_naming_integration
- test_topic_name_sanitization (46/60 tests failed)
- test_topic_naming
- test_topic_slug_validation

All fail with: `sanitize_topic_name: command not found` or `extract_significant_words: command not found`

**Category 2: Error Logging Compliance (1 test)**
- test_error_logging_compliance
- 4/13 commands missing error logging: /collapse, /convert-docs, /errors, /expand

**Category 3: Bash Error Trap Compliance (1 test)**
- test_bash_error_compliance
- /build command: Block 3 (line ~629) missing `setup_bash_error_trap()`

**Category 4: Documentation Separation (1 test)**
- validate_executable_doc_separation
- /build.md: 1483 lines (max 1200)
- /debug.md: 1269 lines (max 1200)

**Category 5: Plan Progress Markers (1 test)**
- test_plan_progress_markers
- Error: "Cannot mark Phase 1 complete - incomplete tasks remain"
- `add_complete_marker()` validates phase completion before marking

**Category 6: Stopword Filtering (1 test)**
- test_semantic_slug_commands
- Stopword "the" not being removed from: "fix the token refresh bug"
- Expected: "fix_token_refresh_bug"
- Got: "fix_the_token_refresh_bug"

### Code Investigation

**Finding 1: Function Migration Issue**

File: `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh`
- Current version: 203 lines
- Backup version: 343 lines
- **140 lines removed** including `sanitize_topic_name()` and `extract_significant_words()`

These functions were moved to:
File: `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh`
- Line 366: `sanitize_topic_name()`
- Line 30 (in backup): `extract_significant_words()`

**Problem**: Tests source `topic-utils.sh` expecting these functions, but they're not exported/available.

**Circular Dependency**:
- `unified-location-detection.sh` sources `topic-utils.sh` (line 84)
- But `sanitize_topic_name` is in `unified-location-detection.sh`
- Tests can't source both without creating dependency issues

**Finding 2: Error Logging Missing**

Commands missing error logging integration:
1. `/home/benjamin/.config/.claude/commands/collapse.md`
2. `/home/benjamin/.config/.claude/commands/convert-docs.md`
3. `/home/benjamin/.config/.claude/commands/errors.md`
4. `/home/benjamin/.config/.claude/commands/expand.md`

Required additions:
- Source error-handling library
- Set workflow metadata (COMMAND_NAME, WORKFLOW_ID, USER_ARGS)
- Initialize error log with `ensure_error_log_exists`
- Log errors with `log_command_error` at all error points

**Finding 3: Missing Error Trap**

File: `/home/benjamin/.config/.claude/commands/build.md`
- Block 3 (lines 620-629): Bash block without `setup_bash_error_trap()`
- Block calculates test output path and echoes variables for Task tool
- Missing trap integration at block start

**Finding 4: File Size Violations**

File: `/home/benjamin/.config/.claude/commands/build.md`
- Current: 1483 lines
- Maximum: 1200 lines
- Overage: 283 lines (23.6% over limit)

File: `/home/benjamin/.config/.claude/commands/debug.md`
- Current: 1269 lines
- Maximum: 1200 lines
- Overage: 69 lines (5.8% over limit)

**Finding 5: Progress Marker Validation**

File: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`
- Line 472-507: `add_complete_marker()` function
- Line 482: Calls `verify_phase_complete()` before marking
- Returns error if incomplete tasks remain

This is correct behavior - the test may have incorrect expectations.

**Finding 6: Stopword Filtering Logic**

File: `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh`
- Line 366+: `sanitize_topic_name()` function
- Stopword list includes "the" but filtering may not be working correctly

## Root Cause Analysis

### Primary Root Cause: Function Migration Without Test Updates

**Hypothesis**: CONFIRMED

**Evidence**:
1. Functions `sanitize_topic_name()` and `extract_significant_words()` moved from `topic-utils.sh` to `unified-location-detection.sh`
2. Backup file shows 140 lines removed from `topic-utils.sh`
3. All 7 failing tests source `topic-utils.sh` expecting these functions
4. Tests fail with "command not found" errors

**Timeline**:
- Backup created: 2025-11-20 17:21:08
- Functions moved during refactoring to consolidate location detection logic
- Tests not updated to source new location

### Secondary Root Causes

**RC2: Missing Error Logging Integration**
- 4 commands never integrated error logging standard
- Missing library sourcing and log calls
- Compliance standard not enforced during initial implementation

**RC3: Missing Error Trap in /build**
- Block 3 added without error trap integration
- ERR trap standard requires all executable blocks to have traps
- Documentation blocks (usage examples) are exempt

**RC4: Command File Size Growth**
- /build.md and /debug.md exceeded size limits
- Need documentation extraction to guide files
- Executable/documentation separation standard violated

**RC5: Test Validation Logic**
- test_plan_progress_markers expects to mark incomplete phase complete
- This violates the function's design (intentional validation)
- Test needs fixing, not the function

**RC6: Stopword Filtering Implementation**
- Stopword "the" in list but not being filtered correctly
- Logic issue in word filtering loop in `sanitize_topic_name()`

## Proposed Fix

### Fix 1: Restore Functions to topic-utils.sh (RECOMMENDED)

**Approach**: Add back `sanitize_topic_name()` and `extract_significant_words()` to `topic-utils.sh`

**Rationale**:
- Tests expect these functions in `topic-utils.sh`
- Minimal disruption - only update one file
- Maintains backward compatibility
- Avoids circular dependency issues

**Implementation**:
1. Copy functions from `unified-location-detection.sh` (lines 366+, line 30 from backup)
2. Add to end of `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh`
3. Keep functions in `unified-location-detection.sh` for now (duplication acceptable)
4. Add comment explaining dual location

**Affected Files**:
- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` (add functions)

**Fix Complexity**: Low
**Risk Level**: Low
**Testing Required**: Run failing test suites to verify

### Fix 2: Add Error Logging to 4 Commands

**Implementation**:
Add to each of 4 commands (/collapse, /convert-docs, /errors, /expand):

```bash
# Source error handling library
source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library"
  exit 1
}

# Initialize error logging
ensure_error_log_exists
COMMAND_NAME="/command-name"
WORKFLOW_ID="workflow_$(date +%s)"
USER_ARGS="$*"
```

**Affected Files**:
- `/home/benjamin/.config/.claude/commands/collapse.md`
- `/home/benjamin/.config/.claude/commands/convert-docs.md`
- `/home/benjamin/.config/.claude/commands/errors.md`
- `/home/benjamin/.config/.claude/commands/expand.md`

**Fix Complexity**: Low
**Risk Level**: Low
**Testing Required**: test_error_logging_compliance.sh

### Fix 3: Add Error Trap to /build Block 3

**Implementation**:
Add to beginning of bash block at line ~621:

```bash
# Setup error handling
setup_bash_error_trap
```

**Affected Files**:
- `/home/benjamin/.config/.claude/commands/build.md` (line ~621)

**Fix Complexity**: Trivial
**Risk Level**: Very Low
**Testing Required**: test_bash_error_compliance.sh

### Fix 4: Extract Documentation from /build and /debug

**Implementation**:
1. Move usage examples and detailed explanations to guide files
2. Keep only essential execution logic in command files
3. Add references to guide files for documentation

**Affected Files**:
- `/home/benjamin/.config/.claude/commands/build.md` (reduce by 283 lines)
- `/home/benjamin/.config/.claude/commands/debug.md` (reduce by 69 lines)
- `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` (expand)
- `/home/benjamin/.config/.claude/docs/guides/commands/debug-command-guide.md` (expand)

**Fix Complexity**: Medium
**Risk Level**: Medium (requires careful content migration)
**Testing Required**: validate_executable_doc_separation.sh, manual testing

### Fix 5: Update test_plan_progress_markers Test

**Implementation**:
Modify test to expect error when marking incomplete phase complete:

```bash
# Test marking incomplete phase should fail
if ! add_complete_marker "$test_file" "1" 2>/dev/null; then
  test_pass "Lifecycle: Phase 1 cannot be marked complete (incomplete tasks)"
else
  test_fail "Lifecycle: Phase 1 should fail with incomplete tasks"
fi

# Mark all tasks complete first
mark_phase_complete "$test_file" "1"

# Now marking complete should succeed
if add_complete_marker "$test_file" "1"; then
  test_pass "Lifecycle: Phase 1 IN PROGRESS -> COMPLETE (after tasks done)"
else
  test_fail "Lifecycle: Phase 1 IN PROGRESS -> COMPLETE"
fi
```

**Affected Files**:
- `/home/benjamin/.config/.claude/tests/test_plan_progress_markers.sh` (lines 245-251)

**Fix Complexity**: Low
**Risk Level**: Low
**Testing Required**: test_plan_progress_markers.sh

### Fix 6: Debug Stopword Filtering Logic

**Investigation Required**:
1. Examine `sanitize_topic_name()` function in detail
2. Test stopword filtering with various inputs
3. Identify why "the" is not being filtered
4. Fix word matching/filtering logic

**Affected Files**:
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh` (line 366+)

**Fix Complexity**: Low-Medium
**Risk Level**: Low
**Testing Required**: test_semantic_slug_commands.sh

## Impact Assessment

### Scope

**Affected Files**: 11 files total
- 1 library file (topic-utils.sh)
- 4 command files (collapse, convert-docs, errors, expand)
- 2 command files (build, debug - size reduction)
- 2 guide files (build-command-guide, debug-command-guide)
- 1 test file (test_plan_progress_markers.sh)
- 1 library file (unified-location-detection.sh - stopword fix)

**Affected Components**:
- Topic naming system (7 tests)
- Error logging system (1 test)
- Error trap system (1 test)
- Documentation separation (2 commands)
- Plan progress tracking (1 test)
- Semantic slug generation (1 test)

**Severity**: Medium

### Related Issues

1. **Function Duplication**: Restoring functions to topic-utils.sh creates duplication
   - Need to decide on long-term location
   - Consider deprecation plan for dual location

2. **Test Isolation**: Tests expect production file structure
   - Tests should use temporary directories (already do via CLAUDE_SPECS_ROOT)
   - Tests should not assume specific library sourcing patterns

3. **Refactoring Documentation**: Function migration not documented
   - Breaking changes should be tracked
   - Update documentation when moving functions between libraries

4. **Compliance Testing**: Error logging compliance not enforced in CI
   - Consider pre-commit hooks for compliance checks
   - Automated validation before merging

## Recommendations

### Immediate Actions (Fix Test Failures)

1. **Restore functions to topic-utils.sh** (Fix 1) - Highest priority
   - Resolves 7/10 test failures immediately
   - Low risk, quick implementation

2. **Add error trap to /build** (Fix 3) - Quick win
   - Resolves 1/10 test failures
   - Trivial change, very low risk

3. **Add error logging to 4 commands** (Fix 2) - Compliance
   - Resolves 1/10 test failures
   - Straightforward implementation

4. **Update progress markers test** (Fix 5) - Test fix
   - Resolves 1/10 test failures
   - Test logic correction, not code change

5. **Debug stopword filtering** (Fix 6) - Logic fix
   - Resolves 1/10 test failures
   - Requires investigation first

### Short-term Actions (Documentation)

6. **Extract documentation from /build and /debug** (Fix 4) - Deferred
   - Can be done after tests pass
   - Requires careful content migration
   - Medium complexity, medium risk

### Long-term Actions (Process Improvements)

7. **Create function migration guide**
   - Document process for moving functions between libraries
   - Include test update checklist
   - Prevent future "command not found" errors

8. **Implement compliance automation**
   - Pre-commit hooks for error logging compliance
   - Pre-commit hooks for error trap compliance
   - Automated file size validation

9. **Consolidate function locations**
   - Decide permanent location for topic naming functions
   - Remove duplication
   - Update all references

### Execution Order

**Phase 1**: Fix test failures (Fixes 1, 2, 3, 5, 6) - 1-2 hours
**Phase 2**: Documentation extraction (Fix 4) - 2-3 hours
**Phase 3**: Process improvements (Recommendations 7-9) - Future sprint

### Success Criteria

- All 10 test suites pass
- Test suite exit code: 0
- No new test failures introduced
- Documentation properly separated (can be deferred)
