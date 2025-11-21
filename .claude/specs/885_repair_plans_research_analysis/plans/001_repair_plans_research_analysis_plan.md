# Unified Repair Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Unified repair implementation combining error infrastructure fixes and /build iteration persistence
- **Scope**: Systematic implementation of validated repair phases from Plans 871 and 881, removing obsolete work
- **Estimated Phases**: 10
- **Estimated Hours**: 23.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 142.5
- **Research Reports**:
  - [Repair Plans Comprehensive Analysis](/home/benjamin/.config/.claude/specs/885_repair_plans_research_analysis/reports/001_repair_plans_comprehensive_analysis.md)

## Overview

This plan unifies and optimizes two existing repair plans (871: Error Analysis and Repair, 881: Build Persistent Workflow Refactor) based on comprehensive research analysis of current implementation state. Research revealed that **40% of Plan 871's phases are obsolete** due to features already implemented in the current codebase, while **Plan 881 remains fully relevant** with no existing iteration logic.

### Key Objectives

1. **Fix Production Errors**: Eliminate 60% of current production errors (exit code 127 for missing functions) through centralized library initialization
2. **Enable Large Plan Support**: Transform /build from single-shot to persistent iteration loop supporting 40+ phase plans
3. **Complete Partial Implementations**: Finish exit code capture pattern audit and test script validation
4. **Enhance Diagnostics**: Add topic naming agent diagnostics and state transition validation
5. **Ensure Reliability**: Comprehensive testing and documentation for all new features

### Research Synthesis

Research analysis identified critical implementation gaps:

**Already Implemented** (removed from plan):
- Error logging infrastructure with JSONL format
- State persistence library with atomic writes
- Bash error trap with global variables
- Test mode detection via CLAUDE_TEST_MODE
- Checkpoint utilities v2.0

