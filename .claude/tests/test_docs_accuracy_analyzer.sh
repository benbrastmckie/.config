#!/usr/bin/env bash
# Test Suite: Documentation Accuracy Analyzer
# Tests agent creation, metadata extraction, and workflow integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test result tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo -e "  ${YELLOW}Reason${NC}: $2"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

echo "=== Documentation Accuracy Analyzer Test Suite ==="
echo ""

# Test 1: Agent behavioral file exists and has correct frontmatter
echo "Test 1: Agent file exists with Opus 4.5 frontmatter"
if [ -f "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md" ]; then
  if grep -q "model: opus-4.5" "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md"; then
    pass "Agent file exists with Opus 4.5 model"
  else
    fail "Agent file missing Opus 4.5 model" "frontmatter incorrect"
  fi
else
  fail "Agent file does not exist" "expected at .claude/agents/docs-accuracy-analyzer.md"
fi

# Test 2: Agent file size compliance
echo "Test 2: Agent file size compliance (<450 lines)"
AGENT_LINES=$(wc -l < "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md" 2>/dev/null || echo "0")
if [ "$AGENT_LINES" -gt 0 ] && [ "$AGENT_LINES" -lt 450 ]; then
  pass "Agent file size: $AGENT_LINES lines (under 450)"
else
  fail "Agent file size: $AGENT_LINES lines" "should be <450 lines"
fi

# Test 3: Six-step execution process present
echo "Test 3: Six-step execution process (STEP 1-6 headings)"
STEP_COUNT=$(grep -c "^### STEP" "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md" 2>/dev/null || echo "0")
if [ "$STEP_COUNT" -ge 6 ]; then
  pass "Found $STEP_COUNT execution steps (≥6)"
else
  fail "Found only $STEP_COUNT execution steps" "expected ≥6 steps"
fi

# Test 4: Completion signal format validation
echo "Test 4: Completion signal format (REPORT_CREATED: path)"
if grep -q "REPORT_CREATED:" "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md"; then
  pass "Completion signal format present"
else
  fail "Completion signal missing" "should contain REPORT_CREATED:"
fi

# Test 5: Mock invocation test (skip for now - would require full agent invocation)
echo "Test 5: Mock invocation (skipped - requires agent runtime)"
echo -e "${YELLOW}⊘ SKIP${NC}: Mock invocation test (requires full agent execution)"
((TESTS_RUN++))

# Test 6: Report structure validation (check template sections in agent)
echo "Test 6: Report structure template (9+ sections)"
SECTION_COUNT=$(grep "^##" "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md" | grep -c -E "(Metadata|Executive Summary|Current Accuracy|Completeness|Consistency|Timeliness|Usability|Clarity|Quality Improvement|Documentation Optimization)" || echo "0")
if [ "$SECTION_COUNT" -ge 9 ]; then
  pass "Report template has $SECTION_COUNT quality sections (≥9)"
else
  fail "Report template only has $SECTION_COUNT sections" "expected ≥9"
fi

# Test 7: Metadata extraction function exists
echo "Test 7: Metadata extraction function (extract_accuracy_metadata)"
if [ -f "$PROJECT_ROOT/.claude/lib/metadata-extraction.sh" ]; then
  if grep -q "extract_accuracy_metadata()" "$PROJECT_ROOT/.claude/lib/metadata-extraction.sh"; then
    pass "Metadata extraction function exists"
  else
    fail "Function extract_accuracy_metadata not found" "missing in metadata-extraction.sh"
  fi
else
  fail "metadata-extraction.sh not found" "library file missing"
fi

# Test 8: Context reduction capability (test function)
echo "Test 8: Context reduction test (metadata extraction)"
source "$PROJECT_ROOT/.claude/lib/metadata-extraction.sh" 2>/dev/null || {
  fail "Cannot source metadata-extraction.sh" "library error"
  ((TESTS_RUN++))
}

if declare -f extract_accuracy_metadata > /dev/null 2>&1; then
  # Create minimal test report
  TEST_REPORT="/tmp/test_accuracy_minimal_$$.md"
  cat > "$TEST_REPORT" <<'EOF'
# Documentation Accuracy Analysis Report

## Metadata
- Date: 2025-11-14

## Executive Summary
Found 12 critical errors, 8 gaps. Completeness: 85%.

## Current Accuracy State
Errors found.

## Completeness Analysis
Overall Completeness: 85% (102/120)
EOF

  # Extract metadata
  METADATA=$(extract_accuracy_metadata "$TEST_REPORT" 2>/dev/null || echo "{}")

  # Verify metadata structure
  if echo "$METADATA" | jq -e '.title' > /dev/null 2>&1; then
    ERROR_COUNT=$(echo "$METADATA" | jq -r '.error_count' 2>/dev/null || echo "0")
    COMPLETENESS=$(echo "$METADATA" | jq -r '.completeness_pct' 2>/dev/null || echo "0")

    if [ "$ERROR_COUNT" = "12" ] && [ "$COMPLETENESS" = "85" ]; then
      pass "Metadata extraction works (error_count: 12, completeness: 85%)"
    else
      fail "Metadata extraction incomplete" "error_count: $ERROR_COUNT, completeness: $COMPLETENESS"
    fi
  else
    fail "Metadata extraction failed" "invalid JSON output"
  fi

  rm -f "$TEST_REPORT"
