# Feature Tests

Tests organized by feature area.

## Purpose

This directory organizes tests by the features they verify, providing
a logical grouping for feature-specific test coverage.

## Subdirectories

| Directory | Description |
|-----------|-------------|
| `commands/` | Tests for specific commands (/plan, /build, etc.) |
| `compliance/` | Code standards and compliance tests |
| `convert-docs/` | Document conversion feature tests |
| `location/` | Location detection feature tests |
| `specialized/` | Specialized feature tests |

## Running Tests

```bash
# Run all feature tests
./run_all_tests.sh --category features

# Run tests in a specific subdirectory
./run_all_tests.sh --category features/commands
```

## Adding Feature Tests

1. Create test file in appropriate subdirectory
2. Follow naming convention: `test_<feature>_<aspect>.sh`
3. Update subdirectory README with test description

## Navigation

- [← Parent Directory](../README.md)
- [Subdirectory: commands/](commands/README.md)
- [Subdirectory: compliance/](compliance/README.md)
- [Subdirectory: convert-docs/](convert-docs/README.md)
- [Subdirectory: location/](location/README.md)
- [Subdirectory: specialized/](specialized/README.md)
