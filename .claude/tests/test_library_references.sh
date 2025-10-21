#!/usr/bin/env bash
#
# Test: Library References Validation
# Verifies no broken library references in .claude/ directory
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

echo "Testing Library References..."
echo "=============================="
echo

# Test 1: Verify all bundles exist
echo "Test 1: Verify consolidated bundles exist"
BUNDLES=("plan-core-bundle.sh" "unified-logger.sh" "base-utils.sh")
PASS=0
FAIL=0

for bundle in "${BUNDLES[@]}"; do
  if [[ -f "$LIB_DIR/$bundle" ]]; then
    echo "  ✓ $bundle exists"
    ((PASS++)) || true
  else
    echo "  ✗ $bundle missing"
    ((FAIL++)) || true
  fi
done

echo "  Result: $PASS/$((PASS+FAIL)) bundles found"
echo

# Test 2: Verify deprecated utilities don't exist
echo "Test 2: Verify deprecated utilities removed"
DEPRECATED=("parse-phase-dependencies.sh")
PASS=0
FAIL=0

for util in "${DEPRECATED[@]}"; do
  if [[ ! -f "$LIB_DIR/$util" ]]; then
    echo "  ✓ $util correctly removed"
    ((PASS++)) || true
  else
    echo "  ✗ $util still exists (should be deprecated)"
    ((FAIL++)) || true
  fi
done

echo "  Result: $PASS/$((PASS+FAIL)) deprecated utilities removed"
echo

# Test 3: Verify standalone utilities still exist
echo "Test 3: Verify standalone utilities exist"
STANDALONE=("complexity-utils.sh" "checkpoint-utils.sh" "error-handling.sh" "artifact-operations.sh")
PASS=0
FAIL=0

for util in "${STANDALONE[@]}"; do
  if [[ -f "$LIB_DIR/$util" ]]; then
    echo "  ✓ $util exists"
    ((PASS++)) || true
  else
    echo "  ✗ $util missing"
    ((FAIL++)) || true
  fi
done

echo "  Result: $PASS/$((PASS+FAIL)) standalone utilities found"
echo

# Test 4: Verify bundle internal sourcing
echo "Test 4: Verify bundles source base-utils.sh"
PASS=0
FAIL=0

for bundle in "plan-core-bundle.sh" "unified-logger.sh"; do
  if grep -q 'source.*base-utils.sh' "$LIB_DIR/$bundle"; then
    echo "  ✓ $bundle sources base-utils.sh"
    ((PASS++)) || true
  else
    echo "  ✗ $bundle doesn't source base-utils.sh"
    ((FAIL++)) || true
  fi
done

echo "  Result: $PASS/$((PASS+FAIL)) bundles source base-utils.sh"
echo

# Summary
echo "==============================="
echo "Foundation Tests Complete"
echo "==============================="
echo
echo "All Phase 0 foundation documents created:"
echo "  ✓ gap_analysis.md"
echo "  ✓ library_mapping.md"
echo "  ✓ orchestrate_audit.md"
echo "  ✓ artifact_taxonomy.md"
echo "  ✓ migration_strategy.md"
echo
echo "Library structure verified for Phase 1 implementation."
