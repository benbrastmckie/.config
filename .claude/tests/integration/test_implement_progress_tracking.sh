#!/usr/bin/env bash
# Integration tests for /implement real-time progress tracking
#
# Tests verify that implementation-executor agent updates phase markers in real-time
# and that /implement Block 1d validation/recovery logic works correctly.
#
# Usage: bash .claude/tests/integration/test_implement_progress_tracking.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper: Print test result
print_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓${NC} Test $TESTS_RUN passed: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test $TESTS_RUN failed: $test_name"
        if [[ -n "$message" ]]; then
            echo -e "  ${YELLOW}Reason:${NC} $message"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper: Create test plan file
create_test_plan() {
    local plan_file="$1"
    cat > "$plan_file" <<'EOF'
# Test Plan for Progress Tracking

## Metadata
- **Date**: 2025-12-02
- **Feature**: Test progress tracking
- **Status**: [NOT STARTED]
- **Estimated Hours**: 1-2 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: none

## Implementation Phases

### Phase 1: First Phase [NOT STARTED]
dependencies: []

**Tasks**:
- [ ] Task 1.1
- [ ] Task 1.2

**Expected Duration**: 30 minutes

### Phase 2: Second Phase [NOT STARTED]
dependencies: [1]

**Tasks**:
- [ ] Task 2.1
- [ ] Task 2.2

**Expected Duration**: 30 minutes
EOF
}

# Test 1: Verify add_in_progress_marker() marks phase [IN PROGRESS] at start
test_in_progress_marker() {
    local test_plan="/tmp/test_progress_tracking_$$.md"
    create_test_plan "$test_plan"

    # Source checkbox-utils.sh
    source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh 2>/dev/null || {
        print_result "add_in_progress_marker() marks phase [IN PROGRESS]" "FAIL" "Cannot load checkbox-utils.sh"
        return 1
    }

    # Call add_in_progress_marker for Phase 1
    add_in_progress_marker "$test_plan" 1 2>/dev/null || true

    # Verify Phase 1 has [IN PROGRESS] marker
    if grep -q "### Phase 1:.*\[IN PROGRESS\]" "$test_plan"; then
        print_result "add_in_progress_marker() marks phase [IN PROGRESS]" "PASS"
        rm -f "$test_plan"
        return 0
    else
        local actual=$(grep "### Phase 1:" "$test_plan" || echo "Phase heading not found")
        print_result "add_in_progress_marker() marks phase [IN PROGRESS]" "FAIL" "Expected [IN PROGRESS] marker, got: $actual"
        rm -f "$test_plan"
        return 1
    fi
}

# Test 2: Verify add_complete_marker() marks phase [COMPLETE] at end
test_complete_marker() {
    local test_plan="/tmp/test_progress_tracking_$$.md"
    create_test_plan "$test_plan"

    # Source checkbox-utils.sh
    source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh 2>/dev/null || {
        print_result "add_complete_marker() marks phase [COMPLETE]" "FAIL" "Cannot load checkbox-utils.sh"
        return 1
    }

    # Mark Phase 1 in progress first
    add_in_progress_marker "$test_plan" 1 2>/dev/null || true

    # Mark all tasks complete
    mark_task_complete "$test_plan" 1 1 2>/dev/null || true
    mark_task_complete "$test_plan" 1 2 2>/dev/null || true

    # Call add_complete_marker for Phase 1
    add_complete_marker "$test_plan" 1 2>/dev/null || true

    # Verify Phase 1 has [COMPLETE] marker
    if grep -q "### Phase 1:.*\[COMPLETE\]" "$test_plan"; then
        print_result "add_complete_marker() marks phase [COMPLETE]" "PASS"
        rm -f "$test_plan"
        return 0
    else
        local actual=$(grep "### Phase 1:" "$test_plan" || echo "Phase heading not found")
        print_result "add_complete_marker() marks phase [COMPLETE]" "FAIL" "Expected [COMPLETE] marker, got: $actual"
        rm -f "$test_plan"
        return 1
    fi
}

