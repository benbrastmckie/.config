#!/usr/bin/env bash
# Test suite for todo-functions.sh cleanup functions
# Tests: has_uncommitted_changes(), create_cleanup_git_commit(), execute_cleanup_removal()

set -e

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Source library under test
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
export CLAUDE_PROJECT_DIR
source "$CLAUDE_PROJECT_DIR/lib/todo/todo-functions.sh"

# Test suite
test_suite="todo_functions_cleanup"

# ============================================================================
# Test: has_uncommitted_changes()
# ============================================================================

test_has_uncommitted_changes_clean_directory() {
  local test_name="has_uncommitted_changes_clean_directory"

  # Create test directory with committed file
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  echo "test" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"

  # Test: Clean directory should return 1 (no changes)
  if has_uncommitted_changes "$test_dir"; then
    echo "FAIL: $test_name - Clean directory reported as having changes"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  cleanup_test_dir "$test_dir"
  return 0
}

test_has_uncommitted_changes_modified_file() {
  local test_name="has_uncommitted_changes_modified_file"

  # Create test directory with modified file
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  echo "test" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"

  # Modify file
  echo "modified" >> file.txt

  # Test: Modified directory should return 0 (has changes)
  if ! has_uncommitted_changes "$test_dir"; then
    echo "FAIL: $test_name - Modified directory not detected"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  cleanup_test_dir "$test_dir"
  return 0
}

test_has_uncommitted_changes_untracked_file() {
  local test_name="has_uncommitted_changes_untracked_file"

  # Create test directory with untracked file
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  echo "test" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"

  # Add untracked file
  echo "untracked" > untracked.txt

  # Test: Untracked file should return 0 (has changes)
  if ! has_uncommitted_changes "$test_dir"; then
    echo "FAIL: $test_name - Untracked file not detected"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  cleanup_test_dir "$test_dir"
  return 0
}

test_has_uncommitted_changes_nonexistent_directory() {
  local test_name="has_uncommitted_changes_nonexistent_directory"

  local test_dir="/tmp/nonexistent_$$"

  # Test: Non-existent directory should return 1 (clean)
  if has_uncommitted_changes "$test_dir"; then
    echo "FAIL: $test_name - Non-existent directory reported as having changes"
    return 1
  fi

  echo "PASS: $test_name"
  return 0
}

# ============================================================================
# Test: create_cleanup_git_commit()
# ============================================================================

test_create_cleanup_git_commit_success() {
  local test_name="create_cleanup_git_commit_success"

  # Create test directory
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial file
  echo "test" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"

  # Create uncommitted change
  echo "modified" >> file.txt

  # Test: Create cleanup commit
  COMMIT_HASH=""
  if ! create_cleanup_git_commit 5; then
    echo "FAIL: $test_name - Failed to create git commit"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  # Verify commit hash set
  if [ -z "$COMMIT_HASH" ]; then
    echo "FAIL: $test_name - COMMIT_HASH not set"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  # Verify commit message
  local commit_msg=$(git log -1 --format=%s)
  if [[ ! "$commit_msg" =~ "pre-cleanup snapshot before /todo --clean" ]]; then
    echo "FAIL: $test_name - Incorrect commit message: $commit_msg"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  cleanup_test_dir "$test_dir"
  return 0
}

test_create_cleanup_git_commit_no_changes() {
  local test_name="create_cleanup_git_commit_no_changes"

  # Create test directory with no uncommitted changes
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  echo "test" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"

  # Test: Should succeed even with no changes
  COMMIT_HASH=""
  if ! create_cleanup_git_commit 0 2>/dev/null; then
    echo "FAIL: $test_name - Failed when no changes to commit"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  # COMMIT_HASH should be set to current HEAD
  if [ -z "$COMMIT_HASH" ]; then
    echo "FAIL: $test_name - COMMIT_HASH not set"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  cleanup_test_dir "$test_dir"
  return 0
}

# ============================================================================
# Test: execute_cleanup_removal()
# ============================================================================

