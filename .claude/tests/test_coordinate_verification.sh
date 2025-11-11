#!/usr/bin/env bash
# Test coordinate verification grep patterns
# Tests that verification patterns correctly match state file format

set -euo pipefail

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

STATE_FILE="$TEST_DIR/test_state.sh"

# Create test state file with correct format
cat > "$STATE_FILE" <<'INNER_EOF'
#!/usr/bin/env bash
export WORKFLOW_DESCRIPTION="test workflow"
export WORKFLOW_SCOPE="research-only"
export USE_HIERARCHICAL_RESEARCH="false"
export RESEARCH_COMPLEXITY="2"
export REPORT_PATHS_COUNT="3"
export REPORT_PATH_0="/path/to/report1.md"
export REPORT_PATH_1="/path/to/report2.md"
export REPORT_PATH_2="/path/to/report3.md"
INNER_EOF

# Test 1: Verify REPORT_PATHS_COUNT pattern
echo "Test 1: REPORT_PATHS_COUNT verification"
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ PASS: REPORT_PATHS_COUNT pattern works"
else
  echo "✗ FAIL: REPORT_PATHS_COUNT pattern doesn't match"
  exit 1
fi

# Test 2: Verify USE_HIERARCHICAL_RESEARCH pattern
echo "Test 2: USE_HIERARCHICAL_RESEARCH verification"
if grep -q "^export USE_HIERARCHICAL_RESEARCH=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ PASS: USE_HIERARCHICAL_RESEARCH pattern works"
else
  echo "✗ FAIL: USE_HIERARCHICAL_RESEARCH pattern doesn't match"
  exit 1
fi

# Test 3: Verify RESEARCH_COMPLEXITY pattern
echo "Test 3: RESEARCH_COMPLEXITY verification"
if grep -q "^export RESEARCH_COMPLEXITY=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ PASS: RESEARCH_COMPLEXITY pattern works"
else
  echo "✗ FAIL: RESEARCH_COMPLEXITY pattern doesn't match"
  exit 1
fi

# Test 4: Verify REPORT_PATH_N patterns
echo "Test 4: REPORT_PATH_N verification"
for i in 0 1 2; do
  var_name="REPORT_PATH_$i"
  if grep -q "^export ${var_name}=" "$STATE_FILE" 2>/dev/null; then
    echo "✓ PASS: $var_name pattern works"
  else
    echo "✗ FAIL: $var_name pattern doesn't match"
    exit 1
  fi
done

# Test 5: Verify WORKFLOW_SCOPE pattern
echo "Test 5: WORKFLOW_SCOPE verification"
if grep -q "^export WORKFLOW_SCOPE=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ PASS: WORKFLOW_SCOPE pattern works"
else
  echo "✗ FAIL: WORKFLOW_SCOPE pattern doesn't match"
  exit 1
fi

# Test 6: Negative test (patterns without export prefix should fail)
echo "Test 6: Negative test (patterns without export prefix)"
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "✗ FAIL: Pattern without export prefix incorrectly matched"
  exit 1
else
  echo "✓ PASS: Pattern without export prefix correctly failed"
fi

echo ""
echo "All verification grep pattern tests passed (6/6)"
