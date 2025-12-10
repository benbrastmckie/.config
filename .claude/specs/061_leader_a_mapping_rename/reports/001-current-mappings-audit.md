# Current Mappings Audit Research Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Current <leader>a Mappings Audit
- **Report Type**: codebase analysis

## Executive Summary

The `<leader>a` prefix is heavily utilized for AI/assistant-related functionality, with 22 distinct mappings defined in which-key.lua. All mappings are consolidated in a single location with no duplicates elsewhere. Avante-related mappings (`<leader>aa`, `<leader>ae`, `<leader>ap`, `<leader>am`, `<leader>ax`) use 5 of the most accessible keys and are slated for removal, creating significant namespace availability for remapping Goose commands to more ergonomic positions.

## Findings

### Finding 1: Complete <leader>a Mapping Inventory
- **Description**: All `<leader>a` mappings are centralized in the which-key configuration with clear AI/assistant categorization. The namespace contains 22 mappings across multiple AI tools (Claude Code, Avante, Lectic, Goose).
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 244-417)
- **Evidence**: Mapping breakdown by tool:
  ```lua
  -- Claude AI commands (5 mappings)
  <leader>ac - Claude commands/send selection to claude
  <leader>as - Claude sessions
  <leader>av - View worktrees
  <leader>aw - Create worktree
  <leader>ar - Restore closed worktree

  -- Avante AI commands (5 mappings - BEING REMOVED)
  <leader>aa - Avante ask
  <leader>ae - Avante edit (visual mode)
  <leader>ap - Avante provider
  <leader>am - Avante model
  <leader>ax - MCP hub

  -- Lectic actions (3 mappings, filetype-conditional)
  <leader>al - Lectic run
  <leader>an - New lectic file
  <leader>aP - Provider select (uppercase P)

  -- Configuration toggles (2 mappings)
  <leader>at - Toggle TTS
  <leader>ay - Toggle yolo mode

  -- Goose AI commands (7 mappings)
  <leader>ag - Goose toggle
  <leader>ai - Goose input
  <leader>ao - Goose output
  <leader>af - Goose fullscreen
  <leader>ad - Goose diff
  <leader>aA - Goose auto mode (uppercase A)
  <leader>aC - Goose chat mode (uppercase C)
  <leader>aR - Goose run recipe (uppercase R)
  <leader>ab - Goose backend/provider
  <leader>aq - Goose quit
  ```
- **Impact**: The namespace is well-organized but 5 Avante mappings occupy prime positions (`aa`, `ae`, `ap`, `am`, `ax`) that could be reassigned to more frequently-used Goose commands.

### Finding 2: Avante Mappings Using Optimal Keys
- **Description**: Avante currently occupies 5 of the most ergonomic keys in the `<leader>a` namespace (double-tap `aa` and easily reachable home-row keys `ae`, `ap`, `am`, `ax`).
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 261-265)
- **Evidence**:
  ```lua
  { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "avante ask", icon = "󰚩" },
  { "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "avante edit", icon = "󱇧", mode = { "v" } },
  { "<leader>ap", "<cmd>AvanteProvider<CR>", desc = "avante provider", icon = "󰜬" },
  { "<leader>am", "<cmd>AvanteModel<CR>", desc = "avante model", icon = "󰡨" },
  { "<leader>ax", "<cmd>MCPHubOpen<CR>", desc = "mcp hub", icon = "󰚩" },
  ```
- **Impact**: Once Avante is removed, these optimal positions become available. The `<leader>aa` double-tap pattern is particularly valuable for high-frequency operations like Goose toggle, which currently uses `<leader>ag`.

### Finding 3: Current Goose Mappings Use Suboptimal Keys
- **Description**: Goose commands are scattered across less ergonomic keys, with the primary toggle using `<leader>ag` (requires reaching to 'g' key) and important functions using uppercase modifiers or distant keys.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 363-416)
- **Evidence**:
  ```lua
  -- Current Goose mappings with ergonomic assessment
  <leader>ag - Goose toggle          [distant 'g', not optimal for high-frequency use]
  <leader>ai - Goose input            [good position, home row]
  <leader>ao - Goose output           [acceptable, right hand home row]
  <leader>af - Goose fullscreen       [good position, home row]
  <leader>ad - Goose diff             [good position, home row]
  <leader>aA - Goose auto mode        [requires shift modifier]
  <leader>aC - Goose chat mode        [requires shift modifier]
  <leader>aR - Goose run recipe       [requires shift modifier]
  <leader>ab - Goose backend/provider [good position, but verbose implementation]
  <leader>aq - Goose quit             [edge of home row]
  ```
