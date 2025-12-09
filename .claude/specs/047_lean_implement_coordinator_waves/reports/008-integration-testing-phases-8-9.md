# Integration Testing Strategy for Phases 8-9 Research Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Integration testing strategy for plan revision workflow and wave-based parallel execution
- **Report Type**: codebase analysis

## Executive Summary

This research analyzes integration testing requirements for Phases 8-9 of the lean-implement coordinator waves refactoring. Phase 8 adds coordinator-triggered plan revision workflows, while Phase 9 transforms the command from sequential per-phase routing to wave-based full plan delegation. The existing integration test suite provides strong coverage for Phases 0-7 (phase detection, context tracking, checkpoint resume), but lacks test scenarios for the deferred architectural transformations. The research identifies test fixture design patterns, timing measurement strategies, and automation compliance requirements for completing comprehensive integration testing.

## Findings

### Finding 1: Existing Integration Test Coverage (Phases 0-7)

- **Description**: The existing integration test suite validates all implemented functionality from Phases 0-7, with 11 test cases covering critical behaviors
- **Location**: `/home/benjamin/.config/.claude/tests/integration/test_lean_implement_coordinator_waves.sh` (lines 1-548)
- **Evidence**: Test suite structure:
  ```bash
  # Test 1: Phase 0 detection in /lean-implement (lines 163-195)
  test_phase_0_detection_lean_implement()

  # Test 2: Phase 0 detection in /implement (lines 197-217)
  test_phase_0_detection_implement()

  # Test 3: Checkpoint utilities integration (lines 219-253)
  test_checkpoint_integration()

  # Test 4: Context threshold monitoring (lines 255-281)
  test_context_threshold()

  # Test 5: Validation utils integration (lines 283-310)
  test_validation_utils()

  # Test 6: Task invocation standards compliance (lines 312-339)
  test_task_invocation_compliance()

  # Test 7: Dependency recalculation utility (lines 341-376)
  test_dependency_recalculation_utility()

  # Test 8: Iteration context passing (lines 378-404)
  test_iteration_context()

  # Test 9: Defensive continuation validation (lines 406-432)
  test_defensive_validation()

  # Test 10: Error logging integration (lines 434-460)
  test_error_logging()

  # Test 11: Plan fixture generation (lines 462-490)
  test_plan_fixtures()
  ```
- **Impact**: Strong baseline coverage for completed phases, but requires extension for Phases 8-9 functionality

### Finding 2: Unit Test Infrastructure for Dependency Recalculation

- **Description**: The dependency recalculation utility has comprehensive unit test coverage with 7 test cases validating wave calculation logic
- **Location**: `/home/benjamin/.config/.claude/tests/unit/test_dependency_recalculation.sh` (lines 1-224)
- **Evidence**: Unit test cases demonstrating test fixture patterns:
  ```bash
  # Test 1: Simple dependency chain (lines 49-94)
  test_simple_dependency_chain()
  # - Creates plan with phases 1->2->3,4 dependencies
  # - Validates wave calculation after phase 1 complete (returns phase 2)
  # - Validates parallel wave after phases 1,2 complete (returns phases 3,4)

  # Test 2: Complex decimal phase dependencies (lines 96-127)
  test_complex_dependencies()
  # - Uses phase numbers: 0, 0.5, 1, 2, 3
  # - Validates chained dependencies with decimal phases

  # Test 3: No dependencies (full parallel) (lines 129-153)
  test_no_dependencies()
  # - All phases have depends_on: []
  # - Validates all phases return in first wave

  # Test 4: Empty completed phases (lines 155-174)
  test_empty_completed_phases()
  # - Validates initial wave calculation with no completed work

  # Test 5: Phase status markers (lines 176-199)
  test_phase_status_markers()
  # - Validates detection of [COMPLETE] markers vs explicit completed_phases
  ```
- **Impact**: Provides reusable test fixture creation patterns (`create_test_plan()` function) for integration test expansion

### Finding 3: Test Fixture Design Patterns from Existing Suite

