# Test Isolation Standards

## Overview

This document defines comprehensive test isolation standards for all test types in the .claude system. Proper test isolation prevents production directory pollution, ensures test reproducibility, and enables concurrent test execution.

## Purpose

Test isolation ensures that:
- Tests do not create directories or files in production locations
- Tests can run concurrently without interference
- Tests clean up all temporary resources on exit
- Test failures are reproducible and deterministic
- Production workflows are not affected by testing activities

## Environment Override Requirements

### CLAUDE_SPECS_ROOT Override Pattern

All tests that invoke location detection mechanisms MUST override `CLAUDE_SPECS_ROOT` to prevent production directory creation.

**Required Pattern**:

```bash
#!/bin/bash
# Test file header

# Set up isolated test environment
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"

# Run tests...
```

**Detection Point**: The `unified-location-detection.sh` library checks `CLAUDE_SPECS_ROOT` first (lines 103-108):

```bash
# Library checks in order:
# 1. CLAUDE_SPECS_ROOT (test override)
# 2. CLAUDE_PROJECT_DIR/.claude/specs
# 3. Git root detection
# 4. Upward directory search
```

**When Required**:
- Tests invoking `/plan`, `/coordinate`, `/orchestrate`, `/implement`
- Tests that call `get_specs_root()` from `unified-location-detection.sh`
- Integration tests that exercise full workflow commands
- Any test that might trigger topic allocation (Phase 0)

**Example Test Files** (demonstrating correct pattern):
- `.claude/tests/test_unified_location_detection.sh` (lines 23-27)
- `.claude/tests/test_unified_location_simple.sh` (lines 18-22)
- `.claude/tests/test_system_wide_location.sh` (lines 19-23)

### CLAUDE_PROJECT_DIR Override

For tests that need project root detection:

```bash
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
```

**When Required**:
- Tests validating project structure detection
- Tests requiring `.claude/` subdirectory presence
- Integration tests simulating full project environment

### Common Pitfalls

**Pitfall 1: Partial Isolation**

Setting only `CLAUDE_SPECS_ROOT` while leaving `CLAUDE_PROJECT_DIR` pointing to the real project causes production pollution. Some library functions (like `workflow-initialization.sh`) calculate paths from `project_root`, bypassing the `CLAUDE_SPECS_ROOT` override.

WRONG:
```bash
# Partial isolation - causes production pollution!
export CLAUDE_SPECS_ROOT="/tmp/test_$$"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"  # Points to real project
```

CORRECT:
```bash
# Complete isolation - both point to temp
TEST_ROOT="/tmp/test_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"
```

**Pitfall 2: Incomplete Cleanup Trap**

The cleanup trap must remove the entire test root, not just `CLAUDE_SPECS_ROOT`:

WRONG:
```bash
trap 'rm -rf "$CLAUDE_SPECS_ROOT"' EXIT  # Leaves other temp dirs
```

CORRECT:
```bash
trap 'rm -rf "$TEST_ROOT"' EXIT  # Removes everything
```

**Historical Context**: Empty directories 808-813 in `.claude/specs/` were created by `test_semantic_slug_commands.sh` due to Pitfall 1 (Plan 815 root cause analysis).

## Temporary Directory Standards

### mktemp Pattern

All tests MUST use `mktemp` for creating temporary directories:

```bash
#!/bin/bash

# Create temporary test root
TEST_ROOT="$(mktemp -d -t test_name.XXXXXX)"

# Set up test environment
export CLAUDE_SPECS_ROOT="$TEST_ROOT/specs"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Define cleanup function (see Cleanup Obligations section)
cleanup() {
    rm -rf "$TEST_ROOT"
}

# Register cleanup trap
trap cleanup EXIT

# Run tests...
```

**Key Requirements**:
- Use `-t` flag for template with unique suffix (`.XXXXXX`)
- Create subdirectories as needed (`mkdir -p`)
- Always register EXIT trap for cleanup
- Test name in template for debugging (e.g., `test_coordinate.XXXXXX`)

**Benefits**:
- Unique directory per test run (enables concurrent execution)
- Automatic cleanup on normal or abnormal exit
- Prevents test interference
- Clear test isolation boundaries

