# /build Persistent Workflow Refactor - Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Refactor /build command to implement persistent workflow execution
- **Scope**: Core /build command, implementer-coordinator integration, documentation updates
- **Estimated Phases**: 5
- **Estimated Hours**: 12-15 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 87.0
- **Research Reports**:
  - [Build Persistence Research](/home/benjamin/.config/.claude/specs/881_build_persistent_workflow_refactor/reports/001_build_persistence_research.md)

## Overview

Transform the /build command from a single-shot workflow into a **persistent execution system** that runs implementer subagents iteratively for phases until the entire plan completes or the primary agent reaches 90% context usage. This enables handling large plans (15+ phases) that cannot be completed in a single execution cycle.

### Goals

1. **Persistent Loop**: Implement while loop in /build Block 1 that re-invokes implementer-coordinator until work_remaining == 0
2. **Context Management**: Monitor primary agent context usage before each iteration, halt gracefully at 90% threshold
3. **Seamless Continuation**: Pass previous summary as continuation_context to enable checkpoint-free resumption
4. **Safety Guards**: Prevent infinite loops via MAX_ITERATIONS limit (default 5) and stuck state detection
5. **Documentation Alignment**: Update all docs to reflect persistent behavior and continuation patterns

### Research Summary

The research report identified that:
- **Implementer-coordinator already supports continuation** via `continuation_context` and `iteration` parameters, but /build never uses them
- **Current /build is single-shot**: Invokes implementer-coordinator once in Block 1, no iteration logic
- **Context exhaustion detection exists**: Implementation-executor monitors 70% threshold and signals work_remaining
- **Missing loop infrastructure**: No parsing of work_remaining, no iteration tracking, no context estimation
- **Documentation gaps**: State-based orchestration docs and build guide don't describe persistent workflows

The architecture is sound and ready for this enhancement. The implementer-coordinator agent is fully equipped for multi-iteration execution, requiring only orchestration changes in /build.

## Success Criteria

- [ ] /build executes implementation phases iteratively until plan complete or 90% context threshold
- [ ] Context usage estimated before each iteration using heuristic formula
- [ ] Resumption checkpoint created when halted, enabling seamless continuation
- [ ] MAX_ITERATIONS limit (default 5, configurable via --max-iterations flag)
- [ ] Stuck state detection prevents infinite loops (work_remaining unchanged across iterations)
- [ ] work_remaining parsed from implementer-coordinator IMPLEMENTATION_COMPLETE signal
- [ ] continuation_context passed to subsequent iterations via behavioral injection
- [ ] Plan checkboxes and git commits remain correct across all iterations
- [ ] Documentation updated with persistent workflow pattern, continuation protocol, troubleshooting
- [ ] Test coverage >90% for new iteration logic, context estimation, checkpoint functions
- [ ] Backward compatible with existing plans (no breaking changes to plan format)
- [ ] Small plans (5 phases) complete in 1 iteration, medium plans (15 phases) in 2-3 iterations
- [ ] Large plans (30 phases) halt gracefully at 90%, resume correctly with /build retry

## Technical Design

### Architecture Changes

**Current /build Structure (4 blocks)**:
```
Block 1: Setup → invoke implementer-coordinator ONCE → persist state
Block 2: Parse test results → update state
Block 3: Conditional debug/document → update state
Block 4: Completion summary → cleanup
```

**Enhanced /build Structure**:
```
Block 1: Setup → ITERATION LOOP:
  ├─ Estimate context usage
  ├─ Check 90% threshold → halt if exceeded
  ├─ Invoke implementer-coordinator with continuation_context
  ├─ Parse work_remaining from output
  ├─ Break if work_remaining == 0
  ├─ Detect stuck state (work_remaining unchanged)
  ├─ Prepare next iteration (continuation_context = summary_path)
  └─ Repeat until complete or MAX_ITERATIONS
Block 2-4: Unchanged (testing, debug/document, completion)
```

### Key Components

