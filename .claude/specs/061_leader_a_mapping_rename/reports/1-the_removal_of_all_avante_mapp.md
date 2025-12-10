# Avante Mapping Removal Research Report

## Metadata
- **Date**: 2025-12-09
- **Research Focus**: Removal of all Avante mappings from which-key.lua by commenting them out
- **Target File**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua
- **Workflow**: research-and-revise

## Executive Summary

This report documents all Avante-related keybindings in which-key.lua and provides specific instructions for commenting them out. Five Avante mappings currently occupy prime ergonomic positions in the `<leader>a` (AI/Assistant) namespace, blocking implementation of comprehensive Goose command coverage planned in the Leader A Mapping Rename implementation plan.

## Current Avante Mappings Inventory

### Location in which-key.lua

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua
**Section**: `<leader>a - AI/ASSISTANT GROUP`
**Line Range**: 260-265

### Complete Mapping List

| Key Binding | Command | Description | Icon | Mode | Line Number |
|-------------|---------|-------------|------|------|-------------|
| `<leader>aa` | `AvanteAsk` | avante ask | 󰚩 | n | 261 |
| `<leader>ae` | `AvanteEdit` | avante edit | 󱇧 | v | 262 |
| `<leader>ap` | `AvanteProvider` | avante provider | 󰜬 | n | 263 |
| `<leader>am` | `AvanteModel` | avante model | 󰡨 | n | 264 |
| `<leader>ax` | `MCPHubOpen` | mcp hub | 󰚩 | n | 265 (exception: MCP Hub) |

### Prime Ergonomic Key Analysis

These five mappings occupy optimal ergonomic positions in the `<leader>a` namespace:

1. **`<leader>aa`** - Double-tap pattern (highest ergonomic value for toggle operations)
2. **`<leader>ae`** - Home row position (excellent for high-frequency "edit/entry" actions)
3. **`<leader>am`** - Home row position (ideal for mode/model selection)
4. **`<leader>ap`** - Home row adjacent (strong mnemonic for "provider" selection)
5. **`<leader>ax`** - Right hand pinky reach (suitable for less frequent "execute" operations)

### Strategic Removal Justification

According to the existing implementation plan (001-leader-a-mapping-rename-plan.md), these prime keys are being reassigned to high-frequency Goose commands:

- **`<leader>aa`**: Reassigned to Goose toggle (double-tap pattern optimization)
- **`<leader>ae`**: Reassigned to Goose input (edit/entry mnemonic)
- **`<leader>am`**: Reassigned to Goose mode picker (auto/chat selection)
- **`<leader>ap`**: Reassigned to Goose provider picker (backend selection)
- **`<leader>ax`**: Reassigned to Goose new session (execute new session)

## Lua Comment Syntax

### Single-Line Comments
Lua uses `--` for single-line comments:

```lua
-- This is a single-line comment
local value = 42 -- Inline comment after code
```

### Multi-Line Comments
Lua uses `--[[` and `]]` for multi-line block comments:

```lua
--[[
  This is a multi-line comment
  that spans multiple lines
]]
```

## Removal Instructions

### Recommended Approach: Line-by-Line Commenting

Comment out each Avante mapping individually using single-line `--` syntax to maintain code structure and allow easy rollback if needed.

### Exact Code to Comment Out

**Original Code (Lines 260-265)**:
```lua
      -- Avante AI commands
      { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "avante ask", icon = "󰚩" },
      { "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "avante edit", icon = "󱇧", mode = { "v" } },
      { "<leader>ap", "<cmd>AvanteProvider<CR>", desc = "avante provider", icon = "󰜬" },
      { "<leader>am", "<cmd>AvanteModel<CR>", desc = "avante model", icon = "󰡨" },
      { "<leader>ax", "<cmd>MCPHubOpen<CR>", desc = "mcp hub", icon = "󰚩" },
```

**Commented Out Code**:
```lua
      -- Avante AI commands (REMOVED: 2025-12-09 - Avante plugin no longer used)
      -- { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "avante ask", icon = "󰚩" },
      -- { "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "avante edit", icon = "󱇧", mode = { "v" } },
      -- { "<leader>ap", "<cmd>AvanteProvider<CR>", desc = "avante provider", icon = "󰜬" },
      -- { "<leader>am", "<cmd>AvanteModel<CR>", desc = "avante model", icon = "󰡨" },
      -- { "<leader>ax", "<cmd>MCPHubOpen<CR>", desc = "mcp hub", icon = "󰚩" },
```

### Implementation Steps

1. **Open which-key.lua** in editor:
   ```bash
   nvim /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua +260
   ```

2. **Update section header** (line 260):
   - Change from: `-- Avante AI commands`
   - Change to: `-- Avante AI commands (REMOVED: 2025-12-09 - Avante plugin no longer used)`

3. **Comment out each mapping** (lines 261-265):
   - Add `-- ` prefix to each line containing Avante mappings

4. **Verify syntax** after commenting:
   - Ensure no hanging commas in the `wk.add()` table
   - Check that Claude commands (above) and Lectic commands (below) remain valid
   - Verify closing braces/brackets match opening ones