### Subdirectory Organization

Organize test temporary directories to mirror production structure:

```bash
TEST_ROOT="$(mktemp -d -t test_orchestration.XXXXXX)"

# Mirror production structure
mkdir -p "$TEST_ROOT/.claude/specs"
mkdir -p "$TEST_ROOT/.claude/lib"
mkdir -p "$TEST_ROOT/.claude/docs"

export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"
```

**When Required**:
- Integration tests requiring full project structure
- Tests validating cross-directory interactions
- Tests exercising file creation workflows

## Cleanup Obligations

### By Test Type

**Unit Tests** (testing isolated functions):
- Cleanup: Remove temporary files and directories
- Pattern: `trap cleanup EXIT` with `rm -rf "$TEST_ROOT"`
- Timing: Immediate (on test exit)

**Integration Tests** (testing command workflows):
- Cleanup: Remove all temporary directories, reset environment variables
- Pattern: Multi-step cleanup function
- Timing: After all assertions complete

**End-to-End Tests** (simulating full user workflows):
- Cleanup: Full teardown of test environment, validate no pollution
- Pattern: Comprehensive cleanup with validation
- Timing: After workflow completion verification

**Concurrent Tests** (running in parallel):
- Cleanup: Individual test cleanup + shared resource validation
- Pattern: Unique temporary directories with independent cleanup
- Timing: Per-test cleanup + post-suite validation

### Cleanup Function Template

```bash
cleanup() {
    local exit_code=$?

    # Remove test root
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi

    # Unset environment overrides
    unset CLAUDE_SPECS_ROOT
    unset CLAUDE_PROJECT_DIR

    # Restore any modified state
    # (add custom restoration logic here)

    exit $exit_code
}

trap cleanup EXIT
```

**Critical Requirements**:
- Preserve exit code for test result reporting
- Check variables are set before using (`[[ -n "$VAR" ]]`)
- Use `-rf` for recursive removal (handles subdirectories)
- Unset environment variables to prevent pollution
- Register trap BEFORE creating temporary resources

### Idempotency

Cleanup functions MUST be idempotent (safe to run multiple times):

```bash
cleanup() {
    # Check before removing
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"

    # Safe to unset even if not set
    unset CLAUDE_SPECS_ROOT
    unset CLAUDE_PROJECT_DIR
}
```

**Why Required**:
- Trap may fire multiple times (EXIT + ERR)
- Manual cleanup during debugging
- Ensures consistent final state

## Validation Requirements

### Empty Directory Detection

Tests MUST NOT create empty directories in production locations. Use validation to detect pollution:

```bash
# Pre-test state capture
BEFORE_COUNT=$(find .claude/specs -maxdepth 1 -type d -empty 2>/dev/null | wc -l)

# Run tests...

# Post-test validation
AFTER_COUNT=$(find .claude/specs -maxdepth 1 -type d -empty 2>/dev/null | wc -l)

if (( AFTER_COUNT > BEFORE_COUNT )); then
    echo "ERROR: Tests created empty directories"
    find .claude/specs -maxdepth 1 -type d -empty
    exit 1
fi
```

**Validation Points**:
- Before test suite execution (capture baseline)
- After test suite completion (detect pollution)
- In test runner (`run_all_tests.sh`)

**Example Implementation**: `.claude/tests/test_empty_directory_detection.sh` (lines 77-98)

### Production Directory Protection

Tests MUST verify they are NOT operating on production locations:

```bash
# Validate test isolation
if [[ "$CLAUDE_SPECS_ROOT" != /tmp/* ]]; then
    echo "ERROR: CLAUDE_SPECS_ROOT not isolated: $CLAUDE_SPECS_ROOT"
    exit 1
fi

if [[ "$CLAUDE_PROJECT_DIR" != /tmp/* ]]; then
    echo "ERROR: CLAUDE_PROJECT_DIR not isolated: $CLAUDE_PROJECT_DIR"
    exit 1
fi
```

**When Required**:
- At test initialization (before any operations)
- Before destructive operations (rm, cleanup)
- In test runner validation phase

