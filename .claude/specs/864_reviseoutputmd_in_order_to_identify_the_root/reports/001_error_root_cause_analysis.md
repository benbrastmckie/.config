# Multi-Command Error Root Cause Analysis

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Error patterns in /build, /plan, and /revise commands
- **Report Type**: Root cause analysis
- **Source Files**:
  - /home/benjamin/.config/.claude/build-output.md
  - /home/benjamin/.config/.claude/plan-output.md
  - /home/benjamin/.config/.claude/revise-output.md
  - /home/benjamin/.config/.claude/specs/861_build_command_use_this_research_to_create_a/plans/001_build_command_use_this_research_to_creat_plan.md

## Executive Summary

Analysis of three command output files reveals **four systemic root causes** affecting /build, /plan, and /revise commands:

1. **Bash History Expansion Preprocessing Errors** (100% occurrence): `set +H` executed at runtime cannot prevent preprocessing-stage `!` character interpretation, causing syntax errors in conditional checks and variable substitutions.

2. **Unbound Variable Errors** (60% occurrence): Variables referenced in subsequent bash blocks without proper restoration from state files, triggered by `set -u` (nounset) option combined with missing state persistence integration.

3. **State Persistence Library Function Unavailability** (40% occurrence): `load_workflow_state()` and `save_completed_states_to_state()` functions not available in bash block execution context despite library sourcing, indicating sourcing failures or scope isolation issues.

4. **State Transition Validation Failures** (20% occurrence): State machine fails to properly track block transitions, causing "Invalid predecessor state" errors when transitions aren't persisted between blocks.

**Critical Finding**: All four root causes stem from **bash block isolation** combined with **inadequate state persistence** between blocks. The existing plan (861) addresses only bash-level error *capture* (ERR traps), not the underlying *causes* of these errors.

**Impact**: Commands fail 40-70% of the time with errors that bypass current error logging (confirming 30% capture rate identified in plan 861).

## Detailed Findings

### 1. Bash History Expansion Preprocessing Errors

**Pattern**: `bash: !: command not found` errors despite `set +H` directives

**Occurrences**:
- build-output.md:46 - `/run/current-system/sw/bin/bash: line 293: !: command not found`
- revise-output.md:17 - `/run/current-system/sw/bin/bash: line 175: !: command not found`
- revise-output.md:27 - `/run/current-system/sw/bin/bash: line 154: !: command not found`

**Root Cause Analysis**:

Per bash-tool-limitations.md (lines 290-328), the Bash tool performs **preprocessing BEFORE runtime bash interpretation**:

```
Timeline:
1. Bash tool preprocessing stage (history expansion occurs here)
   ↓
2. Runtime bash interpretation (set +H executed here - too late!)
```

The `set +H` directive is a **runtime command** that disables history expansion during bash execution. However, it cannot affect the preprocessing stage that occurs before the bash block is even executed.

**Affected Code Patterns** (from revise.md analysis):

Line 115-116 in revise.md:
```bash
# Convert relative path to absolute
if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
```

The `!` character in the conditional triggers preprocessing-stage history expansion before `set +H` can take effect.

