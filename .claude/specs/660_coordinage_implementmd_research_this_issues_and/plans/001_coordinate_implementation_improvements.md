# /coordinate Implementation Phase Improvements

## Metadata
- **Date**: 2025-11-11
- **Feature**: Replace /coordinate's SlashCommand invocation of /implement with proper implementer-coordinator agent delegation following Standard 11
- **Scope**: Fix implementation phase (Phase 3) to use behavioral injection pattern, integrate with state-based orchestration, and enable wave-based parallel execution
- **Estimated Phases**: 6
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [/coordinate Implementation Approach Analysis](../reports/001_coordinate_implementation_approach.md)
  - [Infrastructure and Standards Research](../reports/002_infrastructure_and_standards.md)
- **Structure Level**: 0
- **Complexity Score**: 45.0

## Overview

The /coordinate command currently violates Standard 11 (Imperative Agent Invocation Pattern) by invoking /implement as a slash command through the Task tool, rather than delegating directly to the implementer-coordinator agent. This creates command-to-command invocation issues including context bloat, loss of path control, and breaks wave-based parallel execution.

This plan replaces the SlashCommand pattern with proper behavioral injection, enabling wave-based parallel implementation, maintaining 100% file creation reliability, and achieving 40-60% time savings through parallel execution of independent phases.

## Research Summary

**Key Findings from Research Reports:**

1. **Current /coordinate Implementation** (Report 001):
   - Lines 1089-1107 invoke /implement as a slash command via Task tool
   - Causes command-to-command invocation anti-pattern
   - Prevents wave-based execution (uses sequential /implement instead)
   - Creates context bloat (nests full 5,000+ line /implement prompt)
   - Loses artifact path control

2. **Correct Patterns** (Report 001):
   - /orchestrate (lines 376-396): Properly invokes implementer-coordinator agent with behavioral injection
   - /supervise (lines 260-273): Minimal agent delegation pattern
   - Both use `Read and follow: .claude/agents/implementer-coordinator.md` pattern
   - Both inject plan path and workflow options directly
   - Both receive metadata-only responses (95% context reduction)

3. **Standard 11 Requirements** (Report 002, lines 179-245):
   - Imperative directive: `**EXECUTE NOW**: USE the Task tool...`
   - Behavioral reference: `Read and follow: .claude/agents/[agent].md`
   - Context injection: Pre-calculated paths, constraints, specifications
   - Completion signal: `Return: IMPLEMENTATION_COMPLETE: [summary]`
   - NO code block wrappers, NO "Example" prefixes, NO documentation-only YAML

4. **Infrastructure Available** (Report 002):
   - State machine library (workflow-state-machine.sh): sm_transition(), sm_execute()
   - State persistence (state-persistence.sh): GitHub Actions-style state files
   - Dependency analyzer (dependency-analyzer.sh): Wave calculation, parallelization metrics
   - Metadata extraction: 95.6% context reduction achieved
   - Error handling: Fail-fast with clear diagnostics

5. **Performance Targets** (Report 002, lines 30-35):
   - Code reduction: 48.9% achieved across orchestrators
   - State operations: 67% performance improvement
   - Context reduction: 95.6% via hierarchical supervisors
   - Time savings: 40-60% via wave-based execution
   - Reliability: 100% file creation maintained

**Recommended Approach:**
Replace SlashCommand invocation (lines 1089-1107) with direct implementer-coordinator agent delegation following /orchestrate's proven pattern, integrate with state machine architecture, and leverage dependency analyzer for wave-based execution.

## Success Criteria

- [ ] /coordinate implementation phase uses implementer-coordinator agent (not /implement command)
- [ ] Agent invocation follows Standard 11 pattern (imperative directive, behavioral reference, no code blocks)
- [ ] Wave-based parallel execution enabled for independent phases
- [ ] All artifact paths pre-calculated in Phase 0 and injected into agent
- [ ] State machine transitions properly manage implementation state
- [ ] Verification checkpoint confirms expected artifacts created
- [ ] Context reduction achieved (metadata-only response from agent)
- [ ] Time savings measured and documented (target: 40-60% for plans with parallel phases)
- [ ] All existing tests continue to pass
- [ ] Command guide updated with new architecture

