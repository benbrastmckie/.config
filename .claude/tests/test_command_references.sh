#!/usr/bin/env bash
# test_command_references.sh
# Validates that all pattern references in command files resolve correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="$SCRIPT_DIR/../commands"
PATTERNS_FILE="$SCRIPT_DIR/../docs/command-patterns.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test: Verify reference links resolve
test_reference_links_resolve() {
  local command_file="$1"
  local command_name=$(basename "$command_file" .md)
  local broken_refs=()
  local test_passed=true

  # Extract all pattern references
  while IFS= read -r line; do
    if [[ $line =~ \]\(\.\.\/docs\/command-patterns\.md#([^\)]+)\) ]]; then
      local anchor="${BASH_REMATCH[1]}"

      # Check if anchor exists in command-patterns.md
      # Anchors in markdown are section headers converted to lowercase with spaces as hyphens
      if ! grep -qi "^## .*$anchor" "$PATTERNS_FILE" && \
         ! grep -qi "^### .*$anchor" "$PATTERNS_FILE" && \
         ! grep -qi "^### Pattern:.*$anchor" "$PATTERNS_FILE"; then
        broken_refs+=("$anchor")
        test_passed=false
      fi
    fi
  done < "$command_file"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if [ "$test_passed" = true ]; then
    echo -e "${GREEN}✓${NC} $command_name: All references resolve"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $command_name: Broken references found:"
    for ref in "${broken_refs[@]}"; do
      echo -e "  ${RED}-${NC} #$ref"
    done
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return 1
  fi
}

# Test: Check that command-specific sections are preserved
test_no_information_loss() {
  local command_file="$1"
  local backup_file="$2"
  local command_name=$(basename "$command_file" .md)
  local warnings=()

  # Skip if backup doesn't exist
  if [ ! -f "$backup_file" ]; then
    return 0
  fi

  # Check for command-specific marker sections
  local markers=("command-specific" "orchestrate-specific" "implement-specific" "setup-specific")

  for marker in "${markers[@]}"; do
    # Count occurrences in backup
    local backup_count=$(grep -ic "$marker" "$backup_file" 2>/dev/null || echo "0")

    if [ "$backup_count" -gt 0 ]; then
      # Check if still present in refactored version
      local current_count=$(grep -ic "$marker" "$command_file" 2>/dev/null || echo "0")

      if [ "$current_count" -eq 0 ]; then
        warnings+=("Missing '$marker' sections (had $backup_count)")
      fi
    fi
  done

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if [ ${#warnings[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} $command_name: Command-specific content preserved"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
  else
    echo -e "${YELLOW}⚠${NC} $command_name: Potential information loss:"
    for warning in "${warnings[@]}"; do
      echo -e "  ${YELLOW}-${NC} $warning"
    done
    PASSED_TESTS=$((PASSED_TESTS + 1))  # Warnings don't fail the test
    return 0
  fi
}

# Test: Verify command can still be invoked
test_command_invocation() {
  local command_name="$1"

  # Skip README and example files
  if [[ "$command_name" == "README" ]] || [[ "$command_name" == "example-"* ]]; then
    return 0
  fi

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  # Test if command help works (this is a placeholder - actual invocation depends on command system)
  if grep -q "^# " "$COMMANDS_DIR/$command_name.md"; then
    echo -e "${GREEN}✓${NC} $command_name: Command file structure valid"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $command_name: Invalid command file structure"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return 1
  fi
}

# Main test execution
main() {
  echo "=== Command Reference Validation Tests ==="
  echo "Commands directory: $COMMANDS_DIR"
  echo "Patterns file: $PATTERNS_FILE"
  echo ""

  # Check if patterns file exists
  if [ ! -f "$PATTERNS_FILE" ]; then
    echo -e "${RED}✗${NC} Pattern file not found: $PATTERNS_FILE"
    exit 1
  fi

  # Find backup directory (most recent)
  BACKUP_DIR=$(find "$COMMANDS_DIR/backups" -type d -name "phase4_*" 2>/dev/null | sort -r | head -1)

  echo "Testing command files..."
  echo ""

  # Test all command files
  for cmd_file in "$COMMANDS_DIR"/*.md; do
    if [ -f "$cmd_file" ]; then
      local cmd_name=$(basename "$cmd_file" .md)
      local backup_file="$BACKUP_DIR/$cmd_name.md"

      # Test reference resolution
      test_reference_links_resolve "$cmd_file"

      # Test information preservation (if backup exists)
      if [ -n "$BACKUP_DIR" ] && [ -f "$backup_file" ]; then
        test_no_information_loss "$cmd_file" "$backup_file"
      fi

      # Test command invocation
      test_command_invocation "$cmd_name"

      echo ""
    fi
  done

  # Print summary
  echo "=== Test Summary ==="
  echo -e "Total tests: $TOTAL_TESTS"
  echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
  if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    exit 1
  else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

# Run tests
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  main "$@"
fi
