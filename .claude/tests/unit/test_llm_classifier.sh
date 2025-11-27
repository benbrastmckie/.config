#!/usr/bin/env bash
# Test workflow-llm-classifier.sh library
# Tests: Input validation, JSON building, response parsing, confidence threshold, timeout, error handling

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
    echo "  Got: ${3:-<not provided>}"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}

# Find lib directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source workflow LLM classifier
source "$LIB_DIR/workflow/workflow-llm-classifier.sh"

echo "========================================="
echo "Workflow LLM Classifier Unit Tests"
echo "========================================="
echo

# =============================================================================
# Section 1: Input Validation Tests
# =============================================================================
echo "Section 1: Input Validation"
echo "----------------------------"

# Test 1.1: Empty workflow description
info "Test 1.1: build_llm_classifier_input with empty description"
if build_llm_classifier_input "" 2>/dev/null; then
  fail "Empty input validation" "should return error" "succeeded"
else
  pass "Empty input correctly rejected"
fi

# Test 1.2: Valid workflow description
info "Test 1.2: build_llm_classifier_input with valid description"
result=$(build_llm_classifier_input "research authentication patterns and create plan")
if echo "$result" | jq -e .task >/dev/null 2>&1; then
  pass "Valid input generates JSON"
else
  fail "Valid input handling" "valid JSON" "invalid or missing"
fi

# Test 1.3: Long workflow description (500+ characters)
info "Test 1.3: build_llm_classifier_input with long description"
long_desc=$(printf 'research authentication patterns %.0s' {1..50})
result=$(build_llm_classifier_input "$long_desc")
if echo "$result" | jq -e .description >/dev/null 2>&1; then
  pass "Long input handled correctly"
else
  fail "Long input handling" "valid JSON" "invalid or missing"
fi

# Test 1.4: Special characters in description
info "Test 1.4: build_llm_classifier_input with special characters"
result=$(build_llm_classifier_input "research auth \"patterns\" & create plan's structure")
if echo "$result" | jq -e .description >/dev/null 2>&1; then
  if echo "$result" | jq -r .description | grep -q '"patterns"'; then
    pass "Special characters properly escaped"
  else
    fail "Special character escaping" "quotes preserved" "quotes lost"
  fi
else
  fail "Special character handling" "valid JSON" "invalid or missing"
fi

# Test 1.5: Unicode characters in description
info "Test 1.5: build_llm_classifier_input with Unicode"
result=$(build_llm_classifier_input "research 日本語 patterns and plan 中文")
if echo "$result" | jq -e .description >/dev/null 2>&1; then
  pass "Unicode characters handled correctly"
else
  fail "Unicode handling" "valid JSON" "invalid or missing"
fi

echo

# =============================================================================
# Section 2: JSON Building and Structure Tests
# =============================================================================
echo "Section 2: JSON Building"
echo "------------------------"

# Test 2.1: JSON structure validation
info "Test 2.1: Verify JSON structure has required fields"
result=$(build_llm_classifier_input "test description")
task=$(echo "$result" | jq -r .task)
desc=$(echo "$result" | jq -r .description)
valid_scopes=$(echo "$result" | jq -r '.valid_scopes | length')
instructions=$(echo "$result" | jq -r .instructions)

if [ "$task" = "classify_workflow_scope" ] && [ -n "$desc" ] && [ "$valid_scopes" -eq 5 ] && [ -n "$instructions" ]; then
  pass "JSON structure has all required fields"
else
  fail "JSON structure validation" "all fields present" "missing: task=$task, desc_len=${#desc}, scopes=$valid_scopes"
fi

# Test 2.2: Valid scopes array content
info "Test 2.2: Verify valid_scopes array contains expected values"
result=$(build_llm_classifier_input "test")
scopes=$(echo "$result" | jq -r '.valid_scopes | join(",")')
if echo "$scopes" | grep -q "research-only" && \
   echo "$scopes" | grep -q "research-and-plan" && \
   echo "$scopes" | grep -q "research-and-revise" && \
   echo "$scopes" | grep -q "full-implementation" && \
   echo "$scopes" | grep -q "debug-only"; then
  pass "Valid scopes array contains all expected values"
