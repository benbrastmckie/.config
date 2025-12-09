# Automated Integration Tests Template

Use this template for integration testing phases that validate interactions between components/modules.

## Template Structure

```markdown
### Phase N: Automated Integration Testing [NOT STARTED]

**Objective**: Execute integration test suite validating component interactions and end-to-end workflows.

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["integration-test-results.xml", "integration-coverage.lcov", "test-logs.txt"]

**Dependencies**: Phase N-1 (unit tests complete), Phase N-2 (component integration complete)

**Tasks**:

1. Setup test environment
   - [ ] Start test dependencies (database, message queue, mock services): `[SETUP_SCRIPT]`
   - [ ] Validate all services running with health checks
   - [ ] Seed test data using reproducible fixtures: `[SEED_SCRIPT]`
   - [ ] Configure environment variables for test mode

2. Execute integration test suite
   - [ ] Run integration tests with isolation: `[INTEGRATION_TEST_COMMAND]`
   - [ ] Validate exit code 0 (all integration tests pass)
   - [ ] Generate JUnit XML report for test results
   - [ ] Capture test execution logs for debugging

3. Validate integration coverage
   - [ ] Verify all critical integration points tested (API endpoints, database queries, message handling)
   - [ ] Check integration test count meets minimum threshold (≥ [MIN_TEST_COUNT] tests)
   - [ ] Validate no skipped or pending integration tests

4. Teardown test environment
   - [ ] Stop test dependencies gracefully: `[TEARDOWN_SCRIPT]`
   - [ ] Clean up test data and temporary files
   - [ ] Archive test artifacts to output directory

**Validation**:
```bash
# Setup test environment
[SETUP_SCRIPT] || { echo "ERROR: Test environment setup failed"; exit 1; }

# Execute integration tests
[INTEGRATION_TEST_COMMAND] --format junit --output integration-test-results.xml
EXIT_CODE=$?

# Teardown regardless of test result
[TEARDOWN_SCRIPT]

# Check test results
test $EXIT_CODE -eq 0 || { echo "ERROR: Integration tests failed"; exit 1; }

# Validate test count
TEST_COUNT=$(grep -c '<testcase' integration-test-results.xml || echo 0)
[ "$TEST_COUNT" -ge [MIN_TEST_COUNT] ] || {
  echo "ERROR: Only $TEST_COUNT integration tests (need ≥[MIN_TEST_COUNT])"
  exit 1
}

echo "✓ $TEST_COUNT integration tests passed"
```
```

## Customization Variables

Replace these placeholders when using the template:

- `[SETUP_SCRIPT]`: Script to start test dependencies (e.g., `docker-compose -f test-compose.yml up -d`)
- `[TEARDOWN_SCRIPT]`: Script to stop test dependencies (e.g., `docker-compose -f test-compose.yml down`)
- `[SEED_SCRIPT]`: Script to seed test data (e.g., `npm run seed:test`, `python scripts/seed_test_db.py`)
- `[INTEGRATION_TEST_COMMAND]`: Integration test command (e.g., `npm run test:integration`, `pytest tests/integration/`)
- `[MIN_TEST_COUNT]`: Minimum number of integration tests required (e.g., `10`, `20`)

## Framework-Specific Examples

### Node.js/Supertest
```bash
# Setup
docker-compose -f test-compose.yml up -d postgres redis
npm run db:migrate:test
npm run seed:test

# Test
npm run test:integration -- --reporters=default --reporters=jest-junit --forceExit

# Teardown
docker-compose -f test-compose.yml down -v
```

### Python/pytest with testcontainers
```bash
# Tests manage their own containers via testcontainers
pytest tests/integration/ --junitxml=integration-test-results.xml -v
```

### Rust/cargo with docker
```bash
# Setup
docker-compose -f test-compose.yml up -d
sleep 5  # Wait for services

# Test
cargo test --test integration_tests -- --test-threads=1

# Teardown
docker-compose -f test-compose.yml down
```

## Anti-Patterns to Avoid

DO NOT use these phrases in integration test phases:
- "Manually start test services and run tests"
- "Skip integration tests if environment unavailable"
- "Optionally validate service interactions"
- "Visually inspect integration test output"
- "Check test logs manually for errors"

ALWAYS use automated setup/teardown with programmatic validation.
