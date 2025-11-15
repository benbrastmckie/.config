# Coordinate Command Resilience Improvements Research Report

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Coordinate Command Resilience Improvements
- **Report Type**: Codebase analysis and architectural patterns
- **Complexity**: 4
- **Focus Areas**: State validation, verification checkpoints, error recovery, diagnostics

## Executive Summary

The coordinate command demonstrates robust verification checkpoint architecture through three core libraries (verification-helpers.sh, error-handling.sh, checkpoint-utils.sh) that implement fail-fast validation with comprehensive diagnostics. Key strengths include 90% token reduction at checkpoints via concise success reporting, five-component error message format for faster troubleshooting, and state-aware error recovery with retry tracking. Primary improvement opportunities exist in state variable verification coverage (currently used 69 times but could expand to all critical state transitions), graceful degradation patterns for partial agent failures, and enhanced diagnostic commands for common error scenarios.

## Findings

### Current State Verification Architecture

#### 1. Verification Checkpoint Library (verification-helpers.sh)

**Purpose**: Standardized file and state verification with 90% token reduction
**Location**: `.claude/lib/verification-helpers.sh` (514 lines)

**Key Functions**:

**verify_file_created()** (lines 73-170):
- Single-character success output ("✓") vs multi-line failure diagnostics
- Enhanced directory analysis with file metadata
- Root cause analysis for path mismatches
- Comprehensive troubleshooting commands

**verify_state_variable()** (lines 223-280):
- Single variable verification in state file
- Defensive checks for STATE_FILE existence
- Export format validation (matches state-persistence.sh pattern)
- Detailed diagnostic messages with troubleshooting steps

**verify_state_variables()** (lines 302-370):
- Batch verification for multiple state variables
- Lists missing variables with diagnostic context
- File size and content analysis
- Comprehensive error reporting

**verify_files_batch()** (lines 420-513):
- Batch file verification with token efficiency
- Success: "✓ All N files verified" (single line)
- Failure: Per-file diagnostics with consolidated troubleshooting
- 88% token reduction for 5-file verification (250 → 30 tokens)

**Performance Characteristics**:
- Success path: <10 tokens per verification
- Failure path: 200-400 tokens with comprehensive diagnostics
- Net token savings: 90% at checkpoints (3,150 tokens saved per workflow)

#### 2. Error Handling Library (error-handling.sh)

**Purpose**: Error classification, recovery strategies, retry logic
**Location**: `.claude/lib/error-handling.sh` (882 lines)

**Error Classification**:
- Transient errors: Network timeouts, file locks, resource contention
- Permanent errors: Code-level issues requiring fixes
- Fatal errors: System-level issues (disk full, permissions)
- LLM-specific errors: Timeouts, API errors, parsing errors, low confidence (Spec 688)

**Key Functions**:

**classify_error()** (lines 33-55):
- Pattern-based classification from error messages
- Keyword matching for error types
- Defaults to permanent (code-level) classification

**suggest_recovery()** (lines 61-84):
- Error-type-specific recovery suggestions
- Retry guidance for transient errors
- Debug command recommendations for permanent errors
- User intervention guidance for fatal errors

**detect_error_type()** (lines 94-141):
- Detailed error categorization (syntax, test_failure, file_not_found, etc.)
- Pattern matching for specific error scenarios
- Returns specific error type for targeted recovery

**generate_suggestions()** (lines 164-237):
- Error-type-specific actionable suggestions
- Context-aware troubleshooting steps
- Tool-specific guidance (linters, debuggers, package managers)

**handle_state_error()** (lines 767-858):
- **Five-component error message format**:
  1. What failed (error message with state context)
  2. Expected behavior (state-specific expectations)
  3. Diagnostic commands (actionable troubleshooting)
  4. Context (workflow scope, state, topic path)
  5. Recommended action (retry logic with counter tracking)
- State persistence for resume support
- Retry counter tracking (max 2 retries per state)
- Automatic retry suggestions vs manual intervention

**Retry Logic**:

**retry_with_backoff()** (lines 247-273):
- Exponential backoff implementation
- Configurable max attempts and base delay
- Silent retry with progress reporting

