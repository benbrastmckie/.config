# Implementation Plan: Lean Command Parallel Subagent Orchestration

## Metadata
- **Date**: 2025-12-03
- **Feature**: Refactor /lean command to support parallel subagent orchestration with plan progress updates and persistence loops similar to /implement
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 22-28 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-lean-orchestration-patterns.md](../reports/001-lean-orchestration-patterns.md)

---

## Research Summary

The research analyzed the current single-agent /lean command architecture and documented patterns from /implement for parallel subagent orchestration. Key findings:

1. **Current Architecture**: /lean uses single lean-implementer agent with no parallelization, no plan file support, and no persistence loop
2. **Target Pattern**: /implement demonstrates mature wave-based parallel execution with implementer-coordinator pattern, achieving 40-70% time savings
3. **Infrastructure Available**: checkbox-utils.sh provides comprehensive plan progress tracking, dependency-analyzer.sh enables wave structure generation
4. **Parallelization Opportunity**: Lean theorem proving can parallelize at theorem-level (1 theorem per phase), with coordination for MCP rate limits (3 requests/30s for external search tools)
5. **Persistence Need**: Large proof sessions (10+ theorems) require iteration loop with context estimation and checkpoint saving

**Recommended Architecture**:
- Create lean-coordinator agent based on implementer-coordinator pattern
- Modify lean-implementer to accept theorem_tasks subset and rate_limit_budget parameters
- Add plan support, iteration loop, and phase marker recovery to /lean command
- Use theorem-level parallelization with budget allocation for MCP rate limit coordination

---

## Technical Design

### Architecture Components

#### 1. Plan Format for Lean Workflows

**Structure**: 1 Phase = 1 Theorem (for clean parallelization)

```markdown
### Phase N: Prove [Theorem Name] [NOT STARTED]

**Theorem**: theorem_name
**Location**: File.lean:LINE
**Goal**: ⊢ proof_goal
**Dependencies**: depends_on: [Phase 1, Phase 2] or []

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for applicable theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build
```

**Dependency Syntax**: Uses standard `depends_on:` for wave-based execution
**Progress Markers**: Standard [NOT STARTED] → [IN PROGRESS] → [COMPLETE] transitions

#### 2. lean-coordinator Agent

**Based on**: implementer-coordinator.md pattern
**Model**: haiku-4.5 (deterministic coordination, mechanical orchestration)
**Responsibilities**:
1. Parse plan file or generate implicit plan from Lean file sorry markers
2. Invoke dependency-analyzer for wave structure
3. Execute waves with parallel lean-implementer instances
4. Coordinate MCP rate limit budget allocation (3 requests/30s shared)
5. Collect proof results and aggregate metrics
6. Create consolidated proof summary
7. Handle context estimation and checkpoint creation

**Rate Limit Coordination Strategy**: Budget Allocation
- Wave with N agents: Each gets 3/N external search requests
- Agents prioritize lean_local_search (no rate limit)
- Agents use budget for critical theorems only

#### 3. lean-implementer Modifications

**New Input Parameters**:
- `theorem_tasks`: Array of theorem objects (name, line, phase_number, dependencies)
- `plan_path`: Optional path to plan file for progress tracking
- `rate_limit_budget`: Number of external search requests allowed (default: 3)

**Modified Workflow**:
- Process only assigned theorem_tasks (not all sorry markers)
- Respect rate_limit_budget (prioritize lean_local_search)
- Update plan file with progress markers if plan_path provided
- Return THEOREM_BATCH_COMPLETE signal with per-wave metrics

**Output Signal**:
```yaml
THEOREM_BATCH_COMPLETE:
  theorems_completed: [list]
  theorems_partial: [list]
  tactics_used: [list]
  mathlib_theorems: [list]
  diagnostics: [list]
  context_exhausted: true|false
  work_remaining: 0 or list
```

#### 4. /lean Command Refactoring

**New Block Structure**:
- **Block 1a**: Setup & Plan Detection (support both .lean and .md files)
- **Block 1b**: lean-coordinator Invocation (HARD BARRIER)
- **Block 1c**: Verification & Iteration Check (parse work_remaining, determine continuation)
- **Block 1d**: Phase Marker Recovery (validate/recover [COMPLETE] markers)
- **Block 2**: Completion & Summary

