#!/usr/bin/env bash
# test_standards_extraction.sh - Test suite for standards-extraction.sh library
#
# Tests the standards extraction library functions for CLAUDE.md integration

set -euo pipefail

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_NAME="Standards Extraction Library"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the library under test
CLAUDE_LIB="${CLAUDE_LIB:-/home/benjamin/.config/.claude/lib}"
source "$CLAUDE_LIB/plan/standards-extraction.sh" 2>/dev/null || {
  echo "FATAL: Cannot load standards-extraction library"
  exit 1
}

# Helper functions
pass() {
  echo "  ✓ $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo "  ✗ $1"
  echo "    Reason: $2"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE
# ═══════════════════════════════════════════════════════════════════════════

echo "Running $TEST_NAME Tests"
echo "═══════════════════════════════════════════════════════════════════════════"

# Test 1: Extract single section (code_standards)
echo ""
echo "Test 1: Extract code_standards section"
EXTRACTED=$(extract_claude_section "code_standards" 2>/dev/null)
if [ -n "$EXTRACTED" ] && echo "$EXTRACTED" | grep -q "Bash Sourcing"; then
  pass "code_standards extracted with expected content"
else
  fail "code_standards extraction" "Content missing or incomplete"
fi

# Test 2: Extract single section (testing_protocols)
echo ""
echo "Test 2: Extract testing_protocols section"
EXTRACTED=$(extract_claude_section "testing_protocols" 2>/dev/null)
if [ -n "$EXTRACTED" ]; then
  pass "testing_protocols extracted (${#EXTRACTED} bytes)"
else
  fail "testing_protocols extraction" "Section empty or missing"
fi

# Test 3: Extract all planning standards
echo ""
echo "Test 3: Extract all planning standards"
ALL_STANDARDS=$(extract_planning_standards 2>/dev/null)
if [ -n "$ALL_STANDARDS" ]; then
  SECTION_COUNT=$(echo "$ALL_STANDARDS" | grep -c "^SECTION:" || true)
  if [ "$SECTION_COUNT" -ge 5 ]; then
    pass "All planning standards extracted ($SECTION_COUNT sections)"
  else
    fail "Planning standards extraction" "Expected 6 sections, got $SECTION_COUNT"
  fi
else
  fail "Planning standards extraction" "Output empty"
fi

# Test 4: Verify all 6 expected sections present
echo ""
echo "Test 4: Verify all 6 planning-relevant sections present"
EXPECTED_SECTIONS=(
  "code_standards"
  "testing_protocols"
  "documentation_policy"
  "error_logging"
  "clean_break_development"
  "directory_organization"
)

MISSING=0
for section in "${EXPECTED_SECTIONS[@]}"; do
  if ! echo "$ALL_STANDARDS" | grep -q "^SECTION: $section"; then
    echo "    Missing: $section"
    ((MISSING++))
  fi
done

if [ $MISSING -eq 0 ]; then
  pass "All 6 expected sections present"
else
  fail "Section completeness" "$MISSING sections missing"
fi

# Test 5: Format standards for prompt
echo ""
echo "Test 5: Format standards for agent prompt"
FORMATTED=$(format_standards_for_prompt 2>/dev/null)
if [ -n "$FORMATTED" ]; then
  HEADER_COUNT=$(echo "$FORMATTED" | grep -c "^###" || true)
  if [ "$HEADER_COUNT" -ge 5 ]; then
    pass "Standards formatted with markdown headers ($HEADER_COUNT headers)"
  else
    fail "Standards formatting" "Expected 6 headers, got $HEADER_COUNT"
  fi
else
  fail "Standards formatting" "Output empty"
fi

# Test 6: Verify markdown header format
echo ""
echo "Test 6: Verify markdown header titles are properly formatted"
if echo "$FORMATTED" | grep -q "### Code Standards"; then
  pass "Title case conversion working (Code Standards)"
else
  fail "Title case conversion" "Expected '### Code Standards' not found"
fi

# Test 7: Verify content preservation
echo ""
echo "Test 7: Verify content preserved in formatted output"
if echo "$FORMATTED" | grep -q "Bash Sourcing"; then
  pass "Content preserved after formatting"
else
  fail "Content preservation" "Expected content not found in formatted output"
fi

# Test 8: Test graceful degradation (non-existent section)
echo ""
echo "Test 8: Graceful degradation for missing section"
NONEXISTENT=$(extract_claude_section "nonexistent_section" 2>/dev/null)
if [ -z "$NONEXISTENT" ]; then
  pass "Missing section returns empty string (graceful degradation)"
else
  fail "Graceful degradation" "Expected empty string for missing section"
fi

# Test 9: Test built-in validation function
echo ""
echo "Test 9: Built-in validation function"
if validate_standards_extraction >/dev/null 2>&1; then
  pass "Built-in validation function passes"
else
  fail "Built-in validation" "validate_standards_extraction returned error"
fi

# Test 10: Verify CLAUDE.md discovery (upward search)
echo ""
echo "Test 10: CLAUDE.md upward directory search"
# Create temp subdirectory and test from there
TEMP_DIR="/tmp/test_standards_$$"
mkdir -p "$TEMP_DIR/subdir/deep"
cd "$TEMP_DIR/subdir/deep"

# Should still find CLAUDE.md from /home/benjamin/.config
FOUND=$(extract_claude_section "code_standards" 2>/dev/null)
cd - >/dev/null
rm -rf "$TEMP_DIR"

if [ -n "$FOUND" ]; then
  pass "Upward directory search finds CLAUDE.md"
else
  fail "Upward directory search" "CLAUDE.md not found from subdirectory"
fi

# ═══════════════════════════════════════════════════════════════════════════
# TEST SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "Test Summary: $TEST_NAME"
echo "  Tests Run:    $TESTS_RUN"
echo "  Tests Passed: $TESTS_PASSED"
echo "  Tests Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo "  Status: PASSED ✓"
  exit 0
else
  echo "  Status: FAILED ✗"
  exit 1
fi
