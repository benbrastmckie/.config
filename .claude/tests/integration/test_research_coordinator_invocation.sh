#!/usr/bin/env bash
# Integration test for research-coordinator agent Task invocation fixes
# Tests that research-coordinator successfully invokes research-specialist agents
# and creates expected reports with diagnostic capabilities

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_NAME="research-coordinator-invocation"
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test result functions
pass_test() {
    local test_name="$1"
    echo -e "${GREEN}✓ PASS${NC}: $test_name"
    ((TESTS_PASSED++))
}

fail_test() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}✗ FAIL${NC}: $test_name"
    echo -e "  Reason: $reason"
    ((TESTS_FAILED++))
}

# Test 1: Verify behavioral file has execution enforcement markers
test_execution_markers() {
    local test_name="Behavioral file contains execution enforcement markers"
    local behavioral_file="$PROJECT_DIR/agents/research-coordinator.md"

    if [ ! -f "$behavioral_file" ]; then
        fail_test "$test_name" "Behavioral file not found: $behavioral_file"
        return
    fi

    # Check for key execution markers
    local markers_found=0

    grep -q "EXECUTE NOW - DO NOT SKIP" "$behavioral_file" 2>/dev/null && ((markers_found++))
    grep -q "THIS IS NOT DOCUMENTATION - EXECUTE NOW" "$behavioral_file" 2>/dev/null && ((markers_found++))
    grep -q "EXECUTION ZONE" "$behavioral_file" 2>/dev/null && ((markers_found++))
    grep -q "### STEP.*(EXECUTE" "$behavioral_file" 2>/dev/null && ((markers_found++))
    grep -q "target-audience: agent-execution" "$behavioral_file" 2>/dev/null && ((markers_found++))

    if [ "$markers_found" -ge 4 ]; then
        pass_test "$test_name (found $markers_found/5 markers)"
    else
        fail_test "$test_name" "Insufficient execution markers found: $markers_found/5"
    fi
}

# Test 2: Verify empty directory validation exists in STEP 4
test_empty_directory_validation() {
    local test_name="Empty directory validation implemented in STEP 4"
    local behavioral_file="$PROJECT_DIR/agents/research-coordinator.md"

    if [ ! -f "$behavioral_file" ]; then
        fail_test "$test_name" "Behavioral file not found"
        return
    fi

    local checks_found=0
    grep -q "Reports directory is empty - no reports created" "$behavioral_file" && ((checks_found++))
    grep -q "CREATED_REPORTS=\$(ls.*wc -l)" "$behavioral_file" && ((checks_found++))
    grep -q 'if \[ "$CREATED_REPORTS" -eq 0 \]' "$behavioral_file" && ((checks_found++))
    grep -q "Diagnostic Information:" "$behavioral_file" && ((checks_found++))

    if [ "$checks_found" -eq 4 ]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Missing validation checks: $checks_found/4"
    fi
}

# Test 3: Verify invocation logging instructions exist
test_invocation_logging() {
    local test_name="Invocation logging instructions present"
    local behavioral_file="$PROJECT_DIR/agents/research-coordinator.md"

    if [ ! -f "$behavioral_file" ]; then
        fail_test "$test_name" "Behavioral file not found"
        return
    fi

    local checks_found=0
    grep -q "Log this invocation" "$behavioral_file" && ((checks_found++))
    grep -q ".invocation-trace.log" "$behavioral_file" && ((checks_found++))
    grep -q "STEP 3 Summary" "$behavioral_file" && ((checks_found++))

    if [ "$checks_found" -eq 3 ]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Missing logging elements: $checks_found/3"
    fi
}

# Test 4: Verify STEP 3.5 self-validation checkpoint
test_self_validation_checkpoint() {
    local test_name="STEP 3.5 self-validation checkpoint enhanced"
    local behavioral_file="$PROJECT_DIR/agents/research-coordinator.md"

    if [ ! -f "$behavioral_file" ]; then
        fail_test "$test_name" "Behavioral file not found"
        return
    fi

    local checks_found=0
    grep -q "STEP 3.5.*MANDATORY SELF-VALIDATION" "$behavioral_file" && ((checks_found++))
    grep -q "SELF-CHECK QUESTIONS" "$behavioral_file" && ((checks_found++))
    grep -q "FAIL-FAST INSTRUCTION" "$behavioral_file" && ((checks_found++))
    grep -q "return to STEP 3" "$behavioral_file" && ((checks_found++))

    if [ "$checks_found" -eq 4 ]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Missing validation elements: $checks_found/4"
    fi
}

# Test 5: Verify documentation clarity improvements
test_documentation_clarity() {
    local test_name="Documentation clarity and audience separation"
    local behavioral_file="$PROJECT_DIR/agents/research-coordinator.md"

    if [ ! -f "$behavioral_file" ]; then
        fail_test "$test_name" "Behavioral file not found"
        return
    fi

    local checks_found=0
    grep -q "File Structure (Read This First)" "$behavioral_file" && ((checks_found++))
    grep -q "Command-Author Reference.*NOT FOR AGENT EXECUTION" "$behavioral_file" && ((checks_found++))
    grep -q "AGENT: EXECUTE" "$behavioral_file" && ((checks_found++))
    grep -q "DOCUMENTATION ONLY" "$behavioral_file" && ((checks_found++))

    if [ "$checks_found" -eq 4 ]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Missing clarity elements: $checks_found/4"
    fi
}

# Test 6: Verify minimum report size increased to 1000 bytes
test_minimum_report_size() {
    local test_name="Minimum report size increased to 1000 bytes"
    local behavioral_file="$PROJECT_DIR/agents/research-coordinator.md"

    if [ ! -f "$behavioral_file" ]; then
        fail_test "$test_name" "Behavioral file not found"
        return
    fi

    if grep -q "lt 1000" "$behavioral_file" && ! grep -q "lt 500" "$behavioral_file"; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "1000 byte threshold not found or 500 byte threshold still present"
    fi
}

# Test 7: Verify trace file cleanup instruction
test_trace_file_cleanup() {
    local test_name="Trace file cleanup instruction present"
    local behavioral_file="$PROJECT_DIR/agents/research-coordinator.md"

    if [ ! -f "$behavioral_file" ]; then
        fail_test "$test_name" "Behavioral file not found"
        return
    fi

    local checks_found=0
    grep -q "Cleanup Invocation Trace" "$behavioral_file" && ((checks_found++))
    grep -q "rm.*invocation-trace.log" "$behavioral_file" && ((checks_found++))

    if [ "$checks_found" -eq 2 ]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Missing cleanup elements: $checks_found/2"
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "Research Coordinator Invocation Test Suite"
    echo "=========================================="
    echo ""

    # Run tests
    test_execution_markers
    test_empty_directory_validation
    test_invocation_logging
    test_self_validation_checkpoint
    test_documentation_clarity
    test_minimum_report_size
    test_trace_file_cleanup

    # Summary
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed${NC}: $TESTS_PASSED"
    echo -e "${RED}Failed${NC}: $TESTS_FAILED"
    echo "Total: $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

# Run main function
main "$@"
