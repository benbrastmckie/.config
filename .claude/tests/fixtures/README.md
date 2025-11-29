# Test Fixtures

Static test data and mock files for test suites.

## Purpose

This directory contains static fixture files used by tests to verify parsing,
validation, and processing functions. Fixtures provide known-good and
known-bad inputs for consistent testing.

## Directory Structure

```
fixtures/
|-- mock-data/       # Mock input data for various tests
|-- templates/       # Template files for testing
|-- plans/           # Sample plan files for plan tests
|-- configs/         # Configuration fixtures
`-- expected/        # Expected output files for comparison
```

## Usage in Tests

```bash
# Load a fixture file
fixture_path="${SCRIPT_DIR}/../fixtures/plans/sample_plan.md"

# Compare output against expected
expected=$(cat "${SCRIPT_DIR}/../fixtures/expected/output.txt")
actual=$(process_input "$fixture_path")
assert_equals "$expected" "$actual" "process_produces_expected_output"
```

## Adding Fixtures

1. Create fixture in appropriate subdirectory
2. Document fixture purpose in this README if it's a new category
3. Use descriptive filenames indicating test scenario

**Note**: Fixture subdirectories do not require individual READMEs per documentation standards. This root README documents the overall organization and usage patterns for all fixtures.

## Navigation

- [← Parent Directory](../README.md)
- [Related: Unit Tests](../unit/README.md)
- [Related: Integration Tests](../integration/README.md)
