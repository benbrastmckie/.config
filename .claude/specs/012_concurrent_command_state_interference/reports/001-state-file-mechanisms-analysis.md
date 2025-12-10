# State File Mechanisms and Locking Analysis

**Research Topic**: State file mechanisms and concurrent access patterns in state-persistence.sh and workflow state management

**Date**: 2025-12-10

**Status**: Research complete

---

## Executive Summary

This research analyzes state file mechanisms in `.claude/` commands and identifies the root cause of concurrent command interference when two `/create-plan` instances run simultaneously. The primary issue is the use of a **shared, non-unique state ID file** (`plan_state_id.txt`) that gets overwritten when multiple instances execute concurrently in the same repository, causing "Failed to restore WORKFLOW_ID" errors.

**Key Findings**:

1. **Critical Shared Resource**: `/create-plan` and `/lean-plan` commands use a single shared file `.claude/tmp/plan_state_id.txt` to store the current WORKFLOW_ID
2. **No Concurrency Protection**: The state ID file has no file locking, atomic operations, or uniqueness mechanisms
3. **Race Condition Pattern**: Second command instance overwrites the state ID file, causing the first instance to fail when it attempts to restore WORKFLOW_ID from the file
4. **Widespread Pattern**: This same pattern appears in 10+ locations across create-plan.md and lean-plan.md
5. **No Locking in Core Libraries**: Neither state-persistence.sh nor workflow-state-machine.sh implement file locking or concurrency controls

---

## Research Objectives

1. ✅ Analyze state-persistence.sh state file management and locking mechanisms
2. ✅ Examine workflow-state-machine.sh state transition patterns
3. ✅ Identify shared state files causing concurrent command interference
4. ✅ Document evidence of interference from create-plan outputs
5. ✅ Identify gaps in current locking/isolation mechanisms

---

## Findings

### 1. Shared State ID File Pattern (Root Cause)

#### Evidence from Source Code

The `/create-plan` command uses a **single shared file** to store the WORKFLOW_ID that is reused across all bash blocks:

**Location**: `.claude/commands/create-plan.md`, Block 1a (lines 173-178)

```bash
WORKFLOW_ID="plan_$(date +%s)"
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches state file location)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID
```

**Problem**: This file path is **identical for all concurrent /create-plan invocations** in the same repository. When a second instance writes its WORKFLOW_ID to this file, it overwrites the first instance's ID.

#### Restoration Pattern (Failure Point)

**Location**: `.claude/commands/create-plan.md`, Block 1b (lines 315-321)

```bash
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1a" >&2
  exit 1
fi
```

This pattern repeats in **10+ locations** across the command:
- Block 1b (line 316)
- Block 1b-exec (line 492)
- Block 1c (line 600)
- Block 1d (line 684)
- Block 1d-exec-optional (line 914)
- Block 1d-topics-auto (line 1068)
- Block 1d-topics-auto-validate (line 1243)
- And more...

Each of these blocks attempts to restore WORKFLOW_ID from the **same shared file**, making them vulnerable to concurrent overwrites.

---

### 2. Evidence of Interference from Create-Plan Outputs

#### Instance 1: `.claude/output/create-plan-output.md` (Lines 73-89)

```
● Bash(set +H  # CRITICAL: Disable history       timeout:
      expansion…)                                30s
  ⎿  Error: Exit code 1
     ERROR: Failed to restore WORKFLOW_ID

● Bash(# Check state file
      cat
      /home/benjamin/.config/.claude/tmp/plan_state_id.txt
      2>/dev/null || echo "STATE_ID_FILE missing"…)
  ⎿ plan_1765352804
    -rw-r--r-- 1 benjamin users 16 Dec  9 23:46 /home/b
    enjamin/.config/.claude/tmp/plan_state_id.txt


● The state ID file was overwritten by another process.
  Let me recover and continue with the correct workflow
  ID:
```

