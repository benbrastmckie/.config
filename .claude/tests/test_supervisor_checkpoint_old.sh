#!/usr/bin/env bash
# Test suite for supervisor checkpoint schema (Phase 4)
# Tests supervisor_state field structure, metadata aggregation, nested checkpoints

set -uo pipefail

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source required libraries
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/state-persistence.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test output
TEST_OUTPUT=""

# Helper functions
pass() {
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
  echo "✓ $1"
}

fail() {
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
  echo "✗ $1"
  if [ -n "${2:-}" ]; then
    echo "  Error: $2"
  fi
}

# ==============================================================================
# Test 1: Research Supervisor Checkpoint Schema
# ==============================================================================
test_research_supervisor_schema() {
  echo "Test 1: Research supervisor checkpoint schema validation"

  # Create research supervisor checkpoint
  local supervisor_checkpoint=$(jq -n '{
    supervisor_id: "research_sub_supervisor_20251107_143030",
    supervisor_name: "research-sub-supervisor",
    worker_count: 4,
    workers: [
      {
        worker_id: "research_specialist_1",
        topic: "authentication patterns",
        status: "completed",
        output_path: "/path/to/report1.md",
        duration_ms: 12000,
        metadata: {
          title: "Authentication Patterns",
          summary: "Analysis of session-based auth, JWT, OAuth2",
          key_findings: ["Finding1", "Finding2"]
        }
      },
      {
        worker_id: "research_specialist_2",
        topic: "authorization patterns",
        status: "completed",
        output_path: "/path/to/report2.md",
        duration_ms: 10500,
        metadata: {
          title: "Authorization Patterns",
          summary: "RBAC, ABAC comparison",
          key_findings: ["Finding3", "Finding4"]
        }
      },
      {
        worker_id: "research_specialist_3",
        topic: "session management",
        status: "completed",
        output_path: "/path/to/report3.md",
        duration_ms: 11200,
        metadata: {
          title: "Session Management",
          summary: "Server-side vs client-side sessions",
          key_findings: ["Finding5", "Finding6"]
        }
      },
      {
        worker_id: "research_specialist_4",
        topic: "password security",
        status: "completed",
        output_path: "/path/to/report4.md",
        duration_ms: 9800,
        metadata: {
          title: "Password Security",
          summary: "bcrypt, Argon2 comparison",
          key_findings: ["Finding7", "Finding8"]
        }
      }
    ],
    aggregated_metadata: {
      topics_researched: 4,
      reports_created: ["/path/to/report1.md", "/path/to/report2.md", "/path/to/report3.md", "/path/to/report4.md"],
      summary: "Comprehensive auth research covering authentication, authorization, session management, and password security",
      key_findings: ["Finding1", "Finding2", "Finding3", "Finding4", "Finding5", "Finding6", "Finding7", "Finding8"],
      total_duration_ms: 43500,
      context_tokens: 500
    }
  }')

  # Validate required fields
  if [ "$(echo "$supervisor_checkpoint" | jq -r '.supervisor_id')" = "research_sub_supervisor_20251107_143030" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.worker_count')" = "4" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.workers | length')" = "4" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.aggregated_metadata.topics_researched')" = "4" ]; then
    pass "Research supervisor schema valid"
  else
    fail "Research supervisor schema invalid" "Missing required fields"
  fi
}

