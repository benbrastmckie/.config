# Test Execution Report

## Metadata
- **Date**: 2025-11-29 00:00:00
- **Plan**: /home/benjamin/.config/.claude/specs/965_optimize_plan_command_performance/plans/001-optimize-plan-command-performance-plan.md
- **Test Framework**: bash-tests
- **Test Command**: bash .claude/tests/run_all_tests.sh
- **Exit Code**: 1
- **Execution Time**: 1m 18s (78 seconds)
- **Environment**: test

## Summary
- **Total Tests**: 677
- **Passed**: 672
- **Failed**: 5
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

1. **test_expand_collapse_hard_barriers**
   - Location: features/commands/test_expand_collapse_hard_barriers
   - Error: Missing merge verification check in /collapse phase verification block
   - Details: /collapse phase missing 3-block pattern verification

2. **test_command_remediation** (1/11 tests failed)
   - Location: features/commands/test_command_remediation
   - Error: Remediation test failure
   - Details: 1 of 11 tests failed in command remediation suite

3. **test_bash_error_compliance**
   - Location: features/commands/test_bash_error_compliance
   - Error: /repair command missing error trap in Block 2 (line ~345)
   - Details: 3/4 blocks have coverage, 1 executable block missing setup_bash_error_trap()

4. **test_no_if_negation_patterns**
   - Location: features/commands/test_no_if_negation_patterns
   - Error: Found 1 'if !' pattern in /todo.md:437
   - Details: All 'if !' patterns should be eliminated per standards

5. **validate_executable_doc_separation**
   - Location: scripts/validate_executable_doc_separation
   - Error: 1 validation(s) failed
   - Details: Documentation separation validation failure

## Full Output

