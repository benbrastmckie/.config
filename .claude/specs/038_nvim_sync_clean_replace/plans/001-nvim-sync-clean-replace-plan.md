# Implementation Plan: Fix Option 5 (Clean Replace) in Nvim Claude-Code Sync Utility

## Metadata
- **Date**: 2025-12-04
- **Feature**: Enable option 5 (clean replace) to remove all local artifacts and replace with global versions
- **Status**: [COMPLETE]
- **Estimated Hours**: 3-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-nvim-sync-clean-replace-research.md](../reports/001-nvim-sync-clean-replace-research.md)
- **Complexity Score**: 42.5
- **Structure Level**: 0

## Overview

Currently, option 5 ("Clean copy") in the nvim claude-code sync utility is unimplemented and falls back to option 1 behavior. This plan implements the clean replace functionality that removes all local artifact directories and replaces them with fresh copies from the global `~/.config/.claude/` directory, enabling removal of commands/agents that no longer exist in the central configuration.

## Research Summary

From the research report, we identified:
- **Current Behavior**: Option 5 shows a warning and falls back to option 1 (Replace + add new), which preserves all local-only files
- **User Need**: Ability to "reset to global defaults" by removing stale local artifacts that no longer exist in global config
- **Safety Requirement**: Two-step confirmation to prevent accidental data loss
- **Implementation Approach**: Selective clean (remove only artifact directories, preserve specs/, output/, logs/)
- **Existing Infrastructure**: Can reuse existing scanning and copying functions (`scan_directory_for_sync()`, `sync_files()`, `load_all_with_strategy()`)

## Success Criteria
- [ ] Option 5 removes all local artifact directories (commands/, agents/, hooks/, scripts/, tests/, lib/, docs/, skills/, templates/, tts/, etc.)
- [ ] Option 5 copies all global artifacts to local directory successfully
- [ ] Preserved directories (specs/, output/, logs/, tmp/) remain untouched
- [ ] Settings file (settings.local.json) is removed and replaced with global version
- [ ] Two-step confirmation dialog prevents accidental deletion
- [ ] Clear warning messages explain what will be deleted
- [ ] Error handling prevents partial deletion failures
- [ ] Picker refreshes after successful sync
- [ ] Sync report shows accurate file counts

## Technical Design

### Architecture Overview

The clean replace feature extends the existing sync infrastructure with three new components:

```
┌─────────────────────────────────────────────────────────────┐
│           load_all_globally() [Entry Point]                 │
│         Detects conflicts, shows sync options               │
└────────────────────┬────────────────────────────────────────┘
                     │ option 5 selected
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          confirm_clean_replace() [NEW]                      │
│    Two-step confirmation with clear warning messages        │
└────────────────────┬────────────────────────────────────────┘
                     │ confirmed
                     ▼
┌─────────────────────────────────────────────────────────────┐
│         clean_and_replace_all() [NEW]                       │
│   Orchestrates: remove dirs → scan artifacts → sync all     │
└────────────────────┬────────────────────────────────────────┘
                     │
       ┌─────────────┴─────────────┐
       ▼                           ▼
┌─────────────────┐      ┌──────────────────────┐
│  remove_dirs()  │      │  load_all_with_      │
│      [NEW]      │      │    strategy()        │
│  Delete artifact│      │   [EXISTING]         │
│   directories   │      │  Copy all artifacts  │
└─────────────────┘      └──────────────────────┘
```

### Key Functions

#### New Functions

1. **`confirm_clean_replace()`** - Safety confirmation dialog
   - Shows detailed warning about deletion
   - Lists what will be deleted vs preserved
   - Returns boolean (true if confirmed, false if cancelled)

2. **`remove_artifact_directories(project_dir)`** - Directory deletion
   - Removes all artifact directories from list
   - Handles deletion errors gracefully
   - Returns success status and error details

3. **`clean_and_replace_all(project_dir, global_dir)`** - Main orchestration
   - Confirms clean replace with user
   - Calls `remove_artifact_directories()`
   - Scans global artifacts (reuse existing scan functions)
   - Syncs all artifacts with `merge_only=false`
   - Returns total synced count

#### Modified Functions

1. **`load_all_globally()`** (sync.lua:175-393)
   - Update option 5 handler (lines 370-373)
   - Remove fallback warning
   - Call `clean_and_replace_all()` instead

### Directory Classification

**Directories to Remove** (artifact directories):
- commands/
- agents/
- hooks/
- scripts/
- tests/
- lib/
- docs/
- skills/
- templates/
- tts/
- data/commands/
- data/agents/
- data/templates/
- agents/prompts/
- agents/shared/
- specs/standards/
- settings.local.json (file)

**Directories to Preserve** (user work):
- specs/ (user plans and reports)
- output/ (generated artifacts)
- logs/ (command history)
- tmp/ (temporary files)
- CLAUDE.md (project-specific standards)

### Error Handling Strategy

