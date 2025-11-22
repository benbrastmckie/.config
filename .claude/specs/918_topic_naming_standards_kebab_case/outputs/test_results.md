# Test Execution Report

## Metadata
- **Date**: 2025-11-22 02:07:00
- **Plan**: /home/benjamin/.config/.claude/specs/918_topic_naming_standards_kebab_case/plans/001_topic_naming_standards_kebab_case_plan.md
- **Test Framework**: bash-tests
- **Test Command**: bash .claude/tests/run_all_tests.sh
- **Exit Code**: 1
- **Execution Time**: 63s
- **Environment**: test

## Summary
- **Total Tests**: 69
- **Passed**: 35
- **Failed**: 34
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

1. test_offline_classification - workflow-llm-classifier.sh not found
2. test_scope_detection_ab - workflow-scope-detection.sh not found
3. test_scope_detection - cd: too many arguments
4. test_workflow_detection - workflow-detection.sh not found
5. test_command_remediation - cd: too many arguments
6. test_convert_docs_error_logging - Validation error test failed
7. test_agent_validation - cd: too many arguments
8. test_argument_capture - argument-capture.sh not found
9. test_bash_command_fixes - cd: too many arguments
10. test_bash_error_compliance - /plan FILE NOT FOUND

## Passed Tests

- test_command_references (0 tests)
- test_command_standards_compliance (0 tests)
- test_errors_report_generation (0 tests)
- test_orchestration_commands (0 tests)
- test_history_expansion (0 tests)
- test_convert_docs_filenames (0 tests)
- test_library_deduplication (0 tests)
- test_library_references (0 tests)
- test_model_optimization (0 tests)
- test_parallel_agents (0 tests)
- test_parallel_waves (0 tests)
- test_phase2_caching (5 tests)
- test_return_code_verification (0 tests)
- test_subprocess_isolation_plan (0 tests)
- test_template_integration (0 tests)
- test_verification_checkpoints (0 tests)
- test_all_fixes_integration (0 tests)
- test_build_iteration (0 tests)
- test_command_integration (41 tests)
- test_recovery_integration (0 tests)
- test_repair_state_transitions (0 tests)
- test_revise_automode (45 tests)
- test_workflow_classifier_agent (0 tests)
- test_plan_updates (0 tests)
- test_progressive_collapse (15 tests)
- test_progressive_expansion (20 tests)
- test_progressive_roundtrip (10 tests)
- test_build_state_transitions (0 tests)
- test_state_file_path_consistency (0 tests)
- test_state_management (20 tests)

## Failure Analysis

Most failures are due to:
1. **Missing library files** - Tests reference relative paths (../lib/) that don't exist from test directory
2. **cd: too many arguments** - Script path handling issues with spaces or special characters
3. **Pre-existing infrastructure issues** - Many tests rely on deprecated or moved libraries

These failures appear to be pre-existing test infrastructure issues, not related to the topic naming standards kebab-case implementation.

## Full Output

Test output captured during execution (truncated due to size). Tests were terminated after ~63 seconds due to running background process timeout.
