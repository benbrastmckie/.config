# Research Report: Telescope Escape Key Issue

**Report Number**: 043
**Date**: 2025-10-08
**Component**: Claude Code Artifacts Picker (Telescope)
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`

## Executive Summary

Investigation into why the Escape key doesn't reliably close the custom Telescope picker for Claude Code artifacts. The issue has been identified as a conflict between:

1. Global Telescope configuration that maps `<Esc>` to close immediately
2. Custom picker implementation that uses `attach_mappings`
3. Potential interference from nvim-autopairs plugin
4. Missing explicit escape mapping in the custom picker's `attach_mappings` function

## Problem Analysis

### Current Behavior

Users report that pressing `<Esc>` sometimes requires multiple presses to close the Claude Code artifacts picker, despite working correctly in other Telescope pickers.

### Root Cause

The picker at line 2742-3028 in `picker.lua` uses `attach_mappings` to define custom keybindings but **does not explicitly map the Escape key**. While it correctly returns `true` at line 3027, this doesn't fully preserve the global Telescope escape mapping due to a known Telescope behavior.

### Key Finding: attach_mappings Override Behavior

According to Telescope.nvim issue #2612, when `attach_mappings` is used in a custom picker, it **completely overrides** mappings from `telescope.setup()` rather than just having higher priority. This means even though the global config at `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/telescope.lua` line 28 sets:

```lua
["<esc>"] = actions.close, -- Close picker immediately (no mode switch)
```

This mapping is **not inherited** by the custom picker that uses `attach_mappings`.

### Additional Factors

1. **nvim-autopairs Configuration**: The autopairs plugin at `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua` line 18 correctly disables itself for TelescopePrompt:
   ```lua
   disable_filetype = { "TelescopePrompt", "spectre_panel" },
   ```
   This is the proper configuration and not causing the issue.

2. **Default Telescope Behavior**: By design, Telescope requires two escape presses:
   - First press: Exit insert mode
   - Second press: Close the picker

   The global config overrides this, but custom pickers need explicit mapping.

## Code Analysis

### Current Custom Picker Implementation

Location: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:2742-3028`

```lua
attach_mappings = function(prompt_bufnr, map)
  -- Preview scrolling using Telescope's native actions (no buffer issues)
  map("i", "<C-u>", actions.preview_scrolling_up)
  map("i", "<C-d>", actions.preview_scrolling_down)
  map("i", "<C-f>", actions.preview_scrolling_down)  -- Alternative (full page)
  map("i", "<C-b>", actions.preview_scrolling_up)    -- Alternative (full page)

  -- Context-aware Enter key: direct action execution
  actions.select_default:replace(function()
    -- ... custom enter handler ...
  end)

  -- Load artifact locally with Ctrl-l
  map("i", "<C-l>", function() ... end)

  -- Edit artifact file with Ctrl-e
  map("i", "<C-e>", function() ... end)

  -- Update artifact from global version with Ctrl-g
  map("i", "<C-g>", function() ... end)

  -- Save local artifact to global with Ctrl-s
  map("i", "<C-s>", function() ... end)

  -- Create new command with Ctrl-n
  map("i", "<C-n>", function() ... end)

  return true  -- Line 3027: Correctly returns true
end,
```

**Critical Issue**: No explicit `<Esc>` mapping despite having custom mappings for other keys.

### Global Telescope Configuration

Location: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/telescope.lua:20-63`

```lua
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-c>"] = actions.close,
        ["<esc>"] = actions.close, -- Line 28: Global escape mapping
        -- ... more mappings ...
      },
      n = {
        ["<esc>"] = actions.close,  -- Line 42: Normal mode escape
        -- ... more mappings ...
      },
    },
  },
})
```

This global configuration **should** make escape close immediately, but it's overridden by `attach_mappings`.

## Solution

### Recommended Fix

Add explicit escape key mappings in the custom picker's `attach_mappings` function:

```lua
attach_mappings = function(prompt_bufnr, map)
  -- ADD THESE LINES AT THE BEGINNING:
  -- Escape key: close picker immediately (override default two-press behavior)
  map("i", "<Esc>", actions.close)
  map("n", "<Esc>", actions.close)

  -- Preview scrolling using Telescope's native actions (no buffer issues)
  map("i", "<C-u>", actions.preview_scrolling_up)
  map("i", "<C-d>", actions.preview_scrolling_down)
  map("i", "<C-f>", actions.preview_scrolling_down)
  map("i", "<C-b>", actions.preview_scrolling_up)

  -- ... rest of existing mappings ...

  return true
