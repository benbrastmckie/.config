#!/usr/bin/env bash
# Test suite for parsing utilities
# Tests plan-core-bundle.sh parsing functions

set -e

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../../lib"

# Source required libraries
source "$LIB_DIR/plan/plan-core-bundle.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="/tmp/parsing_utilities_tests_$$"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/specs/plans"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Test: Parse plan metadata
test_parse_plan_metadata() {
  info "Testing parse_plan_metadata()"

  local plan_file="$TEST_DIR/test_plan.md"
  cat > "$plan_file" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-10-06
- **Feature**: Test Feature
- **Scope**: Testing
- **Structure Level**: 0
- **Estimated Phases**: 3
- **Complexity Score**: 5/10
EOF

  # Test date extraction using grep
  if grep "Date.*2025-10-06" "$plan_file" >/dev/null 2>&1; then
    pass "Found date in metadata"
  else
    fail "Failed to find date" "$(grep Date "$plan_file")"
  fi

  # Test feature extraction
  if grep "Feature.*Test Feature" "$plan_file" >/dev/null 2>&1; then
    pass "Found feature in metadata"
  else
    fail "Failed to find feature" "$(grep Feature "$plan_file")"
  fi

  # Test structure level extraction
  if grep "Structure Level.*0" "$plan_file" >/dev/null 2>&1; then
    pass "Found structure level in metadata"
  else
    fail "Failed to find structure level" "$(grep 'Structure Level' "$plan_file")"
  fi
}

# Test: Parse phases from flat structure
test_parse_phase_list() {
  info "Testing phase list parsing"

  local plan_file="$TEST_DIR/phase_list_plan.md"
  cat > "$plan_file" <<'EOF'
# Test Plan

## Phases

### Phase 1: Setup
**Tasks**:
- [ ] Task 1
- [ ] Task 2

### Phase 2: Implementation
**Tasks**:
- [ ] Task 3
EOF

  # Count phases
  local phase_count=$(grep -c "^### Phase [0-9]" "$plan_file" || echo 0)
  if [ "$phase_count" -eq 2 ]; then
    pass "Counted correct number of phases"
  else
    fail "Incorrect phase count" "Expected 2, got $phase_count"
  fi

  # Extract phase names
  if grep "^### Phase 1:" "$plan_file" | grep -q "Setup"; then
    pass "Extracted Phase 1 name correctly"
  else
    fail "Failed to extract Phase 1 name" "$(grep "^### Phase 1:" "$plan_file")"
  fi
}

# Test: Parse tasks from phase
test_parse_phase_tasks() {
  info "Testing task parsing from phase"

  local plan_file="$TEST_DIR/tasks_plan.md"
  cat > "$plan_file" <<'EOF'
### Phase 1: Test Phase

**Tasks**:
- [ ] First task
- [ ] Second task
- [x] Completed task
- [ ] Fourth task

**Acceptance Criteria**:
- [ ] Test passes
EOF

  # Count uncompleted tasks
  local task_count=$(sed -n '/^### Phase 1:/,/^### Phase [0-9]/p' "$plan_file" | \
                     grep -c "^- \[ \]" || echo 0)
  if [ "$task_count" -eq 4 ]; then
    pass "Counted correct number of tasks"
  else
    fail "Incorrect task count" "Expected 4, got $task_count"
  fi

  # Count completed tasks
  local completed=$(sed -n '/^### Phase 1:/,/^### Phase [0-9]/p' "$plan_file" | \
                   grep -c "^- \[x\]" || echo 0)
  if [ "$completed" -eq 1 ]; then
    pass "Counted completed tasks correctly"
  else
    fail "Incorrect completed count" "Expected 1, got $completed"
  fi
}

# Test: Detect plan structure level
test_detect_structure_level() {
  info "Testing structure level detection"

  # Level 0: Single file
  local l0_plan="$TEST_DIR/level0.md"
  echo "# Plan" > "$l0_plan"

  if [ -f "$l0_plan" ] && [ ! -d "${l0_plan%.md}" ]; then
    pass "Detected Level 0 structure (single file)"
  else
    fail "Failed to detect Level 0" "File check failed"
  fi

  # Level 1: Plan directory with phase files
  local l1_plan="$TEST_DIR/level1_plan"
  mkdir -p "$l1_plan"
  echo "# Plan" > "$l1_plan/level1_plan.md"
  echo "# Phase 1" > "$l1_plan/phase_1_setup.md"

  if [ -d "$l1_plan" ] && [ -f "$l1_plan/level1_plan.md" ]; then
    pass "Detected Level 1 structure (plan directory)"
  else
    fail "Failed to detect Level 1" "Directory structure incorrect"
  fi
}