### File Creation Validation

For tests that create files, validate they are in expected temporary locations:

```bash
# Create test file
echo "test content" > "$TEST_ROOT/test_file.txt"

# Validate location
if [[ ! -f "$TEST_ROOT/test_file.txt" ]]; then
    echo "ERROR: Test file not created in expected location"
    exit 1
fi

# Validate NOT in production
if [[ -f "$HOME/.config/.claude/test_file.txt" ]]; then
    echo "ERROR: Test file created in production location"
    exit 1
fi
```

## Concurrent Test Safety

### Atomic Allocation Pattern

Tests simulating topic allocation MUST use unique identifiers to prevent conflicts:

```bash
# Use $$ for process ID uniqueness
TEST_TOPIC_ID="999_test_topic_$$"
TEST_TOPIC_ROOT="$CLAUDE_SPECS_ROOT/$TEST_TOPIC_ID"

mkdir -p "$TEST_TOPIC_ROOT"

# Run test operations...

# Cleanup
rm -rf "$TEST_TOPIC_ROOT"
```

**Why Required**:
- Prevents race conditions in concurrent test execution
- Enables parallel test runs without interference
- Matches production atomic allocation behavior

### No Execution Order Assumptions

Tests MUST NOT assume execution order:

```bash
# WRONG: Assumes test_A runs before test_B
# test_A creates shared state, test_B uses it

# CORRECT: Each test creates its own state
setup_test_state() {
    # Create all required state within test
}
```

**Best Practices**:
- Independent test setup (no shared state)
- Unique temporary directories per test
- No dependencies between test files

### Shared Resource Management

If tests MUST share resources (rare):

```bash
# Use file-based locking
LOCK_FILE="/tmp/test_lock_${TEST_NAME}"

acquire_lock() {
    while ! mkdir "$LOCK_FILE" 2>/dev/null; do
        sleep 0.1
    done
}

release_lock() {
    rmdir "$LOCK_FILE" 2>/dev/null || true
}

# Acquire lock before shared resource access
acquire_lock
# ... use shared resource ...
release_lock
```

**When Required**:
- Tests accessing singleton resources (rare)
- Performance tests measuring system-wide impact
- Integration tests with external dependencies

## Anti-Patterns

### Production Directory Pollution

**WRONG**:
```bash
#!/bin/bash
# Test file WITHOUT isolation

# This creates directories in production!
/coordinate "test workflow"

# Empty directories left in .claude/specs/
```

**Correct**:
```bash
#!/bin/bash
# Test file WITH isolation

export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Cleanup trap
trap 'rm -rf /tmp/test_specs_$$ /tmp/test_project_$$' EXIT

# Now safe to run
/coordinate "test workflow"
```

### Missing Cleanup Traps

**WRONG**:
```bash
#!/bin/bash
TEST_ROOT="/tmp/test_data"
mkdir -p "$TEST_ROOT"

# Run tests...
# If test fails or is interrupted, TEST_ROOT persists!

# Manual cleanup (may not execute)
rm -rf "$TEST_ROOT"
```

**Correct**:
```bash
#!/bin/bash
TEST_ROOT="$(mktemp -d -t test_name.XXXXXX)"

# Register cleanup BEFORE creating resources
cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# Run tests...
# Cleanup ALWAYS executes
```

### Hardcoded Temporary Paths

**WRONG**:
```bash
# Hardcoded path conflicts in concurrent tests
TEST_ROOT="/tmp/my_test"
mkdir -p "$TEST_ROOT"
```

**Correct**:
```bash
# Unique path per test run
TEST_ROOT="$(mktemp -d -t my_test.XXXXXX)"
```

### Assuming Clean Initial State

**WRONG**:
```bash
# Assumes /tmp/test_dir doesn't exist
mkdir /tmp/test_dir
# Fails if directory already exists!
```

**Correct**:
```bash
# Create unique directory
TEST_DIR="$(mktemp -d -t test_dir.XXXXXX)"
# Always succeeds with unique path
```

### Incomplete Environment Restoration

**WRONG**:
```bash
# Sets variables but never unsets
export CLAUDE_SPECS_ROOT="/tmp/test"
# Variable persists after test, affects subsequent tests!
```

