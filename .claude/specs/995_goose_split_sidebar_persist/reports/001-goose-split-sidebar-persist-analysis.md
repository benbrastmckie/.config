# Implementation Research: goose.nvim Split Window Support

**Date**: 2025-12-05
**Complexity**: 3
**Status**: Complete
**Workflow Type**: research-and-plan
**Prior Research**: [994_sidebar_toggle_research_nvim/reports/001-research-what-it-would-take-implement-th.md](../../994_sidebar_toggle_research_nvim/reports/001-research-what-it-would-take-implement-th.md)

## Executive Summary

This report provides implementation-specific research for converting goose.nvim from floating windows to a toggleable right sidebar split window with width persistence. The prior research (994) established feasibility and identified patterns. This research focuses on:

1. **Specific files and functions** in goose.nvim requiring modification
2. **Exact code changes** needed for split window creation
3. **Width persistence mechanism** implementation details
4. **Configuration options** to be added
5. **Integration with existing codebase** patterns

**Implementation Approach**: Local fork with ~200-250 lines of modifications across 3 core files plus 1 new utility module.

## Architecture Analysis

### Current Window Management Flow

**Window Creation Pipeline** (`ui/ui.lua:56-80`):
```lua
function M.create_windows()
  -- 1. Create buffers
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  -- 2. Create FLOATING windows (lines 63-64)
  local input_win = vim.api.nvim_open_win(input_buf, false, configurator.base_window_opts)
  local output_win = vim.api.nvim_open_win(output_buf, false, configurator.base_window_opts)

  -- 3. Setup configuration (lines 72-78)
  configurator.setup_options(windows)
  configurator.refresh_placeholder(windows)
  configurator.setup_autocmds(windows)
  configurator.setup_resize_handler(windows)
  configurator.setup_keymaps(windows)
  configurator.configure_window_dimensions(windows)

  return windows
end
```

**Key Observation**: Window creation is highly modular. Only lines 63-64 use `nvim_open_win()` for floating windows. All other setup is window-type agnostic.

### State Management

**Global State** (`state.lua:1-21`):
```lua
M.windows = nil  -- Holds: input_buf, output_buf, input_win, output_win
M.input_content = {}
M.last_focused_goose_window = nil
M.last_input_window_position = nil
M.last_output_window_position = nil
M.last_code_win_before_goose = nil
```

**Critical Finding**: The `windows` table structure doesn't depend on window type. Split windows will use the same structure, ensuring compatibility with all existing functions.

### Toggle/Close Mechanism

**API Toggle Logic** (`api.lua:30-37`):
```lua
function M.toggle()
  if state.windows == nil then
    local focus = state.last_focused_goose_window or "input"
    core.open({ new_session = false, focus = focus })
  else
    M.close()
  end
end
```

**Close Function** (`ui/ui.lua:15-33`):
```lua
function M.close_windows(windows)
  -- 1. Return focus if needed (line 18)
  if M.is_goose_focused() then M.return_to_last_code_win() end

  -- 2. Stop renderer (line 20)
  renderer.stop()

  -- 3. Close windows and delete buffers (lines 23-26)
  pcall(vim.api.nvim_win_close, windows.input_win, true)
  pcall(vim.api.nvim_win_close, windows.output_win, true)
  pcall(vim.api.nvim_buf_delete, windows.input_buf, { force = true })
  pcall(vim.api.nvim_buf_delete, windows.output_buf, { force = true })

  -- 4. Clear autocmds (lines 29-30)
  pcall(vim.api.nvim_del_augroup_by_name, 'GooseResize')
  pcall(vim.api.nvim_del_augroup_by_name, 'GooseWindows')

  -- 5. Clear state (line 32)
  state.windows = nil
end
```

**Key Observation**: Window cleanup is window-type agnostic. No modifications needed for split support.

## Files Requiring Modification

### File 1: `lua/goose/ui/ui.lua` (263 lines)

**Required Changes**: Add `create_split_windows()` function, modify toggle logic