**retry_with_timeout()** (lines 279-317):
- Extended timeout calculation (1.5x increase per attempt)
- JSON metadata return for retry coordination
- Max 3 attempts enforcement

**retry_with_fallback()** (lines 323-351):
- Reduced toolset recommendation for complex operations
- Full toolset → reduced toolset strategy
- JSON metadata with fallback guidance

**Partial Failure Handling**:

**handle_partial_failure()** (lines 551-617):
- Separates successful and failed operations
- Returns JSON with can_continue and requires_retry flags
- Enables graceful degradation for parallel operations
- Research phase example: Continues if ≥50% agents succeed

#### 3. Checkpoint and State Management

**Checkpoint Utilities** (checkpoint-utils.sh):
- Checkpoint schema version 2.1
- Wave tracking fields for parallel execution
- State machine integration (error_state tracking)
- Retry counter persistence (replan_phase_counts)
- Plan modification time tracking for staleness detection

**State Persistence** (state-persistence.sh):
- GitHub Actions-style state persistence pattern
- Selective file-based persistence (7 critical items)
- 70% performance improvement (50ms → 15ms for CLAUDE_PROJECT_DIR)
- Graceful degradation fallback to recalculation
- Atomic writes with temp file + mv pattern

**Key State Variables**:
- WORKFLOW_SCOPE: Determines which phases execute
- RESEARCH_COMPLEXITY: Controls agent invocation count
- REPORT_PATHS_COUNT: Drives verification loop iterations
- EXISTING_PLAN_PATH: Required for research-and-revise workflows
- COORDINATE_STATE_ID_FILE: Enables concurrent workflow isolation

#### 4. Verification Coverage Analysis

**Current Usage in coordinate.md**:
- 69 instances of verification functions identified via grep
- Breakdown by function type:
  - verify_file_created: ~40 instances (research reports, plans, summaries)
  - verify_state_variable: ~15 instances (WORKFLOW_SCOPE, REPORT_PATHS_COUNT, etc.)
  - handle_state_error: ~14 instances (state transition errors, agent failures)

**Critical Verification Points**:
1. **After sm_init** (line 151): WORKFLOW_SCOPE verification
2. **After array export** (line 233): REPORT_PATHS_COUNT verification
3. **Research phase** (lines 797-850): Report file verification loop
4. **Planning phase**: PLAN_PATH verification
5. **Implementation phase**: Wave completion verification
6. **State transitions**: Before every sm_transition call

**Verification Patterns**:
```bash
# Pattern 1: State variable verification
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted" 1
}

# Pattern 2: File verification with diagnostic context
verify_file_created "$REPORT_PATH" "Research report" "Phase 1" || {
  echo "ERROR: Report verification failed"
  exit 1
}

# Pattern 3: Batch verification for multiple files
verify_files_batch "Phase 1" "${FILE_ENTRIES[@]}" && echo ""
```

### State Validation Strategies

#### 1. Pre-Validation Before Use

**Current Implementation**:
- State variables verified immediately after persistence (defensive pattern)
- Prevents unbound variable errors in subsequent bash blocks
- Example: WORKFLOW_SCOPE verified after sm_init (coordinate.md:151)

**Pattern**:
```bash
# After state-altering operation
append_workflow_state "VARIABLE_NAME" "$VARIABLE_VALUE"

# Immediate verification checkpoint
verify_state_variable "VARIABLE_NAME" || {
  handle_state_error "CRITICAL: VARIABLE_NAME not persisted" 1
}
```

**Benefits**:
- Fail-fast error detection (catches persistence failures immediately)
- Clear failure point (shows which operation failed)
- Prevents cascading errors (stops before unbound variables accessed)

#### 2. State Transition Validation

**Current Implementation** (Spec 652):
- sm_transition called BEFORE validation
- State persisted immediately after transition
- Transition logging with timestamps
- Enhanced error diagnostics for validation failures

**Pattern** (coordinate.md lines 221-224, 660-663):
```bash
echo "Transitioning from research to plan"
sm_transition "$STATE_PLAN"
append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
echo "State transition complete: $(date +%Y-%m-%d\ %H:%M:%S)"
```

