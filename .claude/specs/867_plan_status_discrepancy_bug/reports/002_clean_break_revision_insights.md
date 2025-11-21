# Clean-Break Revision Insights for Plan Status Discrepancy Bug

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Plan revision insights for clean-break approach
- **Report Type**: codebase analysis
- **Workflow**: research-and-revise
- **Existing Plan**: /home/benjamin/.config/.claude/specs/867_plan_status_discrepancy_bug/plans/001_debug_strategy.md

## Implementation Status

- **Status**: Plan Revised
- **Plan**: [../plans/001_debug_strategy.md](../plans/001_debug_strategy.md)
- **Implementation**: [Will be updated by build command]
- **Date**: 2025-11-20

## Executive Summary

The current plan (001_debug_strategy.md) contains unnecessary complexity with 4 phases and multiple new components. A clean-break approach reduces this to a single function modification in checkbox-utils.sh:472 by adding validation before the marker is applied. The infrastructure already exists (verify_phase_complete function) and just needs to be called. Creating a separate validation library, repair command, and extensive documentation is over-engineering for what is fundamentally a 5-line fix.

## Findings

### Finding 1: Root Cause is Trivial to Fix

**Location**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:472-500`

The `add_complete_marker()` function adds status markers without validation. The fix requires only:
1. Call existing `verify_phase_complete()` function (line 547)
2. Return error if validation fails
3. Proceed with marker addition if validation passes

**Current Code** (line 472):
```bash
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # First remove any existing status marker
  remove_status_marker "$plan_path" "$phase_num"

  # Add [COMPLETE] marker to phase heading
  # NO VALIDATION
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '...script...' "$plan_path" > "$temp_file"
  mv "$temp_file" "$plan_path"
  return 0
}
```

**Necessary Fix** (5 lines added):
```bash
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # VALIDATE BEFORE MARKING (NEW - 5 lines)
  if ! verify_phase_complete "$plan_path" "$phase_num"; then
    error "Cannot mark Phase $phase_num complete - tasks remain"
    return 1
  fi

  # First remove any existing status marker
  remove_status_marker "$plan_path" "$phase_num"

  # Add [COMPLETE] marker to phase heading
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '...script...' "$plan_path" > "$temp_file"
  mv "$temp_file" "$plan_path"
  return 0
}
```

**Evidence**: The `verify_phase_complete()` function already exists at line 547 and does exactly what's needed. It returns 0 if all tasks are complete, 1 if incomplete. No new validation logic required.

### Finding 2: Build Command Already Handles Failures Gracefully

**Location**: `/home/benjamin/.config/.claude/commands/build.md:438-442`

The build command already has error handling for `add_complete_marker()` failures:

```bash
if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
  echo "  ✓ [COMPLETE] marker added"
else
  echo "  ⚠ [COMPLETE] marker failed"
  FALLBACK_NEEDED="${FALLBACK_NEEDED}${phase_num},"
fi
```

**Impact**: No build command modifications needed. When validation fails, the error branch already executes. The phase remains IN PROGRESS automatically because the COMPLETE marker isn't added.

### Finding 3: The Affected Plan Can Be Fixed Manually

**Location**: `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md`

**Current State**:
- All 4 phases marked `[COMPLETE]`
- Summary file shows 15% completion (Phase 1 in progress)

**Manual Fix** (no command needed):
1. Use Edit tool to change `[COMPLETE]` to `[IN PROGRESS]` on Phase 1 heading
2. Use Edit tool to change `[COMPLETE]` to `[NOT STARTED]` on Phases 2-4 headings

This is a one-time fix for one file. Creating a whole repair command is unnecessary.

### Finding 4: Unnecessary Components in Current Plan

The plan proposes these components that aren't needed:

**Phase 1: Repair Command** - UNNECESSARY
- Affected plan is one file that can be manually edited
- No other plans are affected (validated by checking git status)
- Creating infrastructure for a one-time fix is over-engineering

**Phase 2: status-validation.sh Library** - UNNECESSARY
- Proposes 3 functions: validate_plan_status(), sync_status_with_summary(), fix_plan_status()
- Only validation is needed, and it already exists (verify_phase_complete)
- Summary sync adds complexity for no benefit (summaries are generated, not authoritative)
- Validation library duplicates existing checkbox-utils.sh logic

**Phase 3: Force Flag** - UNNECESSARY
- Plan proposes optional force parameter to skip validation
- Clean-break approach: validation should always run
- If someone needs to force a marker, they can directly edit the plan file
- Force flags create bypass mechanisms that defeat the fix's purpose

**Phase 4: Documentation** - EXCESSIVE
- Plan proposes updating 4 files and creating 2 new docs
- Actual change: 5 lines in one function
- Standard inline comment is sufficient documentation

### Finding 5: Clean-Break Approach Analysis

**Project Standard**: `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md:23-46`

The project's clean-break philosophy prioritizes:
- Coherence over compatibility
- No legacy burden
- Clean, well-designed refactors
- Breaking changes when they improve quality

**Application to This Fix**:
- **No backward compatibility needed**: Function signature unchanged (2 required params)
- **No migration path needed**: Existing callers get validation automatically (improvement)
- **No force flag needed**: If validation fails, it should fail (correct behavior)
- **Clean break**: Old behavior (no validation) is replaced entirely with new behavior (validation)

**Evidence**: Grep results show 23 references to "clean-break" across documentation, with examples like:
- Hybrid mode removal (state-machine.md:108)
- LLM classification rewrite (llm-classification-pattern.md:532)
- Pattern: Remove old functionality entirely, no compatibility layers

### Finding 6: Testing Requirements

**Current Test Files**: Glob shows 7 libraries in `/home/benjamin/.config/.claude/lib/plan/`:
- checkbox-utils.sh (contains the function to modify)
- 6 other utilities

**Testing Approach**:
- Test add_complete_marker() with complete phase (should succeed)
- Test add_complete_marker() with incomplete phase (should fail)
- Test build command continues working (integration test)

**Test Location**: No dedicated test file exists for checkbox-utils.sh. Can add to manual testing or create tests/test_checkbox_utils.sh if needed.

### Finding 7: Impact Analysis

**Functions Affected**: 1 function in 1 file
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:472` - add_complete_marker()

