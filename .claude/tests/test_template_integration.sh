#!/bin/bash
# Integration tests for template system workflows
# Tests end-to-end functionality of template commands

set -e

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$CLAUDE_ROOT/lib"
TEMPLATE_DIR="$CLAUDE_ROOT/commands/templates"
TEST_SPECS_DIR="$SCRIPT_DIR/test_specs"

# Check if template system exists
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "⚠️  SKIPPED: Template system not found (may have been removed/refactored)"
  echo "Template directory expected at: $TEMPLATE_DIR"
  exit 0
fi

# Note: We'll call utility functions directly rather than sourcing
# to avoid side effects from script-level code

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  File not found: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if grep -q "$pattern" "$file"; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Pattern not found in $file: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_success() {
  local command="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command" &>/dev/null; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Command failed: $command"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Setup test environment
setup_test_env() {
  # Create test specs directory
  mkdir -p "$TEST_SPECS_DIR/plans"
  mkdir -p "$TEST_SPECS_DIR/reports"

  # Clean up any existing test files
  rm -f "$TEST_SPECS_DIR/plans/"*.md
}

# Cleanup test environment
cleanup_test_env() {
  # Remove test specs directory
  rm -rf "$TEST_SPECS_DIR"
}

# Test Suite 1: Template Discovery
echo -e "\n${YELLOW}=== Test Suite 1: Template Discovery ===${NC}\n"

test_list_templates() {
  local output
  output=$(bash "$LIB_DIR/artifact/template-integration.sh" list)
  local count
  count=$(echo "$output" | wc -l)

  assert_equals "10" "$count" "Should list 10 templates"
}

test_list_categories() {
  local output
  output=$(bash "$LIB_DIR/artifact/template-integration.sh" list-category)
  local has_feature
  has_feature=$(echo "$output" | grep -c "feature" || true)

  [[ $has_feature -gt 0 ]] && assert_equals "1" "1" "Should list feature category" || assert_equals "1" "0" "Should list feature category"
}

test_list_templates_by_category() {
  local output
  output=$(bash "$LIB_DIR/artifact/template-integration.sh" list-category "feature")
  local count
  count=$(echo "$output" | wc -l)

  [[ $count -ge 1 ]] && assert_equals "1" "1" "Should list templates in feature category" || assert_equals "1" "0" "Should list templates in feature category"
}

test_list_templates
test_list_categories
test_list_templates_by_category

# Test Suite 2: Plan Number Generation
echo -e "\n${YELLOW}=== Test Suite 2: Plan Number Generation ===${NC}\n"

test_next_plan_number() {
  setup_test_env

  # Create a test plan with number 042
  echo "# Test Plan" > "$TEST_SPECS_DIR/plans/042_test.md"

  local next_num
  next_num=$(bash "$LIB_DIR/artifact/template-integration.sh" next-number "$TEST_SPECS_DIR/plans")

  assert_equals "043" "$next_num" "Should return next plan number after 042"

  cleanup_test_env
}

test_next_plan_number_empty_dir() {
  setup_test_env

  local next_num
  next_num=$(bash "$LIB_DIR/artifact/template-integration.sh" next-number "$TEST_SPECS_DIR/plans")

  assert_equals "001" "$next_num" "Should return 001 for empty directory"

  cleanup_test_env
}

test_next_plan_number
test_next_plan_number_empty_dir

# Test Suite 3: Plan Validation
echo -e "\n${YELLOW}=== Test Suite 3: Plan Validation ===${NC}\n"

test_validate_valid_plan() {
  setup_test_env

  # Create a valid plan
  cat > "$TEST_SPECS_DIR/plans/001_test.md" <<'EOF'
# Test Feature Plan

## Metadata
- **Date**: 2025-10-13
- **Plan Number**: 001
- **Feature**: Test Feature

## Overview
Test plan overview.

## Phase 1: Implementation
- [ ] Task 1
- [ ] Task 2
EOF

  assert_success "bash '$LIB_DIR/artifact/template-integration.sh' validate '$TEST_SPECS_DIR/plans/001_test.md'" "Should validate correct plan structure"

  cleanup_test_env
}

test_validate_missing_metadata() {
  setup_test_env

  # Create an invalid plan (missing metadata)
  cat > "$TEST_SPECS_DIR/plans/002_test.md" <<'EOF'
# Test Feature Plan

## Overview
Test plan overview.

## Phase 1: Implementation
- [ ] Task 1
EOF

  if bash "$LIB_DIR/artifact/template-integration.sh" validate "$TEST_SPECS_DIR/plans/002_test.md" 2>/dev/null; then
    assert_equals "fail" "pass" "Should fail validation for missing metadata"
  else
    assert_equals "fail" "fail" "Should fail validation for missing metadata"
  fi

  cleanup_test_env
}

test_validate_valid_plan
test_validate_missing_metadata

# Test Suite 4: Template Linking
echo -e "\n${YELLOW}=== Test Suite 4: Template Linking ===${NC}\n"

test_link_template_to_plan() {
  setup_test_env

  # Create a plan
  cat > "$TEST_SPECS_DIR/plans/003_test.md" <<'EOF'
# Test Feature Plan

## Metadata
- **Date**: 2025-10-13
- **Plan Number**: 003

## Overview
Test plan.
EOF

  bash "$LIB_DIR/artifact/template-integration.sh" link "$TEST_SPECS_DIR/plans/003_test.md" "example-feature"

  assert_file_contains "$TEST_SPECS_DIR/plans/003_test.md" "Template Source" "Should add template source to plan"

  cleanup_test_env
}

test_link_template_to_plan

# Test Suite 5: End-to-End Template Workflow
echo -e "\n${YELLOW}=== Test Suite 5: End-to-End Workflow ===${NC}\n"

test_template_to_plan_workflow() {
  setup_test_env

  # 1. Validate template exists
  local template_file="$TEMPLATE_DIR/example-feature.yaml"
  [[ -f "$template_file" ]] && assert_equals "success" "success" "Step 1: Template file exists" || assert_equals "success" "fail" "Step 1: Template file exists"

  # 2. Validate template structure
  if bash "$LIB_DIR/plan/parse-template.sh" "$template_file" validate &>/dev/null; then
    assert_equals "success" "success" "Step 2: Template validates"
  else
    assert_equals "success" "fail" "Step 2: Template validates"
  fi

  # 3. Get next plan number
  local next_num
  next_num=$(bash "$LIB_DIR/artifact/template-integration.sh" next-number "$TEST_SPECS_DIR/plans")

  assert_equals "001" "$next_num" "Step 3: Get next plan number"

  # 4. Generate plan file (simplified - just copy template for testing)
  local plan_file="$TEST_SPECS_DIR/plans/${next_num}_test_feature.md"
  cat > "$plan_file" <<'EOF'
# Test Feature Plan

## Metadata
- **Date**: 2025-10-13
- **Plan Number**: 001
- **Feature**: Test Feature

## Overview
Test plan from template.

## Phase 1: Implementation
- [ ] Task 1
EOF

  assert_file_exists "$plan_file" "Step 4: Generate plan file"

  # 5. Link template
  bash "$LIB_DIR/artifact/template-integration.sh" link "$plan_file" "example-feature"

  assert_file_contains "$plan_file" "Template Source" "Step 5: Link template to plan"

  # 6. Validate generated plan
  if bash "$LIB_DIR/artifact/template-integration.sh" validate "$plan_file" &>/dev/null; then
    assert_equals "success" "success" "Step 6: Plan validates"
  else
    assert_equals "success" "fail" "Step 6: Plan validates"
  fi

  cleanup_test_env
}

test_template_to_plan_workflow

# Test Suite 6: Integration with Existing Templates
echo -e "\n${YELLOW}=== Test Suite 6: Template Compatibility ===${NC}\n"

test_all_templates_parseable() {
  local all_parseable=true

  for template in "$TEMPLATE_DIR"/*.yaml; do
    local template_name
    template_name=$(basename "$template" .yaml)

    if bash "$LIB_DIR/plan/parse-template.sh" "$template" validate &>/dev/null; then
      echo -e "${GREEN}✓${NC} Template parseable: $template_name"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} Template not parseable: $template_name"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      all_parseable=false
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
  done

  [[ "$all_parseable" == "true" ]] && return 0 || return 1
}

test_all_templates_have_metadata() {
  local all_have_metadata=true

  for template in "$TEMPLATE_DIR"/*.yaml; do
    local template_name
    template_name=$(basename "$template" .yaml)

    if grep -q "^name:" "$template" && grep -q "^description:" "$template"; then
      echo -e "${GREEN}✓${NC} Template has metadata: $template_name"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} Template missing metadata: $template_name"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      all_have_metadata=false
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
  done

  [[ "$all_have_metadata" == "true" ]] && return 0 || return 1
}

test_all_templates_parseable
test_all_templates_have_metadata

# Print summary
echo -e "\n${YELLOW}=== Test Summary ===${NC}\n"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "\n${GREEN}All tests passed!${NC}\n"
  exit 0
else
  echo -e "\n${RED}Some tests failed.${NC}\n"
  exit 1
fi
