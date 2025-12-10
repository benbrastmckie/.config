# Split Window UI Implementation in Neovim - Research Report

**Date**: 2025-12-09
**Topic**: Split Window UI Implementation for goose.nvim
**Research Focus**: Neovim split window APIs, goose.nvim architecture, and refactoring strategy

---

## Executive Summary

This report documents research into implementing split window support for goose.nvim as an alternative to its current floating window implementation. The feature request (GitHub issue #82) seeks to integrate goose.nvim with standard Neovim split navigation workflows, matching the UX of other sidebar plugins like nvim-tree, toggleterm, and lean.nvim infoview.

**Key Findings**:
1. Neovim 0.10+ supports split window creation via `nvim_open_win()` with `split` parameter
2. goose.nvim's current architecture uses floating windows created in `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/ui.lua`
3. User's config already demonstrates split window patterns in toggleterm and claude-code.nvim plugins
4. Refactoring requires minimal changes to window creation logic while maintaining existing features

---

## 1. Feature Request Analysis

### 1.1 GitHub Issue #82 Details

**Issue URL**: https://github.com/azorng/goose.nvim/issues/82
**Title**: Feature Request: Split window support as alternative to floating window
**Author**: benbrastmckie (Benjamin Brast-McKie)
**Created**: 2025-12-06

### 1.2 User Requirements

**Problem Statement**:
- Neovim users with split navigation keybindings (`<C-l>`, `<C-h>`) cannot navigate to goose.nvim's floating window
- Breaking muscle memory compared to other sidebar plugins (nvim-tree, toggleterm, lean.nvim infoview)
- Requires separate keybindings for floating window interaction

**Proposed Solution**:
```lua
ui = {
  window_type = "float",  -- Options: "float" or "split"
  layout = "right",
  window_width = 0.35,
}
```

When `window_type = "split"`, use `nvim_open_win()` with `split = "right"` (or `"left"` based on layout) instead of floating window configuration.

**Benefits**:
- Integrates with existing split navigation workflows
- Consistent UX with other sidebar plugins
- No breaking changes (float remains default)

---

## 2. Neovim Split Window API Research

### 2.1 nvim_open_win() Evolution

**Neovim 0.10 Enhancement** (Issue #18560):
- Extended `nvim_open_win()` to support regular (non-floating) windows
- Added `split` parameter for directional split creation
- Previously limited to floating and external windows

**Sources**:
- [Neovim API Documentation](https://neovim.io/doc/user/api.html)
- [GitHub Issue #18560: nvim_open_win() support for regular windows](https://github.com/neovim/neovim/issues/18560)
- [Neovim 0.10 News](https://neovim.io/doc/user/news-0.10.html)

### 2.2 Split Parameter Syntax

**Parameter Options**:
```lua
-- Create buffer first
local buf = vim.api.nvim_create_buf(false, true)

-- Split to the right (sidebar)
local win = vim.api.nvim_open_win(buf, true, {
  split = "right",
})

-- Split to the left
local win = vim.api.nvim_open_win(buf, true, {
  split = "left",
})

-- Split below
local win = vim.api.nvim_open_win(buf, true, {
  split = "below",
})

-- Split above
local win = vim.api.nvim_open_win(buf, true, {
  split = "above",
})

-- Vertical split (direction follows 'splitright' option)
local win = vim.api.nvim_open_win(buf, true, {
  vertical = true,
})
```

**Key Constraints**:
- Split windows cannot have `bufpos`, `row`, `col`, `border`, `title`, or `footer` properties
- For `vertical` parameter, exact direction determined by `splitright` and `splitbelow` Vim options
- Split direction can be explicitly controlled with `split = "left"|"right"|"above"|"below"`

### 2.3 Alternative Approaches

**Vim Command Method** (fallback for older Neovim versions):
```lua
-- Vertical split to the left
vim.api.nvim_command('leftabove vsplit')

-- Vertical split to the right
vim.api.nvim_command('rightbelow vsplit')
```

**splitright Option** (global setting):
```lua
-- From /home/benjamin/.config/nvim/lua/neotex/config/options.lua:49
splitright = true,  -- force all vertical splits to go to the right of current window
```

---

## 3. goose.nvim Architecture Analysis

### 3.1 Current Window Creation System

**Primary File**: `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/ui.lua`

**Window Creation Flow**:
```lua
-- Line 56-79: M.create_windows()
function M.create_windows()
  local configurator = require("goose.ui.window_config")
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  require('goose.ui.highlight').setup()

  local input_win = vim.api.nvim_open_win(input_buf, false, configurator.base_window_opts)
  local output_win = vim.api.nvim_open_win(output_buf, false, configurator.base_window_opts)

  local windows = {
    input_buf = input_buf,
    output_buf = output_buf,
    input_win = input_win,
    output_win = output_win
  }

  configurator.setup_options(windows)
  configurator.refresh_placeholder(windows)
  configurator.setup_autocmds(windows)
  configurator.setup_resize_handler(windows)
  configurator.setup_keymaps(windows)
  configurator.setup_after_actions(windows)
  configurator.configure_window_dimensions(windows)
  return windows
end
```

### 3.2 Window Configuration Module

**File**: `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/window_config.lua`

**Base Window Options** (Lines 8-17):
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

**Dimension Configuration** (Lines 129-177):
```lua
function M.configure_window_dimensions(windows)
  local total_width = vim.api.nvim_get_option('columns')
  local total_height = vim.api.nvim_get_option('lines')
  local is_fullscreen = config.ui.fullscreen

  local width
  if is_fullscreen then
    width = total_width
  else
    width = math.floor(total_width * config.ui.window_width)
  end

  local layout = config.ui.layout
  local total_usable_height
  local row, col

  if layout == "center" then
    -- Floating window centered
    local fh = config.ui.floating_height
    total_usable_height = math.floor(total_height * fh)
    row = math.floor((total_height - total_usable_height) / 2)
    col = is_fullscreen and 0 or math.floor((total_width - width) / 2)
  else
    -- "right" layout (sidebar)
    total_usable_height = total_height - 3
    row = 0
    col = is_fullscreen and 0 or (total_width - width)
  end

  -- Split input/output windows vertically
  local input_height = math.floor(total_usable_height * config.ui.input_height)
  local output_height = total_usable_height - input_height - 2

  -- Update window positions with relative='editor' (floating)
  vim.api.nvim_win_set_config(windows.output_win, {
    relative = 'editor',
    width = width,
    height = output_height,
    col = col,
    row = row,
  })

  vim.api.nvim_win_set_config(windows.input_win, {
    relative = 'editor',
    width = width,
    height = input_height,
    col = col,
    row = row + output_height + 2,
  })
end
```

**Key Observations**:
1. Two windows created: `input_win` (prompt) and `output_win` (conversation)
2. Windows positioned as floating with `relative = 'editor'`
3. Layout supports "center" (floating) and "right" (sidebar-positioned floating)
4. Width controlled by `config.ui.window_width` (35% in user's config)
5. Input/output split vertically with `config.ui.input_height` ratio (15% in user's config)

### 3.3 User Configuration

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`

**Current UI Settings** (Lines 77-85):
```lua
ui = {
  window_width = 0.35,      -- 35% of screen width
  input_height = 0.15,      -- 15% for input area
  fullscreen = false,
  layout = "right",         -- Sidebar on right
  floating_height = 0.8,
  display_model = true,     -- Show model in winbar
  display_goose_mode = true, -- Show mode in winbar
},
```

---

## 4. Reference Implementations

### 4.1 toggleterm.nvim (User's Config)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua`

```lua
require("toggleterm").setup {
  size = 80,
  direction = "vertical",  -- Creates split window instead of floating
  -- ...
}
```

**Key Pattern**: Single `direction` parameter switches between floating and split modes.

### 4.2 claude-code.nvim (User's Config)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`

```lua
opts = {
  window = {
    split_ratio = 0.40,      -- 40% width
    position = "vertical",   -- Vertical split (sidebar)
    -- ...
  },
}
```

**Key Pattern**: `position = "vertical"` creates sidebar split, `split_ratio` controls width.

### 4.3 Common Patterns

Both reference implementations demonstrate:
1. Configuration parameter to switch window type (direction/position)
2. Width/size ratio configuration (0.35-0.40 typical for sidebars)
3. Vertical split positioning on right side (follows `splitright = true`)
4. No complex position calculations for split windows

---

## 5. Refactoring Strategy

### 5.1 Configuration Changes

**Add to goose.nvim config** (proposed):
```lua
ui = {
  window_type = "float",     -- NEW: "float" or "split"
  window_width = 0.35,       -- Existing: applies to both modes
  input_height = 0.15,       -- Existing: applies to both modes
  fullscreen = false,        -- Existing: applies to both modes
  layout = "right",          -- Existing: "right", "left", "center"
  floating_height = 0.8,     -- Existing: only for float mode
  display_model = true,
  display_goose_mode = true,
}
```

**Backward Compatibility**:
- Default `window_type = "float"` preserves existing behavior
- All existing configuration options remain functional
- No breaking changes to API

### 5.2 Code Modifications

**File to Modify**: `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/window_config.lua`

**Proposed Changes**:

1. **Update base_window_opts** (conditional on window_type):
```lua
function M.get_base_window_opts()
  if config.ui.window_type == "split" then
    -- Split windows use minimal config
    return {}
  else
    -- Floating windows use existing config
    return {
      relative = 'editor',
      style = 'minimal',
      border = 'rounded',
      zindex = 50,
      width = 1,
      height = 1,
      col = 0,
      row = 0
    }
  end
end
```

2. **Refactor configure_window_dimensions()** (split window branch):
```lua
function M.configure_window_dimensions(windows)
  if config.ui.window_type == "split" then
    -- Split window mode: use native Neovim splits
    M.configure_split_dimensions(windows)
  else
    -- Existing floating window logic
    M.configure_floating_dimensions(windows)
  end
end

function M.configure_split_dimensions(windows)
  local total_width = vim.api.nvim_get_option('columns')
  local total_height = vim.api.nvim_get_option('lines')

  -- Calculate width based on window_width ratio
  local width = math.floor(total_width * config.ui.window_width)

  -- Calculate split heights for input/output windows
  local total_usable_height = total_height - 3
  local input_height = math.floor(total_usable_height * config.ui.input_height)
  local output_height = total_usable_height - input_height - 1

  -- Determine split direction from layout
  local split_direction = (config.ui.layout == "left") and "left" or "right"

  -- Configure output window (top split)
  vim.api.nvim_win_set_config(windows.output_win, {
    split = split_direction,
    width = width,
    height = output_height,
  })

  -- Configure input window (bottom split, relative to output)
  vim.api.nvim_win_set_config(windows.input_win, {
    split = "below",
    win = windows.output_win,  -- Split relative to output window
    width = width,
    height = input_height,
  })
end

function M.configure_floating_dimensions(windows)
  -- Existing implementation (lines 129-177)
  -- ... (unchanged)
end
```

3. **Update M.create_windows()** in ui.lua:
```lua
function M.create_windows()
  local configurator = require("goose.ui.window_config")
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  require('goose.ui.highlight').setup()

  local base_opts = configurator.get_base_window_opts()  -- NEW: conditional opts
  local input_win = vim.api.nvim_open_win(input_buf, false, base_opts)
  local output_win = vim.api.nvim_open_win(output_buf, false, base_opts)

  -- ... rest unchanged
end
```

### 5.3 Testing Checklist

**Functional Requirements**:
- [ ] Split window opens on right side (layout = "right")
- [ ] Split window opens on left side (layout = "left")
- [ ] Input/output windows maintain vertical split relationship
- [ ] Window width respects window_width ratio (0.35)
- [ ] Input height respects input_height ratio (0.15)
- [ ] Keybindings work in split mode (submit, close, toggle_pane)
- [ ] Navigation works with `<C-h>` and `<C-l>` (primary goal)
- [ ] Floating window mode still works (backward compatibility)

**Edge Cases**:
- [ ] Window resize (VimResized autocmd)
- [ ] Fullscreen mode (should it apply to splits?)
- [ ] Multiple sessions/instances
- [ ] Window close behavior (both windows close together)
- [ ] Focus restoration (last_code_win_before_goose)

**Integration Tests**:
- [ ] Works with toggleterm.nvim split navigation
- [ ] Works with nvim-tree sidebar
- [ ] No conflicts with lean.nvim infoview
- [ ] Session persistence (if applicable)

---

## 6. Implementation Complexity Analysis

### 6.1 Low Complexity Changes

1. **Configuration parameter addition**: Add `window_type` to config schema
2. **Conditional base_window_opts**: Simple if/else based on window_type
3. **Split direction mapping**: Map "right"/"left" layout to split parameter

### 6.2 Medium Complexity Changes

1. **Dimension calculation refactoring**: Split configure_window_dimensions() into two functions
2. **Window creation logic**: Update to use conditional base_opts
3. **Resize handler**: Ensure VimResized autocmd works for both modes

### 6.3 Potential Challenges

1. **Two-window split relationship**: Input window must split relative to output window (not editor)
   - Solution: Use `win` parameter in nvim_win_set_config for input window

2. **Border handling**: Split windows cannot have borders (constraint from nvim_open_win)
   - Solution: Only apply border config in floating mode

3. **Fullscreen mode**: Unclear if fullscreen should apply to splits
   - Recommendation: Disable fullscreen option in split mode (or no-op)

4. **Center layout**: Only makes sense for floating windows
   - Solution: Treat "center" as floating-only, fallback to "right" in split mode

---

## 7. Recommended Implementation Plan

### Phase 1: Core Split Window Support
1. Add `window_type` configuration parameter (default: "float")
2. Implement `get_base_window_opts()` conditional function
3. Implement `configure_split_dimensions()` for "right" layout only
4. Update `M.create_windows()` to use new functions
5. Test basic split window creation

### Phase 2: Layout Variants
1. Add "left" split support
2. Handle "center" layout (fallback to floating)
3. Test all layout combinations

### Phase 3: Edge Cases
1. Fix window resize behavior for splits
2. Ensure window close autocmds work
3. Test focus restoration
4. Verify keybindings

### Phase 4: Polish
1. Update documentation
2. Add configuration examples
3. Create migration guide for users
4. Submit PR to goose.nvim repository

---

## 8. Alternative Approaches

### 8.1 Vim Command Approach (Not Recommended)

Instead of nvim_open_win with split parameter, use vim commands:
```lua
vim.api.nvim_command('rightbelow vsplit')
```

**Drawbacks**:
- Less control over window properties
- Harder to maintain two windows (input/output)
- No access to window handle immediately

### 8.2 Single Window Mode (Out of Scope)

Merge input and output into single buffer with prompt at bottom:
```
[Output Area]
...conversation history...
─────────────────
> [Input Area]
```

**Drawbacks**:
- Major UX change (not backward compatible)
- Complex buffer management
- Different from current two-window design

---

## 9. Open Questions

1. **Should fullscreen mode work with splits?**
   - Recommendation: Disable or treat as no-op in split mode

2. **Should border config apply to splits?**
   - Recommendation: No (nvim_open_win constraint), only for floating

3. **Should center layout be supported in split mode?**
   - Recommendation: No, fallback to right split

4. **What should happen if user has 'nosplitright'?**
   - Recommendation: goose.nvim should explicitly set split direction (ignore global setting)

---

## 10. Conclusion

Implementing split window support for goose.nvim is **technically feasible** with **low-to-medium complexity**. The Neovim 0.10+ API provides the `split` parameter needed for directional window creation, and the goose.nvim architecture can be refactored with minimal changes to existing code.

**Confidence Level**: High

**Estimated Implementation Time**: 4-8 hours (including testing)

**Recommended Approach**: Phase 1-3 implementation with focus on "right" and "left" layouts

**Next Steps**:
1. Create implementation plan in `/home/benjamin/.config/.claude/specs/057_goose_sidebar_split_refactor/plans/`
2. Implement Phase 1 (core split support)
3. Test with user's nvim configuration
4. Submit upstream PR to goose.nvim repository

---

## References

### Documentation Sources
- [Neovim API Documentation](https://neovim.io/doc/user/api.html)
- [Neovim 0.10 News](https://neovim.io/doc/user/news-0.10.html)
- [Neovim Windows Documentation](https://neovim.io/doc/user/windows.html)

### GitHub Issues
- [nvim_open_win(): support regular windows - Issue #18560](https://github.com/neovim/neovim/issues/18560)
- [Feature Request: Split window support - Issue #82](https://github.com/azorng/goose.nvim/issues/82)

### Code References
- goose.nvim: `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/ui/`
- User config: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/`
- toggleterm.nvim: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua`
- claude-code.nvim: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`

### Articles
- [Neovim Windows - Splitting Windows | tui.ninja](https://tui.ninja/neovim/fundamentals/windows/splitting/)

---

**Report Generated**: 2025-12-09
**Research Duration**: ~45 minutes
**Researcher**: Claude Opus 4.5 (research-specialist agent)
