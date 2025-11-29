#!/usr/bin/env bash
# Test: /build iteration with barriers and checkpoint persistence
# Validates iteration logic respects hard barriers

set -uo pipefail

# Test configuration
TEST_NAME="build_iteration_barriers"
TEST_DIR="/tmp/test_${TEST_NAME}_$$"

# Setup test environment
setup_test() {
    echo "Setting up test environment..."
    mkdir -p "$TEST_DIR"

    # Note: Full iteration testing requires actual /build execution
    # This test focuses on verifying the iteration detection logic
}

# Test 1: Verify iteration continuation logic exists
test_iteration_continuation() {
    echo "Test 1: Verifying iteration continuation logic..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    # Check for work_remaining parsing
    if ! grep -q "work_remaining" "$build_cmd"; then
        echo "FAIL: work_remaining not found in /build"
        return 1
    fi

    # Check for ITERATION variable
    if ! grep -q "ITERATION" "$build_cmd"; then
        echo "FAIL: ITERATION tracking not found"
        return 1
    fi

    echo "PASS: Iteration continuation logic present"
    return 0
}

# Test 2: Verify iteration check happens AFTER verification
test_iteration_after_verification() {
    echo "Test 2: Verifying iteration check after verification block..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    # Extract line numbers
    local verify_line=$(grep -n "Block 1c: Implementation Verification" "$build_cmd" | head -1 | cut -d: -f1)
    # Look for the actual iteration check logic (after verification)
    local iteration_line=$(grep -n "# Check for work_remaining signal" "$build_cmd" | head -1 | cut -d: -f1)

    if [ -z "$verify_line" ]; then
        echo "FAIL: Could not find verification block"
        return 1
    fi

    if [ -z "$iteration_line" ]; then
        # Fallback: any work_remaining reference after the verification line
        iteration_line=$(awk -v verify="$verify_line" -F: '$1 > verify && /work_remaining/ {print $1; exit}' <(grep -n "work_remaining" "$build_cmd"))
    fi

    if [ -z "$iteration_line" ]; then
        echo "FAIL: Could not find iteration/work_remaining logic"
        return 1
    fi

    if [ "$iteration_line" -le "$verify_line" ]; then
        echo "FAIL: Iteration check happens BEFORE verification (line $iteration_line <= $verify_line)"
        return 1
    fi

    echo "PASS: Iteration check happens after verification (line $iteration_line > $verify_line)"
    return 0
}

# Test 3: Verify checkpoint persistence variables
test_checkpoint_persistence() {
    echo "Test 3: Verifying checkpoint persistence..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    # Check for LATEST_SUMMARY persistence
    if ! grep -q "LATEST_SUMMARY" "$build_cmd"; then
        echo "FAIL: LATEST_SUMMARY not persisted"
        return 1
    fi

    # Check for SUMMARY_COUNT persistence
    if ! grep -q "SUMMARY_COUNT" "$build_cmd"; then
        echo "FAIL: SUMMARY_COUNT not persisted"
        return 1
    fi

    echo "PASS: Checkpoint variables persisted"
    return 0
}

# Test 4: Verify MAX_ITERATIONS safety limit
test_max_iterations_limit() {
    echo "Test 4: Verifying MAX_ITERATIONS safety limit..."

    local build_cmd="/home/benjamin/.config/.claude/commands/build.md"

    if ! grep -q "MAX_ITERATIONS" "$build_cmd"; then
        echo "FAIL: MAX_ITERATIONS limit not found"
        return 1
    fi

    echo "PASS: MAX_ITERATIONS safety limit present"
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
    echo "Test Suite: /build Iteration Barriers"
    echo "==================================="

    setup_test

    local tests_passed=0
    local tests_failed=0

    # Run tests
    if test_iteration_continuation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    if test_iteration_after_verification; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    if test_checkpoint_persistence; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi

    if test_max_iterations_limit; then
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
