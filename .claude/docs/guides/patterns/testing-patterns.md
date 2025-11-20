# Testing Patterns Guide

**Path**: docs → guides → testing-patterns.md

## Purpose

This guide demonstrates how to organize tests, create fixtures, write assertions, and measure coverage in the Claude Code testing framework. Following these patterns ensures consistent, reliable test execution and maintainable test suites.

## Prerequisites

- Understanding of project Testing Protocols (see CLAUDE.md)
- Bash scripting fundamentals
- Familiarity with test directory structure (`.claude/tests/`)

## Steps

### Step 1: Organize Test Files

Test files follow a consistent naming convention that groups related tests together.

**Test File Naming**:
```bash
# Pattern: test_<component>_<aspect>.sh
test_shared_utilities.sh      # Tests for utility libraries
test_complexity_basic.sh       # Basic complexity evaluation tests
test_complexity_estimator.sh   # Advanced complexity estimation tests
test_command_references.sh     # Command file reference validation
test_library_references.sh     # Library sourcing and reference tests
test_artifact_utils.sh         # Artifact operations tests
```

**Test Suite Organization**:
```bash
.claude/tests/
├── run_all_tests.sh           # Main test runner
├── test_*.sh                  # Individual test files
├── fixtures/                  # Test data and mock files
│   ├── plans/                 # Sample plan files
│   ├── spec_updater/          # Spec updater test data
│   ├── complexity_evaluation/ # Complexity test cases
│   ├── valid/                 # Valid input examples
│   ├── malformed/             # Invalid input examples
│   └── edge_cases/            # Boundary condition tests
└── tmp/                       # Temporary test artifacts (gitignored)
```

**Running Tests**:
```bash
# Run all tests
./run_all_tests.sh

# Run specific test file
./test_shared_utilities.sh

# Run with verbose output
bash -x ./test_shared_utilities.sh
```

### Step 2: Create Test Fixtures

Fixtures provide consistent, reusable test data. Organize fixtures by test category.

**Fixture Structure**:
```bash
fixtures/
├── plans/                     # Sample plan files
│   ├── simple_plan.md         # Minimal valid plan
│   ├── complex_plan.md        # Multi-phase plan with dependencies
│   └── expanded_plan/         # Hierarchical plan structure
│       ├── main.md
│       └── phase_1.md
├── spec_updater/              # Spec updater fixtures
│   ├── test_level0_plan.md
│   └── test_level1_plan/
│       ├── test_level1_plan.md
│       └── phase_1_setup.md
└── complexity_evaluation/     # Complexity test cases
    ├── low_complexity.md      # Score <5.0
    ├── medium_complexity.md   # Score 5.0-8.0
    └── high_complexity.md     # Score >8.0
```

**Creating Fixtures**:
```bash
# Example: Create a simple plan fixture
cat > fixtures/plans/simple_plan.md <<'EOF'
# Simple Test Plan

## Metadata
- **Estimated Phases**: 3
- **Structure Level**: 0

## Phases

### Phase 1: Setup
- Create test directory
- Initialize configuration

### Phase 2: Implementation
- Write core logic
- Add error handling

### Phase 3: Testing
- Write unit tests
- Verify functionality
EOF
```

**Fixture Best Practices**:
- Use realistic data (based on actual project files)
- Create both valid and invalid examples
- Include edge cases (empty files, malformed syntax, boundary values)
- Document expected behavior in fixture comments
- Keep fixtures minimal (only necessary content)

### Step 3: Write Assertions

Use consistent assertion patterns for reliable test validation.

**Test Framework Functions**:
```bash
# Defined in test files
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}
```

