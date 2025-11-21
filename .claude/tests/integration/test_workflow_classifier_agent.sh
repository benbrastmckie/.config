#!/bin/bash
# Test Suite: Workflow Classifier Agent Compliance
# Tests Standard 0.5 compliance and structure validation

# Note: NOT using set -e to allow all tests to run even if some fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENT_FILE="$PROJECT_ROOT/agents/workflow-classifier.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS

# Helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  FAILED_TESTS+=("$1")
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

section() {
  echo ""
  echo "=== $1 ==="
  echo ""
}

# Pre-flight check
if [ ! -f "$AGENT_FILE" ]; then
  echo "SKIP: Agent file not found: $AGENT_FILE (workflow-classifier agent was archived)"
  exit 0  # Exit successfully to indicate skip, not failure
fi

info "Testing agent file: $AGENT_FILE"
echo ""

#############################################
# Test Category 1: YAML Front Matter
#############################################

section "YAML Front Matter Validation"

# Test 1.1: YAML block exists
if grep -q "^---$" "$AGENT_FILE"; then
  pass "YAML front matter block exists"
else
  fail "YAML front matter block missing"
fi

# Test 1.2: allowed-tools field
if grep -q "^allowed-tools: None$" "$AGENT_FILE"; then
  pass "allowed-tools field correct (None)"
else
  fail "allowed-tools field missing or incorrect"
fi

