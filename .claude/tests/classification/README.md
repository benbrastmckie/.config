# Classification Tests

Tests for workflow and scope classification functionality.

## Purpose

This directory contains tests that verify the classification system works
correctly, including workflow type detection, scope detection, and A/B
comparison testing.

## Test Files

| File | Description |
|------|-------------|
| `test_offline_classification.sh` | Test offline classification logic |
| `test_scope_detection_ab.sh` | A/B test for scope detection |
| `test_scope_detection.sh` | Test scope detection algorithms |
| `test_workflow_detection.sh` | Test workflow type classification |

## Running Tests

```bash
# Run all classification tests
./run_all_tests.sh --category classification

# Run a specific test
bash tests/classification/test_workflow_detection.sh
```

## Classification Types

- Workflow types: research, plan, build, debug, repair
- Scope detection: project, file, directory, topic
