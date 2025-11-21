# Test Execution Report

## Metadata
- **Date**: 2025-11-20 18:25:37
- **Plan**: /home/benjamin/.config/.claude/specs/876_bash_history_expansion_ui_errors_fix/plans/001_bash_history_expansion_ui_errors_fix_plan.md
- **Test Framework**: bash-tests
- **Test Command**: bash .claude/tests/run_all_tests.sh
- **Exit Code**: 1
- **Execution Time**: 1m 46s
- **Environment**: test

## Summary
- **Total Tests**: 448
- **Passed**: 85
- **Failed**: 10
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

1. test_bash_error_compliance
   - /build: 5/7 blocks (1 executable blocks missing traps)
   - Block 3 (line ~633): Missing setup_bash_error_trap()

2. test_directory_naming_integration
   - 46 failures related to sanitize_topic_name function

3. test_directory_naming_race
   - Parallel process coordination timing issues (race conditions)

4. test_duplicate_commands
   - Command discovery hierarchy validation failures

5. test_interactive_flow
   - abort_cleanup function not found errors

6. test_parallel_transitions
   - Race condition in state machine parallel transitions

7. test_picker_artifact_sync_conflicts
   - Test failures in Phase 3 artifact sync (picker tests)

8. test_state_save_atomic
   - grep: .claude/specs/*/state.json: No such file or directory

9. test_topic_name_sanitization
   - 46/60 tests failed - sanitize_topic_name: command not found

10. test_topic_naming
    - sanitize_topic_name: command not found

Additional failures:
11. test_topic_slug_validation
    - extract_significant_words: command not found

12. validate_executable_doc_separation
    - 2 validation failures for command guide cross-references

## Full Output

```bash
════════════════════════════════════════════════
  Claude Code Test Suite Runner
════════════════════════════════════════════════

Pre-test validation: 1 empty topic directories

Running: test_agent_validation
────────────────────────────────────────────────
✓ test_agent_validation PASSED (0 tests)

Running: test_all_fixes_integration
────────────────────────────────────────────────
✓ test_all_fixes_integration PASSED (3 tests)

Running: test_argument_capture
────────────────────────────────────────────────
✓ test_argument_capture PASSED (0 tests)

Running: test_array_serialization
────────────────────────────────────────────────
✓ test_array_serialization PASSED (0 tests)

Running: test_atomic_topic_allocation
────────────────────────────────────────────────
✓ test_atomic_topic_allocation PASSED (0 tests)

Running: test_bash_command_fixes
────────────────────────────────────────────────
✓ test_bash_command_fixes PASSED (0 tests)

Running: test_bash_error_compliance
────────────────────────────────────────────────
✗ test_bash_error_compliance FAILED
╔══════════════════════════════════════════════════════════╗
║       ERR TRAP COMPLIANCE AUDIT                          ║
╠══════════════════════════════════════════════════════════╣
║ Verifying trap integration across all commands          ║
╚══════════════════════════════════════════════════════════╝

✓ /plan: 4/4 blocks (100% coverage)
✗ /build: 5/7 blocks (1 executable blocks missing traps)
  → Block 3 (line ~633): Missing setup_bash_error_trap()
TEST_FAILED

[Full test output truncated for brevity - see above summary for key failures]

════════════════════════════════════════════════
✓ NO POLLUTION DETECTED
════════════════════════════════════════════════
Post-test validation: 1 empty topic directories

════════════════════════════════════════════════
  Test Results Summary
════════════════════════════════════════════════
Test Suites Passed:  85
Test Suites Failed:  10
Total Individual Tests: 448

✗ SOME TESTS FAILED
```
