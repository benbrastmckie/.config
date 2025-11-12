# Error Handling Integration in State-Based Orchestration

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Error Handling Integration in State-Based Orchestration
- **Report Type**: Infrastructure analysis

## Executive Summary

Error handling in state-based orchestration is provided by `handle_state_error()` function (error-handling.sh:740-851) which integrates with workflow-state-machine.sh through state persistence and retry tracking. The function uses a five-component diagnostic format and requires error-handling.sh and state-persistence.sh libraries to be sourced. The pattern is used throughout /coordinate command at lines 162, 167, 209, 239, and 247 for fail-fast error detection with workflow context.

## Findings

### 1. handle_state_error() Function Definition

**Location**: `/home/benjamin/.config/.claude/lib/error-handling.sh` lines 740-851

**Function Signature**:
```bash
handle_state_error() {
  local error_message="$1"
  local current_state="${CURRENT_STATE:-unknown}"
  local exit_code="${2:-1}"
```

**Key Features**:
- **State-aware error messages**: Uses `CURRENT_STATE` variable from state machine context
- **Five-component diagnostic format**:
  1. What failed (line 767)
  2. Expected state/behavior (lines 771-788)
  3. Diagnostic commands (lines 792-802)
  4. Context (workflow phase, state) (lines 805-812)
  5. Recommended action (lines 826-841)
- **Retry counter tracking**: Max 2 retries per state enforced (lines 819-823)
- **State persistence**: Saves failed state and retry counts to workflow state (lines 814-823)
- **Workflow context**: Displays `WORKFLOW_DESCRIPTION`, `WORKFLOW_SCOPE`, `TERMINAL_STATE`, `TOPIC_PATH` (lines 806-810)

**Example Output Structure** (error-handling.sh:765-850):
```
✗ ERROR in state 'research': Research phase failed verification - 1 reports not created

Expected behavior:
  - All research agents should complete successfully
  - All report files created in $TOPIC_PATH/reports/

Diagnostic commands:
  # Check workflow state
  cat "$STATE_FILE"

  # Check topic directory
  ls -la "${TOPIC_PATH:-<not set>}"

  # Check library sourcing
  bash -n "${LIB_DIR}/workflow-state-machine.sh"

Context:
  - Workflow: <description>
  - Scope: <scope>
  - Current State: research
  - Terminal State: <terminal>
  - Topic Path: <path>

Recommended action:
  - Retry 0/2 available for state 'research'
  - Fix the issue identified in diagnostic output
  - Re-run: /coordinate "<workflow-description>"
  - State machine will resume from failed state
```

### 2. Library Dependency Chain

**Required Libraries**:

1. **error-handling.sh** (primary): Defines `handle_state_error()` function
2. **state-persistence.sh** (dependency): Provides `append_workflow_state()` for retry counter tracking (line 816-823)
3. **workflow-state-machine.sh** (context): Provides `CURRENT_STATE` variable (line 762)

**Sourcing Order** (from coordinate.md lines 88-105):
```bash
# 1. State machine library (provides CURRENT_STATE)
source "${LIB_DIR}/workflow-state-machine.sh"

# 2. State persistence library (provides append_workflow_state)
source "${LIB_DIR}/state-persistence.sh"

# 3. Error handling library (provides handle_state_error)
source "${LIB_DIR}/error-handling.sh"
```

**Critical**: error-handling.sh depends on:
- `append_workflow_state()` function (state-persistence.sh)
- `CURRENT_STATE` variable (workflow-state-machine.sh)
- `WORKFLOW_DESCRIPTION`, `WORKFLOW_SCOPE`, `TERMINAL_STATE`, `TOPIC_PATH` variables (set by workflow initialization)

**Source Guards**: All libraries use source guards to prevent multiple sourcing (error-handling.sh:6-9):
```bash
if [ -n "${ERROR_HANDLING_SOURCED:-}" ]; then
  return 0
fi
export ERROR_HANDLING_SOURCED=1
```

### 3. State Machine Integration

**State Persistence Coordination** (error-handling.sh:814-823):

The function saves error context to workflow state file for resume capability:

```bash
if command -v append_workflow_state &>/dev/null; then
  append_workflow_state "FAILED_STATE" "$current_state"
  append_workflow_state "LAST_ERROR" "$error_message"

  # Increment retry counter for this state
  RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
  RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
  RETRY_COUNT=$((RETRY_COUNT + 1))
  append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"
```

**Retry Logic**:
- Maximum 2 retries per state (line 826)
- Retry counter format: `RETRY_COUNT_research`, `RETRY_COUNT_plan`, etc.
- State-specific counters prevent cross-state retry pollution
- After max retries, recommends manual investigation (lines 827-832)

**State Machine Context Variables** (used by error messages):
- `CURRENT_STATE`: Current state machine state (from workflow-state-machine.sh line 68)
- `WORKFLOW_DESCRIPTION`: User-provided workflow description (line 806)
- `WORKFLOW_SCOPE`: Detected workflow scope (research-only, full-implementation, etc.) (line 807)
- `TERMINAL_STATE`: Target terminal state for this workflow (line 809)
- `TOPIC_PATH`: Artifact directory path (line 810)

