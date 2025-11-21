# Debug Strategy Plan: /plan Command Error Resolution

## Plan Metadata
- **Plan Type**: Debug strategy
- **Workflow**: debug-only
- **Complexity**: 3
- **Output Path**: /home/benjamin/.config/.claude/specs/890_plan_command_error_debug_infrastructure/plans/001_debug_strategy.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/890_plan_command_error_debug_infrastructure/reports/001_root_cause_analysis.md
- **Target**: Resolve 11 errors (81% from 3 root causes) affecting /plan command

## Executive Summary

This debug strategy addresses systematic failures in the /plan command that caused 11 errors across 5 workflows (100% failure rate). The errors stem from three infrastructure gaps:

1. **State Management Failures (27%)**: Missing state-persistence.sh sourcing in Block 1c
2. **Topic Naming Agent Failures (27%, 100% agent failure rate)**: No output file validation
3. **Environment Initialization Failures (27%)**: Non-portable bashrc sourcing on NixOS

The strategy provides immediate fixes (resolve 81% of errors), infrastructure improvements (library sourcing helper, agent validation framework), comprehensive testing (unit, integration, regression), and documentation updates.

**Impact**: Resolves all identified root causes while improving system-wide reliability through reusable infrastructure components.

## Root Cause Summary

### Root Cause 1: Incomplete Library Sourcing in Block 1c
**Severity**: HIGH | **Occurrence**: 27% of errors (3/11)

**Symptom**: `append_workflow_state: command not found` at lines 319, 183, 323

**Root Cause Chain**:
- Block 1c attempts to call `append_workflow_state()` without sourcing state-persistence.sh
- Each bash block runs in separate subprocess - Block 1a sourcing not inherited
- Block 1c only sources error-handling.sh and workflow-initialization.sh (missing state-persistence.sh)
- Function defined in state-persistence.sh (v1.5.0), not workflow-initialization.sh

**Evidence**:
- Block 1a (lines 119-120): Sources state-persistence.sh correctly
- Block 1c (lines 325-326): Missing state-persistence.sh sourcing
- Block 1c (line 422): Calls append_workflow_state() from un-sourced library

### Root Cause 2: Topic Naming Agent Output File Not Created
**Severity**: HIGH | **Occurrence**: 27% of errors (3/11), 100% agent failure rate (3/3 attempts)

**Symptom**: `agent_error: Topic naming agent failed or returned invalid name` with `fallback_reason: agent_no_output_file`

**Root Cause Chain**:
- Agent completes Task invocation successfully (no error signal from Task tool)
- Block 1c checks for output file at `${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt`
- File does not exist - agent did not write output despite successful completion
- No validation in Block 1b verifies agent actually wrote file after Task completion

**Failure Modes**:
1. **Write Tool Failure** (most likely): Agent invokes Write tool but tool fails (permissions, disk space, path issues) - agent does not return TASK_ERROR on Write failure
2. **Path Variable Substitution**: `${HOME}` or `${WORKFLOW_ID}` not correctly substituted in Task prompt
3. **Agent Output Format Violation**: Agent writes file with incorrect format triggering validation failure

### Root Cause 3: Non-Portable Shell Initialization
**Severity**: MEDIUM | **Occurrence**: 27% of errors (3/11)

**Symptom**: `Bash error at line 1: exit code 127` with `. /etc/bashrc` command failed

**Root Cause Chain**:
- `/etc/bashrc` does not exist on NixOS system (uses `/etc/bash.bashrc` or per-user `~/.bashrc`)
- Exit code 127 indicates "command not found" (for sourcing, means file does not exist)
- No existence check before sourcing (should use `[[ -f /etc/bashrc ]] && . /etc/bashrc`)
- With `set -e`, non-existent file sourcing terminates script immediately

**System Context**: NixOS uses different shell initialization paths than standard Linux distributions

## Implementation Plan

### Phase 1: Immediate Fixes (HIGH PRIORITY) [COMPLETE]
**Goal**: Resolve 81% of errors (9/11) through targeted fixes
**Duration**: 1-2 hours
**Dependencies**: None

#### Stage 1.1: Fix Missing Library Sourcing in Block 1c
**Impact**: Resolves 27% of errors (3/11) - append_workflow_state failures
**Effort**: LOW (5 minutes) | **Risk**: LOW

**Changes Required**:
```bash
# File: .claude/commands/plan.md
# Location: Block 1c, line 325 (after error-handling.sh sourcing)
# Current:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null

# Add:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
```

**Rationale**: Block 1c calls append_workflow_state() at line 422 (14 times) but never sources the library that defines it. Block 1a sources it correctly, but subprocess isolation means Block 1c must source it independently.

**Validation Test**:
```bash
# Execute /plan command and verify no "command not found" errors
/plan "test feature description for library sourcing fix"

# Check error log for execution_error related to append_workflow_state
/errors --command /plan --type execution_error --since 5m --limit 5
# Expected: No append_workflow_state errors
```

**Success Criteria**:
- Block 1c executes without exit code 127 on append_workflow_state
- All 14 state variables successfully persisted to state file
- Error log shows 0 "command not found" errors for this workflow

#### Stage 1.2: Add Agent Output Validation to Block 1b
**Impact**: Enables debugging of 100% agent failure rate (3/3) - topic naming agent
**Effort**: MEDIUM (30 minutes) | **Risk**: LOW

**Changes Required**:

**File 1: .claude/lib/core/error-handling.sh**
Add agent output validation helper function:
```bash
# Validate agent created expected output file
# Usage: validate_agent_output <agent_name> <expected_file> [timeout_seconds]
# Returns: 0 if file exists and non-empty, 1 otherwise
validate_agent_output() {
  local agent_name="$1"
  local expected_file="$2"
  local timeout_seconds="${3:-5}"

  local elapsed=0
  while [ $elapsed -lt $timeout_seconds ]; do
    if [ -f "$expected_file" ] && [ -s "$expected_file" ]; then
      return 0  # Success: file exists and non-empty
    fi
    sleep 0.5
    elapsed=$((elapsed + 1))
  done

  # Timeout: file not created
  log_command_error \
    "${COMMAND_NAME:-/unknown}" \
    "${WORKFLOW_ID:-unknown}" \
    "${USER_ARGS:-}" \
    "agent_error" \
    "Agent $agent_name did not create output file within ${timeout_seconds}s" \
    "agent_validation" \
    "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" '{agent: $agent, expected_file: $file}')"

  return 1
}
```

**File 2: .claude/commands/plan.md**
Add validation after Block 1b Task invocation:
```markdown
## Block 1b: Generate Semantic Topic Directory Name

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  ...
}

**EXECUTE NOW**: Validate agent output file was created.

```bash
set +H  # CRITICAL: Disable history expansion