**Correct**:
```bash
export CLAUDE_SPECS_ROOT="/tmp/test_$$"

cleanup() {
    unset CLAUDE_SPECS_ROOT
    unset CLAUDE_PROJECT_DIR
}
trap cleanup EXIT
```

## Code Examples

### Complete Unit Test Template

```bash
#!/bin/bash
# test_example_unit.sh
# Unit test template demonstrating all isolation patterns

set -euo pipefail

# Test configuration
TEST_NAME="example_unit"
TEST_ROOT="$(mktemp -d -t "${TEST_NAME}.XXXXXX")"

# Environment isolation
export CLAUDE_SPECS_ROOT="$TEST_ROOT/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Create test structure
mkdir -p "$CLAUDE_SPECS_ROOT"
mkdir -p "$TEST_ROOT/.claude/lib"

# Cleanup function
cleanup() {
    local exit_code=$?

    # Remove temporary directory
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"

    # Unset environment variables
    unset CLAUDE_SPECS_ROOT
    unset CLAUDE_PROJECT_DIR

    exit $exit_code
}

# Register cleanup trap
trap cleanup EXIT

# Validate isolation
if [[ "$CLAUDE_SPECS_ROOT" != /tmp/* ]]; then
    echo "ERROR: Test not isolated"
    exit 1
fi

# Test assertions
echo "Running unit tests..."

# Example test
source .claude/lib/example-library.sh
result=$(example_function "test_input")

if [[ "$result" == "expected_output" ]]; then
    echo "✓ Test passed"
else
    echo "✗ Test failed: expected 'expected_output', got '$result'"
    exit 1
fi

echo "✓ All unit tests passed"
```

### Complete Integration Test Template

```bash
#!/bin/bash
# test_example_integration.sh
# Integration test template with workflow simulation

set -euo pipefail

# Test configuration
TEST_NAME="example_integration"
TEST_ROOT="$(mktemp -d -t "${TEST_NAME}.XXXXXX")"

# Environment isolation
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"
export PATH="$TEST_ROOT/.claude/scripts:$PATH"

# Create test project structure
mkdir -p "$CLAUDE_SPECS_ROOT"
mkdir -p "$TEST_ROOT/.claude/lib"
mkdir -p "$TEST_ROOT/.claude/scripts"
mkdir -p "$TEST_ROOT/.claude/commands"

# Copy required libraries
cp -r .claude/lib/* "$TEST_ROOT/.claude/lib/"

# Cleanup function
cleanup() {
    local exit_code=$?

    # Validation before cleanup
    local empty_dirs=$(find "$CLAUDE_SPECS_ROOT" -maxdepth 1 -type d -empty 2>/dev/null | wc -l)
    if (( empty_dirs > 0 )); then
        echo "WARNING: Test created empty directories"
        find "$CLAUDE_SPECS_ROOT" -maxdepth 1 -type d -empty
    fi

    # Remove temporary directory
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"

    # Unset environment variables
    unset CLAUDE_SPECS_ROOT
    unset CLAUDE_PROJECT_DIR

    exit $exit_code
}

trap cleanup EXIT

# Validate isolation
if [[ "$CLAUDE_SPECS_ROOT" != /tmp/* ]]; then
    echo "ERROR: Test not isolated: $CLAUDE_SPECS_ROOT"
    exit 1
fi

# Run integration test
echo "Running integration tests..."

# Example: Test workflow command
cd "$TEST_ROOT"
/coordinate "test workflow" > /tmp/test_output_$$.txt 2>&1

# Validate results
if grep -q "SUCCESS" /tmp/test_output_$$.txt; then
    echo "✓ Integration test passed"
else
    echo "✗ Integration test failed"
    cat /tmp/test_output_$$.txt
    exit 1
fi

# Cleanup command output
rm -f /tmp/test_output_$$.txt

echo "✓ All integration tests passed"
```

### Concurrent Test Example

