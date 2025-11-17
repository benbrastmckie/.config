#!/usr/bin/env bash
# Verify all debug artifacts are complete and ready

echo "=== Debug Artifacts Verification ==="
echo ""

ARTIFACTS_DIR="/home/benjamin/.config/.claude/specs/752_debug_coordinate_workflow_classifier/debug"
cd "$ARTIFACTS_DIR"

# Check all required files exist
REQUIRED_FILES=(
  "001_fix_workflow_classifier.md"
  "002_fix_coordinate_command.md"
  "003_fix_state_persistence.md"
  "004_test_plan.md"
  "README.md"
)

echo "1. Checking required files..."
ALL_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    SIZE=$(stat -c%s "$file")
    echo "  ✓ $file (${SIZE} bytes)"
  else
    echo "  ✗ $file MISSING"
    ALL_PRESENT=false
  fi
done
echo ""

if [ "$ALL_PRESENT" = false ]; then
  echo "✗ FAILED: Some artifacts missing"
  exit 1
fi

# Check content quality
echo "2. Checking content completeness..."

echo "  Checking Fix 001..."
grep -q "sed -i '530,587d'" 001_fix_workflow_classifier.md && \
  echo "    ✓ Deletion command present" || echo "    ✗ Deletion command missing"

echo "  Checking Fix 002..."
grep -q "EXTRACT_FROM_TASK_OUTPUT" 002_fix_coordinate_command.md && \
  echo "    ✓ Extraction pattern present" || echo "    ✗ Extraction pattern missing"

echo "  Checking Fix 003..."
grep -q "shift 2 2>/dev/null || true" 003_fix_state_persistence.md && \
  echo "    ✓ Enhanced signature present" || echo "    ✗ Enhanced signature missing"

echo "  Checking Test Plan..."
grep -q "test_state_validation.sh" 004_test_plan.md && \
  echo "    ✓ Test scripts documented" || echo "    ✗ Test scripts missing"

echo ""

# Check documentation structure
echo "3. Checking documentation structure..."
TOTAL_LINES=$(wc -l *.md | tail -1 | awk '{print $1}')
echo "  Total documentation: $TOTAL_LINES lines"

if [ "$TOTAL_LINES" -gt 2500 ]; then
  echo "  ✓ Comprehensive documentation (>2500 lines)"
else
  echo "  ⚠ Documentation may be incomplete (<2500 lines)"
fi

echo ""
echo "=== Verification Complete ==="
echo ""
echo "Summary:"
echo "  - 5 artifacts created"
echo "  - $TOTAL_LINES lines of documentation"
echo "  - Ready for implementation"
echo ""
echo "Next steps:"
echo "  1. Read README.md for implementation overview"
echo "  2. Apply Fix 001 (workflow-classifier.md)"
echo "  3. Apply Fix 002 (coordinate.md)"
echo "  4. Apply Fix 003 (state-persistence.sh)"
echo "  5. Execute test plan (004_test_plan.md)"
echo ""