## Technical Design

### Architecture Changes

**Current Flow (Anti-Pattern):**
```
/coordinate Phase 3 → Task tool invokes "/implement $PLAN_PATH" →
  Full /implement command loads (5,000+ lines) →
  Sequential phase execution →
  Full output returned (context bloat)
```

**New Flow (Behavioral Injection):**
```
/coordinate Phase 0 → Pre-calculate all artifact paths →
/coordinate Phase 3 → Task tool invokes implementer-coordinator agent →
  Agent reads behavioral file →
  Receives injected context (plan path, artifact paths) →
  Wave-based parallel execution →
  Returns metadata only (95% context reduction)
```

### Component Integration

1. **State Machine Integration**:
   - Use sm_transition() to move from STATE_PLAN to STATE_IMPLEMENT
   - Execute implementation via sm_execute() pattern
   - Transition to STATE_TEST after successful completion
   - Handle errors via sm_error() with retry logic (max 2 retries)

2. **Path Pre-Calculation (Phase 0)**:
   - Calculate and export: REPORTS_DIR, PLANS_DIR, SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINT_DIR
   - Store in state file via append_workflow_state()
   - Load in implementation phase via load_workflow_state()

3. **Agent Delegation (Phase 3)**:
   - Use imperative directive: `**EXECUTE NOW**: USE the Task tool`
   - Reference behavioral file: `.claude/agents/implementer-coordinator.md`
   - Inject complete context: plan path, artifact directories, workflow options
   - Specify completion signal: `Return: IMPLEMENTATION_COMPLETE: [summary]`

4. **Wave-Based Execution**:
   - implementer-coordinator uses dependency-analyzer.sh internally
   - Parses plan dependencies automatically
   - Executes phases in parallel waves
   - Achieves 40-60% time savings for plans with independent phases

5. **Verification Checkpoint**:
   - After agent returns, verify plan file exists
   - Check for implementation summary (optional)
   - Validate state transition completed
   - Report any missing artifacts with diagnostic commands

### Files Modified

- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1089-1107): Replace SlashCommand with agent delegation
- `/home/benjamin/.config/.claude/commands/coordinate.md` (Phase 0): Add artifact path calculations
- `/home/benjamin/.config/.claude/commands/coordinate.md` (frontmatter): Update dependent-commands/dependent-agents
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md`: Document architecture changes

## Implementation Phases

### Phase 0: Preparation and Analysis [COMPLETED]
dependencies: []

**Objective**: Analyze current /coordinate implementation, validate research findings, and prepare test environment

**Complexity**: Low

**Tasks**:
- [x] Read current /coordinate command file: /home/benjamin/.config/.claude/commands/coordinate.md
- [x] Locate exact lines requiring changes (verify lines 1089-1107 contain SlashCommand invocation)
- [x] Read implementer-coordinator agent behavioral file: /home/benjamin/.config/.claude/agents/implementer-coordinator.md
- [x] Review /orchestrate's correct pattern: /home/benjamin/.config/.claude/commands/orchestrate.md lines 376-396
- [x] Review /supervise's minimal pattern: /home/benjamin/.config/.claude/commands/supervise.md lines 260-273
- [x] Identify all required library functions (state-persistence.sh, workflow-state-machine.sh, dependency-analyzer.sh)
- [x] Create backup of coordinate.md before modifications
- [x] Set up test plan with parallel phase dependencies for validation

**Testing**:
```bash
# Verify file locations and line numbers
grep -n "Execute the /implement slash command" /home/benjamin/.config/.claude/commands/coordinate.md
test -f /home/benjamin/.config/.claude/agents/implementer-coordinator.md && echo "Agent file exists"

