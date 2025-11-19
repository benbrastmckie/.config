#!/bin/bash
# test_library_sourcing_order.sh
# Validates that library functions are sourced before being called
# Prevents "command not found" errors in orchestration commands

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test result tracking
total_tests=0
passed_tests=0
failed_tests=0

# Test helper function
run_test() {
  local test_name="$1"
  local test_result="$2"

  total_tests=$((total_tests + 1))

  if [ "$test_result" -eq 0 ]; then
    echo "✓ PASS: $test_name"
    passed_tests=$((passed_tests + 1))
  else
    echo "✗ FAIL: $test_name"
    failed_tests=$((failed_tests + 1))
  fi
}

# Test /coordinate command for library sourcing order violations
test_coordinate_sourcing_order() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  # Check verify_state_variable (from verification-helpers.sh)
  local first_source=$(grep -n "source.*verification-helpers" "$cmd_file" | head -1 | cut -d: -f1)
  local first_call=$(grep -n "verify_state_variable\|verify_file_created" "$cmd_file" | grep -v "^[0-9]*:#" | grep -v "provides verify_" | head -1 | cut -d: -f1)

  if [ "$first_call" -gt "$first_source" ]; then
    echo "  ✓ verify_state_variable sourced at line $first_source, first call at line $first_call"
  else
    echo "  ✗ verify_state_variable called at line $first_call before sourcing at $first_source"
    violations=$((violations + 1))
  fi

  # Check handle_state_error (from error-handling.sh)
  first_source=$(grep -n "source.*error-handling" "$cmd_file" | head -1 | cut -d: -f1)
  first_call=$(grep -n "handle_state_error" "$cmd_file" | grep -v "^[0-9]*:#" | grep -v "provides handle_" | head -1 | cut -d: -f1)

  if [ "$first_call" -gt "$first_source" ]; then
    echo "  ✓ handle_state_error sourced at line $first_source, first call at line $first_call"
  else
    echo "  ✗ handle_state_error called at line $first_call before sourcing at $first_source"
    violations=$((violations + 1))
  fi

  return $violations
}

# Test that source guards exist in libraries
test_source_guards() {
  local violations=0

  # Check error-handling.sh
  if grep -q "ERROR_HANDLING_SOURCED" "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"; then
    echo "  ✓ error-handling.sh has source guard"
  else
    echo "  ✗ error-handling.sh missing source guard"
    violations=$((violations + 1))
  fi

  # Check verification-helpers.sh
  if grep -q "VERIFICATION_HELPERS_SOURCED" "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"; then
    echo "  ✓ verification-helpers.sh has source guard"
  else
    echo "  ✗ verification-helpers.sh missing source guard"
    violations=$((violations + 1))
  fi

  return $violations
}

# Test that libraries are sourced early in initialization
test_early_sourcing() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  # Check that error-handling.sh is sourced within first 150 lines
  local error_handling_line=$(grep -n "source.*error-handling" "$cmd_file" | head -1 | cut -d: -f1)
  if [ "$error_handling_line" -lt 150 ]; then
    echo "  ✓ error-handling.sh sourced early (line $error_handling_line)"
  else
    echo "  ✗ error-handling.sh sourced too late (line $error_handling_line, should be < 150)"
    violations=$((violations + 1))
  fi

  # Check that verification-helpers.sh is sourced within first 150 lines
  local verification_line=$(grep -n "source.*verification-helpers" "$cmd_file" | head -1 | cut -d: -f1)
  if [ "$verification_line" -lt 150 ]; then
    echo "  ✓ verification-helpers.sh sourced early (line $verification_line)"
  else
    echo "  ✗ verification-helpers.sh sourced too late (line $verification_line, should be < 150)"
    violations=$((violations + 1))
  fi

  return $violations
}

# Test that state-persistence is sourced before error-handling/verification
test_dependency_order() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  local state_persist_line=$(grep -n "^source.*state-persistence" "$cmd_file" | head -1 | cut -d: -f1)
  local error_handling_line=$(grep -n "source.*error-handling" "$cmd_file" | head -1 | cut -d: -f1)
  local verification_line=$(grep -n "source.*verification-helpers" "$cmd_file" | head -1 | cut -d: -f1)

  if [ "$state_persist_line" -lt "$error_handling_line" ]; then
    echo "  ✓ state-persistence.sh (line $state_persist_line) before error-handling.sh (line $error_handling_line)"
  else
    echo "  ✗ state-persistence.sh must be sourced before error-handling.sh"
    violations=$((violations + 1))
  fi

  if [ "$state_persist_line" -lt "$verification_line" ]; then
    echo "  ✓ state-persistence.sh (line $state_persist_line) before verification-helpers.sh (line $verification_line)"
  else
    echo "  ✗ state-persistence.sh must be sourced before verification-helpers.sh"
    violations=$((violations + 1))
  fi

  return $violations
}

