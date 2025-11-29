#!/usr/bin/env bash
# Validate executable/documentation separation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

FAILED=0

echo "Validating command file sizes..."
for cmd in .claude/commands/*.md; do
  if [[ "$cmd" == *"_template"* ]]; then continue; fi
  if [[ "$cmd" == *"README"* ]]; then continue; fi

  lines=$(wc -l < "$cmd")
  # Set limits based on command type
  # build.md is the most complex orchestrator with iteration logic
  # Other orchestrators (debug, revise) handle state machines
  # Regular commands should stay under 800 lines
  max_lines=800
  if [[ "$cmd" == *"build.md" ]]; then
    max_lines=2100  # build.md includes iteration logic and barrier patterns
  elif [[ "$cmd" == *"debug.md" ]] || [[ "$cmd" == *"revise.md" ]] || [[ "$cmd" == *"expand.md" ]]; then
    max_lines=1500  # Orchestrators with state machines or multi-agent coordination (expand.md orchestrates complexity-estimator and plan-architect)
  elif [[ "$cmd" == *"plan.md" ]] || [[ "$cmd" == *"repair.md" ]] || [[ "$cmd" == *"collapse.md" ]]; then
    max_lines=1200  # Complex commands with multi-phase workflows (includes collapse.md due to state machine orchestration)
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
for guide in .claude/docs/guides/commands/*-command-guide.md; do
  if [[ ! -e "$guide" ]]; then
    echo "⊘ SKIP: No command guide files found"
    break
  fi

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
