# Enhanced Conflict Resolution Options - Revision Research

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Enhanced Conflict Resolution options for picker Load All Artifacts
- **Report Type**: plan revision insights
- **Workflow**: research-and-revise
- **Existing Plan**: /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md

## Executive Summary

Research findings for revising Enhanced Conflict Resolution options in the Claude artifacts picker refactor plan. The user requests two specific changes: (1) change Option 1 to read "Replace existing + add new" instead of "Replace all + add new", and (2) add Option 5 as "Clean copy" which completely replaces all artifacts, including removing artifacts that only exist in the local project. This research analyzes the current conflict resolution design, validates the terminology changes, and provides detailed specifications for the new "Clean copy" option.

## Findings

### Finding 1: Current Conflict Resolution Implementation

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:1746-1807`

The current `load_all_globally()` function implements a two-option conflict resolution strategy:

**When conflicts exist** (lines 1749-1763):
- **Option 1**: "Replace all + add new" - Replaces all conflicting files and adds new ones
- **Option 2**: "Add new only" - Skips conflicting files, only copies new ones
- **Option 3**: "Cancel" - Aborts the operation

**When no conflicts exist** (lines 1766-1779):
- **Option 1**: "Add all" - Copies all new artifacts
- **Option 2**: "Cancel" - Aborts the operation

**Key Implementation Details**:
- Uses `vim.fn.confirm()` for blocking dialog (line 1781)
- Action tracking via `file.action` field: "copy" (new) or "replace" (conflict)
- Action counting functions track copy vs replace operations (lines 1678-1701)
- Strategy controlled by `merge_only` boolean flag (line 1747)
  - `merge_only = false`: Replace all + add new
  - `merge_only = true`: Add new only

### Finding 2: File Sync Mechanism

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:772-814`

The `sync_files()` function implements the actual file synchronization:

**Parameters** (line 772):
- `files`: Array of file objects with `global_path`, `local_path`, `name`, `action` fields
- `preserve_perms`: Boolean flag to preserve executable permissions (for `.sh` files)
- `merge_only`: Boolean flag to skip "replace" actions

**Behavior** (lines 777-810):
- When `merge_only = true`: Skips files where `file.action == "replace"` (line 779)
- When `merge_only = false`: Processes all files (both "copy" and "replace" actions)
- Reads from global path, writes to local path
- Preserves permissions for shell scripts (`.sh` files) when `preserve_perms = true`
- Reports errors for failed reads or writes

**Current Limitation**: The sync operation **never deletes local-only artifacts**. Files that exist locally but not in the global directory are always preserved (documented at lines 937, 1035, 1509, 1731).

### Finding 3: Terminology Analysis - "Replace All" vs "Replace Existing"

**User Request**: Change Option 1 from "Replace all + add new" to "Replace existing + add new"

**Semantic Analysis**:
- **"Replace all"** (current): Implies replacing everything, potentially including deletion
- **"Replace existing"** (proposed): Clearer - only replaces files that exist in both locations
- **Actual behavior**: The implementation replaces only conflicting files (those in both locations), never deletes local-only files

**Conclusion**: "Replace existing + add new" is more accurate terminology because:
1. It matches the actual implementation behavior (replaces conflicts, preserves local-only)
2. It reduces user confusion about whether "all" means "delete everything"
3. It clearly communicates the two-part operation: replace conflicts + add new files

### Finding 4: Local-Only Artifact Preservation

**Current Behavior** (documented throughout picker.lua):
- Line 937: "name while preserving local-only artifacts."
- Line 1035: "Note: Local-only artifacts will not be affected."
- Line 1509: "with global versions. Preserves local-only artifacts without global equivalents."
- Line 1731: "Local-only artifacts will not be affected."

**Key Insight**: The current implementation **always** preserves local-only artifacts, regardless of which option is chosen. This is the intended behavior to prevent accidental data loss.

### Finding 5: "Clean Copy" Option Requirements

**User Request**: Add Option 5 as "Clean copy" which completely replaces all artifacts, including removing artifacts that only exist in the local project.