**Iteration Loop Variables**:
- ITERATION, MAX_ITERATIONS (default: 5)
- CONTINUATION_CONTEXT (path to previous summary)
- WORK_REMAINING (space-separated theorem names)
- STUCK_COUNT (tracks lack of progress)

**Execution Modes**:
- `file-based`: Lean file provided, create implicit plan in-memory
- `plan-based`: Plan file provided, use structured phases

---

## Implementation Phases

### Phase 1: Basic Plan Support for /lean (No Parallelization Yet) [COMPLETE]

**Dependencies**: depends_on: []

**Objective**: Add plan file detection and progress tracking to /lean command without introducing parallelization. This establishes the foundation for coordinator integration.

**Tasks**:
- [x] Update /lean Block 1a to detect plan files (.md extension)
- [x] Add plan file parsing logic (extract lean_file_path from plan metadata)
- [x] Add execution mode detection (file-based vs plan-based)
- [x] Source checkbox-utils.sh in Block 1a
- [x] Add legacy plan detection and [NOT STARTED] marker initialization
- [x] Add starting phase [IN PROGRESS] marker in Block 1a
- [x] Update plan metadata status to IN PROGRESS
- [x] Modify lean-implementer input contract to accept optional plan_path parameter
- [x] Add progress tracking to lean-implementer STEP 6 (mark_phase_complete, add_complete_marker)
- [x] Test with sample Lean plan file (single theorem, verify markers update)

**Testing Strategy**:
- Create test plan file with 1 theorem phase
- Run /lean with plan file, verify [IN PROGRESS] marker added
- Verify lean-implementer updates markers to [COMPLETE]
- Verify plan metadata status updates to COMPLETE

**Files Modified**:
- `.claude/commands/lean.md` (Block 1a plan detection)
- `.claude/agents/lean-implementer.md` (plan_path parameter, progress tracking)

**Estimated Duration**: 3-4 hours

---

### Phase 2: Create lean-coordinator Agent [NOT STARTED]

**Dependencies**: depends_on: [Phase 1]

**Objective**: Create lean-coordinator agent based on implementer-coordinator pattern for wave-based parallel theorem proving orchestration.

**Tasks**:
- [ ] Create `.claude/agents/lean-coordinator.md` from implementer-coordinator template
- [ ] Update frontmatter (model: haiku-4.5, description, allowed-tools)
- [ ] Implement STEP 1: Plan Structure Detection (parse Lean plan for theorem phases)
- [ ] Implement STEP 2: Dependency Analysis (invoke dependency-analyzer.sh)
- [ ] Implement STEP 3: Wave Execution Loop (iterate over waves, collect completion reports)
- [ ] Implement parallel Task invocation pattern (multiple lean-implementer calls in single message)
- [ ] Implement MCP rate limit budget allocation (budget = 3 / num_agents_in_wave)
- [ ] Implement progress monitoring (collect theorems_proven, tactics_used, mathlib_theorems)
- [ ] Implement STEP 4: Verification (run lean_build once per wave)
- [ ] Implement STEP 5: Result Aggregation (create consolidated proof summary)
- [ ] Add output signal format (PROOF_COMPLETE with work_remaining field)
- [ ] Document rate limit coordination strategy in agent guidelines
- [ ] Create unit test for dependency analysis parsing
- [ ] Create integration test for single-wave execution (2 theorems parallel)

**Testing Strategy**:
- Create plan with 3 theorems (1 in Wave 1, 2 in Wave 2 parallel)
- Invoke lean-coordinator directly with Task tool
- Verify wave structure generated correctly
- Verify parallel Task invocations in Wave 2
- Verify consolidated summary created
- Verify lean_build runs once per wave

**Files Created**:
- `.claude/agents/lean-coordinator.md`

**Estimated Duration**: 5-6 hours

---

### Phase 3: Modify lean-implementer for Theorem Batches [NOT STARTED]

**Dependencies**: depends_on: [Phase 2]

**Objective**: Update lean-implementer agent to accept theorem_tasks subset and rate_limit_budget parameters for parallel coordination.

