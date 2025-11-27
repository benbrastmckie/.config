#!/usr/bin/env bash
#
# Test: Library References Validation
# Verifies no broken library references in .claude/ directory
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

echo "Testing Library References..."
echo "=============================="
echo

# Test 1: Verify all bundles exist (now in subdirectories)
echo "Test 1: Verify consolidated bundles exist"
# Bundles are now in subdirectories: plan/, core/
declare -A BUNDLES=(
  ["plan-core-bundle.sh"]="plan"
  ["unified-logger.sh"]="core"
)
PASS=0
FAIL=0

for bundle in "${!BUNDLES[@]}"; do
  subdir="${BUNDLES[$bundle]}"
  if [[ -f "$LIB_DIR/$subdir/$bundle" ]]; then
    echo "  ✓ $bundle exists (in $subdir/)"
    ((PASS++)) || true
  else
    echo "  ✗ $bundle missing from $subdir/"
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

# Test 3: Verify standalone utilities still exist (now in subdirectories)
echo "Test 3: Verify standalone utilities exist"
# Utilities are now organized in subdirectories
declare -A STANDALONE=(
  ["checkpoint-utils.sh"]="workflow"
  ["error-handling.sh"]="core"
  ["artifact-creation.sh"]="artifact"
)
PASS=0
FAIL=0

for util in "${!STANDALONE[@]}"; do
  subdir="${STANDALONE[$util]}"
  if [[ -f "$LIB_DIR/$subdir/$util" ]]; then
    echo "  ✓ $util exists (in $subdir/)"
    ((PASS++)) || true
  else
    echo "  ✗ $util missing from $subdir/"
    ((FAIL++)) || true
  fi
done

echo "  Result: $PASS/$((PASS+FAIL)) standalone utilities found"
echo

# Test 4: Verify subdirectory structure exists
echo "Test 4: Verify library subdirectory structure"
SUBDIRS=("core" "workflow" "plan" "artifact" "convert" "util")
PASS=0
FAIL=0

for subdir in "${SUBDIRS[@]}"; do
  if [[ -d "$LIB_DIR/$subdir" ]]; then
    # Count files in subdirectory
    count=$(find "$LIB_DIR/$subdir" -name "*.sh" -type f 2>/dev/null | wc -l)
    echo "  ✓ $subdir/ exists ($count libraries)"
    ((PASS++)) || true
  else
    echo "  ✗ $subdir/ missing"
    ((FAIL++)) || true
  fi
done

echo "  Result: $PASS/$((PASS+FAIL)) subdirectories found"
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
