# Research Report: Phase 0 Skip Fix for /lean-implement

**Date**: 2025-12-09
**Research Complexity**: 2
**Workflow Type**: research-and-revise

## Executive Summary

Both `/lean-implement` and `/implement` commands have the **same root cause**: they hardcode `STARTING_PHASE=1` as the default instead of detecting the lowest incomplete phase. Neither command correctly handles phase 0 when invoked without explicit phase arguments. The fix requires adding phase 0 detection logic to both commands, with the implementer-coordinator responsible for finding the actual starting phase during wave orchestration.

## Problem Description

When either command is invoked without a starting phase argument:
- **Expected behavior**: Start at phase 0 if it exists and is incomplete
- **Actual behavior**: Always starts at phase 1, skipping phase 0 if present
- **Impact**: Phase 0 (typically "Standards Revision") is never executed in automatic mode
- **Scope**: Affects both `/lean-implement` AND `/implement` commands

## Root Cause Analysis

### 1. Identical Hardcoded Default in Both Commands

#### /lean-implement (Lines 151-153)
```bash
read -ra ARGS_ARRAY <<< "$LEAN_IMPLEMENT_ARGS"
PLAN_FILE="${ARGS_ARRAY[0]:-}"
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"  # ❌ PROBLEM: Hardcoded to 1
```

#### /implement (Lines 157-159)
```bash
read -ra ARGS_ARRAY <<< "$IMPLEMENT_ARGS"
PLAN_FILE="${ARGS_ARRAY[0]:-}"
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"  # ❌ SAME PROBLEM: Hardcoded to 1
```

**Root Cause**: Both commands use `:-1` as the default fallback for `STARTING_PHASE`, which assumes phase numbering always begins at 1. This is a **false assumption** - plans can have phase 0 for standards revision tasks.

### 2. Missing Phase Detection Logic

Neither command implements logic to:
1. Scan the plan file for the lowest phase number
2. Detect if phase 0 exists
3. Check phase completion status before starting
4. Override the default with the actual lowest incomplete phase

**Comparison to Other Commands**: The `/create-plan` and `/lean-plan` commands have phase 0 detection (lines 2613-2616 in create-plan.md):

```bash
# === DETECT PHASE 0 (STANDARDS DIVERGENCE) ===
PHASE_0_DETECTED=false
if grep -q "^### Phase 0: Standards Revision" "$PLAN_PATH" 2>/dev/null; then
  PHASE_0_DETECTED=true
```

However, this detection is only used for **informational messages** - it doesn't automatically set STARTING_PHASE for implementation commands.

### 3. Coordinator Trusts Orchestrator's STARTING_PHASE

The `implementer-coordinator` agent (lines 821-829) documents:

```
1. **First Iteration** (iteration=1, continuation_context=null):
   - Start fresh from Starting Phase
   - Execute phases until context threshold or completion
   - Return work_remaining with incomplete phase list

2. **Continuation Iterations** (iteration>1):
   - Read continuation_context summary for completed phase context
   - Resume from first incomplete phase
   - Execute phases until context threshold or completion
```

**Key Finding**:
- **First iteration**: Coordinator uses the `STARTING_PHASE` value provided by the orchestrator without question
- **Continuation iterations**: Coordinator intelligently resumes from first incomplete phase
- **Gap**: The first iteration assumes the orchestrator provided the correct starting phase

### 4. Why This Bug Persists

Phase 0 is rare - it only appears when:
- plan-architect detects standards divergence during `/create-plan`
- Lean-specific standards updates are needed during `/lean-plan`
- Manual phase 0 addition for prerequisite work

Most plans start at phase 1, so this bug goes unnoticed in normal workflows.

## Code Sections Requiring Changes

### A. /lean-implement Command (Block 1a: Lines 151-167)

**Current Code**:
```bash
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"  # Line 153
```

**Fix Location**: After line 213 (after PLAN_FILE is validated and converted to absolute path), add phase detection logic.

**Proposed Fix**:
```bash
# === DETECT LOWEST INCOMPLETE PHASE ===
# If no starting phase argument provided, find the lowest incomplete phase
if [ "${ARGS_ARRAY[1]:-}" = "" ]; then
  # Extract all phase numbers from plan file
  PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | sort -n)

  # Find first phase without [COMPLETE] marker
  LOWEST_INCOMPLETE_PHASE=""
  for phase_num in $PHASE_NUMBERS; do
    if ! grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
      LOWEST_INCOMPLETE_PHASE="$phase_num"
      break
    fi
  done

  # Use lowest incomplete phase, or default to 1 if all complete
  if [ -n "$LOWEST_INCOMPLETE_PHASE" ]; then
    STARTING_PHASE="$LOWEST_INCOMPLETE_PHASE"
    echo "Auto-detected starting phase: $STARTING_PHASE (lowest incomplete)"
  else
    # All phases complete - default to 1 (likely resumption scenario)
    STARTING_PHASE="1"
  fi
else
  # Explicit phase argument provided
  STARTING_PHASE="${ARGS_ARRAY[1]}"
fi
```

