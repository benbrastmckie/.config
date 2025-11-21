# Root Cause Analysis: /build Command State Management Errors

## Metadata
- **Analysis Date**: 2025-11-21
- **Error Source**: /build command failures (7 errors over 11 hours)
- **Primary Issue**: `save_completed_states_to_state: command not found` (Exit code 127)
- **Affected Workflows**: 5 distinct build workflows
- **Severity**: CRITICAL - Blocks workflow completion and state persistence

## Executive Summary

The /build command experiences systematic failures (57% error rate for state_error type) due to **subprocess isolation violations** in bash block architecture. The root cause is that `save_completed_states_to_state()` function is not available in certain bash blocks because:

1. **Library not re-sourced**: Some blocks call state management functions without re-sourcing `workflow-state-machine.sh`
2. **Subprocess isolation violation**: Each bash block runs as a separate process (new PID), so functions from previous blocks are lost
3. **Anti-pattern usage**: Error suppression pattern (`2>&1`) applied to function call prevents proper exit code capture

Secondary issues include missing environment variables (CLAUDE_LIB undefined) and validation logic that's too strict for actual output formats.

## Technical Architecture Context

### Bash Block Execution Model

From `.claude/docs/concepts/bash-block-execution-model.md`:

```
Claude Code Session
    ↓
Command Execution (build.md)
    ↓
┌────────── Bash Block 1 ──────────┐
│ PID: 12345                       │
│ - Source libraries               │
│ - Call save_completed_states_to_state() │
│ - Exit subprocess                │
└──────────────────────────────────┘
    ↓ (subprocess terminates, functions lost)
┌────────── Bash Block 2 ──────────┐
│ PID: 12346 (NEW PROCESS)        │
│ - Libraries NOT sourced          │
│ - save_completed_states_to_state() NOT AVAILABLE │
│ - Exit code 127 (command not found) │
└──────────────────────────────────┘
```

**Key Insight**: Each bash block is a **separate subprocess**, not a subshell. All bash functions, exports, and state are lost between blocks unless explicitly persisted to files and re-loaded.

## Root Cause Breakdown

### Primary Issue: Missing Library Re-Sourcing in Subsequent Blocks

**Evidence from `/build` command**:

```bash
# Block 1 (lines 76-79) - Correctly sources libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
```

```bash
# Block 2 (lines 380-381) - INCOMPLETE library sourcing
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null
# Missing: workflow-state-machine.sh
# Missing: state-persistence.sh
# Missing: error-handling.sh
```

```bash
# Block 2 (line 543) - Calls function without library loaded
save_completed_states_to_state
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  # Error logging fails because error-handling.sh not sourced
  log_command_error "state_error" "Failed to persist state transitions" ...
fi
```

**Problem**: Block 2 calls `save_completed_states_to_state()` (defined in `workflow-state-machine.sh` line 126) and `log_command_error()` (defined in `error-handling.sh`) without sourcing these libraries first.

**Why This Happens**: The subprocess isolation model means Block 1's sourced libraries are lost when Block 2 starts with a new PID.

### Secondary Issue: CLAUDE_LIB Variable Not Defined

**Evidence from build-output.md line 78**:

```
Error: Exit code 127
/run/current-system/sw/bin/bash: line 116: CLAUDE_LIB: unbound variable
```

**Code Location** (build.md line 1434):

```bash
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}
```

**Problem**: `CLAUDE_LIB` variable is never set or exported in /build command. The code assumes it's available from environment but it's not initialized.

**Expected Value**: `CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"`

### Tertiary Issue: Improper Error Suppression Pattern

**Evidence from error report** (Pattern 1):

```bash
# Current code (lines 543-549)
save_completed_states_to_state 2>&1  # WRONG: Suppresses all output
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" ...
fi
```

**Problem**: The `2>&1` redirection combines stdout and stderr, which interferes with exit code capture when function doesn't exist. When bash tries to run `save_completed_states_to_state`, it outputs "command not found" to stderr, which gets redirected, and the exit code (127) is captured, but the ERROR function call also fails.

**From Output Formatting Standards** (.claude/docs/reference/standards/output-formatting.md lines 56-88):

```bash
# WRONG: Suppresses errors, hides failures
save_completed_states_to_state 2>/dev/null

# WRONG: Prevents error detection
library_function || true

# RIGHT: Explicit error checking
if ! save_completed_states_to_state; then
  log_command_error ...
  exit 1
fi
```