### 4. Usage Pattern in /coordinate Command

**Locations in coordinate.md**:

1. **Line 162**: Extracted plan path validation for research-and-revise workflows
   ```bash
   if [ ! -f "$EXISTING_PLAN_PATH" ]; then
     handle_state_error "Extracted plan path does not exist: $EXISTING_PLAN_PATH" 1
   fi
   ```

2. **Line 167**: Missing plan path in workflow description
   ```bash
   handle_state_error "research-and-revise workflow requires plan path in description" 1
   ```

3. **Line 209**: Workflow initialization failure
   ```bash
   if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
     : # Success
   else
     handle_state_error "Workflow initialization failed" 1
   fi
   ```

4. **Line 239**: TOPIC_PATH validation after initialization
   ```bash
   if [ -z "${TOPIC_PATH:-}" ]; then
     handle_state_error "TOPIC_PATH not set after workflow initialization (bug in initialize_workflow_paths)" 1
   fi
   ```

5. **Lines 178, 186, 238**: Verification checkpoint failures
   ```bash
   verify_state_variable "WORKFLOW_SCOPE" || {
     handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
   }
   ```

**Common Pattern**:
```bash
# Condition check
if [ failure_condition ]; then
  handle_state_error "Descriptive error message with context" 1
fi

# Or with validation checkpoint
verify_critical_condition || {
  handle_state_error "CRITICAL: Detailed failure description" 1
}
```

### 5. Error Classification and Recovery

**Error Classification System** (error-handling.sh:16-48):

Three error types defined:
- `ERROR_TYPE_TRANSIENT="transient"`: Temporary issues (locked files, timeouts) - retry recommended
- `ERROR_TYPE_PERMANENT="permanent"`: Code-level issues - fix and retry
- `ERROR_TYPE_FATAL="fatal"`: Environment issues (disk full, permissions) - user intervention required

**Classification Logic** (error-handling.sh:26-48):
```bash
classify_error() {
  local error_message="${1:-}"

  # Transient: locked|busy|timeout|temporary|unavailable
  if echo "$error_message" | grep -qiE "locked|busy|timeout|temporary|unavailable"; then
    echo "$ERROR_TYPE_TRANSIENT"
    return
  fi

  # Fatal: out of space|disk full|permission denied|no such file|corrupted
  if echo "$error_message" | grep -qiE "out of.*space|disk.*full|permission.*denied|no such file|corrupted"; then
    echo "$ERROR_TYPE_FATAL"
    return
  fi

  # Default: permanent (code-level issues)
  echo "$ERROR_TYPE_PERMANENT"
}
```

**Recovery Suggestions** (error-handling.sh:54-77):
- Transient: "Retry with exponential backoff (2-3 attempts)"
- Permanent: "Analyze error message for code-level issues", "Consider using /debug"
- Fatal: "User intervention required", "Check system resources"

### 6. Additional Error Handling Functions

**Retry with Backoff** (error-handling.sh:240-266):
```bash
retry_with_backoff() {
  local max_attempts="${1:-3}"
  local base_delay_ms="${2:-500}"
  shift 2
  local command=("$@")

  # Exponential backoff: 500ms → 1000ms → 2000ms
  # Used for transient errors
}
```

**Partial Failure Handling** (error-handling.sh:540-610):
```bash
handle_partial_failure() {
  local aggregation_json="${1:-}"

  # Processes parallel operation results
  # Separates successful and failed operations
  # Returns JSON with can_continue and requires_retry fields
}
```

**User Escalation** (error-handling.sh:392-479):
```bash
escalate_to_user() {
  local error_message="${1:-}"
  local recovery_suggestions="${2:-}"

  # Interactive error handling
  # Presents options to user
  # Returns user choice or default
}
```

### 7. Bootstrap Phase Considerations

**Function Availability Check** (error-handling.sh:814):
```bash
if command -v append_workflow_state &>/dev/null; then
  # Save state
else
  # Bootstrap phase - state persistence not available yet
  echo "Recommended action:"
  echo "  - Fix the issue identified in diagnostic output"
  echo "  - Re-run the workflow"
fi
```

**Bootstrap Behavior**:
- During initialization before state-persistence.sh is sourced, `append_workflow_state` may not exist
- Error handler gracefully degrades to basic error message without retry tracking
- Recommended for post-bootstrap errors only (after all libraries sourced)

### 8. Fail-Fast Philosophy

**Design Principle** (from CLAUDE.md section "development_philosophy"):
- Errors produce immediate, obvious bash errors
- Breaking changes break loudly with clear error messages
- No silent fallbacks or graceful degradation
- Missing files produce immediate bash errors

**Implementation in handle_state_error**:
- Always exits with non-zero code (default: 1)
- Never returns (line 850: `exit $exit_code`)
- Forces workflow to halt immediately
- Provides full diagnostic context before exit