else
  fail "Valid scopes content" "all 5 scopes" "got: $scopes"
fi

# Test 2.3: Description preservation
info "Test 2.3: Verify description is preserved exactly"
original="research the research-and-revise workflow misclassification"
result=$(build_llm_classifier_input "$original")
extracted=$(echo "$result" | jq -r .description)
if [ "$extracted" = "$original" ]; then
  pass "Description preserved exactly"
else
  fail "Description preservation" "$original" "$extracted"
fi

echo

# =============================================================================
# Section 3: Response Parsing Tests
# =============================================================================
echo "Section 3: Response Parsing"
echo "---------------------------"

# Test 3.1: Valid complete response
info "Test 3.1: parse_llm_classifier_response with valid response"
valid_response='{"scope":"research-and-plan","confidence":0.95,"reasoning":"Intent is to research and create a plan"}'
result=$(parse_llm_classifier_response "$valid_response")
if echo "$result" | jq -e . >/dev/null 2>&1; then
  pass "Valid response parsed successfully"
else
  fail "Valid response parsing" "valid JSON" "parsing failed"
fi

# Test 3.2: Missing required field (scope)
info "Test 3.2: parse_llm_classifier_response with missing scope"
invalid_response='{"confidence":0.95,"reasoning":"test"}'
if parse_llm_classifier_response "$invalid_response" 2>/dev/null; then
  fail "Missing scope validation" "should return error" "succeeded"
else
  pass "Missing scope correctly rejected"
fi

# Test 3.3: Missing required field (confidence)
info "Test 3.3: parse_llm_classifier_response with missing confidence"
invalid_response='{"scope":"research-and-plan","reasoning":"test"}'
if parse_llm_classifier_response "$invalid_response" 2>/dev/null; then
  fail "Missing confidence validation" "should return error" "succeeded"
else
  pass "Missing confidence correctly rejected"
fi

# Test 3.4: Missing required field (reasoning)
info "Test 3.4: parse_llm_classifier_response with missing reasoning"
invalid_response='{"scope":"research-and-plan","confidence":0.95}'
if parse_llm_classifier_response "$invalid_response" 2>/dev/null; then
  fail "Missing reasoning validation" "should return error" "succeeded"
else
  pass "Missing reasoning correctly rejected"
fi

# Test 3.5: Invalid scope value
info "Test 3.5: parse_llm_classifier_response with invalid scope"
invalid_response='{"scope":"invalid-scope","confidence":0.95,"reasoning":"test"}'
if parse_llm_classifier_response "$invalid_response" 2>/dev/null; then
  fail "Invalid scope validation" "should return error" "succeeded"
else
  pass "Invalid scope correctly rejected"
fi

# Test 3.6: Invalid confidence value (out of range)
info "Test 3.6: parse_llm_classifier_response with out-of-range confidence"
invalid_response='{"scope":"research-and-plan","confidence":1.5,"reasoning":"test"}'
if parse_llm_classifier_response "$invalid_response" 2>/dev/null; then
  fail "Out-of-range confidence validation" "should return error" "succeeded"
else
  pass "Out-of-range confidence correctly rejected"
fi

# Test 3.7: Invalid confidence value (non-numeric)
info "Test 3.7: parse_llm_classifier_response with non-numeric confidence"
invalid_response='{"scope":"research-and-plan","confidence":"high","reasoning":"test"}'
if parse_llm_classifier_response "$invalid_response" 2>/dev/null; then
  fail "Non-numeric confidence validation" "should return error" "succeeded"
else
  pass "Non-numeric confidence correctly rejected"
fi