# Load state for validation
WORKFLOW_STATE_FILE="${HOME}/.claude/tmp/workflow_plan_${WORKFLOW_ID}.sh"
if [ -f "$WORKFLOW_STATE_FILE" ]; then
  set +u  # Allow unbound variables during source
  source "$WORKFLOW_STATE_FILE"
  set -u  # Re-enable strict mode
fi

# Source error handling library for validation
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/.config")}"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Set workflow metadata for error logging
COMMAND_NAME="/plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

# Validate topic naming agent output
TOPIC_NAME_FILE="${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"

if ! validate_agent_output "topic-naming-agent" "$TOPIC_NAME_FILE" 5; then
  echo "WARNING: Topic naming agent failed to create output file within 5s" >&2
  echo "         Falling back to 'no_name' directory structure" >&2
  echo "         Check error log for diagnostic details: /errors --type agent_error --limit 5" >&2
fi

echo "Agent output validation complete"
```
```

**Rationale**: Current workflow assumes Task completion guarantees file creation. Agent may complete "successfully" while Write tool fails internally. Validation detects failure immediately and provides diagnostic context for debugging.

**Validation Test**:
```bash
# Execute /plan command and check for agent validation output
/plan "test agent output validation with diagnostic logging"

# Check error log for agent diagnostic output if agent failed
/errors --type agent_error --command /plan --since 5m
# Expected: Detailed error with expected_file path if agent failed
```

**Success Criteria**:
- If agent fails to write file, error log contains diagnostic context (expected file path, agent name)
- Workflow continues with "no_name" fallback (graceful degradation)
- Validation completes within 5 seconds (prevents workflow hanging)
- Warning message guides user to check error log

#### Stage 1.3: Replace Bashrc Sourcing with Portable Pattern
**Impact**: Resolves 27% of errors (3/11) - bashrc sourcing failures on NixOS
**Effort**: LOW (15 minutes) | **Risk**: LOW

**Investigation Step**:
First, locate where bashrc sourcing occurs (error happens at "line 1" before Block 1a):
```bash
# Search for bashrc sourcing in codebase
grep -r "/etc/bashrc" .claude/lib/ .claude/commands/ 2>/dev/null

# Check error-handling.sh for bashrc sourcing in error trap setup
grep -A 20 "setup_bash_error_trap" .claude/lib/core/error-handling.sh
```

**Changes Required** (location TBD based on investigation):

**Option A: If in error-handling.sh setup_bash_error_trap()**
```bash
# File: .claude/lib/core/error-handling.sh
# Replace: . /etc/bashrc
# With: Portable pattern

# Portable shell initialization (NixOS, FreeBSD, macOS compatible)
for bashrc_path in /etc/bashrc /etc/bash.bashrc ~/.bashrc; do
  if [ -f "$bashrc_path" ]; then
    . "$bashrc_path" 2>/dev/null && break
  fi
done
```

**Option B: If in bash block subprocess initialization**
```bash
# Remove bashrc sourcing entirely if not essential for workflow execution
# OR make conditional with error suppression:
[[ -f /etc/bashrc ]] && . /etc/bashrc 2>/dev/null || true
```

**Rationale**: Hard-coded `/etc/bashrc` path assumes standard Linux directory structure. NixOS uses `/etc/bash.bashrc`. Portable pattern tries multiple locations in order, gracefully handling missing files.

**Validation Test**:
```bash
# Execute /plan command on NixOS system (current environment)
/plan "test portable shell initialization on NixOS"

# Check error log for bashrc sourcing errors
/errors --command /plan --type execution_error --since 5m | grep -i bashrc
# Expected: No bashrc-related errors
```

**Success Criteria**:
- No exit code 127 errors related to bashrc sourcing
- Workflow initializes successfully on NixOS
- Portable pattern supports FreeBSD, macOS (future compatibility)

**Phase 1 Completion Criteria**:
- All 3 immediate fixes implemented and validated
- Test suite passes for modified components (unit tests for each fix)
- Error log shows 0 occurrences of fixed error patterns for new workflows
- Documentation updated with fix details

---

### Phase 2: Infrastructure Improvements (MEDIUM PRIORITY) [COMPLETE]
**Goal**: System-wide reliability improvements through reusable components
**Duration**: 4-6 hours
**Dependencies**: Phase 1 complete

#### Stage 2.1: Create Library Sourcing Helper Function
**Impact**: Prevents future undefined function errors across all commands
**Effort**: MEDIUM (2-3 hours) | **Risk**: MEDIUM (requires updating all orchestrator commands)

**Rationale**: Manual library sourcing in each bash block creates maintenance burden and error-prone patterns. Block 1c missing state-persistence.sh is symptom of broader issue - no enforced checklist ensures required libraries sourced per block.

**Component**: Library Sourcing Helper
**File**: .claude/lib/core/source-libraries.sh

**Implementation**:
```bash
#!/usr/bin/env bash
# source-libraries.sh - Standardized library sourcing for bash blocks
# Version: 1.0.0

# Source guard: Prevent multiple sourcing
if [ -n "${SOURCE_LIBRARIES_SOURCED:-}" ]; then
  return 0
fi
export SOURCE_LIBRARIES_SOURCED=1

# Block-specific library sourcing profiles
# Ensures all required libraries loaded per block type
source_libraries_for_block() {
  local block_type="$1"  # init, state, agent, verify
  local claude_dir="${CLAUDE_PROJECT_DIR:-.}"

  case "$block_type" in
    init)
      # Block 1a: Initial setup and state creation
      source "${claude_dir}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/library-version-check.sh" 2>/dev/null || return 1
      ;;

    state)
      # Block 1c: State loading and path initialization
      source "${claude_dir}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || return 1
      ;;

    verify)
      # Block 2/3: Verification and completion
      source "${claude_dir}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${claude_dir}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || return 1
      ;;

    *)
      echo "ERROR: Unknown block type: $block_type" >&2
      echo "Valid types: init, state, verify" >&2
      return 1
      ;;
  esac

  return 0
}

# Validate required functions are available after sourcing
validate_sourced_functions() {
  local block_type="$1"
  local missing_functions=()

  case "$block_type" in
    init)
      local required=("log_command_error" "init_workflow_state" "append_workflow_state" "initialize_state_machine")
      ;;
    state)
      local required=("log_command_error" "load_workflow_state" "append_workflow_state" "initialize_workflow_paths")
      ;;
    verify)
      local required=("log_command_error" "load_workflow_state" "transition_state")
      ;;
    *)
      return 1
      ;;
  esac

  for func in "${required[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      missing_functions+=("$func")
    fi
  done

  if [ ${#missing_functions[@]} -gt 0 ]; then
    echo "ERROR: Required functions not available after sourcing: ${missing_functions[*]}" >&2
    return 1
  fi

  return 0
}
```

