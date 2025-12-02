# Research Report: Lean Infoview Keybinding Issue

## Executive Summary

The `<leader>ri` keybinding is correctly defined in the Neovim configuration but is non-functional because it references a non-existent command `LeanInfoviewToggle`. The lean.nvim plugin does NOT provide this command. Instead, the infoview toggle functionality is only accessible via the keybinding `<LocalLeader>i` when default mappings are enabled.

## Root Cause Analysis

### Issue 1: Non-Existent Command

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:604`

```lua
{ "<leader>ri", "<cmd>LeanInfoviewToggle<CR>", desc = "lean info", icon = "󰊕", cond = is_lean },
```

**Problem**: The command `LeanInfoviewToggle` does not exist in lean.nvim. According to the official lean.nvim documentation, the plugin only provides these explicit commands:
- `:LeanGoal` - Show goal state in preview window
- `:LeanTermGoal` - Show term-mode type information
- `:Telescope loogle` - Loogle search frontend (requires telescope.nvim)

There is NO `:LeanInfoviewToggle` command provided by the plugin.

### Issue 2: Missing Local Leader Configuration

**Location**: `/home/benjamin/.config/nvim/init.lua`

**Problem**: The configuration sets `vim.g.mapleader = " "` (space) but never configures `vim.g.maplocalleader`. This means:
- `<LocalLeader>` is undefined or defaults to backslash (`\`)
- The default lean.nvim keybinding `<LocalLeader>i` for toggling infoview may not be discoverable or intuitive

### Issue 3: Incorrect Documentation

**Location**: `/home/benjamin/.config/nvim/docs/FORMAL_VERIFICATION.md:323-324`

```markdown
- `:LeanInfoviewEnable` - Show infoview
- `:LeanInfoviewDisable` - Hide infoview
```

**Problem**: These commands are documented but do not exist in lean.nvim.

## How Lean Infoview Toggle Actually Works

According to the [lean.nvim README](https://github.com/Julian/lean.nvim), the infoview toggle functionality is accessed through:

1. **Default Keybinding**: `<LocalLeader>i` - Toggles infoview open/closed
   - Only available when `mappings = true` is set in plugin configuration
   - Requires `vim.g.maplocalleader` to be configured

2. **Programmatic Access**: `require('lean.infoview').toggle()`
   - Can be called directly from Lua

The plugin intentionally does NOT expose user commands (`:Lean*` commands) for infoview control, instead relying on:
- Default keybindings via `mappings = true`
- Direct Lua API calls

## Current Configuration Status

### What's Working

1. **Plugin Configuration**: `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua`
   ```lua
   opts = {
     mappings = true,  -- Enables default keybindings
     infoview = {
       autoopen = true,
     }
   }
   ```
   - Default mappings are enabled
   - Infoview auto-opens correctly

2. **Filetype Detection**: The `is_lean()` function correctly detects Lean files:
   ```lua
   local function is_lean()
     return vim.bo.filetype == "lean"
   end
   ```

3. **Plugin Loading**: lean.nvim is properly loaded via lazy.nvim with correct events:
   ```lua
   event = { 'BufReadPre *.lean', 'BufNewFile *.lean' }
   ```

### What's Broken

1. **Custom Keybinding**: `<leader>ri` → `:LeanInfoviewToggle` (non-existent command)
2. **Local Leader**: Not configured, so default `<LocalLeader>i` keybinding is not user-friendly
3. **Documentation**: References non-existent commands

## Solution Options

### Option 1: Use Lua API Call (Recommended)

Replace the which-key mapping with a direct Lua function call:

```lua
{ "<leader>ri", function() require('lean.infoview').toggle() end,
  desc = "lean info", icon = "󰊕", cond = is_lean },
```

**Pros**:
- Works reliably
- No dependency on command existence
- Clean integration with which-key

**Cons**:
- None

### Option 2: Configure Local Leader and Document Default Keybinding

Set up `maplocalleader` and document the default keybinding:

```lua
-- In init.lua, after setting mapleader
vim.g.maplocalleader = " "  -- Space twice, or comma, or backslash
```

Then document that `<LocalLeader>i` is the native way to toggle infoview.

**Pros**:
- Uses plugin's intended interface
- Maintains consistency with lean.nvim ecosystem
- Other lean.nvim keybindings also become available

**Cons**:
- User must learn/remember localleader concept
- Less discoverable via which-key

### Option 3: Hybrid Approach (Most User-Friendly)

1. Configure `maplocalleader` for access to all lean.nvim features
2. Add custom `<leader>ri` mapping using Lua API for discoverability
3. Update documentation to reflect actual commands

**Implementation**:

```lua
-- In init.lua
vim.g.maplocalleader = ","  -- Or another convenient key

-- In which-key.lua
{ "<leader>ri", function() require('lean.infoview').toggle() end,
  desc = "toggle infoview", icon = "󰊕", cond = is_lean },
