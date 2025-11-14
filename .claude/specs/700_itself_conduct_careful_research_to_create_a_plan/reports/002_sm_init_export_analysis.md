# sm_init Variable Export Analysis

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist
- **Topic**: sm_init variable export failures
- **Report Type**: root cause analysis
- **Complexity Level**: 4

## Executive Summary

The sm_init variable export failures in coordinate.md are caused by bash subprocess isolation, NOT by errors in sm_init itself. Each bash block runs in a separate subprocess where exports don't propagate to parent shells. The error message is misleading - sm_init DOES export the variables successfully within its subprocess, but those exports are immediately lost when the subprocess terminates. The solution requires explicit state persistence via append_workflow_state() after sm_init returns.

## Findings

### Finding 1: Bash Block Subprocess Isolation (Root Cause)

**Location**: Claude Code execution model, documented in `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-369`

**Core Issue**: Each bash block in Claude Code command files runs as a **separate subprocess** (not subshell), causing complete isolation between blocks:

```bash
# Bash Block 1 (PID: 12345)
export VAR="value"  # Set in subprocess
# Subprocess terminates, VAR lost

# Bash Block 2 (PID: 12346 - NEW PROCESS)
echo "$VAR"  # Empty - previous export doesn't exist
```

**Key Characteristics** (bash-block-execution-model.md:35-48):
- Process ID changes between blocks
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Only files written to disk persist across blocks

**Validation Test** (bash-block-execution-model.md:72-145):
```bash
# Test confirms: exports don't persist
export TEST_VAR="set_in_block_1"
# Next block: TEST_VAR is unset (subprocess boundary)
```

### Finding 2: sm_init Export Behavior is Correct

**Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:337-416`

**Export Statements** (lines 364-366):
```bash
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON
```

**Why Exports Succeed BUT Variables Disappear**:
1. sm_init successfully exports variables (lines 364-366)
2. Classification completes and sets values (line 352-358)
3. Function returns successfully (return code 0)
4. **Bash block terminates immediately after return**
5. All exports lost when subprocess exits
6. Next bash block starts with clean environment

**Evidence** (coordinate.md:166-169):
```bash
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed..." 1
fi
# Variables now available via export (verified by successful sm_init return code check above)
```

**Comment is misleading**: The verification happens in SAME subprocess where sm_init ran. Variables ARE available in that subprocess, but will be lost after block exit.

### Finding 3: The Real Problem - Missing State Persistence

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:166-209`

**Current Flow** (BROKEN):
```bash
# Bash Block (Initialization)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1  # Exports variables
# Verification passes (lines 173-183)
echo "✓ State machine variables verified..."  # Variables exist in THIS subprocess
# Bash block ends → subprocess terminates → exports lost

# Next Bash Block (Research Phase)
# NEW SUBPROCESS - no memory of previous exports
load_workflow_state "$WORKFLOW_ID"  # Loads state file
# WORKFLOW_SCOPE NOT in state file → still unset
```

**The Gap** (coordinate.md:206-209):
```bash
# Save state machine configuration to workflow state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

**Critical Omission**: RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON are exported but NEVER persisted to workflow state. They exist only in the initialization subprocess and are lost when it terminates.

### Finding 4: Historical Context - This Bug Was Fixed Before

**Location**: `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md:2048-2124`

**Spec 683 - Issue 5: Subshell Export Pattern** (coordinate-command-guide.md:2075-2092):

**Previous Bug Pattern**:
```bash
# Incorrect pattern (don't use):
COMPLEXITY=$(sm_init "$workflow_desc" "coordinate")
```

**Problem**: Command substitution $(...)  creates subprocess, exports in subprocess don't affect parent shell.

**Fix Applied**:
```bash
# Correct pattern (use this):
sm_init "$workflow_desc" "coordinate" >/dev/null
# Variables now available: $WORKFLOW_SCOPE, $RESEARCH_COMPLEXITY, $RESEARCH_TOPICS_JSON
```

**Why Fix is Incomplete**: While this fixed command substitution issue (exports now work in SAME bash block), it didn't address subprocess isolation (exports don't persist to NEXT bash block).

**Related Issue - Spec 683 Issue 6** (coordinate-command-guide.md:2098-2124):
RESEARCH_COMPLEXITY recalculation mismatch caused 40-50% verification failures. Solution: Use sm_init values consistently, don't recalculate. But this assumes sm_init values persist across bash blocks (they don't without state persistence).

### Finding 5: Documented Pattern - Save-Before-Source

**Location**: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:193-224`

**Pattern 2: Save-Before-Source Pattern** (bash-block-execution-model.md:193-224):

**Problem**: State ID must persist across subprocess boundaries.

**Solution**: Save state to fixed location file before subprocess terminates.

```bash
# Part 1: Initialize and save state ID
WORKFLOW_ID="coordinate_$(date +%s)"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Part 2: Load state ID in next bash block
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE"
```