**Usage Pattern** (update all commands):
```bash
# Block 1c: Replace manual sourcing with helper
# OLD:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null

# NEW:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries.sh" 2>/dev/null || {
  echo "ERROR: Failed to load library sourcing helper" >&2
  exit 1
}

source_libraries_for_block "state" || {
  echo "ERROR: Failed to source required libraries for Block 1c" >&2
  exit 1
}

validate_sourced_functions "state" || {
  echo "ERROR: Required functions not available after sourcing" >&2
  exit 1
}
```

**Rollout Plan**:
1. Create source-libraries.sh with block profiles (init, state, verify)
2. Update /plan command to use helper (pilot)
3. Test /plan command thoroughly (unit + integration tests)
4. Update remaining orchestrator commands (/research, /debug, /revise, /build)
5. Add linting rule: All commands must use `source_libraries_for_block()`

**Validation Test**:
```bash
# Test library sourcing helper
bash -c "
  export CLAUDE_PROJECT_DIR=/home/benjamin/.config
  source .claude/lib/core/source-libraries.sh
  source_libraries_for_block 'state' || exit 1
  validate_sourced_functions 'state' || exit 1
  echo 'PASS: Library sourcing helper works correctly'
"

# Test integration with /plan command
/plan "test library sourcing helper integration"
/errors --command /plan --type execution_error --since 5m
# Expected: No "command not found" errors
```

**Documentation Updates**:
- Add library sourcing standard to `.claude/docs/reference/standards/command-reference.md`
- Document block types and required libraries per type
- Add troubleshooting guide for missing function errors

#### Stage 2.2: Implement Agent Output Validation Framework
**Impact**: Systematic solution for all agent integration failures (not just topic naming)
**Effort**: MEDIUM (2 hours) | **Risk**: LOW

**Rationale**: Topic naming agent 100% failure rate is symptom of broader gap - no validation framework verifies agent output exists and matches expected format. Framework should apply to all agent invocations.

**Component**: Agent Output Validation Framework
**File**: .claude/lib/core/error-handling.sh (extend existing)

**Implementation** (enhanced from Stage 1.2):
```bash
# Enhanced agent output validation with retry logic
# Usage: validate_agent_output_with_retry <agent_name> <expected_file> <format_validator> [timeout] [retries]
# Returns: 0 if file exists and passes validation, 1 otherwise
validate_agent_output_with_retry() {
  local agent_name="$1"
  local expected_file="$2"
  local format_validator="$3"  # Function name or "none"
  local timeout_seconds="${4:-5}"
  local max_retries="${5:-3}"

  for retry in $(seq 1 $max_retries); do
    local elapsed=0
    while [ $elapsed -lt $timeout_seconds ]; do
      if [ -f "$expected_file" ] && [ -s "$expected_file" ]; then
        # File exists and non-empty, validate format if validator provided
        if [ "$format_validator" != "none" ]; then
          if $format_validator "$expected_file"; then
            return 0  # Success: file exists and passes validation
          else
            log_command_error \
              "${COMMAND_NAME:-/unknown}" \
              "${WORKFLOW_ID:-unknown}" \
              "${USER_ARGS:-}" \
              "validation_error" \
              "Agent $agent_name output file failed format validation (retry $retry/$max_retries)" \
              "agent_validation" \
              "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retry "$retry" '{agent: $agent, output_file: $file, retry: $retry}')"

            # Remove invalid file before retry
            rm -f "$expected_file" 2>/dev/null
            break  # Exit timeout loop, proceed to next retry
          fi
        else
          return 0  # Success: file exists, no format validation required
        fi
      fi
      sleep 0.5
      elapsed=$((elapsed + 1))
    done

    # If not last retry, sleep before next attempt
    if [ $retry -lt $max_retries ]; then
      sleep $((retry * 2))  # Exponential backoff: 2s, 4s, 6s
    fi
  done

  # All retries exhausted: file not created or validation failed
  log_command_error \
    "${COMMAND_NAME:-/unknown}" \
    "${WORKFLOW_ID:-unknown}" \
    "${USER_ARGS:-}" \
    "agent_error" \
    "Agent $agent_name did not create valid output file after $max_retries attempts" \
    "agent_validation" \
    "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retries "$max_retries" '{agent: $agent, expected_file: $file, retries: $retries}')"

  return 1
}

# Topic name format validator
validate_topic_name_format() {
  local file="$1"
  local topic_name=$(cat "$file" 2>/dev/null | tr -d '\n' | tr -d ' ')

  # Validate format: lowercase alphanumeric + underscore, 5-40 chars
  if echo "$topic_name" | grep -Eq '^[a-z0-9_]{5,40}$'; then
    return 0
  fi

  return 1
}
```

**Usage Pattern**:
```bash
# Invoke agent
Task { ... }

# Validate output with retry and format validation
if ! validate_agent_output_with_retry \
     "topic-naming-agent" \
     "$TOPIC_NAME_FILE" \
     "validate_topic_name_format" \
     5 \
     3; then
  echo "WARNING: Agent failed after 3 retries, using fallback" >&2
  NAMING_STRATEGY="agent_failed_validation"
fi
```

**Agent Behavioral Requirement Update**:
Add requirement to all agent specifications:
```markdown
## Error Handling Requirements

**CRITICAL**: If Write tool invocation fails, you MUST:
1. Return TASK_ERROR signal immediately
2. Include diagnostic context: file path, error message, attempted operation
3. DO NOT continue with remaining steps
4. DO NOT return success signal if file write failed

**Example Error Return**:
```
TASK_ERROR: Failed to write output file
- File path: /path/to/output.md
- Error: Permission denied (write-protected directory)
- Attempted operation: Write tool invocation for research report
```
```

**Validation Test**:
```bash
# Unit test: Validate framework detects missing file
test_validate_agent_output_missing_file() {
  local test_file="/tmp/nonexistent_$$.txt"

  if validate_agent_output_with_retry "test-agent" "$test_file" "none" 1 1; then
    echo "FAIL: Should detect missing file"
    return 1
  fi

  echo "PASS: Framework detected missing file"
  return 0
}

# Integration test: Validate framework with /plan command
/plan "test agent validation framework integration"
/errors --command /plan --type agent_error --since 5m
# Expected: Detailed diagnostics if agent failed
```