else
  fail "Function extract_accuracy_metadata not loaded" "sourcing failed"
fi

# Test 9: Workflow integration (/optimize-claude references accuracy analyzer)
echo "Test 9: Workflow integration (/optimize-claude)"
if [ -f "$PROJECT_ROOT/.claude/commands/optimize-claude.md" ]; then
  if grep -q "docs-accuracy-analyzer" "$PROJECT_ROOT/.claude/commands/optimize-claude.md"; then
    if grep -q "ACCURACY_REPORT_PATH" "$PROJECT_ROOT/.claude/commands/optimize-claude.md"; then
      pass "Workflow integrates accuracy analyzer with ACCURACY_REPORT_PATH"
    else
      fail "ACCURACY_REPORT_PATH not found" "workflow missing path variable"
    fi
  else
    fail "docs-accuracy-analyzer not referenced" "workflow not integrated"
  fi
else
  fail "/optimize-claude command not found" "workflow file missing"
fi

# Test 10: Verification checkpoint (fail-fast pattern)
echo "Test 10: Verification checkpoint (fail-fast when report missing)"
if grep -q "if \[ ! -f.*ACCURACY_REPORT_PATH" "$PROJECT_ROOT/.claude/commands/optimize-claude.md" 2>/dev/null; then
  pass "Fail-fast verification checkpoint present"
else
  fail "Verification checkpoint missing" "should check ACCURACY_REPORT_PATH exists"
fi

# Test 11: Planning integration (cleanup-plan-architect receives accuracy report)
echo "Test 11: Planning integration (cleanup-plan-architect)"
if [ -f "$PROJECT_ROOT/.claude/agents/cleanup-plan-architect.md" ]; then
  if grep -q "ACCURACY_REPORT_PATH" "$PROJECT_ROOT/.claude/agents/cleanup-plan-architect.md"; then
    pass "Planning agent handles accuracy reports"
  else
    fail "Planning agent missing ACCURACY_REPORT_PATH" "not integrated"
  fi
else
  fail "cleanup-plan-architect.md not found" "planning agent missing"
fi

# Test 12: Architectural compliance validation
echo "Test 12: Architectural compliance (Standards 0, 11, 14)"

# Standard 0: Imperative language
IMPERATIVE_COUNT=$(grep -c "YOU MUST\|EXECUTE NOW\|MANDATORY\|CRITICAL\|ABSOLUTE REQUIREMENT" "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md" 2>/dev/null || echo "0")
if [ "$IMPERATIVE_COUNT" -ge 5 ]; then
  pass "Standard 0: Imperative language ($IMPERATIVE_COUNT instances ≥5)"
else
  fail "Standard 0: Insufficient imperative language" "found $IMPERATIVE_COUNT, need ≥5"
fi

# Standard 11: Imperative agent invocation
if grep -A 5 "docs-accuracy-analyzer.md" "$PROJECT_ROOT/.claude/commands/optimize-claude.md" 2>/dev/null | grep -q "Read and follow ALL behavioral guidelines"; then
  pass "Standard 11: Imperative agent invocation pattern"
else
  fail "Standard 11: Missing imperative invocation" "workflow should use 'Read and follow ALL behavioral guidelines'"
fi

# Standard 14: File size separation
GUIDE_EXISTS=0
if [ -f "$PROJECT_ROOT/.claude/docs/guides/docs-accuracy-analyzer-agent-guide.md" ]; then
  GUIDE_EXISTS=1
  pass "Standard 14: Comprehensive guide exists"
else
  fail "Standard 14: Guide file missing" "should exist at .claude/docs/guides/"
fi

# Bidirectional cross-references
if [ "$GUIDE_EXISTS" -eq 1 ]; then
  if grep -q "docs-accuracy-analyzer-agent-guide.md" "$PROJECT_ROOT/.claude/agents/docs-accuracy-analyzer.md" 2>/dev/null; then
    pass "Bidirectional reference: Behavioral → Guide"
  else
    fail "Missing reference" "behavioral file should link to guide"
  fi

  if grep -q "docs-accuracy-analyzer.md" "$PROJECT_ROOT/.claude/docs/guides/docs-accuracy-analyzer-agent-guide.md" 2>/dev/null; then
    pass "Bidirectional reference: Guide → Behavioral"
  else
    fail "Missing reference" "guide should link to behavioral file"
  fi
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
fi

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed.${NC}"
  exit 1
fi
