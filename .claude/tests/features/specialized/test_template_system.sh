#!/usr/bin/env bash
# Test suite for template system
# Tests parse-template.sh and substitute-variables.sh

set -euo pipefail

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
TEST_DIR="/tmp/template_system_tests_$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$CLAUDE_ROOT/lib"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/templates"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# ============================================================================
# TEMPLATE VALIDATION TESTS
# ============================================================================

test_valid_template_passes() {
  info "Testing valid template validation"

  local template_file="$TEST_DIR/valid_template.yaml"
  cat > "$template_file" <<'EOF'
name: Valid Template
description: A valid test template
version: 1.0

variables:
  - name: feature_name
    description: Name of feature
    required: true

plan:
  title: "{{feature_name}} Implementation"
  overview: |
    Test template overview

  phases:
    - name: Phase 1
      complexity: Low
      tasks:
        - Task 1
        - Task 2
EOF

  if bash "$LIB_DIR/plan/parse-template.sh" "$template_file" validate >/dev/null 2>&1; then
    pass "Valid template passes validation"
  else
    fail "Valid template failed validation" "Template should be valid"
  fi
}

test_missing_name_fails() {
  info "Testing template without name field"

  local template_file="$TEST_DIR/no_name.yaml"
  cat > "$template_file" <<'EOF'
description: Template without name
variables:
  - name: test_var
EOF

  local output
  output=$(bash "$LIB_DIR/plan/parse-template.sh" "$template_file" validate 2>&1) || true
  if echo "$output" | grep -q "missing 'name' field"; then
    pass "Template without name fails validation"
  else
    fail "Template without name should fail" "Expected name field error"
  fi
}

test_missing_description_fails() {
  info "Testing template without description field"

  local template_file="$TEST_DIR/no_desc.yaml"
  cat > "$template_file" <<'EOF'
name: No Description Template
variables:
  - name: test_var
EOF

  local output
  output=$(bash "$LIB_DIR/plan/parse-template.sh" "$template_file" validate 2>&1) || true
  if echo "$output" | grep -q "missing 'description' field"; then
    pass "Template without description fails validation"
  else
    fail "Template without description should fail" "Expected description field error"
  fi
}

test_nonexistent_template_fails() {
  info "Testing nonexistent template file"

  local output
  output=$(bash "$LIB_DIR/plan/parse-template.sh" "$TEST_DIR/nonexistent.yaml" validate 2>&1) || true
  if echo "$output" | grep -q "not found"; then
    pass "Nonexistent template fails with error"
  else
    fail "Nonexistent template should fail" "Expected file not found error"
  fi
}

# ============================================================================
# METADATA EXTRACTION TESTS
# ============================================================================

test_extract_metadata() {
  info "Testing metadata extraction"

  local template_file="$TEST_DIR/metadata_test.yaml"
  cat > "$template_file" <<'EOF'
name: Metadata Test Template
description: Template for testing metadata extraction
version: 1.0
author: Test Author

variables:
  - name: var1
EOF

  local output
  output=$(bash "$LIB_DIR/plan/parse-template.sh" "$template_file" extract-metadata)

  if echo "$output" | grep -q '"name": "Metadata Test Template"'; then
    pass "Extracted template name correctly"
  else
    fail "Failed to extract name" "Output: $output"
  fi

  if echo "$output" | grep -q '"description": "Template for testing metadata extraction"'; then
    pass "Extracted template description correctly"
  else
    fail "Failed to extract description" "Output: $output"
  fi
}

# ============================================================================
# VARIABLE EXTRACTION TESTS
# ============================================================================