# Verify library availability
test -f /home/benjamin/.config/.claude/lib/workflow-state-machine.sh && echo "State machine available"
test -f /home/benjamin/.config/.claude/lib/state-persistence.sh && echo "State persistence available"
test -f /home/benjamin/.config/.claude/lib/dependency-analyzer.sh && echo "Dependency analyzer available"
```

**Expected Duration**: 1 hour

**Phase 0 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (verification commands executed successfully)
- [ ] Git commit created: `feat(660): complete Phase 0 - Preparation and Analysis`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 1: Add Artifact Path Pre-Calculation to Phase 0 [COMPLETED]
dependencies: [0]

**Objective**: Extend /coordinate Phase 0 to calculate all artifact paths required by implementer-coordinator agent

**Complexity**: Medium

**Tasks**:
- [x] Locate Phase 0 section in coordinate.md (after topic directory creation)
- [x] Add artifact path calculations using pattern from /orchestrate:
  - [x] REPORTS_DIR="${TOPIC_PATH}/reports"
  - [x] PLANS_DIR="${TOPIC_PATH}/plans"
  - [x] SUMMARIES_DIR="${TOPIC_PATH}/summaries"
  - [x] DEBUG_DIR="${TOPIC_PATH}/debug"
  - [x] OUTPUTS_DIR="${TOPIC_PATH}/outputs"
  - [x] CHECKPOINT_DIR="${HOME}/.claude/data/checkpoints"
- [x] Export paths for cross-bash-block availability
- [x] Add paths to state file via append_workflow_state() for persistence
- [x] Add comment explaining paths will be injected into implementer-coordinator

**Testing**:
```bash
# Manual verification after edit
grep -A 10 "REPORTS_DIR=" /home/benjamin/.config/.claude/commands/coordinate.md
grep -A 10 "export.*REPORTS_DIR" /home/benjamin/.config/.claude/commands/coordinate.md

# Verify state persistence integration
grep "append_workflow_state" /home/benjamin/.config/.claude/commands/coordinate.md | grep -i "reports_dir\|plans_dir"
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (grep commands show expected additions)
- [ ] Git commit created: `feat(660): complete Phase 1 - Add Artifact Path Pre-Calculation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Replace SlashCommand Invocation with Agent Delegation [COMPLETED]
dependencies: [1]

**Objective**: Replace /implement command invocation with direct implementer-coordinator agent delegation following Standard 11

**Complexity**: High

**Tasks**:
- [x] Locate implementation phase invocation (coordinate.md lines 1089-1107)
- [x] Replace entire Task block with Standard 11 compliant pattern:
  - [x] Add imperative directive: `**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator`
  - [x] Remove code block wrappers (no ` ```yaml `)
  - [x] Reference behavioral file: `Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md`
  - [x] Inject plan path: `Plan File: $PLAN_PATH`
  - [x] Inject artifact paths: All directories from Phase 0 (REPORTS_DIR, PLANS_DIR, etc.)
  - [x] Inject workflow options if applicable
  - [x] Specify execution requirements: wave-based parallel execution, automated testing, git commits, checkpoint state management
  - [x] Specify completion signal: `Return: IMPLEMENTATION_COMPLETE: [summary]`
- [x] Remove any reference to "/implement slash command" in description
- [x] Update description to: "Execute implementation with wave-based parallel execution"
- [x] Verify no documentation-only markers remain ("Example", etc.)

**Testing**:
```bash
# Verify pattern changes
grep -A 20 "EXECUTE NOW.*implementer-coordinator" /home/benjamin/.config/.claude/commands/coordinate.md
grep "Read and follow.*implementer-coordinator.md" /home/benjamin/.config/.claude/commands/coordinate.md
grep "/implement" /home/benjamin/.config/.claude/commands/coordinate.md | grep -v "comment\|guide" && echo "ERROR: Found /implement reference" || echo "OK: No /implement references"

# Verify no code block wrappers
grep -B 2 -A 15 "implementer-coordinator" /home/benjamin/.config/.claude/commands/coordinate.md | grep '```' && echo "ERROR: Code block wrapper found" || echo "OK: No code blocks"
```

**Expected Duration**: 1.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (verification commands show expected pattern)
- [ ] Git commit created: `feat(660): complete Phase 2 - Replace SlashCommand with Agent Delegation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Add State Machine Integration [COMPLETED]
dependencies: [2]

