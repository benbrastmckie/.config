#!/usr/bin/env bash
# Test shared utility libraries
# Tests: checkpoint-utils, error-handling, complexity-utils, artifact-operations

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}

# Test environment
TEST_DIR=$(mktemp -d -t shared_utils_tests_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Detect actual project directory for sourcing libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTUAL_PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Find lib directory
LIB_DIR="$ACTUAL_PROJECT_DIR/lib"

if [ ! -d "$LIB_DIR" ]; then
  fail "Lib directory not found: $LIB_DIR"
  exit 1
fi

echo "════════════════════════════════════════════════"
echo "Shared Utilities Test Suite"
echo "════════════════════════════════════════════════"
echo ""
echo "Test environment: $TEST_DIR"

# ============================================================================
# Test checkpoint-utils.sh
# ============================================================================

info "Testing checkpoint-utils.sh"

# Source the library
if source "$LIB_DIR/checkpoint-utils.sh" 2>/dev/null; then
  pass "checkpoint-utils.sh sourced successfully"
else
  fail "Failed to source checkpoint-utils.sh"
fi

# Test save_checkpoint
info "Testing save_checkpoint()"
STATE_JSON='{"phase":2,"status":"in_progress"}'
CHECKPOINT_FILE=$(save_checkpoint "test_workflow" "test_project" "$STATE_JSON" 2>/dev/null || echo "")

if [ -n "$CHECKPOINT_FILE" ] && [ -f "$CHECKPOINT_FILE" ]; then
  pass "save_checkpoint() created checkpoint file"
else
  fail "save_checkpoint() failed to create checkpoint"
fi

# Test checkpoint contains correct data
if [ -f "$CHECKPOINT_FILE" ]; then
  if grep -q "test_workflow" "$CHECKPOINT_FILE"; then
    pass "Checkpoint contains workflow type"
  else
    fail "Checkpoint missing workflow type"
  fi

  if grep -q "test_project" "$CHECKPOINT_FILE"; then
    pass "Checkpoint contains project name"
  else
    fail "Checkpoint missing project name"
  fi

  # Check for schema version (v1.2 with replanning fields)
  if command -v jq &>/dev/null; then
    SCHEMA_VERSION=$(jq -r '.schema_version // "unknown"' "$CHECKPOINT_FILE")
    if [ "$SCHEMA_VERSION" = "1.2" ]; then
      pass "Checkpoint schema version is 1.2"
    else
      fail "Checkpoint schema version mismatch" "Expected 1.2, got $SCHEMA_VERSION"
    fi

    # Check replanning fields
    if jq -e '.replanning_count' "$CHECKPOINT_FILE" >/dev/null; then
      pass "Checkpoint has replanning_count field"
    else
      fail "Checkpoint missing replanning_count field"
    fi

    if jq -e '.replan_phase_counts' "$CHECKPOINT_FILE" >/dev/null; then
      pass "Checkpoint has replan_phase_counts field"
    else
      fail "Checkpoint missing replan_phase_counts field"
    fi
  else
    skip "jq not available, skipping JSON validation"
  fi
fi

# Test restore_checkpoint
info "Testing restore_checkpoint()"
RESTORED=$(restore_checkpoint "test_workflow" "test_project" 2>/dev/null || echo "")

if [ -n "$RESTORED" ]; then
  pass "restore_checkpoint() returned data"

  if echo "$RESTORED" | grep -q "test_workflow"; then
    pass "Restored checkpoint contains workflow type"
  else
    fail "Restored checkpoint missing workflow type"
  fi
else
  fail "restore_checkpoint() failed"
fi

# Test checkpoint_increment_replan
if [ -f "$CHECKPOINT_FILE" ] && command -v jq &>/dev/null; then
  info "Testing checkpoint_increment_replan()"

  checkpoint_increment_replan "$CHECKPOINT_FILE" "3" "Test complexity trigger" 2>/dev/null || true

  REPLAN_COUNT=$(jq -r '.replanning_count // 0' "$CHECKPOINT_FILE")
  if [ "$REPLAN_COUNT" -eq 1 ]; then
    pass "checkpoint_increment_replan() incremented counter"
  else
    fail "checkpoint_increment_replan() did not increment" "Expected 1, got $REPLAN_COUNT"
  fi

  PHASE_COUNT=$(jq -r '.replan_phase_counts.phase_3 // 0' "$CHECKPOINT_FILE")
  if [ "$PHASE_COUNT" -eq 1 ]; then
    pass "checkpoint_increment_replan() incremented phase counter"
  else
    fail "Phase counter not incremented" "Expected 1, got $PHASE_COUNT"
  fi
fi

echo ""

# ============================================================================
# Test error-handling.sh
# ============================================================================

info "Testing error-handling.sh"

# Source the library
if source "$LIB_DIR/error-handling.sh" 2>/dev/null; then
  pass "error-handling.sh sourced successfully"
else
  fail "Failed to source error-handling.sh"
fi

# Test classify_error
info "Testing classify_error()"

ERROR_TYPE=$(classify_error "File locked by another process")
if [ "$ERROR_TYPE" = "transient" ]; then
  pass "classify_error() correctly identified transient error"
else
  fail "classify_error() misclassified transient error" "Expected 'transient', got '$ERROR_TYPE'"
fi

ERROR_TYPE=$(classify_error "Syntax error on line 42")
if [ "$ERROR_TYPE" = "permanent" ]; then
  pass "classify_error() correctly identified permanent error"
else
  fail "classify_error() misclassified permanent error" "Expected 'permanent', got '$ERROR_TYPE'"
fi

ERROR_TYPE=$(classify_error "Out of disk space")
if [ "$ERROR_TYPE" = "fatal" ]; then
  pass "classify_error() correctly identified fatal error"
else
  fail "classify_error() misclassified fatal error" "Expected 'fatal', got '$ERROR_TYPE'"
fi

# Test retry_with_backoff
info "Testing retry_with_backoff()"

# Create a command that succeeds on second attempt
ATTEMPT_FILE="$TEST_DIR/attempt_counter"
echo "0" > "$ATTEMPT_FILE"

test_command() {
  ATTEMPT=$(cat "$ATTEMPT_FILE")
  ATTEMPT=$((ATTEMPT + 1))
  echo "$ATTEMPT" > "$ATTEMPT_FILE"

  if [ "$ATTEMPT" -ge 2 ]; then
    return 0
  else
    return 1
  fi
}

export -f test_command
export ATTEMPT_FILE

if retry_with_backoff 3 100 test_command 2>/dev/null; then
  pass "retry_with_backoff() succeeded after retry"

  FINAL_ATTEMPT=$(cat "$ATTEMPT_FILE")
  if [ "$FINAL_ATTEMPT" -eq 2 ]; then
    pass "retry_with_backoff() attempted correct number of times"
  else
    fail "Unexpected retry count" "Expected 2, got $FINAL_ATTEMPT"
  fi
else
  fail "retry_with_backoff() failed unexpectedly"
fi

# Test log_error_context
info "Testing log_error_context()"

LOG_FILE=$(log_error_context "test_error" "test.lua:42" "Test error message" '{"context":"test"}')

if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
  pass "log_error_context() created log file"

  if grep -q "test_error" "$LOG_FILE"; then
    pass "Log file contains error type"
  else
    fail "Log file missing error type"
  fi
else
  fail "log_error_context() failed to create log"
fi

echo ""

# ============================================================================
# Test complexity-utils.sh
# ============================================================================

info "Testing complexity-utils.sh"

# Source the library
if source "$LIB_DIR/complexity-utils.sh" 2>/dev/null; then
  pass "complexity-utils.sh sourced successfully"
else
  fail "Failed to source complexity-utils.sh"
fi

# Test calculate_phase_complexity
info "Testing calculate_phase_complexity()"

TASK_LIST="$(cat <<'EOF'
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
EOF
)"

