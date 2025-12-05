# Implementation Plan: Interactive Mode (Option 3) in Nvim Claude-Code Sync Utility

## Metadata
- **Date**: 2025-12-04
- **Feature**: Interactive per-file sync decisions for conflicting artifacts
- **Status**: [COMPLETE]
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: none (codebase exploration conducted inline)
- **Complexity Score**: 65.0
- **Structure Level**: 0

## Overview

Currently, option 3 ("Interactive") in the nvim claude-code sync utility is unimplemented and falls back to option 1 behavior with a warning message. This plan implements an interactive per-file decision mode that allows users to choose how to handle each conflicting file individually, with support for bulk operations ("Apply to all remaining") to speed up the process.

## Research Summary

From codebase exploration:
- **Current Behavior**: Option 3 shows warning and falls back to Replace all (lines 362-365 in sync.lua)
- **File Object Structure**: Files have `{name, global_path, local_path, action, is_subdir}` with `action="replace"` indicating conflicts
- **Conflict Detection**: `scan.scan_directory_for_sync()` returns files with action field
- **UI Patterns**: `vim.ui.select()` used for async selection with callbacks (worktree.lua pattern)
- **Async Safety**: `vim.defer_fn()` and `vim.schedule()` used for event loop coordination
- **Existing Infrastructure**: Can reuse `sync_files()` for final file operations

## Success Criteria

- [ ] Option 3 prompts user for each conflicting file (action="replace")
- [ ] Each prompt shows: "File X of Y: path/to/file.md"
- [ ] User can choose: Keep local, Replace with global, Skip, View diff
- [ ] "Apply to all remaining" shortcuts work (keep all / replace all)
- [ ] User decisions tracked and applied after all prompts complete
- [ ] Non-conflicting files (action="copy") synced automatically without prompts
- [ ] Progress notification shows current file count
- [ ] Cancellation at any point preserves unsynced state
- [ ] View diff option opens side-by-side comparison
- [ ] Integration with existing sync infrastructure (sync_files())

## Technical Design

### Architecture Overview

The interactive mode extends the existing sync flow with a recursive prompting mechanism:

```
┌─────────────────────────────────────────────────────────────┐
│           load_all_globally() [Entry Point]                 │
│         Detects conflicts, shows sync options               │
└────────────────────┬────────────────────────────────────────┘
                     │ option 3 selected
                     ▼
┌─────────────────────────────────────────────────────────────┐
│        run_interactive_sync() [NEW]                         │
│   Separates conflicts from new files, starts prompt loop    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│        prompt_for_conflict() [NEW - Recursive]              │
│   Uses vim.ui.select for async conflict resolution          │
│   Tracks decisions: {file, decision: keep|replace|skip}     │
└────────────────────┬────────────────────────────────────────┘
                     │ all conflicts resolved
                     ▼
┌─────────────────────────────────────────────────────────────┐
│        apply_interactive_decisions() [NEW]                  │
│   Filters files based on decisions, calls sync_files()      │
└─────────────────────────────────────────────────────────────┘
```

### Data Structures

#### Decision State
```lua
--- @class InteractiveState
--- @field conflicts table Array of conflict files (action="replace")
--- @field new_files table Array of new files (action="copy")
--- @field decisions table Map of filepath -> decision
--- @field current_index number Current conflict index (1-based)
--- @field apply_all string|nil "keep" or "replace" if bulk action chosen
--- @field cancelled boolean User cancelled operation
```

#### Decision Values
```lua
-- Valid decisions for each conflict
local DECISION = {
  KEEP = "keep",       -- Keep local version (skip sync)
  REPLACE = "replace", -- Replace with global version
  SKIP = "skip",       -- Decide later (skip in this session)
  DIFF = "diff",       -- View diff (returns to same prompt after)
}
```

### Key Functions

#### New Functions