**Analysis**:
- Instance 1 was using `WORKFLOW_ID=plan_1765352600` (created at timestamp 1765352600)
- The state ID file was overwritten with `plan_1765352804` (timestamp 1765352804, **204 seconds later**)
- The file timestamp shows Dec 9 23:46, confirming concurrent modification
- Instance 1 detected the corruption and attempted recovery but failed to continue properly

#### Instance 2: `.claude/output/create-plan-output-2.md` (Lines 164-209)

```
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  === Topic Decomposition ===

     Using heuristic decomposition (fallback mode)
     … +10 lines (ctrl+o to expand)

● The state file got corrupted with a different FEATURE_DESCRIPTION.
  Let me check and fix the state:
```

Later in the output (lines 207-210):

```
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 1
     ERROR: Failed to restore WORKFLOW_ID
```

**Analysis**:
- Instance 2 created `WORKFLOW_ID=plan_1765352804` and wrote it to the shared state ID file
- Instance 2 detected state corruption (different FEATURE_DESCRIPTION)
- Instance 2 also failed due to state ID file deletion/corruption during concurrent execution
- Both instances experienced state interference from each other

#### Timeline of Interference

```
Time (Unix)     Event
═══════════════════════════════════════════════════════════════════
1765352600      Instance 1 creates plan_1765352600
1765352600      Instance 1 writes to plan_state_id.txt
1765352600      Instance 1 begins execution...
1765352804      Instance 2 creates plan_1765352804 (+204 seconds)
1765352804      Instance 2 OVERWRITES plan_state_id.txt
1765352804      Instance 1 attempts to read plan_state_id.txt
1765352804      Instance 1 gets plan_1765352804 instead of plan_1765352600
1765352804      Instance 1 ERROR: Failed to restore WORKFLOW_ID
```

---

### 3. State-Persistence.sh Analysis (Core Library)

#### File Location and Purpose

**File**: `.claude/lib/core/state-persistence.sh`
**Version**: 1.6.0
**Purpose**: Implements GitHub Actions-style state persistence for workflows

#### State File Naming Convention

**Location**: Lines 13-26

```bash
# IMPORTANT: State File Path Pattern
# ==================================
# State files are ALWAYS created at:
#   ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh
#
# Commands MUST construct STATE_FILE paths using ${CLAUDE_PROJECT_DIR}, NOT ${HOME}.
```

**Analysis**:
- Individual workflow state files ARE unique per WORKFLOW_ID: `workflow_plan_1765352600.sh` vs `workflow_plan_1765352804.sh`
- The state-persistence.sh library correctly isolates per-workflow state
- **The problem is NOT in state-persistence.sh** - the library design is sound
- The problem is in the **command-level state ID coordination file** (plan_state_id.txt)

#### No Locking Mechanisms

The library implements several state management functions:

1. `init_workflow_state()` (line 165) - Creates unique per-workflow state file
2. `load_workflow_state()` (line 313) - Loads state from per-workflow file
3. `append_workflow_state()` (line 516) - Appends to per-workflow file
4. `validate_state_file()` (line 238) - Validates file integrity

**Critical Observation**: None of these functions implement:
- File locking (flock, lockfile)
- Atomic operations beyond temp file + mv
- Concurrency detection
- PID-based uniqueness

The library assumes:
1. Single writer per workflow (correct for per-workflow state files)
2. WORKFLOW_ID is stable and unique (violated by shared state ID file pattern)
3. Commands handle state ID coordination (this assumption is broken)

#### State File Validation (Lines 238-266)

```bash
validate_state_file() {
  local state_file="$1"

  # File exists and is readable
  if [[ ! -f "$state_file" ]]; then
    echo "State file does not exist: $state_file" >&2
    return 1
  fi

  # File has minimum content (not empty or truncated)
  local file_size
  file_size=$(wc -c < "$state_file" 2>/dev/null || echo 0)
  if [[ "$file_size" -lt 50 ]]; then
    echo "State file too small (possible corruption): $file_size bytes" >&2
    return 1
  fi

  return 0
}
```

**Analysis**: Validation checks file existence and size but cannot detect concurrent overwrites or stale reads from the shared state ID file.

