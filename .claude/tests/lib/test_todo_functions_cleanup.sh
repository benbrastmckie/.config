#!/usr/bin/env bash
# Test suite for todo-functions.sh cleanup functions
# Tests: parse_todo_sections(), has_uncommitted_changes(), create_cleanup_git_commit(), execute_cleanup_removal()

set -e

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Source library under test
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
export CLAUDE_PROJECT_DIR
source "$CLAUDE_PROJECT_DIR/.claude/lib/todo/todo-functions.sh"

# Test suite
test_suite="todo_functions_cleanup"

# ============================================================================
# Test: parse_todo_sections()
# ============================================================================

test_parse_todo_sections_empty_file() {
  local test_name="parse_todo_sections_empty_file"

  # Create empty TODO.md
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir/.claude"
  local todo_path="$test_dir/.claude/TODO.md"
  touch "$todo_path"

  # Test: Empty file should return empty JSON array
  CLAUDE_PROJECT_DIR="$test_dir"
  local result
  result=$(parse_todo_sections "$todo_path")

  if [ "$result" != "[]" ]; then
    echo "FAIL: $test_name - Expected [], got $result"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

test_parse_todo_sections_nonexistent_file() {
  local test_name="parse_todo_sections_nonexistent_file"

  # Test: Non-existent file should return empty JSON array
  local result
  result=$(parse_todo_sections "/tmp/nonexistent_todo_$$.md")

  if [ "$result" != "[]" ]; then
    echo "FAIL: $test_name - Expected [], got $result"
    return 1
  fi

  echo "PASS: $test_name"
  return 0
}

test_parse_todo_sections_with_entries() {
  local test_name="parse_todo_sections_with_entries"

  # Create test directory structure
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir/.claude/specs/001_test_completed"
  mkdir -p "$test_dir/.claude/specs/002_test_abandoned"
  mkdir -p "$test_dir/.claude/specs/003_test_superseded"

  # Create TODO.md with entries in each section
  local todo_path="$test_dir/.claude/TODO.md"
  cat > "$todo_path" << 'EOF'
# TODO

## In Progress

(No plans currently in progress)

## Not Started

- [ ] **Test Not Started** - Description [.claude/specs/099_not_started/plans/001.md]

## Backlog

Some backlog items

## Superseded

- [~] **Test Superseded** - Description [.claude/specs/003_test_superseded/plans/001.md]

## Abandoned

- [x] **Test Abandoned (002)** - Description [.claude/specs/002_test_abandoned/plans/001.md]

## Completed

- [x] **Test Completed (001)** - Description [.claude/specs/001_test_completed/plans/001.md]
EOF

  # Set CLAUDE_PROJECT_DIR for the function
  CLAUDE_PROJECT_DIR="$test_dir"

  # Test: Should find entries in Completed, Abandoned, Superseded sections
  local result
  result=$(parse_todo_sections "$todo_path")

  local count
  count=$(echo "$result" | jq 'length')

  if [ "$count" -ne 3 ]; then
    echo "FAIL: $test_name - Expected 3 entries, got $count"
    echo "Result: $result"
    rm -rf "$test_dir"
    return 1
  fi

  # Verify sections
  local completed_count
  completed_count=$(echo "$result" | jq '[.[] | select(.section == "Completed")] | length')
  if [ "$completed_count" -ne 1 ]; then
    echo "FAIL: $test_name - Expected 1 Completed entry, got $completed_count"
    rm -rf "$test_dir"
    return 1
  fi

  local abandoned_count
  abandoned_count=$(echo "$result" | jq '[.[] | select(.section == "Abandoned")] | length')
  if [ "$abandoned_count" -ne 1 ]; then
    echo "FAIL: $test_name - Expected 1 Abandoned entry, got $abandoned_count"
    rm -rf "$test_dir"
    return 1
  fi

  local superseded_count
  superseded_count=$(echo "$result" | jq '[.[] | select(.section == "Superseded")] | length')
  if [ "$superseded_count" -ne 1 ]; then
    echo "FAIL: $test_name - Expected 1 Superseded entry, got $superseded_count"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

test_parse_todo_sections_extracts_from_path() {
  local test_name="parse_todo_sections_extracts_from_path"

  # Create test directory (no parentheses in title)
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir/.claude/specs/999_path_only"

  # Create TODO.md with entry that only has topic number in path
  local todo_path="$test_dir/.claude/TODO.md"
  cat > "$todo_path" << 'EOF'
# TODO

## Completed

- [x] **No Parens Title** - Desc [.claude/specs/999_path_only/plans/001.md]
EOF

  CLAUDE_PROJECT_DIR="$test_dir"
  local result
  result=$(parse_todo_sections "$todo_path")

  local count
  count=$(echo "$result" | jq 'length')

  if [ "$count" -ne 1 ]; then
    echo "FAIL: $test_name - Expected 1 entry, got $count"
    rm -rf "$test_dir"
    return 1
  fi

  # Verify topic_name was extracted from path
  local topic_name
  topic_name=$(echo "$result" | jq -r '.[0].topic_name')
  if [ "$topic_name" != "999_path_only" ]; then
    echo "FAIL: $test_name - Expected topic_name='999_path_only', got '$topic_name'"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

test_parse_todo_sections_skips_missing_directories() {
  local test_name="parse_todo_sections_skips_missing_directories"

  # Create test directory WITHOUT the referenced spec directory
  local test_dir="/tmp/test_todo_cleanup_$$"
  mkdir -p "$test_dir/.claude/specs"

  # Create TODO.md with entry referencing non-existent directory
  local todo_path="$test_dir/.claude/TODO.md"
  cat > "$todo_path" << 'EOF'
# TODO

## Completed

- [x] **Missing Dir (888)** - Desc [.claude/specs/888_missing/plans/001.md]
EOF

  CLAUDE_PROJECT_DIR="$test_dir"
  local result
  result=$(parse_todo_sections "$todo_path")

  local count
  count=$(echo "$result" | jq 'length')

  if [ "$count" -ne 0 ]; then
    echo "FAIL: $test_name - Expected 0 entries (dir missing), got $count"
    rm -rf "$test_dir"
    return 1
  fi

  echo "PASS: $test_name"
  rm -rf "$test_dir"
  return 0
}

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

  # Test parse_todo_sections()
  if test_parse_todo_sections_empty_file; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_parse_todo_sections_nonexistent_file; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_parse_todo_sections_with_entries; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_parse_todo_sections_extracts_from_path; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_parse_todo_sections_skips_missing_directories; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

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
