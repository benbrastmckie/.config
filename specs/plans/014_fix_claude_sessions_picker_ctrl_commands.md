# Fix Claude Sessions Picker Ctrl Commands Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases completed successfully. All ctrl commands in the `<leader>av` picker are now functional.

## Metadata
- **Date**: 2025-09-30
- **Feature**: Fix all ctrl commands in the <leader>av picker (ClaudeSessions)
- **Scope**: Implement missing telescope keymaps for Claude sessions browser
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Reference Commit**: 3c033e1bbdf1

## Overview

The Claude sessions picker (`<leader>av`) displays help text showing keyboard shortcuts (Ctrl-d, Ctrl-t, Ctrl-o, Ctrl-n, Ctrl-x, Ctrl-h) but these mappings are not actually implemented. The function `_setup_telescope_keymaps` in `ui_handlers.lua` only implements the default Enter action and has a comment indicating additional keymaps should be added. This plan implements all the missing control key mappings to match the documented help text.

## Success Criteria
- [x] Ctrl-d deletes selected session
- [x] Ctrl-t opens session in new tab
- [x] Ctrl-o opens worktree in new terminal tab
- [x] Ctrl-n creates new Claude worktree
- [x] Ctrl-x cleanup stale worktrees
- [x] Ctrl-h shows worktree health report
- [x] All mappings work in both insert and normal mode
- [x] Help text remains accurate to implementation

## Technical Design

### Architecture
The implementation follows the pattern established in `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/worktree.lua` which shows proper telescope keymap implementation with both insert and normal mode support.

### Component Interactions
- **ui_handlers.lua**: `_setup_telescope_keymaps` function - main implementation location
- **session.lua**: Provides session deletion functionality
- **terminal_integration.lua**: Provides terminal tab spawning
- **restoration.lua**: Reference for delete confirmation pattern

### Key Implementation Details
1. Each ctrl mapping needs both insert ("i") and normal ("n") mode versions
2. Delete operations should request confirmation before executing
3. Terminal operations should use the terminal_integration module
4. New worktree creation should call existing UI handler function
5. All operations should close the picker before executing (except help)

## Implementation Phases

### Phase 1: Core Control Mappings [COMPLETED]
**Objective**: Implement Ctrl-d, Ctrl-t, and Ctrl-o mappings
**Complexity**: Medium

Tasks:
- [x] Add Ctrl-d (delete session) mapping with confirmation dialog
  - Check if session exists and has worktree
  - Use restoration.lua pattern for confirmation
  - Call session deletion and worktree cleanup
  - Location: nvim/lua/neotex/plugins/ai/claude/core/worktree/ui_handlers.lua:425-467
- [x] Add Ctrl-t (open in new tab) mapping
  - Switch to session's worktree directory
  - Open new Neovim tab
  - Load CLAUDE.md if exists
  - Location: nvim/lua/neotex/plugins/ai/claude/core/worktree/ui_handlers.lua:425-467
- [x] Add Ctrl-o (open in terminal tab) mapping
  - Use terminal_integration.spawn_terminal_tab
  - Pass session worktree path and context
  - Location: nvim/lua/neotex/plugins/ai/claude/core/worktree/ui_handlers.lua:425-467
- [x] Add both insert and normal mode versions for each mapping
- [x] Ensure proper error handling for main branch selections
- [x] Test all three mappings with actual Claude sessions

Testing:
```vim
" Create test session
:ClaudeWorktree
" Test in session picker
<leader>av
" Try Ctrl-d, Ctrl-t, Ctrl-o on various sessions
```

Expected behavior:
- Ctrl-d prompts for confirmation then deletes
- Ctrl-t opens session in new Neovim tab
- Ctrl-o spawns new terminal tab with worktree

### Phase 2: Utility Control Mappings [COMPLETED]
**Objective**: Implement Ctrl-n, Ctrl-x, and Ctrl-h mappings
**Complexity**: Low

Tasks:
- [x] Add Ctrl-n (create new worktree) mapping
  - Close picker
  - Call M.create_worktree_with_claude with existing parameters
  - Location: nvim/lua/neotex/plugins/ai/claude/core/worktree/ui_handlers.lua:425-467
- [x] Add Ctrl-x (cleanup stale worktrees) mapping
  - Close picker
  - Call session_manager.cleanup_sessions
  - Show notification with cleanup results
  - Location: nvim/lua/neotex/plugins/ai/claude/core/worktree/ui_handlers.lua:425-467
- [x] Add Ctrl-h (health report) mapping
  - Generate worktree health statistics
  - Display in floating window or notification
  - Location: nvim/lua/neotex/plugins/ai/claude/core/worktree/ui_handlers.lua:425-467
- [x] Add both insert and normal mode versions for each mapping
- [x] Verify help text matches all implementations
- [x] Final integration testing of all ctrl commands

Testing:
```vim
" Test utility mappings
<leader>av
" Try Ctrl-n (should prompt for new worktree)
" Try Ctrl-x (should cleanup stale sessions)
" Try Ctrl-h (should show health report)
```

Expected behavior:
- Ctrl-n initiates worktree creation flow
- Ctrl-x removes stale/orphaned sessions
- Ctrl-h displays comprehensive health status

## Testing Strategy

### Manual Testing
1. Create multiple Claude sessions via `<leader>aw`
2. Open session picker via `<leader>av`
3. Test each ctrl command in both insert and normal mode
4. Verify operations on main branch are handled correctly
5. Test with help entry selected (should do nothing)

### Edge Cases
- Attempting to delete main branch (should show error)
- Operating on help entry (should be no-op or show message)
- Deleting session while in that session's worktree
- Terminal operations when terminal is not available

### Reference Implementation
Use `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/worktree.lua:324-359` as the reference pattern for implementing telescope mappings.

## Documentation Requirements

No documentation updates needed - the help text in the previewer already documents all functionality correctly (lines 343-361 of ui_handlers.lua).

## Dependencies

### Required Modules
- `telescope.actions` - Already imported
- `telescope.actions.state` - Already imported
- Session manager module (for delete/cleanup operations)
- Terminal integration module (for terminal operations)

### External Dependencies
- git worktree functionality
- Terminal emulator with tab support (WezTerm, Kitty, or Alacritty)

## Notes

### Implementation Pattern
Each mapping should follow this structure:
```lua
map("i", "<C-x>", function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if not selection then return end

  local entry = selection.value

  -- Handle special cases (help, main branch)
  if entry.is_help then return end
  if entry.is_main then
    vim.notify("Operation not supported on main branch", vim.log.levels.WARN)
    return
  end

  actions.close(prompt_bufnr)

  -- Perform operation
  -- ...
end)
map("n", "<C-x>", function(prompt_bufnr) -- Same implementation end)
```

### Session Manager Access
The session manager module is not currently passed to `_setup_telescope_keymaps`. We'll need to either:
1. Add it as a parameter to the function
2. Require it within the function
3. Implement functionality inline using git commands

Option 2 (require within function) is cleanest for this implementation.

### Delete Operation Details
When deleting a session:
1. Confirm with user via `vim.fn.confirm()`
2. Close all buffers from that worktree (see worktree.lua:182-196)
3. Run `git worktree remove <path>`
4. Delete the branch with `git branch -D <branch>`
5. Remove from sessions table
6. Save sessions file
