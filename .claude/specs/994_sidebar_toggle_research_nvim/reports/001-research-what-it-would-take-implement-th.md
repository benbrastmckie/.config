# Research Report: Implementing Toggleable Sidebar for goose.nvim

**Date**: 2025-12-05
**Complexity**: 2
**Status**: Complete
**Workflow Type**: research-only

## Executive Summary

This report analyzes the feasibility of converting goose.nvim from a floating window interface to a toggleable sidebar split window, similar to nvim-tree and toggleterm. The modification would enable standard split navigation with `<C-l>` and `<C-h>` while maintaining goose.nvim's dual-pane (input/output) functionality.

**Key Finding**: This change requires **plugin modification** rather than configuration, but the implementation is straightforward and well-documented by existing patterns in the user's Neovim config.

## Current Architecture

### goose.nvim Window Implementation

The plugin currently uses **floating windows** exclusively:

**Location**: `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/window_config.lua`

```lua
M.base_window_opts = {
  relative = 'editor',
  style = 'minimal',
  border = 'rounded',
  zindex = 50,
  width = 1,
  height = 1,
  col = 0,
  row = 0
}
```

**Window Creation** (`ui/ui.lua:56-80`):
```lua
function M.create_windows()
  local configurator = require("goose.ui.window_config")
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  local input_win = vim.api.nvim_open_win(input_buf, false, configurator.base_window_opts)
  local output_win = vim.api.nvim_open_win(output_buf, false, configurator.base_window_opts)
  -- ... setup and configuration
end
```

**Layout Configuration** (`config.lua:44-52`):
```lua
ui = {
  window_width = 0.35,
  input_height = 0.15,
  fullscreen = false,
  layout = "right",        -- Position: right or center
  floating_height = 0.8,   -- Only used for "center" layout
  display_model = true,
  display_goose_mode = true
}
```

**Dimension Calculation** (`window_config.lua:129-177`):
- Floating windows positioned with absolute `row`/`col` coordinates
- `layout = "right"` places floats on right side of editor
- `layout = "center"` places floats in center with reduced height
- Uses `vim.api.nvim_win_set_config()` to position windows

### Key Limitations of Current Design

