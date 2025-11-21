# Test Execution Report

## Metadata
- **Date**: 2025-11-20 23:28:21
- **Plan**: /home/benjamin/.config/.claude/specs/878_artifact_console_summary_format/plans/001_artifact_console_summary_format_plan.md
- **Test Framework**: bash-tests
- **Test Command**: /home/benjamin/.config/.claude/tests/run_all_tests.sh
- **Exit Code**: 1
- **Execution Time**: < 1 minute
- **Environment**: test

## Summary
- **Total Tests**: 448 individual tests across 95 test suites
- **Test Suites Passed**: 84
- **Test Suites Failed**: 11
- **Failed**: 11 test suites
- **Coverage**: N/A

## Failed Tests

1. **test_bash_error_compliance** - ERR trap coverage validation
   - /build command: Block 3 (line ~637) missing setup_bash_error_trap()

2. **test_command_topic_allocation** - Error handling validation
   - plan.md missing error handling for allocation
   - debug.md missing error handling for allocation
   - research.md missing error handling for allocation

3. **test_directory_naming_integration** - Directory naming workflow
   - Error: sanitize_topic_name command not found

4. **test_error_logging_compliance** - Error logging integration
   - 4/13 commands missing error logging integration

5. **test_plan_progress_markers** - Plan marker lifecycle
   - Cannot mark Phase 1 complete with incomplete tasks

6. **test_research_err_trap** - Error trap capture
   - Unexpected capture in T5 (pre-trap error scenario)

7. **test_semantic_slug_commands** - Command slug generation
   - 1 test failed (out of 23 tests)

8. **test_topic_name_sanitization** - Topic name sanitization
   - 46 tests failed (out of 60 tests)
   - sanitize_topic_name function not found in test environment

9. **test_topic_naming** - Topic naming algorithm
   - sanitize_topic_name function not found

10. **test_topic_slug_validation** - Topic slug validation
    - extract_significant_words function not found

11. **validate_executable_doc_separation** - Documentation validation
    - 2 validations failed
    - Guide files missing cross-references

## Full Output

