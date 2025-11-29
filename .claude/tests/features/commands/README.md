# Command Tests

## Purpose

Tests for specific slash commands. This directory contains tests that verify individual slash command functionality, including error handling, standards compliance, orchestration patterns, and error logging integration.

## Test Files

| File | Description |
|------|-------------|
| `test_command_references.sh` | Test command reference handling |
| `test_command_remediation.sh` | Test command error remediation |
| `test_command_standards_compliance.sh` | Test command standards |
| `test_convert_docs_error_logging.sh` | Test convert-docs error logging |
| `test_errors_report_generation.sh` | Test /errors report generation |
| `test_orchestration_commands.sh` | Test command orchestration |

## Running Tests

```bash
bash tests/features/commands/test_errors_report_generation.sh
```

## Navigation

- [← Parent Directory](../README.md)
- [Related: Compliance Tests](../compliance/README.md)
- [Related: Specialized Tests](../specialized/README.md)