**Specification Analysis**:

**Destructive Operation Characteristics**:
- **Scope**: Deletes all local `.claude/` artifacts not present in global directory
- **Risk Level**: HIGH - permanent data loss if user has local-only customizations
- **Use Case**: Fresh sync when local directory is corrupted or needs complete reset

**Implementation Requirements**:
1. **Pre-deletion scan**: Identify local-only artifacts before deletion
2. **Confirmation dialog**: Show user exactly what will be deleted
3. **Safety confirmation**: Require explicit "Yes, delete local-only files" confirmation
4. **Backup recommendation**: Suggest creating backup before proceeding
5. **Atomic operation**: Either complete sync or rollback (no partial state)
6. **Deletion logic**: Remove local files not in global scan results
7. **Directory cleanup**: Remove empty directories after file deletion

**Recommended Implementation Approach**:

```lua
-- Pseudo-code for clean copy option
function clean_copy_sync()
  -- Step 1: Scan local directory for all artifacts
  local local_artifacts = scan_local_claude_directory()

  -- Step 2: Scan global directory for all artifacts
  local global_artifacts = scan_global_claude_directory()

  -- Step 3: Identify files to delete (local-only)
  local to_delete = {}
  for _, local_file in ipairs(local_artifacts) do
    if not exists_in_global(local_file, global_artifacts) then
      table.insert(to_delete, local_file)
    end
  end

  -- Step 4: Show deletion preview
  if #to_delete > 0 then
    local confirmation = show_deletion_preview(to_delete)
    if not confirmation then
      return -- User cancelled
    end
  end

  -- Step 5: Delete local-only files
  for _, file in ipairs(to_delete) do
    delete_file(file)
  end

  -- Step 6: Sync all global artifacts (replace all)
  sync_all_global_artifacts(merge_only = false)

  -- Step 7: Cleanup empty directories
  cleanup_empty_directories()
end
```

**Safety Mechanisms**:
- Two-step confirmation: (1) Choose "Clean copy", (2) Confirm deletion list
- Preview shows exact files to be deleted with full paths
- Option to cancel at any point before deletion begins
- Backup suggestion in dialog: "Consider backing up .claude/ directory first"

### Finding 6: Plan Update Requirements

**Current Plan Section** (lines 230-234 in plan):
```
Enhanced Conflict Resolution:
- Option 1: Replace all + add new (replaces existing, adds new)
- Option 2: Add new only (skip existing files)
- Option 3: Interactive per-file (prompt for each conflict)
- Option 4: Preview diff (show changes before applying)
```

**Requested Changes**:
1. **Option 1 text change**: "Replace all + add new" → "Replace existing + add new"
2. **Add Option 5**: "Clean copy" with full description

**Revised Section**:
```
Enhanced Conflict Resolution:
- Option 1: Replace existing + add new (replaces conflicts, adds new, preserves local-only)
- Option 2: Add new only (skip existing files)
- Option 3: Interactive per-file (prompt for each conflict)
- Option 4: Preview diff (show changes before applying)
- Option 5: Clean copy (delete local-only artifacts, replace all with global versions)
```

### Finding 7: Related Plan Sections Requiring Updates

**Phase 3 Tasks** (lines 353-359 in plan):
Currently mentions "Add interactive conflict resolution UI" but doesn't specify all 5 options.

**Recommended Task Updates**:
- [ ] Implement Option 1: Replace existing + add new (rename from "Replace all")
- [ ] Implement Option 2: Add new only (existing)
- [ ] Implement Option 3: Interactive per-file conflict resolution
- [ ] Implement Option 4: Preview diff before applying changes
- [ ] Implement Option 5: Clean copy with local-only deletion
- [ ] Add deletion preview UI for Option 5
- [ ] Add safety confirmation for Option 5
- [ ] Add backup recommendation dialog for Option 5

