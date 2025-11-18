# State Machine Persistence Bug Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: State machine persistence bug where STATE_FILE and CURRENT_STATE are not properly persisted across bash subprocess boundaries in /build command
- **Report Type**: codebase analysis

## Executive Summary

The state machine persistence bug in /build command is caused by two interrelated issues: (1) Part 4 of build.md fails to call `load_workflow_state()` before attempting state transitions, leaving STATE_FILE undefined, and (2) `sm_transition()` in workflow-state-machine.sh updates CURRENT_STATE in memory but does not persist it to the state file. This causes subsequent Parts to read stale state ("initialize") when attempting transitions, resulting in "Invalid transition: initialize -> test" errors even though the in-memory state was correctly updated to "implement".

## Findings

### Root Cause Analysis

#### Bug 1: Missing load_workflow_state() in Part 4 (build.md:281-340)

**Location**: `/home/benjamin/.config/.claude/commands/build.md` lines 281-340

**Problem**: Part 4 (Implementation Phase) sources the state-persistence.sh library but never calls `load_workflow_state()` to restore the STATE_FILE variable from the workflow state file. This means:

- STATE_FILE remains undefined in this bash subprocess
- When `sm_transition()` calls `save_completed_states_to_state()` (line 645-647 of workflow-state-machine.sh), which internally calls `append_workflow_state()` (line 148-149), the function fails with "ERROR: STATE_FILE not set" (state-persistence.sh:326)

**Evidence from build-output.md (line 37)**:
```
ERROR: STATE_FILE not set. Call init_workflow_state first.
```

**Comparison to working Parts**:
- Part 5 (line 522): `load_workflow_state "$WORKFLOW_ID" false`
- Part 6 (line 651): `load_workflow_state "$WORKFLOW_ID" false`
- Part 7 (line 897): `load_workflow_state "$WORKFLOW_ID" false`

Part 4 is missing this critical call.

#### Bug 2: CURRENT_STATE Not Persisted in sm_transition() (workflow-state-machine.sh:625)

**Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` lines 603-651

**Problem**: The `sm_transition()` function updates CURRENT_STATE in memory (line 625) but does not persist it to the state file via `append_workflow_state()`.

**Code Analysis**:
```bash
# Line 625 - Updates in-memory variable
CURRENT_STATE="$next_state"

# Lines 643-647 - Only saves COMPLETED_STATES, NOT CURRENT_STATE
if command -v save_completed_states_to_state &> /dev/null; then
  save_completed_states_to_state || true  # Non-critical, continue on failure
fi
```

**Contrast with sm_init()** (lines 497-503):
```bash
# sm_init correctly persists both TERMINAL_STATE and CURRENT_STATE
if command -v append_workflow_state &> /dev/null; then
  append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
  append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"  # Line 500
```

The `sm_transition()` function should follow the same pattern but does not.

### Impact Analysis

The combined effect of these two bugs is:

1. **Part 3 (sm_init)**: Correctly initializes state machine and persists CURRENT_STATE="initialize" to state file
2. **Part 4 (first sm_transition)**:
   - Never loads workflow state (STATE_FILE undefined)
   - Calls `sm_transition("implement")` - succeeds in memory
   - CURRENT_STATE becomes "implement" in memory
   - `save_completed_states_to_state()` fails due to undefined STATE_FILE
   - CURRENT_STATE="implement" is NOT written to state file
3. **Part 5 (second sm_transition)**:
   - Calls `load_workflow_state()` correctly
   - Loads stale CURRENT_STATE="initialize" from state file
   - Attempts `sm_transition("test")`
   - Fails because "initialize" -> "test" is invalid (valid: research, implement)

**Evidence from build-output.md (lines 68-69)**:
```
ERROR: Invalid transition: initialize → test
Valid transitions from initialize: research,implement
```

### Subprocess Isolation Pattern

The /build command uses bash subprocesses that cannot share state via shell variables. The design pattern is:

1. **init_workflow_state()**: Creates state file at `.claude/tmp/workflow_${WORKFLOW_ID}.sh`
2. **load_workflow_state()**: Sources state file to restore exported variables
3. **append_workflow_state()**: Appends new export statements to state file

Each Part (bash block) is a separate subprocess that must:
1. Detect CLAUDE_PROJECT_DIR (each subprocess does this)
2. Source library files
3. Load WORKFLOW_ID from `${HOME}/.claude/tmp/build_state_id.txt`
4. Call `load_workflow_state()` to restore STATE_FILE and other variables
5. Perform operations
6. Persist any state changes

### State File Contents Analysis

When `init_workflow_state()` creates the state file, it contains:
```bash
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
export WORKFLOW_ID="build_1763450960"
export STATE_FILE="/home/benjamin/.config/.claude/tmp/workflow_build_1763450960.sh"
```

After `sm_init()`, these are appended:
```bash
export WORKFLOW_SCOPE="full-implementation"
export RESEARCH_COMPLEXITY="1"
export RESEARCH_TOPICS_JSON="[]"
export TERMINAL_STATE="complete"
export CURRENT_STATE="initialize"
```

When Part 4 calls `sm_transition("implement")` but fails to persist, the state file still shows:
```bash
export CURRENT_STATE="initialize"  # Stale!
```

## Recommendations

### Recommendation 1: Add load_workflow_state() to Part 4

**Priority**: Critical

Add the missing workflow state loading to Part 4 immediately after sourcing libraries:

```bash
# At line 307 in build.md, after sourcing libraries:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# ADD THESE LINES:
# Load WORKFLOW_ID from file (fail-fast pattern)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Load workflow state (critical for STATE_FILE and CURRENT_STATE)
load_workflow_state "$WORKFLOW_ID" false
```

### Recommendation 2: Add CURRENT_STATE Persistence to sm_transition()

**Priority**: Critical

Modify `sm_transition()` in workflow-state-machine.sh to persist CURRENT_STATE after updating it:

```bash
# At line 625 in workflow-state-machine.sh, after updating CURRENT_STATE:
CURRENT_STATE="$next_state"

