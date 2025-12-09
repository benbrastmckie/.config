# Implementation Plan: Remaining Phases 8-9-10 for Lean-Implement Coordinator Waves

## Metadata
- **Date**: 2025-12-09
- **Feature**: Implement coordinator-triggered plan revision workflow, wave-based full plan delegation, and comprehensive integration testing for lean-implement coordinator wave-based orchestration
- **Status**: [NOT STARTED]
- **Estimated Hours**: 12-15 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinator-Triggered Plan Revision Workflow Analysis](../reports/006-plan-revision-workflow.md)
  - [Wave-Based Full Plan Delegation Architecture Research](../reports/007-wave-based-delegation.md)
  - [Integration Testing Strategy for Phases 8-9 Research Report](../reports/008-integration-testing-phases-8-9.md)
- **Original Plan**: /home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/plans/001-lean-implement-coordinator-waves-plan.md

---

## Overview

This plan implements the three deferred phases from spec 047: coordinator-triggered plan revision (Phase 8), wave-based full plan delegation (Phase 9), and comprehensive integration testing (Phase 10). These phases were deferred from the original plan due to architectural complexity and high-risk refactoring requirements.

**Architectural Context**:
- **Phases 0-7**: Complete (83% of original scope) - Standards compliance, phase detection, context tracking, checkpoint resume, dependency recalculation utility
- **Phase 8**: Coordinator-triggered plan revision when blocking dependencies discovered (enhancement feature, separate spec recommended)
- **Phase 9**: Transform from per-phase routing to full plan delegation with wave-based parallel execution (high-risk refactor, 40-60% time savings)
- **Phase 10**: Integration testing for all phases including Phase 8-9 workflows

**Key Problems Addressed**:
1. **Plan Revision Workflow Gap**: Blocking dependencies discovered by lean-implementer don't trigger automated plan modification
2. **Sequential Execution Limitation**: Current per-phase routing misses 40-60% time savings from wave-based parallelization
3. **Integration Test Coverage**: No end-to-end testing for dual coordinator workflow, checkpoint resume, or plan revision cycles

**Solution Approach**:
- Phase 8: Add blocking detection to lean-coordinator, integrate /revise Task delegation, recalculate waves after plan mutation
- Phase 9: Refactor Block 1a/1b to pass full plan (not single phase), implement wave execution loop in lean-coordinator
- Phase 10: Create comprehensive integration test suite with timing instrumentation, checkpoint save/resume validation, and plan revision cycle testing

**Success Criteria**:
- [ ] Automated plan revision triggered when theorems_partial count > 0 and context budget available (>= 30k tokens)
- [ ] Wave-based parallel execution for independent Lean/software phases (40-60% time savings measured)
- [ ] Integration test suite validates phase 0 detection, dual coordinator workflow, checkpoint resume, and plan revision cycles
- [ ] MAX_REVISION_DEPTH=2 limit prevents infinite revision loops
- [ ] Context threshold (default 90%) triggers checkpoint save with v2.1 schema
- [ ] Dependency recalculation after plan revision enables dynamic wave updates

---

## Phase 8: Implement Coordinator-Triggered Plan Revision Workflow [NOT STARTED]

**Dependencies**: depends_on: []
**Estimated Time**: 4-5 hours

### Objective
Add automated plan revision workflow to lean-coordinator that detects blocking dependencies from lean-implementer output, triggers /revise command via Task delegation, and recalculates wave dependencies after plan mutation.

### Complexity
High - Requires lean-coordinator behavioral changes, error handling for revision failures, revision depth tracking, and context budget management