1. **Floating-Only API**: Uses `nvim_open_win()` which **only creates floating windows** ([Neovim Issue #14315](https://github.com/neovim/neovim/issues/14315))
2. **Split Navigation Incompatibility**: Floats exist outside normal split layout, preventing `<C-h>/<C-l>` navigation
3. **No Native Split Support**: Neovim's `nvim_open_win()` API does not support creating splits directly

## Reference Implementations

### 1. nvim-tree (Deprecated in User's Config)

**Location**: `/home/benjamin/.config/nvim/lua/neotex/deprecated/nvim-tree.lua`

**Split Creation Pattern** (lines 29-834):
- Uses plugin's own API: `api.tree.open()`, `api.tree.close()`, `api.tree.toggle()`
- Plugin internally manages split creation via vim commands
- Width persistence implemented via global state and `nvim_win_set_width()`
- Position controlled by `view.side = "left"` configuration

**Key Features**:
```lua
view = {
  adaptive_size = false,
  side = "left",          -- Split position
  width = initial_width,  -- Persisted width
  float = {
    enable = false,       -- Disable floating mode
  }
}
```

**Window Management**:
- Custom toggle function saves width before closing
- Autocmds track `WinResized` events for width persistence
- `winfixwidth = true` prevents unwanted resizing

### 2. neo-tree (Current File Explorer)

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua`

**Split Configuration** (lines 70-148):
```lua
window = {
  width = saved_width,
  position = "left",      -- Split position
  mappings = {
    ["l"] = "open",       -- Vim-style navigation
    ["h"] = "close_node",
    ["q"] = "close_window",
    -- ... custom keymaps
  }
}
```

**Width Persistence** (utilizes `neotex.util.neotree-width` module):
- Saves/loads width from `stdpath("data")/neotree_width`
- Event handlers track width changes via `neo_tree_window_after_open`
- Auto-close on file open: `event = "file_opened"`

**Key Implementation Details**:
- Plugin handles split creation internally
- Configuration controls split behavior
- Native integration with Neovim split layout

### 3. toggleterm

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua`

**Split Configuration** (lines 5-29):
```lua
{
  size = 80,
  direction = "vertical",  -- Creates vertical split
  persist_size = true,     -- Width persistence
  close_on_exit = true,
  float_opts = {           -- Floating mode also supported
    border = "curved",
  }
}
```

**Key Pattern**:
- `direction` option controls split vs float: `"vertical" | "horizontal" | "tab" | "float"`
- Plugin abstracts away split creation complexity
- Toggle command manages split lifecycle

### 4. lean.nvim Infoview

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua`

**Infoview Configuration** (lines 92-96):
```lua
infoview = {
  autoopen = true,
}
```

**Pattern**:
- Plugin manages split internally via `require('lean').infoview.toggle()`
- No direct window manipulation in config
- Plugin handles position and size

## Technical Implementation Requirements

### 1. Window Creation Changes

**Current Approach** (Floating):
```lua
-- Uses nvim_open_win with floating config
local win = vim.api.nvim_open_win(buf, false, {
  relative = 'editor',
  width = width,
  height = height,
  col = col,
  row = row,
})
```

**Required Approach** (Split):
```lua
-- Use vim commands to create splits
-- Option 1: Pre-create split, then set buffer
vim.cmd("vsplit")
vim.api.nvim_set_current_buf(bufnr)

-- Option 2: Split with buffer directly
vim.cmd(string.format("vertical sb %d", bufnr))

-- Option 3: Use vim.cmd with explicit positioning
vim.cmd("botright vsplit")
vim.api.nvim_win_set_buf(0, bufnr)
```

**Split Position Control**:
```lua
-- Right sidebar
vim.cmd("botright vsplit")  -- Create split on far right

-- Left sidebar
vim.cmd("topleft vsplit")   -- Create split on far left
```

**Reference**: [Neovim API Documentation](https://neovim.io/doc/user/api.html) and [Stack Overflow: nvim_open_win split support discussion](https://github.com/nvim-neotest/neotest/discussions/56)

### 2. Dual-Pane Layout

goose.nvim uses **two windows** (input + output), requiring stacked splits:

**Proposed Layout** (Right Sidebar):
```
┌────────────────────────────────┬──────────────────┐
│                                │                  │
│                                │  Output Window   │
│    Main Editor                 │  (Markdown)      │
│    (Code Files)                │                  │
│                                ├──────────────────┤
│                                │  Input Window    │
│                                │  (Prompt)        │
└────────────────────────────────┴──────────────────┘
```

**Implementation Strategy**:
1. Create vertical split on right: `botright vsplit`
2. Set first buffer (output) in split window
3. Horizontally split within sidebar: `split` (in sidebar window)
4. Set second buffer (input) in bottom pane
5. Adjust heights to match `input_height` ratio

**Code Sketch**:
```lua
function M.create_split_windows()
  -- Save current window
  local origin_win = vim.api.nvim_get_current_win()

  -- Create right vertical split
  vim.cmd("botright vsplit")
  local sidebar_win = vim.api.nvim_get_current_win()

  -- Set output buffer
  vim.api.nvim_win_set_buf(sidebar_win, output_buf)

  -- Split horizontally within sidebar
  vim.cmd("split")
  local input_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(input_win, input_buf)

  -- Set heights
  local total_height = vim.api.nvim_win_get_height(0)
  local input_height = math.floor(total_height * config.ui.input_height)
  vim.api.nvim_win_set_height(input_win, input_height)

  -- Return to origin
  vim.api.nvim_set_current_win(origin_win)

  return { input_win = input_win, output_win = sidebar_win }
end
```

### 3. Width Persistence

**Pattern from neo-tree**:
```lua
-- Save width to persistent storage
local width_file = vim.fn.stdpath("data") .. "/goose_width"
vim.fn.writefile({ tostring(width) }, width_file)

-- Load on startup
local saved_width = 30  -- default
if vim.fn.filereadable(width_file) == 1 then
  local content = vim.fn.readfile(width_file)
  saved_width = tonumber(content[1]) or 30
end

-- Apply width to split
vim.api.nvim_win_set_width(win, saved_width)
vim.api.nvim_win_set_option(win, "winfixwidth", true)
```

**Autocmd for tracking**:
```lua
vim.api.nvim_create_autocmd("WinResized", {
  callback = function()
    if is_goose_window(vim.api.nvim_get_current_win()) then
      local width = vim.api.nvim_win_get_width(0)
      vim.fn.writefile({ tostring(width) }, width_file)
    end
  end
})
```

### 4. Toggle Functionality

**Pattern from nvim-tree's custom toggle** (lines 576-582):
```lua
api.tree.toggle = function(find_file, no_focus)
  _G.NvimTreePersistence.toggle({
    find_file = find_file,
    focus = not no_focus
  })
end

function toggle()
  if is_open() then
    save_width()
    close_windows()
  else
    create_windows()
    restore_width()
  end
end
```

**Required Changes for goose.nvim**:
```lua
-- Modify goose/ui/ui.lua
function M.toggle()
  if state.windows then
    M.close_windows(state.windows)
  else
    state.windows = M.create_split_windows()
    -- ... existing setup code
  end
end
```

### 5. Split Navigation Integration

Once using splits instead of floats, standard navigation works automatically:

**User's Desired Workflow**:
- `<C-h>`: Move to left split (editor)
- `<C-l>`: Move to right split (goose sidebar)
- `<Tab>`: Toggle between input/output panes (within goose)

**No changes needed** to existing navigation mappings - native Neovim split navigation will work.

## Configuration vs Plugin Modification

### Why Configuration Alone Won't Work

**Neovim API Limitation**:
> `nvim_open_win()` only supports opening floating windows. It'd be nice to have a way to create normal windows from Lua.
>
> — [Neovim Issue #14315](https://github.com/neovim/neovim/issues/14315)

**goose.nvim Hardcoded Behavior**:
- `ui/ui.lua:63-64` always calls `nvim_open_win()` with floating config
- `window_config.lua:162-176` always uses `relative = 'editor'` (floating mode)
- No configuration option to switch between float/split modes

**Conclusion**: Plugin modification is **required**.

### Required Plugin Changes

**Files to Modify**:

1. **`lua/goose/ui/ui.lua`**:
   - Add `create_split_windows()` function alongside `create_windows()`
   - Modify toggle logic to use split creation

2. **`lua/goose/ui/window_config.lua`**:
   - Add split dimension calculation (alternative to floating dimensions)
   - Add split-specific autocmds for width tracking

3. **`lua/goose/config.lua`**:
   - Add `ui.use_splits` boolean option (default: false for backward compatibility)
   - Optionally add `ui.sidebar_position` ("left" | "right")

**Estimated Changes**: ~150-200 lines of code across 3 files

### Alternative: Fork vs Upstream Contribution

**Option A: Local Fork**
- Clone goose.nvim to `~/.config/nvim/lua/` as local plugin
- Implement split support
- Configure lazy.nvim to use local version
- **Pros**: Full control, immediate implementation
- **Cons**: Manual updates, no community benefit

**Option B: Upstream Contribution**
- Fork goose.nvim on GitHub
- Implement split support with config option
- Submit pull request
- **Pros**: Benefits all users, maintained by community
- **Cons**: Requires coordination, review process

**Recommendation**: Start with **Option A** (local fork) to validate approach, then contribute upstream once proven.

## Implementation Plan

### Phase 1: Core Split Creation (4-6 hours)

**Tasks**:
1. Create local fork of goose.nvim
2. Implement `create_split_windows()` in `ui/ui.lua`
3. Add split dimension calculations
4. Test basic dual-pane split layout

**Success Criteria**:
- goose opens as right sidebar split
- Input/output panes display correctly
- Standard content functionality works

### Phase 2: Width Persistence (2-3 hours)

**Tasks**:
1. Implement width save/load functions
2. Add `WinResized` autocmd tracking
3. Set `winfixwidth` option
4. Test across Neovim sessions

**Success Criteria**:
- Width persists across restarts
- Manual resizing updates saved width
- No conflicts with other split resizing

### Phase 3: Toggle Integration (2-3 hours)

**Tasks**:
1. Modify toggle logic to detect split state
2. Implement clean close with width save
3. Test rapid toggle operations
4. Validate focus management

**Success Criteria**:
- Toggle opens/closes cleanly
- No orphaned buffers or windows
- Cursor returns to correct location

### Phase 4: Configuration Options (1-2 hours)

**Tasks**:
1. Add `ui.use_splits` config option
2. Add `ui.sidebar_position` config option
3. Update user's goose config to enable splits
4. Test fallback to floating mode

**Success Criteria**:
- Config option controls split vs float
- Backward compatibility maintained
- Documentation updated

### Phase 5: Polish & Testing (2-3 hours)

**Tasks**:
1. Test with various screen sizes
2. Test with other sidebars (neo-tree, toggleterm)
3. Validate autocmd cleanup
4. Edge case testing (empty buffers, errors, etc.)

**Success Criteria**:
- Stable across use cases
- No memory leaks or orphaned resources
- Integration with existing workflows

**Total Estimated Time**: 11-17 hours

## Comparison with Existing Patterns

### Similar Implementations in User's Config

| Plugin | Split Type | Toggle | Width Persistence | Dual Pane |
|--------|------------|--------|-------------------|-----------|
| **neo-tree** | Vertical (left) | Yes | Yes (custom util) | No |
| **nvim-tree** | Vertical (left) | Yes | Yes (global state) | No |
| **toggleterm** | Vertical/Horizontal | Yes | Yes (native) | No |
| **lean.nvim** | Plugin-managed | Yes | Plugin-managed | Yes (infoview) |
| **goose.nvim (current)** | Floating | Yes | No | Yes |
| **goose.nvim (proposed)** | Vertical (right) | Yes | Yes (file-based) | Yes |

### Code Reuse Opportunities

**From neo-tree** (`neotex/plugins/ui/neo-tree.lua`):
- Width persistence pattern (lines 10-13, utilities)
- Event handler structure (lines 150-230)
- `winfixwidth` usage (line 283)

**From nvim-tree** (`neotex/deprecated/nvim-tree.lua`):
- Global state management pattern (lines 3-27)
- Toggle function structure (lines 321-362)
- Autocmd setup (lines 137-169)

**From toggleterm** (`neotex/plugins/editor/toggleterm.lua`):
- Direction-based split control (line 14)
- Size persistence (line 13)

**Integration Point**: Reuse `neotex.util.neotree-width` module pattern for goose width persistence.

## Risks and Mitigation

### Risk 1: Dual-Pane Complexity
**Issue**: Stacking two splits within sidebar is non-trivial
**Mitigation**:
- Prototype with simpler single-pane version first
- Use `vim.cmd()` for reliable split commands
- Reference lean.nvim's dual-pane implementation

### Risk 2: Window Management State
**Issue**: Tracking multiple window handles and their relationships
**Mitigation**:
- Use goose's existing `state.windows` table
- Add validation checks before window operations
- Implement robust cleanup in close function

### Risk 3: Conflicts with Other Splits
**Issue**: Multiple sidebars competing for space
**Mitigation**:
- Set `winfixwidth = true` on goose windows
- Use explicit `botright`/`topleft` positioning
- Test with neo-tree, toggleterm simultaneously

### Risk 4: Plugin Updates Breaking Changes
**Issue**: Local fork diverges from upstream
**Mitigation**:
- Track upstream changes via Git remote
- Keep modifications minimal and well-documented
- Consider submitting PR to avoid long-term fork maintenance

## Alternative Approaches (Not Recommended)

### Approach 1: Wrapper Plugin
Create separate plugin that opens goose in a split, managing windows externally.

**Pros**: No goose.nvim modification
**Cons**:
- Complex state synchronization
- Fragile - breaks if goose internal API changes
- Duplicate window management logic

### Approach 2: Vim Commands Only
Use autocmds to convert floating windows to splits after creation.

**Pros**: Minimal code changes
**Cons**:
- Relies on undocumented behavior
- May cause flicker during conversion
- Limited control over layout

### Approach 3: Wait for Upstream Feature
Request feature from goose.nvim maintainers.

**Pros**: Community-maintained solution
**Cons**:
- Unknown timeline (could be months/years)
- May not match exact requirements
- No control over implementation

## Recommendations

### Immediate Actions (User's Workflow)

1. **Fork goose.nvim locally**:
   ```bash
   cd ~/.config/nvim/lua/
   mkdir -p custom
   cp -r ~/.local/share/nvim/lazy/goose.nvim custom/goose-split.nvim
   ```

2. **Update lazy.nvim config**:
   ```lua
   -- lua/neotex/plugins/ai/goose/init.lua
   return {
     dir = vim.fn.stdpath("config") .. "/lua/custom/goose-split.nvim",
     -- rest of config unchanged
   }
   ```

3. **Implement Phase 1** (core split creation) as proof of concept

4. **Test basic functionality** before proceeding to width persistence

### Long-Term Strategy

1. **Validate local implementation** over 1-2 weeks of usage
2. **Document changes** in fork with comments and README
3. **Consider upstream PR** if implementation is stable
4. **Monitor goose.nvim releases** for potential conflicts

### Configuration After Implementation

**Expected user config** (`lua/neotex/plugins/ai/goose/init.lua`):
```lua
require("goose").setup({
  prefered_picker = "telescope",
  default_global_keymaps = false,

  ui = {
    use_splits = true,          -- NEW: Enable split mode
    sidebar_position = "right", -- NEW: Right sidebar
    window_width = 0.35,
    input_height = 0.15,
    fullscreen = false,
    display_model = true,
    display_goose_mode = true,
  },

  -- ... rest of config unchanged
})
```

## Conclusion

Converting goose.nvim from floating windows to a toggleable sidebar split is **technically feasible** and **well-documented** by existing patterns in the user's Neovim configuration. The implementation requires plugin modification rather than configuration changes due to Neovim API limitations.

**Key Takeaways**:

1. **Plugin modification required**: Cannot be achieved via configuration alone
2. **Well-established patterns**: neo-tree, nvim-tree, and toggleterm provide proven implementations
3. **Moderate complexity**: Estimated 11-17 hours of development
4. **Low risk**: Local fork approach provides safe experimentation
5. **Standard navigation**: Once implemented, `<C-h>/<C-l>` will work automatically

**Recommended Approach**: Implement as local fork using patterns from neo-tree (width persistence) and nvim-tree (toggle logic), then consider upstream contribution after validation.

## References

### Documentation
- [Neovim Windows Documentation](https://neovim.io/doc/user/windows.html)
- [Neovim API Documentation](https://neovim.io/doc/user/api.html)
- [Neovim Issue #14315: nvim_open_win split support](https://github.com/neovim/neovim/issues/14315)

### Plugin Implementations
- [neo-tree.nvim GitHub](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [vim-sidebar-manager](https://github.com/brglng/vim-sidebar-manager)
- [outline.nvim](https://neovimcraft.com/plugin/hedyhli/outline.nvim/)
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)

### Related Discussions
- [Stack Overflow: Open fzf.vim in split instead of floating window](https://stackoverflow.com/questions/63905992/open-fzf-vim-in-split-instead-of-floating-window)
- [Neotest Discussion #56: Output Window as split](https://github.com/nvim-neotest/neotest/discussions/56)
- [Neovim Discourse: How to split a floating window?](https://neovim.discourse.group/t/how-to-split-a-floating-window/2578)

### User's Configuration Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua` - Split sidebar with width persistence
- `/home/benjamin/.config/nvim/lua/neotex/deprecated/nvim-tree.lua` - Toggle and state management patterns
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua` - Direction-based split control
- `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.nvim` - Dual-pane sidebar implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` - Current goose.nvim configuration

---

**Report Status**: Ready for implementation planning
**Next Steps**: Review findings with user, proceed to implementation if approved