```bash
════════════════════════════════════════════════
  Claude Code Test Suite Runner
════════════════════════════════════════════════

Pre-test validation: 0 empty topic directories

[0;34mRunning: test_plan_architect_revision_mode[0m
────────────────────────────────────────────────
[0;32m✓ test_plan_architect_revision_mode PASSED[0m (14 tests)

[0;34mRunning: test_offline_classification[0m
────────────────────────────────────────────────
[0;32m✓ test_offline_classification PASSED[0m (4 tests)

[0;34mRunning: test_scope_detection_ab[0m
────────────────────────────────────────────────
[0;32m✓ test_scope_detection_ab PASSED[0m (0 tests)

[0;34mRunning: test_scope_detection[0m
────────────────────────────────────────────────
[0;32m✓ test_scope_detection PASSED[0m (34 tests)

[0;34mRunning: test_workflow_detection[0m
────────────────────────────────────────────────
[0;32m✓ test_workflow_detection PASSED[0m (12 tests)

[0;34mRunning: test_build_task_delegation[0m
────────────────────────────────────────────────
[0;32m✓ test_build_task_delegation PASSED[0m (0 tests)

[0;34mRunning: test_expand_collapse_hard_barriers[0m
────────────────────────────────────────────────
[0;31m✗ test_expand_collapse_hard_barriers FAILED[0m
TEST: Verify /expand phase has 3-block pattern (Setup → Execute → Verify)
[0;32m✓ PASS[0m: ✓ /expand phase has complete hard barrier pattern (3a/3b/3c)
TEST: Verify /expand stage has 3-block pattern (Setup → Execute → Verify)
[0;32m✓ PASS[0m: ✓ /expand stage has complete hard barrier pattern (3a/3b/3c)
TEST: Verify /collapse phase has 3-block pattern (Setup → Execute → Verify)
[0;31m✗ FAIL[0m: Missing merge verification check in /collapse phase verification block
TEST_FAILED

[0;34mRunning: test_revise_error_recovery[0m
────────────────────────────────────────────────
[0;32m✓ test_revise_error_recovery PASSED[0m (18 tests)

[0;34mRunning: test_revise_long_prompt[0m
────────────────────────────────────────────────
[0;32m✓ test_revise_long_prompt PASSED[0m (13 tests)

[0;34mRunning: test_revise_preserve_completed[0m
────────────────────────────────────────────────
[0;32m✓ test_revise_preserve_completed PASSED[0m (9 tests)

[0;34mRunning: test_revise_small_plan[0m
────────────────────────────────────────────────
[0;32m✓ test_revise_small_plan PASSED[0m (23 tests)

[0;34mRunning: test_command_references[0m
────────────────────────────────────────────────
[0;32m✓ test_command_references PASSED[0m (0 tests)

[0;34mRunning: test_command_remediation[0m
────────────────────────────────────────────────
[0;31m✗ test_command_remediation FAILED[0m (1/11 tests failed)
[0;31m✗ FAIL[0m

[0;34mRunning: test_command_standards_compliance[0m
────────────────────────────────────────────────
[0;32m✓ test_command_standards_compliance PASSED[0m (0 tests)

[0;34mRunning: test_convert_docs_error_logging[0m
────────────────────────────────────────────────
[0;32m✓ test_convert_docs_error_logging PASSED[0m (0 tests)

[0;34mRunning: test_errors_report_generation[0m
────────────────────────────────────────────────
[0;32m✓ test_errors_report_generation PASSED[0m (12 tests)

[0;34mRunning: test_orchestration_commands[0m
────────────────────────────────────────────────
[0;32m✓ test_orchestration_commands PASSED[0m (0 tests)

[0;34mRunning: test_todo_hard_barrier[0m
────────────────────────────────────────────────
[0;32m✓ test_todo_hard_barrier PASSED[0m (1 tests)

[0;34mRunning: test_agent_validation[0m
────────────────────────────────────────────────
[0;32m✓ test_agent_validation PASSED[0m (0 tests)

[0;34mRunning: test_argument_capture[0m
────────────────────────────────────────────────
[0;32m✓ test_argument_capture PASSED[0m (10 tests)

[0;34mRunning: test_bash_command_fixes[0m
────────────────────────────────────────────────
[0;32m✓ test_bash_command_fixes PASSED[0m (0 tests)

[0;34mRunning: test_bash_error_compliance[0m
────────────────────────────────────────────────
[0;31m✗ test_bash_error_compliance FAILED[0m
╔══════════════════════════════════════════════════════════╗
║       ERR TRAP COMPLIANCE AUDIT                          ║
╠══════════════════════════════════════════════════════════╣
║ Verifying trap integration across all commands          ║
╚══════════════════════════════════════════════════════════╝

[0;32m✓[0m /plan: 5/5 blocks (100% coverage)
[0;32m✓[0m /build: 7/8 blocks (100% coverage, 1 doc block(s))
[0;32m✓[0m /debug: 10/11 blocks (100% coverage, 1 doc block(s))
[0;31m✗[0m /repair: 3/4 blocks (1 executable blocks missing traps)
  [1;33m→[0m Block 2 (line ~345): Missing setup_bash_error_trap()
TEST_FAILED

[0;34mRunning: test_bash_error_integration[0m
────────────────────────────────────────────────
[0;32m✓ test_bash_error_integration PASSED[0m (0 tests)

[0;34mRunning: test_compliance_remediation_phase7[0m
────────────────────────────────────────────────
[0;32m✓ test_compliance_remediation_phase7 PASSED[0m (0 tests)

[0;34mRunning: test_error_logging_compliance[0m
────────────────────────────────────────────────
[0;32m✓ test_error_logging_compliance PASSED[0m (0 tests)

[0;34mRunning: test_history_expansion[0m
────────────────────────────────────────────────
[0;32m✓ test_history_expansion PASSED[0m (0 tests)

[0;34mRunning: test_no_if_negation_patterns[0m
────────────────────────────────────────────────
[0;31m✗ test_no_if_negation_patterns FAILED[0m
[0;32m✓[0m Found 14 command files to validate
[1;33mℹ[0m Testing 'if !' pattern detection
  ❌ /home/benjamin/.config/.claude/commands/todo.md:437
[0;31m✗[0m Found 1 'if !' patterns
  [1;33mReason:[0m All if ! patterns should be eliminated
[1;33mℹ[0m Testing 'elif !' pattern detection
[0;32m✓[0m No 'elif !' patterns found in command files

===============================
Test Results
===============================
Tests Run:    3
Tests Passed: [0;32m2[0m
Tests Failed: [0;31m1[0m

[0;31mFAILURE[0m: Some tests failed

Review test errors: /errors --log-file .claude/tests/logs/test-errors.jsonl
Or: /errors --command test_no_if_negation_patterns
TEST_FAILED

[Remaining test output truncated for brevity - 110 test suites passed, 5 failed]

════════════════════════════════════════════════
  Test Results Summary
════════════════════════════════════════════════
Test Suites Passed:  [0;32m110[0m
Test Suites Failed:  [0;31m5[0m
Total Individual Tests: 677

[0;31m✗ SOME TESTS FAILED[0m
```