- **Description**: The integration test suite demonstrates three distinct test fixture patterns for different validation scenarios
- **Location**: `/home/benjamin/.config/.claude/tests/integration/test_lean_implement_coordinator_waves.sh` (lines 18-140)
- **Evidence**: Fixture creation functions:
  ```bash
  # Pattern 1: Phase 0 detection fixture (lines 18-61)
  create_test_plan_with_phase_0() {
    # Contains Phase 0 [NOT STARTED], Phase 1 [COMPLETE], Phase 2 [NOT STARTED]
    # Tests auto-detection finds lowest incomplete phase (Phase 0)
  }

  # Pattern 2: Normal numbering fixture (lines 63-93)
  create_test_plan_without_phase_0() {
    # Contains Phase 1, Phase 2 (no phase 0)
    # Tests no regression in standard phase numbering
  }

  # Pattern 3: Mixed Lean/software fixture (lines 95-140)
  create_mixed_lean_software_plan() {
    # Contains both Lean phases (with **Lean File** metadata)
    # and software phases (no Lean file)
    # Tests dual coordinator routing logic
  }
  ```
- **Impact**: Established patterns for creating realistic plan fixtures with metadata fields, dependency structures, and phase status markers

### Finding 4: Gap Analysis for Phase 8 Testing (Plan Revision Workflow)

- **Description**: Phase 8 requires testing coordinator-triggered plan revision, but no test fixtures or scenarios exist for blocking dependency detection or revision depth limits
- **Location**: Plan specification at `/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/plans/001-lean-implement-coordinator-waves-plan.md` (lines 638-722)
- **Evidence**: Phase 8 validation requirements (lines 717-721):
  ```markdown
  ### Validation
  - Integration test: Lean plan with theorems requiring missing lemmas triggers revision
  - Integration test: Plan revision adds new phase with depends_on metadata
  - Integration test: Wave recalculation identifies newly available phases
  - Unit test: Revision depth counter enforces MAX_REVISION_DEPTH limit
  - Integration test: Context budget check skips revision when tokens < 30,000
  ```

  Missing test fixtures:
  1. Lean plan with theorems_partial field populated (blocking theorems)
  2. Mock lean-implementer output with diagnostic messages ("blocked on lemma X")
  3. Plan revision workflow simulation (triggering /revise command)
  4. Revision depth counter state management test
  5. Context budget threshold test (require >= 30,000 tokens remaining)
- **Impact**: Phase 8 testing cannot proceed until these test fixtures and scenarios are designed

### Finding 5: Gap Analysis for Phase 9 Testing (Wave-Based Delegation)

- **Description**: Phase 9 requires testing parallel wave execution with timing measurement, but the architectural transformation is deferred
- **Location**: Plan specification (lines 724-831)
- **Evidence**: Phase 9 validation requirements (lines 827-831):
  ```markdown
  ### Validation
  - Integration test: Plan with 5 phases (3 Lean, 2 software), verify waves calculated correctly
  - Integration test: Independent phases execute in parallel (verify Task invocation timing)
  - Performance test: Measure time savings vs sequential execution (expect 40-60% for 2+ parallel phases)
  - Integration test: Iteration loop triggers only on context threshold, not per-phase
  ```

  Testing challenges:
  1. **Timing measurement**: Requires instrumentation to measure Task invocation parallelism
  2. **Wave calculation verification**: Dependency-analyzer.sh integration testing
  3. **Coordinator delegation pattern**: Full plan delegation vs current per-phase routing
  4. **Baseline comparison**: Need sequential execution timing for comparison
  5. **Mock coordinator responses**: Simulate wave completion without full Lean/software execution
- **Impact**: Phase 9 testing requires mock infrastructure for coordinator responses and timing instrumentation

### Finding 6: Non-Interactive Testing Standard Compliance

