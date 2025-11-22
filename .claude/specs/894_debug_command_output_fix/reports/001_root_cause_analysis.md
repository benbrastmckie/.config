# Root Cause Analysis: /debug Command Output and Directory Issues

## Metadata
- **Analysis Date**: 2025-11-21
- **Analyzed Issue**: /debug command produces debug-output.md with errors and creates empty debug/ directory
- **Error Source**: /debug command execution with subprocess isolation violations
- **Primary References**:
  - /home/benjamin/.config/.claude/debug-output.md (command execution output)
  - /home/benjamin/.config/.claude/specs/107_debug_command_error_analysis/reports/001_error_report.md (error analysis)
  - /home/benjamin/.config/.claude/specs/105_build_state_management_bash_errors_fix/reports/001_root_cause_analysis.md (related analysis)
- **Severity**: CRITICAL - /debug command non-functional, creates misleading artifacts

## Executive Summary

The /debug command suffers from **two critical architectural issues** that render it non-functional:

1. **Library Function Availability Failures** (67% of errors): Functions like `initialize_workflow_paths`, `load_workflow_state`, and `setup_bash_error_trap` are not available in bash blocks due to missing library re-sourcing, causing exit code 127 ("command not found") errors.

2. **Incomplete Directory Structure Creation**: The `initialize_workflow_paths()` function creates only the topic root directory (e.g., `105_build_state_management_bash_errors_fix/`) but **never creates subdirectories** (`reports/`, `plans/`, `debug/`), yet the command assumes these directories exist.

These issues are **symptoms of a broader system-wide problem** affecting multiple commands (/plan, /build, /research, /repair) that violates the Bash Block Execution Model standard documented in `.claude/docs/concepts/bash-block-execution-model.md`.

### Impact Assessment

**Immediate Impact**:
- /debug command has 100% failure rate (3 out of 3 executions failed)
- Users cannot perform root cause analysis or debugging workflows
- Misleading error messages provide no actionable guidance
- Empty `debug/` directories create confusion about command state

**Systemic Impact**:
- Pattern affects 35+ files using `save_completed_states_to_state` (found via grep)
- Violates documented subprocess isolation standards
- Creates technical debt across entire command infrastructure
- Error logging system itself fails due to library loading issues

## Technical Architecture Context

### Bash Block Execution Model (Standard)

From `.claude/docs/concepts/bash-block-execution-model.md`:

```
Claude Code Session
    ↓
Command Execution (debug.md)
    ↓
┌────────── Bash Block 1 ──────────┐
│ PID: 12345                       │
│ - Source libraries               │
│ - Call initialize_workflow_paths() │
│ - Exit subprocess                │
└──────────────────────────────────┘
    ↓ (subprocess terminates, functions lost)
┌────────── Bash Block 2 ──────────┐
│ PID: 12346 (NEW PROCESS)        │
│ - Libraries NOT sourced          │
│ - initialize_workflow_paths() NOT AVAILABLE │
│ - Exit code 127 (command not found) │
└──────────────────────────────────┘
```

**Key Principle**: Each bash block is a separate subprocess. All bash functions, exports, and state are lost between blocks unless:
1. Libraries are explicitly re-sourced in each block
2. State is persisted to files and re-loaded
3. Functions are available in the current subprocess context

### Directory Creation Model (Incomplete Implementation)

From `.claude/lib/plan/topic-utils.sh` (lines 125-138):

```bash
create_topic_structure() {
  local topic_path="$1"

  # Create only the topic root directory
  mkdir -p "$topic_path"

  # Verification checkpoint
  if [ ! -d "$topic_path" ]; then
    echo "ERROR: Failed to create topic directory: $topic_path" >&2
    return 1
  fi

  return 0
}
```

**Problem**: Function creates **only** the topic root directory (e.g., `105_topic_name/`). The comment explicitly states "Create only the topic root directory", yet commands assume subdirectories exist.

## Root Cause Breakdown

### Root Cause 1: Missing Library Re-Sourcing in Subsequent Blocks (67% of Errors)

**Evidence from /debug command** (/home/benjamin/.config/.claude/commands/debug.md):

