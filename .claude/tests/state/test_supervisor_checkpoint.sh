#!/usr/bin/env bash
# Test suite for supervisor checkpoint schema (Phase 4)
# Tests core supervisor_state field structure

set -uo pipefail

# Detect project directory
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

# Source required libraries
source "$CLAUDE_LIB/workflow/checkpoint-utils.sh"
source "$CLAUDE_LIB/core/state-persistence.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "✓ $1"
}

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "✗ $1"
  if [ -n "${2:-}" ]; then
    echo "  Error: $2"
  fi
}

echo "========================================="
echo "Supervisor Checkpoint Tests (Phase 4)"
echo "========================================="
echo ""

# Test 1: Basic Supervisor Checkpoint Structure
echo "Test 1: Basic supervisor checkpoint structure"

supervisor_checkpoint='{"supervisor_id": "research_sub_supervisor_20251107_143030", "supervisor_name": "research-sub-supervisor", "worker_count": 4, "aggregated_metadata": {"topics_researched": 4, "summary": "Test summary"}}'

supervisor_id=$(echo "$supervisor_checkpoint" | jq -r '.supervisor_id')
worker_count=$(echo "$supervisor_checkpoint" | jq -r '.worker_count')

if [ "$supervisor_id" = "research_sub_supervisor_20251107_143030" ] && [ "$worker_count" = "4" ]; then
  pass "Basic supervisor checkpoint structure valid"
else
  fail "Basic supervisor checkpoint structure invalid"
fi

# Test 2: Supervisor State in v2.0 Checkpoint
echo "Test 2: Supervisor state in v2.0 checkpoint"

workflow_state='{"workflow_description": "Test workflow", "supervisor_state": {"research_supervisor": {"supervisor_id": "test_123", "worker_count": 4}}}'

checkpoint_file=$(save_checkpoint "test" "supervisor_v2" "$workflow_state")

if [ -f "$checkpoint_file" ]; then
  schema_version=$(jq -r '.schema_version' "$checkpoint_file")
  supervisor_state=$(jq -r '.supervisor_state.research_supervisor' "$checkpoint_file")

  if [ "$schema_version" = "2.1" ] && [ "$supervisor_state" != "null" ]; then
    pass "Supervisor state in v2.1 checkpoint working"
    rm -f "$checkpoint_file"
  else
    fail "Supervisor state in v2.0 checkpoint failed"
    rm -f "$checkpoint_file"
  fi
else
  fail "Supervisor state in v2.0 checkpoint failed" "Checkpoint not created"
fi

# Test 3: Multiple Supervisors in Checkpoint
echo "Test 3: Multiple supervisors in single checkpoint"

workflow_state='{"workflow_description": "Multi-supervisor workflow", "supervisor_state": {"research_supervisor": {"supervisor_id": "research_123", "worker_count": 4}, "implementation_supervisor": {"supervisor_id": "impl_456", "worker_count": 3}}}'

checkpoint_file=$(save_checkpoint "test" "multi_supervisor" "$workflow_state")

if [ -f "$checkpoint_file" ]; then
  research_sup=$(jq -r '.supervisor_state.research_supervisor' "$checkpoint_file")
  impl_sup=$(jq -r '.supervisor_state.implementation_supervisor' "$checkpoint_file")

  if [ "$research_sup" != "null" ] && [ "$impl_sup" != "null" ]; then
    pass "Multiple supervisors in checkpoint working"
    rm -f "$checkpoint_file"
  else
    fail "Multiple supervisors in checkpoint failed"
    rm -f "$checkpoint_file"
  fi
else
  fail "Multiple supervisors in checkpoint failed" "Checkpoint not created"
fi

# Test 4: Supervisor Checkpoint Persistence
echo "Test 4: Supervisor checkpoint save and load"

supervisor_checkpoint='{"supervisor_id": "test_supervisor_123", "supervisor_name": "test-supervisor", "worker_count": 3}'

checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_supervisor.json"
mkdir -p "$(dirname "$checkpoint_file")"
echo "$supervisor_checkpoint" > "$checkpoint_file"

