# State Management Tests

Tests for workflow state persistence, transitions, and checkpointing.

## Purpose

This directory contains tests that verify the state management system works
correctly, including state transitions, persistence across bash blocks, and
checkpoint creation/restoration.

## Test Files

| File | Description |
|------|-------------|
| `test_build_state_transitions.sh` | Test build workflow state machine |
| `test_checkpoint_parallel_ops.sh` | Test parallel checkpoint operations |
| `test_checkpoint_schema_v2.sh` | Test checkpoint schema validation |
| `test_smart_checkpoint_resume.sh` | Test smart checkpoint resumption |
| `test_state_file_path_consistency.sh` | Test state file path handling |
| `test_state_machine_persistence.sh` | Test state machine persistence |
| `test_state_management.sh` | Test state management functions |
| `test_state_persistence.sh` | Test state save/restore |
| `test_supervisor_checkpoint.sh` | Test supervisor checkpointing |

## Running Tests

```bash
# Run all state tests
./run_all_tests.sh --category state

# Run a specific test
bash tests/state/test_build_state_transitions.sh
```

## State Machine Concepts

- States: initialize, research, plan, implement, test, debug, document, complete
- Valid transitions are defined in workflow-state-machine.sh
- Invalid transitions should be rejected with appropriate error messages

## Navigation

- [← Parent Directory](../README.md)
- [Related: Integration Tests](../integration/README.md)
- [Related: Progressive Tests](../progressive/README.md)