#### Stage 2.3: Enhance Error Logging with Stack Trace Capture
**Impact**: Improves debugging of 9% of errors with poor attribution (line 252 generic failures)
**Effort**: MEDIUM (1-2 hours) | **Risk**: LOW

**Rationale**: Error trap reports line where `set -e` triggered, not line of original failure. "Line 252: exit code 1" is misleading - line 252 may be blank or unrelated to actual failure. Full stack trace provides complete failure context.

**Component**: Enhanced Error Trap
**File**: .claude/lib/core/error-handling.sh

**Implementation**:
```bash
# Enhanced bash error trap with stack trace capture
# Usage: setup_bash_error_trap <command_name> <workflow_id> <user_args>
setup_bash_error_trap() {
  local cmd_name="${1:-/unknown}"
  local workflow_id="${2:-unknown}"
  local user_args="${3:-}"

  # ERR trap with full context capture
  trap '
    local exit_code=$?
    local line_no=$LINENO
    local failed_cmd="$BASH_COMMAND"
    local source_file="${BASH_SOURCE[1]}"
    local caller_line="${BASH_LINENO[0]}"

    # Capture full stack trace
    local stack_trace=""
    for ((i=0; i<${#FUNCNAME[@]}-1; i++)); do
      stack_trace+="${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} in ${FUNCNAME[$i]}\n"
    done

    # Capture surrounding source code context (±5 lines)
    local source_context=""
    if [ -f "$source_file" ]; then
      local start_line=$((line_no - 5))
      [ $start_line -lt 1 ] && start_line=1
      local end_line=$((line_no + 5))
      source_context=$(sed -n "${start_line},${end_line}p" "$source_file" 2>/dev/null | \
                       nl -v $start_line -w 4 -s " | ")
    fi

    log_command_error \
      "'"$cmd_name"'" \
      "'"$workflow_id"'" \
      "'"$user_args"'" \
      "execution_error" \
      "Bash error at line $line_no: exit code $exit_code" \
      "bash_trap" \
      "$(jq -n \
        --argjson line "$line_no" \
        --argjson code "$exit_code" \
        --arg cmd "$failed_cmd" \
        --arg stack "$stack_trace" \
        --arg context "$source_context" \
        --arg file "$source_file" \
        '"'"'{line: $line, exit_code: $code, command: $cmd, stack_trace: $stack, source_context: $context, source_file: $file}'"'"')"

    exit $exit_code
  ' ERR
}
```

**Error Log Schema Update**:
Extend JSONL schema to include stack trace and source context:
```json
{
  "timestamp": "2025-11-21T16:33:14Z",
  "environment": "production",
  "command": "/plan",
  "workflow_id": "plan_1763742651",
  "error_type": "execution_error",
  "error_message": "Bash error at line 252: exit code 1",
  "source": "bash_trap",
  "context": {
    "line": 252,
    "exit_code": 1,
    "command": "return 1",
    "stack_trace": ".claude/commands/plan.md:252 in main\n.claude/lib/workflow/workflow-initialization.sh:156 in initialize_workflow_paths\n",
    "source_context": "  248 | \n  249 |   # Validate classification result\n  250 |   if [ -z \"$TOPIC_PATH\" ]; then\n  251 |     echo \"ERROR: Topic path not set\" >&2\n  252 |     return 1\n  253 |   fi\n  254 | \n  255 |   echo \"Topic path: $TOPIC_PATH\"\n  256 |   return 0\n",
    "source_file": ".claude/commands/plan.md"
  }
}
```

**Benefits**:
- Identifies actual failure point (not just trap trigger line)
- Shows function call chain leading to error
- Provides source code context for rapid debugging
- Enables pattern detection across similar failures

**Validation Test**:
```bash
# Unit test: Validate stack trace capture
test_stack_trace_capture() {
  local test_script="/tmp/test_error_trap_$$.sh"
  cat > "$test_script" <<'EOF'
#!/usr/bin/env bash
source .claude/lib/core/error-handling.sh
COMMAND_NAME="/test"
WORKFLOW_ID="test_123"
USER_ARGS="test"
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

failing_function() {
  return 1  # Trigger error
}

failing_function
EOF

  bash "$test_script" 2>&1

  # Check error log contains stack trace
  if grep -q "stack_trace" .claude/data/logs/errors.jsonl; then
    echo "PASS: Stack trace captured in error log"
    rm -f "$test_script"
    return 0
  fi

  echo "FAIL: Stack trace not captured"
  rm -f "$test_script"
  return 1
}
```

#### Stage 2.4: Add State Restoration Validation
**Impact**: Prevents cascading failures from partial state loads
**Effort**: MEDIUM (2 hours) | **Risk**: LOW

**Rationale**: Blocks load state from previous blocks but don't validate required variables are present. If state partially loads (e.g., FEATURE_DESCRIPTION missing), subsequent operations fail with "unbound variable" errors.

**Component**: State Variable Validation
**File**: .claude/lib/core/state-persistence.sh

**Implementation**:
```bash
# Validate required variables are present in loaded state
# Usage: validate_state_variables <var1> <var2> ... <varN>
# Returns: 0 if all variables set, 1 if any missing
# Example: validate_state_variables "FEATURE_DESCRIPTION" "TOPIC_PATH" "WORKFLOW_ID"
validate_state_variables() {
  local -a required_vars=("$@")
  local missing_vars=()

  for var_name in "${required_vars[@]}"; do
    # Check if variable is set (not empty or unset)
    if [ -z "${!var_name+x}" ]; then
      missing_vars+=("$var_name")
    fi
  done

  if [ ${#missing_vars[@]} -gt 0 ]; then
    log_command_error \
      "${COMMAND_NAME:-/unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "state_error" \
      "Required state variables missing after load: ${missing_vars[*]}" \
      "state_validation" \
      "$(jq -n --arg vars "${missing_vars[*]}" '{missing_variables: $vars}')"

    echo "ERROR: State validation failed - missing variables: ${missing_vars[*]}" >&2
    return 1
  fi

  return 0
}

# Block-specific state validation profiles
# Defines required variables per block type
validate_block_state() {
  local block_type="$1"

  case "$block_type" in
    state)
      # Block 1c: Requires feature description, workflow ID, project dir
      validate_state_variables "FEATURE_DESCRIPTION" "WORKFLOW_ID" "CLAUDE_PROJECT_DIR" "RESEARCH_COMPLEXITY"
      ;;
    verify)
      # Block 2/3: Requires all paths and metadata
      validate_state_variables "TOPIC_PATH" "RESEARCH_DIR" "PLANS_DIR" "WORKFLOW_ID" "FEATURE_DESCRIPTION"
      ;;
    *)
      echo "ERROR: Unknown block type for validation: $block_type" >&2
      return 1
      ;;
  esac
}
```

