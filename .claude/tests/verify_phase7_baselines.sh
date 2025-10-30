#!/usr/bin/env bash
# Verify Phase 7 baseline file sizes and counts

set -e

CLAUDE_DIR="/home/benjamin/.config/.claude"
PASS_COUNT=0
FAIL_COUNT=0

echo "═══════════════════════════════════════"
echo "Phase 7 Baseline Verification"
echo "Date: $(date -I)"
echo "═══════════════════════════════════════"
echo ""

# Helper functions
check_file_lines() {
  local file=$1
  local expected=$2
  local name=$3

  if [ ! -f "$file" ]; then
    echo "✗ FAIL: $name - File not found: $file"
    ((FAIL_COUNT++))
    return 1
  fi

  local actual=$(wc -l < "$file")
  if [ "$actual" -eq "$expected" ]; then
    echo "✓ PASS: $name - $actual lines (matches baseline)"
    ((PASS_COUNT++))
    return 0
  else
    echo "✗ FAIL: $name - $actual lines (expected $expected)"
    ((FAIL_COUNT++))
    return 1
  fi
}

check_file_count() {
  local dir=$1
  local pattern=$2
  local expected=$3
  local name=$4

  if [ ! -d "$dir" ]; then
    echo "✗ FAIL: $name - Directory not found: $dir"
    ((FAIL_COUNT++))
    return 1
  fi

  local actual=$(find "$dir" $pattern | wc -l)
  if [ "$actual" -eq "$expected" ]; then
    echo "✓ PASS: $name - $actual files (matches baseline)"
    ((PASS_COUNT++))
    return 0
  else
    echo "✗ FAIL: $name - $actual files (expected $expected)"
    ((FAIL_COUNT++))
    return 1
  fi
}

check_dir_size() {
  local dir=$1
  local expected_size=$2
  local name=$3

  if [ ! -d "$dir" ]; then
    echo "✗ FAIL: $name - Directory not found: $dir"
    ((FAIL_COUNT++))
    return 1
  fi

  local actual_size=$(du -sh "$dir" | awk '{print $1}')
  if [ "$actual_size" = "$expected_size" ]; then
    echo "✓ PASS: $name - $actual_size (matches baseline)"
    ((PASS_COUNT++))
    return 0
  else
    echo "⚠ INFO: $name - $actual_size (baseline: $expected_size)"
    # Don't fail on size differences, just informational
    ((PASS_COUNT++))
    return 0
  fi
}

echo "Checking Command Files..."
check_file_lines "$CLAUDE_DIR/commands/orchestrate.md" 2720 "orchestrate.md"
check_file_lines "$CLAUDE_DIR/commands/implement.md" 987 "implement.md"
# artifact-operations.sh split into artifact-creation.sh (267 lines) and artifact-registry.sh (410 lines)
check_file_lines "$CLAUDE_DIR/lib/artifact-creation.sh" 267 "artifact-creation.sh"
check_file_lines "$CLAUDE_DIR/lib/artifact-registry.sh" 410 "artifact-registry.sh"

echo ""
echo "Checking Directory Counts..."
check_file_count "$CLAUDE_DIR/lib" "-name '*.sh' -type f" 30 "lib/ script count"
check_file_count "$CLAUDE_DIR/commands" "-type f" 20 "commands/ file count"
check_file_count "$CLAUDE_DIR/agents" "-type f" 22 "agents/ file count"

echo ""
echo "Checking Directory Sizes..."
check_dir_size "$CLAUDE_DIR/lib" "492K" "lib/ size"
check_dir_size "$CLAUDE_DIR/commands" "400K" "commands/ size"
check_dir_size "$CLAUDE_DIR/agents" "296K" "agents/ size"

echo ""
echo "Checking Stage Files..."
check_file_count "$CLAUDE_DIR/specs/plans/045_claude_directory_optimization/phase_7_directory_modularization" "-name 'stage_*.md' -type f" 5 "stage file count"

echo ""
echo "═══════════════════════════════════════"
echo "Results:"
echo "  ✓ PASS: $PASS_COUNT"
echo "  ✗ FAIL: $FAIL_COUNT"
echo "═══════════════════════════════════════"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "All baseline checks passed!"
  exit 0
else
  echo "Some baseline checks failed!"
  exit 1
fi
