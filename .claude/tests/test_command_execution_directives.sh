#!/usr/bin/env bash
# Test: Command Execution Directives
# Verifies all command files have proper execution directives per command-authoring-standards.md
#
# Requirements from Spec 756:
# - All bash blocks must have execution directives
# - No documentation-only YAML blocks
# - set +H must appear in multi-block commands

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Find project root
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

COMMANDS_DIR="${PROJECT_ROOT}/.claude/commands"

echo "=== Command Execution Directives Tests ==="
echo "Commands directory: $COMMANDS_DIR"
echo ""

# Test 1: All commands have execution directives
test_execution_directives_present() {
  echo "Test 1: Execution directives present in all command files"

  local failed=0
  local total=0

  for cmd in "$COMMANDS_DIR"/*.md; do
    [[ "$(basename "$cmd")" == "README.md" ]] && continue
    [[ ! -f "$cmd" ]] && continue

    ((total++))

    # Count bash blocks
    local bash_blocks
    bash_blocks=$(grep -c '```bash' "$cmd" 2>/dev/null || echo 0)
    bash_blocks=$(echo "$bash_blocks" | head -1 | tr -d ' ')

    # Skip commands without bash blocks
    if [ "$bash_blocks" -eq 0 ]; then
      continue
    fi

    # Count execution directives
    local directive_count
    directive_count=$(grep -cE '\*\*EXECUTE NOW\*\*:|Execute this|Run the following|STEP [0-9]+:' "$cmd" 2>/dev/null || echo 0)
    directive_count=$(echo "$directive_count" | head -1 | tr -d ' ')

    if [ "$directive_count" -eq 0 ]; then
      echo -e "  ${RED}FAIL${NC}: $(basename "$cmd") has $bash_blocks bash blocks but 0 execution directives"
      ((failed++))
    else
      echo -e "  ${GREEN}PASS${NC}: $(basename "$cmd") - $directive_count directives for $bash_blocks blocks"
    fi
  done

  if [ "$failed" -eq 0 ]; then
    echo -e "  ${GREEN}Result: All $total commands have execution directives${NC}"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${RED}Result: $failed of $total commands missing execution directives${NC}"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Test 2: No documentation-only YAML blocks
test_no_documentation_only_yaml() {
  echo ""
  echo "Test 2: No documentation-only YAML blocks in commands"

  local failed=0
  local total=0

  for cmd in "$COMMANDS_DIR"/*.md; do
    [[ "$(basename "$cmd")" == "README.md" ]] && continue
    [[ ! -f "$cmd" ]] && continue

    ((total++))

    # Check for YAML blocks without preceding imperative instruction
    local violations
    violations=$(awk '/```yaml/{
      found=0
      for(i=NR-5; i<NR; i++) {
        if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
      }
      if(!found) print NR
    } {lines[NR]=$0}' "$cmd")

    if [ -n "$violations" ]; then
      echo -e "  ${RED}FAIL${NC}: $(basename "$cmd") has documentation-only YAML blocks at lines: $violations"
      ((failed++))
    fi
  done

  if [ "$failed" -eq 0 ]; then
    echo -e "  ${GREEN}Result: No documentation-only YAML blocks found${NC}"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${RED}Result: $failed commands have documentation-only YAML blocks${NC}"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Test 3: set +H in multi-block commands
test_set_h_present() {
  echo ""
  echo "Test 3: set +H present in multi-block commands"

  local warnings=0
  local total=0

  for cmd in "$COMMANDS_DIR"/*.md; do
    [[ "$(basename "$cmd")" == "README.md" ]] && continue
    [[ ! -f "$cmd" ]] && continue

    # Count bash blocks
    local bash_blocks
    bash_blocks=$(grep -c '```bash' "$cmd" 2>/dev/null || echo 0)
    bash_blocks=$(echo "$bash_blocks" | head -1 | tr -d ' ')

    # Skip single-block commands
    [ "$bash_blocks" -le 1 ] && continue

    ((total++))

    # Check for set +H
    local set_h_count
    set_h_count=$(grep -c 'set +H' "$cmd" 2>/dev/null || echo 0)
    set_h_count=$(echo "$set_h_count" | head -1 | tr -d ' ')

    if [ "$set_h_count" -lt "$bash_blocks" ]; then
      echo -e "  ${YELLOW}WARN${NC}: $(basename "$cmd") may be missing 'set +H' ($set_h_count found, $bash_blocks blocks)"
      ((warnings++))
    else
      echo -e "  ${GREEN}PASS${NC}: $(basename "$cmd") - $set_h_count 'set +H' for $bash_blocks blocks"
    fi
  done

  if [ "$warnings" -eq 0 ]; then
    echo -e "  ${GREEN}Result: All $total multi-block commands have proper 'set +H'${NC}"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${YELLOW}Result: $warnings commands may need additional 'set +H'${NC}"
    # Warning, not failure
    ((TESTS_PASSED++))
    return 0
  fi
}

# Test 4: No Task pseudo-syntax without imperative
test_no_task_pseudo_syntax() {
  echo ""
  echo "Test 4: All Task invocations have imperative instructions"

  local failed=0
  local total=0

  for cmd in "$COMMANDS_DIR"/*.md; do
    [[ "$(basename "$cmd")" == "README.md" ]] && continue
    [[ ! -f "$cmd" ]] && continue

    # Check if file has Task { patterns
    local task_count
    task_count=$(grep -c '^Task {' "$cmd" 2>/dev/null || echo 0)
    task_count=$(echo "$task_count" | head -1 | tr -d ' ')

    [ "$task_count" -eq 0 ] && continue

    ((total++))

    # Check for Task blocks without preceding imperative
    local violations
    violations=$(awk '/^Task \{/{
      found=0
      for(i=NR-5; i<NR; i++) {
        if(lines[i] ~ /EXECUTE NOW|USE the Task tool/) found=1
      }
      if(!found) print NR
    } {lines[NR]=$0}' "$cmd")

    if [ -n "$violations" ]; then
      echo -e "  ${RED}FAIL${NC}: $(basename "$cmd") has Task invocations without imperatives at lines: $violations"
      ((failed++))
    else
      echo -e "  ${GREEN}PASS${NC}: $(basename "$cmd") - All $task_count Task invocations have imperatives"
    fi
  done

  if [ "$failed" -eq 0 ]; then
    echo -e "  ${GREEN}Result: All Task invocations properly imperative${NC}"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${RED}Result: $failed commands have Task invocations without imperatives${NC}"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Run all tests
test_execution_directives_present || true
test_no_documentation_only_yaml || true
test_set_h_present || true
test_no_task_pseudo_syntax || true

# Summary
echo ""
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
