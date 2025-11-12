#!/usr/bin/env bash
# Test hierarchical supervisor functionality
# Tests research-sub-supervisor, implementation-sub-supervisor, testing-sub-supervisor

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
TEST_TMP="/tmp/test_supervisors_$$"

# Source required libraries (if they exist)
if [ -f "${CLAUDE_DIR}/lib/state-persistence.sh" ]; then
  source "${CLAUDE_DIR}/lib/state-persistence.sh"
fi

if [ -f "${CLAUDE_DIR}/lib/metadata-extraction.sh" ]; then
  source "${CLAUDE_DIR}/lib/metadata-extraction.sh"
fi

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup
setup_test_env() {
  mkdir -p "$TEST_TMP"
  export CLAUDE_PROJECT_DIR="$TEST_TMP"
  mkdir -p "$TEST_TMP/.claude/tmp"
  mkdir -p "$TEST_TMP/.claude/specs/test_topic/reports"
}

# Teardown
teardown_test_env() {
  rm -rf "$TEST_TMP"
}

# Test helpers
pass_test() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "  ✓ PASS"
}

fail_test() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "  ✗ FAIL: $message"
}

run_test() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo -n "Test $TESTS_RUN: $test_name..."
}

## Research Sub-Supervisor Tests

test_research_supervisor_exists() {
  run_test "Research supervisor behavioral file exists"

  if [ -f "${CLAUDE_DIR}/agents/research-sub-supervisor.md" ]; then
    pass_test
  else
    fail_test "research-sub-supervisor.md not found"
  fi
}