**1. Iteration Loop** (replaces single invocation in Block 1):
```bash
ITERATION=1
MAX_ITERATIONS=5
CONTINUATION_CONTEXT="null"
WORK_REMAINING="initial"

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  # Context check
  CONTEXT_PCT=$(estimate_context_usage "$PLAN_FILE" "$CONTINUATION_CONTEXT" "$ITERATION")
  if [ $CONTEXT_PCT -gt 90 ]; then
    save_resumption_checkpoint
    exit 0 with clear messaging
  fi

  # Invoke implementer-coordinator
  Task tool with continuation_context + iteration params

  # Parse results: WORK_REMAINING, SUMMARY_PATH

  # Check completion
  [ "$WORK_REMAINING" == "0" ] && break

  # Stuck detection
  [ "$WORK_REMAINING" == "$PREV_WORK_REMAINING" ] && error exit

  # Prepare next iteration
  CONTINUATION_CONTEXT="$SUMMARY_PATH"
  ((ITERATION++))
done
```

**2. Context Estimation Function**:
```bash
estimate_context_usage() {
  local plan_file="$1"
  local continuation_context="$2"
  local iteration="$3"

  # Component sizes
  local base_overhead=10000
  local plan_size=$(wc -c < "$plan_file")
  local summary_size=$(wc -c < "$continuation_context" 2>/dev/null || echo 0)
  local iteration_overhead=$((iteration * 5000))
  local coordinator_output=$((iteration * 8000))

  # Total chars → tokens (4 chars/token estimate)
  local total_chars=$((base_overhead + plan_size + summary_size + iteration_overhead + coordinator_output))
  local estimated_tokens=$((total_chars / 4))

  # Haiku-4.5 context: 200k tokens
  local context_pct=$((estimated_tokens * 100 / 200000))
  [ $context_pct -gt 100 ] && context_pct=100

  echo $context_pct
}
```

**3. Checkpoint Format Extension (V2.1)**:
```json
{
  "version": "2.1",
  "state_machine": {
    "current_state": "implement",
    "iteration": 3,
    "continuation_context": "/path/to/summaries/002_iteration_2.md",
    "work_remaining": ["Phase 9", "Phase 10"]
  },
  "plan_path": "/path/to/plan.md",
  "timestamp": "2025-11-20T15:30:00Z",
  "resumable": true
}
```

**4. State Persistence**:
New variables added to workflow state:
- `ITERATION`: Current iteration counter
- `CONTINUATION_CONTEXT`: Path to previous summary
- `WORK_REMAINING`: List of incomplete phases
- `IMPLEMENTATION_HALTED`: Boolean flag if stopped at 90%
- `HALT_REASON`: "context_threshold" or "max_iterations"

### Integration Points

**Implementer-Coordinator**: No changes needed (already has continuation support)
**Implementation-Executor**: No changes needed (already signals context exhaustion)
**State Machine**: No changes to transition table (implement → test transition preserved)
**Checkpoint Utils**: Extend schema to V2.1 with iteration fields

### Error Handling

**Stuck State Detection**:
- If `work_remaining` unchanged across 2 consecutive iterations → halt with error
- Log details via error-handling.sh: `log_command_error "execution_error" "Loop stuck"`

**Max Iterations Exceeded**:
- If loop reaches MAX_ITERATIONS without completion → create checkpoint, exit 0 with warning
- User can increase limit: `/build --max-iterations 10`

**Context Overflow Prevention**:
- Estimate before each iteration (not reactive)
- 90% threshold provides 10% safety margin
- Graceful halt with resumption instructions

## Implementation Phases

### Phase 1: Core Iteration Loop [NOT STARTED]
dependencies: []

**Objective**: Replace single implementer-coordinator invocation in /build Block 1 with persistent iteration loop

**Complexity**: High

**Tasks**:
- [ ] Add `MAX_ITERATIONS` variable with default 5 (file: .claude/commands/build.md, line ~96)
- [ ] Parse `--max-iterations=N` flag from command arguments (after line 103)
- [ ] Create iteration loop structure wrapping implementer-coordinator invocation (replace lines 200-300)
- [ ] Add `ITERATION` counter initialization before loop
- [ ] Add `CONTINUATION_CONTEXT` variable (initially "null")
- [ ] Add `WORK_REMAINING` variable (initially "initial")
- [ ] Modify Task tool invocation to pass `continuation_context: $CONTINUATION_CONTEXT` parameter
- [ ] Modify Task tool invocation to pass `iteration: $ITERATION` parameter
- [ ] Parse `work_remaining` field from implementer-coordinator IMPLEMENTATION_COMPLETE output
- [ ] Parse `summary_path` field from implementer-coordinator output
- [ ] Add completion check: break loop if `work_remaining == "0"`
- [ ] Add iteration increment and continuation_context update at loop end
- [ ] Persist ITERATION, CONTINUATION_CONTEXT, WORK_REMAINING to state file via append_workflow_state

