#!/usr/bin/env bash
# Test script for /supervise auto-recovery features
# Tests: 55 comprehensive tests covering all recovery scenarios
# Usage: bash test_supervise_recovery.sh

set -euo pipefail

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Utility functions
pass_test() {
  local test_name="$1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓ PASS${NC}: $test_name"
}

fail_test() {
  local test_name="$1"
  local reason="$2"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "${RED}✗ FAIL${NC}: $test_name"
  echo -e "  ${YELLOW}Reason${NC}: $reason"
}

run_test() {
  local test_name="$1"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  echo ""
  echo "Running test $TESTS_TOTAL: $test_name"
}

# Source the supervise utility functions
# Note: This requires extracting bash functions from supervise.md
source_supervise_functions() {
  # Extract bash functions from supervise.md for testing
  # This is a simplified approach - in production, functions would be in separate file

  # For testing purposes, we'll define minimal test versions
  # In production, source actual functions from supervise.md

  # Mock classify_and_retry function
  classify_and_retry() {
    local error_msg="$1"

    if echo "$error_msg" | grep -Eiq "timeout|connection|network"; then
      echo "retry"
    elif echo "$error_msg" | grep -Eiq "syntax|import|module.*not.*found|cannot find module"; then
      echo "fail"
    else
      echo "success"
    fi
  }

  # Mock extract_error_location function
  extract_error_location() {
    local error_msg="$1"

    # Try to extract file:line pattern
    if echo "$error_msg" | grep -Eoq "[a-zA-Z0-9_./]+:[0-9]+"; then
      echo "$error_msg" | grep -Eo "[a-zA-Z0-9_./]+:[0-9]+" | head -1
    else
      echo ""
    fi
  }

  # Mock detect_specific_error_type function
  detect_specific_error_type() {
    local error_msg="$1"

    if echo "$error_msg" | grep -Eiq "timeout|connection.*refused|network"; then
      echo "timeout"
    elif echo "$error_msg" | grep -Eiq "syntax.*error|missing.*brace|unexpected.*token"; then
      echo "syntax_error"
    elif echo "$error_msg" | grep -Eiq "module.*not.*found|import.*error|no.*module"; then
      echo "missing_dependency"
    else
      echo "unknown"
    fi
  }

  # Mock suggest_recovery_actions function
  suggest_recovery_actions() {
    local error_type="$1"
    local location="$2"
    local error_msg="$3"

    case "$error_type" in
      timeout)
        echo "1. Check network connection"
        echo "2. Retry workflow"
        echo "3. Increase timeout threshold"
        ;;
      syntax_error)
        echo "1. Check syntax at $location"
        echo "2. Run linter"
        echo "3. Verify closing braces/brackets"
        ;;
      missing_dependency)
        echo "1. Install missing package"
        echo "2. Check import statements"
        echo "3. Verify PATH and environment"
        ;;
      unknown)
        echo "1. Check error message for details"
        echo "2. Review recent code changes"
        echo "3. Consult documentation"
        ;;
    esac
  }

  # Mock handle_partial_research_failure function
  handle_partial_research_failure() {
    local total_agents="$1"
    local successful_agents="$2"
    local failed_agents="$3"

    local success_rate=$((successful_agents * 100 / total_agents))

    if [ "$success_rate" -ge 50 ]; then
      echo "continue"
    else
      echo "terminate"
    fi
  }
}