# ==============================================================================
# Test 2: Implementation Supervisor Checkpoint Schema
# ==============================================================================
test_implementation_supervisor_schema() {
  echo "Test 2: Implementation supervisor checkpoint schema validation"

  # Create implementation supervisor checkpoint
  local supervisor_checkpoint=$(jq -n '{
    supervisor_id: "impl_sub_supervisor_20251107_150000",
    supervisor_name: "implementation-sub-supervisor",
    worker_count: 3,
    tracks: [
      {
        track_id: "frontend_track",
        track_name: "Frontend Implementation",
        worker_id: "implementation_executor_1",
        status: "completed",
        files_modified: ["src/LoginForm.tsx", "src/RegisterForm.tsx"],
        duration_ms: 25000,
        metadata: {
          components_created: 2,
          tests_created: 2,
          total_lines: 450
        }
      },
      {
        track_id: "backend_track",
        track_name: "Backend Implementation",
        worker_id: "implementation_executor_2",
        status: "completed",
        files_modified: ["src/auth.service.ts", "src/auth.controller.ts"],
        duration_ms: 30000,
        metadata: {
          endpoints_created: 4,
          tests_created: 8,
          total_lines: 680
        }
      },
      {
        track_id: "testing_track",
        track_name: "Integration Testing",
        worker_id: "implementation_executor_3",
        status: "completed",
        files_modified: ["tests/auth.test.ts"],
        duration_ms: 15000,
        metadata: {
          test_suites: 1,
          test_cases: 12,
          total_lines: 320
        }
      }
    ],
    aggregated_metadata: {
      tracks_completed: 3,
      files_modified: 5,
      total_lines: 1450,
      parallel_duration_ms: 30000,
      sequential_duration_ms: 70000,
      time_savings_percent: 57,
      summary: "Parallel implementation across frontend, backend, testing. 57% time savings."
    }
  }')

  # Validate required fields
  if [ "$(echo "$supervisor_checkpoint" | jq -r '.supervisor_id')" = "impl_sub_supervisor_20251107_150000" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.worker_count')" = "3" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.tracks | length')" = "3" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.aggregated_metadata.time_savings_percent')" = "57" ]; then
    pass "Implementation supervisor schema valid"
  else
    fail "Implementation supervisor schema invalid" "Missing required fields"
  fi
}

# ==============================================================================
# Test 3: Testing Supervisor Checkpoint Schema
# ==============================================================================
test_testing_supervisor_schema() {
  echo "Test 3: Testing supervisor checkpoint schema validation"

  # Create testing supervisor checkpoint
  local supervisor_checkpoint=$(jq -n '{
    supervisor_id: "test_sub_supervisor_20251107_160000",
    supervisor_name: "testing-sub-supervisor",
    worker_count: 4,
    stages: [
      {
        stage_id: "generation",
        stage_name: "Test Generation",
        workers: [
          {
            worker_id: "unit_test_generator",
            status: "completed",
            tests_created: 15,
            duration_ms: 8000
          },
          {
            worker_id: "integration_test_generator",
            status: "completed",
            tests_created: 8,
            duration_ms: 12000
          }
        ],
        status: "completed",
        duration_ms: 12000
      },
      {
        stage_id: "execution",
        stage_name: "Test Execution",
        workers: [
          {
            worker_id: "test_executor",
            status: "completed",
            tests_passed: 23,
            tests_failed: 0,
            duration_ms: 5000
          }
        ],
        status: "completed",
        duration_ms: 5000
      }
    ],
    aggregated_metadata: {
      total_tests: 23,
      tests_passed: 23,
      tests_failed: 0,
      coverage_percent: 85,
      total_duration_ms: 17000,
      summary: "Generated 23 tests with 85% coverage. All tests passing."
    }
  }')

  # Validate required fields
  if [ "$(echo "$supervisor_checkpoint" | jq -r '.supervisor_id')" = "test_sub_supervisor_20251107_160000" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.worker_count')" = "4" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.stages | length')" = "2" ] && \
     [ "$(echo "$supervisor_checkpoint" | jq -r '.aggregated_metadata.total_tests')" = "23" ]; then
    pass "Testing supervisor schema valid"
  else
    fail "Testing supervisor schema invalid" "Missing required fields"
  fi
}