- **Description**: The non-interactive testing standard defines strict requirements for automated test phases, applicable to Phases 8-9 test design
- **Location**: `/home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md` (lines 1-370)
- **Evidence**: Required automation metadata fields (lines 18-75):
  ```yaml
  automation_type: automated  # NOT manual
  validation_method: programmatic  # NOT visual
  skip_allowed: false  # Testing is mandatory
  artifact_outputs:
    - test-results.xml
    - coverage-report.json
    - test-execution.log
  ```

  Prohibited anti-patterns (lines 131-168):
  - "manually verify" - requires programmatic validation
  - "skip if needed" - all tests mandatory
  - "verify visually" - requires structured artifact output
  - "inspect output" - requires exit code validation
  - "optional" - testing cannot be conditional
  - "check results" - requires automated success criteria

  Exit code semantics (lines 78-92):
  ```bash
  # Good: Clear success/failure exit codes
  pytest tests/ --cov=src --cov-report=json || exit 1

  # Bad: No exit code validation
  pytest tests/  # continues even if tests fail
  ```
- **Impact**: All Phase 8-9 integration tests MUST follow programmatic validation patterns with exit code checking and structured artifact outputs

### Finding 7: Checkpoint Save/Resume Test Automation Patterns

- **Description**: The checkpoint-utils.sh integration test validates checkpoint save logic but lacks resume workflow end-to-end testing
- **Location**: Integration test suite (lines 219-253)
- **Evidence**: Current checkpoint test coverage:
  ```bash
  test_checkpoint_integration() {
    # ✓ Validates checkpoint-utils.sh library exists
    # ✓ Validates library sourcing in lean-implement command
    # ✓ Validates save_checkpoint usage
    # ~ Partial: Checks for --resume flag (notes "optional Phase 4 feature")
    # ✗ Missing: End-to-end checkpoint save/resume cycle test
    # ✗ Missing: State restoration validation (PLAN_FILE, ITERATION, etc.)
    # ✗ Missing: Context threshold trigger test (CONTEXT_USAGE_PERCENT >= 90)
  }
  ```

  Required additions for Phase 8-9 testing:
  1. **Checkpoint trigger test**: Set CONTEXT_THRESHOLD=50, run coordinator, verify checkpoint saves when threshold exceeded
  2. **Resume workflow test**: Load saved checkpoint, verify all state variables restored correctly
  3. **Iteration counter test**: Resume from checkpoint, verify ITERATION increments correctly
  4. **Checkpoint schema validation**: Verify v2.1 schema fields present (plan_path, topic_path, iteration, work_remaining, context_usage_percent, completed_phases)
  5. **Checkpoint deletion test**: Verify checkpoint cleaned up on workflow completion
- **Impact**: Checkpoint resume testing pattern required for Phase 8-9 integration scenarios where plan revision may exceed context limits

### Finding 8: Timing Measurement Strategies for Parallel Execution

- **Description**: No existing timing instrumentation exists in the codebase for measuring parallel Task invocation performance
- **Location**: Research analysis (no existing implementation)
- **Evidence**: Required timing measurement approaches:

  **Approach 1: Bash time command with SECONDS variable**
  ```bash
  # Baseline: Sequential execution timing
  SECONDS=0
  # Execute phase 1
  # Execute phase 2
  # Execute phase 3
  SEQUENTIAL_TIME=$SECONDS

  # Wave-based: Parallel execution timing
  SECONDS=0
  # Execute wave 1 (phases 1,2,3 in parallel via multiple Task calls)
  WAVE_TIME=$SECONDS

  # Calculate savings
  TIME_SAVINGS=$(echo "scale=2; (1 - $WAVE_TIME/$SEQUENTIAL_TIME) * 100" | bc)
  echo "Time savings: ${TIME_SAVINGS}%"
  ```

  **Approach 2: Mock coordinator responses with simulated delays**
  ```bash
  # Mock lean-implementer with configurable execution time
  mock_lean_implementer_response() {
    local phase="$1"
    local delay_seconds="${2:-5}"  # Default 5s per phase

    sleep "$delay_seconds"
    cat > "$OUTPUT_PATH" <<EOF
  summary_brief: Completed phase $phase
  phases_completed: $phase
  work_remaining:
  context_usage_percent: 30
  requires_continuation: false
  EOF
  }
  ```

  **Approach 3: Timestamp-based wave duration tracking**
  ```bash
  # Log wave start/end timestamps
  WAVE_START=$(date +%s)
  # Execute wave phases
  WAVE_END=$(date +%s)
  WAVE_DURATION=$((WAVE_END - WAVE_START))

  echo "Wave 1 duration: ${WAVE_DURATION}s"
  ```