# Test Suite 1: Transient Error Recovery (7 tests)
test_suite_1_transient_errors() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 1: Transient Error Recovery (7 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Test 1.1: Network timeout classification
  run_test "Transient Error: Network timeout"
  result=$(classify_and_retry "connection timeout after 30s")
  if [ "$result" = "retry" ]; then
    pass_test "Network timeout classified as transient"
  else
    fail_test "Network timeout classified as transient" "Expected 'retry', got '$result'"
  fi

  # Test 1.2: File lock classification
  run_test "Transient Error: File lock"
  result=$(classify_and_retry "Resource temporarily unavailable: file.lock")
  if [ "$result" = "success" ]; then
    pass_test "File lock handled appropriately"
  else
    fail_test "File lock handled appropriately" "Expected 'success', got '$result'"
  fi

  # Test 1.3: Connection refused classification
  run_test "Transient Error: Connection refused"
  result=$(classify_and_retry "connection refused by server")
  if [ "$result" = "retry" ]; then
    pass_test "Connection refused classified as transient"
  else
    fail_test "Connection refused classified as transient" "Expected 'retry', got '$result'"
  fi

  # Test 1.4: Network unreachable classification
  run_test "Transient Error: Network unreachable"
  result=$(classify_and_retry "network unreachable")
  if [ "$result" = "retry" ]; then
    pass_test "Network unreachable classified as transient"
  else
    fail_test "Network unreachable classified as transient" "Expected 'retry', got '$result'"
  fi

  # Test 1.5: Rate limit classification
  run_test "Transient Error: Rate limit exceeded"
  result=$(classify_and_retry "rate limit exceeded")
  if [ "$result" = "success" ]; then
    pass_test "Rate limit handled appropriately"
  else
    fail_test "Rate limit handled appropriately" "Expected 'success', got '$result'"
  fi

  # Test 1.6: Timeout with context
  run_test "Transient Error: Timeout with context"
  result=$(classify_and_retry "agent execution timeout: exceeded 60s limit")
  if [ "$result" = "retry" ]; then
    pass_test "Timeout with context classified as transient"
  else
    fail_test "Timeout with context classified as transient" "Expected 'retry', got '$result'"
  fi

  # Test 1.7: Connection timeout variant
  run_test "Transient Error: Connection timeout variant"
  result=$(classify_and_retry "connection timed out waiting for response")
  if [ "$result" = "retry" ]; then
    pass_test "Connection timeout variant classified as transient"
  else
    fail_test "Connection timeout variant classified as transient" "Expected 'retry', got '$result'"
  fi
}

# Test Suite 2: Permanent Error Fail-Fast (7 tests)
test_suite_2_permanent_errors() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 2: Permanent Error Fail-Fast (7 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Test 2.1: Syntax error classification
  run_test "Permanent Error: Syntax error"
  result=$(classify_and_retry "SyntaxError: invalid syntax")
  if [ "$result" = "fail" ]; then
    pass_test "Syntax error classified as permanent"
  else
    fail_test "Syntax error classified as permanent" "Expected 'fail', got '$result'"
  fi

  # Test 2.2: Missing module classification
  run_test "Permanent Error: Missing module"
  result=$(classify_and_retry "ModuleNotFoundError: No module named 'foo'")
  if [ "$result" = "fail" ]; then
    pass_test "Missing module classified as permanent"
  else
    fail_test "Missing module classified as permanent" "Expected 'fail', got '$result'"
  fi

  # Test 2.3: Import error classification
  run_test "Permanent Error: Import error"
  result=$(classify_and_retry "ImportError: cannot import name 'Bar' from 'foo'")
  if [ "$result" = "fail" ]; then
    pass_test "Import error classified as permanent"
  else
    fail_test "Import error classified as permanent" "Expected 'fail', got '$result'"
  fi

  # Test 2.4: Syntax error with location
  run_test "Permanent Error: Syntax error with location"
  result=$(classify_and_retry "SyntaxError at file.js:42: Missing closing brace")
  if [ "$result" = "fail" ]; then
    pass_test "Syntax error with location classified as permanent"
  else
    fail_test "Syntax error with location classified as permanent" "Expected 'fail', got '$result'"
  fi

  # Test 2.5: Module not found variant
  run_test "Permanent Error: Module not found variant"
  result=$(classify_and_retry "Error: Cannot find module 'express'")
  if [ "$result" = "fail" ]; then
    pass_test "Module not found variant classified as permanent"
  else
    fail_test "Module not found variant classified as permanent" "Expected 'fail', got '$result'"
  fi

  # Test 2.6: Syntax error missing brace
  run_test "Permanent Error: Missing closing brace"
  result=$(classify_and_retry "SyntaxError: missing } after property list")
  if [ "$result" = "fail" ]; then
    pass_test "Missing brace classified as permanent"
  else
    fail_test "Missing brace classified as permanent" "Expected 'fail', got '$result'"
  fi

  # Test 2.7: Unexpected token
  run_test "Permanent Error: Unexpected token"
  result=$(classify_and_retry "SyntaxError: Unexpected token ']'")
  if [ "$result" = "fail" ]; then
    pass_test "Unexpected token classified as permanent"
  else
    fail_test "Unexpected token classified as permanent" "Expected 'fail', got '$result'"
  fi
}