### Tasks
- [ ] Add blocking detection logic to lean-coordinator.md after implementer output parsing (STEP 3.5)
- [ ] Implement context budget calculation function: get_context_usage() with defensive error handling
- [ ] Add revision depth counter to workflow state initialization (MAX_REVISION_DEPTH=2)
- [ ] Create revision trigger conditional block with context budget check (>= 30,000 tokens required)
- [ ] Add Task invocation to lean-coordinator for /revise command with blocking summary prompt
- [ ] Implement dependency recalculation call after revision: source dependency-recalculation.sh and invoke recalculate_wave_dependencies()
- [ ] Update lean-coordinator output signal with revision_triggered, revision_depth, revised_plan_path fields
- [ ] Add error logging integration via log_command_error for revision failures
- [ ] Implement plan validation after revision: verify phase structure integrity, detect circular dependencies
- [ ] Add revision limit enforcement: skip revision if depth >= MAX_REVISION_DEPTH, log error with deferred_revision flag

### Testing
```bash
# Unit Test 1: Blocking Detection Extraction
# Input: lean-implementer output with theorems_partial field
# Expected: PARTIAL_COUNT > 0, BLOCKING_DIAGNOSTICS extracted correctly

# Unit Test 2: Context Budget Calculation
# Input: CURRENT_CONTEXT values (50k, 130k, 180k tokens)
# Expected: Correct REVISION_VIABLE decisions based on 30k minimum

# Unit Test 3: Revision Depth Enforcement
# Setup: REVISION_DEPTH=2, blocking dependencies detected
# Expected: Revision skipped, error logged with revision_limit_reached

# Integration Test 1: End-to-End Revision Workflow
# Setup: Lean plan with theorems blocked on missing lemma
# Execution: lean-coordinator detects blockers, triggers /revise, recalculates waves
# Expected: New infrastructure phase added with depends_on metadata, waves recalculated

# Integration Test 2: Context Exhaustion Handling
# Setup: Coordinator at 85% context, blockers detected
# Expected: Revision deferred, checkpoint saved with revision_deferred flag

# Integration Test 3: Dependency Cycle Detection
# Setup: /revise adds phase with circular dependency
# Expected: Plan restored from backup, error logged, revision marked failed
```

**Validation**:
- [ ] Blocking detection extracts theorems_partial and diagnostics fields
- [ ] Context budget check prevents revision when tokens < 30,000 remaining
- [ ] Revision depth counter increments correctly, enforces limit
- [ ] Plan validation after revision detects circular dependencies
- [ ] Error logging captures revision failures with structured data

**Expected Duration**: 4-5 hours

---

## Phase 9: Transform to Wave-Based Full Plan Delegation [NOT STARTED]

**Dependencies**: depends_on: [8]
**Estimated Time**: 5-6 hours

### Objective
Refactor /lean-implement command from sequential per-phase routing to full plan delegation with wave-based parallel execution, achieving 40-60% time savings for plans with independent phases.

### Complexity
High - Major architectural refactor of core command structure, iteration loop redesign, coordinator input contract changes

### Tasks
- [ ] Refactor Block 1a to remove CURRENT_PHASE extraction logic, add EXECUTION_MODE="full-plan" flag
- [ ] Update coordinator Task invocation to pass routing_map_path for dual coordinator support
- [ ] Add STEP 2 to lean-coordinator.md: integrate dependency-analyzer.sh for wave calculation
- [ ] Implement STEP 4 wave execution loop in lean-coordinator.md: iterate through waves, parallel Task invocations per wave
- [ ] Add wave synchronization hard barrier: wait for ALL executors before Wave N+1
- [ ] Update lean-coordinator output signal with waves_completed, current_wave_number, total_waves fields
- [ ] Add parallelization_metrics section to output: parallel_phases, time_savings_percent
- [ ] Refactor Block 1c iteration logic: trigger only on context threshold (not per-phase)
- [ ] Remove per-phase routing logic from Block 1b (consolidate to full plan routing)
- [ ] Update continuation context handling: pass iteration summary path for brief summary parsing
- [ ] Add wave execution metrics to completion summary (Block 2): total waves, parallel phases, time savings

