# Test Failure Fix Coverage - Debug Strategy Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Debug strategy for Plan 861 test failures
- **Scope**: Fix jq operator precedence bug, improve test environment separation, achieve 100% test pass rate
- **Estimated Phases**: 4
- **Estimated Hours**: 4-6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 38.0
- **Research Reports**:
  - [Root Cause Analysis](/home/benjamin/.config/.claude/specs/872_test_failure_fix_coverage/reports/001_root_cause_analysis.md)

## Overview

The integration test suite for Plan 861 (bash error trap rollout) is experiencing 100% test failure (0/10 tests passing) due to a jq operator precedence bug in the test helper function. The root cause analysis confirms that:

1. **Primary Issue**: jq filter on line 65 of `test_bash_error_integration.sh` has operator precedence bug causing boolean-to-string type errors
2. **Secondary Issue**: Test environment detection fails for temporary test scripts, routing test errors to production log
3. **Validation Status**: Error logging implementation is correct; all error_message fields are strings

This debug strategy will fix the test suite, achieve 100% pass rate, and ensure proper test isolation.

## Research Summary

Key findings from root cause analysis:
- **jq Operator Precedence Bug** (line 65): Filter evaluates `(.command == "X" and .error_message)` as boolean before piping to `contains()`, causing type error
- **Error Log Structure**: All 35 production log entries validated - all error_message fields are strings (no boolean values found)
- **Test Environment Routing**: Temporary test scripts (`/tmp/test_*.sh`) don't trigger test environment detection, routing to production log
- **Coverage Gap**: Structural coverage is 91%, but runtime validation blocked by test failures

Recommended approach based on research:
1. Fix jq operator precedence with parentheses: `(.error_message | contains(...))`
2. Add explicit test environment variable (`CLAUDE_TEST_MODE=1`)
3. Enhance test diagnostics to distinguish error types
4. Verify ≥90% error capture rate after fixes

## Success Criteria
- [ ] All 10 integration tests pass (100% pass rate)
- [ ] Error capture rate ≥90% (target from test suite)
- [ ] Test logs properly isolated from production logs
- [ ] jq filter handles all error_message types safely
- [ ] Test diagnostics provide actionable error information
- [ ] All fixes conform to testing-protocols.md and code-standards.md
- [ ] Documentation updated with jq filter best practices

## Root Cause Summary

### Primary Root Cause: jq Operator Precedence Bug

**Location**: `/home/benjamin/.config/.claude/tests/test_bash_error_integration.sh:65`

**Problematic Code**:
```bash
local found=$(tail -20 "$ERROR_LOG_FILE" | jq -r "select(.command == \"$command_name\" and .error_message | contains(\"$error_pattern\")) | .timestamp" | head -1)
```

**Issue**: jq interprets the filter as `(.command == "X" and .error_message) | contains("Y")`, which evaluates to a boolean before piping to `contains()`. The `contains()` function requires string input, resulting in type error.

**Evidence**:
```
jq: error (at <stdin>:1): boolean (false) and string ("UNDEFINED_...) cannot have their containment checked
jq: error (at <stdin>:2): boolean (true) and string ("UNDEFINED_...) cannot have their containment checked
```

**Impact**: 100% test failure rate (10/10 tests failing with identical error)

### Secondary Issue: Test Environment Routing

**Problem**: Test errors from temporary scripts (`/tmp/test_*.sh`) route to production log instead of test log

**Root Cause**: Environment detection in `error-handling.sh:437-448` checks for `/tests/` in path, but temporary test scripts are outside this directory

**Impact**:
- Test errors pollute production log (5+ test entries found in production log)
- Test log file `.claude/tests/logs/test-errors.jsonl` doesn't exist
- Cleanup between test runs more complex

### Validation: Error Logging Implementation is Correct

**Verification**: Examined `/home/benjamin/.config/.claude/data/logs/errors.jsonl` with jq type analysis

**Results**:
- All 35 entries have `error_message` as string type
- No boolean values found in any log entry
- Log structure matches specification from `error-handling.sh:479-501`

**Conclusion**: The error logging implementation works correctly. Test failure is purely a test code bug.

## Technical Design

### Architecture Overview

The fix strategy targets three layers:

1. **Test Helper Layer** (Priority 1): Fix jq operator precedence in `check_error_logged()`
2. **Environment Detection Layer** (Priority 2): Add explicit test mode variable
3. **Diagnostics Layer** (Priority 3): Enhance error reporting in test suite

### Component Interactions

```
Test Script (test_bash_error_integration.sh)
    │
    ├─→ Set CLAUDE_TEST_MODE=1 (NEW)
    │
    ├─→ Create temp test scripts (/tmp/test_*.sh)
    │   └─→ Source error-handling.sh
    │       └─→ Check CLAUDE_TEST_MODE (NEW)
    │           ├─→ Route to test log (if set)
    │           └─→ Route to production log (if not set)
    │
    └─→ check_error_logged() helper
        └─→ jq filter with correct precedence (FIXED)
            └─→ Returns FOUND/NOT_FOUND/jq_error (ENHANCED)
```

### Fix Strategy

**Phase 1 - Critical Fix**:
- Fix jq operator precedence by adding parentheses
- Verify fix with manual jq testing
- Run integration test suite

**Phase 2 - Environment Separation**:
- Add `CLAUDE_TEST_MODE` environment variable
- Update error-handling.sh to check variable
- Verify test logs route correctly

**Phase 3 - Quality Improvements**:
- Enhance test diagnostics with error type detection
- Add jq error capture to test helper
- Create test log cleanup script

**Phase 4 - Documentation**:
- Update testing-protocols.md with jq filter patterns
- Document test environment separation
- Add troubleshooting guide for test failures

## Implementation Phases

### Phase 1: Fix jq Operator Precedence Bug [COMPLETE]
dependencies: []

**Objective**: Correct jq filter syntax to eliminate type errors and restore test functionality

**Complexity**: Low

**Tasks**:
- [x] Update line 65 of `test_bash_error_integration.sh` with correct parentheses (file: /home/benjamin/.config/.claude/tests/test_bash_error_integration.sh)
- [x] Change filter from `and .error_message | contains(...)` to `and (.error_message | contains(...))`
- [x] Test jq filter manually against production log to verify correct parsing
- [x] Verify filter returns expected timestamps for known log entries
- [x] Run integration test suite to confirm all 10 tests pass

**Testing**:
```bash
# Verify jq filter syntax manually
tail -5 /home/benjamin/.config/.claude/data/logs/errors.jsonl | \
  jq -r 'select(.command == "/test" and (.error_message | contains("Bash error"))) | .timestamp'

# Run integration test suite
cd /home/benjamin/.config/.claude/tests
./test_bash_error_integration.sh

# Expected: 10/10 tests pass, capture rate ≥90%
```

**Success Criteria**:
- jq no longer produces type errors
- All 10 integration tests pass
- Error capture rate ≥90%

**Expected Duration**: 1 hour

### Phase 2: Implement Test Environment Separation [COMPLETE]
dependencies: [1]

**Objective**: Isolate test logs from production logs using explicit environment variable

**Complexity**: Low

**Tasks**:
- [x] Add `export CLAUDE_TEST_MODE=1` to test script initialization (file: /home/benjamin/.config/.claude/tests/test_bash_error_integration.sh, lines 20-30)
- [x] Update environment detection in error-handling.sh to check `CLAUDE_TEST_MODE` variable (file: /home/benjamin/.config/.claude/lib/core/error-handling.sh, line 437)
- [x] Change condition from `if [[ "${BASH_SOURCE[2]:-}" =~ /tests/ ]] || [[ "$0" =~ /tests/ ]]; then` to include `|| [[ -n "${CLAUDE_TEST_MODE:-}" ]]`
- [x] Create test log directory if missing (file: /home/benjamin/.config/.claude/tests/logs/, ensure exists)
- [x] Run test suite and verify test errors route to `.claude/tests/logs/test-errors.jsonl`
- [x] Verify production log is not polluted with new test entries

**Testing**:
```bash
# Run test suite with environment variable
cd /home/benjamin/.config/.claude/tests
export CLAUDE_TEST_MODE=1
./test_bash_error_integration.sh

# Verify test log created and populated
test -f /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl
tail -10 /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl | jq .

# Verify production log not modified
PROD_ENTRIES_BEFORE=$(wc -l < /home/benjamin/.config/.claude/data/logs/errors.jsonl)
# ... run tests ...
PROD_ENTRIES_AFTER=$(wc -l < /home/benjamin/.config/.claude/data/logs/errors.jsonl)
[ "$PROD_ENTRIES_BEFORE" -eq "$PROD_ENTRIES_AFTER" ]
```

