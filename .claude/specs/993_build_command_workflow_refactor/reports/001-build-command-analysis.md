# Build Command Workflow Refactor - Comprehensive Analysis

## Metadata
- **Date**: 2025-12-01
- **Agent**: research-specialist
- **Topic**: Build command refactor into implement-only and test/debug workflows
- **Report Type**: codebase analysis
- **Complexity**: 3
- **Reference Commands**: /build, /plan, /research
- **Documentation Sources**: command-authoring.md, hard-barrier-subagent-delegation.md

## Executive Summary

The /build command (1913 lines) currently implements a monolithic full-implementation workflow combining implementation, testing, and debugging phases. Analysis reveals a clear separation boundary: implementation phases (initialize → implement) are structurally distinct from test/debug phases (test → debug → document). Refactoring into two commands (/implement and /test) requires: (1) splitting at the test state boundary, (2) implementing hard barrier pattern for both commands, (3) migrating state machine transitions, and (4) separating agent delegation (implementer-coordinator vs test-executor/debug-analyst). The /plan command provides the architectural reference for standards-compliant command structure.

## Current /build Command Structure

### File Location and Scope
- **Path**: `/home/benjamin/.config/.claude/commands/build.md`
- **Size**: 1913 lines
- **Workflow Type**: full-implementation
- **Terminal State**: complete
- **Dependent Agents**: implementer-coordinator, debug-analyst
- **Library Dependencies**: workflow-state-machine.sh >=2.0.0, state-persistence.sh >=1.5.0

### Phase Architecture (Lines 24-1912)

The command implements 7 bash blocks organized into phases:

#### Block 1a: Implementation Phase Setup (Lines 24-496)
**Purpose**: Argument capture, state machine initialization, path allocation
**Key Operations**:
- 2-block argument capture pattern (lines 34-56): `YOUR_BUILD_ARGS_HERE` substitution
- Project directory detection (lines 62-78)
- Three-tier library sourcing (lines 82-110): error-handling → state-persistence → workflow-state-machine
- Pre-flight validation (lines 112-155): Function existence checks
- Argument parsing (lines 157-198): PLAN_FILE, STARTING_PHASE, DRY_RUN, MAX_ITERATIONS, CONTEXT_THRESHOLD
- Checkpoint resumption (lines 204-250): JSON v2.1 schema
- Auto-resume logic (lines 253-283): 24-hour checkpoint expiry
- Plan file validation (lines 286-305)
- Legacy plan marker migration (lines 324-340): add_not_started_markers
- State machine initialization (lines 354-420): `sm_init` with fail-fast
- State transition to IMPLEMENT (lines 422-437)
- Iteration loop variables (lines 457-469): MAX_ITERATIONS, CONTINUATION_CONTEXT, STUCK_COUNT

**Standards Compliance**:
- ✓ Execution directive (line 26): "**EXECUTE NOW**"
- ✓ `set +H` preprocessing safety (line 39)
- ✓ Error logging integration (lines 94, 153-155)
- ✓ State persistence (lines 448-474)
- ✓ Checkpoint reporting (lines 487-495)

#### Block 1b: Implementer-Coordinator Invocation (Lines 498-566)
**Purpose**: Hard barrier delegation to implementer-coordinator agent
**Pattern**: Task tool invocation with behavioral injection
**Key Features**:
- Hard barrier label (lines 500-503): "CRITICAL BARRIER - Implementer-Coordinator Invocation"
- Input contract specification (lines 518-540): plan_path, topic_path, summaries_dir, artifact_paths, continuation_context, iteration
- Iteration management (lines 538-542): MAX_ITERATIONS, CONTEXT_THRESHOLD
- Progress tracking instructions (lines 543-546): checkbox-utils.sh integration
- Expected return signal (lines 555-564): IMPLEMENTATION_COMPLETE with metadata

**Delegation Contract**:
```markdown
**Input Contract (Hard Barrier Pattern)**:
- plan_path: $PLAN_FILE
- topic_path: $TOPIC_PATH
- summaries_dir: ${TOPIC_PATH}/summaries/
- artifact_paths: reports/, plans/, summaries/, debug/, outputs/, checkpoints/
- continuation_context: ${CONTINUATION_CONTEXT:-null}
- iteration: ${ITERATION}
```

#### Block 1c: Implementation Phase Verification (Lines 568-846)
**Purpose**: Hard barrier verification - validate implementer-coordinator artifacts
**Key Validations** (lines 653-747):
1. Summaries directory existence (lines 671-686)
2. Summary file existence (lines 689-710): `find "$SUMMARIES_DIR" -name "*.md"`
3. Summary file size (lines 713-728): Minimum 100 bytes
4. Summary count tracking (lines 731-739)

**Iteration Management** (lines 751-843):
- Context estimation parsing (lines 758-769): WORK_REMAINING, CONTEXT_EXHAUSTED, CHECKPOINT_PATH
- Agent return signal parsing (lines 772-785): AGENT_PLAN_FILE, AGENT_TOPIC_PATH override
- Completion check (lines 805-843): REQUIRES_CONTINUATION flag
- Next iteration preparation (lines 809-826): CONTINUATION_CONTEXT persistence

**State Variables**:
- IMPLEMENTATION_STATUS: "continuing", "complete", "stuck", "max_iterations"
- ITERATION: Incremented for continuation
- WORK_REMAINING: Unparsed phases list