**New Function to Add** (after line 80):
```lua
function M.create_split_windows()
  local configurator = require("goose.ui.window_config")
  local config = require("goose.config").get()

  -- Create buffers
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  require('goose.ui.highlight').setup()

  -- Save current window to return focus later
  local origin_win = vim.api.nvim_get_current_win()

  -- Create vertical split on right (or left based on config)
  local split_cmd = config.ui.sidebar_position == "left"
    and "topleft vsplit"
    or "botright vsplit"
  vim.cmd(split_cmd)

  -- Get the sidebar window handle
  local sidebar_win = vim.api.nvim_get_current_win()

  -- Set output buffer in top pane
  vim.api.nvim_win_set_buf(sidebar_win, output_buf)
  local output_win = sidebar_win

  -- Split horizontally within sidebar for input pane
  vim.cmd("split")
  local input_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(input_win, input_buf)

  -- Build windows table
  local windows = {
    input_buf = input_buf,
    output_buf = output_buf,
    input_win = input_win,
    output_win = output_win
  }

  -- Apply all standard configurations
  configurator.setup_options(windows)
  configurator.refresh_placeholder(windows)
  configurator.setup_autocmds(windows)
  configurator.setup_resize_handler(windows)
  configurator.setup_keymaps(windows)
  configurator.configure_split_dimensions(windows)  -- NEW function
  configurator.apply_split_constraints(windows)     -- NEW function

  -- Return to origin window
  vim.api.nvim_set_current_win(origin_win)

  return windows
end
```

**Modification to `create_windows()`** (line 56):
```lua
function M.create_windows()
  local config = require("goose.config").get()

  -- Route to split or float based on config
  if config.ui.use_splits then
    return M.create_split_windows()
  end

  -- Original floating window code remains unchanged
  local configurator = require("goose.ui.window_config")
  local input_buf = vim.api.nvim_create_buf(false, true)
  -- ... rest of original function
end
```

**Estimated Changes**: ~60 new lines, 5 modified lines

### File 2: `lua/goose/ui/window_config.lua` (285 lines)

**Required Changes**: Add split dimension calculation, width persistence integration, split constraints

**New Function 1: Split Dimensions** (after line 177):
```lua
function M.configure_split_dimensions(windows)
  local config = require("goose.config").get()
  local width_manager = require("goose.ui.width_persistence")

  -- Load and apply saved width
  local saved_width = width_manager.load_width()

  -- Apply width to both windows
  pcall(function()
    vim.api.nvim_win_set_width(windows.output_win, saved_width)
    vim.api.nvim_win_set_width(windows.input_win, saved_width)
  end)

  -- Calculate heights for dual-pane layout
  local total_height = vim.api.nvim_win_get_height(windows.output_win)
  local input_height = math.floor(total_height * config.ui.input_height)
  local output_height = total_height - input_height

  -- Apply heights
  pcall(function()
    vim.api.nvim_win_set_height(windows.input_win, input_height)
    vim.api.nvim_win_set_height(windows.output_win, output_height)
  end)
end
```

**New Function 2: Split Constraints** (after split dimensions):
```lua
function M.apply_split_constraints(windows)
  -- Prevent unwanted resizing
  vim.api.nvim_win_set_option(windows.output_win, 'winfixwidth', true)
  vim.api.nvim_win_set_option(windows.input_win, 'winfixwidth', true)

  -- Track width changes for persistence
  local width_manager = require("goose.ui.width_persistence")

  vim.api.nvim_create_autocmd("WinResized", {
    group = vim.api.nvim_create_augroup('GooseSplitResize', { clear = true }),
    callback = function()
      width_manager.track_width_change(windows)
    end
  })
end
```

**Modification to `setup_resize_handler()`** (line 179):
```lua
function M.setup_resize_handler(windows)
  local config = require("goose.config").get()

  local function cb()
    if config.ui.use_splits then
      M.configure_split_dimensions(windows)
    else
      M.configure_window_dimensions(windows)
    end
    require('goose.ui.topbar').render()
  end

  vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('GooseResize', { clear = true }),
    callback = cb
  })
end
```