**Objective**: Integrate implementation phase with state machine for proper lifecycle management

**Complexity**: Medium

**Tasks**:
- [x] Add state transition before implementation: `sm_transition "$STATE_IMPLEMENT"` (already present at line 1033)
- [x] Load workflow state at start of implementation phase: `load_workflow_state "$WORKFLOW_ID"` (already present at line 1085, 1168)
- [x] Wrap agent invocation with state execution pattern if applicable (state verification present at line 1099)
- [x] Add state transition after successful completion: `sm_transition "$STATE_TEST"` (already present at line 1215)
- [x] Add error handling via state machine: `handle_state_error "Implementation failed" 1` (added at line 1179)
- [x] Parse agent response for IMPLEMENTATION_COMPLETE signal (implicit verification via file existence)
- [x] Store implementation summary in state file if needed (added IMPLEMENTATION_COMPLETED, IMPLEMENTATION_TIMESTAMP)
- [x] Add state persistence calls for resumability (already present at lines 1034, 1216)

**Testing**:
```bash
# Verify state machine integration
grep "sm_transition.*STATE_IMPLEMENT" /home/benjamin/.config/.claude/commands/coordinate.md
grep "sm_transition.*STATE_TEST" /home/benjamin/.config/.claude/commands/coordinate.md
grep "handle_state_error" /home/benjamin/.config/.claude/commands/coordinate.md

# Verify state persistence
grep "load_workflow_state" /home/benjamin/.config/.claude/commands/coordinate.md | grep -A 5 -B 5 "implementation\|implement"
```

**Expected Duration**: 1 hour

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (state machine calls verified)
- [ ] Git commit created: `feat(660): complete Phase 3 - Add State Machine Integration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Add Verification Checkpoint and Error Handling
dependencies: [3]

**Objective**: Add mandatory verification checkpoint to ensure implementer-coordinator creates expected artifacts

**Complexity**: Medium

**Tasks**:
- [ ] Add verification checkpoint after agent returns
- [ ] Verify plan file exists: `test -f "$PLAN_PATH"`
- [ ] Check for implementation summary (optional, non-critical): `ls $SUMMARIES_DIR/[0-9][0-9][0-9]_implementation_summary.md`
- [ ] Validate IMPLEMENTATION_COMPLETE signal received
- [ ] Add fail-fast error handling with diagnostics if verification fails:
  - [ ] Show expected vs actual artifact paths
  - [ ] Display agent output/error messages
  - [ ] List diagnostic commands (check permissions, verify agent file, etc.)
  - [ ] Exit with non-zero status
- [ ] Add success message showing artifacts created
- [ ] Log verification results using unified-logger.sh

**Testing**:
```bash
# Verify checkpoint added
grep -A 10 "Verify implementation artifacts" /home/benjamin/.config/.claude/commands/coordinate.md
grep "test -f.*PLAN_PATH" /home/benjamin/.config/.claude/commands/coordinate.md

# Verify error handling
grep -A 5 "ERROR.*implementation" /home/benjamin/.config/.claude/commands/coordinate.md
grep "DIAGNOSTIC\|What to check" /home/benjamin/.config/.claude/commands/coordinate.md
```

**Expected Duration**: 1 hour

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (verification checkpoint confirmed)
- [ ] Git commit created: `feat(660): complete Phase 4 - Add Verification and Error Handling`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Update Metadata and Documentation
dependencies: [4]

**Objective**: Update command frontmatter and documentation to reflect new architecture

**Complexity**: Low

**Tasks**:
- [ ] Update coordinate.md frontmatter:
  - [ ] Remove `/implement` from dependent-commands (since we use agent directly)
  - [ ] Add `implementer-coordinator` to dependent-agents list
  - [ ] Verify all other agents listed (research-specialist, plan-architect)
- [ ] Update coordinate-command-guide.md to document changes:
  - [ ] Add section explaining implementer-coordinator agent usage
  - [ ] Document wave-based execution capabilities
  - [ ] Document artifact path injection requirements
  - [ ] Note Standard 11 compliance achieved
  - [ ] Add migration notes (change from /implement command to agent)
  - [ ] Update architecture diagram if present
- [ ] Update any inline comments in coordinate.md explaining new pattern
- [ ] Check for any other references to /implement command pattern in guide

**Testing**:
```bash
# Verify frontmatter changes
head -20 /home/benjamin/.config/.claude/commands/coordinate.md | grep "dependent-agents.*implementer-coordinator"
head -20 /home/benjamin/.config/.claude/commands/coordinate.md | grep "dependent-commands" | grep -v "/implement" || echo "ERROR: Still references /implement"