#### Block 1d: Phase Update (Lines 848-1096)
**Purpose**: Mark completed phases, update plan status, delegate to spec-updater (fallback)
**Key Operations** (lines 856-1053):
- Library re-sourcing with three-tier pattern (lines 883-898)
- Workflow state recovery (lines 902-948): STATE_ID_FILE → WORKFLOW_ID → load_workflow_state
- Completed phase extraction (lines 964-966): `grep -c "^### Phase" "$PLAN_FILE"`
- Checkbox-utils integration (lines 979-1000): mark_phase_complete, add_complete_marker
- Fallback tracking (lines 992-1012): FALLBACK_NEEDED comma-separated list
- State persistence (lines 1023-1045): append_workflow_state, save_completed_states_to_state
- Plan status update (lines 1056-1063): check_all_phases_complete → update_plan_status "COMPLETE"

**Spec-Updater Delegation** (lines 1068-1096):
Fallback Task invocation if checkbox-utils fails:
- Agent: spec-updater.md (line 1074)
- Purpose: Update plan hierarchy checkboxes (line 1080)
- Steps: mark_phase_complete for each phase, verify_checkbox_consistency (lines 1085-1089)

#### Block 2a-2c: Testing Phase (Lines 1098-1586)
**Purpose**: Test execution, result parsing, conditional branching

**Block 2a: State Load and Path Validation** (Lines 1104-1227):
- Project directory detection (lines 1106-1123)
- State file restoration (lines 1134-1200): STATE_ID_FILE → WORKFLOW_ID → load_workflow_state
- TEST_OUTPUT_PATH calculation (lines 1202-1221): `${TOPIC_PATH}/outputs/test_results_$(date +%s).md`

**Test-Executor Delegation** (Lines 1229-1289):
Task tool invocation pattern:
- Agent: test-executor.md (line 1234)
- 6-step execution process (lines 1256-1262): Create artifact → Detect framework → Execute → Parse → Update → Return
- Expected return format (lines 1264-1287): TEST_COMPLETE signal with metadata (status, framework, test_command, counts, next_state)

**Block 2: Testing Phase - Load Test Results** (Lines 1291-1586):
- Library sourcing with defensive trap pattern (lines 1299-1336)
- State restoration (lines 1338-1382)
- State transition to TEST (lines 1396-1410)
- Test result parsing (lines 1415-1468): Agent return signal extraction (TEST_STATUS, TEST_EXIT_CODE, NEXT_STATE)
- Artifact verification (lines 1439-1445): TEST_ARTIFACT_PATH existence
- State persistence (lines 1469-1504)
- State-driven transition (lines 1509-1541): Trust test-executor's NEXT_STATE recommendation
- Conditional phase setup (lines 1545-1562): DEBUG vs DOCUMENT paths

**Standards Compliance Issues**:
- ⚠ Blocks 2a and 2b should be separate per hard barrier pattern
- ⚠ Test-executor invocation should be Block 2b (execute), not embedded in Block 2a

#### Block 3: Debug Phase (Lines 1588-1612)
**Purpose**: Debug-analyst delegation for test failures
**Conditional**: Only if NEXT_STATE="DEBUG" from Block 2
**Key Operations**:
- Task invocation (lines 1591-1612): debug-analyst.md
- Input context (lines 1598-1606): Issue description, failed phase, test command, exit code, debug directory

#### Block 4: Completion (Lines 1614-1912)
**Purpose**: Workflow finalization, console summary, cleanup
**Key Operations** (lines 1619-1822):
- Library sourcing (lines 1644-1665)
- State restoration with recovery (lines 1667-1687)
- Error logging context restoration (lines 1689-1707)
- State validation (lines 1710-1773): STATE_FILE, CURRENT_STATE checks
- State transition to COMPLETE (lines 1776-1795)
- State persistence (lines 1798-1821)
- Summary plan link validation (lines 1824-1840)
- Console summary (lines 1843-1888): summary-formatting.sh integration
- IMPLEMENTATION_COMPLETE signal (lines 1890-1896)
- Checkpoint cleanup (lines 1899-1901)
- State file cleanup (lines 1904-1909)

## Comparison with /plan Command

### File Location
- **Path**: `/home/benjamin/.config/.claude/commands/plan.md`
- **Size**: 1504 lines
- **Workflow Type**: research-and-plan
- **Terminal State**: plan
- **Dependent Agents**: research-specialist, plan-architect
- **Library Dependencies**: Same as /build

### Architectural Patterns Matching /build

Both commands follow identical patterns for:

1. **Argument Capture** (plan.md lines 36-95):
   - 2-block pattern with temp file (lines 40-44)
   - Flag parsing: --complexity, --file (lines 55-95)
   - Same substitution pattern: "YOUR_FEATURE_DESCRIPTION_HERE"

2. **Library Sourcing** (plan.md lines 122-144):
   - Three-tier pattern: error-handling → state-persistence → workflow-state-machine → library-version-check
   - Same fail-fast pattern: `|| { echo "ERROR: ..."; exit 1; }`
   - Pre-flight function validation (lines 146-150)

3. **State Machine Integration** (plan.md lines 160-238):
   - `sm_init` with classification parameters (line 223)
   - `sm_transition` with fail-fast (lines 241-255)
   - State persistence via append_workflow_state (lines 457-463, 499-504)

4. **Hard Barrier Pattern** (plan.md lines 265-525):
   - Topic naming agent invocation (Block 1b: lines 384-416)
   - Path pre-calculation (Block 1b: lines 267-383)
   - Hard barrier validation (Block 1c: lines 418-525)
   - Research specialist invocation (Block 1d-exec: lines 832-857)
   - Plan architect invocation (Block 2: lines 1173-1204)

5. **Error Logging** (plan.md lines 152-178):
   - `ensure_error_log_exists` (line 153)
   - `setup_bash_error_trap` (lines 157, 174, 919, 1266)
   - `log_command_error` for validation failures (lines 189-200, 226-235)

### Key Structural Differences

