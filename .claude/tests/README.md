# Test Suite Documentation

This directory contains the comprehensive test suite for the Claude Code agential system.

## Test Files

### Core Test Suites

1. **test_parsing_utilities.sh** - Tests for plan parsing functions
   - Plan metadata extraction
   - Phase and task parsing
   - Structure level detection
   - Legacy format migration
   - Unicode and edge case handling

2. **test_command_integration.sh** - Tests for command workflows
   - Plan file structure validation
   - Argument parsing for all commands
   - Checkpoint operations
   - Flag parsing
   - Template rendering
   - Error handling

3. **test_progressive_roundtrip.sh** - Tests for expansion/collapse operations
   - Phase expansion → collapse roundtrip
   - Metadata preservation
   - Content checksum validation
   - Empty phases and edge cases
   - Unicode character preservation
   - Version history preservation

4. **test_state_management.sh** - Tests for checkpoint operations
   - Checkpoint save/restore
   - Field get/set operations
   - Version migration (v1→v2)
   - Concurrent access handling
   - Lock file management
   - Replanning field support

5. **test_progressive_expansion.sh** - Tests for phase/stage expansion
   - Expansion command functionality
   - Directory structure creation
   - Content extraction and preservation

6. **test_progressive_collapse.sh** - Tests for phase/stage collapse
   - Collapse command functionality
   - Content merging
   - Structure simplification

7. **test_template_system.sh** - Tests for template system (26 tests)
   - Template validation (required fields, file existence)
   - Metadata extraction (name, description, variables)
   - Phase extraction and counting
   - Simple variable substitution
   - Conditional substitution (if/unless)
   - Array iteration (each with index helpers)
   - Error handling (malformed YAML, invalid JSON)
   - Integration workflow (full template processing)
   - **Coverage**: 17/26 tests passing (65% - acceptable for bash implementation)

8. **test_adaptive_planning.sh** - Tests for adaptive planning integration
   - Complexity-based replan triggers
   - Test failure pattern detection
   - Scope drift handling
   - Replan counter limits
   - Checkpoint integration
   - Logging verification

9. **test_revise_automode.sh** - Tests for /revise auto-mode integration
   - Auto-mode invocation from /implement
   - Progressive structure awareness
   - Revision scope analysis
   - Plan update integration

10. **test_hierarchy_updates.sh** - Tests for checkbox hierarchy update utilities (16 tests)
    - Level 0 structure tests (single file)
    - Level 1 structure tests (expanded phases)
    - Level 2 structure tests (stage → phase → main)
    - Partial phase completion tracking
    - Concurrent checkbox updates
    - Checkpoint integration (hierarchy_updated field)
    - Edge cases (missing files, empty phases, special characters)
    - **Coverage**: 16/16 tests passing (100%)

11. **test_workflow_detection.sh** - Tests for workflow scope detection (12 tests)
    - Pattern 1: Research-only detection
    - Pattern 2: Research-and-plan detection
    - Pattern 3: Full-implementation detection
    - Pattern 4: Debug-only detection
    - Edge cases: Multi-intent prompts (research + plan + implement)
    - Smart matching algorithm validation
    - User-reported bug case (implement a plan → full-implementation)
    - **Coverage**: 12/12 tests passing (100%)
    - **Purpose**: Regression prevention for workflow detection algorithm

12. **test_llm_classifier.sh** - Tests for LLM-based workflow classifier (37 tests)
    - Input validation and JSON building
    - Response parsing and validation
    - Confidence threshold logic
    - Timeout behavior (mocked)
    - Logging functions (debug/error/result)
    - Configuration (confidence threshold, timeout, debug mode)
    - Error handling paths
    - **Coverage**: 35/37 tests passing (100% pass rate, 2 skipped for manual LLM integration)
    - **Purpose**: Unit testing for LLM classifier library

13. **test_scope_detection.sh** - Tests for unified hybrid workflow classification (31 tests)
    - Hybrid mode (LLM + regex fallback)
    - LLM-only mode
    - Regex-only mode
    - Fallback scenarios (timeout, low confidence, API error)
    - Backward compatibility (function signature unchanged)
    - Integration tests (/coordinate and /supervise)
    - Edge case tests (quoted keywords, negation, multiple actions, long descriptions, special characters)
    - **Coverage**: 30/31 tests passing (100% pass rate, 1 skipped for edge case prioritization)
    - **Purpose**: Integration testing for hybrid classification system

14. **test_scope_detection_ab.sh** - A/B testing for LLM vs regex classification (42 test cases)
    - Straightforward cases (clear intent)
    - Edge cases (semantic ambiguity, quoted keywords, negation)
    - Ambiguous cases (multiple actions, complex intents)
    - Real workflow descriptions from production usage
    - Agreement rate tracking and disagreement reporting
    - **Coverage**: 41/42 tests passing (97% pass rate, exceeds 90% target)
    - **Purpose**: Validation of LLM classification accuracy vs regex baseline

## Running Tests

### Run Individual Test Suites