**Tasks**:
- [ ] Add theorem_tasks parameter to input contract (array of theorem objects)
- [ ] Add rate_limit_budget parameter (default: 3)
- [ ] Modify STEP 1 to process only assigned theorem_tasks (not all sorry markers)
- [ ] Update STEP 3 to prioritize lean_local_search over rate-limited tools
- [ ] Add rate limit budget tracking (decrement on each external search tool use)
- [ ] Add budget exhaustion handling (fall back to lean_local_search)
- [ ] Update output signal to THEOREM_BATCH_COMPLETE format
- [ ] Add work_remaining field to output (list theorems with remaining sorry)
- [ ] Update STEP 8 to create per-wave summary (not full-session summary)
- [ ] Add context_exhausted field to output (estimate based on theorem count)
- [ ] Test with theorem_tasks=[theorem1, theorem2], verify both processed
- [ ] Test with rate_limit_budget=1, verify only 1 external search used
- [ ] Test batch completion signal parsing

**Testing Strategy**:
- Create Lean file with 3 theorems (all with sorry)
- Invoke lean-implementer with theorem_tasks=[theorem1, theorem2]
- Verify only theorem1 and theorem2 processed (theorem3 untouched)
- Invoke with rate_limit_budget=1, verify lean_local_search prioritized
- Verify THEOREM_BATCH_COMPLETE signal returned
- Verify work_remaining includes theorem3

**Files Modified**:
- `.claude/agents/lean-implementer.md` (input contract, workflow steps)

**Estimated Duration**: 4-5 hours

---

### Phase 4: Add Iteration Loop to /lean Command [NOT STARTED]

**Dependencies**: depends_on: [Phase 3]

**Objective**: Implement persistence loop pattern in /lean command with context estimation, checkpoint saving, and stuck detection for handling large proof sessions.

**Tasks**:
- [ ] Add iteration variables to Block 1a (ITERATION, MAX_ITERATIONS, CONTINUATION_CONTEXT, STUCK_COUNT)
- [ ] Add --max-iterations flag parsing (default: 5)
- [ ] Add --context-threshold flag parsing (default: 90%)
- [ ] Persist iteration variables via append_workflow_state
- [ ] Create lean workspace directory for iteration summaries
- [ ] Update lean-coordinator input contract to include iteration parameters
- [ ] Add Block 1c verification section (parse work_remaining from coordinator)
- [ ] Implement iteration decision logic (check requires_continuation signal)
- [ ] Add stuck detection (track WORK_REMAINING across iterations)
- [ ] Add iteration state update for next iteration
- [ ] Add continuation context saving (copy summary to workspace)
- [ ] Implement iteration loop back to Block 1b (re-invoke coordinator)
- [ ] Add max iterations check before re-invocation
- [ ] Test with large Lean file (10 theorems), verify multi-iteration execution
- [ ] Test stuck detection (same work_remaining for 2 iterations)

**Testing Strategy**:
- Create Lean file with 10 theorems requiring multiple iterations
- Run /lean with --max-iterations=3
- Verify iteration counter increments
- Verify continuation context passed between iterations
- Simulate stuck scenario (modify coordinator to return same work_remaining)
- Verify stuck detection triggers halt

**Files Modified**:
- `.claude/commands/lean.md` (Block 1a, Block 1c iteration logic)
- `.claude/agents/lean-coordinator.md` (context estimation, checkpoint creation)

**Estimated Duration**: 4-5 hours

---

### Phase 5: Add Phase Marker Recovery (Block 1d) [NOT STARTED]

**Dependencies**: depends_on: [Phase 4]

**Objective**: Add phase marker validation and recovery to /lean command to ensure plan file reflects actual proof completion state after parallel execution.