**Usage Pattern**:
```bash
# Block 1c: After load_workflow_state
load_workflow_state "$WORKFLOW_ID" false

# Validate required variables loaded
validate_block_state "state" || {
  echo "ERROR: State validation failed after load" >&2
  echo "This indicates state file corruption or incomplete initialization in Block 1a" >&2
  exit 1
}

# Continue with block operations (safe - all variables guaranteed set)
```

**Validation Test**:
```bash
# Unit test: Detect missing variables
test_validate_missing_variables() {
  export WORKFLOW_ID="test_123"
  export CLAUDE_PROJECT_DIR="/test"
  # Intentionally omit FEATURE_DESCRIPTION

  if validate_state_variables "FEATURE_DESCRIPTION" "WORKFLOW_ID" "CLAUDE_PROJECT_DIR"; then
    echo "FAIL: Should detect missing FEATURE_DESCRIPTION"
    return 1
  fi

  echo "PASS: Detected missing variable"
  return 0
}

# Integration test: Validate state validation in /plan
# Manually corrupt state file to test validation
/plan "test state validation with corrupted state"
# Expected: Clear error message identifying missing variables
```

**Phase 2 Completion Criteria**:
- All 4 infrastructure components implemented and tested
- Integration tests pass for all components
- Documentation updated with usage patterns and troubleshooting
- At least 2 commands updated to use new infrastructure (/plan + one other)

---

### Phase 3: Testing and Validation (HIGH PRIORITY) [COMPLETE]
**Goal**: Comprehensive test coverage for fixes and infrastructure improvements
**Duration**: 3-4 hours
**Dependencies**: Phase 1 and Phase 2 complete

#### Stage 3.1: Unit Tests for Immediate Fixes
**Impact**: Validates individual fix components work correctly in isolation
**Effort**: MEDIUM (1.5 hours) | **Risk**: LOW

**Test Suite**: .claude/tests/unit/test_plan_command_fixes.sh

**Test Cases**:

**Test 1: append_workflow_state Available in Block 1c**
```bash
test_append_workflow_state_available() {
  echo "TEST: append_workflow_state available in Block 1c"

  # Mock environment
  export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
  export WORKFLOW_ID="test_$RANDOM"
  export COMMAND_NAME="/plan"
  export USER_ARGS="test feature"

  # Simulate Block 1c library sourcing
  source .claude/lib/core/source-libraries.sh
  source_libraries_for_block "state" || {
    echo "FAIL: Failed to source libraries for state block"
    return 1
  }

  # Verify append_workflow_state function exists
  if ! declare -f append_workflow_state >/dev/null; then
    echo "FAIL: append_workflow_state function not defined after sourcing"
    return 1
  fi

  # Test function can be called
  STATE_FILE="${HOME}/.claude/tmp/workflow_plan_${WORKFLOW_ID}.sh"
  init_workflow_state "$WORKFLOW_ID" || {
    echo "FAIL: Cannot initialize workflow state"
    return 1
  }

  append_workflow_state "TEST_VAR" "test_value" || {
    echo "FAIL: Cannot call append_workflow_state"
    return 1
  }

  # Verify state persisted
  if ! grep -q "TEST_VAR=" "$STATE_FILE"; then
    echo "FAIL: State not persisted to file"
    return 1
  fi

  echo "PASS: append_workflow_state available and functional"
  rm -f "$STATE_FILE"
  return 0
}
```

**Test 2: Agent Output Validation Detects Missing File**
```bash
test_agent_validation_detects_missing() {
  echo "TEST: Agent output validation detects missing file"

  # Setup
  export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
  export COMMAND_NAME="/plan"
  export WORKFLOW_ID="test_$RANDOM"
  export USER_ARGS="test"

  source .claude/lib/core/error-handling.sh
  ensure_error_log_exists

  # Mock missing agent output file
  local test_file="/tmp/nonexistent_agent_output_$RANDOM.txt"

  # Validate should fail and log error
  if validate_agent_output "test-agent" "$test_file" 1; then
    echo "FAIL: Validation should fail for missing file"
    return 1
  fi

  # Check error log
  local error_count=$(grep -c "\"error_type\":\"agent_error\"" .claude/tests/logs/test-errors.jsonl 2>/dev/null || echo 0)
  if [ "$error_count" -eq 0 ]; then
    echo "FAIL: Error not logged to error log"
    return 1
  fi

  echo "PASS: Agent validation detected missing file and logged error"
  return 0
}
```

**Test 3: Portable Shell Initialization on NixOS**
```bash
test_portable_shell_init_nixos() {
  echo "TEST: Portable shell initialization works on NixOS"

  # Create test function with portable init pattern
  test_init() {
    # Portable shell initialization
    for bashrc_path in /etc/bashrc /etc/bash.bashrc ~/.bashrc; do
      if [ -f "$bashrc_path" ]; then
        . "$bashrc_path" 2>/dev/null && break
      fi
    done
    return 0
  }

  # Execute test function (should not fail even if /etc/bashrc missing)
  if ! test_init; then
    echo "FAIL: Portable init failed"
    return 1
  fi

  echo "PASS: Portable shell initialization succeeded"
  return 0
}
```

**Test 4: State Variable Validation Detects Missing**
```bash
test_state_validation_detects_missing() {
  echo "TEST: State validation detects missing variables"

  # Setup
  export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
  source .claude/lib/core/state-persistence.sh

  # Set some variables, omit others
  export WORKFLOW_ID="test_123"
  export CLAUDE_PROJECT_DIR="/test"
  # Intentionally omit FEATURE_DESCRIPTION

  # Validation should fail
  if validate_state_variables "FEATURE_DESCRIPTION" "WORKFLOW_ID" "CLAUDE_PROJECT_DIR" 2>/dev/null; then
    echo "FAIL: Should detect missing FEATURE_DESCRIPTION"
    return 1
  fi

  echo "PASS: Detected missing variable"
  return 0
}
```

**Test Runner Integration**:
```bash
# Add to .claude/tests/run_all_tests.sh
run_test_with_summary "Unit Tests: /plan Command Fixes" ".claude/tests/unit/test_plan_command_fixes.sh"
```

#### Stage 3.2: Integration Tests for Full Workflow
**Impact**: Validates fixes work correctly in complete /plan workflow context
**Effort**: MEDIUM (1.5 hours) | **Risk**: LOW

**Test Suite**: .claude/tests/integration/test_plan_command_integration.sh

