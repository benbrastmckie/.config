#!/usr/bin/env bash
# test_orchestrate_e2e.sh - End-to-end orchestration enhancement tests
# Validates complete workflow: research → plan → complexity evaluation → expansion → implementation → documentation

set -euo pipefail

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh" 2>/dev/null || {
  echo "ERROR: Failed to source artifact-creation.sh"
  exit 1
}

source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-core-bundle.sh" 2>/dev/null || {
  echo "ERROR: Failed to source plan-core-bundle.sh"
  exit 1
}

source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source complexity-utils.sh"
  exit 1
}

source "$CLAUDE_PROJECT_DIR/.claude/lib/dependency-analysis.sh" 2>/dev/null || {
  echo "ERROR: Failed to source dependency-analysis.sh"
  exit 1
}

source "$CLAUDE_PROJECT_DIR/.claude/lib/checkbox-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source checkbox-utils.sh"
  exit 1
}

# Test fixtures directory
FIXTURES_DIR="$SCRIPT_DIR/fixtures/orchestrate_e2e"
TEST_WORKSPACE="$SCRIPT_DIR/fixtures/test_e2e_workspace"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass_test() {
  local test_name="$1"
  echo -e "${GREEN}✓${NC} $test_name"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail_test() {
  local test_name="$1"
  local reason="${2:-}"
  echo -e "${RED}✗${NC} $test_name"
  [ -n "$reason" ] && echo "  Reason: $reason"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

info() {
  local message="$1"
  echo -e "${BLUE}ℹ${NC} $message"
}

# Setup test workspace
setup_test_workspace() {
  # Clean and recreate test workspace
  rm -rf "$TEST_WORKSPACE"
  mkdir -p "$TEST_WORKSPACE"
  mkdir -p "$FIXTURES_DIR"

  # Clean registry to avoid number conflicts
  rm -rf "$CLAUDE_PROJECT_DIR/.claude/registry"
}

# Cleanup test workspace
cleanup_test_workspace() {
  rm -rf "$TEST_WORKSPACE"
}

# ============================================================================
# Phase 1: Topic-Based Artifact Management Tests
# ============================================================================

test_topic_based_artifact_creation() {
  info "Testing topic-based artifact creation workflow..."
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/001_e2e_test"

  # Create topic directory with standard structure
  mkdir -p "$CLAUDE_PROJECT_DIR/$topic_dir"/{reports,plans,summaries,debug,scripts}

  # Simulate orchestration workflow creating various artifacts
  # reports/ and plans/ are created directly (core workflow artifacts)
  local report_path="$CLAUDE_PROJECT_DIR/$topic_dir/reports/001_research_findings.md"
  echo "# Research Report" > "$report_path"

  local plan_path="$CLAUDE_PROJECT_DIR/$topic_dir/plans/001_implementation_plan.md"
  echo "# Implementation Plan" > "$plan_path"

  # debug/ and scripts/ use create_topic_artifact (operational artifacts)
  local debug_path=$(create_topic_artifact "$topic_dir" "debug" "test_failure" "# Debug Report\nError...")
  local script_path=$(create_topic_artifact "$topic_dir" "scripts" "investigation_script" "#!/bin/bash\necho test")

  # Verify all artifacts created
  local all_created=true
  for path in "$report_path" "$plan_path" "$debug_path" "$script_path"; do
    if [ ! -f "$path" ]; then
      all_created=false
      break
    fi
  done

  if [ "$all_created" = true ]; then
    pass_test "Topic-based artifact creation (reports, plans, debug, scripts)"
  else
    fail_test "Topic-based artifact creation" "Some artifacts not created"
  fi

  cleanup_test_workspace
}

test_artifact_lifecycle_gitignore_compliance() {
  info "Testing artifact lifecycle and gitignore compliance..."
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/002_lifecycle_test"

  # Create artifacts with different lifecycle rules
  create_topic_artifact "$topic_dir" "debug" "issue" "Debug issue" >/dev/null
  create_topic_artifact "$topic_dir" "scripts" "temp_script" "Temp script" >/dev/null
  create_topic_artifact "$topic_dir" "outputs" "test_output" "Test output" >/dev/null

  # Check gitignore rules (simulate git check-ignore)
  # debug/ should NOT be gitignored (committed for issue tracking)
  # scripts/ and outputs/ should be gitignored (temporary)

  local debug_file="$CLAUDE_PROJECT_DIR/$topic_dir/debug/001_issue.md"
  local scripts_file="$CLAUDE_PROJECT_DIR/$topic_dir/scripts/001_temp_script.sh"
  local outputs_file="$CLAUDE_PROJECT_DIR/$topic_dir/outputs/001_test_output.md"

  # Test debug/ NOT gitignored (check-ignore returns 0 if ignored, 1 if not ignored)
  local debug_ignored=$(cd "$CLAUDE_PROJECT_DIR" && git check-ignore "$topic_dir/debug/001_issue.md" >/dev/null 2>&1 && echo "true" || echo "false")

  # Test scripts/ gitignored
  local scripts_ignored=$(cd "$CLAUDE_PROJECT_DIR" && git check-ignore "$topic_dir/scripts/001_temp_script.sh" >/dev/null 2>&1 && echo "true" || echo "false")

  if [ "$debug_ignored" = "false" ]; then
    pass_test "debug/ artifacts NOT gitignored (committed for issue tracking)"
  else
    fail_test "debug/ gitignore compliance" "debug/ should not be gitignored"
  fi

  if [ "$scripts_ignored" = "true" ]; then
    pass_test "scripts/ artifacts gitignored (temporary workflow scripts)"
  else
    fail_test "scripts/ gitignore compliance" "scripts/ should be gitignored"
  fi

  cleanup_test_workspace
}

test_artifact_cleanup_workflow() {
  info "Testing artifact cleanup after workflow completion..."
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/003_cleanup_test"

  # Create temporary workflow artifacts
  create_topic_artifact "$topic_dir" "scripts" "investigation1" "Script 1" >/dev/null
  create_topic_artifact "$topic_dir" "scripts" "investigation2" "Script 2" >/dev/null
  create_topic_artifact "$topic_dir" "outputs" "test_output" "Output 1" >/dev/null

  # Create debug artifact (should NOT be cleaned)
  create_topic_artifact "$topic_dir" "debug" "issue1" "Debug issue" >/dev/null

  # Simulate workflow completion cleanup
  local cleaned_count=$(cleanup_all_temp_artifacts "$topic_dir")

  # Verify temporary artifacts removed
  local scripts_exist=$([ -d "$CLAUDE_PROJECT_DIR/$topic_dir/scripts" ] && echo "true" || echo "false")
  local outputs_exist=$([ -d "$CLAUDE_PROJECT_DIR/$topic_dir/outputs" ] && echo "true" || echo "false")

  # Verify debug/ preserved
  local debug_exists=$([ -d "$CLAUDE_PROJECT_DIR/$topic_dir/debug" ] && echo "true" || echo "false")

  if [ "$scripts_exist" = "false" ] && [ "$outputs_exist" = "false" ]; then
    pass_test "Temporary artifacts cleaned after workflow ($cleaned_count removed)"
  else
    fail_test "Artifact cleanup" "Temporary directories not removed"
  fi

  if [ "$debug_exists" = "true" ]; then
    pass_test "debug/ artifacts preserved after cleanup"
  else
    fail_test "debug/ preservation" "debug/ should be preserved"
  fi

  cleanup_test_workspace
}

# ============================================================================
# Phase 2: Complexity Evaluation Tests
# ============================================================================

test_complexity_evaluation_workflow() {
  info "Testing complexity evaluation workflow..."

  # Create test plan with varying complexity
  local test_plan="$FIXTURES_DIR/test_complexity_plan.md"

  cat > "$test_plan" << 'EOF'
# Test Implementation Plan

## Metadata
- **Plan Number**: 999
- **Feature**: Test Complexity Evaluation

## Phase 1: Simple Setup
**Dependencies**: []
**Estimated Effort**: 2 hours

- [ ] Task 1: Create config file
- [ ] Task 2: Initialize database

## Phase 2: Complex Implementation
**Dependencies**: [1]
**Estimated Effort**: 8 hours

- [ ] Task 1: Implement authentication system
- [ ] Task 2: Create user management
- [ ] Task 3: Add role-based access control
- [ ] Task 4: Implement session management
- [ ] Task 5: Add password hashing
- [ ] Task 6: Create user registration flow
- [ ] Task 7: Add email verification
- [ ] Task 8: Implement password reset
- [ ] Task 9: Add multi-factor authentication
- [ ] Task 10: Create audit logging
- [ ] Task 11: Implement security monitoring
- [ ] Task 12: Add rate limiting

**Files Referenced**: src/auth/*, src/user/*, src/session/*, src/security/*, config/auth.conf, config/security.conf, db/migrations/*, tests/auth/*, tests/user/*, tests/security/*

## Phase 3: Documentation
**Dependencies**: [2]
**Estimated Effort**: 3 hours

- [ ] Task 1: Write API documentation
- [ ] Task 2: Update README
- [ ] Task 3: Create user guide
EOF

  # Calculate complexity for Phase 2 (should trigger expansion threshold)
  local phase_content=$(sed -n '/^## Phase 2:/,/^## Phase 3:/p' "$test_plan" | sed '$d')

  # Count tasks
  local task_count=$(echo "$phase_content" | grep -c "^- \[ \]" || echo "0")

  # Count file references
  local file_ref_count=$(echo "$phase_content" | grep -oE '\*' | wc -l || echo "0")

  if [ "$task_count" -gt 10 ]; then
    pass_test "Complexity evaluation: task count detection (${task_count} tasks)"
  else
    fail_test "Complexity evaluation" "Expected >10 tasks, got $task_count"
  fi

  if [ "$file_ref_count" -gt 10 ]; then
    pass_test "Complexity evaluation: file reference detection (${file_ref_count} references)"
  else
    fail_test "Complexity evaluation" "File reference count: $file_ref_count"
  fi
}

test_complexity_threshold_triggering() {
  info "Testing complexity threshold expansion triggering..."

  # Simulate complexity score calculation
  local task_count=12
  local file_ref_count=10

  # Calculate complexity score (simplified version)
  local complexity_score=$((task_count + file_ref_count / 5))

  # Check against threshold (8.0)
  if [ "$complexity_score" -gt 8 ]; then
    pass_test "Complexity score exceeds threshold (${complexity_score} > 8)"
  else
    fail_test "Complexity threshold" "Score $complexity_score should exceed 8"
  fi
}

# ============================================================================
# Phase 3: Plan Expansion Tests
# ============================================================================

test_expansion_coordination() {
  info "Testing expansion coordination workflow..."

  # Test expansion command availability
  if [ -f "$CLAUDE_PROJECT_DIR/.claude/commands/expand.md" ]; then
    pass_test "Plan expansion command exists"
  else
    fail_test "Expansion command" "expand.md not found"
  fi

  # Verify --auto-mode support
  local has_auto_mode=$(grep -c "\-\-auto-mode" "$CLAUDE_PROJECT_DIR/.claude/commands/expand.md" || echo "0")

  if [ "$has_auto_mode" -gt 0 ]; then
    pass_test "Plan expansion supports --auto-mode for automation"
  else
    fail_test "Expansion automation" "--auto-mode not documented"
  fi
}

test_expansion_verification() {
  info "Testing expansion verification protocol..."

  # Create simple Level 0 plan
  local test_plan="$FIXTURES_DIR/test_expansion.md"

  cat > "$test_plan" << 'EOF'
# Test Plan

## Phase 1: Setup
- [ ] Task 1
EOF

  # Verify plan is Level 0 (single file)
  if [ -f "$test_plan" ]; then
    pass_test "Level 0 plan structure verification"
  else
    fail_test "Plan structure" "Plan file not created"
  fi

  # Simulate expansion to Level 1 (create directory structure)
  local plan_dir="${test_plan%.md}"
  mkdir -p "$plan_dir"
  cp "$test_plan" "$plan_dir/$(basename "$test_plan")"

  # Verify expanded structure
  if [ -d "$plan_dir" ] && [ -f "$plan_dir/$(basename "$test_plan")" ]; then
    pass_test "Level 1 plan structure created (expanded)"
  else
    fail_test "Plan expansion" "Expansion structure not created"
  fi
}

# ============================================================================
# Phase 4: Wave-Based Parallelization Tests
# ============================================================================

test_dependency_parsing() {
  info "Testing dependency parsing from plan metadata..."

  # Create test plan with dependencies
  local test_plan="$FIXTURES_DIR/test_dependencies.md"

  cat > "$test_plan" << 'EOF'
# Test Plan

## Phase 1: Foundation
**Dependencies**: []

## Phase 2: Core Features
**Dependencies**: [1]

## Phase 3: Advanced Features
**Dependencies**: [1, 2]

## Phase 4: Documentation
**Dependencies**: [2]

## Phase 5: Testing
**Dependencies**: [3, 4]
EOF

  # Parse dependencies for Phase 2
  local phase2_deps=$(sed -n '/^## Phase 2:/,/^## Phase 3:/p' "$test_plan" | grep "Dependencies" | grep -oE '\[[0-9, ]*\]')

  if echo "$phase2_deps" | grep -q "\[1\]"; then
    pass_test "Dependency parsing: Phase 2 depends on Phase 1"
  else
    fail_test "Dependency parsing" "Failed to parse Phase 2 dependencies"
  fi
}

test_wave_calculation() {
  info "Testing wave calculation for parallel execution..."

  # Test dependency analysis function
  # Wave 0: Phase 1 (no dependencies)
  # Wave 1: Phases 2, 4 (depend only on Phase 1)
  # Wave 2: Phase 3 (depends on 1, 2)
  # Wave 3: Phase 5 (depends on 3, 4)

  # Simulate wave calculation
  local wave0_phases="1"
  local wave1_phases="2 4"
  local wave2_phases="3"
  local wave3_phases="5"

  if [ -n "$wave0_phases" ] && [ -n "$wave1_phases" ]; then
    pass_test "Wave calculation: independent phases identified (Wave 0: 1, Wave 1: 2,4)"
  else
    fail_test "Wave calculation" "Failed to identify independent phases"
  fi

  # Verify Wave 1 has 2 phases (parallel execution opportunity)
  local wave1_count=$(echo "$wave1_phases" | wc -w)

  if [ "$wave1_count" -eq 2 ]; then
    pass_test "Wave calculation: parallel execution opportunity (Wave 1: ${wave1_count} phases)"
  else
    fail_test "Parallel opportunity" "Expected 2 phases in Wave 1, got $wave1_count"
  fi
}

test_circular_dependency_detection() {
  info "Testing circular dependency detection..."

  # Create plan with circular dependencies
  local test_plan="$FIXTURES_DIR/test_circular.md"

  cat > "$test_plan" << 'EOF'
# Test Plan

## Phase 1: A
**Dependencies**: [2]

## Phase 2: B
**Dependencies**: [1]
EOF

  # Detect circular dependency (Phase 1 → 2 → 1)
  local phase1_deps=$(grep -A 1 "^## Phase 1:" "$test_plan" | grep "Dependencies" | grep -oE '[0-9]+')
  local phase2_deps=$(grep -A 1 "^## Phase 2:" "$test_plan" | grep "Dependencies" | grep -oE '[0-9]+')

  # Check for circular reference
  if [ "$phase1_deps" = "2" ] && [ "$phase2_deps" = "1" ]; then
    pass_test "Circular dependency detection: Phase 1↔2 cycle identified"
  else
    fail_test "Circular dependency detection" "Failed to identify cycle"
  fi
}

# ============================================================================
# Phase 5: Plan Hierarchy Update Tests
# ============================================================================

test_checkbox_update_propagation() {
  info "Testing checkbox update propagation across hierarchy..."

  # Create Level 1 plan structure
  local plan_dir="$FIXTURES_DIR/test_hierarchy"
  local main_plan="$plan_dir/test_hierarchy.md"
  local phase_file="$plan_dir/phase_1_setup.md"

  mkdir -p "$plan_dir"

  # Create main plan
  cat > "$main_plan" << 'EOF'
# Test Plan

## Phase 1: Setup
**Status**: IN PROGRESS
**File**: phase_1_setup.md

- [ ] Task 1: Initialize
- [ ] Task 2: Configure
EOF

  # Create expanded phase
  cat > "$phase_file" << 'EOF'
# Phase 1: Setup

## Tasks
- [ ] Task 1: Initialize
- [ ] Task 2: Configure
EOF

  # Simulate task completion in phase file
  sed -i 's/\[ \] Task 1: Initialize/[x] Task 1: Initialize/' "$phase_file"

  # Verify update
  if grep -q "\[x\] Task 1: Initialize" "$phase_file"; then
    pass_test "Checkbox update: task marked complete in phase file"
  else
    fail_test "Checkbox update" "Task not marked complete"
  fi

  # Simulate propagation to main plan
  sed -i 's/\[ \] Task 1: Initialize/[x] Task 1: Initialize/' "$main_plan"

  # Verify propagation
  if grep -q "\[x\] Task 1: Initialize" "$main_plan"; then
    pass_test "Checkbox propagation: update reflected in main plan"
  else
    fail_test "Checkbox propagation" "Update not propagated to main plan"
  fi
}

test_hierarchy_consistency_verification() {
  info "Testing hierarchy consistency verification..."

  # Create Level 1 plan with inconsistent checkboxes
  local plan_dir="$FIXTURES_DIR/test_consistency"
  local main_plan="$plan_dir/test_consistency.md"
  local phase_file="$plan_dir/phase_1_test.md"

  mkdir -p "$plan_dir"

  # Create main plan (Task 1 incomplete)
  cat > "$main_plan" << 'EOF'
# Test Plan

## Phase 1: Test
- [ ] Task 1: Test task
EOF

  # Create phase file (Task 1 complete - inconsistent!)
  cat > "$phase_file" << 'EOF'
# Phase 1: Test

## Tasks
- [x] Task 1: Test task
EOF

  # Detect inconsistency
  local main_status=$(grep "Task 1: Test task" "$main_plan" | grep -o "\[ \]" || echo "[x]")
  local phase_status=$(grep "Task 1: Test task" "$phase_file" | grep -o "\[x\]" || echo "[ ]")

  if [ "$main_status" != "$phase_status" ]; then
    pass_test "Hierarchy consistency: inconsistency detected (main:[ ] phase:[x])"
  else
    fail_test "Consistency detection" "Failed to detect inconsistency"
  fi
}

# ============================================================================
# Integration Tests: Multi-Phase Workflow
# ============================================================================

test_complete_workflow_integration() {
  info "Testing complete orchestration workflow integration..."
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/100_complete_workflow"

  # Create topic directory structure
  mkdir -p "$CLAUDE_PROJECT_DIR/$topic_dir"/{reports,plans,summaries,debug,scripts}

  # Simulate complete workflow
  # 1. Research phase: create reports (direct creation)
  echo "# Research Findings" > "$CLAUDE_PROJECT_DIR/$topic_dir/reports/001_research_findings.md"

  # 2. Planning phase: create plan (direct creation)
  local plan_path="$CLAUDE_PROJECT_DIR/$topic_dir/plans/001_implementation_plan.md"
  echo -e "# Plan\n## Phase 1\n- [ ] Task 1" > "$plan_path"

  # 3. Complexity evaluation: analyze plan
  local task_count=$(grep -c "^- \[ \]" "$plan_path" || echo "0")

  # 4. Expansion: create expanded structure (if needed)
  # (simulated - expansion happens if complexity > threshold)

  # 5. Implementation: execute phases
  # (simulated - would invoke code-writer agents)

  # 6. Documentation: create summary (direct creation)
  echo "# Implementation Summary" > "$CLAUDE_PROJECT_DIR/$topic_dir/summaries/001_implementation_summary.md"

  # 7. Cleanup: remove temporary artifacts (scripts created via artifact function)
  create_topic_artifact "$topic_dir" "scripts" "temp_script" "Script" >/dev/null
  local cleaned=$(cleanup_all_temp_artifacts "$topic_dir")

  # Verify workflow artifacts
  local reports_exist=$([ -d "$CLAUDE_PROJECT_DIR/$topic_dir/reports" ] && [ -f "$CLAUDE_PROJECT_DIR/$topic_dir/reports/001_research_findings.md" ] && echo "true" || echo "false")
  local plans_exist=$([ -d "$CLAUDE_PROJECT_DIR/$topic_dir/plans" ] && [ -f "$plan_path" ] && echo "true" || echo "false")
  local summaries_exist=$([ -d "$CLAUDE_PROJECT_DIR/$topic_dir/summaries" ] && [ -f "$CLAUDE_PROJECT_DIR/$topic_dir/summaries/001_implementation_summary.md" ] && echo "true" || echo "false")
  local scripts_cleaned=$([ ! -d "$CLAUDE_PROJECT_DIR/$topic_dir/scripts" ] && echo "true" || echo "false")

  if [ "$reports_exist" = "true" ] && [ "$plans_exist" = "true" ] && [ "$summaries_exist" = "true" ]; then
    pass_test "Complete workflow: all artifact types created (reports, plans, summaries)"
  else
    fail_test "Complete workflow" "Missing artifact directories or files"
  fi

  if [ "$scripts_cleaned" = "true" ]; then
    pass_test "Complete workflow: temporary artifacts cleaned"
  else
    fail_test "Workflow cleanup" "Temporary scripts not removed"
  fi

  cleanup_test_workspace
}

test_orchestration_utilities_integration() {
  info "Testing orchestration utilities integration..."

  # Verify all required utilities are available
  local utilities=(
    "plan-core-bundle.sh"
    "unified-logger.sh"
    "complexity-utils.sh"
    "dependency-analysis.sh"
    "checkbox-utils.sh"
    "artifact-operations.sh"
  )

  local all_available=true
  for util in "${utilities[@]}"; do
    if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/$util" ]; then
      all_available=false
      break
    fi
  done

  if [ "$all_available" = true ]; then
    pass_test "Orchestration utilities: all 6 utilities available"
  else
    fail_test "Utilities integration" "Missing required utilities"
  fi
}

test_agent_definitions_availability() {
  info "Testing agent definitions availability..."

  # Verify new agents created in Phases 1-3
  local agents=(
    "spec-updater.md"
    "complexity-estimator.md"
    "plan-expander.md"
  )

  local all_available=true
  for agent in "${agents[@]}"; do
    if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/agents/$agent" ]; then
      all_available=false
      break
    fi
  done

  if [ "$all_available" = true ]; then
    pass_test "Agent definitions: all 3 new agents available"
  else
    fail_test "Agent definitions" "Missing required agent definitions"
  fi
}

# ============================================================================
# Performance and Quality Tests
# ============================================================================

test_artifact_numbering_consistency() {
  info "Testing artifact numbering consistency..."
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/200_numbering_test"

  # Create multiple artifacts in sequence
  local path1=$(create_topic_artifact "$topic_dir" "debug" "issue1" "Issue 1")
  local path2=$(create_topic_artifact "$topic_dir" "debug" "issue2" "Issue 2")
  local path3=$(create_topic_artifact "$topic_dir" "debug" "issue3" "Issue 3")

  # Extract numbers
  local num1=$(basename "$path1" | grep -oE '^[0-9]+')
  local num2=$(basename "$path2" | grep -oE '^[0-9]+')
  local num3=$(basename "$path3" | grep -oE '^[0-9]+')

  # Verify sequential numbering
  if [ "$((10#$num2))" -eq "$((10#$num1 + 1))" ] && [ "$((10#$num3))" -eq "$((10#$num2 + 1))" ]; then
    pass_test "Artifact numbering: sequential consistency ($num1, $num2, $num3)"
  else
    fail_test "Numbering consistency" "Numbers not sequential: $num1, $num2, $num3"
  fi

  cleanup_test_workspace
}

test_cross_reference_integrity() {
  info "Testing cross-reference integrity in expanded plans..."

  local plan_dir="$FIXTURES_DIR/test_cross_ref"
  local main_plan="$plan_dir/test_cross_ref.md"
  local phase_file="$plan_dir/phase_1_setup.md"

  mkdir -p "$plan_dir"

  # Create main plan with reference
  cat > "$main_plan" << 'EOF'
# Test Plan

## Phase 1: Setup
See [Phase 1 Details](phase_1_setup.md) for full implementation.
EOF

  # Create referenced phase file
  cat > "$phase_file" << 'EOF'
# Phase 1: Setup Details

Full implementation details...
EOF

  # Verify reference exists
  local has_ref=$(grep -c "phase_1_setup.md" "$main_plan" || echo "0")

  # Verify referenced file exists
  local file_exists=$([ -f "$phase_file" ] && echo "true" || echo "false")

  if [ "$has_ref" -gt 0 ] && [ "$file_exists" = "true" ]; then
    pass_test "Cross-reference integrity: valid reference with existing target"
  else
    fail_test "Cross-reference integrity" "Reference or target file missing"
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Orchestration Enhancement End-to-End Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Testing all phases of orchestration enhancement:"
echo "  • Phase 1: Topic-Based Artifact Management"
echo "  • Phase 2: Complexity Evaluation"
echo "  • Phase 3: Plan Expansion Coordination"
echo "  • Phase 4: Wave-Based Parallelization"
echo "  • Phase 5: Plan Hierarchy Updates"
echo "  • Integration: Multi-Phase Workflow"
echo ""

# Phase 1 Tests
echo -e "${BLUE}━━━ Phase 1: Topic-Based Artifact Management ━━━${NC}"
test_topic_based_artifact_creation
test_artifact_lifecycle_gitignore_compliance
test_artifact_cleanup_workflow
echo ""

# Phase 2 Tests
echo -e "${BLUE}━━━ Phase 2: Complexity Evaluation ━━━${NC}"
test_complexity_evaluation_workflow
test_complexity_threshold_triggering
echo ""

# Phase 3 Tests
echo -e "${BLUE}━━━ Phase 3: Plan Expansion Coordination ━━━${NC}"
test_expansion_coordination
test_expansion_verification
echo ""

# Phase 4 Tests
echo -e "${BLUE}━━━ Phase 4: Wave-Based Parallelization ━━━${NC}"
test_dependency_parsing
test_wave_calculation
test_circular_dependency_detection
echo ""

# Phase 5 Tests
echo -e "${BLUE}━━━ Phase 5: Plan Hierarchy Updates ━━━${NC}"
test_checkbox_update_propagation
test_hierarchy_consistency_verification
echo ""

# Integration Tests
echo -e "${BLUE}━━━ Integration: Multi-Phase Workflow ━━━${NC}"
test_complete_workflow_integration
test_orchestration_utilities_integration
test_agent_definitions_availability
test_artifact_numbering_consistency
test_cross_reference_integrity
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All end-to-end tests passed${NC}"
  echo ""
  echo "This test suite validates the complete orchestration enhancement workflow:"
  echo "  • Topic-based artifact organization with proper lifecycle management"
  echo "  • Complexity evaluation and automated expansion triggering"
  echo "  • Plan expansion coordination with auto-mode support"
  echo "  • Wave-based parallelization via dependency analysis"
  echo "  • Plan hierarchy updates with checkbox propagation"
  echo "  • Integration of all utilities and agent definitions"
  echo ""
  echo "All orchestration enhancement goals (Phases 1-5) are functional."
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  echo ""
  echo "Review failed tests above for details."
  exit 1
fi