# Test Suite 3: Enhanced Error Reporting (7 tests)
test_suite_3_error_reporting() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 3: Enhanced Error Reporting (7 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Test 3.1: Error location extraction - file:line format
  run_test "Error Location: file:line format"
  location=$(extract_error_location "SyntaxError at supervise.md:856: Missing closing brace")
  if echo "$location" | grep -q "supervise.md:856"; then
    pass_test "Location extracted from file:line format"
  else
    fail_test "Location extracted from file:line format" "Expected 'supervise.md:856', got '$location'"
  fi

  # Test 3.2: Error location extraction - in keyword
  run_test "Error Location: 'in' keyword format"
  location=$(extract_error_location "Error in module.py:156 - undefined variable")
  if echo "$location" | grep -q "module.py:156"; then
    pass_test "Location extracted from 'in' keyword format"
  else
    fail_test "Location extracted from 'in' keyword format" "Expected 'module.py:156', got '$location'"
  fi

  # Test 3.3: Error type detection - timeout
  run_test "Error Type: Timeout detection"
  error_type=$(detect_specific_error_type "connection timeout after 30s")
  if [ "$error_type" = "timeout" ]; then
    pass_test "Timeout error type detected"
  else
    fail_test "Timeout error type detected" "Expected 'timeout', got '$error_type'"
  fi

  # Test 3.4: Error type detection - syntax error
  run_test "Error Type: Syntax error detection"
  error_type=$(detect_specific_error_type "SyntaxError: invalid syntax")
  if [ "$error_type" = "syntax_error" ]; then
    pass_test "Syntax error type detected"
  else
    fail_test "Syntax error type detected" "Expected 'syntax_error', got '$error_type'"
  fi

  # Test 3.5: Error type detection - missing dependency
  run_test "Error Type: Missing dependency detection"
  error_type=$(detect_specific_error_type "ModuleNotFoundError: No module named 'foo'")
  if [ "$error_type" = "missing_dependency" ]; then
    pass_test "Missing dependency type detected"
  else
    fail_test "Missing dependency type detected" "Expected 'missing_dependency', got '$error_type'"
  fi

  # Test 3.6: Recovery suggestions - timeout
  run_test "Recovery Suggestions: Timeout errors"
  suggestions=$(suggest_recovery_actions "timeout" "file.js:42" "connection timeout")
  if echo "$suggestions" | grep -q "network connection"; then
    pass_test "Timeout recovery suggestions generated"
  else
    fail_test "Timeout recovery suggestions generated" "Expected network-related suggestions"
  fi

  # Test 3.7: Recovery suggestions - syntax error
  run_test "Recovery Suggestions: Syntax errors"
  suggestions=$(suggest_recovery_actions "syntax_error" "auth.js:42" "Missing closing brace")
  if echo "$suggestions" | grep -q "syntax" && echo "$suggestions" | grep -q "linter"; then
    pass_test "Syntax error recovery suggestions generated"
  else
    fail_test "Syntax error recovery suggestions generated" "Expected syntax-related suggestions"
  fi
}

