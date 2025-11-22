# Test Execution Report

## Metadata
- **Date**: 2025-11-21 00:56:33
- **Plan**: /home/benjamin/.config/.claude/specs/908_plan_error_analysis/plans/001_plan_error_analysis_fix_plan.md
- **Test Framework**: bash-tests
- **Test Command**: bash .claude/tests/unit/test_benign_error_filter.sh && bash .claude/tests/unit/test_source_libraries_inline_error_logging.sh
- **Exit Code**: 0
- **Execution Time**: 5s
- **Environment**: test

## Summary
- **Total Tests**: 22
- **Passed**: 22
- **Failed**: 0
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

None - all tests passed.

## Full Output

### Test 1: test_benign_error_filter.sh

```bash
=== Benign Error Filter Unit Tests ===

--- Bashrc sourcing commands (should be filtered) ---
PASS: Direct bashrc source
PASS: Source bashrc explicit
PASS: Tilde bashrc
PASS: Relative bashrc
PASS: Bash.bashrc path

--- Exit 127 with system init patterns (should be filtered) ---
PASS: Bashrc exit 127
PASS: Profile exit 127
PASS: Bash completion 127

--- Non-bashrc commands (should NOT be filtered) ---
PASS: Regular command exit 1
PASS: Unknown command 127
PASS: User script failure
PASS: Append workflow state

--- Return statements (outside library context - NOT filtered) ---
PASS: Return 1 outside lib
PASS: Return 0 outside lib

--- Edge cases ---
PASS: Empty command
PASS: Exit code 0

=== Results ===
Passed: 16
Failed: 0
All tests passed!
```

### Test 2: test_source_libraries_inline_error_logging.sh

```bash
==================================================
Testing source-libraries-inline.sh Error Logging
==================================================

Test 1: Error log directory setup
  PASS: Test logs directory exists

Test 2: log_command_error writes to test error log
  PASS: dependency_error logged to test error log

Test 3: Error log entry has correct JSONL structure
  PASS: Error log entry has all required fields

Test 4: Error context contains function and library metadata
  PASS: Context contains function and library metadata

Test 5: Error log environment is 'test'
  PASS: Environment correctly set to 'test'

Test 6: workflow_id pattern matching routes test_* to test log
  PASS: workflow_id pattern test_* routes to test log

==================================================
Test Summary
==================================================
Tests run:    6
Tests passed: 6
Tests failed: 0

All tests passed!
```
