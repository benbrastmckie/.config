# Convert-Docs Tests

## Purpose

Tests for the document conversion feature. This directory contains tests that verify the /convert-docs command functionality, including concurrent conversion handling, edge cases, filename processing, parallel execution, and input validation.

## Test Files

| File | Description |
|------|-------------|
| `test_convert_docs_concurrency.sh` | Test concurrent conversion |
| `test_convert_docs_edge_cases.sh` | Test edge cases |
| `test_convert_docs_filenames.sh` | Test filename handling |
| `test_convert_docs_parallel.sh` | Test parallel processing |
| `test_convert_docs_validation.sh` | Test input validation |

## Running Tests

```bash
bash tests/features/convert-docs/test_convert_docs_validation.sh
```

## Navigation

- [← Parent Directory](../README.md)
- [Related: Command Tests](../commands/README.md)
- [Related: Compliance Tests](../compliance/README.md)