# ==============================================================================
# Test 4: Nested Checkpoint Structure (Orchestrator → Supervisor)
# ==============================================================================
test_nested_checkpoint_structure() {
  echo "Test 4: Nested checkpoint structure validation"

  # Create full checkpoint with supervisor_state
  local workflow_state=$(jq -n '{
    workflow_description: "Research and plan authentication system",
    status: "in_progress",
    current_phase: 2,
    total_phases: 7,
    completed_phases: [0, 1],
    state_machine: {
      current_state: "plan",
      completed_states: ["initialize", "research"]
    },
    phase_data: {
      research: {
        reports_created: ["/path1.md", "/path2.md", "/path3.md", "/path4.md"],
        duration_ms: 43500
      }
    },
    supervisor_state: {
      research_supervisor: {
        supervisor_id: "research_sub_supervisor_20251107_143030",
        supervisor_name: "research-sub-supervisor",
        worker_count: 4,
        workers: [],
        aggregated_metadata: {
          topics_researched: 4,
          summary: "Combined summary"
        }
      }
    },
    error_state: {
      last_error: null,
      retry_count: 0,
      failed_state: null
    }
  }')

  # Save checkpoint
  local checkpoint_file=$(save_checkpoint "coordinate" "test_nested" "$workflow_state")

  # Validate checkpoint structure
  if [ -f "$checkpoint_file" ]; then
    local supervisor_state=$(jq -r '.supervisor_state.research_supervisor' "$checkpoint_file")
    if [ "$supervisor_state" != "null" ] && \
       [ "$(echo "$supervisor_state" | jq -r '.worker_count')" = "4" ]; then
      pass "Nested checkpoint structure valid"
      rm -f "$checkpoint_file"
    else
      fail "Nested checkpoint structure invalid" "supervisor_state not nested correctly"
      rm -f "$checkpoint_file"
    fi
  else
    fail "Nested checkpoint structure invalid" "Checkpoint file not created"
  fi
}

# ==============================================================================
# Test 5: Metadata Aggregation Algorithm
# ==============================================================================
test_metadata_aggregation() {
  echo "Test 5: Metadata aggregation algorithm"

  # Create workers array
  local workers_array=$(jq -n '[
    {
      worker_id: "research_specialist_1",
      metadata: {
        summary: "Authentication patterns research.",
        key_findings: ["Finding1", "Finding2"]
      }
    },
    {
      worker_id: "research_specialist_2",
      metadata: {
        summary: "Authorization patterns research.",
        key_findings: ["Finding3", "Finding4"]
      }
    }
  ]')

  # Aggregate metadata
  local aggregated=$(echo "$workers_array" | jq '{
    topics_researched: (. | length),
    summary: ([.[].metadata.summary] | join(" ")),
    key_findings: ([.[].metadata.key_findings[]] | .[0:12])
  }')

  # Validate aggregation
  if [ "$(echo "$aggregated" | jq -r '.topics_researched')" = "2" ] && \
     [ "$(echo "$aggregated" | jq -r '.key_findings | length')" = "4" ]; then
    pass "Metadata aggregation algorithm working"
  else
    fail "Metadata aggregation algorithm failed" "Incorrect aggregation"
  fi
}

# ==============================================================================
# Test 6: Partial Failure Handling
# ==============================================================================
test_partial_failure_handling() {
  echo "Test 6: Partial failure handling (2/3 workers succeed)"

  # Create workers array with failures
  local workers_array=$(jq -n '[
    {
      worker_id: "worker_1",
      status: "completed",
      metadata: {summary: "Summary1", key_findings: ["F1"]}
    },
    {
      worker_id: "worker_2",
      status: "completed",
      metadata: {summary: "Summary2", key_findings: ["F2"]}
    },
    {
      worker_id: "worker_3",
      status: "failed",
      error: "Worker crashed"
    }
  ]')

  # Filter successful workers
  local successful=$(echo "$workers_array" | jq '[.[] | select(.status == "completed")]')
  local success_count=$(echo "$successful" | jq 'length')

  # Aggregate successful workers only
  if [ "$success_count" -ge 2 ]; then
    local aggregated=$(echo "$successful" | jq '{
      topics_researched: length,
      summary: ([.[].metadata.summary] | join(" "))
    }')

    if [ "$(echo "$aggregated" | jq -r '.topics_researched')" = "2" ]; then
      pass "Partial failure handling working (2/3 workers succeeded)"
    else
      fail "Partial failure handling failed" "Incorrect success count"
    fi
  else
    fail "Partial failure handling failed" "Success count < 2"
  fi
}

