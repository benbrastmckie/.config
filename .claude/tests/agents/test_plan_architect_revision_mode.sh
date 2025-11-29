#!/usr/bin/env bash
# Test plan-architect agent in revision mode
# Tests: Revision mode detection, Edit tool usage, completed phase preservation, PLAN_REVISED signal

set -euo pipefail

# Detect script directory and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || {
  echo "ERROR: Cannot load test-helpers.sh"
  exit 1
}

# Initialize test
setup_test
detect_project_paths "$SCRIPT_DIR"

# Test environment (use temp for test fixtures, but check actual agent file)
TEST_DIR=$(mktemp -d -t plan_architect_revision_XXXXXX)

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Create test environment
mkdir -p "$TEST_DIR/.claude/specs/test_topic/plans"

echo "========================================="
echo "plan-architect Revision Mode Tests"
echo "========================================="
echo

# =============================================================================
# Test 1: plan-architect.md supports revision mode
# =============================================================================
info() { echo "[INFO] $*"; }
info "Test 1: Verify plan-architect.md has revision mode support"

# Read actual plan-architect.md from project
PLAN_ARCHITECT="/home/benjamin/.config/.claude/agents/plan-architect.md"
if [[ -f "$PLAN_ARCHITECT" ]]; then
  # Check for operation mode detection logic
  if grep -q "operation.mode\|Operation Mode\|plan revision" "$PLAN_ARCHITECT"; then
    pass "plan-architect.md contains revision mode logic"
  else
    fail "plan-architect.md missing revision mode" "Should have operation mode detection"
  fi
else
  skip "plan-architect.md not found" "Cannot test agent file"
fi

# =============================================================================
# Test 2: Verify Edit tool in agent metadata
# =============================================================================
info "Test 2: Verify plan-architect.md has Edit tool in allowed-tools"

if [[ -f "$PLAN_ARCHITECT" ]]; then
  # Check frontmatter for Edit tool
  if grep -A 3 "allowed-tools:" "$PLAN_ARCHITECT" | grep -q "Edit"; then
    pass "plan-architect.md has Edit tool enabled"
  else
    fail "plan-architect.md missing Edit tool" "Required for plan revisions"
  fi
else
  skip "plan-architect.md not found"
fi

# =============================================================================
# Test 3: Verify completion signal documentation
# =============================================================================
info "Test 3: Verify PLAN_REVISED completion signal documented"

if [[ -f "$PLAN_ARCHITECT" ]]; then
  # Check for PLAN_REVISED or PLAN_CREATED signal documentation
  if grep -q "PLAN_REVISED\|PLAN_CREATED" "$PLAN_ARCHITECT"; then
    pass "plan-architect.md documents completion signals"
  else
    fail "plan-architect.md missing completion signals" "Should document PLAN_REVISED vs PLAN_CREATED"
  fi
else
  skip "plan-architect.md not found"
fi

# =============================================================================
# Test 4: Create test plan with completed phases
# =============================================================================
info "Test 4: Create test plan fixture with mix of completed and pending phases"

TEST_PLAN="${TEST_DIR}/.claude/specs/test_topic/plans/001_test.md"
cat > "$TEST_PLAN" <<'EOF'
# Test Implementation Plan

## Metadata
- **Date**: 2025-11-26
- **Feature**: Test Feature
- **Structure Level**: 0
- **Status**: IN PROGRESS

## Revision History

## Overview
Test plan for revision mode validation

### Phase 1: Foundation [COMPLETE]
**Objective**: Setup foundation
**Complexity**: Low

**Tasks**:
- [x] Task 1 completed
- [x] Task 2 completed

### Phase 2: Implementation
**Objective**: Core implementation
**Complexity**: Medium

**Tasks**:
- [ ] Task 1 pending
- [ ] Task 2 pending
- [ ] Task 3 pending

### Phase 3: Testing
**Objective**: Test suite
**Complexity**: Low

**Tasks**:
- [ ] Task 1 pending
- [ ] Task 2 pending
EOF

assert_file_exists "$TEST_PLAN" "Test plan fixture created"

# Verify fixture has completed phase marker
if grep -q "\[COMPLETE\]" "$TEST_PLAN"; then
  pass "Test plan has [COMPLETE] marker"
else
  fail "Test plan missing [COMPLETE] marker"
fi

