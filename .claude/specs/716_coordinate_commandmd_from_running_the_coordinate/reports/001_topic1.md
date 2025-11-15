# Coordinate Command Error Analysis

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Coordinate Command Error Analysis
- **Report Type**: error analysis

## Executive Summary

The coordinate command execution failed with multiple unbound variable errors, primarily related to `CLASSIFICATION_JSON` not being properly persisted across bash subprocess boundaries. Root causes include: (1) state persistence failing after Task invocations due to subprocess isolation, (2) `load_workflow_state` re-enabling `set -u` flag causing strict variable checking, and (3) missing state file creation/loading logic in workflow initialization sequence.

## Findings

### 1. Primary Error Pattern: Unbound Variable CLASSIFICATION_JSON

**Error Manifestation** (lines 67-68, 75-76, 382-383, 561-562):
```
/home/benjamin/.config/.claude/tmp/workflow_coordinate_1763179819.sh: line 16: CLASSIFICATION_JSON: unbound variable
```

**Frequency**: Occurred 4 times across multiple bash blocks after Task invocation

**Context**: Error occurs when coordinate command attempts to load workflow state after the workflow-classifier agent completes classification via Task tool.

### 2. Root Cause Analysis

#### 2.1 Subprocess Isolation Boundary

**Core Issue**: Task invocations create subprocess boundaries where bash state is NOT inherited.

**Evidence**:
- Line 170-190 (coordinate.md): Task tool invokes workflow-classifier agent
- Line 192-220 (coordinate.md): New bash block after Task must re-source libraries and reload state
- Lines 538-580 (workflow-classifier.md): Agent instructed to save classification to state via `append_workflow_state`
- Console output line 42-55: Agent did NOT execute the bash block to save state

**Critical Discovery**: The workflow-classifier agent behavioral file (lines 530-586) contains bash block instructions to save classification to state, but the agent returned text-only classification without executing the bash save operation.

#### 2.2 State Persistence Library Behavior

**Library Source**: `.claude/lib/state-persistence.sh`

**Key Behaviors**:
1. Line 81: Sets `set -uo pipefail` (enables unbound variable checking)
2. Line 187-228: `load_workflow_state()` function sources state file
3. Line 194: When state file sourced, `set -uo pipefail` is re-applied to current shell
4. Line 254-269: `append_workflow_state()` appends export statements to state file

**Problem**: When `load_workflow_state` is called and `CLASSIFICATION_JSON` hasn't been saved to state file, the `set -u` flag causes immediate exit when code attempts to reference `${CLASSIFICATION_JSON:-}`.

#### 2.3 Workaround Attempts in Console Output

**Attempt 1** (lines 62-77): Used `set -euo pipefail` (still has `-u` flag) → Failed
**Attempt 2** (lines 82-85): Disabled `-u` via `set +u` temporarily → Partial success
**Attempt 3** (lines 394-557): Multiple attempts with `set +u` → Eventually succeeded after manual state file creation

**Pattern**: All failed attempts show the coordinate command tried to work around the issue by disabling strict mode, but the root cause (agent not saving state) persisted.

### 3. Error Handling Gap Analysis

#### 3.1 Missing Verification Checkpoint

**Location**: coordinate.md lines 222-236

**Current Behavior**:
```bash
# FAIL-FAST VALIDATION: Classification must exist in state
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  handle_state_error "CRITICAL: workflow-classifier agent did not save CLASSIFICATION_JSON to state..."
fi
```

**Problem**: This check happens AFTER `load_workflow_state` already triggered unbound variable error at line 220. The fail-fast validation never executes because bash exits at line 220.

**Gap**: No pre-validation that state file contains `CLASSIFICATION_JSON` before attempting to reference it.

#### 3.2 Agent Behavioral Compliance Gap

**Expectation** (workflow-classifier.md lines 530-586): Agent MUST execute bash block to save classification to state

**Reality** (console output line 34-35): Task tool completed after 36.1k tokens and 13s, but no bash block was executed

**Gap**: No verification checkpoint after Task invocation to ensure agent executed required bash blocks. The coordinate command blindly assumes agent compliance.

#### 3.3 State Persistence Failure Detection

**Current Behavior**: `load_workflow_state` assumes state file exists and is complete
**Missing**: Pre-flight check to verify state file contains expected variables before sourcing

**Proposed Check** (not currently implemented):
```bash
# Verify state file contains required variable before sourcing
if ! grep -q "export CLASSIFICATION_JSON=" "$STATE_FILE"; then
  handle_state_error "Agent did not save CLASSIFICATION_JSON to state file"
fi
```

### 4. Bash Block Execution Model Issues

**Reference**: `.claude/docs/concepts/bash-block-execution-model.md` (referenced in coordinate.md line 120, 146)