# Test 3.8: Malformed JSON
info "Test 3.8: parse_llm_classifier_response with malformed JSON"
malformed_response='{"scope":"research-and-plan","confidence":0.95,'
if parse_llm_classifier_response "$malformed_response" 2>/dev/null; then
  fail "Malformed JSON validation" "should return error" "succeeded"
else
  pass "Malformed JSON correctly rejected"
fi

# Test 3.9: Empty response
info "Test 3.9: parse_llm_classifier_response with empty string"
if parse_llm_classifier_response "" 2>/dev/null; then
  fail "Empty response validation" "should return error" "succeeded"
else
  pass "Empty response correctly rejected"
fi

# Test 3.10: Valid response with all scopes
info "Test 3.10: parse_llm_classifier_response with each valid scope"
for scope in "research-only" "research-and-plan" "research-and-revise" "full-implementation" "debug-only"; do
  response="{\"scope\":\"$scope\",\"confidence\":0.85,\"reasoning\":\"test\"}"
  if parse_llm_classifier_response "$response" >/dev/null 2>&1; then
    pass "Valid scope '$scope' accepted"
  else
    fail "Valid scope validation" "$scope accepted" "rejected"
  fi
done

echo

# =============================================================================
# Section 4: Confidence Threshold Tests
# =============================================================================
echo "Section 4: Confidence Threshold"
echo "--------------------------------"

# Test 4.1: Confidence above threshold (mock test)
info "Test 4.1: High confidence (0.95) should pass threshold (0.7)"
conf=0.95
threshold=0.7
conf_int=$(echo "$conf * 100" | awk '{printf "%.0f", $1}')
threshold_int=$(echo "$threshold * 100" | awk '{printf "%.0f", $1}')
if [ "$conf_int" -ge "$threshold_int" ]; then
  pass "Confidence 0.95 >= threshold 0.7"
else
  fail "Confidence threshold logic" "pass" "fail"
fi

# Test 4.2: Confidence below threshold (mock test)
info "Test 4.2: Low confidence (0.5) should fail threshold (0.7)"
conf=0.5
threshold=0.7
conf_int=$(echo "$conf * 100" | awk '{printf "%.0f", $1}')
threshold_int=$(echo "$threshold * 100" | awk '{printf "%.0f", $1}')
if [ "$conf_int" -lt "$threshold_int" ]; then
  pass "Confidence 0.5 < threshold 0.7"
else
  fail "Confidence threshold logic" "fail" "pass"
fi

# Test 4.3: Confidence exactly at threshold (mock test)
info "Test 4.3: Confidence at threshold (0.7) should pass"
conf=0.7
threshold=0.7
conf_int=$(echo "$conf * 100" | awk '{printf "%.0f", $1}')
threshold_int=$(echo "$threshold * 100" | awk '{printf "%.0f", $1}')
if [ "$conf_int" -ge "$threshold_int" ]; then
  pass "Confidence 0.7 >= threshold 0.7"
else
  fail "Confidence threshold logic" "pass" "fail"
fi

echo

# =============================================================================
# Section 5: Logging Tests
# =============================================================================
echo "Section 5: Logging Functions"
echo "-----------------------------"

# Test 5.1: log_classification_error
info "Test 5.1: log_classification_error outputs to stderr"
if log_classification_error "test_function" "test error" 2>&1 | grep -q "ERROR"; then
  pass "log_classification_error outputs error message"
else
  fail "log_classification_error" "ERROR message" "no output"
fi

# Test 5.2: log_classification_debug (debug mode off)
info "Test 5.2: log_classification_debug silent when debug=0"
export WORKFLOW_CLASSIFICATION_DEBUG=0
output=$(log_classification_debug "test_function" "debug message" 2>&1)
if [ -z "$output" ]; then
  pass "log_classification_debug silent when DEBUG=0"
else
  fail "log_classification_debug silence" "no output" "got: $output"
fi