**Testing**:
```bash
# Test with small plan (should complete in 1 iteration)
/build .claude/specs/test_small/plans/001_test.md

# Verify iteration counter in state file
grep ITERATION ~/.claude/tmp/workflow_state_*.txt

# Verify continuation_context passed on iteration 2+
# (manual test with medium plan)
```

**Expected Duration**: 4 hours

### Phase 2: Context Monitoring and Halt Logic [NOT STARTED]
dependencies: [1]

**Objective**: Implement context usage estimation and graceful halt at 90% threshold

**Complexity**: Medium

**Tasks**:
- [ ] Create `estimate_context_usage()` function in /build Block 1 (after library sourcing, before loop)
- [ ] Implement heuristic calculation: base + plan_size + summary_size + iteration_overhead + coordinator_output
- [ ] Convert char count to token estimate (divide by 4)
- [ ] Calculate percentage against Haiku-4.5 context window (200k tokens)
- [ ] Add context check at start of while loop (before Task invocation)
- [ ] If context_pct > 90: Display warning message with threshold details
- [ ] Call `save_resumption_checkpoint()` function (to be created in next task)
- [ ] Set `IMPLEMENTATION_HALTED="true"` in state
- [ ] Set `HALT_REASON="context_threshold"` in state
- [ ] Transition to STATE_COMPLETE (partial completion)
- [ ] Exit 0 with clear resumption instructions (echo "To continue: /build $PLAN_FILE")
- [ ] Add Block 2 check: if IMPLEMENTATION_HALTED==true, skip testing phase

**Testing**:
```bash
# Test context estimation accuracy
# Create test plan with known size, verify estimate within 10%

# Mock large plan scenario (adjust estimate_context_usage to return 91%)
# Verify halt behavior triggers correctly

# Verify resumption checkpoint created
cat ~/.claude/data/checkpoints/build_checkpoint.json
```

**Expected Duration**: 3 hours

### Phase 3: Checkpoint and Stuck Detection [NOT STARTED]
dependencies: [1, 2]

**Objective**: Implement resumption checkpoint creation and infinite loop prevention

**Complexity**: Medium

**Tasks**:
- [ ] Create `save_resumption_checkpoint()` function in /build Block 1 (after estimate_context_usage function)
- [ ] Function params: plan_file, iteration, continuation_context, work_remaining
- [ ] Generate JSON checkpoint with schema V2.1 structure (use jq)
- [ ] Save to ~/.claude/data/checkpoints/build_checkpoint.json
- [ ] Add stuck detection logic in iteration loop (after parsing work_remaining)
- [ ] Compare current work_remaining with PREV_WORK_REMAINING from previous iteration
- [ ] If unchanged and iteration > 1: Display stuck state error
- [ ] Log error via error-handling.sh: `log_command_error "execution_error" "Stuck state"`
- [ ] Exit 1 with details (which phases stuck, what to investigate)
- [ ] Add PREV_WORK_REMAINING variable update at end of loop
- [ ] Add max iterations check: if ITERATION > MAX_ITERATIONS, save checkpoint and exit 0 with warning
- [ ] Update auto-resume logic in Block 1 to read iteration, continuation_context from checkpoint V2.1

**Testing**:
```bash
# Test stuck detection
# Manually create scenario where phase blocks (modify plan checkbox without commit)
# Run /build, verify stuck detection triggers after 2 iterations

# Test max iterations
/build --max-iterations=2 .claude/specs/test_large/plans/001_test.md
# Verify stops at iteration 2 with checkpoint

# Test checkpoint resumption
/build  # Should auto-resume from checkpoint with correct iteration/context
```

**Expected Duration**: 2.5 hours

### Phase 4: Documentation Updates [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Update all documentation to reflect persistent workflow pattern and continuation behavior

**Complexity**: Medium