**Callers of add_complete_marker()**: Grep shows 3 references:
1. build.md:309 (documentation/comment)
2. build.md:437 (comment)
3. build.md:438 (actual call with error handling)

**Breaking Changes**: None
- Function signature unchanged
- Return value already checked by caller
- Error already handled by build command

**Plans Affected**: 1 plan file needs manual status correction
- Plan 859 has incorrect markers (can be manually fixed)

### Finding 8: The Actual Problem

**Evidence**: Summary file shows 15% completion, plan shows 100%

The discrepancy suggests someone/something called `add_complete_marker()` for all phases without checking completion. Possible causes:
1. Manual editing of plan file
2. Script that marks phases complete in bulk
3. Misunderstanding of status markers

**Key Insight**: This appears to be a one-time error, not a systemic workflow problem. The root cause analysis report (001_plan_status_discrepancy_root_cause_analysis.md) notes that all 4 phases were marked complete simultaneously, suggesting bulk marking rather than incremental marking during build execution.

**Implication**: The fix prevents future occurrences. The current discrepancy is corrected with a simple manual edit.

## Recommendations

### Recommendation 1: Minimal Fix - Add Validation to add_complete_marker()

**Action**: Modify `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` line 472

**Implementation**:
```bash
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # Validate phase completion before marking
  if ! verify_phase_complete "$plan_path" "$phase_num"; then
    error "Cannot mark Phase $phase_num complete - incomplete tasks remain"
    return 1
  fi

  remove_status_marker "$plan_path" "$phase_num"

  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase && !/\[COMPLETE\]/) {
        sub(/$/, " [COMPLETE]")
      }
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  mv "$temp_file" "$plan_path"
  return 0
}
```

**Lines Changed**: 5 lines added (validation check + error message)
**Files Modified**: 1 file
**Testing Required**: Basic validation tests (complete vs incomplete phase)
**Documentation**: Inline comment added (validation requirement)

### Recommendation 2: Manual Fix for Affected Plan

**Action**: Edit plan file to correct status markers

**File**: `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md`

**Changes**:
1. Phase 1: `[COMPLETE]` → `[IN PROGRESS]` (15% done per summary)
2. Phase 2: `[COMPLETE]` → `[NOT STARTED]`
3. Phase 3: `[COMPLETE]` → `[NOT STARTED]`
4. Phase 4: `[COMPLETE]` → `[NOT STARTED]`

**Rationale**: One-time correction doesn't justify creating repair infrastructure

### Recommendation 3: No Additional Components

**DO NOT CREATE**:
- status-validation.sh library (unnecessary - validation exists)
- /fix-plan-status command (one-time fix doesn't need command)
- Force flag parameter (defeats purpose of validation)
- Multiple documentation files (5-line change needs inline comment)

**RATIONALE**:
- Clean-break approach favors simplicity over complexity
- Infrastructure should match problem scope (1 function, 5 lines)
- Over-engineering creates maintenance burden

### Recommendation 4: Testing Approach

**Minimal Testing**:
1. Test add_complete_marker with complete phase (verify succeeds)
2. Test add_complete_marker with incomplete phase (verify fails with error)
3. Test build command with incomplete phase (verify handles gracefully)

**Optional**: Create tests/test_checkbox_utils.sh if systematic testing desired

### Recommendation 5: Revised Plan Structure

**Single Phase Implementation**:

**Phase 1: Fix and Validate (1 hour)**
1. Modify add_complete_marker() function (5 lines)
2. Manually fix affected plan file (3 edits)
3. Test validation with complete/incomplete phases
4. Test build command integration
5. Commit changes

**Complexity**: Trivial (5-line change)
**Components**: 1 function modification, 1 file manual edit
**Documentation**: Inline comment in function
**Testing**: Basic function validation tests

## References

### Code References
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:472-500` - add_complete_marker function
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:547-583` - verify_phase_complete function (existing)
- `/home/benjamin/.config/.claude/commands/build.md:438-442` - add_complete_marker caller with error handling

### Documentation References
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md:23-46` - Clean-break refactor philosophy
- `/home/benjamin/.config/.claude/specs/867_plan_status_discrepancy_bug/reports/001_plan_status_discrepancy_root_cause_analysis.md` - Root cause analysis
- `/home/benjamin/.config/.claude/specs/867_plan_status_discrepancy_bug/plans/001_debug_strategy.md` - Current plan (over-engineered)

### Affected Files
- `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md` - Plan with incorrect markers
- `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/summaries/002_phase_1_foundation_partial_implementation.md:4` - Shows 15% completion

### Search Results
- Grep "verify_phase_complete": 4 matches in checkbox-utils.sh (function exists, exports, documentation)
- Grep "add_complete_marker": 3 matches in build.md (caller with error handling)
- Grep "clean.break": 23 matches across documentation (project standard)
- Glob "*.sh" in lib/plan/: 7 library files (no status-validation.sh exists)