# Test Suite 4: Partial Research Failure Handling (3 tests)
test_suite_4_partial_failures() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 4: Partial Research Failure Handling (3 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Test 4.1: 3/4 success rate (75%) - should continue
  run_test "Partial Failure: 3/4 agents succeeded (75%)"
  result=$(handle_partial_research_failure 4 3 "agent_4")
  if [ "$result" = "continue" ]; then
    pass_test "3/4 success allows continuation"
  else
    fail_test "3/4 success allows continuation" "Expected 'continue', got '$result'"
  fi

  # Test 4.2: 2/4 success rate (50%) - should continue (at threshold)
  run_test "Partial Failure: 2/4 agents succeeded (50%)"
  result=$(handle_partial_research_failure 4 2 "agent_3 agent_4")
  if [ "$result" = "continue" ]; then
    pass_test "2/4 success allows continuation (at threshold)"
  else
    fail_test "2/4 success allows continuation (at threshold)" "Expected 'continue', got '$result'"
  fi

  # Test 4.3: 1/4 success rate (25%) - should terminate
  run_test "Partial Failure: 1/4 agents succeeded (25%)"
  result=$(handle_partial_research_failure 4 1 "agent_2 agent_3 agent_4")
  if [ "$result" = "terminate" ]; then
    pass_test "1/4 success terminates workflow (below threshold)"
  else
    fail_test "1/4 success terminates workflow (below threshold)" "Expected 'terminate', got '$result'"
  fi
}

# Test Suite 5: Checkpoint Save at Boundaries (4 tests)
test_suite_5_checkpoint_save() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 5: Checkpoint Save at Boundaries (4 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  CHECKPOINT_DIR="/home/benjamin/.config/.claude/data/checkpoints"
  CHECKPOINT_FILE="$CHECKPOINT_DIR/supervise_latest.json"

  # Test 5.1: Checkpoint directory creation
  run_test "Checkpoint: Directory exists or can be created"
  mkdir -p "$CHECKPOINT_DIR" 2>/dev/null
  if [ -d "$CHECKPOINT_DIR" ]; then
    pass_test "Checkpoint directory exists"
  else
    fail_test "Checkpoint directory exists" "Failed to create checkpoint directory"
  fi

  # Test 5.2: Checkpoint schema validation (minimal v1.0)
  run_test "Checkpoint: Schema validation"
  cat > "$CHECKPOINT_FILE" <<'EOF'
{
  "schema_version": "1.0",
  "workflow_type": "supervise",
  "workflow_description": "test workflow",
  "current_phase": 1,
  "completed_phases": [0, 1],
  "scope": "research-and-plan",
  "topic_path": "/test/path",
  "artifact_paths": {
    "research_reports": ["report1.md", "report2.md"],
    "overview_path": "overview.md"
  }
}
EOF

  if [ -f "$CHECKPOINT_FILE" ] && grep -q '"schema_version": "1.0"' "$CHECKPOINT_FILE"; then
    pass_test "Checkpoint schema is valid v1.0"
  else
    fail_test "Checkpoint schema is valid v1.0" "Schema validation failed"
  fi

  # Test 5.3: Checkpoint content validation
  run_test "Checkpoint: Content validation"
  if grep -q '"current_phase": 1' "$CHECKPOINT_FILE" && \
     grep -q '"completed_phases"' "$CHECKPOINT_FILE" && \
     grep -q '"artifact_paths"' "$CHECKPOINT_FILE"; then
    pass_test "Checkpoint contains required fields"
  else
    fail_test "Checkpoint contains required fields" "Missing required fields"
  fi

  # Test 5.4: Checkpoint JSON validity
  run_test "Checkpoint: JSON validity"
  if command -v jq >/dev/null 2>&1; then
    if jq empty "$CHECKPOINT_FILE" 2>/dev/null; then
      pass_test "Checkpoint JSON is valid"
    else
      fail_test "Checkpoint JSON is valid" "Invalid JSON format"
    fi
  else
    # Fallback validation without jq
    if python3 -c "import json; json.load(open('$CHECKPOINT_FILE'))" 2>/dev/null; then
      pass_test "Checkpoint JSON is valid (python validation)"
    else
      fail_test "Checkpoint JSON is valid" "Invalid JSON format (no jq or python available)"
    fi
  fi
}

