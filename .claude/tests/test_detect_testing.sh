#!/usr/bin/env bash
# Test suite for detect-testing.sh

set -euo pipefail

# Source the utility
source "$(dirname "$0")/../lib/detect-testing.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  ((TESTS_RUN++))
  if [[ "$expected" == "$actual" ]]; then
    ((TESTS_PASSED++))
    echo "✓ $test_name"
  else
    echo "✗ $test_name"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
  fi
}

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local test_name="$3"

  ((TESTS_RUN++))
  if echo "$haystack" | grep -q "$needle"; then
    ((TESTS_PASSED++))
    echo "✓ $test_name"
  else
    echo "✗ $test_name"
    echo "  Expected to contain: $needle"
    echo "  Actual: $haystack"
  fi
}

# Setup test environments
setup_test_dirs() {
  local base_dir="$1"
  mkdir -p "$base_dir"
}

cleanup_test_dirs() {
  local base_dir="$1"
  rm -rf "$base_dir"
}

# Test 1: Empty directory (score 0)
test_empty_directory() {
  local test_dir="/tmp/test_detect_empty_$$"
  setup_test_dirs "$test_dir"

  local result
  result=$(cd "$test_dir" && detect_testing_score .)

  assert_contains "SCORE:0" "$result" "Empty directory has score 0"
  assert_contains "FRAMEWORKS:none" "$result" "Empty directory has no frameworks"

  cleanup_test_dirs "$test_dir"
}

# Test 2: Directory with test directory (+1)
test_with_test_directory() {
  local test_dir="/tmp/test_detect_testdir_$$"
  setup_test_dirs "$test_dir/tests"

  local result
  result=$(cd "$test_dir" && detect_testing_score .)

  assert_contains "SCORE:1" "$result" "Test directory adds 1 point"

  cleanup_test_dirs "$test_dir"
}

# Test 3: pytest project (high confidence)
test_pytest_project() {
  local test_dir="/tmp/test_detect_pytest_$$"
  setup_test_dirs "$test_dir/tests"
  touch "$test_dir/pytest.ini"
  touch "$test_dir/.github/workflows/test.yml"
  touch "$test_dir/.coveragerc"
  touch "$test_dir/run_tests.sh"

  # Create >10 test files
  for i in {1..12}; do
    touch "$test_dir/tests/test_file${i}.py"
  done

  local result
  result=$(cd "$test_dir" && detect_testing_score .)

  # Should have: CI (+2), test dir (+1), >10 files (+1), coverage (+1), runner (+1) = 6 points
  assert_contains "SCORE:6" "$result" "pytest project with full infrastructure scores 6"
  assert_contains "FRAMEWORKS:pytest" "$result" "pytest project detects pytest framework"

  cleanup_test_dirs "$test_dir"
}

# Test 4: JavaScript project with jest (medium confidence)
test_jest_project() {
  local test_dir="/tmp/test_detect_jest_$$"
  setup_test_dirs "$test_dir/__tests__"
  cat > "$test_dir/package.json" <<'EOF'
{
  "devDependencies": {
    "jest": "^27.0.0"
  }
}
EOF
  touch "$test_dir/jest.config.js"

  # Create 5 test files (not enough for +1 point)
  for i in {1..5}; do
    touch "$test_dir/__tests__/test${i}.spec.js"
  done

  local result
  result=$(cd "$test_dir" && detect_testing_score .)

  # Should have: test dir (+1), coverage tool (+1) = 2 points
  assert_contains "SCORE:2" "$result" "jest project without CI scores 2"
  assert_contains "FRAMEWORKS:jest" "$result" "jest project detects jest framework"

  cleanup_test_dirs "$test_dir"
}

# Test 5: Mixed frameworks (pytest + jest)
test_mixed_frameworks() {
  local test_dir="/tmp/test_detect_mixed_$$"
  setup_test_dirs "$test_dir/tests"
  touch "$test_dir/pytest.ini"
  cat > "$test_dir/package.json" <<'EOF'
{
  "devDependencies": {
    "jest": "^27.0.0"
  }
}
EOF

  local result
  result=$(cd "$test_dir" && detect_testing_score .)

  assert_contains "pytest" "$result" "Mixed project detects pytest"
  assert_contains "jest" "$result" "Mixed project detects jest"

  cleanup_test_dirs "$test_dir"
}

# Test 6: Neovim/Lua project with plenary
test_plenary_project() {
  local test_dir="/tmp/test_detect_plenary_$$"
  setup_test_dirs "$test_dir/tests"
  touch "$test_dir/tests/init_spec.lua"
  touch "$test_dir/tests/config_spec.lua"

  local result
  result=$(cd "$test_dir" && detect_testing_score .)

  assert_contains "SCORE:1" "$result" "plenary project with test dir scores 1"
  assert_contains "FRAMEWORKS:plenary" "$result" "plenary project detects plenary framework"

  cleanup_test_dirs "$test_dir"
}

# Test 7: Current repository
test_current_repository() {
  local result
  result=$(cd /home/benjamin/.config && detect_testing_score .)

  # Should detect bash-tests at minimum
  assert_contains "bash-tests" "$result" "Current repository detects bash-tests"

  # Score should be at least 1 (test directory exists)
  local score
  score=$(echo "$result" | grep "SCORE:" | cut -d':' -f2)
  if [[ $score -ge 1 ]]; then
    ((TESTS_PASSED++))
    echo "✓ Current repository has score >= 1"
  else
    echo "✗ Current repository has score >= 1"
    echo "  Expected: >= 1"
    echo "  Actual: $score"
  fi
  ((TESTS_RUN++))
}

# Run all tests
echo "Running detect-testing.sh test suite..."
echo ""

test_empty_directory
test_with_test_directory
test_pytest_project
test_jest_project
test_mixed_frameworks
test_plenary_project
test_current_repository

# Summary
echo ""
echo "========================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
