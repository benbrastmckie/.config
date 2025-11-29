# Buffer Pane Targeting Research Report

## Date
2025-11-29

## Research Question
How to ensure workflow artifact buffers open in the correct nvim pane (the main editing area with other buffers) rather than splitting the terminal pane where Claude Code is running?

## Executive Summary

The current `buffer-opener.lua` module uses `vsplit` when opening from a terminal buffer, which creates a new split adjacent to the terminal. This is problematic because the terminal pane should remain dedicated to Claude Code. The solution is to:

1. Find a non-terminal window before opening the buffer
2. Switch to that window first
3. Open the artifact as a new tab in that window

This keeps the Claude Code terminal pane intact and unchanged while opening artifacts in the main editor area.

## Current Implementation Analysis

### Hook Flow (post-buffer-opener.sh)
1. Hook triggers on workflow command completion (Stop event)
2. Extracts completion signal from terminal output (PLAN_CREATED, etc.)
3. Calls buffer-opener module via nvim RPC:
   ```lua
   opener.open_artifact('/path/to/artifact.md')
   ```

### Current buffer-opener.lua Behavior
Located at: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua`

```lua
function M.open_artifact(filepath)
  -- ...validation...

  if is_terminal_buffer() then
    -- In terminal: open in split to preserve terminal
    open_command = M.config.split_direction .. ' ' .. escaped_path  -- vsplit
  else
    -- In normal buffer: replace current buffer
    open_command = 'edit ' .. escaped_path
  end

  vim.cmd(open_command)
end
```

**Problem**: When called from terminal context, `vsplit` creates a new window split adjacent to the terminal. This splits the terminal pane, not the main editor area.

## Proposed Solution

### Strategy: Navigate to Non-Terminal Window First

Before opening the artifact, the buffer-opener should:
1. Find any non-terminal window in the current tab
2. Switch focus to that window
3. Open the artifact as a new tab (`tabedit`)

### Implementation Changes to buffer-opener.lua

```lua
-- Find a non-terminal window to open buffers in
local function find_editor_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
    -- Look for normal buffers (not terminal, not special buffers)
    if buftype == '' or buftype == 'acwrite' then
      return win
    end
  end
  return nil
end

function M.open_artifact(filepath)
  -- ...validation...

  local escaped_path = vim.fn.fnameescape(filepath)

  if is_terminal_buffer() then
    -- When called from terminal context, find editor window first
    local editor_win = find_editor_window()
    if editor_win then
      -- Switch to editor window, then open as new tab
      vim.api.nvim_set_current_win(editor_win)
      vim.cmd('tabedit ' .. escaped_path)
    else
      -- Fallback: create new tab (tab will be in editor area)
      vim.cmd('tabnew ' .. escaped_path)
    end
  else
    -- In normal buffer: open as new tab
    vim.cmd('tabedit ' .. escaped_path)
  end

  -- ...notification...
end
```

### Why `tabedit` Instead of `vsplit`

1. **Tabs preserve pane layout**: Opening a new tab doesn't affect the existing window splits
2. **Terminal pane stays intact**: The Claude Code terminal remains exactly as it was
3. **Natural editor workflow**: Users can cycle through tabs with standard keymaps
4. **No accidental splits**: Won't create tiny splits that fragment the layout

### Alternative Approaches Considered

#### Alternative 1: Use `wincmd` to Navigate
```lua
vim.cmd('wincmd l')  -- Move right
vim.cmd('tabedit ' .. escaped_path)
```
**Rejected**: Fragile - depends on window layout. `wincmd l` might not always go to editor.

#### Alternative 2: Open in Previous Window
```lua
vim.cmd('wincmd p')  -- Go to previous window
vim.cmd('tabedit ' .. escaped_path)
```
**Rejected**: Previous window might still be a terminal or special buffer.

#### Alternative 3: Create Float Window
```lua
vim.api.nvim_open_win(buf, true, float_opts)
```
**Rejected**: Float windows don't integrate with tab bar, feel disconnected.

## Impact on Plan

The existing plan at `/home/benjamin/.config/.claude/specs/954_completion_signals_echo_output/plans/001-completion-signals-echo-output-plan.md` focuses on adding echo statements to workflow commands. This research identifies an **additional requirement**:

**New Phase Required**: Update `buffer-opener.lua` to target the correct window pane.

### Recommended Addition

Add a new phase (Phase 0 or Phase 5) to address this:

```markdown
### Phase 5: Fix Buffer Opener Pane Targeting [NOT STARTED]
dependencies: []

**Objective**: Update buffer-opener.lua to open artifacts in editor tabs, not terminal splits

Tasks:
- [ ] Add find_editor_window() helper function
- [ ] Update open_artifact() to navigate to editor window first
- [ ] Change open command from vsplit to tabedit
- [ ] Test that terminal pane remains unchanged after artifact opens
```

## Verification Steps

1. Start nvim with Claude Code in terminal pane (right side)
2. Run a workflow command (e.g., `/plan "test"`)
3. Verify completion signal appears in terminal
4. Verify artifact opens as new tab in left (editor) area
5. Verify Claude Code terminal pane is unchanged (no splits, no resizing)

## Files Requiring Changes

1. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua` - Main changes
2. `/home/benjamin/.config/.claude/specs/954_completion_signals_echo_output/plans/001-completion-signals-echo-output-plan.md` - Add new phase

## Conclusion

The plan requires revision to include buffer-opener.lua pane targeting fix. The echo signal additions are still needed, but they won't solve the pane targeting issue alone. Both changes are required for the complete solution:

1. **Echo signals** (existing plan) - Make signals visible in terminal output
2. **Pane targeting** (new requirement) - Ensure buffers open in correct location
