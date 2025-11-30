# Build Command Context Streamline Analysis

## Executive Summary

This research analyzes the /build command's current execution patterns to identify opportunities for streamlining substantial work to subagents while preserving primary agent context. Analysis of the build-output.md file reveals that the command consumed 30 tool invocations across multiple phases, with significant context consumption in bash blocks that could be delegated to specialized subagents.

**Key Findings**:
- Current design: 1,972 lines with consolidated Setup/Execute/Cleanup pattern (Block 1: 430 lines, Block 2: 700+ lines, Block 4: 300+ lines)
- Tool invocations: 30 total (7 Read operations, multiple inline bash verification blocks, 2 Task delegations to implementer-coordinator and test-executor)
- Context pressure points: Inline iteration logic (lines 609-843), inline test result parsing (lines 1337-1473), inline verification blocks
- Compliance status: Hard barrier pattern implemented for implementer-coordinator, but testing/debug phases contain substantial inline work

**Recommended Streamline Strategy**:
1. Delegate iteration management to implementer-coordinator (eliminate Block 1b verification, context estimation)
2. Extract test result parsing to test-executor subagent (eliminate inline parsing logic)
3. Consolidate conditional branching into state-driven transitions (eliminate Block 2 inline conditionals)
4. Apply consistent hard barrier pattern across all phases (testing, debug, completion)

