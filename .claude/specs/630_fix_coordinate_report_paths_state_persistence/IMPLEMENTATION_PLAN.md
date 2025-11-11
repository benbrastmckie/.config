# Implementation Plan: Fix REPORT_PATHS State Persistence in /coordinate

## Metadata
- **Spec**: 630_fix_coordinate_report_paths_state_persistence
- **Date**: 2025-11-10
- **Status**: AWAITING USER REVIEW
- **Priority**: HIGH (blocks /coordinate research phase execution)
- **Complexity**: LOW (targeted fix, clear solution)

---

## Executive Summary

The `/coordinate` command fails in the research phase with "unbound variable" errors when trying to reconstruct the REPORT_PATHS array. The root cause is missing state persistence for array metadata after workflow initialization.

**Impact**: /coordinate research phase fails, requiring manual workarounds by AI execution.

**Solution**: Save REPORT_PATHS array metadata to workflow state after initialization, align with existing REPORT_PATHS_JSON pattern.

**Effort**: ~30 minutes (2 files, ~15 lines of code)

---

## Root Cause Analysis

### Error Evidence

From `/home/benjamin/.config/.claude/specs/coordinate_output.md:68-71`:

```
Error: Exit code 127
/home/benjamin/.config/.claude/lib/workflow-initialization.sh: line 326: REPORT_PATHS_COUNT: unbound variable
/run/current-system/sw/bin/bash: line 68: REPORT_PATHS[$i-1]: unbound variable
```

### Execution Flow

**Block 1: Initialization** (coordinate.md:161-174)
```bash
# Calls initialize_workflow_paths
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"

# initialize_workflow_paths exports (workflow-initialization.sh:296-301):
export REPORT_PATHS_COUNT="${#report_paths[@]}"  # e.g., "2"
export REPORT_PATH_0="/path/to/001_research.md"
export REPORT_PATH_1="/path/to/002_research.md"

# Only TOPIC_PATH is saved to state:
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"

# ❌ REPORT_PATHS_COUNT and REPORT_PATH_N are NOT saved!
```

**Block 2: Research Handler** (coordinate.md:254-300)
```bash
# Load workflow state (only gets TOPIC_PATH, not REPORT_PATHS_COUNT)
load_workflow_state "$WORKFLOW_ID"

# Try to reconstruct array:
reconstruct_report_paths_array

# ❌ FAILS - REPORT_PATHS_COUNT is unbound!
```

### Why This Fails

1. **Subprocess Isolation**: Each bash block runs as separate process, exports don't persist
2. **Missing State Persistence**: REPORT_PATHS_COUNT never saved via `append_workflow_state`
3. **set -u Enforcement**: Bash fails fast on unbound variables
4. **Broken Function**: `reconstruct_report_paths_array()` expects variables that don't exist

---

## Proposed Solution

### Option A: Save Array Metadata to State (RECOMMENDED)

**Approach**: After `initialize_workflow_paths`, save REPORT_PATHS_COUNT and individual REPORT_PATH_N variables to workflow state.

**Advantages**:
- ✅ Minimal change (5 lines in coordinate.md)
- ✅ Uses existing state-persistence.sh infrastructure
- ✅ No changes to workflow-initialization.sh needed
- ✅ Works with existing reconstruct function

**Implementation**:

```bash
# In coordinate.md after line 173 (after append_workflow_state "TOPIC_PATH"):

# Save report paths array metadata to state
# (Required by reconstruct_report_paths_array in subsequent blocks)
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"
for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
  append_workflow_state "REPORT_PATH_$i" "${!REPORT_PATH_$i}"
done
```

**Why This Works**:
- Variables are now in workflow state file
- `load_workflow_state` restores them
- `reconstruct_report_paths_array()` works unchanged

---

### Option B: Use JSON Pattern Everywhere (ALTERNATIVE)

**Approach**: Initialize REPORT_PATHS as JSON from the start, reconstruct using jq.

