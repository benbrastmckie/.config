#!/usr/bin/env bash
# Validate all file references in Phase 7 plan files

set -e

PLAN_DIR="/home/benjamin/.config/.claude/specs/plans/045_claude_directory_optimization/phase_7_directory_modularization"
CLAUDE_DIR="/home/benjamin/.config/.claude"
PASS_COUNT=0
FAIL_COUNT=0

echo "═══════════════════════════════════════"
echo "Phase 7 File Reference Validation"
echo "Date: $(date -I)"
echo "═══════════════════════════════════════"
echo ""

# Helper function to check if file exists
check_file_exists() {
  local file=$1
  local referenced_in=$2

  if [ -f "$file" ]; then
    echo "✓ PASS: $file (referenced in $referenced_in)"
    ((PASS_COUNT++))
    return 0
  else
    echo "✗ FAIL: $file NOT FOUND (referenced in $referenced_in)"
    ((FAIL_COUNT++))
    return 1
  fi
}

echo "Checking Plan Files..."
check_file_exists "$PLAN_DIR/phase_7_overview.md" "plan root"
check_file_exists "$PLAN_DIR/stage_1_foundation.md" "phase_7_overview.md"
check_file_exists "$PLAN_DIR/stage_2_orchestrate_extraction.md" "phase_7_overview.md"
check_file_exists "$PLAN_DIR/stage_3_implement_extraction.md" "phase_7_overview.md"
check_file_exists "$PLAN_DIR/stage_4_utility_consolidation.md" "phase_7_overview.md"
check_file_exists "$PLAN_DIR/stage_5_documentation_validation.md" "phase_7_overview.md"

echo ""
echo "Checking Referenced Command Files..."
check_file_exists "$CLAUDE_DIR/commands/orchestrate.md" "plan baselines"
check_file_exists "$CLAUDE_DIR/commands/implement.md" "plan baselines"
check_file_exists "$CLAUDE_DIR/commands/setup.md" "plan baselines"
check_file_exists "$CLAUDE_DIR/commands/revise.md" "plan baselines"

echo ""
echo "Checking Referenced Utility Files..."
check_file_exists "$CLAUDE_DIR/lib/artifact-operations.sh" "plan baselines"
check_file_exists "$CLAUDE_DIR/lib/checkpoint-utils.sh" "plan references"
check_file_exists "$CLAUDE_DIR/lib/complexity-utils.sh" "plan references"
check_file_exists "$CLAUDE_DIR/lib/error-handling.sh" "plan references"

echo ""
echo "Checking Directories..."
if [ -d "$CLAUDE_DIR/lib" ]; then
  echo "✓ PASS: lib/ directory exists"
  ((PASS_COUNT++))
else
  echo "✗ FAIL: lib/ directory NOT FOUND"
  ((FAIL_COUNT++))
fi

if [ -d "$CLAUDE_DIR/commands" ]; then
  echo "✓ PASS: commands/ directory exists"
  ((PASS_COUNT++))
else
  echo "✗ FAIL: commands/ directory NOT FOUND"
  ((FAIL_COUNT++))
fi

if [ -d "$CLAUDE_DIR/agents" ]; then
  echo "✓ PASS: agents/ directory exists"
  ((PASS_COUNT++))
else
  echo "✗ FAIL: agents/ directory NOT FOUND"
  ((FAIL_COUNT++))
fi

if [ -d "$CLAUDE_DIR/utils" ]; then
  echo "✓ PASS: utils/ directory exists"
  ((PASS_COUNT++))
else
  echo "✗ FAIL: utils/ directory NOT FOUND"
  ((FAIL_COUNT++))
fi

if [ -d "$CLAUDE_DIR/data" ]; then
  echo "✓ PASS: data/ directory exists"
  ((PASS_COUNT++))
else
  echo "⚠ INFO: data/ directory not found (may not exist yet)"
  ((PASS_COUNT++))
fi

echo ""
echo "Checking Stage Consistency..."
OVERVIEW_STAGES=$(grep -c "^### Stage [0-9]:" "$PLAN_DIR/phase_7_overview.md" || echo 0)
STAGE_FILES=$(find "$PLAN_DIR" -name "stage_*.md" -type f | wc -l)

if [ "$OVERVIEW_STAGES" -eq "$STAGE_FILES" ]; then
  echo "✓ PASS: Stage count consistent (overview: $OVERVIEW_STAGES, files: $STAGE_FILES)"
  ((PASS_COUNT++))
else
  echo "✗ FAIL: Stage count mismatch (overview: $OVERVIEW_STAGES, files: $STAGE_FILES)"
  ((FAIL_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════"
echo "Results:"
echo "  ✓ PASS: $PASS_COUNT"
echo "  ✗ FAIL: $FAIL_COUNT"
echo "═══════════════════════════════════════"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "All file references are valid!"
  exit 0
else
  echo "Some file references are invalid!"
  exit 1
fi
