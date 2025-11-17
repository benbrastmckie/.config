#!/usr/bin/env bash
# test_agent_behavioral_compliance.sh - Agent behavioral compliance test suite
#
# Tests critical agents for behavioral compliance patterns:
# - STEP structure
# - Imperative language (MUST/WILL/SHALL)
# - Verification checkpoints
# - File size limits (40KB max)
# - Completion signals
# - Absolute path requirements
# - Create file FIRST pattern
#
# Usage: ./test_agent_behavioral_compliance.sh [--verbose]
#
# Exit Codes:
#   0 - All tests passed
#   1 - Test failures detected

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$SCRIPT_DIR/../agents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Priority agents to test
PRIORITY_AGENTS=(
    "research-specialist"
    "implementer-coordinator"
    "plan-architect"
    "revision-specialist"
)

# Additional agents to test
ADDITIONAL_AGENTS=(
    "debug-analyst"
    "code-writer"
    "documentation-specialist"
    "github-specialist"
)

# Verbose mode
VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
fi

# Test directory
TEST_DIR="/tmp/agent_behavioral_tests_$$"

# Setup test environment
setup() {
    if $VERBOSE; then
        echo "Setting up test environment: $TEST_DIR"
    fi
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
}

# Cleanup test environment
cleanup() {
    if $VERBOSE; then
        echo "Cleaning up test environment"
    fi
    rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++)) || true
    ((TESTS_RUN++)) || true
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo "  Reason: $2"
    ((TESTS_FAILED++)) || true
    ((TESTS_RUN++)) || true
}

skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
    echo "  Reason: $2"
    ((TESTS_RUN++)) || true
}

# Assert helper functions
assert_file_exists() {
    local file="$1"
    local msg="$2"

    if [ -f "$file" ]; then
        pass "$msg"
    else
        fail "$msg" "File not found: $file"
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local msg="$3"

    if [ ! -f "$file" ]; then
        fail "$msg" "File not found: $file"
        return
    fi

    if grep -q "$pattern" "$file"; then
        pass "$msg"
    else
        fail "$msg" "Pattern not found: $pattern"
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local msg="$3"

    if [ ! -f "$file" ]; then
        fail "$msg" "File not found: $file"
        return
    fi

    if ! grep -q "$pattern" "$file"; then
        pass "$msg"
    else
        fail "$msg" "Pattern should not be present: $pattern"
    fi
}

# ============================================================================
# Test Pattern 1: STEP Structure Validation
# ============================================================================

test_agent_step_structure() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: STEP Structure - $agent"
    echo "================================="

    if [ ! -f "$agent_file" ]; then
        skip "$agent STEP structure" "Agent file not found"
        return
    fi

    # Check for STEP 1
    assert_file_contains "$agent_file" "### STEP 1" \
        "$agent has STEP 1"

    # Check for STEP 2
    assert_file_contains "$agent_file" "### STEP 2" \
        "$agent has STEP 2"

    # Check for sequential STEP numbering
    local step_count=$(grep -c "^### STEP [0-9]" "$agent_file" 2>/dev/null || echo 0)
    step_count=$(echo "$step_count" | tr -d '\n' | tr -d ' ')
    step_count=${step_count:-0}

    if [ "$step_count" -ge 2 ]; then
        pass "$agent has sequential STEP structure ($step_count steps)"
    else
        fail "$agent has insufficient STEP structure" "Found $step_count steps (expected ≥2)"
    fi
}

# ============================================================================
# Test Pattern 2: Imperative Language Validation
# ============================================================================

test_agent_imperative_language() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: Imperative Language - $agent"
    echo "======================================"

    if [ ! -f "$agent_file" ]; then
        skip "$agent imperative language" "Agent file not found"
        return
    fi

    # Check for MUST
    assert_file_contains "$agent_file" "MUST" \
        "$agent uses imperative language (MUST)"

    # Check for WILL or SHALL
    if grep -q "WILL\|SHALL" "$agent_file"; then
        pass "$agent uses strong imperative language (WILL/SHALL)"
    else
        fail "$agent lacks strong imperative language" "No WILL/SHALL found"
    fi

    # Check for absence of weak language (should, may, can)
    local weak_count=$(grep -ci "should\|may\|can" "$agent_file" 2>/dev/null || echo 0)
    weak_count=$(echo "$weak_count" | tr -d '\n' | tr -d ' ')
    weak_count=${weak_count:-0}

    if [ "$weak_count" -le 5 ]; then
        pass "$agent avoids weak language ($weak_count occurrences)"
    else
        fail "$agent uses too much weak language" "Found $weak_count occurrences (expected ≤5)"
    fi
}

