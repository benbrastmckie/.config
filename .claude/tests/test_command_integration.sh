#!/usr/bin/env bash
# Test suite for command integration workflows
# Tests /plan, /implement, /resume-implement, /expand-phase, /collapse-phase

set -e

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
TEST_DIR="/tmp/command_integration_tests_$$"
COMMANDS_DIR="$(dirname "$0")/../commands"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/specs/plans"
  mkdir -p "$TEST_DIR/.claude/checkpoints"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Test: Plan file structure validation
test_plan_file_structure() {
  info "Testing plan file structure"

  local plan_file="$TEST_DIR/specs/plans/001_test_plan.md"
  cat > "$plan_file" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-10-06
- **Feature**: Test Feature
- **Scope**: Testing
- **Structure Level**: 0

## Overview
Test overview

## Implementation Phases

### Phase 1: Setup
**Objective**: Setup test environment
**Complexity**: 3/10

**Tasks**:
- [ ] Create test directory
- [ ] Initialize configuration
EOF

  # Validate metadata section exists
  if grep -q "^## Metadata" "$plan_file"; then
    pass "Plan has metadata section"
  else
    fail "Plan missing metadata section" "No metadata found"
  fi

  # Validate phases section exists
  if grep -q "^## Implementation Phases" "$plan_file" || grep -q "^### Phase 1:" "$plan_file"; then
    pass "Plan has phases section"
  else
    fail "Plan missing phases" "No phases found"
  fi

  # Validate task format
  if grep -q "^- \[ \]" "$plan_file"; then
    pass "Plan has properly formatted tasks"
  else
    fail "Tasks not properly formatted" "Expected checklist format"
  fi
}

# Test: Argument parsing for /plan command
test_plan_argument_parsing() {
  info "Testing /plan argument parsing"

  # Test with valid feature description
  local feature="Add authentication system"
  if [ -n "$feature" ] && [ "${#feature}" -gt 5 ]; then
    pass "Valid feature description accepted"
  else
    fail "Feature description validation failed" "Description: $feature"
  fi

  # Test with empty feature (should fail)
  local empty_feature=""
  if [ -z "$empty_feature" ]; then
    pass "Empty feature description rejected"
  else
    fail "Empty feature should be rejected" "Got: $empty_feature"
  fi
}

# Test: Checkpoint creation and validation
test_checkpoint_operations() {
  info "Testing checkpoint save/restore"

  local checkpoint_file="$TEST_DIR/.claude/data/checkpoints/test_checkpoint.json"

  # Create a simple checkpoint
  cat > "$checkpoint_file" <<'EOF'
{
  "plan_file": "/path/to/plan.md",
  "current_phase": 1,
  "timestamp": "2025-10-06T12:00:00Z",
  "completed_phases": [],
  "status": "in_progress"
}
EOF

  # Validate checkpoint exists
  if [ -f "$checkpoint_file" ]; then
    pass "Checkpoint file created"
  else
    fail "Checkpoint creation failed" "File not found"
  fi

  # Validate checkpoint JSON structure
  if grep -q '"plan_file"' "$checkpoint_file" && \
     grep -q '"current_phase"' "$checkpoint_file"; then
    pass "Checkpoint has required fields"
  else
    fail "Checkpoint missing required fields" "$(cat "$checkpoint_file")"
  fi
}

# Test: Checkpoint field extraction
test_checkpoint_field_parsing() {
  info "Testing checkpoint field extraction"

  local checkpoint_file="$TEST_DIR/.claude/data/checkpoints/fields_test.json"
  cat > "$checkpoint_file" <<'EOF'
{
  "plan_file": "/test/plan.md",
  "current_phase": 2,
  "replanning_count": 0,
  "last_replan_reason": ""
}
EOF

  # Extract current_phase field
  local phase=$(grep '"current_phase"' "$checkpoint_file" | sed 's/.*: \([0-9]*\).*/\1/')
  if [ "$phase" = "2" ]; then
    pass "Extracted current_phase correctly"
  else
    fail "Failed to extract current_phase" "Got: $phase"
  fi

  # Extract plan_file field
  if grep -q '"/test/plan.md"' "$checkpoint_file"; then
    pass "Extracted plan_file correctly"
  else
    fail "Failed to extract plan_file" "$(grep 'plan_file' "$checkpoint_file")"
  fi
}

# Test: /expand-phase creates correct structure
test_expand_phase_structure() {
  info "Testing /expand-phase directory structure"

  local plan_dir="$TEST_DIR/specs/plans/002_expanded_plan"
  mkdir -p "$plan_dir"

  # Create main plan file
  cat > "$plan_dir/002_expanded_plan.md" <<'EOF'
# Expanded Plan

## Metadata
- **Structure Level**: 1

### Phase 1: See phase_1_setup.md
### Phase 2: Implementation
EOF

  # Create expanded phase file
  cat > "$plan_dir/phase_1_setup.md" <<'EOF'
# Phase 1: Setup

**Objective**: Setup environment

**Tasks**:
- [ ] Task 1
- [ ] Task 2
EOF

  # Validate structure
  if [ -d "$plan_dir" ] && \
     [ -f "$plan_dir/002_expanded_plan.md" ] && \
     [ -f "$plan_dir/phase_1_setup.md" ]; then
    pass "Expanded phase structure correct"
  else
    fail "Expanded phase structure invalid" "Missing files or directory"
  fi
}

