# Cleanup Completed Projects

## Plan Metadata

**Title**: Cleanup Completed Projects
**Status**: [NOT STARTED]
**Created**: 2025-11-29
**Scope**: Archive 99 cleanup-eligible projects (98 Completed, 1 Abandoned)
**Eligible Projects File**: /home/benjamin/.config/.claude/tmp/todo_eligible_1764470780.json

## Objective

Archive all cleanup-eligible projects from the .claude/specs/ directory to create a clean working environment. This cleanup will move 99 completed and abandoned project directories to a timestamped archive, preserving them for future reference while decluttering the active workspace.

## Safety Measures

1. **Git Snapshot**: Pre-cleanup commit creates a recovery point
2. **Archive (Not Delete)**: Projects are moved to archive/, not permanently deleted
3. **Recovery Instructions**: If needed, revert with `git revert HEAD~1`
4. **Uncommitted Changes Check**: Skip any directory with uncommitted git-tracked changes
5. **Verification**: Post-move verification ensures all 99 projects were successfully archived

## Implementation Phases

### Phase 1: Pre-Cleanup Git Commit

**Goal**: Create a recovery point before any deletions

**Tasks**:
1. Run `git add .` to stage all current changes
2. Create commit with message: `chore: pre-cleanup snapshot before /todo --clean`
3. Verify commit was created successfully
4. Log commit hash for reference

**Success Criteria**:
- Git commit created successfully
- Commit hash logged
- No uncommitted changes remain

**CRITICAL**: Do NOT skip this phase. This is the recovery mechanism.

**Estimated Duration**: 1-2 minutes

---

### Phase 2: Git Verification

**Goal**: Ensure clean working tree before proceeding with cleanup

**Tasks**:
1. Run `git status` to verify clean working tree
2. Check for any remaining uncommitted changes after commit
3. Log any warnings if changes remain
4. Exit with error if critical uncommitted changes detected

**Success Criteria**:
- Working tree is clean OR
- Any uncommitted changes are non-critical and logged

**Estimated Duration**: < 1 minute

---

### Phase 3: Archive Creation

**Goal**: Prepare archive directory structure

**Tasks**:
1. Create timestamped archive directory:
   - Path format: `/home/benjamin/.config/.claude/archive/cleaned_$(date +%Y%m%d_%H%M%S)/`
   - Example: `/home/benjamin/.config/.claude/archive/cleaned_20251129_143000/`
2. Create manifest file in archive directory listing all projects to be archived:
   - Manifest path: `<archive_dir>/MANIFEST.txt`
   - Include: topic name, plan title, status, phases complete
3. Log archive directory path for user reference
4. Verify archive directory was created successfully

**Success Criteria**:
- Archive directory created with timestamp
- Manifest file created and populated
- Archive path logged to console

**Estimated Duration**: < 1 minute

---

### Phase 4: Directory Removal

**Goal**: Move all 99 eligible projects to archive

**Tasks**:
1. Read eligible projects from: `/home/benjamin/.config/.claude/tmp/todo_eligible_1764470780.json`
2. For each project directory:
   - Check if directory has uncommitted git-tracked changes (skip if yes)
   - Move directory from `/home/benjamin/.config/.claude/specs/<topic_name>/` to archive using `mv`
   - Log each successful move operation
   - Track any failed moves with error details
3. Generate summary:
   - Total projects to archive: 99
   - Successfully archived: N
   - Skipped (uncommitted changes): N
   - Failed: N

**Safety Notes**:
- Use `mv` command (NOT `rm`) for safety
- Preserve all directory contents and permissions
- Skip any directory with uncommitted changes
- Log all operations for audit trail

**Success Criteria**:
- All eligible projects without uncommitted changes moved to archive
- All move operations logged
- Summary statistics generated

**Estimated Duration**: 2-3 minutes

---

### Phase 5: Verification

**Goal**: Confirm cleanup completed successfully

**Tasks**:
1. Verify archive contains expected number of directories
2. Confirm source specs/ directory no longer contains archived projects
3. Verify manifest matches actual archived directories
4. Update TODO.md to reflect cleanup:
   - Remove archived projects from Completed section
   - Add cleanup summary note
5. Generate final report:
   - Archive location
   - Number of projects archived
   - Recovery instructions
   - Any skipped/failed projects

**Success Criteria**:
- All expected projects present in archive
- Source directory cleaned
- TODO.md updated
- Final report generated

**Recovery Instructions**:
If you need to restore archived projects:
```bash
# Revert the pre-cleanup commit
git revert HEAD~1

# Or manually restore specific projects
mv /home/benjamin/.config/.claude/archive/cleaned_YYYYMMDD_HHMMSS/<topic_name> /home/benjamin/.config/.claude/specs/
```

**Estimated Duration**: 1-2 minutes

---

## Summary

**Total Phases**: 5
**Total Projects to Archive**: 99 (98 Completed, 1 Abandoned)
**Estimated Total Duration**: 5-9 minutes
**Recovery Method**: `git revert HEAD~1` or manual restore from archive

**Project Breakdown**:
- Completed projects: 98
- Abandoned projects: 1
- Total cleanup-eligible: 99

**Archive Location**: `/home/benjamin/.config/.claude/archive/cleaned_$(date +%Y%m%d_%H%M%S)/`

**Dependencies**:
- Git repository must be initialized
- User must have write permissions to .claude/specs/ and .claude/archive/
- jq must be installed for JSON parsing

**Risk Assessment**: LOW
- All changes are reversible via git revert
- Projects archived (not deleted)
- Uncommitted changes preserved (directories skipped)
- Full audit trail maintained
