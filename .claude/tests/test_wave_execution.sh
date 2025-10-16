#!/bin/bash
# Test Wave-Based Execution
#
# Tests for dependency analysis and wave calculation functionality
# used in wave-based parallel execution during orchestration.

set -e

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "$CLAUDE_DIR/lib/base-utils.sh" || {
  echo "ERROR: Failed to source base-utils.sh" >&2
  exit 1
}

source "$CLAUDE_DIR/lib/dependency-analysis.sh" || {
  error "Failed to source dependency-analysis.sh"
  exit 1
}

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test fixtures directory
FIXTURES_DIR="$SCRIPT_DIR/fixtures/wave_execution"
mkdir -p "$FIXTURES_DIR"

# Helper functions

pass() {
  echo "✓ $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo "✗ $1"
  echo "  Expected: $2"
  echo "  Got: $3"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if [[ "$expected" == "$actual" ]]; then
    pass "$test_name"
    return 0
  else
    fail "$test_name" "$expected" "$actual"
    return 1
  fi
}

assert_exit_code() {
  local expected_code="$1"
  local actual_code="$2"
  local test_name="$3"

  if [[ $actual_code -eq $expected_code ]]; then
    pass "$test_name"
    return 0
  else
    fail "$test_name" "exit code $expected_code" "exit code $actual_code"
    return 1
  fi
}

# Create test fixtures

create_linear_plan() {
  local plan_file="$FIXTURES_DIR/linear_plan.md"
  cat >"$plan_file" <<'EOF'
# Linear Plan Test

## Implementation Phases

### Phase 1: Foundation
**Dependencies**: []

Tasks:
- [ ] Task 1

### Phase 2: Core
**Dependencies**: [1]

Tasks:
- [ ] Task 1

### Phase 3: Integration
**Dependencies**: [2]

Tasks:
- [ ] Task 1

### Phase 4: Testing
**Dependencies**: [3]

Tasks:
- [ ] Task 1
EOF
  echo "$plan_file"
}

create_fan_out_plan() {
  local plan_file="$FIXTURES_DIR/fan_out_plan.md"
  cat >"$plan_file" <<'EOF'
# Fan-Out Plan Test

## Implementation Phases

### Phase 1: Foundation
**Dependencies**: []

Tasks:
- [ ] Task 1

### Phase 2: Module A
**Dependencies**: [1]

Tasks:
- [ ] Task 1

### Phase 3: Module B
**Dependencies**: [1]

Tasks:
- [ ] Task 1

### Phase 4: Module C
**Dependencies**: [1]

Tasks:
- [ ] Task 1

### Phase 5: Integration
**Dependencies**: [2, 3, 4]

Tasks:
- [ ] Task 1
EOF
  echo "$plan_file"
}

create_diamond_plan() {
  local plan_file="$FIXTURES_DIR/diamond_plan.md"
  cat >"$plan_file" <<'EOF'
# Diamond Plan Test

## Implementation Phases

### Phase 1: Setup
**Dependencies**: []

Tasks:
- [ ] Task 1

### Phase 2: Backend
**Dependencies**: [1]

Tasks:
- [ ] Task 1

### Phase 3: Frontend
**Dependencies**: [1]

Tasks:
- [ ] Task 1

### Phase 4: Integration
**Dependencies**: [2, 3]

Tasks:
- [ ] Task 1
EOF
  echo "$plan_file"
}

create_circular_plan() {
  local plan_file="$FIXTURES_DIR/circular_plan.md"
  cat >"$plan_file" <<'EOF'
# Circular Dependency Plan Test

## Implementation Phases

### Phase 1: Module A
**Dependencies**: [3]

Tasks:
- [ ] Task 1

### Phase 2: Module B
**Dependencies**: [1]

Tasks:
- [ ] Task 1

### Phase 3: Module C
**Dependencies**: [2]

Tasks:
- [ ] Task 1
EOF
  echo "$plan_file"
}

create_invalid_dependency_plan() {
  local plan_file="$FIXTURES_DIR/invalid_dependency_plan.md"
  cat >"$plan_file" <<'EOF'
# Invalid Dependency Plan Test

## Implementation Phases

### Phase 1: Setup
**Dependencies**: []

Tasks:
- [ ] Task 1

### Phase 2: Implementation
**Dependencies**: [5]

Tasks:
- [ ] Task 1

### Phase 3: Testing
**Dependencies**: [2]

Tasks:
- [ ] Task 1
EOF
  echo "$plan_file"
}

create_self_dependency_plan() {
  local plan_file="$FIXTURES_DIR/self_dependency_plan.md"
  cat >"$plan_file" <<'EOF'
# Self-Dependency Plan Test

## Implementation Phases

### Phase 1: Setup
**Dependencies**: []

Tasks:
- [ ] Task 1

### Phase 2: Implementation
**Dependencies**: [2]

Tasks:
- [ ] Task 1

### Phase 3: Testing
**Dependencies**: [2]

Tasks:
- [ ] Task 1
EOF
  echo "$plan_file"
}

# Test Suite

echo "Running Wave-Based Execution Tests..."
echo ""

# Test 1: Parse dependencies from phase with no dependencies
echo "Test 1: Parse empty dependencies"
plan_file=$(create_linear_plan)
result=$(parse_dependencies "$plan_file" 1)
assert_equals "" "$result" "Parse empty dependencies (Phase 1)"

# Test 2: Parse dependencies from phase with single dependency
echo "Test 2: Parse single dependency"
result=$(parse_dependencies "$plan_file" 2)
assert_equals "1" "$result" "Parse single dependency (Phase 2)"

