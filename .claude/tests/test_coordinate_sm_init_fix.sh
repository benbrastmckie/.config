#!/usr/bin/env bash
# Test Suite: /coordinate Command sm_init Fix Verification
# Created: 2025-11-14
# Purpose: Verify Phase 1-3 implementation of sm_init 5-parameter fix

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0
COORDINATE_FILE="/home/benjamin/.config/.claude/commands/coordinate.md"

echo "=================================="
echo "Testing /coordinate sm_init Fix"
echo "=================================="
echo ""

# Test 1: Verify Phase 0.1 section exists
echo -n "Test 1: Phase 0.1 Workflow Classification section exists... "
if grep -q "## Phase 0.1: Workflow Classification" "$COORDINATE_FILE"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: '## Phase 0.1: Workflow Classification' header"
  ((TESTS_FAILED++))
fi

# Test 2: Verify workflow-classifier agent invocation exists
echo -n "Test 2: workflow-classifier agent invocation present... "
if grep -q "workflow-classifier.md" "$COORDINATE_FILE"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${GREEN}PASS${NC}"
  echo "  Expected: Reference to workflow-classifier.md agent"
  ((TESTS_FAILED++))
fi

# Test 3: Verify sm_init call has 5 parameters
echo -n "Test 3: sm_init called with 5 parameters... "
SM_INIT_LINE=$(grep -n "^sm_init" "$COORDINATE_FILE" | head -1)
if echo "$SM_INIT_LINE" | grep -q '\$WORKFLOW_TYPE.*\$RESEARCH_COMPLEXITY.*\$RESEARCH_TOPICS_JSON'; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: sm_init with WORKFLOW_TYPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON parameters"
  echo "  Found: $SM_INIT_LINE"
  ((TESTS_FAILED++))
fi

# Test 4: Verify workflow-llm-classifier.sh in research-only REQUIRED_LIBS
echo -n "Test 4: workflow-llm-classifier.sh in research-only REQUIRED_LIBS... "
if grep -A1 "research-only)" "$COORDINATE_FILE" | grep -q "workflow-llm-classifier.sh"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: workflow-llm-classifier.sh in research-only REQUIRED_LIBS array"
  ((TESTS_FAILED++))
fi

# Test 5: Verify workflow-llm-classifier.sh in research-and-plan REQUIRED_LIBS
echo -n "Test 5: workflow-llm-classifier.sh in research-and-plan REQUIRED_LIBS... "
if grep -A1 "research-and-plan|research-and-revise)" "$COORDINATE_FILE" | grep -q "workflow-llm-classifier.sh"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: workflow-llm-classifier.sh in research-and-plan REQUIRED_LIBS array"
  ((TESTS_FAILED++))
fi

# Test 6: Verify workflow-llm-classifier.sh in full-implementation REQUIRED_LIBS
echo -n "Test 6: workflow-llm-classifier.sh in full-implementation REQUIRED_LIBS... "
if grep -A1 "full-implementation)" "$COORDINATE_FILE" | grep -q "workflow-llm-classifier.sh"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: workflow-llm-classifier.sh in full-implementation REQUIRED_LIBS array"
  ((TESTS_FAILED++))
fi

# Test 7: Verify workflow-llm-classifier.sh in debug-only REQUIRED_LIBS
echo -n "Test 7: workflow-llm-classifier.sh in debug-only REQUIRED_LIBS... "
if grep -A1 "debug-only)" "$COORDINATE_FILE" | grep -q "workflow-llm-classifier.sh"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: workflow-llm-classifier.sh in debug-only REQUIRED_LIBS array"
  ((TESTS_FAILED++))
fi

# Test 8: Verify obsolete WORKFLOW_CLASSIFICATION_MODE=regex-only reference removed
echo -n "Test 8: Obsolete regex-only mode reference removed... "
if grep -q "WORKFLOW_CLASSIFICATION_MODE=regex-only" "$COORDINATE_FILE"; then
  echo -e "${RED}FAIL${NC}"
  echo "  Found obsolete reference to WORKFLOW_CLASSIFICATION_MODE=regex-only"
  ((TESTS_FAILED++))
else
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
fi

# Test 9: Verify WORKFLOW_TYPE variable extraction exists
echo -n "Test 9: WORKFLOW_TYPE extraction from classification JSON... "
if grep -q "WORKFLOW_TYPE=.*jq.*workflow_type" "$COORDINATE_FILE"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: WORKFLOW_TYPE extraction using jq"
  ((TESTS_FAILED++))
fi

# Test 10: Verify RESEARCH_COMPLEXITY variable extraction exists
echo -n "Test 10: RESEARCH_COMPLEXITY extraction from classification JSON... "
if grep -q "RESEARCH_COMPLEXITY=.*jq.*research_complexity" "$COORDINATE_FILE"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: RESEARCH_COMPLEXITY extraction using jq"
  ((TESTS_FAILED++))
fi

# Test 11: Verify RESEARCH_TOPICS_JSON variable extraction exists
echo -n "Test 11: RESEARCH_TOPICS_JSON extraction from classification JSON... "
if grep -q "RESEARCH_TOPICS_JSON=.*jq.*research_topics" "$COORDINATE_FILE"; then
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: RESEARCH_TOPICS_JSON extraction using jq"
  ((TESTS_FAILED++))
fi

# Test 12: Verify verification checkpoints preserved
echo -n "Test 12: Original verification checkpoints preserved... "
CHECKPOINT_COUNT=$(grep -c "VERIFICATION CHECKPOINT" "$COORDINATE_FILE")
if [ "$CHECKPOINT_COUNT" -ge 5 ]; then
  echo -e "${GREEN}PASS${NC} (found $CHECKPOINT_COUNT checkpoints)"
  ((TESTS_PASSED++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected: ≥5 verification checkpoints, found: $CHECKPOINT_COUNT"
  ((TESTS_FAILED++))
fi

# Summary
echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