- **Impact**: Timing instrumentation must be designed for Phase 9 performance validation (40-60% time savings claim)

### Finding 9: Plan Revision Cycle Testing with Blocking Dependency Injection

- **Description**: Phase 8 requires testing automated plan revision triggered by blocking dependencies, but no injection mechanism exists
- **Location**: Plan specification (lines 662-714)
- **Evidence**: Plan revision workflow requirements:

  **Blocking Detection Pattern** (from Phase 8 implementation notes):
  ```yaml
  # lean-implementer output signal with blocking theorems
  theorems_partial: theorem_1 theorem_2
  diagnostics:
    - "theorem_1: blocked on lemma ListAppendAssoc"
    - "theorem_2: blocked on lemma NatAddComm"
  ```

  **Test Fixture Design Requirements**:
  1. **Mock lean-implementer with theorems_partial**: Create fixture that simulates incomplete proof output
  2. **Blocking dependency extraction**: Parse diagnostics field for "blocked on" patterns
  3. **/revise command simulation**: Mock Task delegation to plan-architect for revision
  4. **Plan mutation validation**: Verify revised plan has new infrastructure phase with depends_on metadata
  5. **Wave recalculation after revision**: Call dependency-recalculation.sh with updated plan, verify new waves
  6. **Revision depth limit**: Test MAX_REVISION_DEPTH=2 enforcement (reject third revision)

  **Test Scenario Structure**:
  ```bash
  test_plan_revision_cycle() {
    # 1. Create plan with Lean phases
    # 2. Mock lean-implementer response with theorems_partial field
    # 3. Inject blocking dependency diagnostics
    # 4. Trigger lean-coordinator (should detect blocking and call /revise)
    # 5. Verify revised plan has new infrastructure phase
    # 6. Verify dependency recalculation returns updated waves
    # 7. Test revision depth counter (increment to 2, reject 3rd)
  }
  ```
- **Impact**: Comprehensive test fixture design required for Phase 8 validation, including mock subagent responses and plan mutation tracking

### Finding 10: Wave Execution Metrics Collection and Validation

- **Description**: Phase 9 success criteria require collecting and validating wave execution metrics (total waves, parallel phases, time savings)
- **Location**: Plan specification (lines 746-748)
- **Evidence**: Required completion summary fields:
  ```bash
  # Wave execution metrics to collect
  echo "Wave execution summary:"
  echo "  Total waves executed: $TOTAL_WAVES"
  echo "  Parallel phases per wave: $PARALLEL_PHASES_COUNT"
  echo "  Estimated time savings: ${TIME_SAVINGS_PERCENT}%"
  echo "  Sequential baseline: ${SEQUENTIAL_TIME}s"
  echo "  Wave-based actual: ${WAVE_TIME}s"
  ```

  **Metrics Validation Pattern**:
  ```bash
  # Test: Plan with 5 phases (2 independent waves)
  # Wave 1: Phases 1,2 (parallel, no dependencies)
  # Wave 2: Phases 3,4,5 (parallel, depend on wave 1)

  # Expected metrics:
  EXPECTED_TOTAL_WAVES=2
  EXPECTED_PARALLEL_PHASES_WAVE1=2
  EXPECTED_PARALLEL_PHASES_WAVE2=3
  EXPECTED_TIME_SAVINGS=40  # Minimum 40% for 2+ parallel phases

  # Validation:
  if [ "$TOTAL_WAVES" -ne "$EXPECTED_TOTAL_WAVES" ]; then
    echo "ERROR: Expected $EXPECTED_TOTAL_WAVES waves, got $TOTAL_WAVES"
    exit 1
  fi

  if [ "$TIME_SAVINGS_PERCENT" -lt 40 ]; then
    echo "ERROR: Time savings ${TIME_SAVINGS_PERCENT}% below 40% threshold"
    exit 1
  fi
  ```

  **Artifact Output Requirements** (per non-interactive testing standard):
  ```yaml
  artifact_outputs:
    - wave-execution-metrics.json
    - timing-baseline.txt
    - wave-execution.log
  ```
