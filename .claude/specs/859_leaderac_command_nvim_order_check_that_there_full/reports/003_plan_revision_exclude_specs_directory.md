# Plan Revision: Exclude specs/ Directory Consideration

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Plan revision to exclude specs/ directory from artifact coverage
- **Report Type**: plan revision analysis
- **Workflow**: revise

## Executive Summary

The implementation plan incorrectly treats specs/ directory artifacts (plans, reports, summaries) as permanent .claude/ artifacts requiring picker integration. According to directory-protocols.md, specs/ is a temporary working directory that is gitignored (except debug/). The plan must be revised to exclude specs/{topic}/plans/, reports/, and summaries/ from artifact coverage goals, focusing instead on the 8 permanent .claude/ directories that constitute the actual system artifacts.

## Findings

### 1. specs/ Directory Nature and Purpose

**Key Discovery**: The specs/ directory is explicitly defined as a **temporary artifact workspace** in directory-protocols.md:

**From /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:449-463**:
```markdown
| Artifact Type | Committed to Git | Reason |
|---------------|------------------|--------|
| `debug/` | YES | Project history, issue tracking |
| `plans/` | NO | Local working artifacts |
| `reports/` | NO | Local working artifacts |
| `summaries/` | NO | Local working artifacts |
| `scripts/` | NO | Temporary investigation |
| `outputs/` | NO | Regenerable test results |
| `artifacts/` | NO | Operational metadata |
| `backups/` | NO | Temporary recovery files |
```

**Gitignore Configuration** (lines 464-476):
```gitignore
# Specs directory (gitignored except debug/)
specs/
!specs/**/debug/
!specs/**/debug/**
```

**Lifecycle Classification** (lines 329-335):
- **Created during**: Planning, research, documentation phases
- **Preserved**: Indefinitely (reference material)
- **Cleaned up**: Never
- **Gitignore**: YES (local working artifacts)

### 2. Current Plan's Incorrect Assumptions

**From plan lines 6, 20, 41**:
- Scope includes "add 5 missing artifact types (scripts/, tests/, specs/ subdirs)"
- Overview states "lacks coverage for several critical .claude/ directories (scripts/, tests/, specs/ subdirectories)"
- Gap analysis lists "Missing 5 artifact types: scripts/, tests/, specs/{topic}/plans/, reports/, summaries/"

**Problem**: These statements treat specs/ artifacts as permanent system artifacts equivalent to commands/, agents/, etc.

**Reality**: specs/ artifacts are:
1. **Temporary working files** for active development
2. **Gitignored** (not part of permanent codebase)
3. **Local-only** (not synchronized across systems)
4. **Workflow-specific** (created during /plan, /research commands, deleted after completion)

### 3. Permanent vs Temporary Artifacts

**Permanent .claude/ System Artifacts** (should be in picker):
1. `agents/` - Agent definitions
2. `commands/` - Slash commands
3. `docs/` - Documentation
4. `hooks/` - Event hooks
5. `lib/` - Function libraries
6. `scripts/` - Standalone CLI tools (currently missing from picker)
7. `tests/` - Test suites (currently missing from picker)
8. `tts/` - TTS system files

**Temporary Working Artifacts** (should NOT be in picker):
1. `specs/{topic}/plans/` - Implementation plans (gitignored, temporary)
2. `specs/{topic}/reports/` - Research reports (gitignored, temporary)
3. `specs/{topic}/summaries/` - Implementation summaries (gitignored, temporary)
4. `specs/{topic}/debug/` - Debug reports (committed but topic-specific, not reusable)
5. `specs/{topic}/scripts/` - Investigation scripts (gitignored, temporary)
6. `specs/{topic}/outputs/` - Test outputs (gitignored, temporary)
7. `tmp/` - Temporary files (gitignored, temporary)
8. `archive/` - Archived artifacts (historical, not active)
9. `backups/` - Backup files (recovery only)

### 4. Correct Artifact Count

**Current State**: 11 artifact types (7 visible, 4 sync-only)
**Plan Claims**: Add 5 missing types to reach 16+ types

**Correct Analysis**:
- **Missing permanent artifacts**: scripts/, tests/ (2 types)
- **Incorrectly included**: specs/plans/, specs/reports/, specs/summaries/ (3 types)
- **Correct target**: 13 artifact types (11 current + 2 missing)

### 5. Phase 3 Specific Issues

**From plan lines 379-411 (Phase 3: Add Specs Artifacts)**:

The entire Phase 3 is predicated on adding specs/ artifacts to the picker:
- "Add Plans artifact type to registry" (line 388)
- "Add Reports artifact type to registry" (line 389)
- "Add Summaries artifact type to registry" (line 390)
- "Implement plan metadata extraction (phases, complexity, hours)" (line 392)
- "Implement glob pattern scanning for specs/*/plans/" (line 395)
- "Update Load All to optionally sync specs/standards/" (line 398)

**Problem**: These tasks contradict the purpose of specs/ as temporary working artifacts.

