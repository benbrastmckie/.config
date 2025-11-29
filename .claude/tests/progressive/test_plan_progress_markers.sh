#!/usr/bin/env bash
# test_plan_progress_markers.sh
#
# Test suite for plan progress marker functions in checkbox-utils.sh

# Don't use set -e in tests - we need to handle expected failures
# set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source without set -e to avoid exit on errors
(set +e; source "$CLAUDE_LIB/plan/checkbox-utils.sh") 2>/dev/null
source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || true

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_pass() {
  echo "  PASS: $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

test_fail() {
  echo "  FAIL: $1"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

# Create test plan files
create_test_plan() {
  local path="$1"
  cat > "$path" <<'EOF'
# Test Plan

## Implementation Phases

### Phase 1: Setup [NOT STARTED]

Tasks:
- [ ] Task 1
- [ ] Task 2

### Phase 2: Implementation [NOT STARTED]

Tasks:
- [ ] Task 3
- [ ] Task 4

### Phase 3: Testing [NOT STARTED]

Tasks:
- [ ] Task 5
EOF
}

create_legacy_plan() {
  local path="$1"
  cat > "$path" <<'EOF'
# Legacy Plan

## Implementation Phases

### Phase 1: Setup

Tasks:
- [ ] Task 1

### Phase 2: Implementation

Tasks:
- [ ] Task 2
EOF
}

# Test remove_status_marker
test_remove_status_marker() {
  echo "Testing remove_status_marker..."

  local test_file=$(mktemp)

  # Test removing NOT STARTED
  echo "### Phase 1: Setup [NOT STARTED]" > "$test_file"
  remove_status_marker "$test_file" "1"
  if ! grep -q "\[NOT STARTED\]" "$test_file" && grep -q "### Phase 1: Setup" "$test_file"; then
    test_pass "remove_status_marker removes NOT STARTED"
  else
    test_fail "remove_status_marker removes NOT STARTED"
  fi

  # Test removing IN PROGRESS
  echo "### Phase 1: Setup [IN PROGRESS]" > "$test_file"
  remove_status_marker "$test_file" "1"
  if ! grep -q "\[IN PROGRESS\]" "$test_file"; then
    test_pass "remove_status_marker removes IN PROGRESS"
  else
    test_fail "remove_status_marker removes IN PROGRESS"
  fi

  # Test removing COMPLETE
  echo "### Phase 1: Setup [COMPLETE]" > "$test_file"
  remove_status_marker "$test_file" "1"
  if ! grep -q "\[COMPLETE\]" "$test_file"; then
    test_pass "remove_status_marker removes COMPLETE"
  else
    test_fail "remove_status_marker removes COMPLETE"
  fi

  # Test removing BLOCKED
  echo "### Phase 2: Implementation [BLOCKED]" > "$test_file"
  remove_status_marker "$test_file" "2"
  if ! grep -q "\[BLOCKED\]" "$test_file"; then
    test_pass "remove_status_marker removes BLOCKED"
  else
    test_fail "remove_status_marker removes BLOCKED"
  fi

  rm -f "$test_file"
}

# Test add_in_progress_marker
test_add_in_progress_marker() {
  echo "Testing add_in_progress_marker..."

  local test_file=$(mktemp)

  # Test adding to NOT STARTED phase
  echo "### Phase 1: Setup [NOT STARTED]" > "$test_file"
  add_in_progress_marker "$test_file" "1"
  if grep -q "\[IN PROGRESS\]" "$test_file" && ! grep -q "\[NOT STARTED\]" "$test_file"; then
    test_pass "add_in_progress_marker replaces NOT STARTED"
  else
    test_fail "add_in_progress_marker replaces NOT STARTED"
  fi

  # Test adding to unmarked phase
  echo "### Phase 1: Setup" > "$test_file"
  add_in_progress_marker "$test_file" "1"
  if grep -q "\[IN PROGRESS\]" "$test_file"; then
    test_pass "add_in_progress_marker adds to unmarked phase"
  else
    test_fail "add_in_progress_marker adds to unmarked phase"
  fi

  # Test specific phase number
  create_test_plan "$test_file"
  add_in_progress_marker "$test_file" "2"
  if grep -q "Phase 2.*\[IN PROGRESS\]" "$test_file" && grep -q "Phase 1.*\[NOT STARTED\]" "$test_file"; then
    test_pass "add_in_progress_marker targets correct phase"
  else
    test_fail "add_in_progress_marker targets correct phase"
  fi

  rm -f "$test_file"
}

# Test add_complete_marker
test_add_complete_marker() {
  echo "Testing add_complete_marker..."

  local test_file=$(mktemp)

  # Test replacing IN PROGRESS
  echo "### Phase 1: Setup [IN PROGRESS]" > "$test_file"
  add_complete_marker "$test_file" "1"
  if grep -q "\[COMPLETE\]" "$test_file" && ! grep -q "\[IN PROGRESS\]" "$test_file"; then
    test_pass "add_complete_marker replaces IN PROGRESS"
  else
    test_fail "add_complete_marker replaces IN PROGRESS"
  fi

  # Test replacing NOT STARTED
  echo "### Phase 1: Setup [NOT STARTED]" > "$test_file"
  add_complete_marker "$test_file" "1"
  if grep -q "\[COMPLETE\]" "$test_file" && ! grep -q "\[NOT STARTED\]" "$test_file"; then
    test_pass "add_complete_marker replaces NOT STARTED"
  else
    test_fail "add_complete_marker replaces NOT STARTED"
  fi

  # Test adding to unmarked phase
  echo "### Phase 1: Setup" > "$test_file"
  add_complete_marker "$test_file" "1"
  if grep -q "\[COMPLETE\]" "$test_file"; then
    test_pass "add_complete_marker adds to unmarked phase"
  else
    test_fail "add_complete_marker adds to unmarked phase"
  fi

  rm -f "$test_file"
}

# Test add_not_started_markers
test_add_not_started_markers() {
  echo "Testing add_not_started_markers..."

  local test_file=$(mktemp)

  # Test adding to legacy plan
  create_legacy_plan "$test_file"
  add_not_started_markers "$test_file"
  local count=$(grep -c "\[NOT STARTED\]" "$test_file")
  if [ "$count" -eq 2 ]; then
    test_pass "add_not_started_markers adds to all phases"
  else
    test_fail "add_not_started_markers adds to all phases (got $count, expected 2)"
  fi

  # Test preserving existing markers
  cat > "$test_file" <<'EOF'
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation
### Phase 3: Testing [IN PROGRESS]
EOF
  add_not_started_markers "$test_file"
  if grep -q "Phase 1.*\[COMPLETE\]" "$test_file" && \
     grep -q "Phase 2.*\[NOT STARTED\]" "$test_file" && \
     grep -q "Phase 3.*\[IN PROGRESS\]" "$test_file"; then
    test_pass "add_not_started_markers preserves existing markers"
  else
    test_fail "add_not_started_markers preserves existing markers"
  fi

  rm -f "$test_file"
}

# Test full lifecycle
test_marker_lifecycle() {
  echo "Testing marker lifecycle..."

  local test_file=$(mktemp)
  create_test_plan "$test_file"

  # Phase 1: NOT STARTED -> IN PROGRESS
  add_in_progress_marker "$test_file" "1"
  if grep -q "Phase 1.*\[IN PROGRESS\]" "$test_file"; then
    test_pass "Lifecycle: Phase 1 NOT STARTED -> IN PROGRESS"
  else
    test_fail "Lifecycle: Phase 1 NOT STARTED -> IN PROGRESS"
  fi

  # Phase 1: IN PROGRESS -> COMPLETE
  # First mark all tasks in Phase 1 as complete
  sed -i '/^### Phase 1:/,/^### Phase 2:/ s/- \[ \]/- [x]/' "$test_file"
  add_complete_marker "$test_file" "1"
  if grep -q "Phase 1.*\[COMPLETE\]" "$test_file"; then
    test_pass "Lifecycle: Phase 1 IN PROGRESS -> COMPLETE"
  else
    test_fail "Lifecycle: Phase 1 IN PROGRESS -> COMPLETE"
  fi

  # Phase 2: NOT STARTED -> IN PROGRESS
  add_in_progress_marker "$test_file" "2"
  if grep -q "Phase 2.*\[IN PROGRESS\]" "$test_file"; then
    test_pass "Lifecycle: Phase 2 NOT STARTED -> IN PROGRESS"
  else
    test_fail "Lifecycle: Phase 2 NOT STARTED -> IN PROGRESS"
  fi

  # Verify Phase 3 still NOT STARTED
  if grep -q "Phase 3.*\[NOT STARTED\]" "$test_file"; then
    test_pass "Lifecycle: Phase 3 remains NOT STARTED"
  else
    test_fail "Lifecycle: Phase 3 remains NOT STARTED"
  fi

  rm -f "$test_file"
}

# Test edge cases
test_edge_cases() {
  echo "Testing edge cases..."

  local test_file=$(mktemp)

  # Test with phase not found (should still succeed, just no change)
  echo "### Phase 1: Setup" > "$test_file"
  add_in_progress_marker "$test_file" "99" 2>/dev/null || true
  test_pass "Edge case: missing phase doesn't crash"

  # Test with empty file
  echo "" > "$test_file"
  add_in_progress_marker "$test_file" "1" 2>/dev/null || true
  test_pass "Edge case: empty file doesn't crash"

  rm -f "$test_file"
}

# Run all tests
echo "=== Plan Progress Markers Test Suite ==="
echo ""

test_remove_status_marker
echo ""

test_add_in_progress_marker
echo ""

test_add_complete_marker
echo ""

test_add_not_started_markers
echo ""

test_marker_lifecycle
echo ""

test_edge_cases
echo ""

# Summary
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo "All tests passed!"
  exit 0
else
  echo ""
  echo "Some tests failed!"
  exit 1
fi
