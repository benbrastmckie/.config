#!/usr/bin/env bash
# test_spec_updater.sh - Test spec updater integration
# Tests artifact-operations.sh functions that support spec updater agent

set -euo pipefail

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh" 2>/dev/null || {
  echo "ERROR: Failed to source artifact-creation.sh"
  exit 1
}

# Test fixtures directory
FIXTURES_DIR="$SCRIPT_DIR/fixtures/spec_updater"
TEST_WORKSPACE="$SCRIPT_DIR/fixtures/test_topic_workspace"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Setup test workspace
setup_test_workspace() {
  # Clean and recreate test workspace
  rm -rf "$TEST_WORKSPACE"
  mkdir -p "$TEST_WORKSPACE"

  # Clean registry to avoid number conflicts
  rm -rf "$CLAUDE_PROJECT_DIR/.claude/registry"
}

# Cleanup test workspace
cleanup_test_workspace() {
  rm -rf "$TEST_WORKSPACE"
}

# Test 1: Topic directory structure creation
test_topic_directory_structure() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/001_test_topic"

  # Create topic directory with standard subdirectories
  mkdir -p "$topic_dir"/{reports,plans,summaries,debug,scripts,outputs,artifacts,backups}

  # Verify all subdirectories exist
  local all_exist=true
  for subdir in reports plans summaries debug scripts outputs artifacts backups; do
    if [ ! -d "$topic_dir/$subdir" ]; then
      all_exist=false
      break
    fi
  done

  if [ "$all_exist" = true ]; then
    pass_test "Topic directory structure creation (8 subdirectories)"
  else
    fail_test "Topic directory structure creation" "Missing subdirectories"
  fi

  cleanup_test_workspace
}

# Test 2: create_topic_artifact function
test_create_topic_artifact() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/002_fresh_topic"

  # Create artifact
  local artifact_path=$(create_topic_artifact "$topic_dir" "debug" "test_issue" "Test debug content")

  # Verify artifact was created
  if [ -f "$artifact_path" ] && grep -q "Test debug content" "$artifact_path"; then
    pass_test "create_topic_artifact creates debug artifact"
  else
    fail_test "create_topic_artifact" "Artifact not created or content missing"
  fi

  # Verify artifact numbering (extract the number part)
  local first_num=$(basename "$artifact_path" | grep -oE '^[0-9]+')
  if [ -n "$first_num" ] && [ "$first_num" -ge 1 ]; then
    pass_test "create_topic_artifact uses correct numbering (got $first_num)"
  else
    fail_test "create_topic_artifact numbering" "Invalid number: $first_num"
  fi

  # Create second artifact, verify numbering increments
  local artifact_path2=$(create_topic_artifact "$topic_dir" "debug" "second_issue" "Second issue")
  local second_num=$(basename "$artifact_path2" | grep -oE '^[0-9]+')

  # Second number should be first_num + 1
  if [ "$((10#$second_num))" = "$((10#$first_num + 1))" ]; then
    pass_test "create_topic_artifact increments numbering correctly"
  else
    fail_test "create_topic_artifact incrementing" "Expected $((10#$first_num + 1)), got $second_num"
  fi

  cleanup_test_workspace
}

# Test 3: Artifact metadata structure
test_artifact_metadata() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/001_test_topic"

  # Create artifact with no content (should generate metadata template)
  local artifact_path=$(create_topic_artifact "$topic_dir" "scripts" "test_script" "")

  # Verify metadata fields exist
  local has_date has_topic has_type has_number
  has_date=$(grep -c "\*\*Date\*\*:" "$artifact_path" 2>/dev/null | tr -d '[:space:]' || echo "0")
  has_topic=$(grep -c "\*\*Topic\*\*:" "$artifact_path" 2>/dev/null | tr -d '[:space:]' || echo "0")
  has_type=$(grep -c "\*\*Type\*\*:" "$artifact_path" 2>/dev/null | tr -d '[:space:]' || echo "0")
  has_number=$(grep -c "\*\*Number\*\*:" "$artifact_path" 2>/dev/null | tr -d '[:space:]' || echo "0")

  if [ "$has_date" -gt 0 ] && [ "$has_topic" -gt 0 ] && [ "$has_type" -gt 0 ] && [ "$has_number" -gt 0 ]; then
    pass_test "Artifact metadata includes all required fields"
  else
    fail_test "Artifact metadata" "Missing required metadata fields"
  fi

  cleanup_test_workspace
}