- **Impact**: Metrics collection infrastructure required for Phase 9 performance validation and 40-60% time savings verification

## Recommendations

### Recommendation 1: Extend Integration Test Suite with Phase 8 Scenarios

**Priority**: High
**Rationale**: Phase 8 testing depends on coordinator-triggered plan revision workflow validation

**Implementation Steps**:
1. Create `test_plan_revision_workflow()` function in integration test suite
2. Design test fixture with mock lean-implementer output containing `theorems_partial` field
3. Implement blocking dependency injection pattern ("blocked on lemma X")
4. Add plan mutation tracking to verify revised plan structure
5. Validate dependency recalculation after plan revision
6. Test revision depth counter (MAX_REVISION_DEPTH=2 enforcement)
7. Test context budget check (skip revision when tokens < 30,000)

**Example Test Structure**:
```bash
test_plan_revision_workflow() {
  echo "Testing coordinator-triggered plan revision..."

  # Create Lean plan with incomplete theorems
  local test_plan="${TEST_WORKSPACE}/lean_blocking.md"
  create_lean_plan_with_dependencies "$test_plan"

  # Mock lean-implementer response with blocking theorems
  local mock_output="${TEST_WORKSPACE}/lean_implementer_output.md"
  cat > "$mock_output" <<EOF
summary_brief: Partial completion - 2 theorems blocked
phases_completed:
work_remaining: Phase 1
context_usage_percent: 45
requires_continuation: true
theorems_partial: theorem_1 theorem_2
diagnostics:
  - "theorem_1: blocked on lemma ListAppendAssoc"
  - "theorem_2: blocked on lemma NatAddComm"
EOF

  # Trigger lean-coordinator (should detect blocking)
  # (Test implementation TBD - requires coordinator mock)

  # Verify plan revision triggered
  if ! grep -q "Phase 0.5: Infrastructure" "$test_plan"; then
    echo "ERROR: Plan revision did not add infrastructure phase"
    return 1
  fi

  # Verify dependency recalculation
  source "${PROJECT_DIR}/.claude/lib/plan/dependency-recalculation.sh"
  NEXT_WAVE=$(recalculate_wave_dependencies "$test_plan" "0")

  if [ "$NEXT_WAVE" != "0.5" ]; then
    echo "ERROR: Expected wave 0.5 after revision, got: $NEXT_WAVE"
    return 1
  fi

  echo "✓ Plan revision workflow validated"
  return 0
}
```

### Recommendation 2: Design Timing Instrumentation for Phase 9 Validation

**Priority**: High
**Rationale**: 40-60% time savings claim requires empirical measurement with baseline comparison

**Implementation Steps**:
1. Add timing instrumentation to integration test suite using Bash `SECONDS` variable
2. Create sequential baseline execution mode (execute phases one-by-one)
3. Create wave-based execution mode (execute phases in parallel within waves)
4. Collect timing data for both modes with identical mock coordinator responses
5. Calculate time savings percentage with programmatic threshold validation
6. Generate timing artifacts (JSON format for metrics, text logs for debugging)