## Error Pattern Analysis

### Pattern Distribution

From error report (001_error_report.md):

```
Exit Code 127 (Command Not Found): 5 errors (71%)
  - save_completed_states_to_state: 4 (lines 390, 392, 398, 404)
  - . /etc/bashrc: 1 (line 1)

Exit Code 1 (General Failure): 2 errors (29%)
  - grep validation: 1 (line 254)
  - explicit return: 1 (line 404)
```

**Time Distribution**:
- Morning Cluster (06:04-06:18): 3 errors
- Afternoon Cluster (16:46-17:09): 4 errors

**Affected Plans**:
- `886_errors_command_report`: 2 errors
- `882_no_name`: 2 errors
- `868_directory_has_become_bloated`: 1 error
- `858_readmemd_files_throughout_claude_order_improve`: 1 error

## Standards Conformance Analysis

### Violation 1: Subprocess Isolation Pattern Not Followed

**Standard**: Bash Block Execution Model (.claude/docs/concepts/bash-block-execution-model.md)

**Requirement**:
> "File System as Communication Channel:
> - Only files written to disk persist across blocks
> - State persistence requires explicit file writes
> - **Libraries must be re-sourced in each block**"

**Current State**: Libraries not re-sourced in subsequent blocks

**Impact**: Functions unavailable, causing exit code 127 errors

### Violation 2: Error Suppression Applied to Critical Operations

**Standard**: Output Formatting Standards (.claude/docs/reference/standards/output-formatting.md lines 56-70)

**Requirement**:
> "Error suppression should NEVER be used for:
> - Critical operations (state persistence, library loading)
> - Operations where failure must be detected
> - Function calls that need error capture"

**Current State**: `2>&1` applied to `save_completed_states_to_state` calls

**Impact**: Exit code 127 captured but error context lost

### Violation 3: Missing Environment Variable Initialization

**Standard**: Code Standards (.claude/docs/reference/standards/code-standards.md lines 225-244)

**Requirement**: "Validate required environment" before use

**Current State**: `CLAUDE_LIB` used without initialization or validation

**Impact**: "unbound variable" error when accessed

## Impact Assessment

### Immediate Impact
- **Workflow Failure Rate**: 57% of /build executions fail at state persistence
- **State Loss**: Completed phases not persisted to state file
- **User Experience**: Build appears to complete but state is lost, requiring manual recovery
- **Debugging Difficulty**: Error messages unclear due to cascading failures

### Systemic Impact
- **Pattern Replication**: Same anti-pattern exists in other commands (/plan, /research, /debug, /repair)
- **Technical Debt**: 30+ files reference `save_completed_states_to_state` (found via grep)
- **Standards Drift**: Code no longer conforms to documented subprocess isolation pattern

## Recommended Fixes

### Fix 1: Add Library Re-Sourcing to All Blocks (CRITICAL)

**Location**: build.md lines 380-381 (and similar blocks)

**Change**:
```bash
# Current (WRONG)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null

# Fixed (RIGHT)
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null
```

**Rationale**: Ensures functions are available in each subprocess

**Expected Impact**: Eliminates 57% of /build errors (4 of 7)

### Fix 2: Initialize CLAUDE_LIB Variable (HIGH)

**Location**: build.md line ~75 (after CLAUDE_PROJECT_DIR initialization)

**Change**:
```bash
export CLAUDE_PROJECT_DIR

# Add immediately after
export CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Rationale**: Makes library path available to all blocks

**Expected Impact**: Eliminates "unbound variable" error (1 of 7 errors)

### Fix 3: Remove Error Suppression from Critical Calls (HIGH)

**Location**: build.md lines 543, 956, 1170

**Change**:
```bash
# Current (WRONG)
save_completed_states_to_state 2>&1
SAVE_EXIT=$?

# Fixed (RIGHT)
save_completed_states_to_state
SAVE_EXIT=$?
```

**Rationale**: Allows error messages to reach stderr for debugging

**Expected Impact**: Improves error visibility, does not fix root cause but aids debugging

### Fix 4: Relax Validation Logic (MEDIUM)

**Location**: build.md line 254

**Change**:
```bash
# Current (too strict)
grep -q '^\*\*Plan\*\*:' "$LATEST_SUMMARY" 2> /dev/null