**Estimated Changes**: ~50 new lines, 10 modified lines

### File 3: `lua/goose/config.lua` (101 lines)

**Required Changes**: Add split-related configuration options

**Modifications to defaults** (line 44):
```lua
ui = {
  window_width = 0.35,
  input_height = 0.15,
  fullscreen = false,
  layout = "right",
  floating_height = 0.8,
  display_model = true,
  display_goose_mode = true,

  -- NEW: Split mode options
  use_splits = false,              -- Enable split mode (default: false for backward compat)
  sidebar_position = "right",      -- "left" or "right"
  persist_width = true,            -- Enable width persistence
  default_split_width = 80,        -- Default width when no saved width exists
}
```

**Estimated Changes**: 4 new lines

### File 4: `lua/goose/ui/width_persistence.lua` (NEW FILE)

**Purpose**: Width persistence module (based on neotree-width pattern)

**Complete Implementation**:
```lua
-- Width persistence for goose.nvim split windows
-- Pattern adapted from neotex.util.neotree-width module

local M = {}

-- Configuration
M.width_file = vim.fn.stdpath("data") .. "/goose_split_width"
M.default_width = 80
M.current_width = M.default_width

-- Load width from persistence file
function M.load_width()
  local config = require("goose.config").get()

  -- Return configured default if persistence disabled
  if not config.ui.persist_width then
    return config.ui.default_split_width or M.default_width
  end

  -- Try to load saved width
  if vim.fn.filereadable(M.width_file) == 1 then
    local content = vim.fn.readfile(M.width_file)
    if content and content[1] then
      local width = tonumber(content[1])
      if width and width >= 30 and width <= 200 then
        M.current_width = width
        return width
      end
    end
  end

  return config.ui.default_split_width or M.default_width
end

-- Save width to persistence file
function M.save_width(width)
  local config = require("goose.config").get()

  if not config.ui.persist_width then
    return
  end

  -- Validate width range
  if width and width >= 30 and width <= 200 then
    M.current_width = width
    pcall(function()
      vim.fn.writefile({ tostring(width) }, M.width_file)
    end)
  end
end

-- Find goose windows
local function find_goose_windows(windows)
  if not windows then
    local state = require("goose.state")
    windows = state.windows
  end

  if not windows then
    return nil, nil
  end

  return windows.output_win, windows.input_win
end

-- Track and save width changes
function M.track_width_change(windows)
  local output_win, input_win = find_goose_windows(windows)

  if output_win and vim.api.nvim_win_is_valid(output_win) then
    local new_width = vim.api.nvim_win_get_width(output_win)
    if new_width ~= M.current_width and new_width >= 30 and new_width <= 200 then
      M.save_width(new_width)
    end
  end
end

-- Get current width
function M.get_width()
  return M.current_width
end

return M
```

**Estimated Changes**: 75 new lines (new file)

## Code Patterns from Reference Implementations

### Pattern 1: Split Creation (toggleterm.nvim)

**Source**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua:14`

```lua
direction = "vertical",  -- Creates vertical split
persist_size = true,     -- Width persistence
```

**Application to goose.nvim**: Use `botright vsplit` for right sidebar, `topleft vsplit` for left.

### Pattern 2: Width Persistence (neo-tree)

**Source**: `/home/benjamin/.config/nvim/lua/neotex/util/neotree-width.lua:12-24`

```lua
function M.load_width()
  if vim.fn.filereadable(M.width_file) == 1 then
    local content = vim.fn.readfile(M.width_file)
    if content and content[1] then
      local width = tonumber(content[1])
      if width and width > 10 and width < 100 then
        M.current_width = width
        return width
      end
    end
  end
  return M.default_width