**Example Timing Pattern**:
```bash
test_wave_based_timing() {
  echo "Testing wave-based parallel execution timing..."

  # Configure mock response delay (5 seconds per phase)
  MOCK_DELAY=5

  # Baseline: Sequential execution
  SECONDS=0
  mock_execute_phase 1 "$MOCK_DELAY"
  mock_execute_phase 2 "$MOCK_DELAY"
  mock_execute_phase 3 "$MOCK_DELAY"
  SEQUENTIAL_TIME=$SECONDS

  # Wave-based: Parallel execution
  # Wave 1: Phases 1,2 (parallel - should take ~5s, not 10s)
  # Wave 2: Phase 3 (depends on wave 1 - should take ~5s)
  SECONDS=0
  mock_execute_wave 1 "1 2" "$MOCK_DELAY"  # Parallel invocation
  mock_execute_wave 2 "3" "$MOCK_DELAY"
  WAVE_TIME=$SECONDS

  # Calculate time savings
  TIME_SAVINGS=$(echo "scale=2; (1 - $WAVE_TIME/$SEQUENTIAL_TIME) * 100" | bc)

  # Validate 40% minimum savings
  if (( $(echo "$TIME_SAVINGS < 40" | bc -l) )); then
    echo "ERROR: Time savings ${TIME_SAVINGS}% below 40% threshold"
    return 1
  fi

  # Generate metrics artifact
  cat > "${TEST_WORKSPACE}/wave-metrics.json" <<EOF
{
  "sequential_time_seconds": $SEQUENTIAL_TIME,
  "wave_time_seconds": $WAVE_TIME,
  "time_savings_percent": $TIME_SAVINGS,
  "total_waves": 2,
  "parallel_phases": [2, 1],
  "test_timestamp": "$(date -Iseconds)"
}
EOF

  echo "✓ Wave-based timing validated (${TIME_SAVINGS}% savings)"
  return 0
}
```

### Recommendation 3: Implement Mock Coordinator Response Infrastructure

**Priority**: Medium
**Rationale**: Integration testing requires realistic coordinator responses without full Lean/software execution

**Implementation Steps**:
1. Create `mock_coordinator_response()` helper function accepting phase number, delay, output fields
2. Generate standardized output signal format (summary_brief, phases_completed, work_remaining, context_usage_percent, requires_continuation)
3. Support configurable execution delays for timing tests
4. Add fixture templates for common scenarios (success, partial completion, blocking dependencies)
5. Integrate with existing test fixture creation functions

**Example Mock Infrastructure**:
```bash
mock_coordinator_response() {
  local output_file="$1"
  local phase="$2"
  local status="${3:-complete}"  # complete|partial|blocked
  local delay="${4:-0}"

  # Simulate execution delay
  if [ "$delay" -gt 0 ]; then
    sleep "$delay"
  fi

  # Generate response based on status
  case "$status" in
    complete)
      cat > "$output_file" <<EOF
summary_brief: Phase $phase completed successfully
phases_completed: $phase
work_remaining:
context_usage_percent: 30
requires_continuation: false
EOF
      ;;

    partial)
      cat > "$output_file" <<EOF
summary_brief: Phase $phase partially completed
phases_completed:
work_remaining: Phase $phase
context_usage_percent: 75
requires_continuation: true
EOF
      ;;

    blocked)
      cat > "$output_file" <<EOF
summary_brief: Phase $phase blocked on dependencies
phases_completed:
work_remaining: Phase $phase
context_usage_percent: 45
requires_continuation: true
theorems_partial: theorem_1
diagnostics:
  - "theorem_1: blocked on lemma RequiredLemma"
EOF
      ;;
  esac
}

# Usage in tests
mock_coordinator_response "${TEST_WORKSPACE}/phase1.md" 1 "complete" 5
mock_coordinator_response "${TEST_WORKSPACE}/phase2.md" 2 "blocked" 3
```

### Recommendation 4: Add Checkpoint Resume End-to-End Test

**Priority**: Medium
**Rationale**: Checkpoint save logic is implemented but resume workflow lacks comprehensive validation

**Implementation Steps**:
1. Extend `test_checkpoint_integration()` with checkpoint save trigger test
2. Add checkpoint schema v2.1 validation (verify all required fields present)
3. Implement checkpoint load and state restoration test
4. Validate ITERATION counter increment on resume
5. Test checkpoint deletion on workflow completion
6. Add context threshold trigger test (CONTEXT_THRESHOLD=50, verify save when exceeded)