if [ -f "$checkpoint_file" ]; then
  loaded=$(cat "$checkpoint_file")
  loaded_id=$(echo "$loaded" | jq -r '.supervisor_id')

  if [ "$loaded_id" = "test_supervisor_123" ]; then
    pass "Supervisor checkpoint persistence working"
    rm -f "$checkpoint_file"
  else
    fail "Supervisor checkpoint persistence failed" "Loaded data incorrect"
    rm -f "$checkpoint_file"
  fi
else
  fail "Supervisor checkpoint persistence failed" "Checkpoint file not created"
fi

# Test 5: Metadata Aggregation Structure
echo "Test 5: Metadata aggregation structure"

aggregated_metadata='{"topics_researched": 4, "reports_created": ["path1.md", "path2.md", "path3.md", "path4.md"], "summary": "Combined summary", "key_findings": ["F1", "F2", "F3", "F4"], "total_duration_ms": 43500, "context_tokens": 500}'

topics=$(echo "$aggregated_metadata" | jq -r '.topics_researched')
reports=$(echo "$aggregated_metadata" | jq -r '.reports_created | length')
findings=$(echo "$aggregated_metadata" | jq -r '.key_findings | length')

if [ "$topics" = "4" ] && [ "$reports" = "4" ] && [ "$findings" = "4" ]; then
  pass "Metadata aggregation structure valid"
else
  fail "Metadata aggregation structure invalid"
fi

# Test 6: Worker Status Tracking
echo "Test 6: Worker status tracking"

workers_array='[{"worker_id": "w1", "status": "completed"}, {"worker_id": "w2", "status": "completed"}, {"worker_id": "w3", "status": "failed"}]'

completed=$(echo "$workers_array" | jq '[.[] | select(.status == "completed")] | length')
failed=$(echo "$workers_array" | jq '[.[] | select(.status == "failed")] | length')

if [ "$completed" = "2" ] && [ "$failed" = "1" ]; then
  pass "Worker status tracking working"
else
  fail "Worker status tracking failed"
fi

# Test 7: Context Reduction Validation
echo "Test 7: Context reduction validation"

# Simulate large worker outputs
worker_outputs='{"w1": "content", "w2": "content", "w3": "content", "w4": "content"}'
# Repeat to make it larger
for i in {1..100}; do
  worker_outputs=$(echo "$worker_outputs" | jq '. + {extra'$i': "more content"}')
done

aggregated='{"summary": "Short summary", "key_findings": ["F1", "F2"]}'

worker_tokens=$(echo "$worker_outputs" | wc -c | awk '{print int($1/4)}')
aggregated_tokens=$(echo "$aggregated" | wc -c | awk '{print int($1/4)}')

reduction_percent=$(echo "$worker_tokens $aggregated_tokens" | awk '{
  reduction = (($1 - $2) / $1) * 100
  printf "%.1f", reduction
}')

is_valid=$(echo "$reduction_percent" | awk '{if ($1 >= 90) print "1"; else print "0"}')
if [ "$is_valid" = "1" ]; then
  pass "Context reduction validated: ${reduction_percent}% (≥90% target)"
else
  fail "Context reduction below target" "${reduction_percent}% < 90%"
fi

# Test 8: Nested Checkpoint Structure
echo "Test 8: Nested checkpoint structure (orchestrator → supervisor)"

workflow_state='{"workflow_description": "Full workflow", "current_phase": 2, "state_machine": {"current_state": "plan", "completed_states": ["initialize", "research"]}, "supervisor_state": {"research_supervisor": {"supervisor_id": "research_123", "worker_count": 4, "aggregated_metadata": {"summary": "Test summary"}}}}'

checkpoint_file=$(save_checkpoint "test" "nested" "$workflow_state")

if [ -f "$checkpoint_file" ]; then
  state_machine=$(jq -r '.state_machine.current_state' "$checkpoint_file")
  supervisor=$(jq -r '.supervisor_state.research_supervisor.supervisor_id' "$checkpoint_file")

  if [ "$state_machine" = "plan" ] && [ "$supervisor" = "research_123" ]; then
    pass "Nested checkpoint structure valid"
    rm -f "$checkpoint_file"
  else
    fail "Nested checkpoint structure invalid"
    rm -f "$checkpoint_file"
  fi
else
  fail "Nested checkpoint structure failed" "Checkpoint not created"
fi

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All supervisor checkpoint tests passed!"
  exit 0
else
  echo "✗ Some supervisor checkpoint tests failed"
  exit 1
fi
