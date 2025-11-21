#!/usr/bin/env bash
# Test suite for progressive expansion commands
# Tests /expand-phase and /expand-stage functionality

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
TEST_DIR="/tmp/progressive_expansion_tests_$$"

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

# Create test plan at Level 0
create_test_plan() {
  local plan_file="$TEST_DIR/specs/plans/001_test_feature.md"

  cat > "$plan_file" <<'EOF'
# Test Feature Implementation Plan

## Metadata
- **Date**: 2025-10-06
- **Feature**: Test Feature
- **Plan Number**: 001
- **Structure Tier**: 1
- **Complexity Score**: 45.0

## Overview
This is a test plan for progressive expansion testing.

## Implementation Phases

### Phase 1: Setup [COMPLETED]
**Objective**: Initial setup and configuration
**Complexity**: Low

Tasks:
- [x] Task 1
- [x] Task 2

Testing:
```bash
echo "Test setup"
```

Expected Outcomes:
- Setup complete
- Configuration validated

### Phase 2: Implementation
**Objective**: Build core features
**Complexity**: High

Tasks:
- [ ] Task 1: Backend setup
- [ ] Task 2: Frontend setup
- [ ] Task 3: Integration
- [ ] Task 4: Testing
- [ ] Task 5: Documentation

#### Stage 1: Backend Setup
**Objective**: Setup backend infrastructure

Tasks:
- [ ] Database schema
- [ ] API endpoints
- [ ] Authentication

#### Stage 2: Frontend Setup
**Objective**: Setup frontend components

Tasks:
- [ ] Component structure
- [ ] State management
- [ ] Routing

Testing:
```bash
npm test
```

Expected Outcomes:
- Core features implemented
- Tests passing

### Phase 3: Deployment
**Objective**: Deploy to production
**Complexity**: Medium

Tasks:
- [ ] Deployment task 1
- [ ] Deployment task 2

Testing:
```bash
./deploy.sh test
```

Expected Outcomes:
- Successful deployment

## Testing Strategy
End-to-end testing of all features.
EOF

  echo "$plan_file"
}

# Test 1: Detect structure level of single file (Level 0)
test_detect_level_0() {
  local plan_file=$(create_test_plan)

  local level=$(detect_structure_level "$plan_file")

  if [[ "$level" == "0" ]]; then
    pass "Detect Level 0 structure"
  else
    fail "Detect Level 0 structure" "Expected 0, got $level"
  fi
}

# Test 2: Check plan not expanded initially
test_plan_not_expanded() {
  local plan_file=$(create_test_plan)

  local expanded=$(is_plan_expanded "$plan_file")

  if [[ "$expanded" == "false" ]]; then
    pass "Plan not expanded initially"
  else
    fail "Plan not expanded initially" "Expected false, got $expanded"
  fi
}

# Test 3: Extract phase name
test_extract_phase_name() {
  local plan_file=$(create_test_plan)

  local name=$(extract_phase_name "$plan_file" 2)

  if [[ "$name" == "implementation" ]]; then
    pass "Extract phase name"
  else
    fail "Extract phase name" "Expected 'implementation', got '$name'"
  fi
}

# Test 4: Extract phase content
test_extract_phase_content() {
  local plan_file=$(create_test_plan)

  local content=$(extract_phase_content "$plan_file" 2)

  if echo "$content" | grep -q "### Phase 2: Implementation"; then
    pass "Extract phase content (heading)"
  else
    fail "Extract phase content (heading)" "Phase heading not found"
    return
  fi

  if echo "$content" | grep -q "Build core features"; then
    pass "Extract phase content (objective)"
  else
    fail "Extract phase content (objective)" "Objective not found"
  fi

  if echo "$content" | grep -q "Task 1: Backend setup"; then
    pass "Extract phase content (tasks)"
  else
    fail "Extract phase content (tasks)" "Tasks not found"
  fi
}

# Test 5: Extract stage name
test_extract_stage_name() {
  local plan_file=$(create_test_plan)

  local name=$(extract_stage_name "$plan_file" 1)

  if [[ "$name" == "backend_setup" ]]; then
    pass "Extract stage name"
  else
    fail "Extract stage name" "Expected 'backend_setup', got '$name'"
  fi
}

# Test 6: Extract stage content
test_extract_stage_content() {
  local plan_file=$(create_test_plan)

  local content=$(extract_stage_content "$plan_file" 1)

  if echo "$content" | grep -q "#### Stage 1: Backend Setup"; then
    pass "Extract stage content (heading)"
  else
    fail "Extract stage content (heading)" "Stage heading not found"
  fi

  if echo "$content" | grep -q "Database schema"; then
    pass "Extract stage content (tasks)"
  else
    fail "Extract stage content (tasks)" "Tasks not found"
  fi
}