# ADD THESE LINES:
# Persist CURRENT_STATE to state file (following sm_init pattern)
if command -v append_workflow_state &> /dev/null; then
  append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
fi
```

This should be added after line 625 and before the completed states history update (line 627).

### Recommendation 3: Add Diagnostic Output for State Loading Failures

**Priority**: Medium

Enhance `load_workflow_state()` to provide better diagnostics when the state file is missing or incomplete:

```bash
# In load_workflow_state(), after sourcing state file:
if [ -z "${STATE_FILE:-}" ]; then
  echo "WARNING: STATE_FILE not restored from state file" >&2
  echo "  State file: $state_file" >&2
  echo "  Contents:" >&2
  cat "$state_file" >&2
fi
```

### Recommendation 4: Add State Validation Guard in sm_transition()

**Priority**: Medium

Add fail-fast validation in `sm_transition()` before attempting the transition:

```bash
# At the beginning of sm_transition():
sm_transition() {
  local next_state="$1"

  # ADD THESE LINES:
  # Fail-fast if STATE_FILE not loaded
  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR: STATE_FILE not set in sm_transition()" >&2
    echo "DIAGNOSTIC: Call load_workflow_state() before sm_transition()" >&2
    return 1
  fi

  # ... rest of function
}
```

### Recommendation 5: Create Comprehensive Test for State Persistence

**Priority**: Low

Create a test in `.claude/tests/` that validates the complete state persistence flow across multiple bash blocks:

1. Initialize workflow state
2. Call sm_init() and verify state file contains CURRENT_STATE
3. Simulate subprocess boundary (new bash block)
4. Load workflow state
5. Call sm_transition() and verify CURRENT_STATE updated in state file
6. Verify subsequent loads read correct CURRENT_STATE

## References

- `/home/benjamin/.config/.claude/lib/state-persistence.sh`:321-336 (append_workflow_state function with STATE_FILE check)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`:130-169 (init_workflow_state function)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`:212-296 (load_workflow_state function)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`:392-512 (sm_init function with CURRENT_STATE persistence at line 500)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`:603-651 (sm_transition function missing CURRENT_STATE persistence)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`:625 (CURRENT_STATE update without persistence)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`:643-647 (save_completed_states_to_state call)
- `/home/benjamin/.config/.claude/commands/build.md`:251 (init_workflow_state call in Part 3)
- `/home/benjamin/.config/.claude/commands/build.md`:281-340 (Part 4 missing load_workflow_state)
- `/home/benjamin/.config/.claude/commands/build.md`:522 (Part 5 correctly calls load_workflow_state)
- `/home/benjamin/.config/.claude/commands/build.md`:651 (Part 6 correctly calls load_workflow_state)
- `/home/benjamin/.config/.claude/commands/build.md`:897 (Part 7 correctly calls load_workflow_state)
- `/home/benjamin/.config/.claude/build-output.md`:37 (STATE_FILE not set error)
- `/home/benjamin/.config/.claude/build-output.md`:68-69 (Invalid transition error)

## Implementation Status
- **Status**: Plan Revised
- **Plan**: [../plans/001_state_machine_persistence_fix_plan.md](../plans/001_state_machine_persistence_fix_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
- **Note**: Plan revised to include fixes for debug.md and revise.md in addition to build.md