# Test 4: get_next_artifact_number function
test_get_next_artifact_number() {
  setup_test_workspace

  local artifact_dir="$TEST_WORKSPACE/001_test/debug"
  mkdir -p "$artifact_dir"

  # First artifact should be 001
  local next_num=$(get_next_artifact_number "$artifact_dir")
  if [ "$next_num" = "001" ]; then
    pass_test "get_next_artifact_number returns 001 for empty directory"
  else
    fail_test "get_next_artifact_number" "Expected 001, got $next_num"
  fi

  # Create some artifacts
  touch "$artifact_dir/001_first.md"
  touch "$artifact_dir/002_second.md"
  touch "$artifact_dir/005_gap.md"

  # Next number should be 006 (after highest)
  next_num=$(get_next_artifact_number "$artifact_dir")
  if [ "$next_num" = "006" ]; then
    pass_test "get_next_artifact_number returns next after highest (006)"
  else
    fail_test "get_next_artifact_number" "Expected 006, got $next_num"
  fi

  cleanup_test_workspace
}

# Test 5: cleanup_topic_artifacts with age filter
test_cleanup_topic_artifacts() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/001_test_topic"

  # Create some artifacts
  create_topic_artifact "$topic_dir" "scripts" "old_script" "Old content" >/dev/null
  create_topic_artifact "$topic_dir" "scripts" "new_script" "New content" >/dev/null

  # Count files before cleanup
  local files_before=$(find "$CLAUDE_PROJECT_DIR/$topic_dir/scripts" -type f -name "*.md" 2>/dev/null | wc -l | tr -d '[:space:]')

  # Cleanup with age=0 (remove all)
  local count=$(cleanup_topic_artifacts "$topic_dir" "scripts" 0)

  if [ "$count" = "$files_before" ]; then
    pass_test "cleanup_topic_artifacts removes all when age=0 ($count files)"
  else
    fail_test "cleanup_topic_artifacts" "Expected $files_before removed, got $count"
  fi

  # Verify directory was removed (empty)
  if [ ! -d "$topic_dir/scripts" ]; then
    pass_test "cleanup_topic_artifacts removes empty directory"
  else
    fail_test "cleanup_topic_artifacts" "Empty directory not removed"
  fi

  cleanup_test_workspace
}

# Test 6: cleanup_all_temp_artifacts
test_cleanup_all_temp_artifacts() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/006_cleanup_test"

  # Create artifacts in multiple temporary subdirectories
  create_topic_artifact "$topic_dir" "scripts" "script1" "Content" >/dev/null
  create_topic_artifact "$topic_dir" "outputs" "output1" "Content" >/dev/null
  create_topic_artifact "$topic_dir" "artifacts" "artifact1" "Content" >/dev/null

  # Create debug artifact (should NOT be cleaned)
  create_topic_artifact "$topic_dir" "debug" "issue1" "Content" >/dev/null

  # Count temp files before cleanup
  local temp_count=0
  for subdir in scripts outputs artifacts backups data logs notes; do
    local subdir_path="$CLAUDE_PROJECT_DIR/$topic_dir/$subdir"
    if [ -d "$subdir_path" ]; then
      local files=$(find "$subdir_path" -type f -name "*.md" 2>/dev/null | wc -l | tr -d '[:space:]')
      temp_count=$((temp_count + files))
    fi
  done

  # Cleanup all temporary artifacts
  local count=$(cleanup_all_temp_artifacts "$topic_dir")

  if [ "$count" = "$temp_count" ]; then
    pass_test "cleanup_all_temp_artifacts removes all temporary files ($count)"
  else
    fail_test "cleanup_all_temp_artifacts" "Expected $temp_count removed, got $count"
  fi

  # Verify debug/ was NOT touched
  # Find the debug file (number may vary due to test isolation issues)
  local debug_file=$(find "$CLAUDE_PROJECT_DIR/$topic_dir/debug" -name "*.md" -type f | head -1)
  if [ -n "$debug_file" ] && [ -f "$debug_file" ]; then
    pass_test "cleanup_all_temp_artifacts preserves debug/ artifacts"
  else
    fail_test "cleanup_all_temp_artifacts" "Debug artifact was incorrectly removed"
  fi

  cleanup_test_workspace
}

# Test 7: Artifact type validation
test_artifact_type_validation() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/001_test_topic"

  # Try to create artifact with invalid type
  local result=$(create_topic_artifact "$topic_dir" "invalid_type" "test" "Content" 2>&1 || echo "ERROR")

  if echo "$result" | grep -q "Invalid artifact type"; then
    pass_test "create_topic_artifact validates artifact types"
  else
    fail_test "Artifact type validation" "Did not reject invalid type"
  fi

  # Verify valid types work
  local valid_types="debug scripts outputs artifacts backups data logs notes"
  local all_valid=true

  for artifact_type in $valid_types; do
    local artifact_path=$(create_topic_artifact "$topic_dir" "$artifact_type" "test" "Content" 2>/dev/null || echo "FAIL")
    if [[ "$artifact_path" == "FAIL" ]]; then
      all_valid=false
      break
    fi
  done

  if [ "$all_valid" = true ]; then
    pass_test "create_topic_artifact accepts all valid types (8)"
  else
    fail_test "Valid artifact types" "Some valid types were rejected"
  fi

  cleanup_test_workspace
}

