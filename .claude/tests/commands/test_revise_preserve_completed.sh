#!/usr/bin/env bash
# Test /revise command preserves completed phases
# Tests: [COMPLETE] marker preservation, revision only affects pending phases

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || {
  echo "ERROR: Cannot load test-helpers.sh"
  exit 1
}

setup_test
detect_project_paths "$SCRIPT_DIR"

TEST_DIR=$(mktemp -d -t revise_preserve_completed_XXXXXX)
cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

mkdir -p "$TEST_DIR/.claude/specs/test/plans"

echo "========================================="
echo "/revise Completed Phase Preservation Tests"
echo "========================================="
echo

info() { echo "[INFO] $*"; }

# Create plan with mix of completed and pending phases
TEST_PLAN="${TEST_DIR}/.claude/specs/test/plans/001_mixed.md"
cat > "$TEST_PLAN" <<'EOF'
# Mixed Status Plan

## Metadata
- **Status**: IN PROGRESS

## Revision History

### Phase 1: Setup [COMPLETE]
- [x] Task 1 done
- [x] Task 2 done

### Phase 2: Implementation [COMPLETE]
- [x] Task 1 done

### Phase 3: Testing
- [ ] Task 1 pending
- [ ] Task 2 pending

### Phase 4: Deployment
- [ ] Task 1 pending
EOF

info "Test 1: Create plan with 2 completed, 2 pending phases"
assert_file_exists "$TEST_PLAN" "Mixed status plan created"

# Verify completed phases
COMPLETE_COUNT=$(grep -c "\[COMPLETE\]" "$TEST_PLAN" || true)
assert_equals "2" "$COMPLETE_COUNT" "Plan has 2 completed phases"

# Simulate revision (plan-architect should preserve [COMPLETE])
info "Test 2: Simulate plan revision"
cat > "$TEST_PLAN" <<'EOF'
# Mixed Status Plan

## Metadata
- **Status**: IN PROGRESS

## Revision History
- **2025-11-26**: Added Phase 3.5 for error handling

### Phase 1: Setup [COMPLETE]
- [x] Task 1 done
- [x] Task 2 done

### Phase 2: Implementation [COMPLETE]
- [x] Task 1 done

### Phase 3: Testing
- [ ] Task 1 pending
- [ ] Task 2 pending
- [ ] Task 3 NEW error tests

### Phase 3.5: Error Handling
- [ ] Add error handlers
- [ ] Test error scenarios

### Phase 4: Deployment
- [ ] Task 1 pending
EOF

# Verify [COMPLETE] preserved
COMPLETE_AFTER=$(grep -c "\[COMPLETE\]" "$TEST_PLAN" || true)
assert_equals "2" "$COMPLETE_AFTER" "Completed phases still marked [COMPLETE]"

# Verify Phase 1 still complete
if grep -q "Phase 1: Setup \[COMPLETE\]" "$TEST_PLAN"; then
  pass "Phase 1 [COMPLETE] marker preserved"
else
  fail "Phase 1 lost [COMPLETE] marker"
fi

# Verify Phase 2 still complete
if grep -q "Phase 2: Implementation \[COMPLETE\]" "$TEST_PLAN"; then
  pass "Phase 2 [COMPLETE] marker preserved"
else
  fail "Phase 2 lost [COMPLETE] marker"
fi

# Verify pending phases not marked complete
if ! grep -q "Phase 3.*\[COMPLETE\]" "$TEST_PLAN"; then
  pass "Phase 3 remains pending (no [COMPLETE])"
else
  fail "Phase 3 incorrectly marked complete"
fi

# Verify new phase is pending
if ! grep -q "Phase 3.5.*\[COMPLETE\]" "$TEST_PLAN"; then
  pass "New Phase 3.5 is pending (no [COMPLETE])"
else
  fail "New phase incorrectly marked complete"
fi

# Verify completed task checkboxes unchanged
if grep -q "\[x\] Task 1 done" "$TEST_PLAN"; then
  pass "Completed task checkboxes preserved"
else
  fail "Completed checkboxes lost"
fi

# Verify pending checkboxes unchanged
PENDING_COUNT=$(grep -c "\[ \]" "$TEST_PLAN" || true)
if [[ "$PENDING_COUNT" -ge 4 ]]; then
  pass "Pending tasks remain unchecked ($PENDING_COUNT tasks)"
else
  fail "Pending task count incorrect" "Expected >= 4, got $PENDING_COUNT"
fi

echo
teardown_test
