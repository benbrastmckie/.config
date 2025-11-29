# Integration Tests

Integration tests for multi-component workflows and system interactions.

## Purpose

This directory contains tests that verify multiple components work together
correctly, including command execution, workflow pipelines, and cross-module
interactions.

## Test Files

| File | Description |
|------|-------------|
| `test_all_fixes_integration.sh` | Verify all bug fixes work together |
| `test_build_iteration.sh` | Test multi-iteration build workflow |
| `test_command_integration.sh` | Test command pipeline execution |
| `test_no_empty_directories.sh` | Verify lazy directory creation |
| `test_recovery_integration.sh` | Test error recovery flows |
| `test_repair_state_transitions.sh` | Test repair workflow state machine |
| `test_repair_workflow.sh` | Test full repair workflow |
| `test_revise_automode.sh` | Test revision auto-mode detection |
| `test_system_wide_location.sh` | Test system-wide path detection |
| `test_workflow_classifier_agent.sh` | Test workflow classification |
| `test_workflow_init.sh` | Test workflow initialization |
| `test_workflow_initialization.sh` | Test workflow bootstrap |
| `test_workflow_scope_detection.sh` | Test scope detection |

## Running Tests

```bash
# Run all integration tests
./run_all_tests.sh --category integration

# Run a specific test
bash tests/integration/test_build_iteration.sh
```

## Test Isolation

Integration tests follow the isolation pattern from testing-protocols.md:
- Create isolated test environments using `mktemp -d`
- Clean up test directories with `trap` handlers
- Export scoped `CLAUDE_PROJECT_DIR` variables

## Navigation

- [← Parent Directory](../README.md)
- [Related: Unit Tests](../unit/README.md)
- [Related: State Tests](../state/README.md)