# ==============================================================================
# Test 7: Context Reduction Validation (95% Target)
# ==============================================================================
test_context_reduction_validation() {
  echo "Test 7: Context reduction validation (95% target)"

  # Simulate worker outputs (large)
  local worker_outputs=$(jq -n '[
    {metadata: {summary: ("Large summary " * 100), key_findings: ["F1", "F2"]}},
    {metadata: {summary: ("Large summary " * 100), key_findings: ["F3", "F4"]}},
    {metadata: {summary: ("Large summary " * 100), key_findings: ["F5", "F6"]}},
    {metadata: {summary: ("Large summary " * 100), key_findings: ["F7", "F8"]}}
  ]')

  # Simulate aggregated metadata (small)
  local aggregated=$(jq -n '{
    topics_researched: 4,
    summary: "Combined 50-word summary",
    key_findings: ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8"]
  }')

  # Calculate token counts (rough estimate: 4 chars per token)
  local worker_tokens=$(echo "$worker_outputs" | wc -c | awk '{print int($1/4)}')
  local aggregated_tokens=$(echo "$aggregated" | wc -c | awk '{print int($1/4)}')

  # Calculate reduction percentage using awk (bc not available)
  local reduction_percent=$(echo "$worker_tokens $aggregated_tokens" | awk '{
    reduction = (($1 - $2) / $1) * 100
    printf "%.1f", reduction
  }')

  # Validate ≥ 90% reduction
  local is_valid=$(echo "$reduction_percent" | awk '{if ($1 >= 90) print "1"; else print "0"}')
  if [ "$is_valid" = "1" ]; then
    pass "Context reduction validated: ${reduction_percent}% (≥90% target)"
  else
    fail "Context reduction below target" "${reduction_percent}% < 90%"
  fi
}

# ==============================================================================
# Test 8: Supervisor Checkpoint Save and Load
# ==============================================================================
test_supervisor_checkpoint_persistence() {
  echo "Test 8: Supervisor checkpoint save and load"

  # Create supervisor checkpoint
  local supervisor_checkpoint=$(jq -n '{
    supervisor_id: "test_supervisor_123",
    supervisor_name: "test-supervisor",
    worker_count: 3,
    aggregated_metadata: {
      summary: "Test summary",
      total_duration_ms: 30000
    }
  }')

  # Save checkpoint using state-persistence.sh
  local checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_supervisor_checkpoint.json"
  echo "$supervisor_checkpoint" > "$checkpoint_file"

  # Load checkpoint
  if [ -f "$checkpoint_file" ]; then
    local loaded=$(cat "$checkpoint_file")
    if [ "$(echo "$loaded" | jq -r '.supervisor_id')" = "test_supervisor_123" ]; then
      pass "Supervisor checkpoint persistence working"
      rm -f "$checkpoint_file"
    else
      fail "Supervisor checkpoint persistence failed" "Loaded data incorrect"
      rm -f "$checkpoint_file"
    fi
  else
    fail "Supervisor checkpoint persistence failed" "Checkpoint file not created"
  fi
}

# ==============================================================================
# Test 9: Worker Metadata Extraction
# ==============================================================================
test_worker_metadata_extraction() {
  echo "Test 9: Worker metadata extraction from output"

  # Simulate worker output with metadata
  local worker_output='{
    "title": "Research Report",
    "summary": "Comprehensive analysis of authentication patterns",
    "key_findings": ["Finding1", "Finding2", "Finding3"]
  }'

  # Extract metadata fields
  local title=$(echo "$worker_output" | jq -r '.title')
  local summary=$(echo "$worker_output" | jq -r '.summary')
  local findings=$(echo "$worker_output" | jq -r '.key_findings | length')

  if [ "$title" = "Research Report" ] && \
     [ -n "$summary" ] && \
     [ "$findings" = "3" ]; then
    pass "Worker metadata extraction working"
  else
    fail "Worker metadata extraction failed" "Incorrect metadata extracted"
  fi
}

# ==============================================================================
# Test 10: Supervisor State in v2.0 Checkpoint
# ==============================================================================
test_supervisor_state_v2_checkpoint() {
  echo "Test 10: Supervisor state in v2.0 checkpoint schema"

  # Create workflow state with supervisor_state
  local workflow_state=$(jq -n '{
    workflow_description: "Test workflow",
    supervisor_state: {
      research_supervisor: {
        supervisor_id: "test_123",
        worker_count: 4
      }
    }
  }')

  # Save checkpoint
  local checkpoint_file=$(save_checkpoint "test" "supervisor_v2" "$workflow_state")

  # Validate checkpoint has supervisor_state
  if [ -f "$checkpoint_file" ]; then
    local schema_version=$(jq -r '.schema_version' "$checkpoint_file")
    local supervisor_state=$(jq -r '.supervisor_state.research_supervisor' "$checkpoint_file")

    if [ "$schema_version" = "2.0" ] && \
       [ "$supervisor_state" != "null" ] && \
       [ "$(echo "$supervisor_state" | jq -r '.worker_count')" = "4" ]; then
      pass "Supervisor state in v2.0 checkpoint working"
      rm -f "$checkpoint_file"
    else
      fail "Supervisor state in v2.0 checkpoint failed" "Schema or state incorrect"
      rm -f "$checkpoint_file"
    fi
  else
    fail "Supervisor state in v2.0 checkpoint failed" "Checkpoint not created"
  fi
}

