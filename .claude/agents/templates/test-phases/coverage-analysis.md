# Coverage Analysis Template

Use this template for coverage analysis phases that measure and validate test coverage metrics.

## Template Structure

```markdown
### Phase N: Coverage Analysis and Validation [NOT STARTED]

**Objective**: Measure test coverage, validate against thresholds, and generate comprehensive coverage reports.

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["coverage.lcov", "coverage-summary.json", "coverage-report.html", "coverage-badge.svg"]

**Dependencies**: Phase N-1 (all test suites complete)

**Tasks**:

1. Generate coverage data
   - [ ] Run all test suites with coverage instrumentation: `[COVERAGE_COMMAND]`
   - [ ] Collect coverage data from unit tests, integration tests, and end-to-end tests
   - [ ] Merge coverage reports from multiple test runs if applicable
   - [ ] Generate LCOV format coverage report for CI integration

2. Validate coverage thresholds
   - [ ] Parse coverage summary for line, branch, function, and statement coverage
   - [ ] Validate line coverage ≥ [LINE_THRESHOLD]% using programmatic check
   - [ ] Validate branch coverage ≥ [BRANCH_THRESHOLD]% using programmatic check
   - [ ] Validate function coverage ≥ [FUNCTION_THRESHOLD]% using programmatic check
   - [ ] Exit with error if any threshold violated

3. Generate coverage reports
   - [ ] Create HTML coverage report with per-file breakdown: `[HTML_REPORT_COMMAND]`
   - [ ] Generate coverage badge SVG for README integration
   - [ ] Export coverage summary JSON for tracking over time
   - [ ] Identify uncovered code segments for targeted testing

4. Archive coverage artifacts
   - [ ] Save LCOV report to artifact directory
   - [ ] Save coverage summary JSON to artifact directory
   - [ ] Save HTML report to artifact directory for review
   - [ ] Update coverage badge in project documentation if changed

**Validation**:
```bash
# Run coverage collection
[COVERAGE_COMMAND] || { echo "ERROR: Coverage collection failed"; exit 1; }

# Parse coverage summary
COVERAGE_SUMMARY="[COVERAGE_SUMMARY_PATH]"
test -f "$COVERAGE_SUMMARY" || { echo "ERROR: Coverage summary not found"; exit 1; }

# Extract coverage metrics (adjust parsing for your coverage tool)
LINE_COV=$(node -e "const c=require('$COVERAGE_SUMMARY'); console.log(c.total.lines.pct)")
BRANCH_COV=$(node -e "const c=require('$COVERAGE_SUMMARY'); console.log(c.total.branches.pct)")
FUNC_COV=$(node -e "const c=require('$COVERAGE_SUMMARY'); console.log(c.total.functions.pct)")

# Validate thresholds
validate_threshold() {
  local metric=$1
  local value=$2
  local threshold=$3
  awk -v val="$value" -v thr="$threshold" 'BEGIN { exit (val < thr) ? 1 : 0 }' || {
    echo "ERROR: $metric coverage $value% below threshold $threshold%"
    return 1
  }
}

validate_threshold "Line" "$LINE_COV" "[LINE_THRESHOLD]" || exit 1
validate_threshold "Branch" "$BRANCH_COV" "[BRANCH_THRESHOLD]" || exit 1
validate_threshold "Function" "$FUNC_COV" "[FUNCTION_THRESHOLD]" || exit 1

# Generate reports
[HTML_REPORT_COMMAND]

echo "✓ Coverage validation passed"
echo "  Line: $LINE_COV%"
echo "  Branch: $BRANCH_COV%"
echo "  Function: $FUNC_COV%"
```
```

## Customization Variables

Replace these placeholders when using the template:

- `[COVERAGE_COMMAND]`: Command to run tests with coverage (e.g., `npm test -- --coverage`, `pytest --cov=src`)
- `[COVERAGE_SUMMARY_PATH]`: Path to coverage summary file (e.g., `./coverage/coverage-summary.json`, `./coverage.json`)
- `[HTML_REPORT_COMMAND]`: Command to generate HTML report (e.g., `nyc report --reporter=html`, `coverage html`)
- `[LINE_THRESHOLD]`: Line coverage threshold percentage (e.g., `80`, `90`)
- `[BRANCH_THRESHOLD]`: Branch coverage threshold percentage (e.g., `75`, `85`)
- `[FUNCTION_THRESHOLD]`: Function coverage threshold percentage (e.g., `80`, `90`)

## Framework-Specific Examples

### Node.js/Jest with nyc
```bash
# Generate coverage
npm test -- --coverage --ci

# Parse thresholds
LINE_COV=$(node -e "const c=require('./coverage/coverage-summary.json'); console.log(c.total.lines.pct)")
BRANCH_COV=$(node -e "const c=require('./coverage/coverage-summary.json'); console.log(c.total.branches.pct)")

# Generate HTML report
nyc report --reporter=html --report-dir=coverage/html
```

### Python/pytest with coverage.py
```bash
# Generate coverage
pytest --cov=src --cov-report=json --cov-report=html --cov-report=lcov

# Parse thresholds
LINE_COV=$(python -c "import json; c=json.load(open('coverage.json')); print(c['totals']['percent_covered'])")

# Validate
coverage report --fail-under=80
```

### Rust/cargo-tarpaulin
```bash
# Generate coverage
cargo tarpaulin --out Xml --out Lcov --out Html --output-dir coverage

# Parse thresholds (from tarpaulin output)
LINE_COV=$(grep -oP 'Coverage: \K[0-9.]+' coverage/tarpaulin-report.html | head -1)

# Validate minimum coverage
cargo tarpaulin --fail-under 80
```

### Lua/luacov
```bash
# Generate coverage
busted --coverage
luacov

# Parse thresholds
LINE_COV=$(grep 'Summary' luacov.report.out | awk '{print $NF}' | tr -d '%')

# Validate (manual threshold check)
awk -v cov="$LINE_COV" 'BEGIN { exit (cov < 80) ? 1 : 0 }'
```

## Coverage Trend Tracking

Optional: Track coverage over time for regression detection

```bash
# Store coverage summary with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp coverage-summary.json "coverage-history/coverage-$TIMESTAMP.json"

# Compare with previous run
PREV_COV=$(ls -t coverage-history/coverage-*.json | sed -n '2p')
if [ -f "$PREV_COV" ]; then
  PREV_LINE=$(node -e "const c=require('$PREV_COV'); console.log(c.total.lines.pct)")
  CURR_LINE=$(node -e "const c=require('coverage-summary.json'); console.log(c.total.lines.pct)")

  DIFF=$(awk -v curr="$CURR_LINE" -v prev="$PREV_LINE" 'BEGIN { print curr - prev }')
  echo "Coverage change: $DIFF% (was $PREV_LINE%, now $CURR_LINE%)"

  # Optionally fail if coverage decreased
  awk -v diff="$DIFF" 'BEGIN { exit (diff < 0) ? 1 : 0 }' || {
    echo "WARNING: Coverage decreased"
  }
fi
```

## Anti-Patterns to Avoid

DO NOT use these phrases in coverage phases:
- "Run coverage and manually review report"
- "Skip coverage analysis if time constrained"
- "Optionally validate coverage thresholds"
- "Visually inspect coverage report for gaps"
- "Check coverage percentage and address if needed"

ALWAYS use programmatic threshold validation with exit codes.