test_execute_cleanup_removal_basic() {
  local test_name="execute_cleanup_removal_basic"

  # Create test repository
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir/.claude/specs"
  cd "$test_dir"

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create test project directories
  mkdir -p ".claude/specs/001_test_project"
  echo "test" > ".claude/specs/001_test_project/README.md"

  mkdir -p ".claude/specs/002_another_project"
  echo "test" > ".claude/specs/002_another_project/README.md"

  git add .
  git commit -q -m "Initial commit"

  # Create projects JSON
  local projects_json='[
    {"topic_name": "001_test_project", "title": "Test Project"},
    {"topic_name": "002_another_project", "title": "Another Project"}
  ]'

  # Test: Execute cleanup removal
  REMOVED_COUNT=0
  SKIPPED_COUNT=0
  FAILED_COUNT=0
  COMMIT_HASH=""

  if ! execute_cleanup_removal "$projects_json" "$test_dir/.claude/specs"; then
    echo "FAIL: $test_name - Cleanup removal failed"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  # Verify counts
  if [ "$REMOVED_COUNT" -ne 2 ]; then
    echo "FAIL: $test_name - Expected REMOVED_COUNT=2, got $REMOVED_COUNT"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  if [ "$SKIPPED_COUNT" -ne 0 ]; then
    echo "FAIL: $test_name - Expected SKIPPED_COUNT=0, got $SKIPPED_COUNT"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  # Verify directories removed
  if [ -d "$test_dir/.claude/specs/001_test_project" ]; then
    echo "FAIL: $test_name - Directory not removed: 001_test_project"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  cleanup_test_dir "$test_dir"
  return 0
}

test_execute_cleanup_removal_skip_uncommitted() {
  local test_name="execute_cleanup_removal_skip_uncommitted"

  # Create test repository
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir/.claude/specs"
  cd "$test_dir"

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create test project directories
  mkdir -p ".claude/specs/001_clean_project"
  echo "test" > ".claude/specs/001_clean_project/README.md"

  mkdir -p ".claude/specs/002_dirty_project"
  echo "test" > ".claude/specs/002_dirty_project/README.md"

  git add .
  git commit -q -m "Initial commit"

  # Modify one project (uncommitted changes)
  echo "modified" >> ".claude/specs/002_dirty_project/README.md"

  # Create projects JSON
  local projects_json='[
    {"topic_name": "001_clean_project", "title": "Clean Project"},
    {"topic_name": "002_dirty_project", "title": "Dirty Project"}
  ]'

  # Test: Execute cleanup removal
  REMOVED_COUNT=0
  SKIPPED_COUNT=0
  FAILED_COUNT=0
  COMMIT_HASH=""

  if ! execute_cleanup_removal "$projects_json" "$test_dir/.claude/specs"; then
    echo "FAIL: $test_name - Cleanup removal failed"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  # Verify counts
  if [ "$REMOVED_COUNT" -ne 1 ]; then
    echo "FAIL: $test_name - Expected REMOVED_COUNT=1, got $REMOVED_COUNT"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  if [ "$SKIPPED_COUNT" -ne 1 ]; then
    echo "FAIL: $test_name - Expected SKIPPED_COUNT=1, got $SKIPPED_COUNT"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  # Verify clean directory removed, dirty directory preserved
  if [ -d "$test_dir/.claude/specs/001_clean_project" ]; then
    echo "FAIL: $test_name - Clean directory not removed"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  if [ ! -d "$test_dir/.claude/specs/002_dirty_project" ]; then
    echo "FAIL: $test_name - Dirty directory was removed (should be skipped)"
    cleanup_test_dir "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  cleanup_test_dir "$test_dir"
  return 0
}

# ============================================================================
# Helper Functions
# ============================================================================

cleanup_test_dir() {
  local dir="$1"
  cd /tmp
  rm -rf "$dir" 2>/dev/null || true
}

# ============================================================================
# Run All Tests
# ============================================================================

main() {
  echo "Running $test_suite tests..."
  echo ""

  local passed=0
  local failed=0

  # Test has_uncommitted_changes()
  if test_has_uncommitted_changes_clean_directory; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_has_uncommitted_changes_modified_file; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_has_uncommitted_changes_untracked_file; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_has_uncommitted_changes_nonexistent_directory; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  # Test create_cleanup_git_commit()
  if test_create_cleanup_git_commit_success; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_create_cleanup_git_commit_no_changes; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  # Test execute_cleanup_removal()
  if test_execute_cleanup_removal_basic; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_execute_cleanup_removal_skip_uncommitted; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  # Summary
  echo ""
  echo "========================================="
  echo "Test Results: $test_suite"
  echo "========================================="
  echo "Passed: $passed"
  echo "Failed: $failed"
  echo "========================================="

  if [ $failed -eq 0 ]; then
    echo "All tests passed!"
    exit 0
  else
    echo "Some tests failed!"
    exit 1
  fi
}

# Run tests
main