1. **`run_interactive_sync(all_artifacts, project_dir, global_dir)`**
   - Entry point for interactive mode
   - Separates conflicts (action="replace") from new files (action="copy")
   - Initializes state and starts recursive prompting
   - Returns total synced count

2. **`prompt_for_conflict(state, callback)`**
   - Recursive async function using vim.ui.select
   - Shows "File X of Y: path/to/file.md"
   - Offers choices: Keep local, Replace with global, Skip, View diff
   - Includes "Apply to all remaining" shortcuts
   - Calls callback when all conflicts resolved

3. **`apply_interactive_decisions(state, all_artifacts)`**
   - Builds filtered file list based on decisions
   - New files always included (action="copy")
   - Conflicts included only if decision="replace"
   - Calls sync_files() with filtered list
   - Reports results via helpers.notify()

4. **`show_diff_for_file(file, callback)`**
   - Opens diff view between local and global versions
   - Uses vim.cmd("diffsplit") for side-by-side comparison
   - Calls callback when user closes diff to return to prompt

#### Modified Functions

1. **`load_all_globally()`** (sync.lua:175-393)
   - Update option 3 handler (lines 362-365)
   - Remove fallback warning
   - Call `run_interactive_sync()` with all artifact arrays

### UI Choice Format

```
┌─────────────────────────────────────────────────┐
│  File 3 of 15: commands/implement.md            │
│                                                 │
│  Local differs from global version              │
│                                                 │
│  1. Keep local version                          │
│  2. Replace with global                         │
│  3. Skip (decide later)                         │
│  4. View diff                                   │
│  ─────────────────────────────────              │
│  5. Keep ALL remaining local                    │
│  6. Replace ALL remaining with global           │
│  7. Cancel                                      │
└─────────────────────────────────────────────────┘
```

### Error Handling Strategy

1. **Vim API Errors**: Use `pcall` for file operations and API calls
2. **Callback Failures**: Track state, allow cancellation at any point
3. **Diff View Errors**: Handle missing files gracefully, skip to next prompt
4. **Partial Completion**: Track decisions, user can re-run for skipped files

## Implementation Phases

### Phase 1: Add State and Constants [COMPLETE]
dependencies: []

**Objective**: Define decision constants and state structure for interactive mode

**Complexity**: Low

**Tasks**:
- [x] Add DECISION constants table at top of sync.lua (after line 8)
- [x] Add InteractiveState documentation comment with LuaLS annotations
- [x] Add `create_interactive_state(conflicts, new_files)` helper function
- [x] State includes: conflicts, new_files, decisions, current_index, apply_all, cancelled

**Testing**:
```lua
-- Unit test: State creation
local state = create_interactive_state({conflict1, conflict2}, {new1})
assert.equals(2, #state.conflicts)
assert.equals(1, #state.new_files)
assert.equals(1, state.current_index)
```

**Expected Duration**: 30 minutes

### Phase 2: Add Prompt Function [COMPLETE]
dependencies: [1]

**Objective**: Create recursive async prompt function using vim.ui.select

**Complexity**: High

**Tasks**:
- [x] Add `prompt_for_conflict(state, on_complete)` function after state helpers
- [x] Build prompt title: "File X of Y: relative/path/to/file.md"
- [x] Build choices array with 7 options (keep, replace, skip, diff, keep-all, replace-all, cancel)
- [x] Use `vim.ui.select()` with custom format_item for clear display
- [x] Handle each choice in callback:
  - Keep: Record decision, advance to next conflict
  - Replace: Record decision, advance to next conflict
  - Skip: Record decision, advance to next conflict
  - Diff: Call show_diff_for_file, return to same prompt
  - Keep-all: Set apply_all="keep", complete immediately
  - Replace-all: Set apply_all="replace", complete immediately
  - Cancel: Set cancelled=true, complete immediately
- [x] Use `vim.schedule()` for recursive call to avoid stack overflow
- [x] Call on_complete(state) when all conflicts processed or cancelled

**Testing**:
```lua
-- Integration test: Prompt appears with correct format
-- Manual verification of all 7 choices
```

