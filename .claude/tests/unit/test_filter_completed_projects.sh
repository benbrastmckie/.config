#!/bin/bash
#
# Unit tests for filter_completed_projects() function
#
# Tests that the function correctly filters projects by cleanup-eligible status
# (completed, superseded, abandoned) without age-based filtering.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the library (with absolute path)
if [ -f "$PROJECT_ROOT/lib/todo/todo-functions.sh" ]; then
  source "$PROJECT_ROOT/lib/todo/todo-functions.sh" 2>/dev/null || {
    echo "ERROR: Failed to load todo-functions.sh"
    exit 1
  }
elif [ -f "/home/benjamin/.config/.claude/lib/todo/todo-functions.sh" ]; then
  source "/home/benjamin/.config/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
    echo "ERROR: Failed to load todo-functions.sh"
    exit 1
  }
else
  echo "ERROR: Cannot find todo-functions.sh"
  echo "Searched: $PROJECT_ROOT/lib/todo/todo-functions.sh"
  exit 1
fi

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$haystack" | grep -q "$needle"; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected to find: $needle"
    echo "  In: $haystack"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "======================================"
echo "Testing filter_completed_projects()"
echo "======================================"
echo ""

# Test 1: Filter completed status
echo "Test 1: Filter completed status"
test_data='[
  {"plan_path": "/test/1.md", "status": "completed", "title": "Completed Test"},
  {"plan_path": "/test/2.md", "status": "in_progress", "title": "In Progress Test"}
]'
result=$(filter_completed_projects "$test_data")
count=$(echo "$result" | jq 'length')
assert_equals "1" "$count" "Should return 1 completed project"
assert_contains "$result" "Completed Test" "Should include completed project"
echo ""

# Test 2: Filter superseded status
echo "Test 2: Filter superseded status"
test_data='[
  {"plan_path": "/test/1.md", "status": "superseded", "title": "Superseded Test"},
  {"plan_path": "/test/2.md", "status": "not_started", "title": "Not Started Test"}
]'
result=$(filter_completed_projects "$test_data")
count=$(echo "$result" | jq 'length')
assert_equals "1" "$count" "Should return 1 superseded project"
assert_contains "$result" "Superseded Test" "Should include superseded project"
echo ""

# Test 3: Filter abandoned status
echo "Test 3: Filter abandoned status"
test_data='[
  {"plan_path": "/test/1.md", "status": "abandoned", "title": "Abandoned Test"},
  {"plan_path": "/test/2.md", "status": "in_progress", "title": "In Progress Test"}
]'
result=$(filter_completed_projects "$test_data")
count=$(echo "$result" | jq 'length')
assert_equals "1" "$count" "Should return 1 abandoned project"
assert_contains "$result" "Abandoned Test" "Should include abandoned project"
echo ""

# Test 4: Filter all three eligible statuses
echo "Test 4: Filter all three eligible statuses"
test_data='[
  {"plan_path": "/test/1.md", "status": "completed", "title": "Completed Test"},
  {"plan_path": "/test/2.md", "status": "superseded", "title": "Superseded Test"},
  {"plan_path": "/test/3.md", "status": "abandoned", "title": "Abandoned Test"},
  {"plan_path": "/test/4.md", "status": "in_progress", "title": "In Progress Test"},
  {"plan_path": "/test/5.md", "status": "not_started", "title": "Not Started Test"}
]'
result=$(filter_completed_projects "$test_data")
count=$(echo "$result" | jq 'length')
assert_equals "3" "$count" "Should return 3 eligible projects"
assert_contains "$result" "Completed Test" "Should include completed project"
assert_contains "$result" "Superseded Test" "Should include superseded project"
assert_contains "$result" "Abandoned Test" "Should include abandoned project"
echo ""

# Test 5: Empty input
echo "Test 5: Empty input"
test_data='[]'
result=$(filter_completed_projects "$test_data")
count=$(echo "$result" | jq 'length')
assert_equals "0" "$count" "Should return 0 projects for empty input"
echo ""

# Test 6: No eligible projects
echo "Test 6: No eligible projects"
test_data='[
  {"plan_path": "/test/1.md", "status": "in_progress", "title": "In Progress Test"},
  {"plan_path": "/test/2.md", "status": "not_started", "title": "Not Started Test"}
]'
result=$(filter_completed_projects "$test_data")
count=$(echo "$result" | jq 'length')
assert_equals "0" "$count" "Should return 0 projects when none are eligible"
echo ""

# Test 7: Verify JSON structure preserved
echo "Test 7: Verify JSON structure preserved"
test_data='[
  {"plan_path": "/test/1.md", "status": "completed", "title": "Test", "extra_field": "value"}
]'
result=$(filter_completed_projects "$test_data")
extra_field=$(echo "$result" | jq -r '.[0].extra_field // empty')
assert_equals "value" "$extra_field" "Should preserve all JSON fields"
echo ""

# Summary
echo "======================================"
echo "Test Summary"
echo "======================================"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