**Success Criteria**:
- Test errors route to test log (not production log)
- Test log directory and file created automatically
- Environment variable correctly detected by error-handling.sh

**Expected Duration**: 1.5 hours

### Phase 3: Enhance Test Diagnostics and Cleanup [NOT STARTED]
dependencies: [1, 2]

**Objective**: Improve test error reporting and add cleanup utilities

**Complexity**: Medium

**Tasks**:
- [ ] Update `check_error_logged()` to capture jq stderr (file: /home/benjamin/.config/.claude/tests/test_bash_error_integration.sh, lines 60-80)
- [ ] Add error type detection: distinguish "jq_error", "log_missing", "wrong_command", "wrong_message"
- [ ] Return detailed error codes: `NOT_FOUND:jq_error`, `NOT_FOUND:log_file_missing`, etc.
- [ ] Update test assertions to display detailed error information
- [ ] Create test log cleanup script (file: /home/benjamin/.config/.claude/tests/scripts/cleanup_test_logs.sh)
- [ ] Add cleanup script to test suite initialization
- [ ] Verify enhanced diagnostics provide actionable error messages

**Testing**:
```bash
# Test enhanced diagnostics with intentional failures
cd /home/benjamin/.config/.claude/tests

# Simulate missing log file
mv /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl /tmp/backup.jsonl
./test_bash_error_integration.sh
# Expected: "NOT_FOUND:log_file_missing"

# Restore log and test cleanup script
mv /tmp/backup.jsonl /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl
./scripts/cleanup_test_logs.sh
# Expected: logs cleared, backup created
```

**Success Criteria**:
- Test failures show specific error type (not generic "NOT_FOUND")
- Cleanup script removes test logs and backs up production log
- Enhanced diagnostics help debug future test failures

**Expected Duration**: 2 hours

### Phase 4: Documentation and Best Practices [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Document fixes, patterns, and troubleshooting procedures

**Complexity**: Low

**Tasks**:
- [ ] Add jq filter safety section to testing-protocols.md (file: /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md)
- [ ] Document operator precedence pitfalls and correct patterns
- [ ] Add test environment separation guidelines to error-handling.md (file: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)
- [ ] Document `CLAUDE_TEST_MODE` variable and usage
- [ ] Create troubleshooting guide for test failures (file: /home/benjamin/.config/.claude/docs/troubleshooting/test-failures.md)
- [ ] Add inline comments to test_bash_error_integration.sh explaining jq filter precedence
- [ ] Update root cause analysis report with implementation status

**Testing**:
```bash
# Verify documentation completeness
grep -q "jq operator precedence" /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md
grep -q "CLAUDE_TEST_MODE" /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md

# Verify inline comments added
grep -A 5 "check_error_logged()" /home/benjamin/.config/.claude/tests/test_bash_error_integration.sh | grep -q "precedence"
```

**Success Criteria**:
- testing-protocols.md includes jq filter safety guidelines
- error-handling.md documents test environment separation
- Troubleshooting guide covers common test failure scenarios
- Code comments explain jq precedence fix rationale

**Expected Duration**: 1.5 hours

## Testing Strategy

### Overall Approach
- **Unit Testing**: Validate jq filter syntax with manual test cases
- **Integration Testing**: Run full integration test suite after each phase
- **Regression Testing**: Verify production error logging still works correctly
- **Isolation Testing**: Confirm test logs don't pollute production logs

### Test Coverage Requirements
- All 10 integration tests must pass (100% pass rate)
- Error capture rate ≥90% (target from test suite specification)
- Test log isolation verified (0 test entries in production log)
- jq filter handles all error_message types (strings only, per validation)