**Issue**: Each bash block runs in separate subprocess, requiring:
1. Re-detection of CLAUDE_PROJECT_DIR (or loading from state)
2. Re-sourcing of all libraries
3. Re-loading of workflow state

**Pattern Violation**: The workflow-classifier agent did NOT follow the "save-before-source" pattern required for cross-bash-block state persistence.

**Expected Pattern**:
```
Step 1: Agent generates classification (in-memory)
Step 2: Agent executes bash block to save to state
Step 3: Agent returns completion signal
```

**Actual Pattern**:
```
Step 1: Agent generates classification (in-memory)
Step 2: Agent returns completion signal (SKIPPED bash save)
Step 3: Coordinate command fails to load missing state
```

### 5. Secondary Errors

#### 5.1 State File Path Confusion

**Evidence** (lines 578-599):
- Line 584: Checked wrong path `.claude/data/workflow_state_coordinate_*.env`
- Line 619: Correct path is `.claude/tmp/workflow_coordinate_*.sh`

**Cause**: Comment in error diagnostic referenced obsolete `.claude/data/` directory instead of current `.claude/tmp/` location.

#### 5.2 Variable Re-initialization After Library Sourcing

**Evidence** (lines 663-693):
- Line 670: Variables empty after library sourcing
- Line 679-681: Only WORKFLOW_SCOPE and TOPIC_PATH present in state
- Line 687-692: Manual addition of RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON required

**Pattern**: State variables not persisted by agent, requiring manual workaround in console session.

## Recommendations

### 1. Add Pre-Load State Validation (Priority: Critical)

**Location**: coordinate.md line 220 (before `load_workflow_state`)

**Implementation**:
```bash
# VERIFICATION CHECKPOINT: Check state file contains required variable
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ ! -f "$STATE_FILE" ]; then
  handle_state_error "State file missing: $STATE_FILE" 2
fi

if ! grep -q "^export CLASSIFICATION_JSON=" "$STATE_FILE"; then
  handle_state_error "CRITICAL: workflow-classifier agent did not save CLASSIFICATION_JSON to state

Diagnostic:
  - State file exists: $STATE_FILE
  - But CLASSIFICATION_JSON not found in state
  - Agent likely returned text instead of executing bash save block
  - Review agent response for bash execution confirmation

This indicates agent behavioral non-compliance." 1
fi

# Now safe to load state (CLASSIFICATION_JSON definitely exists)
load_workflow_state "$WORKFLOW_ID"
```

**Benefit**: Fail-fast with clear diagnostic BEFORE unbound variable error triggers.

### 2. Enhance Agent Invocation with Post-Task Verification (Priority: Critical)

**Location**: coordinate.md line 191 (after Task invocation)

**Implementation**:
```bash
# VERIFICATION CHECKPOINT: Ensure agent executed bash save block
# Agent MUST have saved CLASSIFICATION_JSON to state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

# Allow 2-second grace period for file system sync
sleep 2

if ! grep -q "^export CLASSIFICATION_JSON=" "$STATE_FILE" 2>/dev/null; then
  echo "❌ CRITICAL: workflow-classifier agent did not execute state save bash block"
  echo ""
  echo "Expected agent behavior:"
  echo "  1. Generate classification JSON"
  echo "  2. Execute bash block to append_workflow_state"
  echo "  3. Return CLASSIFICATION_COMPLETE signal"
  echo ""
  echo "Actual agent behavior:"
  echo "  1. Generated classification JSON"
  echo "  2. SKIPPED bash block execution"
  echo "  3. Returned text-only response"
  echo ""
  echo "Fallback: Manually checking agent response for classification JSON..."

  # Fallback parser (extract JSON from agent response if present)
  # Implementation TBD based on response format
fi
```

**Benefit**: Detect agent non-compliance immediately after Task completion, before attempting to load state.

### 3. Modify load_workflow_state to Gracefully Handle Missing Variables (Priority: Medium)

**Location**: `.claude/lib/state-persistence.sh` line 187-228

**Current Issue**: `set -uo pipefail` at line 81 makes library fail-fast on unbound variables

**Proposed Change**:
```bash
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"
  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  # Temporarily disable unbound variable checking during source
  # to allow ${VAR:-} syntax in caller code
  local previous_opts=$(set +o)
  set +u

  if [ -f "$state_file" ]; then
    source "$state_file"
    # Restore previous options (but keep -u disabled for caller)
    # Caller can re-enable if needed
    return 0
  else
    # ... existing error handling ...
  fi
}
```

**Rationale**: Allow caller code to use `${VAR:-default}` syntax without failing on unbound variables before they check if variable exists.

**Risk**: May hide unbound variable bugs in other code. Requires careful testing.

### 4. Enhance Workflow-Classifier Agent Behavioral File (Priority: High)