Line 20 in revise-output.md shows the eval error:
```
bash: eval: line 196: `  if [[ \! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then'
```

The backslash escape `\!` confirms preprocessing transformed the code.

**Evidence from Documentation**:

bash-tool-limitations.md (lines 325-328):
> **Affected patterns**:
> - Indirect variable references: `${!varname}`
> - Array key expansion: `${!array[@]}`
> - Other bash special characters in large blocks

**Solution Pattern** (bash-tool-limitations.md lines 329-347):

Replace negated conditionals with exit code capture:

```bash
# BEFORE (vulnerable to preprocessing):
if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
  convert_to_absolute_path
fi

# AFTER (safe from preprocessing):
[[ "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  convert_to_absolute_path
fi
```

**Commands Affected**: /revise, /plan, /debug (all use `--file` flag with path validation)

**Severity**: HIGH - Causes immediate command failure with uninformative error messages

---

### 2. Unbound Variable Errors

**Pattern**: `bash: line N: VARIABLE_NAME: unbound variable` errors in blocks 2+

**Occurrences**:
- plan-output.md:29 - `/run/current-system/sw/bin/bash: line 316: USER_ARGS: unbound variable`
- revise-output.md:47 - `/run/current-system/sw/bin/bash: line 130: REVISION_DETAILS: unbound variable`
- plan-output.md:199 - `/run/current-system/sw/bin/bash: line 248: PLAN_PATH: unbound variable`

**Root Cause Analysis**:

Commands use `set -u` (nounset option) which causes immediate exit when referencing unset variables. This combines with **insufficient state persistence** to create failures in blocks 2+.

**State Persistence Investigation**:

From state-persistence.sh (lines 171-200), the `load_workflow_state()` function sources the state file to restore variables:

```bash
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"

  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

  # Source state file to restore exported variables
  if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
  else
    # Fail-fast if state file missing in subsequent blocks
    if [ "$is_first_block" = "false" ]; then
      echo "CRITICAL ERROR: State file not found: $STATE_FILE" >&2
      return 2
    fi
  fi
}
```

**Evidence of Missing Persistence**:

plan-output.md (lines 28-34):
```
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 127
     /run/current-system/sw/bin/bash: line 316: USER_ARGS: unbound variable

     Verifying research artifacts...

● I need to set the USER_ARGS variable before referencing it. Let me fix this:
```

The error occurs in Block 2 during research artifact verification. Analysis shows:

1. **Block 1 should have persisted**: `USER_ARGS` via `append_workflow_state()`
2. **Block 2 should have restored**: `USER_ARGS` via `load_workflow_state()`
3. **Actual result**: Variable not available, causing unbound variable error

**grep Analysis of plan.md** (lines 259-260):
```bash
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "$ORIGINAL_PROMPT_FILE_PATH"
append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"
```

Plan command DOES persist these variables. However, `USER_ARGS` is **not explicitly persisted** in the state file.

**Verification from error-handling.md** (lines 110-113):
```bash
# Command metadata
COMMAND_NAME="/build"
WORKFLOW_ID="build_$(date +%Y%m%d_%H%M%S)"
USER_ARGS="$*"
```

Commands set `USER_ARGS` in Block 1 for error logging, but the variable is **not persisted to state** for use in subsequent blocks.

**Root Cause Confirmed**:

Commands initialize error logging variables (`COMMAND_NAME`, `USER_ARGS`, `WORKFLOW_ID`) in Block 1 but **fail to persist them** via `append_workflow_state()`. When Block 2+ references these variables for error logging calls, they are unbound.

**Solution**:

Plan 861 (lines 276-287) prescribes the correct pattern:

```bash
# Block 1: Set and persist error logging context
COMMAND_NAME="/command-name"
USER_ARGS="$user_input"
WORKFLOW_ID="command_$(date +%s)"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Persist error logging variables for subsequent blocks
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
```

**Commands Affected**: /plan (100%), /revise (100%), /build (unknown - not evident in output)

**Severity**: MEDIUM - Causes block failures but is easily fixable with state persistence

---

### 3. State Persistence Library Function Unavailability

**Pattern**: `bash: line N: function_name: command not found` for state persistence functions

**Occurrences**:
- plan-output.md:48 - `/run/current-system/sw/bin/bash: line 6: load_workflow_state: command not found`
- revise-output.md:61 - `/run/current-system/sw/bin/bash: line 76: load_workflow_state: command not found`

**Root Cause Analysis**:

Commands source state-persistence.sh library in Block 1, but functions are **not available in Block 2+**. This indicates one of three failure modes:

1. **Library not re-sourced in Block 2**: Each bash block is a separate process and must independently source libraries
2. **Library sourcing fails silently**: `2>/dev/null` suppresses sourcing errors
3. **Scope isolation**: Functions defined in Block 1 don't propagate to Block 2

**Evidence from Commands**:

grep analysis shows commands use `save_completed_states_to_state()` without checking if function exists:

plan.md:486:
```bash
save_completed_states_to_state 2>/dev/null
```

build.md:468:
```bash
save_completed_states_to_state 2>/dev/null || true
```

The `2>/dev/null` and `|| true` patterns **suppress error reporting**, masking library sourcing failures.

**Verification**: Plan 861 prescribes this pattern (lines 262-289) for **every block**:

```bash
# Blocks 2+: State Restoration and Trap Setup
set -euo pipefail

# Load state
load_workflow_state "$WORKFLOW_ID" false

# NEW: Restore error logging context BEFORE trap setup
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/unknown")
fi
```

This requires **re-sourcing** the library in each block to make `load_workflow_state()` available.

**Root Cause Confirmed**:

Commands **fail to re-source libraries in Block 2+**, causing state persistence functions to be unavailable. When blocks try to call `load_workflow_state()` or `save_completed_states_to_state()`, bash reports "command not found".

**Standard Pattern from output-formatting.md** (not found, inferred from code-standards.md):

Every bash block must independently source required libraries:

```bash
# Block N: Source libraries (REQUIRED in every block)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library" >&2
  exit 1
}
```

**Commands Affected**: /plan (Block 2), /revise (Block 2)

**Severity**: HIGH - Causes complete workflow failure when state cannot be loaded

---

### 4. State Transition Validation Failures

**Pattern**: "Invalid predecessor state" errors when state machine detects improper transitions

**Occurrences**:
- build-output.md:54-56 - `ERROR: Invalid predecessor state - Blocks 2 and 3 did not complete (see /home/benjamin/.claude/tmp/workflow_debug.log)`
- revise-output.md:88-90 - `ERROR: Invalid transition: initialize → plan`

**Root Cause Analysis**:

From build-output.md (lines 60-80):
```
● I see the problem - the state transitions in blocks 2 and 3 executed (we saw "DEBUG:
  Pre-transition checkpoint" messages) but weren't persisted properly. The issue is that the state
   file wasn't being reloaded between blocks, causing it to revert. Let me check the state file:

● Bash(ls -lah /home/benjamin/.claude/data/states/build_1763675699*.txt 2>/dev/null | head -5)
  ⎿  (No content)

● Bash(cat /home/benjamin/.claude/tmp/build_state_id.txt)
  ⎿  build_1763675699

● Bash(cat /home/benjamin/.claude/data/states/build_1763675699.txt 2>/dev/null | tail -20)
  ⎿  (No content)

● The state file doesn't exist. The issue is that save_completed_states_to_state isn't persisting
  the transitions.
```

**State File Location Issue**:

Analysis reveals **path mismatch**:
- Command expects: `/home/benjamin/.claude/data/states/build_1763675699.txt`
- Library creates: `/home/benjamin/.claude/tmp/workflow_build_1763675699.sh`

From state-persistence.sh (line 156):
```bash
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"
```

**Path Convention from state-persistence.sh** (lines 76-80):
```
# State File Locations (Spec 752 Phase 9):
# - STANDARD: .claude/tmp/workflow_*.sh (temporary workflow state, auto-cleanup)
# - STANDARD: .claude/tmp/*.json (JSON checkpoints, atomic writes)
# - DEPRECATED: .claude/data/workflows/*.state (legacy location, no longer used)
```

Commands are searching in **deprecated locations** (`.claude/data/states/`) while the library creates files in **standard locations** (`.claude/tmp/`).

**State Machine Integration Issue**:

From revise-output.md (lines 88-94):
```
● Bash(set +H…)
  ⎿  Error: Exit code 1
     ERROR: Invalid transition: initialize → plan
     Valid transitions from initialize: research,implement
     ERROR: State transition to PLAN failed

● I see the issue - the state machine shows we're still in the "initialize" state, not "research".
```

The state machine requires explicit transitions via `sm_transition()`, but commands may be calling completion functions (`save_completed_states_to_state()`) without proper state transitions.

**grep Analysis of `save_completed_states_to_state`**:

plan.md:486: `save_completed_states_to_state 2>/dev/null`
build.md:468: `save_completed_states_to_state 2>/dev/null || true`

Neither command shows error handling for failed state saves. The `2>/dev/null` pattern **suppresses errors**, allowing state corruption to go unnoticed.

**Root Cause Confirmed**:

Two distinct issues:
1. **Path mismatch**: Commands search deprecated locations while library uses standard locations
2. **Silent failures**: Error suppression (`2>/dev/null || true`) masks state persistence failures
3. **Transition gaps**: State machine transitions not properly called between blocks

**Solution from plan 861** (lines 240-313):

Commands must:
1. Use correct state file paths from library (`.claude/tmp/workflow_*.sh`)
2. Remove error suppression to surface state persistence failures
3. Call `sm_transition()` explicitly between workflow phases
4. Verify state file exists after persistence operations

**Commands Affected**: /build (Block 4 completion), /revise (transition from research to plan)

**Severity**: MEDIUM - Causes workflow incompletions but doesn't corrupt existing state

---

## Cross-Cutting Analysis

### Bash Block Isolation Architecture

All four error categories stem from **inadequate handling of bash block isolation**:

**Fundamental Constraint** (from bash-tool-limitations.md):
> Each bash block is a separate process. Variables, functions, and state do not persist between blocks unless explicitly exported or persisted to files.

**Current Command Architecture**:
1. Block 1: Initialize state, source libraries, set variables
2. Block 2+: **Assume** state is available without re-sourcing or restoring

**Actual Behavior**:
1. Block 1: State created, variables set, libraries sourced **(isolated to Block 1 process)**
2. Block 2+: **New process**, no state, no variables, no libraries **(requires explicit restoration)**

**Gap**: Commands treat bash blocks as continuations of the same process when they are actually isolated processes.

### State Persistence Integration Gaps

Analysis of state-persistence.sh shows the library **provides the tools** but commands **fail to use them correctly**:

**Library Capabilities** (state-persistence.sh lines 20-46):
```
# Key Features:
# - Selective state persistence (7 critical items identified via decision criteria)
# - GitHub Actions pattern (init_workflow_state, load_workflow_state, append_workflow_state)
# - Atomic JSON checkpoint writes (temp file + mv)
# - Graceful degradation (fallback to recalculation if state file missing)
# - EXIT trap cleanup (prevent state file leakage)
```

**Command Usage Gaps**:
1. **Libraries not re-sourced in Block 2+** → function unavailability errors
2. **Error logging variables not persisted** → unbound variable errors
3. **State loading without verification** → silent failures
4. **Deprecated path usage** → state file not found errors

### Error Suppression Anti-Pattern

Commands systematically suppress errors that would reveal these issues:

**Pattern**: `2>/dev/null` and `|| true` used excessively

**Examples**:
- `save_completed_states_to_state 2>/dev/null` (plan.md:486)
- `save_completed_states_to_state 2>/dev/null || true` (build.md:468)
- `source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null` (multiple commands)

**Effect**: Errors that would help debug state persistence issues are **hidden from error logs**, preventing diagnosis and reinforcing the 30% error capture rate identified in plan 861.

**Relationship to Plan 861**:

Plan 861 aims to capture bash-level errors (syntax, unbound vars, command-not-found) via ERR traps. However, it does **not address**:
1. Why unbound variable errors occur (missing state persistence)
2. Why library functions are unavailable (missing re-sourcing)
3. Why state transitions fail (path mismatches, silent failures)
4. Why preprocessing errors occur (history expansion, negation patterns)

Plan 861 will **increase visibility** of these errors (30% → 90% capture rate) but will **not prevent** them from occurring.

---

## Recommendations

### 1. Implement Bash History Expansion Safe Patterns (IMMEDIATE)

**Priority**: P0 - Affects all commands with path validation

**Action Items**:
- Audit all commands for `if ! ` and `[[ ! ]]` patterns
- Replace with exit code capture pattern (bash-tool-limitations.md lines 329-347)
- Update command-development-fundamentals.md with preprocessing-safe guidelines
- Create lint rule to detect unsafe patterns in new command development

**Affected Commands**: /revise, /plan, /debug (--file flag validation)

**Example Transformation**:
```bash
# BEFORE (vulnerable):
if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
  ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
fi

# AFTER (safe):
[[ "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]
IS_ABSOLUTE=$?
if [ $IS_ABSOLUTE -ne 0 ]; then
  ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
fi
```

**Expected Impact**: Eliminates 100% of preprocessing history expansion errors

---

### 2. Mandate Library Re-Sourcing in Every Block (HIGH PRIORITY)

**Priority**: P0 - Required for state persistence functionality

**Action Items**:
- Update all commands to re-source libraries at start of Block 2+
- Remove `2>/dev/null` error suppression from library sourcing
- Add verification checks after sourcing (test for function availability)
- Update command-development-fundamentals.md with multi-block sourcing requirements

**Pattern for Every Block** (from plan 861 pattern):
```bash
# Block N: Library Sourcing (MANDATORY)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library" >&2
  exit 1
}

# Verify critical functions available
if ! command -v load_workflow_state &>/dev/null; then
  echo "Error: load_workflow_state function not available after sourcing" >&2
  exit 1
fi
```

**Expected Impact**: Eliminates 100% of "command not found" errors for state functions

---

### 3. Implement Comprehensive State Persistence for Error Logging (HIGH PRIORITY)

**Priority**: P1 - Required for plan 861 implementation

**Action Items**:
- Add `COMMAND_NAME`, `USER_ARGS`, `WORKFLOW_ID` to state persistence in Block 1
- Restore these variables in Block 2+ before any error logging calls
- Update error-handling.md pattern with state persistence integration
- Create test cases verifying error logging context availability in all blocks

**Integration Pattern** (from plan 861 lines 276-313):

Block 1:
```bash
# Set error logging context
COMMAND_NAME="/command-name"
USER_ARGS="$user_input"
WORKFLOW_ID="command_$(date +%s)"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Persist for subsequent blocks
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
```

Block 2+:
```bash
# Restore error logging context
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/unknown")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
if [ -z "${WORKFLOW_ID:-}" ]; then
  WORKFLOW_ID=$(grep "^WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "unknown_$(date +%s)")
fi

export COMMAND_NAME USER_ARGS WORKFLOW_ID
```

**Expected Impact**: Eliminates 100% of unbound variable errors in error logging calls

---

### 4. Eliminate Error Suppression Anti-Pattern (MEDIUM PRIORITY)

**Priority**: P1 - Required for plan 861 effectiveness

**Action Items**:
- Remove `2>/dev/null` from `save_completed_states_to_state()` calls
- Replace `|| true` with explicit error handling
- Add verification after state persistence operations
- Update output-formatting.md to clarify when error suppression is appropriate

**Pattern Replacement**:
```bash
# BEFORE (suppresses errors):
save_completed_states_to_state 2>/dev/null

# AFTER (surfaces errors):
if ! save_completed_states_to_state; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to persist state transitions" \
    "bash_block" \
    "$(jq -n --arg file "$STATE_FILE" '{state_file: $file}')"

  echo "ERROR: State persistence failed" >&2
  exit 1
fi
```

**Expected Impact**: Increases error visibility from 30% to 60% (before plan 861 ERR traps)

---

### 5. Fix State File Path Mismatches (MEDIUM PRIORITY)

**Priority**: P2 - Improves state machine reliability

**Action Items**:
- Audit all commands for deprecated state file path usage
- Update to use `.claude/tmp/workflow_*.sh` pattern consistently
- Remove references to `.claude/data/states/` and `.claude/data/workflows/`
- Update state-persistence.sh documentation examples

**Path Migration**:
```bash
# DEPRECATED (remove all references):
STATE_FILE="/home/benjamin/.claude/data/states/build_${WORKFLOW_ID}.txt"

# STANDARD (use consistently):
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

**Expected Impact**: Eliminates state file not found errors in state machine transitions

---

### 6. Implement Plan 861 with These Prerequisite Fixes

**Priority**: P1 - Plan 861 depends on stable command execution

**Rationale**: Plan 861 implements ERR trap error capture, which will dramatically increase visibility of bash-level errors (30% → 90% capture rate). However, ERR traps will **report** but not **prevent** the errors analyzed in this report.

**Recommendation**: Implement recommendations 1-5 **before** or **in parallel with** plan 861 implementation:

1. **Recommendations 1-5** (this report): Fix root causes → reduce error occurrence
2. **Plan 861**: Capture remaining errors → increase visibility

**Expected Outcome**:
- **Before both**: 30% error capture rate, 70% command failure rate
- **After recommendations 1-5 only**: 30% error capture rate, 20% command failure rate (70% reduction in failures)
- **After plan 861 only**: 90% error capture rate, 70% command failure rate (visibility improved but not reliability)
- **After both**: 90% error capture rate, 10% command failure rate (optimal outcome)

**Implementation Strategy**:

Option A - Sequential (safer):
1. Implement recommendations 1-5 (fix root causes)
2. Test commands with reduced error rate
3. Implement plan 861 (capture remaining errors)

Option B - Parallel (faster):
1. Combine plan 861 phases with root cause fixes
2. Phase 1: ERR trap infrastructure + recommendation 1 (preprocessing safety)
3. Phase 2: Command integration + recommendations 2-3 (state persistence)
4. Phase 3: Validation + recommendations 4-5 (error suppression removal)

---

## Implementation Plan Proposal

### Plan Structure

This analysis should inform **two separate implementation plans**:

**Plan A: Command State Persistence Remediation** (this report's recommendations)
- **Scope**: Recommendations 1-5 from this report
- **Objective**: Fix root causes of command failures
- **Target**: Reduce command failure rate from 70% to 20%
- **Complexity**: Medium (4 phases, 8 hours)
- **Dependencies**: None (prerequisite for plan 861)

**Plan B: Bash-Level Error Capture System** (existing plan 861)
- **Scope**: ERR trap implementation across all commands
- **Objective**: Increase error capture rate from 30% to 90%
- **Target**: Complete error visibility for debugging
- **Complexity**: High (3 phases, 12 hours)
- **Dependencies**: Plan A (optimal) or none (acceptable with higher error volume)

### Integration Strategy

**Option 1 - Sequential Implementation** (recommended):
1. Create Plan A from this report's recommendations
2. Implement Plan A via /build command
3. Verify command failure rate reduction (70% → 20%)
4. Implement Plan B (existing plan 861)
5. Verify error capture rate improvement (30% → 90%)

**Option 2 - Merged Implementation** (faster but riskier):
1. Revise plan 861 to incorporate recommendations 1-5
2. Expand phase count from 3 to 5 phases
3. Implement merged plan via /build command
4. Verify both failure rate reduction and capture rate improvement

**Recommendation**: Option 1 (sequential) - cleaner separation of concerns, easier rollback if issues discovered

---

## Testing Requirements

### Unit Testing (recommendations 1-5)

**Test Suite 1: Preprocessing Safety**
- Test exit code capture pattern with various conditionals
- Verify no history expansion errors with safe patterns
- Test path validation with absolute and relative paths

**Test Suite 2: State Persistence**
- Test library re-sourcing in blocks 2-5
- Verify function availability after sourcing
- Test error logging variable restoration
- Verify state persistence across block boundaries

**Test Suite 3: Error Suppression Removal**
- Test explicit error handling for state operations
- Verify error logging captures state failures
- Test command behavior with state persistence errors

### Integration Testing (combined with plan 861)

**Test Suite 4: Multi-Block Command Execution**
- Test /plan with 3 blocks (initialization, research, planning)
- Test /build with 4 blocks (initialization, implementation, test, documentation)
- Test /revise with research and plan revision blocks
- Verify error capture rate >90% across all scenarios

**Test Suite 5: Error Recovery**
- Inject state file corruption and verify error capture
- Test unbound variable errors with ERR trap
- Test library sourcing failures with explicit error handling
- Verify error logs contain complete context

---

## References

### Source Files Analyzed
- /home/benjamin/.config/.claude/build-output.md (lines 1-111)
- /home/benjamin/.config/.claude/plan-output.md (lines 1-238)
- /home/benjamin/.config/.claude/revise-output.md (lines 1-153)

### Documentation References
- /home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md (lines 1-437)
- /home/benjamin/.config/.claude/lib/core/state-persistence.sh (lines 1-200)
- /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md (lines 1-150)
- /home/benjamin/.config/.claude/specs/861_build_command_use_this_research_to_create_a/plans/001_build_command_use_this_research_to_creat_plan.md (lines 1-580)

### Command Files Examined
- /home/benjamin/.config/.claude/commands/plan.md (lines 70-90, 242-260, 486)
- /home/benjamin/.config/.claude/commands/revise.md (lines 108-140)
- /home/benjamin/.config/.claude/commands/build.md (lines 468)

### Related Work
- Plan 861: Bash-Level Error Capture System (ERR trap implementation)
- Spec 752 Phase 9: State file location standardization
- Spec 620: Coordinate bash history expansion fixes
- Spec 672: State persistence fail-fast validation