**Exception**: Line 398 mentions "specs/standards/" which IS a permanent artifact (committed to git, contains shared standards). This is already covered in the current picker as a sync-only artifact.

### 6. Load All Artifacts Implication

**From plan lines 238-274 (Enhanced Load All Artifacts)**:

The registry-driven sync would include specs/ artifacts if Phase 3 is implemented:
```lua
for _, artifact_type in pairs(registry.types) do
  if artifact_type.sync_enabled then
    local files = scan_artifact_type(artifact_type)
    sync_plan[artifact_type.id] = files
  end
end
```

**Problem**: Load All would attempt to sync temporary, gitignored, workflow-specific files across the system, which makes no sense for local working artifacts.

### 7. Architecture Goal Misalignment

**Plan states** (line 23): "add full coverage of all .claude/ artifact types"

**Should be**: "add coverage of missing permanent .claude/ artifact types"

The architectural goals (modularization, registry system) are sound, but the scope is incorrect.

## Recommendations

### 1. Remove specs/ Artifacts from Plan Scope

**Delete or mark as excluded**:
- specs/{topic}/plans/
- specs/{topic}/reports/
- specs/{topic}/summaries/
- specs/{topic}/debug/

**Reasoning**: These are temporary working artifacts, not reusable system components.

**Exception**: Keep specs/standards/ (already supported as sync-only artifact).

### 2. Update Artifact Count Goals

**Change from**:
- "Artifact type coverage increased from 11 to 16+ types"
- "Missing 5 artifact types: scripts/, tests/, specs/{topic}/plans/, reports/, summaries/"

**Change to**:
- "Artifact type coverage increased from 11 to 13 types"
- "Missing 2 artifact types: scripts/, tests/"

### 3. Remove or Rewrite Phase 3

**Current Phase 3**: "Add Specs Artifacts" (12 hours, high complexity)

**Options**:
A. **Delete Phase 3 entirely** - Reduces plan from 36 hours to 24 hours
B. **Repurpose Phase 3** - Focus on other improvements (performance, testing, etc.)
C. **Merge Phase 3 into Phase 2** - Combine Scripts and Tests into one phase

**Recommendation**: Option A (delete) or Option C (merge) to maintain clean scope.

### 4. Clarify Permanent vs Temporary Distinction

Add a section to the plan explaining:
- What constitutes a permanent .claude/ artifact (committed, reusable, system-wide)
- What constitutes a temporary working artifact (gitignored, workflow-specific, local)
- Why specs/ artifacts are excluded from picker scope

### 5. Update Success Criteria

**Remove**:
- "Scripts, tests, plans, reports, summaries visible in picker with preview/edit" (line 68)
- "Picker-visible categories increased from 7 to 12+" (line 62)

**Change to**:
- "Scripts and tests visible in picker with preview/edit"
- "Picker-visible categories increased from 7 to 9"

### 6. Preserve specs/standards/ Coverage

**Keep** (line 398): "Update Load All to optionally sync specs/standards/"

This is correct because specs/standards/ contains permanent, committed standards files that should be synchronized.

### 7. Update Phase Dependencies

If Phase 3 is deleted:
- Phase 4 dependencies: `[1, 2]` (remove dependency on Phase 3)
- Phase 5 dependencies: `[1, 2, 4]` (remove dependency on Phase 3)

### 8. Recalculate Complexity Score

**Current**: 142.0 (with Phase 3 included)

**Adjusted** (without Phase 3):
- Remove Phase 3 tasks: -15 tasks = -7.5
- Remove Phase 3 files: -5 files = -15
- **New total**: ~119.5

Still suggests phase expansion may be beneficial, but significantly reduced scope.

## References

### Primary Sources

1. **/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md**
   - Lines 3-33: Overview of topic-based artifact organization
   - Lines 329-335: Core Planning Artifacts lifecycle (gitignored, local)
   - Lines 349-388: Debug Reports (committed exception)
   - Lines 390-407: Investigation Scripts (temporary, gitignored)
   - Lines 449-525: Gitignore Compliance rules and verification

2. **/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md**
   - Lines 6, 20, 41: Incorrect scope statements about specs/ artifacts
   - Lines 61-72: Success criteria including specs/ artifacts
   - Lines 196-235: New Artifact Type Definitions for specs/ artifacts
   - Lines 379-411: Phase 3 tasks for adding specs/ artifacts
   - Lines 695-720: Success validation criteria

3. **/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/001_artifact_management_comprehensive_analysis.md**
   - Lines 1-14: Executive summary listing specs/ as missing coverage
   - Lines 166-177: Gap analysis incorrectly categorizing specs/ as "missing"
   - Lines 184-200: Analysis of specs artifacts as if they were permanent

### .claude/ Directory Structure

4. **/home/benjamin/.config/.claude/** - Verified directory structure
   - Permanent directories: agents/, commands/, docs/, hooks/, lib/, scripts/, tests/, tts/
   - Temporary directories: specs/, tmp/, archive/, backups/
   - specs/859_leaderac_command_nvim_order_check_that_there_full/: Contains plans/ and reports/ (gitignored)
