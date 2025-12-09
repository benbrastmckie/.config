# Automated Unit Tests Template

Use this template for unit testing phases that execute focused tests on individual modules/functions.

## Template Structure

```markdown
### Phase N: Automated Unit Testing [NOT STARTED]

**Objective**: Execute comprehensive unit test suite with coverage validation and artifact generation.

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-results.xml", "coverage.lcov", "coverage-summary.json"]

**Dependencies**: Phase N-1 (implementation complete)

**Tasks**:

1. Execute unit test suite
   - [ ] Run test framework with coverage enabled: `[TEST_COMMAND] --coverage --ci`
   - [ ] Validate exit code 0 (all tests pass)
   - [ ] Generate JUnit XML report for CI integration
   - [ ] Create coverage report in LCOV format

2. Validate coverage thresholds
   - [ ] Parse coverage summary JSON for line/branch/function coverage percentages
   - [ ] Verify line coverage ≥ [THRESHOLD]% using programmatic check
   - [ ] Verify branch coverage ≥ [THRESHOLD]% using programmatic check
   - [ ] Exit with error if coverage below thresholds

3. Archive test artifacts
   - [ ] Save test results XML to artifact directory: `[ARTIFACT_PATH]/test-results.xml`
   - [ ] Save coverage report to artifact directory: `[ARTIFACT_PATH]/coverage.lcov`
   - [ ] Generate coverage HTML report for review: `[COVERAGE_TOOL] --html-report`

**Validation**:
```bash
# Execute unit tests with coverage
[TEST_COMMAND] --coverage --ci --reporters=default --reporters=junit
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || { echo "ERROR: Unit tests failed"; exit 1; }

# Validate coverage thresholds
COVERAGE=$(node -e "const c=require('[COVERAGE_SUMMARY_PATH]'); console.log(c.total.lines.pct)")
awk -v cov="$COVERAGE" -v threshold="[THRESHOLD]" 'BEGIN { exit (cov < threshold) ? 1 : 0 }' || {
  echo "ERROR: Coverage $COVERAGE% below threshold [THRESHOLD]%"
  exit 1
}

echo "✓ Unit tests passed with $COVERAGE% coverage"
```
```

## Customization Variables

Replace these placeholders when using the template:

- `[TEST_COMMAND]`: Test framework command (e.g., `npm test`, `pytest`, `cargo test`, `busted`)
- `[THRESHOLD]`: Coverage threshold percentage (e.g., `80`, `90`)
- `[ARTIFACT_PATH]`: Directory for test artifacts (e.g., `.claude/specs/XXX/outputs/`)
- `[COVERAGE_SUMMARY_PATH]`: Path to coverage summary file (e.g., `./coverage/coverage-summary.json`)
- `[COVERAGE_TOOL]`: Coverage report tool (e.g., `nyc`, `coverage.py`, `cargo-tarpaulin`)

## Framework-Specific Examples

### Node.js/Jest
```bash
npm test -- --coverage --ci --reporters=default --reporters=jest-junit
```

### Python/pytest
```bash
pytest --cov=src --cov-report=xml --cov-report=lcov --junitxml=test-results.xml
```

### Rust/cargo
```bash
cargo test --all-features -- --test-threads=1 --nocapture
cargo tarpaulin --out Xml --out Lcov --output-dir coverage
```

### Lua/busted
```bash
busted --coverage --output=junit > test-results.xml
```

## Anti-Patterns to Avoid

DO NOT use these phrases in test phases:
- "Run tests and manually verify results"
- "Skip testing if time constrained"
- "Optionally run unit tests"
- "Verify test output visually"
- "Check test results and inspect failures"

ALWAYS use programmatic validation with exit codes and thresholds.