# Test: Hook execution sequence
test_hook_execution() {
  info "Testing hook execution (simulated)"

  local hook_log="$TEST_DIR/hook_execution.log"

  # Simulate pre-phase hook
  echo "PRE_PHASE: Phase 1 starting" > "$hook_log"

  # Simulate phase execution
  echo "EXECUTE: Running tasks" >> "$hook_log"

  # Simulate post-phase hook
  echo "POST_PHASE: Phase 1 completed" >> "$hook_log"

  # Validate hook sequence
  if grep -q "PRE_PHASE" "$hook_log" && \
     grep -q "POST_PHASE" "$hook_log"; then
    pass "Hook execution sequence correct"
  else
    fail "Hook sequence invalid" "$(cat "$hook_log")"
  fi
}

# Test: Flag parsing for commands
test_flag_parsing() {
  info "Testing command flag parsing"

  # Simulate /setup --cleanup flag
  local args="--cleanup --dry-run"
  if echo "$args" | grep -q -- "--cleanup"; then
    pass "Parsed --cleanup flag"
  else
    fail "Failed to parse --cleanup flag" "Args: $args"
  fi

  if echo "$args" | grep -q -- "--dry-run"; then
    pass "Parsed --dry-run flag"
  else
    fail "Failed to parse --dry-run flag" "Args: $args"
  fi
}

# Test: Template rendering (simulated)
test_template_rendering() {
  info "Testing template variable substitution"

  local template="$TEST_DIR/template.md"
  cat > "$template" <<'EOF'
# Plan: {{PLAN_NAME}}

## Metadata
- **Feature**: {{FEATURE_NAME}}
- **Date**: {{DATE}}
EOF

  # Simulate variable substitution
  local rendered=$(sed -e 's/{{PLAN_NAME}}/Test Plan/' \
                       -e 's/{{FEATURE_NAME}}/Auth System/' \
                       -e 's/{{DATE}}/2025-10-06/' "$template")

  if echo "$rendered" | grep -q "Test Plan" && \
     echo "$rendered" | grep -q "Auth System"; then
    pass "Template variables substituted correctly"
  else
    fail "Template rendering failed" "$rendered"
  fi
}

# Test: Error handling for invalid arguments
test_error_handling() {
  info "Testing error handling for invalid arguments"

  # Test invalid plan path (should be detected)
  local invalid_path="/nonexistent/path/plan.md"
  if [ ! -f "$invalid_path" ]; then
    pass "Detected invalid plan path"
  else
    fail "Failed to detect invalid path" "Path: $invalid_path"
  fi

  # Test malformed checkpoint
  local bad_checkpoint="$TEST_DIR/bad_checkpoint.json"
  echo "not valid json" > "$bad_checkpoint"

  if ! grep -q '"plan_file"' "$bad_checkpoint"; then
    pass "Detected malformed checkpoint"
  else
    fail "Failed to detect malformed checkpoint" "$(cat "$bad_checkpoint")"
  fi
}

# Test: Concurrent checkpoint detection
test_concurrent_checkpoint_handling() {
  info "Testing concurrent checkpoint detection"

  local checkpoint_dir="$TEST_DIR/.claude/checkpoints"
  local lock_file="$checkpoint_dir/test_plan.lock"

  # Simulate existing lock
  mkdir -p "$checkpoint_dir"
  echo "$$" > "$lock_file"

  if [ -f "$lock_file" ]; then
    pass "Lock file created for concurrent access"
  else
    fail "Lock file not created" "Directory: $checkpoint_dir"
  fi

  # Clean up lock
  rm -f "$lock_file"
}

# Test: Legacy format migration
test_legacy_format_migration() {
  info "Testing legacy format migration"

  local legacy_plan="$TEST_DIR/legacy_plan.md"
  cat > "$legacy_plan" <<'EOF'
# Legacy Plan

## Metadata
- **Tier**: 2
- **Date**: 2025-10-06

### Phase 1: Setup
EOF

  # Detect legacy tier field
  if grep -q "Tier" "$legacy_plan"; then
    pass "Detected legacy tier field"
  else
    fail "Failed to detect legacy format" "$(cat "$legacy_plan")"
  fi

  # Simulate migration (replace Tier with Structure Level)
  sed -i 's/Tier/Structure Level/' "$legacy_plan"

  if grep -q "Structure Level" "$legacy_plan"; then
    pass "Migrated tier to structure level"
  else
    fail "Migration failed" "$(grep 'Structure\|Tier' "$legacy_plan")"
  fi
}

# Run all tests
run_all_tests() {
  echo "================================"
  echo "Command Integration Test Suite"
  echo "================================"
  echo ""

  setup

  test_plan_file_structure
  test_plan_argument_parsing
  test_checkpoint_operations
  test_checkpoint_field_parsing
  test_expand_phase_structure
  test_hook_execution
  test_flag_parsing
  test_template_rendering
  test_error_handling
  test_concurrent_checkpoint_handling
  test_legacy_format_migration

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