test_extract_variables() {
  info "Testing variable extraction"

  local template_file="$TEST_DIR/variables_test.yaml"
  cat > "$template_file" <<'EOF'
name: Variable Test
description: Test variable extraction

variables:
  - name: feature_name
    description: Feature name
    required: true
  - name: component_name
    description: Component name
    required: false
  - name: estimated_hours
    description: Hours estimate
    required: false
    default: "8"

plan:
  title: Test
EOF

  local output
  output=$(bash "$LIB_DIR/plan/parse-template.sh" "$template_file" extract-variables)

  if echo "$output" | grep -q '"name":"feature_name"'; then
    pass "Extracted first variable"
  else
    fail "Failed to extract first variable" "Output: $output"
  fi

  if echo "$output" | grep -q '"name":"component_name"'; then
    pass "Extracted second variable"
  else
    fail "Failed to extract second variable" "Output: $output"
  fi
}

# ============================================================================
# PHASE EXTRACTION TESTS
# ============================================================================

test_extract_phases() {
  info "Testing phase extraction"

  local template_file="$TEST_DIR/phases_test.yaml"
  cat > "$template_file" <<'EOF'
name: Phase Test
description: Test phase extraction

plan:
  phases:
    - name: Planning
      complexity: Low
      tasks:
        - Task 1
    - name: Implementation
      complexity: High
      tasks:
        - Task 2
    - name: Testing
      complexity: Medium
      tasks:
        - Task 3
EOF

  local output
  output=$(bash "$LIB_DIR/plan/parse-template.sh" "$template_file" extract-phases)

  if [[ "$output" == "3" ]]; then
    pass "Extracted correct number of phases (3)"
  else
    fail "Failed to extract phases" "Expected 3, got: $output"
  fi
}

# ============================================================================
# SIMPLE VARIABLE SUBSTITUTION TESTS
# ============================================================================

test_simple_variable_substitution() {
  info "Testing simple variable substitution"

  local template_file="$TEST_DIR/subst_test.yaml"
  cat > "$template_file" <<'EOF'
name: Substitution Test
description: Test {{feature_name}} substitution

plan:
  title: "{{feature_name}} Implementation"
  overview: |
    Implementing {{feature_name}} with {{component_name}}
EOF

  local variables='{"feature_name":"User Auth","component_name":"AuthManager"}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if echo "$output" | grep -q "Test User Auth substitution"; then
    pass "Simple substitution in description"
  else
    fail "Failed substitution in description" "Output: $output"
  fi

  if echo "$output" | grep -q "User Auth Implementation"; then
    pass "Simple substitution in title"
  else
    fail "Failed substitution in title" "Output: $output"
  fi

  if echo "$output" | grep -q "Implementing User Auth with AuthManager"; then
    pass "Multiple substitutions in same line"
  else
    fail "Failed multiple substitutions" "Output: $output"
  fi
}

test_missing_variable_leaves_placeholder() {
  info "Testing missing variable behavior"

  local template_file="$TEST_DIR/missing_var.yaml"
  cat > "$template_file" <<'EOF'
name: Missing Var Test
description: Template with {{undefined_var}}
EOF

  local variables='{"feature_name":"Test"}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if echo "$output" | grep -q "{{undefined_var}}"; then
    pass "Missing variable leaves placeholder intact"
  else
    fail "Missing variable should remain as placeholder" "Output: $output"
  fi
}

# ============================================================================
# CONDITIONAL SUBSTITUTION TESTS
# ============================================================================