SCORE=$(calculate_phase_complexity "Refactor Architecture" "$TASK_LIST")

if [ -n "$SCORE" ] && [ "$SCORE" -ge 0 ]; then
  pass "calculate_phase_complexity() returned score: $SCORE"

  # Refactor should have high complexity
  if [ "$SCORE" -ge 3 ]; then
    pass "Refactor phase has appropriate complexity score"
  else
    fail "Complexity score too low for refactor" "Expected ≥3, got $SCORE"
  fi
else
  fail "calculate_phase_complexity() returned invalid score"
fi

# Test detect_complexity_triggers
info "Testing detect_complexity_triggers()"

TRIGGER=$(detect_complexity_triggers 9 12)
if [ "$TRIGGER" = "true" ]; then
  pass "detect_complexity_triggers() detected high complexity"
else
  fail "detect_complexity_triggers() missed trigger" "Expected 'true', got '$TRIGGER'"
fi

TRIGGER=$(detect_complexity_triggers 5 7 || true)
if [ "$TRIGGER" = "false" ]; then
  pass "detect_complexity_triggers() correctly rejected low complexity"
else
  fail "detect_complexity_triggers() false positive" "Expected 'false', got '$TRIGGER'"
fi

# Test generate_complexity_report
info "Testing generate_complexity_report()"

