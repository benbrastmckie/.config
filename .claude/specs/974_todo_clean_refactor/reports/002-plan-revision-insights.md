# Plan Revision Insights: /todo --clean Refactor

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: Plan revision for /todo --clean command
- **Report Type**: Revision guidance for existing plan
- **Workflow**: revise workflow for Plan 974
- **Status**: Research Complete

## Executive Summary

The existing Plan 974 aligns well with the user's stated objectives to keep the plan-generation approach while removing the 30-day age threshold. The primary revision focuses on clarifying that `/todo --clean` should generate a cleanup plan (maintaining current architectural pattern) but target ALL Completed, Superseded, and Abandoned projects without requiring 30-day age filtering. The plan requires minimal modifications to achieve this goal.

## Current Implementation Analysis

### Command Structure (todo.md)
- **Location**: `/home/benjamin/.config/.claude/commands/todo.md`
- **Lines 618-652**: Clean Mode section
- **Current behavior**: Generates cleanup plan via plan-architect agent
- **Age threshold**: Currently documented as "completed projects older than 30 days" (line 620)

### Plan 974 Design
The existing plan maintains the plan-generation approach as intended:
- **Block 5**: Proposed direct execution (lines 89-114)
- **Key Decision**: Changed from plan-generation to direct cleanup (line 18)
- **Phase 2**: Replaces plan-generation description (lines 254-265)

## Revision Requirements Analysis

### User Request Clarity
The user wants to **KEEP** the plan-generation approach but modify:

1. **Remove 30-day age threshold**: Allow cleanup of ANY project marked Complete/Superseded/Abandoned
2. **Preserve plan-architect invocation**: Continue using plan-architect agent to generate cleanup plans
3. **Expand target sections**: Include Completed + Superseded + Abandoned (not just Completed)

### Critical Discovery: Plan Mismatch
**FINDING**: Plan 974 currently specifies **direct execution** (not plan-generation):
- Line 6: "Change from plan-generation to direct directory removal"
- Line 18: "Execution Model: Direct cleanup (not plan generation)"
- Phase 2 (lines 254-265): "Replace the plan-generation Clean Mode section... with direct execution logic"

**PROBLEM**: This contradicts the user's stated desire to "keep plan-generation approach"

## Recommended Revision Strategy

### Option 1: Minimal Scope Revision (RECOMMENDED)
Keep Plan 974 structure but modify it to maintain plan-generation approach:

**Changes Required**:
1. **Metadata Update** (lines 1-14):
   - Change Scope from "Change from plan-generation to direct directory removal" to "Refactor /todo --clean to remove 30-day age threshold while maintaining plan-generation approach"

2. **Overview Update** (lines 16-27):
   - Line 21: Change "Execution Model: Direct cleanup (not plan generation)" to "Execution Model: Plan generation (maintains current approach)"
   - Remove lines 17-18 about "two-step process" as complexity point
   - Update Key Changes to focus on threshold removal, not execution model change

3. **Research Summary Update** (lines 28-45):
   - Reframe findings around age threshold removal
   - Focus on plan-architect integration (already exists)
   - Remove findings about "direct execution" recommendations

4. **Technical Design Update** (lines 62-166):
   - **Component Structure**: Remove "Block 5: Clean Mode" direct execution
   - **Workflow**: Simplify to show plan generation only (current behavior)
   - Modify plan prompt to remove age-based filtering

5. **Implementation Phases** (lines 204-457):
   - **Phase 1**: Modify `filter_completed_projects()` to accept Completed/Superseded/Abandoned AND remove age threshold
   - **Phase 2**: Update plan-architect prompt in Block 5 (around lines 624-651) to remove age requirement
   - **Phase 3-5**: Adjust to match reduced scope

