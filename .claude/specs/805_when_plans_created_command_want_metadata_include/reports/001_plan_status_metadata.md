# Plan Status Metadata Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Adding [NOT STARTED] status to plan metadata
- **Report Type**: codebase analysis

## Executive Summary

The plan creation system currently includes `[NOT STARTED]` status markers on individual phase headings but lacks a plan-level status field in the metadata section. Adding a `- **Status**: [NOT STARTED]` field to plan metadata would provide immediate visibility into overall plan execution status, complement the existing phase-level markers, and enable automated status tracking across the plan lifecycle.

## Findings

### Current Implementation Analysis

#### Phase-Level Status Markers

The plan-architect agent (`/home/benjamin/.config/.claude/agents/plan-architect.md`) already implements phase-level status markers:

**Location**: Lines 291-314
```markdown
### Phase Heading Format

Phase headings MUST include status markers for progress tracking:

**Required Format**: `### Phase N: Name [NOT STARTED]`

**Status Marker Lifecycle**:
1. **[NOT STARTED]**: Applied during plan creation (your responsibility)
2. **[IN PROGRESS]**: Applied by /build when phase execution begins
3. **[COMPLETE]**: Applied by /build when phase execution ends
4. **[BLOCKED]**: Applied when phase cannot proceed due to failures
```

**Verification in Completion Criteria** (Lines 803-806):
```bash
# 5. Status marker check (all phases must have [NOT STARTED])
PHASE_HEADERS=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo 0)
STATUS_MARKERS=$(grep -c "^### Phase [0-9].*\[NOT STARTED\]" "$PLAN_PATH" || echo 0)
```

#### Current Metadata Structure

Examining existing plans reveals the metadata section structure:

**Example from `/home/benjamin/.config/.claude/specs/804_build_commands_included_there_then_move/plans/001_build_commands_included_there_then_move_plan.md`** (Lines 3-14):
```markdown
## Metadata
- **Date**: 2025-11-19
- **Feature**: Restructure commands/README.md for workflow documentation
- **Scope**: Reorganize sections, add dependency documentation
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 15.5
- **Research Reports**:
  - [README Restructure Analysis](../reports/001_readme_restructure_analysis.md)
```

**Notable absence**: No `- **Status**:` field in plan metadata.

#### Research Report Status Fields

Research reports **do** include status fields in their "Implementation Status" section:

**Location**: Various reports in `/home/benjamin/.config/.claude/specs/*/reports/*.md`

**Examples found**:
- `- **Status**: Planning In Progress`
- `- **Status**: Planning Complete`
- `- **Status**: Research Complete`
- `- **Status**: Plan Revised`

This demonstrates precedent for lifecycle status tracking in artifacts.

### Gap Analysis

| Aspect | Current State | Desired State |
|--------|---------------|---------------|
| Phase status | `[NOT STARTED]` markers on phase headings | Unchanged |
| Plan metadata status | Not present | `- **Status**: [NOT STARTED]` |
| Status lifecycle | Only phases track lifecycle | Both plan and phases track lifecycle |
| Automated tracking | Phase markers updated by /build | Plan status also updated by /build |

### Implementation Locations Identified

1. **Plan-architect agent** (`/home/benjamin/.config/.claude/agents/plan-architect.md`)
   - Plan template (Lines 536-549): Add `- **Status**: [NOT STARTED]` to metadata
   - Completion criteria (Lines 729): Add check for status field
   - Verification commands (Lines 784-808): Add status field validation

2. **Build command** (`/home/benjamin/.config/.claude/commands/build.md`)
   - Update plan metadata status to `[IN PROGRESS]` at start
   - Update plan metadata status to `[COMPLETE]` or `[INCOMPLETE]` at end

### Status Lifecycle Proposal

```
[NOT STARTED] → [IN PROGRESS] → [COMPLETE]
                            ↘ [INCOMPLETE] (if phases blocked/failed)
```

- **[NOT STARTED]**: Plan created, no phases executed
- **[IN PROGRESS]**: At least one phase executing or completed
- **[COMPLETE]**: All phases completed successfully
- **[INCOMPLETE]**: Workflow stopped with failed/blocked phases

## Recommendations

### Recommendation 1: Add Status Field to Plan Template

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

Add `- **Status**: [NOT STARTED]` to the plan template in the metadata section (around line 541).

**Updated template section**:
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [Name]
- **Scope**: [Brief description]
- **Estimated Phases**: [N]
- **Estimated Hours**: [H]
- **Standards File**: /path/to/CLAUDE.md
- **Status**: [NOT STARTED]
- **Research Reports**:
```

**Rationale**: Provides immediate visibility into plan execution state.

### Recommendation 2: Update Completion Criteria

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

Add status field to required metadata verification (around line 729).

**Updated criteria**:
```markdown
### Content Completeness (MANDATORY SECTIONS)
- [x] All required metadata present (Date, Feature, Status, Research Reports, Standards, Complexity, Time)
```

**Rationale**: Ensures plan-architect always includes the status field.

### Recommendation 3: Add Status Verification Command

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

Add verification command to check status field exists (around line 801).

**New verification**:
```bash
# 6. Status field check
grep -q "^- \*\*Status\*\*: \[NOT STARTED\]" "$PLAN_PATH" || echo "WARNING: Status field missing or incorrect"
```

**Rationale**: Automated validation prevents incomplete plans.

### Recommendation 4: Update Build Command for Status Transitions

**File**: `/home/benjamin/.config/.claude/commands/build.md`

Add status transitions:
1. At workflow start: Update `- **Status**: [NOT STARTED]` to `- **Status**: [IN PROGRESS]`
2. At workflow end: Update to `- **Status**: [COMPLETE]` or `- **Status**: [INCOMPLETE]`

**Implementation approach**: Use sed substitution similar to phase status marker updates.

**Rationale**: Creates complete lifecycle tracking matching phase-level behavior.

### Recommendation 5: Update Documentation Standards

**File**: `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md`

Document the new status field and its lifecycle transitions.

**Rationale**: Ensures users understand and can verify status tracking.

## Implementation Priority

1. **High Priority**: Add status field to plan-architect template (Recommendation 1)
2. **High Priority**: Update completion criteria and verification (Recommendations 2-3)
3. **Medium Priority**: Update build command for status transitions (Recommendation 4)
4. **Low Priority**: Update documentation (Recommendation 5)

The plan creation change (Recommendations 1-3) should be implemented first since it's the user's explicit request. Build command integration can follow as an enhancement.

## References

- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Lines 291-314 (phase status markers), Lines 536-549 (plan template), Lines 729 (completion criteria), Lines 803-806 (verification commands)
- `/home/benjamin/.config/.claude/commands/plan.md` - Lines 1-419 (plan command workflow)
- `/home/benjamin/.config/.claude/specs/804_build_commands_included_there_then_move/plans/001_build_commands_included_there_then_move_plan.md` - Lines 3-14 (example metadata structure)
- `/home/benjamin/.config/.claude/specs/803_claude_buildoutputmd_which_looks_ok_but_i_dont/plans/001_claude_buildoutputmd_which_looks_ok_but__plan.md` - Lines 3-13 (example metadata structure)
- `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh` - Lines 1-1160 (plan utilities library)