# Run tests
echo "========================================="
echo "Testing library sourcing order"
echo "========================================="
echo ""

echo "Test 1: /coordinate sourcing order"
test_coordinate_sourcing_order
run_test "Coordinate command sourcing order" $?
echo ""

echo "Test 2: Source guards"
test_source_guards
run_test "Library source guards present" $?
echo ""

echo "Test 3: Early sourcing"
test_early_sourcing
run_test "Libraries sourced early in initialization" $?
echo ""

echo "Test 4: Dependency order"
test_dependency_order
run_test "state-persistence sourced before dependent libraries" $?
echo ""

# Test sourcing order in ALL bash blocks (Spec 661 Phase 4)
test_subsequent_blocks_sourcing_order() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  # Find all bash code blocks in coordinate.md
  local block_count=0
  local in_bash_block=false
  local block_start=0

  while IFS= read -r line_content; do
    local line_num=$((block_count + 1))

    if echo "$line_content" | grep -q '^```bash$'; then
      in_bash_block=true
      block_start=$line_num
    elif echo "$line_content" | grep -q '^```$' && [ "$in_bash_block" = true ]; then
      in_bash_block=false
      block_count=$((block_count + 1))

      # Check sourcing order in this block (blocks 2+ should follow same pattern)
      if [ $block_count -gt 1 ]; then
        # Extract this block
        local block_end=$line_num
        local block_lines=$(sed -n "${block_start},${block_end}p" "$cmd_file")

        # Check if block contains library sourcing
        if echo "$block_lines" | grep -q "source.*\.sh"; then
          # Verify Standard 15 order: state-machine, state-persistence, error-handling, verification-helpers
          local state_machine_line=$(echo "$block_lines" | grep -n "source.*workflow-state-machine" | head -1 | cut -d: -f1)
          local state_persist_line=$(echo "$block_lines" | grep -n "source.*state-persistence" | head -1 | cut -d: -f1)
          local error_handling_line=$(echo "$block_lines" | grep -n "source.*error-handling" | head -1 | cut -d: -f1)
          local verification_line=$(echo "$block_lines" | grep -n "source.*verification-helpers" | head -1 | cut -d: -f1)

          # If any are found, verify order
          if [ -n "$state_machine_line" ] && [ -n "$state_persist_line" ]; then
            if [ "$state_machine_line" -lt "$state_persist_line" ]; then
              echo "  ✓ Block $block_count: workflow-state-machine before state-persistence"
            else
              echo "  ✗ Block $block_count: incorrect order (state-machine should be first)"
              violations=$((violations + 1))
            fi
          fi

          if [ -n "$state_persist_line" ] && [ -n "$error_handling_line" ]; then
            if [ "$state_persist_line" -lt "$error_handling_line" ]; then
              echo "  ✓ Block $block_count: state-persistence before error-handling"
            else
              echo "  ✗ Block $block_count: state-persistence must be before error-handling"
              violations=$((violations + 1))
            fi
          fi

          if [ -n "$error_handling_line" ] && [ -n "$verification_line" ]; then
            if [ "$error_handling_line" -lt "$verification_line" ]; then
              echo "  ✓ Block $block_count: error-handling before verification-helpers"
            else
              echo "  ✗ Block $block_count: error-handling must be before verification-helpers"
              violations=$((violations + 1))
            fi
          fi
        fi
      fi
    fi
  done < "$cmd_file"

  if [ $block_count -lt 2 ]; then
    echo "  ⚠ Warning: Found only $block_count bash block(s), expected multiple"
  else
    echo "  ℹ Checked sourcing order in $block_count bash blocks"
  fi

  return $violations
}

echo "Test 5: Subsequent blocks sourcing order (Spec 661)"
test_subsequent_blocks_sourcing_order
run_test "All bash blocks follow Standard 15 sourcing order" $?
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"
echo ""

if [ $failed_tests -eq 0 ]; then
  echo "✓ All library sourcing order tests passed"
  exit 0
else
  echo "✗ Some library sourcing order tests failed"
  exit 1
fi