```bash
════════════════════════════════════════════════
  Claude Code Test Suite Runner
════════════════════════════════════════════════

Pre-test validation: 1 empty topic directories

[0;34mRunning: test_agent_validation[0m
────────────────────────────────────────────────
[0;32m✓ test_agent_validation PASSED[0m (0 tests)

[0;34mRunning: test_all_fixes_integration[0m
────────────────────────────────────────────────
[0;32m✓ test_all_fixes_integration PASSED[0m (3 tests)

[0;34mRunning: test_argument_capture[0m
────────────────────────────────────────────────
[0;32m✓ test_argument_capture PASSED[0m (0 tests)

[0;34mRunning: test_array_serialization[0m
────────────────────────────────────────────────
[0;32m✓ test_array_serialization PASSED[0m (0 tests)

[0;34mRunning: test_atomic_topic_allocation[0m
────────────────────────────────────────────────
[0;32m✓ test_atomic_topic_allocation PASSED[0m (0 tests)

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

[0;32m✓[0m /plan: 4/4 blocks (100% coverage)
[0;31m✗[0m /build: 5/7 blocks (1 executable blocks missing traps)
  [1;33m→[0m Block 3 (line ~637): Missing setup_bash_error_trap()
TEST_FAILED

[0;34mRunning: test_bash_error_integration[0m
────────────────────────────────────────────────
[0;32m✓ test_bash_error_integration PASSED[0m (0 tests)

[0;34mRunning: test_build_state_transitions[0m
────────────────────────────────────────────────
[0;32m✓ test_build_state_transitions PASSED[0m (0 tests)

[0;34mRunning: test_checkpoint_parallel_ops[0m
────────────────────────────────────────────────
[0;32m✓ test_checkpoint_parallel_ops PASSED[0m (0 tests)

[0;34mRunning: test_checkpoint_schema_v2[0m
────────────────────────────────────────────────
[0;32m✓ test_checkpoint_schema_v2 PASSED[0m (25 tests)

[0;34mRunning: test_checkpoint_v2_simple[0m
────────────────────────────────────────────────
[0;32m✓ test_checkpoint_v2_simple PASSED[0m (8 tests)

[0;34mRunning: test_command_integration[0m
────────────────────────────────────────────────
[0;32m✓ test_command_integration PASSED[0m (41 tests)

[0;34mRunning: test_command_references[0m
────────────────────────────────────────────────
[0;32m✓ test_command_references PASSED[0m (0 tests)

[0;34mRunning: test_command_remediation[0m
────────────────────────────────────────────────
[0;32m✓ test_command_remediation PASSED[0m (11 tests)

[0;34mRunning: test_command_standards_compliance[0m
────────────────────────────────────────────────
[0;32m✓ test_command_standards_compliance PASSED[0m (0 tests)

[0;34mRunning: test_command_topic_allocation[0m
────────────────────────────────────────────────
[0;31m✗ test_command_topic_allocation FAILED[0m
[0;32mPASS[0m: All commands use initialize_workflow_paths()
[0;32mPASS[0m: No commands use unsafe count+increment pattern
[0;31mFAIL[0m: All commands have error handling for allocation - plan.md missing error handling
[0;31mFAIL[0m: All commands have error handling for allocation - debug.md missing error handling
[0;31mFAIL[0m: All commands have error handling for allocation - research.md missing error handling
[0;32mPASS[0m: All commands use TOPIC_PATH from initialize_workflow_paths
[0;32mPASS[0m: Lock file cleaned up after allocation
[0;32mPASS[0m: Documentation includes atomic allocation section
[0;32mPASS[0m: Migration guide exists (skipped - consolidated into other docs)
[0;32mPASS[0m: Concurrent library allocation (20 parallel)
[0;32mPASS[0m: Sequential numbering verification
[0;32mPASS[0m: High concurrency stress test (50 parallel) (0% collision rate)
[0;33mWARN[0m: Permission denied handling - Skipped (environment-dependent)

=== Test Summary ===
Passed: 11
Failed: 3

[0;31m3 test(s) failed[0m
TEST_FAILED

[0;34mRunning: test_compliance_remediation_phase7[0m
────────────────────────────────────────────────
[0;32m✓ test_compliance_remediation_phase7 PASSED[0m (0 tests)

[0;34mRunning: test_convert_docs_concurrency[0m
────────────────────────────────────────────────
[0;32m✓ test_convert_docs_concurrency PASSED[0m (0 tests)

[0;34mRunning: test_convert_docs_edge_cases[0m
────────────────────────────────────────────────
[0;32m✓ test_convert_docs_edge_cases PASSED[0m (0 tests)

[0;34mRunning: test_convert_docs_filenames[0m
────────────────────────────────────────────────
[0;32m✓ test_convert_docs_filenames PASSED[0m (0 tests)

[0;34mRunning: test_convert_docs_parallel[0m
────────────────────────────────────────────────
[0;32m✓ test_convert_docs_parallel PASSED[0m (0 tests)

[0;34mRunning: test_convert_docs_validation[0m
────────────────────────────────────────────────
[0;32m✓ test_convert_docs_validation PASSED[0m (0 tests)

[0;34mRunning: test_cross_block_function_availability[0m
────────────────────────────────────────────────
[0;32m✓ test_cross_block_function_availability PASSED[0m (0 tests)

[0;34mRunning: test_debug[0m
────────────────────────────────────────────────
[0;32m✓ test_debug PASSED[0m (0 tests)

[0;34mRunning: test_detect_project_dir[0m
────────────────────────────────────────────────
[0;32m✓ test_detect_project_dir PASSED[0m (0 tests)

[0;34mRunning: test_directory_naming_integration[0m
────────────────────────────────────────────────
[0;31m✗ test_directory_naming_integration FAILED[0m
========================================
Directory Naming Integration Test Suite
========================================

Testing topic directory creation for:
  - /plan command
  - /research command
  - /debug command
  - /optimize-claude command

Testing /plan command simulations:

/home/benjamin/.config/.claude/tests/test_directory_naming_integration.sh: line 115: sanitize_topic_name: command not found

Cleaning up test directories...
  Removed: /tmp/test_directory_naming_312291
TEST_FAILED

[0;34mRunning: test_empty_directory_detection[0m
────────────────────────────────────────────────
[0;32m✓ test_empty_directory_detection PASSED[0m (0 tests)

[0;34mRunning: test_error_logging_compliance[0m
────────────────────────────────────────────────
[0;31m✗ test_error_logging_compliance FAILED[0m

==========================================
Summary
==========================================
Compliant:     9/13 commands
Non-compliant: 4/13 commands

⚠️  Some commands are missing error logging integration.

Integration steps:
1. Source error-handling library
2. Set workflow metadata (COMMAND_NAME, WORKFLOW_ID, USER_ARGS)
3. Initialize error log with ensure_error_log_exists
4. Log errors with log_command_error at all error points
5. Parse subagent errors with parse_subagent_error

See: .claude/docs/concepts/patterns/error-handling.md
See: .claude/docs/reference/architecture/error-handling.md#standard-17

TEST_FAILED

[0;34mRunning: test_error_logging[0m
────────────────────────────────────────────────
[0;32m✓ test_error_logging PASSED[0m (0 tests)

[0;34mRunning: test_error_recovery[0m
────────────────────────────────────────────────
[0;32m✓ test_error_recovery PASSED[0m (0 tests)

[0;34mRunning: test_git_commit_utils[0m
────────────────────────────────────────────────
[0;32m✓ test_git_commit_utils PASSED[0m (0 tests)

[0;34mRunning: test_hierarchy_updates[0m
────────────────────────────────────────────────
[0;32m✓ test_hierarchy_updates PASSED[0m (0 tests)

[0;34mRunning: test_history_expansion[0m
────────────────────────────────────────────────
[0;32m✓ test_history_expansion PASSED[0m (0 tests)

[0;34mRunning: test_library_deduplication[0m
────────────────────────────────────────────────
[0;32m✓ test_library_deduplication PASSED[0m (0 tests)

[0;34mRunning: test_library_references[0m
────────────────────────────────────────────────
[0;32m✓ test_library_references PASSED[0m (0 tests)

[0;34mRunning: test_library_sourcing[0m
────────────────────────────────────────────────
[0;32m✓ test_library_sourcing PASSED[0m (5 tests)

[0;34mRunning: test_llm_classifier[0m
────────────────────────────────────────────────
[0;32m✓ test_llm_classifier PASSED[0m (36 tests)

[0;34mRunning: test_model_optimization[0m
────────────────────────────────────────────────
[0;32m✓ test_model_optimization PASSED[0m (0 tests)

[0;34mRunning: test_offline_classification[0m
────────────────────────────────────────────────
[0;32m✓ test_offline_classification PASSED[0m (4 tests)

[0;34mRunning: test_optimize_claude_enhancements[0m
────────────────────────────────────────────────
[0;32m✓ test_optimize_claude_enhancements PASSED[0m (8 tests)

[0;34mRunning: test_orchestration_commands[0m
────────────────────────────────────────────────
[0;32m✓ test_orchestration_commands PASSED[0m (0 tests)

[0;34mRunning: test_overview_synthesis[0m
────────────────────────────────────────────────
[0;32m✓ test_overview_synthesis PASSED[0m (16 tests)

[0;34mRunning: test_parallel_agents[0m
────────────────────────────────────────────────
[0;32m✓ test_parallel_agents PASSED[0m (0 tests)

[0;34mRunning: test_parallel_collapse[0m
────────────────────────────────────────────────
[0;32m✓ test_parallel_collapse PASSED[0m (0 tests)

[0;34mRunning: test_parallel_expansion[0m
────────────────────────────────────────────────
[0;32m✓ test_parallel_expansion PASSED[0m (0 tests)

[0;34mRunning: test_parallel_waves[0m
────────────────────────────────────────────────
[0;32m✓ test_parallel_waves PASSED[0m (0 tests)

[0;34mRunning: test_parsing_utilities[0m
────────────────────────────────────────────────
[0;32m✓ test_parsing_utilities PASSED[0m (14 tests)

[0;34mRunning: test_partial_success[0m
────────────────────────────────────────────────
[0;32m✓ test_partial_success PASSED[0m (0 tests)

[0;34mRunning: test_phase2_caching[0m
────────────────────────────────────────────────
[0;32m✓ test_phase2_caching PASSED[0m (5 tests)

[0;34mRunning: test_plan_progress_markers[0m
────────────────────────────────────────────────
[0;31m✗ test_plan_progress_markers FAILED[0m
Testing add_in_progress_marker...
  PASS: add_in_progress_marker replaces NOT STARTED
  PASS: add_in_progress_marker adds to unmarked phase
  PASS: add_in_progress_marker targets correct phase

Testing add_complete_marker...
  PASS: add_complete_marker replaces IN PROGRESS
  PASS: add_complete_marker replaces NOT STARTED
  PASS: add_complete_marker adds to unmarked phase

Testing add_not_started_markers...
Added [NOT STARTED] markers to 2 phases in legacy plan
  PASS: add_not_started_markers adds to all phases
Added [NOT STARTED] markers to 1 phases in legacy plan
  PASS: add_not_started_markers preserves existing markers

Testing marker lifecycle...
  PASS: Lifecycle: Phase 1 NOT STARTED -> IN PROGRESS
Error: Cannot mark Phase 1 complete - incomplete tasks remain
TEST_FAILED

[0;34mRunning: test_plan_updates[0m
────────────────────────────────────────────────
[0;32m✓ test_plan_updates PASSED[0m (0 tests)

[0;34mRunning: test_progress_dashboard[0m
────────────────────────────────────────────────
[0;32m✓ test_progress_dashboard PASSED[0m (0 tests)

[0;34mRunning: test_progressive_collapse[0m
────────────────────────────────────────────────
[0;32m✓ test_progressive_collapse PASSED[0m (15 tests)

[0;34mRunning: test_progressive_expansion[0m
────────────────────────────────────────────────
[0;32m✓ test_progressive_expansion PASSED[0m (20 tests)

[0;34mRunning: test_progressive_roundtrip[0m
────────────────────────────────────────────────
[0;32m✓ test_progressive_roundtrip PASSED[0m (10 tests)

[0;34mRunning: test_recovery_integration[0m
────────────────────────────────────────────────
[0;32m✓ test_recovery_integration PASSED[0m (0 tests)

[0;34mRunning: test_repair_workflow[0m
────────────────────────────────────────────────
[0;32m✓ test_repair_workflow PASSED[0m (10 tests)

[0;34mRunning: test_report_multi_agent_pattern[0m
────────────────────────────────────────────────
[0;32m✓ test_report_multi_agent_pattern PASSED[0m (0 tests)

[0;34mRunning: test_research_err_trap[0m
────────────────────────────────────────────────
[0;31m✗ test_research_err_trap FAILED[0m
  Details: Unexpected capture (should be impossible)

Running T6: State file missing (existing error handling)...
[0;32m✓[0m T6: State file missing (existing check)

==================================
Test Summary
==================================
Mode: with-traps
Tests Run: 6
[0;32mPassed: 5[0m
[0;31mFailed: 1[0m

Error Capture Rate: 83%

Expected with traps: 5/6 tests (83%) - all except T5 (pre-trap error)
==================================

Results saved to: /home/benjamin/.config/.claude/tests/logs/with-traps-results.log
TEST_FAILED

[0;34mRunning: test_return_code_verification[0m
────────────────────────────────────────────────
[0;32m✓ test_return_code_verification PASSED[0m (0 tests)

[0;34mRunning: test_revise_automode[0m
────────────────────────────────────────────────
[0;32m✓ test_revise_automode PASSED[0m (45 tests)

[0;34mRunning: test_scope_detection_ab[0m
────────────────────────────────────────────────
[0;32m✓ test_scope_detection_ab PASSED[0m (0 tests)

[0;34mRunning: test_scope_detection[0m
────────────────────────────────────────────────
[0;32m✓ test_scope_detection PASSED[0m (34 tests)

[0;34mRunning: test_semantic_slug_commands[0m
────────────────────────────────────────────────
[0;31m✗ test_semantic_slug_commands FAILED[0m
  [PASS] Scope 'research-and-plan' accepted
  [PASS] Scope 'full-implementation' accepted
  [PASS] Scope 'debug-only' accepted

Test Suite 5: Edge cases and error handling
--------------------------------------------
  [PASS] Short description handled: fix_bug
  [PASS] Numbers and technical terms preserved: fix_issue_123_in_api_v2
  [PASS] Special characters removed: fix_bug_with_useremailcom
  [PASS] Empty description handled without crash

========================================
TEST RESULTS
========================================
Tests run: 23
Passed: 22
Failed: 1

[FAILURE] Some tests failed
TEST_FAILED

[0;34mRunning: test_smart_checkpoint_resume[0m
────────────────────────────────────────────────
[0;32m✓ test_smart_checkpoint_resume PASSED[0m (0 tests)

[0;34mRunning: test_state_file_path_consistency[0m
────────────────────────────────────────────────
[0;32m✓ test_state_file_path_consistency PASSED[0m (0 tests)

[0;34mRunning: test_state_machine_persistence[0m
────────────────────────────────────────────────
[0;32m✓ test_state_machine_persistence PASSED[0m (16 tests)

[0;34mRunning: test_state_management[0m
────────────────────────────────────────────────
[0;32m✓ test_state_management PASSED[0m (20 tests)

[0;34mRunning: test_state_persistence[0m
────────────────────────────────────────────────
[0;32m✓ test_state_persistence PASSED[0m (0 tests)

[0;34mRunning: test_subprocess_isolation_plan[0m
────────────────────────────────────────────────
[0;32m✓ test_subprocess_isolation_plan PASSED[0m (0 tests)

[0;34mRunning: test_supervisor_checkpoint_old[0m
────────────────────────────────────────────────
[0;32m✓ test_supervisor_checkpoint_old PASSED[0m (0 tests)

[0;34mRunning: test_supervisor_checkpoint[0m
────────────────────────────────────────────────
[0;32m✓ test_supervisor_checkpoint PASSED[0m (0 tests)

[0;34mRunning: test_system_wide_location[0m
────────────────────────────────────────────────
[0;32m✓ test_system_wide_location PASSED[0m (0 tests)

[0;34mRunning: test_template_integration[0m
────────────────────────────────────────────────
[0;32m✓ test_template_integration PASSED[0m (0 tests)

[0;34mRunning: test_template_system[0m
────────────────────────────────────────────────
[0;32m✓ test_template_system PASSED[0m (26 tests)

[0;34mRunning: test_test_executor_behavioral_compliance[0m
────────────────────────────────────────────────
[0;32m✓ test_test_executor_behavioral_compliance PASSED[0m (0 tests)

[0;34mRunning: test_topic_decomposition[0m
────────────────────────────────────────────────
[0;32m✓ test_topic_decomposition PASSED[0m (0 tests)

[0;34mRunning: test_topic_filename_generation[0m
────────────────────────────────────────────────
[0;32m✓ test_topic_filename_generation PASSED[0m (15 tests)

[0;34mRunning: test_topic_name_sanitization[0m
────────────────────────────────────────────────
[0;31m✗ test_topic_name_sanitization FAILED[0m
    Expected: 'jwt_401_error'
    Actual:   ''
/home/benjamin/.config/.claude/tests/test_topic_name_sanitization.sh: line 228: sanitize_topic_name: command not found
  ✗ Mixed artifacts
    Expected: 'findings'
    Actual:   ''
/home/benjamin/.config/.claude/tests/test_topic_name_sanitization.sh: line 231: sanitize_topic_name: command not found
  ✗ Complex real example
    Expected: 'authentication_patterns'
    Actual:   ''

========================================
Test Summary
========================================
Total Tests:  60
Passed:       14
Failed:       46

✗ Some tests failed
TEST_FAILED

[0;34mRunning: test_topic_naming_agent[0m
────────────────────────────────────────────────
[0;32m✓ test_topic_naming_agent PASSED[0m (0 tests)

[0;34mRunning: test_topic_naming_fallback[0m
────────────────────────────────────────────────
[0;32m✓ test_topic_naming_fallback PASSED[0m (0 tests)

[0;34mRunning: test_topic_naming_integration[0m
────────────────────────────────────────────────
[0;32m✓ test_topic_naming_integration PASSED[0m (0 tests)

[0;34mRunning: test_topic_naming[0m
────────────────────────────────────────────────
[0;31m✗ test_topic_naming FAILED[0m
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST SUITE: Topic Naming Algorithm
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test 1: Verify path extraction from full file paths
/home/benjamin/.config/.claude/tests/test_topic_naming.sh: line 46: sanitize_topic_name: command not found
TEST_FAILED

[0;34mRunning: test_topic_slug_validation[0m
────────────────────────────────────────────────
[0;31m✗ test_topic_slug_validation FAILED[0m
=========================================
Topic Directory Slug Validation Tests
=========================================

Section 1: extract_significant_words() Tests
----------------------------------------------
[0;34mINFO[0m: Test 1.1: Basic significant word extraction
/home/benjamin/.config/.claude/tests/test_topic_slug_validation.sh: line 63: extract_significant_words: command not found
TEST_FAILED

[0;34mRunning: test_verification_checkpoints[0m
────────────────────────────────────────────────
[0;32m✓ test_verification_checkpoints PASSED[0m (0 tests)

[0;34mRunning: test_workflow_classifier_agent[0m
────────────────────────────────────────────────
[0;32m✓ test_workflow_classifier_agent PASSED[0m (0 tests)

[0;34mRunning: test_workflow_detection[0m
────────────────────────────────────────────────
[0;32m✓ test_workflow_detection PASSED[0m (12 tests)

[0;34mRunning: test_workflow_initialization[0m
────────────────────────────────────────────────
[0;32m✓ test_workflow_initialization PASSED[0m (21 tests)

[0;34mRunning: test_workflow_init[0m
────────────────────────────────────────────────
[0;32m✓ test_workflow_init PASSED[0m (0 tests)

[0;34mRunning: test_workflow_scope_detection[0m
────────────────────────────────────────────────
[0;32m✓ test_workflow_scope_detection PASSED[0m (20 tests)

[0;34mRunning: validate_command_behavioral_injection[0m
────────────────────────────────────────────────
[0;32m✓ validate_command_behavioral_injection PASSED[0m (0 tests)

[0;34mRunning: validate_executable_doc_separation[0m
────────────────────────────────────────────────
[0;31m✗ validate_executable_doc_separation FAILED[0m

Validating guide files exist...
✓ PASS: .claude/commands/build.md has guide at .claude/docs/guides/commands/build-command-guide.md
⊘ SKIP: .claude/commands/collapse.md (no guide reference)
⊘ SKIP: .claude/commands/convert-docs.md (no guide reference)
✓ PASS: .claude/commands/debug.md has guide at .claude/docs/guides/commands/debug-command-guide.md
⊘ SKIP: .claude/commands/errors.md (no guide reference)
⊘ SKIP: .claude/commands/expand.md (no guide reference)
⊘ SKIP: .claude/commands/optimize-claude.md (no guide reference)
✓ PASS: .claude/commands/plan.md has guide at .claude/docs/guides/commands/plan-command-guide.md
✓ PASS: .claude/commands/repair.md has guide at .claude/docs/guides/commands/repair-command-guide.md
✓ PASS: .claude/commands/research.md has guide at .claude/docs/guides/commands/research-command-guide.md
✓ PASS: .claude/commands/revise.md has guide at .claude/docs/guides/commands/revise-command-guide.md
✓ PASS: .claude/commands/setup.md has guide at .claude/docs/guides/commands/setup-command-guide.md

Validating cross-references...
⊘ SKIP: .claude/docs/guides/*-command-guide.md (command file not found)

✗ 2 validation(s) failed
TEST_FAILED

[0;34mRunning: validate_no_agent_slash_commands[0m
────────────────────────────────────────────────
[0;32m✓ validate_no_agent_slash_commands PASSED[0m (0 tests)

[0;34mRunning: validate_topic_based_artifacts[0m
────────────────────────────────────────────────
[0;32m✓ validate_topic_based_artifacts PASSED[0m (0 tests)

════════════════════════════════════════════════
[0;32m✓ NO POLLUTION DETECTED[0m
════════════════════════════════════════════════
Post-test validation: 1 empty topic directories

════════════════════════════════════════════════
  Test Results Summary
════════════════════════════════════════════════
Test Suites Passed:  [0;32m84[0m
Test Suites Failed:  [0;31m11[0m
Total Individual Tests: 448

[0;31m✗ SOME TESTS FAILED[0m
```