**Testing Requirements** (lines 373-377 in plan):
Should include tests for all 5 options:
```bash
# Verify Option 1: Replace existing + add new
# Verify Option 2: Add new only
# Verify Option 3: Interactive conflict resolution
# Verify Option 4: Preview diff accurate
# Verify Option 5: Clean copy deletes local-only files correctly
# Verify Option 5: Safety confirmations work
```

## Recommendations

### Recommendation 1: Approve Option 1 Terminology Change

**Change**: "Replace all + add new" → "Replace existing + add new"

**Rationale**:
1. More accurate description of actual behavior
2. Reduces user confusion about scope of "all"
3. Explicitly communicates preservation of local-only artifacts
4. Aligns with industry-standard terminology (git, rsync use "existing" for conflict resolution)

**Implementation Impact**: Low
- Update dialog message text (line 1759)
- Update button label (line 1759)
- Update documentation in README
- No code logic changes required

**Approval**: RECOMMENDED

### Recommendation 2: Implement Option 5 "Clean Copy" with Enhanced Safety

**Implementation Priority**: Medium (after Options 3 and 4)

**Safety Requirements** (CRITICAL):
1. **Two-stage confirmation**:
   - Stage 1: User selects "Clean copy" option
   - Stage 2: Preview deletion list with explicit "Yes, delete these N files" confirmation
2. **Deletion preview must show**:
   - Full list of local-only files to be deleted
   - Total count and size of deletions
   - Clear warning: "This action cannot be undone"
   - Backup recommendation: "Consider backing up .claude/ directory first"
3. **Confirmation dialog wording**:
   - Must include "DELETE" or "REMOVE" in button text (not just "OK")
   - Default selection: "Cancel" (not "Confirm")
   - Require explicit click on deletion confirmation

**Implementation Phases**:
1. Phase 3, Task 1: Implement local-only artifact identification
2. Phase 3, Task 2: Implement deletion preview UI
3. Phase 3, Task 3: Implement safety confirmation dialog
4. Phase 3, Task 4: Implement clean copy sync logic
5. Phase 3, Task 5: Add comprehensive tests for clean copy
6. Phase 3, Task 6: Add error handling and rollback capability

**Code Placement**:
- New function: `clean_copy_sync()` in `picker/operations/sync.lua`
- Helper functions in `picker/utils/scan.lua`:
  - `scan_local_claude_directory()`
  - `identify_local_only_artifacts(local_files, global_files)`
  - `cleanup_empty_directories()`

**Approval**: RECOMMENDED with safety requirements

### Recommendation 3: Update Enhanced Conflict Resolution Documentation

**Plan Section Update** (line 230):

**Current**:
```
Enhanced Conflict Resolution:
- Option 1: Replace all + add new (replaces existing, adds new)
- Option 2: Add new only (skip existing files)
- Option 3: Interactive per-file (prompt for each conflict)
- Option 4: Preview diff (show changes before applying)
```

**Proposed**:
```
Enhanced Conflict Resolution:
- Option 1: Replace existing + add new (replaces conflicts, adds new, preserves local-only)
- Option 2: Add new only (skip conflicts, only add new files)
- Option 3: Interactive per-file (prompt for each conflict individually)
- Option 4: Preview diff (show changes before applying)
- Option 5: Clean copy (DELETE local-only artifacts, replace all with global)

Note: Options 1-4 preserve local-only artifacts. Option 5 is destructive and requires confirmation.
```

**Rationale**:
1. Clarifies preservation behavior for Options 1-4
2. Highlights destructive nature of Option 5 with "DELETE" emphasis
3. Adds explanatory note about safety differences
4. Improves user understanding of each option's scope

**Approval**: RECOMMENDED

### Recommendation 4: Add Safety Documentation to User Guide

**Create**: `picker/USER_GUIDE.md` section on "Conflict Resolution Safety"

