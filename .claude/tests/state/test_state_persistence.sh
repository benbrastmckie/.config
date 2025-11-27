#!/usr/bin/env bash
# test_state_persistence.sh - Test suite for state-persistence.sh library
#
# Tests the GitHub Actions-style state persistence implementation including:
# - init_workflow_state() - State file initialization
# - load_workflow_state() - State file loading with fallback
# - append_workflow_state() - GitHub Actions $GITHUB_OUTPUT pattern
# - save_json_checkpoint() - Atomic JSON checkpoint saves
# - load_json_checkpoint() - JSON checkpoint loading with validation
# - append_jsonl_log() - JSONL benchmark logging
# - Performance characteristics (file-based vs recalculation)
# - Graceful degradation (missing state file handling)
# - EXIT trap cleanup (state file removal)
#
# Expected: 18+ tests passing

# Don't use -e flag - we want to continue even if tests fail
set -uo pipefail

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
pass() {
  ((TESTS_PASSED++))
  echo -e "${GREEN}✓${NC} $1"
}

fail() {
  ((TESTS_FAILED++))
  echo -e "${RED}✗${NC} $1"
  if [ -n "${2:-}" ]; then
    echo "  Error: $2"
  fi
}

section() {
  echo ""
  echo -e "${YELLOW}=== $1 ===${NC}"
}

# Setup
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
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source the library under test
source "${CLAUDE_LIB}/core/state-persistence.sh"

# Test 1: init_workflow_state creates state file
section "Test 1: init_workflow_state creates state file"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_init_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

if [ -f "$STATE_FILE" ]; then
  pass "State file created at $STATE_FILE"
  rm -f "$STATE_FILE"
else
  fail "State file NOT created" "Expected: $STATE_FILE"
fi

# Test 2: State file contains CLAUDE_PROJECT_DIR
section "Test 2: State file contains CLAUDE_PROJECT_DIR"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_claude_dir_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

if grep -q "export CLAUDE_PROJECT_DIR=" "$STATE_FILE"; then
  pass "State file contains CLAUDE_PROJECT_DIR"
  rm -f "$STATE_FILE"
else
  fail "State file missing CLAUDE_PROJECT_DIR" "Content: $(cat $STATE_FILE)"
fi

# Test 3: State file contains WORKFLOW_ID
section "Test 3: State file contains WORKFLOW_ID"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_workflow_id_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

if grep -q "export WORKFLOW_ID=\"$TEST_WORKFLOW_ID\"" "$STATE_FILE"; then
  pass "State file contains WORKFLOW_ID"
  rm -f "$STATE_FILE"
else
  fail "State file missing WORKFLOW_ID" "Expected: $TEST_WORKFLOW_ID"
fi

# Test 4: load_workflow_state restores variables
section "Test 4: load_workflow_state restores variables"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_load_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

# Clear the variable
unset WORKFLOW_ID

# Load state
load_workflow_state "$TEST_WORKFLOW_ID" >/dev/null 2>&1

if [ "${WORKFLOW_ID:-}" == "$TEST_WORKFLOW_ID" ]; then
  pass "load_workflow_state restored WORKFLOW_ID"
  rm -f "$STATE_FILE"
else
  fail "load_workflow_state did NOT restore WORKFLOW_ID" "Got: ${WORKFLOW_ID:-empty}"
fi

# Test 5: load_workflow_state fallback (missing file, first block)
section "Test 5: load_workflow_state graceful degradation"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_fallback_$$"
NONEXISTENT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${TEST_WORKFLOW_ID}.sh"

# Ensure file doesn't exist
rm -f "$NONEXISTENT_FILE"

# Load state with is_first_block=true - should return 1 but create fallback file
if load_workflow_state "$TEST_WORKFLOW_ID" "true" >/dev/null 2>&1; then
  fail "load_workflow_state should return 1 for missing file"
else
  if [ -f "$NONEXISTENT_FILE" ]; then
    pass "load_workflow_state gracefully degraded (created fallback)"
    rm -f "$NONEXISTENT_FILE"
  else
    fail "load_workflow_state didn't create fallback file"
  fi
fi

# Test 6: append_workflow_state adds to state file
section "Test 6: append_workflow_state adds variables"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_append_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

append_workflow_state "RESEARCH_COMPLETE" "true"

if grep -q 'export RESEARCH_COMPLETE="true"' "$STATE_FILE"; then
  pass "append_workflow_state added RESEARCH_COMPLETE"
  rm -f "$STATE_FILE"
else
  fail "append_workflow_state did NOT add variable" "Content: $(cat $STATE_FILE)"
fi

# Test 7: append_workflow_state with multiple values
section "Test 7: append_workflow_state accumulates state"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_append_multi_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