| Aspect | /build Command | /plan Command |
|--------|---------------|---------------|
| **Block Count** | 7 major blocks (1a, 1b, 1c, 1d, 2, 3, 4) | 5 major blocks (1a-1d, 2, 3) |
| **Agent Delegations** | 3 agents (implementer-coordinator, test-executor, debug-analyst) | 2 agents (research-specialist, plan-architect) |
| **Conditional Phases** | Test → Debug (conditional) | Research → Plan (linear) |
| **Iteration Support** | Yes (CONTINUATION_CONTEXT, MAX_ITERATIONS) | No |
| **Checkpoint Resumption** | Yes (v2.1 schema, lines 204-250) | No |
| **Plan Modification** | Yes (checkbox-utils, spec-updater) | No (creates new plan) |

## Implementation Phase Analysis

### Phase Boundaries

The current /build command has natural separation at these boundaries:

1. **Initialize → Implement** (Lines 24-496):
   - Argument capture and validation
   - State machine initialization
   - Path allocation
   - Checkpoint resumption
   - **Output**: Initialized state, validated PLAN_FILE

2. **Implement → Test** (Lines 498-846):
   - Implementer-coordinator delegation
   - Summary artifact verification
   - Iteration management
   - Phase checkbox updates
   - **Output**: Implementation complete, plan updated

3. **Test → Debug** (Lines 1098-1586):
   - Test-executor delegation
   - Result parsing and validation
   - Conditional branching (DEBUG vs DOCUMENT)
   - **Output**: Test results, next state recommendation

4. **Debug → Complete** (Lines 1588-1912):
   - Debug-analyst delegation (conditional)
   - Workflow finalization
   - Console summary
   - **Output**: Debug report (if applicable), summary

### Proposed Split Point

**Primary Separation**: Between Block 1d (Phase Update) and Block 2a (Testing Phase)

**Rationale**:
1. **State Machine Alignment**: IMPLEMENT state completes at end of Block 1d, TEST state begins at Block 2
2. **Artifact Boundary**: Implementation produces plan updates + summaries; testing produces test results
3. **Agent Separation**: implementer-coordinator (Blocks 1b-1d) vs test-executor/debug-analyst (Blocks 2-3)
4. **Workflow Scope**: Implementation is always required; testing is conditional (may skip for non-code changes)

### /implement Command Scope

**Blocks to Include**:
- Block 1a: Implementation Phase Setup (lines 24-496)
- Block 1b: Implementer-Coordinator Invocation (lines 498-566)
- Block 1c: Implementation Phase Verification (lines 568-846)
- Block 1d: Phase Update (lines 848-1096)
- Modified Block 4: Completion (simplified, no test artifacts)

**New Requirements**:
1. Terminal state should be IMPLEMENT (not COMPLETE)
2. Console summary should reference test command for next step
3. No test-executor or debug-analyst delegation
4. IMPLEMENTATION_COMPLETE signal for buffer-opener hook

**Estimated Size**: ~600-700 lines (condensed from 1096 lines via checkpoint consolidation)

### /test Command Scope

**Blocks to Include**:
- New Block 1: Setup - Load plan, restore implementation state
- Block 2a: Test Path Validation (lines 1104-1227) → becomes Block 2
- Test-Executor Delegation (lines 1229-1289) → becomes Block 3
- Block 2b-2c: Test Result Parsing (lines 1291-1586) → becomes Block 4
- Block 3: Debug Phase (lines 1588-1612) → becomes Block 5 (conditional)
- Block 4: Completion (lines 1614-1912) → becomes Block 6

**New Requirements**:
1. Accept plan file path as argument (derive from /implement output)
2. Terminal state should be TEST (success) or DEBUG (failure)
3. No implementation delegation (reads existing implementation artifacts)
4. Conditional debug-analyst delegation based on test results
5. TEST_COMPLETE signal for buffer-opener hook

**Estimated Size**: ~700-800 lines (includes new setup + conditional branching)

## State Machine Implications

### Current State Transitions (workflow-state-machine.sh lines 56-65)

```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research,implement"     # /plan uses research, /build uses implement
  [research]="plan,complete"            # /plan terminal
  [plan]="implement,complete,debug"     # /plan can skip to complete
  [implement]="test"                    # MUST go through testing (enforce sequence)
  [test]="debug,document,complete"      # Conditional: debug if failed, document if passed
  [debug]="test,document,complete"      # Can retry testing, complete if unfixable
  [document]="complete"
  [complete]=""                         # Terminal state
)
```

### Required Changes for Split

**Current Transition**: `[implement]="test"` (enforces full-implementation workflow)

**Proposed New Transitions**:
```bash
[implement]="test,complete"           # Allow /implement to complete without testing
[test]="debug,document,complete"      # Unchanged (existing conditional logic)
```

**Rationale**:
- `/implement` should be able to complete at IMPLEMENT state (terminal for implement-only workflows)
- `/test` can be invoked separately and should accept IMPLEMENT as valid predecessor
- Existing test → debug → complete logic remains unchanged

### Terminal State Configuration

**Current /build Configuration** (build.md lines 354-420):
```bash
WORKFLOW_TYPE="full-implementation"
TERMINAL_STATE="complete"
```

**Proposed /implement Configuration**:
```bash
WORKFLOW_TYPE="implement-only"
TERMINAL_STATE="implement"           # Terminal at implement state
```

**Proposed /test Configuration**:
```bash
WORKFLOW_TYPE="test-and-debug"
TERMINAL_STATE="complete"            # Terminal after test → debug → complete
```

### sm_transition Validation

Both commands must update state transitions:

**In /implement** (after Block 1c verification):
```bash
sm_transition "$STATE_IMPLEMENT" "implementation complete" || exit 1
# Then transition to terminal
sm_transition "$STATE_COMPLETE" "workflow complete (implement-only)" || exit 1
```