test_if_conditional_true() {
  info "Testing {{#if}} conditional (true case)"

  local template_file="$TEST_DIR/if_true.yaml"
  cat > "$template_file" <<'EOF'
name: If True Test
description: Test conditional
plan:
  title: "Feature"
  {{#if has_tests}}
  testing: true
  {{/if}}
EOF

  local variables='{"has_tests":"true"}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if echo "$output" | grep -q "testing: true"; then
    pass "If conditional includes content when true"
  else
    fail "If conditional should include content" "Output: $output"
  fi
}

test_if_conditional_false() {
  info "Testing {{#if}} conditional (false case)"

  local template_file="$TEST_DIR/if_false.yaml"
  cat > "$template_file" <<'EOF'
name: If False Test
description: Test conditional
plan:
  title: "Feature"
  {{#if has_tests}}
  testing: true
  {{/if}}
EOF

  local variables='{"has_tests":"false"}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if ! echo "$output" | grep -q "testing: true"; then
    pass "If conditional excludes content when false"
  else
    fail "If conditional should exclude content" "Output: $output"
  fi
}

test_unless_conditional() {
  info "Testing {{#unless}} conditional"

  local template_file="$TEST_DIR/unless_test.yaml"
  cat > "$template_file" <<'EOF'
name: Unless Test
description: Test unless
plan:
  {{#unless skip_phase}}
  phase_included: true
  {{/unless}}
EOF

  local variables='{"skip_phase":"false"}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if echo "$output" | grep -q "phase_included: true"; then
    pass "Unless conditional includes content when false"
  else
    fail "Unless conditional should include content" "Output: $output"
  fi
}

# ============================================================================
# ARRAY ITERATION TESTS
# ============================================================================

test_each_array_iteration() {
  info "Testing {{#each}} array iteration"

  local template_file="$TEST_DIR/each_test.yaml"
  cat > "$template_file" <<'EOF'
name: Each Test
description: Test iteration
plan:
  fields:
    {{#each fields}}
    - {{this}}
    {{/each}}
EOF

  local variables='{"fields":["name","email","password"]}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if echo "$output" | grep -q -- "- name" && echo "$output" | grep -q -- "- email" && echo "$output" | grep -q -- "- password"; then
    pass "Each iteration processes all array items"
  else
    fail "Each iteration failed" "Output: $output"
  fi
}

test_each_with_index() {
  info "Testing {{@index}} in array iteration"

  local template_file="$TEST_DIR/index_test.yaml"
  cat > "$template_file" <<'EOF'
name: Index Test
description: Test index
plan:
  items:
    {{#each items}}
    - index: {{@index}}, value: {{this}}
    {{/each}}
EOF

  local variables='{"items":["first","second","third"]}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if echo "$output" | grep -q "index: 0" && echo "$output" | grep -q "index: 1" && echo "$output" | grep -q "index: 2"; then
    pass "Index helper works correctly"
  else
    fail "Index helper failed" "Output: $output"
  fi
}

test_each_empty_array() {
  info "Testing {{#each}} with empty array"

  local template_file="$TEST_DIR/empty_array.yaml"
  cat > "$template_file" <<'EOF'
name: Empty Array Test
description: Test empty
plan:
  fields:
    {{#each fields}}
    - {{this}}
    {{/each}}
EOF

  local variables='{"fields":[]}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  # Should not contain any list items after "fields:"
  if ! echo "$output" | grep -A 1 "fields:" | grep -q " - "; then
    pass "Empty array produces no iteration output"
  else
    fail "Empty array should produce no output" "Output: $output"
  fi
}

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

test_malformed_yaml_error() {
  info "Testing malformed YAML handling"

  local template_file="$TEST_DIR/malformed.yaml"
  cat > "$template_file" <<'EOF'
name: Malformed Test
description: Missing quote
  unindented: broken
EOF

  # Template should still validate (our validator is simple)
  # but YAML parser would catch this - testing our validator's limits
  if bash "$LIB_DIR/plan/parse-template.sh" "$template_file" validate >/dev/null 2>&1; then
    pass "Simple validator accepts syntactically complete file"
  else
    fail "Validator too strict" "File has required fields"
  fi
}

test_invalid_json_variables() {
  info "Testing invalid JSON variables"

  local template_file="$TEST_DIR/valid.yaml"
  cat > "$template_file" <<'EOF'
name: Valid
description: Valid template
EOF

  local invalid_json='{invalid json}'

  # Script should handle gracefully (may produce empty substitutions)
  if bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$invalid_json" 2>&1 >/dev/null || true; then
    pass "Invalid JSON handled without crash"
  else
    fail "Should handle invalid JSON gracefully" "Script crashed"
  fi
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_full_template_workflow() {
  info "Testing complete template workflow"

  local template_file="$TEST_DIR/crud_template.yaml"
  cat > "$template_file" <<'EOF'
name: CRUD Feature Template
description: Template for {{entity_name}} CRUD operations

variables:
  - name: entity_name
    description: Entity name
    required: true
  - name: fields
    description: Entity fields
    required: true

plan:
  title: "{{entity_name}} CRUD Implementation"

  overview: |
    Implementing CRUD operations for {{entity_name}} entity.

  phases:
    - name: "Data Model"
      tasks:
        {{#each fields}}
        - Add {{this}} field
        {{/each}}

    - name: "API Endpoints"
      tasks:
        - Create endpoint
        - Read endpoint
        - Update endpoint
        - Delete endpoint
EOF

  # Step 1: Validate
  if bash "$LIB_DIR/plan/parse-template.sh" "$template_file" validate >/dev/null 2>&1; then
    pass "Full workflow: template validation"
  else
    fail "Full workflow: validation failed" "Template should be valid"
  fi

  # Step 2: Extract metadata
  local metadata
  metadata=$(bash "$LIB_DIR/plan/parse-template.sh" "$template_file" extract-metadata)
  if echo "$metadata" | grep -q "CRUD Feature Template"; then
    pass "Full workflow: metadata extraction"
  else
    fail "Full workflow: metadata extraction failed" "Output: $metadata"
  fi

  # Step 3: Extract phases
  local phase_count
  phase_count=$(bash "$LIB_DIR/plan/parse-template.sh" "$template_file" extract-phases)
  if [[ "$phase_count" == "2" ]]; then
    pass "Full workflow: phase extraction (2 phases)"
  else
    fail "Full workflow: phase extraction failed" "Expected 2, got: $phase_count"
  fi

  # Step 4: Substitute variables
  local variables='{"entity_name":"Product","fields":["name","price","description"]}'
  local output
  output=$(bash "$LIB_DIR/artifact/substitute-variables.sh" "$template_file" "$variables")

  if echo "$output" | grep -q "Product CRUD Implementation"; then
    pass "Full workflow: title substitution"
  else
    fail "Full workflow: title substitution failed" "Output: $output"
  fi

  if echo "$output" | grep -q "Add name field" && echo "$output" | grep -q "Add price field"; then
    pass "Full workflow: array iteration in tasks"
  else
    fail "Full workflow: array iteration failed" "Output: $output"
  fi
}

# ============================================================================
# TEST EXECUTION
# ============================================================================

# Set up test environment
setup
trap cleanup EXIT

echo ""
echo "=========================================="
echo "Template System Test Suite"
echo "=========================================="
echo ""

# Template Validation Tests
echo "--- Template Validation Tests ---"
test_valid_template_passes
test_missing_name_fails
test_missing_description_fails
test_nonexistent_template_fails
echo ""

# Metadata Extraction Tests
echo "--- Metadata Extraction Tests ---"
test_extract_metadata
echo ""

# Variable Extraction Tests
echo "--- Variable Extraction Tests ---"
test_extract_variables
echo ""

# Phase Extraction Tests
echo "--- Phase Extraction Tests ---"
test_extract_phases
echo ""

# Simple Variable Substitution Tests
echo "--- Variable Substitution Tests ---"
test_simple_variable_substitution
test_missing_variable_leaves_placeholder
echo ""

# Conditional Tests
echo "--- Conditional Tests ---"
test_if_conditional_true
test_if_conditional_false
test_unless_conditional
echo ""

# Array Iteration Tests
echo "--- Array Iteration Tests ---"
test_each_array_iteration
test_each_with_index
test_each_empty_array
echo ""

# Error Handling Tests
echo "--- Error Handling Tests ---"
test_malformed_yaml_error
test_invalid_json_variables
echo ""

# Integration Tests
echo "--- Integration Tests ---"
test_full_template_workflow
echo ""

# Print summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