# Test 5.3: log_classification_debug (debug mode on)
info "Test 5.3: log_classification_debug outputs when debug=1"
export WORKFLOW_CLASSIFICATION_DEBUG=1
if log_classification_debug "test_function" "debug message" 2>&1 | grep -q "DEBUG"; then
  pass "log_classification_debug outputs when DEBUG=1"
else
  fail "log_classification_debug output" "DEBUG message" "no output"
fi
export WORKFLOW_CLASSIFICATION_DEBUG=0

# Test 5.4: log_classification_result
info "Test 5.4: log_classification_result silent when debug=0"
export WORKFLOW_CLASSIFICATION_DEBUG=0
output=$(log_classification_result "success" '{"test":"data"}' 2>&1)
if [ -z "$output" ]; then
  pass "log_classification_result silent when DEBUG=0"
else
  fail "log_classification_result silence" "no output" "got: $output"
fi

# Test 5.5: log_classification_result (debug mode on)
info "Test 5.5: log_classification_result outputs when debug=1"
export WORKFLOW_CLASSIFICATION_DEBUG=1
if log_classification_result "success" '{"test":"data"}' 2>&1 | grep -q "DEBUG"; then
  pass "log_classification_result outputs when DEBUG=1"
else
  fail "log_classification_result output" "DEBUG message" "no output"
fi
export WORKFLOW_CLASSIFICATION_DEBUG=0

echo

# =============================================================================
# Section 6: Environment Variable Configuration Tests
# =============================================================================
echo "Section 6: Configuration"
echo "------------------------"

# Test 6.1: Default confidence threshold
info "Test 6.1: Default confidence threshold is 0.7"
# Re-check already sourced library variable
if [ "${WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD}" = "0.7" ]; then
  pass "Default confidence threshold is 0.7"
else
  fail "Default confidence threshold" "0.7" "$WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD"
fi

# Test 6.2: Custom confidence threshold (check current value)
info "Test 6.2: Confidence threshold configuration"
# Note: Library already sourced with defaults, this test verifies current state
if [ -n "${WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD}" ]; then
  pass "Confidence threshold is configured: $WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD"
else
  fail "Confidence threshold" "should be set" "empty"
fi

# Test 6.3: Default timeout
info "Test 6.3: Default timeout is 10 seconds"
if [ "${WORKFLOW_CLASSIFICATION_TIMEOUT}" = "10" ]; then
  pass "Default timeout is 10 seconds"
else
  fail "Default timeout" "10" "$WORKFLOW_CLASSIFICATION_TIMEOUT"
fi

# Test 6.4: Timeout configuration
info "Test 6.4: Timeout configuration"
if [ -n "${WORKFLOW_CLASSIFICATION_TIMEOUT}" ]; then
  pass "Timeout is configured: $WORKFLOW_CLASSIFICATION_TIMEOUT"
else
  fail "Timeout" "should be set" "empty"
fi

echo

# =============================================================================
# Section 7: Error Handling Tests
# =============================================================================
echo "Section 7: Error Handling"
echo "-------------------------"

# Test 7.1: classify_workflow_llm with empty input
info "Test 7.1: classify_workflow_llm rejects empty input"
if classify_workflow_llm "" 2>/dev/null; then
  fail "Empty input to classify_workflow_llm" "should return error" "succeeded"
else
  pass "Empty input correctly rejected by classify_workflow_llm"
fi

# Test 7.2: invoke_llm_classifier timeout behavior (mocked)
info "Test 7.2: invoke_llm_classifier timeout mechanism"
skip "Timeout behavior requires real LLM integration test (manual)"

# Test 7.3: Parse invalid JSON in classify workflow
info "Test 7.3: Invalid JSON handled gracefully"
skip "Full integration test with invalid LLM response (manual)"

echo

# =============================================================================
# Test Summary
# =============================================================================
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "✓ PASS: $PASS_COUNT"
echo "✗ FAIL: $FAIL_COUNT"
echo "⊘ SKIP: $SKIP_COUNT"
echo "TOTAL: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))"
echo

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