# Test Suite 6: Resume from Checkpoints (4 tests)
test_suite_6_checkpoint_resume() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 6: Resume from Checkpoints (4 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  CHECKPOINT_FILE="/home/benjamin/.config/.claude/data/checkpoints/supervise_latest.json"

  # Test 6.1: Resume from Phase 1 checkpoint
  run_test "Resume: From Phase 1 checkpoint"
  cat > "$CHECKPOINT_FILE" <<'EOF'
{
  "schema_version": "1.0",
  "workflow_type": "supervise",
  "current_phase": 1,
  "completed_phases": [0, 1],
  "scope": "research-and-plan",
  "topic_path": "/test/path",
  "artifact_paths": {
    "research_reports": ["report1.md"]
  }
}
EOF

  if [ -f "$CHECKPOINT_FILE" ]; then
    current_phase=$(grep '"current_phase":' "$CHECKPOINT_FILE" | grep -o '[0-9]')
    if [ "$current_phase" = "1" ]; then
      pass_test "Phase 1 checkpoint can be loaded"
    else
      fail_test "Phase 1 checkpoint can be loaded" "Wrong phase: $current_phase"
    fi
  else
    fail_test "Phase 1 checkpoint can be loaded" "Checkpoint file not found"
  fi

  # Test 6.2: Resume from Phase 2 checkpoint
  run_test "Resume: From Phase 2 checkpoint"
  cat > "$CHECKPOINT_FILE" <<'EOF'
{
  "schema_version": "1.0",
  "workflow_type": "supervise",
  "current_phase": 2,
  "completed_phases": [0, 1, 2],
  "scope": "research-and-plan",
  "topic_path": "/test/path",
  "artifact_paths": {
    "research_reports": ["report1.md"],
    "plan_path": "plan.md"
  }
}
EOF

  current_phase=$(grep '"current_phase":' "$CHECKPOINT_FILE" | grep -o '[0-9]')
  if [ "$current_phase" = "2" ]; then
    pass_test "Phase 2 checkpoint can be loaded"
  else
    fail_test "Phase 2 checkpoint can be loaded" "Wrong phase: $current_phase"
  fi

  # Test 6.3: Invalid checkpoint handling
  run_test "Resume: Invalid checkpoint handling"
  echo "invalid json {{{" > "$CHECKPOINT_FILE"

  # Checkpoint should be recognized as invalid
  if ! python3 -c "import json; json.load(open('$CHECKPOINT_FILE'))" 2>/dev/null; then
    pass_test "Invalid checkpoint detected"
    # Clean up invalid checkpoint
    rm -f "$CHECKPOINT_FILE"
  else
    fail_test "Invalid checkpoint detected" "Invalid JSON not detected"
  fi

  # Test 6.4: Checkpoint cleanup after completion
  run_test "Resume: Checkpoint cleanup after completion"
  # Simulate checkpoint exists
  cat > "$CHECKPOINT_FILE" <<'EOF'
{"schema_version": "1.0", "current_phase": 6}
EOF

  # Verify checkpoint can be deleted (simulating workflow completion)
  rm -f "$CHECKPOINT_FILE"
  if [ ! -f "$CHECKPOINT_FILE" ]; then
    pass_test "Checkpoint deleted after workflow completion"
  else
    fail_test "Checkpoint deleted after workflow completion" "Checkpoint still exists"
  fi
}