**Block 1 (Lines 143-147)** - Correctly sources libraries:
```bash
# Source libraries in dependency order with output suppression
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
```

**Block 2a (Lines 286-289)** - INCOMPLETE library sourcing:
```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
```

Missing: `workflow-initialization.sh` (contains `initialize_workflow_paths`)

**Block 2a (Line 538)** - Calls function without library loaded:
```bash
initialize_workflow_paths "$ISSUE_DESCRIPTION" "debug-only" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  echo "ERROR: Failed to initialize workflow paths"
  echo "DIAGNOSTIC: Check initialize_workflow_paths() in workflow-initialization.sh"
  exit 1
fi
```

**Problem**:
- `initialize_workflow_paths()` is defined in `workflow-initialization.sh` (sourced in Block 1)
- Block 2a does NOT re-source `workflow-initialization.sh`
- Function is not available when called → Exit code 127 ("command not found")
- Error handler itself (`log_command_error`) may also fail if `error-handling.sh` not sourced

**Error from debug-output.md (Line 44)**:
```
Error: Exit code 1
/run/current-system/sw/bin/bash: line 151: load_workflow_state: command not found
/run/current-system/sw/bin/bash: line 163: setup_bash_error_trap: command not found
/run/current-system/sw/bin/bash: line 171: log_command_error: command not found
ERROR: State file path not set (see /home/benjamin/.claude/tmp/workflow_debug.log)
```

**Analysis**: Cascading failures due to missing library functions. The bash block attempts to:
1. Call `load_workflow_state()` - fails (not sourced)
2. Call `setup_bash_error_trap()` - fails (not sourced)
3. Call `log_command_error()` - fails (not sourced)

Result: Total breakdown of error handling and state management infrastructure.

### Root Cause 2: Incomplete Directory Structure Creation

**Evidence from workflow-initialization.sh** (lines 543-578):

```bash
elif ! create_topic_structure "$topic_path"; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "CRITICAL ERROR: Topic root directory creation failed" >&2
  # ... extensive error handling ...
  return 1
fi
```

The function `create_topic_structure()` creates **only** the topic root directory. From `topic-utils.sh` lines 125-138:

```bash
create_topic_structure() {
  local topic_path="$1"

  # Create only the topic root directory
  mkdir -p "$topic_path"

  # Verification checkpoint
  if [ ! -d "$topic_path" ]; then
    echo "ERROR: Failed to create topic directory: $topic_path" >&2
    return 1
  fi

  return 0
}
```

**Problem**: The function comment explicitly states "Create only the topic root directory" - this is **by design**, not a bug in `topic-utils.sh`. However:

**Assumption Violation in /debug command** (lines 549-550):
```bash
RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
```

The command **assumes** these subdirectories exist, but they were never created. The `initialize_workflow_paths()` function:
1. Creates topic root: `/path/to/specs/105_build_state_management_bash_errors_fix/`
2. Does NOT create subdirectories: `reports/`, `plans/`, `debug/`, `summaries/`
3. Exports variables pointing to non-existent directories

**Evidence from filesystem**:
```bash
$ ls -la /home/benjamin/.config/.claude/specs/105_build_state_management_bash_errors_fix/
total 44
drwxr-xr-x   4 benjamin users  4096 Nov 21 09:29 .
drwxr-xr-x 112 benjamin users 28672 Nov 21 09:40 ..
drwxr-xr-x   3 benjamin users  4096 Nov 21 09:40 plans
drwxr-xr-x   2 benjamin users  4096 Nov 21 09:39 reports
# NO debug/ directory exists
```

The `plans/` and `reports/` directories were created **by agents** (research-specialist, plan-architect) when they wrote files, not by `initialize_workflow_paths()`. The `debug/` directory was never created because:
1. No agent wrote files to it (debug-analyst agent may not have been invoked)
2. `/debug` command doesn't create it proactively
3. `initialize_workflow_paths()` doesn't create subdirectories

**Impact**:
- Commands reference non-existent directories
- Agents create directories implicitly when writing files (inconsistent behavior)
- Empty `debug/` directories indicate incomplete workflows, but may just mean no agent created files
- Directory existence checks fail silently or cause misleading errors