**Assertion Patterns**:
```bash
# Test 1: File existence
if [ -f "$CHECKPOINT_FILE" ]; then
  pass "Checkpoint file created"
else
  fail "Checkpoint file not created" "File should exist at $CHECKPOINT_FILE"
fi

# Test 2: String content
if grep -q "expected_value" "$OUTPUT_FILE"; then
  pass "Output contains expected value"
else
  fail "Output missing expected value" "Should contain 'expected_value'"
fi

# Test 3: Numeric comparison
SCORE=$(calculate_score "$INPUT")
if [ "$SCORE" -ge 8 ]; then
  pass "Score meets threshold ($SCORE >= 8)"
else
  fail "Score below threshold ($SCORE < 8)" "Expected score >= 8"
fi

# Test 4: Exit code validation
if some_command 2>/dev/null; then
  pass "Command succeeded"
else
  fail "Command failed" "Expected exit code 0"
fi

# Test 5: JSON structure validation
if echo "$JSON" | jq -e '.phase' >/dev/null 2>&1; then
  pass "JSON contains required field"
else
  fail "JSON missing field" "Should have .phase field"
fi
```

**Comprehensive Test Structure**:
```bash
#!/usr/bin/env bash
# Test suite template

set -euo pipefail

# Test counters
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Test environment setup
TEST_DIR=$(mktemp -d -t test_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Source library under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/lib/target_library.sh"

echo "════════════════════════════════════════════════"
echo "Test Suite Name"
echo "════════════════════════════════════════════════"
echo "Test environment: $TEST_DIR"
echo ""

# Test cases
info "Testing function_name()"

# Test case 1
RESULT=$(function_name "input" 2>/dev/null || echo "")
if [ "$RESULT" = "expected" ]; then
  pass "Function returns correct value"
else
  fail "Function returns incorrect value" "Expected: expected, Got: $RESULT"
fi

# Test case 2
if function_name --invalid-arg 2>/dev/null; then
  fail "Function accepted invalid argument"
else
  pass "Function rejected invalid argument"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════"
echo "Test Summary"
echo "════════════════════════════════════════════════"
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo "SKIP: $SKIP_COUNT"
echo "TOTAL: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))"

if [ $FAIL_COUNT -eq 0 ]; then
  echo "Status: ✓ ALL TESTS PASSED"
  exit 0
else
  echo "Status: ✗ SOME TESTS FAILED"
  exit 1
fi
```

### Step 4: Measure Coverage

Track which code paths are tested and identify gaps.

**Coverage Measurement**:
```bash
# Manual coverage tracking
# List all public functions in library
grep -E '^[a-z_]+\(\)' lib/target_library.sh

# Check which functions have tests
grep -E 'Testing [a-z_]+\(\)' tests/test_target_library.sh

# Calculate coverage percentage
TOTAL_FUNCTIONS=$(grep -cE '^[a-z_]+\(\)' lib/target_library.sh)
TESTED_FUNCTIONS=$(grep -cE 'Testing [a-z_]+\(\)' tests/test_target_library.sh)
COVERAGE=$((TESTED_FUNCTIONS * 100 / TOTAL_FUNCTIONS))
echo "Coverage: $COVERAGE% ($TESTED_FUNCTIONS/$TOTAL_FUNCTIONS functions)"
```

**Coverage Targets** (from CLAUDE.md):
- New code: >80% coverage
- Modified code: >80% coverage
- Overall baseline: >60% coverage
- Critical paths: 100% coverage (with integration tests)

**Coverage Best Practices**:
- Test all public functions
- Include edge cases (empty input, null values, boundary conditions)
- Test error handling paths
- Add integration tests for critical workflows
- Document untested code with rationale

## Examples

### Example 1: Testing Checkpoint Utilities

```bash
# From test_shared_utilities.sh
info "Testing save_checkpoint()"

# Setup
STATE_JSON='{"phase":2,"status":"in_progress"}'
CHECKPOINT_FILE=$(save_checkpoint "test_workflow" "test_project" "$STATE_JSON" 2>/dev/null || echo "")

# Assertions
if [ -n "$CHECKPOINT_FILE" ] && [ -f "$CHECKPOINT_FILE" ]; then
  pass "save_checkpoint() created checkpoint file"
else
  fail "save_checkpoint() failed to create checkpoint"
fi

if grep -q "test_workflow" "$CHECKPOINT_FILE"; then
  pass "Checkpoint contains workflow type"
else
  fail "Checkpoint missing workflow type"
fi

if grep -q '"phase":2' "$CHECKPOINT_FILE"; then
  pass "Checkpoint contains state JSON"
else
  fail "Checkpoint missing state JSON"
fi
```