**Partially Implemented** (needs completion):
- Exit code capture pattern (some commands still use bash history expansion)
- Test script validation (3 scripts lack execute permissions)
- Iteration infrastructure (agent supports continuation but /build doesn't use it)

**Not Implemented** (core work):
- command-init.sh centralized library loader
- /build iteration loop with MAX_ITERATIONS
- Context monitoring and graceful halt logic
- Checkpoint v2.1 with iteration tracking
- Stuck state detection

**Production Impact**: Recent error logs show 6/10 errors (60%) are exit code 127 for missing library functions despite libraries existing. This validates the need for centralized library initialization with function validation.

## Success Criteria

- [ ] Zero exit code 127 errors for library functions in 24 hours of production use
- [ ] /build successfully completes 12-phase plan in 2-3 iterations
- [ ] /build gracefully halts at 90% context threshold and creates resumption checkpoint
- [ ] Stuck detection prevents infinite loops (work_remaining unchanged for 2 iterations)
- [ ] All test scripts executable with proper shebangs and TEST_MODE
- [ ] Topic naming agent failures log actionable diagnostic information
- [ ] Invalid state transitions show actionable error messages with resolution steps
- [ ] >90% test coverage for all new iteration logic
- [ ] All documentation updated with persistent workflow patterns and examples

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Command Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  build.md    │  │  plan.md     │  │  debug.md    │     │
│  │  (iteration) │  │ (agent diag) │  │ (exit codes) │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            ▼                                │
│                 ┌─────────────────────┐                     │
│                 │  command-init.sh    │ ◄── NEW            │
│                 │  (library loader)   │                     │
│                 └─────────┬───────────┘                     │
│                           │                                 │
└───────────────────────────┼─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  Library Layer (Core)                       │
│  ┌──────────────────┐  ┌───────────────────┐              │
│  │ error-handling   │  │ state-persistence │ ◄── EXISTS   │
│  │ (logging + trap) │  │ (atomic writes)   │              │
│  └──────────────────┘  └───────────────────┘              │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Workflow Layer (Orchestration)                 │
│  ┌─────────────────────┐  ┌───────────────────────┐        │
│  │ workflow-state-     │  │ checkpoint-utils.sh   │        │
│  │ machine.sh          │  │ (v2.0 → v2.1)         │ ◄── EXTEND
│  │ (+ validation)      │  │ (iteration tracking)  │        │
│  └─────────────────────┘  └───────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│            /build Iteration Loop (NEW)                      │
│                                                             │
│  ITERATION=1                                                │
│  while [ $ITERATION -le $MAX_ITERATIONS ]; do              │
│    ┌─────────────────────────────────────┐                │
│    │ 1. Check context usage              │                │
│    │    if >90%: halt, save checkpoint   │                │
│    ├─────────────────────────────────────┤                │
│    │ 2. Invoke implementer-coordinator   │                │
│    │    with continuation_context        │                │
│    ├─────────────────────────────────────┤                │
│    │ 3. Parse work_remaining             │                │
│    │    if empty: exit success           │                │
│    │    if unchanged: stuck, exit error  │                │
│    ├─────────────────────────────────────┤                │
│    │ 4. Save iteration checkpoint        │                │
│    │    ITERATION++, continue            │                │
│    └─────────────────────────────────────┘                │
│  done                                                       │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

**1. command-init.sh (Phase 1)**
- Centralized library loader with validation
- Sources: error-handling, state-persistence, workflow-state-machine, checkpoint-utils
- Validates each critical function is defined after sourcing
- Provides actionable error messages if libraries missing or corrupt
- Exports common environment variables (CLAUDE_PROJECT_DIR, CLAUDE_LIB)

**2. /build Iteration Loop (Phase 5)**
- MAX_ITERATIONS: Default 5, configurable via --max-iterations flag
- ITERATION counter: Tracks current iteration (1-based)
- CONTINUATION_CONTEXT: Path to previous iteration summary
- work_remaining parser: Extracts incomplete phases from agent output
- Graceful exit on completion (work_remaining empty) or stuck (unchanged)

**3. Context Monitoring (Phase 6)**
- estimate_context_usage(): Heuristic calculation based on plan size, completed phases, remaining phases
- Formula: `base + (completed * 15000) + (remaining * 12000) + (continuation * 5000)`
- 90% threshold check before each iteration
- save_resumption_checkpoint(): Creates v2.1 checkpoint with iteration state
- Conservative threshold to avoid context overflow

**4. Checkpoint v2.1 Schema (Phase 7)**
```json
{
  "version": "2.1",
  "timestamp": "2025-11-20T12:34:56Z",
  "plan_path": "/path/to/plan.md",
  "iteration": 3,
  "max_iterations": 5,
  "continuation_context": "/path/to/iteration_2_summary.md",
  "work_remaining": ["phase_8", "phase_9", "phase_10"],
  "last_work_remaining": ["phase_8", "phase_9", "phase_10", "phase_11"],
  "context_estimate": 185000,
  "halt_reason": "context_threshold"
}
```

**5. State Machine Validation Enhancement (Phase 8)**
- Add precondition validation to sm_transition()
- Validate expected current state matches actual state
- Provide diagnostic output with resolution steps
- Add build test phase error context (which phase failed, test command used, error type)

### Integration Points

**Existing Systems**:
- Error logging: command-init.sh will use log_command_error for sourcing failures
- State persistence: Iteration loop will use append_workflow_state for iteration events
- Checkpoint system: Extends existing v2.0 schema to v2.1 with iteration fields
- Implementer-coordinator agent: Already supports continuation_context and iteration parameters

**New Systems**:
- command-init.sh: Sourced by all commands before library loading
- estimate_context_usage: Called before each iteration in /build
- save_resumption_checkpoint: Called when halting at context threshold

## Implementation Phases

### Phase 1: Centralized Library Initialization [NOT STARTED]
dependencies: []

**Objective**: Create command-init.sh to eliminate 60% of production errors (exit code 127 for missing library functions)

**Complexity**: Low

**Tasks**:
- [ ] Create `.claude/lib/core/command-init.sh` with library sourcing logic
  - Source error-handling.sh, state-persistence.sh, workflow-state-machine.sh, checkpoint-utils.sh
  - Validate each critical function is defined: log_command_error, save_json_checkpoint, sm_transition, load_checkpoint
  - Export CLAUDE_PROJECT_DIR and CLAUDE_LIB environment variables
  - Provide actionable error messages if library missing or function undefined
- [ ] Update `.claude/commands/build.md` to source command-init.sh (replace lines 77-81)
- [ ] Update `.claude/commands/plan.md` to source command-init.sh
- [ ] Update `.claude/commands/debug.md` to source command-init.sh
- [ ] Update `.claude/commands/repair.md` to source command-init.sh
- [ ] Update `.claude/commands/revise.md` to source command-init.sh
- [ ] Add library sourcing error recovery (exit with code 1 if critical function missing)

**Testing**:
```bash
# Test: command-init.sh sources all libraries successfully
source .claude/lib/core/command-init.sh
[[ $(type -t log_command_error) == "function" ]] || echo "FAIL: log_command_error not defined"
[[ $(type -t save_json_checkpoint) == "function" ]] || echo "FAIL: save_json_checkpoint not defined"
[[ $(type -t sm_transition) == "function" ]] || echo "FAIL: sm_transition not defined"

# Test: All commands source command-init successfully
for cmd in build plan debug repair revise; do
  grep -q "source.*command-init.sh" .claude/commands/${cmd}.md || echo "FAIL: $cmd missing command-init"
done

# Validation: Zero exit code 127 errors in production use (24 hour window)
# Monitor .claude/data/logs/errors.jsonl for exit_code: 127
```

**Expected Duration**: 2 hours

### Phase 2: Exit Code Capture Pattern Audit [NOT STARTED]
dependencies: []

**Objective**: Replace all bash history expansion patterns (`if ! command`) with exit code capture pattern to prevent preprocessing errors

**Complexity**: Low

**Tasks**:
- [ ] Audit `.claude/commands/plan.md` for `if ! ` patterns (replace with exit code capture)
- [ ] Audit `.claude/commands/debug.md` for `if ! ` patterns (replace with exit code capture)
- [ ] Audit `.claude/commands/repair.md` for `if ! ` patterns (replace with exit code capture)
- [ ] Audit `.claude/commands/revise.md` for `if ! ` patterns (replace with exit code capture)
- [ ] Document exit code capture pattern in code standards (if not already present)

**Pattern Replacement**:
```bash
# OLD (bash history expansion - can fail in preprocessing):
if ! grep -q "pattern" file.txt; then
  echo "Pattern not found"
fi

# NEW (exit code capture - always safe):
grep -q "pattern" file.txt
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "Pattern not found"
fi
```

**Testing**:
```bash
# Test: No `if ! ` patterns in commands
grep -r "if ! " .claude/commands/*.md && echo "FAIL: Found if ! patterns"

# Validation: No bash history expansion errors in command execution
# Run all commands with set -o pipefail and verify no errors
```

**Expected Duration**: 1 hour

### Phase 3: Test Script Validation [NOT STARTED]
dependencies: []

**Objective**: Ensure all test scripts are executable with proper shebangs and TEST_MODE integration

**Complexity**: Low

**Tasks**:
- [ ] chmod +x for 3 scripts lacking execute permissions (identify with `find .claude/tests -name "*.sh" ! -perm -u+x`)
- [ ] Audit shebangs across all `.claude/tests/*.sh` files (ensure `#!/usr/bin/env bash`)
- [ ] Add `export CLAUDE_TEST_MODE=1` to all test scripts (if not already present)
- [ ] Create validate_test_script() function in `run_all_tests.sh` (checks shebang, permissions, TEST_MODE export)
- [ ] Call validate_test_script() before executing each test

**Testing**:
```bash
# Test: All test scripts executable
find .claude/tests -name "*.sh" ! -perm -u+x && echo "FAIL: Non-executable scripts found"

# Test: All test scripts have proper shebangs
for script in .claude/tests/*.sh; do
  head -n1 "$script" | grep -q "#!/usr/bin/env bash" || echo "FAIL: $script missing shebang"
done

# Test: run_all_tests.sh executes without permission errors
cd .claude/tests && ./run_all_tests.sh 2>&1 | grep -i "permission denied" && echo "FAIL: Permission errors"

# Validation: CLAUDE_TEST_MODE detected in error logs from test runs
```

**Expected Duration**: 0.5 hours

### Phase 4: Topic Naming Agent Diagnostics [NOT STARTED]
dependencies: []

**Objective**: Add diagnostic logging to topic naming agent to reduce 20% failure rate and improve debugging

**Complexity**: Medium

**Tasks**:
- [ ] Identify topic naming agent invocation in `.claude/commands/plan.md` (or relevant command)
- [ ] Add pre-validation logging before agent invocation (log input prompt, expected output path)
- [ ] Add 30-second timeout to agent invocation using Task tool timeout parameter
- [ ] Capture stderr from agent execution (redirect to temp file for diagnostics)
- [ ] Add post-validation logging after agent returns (log success/failure, output file existence, fallback reason)
- [ ] Log diagnostic info using log_command_error with error_type="agent_error" on failure
- [ ] Include stderr content in error context JSON

**Testing**:
```bash
# Test: Agent failure logs diagnostic info
# Trigger agent failure (corrupt prompt or agent file)
# Verify error log contains:
# - Input prompt hash
# - Expected output path
# - Actual stderr content
# - Fallback reason (timeout, no_output_file, invalid_name)

# Validation: Next agent failure has actionable diagnostic in errors.jsonl
```

**Expected Duration**: 1.5 hours

### Phase 5: /build Iteration Loop [NOT STARTED]
dependencies: [1]

**Objective**: Transform /build from single-shot to persistent iteration loop supporting large plans (40+ phases)

**Complexity**: High

**Tasks**:
- [ ] Add MAX_ITERATIONS variable to `.claude/commands/build.md` (default 5, configurable via --max-iterations flag)
- [ ] Add ITERATION counter initialization (ITERATION=1) before Block 1
- [ ] Add CONTINUATION_CONTEXT variable (null for first iteration, set from previous summary for subsequent)
- [ ] Wrap existing implementer-coordinator invocation (Block 1) in while loop: `while [ $ITERATION -le $MAX_ITERATIONS ]; do`
- [ ] Parse work_remaining from agent output JSON (extract incomplete phases list)
- [ ] Add completion exit condition: `if [ -z "$work_remaining" ]; then exit 0; fi`
- [ ] Add stuck detection: compare work_remaining to last_work_remaining, exit error if unchanged
- [ ] Set CONTINUATION_CONTEXT to previous iteration summary path before next iteration
- [ ] Increment ITERATION counter: `ITERATION=$((ITERATION + 1))`
- [ ] Close while loop with done statement
- [ ] Pass continuation_context and iteration parameters to implementer-coordinator agent

**Implementation Pattern**:
```bash
# In build.md after argument parsing, before Block 1:

MAX_ITERATIONS="${MAX_ITERATIONS:-5}"
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "=== Iteration $ITERATION/$MAX_ITERATIONS ===" >&2

  # Block 1: Invoke implementer-coordinator with continuation
  # (existing Task invocation, add continuation_context: $CONTINUATION_CONTEXT, iteration: $ITERATION)

  # Parse work_remaining from agent output
  work_remaining=$(echo "$AGENT_OUTPUT" | jq -r '.work_remaining // [] | join(",")')

  # Check completion
  if [ -z "$work_remaining" ] || [ "$work_remaining" = "0" ]; then
    echo "✓ Implementation complete" >&2
    exit 0
  fi

  # Check stuck state
  if [ "$work_remaining" = "$LAST_WORK_REMAINING" ]; then
    echo "ERROR: Stuck - work_remaining unchanged between iterations" >&2
    log_command_error "execution_error" "Iteration stuck" "{\"iteration\": $ITERATION, \"work_remaining\": \"$work_remaining\"}"
    exit 1
  fi

  # Prepare for next iteration
  LAST_WORK_REMAINING="$work_remaining"
  CONTINUATION_CONTEXT="${BUILD_WORKSPACE}/iteration_${ITERATION}_summary.md"
  ITERATION=$((ITERATION + 1))
done

echo "ERROR: Max iterations ($MAX_ITERATIONS) exceeded" >&2
exit 1
```

**Testing**:
```bash
# Test: Small plan completes in 1 iteration
# Create 2-phase plan, verify ITERATION=1 and work_remaining=0

# Test: Medium plan completes in 2-3 iterations
# Create 8-phase plan, verify ITERATION=2 or 3 and work_remaining=0

# Test: Max iterations exceeded
# Create plan with 100 phases, verify exit code 1 after 5 iterations

# Validation: 12-phase plan completes successfully
```

**Expected Duration**: 4 hours

### Phase 6: Context Monitoring and Graceful Halt [NOT STARTED]
dependencies: [5]

**Objective**: Add context estimation heuristic and graceful halt at 90% threshold to prevent context overflow

**Complexity**: High

**Tasks**:
- [ ] Create estimate_context_usage() function in `.claude/commands/build.md`
  - Calculate base context: plan file size + standards file size
  - Add per-completed-phase estimate: 15000 tokens average
  - Add per-remaining-phase estimate: 12000 tokens average
  - Add continuation context: 5000 tokens if resuming from checkpoint
  - Return total estimated context usage
- [ ] Add CONTEXT_THRESHOLD variable (default 0.90, configurable via --context-threshold flag)
- [ ] Add MAX_CONTEXT constant (200000 tokens for Claude Sonnet)
- [ ] Check context before each iteration: `if [ $(estimate_context_usage) -ge $((MAX_CONTEXT * CONTEXT_THRESHOLD / 100)) ]; then`
- [ ] Create save_resumption_checkpoint() function
  - Generate checkpoint v2.1 with iteration state (see Checkpoint v2.1 Schema)
  - Save to `.claude/tmp/checkpoints/build_${WORKFLOW_ID}_iteration_${ITERATION}.json`
  - Use atomic write pattern from state-persistence.sh
- [ ] Call save_resumption_checkpoint() on context threshold halt
- [ ] Log halt event with log_command_error (error_type="execution_error", message="Context threshold halt")
- [ ] Exit with code 0 and display resumption instructions

**Context Estimation Formula**:
```bash
estimate_context_usage() {
  local plan_path="$1"
  local completed_phases="$2"
  local remaining_phases="$3"
  local continuation_context="$4"

  local base=20000  # Plan file + standards + system prompt
  local completed_cost=$((completed_phases * 15000))
  local remaining_cost=$((remaining_phases * 12000))
  local continuation_cost=0

  if [ -n "$continuation_context" ] && [ -f "$continuation_context" ]; then
    continuation_cost=5000
  fi

  echo $((base + completed_cost + remaining_cost + continuation_cost))
}
```

**Testing**:
```bash
# Test: Context estimation accuracy
# Run estimate_context_usage on 10 plans with known context usage
# Verify estimate error is <15% (target ±12000 tokens)

# Test: Graceful halt at 90% threshold
# Create large plan (30+ phases) with estimated context >180k
# Verify halt occurs before context overflow
# Verify checkpoint v2.1 created with iteration state

# Test: Resumption from checkpoint
# Load checkpoint, verify iteration and continuation_context restored
# Verify next iteration continues from correct phase

# Validation: Large plan halts at 90%, creates resumption checkpoint
```

**Expected Duration**: 3 hours

### Phase 7: Checkpoint v2.1 and Stuck Detection [NOT STARTED]
dependencies: [5, 6]

**Objective**: Extend checkpoint schema to v2.1 with iteration tracking and add robust stuck state detection

**Complexity**: Medium

**Tasks**:
- [ ] Update checkpoint schema in `.claude/lib/workflow/checkpoint-utils.sh` to v2.1
  - Add iteration field (current iteration number)
  - Add max_iterations field (configured limit)
  - Add continuation_context field (path to previous summary)
  - Add work_remaining field (list of incomplete phases)
  - Add last_work_remaining field (for stuck detection)
  - Add context_estimate field (current estimated context usage)
  - Add halt_reason field (context_threshold, max_iterations, stuck, error)
- [ ] Update save_checkpoint() to write v2.1 schema
- [ ] Update load_checkpoint() to read v2.1 schema (backward compatible with v2.0)
- [ ] Add validate_checkpoint() function
  - Check JSON schema validity (all required fields present)
  - Verify plan file exists at plan_path
  - Verify iteration count <= max_iterations
  - Verify continuation_context file exists if not null
  - Return validation errors if any check fails
- [ ] Add stuck detection logic to /build iteration loop
  - Compare work_remaining to last_work_remaining
  - If unchanged for 2 consecutive iterations, set halt_reason="stuck" and exit
  - Log stuck state with diagnostic info (which phases stuck, last agent output)
- [ ] Call validate_checkpoint() before resuming from checkpoint
- [ ] Handle checkpoint validation errors gracefully (fallback to plan file analysis)

**Checkpoint v2.1 Schema**:
```json
{
  "version": "2.1",
  "timestamp": "2025-11-20T12:34:56Z",
  "plan_path": "/home/benjamin/.config/.claude/specs/042_auth/plans/001_user_auth.md",
  "iteration": 3,
  "max_iterations": 5,
  "continuation_context": "/home/benjamin/.config/.claude/tmp/build_12345/iteration_2_summary.md",
  "work_remaining": ["phase_8", "phase_9", "phase_10"],
  "last_work_remaining": ["phase_8", "phase_9", "phase_10", "phase_11"],
  "context_estimate": 185000,
  "halt_reason": "context_threshold"
}
```

**Testing**:
```bash
# Test: Checkpoint v2.1 write/read round-trip
# Create checkpoint with all v2.1 fields, load, verify all fields match

# Test: Stuck detection triggers
# Mock agent output with unchanged work_remaining for 2 iterations
# Verify halt_reason="stuck" and exit code 1

# Test: Checkpoint validation catches corrupt files
# Create checkpoint with missing fields, invalid JSON, nonexistent plan_path
# Verify validate_checkpoint() returns errors

# Test: Backward compatibility with v2.0 checkpoints
# Load v2.0 checkpoint, verify graceful handling of missing v2.1 fields

# Validation: Stuck detection prevents infinite loops, checkpoint resumption works
```

**Expected Duration**: 2.5 hours

### Phase 8: State Transition Diagnostics [NOT STARTED]
dependencies: []

**Objective**: Enhance workflow-state-machine.sh with precondition validation and actionable error messages

**Complexity**: Low

**Tasks**:
- [ ] Add validate_state_transition() function to `.claude/lib/workflow/workflow-state-machine.sh`
  - Check current state matches expected state before transition
  - Validate requested transition is valid for current state
  - Return detailed error with resolution steps if validation fails
- [ ] Update sm_transition() to call validate_state_transition() before state change
- [ ] Add diagnostic output for invalid transitions
  - Show current state, requested state, valid next states
  - Provide resolution steps (e.g., "Run /build to complete implementation before testing")
- [ ] Add build test phase error context
  - If transition to TESTING fails, include which phase failed, test command used, error type
  - Extract from most recent error log entry
- [ ] Log validation errors with log_command_error (error_type="state_error")

**Validation Logic**:
```bash
validate_state_transition() {
  local current_state="$1"
  local next_state="$2"

  # Define valid transitions
  local valid_transitions=(
    "INIT->RESEARCHING"
    "RESEARCHING->PLANNING"
    "PLANNING->IMPLEMENTING"
    "IMPLEMENTING->TESTING"
    "TESTING->DOCUMENTING"
    "DOCUMENTING->COMPLETE"
  )

  local transition="${current_state}->${next_state}"

  if ! [[ " ${valid_transitions[@]} " =~ " ${transition} " ]]; then
    echo "ERROR: Invalid state transition: $transition" >&2
    echo "Current state: $current_state" >&2
    echo "Requested state: $next_state" >&2
    echo "Valid next states: $(get_valid_next_states "$current_state")" >&2
    echo "" >&2
    echo "Resolution: $(get_resolution_steps "$current_state" "$next_state")" >&2
    return 1
  fi

  return 0
}
```

**Testing**:
```bash
# Test: Valid transition succeeds
# sm_transition INIT RESEARCHING
# Verify no error output

# Test: Invalid transition shows diagnostic
# sm_transition INIT TESTING
# Verify error shows current state, requested state, valid next states, resolution steps

# Test: Build test failure includes phase context
# Trigger test failure in Phase 3
# Verify error includes "Phase 3", test command, error type

# Validation: Invalid transitions show actionable error messages with resolution steps
```

**Expected Duration**: 1.5 hours

### Phase 9: Documentation Updates [NOT STARTED]
dependencies: [5, 6, 7]

**Objective**: Document persistent workflow patterns, iteration behavior, and troubleshooting guidance

**Complexity**: Medium

**Tasks**:
- [ ] Add "Persistent Workflows" section to `.claude/docs/architecture/state-based-orchestration-overview.md` (180 lines)
  - Overview of iteration loop architecture
  - Context monitoring and graceful halt strategy
  - Checkpoint v2.1 schema and resumption protocol
  - Stuck detection logic and resolution
  - MAX_ITERATIONS configuration and tuning guidance
  - Parallel wave execution with iteration support
  - Performance characteristics (iteration 1 vs 2 timing)
- [ ] Add "Persistence Behavior" section to `.claude/docs/guides/commands/build-command-guide.md` (100 lines)
  - How /build detects incomplete plans
  - Iteration loop execution flow
  - Context threshold halt and resumption
  - Max iterations exceeded handling
  - Stuck state detection and recovery
  - Troubleshooting common iteration issues
- [ ] Add "Multi-Iteration Execution" examples to `.claude/agents/implementer-coordinator.md` (140 lines)
  - Iteration 1 (fresh start): continuation_context null, iteration 1
  - Iteration 2 (continuation): continuation_context set, iteration 2, work_remaining reduced
  - Iteration 3 (completion): work_remaining empty, final summary
  - Context monitoring example: halt at 90%, checkpoint created
  - Stuck detection example: work_remaining unchanged, error logged
- [ ] Add "Command Initialization Requirements" to `.claude/docs/guides/development/command-development-guide.md` (40 lines)
  - How to use command-init.sh in new commands
  - Critical functions to validate after sourcing
  - Error handling for library sourcing failures
  - Environment variable exports (CLAUDE_PROJECT_DIR, CLAUDE_LIB)
- [ ] Add "Test Mode Examples" to `.claude/docs/concepts/patterns/error-handling-pattern.md` (20 lines)
  - CLAUDE_TEST_MODE usage in test scripts
  - Environment detection logic in error-handling.sh
  - Test vs production error log separation

**Testing**:
```bash
# Test: All markdown syntax valid
markdownlint .claude/docs/architecture/state-based-orchestration-overview.md
markdownlint .claude/docs/guides/commands/build-command-guide.md
markdownlint .claude/agents/implementer-coordinator.md

# Test: All internal links work
# Extract all markdown links, verify target files exist

# Test: Code examples are syntactically correct
# Extract bash code blocks, run shellcheck

# Validation: Documentation covers all iteration features with examples
```

**Expected Duration**: 2.5 hours

### Phase 10: Comprehensive Testing and Validation [NOT STARTED]
dependencies: [1, 2, 3, 4, 5, 6, 7, 8, 9]

**Objective**: Ensure >90% test coverage for all new functionality with unit, integration, and E2E tests

**Complexity**: High

**Tasks**:
- [ ] Create unit tests for estimate_context_usage() (`.claude/tests/unit/test_context_estimation.sh`)
  - Test with varying plan sizes (2-phase, 10-phase, 30-phase)
  - Test with varying completion states (0%, 50%, 100%)
  - Test with and without continuation_context
  - Verify estimate error is <15% (compare to actual context usage)
- [ ] Create unit tests for validate_checkpoint() (`.claude/tests/unit/test_checkpoint_validation.sh`)
  - Test valid v2.1 checkpoint (all fields present)
  - Test v2.0 checkpoint (backward compatibility)
  - Test missing required fields (version, plan_path, iteration)
  - Test invalid JSON syntax
  - Test nonexistent plan_path
  - Test iteration > max_iterations
  - Test nonexistent continuation_context
- [ ] Create unit tests for stuck detection logic (`.claude/tests/unit/test_stuck_detection.sh`)
  - Test work_remaining unchanged for 2 iterations (should trigger stuck)
  - Test work_remaining reduced each iteration (should not trigger stuck)
  - Test work_remaining empty (should exit success)
- [ ] Create integration tests for iteration loop (`.claude/tests/integration/test_build_iteration.sh`)
  - Test 1-iteration plan (4 phases, completes in single iteration)
  - Test 2-iteration plan (8 phases, completes in 2 iterations)
  - Test 3-iteration plan (12 phases, completes in 3 iterations)
  - Test context halt (30-phase plan, halts at 90%, creates checkpoint)
  - Test max iterations exceeded (100-phase plan, exits after 5 iterations)
  - Test stuck detection (mock agent with unchanged work_remaining)
  - Test resumption from checkpoint (load checkpoint, continue from iteration 2)
- [ ] Create E2E tests with real plans (`.claude/tests/e2e/test_build_e2e.sh`)
  - Test small plan: 4 phases, simple feature, should complete in 1 iteration
  - Test large plan: 22 phases, complex feature, should complete in 3-4 iterations or halt
  - Verify checkpoint created on halt
  - Verify resumption works correctly
- [ ] Create performance validation tests (`.claude/tests/performance/test_iteration_timing.sh`)
  - Measure iteration 1 timing (baseline)
  - Measure iteration 2 timing (with continuation_context)
  - Verify iteration 2 is 10-20% faster (cached context)
  - Measure context estimation accuracy across 10 plans (target ±15%)
- [ ] Create regression tests for exit code patterns (`.claude/tests/regression/test_exit_codes.sh`)
  - Verify no `if ! ` patterns in commands
  - Verify all commands use exit code capture
  - Test commands execute without bash history expansion errors
- [ ] Update run_all_tests.sh to include all new test suites
  - Add unit tests section
  - Add integration tests section
  - Add E2E tests section
  - Add performance tests section
  - Add regression tests section
  - Calculate and display total coverage percentage

**Test Coverage Targets**:
- Unit tests: >95% coverage for new functions
- Integration tests: All iteration scenarios (1-iter, 2-iter, halt, stuck, max exceeded)
- E2E tests: At least 2 real plans (small and large)
- Performance tests: Context estimation accuracy ±15%
- Regression tests: Zero `if ! ` patterns, zero exit code 127 errors

**Testing**:
```bash
# Run all test suites
cd .claude/tests && ./run_all_tests.sh

# Verify coverage >90%
# (run_all_tests.sh displays coverage at end)

# Manual validation tests:
# 1. Create real 22-phase plan (e.g., leader.ac command from Spec 859)
# 2. Run /build on plan
# 3. Verify completion or graceful halt with checkpoint
# 4. If halted, verify resumption works: /build --resume <checkpoint>
# 5. Monitor errors.jsonl for any exit code 127 errors (should be zero)

# Performance validation:
# 1. Run 10 plans of varying sizes (4, 8, 12, 16, 20, 24, 28, 32, 36, 40 phases)
# 2. Record actual context usage and estimated context usage
# 3. Calculate estimate error: abs(actual - estimated) / actual
# 4. Verify average error <15%
```

**Expected Duration**: 5 hours

## Testing Strategy

### Unit Testing
- **Target**: Individual functions (estimate_context_usage, validate_checkpoint, stuck detection)
- **Approach**: Isolated tests with mocked inputs and known outputs
- **Coverage Goal**: >95% line coverage for new functions
- **Tools**: Bash test framework with assertions, shellcheck for syntax validation

### Integration Testing
- **Target**: Iteration loop with real implementer-coordinator agent
- **Approach**: End-to-end scenarios with mocked plans (1-iter, 2-iter, halt, stuck, max exceeded)
- **Coverage Goal**: All iteration paths tested (success, halt, stuck, max iterations)
- **Tools**: Real /build command with test plans, checkpoint validation

### E2E Testing
- **Target**: Complete workflows with real plans from specs/
- **Approach**: Execute /build on small (4-phase) and large (22-phase) plans
- **Coverage Goal**: Real-world validation of iteration behavior
- **Tools**: Actual plans from specifications, manual verification of results

### Performance Testing
- **Target**: Context estimation accuracy and iteration timing
- **Approach**: Run 10 plans of varying sizes, measure context usage and timing
- **Coverage Goal**: Context estimate error <15%, iteration 2 faster than iteration 1
- **Tools**: Custom timing scripts, context measurement utilities

### Regression Testing
- **Target**: Prevent reintroduction of fixed bugs (bash history expansion, exit code 127 errors)
- **Approach**: Automated checks for `if ! ` patterns, library sourcing failures
- **Coverage Goal**: Zero instances of known anti-patterns
- **Tools**: grep/ripgrep for pattern detection, error log monitoring

### Test Execution Flow
1. **Pre-commit**: Run unit tests (fast, <30s)
2. **Daily**: Run integration tests (medium, 2-5 min)
3. **Weekly**: Run E2E and performance tests (slow, 15-30 min)
4. **Release**: Full test suite including manual validation (1-2 hours)

## Documentation Requirements

### New Documentation
- **state-based-orchestration-overview.md**: "Persistent Workflows" section (180 lines)
- **build-command-guide.md**: "Persistence Behavior" section (100 lines)
- **implementer-coordinator.md**: "Multi-Iteration Execution" examples (140 lines)
- **command-development-guide.md**: "Command Initialization Requirements" (40 lines)
- **error-handling-pattern.md**: "Test Mode Examples" (20 lines)

**Total New Documentation**: 480 lines

### Updated Documentation
- **command-init.sh**: Inline documentation for library sourcing and validation
- **checkpoint-utils.sh**: Update schema documentation to v2.1
- **workflow-state-machine.sh**: Document validation logic and error messages
- **build.md**: Comment iteration loop logic and context monitoring

### Cross-References to Add
- Persistent Workflows → checkpoint-recovery.md (resumption protocol)
- Build guide → state-based-orchestration-overview.md (architecture context)
- Implementer-coordinator → build-command-guide.md (orchestration patterns)
- Command-init → error-handling-pattern.md (library sourcing errors)

## Dependencies

### External Dependencies
None - all work is internal to .claude/ system

### Internal Dependencies
- **Existing Libraries**: error-handling.sh (v1.0+), state-persistence.sh (v1.5.0+), workflow-state-machine.sh (v2.0+), checkpoint-utils.sh (v2.0+)
- **Existing Agents**: implementer-coordinator.md (supports continuation_context and iteration parameters)
- **Existing Commands**: /build (modified for iteration loop), /plan (modified for command-init)
- **Existing Utilities**: Task tool (for agent invocation with timeout), jq (for JSON parsing)

### Phase Dependencies
- Phase 5 depends on Phase 1 (iteration loop needs command-init for library sourcing)
- Phase 6 depends on Phase 5 (context monitoring needs iteration loop)
- Phase 7 depends on Phases 5, 6 (checkpoint v2.1 needs loop + context monitoring)
- Phase 9 depends on Phases 5-7 (documentation requires iteration features complete)
- Phase 10 depends on all phases (testing validates all features)

**Parallel Execution Waves**:
- Wave 1 (parallel): Phases 1, 2, 3, 4, 8 (5 phases, ~7.5 hours)
- Wave 2 (sequential): Phase 5 (4 hours)
- Wave 3 (sequential): Phase 6 (3 hours)
- Wave 4 (sequential): Phase 7 (2.5 hours)
- Wave 5 (sequential): Phase 9 (2.5 hours)
- Wave 6 (sequential): Phase 10 (5 hours)

**Total Time with Parallelization**: ~24.5 hours (vs 23.5 sequential)

## Risk Analysis

### Risk 1: command-init.sh Breaks Existing Commands
- **Likelihood**: Medium
- **Impact**: High (all commands fail to execute)
- **Mitigation**:
  - Implement backward-compatible sourcing (check if command-init exists, fallback to direct sourcing)
  - Test each command individually after command-init integration
  - Keep direct sourcing as fallback for 1 release cycle
  - Add validation tests before merging
- **Rollback**: Revert command-init changes, restore direct sourcing in all commands

### Risk 2: Iteration Loop Introduces Infinite Loop
- **Likelihood**: Low (MAX_ITERATIONS and stuck detection prevent this)
- **Impact**: High (/build workflow hangs indefinitely, blocks user)
- **Mitigation**:
  - Implement MAX_ITERATIONS hard limit (default 5)
  - Add stuck detection (work_remaining unchanged for 2 iterations)
  - Add per-iteration timeout (2 hours via Task tool)
  - Test with blocking scenario before production deployment
- **Rollback**: Revert /build to single invocation, disable iteration loop

### Risk 3: Context Estimation Inaccurate
- **Likelihood**: High (heuristic-based, not actual measurement)
- **Impact**: Medium (premature halt or context overflow)
- **Mitigation**:
  - Use conservative 90% threshold (10% safety margin)
  - Allow user override via --context-threshold flag
  - Document expected accuracy (±15%) in build-command-guide.md
  - Include calibration tests in Phase 10 (measure actual vs estimated across 10 plans)
  - Adjust heuristic coefficients if average error >15%
- **Rollback**: Disable context monitoring, rely on MAX_ITERATIONS only

### Risk 4: Checkpoint Corruption
- **Likelihood**: Low (atomic writes prevent most corruption)
- **Impact**: Medium (resumption fails, user must restart from beginning)
- **Mitigation**:
  - Use atomic write pattern (temp file + mv) per state-persistence.sh
  - Validate checkpoint schema on load with validate_checkpoint()
  - Fallback to plan file analysis if checkpoint invalid
  - Keep backup checkpoints (last 3 iterations) for recovery
  - Add checkpoint integrity checks (JSON syntax, required fields)
- **Rollback**: Delete corrupt checkpoint, /build auto-detects most recent complete plan state

### Risk 5: Test Coverage Gaps
- **Likelihood**: Medium (comprehensive testing is time-intensive)
- **Impact**: Low (bugs may slip through but are catchable in production)
- **Mitigation**:
  - Prioritize high-risk areas: iteration loop, stuck detection, context monitoring
  - Include E2E tests with real plans from specs/ (not just synthetic tests)
  - Manual validation with 22-phase plan before release
  - Monitor error logs in production for 1 week after deployment
- **Rollback**: Revert specific phases if bugs detected, not entire plan

## Implementation Timeline

### Priority 1: Fix Production Errors (Immediate - 2 hours)
**Goal**: Eliminate 60% of current production errors (exit code 127 for missing functions)

**Phases**: Phase 1 only

**Rationale**: Recent error logs show 6/10 errors are library sourcing failures blocking production workflows (/build, /plan, /debug)

**Deliverable**: command-init.sh with function validation, all commands updated to use it

**Success Metric**: Zero exit code 127 errors in next 24 hours of production use

### Priority 2: Complete Iteration Infrastructure (Next - 9.5 hours)
**Goal**: Enable /build to handle large plans (40+ phases)

**Phases**: Phases 5-7

**Rationale**: Highest-value feature, unblocks large implementation plans that currently fail due to context limits

**Deliverable**: /build iteration loop, context monitoring, checkpoint v2.1, stuck detection

**Success Metric**:
- 12-phase plan completes in 2-3 iterations
- 30-phase plan halts at 90% context, creates resumption checkpoint
- Stuck detection prevents infinite loops

### Priority 3: Polish and Documentation (Final - 12 hours)
**Goal**: Production-ready release with comprehensive docs and tests

**Phases**: Phases 2-4, 8-10

**Rationale**: Ensures long-term maintainability, user understanding, and prevents regression

**Deliverable**: Exit code pattern compliance, test script validation, agent diagnostics, state diagnostics, comprehensive documentation, >90% test coverage

**Success Metric**:
- All test suites pass with >90% coverage
- All documentation updated with iteration patterns and examples
- No bash preprocessing errors in commands
- All test scripts executable with proper shebangs

### Suggested Timeline

**Week 1: Priority 1 + Priority 2**
- **Monday**: Phase 1 (command-init.sh) - 2 hours
- **Monday-Tuesday**: Phase 5 (iteration loop) - 4 hours
- **Wednesday**: Phase 6 (context monitoring) - 3 hours
- **Thursday**: Phase 7 (checkpoint + stuck detection) - 2.5 hours
- **Friday**: Buffer + manual testing with real plans

**Week 2: Priority 3**
- **Monday**: Phases 2, 3, 4 (exit code, tests, agent) - 3 hours
- **Tuesday**: Phase 8 (state diagnostics) - 1.5 hours
- **Wednesday**: Phase 9 (documentation) - 2.5 hours
- **Thursday-Friday**: Phase 10 (comprehensive testing) - 5 hours

**Total Duration**: 10 working days (2 weeks)

### Alternative: Minimal Viable Implementation (1 week)

If time-constrained, implement only critical phases:
- **Phase 1**: command-init.sh (fixes production errors) - 2 hours
- **Phase 5**: Iteration loop (core feature) - 4 hours
- **Phase 6**: Context monitoring (safety) - 3 hours
- **Phase 10**: Basic testing (validation) - 4.5 hours (reduced scope)

**Total**: 13.5 hours (~4-5 days)

**Trade-offs**: Skip stuck detection, diagnostics, comprehensive docs, comprehensive tests (can add later)

## Maintenance and Monitoring

### Post-Deployment Monitoring (First Week)
- **Error Logs**: Monitor `.claude/data/logs/errors.jsonl` for new error types
- **Iteration Success Rate**: Track percentage of plans completing vs halting vs stuck
- **Context Estimation Accuracy**: Measure actual vs estimated context usage across all builds
- **Checkpoint Resumption**: Verify resumption success rate (target >95%)

### Long-Term Maintenance
- **Checkpoint Schema Versioning**: Plan for future v2.2, v2.3 with backward compatibility
- **Context Estimation Calibration**: Quarterly review of estimation accuracy, adjust coefficients if needed
- **Library Version Management**: Track command-init.sh compatibility with library versions
- **Documentation Updates**: Update examples as iteration patterns evolve

### Success Metrics Dashboard
- Exit code 127 error rate: Target <1% (currently 60%)
- Plan completion rate: Target >90% (currently unknown)
- Context overflow incidents: Target 0 (currently unknown)
- Stuck state detections: Track frequency, analyze root causes
- Average iterations per plan: Monitor trend over time (should stabilize at 2-3)

## Conclusion

This unified plan combines the best of Plans 871 and 881 while removing 40% of obsolete work (4.5 hours saved). The implementation is sequenced by impact: fix production errors immediately (Priority 1), enable large plan support next (Priority 2), then polish and document (Priority 3).

**Expected Outcomes**:
1. **Reliability**: Production error rate drops from 60% (exit code 127) to near-zero
2. **Scalability**: /build handles plans up to 40 phases (vs current limit of ~10)
3. **Usability**: Comprehensive documentation enables user self-service
4. **Quality**: >90% test coverage ensures long-term maintainability

**Key Success Factors**:
- Phase 1 (command-init.sh) is foundational - must be implemented correctly
- Context estimation accuracy is critical - calibration testing in Phase 10 is essential
- Stuck detection prevents infinite loops - testing must cover edge cases
- Documentation must include real examples - synthetic examples are insufficient

**Next Steps**:
1. Begin with Priority 1 (Phase 1) to fix production errors immediately
2. Execute Priority 2 (Phases 5-7) in Week 1 to enable iteration infrastructure
3. Complete Priority 3 (Phases 2-4, 8-10) in Week 2 for production readiness
4. Validate with real 22-phase plan (e.g., from Spec 859) before final release
