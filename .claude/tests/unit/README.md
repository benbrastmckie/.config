# Unit Tests

Unit tests for individual library functions and utilities.

## Purpose

This directory contains isolated unit tests that verify individual functions
work correctly in isolation, without external dependencies or side effects.

## Test Files

| File | Tests | Description |
|------|-------|-------------|
| `test_array_serialization.sh` | Array serialization | Test array to string conversion |
| `test_artifact_registry.sh` | Artifact registry | Test artifact registration and query |
| `test_base_utils.sh` | Base utilities | Test error, warn, info, debug functions |
| `test_benign_error_filter.sh` | Error filtering | Test benign error detection |
| `test_complexity_utils.sh` | Complexity calculation | Test plan/phase complexity scoring |
| `test_cross_block_function_availability.sh` | Function export | Test function availability across blocks |
| `test_error_logging.sh` | Error logging | Test centralized error logging |
| `test_git_commit_utils.sh` | Git utilities | Test commit-related functions |
| `test_llm_classifier.sh` | LLM classifier | Test workflow classification |
| `test_parsing_utilities.sh` | Parsing utilities | Test string/data parsing |
| `test_plan_command_fixes.sh` | Plan command | Test plan generation fixes |
| `test_source_libraries_inline_error_logging.sh` | Library sourcing | Test inline sourcing with error logging |
| `test_state_persistence_across_blocks.sh` | State persistence | Test state save/restore across blocks |
| `test_summary_formatting.sh` | Summary formatting | Test console output formatting |
| `test_test_executor_behavioral_compliance.sh` | Test executor | Test executor compliance |

## Running Tests

```bash
# Run all unit tests
./run_all_tests.sh --category unit

# Run a specific test
bash tests/unit/test_base_utils.sh
```

## Writing Tests

All unit tests should:
1. Source `tests/lib/test-helpers.sh` for standardized output
2. Use `pass`, `fail`, `skip` functions for results
3. Use `assert_*` functions for assertions
4. Call `setup_test` at start and `teardown_test` at end

See [test-helpers.sh](../lib/README.md) for the complete testing API.