**In /test** (Block 1 setup):
```bash
# Validate predecessor state from /implement
if [ "$CURRENT_STATE" != "$STATE_IMPLEMENT" ]; then
  echo "ERROR: Invalid predecessor state: $CURRENT_STATE"
  echo "  /test requires IMPLEMENT state from /implement command"
  exit 1
fi

sm_transition "$STATE_TEST" "starting test phase" || exit 1
```

## Agent Delegation Patterns

### Implementer-Coordinator Agent

**Current Usage** (build.md lines 498-566):
- Agent file: `.claude/agents/implementer-coordinator.md`
- Delegation block: Block 1b (lines 498-566)
- Verification block: Block 1c (lines 568-846)

**Responsibilities**:
1. Execute implementation phases from plan (line 549)
2. Perform wave-based parallelization (line 511)
3. Track progress with checkbox-utils (lines 543-546)
4. Create implementation summary (line 532, 552-554)
5. Manage iteration context (lines 528, 538-542)
6. Return IMPLEMENTATION_COMPLETE signal (lines 555-564)

**Contract Fields**:
- plan_path, topic_path, summaries_dir (lines 518-520)
- artifact_paths (reports, plans, summaries, debug, outputs, checkpoints) (lines 521-527)
- continuation_context, iteration (lines 528-529)
- Starting phase, workflow type, execution mode (lines 535-537)
- Max iterations, context threshold (lines 539-540)

**Hard Barrier Compliance**: ✓ Complete
- Path pre-calculation: Implicit (summaries_dir known)
- Mandatory delegation: "CRITICAL BARRIER" label (line 500)
- Artifact verification: Summary file existence + size (lines 689-728)
- Error logging: log_command_error on verification failure (lines 692-699)

**Migration to /implement**: No changes required (keep delegation as-is)

### Test-Executor Agent

**Current Usage** (build.md lines 1229-1289):
- Agent file: `.claude/agents/test-executor.md`
- Delegation block: Embedded in Block 2a (lines 1229-1289)
- Verification block: Block 2 (lines 1439-1445)

**Responsibilities**:
1. Auto-detect test framework (line 1258)
2. Execute tests with isolation (line 1259)
3. Parse test results (line 1260)
4. Update test artifact (line 1261)
5. Return TEST_COMPLETE signal (lines 1264-1287)
6. Recommend next state (DEBUG or DOCUMENT) (line 1279)

**Contract Fields**:
- plan_path, topic_path, artifact_paths (lines 1242-1246)
- test_config (test_command, retry_on_failure, isolation_mode, max_retries, timeout_minutes) (lines 1247-1252)
- output_path (pre-calculated TEST_OUTPUT_PATH) (line 1253)

**Hard Barrier Compliance**: ⚠ Partial
- Path pre-calculation: ✓ Yes (TEST_OUTPUT_PATH in Block 2a, line 1211)
- Mandatory delegation: ⚠ Missing "CRITICAL BARRIER" label
- Artifact verification: ✓ Yes (lines 1439-1445)
- Error logging: ✓ Yes (lines 1441-1444)

**Migration to /test**: Requires hard barrier refactor
- Split into 3 blocks: Setup (Block 2) → Execute (Block 3) → Verify (Block 4)
- Add CRITICAL BARRIER label
- Move TEST_OUTPUT_PATH calculation to Block 2 (path pre-calculation pattern)

### Debug-Analyst Agent

**Current Usage** (build.md lines 1588-1612):
- Agent file: `.claude/agents/debug-analyst.md`
- Delegation block: Block 3 (lines 1591-1612)
- Verification block: None (debug is terminal/optional phase)

**Responsibilities**:
1. Analyze test failures (line 1599)
2. Create debug report in debug/ directory (line 1605)
3. Provide troubleshooting guidance (implicit)
4. Return DEBUG_COMPLETE signal (line 1610)

**Contract Fields**:
- Issue description (test exit code) (lines 1599-1600)
- Failed phase ("testing") (line 1601)
- Test command, exit code (lines 1602-1603)
- Debug directory (line 1604)
- Workflow type (line 1605)

**Hard Barrier Compliance**: ✗ Not applicable
- Debug phase is conditional (only on test failure)
- No verification block (debug reports are best-effort)
- Agent creates debug artifacts but no mandatory validation

**Migration to /test**: No changes required (keep conditional delegation as-is)

## Command Authoring Standards Compliance

### Current /build Compliance Score

Based on `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md`:

#### Execution Directive Requirements (Section 1)
- ✓ All bash blocks have execution directives (lines 26, 574, 856, 1295, 1619)
- ✓ Uses "**EXECUTE NOW**:" pattern consistently
- ✓ Task invocations have imperative instructions (lines 498, 1229, 1591)

#### Task Tool Invocation Patterns (Section 2)
- ✓ No YAML code block wrappers (correct pseudo-syntax)
- ✓ Behavioral injection pattern (lines 512, 1234, 1595)
- ✗ Missing explicit completion signal verification in some blocks

#### Subprocess Isolation Requirements (Section 3)
- ✓ `set +H` at start of every block (lines 39, 576, 859, 1297, 1621)
- ✓ Library re-sourcing in every block (three-tier pattern)
- ✓ Return code verification for critical functions (lines 406-420, 424-437)

#### State Persistence Patterns (Section 4)
- ✓ File-based communication via append_workflow_state
- ✓ Workflow ID persistence in fixed location (lines 362-368)
- ✓ Conditional initialization preserved (lines 620-659 via source "$STATE_FILE")

#### Argument Capture Patterns (Section 6)
- ✓ 2-block standardized pattern (Block 1a captures, validates immediately)
- ✓ Temp file with timestamp (line 53): `build_arg_$(date +%s%N).txt`
- ✓ Path file for recovery (line 56): `build_arg_path.txt`