### Testing
```bash
# Integration Test 1: Wave Calculation Correctness
# Setup: Plan with 5 phases (dependencies: []->[1]->[2,3]->[4])
# Expected: Wave structure: Wave 1=[0], Wave 2=[1], Wave 3=[2,3], Wave 4=[4]

# Integration Test 2: Parallel Task Invocation
# Setup: Wave with 2 independent Lean phases
# Expected: Both lean-implementer tasks invoked in single coordinator response

# Performance Test 1: Time Savings Measurement
# Setup: 5-phase plan (2 parallel waves with 2 phases each)
# Baseline: Sequential execution = 75 minutes
# Wave-based: Parallel execution = 45 minutes
# Expected: Time savings >= 40% (30 minutes saved)

# Integration Test 3: Iteration Loop Context Trigger
# Setup: CONTEXT_THRESHOLD=50, plan with 10 phases
# Expected: Checkpoint saved after Wave N when context >= 50%, iteration continues

# Integration Test 4: Coordinator Input Contract
# Setup: Full plan delegation with routing_map_path
# Expected: Coordinator receives plan_path, routing_map_path, execution_mode parameters

# Integration Test 5: Brief Summary Parsing
# Setup: Coordinator returns summary_brief field (80 tokens)
# Expected: Orchestrator parses brief field only, not full 2,000-token file (96% reduction)
```

**Validation**:
- [ ] dependency-analyzer.sh calculates waves correctly for plan with dependencies
- [ ] Parallel Task invocations occur in single coordinator response (multiple Task calls)
- [ ] Time savings measurement shows 40-60% improvement for plans with 2+ parallel phases
- [ ] Iteration loop only triggers on context threshold, not per-phase completion
- [ ] Context reduction via brief summary parsing enables 10+ iterations

**Expected Duration**: 5-6 hours

---

## Phase 10: Integration Testing and Documentation [NOT STARTED]

**Dependencies**: depends_on: [9]
**Estimated Time**: 3-4 hours

### Objective
Create comprehensive integration test suite for Phases 0-9 functionality, implement timing instrumentation for parallel execution validation, and update command/agent documentation with wave-based orchestration patterns.

### Complexity
Medium - Test design requires mock coordinator infrastructure, timing measurement, and checkpoint save/resume validation

### Tasks
- [ ] Create integration test script: /home/benjamin/.config/.claude/tests/integration/test_lean_implement_coordinator_waves.sh (file exists with 11 tests for Phases 0-7)
- [ ] Extend test_plan_fixtures() to include mixed Lean/software plan with dependencies
- [ ] Add test_plan_revision_workflow() function with mock lean-implementer output containing theorems_partial field
- [ ] Add test_wave_based_timing() function with timing instrumentation using Bash SECONDS variable
- [ ] Add test_checkpoint_resume_workflow() function with checkpoint save trigger (CONTEXT_THRESHOLD=50)
- [ ] Implement mock_coordinator_response() helper for realistic coordinator output without full execution
- [ ] Add timing measurement pattern: sequential baseline vs wave-based execution with 40% threshold validation
- [ ] Create test artifact generation: wave-execution-metrics.json, timing-baseline.txt, test-execution.log
- [ ] Update /lean-implement.md documentation: add wave-based orchestration section, checkpoint resume examples, phase 0 auto-detection
- [ ] Update /implement.md documentation: add phase 0 auto-detection notes in argument parsing section
- [ ] Update CLAUDE.md hierarchical agent examples: add lean-implement coordinator pattern with performance metrics
- [ ] Create success example documentation: link to lean-implement-output.md with plan path and time savings data