### Test Commands
```bash
# Phase 1: Integration test suite
cd /home/benjamin/.config/.claude/tests
./test_bash_error_integration.sh

# Phase 2: Environment separation verification
export CLAUDE_TEST_MODE=1
./test_bash_error_integration.sh
test -f logs/test-errors.jsonl

# Phase 3: Enhanced diagnostics verification
./test_bash_error_integration.sh 2>&1 | grep "NOT_FOUND:" | head -3

# Phase 4: Documentation verification
grep -r "jq operator precedence" /home/benjamin/.config/.claude/docs/
```

### Success Metrics
- **Test Pass Rate**: 100% (10/10 tests)
- **Capture Rate**: ≥90% (calculated by test suite)
- **Test Isolation**: 100% (no test entries in production log)
- **Documentation Coverage**: 100% (all fix patterns documented)

## Documentation Requirements

### Files to Update
1. `/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md`
   - Add section: "jq Filter Safety and Operator Precedence"
   - Document common pitfalls and correct patterns
   - Add examples of type-safe jq filters

2. `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md`
   - Document `CLAUDE_TEST_MODE` environment variable
   - Explain test environment detection logic
   - Add log file routing flowchart

3. `/home/benjamin/.config/.claude/docs/troubleshooting/test-failures.md` (NEW)
   - Create comprehensive troubleshooting guide
   - Cover jq errors, log routing issues, capture rate problems
   - Include diagnostic commands and common fixes

4. `/home/benjamin/.config/.claude/tests/test_bash_error_integration.sh`
   - Add inline comments explaining jq precedence fix
   - Document check_error_logged() return codes
   - Explain test environment setup

5. `/home/benjamin/.config/.claude/specs/872_test_failure_fix_coverage/reports/001_root_cause_analysis.md`
   - Update implementation status section
   - Link to this debug strategy plan
   - Mark as "Implementation In Progress"

### Documentation Standards
- Follow code-standards.md documentation policy (README in every directory)
- Use clear, concise language with code examples
- Include CommonMark-compliant markdown
- No emojis in file content (UTF-8 encoding issues)
- Document WHAT code does, not WHY design decisions were made

## Dependencies

### External Dependencies
- `jq` (version 1.5+) - JSON query tool (already installed)
- `bash` (version 4.0+) - Test script interpreter (already installed)

### Internal Dependencies
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error logging implementation (Phase 2 modification)
- `/home/benjamin/.config/.claude/tests/test_bash_error_integration.sh` - Integration test suite (Phase 1 & 3 modifications)
- `/home/benjamin/.config/.claude/data/logs/errors.jsonl` - Production error log (read-only)
- `/home/benjamin/.config/.claude/tests/logs/test-errors.jsonl` - Test error log (Phase 2 creation)

### Prerequisites
- Root cause analysis complete (✅ `/home/benjamin/.config/.claude/specs/872_test_failure_fix_coverage/reports/001_root_cause_analysis.md`)
- Test failure analysis complete (✅ `/home/benjamin/.config/.claude/specs/861_build_command_use_this_research_to_create_a/summaries/003_test_failure_analysis.md`)
- Plan 861 structurally complete (✅ ERR trap rollout finished)

## Risk Assessment

### Low Risk
- jq filter fix is isolated to test code (no production impact)
- Error logging implementation validated as correct
- Changes are backwards compatible

### Medium Risk
- Test environment variable might not be exported to subprocesses (mitigation: test thoroughly)
- Cleanup script might inadvertently delete production logs (mitigation: backup before delete)

### High Risk
- None identified (test-only changes)

## Rollback Plan

If fixes introduce regressions:

1. **Phase 1 Rollback**: Revert jq filter change using git
   ```bash
   git checkout HEAD -- .claude/tests/test_bash_error_integration.sh
   ```

2. **Phase 2 Rollback**: Remove `CLAUDE_TEST_MODE` check from error-handling.sh
   ```bash
   git checkout HEAD -- .claude/lib/core/error-handling.sh
   ```

3. **Phase 3 Rollback**: Remove enhanced diagnostics (test suite still functional with original logic)

4. **Phase 4 Rollback**: Documentation changes have no runtime impact (no rollback needed)

## Notes

- This debug strategy focuses exclusively on fixing test failures, not modifying error logging implementation
- All changes are test-focused with zero impact on production error handling
- Research analysis confirms error logging implementation is correct and working as designed
- Priority order optimized for fastest path to 100% test pass rate
- Phases 3-4 are quality improvements and can be deferred if time-constrained