**Tasks**:
- [ ] Add Block 1d to /lean command after Block 1c
- [ ] Source checkbox-utils.sh in Block 1d
- [ ] Load workflow state (PLAN_FILE, WORKFLOW_ID)
- [ ] Count total phases and phases with [COMPLETE] marker
- [ ] Implement recovery loop for missing markers
- [ ] For each phase without marker, check if all tasks complete (verify_phase_complete)
- [ ] If complete, mark all tasks (mark_phase_complete) and add marker (add_complete_marker)
- [ ] Verify checkbox consistency across hierarchy (verify_checkbox_consistency)
- [ ] Update plan metadata status to COMPLETE if all phases done (check_all_phases_complete)
- [ ] Persist validation results (PHASES_WITH_MARKER count)
- [ ] Save completed states to state file (save_completed_states_to_state)
- [ ] Test with plan where coordinator failed to update markers
- [ ] Verify recovery detects and fixes missing markers
- [ ] Test with partially complete plan (some phases incomplete)
- [ ] Verify only complete phases get markers

**Testing Strategy**:
- Create plan with 3 theorem phases
- Run lean-coordinator to complete 2 phases (simulate marker update failure)
- Run /lean Block 1d recovery
- Verify missing [COMPLETE] markers added
- Verify plan metadata status remains IN PROGRESS (not all complete)
- Complete final phase, re-run recovery
- Verify plan metadata updates to COMPLETE

**Files Modified**:
- `.claude/commands/lean.md` (new Block 1d)

**Estimated Duration**: 2-3 hours

---

### Phase 6: MCP Rate Limit Coordination Testing [NOT STARTED]

**Dependencies**: depends_on: [Phase 5]

**Objective**: Test and validate MCP rate limit coordination across parallel lean-implementer instances to ensure compliance with 3 requests/30s combined limit.

**Tasks**:
- [ ] Create test plan with 6 theorem phases (2 waves of 3 theorems each)
- [ ] Add instrumentation to lean-implementer to log search tool usage
- [ ] Run /lean with plan, verify Wave 1 agents each get budget=1 (3/3)
- [ ] Verify total external search calls in Wave 1 ≤ 3
- [ ] Verify lean_local_search prioritized when budget exhausted
- [ ] Run /lean with plan, verify Wave 2 agents respect 30s window
- [ ] Add rate limit backoff test (simulate rate limit error response)
- [ ] Verify agent falls back to lean_local_search on rate limit error
- [ ] Test sequential fallback strategy (stagger agent start times by 10s)
- [ ] Create performance benchmark (time savings vs sequential execution)
- [ ] Document rate limit best practices in lean-coordinator agent
- [ ] Add rate limit troubleshooting section to lean command guide

**Testing Strategy**:
- Create Lean file with 6 theorems (all require Mathlib search)
- Run /lean with plan (2 waves of 3 parallel agents)
- Monitor search tool usage in agent logs
- Verify external search calls ≤ 3 per 30s window
- Simulate rate limit error (mock MCP server response)
- Verify graceful degradation to lean_local_search
- Measure total execution time vs sequential baseline

**Files Modified**:
- `.claude/agents/lean-implementer.md` (add search tool logging)
- `.claude/agents/lean-coordinator.md` (rate limit documentation)
- `.claude/docs/guides/commands/lean-command-guide.md` (troubleshooting section)

**Estimated Duration**: 3-4 hours

---

### Phase 7: Testing and Validation [NOT STARTED]

**Dependencies**: depends_on: [Phase 6]

**Objective**: Comprehensive testing of all components including unit tests, integration tests, and end-to-end workflow validation.

**Tasks**:
- [ ] Create test suite directory `.claude/tests/lean/`
- [ ] Write unit test for theorem extraction from Lean files
- [ ] Write unit test for dependency graph parsing from Lean plans
- [ ] Write unit test for wave structure generation
- [ ] Write unit test for rate limit budget allocation
- [ ] Write integration test for single theorem proof (baseline)
- [ ] Write integration test for multi-theorem proof with dependencies (3 theorems, 2 waves)
- [ ] Write integration test for multi-theorem proof without dependencies (3 theorems, 1 wave parallel)
- [ ] Write integration test for large proof session (10+ theorems, persistence loop)
- [ ] Write integration test for plan file workflow (plan → parallel proof → summary)
- [ ] Write integration test for file-based workflow (Lean file → implicit plan → proof)
- [ ] Test checkpoint resumption (--resume flag)
- [ ] Test dry-run mode (preview only, no execution)
- [ ] Run all tests and document results in test report
- [ ] Add continuous integration workflow for lean tests