### Option 2: Create New Plan 975
Create a separate plan for maintaining current plan-generation approach:
- Smaller scope than Plan 974
- Focuses solely on age threshold removal
- Leaves Plan 974 as historical reference
- Estimated 2-3 phases (vs Plan 974's 5 phases)

## Key Code Sections Needing Modification

### todo.md Clean Mode Section
**Current** (lines 618-622):
```
When invoked with `--clean` flag, identifies completed projects older than 30 days and generates a cleanup plan.

If CLEAN_MODE is true, instead of updating TODO.md, generate a cleanup plan for completed projects older than 30 days.
```

**Should Be**:
```
When invoked with `--clean` flag, generates a cleanup plan for all projects marked Completed, Superseded, or Abandoned.

If CLEAN_MODE is true, instead of updating TODO.md, generate a cleanup plan for projects in target sections (Completed, Superseded, Abandoned).
```

### plan-architect Task Block
**Current** (lines 624-651):
- References `age_threshold: 30 days`
- Only mentions "completed_projects"
- Archive path: `archive/completed_$(date +%Y%m%d)/`

**Should Specify**:
- Remove age_threshold requirement entirely
- Include three sections: "completed_projects", "superseded_projects", "abandoned_projects"
- Archive path unchanged (or make section-specific: `archive/cleaned_$(date +%Y%m%d)/`)

### todo-functions.sh Library Functions
**Current function** (to be modified):
- `filter_completed_projects()`: Only filters status="completed" with age check
- Uses age threshold from metadata

**Needed changes**:
- Rename to `filter_eligible_cleanup_projects()` or keep name, expand logic
- Accept all three statuses: "completed", "superseded", "abandoned"
- Remove age-based filtering entirely
- Maintain backward compatibility if referenced elsewhere

## Findings Summary

### Strengths of Plan 974
1. Comprehensive 5-phase structure covers all aspects
2. Strong focus on safety (git verification, archiving)
3. Good error handling integration
4. Clear documentation and testing strategy
5. Risk management well-developed

### Misalignment with User Request
1. Plan proposes direct execution, user wants to keep plan-generation
2. Phase 1 adds cleanup functions unnecessary for plan-generation approach
3. Phases 2-5 focused on implementing direct execution (not applicable)
4. Risk mitigation for direct execution (archive strategies) less relevant

### Revision Complexity
- **If Option 1**: Low-to-Medium (modify existing plan sections)
- **If Option 2**: Low (create smaller new plan)
- **Implementation complexity**: Low (existing plan-architect already handles plan generation)

## Recommendations

### Recommendation 1: Clarify User Intent First
Before revising Plan 974, confirm with user:
- Does "keep plan-generation approach" mean user wants `/todo --clean` to output a plan file (not execute cleanup)?
- Should plan-architect still generate plan-PHASE details, or just cleanup task descriptions?
- Should cleanup plan be auto-executed by `/build`, or saved for manual review?

### Recommendation 2: Choose Revision Approach
- **If scope is clear**: Use Option 1 (minimal revision of Plan 974)
  - Modify ~4 sections of existing plan
  - Estimated 2-3 hours revision effort
  - Maintains context of original research

- **If scope is unclear**: Use Option 2 (create Plan 975)
  - Fresh start with clear scope
  - No need to reconcile competing directions
  - Better documentation of final approach

### Recommendation 3: Clarify Terminology
Establish clear distinction:
- **"Plan-generation approach"**: `/todo --clean` creates a cleanup plan file → user reviews → `/build` executes
- **"Direct execution approach"**: `/todo --clean` directly removes directories (Plan 974's current design)

Plan 974 implements approach 2; user request aligns with approach 1.

### Recommendation 4: Update Research Documentation
After user clarification:
- Create supplementary research report documenting age-threshold removal requirements
- Analyze current `filter_completed_projects()` function behavior
- Document plan-architect prompt modifications needed
- Include examples of new plan structure with 3 target sections

## References

**Primary Plan File**:
- `/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/plans/001-todo-clean-refactor-plan.md` (lines 1-699)

**Command Implementation**:
- `/home/benjamin/.config/.claude/commands/todo.md` (lines 1-679)
  - Lines 618-652: Current Clean Mode section
  - Lines 624-651: plan-architect task block

**Library Functions**:
- `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh` (lines 1-100+)
  - Project discovery and classification functions

**Key Differences**:
- User requirement: Maintain plan-generation, remove 30-day threshold, expand to 3 sections
- Plan 974: Replace plan-generation with direct execution, remove age threshold, expand to 3 sections
- Overlap: Age threshold removal, expand target sections (both agree)
- Conflict: Execution model (plan-generation vs direct execution)

