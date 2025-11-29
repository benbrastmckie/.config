#!/usr/bin/env bash
# Integration test for /expand and /collapse hard barrier pattern

set -euo pipefail

# Bootstrap project directory detection
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source test helpers
source "${CLAUDE_PROJECT_DIR}/.claude/tests/lib/test-helpers.sh"

# Test metadata
TEST_NAME="expand_collapse_hard_barriers"
TEST_DESC="Verify /expand and /collapse enforce plan-architect delegation via hard barriers"

# Initialize test counters
setup_test

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

cd "$TEST_DIR"

# ============================================================================
# TEST 1: Verify /expand has hard barrier pattern for phase expansion
# ============================================================================

echo "TEST: Verify /expand phase has 3-block pattern (Setup → Execute → Verify)"

# Check expand.md for Block 3a, 3b, 3c pattern
EXPAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/expand.md"

# Verify Block 3a: Setup
if ! grep -q "^**Block 3a: Complexity Detection Setup**" "$EXPAND_FILE"; then
  fail "Missing Block 3a (Setup) in /expand phase expansion"
fi

# Verify Block 3b: Execute with CRITICAL BARRIER
if ! grep -q "^**Block 3b: Phase Expansion Execution \[CRITICAL BARRIER\]**" "$EXPAND_FILE"; then
  fail "Missing Block 3b (Execute) CRITICAL BARRIER label in /expand phase expansion"
fi

# Verify Block 3c: Verify
if ! grep -q "^**Block 3c: Phase File Verification**" "$EXPAND_FILE"; then
  fail "Missing Block 3c (Verification) in /expand phase expansion"
fi

# Verify verification block checks file existence
if ! grep -q "if \[\[ ! -f \"\$PHASE_FILE\" \]\]" "$EXPAND_FILE"; then
  fail "Missing file existence check in /expand phase verification block"
fi

# Verify verification block checks file size
if ! grep -q "file_size.*wc -c.*PHASE_FILE" "$EXPAND_FILE"; then
  fail "Missing file size check in /expand phase verification block"
fi

# Verify error logging in verification block
if ! grep -q "log_command_error \"verification_error\"" "$EXPAND_FILE"; then
  fail "Missing error logging in /expand phase verification block"
fi

pass "✓ /expand phase has complete hard barrier pattern (3a/3b/3c)"

# ============================================================================
# TEST 2: Verify /expand has hard barrier pattern for stage expansion
# ============================================================================

echo "TEST: Verify /expand stage has 3-block pattern (Setup → Execute → Verify)"

# Verify Block 3a for stage: Setup
if ! grep -q "^**Block 3a: Stage Complexity Detection Setup**" "$EXPAND_FILE"; then
  fail "Missing Block 3a (Setup) in /expand stage expansion"
fi

# Verify Block 3b for stage: Execute with CRITICAL BARRIER
if ! grep -q "^**Block 3b: Stage Expansion Execution \[CRITICAL BARRIER\]**" "$EXPAND_FILE"; then
  fail "Missing Block 3b (Execute) CRITICAL BARRIER label in /expand stage expansion"
fi

# Verify Block 3c for stage: Verify
if ! grep -q "^**Block 3c: Stage File Verification**" "$EXPAND_FILE"; then
  fail "Missing Block 3c (Verification) in /expand stage expansion"
fi

pass "✓ /expand stage has complete hard barrier pattern (3a/3b/3c)"

# ============================================================================
# TEST 3: Verify /collapse has hard barrier pattern for phase collapse
# ============================================================================

echo "TEST: Verify /collapse phase has 3-block pattern (Setup → Execute → Verify)"

COLLAPSE_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/collapse.md"

# Verify Block 4a: Merge Setup
if ! grep -q "^#### Block 4a: Merge Setup$" "$COLLAPSE_FILE"; then
  fail "Missing Block 4a (Setup) in /collapse phase collapse"
fi

# Verify Block 4b: Execute with CRITICAL BARRIER
if ! grep -q "^#### Block 4b: Phase Collapse Execution \[CRITICAL BARRIER\]$" "$COLLAPSE_FILE"; then
  fail "Missing Block 4b (Execute) CRITICAL BARRIER label in /collapse phase collapse"
fi

# Verify Block 4c: Merge Verification
if ! grep -q "^#### Block 4c: Merge Verification$" "$COLLAPSE_FILE"; then
  fail "Missing Block 4c (Verification) in /collapse phase collapse"
fi

# Verify verification block checks merge occurred
if ! grep -q "if ! grep -q \"### Phase \${PHASE_NUM}:\" \"\$MERGE_TARGET\"" "$COLLAPSE_FILE"; then
  fail "Missing merge verification check in /collapse phase verification block"
fi

# Verify error logging in verification block
if ! grep -q "log_command_error \"verification_error\"" "$COLLAPSE_FILE"; then
  fail "Missing error logging in /collapse phase verification block"
fi

pass "✓ /collapse phase has complete hard barrier pattern (4a/4b/4c)"

# ============================================================================
# TEST 4: Verify /collapse has hard barrier pattern for stage collapse
# ============================================================================

echo "TEST: Verify /collapse stage has 3-block pattern (Setup → Execute → Verify)"

# Verify STEP 4a for stage: Setup
if ! grep -q "^#### STEP 4a: Stage Merge Setup$" "$COLLAPSE_FILE"; then
  fail "Missing STEP 4a (Setup) in /collapse stage collapse"
fi

# Verify STEP 4b for stage: Execute with CRITICAL BARRIER
if ! grep -q "^#### STEP 4b: Stage Collapse Execution \[CRITICAL BARRIER\]$" "$COLLAPSE_FILE"; then
  fail "Missing STEP 4b (Execute) CRITICAL BARRIER label in /collapse stage collapse"
fi

# Verify STEP 4c for stage: Verify
if ! grep -q "^#### STEP 4c: Stage Merge Verification$" "$COLLAPSE_FILE"; then
  fail "Missing STEP 4c (Verification) in /collapse stage collapse"
fi

pass "✓ /collapse stage has complete hard barrier pattern (4a/4b/4c)"

# ============================================================================
# TEST 5: Verify metadata documentation of tool restriction decision
# ============================================================================

echo "TEST: Verify both commands document tool usage restrictions"

# Check /expand metadata
if ! grep -q "^tool-usage-note:.*plan-architect performs all content generation" "$EXPAND_FILE"; then
  fail "Missing tool-usage-note in /expand metadata"
fi

# Check /collapse metadata
if ! grep -q "^tool-usage-note:.*plan-architect performs all content merging" "$COLLAPSE_FILE"; then
  fail "Missing tool-usage-note in /collapse metadata"
fi

pass "✓ Both commands document tool usage restrictions in metadata"

# ============================================================================
# TEST SUMMARY
# ============================================================================

teardown_test