**Expected Impact**:
- Primary agent context reduction: 40-50% (from inline logic delegation)
- Command file size reduction: 600-800 lines (consolidation of verification patterns)
- Improved reusability: Iteration logic, test parsing, and debug handling become standalone capabilities
- Standards compliance: Full hard barrier pattern enforcement across all workflow phases

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Context Consumption Patterns](#context-consumption-patterns)
3. [Subagent Delegation Opportunities](#subagent-delegation-opportunities)
4. [Standards Compliance Assessment](#standards-compliance-assessment)
5. [Streamline Recommendations](#streamline-recommendations)
6. [Implementation Strategy](#implementation-strategy)
7. [Risk Assessment](#risk-assessment)

---

## 1. Current State Analysis

### 1.1 File Structure

**File**: `/home/benjamin/.config/.claude/commands/build.md`
- **Total Lines**: 1,972
- **Bash Blocks**: 5 major blocks (Setup, Verification, Testing, Conditional, Completion)
- **Task Invocations**: 3 (implementer-coordinator, spec-updater fallback, test-executor)
- **Block Organization**: Consolidated Setup/Execute/Cleanup pattern

### 1.2 Execution Flow

From build-output.md analysis (30 tool invocations total):

```
Phase 1: Setup and Implementation
├─ Block 1a: Setup (lines 1-430)
│  ├─ Argument capture and validation
│  ├─ Library sourcing (state-persistence, workflow-state-machine, error-handling)
│  ├─ State machine initialization
│  ├─ Checkpoint resumption logic
│  ├─ Auto-resume logic
│  ├─ Legacy plan marker addition
│  ├─ Iteration loop variable initialization
│  └─ Barrier utilities sourcing
│
├─ Block 1b: Implementation Task Invocation
│  └─ Task(implementer-coordinator) - 5m 52s, 92.5k tokens
│
├─ Block 1c: Implementation Verification (lines 486-843) ⚠️ HIGH CONTEXT
│  ├─ Summary verification (existence, count, size)
│  ├─ Iteration check logic
│  ├─ Context estimation function (estimate_context_usage)
│  ├─ Checkpoint save function (save_resumption_checkpoint)
│  ├─ Context threshold check (lines 675-742)
│  ├─ Work remaining parsing
│  ├─ Completion vs continuation decision
│  ├─ Stuck detection logic
│  └─ Iteration limit check
│
└─ Block 1d: Phase Update (lines 850-1046)
   ├─ Completed phase marking (checkbox-utils)
   ├─ Plan hierarchy update
   └─ Fallback spec-updater Task invocation

Phase 2: Testing
├─ Block 2a: Test Setup (lines 1086-1159)
│  ├─ State restoration
│  ├─ Path extraction
│  └─ Test output path calculation
│
├─ Block 2b: Test Execution
│  └─ Task(test-executor) - 1m 43s, 45.7k tokens
│
└─ Block 2c: Test Result Processing (lines 1220-1563) ⚠️ HIGH CONTEXT
   ├─ Inline test artifact parsing (lines 1337-1430)
   ├─ Test result extraction (exit code, framework, command, failures)
   ├─ Inline conditional branching (lines 1474-1539)
   ├─ State transitions (DEBUG vs DOCUMENT)
   ├─ Inline debug directory setup
   └─ Inline documentation phase handling

Phase 3: Completion
└─ Block 4: Workflow Completion (lines 1596-1946)
   ├─ State restoration
   ├─ Predecessor state validation (lines 1753-1800)
   ├─ State transition to COMPLETE
   ├─ Summary plan link validation
   ├─ Console summary generation (lines 1864-1909)
   ├─ Plan status update to COMPLETE
   └─ Cleanup operations
```

### 1.3 Observed Execution Pattern (from build-output.md)

**Tool Invocation Breakdown**:
- **Bash**: 7 blocks (setup, verification, phase update, test parsing, state validation, completion)
- **Task**: 2 primary (implementer-coordinator, test-executor)
- **Read**: 7 operations (plan file, agent files, test results, verification)
- **Search/Grep**: 2 operations (CLAUDE_PROJECT_DIR pattern search)
- **Update/Edit**: 3 operations (plan.md fixes for CLAUDE_PROJECT_DIR initialization)

**Critical Observation**: The primary agent performed substantial inline work:
1. **Plan file debugging** (lines 73-262 of build-output.md): Read plan.md multiple times to identify and fix CLAUDE_PROJECT_DIR initialization order bug
2. **Inline verification**: Manual test failure analysis and code inspection
3. **Inline fixes**: Edit operations to correct bash block ordering
4. **Re-test execution**: Manual test re-run after fixes

This demonstrates the current pattern allows primary agent to bypass subagent delegation when encountering issues.

---

## 2. Context Consumption Patterns

### 2.1 High-Context Bash Blocks

**Block 1c: Implementation Verification (lines 486-843)** - 357 lines
- **Functions Defined Inline**:
  - `estimate_context_usage()` - 18 lines (lines 615-630)
  - `save_resumption_checkpoint()` - 41 lines (lines 634-673)
- **Complex Logic**:
  - Context threshold calculation and comparison (68 lines, lines 675-742)
  - Work remaining parsing with multiple fallbacks (27 lines, lines 744-770)
  - Stuck detection with 2-iteration tracking (22 lines, lines 779-800)
  - Iteration limit enforcement (15 lines, lines 803-816)
  - Next iteration preparation (22 lines, lines 817-837)

**Context Cost**: ~8,000-10,000 tokens for iteration management logic alone

**Block 2c: Test Result Processing (lines 1220-1563)** - 343 lines
- **Inline Parsing Logic**:
  - Test artifact metadata extraction (53 lines, lines 1391-1443)
  - Fallback test execution (38 lines, lines 1350-1388)
  - Test result determination (15 lines, lines 1412-1426)
- **Conditional Branching**:
  - Debug phase setup (43 lines, lines 1474-1516)
  - Documentation phase setup (23 lines, lines 1514-1539)

**Context Cost**: ~7,000-9,000 tokens for test parsing and conditional logic

**Block 4: Completion (lines 1596-1946)** - 350 lines
- **Validation Logic**:
  - Predecessor state validation with case statement (48 lines, lines 1753-1800)
  - Summary plan link validation (20 lines, lines 1846-1862)
- **Console Summary Generation**:
  - Variable substitution and formatting (46 lines, lines 1864-1909)

**Context Cost**: ~6,000-8,000 tokens for validation and summary generation

**Total Inline Logic Context**: ~21,000-27,000 tokens (10-13% of context window)

### 2.2 Subagent Interaction Patterns

**Implementer-Coordinator** (Block 1b):
- **Invocation Context**: Iteration parameters, continuation context path, starting phase
- **Return Format**: IMPLEMENTATION_COMPLETE signal with phase_count, summary_path, work_remaining, context_exhausted
- **Context Efficiency**: Good - metadata-only return per hierarchical agents pattern
- **Issue**: Primary agent re-parses work_remaining and context_exhausted inline instead of trusting subagent assessment

**Test-Executor** (Block 2b):
- **Invocation Context**: Plan path, topic path, artifact paths, test config
- **Return Format**: TEST_COMPLETE signal with status, framework, test_command, tests_run, tests_passed, tests_failed, test_output_path
- **Context Efficiency**: Good - metadata-only return
- **Issue**: Primary agent performs inline fallback test execution (lines 1350-1388) and inline artifact parsing (lines 1391-1443) instead of delegating to test-executor retry

**Debug-Analyst** (Block 2c, conditional):
- **Invocation Context**: Issue description, test exit code, test command, debug directory
- **Return Format**: DEBUG_COMPLETE signal with report_path
- **Context Efficiency**: Good - metadata-only return
- **Issue**: Primary agent performs inline debug directory setup and state transitions instead of delegating to debug-analyst setup

### 2.3 Context Leakage Points

1. **Iteration Management** (Block 1c, lines 609-843):
   - Primary agent calculates context usage, saves checkpoints, determines continuation
   - **Should be**: Implementer-coordinator returns context_usage, checkpoint_path, requires_continuation
   - **Impact**: 8,000-10,000 tokens of inline logic

2. **Test Result Parsing** (Block 2c, lines 1391-1443):
   - Primary agent extracts metadata from test artifact file
   - **Should be**: Test-executor returns all metadata in structured format
   - **Impact**: 7,000-9,000 tokens of inline parsing

3. **Conditional Branching** (Block 2c, lines 1474-1539):
   - Primary agent determines debug vs document phase based on test results
   - **Should be**: State machine transitions driven by test-executor return status
   - **Impact**: 3,000-4,000 tokens of inline conditionals

4. **Validation Logic** (Block 4, lines 1753-1800):
   - Primary agent validates predecessor states with complex case statement
   - **Should be**: State machine enforces valid transitions automatically
   - **Impact**: 2,000-3,000 tokens of inline validation

**Total Context Leakage**: ~20,000-26,000 tokens (10-13% of context window)

---

## 3. Subagent Delegation Opportunities

### 3.1 Iteration Management Delegation

**Current Pattern** (Block 1c, lines 609-843):
```bash
# Primary agent performs:
- Context estimation (estimate_context_usage function)
- Checkpoint saving (save_resumption_checkpoint function)
- Context threshold checking
- Work remaining parsing
- Stuck detection
- Iteration limit enforcement
- Next iteration preparation
```

**Proposed Pattern**:
```markdown
## Block 1b: Implementation Execution

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with iteration management"
  prompt: |
    Read and follow: .claude/agents/implementer-coordinator.md

    Input:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - iteration: $ITERATION
    - max_iterations: $MAX_ITERATIONS
    - context_threshold: $CONTEXT_THRESHOLD
    - continuation_context: $CONTINUATION_CONTEXT

    Execute implementation phases with built-in iteration management.

    Return:
    IMPLEMENTATION_COMPLETE:
      phase_count: N
      summary_path: /path/to/summary
      work_remaining: 0|[list]
      context_exhausted: true|false
      context_usage_percent: N%
      checkpoint_path: /path/to/checkpoint (if created)
      requires_continuation: true|false
}

## Block 1c: Implementation Verification (SIMPLIFIED)

**EXECUTE NOW**: Verify implementer-coordinator created summary and check continuation status:

```bash
# Restore state
load_workflow_state "$WORKFLOW_ID" false

# Simple verification - no complex logic
if [ ! -f "$LATEST_SUMMARY" ]; then
  log_command_error "verification_error" \
    "Summary missing: $LATEST_SUMMARY" \
    "implementer-coordinator should have created summary"
  exit 1
fi

# Trust subagent assessment - no re-parsing
if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  append_workflow_state "IMPLEMENTATION_STATUS" "continuing"
else
  append_workflow_state "IMPLEMENTATION_STATUS" "complete"
fi

echo "[CHECKPOINT] Implementation verification complete"
```
```

**Benefits**:
- **Context Reduction**: 8,000-10,000 tokens eliminated from primary agent
- **Reusability**: Iteration logic becomes standalone capability usable by other commands
- **Maintainability**: Single source of truth for iteration management in implementer-coordinator.md
- **Simplification**: Block 1c reduces from 357 lines to ~50 lines

### 3.2 Test Result Delegation

**Current Pattern** (Block 2c, lines 1337-1443):
```bash
# Primary agent performs:
- Test artifact loading
- Metadata extraction (exit code, framework, command, failures)
- Test result determination
- Fallback test execution
```

**Proposed Pattern**:
```markdown
## Block 2b: Test Execution

Task {
  subagent_type: "general-purpose"
  description: "Execute tests with comprehensive result reporting"
  prompt: |
    Read and follow: .claude/agents/test-executor.md

    Input:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - test_config: {retry_on_failure: true, max_retries: 2}

    Execute tests and return COMPLETE structured results.

    Return:
    TEST_COMPLETE:
      status: passed|failed|error
      framework: <detected>
      test_command: <executed>
      tests_run: N
      tests_passed: N
      tests_failed: N
      exit_code: N
      execution_time: <duration>
      artifact_path: /path/to/results.md
      next_state: DOCUMENT|DEBUG (recommendation)
}

## Block 2c: Test Verification (SIMPLIFIED)

**EXECUTE NOW**: Verify test-executor created artifact and transition to recommended state:

```bash
# Restore state
load_workflow_state "$WORKFLOW_ID" false

# Simple verification - trust subagent
if [ ! -f "$TEST_ARTIFACT_PATH" ]; then
  log_command_error "verification_error" \
    "Test artifact missing: $TEST_ARTIFACT_PATH" \
    "test-executor should have created artifact"
  exit 1
fi

# State transition based on subagent recommendation
sm_transition "$NEXT_STATE"

echo "[CHECKPOINT] Test verification complete - transitioning to $NEXT_STATE"
```
```

**Benefits**:
- **Context Reduction**: 7,000-9,000 tokens eliminated from primary agent
- **Error Handling**: Test-executor handles retries internally
- **Decision Delegation**: Subagent recommends next state based on test results
- **Simplification**: Block 2c reduces from 343 lines to ~40 lines

### 3.3 Conditional Branching Delegation

**Current Pattern** (Block 2c, lines 1474-1539):
```bash
# Primary agent performs:
if [ "$TESTS_PASSED" = "false" ]; then
  sm_transition "$STATE_DEBUG"
  # Inline debug setup (43 lines)
else
  sm_transition "$STATE_DOCUMENT"
  # Inline documentation setup (23 lines)
fi
```

**Proposed Pattern**:
```markdown
## Block 2c: Test Verification (CONSOLIDATED)

**EXECUTE NOW**: Transition to state recommended by test-executor:

```bash
# Restore state
load_workflow_state "$WORKFLOW_ID" false

# Single state transition - no conditionals
sm_transition "$NEXT_STATE" || {
  log_command_error "state_error" \
    "Failed to transition to $NEXT_STATE" \
    "test-executor recommended this transition"
  exit 1
}

# Persist for next phase
append_workflow_state "CURRENT_PHASE" "$NEXT_STATE"

echo "[CHECKPOINT] Transitioned to $NEXT_STATE phase"
```

**Conditional Invocations** (only if needed):

<!-- If NEXT_STATE = DEBUG -->
Task {
  subagent_type: "general-purpose"
  description: "Debug failed tests"
  prompt: "Read and follow: .claude/agents/debug-analyst.md..."
}

<!-- If NEXT_STATE = DOCUMENT -->
Task {
  subagent_type: "general-purpose"
  description: "Update documentation"
  prompt: "Read and follow: .claude/agents/doc-updater.md..."
}
```

**Benefits**:
- **Context Reduction**: 3,000-4,000 tokens eliminated from primary agent
- **State-Driven Logic**: State machine enforces valid transitions
- **Simplification**: Eliminates inline conditional blocks
- **Clarity**: Conditional subagent invocations separated from core workflow

### 3.4 Validation Delegation

**Current Pattern** (Block 4, lines 1753-1800):
```bash
# Primary agent performs:
case "$CURRENT_STATE" in
  document|debug) ;;  # Valid
  test) exit 1 ;;     # Invalid
  implement) exit 1 ;; # Invalid
  *) exit 1 ;;        # Invalid
esac
```

**Proposed Pattern**:
```bash
# State machine enforces valid transitions automatically
sm_transition "$STATE_COMPLETE" || {
  log_command_error "state_error" \
    "Invalid transition to COMPLETE from $CURRENT_STATE" \
    "State machine rejected transition"
  exit 1
}
```

**Benefits**:
- **Context Reduction**: 2,000-3,000 tokens eliminated from primary agent
- **Single Source of Truth**: State machine library enforces transitions
- **Maintainability**: Transition rules centralized in workflow-state-machine.sh
- **Simplification**: Eliminates 48-line case statement

---

## 4. Standards Compliance Assessment

### 4.1 Hard Barrier Pattern Compliance

**Current Status**:

✅ **Implemented**:
- Block 1b: implementer-coordinator delegation (hard barrier present)
- Block 2b: test-executor delegation (hard barrier present)

⚠️ **Partial**:
- Block 1d: spec-updater fallback (conditional delegation)
- Block 2c: debug-analyst delegation (conditional, only on test failure)

❌ **Missing**:
- Block 1c: Iteration management (inline logic, no hard barrier)
- Block 2c: Test result parsing (inline logic, no hard barrier)
- Block 2c: Conditional branching (inline logic, no hard barrier)
- Block 4: Validation logic (inline logic, no hard barrier)

**Standards Reference**: [Hard Barrier Subagent Delegation Pattern](.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)

**Requirements**:
1. **CRITICAL BARRIER Label**: Present for implementer-coordinator and test-executor
2. **Fail-Fast Verification**: Present for implementer-coordinator and test-executor
3. **State Transitions as Gates**: Present in Block 1a (IMPLEMENT), Block 2c (TEST, DEBUG, DOCUMENT), Block 4 (COMPLETE)
4. **Variable Persistence**: Present via append_workflow_state calls
5. **Checkpoint Reporting**: Present via echo "[CHECKPOINT]" statements
6. **Error Logging Integration**: Present via log_command_error calls

**Gaps**:
- Iteration management, test parsing, and conditional branching are NOT delegated to subagents
- No hard barriers enforcing delegation for these operations
- Inline logic prevents reusability across workflows

### 4.2 Output Formatting Standards Compliance

**Current Status**:

✅ **Compliant**:
- Library sourcing uses fail-fast pattern: `source lib.sh 2>/dev/null || { echo "ERROR"; exit 1; }`
- Error logging integrated: `log_command_error` calls present
- Single summary lines per block: "[CHECKPOINT]" pattern used
- Console summary uses 4-section format (Block 4, lines 1864-1909)

⚠️ **Partial**:
- Block consolidation: 5 major blocks (target: 2-3)
- Comment standards: Mix of WHAT and WHY comments

❌ **Missing**:
- Output suppression could be improved (some verbose echo statements remain)
- Function definitions inline (estimate_context_usage, save_resumption_checkpoint) instead of in libraries

**Standards Reference**: [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md)

**Gaps**:
- Functions defined inline contribute to context consumption
- Additional block consolidation possible by delegating iteration/test parsing to subagents

### 4.3 Hierarchical Agent Architecture Compliance

**Current Status**:

✅ **Compliant**:
- Behavioral injection pattern used for implementer-coordinator and test-executor
- Metadata-only context passing from subagents
- Pre-calculated paths passed to subagents

⚠️ **Partial**:
- Context efficiency: Primary agent performs substantial inline work (iteration, parsing)
- Hard barrier pattern: Only applied to 2 of 4 delegation opportunities

❌ **Missing**:
- Coordination patterns: Iteration management and test result parsing NOT delegated
- Metadata extraction: Primary agent re-parses subagent outputs instead of trusting structured returns

**Standards Reference**: [Hierarchical Agent Architecture Overview](.claude/docs/concepts/hierarchical-agents-overview.md)

**Gaps**:
- Primary agent acts as both orchestrator AND executor (violates role separation)
- Inline logic prevents context efficiency gains from hierarchical architecture

### 4.4 State-Based Orchestration Compliance

**Current Status**:

✅ **Compliant**:
- State machine transitions present (IMPLEMENT → TEST → DEBUG/DOCUMENT → COMPLETE)
- State persistence via append_workflow_state
- State restoration via load_workflow_state

⚠️ **Partial**:
- Idempotent transitions: Present but not fully leveraged
- State-driven logic: Conditionals inline instead of state-driven subagent invocations

❌ **Missing**:
- State machine does NOT enforce iteration management
- State machine does NOT recommend next phase based on test results

**Standards Reference**: [State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md)

**Gaps**:
- State machine could enforce iteration limits and context thresholds
- State machine could recommend debug vs document phase based on test status

---

## 5. Streamline Recommendations

### 5.1 Priority 1: Iteration Management Delegation (High Impact)

**Rationale**: Largest context reduction opportunity (8,000-10,000 tokens)

**Changes Required**:

1. **Enhance implementer-coordinator.md** (lines 501-582):
   - Add built-in iteration management to agent
   - Accept max_iterations and context_threshold parameters
   - Return context_usage_percent, checkpoint_path, requires_continuation
   - Internal logic for stuck detection, iteration limits, checkpoint saving

2. **Simplify build.md Block 1c** (lines 486-843):
   - Remove estimate_context_usage function definition (move to implementer-coordinator)
   - Remove save_resumption_checkpoint function definition (move to implementer-coordinator)
   - Remove context threshold check (trust implementer-coordinator)
   - Remove work remaining parsing (trust implementer-coordinator)
   - Remove stuck detection (trust implementer-coordinator)
   - Reduce to simple verification: summary exists, requires_continuation status

3. **Update build.md Block 1b Task invocation** (lines 432-482):
   - Add max_iterations parameter
   - Add context_threshold parameter
   - Expect requires_continuation in return

**File Changes**:
- `.claude/agents/implementer-coordinator.md`: +150 lines (iteration logic)
- `.claude/commands/build.md`: -300 lines (removed inline logic)
- **Net Impact**: -150 lines, 8,000-10,000 tokens saved in primary agent

**Compliance Gains**:
- Hard barrier pattern: Full compliance for iteration management
- Output formatting: Function definitions moved to agent
- Hierarchical agents: Proper role separation (orchestrator vs executor)

### 5.2 Priority 2: Test Result Delegation (High Impact)

**Rationale**: Second largest context reduction opportunity (7,000-9,000 tokens)

**Changes Required**:

1. **Enhance test-executor.md**:
   - Add retry_on_failure logic internally
   - Add next_state recommendation based on test results
   - Return comprehensive metadata (no inline parsing needed)
   - Internal fallback test execution (eliminate Block 2c inline fallback)

2. **Simplify build.md Block 2c** (lines 1220-1563):
   - Remove inline test artifact parsing (lines 1391-1443)
   - Remove fallback test execution (lines 1350-1388)
   - Remove inline conditional branching (lines 1474-1539)
   - Reduce to simple verification: artifact exists, trust next_state

3. **Update build.md Block 2b Task invocation** (lines 1162-1215):
   - Add test_config parameter with retry_on_failure
   - Expect next_state in return

**File Changes**:
- `.claude/agents/test-executor.md`: +100 lines (retry and recommendation logic)
- `.claude/commands/build.md`: -300 lines (removed inline logic)
- **Net Impact**: -200 lines, 7,000-9,000 tokens saved in primary agent

**Compliance Gains**:
- Hard barrier pattern: Full compliance for test result processing
- Output formatting: Inline parsing eliminated
- Hierarchical agents: Test executor fully autonomous

### 5.3 Priority 3: Conditional Branching Consolidation (Medium Impact)

**Rationale**: Simplifies workflow, improves maintainability (3,000-4,000 tokens)

**Changes Required**:

1. **Leverage test-executor next_state recommendation**:
   - Replace inline conditionals with state transition to recommended state
   - Remove debug setup inline logic
   - Remove documentation setup inline logic

2. **Add conditional subagent invocations**:
   - If state = DEBUG, invoke debug-analyst
   - If state = DOCUMENT, invoke doc-updater (optional)

**File Changes**:
- `.claude/commands/build.md`: -70 lines (removed inline conditionals)
- **Net Impact**: -70 lines, 3,000-4,000 tokens saved in primary agent

**Compliance Gains**:
- State-based orchestration: Full state-driven logic
- Hard barrier pattern: Conditional invocations delegated

### 5.4 Priority 4: Validation Delegation (Low Impact)

**Rationale**: Smallest context reduction (2,000-3,000 tokens), but improves maintainability

**Changes Required**:

1. **Enhance workflow-state-machine.sh**:
   - Add transition validation enforcement in sm_transition function
   - Return descriptive error on invalid transition

2. **Simplify build.md Block 4** (lines 1596-1946):
   - Remove predecessor state validation case statement (lines 1753-1800)
   - Trust state machine to reject invalid transitions

**File Changes**:
- `.claude/lib/workflow/workflow-state-machine.sh`: +30 lines (validation logic)
- `.claude/commands/build.md`: -50 lines (removed case statement)
- **Net Impact**: -20 lines, 2,000-3,000 tokens saved in primary agent

**Compliance Gains**:
- State-based orchestration: Transition validation in state machine
- Single source of truth: Validation rules in library

### 5.5 Summary of Recommendations

| Priority | Delegation Opportunity | Context Saved | File Impact | Compliance Gain |
|----------|------------------------|---------------|-------------|-----------------|
| 1 | Iteration Management | 8,000-10,000 | -150 lines | Hard barrier, role separation |
| 2 | Test Result Processing | 7,000-9,000 | -200 lines | Hard barrier, autonomous executor |
| 3 | Conditional Branching | 3,000-4,000 | -70 lines | State-driven logic |
| 4 | Validation Logic | 2,000-3,000 | -20 lines | Single source of truth |
| **Total** | **All Opportunities** | **20,000-26,000** | **-440 lines** | **Full standards compliance** |

**Expected Primary Agent Context After Streamline**:
- Current: ~30,000 tokens (15% of context window)
- After streamline: ~10,000 tokens (5% of context window)
- **Reduction**: 66% context consumption reduction

---

## 6. Implementation Strategy

### 6.1 Phased Rollout

**Phase 1: Iteration Management Delegation** (Week 1)
1. Create spec: `974_build_iteration_delegation`
2. Research: Analyze implementer-coordinator.md for iteration logic placement
3. Plan: Design iteration management interface (parameters, return format)
4. Implement: Enhance implementer-coordinator.md, simplify build.md Block 1c
5. Test: Verify iteration management with multi-iteration plan
6. Commit: "feat(build): Delegate iteration management to implementer-coordinator"

**Phase 2: Test Result Delegation** (Week 2)
1. Create spec: `975_build_test_delegation`
2. Research: Analyze test-executor.md for retry and recommendation logic
3. Plan: Design test result interface (retry config, next_state recommendation)
4. Implement: Enhance test-executor.md, simplify build.md Block 2c
5. Test: Verify test failure handling and retry logic
6. Commit: "feat(build): Delegate test result processing to test-executor"

**Phase 3: Conditional Branching Consolidation** (Week 3)
1. Create spec: `976_build_conditional_consolidation`
2. Research: Analyze state machine for conditional invocation patterns
3. Plan: Design state-driven subagent invocation logic
4. Implement: Simplify build.md Block 2c conditionals, add state-driven invocations
5. Test: Verify debug and documentation phase transitions
6. Commit: "refactor(build): Consolidate conditional branching into state-driven logic"

**Phase 4: Validation Delegation** (Week 4)
1. Create spec: `977_build_validation_delegation`
2. Research: Analyze workflow-state-machine.sh for transition validation
3. Plan: Design transition validation enforcement
4. Implement: Enhance workflow-state-machine.sh, simplify build.md Block 4
5. Test: Verify invalid transition rejection
6. Commit: "refactor(build): Delegate validation to state machine"

### 6.2 Testing Strategy

**Unit Tests**:
- Test implementer-coordinator iteration management in isolation
- Test test-executor retry and recommendation logic in isolation
- Test state machine transition validation in isolation

**Integration Tests**:
- Test /build with multi-iteration plan (iteration delegation)
- Test /build with test failures (test result delegation)
- Test /build with debug phase (conditional branching)
- Test /build with invalid state transitions (validation delegation)

**Regression Tests**:
- Verify /build still completes successfully for existing plans
- Verify checkpoint resumption still works
- Verify git commit creation still works
- Verify summary generation still works

**Performance Tests**:
- Measure primary agent context consumption before/after
- Measure command execution time before/after
- Measure subagent context consumption before/after

### 6.3 Rollback Plan

**Trigger Conditions**:
- Primary agent context consumption increases (regression)
- Command execution time increases by >20%
- Test failure rate increases
- User-reported issues with /build workflow

**Rollback Steps**:
1. Identify problematic phase (iteration, test, conditional, validation)
2. Revert commit for that phase
3. Re-test /build with revert
4. Document issue for future resolution
5. Create follow-up spec to address root cause

---

## 7. Risk Assessment

### 7.1 Technical Risks

**Risk 1: Increased Subagent Context Consumption**
- **Probability**: Medium
- **Impact**: Medium
- **Mitigation**: Careful design of subagent interfaces to minimize context overhead
- **Acceptance**: Monitor subagent context consumption, ensure <30% of their context window

**Risk 2: Subagent Reliability Issues**
- **Probability**: Low
- **Impact**: High
- **Mitigation**: Comprehensive testing of subagent logic, fail-fast error handling
- **Acceptance**: Maintain >95% subagent success rate in integration tests

**Risk 3: State Machine Complexity**
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**: Limit state machine enhancements to transition validation only
- **Acceptance**: State machine remains <500 lines, well-documented

**Risk 4: Iteration Management Bugs**
- **Probability**: Medium
- **Impact**: High
- **Mitigation**: Extensive testing of multi-iteration scenarios, checkpoint resumption
- **Acceptance**: Zero data loss in checkpoint resumption, accurate iteration tracking

### 7.2 Workflow Risks

**Risk 1: Breaking Changes to /build UX**
- **Probability**: Low
- **Impact**: High
- **Mitigation**: Maintain backward compatibility for plan file format and checkpoint format
- **Acceptance**: Existing users see no change in /build behavior

**Risk 2: Migration Complexity**
- **Probability**: Medium
- **Impact**: Medium
- **Mitigation**: Phased rollout, comprehensive testing at each phase
- **Acceptance**: Each phase can be rolled back independently

**Risk 3: Documentation Burden**
- **Probability**: Low
- **Impact**: Low
- **Mitigation**: Update .claude/docs/ as part of each phase implementation
- **Acceptance**: All changes documented in guides/commands/build-command-guide.md

### 7.3 Compliance Risks

**Risk 1: Standards Violations**
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**: Run linters and validators after each phase
- **Acceptance**: Zero linter errors, 100% hard barrier compliance

**Risk 2: Regression in Code Quality**
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**: Code review for each phase, test coverage >90%
- **Acceptance**: Maintain or improve code quality metrics

### 7.4 Risk Summary

| Risk Category | Overall Probability | Overall Impact | Mitigation Effectiveness | Residual Risk |
|---------------|---------------------|----------------|--------------------------|---------------|
| Technical | Medium | Medium-High | High | Low |
| Workflow | Low-Medium | Medium-High | High | Low |
| Compliance | Low | Medium | High | Very Low |

**Overall Risk Level**: LOW-MEDIUM (acceptable for implementation)

---

## 8. Conclusion

### 8.1 Research Summary

This research identified **four major delegation opportunities** in the /build command:

1. **Iteration Management** (357 lines, 8,000-10,000 tokens): Delegate to implementer-coordinator
2. **Test Result Processing** (343 lines, 7,000-9,000 tokens): Delegate to test-executor
3. **Conditional Branching** (66 lines, 3,000-4,000 tokens): State-driven logic
4. **Validation Logic** (48 lines, 2,000-3,000 tokens): Delegate to state machine

**Total Impact**: 440 lines removed, 20,000-26,000 tokens saved (66% context reduction)

### 8.2 Standards Compliance Gaps

- **Hard Barrier Pattern**: Only 2 of 6 delegation opportunities enforce hard barriers
- **Output Formatting**: Function definitions inline instead of in libraries
- **Hierarchical Agents**: Primary agent acts as executor instead of pure orchestrator
- **State-Based Orchestration**: Conditionals inline instead of state-driven

### 8.3 Recommended Next Steps

1. **Create Plan**: Use /plan to generate implementation plan for iteration delegation (Priority 1)
2. **Implement Phases**: Execute 4-phase rollout over 4 weeks
3. **Validate Compliance**: Run linters and validators after each phase
4. **Measure Impact**: Track context consumption, execution time, test success rate
5. **Document Changes**: Update build-command-guide.md with new architecture

### 8.4 Expected Outcomes

**Primary Agent Context**:
- Before: 30,000 tokens (15% of window)
- After: 10,000 tokens (5% of window)
- Improvement: 66% reduction

**Command File Size**:
- Before: 1,972 lines
- After: 1,532 lines
- Improvement: 22% reduction

**Standards Compliance**:
- Before: Partial (2/6 hard barriers)
- After: Full (6/6 hard barriers)
- Improvement: 100% compliance

**Reusability**:
- Before: Iteration/test logic locked in /build
- After: Iteration/test logic reusable across workflows
- Improvement: 4 new standalone capabilities

---

## Appendix A: Build-Output.md Analysis

**Total Tool Invocations**: 30

**Breakdown**:
1. Bash (setup): Line 5 - Setup preprocessing safety, capture arguments, source libraries
2. Read (plan): Line 17 - Read plan file
3. Read (agent): Line 21 - Read implementer-coordinator agent
4. Task (implementer): Line 27 - Invoke implementer-coordinator (5m 52s, 92.5k tokens)
5. Bash (verify impl): Line 33 - Verify implementation completion
6. Bash (phase update): Line 40 - Mark completed phases
7. Bash (test setup): Line 49 - Prepare test environment
8. Task (test): Line 60 - Invoke test-executor (1m 43s, 45.7k tokens)
9. Bash (test results): Line 66 - Load and parse test results
10. Read (test results): Line 76 - Read test output artifact
11. Search (CLAUDE_PROJECT_DIR): Line 80 - Search for pattern in plan.md
12. Search (bash blocks): Line 87 - Search for bash block markers
13. Read (plan validation): Line 90 - Read plan.md to validate
14-17. Read (plan multiple): Lines 93-100 - Read plan.md sections multiple times
18. Update (fix): Line 124 - Fix CLAUDE_PROJECT_DIR initialization order
19. Update (syntax fix): Line 159 - Fix ; then to ; do syntax
20. Update (cleanup): Line 180 - Remove redundant initialization
21. Update (consolidate): Line 218 - Consolidate environment restore
22. Bash (test fix): Line 251 - Re-run test after fix
23. Bash (git commit): Line 264 - Commit the fix
24. Bash (re-test): Line 272 - Re-run tests after fix
25. Bash (transition): Line 281 - Attempt transition to document phase (failed)
26. Bash (retry transition): Line 288 - Retry transition with state restoration

**Key Observations**:
- **High Read count** (7 operations): Primary agent inspecting plan.md multiple times for debugging
- **Inline fixes** (4 Update operations): Primary agent fixing plan.md directly instead of delegating to plan-architect
- **Re-test pattern**: Manual test execution after fixes instead of delegating to test-executor retry
- **State machine errors**: Invalid transition attempts indicate complex state management

**Context Consumption Pattern**:
- Setup phase: ~5,000 tokens (library sourcing, argument parsing)
- Implementation phase: 92,500 tokens (implementer-coordinator)
- Verification phase: ~10,000 tokens (inline iteration logic, debugging)
- Test phase: 45,700 tokens (test-executor)
- Test parsing phase: ~8,000 tokens (inline parsing, debugging)
- Completion phase: ~5,000 tokens (validation, summary)
- **Total Primary Agent**: ~28,000 tokens (excluding subagents)
- **Total Subagents**: 138,200 tokens

**Efficiency Ratio**: 16.8% overhead (primary agent context / total context)
**Target Ratio**: 5% overhead (with full delegation)
**Improvement Potential**: 70% reduction in primary agent overhead

---

## Appendix B: Standards Cross-Reference

### Hard Barrier Pattern Requirements

From `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`:

**Required Elements**:
1. Setup Block (Na): State transition, variable persistence, checkpoint reporting
2. Execute Block (Nb): CRITICAL BARRIER label, Task invocation ONLY
3. Verify Block (Nc): Artifact checks, fail-fast, error logging, recovery instructions

**Current Compliance**:
- ✅ Block 1a/1b/1c: Setup/Execute/Verify (implementer-coordinator)
- ✅ Block 2a/2b/2c: Setup/Execute/Verify (test-executor)
- ❌ Iteration management: Inline logic in Block 1c (should be in implementer-coordinator)
- ❌ Test parsing: Inline logic in Block 2c (should be in test-executor)
- ❌ Conditional branching: Inline logic in Block 2c (should be state-driven)
- ❌ Validation: Inline logic in Block 4 (should be in state machine)

### Output Formatting Standards Requirements

From `.claude/docs/reference/standards/output-formatting.md`:

**Required Patterns**:
1. Library sourcing: Fail-fast with `|| { exit 1 }` (✅ Compliant)
2. Directory operations: Suppress with `2>/dev/null || true` (✅ Compliant)
3. Single summary line: One echo per block (✅ Compliant)
4. Block consolidation: 2-3 blocks target (⚠️ Partial - 5 blocks currently)
5. Function definitions: In libraries, not inline (❌ Non-compliant - 2 functions inline)

### Hierarchical Agent Architecture Requirements

From `.claude/docs/concepts/hierarchical-agents-overview.md`:

**Required Patterns**:
1. Behavioral injection: Reference agent files, don't duplicate (✅ Compliant)
2. Metadata-only passing: Summaries, not full content (✅ Compliant for subagents)
3. Single source of truth: Behavioral guidelines in .md files (✅ Compliant)
4. Context efficiency: 95% reduction at scale (⚠️ Partial - 70% reduction currently)
5. Role separation: Orchestrator vs executor (❌ Non-compliant - primary agent executes)

---

## Appendix C: File Size Comparison

**Current Build Command** (`/home/benjamin/.config/.claude/commands/build.md`):
- Total Lines: 1,972
- Bash Blocks: 5 major blocks
- Inline Functions: 2 (estimate_context_usage, save_resumption_checkpoint)
- Inline Logic: ~814 lines (Block 1c: 357, Block 2c: 343, Block 4: 114)

**Target After Streamline**:
- Total Lines: 1,532 (-440 lines, -22%)
- Bash Blocks: 4 major blocks (consolidated)
- Inline Functions: 0 (moved to agents/libraries)
- Inline Logic: ~250 lines (verification only)

**Enhanced Implementer-Coordinator** (`.claude/agents/implementer-coordinator.md`):
- Current Lines: 660
- After Enhancement: 810 (+150 lines for iteration management)

**Enhanced Test-Executor** (`.claude/agents/test-executor.md`):
- Current Lines: ~400 (estimated)
- After Enhancement: 500 (+100 lines for retry and recommendation logic)

**Enhanced Workflow State Machine** (`.claude/lib/workflow/workflow-state-machine.sh`):
- Current Lines: ~300 (estimated)
- After Enhancement: 330 (+30 lines for transition validation)

**Net Impact Across All Files**:
- Build command: -440 lines
- Implementer-coordinator: +150 lines
- Test-executor: +100 lines
- State machine: +30 lines
- **Total**: -160 lines across codebase (8% reduction)
- **Context Savings**: 20,000-26,000 tokens in primary agent

---

**Report Metadata**:
- **Created**: 2025-11-29
- **Research Complexity**: 3
- **Standards Reviewed**: 4 (Hard Barrier, Output Formatting, Hierarchical Agents, State-Based Orchestration)
- **Files Analyzed**: 5 (build.md, build-output.md, implementer-coordinator.md, test-executor.md, standards docs)
- **Delegation Opportunities Identified**: 4
- **Expected Context Reduction**: 66%
- **Expected File Size Reduction**: 22%