**Location**: `.claude/agents/workflow-classifier.md` lines 530-586

**Issue**: Instructions are present but agent may not execute them reliably

**Proposed Enhancement**:

1. **Add explicit execution instruction before bash block**:
```markdown
**CRITICAL - YOU MUST EXECUTE THIS BASH BLOCK NOW**

DO NOT skip this step. DO NOT return text instead.
The coordinate command WILL FAIL if you skip bash execution.

**EXECUTE IMMEDIATELY using the Bash tool**:
```

2. **Add verification step after bash execution**:
```markdown
**VERIFICATION CHECKPOINT**

After executing the bash block above, verify:
- [ ] Bash tool reported success (no errors)
- [ ] Console shows "✓ Classification saved to state successfully"
- [ ] No error messages about missing state file

If verification fails, retry the bash block execution.
```

3. **Simplify bash block to reduce failure modes**:
```bash
#!/usr/bin/env bash
# CRITICAL: This block MUST execute for coordinate command to proceed

# Detect project directory
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Load state persistence library
source "$CLAUDE_PROJECT_DIR/.claude/lib/state-persistence.sh"

# Load workflow ID from fixed file location
WORKFLOW_ID=$(cat "$CLAUDE_PROJECT_DIR/.claude/tmp/coordinate_state_id.txt")

# REPLACE THIS LINE with your actual classification JSON
CLASSIFICATION_JSON='{"workflow_type":"research-and-plan","confidence":0.95,...}'

# Save to state (REQUIRED)
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"

echo "✓ Classification saved to state"
```

**Benefit**: Clearer instructions, explicit verification, simpler bash block reduces execution failures.

### 5. Add State File Diagnostic Command (Priority: Low)

**Location**: New utility script `.claude/lib/diagnose-workflow-state.sh`

**Purpose**: Debug state persistence issues during development

**Implementation**:
```bash
#!/usr/bin/env bash
# diagnose-workflow-state.sh - Debug workflow state persistence

diagnose_workflow_state() {
  local workflow_id="$1"
  local state_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

  echo "=== Workflow State Diagnostic ==="
  echo "Workflow ID: $workflow_id"
  echo "State file: $state_file"
  echo ""

  if [ -f "$state_file" ]; then
    echo "✓ State file exists"
    echo "File size: $(wc -c < "$state_file") bytes"
    echo ""
    echo "Variables in state:"
    grep "^export " "$state_file" | sed 's/^export /  - /' | cut -d= -f1
    echo ""
    echo "Missing expected variables:"
    for var in CLASSIFICATION_JSON WORKFLOW_SCOPE RESEARCH_COMPLEXITY; do
      if ! grep -q "^export $var=" "$state_file"; then
        echo "  ✗ $var"
      fi
    done
  else
    echo "✗ State file not found"
  fi
}
```

**Usage**: `source .claude/lib/diagnose-workflow-state.sh && diagnose_workflow_state "$WORKFLOW_ID"`

### 6. Document Bash Block Execution Model Requirements (Priority: Medium)

**Location**: `.claude/docs/concepts/bash-block-execution-model.md` (add new section)

**Content**: Agent Cross-Subprocess State Persistence Requirements

**Key Points**:
1. Agents invoked via Task tool run in separate subprocess
2. In-memory agent state does NOT persist to parent coordinate command
3. Agents MUST use `append_workflow_state` to persist data
4. Bash block execution is MANDATORY, not optional
5. Text-only returns without bash execution cause workflow failures

**Benefit**: Clear architectural documentation prevents future agent behavioral issues.

## References

### Console Output
- `/home/benjamin/.config/.claude/specs/coordinate_command.md` (complete console output, 773 lines)

### Command Files
- `.claude/commands/coordinate.md:170-249` - Workflow classification phase and state loading logic
- `.claude/commands/coordinate.md:100-163` - State machine initialization

### Agent Behavioral Files
- `.claude/agents/workflow-classifier.md:530-586` - State persistence instructions (not executed)
- `.claude/agents/workflow-classifier.md:1-528` - Classification logic

### Library Files
- `.claude/lib/state-persistence.sh:81` - set -uo pipefail flag
- `.claude/lib/state-persistence.sh:187-228` - load_workflow_state function
- `.claude/lib/state-persistence.sh:254-269` - append_workflow_state function
- `.claude/lib/workflow-state-machine.sh:26` - set -euo pipefail flag

### Documentation References
- `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation patterns (referenced in coordinate.md:120, 146)

### Error Instances
- Console output lines 42-55: First unbound variable error and diagnostic
- Console output lines 67-76: Second unbound variable error after set -euo pipefail
- Console output lines 379-392: Third unbound variable error
- Console output lines 558-565: Fourth unbound variable error
- Console output lines 642-661: Fifth unbound variable error (RESEARCH_COMPLEXITY)