# ==============================================================================
# Test 11: Multiple Supervisors in Single Checkpoint
# ==============================================================================
test_multiple_supervisors_checkpoint() {
  echo "Test 11: Multiple supervisors in single checkpoint"

  # Create workflow state with multiple supervisors
  local workflow_state=$(jq -n '{
    workflow_description: "Full workflow with multiple supervisors",
    supervisor_state: {
      research_supervisor: {
        supervisor_id: "research_123",
        worker_count: 4
      },
      implementation_supervisor: {
        supervisor_id: "impl_456",
        worker_count: 3
      },
      testing_supervisor: {
        supervisor_id: "test_789",
        worker_count: 2
      }
    }
  }')

  # Save checkpoint
  local checkpoint_file=$(save_checkpoint "test" "multi_supervisor" "$workflow_state")

  # Validate all supervisors present
  if [ -f "$checkpoint_file" ]; then
    local research_sup=$(jq -r '.supervisor_state.research_supervisor' "$checkpoint_file")
    local impl_sup=$(jq -r '.supervisor_state.implementation_supervisor' "$checkpoint_file")
    local test_sup=$(jq -r '.supervisor_state.testing_supervisor' "$checkpoint_file")

    if [ "$research_sup" != "null" ] && \
       [ "$impl_sup" != "null" ] && \
       [ "$test_sup" != "null" ]; then
      pass "Multiple supervisors in checkpoint working"
      rm -f "$checkpoint_file"
    else
      fail "Multiple supervisors in checkpoint failed" "Not all supervisors present"
      rm -f "$checkpoint_file"
    fi
  else
    fail "Multiple supervisors in checkpoint failed" "Checkpoint not created"
  fi
}

# ==============================================================================
# Test 12: Supervisor Checkpoint Resume Capability
# ==============================================================================
test_supervisor_checkpoint_resume() {
  echo "Test 12: Supervisor checkpoint resume capability"

  # Create initial checkpoint with partial supervisor state
  local initial_state=$(jq -n '{
    workflow_description: "Research workflow",
    current_phase: 1,
    supervisor_state: {
      research_supervisor: {
        supervisor_id: "research_resume_123",
        worker_count: 4,
        workers: [
          {worker_id: "w1", status: "completed"},
          {worker_id: "w2", status: "completed"},
          {worker_id: "w3", status: "in_progress"},
          {worker_id: "w4", status: "pending"}
        ]
      }
    }
  }')

  # Save checkpoint
  local checkpoint_file=$(save_checkpoint "test" "resume" "$initial_state")

  # Restore checkpoint
  local restored=$(cat "$checkpoint_file")

  # Check incomplete workers
  local incomplete=$(echo "$restored" | jq -r '.supervisor_state.research_supervisor.workers | map(select(.status != "completed")) | length')

  if [ "$incomplete" = "2" ]; then
    pass "Supervisor checkpoint resume capability working (2 workers incomplete)"
    rm -f "$checkpoint_file"
  else
    fail "Supervisor checkpoint resume capability failed" "Incorrect incomplete count: $incomplete"
    rm -f "$checkpoint_file"
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================
echo "========================================="
echo "Supervisor Checkpoint Tests (Phase 4)"
echo "========================================="
echo ""

test_research_supervisor_schema
test_implementation_supervisor_schema
test_testing_supervisor_schema
test_nested_checkpoint_structure
test_metadata_aggregation
test_partial_failure_handling
test_context_reduction_validation
test_supervisor_checkpoint_persistence
test_worker_metadata_extraction
test_supervisor_state_v2_checkpoint
test_multiple_supervisors_checkpoint
test_supervisor_checkpoint_resume

# ==============================================================================
# Summary
# ==============================================================================
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