**Pattern 3: State Persistence Library** (bash-block-execution-model.md:226-248):

**Standardized State Management**:
```bash
# After sm_init exports succeed:
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"

# Next bash block:
load_workflow_state "$WORKFLOW_ID"
# All three variables restored from state file
```

**This pattern is documented but NOT applied to RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON in coordinate.md.**

### Finding 6: Error Message Misleading

**Location**: `/home/benjamin/.config/.claude/specs/coordinage_implement.md:35-38`

**Error Message**:
```
✗ ERROR in state 'initialize': CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)
```

**Why Message is Wrong**:
1. **Not a library bug**: sm_init exports correctly (line 364-366)
2. **"Not exported" is inaccurate**: Variables ARE exported in initialization subprocess
3. **Real issue**: Variables not persisted to state file before subprocess exit
4. **Better message**: "CRITICAL: WORKFLOW_SCOPE not persisted to workflow state (missing append_workflow_state call)"

**Verification Checkpoint Location** (coordinate.md:171-183):
```bash
# VERIFICATION CHECKPOINT: Verify critical variables exported by sm_init
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)" 1
fi
```

**Issue**: Verification runs in SAME subprocess as sm_init, so it always passes. The real failure happens in NEXT bash block when variables are missing from loaded state.

## Root Cause Analysis

### Primary Root Cause: State Persistence Gap

**What Happens**:
1. sm_init successfully exports WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON (workflow-state-machine.sh:364-366)
2. Exports are verified successfully in same subprocess (coordinate.md:173-183)
3. WORKFLOW_SCOPE is persisted to state (coordinate.md:206)
4. **RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON are NOT persisted** (gap in coordinate.md:206-209)
5. Bash block terminates, subprocess exits, all exports lost
6. Next bash block starts fresh subprocess, loads state file
7. RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON are missing from state file
8. Variables remain unset, causing downstream failures

### Secondary Root Cause: Verification Timing

**Current Verification** (coordinate.md:171-183):
- Runs immediately after sm_init in SAME subprocess
- Verifies exports exist in current subprocess memory
- Passes successfully because exports DO exist at that moment
- **Doesn't detect that exports won't persist**

**Better Verification Would**:
- Run in NEXT bash block after state load
- Verify variables exist in loaded state
- Detect missing persistence immediately

### Architectural Root Cause: Bash Block Subprocess Isolation

**Claude Code Execution Model**:
- Each bash block = separate subprocess (not subshell)
- Subprocess isolation prevents export propagation
- Only file-based persistence survives subprocess boundaries
- This is intentional tool design, not a bug

**Documentation** (bash-block-execution-model.md:1-69):
- Well-documented constraint
- Validated patterns exist (Pattern 2, Pattern 3)
- State persistence library exists (.claude/lib/state-persistence.sh)
- **Gap**: Pattern not applied consistently in coordinate.md

## Recommendations

### Recommendation 1: Persist All sm_init Exports to Workflow State

**Priority**: CRITICAL (blocks coordinate.md execution)

**Implementation**:
```bash
# In coordinate.md after sm_init call (line 185)
# Add missing state persistence:
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"

# Existing persistence (line 206):
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

**Rationale**:
- sm_init exports three variables (workflow-state-machine.sh:364-366)
- Only one is persisted (coordinate.md:206)
- Missing persistence causes subprocess boundary loss
- All three must be persisted for consistency

**Files to Modify**:
- /home/benjamin/.config/.claude/commands/coordinate.md:185-210

### Recommendation 2: Update Verification Error Messages

**Priority**: HIGH (prevents misleading debugging)

**Implementation**:
```bash
# Replace coordinate.md:174
# Old message:
"CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)"

# New message:
"CRITICAL: WORKFLOW_SCOPE not persisted to workflow state (missing append_workflow_state call after sm_init)"
```

**Rationale**:
- Current message blames sm_init (incorrect)
- Real issue is missing state persistence
- Accurate error messages accelerate debugging
- Prevents false investigation of workflow-state-machine.sh

**Files to Modify**:
- /home/benjamin/.config/.claude/commands/coordinate.md:174, 178, 182

### Recommendation 3: Move Verification to Next Bash Block

**Priority**: MEDIUM (improves reliability detection)

**Implementation**:
```bash
# Current: Verification in initialization block (coordinate.md:171-183)
# Problem: Verifies exports in same subprocess (always passes)

# Better: Verification in research block (after state load)
load_workflow_state "$WORKFLOW_ID"

# Verify state persistence worked
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE missing from workflow state after initialization" 1
fi

if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_COMPLEXITY missing from workflow state after initialization" 1
fi

