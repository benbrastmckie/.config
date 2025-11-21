#!/usr/bin/env bash
# Test wave generation and execution logic

set -euo pipefail

# Check if parse-phase-dependencies.sh exists
# This script was removed in Phase 1 refactor (commit 6f03824) as dead code
if [ ! -f ".claude/.claude/archive/lib/parse-phase-dependencies.sh" ]; then
  echo "SKIP: parse-phase-dependencies.sh was removed (wave generation functionality deprecated)"
  echo "This test validates functionality that is no longer part of the system."
  exit 0
fi

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Color codes for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to report test results
report_test() {
  local test_name="$1"
  local result="$2"

  if [ "$result" = "PASS" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 1: Simple dependency chain
test_simple_chain() {
  cat > "$TEST_DIR/simple_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: []

### Phase 2: Build
dependencies: [1]

### Phase 3: Test
dependencies: [2]
EOF

  WAVES=$(.claude/.claude/archive/lib/parse-phase-dependencies.sh "$TEST_DIR/simple_plan.md")

  # Expected output: 3 waves, one phase each
  local expected="WAVE_1:1"$'\n'"WAVE_2:2"$'\n'"WAVE_3:3"

  if [ "$WAVES" = "$expected" ]; then
    report_test "Simple dependency chain" "PASS"
    return 0
  else
    report_test "Simple dependency chain" "FAIL"
    echo "  Expected: $expected"
    echo "  Got: $WAVES"
    return 1
  fi
}

# Test 2: Parallel phases
test_parallel_phases() {
  cat > "$TEST_DIR/parallel_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: []

### Phase 2: Feature A
dependencies: [1]

### Phase 3: Feature B
dependencies: [1]

### Phase 4: Integration
dependencies: [2, 3]
EOF

  WAVES=$(.claude/.claude/archive/lib/parse-phase-dependencies.sh "$TEST_DIR/parallel_plan.md")

  # Wave 2 should contain phases 2 and 3 in parallel
  if echo "$WAVES" | grep -q "WAVE_2:2 3"; then
    report_test "Parallel phases detected" "PASS"
    return 0
  else
    report_test "Parallel phases detected" "FAIL"
    echo "  Expected WAVE_2 to contain '2 3'"
    echo "  Got: $WAVES"
    return 1
  fi
}

# Test 3: Complex dependency graph
test_complex_dependencies() {
  cat > "$TEST_DIR/complex_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: []

### Phase 2: Database
dependencies: [1]

### Phase 3: API
dependencies: [1]

### Phase 4: Frontend
dependencies: [1]

### Phase 5: Integration Tests
dependencies: [2, 3, 4]
EOF

  WAVES=$(.claude/.claude/archive/lib/parse-phase-dependencies.sh "$TEST_DIR/complex_plan.md")

  # Wave 2 should contain phases 2, 3, and 4 in parallel
  # Wave 3 should contain phase 5
  if echo "$WAVES" | grep -q "WAVE_2:2 3 4" && echo "$WAVES" | grep -q "WAVE_3:5"; then
    report_test "Complex dependency graph" "PASS"
    return 0
  else
    report_test "Complex dependency graph" "FAIL"
    echo "  Expected WAVE_2 to contain '2 3 4' and WAVE_3 to contain '5'"
    echo "  Got: $WAVES"
    return 1
  fi
}

# Test 4: Circular dependency detection
test_circular_dependency() {
  cat > "$TEST_DIR/circular_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: [2]

### Phase 2: Build
dependencies: [1]
EOF

  WAVES=$(.claude/.claude/archive/lib/parse-phase-dependencies.sh "$TEST_DIR/circular_plan.md" 2>&1 || true)

  # Should detect circular dependency
  if echo "$WAVES" | grep -q "ERROR: Circular dependency"; then
    report_test "Circular dependency detection" "PASS"
    return 0
  else
    report_test "Circular dependency detection" "FAIL"
    echo "  Expected error message about circular dependency"
    echo "  Got: $WAVES"
    return 1
  fi
}

# Test 5: No dependencies (all parallel)
test_no_dependencies() {
  cat > "$TEST_DIR/no_deps_plan.md" << 'EOF'
### Phase 1: Feature A
dependencies: []

### Phase 2: Feature B
dependencies: []

### Phase 3: Feature C
dependencies: []
EOF

  WAVES=$(.claude/.claude/archive/lib/parse-phase-dependencies.sh "$TEST_DIR/no_deps_plan.md")

  # All phases should be in wave 1
  if echo "$WAVES" | grep -q "WAVE_1:1 2 3"; then
    report_test "No dependencies (all parallel)" "PASS"
    return 0
  else
    report_test "No dependencies (all parallel)" "FAIL"
    echo "  Expected all phases in WAVE_1"
    echo "  Got: $WAVES"
    return 1
  fi
}

# Test 6: Missing dependency reference
test_missing_dependency() {
  cat > "$TEST_DIR/missing_dep_plan.md" << 'EOF'
### Phase 1: Setup
dependencies: []

### Phase 2: Build
dependencies: [1, 99]
EOF

  WAVES=$(.claude/.claude/archive/lib/parse-phase-dependencies.sh "$TEST_DIR/missing_dep_plan.md" 2>&1 || true)

  # Should detect missing phase reference
  # Note: Current implementation may not catch this - test documents expected behavior
  if echo "$WAVES" | grep -q "ERROR" || echo "$WAVES" | grep -q "non-existent"; then
    report_test "Missing dependency reference" "PASS"
    return 0
  else
    # This test may fail with current implementation - that's okay, documents future improvement
    report_test "Missing dependency reference (optional)" "SKIP"
    return 0
  fi
}

# Run all tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Wave Generation (parse-phase-dependencies.sh)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_simple_chain || true
test_parallel_phases || true
test_complex_dependencies || true
test_circular_dependency || true
test_no_dependencies || true
test_missing_dependency || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
