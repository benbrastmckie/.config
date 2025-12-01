# Topic Number Allocation Analysis Report

**Report ID**: 001-topic-number-allocation-analysis
**Workflow**: Research why /repair allocated topic number 1000 instead of wrapping to 003
**Analysis Date**: 2025-12-01
**Complexity**: 2 (Moderate)

---

## Executive Summary

The topic number 1000 was allocated instead of the correct 003 because the orchestrator (primary agent) manually executed bash blocks that **bypassed the proper `initialize_workflow_paths()` function**. The correct allocation logic exists in `allocate_and_create_topic()` and properly wraps at 1000 (999 → 000), but this function was not called.

**Root Cause**: Manual bash execution bypassed the /repair command's documented workflow, using ad-hoc topic number calculation without the modulo wrapping.

---

## Technical Analysis

### Correct Allocation Logic (unified-location-detection.sh:360)

The `allocate_and_create_topic()` function correctly implements wrapping:

```bash
# Increment with rollover at 1000 (999 -> 000)
local next_num=$(( (10#$max_num + 1) % 1000 ))
topic_number=$(printf "%03d" "$next_num")
```

This logic:
1. Forces base-10 interpretation with `10#$max_num` (prevents octal issues)
2. Uses modulo 1000 for wrapping (`% 1000`)
3. Formats as 3-digit zero-padded number

### Buggy Manual Execution (What Actually Happened)

During /repair execution, the orchestrator ran this manual code:

```bash
EXISTING_NUMS=$(find "$SPECS_ROOT" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | sed 's:.*/::' | grep -oE '^[0-9]+' | sort -n)
LAST_NUM=$(echo "$EXISTING_NUMS" | tail -1)
TOPIC_NUM=$(printf "%03d" $((${LAST_NUM:-0} + 1)))
```

**Bug**: The calculation `$((${LAST_NUM:-0} + 1))` does NOT wrap:
- When `LAST_NUM=999`, result is `1000` (not `000`)
- Missing: `% 1000` modulo operation

### Why This Happened

1. The /repair command markdown file correctly specifies using `initialize_workflow_paths()`
2. However, the orchestrator executed manual bash blocks instead of following the documented flow
3. The manual bash blocks reimplemented topic number allocation incorrectly

---

## Evidence

### Current Directory State

```
$ ls -1 .claude/specs/ | grep "^[0-9]" | tail -10
983_repair_20251130_100233
984_repair_research_20251130_101553
985_phase_metadata_status_fix
986_optimize_command_performance
989_no_name_error
990_commands_todo_tracking_integration
993_todo_command_revise_standards
998_commands_uniformity_enforcement
999_commands_plans_todo_standard
1000_repair_todo_20251201_111414   <-- INCORRECT (should be 003)
```

### Correct Behavior Verification

When using proper `initialize_workflow_paths()`:
```
Topic Path: /home/benjamin/.config/.claude/specs/003_topic_number_allocation_fix
Topic Num: 003 (correctly wrapped!)
```

---

## Root Cause Summary

| Aspect | Expected | Actual |
|--------|----------|--------|
| Function Used | `initialize_workflow_paths()` → `allocate_and_create_topic()` | Manual bash calculation |
| Wrapping Logic | `$(( (10#$max + 1) % 1000 ))` | `$(( $max + 1 ))` |
| Result for max=999 | 000 | 1000 |
| Allocated Number | 003 (next available after wrap) | 1000 (no wrap) |

---

## Recommendations

### Fix 1: Remove Manual Topic Allocation from Orchestrator

The orchestrator should NEVER manually calculate topic numbers. All topic allocation must go through:
- `initialize_workflow_paths()` (workflow-initialization.sh)
- Which uses `allocate_and_create_topic()` (unified-location-detection.sh)

### Fix 2: Add Guard in Manual Bash Patterns

If manual allocation is ever needed as fallback, ensure wrapping:

```bash
# CORRECT: With wrapping
TOPIC_NUM=$(printf "%03d" $(( (10#${LAST_NUM:-0} + 1) % 1000 )))

# WRONG: Without wrapping
TOPIC_NUM=$(printf "%03d" $((${LAST_NUM:-0} + 1)))
```

### Fix 3: Rename the Incorrectly Allocated Directory

```bash
cd /home/benjamin/.config/.claude/specs
mv 1000_repair_todo_20251201_111414 004_repair_todo_20251201_111414
```

Note: This also requires updating any plan file references.

### Fix 4: Documentation Enhancement

Add explicit warning to command documentation that topic number allocation must use library functions, not manual calculation.

---

## Files Involved

| File | Role |
|------|------|
| `.claude/lib/core/unified-location-detection.sh` | Contains correct `allocate_and_create_topic()` |
| `.claude/lib/workflow/workflow-initialization.sh` | Wrapper that calls atomic allocation |
| `.claude/commands/repair.md` | /repair command - correctly specifies using `initialize_workflow_paths()` |

---

## Prevention Strategy

1. **Library Enforcement**: All topic number allocation MUST use `allocate_and_create_topic()` or higher-level wrappers
2. **Orchestrator Training**: When executing workflow commands, follow the documented bash blocks exactly rather than improvising
3. **Validation Hook**: Consider adding a pre-commit hook that checks for invalid topic numbers (>999 or non-3-digit)

---

## Conclusion

The bug is **not** in the /repair command or allocation libraries - they correctly implement wrapping. The bug occurred because the orchestrator bypassed the documented workflow and used manual bash code that lacked the modulo operation. The fix is procedural: always use the provided library functions for topic allocation.
