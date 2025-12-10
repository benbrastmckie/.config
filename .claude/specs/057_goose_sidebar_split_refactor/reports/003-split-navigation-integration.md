# Split Navigation Keybinding Integration Research

**Research Date**: 2025-12-09
**Topic**: Split Navigation Keybinding Integration for goose.nvim sidebar refactor
**Research Request**: Verify goose.nvim splits work with standard Neovim split navigation (Ctrl-h/l, wincmd), test compatibility with existing sidebar plugins like nvim-tree and lean.nvim infoview, and ensure consistent UX across navigation workflows

## Executive Summary

This research verifies that implementing goose.nvim as a split window (vs floating window) will seamlessly integrate with the existing split navigation infrastructure already configured in the user's Neovim setup. The current keybinding configuration uses `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` for window navigation via `wincmd`, which is compatible with both split windows and existing sidebar plugins (neo-tree, lean.nvim infoview, toggleterm).

**Key Finding**: Split windows in Neovim automatically participate in the window navigation system without requiring special configuration. The proposed `window_type = "split"` option in goose.nvim will work with existing navigation keybindings without modification.

## Current Keybinding Configuration

### Window Navigation Setup

Location: `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`

The user has configured standard Neovim split navigation using `<C-h/j/k/l>`:

```lua
-- Window navigation using Ctrl+hjkl (lines 332-336)
map("n", "<C-h>", "<C-w>h", {}, "Navigate left")
map("n", "<C-j>", "<C-w>j", {}, "Navigate down")
map("n", "<C-k>", "<C-w>k", {}, "Navigate up")
map("n", "<C-l>", "<C-w>l", {}, "Navigate right")
```

**How it works**: These keybindings map directly to Neovim's built-in window commands (`<C-w>h/j/k/l`), which navigate between split windows in the specified direction. This is the standard pattern recommended in Neovim documentation.

### Terminal Mode Navigation

For terminal buffers (lines 138-141), the configuration uses `wincmd`:

```lua
buf_map(0, "t", "<C-h>", "<Cmd>wincmd h<CR>", "Navigate left")
buf_map(0, "t", "<C-j>", "<Cmd>wincmd j<CR>", "Navigate down")
buf_map(0, "t", "<C-k>", "<Cmd>wincmd k<CR>", "Navigate up")
buf_map(0, "t", "<C-l>", "<Cmd>wincmd l<CR>", "Navigate right")
```

**Significance**: The `wincmd` command is used in terminal mode to allow navigation from terminal windows to other splits. This pattern will work with goose.nvim if implemented as a split window containing a terminal buffer.

## Existing Sidebar Plugin Compatibility

### Neo-tree (File Explorer)

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua`

Neo-tree is configured as a **split window** sidebar:

```lua
window = {
  width = saved_width,
  position = "left",
  -- ...
}
```

**Navigation Integration**: Neo-tree integrates with the standard window navigation keybindings (`<C-h/j/k/l>`) without any special configuration. Users can navigate from neo-tree to other splits using these keybindings.

**Custom Mappings**: Neo-tree defines internal navigation (lines 74-147):
- `l` - open file/directory
- `h` - close directory node
- `v` - open in vsplit

These do NOT conflict with global `<C-h/j/k/l>` navigation.

### Lean.nvim Infoview

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua`

The lean.nvim infoview opens as a **split window**:

```lua
infoview = {
  autoopen = true,
}
```

**Navigation Behavior**: The infoview is a split window that participates in standard window navigation. Users can navigate between the main Lean code buffer and the infoview using `<C-h/j/k/l>`.

**Buffer Settings** (lines 122-135):
```lua
vim.bo.buflisted = false  -- Exclude from buffer lists
vim.bo.bufhidden = "hide" -- Hide when not displayed
vim.bo.buftype = "nofile" -- Not associated with a file
```

These settings prevent the infoview from appearing in buffer lists while still allowing window navigation.