### Testing
```bash
# Integration Test 1: Phase 0 Detection (Already Exists - Test 1)
# Verify both /lean-implement and /implement auto-detect lowest incomplete phase

# Integration Test 2: Dual Coordinator Workflow
# Setup: Mixed plan with 2 Lean phases, 3 software phases
# Expected: lean-coordinator invoked for Lean phases, implementer-coordinator for software

# Integration Test 3: Checkpoint Save/Resume
# Setup: CONTEXT_THRESHOLD=50, execute until threshold exceeded
# Expected: Checkpoint saved with v2.1 schema, --resume flag restores state

# Integration Test 4: Plan Revision Cycle
# Setup: Lean plan with blocking theorems
# Expected: Revision triggered, infrastructure phase added, waves recalculated

# Integration Test 5: Wave-Based Parallel Execution
# Setup: Plan with 4 phases (2 independent waves with 2 phases each)
# Expected: Time savings 40-60% vs sequential baseline

# Documentation Validation
# Verify: lean-implement.md has wave execution section
# Verify: CLAUDE.md has hierarchical agent example with metrics
# Verify: All code examples use non-interactive testing patterns
```

**Validation**:
- [ ] All 16 integration tests pass (11 existing + 5 new for Phases 8-9)
- [ ] Timing measurement shows 40-60% savings for plans with 2+ parallel phases
- [ ] Checkpoint resume restores PLAN_FILE, ITERATION, COMPLETED_PHASES correctly
- [ ] Plan revision test verifies infrastructure phase added with depends_on metadata
- [ ] Documentation includes wave-based execution examples with performance metrics

**Expected Duration**: 3-4 hours

---

## Technical Design

### Blocking Dependency Detection Pattern

**lean-coordinator.md STEP 3.5: Blocking Detection and Revision Trigger**

```bash
# After parsing lean-implementer output (STEP 3)
PARTIAL_THEOREMS=$(grep "^  theorems_partial:" "$IMPLEMENTER_OUTPUT" | \
                   sed 's/theorems_partial:[[:space:]]*//' | \
                   tr -d '[],' | xargs)
PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)

# Extract diagnostic blockers
BLOCKING_DIAGNOSTICS=$(grep "^  diagnostics:" "$IMPLEMENTER_OUTPUT" | \
                       sed 's/diagnostics:[[:space:]]*//')

# Trigger revision if blocking detected
if [ "$PARTIAL_COUNT" -gt 0 ]; then
  # Check context budget (30k tokens minimum for /revise workflow)
  CURRENT_CONTEXT=$(get_context_usage "$CURRENT_WAVE" "$TOTAL_WAVES" "$HAS_CONTINUATION")
  CONTEXT_REMAINING=$((200000 - CURRENT_CONTEXT))

  # Check revision depth limit
  REVISION_DEPTH=$(grep "^REVISION_DEPTH=" "$STATE_FILE" | cut -d'=' -f2 || echo "0")
  MAX_REVISION_DEPTH=$(grep "^MAX_REVISION_DEPTH=" "$STATE_FILE" | cut -d'=' -f2 || echo "2")

  if [ "$CONTEXT_REMAINING" -ge 30000 ] && [ "$REVISION_DEPTH" -lt "$MAX_REVISION_DEPTH" ]; then
    echo "Triggering plan revision for $PARTIAL_COUNT blocking theorems..."

    # Increment revision depth
    REVISION_DEPTH=$((REVISION_DEPTH + 1))
    append_workflow_state "REVISION_DEPTH" "$REVISION_DEPTH"

    # Build revision prompt
    REVISION_DESCRIPTION="Revise plan at $PLAN_PATH to add infrastructure for blocking dependencies:

Blocking Dependencies Detected in Wave $CURRENT_WAVE:
- Partial Theorems: $PARTIAL_THEOREMS ($PARTIAL_COUNT incomplete)
- Diagnostic Messages: $BLOCKING_DIAGNOSTICS

Recommended Actions:
- Add infrastructure phase(s) for missing lemmas/definitions
- Update dependency metadata to sequence infrastructure before blocked theorems"

    append_workflow_state "REVISION_DESCRIPTION" "$REVISION_DESCRIPTION"
    append_workflow_state "REVISION_TRIGGERED" "true"
  else
    echo "Revision not viable: context=${CONTEXT_REMAINING}, depth=${REVISION_DEPTH}/${MAX_REVISION_DEPTH}"
  fi
fi
```

**EXECUTE NOW**: USE the Task tool to invoke the /revise command.

