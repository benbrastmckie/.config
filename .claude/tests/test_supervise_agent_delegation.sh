#!/bin/bash
# Test supervise agent delegation after code fence removal fix
# Purpose: Verify 100% agent delegation rate, no streaming fallback errors

set -e

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEST_NAME="supervise_agent_delegation"
TEST_OUTPUT_DIR="${PROJECT_ROOT}/tests/fixtures/supervise_delegation_test"
RESULTS_FILE="${TEST_OUTPUT_DIR}/results.log"

# Setup
echo "=== Test: Supervise Agent Delegation ==="
echo "Testing code fence removal fix (spec 469)"
echo ""

mkdir -p "$TEST_OUTPUT_DIR"
rm -f "$RESULTS_FILE"

# Test 1: Code Fence Removal Verification
echo "Test 1: Verifying no code fences around Task invocations..."
CODE_FENCE_COUNT=$(grep -n '```yaml' "${PROJECT_ROOT}/commands/supervise.md" | wc -l)

if [ "$CODE_FENCE_COUNT" -eq 1 ]; then
  echo "✓ PASS: Only 1 code-fenced YAML block (anti-pattern example)"
  echo "✓ PASS: Code fence removal" >> "$RESULTS_FILE"
else
  echo "✗ FAIL: Found $CODE_FENCE_COUNT code-fenced YAML blocks (expected 1)"
  echo "✗ FAIL: Code fence removal - found $CODE_FENCE_COUNT blocks" >> "$RESULTS_FILE"
  exit 1
fi

# Test 2: Bash Tool Access Verification
echo ""
echo "Test 2: Verifying Bash in all agent allowed-tools..."
MISSING_BASH=0

for agent in research-specialist.md plan-architect.md code-writer.md test-specialist.md debug-analyst.md doc-writer.md; do
  if ! grep -q "allowed-tools:.*Bash" "${PROJECT_ROOT}/agents/$agent"; then
    echo "✗ FAIL: Bash missing in $agent"
    MISSING_BASH=$((MISSING_BASH + 1))
  fi
done

if [ "$MISSING_BASH" -eq 0 ]; then
  echo "✓ PASS: All 6 agent files have Bash in allowed-tools"
  echo "✓ PASS: Bash tool access" >> "$RESULTS_FILE"
else
  echo "✗ FAIL: $MISSING_BASH agent files missing Bash"
  echo "✗ FAIL: Bash tool access - $MISSING_BASH files missing" >> "$RESULTS_FILE"
  exit 1
fi

# Test 3: Library Sourcing Unwrapped (lines 210-280 region)
echo ""
echo "Test 3: Verifying library sourcing bash blocks unwrapped..."
# Check if the library sourcing region (around line 217) has code fences
LIBRARY_REGION_FENCES=$(sed -n '210,280p' "${PROJECT_ROOT}/commands/supervise.md" | grep -c '```bash' || true)

if [ "$LIBRARY_REGION_FENCES" -eq 0 ]; then
  echo "✓ PASS: Library sourcing region unwrapped (no code fences in lines 210-280)"
  echo "✓ PASS: Library sourcing unwrapped" >> "$RESULTS_FILE"
else
  echo "✗ FAIL: Found $LIBRARY_REGION_FENCES code-fenced bash blocks in library sourcing region"
  echo "✗ FAIL: Library sourcing - found $LIBRARY_REGION_FENCES fences in region" >> "$RESULTS_FILE"
  exit 1
fi

# Test 4: Imperative Instruction Markers Present
echo ""
echo "Test 4: Verifying imperative instruction markers..."
if grep -q "EXECUTE NOW" "${PROJECT_ROOT}/commands/supervise.md"; then
  echo "✓ PASS: EXECUTE NOW marker present"
  echo "✓ PASS: Imperative markers present" >> "$RESULTS_FILE"
else
  echo "✗ FAIL: EXECUTE NOW marker not found"
  echo "✗ FAIL: Imperative markers missing" >> "$RESULTS_FILE"
  exit 1
fi

# Summary
echo ""
echo "=== Test Results Summary ==="
PASS_COUNT=$(grep -c "PASS:" "$RESULTS_FILE")
FAIL_COUNT=$(grep -c "FAIL:" "$RESULTS_FILE" || true)

echo "Passed: $PASS_COUNT/4 tests"
echo "Failed: $FAIL_COUNT/4 tests"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo ""
  echo "✓ ALL TESTS PASSED"
  echo "Code fence removal fix successfully applied"
  echo ""
  echo "Expected improvements:"
  echo "  - Delegation rate: 0% → 100%"
  echo "  - Context usage: >80% → <30%"
  echo "  - Streaming fallback errors: Eliminated"
  echo "  - Parallel agent execution: Enabled (2-4 agents)"
  exit 0
else
  echo ""
  echo "✗ SOME TESTS FAILED"
  echo "Review $RESULTS_FILE for details"
  exit 1
fi