#### Output Suppression Requirements (Section 7)
- ✓ Library sourcing suppression (lines 83-92): `2>/dev/null || { ... }`
- ✓ Directory operations suppression (line 52): `2>/dev/null || true`
- ✓ Single summary line per block (checkpoint reporting)

#### Prohibited Patterns (Section 8)
- ✓ No `if !` or `elif !` negation patterns (exit code capture used throughout)
- ✓ Examples: lines 193-199, 406-420, 635-644

**Overall Compliance**: 95% (missing hard barrier refinement for test-executor)

### /plan Command Compliance Score

Based on same standards:

#### All Sections
- ✓ Execution directives (lines 27, 272, 384, 419, 532, 620, 864, 1210)
- ✓ Task invocations with behavioral injection (lines 390, 835, 1174)
- ✓ `set +H` consistently (lines 40, 275, 425, 623, 867, 1213)
- ✓ Three-tier library sourcing (lines 122-136, 686-693, 888-899)
- ✓ 2-block argument capture (lines 36-95)
- ✓ State persistence (lines 457-463, 499-504, 808-823, 1122-1125)
- ✓ Output suppression (lines 125-132, 689-691)
- ✓ No prohibited negation patterns

**Overall Compliance**: 100% (reference standard for new commands)

### Standards Gaps in /build

1. **Hard Barrier Pattern Refinement** (test-executor):
   - Missing separate Block 2b for test-executor invocation
   - Block 2a combines setup + execution (violates separation)
   - Fix: Split Block 2a into 2a (setup) + 2b (execute) + 2c (verify)

2. **Checkpoint Consolidation Opportunity**:
   - Block 1a has very verbose setup (472 lines)
   - Could consolidate pre-flight validation, argument parsing into single summary
   - Target: Reduce to ~300 lines via output suppression

3. **Error Logging Coverage**:
   - Some validation failures lack log_command_error (e.g., lines 286-299)
   - Should add error logging for all exit paths

## Recommended Refactor Approach

### Phase 1: Create /implement Command

**Scope**: Extract Blocks 1a-1d from /build into new command

**Files to Create**:
1. `/home/benjamin/.config/.claude/commands/implement.md` (estimated 700 lines)

**Key Changes**:
1. **Frontmatter**:
   ```yaml
   allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
   argument-hint: [plan-file] [starting-phase] [--dry-run] [--max-iterations=N]
   description: Implementation-only workflow - Execute plan phases without testing
   command-type: primary
   dependent-agents:
     - implementer-coordinator
   library-requirements:
     - workflow-state-machine.sh: ">=2.0.0"
     - state-persistence.sh: ">=1.5.0"
   documentation: See .claude/docs/guides/commands/implement-command-guide.md
   ```

2. **Block Structure**:
   - Block 1a: Implementation Phase Setup (preserve lines 24-496 with modifications)
   - Block 1b: Implementer-Coordinator Invocation (preserve lines 498-566)
   - Block 1c: Implementation Verification (preserve lines 568-846)
   - Block 1d: Phase Update (preserve lines 848-1096)
   - Block 2: Completion (new, simplified from build.md Block 4)

3. **State Machine Integration**:
   ```bash
   # Block 1a: After sm_init
   WORKFLOW_TYPE="implement-only"
   TERMINAL_STATE="$STATE_IMPLEMENT"

   # Block 2: Final transition
   sm_transition "$STATE_COMPLETE" "implementation complete (no testing)" || exit 1
   ```

4. **Console Summary** (Block 2):
   ```bash
   SUMMARY_TEXT="Completed implementation of ${COMPLETED_PHASE_COUNT:-0} phases. Implementation summary includes phase breakdown and git commit history. Run /test to execute test suite."

   NEXT_STEPS="  • Review implementation: cat $LATEST_SUMMARY
     • Run tests: /test $PLAN_FILE
     • Check git commits: git log --oneline -5"
   ```

5. **Return Signal**:
   ```bash
   echo "IMPLEMENTATION_COMPLETE"
   echo "  summary_path: $LATEST_SUMMARY"
   echo "  plan_path: $PLAN_FILE"
   echo "  next_command: /test $PLAN_FILE"
   ```

**Testing Strategy**:
1. Create test plan with 2-3 simple phases
2. Run `/implement` and verify:
   - Implementation summary created
   - Plan phases marked complete
   - No test execution
   - IMPLEMENTATION_COMPLETE signal emitted
3. Validate state file contains TERMINAL_STATE="implement"

### Phase 2: Create /test Command

**Scope**: Extract Blocks 2-4 from /build into new command with hard barrier refactor

**Files to Create**:
1. `/home/benjamin/.config/.claude/commands/test.md` (estimated 800 lines)

**Key Changes**:
1. **Frontmatter**:
   ```yaml
   allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
   argument-hint: <plan-file> [--retry-on-failure] [--timeout=MINUTES]
   description: Test and debug workflow - Execute test suite with optional debugging
   command-type: primary
   dependent-agents:
     - test-executor
     - debug-analyst
   library-requirements:
     - workflow-state-machine.sh: ">=2.0.0"
     - state-persistence.sh: ">=1.5.0"
   documentation: See .claude/docs/guides/commands/test-command-guide.md
   ```

2. **Block Structure**:
   - Block 1: Setup - Argument capture, state restoration, path derivation
   - Block 2: Test Setup - Path pre-calculation, state transition (refactored from build.md lines 1104-1227)
   - Block 3: Test Execution [CRITICAL BARRIER] - test-executor invocation (refactored from build.md lines 1229-1289)
   - Block 4: Test Verification - Parse results, validate artifact (refactored from build.md lines 1291-1586)
   - Block 5: Debug Phase [CONDITIONAL] - debug-analyst invocation if tests failed (preserve build.md lines 1588-1612)
   - Block 6: Completion - Finalization, summary (adapted from build.md lines 1614-1912)