# Verify guide updated
grep -i "implementer-coordinator\|wave-based" /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md
```

**Expected Duration**: 1.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (frontmatter and guide verification)
- [ ] Git commit created: `feat(660): complete Phase 5 - Update Metadata and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Integration Testing and Validation
dependencies: [5]

**Objective**: Validate all changes work correctly through comprehensive integration testing

**Complexity**: High

**Tasks**:
- [ ] Run existing /coordinate tests: `.claude/tests/test_orchestration_commands.sh`
- [ ] Create test plan with parallel phase dependencies for wave-based execution validation
- [ ] Execute /coordinate with test plan (dry-run if possible)
- [ ] Verify implementer-coordinator agent is invoked (not /implement command)
- [ ] Verify wave-based execution occurs for independent phases
- [ ] Verify state transitions work correctly (initialize → research → plan → implement → test)
- [ ] Verify artifact paths are correctly injected and used
- [ ] Verify verification checkpoint catches missing files
- [ ] Measure and document performance:
  - [ ] Context reduction achieved (target: 95%)
  - [ ] Time savings for parallel execution (target: 40-60%)
  - [ ] Agent delegation rate (target: 100%)
- [ ] Test error handling (missing agent file, invalid plan path, etc.)
- [ ] Verify all existing tests still pass
- [ ] Update test suite if needed to cover new agent delegation pattern

**Testing**:
```bash
# Run orchestration command tests
cd /home/benjamin/.config/.claude/tests
./test_orchestration_commands.sh 2>&1 | grep -A 20 "coordinate"

# Check for any test failures
./run_all_tests.sh 2>&1 | grep -i "fail\|error" | head -20

# Manual integration test (if safe)
# /coordinate "test workflow for agent delegation validation" --dry-run
```