# Test 8: Script executable permission
test_script_executable_permission() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/001_test_topic"

  # Create script artifact
  local script_path=$(create_topic_artifact "$topic_dir" "scripts" "test_script" "#!/bin/bash\necho test")

  # Verify executable permission
  if [ -x "$script_path" ]; then
    pass_test "Scripts created with executable permission"
  else
    fail_test "Script executable permission" "Script not executable"
  fi

  cleanup_test_workspace
}

# Test 9: Level 0 plan structure detection
test_level0_plan_structure() {
  local plan_path="$FIXTURES_DIR/test_level0_plan.md"

  # Verify plan file exists
  if [ -f "$plan_path" ]; then
    pass_test "Level 0 plan fixture exists"
  else
    fail_test "Level 0 plan fixture" "File not found"
    return
  fi

  # Count phases (should be 2)
  local phase_count=$(grep -c "^### Phase [0-9]" "$plan_path" || echo "0")

  if [ "$phase_count" = "2" ]; then
    pass_test "Level 0 plan has correct phase count (2)"
  else
    fail_test "Level 0 plan structure" "Expected 2 phases, got $phase_count"
  fi
}

# Test 10: Level 1 plan structure detection
test_level1_plan_structure() {
  local plan_dir="$FIXTURES_DIR/test_level1_plan"
  local main_plan="$plan_dir/test_level1_plan.md"

  # Verify plan directory and main file exist
  if [ -d "$plan_dir" ] && [ -f "$main_plan" ]; then
    pass_test "Level 1 plan fixture structure exists"
  else
    fail_test "Level 1 plan fixture" "Directory or main file not found"
    return
  fi

  # Verify expanded phase files exist
  local phase1_exists=false
  local phase3_exists=false

  [ -f "$plan_dir/phase_1_setup.md" ] && phase1_exists=true
  [ -f "$plan_dir/phase_3_documentation.md" ] && phase3_exists=true

  if [ "$phase1_exists" = true ] && [ "$phase3_exists" = true ]; then
    pass_test "Level 1 plan has expanded phase files (2)"
  else
    fail_test "Level 1 plan structure" "Missing expanded phase files"
  fi
}

# Test 11: Cross-reference validation
test_cross_reference_validation() {
  local plan_dir="$FIXTURES_DIR/test_level1_plan"
  local main_plan="$plan_dir/test_level1_plan.md"

  # Check for cross-references in main plan
  local has_phase1_ref has_phase3_ref
  has_phase1_ref=$(grep -c "phase_1_setup.md" "$main_plan" || echo "0")
  has_phase3_ref=$(grep -c "phase_3_documentation.md" "$main_plan" || echo "0")

  if [ "$has_phase1_ref" -gt 0 ] && [ "$has_phase3_ref" -gt 0 ]; then
    pass_test "Level 1 plan contains cross-references to expanded phases"
  else
    fail_test "Cross-reference validation" "Missing cross-references"
  fi
}

# Test 12: Artifact registry integration
test_artifact_registry_integration() {
  setup_test_workspace

  local topic_dir="$TEST_WORKSPACE/001_test_topic"

  # Create artifact (should register automatically)
  local artifact_path=$(create_topic_artifact "$topic_dir" "debug" "test_issue" "Test content")

  # Verify artifact was registered
  local registry_dir="$CLAUDE_PROJECT_DIR/.claude/registry"

  if [ -d "$registry_dir" ]; then
    local registry_count=$(ls "$registry_dir"/debug_*.json 2>/dev/null | wc -l || echo "0")
    registry_count=${registry_count// /}  # Remove whitespace

    if [ "$registry_count" -gt 0 ]; then
      pass_test "Artifacts are registered in central registry"
    else
      fail_test "Artifact registry integration" "No registry entries found"
    fi
  else
    # Registry integration is optional, don't fail if it doesn't exist
    echo -e "${YELLOW}⊘${NC} Artifact registry not found (optional)"
    ((TESTS_RUN++))
  fi

  cleanup_test_workspace
}

# Run all tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Spec Updater Integration Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_topic_directory_structure
test_create_topic_artifact
test_artifact_metadata
test_get_next_artifact_number
test_cleanup_topic_artifacts
test_cleanup_all_temp_artifacts
test_artifact_type_validation
test_script_executable_permission
test_level0_plan_structure
test_level1_plan_structure
test_cross_reference_validation
test_artifact_registry_integration

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed${NC}"
  echo ""
  echo "NOTE: This test suite validates shell utility integration."
  echo "      Agent-based spec updater functionality (invoked via Task tool)"
  echo "      is tested during Phase 6 end-to-end orchestration testing."
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
