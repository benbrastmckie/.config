# Test Execution Report

## Metadata
- **Date**: 2025-11-30 10:49:20
- **Plan**: /home/benjamin/.config/.claude/specs/987_todo_command_sections_review/plans/001-todo-command-sections-review-plan.md
- **Test Framework**: bash-tests
- **Test Command**: bash .claude/tests/lib/test_todo_functions_cleanup.sh
- **Exit Code**: 0
- **Execution Time**: 1s
- **Environment**: test

## Summary
- **Total Tests**: 13
- **Passed**: 13
- **Failed**: 0
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

None - all tests passed successfully!

## Test List

### Passed Tests (13)
1. parse_todo_sections_empty_file
2. parse_todo_sections_nonexistent_file
3. parse_todo_sections_with_entries
4. parse_todo_sections_extracts_from_path
5. parse_todo_sections_skips_missing_directories
6. has_uncommitted_changes_clean_directory
7. has_uncommitted_changes_modified_file
8. has_uncommitted_changes_untracked_file
9. has_uncommitted_changes_nonexistent_directory
10. create_cleanup_git_commit_success
11. create_cleanup_git_commit_no_changes
12. execute_cleanup_removal_basic
13. execute_cleanup_removal_skip_uncommitted

## Full Output

```bash
Running todo_functions_cleanup tests...

PASS: parse_todo_sections_empty_file
PASS: parse_todo_sections_nonexistent_file
PASS: parse_todo_sections_with_entries
PASS: parse_todo_sections_extracts_from_path
PASS: parse_todo_sections_skips_missing_directories
PASS: has_uncommitted_changes_clean_directory
PASS: has_uncommitted_changes_modified_file
PASS: has_uncommitted_changes_untracked_file
PASS: has_uncommitted_changes_nonexistent_directory
[master 220a78f] chore: pre-cleanup snapshot before /todo --clean (5 projects)
 1 file changed, 1 insertion(+)
Created pre-cleanup commit: 220a78f022d74e2048bb7ac70794c6775d90a103
Recovery command: git revert 220a78f022d74e2048bb7ac70794c6775d90a103
PASS: create_cleanup_git_commit_success
On branch master
nothing to commit, working tree clean
PASS: create_cleanup_git_commit_no_changes
Checking for uncommitted changes in eligible projects...
On branch master
nothing to commit, working tree clean
WARNING: No changes to commit (repository already clean)

Removing eligible project directories...
  ✓ REMOVED: 001_test_project
  ✓ REMOVED: 002_another_project

Cleanup summary:
  Removed: 2
  Skipped: 0
  Failed: 0

PASS: execute_cleanup_removal_basic
Checking for uncommitted changes in eligible projects...
  ⚠ SKIP: 002_dirty_project (uncommitted changes detected)
[master 2900274] chore: pre-cleanup snapshot before /todo --clean (2 projects)
 1 file changed, 1 insertion(+)
Created pre-cleanup commit: 2900274fe081f6a5cfed2b57cc1ca7aaaab74c91
Recovery command: git revert 2900274fe081f6a5cfed2b57cc1ca7aaaab74c91

Removing eligible project directories...
  ✓ REMOVED: 001_clean_project

Cleanup summary:
  Removed: 1
  Skipped: 1
  Failed: 0

PASS: execute_cleanup_removal_skip_uncommitted

=========================================
Test Results: todo_functions_cleanup
=========================================
Passed: 13
Failed: 0
=========================================
All tests passed!
```