end
```

**Application to goose.nvim**: Direct adaptation in `width_persistence.lua` with goose-specific path and ranges.

### Pattern 3: Width Constraints (nvim-tree deprecated)

**Source**: `/home/benjamin/.config/nvim/lua/neotex/deprecated/nvim-tree.lua:206`

```lua
vim.api.nvim_win_set_option(win, "winfixwidth", true)
```

**Application to goose.nvim**: Apply to both input and output windows in `apply_split_constraints()`.

### Pattern 4: Global State Management (nvim-tree)

**Source**: `/home/benjamin/.config/nvim/lua/neotex/deprecated/nvim-tree.lua:3-27`

```lua
_G.NvimTreePersistence = _G.NvimTreePersistence or {}
_G.NvimTreePersistence.width = width
```

**Application to goose.nvim**: NOT NEEDED. goose.nvim already has `state.lua` module. Use existing `state.windows` table.

## Implementation Details

### Dual-Pane Split Layout

**Visual Layout** (Right Sidebar):
```
┌─────────────────────────────┬────────────────────┐
│                             │                    │
│                             │  Output Window     │
│    Main Editor              │  (output_win)      │
│    (Code Files)             │  Markdown render   │
│                             │                    │
│                             ├────────────────────┤
│                             │  Input Window      │
│                             │  (input_win)       │
│                             │  Prompt input      │
└─────────────────────────────┴────────────────────┘
```

**Split Commands Sequence**:
1. `botright vsplit` - Create right vertical split
2. Set `output_buf` in top pane (`output_win`)
3. `split` (within sidebar) - Horizontal split
4. Set `input_buf` in bottom pane (`input_win`)
5. Calculate and apply heights based on `config.ui.input_height`

**Height Calculation**:
```lua
local total_height = vim.api.nvim_win_get_height(windows.output_win)
local input_height = math.floor(total_height * config.ui.input_height)  -- 15%
local output_height = total_height - input_height                        -- 85%
```

### Width Persistence Flow

**Initialization** (on window creation):
1. `width_persistence.load_width()` reads from `~/.local/share/nvim/goose_split_width`
2. Returns saved width or default (80)
3. `nvim_win_set_width()` applies to both windows

**Runtime Tracking** (on resize):
1. `WinResized` autocmd triggers
2. `width_persistence.track_width_change()` checks current width
3. If changed, writes to persistence file
4. Updates `M.current_width` state

**Persistence File Format**:
```
80
```
(Single line with numeric width value)

### Configuration Options

**User Configuration** (`nvim/lua/neotex/plugins/ai/goose/init.lua`):
```lua
require("goose").setup({
  prefered_picker = "telescope",
  default_global_keymaps = false,

  ui = {
    -- Existing options
    window_width = 0.35,      -- Used in float mode only
    input_height = 0.15,      -- Used in both modes (percentage)
    fullscreen = false,
    layout = "right",         -- Used in float mode only
    floating_height = 0.8,    -- Used in float mode only
    display_model = true,
    display_goose_mode = true,

    -- NEW: Split mode options
    use_splits = true,              -- ENABLE split mode
    sidebar_position = "right",     -- "left" or "right"
    persist_width = true,           -- Enable width persistence
    default_split_width = 80,       -- Default width (columns)
  },
})
```

**Backward Compatibility**: `use_splits = false` by default. Existing configurations work unchanged.

## Navigation Integration

### Standard Split Navigation

Once using splits, native Neovim navigation works automatically:

**Window Navigation** (no changes needed):
- `<C-h>` - Move to left window (editor)
- `<C-l>` - Move to right window (goose sidebar)
- `<C-w>w` - Cycle through windows

**Goose Internal Navigation** (existing keymaps, line 268-274 in window_config.lua):
- `<Tab>` - Toggle between input/output panes (within goose)
- Mapped to `api.toggle_pane()` in both windows

**Key Observation**: No keymap modifications needed. Split navigation is native Neovim behavior.

### Focus Management

**Existing Focus Functions** (ui.lua:82-101):
```lua
function M.focus_input(opts)
  vim.api.nvim_set_current_win(windows.input_win)
  -- ... restore position logic
end

function M.focus_output(opts)
  vim.api.nvim_set_current_win(windows.output_win)
  -- ... restore position logic