---

### 4. Workflow-State-Machine.sh Analysis

#### File Location and Purpose

**File**: `.claude/lib/workflow/workflow-state-machine.sh`
**Version**: 2.0.0
**Purpose**: Formal state machine abstraction for orchestration commands

#### State Machine Variables (Lines 74-92)

```bash
# Current state of the state machine
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"

# Array of completed states (state history)
declare -ga COMPLETED_STATES=()

# Terminal state for this workflow (determined by scope)
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"

# Workflow configuration
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"
```

**Analysis**:
- State machine operates on variables passed from commands
- Assumes WORKFLOW_ID is stable (relies on external state ID management)
- No concurrency protection in state transitions

#### State Transition Function (Lines 676-911)

The `sm_transition()` function includes extensive validation but no concurrency controls:

**Line 689-759**: STATE_FILE validation with auto-initialization
```bash
if [ -z "${STATE_FILE:-}" ]; then
    # Get caller information for debugging
    # ...
    # Log STATE_FILE validation error with caller context
    # ...
    # Attempt auto-initialization
    if declare -f load_workflow_state &>/dev/null; then
      # Try to load state using WORKFLOW_ID if available
```

**Analysis**: The state machine can auto-recover if STATE_FILE is unset, but this does not protect against loading the **wrong** WORKFLOW_ID from a corrupted shared state ID file.

#### No Locking or Concurrency Protection

The state machine library does not implement:
1. State transition locks
2. Concurrent transition detection
3. State file versioning
4. Optimistic locking (compare-and-swap)

This is appropriate because the library correctly assumes **per-workflow isolation**. The issue arises at the command level where WORKFLOW_ID coordination is mishandled.

---

### 5. Concurrency Gap Analysis

#### Design Assumptions vs Reality

| Component | Assumed Concurrency Model | Actual Behavior |
|-----------|---------------------------|-----------------|
| state-persistence.sh | Single writer per WORKFLOW_ID | ✅ Correct - per-workflow files ARE unique |
| workflow-state-machine.sh | WORKFLOW_ID is stable | ✅ Correct - state machine doesn't manage IDs |
| Commands (/create-plan) | WORKFLOW_ID coordination is isolated | ❌ **BROKEN** - shared state ID file |

#### Root Cause Summary

The concurrency failure occurs at the **command orchestration layer**, not in the libraries:

1. **Library Design**: Sound - uses unique per-workflow state files
2. **Command Pattern**: Broken - uses shared state ID file for WORKFLOW_ID coordination
3. **Missing Mechanism**: No PID-based or lock-based uniqueness for state ID file

#### Why This Pattern Exists

Looking at the comments in create-plan.md (lines 174-175):

```bash
WORKFLOW_ID="plan_$(date +%s)"
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches state file location)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
```

**Analysis**: The pattern was designed to solve a different problem:
- **Intended Problem**: Consistent path between HOME and CLAUDE_PROJECT_DIR
- **Side Effect**: Created a shared resource without concurrency protection
- **Missing Consideration**: Multiple concurrent command invocations were not tested

---

### 6. Affected Commands

The following commands use the shared state ID file pattern:

1. `/create-plan` - Uses `plan_state_id.txt` (10+ references)
2. `/lean-plan` - Uses `plan_state_id.txt` (similar pattern)

**Verification Command**:
```bash
$ grep -r "plan_state_id.txt" .claude/commands/
.claude/commands/lean-plan.md
.claude/commands/create-plan.md
```

**Impact**: Any concurrent invocation of these commands in the same repository will experience state interference.

---

### 7. Technical Solutions (Analysis)

#### Option 1: PID-Based Unique State ID Files

**Pattern**:
```bash
WORKFLOW_ID="plan_$(date +%s)_$$"  # Add PID for uniqueness
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id_$$.txt"
```

**Pros**:
- Simple implementation
- No locking required
- Each command instance has its own state ID file

**Cons**:
- State ID files accumulate (need cleanup)
- PID reuse edge case (very rare)

