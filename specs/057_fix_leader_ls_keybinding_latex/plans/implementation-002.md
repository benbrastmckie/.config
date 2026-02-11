# Implementation Plan: Task #57 (Revised)

- **Task**: 57 - Fix leader-ls keybinding not working in LaTeX files
- **Version**: 002
- **Status**: [NOT STARTED]
- **Effort**: 15 minutes
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Previous Plan**: [implementation-001.md](implementation-001.md)
- **Standards**: /home/benjamin/.config/nvim/CLAUDE.md
- **Type**: neovim

## Revision Summary

**User feedback**: "The only change that is needed is to have a good message for when already on the main file. Otherwise it works. No other changes are needed."

**Scope reduction**: The toggle functionality works correctly. Only the "already on main file" scenario needs a notification message.

## Goals & Non-Goals

**Goals**:
- Add a notification message when `<leader>ls` is pressed on the main file

**Non-Goals**:
- Changing any other toggle behavior (it works)
- Adding messages for successful toggles (not needed)
- Error handling for edge cases (not requested)

## Implementation Phases

### Phase 1: Add Main File Notification [NOT STARTED]

**Goal**: Show a helpful message when user presses `<leader>ls` while already on the main file.

**Tasks**:
- [ ] Modify `<leader>ls` mapping in `after/ftplugin/tex.lua` to wrap with a function
- [ ] Check if current file is the main file before toggling
- [ ] If on main file, show notification and skip toggle
- [ ] Otherwise, execute normal VimtexToggleMain

**Timing**: 15 minutes

**Files to modify**:
- `after/ftplugin/tex.lua` - Update line 108

**Implementation Details**:

Replace line 108:
```lua
{ "<leader>ls", "<cmd>VimtexToggleMain<CR>", desc = "subfile toggle", icon = "󰔏", buffer = 0 },
```

With:
```lua
{ "<leader>ls", function()
  local vimtex = vim.b.vimtex
  if vimtex and vim.fn.expand('%:p') == vimtex.tex then
    vim.notify("Already on main file", vim.log.levels.INFO)
  else
    vim.cmd('VimtexToggleMain')
  end
end, desc = "subfile toggle", icon = "󰔏", buffer = 0 },
```

**Verification**:
- [ ] Open LogosReference.tex, press `<leader>ls`, see "Already on main file" message
- [ ] Open a subfile, press `<leader>ls`, toggle works as before (no change needed)

## Testing & Validation

- [ ] Test on `/home/benjamin/Projects/Logos/Theory/latex/LogosReference.tex`
- [ ] Verify notification appears in command line
- [ ] Verify no Lua errors in `:messages`

## Rollback

Revert line 108 to original:
```lua
{ "<leader>ls", "<cmd>VimtexToggleMain<CR>", desc = "subfile toggle", icon = "󰔏", buffer = 0 },
```