3. **Argument Capture** (Block 1):
   ```bash
   # Accept plan file path (from /implement output or manual)
   PLAN_FILE="$1"
   if [ -z "$PLAN_FILE" ]; then
     echo "ERROR: Plan file required"
     echo "  Usage: /test <plan-file> [--retry-on-failure] [--timeout=MINUTES]"
     exit 1
   fi

   # Derive topic path from plan file
   TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
   ```

4. **State Validation** (Block 1):
   ```bash
   # Verify implementation was completed
   IMPLEMENTATION_STATUS=$(grep "^IMPLEMENTATION_STATUS=" "$STATE_FILE" | cut -d'=' -f2 || echo "unknown")
   if [ "$IMPLEMENTATION_STATUS" != "complete" ]; then
     echo "WARNING: Implementation may be incomplete (status: $IMPLEMENTATION_STATUS)"
     echo "  Proceeding with testing anyway"
   fi
   ```

5. **Hard Barrier Refactor** (Blocks 2-4):
   ```markdown
   ## Block 2: Test Path Pre-Calculation

   ```bash
   # Pre-calculate TEST_OUTPUT_PATH (hard barrier pattern)
   TEST_OUTPUT_PATH="${TOPIC_PATH}/outputs/test_results_$(date +%s).md"

   # Validate path is absolute
   if [[ ! "$TEST_OUTPUT_PATH" =~ ^/ ]]; then
     log_command_error "validation_error" "TEST_OUTPUT_PATH not absolute" "$TEST_OUTPUT_PATH"
     exit 1
   fi

   # Persist for Block 4 verification
   append_workflow_state "TEST_OUTPUT_PATH" "$TEST_OUTPUT_PATH"

   echo "Test output path: $TEST_OUTPUT_PATH"
   ```

   ## Block 3: Test Execution [CRITICAL BARRIER]

   **HARD BARRIER**: This block MUST invoke test-executor via Task tool.
   Block 4 will FAIL if test artifact not created at the pre-calculated path.

   **EXECUTE NOW**: Invoke test-executor subagent

   Task {
     # ... same as build.md lines 1229-1289
   }

   ## Block 4: Test Verification (Hard Barrier)

   ```bash
   # Restore TEST_OUTPUT_PATH from state
   source "$STATE_FILE"

   # HARD BARRIER: Test artifact MUST exist
   if [ ! -f "$TEST_OUTPUT_PATH" ]; then
     log_command_error "agent_error" \
       "test-executor failed to create artifact" \
       "Expected: $TEST_OUTPUT_PATH"
     echo "ERROR: HARD BARRIER FAILED - Test artifact not found"
     exit 1
   fi
   ```
   ```

6. **Conditional Debug** (Block 5):
   ```bash
   # Only invoke debug-analyst if tests failed
   if [ "$NEXT_STATE" = "DEBUG" ]; then
     # Task invocation (same as build.md lines 1591-1612)
   else
     echo "Tests passed, skipping debug phase"
   fi
   ```

7. **Console Summary** (Block 6):
   ```bash
   if [ "$TESTS_PASSED" = "true" ]; then
     SUMMARY_TEXT="All tests passed. Test results and coverage available in test artifact."
     NEXT_STEPS="  • Review test results: cat $TEST_ARTIFACT_PATH
       • Update documentation: /document $PLAN_FILE
       • Deploy changes: (manual deployment steps)"
   else
     SUMMARY_TEXT="Tests failed. Debug report created with troubleshooting guidance."
     NEXT_STEPS="  • Review debug report: cat $DEBUG_REPORT_PATH
       • Fix issues and re-run: /test $PLAN_FILE
       • Check test failures: see test artifact for details"
   fi
   ```

**Testing Strategy**:
1. Use output from `/implement` test run
2. Run `/test` with plan file path and verify:
   - Test execution occurs
   - Test artifact created at pre-calculated path
   - Conditional debug invocation (create failing test to verify)
   - TEST_COMPLETE signal emitted
3. Validate hard barrier: Delete test artifact after test-executor, verify Block 4 fails

### Phase 3: Update /build Command

**Scope**: Modify /build to orchestrate /implement + /test

**Options**:

**Option A: Deprecate /build** (Recommended)
- Add deprecation notice to build.md
- Redirect users to `/implement` + `/test`
- Preserve file for backward compatibility (6-month deprecation period)
- Remove after deprecation period

**Option B: Wrapper Command**
- Rewrite /build as thin wrapper calling /implement → /test
- Simpler migration path
- Maintains existing workflow for users

**Option C: Full Refactor**
- Keep /build as full-implementation workflow
- Extract shared logic to library functions
- /implement and /test become specialized variants

**Recommendation**: Option A (Deprecate)
- Simplest maintenance burden
- Forces users to explicit workflow choice
- Aligns with standards (single-responsibility commands)
- 6-month deprecation period provides transition time

### Phase 4: Documentation Updates

**Files to Create**:
1. `/home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md`
2. `/home/benjamin/.config/.claude/docs/guides/commands/test-command-guide.md`

**Files to Update**:
1. `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
   - Add /implement and /test entries
   - Update /build entry with deprecation notice
2. `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md`
   - Add deprecation notice at top
   - Link to /implement and /test guides
3. `/home/benjamin/.config/CLAUDE.md`
   - Update "Project-Specific Commands" section
   - Add /implement and /test to command list

**Template Structure** (from build-command-guide.md):
```markdown
# /implement Command Guide