- **Impact**: Goose is the primary AI assistant but lacks ergonomic mapping for its most-used command (toggle). Remapping to available Avante keys would significantly improve workflow efficiency.

### Finding 4: No Global AI Toggle Conflicts
- **Description**: Global AI toggles are correctly separated from which-key leader mappings to avoid conflicts. Claude Code uses `<C-c>` and Avante uses `<C-g>`, with special handling for buffer-specific overrides.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua (lines 290-317)
- **Evidence**:
  ```lua
  -- Claude Code toggle (smart session management)
  -- Note: This global mapping is overridden by buffer-local mappings in:
  --   - Avante buffers (<C-c> clears chat history)
  --   - Telescope pickers (<C-c> closes picker)
  map("n", "<C-c>", function()
    require("neotex.plugins.ai.claude").smart_toggle()
  end, {}, "Toggle Claude Code")

  -- Avante toggle
  map("n", "<C-g>", "<cmd>AvanteToggle<CR>", {}, "Toggle Avante")
  ```
- **Impact**: The global toggle approach is working well and should be considered for Goose as well. Goose currently only has leader-key mappings, missing a convenient global toggle pattern.

### Finding 5: Mapping Pattern Consistency
- **Description**: The codebase follows a consistent pattern where uppercase letter suffixes indicate mode variations (e.g., `<leader>aA` for auto mode, `<leader>aC` for chat mode, `<leader>aR` for recipe runner) while lowercase letters are primary actions.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 369-373)
- **Evidence**:
  ```lua
  { "<leader>aA", "<cmd>GooseModeAuto<CR>", desc = "goose auto mode", icon = "󰒓" },
  { "<leader>aC", "<cmd>GooseModeChat<CR>", desc = "goose chat mode", icon = "󰭹" },
  { "<leader>aR", function()
    require("neotex.plugins.ai.goose.picker").show_recipe_picker()
  end, desc = "goose run recipe (sidebar)", icon = "󰑮" },
  ```
- **Impact**: When redesigning mappings, maintaining this pattern (lowercase for primary actions, uppercase for variations) will preserve consistency and user expectations. Consider using this pattern to minimize cognitive overhead during the transition.

### Finding 6: Filetype-Conditional Mappings Present
- **Description**: Some `<leader>a` mappings are filetype-conditional (Lectic mappings only appear in .lec and .md files), demonstrating that context-aware mapping is already implemented in the configuration.
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 268-271)
- **Evidence**:
  ```lua
  -- Lectic actions (only for .lec and .md files)
  { "<leader>al", "<cmd>Lectic<CR>", desc = "lectic run", icon = "󰊠", cond = is_lectic },
  { "<leader>al", "<cmd>LecticSubmitSelection<CR>", desc = "lectic selection", icon = "󰚟", mode = { "v" }, cond = is_lectic },
  { "<leader>an", "<cmd>LecticCreateFile<CR>", desc = "new lectic file", icon = "󰈙", cond = is_lectic },
  { "<leader>aP", "<cmd>LecticSelectProvider<CR>", desc = "provider select", icon = "󰚩", cond = is_lectic },
  ```
- **Impact**: This demonstrates that the `<leader>a` namespace can accommodate both universal and context-specific commands. When remapping, consider whether any Goose commands should be context-aware (e.g., project-specific recipe shortcuts).

## Recommendations

1. **Reassign Avante's Optimal Keys to High-Frequency Goose Commands**: Once Avante is removed, immediately reassign `<leader>aa` (double-tap) to Goose toggle, moving from the current `<leader>ag`. The double-tap pattern is ideal for the most frequent operation. Consider `<leader>ae` for Goose input, `<leader>am` for mode selection, and `<leader>ap` for provider selection to maintain semantic consistency with Avante's legacy naming.

2. **Consolidate Mode Selection Under Single Key**: The current pattern uses uppercase modifiers for mode variations (`<leader>aA`, `<leader>aC`). Consider consolidating these under a single key like `<leader>am` (reusing Avante's model key) that opens a picker for Auto/Chat mode selection, similar to the provider picker at `<leader>ab`. This reduces the number of mappings while improving discoverability.

3. **Evaluate Global Toggle for Goose**: Given the success of global toggles for Claude Code (`<C-c>`) and Avante (`<C-g>`), evaluate adding a global toggle for Goose (e.g., `<C-o>` for "Output"). This would complement the leader-key approach and provide quick access from any context. The current `<leader>ag` mapping could remain as a secondary option or be reassigned to a less-critical function.

## References

- /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 244-417) - Complete `<leader>a` mapping definitions
- /home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua (lines 290-317) - Global AI toggle definitions
- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua (lines 1-96) - Goose plugin configuration
- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua (lines 1-707) - Avante plugin configuration (being removed)