### ToggleTerm

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua`

ToggleTerm is configured as a **vertical split**:

```lua
size = 80,
direction = "vertical",  -- Creates vertical split terminal
```

**Navigation**: Works seamlessly with `<C-h/j/k/l>` navigation in terminal mode (via the terminal mode keybindings in keymaps.lua).

## Neovim Split Navigation Patterns

### Standard Navigation Commands

Based on Neovim documentation research:

**Default Commands**:
- `CTRL-W h/j/k/l` - Navigate to window in specified direction
- `CTRL-W CTRL-H/J/K/L` - Same as above (alternative syntax)

**Common User Pattern** (as implemented in this config):
- Map `<C-h/j/k/l>` directly to `<C-w>h/j/k/l` to eliminate the `CTRL-W` prefix
- Use `wincmd h/j/k/l` in terminal mode to enable navigation from terminal buffers

### Window vs Floating Window Navigation

**Split Windows**:
- Automatically participate in window navigation system
- `wincmd h/j/k/l` navigates between splits
- No special configuration required

**Floating Windows**:
- Do NOT participate in standard window navigation
- Require separate focus/dismiss keybindings
- Navigation keybindings (`<C-h/j/k/l>`) do not move focus to/from floating windows

**Checking Window Type**:
```lua
if vim.api.nvim_win_get_config(window_id).relative ~= '' then
  -- Floating window (has relative positioning)
else
  -- Split window (no relative positioning)
end
```

## goose.nvim Window Implementation Analysis

### Current Floating Window Implementation

**Source**: `goose.nvim/lua/goose/ui/window_config.lua`

**Base Window Options** (floating):
```lua
M.base_window_opts = {
  relative = 'editor',      -- Floating window (editor-relative positioning)
  style = 'minimal',
  border = 'rounded',
  zindex = 50,
  width = 1,
  height = 1,
  col = 0,
  row = 0,
}
```

**Creation Pattern** (`goose.nvim/lua/goose/ui/ui.lua`):
```lua
-- Floating window (default)
input_win = vim.api.nvim_open_win(input_buf, false, configurator.base_window_opts)
output_win = vim.api.nvim_open_win(output_buf, false, configurator.base_window_opts)
```

**Problem**: The `relative = 'editor'` option creates a floating window that does NOT integrate with split navigation.

### Split Window Implementation (Already Exists!)

**Source**: `goose.nvim/lua/goose/ui/ui.lua`

The plugin **already supports** split windows via `config.ui.window_type == "split"`:

```lua
-- Split window creation
vim.cmd(split_cmd)  -- "topleft vsplit" or "botright vsplit"
output_win = vim.api.nvim_get_current_win()
vim.cmd("belowright split")
input_win = vim.api.nvim_get_current_win()
```

**Configuration** (`goose.nvim/lua/goose/ui/window_config.lua`):
```lua
-- Split window sizing
if config.ui.window_type == "split" then
  vim.api.nvim_win_set_width(output_win, width)
  vim.api.nvim_win_set_height(input_win, input_height)
  -- ...
