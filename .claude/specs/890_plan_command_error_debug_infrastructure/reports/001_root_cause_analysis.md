# Root Cause Analysis: /plan Command Errors and Infrastructure Gaps

## Report Metadata
- **Generated**: 2025-11-21
- **Analysis Type**: Root cause analysis for debug workflow
- **Primary Sources**:
  - `/home/benjamin/.config/.claude/plan-output.md` (command execution log)
  - `/home/benjamin/.config/.claude/specs/102_plan_command_error_analysis/reports/001_error_report.md` (error analysis)
- **Standards Reviewed**:
  - `.claude/docs/reference/standards/command-reference.md`
  - `.claude/docs/concepts/patterns/error-handling.md`
  - `.claude/commands/plan.md` (command implementation)
  - `.claude/lib/core/error-handling.sh` (error handling library)
  - `.claude/lib/workflow/workflow-initialization.sh` (initialization library)
  - `.claude/agents/topic-naming-agent.md` (naming agent spec)

## Executive Summary

The /plan command experienced 11 errors across 5 workflows (2025-11-21T06:13-16:33), with three critical failure patterns causing systematic workflow failures:

1. **State Management Failures (27% of errors)**: Undefined `append_workflow_state` function due to missing library sourcing in Block 1c, causing cascading state persistence failures
2. **Topic Naming Agent Failures (27% of errors)**: 100% failure rate (3/3 attempts) with `agent_no_output_file` error, indicating agent not writing output files despite successful invocation
3. **Environment Initialization Failures (27% of errors)**: Bashrc sourcing failures (`. /etc/bashrc` exit code 127) at workflow startup, indicating missing/incompatible shell configuration

These patterns reveal three infrastructure gaps: (1) incomplete library initialization in Block 1c, (2) missing agent output validation in topic naming workflow, and (3) non-portable shell initialization assumptions. The errors share a common root cause: **defensive programming gaps in subprocess isolation boundaries** where state and context are not fully restored between bash blocks.

### Impact Assessment
- **Workflow Success Rate**: 0% (all 5 workflows encountered at least one error)
- **User Experience**: Degraded - workflows fall back to "no_name" directories, losing semantic organization
- **Data Integrity**: Partial - state files created but incomplete due to missing function calls
- **Recovery**: Manual - users must identify error patterns via `/errors` command

## Error Analysis Summary

### Error Distribution by Type
| Error Type | Count | Percentage | Severity |
|------------|-------|------------|----------|
| execution_error | 8 | 72.7% | HIGH |
| agent_error | 3 | 27.3% | HIGH |

### Error Distribution by Pattern
| Pattern | Occurrences | Root Cause Category |
|---------|-------------|---------------------|
| append_workflow_state: command not found | 3 | State Management |
| Topic naming agent no output file | 3 | Agent Integration |
| Bashrc sourcing failure (exit code 127) | 3 | Environment Setup |
| Generic execution error (line 252) | 1 | Validation Logic |
| initialize_workflow_paths: command not found | 1 | Cross-Command Issue |

## Root Cause Analysis

### Root Cause 1: Incomplete Library Sourcing in Block 1c

**Severity**: HIGH
**Occurrence Rate**: 27% of errors (3/11)
**Affected Workflows**: plan_1763705583, plan_1763707476, plan_1763742651

#### Symptom
```bash
/run/current-system/sw/bin/bash: line 323: append_workflow_state: command not found
/run/current-system/sw/bin/bash: line 183: append_workflow_state: command not found
```

#### Root Cause Chain

**Immediate Cause**: Block 1c attempts to call `append_workflow_state()` without sourcing the library that defines it.

**Contributing Factors**:
1. **Subprocess Isolation**: Each bash block runs in a new subprocess, library sourcing from Block 1a is not inherited
2. **Incomplete Restoration**: Block 1c only sources error-handling.sh and workflow-initialization.sh, missing state-persistence.sh
3. **Library Dependency**: `append_workflow_state()` is defined in state-persistence.sh, not workflow-initialization.sh

**Design Gap**: The /plan command assumes functions from Block 1a are available in Block 1c, violating subprocess isolation boundaries.

#### Evidence from Source Files

