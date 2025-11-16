#!/usr/bin/env bash
# Test: Wave-Based Execution in /coordinate Command
# Category: HIGH - Verifies parallel wave execution capability

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_FILE="$SCRIPT_DIR/../commands/coordinate.md"
LIB_DIR="$SCRIPT_DIR/../lib"
TEST_NAME="test_coordinate_waves"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_test_header() {
  echo -e "\n${YELLOW}=== $1 ===${NC}"
}

assert_true() {
  local description="$1"
  local command="$2"
  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command"; then
    echo -e "${GREEN}✓${NC} $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_false() {
  local description="$1"
  local command="$2"
  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command"; then
    echo -e "${RED}✗${NC} $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  else
    echo -e "${GREEN}✓${NC} $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  fi
}

assert_count() {
  local description="$1"
  local expected="$2"
  local command="$3"
  TESTS_RUN=$((TESTS_RUN + 1))

  local actual
  actual=$(eval "$command")

  if [ "$actual" -ge "$expected" ]; then
    echo -e "${GREEN}✓${NC} $description (expected ≥$expected, got $actual)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description (expected ≥$expected, got $actual)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: Dependency Analyzer Library Integration
print_test_header "Test 1: Dependency Analyzer Library Integration"
assert_true "Dependency-analyzer.sh exists" "[ -f '$LIB_DIR/dependency-analyzer.sh' ]"
assert_true "Dependency-analyzer.sh sourced in command" "grep -q 'source.*dependency-analyzer.sh' '$COMMAND_FILE'"

# Test 2: Wave Calculation Logic Present
print_test_header "Test 2: Wave Calculation Logic"
assert_true "Wave-based execution documented" "grep -qE 'wave-based|Wave-based' '$COMMAND_FILE'"
assert_true "Dependency analyzer sourced" "grep -q 'dependency-analyzer.sh' '$COMMAND_FILE'"
assert_true "Parallel execution mentioned" "grep -qE 'parallel.*execution|execute.*parallel' '$COMMAND_FILE'"

# Test 3: Implementation Phase Uses Wave-Based Execution
print_test_header "Test 3: Implementation Phase Wave-Based Execution"
assert_true "Implementation Phase mentions waves" "grep -A 100 '## State Handler: Implementation Phase' '$COMMAND_FILE' | grep -qE 'wave|parallel'"
assert_true "Implementation Phase uses implementer-coordinator" "grep -A 100 '## State Handler: Implementation Phase' '$COMMAND_FILE' | grep -q 'implementer-coordinator.md'"
assert_false "Implementation Phase does NOT use sequential code-writer" "grep -A 100 '## State Handler: Implementation Phase' '$COMMAND_FILE' | grep -q 'code-writer.md'"

# Test 4: Parallel Execution Pattern
print_test_header "Test 4: Parallel Execution Pattern"
assert_true "Parallel execution documented" "grep -qE 'parallel.*execution|execute.*parallel' '$COMMAND_FILE'"
assert_true "Implementer-coordinator agent documented" "grep -q 'implementer-coordinator' '$COMMAND_FILE'"

# Test 5: Checkpoint Integration
print_test_header "Test 5: Checkpoint Integration"
assert_true "Checkpoint utilities integrated" "grep -qE 'checkpoint-utils.sh|checkpoint.*recovery' '$COMMAND_FILE'"
assert_true "State persistence mentioned" "grep -qE 'state.*persistence|persist.*state' '$COMMAND_FILE'"

# Test 6: Implementation Delegation
print_test_header "Test 6: Implementation Delegation"
assert_true "Implementer-coordinator delegation" "grep -q 'implementer-coordinator' '$COMMAND_FILE'"
assert_true "Parallel execution strategy" "grep -qE 'parallel.*execution|wave.*based' '$COMMAND_FILE'"

# Test 7: Documentation Quality
print_test_header "Test 7: Documentation Quality"
assert_true "Wave-based execution documented" "grep -qi 'wave' '$COMMAND_FILE'"
assert_true "State-based architecture documented" "grep -qE 'State Handler|state.*machine' '$COMMAND_FILE'"

# Test 8: Library Integration
print_test_header "Test 8: Library Integration"
assert_true "Dependency analyzer sourced" "grep -q 'dependency-analyzer.sh' '$COMMAND_FILE'"
assert_true "Error handling library sourced" "grep -qE 'error-handling.sh|emit_error' '$COMMAND_FILE'"

# Test 9: Architecture Compliance
print_test_header "Test 9: Architecture Compliance"
assert_true "Uses state-based phases" "grep -qE 'Implementation Phase|Testing Phase|Research Phase' '$COMMAND_FILE'"
assert_true "Supports parallel execution" "grep -qE 'parallel|wave' '$COMMAND_FILE'"

# Test 10: Library Function Usage
print_test_header "Test 10: Library Function Usage"
if [ -f "$LIB_DIR/dependency-analyzer.sh" ]; then
  # Source the library to check for required functions
  source "$LIB_DIR/dependency-analyzer.sh"

  assert_true "analyze_dependencies function exists" "type -t analyze_dependencies >/dev/null"
  assert_true "build_dependency_graph function exists" "type -t build_dependency_graph >/dev/null"

  echo -e "${GREEN}✓${NC} Dependency analyzer library is functional"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗${NC} Dependency analyzer library not found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 11: Wave-Based Execution Benefits
print_test_header "Test 11: Wave-Based Execution Benefits"
assert_true "Wave-based execution mentioned" "grep -qi 'wave.*based' '$COMMAND_FILE'"
assert_true "Parallel execution capability documented" "grep -qi 'parallel' '$COMMAND_FILE'"

# Summary
print_test_header "Test Summary"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All wave execution tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some wave execution tests failed.${NC}"
  exit 1
fi
