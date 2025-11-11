# Fix Report: Missing State Transition Persistence

## Metadata
- **Date**: 2025-11-10
- **Issue**: State transition not persisted to workflow state
- **Impact**: Research handler fails with "Expected state 'research' but current state is 'initialize'"
- **Fix**: 1 line addition to coordinate.md
- **Status**: ✅ IMPLEMENTED

---

## Problem

### Error Message
```
ERROR: Expected state 'research' but current state is 'initialize'
```

### Root Cause

**Initialization block** (coordinate.md:231-232):
```bash
# Transition to research state
sm_transition "$STATE_RESEARCH"  # Sets CURRENT_STATE in memory only
# ❌ MISSING: append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

**Result**:
1. Line 125 saves `CURRENT_STATE="initialize"` to state file
2. Line 231 changes `CURRENT_STATE="research"` in memory
3. State is NOT saved to file
4. Research handler loads state → gets old value ("initialize")
5. Error: State mismatch

---

## Solution

### Fix Applied

**File**: `.claude/commands/coordinate.md`
**Location**: After line 231

**Before**:
```bash
sm_transition "$STATE_RESEARCH"

echo ""
echo "State Machine Initialized:"
```

**After**:
```bash
sm_transition "$STATE_RESEARCH"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

echo ""
echo "State Machine Initialized:"
```

**Lines Changed**: +1 line

---

## Pattern Consistency

This fix matches the existing pattern used throughout coordinate.md:

**Line 482** (research completion):
```bash
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"
```

**Line 491** (research-and-plan):
```bash
sm_transition "$STATE_PLAN"
append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
```

**Line 635** (plan completion):
```bash
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"
```

**Pattern**: Every `sm_transition` call is followed by `append_workflow_state "CURRENT_STATE"`

---

## Why This Was Missed

This is the **only** state transition in the initialization block. All other transitions happen in subsequent blocks (research, plan, implement, etc.) and were already correctly saving state.

The initialization block was assumed to be complete after saving:
- WORKFLOW_SCOPE
- TERMINAL_STATE
- CURRENT_STATE (line 125 - but this was the initial state, not after transition)

The transition on line 231 happened AFTER the initial state save, creating the bug.

---

## Verification

**State File Before Fix**:
```bash
export CURRENT_STATE="initialize"  # Saved on line 125
# sm_transition happens but isn't saved
```

**State File After Fix**:
```bash
export CURRENT_STATE="initialize"  # Saved on line 125
export CURRENT_STATE="research"    # Saved on line 232 (overwrites previous)
```

**Research Handler**:
```bash
load_workflow_state "$WORKFLOW_ID"
# Now gets CURRENT_STATE="research" ✅
```

---

## Related Fixes

This is part of the coordinate state persistence fix series:

1. **Spec 620**: Variable scoping (SAVED_WORKFLOW_DESC)
2. **Spec 620**: Process ID pattern (fixed filenames)
3. **Spec 620**: Trap handler (premature cleanup)
4. **Spec 630**: Array metadata (REPORT_PATHS_COUNT)
5. **Spec 630**: State transition (CURRENT_STATE) ← This fix

**Common Theme**: Subprocess isolation requires explicit state persistence for ALL variables used across bash blocks.

---

## Testing

**Expected Behavior**:
```bash
/coordinate "Research any topic"

# Initialization block:
# - Sets CURRENT_STATE="research"
# - Saves to state file ✅

# Research handler:
# - Loads state
# - Gets CURRENT_STATE="research" ✅
# - Validation passes ✅
```

**Previous Behavior**:
```bash
# Initialization: CURRENT_STATE="research" in memory only
# Research handler: Loads CURRENT_STATE="initialize" from state
# Error: State mismatch ❌
```

---

## Checklist

- [x] Root cause identified
- [x] Fix implemented (1 line)
- [x] Pattern verified against existing code
- [x] Documentation created

---

**Status**: ✅ COMPLETE
**Next**: Monitor /coordinate execution for additional issues