**Block 1a (lines 119-120)**: Sources state-persistence.sh correctly
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
```

**Block 1c (lines 325-326)**: Missing state-persistence.sh sourcing
```bash
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null
```

**Block 1c (line 422)**: Calls function from un-sourced library
```bash
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
```

#### Infrastructure Gap
The command lacks a **library sourcing checklist** for each bash block. Blocks 2 and 3 have complete sourcing (lines 499-501, 749-751), but Block 1c is incomplete.

**Pattern Inconsistency**:
- Block 1a: Sources all 5 libraries
- Block 1c: Sources only 2 libraries (missing state-persistence.sh, workflow-state-machine.sh, library-version-check.sh)
- Block 2/3: Sources all 3 required libraries for their operations

#### Recommended Fix
Add missing library sourcing to Block 1c:
```bash
# Source required libraries for state persistence
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null  # ADDED
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null
```

---

### Root Cause 2: Topic Naming Agent Output File Not Created

**Severity**: HIGH
**Occurrence Rate**: 27% of errors (3/11), 100% agent failure rate (3/3 attempts)
**Affected Workflows**: plan_1763705583 (2 attempts), plan_1763707955, plan_1763742651

#### Symptom
```
ERROR_CONTEXT: {"error_type": "agent_error", "message": "Topic naming agent failed or returned invalid name", "context": {"feature": "...", "fallback_reason": "agent_no_output_file"}}
```

Block 1b invokes topic-naming-agent successfully (agent completes without error signal), but Block 1c finds output file missing at expected path.

#### Root Cause Chain

**Immediate Cause**: Agent completes Task invocation but does not write output file to `${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt`

**Contributing Factors**:
1. **Agent Model**: Uses Haiku-4.5 for speed (<3s response), but may encounter API errors or timeouts not captured in error handling
2. **Missing Output Validation**: Block 1b does not verify output file existence after agent completes
3. **Silent Agent Failures**: Agent may return success without writing file due to Write tool failures or permission issues
4. **Path Mismatch**: Agent may write to incorrect path if OUTPUT_FILE_PATH not correctly passed in Task invocation prompt

**Design Gap**: The workflow lacks **agent output validation** - it assumes successful Task completion guarantees file creation.

#### Evidence from Source Files

**Block 1b (lines 244-267)**: Agent invocation with OUTPUT_FILE_PATH
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    ...
    **Input**:
    - OUTPUT_FILE_PATH: ${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Execute topic naming according to behavioral guidelines:
    ...
    3. Write topic name to OUTPUT_FILE_PATH using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>
```

**Block 1c (lines 332-370)**: File existence check without agent output validation
```bash
TOPIC_NAME_FILE="${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
TOPIC_NAME="no_name"
NAMING_STRATEGY="fallback"

# Check if agent wrote output file
if [ -f "$TOPIC_NAME_FILE" ]; then
  # Read topic name from file
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')
  ...
else
  # File doesn't exist - agent failed to write
  NAMING_STRATEGY="agent_no_output_file"
fi
```

**Agent Specification (topic-naming-agent.md, lines 144-150)**: Agent should write file and return signal
```markdown
**Output File Format**:
Write a single line containing only the topic name (no signal prefix, no extra text):
```
topic_name_here
```
```

#### Failure Modes

**Mode 1: Write Tool Failure** (most likely given 100% failure rate)
- Agent invokes Write tool, but tool fails due to permissions, disk space, or path issues
- Agent sees Write failure but does not return TASK_ERROR (behavioral gap)
- Task completes "successfully" from coordinator perspective, but output missing

**Mode 2: Path Variable Substitution Failure**
- `${HOME}` or `${WORKFLOW_ID}` not correctly substituted in Task prompt
- Agent writes to wrong path or cannot resolve path
- Block 1c checks correct path, finds nothing

**Mode 3: Agent Output Format Violation**
- Agent writes file but with incorrect format (JSON wrapping, quotes, etc.)
- File exists but Block 1c validation fails (though this should trigger "validation_failed" not "agent_no_output_file")

#### Infrastructure Gap
The workflow lacks **agent output guarantees**:
1. No validation that agent actually wrote output file after Task completion
2. No retry logic for Write tool failures within agent
3. No diagnostic logging of agent stderr output to debug Write failures
4. No timeout monitoring (agent spec says <3s, but no enforcement)

#### Recommended Fix
Add agent output validation in Block 1b (after Task completes, before Block 1c):
```bash
# Block 1b: After Task invocation
TOPIC_NAME_FILE="${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"

# Validate output file was created
if [ ! -f "$TOPIC_NAME_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Topic naming agent did not create output file" \
    "bash_block_1b" \
    "$(jq -n --arg path "$TOPIC_NAME_FILE" '{expected_file: $path}')"

  echo "WARNING: Topic naming agent failed to create output, falling back to 'no_name'" >&2
fi
```

---

### Root Cause 3: Non-Portable Shell Initialization

**Severity**: MEDIUM
**Occurrence Rate**: 27% of errors (3/11)
**Affected Workflows**: plan_1763705583, plan_1763707476, plan_1763742651

#### Symptom
```bash
/run/current-system/sw/bin/bash: line 1: exit code 127
Command: . /etc/bashrc
```

Exit code 127 indicates "command not found", but for `. /etc/bashrc` this means the file does not exist.

#### Root Cause Chain

**Immediate Cause**: `/etc/bashrc` does not exist on NixOS system (non-standard location)

**Contributing Factors**:
1. **Non-Portable Assumption**: Command assumes `/etc/bashrc` exists on all Unix systems
2. **Unconditioned Sourcing**: No existence check before sourcing (should use `[[ -f /etc/bashrc ]] && . /etc/bashrc`)
3. **set -e Interaction**: With `set -e` (fail-fast), non-existent file sourcing terminates script immediately

**System Context**: NixOS uses different shell initialization paths:
- Standard: `/etc/bashrc`
- NixOS: `/etc/bash.bashrc` or per-user `~/.bashrc`

**Design Gap**: The workflow lacks **environment portability** - assumes standard Linux shell configuration paths.

#### Evidence from Source Files

**Error Log Context** (001_error_report.md, lines 133-135):
```markdown
### Error 1
- **Timestamp**: 2025-11-21T06:13:55Z
- **Workflow ID**: plan_1763705583
- **Error Type**: execution_error
- **Message**: Bash error at line 1: exit code 127
- **Context**: `. /etc/bashrc` command failed
```

**Pattern Analysis**:
- Same error occurs at workflow startup for all 3 affected workflows
- Always at "line 1" suggesting very early in bash block execution
- No bashrc sourcing visible in /plan command blocks (likely in error trap setup or subprocess initialization)

#### Where Does This Occur?

The error occurs at "line 1" before Block 1a executes, suggesting it's in:
1. **Subshell initialization**: Claude Code may inject bashrc sourcing into bash blocks automatically
2. **Error trap setup**: setup_bash_error_trap() might source shell config
3. **Subprocess environment**: Parent process might pass sourcing command to child

**Investigation Required**: Search for bashrc sourcing in:
- Claude Code CLI initialization
- error-handling.sh library (checked: no bashrc sourcing found)
- Bash block subprocess invocation logic

#### Infrastructure Gap
The system lacks **portable shell initialization**:
1. Hard-coded shell config paths not validated for existence
2. No fallback for non-standard systems (NixOS, FreeBSD, Alpine Linux)
3. No documentation of required shell configuration files

#### Recommended Fix
Replace hard-coded bashrc sourcing with portable pattern:
```bash
# Portable shell initialization
for bashrc in /etc/bashrc /etc/bash.bashrc ~/.bashrc; do
  [[ -f "$bashrc" ]] && . "$bashrc" 2>/dev/null && break
done
```

Or remove bashrc sourcing entirely if not required for workflow execution (preferred for lightweight initialization).

---

### Root Cause 4: Generic Validation Failure (Line 252)

**Severity**: LOW
**Occurrence Rate**: 9% of errors (1/11)
**Affected Workflow**: plan_1763707955

#### Symptom
```
ERROR_CONTEXT: {"error_type": "execution_error", "message": "Bash error at line 252: exit code 1", "context": {"command": "return 1"}}
```

#### Root Cause Chain

**Immediate Cause**: Validation check failed at line 252, returning exit code 1

**Contributing Factor**: Line 252 in /plan command (Block 1c) is not a validation check - it's in the middle of CLAUDE_PROJECT_DIR detection logic. The error likely occurred earlier but was caught by error trap at line 252.

**Evidence from Source**: Line 252 in plan.md is blank (between CLAUDE_PROJECT_DIR detection and library sourcing). This suggests the error originated elsewhere and was caught by the error trap.

#### Analysis
This error is a **symptom of an earlier failure**, not a root cause itself. The actual failure likely occurred in:
1. **CLAUDE_PROJECT_DIR detection** (lines 98-114): Git or directory traversal failed
2. **State file validation** (lines 163-193): State file not found or missing WORKFLOW_ID

The line 252 attribution is an **error trap reporting artifact** - the trap handler reports the line where `set -e` triggered, not the line of the original error.

#### Infrastructure Gap
**Error attribution accuracy**: Error trap reports line of trap trigger, not line of original failure. This makes debugging difficult.

#### Recommended Fix
Enhance error trap to capture more context:
```bash
setup_bash_error_trap() {
  # Capture full command pipeline and stack trace
  trap 'log_bash_error $? $LINENO "$BASH_COMMAND" "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}"' ERR
}
```

---

### Cross-Command Pattern: initialize_workflow_paths Failure

**Severity**: HIGH
**Occurrence Rate**: 1 occurrence in /debug command (not /plan), but indicates systemic issue
**Affected Command**: /debug

#### Symptom
```
ERROR_CONTEXT: {"error_type": "execution_error", "message": "Bash error at line 96: exit code 127", "context": {"command": "initialize_workflow_paths: command not found"}}
```

#### Root Cause Chain
Same as Root Cause 1: Missing library sourcing in bash block that calls workflow initialization functions.

#### Systemic Pattern
This error appearing in both /plan and /debug commands indicates:
1. **Shared infrastructure bug**: Multiple commands suffer from same subprocess isolation gap
2. **Copy-paste propagation**: Block structure copied between commands without fixing sourcing issues
3. **Missing standards compliance**: Commands not following library sourcing checklist from command standards

#### Infrastructure Gap
**System-wide library sourcing audit needed**: All orchestrator commands (/plan, /research, /debug, /revise, /build) likely have similar gaps.

---

## Infrastructure Gaps Summary

### Gap 1: Library Sourcing Checklist Enforcement
**Category**: Development Standards
**Severity**: HIGH

**Current State**: Commands manually source libraries in each bash block with no validation

**Gap**: No enforced checklist ensures all required libraries are sourced per block

**Impact**: Undefined function errors (append_workflow_state, initialize_workflow_paths) that cascade into workflow failures

**Recommended Solution**:
1. Create `source-libraries.sh` helper with block-specific profiles:
```bash
# .claude/lib/core/source-libraries.sh
source_libraries_for_block() {
  local block_type="$1"  # init, state, agent, verify

  case "$block_type" in
    init)
      source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || return 1
      ;;
    state)
      source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || return 1
      source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || return 1
      source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || return 1
      ;;
  esac
}
```

2. Update all commands to use helper:
```bash
# Block 1c
source_libraries_for_block "state" || {
  echo "ERROR: Failed to source required libraries for Block 1c" >&2
  exit 1
}
```

3. Add linting rule: All commands must use `source_libraries_for_block()`

---

### Gap 2: Agent Output Validation Framework
**Category**: Agent Integration
**Severity**: HIGH

**Current State**: Commands invoke agents via Task tool and assume success implies output file creation

**Gap**: No validation framework verifies agent output exists and matches expected format

**Impact**: 100% topic naming agent failure rate (3/3), workflows fall back to "no_name" directories losing semantic organization

**Recommended Solution**:
1. Add agent output validation helper in error-handling.sh:
```bash
# Validate agent created expected output file
validate_agent_output() {
  local agent_name="$1"
  local expected_file="$2"
  local timeout_seconds="${3:-5}"

  local elapsed=0
  while [ $elapsed -lt $timeout_seconds ]; do
    if [ -f "$expected_file" ]; then
      if [ -s "$expected_file" ]; then
        return 0  # Success: file exists and non-empty
      fi
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

2. Update agent invocation pattern:
```bash
# Invoke agent
Task { ... }

# Validate output
validate_agent_output "topic-naming-agent" "$TOPIC_NAME_FILE" 5 || {
  echo "WARNING: Agent output validation failed, using fallback" >&2
  NAMING_STRATEGY="agent_no_output_file"
}
```

3. Add agent behavioral requirement: All agents MUST return TASK_ERROR if Write tool fails

---

### Gap 3: Portable Environment Initialization
**Category**: System Compatibility
**Severity**: MEDIUM

**Current State**: Commands assume standard Linux paths (/etc/bashrc) exist

**Gap**: No portable shell initialization pattern for non-standard systems (NixOS, FreeBSD, Alpine)

**Impact**: 27% of errors (3/11) from bashrc sourcing failures on NixOS

**Recommended Solution**:
1. Add portable shell initialization to detect-project-dir.sh:
```bash
# Portable shell initialization (called once per workflow)
init_portable_shell() {
  # Try standard locations in order
  for config in /etc/bashrc /etc/bash.bashrc ~/.bashrc; do
    if [ -f "$config" ]; then
      . "$config" 2>/dev/null && return 0
    fi
  done

  # No shell config found - continue without it
  return 0
}
```

2. Update bash block initialization to call `init_portable_shell` conditionally

3. Add environment detection to error logs (Linux, NixOS, macOS, FreeBSD)

---

### Gap 4: Error Attribution Accuracy
**Category**: Debugging Infrastructure
**Severity**: MEDIUM

**Current State**: Error trap reports line where `set -e` triggered, not line of original failure

**Gap**: No full stack trace or command pipeline capture in error logs

**Impact**: Difficult to debug errors like "line 252: exit code 1" where line 252 is not the actual failure point

**Recommended Solution**:
1. Enhance setup_bash_error_trap() to capture more context:
```bash
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
        '"'"'{line: $line, exit_code: $code, command: $cmd, stack_trace: $stack}'"'"')"

    exit $exit_code
  ' ERR
}
```

2. Update error log schema to include stack_trace field

---

### Gap 5: State Restoration Validation
**Category**: State Management
**Severity**: MEDIUM

**Current State**: Blocks load state from previous blocks but don't validate required variables are present

**Gap**: No defensive validation ensures critical variables (TOPIC_PATH, FEATURE_DESCRIPTION) are set after load_workflow_state()

**Impact**: Cascading failures when state partially loads (error at line 64: unbound variable FEATURE_DESCRIPTION)

**Recommended Solution**:
1. Add state validation helper in state-persistence.sh:
```bash
# Validate required variables are present in loaded state
validate_state_variables() {
  local -a required_vars=("$@")
  local missing_vars=()

  for var_name in "${required_vars[@]}"; do
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
    return 1
  fi

  return 0
}
```

2. Update blocks to validate state after loading:
```bash
# Block 1c
load_workflow_state "$WORKFLOW_ID" false