**Test Cases**:

**Test 1: /plan Workflow Completes Without Errors**
```bash
test_plan_workflow_complete() {
  echo "TEST: /plan workflow completes without errors"

  # Clear previous error logs
  local test_errors=".claude/tests/logs/test-errors.jsonl"
  > "$test_errors"

  # Execute /plan command
  local feature_desc="Integration test feature for /plan fixes"
  /plan "$feature_desc"

  # Check for errors in error log
  local error_count=$(grep -c "\"command\":\"/plan\"" "$test_errors" 2>/dev/null || echo 0)
  if [ "$error_count" -gt 0 ]; then
    echo "FAIL: /plan workflow logged $error_count errors"
    echo "Errors:"
    jq -r '.error_message' "$test_errors" | head -5
    return 1
  fi

  # Verify plan created
  local plan_files=$(find .claude/specs/ -name "*_plan.md" -mmin -5 | wc -l)
  if [ "$plan_files" -eq 0 ]; then
    echo "FAIL: No plan file created"
    return 1
  fi

  echo "PASS: /plan workflow completed without errors"
  return 0
}
```

**Test 2: Agent Failure Gracefully Falls Back**
```bash
test_agent_failure_fallback() {
  echo "TEST: Agent failure triggers graceful fallback to no_name"

  # Note: This test requires mocking agent to not create output file
  # For now, test checks fallback mechanism works when file missing

  local feature_desc="Test agent failure fallback"
  local workflow_output=$(/plan "$feature_desc" 2>&1)

  # Check for fallback message in output
  if ! echo "$workflow_output" | grep -q "no_name"; then
    echo "FAIL: No fallback to no_name directory"
    return 1
  fi

  # Check error log contains agent_error with diagnostic context
  if ! grep -q "\"error_type\":\"agent_error\"" .claude/tests/logs/test-errors.jsonl; then
    echo "FAIL: Agent error not logged"
    return 1
  fi

  # Verify workflow still completed (graceful degradation)
  local plan_files=$(find .claude/specs/ -name "*no_name*plan.md" -mmin -5 | wc -l)
  if [ "$plan_files" -eq 0 ]; then
    echo "FAIL: Workflow did not complete with fallback"
    return 1
  fi

  echo "PASS: Agent failure triggered graceful fallback"
  return 0
}
```

**Test 3: Cross-Command Library Sourcing**
```bash
test_cross_command_library_sourcing() {
  echo "TEST: Library sourcing works across multiple commands"

  local commands=("/plan" "/research" "/debug")
  local test_errors=".claude/tests/logs/test-errors.jsonl"
  > "$test_errors"

  for cmd in "${commands[@]}"; do
    # Execute command (with minimal args to trigger initialization)
    timeout 30s $cmd "test library sourcing" 2>&1 >/dev/null || true

    # Check for "command not found" errors
    local cmd_errors=$(grep "\"command\":\"$cmd\"" "$test_errors" 2>/dev/null | \
                       grep -c "command not found" || echo 0)

    if [ "$cmd_errors" -gt 0 ]; then
      echo "FAIL: $cmd has undefined function errors"
      return 1
    fi
  done

  echo "PASS: All commands source libraries correctly"
  return 0
}
```

#### Stage 3.3: Regression Tests for Error Patterns
**Impact**: Prevents fixed error patterns from returning in future changes
**Effort**: LOW (1 hour) | **Risk**: LOW

**Test Suite**: .claude/tests/regression/test_plan_error_patterns.sh

**Test Cases**:

**Test 1: No Bashrc Sourcing Failures on NixOS**
```bash
test_no_bashrc_errors_nixos() {
  echo "TEST: No bashrc sourcing errors on NixOS"

  local test_errors=".claude/tests/logs/test-errors.jsonl"
  > "$test_errors"

  # Execute /plan
  /plan "test bashrc portability on NixOS"

  # Check for bashrc-related errors
  if grep -q "bashrc" "$test_errors"; then
    echo "FAIL: Bashrc sourcing errors still occurring"
    grep "bashrc" "$test_errors"
    return 1
  fi

  echo "PASS: No bashrc sourcing errors on NixOS"
  return 0
}
```

**Test 2: State Persistence Works Across Blocks**
```bash
test_state_persistence_across_blocks() {
  echo "TEST: State persists correctly from Block 1a to Block 1c"

  # This is implicitly tested by workflow completion, but explicitly check state file
  local feature_desc="Test state persistence"
  /plan "$feature_desc"

  # Find most recent state file
  local state_file=$(ls -t ${HOME}/.claude/tmp/workflow_plan_*.sh 2>/dev/null | head -1)

  if [ ! -f "$state_file" ]; then
    echo "FAIL: State file not created"
    return 1
  fi

  # Verify critical variables present
  if ! grep -q "FEATURE_DESCRIPTION=" "$state_file"; then
    echo "FAIL: FEATURE_DESCRIPTION not in state file"
    return 1
  fi

  if ! grep -q "TOPIC_PATH=" "$state_file"; then
    echo "FAIL: TOPIC_PATH not in state file"
    return 1
  fi

  echo "PASS: State persists correctly across blocks"
  return 0
}
```

**Test 3: No Undefined Function Errors (append_workflow_state)**
```bash
test_no_undefined_function_errors() {
  echo "TEST: No undefined function errors in /plan workflow"

  local test_errors=".claude/tests/logs/test-errors.jsonl"
  > "$test_errors"

  /plan "test undefined function detection"

  # Check for exit code 127 (command not found)
  if grep -q "\"exit_code\":127" "$test_errors"; then
    echo "FAIL: Exit code 127 (command not found) detected"
    grep "exit_code" "$test_errors" | head -3
    return 1
  fi

  echo "PASS: No undefined function errors"
  return 0
}
```

**Phase 3 Completion Criteria**:
- All unit tests pass (4/4)
- All integration tests pass (3/3)
- All regression tests pass (3/3)
- Test coverage ≥80% for modified code
- Tests integrated into run_all_tests.sh
- CI/CD pipeline includes new tests

---

### Phase 4: Documentation and Standards Updates (MEDIUM PRIORITY) [COMPLETE]
**Goal**: Document fixes, update standards, provide troubleshooting guides
**Duration**: 2-3 hours
**Dependencies**: Phase 1, 2, 3 complete

#### Stage 4.1: Update Command Development Standards
**Impact**: Prevents future commands from repeating same mistakes
**Effort**: LOW (1 hour) | **Risk**: LOW

**File**: .claude/docs/reference/standards/command-reference.md

**Updates Required**:

**Section 1: Library Sourcing Standard**
```markdown
### Library Sourcing Requirements

All commands MUST use standardized library sourcing via `source_libraries_for_block()` helper.

**Required Pattern**:
```bash
# Load library sourcing helper
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries.sh" 2>/dev/null || {
  echo "ERROR: Failed to load library sourcing helper" >&2
  exit 1
}

# Source libraries for block type
source_libraries_for_block "<block_type>" || {
  echo "ERROR: Failed to source required libraries" >&2
  exit 1
}

# Validate required functions available
validate_sourced_functions "<block_type>" || {
  echo "ERROR: Required functions not available" >&2
  exit 1
}
```

**Block Types**:
- `init`: Block 1a (initial setup and state creation)
- `state`: Block 1c (state loading and path initialization)
- `verify`: Block 2/3 (verification and completion)

**Required Libraries Per Block**:
| Block Type | Required Libraries |
|------------|-------------------|
| init | error-handling.sh, state-persistence.sh, workflow-state-machine.sh, workflow-initialization.sh, library-version-check.sh |
| state | error-handling.sh, state-persistence.sh, workflow-initialization.sh |
| verify | error-handling.sh, state-persistence.sh, workflow-state-machine.sh |

**Rationale**: Manual library sourcing creates maintenance burden and error-prone patterns. Subprocess isolation means each bash block must independently source required libraries.
```

**Section 2: Agent Output Validation Standard**
```markdown
### Agent Output Validation Requirements

All commands that invoke agents MUST validate agent output files were created and match expected format.

**Required Pattern**:
```bash
# Invoke agent via Task tool
Task { ... }

# Validate agent created output file
if ! validate_agent_output_with_retry \
     "<agent_name>" \
     "$OUTPUT_FILE_PATH" \
     "<format_validator_function>" \
     <timeout_seconds> \
     <max_retries>; then
  echo "WARNING: Agent failed to create valid output, using fallback" >&2
  # Implement graceful degradation
fi
```

**Parameters**:
- `agent_name`: Human-readable agent identifier (e.g., "topic-naming-agent")
- `OUTPUT_FILE_PATH`: Expected output file path
- `format_validator_function`: Function name to validate file format, or "none"
- `timeout_seconds`: Max wait time for file creation (default: 5s)
- `max_retries`: Number of retry attempts with exponential backoff (default: 3)

**Rationale**: Agent Task completion does not guarantee output file creation. Write tool failures may occur silently within agent execution.
```

#### Stage 4.2: Create Troubleshooting Guide for /plan Command
**Impact**: Helps users and developers debug /plan command issues independently
**Effort**: MEDIUM (1 hour) | **Risk**: LOW

**File**: .claude/docs/troubleshooting/plan-command-errors.md

**Content Structure**:
```markdown
# Troubleshooting Guide: /plan Command Errors

## Common Error Patterns

### Error: append_workflow_state: command not found

**Symptom**: Exit code 127 in Block 1c
**Root Cause**: Missing state-persistence.sh library sourcing
**Fix**: Verify Block 1c sources state-persistence.sh
**Prevention**: Use `source_libraries_for_block "state"` pattern

### Error: Topic naming agent failed (agent_no_output_file)

**Symptom**: Fallback to "no_name" directory structure
**Root Cause**: Agent did not write output file
**Debugging Steps**:
1. Check error log: `/errors --command /plan --type agent_error --limit 5`
2. Verify file permissions: `ls -la ${HOME}/.claude/tmp/`
3. Check disk space: `df -h ${HOME}/.claude/tmp/`
4. Review agent output validation timeout (default 5s)

**Fix**: Increase validation timeout or check Write tool failures in agent
**Prevention**: Agent must return TASK_ERROR if Write fails

### Error: Bash error at line 1: exit code 127 (bashrc sourcing)

**Symptom**: Workflow fails at startup before Block 1a
**Root Cause**: `/etc/bashrc` does not exist on NixOS
**Fix**: Use portable shell initialization pattern
**Prevention**: Commands should not assume standard Linux paths

## Diagnostic Commands

**View recent /plan errors**:
```bash
/errors --command /plan --since 1h --summary
```

**Analyze error patterns**:
```bash
/errors --command /plan --type execution_error --limit 20
```

**Check agent failures**:
```bash
/errors --command /plan --type agent_error --limit 10
```

**Verify state file integrity**:
```bash
ls -lh ${HOME}/.claude/tmp/workflow_plan_*.sh | tail -5
cat ${HOME}/.claude/tmp/workflow_plan_$(cat ${HOME}/.claude/tmp/plan_state_id.txt).sh
```
```

#### Stage 4.3: Update Error Handling Documentation
**Impact**: Documents new validation functions and best practices
**Effort**: LOW (30 minutes) | **Risk**: LOW

**File**: .claude/docs/concepts/patterns/error-handling.md

**Updates Required**:

**Section 1: Agent Output Validation**
```markdown
### Agent Output Validation Pattern

Commands that invoke agents must validate output files were created and match expected format using `validate_agent_output_with_retry()`.

**Function Signature**:
```bash
validate_agent_output_with_retry <agent_name> <expected_file> <format_validator> [timeout] [retries]
```

**Example**:
```bash
# Invoke topic naming agent
Task { ... }

# Validate output with retry and format validation
if ! validate_agent_output_with_retry \
     "topic-naming-agent" \
     "$TOPIC_NAME_FILE" \
     "validate_topic_name_format" \
     5 \
     3; then
  echo "WARNING: Agent failed after 3 retries, using fallback" >&2
  NAMING_STRATEGY="agent_failed_validation"
fi
```

**Behavioral Requirement**: All agents MUST return TASK_ERROR if Write tool invocation fails.
```

**Section 2: State Validation Pattern**
```markdown
### State Variable Validation Pattern

Blocks that load state from previous blocks must validate required variables are present using `validate_state_variables()` or `validate_block_state()`.

**Function Signatures**:
```bash
validate_state_variables <var1> <var2> ... <varN>
validate_block_state <block_type>
```

**Example**:
```bash
# Load workflow state
load_workflow_state "$WORKFLOW_ID" false

# Validate required variables loaded
validate_block_state "state" || {
  echo "ERROR: State validation failed - missing required variables" >&2
  exit 1
}

# Continue with block operations (all variables guaranteed set)
```

**Block Types**: init, state, verify (see command-reference.md for required variables per type)
```

**Phase 4 Completion Criteria**:
- All documentation files updated with new standards
- Troubleshooting guide published and linked from command-reference.md
- At least 1 example added per new pattern
- Documentation reviewed for accuracy and completeness

---

## Success Metrics