### B. /implement Command (Block 1a: Lines 157-177)

**Current Code**:
```bash
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"  # Line 159
```

**Fix Location**: After line 308 (after PLAN_FILE validation and conversion to absolute path), add **identical** phase detection logic as /lean-implement.

**Proposed Fix**: Use the same bash code block as shown in section A above.

### C. implementer-coordinator Agent (Documentation Update)

**Location**: Lines 821-831 (Iteration Behavior section)

**Current Documentation**:
```
1. **First Iteration** (iteration=1, continuation_context=null):
   - Start fresh from Starting Phase
```

**Updated Documentation**:
```
1. **First Iteration** (iteration=1, continuation_context=null):
   - Start fresh from Starting Phase (provided by orchestrator, auto-detected as lowest incomplete)
   - Note: Orchestrator detects lowest incomplete phase if no explicit phase argument
```

## Implementation Strategy

### Phase 1: Fix /lean-implement Command
1. Add phase detection logic after line 213 in Block 1a
2. Update echo output to show auto-detection status
3. Test with plan containing phase 0

### Phase 2: Fix /implement Command
1. Add identical phase detection logic after line 308 in Block 1a
2. Update echo output to show auto-detection status
3. Test with plan containing phase 0

### Phase 3: Update Documentation
1. Update implementer-coordinator.md to clarify auto-detection behavior
2. Update lean-implement command guide (if exists)
3. Update implement command guide (if exists)

## Testing Strategy

### Test Case 1: Plan with Phase 0 (Incomplete)
```bash
# Plan structure:
### Phase 0: Standards Revision [NOT STARTED]
### Phase 1: Setup [NOT STARTED]

# Expected: STARTING_PHASE=0
/lean-implement plan.md
```

### Test Case 2: Plan with Phase 0 (Complete)
```bash
# Plan structure:
### Phase 0: Standards Revision [COMPLETE]
### Phase 1: Setup [NOT STARTED]

# Expected: STARTING_PHASE=1
/lean-implement plan.md
```

### Test Case 3: Plan without Phase 0
```bash
# Plan structure:
### Phase 1: Setup [NOT STARTED]
### Phase 2: Implementation [NOT STARTED]

# Expected: STARTING_PHASE=1 (no regression)
/lean-implement plan.md
```

### Test Case 4: Explicit Phase Argument
```bash
# Plan structure:
### Phase 0: Standards Revision [NOT STARTED]
### Phase 1: Setup [NOT STARTED]

# Expected: STARTING_PHASE=1 (user override respected)
/lean-implement plan.md 1
```

### Test Case 5: All Phases Complete
```bash
# Plan structure:
### Phase 0: Standards Revision [COMPLETE]
### Phase 1: Setup [COMPLETE]

# Expected: STARTING_PHASE=0 (attempt resume from start)
/lean-implement plan.md
```

## Validation Criteria

- [ ] Phase 0 detection works when phase 0 exists and is incomplete
- [ ] Phase 1 detection works when phase 0 is complete
- [ ] Phase 1 detection works when phase 0 doesn't exist (no regression)
- [ ] Explicit phase arguments override auto-detection
- [ ] Error handling for malformed plan files
- [ ] Performance impact < 100ms for typical plan files

## References

- `/lean-implement` command: `/home/benjamin/.config/.claude/commands/lean-implement.md` (lines 151-213)
- `/implement` command: `/home/benjamin/.config/.claude/commands/implement.md` (lines 157-308)
- `implementer-coordinator` agent: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (lines 821-831)
- Phase 0 detection example: `/home/benjamin/.config/.claude/commands/create-plan.md` (lines 2613-2616)

## Estimated Impact

- **Time to Fix**: 1-2 hours (add detection logic to both commands + testing)
- **Risk Level**: Low (defensive logic with fallback, explicit phase args unchanged)
- **Breaking Changes**: None (only changes default behavior when no phase argument provided)
- **User Experience Impact**: High (phase 0 will now execute automatically)