**Advantages**:
- ✅ Consistent with existing REPORT_PATHS_JSON pattern (line 461)
- ✅ Single source of truth for array serialization
- ✅ No numbered variable proliferation

**Disadvantages**:
- ❌ Requires modifying workflow-initialization.sh
- ❌ More complex (2 functions to change)
- ❌ Requires jq for basic initialization

**Implementation**:

```bash
# In coordinate.md after line 173:
# Save report paths as JSON (matching pattern used after research completion)
append_workflow_state "REPORT_PATHS_JSON" "$(printf '%s\n' "${REPORT_PATHS[@]}" | jq -R . | jq -s .)"

# Modify reconstruct_report_paths_array in workflow-initialization.sh:
reconstruct_report_paths_array() {
  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
  else
    REPORT_PATHS=()
  fi
}
```

---

### Option C: Remove reconstruct Function (SIMPLIFICATION)

**Approach**: Remove `reconstruct_report_paths_array()` entirely, build array manually in each block.

**Advantages**:
- ✅ No complex state persistence
- ✅ Explicit and clear
- ✅ Removes abstraction that doesn't provide value

**Disadvantages**:
- ❌ Code duplication across blocks
- ❌ Removes reusability (if other commands use it)

**Implementation**:

```bash
# In research handler (coordinate.md:300), replace:
reconstruct_report_paths_array

# With:
REPORT_PATHS=()
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_NUM=$(printf "%03d" $i)
  REPORT_PATHS+=("${TOPIC_PATH}/reports/${REPORT_NUM}_research.md")
done
```

---

## Recommendation: Option A

**Rationale**:

1. **Least invasive**: Only touches coordinate.md, no library changes
2. **Uses existing pattern**: `append_workflow_state` already used for other variables
3. **Works immediately**: No refactoring of reconstruct function
4. **Maintainable**: Clear cause-effect relationship

**Risk**: LOW - Simple state persistence addition

**Testing**: Easy to validate - run any /coordinate workflow and check research phase

---

## Implementation Details

### Files to Modify

**1. `.claude/commands/coordinate.md`** (1 change)

**Location**: After line 173 (after `append_workflow_state "TOPIC_PATH"`)

**Code to Add**:
```bash
# Save report paths array metadata to state
# Required by reconstruct_report_paths_array() in subsequent bash blocks
# (Export doesn't persist across blocks due to subprocess isolation)
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"

# Save individual report path variables
# Using C-style loop to avoid history expansion issues with array expansion
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  append_workflow_state "$var_name" "${!var_name}"
done

echo "Saved $REPORT_PATHS_COUNT report paths to workflow state"
```

**Justification**:
- Matches pattern in workflow-initialization.sh:296-301
- Uses C-style for loop (avoids `!` history expansion issues)
- Clear comments explain why this is needed

---

### Testing Plan

**Test 1: Research-Only Workflow**
```bash
/coordinate "Research bash subprocess execution patterns"
```

**Expected**:
- ✅ No "unbound variable" errors
- ✅ Research phase completes successfully
- ✅ Reports created in topic directory
- ✅ State file contains REPORT_PATHS_COUNT and REPORT_PATH_N variables

**Verification**:
```bash
# Check state file contains report paths
cat ~/.claude/tmp/workflow_coordinate_*.sh | grep REPORT_PATH
```

**Test 2: Research-and-Plan Workflow**
```bash
/coordinate "Research and plan coordinate improvements"
```

**Expected**:
- ✅ Research phase passes
- ✅ Planning phase receives report paths correctly
- ✅ Plan file created successfully

**Test 3: State Restoration**
```bash
# After test 1 or 2, manually verify state restoration
source ~/.claude/tmp/workflow_coordinate_*.sh
echo "REPORT_PATHS_COUNT=$REPORT_PATHS_COUNT"
echo "REPORT_PATH_0=$REPORT_PATH_0"
```

**Expected**:
- Variables should have values (not unbound)

---

## Integration with Existing Infrastructure