end
```

**Compatibility**: These functions work identically for float and split windows. No modifications needed.

## Testing Strategy

### Phase 1: Basic Split Creation
**Test Cases**:
1. Open goose with `use_splits = true`
2. Verify right sidebar appears
3. Verify dual-pane layout (input/output)
4. Verify buffer content displays correctly
5. Close and verify cleanup

**Success Criteria**: Sidebar opens/closes cleanly, no orphaned windows/buffers.

### Phase 2: Width Persistence
**Test Cases**:
1. Open goose, resize sidebar width
2. Close goose
3. Restart Neovim
4. Open goose, verify width restored
5. Test across multiple sessions

**Success Criteria**: Width persists across restarts, changes tracked in real-time.

### Phase 3: Navigation
**Test Cases**:
1. Use `<C-h>` to move to editor
2. Use `<C-l>` to move to goose
3. Use `<Tab>` to toggle input/output
4. Test focus management with `toggle_focus()`

**Success Criteria**: All navigation works as expected, focus tracked correctly.

### Phase 4: Integration
**Test Cases**:
1. Open neo-tree and goose simultaneously
2. Test with toggleterm open
3. Resize windows, verify `winfixwidth` works
4. Test fullscreen toggle (should warn or disable in split mode)
5. Test with multiple Neovim tabs

**Success Criteria**: No conflicts, stable behavior with other sidebars.

### Phase 5: Backward Compatibility
**Test Cases**:
1. Set `use_splits = false`, verify float mode works
2. Test with no config changes (defaults)
3. Test config migration (old config → new config)

**Success Criteria**: Float mode unchanged, existing users unaffected.

## Local Fork Setup

### Step 1: Create Local Fork

**Directory Structure**:
```
~/.config/nvim/lua/custom/
└── goose-split.nvim/
    ├── lua/goose/
    │   ├── ui/
    │   │   ├── ui.lua              (MODIFIED)
    │   │   ├── window_config.lua   (MODIFIED)
    │   │   └── width_persistence.lua (NEW)
    │   └── config.lua              (MODIFIED)
    └── ... (rest of goose.nvim files)
```

**Fork Commands**:
```bash
cd ~/.config/nvim/lua
mkdir -p custom
cp -r ~/.local/share/nvim/lazy/goose.nvim custom/goose-split.nvim
cd custom/goose-split.nvim
git init
git remote add upstream https://github.com/azorng/goose.nvim
git add .
git commit -m "Initial fork for split window support"
```

### Step 2: Update lazy.nvim Configuration

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`

**Modified Configuration**:
```lua
return {
  -- Use local fork instead of GitHub repo
  dir = vim.fn.stdpath("config") .. "/lua/custom/goose-split.nvim",

  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
      },
    },
  },

  config = function()
    require("goose").setup({
      prefered_picker = "telescope",
      default_global_keymaps = false,

      ui = {
        window_width = 0.35,
        input_height = 0.15,
        fullscreen = false,
        layout = "right",
        floating_height = 0.8,
        display_model = true,
        display_goose_mode = true,

        -- Enable split mode
        use_splits = true,
        sidebar_position = "right",
        persist_width = true,
        default_split_width = 80,
      },

      providers = {
        google = { "gemini-2.0-flash-exp" },
      },
    })
  end,

  cmd = { "Goose", "GooseOpenInput", "GooseClose" },
  keys = {},
}
```

### Step 3: Reload Configuration

```vim
:Lazy reload goose-split.nvim
:Lazy sync
```

## File Modification Summary

| File | Type | Lines Changed | Description |
|------|------|---------------|-------------|
| `lua/goose/ui/ui.lua` | Modified | +60, ~5 | Add `create_split_windows()` function |
| `lua/goose/ui/window_config.lua` | Modified | +50, ~10 | Add split dimension/constraint functions |
| `lua/goose/config.lua` | Modified | +4 | Add split mode configuration options |
| `lua/goose/ui/width_persistence.lua` | New | +75 | Width persistence module |