**Example Checkpoint Resume Test**:
```bash
test_checkpoint_resume_workflow() {
  echo "Testing checkpoint save/resume workflow..."

  local test_plan="${TEST_WORKSPACE}/checkpoint_test.md"
  create_test_plan_with_phase_0 "$test_plan"

  # Simulate context threshold exceeded (trigger checkpoint save)
  local checkpoint_data=$(jq -n \
    --arg plan_path "$test_plan" \
    --arg topic_path "${TEST_WORKSPACE}" \
    --argjson iteration 2 \
    --argjson max_iterations 5 \
    --arg work_remaining "Phase 2" \
    --argjson context_usage 95 \
    --arg completed_phases "0 1" \
    --arg coordinator_name "lean-coordinator" \
    '{
      version: "2.1",
      plan_path: $plan_path,
      topic_path: $topic_path,
      iteration: $iteration,
      max_iterations: $max_iterations,
      work_remaining: $work_remaining,
      context_usage_percent: $context_usage,
      completed_phases: $completed_phases,
      coordinator_name: $coordinator_name
    }')

  # Save checkpoint
  local checkpoint_file="${TEST_WORKSPACE}/checkpoint_test.json"
  echo "$checkpoint_data" > "$checkpoint_file"

  # Validate checkpoint schema
  if ! jq -e '.version == "2.1"' "$checkpoint_file" >/dev/null; then
    echo "ERROR: Invalid checkpoint version"
    return 1
  fi

  # Simulate resume: Load checkpoint and restore state
  PLAN_FILE=$(jq -r '.plan_path' "$checkpoint_file")
  ITERATION=$(jq -r '.iteration' "$checkpoint_file")
  COMPLETED_PHASES=$(jq -r '.completed_phases' "$checkpoint_file")

  # Verify state restoration
  if [ "$ITERATION" != "2" ]; then
    echo "ERROR: ITERATION not restored correctly (expected 2, got $ITERATION)"
    return 1
  fi

  if [ "$COMPLETED_PHASES" != "0 1" ]; then
    echo "ERROR: COMPLETED_PHASES not restored correctly"
    return 1
  fi

  echo "✓ Checkpoint resume workflow validated"
  return 0
}
```

### Recommendation 5: Create Phase 8-9 Documentation Update Plan

**Priority**: Low (depends on Phase 8-9 implementation completion)
**Rationale**: Documentation updates cannot be completed until architectural transformations are implemented

**Implementation Steps**:
1. Document wave-based orchestration pattern in `/lean-implement.md` (add new section after current behavioral guidelines)
2. Document phase 0 auto-detection in both `/lean-implement.md` and `/implement.md` (add to argument parsing section)
3. Add lean-implement coordinator pattern example to `CLAUDE.md` hierarchical agent examples
4. Create success example documentation linking to `lean-implement-output.md` with metrics
5. Document checkpoint resume workflow with `--resume` flag examples
6. Add plan revision cycle documentation with MAX_REVISION_DEPTH explanation

**Documentation Structure**:
```markdown
## Wave-Based Orchestration

The /lean-implement command uses wave-based parallel execution via the lean-coordinator agent, achieving 40-60% time savings for plans with independent phases.

### Wave Calculation

Waves are calculated by dependency-analyzer.sh using the plan's depends_on metadata:

- **Wave 1**: All phases with no dependencies (depends_on: [])
- **Wave 2**: All phases whose dependencies are in Wave 1
- **Wave N**: All phases whose dependencies are in Waves 1 through N-1

### Parallel Execution Pattern

Within each wave, the coordinator invokes multiple lean-implementer subagents in parallel via multiple Task calls in a single response:

[Example with code snippet]

### Performance Metrics

Wave-based execution provides significant time savings:
- 2 parallel phases: ~50% time savings
- 3+ parallel phases: ~60% time savings
- Sequential phases: No parallelization overhead
```

## References

- `/home/benjamin/.config/.claude/tests/integration/test_lean_implement_coordinator_waves.sh` (lines 1-548) - Existing integration test suite structure
- `/home/benjamin/.config/.claude/tests/unit/test_dependency_recalculation.sh` (lines 1-224) - Unit test patterns and fixture creation
- `/home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/plans/001-lean-implement-coordinator-waves-plan.md` (lines 638-831) - Phase 8-9 validation requirements
- `/home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md` (lines 1-370) - Automation compliance requirements
- `/home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh` (entire file) - Wave calculation implementation
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-813) - Research specialist behavioral guidelines
