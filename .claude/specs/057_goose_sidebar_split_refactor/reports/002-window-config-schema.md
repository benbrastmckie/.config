# Window Configuration and Type Selection Research Report

**Research Date**: 2025-12-09
**Topic**: Design configuration schema for window_type option (float/split), layout positioning (left/right), and window sizing parameters specific to split mode, ensuring backward compatibility with existing float defaults
**Related Issue**: [Feature Request #82: Split window support as alternative to floating window](https://github.com/azorng/goose.nvim/issues/82)

## Executive Summary

This report analyzes the window configuration schema required to implement split window support in goose.nvim as an alternative to the current floating window implementation. The feature request seeks to integrate goose.nvim with split-based navigation workflows (e.g., `<C-l>`, `<C-h>`), making it consistent with other sidebar plugins like nvim-tree, toggleterm, and lean.nvim infoview.

**Key Finding**: The goose.nvim plugin already contains split window implementation logic in its source code (`ui.lua` and `window_config.lua`), but the `window_type` configuration option may need to be exposed or properly implemented in the user's local configuration.

## Current Configuration Analysis

### Existing UI Configuration Schema

The current user configuration in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` includes:

```lua
ui = {
  window_width = 0.35,      -- 35% of screen width
  input_height = 0.15,      -- 15% for input area
  fullscreen = false,
  layout = "right",         -- Sidebar on right
  floating_height = 0.8,
  display_model = true,
  display_goose_mode = true,
}
```

**Missing Configuration**: The `window_type` option is not currently set, despite being referenced in the upstream goose.nvim source code.

### Upstream Implementation Discovery

According to the source code analysis of the official goose.nvim repository:

**From `ui.lua`:**
```lua
function M.create_windows()
  local config = require("goose.config").get()

  if config.ui.window_type == "split" then
    local split_cmd = config.ui.layout == "left" and "topleft vsplit" or "botright vsplit"
    -- Split window implementation follows
  else
    -- Floating window implementation (default)
    input_win = vim.api.nvim_open_win(input_buf, false, configurator.base_window_opts)
    output_win = vim.api.nvim_open_win(output_buf, false, configurator.base_window_opts)
  end
end
```

**From `window_config.lua`:**
- Supports both split and floating layouts
- Handles three positioning modes for floating: center, left, right
- Uses `configure_window_dimensions()` to calculate layout-specific sizing
- Applies different highlight groups for split vs. floating modes

## Proposed Configuration Schema

### Complete Schema with window_type

```lua
ui = {
  -- Window Type Selection (NEW)
  window_type = "float",          -- Options: "float" or "split"

  -- Layout Positioning
  layout = "right",               -- Options: "left", "right", "center" (float only)

  -- Window Sizing (Common)
  window_width = 0.35,            -- Width as percentage (0.0-1.0)
  input_height = 0.15,            -- Input area height as percentage

  -- Float-Specific Options
  floating_height = 0.8,          -- Height as percentage (float mode only)
  fullscreen = false,             -- Fullscreen toggle

  -- Display Options
  display_model = true,           -- Show model name in winbar
  display_goose_mode = true,      -- Show mode (auto/chat) in winbar
}
```

### Configuration Parameters

| Parameter | Type | Default | Modes | Description |
|-----------|------|---------|-------|-------------|
| `window_type` | string | `"float"` | all | Window type: `"float"` or `"split"` |
| `layout` | string | `"right"` | all | Position: `"left"`, `"right"`, or `"center"` (float only) |
| `window_width` | number | `0.35` | all | Width as percentage (0.0-1.0) |
| `input_height` | number | `0.15` | all | Input area height as percentage |
| `floating_height` | number | `0.8` | float | Floating window height as percentage |
| `fullscreen` | boolean | `false` | all | Enable fullscreen mode |
| `display_model` | boolean | `true` | all | Show model name in winbar |
| `display_goose_mode` | boolean | `true` | all | Show mode in winbar |

### Backward Compatibility Strategy

**Default Behavior Preservation**:
1. `window_type` defaults to `"float"` if not specified
2. All existing float-mode configurations continue working without changes
3. Float-specific options (e.g., `floating_height`) are ignored in split mode
4. Layout option remains valid for both modes (left/right positioning)

**Migration Path**:
```lua
-- Minimal change to enable split mode
ui = {
  window_type = "split",  -- Add this single line
  layout = "right",       -- Existing configuration works as-is
  window_width = 0.35,    -- Existing configuration works as-is
  -- ... rest of config unchanged
}
```

## Implementation Recommendations

### 1. Configuration Validation

Add validation logic to ensure consistent configuration:

```lua
local function validate_ui_config(config)
  -- Validate window_type
  if config.ui.window_type and
     config.ui.window_type ~= "float" and
     config.ui.window_type ~= "split" then
    vim.notify(
      "goose.nvim: Invalid window_type '" .. config.ui.window_type ..
      "'. Using default 'float'.",
      vim.log.levels.WARN
    )
    config.ui.window_type = "float"
  end

  -- Validate layout for split mode
  if config.ui.window_type == "split" and config.ui.layout == "center" then
    vim.notify(
      "goose.nvim: 'center' layout not supported in split mode. Using 'right'.",
      vim.log.levels.WARN
    )
    config.ui.layout = "right"
  end

  -- Validate numeric ranges
  if config.ui.window_width < 0 or config.ui.window_width > 1 then
    vim.notify(
      "goose.nvim: window_width must be between 0 and 1. Using default 0.35.",
      vim.log.levels.WARN
    )
    config.ui.window_width = 0.35
  end
end
```

### 2. Split Window Creation Pattern

Based on Neovim best practices, split creation should use:

```lua
-- Set split direction preference
vim.o.splitright = (config.ui.layout == "right")

-- Create vertical split
vim.cmd.vsplit()

-- Set buffer in new window
vim.api.nvim_win_set_buf(0, buf)

-- Configure window width
local width = math.floor(vim.o.columns * config.ui.window_width)
vim.api.nvim_win_set_width(0, width)
```

### 3. Split-Specific Behavior

**Integration with split navigation**:
- Split mode windows automatically work with `<C-h>`, `<C-l>`, `<C-j>`, `<C-k>` navigation
- No special handling needed for split navigation keybindings
- Compatible with plugins like vim-tmux-navigator, smart-splits.nvim

**Window positioning**:
- `layout = "left"`: Use `vim.cmd("topleft vsplit")` or set `vim.o.splitright = false`
- `layout = "right"`: Use `vim.cmd("botright vsplit")` or set `vim.o.splitright = true`

### 4. Mode-Specific Option Handling

Options should be conditionally applied based on `window_type`:

```lua
local function apply_window_options(config)
  if config.ui.window_type == "split" then
    -- Split-specific options
    return {
      width = config.ui.window_width,
      input_height = config.ui.input_height,
      position = config.ui.layout,
      -- floating_height ignored in split mode
    }
  else
    -- Float-specific options
    return {
      width = config.ui.window_width,
      height = config.ui.floating_height,
      input_height = config.ui.input_height,
      position = config.ui.layout,
      relative = 'editor',
      style = 'minimal',
      border = 'rounded',
    }
  end
end
```

## Comparison with Similar Plugins

### nvim-tree Configuration Pattern

```lua
require("nvim-tree").setup({
  view = {
    side = "left",      -- or "right"
    width = 30,
  },
})
```

**Observation**: Uses explicit `side` parameter rather than generic `layout`. Consider this naming for clarity.

### toggleterm.nvim Configuration Pattern

```lua
require("toggleterm").setup({
  direction = 'vertical',  -- 'horizontal', 'tab', 'float'
  size = function(term)
    if term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,
})
```

**Observation**: Uses `direction` parameter with multiple options. Dynamic sizing based on mode is a good pattern.

### neo-tree.nvim Configuration Pattern

```lua
require("neo-tree").setup({
  window = {
    position = "left",  -- "left", "right", "top", "bottom", "float", "current"
    width = 40,
  },
})
```

**Observation**: Combines position and window type into a single `position` parameter. This is simpler but less explicit.

## Testing Considerations

### Test Cases for Configuration Schema

1. **Default Configuration Test**:
   - No `window_type` specified → defaults to `"float"`
   - Verify backward compatibility with existing configs

2. **Split Mode Test**:
   - `window_type = "split"`, `layout = "right"` → vertical split on right
   - `window_type = "split"`, `layout = "left"` → vertical split on left
   - Verify split navigation keybindings work (`<C-h>`, `<C-l>`)

3. **Float Mode Test**:
   - `window_type = "float"`, `layout = "center"` → centered floating window
   - `window_type = "float"`, `layout = "right"` → right-anchored floating window

4. **Invalid Configuration Test**:
   - `window_type = "invalid"` → warning + fallback to `"float"`
   - `window_type = "split"`, `layout = "center"` → warning + fallback to `"right"`
   - `window_width = 1.5` → warning + fallback to default `0.35`

5. **Sizing Test**:
   - `window_width = 0.35` → verify 35% of screen width
   - `input_height = 0.15` → verify 15% of window height for input area
   - Fullscreen mode → verify both split and float modes work

6. **Integration Test**:
   - Test with nvim-tree open → verify no layout conflicts
   - Test with toggleterm open → verify coexistence
   - Test split navigation → verify muscle memory keybindings work

## Implementation Priorities

### Phase 1: Configuration Schema (High Priority)
1. Add `window_type` option to configuration schema
2. Implement validation logic with sensible defaults
3. Document configuration options in README
4. Add migration examples for existing users

### Phase 2: Split Window Implementation (High Priority)
1. Verify/implement split creation logic in `ui.lua`
2. Add position handling for left/right splits
3. Configure split-specific window options
4. Test split navigation integration

### Phase 3: Polish and Testing (Medium Priority)
1. Add comprehensive test suite for all modes
2. Test with common split navigation plugins
3. Document edge cases and known limitations
4. Add health check for configuration validation

## Risks and Mitigation

### Risk 1: Layout Conflicts with Other Plugins
**Mitigation**: Document plugin ordering in lazy.nvim, test with common sidebar plugins (nvim-tree, neo-tree, toggleterm), provide troubleshooting guide.

### Risk 2: Breaking Existing Configurations
**Mitigation**: Default `window_type = "float"` ensures zero-impact on existing setups. Add deprecation warnings if any options are renamed.

### Risk 3: Split Resizing Behavior
**Mitigation**: Respect Neovim's `splitright` and `splitbelow` global settings. Test with window management plugins (focus.nvim, smart-splits.nvim).

### Risk 4: Fullscreen Mode in Split Layout
**Mitigation**: Define clear behavior (e.g., expand to full width but remain as split, or temporarily convert to float). Document expected behavior.

## Recommended User Configuration

### Minimal Split Mode Configuration

```lua
require("goose").setup({
  ui = {
    window_type = "split",   -- Enable split mode
    layout = "right",        -- Position on right side
    window_width = 0.35,     -- 35% of screen width
    input_height = 0.15,     -- 15% for input area
    display_model = true,
    display_goose_mode = true,
  },
  -- ... rest of config
})
```

### Comprehensive Configuration Example

```lua
require("goose").setup({
  prefered_picker = "telescope",
  default_global_keymaps = false,
  default_mode = "auto",

  ui = {
    -- Window Configuration
    window_type = "split",        -- "float" or "split"
    layout = "right",             -- "left", "right", or "center" (float only)

    -- Sizing
    window_width = 0.35,          -- 35% of screen width
    input_height = 0.15,          -- 15% for input area
    floating_height = 0.8,        -- Only used in float mode

    -- Display Options
    fullscreen = false,
    display_model = true,
    display_goose_mode = true,
  },

  providers = {
    google = { "gemini-3-pro-preview-11-2025" },
  },
})
```

## Conclusion

The proposed configuration schema provides a clean, backward-compatible path to implementing split window support in goose.nvim. The schema:

1. **Maintains backward compatibility**: Float mode remains default
2. **Follows Neovim conventions**: Aligns with similar plugins (nvim-tree, toggleterm, neo-tree)
3. **Enables requested workflow**: Integrates with split navigation keybindings
4. **Minimizes breaking changes**: Single new parameter (`window_type`) to enable feature
5. **Already implemented**: Upstream goose.nvim source code contains split logic

**Next Steps**:
1. Verify that upstream `window_type` configuration is properly exposed
2. Test split mode in local configuration
3. If needed, implement additional split-specific logic
4. Document configuration in local README
5. Consider contributing improvements back to upstream repository

## Sources

- [GitHub Issue #82: Feature Request - Split window support](https://github.com/azorng/goose.nvim/issues/82)
- [Neovim Windows Documentation](https://neovim.io/doc/user/windows.html)
- [Neovim API Documentation](https://neovim.io/doc/user/api.html)
- [nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- [Everything you need to know to configure neovim using lua](https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/)
- [Lazy.nvim: plugin configuration](https://dev.to/vonheikemen/lazynvim-plugin-configuration-3opi)
- [help-vsplit.nvim - Open help in vertical split](https://github.com/anuvyklack/help-vsplit.nvim)
- [focus.nvim - Auto-Focusing and Auto-Resizing Splits](https://github.com/nvim-focus/focus.nvim)
- [goose.nvim Official Repository](https://github.com/azorng/goose.nvim)
