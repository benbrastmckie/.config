#!/usr/bin/env bash
#
# Directory Naming Integration Test Suite
#
# Tests topic directory creation for all four directory-creating commands:
# - /plan (creates reports/, plans/)
# - /research (creates reports/ only)
# - /debug (creates reports/, plans/, debug/)
# - /optimize-claude (creates reports/, plans/)
#
# Usage:
#   ./test_directory_naming_integration.sh

set -eo pipefail

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_DIRS=()

# Cleanup function
cleanup() {
  echo ""
  echo "Cleaning up test directories..."
  for dir in "${TEST_DIRS[@]}"; do
    if [ -d "$dir" ]; then
      rm -rf "$dir"
      echo "  Removed: $dir"
    fi
  done
}

# Register cleanup on exit
trap cleanup EXIT

# Test assertion function
assert_topic_name() {
  local command="$1"
  local description="$2"
  local expected_pattern="$3"
  local topic_path="$4"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  local topic_name=$(basename "$topic_path" | sed 's/^[0-9][0-9][0-9]_//')

  if [[ "$topic_name" =~ $expected_pattern ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "  ✓ $command: '$description' → '$topic_name'"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "  ✗ $command: '$description'"
    echo "    Expected pattern: '$expected_pattern'"
    echo "    Actual name: '$topic_name'"
  fi
}

assert_subdirs_exist() {
  local command="$1"
  local topic_path="$2"
  shift 2
  local expected_subdirs=("$@")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  local all_exist=true
  local missing=()

  for subdir in "${expected_subdirs[@]}"; do
    if [ ! -d "$topic_path/$subdir" ]; then
      all_exist=false
      missing+=("$subdir")
    fi
  done

  if $all_exist; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "  ✓ $command subdirectories: ${expected_subdirs[*]}"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "  ✗ $command subdirectories missing: ${missing[*]}"
  fi
}

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/plan/topic-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load topic-utils.sh"
  exit 1
}

# Set SPECS_DIR for testing
SPECS_DIR="/tmp/test_directory_naming_$$"
mkdir -p "$SPECS_DIR"
TEST_DIRS+=("$SPECS_DIR")

echo "========================================"
echo "Directory Naming Integration Test Suite"
echo "========================================"
echo ""
echo "Testing topic directory creation for:"
echo "  - /plan command"
echo "  - /research command"
echo "  - /debug command"
echo "  - /optimize-claude command"
echo ""

# Test 1: /plan command simulation
echo "Testing /plan command simulations:"
echo ""

# Test 1a: Artifact reference in description
desc1="Research .claude/commands/README.md and update flags"
slug1=$(sanitize_topic_name "$desc1")
topic_num1=$(get_or_create_topic_number "$SPECS_DIR" "$slug1")
topic_path1="$SPECS_DIR/${topic_num1}_${slug1}"
create_topic_structure "$topic_path1"
mkdir -p "$topic_path1/reports" "$topic_path1/plans"
TEST_DIRS+=("$topic_path1")
# Expected: no '.md' extension, 'readme' filtered as common basename, 'and' filtered as stopword
# 'commands' preserved as path component, 'update' filtered as planning stopword
assert_topic_name "/plan" "$desc1" "(commands|flags)" "$topic_path1"
assert_subdirs_exist "/plan" "$topic_path1" "reports" "plans"

# Test 1b: Verbose description with stopwords
desc2="carefully create a detailed plan to implement user authentication"
slug2=$(sanitize_topic_name "$desc2")
topic_num2=$(get_or_create_topic_number "$SPECS_DIR" "$slug2")
topic_path2="$SPECS_DIR/${topic_num2}_${slug2}"
create_topic_structure "$topic_path2"
mkdir -p "$topic_path2/reports" "$topic_path2/plans"
TEST_DIRS+=("$topic_path2")
# Expected: stopwords filtered, keep 'user' and 'authentication'
assert_topic_name "/plan" "$desc2" "^(user_authentication|authentication)" "$topic_path2"
assert_subdirs_exist "/plan" "$topic_path2" "reports" "plans"

# Test 1c: Length limit enforcement
desc3="fix the state machine transition error in build command that occurs during phase execution"
slug3=$(sanitize_topic_name "$desc3")
topic_num3=$(get_or_create_topic_number "$SPECS_DIR" "$slug3")
topic_path3="$SPECS_DIR/${topic_num3}_${slug3}"
create_topic_structure "$topic_path3"
mkdir -p "$topic_path3/reports" "$topic_path3/plans"
TEST_DIRS+=("$topic_path3")
# Expected: truncated to ≤35 chars at word boundary
topic_name3=$(basename "$topic_path3" | sed 's/^[0-9][0-9][0-9]_//')
if [ ${#topic_name3} -le 35 ]; then
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  PASSED_TESTS=$((PASSED_TESTS + 1))
  echo "  ✓ /plan: length limit enforced (${#topic_name3} ≤ 35 chars)"
else
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  FAILED_TESTS=$((FAILED_TESTS + 1))
  echo "  ✗ /plan: length limit not enforced (${#topic_name3} > 35 chars)"
fi
assert_subdirs_exist "/plan" "$topic_path3" "reports" "plans"

echo ""

# Test 2: /research command simulation
echo "Testing /research command simulations:"
echo ""

# Test 2a: Artifact path
desc4="research reports/001_analysis.md findings"
slug4=$(sanitize_topic_name "$desc4")
topic_num4=$(get_or_create_topic_number "$SPECS_DIR" "$slug4")
topic_path4="$SPECS_DIR/${topic_num4}_${slug4}"
create_topic_structure "$topic_path4"
mkdir -p "$topic_path4/reports"
TEST_DIRS+=("$topic_path4")
# Expected: no 'reports', no '001_', no '.md'
assert_topic_name "/research" "$desc4" "findings" "$topic_path4"
assert_subdirs_exist "/research" "$topic_path4" "reports"

# Test 2b: Planning meta-words
desc5="carefully research authentication patterns to create comprehensive analysis"
slug5=$(sanitize_topic_name "$desc5")
topic_num5=$(get_or_create_topic_number "$SPECS_DIR" "$slug5")
topic_path5="$SPECS_DIR/${topic_num5}_${slug5}"
create_topic_structure "$topic_path5"
mkdir -p "$topic_path5/reports"
TEST_DIRS+=("$topic_path5")
# Expected: stopwords filtered
assert_topic_name "/research" "$desc5" "authentication_patterns" "$topic_path5"
assert_subdirs_exist "/research" "$topic_path5" "reports"

# Test 2c: File extension
desc6="analyze error-handling.sh patterns in lib directory"
slug6=$(sanitize_topic_name "$desc6")
topic_num6=$(get_or_create_topic_number "$SPECS_DIR" "$slug6")
topic_path6="$SPECS_DIR/${topic_num6}_${slug6}"
create_topic_structure "$topic_path6"
mkdir -p "$topic_path6/reports"
TEST_DIRS+=("$topic_path6")
# Expected: no '.sh', no 'directory', hyphen removed (becomes errorhandling)
assert_topic_name "/research" "$desc6" "errorhandling_patterns_lib" "$topic_path6"
assert_subdirs_exist "/research" "$topic_path6" "reports"

echo ""

# Test 3: /debug command simulation
echo "Testing /debug command simulations:"
echo ""

# Test 3a: Error description
desc7="timeout errors occurring in production environment"
slug7=$(sanitize_topic_name "$desc7")
topic_num7=$(get_or_create_topic_number "$SPECS_DIR" "$slug7")
topic_path7="$SPECS_DIR/${topic_num7}_${slug7}"
create_topic_structure "$topic_path7"
mkdir -p "$topic_path7/reports" "$topic_path7/plans" "$topic_path7/debug"
TEST_DIRS+=("$topic_path7")
assert_topic_name "/debug" "$desc7" "timeout_errors" "$topic_path7"
assert_subdirs_exist "/debug" "$topic_path7" "reports" "plans" "debug"

# Test 3b: Artifact reference
desc8="investigate 001_build_failure.md from debug/ directory"
slug8=$(sanitize_topic_name "$desc8")
topic_num8=$(get_or_create_topic_number "$SPECS_DIR" "$slug8")
topic_path8="$SPECS_DIR/${topic_num8}_${slug8}"
create_topic_structure "$topic_path8"
mkdir -p "$topic_path8/reports" "$topic_path8/plans" "$topic_path8/debug"
TEST_DIRS+=("$topic_path8")
# Expected: no '001_', no '.md', no 'debug'
assert_topic_name "/debug" "$desc8" "build_failure" "$topic_path8"
assert_subdirs_exist "/debug" "$topic_path8" "reports" "plans" "debug"

# Test 3c: Verbose meta-words
desc9="carefully examine the bug in state machine transitions"
slug9=$(sanitize_topic_name "$desc9")
topic_num9=$(get_or_create_topic_number "$SPECS_DIR" "$slug9")
topic_path9="$SPECS_DIR/${topic_num9}_${slug9}"
create_topic_structure "$topic_path9"
mkdir -p "$topic_path9/reports" "$topic_path9/plans" "$topic_path9/debug"
TEST_DIRS+=("$topic_path9")
# Expected: stopwords filtered
assert_topic_name "/debug" "$desc9" "bug_state_machine_transitions" "$topic_path9"
assert_subdirs_exist "/debug" "$topic_path9" "reports" "plans" "debug"

echo ""

# Test 4: /optimize-claude command simulation
echo "Testing /optimize-claude command simulations:"
echo ""

# Test 4a: Standard optimization (fixed description from command)
desc10="optimize claude structure"
slug10=$(sanitize_topic_name "$desc10")
topic_num10=$(get_or_create_topic_number "$SPECS_DIR" "$slug10")
topic_path10="$SPECS_DIR/${topic_num10}_${slug10}"
create_topic_structure "$topic_path10"
mkdir -p "$topic_path10/reports" "$topic_path10/plans"
TEST_DIRS+=("$topic_path10")
assert_topic_name "/optimize-claude" "$desc10" "^(optimize_structure|structure)" "$topic_path10"
assert_subdirs_exist "/optimize-claude" "$topic_path10" "reports" "plans"

# Test 4b: Ensure artifact references handled (edge case)
desc11="claude.md update optimization"
slug11=$(sanitize_topic_name "$desc11")
topic_num11=$(get_or_create_topic_number "$SPECS_DIR" "$slug11")
topic_path11="$SPECS_DIR/${topic_num11}_${slug11}"
create_topic_structure "$topic_path11"
mkdir -p "$topic_path11/reports" "$topic_path11/plans"
TEST_DIRS+=("$topic_path11")
# Expected: no '.md', 'update' filtered as planning stopword
assert_topic_name "/optimize-claude" "$desc11" "optimization" "$topic_path11"
assert_subdirs_exist "/optimize-claude" "$topic_path11" "reports" "plans"

echo ""

# Print summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Total Tests:  $TOTAL_TESTS"
echo "Passed:       $PASSED_TESTS"
echo "Failed:       $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
  echo ""
  echo "✓ All integration tests passed (100%)"
  exit 0
else
  echo ""
  echo "✗ Some integration tests failed"
  exit 1
fi