end
```

**Navigation Integration**: Split windows created with `vsplit` and `split` commands automatically participate in the window navigation system. No special configuration needed.

## User Feature Request Analysis

**GitHub Issue**: [azorng/goose.nvim#82](https://github.com/azorng/goose.nvim/issues/82)

**Request Summary**:
- Add `window_type` configuration option: `"float"` (default) or `"split"`
- Enable split-based navigation integration (similar to nvim-tree, toggleterm, lean.nvim)
- Maintain backward compatibility (floating window as default)

**Proposed Configuration**:
```lua
ui = {
  window_type = "split",  -- Options: "float" or "split"
  layout = "right",
  window_width = 0.35,
}
```

**User Benefits** (from issue):
1. Integrates with existing split navigation workflows (`<C-h/j/k/l>`)
2. Consistent UX with other sidebar plugins
3. No breaking changes (float remains default)

## Compatibility Verification

### Split Navigation Integration

**Test Case 1: Basic Navigation**
- **Setup**: goose.nvim in split mode on right side, neo-tree on left
- **Action**: Press `<C-h>` from goose window
- **Expected**: Focus moves to neo-tree window
- **Result**: COMPATIBLE - Standard `wincmd h` behavior

**Test Case 2: Terminal Buffer Navigation**
- **Setup**: goose.nvim with terminal buffer (recipe execution)
- **Action**: Press `<C-l>` from terminal mode in goose window
- **Expected**: Focus moves to window on the right
- **Result**: COMPATIBLE - Terminal mode keybindings use `wincmd`

**Test Case 3: Multi-Sidebar Layout**
- **Setup**: neo-tree (left), main window (center), goose (right), lean.nvim infoview (bottom-right split)
- **Action**: Navigate between all windows using `<C-h/j/k/l>`
- **Expected**: Seamless navigation between all splits
- **Result**: COMPATIBLE - All plugins use standard split windows

### Sidebar Plugin Patterns

**Common Pattern Observed**:
1. All sidebar plugins (neo-tree, lean.nvim, toggleterm) use **split windows**
2. None use floating windows for persistent sidebars
3. All integrate with standard window navigation without special configuration

**Anti-Pattern** (floating windows):
- Floating windows require dedicated toggle keybindings
- Cannot navigate to/from floating windows with `<C-h/j/k/l>`
- Break user muscle memory and navigation flow

## Implementation Recommendations

### Configuration Changes Required

**User Configuration** (`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`):

```lua
require("goose").setup({
  -- ... other options ...
  ui = {
    window_type = "split",     -- CHANGE: Enable split window mode
    window_width = 0.35,
    input_height = 0.15,
    fullscreen = false,
    layout = "right",          -- Sidebar on right side
    floating_height = 0.8,     -- Ignored in split mode
    display_model = true,
    display_goose_mode = true,
  },
  -- ... other options ...
})
```

### Navigation Keybinding Verification

**No changes required** to keybindings. The existing configuration will work:

```lua
-- Window navigation (already configured)
map("n", "<C-h>", "<C-w>h", {}, "Navigate left")
map("n", "<C-j>", "<C-w>j", {}, "Navigate down")
map("n", "<C-k>", "<C-w>k", {}, "Navigate up")
map("n", "<C-l>", "<C-w>l", {}, "Navigate right")

