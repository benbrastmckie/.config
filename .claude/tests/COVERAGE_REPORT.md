# Test Coverage Report

**Date**: 2025-11-23
**Updated**: Test Refactor Organization (spec 919)

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Test Files | 98 |
| Test Categories | 7 |
| Library Files | 49 |
| Library Coverage | ~55% |
| Python Tests | 2 |

## Test Distribution by Category

| Category | Test Files | Description |
|----------|------------|-------------|
| unit/ | 15 | Isolated function tests |
| integration/ | 13 | Multi-component tests |
| state/ | 9 | State management tests |
| progressive/ | 8 | Plan expansion/collapse tests |
| classification/ | 4 | Workflow classification tests |
| features/ | 42 | Feature-specific tests |
| topic-naming/ | 7 | Topic naming system tests |

## Library Coverage

### Well-Tested Libraries (>80% coverage)

| Library | Test File | Coverage |
|---------|-----------|----------|
| state-persistence.sh | test_state_persistence.sh | High |
| workflow-state-machine.sh | test_build_state_transitions.sh | High |
| checkbox-utils.sh | test_plan_progress_markers.sh | High |
| error-handling.sh | test_error_logging.sh | Medium |
| base-utils.sh | test_base_utils.sh | High |
| complexity-utils.sh | test_complexity_utils.sh | High |
| summary-formatting.sh | test_summary_formatting.sh | High |
| artifact-registry.sh | test_artifact_registry.sh | High |

### Partially Tested Libraries (40-80% coverage)

| Library | Test File | Notes |
|---------|-----------|-------|
| topic-utils.sh | test_topic_naming_*.sh | 7 test files |
| parsing utilities | test_parsing_utilities.sh | Basic coverage |
| git-commit-utils.sh | test_git_commit_utils.sh | Basic coverage |

### Untested Libraries (<40% coverage)

| Library | Priority | Recommended Tests |
|---------|----------|-------------------|
| template-integration.sh | Medium | Template variable substitution |
| overview-synthesis.sh | Low | Output generation |
| auto-analysis-utils.sh | Medium | Auto-analysis logic |
| unified-location-detection.sh | Medium | Path resolution |

## Test Output Standards

All tests use standardized output patterns:
- Success: `[checkmark] PASS: test_name`
- Failure: `[X] FAIL: test_name`
- Skip: `[circle] SKIP: test_name`

## Running Tests

```bash
# Run all shell tests
./run_all_tests.sh

# Run with verbose output
./run_all_tests.sh --verbose

# Include Python tests
./run_all_tests.sh --python

# Run specific category
./run_all_tests.sh --category unit
```

## Python Tests

Python tests require pytest or python3:

| File | Purpose |
|------|---------|
| test_agent_correlation.py | Agent correlation analysis |
| test_complexity_baseline.py | Complexity baseline validation |

Run with: `./run_all_tests.sh --python`

## Coverage Improvement History

| Date | Libraries Covered | Test Files | Notes |
|------|-------------------|------------|-------|
| 2025-10-06 | 22/48 (46%) | 60+ | Initial coverage |
| 2025-11-23 | 27/49 (55%) | 98 | Added unit tests for critical libs |

## Test Helper Library

All tests should use `tests/lib/test-helpers.sh` for consistent output:

```bash
source "${SCRIPT_DIR}/../lib/test-helpers.sh"
setup_test

pass "test_name"
fail "test_name" "reason"
assert_equals "expected" "actual" "test_name"

teardown_test
```

See [tests/lib/README.md](lib/README.md) for full API documentation.