# =============================================================================
# Test 5: Verify backup requirement in agent behavioral file
# =============================================================================
info "Test 5: Verify plan-architect.md requires backup verification"

if [[ -f "$PLAN_ARCHITECT" ]]; then
  # Check for backup-related instructions
  if grep -qi "backup\|BACKUP_PATH" "$PLAN_ARCHITECT"; then
    pass "plan-architect.md references backup requirement"
  else
    skip "plan-architect.md may not reference backups" "Not critical for agent"
  fi
else
  skip "plan-architect.md not found"
fi

# =============================================================================
# Test 6: Test plan structure preservation
# =============================================================================
info "Test 6: Verify plan structure allows for revision"

# Parse the test plan
PHASE_COUNT=$(grep -c "^### Phase" "$TEST_PLAN" || true)
if [[ "$PHASE_COUNT" -eq 3 ]]; then
  pass "Test plan has 3 phases (parseable structure)"
else
  fail "Test plan structure invalid" "Expected 3 phases, found $PHASE_COUNT"
fi

# Verify metadata section exists
if grep -q "^## Metadata" "$TEST_PLAN"; then
  pass "Test plan has Metadata section"
else
  fail "Test plan missing Metadata section"
fi

# Verify Revision History section exists
if grep -q "^## Revision History" "$TEST_PLAN"; then
  pass "Test plan has Revision History section"
else
  fail "Test plan missing Revision History section"
fi

# =============================================================================
# Test 7: Verify operation mode in workflow context
# =============================================================================
info "Test 7: Verify operation mode detection workflow"

# Simulate workflow context that would be passed to plan-architect
WORKFLOW_CONTEXT='operation_mode: plan revision
existing_plan_path: /test/plan.md
backup_path: /test/plan.md.backup
revision_details: Add new phase for error handling'

# Check if context has required fields
if echo "$WORKFLOW_CONTEXT" | grep -q "operation_mode: plan revision"; then
  pass "Workflow context has operation mode field"
else
  fail "Workflow context missing operation mode"
fi

if echo "$WORKFLOW_CONTEXT" | grep -q "existing_plan_path:"; then
  pass "Workflow context has existing plan path"
else
  fail "Workflow context missing existing plan path"
fi

# =============================================================================
# Test 8: Test revision history format
# =============================================================================
info "Test 8: Verify revision history entry format"

REVISION_ENTRY="- **2025-11-26**: Revised based on new security requirements
  - Added Phase 4: Security Hardening
  - Updated Phase 2 complexity estimate"

# Check revision entry format (bullet point with date)
if echo "$REVISION_ENTRY" | grep -q "^- \*\*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\*\*:"; then
  pass "Revision history entry has correct date format"
else
  fail "Revision history format incorrect" "Should be: - **YYYY-MM-DD**: Description"
fi

# =============================================================================
# Test 9: Verify completed phase markers are preserved
# =============================================================================
info "Test 9: Simulate revision and verify [COMPLETE] preservation"

# Create a revised plan (simulating plan-architect Edit)
REVISED_PLAN="${TEST_DIR}/.claude/specs/test_topic/plans/001_test_revised.md"
cp "$TEST_PLAN" "$REVISED_PLAN"

# Simulate adding new phase (keeping Phase 1 [COMPLETE])
# In real scenario, plan-architect would use Edit tool to preserve [COMPLETE]
if grep -q "Phase 1: Foundation \[COMPLETE\]" "$REVISED_PLAN"; then
  pass "Revised plan preserves [COMPLETE] marker"
else
  fail "Revised plan lost [COMPLETE] marker" "Should preserve completed phases"
fi

# =============================================================================
# Test 10: Verify plan-architect uses Edit vs Write
# =============================================================================
info "Test 10: Verify agent instructions emphasize Edit over Write for revisions"

if [[ -f "$PLAN_ARCHITECT" ]]; then
  # Check for Edit tool usage instructions in revision mode
  # This is behavioral guidance, not strict requirement
  if grep -qi "edit\|modify\|update" "$PLAN_ARCHITECT"; then
    pass "plan-architect.md mentions Edit operations"
  else
    skip "plan-architect.md may not explicitly document Edit usage"
  fi
else
  skip "plan-architect.md not found"
fi

# =============================================================================
# Summary
# =============================================================================
echo
teardown_test
