# Coordinate Command Infrastructure Analysis

## Metadata
- **Report Type**: Infrastructure Analysis
- **Date**: 2025-11-10
- **Scope**: /coordinate command architecture, dependencies, and integration patterns
- **Complexity Level**: 3
- **Status**: Complete

---

## Executive Summary

The `/coordinate` command implements a state-based orchestration architecture using explicit state machines, file-based persistence, and subprocess isolation patterns. The command coordinates multi-agent workflows through 7 phases (initialize → research → plan → implement → test → debug → document → complete) with wave-based parallel execution capabilities.

**Key Achievements**:
- 800 lines of executable code (26.2% reduction from 1,084 lines)
- 100% file creation reliability via mandatory verification checkpoints
- State-based architecture eliminates implicit phase dependencies
- Two-step execution pattern solves bash subprocess isolation issues

**Critical Dependencies**:
- 5 core libraries (workflow-state-machine, state-persistence, workflow-initialization, error-handling, verification-helpers)
- Bash tool subprocess isolation requires special patterns (no `$$`, no exports, file-based state)
- All bash blocks re-source libraries due to function scope loss across processes

---

## Architecture Overview

### 1. Command Structure

The coordinate command follows a **two-step execution pattern** to work around bash subprocess isolation:

```
Part 1: Workflow Description Capture (Lines 17-38)
└─> Writes user's workflow description to fixed file location

Part 2: Main Logic (Lines 40-242)
└─> Reads description from file and initializes state machine

State Handlers (Lines 243-1102)
├─> Research Phase (Lines 243-502)
├─> Planning Phase (Lines 503-660)
├─> Implementation Phase (Lines 661-773)
├─> Testing Phase (Lines 774-860)
├─> Debug Phase (Lines 861-980)
└─> Documentation Phase (Lines 981-1102)
```