### State Persistence Library Integration

**Existing Pattern** (`state-persistence.sh`):
```bash
append_workflow_state() {
  local key="$1"
  local value="$2"
  echo "export $key=\"$value\"" >> "$STATE_FILE"
}
```

**Our Usage**:
```bash
append_workflow_state "REPORT_PATHS_COUNT" "2"
append_workflow_state "REPORT_PATH_0" "/path/001.md"
append_workflow_state "REPORT_PATH_1" "/path/002.md"
```

**Result in State File**:
```bash
export REPORT_PATHS_COUNT="2"
export REPORT_PATH_0="/path/001.md"
export REPORT_PATH_1="/path/002.md"
```

### Alignment with Standards

**From `.claude/docs/concepts/patterns/checkpoint-recovery.md`**:
> State persistence should save all variables needed for workflow resumption

**From `.claude/docs/concepts/patterns/context-management.md`**:
> Minimize state file size, but don't sacrifice correctness

**Our Approach**:
- ✅ Saves only essential metadata (count + paths)
- ✅ Enables workflow resumption
- ✅ Small overhead (2-4 variables for typical workflows)

---

## Alternative Improvements (Future Work)

### 1. Standardize Array Persistence Pattern

**Current State**: Inconsistent array handling
- Some use numbered variables (REPORT_PATH_0, REPORT_PATH_1)
- Some use JSON (REPORT_PATHS_JSON)

**Future Standard**:
```bash
# Save array
save_array_to_state "REPORT_PATHS" "${REPORT_PATHS[@]}"

# Load array
load_array_from_state "REPORT_PATHS"
```

**Implementation**:
- Create `array-persistence.sh` library
- Migrate all array uses to standard pattern
- Remove reconstruct functions

**Effort**: MEDIUM (affects multiple commands)

---

### 2. Remove reconstruct_report_paths_array Entirely

**Rationale**: Function adds abstraction without value

**Current**:
```bash
# Caller must ensure REPORT_PATHS_COUNT and REPORT_PATH_N are in state
reconstruct_report_paths_array  # Fragile, unclear dependencies
```

**Proposed**:
```bash
# Explicit, clear, no hidden dependencies
if [ -n "${REPORT_PATHS_JSON:-}" ]; then
  mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
fi
```

**Effort**: LOW (change 1 function, update callers)

---

### 3. Add State Validation

**Problem**: No validation that required state variables exist

**Solution**:
```bash
# In research handler, before using variables:
required_vars=("WORKFLOW_DESCRIPTION" "WORKFLOW_SCOPE" "TOPIC_PATH" "REPORT_PATHS_COUNT")
for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: Required state variable $var not found"
    exit 1
  fi
done
```

**Effort**: LOW (add validation function to error-handling.sh)

---

## Risks and Mitigation

### Risk 1: State File Size Growth

**Risk**: Saving arrays increases state file size

**Mitigation**:
- Current overhead: ~100 bytes per report path (negligible)
- Typical workflows: 2-4 reports = 200-400 bytes total
- Acceptable given context window savings elsewhere

### Risk 2: Breaking Other Commands

**Risk**: Changes to workflow-initialization.sh affect other commands

**Mitigation**:
- Option A doesn't modify workflow-initialization.sh
- Changes only in coordinate.md (isolated)
- No impact on /orchestrate or /supervise

### Risk 3: JSON vs Export Inconsistency

**Risk**: Mix of patterns (numbered exports + JSON) is confusing

**Mitigation**:
- Short term: Option A gets /coordinate working immediately
- Long term: Create spec for array persistence standardization
- Document pattern in command development guide

---

## Checklist for Implementation

- [ ] Read coordinate.md around line 173
- [ ] Add state persistence for REPORT_PATHS_COUNT
- [ ] Add loop to persist individual REPORT_PATH_N variables
- [ ] Test with research-only workflow
- [ ] Test with research-and-plan workflow
- [ ] Verify state file contains expected variables
- [ ] Update documentation (if needed)
- [ ] Create diagnostic report confirming fix

