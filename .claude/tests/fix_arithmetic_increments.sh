#!/usr/bin/env bash
# Fix arithmetic increment operations to work with set -e
# Issue: ((VAR++)) returns old value (0), which causes set -e to exit

set -euo pipefail

echo "Fixing arithmetic increment operations in test files..."
echo ""

# Find all test files with arithmetic increments that don't have || true
FILES=$(grep -rl "\(\([A-Z_]*++\)\)" .claude/tests/*.sh 2>/dev/null | grep -v "|| true" || true)

if [ -z "$FILES" ]; then
  echo "No files found to fix (or all already fixed)"
  exit 0
fi

TOTAL_FIXES=0

for file in $FILES; do
  # Count instances before fix
  BEFORE=$(grep -c "\(\([A-Z_]*++\)\)" "$file" 2>/dev/null | grep -v "|| true" || echo "0")

  if [ "$BEFORE" -eq 0 ]; then
    continue
  fi

  echo "Fixing $file ($BEFORE instances)..."

  # Fix all instances: ((VAR++)) -> ((VAR++)) || true
  # This regex matches:
  # - (( followed by uppercase letters/underscore
  # - followed by ++
  # - followed by ))
  # - NOT followed by || true
  sed -i 's/((TESTS_RUN++)) || true/((TESTS_RUN++)) || true || true/g' "$file"
  sed -i 's/((TESTS_PASSED++)) || true/((TESTS_PASSED++)) || true || true/g' "$file"
  sed -i 's/((TESTS_FAILED++)) || true/((TESTS_FAILED++)) || true || true/g' "$file"
  sed -i 's/((PASSED++)) || true/((PASSED++)) || true || true/g' "$file"
  sed -i 's/((FAILED++)) || true/((FAILED++)) || true || true/g' "$file"
  sed -i 's/((SKIPPED++)) || true/((SKIPPED++)) || true || true/g' "$file"
  sed -i 's/((COUNT++)) || true/((COUNT++)) || true || true/g' "$file"
  sed -i 's/((ERRORS++)) || true/((ERRORS++)) || true || true/g' "$file"

  # Count instances after fix (should be 0 unfixed)
  AFTER=$(grep "\(\([A-Z_]*++\)\)" "$file" 2>/dev/null | grep -v "|| true" | wc -l || echo "0")

  FIXED=$((BEFORE - AFTER))
  TOTAL_FIXES=$((TOTAL_FIXES + FIXED))

  echo "  Fixed $FIXED instances"
done

echo ""
echo "Total fixes applied: $TOTAL_FIXES"
echo "Done!"