# ============================================================================
# Test Pattern 3: Verification Checkpoints
# ============================================================================

test_agent_verification_checkpoints() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: Verification Checkpoints - $agent"
    echo "==========================================="

    if [ ! -f "$agent_file" ]; then
        skip "$agent verification checkpoints" "Agent file not found"
        return
    fi

    # Check for CHECKPOINT keyword
    assert_file_contains "$agent_file" "CHECKPOINT" \
        "$agent has verification checkpoints"

    # Check for VERIFICATION keyword
    if grep -q "VERIFICATION" "$agent_file"; then
        pass "$agent has verification blocks"
    fi

    # Check for verification density
    local checkpoint_count=$(grep -ci "checkpoint\|verification" "$agent_file" 2>/dev/null || echo 0)
    checkpoint_count=$(echo "$checkpoint_count" | tr -d '\n' | tr -d ' ')
    checkpoint_count=${checkpoint_count:-1}

    local total_lines=$(wc -l < "$agent_file")
    local density=$((total_lines / checkpoint_count))

    if [ "$density" -le 100 ]; then
        pass "$agent has adequate verification density (1 per $density lines)"
    else
        fail "$agent has low verification density" "1 per $density lines (expected ≤100)"
    fi
}

# ============================================================================
# Test Pattern 4: File Size Limits
# ============================================================================

test_agent_file_size_limits() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: File Size Limits - $agent"
    echo "==================================="

    if [ ! -f "$agent_file" ]; then
        skip "$agent file size" "Agent file not found"
        return
    fi

    # Check file size in bytes (40KB = 40960 bytes)
    local file_size=$(stat -c %s "$agent_file" 2>/dev/null || stat -f %z "$agent_file" 2>/dev/null)
    local size_kb=$((file_size / 1024))

    if [ "$file_size" -le 40960 ]; then
        pass "$agent is within 40KB limit (${size_kb}KB)"
    else
        fail "$agent exceeds 40KB limit" "${size_kb}KB (should be ≤40KB)"
    fi

    # Check line count (400 lines is typical threshold)
    local line_count=$(wc -l < "$agent_file")
    if [ "$line_count" -le 400 ]; then
        pass "$agent is within 400 line limit ($line_count lines)"
    else
        fail "$agent exceeds 400 line limit" "$line_count lines (should be ≤400)"
    fi
}

# ============================================================================
# Test Pattern 5: Completion Signals
# ============================================================================

test_agent_completion_signals() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: Completion Signals - $agent"
    echo "====================================="

    if [ ! -f "$agent_file" ]; then
        skip "$agent completion signals" "Agent file not found"
        return
    fi

    # Check for completion signal patterns
    if grep -q "REPORT_CREATED:\|PLAN_CREATED:\|COMPLETION:" "$agent_file"; then
        pass "$agent has completion signal format"
    else
        fail "$agent lacks completion signal" "No REPORT_CREATED/PLAN_CREATED/COMPLETION found"
    fi

    # Check for properly formatted path in signal
    if grep -q "_CREATED:.*/" "$agent_file" || grep -q "COMPLETION:.*/" "$agent_file"; then
        pass "$agent includes path in completion signal"
    else
        fail "$agent lacks path in completion signal" "Signal should include artifact path"
    fi
}

# ============================================================================
# Test Pattern 6: Absolute Path Requirements
# ============================================================================

test_agent_absolute_paths() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: Absolute Path Requirements - $agent"
    echo "============================================="

    if [ ! -f "$agent_file" ]; then
        skip "$agent absolute paths" "Agent file not found"
        return
    fi

    # Check for absolute path requirement documentation
    assert_file_contains "$agent_file" "absolute" \
        "$agent requires absolute paths"

    # Check for relative path anti-pattern warnings
    if grep -qi "relative path\|DO NOT use relative" "$agent_file"; then
        pass "$agent warns against relative paths"
    fi

    # Check for path validation
    if grep -q "must start with /\|must be absolute\|^/" "$agent_file"; then
        pass "$agent validates absolute path format"
    fi
}