## Overview
- **Purpose**: Execute implementation plan phases without testing
- **Workflow Type**: implement-only
- **Terminal State**: implement
- **Prerequisites**: Existing implementation plan (from /plan)
- **Output**: Implementation summary, updated plan checkboxes
- **Next Steps**: Run /test to execute test suite

## Usage
...

## Workflow Architecture
...

## Integration with /test
...
```

### Phase 5: State Machine Updates

**File to Modify**:
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Changes Required**:

1. **Update Transition Table** (line 56):
   ```bash
   declare -gA STATE_TRANSITIONS=(
     [initialize]="research,implement"
     [research]="plan,complete"
     [plan]="implement,complete,debug"
     [implement]="test,complete"        # NEW: Allow implement to complete without testing
     [test]="debug,document,complete"
     [debug]="test,document,complete"
     [document]="complete"
     [complete]=""
   )
   ```

2. **Add Workflow Type** (line 443):
   ```bash
   case "$WORKFLOW_SCOPE" in
     research-only)
       TERMINAL_STATE="$STATE_RESEARCH"
       ;;
     research-and-plan)
       TERMINAL_STATE="$STATE_PLAN"
       ;;
     research-and-revise)
       TERMINAL_STATE="$STATE_PLAN"
       ;;
     implement-only)                     # NEW: For /implement command
       TERMINAL_STATE="$STATE_IMPLEMENT"
       ;;
     test-and-debug)                     # NEW: For /test command
       TERMINAL_STATE="$STATE_COMPLETE"
       ;;
     full-implementation)
       TERMINAL_STATE="$STATE_COMPLETE"
       ;;
     debug-only)
       TERMINAL_STATE="$STATE_DEBUG"
       ;;
     *)
       echo "WARNING: Unknown workflow scope '$WORKFLOW_SCOPE', defaulting to full-implementation" >&2
       TERMINAL_STATE="$STATE_COMPLETE"
       ;;
   esac
   ```

3. **Validation** (lines 788-815):
   - Update sm_validate_state to accept implement-only and test-and-debug workflow types
   - No code changes needed (WORKFLOW_SCOPE validation is permissive)

**Testing**:
```bash
# Test state machine transitions
source .claude/lib/workflow/workflow-state-machine.sh

# Test implement-only workflow
sm_init "test" "implement" "implement-only" 3 "[]"
echo "Terminal: $TERMINAL_STATE"  # Should be "implement"
sm_transition "$STATE_IMPLEMENT"  # Should succeed
sm_transition "$STATE_COMPLETE"   # Should succeed (new transition)

# Test test-and-debug workflow
sm_init "test" "test" "test-and-debug" 3 "[]"
echo "Terminal: $TERMINAL_STATE"  # Should be "complete"
sm_transition "$STATE_TEST"       # Should succeed
sm_transition "$STATE_DEBUG"      # Should succeed (if tests fail)
```

## Risk Analysis

### High-Risk Items

1. **State Persistence Across Commands** (HIGH)
   - **Risk**: /test cannot access /implement state if state file not preserved
   - **Mitigation**: Implement state file naming convention (plan-based instead of workflow-based)
   - **Example**: `${TOPIC_PATH}/.state/implement_state.sh` (persistent), not `${TEMP_DIR}/workflow_${ID}.sh` (ephemeral)

2. **Checkpoint Schema Changes** (HIGH)
   - **Risk**: Existing checkpoints become incompatible with new commands
   - **Mitigation**: Version checkpoint schema, implement migration logic
   - **Testing**: Verify /build checkpoints can be migrated to /implement + /test

3. **Backward Compatibility** (MEDIUM)
   - **Risk**: Users with scripts calling /build will break
   - **Mitigation**: 6-month deprecation period with clear migration guide
   - **Communication**: Add deprecation notice to /build, CLAUDE.md, command-reference.md

### Medium-Risk Items

1. **Agent Contract Changes** (MEDIUM)
   - **Risk**: Agents expect full workflow context, break with partial workflow
   - **Mitigation**: Agents already isolated (input contracts explicitly defined)
   - **Testing**: Verify implementer-coordinator works without test context

2. **Error Handling Gaps** (MEDIUM)
   - **Risk**: New error paths not covered by log_command_error integration
   - **Mitigation**: Comprehensive error logging in new commands
   - **Testing**: Use /errors command to verify all error types logged

3. **Documentation Inconsistency** (LOW)
   - **Risk**: Outdated examples in docs reference /build
   - **Mitigation**: Global search-and-replace, update all examples
   - **Testing**: Grep for "build" in .claude/docs/, verify all references updated

### Low-Risk Items

1. **Tool Access Changes** (LOW)
   - **Risk**: Commands need different tool permissions
   - **Mitigation**: Both /implement and /test use same tool set as /build
   - **No Changes**: allowed-tools frontmatter identical

2. **Buffer-Opener Hook** (LOW)
   - **Risk**: Hook expects IMPLEMENTATION_COMPLETE signal format
   - **Mitigation**: Both commands emit same signal format
   - **Testing**: Verify buffer opens implementation summary after /implement

## Testing Strategy

### Unit Tests

**Create** `/home/benjamin/.config/.claude/tests/commands/test_implement_command.sh`:
```bash
#!/bin/bash
# Test /implement command in isolation

# Test 1: Verify argument capture
# Test 2: Verify state machine transitions (initialize → implement → complete)
# Test 3: Verify implementer-coordinator delegation
# Test 4: Verify summary creation
# Test 5: Verify IMPLEMENTATION_COMPLETE signal
```

**Create** `/home/benjamin/.config/.claude/tests/commands/test_test_command.sh`:
```bash
#!/bin/bash
# Test /test command in isolation