**Testing Strategy**:
- Run all unit tests with bash test runner
- Run all integration tests sequentially
- Verify success rate ≥ 95%
- Document any known limitations or edge cases
- Create test fixtures (sample Lean files with varying theorem counts)
- Measure performance metrics (time savings, parallelization efficiency)

**Files Created**:
- `.claude/tests/lean/unit/test_theorem_extraction.sh`
- `.claude/tests/lean/unit/test_dependency_parsing.sh`
- `.claude/tests/lean/integration/test_single_theorem.sh`
- `.claude/tests/lean/integration/test_parallel_wave.sh`
- `.claude/tests/lean/integration/test_persistence_loop.sh`
- `.claude/tests/lean/fixtures/sample_theorems.lean`

**Estimated Duration**: 4-5 hours

---

### Phase 8: Documentation [NOT STARTED]

**Dependencies**: depends_on: [Phase 7]

**Objective**: Complete documentation for all new components including command guide, agent references, and architecture overview.

**Tasks**:
- [ ] Create `.claude/docs/guides/commands/lean-command-guide.md`
- [ ] Document /lean command syntax with all flags (--prove-all, --verify, --max-iterations, --resume)
- [ ] Document plan-based vs file-based execution modes
- [ ] Document iteration loop behavior and checkpoint management
- [ ] Create lean-coordinator agent reference in `.claude/docs/reference/agents/`
- [ ] Document wave-based execution pattern for Lean workflows
- [ ] Document MCP rate limit coordination strategy
- [ ] Add troubleshooting section for common issues
- [ ] Create architecture diagram for Lean parallel orchestration
- [ ] Update CLAUDE.md with lean workflow section
- [ ] Add example plan templates to `.claude/docs/examples/lean/`
- [ ] Document theorem-level parallelization best practices
- [ ] Add performance metrics section (expected time savings)
- [ ] Update lean-implementer agent reference with new parameters
- [ ] Review and update all inline documentation in agents and commands

**Testing Strategy**:
- Review all documentation for accuracy
- Test all code examples in documentation
- Verify all links resolve correctly
- Run vale linter on markdown documentation
- Get peer review of architecture diagram

**Files Created**:
- `.claude/docs/guides/commands/lean-command-guide.md`
- `.claude/docs/reference/agents/lean-coordinator-reference.md`
- `.claude/docs/examples/lean/theorem-plan-template.md`
- `.claude/docs/architecture/lean-parallel-orchestration.md`

**Files Modified**:
- `CLAUDE.md` (add lean workflow section)
- `.claude/docs/reference/agents/lean-implementer-reference.md` (update parameters)

**Estimated Duration**: 3-4 hours

---

## Testing Strategy

### Unit Tests
- Theorem extraction from Lean files (grep sorry markers)
- Dependency graph parsing from Lean plans (extract depends_on clauses)
- Wave structure generation (topological sort, wave assignment)
- Rate limit budget allocation (3 / num_agents calculation)

### Integration Tests
- Single theorem proof (baseline, verify proof completes)
- Multi-theorem parallel proof (2 theorems, 1 wave, verify both complete)
- Sequential waves (3 theorems with dependencies, 2 waves)
- Large proof session (10 theorems, verify persistence loop)
- Plan file workflow (plan → parallel proof → summary)
- File-based workflow (Lean file → implicit plan → proof)

### MCP Rate Limit Tests
- Budget allocation compliance (verify ≤ 3 requests/30s per wave)
- Graceful degradation (fallback to lean_local_search on limit)
- Rate limit backoff (retry after 30s window)

### Progress Tracking Tests
- Phase marker updates ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])
- Checkbox state propagation (task complete → phase complete)
- Phase marker recovery (detect and fix missing markers)
- Plan metadata status updates (IN PROGRESS → COMPLETE)

### Performance Tests
- Time savings measurement (parallel vs sequential)
- Parallelization efficiency (actual vs theoretical speedup)
- Context estimation accuracy (estimated vs actual token usage)

---

## Documentation Requirements

### Command Documentation
- `/lean` command guide with all flags and examples
- Plan-based vs file-based execution mode comparison
- Iteration loop and checkpoint management guide
- Troubleshooting guide for common issues