# Test 1.3: description field
if grep -q "^description:.*" "$AGENT_FILE"; then
  DESCRIPTION=$(grep "^description:" "$AGENT_FILE" | sed 's/^description: *//')
  if [ ${#DESCRIPTION} -gt 20 ]; then
    pass "description field exists and is descriptive (${#DESCRIPTION} chars)"
  else
    fail "description field too short (<20 chars)"
  fi
else
  fail "description field missing"
fi

# Test 1.4: model field
if grep -q "^model: haiku$" "$AGENT_FILE"; then
  pass "model field correct (haiku)"
else
  fail "model field missing or incorrect"
fi

# Test 1.5: model-justification field
if grep -q "^model-justification:.*" "$AGENT_FILE"; then
  JUSTIFICATION=$(grep "^model-justification:" "$AGENT_FILE" | sed 's/^model-justification: *//')
  if [ ${#JUSTIFICATION} -gt 20 ]; then
    pass "model-justification field exists and is descriptive (${#JUSTIFICATION} chars)"
  else
    fail "model-justification field too short (<20 chars)"
  fi
else
  fail "model-justification field missing"
fi

# Test 1.6: fallback-model field
if grep -q "^fallback-model:.*" "$AGENT_FILE"; then
  pass "fallback-model field exists"
else
  fail "fallback-model field missing"
fi

#############################################
# Test Category 2: Imperative Language
#############################################

section "Imperative Language Validation"

# Test 2.1: YOU MUST pattern count
YOU_MUST_COUNT=$(grep -c "YOU MUST\|EXECUTE NOW\|REQUIRED\|ABSOLUTE REQUIREMENT\|MANDATORY" "$AGENT_FILE" || true)
if [ "$YOU_MUST_COUNT" -gt 10 ]; then
  pass "Imperative language present (${YOU_MUST_COUNT} occurrences)"
else
  fail "Insufficient imperative language (${YOU_MUST_COUNT} < 10 occurrences)"
fi

# Test 2.2: Anti-pattern check (first-person)
FIRST_PERSON_COUNT=$(grep -c "^I am\|^I will\|^I can\|^I should" "$AGENT_FILE" || true)
if [ "$FIRST_PERSON_COUNT" -eq 0 ]; then
  pass "No first-person anti-patterns found"
else
  fail "First-person anti-patterns found (${FIRST_PERSON_COUNT} occurrences)"
fi

# Test 2.3: CRITICAL INSTRUCTIONS section
if grep -q "^\*\*CRITICAL INSTRUCTIONS\*\*:" "$AGENT_FILE"; then
  pass "CRITICAL INSTRUCTIONS section exists"
else
  fail "CRITICAL INSTRUCTIONS section missing"
fi

#############################################
# Test Category 3: Sequential Steps
#############################################

section "Sequential Steps Validation"

# Test 3.1: STEP 1 exists
if grep -q "### STEP 1" "$AGENT_FILE"; then
  pass "STEP 1 exists"
else
  fail "STEP 1 missing"
fi

# Test 3.2: STEP 2 exists
if grep -q "### STEP 2" "$AGENT_FILE"; then
  pass "STEP 2 exists"
else
  fail "STEP 2 missing"
fi

# Test 3.3: STEP 3 exists
if grep -q "### STEP 3" "$AGENT_FILE"; then
  pass "STEP 3 exists"
else
  fail "STEP 3 missing"
fi

# Test 3.4: STEP 4 exists
if grep -q "### STEP 4" "$AGENT_FILE"; then
  pass "STEP 4 exists"
else
  fail "STEP 4 missing"
fi

# Test 3.5: CHECKPOINT markers
CHECKPOINT_COUNT=$(grep -c "^\*\*CHECKPOINT\*\*:" "$AGENT_FILE" || true)
if [ "$CHECKPOINT_COUNT" -gt 0 ]; then
  pass "CHECKPOINT markers present (${CHECKPOINT_COUNT} occurrences)"
else
  fail "No CHECKPOINT markers found"
fi

#############################################
# Test Category 4: Edge Cases Documentation
#############################################

section "Edge Cases Documentation"

# Test 4.1: Edge Case section exists
if grep -q "## Edge Case" "$AGENT_FILE"; then
  pass "Edge Case section exists"
else
  fail "Edge Case section missing"
fi

# Test 4.2: Multiple edge cases documented
EDGE_CASE_COUNT=$(grep -c "### Edge Case" "$AGENT_FILE" || true)
if [ "$EDGE_CASE_COUNT" -ge 3 ]; then
  pass "Multiple edge cases documented (${EDGE_CASE_COUNT} cases)"
else
  fail "Insufficient edge cases documented (${EDGE_CASE_COUNT} < 3)"
fi

# Test 4.3: Ambiguous workflow edge case
if grep -q -i "ambiguous\|quoted.*keywords\|negation" "$AGENT_FILE"; then
  pass "Ambiguous/complex edge cases documented"
else
  fail "Ambiguous/complex edge cases missing"
fi

#############################################
# Test Category 5: JSON Schema Documentation
#############################################

section "JSON Schema Documentation"

# Test 5.1: workflow_type field documented
if grep -q "workflow_type" "$AGENT_FILE"; then
  pass "workflow_type field documented"
else
  fail "workflow_type field missing from documentation"
fi

# Test 5.2: research_complexity field documented
if grep -q "research_complexity" "$AGENT_FILE"; then
  pass "research_complexity field documented"
else
  fail "research_complexity field missing from documentation"
fi

# Test 5.3: research_topics field documented
if grep -q "research_topics" "$AGENT_FILE"; then
  pass "research_topics field documented"
else
  fail "research_topics field missing from documentation"
fi

# Test 5.4: All workflow types documented
WORKFLOW_TYPES=("research-only" "research-and-plan" "research-and-revise" "full-implementation" "debug-only")
MISSING_TYPES=()
for TYPE in "${WORKFLOW_TYPES[@]}"; do
  if ! grep -q "$TYPE" "$AGENT_FILE"; then
    MISSING_TYPES+=("$TYPE")
  fi
done

if [ ${#MISSING_TYPES[@]} -eq 0 ]; then
  pass "All workflow types documented (${#WORKFLOW_TYPES[@]} types)"
else
  fail "Missing workflow types: ${MISSING_TYPES[*]}"
fi

# Test 5.5: Topic structure fields documented
TOPIC_FIELDS=("short_name" "detailed_description" "filename_slug" "research_focus")
MISSING_FIELDS=()
for FIELD in "${TOPIC_FIELDS[@]}"; do
  if ! grep -q "$FIELD" "$AGENT_FILE"; then
    MISSING_FIELDS+=("$FIELD")
  fi
done

if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
  pass "All topic structure fields documented (${#TOPIC_FIELDS[@]} fields)"
else
  fail "Missing topic fields: ${MISSING_FIELDS[*]}"
fi

#############################################
# Test Category 6: Validation Rules
#############################################

section "Validation Rules Documentation"

# Test 6.1: Confidence range validation
if grep -q "confidence.*0\.0.*1\.0\|confidence.*float.*0-1" "$AGENT_FILE"; then
  pass "Confidence range validation documented"
else
  fail "Confidence range validation missing"
fi

# Test 6.2: Research complexity range
if grep -q "research_complexity.*1.*4\|complexity.*1-4" "$AGENT_FILE"; then
  pass "Research complexity range documented"
else
  fail "Research complexity range missing"
fi

# Test 6.3: Filename slug regex
if grep -q "filename_slug.*\^.*\$\|lowercase.*underscore" "$AGENT_FILE"; then
  pass "Filename slug validation documented"
else
  fail "Filename slug validation missing"
fi

# Test 6.4: Description length validation
if grep -q "detailed_description.*50.*500\|description.*character" "$AGENT_FILE"; then
  pass "Description length validation documented"
else
  fail "Description length validation missing"
fi

#############################################
# Test Category 7: Completion Criteria
#############################################

section "Completion Criteria Checklist"

# Test 7.1: Completion criteria section exists
if grep -q "## Completion Criteria" "$AGENT_FILE"; then
  pass "Completion Criteria section exists"
else
  fail "Completion Criteria section missing"
fi

# Test 7.2: Checklist items present
CHECKLIST_COUNT=$(grep -c "^- \[ \]" "$AGENT_FILE" || true)
if [ "$CHECKLIST_COUNT" -gt 5 ]; then
  pass "Completion checklist present (${CHECKLIST_COUNT} items)"
else
  fail "Insufficient checklist items (${CHECKLIST_COUNT} < 5)"
fi

#############################################
# Test Category 8: Anti-Patterns Section
#############################################

section "Anti-Patterns Documentation"

# Test 8.1: Anti-patterns section exists
if grep -q "## Anti-Pattern\|Anti-Patterns to Avoid" "$AGENT_FILE"; then
  pass "Anti-Patterns section exists"
else
  fail "Anti-Patterns section missing"
fi

# Test 8.2: Wrong/Correct examples
WRONG_COUNT=$(grep -c "❌ WRONG\|WRONG:" "$AGENT_FILE" || true)
CORRECT_COUNT=$(grep -c "✓ CORRECT\|CORRECT:" "$AGENT_FILE" || true)

if [ "$WRONG_COUNT" -gt 0 ] && [ "$CORRECT_COUNT" -gt 0 ]; then
  pass "Anti-pattern examples documented (${WRONG_COUNT} wrong, ${CORRECT_COUNT} correct)"
else
  fail "Insufficient anti-pattern examples"
fi

#############################################
# Test Category 9: Output Format
#############################################

section "Output Format Specification"

# Test 9.1: CLASSIFICATION_COMPLETE signal documented
if grep -q "CLASSIFICATION_COMPLETE:" "$AGENT_FILE"; then
  pass "CLASSIFICATION_COMPLETE signal documented"
else
  fail "CLASSIFICATION_COMPLETE signal missing"
fi

# Test 9.2: JSON output example
if grep -q '```json\|```\n{' "$AGENT_FILE"; then
  pass "JSON output examples present"
else
  fail "JSON output examples missing"
fi

#############################################
# Test Category 10: File Structure
#############################################

section "File Structure Validation"

# Test 10.1: File size reasonable
FILE_SIZE=$(wc -l < "$AGENT_FILE")
if [ "$FILE_SIZE" -ge 300 ] && [ "$FILE_SIZE" -le 800 ]; then
  pass "File size reasonable (${FILE_SIZE} lines, 300-800 expected)"
elif [ "$FILE_SIZE" -lt 300 ]; then
  fail "File too short (${FILE_SIZE} < 300 lines)"
else
  fail "File too long (${FILE_SIZE} > 800 lines)"
fi

# Test 10.2: No trailing whitespace on critical lines
if grep -q "^---[[:space:]]\+$\|^STEP.*[[:space:]]\+$" "$AGENT_FILE"; then
  fail "Trailing whitespace found on critical lines"
else
  pass "No trailing whitespace on critical lines"
fi

#############################################
# Summary
#############################################

section "Test Summary"

echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
  echo ""
  echo "Failed tests:"
  for TEST in "${FAILED_TESTS[@]}"; do
    echo "  - $TEST"
  done
fi

echo ""

# Calculate compliance score
COMPLIANCE_SCORE=$((TESTS_PASSED * 100 / TESTS_RUN))
echo "Compliance Score: ${COMPLIANCE_SCORE}% ($TESTS_PASSED / $TESTS_RUN)"

if [ $COMPLIANCE_SCORE -ge 95 ]; then
  echo -e "${GREEN}✓ PASSED: Agent meets Standard 0.5 requirements (≥95%)${NC}"
  exit 0
elif [ $COMPLIANCE_SCORE -ge 80 ]; then
  echo -e "${YELLOW}⚠ WARNING: Agent compliance below target ($COMPLIANCE_SCORE% < 95%)${NC}"
  exit 1
else
  echo -e "${RED}✗ FAILED: Agent compliance insufficient ($COMPLIANCE_SCORE% < 80%)${NC}"
  exit 1
fi