**Expected Duration**: 2 hours

### Phase 3: Add Diff Viewing Function [COMPLETE]
dependencies: [2]

**Objective**: Display side-by-side diff for local vs global file

**Complexity**: Medium

**Tasks**:
- [x] Add `show_diff_for_file(file, on_close)` function
- [x] Open global file in new vertical split: `vim.cmd("vsplit " .. file.global_path)`
- [x] Open local file and start diff mode: `vim.cmd("diffsplit " .. file.local_path)`
- [x] Set up autocmd to detect when diff windows closed
- [x] Call on_close() callback when both windows closed or user presses q
- [x] Use `pcall` for file operations to handle missing files
- [x] Show notification with instructions: "Press q to return to sync prompt"

**Testing**:
```bash
# Manual test: Trigger diff view for conflicting file
# Verify side-by-side comparison shows
# Verify q closes diff and returns to prompt
```

**Expected Duration**: 1 hour

### Phase 4: Add Decision Application Function [COMPLETE]
dependencies: [3]

**Objective**: Build filtered file list and sync based on user decisions

**Complexity**: Medium

**Tasks**:
- [x] Add `apply_interactive_decisions(state, preserve_perms_map)` function
- [x] Check cancelled flag first, return 0 if cancelled
- [x] Build files_to_sync array:
  - All new_files (action="copy") always included
  - For conflicts: include if decisions[filepath]="replace" or apply_all="replace"
  - Skip if decisions[filepath]="keep" or "skip" or apply_all="keep"
- [x] Call existing `sync_files()` with filtered array
- [x] Build summary notification:
  - "Synced X files (Y new, Z replaced)"
  - "Skipped W files (kept local versions)"
- [x] Return total synced count

**Testing**:
```lua
-- Unit test: Decision application
local state = {
  decisions = {["/path/a.md"] = "replace", ["/path/b.md"] = "keep"},
  apply_all = nil,
  cancelled = false
}
local count = apply_interactive_decisions(state, {})
-- Verify only a.md synced
```

**Expected Duration**: 1 hour

### Phase 5: Add Interactive Sync Entry Point [COMPLETE]
dependencies: [4]

**Objective**: Create main orchestration function for interactive mode

**Complexity**: Medium

**Tasks**:
- [x] Add `run_interactive_sync(all_artifacts, project_dir, global_dir)` function
- [x] Flatten all artifact arrays into single array for conflict detection
- [x] Separate into conflicts (action="replace") and new_files (action="copy")
- [x] If no conflicts, notify and sync all new files directly
- [x] Create state with `create_interactive_state()`
- [x] Build preserve_perms_map for shell scripts
- [x] Call `prompt_for_conflict(state, function(final_state) ... end)`
- [x] In callback: call `apply_interactive_decisions()` and return count
- [x] Handle edge cases: empty conflict list, all cancelled

**Testing**:
```lua
-- Integration test: Full interactive flow
-- Create test directory with conflicts
-- Run interactive sync
-- Make decisions
-- Verify correct files synced
```

**Expected Duration**: 1 hour

### Phase 6: Update Option 3 Handler [COMPLETE]
dependencies: [5]

**Objective**: Connect interactive mode to main sync dialog

**Complexity**: Low

**Tasks**:
- [x] Locate option 3 handler (file: sync.lua, lines 362-365)
- [x] Remove warning notification (line 364)
- [x] Remove `merge_only = false` fallback (line 365)
- [x] Collect all artifact arrays into single table for passing to interactive mode
- [x] Replace with call to `run_interactive_sync()`
- [x] Use `vim.schedule()` to ensure picker closes before prompts appear
- [x] Return synced count from interactive mode

**Testing**:
```lua
-- Manual test: Select option 3 in picker
:ClaudeCommands
-- Navigate to [Load All Artifacts]
-- Select option 3 (Interactive)
-- Verify prompt appears for first conflict
-- Verify no fallback warning
```

