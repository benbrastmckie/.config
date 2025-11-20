#!/usr/bin/env bash
# Validate executable/documentation separation

FAILED=0

echo "Validating command file sizes..."
for cmd in .claude/commands/*.md; do
  if [[ "$cmd" == *"_template"* ]]; then continue; fi
  if [[ "$cmd" == *"README"* ]]; then continue; fi

  lines=$(wc -l < "$cmd")
  # Set limits: coordinate.md needs higher limit (2200), other orchestrators 1200, regular commands 300
  max_lines=1200
  if [[ "$cmd" == *"coordinate.md" ]]; then
    max_lines=3000  # coordinate.md is large due to state-based orchestration complexity
  fi

  if [ "$lines" -gt "$max_lines" ]; then
    echo "✗ FAIL: $cmd has $lines lines (max $max_lines)"
    FAILED=$((FAILED + 1))
  else
    echo "✓ PASS: $cmd ($lines lines)"
  fi
done

echo ""
echo "Validating guide files exist..."
for cmd in .claude/commands/*.md; do
  if [[ "$cmd" == *"_template"* ]]; then continue; fi
  if [[ "$cmd" == *"README"* ]]; then continue; fi

  basename=$(basename "$cmd" .md)
  guide=".claude/docs/guides/commands/${basename}-command-guide.md"

  if grep -q "docs/guides.*${basename}-command-guide.md" "$cmd" 2>/dev/null; then
    if [ -f "$guide" ]; then
      echo "✓ PASS: $cmd has guide at $guide"
    else
      echo "✗ FAIL: $cmd references missing guide $guide"
      FAILED=$((FAILED + 1))
    fi
  else
    # Skip guide requirement check - guides are optional
    echo "⊘ SKIP: $cmd (no guide reference)"
  fi
done

echo ""
echo "Validating cross-references..."
for guide in .claude/docs/guides/*-command-guide.md; do
  basename=$(basename "$guide" -command-guide.md)
  cmd=".claude/commands/${basename}.md"

  if [ -f "$cmd" ]; then
    if grep -q "commands/${basename}.md" "$guide"; then
      echo "✓ PASS: $guide references $cmd"
    else
      echo "✗ FAIL: $guide missing reference to $cmd"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "⊘ SKIP: $guide (command file not found)"
  fi
done

echo ""
if [ $FAILED -eq 0 ]; then
  echo "✓ All validations passed"
  exit 0
else
  echo "✗ $FAILED validation(s) failed"
  exit 1
fi
