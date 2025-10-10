#!/usr/bin/env bash
# test_auto_analysis_orchestration.sh
# Tests for auto-analysis-utils.sh functions

set -euo pipefail

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh" 2>/dev/null || {
  # Minimal test framework if not available
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0

  assert_equals() {
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$1" == "$2" ]]; then
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo "✓ $3"
    else
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo "✗ $3"
      echo "  Expected: $2"
      echo "  Got: $1"
    fi
  }

  assert_success() {
    TESTS_RUN=$((TESTS_RUN + 1))
    if "$@" &>/dev/null; then
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo "✓ $*"
    else
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo "✗ $* (failed)"
    fi
  }

  assert_file_exists() {
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -f "$1" ]]; then
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo "✓ File exists: $1"
    else
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo "✗ File not found: $1"
    fi
  }

  print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total:  $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    if [[ $TESTS_FAILED -eq 0 ]]; then
      echo "Status: ✓ ALL TESTS PASSED"
      return 0
    else
      echo "Status: ✗ SOME TESTS FAILED"
      return 1
    fi
  }
}

# Source the library under test
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"
source "$LIB_DIR/auto-analysis-utils.sh"

# Test data directory
TEST_DATA_DIR="$SCRIPT_DIR/test_data/auto_analysis"
mkdir -p "$TEST_DATA_DIR"

echo "Testing Auto-Analysis Orchestration Utilities"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# Test 1: Library loads correctly
# ============================================================================

echo "Test Suite 1: Library Loading"
echo "──────────────────────────────"

assert_file_exists "$LIB_DIR/auto-analysis-utils.sh"

# Check that functions are defined
if declare -f invoke_complexity_estimator &>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ invoke_complexity_estimator function defined"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ invoke_complexity_estimator function not found"
fi

if declare -f analyze_phases_for_expansion &>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ analyze_phases_for_expansion function defined"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ analyze_phases_for_expansion function not found"
fi

if declare -f generate_analysis_report &>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ generate_analysis_report function defined"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ generate_analysis_report function not found"
fi

echo ""

# ============================================================================
# Test 2: invoke_complexity_estimator validation
# ============================================================================

echo "Test Suite 2: Agent Invocation Function"
echo "────────────────────────────────────────"

# Test invalid mode
if ! invoke_complexity_estimator "invalid" '[]' '{}' 2>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Rejects invalid mode"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Should reject invalid mode"
fi

# Test missing arguments
if ! invoke_complexity_estimator "" "" "" 2>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Rejects missing arguments"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Should reject missing arguments"
fi

# Test invalid JSON
if ! invoke_complexity_estimator "expansion" "not json" '{}' 2>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Rejects invalid JSON in content"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Should reject invalid JSON"
fi

# Test valid invocation (expansion mode)
valid_content='[{"item_id":"phase_1","item_name":"Test","content":"test content"}]'
valid_context='{"overview":"test","goals":"test goals","current_level":"0"}'

if invoke_complexity_estimator "expansion" "$valid_content" "$valid_context" &>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Accepts valid expansion invocation"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Should accept valid invocation"
fi

# Test valid invocation (collapse mode)
if invoke_complexity_estimator "collapse" "$valid_content" "$valid_context" &>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Accepts valid collapse invocation"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Should accept valid collapse invocation"
fi

echo ""

# ============================================================================
# Test 3: analyze_phases_for_expansion
# ============================================================================

echo "Test Suite 3: Phase Analysis for Expansion"
echo "───────────────────────────────────────────"

# Create a minimal test plan
test_plan="$TEST_DATA_DIR/test_plan.md"
cat > "$test_plan" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 0

## Overview
This is a test plan for expansion analysis.

## Success Criteria
- Feature works correctly
- Tests pass

### Phase 1: Simple Setup
**Objective**: Basic configuration
**Tasks**:
- [ ] Create config file
- [ ] Set environment variables

### Phase 2: Complex Implementation
**Objective**: Implement core architecture
**Tasks**:
- [ ] Design state management
- [ ] Implement API layer
- [ ] Add authentication
- [ ] Write integration tests
- [ ] Performance optimization
EOF

# Test with valid plan
if analyze_phases_for_expansion "$test_plan" &>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Analyzes valid plan for expansion"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Should analyze valid plan"
fi

# Test with non-existent plan
if ! analyze_phases_for_expansion "/nonexistent/plan.md" 2>/dev/null; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Rejects non-existent plan"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Should reject non-existent plan"
fi

echo ""

# ============================================================================
# Test 4: generate_analysis_report
# ============================================================================

echo "Test Suite 4: Report Generation"
echo "────────────────────────────────"

# Test with valid decisions JSON
decisions='[{"item_id":"phase_1","item_name":"Setup","complexity_level":3,"reasoning":"Simple config","recommendation":"skip","confidence":"high"},{"item_id":"phase_2","item_name":"Implementation","complexity_level":9,"reasoning":"Complex architecture","recommendation":"expand","confidence":"high"}]'

report_output=$(generate_analysis_report "expand" "$decisions" "$test_plan" 2>&1)

if echo "$report_output" | grep -q "Auto-Analysis Mode"; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Report includes header"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Report should include header"
fi

if echo "$report_output" | grep -q "Setup.*complexity: 3/10"; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Report includes phase 1 details"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Report should include phase details"
fi

if echo "$report_output" | grep -q "Summary:"; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ Report includes summary"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ Report should include summary"
fi

echo ""

# ============================================================================
# Cleanup and Summary
# ============================================================================

# Cleanup test data
rm -rf "$TEST_DATA_DIR"

# Print summary
print_summary
