#!/usr/bin/env bash
# Integration test suite for /todo --clean workflow
# Tests end-to-end cleanup with parser fixes for sub-bullets

# Note: Don't use 'set -e' - it causes early exit when tests fail
# We want to run all tests and report failures at the end

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/test-helpers.sh" ]; then
  source "$SCRIPT_DIR/test-helpers.sh" 2>/dev/null || true
fi

# Source library under test
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
export CLAUDE_PROJECT_DIR
source "$CLAUDE_PROJECT_DIR/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "ERROR: Cannot load todo-functions.sh"
  exit 1
}

# Test suite
test_suite="todo_cleanup_integration"

# ============================================================================
# Test: Parser with sub-bullet entries
# ============================================================================

test_parser_handles_sub_bullets() {
  local test_name="parser_handles_sub_bullets"

  # Create test directory structure
  local test_dir="/tmp/test_todo_integration_$$"
  mkdir -p "$test_dir/.claude/specs/001_test_project/plans"
  mkdir -p "$test_dir/.claude/specs/002_another_project/plans"
  mkdir -p "$test_dir/.claude/specs/003_third_project/plans"

  echo "# Test Plan" > "$test_dir/.claude/specs/001_test_project/plans/001.md"
  echo "# Test Plan" > "$test_dir/.claude/specs/002_another_project/plans/001.md"
  echo "# Test Plan" > "$test_dir/.claude/specs/003_third_project/plans/001.md"

  # Create TODO.md with sub-bullets and markdown links
  local todo_path="$test_dir/.claude/TODO.md"
  cat > "$todo_path" << 'EOF'
# TODO

## Completed

- [x] **Test Project 1** - Description [.claude/specs/001_test_project/plans/001.md]
  - Sub-bullet with [link](path.md)
  - Another sub-bullet with [multiple](a.md) [links](b.md)
- [x] **Test Project 2** - Description [.claude/specs/002_another_project/plans/001.md]

## Abandoned

- [x] **Test Project 3** - Description [.claude/specs/003_third_project/plans/001.md]
  - Multiple sub-bullets
  - With [links](a.md) and [more](b.md)
  - Third sub-bullet [here](c.md)
EOF

  # Test: Parser should extract all 3 projects despite sub-bullets
  CLAUDE_SPECS_ROOT="$test_dir/.claude/specs"
  local result
  result=$(parse_todo_sections "$todo_path")
  local count
  count=$(echo "$result" | jq 'length')

  if [ "$count" -ne 3 ]; then
    echo "FAIL: $test_name - Expected 3 projects, got $count"
    echo "Result: $result"
    rm -rf "$test_dir"
    return 1
  fi

  # Verify correct paths extracted
  local path1 path2 path3
  path1=$(echo "$result" | jq -r '.[0].plan_path')
  path2=$(echo "$result" | jq -r '.[1].plan_path')
  path3=$(echo "$result" | jq -r '.[2].plan_path')

  if [ "$path1" != ".claude/specs/001_test_project/plans/001.md" ]; then
    echo "FAIL: $test_name - Wrong path for project 1: $path1"
    rm -rf "$test_dir"
    return 1
  fi

  if [ "$path2" != ".claude/specs/002_another_project/plans/001.md" ]; then
    echo "FAIL: $test_name - Wrong path for project 2: $path2"
    rm -rf "$test_dir"
    return 1
  fi

  if [ "$path3" != ".claude/specs/003_third_project/plans/001.md" ]; then
    echo "FAIL: $test_name - Wrong path for project 3: $path3"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

# ============================================================================
# Test: Parser ignores non-spec links in sub-bullets
# ============================================================================

test_parser_ignores_non_spec_links() {
  local test_name="parser_ignores_non_spec_links"

  # Create test directory structure
  local test_dir="/tmp/test_todo_integration_$$"
  mkdir -p "$test_dir/.claude/specs/001_test_project/plans"

  echo "# Test Plan" > "$test_dir/.claude/specs/001_test_project/plans/001.md"

  # Create TODO.md with non-spec links that should be ignored
  local todo_path="$test_dir/.claude/TODO.md"
  cat > "$todo_path" << 'EOF'
# TODO

## Completed

- [x] **Test Project** - Description [.claude/specs/001_test_project/plans/001.md]
  - See [research report](docs/research.md)
  - Reference [implementation](src/impl.md)
  - Check [tests](tests/unit.md)
EOF

  # Test: Parser should extract only the spec path, not the non-spec links
  CLAUDE_SPECS_ROOT="$test_dir/.claude/specs"
  local result
  result=$(parse_todo_sections "$todo_path")
  local count
  count=$(echo "$result" | jq 'length')

  if [ "$count" -ne 1 ]; then
    echo "FAIL: $test_name - Expected 1 project, got $count"
    echo "Result: $result"
    rm -rf "$test_dir"
    return 1
  fi

  # Verify correct path extracted
  local path
  path=$(echo "$result" | jq -r '.[0].plan_path')

  if [ "$path" != ".claude/specs/001_test_project/plans/001.md" ]; then
    echo "FAIL: $test_name - Wrong path: $path"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

# ============================================================================
# Test: Parser handles entries without sub-bullets
# ============================================================================

test_parser_handles_simple_entries() {
  local test_name="parser_handles_simple_entries"

  # Create test directory structure
  local test_dir="/tmp/test_todo_integration_$$"
  mkdir -p "$test_dir/.claude/specs/001_simple/plans"
  mkdir -p "$test_dir/.claude/specs/002_another/plans"

  echo "# Test Plan" > "$test_dir/.claude/specs/001_simple/plans/001.md"
  echo "# Test Plan" > "$test_dir/.claude/specs/002_another/plans/001.md"

  # Create TODO.md without sub-bullets
  local todo_path="$test_dir/.claude/TODO.md"
  cat > "$todo_path" << 'EOF'
# TODO

## Completed

- [x] **Simple Project** - Description [.claude/specs/001_simple/plans/001.md]
- [x] **Another Project** - Description [.claude/specs/002_another/plans/001.md]
EOF

  # Test: Parser should work normally with simple entries
  CLAUDE_SPECS_ROOT="$test_dir/.claude/specs"
  local result
  result=$(parse_todo_sections "$todo_path")
  local count
  count=$(echo "$result" | jq 'length')

  if [ "$count" -ne 2 ]; then
    echo "FAIL: $test_name - Expected 2 projects, got $count"
    echo "Result: $result"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

# ============================================================================
# Test: Anchored regex matches only .claude/specs/ paths
# ============================================================================

test_parser_anchored_regex() {
  local test_name="parser_anchored_regex"

  # Create test directory structure
  local test_dir="/tmp/test_todo_integration_$$"
  mkdir -p "$test_dir/.claude/specs/001_project/plans"

  echo "# Test Plan" > "$test_dir/.claude/specs/001_project/plans/001.md"

  # Create TODO.md with multiple bracket pairs
  local todo_path="$test_dir/.claude/TODO.md"
  cat > "$todo_path" << 'EOF'
# TODO

## Completed

- [x] **Project** - Description with [random.md] link [.claude/specs/001_project/plans/001.md]
EOF

  # Test: Parser should extract only the .claude/specs/ path
  CLAUDE_SPECS_ROOT="$test_dir/.claude/specs"
  local result
  result=$(parse_todo_sections "$todo_path")
  local path
  path=$(echo "$result" | jq -r '.[0].plan_path')

  if [ "$path" != ".claude/specs/001_project/plans/001.md" ]; then
    echo "FAIL: $test_name - Wrong path: $path (should ignore [random.md])"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

# ============================================================================
# Run all tests
# ============================================================================

echo "Running $test_suite tests..."
echo ""

# Track results
passed=0
failed=0

# Run tests
tests=(
  "test_parser_handles_sub_bullets"
  "test_parser_ignores_non_spec_links"
  "test_parser_handles_simple_entries"
  "test_parser_anchored_regex"
)

for test in "${tests[@]}"; do
  if $test; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

# Summary
echo ""
echo "================================"
echo "Test Results: $test_suite"
echo "================================"
echo "Passed: $passed"
echo "Failed: $failed"
echo "Total: $((passed + failed))"
echo "================================"

if [ $failed -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