# Test 3: Parse dependencies from phase with multiple dependencies
echo "Test 3: Parse multiple dependencies"
plan_file=$(create_fan_out_plan)
result=$(parse_dependencies "$plan_file" 5)
assert_equals "2 3 4" "$result" "Parse multiple dependencies (Phase 5)"

# Test 4: Calculate waves for linear plan
echo "Test 4: Calculate waves - linear plan"
plan_file=$(create_linear_plan)
result=$(calculate_execution_waves "$plan_file")
expected='[[1],[2],[3],[4]]'
assert_equals "$expected" "$result" "Linear plan waves"

# Test 5: Calculate waves for fan-out plan
echo "Test 5: Calculate waves - fan-out plan"
plan_file=$(create_fan_out_plan)
result=$(calculate_execution_waves "$plan_file")
# Wave 1: [1], Wave 2: [2,3,4], Wave 3: [5]
# Check if result matches pattern (order of phases in wave may vary)
if echo "$result" | jq -e 'length == 3' >/dev/null 2>&1; then
  if echo "$result" | jq -e '.[0] == [1]' >/dev/null 2>&1; then
    if echo "$result" | jq -e '.[1] | length == 3' >/dev/null 2>&1; then
      if echo "$result" | jq -e '.[2] == [5]' >/dev/null 2>&1; then
        pass "Fan-out plan waves"
        TESTS_RUN=$((TESTS_RUN + 1))
      else
        fail "Fan-out plan waves" "Wave 3 = [5]" "Wave 3 = $(echo "$result" | jq '.[2]')"
      fi
    else
      fail "Fan-out plan waves" "Wave 2 has 3 phases" "Wave 2 has $(echo "$result" | jq '.[1] | length') phases"
    fi
  else
    fail "Fan-out plan waves" "Wave 1 = [1]" "Wave 1 = $(echo "$result" | jq '.[0]')"
  fi
else
  fail "Fan-out plan waves" "3 waves" "$(echo "$result" | jq 'length') waves"
fi

# Test 6: Calculate waves for diamond plan
echo "Test 6: Calculate waves - diamond plan"
plan_file=$(create_diamond_plan)
result=$(calculate_execution_waves "$plan_file")
# Wave 1: [1], Wave 2: [2,3], Wave 3: [4]
if echo "$result" | jq -e 'length == 3' >/dev/null 2>&1; then
  if echo "$result" | jq -e '.[0] == [1]' >/dev/null 2>&1; then
    if echo "$result" | jq -e '.[1] | length == 2' >/dev/null 2>&1; then
      if echo "$result" | jq -e '.[2] == [4]' >/dev/null 2>&1; then
        pass "Diamond plan waves"
        TESTS_RUN=$((TESTS_RUN + 1))
      else
        fail "Diamond plan waves" "Wave 3 = [4]" "Wave 3 = $(echo "$result" | jq '.[2]')"
      fi
    else
      fail "Diamond plan waves" "Wave 2 has 2 phases" "Wave 2 has $(echo "$result" | jq '.[1] | length') phases"
    fi
  else
    fail "Diamond plan waves" "Wave 1 = [1]" "Wave 1 = $(echo "$result" | jq '.[0]')"
  fi
else
  fail "Diamond plan waves" "3 waves" "$(echo "$result" | jq 'length') waves"
fi

# Test 7: Detect circular dependencies
echo "Test 7: Detect circular dependencies"
plan_file=$(create_circular_plan)
if detect_circular_dependencies "$plan_file" 2>/dev/null; then
  fail "Detect circular dependencies" "circular dependency detected (exit 1)" "no circular dependency (exit 0)"
else
  pass "Detect circular dependencies"
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 8: Wave calculation fails on circular dependencies
echo "Test 8: Wave calculation fails on circular dependencies"
plan_file=$(create_circular_plan)
if calculate_execution_waves "$plan_file" 2>/dev/null; then
  fail "Wave calculation with circular deps" "failure (exit 1)" "success (exit 0)"
else
  pass "Wave calculation with circular deps"
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 9: Validate dependencies - valid plan
echo "Test 9: Validate dependencies - valid plan"
plan_file=$(create_diamond_plan)
if validate_dependencies "$plan_file" 2>/dev/null; then
  pass "Validate dependencies - valid plan"
  TESTS_RUN=$((TESTS_RUN + 1))
else
  fail "Validate dependencies - valid plan" "success (exit 0)" "failure (exit 1)"
fi

# Test 10: Validate dependencies - invalid dependency number
echo "Test 10: Validate dependencies - invalid dependency"
plan_file=$(create_invalid_dependency_plan)
if validate_dependencies "$plan_file" 2>/dev/null; then
  fail "Validate dependencies - invalid dep" "failure (exit 1)" "success (exit 0)"
else
  pass "Validate dependencies - invalid dep"
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 11: Validate dependencies - self dependency
echo "Test 11: Validate dependencies - self dependency"
plan_file=$(create_self_dependency_plan)
if validate_dependencies "$plan_file" 2>/dev/null; then
  fail "Validate dependencies - self dep" "failure (exit 1)" "success (exit 0)"
else
  pass "Validate dependencies - self dep"
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 12: Parse dependencies - phase not found
echo "Test 12: Parse dependencies - phase not found"
plan_file=$(create_linear_plan)
if parse_dependencies "$plan_file" 999 2>/dev/null; then
  fail "Parse dependencies - phase not found" "failure (exit 1)" "success (exit 0)"
else
  pass "Parse dependencies - phase not found"
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# Clean up test fixtures
echo ""
echo "Cleaning up test fixtures..."
rm -rf "$FIXTURES_DIR"

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "========================================="

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