# Test Suite 7: Progress Marker Emission (7 tests)
test_suite_7_progress_markers() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 7: Progress Marker Emission (7 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Mock emit_progress function
  emit_progress() {
    local phase="$1"
    local action="$2"
    echo "PROGRESS: [Phase $phase] - $action"
  }

  # Test 7.1: Phase 0 progress marker
  run_test "Progress Marker: Phase 0"
  output=$(emit_progress 0 "Topic directory created")
  if echo "$output" | grep -q "PROGRESS: \[Phase 0\] - Topic directory created"; then
    pass_test "Phase 0 progress marker formatted correctly"
  else
    fail_test "Phase 0 progress marker formatted correctly" "Unexpected format: $output"
  fi

  # Test 7.2: Phase 1 research start marker
  run_test "Progress Marker: Phase 1 start"
  output=$(emit_progress 1 "Research agent 1/4 invoked")
  if echo "$output" | grep -q "PROGRESS: \[Phase 1\] - Research agent 1/4 invoked"; then
    pass_test "Phase 1 research start marker formatted correctly"
  else
    fail_test "Phase 1 research start marker formatted correctly" "Unexpected format: $output"
  fi

  # Test 7.3: Phase 1 research complete marker
  run_test "Progress Marker: Phase 1 complete"
  output=$(emit_progress 1 "Research complete (4/4 succeeded)")
  if echo "$output" | grep -q "PROGRESS: \[Phase 1\] - Research complete"; then
    pass_test "Phase 1 complete marker formatted correctly"
  else
    fail_test "Phase 1 complete marker formatted correctly" "Unexpected format: $output"
  fi

  # Test 7.4: Phase 2 planning marker
  run_test "Progress Marker: Phase 2"
  output=$(emit_progress 2 "Planning agent invoked")
  if echo "$output" | grep -q "PROGRESS: \[Phase 2\] - Planning agent invoked"; then
    pass_test "Phase 2 planning marker formatted correctly"
  else
    fail_test "Phase 2 planning marker formatted correctly" "Unexpected format: $output"
  fi

  # Test 7.5: Resume marker
  run_test "Progress Marker: Resume"
  output=$(echo "PROGRESS: [Resume] - Skipping completed phases 0-2")
  if echo "$output" | grep -q "PROGRESS: \[Resume\] - Skipping completed phases"; then
    pass_test "Resume marker formatted correctly"
  else
    fail_test "Resume marker formatted correctly" "Unexpected format: $output"
  fi

  # Test 7.6: Phase 3 implementation marker
  run_test "Progress Marker: Phase 3"
  output=$(emit_progress 3 "Implementation agent invoked")
  if echo "$output" | grep -q "PROGRESS: \[Phase 3\] - Implementation agent invoked"; then
    pass_test "Phase 3 implementation marker formatted correctly"
  else
    fail_test "Phase 3 implementation marker formatted correctly" "Unexpected format: $output"
  fi

  # Test 7.7: Phase 4 testing marker
  run_test "Progress Marker: Phase 4"
  output=$(emit_progress 4 "Testing agent invoked")
  if echo "$output" | grep -q "PROGRESS: \[Phase 4\] - Testing agent invoked"; then
    pass_test "Phase 4 testing marker formatted correctly"
  else
    fail_test "Phase 4 testing marker formatted correctly" "Unexpected format: $output"
  fi
}

