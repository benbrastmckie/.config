#!/usr/bin/env bash
# Unit tests for lib/artifact/artifact-registry.sh
#
# Tests artifact registration and tracking functions:
#   - register_artifact
#   - query_artifacts
#   - cleanup_artifacts
#   - validate_artifact_references

# Note: Not using set -e because the library being tested has its own set -euo pipefail
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

# Source test helpers
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || \
  { echo "Cannot load test helpers"; exit 1; }

# Create isolated test environment
TEST_TMP="${SCRIPT_DIR}/../tmp/test_artifact_$$"
mkdir -p "$TEST_TMP"

# Set up isolated registry directory
export CLAUDE_PROJECT_DIR="$TEST_TMP"
mkdir -p "${TEST_TMP}/.claude/data/registry"

# Source library under test (it has set -euo pipefail)
LIB_PATH="${PROJECT_ROOT}/lib/artifact/artifact-registry.sh"
source "$LIB_PATH" 2>/dev/null || { echo "Cannot load artifact-registry"; exit 1; }

# Disable errexit that the library set
set +e

# Set up cleanup trap AFTER sourcing the library
trap "rm -rf '$TEST_TMP'" EXIT

setup_test

# Test: register_artifact creates artifact ID
test_register_artifact_basic() {
  local artifact_id
  artifact_id=$(register_artifact "test" "${TEST_TMP}/sample.txt" '{"key":"value"}')

  if [[ -n "$artifact_id" && "$artifact_id" == test_* ]]; then
    pass "register_artifact_returns_id"
  else
    fail "register_artifact_returns_id" "Expected ID starting with 'test_', got: $artifact_id"
  fi
}

# Test: register_artifact creates registry file
test_register_artifact_creates_file() {
  local artifact_id
  artifact_id=$(register_artifact "plan" "${TEST_TMP}/test_plan.md" '{}')

  local registry_file="${TEST_TMP}/.claude/data/registry/${artifact_id}.json"
  assert_file_exists "$registry_file" "register_artifact_creates_file"
}

# Test: register_artifact validates required args
test_register_artifact_missing_args() {
  local exit_code=0
  register_artifact "" "" "" >/dev/null 2>&1 || exit_code=$?

  # Should return non-zero exit code when args missing
  if [[ $exit_code -ne 0 ]]; then
    pass "register_artifact_validates_args"
  else
    fail "register_artifact_validates_args" "Expected non-zero exit for missing args"
  fi
}

# Test: query_artifacts returns empty array for no matches
test_query_artifacts_empty() {
  # Use a type that doesn't exist
  local result
  result=$(query_artifacts "nonexistent_type_xyz")

  assert_equals "[]" "$result" "query_artifacts_empty_result"
}

# Test: query_artifacts finds registered artifacts
test_query_artifacts_finds() {
  # Register some test artifacts
  register_artifact "query_test" "${TEST_TMP}/file1.txt" '{}' >/dev/null
  register_artifact "query_test" "${TEST_TMP}/file2.txt" '{}' >/dev/null

  local result
  result=$(query_artifacts "query_test")

  if [[ "$result" != "[]" && "$result" == *"query_test"* ]]; then
    pass "query_artifacts_finds_registered"
  else
    fail "query_artifacts_finds_registered" "Expected to find query_test artifacts"
  fi
}

# Test: query_artifacts with pattern
test_query_artifacts_pattern() {
  register_artifact "pattern_test" "${TEST_TMP}/match_file.txt" '{}' >/dev/null
  register_artifact "pattern_test" "${TEST_TMP}/other_file.txt" '{}' >/dev/null

  local result
  result=$(query_artifacts "pattern_test" "match*")

  if [[ "$result" != "[]" && "$result" == *"match_file"* ]]; then
    pass "query_artifacts_pattern_matching"
  else
    fail "query_artifacts_pattern_matching" "Expected to find match_file"
  fi
}

# Test: cleanup_artifacts returns count
test_cleanup_artifacts_count() {
  local count
  count=$(cleanup_artifacts 0)

  # Should return a number (may be 0 or more)
  if [[ "$count" =~ ^[0-9]+$ ]]; then
    pass "cleanup_artifacts_returns_count"
  else
    fail "cleanup_artifacts_returns_count" "Expected numeric count, got: $count"
  fi
}