end,
```

### Location to Edit

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
Line: 2742 (immediately after `attach_mappings = function(prompt_bufnr, map)`)

### Why This Works

1. **Explicit override**: Directly maps `<Esc>` to `actions.close` in both insert and normal modes
2. **Precedence**: Mappings defined in `attach_mappings` take highest precedence
3. **Consistency**: Matches the behavior of other Telescope pickers in the configuration
4. **Standard pattern**: Follows Telescope best practices for custom pickers

## Alternative Solutions Considered

### Alternative 1: Remove attach_mappings and use global config
**Rejected**: Would lose all custom keybindings (Ctrl-l, Ctrl-e, Ctrl-g, etc.)

### Alternative 2: Use Ctrl-c instead
**Rejected**: Global config already has `<C-c>` mapped, but doesn't solve the user's expectation that Esc should work

### Alternative 3: Return false from attach_mappings
**Rejected**: Would disable all default Telescope behaviors, breaking preview scrolling and other features

## Testing Recommendations

After implementing the fix:

1. **Basic close**: Press `<Esc>` once in insert mode - picker should close immediately
2. **Normal mode close**: Press `<Esc>` in normal mode - picker should close immediately
3. **Custom keybindings**: Verify Ctrl-l, Ctrl-e, Ctrl-g, Ctrl-s, Ctrl-n still work
4. **Preview scrolling**: Verify Ctrl-u and Ctrl-d still work for preview navigation
5. **Multiple pickers**: Test escape in different Telescope pickers to ensure no regression

## Related Documentation

### Telescope Issues
- Issue #2512: "Need to press Esc twice for it to work"
  - Solution: Map `["<Esc>"] = actions.close` in defaults.mappings.i

- Issue #595: "Mapping Esc to quit in insert mode doesn't work"
  - Solution: Check for conflicting autopairs plugins
  - Note: autopairs correctly configured in this case

- Issue #2612: "attach_mappings completely cancels mappings in telescope.setup()"
  - This is the key issue - `attach_mappings` overrides global config
  - Must explicitly remap desired keys in `attach_mappings`

### Telescope Configuration Recipes

From the official wiki (https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes):

```lua
require("telescope").setup{
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = actions.close
      },
    }
  }
}
```

This is the standard pattern for single-press escape to close.

### Best Practices for attach_mappings

From Telescope documentation and community:

1. **Always return true** if you want to preserve any default mappings
2. **Explicitly map critical keys** like escape, even if they're in global config
3. **Map for both modes** (insert and normal) for consistent behavior
4. **Test thoroughly** as `attach_mappings` overrides global configuration

## Implementation Checklist

- [ ] Add `map("i", "<Esc>", actions.close)` at line 2744 (after attach_mappings opens)
- [ ] Add `map("n", "<Esc>", actions.close)` at line 2745
- [ ] Test escape key in insert mode
- [ ] Test escape key in normal mode
- [ ] Verify all custom keybindings still work
- [ ] Verify preview scrolling still works
- [ ] Update documentation if needed (README.md already documents Esc behavior)

## References

### File Locations

- **Custom Picker**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
  - Function: `M.show_commands_picker()` starting at line 2698
  - attach_mappings: lines 2742-3028

- **Global Telescope Config**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/telescope.lua`
  - Escape mapping: line 28 (insert mode), line 42 (normal mode)

- **Autopairs Config**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua`
  - TelescopePrompt disabled: line 18

### External Resources

- Telescope.nvim repository: https://github.com/nvim-telescope/telescope.nvim
- Configuration Recipes wiki: https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes
- Issue #2512 (escape twice): https://github.com/nvim-telescope/telescope.nvim/issues/2512
- Issue #2612 (attach_mappings override): https://github.com/nvim-telescope/telescope.nvim/issues/2612
- Issue #595 (escape mapping): https://github.com/nvim-telescope/telescope.nvim/issues/595

## Conclusion

The escape key issue in the Claude Code artifacts picker is caused by `attach_mappings` completely overriding the global Telescope configuration. The solution is straightforward: explicitly map `<Esc>` to `actions.close` in both insert and normal modes within the `attach_mappings` function. This is a well-documented pattern in the Telescope community and should resolve the issue immediately.

The fix requires adding just 2 lines of code and maintains full compatibility with all existing custom keybindings and Telescope functionality.
