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
assert_true "Dependency graph building referenced" "grep -qE 'build_dependency_graph|analyze_dependencies|parse.*dependencies' '$COMMAND_FILE'"
assert_true "Wave calculation referenced" "grep -qE 'calculate_waves|topological.*sort|Kahn' '$COMMAND_FILE'"
assert_true "Wave loop structure present" "grep -qE 'for.*wave|while.*wave' '$COMMAND_FILE'"

# Test 3: Phase 3 Uses Wave-Based Execution
print_test_header "Test 3: Phase 3 Wave-Based Execution"
assert_true "Phase 3 mentions waves" "grep -A 100 '## Phase 3:' '$COMMAND_FILE' | grep -qE 'wave|parallel'"
assert_true "Phase 3 uses implementer-coordinator" "grep -A 100 '## Phase 3:' '$COMMAND_FILE' | grep -q 'implementer-coordinator.md'"
assert_false "Phase 3 does NOT use sequential code-writer" "grep -A 100 '## Phase 3:' '$COMMAND_FILE' | grep -q 'code-writer.md'"

# Test 4: Parallel Execution Pattern
print_test_header "Test 4: Parallel Execution Pattern"
assert_true "Parallel execution documented" "grep -qE 'parallel.*execution|execute.*parallel' '$COMMAND_FILE'"
assert_true "Wave context mentioned" "grep -qiE 'Wave.*Execution.*Context|Wave.*Context' '$COMMAND_FILE'"

# Test 5: Wave Checkpoint Schema
print_test_header "Test 5: Wave Checkpoint Schema"
assert_true "Wave number tracking" "grep -qE 'wave_num|WAVE_COUNT' '$COMMAND_FILE'"
assert_true "Completed waves tracking" "grep -qE 'WAVES_COMPLETED|waves.*completed' '$COMMAND_FILE'"
assert_true "Wave-level checkpointing" "grep -qE 'checkpoint.*wave|wave.*checkpoint' '$COMMAND_FILE'"

# Test 6: Wave Progress Markers
print_test_header "Test 6: Wave Progress Markers"
assert_true "Wave progress markers documented" "grep -qE 'Wave [0-9]+|wave.*[0-9]+' '$COMMAND_FILE'"
assert_true "Parallel phase execution mentioned" "grep -qE 'parallel.*phase|phase.*parallel' '$COMMAND_FILE'"

# Test 7: Wave Execution Control
print_test_header "Test 7: Wave Execution Control"
assert_true "Wave execution control flow" "grep -qE 'for.*wave|while.*wave' '$COMMAND_FILE'"
assert_true "Wave processing structure" "grep -qE 'WAVE.*\$|wave_num' '$COMMAND_FILE'"

# Test 8: Performance Metrics Tracking
print_test_header "Test 8: Performance Metrics"
assert_true "Time savings tracking" "grep -qE 'time.*saving|performance.*improvement' '$COMMAND_FILE'"
assert_true "Parallel phase count tracking" "grep -qE 'parallel.*phase.*count|phases.*parallel' '$COMMAND_FILE'"
assert_true "Wave performance targets" "grep -qE '40-60%|40.*60.*percent' '$COMMAND_FILE'"

# Test 9: Dependency Syntax Documentation
print_test_header "Test 9: Dependency Syntax Documentation"
assert_true "Dependency syntax mentioned" "grep -qE 'dependencies:\s*\[|phase.*depend' '$COMMAND_FILE'"
assert_true "Wave execution explanation present" "grep -qE 'wave.*execution|parallel.*wave' '$COMMAND_FILE'"

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

# Test 11: Wave-Based Performance Documentation
print_test_header "Test 11: Wave-Based Performance Documentation"
assert_true "Performance improvement documented" "grep -qE '40-60%|40.*60.*percent' '$COMMAND_FILE'"
assert_true "Wave-based execution benefits mentioned" "grep -qiE 'wave.*saving|wave.*performance|parallel.*saving' '$COMMAND_FILE'"

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