Task {
  subagent_type: "general-purpose"
  description: "Revise plan to address blocking dependencies in wave ${CURRENT_WAVE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/commands/revise.md

    You are executing a plan revision workflow triggered by coordinator blocking dependency detection.

    **Revision Description**:
    ${REVISION_DESCRIPTION}

    **Context**:
    - Plan Path: ${PLAN_PATH}
    - Wave Number: ${CURRENT_WAVE}
    - Partial Theorems: ${PARTIAL_THEOREMS}
    - Blocking Diagnostics: ${BLOCKING_DIAGNOSTICS}

    **Revision Requirements**:
    1. Analyze blocking diagnostics to identify missing infrastructure
    2. Create research report documenting infrastructure gaps
    3. Add new phases for infrastructure lemmas/definitions
    4. Update dependency metadata to ensure proper wave sequencing
    5. Preserve all [COMPLETE] phases unchanged

    Execute /revise workflow and return completion signal:
    PLAN_REVISED: ${PLAN_PATH}
  "
}

```bash
# After /revise completes
PLAN_REVISED_PATH=$(echo "$REVISE_OUTPUT" | grep "^PLAN_REVISED:" | sed 's/PLAN_REVISED:[[:space:]]*//')

if [ -n "$PLAN_REVISED_PATH" ]; then
  echo "Plan revision completed: $PLAN_REVISED_PATH"

  # Recalculate wave dependencies
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/dependency-recalculation.sh" 2>/dev/null || {
    echo "ERROR: Cannot load dependency-recalculation.sh" >&2
    exit 1
  }

  COMPLETED_PHASES=$(grep -oE "^### Phase ([0-9]+):.*\[COMPLETE\]" "$PLAN_PATH" | \
                     grep -oE "[0-9]+" | xargs)

  NEXT_WAVE_PHASES=$(recalculate_wave_dependencies "$PLAN_PATH" "$COMPLETED_PHASES")

  if [ -n "$NEXT_WAVE_PHASES" ]; then
    echo "Next wave after revision: $NEXT_WAVE_PHASES"
    append_workflow_state "NEXT_WAVE_PHASES" "$NEXT_WAVE_PHASES"
    append_workflow_state "DEPENDENCIES_RECALCULATED" "true"
  fi
fi
```

### Wave-Based Full Plan Delegation Pattern

**lean-implement.md Block 1a: Full Plan Delegation**

```bash
# OLD (per-phase routing):
# CURRENT_PHASE=$(get_starting_phase "$PLAN_FILE")

# NEW (full plan delegation):
EXECUTION_MODE="full-plan"
append_workflow_state "EXECUTION_MODE" "$EXECUTION_MODE"

# Pass routing map to coordinator for dual coordinator support
ROUTING_MAP_PATH="${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
append_workflow_state "ROUTING_MAP_PATH" "$ROUTING_MAP_PATH"

echo "Execution mode: full plan delegation with wave-based orchestration"
```

**lean-coordinator.md STEP 2: Dependency Analysis and Wave Calculation**

```bash
# Invoke dependency-analyzer utility
bash "${CLAUDE_PROJECT_DIR}/.claude/lib/util/dependency-analyzer.sh" "$PLAN_PATH" > dependency_analysis.json

# Parse JSON output
WAVES=$(jq '.waves' dependency_analysis.json)
TOTAL_WAVES=$(echo "$WAVES" | jq 'length')

# Validate no cycles
if jq -e '.error' dependency_analysis.json >/dev/null; then
  echo "ERROR: Circular dependency detected" >&2
  DEPENDENCY_ERROR=$(jq -r '.error' dependency_analysis.json)
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "dependency_error" \
    "Dependency analysis failed: $DEPENDENCY_ERROR" \
    "wave_calculation" \
    "$(jq -c '.cycles' dependency_analysis.json)"
  exit 1
fi

echo "Wave structure calculated: $TOTAL_WAVES waves"
echo "$WAVES" | jq -r '.[] | "Wave \(.wave_number): phases \(.phases | join(", "))"'
```