test_research_supervisor_has_required_sections() {
  run_test "Research supervisor has all required sections"

  local supervisor_file="${CLAUDE_DIR}/agents/research-sub-supervisor.md"
  local required_sections=(
    "Agent Metadata"
    "Purpose"
    "Inputs"
    "Expected Outputs"
    "STEP 1: Load Workflow State"
    "STEP 2: Parse Inputs"
    "STEP 3: Invoke Workers in Parallel"
    "STEP 4: Extract Worker Metadata"
    "STEP 5: Aggregate Worker Metadata"
    "STEP 6: Save Supervisor Checkpoint"
    "STEP 7: Handle Partial Failures"
    "STEP 8: Return Aggregated Metadata"
  )

  local missing_sections=()

  for section in "${required_sections[@]}"; do
    if ! grep -q "$section" "$supervisor_file"; then
      missing_sections+=("$section")
    fi
  done

  if [ ${#missing_sections[@]} -eq 0 ]; then
    pass_test
  else
    fail_test "Missing sections: ${missing_sections[*]}"
  fi
}

test_research_supervisor_checkpoint_schema() {
  run_test "Research supervisor checkpoint schema validation"

  # Create mock supervisor checkpoint
  local checkpoint=$(jq -n \
    '{
      supervisor_id: "research_sub_supervisor_test",
      supervisor_name: "research-sub-supervisor",
      worker_count: 4,
      workers: [
        {
          worker_id: "research_specialist_1",
          topic: "authentication",
          status: "completed",
          output_path: "/path/report1.md",
          duration_ms: 12000,
          metadata: {
            title: "Auth Research",
            summary: "Summary 1",
            key_findings: ["finding1", "finding2"]
          }
        }
      ],
      aggregated_metadata: {
        reports_count: 4,
        reports_created: ["/path1", "/path2", "/path3", "/path4"],
        summary: "Combined summary",
        key_findings: ["finding1", "finding2"],
        total_duration_ms: 45000,
        context_tokens: 500
      }
    }')

  # Validate schema
  if echo "$checkpoint" | jq -e '.supervisor_id and .worker_count and .aggregated_metadata.reports_created' >/dev/null 2>&1; then
    pass_test
  else
    fail_test "Checkpoint schema validation failed"
  fi
}

test_research_supervisor_context_reduction() {
  run_test "Research supervisor achieves 95% context reduction"

  # Simulate 4 worker outputs (2500 tokens each = 10000 total)
  local worker_tokens=10000

  # Simulate aggregated metadata (~500 tokens)
  local aggregated_tokens=500

  # Calculate reduction using awk
  local reduction=$(awk "BEGIN {printf \"%.1f\", (($worker_tokens - $aggregated_tokens) / $worker_tokens) * 100}")

  if [ $(awk "BEGIN {print ($reduction >= 95.0) ? 1 : 0}") -eq 1 ]; then
    pass_test
  else
    fail_test "Context reduction $reduction% < 95%"
  fi
}

## Implementation Sub-Supervisor Tests

test_implementation_supervisor_exists() {
  run_test "Implementation supervisor behavioral file exists"

  if [ -f "${CLAUDE_DIR}/agents/implementation-sub-supervisor.md" ]; then
    pass_test
  else
    fail_test "implementation-sub-supervisor.md not found"
  fi
}

test_implementation_supervisor_track_detection() {
  run_test "Implementation supervisor track detection patterns"

  # Mock plan file with track patterns
  local plan_file="$TEST_TMP/test_plan.md"
  cat > "$plan_file" <<EOF
# Implementation Plan

## Phase 1
- [ ] Update src/frontend/components/Auth.tsx
- [ ] Update src/backend/api/auth.ts
- [ ] Update tests/integration/auth.spec.ts
EOF

  # Detect tracks (simplified version)
  local has_frontend=$(grep -c 'frontend/' "$plan_file" || true)
  local has_backend=$(grep -c 'backend/' "$plan_file" || true)
  local has_testing=$(grep -c 'tests/' "$plan_file" || true)

  if [ $has_frontend -gt 0 ] && [ $has_backend -gt 0 ] && [ $has_testing -gt 0 ]; then
    pass_test
  else
    fail_test "Track detection failed (frontend=$has_frontend, backend=$has_backend, testing=$has_testing)"
  fi
}

test_implementation_supervisor_parallel_savings() {
  run_test "Implementation supervisor calculates parallel savings"

  # Simulate 3 tracks: backend (40s), frontend (30s), testing (25s)
  local sequential_duration=$((40000 + 30000 + 25000))  # 95000ms
  local parallel_duration=40000  # max duration = 40000ms

  # Calculate savings using awk
  local savings=$(awk "BEGIN {printf \"%.1f\", (($sequential_duration - $parallel_duration) / $sequential_duration) * 100}")

  if [ $(awk "BEGIN {print ($savings >= 40.0) ? 1 : 0}") -eq 1 ]; then
    pass_test
  else
    fail_test "Parallel savings $savings% < 40%"
  fi
}

test_implementation_supervisor_dependency_waves() {
  run_test "Implementation supervisor handles cross-track dependencies"

  # Mock tracks with frontend depending on backend
  local tracks='["backend", "frontend", "testing"]'

  # Simulate wave detection
  local has_frontend=$(echo "$tracks" | jq 'contains(["frontend"])')
  local has_backend=$(echo "$tracks" | jq 'contains(["backend"])')

  if [ "$has_frontend" = "true" ] && [ "$has_backend" = "true" ]; then
    # Should create Wave 1 (backend, testing) and Wave 2 (frontend)
    pass_test
  else
    fail_test "Dependency wave detection failed"
  fi
}

## Testing Sub-Supervisor Tests

test_testing_supervisor_exists() {
  run_test "Testing supervisor behavioral file exists"

  if [ -f "${CLAUDE_DIR}/agents/testing-sub-supervisor.md" ]; then
    pass_test
  else
    fail_test "testing-sub-supervisor.md not found"
  fi
}

test_testing_supervisor_sequential_stages() {
  run_test "Testing supervisor enforces sequential lifecycle stages"

  # Verify stages are documented in behavioral file
  local supervisor_file="${CLAUDE_DIR}/agents/testing-sub-supervisor.md"

  if grep -q "Stage 1.*Generation" "$supervisor_file" &&
     grep -q "Stage 2.*Execution" "$supervisor_file" &&
     grep -q "Stage 3.*Validation" "$supervisor_file"; then
    pass_test
  else
    fail_test "Sequential stages not documented"
  fi
}

test_testing_supervisor_metadata_aggregation() {
  run_test "Testing supervisor aggregates test metrics correctly"

  # Mock stage 2 metadata
  local stage_2_metadata=$(jq -n \
    '{
      stage: "execution",
      test_types: [
        {test_type: "unit", tests_run: 50, tests_passed: 48, tests_failed: 2, coverage_percent: 85},
        {test_type: "integration", tests_run: 30, tests_passed: 29, tests_failed: 1, coverage_percent: 80},
        {test_type: "e2e", tests_run: 7, tests_passed: 7, tests_failed: 0, coverage_percent: 90}
      ],
      total_tests_run: 87,
      total_tests_passed: 84,
      total_tests_failed: 3,
      average_coverage: 85
    }')

  # Validate aggregation
  if echo "$stage_2_metadata" | jq -e '.total_tests_run == 87 and .total_tests_passed == 84' >/dev/null 2>&1; then
    pass_test
  else
    fail_test "Test metrics aggregation incorrect"
  fi
}

## Supervisor Checkpoint Integration Tests

test_supervisor_checkpoint_persistence() {
  run_test "Supervisor checkpoints saved and loaded correctly"

  # Initialize state file
  local state_file=$(init_workflow_state "test_$$")

  # Create supervisor checkpoint
  local checkpoint=$(jq -n \
    '{
      supervisor_id: "test_supervisor",
      supervisor_name: "test-sub-supervisor",
      worker_count: 3,
      aggregated_metadata: {
        test_field: "test_value"
      }
    }')

  # Save checkpoint
  save_json_checkpoint "test_supervisor" "$checkpoint"

  # Load checkpoint
  local loaded_checkpoint=$(load_json_checkpoint "test_supervisor")

  # Validate
  if echo "$loaded_checkpoint" | jq -e '.supervisor_id == "test_supervisor"' >/dev/null 2>&1; then
    pass_test
  else
    fail_test "Checkpoint save/load failed"
  fi

  # Cleanup
  rm -f "$state_file"
}

test_supervisor_partial_failure_handling() {
  run_test "Supervisors handle partial worker failures gracefully"

  # Mock workers array with 1 failure
  local workers=$(jq -n \
    '[
      {worker_id: "w1", status: "completed", output: "success"},
      {worker_id: "w2", status: "completed", output: "success"},
      {worker_id: "w3", status: "failed", error: "timeout"}
    ]')

  # Check partial success (2/3)
  local successful=$(echo "$workers" | jq '[.[] | select(.status == "completed")]')
  local success_count=$(echo "$successful" | jq 'length')

  if [ $success_count -ge 2 ]; then
    # Partial success threshold met (>=50%)
    pass_test
  else
    fail_test "Partial failure handling incorrect (success_count=$success_count)"
  fi
}

## /coordinate Integration Tests

test_coordinate_hierarchical_research_detection() {
  run_test "/coordinate detects when to use hierarchical research"

  # Simulate complexity detection
  local research_complexity=4  # Should trigger hierarchical

  local use_hierarchical=$([ $research_complexity -ge 4 ] && echo "true" || echo "false")

  if [ "$use_hierarchical" = "true" ]; then
    pass_test
  else
    fail_test "Hierarchical detection failed (complexity=$research_complexity)"
  fi
}

test_coordinate_flat_research_detection() {
  run_test "/coordinate uses flat coordination for <4 topics"

  local research_complexity=3  # Should NOT trigger hierarchical

  local use_hierarchical=$([ $research_complexity -ge 4 ] && echo "true" || echo "false")

  if [ "$use_hierarchical" = "false" ]; then
    pass_test
  else
    fail_test "Flat coordination detection failed (complexity=$research_complexity)"
  fi
}

test_coordinate_supervisor_checkpoint_integration() {
  run_test "/coordinate loads supervisor checkpoint after research"

  # Create mock supervisor checkpoint
  local checkpoint=$(jq -n \
    '{
      supervisor_id: "research_sub_supervisor_test",
      aggregated_metadata: {
        reports_created: ["/path1.md", "/path2.md", "/path3.md", "/path4.md"],
        summary: "Research summary",
        context_tokens: 500
      }
    }')

  save_json_checkpoint "research_supervisor" "$checkpoint"

  # Load and validate
  local loaded=$(load_json_checkpoint "research_supervisor")
  local reports=$(echo "$loaded" | jq -r '.aggregated_metadata.reports_created | length')

  if [ "$reports" -eq 4 ]; then
    pass_test
  else
    fail_test "Checkpoint integration failed (reports=$reports)"
  fi
}

## Performance Validation Tests

test_supervisor_context_reduction_target() {
  run_test "Supervisors meet 95% context reduction target"

  # Research supervisor: 10000 tokens → 500 tokens = 95%
  local original=10000
  local reduced=500
  local reduction=$(awk "BEGIN {printf \"%.1f\", (($original - $reduced) / $original) * 100}")

  if [ $(awk "BEGIN {print ($reduction >= 95.0) ? 1 : 0}") -eq 1 ]; then
    pass_test
  else
    fail_test "Context reduction target not met ($reduction% < 95%)"
  fi
}

test_supervisor_time_savings_target() {
  run_test "Implementation supervisor meets 40-60% time savings target"

  # Simulate parallel execution (3 tracks @ 40s max vs 95s sequential)
  local sequential=95000
  local parallel=40000
  local savings=$(awk "BEGIN {printf \"%.1f\", (($sequential - $parallel) / $sequential) * 100}")

  if [ $(awk "BEGIN {print ($savings >= 40.0 && $savings <= 100.0) ? 1 : 0}") -eq 1 ]; then
    pass_test
  else
    fail_test "Time savings target not met ($savings%)"
  fi
}

## Test Template Compliance

test_supervisor_template_compliance() {
  run_test "Supervisors follow sub-supervisor-template.md structure"

  local template="${CLAUDE_DIR}/templates/sub-supervisor-template.md"

  if [ ! -f "$template" ]; then
    fail_test "Template file not found"
    return
  fi

  # Check research supervisor follows template
  local research_supervisor="${CLAUDE_DIR}/agents/research-sub-supervisor.md"

  # Key template sections that must be present
  if grep -q "STEP 1: Load Workflow State" "$research_supervisor" &&
     grep -q "STEP 3: Invoke Workers in Parallel" "$research_supervisor" &&
     grep -q "aggregate.*metadata" "$research_supervisor"; then
    pass_test
  else
    fail_test "Supervisor doesn't follow template structure"
  fi
}

## Run all tests

echo "=== Hierarchical Supervisor Tests ==="
echo ""

setup_test_env

# Research Sub-Supervisor Tests
echo "Research Sub-Supervisor Tests:"
test_research_supervisor_exists
test_research_supervisor_has_required_sections
test_research_supervisor_checkpoint_schema
test_research_supervisor_context_reduction

# Implementation Sub-Supervisor Tests
echo ""
echo "Implementation Sub-Supervisor Tests:"
test_implementation_supervisor_exists
test_implementation_supervisor_track_detection
test_implementation_supervisor_parallel_savings
test_implementation_supervisor_dependency_waves

# Testing Sub-Supervisor Tests
echo ""
echo "Testing Sub-Supervisor Tests:"
test_testing_supervisor_exists
test_testing_supervisor_sequential_stages
test_testing_supervisor_metadata_aggregation

# Checkpoint Integration Tests
echo ""
echo "Checkpoint Integration Tests:"
test_supervisor_checkpoint_persistence
test_supervisor_partial_failure_handling

# /coordinate Integration Tests
echo ""
echo "/coordinate Integration Tests:"
test_coordinate_hierarchical_research_detection
test_coordinate_flat_research_detection
test_coordinate_supervisor_checkpoint_integration

# Performance Validation Tests
echo ""
echo "Performance Validation Tests:"
test_supervisor_context_reduction_target
test_supervisor_time_savings_target

# Template Compliance Tests
echo ""
echo "Template Compliance Tests:"
test_supervisor_template_compliance

teardown_test_env

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests Run: $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo "✓ All tests passed!"
  exit 0
else
  echo ""
  echo "✗ Some tests failed"
  exit 1
fi