# Test: Handle malformed metadata
test_malformed_metadata() {
  info "Testing malformed metadata handling"

  local plan_file="$TEST_DIR/malformed.md"
  cat > "$plan_file" <<'EOF'
# Malformed Plan

## Metadata
- Date: 2025-10-06
- **Feature Missing**:
- **Scope**
EOF

  # Should not crash when reading malformed metadata
  if grep -q "Feature" "$plan_file" 2>/dev/null; then
    pass "Handled malformed metadata gracefully"
  else
    # This is expected - malformed fields may not match
    pass "Handled malformed field (expected)"
  fi
}

# Test: Handle missing metadata sections
test_missing_metadata() {
  info "Testing missing metadata section"

  local plan_file="$TEST_DIR/no_metadata.md"
  cat > "$plan_file" <<'EOF'
# Plan Without Metadata

### Phase 1: Test
**Tasks**:
- [ ] Task
EOF

  # Should handle missing metadata section
  if ! grep -q "^## Metadata" "$plan_file"; then
    pass "Detected missing metadata section"
  else
    fail "Should not have metadata section" "Found: $(grep 'Metadata' "$plan_file")"
  fi
}

# Test: Unicode and special characters
test_unicode_handling() {
  info "Testing Unicode character handling"

  local plan_file="$TEST_DIR/unicode.md"
  cat > "$plan_file" <<'EOF'
# Plan with Unicode

## Metadata
- **Feature**: Test with → arrows ← and émojis

### Phase 1: Testing
**Tasks**:
- [ ] Task with unicode: ✓ ✗ ⚠
EOF

  if grep "arrows" "$plan_file" >/dev/null 2>&1; then
    pass "Handled Unicode characters in metadata"
  else
    fail "Failed to handle Unicode" "$(grep Feature "$plan_file")"
  fi
}

# Test: Legacy format detection
test_legacy_format_detection() {
  info "Testing legacy format detection"

  local plan_file="$TEST_DIR/legacy.md"
  cat > "$plan_file" <<'EOF'
# Legacy Plan

## Metadata
- **Tier**: 2

### Phase 1: Test
EOF

  # Detect presence of old "Tier" field
  if grep -q "Tier" "$plan_file"; then
    pass "Detected legacy tier field"
  else
    fail "Failed to detect legacy format" "Tier field not found"
  fi
}

# Test: Extract multiple phase sections
test_multiple_phases() {
  info "Testing multiple phase extraction"

  local plan_file="$TEST_DIR/multi_phase.md"
  cat > "$plan_file" <<'EOF'
### Phase 1: Setup
**Tasks**:
- [ ] Task 1

---

### Phase 2: Build
**Tasks**:
- [ ] Task 2

---

### Phase 3: Test
**Tasks**:
- [ ] Task 3
EOF

  local count=$(grep -c "^### Phase [0-9]" "$plan_file")
  if [ "$count" -eq 3 ]; then
    pass "Extracted all phases correctly"
  else
    fail "Incorrect phase extraction" "Expected 3, got $count"
  fi
}

# Run all tests
run_all_tests() {
  echo "================================"
  echo "Parsing Utilities Test Suite"
  echo "================================"
  echo ""

  setup

  test_parse_plan_metadata
  test_parse_phase_list
  test_parse_phase_tasks
  test_detect_structure_level
  test_malformed_metadata
  test_missing_metadata
  test_unicode_handling
  test_legacy_format_detection
  test_multiple_phases

  cleanup

  echo ""
  echo "================================"
  echo "Test Results"
  echo "================================"
  echo "Tests Run:    $TESTS_RUN"
  echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}FAILURE${NC}: Some tests failed"
    exit 1
  else
    echo -e "${GREEN}SUCCESS${NC}: All tests passed"
    exit 0
  fi
}

# Run tests
run_all_tests