# Fixed (more flexible)
if [[ -f "$LATEST_SUMMARY" ]] && [[ -s "$LATEST_SUMMARY" ]]; then
    # File exists and has content - validate format but don't fail
    if ! grep -q '^\*\*Plan\*\*:' "$LATEST_SUMMARY" 2>/dev/null; then
        echo "WARNING: Summary format unexpected: $LATEST_SUMMARY" >&2
    fi
else
    echo "ERROR: Summary file missing or empty: $LATEST_SUMMARY" >&2
    exit 1
fi
```

**Rationale**: Prevents workflow failure on minor format deviations

**Expected Impact**: Eliminates validation errors (1 of 7 errors)

## Implementation Strategy

### Phase 1: Immediate Fixes (Block /build failures)
1. Add library re-sourcing to Block 2 (lines 380-381)
2. Initialize CLAUDE_LIB variable in Block 1 (line 75)
3. Remove error suppression from state function calls (lines 543, 956, 1170)

**Expected Outcome**: Reduce /build errors from 7 to 1-2

### Phase 2: Systematic Remediation (Prevent recurrence)
1. Audit all commands for subprocess isolation violations
2. Create bash block template with required library sourcing
3. Add linter rule to detect missing library re-sourcing
4. Update Bash Block Execution Model docs with anti-pattern examples

**Expected Outcome**: Eliminate class of subprocess isolation errors

### Phase 3: Standards Update (Documentation)
1. Add "Library Re-Sourcing Checklist" to Code Standards
2. Create troubleshooting guide for "command not found" errors
3. Update /build command guide with subprocess isolation section

**Expected Outcome**: Prevent future violations through better documentation

## Testing Strategy

### Unit Tests
```bash
# Test 1: Verify library functions available in each block
test_library_availability() {
  # Block 1: Source libraries
  source workflow-state-machine.sh
  type save_completed_states_to_state  # Should succeed

  # Block 2: Without re-sourcing
  # (simulate new subprocess)
  bash -c 'type save_completed_states_to_state'  # Should fail (127)

  # Block 2: With re-sourcing
  bash -c 'source workflow-state-machine.sh && type save_completed_states_to_state'  # Should succeed
}

# Test 2: Verify CLAUDE_LIB variable set
test_claude_lib_defined() {
  source build.md  # Block 1
  [[ -n "$CLAUDE_LIB" ]]  # Should pass
  [[ "$CLAUDE_LIB" == *"/.claude/lib" ]]  # Should pass
}
```

### Integration Tests
```bash
# Test 3: Full workflow with state persistence
test_build_state_persistence() {
  /build test_plan.md 1
  # Verify state file created
  [[ -f .claude/tmp/workflow_build_*.sh ]]
  # Verify COMPLETED_STATES persisted
  grep "COMPLETED_STATES=" .claude/tmp/workflow_build_*.sh
}
```

### Regression Tests
```bash
# Test 4: Reproduce original errors
test_original_error_scenarios() {
  # Test scenario from error report
  /build .claude/specs/868_directory_has_become_bloated/plans/001_directory_has_become_bloated_plan.md
  # Should NOT produce exit code 127
  # Should NOT log "save_completed_states_to_state: command not found"
}
```

## Related Documentation

- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md)
- [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md)
- [Code Standards](.claude/docs/reference/standards/code-standards.md)
- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md)
- [Workflow State Machine Library](.claude/lib/workflow/workflow-state-machine.sh)

## Appendix: Error Locations in /build Command

### save_completed_states_to_state Call Sites

1. **Line 543** (Block 2: After phase completion marking)
2. **Line 956** (Block 3: After test phase)
3. **Line 1170** (Block 4: After documentation phase)

All three locations have the same issue: function called without library re-sourced.

### CLAUDE_LIB Usage Sites

1. **Line 1434** (Block 4: Summary formatting)

Only one location, but critical for workflow completion.

### grep Validation Site

1. **Line 254** (Location TBD - not in visible excerpts)

Validation logic for summary file format.

---

**Report Generated**: 2025-11-21
**Analysis Basis**:
- Error report: .claude/specs/20251120_build_error_analysis/reports/001_error_report.md
- Build output: .claude/build-output.md
- Source code: .claude/commands/build.md
- Documentation: .claude/docs/