# Test 1: Verify plan file argument
# Test 2: Verify state restoration from /implement
# Test 3: Verify test-executor delegation
# Test 4: Verify hard barrier (missing test artifact)
# Test 5: Verify conditional debug invocation
# Test 6: Verify TEST_COMPLETE signal
```

### Integration Tests

**Create** `/home/benjamin/.config/.claude/tests/integration/test_implement_test_workflow.sh`:
```bash
#!/bin/bash
# Test complete implement → test workflow

# Setup: Create test plan
# Step 1: Run /implement, capture summary path
# Step 2: Verify implementation complete, plan updated
# Step 3: Run /test with plan file from Step 1
# Step 4: Verify test execution, results captured
# Step 5: Verify state transitions (implement → test → complete)
# Cleanup: Remove test artifacts
```

### Regression Tests

**Update** `/home/benjamin/.config/.claude/tests/integration/test_build_command.sh`:
```bash
#!/bin/bash
# Verify /build wrapper (if Option B chosen)

# Test 1: Verify /build calls /implement
# Test 2: Verify /build calls /test after /implement
# Test 3: Verify backward compatibility with existing checkpoints
```

## Recommendations

### Immediate Actions (Phase 1)

1. **Create /implement Command** (Estimated: 8-12 hours)
   - Extract Blocks 1a-1d from build.md
   - Add implement-only state machine integration
   - Create implement-command-guide.md
   - Write unit tests

2. **Update State Machine** (Estimated: 2-4 hours)
   - Add implement-only workflow type
   - Update STATE_TRANSITIONS table
   - Test state transitions

3. **Create Integration Tests** (Estimated: 4-6 hours)
   - Test implement-only workflow
   - Verify state persistence
   - Validate agent delegation

### Short-Term Actions (Phase 2-3)

1. **Create /test Command** (Estimated: 10-14 hours)
   - Extract Blocks 2-4 from build.md
   - Refactor test-executor hard barrier (3-block pattern)
   - Add conditional debug delegation
   - Create test-command-guide.md
   - Write unit tests

2. **Deprecate /build** (Estimated: 2-4 hours)
   - Add deprecation notice
   - Update documentation
   - Create migration guide

3. **Integration Testing** (Estimated: 6-8 hours)
   - Test implement → test workflow
   - Verify checkpoint compatibility
   - Test error scenarios

### Long-Term Actions (Phase 4-5)

1. **Documentation Updates** (Estimated: 6-8 hours)
   - Update CLAUDE.md
   - Update command-reference.md
   - Create workflow comparison table
   - Update all examples

2. **Monitoring and Refinement** (Ongoing)
   - Track error logs via /errors command
   - Collect user feedback
   - Refine hard barrier patterns
   - Update standards documentation

### Total Estimated Effort

- **Phase 1**: 14-22 hours
- **Phase 2-3**: 18-26 hours
- **Phase 4-5**: 6-8 hours (+ ongoing monitoring)
- **Total**: 38-56 hours (approximately 1-1.5 weeks of focused work)

## References

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/build.md` (1913 lines)
- `/home/benjamin/.config/.claude/commands/plan.md` (1504 lines)
- `/home/benjamin/.config/.claude/commands/research.md` (referenced)

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (1051 lines)
  - Lines 29-90: Execution directive requirements
  - Lines 92-166: Task tool invocation patterns
  - Lines 168-230: Subprocess isolation requirements
  - Lines 232-271: State persistence patterns
  - Lines 370-502: Argument capture patterns (2-block standardized pattern)
  - Lines 686-909: Output suppression requirements
  - Lines 943-1037: Prohibited patterns (negation in conditionals)

### Architecture Patterns
- `/home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md` (616 lines)
  - Lines 45-166: Setup → Execute → Verify pattern (3-block structure)
  - Lines 74-166: Research phase delegation template (path pre-calculation)
  - Lines 176-287: Plan revision delegation template
  - Lines 289-365: Pattern requirements (CRITICAL BARRIER label, fail-fast verification, state transitions)
  - Lines 367-466: Anti-patterns (merged bash+task, soft verification, missing error logging)

### Library Files
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` (1075 lines)
  - Lines 56-65: State transition table
  - Lines 393-513: sm_init function (state machine initialization)
  - Lines 609-783: sm_transition function (state validation and transition)
  - Lines 127-153: save_completed_states_to_state (array persistence)

### Agent Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (691 lines)
  - Lines 24-51: Hard barrier pattern compliance (receive and verify report path)
  - Lines 53-119: File creation FIRST pattern
  - Lines 201-237: Progress streaming requirements
  - Lines 322-410: Completion criteria (28 requirements)

### Testing Utilities
- `/home/benjamin/.config/.claude/lib/util/detect-testing.sh` (test framework detection)
- `/home/benjamin/.config/.claude/lib/util/generate-testing-protocols.sh` (test protocol generation)

## Conclusion

The /build command refactor into /implement and /test commands is architecturally sound and well-supported by existing patterns in the codebase. The /plan command provides a complete reference for standards-compliant structure, and the hard barrier pattern documentation provides clear guidance for agent delegation.

**Key Success Factors**:
1. **Clear State Boundaries**: IMPLEMENT state is natural separation point
2. **Existing Patterns**: /plan command demonstrates all required patterns
3. **Modular Agents**: implementer-coordinator, test-executor, debug-analyst already isolated
4. **Standards Compliance**: Both commands can achieve 100% compliance with command-authoring.md
5. **Incremental Migration**: Users can adopt /implement + /test gradually while /build remains available

**Recommended Timeline**:
- **Week 1**: Phase 1 (/implement command creation)
- **Week 2**: Phase 2-3 (/test command creation, /build deprecation)
- **Week 3**: Phase 4-5 (documentation updates, integration testing)
- **Ongoing**: Monitor error logs, refine based on usage patterns

The refactor will improve modularity, reduce context usage, enable independent testing workflows, and align with project standards for command architecture.