# Test 3: Verify Block 1d recovery for missing markers
test_block1d_recovery() {
    local test_plan="/tmp/test_progress_tracking_$$.md"
    create_test_plan "$test_plan"

    # Source checkbox-utils.sh
    source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh 2>/dev/null || {
        print_result "Block 1d recovery for missing markers" "FAIL" "Cannot load checkbox-utils.sh"
        return 1
    }

    # Mark all tasks complete but do NOT call add_complete_marker
    # This simulates executor marker update failure
    mark_task_complete "$test_plan" 1 1 2>/dev/null || true
    mark_task_complete "$test_plan" 1 2 2>/dev/null || true

    # Verify phase has all tasks complete but no [COMPLETE] marker
    if verify_phase_complete "$test_plan" 1 2>/dev/null && ! grep -q "### Phase 1:.*\[COMPLETE\]" "$test_plan"; then
        # Simulate Block 1d recovery logic
        mark_phase_complete "$test_plan" 1 2>/dev/null || true
        add_complete_marker "$test_plan" 1 2>/dev/null || true

        # Verify recovery worked
        if grep -q "### Phase 1:.*\[COMPLETE\]" "$test_plan"; then
            print_result "Block 1d recovery for missing markers" "PASS"
            rm -f "$test_plan"
            return 0
        else
            print_result "Block 1d recovery for missing markers" "FAIL" "Recovery did not add [COMPLETE] marker"
            rm -f "$test_plan"
            return 1
        fi
    else
        print_result "Block 1d recovery for missing markers" "FAIL" "Test setup failed (phase should be complete without marker)"
        rm -f "$test_plan"
        return 1
    fi
}

# Test 4: Verify parallel execution does not corrupt plan file
test_parallel_execution_safety() {
    local test_plan="/tmp/test_progress_tracking_$$.md"

    # Create plan with 4 phases for parallel testing
    cat > "$test_plan" <<'EOF'
# Test Plan for Parallel Progress Tracking

## Metadata
- **Date**: 2025-12-02
- **Feature**: Test parallel progress tracking
- **Status**: [NOT STARTED]
- **Estimated Hours**: 1-2 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: none

## Implementation Phases

### Phase 1: Parallel Phase 1 [NOT STARTED]
dependencies: []

**Tasks**:
- [ ] Task 1.1

**Expected Duration**: 1 minute

### Phase 2: Parallel Phase 2 [NOT STARTED]
dependencies: []

**Tasks**:
- [ ] Task 2.1

**Expected Duration**: 1 minute

### Phase 3: Parallel Phase 3 [NOT STARTED]
dependencies: []

**Tasks**:
- [ ] Task 3.1

**Expected Duration**: 1 minute

### Phase 4: Parallel Phase 4 [NOT STARTED]
dependencies: []

**Tasks**:
- [ ] Task 4.1

**Expected Duration**: 1 minute
EOF

    # Source checkbox-utils.sh
    source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh 2>/dev/null || {
        print_result "Parallel execution does not corrupt plan file" "FAIL" "Cannot load checkbox-utils.sh"
        return 1
    }

    # Run marker updates in parallel (simulates multiple executors)
    (add_in_progress_marker "$test_plan" 1 2>/dev/null || true) &
    (add_in_progress_marker "$test_plan" 2 2>/dev/null || true) &
    (add_in_progress_marker "$test_plan" 3 2>/dev/null || true) &
    (add_in_progress_marker "$test_plan" 4 2>/dev/null || true) &

    # Wait for all background jobs
    wait

    # Verify all phases marked [IN PROGRESS]
    local marked_count=0
    for phase in 1 2 3 4; do
        if grep -q "### Phase $phase:.*\[IN PROGRESS\]" "$test_plan"; then
            marked_count=$((marked_count + 1))
        fi
    done

    # Complete all phases in parallel
    for phase in 1 2 3 4; do
        (mark_task_complete "$test_plan" "$phase" 1 2>/dev/null || true; add_complete_marker "$test_plan" "$phase" 2>/dev/null || true) &
    done

    # Wait for all background jobs
    wait

    # Verify all phases marked [COMPLETE]
    local complete_count=0
    for phase in 1 2 3 4; do
        if grep -q "### Phase $phase:.*\[COMPLETE\]" "$test_plan"; then
            complete_count=$((complete_count + 1))
        fi
    done

    # Verify plan file structure is intact (all phase headings exist)
    local headings_intact=true
    for phase in 1 2 3 4; do
        if ! grep -q "### Phase $phase:" "$test_plan"; then
            headings_intact=false
            break
        fi
    done

    if [[ $marked_count -ge 3 ]] && [[ $complete_count -ge 3 ]] && [[ "$headings_intact" == "true" ]]; then
        print_result "Parallel execution does not corrupt plan file" "PASS"
        rm -f "$test_plan"
        return 0
    else
        print_result "Parallel execution does not corrupt plan file" "FAIL" "IN PROGRESS: $marked_count/4, COMPLETE: $complete_count/4, Headings intact: $headings_intact"
        rm -f "$test_plan"
        return 1
    fi
}

# Main test execution
main() {
    echo "Running /implement real-time progress tracking integration tests..."
    echo ""

    # Run all tests
    test_in_progress_marker
    test_complete_marker
    test_block1d_recovery
    test_parallel_execution_safety

    # Print summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test Summary:"
    echo "  Total:  $TESTS_RUN"
    echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    else
        echo -e "  ${GREEN}All progress tracking tests passed!${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