### Example 2: Testing Complexity Evaluation

```bash
# From test_complexity_basic.sh
info "Testing complexity score calculation"

# Use fixture
TEST_PLAN="fixtures/complexity_evaluation/high_complexity.md"

# Calculate score
SCORE=$(calculate_complexity_score "$TEST_PLAN" 2>/dev/null || echo "0")

# Validate threshold
THRESHOLD=8.0
if awk -v s="$SCORE" -v t="$THRESHOLD" 'BEGIN { exit (s >= t ? 0 : 1) }'; then
  pass "High complexity plan exceeds threshold ($SCORE >= $THRESHOLD)"
else
  fail "High complexity plan below threshold ($SCORE < $THRESHOLD)"
fi
```

### Example 3: Testing with Malformed Input

```bash
# Test error handling with invalid input
info "Testing error handling for malformed plan"

# Use malformed fixture
MALFORMED_PLAN="fixtures/malformed/invalid_syntax.md"

# Should fail gracefully
if parse_plan "$MALFORMED_PLAN" 2>/dev/null; then
  fail "Parser accepted malformed input"
else
  pass "Parser rejected malformed input"
fi

# Should return empty result, not crash
RESULT=$(extract_phases "$MALFORMED_PLAN" 2>/dev/null || echo "")
if [ -z "$RESULT" ]; then
  pass "Extractor returned empty result for malformed input"
else
  fail "Extractor should return empty for malformed input"
fi
```

## Troubleshooting

### Issue: Tests pass individually but fail in test suite

**Cause**: Shared state or environment pollution between tests

**Solution**: Ensure proper cleanup between tests
```bash
# Use isolated test directories
TEST_DIR=$(mktemp -d -t test_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Reset counters for each test file
PASS_COUNT=0
FAIL_COUNT=0
```

### Issue: Fixture not found during test execution

**Cause**: Incorrect relative path or missing fixture file

**Solution**: Use absolute paths based on script location
```bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reference fixtures with absolute path
FIXTURE="$SCRIPT_DIR/fixtures/plans/simple_plan.md"

# Verify fixture exists before using
if [ ! -f "$FIXTURE" ]; then
  fail "Fixture not found: $FIXTURE"
  exit 1
fi
```

### Issue: Inconsistent test results across environments

**Cause**: Dependency on system-specific tools or configurations

**Solution**: Check for required tools and skip if unavailable
```bash
# Check for required tool
if ! command -v jq >/dev/null 2>&1; then
  skip "jq not installed, skipping JSON tests"
  # Continue with other tests
fi

# Use portable bash constructs
# AVOID: [[, local -n, ${var@Q}
# USE: [, declare, ${var}
```

### Issue: Tests take too long to run

**Cause**: Expensive operations or large fixtures

**Solution**: Use smaller fixtures and mock external dependencies
```bash
# Create minimal fixtures for unit tests
cat > "$TEST_DIR/minimal_plan.md" <<'EOF'
# Minimal Plan
## Phases
### Phase 1: Test
- Task 1
EOF

# Mock expensive operations
calculate_score() {
  # Return mock score for tests
  echo "7.5"
}
```

## Related Documentation

- [CLAUDE.md Testing Protocols](../../../CLAUDE.md#testing-protocols) - Test commands and coverage targets
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - Testing verification checkpoints
- [Migration Validation Guide](./migration-validation.md) - Validating enforcement migrations
- [Test Suite Documentation](../../../tests/README.md) - Complete test suite reference
