#!/bin/bash
# Synchronization Validation Tests for /coordinate Command
# Verifies that duplicate code blocks remain synchronized

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/.claude/commands/coordinate.md"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if $test_func; then
    echo "PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "FAIL: $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

echo "========================================"
echo "Synchronization Tests: /coordinate"
echo "========================================"
echo ""

# Verify command file exists
if [ ! -f "$COMMAND_FILE" ]; then
  echo "FATAL: Command file not found: $COMMAND_FILE"
  exit 1
fi

# ────────────────────────────────────────────────────────────────────
# Test 1: CLAUDE_PROJECT_DIR Pattern Consistency
# ────────────────────────────────────────────────────────────────────

test_claude_project_dir_consistency() {
  # Extract CLAUDE_PROJECT_DIR detection pattern from multiple blocks
  # We expect: if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  #              CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  #              export CLAUDE_PROJECT_DIR
  #            fi

  local pattern_count=$(grep -c "CLAUDE_PROJECT_DIR=\"\$(git rev-parse" "$COMMAND_FILE")

  # There should be 7 occurrences (one per bash block in /coordinate)
  if [ "$pattern_count" -eq 7 ]; then
    return 0
  else
    echo "  Expected 7 CLAUDE_PROJECT_DIR patterns, found: $pattern_count"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Test 2: Library Sourcing Pattern Consistency
# ────────────────────────────────────────────────────────────────────

test_library_sourcing_consistency() {
  # Verify all blocks properly source libraries
  # Pattern 1: source "${CLAUDE_PROJECT_DIR}/.claude/lib/..."
  local sourcing_pattern1=$(grep -c "source.*\${CLAUDE_PROJECT_DIR}/\.claude/lib/" "$COMMAND_FILE")

  # Pattern 2: source "${LIB_DIR}/..."
  local sourcing_pattern2=$(grep -c "source.*\${LIB_DIR}/" "$COMMAND_FILE")

  # Total sourcing operations (should be at least 6-7)
  local total_sourcing=$((sourcing_pattern1 + sourcing_pattern2))

  if [ "$total_sourcing" -ge 6 ]; then
    return 0
  else
    echo "  Expected ≥6 library sourcing patterns, found: $total_sourcing"
    echo "  (Pattern 1: $sourcing_pattern1, Pattern 2: $sourcing_pattern2)"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Test 3: Scope Detection Uses Library (Phase 1 Verification)
# ────────────────────────────────────────────────────────────────────

test_scope_detection_uses_library() {
  # Verify Block 1 and Block 3 use detect_workflow_scope() function
  # Should NOT find inline scope detection patterns
  local inline_patterns=$(grep -c "if echo.*WORKFLOW_DESCRIPTION.*grep.*research\.\*" "$COMMAND_FILE" || true)

  # After Phase 1, there should be NO inline scope detection patterns
  if [ "$inline_patterns" -eq 0 ]; then
    # Verify library function is called instead
    local library_calls=$(grep -c "detect_workflow_scope" "$COMMAND_FILE")
    if [ "$library_calls" -ge 2 ]; then
      return 0
    else
      echo "  Library function detect_workflow_scope not found (expected ≥2 calls)"
      return 1
    fi
  else
    echo "  Found $inline_patterns inline scope detection patterns (expected 0)"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Test 4: Required Libraries Complete
# ────────────────────────────────────────────────────────────────────

test_required_libraries_complete() {
  # Verify all 4 REQUIRED_LIBS arrays include workflow-scope-detection.sh
  local workflow_scope_lib_count=$(grep -c '"workflow-scope-detection.sh"' "$COMMAND_FILE")

  # Should appear in all 4 REQUIRED_LIBS arrays
  if [ "$workflow_scope_lib_count" -eq 4 ]; then
    # Also verify overview-synthesis.sh is in all arrays (from 598 fix)
    local overview_synthesis_count=$(grep -c '"overview-synthesis.sh"' "$COMMAND_FILE")
    if [ "$overview_synthesis_count" -eq 4 ]; then
      return 0
    else
      echo "  overview-synthesis.sh found in $overview_synthesis_count arrays (expected 4)"
      return 1
    fi
  else
    echo "  workflow-scope-detection.sh found in $workflow_scope_lib_count arrays (expected 4)"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Test 5: PHASES_TO_EXECUTE Mapping Consistency
# ────────────────────────────────────────────────────────────────────

test_phases_to_execute_consistency() {
  # Extract both PHASES_TO_EXECUTE case statements
  # Block 1 around line 607-626, Block 3 around line 957-976

  # Count occurrences of PHASES_TO_EXECUTE case statements
  local case_statements=$(grep -c "case \"\$WORKFLOW_SCOPE\" in" "$COMMAND_FILE")

  # Should be at least 2 (Block 1 and Block 3)
  if [ "$case_statements" -ge 2 ]; then
    # Verify research-only mapping consistency
    local research_only_count=$(grep -c "PHASES_TO_EXECUTE=\"0,1\"" "$COMMAND_FILE")
    if [ "$research_only_count" -ge 2 ]; then
      # Verify full-implementation includes phase 6 (corrected in 598)
      local full_impl_count=$(grep -c "PHASES_TO_EXECUTE=\"0,1,2,3,4,6\"" "$COMMAND_FILE")
      if [ "$full_impl_count" -ge 2 ]; then
        return 0
      else
        echo "  full-implementation mapping found $full_impl_count times (expected ≥2)"
        return 1
      fi
    else
      echo "  research-only mapping found $research_only_count times (expected ≥2)"
      return 1
    fi
  else
    echo "  Found $case_statements case statements (expected ≥2)"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Test 6: Defensive Validation Present
# ────────────────────────────────────────────────────────────────────

test_defensive_validation_present() {
  # After Phase 1, WORKFLOW_DESCRIPTION validation moved to library function
  # Verify WORKFLOW_SCOPE validation (result of library call) in Block 1
  local workflow_scope_validation=$(grep -c "if \[ -z \"\${WORKFLOW_SCOPE:-}\" \]" "$COMMAND_FILE")

  # Should appear at least once after detect_workflow_scope call
  if [ "$workflow_scope_validation" -ge 1 ]; then
    # Verify WORKFLOW_DESCRIPTION validation still present in Block 3
    local workflow_desc_validation=$(grep -c "if \[ -z \"\${WORKFLOW_DESCRIPTION:-}\" \]" "$COMMAND_FILE")
    if [ "$workflow_desc_validation" -ge 1 ]; then
      # Verify PHASES_TO_EXECUTE validation (added in 598)
      local phases_validation=$(grep -c "if \[ -z \"\${PHASES_TO_EXECUTE:-}\" \]" "$COMMAND_FILE")
      if [ "$phases_validation" -ge 1 ]; then
        return 0
      else
        echo "  PHASES_TO_EXECUTE validation not found"
        return 1
      fi
    else
      echo "  WORKFLOW_DESCRIPTION validation not found"
      return 1
    fi
  else
    echo "  WORKFLOW_SCOPE validation not found (expected ≥1)"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Run All Tests
# ────────────────────────────────────────────────────────────────────

run_test "Test 1: CLAUDE_PROJECT_DIR pattern consistent across 7 blocks" \
  test_claude_project_dir_consistency

run_test "Test 2: Library sourcing pattern consistent across 7 blocks" \
  test_library_sourcing_consistency

run_test "Test 3: Scope detection uses library function (Phase 1 verification)" \
  test_scope_detection_uses_library

run_test "Test 4: All required libraries present in REQUIRED_LIBS arrays" \
  test_required_libraries_complete

run_test "Test 5: PHASES_TO_EXECUTE mapping consistent between Block 1 and Block 3" \
  test_phases_to_execute_consistency

run_test "Test 6: Defensive validation present after critical recalculations" \
  test_defensive_validation_present

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All synchronization tests passed"
  exit 0
else
  echo "✗ Some synchronization tests failed"
  exit 1
fi