**Example Error Message Structure**:
```
✗ ERROR in state 'plan': Plan file not created
  ↓ Component 1: What failed
Expected behavior:
  - Implementation plan should be created successfully
  ↓ Component 2: Expected state
Diagnostic commands:
  cat "$STATE_FILE"
  ↓ Component 3: Diagnostic commands
Context:
  - Workflow: Add authentication
  - Current State: plan
  ↓ Component 4: Context
Recommended action:
  - Review plan-architect agent output
  ↓ Component 5: Recommended action
```

### 9. Orchestrator-Specific Error Contexts

**Specialized Error Formatters** (error-handling.sh:635-735):

1. **Agent Invocation Failure** (lines 635-673):
   ```bash
   format_orchestrate_agent_failure() {
     local agent_type="${1:-unknown}"
     local workflow_phase="${2:-unknown}"
     local error_message="${3:-}"
     local checkpoint_path="${4:-}"

     # Returns formatted error with resume command
   }
   ```

2. **Test Failure** (lines 675-715):
   ```bash
   format_orchestrate_test_failure() {
     local workflow_phase="${1:-unknown}"
     local test_output="${2:-}"
     local checkpoint_path="${3:-}"

     # Includes error type detection, location extraction
     # Generates suggestions via generate_suggestions()
   }
   ```

3. **Phase Context** (lines 717-735):
   ```bash
   format_orchestrate_phase_context() {
     local base_error="${1:-}"
     local phase="${2:-unknown}"
     local agent_type="${3:-}"
     local params="${4:-}"

     # Prepends orchestrate context to any error
   }
   ```

**Use Case**: Orchestration commands can wrap generic errors with workflow-specific context

## Recommendations

### 1. Library Sourcing Best Practices

**Always source error-handling.sh after state-persistence.sh**:
```bash
# Correct order
source "${LIB_DIR}/workflow-state-machine.sh"  # Provides CURRENT_STATE
source "${LIB_DIR}/state-persistence.sh"       # Provides append_workflow_state
source "${LIB_DIR}/error-handling.sh"          # Provides handle_state_error
```

**Rationale**: handle_state_error() uses `append_workflow_state` function which must exist before error-handling.sh functions are called.

### 2. Error Message Guidelines

**Use descriptive, actionable error messages**:
```bash
# Good: Specific, includes context
handle_state_error "WORKFLOW_SCOPE not persisted to state after sm_init" 1

# Bad: Generic, no context
handle_state_error "State error" 1
```

**Include variable values in error messages**:
```bash
handle_state_error "TOPIC_PATH not set after workflow initialization (bug in initialize_workflow_paths)" 1
```

**Use CRITICAL prefix for severe failures**:
```bash
handle_state_error "CRITICAL: EXISTING_PLAN_PATH not persisted to state for research-and-revise workflow" 1
```

### 3. Verification Checkpoint Integration

**Pattern**: Combine verification helpers with handle_state_error for fail-fast validation:
```bash
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**Benefits**:
- Immediate failure detection
- Contextual error messages
- Automatic retry tracking
- Resume capability via state persistence

### 4. State-Specific Error Handling

**For each state, provide state-specific diagnostic guidance**:

The function already includes state-aware expected behavior (error-handling.sh:772-788):
- Research: "All research agents should complete successfully"
- Plan: "Implementation plan created successfully"
- Implement/test/debug/document: State-specific expectations

**Recommendation**: Orchestrators should set `CURRENT_STATE` before calling handle_state_error to get accurate diagnostic output.

### 5. Retry Strategy

**Use built-in retry tracking for recoverable errors**:
- State machine automatically tracks retry counts per state
- Max 2 retries prevents infinite loops
- Retry metadata saved to workflow state for resume

**Manual retry pattern**:
```bash
# State machine handles retry counting automatically
# Just re-run the workflow command
/coordinate "same workflow description"
```

**Escalation after max retries**: User must investigate logs and fix underlying issue.

### 6. Bootstrap Phase Error Handling

**During initialization (before state persistence available)**:
```bash
# Use simple error messages with exit
if [ critical_bootstrap_failure ]; then
  echo "ERROR: Critical initialization failure"
  echo "Details: ..."
  exit 1
fi
```

**After state persistence initialized**:
```bash
# Use handle_state_error for full diagnostic context
if [ post_bootstrap_failure ]; then
  handle_state_error "Detailed failure with retry tracking" 1
fi
```

## References

- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 740-851): handle_state_error function definition
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 6-9): Source guard pattern
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 16-48): Error classification system
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 240-266): Retry with backoff implementation
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (lines 540-610): Partial failure handling
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (lines 68): CURRENT_STATE variable definition
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`: append_workflow_state function
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 88-105): Library sourcing order
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 162, 167, 209, 239): handle_state_error usage examples
- `/home/benjamin/.config/.claude/specs/coordinate_output.md` (lines 162, 167, 239): Error examples in context
- `/home/benjamin/.config/CLAUDE.md` (section "development_philosophy"): Fail-fast policy documentation
