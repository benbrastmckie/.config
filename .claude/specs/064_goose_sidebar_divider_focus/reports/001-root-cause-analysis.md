# Root Cause Analysis: Goose Sidebar Horizontal Divider Issue

## Issue Summary

After implementing Phase 1 of the goose sidebar split refactor (enabling `window_type = "split"`), the horizontal divider between the response box (output_win) and input box (input_win) is not visible until the user tabs into the response box, at which point a thick bar appears and persists even after tabbing back to the input box.

## Root Cause

**The issue is caused by conflicting window separator behavior between Neovim's native window system and the lualine plugin's statusline disabling configuration.**

### Technical Analysis

1. **Neovim's Global Statusline Setting**:
   - User has `laststatus = 3` in `nvim/lua/neotex/config/options.lua:30`
   - This enables "global statusline" mode: one status bar at the bottom of the entire editor rather than per-window status lines
   - In this mode, horizontal splits between windows do NOT show the traditional status line separator

2. **Lualine Disabling Goose Filetypes**:
   - In `nvim/lua/neotex/plugins/ui/lualine.lua:36-52`, lualine explicitly disables statusline and winbar for goose buffers:
   ```lua
   disabled_filetypes = {
     statusline = {
       "goose-input",
       "goose-output",
     },
     winbar = {
       "goose-input",
       "goose-output",
     },
   },
   disabled_buftypes = {
     statusline = { "terminal", "nofile" },
     winbar = { "terminal", "nofile" },
   },
   ```

3. **Goose Window Creation**:
   - In `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/ui.lua:68-76`:
   ```lua
   if config.ui.window_type == "split" then
     vim.cmd(split_cmd)  -- Creates vsplit for the sidebar
     output_win = vim.api.nvim_get_current_win()
     vim.cmd("belowright split")  -- Creates horizontal split between output and input
     input_win = vim.api.nvim_get_current_win()
   ```
   - The `belowright split` command creates a native Neovim horizontal window split

4. **The Visibility Issue**:
   - With `laststatus = 3` (global statusline), horizontal splits between windows don't show a status bar separator
   - The separator line between split windows is controlled by `fillchars` option, specifically the `horiz` character
   - Current `fillchars` in `options.lua:40` only sets `eob: ` (end of buffer), not `horiz`
   - The WinSeparator highlight group controls the color of the divider line

5. **Why It Appears When Focused**:
   - When you tab into the output window, the winbar is rendered by `topbar.lua:77-88`:
   ```lua
   function M.render()
     vim.wo[win].winbar = create_winbar_text(...)
     update_winbar_highlights(win)
   end
   ```
   - This creates a winbar on the OUTPUT window (response box), but NOT on the input window
   - The "thick bar" you see when focused is the WINBAR (topbar), not the horizontal window separator
   - The confusion: the winbar appears at the TOP of the output_win when focused, but the expected thin separator should be between output_win and input_win

6. **Missing Element**:
   - Neovim's native horizontal window separator (controlled by `fillchars = "horiz:─"` and `WinSeparator` highlight) is nearly invisible or blending with background
   - The `winhighlight` set in `window_config.lua:21-24` is `'Normal:Normal'` for split mode, which may be causing the WinSeparator to blend with the background

## Code References

| File | Line | Description |
|------|------|-------------|
| `nvim/lua/neotex/config/options.lua` | 30 | `laststatus = 3` enables global statusline |
| `nvim/lua/neotex/config/options.lua` | 40 | `fillchars = "eob: "` only sets end-of-buffer char |
| `nvim/lua/neotex/plugins/ui/lualine.lua` | 36-52 | Disables statusline for goose filetypes |
| `goose.nvim/lua/goose/ui/ui.lua` | 68-76 | Creates split windows with `belowright split` |
| `goose.nvim/lua/goose/ui/window_config.lua` | 19-24 | Sets `winhighlight` to `Normal:Normal` for splits |
| `goose.nvim/lua/goose/ui/topbar.lua` | 77-88 | Renders winbar only on output_win |

## Visual Explanation

```
Expected Layout with Split Mode:
┌────────────────────────────────────────┐
│            Main Editor                 │  <- Vertical separator (visible)
├────────────────────────────────────────┤
│     Goose Output (response box)        │  <- No status bar (laststatus=3)
│     [winbar appears here when focused] │
├────────────────────────────────────────┤  <- MISSING: horizontal separator
│     Goose Input (input box)            │
└────────────────────────────────────────┘

What's Happening:
┌────────────────────────────────────────┐
│            Main Editor                 │
├────────────────────────────────────────┤
│     Goose Output (response box)        │
│                                        │  <- WinSeparator invisible/blending
│     Goose Input (input box)            │
└────────────────────────────────────────┘
```

## Recommended Fixes

### Fix Option 1: Configure WinSeparator Highlight (Minimal Change)

Add WinSeparator highlight configuration to make the native separator visible:

```lua
-- In options.lua or colorscheme configuration
vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#504945', bg = 'NONE' })  -- gruvbox gray
```

### Fix Option 2: Add fillchars for Horizontal Separator

Update `options.lua:40` to include horizontal separator character:

```lua
fillchars = "eob: ,horiz:─,horizup:┴,horizdown:┬,vert:│",
```

### Fix Option 3: Configure Local WinSeparator in Goose Windows

Modify the goose setup_options function to explicitly set WinSeparator highlight for split windows:

```lua
-- In goose init.lua or after setup
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "goose-input", "goose-output" },
  callback = function()
    vim.wo.winhighlight = vim.wo.winhighlight .. ",WinSeparator:Comment"
  end,
})
```

### Fix Option 4: Use Winbar for Input Window (Upstream Change)

Have goose.nvim set a winbar on the input_win as well, creating a consistent visual separator:

```lua
-- In topbar.lua, add winbar to input window
vim.wo[state.windows.input_win].winbar = " Input "
```

## Recommended Approach

**Use Fix Option 1 + Option 2** together for immediate resolution:

1. Update `options.lua` fillchars to include horizontal separator
2. Ensure WinSeparator highlight group has visible foreground color

This maintains consistency with other sidebar plugins (neo-tree, toggleterm) that use native Neovim separators and doesn't require upstream goose.nvim changes.

## Verification Commands

After implementing fix, verify with:

```vim
:echo &fillchars
" Expected: eob: ,horiz:─,horizup:┴,horizdown:┬,vert:│

:hi WinSeparator
" Expected: foreground color should be visible (not NONE or same as bg)

" Open goose and check window config:
:lua print(vim.wo.winhighlight)
" Verify WinSeparator is included
```
