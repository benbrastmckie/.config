# Test Execution Report

## Metadata
- **Date**: 2025-11-23 17:34:57
- **Plan**: /home/benjamin/.config/.claude/specs/919_test_refactor_organization/plans/001-test-refactor-organization-plan.md
- **Test Framework**: bash-tests
- **Test Command**: bash /home/benjamin/.config/.claude/tests/run_all_tests.sh
- **Exit Code**: 1
- **Execution Time**: 49s
- **Environment**: test

## Summary
- **Total Tests**: 87 suites (192+ individual tests)
- **Passed**: 34 suites (192 individual tests)
- **Failed**: 53 suites
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

1. tests/classification/test_offline_classification.sh - workflow-llm-classifier.sh not found
2. tests/classification/test_scope_detection_ab.sh - path bug (.claude/.claude/lib)
3. tests/classification/test_scope_detection.sh - path bug (tests/lib/workflow)
4. tests/classification/test_workflow_detection.sh - path bug (../lib/workflow)
5. tests/features/commands/test_command_remediation.sh - cd: too many arguments
6. tests/features/convert-docs/test_convert_docs_error_logging.sh - validation error
7. tests/features/compliance/test_agent_validation.sh - cd: too many arguments
8. tests/features/compliance/test_argument_capture.sh - library not found
9. tests/features/compliance/test_bash_command_fixes.sh - cd: too many arguments
10. tests/features/compliance/test_bash_error_compliance.sh - /plan FILE NOT FOUND

Note: Many failures are due to incorrect library path resolution (using .claude/.claude/lib or ../lib instead of correct paths). This is a known issue being addressed in the test refactor plan.

## Error Categories

### Path Resolution Bugs (High)
- 25+ tests with `.claude/.claude/lib` double-path bug
- 15+ tests with `../lib` relative path resolution failure
- Root cause: Tests not using consistent PROJECT_ROOT detection

### Missing Libraries (Medium)
- workflow-llm-classifier.sh not found
- convert-core.sh not found
- checkpoint-utils.sh not found
- workflow-state-machine.sh not found

### cd Command Errors (Low)
- Multiple tests with "cd: too many arguments"
- Likely caused by unquoted paths with spaces

## Full Output

Test output was too large for inline capture. Key statistics:
- 34 suites passed
- 53 suites failed
- Most failures due to library path resolution issues
- Individual test counts: 192+ tests executed across passing suites