1. **Permission Errors**: Use `pcall` for deletion, report specific failures
2. **Global Directory Missing**: Check existence before deletion
3. **Partial Deletion**: Track which directories deleted successfully, report partial state
4. **Recovery**: No automatic rollback (user confirmation should be sufficient safety)

## Implementation Phases

### Phase 1: Add Confirmation Dialog Function [COMPLETE]
dependencies: []

**Objective**: Create safety confirmation dialog that clearly warns users about data loss

**Complexity**: Low

**Tasks**:
- [x] Add `confirm_clean_replace()` function at top of sync.lua (file: nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua, after line 45)
- [x] Build confirmation message listing directories to delete
- [x] Build confirmation message listing directories to preserve
- [x] Use `vim.fn.confirm()` with "&Yes\n&No" buttons, default to No (option 2)
- [x] Return boolean: true if confirmed, false if cancelled
- [x] Add function documentation comment with @return annotation

**Testing**:
```lua
-- Manual test: Call function and verify dialog appears
local confirmed = confirm_clean_replace()
assert.is_not_nil(confirmed)
```

**Expected Duration**: 30 minutes

### Phase 2: Add Directory Removal Function [COMPLETE]
dependencies: [1]

**Objective**: Safely remove artifact directories with error handling

**Complexity**: Medium

**Tasks**:
- [x] Add `remove_artifact_directories(project_dir)` function after `confirm_clean_replace()` (file: nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua)
- [x] Define artifact_dirs table with all 16 artifact directories
- [x] Loop through artifact_dirs and delete each with `vim.fn.delete(path, "rf")`
- [x] Use `pcall` to catch deletion errors
- [x] Track successful and failed deletions in separate lists
- [x] Remove settings.local.json file separately
- [x] Return success status (boolean) and details (table with success/fail lists)
- [x] Add function documentation with @param and @return annotations

**Testing**:
```bash
# Manual test: Create test project with artifact directories
cd /tmp/test-sync
mkdir -p .claude/{commands,agents,hooks}
echo "test" > .claude/commands/old.md

# Run sync option 5 and verify directories removed
```

**Expected Duration**: 1 hour

### Phase 3: Add Clean and Replace Orchestration Function [COMPLETE]
dependencies: [2]

**Objective**: Orchestrate full clean replace: confirm → remove → scan → sync

**Complexity**: Medium

**Tasks**:
- [x] Add `clean_and_replace_all(project_dir, global_dir)` function after `remove_artifact_directories()` (file: nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua)
- [x] Call `confirm_clean_replace()` and return 0 if cancelled
- [x] Call `remove_artifact_directories(project_dir)` and check for errors
- [x] If removal fails, show error notification and return 0
- [x] Scan all 14 artifact types using existing `scan.scan_directory_for_sync()` calls (reuse code from lines 186-225)
- [x] Call `load_all_with_strategy()` with `merge_only=false` (reuse code from lines 389-392)
- [x] Return total synced count from `load_all_with_strategy()`
- [x] Add function documentation with @param and @return annotations

**Testing**:
```bash
# Integration test: Full clean replace workflow
cd /tmp/test-sync
mkdir -p .claude/commands
echo "old" > .claude/commands/stale.md

# Run option 5, confirm, verify:
# - stale.md removed
# - global artifacts copied
# - sync count accurate
```

**Expected Duration**: 1 hour

### Phase 4: Update Option 5 Handler [COMPLETE]
dependencies: [3]

**Objective**: Replace fallback warning with clean_and_replace_all() call

**Complexity**: Low

**Tasks**:
- [x] Locate option 5 handler in `load_all_globally()` (file: nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua, lines 370-373)
- [x] Remove warning notification line (line 372)
- [x] Remove `merge_only = false` fallback (line 373)
- [x] Replace with: `return clean_and_replace_all(project_dir, global_dir)`
- [x] Verify early return prevents fallthrough to `load_all_with_strategy()` (no double sync)

**Testing**:
```lua
-- Manual test: Select option 5 in picker
:ClaudeCommands
-- Navigate to [Load All Artifacts]
-- Select option 5
-- Verify confirmation dialog appears
-- Verify no fallback warning
```

**Expected Duration**: 15 minutes

### Phase 5: Add Option 5 to No-Conflicts Dialog [COMPLETE]
dependencies: [4]

**Objective**: Allow clean replace even when no conflicts detected

**Complexity**: Low

**Tasks**:
- [x] Locate no-conflicts dialog code (file: nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua, lines 346-352)
- [x] Update buttons to include clean copy option: `"&Add all\n&Clean copy\n&Cancel"`
- [x] Update choice handling to map: 1=Add all, 2=Clean copy, 3=Cancel
- [x] Add `elseif choice == 2` branch to call `clean_and_replace_all(project_dir, global_dir)`
- [x] Update existing choice 1 to call standard sync flow
- [x] Update existing choice 2 (cancel) to choice 3

**Testing**:
```bash
# Test: Sync with no conflicts, verify option 5 available
cd /tmp/clean-project
# No local .claude/ directory yet

# Run sync, verify 3 options shown:
# 1. Add all
# 2. Clean copy
# 3. Cancel
```