**Expected Duration**: 2 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (≥80% coverage maintained, all tests pass)
- [ ] Git commit created: `feat(660): complete Phase 6 - Integration Testing and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Verify path calculations in Phase 0 (grep validation)
- Verify SlashCommand removal and agent delegation pattern (grep validation)
- Verify state machine integration points (grep validation)
- Verify verification checkpoint existence (grep validation)

### Integration Testing
- Run `.claude/tests/test_orchestration_commands.sh` to validate /coordinate behavior
- Execute /coordinate with test plan containing parallel dependencies
- Verify wave-based execution occurs (check for parallel phase execution logs)
- Verify implementer-coordinator agent is invoked (not /implement command)
- Verify all artifacts created at expected paths

### Regression Testing
- Run full test suite: `.claude/tests/run_all_tests.sh`
- Ensure all existing tests pass (≥80% coverage maintained)
- Verify no unintended side effects on other commands

### Performance Testing
- Measure context reduction: Compare agent response size to full /implement output
- Measure time savings: Compare wave-based execution time to sequential baseline
- Verify agent delegation rate: Confirm 100% delegation (no fallback to direct execution)

### Error Handling Testing
- Test missing agent file scenario
- Test invalid plan path scenario
- Test plan with no dependencies (sequential execution)
- Test plan with circular dependencies (should error gracefully)
- Verify diagnostic messages are clear and actionable

## Documentation Requirements

### Command Guide Updates
Update `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md`:
- Add "Implementation Architecture" section explaining implementer-coordinator usage
- Document wave-based parallel execution capabilities and benefits
- Document artifact path injection requirements and rationale
- Add examples showing parallel phase execution
- Note Standard 11 compliance achieved
- Add troubleshooting section for agent delegation issues
- Update migration notes documenting change from /implement command

### Inline Documentation
Update `/home/benjamin/.config/.claude/commands/coordinate.md`:
- Add comments explaining path pre-calculation in Phase 0
- Add comments explaining agent delegation pattern in Phase 3
- Add comments explaining state machine integration
- Add comments explaining verification checkpoint purpose
- Keep comments minimal (WHAT not WHY per executable/documentation separation pattern)

### Architecture Documentation
Potentially update `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`:
- Add /coordinate to list of state-based orchestrators using implementer-coordinator
- Note performance metrics achieved (context reduction, time savings)
- Reference as example of Standard 11 compliance

## Dependencies

### Internal Dependencies
- State machine library: `.claude/lib/workflow-state-machine.sh` (must be sourced)
- State persistence library: `.claude/lib/state-persistence.sh` (for path caching)
- Dependency analyzer: `.claude/lib/dependency-analyzer.sh` (used by implementer-coordinator)
- Metadata extraction: `.claude/lib/metadata-extraction.sh` (for context reduction)
- Error handling: `.claude/lib/error-handling.sh` (for diagnostics)
- Unified logger: `.claude/lib/unified-logger.sh` (for progress tracking)

### Agent Dependencies
- implementer-coordinator agent: `.claude/agents/implementer-coordinator.md` (must exist and be readable)
- implementation-executor agent: `.claude/agents/implementation-executor.md` (invoked by implementer-coordinator)

### External Dependencies
None (all dependencies are internal .claude/ infrastructure)

### Standards Compliance
- Standard 11: Imperative Agent Invocation Pattern (must follow exactly)
- Standard 12: Structural vs Behavioral Content Separation (keep agent behaviors in agent files)
- Standard 14: Executable/Documentation Separation (keep coordinate.md lean, guide comprehensive)
- Behavioral Injection Pattern: Use Task tool with behavioral file reference and context injection
- Verification and Fallback Pattern: Add mandatory verification checkpoint after agent delegation

## Notes

### High-Value Hints for /expand-phase
If complexity score indicates expansion needed during implementation:
- Phase 2 (Replace SlashCommand): Could be expanded if edge cases emerge (multiple invocation patterns, error handling variations)
- Phase 6 (Integration Testing): Could be expanded if testing reveals issues requiring additional validation phases

### Performance Expectations
- **Context Reduction**: Target 95% (5,000+ tokens → <300 tokens via metadata-only response)
- **Time Savings**: Target 40-60% for plans with parallel phases
- **Reliability**: Maintain 100% file creation rate through verification checkpoint
- **Agent Delegation**: Target 100% (implementer-coordinator always invoked successfully)

### Risk Mitigation
- **Risk**: Breaking existing /coordinate workflows that depend on /implement command behavior
  - **Mitigation**: implementer-coordinator provides same functionality as /implement with added parallelization
- **Risk**: Agent delegation fails silently
  - **Mitigation**: Mandatory verification checkpoint catches failures immediately
- **Risk**: State machine integration introduces regressions
  - **Mitigation**: Comprehensive test suite validation before completion

### Related Work
- Spec 495: /coordinate delegation failures (anti-pattern documentation)
- Spec 502: Undermined imperative pattern discovery (Standard 11 enforcement)
- Spec 080: /orchestrate Phase 0 improvements (location detection pattern reference)
- Spec 620/630: Bash block execution model (subprocess isolation patterns)
- Spec 602: State-based orchestration architecture (performance validation)

### Future Enhancements
- Consider extracting common agent delegation pattern into shared library function
- Consider adding telemetry for wave-based execution performance tracking
- Consider dashboard integration for visualizing parallel execution