**Error Message Structure** (error-handling.sh:1973-1991):
```
ERROR: State transition validation failed
  Expected: plan
  Actual: implement

TROUBLESHOOTING:
  1. Verify sm_transition was called in previous bash block
  2. Check workflow state file for CURRENT_STATE value
  3. Verify workflow scope: full-implementation
  4. Review state machine transition logs above
```

#### 3. Subprocess State Restoration

**Critical Pattern** (Standard 15):
- Load workflow state BEFORE sourcing libraries
- Maintain consistent dependency order in ALL bash blocks
- Add verification checkpoints after library initialization

**Implementation** (all bash blocks in coordinate.md):
```bash
# Step 1: Read state ID file
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")

# Step 2: Load workflow state BEFORE sourcing
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
fi

# Step 3: Re-source libraries in dependency order
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Verification checkpoint
if ! command -v verify_file_created &>/dev/null; then
  echo "ERROR: Required functions not available" >&2
  exit 1
fi
```

**Why This Order**:
- Load state first prevents WORKFLOW_SCOPE reset by library initialization
- Dependency order ensures later libraries can use earlier ones
- Verification checkpoint ensures libraries loaded correctly

#### 4. Concurrent Workflow Isolation (Spec 672 Phase 4)

**Problem**: Fixed state ID file location causes concurrent workflows to interfere

**Solution**: Unique timestamp-based state ID files per workflow

**Pattern**:
```bash
# Block 1: Create unique state ID file
TIMESTAMP=$(date +%s%N)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Persist path to workflow state
append_workflow_state "COORDINATE_STATE_ID_FILE" "$COORDINATE_STATE_ID_FILE"

# Cleanup trap
trap "rm -f '$COORDINATE_STATE_ID_FILE' 2>/dev/null || true" EXIT

# Block 2+: Load with backward compatibility
COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  load_workflow_state "$WORKFLOW_ID"

  if [ -n "${COORDINATE_STATE_ID_FILE:-}" ] && \
     [ "$COORDINATE_STATE_ID_FILE" != "$COORDINATE_STATE_ID_FILE_OLD" ]; then
    # New pattern: use unique file from state
    :
  else
    # Old pattern: use fixed location (backward compat)
    COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
  fi
fi
```

**Benefits**:
- 2+ workflows can run simultaneously without state conflicts
- Backward compatibility with old workflows using fixed location
- Automatic cleanup via trap (no state file leakage)
- No race conditions (isolated state per workflow)

### Error Recovery Mechanisms

#### 1. Graceful Degradation for Partial Failures

**Research Phase Pattern** (coordinate.md):
- Continues if ≥50% of parallel agents succeed
- Partial success handling via handle_partial_failure()
- Separate tracking of successful vs failed operations

**Implementation**:
```bash
# After parallel agent invocations
PARTIAL_RESULT=$(handle_partial_failure "$AGGREGATION_JSON")
CAN_CONTINUE=$(echo "$PARTIAL_RESULT" | jq -r '.can_continue')

if [ "$CAN_CONTINUE" = "true" ]; then
  # Extract successful operations
  SUCCESSFUL_REPORTS=$(echo "$PARTIAL_RESULT" | jq -r '.successful_operations')
  # Proceed with available data
else
  # All agents failed - fail-fast
  handle_state_error "All research agents failed" 1
fi
```

**Rationale**:
- Research phase uses redundancy (multiple agents, overlapping focus areas)
- Partial success still provides value for planning
- Other phases (planning, implementation) use single-agent execution where failure indicates fundamental issues

#### 2. Retry Logic with Exponential Backoff

**Transient Error Handling**:
- Network errors: 3 retries with exponential backoff (1s, 2s, 4s)
- File access errors: 2 retries with 500ms delay
- Search timeouts: 1 retry with simplified pattern

**Implementation** (error-handling.sh:247-273):
```bash
retry_with_backoff() {
  local max_attempts="${1:-3}"
  local base_delay_ms="${2:-500}"
  shift 2
  local command=("$@")

  local attempt=1
  local delay_ms=$base_delay_ms

  while [ $attempt -le $max_attempts ]; do
    if "${command[@]}" 2>/dev/null; then
      return 0
    fi

    if [ $attempt -lt $max_attempts ]; then
      echo "Attempt $attempt failed, retrying in ${delay_ms}ms..." >&2
      sleep $(bc <<< "scale=3; $delay_ms / 1000")
      delay_ms=$((delay_ms * 2))
      attempt=$((attempt + 1))
    else
      echo "All $max_attempts attempts failed" >&2
      return 1
    fi
  done
}
```