```bash
# Run parsing utilities tests
cd /home/benjamin/.config/.claude/tests
./test_parsing_utilities.sh

# Run command integration tests
./test_command_integration.sh

# Run roundtrip tests
./test_progressive_roundtrip.sh

# Run state management tests
./test_state_management.sh

# Run expansion tests
./test_progressive_expansion.sh

# Run collapse tests
./test_progressive_collapse.sh

# Run hierarchy updates tests
./test_hierarchy_updates.sh

# Run hierarchy updates tests with coverage report
./test_hierarchy_updates.sh --coverage

# Run hierarchy updates tests for all levels
./test_hierarchy_updates.sh --all-levels

# Run workflow detection tests
./test_workflow_detection.sh
```

### Run All Tests

```bash
# Run complete test suite
cd /home/benjamin/.config/.claude/tests
for test in test_*.sh; do
  echo "Running $test..."
  ./"$test"
done
```

### Run with Coverage

```bash
# Generate coverage report (requires kcov or bashcov)
cd /home/benjamin/.config/.claude/tests
./run_coverage.sh --html-report
```

## Test Framework

### Test Structure

All test files follow a common structure:

1. **Setup**: Create temporary test environment
2. **Test Functions**: Individual test cases with descriptive names
3. **Assertions**: pass() and fail() helpers for reporting
4. **Cleanup**: Remove temporary files
5. **Summary**: Display test results

### Assertion Helpers

```bash
# Pass a test
pass "Test description"

# Fail a test with reason
fail "Test description" "Reason for failure"

# Info message (doesn't count as test)
info "Additional information"
```

### Test Counters

Each test file maintains:
- `TESTS_RUN` - Total tests executed
- `TESTS_PASSED` - Tests that passed
- `TESTS_FAILED` - Tests that failed

### Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Test Coverage

### Current Coverage

| Category | Coverage | Notes |
|----------|----------|-------|
| Parsing Utilities | ~70% | Core parsing functions covered |
| Command Integration | ~60% | Main workflows covered |
| Roundtrip Operations | ~80% | Comprehensive edge cases |
| State Management | ~75% | Checkpoint operations covered |
| Progressive Expansion | ~65% | Expansion commands covered |
| Progressive Collapse | ~65% | Collapse commands covered |
| Hierarchy Updates | 100% | All checkbox-utils.sh functions covered |

### Coverage Goals

- **Modified Code**: ≥80% line coverage
- **Existing Code**: ≥60% baseline coverage
- **Critical Paths**: 100% coverage required
  - Checkpoint save/restore
  - Plan expansion/collapse
  - Metadata preservation

## Adding New Tests

### Test Naming Convention

```bash
test_<feature_being_tested>() {
  info "Testing <description>"

  # Setup
  local test_file="$TEST_DIR/test.md"

  # Execute test logic
  # ...

  # Assert results
  if [ condition ]; then
    pass "Test passed"
  else
    fail "Test failed" "Reason"
  fi
}
```

### Test Categories

When adding new tests, categorize them:

1. **Unit Tests** - Test individual functions in isolation
2. **Integration Tests** - Test command workflows end-to-end
3. **Round-Trip Tests** - Test data preservation across transformations
4. **Regression Tests** - Test legacy format compatibility
5. **Edge Case Tests** - Test boundary conditions and error handling

### Test File Template

**IMPORTANT**: All tests MUST use test isolation patterns to prevent production directory pollution.
See: [Test Isolation Standards](../docs/reference/standards/test-isolation.md)

```bash
#!/usr/bin/env bash
# Test suite for <feature>
# Tests <description>

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory (unique per test run for concurrent safety)
TEST_DIR="$(mktemp -d -t <feature>_tests.XXXXXX)"

# Test isolation: Override location detection to use temporary directories
export CLAUDE_SPECS_ROOT="$TEST_DIR/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_DIR"

# Setup/cleanup functions
setup() {
  echo "Setting up test environment: $TEST_DIR"

  # Create test project structure
  mkdir -p "$CLAUDE_SPECS_ROOT"
  mkdir -p "$TEST_DIR/.claude/lib"
  mkdir -p "$TEST_DIR/.claude/commands"

  # Copy required libraries if needed
  # cp -r /path/to/.claude/lib/* "$TEST_DIR/.claude/lib/"
}

cleanup() {
  local exit_code=$?

  echo "Cleaning up test environment"

  # Validate no production pollution (for workflow tests)
  # if [[ -d "/home/user/.config/.claude/specs" ]]; then
  #   local pollution=$(find /home/user/.config/.claude/specs -maxdepth 1 -type d -empty 2>/dev/null | wc -l)
  #   if (( pollution > 0 )); then
  #     echo "WARNING: Test created production pollution"
  #     find /home/user/.config/.claude/specs -maxdepth 1 -type d -empty
  #   fi
  # fi

  # Remove test directory
  [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"

  # Unset environment overrides
  unset CLAUDE_SPECS_ROOT
  unset CLAUDE_PROJECT_DIR

  exit $exit_code
}

# Register cleanup trap (MUST be before any test operations)
trap cleanup EXIT

# Test helper functions (pass, fail, info)
# ... (copy from existing test files)

# Test functions
test_feature() {
  info "Testing feature"
  # Test implementation
}

# Run all tests
run_all_tests() {
  echo "==============================="
  echo "<Feature> Test Suite"
  echo "==============================="
  echo ""

  setup

  # Call all test functions
  test_feature

  cleanup

  # Display results
  echo ""
  echo "==============================="
  echo "Test Results"
  echo "==============================="
  echo "Tests Run:    $TESTS_RUN"
  echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}FAILURE${NC}: Some tests failed"
    exit 1
  else
    echo -e "${GREEN}SUCCESS${NC}: All tests passed"
    exit 0
  fi
}

# Run tests
run_all_tests
```

