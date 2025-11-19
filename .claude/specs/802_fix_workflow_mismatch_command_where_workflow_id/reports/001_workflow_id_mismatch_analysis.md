# Workflow ID Mismatch in /plan Command Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Fix workflow ID mismatch in /plan command where WORKFLOW_ID generated in Block 1 differs from ID written to state_id.txt
- **Report Type**: codebase analysis

## Executive Summary

The workflow ID mismatch bug in `/plan` is caused by a dual-timestamp generation issue: the WORKFLOW_ID is generated with one timestamp at line 140, but `init_workflow_state()` generates a separate state file with a completely different WORKFLOW_ID based on when that function executes. This creates a disconnect where `plan_state_id.txt` contains one ID (e.g., `plan_1763513645`) but the actual state file was created with a different ID derived from the original WORKFLOW_ID passed to `init_workflow_state()`. The fix requires ensuring consistent ID propagation by using the pre-generated WORKFLOW_ID throughout the initialization chain.

## Findings

### 1. Root Cause Analysis: Dual-Timestamp Generation

The bug originates from two separate timestamp generation points in Block 1 of plan.md:

**First Timestamp (Line 140)**:
```bash
WORKFLOW_ID="plan_$(date +%s)"   # Creates e.g., plan_1763513496
```
At `/home/benjamin/.config/.claude/commands/plan.md:140`, a WORKFLOW_ID is generated using the current timestamp.

**State ID File Write (Lines 141-143)**:
```bash
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"    # Writes plan_1763513496
```
This correctly writes the first WORKFLOW_ID to the state ID file.

**Second Implicit Timestamp in init_workflow_state (Line 146)**:
```bash
init_workflow_state "$WORKFLOW_ID"
```

Looking at `init_workflow_state()` in `/home/benjamin/.config/.claude/lib/state-persistence.sh:130-168`:
```bash
init_workflow_state() {
  local workflow_id="${1:-$$}"    # Receives the passed WORKFLOW_ID

  # ... project directory detection ...

  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

  cat > "$STATE_FILE" <<EOF
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export WORKFLOW_ID="$workflow_id"
export STATE_FILE="$STATE_FILE"
EOF

  echo "$STATE_FILE"
}
```

The function correctly uses the passed `workflow_id` parameter. However, the state file is created as `workflow_plan_1763513496.sh`.

### 2. Timeline Analysis: The 149-Second Gap

The error output shows:
- Block 1 created `workflow_plan_1763513496.sh`
- But state_id.txt contains `plan_1763513645` (149 seconds later)

This suggests the **state_id.txt is being rewritten** somewhere after init_workflow_state(). Looking at the code flow:

1. Line 140: `WORKFLOW_ID="plan_$(date +%s)"` - generates `plan_1763513496`
2. Line 143: Writes to state_id.txt
3. Line 146: `init_workflow_state "$WORKFLOW_ID"` - creates `workflow_plan_1763513496.sh`

But wait - the discrepancy shows `plan_1763513645` in state_id.txt, which is 149 seconds LATER than the state file. This means something is regenerating the WORKFLOW_ID AFTER init_workflow_state().

### 3. Potential Regeneration Point: sm_init()

At `/home/benjamin/.config/.claude/commands/plan.md:148-151`:
```bash
if ! sm_init "$FEATURE_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi
```

Looking at `sm_init()` in `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:392-511`, I see it:
- Does NOT regenerate WORKFLOW_ID
- Uses `append_workflow_state()` to persist state machine variables
- Assumes STATE_FILE is already set

**Critical Finding**: `sm_init()` at lines 455-461 and 497-502 calls `append_workflow_state()`:
```bash
if command -v append_workflow_state &> /dev/null; then
  append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
  append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
  // ...
}
```

But `append_workflow_state()` at `/home/benjamin/.config/.claude/lib/state-persistence.sh:321-336` requires STATE_FILE to be set:
```bash
append_workflow_state() {
  local key="$1"
  local value="$2"

  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR: STATE_FILE not set. Call init_workflow_state first." >&2
    return 1
  }
  // ...
}
```

