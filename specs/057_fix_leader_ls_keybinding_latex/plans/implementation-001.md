# Implementation Plan: Task #57

- **Task**: 57 - Fix leader-ls keybinding not working in LaTeX files
- **Status**: [NOT STARTED]
- **Effort**: 1 hour
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

The `<leader>ls` keybinding IS correctly defined and executes `VimtexToggleMain` successfully. The issue is that when invoked from the main file (LogosReference.tex), there is no visible feedback to indicate whether the toggle succeeded or had no effect. The user expects command-line notification showing success/failure status.

### Research Integration

From research-001.md:
- The mapping exists at `after/ftplugin/tex.lua:108`
- `VimtexToggleMain` is designed for subfile workflows
- When invoked from the main file, there is no toggle to perform and no feedback is provided
- User expectation: visible feedback when the command executes

## Goals & Non-Goals

**Goals**:
- Add visible command-line feedback when `<leader>ls` is pressed
- Show appropriate message for "already on main file" scenario
- Show confirmation message when toggling succeeds on a subfile
- Integrate cleanly with existing tex.lua ftplugin configuration

**Non-Goals**:
- Changing the behavior of VimtexToggleMain itself
- Adding notification plugins or dependencies
- Consolidating which-key.lua and tex.lua keymaps (separate task)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| vim.b.vimtex structure differs | Medium | Low | Test with actual VimTeX data structure, use pcall |
| Message too verbose | Low | Low | Keep messages short (under 50 chars) |
| Silent failure on edge cases | Low | Medium | Wrap in pcall, provide fallback message |

## Implementation Phases

### Phase 1: Add Notification Feedback to VimtexToggleMain [NOT STARTED]

**Goal**: Replace the simple command mapping with a function that provides visible feedback.

**Tasks**:
- [ ] Modify `<leader>ls` mapping in `after/ftplugin/tex.lua` to use a function
- [ ] Capture VimTeX state before toggle (main file path)
- [ ] Execute VimtexToggleMain with pcall for error handling
- [ ] Compare state after toggle to determine what happened
- [ ] Display appropriate notification via vim.notify

**Timing**: 30 minutes

**Files to modify**:
- `after/ftplugin/tex.lua` - Update line 108 to use function instead of `<cmd>VimtexToggleMain<CR>`

**Implementation Details**:

Replace line 108:
```lua
{ "<leader>ls", "<cmd>VimtexToggleMain<CR>", desc = "subfile toggle", icon = "󰔏", buffer = 0 },
```

With:
```lua
{ "<leader>ls", function()
  local vimtex = vim.b.vimtex
  if not vimtex then
    vim.notify("VimTeX not initialized", vim.log.levels.WARN)
    return
  end

  local main_before = vimtex.tex
  local current_file = vim.fn.expand('%:p')

  local ok, err = pcall(vim.cmd, 'VimtexToggleMain')
  if not ok then
    vim.notify("Toggle failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Refresh vimtex state
  vimtex = vim.b.vimtex
  local main_after = vimtex and vimtex.tex or main_before

  if main_before == main_after then
    if current_file == main_before then
      vim.notify("Already on main file", vim.log.levels.INFO)
    else
      vim.notify("No change (check subfiles config)", vim.log.levels.INFO)
    end
  else
    local target = vim.fn.fnamemodify(main_after, ':t')
    vim.notify("Switched to: " .. target, vim.log.levels.INFO)
  end
end, desc = "subfile toggle", icon = "󰔏", buffer = 0 },
```

**Verification**:
- [ ] Open LogosReference.tex (main file), press `<leader>ls`, expect "Already on main file" message
- [ ] Open a subfile, press `<leader>ls`, expect "Switched to: filename.tex" message
- [ ] Press `<leader>ls` again on subfile to toggle back, expect different message

---

### Phase 2: Verification and Testing [NOT STARTED]

**Goal**: Verify the fix works in the user's actual workflow.

**Tasks**:
- [ ] Test with `/home/benjamin/Projects/Logos/Theory/latex/LogosReference.tex`
- [ ] Test with a subfile if available in the project
- [ ] Verify which-key popup still shows the mapping correctly
- [ ] Check no regressions in other LaTeX keymaps

**Timing**: 15 minutes

**Verification**:
- [ ] `nvim --headless -c "e /home/benjamin/Projects/Logos/Theory/latex/LogosReference.tex" -c "lua require('which-key').show('<leader>l')" -c "q"` shows `s` entry
- [ ] Manual test in actual file shows notification

## Testing & Validation

- [ ] Open main LaTeX file, press `<leader>ls` - should show "Already on main file"
- [ ] Verify mapping description unchanged in which-key popup
- [ ] Verify no Lua errors in `:messages` after pressing the keymap
- [ ] Test with VimTeX not yet initialized (edge case)

## Artifacts & Outputs

- `after/ftplugin/tex.lua` - Modified with notification feedback
- `specs/057_fix_leader_ls_keybinding_latex/summaries/implementation-summary-YYYYMMDD.md` - Completion summary

## Rollback/Contingency

If the notification causes issues:
1. Revert line 108 in `after/ftplugin/tex.lua` to original:
   ```lua
   { "<leader>ls", "<cmd>VimtexToggleMain<CR>", desc = "subfile toggle", icon = "󰔏", buffer = 0 },
   ```
2. The original behavior (silent toggle) will be restored
3. Git revert the commit if needed
