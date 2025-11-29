# Test Utilities

Testing utilities, validators, and benchmarks.

## Purpose

This directory contains utility scripts for testing, including validators
that check code standards, benchmarks for performance testing, and helper
tools for test development.

## Contents

### Validators

Scripts that validate code quality and standards:

| File | Description |
|------|-------------|
| `lint_error_suppression.sh` | Check for improper error suppression |
| `validate_command_behavioral_injection.sh` | Validate command behavioral patterns |
| `validate_executable_doc_separation.sh` | Check documentation separation |

### Benchmarks

Performance testing scripts (in `benchmarks/` subdirectory):

| File | Description |
|------|-------------|
| `bench_workflow_classification.sh` | Benchmark classification performance |

## Running Utilities

```bash
# Run a validator
bash tests/utilities/lint_error_suppression.sh

# Run a benchmark
bash tests/utilities/benchmarks/bench_workflow_classification.sh
```

## Writing Validators

Validators should:
1. Exit 0 on success, non-zero on failure
2. Output clear error messages for violations
3. Support `--help` flag for usage information

## Navigation

- [← Parent Directory](../README.md)
- [Subdirectory: benchmarks/](benchmarks/README.md)
- [Subdirectory: manual/](manual/README.md)