**Expected Duration**: 30 minutes

## Testing Strategy

### Unit Testing
- Test `create_interactive_state()` initializes correctly
- Test `apply_interactive_decisions()` filters correctly based on decisions
- Test state transitions for each choice type

### Integration Testing
- Test full interactive workflow with conflicts
- Test "Apply to all remaining" shortcuts complete correctly
- Test diff view opens and closes correctly
- Test cancellation preserves original state
- Test new files sync regardless of conflict decisions

### Edge Case Testing
- Test with 0 conflicts (should skip to sync)
- Test with 0 new files (only conflicts)
- Test cancel on first prompt
- Test diff view with missing file

### Quality Standards
- All new functions must have documentation comments
- Use `vim.ui.select()` for async-safe prompts (not vim.fn.confirm)
- Use `vim.schedule()` for recursive calls
- Follow Lua code style: 2-space indent, descriptive names, local functions

## Documentation Requirements

### Code Documentation
- [ ] Add function documentation comments with @param, @return annotations
- [ ] Add inline comments explaining async flow
- [ ] Document state machine transitions
- [ ] Add LuaLS type annotations for state objects

### README Updates
- [ ] Update `nvim/lua/neotex/plugins/ai/claude/commands/README.md` with option 3 documentation
- [ ] Add "Interactive Mode" section explaining behavior
- [ ] Document keyboard shortcuts in diff view
- [ ] Include example workflow

### Help Text Updates
- [ ] Update previewer.lua help text (preview_help function, ~line 120)
- [ ] Add Interactive mode documentation to [Keyboard Shortcuts] section

## Dependencies

### External Dependencies
None - uses existing Neovim Lua API

### Internal Dependencies
- `scan.scan_directory_for_sync()` - Directory scanning (scan.lua:38-90)
- `sync_files()` - File copying with permissions (sync.lua:49-91)
- `helpers.notify()` - User notifications (helpers.lua:109-113)
- `vim.ui.select()` - Async selection dialog (Neovim API)
- `vim.cmd("diffsplit")` - Diff view (Neovim API)

### Prerequisite Knowledge
- Lua callback patterns
- Neovim async/event loop model
- vim.ui.select() API

## Risk Management

### High Risk: Event Loop Blocking
**Mitigation**:
- Use `vim.ui.select()` instead of `vim.fn.confirm()` for non-blocking prompts
- Use `vim.schedule()` for recursive calls
- Test with fast repeated selections

### Medium Risk: State Corruption
**Mitigation**:
- Immutable state updates
- Defensive checks before accessing state fields
- Clear state initialization

### Low Risk: User Confusion
**Mitigation**:
- Clear prompt text showing file count and path
- Consistent choice ordering
- "Apply to all" clearly marked as bulk action

## Rollback Plan

If implementation fails:
1. Remove new functions (create_interactive_state, prompt_for_conflict, show_diff_for_file, apply_interactive_decisions, run_interactive_sync)
2. Restore original option 3 handler with fallback warning
3. Existing sync options (1-2) continue to work
4. No data loss risk (prompts don't modify files until final sync)

## Critical Files

1. **sync.lua** (`nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`) - Core implementation file, option 3 handler at lines 362-365
2. **scan.lua** (`nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua`) - File object structure reference (lines 38-90)
3. **helpers.lua** (`nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/helpers.lua`) - Utility functions for notifications and file operations
4. **previewer.lua** (`nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua`) - Help section to update (line 120)
5. **worktree.lua** (`nvim/lua/neotex/plugins/ai/claude/core/worktree.lua`) - Reference for vim.ui.select() patterns

## Completion Checklist

- [ ] All phases completed
- [ ] All tasks checked off
- [ ] All success criteria met
- [ ] Testing strategy executed
- [ ] Documentation updated
- [ ] Code reviewed for standards compliance
- [ ] Error handling tested
- [ ] Async flow tested for race conditions
- [ ] Apply-all shortcuts tested