append_workflow_state "PHASE_1_DONE" "true"
append_workflow_state "PHASE_2_DONE" "true"
append_workflow_state "REPORTS_CREATED" "4"

PHASE_1_COUNT=$(grep -c 'export PHASE_1_DONE="true"' "$STATE_FILE")
PHASE_2_COUNT=$(grep -c 'export PHASE_2_DONE="true"' "$STATE_FILE")
REPORTS_COUNT=$(grep -c 'export REPORTS_CREATED="4"' "$STATE_FILE")

if [ "$PHASE_1_COUNT" -eq 1 ] && [ "$PHASE_2_COUNT" -eq 1 ] && [ "$REPORTS_COUNT" -eq 1 ]; then
  pass "append_workflow_state accumulated 3 variables"
  rm -f "$STATE_FILE"
else
  fail "append_workflow_state accumulation failed" "Counts: P1=$PHASE_1_COUNT, P2=$PHASE_2_COUNT, R=$REPORTS_COUNT"
fi

# Test 8: save_json_checkpoint creates file
section "Test 8: save_json_checkpoint creates checkpoint"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_json_save_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

TEST_JSON='{"topics": 4, "reports": ["r1.md", "r2.md"]}'
save_json_checkpoint "test_checkpoint" "$TEST_JSON"

CHECKPOINT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_checkpoint.json"
if [ -f "$CHECKPOINT_FILE" ]; then
  pass "save_json_checkpoint created checkpoint file"
  rm -f "$CHECKPOINT_FILE"
  rm -f "$STATE_FILE"
else
  fail "save_json_checkpoint did NOT create file" "Expected: $CHECKPOINT_FILE"
fi

# Test 9: save_json_checkpoint atomic write
section "Test 9: save_json_checkpoint uses atomic write"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_atomic_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

TEST_JSON='{"test": "atomic"}'
save_json_checkpoint "test_atomic" "$TEST_JSON"

CHECKPOINT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_atomic.json"
# Check no .tmp files left behind (atomic write cleanup)
TEMP_FILES=$(find "${CLAUDE_PROJECT_DIR}/.claude/tmp" -name "test_atomic.json.*" 2>/dev/null | wc -l)

if [ "$TEMP_FILES" -eq 0 ]; then
  pass "save_json_checkpoint cleaned up temp files (atomic write)"
  rm -f "$CHECKPOINT_FILE"
  rm -f "$STATE_FILE"
else
  fail "save_json_checkpoint left temp files" "Count: $TEMP_FILES"
fi

# Test 10: load_json_checkpoint reads saved data
section "Test 10: load_json_checkpoint reads checkpoint"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_json_load_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

TEST_JSON='{"key": "value", "number": 42}'
save_json_checkpoint "test_load" "$TEST_JSON"

LOADED_JSON=$(load_json_checkpoint "test_load")

if [ "$LOADED_JSON" == "$TEST_JSON" ]; then
  pass "load_json_checkpoint read correct data"
  rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/test_load.json"
  rm -f "$STATE_FILE"
else
  fail "load_json_checkpoint returned wrong data" "Expected: $TEST_JSON, Got: $LOADED_JSON"
fi

# Test 11: load_json_checkpoint missing file returns {}
section "Test 11: load_json_checkpoint graceful degradation"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_json_missing_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

LOADED_JSON=$(load_json_checkpoint "nonexistent_checkpoint")

if [ "$LOADED_JSON" == "{}" ]; then
  pass "load_json_checkpoint returned {} for missing file"
  rm -f "$STATE_FILE"
else
  fail "load_json_checkpoint should return {}" "Got: $LOADED_JSON"
fi

# Test 12: append_jsonl_log creates JSONL file
section "Test 12: append_jsonl_log creates log file"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_jsonl_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

LOG_ENTRY='{"phase": "research", "duration_ms": 12500}'
append_jsonl_log "test_log" "$LOG_ENTRY"

LOG_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_log.jsonl"
if [ -f "$LOG_FILE" ]; then
  pass "append_jsonl_log created log file"
  rm -f "$LOG_FILE"
  rm -f "$STATE_FILE"
else
  fail "append_jsonl_log did NOT create file" "Expected: $LOG_FILE"
fi

# Test 13: append_jsonl_log appends multiple entries
section "Test 13: append_jsonl_log accumulates entries"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_jsonl_multi_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

append_jsonl_log "test_multi" '{"phase": "research", "duration": 100}'
append_jsonl_log "test_multi" '{"phase": "plan", "duration": 200}'
append_jsonl_log "test_multi" '{"phase": "implement", "duration": 300}'

LOG_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_multi.jsonl"
LINE_COUNT=$(wc -l < "$LOG_FILE")

if [ "$LINE_COUNT" -eq 3 ]; then
  pass "append_jsonl_log accumulated 3 entries"
  rm -f "$LOG_FILE"
  rm -f "$STATE_FILE"