**Usage Example**:
```bash
# Retry web search with backoff
retry_with_backoff 3 500 WebSearch "authentication patterns 2025"
```

#### 3. State-Aware Retry Tracking

**handle_state_error() Implementation** (error-handling.sh:767-858):

**Retry Counter Tracking**:
```bash
# Increment retry counter for current state
RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
RETRY_COUNT=$((RETRY_COUNT + 1))
append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"
```

**Max Retry Enforcement**:
```bash
if [ $RETRY_COUNT -ge 2 ]; then
  echo "Recommended action:"
  echo "  - Max retries (2) reached for state '$current_state'"
  echo "  - Manual intervention required"
  echo "  - Workflow cannot proceed automatically"
else
  echo "Recommended action:"
  echo "  - Retry $RETRY_COUNT/2 available"
  echo "  - Fix issue and re-run: /coordinate \"\${WORKFLOW_DESCRIPTION}\""
  echo "  - State machine will resume from failed state"
fi
```

**Benefits**:
- Prevents infinite retry loops
- Preserves retry state across workflow invocations
- Clear user guidance on retry vs manual intervention
- State-specific retry counters (research failures don't affect planning retries)

#### 4. Checkpoint Resume

**Checkpoint Schema** (checkpoint-utils.sh lines 23-152):
- Schema version 2.1 with state machine integration
- Error state tracking (last_error, retry_count, failed_state)
- Wave tracking for parallel execution resume
- Plan modification time for staleness detection

**Resume Pattern**:
```bash
# Check for existing checkpoint
CHECKPOINT=$(restore_checkpoint "coordinate" "$PROJECT_NAME")

if [ -n "$CHECKPOINT" ]; then
  # Extract resume state
  CURRENT_STATE=$(echo "$CHECKPOINT" | jq -r '.state_machine.current_state')
  RETRY_COUNT=$(echo "$CHECKPOINT" | jq -r '.error_state.retry_count')

  if [ $RETRY_COUNT -lt 2 ]; then
    echo "Resuming from state: $CURRENT_STATE (retry $RETRY_COUNT/2)"
    # Resume workflow
  else
    echo "Max retries reached, cannot auto-resume"
    exit 1
  fi
fi
```

### Diagnostic Improvements

#### 1. Five-Component Error Message Format

**Pattern** (handle_state_error in error-handling.sh):

**Component 1: What Failed**
```
✗ ERROR in state 'research': Research phase failed verification - 1 reports not created
```

**Component 2: Expected Behavior**
```
Expected behavior:
  - All research agents should complete successfully
  - All report files created in $TOPIC_PATH/reports/
```

**Component 3: Diagnostic Commands**
```
Diagnostic commands:
  # Check workflow state
  cat "$STATE_FILE"

  # Check topic directory
  ls -la "${TOPIC_PATH:-<not set>}"

  # Check library sourcing
  bash -n "${LIB_DIR}/workflow-state-machine.sh"
```

**Component 4: Context**
```
Context:
  - Workflow: implement OAuth2 authentication
  - Scope: full-implementation
  - Current State: research
  - Terminal State: document
  - Topic Path: /path/to/specs/042_oauth2
```

**Component 5: Recommended Action**
```
Recommended action:
  - Retry 1/2 available for state 'research'
  - Fix issue and re-run: /coordinate "implement OAuth2 authentication"
  - State machine will resume from failed state
```

**Benefits**:
- Faster troubleshooting (all info in one place)
- Clear action items (diagnostic commands copy-paste ready)
- Context preservation (workflow details included)
- Retry guidance (automatic vs manual intervention)

#### 2. Enhanced Directory Diagnostics

**verify_file_created() Enhancement** (verification-helpers.sh:103-150):

**Directory Analysis**:
- File count in parent directory
- Recent files with metadata (size, modification time)
- Pattern matching (highlights files matching expected pattern)
- Root cause analysis suggestions

**Example Output**:
```
Directory Analysis:
  Parent directory: /path/to/specs/042_topic/reports
  Directory status: ✓ Exists (3 files)

  Files found in directory:
     - 001_authentication_patterns.md (size: 4.2K, modified: Nov 14 10:30)
     - 002_security_analysis.md (size: 3.8K, modified: Nov 14 10:35)
     - 003_implementation_guide.md (size: 5.1K, modified: Nov 14 10:40)

  Possible causes:
    1. Agent created descriptive filename instead of generic name
    2. Dynamic path discovery executed after verification
    3. State persistence incomplete (REPORT_PATHS array not populated)
```

#### 3. Troubleshooting Command Library

**Common Diagnostic Commands**:

**State File Inspection**:
```bash
# View complete state file
cat "$STATE_FILE"

# Check specific variable
grep "WORKFLOW_SCOPE" "$STATE_FILE"

# Verify export format
grep "^export" "$STATE_FILE"
```

**Topic Directory Validation**:
```bash
# List topic directory contents
ls -la "${TOPIC_PATH}"

# Check subdirectory structure
ls -la "${TOPIC_PATH}/reports"
ls -la "${TOPIC_PATH}/plans"

# Find actual files created
find "${TOPIC_PATH}" -name "*.md" -type f -mtime -1
```

**Agent Completion Verification**:
```bash
# Check agent completion signals
grep -r "REPORT_CREATED:" "${CLAUDE_PROJECT_DIR}/.claude/tmp/"

# Check for error messages
grep -r "ERROR:" "${CLAUDE_PROJECT_DIR}/.claude/tmp/"
```

**Library Function Availability**:
```bash
# Verify library sourced
command -v verify_file_created &>/dev/null && echo "✓ Available"

# List available functions
declare -F | grep verify_

# Check library syntax
bash -n "${LIB_DIR}/verification-helpers.sh"
```

### Common Error Scenarios and Solutions

#### 1. Unbound Variable Errors

**Symptom**: `bash: VARIABLE_NAME: unbound variable`

**Root Causes**:
1. Variable not persisted to state file
2. State file not loaded in current bash block
3. Library sourcing order violation
4. Subprocess export isolation

**Solutions**:

**Prevention Pattern**:
```bash
# After setting critical variable
append_workflow_state "VARIABLE_NAME" "$VARIABLE_VALUE"

# Immediate verification
verify_state_variable "VARIABLE_NAME" || {
  handle_state_error "CRITICAL: VARIABLE_NAME not persisted" 1
}
```

**Diagnostic Pattern**:
```bash
# Check if variable set
echo "${VARIABLE_NAME:-NOT SET}"

# Check state file
grep "VARIABLE_NAME" "$STATE_FILE"

# Verify state file loaded
echo "${STATE_FILE:-STATE FILE NOT LOADED}"
```

#### 2. State File Not Found

**Symptom**: `grep: /path/to/state: No such file or directory`

**Root Causes**:
1. State file not initialized in first bash block
2. Workflow ID file missing or corrupted
3. Premature EXIT trap cleanup
4. File system issues

**Solutions**:

**Fail-Fast Detection** (verification-helpers.sh:308-320):
```bash
verify_state_variables() {
  local state_file="$1"

  # Defensive check before grep
  if [ ! -f "$state_file" ]; then
    echo "✗ ERROR: State file does not exist"
    echo "   Expected path: $state_file"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  1. Verify init_workflow_state() was called"
    echo "  2. Check STATE_FILE variable saved to state"
    echo "  3. Verify workflow ID file exists"
    echo "  4. Ensure no premature cleanup"
    return 1
  fi
  # ... continue with verification
}
```

**Recovery Pattern**:
```bash
# Check state file existence defensively
if [ ! -f "$STATE_FILE" ]; then
  # Attempt recovery via workflow ID discovery
  WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt" 2>/dev/null)

  if [ -n "$WORKFLOW_ID" ]; then
    STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

    if [ -f "$STATE_FILE" ]; then
      source "$STATE_FILE"
    else
      handle_state_error "State file missing, cannot recover" 1
    fi
  else
    handle_state_error "Workflow ID file missing, cannot recover" 1
  fi
fi
```

#### 3. Agent Failed to Create Expected File

**Symptom**: `ERROR: Agent failed to create expected file`

**Root Causes**:
1. Agent behavioral file missing/incorrect
2. Path calculation error
3. File system permissions
4. Agent misinterpreted instructions

**Solutions**:

**Enhanced Verification** (verification-helpers.sh:73-170):
```bash
verify_file_created() {
  # ... file existence check ...

  if [ ! -f "$file_path" ]; then
    echo "Status: File does not exist"

    # Show actual files in directory
    if [ -d "$dir" ]; then
      echo "Files found in directory:"
      ls -lht "$dir" | head -6 | tail -n +2
    fi

    # Root cause analysis
    echo "Possible causes:"
    echo "  1. Agent created descriptive filename"
    echo "  2. Wrong topic directory calculated"
    echo "  3. Agent failed to execute file creation"

    return 1
  fi
}
```

**Diagnostic Commands**:
```bash
# Check agent behavioral file
ls -la .claude/agents/research-specialist.md

# Check topic directory permissions
ls -ld "${TOPIC_PATH}"
ls -ld "${TOPIC_PATH}/reports"

# Verify path calculation
echo "REPORT_PATH: $REPORT_PATH"
echo "TOPIC_PATH: $TOPIC_PATH"

# Check dynamic discovery results
ls -la "${TOPIC_PATH}/reports/"
```

## Recommendations

### 1. Expand State Variable Verification Coverage

**Current State**: 69 verification checkpoints in coordinate.md

**Gaps Identified**:
- Array variables (REPORT_PATHS) verified via count but not content
- Intermediate calculations not always verified before use
- Some state transitions lack pre-validation

**Recommended Pattern**:
```bash
# After array export to state
for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
  verify_state_variable "REPORT_PATH_${i}" || {
    handle_state_error "Report path $i not persisted" 1
  }
done

# After critical calculations
verify_state_variable "RESEARCH_COMPLEXITY" || {
  handle_state_error "RESEARCH_COMPLEXITY not available" 1
}

# Before state-dependent operations
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  verify_state_variable "EXISTING_PLAN_PATH" || {
    handle_state_error "EXISTING_PLAN_PATH required but not set" 1
  }
fi
```

**Benefits**:
- Earlier error detection (fail before operations, not during)
- Clear failure points (know exactly which variable caused error)
- Better diagnostic context (state verification shows expected format)

### 2. Implement Defensive Array Reconstruction

**Current Pattern** (Spec 672 Phase 4):
```bash
reconstruct_array_from_indexed_vars() {
  local array_name="$1"
  local count_var_name="$2"
  local var_prefix="${3:-${array_name%S}}"

  # Defensive: Default to 0 if count unset
  local count="${!count_var_name:-0}"

  # Clear target array
  eval "${array_name}=()"

  # Reconstruct with defensive checks
  for ((i=0; i<count; i++)); do
    local var_name="${var_prefix}_${i}"

    # Defensive: Check if indexed variable exists
    if [ -n "${!var_name+x}" ]; then
      eval "${array_name}+=(\"${!var_name}\")"
    else
      echo "WARNING: $var_name missing (expected $count elements)" >&2
    fi
  done
}
```

**Usage**:
```bash
# Reconstruct REPORT_PATHS array from state
reconstruct_array_from_indexed_vars "REPORT_PATHS" "REPORT_PATHS_COUNT" "REPORT_PATH"

# Verify reconstruction succeeded
if [ ${#REPORT_PATHS[@]} -ne $REPORT_PATHS_COUNT ]; then
  handle_state_error "Array reconstruction incomplete: ${#REPORT_PATHS[@]}/$REPORT_PATHS_COUNT" 1
fi
```

**Benefits**:
- Prevents unbound variable errors during reconstruction
- Graceful degradation (warns about missing elements)
- Clear diagnostic output (shows expected vs actual counts)

### 3. Enhance Graceful Error Recovery

**Partial Failure Continuation**:

Current research phase pattern (≥50% success) should extend to:
- Implementation waves (continue if ≥60% of wave phases succeed)
- Testing phases (continue with partial test coverage)
- Documentation updates (continue if core docs updated)

**Recommended Enhancement**:
```bash
# Generic partial failure handler
handle_workflow_partial_failure() {
  local phase_name="$1"
  local success_count="$2"
  local total_count="$3"
  local min_success_threshold="${4:-0.5}"  # Default 50%

  local success_rate=$(bc <<< "scale=2; $success_count / $total_count")

  if (( $(bc <<< "$success_rate >= $min_success_threshold") )); then
    echo "✓ Partial success: $success_count/$total_count ($success_rate)"
    echo "  Phase: $phase_name"
    echo "  Continuing with available results"
    return 0
  else
    echo "✗ Insufficient success: $success_count/$total_count ($success_rate)"
    echo "  Phase: $phase_name"
    echo "  Threshold: $min_success_threshold"
    handle_state_error "$phase_name failed below threshold" 1
  fi
}

# Usage in implementation wave
handle_workflow_partial_failure "Implementation Wave 2" 2 3 0.6
# Returns 0 if 2/3 >= 0.6 (66.7% >= 60%)
```

**Phase-Specific Thresholds**:
- Research: 50% (redundant agents, exploratory)
- Implementation waves: 60% (core functionality must succeed)
- Testing: 80% (critical for quality assurance)
- Documentation: 70% (key docs required)

### 4. Add State Transition Guards

**Pre-Transition Validation**:
```bash
# Before transitioning to plan state
validate_transition_to_plan() {
  # Check prerequisites
  verify_state_variable "RESEARCH_COMPLETE" || return 1
  verify_state_variable "REPORT_PATHS_COUNT" || return 1

  # Check filesystem state
  if [ ! -d "${TOPIC_PATH}/reports" ]; then
    echo "ERROR: Reports directory missing" >&2
    return 1
  fi

  # Check report count matches expectation
  local actual_count=$(ls -1 "${TOPIC_PATH}/reports"/*.md 2>/dev/null | wc -l)
  if [ $actual_count -lt $REPORT_PATHS_COUNT ]; then
    echo "ERROR: Expected $REPORT_PATHS_COUNT reports, found $actual_count" >&2
    return 1
  fi

  return 0
}

# Use before transition
if validate_transition_to_plan; then
  sm_transition "$STATE_PLAN"
else
  handle_state_error "Cannot transition to plan: prerequisites not met" 1
fi
```

**Benefits**:
- Prevents invalid state transitions
- Clear prerequisite validation
- Early error detection before state changes
- Comprehensive diagnostic context

### 5. Implement Diagnostic Command Helpers

**Quick Diagnostic Functions**:
```bash
# diagnose_coordinate_state: Print complete workflow state
diagnose_coordinate_state() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Coordinate Workflow Diagnostic"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "State Variables:"
  echo "  WORKFLOW_ID: ${WORKFLOW_ID:-NOT SET}"
  echo "  WORKFLOW_SCOPE: ${WORKFLOW_SCOPE:-NOT SET}"
  echo "  CURRENT_STATE: ${CURRENT_STATE:-NOT SET}"
  echo "  TOPIC_PATH: ${TOPIC_PATH:-NOT SET}"
  echo "  REPORT_PATHS_COUNT: ${REPORT_PATHS_COUNT:-NOT SET}"
  echo ""

  echo "State File:"
  echo "  Path: ${STATE_FILE:-NOT SET}"
  if [ -f "${STATE_FILE:-}" ]; then
    echo "  Status: ✓ Exists"
    echo "  Size: $(stat -c%s "$STATE_FILE" 2>/dev/null || echo "unknown") bytes"
    echo "  Variables: $(grep -c '^export' "$STATE_FILE" 2>/dev/null || echo 0)"
  else
    echo "  Status: ✗ Missing"
  fi
  echo ""

  echo "Topic Directory:"
  if [ -d "${TOPIC_PATH:-}" ]; then
    echo "  Path: $TOPIC_PATH"
    echo "  Status: ✓ Exists"
    echo "  Reports: $(ls -1 "$TOPIC_PATH/reports"/*.md 2>/dev/null | wc -l)"
    echo "  Plans: $(ls -1 "$TOPIC_PATH/plans"/*.md 2>/dev/null | wc -l)"
  else
    echo "  Status: ✗ Not set or missing"
  fi
  echo ""

  echo "Recent Errors:"
  if [ -f "${STATE_FILE:-}" ]; then
    grep "LAST_ERROR" "$STATE_FILE" 2>/dev/null || echo "  None recorded"
  else
    echo "  State file not available"
  fi
}

# diagnose_library_functions: Check library availability
diagnose_library_functions() {
  echo "Library Function Availability:"

  local functions=(
    "verify_file_created"
    "verify_state_variable"
    "handle_state_error"
    "sm_init"
    "sm_transition"
    "append_workflow_state"
  )

  for func in "${functions[@]}"; do
    if command -v "$func" &>/dev/null; then
      echo "  ✓ $func"
    else
      echo "  ✗ $func (NOT AVAILABLE)"
    fi
  done
}

# Export for use in error contexts
export -f diagnose_coordinate_state
export -f diagnose_library_functions
```

**Usage in Error Handler**:
```bash
handle_state_error() {
  local error_message="$1"

  # ... standard error message ...

  echo "DIAGNOSTIC OUTPUT:"
  diagnose_coordinate_state
  diagnose_library_functions

  exit 1
}
```

### 6. Add Verification Checkpoint Summary

**Checkpoint Summary Reporter**:
```bash
# report_verification_summary: Show verification checkpoint status
report_verification_summary() {
  local phase_name="$1"
  local total_checks="$2"
  local passed_checks="$3"
  local failed_checks=$((total_checks - passed_checks))

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Verification Summary: $phase_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Total Checkpoints: $total_checks"
  echo "Passed: $passed_checks ($(bc <<< "scale=1; 100 * $passed_checks / $total_checks")%)"

  if [ $failed_checks -gt 0 ]; then
    echo "Failed: $failed_checks ($(bc <<< "scale=1; 100 * $failed_checks / $total_checks")%)"
    echo ""
    echo "Status: ✗ VERIFICATION FAILED"
  else
    echo "Failed: 0"
    echo ""
    echo "Status: ✓ ALL CHECKS PASSED"
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}
```

**Usage After Verification Loop**:
```bash
# Research phase verification
PASSED_COUNT=0
FAILED_COUNT=0

for i in $(seq 1 $REPORT_PATHS_COUNT); do
  if verify_file_created "${REPORT_PATHS[$i]}" "Report $i" "Research"; then
    ((PASSED_COUNT++))
  else
    ((FAILED_COUNT++))
  fi
done

# Show summary
report_verification_summary "Research Phase" $REPORT_PATHS_COUNT $PASSED_COUNT

# Fail-fast if any failed
if [ $FAILED_COUNT -gt 0 ]; then
  handle_state_error "Research verification failed: $FAILED_COUNT/$REPORT_PATHS_COUNT reports missing" 1
fi
```

## References

**Core Libraries**:
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (514 lines)
  - verify_file_created() (lines 73-170)
  - verify_state_variable() (lines 223-280)
  - verify_state_variables() (lines 302-370)
  - verify_files_batch() (lines 420-513)

- `/home/benjamin/.config/.claude/lib/error-handling.sh` (882 lines)
  - classify_error() (lines 33-55)
  - suggest_recovery() (lines 61-84)
  - detect_error_type() (lines 94-141)
  - generate_suggestions() (lines 164-237)
  - retry_with_backoff() (lines 247-273)
  - handle_state_error() (lines 767-858)

- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (200+ lines)
  - save_checkpoint() (lines 58-186)
  - restore_checkpoint() (lines 188-200+)
  - Checkpoint schema v2.1 (lines 23-152)

- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (200+ lines)
  - init_workflow_state() (lines 117-144)
  - load_workflow_state() (lines 187-200+)
  - append_workflow_state() (documented in header)

**Documentation**:
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` (2,380 lines)
  - Troubleshooting section (lines 1299-2174)
  - State management patterns (lines 2176-2369)
  - Error handling examples throughout

- `/home/benjamin/.config/.claude/commands/coordinate.md` (primary implementation)
  - 69 verification checkpoint invocations
  - State machine integration
  - Multi-block bash patterns

**Related Specifications**:
- Spec 652: State transition validation and error diagnostics
- Spec 661: State persistence and library sourcing fixes
- Spec 672 Phase 4: State variable verification and concurrent workflow isolation
- Spec 687: Research complexity recalculation bug fix
- Spec 688: LLM-specific error types