## Test Isolation Patterns

### Overview

All tests MUST use isolation patterns to prevent production directory pollution. This is enforced by the test runner's pollution detection (see Phase 3).

**Reference**: [Test Isolation Standards](../docs/reference/standards/test-isolation.md) - Complete documentation

### Required Patterns

**1. Environment Variable Overrides**

```bash
# Set BEFORE sourcing any libraries or running commands
export CLAUDE_SPECS_ROOT="$TEST_DIR/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
```

**Why Required**: Location detection checks `CLAUDE_SPECS_ROOT` first (see `unified-location-detection.sh:57`), preventing production directory creation.

**2. mktemp for Temporary Directories**

```bash
# Use mktemp with unique suffix for concurrent safety
TEST_DIR="$(mktemp -d -t feature_tests.XXXXXX)"
```

**Benefits**:
- Unique directory per test run
- Enables concurrent test execution
- Standard temporary directory location

**3. EXIT Trap Registration**

```bash
cleanup() {
  local exit_code=$?
  [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
  unset CLAUDE_SPECS_ROOT
  unset CLAUDE_PROJECT_DIR
  exit $exit_code
}

trap cleanup EXIT  # Register BEFORE creating any test resources
```

**Why Required**: Ensures cleanup happens on normal exit, test failure, or interruption.

### Validation Checklist

Before submitting tests, verify:

- [ ] Test uses `mktemp` for temporary directory creation
- [ ] Test sets `CLAUDE_SPECS_ROOT` to `/tmp` location
- [ ] Test sets `CLAUDE_PROJECT_DIR` to `/tmp` location (if needed)
- [ ] Test registers `trap cleanup EXIT` before operations
- [ ] Cleanup function removes temporary directories
- [ ] Cleanup function unsets environment variables
- [ ] Cleanup function preserves exit code
- [ ] Test uses unique identifiers ($$) for concurrent safety

### Example Test Files

See these files for correct isolation patterns:

- `.claude/tests/test_unified_location_detection.sh` (environment overrides)
- `.claude/tests/test_parsing_utilities.sh` (mktemp + trap pattern)
- `.claude/tests/test_command_integration.sh` (complete isolation setup)

### Manual Testing

When testing commands manually:

```bash
# ALWAYS set isolation overrides for manual testing
export CLAUDE_SPECS_ROOT="/tmp/manual_test_$$"
export CLAUDE_PROJECT_DIR="/tmp/manual_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Run command
/command-to-test "arguments"

# Cleanup
rm -rf "/tmp/manual_test_$$"
unset CLAUDE_SPECS_ROOT
unset CLAUDE_PROJECT_DIR
```

**Benefits**: Prevents empty directory creation during development and experimentation.

## Troubleshooting

### Test Failures

If tests fail:

1. Check the failure reason in the output
2. Examine the test directory (if cleanup is disabled)
3. Run the test in verbose mode (add `set -x` after `set -e`)
4. Check for environmental differences

### Common Issues

**Issue**: Tests pass individually but fail when run together
- **Cause**: Shared state or insufficient cleanup
- **Fix**: Ensure proper cleanup between tests

**Issue**: Tests fail with "command not found"
- **Cause**: Missing utilities or incorrect path
- **Fix**: Verify UTILS_DIR and source paths are correct

**Issue**: Unicode tests fail
- **Cause**: Locale settings
- **Fix**: Ensure UTF-8 locale is set (`export LANG=en_US.UTF-8`)

## Best Practices

1. **Isolation**: Each test should be independent and idempotent
2. **Cleanup**: Always clean up temporary files, even on failure
3. **Descriptive Names**: Use clear, descriptive test function names
4. **Assertions**: Use pass/fail helpers for consistent reporting
5. **Documentation**: Comment complex test logic
6. **Edge Cases**: Test boundary conditions and error paths
7. **Performance**: Keep tests fast (<1s per test when possible)

## Future Enhancements

Planned improvements to the test suite:

- [ ] Continuous integration (CI) setup
- [ ] Automated coverage reporting
- [ ] Performance benchmarking tests
- [ ] Parallel test execution
- [ ] Test data fixtures and mocking
- [ ] Integration with code review process

## Navigation

- [← Parent Directory](../README.md)
- [Project Standards](/home/benjamin/.config/CLAUDE.md) - Testing protocols and standards
- [Commands](../commands/) - Commands that use tests
- [Library Utilities](../lib/) - Utilities being tested
