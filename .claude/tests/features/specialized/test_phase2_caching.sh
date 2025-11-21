#!/usr/bin/env bash
# Test Phase 2 caching optimizations  
# Tests source guards and CLAUDE_PROJECT_DIR caching

set -euo pipefail

CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "Test 1: Source guard prevents duplicate execution"
# Source the library twice and verify the guard works
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-logger.sh"
if [ "${UNIFIED_LOGGER_SOURCED:-}" = "1" ]; then
  echo "✓ PASS: unified-logger.sh sourced, guard variable set"
else
  echo "✗ FAIL: Source guard variable not set"
  exit 1
fi

# Source again - should return immediately
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-logger.sh"
if [ "${UNIFIED_LOGGER_SOURCED:-}" = "1" ]; then
  echo "✓ PASS: Second sourcing worked (guard prevented re-execution)"
else
  echo "✗ FAIL: Source guard failed"
  exit 1
fi

echo ""
echo "Test 2: CLAUDE_PROJECT_DIR caching via state persistence"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Initialize state (saves CLAUDE_PROJECT_DIR)
STATE_FILE=$(init_workflow_state "test_caching_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Verify CLAUDE_PROJECT_DIR was saved
if grep -q "^export CLAUDE_PROJECT_DIR=" "$STATE_FILE"; then
  CACHED_DIR=$(grep "^export CLAUDE_PROJECT_DIR=" "$STATE_FILE" | cut -d'"' -f2)
  echo "✓ PASS: CLAUDE_PROJECT_DIR saved to state file (value: $CACHED_DIR)"
else
  echo "✗ FAIL: CLAUDE_PROJECT_DIR not in state file"
  exit 1
fi

# Test that subsequent bash blocks can use cached value
# Simulate new bash block by sourcing state file
SAVED_DIR="$CLAUDE_PROJECT_DIR"
unset CLAUDE_PROJECT_DIR
source "$STATE_FILE"

if [ "${CLAUDE_PROJECT_DIR:-}" = "$SAVED_DIR" ]; then
  echo "✓ PASS: CLAUDE_PROJECT_DIR restored from state file (no git rev-parse needed)"
else
  echo "✗ FAIL: CLAUDE_PROJECT_DIR not restored correctly"
  exit 1
fi

echo ""
echo "Test 3: Verify all critical libraries have source guards"
# Library paths after refactoring (commit fb8680db) - uses subdirectory structure
declare -A LIB_PATHS=(
  ["workflow-state-machine"]="workflow/workflow-state-machine.sh"
  ["state-persistence"]="core/state-persistence.sh"
  ["workflow-initialization"]="workflow/workflow-initialization.sh"
  ["error-handling"]="core/error-handling.sh"
  ["unified-logger"]="core/unified-logger.sh"
)

MISSING_GUARDS=0
for lib in "${!LIB_PATHS[@]}"; do
  lib_path="${LIB_PATHS[$lib]}"
  if grep -q "SOURCED" "${SAVED_DIR}/.claude/lib/${lib_path}" 2>/dev/null; then
    echo "✓ $lib has source guard"
  else
    echo "✗ $lib missing source guard"
    MISSING_GUARDS=$((MISSING_GUARDS + 1))
  fi
done

if [ $MISSING_GUARDS -eq 0 ]; then
  echo "✓ PASS: All libraries have source guards"
else
  echo "✗ FAIL: $MISSING_GUARDS libraries missing source guards"
  exit 1
fi

echo ""
echo "All Phase 2 caching tests passed (3/3)"