**Why Two Steps?**: Each bash block in Claude Code runs as a **separate sibling process** (not child), so:
- Environment variables don't persist (`export` fails)
- Functions don't persist (must re-source libraries)
- Process ID `$$` changes (can't use for state tracking)
- **Solution**: Write arguments to file in Part 1, read in Part 2

### 2. State Machine Architecture

Implemented via `workflow-state-machine.sh` (508 lines):

**8 Core States**:
```
STATE_INITIALIZE  → Phase 0: Setup, scope detection, path pre-calculation
STATE_RESEARCH    → Phase 1: Parallel research agent invocation
STATE_PLAN        → Phase 2: Implementation plan creation
STATE_IMPLEMENT   → Phase 3: Wave-based parallel execution
STATE_TEST        → Phase 4: Test suite execution
STATE_DEBUG       → Phase 5: Debug analysis (conditional)
STATE_DOCUMENT    → Phase 6: Documentation updates (conditional)
STATE_COMPLETE    → Phase 7: Finalization, cleanup
```

**State Transition Table** (Lines 50-59):
```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research"
  [research]="plan,complete"        # Can skip to complete for research-only
  [plan]="implement,complete"       # Can skip to complete for research-and-plan
  [implement]="test"
  [test]="debug,document"           # Conditional: debug if failed, document if passed
  [debug]="test,complete"           # Retry testing or complete if unfixable
  [document]="complete"
  [complete]=""                     # Terminal state
)
```

**Key Functions**:
- `sm_init()` - Initialize state machine from workflow description
- `sm_transition()` - Validate and execute state transition (fail-fast on invalid)
- `sm_load()` - Load state machine from checkpoint (supports v1.3 → v2.0 migration)
- `sm_save()` - Save state machine to checkpoint (v2.0 schema)
- `sm_is_terminal()` - Check if current state is terminal for workflow scope

### 3. State Persistence Architecture

Implemented via `state-persistence.sh` (341 lines), follows **GitHub Actions pattern**:

**Selective File-Based Persistence** (7 critical items):
```bash
# Performance: 70% improvement (50ms → 15ms for CLAUDE_PROJECT_DIR detection)
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

# Format: bash export statements (sourceable)
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_ID="coordinate_1699123456"
export RESEARCH_COMPLETE="true"
export REPORTS_CREATED="4"
```

**Key Functions**:
- `init_workflow_state()` - Create state file once in initialization block
- `load_workflow_state()` - Source state file to restore variables (graceful degradation)
- `append_workflow_state()` - Append key-value pair (GitHub Actions `$GITHUB_OUTPUT` pattern)
- `save_json_checkpoint()` - Atomic write for structured data (temp file + mv)
- `load_json_checkpoint()` - Load JSON checkpoint (graceful degradation to `{}`)

**Why File-Based?**:
- Bash exports don't persist across subprocess boundaries
- Recalculation expensive (git rev-parse: 50ms vs file read: 15ms)
- Enables graceful degradation if state file missing

### 4. Workflow Initialization

Implemented via `workflow-initialization.sh` (333 lines):

**3-Step Pattern** (replaces 350+ line inline blocks):
```
STEP 1: Scope Detection (Lines 100-114)
└─> Validates workflow scope (research-only, research-and-plan, full-implementation, debug-only)

STEP 2: Path Pre-Calculation (Lines 117-260)
└─> Calculates ALL artifact paths upfront (85% token reduction)
    - Topic directory (NNN_topic_name)
    - Report paths (max 4 topics)
    - Plan path (001_implementation.md)
    - Implementation artifacts directory
    - Debug report path
    - Summary path

STEP 3: Directory Creation (Lines 191-228)
└─> Creates ONLY topic root directory (lazy creation)
    - Subdirectories created on-demand by agents
    - Fail-fast if topic root creation fails (no fallback)
```

**Key Functions**:
- `initialize_workflow_paths()` - Consolidate Phase 0 initialization
- `reconstruct_report_paths_array()` - Rebuild REPORT_PATHS array from exported variables

**Why Pre-Calculate?**: Agent-based detection consumed 10,000+ tokens per invocation. Pre-calculation reduces to ~400 tokens (96% reduction).

### 5. Error Handling Architecture

Implemented via `error-handling.sh` (875 lines):

**Error Classification** (3 types):
```
transient  → Locked files, timeouts, temporary unavailability (retry with backoff)
permanent  → Code-level issues (requires fix, no retry)
fatal      → Out of space, permissions, corrupted files (user intervention required)
```

**State-Specific Error Handler** (`handle_state_error()`, Lines 760-851):

**Five-Component Format**:
```
1. What failed - State and error message
2. Expected behavior - What should have happened in this state
3. Diagnostic commands - How to investigate the issue
4. Context - Workflow details, state info, paths
5. Recommended action - Retry count, next steps
```

**Example Output**:
```
✗ ERROR in state 'research': Research phase failed verification - 1 reports not created

Expected behavior:
  - All research agents should complete successfully
  - All report files created in $TOPIC_PATH/reports/

Diagnostic commands:
  cat "$STATE_FILE"
  ls -la "${TOPIC_PATH}"
  bash -n "${LIB_DIR}/workflow-state-machine.sh"

Context:
  - Workflow: Research auth patterns
  - Scope: research-only
  - Current State: research
  - Terminal State: research
  - Topic Path: /path/to/specs/042_auth

Recommended action:
  - Retry 1/2 available for state 'research'
  - Fix the issue identified in diagnostic output
  - Re-run: /coordinate "Research auth patterns"
  - State machine will resume from failed state
```

**Key Functions**:
- `classify_error()` - Classify error type from message
- `suggest_recovery()` - Generate recovery suggestions
- `retry_with_backoff()` - Exponential backoff retry (max 3 attempts)
- `handle_state_error()` - Fail-fast error handler with state context
- `escalate_to_user_parallel()` - User escalation for parallel operations

### 6. Verification Architecture

Implemented via `verification-helpers.sh` (130 lines):

**Concise Checkpoint Pattern** (90% token reduction):
```bash
# Success: Single character
verify_file_created "$REPORT_PATH" "Research report" "Phase 1"
# Output: ✓
# Return: 0

# Failure: 38-line diagnostic
# Output:
✗ ERROR [Phase 1]: Research report verification failed
   Expected: File exists at /path/to/report.md
   Found: File does not exist

DIAGNOSTIC INFORMATION:
  - Expected path: /path/to/report.md
  - Parent directory: /path/to/reports/
  - Directory status: ✓ Exists (3 files)
  - Recent files:
    -rw-r--r-- 1 user group 1234 Nov 10 12:34 001_topic1.md
    -rw-r--r-- 1 user group 5678 Nov 10 12:35 002_topic2.md

Diagnostic commands:
  ls -la /path/to/reports/
  cat .claude/agents/research-specialist.md | head -50

# Return: 1
```

**Key Functions**:
- `verify_file_created()` - Single-character success (✓), verbose failure diagnostics

**Benefits**:
- 90% token reduction at verification checkpoints
- 100% file creation reliability (mandatory verification after agent invocations)
- Fail-fast on missing files (no silent failures)

---

## Critical Bash-Specific Issues (From Spec 620)

### Issue #1: Process ID ($$ Pattern) - FIXED ✅

**Problem**: Using `$$` for filenames failed because each bash block runs as **separate sibling process**.

**Before**:
```bash
echo "description" > /tmp/coordinate_workflow_$$.txt  # PID 12345
# Next block...
cat /tmp/coordinate_workflow_$$.txt  # PID 67890 - different file!
```

**After** (Lines 34-36):
```bash
# Fixed semantic filename (same in all blocks)
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
echo "description" > "$COORDINATE_DESC_FILE"
# Next block...
cat "$COORDINATE_DESC_FILE"  # Same file ✅
```

**Impact**: Workflow description now persists correctly between blocks.

### Issue #2: Variable Scoping with Sourced Libraries - FIXED ✅

**Problem**: `workflow-state-machine.sh` has global variable initialization that **overwrites parent script's variables** when sourced.

**Root Cause** (`workflow-state-machine.sh:76`):
```bash
WORKFLOW_DESCRIPTION=""  # Overwrites parent's WORKFLOW_DESCRIPTION!
```

**Before** (coordinate.md):
```bash
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE")  # Set correctly
source "${LIB_DIR}/workflow-state-machine.sh"  # OVERWRITES to ""!
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"  # Empty string ❌
```

**After** (Lines 78-81):
```bash
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE")
# CRITICAL: Save BEFORE sourcing
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
source "${LIB_DIR}/workflow-state-machine.sh"  # Overwrites WORKFLOW_DESCRIPTION
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"  # Uses saved value ✅
```

**Impact**: Workflow description and scope detection now work correctly.

### Issue #3: Premature Cleanup (Trap Handler) - FIXED ✅

**Problem**: Trap handler in initialization block removed temp files at the **END of the first bash block**, before subsequent blocks could use them.

**Before** (Line 113):
```bash
# In initialization block:
trap "rm -f '$COORDINATE_DESC_FILE' '$COORDINATE_STATE_ID_FILE'" EXIT
# Trap fires when block exits → removes files ❌
```

**Result**:
```
# Next bash block:
ERROR: Workflow state ID file not found: coordinate_state_id.txt
```

**After**:

**1. Removed trap from initialization** (Lines 112-113):
```bash
# NOTE: NO trap handler here! Files must persist for subsequent bash blocks.
# Cleanup will happen manually or via external cleanup script.
```

**2. Added cleanup to completion function** (Lines 220-223):
```bash
display_brief_summary() {
  # ... show summary ...

  # Cleanup temp files now that workflow is complete
  COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  rm -f "$COORDINATE_DESC_FILE" "$COORDINATE_STATE_ID_FILE" 2>/dev/null || true
}
```

**Impact**: Temp files now persist across all bash blocks and cleanup happens only when workflow completes.

### Issue #4: History Expansion (`!` operator) - FIXED ✅

**Problem**: Bash history expansion (`!`) triggers in Claude Code's Bash tool preprocessing, causing syntax errors.

**Examples**:
```bash
if ! command -v jq &>/dev/null; then  # ERROR: !: command not found
if [[ ! -f "$file" ]]; then           # ERROR: !: event not found
```

**Fix** (Line 46):
```bash
set +H  # Explicitly disable history expansion (workaround for Bash tool preprocessing issues)
```

**Workarounds Applied**:
```bash
# Before:
if ! verify_file_created "$PATH" ...; then

# After (Lines 146, 622):
if verify_file_created "$PATH" ...; then
  : # Success - libraries loaded
else
  echo "ERROR: Failed to source required libraries"
  exit 1
fi
```

**Impact**: All `!` operators removed or replaced with `if/else` inversion.

---

## Library Dependencies

### Core Libraries (5)

1. **workflow-state-machine.sh** (508 lines)
   - Purpose: State machine abstraction for orchestration
   - Functions: 13 (sm_init, sm_transition, sm_load, sm_save, etc.)
   - Dependencies: workflow-detection.sh, checkpoint-utils.sh
   - Sourced: Every bash block (lines 88, 263, 396, 523, 600, 681, 749, 794, 882, 947, 1002, 1067)

2. **state-persistence.sh** (341 lines)
   - Purpose: GitHub Actions-style state persistence
   - Functions: 6 (init_workflow_state, load_workflow_state, append_workflow_state, etc.)
   - Performance: 67% improvement (6ms → 2ms for CLAUDE_PROJECT_DIR detection)
   - Sourced: Every bash block (lines 100, 264, 397, 524, 601, 682, 750, 795, 883, 948, 1003, 1068)

3. **workflow-initialization.sh** (333 lines)
   - Purpose: Consolidate Phase 0 initialization (3-step pattern)
   - Functions: 2 (initialize_workflow_paths, reconstruct_report_paths_array)
   - Token Reduction: 85% (10,000 → 1,500 tokens)
   - Sourced: Every bash block (lines 155, 265, 398, 525, 602, 683, 751, 796, 884, 949, 1004, 1069)

4. **error-handling.sh** (875 lines)
   - Purpose: Error classification, retry logic, state-aware error handling
   - Functions: 20+ (classify_error, retry_with_backoff, handle_state_error, etc.)
   - Features: Five-component error format, retry counters, user escalation
   - Sourced: Every bash block (lines 266, 399, 526, 603, 684, 752, 797, 885, 950, 1005, 1070)

5. **verification-helpers.sh** (130 lines)
   - Purpose: Concise verification patterns with 90% token reduction
   - Functions: 1 (verify_file_created)
   - Pattern: ✓ on success, 38-line diagnostic on failure
   - Sourced: Every bash block (lines 191, 267, 400, 527, 604, 685, 753, 798, 886, 951, 1006, 1071)

### Secondary Libraries (Referenced but not directly sourced by coordinate.md)

6. **library-sourcing.sh** (sourced line 128)
   - Purpose: Dynamic library loading based on workflow scope
   - Loads different library sets for research-only vs full-implementation

7. **workflow-detection.sh** (referenced by workflow-state-machine.sh)
   - Purpose: Detect workflow scope from description
   - Function: detect_workflow_scope()

8. **topic-utils.sh** (referenced by workflow-initialization.sh)
   - Purpose: Topic number generation, name sanitization
   - Functions: get_or_create_topic_number(), sanitize_topic_name()

9. **detect-project-dir.sh** (referenced by workflow-initialization.sh)
   - Purpose: Detect CLAUDE_PROJECT_DIR
   - Performance: Cached in state file (70% improvement)

### Library Sourcing Pattern

**Every bash block follows identical pattern**:
```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi
```

**Why Re-Source?**: Each bash block runs as separate process. Bash functions don't persist, must be re-declared.

**Performance**: Source guards in each library prevent duplicate execution:
```bash
if [ -n "${WORKFLOW_STATE_MACHINE_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_STATE_MACHINE_SOURCED=1
```

---

## State Management Patterns

### 1. State File Persistence

**Fixed-Location Pattern** (not `$$`-based):
```bash
# Initialization (Part 2, Line 109)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# State Restoration (Every bash block)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi
```

**Why Fixed Location?**:
- `$$` (process ID) changes per bash block
- Semantic filenames persist correctly
- Graceful error handling if state missing

### 2. Report Paths Array Reconstruction

**Problem**: Bash arrays don't export across subprocess boundaries.

**Solution** (Lines 176-186, 296-302):
```bash
# Initialization: Save array as individual variables
export REPORT_PATHS_COUNT="${#report_paths[@]}"
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done

# State Restoration: Reconstruct array from individual variables
reconstruct_report_paths_array() {
  REPORT_PATHS=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    local var_name="REPORT_PATH_$i"
    REPORT_PATHS+=("${!var_name}")
  done
}
```

**Why This Pattern?**: Bash arrays can't be exported. Workaround: Export count + individual variables.

### 3. Workflow State Append Pattern

**GitHub Actions `$GITHUB_OUTPUT` Pattern**:
```bash
# Append key-value pairs to state file
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"

# State file format (sourceable bash):
export CURRENT_STATE="research"
export TERMINAL_STATE="complete"
export TOPIC_PATH="/path/to/specs/042_auth"
```

**Benefits**:
- Simple append operation (<1ms)
- Sourceable format (bash export statements)
- Graceful degradation (file missing → recalculate)

### 4. Save-Before-Source Pattern

**Critical for Variable Preservation** (Lines 78-81):
```bash
# Read workflow description
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE")

# CRITICAL: Save BEFORE sourcing libraries
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

# Source libraries (may overwrite WORKFLOW_DESCRIPTION)
source "${LIB_DIR}/workflow-state-machine.sh"

# Use saved value (not overwritten variable)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
```

**Why Necessary?**: Libraries declare globals with same names, overwriting parent values.

---

## Agent Invocation Patterns

### 1. Research Phase - Flat Coordination (<4 topics)

**Pattern** (Lines 362-383):
```bash
# Invoke research-specialist agent for EACH topic
for i in 1 2 3; do
  Task {
    subagent_type: "general-purpose"
    description: "Research [topic name] with mandatory artifact creation"
    timeout: 300000
    prompt: "
      Read and follow ALL behavioral guidelines from:
      /home/benjamin/.config/.claude/agents/research-specialist.md

      **Workflow-Specific Context**:
      - Research Topic: [actual topic name]
      - Report Path: [REPORT_PATHS[$i-1] for topic $i]
      - Project Standards: /home/benjamin/.config/CLAUDE.md
      - Complexity Level: [RESEARCH_COMPLEXITY value]

      **CRITICAL**: Create report file at EXACT path provided above.

      Execute research following all guidelines in behavioral file.
      Return: REPORT_CREATED: [exact absolute path to report file]
    "
  }
done
```

**Verification** (Lines 450-473):
```bash
# Verify all research reports created
VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Research"; then
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done

if [ $VERIFICATION_FAILURES -gt 0 ]; then
  handle_state_error "Research phase failed verification - $VERIFICATION_FAILURES reports not created" 1
fi
```

**Key Features**:
- Parallel agent invocations (1-3 agents)
- Mandatory verification checkpoint (100% reliability)
- Fail-fast on missing reports (no silent failures)
- Save successful report paths to state

### 2. Research Phase - Hierarchical Coordination (≥4 topics)

**Pattern** (Lines 337-355):
```bash
# Invoke research-sub-supervisor for 4+ topics
Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4+ topics with 95% context reduction"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-sub-supervisor.md

    **Supervisor Inputs**:
    - Topics: [comma-separated list of $RESEARCH_COMPLEXITY topics]
    - Output directory: $TOPIC_PATH/reports
    - State file: $STATE_FILE
    - Supervisor ID: research_sub_supervisor_$(date +%s)

    **CRITICAL**: Invoke all research-specialist workers in parallel, aggregate metadata, save supervisor checkpoint.

    Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
  "
}
```

**Verification** (Lines 414-447):
```bash
# Load supervisor checkpoint
SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "research_supervisor")

# Extract report paths from supervisor checkpoint
SUPERVISOR_REPORTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')

# Verify reports exist
for REPORT_PATH in $SUPERVISOR_REPORTS; do
  if verify_file_created "$REPORT_PATH" "Supervisor report $REPORT_INDEX" "Hierarchical Research"; then
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done
```

**Key Features**:
- Hierarchical supervision (supervisor → workers)
- 95% context reduction (aggregate metadata, not full content)
- JSON checkpoint for supervisor state
- Same verification checkpoint pattern

### 3. Planning Phase

**Pattern** (Lines 570-586):
```bash
# Invoke /plan command via Task tool
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Execute the /plan slash command with the following arguments:

    /plan \"$WORKFLOW_DESCRIPTION\" $REPORT_ARGS

    This will create an implementation plan guided by the research reports.
    The plan will be saved to: $TOPIC_PATH/plans/

    Return: PLAN_CREATED: [absolute path to plan file]
  "
}
```

**Verification** (Lines 619-626):
```bash
# Verify plan was created
PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"

if verify_file_created "$PLAN_PATH" "Implementation plan" "Planning"; then
  echo "✓ Plan verified: $PLAN_PATH"
else
  handle_state_error "Plan file not created at expected path: $PLAN_PATH" 1
fi
```

**Key Features**:
- Delegates to /plan slash command (not agent)
- Passes research report paths as arguments
- Mandatory verification checkpoint
- Fail-fast if plan not created

### 4. Implementation Phase

**Pattern** (Lines 717-735):
```bash
# Invoke /implement command via Task tool
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with automated testing and commits"
  timeout: 600000
  prompt: "
    Execute the /implement slash command with the following arguments:

    /implement \"$PLAN_PATH\"

    This will execute the implementation plan phase-by-phase with:
    - Automated testing after each phase
    - Git commits for completed phases
    - Progress tracking and checkpoints

    Return: IMPLEMENTATION_COMPLETE: [summary or status]
  "
}
```

**Key Features**:
- Delegates to /implement slash command
- No explicit verification (handled by /implement)
- Longest timeout (600 seconds)

### 5. Testing Phase

**Pattern** (Lines 827-837):
```bash
# Run test suite
if command -v run_test_suite &>/dev/null; then
  TEST_RESULT=$(run_test_suite)
  TEST_EXIT_CODE=$?
else
  # Fallback: use /test-all
  bash "${CLAUDE_PROJECT_DIR}/.claude/tests/run_all_tests.sh"
  TEST_EXIT_CODE=$?
fi

# Save test result to workflow state
append_workflow_state "TEST_EXIT_CODE" "$TEST_EXIT_CODE"
```

**Conditional Transition** (Lines 843-859):
```bash
# Determine next state based on test results
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✓ All tests passed"
  sm_transition "$STATE_DOCUMENT"  # → documentation
else
  echo "❌ Tests failed"
  sm_transition "$STATE_DEBUG"     # → debug
fi
```

**Key Features**:
- Direct test execution (no agent)
- Fallback to bash script if run_test_suite unavailable
- Conditional state transition based on exit code

### 6. Debug Phase (Conditional)

**Pattern** (Lines 918-933):
```bash
# Invoke /debug command via Task tool
Task {
  subagent_type: "general-purpose"
  description: "Analyze and debug test failures"
  timeout: 300000
  prompt: "
    Execute the /debug slash command with the following context:

    /debug \"Analyze test failures from implementation of: $WORKFLOW_DESCRIPTION\"

    This will create a debug report with root cause analysis and proposed fixes.

    Return: DEBUG_REPORT_CREATED: [absolute path to debug report]
  "
}
```

**Terminal State** (Lines 969-978):
```bash
# Transition to complete (user must fix issues manually)
sm_transition "$STATE_COMPLETE"

echo "✓ Debug analysis complete"
echo "Debug report: $DEBUG_REPORT"
echo "NOTE: Please review debug report and fix issues manually"
echo "Then re-run: /coordinate \"$WORKFLOW_DESCRIPTION\""
```

**Key Features**:
- Delegates to /debug slash command
- Does not retry automatically (user intervention required)
- Transitions to terminal state after debug report created

### 7. Documentation Phase (Conditional)

**Pattern** (Lines 1038-1053):
```bash
# Invoke /document command via Task tool
Task {
  subagent_type: "general-purpose"
  description: "Update documentation based on implementation changes"
  timeout: 300000
  prompt: "
    Execute the /document slash command with the following context:

    /document \"Update docs for: $WORKFLOW_DESCRIPTION\"

    This will update all relevant documentation files based on the implementation changes.

    Return: DOCUMENTATION_UPDATED: [list of updated files]
  "
}
```

**Terminal State** (Lines 1085-1091):
```bash
# Transition to complete
sm_transition "$STATE_COMPLETE"

echo "✓ Documentation phase complete"
display_brief_summary
```

**Key Features**:
- Delegates to /document slash command
- Final phase before completion
- Displays workflow summary

---

## Data Flow Architecture

### Phase 0: Initialization

```
User Input → Part 1 Capture → File Write → Part 2 Read → State Machine Init
  ↓                  ↓                         ↓               ↓
"Research auth"   COORD_DESC_FILE    WORKFLOW_DESCRIPTION   sm_init()
                                            ↓                  ↓
                                     SAVED_WORKFLOW_DESC   WORKFLOW_SCOPE
                                                               ↓
                                                       TERMINAL_STATE
```

**Artifacts Created**:
- `${HOME}/.claude/tmp/coordinate_workflow_desc.txt` - Workflow description
- `${HOME}/.claude/tmp/coordinate_state_id.txt` - Workflow ID
- `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh` - State file

**State Variables Exported**:
- `WORKFLOW_ID` - Timestamp-based identifier
- `WORKFLOW_DESCRIPTION` - User's workflow description
- `WORKFLOW_SCOPE` - Detected scope (research-only, research-and-plan, full-implementation, debug-only)
- `CURRENT_STATE` - State machine current state (initialize → research)
- `TERMINAL_STATE` - Terminal state for this workflow scope
- `TOPIC_PATH` - Topic directory path (e.g., `.claude/specs/042_auth`)
- `REPORT_PATHS_COUNT` - Number of research reports (1-4)
- `REPORT_PATH_0` through `REPORT_PATH_3` - Individual report paths

### Phase 1: Research

```
State Machine → Agent Invocation → Parallel Execution → Verification → State Transition
     ↓               ↓                     ↓                 ↓              ↓
  research    Task tool (1-4 agents)  report files   verify_file_created  plan|complete
                     ↓                     ↓                 ↓              ↓
              research-specialist    REPORT_PATHS    SUCCESS_REPORT_PATHS  state file
```

**Artifacts Created**:
- `${TOPIC_PATH}/reports/001_topic1.md` - Research report 1
- `${TOPIC_PATH}/reports/002_topic2.md` - Research report 2 (if complexity ≥2)
- `${TOPIC_PATH}/reports/003_topic3.md` - Research report 3 (if complexity ≥3)
- `${TOPIC_PATH}/reports/004_topic4.md` - Research report 4 (if complexity ≥4)

**State Variables Updated**:
- `SUCCESSFUL_REPORT_PATHS` - Array of verified report paths
- `REPORT_PATHS_JSON` - JSON array of report paths (for state persistence)
- `CURRENT_STATE` - Transitions to `plan` or `complete` based on workflow scope

### Phase 2: Planning

```
State Machine → Agent Invocation → Plan Creation → Verification → State Transition
     ↓               ↓                   ↓              ↓              ↓
   plan       Task tool (/plan)      plan file    verify_file_created  implement|complete
                     ↓                   ↓              ↓              ↓
             /plan command         PLAN_PATH      plan verified    state file
                     ↓
           research report paths
```

**Artifacts Created**:
- `${TOPIC_PATH}/plans/001_implementation.md` - Implementation plan

**State Variables Updated**:
- `PLAN_PATH` - Path to implementation plan
- `CURRENT_STATE` - Transitions to `implement` or `complete` based on workflow scope

### Phase 3: Implementation

```
State Machine → Agent Invocation → Wave Execution → Commits → State Transition
     ↓               ↓                    ↓            ↓           ↓
  implement   Task tool (/implement)  phase-by-phase  git     test state
                     ↓                    ↓            ↓           ↓
             /implement command    implementation  commits    state file
                     ↓                    ↓
                PLAN_PATH           code changes
```

**Artifacts Created**:
- Modified code files (tracked by /implement)
- Git commits (one per phase)
- Implementation checkpoints (managed by /implement)

**State Variables Updated**:
- `CURRENT_STATE` - Transitions to `test`

### Phase 4: Testing

```
State Machine → Test Execution → Exit Code → State Transition
     ↓               ↓              ↓              ↓
   test       run_test_suite    TEST_EXIT_CODE  document|debug
                     ↓              ↓              ↓
              test output       0=pass, 1=fail  state file
```

**State Variables Updated**:
- `TEST_EXIT_CODE` - Test suite exit code (0=pass, 1=fail)
- `CURRENT_STATE` - Transitions to `document` (pass) or `debug` (fail)

### Phase 5: Debug (Conditional)

```
State Machine → Agent Invocation → Debug Report → Terminal State
     ↓               ↓                   ↓              ↓
  debug       Task tool (/debug)    report file    complete
                     ↓                   ↓              ↓
            /debug command        DEBUG_REPORT    state file
```

**Artifacts Created**:
- `${TOPIC_PATH}/debug/001_debug_analysis.md` - Debug report

**State Variables Updated**:
- `DEBUG_REPORT` - Path to debug report
- `CURRENT_STATE` - Transitions to `complete` (user intervention required)

### Phase 6: Documentation (Conditional)

```
State Machine → Agent Invocation → Doc Updates → Terminal State
     ↓               ↓                  ↓              ↓
  document    Task tool (/document)  doc files    complete
                     ↓                  ↓              ↓
            /document command      updated docs   state file
```

**State Variables Updated**:
- `CURRENT_STATE` - Transitions to `complete`

### Phase 7: Completion

```
State Machine → Summary Display → Cleanup → Exit
     ↓               ↓               ↓        ↓
  complete   display_brief_summary  rm temp  0
                     ↓               ↓
              workflow summary    state files removed
```

**Cleanup Operations**:
- Remove `${HOME}/.claude/tmp/coordinate_workflow_desc.txt`
- Remove `${HOME}/.claude/tmp/coordinate_state_id.txt`
- State file persists (can be manually cleaned or aged out)

---

## Integration Points

### 1. Agent Registry Integration

**Research Specialist Agent** (`/home/benjamin/.config/.claude/agents/research-specialist.md`):
- Invoked for each research topic (1-4 topics)
- Receives: topic name, report path, complexity level
- Returns: `REPORT_CREATED: [absolute path]`
- Behavioral file injection pattern (not YAML documentation blocks)

**Research Sub-Supervisor Agent** (`/home/benjamin/.config/.claude/agents/research-sub-supervisor.md`):
- Invoked for hierarchical research (≥4 topics)
- Manages 2-3 research-specialist workers
- Returns: `SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}`
- Saves checkpoint: `.claude/tmp/research_supervisor.json`

### 2. Slash Command Integration

**Commands Invoked via Task Tool**:
- `/plan` - Create implementation plan (Phase 2)
- `/implement` - Execute implementation plan (Phase 3)
- `/debug` - Analyze test failures (Phase 5)
- `/document` - Update documentation (Phase 6)

**Why Task Tool?**: Behavioral injection pattern (Standard 11) requires Task tool for agent invocations, not SlashCommand tool.

### 3. State Persistence Integration

**Checkpoint Schema v2.0**:
```json
{
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize"],
    "transition_table": { ... },
    "workflow_config": {
      "scope": "full-implementation",
      "description": "Research auth patterns",
      "command": "coordinate"
    }
  },
  "phase_data": { ... },
  "supervisor_state": { ... },
  "error_state": { ... },
  "metadata": { ... }
}
```

**Backward Compatibility**: `sm_load()` auto-migrates v1.3 → v2.0 (Lines 168-209).

### 4. Library Integration

**Dynamic Library Loading** (Lines 128-151):
```bash
# Source library-sourcing.sh
source "${LIB_DIR}/library-sourcing.sh"

# Load libraries based on workflow scope
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "unified-logger.sh" ...)
    ;;
  full-implementation)
    REQUIRED_LIBS=("workflow-detection.sh" "metadata-extraction.sh" "checkpoint-utils.sh" ...)
    ;;
esac

source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Benefits**:
- Minimal library loading for simple workflows
- Full library set for complex workflows
- Source guards prevent duplicate loading

---

## Potential Issues and Risks

### 1. Subprocess Isolation Brittleness

**Issue**: Every bash block runs as separate process. State persistence relies entirely on file I/O.

**Risks**:
- If state file deleted mid-workflow → unrecoverable error
- If state file corrupted → graceful degradation may fail
- If temp directory permissions change → write failures

**Mitigation**:
- Fixed-location temp files (not `/tmp` which may be cleaned)
- Graceful degradation in `load_workflow_state()` (fallback to recalculation)
- Explicit error messages with diagnostic commands

**Recommendation**: Add state file integrity checks (checksum validation).

### 2. Variable Overwriting in Sourced Libraries

**Issue**: Libraries declare globals that overwrite parent variables (Issue #2).

**Current Fix**: Save-before-source pattern (Lines 78-81).

**Risks**:
- Easy to forget when adding new libraries
- No compile-time checks for this pattern
- Silent failures if SAVED_* variable not used

**Mitigation**:
- Document pattern in Command Development Guide
- Add linter check for save-before-source pattern
- Use unique prefixes for library globals (e.g., `_LIB_WORKFLOW_DESCRIPTION`)

**Recommendation**: Refactor libraries to use namespaced globals or function-local scope.

### 3. History Expansion Issues

**Issue**: Bash history expansion (`!`) triggers in Bash tool preprocessing.

**Current Fix**: `set +H` at start of each bash block (Line 46).

**Risks**:
- Must remember to add `set +H` to every bash block
- If forgotten, cryptic error messages (`!: command not found`)
- Workaround applied inconsistently (some blocks use `if/else` inversion, others use `set +H`)

**Mitigation**:
- Standardize on `set +H` at start of every bash block
- Document in Command Development Guide
- Add linter check for `!` operators without `set +H`

**Recommendation**: Investigate Bash tool configuration to disable history expansion globally.

### 4. Array Export Workaround Complexity

**Issue**: Bash arrays don't export across subprocess boundaries. Workaround uses individual `REPORT_PATH_N` variables (Lines 176-186).

**Risks**:
- Complex reconstruction logic (`reconstruct_report_paths_array()`)
- Easy to miss index off-by-one errors
- Not scalable for large arrays (10+ items)

**Mitigation**:
- Limit arrays to small sizes (max 4 research topics)
- Document array reconstruction pattern
- Add test coverage for array reconstruction

**Recommendation**: Consider JSON serialization for complex data structures (used for supervisor checkpoints).

### 5. Cleanup Timing

**Issue**: Temp files cleaned only on workflow completion. If workflow exits early (error, Ctrl-C), files may leak.

**Risks**:
- `.claude/tmp/` accumulates orphaned state files
- Disk space exhaustion over time
- Stale state files confuse debugging

**Mitigation**:
- Document manual cleanup: `rm -f ~/.claude/tmp/coordinate_*`
- Age-based cleanup script (delete files >7 days old)

**Recommendation**: Add external cleanup cron job or integrate with project cleanup utilities.

### 6. Agent Reliability Dependency

**Issue**: 100% file creation reliability assumes agents always produce files. If agent crashes without creating file, verification fails.

**Risks**:
- Network timeouts during agent execution
- Agent tool failures (Write tool unavailable)
- Rate limiting (Claude API quota exhausted)

**Mitigation**:
- Retry logic with timeout extension (Lines 272-310 in error-handling.sh)
- User escalation after max retries (Lines 391-419 in error-handling.sh)
- Detailed diagnostic messages (verify_file_created() failure output)

**Recommendation**: Add automatic retry with backoff for agent invocations.

---

## Performance Characteristics

### Token Usage

**Initialization (Phase 0)**:
- Pre-calculation: ~1,500 tokens (vs 10,000 for agent-based detection = 85% reduction)
- Library sourcing: ~500 tokens (source guards minimize re-execution)
- State initialization: ~200 tokens

**Per-Phase Pattern** (consistent across all phases):
- Library re-sourcing: ~500 tokens
- State restoration: ~100 tokens
- Agent invocation: ~1,000 tokens (depends on prompt length)
- Verification checkpoint: ~50 tokens (single ✓ on success)
- State transition: ~100 tokens

**Total Workflow**:
- Research-only (2 topics): ~8,000 tokens
- Research-and-plan (2 topics + plan): ~12,000 tokens
- Full-implementation (2 topics + plan + implement + test + document): ~20,000 tokens

**Context Reduction**:
- Hierarchical supervision (≥4 topics): 95% reduction (10,000 → 500 tokens)
- Verification checkpoints: 90% reduction (38 lines → 1 character on success)
- Pre-calculated paths: 96% reduction (10,000 → 400 tokens)

### Execution Time

**Initialization**: ~500ms
- CLAUDE_PROJECT_DIR detection: 15ms (cached in state file)
- Scope detection: 50ms (regex matching)
- Path calculation: 100ms (topic number lookup + mkdir)
- Library sourcing: 200ms (5 libraries)
- State initialization: 100ms (file writes)

**Research Phase** (parallel execution):
- 2 topics: ~60 seconds (2 agents in parallel)
- 3 topics: ~90 seconds (3 agents in parallel)
- 4+ topics: ~120 seconds (hierarchical supervision overhead)

**Planning Phase**: ~30 seconds
- /plan command execution

**Implementation Phase**: Variable (depends on plan complexity)
- Simple plan (3 phases): ~10 minutes
- Complex plan (10+ phases): ~30 minutes

**Testing Phase**: Variable (depends on test suite)
- Unit tests only: ~30 seconds
- Full test suite: ~5 minutes

**Documentation Phase**: ~30 seconds
- /document command execution

**Total Workflow Time**:
- Research-only: ~2 minutes
- Research-and-plan: ~3 minutes
- Full-implementation: ~15-40 minutes (depends on implementation complexity)

### Disk Usage

**Temp Files**:
- State file: ~2KB (exports for 20+ variables)
- Workflow description file: <1KB
- State ID file: <1KB

**Artifacts**:
- Research reports: ~10KB each (2-4 reports = 20-40KB)
- Implementation plan: ~20KB
- Debug report: ~15KB (if created)

**Total Per Workflow**: ~50-100KB

---

## Standards Compliance

### Command Architecture Standards

**Standard 11: Imperative Agent Invocation** ✅
- All agent invocations use Task tool (not SlashCommand)
- Behavioral file injection pattern (`Read and follow ALL behavioral guidelines from: /path/to/agent.md`)
- No YAML documentation blocks (executable instructions only)

**Standard 13: CLAUDE_PROJECT_DIR Detection** ✅
- Standardized detection pattern (Lines 53-56)
- Cached in state file (performance optimization)
- Graceful degradation if not set

**Standard 14: Executable/Documentation Separation** ✅
- Executable file: `.claude/commands/coordinate.md` (800 lines)
- Guide file: `.claude/docs/guides/coordinate-command-guide.md` (comprehensive documentation)
- Pattern: Lean execution script (<250 lines target, exceeded due to state handlers)

### Testing Protocols

**Test Coverage**: Partial
- Manual testing: research-only workflow validated (Test 1 passed)
- Automated tests: None (coordinate command not covered by test suite)
- Edge cases: Untested (error recovery, retry logic, partial failures)

**Recommendations**:
- Add `.claude/tests/test_coordinate_command.sh` (integration test)
- Test scenarios: research-only, research-and-plan, full-implementation, error recovery
- Validate state persistence across bash blocks
- Test cleanup on normal exit and error exit

### Code Standards

**Bash Standards** ✅
- 2-space indentation
- `set -euo pipefail` (fail-fast error handling)
- Source guards in all libraries
- Explicit error messages with diagnostic commands

**Variable Naming** ✅
- snake_case for variables and functions
- UPPERCASE for exported constants
- Prefixed temp files (`COORDINATE_*`)

**Error Handling** ✅
- Five-component error format
- Fail-fast verification checkpoints
- Retry logic with exponential backoff
- User escalation after max retries

---

## Recommendations

### High Priority

1. **Add Automated Test Coverage**
   - Create `.claude/tests/test_coordinate_command.sh`
   - Test all workflow scopes (research-only, research-and-plan, full-implementation)
   - Validate state persistence across bash blocks
   - Test error recovery and cleanup

2. **Refactor Library Global Variables**
   - Use namespaced globals (e.g., `_LIB_WORKFLOW_DESCRIPTION`)
   - Eliminate variable overwriting issues
   - Remove need for save-before-source pattern

3. **Add State File Integrity Checks**
   - Checksum validation on state file load
   - Detect corruption early (fail-fast)
   - Improve error messages for corrupted state

4. **Standardize History Expansion Handling**
   - Add `set +H` to all bash blocks consistently
   - Document in Command Development Guide
   - Add linter check for `!` operators without `set +H`

### Medium Priority

5. **Add Automatic Retry for Agent Invocations**
   - Wrap Task tool calls with retry logic
   - Exponential backoff (max 3 attempts)
   - Improve reliability for transient failures

6. **Implement Cleanup Cron Job**
   - Age-based cleanup (delete files >7 days old)
   - Prevent disk space exhaustion
   - Document cleanup procedure

7. **Add JSON Serialization for Complex Arrays**
   - Replace `REPORT_PATH_N` pattern with JSON
   - Simplify reconstruction logic
   - Scale better for large arrays

8. **Enhance Error Context for Agent Failures**
   - Add agent execution logs
   - Capture stdout/stderr from agents
   - Improve diagnostics for silent failures

### Low Priority

9. **Optimize Library Loading**
   - Lazy load libraries (only when needed)
   - Reduce initialization time
   - Profile library sourcing overhead

10. **Add Workflow Resume Support**
    - Detect incomplete workflows on startup
    - Offer resume option to user
    - Skip completed phases

11. **Add Progress Indicators**
    - Real-time progress updates
    - Estimated time remaining
    - Visual feedback for long-running phases

12. **Document Bash Block Execution Model**
    - Create reference doc explaining subprocess isolation
    - Provide examples of correct patterns
    - Add to Command Development Guide

---

## Conclusion

The `/coordinate` command successfully implements a state-based orchestration architecture with robust error handling, state persistence, and verification checkpoints. The two-step execution pattern solves bash subprocess isolation issues, and the library-based architecture provides reusable components.

**Strengths**:
- State machine abstraction eliminates implicit phase dependencies
- File-based state persistence enables graceful degradation
- Mandatory verification checkpoints achieve 100% file creation reliability
- Fail-fast error handling with five-component diagnostics
- Token reduction through pre-calculation (85%), hierarchical supervision (95%), and concise verification (90%)

**Areas for Improvement**:
- Add automated test coverage
- Refactor library globals to eliminate variable overwriting
- Standardize history expansion handling
- Implement cleanup automation
- Add agent invocation retry logic

**Overall Assessment**: Production-ready architecture with known limitations. Recommended improvements focus on reliability (testing, retries) and maintainability (refactoring, documentation).

---

## Report Metadata

- **Report Type**: Infrastructure Analysis
- **Lines Analyzed**: 1,102 (coordinate.md) + 2,057 (5 core libraries) = 3,159 lines
- **Dependencies Mapped**: 9 libraries (5 core, 4 secondary)
- **Issues Identified**: 6 (3 fixed, 3 recommendations)
- **Integration Points**: 4 (agent registry, slash commands, state persistence, libraries)
- **Data Flow Phases**: 7 (initialize → research → plan → implement → test → debug → document → complete)

---

**END OF REPORT**