# Validate required variables
validate_state_variables "FEATURE_DESCRIPTION" "RESEARCH_COMPLEXITY" "CLAUDE_PROJECT_DIR" || {
  echo "ERROR: State validation failed after load" >&2
  exit 1
}
```

---

## Recommendations

### Immediate Fixes (High Priority)

#### Fix 1: Add Missing Library Sourcing to Block 1c
**Impact**: Resolves 27% of errors (3/11)
**Effort**: LOW (5 minutes)
**Risk**: LOW

**Changes Required**:
- File: `.claude/commands/plan.md`
- Location: Block 1c, line 325
- Add: `source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null`

**Validation**:
```bash
# Test that Block 1c can call append_workflow_state
/plan "test feature description"
# Should complete without "append_workflow_state: command not found" error
```

#### Fix 2: Add Agent Output Validation to Block 1b
**Impact**: Enables debugging of 100% agent failure rate (3/3)
**Effort**: MEDIUM (30 minutes)
**Risk**: LOW

**Changes Required**:
- File: `.claude/lib/core/error-handling.sh`
- Add: `validate_agent_output()` function (see Gap 2 solution)
- File: `.claude/commands/plan.md`
- Location: Block 1b, after Task invocation
- Add: Output validation call with diagnostic logging

**Validation**:
```bash
# Test agent output validation
/plan "test feature with agent validation"
# Check error log for agent diagnostic output if agent fails
/errors --type agent_error --limit 5
```

#### Fix 3: Replace Bashrc Sourcing with Portable Pattern
**Impact**: Resolves 27% of errors (3/11)
**Effort**: LOW (15 minutes)
**Risk**: LOW

**Changes Required**:
- File: `.claude/lib/core/detect-project-dir.sh` (or wherever bashrc sourcing occurs)
- Replace: `. /etc/bashrc` with portable pattern (see Gap 3 solution)

**Validation**:
```bash
# Test on NixOS system (current environment)
/plan "test portable shell initialization"
# Should complete without bashrc sourcing errors
```

### Medium-Term Improvements (Medium Priority)

#### Improvement 1: Create Library Sourcing Helper
**Impact**: Prevents future undefined function errors across all commands
**Effort**: MEDIUM (2-3 hours)
**Risk**: MEDIUM (requires updating all orchestrator commands)

**Scope**: All orchestrator commands (/plan, /research, /debug, /revise, /build)

**Implementation Plan**:
1. Create `.claude/lib/core/source-libraries.sh` with block-specific profiles
2. Add `source_libraries_for_block()` function
3. Update all commands to use helper
4. Add linting rule to prevent manual sourcing
5. Document standard in `.claude/docs/reference/standards/command-reference.md`

#### Improvement 2: Enhance Error Trap with Stack Trace
**Impact**: Improves debugging of 9% of errors (1/11) with poor attribution
**Effort**: MEDIUM (1-2 hours)
**Risk**: LOW

**Implementation Plan**:
1. Update `setup_bash_error_trap()` in error-handling.sh
2. Add stack trace capture to ERR trap
3. Update error log schema to include stack_trace field
4. Test with known failure scenarios

#### Improvement 3: Add State Restoration Validation
**Impact**: Prevents cascading failures from partial state loads
**Effort**: MEDIUM (2 hours)
**Risk**: LOW

**Implementation Plan**:
1. Add `validate_state_variables()` to state-persistence.sh
2. Update all commands to validate state after load_workflow_state()
3. Document required variables per block in command standards

### Long-Term Infrastructure (Low Priority, High Value)

#### Infrastructure 1: Agent Output Guarantees Framework
**Impact**: Systematic solution for all agent integration failures
**Effort**: HIGH (1-2 days)
**Risk**: MEDIUM (requires agent behavioral changes)

**Scope**: All agents, all commands that invoke agents

**Implementation Plan**:
1. Add `validate_agent_output()` to error-handling.sh
2. Update agent behavioral requirement: MUST return TASK_ERROR on Write failures
3. Add agent output timeout monitoring (default 5s wait)
4. Update all commands to use validation framework
5. Add agent output validation to command standards

#### Infrastructure 2: System-Wide Library Sourcing Audit
**Impact**: Prevents cross-command propagation of undefined function errors
**Effort**: HIGH (3-5 days)
**Risk**: HIGH (requires testing all commands)

**Scope**: All commands, all bash blocks

**Implementation Plan**:
1. Audit all commands for library sourcing patterns
2. Identify missing sourcing (like Block 1c)
3. Create standardized sourcing profiles per block type
4. Update all commands to use source_libraries_for_block()
5. Add automated linting to detect manual sourcing
6. Document sourcing standard in command development guide

#### Infrastructure 3: Portable Environment Detection
**Impact**: Supports non-standard systems (NixOS, FreeBSD, Alpine)
**Effort**: MEDIUM (1 day)
**Risk**: LOW

**Implementation Plan**:
1. Add environment detection to detect-project-dir.sh (Linux, NixOS, macOS, BSD)
2. Create portable shell initialization pattern
3. Add environment field to error logs
4. Document supported environments in README
5. Add environment-specific troubleshooting to docs

---

## Testing Strategy

### Unit Tests
**Scope**: Individual components fixed

1. **Test: append_workflow_state available in Block 1c**
   - Mock: WORKFLOW_ID, STATE_FILE
   - Action: Source Block 1c libraries, call append_workflow_state
   - Assert: Function exists, no exit code 127

2. **Test: Agent output validation detects missing file**
   - Mock: Agent Task invocation (does not create file)
   - Action: Call validate_agent_output()
   - Assert: Returns 1, logs agent_error

3. **Test: Portable shell initialization on NixOS**
   - Environment: NixOS (no /etc/bashrc)
   - Action: Call init_portable_shell()
   - Assert: Returns 0, no errors

### Integration Tests
**Scope**: Full workflow execution

1. **Test: /plan workflow completes without errors**
   - Action: `/plan "test feature description"`
   - Assert:
     - No "command not found" errors
     - Topic directory created (not "no_name" fallback)
     - Plan file created
     - Error log clean (0 errors for this workflow)

2. **Test: Agent failure gracefully falls back**
   - Setup: Mock agent to not create output file
   - Action: `/plan "test with agent failure"`
   - Assert:
     - Workflow completes with "no_name" fallback
     - Error log contains agent_error with diagnostic context
     - User sees warning message

3. **Test: Cross-command library sourcing**
   - Commands: /plan, /research, /debug, /revise
   - Action: Execute each command
   - Assert: No "command not found" errors in any bash block

### Regression Tests
**Scope**: Prevent error patterns from returning

1. **Test: No bashrc sourcing failures on NixOS**
   - Environment: NixOS
   - Action: `/plan "test"`
   - Assert: No exit code 127 errors

2. **Test: State persistence works across blocks**
   - Action: `/plan "test"`
   - Assert:
     - FEATURE_DESCRIPTION persists from Block 1a to Block 1c
     - append_workflow_state succeeds in Block 1c
     - State file contains all expected variables

---

## References

### Source Files Analyzed
1. `/home/benjamin/.config/.claude/plan-output.md` - Command execution log showing error symptoms
2. `/home/benjamin/.config/.claude/specs/102_plan_command_error_analysis/reports/001_error_report.md` - Error analysis with patterns
3. `/home/benjamin/.config/.claude/commands/plan.md` - /plan command implementation
4. `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error handling library (lines 1-1352)
5. `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` - Initialization library (lines 1-924)
6. `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` - Topic naming agent specification
7. `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md` - Command standards
8. `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` - Error handling patterns