# ============================================================================
# Test Pattern 7: Create File FIRST Pattern
# ============================================================================

test_agent_create_file_first() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: Create File FIRST Pattern - $agent"
    echo "============================================"

    if [ ! -f "$agent_file" ]; then
        skip "$agent create file first" "Agent file not found"
        return
    fi

    # Check for "Create File FIRST" pattern
    if grep -q "Create.*File FIRST\|FIRST.*create\|Write.*file.*FIRST" "$agent_file"; then
        pass "$agent follows create file FIRST pattern"
    else
        fail "$agent lacks create file FIRST enforcement" "Pattern not found"
    fi

    # Check that file creation comes before analysis
    local file_create_line=$(grep -n "Write\|Create.*file" "$agent_file" | head -1 | cut -d: -f1)
    local analysis_line=$(grep -n "Analyz\|Read.*content\|Parse" "$agent_file" | head -1 | cut -d: -f1)

    if [ -n "$file_create_line" ] && [ -n "$analysis_line" ]; then
        if [ "$file_create_line" -lt "$analysis_line" ]; then
            pass "$agent creates file before analysis (line $file_create_line < $analysis_line)"
        else
            fail "$agent creates file after analysis" "Line $file_create_line > $analysis_line"
        fi
    fi
}

# ============================================================================
# Test Pattern 8: Frontmatter Validation
# ============================================================================

test_agent_frontmatter() {
    local agent="$1"
    local agent_file="$AGENTS_DIR/${agent}.md"

    echo ""
    echo "Test Group: Frontmatter - $agent"
    echo "=============================="

    if [ ! -f "$agent_file" ]; then
        skip "$agent frontmatter" "Agent file not found"
        return
    fi

    # Check for allowed-tools
    assert_file_contains "$agent_file" "allowed-tools:" \
        "$agent has allowed-tools"

    # Check for model selection
    assert_file_contains "$agent_file" "model:" \
        "$agent has model selection"

    # Check for description
    assert_file_contains "$agent_file" "description:" \
        "$agent has description"
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo "=========================================="
    echo "  Agent Behavioral Compliance Test Suite"
    echo "=========================================="

    setup

    # Test priority agents
    for agent in "${PRIORITY_AGENTS[@]}"; do
        if [ ! -f "$AGENTS_DIR/${agent}.md" ]; then
            echo ""
            echo "Priority Agent: $agent"
            echo "===================="
            skip "All tests for $agent" "Agent file not found"
            continue
        fi

        echo ""
        echo "Priority Agent: $agent"
        echo "===================="

        test_agent_frontmatter "$agent"
        test_agent_step_structure "$agent"
        test_agent_imperative_language "$agent"
        test_agent_verification_checkpoints "$agent"
        test_agent_file_size_limits "$agent"
        test_agent_completion_signals "$agent"
        test_agent_absolute_paths "$agent"
        test_agent_create_file_first "$agent"
    done

    # Test additional agents (if they exist)
    for agent in "${ADDITIONAL_AGENTS[@]}"; do
        if [ ! -f "$AGENTS_DIR/${agent}.md" ]; then
            continue
        fi

        echo ""
        echo "Additional Agent: $agent"
        echo "===================="

        test_agent_frontmatter "$agent"
        test_agent_step_structure "$agent"
        test_agent_imperative_language "$agent"
        test_agent_file_size_limits "$agent"
    done

    cleanup

    # Print summary
    echo ""
    echo "=========================================="
    echo "  Test Summary"
    echo "=========================================="
    echo "Tests Run:    $TESTS_RUN"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo ""

    # Calculate success rate
    if [ $TESTS_RUN -gt 0 ]; then
        SUCCESS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
        echo "Success Rate: ${SUCCESS_RATE}%"
        echo ""
    fi

    # Exit with appropriate code
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed${NC}"
        exit 1
    fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
