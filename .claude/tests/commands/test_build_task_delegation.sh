#!/usr/bin/env bash
# Test: /build command Task delegation verification
# Validates that implementer-coordinator is invoked via Task tool
# Updated: Tests consolidated block structure (Block 1: Setup + Execute + Verify)

set -uo pipefail

# Test configuration
TEST_NAME="build_task_delegation"
TEST_DIR="/tmp/test_${TEST_NAME}_$$"
PLAN_NAME="test_build_delegation_plan"

# Setup test environment
setup_test() {
    echo "Setting up test environment..."
    mkdir -p "$TEST_DIR"/{plans,summaries}

    # Create minimal test plan
    cat > "$TEST_DIR/plans/${PLAN_NAME}.md" <<'EOF'
# Test Build Delegation Plan

## Metadata
- Complexity: 50
- Structure Level: 0

## Phase 1: Foundation [NOT STARTED]

**Objective**: Basic setup

**Tasks**:
- [ ] Task 1: Create test file
- [ ] Task 2: Verify creation

**Testing**:
```bash
# Simple test
echo "Test complete"
```

**Expected Duration**: 1 hour
EOF
}

# Test 1: Verify Task invocation occurs
test_task_invocation() {
    echo "Test 1: Verifying Task tool is invoked..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    # Check for Task invocation for implementer-coordinator
    if ! grep -q "Task {" "$build_cmd"; then
        echo "FAIL: No Task invocation found in /build"
        return 1
    fi

    # Check for implementer-coordinator reference
    if ! grep -q "implementer-coordinator" "$build_cmd"; then
        echo "FAIL: implementer-coordinator not referenced in Task"
        return 1
    fi

    echo "PASS: Task invocation pattern found for implementer-coordinator"
    return 0
}

# Test 2: Verify inline verification exists (consolidated structure)
test_verification_block() {
    echo "Test 2: Verifying inline verification after Task..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    # Check for consolidated block structure (Block 1: Setup + Execute + Verify)
    if ! grep -q "Block 1.*Setup.*Execute.*Verify" "$build_cmd"; then
        echo "FAIL: Consolidated block structure not found"
        return 1
    fi

    # Check for inline verification marker
    if ! grep -q "INLINE VERIFICATION" "$build_cmd"; then
        echo "FAIL: Inline verification marker not found"
        return 1
    fi

    # Check for summary verification
    if ! grep -q "SUMMARIES_DIR" "$build_cmd"; then
        echo "FAIL: SUMMARIES_DIR verification not found"
        return 1
    fi

    # Check for fail-fast exit
    if ! grep -q "exit 1" "$build_cmd"; then
        echo "FAIL: Fail-fast exit not found in verification"
        return 1
    fi

    echo "PASS: Inline verification exists with fail-fast checks"
    return 0
}

# Test 3: Verify barrier-utils.sh is sourced
test_barrier_utils_sourcing() {
    echo "Test 3: Verifying barrier-utils.sh library sourcing..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    if ! grep -q "barrier-utils.sh" "$build_cmd"; then
        echo "FAIL: barrier-utils.sh not sourced in /build"
        return 1
    fi

    echo "PASS: barrier-utils.sh library sourced"
    return 0
}

# Test 4: Verify checkpoint reporting
test_checkpoint_reporting() {
    echo "Test 4: Verifying checkpoint reporting..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    # Check for checkpoint-related functionality (utils or echo statements)
    if ! grep -q "checkpoint" "$build_cmd"; then
        echo "FAIL: Checkpoint mechanism not found"
        return 1
    fi

    # Check for echo statements that report progress
    if ! grep -q "echo.*Implementation" "$build_cmd"; then
        echo "FAIL: Progress reporting not found"
        return 1
    fi

    echo "PASS: Checkpoint/progress reporting implemented"
    return 0
}

# Cleanup
cleanup_test() {
    echo "Cleaning up test environment..."
    rm -rf "$TEST_DIR"
}

# Run all tests
main() {
    echo "==================================="
    echo "Test Suite: /build Task Delegation"
    echo "==================================="

    setup_test

    local tests_passed=0
    local tests_failed=0

    # Run tests
    if test_task_invocation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    if test_verification_block; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    if test_barrier_utils_sourcing; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    if test_checkpoint_reporting; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    cleanup_test

    # Summary
    echo ""
    echo "==================================="
    echo "Test Results"
    echo "==================================="
    echo "Passed: $tests_passed"
    echo "Failed: $tests_failed"
    echo "Total:  $((tests_passed + tests_failed))"

    if [ "$tests_failed" -eq 0 ]; then
        echo ""
        echo "✓ All tests passed!"
        return 0
    else
        echo ""
        echo "✗ Some tests failed"
        return 1
    fi
}

# Execute
main "$@"