#### Option 2: File Locking (flock)

**Pattern**:
```bash
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
(
  flock -x 200
  echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
) 200>"${STATE_ID_FILE}.lock"
```

**Pros**:
- Protects shared resource
- Standard Unix mechanism
- Prevents concurrent writes

**Cons**:
- More complex
- Lock contention delays
- Requires flock utility

#### Option 3: Eliminate State ID File (Use Environment Only)

**Pattern**:
```bash
# Block 1a: Create and export
WORKFLOW_ID="plan_$(date +%s)"
export WORKFLOW_ID

# Subsequent blocks: Read from state file (already has WORKFLOW_ID)
load_workflow_state "$WORKFLOW_ID"  # Pass explicitly
```

**Pros**:
- Simplest solution
- No shared file to corrupt
- Aligns with state-persistence.sh design

**Cons**:
- Requires command refactoring
- Must ensure WORKFLOW_ID propagates correctly

#### Recommended Solution

**Hybrid Approach**: Option 3 (Eliminate State ID File) + Option 1 (PID for Safety)

```bash
# Block 1a
WORKFLOW_ID="plan_$(date +%s)_$$"  # Include PID for absolute uniqueness
export WORKFLOW_ID
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Subsequent blocks (NO STATE_ID_FILE)
load_workflow_state  # Uses WORKFLOW_ID from state file
```

**Rationale**:
1. PID inclusion ensures WORKFLOW_ID uniqueness even with rapid invocations
2. Eliminating state ID file removes the shared resource entirely
3. State-persistence.sh already embeds WORKFLOW_ID in state file (line 196)
4. Minimal refactoring - remove STATE_ID_FILE reads, keep everything else

---

## Conclusions

### Root Cause

The "Failed to restore WORKFLOW_ID" error when running concurrent `/create-plan` commands is caused by:

1. **Shared Resource**: Both commands use a single file `.claude/tmp/plan_state_id.txt`
2. **No Concurrency Protection**: File is written/read without locks or uniqueness mechanisms
3. **Race Condition**: Second instance overwrites the file before first instance reads it
4. **Widespread Pattern**: The STATE_ID_FILE restoration pattern appears in 10+ blocks in each command

### Why Libraries Are Not at Fault

- `state-persistence.sh` correctly uses unique per-workflow state files (`workflow_${WORKFLOW_ID}.sh`)
- `workflow-state-machine.sh` correctly operates on provided WORKFLOW_ID without managing coordination
- The issue is at the **command orchestration layer** where WORKFLOW_ID coordination was implemented with a shared file

### Recommended Fix Strategy

1. **Immediate Fix**: Add PID to WORKFLOW_ID generation (`plan_$(date +%s)_$$`)
2. **Architectural Fix**: Eliminate STATE_ID_FILE entirely, rely on state-persistence.sh to store WORKFLOW_ID in per-workflow state file
3. **Testing**: Add concurrent execution test to CI to prevent regression

### Broader Implications

This pattern may exist in other commands that need state coordination across bash blocks. A comprehensive audit of all commands using similar patterns is recommended.

---

## Artifacts Referenced

1. `.claude/lib/core/state-persistence.sh` - State persistence library (v1.6.0)
2. `.claude/lib/workflow/workflow-state-machine.sh` - State machine library (v2.0.0)
3. `.claude/commands/create-plan.md` - Command with interference pattern
4. `.claude/output/create-plan-output.md` - Evidence of Instance 1 failure
5. `.claude/output/create-plan-output-2.md` - Evidence of Instance 2 failure
6. `.claude/tmp/plan_state_id.txt` - The shared state file causing interference

---

## Next Steps

1. **Validate Solution**: Prototype the recommended hybrid approach (PID + eliminate STATE_ID_FILE)
2. **Create Fix Plan**: Use this research to generate an implementation plan for fixing the concurrency issue
3. **Audit Other Commands**: Search for similar patterns in other commands (research.md, implement.md, etc.)
4. **Add Concurrency Tests**: Create test cases that run commands concurrently to prevent regression