if command -v jq &>/dev/null; then
  REPORT=$(generate_complexity_report "Test Phase" "$TASK_LIST")

  if echo "$REPORT" | jq -e '.complexity_score' >/dev/null 2>&1; then
    pass "generate_complexity_report() produced valid JSON"

    if echo "$REPORT" | jq -e '.trigger_detected' >/dev/null 2>&1; then
      pass "Report contains trigger_detected field"
    else
      fail "Report missing trigger_detected field"
    fi
  else
    fail "generate_complexity_report() produced invalid JSON"
  fi
else
  skip "jq not available, skipping JSON validation"
fi

echo ""

# ============================================================================
# Test artifact-operations.sh
# ============================================================================

info "Testing artifact-operations.sh"

# Source the library
if source "$LIB_DIR/artifact-operations.sh" 2>/dev/null; then
  pass "artifact-operations.sh sourced successfully"
else
  fail "Failed to source artifact-operations.sh"
fi

# Test register_artifact
info "Testing register_artifact()"

# Create a test artifact file
TEST_ARTIFACT="$TEST_DIR/test_plan.md"
echo "# Test Plan" > "$TEST_ARTIFACT"

ARTIFACT_ID=$(register_artifact "plan" "test_plan.md" '{"status":"test"}' 2>/dev/null || echo "")

if [ -n "$ARTIFACT_ID" ]; then
  pass "register_artifact() returned artifact ID: $ARTIFACT_ID"

  # Check registry file exists
  REGISTRY_DIR="$TEST_DIR/.claude/data/registry"
  if [ -d "$REGISTRY_DIR" ]; then
    pass "Registry directory created"

    ENTRY_FILE="$REGISTRY_DIR/${ARTIFACT_ID}.json"
    if [ -f "$ENTRY_FILE" ]; then
      pass "Registry entry file created"

      if command -v jq &>/dev/null; then
        ARTIFACT_TYPE=$(jq -r '.artifact_type' "$ENTRY_FILE")
        if [ "$ARTIFACT_TYPE" = "plan" ]; then
          pass "Registry entry has correct artifact type"
        else
          fail "Wrong artifact type" "Expected 'plan', got '$ARTIFACT_TYPE'"
        fi
      fi
    else
      fail "Registry entry file not found"
    fi
  else
    fail "Registry directory not created"
  fi
else
  fail "register_artifact() failed to return ID"
fi

# Test query_artifacts
info "Testing query_artifacts()"

if command -v jq &>/dev/null; then
  ARTIFACTS=$(query_artifacts "plan" 2>/dev/null || echo "[]")

  if echo "$ARTIFACTS" | jq -e '.[]' >/dev/null 2>&1; then
    pass "query_artifacts() found registered artifacts"

    COUNT=$(echo "$ARTIFACTS" | jq 'length')
    if [ "$COUNT" -ge 1 ]; then
      pass "Query returned expected artifact count: $COUNT"
    else
      fail "No artifacts found in query"
    fi
  else
    fail "query_artifacts() returned empty or invalid JSON"
  fi
else
  skip "jq not available, skipping query test"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

echo "════════════════════════════════════════════════"
echo "Test Results"
echo "════════════════════════════════════════════════"
echo -e "${GREEN}Passed:  $PASS_COUNT${NC}"
echo -e "${RED}Failed:  $FAIL_COUNT${NC}"
echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
echo "════════════════════════════════════════════════"

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
  exit 0
else
  echo -e "${RED}✗ SOME TESTS FAILED${NC}"
  exit 1
fi