**lean-coordinator.md STEP 4: Wave Execution Loop**

```markdown
## STEP 4: Wave Execution Loop

FOR EACH wave in wave structure:

### Wave Initialization
- Log wave start with timestamp
- Initialize executor tracking for wave
- Determine phase types from routing map

### Parallel Coordinator Invocation

**CRITICAL**: Multiple Task invocations in single response for parallel execution.

Example for Wave 2 with 1 Lean + 1 software phase:

I'm now invoking coordinators for Wave 2 in parallel.

**EXECUTE NOW**: USE the Task tool to invoke lean-implementer.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorem in Phase 2"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-implementer.md

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE_PATH}
    - theorem_tasks: [{"name": "theorem_K", "line": 42, "phase_number": 2}]
    - wave_number: 2
    - phase_number: 2
}

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**:
    - phase_file_path: ${PHASE_3_PATH}
    - wave_number: 2
    - phase_number: 3
}

### Wave Synchronization
**CRITICAL**: Wait for ALL coordinators in wave to complete before Wave N+1
- Collect completion reports from all coordinators
- Aggregate metrics (theorems_proven, git_commits, tasks_completed)
- Update wave state
- Proceed to next wave
```

### Integration Testing Infrastructure

**Mock Coordinator Response Pattern**

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
```

**Timing Measurement Pattern**

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

---

## Testing Strategy

### Unit Tests

**Test 1: Blocking Detection Extraction**
- Input: lean-implementer output with theorems_partial field populated
- Expected: PARTIAL_COUNT correct, BLOCKING_DIAGNOSTICS extracted

**Test 2: Context Budget Calculation**
- Input: CURRENT_CONTEXT values (50k, 130k, 180k tokens)
- Expected: Correct REVISION_VIABLE decisions (>= 30k required)

**Test 3: Revision Depth Enforcement**
- Input: REVISION_DEPTH=2, blocking dependencies detected
- Expected: Revision skipped, error logged with revision_limit_reached

**Test 4: Wave Calculation Correctness**
- Input: Plan with dependencies []->[1]->[2,3]->[4]
- Expected: Wave structure = [[0], [1], [2,3], [4]]

### Integration Tests

**Test 1: End-to-End Plan Revision**
- Setup: Lean plan with theorems requiring missing lemma
- Execution: lean-coordinator detects blockers, triggers /revise
- Expected: Infrastructure phase added, waves recalculated

**Test 2: Wave-Based Parallel Execution**
- Setup: Plan with 5 phases (2 parallel waves)
- Expected: Time savings 40-60% vs sequential baseline

**Test 3: Checkpoint Save/Resume**
- Setup: CONTEXT_THRESHOLD=50, execute until exceeded
- Expected: Checkpoint saved, --resume restores state

**Test 4: Dual Coordinator Workflow**
- Setup: Mixed Lean/software plan with dependencies
- Expected: Correct coordinator routing, phases complete in waves

---

## Documentation Requirements

### Command Documentation Updates

**lean-implement.md**:
- Add "Wave-Based Orchestration" section after behavioral guidelines
- Document phase 0 auto-detection in argument parsing section
- Add checkpoint resume examples with --resume flag
- Include plan revision workflow explanation with MAX_REVISION_DEPTH

**implement.md**:
- Add phase 0 auto-detection notes in argument parsing section
- Reference lean-implement.md for wave-based pattern

### Standards Documentation Updates

**CLAUDE.md**:
- Add lean-implement to hierarchical_agent_architecture examples (Example 9)
- Include performance metrics: 40-60% time savings, 96% context reduction
- Document dual coordinator routing pattern

### Success Examples

**lean-implement-output.md**:
- Link to example plan with wave structure
- Show timing metrics from wave-based execution
- Include checkpoint save/resume workflow example

---

## Dependencies

```
Phase 8 (Plan Revision Workflow)
  |
  +-- Phase 9 (Wave-Based Delegation)
        |
        +-- Phase 10 (Integration Testing & Docs)