**Tasks**:
- [ ] Add "Persistent Workflows" section to state-based-orchestration-overview.md (after line 367)
  - [ ] Overview of iterative state execution pattern (~30 lines)
  - [ ] Use cases for persistent workflows (~20 lines)
  - [ ] Context management strategy and thresholds (~25 lines)
  - [ ] Continuation protocol (3-step process) (~30 lines)
  - [ ] Infinite loop prevention (max iterations, stuck detection) (~20 lines)
  - [ ] Example: /build iteration loop code (~30 lines)
  - [ ] State machine implications (~20 lines)
  - [ ] Performance characteristics (~15 lines)
  - [ ] Troubleshooting section (3 issues) (~30 lines)
- [ ] Update build-command-guide.md "When to Use" section (line 23-26) with large plans mention
- [ ] Add "Persistence Behavior" subsection to build-command-guide.md (after line 105)
  - [ ] Iteration loop explanation (~15 lines)
  - [ ] Context monitoring details (~10 lines)
  - [ ] Iteration limits and configuration (~10 lines)
  - [ ] Example scenarios (small/medium/large plans) (~25 lines)
  - [ ] Manual resumption instructions (~5 lines)
- [ ] Add troubleshooting issue "Build Halted at 90% Context" to build-command-guide.md (after line 566)
  - [ ] Symptoms and cause (~10 lines)
  - [ ] Solution with resumption commands (~15 lines)
  - [ ] Prevention strategies (~10 lines)
  - [ ] When to investigate (~5 lines)
- [ ] Enhance implementer-coordinator.md STEP 1 (lines 49-71) with continuation handling detail
  - [ ] Expand to show first iteration vs continuation iteration logic (~40 lines)
  - [ ] Add work_remaining parsing steps (~15 lines)
  - [ ] Show state display format (~5 lines)
- [ ] Add "Multi-Iteration Execution" section to implementer-coordinator.md (after line 493)
  - [ ] Iteration lifecycle (iteration 1 vs 2 examples) (~40 lines)
  - [ ] Performance across iterations (~20 lines)
  - [ ] Idempotency guarantees (~10 lines)
  - [ ] Error handling in continuation (~10 lines)

**Testing**:
```bash
# Verify markdown syntax
markdownlint .claude/docs/architecture/state-based-orchestration-overview.md
markdownlint .claude/docs/guides/commands/build-command-guide.md
markdownlint .claude/agents/implementer-coordinator.md

# Verify all examples are accurate and code blocks properly formatted
# Verify internal links work (persistence → checkpoint-recovery, etc.)
```

**Expected Duration**: 2.5 hours

### Phase 5: Testing and Validation [NOT STARTED]
dependencies: [1, 2, 3, 4]

**Objective**: Comprehensive testing of iteration loop, context estimation, checkpoint behavior across scenarios

**Complexity**: High

**Tasks**:
- [ ] **Unit Tests**:
  - [ ] Create test for estimate_context_usage() with 3 plan sizes (small/medium/large)
  - [ ] Verify estimates within 15% of expected values (validate heuristic)
  - [ ] Create test for save_resumption_checkpoint() schema validation (verify V2.1 JSON structure)
  - [ ] Create test for work_remaining parsing logic (mock IMPLEMENTATION_COMPLETE output)
  - [ ] Create test for stuck detection (same work_remaining across 2 iterations)
- [ ] **Integration Tests**:
  - [ ] Test small plan (5 phases): Verify completes in 1 iteration, no checkpoint created
  - [ ] Test medium plan (12 phases): Verify completes in 2-3 iterations, correct continuation_context passed
  - [ ] Test large plan scenario (mock 30 phases with context halt at iteration 3)
  - [ ] Verify resumption: After halt, /build auto-resumes from checkpoint with correct iteration
  - [ ] Test stuck detection: Manually block phase progress, verify error after 2 iterations
  - [ ] Test max iterations: Run with --max-iterations=2, verify stops at iteration 2 with checkpoint
  - [ ] Test backward compatibility: Run against existing Level 0/1/2 plans, verify no breaking changes
- [ ] **End-to-End Tests**:
  - [ ] Run real plan from .claude/specs/874_* (build testing subagent, 4 phases)
  - [ ] Run real plan from .claude/specs/859_* (leader.ac command, 22 phases if available)
  - [ ] Verify git commits created correctly across iterations
  - [ ] Verify plan checkboxes updated correctly (phases 1-8 marked [x] after iteration 1, etc.)
  - [ ] Verify summaries created with correct work_remaining sections
  - [ ] Verify state file contains correct ITERATION, CONTINUATION_CONTEXT, WORK_REMAINING values