---

## Documentation Updates

### Files to Update

**1. `.claude/docs/guides/coordinate-command-guide.md`** (if exists)
- Document state persistence pattern
- Explain why report paths need to be saved

**2. `.claude/docs/concepts/patterns/checkpoint-recovery.md`**
- Add example: "Persisting array metadata for cross-block access"

**3. `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/`**
- Add this issue to the series (004 or 005)
- Cross-reference with variable scoping issue (003)

---

## Success Criteria

### Must Have
- [x] Root cause identified and documented
- [ ] Fix implemented in coordinate.md
- [ ] Test 1 (research-only) passes without errors
- [ ] Test 2 (research-and-plan) passes without errors
- [ ] State file verification shows REPORT_PATHS_COUNT saved

### Should Have
- [ ] All existing /coordinate workflows still work
- [ ] No performance regression
- [ ] Documentation updated with pattern

### Nice to Have
- [ ] Standardized array persistence pattern defined
- [ ] Migration plan for other commands created
- [ ] Validation function added to error-handling.sh

---

## Timeline Estimate

**Immediate Fix (Option A)**:
- Implementation: 10 minutes
- Testing: 15 minutes
- Documentation: 5 minutes
- **Total**: 30 minutes

**Future Improvements** (Optional):
- Standardize array persistence: 2 hours
- Remove reconstruct function: 1 hour
- Add state validation: 1 hour

---

## Open Questions for User Review

1. **Prefer Option A (minimal change) or Option B (JSON everywhere)?**
   - Recommendation: Option A for immediate fix, consider Option B for future refactor

2. **Should we remove `reconstruct_report_paths_array()` entirely?**
   - Recommendation: No - keep for now, revisit after array persistence standardization

3. **Add state validation checks in all handlers?**
   - Recommendation: Yes - create follow-up spec for this

4. **Update other orchestration commands (/orchestrate, /supervise) simultaneously?**
   - Recommendation: No - fix /coordinate first, then audit others

---

## Next Steps (After User Approval)

1. **Implement Option A** in coordinate.md
2. **Run Test 1** (research-only workflow)
3. **Run Test 2** (research-and-plan workflow)
4. **Verify state files** contain REPORT_PATHS_COUNT
5. **Create diagnostic report** confirming fix
6. **Update documentation** if needed

---

## Appendix: Debugging Commands

```bash
# View current state file
ls -ltr ~/.claude/tmp/workflow_coordinate_*.sh | tail -1
cat $(ls -tr ~/.claude/tmp/workflow_coordinate_*.sh | tail -1)

# Check if REPORT_PATHS_COUNT exists in state
grep REPORT_PATHS_COUNT ~/.claude/tmp/workflow_coordinate_*.sh

# Manually source state and check variables
source $(ls -tr ~/.claude/tmp/workflow_coordinate_*.sh | tail -1)
echo "REPORT_PATHS_COUNT=$REPORT_PATHS_COUNT"
echo "REPORT_PATH_0=$REPORT_PATH_0"

# Run coordinate with debug
/coordinate "test workflow" 2>&1 | tee /tmp/coordinate_debug.log
```

---

## References

- **Related Specs**:
  - Spec 620: Bash history expansion fixes
  - Spec 627: Bash execution patterns research

- **Related Reports**:
  - 002_diagnostic_analysis.md: Variable scoping issues
  - 003_bash_variable_scoping_diagnostic.md: Deep dive on library sourcing
  - 004_complete_fix_summary.md: Previous fixes to /coordinate

- **Standards**:
  - `.claude/docs/concepts/patterns/checkpoint-recovery.md`
  - `.claude/docs/concepts/patterns/context-management.md`
  - `.claude/docs/guides/command-development-guide.md`

---

**END OF IMPLEMENTATION PLAN**

**Status**: AWAITING USER REVIEW AND APPROVAL