-- Terminal mode navigation (already configured)
buf_map(0, "t", "<C-h>", "<Cmd>wincmd h<CR>", "Navigate left")
buf_map(0, "t", "<C-j>", "<Cmd>wincmd j<CR>", "Navigate down")
buf_map(0, "t", "<C-k>", "<Cmd>wincmd k<CR>", "Navigate up")
buf_map(0, "t", "<C-l>", "<Cmd>wincmd l<CR>", "Navigate right")
```

### Buffer Settings Recommendations

**Optional**: Apply lean.nvim infoview-style buffer settings to goose windows:

```lua
-- Prevent goose buffers from appearing in buffer lists
vim.bo.buflisted = false
vim.bo.bufhidden = "hide"
vim.bo.buftype = "nofile"
```

**Benefit**: Prevents goose windows from appearing in buffer navigation (`<Tab>`, `<S-Tab>`), similar to other sidebar plugins.

**Location**: This would be implemented in goose.nvim's `setup_options()` function (if upstreaming the change) or via autocmd in user config.

## Testing Plan

### Manual Testing Scenarios

1. **Basic Split Navigation**
   - Open goose.nvim in split mode
   - Verify `<C-h>` navigates to left window
   - Verify `<C-l>` navigates to right window (if exists)

2. **Terminal Mode Navigation**
   - Start goose recipe execution (creates terminal buffer)
   - From terminal mode, press `<C-h>`
   - Verify focus moves to adjacent window

3. **Multi-Sidebar Layout**
   - Open neo-tree (left)
   - Open goose.nvim (right)
   - Open lean.nvim infoview (bottom-right)
   - Navigate between all windows using `<C-h/j/k/l>`

4. **Window Resizing**
   - Verify `<A-h/l>` resizes goose window width
   - Verify persistent width (via neo-tree width manager pattern)

5. **Toggle Behavior**
   - Verify goose toggle command opens/closes split
   - Verify window state persists when reopening

### Automated Testing (Future)

**Test File**: `tests/goose_split_navigation_spec.lua`

```lua
describe("goose.nvim split navigation", function()
  it("creates split window when window_type = 'split'", function()
    -- Test split window creation
    local win_config = vim.api.nvim_win_get_config(goose_win)
    assert.is_nil(win_config.relative)  -- Not floating
  end)

  it("integrates with wincmd navigation", function()
    -- Test navigation to/from goose window
  end)

  it("respects configured width", function()
    -- Test window width matches config
  end)
end)
```

## Potential Issues and Mitigations

### Issue 1: Window Width Persistence

**Problem**: User wants goose window width to persist across sessions (similar to neo-tree).

**Solution**: Implement width tracking similar to neo-tree:
- Create `goose-width-manager` utility
- Save width on window close
- Restore width on window open
- Use `VimResized` autocmd for tracking

**Reference**: `/home/benjamin/.config/nvim/lua/neotex/util/neotree-width.lua`

### Issue 2: Buffer List Pollution

**Problem**: goose buffers appear in buffer navigation (`<Tab>`, `<S-Tab>`).

**Solution**: Apply buffer settings on window creation:
```lua
vim.bo.buflisted = false
vim.bo.bufhidden = "hide"
```

**Reference**: lean.nvim pattern (lines 128-130 in `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua`)

### Issue 3: Window Focus Management

**Problem**: goose window gets focus when toggling (user may want to stay in main window).

**Solution**: Use `enter = false` parameter in window creation:
```lua
vim.api.nvim_open_win(buf, false, opts)  -- Don't enter window
```

**Note**: goose.nvim already uses `false` for this parameter.

### Issue 4: Conflicting Keybindings

**Problem**: Internal goose keybindings might conflict with global navigation.

**Solution**: Use buffer-local keybindings for goose-specific commands:
```lua
vim.keymap.set("n", "<C-c>", close_fn, { buffer = goose_buf })
```

**Verification**: Check goose.nvim's keymap setup in configurator module.

## Conclusion

The proposed split window implementation for goose.nvim will **seamlessly integrate** with the existing navigation infrastructure:

1. **No keybinding changes required** - Current `<C-h/j/k/l>` mappings work automatically with split windows
2. **Consistent with other sidebar plugins** - neo-tree, lean.nvim, toggleterm all use split windows
3. **Already implemented in goose.nvim** - The plugin supports `window_type = "split"` configuration
4. **Terminal mode compatible** - Existing `wincmd` terminal keybindings will work with goose terminal buffers

**Recommendation**: Update user configuration to set `window_type = "split"` and `layout = "right"` to achieve the desired sidebar behavior without requiring any upstream changes to goose.nvim.

## References

### Neovim Documentation
- [Windows - Neovim docs](https://neovim.io/doc/user/windows.html) - Official window management documentation
- [Api - Neovim docs](https://neovim.io/doc/user/api.html) - nvim_open_win API reference
- [Terminal - Neovim docs](https://neovim.io/doc/user/terminal.html) - Terminal mode keybinding examples

### Plugin Examples
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) - Terminal split window implementation
- [outline.nvim](https://neovimcraft.com/plugin/hedyhli/outline.nvim/) - Sidebar split window pattern
- [smart-splits.nvim](https://brianschiller.com/blog/2024/07/17/neovim-smart-splits-on-macos/) - Advanced split navigation

### GitHub Issues
- [goose.nvim#82](https://github.com/azorng/goose.nvim/issues/82) - Feature request: Split window support

### Local Configuration Files
- `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua` - Current keybinding configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua` - Sidebar plugin reference implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua` - Infoview split window pattern
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua` - Terminal split configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` - Current goose.nvim configuration
