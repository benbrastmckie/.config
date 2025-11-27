#!/usr/bin/env bash
# test_path_canonicalization.sh
#
# Unit tests for canonicalize_path() function in unified-location-detection.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

# Source test helpers
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || \
  { echo "Cannot load test helpers"; exit 1; }

# Source library under test
LIB_PATH="${PROJECT_ROOT}/lib/core/unified-location-detection.sh"

setup_test

# Test: Absolute paths should pass through
test_absolute_path() {
  local test_dir="/tmp/test_canonicalize_$$"
  mkdir -p "$test_dir"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    canonicalize_path '$test_dir'
  ")

  if [[ "$result" == "$test_dir" ]]; then
    pass "absolute_path"
  else
    fail "absolute_path" "Expected: $test_dir, Got: $result"
  fi

  rm -rf "$test_dir"
}

# Test: Path with .. should normalize
test_path_with_dotdot() {
  local test_dir="/tmp/test_canonicalize_$$"
  mkdir -p "$test_dir/a/b"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    canonicalize_path '${test_dir}/a/b/../..'
  ")

  if [[ "$result" == "$test_dir" ]]; then
    pass "path_with_dotdot"
  else
    fail "path_with_dotdot" "Expected: $test_dir, Got: $result"
  fi

  rm -rf "$test_dir"
}

# Test: Symlinks should resolve to real path
test_symlink_resolution() {
  local test_dir="/tmp/test_canonicalize_$$"
  local real_dir="${test_dir}/real"
  local link_dir="${test_dir}/link"

  mkdir -p "$real_dir"
  ln -s "$real_dir" "$link_dir"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    canonicalize_path '$link_dir'
  ")

  if [[ "$result" == "$real_dir" ]]; then
    pass "symlink_resolution"
  else
    fail "symlink_resolution" "Expected: $real_dir, Got: $result"
  fi

  rm -rf "$test_dir"
}

# Test: Trailing slashes should be normalized
test_trailing_slash_normalization() {
  local test_dir="/tmp/test_canonicalize_$$"
  mkdir -p "$test_dir"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    canonicalize_path '${test_dir}/'
  ")

  # readlink -f removes trailing slash
  if [[ "$result" == "$test_dir" ]]; then
    pass "trailing_slash_normalization"
  else
    fail "trailing_slash_normalization" "Expected: $test_dir, Got: $result"
  fi

  rm -rf "$test_dir"
}

# Test: Non-existent paths should canonicalize parent
test_nonexistent_path() {
  local test_dir="/tmp/test_canonicalize_$$"
  mkdir -p "$test_dir"
  local nonexistent="${test_dir}/nonexistent"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    canonicalize_path '$nonexistent'
  ")

  if [[ "$result" == "$nonexistent" ]]; then
    pass "nonexistent_path"
  else
    fail "nonexistent_path" "Expected: $nonexistent, Got: $result"
  fi

  rm -rf "$test_dir"
}

# Test: Non-existent path under root still succeeds (resolves to canonical form)
test_nonexistent_under_root() {
  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    canonicalize_path '/nonexistent_root_946/subdir/file'
  ")

  # Should succeed and return canonical form (even if doesn't exist)
  if [[ "$result" == "/nonexistent_root_946/subdir/file" ]]; then
    pass "nonexistent_under_root"
  else
    fail "nonexistent_under_root" "Expected: /nonexistent_root_946/subdir/file, Got: $result"
  fi
}

# Test: Multiple symlinks in path
test_multiple_symlinks() {
  local test_dir="/tmp/test_canonicalize_$$"
  local real_a="${test_dir}/real_a"
  local real_b="${test_dir}/real_b"
  local link_a="${test_dir}/link_a"
  local link_b="${real_a}/link_b"

  mkdir -p "$real_a" "$real_b"
  ln -s "$real_a" "$link_a"
  ln -s "$real_b" "$link_b"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    canonicalize_path '${link_a}/link_b'
  ")

  if [[ "$result" == "$real_b" ]]; then
    pass "multiple_symlinks"
  else
    fail "multiple_symlinks" "Expected: $real_b, Got: $result"
  fi

  rm -rf "$test_dir"
}

# Run all tests
echo "Running Path Canonicalization Tests..."
test_absolute_path
test_path_with_dotdot
test_symlink_resolution
test_trailing_slash_normalization
test_nonexistent_path
test_nonexistent_under_root
test_multiple_symlinks

teardown_test