**Expected Duration**: 30 minutes

### Phase 6: Testing and Validation [COMPLETE]
dependencies: [5]

**Objective**: Comprehensive testing of all clean replace scenarios

**Complexity**: Medium

**Tasks**:
- [x] Create test project with stale local artifacts (file: /tmp/test-sync-stale/)
- [x] Test option 5 with conflicts: verify confirmation, deletion, sync
- [x] Test option 5 without conflicts: verify dialog appears, clean replace works
- [x] Test cancellation at confirmation: verify no changes made
- [x] Test preserved directories: create specs/test.md, verify untouched after sync
- [x] Test settings.local.json replacement: verify old settings removed
- [x] Test error scenario: make directory read-only, verify graceful error handling
- [x] Test sync report accuracy: verify file counts match actual synced files
- [x] Test picker refresh: verify commands list updates after sync
- [x] Document test results in phase completion notes

**Testing**:
```bash
# Test suite execution
cd /tmp/test-sync-stale
mkdir -p .claude/{commands,agents,specs}
echo "stale" > .claude/commands/old.md
echo "work" > .claude/specs/my-plan.md

# Run option 5, verify:
# - old.md removed
# - specs/my-plan.md preserved
# - all global artifacts copied
# - picker shows updated commands
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Test `confirm_clean_replace()` returns correct boolean based on user input
- Test `remove_artifact_directories()` deletes only specified directories
- Test `clean_and_replace_all()` orchestrates steps correctly

### Integration Testing
- Test full workflow: select option 5 → confirm → verify deletion → verify sync
- Test no-conflicts path: verify option 5 available and works
- Test cancellation: verify no changes made at each cancel point
- Test preserved directories: verify specs/, output/, logs/ untouched

### Error Testing
- Test permission errors: verify graceful failure
- Test missing global directory: verify error notification
- Test partial deletion: verify error reporting

### Test Commands
- Use `:TestFile` to run sync_spec.lua tests (if test file exists)
- Manual testing via `:ClaudeCommands` → `[Load All Artifacts]` → option 5

### Quality Standards
- All new functions must have documentation comments
- Use `pcall` for error-prone operations (file deletion)
- Follow Lua code style: 2-space indent, descriptive names, local functions

## Documentation Requirements

### Code Documentation
- [ ] Add function documentation comments with @param, @return annotations
- [ ] Add inline comments explaining directory classification logic
- [ ] Add inline comments explaining safety confirmation flow
- [ ] Document error handling strategy in code comments

### README Updates
- [ ] Update `nvim/lua/neotex/plugins/ai/claude/commands/README.md` with option 5 documentation
- [ ] Add "Clean Replace" section explaining behavior and use cases
- [ ] Add safety warnings about data loss
- [ ] Include example workflow

### Changelog
- [ ] Add entry documenting option 5 implementation
- [ ] Note breaking changes: none (new feature)

## Dependencies

### External Dependencies
None - uses existing Neovim Lua API and project utilities

### Internal Dependencies
- `scan.scan_directory_for_sync()` - Directory scanning (scan.lua:38-90)
- `sync_files()` - File copying with permissions (sync.lua:49-91)
- `load_all_with_strategy()` - Multi-category orchestration (sync.lua:111-169)
- `helpers.notify()` - User notifications (helpers.lua:109-113)
- `vim.fn.confirm()` - Dialog boxes (Neovim API)
- `vim.fn.delete()` - Directory deletion (Neovim API)

### Prerequisite Knowledge
- Lua pcall error handling pattern
- Neovim vim.fn API
- Existing sync utility architecture

## Risk Management

### High Risk: Accidental Data Loss
**Mitigation**:
- Two-step confirmation (option selection + safety dialog)
- Default choice is "No" in confirmation dialog
- Clear warning messages listing what will be deleted
- Preserve user work directories (specs/, output/, logs/)

### Medium Risk: Partial Deletion Failure
**Mitigation**:
- Track successful/failed deletions separately
- Report partial state to user
- Don't proceed with sync if deletion fails
- Use pcall for each deletion operation

### Low Risk: Performance
**Mitigation**:
- Reuse existing sync infrastructure (already handles 450+ files)
- No additional optimization needed for MVP
- Future enhancement: async deletion with progress indicator

## Rollback Plan

If implementation fails:
1. Remove new functions (confirm_clean_replace, remove_artifact_directories, clean_and_replace_all)
2. Restore original option 5 handler with fallback warning
3. User data is safe (confirmation prevents accidental deletion)
4. Existing sync options (1-2) continue to work

## Completion Checklist

- [ ] All phases completed
- [ ] All tasks checked off
- [ ] All success criteria met
- [ ] Testing strategy executed
- [ ] Documentation updated
- [ ] Code reviewed for standards compliance
- [ ] Error handling tested
- [ ] User confirmation flow tested
- [ ] Preserved directories verified untouched
