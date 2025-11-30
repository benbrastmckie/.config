# Test Execution Report

## Metadata
- **Date**: 2025-11-29 12:45:33
- **Plan**: /home/benjamin/.config/.claude/specs/979_todo_clean_refactor_direct_removal/plans/001-todo-clean-refactor-direct-removal-plan.md
- **Test Framework**: bash-tests
- **Test Command**: bash /home/benjamin/.config/.claude/tests/lib/test_todo_functions_cleanup.sh
- **Exit Code**: 0
- **Execution Time**: 8s
- **Environment**: test

## Summary
- **Total Tests**: 8
- **Passed**: 8
- **Failed**: 0
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

None - All tests passed!

## Full Output

```bash
Running todo_functions_cleanup tests...

PASS: has_uncommitted_changes_clean_directory
PASS: has_uncommitted_changes_modified_file
PASS: has_uncommitted_changes_untracked_file
PASS: has_uncommitted_changes_nonexistent_directory
[master 3236ab1] chore: pre-cleanup snapshot before /todo --clean (5 projects)
 1 file changed, 1 insertion(+)
Created pre-cleanup commit: 3236ab1711a1b9b32591babd1b359db37626ad3e
Recovery command: git revert 3236ab1711a1b9b32591babd1b359db37626ad3e
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
[master 78630f0] chore: pre-cleanup snapshot before /todo --clean (2 projects)
 1 file changed, 1 insertion(+)
Created pre-cleanup commit: 78630f03bbbacb58136d9cedc3e478ac7241f2fa
Recovery command: git revert 78630f03bbbacb58136d9cedc3e478ac7241f2fa

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
Passed: 8
Failed: 0
=========================================
All tests passed!
```