if [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_TOPICS_JSON missing from workflow state after initialization" 1
fi
```

**Rationale**:
- Detects subprocess boundary persistence failures
- Tests actual cross-block state transfer
- Catches missing append_workflow_state calls immediately
- Aligns with Standard 0 (Execution Enforcement) verification pattern

**Trade-off**: Adds verification overhead to each bash block, but gains fail-fast detection.

### Recommendation 4: Add sm_init Documentation Comment

**Priority**: LOW (documentation improvement)

**Implementation**:
```bash
# Add to workflow-state-machine.sh:337
# sm_init: Initialize workflow state machine with comprehensive classification
#
# CRITICAL: This function exports variables to the CURRENT subprocess only.
# Exports do NOT persist across bash block boundaries (subprocess isolation).
# Calling commands MUST persist exported values using append_workflow_state():
#
#   sm_init "$workflow_desc" "command_name"
#   append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
#   append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
#   append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"
#
# Args:
#   $1: workflow_desc - Workflow description for classification
#   $2: command_name - Name of calling command (for logging)
#
# Exports (temporary, subprocess-scoped):
#   WORKFLOW_SCOPE - Workflow classification (research-and-plan, etc.)
#   RESEARCH_COMPLEXITY - Complexity score (1-5)
#   RESEARCH_TOPICS_JSON - JSON array of research subtopics
#
# Returns:
#   0: Success (classification complete, variables exported)
#   1: Failure (classification failed, see stderr)
```

**Rationale**:
- Clarifies sm_init export lifetime
- Documents required state persistence pattern
- Prevents future implementations from forgetting persistence
- Reduces misleading "library bug" assumptions

**Files to Modify**:
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:337

### Recommendation 5: Create Validation Test for State Persistence

**Priority**: MEDIUM (prevents regression)

**Implementation**:
Create `/home/benjamin/.config/.claude/tests/test_sm_init_state_persistence.sh`:

```bash
#!/usr/bin/env bash
# Test: sm_init exports persist via state persistence
# Validates: Recommendation 1 implementation

set -euo pipefail
source "$(dirname "$0")/../lib/workflow-state-machine.sh"
source "$(dirname "$0")/../lib/state-persistence.sh"

# Test: sm_init exports don't persist without state persistence
test_exports_lost_without_persistence() {
  # Simulate bash block 1
  sm_init "Research authentication patterns" "test_command" >/dev/null

  # Variables exist in current subprocess
  [[ -n "${WORKFLOW_SCOPE:-}" ]] || exit 1
  [[ -n "${RESEARCH_COMPLEXITY:-}" ]] || exit 1
  [[ -n "${RESEARCH_TOPICS_JSON:-}" ]] || exit 1

  # Simulate bash block 2 (subprocess boundary)
  # Don't persist to state, just verify they're lost
  bash -c 'echo "WORKFLOW_SCOPE=${WORKFLOW_SCOPE:-unset}"' | grep -q "unset"
}

# Test: sm_init exports persist with state persistence
test_exports_persist_with_persistence() {
  WORKFLOW_ID="test_$(date +%s)"

  # Simulate bash block 1
  sm_init "Research authentication patterns" "test_command" >/dev/null
  append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
  append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
  append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"

  # Simulate bash block 2 (load state)
  load_workflow_state "$WORKFLOW_ID"

  # Verify variables persisted
  [[ -n "${WORKFLOW_SCOPE:-}" ]] || exit 1
  [[ -n "${RESEARCH_COMPLEXITY:-}" ]] || exit 1
  [[ -n "${RESEARCH_TOPICS_JSON:-}" ]] || exit 1
}

# Run tests
test_exports_lost_without_persistence && echo "✓ Test 1 passed"
test_exports_persist_with_persistence && echo "✓ Test 2 passed"
```

**Rationale**:
- Automated validation of subprocess isolation behavior
- Prevents regression if coordinate.md is refactored
- Documents expected behavior via executable test
- Integrates with existing test suite (.claude/tests/)

## References

### Primary Source Files
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:337-416` - sm_init function implementation and export statements
- `/home/benjamin/.config/.claude/commands/coordinate.md:166-209` - sm_init call site and state persistence gap
- `/home/benjamin/.config/.claude/specs/coordinage_implement.md:35-38` - Error message triggering this investigation
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - State persistence library (append_workflow_state, load_workflow_state)

### Documentation References
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-369` - Complete subprocess isolation patterns and validation tests
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:35-48` - Subprocess vs subshell characteristics
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:72-145` - Validation test demonstrating export loss
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:193-224` - Pattern 2: Save-Before-Source
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:226-248` - Pattern 3: State Persistence Library
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md:2048-2124` - Historical context (Spec 683 Issues 5 and 6)
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md:2075-2092` - Previous subshell export bug fix

### Related Issues
- Spec 683 Issue 5: Subshell export pattern (command substitution bug, previously fixed)
- Spec 683 Issue 6: RESEARCH_COMPLEXITY recalculation mismatch (40-50% failure rate)
- Current Issue: RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON not persisted (100% failure rate in next bash block)
