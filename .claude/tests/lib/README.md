# Test Helper Library

Shared test helper functions providing standardized output patterns for all tests in the .claude/tests/ directory.

## Purpose

This library ensures consistent test output across all test files, enabling the test runner (`run_all_tests.sh`) to accurately count and report test results. All tests should source this library for pass/fail/skip reporting.

## Usage

```bash
#!/usr/bin/env bash
# Source test helpers (handle multiple directory levels)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || \
  source "${SCRIPT_DIR}/../../lib/test-helpers.sh" 2>/dev/null || \
  { echo "Cannot load test helpers"; exit 1; }

# Initialize counters at start
setup_test

# Run your tests
assert_equals "expected" "actual" "test_comparison"
assert_file_exists "/path/to/file" "test_file_check"

if some_condition; then
  pass "test_condition_check"
else
  fail "test_condition_check"
fi

# Report summary at end
teardown_test
```

## API Reference

### Core Output Functions

| Function | Description | Usage |
|----------|-------------|-------|
| `pass "name"` | Mark test as passed (prints green checkmark) | `pass "my_test"` |
| `fail "name" ["msg"]` | Mark test as failed (returns 1) | `fail "my_test" "reason"` |
| `skip "name" ["reason"]` | Mark test as skipped | `skip "my_test" "not supported"` |

### Assertion Functions

| Function | Description | Usage |
|----------|-------------|-------|
| `assert_equals expected actual "name"` | Compare two values | `assert_equals "foo" "$result" "test_foo"` |
| `assert_contains needle haystack "name"` | Check substring | `assert_contains "error" "$output" "test_err"` |
| `assert_file_exists path "name"` | Check file exists | `assert_file_exists "/tmp/test.txt" "test_file"` |
| `assert_dir_exists path "name"` | Check directory exists | `assert_dir_exists "/tmp/dir" "test_dir"` |
| `assert_not_empty value "name"` | Check value is non-empty | `assert_not_empty "$var" "test_var"` |
| `assert_empty value "name"` | Check value is empty | `assert_empty "$var" "test_empty"` |
| `assert_success "cmd" "name"` | Check command exits 0 | `assert_success "ls /tmp" "test_ls"` |
| `assert_failure "cmd" "name"` | Check command exits non-0 | `assert_failure "false" "test_false"` |
| `assert_greater_than val thresh "name"` | Numeric comparison | `assert_greater_than 5 3 "test_gt"` |
| `assert_less_than val thresh "name"` | Numeric comparison | `assert_less_than 3 5 "test_lt"` |

### Lifecycle Functions

| Function | Description | Usage |
|----------|-------------|-------|
| `setup_test` | Initialize counters (call at start) | `setup_test` |
| `teardown_test` | Report summary (call at end) | `teardown_test` |
| `run_test func_name` | Run a test function safely | `run_test test_my_feature` |

### Utility Functions

| Function | Description | Usage |
|----------|-------------|-------|
| `debug_log "msg"` | Print debug message (if DEBUG=1) | `debug_log "checking value"` |

## Output Format

The library produces standardized output that the test runner recognizes:

```
Testing: my_test_file.sh
----------------------------------------
[checkmark] PASS: test_basic_function
[checkmark] PASS: test_edge_case
[X] FAIL: test_broken - Expected 'foo', got 'bar'
[circle-slash] SKIP: test_optional - requires Python

----------------------------------------
Test Summary: 4 total
  Passed:  2
  Failed:  1
  Skipped: 1

Failed tests:
  - test_broken
----------------------------------------
```

## Environment Variables

- `NO_COLOR`: Disable colored output when set
- `DEBUG`: Show debug messages when set to "1"

## Counter Variables

After `teardown_test`, these variables contain the results:

- `TESTS_PASSED`: Count of passing tests
- `TESTS_FAILED`: Count of failing tests
- `TESTS_SKIPPED`: Count of skipped tests
- `FAILED_TESTS`: Array of failed test names

## Best Practices

1. Always call `setup_test` at the beginning
2. Always call `teardown_test` at the end
3. Use descriptive test names (snake_case recommended)
4. Use assertion functions for cleaner code
5. Use `fail` with a message for debugging
6. Use `skip` for optional/conditional tests

## Migration Guide

To migrate existing tests to use test-helpers.sh:

```bash
# Before (non-standard):
echo "PASS: my_test"

# After (standardized):
pass "my_test"

# Before (non-standard):
echo -e "\033[32mPASS\033[0m: my_test"

# After (standardized):
pass "my_test"

# Before (manual assertion):
if [[ "$result" == "expected" ]]; then
  echo "PASS: test_result"
else
  echo "FAIL: test_result"
fi

# After (using assert):
assert_equals "expected" "$result" "test_result"
```

## Files

- `test-helpers.sh` - Main helper library (this file documents)
- `README.md` - This documentation

## Integration with Test Runner

The test runner (`run_all_tests.sh`) counts tests by grepping for:
- `[checkmark] PASS` pattern (from `pass` function)
- `[X] FAIL` pattern (from `fail` function)

Using this library ensures accurate test counts.