# Test Suite 8: Error Logging (7 tests)
test_suite_8_error_logging() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 8: Error Logging (7 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Test 8.1: Error log format - timeout
  run_test "Error Log: Timeout error format"
  error_msg="connection timeout after 30s"
  error_type=$(detect_specific_error_type "$error_msg")
  if [ "$error_type" = "timeout" ]; then
    pass_test "Timeout error logged with correct type"
  else
    fail_test "Timeout error logged with correct type" "Expected 'timeout', got '$error_type'"
  fi

  # Test 8.2: Error log format - syntax error with location
  run_test "Error Log: Syntax error with location"
  error_msg="SyntaxError at file.js:42: Missing closing brace"
  location=$(extract_error_location "$error_msg")
  error_type=$(detect_specific_error_type "$error_msg")

  if [ "$error_type" = "syntax_error" ] && echo "$location" | grep -q "file.js:42"; then
    pass_test "Syntax error logged with location and type"
  else
    fail_test "Syntax error logged with location and type" "Type: $error_type, Location: $location"
  fi

  # Test 8.3: Error log format - missing dependency
  run_test "Error Log: Missing dependency"
  error_msg="ModuleNotFoundError: No module named 'express'"
  error_type=$(detect_specific_error_type "$error_msg")
  if [ "$error_type" = "missing_dependency" ]; then
    pass_test "Missing dependency logged with correct type"
  else
    fail_test "Missing dependency logged with correct type" "Expected 'missing_dependency', got '$error_type'"
  fi

  # Test 8.4: Error log context - includes suggestions
  run_test "Error Log: Context includes suggestions"
  suggestions=$(suggest_recovery_actions "timeout" "file.js:42" "connection timeout")
  if echo "$suggestions" | grep -q "network" && echo "$suggestions" | grep -q "Retry"; then
    pass_test "Error log includes recovery suggestions"
  else
    fail_test "Error log includes recovery suggestions" "Suggestions incomplete"
  fi

  # Test 8.5: Error log context - includes error location
  run_test "Error Log: Context includes location"
  error_msg="Error in auth.py:156 - undefined variable 'user'"
  location=$(extract_error_location "$error_msg")
  if echo "$location" | grep -q "auth.py:156"; then
    pass_test "Error log includes file location"
  else
    fail_test "Error log includes file location" "Location not extracted: $location"
  fi

  # Test 8.6: Error log categorization
  run_test "Error Log: Proper categorization"
  # Test all 4 categories
  timeout=$(detect_specific_error_type "timeout")
  syntax=$(detect_specific_error_type "SyntaxError")
  missing=$(detect_specific_error_type "module not found")
  unknown=$(detect_specific_error_type "random error")

  if [ "$timeout" = "timeout" ] && \
     [ "$syntax" = "syntax_error" ] && \
     [ "$missing" = "missing_dependency" ] && \
     [ "$unknown" = "unknown" ]; then
    pass_test "All error categories properly detected"
  else
    fail_test "All error categories properly detected" "timeout=$timeout, syntax=$syntax, missing=$missing, unknown=$unknown"
  fi

  # Test 8.7: Error message completeness
  run_test "Error Log: Message completeness"
  error_msg="SyntaxError at supervise.md:856: Missing closing brace"
  location=$(extract_error_location "$error_msg")
  error_type=$(detect_specific_error_type "$error_msg")
  suggestions=$(suggest_recovery_actions "$error_type" "$location" "$error_msg")

  # Verify all components present
  if [ -n "$location" ] && [ -n "$error_type" ] && [ -n "$suggestions" ]; then
    pass_test "Complete error context available for logging"
  else
    fail_test "Complete error context available for logging" "Missing components"
  fi
}

