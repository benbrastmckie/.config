#!/usr/bin/env bash
# Test: Build command status metadata update
# Verifies that plan status updates to [COMPLETE] when all phases are marked complete

set -euo pipefail

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$HOME/.config"
fi

# Source checkbox utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source checkbox-utils.sh"
  exit 1
}

# Test setup
TEST_DIR="/tmp/test_build_status_$$"
mkdir -p "$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Create test plan with all phases complete
cat > "$TEST_DIR/test_plan.md" << 'EOF'
# Test Plan for Status Update

## Metadata
- **Status**: [IN PROGRESS]
- **Date**: 2025-11-30
- **Feature**: Test status update functionality

## Implementation Phases

### Phase 1: First Phase [COMPLETE]
Tasks:
- [x] Task 1
- [x] Task 2

### Phase 2: Second Phase [COMPLETE]
Tasks:
- [x] Task 3
- [x] Task 4

### Phase 3: Third Phase [COMPLETE]
Tasks:
- [x] Task 5
- [x] Task 6
EOF

echo "=== Test: Build Status Update ==="
echo ""

# Test 1: Verify all phases are complete
echo "Test 1: Check all phases complete..."
if check_all_phases_complete "$TEST_DIR/test_plan.md"; then
  echo "  ✓ PASS: All phases detected as complete"
else
  echo "  ✗ FAIL: Not all phases detected as complete"
  exit 1
fi

# Test 2: Update status to COMPLETE
echo "Test 2: Update status to COMPLETE..."
if update_plan_status "$TEST_DIR/test_plan.md" "COMPLETE" 2>/dev/null; then
  echo "  ✓ PASS: Status update succeeded"
else
  echo "  ✗ FAIL: Status update failed"
  exit 1
fi

# Test 3: Verify status field updated
echo "Test 3: Verify status field in metadata..."
CURRENT_STATUS=$(grep "^- \*\*Status\*\*:" "$TEST_DIR/test_plan.md" | grep -o "\[.*\]" || echo "")
if [ "$CURRENT_STATUS" = "[COMPLETE]" ]; then
  echo "  ✓ PASS: Status field is [COMPLETE]"
else
  echo "  ✗ FAIL: Status field is $CURRENT_STATUS (expected [COMPLETE])"
  exit 1
fi

# Test 4: Verify incomplete plan does NOT update
echo "Test 4: Verify incomplete plan behavior..."
cat > "$TEST_DIR/incomplete_plan.md" << 'EOF'
# Incomplete Test Plan

## Metadata
- **Status**: [IN PROGRESS]

## Implementation Phases

### Phase 1: First Phase [COMPLETE]
Tasks:
- [x] Task 1

### Phase 2: Second Phase [IN PROGRESS]
Tasks:
- [x] Task 2
- [ ] Task 3

### Phase 3: Third Phase [NOT STARTED]
Tasks:
- [ ] Task 4
EOF

if check_all_phases_complete "$TEST_DIR/incomplete_plan.md"; then
  echo "  ✗ FAIL: Incomplete phases detected as complete"
  exit 1
else
  echo "  ✓ PASS: Incomplete phases correctly detected"
fi

# Attempt update (should not happen)
BEFORE_STATUS=$(grep "^- \*\*Status\*\*:" "$TEST_DIR/incomplete_plan.md")
if check_all_phases_complete "$TEST_DIR/incomplete_plan.md"; then
  update_plan_status "$TEST_DIR/incomplete_plan.md" "COMPLETE" 2>/dev/null
fi
AFTER_STATUS=$(grep "^- \*\*Status\*\*:" "$TEST_DIR/incomplete_plan.md")

if [ "$BEFORE_STATUS" = "$AFTER_STATUS" ] && echo "$AFTER_STATUS" | grep -q "\[IN PROGRESS\]"; then
  echo "  ✓ PASS: Status unchanged for incomplete plan"
else
  echo "  ✗ FAIL: Status changed for incomplete plan"
  exit 1
fi

# Test 5: Verify only one status update code path exists in build.md
echo "Test 5: Verify no duplicate status update logic..."
STATUS_UPDATE_COUNT=$(grep -c "check_all_phases_complete.*PLAN_FILE" "${CLAUDE_PROJECT_DIR}/.claude/commands/build.md" 2>/dev/null || echo "0")
if [ "$STATUS_UPDATE_COUNT" -eq 1 ]; then
  echo "  ✓ PASS: Only one status update code path exists"
else
  echo "  ✗ FAIL: Found $STATUS_UPDATE_COUNT status update code paths (expected 1)"
  exit 1
fi

# Test 6: Verify Block 4 implementation removed
echo "Test 6: Verify Block 4 status update removed..."
if grep -q "CRITICAL: Update metadata status" "${CLAUDE_PROJECT_DIR}/.claude/commands/build.md"; then
  echo "  ✗ FAIL: Block 4 status update logic still present"
  exit 1
else
  echo "  ✓ PASS: Block 4 status update logic removed"
fi

echo ""
echo "=== All Tests Passed ==="
echo "Status update functionality working correctly"
exit 0
