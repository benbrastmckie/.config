# Test Data Directory

This directory contains test data fixtures for feature tests. Test data includes sample files, mock inputs, and expected outputs used during test execution.

## Organization

Test data is organized by feature area:

```
data/
├── sample_readme.md       # Sample README for validation tests
├── invalid_plan.md        # Invalid plan format for error testing
└── test_output.txt        # Expected output for comparison tests
```

## Fixture Naming Convention

- Prefix `sample_` for valid test inputs
- Prefix `invalid_` for error case testing
- Prefix `expected_` for expected outputs
- Use descriptive names indicating test purpose

## Usage in Tests

Tests reference data files using relative paths:

```bash
# Example test usage
test_data_dir="$(dirname "$0")/data"
sample_readme="$test_data_dir/sample_readme.md"

# Run validation against test data
validate_readme "$sample_readme"
```

## Maintenance

- Keep test data minimal and focused
- Update data when tests change
- Document complex test data with inline comments
- Remove obsolete test data when tests are removed

## Navigation

[← Parent](../)