- [ ] **Performance Validation**:
  - [ ] Measure iteration 1 vs iteration 2 execution time (should be comparable)
  - [ ] Verify wave-based parallelization maintained across iterations
  - [ ] Measure context estimation accuracy: Compare estimate to actual usage (use debug logging)
- [ ] **Error Scenario Tests**:
  - [ ] Test phase failure in iteration 2 (verify work_remaining includes failed phase)
  - [ ] Test implementer-coordinator error (verify error propagated, checkpoint saved)
  - [ ] Test checkpoint corruption (verify fallback to plan file analysis)

**Testing**:
```bash
# Run all unit tests
pytest .claude/tests/unit/test_build_iteration.py -v

# Run integration tests
pytest .claude/tests/integration/test_build_persistence.py -v

# Run end-to-end tests (requires real plans)
.claude/scripts/test-build-e2e.sh

# Check test coverage
coverage report --include=".claude/commands/build.md" --fail-under=90
```

**Expected Duration**: 5 hours

## Testing Strategy

### Test Coverage Requirements

**Unit Tests** (Target: 95%):
- `estimate_context_usage()` function (3 test cases: small/medium/large plans)
- `save_resumption_checkpoint()` function (2 test cases: valid + edge case)
- Work_remaining parsing logic (3 test cases: 0, single phase, multiple phases)
- Stuck detection logic (2 test cases: stuck + not stuck)

**Integration Tests** (Target: 90%):
- Iteration loop behavior (5 test cases: 1 iter, 2 iter, 3 iter, halt, max exceeded)
- Checkpoint resumption (3 test cases: auto-resume, manual resume, no checkpoint)
- Context monitoring (2 test cases: below threshold, above threshold)
- Backward compatibility (3 test cases: Level 0, Level 1, Level 2 plans)

**End-to-End Tests** (Target: 85%):
- Real plan execution (2 plans: small 4-phase, large 22-phase)
- Git commit verification across iterations
- Plan checkbox state verification
- Summary content verification

### Test Execution

**Pre-commit**: Run unit tests only (fast feedback, <30 seconds)
**CI Pipeline**: Run all tests (unit + integration + e2e, ~10 minutes)
**Manual QA**: Test resumption flow interactively, verify user messaging clear

### Test Data

Create 3 synthetic test plans:
1. **Small**: 5 phases, ~5k bytes (completes iteration 1)
2. **Medium**: 12 phases, ~15k bytes (completes iteration 2-3)
3. **Large**: Mock 30 phases (triggers halt via context estimation override)

Use existing real plans for e2e validation.

## Documentation Requirements

### Files to Update

1. **state-based-orchestration-overview.md**: Add 180-line "Persistent Workflows" section
2. **build-command-guide.md**: Update 3 sections (~100 lines total)
3. **implementer-coordinator.md**: Enhance STEP 1 + add new section (~140 lines)

Total documentation additions: ~420 lines

### Cross-References

Add links from:
- Persistent Workflows section → checkpoint-recovery.md, hierarchical-agents.md, behavioral-injection.md
- Build guide troubleshooting → state-based-orchestration-overview.md#persistent-workflows
- Implementer-coordinator → build-command-guide.md#persistence-behavior

### Examples to Include

- Iteration loop code snippet (state-based-orchestration-overview.md)
- Small/medium/large plan scenarios (build-command-guide.md)
- Iteration 1 vs iteration 2 comparison (implementer-coordinator.md)
- Checkpoint schema V2.1 example (state-based-orchestration-overview.md)

## Dependencies

### External Dependencies
- jq (JSON processing for checkpoint creation)
- grep with -E flag (work_remaining parsing)
- stat command (checkpoint age calculation)

### Internal Dependencies
- workflow-state-machine.sh v2.0.0 (state transitions)
- state-persistence.sh v1.5.0 (state file operations)
- checkpoint-utils.sh (checkpoint loading/saving)
- error-handling.sh (error logging)

### Agent Dependencies
- implementer-coordinator.md (must support continuation_context, iteration params)
- implementation-executor.md (must signal work_remaining)

## Risk Mitigation

### Technical Risks

**Risk 1: Context estimation inaccurate**
- Mitigation: Conservative 90% threshold, validation testing phase
- Fallback: User can increase --max-iterations if premature halt

