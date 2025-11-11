# Bash Variable Scoping Issue in /coordinate Command

## Executive Summary

**Issue**: The `/coordinate` command fails at initialization with error `initialize_workflow_paths() requires WORKFLOW_DESCRIPTION as first argument`

**Root Cause**: Global variable pre-initialization in `workflow-state-machine.sh` (line 76) overwrites the parent script's `WORKFLOW_DESCRIPTION` variable when the library is sourced, causing it to be empty string when passed to functions.

**Impact**: Critical - prevents `/coordinate` from executing any workflows

**Solution**: Save `WORKFLOW_DESCRIPTION` to temporary variable before sourcing library, use saved value in `sm_init()` call

**Validation**: Fix tested and confirmed working - initialization succeeds, creates topic directory at expected path

---

## Detailed Analysis

### 1. Failure Reproduction

**Command**: `/coordinate "Research bash execution patterns and state management"`

**Error Output**:
```
State machine initialized: scope=research-and-plan, terminal=plan
ERROR: initialize_workflow_paths() requires WORKFLOW_DESCRIPTION as first argument
```

**Observation**: State machine initialization succeeds (shows correct scope detection), but subsequent function call fails due to empty parameter.

---

### 2. Root Cause Investigation

#### Execution Flow Analysis

**File**: `.claude/commands/coordinate.md`

**Critical sequence** (lines 52-158):

```bash
# Line 52: Read workflow description from file
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE" ...)

# Line 78: Export (before sourcing library)
export WORKFLOW_DESCRIPTION

# Line 88-92: Source state machine library
source "${LIB_DIR}/workflow-state-machine.sh"  # ← OVERWRITES VARIABLE

# Line 117: Call sm_init (with now-empty variable)
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"  # ← FAILS

# Line 158: Call initialization (variable still empty)
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"  # ← FAILS
```

#### Library Variable Declaration

**File**: `.claude/lib/workflow-state-machine.sh`

**Problematic code** (lines 74-77):

```bash
# Workflow configuration
WORKFLOW_SCOPE=""
WORKFLOW_DESCRIPTION=""  # ← GLOBAL INITIALIZATION OVERWRITES PARENT
COMMAND_NAME=""
```

**Behavior**: When library is sourced, these global variable declarations OVERWRITE any values set in the parent script BEFORE the `source` command.

---

### 3. Bash Variable Scoping Behavior

#### Scoping Rules

1. **Global variables** in sourced libraries share scope with parent script
2. **Variable declarations** in libraries (e.g., `VAR=""`) execute when library is sourced
3. **Declarations overwrite** parent variables with same name (no namespace isolation)

#### Demonstration

**Test code**:
```bash
# Parent script
MY_VAR="parent value"
echo "$MY_VAR"  # Output: "parent value"

# Source library containing: MY_VAR=""
source library.sh

echo "$MY_VAR"  # Output: "" (OVERWRITES parent value!)
```

**Key insight**: Bash does NOT preserve parent variables when sourcing libraries that declare variables with same names.

---

### 4. State Machine Variable Lifecycle

#### Current (Broken) Flow

```
┌─────────────────────────────────────────────────────────────┐
│ coordinate.md: WORKFLOW_DESCRIPTION="Research ..."         │
├─────────────────────────────────────────────────────────────┤
│ source workflow-state-machine.sh                           │
│   ↓                                                          │
│ workflow-state-machine.sh: WORKFLOW_DESCRIPTION=""  ← BUG   │
├─────────────────────────────────────────────────────────────┤
│ coordinate.md: sm_init "$WORKFLOW_DESCRIPTION" ...         │
│                        ^^^^^^^^^^^^^^^^^^^^                  │
│                        Empty string!                         │
└─────────────────────────────────────────────────────────────┘
```

#### Why sm_init succeeds but initialize_workflow_paths fails

**sm_init behavior** (line 91 of workflow-state-machine.sh):
```bash
sm_init() {
  local workflow_desc="$1"  # Receives "" from coordinate.md
  WORKFLOW_DESCRIPTION="$workflow_desc"  # Sets library's variable to ""
  # ...
}
```