**Content**:
```markdown
## Conflict Resolution Options

### Safe Options (Preserve Local-Only Artifacts)
Options 1-4 never delete local-only artifacts:

**Option 1: Replace existing + add new**
- Replaces files that exist in both global and local
- Adds new files from global
- Preserves local-only files (not in global)
- Use when: You want latest global versions but keep local customizations

**Option 2: Add new only**
- Skips files that exist locally
- Adds new files from global
- Preserves all local files
- Use when: You want to keep all local changes

**Option 3: Interactive per-file**
- Prompts for each conflict individually
- Full control over each file decision
- Use when: You want to review each conflict

**Option 4: Preview diff**
- Shows changes before applying
- Review mode before committing
- Use when: You want to see exactly what will change

### Destructive Option (Deletes Local-Only Artifacts)
**Option 5: Clean copy** [DANGER]
- DELETES all local-only artifacts
- Replaces all files with global versions
- Requires explicit confirmation
- Use when: Local directory is corrupted or needs complete reset
- BACKUP your .claude/ directory first!
```

**Approval**: RECOMMENDED

### Recommendation 5: Implement Comprehensive Test Coverage for Option 5

**Test Requirements**:

**Unit Tests**:
1. `test_identify_local_only_artifacts()` - Verify correct identification
2. `test_deletion_preview_generation()` - Verify preview accuracy
3. `test_file_deletion()` - Verify files deleted correctly
4. `test_directory_cleanup()` - Verify empty dirs removed
5. `test_clean_copy_rollback()` - Verify rollback on error

**Integration Tests**:
1. `test_clean_copy_full_workflow()` - End-to-end test
2. `test_clean_copy_cancellation()` - Verify cancel works at each stage
3. `test_clean_copy_with_errors()` - Verify error handling
4. `test_clean_copy_permissions()` - Verify permissions preserved

**Safety Tests**:
1. `test_clean_copy_requires_confirmation()` - Cannot bypass confirmation
2. `test_clean_copy_default_cancel()` - Default is cancel, not delete
3. `test_clean_copy_preview_accuracy()` - Preview matches actual deletions

**Coverage Target**: 95%+ for Option 5 (higher than standard 80% due to destructive nature)

**Approval**: REQUIRED before merging Option 5

## References

### Source Files Analyzed

1. **Picker Implementation**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
   - Lines 772-814: `sync_files()` function (file synchronization logic)
   - Lines 1566-1808: `load_all_globally()` function (conflict resolution UI)
   - Lines 1746-1763: Conflict dialog with current Options 1-2
   - Lines 1678-1701: Action counting (copy vs replace tracking)
   - Lines 937, 1035, 1509, 1731: Local-only artifact preservation documentation

2. **Existing Plan**: `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md`
   - Lines 230-234: Current Enhanced Conflict Resolution section
   - Lines 353-359: Phase 3 conflict resolution tasks
   - Lines 373-377: Testing requirements for conflict resolution

3. **Research Report**: `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/001_artifact_management_comprehensive_analysis.md`
   - Lines 630-636: Original Enhanced Conflict Resolution proposal
   - Lines 39, 606: Current limitations analysis
   - Lines 754, 761, 766: Enhancement recommendations

### Related Standards and Patterns

1. **Git Conflict Resolution**: Standard terminology uses "existing" (git merge, git rebase)
2. **Rsync Behavior**: Uses `--delete` flag for clean copy semantics
3. **File Sync Best Practices**: Two-stage confirmation for destructive operations
4. **UI/UX Patterns**: Default to safe option (Cancel), require explicit confirmation for deletion

### Implementation Examples

**Rsync Clean Copy Pattern**:
```bash
rsync -av --delete source/ destination/
# --delete removes files in destination not in source
# Equivalent to proposed Option 5
```

**Git Merge Conflict Resolution**:
```bash
git merge --strategy-option theirs  # Replace existing (Option 1)
git merge --no-commit               # Interactive (Option 3)
git diff HEAD...MERGE_HEAD          # Preview diff (Option 4)
```

### Safety Standards Referenced

1. **Nvim CLAUDE.md**: Character encoding standards (no emojis in file content)
2. **Code Standards**: Error handling with `pcall` for file operations
3. **Testing Standards**: 80%+ coverage requirement (95% for destructive operations)
4. **Documentation Standards**: Clear warnings for destructive operations