**Risk 2: Stuck detection false positive**
- Mitigation: Only trigger after 2 consecutive unchanged work_remaining
- Fallback: User can inspect logs, manually fix blocking phase

**Risk 3: Infinite loop despite safeguards**
- Mitigation: Hard MAX_ITERATIONS limit, per-iteration timeout (2h via Task tool default)
- Fallback: User can kill process, checkpoint persists progress

### User Experience Risks

**Risk 4: Confusion about halt behavior**
- Mitigation: Clear messaging ("Context threshold reached, resuming..."), documentation with examples
- Fallback: Troubleshooting guide with step-by-step resumption

**Risk 5: Unexpected multi-iteration duration**
- Mitigation: Display iteration counter (1/5), show estimated time per iteration
- Fallback: User can monitor progress via state file

## Performance Considerations

### Context Budget

Haiku-4.5 context: 200k tokens, 90% threshold = 180k tokens

**Example plan sizes**:
- Small (5 phases): ~10k tokens iteration 1 (5% usage)
- Medium (15 phases): ~17-21k tokens per iteration (9-11% usage)
- Large (30 phases): ~42-48k tokens per iteration (23-26% usage)

**Conclusion**: Context is NOT a bottleneck. Can support 8-15 iterations before threshold.

### Time Per Iteration

**Measured performance**:
- Simple phase: 3-5 minutes
- Medium phase: 8-12 minutes
- Complex phase: 15-25 minutes

**Iteration estimates**:
- 5 phases/iteration: 25-40 minutes
- 8 phases/iteration: 40-70 minutes
- 10 phases/iteration: 60-90 minutes

**Total plan time**:
- 12-phase plan (2 iterations): 60-80 minutes
- 24-phase plan (4 iterations): 120-180 minutes
- 40-phase plan (6 iterations): 200-300 minutes

## Rollback Plan

If critical issues arise:

**Phase 1-3**: Revert /build Block 1 to single invocation (restore from git history)
**Phase 4**: Keep documentation (harmless, provides context for future attempts)
**Phase 5**: Delete test files (no production impact)

**Rollback Trigger**:
- Context estimation off by >30% (causes frequent false halts or overflows)
- Stuck detection triggers incorrectly on >10% of plans
- Performance degradation >20% on iteration 2+ vs iteration 1

## Future Enhancements

### Out of Scope (Explicitly)

1. **Dynamic MAX_ITERATIONS**: Not auto-adjusting based on plan size (user override sufficient)
2. **Sub-phase resumption**: Not resuming mid-phase (phase is atomic unit)
3. **Parallel iterations**: Not running multiple iterations concurrently (sequential only)
4. **Actual context introspection**: Not using real token counts from API (heuristic sufficient)
5. **LLM model changes**: Not changing implementer-coordinator model (haiku-4.5 works well)

### Potential Future Work

- Summary consolidation: Merge iteration summaries into single final summary
- Telemetry: Log iteration metrics for performance analysis
- Advanced checkpoint: Support --resume-from-iteration N flag
- Context threshold override: --context-threshold 85 flag for power users
- Checkpoint pruning: Auto-delete old checkpoints >7 days

## Notes

**Backward Compatibility**: This refactor is **fully backward compatible**. Existing plans work without modification. Small plans complete in 1 iteration (identical behavior to current single-shot). Only large plans benefit from multi-iteration capability.

**No Breaking Changes**:
- Plan format unchanged (same checkboxes, phase headers, dependencies)
- Agent interfaces unchanged (implementer-coordinator already has continuation support)
- State machine transitions unchanged (implement → test preserved)
- Checkpoint schema extended (V2.0 → V2.1), not replaced

**Validation Strategy**: Phase 5 includes backward compatibility tests against all existing plan levels (0, 1, 2) to ensure no regressions.

## Related Documentation

- [State-Based Orchestration Overview](/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md)
- [Build Command Guide](/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md)
- [Implementer-Coordinator Agent](/home/benjamin/.config/.claude/agents/implementer-coordinator.md)
- [Implementation-Executor Agent](/home/benjamin/.config/.claude/agents/implementation-executor.md)
- [Workflow State Machine Library](/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh)
- [Error Handling Pattern](/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)
- [Checkpoint Utilities](/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh)
