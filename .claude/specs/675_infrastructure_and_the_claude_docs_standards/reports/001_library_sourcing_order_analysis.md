# Library Sourcing Order and Function Availability Analysis

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Library sourcing order issue in /coordinate command
- **Report Type**: codebase analysis

## Executive Summary

The /coordinate command has a critical library sourcing order bug where verification and error handling functions are called before the libraries defining them are sourced. Specifically, `verify_state_variable()` is called at lines 155, 164, and 237, while `verification-helpers.sh` is not sourced until line 265. Similarly, `handle_state_error()` is called at lines 140, 145, 156, 165, 209, 217, 238, and 282 before `error-handling.sh` is sourced. This causes "command not found" errors that terminate workflow initialization.

## Findings

### Root Cause Analysis

The issue stems from a fundamental sequencing problem in the initialization bash block (Part 2) of /coordinate command:

**Problem Sequence (Current State)**:
1. Lines 140-282: Multiple calls to `verify_state_variable()` and `handle_state_error()`
2. Line 169: `source_required_libraries()` is called, which sources `error-handling.sh` (via library-sourcing.sh)
3. Line 265: `verification-helpers.sh` is sourced directly

**Critical Issues Identified**:

1. **Premature Function Calls** (Lines 140-238):
   - `handle_state_error()` called at lines: 140, 145, 156, 165, 209, 217, 238, 282
   - `verify_state_variable()` called at lines: 155, 164, 237
   - All occur BEFORE library sourcing at line 169

2. **Incorrect Assumption About Library Loading**:
   - The code assumes `error-handling.sh` is sourced by `source_required_libraries()` at line 169
   - Evidence from `/home/benjamin/.config/.claude/lib/library-sourcing.sh:50`: error-handling.sh IS in the core library list
   - However, `verify_state_variable()` is not available until `verification-helpers.sh` is sourced at line 265

3. **Dual Sourcing Pattern** (Lines 263-266):
   ```bash
   # Source verification helpers (must be sourced BEFORE verify_state_variables is called)
   if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
     source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
   fi
   ```
   - Comment acknowledges the ordering requirement
   - But sourcing happens AFTER calls to these functions at lines 155, 164, 237

### File References

**Primary File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
- Lines 140-282: Initialization block with premature function calls
- Line 155: First `verify_state_variable("WORKFLOW_SCOPE")` call
- Line 164: Second `verify_state_variable("EXISTING_PLAN_PATH")` call
- Line 169: `source_required_libraries()` call (sources error-handling.sh)
- Line 237: Third `verify_state_variable("REPORT_PATHS_COUNT")` call
- Line 265: Direct sourcing of `verification-helpers.sh` (TOO LATE)
- Line 279: `verify_state_variables()` call (plural) - works because sourced by line 265

**Library Definitions**:
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh`:
  - Lines 223-280: `verify_state_variable()` function definition
  - Lines 302-368: `verify_state_variables()` function definition
  - Export statements at lines 282, 370

- `/home/benjamin/.config/.claude/lib/error-handling.sh`:
  - Lines 760+: `handle_state_error()` function definition
  - Sourced by library-sourcing.sh at line 50

- `/home/benjamin/.config/.claude/lib/library-sourcing.sh`:
  - Lines 48-56: Core library list includes error-handling.sh at line 50
  - Lines 87-100: Library sourcing loop

**Error Evidence**: `/home/benjamin/.config/.claude/specs/coordinate_output.md`
- Lines 24, 343, 405: Actual error messages showing "command not found"
- Line 343: `/run/current-system/sw/bin/bash: line 368: verify_state_variable: command not found`
- Line 344: `/run/current-system/sw/bin/bash: line 369: handle_state_error: command not found`
- Line 345: `/run/current-system/sw/bin/bash: line 450: verify_state_variable: command not found`

### Bash Block Execution Model Impact

This bug violates the bash block execution model principles documented in `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`:

1. **Subprocess Isolation**: Each bash block runs in a fresh subprocess, so libraries must be re-sourced
2. **Function Availability**: Functions are only available AFTER sourcing, not before
3. **Execution Order**: Linear top-to-bottom execution means order matters critically

The error demonstrates that the command author assumed functions would be available from:
- Prior bash blocks (violated by subprocess isolation)
- Implicit sourcing (no such mechanism exists)
- Out-of-order execution (bash executes sequentially)

### Why This Bug Exists

**Historical Context** (inferred from code structure):

1. **Evolution of Verification Pattern**:
   - Originally, verification was inline (no helper functions)
   - Verification helpers were extracted to reduce duplication
   - Extraction happened AFTER calls were already placed in initialization

2. **Comment Evidence**:
   - Line 263: "must be sourced BEFORE verify_state_variables is called"
   - Comment refers to `verify_state_variables()` (plural), not `verify_state_variable()` (singular)
   - Suggests developer was aware of ordering for one function but not the other

3. **Split Sourcing Pattern**:
   - `error-handling.sh` sourced via `source_required_libraries()` (line 169)
   - `verification-helpers.sh` sourced directly (line 265)
   - Inconsistent approach created gap where neither is available early

### Expected vs Actual Behavior

**Expected Behavior**:
1. Source all required libraries first
2. Then call functions from those libraries
3. Workflow proceeds to research state

**Actual Behavior**:
1. Call `handle_state_error()` at line 140 → "command not found" error
2. Script exits with error code 1
3. Workflow never reaches research state
4. User sees diagnostic message suggesting retry (which will fail again)

## Recommendations

### 1. Consolidate Library Sourcing at Top of Initialization Block

**Priority**: CRITICAL (blocks all /coordinate workflows)

**Action**: Move all library sourcing to lines 111-130 (immediately after sourcing state machine libraries).

**Specific Changes**:
```bash
# After line 126 (source state-persistence.sh), ADD:

# Source error handling IMMEDIATELY (needed for handle_state_error calls below)
if [ -f "${LIB_DIR}/error-handling.sh" ]; then
  source "${LIB_DIR}/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found"
  exit 1
fi

# Source verification helpers IMMEDIATELY (needed for verify_state_variable calls below)
if [ -f "${LIB_DIR}/verification-helpers.sh" ]; then
  source "${LIB_DIR}/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found"
  exit 1
fi
```

**Remove**: Lines 263-266 (duplicate sourcing of verification-helpers.sh)

**Keep**: Line 169 call to `source_required_libraries()` for remaining libraries

### 2. Audit All Function Calls vs Library Sourcing Order

**Priority**: HIGH (prevents regression)

**Action**: Create validation script to detect premature function calls:

```bash
#!/bin/bash
# validate-function-call-order.sh
# Detects functions called before their defining libraries are sourced

COMMAND_FILE="$1"

# Extract function names from all library files
FUNCTION_DEFS=$(grep -r "^[a-z_]*() {" .claude/lib/*.sh | awk -F: '{print $2}' | sed 's/() {//')

# For each function, find:
# 1. First call line number
# 2. Source line number for its library

# Report violations where call < source line number
```

**Integration**: Add to test suite as `test_library_sourcing_order.sh`

### 3. Standardize Library Sourcing Pattern Across All Commands

**Priority**: MEDIUM (improves consistency)

**Action**: Document and enforce standard sourcing order in command development guide:

**Standard Pattern**:
```bash
# 1. Source state machine core (if needed)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Source error handling and verification (always first)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Source remaining libraries via consolidated function
source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Rationale**:
- Error handling and verification are used throughout initialization
- Must be available before any checkpoints or error paths
- Consistent ordering reduces cognitive load

### 4. Update Bash Block Execution Model Documentation

**Priority**: LOW (documentation improvement)

**Action**: Add section on "Function Availability and Sourcing Order" to `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`

**Content to Add**:
- Functions must be sourced before calls (obvious but violated in practice)
- Recommended sourcing order for orchestration commands
- Anti-pattern: Calling functions before sourcing their libraries
- Detection: Use validation scripts to catch violations

## Implementation Impact

### Files Requiring Changes

1. **Primary Fix** - `/home/benjamin/.config/.claude/commands/coordinate.md`:
   - Lines 127-140: Add early sourcing of error-handling.sh and verification-helpers.sh
   - Lines 263-266: Remove duplicate verification-helpers.sh sourcing
   - Estimated: 10-line change

2. **Test Coverage** - `.claude/tests/test_library_sourcing_order.sh`:
   - New test file to validate function call ordering
   - Estimated: 50-line test script

3. **Documentation** - `.claude/docs/guides/coordinate-command-guide.md`:
   - Add troubleshooting section for "command not found" errors
   - Document correct sourcing order
   - Estimated: 20-line addition

4. **Pattern Documentation** - `.claude/docs/concepts/bash-block-execution-model.md`:
   - Add section on function availability
   - Estimated: 30-line addition

### Testing Strategy

1. **Unit Test**: Run modified coordinate command with all workflow scopes
   - research-only
   - research-and-plan
   - research-and-revise
   - full-implementation
   - debug-only

2. **Integration Test**: Execute full workflows to verify:
   - No "command not found" errors during initialization
   - State persistence verification succeeds
   - Workflow transitions to research state successfully

3. **Regression Test**: Validate other orchestration commands:
   - /orchestrate
   - /supervise
   - Any other commands using these libraries

### Risk Assessment

**Risk Level**: LOW
- Change is isolated to sourcing order (no logic changes)
- Sourcing idempotent (source guard prevents double-loading)
- Error handling improved (early availability of diagnostic functions)

**Rollback Plan**:
- Simple: revert to previous library sourcing pattern
- Complex: None (no state changes or data migrations)

## References

### Primary Files Analyzed
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-300)
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (full file, 371 lines)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 740-770)
- `/home/benjamin/.config/.claude/lib/library-sourcing.sh` (lines 1-100)
- `/home/benjamin/.config/.claude/specs/coordinate_output.md` (full file, error examples)

### Related Documentation
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (subprocess isolation model)
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` (usage guide)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (Standard 0: Execution Enforcement)

### Error Examples
- Line 24: First occurrence of "verify_state_variable: command not found"
- Line 343-345: Full error trace with 3 "command not found" errors
- Line 405: Repeated error in additional test run