### Error Reduction Targets
- **Phase 1 Complete**: 81% error reduction (9/11 errors resolved)
- **Phase 2 Complete**: 100% infrastructure gaps addressed
- **Phase 3 Complete**: ≥80% test coverage for modified components
- **Phase 4 Complete**: Documentation complete and published

### Workflow Reliability Targets
- **Current**: 0% success rate (5/5 workflows had errors)
- **Post-Phase 1**: ≥90% success rate (≤1 error per 10 workflows)
- **Post-Phase 2**: ≥95% success rate with improved diagnostics
- **Post-Phase 3**: ≥98% success rate with regression prevention

### Specific Error Pattern Targets
| Error Pattern | Current Rate | Target Rate | Phase |
|---------------|--------------|-------------|-------|
| append_workflow_state: command not found | 27% (3/11) | 0% | Phase 1 |
| Topic naming agent no output file | 27% (3/11) | <5% | Phase 1+2 |
| Bashrc sourcing exit 127 | 27% (3/11) | 0% | Phase 1 |
| Generic execution errors (poor attribution) | 9% (1/11) | 0% | Phase 2 |
| Cross-command library sourcing issues | 9% (1/11) | 0% | Phase 2 |

### Infrastructure Maturity Targets
- **Library Sourcing**: 100% commands use standardized helper (currently: manual sourcing)
- **Agent Validation**: 100% agent invocations use validation framework (currently: 0%)
- **State Validation**: 100% blocks validate state after load (currently: 0%)
- **Error Attribution**: 100% errors include stack trace and source context (currently: line number only)

## Risk Assessment

### High Risk Items
1. **Library Sourcing Helper Rollout**: Requires updating all orchestrator commands
   - **Mitigation**: Pilot with /plan command, test thoroughly before broader rollout

2. **Agent Behavioral Requirement Change**: Agents must return TASK_ERROR on Write failures
   - **Mitigation**: Update agent specifications first, then test with validation framework

### Medium Risk Items
1. **Error Trap Enhancement**: Stack trace capture may have performance impact
   - **Mitigation**: Benchmark trap overhead, optimize if >10ms per error

2. **State Validation Overhead**: Validation adds processing time per block
   - **Mitigation**: Validate only critical variables, cache validation results

### Low Risk Items
1. **Portable Shell Initialization**: Fallback pattern has minimal impact
2. **Documentation Updates**: No code changes, pure documentation

## Dependencies

### External Dependencies
- None (all changes internal to .claude/ system)

### Internal Dependencies
| Phase | Depends On | Reason |
|-------|-----------|--------|
| Phase 2 | Phase 1 complete | Infrastructure builds on immediate fixes |
| Phase 3 | Phase 1+2 complete | Tests validate all fixes and infrastructure |
| Phase 4 | Phase 1+2+3 complete | Documentation reflects implemented changes |

### Blocking Issues
- None identified

## Rollout Plan

### Stage 1: Immediate Fixes (Week 1)
- Day 1: Implement Fix 1 (library sourcing), validate with unit tests
- Day 2: Implement Fix 2 (agent validation), validate with integration tests
- Day 3: Implement Fix 3 (portable shell init), validate with regression tests
- Day 4: Integration testing of all fixes together
- Day 5: Deploy to production, monitor error logs

### Stage 2: Infrastructure Improvements (Week 2)
- Day 1-2: Library sourcing helper (implementation + rollout)
- Day 3: Agent validation framework (implementation + agent spec updates)
- Day 4: Error trap enhancement + state validation
- Day 5: Integration testing, documentation

### Stage 3: Testing and Validation (Week 3)
- Day 1-2: Unit tests (all components)
- Day 3: Integration tests (full workflows)
- Day 4: Regression tests (error patterns)
- Day 5: CI/CD integration, test automation

### Stage 4: Documentation (Week 3-4)
- Day 1: Command standards updates
- Day 2: Troubleshooting guide
- Day 3: Error handling documentation
- Day 4: Review and polish
- Day 5: Publish and announce

## Monitoring and Validation

### Post-Deployment Monitoring
1. **Error Log Analysis**:
   ```bash
   # Daily error rate check
   /errors --command /plan --since 24h --summary

   # Pattern detection
   /errors --command /plan --type execution_error --since 7d | \
     jq -r '.error_message' | sort | uniq -c | sort -rn | head -10
   ```

2. **Workflow Success Rate**:
   ```bash
   # Count successful vs failed workflows
   find .claude/specs/ -name "*_plan.md" -mtime -7 | wc -l
   grep "\"command\":\"/plan\"" .claude/data/logs/errors.jsonl | \
     jq -r '.workflow_id' | sort -u | wc -l
   ```

3. **Agent Success Rate**:
   ```bash
   # Topic naming agent success rate
   find .claude/specs/ -type d ! -name "*no_name*" -mtime -7 | wc -l
   find .claude/specs/ -type d -name "*no_name*" -mtime -7 | wc -l
   ```

### Success Validation Criteria
- [ ] Zero append_workflow_state errors for 7 consecutive days
- [ ] Agent validation detects all Write failures (100% detection rate)
- [ ] No bashrc sourcing errors on NixOS for 7 consecutive days
- [ ] Error logs include stack traces and source context (100% coverage)
- [ ] At least 2 commands successfully using library sourcing helper
- [ ] Test coverage ≥80% for all modified components
- [ ] Documentation complete and published

## References

### Source Files
- /home/benjamin/.config/.claude/plan-output.md (command execution log)
- /home/benjamin/.config/.claude/specs/102_plan_command_error_analysis/reports/001_error_report.md (error analysis)
- /home/benjamin/.config/.claude/specs/890_plan_command_error_debug_infrastructure/reports/001_root_cause_analysis.md (root cause analysis)
- /home/benjamin/.config/.claude/commands/plan.md (command implementation)
- /home/benjamin/.config/.claude/lib/core/state-persistence.sh (state management library)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh (error handling library)

### Standards Documentation
- .claude/docs/reference/standards/command-reference.md (command development standards)
- .claude/docs/reference/standards/testing-protocols.md (testing requirements)
- .claude/docs/concepts/patterns/error-handling.md (error handling pattern)
- .claude/docs/reference/standards/output-formatting.md (output standards)

### Related Issues
- Root Cause 1: Incomplete library sourcing (lines 325-326 of plan.md)
- Root Cause 2: Topic naming agent failures (100% failure rate, agent_no_output_file)
- Root Cause 3: Non-portable shell initialization (NixOS /etc/bashrc missing)

---

**Plan Created**: 2025-11-21
**Last Updated**: 2025-11-21
**Plan Version**: 1.0
**Status**: Ready for implementation