### Root Cause 3: Improper Error Suppression Pattern

**Evidence from error report** (Pattern from 001_error_report.md):

**Current code pattern** (/debug command, multiple blocks):
```bash
save_completed_states_to_state 2>&1
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" ...
fi
```

**Problem**: The `2>&1` redirection combines stdout and stderr, which:
1. Hides error messages that could aid debugging
2. Prevents proper error context from reaching stderr
3. Violates Output Formatting Standards (lines 56-88)

**From Output Formatting Standards** (`.claude/docs/reference/standards/output-formatting.md`):

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

**Analysis**: Error suppression is being misapplied to critical operations. The pattern should be:
- **Suppress**: Verbose library output, directory creation noise
- **Preserve**: Error messages, function failures, validation errors

Current code suppresses both, making debugging impossible.

### Root Cause 4: Validation Failure on Empty Input

**Evidence from error log** (001_error_report.md, Error 3):

```json
{
  "timestamp": "2025-11-21T16:48:02Z",
  "command": "/debug",
  "user_args": "",
  "error_message": "Bash error at line 52: exit code 1",
  "context": {
    "line": 52,
    "exit_code": 1,
    "command": "return 1"
  }
}
```

**Code location** (debug.md lines 61-66):
```bash
if [ -z "$ISSUE_DESCRIPTION" ]; then
  echo "ERROR: Issue description required"
  echo "USAGE: /debug <issue-description>"
  echo "EXAMPLE: /debug \"investigate authentication timeout errors in production logs\""
  exit 1
fi
```

**Problem**: Validation exists but error message is unclear:
1. User receives "Bash error at line 52: exit code 1" (from error trap)
2. Error message "ERROR: Issue description required" is printed but not logged properly
3. No guidance on command format or examples in error context

**Expected behavior**:
- Validation should log structured error with `log_command_error`
- Error message should be preserved in error log for `/errors` query
- User should receive actionable guidance, not generic "exit code 1"

## Error Pattern Analysis

### Pattern Distribution

From error report analysis (001_error_report.md):

```
Exit Code 127 (Command Not Found): 2 errors (67%)
  - initialize_workflow_paths: 1 (line 96)
  - Multiple functions: 1 (line 151+)

Exit Code 1 (General Failure): 1 error (33%)
  - Empty input validation: 1 (line 52)
```

**Time Distribution**:
- Morning execution (06:17:35): 1 error (initialization failure)
- Afternoon execution (16:47:46-16:48:02): 2 errors (environment + validation)

**Workflow Impact**:
- `debug_1763705783`: Failed at initialization (with valid input)
- `debug_1763743176`: Failed at validation + environment setup (empty input)

### Comparison with /build Command Errors

From 105_build_state_management_bash_errors_fix/reports/001_root_cause_analysis.md:

**Similar Pattern**:
- /build: `save_completed_states_to_state: command not found` (exit 127)
- /debug: `initialize_workflow_paths: command not found` (exit 127)

**Common Root Cause**: Missing library re-sourcing in subsequent bash blocks

**Key Difference**:
- /build errors occur late in workflow (lines 390-404) after some progress
- /debug errors occur early (line 96) preventing any progress

**Systemic Pattern**: Affects multiple commands:
| Command | Missing Function | Affected Lines | Impact |
|---------|-----------------|---------------|--------|
| /debug | initialize_workflow_paths | 96, 151+ | 100% failure rate |
| /build | save_completed_states_to_state | 390, 392, 398, 404 | 57% failure rate |
| /plan | append_workflow_state | Multiple | Unknown |
| /errors | get_next_topic_number | Multiple | 4 errors logged |

## Standards Conformance Analysis

### Violation 1: Subprocess Isolation Pattern Not Followed

**Standard**: Bash Block Execution Model (`.claude/docs/concepts/bash-block-execution-model.md` lines 44-48)

**Requirement**:
> "File System as Communication Channel:
> - Only files written to disk persist across blocks
> - State persistence requires explicit file writes
> - **Libraries must be re-sourced in each block**"

**Current State**: Libraries not re-sourced in blocks 2a, 3, 4, 5, 6