### Agent Documentation
- lean-coordinator agent reference (role, workflow, signals)
- lean-implementer updates reference (new parameters, modified workflow)
- Wave-based execution pattern documentation
- MCP rate limit coordination strategy guide

### Architecture Documentation
- Lean parallel orchestration architecture diagram
- Theorem-level parallelization pattern
- Persistence loop pattern for large proof sessions
- State machine integration for Lean workflows

### Example Documentation
- Theorem plan template with dependencies
- Sample Lean file with multiple theorems
- Multi-wave execution example with metrics
- Rate limit coordination example

---

## Success Criteria

Implementation is successful if:

1. **Plan Support**: /lean accepts both .lean and .md files, detects execution mode correctly
2. **Parallelization**: Multiple theorems proven in parallel within waves (verified by task timing)
3. **Progress Tracking**: Plan file updates with [NOT STARTED] → [IN PROGRESS] → [COMPLETE] markers
4. **Persistence Loop**: Large proof sessions (10+ theorems) complete across multiple iterations
5. **Phase Recovery**: Missing [COMPLETE] markers detected and recovered in Block 1d
6. **Rate Limit Compliance**: MCP external search tools ≤ 3 requests/30s across all parallel agents
7. **Time Savings**: Parallel execution achieves 40-60% time savings vs sequential (measured on sample workload)
8. **Test Coverage**: All unit and integration tests pass with ≥ 95% success rate
9. **Documentation**: Complete command guide, agent references, and architecture documentation
10. **Backward Compatibility**: Existing /lean file-based workflows continue to work without modification

---

## Risk Assessment

### High Risk
- **MCP Rate Limits**: External search tools share 3 req/30s limit, coordination failure could cause throttling
  - **Mitigation**: Prioritize lean_local_search, implement budget allocation, add backoff logic

### Medium Risk
- **Context Exhaustion**: Large proof sessions (20+ theorems) may exceed context window
  - **Mitigation**: Implement persistence loop with context estimation, max 5 iterations default
- **Dependency Cycles**: Invalid plan with circular theorem dependencies could deadlock
  - **Mitigation**: dependency-analyzer.sh validates graph, rejects plans with cycles

### Low Risk
- **Checkpoint Corruption**: Checkpoint file corruption could prevent resumption
  - **Mitigation**: Use atomic writes (temp file + mv), validate checkpoint schema on load
- **Marker Synchronization**: Parallel agents updating same plan file could cause conflicts
  - **Mitigation**: Block 1d recovery validates and fixes markers after all agents complete

---

## Notes

### Implementation Order Rationale

Phase 1 establishes foundation (plan support + progress tracking) before introducing complexity. Phase 2-3 create core orchestration components (coordinator + modified implementer) as independent units. Phase 4-5 add advanced features (iteration loop + recovery) after core parallelization proven. Phase 6 focuses on critical constraint (rate limits) before comprehensive testing. Phase 7-8 validate and document the complete system.

### Migration Path

Existing /lean file-based workflows remain unchanged (backward compatible). New plan-based workflows are opt-in via .md file extension. Users can gradually adopt parallelization by creating plan files for complex proof sessions while continuing to use file-based mode for simple cases.

### Performance Expectations

**Baseline** (Current /lean):
- 10 theorems sequential: 150 minutes (15 min/theorem average)

**Target** (With Parallelization):
- 10 theorems, 2 waves (5 per wave): 30-45 minutes (60-70% time savings)
- Actual savings depend on theorem difficulty distribution and MCP rate limits

**Realistic Estimate**:
- Complex plans with dependencies: 50-60% time savings
- Simple plans without dependencies: 70-80% time savings
- Single theorem or small batches: Minimal overhead vs sequential

### Future Enhancements

- **File-Level Parallelization**: Extend to multi-file Lean projects using lakefile dependencies
- **Adaptive Rate Limiting**: Dynamic budget allocation based on search tool effectiveness
- **Proof Strategy Learning**: Track successful tactic patterns across theorems for better candidate generation
- **Interactive Mode**: Allow user to review and approve tactic applications before Edit tool invocation