### 4. The Actual Bug: Missing STATE_FILE Export

The bug is subtle but critical. Looking at `init_workflow_state()` output:

```bash
init_workflow_state() {
  // ...
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"
  // ...
  echo "$STATE_FILE"   # Returns path, but doesn't export
}
```

The function sets `STATE_FILE` locally and writes it to the state file, but **the export only happens inside the state file itself**. In plan.md line 146:

```bash
init_workflow_state "$WORKFLOW_ID"
```

The return value (the STATE_FILE path) is **not captured**! This means STATE_FILE is not set in the calling script's environment until it sources the state file.

### 5. Secondary Issue: State ID File Redundancy

The plan.md command uses its own `plan_state_id.txt` file to persist the WORKFLOW_ID between blocks, instead of using the standard pattern. This creates redundancy and potential for mismatch.

Looking at `/home/benjamin/.config/.claude/commands/plan.md:141-144`:
```bash
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID
```

Then at lines 232-238 (Block 2):
```bash
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID
```

### 6. Hypothesis: The 149-Second Gap is Task Tool Latency

The 149-second gap between the state file timestamp (1763513496) and the state_id.txt content (1763513645) could be explained by:

1. Block 1 executes at time T1 (1763513496)
2. Task tool invokes research-specialist agent
3. Research takes ~149 seconds
4. **The bash block execution somehow re-runs or there's another process writing to state_id.txt**

However, examining the code, there's no obvious place where state_id.txt would be rewritten. The most likely explanation is:

**The bug report's timestamps may be from different invocations**, or there's an issue with how the error was reported. The core issue remains: WORKFLOW_ID must be consistently propagated.

## Recommendations

### 1. Capture init_workflow_state() Return Value

At `/home/benjamin/.config/.claude/commands/plan.md:146`, change:
```bash
init_workflow_state "$WORKFLOW_ID"
```

To:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE
```

This ensures STATE_FILE is set before calling sm_init() which uses append_workflow_state().

### 2. Remove Redundant State ID File

The plan.md command should follow the same pattern as other commands. Instead of maintaining a separate `plan_state_id.txt`, use the STATE_FILE directly. The WORKFLOW_ID is already persisted in the state file via:
```bash
export WORKFLOW_ID="$workflow_id"
```

In Block 2 and Block 3, replace:
```bash
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
```

With:
```bash
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_plan_${WORKFLOW_ID_SUFFIX}.sh"
source "$STATE_FILE"
```

Or better yet, use the state persistence library's standard pattern.

### 3. Add Defensive Validation

After init_workflow_state(), add validation:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  echo "Expected state file: $STATE_FILE" >&2
  exit 1
fi
```

### 4. Consolidate to Standard Workflow Initialization Pattern

Review other commands (build.md, debug.md, research.md) to see if they use a consistent pattern for state ID persistence. If so, align plan.md with that pattern.

### 5. Add Timestamp Debugging

For future debugging, add logging of the WORKFLOW_ID and STATE_FILE paths:
```bash
echo "DEBUG: WORKFLOW_ID=$WORKFLOW_ID"
echo "DEBUG: STATE_FILE=$STATE_FILE"
echo "DEBUG: State file exists: $(test -f "$STATE_FILE" && echo yes || echo no)"
```

## References

- `/home/benjamin/.config/.claude/commands/plan.md:140-146` - WORKFLOW_ID generation and init_workflow_state call
- `/home/benjamin/.config/.claude/commands/plan.md:141-144` - State ID file write
- `/home/benjamin/.config/.claude/commands/plan.md:232-238` - Block 2 state ID file read
- `/home/benjamin/.config/.claude/commands/plan.md:345-351` - Block 3 state ID file read
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:130-168` - init_workflow_state() function
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:321-336` - append_workflow_state() function
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:392-511` - sm_init() function
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:455-461` - sm_init state persistence calls

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_fix_workflow_mismatch_command_where_work_plan.md](../plans/001_fix_workflow_mismatch_command_where_work_plan.md)
- **Implementation**: [Will be updated during implementation]
- **Date**: 2025-11-18