# Test: validate_artifact_references returns JSON
test_validate_references_json() {
  local result
  result=$(validate_artifact_references "test_type")

  if [[ "$result" == *"valid"* && "$result" == *"invalid"* ]]; then
    pass "validate_references_returns_json"
  else
    fail "validate_references_returns_json" "Expected JSON with valid/invalid, got: $result"
  fi
}

# Test: list_artifacts outputs formatted list
test_list_artifacts_output() {
  # Register an artifact to list
  register_artifact "list_test" "${TEST_TMP}/listable.txt" '{}' >/dev/null

  local output
  output=$(list_artifacts "list_test")

  if [[ "$output" == *"Registered Artifacts"* || "$output" == *"list_test"* ]]; then
    pass "list_artifacts_formatted_output"
  else
    fail "list_artifacts_formatted_output" "Expected formatted artifact list"
  fi
}

# Test: get_artifact_path_by_id retrieves path
test_get_artifact_path() {
  # Register artifact and get ID
  local artifact_id
  artifact_id=$(register_artifact "path_test" "${TEST_TMP}/path_test_file.md" '{}')

  local path
  path=$(get_artifact_path_by_id "$artifact_id")

  if [[ "$path" == *"path_test_file.md"* ]]; then
    pass "get_artifact_path_by_id"
  else
    fail "get_artifact_path_by_id" "Expected path containing 'path_test_file.md', got: $path"
  fi
}

# Test: get_artifact_path_by_id returns error for invalid ID
test_get_artifact_path_invalid() {
  local exit_code=0
  get_artifact_path_by_id "nonexistent_id_xyz" >/dev/null 2>&1 || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    pass "get_artifact_path_invalid_id_fails"
  else
    fail "get_artifact_path_invalid_id_fails" "Expected failure for invalid ID"
  fi
}

# Test: create_artifact_directory creates directory
test_create_artifact_directory() {
  local artifact_dir
  artifact_dir=$(create_artifact_directory "specs/plans/001_test_feature.md")

  if [[ -d "$artifact_dir" ]]; then
    pass "create_artifact_directory_creates_dir"
  else
    fail "create_artifact_directory_creates_dir" "Directory not created: $artifact_dir"
  fi
}

# Test: create_artifact_directory validates input
test_create_artifact_directory_validation() {
  local output
  output=$(create_artifact_directory "" 2>&1) || true

  assert_contains "Usage:" "$output" "create_artifact_directory_validates_input"
}

# Test: registry file contains valid JSON
test_registry_file_valid_json() {
  local artifact_id
  artifact_id=$(register_artifact "json_test" "${TEST_TMP}/json_file.txt" '{"meta":"data"}')

  local registry_file="${TEST_TMP}/.claude/data/registry/${artifact_id}.json"

  if command -v jq &>/dev/null; then
    if jq empty "$registry_file" 2>/dev/null; then
      pass "registry_file_valid_json"
    else
      fail "registry_file_valid_json" "Registry file contains invalid JSON"
    fi
  else
    skip "registry_file_valid_json" "jq not available for JSON validation"
  fi
}

# Test: registry entry contains required fields
test_registry_entry_fields() {
  local artifact_id
  artifact_id=$(register_artifact "fields_test" "${TEST_TMP}/fields.txt" '{}')

  local registry_file="${TEST_TMP}/.claude/data/registry/${artifact_id}.json"

  if command -v jq &>/dev/null; then
    local has_id has_type has_path has_created
    has_id=$(jq -r '.artifact_id' "$registry_file")
    has_type=$(jq -r '.artifact_type' "$registry_file")
    has_path=$(jq -r '.artifact_path' "$registry_file")
    has_created=$(jq -r '.created_at' "$registry_file")

    if [[ -n "$has_id" && -n "$has_type" && -n "$has_path" && -n "$has_created" ]]; then
      pass "registry_entry_has_required_fields"
    else
      fail "registry_entry_has_required_fields" "Missing required fields in registry entry"
    fi
  else
    skip "registry_entry_has_required_fields" "jq not available"
  fi
}

# Run all tests
test_register_artifact_basic
test_register_artifact_creates_file
test_register_artifact_missing_args
test_query_artifacts_empty
test_query_artifacts_finds
test_query_artifacts_pattern
test_cleanup_artifacts_count
test_validate_references_json
test_list_artifacts_output
test_get_artifact_path
test_get_artifact_path_invalid
test_create_artifact_directory
test_create_artifact_directory_validation
test_registry_file_valid_json
test_registry_entry_fields

teardown_test