**Total Changes**: ~189 new lines, ~15 modified lines across 4 files.

## Risk Assessment

### Risk 1: Dual-Pane Complexity
**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- Test split creation sequence in isolation first
- Use `pcall()` wrappers around window operations
- Add validation checks for window handles

### Risk 2: Width Persistence File Conflicts
**Probability**: Low
**Impact**: Low
**Mitigation**:
- Use goose-specific filename: `goose_split_width`
- Validate file content before reading
- Graceful fallback to defaults on corruption

### Risk 3: Window Handle Invalidation
**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- Always check `nvim_win_is_valid()` before operations
- Use `pcall()` for all window/buffer API calls
- Implement robust cleanup in `close_windows()`

### Risk 4: Integration with Existing Sidebars
**Probability**: Medium
**Impact**: Low
**Mitigation**:
- Set `winfixwidth = true` on goose windows
- Use explicit `botright`/`topleft` positioning
- Test with neo-tree and toggleterm simultaneously

### Risk 5: Upstream Divergence
**Probability**: High
**Impact**: Medium
**Mitigation**:
- Track upstream via Git remote
- Keep modifications minimal and well-documented
- Consider PR to upstream after validation

## Implementation Estimate

### Time Breakdown

**Phase 1: Core Split Creation** (4-5 hours)
- Implement `create_split_windows()` in `ui.lua`
- Add routing logic in `create_windows()`
- Basic testing with dual-pane layout

**Phase 2: Width Persistence** (2-3 hours)
- Create `width_persistence.lua` module
- Implement `configure_split_dimensions()`
- Add `apply_split_constraints()`
- Test persistence across sessions

**Phase 3: Configuration Integration** (1-2 hours)
- Add config options to `config.lua`
- Update `setup_resize_handler()`
- Test with various config combinations

**Phase 4: Testing & Debugging** (3-4 hours)
- Test all navigation scenarios
- Integration testing with other plugins
- Edge case handling
- Documentation

**Phase 5: Polish & Validation** (1-2 hours)
- Code cleanup
- Comment documentation
- User configuration examples
- README updates

**Total Estimated Time**: 11-16 hours

**Confidence Level**: High (well-established patterns, modular architecture)

## Next Steps

### Immediate Actions

1. **Create local fork** (Step 1 in Local Fork Setup)
2. **Implement Phase 1** (core split creation)
3. **Test basic functionality** before proceeding
4. **Iterate on dimensions/constraints** until stable
5. **Add width persistence** (Phase 2)
6. **Validate across use cases** (Phase 4-5)

### Long-Term Considerations

1. **Monitor upstream changes**: Track goose.nvim releases for conflicts
2. **Document modifications**: Maintain clear changelog in fork
3. **Consider PR**: Submit upstream if implementation is stable and valuable
4. **User feedback**: Gather feedback from personal usage before broader sharing

## References

### goose.nvim Source Files
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/ui.lua` - Main UI module (263 lines)
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/window_config.lua` - Window configuration (285 lines)
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/config.lua` - Configuration defaults (101 lines)
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/state.lua` - Global state management (21 lines)
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/api.lua` - Public API functions (398 lines)

### Reference Implementations
- `/home/benjamin/.config/nvim/lua/neotex/util/neotree-width.lua` - Width persistence pattern (74 lines)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua` - Split sidebar configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua` - Direction-based split control
- `/home/benjamin/.config/nvim/lua/neotex/deprecated/nvim-tree.lua` - Global state and toggle patterns

### User Configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` - Current goose.nvim configuration

### Documentation
- [Neovim Windows Documentation](https://neovim.io/doc/user/windows.html)
- [Neovim API Documentation](https://neovim.io/doc/user/api.html)
- [Prior Research Report](../../994_sidebar_toggle_research_nvim/reports/001-research-what-it-would-take-implement-th.md)

---

**Report Status**: Implementation-ready
**Implementation Complexity**: Moderate (3/4)
**Confidence**: High (established patterns, modular architecture, clear modification points)