else
  fail "append_jsonl_log wrong entry count" "Expected: 3, Got: $LINE_COUNT"
fi

# Test 14: State file survives subprocess boundary
section "Test 14: State persists across subprocess boundaries"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_subprocess_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")
append_workflow_state "SUBPROCESS_TEST" "initial"

# Simulate subprocess (new bash invocation) with CLAUDE_PROJECT_DIR exported
RESULT=$(CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR" bash -c "
  source '${CLAUDE_LIB}/core/state-persistence.sh'
  load_workflow_state '$TEST_WORKFLOW_ID' >/dev/null 2>&1
  echo \"\${SUBPROCESS_TEST:-missing}\"
")

if [ "$RESULT" == "initial" ]; then
  pass "State persisted across subprocess boundary"
  rm -f "$STATE_FILE"
else
  fail "State did NOT persist across subprocess" "Got: $RESULT"
fi

# Test 15: Multiple workflows don't interfere
section "Test 15: Multiple workflows isolated"
((TESTS_RUN++))
WORKFLOW_A="test_a_$$"
WORKFLOW_B="test_b_$$"

STATE_A=$(init_workflow_state "$WORKFLOW_A")
STATE_B=$(init_workflow_state "$WORKFLOW_B")

append_workflow_state "WORKFLOW" "A"
STATE_FILE="$STATE_A"  # Restore STATE_FILE for workflow A
append_workflow_state "WORKFLOW" "A"

STATE_FILE="$STATE_B"  # Switch to workflow B
append_workflow_state "WORKFLOW" "B"

# Verify isolation
load_workflow_state "$WORKFLOW_A" >/dev/null 2>&1
WORKFLOW_A_VAL="${WORKFLOW:-missing}"

load_workflow_state "$WORKFLOW_B" >/dev/null 2>&1
WORKFLOW_B_VAL="${WORKFLOW:-missing}"

if [ "$WORKFLOW_A_VAL" == "A" ] && [ "$WORKFLOW_B_VAL" == "B" ]; then
  pass "Multiple workflows properly isolated"
  rm -f "$STATE_A" "$STATE_B"
else
  fail "Workflow isolation failed" "A: $WORKFLOW_A_VAL, B: $WORKFLOW_B_VAL"
fi

# Test 16: Error handling - append without init
section "Test 16: Error handling - append without init"
((TESTS_RUN++))
unset STATE_FILE

if append_workflow_state "TEST" "value" 2>/dev/null; then
  fail "append_workflow_state should error without init"
else
  pass "append_workflow_state correctly errors without STATE_FILE"
fi

# Re-initialize for remaining tests
STATE_FILE=$(init_workflow_state "cleanup_$$")

# Test 17: Error handling - save_json_checkpoint without CLAUDE_PROJECT_DIR
section "Test 17: Error handling - checkpoint without init"
((TESTS_RUN++))
(
  unset CLAUDE_PROJECT_DIR
  if save_json_checkpoint "test" '{}' 2>/dev/null; then
    echo "fail"
  else
    echo "pass"
  fi
) | grep -q "pass" && pass "save_json_checkpoint correctly errors without init" || fail "save_json_checkpoint should error without CLAUDE_PROJECT_DIR"

# Test 18: Performance - state file faster than recalculation (caching benefit)
section "Test 18: Performance - state file provides caching benefit"
((TESTS_RUN++))
TEST_WORKFLOW_ID="test_perf_$$"

# Measure init (includes git rev-parse)
START_INIT=$(date +%s%N)
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")
END_INIT=$(date +%s%N)
INIT_TIME=$(( (END_INIT - START_INIT) / 1000000 ))

# Measure load (file read only)
START_LOAD=$(date +%s%N)
load_workflow_state "$TEST_WORKFLOW_ID" >/dev/null 2>&1
END_LOAD=$(date +%s%N)
LOAD_TIME=$(( (END_LOAD - START_LOAD) / 1000000 ))

# Load should be faster than init (file read vs git command)
if [ "$LOAD_TIME" -le "$INIT_TIME" ]; then
  SAVINGS=$(( INIT_TIME - LOAD_TIME ))
  pass "State file provides caching (init: ${INIT_TIME}ms, load: ${LOAD_TIME}ms, savings: ${SAVINGS}ms)"
  rm -f "$STATE_FILE"
else
  # Allow for measurement variance
  DIFF=$(( LOAD_TIME - INIT_TIME ))
  if [ "$DIFF" -lt 5 ]; then
    pass "State file performance acceptable (variance within 5ms)"
    rm -f "$STATE_FILE"
  else
    fail "State file slower than init" "Init: ${INIT_TIME}ms, Load: ${LOAD_TIME}ms"
  fi
fi

# Summary
section "Test Summary"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
  echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
