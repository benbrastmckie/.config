#!/usr/bin/env bash
# Run all Lean workflow tests

set -euo pipefail

TEST_DIR="$(dirname "$0")"
PASS_COUNT=0
FAIL_COUNT=0

echo "═══════════════════════════════════════════════════════════"
echo " LEAN WORKFLOW TEST SUITE"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Run unit tests
echo "Running Unit Tests..."
echo "───────────────────────────────────────────────────────────"

for test_file in "$TEST_DIR"/unit/*.sh; do
  if [ -f "$test_file" ]; then
    test_name=$(basename "$test_file" .sh)
    echo ""
    echo "Running: $test_name"

    if bash "$test_file"; then
      echo "✅ $test_name PASSED"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo "❌ $test_name FAILED"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    echo ""
  fi
done

# Summary
echo "═══════════════════════════════════════════════════════════"
echo " FINAL TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo "Passed Test Suites: $PASS_COUNT"
echo "Failed Test Suites: $FAIL_COUNT"
echo "Total Test Suites: $((PASS_COUNT + FAIL_COUNT))"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "Result: ✅ ALL TEST SUITES PASSED"
  exit 0
else
  echo "Result: ❌ SOME TEST SUITES FAILED"
  exit 1
fi