# Test 7: Simulated first phase expansion (Level 0 → 1)
test_first_phase_expansion() {
  local plan_file=$(create_test_plan)
  local plan_dir="${plan_file%.md}"
  local phase_num=2

  # Simulate expansion
  info "Simulating first phase expansion"

  # Create directory
  mkdir -p "$plan_dir"

  # Move main plan
  mv "$plan_file" "$plan_dir/$(basename "$plan_file")"
  plan_file="$plan_dir/$(basename "$plan_file")"

  # Extract phase content
  local phase_content=$(extract_phase_content "$plan_file" $phase_num)
  local phase_name=$(extract_phase_name "$plan_file" $phase_num)
  local phase_file="$plan_dir/phase_${phase_num}_${phase_name}.md"

  # Create phase file
  echo "$phase_content" > "$phase_file"

  # Add metadata
  add_phase_metadata "$phase_file" $phase_num "$(basename "$plan_file")"

  # Add update reminder
  add_update_reminder "$phase_file" "Phase $phase_num" "$(basename "$plan_file")"

  # Revise main plan
  revise_main_plan_for_phase "$plan_file" $phase_num "$(basename "$phase_file")"

  # Update metadata
  update_structure_level "$plan_file" 1
  update_expanded_phases "$plan_file" $phase_num

  # Verify directory structure
  if [[ -d "$plan_dir" ]]; then
    pass "Phase directory created"
  else
    fail "Phase directory created" "Directory not found"
    return
  fi

  if [[ -f "$phase_file" ]]; then
    pass "Phase file created"
  else
    fail "Phase file created" "Phase file not found"
    return
  fi

  # Verify phase file content
  if grep -q "## Metadata" "$phase_file"; then
    pass "Phase file has metadata"
  else
    fail "Phase file has metadata" "Metadata not found"
  fi

  if grep -q "## Update Reminder" "$phase_file"; then
    pass "Phase file has update reminder"
  else
    fail "Phase file has update reminder" "Update reminder not found"
  fi

  # Verify main plan revision
  if grep -q "For detailed tasks and implementation, see \[Phase 2 Details\]" "$plan_file"; then
    pass "Main plan revised with link"
  else
    fail "Main plan revised with link" "Link not found"
  fi

  # Verify metadata updates
  if grep -q "Structure Level.*: 1" "$plan_file"; then
    pass "Structure Level updated to 1"
  else
    fail "Structure Level updated to 1" "Metadata not updated"
  fi

  if grep -q "Expanded Phases.*: \[2\]" "$plan_file"; then
    pass "Expanded Phases updated"
  else
    fail "Expanded Phases updated" "Expanded Phases not found"
  fi

  # Detect new structure level
  local new_level=$(detect_structure_level "$plan_dir")
  if [[ "$new_level" == "1" ]]; then
    pass "Detect Level 1 after expansion"
  else
    fail "Detect Level 1 after expansion" "Expected 1, got $new_level"
  fi

  # Check if plan is now expanded
  local is_expanded=$(is_plan_expanded "$plan_dir")
  if [[ "$is_expanded" == "true" ]]; then
    pass "Plan detected as expanded"
  else
    fail "Plan detected as expanded" "Expected true, got $is_expanded"
  fi

  # Check if phase is expanded
  local phase_expanded=$(is_phase_expanded "$plan_dir" 2)
  if [[ "$phase_expanded" == "true" ]]; then
    pass "Phase 2 detected as expanded"
  else
    fail "Phase 2 detected as expanded" "Expected true, got $phase_expanded"
  fi

  # List expanded phases
  local expanded_list=$(list_expanded_phases "$plan_dir")
  if [[ "$expanded_list" == "2" ]]; then
    pass "List expanded phases returns [2]"
  else
    fail "List expanded phases returns [2]" "Expected '2', got '$expanded_list'"
  fi
}

# Run all tests
run_tests() {
  info "Starting progressive expansion tests"
  setup

  test_detect_level_0
  test_plan_not_expanded
  test_extract_phase_name
  test_extract_phase_content
  test_extract_stage_name
  test_extract_stage_content
  test_first_phase_expansion

  cleanup

  echo ""
  echo "========================================="
  echo "Test Results:"
  echo "  Total:  $TESTS_RUN"
  echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
  echo "========================================="

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
  fi
}

# Run tests
run_tests