### Standards Consulted
- **Error Handling Pattern**: Centralized JSONL logging, agent error return protocol
- **Command Reference**: Command development standards, library sourcing requirements
- **Directory Protocols**: Topic-based structure, LLM naming, plan levels
- **Testing Protocols**: Test discovery, isolation standards

### Error Patterns Identified
1. **State Management**: append_workflow_state: command not found (lines 319, 183, 323)
2. **Agent Integration**: Topic naming agent no output file (3/3 failures)
3. **Environment Setup**: Bashrc sourcing exit code 127 (line 1)
4. **Validation Logic**: Generic execution error line 252 (attribution artifact)
5. **Cross-Command**: initialize_workflow_paths: command not found (in /debug)

---

## Appendix: Error Timeline

### Workflow plan_1763705583 (06:13-06:17, duration: 3m 15s)
1. 06:13:55 - bashrc sourcing failure (line 1, exit 127)
2. 06:16:44 - Topic naming agent failed (agent_no_output_file)
3. 06:16:44 - bashrc sourcing failure (line 1, exit 127, retry)
4. 06:17:10 - Topic naming agent failed (agent_no_output_file, retry)
5. 06:17:10 - append_workflow_state: command not found (line 319)

**Analysis**: Cascading failures - bashrc error at startup, agent fails twice, state persistence fails

### Workflow plan_1763707476 (06:46-06:47, duration: 19s)
1. 06:46:58 - bashrc sourcing failure (line 1, exit 127)
2. 06:47:17 - append_workflow_state: command not found (line 183)

**Analysis**: Fast failure - bashrc error followed by state persistence error

### Workflow plan_1763707955 (06:54-06:59, duration: 4m 22s)
1. 06:54:44 - Topic naming agent failed (agent_no_output_file)
2. 06:59:06 - Generic execution error (line 252, exit 1)

**Analysis**: Agent failure followed by validation error (attribution artifact)

### Workflow plan_1763742651 (16:32-16:33, duration: 20s)
1. 16:32:54 - bashrc sourcing failure (line 1, exit 127)
2. 16:33:14 - Topic naming agent failed (agent_no_output_file)
3. 16:33:14 - append_workflow_state: command not found (line 323)

**Analysis**: Complete failure sequence - all three root causes triggered

---

**End of Root Cause Analysis Report**

REPORT_CREATED: /home/benjamin/.config/.claude/specs/890_plan_command_error_debug_infrastructure/reports/001_root_cause_analysis.md