```

**Parallelization**: Phase 8 and Phase 9 could theoretically run in parallel, but Phase 9 builds on Phase 8's revision patterns, so sequential execution recommended.

---

## Completion Criteria

**Phase 8 Completion**:
- [ ] Blocking detection extracts theorems_partial and diagnostics from lean-implementer output
- [ ] Context budget check (>= 30k tokens) enforced before triggering revision
- [ ] Revision depth counter increments correctly, enforces MAX_REVISION_DEPTH=2 limit
- [ ] /revise Task delegation invoked with blocking summary prompt
- [ ] Dependency recalculation after revision returns updated wave structure
- [ ] Error logging captures revision failures with structured error data

**Phase 9 Completion**:
- [ ] Block 1a passes full plan to coordinator (EXECUTION_MODE="full-plan")
- [ ] lean-coordinator integrates dependency-analyzer.sh for wave calculation
- [ ] Wave execution loop (STEP 4) implements parallel Task invocations
- [ ] Coordinator output signal includes waves_completed, parallelization_metrics
- [ ] Iteration loop triggers only on context threshold (not per-phase)
- [ ] Time savings measurement shows 40-60% improvement for 2+ parallel phases

**Phase 10 Completion**:
- [ ] Integration test suite has 16 tests total (11 existing + 5 new)
- [ ] Timing instrumentation validates 40-60% time savings claim
- [ ] Checkpoint save/resume test verifies state restoration correctness
- [ ] Plan revision test verifies infrastructure phase addition and wave recalculation
- [ ] Documentation updated: lean-implement.md, implement.md, CLAUDE.md with wave examples

---

## Risk Mitigation

### Risk 1: Iteration Loop Regression (HIGH)

**Description**: Refactoring iteration trigger from per-phase to context-threshold-only may cause infinite loops

**Mitigation**:
- Comprehensive integration tests for iteration loop logic
- Stuck detection pattern (work_remaining unchanged for 2 iterations)
- Backup restoration plan (lean-implement.md.backup.20251209)

### Risk 2: Coordinator Invocation Failure (HIGH)

**Description**: Full plan delegation changes coordinator input contract

**Mitigation**:
- Hard barrier validation (fail-fast if summary not created)
- Error return protocol with TASK_ERROR format
- Input contract validation for all required fields

### Risk 3: Wave Calculation Errors (MEDIUM)

**Description**: dependency-analyzer.sh may fail on malformed dependency metadata

**Mitigation**:
- Cycle detection with DFS (prevents infinite loops)
- Graceful degradation to sequential execution on analysis failure
- Comprehensive error messages with recovery suggestions

---

## Rollback Plan

If critical issues discovered:

1. **Backup Restoration**: `cp lean-implement.md.backup.20251209 lean-implement.md`
2. **Phase-Level Rollback**: Each phase creates incremental backup before changes
3. **Coordinator Revert**: Restore lean-coordinator.md to pre-Phase-8 state
4. **Test Cleanup**: Delete integration test artifacts from failed runs

---

## Notes

**Deferral Justification**:
- Phases 8-9 are enhancement features, not core functionality
- High architectural complexity requires focused spec for risk management
- Test-driven development approach needed for validation
- Original spec 047 achieved 83% completion (Phases 0-7) with strong foundation

**Implementation Strategy**:
- Phase 8: Isolated to lean-coordinator behavioral changes (minimal command refactor)
- Phase 9: Major command refactor but leverages proven implementer-coordinator pattern
- Phase 10: Comprehensive testing validates all integration points

**Success Metrics**:
- 40-60% time savings for plans with 2+ parallel phases (empirically measured)
- MAX_REVISION_DEPTH=2 prevents infinite revision loops (enforced via workflow state)
- 96% context reduction via brief summary parsing (enables 10+ iterations)
- Zero Task invocation violations (linter-verified throughout)