```

**Pros**:
- Best of both worlds
- `<leader>ri` provides discoverable, which-key-documented access
- `<LocalLeader>i` and other native bindings available for power users
- Consistent with user's existing keybinding philosophy

**Cons**:
- Slight duplication (two ways to toggle infoview)

## Additional Findings

### Available Lean.nvim Keybindings

When `mappings = true`, lean.nvim provides these keybindings in Lean files (all with `<LocalLeader>` prefix):

| Key | Function |
|-----|----------|
| `<LocalLeader>i` | Toggle infoview |
| `<LocalLeader>p` | Pause infoview |
| `<LocalLeader>r` | Restart Lean server |
| `<LocalLeader>v` | Configure infoview options |
| `<LocalLeader>x` | Place infoview pin |
| `<LocalLeader>c` | Clear infoview pins |
| `<LocalLeader>dx` | Place diff pin |
| `<LocalLeader>dc` | Clear diff pin |
| `<LocalLeader>dd` | Toggle auto diff mode |
| `<LocalLeader><Tab>` | Jump to infoview window |
| `<LocalLeader>\\` | Show abbreviation |

### Infoview Buffer Management

The configuration correctly handles infoview buffer management:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "leaninfo",
  callback = function()
    vim.bo.buflisted = false
    vim.bo.bufhidden = "hide"
    vim.bo.buftype = "nofile"
    vim.bo.modifiable = false
    vim.bo.swapfile = false
  end,
})
```

This prevents the infoview from cluttering buffer lists, which is good practice.

## Recommended Implementation Plan

### Phase 1: Fix Broken Keybinding (Critical)

1. Update which-key.lua line 604:
   ```lua
   { "<leader>ri", function() require('lean.infoview').toggle() end,
     desc = "toggle infoview", icon = "󰊕", cond = is_lean },
   ```

2. Test in a Lean file to verify functionality

### Phase 2: Configure Local Leader (High Priority)

1. Add to init.lua after line 54:
   ```lua
   vim.g.maplocalleader = ","  -- Comma is common choice
   ```

2. This enables all native lean.nvim keybindings

### Phase 3: Update Documentation (Medium Priority)

1. Update FORMAL_VERIFICATION.md:
   - Remove references to `:LeanInfoviewEnable` and `:LeanInfoviewDisable`
   - Document actual commands: `:LeanGoal`, `:LeanTermGoal`
   - Document keybindings: `<leader>ri` (custom) and `<LocalLeader>i` (native)
   - Add localleader configuration instructions

2. Add which-key documentation comment in which-key.lua explaining the mapping

### Phase 4: Consider Additional Lean Keybindings (Optional)

Add other useful lean.nvim functions to which-key for discoverability:

```lua
{ "<leader>rr", function() require('lean').restart() end,
  desc = "restart lean server", icon = "󰜉", cond = is_lean },
{ "<leader>rp", function() require('lean.infoview').pause() end,
  desc = "pause infoview", icon = "󰏤", cond = is_lean },
```

## Testing Checklist

- [ ] Open a .lean file
- [ ] Verify `<leader>ri` appears in which-key menu
- [ ] Press `<leader>ri` and confirm infoview toggles open
- [ ] Press `<leader>ri` again and confirm infoview toggles closed
- [ ] Verify infoview shows current proof goals when open
- [ ] Test `<LocalLeader>i` also works (after setting maplocalleader)
- [ ] Verify no error messages in `:messages`
- [ ] Confirm infoview buffers don't appear in buffer list

## References

- [lean.nvim GitHub Repository](https://github.com/Julian/lean.nvim)
- [lean.nvim Configuration Wiki](https://github.com/Julian/lean.nvim/wiki/Configuring-&-Extending)
- [lean.nvim README - Default Keybindings](https://github.com/Julian/lean.nvim/blob/main/README.md)

## Technical Details

### Plugin Version
- **lean.nvim commit**: `f6e6ecb8f1a140315f7bfb4ea88c4a39846617b0` (from lazy-lock.json)
- **Repository**: Julian/lean.nvim (main branch)

### File Locations
- Plugin config: `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua`
- Keybinding config: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- Init file: `/home/benjamin/.config/nvim/init.lua`
- Ftplugin: `/home/benjamin/.config/nvim/after/ftplugin/lean.lua`
- Documentation: `/home/benjamin/.config/nvim/docs/FORMAL_VERIFICATION.md`

### Dependencies
- neovim/nvim-lspconfig
- nvim-lua/plenary.nvim
- folke/which-key.nvim (for keybinding discovery)

---

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [Fix Lean Infoview Keybinding Implementation Plan](../plans/001-nvim-lean-keybinding-infoview-plan.md)
- **Implementation**: [Will be updated by implementer]
- **Date**: 2025-12-02

---

**Report Generated**: 2025-12-02
**Research Complexity**: 3
**Status**: Complete