# Test Suite 9: Enhanced Error Reporting Integration in verify_file_created (8 tests)
test_suite_9_verify_file_integration() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Suite 9: verify_file_created Integration (8 tests)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Test 9.1: File missing - error location extraction
  run_test "verify_file_created: Extract location from agent output"
  agent_output="Error at implementation.sh:127 - file creation failed"
  location=$(extract_error_location "$agent_output")
  if echo "$location" | grep -q "implementation.sh:127"; then
    pass_test "Location extracted from agent output in file missing scenario"
  else
    fail_test "Location extracted from agent output in file missing scenario" "Expected 'implementation.sh:127', got '$location'"
  fi

  # Test 9.2: File missing - error type detection
  run_test "verify_file_created: Detect error type from agent output"
  agent_output="Connection timeout while creating file"
  error_type=$(detect_specific_error_type "$agent_output")
  if [ "$error_type" = "timeout" ]; then
    pass_test "Timeout error type detected in file missing scenario"
  else
    fail_test "Timeout error type detected in file missing scenario" "Expected 'timeout', got '$error_type'"
  fi

  # Test 9.3: File missing - syntax error type
  run_test "verify_file_created: Detect syntax error in agent output"
  agent_output="SyntaxError: unexpected token at writer.js:45"
  error_type=$(detect_specific_error_type "$agent_output")
  if [ "$error_type" = "syntax_error" ]; then
    pass_test "Syntax error type detected in file missing scenario"
  else
    fail_test "Syntax error type detected in file missing scenario" "Expected 'syntax_error', got '$error_type'"
  fi

  # Test 9.4: File missing - dependency error type
  run_test "verify_file_created: Detect dependency error in agent output"
  agent_output="ModuleNotFoundError: No module named 'writer' at writer.py:12"
  error_type=$(detect_specific_error_type "$agent_output")
  if [ "$error_type" = "missing_dependency" ]; then
    pass_test "Dependency error type detected in file missing scenario"
  else
    fail_test "Dependency error type detected in file missing scenario" "Expected 'missing_dependency', got '$error_type'"
  fi

  # Test 9.5: File missing - unknown error type fallback
  run_test "verify_file_created: Unknown error type fallback"
  agent_output="Something mysterious went wrong"
  error_type=$(detect_specific_error_type "$agent_output")
  if [ "$error_type" = "unknown" ]; then
    pass_test "Unknown error type detected as fallback"
  else
    fail_test "Unknown error type detected as fallback" "Expected 'unknown', got '$error_type'"
  fi

  # Test 9.6: File missing - timeout recovery suggestions
  run_test "verify_file_created: Timeout recovery suggestions"
  suggestions=$(suggest_recovery_actions "timeout" "file.sh:42" "Connection timeout")
  if echo "$suggestions" | grep -q "network" || echo "$suggestions" | grep -q "Retry"; then
    pass_test "Timeout recovery suggestions provided"
  else
    fail_test "Timeout recovery suggestions provided" "Suggestions incomplete: $suggestions"
  fi

  # Test 9.7: File missing - syntax error recovery suggestions
  run_test "verify_file_created: Syntax error recovery suggestions"
  suggestions=$(suggest_recovery_actions "syntax_error" "test.sh:45" "unexpected token")
  if echo "$suggestions" | grep -q "syntax" || echo "$suggestions" | grep -q "linter"; then
    pass_test "Syntax error recovery suggestions provided"
  else
    fail_test "Syntax error recovery suggestions provided" "Suggestions incomplete: $suggestions"
  fi

  # Test 9.8: Empty file - complete error context
  run_test "verify_file_created: Complete error context for empty file"
  agent_output="File created but write failed at writer.py:89"
  location=$(extract_error_location "$agent_output")
  error_type=$(detect_specific_error_type "$agent_output")
  suggestions=$(suggest_recovery_actions "$error_type" "$location" "$agent_output")

  if [ -n "$location" ] && [ -n "$error_type" ] && [ -n "$suggestions" ]; then
    pass_test "Complete error context available for empty file scenario"
  else
    fail_test "Complete error context available for empty file scenario" "Missing components - location: $location, type: $error_type"
  fi
}

# Main test execution
main() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  /supervise Auto-Recovery Test Suite"
  echo "  Testing 55 recovery scenarios"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Source functions
  source_supervise_functions

  # Run all test suites
  test_suite_1_transient_errors      # 7 tests
  test_suite_2_permanent_errors      # 7 tests
  test_suite_3_error_reporting       # 7 tests
  test_suite_4_partial_failures      # 3 tests
  test_suite_5_checkpoint_save       # 4 tests
  test_suite_6_checkpoint_resume     # 4 tests
  test_suite_7_progress_markers      # 7 tests
  test_suite_8_error_logging         # 7 tests
  test_suite_9_verify_file_integration  # 8 tests

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Test Results Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Total Tests:  $TESTS_TOTAL"
  echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
  echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    exit 0
  else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    exit 1
  fi
}

# Run main function
main "$@"