**Evidence**:
- Block 1: Sources 4 libraries (state-persistence, workflow-state-machine, library-version-check, error-handling)
- Block 2a: Sources 3 libraries (missing workflow-initialization.sh)
- Block 3+: Sources 3-4 libraries but order varies, inconsistent

**Impact**: Functions unavailable when called, causing exit code 127 errors

**Pattern from standards** (bash-block-execution-model.md lines 413-428):
```bash
# In each bash block:

# 1. Re-source library (functions lost across block boundaries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# 2. Load workflow state
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# 3. Update state
append_workflow_state "CURRENT_STATE" "research"

# 4. State automatically persists to file
```

**Current /debug pattern**: Partial implementation, missing step 1 for all required libraries

### Violation 2: Error Suppression Applied to Critical Operations

**Standard**: Output Formatting Standards (`.claude/docs/reference/standards/output-formatting.md` lines 56-95)

**Requirement**:
> "Error suppression should NEVER be used for:
> - Critical operations (state persistence, library loading)
> - Operations where failure must be detected
> - Function calls that need error capture"

**Current State**: `2>&1` applied to critical function calls throughout /debug

**Evidence** (debug.md multiple blocks):
```bash
save_completed_states_to_state 2>&1  # WRONG
sm_transition "$STATE_RESEARCH" 2>&1  # WRONG
initialize_workflow_paths ... # No redirection (CORRECT)
```

**Impact**:
- Error messages hidden or lost
- Exit codes captured but context missing
- Debugging difficulty increased significantly

**Correct Pattern** (output-formatting.md lines 73-88):
```bash
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

### Violation 3: Directory Structure Assumptions

**Standard**: Directory Organization (`.claude/docs/concepts/directory-organization.md`)

**Implicit Requirement**: Commands should not assume directory structure exists unless explicitly created

**Current State**:
- `initialize_workflow_paths()` creates only topic root directory
- /debug assumes `reports/`, `plans/`, `debug/` subdirectories exist
- No explicit directory creation before use

**Evidence** (debug.md lines 549-550):
```bash
RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
```

These directories are assigned but never created by the command. Agents create them implicitly when writing files.

**Impact**:
- Inconsistent directory creation (sometimes by agents, sometimes missing)
- Empty `debug/` directories indicate no files written, not incomplete workflows
- Difficult to distinguish between "workflow incomplete" and "no debug artifacts"

### Violation 4: Missing Input Validation Error Logging

**Standard**: Error Logging Standards (CLAUDE.md, error_logging section)

**Requirement**: All errors must integrate centralized error logging

**Current State**: Input validation errors print to stdout/stderr but don't call `log_command_error`

**Evidence** (debug.md lines 61-66):
```bash
if [ -z "$ISSUE_DESCRIPTION" ]; then
  echo "ERROR: Issue description required"
  echo "USAGE: /debug <issue-description>"
  echo "EXAMPLE: /debug \"investigate authentication timeout errors in production logs\""
  exit 1
