#!/usr/bin/env bash
# Test: Standards Compliance in /coordinate Command
# Category: HIGH - Verifies all architectural standards are met

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_FILE="$SCRIPT_DIR/../commands/coordinate.md"
TEST_NAME="test_coordinate_standards"

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

assert_count_exact() {
  local description="$1"
  local expected="$2"
  local command="$3"
  TESTS_RUN=$((TESTS_RUN + 1))

  local actual
  actual=$(eval "$command")

  if [ "$actual" -eq "$expected" ]; then
    echo -e "${GREEN}✓${NC} $description (expected $expected, got $actual)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description (expected $expected, got $actual)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: No Code-Fenced Task Examples (Critical Standard)
print_test_header "Test 1: No Code-Fenced Task Examples"
assert_false "No code-fenced YAML Task blocks" "grep -Pzo '\`\`\`yaml\s*Task\s*\{' '$COMMAND_FILE'"
assert_false "No code-fenced JSON Task blocks" "grep -Pzo '\`\`\`json\s*Task\s*\{' '$COMMAND_FILE'"
assert_false "No code-fenced Task blocks (any language)" "grep -Pzo '\`\`\`[a-z]*\s*Task\s*\{' '$COMMAND_FILE'"

# Test 2: Imperative Markers Present (Standard 11)
print_test_header "Test 2: Imperative Markers (Standard 11)"
assert_true "EXECUTE NOW markers present" "grep -q 'EXECUTE NOW' '$COMMAND_FILE'"
assert_true "CRITICAL markers present" "grep -q 'CRITICAL:' '$COMMAND_FILE'"
assert_true "EXECUTION-CRITICAL markers present" "grep -q 'EXECUTION-CRITICAL:' '$COMMAND_FILE'"

# Test 3: Behavioral Content Extraction (Standard 12)
print_test_header "Test 3: Behavioral Content Extraction (Standard 12)"
assert_count "Agent behavioral files referenced" 7 "grep -c '.claude/agents/.*\.md' '$COMMAND_FILE'"
assert_count "Behavioral injection pattern used" 5 "grep -c 'Read and follow ALL behavioral guidelines from:' '$COMMAND_FILE'"
assert_false "No large inline behavioral content" "grep -Pzo '(?s)(behavioral|instructions):\s*\|[\s\S]{500,}' '$COMMAND_FILE'"

# Test 4: Verification Checkpoints (Verification-Fallback Pattern)
print_test_header "Test 4: Verification Checkpoints"
assert_count "MANDATORY VERIFICATION checkpoints" 7 "grep -c 'MANDATORY VERIFICATION\|Verification checkpoint' '$COMMAND_FILE'"
assert_count "File existence checks" 5 "grep -c '\[ -f.*\]\|test -f\|file exists' '$COMMAND_FILE'"
assert_count "Verification patterns" 2 "grep -ic 'verif\|check.*file\|ensure.*file' '$COMMAND_FILE'"

# Test 5: Metadata Extraction (Forward Message Pattern)
print_test_header "Test 5: Metadata Extraction Pattern"
assert_true "REPORT_CREATED signal present" "grep -q 'REPORT_CREATED:' '$COMMAND_FILE'"
assert_true "PLAN_CREATED signal present" "grep -q 'PLAN_CREATED:' '$COMMAND_FILE'"
assert_count "Metadata extraction references" 5 "grep -c 'metadata.*extract\|extract.*metadata' '$COMMAND_FILE'"
assert_count "Completion signal patterns" 3 "grep -c '_CREATED:\|_COMPLETE:' '$COMMAND_FILE'"

# Test 6: Context Pruning Integration
print_test_header "Test 6: Context Pruning"
assert_true "Context-pruning.sh library sourced" "grep -q 'source.*context-pruning.sh' '$COMMAND_FILE'"
assert_count "Context pruning implemented" 1 "grep -c 'prune.*context\|apply_pruning_policy\|context.*prun' '$COMMAND_FILE'"
assert_true "Context reduction target documented" "grep -qE '<30%.*context|30.*percent.*context' '$COMMAND_FILE'"

# Test 7: Clear Error Messages (Fail-Fast Pattern)
print_test_header "Test 7: Clear Error Messages"
assert_count "ERROR markers present" 5 "grep -ic 'ERROR:' '$COMMAND_FILE'"
assert_count "Diagnostic information" 3 "grep -ic 'DIAGNOSTIC\|diagnostic' '$COMMAND_FILE'"
assert_false "No retry logic present" "grep -q 'retry.*template\|retry_with_backoff\|for attempt in' '$COMMAND_FILE'"
assert_false "No fallback mechanisms" "grep -qE 'FALLBACK.*MECHANISM|fallback.*implementation' '$COMMAND_FILE'"

# Test 8: Checkpoint Recovery Pattern
print_test_header "Test 8: Checkpoint Recovery Pattern"
assert_true "Checkpoint-utils.sh library referenced" "grep -q 'checkpoint-utils.sh' '$COMMAND_FILE'"

# Test 9: Library Dependencies
print_test_header "Test 9: Required Library Dependencies"
# Updated to support conditional library loading (REQUIRED_LIBS arrays) in addition to direct source
assert_true "unified-location-detection.sh referenced" "grep -q 'unified-location-detection.sh' '$COMMAND_FILE'"
assert_true "dependency-analyzer.sh referenced" "grep -q 'dependency-analyzer.sh' '$COMMAND_FILE'"
assert_true "workflow-detection.sh referenced" "grep -q 'workflow-detection.sh' '$COMMAND_FILE'"
assert_true "unified-logger.sh referenced" "grep -q 'unified-logger.sh' '$COMMAND_FILE'"
assert_true "error-handling.sh referenced" "grep -q 'error-handling.sh' '$COMMAND_FILE'"

# Test 10: Agent Behavioral Files
print_test_header "Test 10: Agent Behavioral File References"
AGENT_DIR="$SCRIPT_DIR/../agents"
assert_true "research-specialist.md exists" "[ -f '$AGENT_DIR/research-specialist.md' ]"
assert_true "plan-architect.md exists" "[ -f '$AGENT_DIR/plan-architect.md' ]"
assert_true "implementer-coordinator.md exists" "[ -f '$AGENT_DIR/implementer-coordinator.md' ]"
assert_true "test-specialist.md exists" "[ -f '$AGENT_DIR/test-specialist.md' ]"
assert_true "debug-analyst.md exists" "[ -f '$AGENT_DIR/debug-analyst.md' ]"
assert_true "doc-writer.md exists" "[ -f '$AGENT_DIR/doc-writer.md' ]"

# Test 11: File Size Budget Compliance
print_test_header "Test 11: File Size Budget"
LINE_COUNT=$(wc -l < "$COMMAND_FILE")
echo "Current file size: $LINE_COUNT lines"

TESTS_RUN=$((TESTS_RUN + 1))
if [ "$LINE_COUNT" -ge 2500 ] && [ "$LINE_COUNT" -le 3000 ]; then
  echo -e "${GREEN}✓${NC} File size within budget (2,500-3,000 lines)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC} File size outside budget: $LINE_COUNT lines (target: 2,500-3,000)"
  if [ "$LINE_COUNT" -lt 2500 ]; then
    echo "  Note: File is smaller than target but acceptable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
fi

# Test 12: Progress Markers
print_test_header "Test 12: Progress Streaming"
assert_count "Progress markers present" 1 "grep -c 'PROGRESS:' '$COMMAND_FILE'"

# Test 13: Documentation Standards
print_test_header "Test 13: Documentation Standards"
assert_true "Command description present" "head -n 50 '$COMMAND_FILE' | grep -qiE 'description:|overview|purpose'"
assert_true "Workflow overview present" "grep -qiE 'workflow.*overview|orchestrates.*workflow' '$COMMAND_FILE'"
assert_true "Library requirements documented" "grep -qiE 'Library.*Requirement|Required.*Librar|Library.*Dependenc' '$COMMAND_FILE'"

# Test 14: Anti-Pattern Avoidance
print_test_header "Test 14: Anti-Pattern Avoidance"
assert_false "No YAML blocks with Task invocations" "grep -Pzo '\`\`\`yaml[\s\S]{0,100}Task\s*\{' '$COMMAND_FILE'"
assert_false "No documentation-only agent blocks" "grep -Pzo '(?s)Example.*agent.*invocation:[\s\S]{0,50}\`\`\`' '$COMMAND_FILE'"
assert_false "No retry_with_backoff calls" "grep -q 'retry_with_backoff' '$COMMAND_FILE'"

# Summary
print_test_header "Test Summary"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All standards compliance tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some standards compliance tests failed.${NC}"
  exit 1
fi