**Result**: `sm_init` sets the library's `WORKFLOW_DESCRIPTION` to empty string, then uses it for scope detection (which reads the description from the first parameter, not the global variable).

**initialize_workflow_paths behavior** (line 86 of workflow-initialization.sh):
```bash
initialize_workflow_paths() {
  local workflow_description="${1:-}"  # Receives empty from coordinate.md
  if [ -z "$workflow_description" ]; then
    echo "ERROR: ..." >&2
    return 1
  fi
}
```

**Result**: Function validates first parameter, finds it empty, fails immediately.

---

### 5. Solution Design

#### Option A: Remove Pre-Initialization (Library Fix)

**Change**: Remove lines 75-77 from `workflow-state-machine.sh`

**Pros**:
- Clean solution
- Follows best practice (don't pre-initialize globals in libraries)
- Prevents future similar issues

**Cons**:
- Requires library modification
- May affect other commands using the library
- Needs comprehensive testing across all commands

**Risk**: Medium (potential impact on `/orchestrate`, `/supervise`)

---

#### Option B: Save and Restore Pattern (Command Fix)

**Change**: Modify `coordinate.md` to save value before sourcing

**Implementation**:
```bash
# Read workflow description
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE" ...)

# SAVE before sourcing (libraries will overwrite!)
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"

# Source library (overwrites WORKFLOW_DESCRIPTION to "")
source "${LIB_DIR}/workflow-state-machine.sh"

# Use saved value
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"

# After sm_init, library's WORKFLOW_DESCRIPTION is properly set
# All subsequent uses reference library's version
```

**Pros**:
- Minimal change (only affects coordinate.md)
- No risk to other commands
- Preserves library architecture
- Clear intent (explicit save/restore)

**Cons**:
- Requires all commands to use this pattern
- Adds boilerplate

**Risk**: Low (isolated to coordinate.md)

---

#### Option C: State File Pattern (Current Pattern Fix)

**Change**: Read from state file instead of relying on variable

**Implementation**:
```bash
# Save to state BEFORE sourcing library
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"

# Source library
source "${LIB_DIR}/workflow-state-machine.sh"

# Load from state after sourcing
WORKFLOW_DESCRIPTION=$(grep "WORKFLOW_DESCRIPTION=" "$STATE_FILE" | cut -d= -f2-)

# Use loaded value
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"
```

**Pros**:
- Aligns with state persistence architecture
- Resilient to library sourcing issues

**Cons**:
- More complex
- Requires state file earlier in initialization
- Circular dependency (state file needs WORKFLOW_ID first)

**Risk**: Medium (requires refactoring initialization sequence)

---

### 6. Recommended Solution

**Choice**: **Option B - Save and Restore Pattern**

**Rationale**:
1. Lowest risk (isolated change)
2. Fastest to implement
3. Clear and explicit
4. No impact on other commands
5. Easy to verify

**Implementation Steps**:

1. Modify `.claude/commands/coordinate.md` (around line 52-78):
```bash
# Read workflow description from file
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
if [ -f "$COORDINATE_DESC_FILE" ]; then
  WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE" 2>/dev/null || echo "")
else
  echo "ERROR: Workflow description file not found: $COORDINATE_DESC_FILE"
  exit 1
fi

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description is empty"
  exit 1
fi

# CRITICAL: Save workflow description BEFORE sourcing libraries
# Libraries pre-initialize WORKFLOW_DESCRIPTION="" which overwrites parent value
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

# Source state machine and state persistence libraries
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

if [ -f "${LIB_DIR}/workflow-state-machine.sh" ]; then
  source "${LIB_DIR}/workflow-state-machine.sh"
else
  echo "ERROR: workflow-state-machine.sh not found"
  exit 1
fi

# ... (rest of sourcing) ...

# Initialize state machine with SAVED value (not overwritten variable)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"

# After sm_init, library's WORKFLOW_DESCRIPTION is properly set via sm_init
# All subsequent function calls can use $WORKFLOW_DESCRIPTION directly
```

2. No changes needed to other files

---

### 7. Validation Results

**Test Script**: `/tmp/coordinate_fix_test.sh`

**Input**: `"Research bash execution patterns and state management"`

**Output**:
```
After sourcing library:
  WORKFLOW_DESCRIPTION: ''
  SAVED_WORKFLOW_DESC: 'Research bash execution patterns and state management'

After sm_init:
  WORKFLOW_DESCRIPTION (library's): 'Research bash execution patterns and state management'
  WORKFLOW_SCOPE (library's): 'research-only'

Calling initialize_workflow_paths...
✓ SUCCESS!
  TOPIC_PATH: /home/benjamin/.config/.claude/specs/629_bash_execution_patterns_state_management
```

**Verification**:
- ✓ Workflow description preserved via SAVED_WORKFLOW_DESC
- ✓ sm_init successfully sets library's WORKFLOW_DESCRIPTION
- ✓ initialize_workflow_paths receives non-empty parameters
- ✓ Topic directory created at expected path
- ✓ No errors during initialization

---

### 8. Related Issues

#### Other Commands Using Same Pattern

**Commands potentially affected**:
- `/orchestrate` (uses workflow-state-machine.sh)
- `/supervise` (uses workflow-state-machine.sh)

**Recommendation**: Apply same fix pattern to all commands sourcing `workflow-state-machine.sh`

#### Library Design Pattern Issue

**Observation**: Current library architecture pre-initializes global variables, creating fragile dependencies on sourcing order.

**Future improvement**: Consider one of:
1. Remove all pre-initializations from libraries
2. Use explicit initialization functions (`init_workflow_state_machine()`) instead of sourcing
3. Use namespace prefixes for library variables (e.g., `WSM_WORKFLOW_DESCRIPTION`)

---

### 9. Implementation Checklist

- [ ] Apply fix to `.claude/commands/coordinate.md`
- [ ] Test with various workflow descriptions
- [ ] Verify all workflow scopes (research-only, research-and-plan, full-implementation, debug-only)
- [ ] Check for similar issues in `/orchestrate` and `/supervise`
- [ ] Update command guide documentation
- [ ] Add test case to prevent regression

---

### 10. Additional Findings

#### History Expansion Issue (Related)

**Observation**: `set +H` is used to disable history expansion in bash blocks

**Reason**: Bash tool preprocessing has issues with `!` operator in certain contexts

**Evidence**: Multiple instances of workarounds like:
```bash
# Avoid ! operator due to Bash tool preprocessing issues
if verify_file_created "$PATH" ...; then
  : # Success
else
  exit 1
fi
```

**Recommendation**: Document this pattern and create a style guide for bash blocks in commands

---

## Appendix: Bash Variable Scoping Reference

### Global vs Local Variables

**Global** (accessible everywhere after declaration):
```bash
MY_VAR="value"  # Global in current script and sourced libraries
```

**Local** (function scope only):
```bash
function_name() {
  local my_var="value"  # Only accessible within function
}
```

### Sourcing Behavior

**Parent script**:
```bash
VAR_A="parent value"
source library.sh
echo "$VAR_A"  # Value depends on library.sh contents
```

**Library (library.sh)**:
```bash
# Case 1: Library doesn't touch VAR_A
# Result: VAR_A remains "parent value"

# Case 2: Library declares VAR_A=""
VAR_A=""
# Result: VAR_A becomes "" (OVERWRITES parent)

# Case 3: Library modifies VAR_A
VAR_A="${VAR_A} + library"
# Result: VAR_A becomes "parent value + library"
```

### Export Behavior

**Export** makes variables available to child processes (not sourced libraries):
```bash
export VAR="value"  # Available to: subshells, executed scripts
source library.sh   # Library sees VAR directly (shares scope)
```

**Key distinction**: Sourced libraries share variable scope with parent, child processes get copies.

---

## References

- Bash Manual: [Shell Variables](https://www.gnu.org/software/bash/manual/html_node/Shell-Variables.html)
- Bash Manual: [Source Command](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-source)
- Related issue: [620_fix_coordinate_bash_history_expansion_errors](../plans/001_implementation.md)