```bash
#!/bin/bash
# test_example_concurrent.sh
# Concurrent test demonstrating unique resource allocation

set -euo pipefail

# Unique test identifier using PID
TEST_NAME="example_concurrent_$$"
TEST_ROOT="$(mktemp -d -t "${TEST_NAME}.XXXXXX")"

# Environment isolation with unique paths
export CLAUDE_SPECS_ROOT="$TEST_ROOT/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

mkdir -p "$CLAUDE_SPECS_ROOT"

# Cleanup function
cleanup() {
    rm -rf "$TEST_ROOT"
    unset CLAUDE_SPECS_ROOT
    unset CLAUDE_PROJECT_DIR
}
trap cleanup EXIT

# Run test with unique resource identifiers
echo "Running concurrent test instance $$..."

# Create unique test topic
TEST_TOPIC_ID="999_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT/$TEST_TOPIC_ID"

# Run test operations (safe to run in parallel)
echo "test data" > "$CLAUDE_SPECS_ROOT/$TEST_TOPIC_ID/test_file.txt"

# Validate
if [[ -f "$CLAUDE_SPECS_ROOT/$TEST_TOPIC_ID/test_file.txt" ]]; then
    echo "✓ Concurrent test $$ passed"
else
    echo "✗ Concurrent test $$ failed"
    exit 1
fi

# Cleanup happens automatically via trap
```

## Reference Test Files

### Demonstrating Correct Patterns

The following test files demonstrate proper isolation patterns:

**Environment Override Pattern**:
- `.claude/tests/test_unified_location_detection.sh` (lines 23-27)
- `.claude/tests/test_unified_location_simple.sh` (lines 18-22)
- `.claude/tests/test_system_wide_location.sh` (lines 19-23)

**mktemp + Trap Pattern** (30+ test files):
- `.claude/tests/test_parsing_utilities.sh`
- `.claude/tests/test_command_integration.sh`
- `.claude/tests/test_progressive_expansion.sh`
- `.claude/tests/test_state_management.sh`
- `.claude/tests/test_shared_utilities.sh`

**Empty Directory Validation**:
- `.claude/tests/test_empty_directory_detection.sh` (lines 77-98)

**Concurrent Safety**:
- `.claude/tests/test_concurrent_allocation.sh` (uses $$-based unique IDs)

## Compliance Checklist

Use this checklist to verify test isolation compliance:

- [ ] Test uses `mktemp` for temporary directory creation
- [ ] Test sets `CLAUDE_SPECS_ROOT` to `/tmp` location
- [ ] Test sets `CLAUDE_PROJECT_DIR` to `/tmp` location (if needed)
- [ ] Test registers `trap cleanup EXIT` before creating resources
- [ ] Cleanup function removes all temporary directories
- [ ] Cleanup function unsets environment variables
- [ ] Cleanup function is idempotent
- [ ] Test validates isolation before operations
- [ ] Test uses unique identifiers for concurrent safety ($$)
- [ ] Test does not assume execution order
- [ ] Test does not create files in production locations
- [ ] Test includes empty directory validation (for workflow tests)

## Enforcement

### Automated Validation

The test runner (`.claude/tests/run_all_tests.sh`) enforces isolation standards:

1. **Pre-test validation**: Captures baseline empty directory count
2. **Post-test validation**: Detects any new empty directories
3. **Failure reporting**: Lists pollution with directory paths
4. **Exit code**: Returns 1 if pollution detected

### Manual Testing Best Practices

When running commands manually for testing:

```bash
# ALWAYS set CLAUDE_SPECS_ROOT for manual testing
export CLAUDE_SPECS_ROOT="/tmp/manual_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Run command
/coordinate "test workflow"

# Cleanup after testing
rm -rf "/tmp/manual_test_$$"
unset CLAUDE_SPECS_ROOT
```

**Why Required**:
- Prevents production directory pollution during development
- Enables safe experimentation without cleanup burden
- Matches automated test environment

## See Also

- [Testing Protocols](../../CLAUDE.md#testing_protocols) - Project-level testing standards
- [Library API Reference](library-api.md) - Location detection library documentation
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Command testing requirements
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Agent testing patterns

## Revision History

- **2025-11-14**: Initial version documenting test isolation patterns and standards (Spec 713)