fi
```

Missing: `log_command_error` call to record validation failure

**Impact**:
- Validation errors not queryable via `/errors` command
- Error patterns not visible for analysis
- No structured error data for debugging

**Correct Pattern** (from error-logging standards):
```bash
if [ -z "$ISSUE_DESCRIPTION" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Issue description is required" \
    "$(printf '{"user_args":"%s","provided_args_count":%d}' "$*" $#)"

  echo "ERROR: Issue description required" >&2
  echo "USAGE: /debug <issue-description>" >&2
  exit 1
fi
```

## Recommended Fixes

### Fix 1: Add Complete Library Re-Sourcing to All Blocks (CRITICAL)

**Priority**: CRITICAL
**Effort**: 2-3 hours
**Impact**: Eliminates 67% of /debug errors (2 of 3)

**Location**: All bash blocks in /debug command (blocks 2a, 3, 4, 5, 6)

**Change**:
```bash
# Current (Block 2a, lines 286-289) - INCOMPLETE
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Fixed - COMPLETE library sourcing
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}
```

**Rationale**:
- Ensures all required functions are available in each subprocess
- Follows Bash Block Execution Model standard (Pattern 4)
- Fail-fast error handling prevents silent failures
- Consistent with recommended pattern across all orchestration commands

**Expected Outcome**:
- `initialize_workflow_paths()` available in Block 2a
- `load_workflow_state()` available in all blocks
- `setup_bash_error_trap()` available in all blocks
- Exit code 127 errors eliminated

**Testing**:
```bash
# Test 1: Verify function availability after sourcing
/debug "test issue description"
# Should complete initialization without "command not found" errors

# Test 2: Verify state persistence works
/errors --command /debug --since 5m
# Should show no exit code 127 errors
```

### Fix 2: Explicitly Create Subdirectories in initialize_workflow_paths (HIGH)

**Priority**: HIGH
**Effort**: 1-2 hours
**Impact**: Prevents misleading empty directories, clarifies directory structure

**Location**: Either in `initialize_workflow_paths()` function OR in /debug command after calling it

**Option A: Modify workflow-initialization.sh** (Affects all commands):
```bash
# In workflow-initialization.sh, after create_topic_structure($topic_path)
# Create subdirectories explicitly (lines 578+)

# Create all standard subdirectories
mkdir -p "${topic_path}/reports" 2>/dev/null
mkdir -p "${topic_path}/plans" 2>/dev/null
mkdir -p "${topic_path}/summaries" 2>/dev/null
mkdir -p "${topic_path}/debug" 2>/dev/null

# Verification checkpoints
for subdir in reports plans summaries debug; do
  if [ ! -d "${topic_path}/${subdir}" ]; then
    echo "ERROR: Failed to create ${subdir}/ directory" >&2
    return 1
  fi
done
```

**Option B: Modify /debug command** (Affects only /debug):
```bash
# In debug.md, after initialize_workflow_paths call (line 544+)

# Create subdirectories explicitly
mkdir -p "$RESEARCH_DIR" 2>/dev/null || {
  echo "ERROR: Failed to create research directory: $RESEARCH_DIR" >&2
  exit 1
}
mkdir -p "${SPECS_DIR}/plans" 2>/dev/null || {
  echo "ERROR: Failed to create plans directory" >&2
  exit 1
}
mkdir -p "$DEBUG_DIR" 2>/dev/null || {
  echo "ERROR: Failed to create debug directory: $DEBUG_DIR" >&2
  exit 1
}
```

**Recommendation**: Use Option A (modify workflow-initialization.sh) because:
1. Centralizes directory creation logic
2. Benefits all commands, not just /debug
3. Consistent with design principle: `initialize_workflow_paths()` should fully initialize
4. Removes implicit directory creation by agents

**Rationale**:
- Explicit is better than implicit (Python Zen applies to bash too)
- Eliminates confusion about whether workflow completed
- Makes directory structure predictable and verifiable
- Prevents missing directory errors in agents

**Expected Outcome**:
- All topic directories have consistent subdirectory structure
- Empty `debug/` directories clearly indicate no artifacts, not failure
- Agents don't need to create directories implicitly
- Directory existence checks always pass

### Fix 3: Remove Error Suppression from State Management Calls (HIGH)

**Priority**: HIGH
**Effort**: 1 hour
**Impact**: Improves error visibility, aids debugging

**Location**: Multiple blocks in /debug command (blocks 3, 4, 5, 6)

**Change**:
```bash
# Current (WRONG) - Example from block 3, line 686
save_completed_states_to_state 2>&1
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" ...
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi

# Fixed (RIGHT) - Remove 2>&1 redirection
save_completed_states_to_state
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" ...
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi

# Even better - Use if ! pattern
if ! save_completed_states_to_state; then
  log_command_error "state_error" "Failed to persist state transitions" ...
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

**Rationale**:
- Allows error messages to reach stderr for debugging
- Conforms to Output Formatting Standards
- Preserves error context for troubleshooting
- Fail-fast pattern still enforced via exit 1

**Expected Outcome**:
- Error messages visible in debug output
- `log_command_error` receives proper context
- Users see actual errors, not just exit codes
- Easier to diagnose future issues

### Fix 4: Add Structured Input Validation Error Logging (MEDIUM)

**Priority**: MEDIUM
**Effort**: 30 minutes
**Impact**: Improves error queryability, consistent error handling

**Location**: debug.md lines 61-66 (input validation)

**Change**:
```bash
# Current (INCOMPLETE)
if [ -z "$ISSUE_DESCRIPTION" ]; then
  echo "ERROR: Issue description required"
  echo "USAGE: /debug <issue-description>"
  echo "EXAMPLE: /debug \"investigate authentication timeout errors in production logs\""
  exit 1
fi

# Fixed (COMPLETE)
if [ -z "$ISSUE_DESCRIPTION" ]; then
  # Log validation error for /errors queryability
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Issue description is required" \
    "bash_block_1" \
    "$(jq -n --arg args "$*" --argjson count $# \
       '{user_args: $args, provided_args_count: $count}')"

  # User-facing error message
  cat <<EOF >&2
ERROR: Issue description required

USAGE: /debug <issue-description> [--file <path>] [--complexity 1-4]

EXAMPLES:
  /debug "Build command fails with exit code 127"
  /debug "Agent not returning expected output" --complexity 3
  /debug "Parser error in test suite" --file tests/parser-test.sh

For more information, see: .claude/docs/guides/commands/debug-command-guide.md
EOF

  exit 1
fi
```

**Rationale**:
- Validation errors become queryable via `/errors --command /debug`
- Consistent with error logging standards
- Provides better user guidance
- Enables error pattern analysis

**Expected Outcome**:
- Validation errors logged to `errors.jsonl`
- Users receive helpful, actionable error messages
- Error analysts can track validation failure patterns
- Command usage examples visible in error output

### Fix 5: Add Defensive Function Availability Checks (LOW)

**Priority**: LOW (defensive programming)
**Effort**: 1 hour
**Impact**: Fail-fast with clear diagnostics when libraries missing

**Location**: After library sourcing in each block

**Change**:
```bash
# After sourcing libraries, verify critical functions available
# In each bash block after sourcing

# Verify critical functions available (fail-fast pattern)
for func in load_workflow_state append_workflow_state setup_bash_error_trap log_command_error; do
  if ! declare -F "$func" >/dev/null 2>&1; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "CRITICAL ERROR: Required function not available" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Missing function: $func" >&2
    echo "" >&2
    echo "Possible causes:" >&2
    echo "  - Library not sourced in this bash block" >&2
    echo "  - Source command failed silently" >&2
    echo "  - Library file missing or corrupted" >&2
    echo "" >&2
    echo "Required libraries for this block:" >&2
    echo "  - core/state-persistence.sh (provides load_workflow_state, append_workflow_state)" >&2
    echo "  - core/error-handling.sh (provides setup_bash_error_trap, log_command_error)" >&2
    echo "  - workflow/workflow-state-machine.sh (provides sm_* functions)" >&2
    echo "  - workflow/workflow-initialization.sh (provides initialize_workflow_paths)" >&2
    echo "" >&2
    echo "Solution: Ensure all libraries sourced at start of bash block" >&2
    echo "See: .claude/docs/concepts/bash-block-execution-model.md" >&2
    exit 1
  fi
done
```

**Rationale**:
- Catches library sourcing failures immediately
- Provides diagnostic information for debugging
- Prevents cryptic "command not found" errors later
- Self-documenting: error message lists required libraries

**Expected Outcome**:
- Clear error messages when libraries fail to source
- Easier troubleshooting for future maintainers
- Fail-fast prevents cascading failures
- Documentation embedded in error messages

## Implementation Strategy

### Phase 1: Critical Fixes (Week 1) - Restore /debug Functionality

**Goal**: Make /debug command functional for basic use cases

**Tasks**:
1. Add complete library re-sourcing to all bash blocks (Fix 1)
2. Remove error suppression from critical calls (Fix 3)
3. Test /debug with various inputs
4. Verify no exit code 127 errors

**Deliverables**:
- /debug command executes successfully with valid input
- No "command not found" errors
- Error messages visible and actionable
- Success rate: >95% for valid inputs

**Validation**:
```bash
# Test 1: Basic functionality
/debug "Test issue: build command fails"
# Expected: Creates reports/, plans/, (maybe debug/), no errors

# Test 2: Empty input validation
/debug ""
# Expected: Clear error message with examples, exit code 1

# Test 3: Error logging
/errors --command /debug --since 10m
# Expected: No exit code 127 errors, validation errors logged properly
```

### Phase 2: Robustness Improvements (Week 2)

**Goal**: Improve directory handling and error diagnostics

**Tasks**:
1. Implement directory creation fix (Fix 2, Option A preferred)
2. Add structured input validation logging (Fix 4)
3. Add defensive function availability checks (Fix 5)
4. Update /debug command guide with new behavior

**Deliverables**:
- Consistent directory structure across all workflows
- Validation errors queryable via `/errors`
- Self-diagnostic error messages
- Updated documentation

**Validation**:
```bash
# Test 4: Directory structure
/debug "Directory test issue"
ls -la .claude/specs/*/
# Expected: All topics have reports/, plans/, summaries/, debug/ subdirectories

# Test 5: Validation error logging
/debug ""
/errors --type validation_error --command /debug
# Expected: Validation error appears in error log with context

# Test 6: Defensive checks
# (Temporarily rename a library to simulate failure)
mv .claude/lib/core/state-persistence.sh{,.bak}
/debug "Test issue"
# Expected: Clear error message identifying missing library
mv .claude/lib/core/state-persistence.sh{.bak,}
```

### Phase 3: System-Wide Remediation (Weeks 3-4)

**Goal**: Apply fixes to other affected commands, prevent recurrence

**Tasks**:
1. Audit all commands for library re-sourcing issues (/plan, /build, /research, /repair)
2. Create bash block template with complete library sourcing
3. Add linter rule to detect missing library re-sourcing
4. Update Bash Block Execution Model docs with anti-patterns
5. Create troubleshooting guide for "command not found" errors

**Deliverables**:
- All commands conform to subprocess isolation standards
- Reusable bash block template
- Automated linting for library sourcing
- Enhanced documentation with examples
- Troubleshooting guide for common patterns

**Validation**:
```bash
# Test 7: Linter catches violations
.claude/scripts/lint-bash-blocks.sh .claude/commands/*.md
# Expected: Reports any blocks missing required library sourcing

# Test 8: System-wide error reduction
/errors --since 1w --type execution_error | grep "command not found" | wc -l
# Expected: Zero instances of exit code 127 errors

# Test 9: Documentation completeness
grep -r "re-source libraries" .claude/docs/
# Expected: Pattern documented in multiple guides and references
```

## Testing Strategy

### Unit Tests

**Test 1: Library Availability Across Blocks**
```bash
# Create test command with multiple bash blocks
# Verify functions available in each block after sourcing

test_library_availability() {
  # Block 1: Source libraries
  source workflow-state-machine.sh
  type save_completed_states_to_state  # Should succeed

  # Block 2: Without re-sourcing (simulates new subprocess)
  bash -c 'type save_completed_states_to_state'  # Should fail (127)

  # Block 2: With re-sourcing
  bash -c 'source workflow-state-machine.sh && type save_completed_states_to_state'  # Should succeed
}
```

**Test 2: Directory Structure Creation**
```bash
test_directory_structure() {
  local topic_path="$(/path/to/test-topic-creation.sh)"

  # Verify all subdirectories exist
  for subdir in reports plans summaries debug; do
    [[ -d "$topic_path/$subdir" ]] || {
      echo "ERROR: Missing $subdir directory"
      return 1
    }
  done

  echo "✓ All subdirectories created"
}
```

**Test 3: Error Suppression Validation**
```bash
test_error_visibility() {
  # Call function that should fail
  output=$(some_failing_function 2>&1)

  # Verify error message visible
  [[ "$output" == *"ERROR"* ]] || {
    echo "ERROR: Error message suppressed"
    return 1
  }

  echo "✓ Error messages preserved"
}
```

### Integration Tests

**Test 4: Full /debug Workflow**
```bash
test_debug_workflow() {
  # Execute /debug with valid input
  /debug "Test issue: investigate timeout"

  # Verify artifacts created
  [[ -d .claude/specs/*/reports/ ]] || return 1
  [[ -f .claude/specs/*/reports/*.md ]] || return 1
  [[ -f .claude/specs/*/plans/*.md ]] || return 1

  # Verify no errors logged
  error_count=$(/errors --command /debug --since 1m | grep -c "ERROR")
  [[ $error_count -eq 0 ]] || return 1

  echo "✓ /debug workflow complete without errors"
}
```

**Test 5: Error Logging Integration**
```bash
test_error_logging() {
  # Trigger validation error
  /debug "" 2>/dev/null || true

  # Verify error logged
  /errors --type validation_error --command /debug --since 1m | grep -q "Issue description is required" || {
    echo "ERROR: Validation error not logged"
    return 1
  }

  echo "✓ Validation errors logged correctly"
}
```

### Regression Tests

**Test 6: Reproduce Original Errors**
```bash
test_original_error_scenarios() {
  # Test scenario 1: initialize_workflow_paths not found
  # (Should NOT occur after Fix 1)
  /debug "Test issue description"

  # Verify no exit code 127
  /errors --command /debug --since 1m | grep -v "exit code 127" || {
    echo "ERROR: Exit code 127 still occurring"
    return 1
  }

  # Test scenario 2: Empty input validation
  # (Should log validation error after Fix 4)
  /debug "" 2>/dev/null || true
  /errors --type validation_error --command /debug | grep -q "required" || {
    echo "ERROR: Validation error not logged"
    return 1
  }

  echo "✓ Original error scenarios resolved"
}
```

## Related Documentation

### Standards and Concepts
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md) - Error suppression guidelines
- [Directory Organization](.claude/docs/concepts/directory-organization.md) - Directory structure standards
- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) - Error logging requirements

