# Workflow Phases: Testing

**Related Documents**:
- [Overview](workflow-phases-overview.md) - Phase coordination
- [Implementation](workflow-phases-implementation.md) - Code execution
- [Documentation](workflow-phases-documentation.md) - Documentation updates

---

## Testing Phase

The testing phase validates all changes through comprehensive test execution, ensuring code quality and functionality before documentation.

## When to Use

- Always after implementation phase
- For any workflow with code changes
- Skip only for documentation-only changes

## Quick Overview

1. Load implementation results from checkpoint
2. Discover and run unit tests
3. Run integration tests
4. Validate code quality checks
5. Report results
6. Save checkpoint with test status

## Execution Procedure

### Step 1: Load Checkpoint

```bash
CHECKPOINT=$(load_checkpoint "orchestrate")
COMPLETED_PHASES=$(echo "$CHECKPOINT" | jq -r '.implementation.completed_phases[]')
```

### Step 2: Discover Tests

```bash
# Find test files based on changed files
discover_tests() {
  local changed_files="$1"

  # Find related test files
  for file in $changed_files; do
    # Look for corresponding test
    test_file="${file%.lua}_spec.lua"
    if [ -f "$test_file" ]; then
      echo "$test_file"
    fi
  done
}

TEST_FILES=$(discover_tests "$(git diff --name-only HEAD~1)")
```

### Step 3: Run Unit Tests

```bash
run_unit_tests() {
  local test_files="$1"

  for test in $test_files; do
    echo "Running: $test"

    if ! busted "$test"; then
      echo "FAIL: $test"
      return 1
    fi

    echo "PASS: $test"
  done

  return 0
}
```

### Step 4: Run Integration Tests

```bash
run_integration_tests() {
  echo "Running integration tests..."

  if ! bash .claude/tests/integration/run_all.sh; then
    echo "FAIL: Integration tests"
    return 1
  fi

  echo "PASS: Integration tests"
  return 0
}
```

### Step 5: Code Quality Checks

```bash
run_quality_checks() {
  # Lint check
  if ! luacheck .; then
    echo "WARN: Lint issues found"
  fi

  # Type check (if configured)
  if [ -f ".luarc.json" ]; then
    lua-language-server --check .
  fi

  # Style check
  if command -v stylua &>/dev/null; then
    stylua --check .
  fi
}
```

### Step 6: Report Results

```bash
report_results() {
  local unit_result="$1"
  local integration_result="$2"

  echo ""
  echo "=== Test Summary ==="
  echo "Unit Tests: $([ $unit_result -eq 0 ] && echo PASS || echo FAIL)"
  echo "Integration Tests: $([ $integration_result -eq 0 ] && echo PASS || echo FAIL)"
  echo ""

  if [ $unit_result -ne 0 ] || [ $integration_result -ne 0 ]; then
    return 1
  fi
  return 0
}
```

### Step 7: Save Checkpoint

```bash
CHECKPOINT=$(echo "$CHECKPOINT" | jq \
  --arg status "$TEST_STATUS" \
  --argjson passed "$TESTS_PASSED" \
  --argjson failed "$TESTS_FAILED" '
  .current_phase = "documentation" |
  .testing = {
    status: $status,
    passed: $passed,
    failed: $failed
  }
')

save_checkpoint "orchestrate" "$CHECKPOINT"
```

## Test Discovery

### By Convention

```
src/
  module.lua       -> tests/module_spec.lua
  utils/helper.lua -> tests/utils/helper_spec.lua
```

### By Pattern

```bash
# Find all test files
find . -name "*_spec.lua" -o -name "*_test.lua"

# Find tests for changed files
git diff --name-only | xargs -I{} find tests -name "$(basename {} .lua)_spec.lua"
```

## Test Isolation

### Per-Test Cleanup

```lua
describe("feature", function()
  local original_state

  before_each(function()
    original_state = save_state()
  end)

  after_each(function()
    restore_state(original_state)
  end)
end)
```

### Environment Isolation

```bash
# Run tests in isolated environment
env -i PATH="$PATH" HOME="$HOME" busted "$TEST_FILE"
```

## Failure Handling

### Test Failure

```bash
if ! run_unit_tests; then
  echo "CRITICAL: Unit tests failed"
  echo "Fix tests before proceeding"

  # Don't proceed to documentation
  exit 1
fi
```

### Partial Failure

```bash
# Some tests may be optional
if ! run_optional_tests; then
  echo "WARN: Optional tests failed"
  # Continue but log warning
fi
```

## Example Timing

```
Test Discovery: 2s
Unit Tests: 15s
Integration Tests: 30s
Quality Checks: 5s
Reporting: 1s

Total: ~53s
```

## Key Requirements

1. **Run all relevant tests** - Don't skip
2. **Report clearly** - Pass/fail summary
3. **Block on failure** - Don't proceed if tests fail
4. **Save checkpoint** - Record test status

---

## Related Documentation

- [Overview](workflow-phases-overview.md)
- [Documentation Phase](workflow-phases-documentation.md)
- [Testing Protocols](testing-protocols.md)