5. **Save file** and test:
   ```bash
   :w
   :source %
   :checkhealth which-key
   ```

## Alternative Removal Approaches (Not Recommended)

### Block Comment Approach
```lua
--[[
      -- Avante AI commands
      { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "avante ask", icon = "󰚩" },
      { "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "avante edit", icon = "󱇧", mode = { "v" } },
      { "<leader>ap", "<cmd>AvanteProvider<CR>", desc = "avante provider", icon = "󰜬" },
      { "<leader>am", "<cmd>AvanteModel<CR>", desc = "avante model", icon = "󰡨" },
      { "<leader>ax", "<cmd>MCPHubOpen<CR>", desc = "mcp hub", icon = "󰚩" },
]]
```

**Why Not Recommended**: Block comments can interfere with nested comment blocks and make it harder to selectively uncomment individual mappings during debugging.

### Complete Deletion Approach
Simply delete lines 260-265 entirely.

**Why Not Recommended**: No rollback capability without git history; harder to reference original mapping structure when implementing replacement Goose mappings.

## MCP Hub Mapping Exception

**Important Note**: Line 265 (`<leader>ax` for `MCPHubOpen`) is technically an MCP Hub mapping, not a pure Avante mapping. However, it is grouped with Avante commands in the current structure and occupies a prime ergonomic key needed for Goose command coverage.

**Recommendation**: Comment out this mapping along with Avante mappings, but add a separate note if MCP Hub functionality needs to be preserved:

```lua
-- { "<leader>ax", "<cmd>MCPHubOpen<CR>", desc = "mcp hub", icon = "󰚩" },
-- NOTE: If MCP Hub access needed, reassign to <leader>mx or similar non-AI namespace
```

## Impact Assessment

### Immediate Impact
- **5 key bindings freed** in `<leader>a` namespace (aa, ae, ap, am, ax)
- **No functional loss** if Avante plugin is disabled/removed from config
- **Syntax validation required** to ensure no broken Lua tables

### Integration with Existing Plan

This removal enables **Phase 3: Optimize Goose Ergonomics with Avante Keys** in the Leader A Mapping Rename implementation plan (001-leader-a-mapping-rename-plan.md):

- Goose toggle moves to `<leader>aa` (optimal double-tap pattern)
- Goose input moves to `<leader>ae` (edit/entry mnemonic)
- Goose mode picker assigns to `<leader>am` (auto/chat selection)
- Goose provider picker moves to `<leader>ap` (backend selection)
- Goose new session assigns to `<leader>ax` (execute new session)

### Potential Side Effects

1. **Plugin Dependency**: If Avante plugin is still loaded, undefined command errors may occur
2. **Global Keybindings**: Check for any global `<C-c>` or similar Avante toggle bindings in keymaps.lua
3. **Autocmds**: Verify no Avante-specific autocmds in autocmds.lua that reference these mappings
4. **Documentation**: Update nvim/docs/KEYBINDINGS.md to reflect Avante removal

## Related Files Requiring Updates

### Primary Files
1. **/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua** (Lines 260-265) - Target file for commenting

### Secondary Files (Verification Needed)
2. **/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua** - Check for global Avante keybindings
3. **/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua** - Check for Avante autocmds
4. **/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua** - Check if Avante plugin loaded
5. **/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua** - Avante plugin config (may need commenting)

### Documentation Files
6. **/home/benjamin/.config/nvim/docs/KEYBINDINGS.md** - Update to reflect Avante removal
7. **/home/benjamin/.config/nvim/docs/MAPPINGS.md** - Update AI/Assistant section

## Validation Checklist

After commenting out Avante mappings:

- [ ] Run `:source %` in which-key.lua to reload config
- [ ] Execute `:checkhealth which-key` to verify no syntax errors
- [ ] Test `<leader>a` popup shows remaining AI commands (Claude, Goose, Lectic)
- [ ] Verify no errors in `:messages` log related to undefined Avante commands
- [ ] Check which-key popup no longer shows aa, ae, ap, am, ax in Avante context
- [ ] Confirm Claude commands (ac, as, av, aw, ar) still functional
- [ ] Confirm Goose commands (ag, ai, ao, af, ad, aA, aC, aR, ab, aq) still functional
- [ ] Verify Lectic commands (al, an, aP) show only in .lec and .md files

## Rollback Procedure

If Avante mappings need to be restored:

1. **Uncomment lines** 260-265 by removing `-- ` prefix
2. **Restore original header** on line 260
3. **Reload config**: `:source %`
4. **Verify functionality**: Test each Avante command

## Conclusion

Commenting out Avante mappings in which-key.lua is a straightforward task that frees up five prime ergonomic keys for Goose command optimization. The recommended approach uses single-line `--` comments to preserve code structure and enable easy rollback. This removal is a prerequisite for Phase 3 of the Leader A Mapping Rename implementation plan.

**Next Steps**: After commenting out Avante mappings, proceed with Phase 3 of the implementation plan to reassign these keys to high-frequency Goose commands, achieving optimal ergonomics and 100% Goose command coverage in the `<leader>a` namespace.