### Related Analysis
- [/debug Error Analysis](.claude/specs/107_debug_command_error_analysis/reports/001_error_report.md) - Error pattern analysis
- [/build State Management Analysis](.claude/specs/105_build_state_management_bash_errors_fix/reports/001_root_cause_analysis.md) - Similar root cause

### Implementation Files
- [debug.md](.claude/commands/debug.md) - /debug command implementation
- [workflow-initialization.sh](.claude/lib/workflow/workflow-initialization.sh) - Path initialization
- [topic-utils.sh](.claude/lib/plan/topic-utils.sh) - Directory creation utilities
- [workflow-state-machine.sh](.claude/lib/workflow/workflow-state-machine.sh) - State management

## Conclusion

The /debug command failures stem from **fundamental violations of the Bash Block Execution Model** standard, specifically:

1. **Missing library re-sourcing** (67% of errors): Functions not available in subprocess blocks
2. **Incomplete directory creation** (architectural issue): Subdirectories assumed but never created
3. **Improper error suppression** (debugging impediment): Critical errors hidden from view

These issues are **not isolated to /debug** - they affect the entire command infrastructure (/plan, /build, /research, /repair) and represent systematic technical debt.

### Immediate Actions Required

1. **Add complete library re-sourcing** to all bash blocks in /debug (Fix 1)
2. **Remove error suppression** from state management calls (Fix 3)
3. **Test thoroughly** with various input scenarios

### Strategic Actions

1. **Standardize directory creation** in `initialize_workflow_paths()` (Fix 2)
2. **Add defensive checks** for function availability (Fix 5)
3. **Apply pattern** to all affected commands system-wide
4. **Update documentation** with anti-patterns and troubleshooting guides
5. **Create linter** to prevent future violations

### Expected Outcome

With Fixes 1-5 implemented:
- /debug success rate: >95% for valid inputs
- Exit code 127 errors: 0 (eliminated)
- Directory structure: Consistent across all workflows
- Error visibility: Clear, actionable messages
- System-wide impact: Pattern applied to all commands

The root causes are well-understood, fixes are straightforward, and the path to resolution is clear. The key is systematic application across the entire command infrastructure to prevent recurrence.

---

**Report Generated**: 2025-11-21
**Analysis Complexity**: 3 (High - Multiple root causes, system-wide impact)
**Analyzed Files**: 6 (debug.md, workflow-initialization.sh, topic-utils.sh, bash-block-execution-model.md, output-formatting.md, error reports)
**Recommendations**: 5 fixes prioritized CRITICAL to LOW
**Implementation Phases**: 3 phases over 3-4 weeks
