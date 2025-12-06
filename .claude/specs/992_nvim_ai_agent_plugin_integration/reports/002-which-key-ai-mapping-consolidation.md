# Research Report: Neovim AI Keybinding Consolidation to which-key.lua

## Research Metadata

**Date**: 2025-12-05
**Research Topic**: Consolidate AI-related keybindings into which-key.lua with `<leader>a` prefix
**Research Complexity**: 2
**Output Directory**: /home/benjamin/.config/.claude/specs/992_nvim_ai_agent_plugin_integration/reports
**Workflow Type**: research-and-revise
**Existing Plan**: /home/benjamin/.config/.claude/specs/992_nvim_ai_agent_plugin_integration/plans/001-nvim-ai-agent-plugin-integration-plan.md

---

## Executive Summary

This report provides a comprehensive analysis of the current AI-related keybindings in the Neovim configuration and identifies which mappings need to be consolidated into `which-key.lua` under the `<leader>a` namespace. The analysis reveals that **most AI mappings are already centralized in which-key.lua**, with a few exceptions that need consolidation.

### Key Findings

1. **which-key.lua Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
2. **Current `<leader>a` Usage**: 14 letters already in use (a, c, e, l, m, n, p, P, r, s, t, v, w, x, y)
3. **Available Letters**: 12 letters available for new mappings (b, d, f, g, h, i, j, k, o, q, u, z)
4. **AI Plugins Identified**: 4 main AI systems (Claude Code, Avante, Lectic, MCP-Hub)
5. **Keybindings to Migrate**: 4 global keybindings currently in keymaps.lua need consolidation

---

## Current `<leader>a` Mapping Analysis

### Already Defined in which-key.lua (Lines 244-361)

The `<leader>a` group is already well-structured in which-key.lua with the following mappings:

#### Core AI Commands

| Mapping | Mode | Description | Plugin | Line |
|---------|------|-------------|--------|------|
| `<leader>a` | n, v | AI group header | which-key | 245 |
| `<leader>ac` | n | Claude commands picker | Claude Code | 248 |
| `<leader>ac` | v | Send selection to Claude with prompt | Claude Code | 249-254 |
| `<leader>as` | n | Claude sessions picker | Claude Code | 255 |
| `<leader>av` | n | View worktrees | Claude Code | 256 |
| `<leader>aw` | n | Create worktree | Claude Code | 257 |
| `<leader>ar` | n | Restore closed worktree | Claude Code | 258 |

#### Avante AI Commands

| Mapping | Mode | Description | Plugin | Line |
|---------|------|-------------|--------|------|
| `<leader>aa` | n | Avante ask | Avante | 261 |
| `<leader>ae` | v | Avante edit selection | Avante | 262 |
| `<leader>ap` | n | Avante provider select | Avante | 263 |
| `<leader>am` | n | Avante model select | Avante | 264 |
| `<leader>ax` | n | MCP Hub open | MCP-Hub | 265 |

#### Lectic AI Commands (Conditional - .lec/.md files only)

| Mapping | Mode | Description | Plugin | Line |
|---------|------|-------------|--------|------|
| `<leader>al` | n | Lectic run | Lectic | 268 |
| `<leader>al` | v | Lectic submit selection | Lectic | 269 |
| `<leader>an` | n | New Lectic file | Lectic | 270 |
| `<leader>aP` | n | Lectic provider select | Lectic | 271 |

#### Utility Commands

| Mapping | Mode | Description | Function | Line |
|---------|------|-------------|----------|------|
| `<leader>at` | n | Toggle TTS (project-specific) | Custom toggle function | 274-301 |
| `<leader>ay` | n | Toggle yolo mode (permissions) | Custom toggle function | 304-360 |

### Letter Usage Summary

**Used Letters** (14 total):
- **a**: Avante ask
- **c**: Claude commands
- **e**: Avante edit
- **l**: Lectic run
- **m**: Avante model
- **n**: New Lectic file
- **p**: Avante provider
- **P**: Lectic provider select (capital P)
- **r**: Restore worktree
- **s**: Claude sessions
- **t**: Toggle TTS
- **v**: View worktrees
- **w**: Create worktree
- **x**: MCP Hub
- **y**: Yolo mode toggle

**Available Letters** (12 total):
- **b, d, f, g, h, i, j, k, o, q, u, z**

---

## Global AI Keybindings (Currently in keymaps.lua)

### Location: `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`

These global keybindings are defined in `keymaps.lua` (lines 290-317) and should potentially be consolidated:

| Mapping | Mode | Description | Plugin | Lines |
|---------|------|-------------|--------|-------|
| `<C-c>` | n, i, v, t | Toggle Claude Code (smart session) | Claude Code | 297-311 |
| `<C-g>` | n, i, v, t | Toggle Avante | Avante | 314-317 |

**Note**: These are global control-key bindings, NOT leader-key bindings. They are intentionally kept separate from the `<leader>a` namespace for quick access.

---

## AI Plugin File Analysis

### 1. Claude Code (`claudecode.lua`)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`

**Configuration**:
- Keymaps explicitly disabled in plugin opts (lines 48-59)
- All keybindings centralized in which-key.lua
- Commands: `ClaudeCommands`, `ClaudeSessions`, `ClaudeWorktree`, `ClaudeRestoreWorktree`

**Status**: ✓ Already centralized in which-key.lua

### 2. Avante AI (`avante.lua`)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua`

**Configuration**:
- Commands: `AvanteAsk`, `AvanteEdit`, `AvanteProvider`, `AvanteModel`, `MCPHubOpen`
- Buffer-specific keymaps defined via `set_avante_keymaps()` in keymaps.lua (lines 218-245)
- Global toggle: `<C-g>` in keymaps.lua

**Status**: ✓ Already centralized in which-key.lua (leader-based commands)

### 3. Lectic (`lectic.lua`)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/lectic.lua`

**Configuration**:
- Commands: `Lectic`, `LecticCreateFile`, `LecticSubmitSelection`, `LecticSelectProvider`
- Filetype-specific (`.lec`, `.md` files only)
- Uses `cond = is_lectic` to show only when relevant

**Status**: ✓ Already centralized in which-key.lua with conditional visibility

### 4. MCP-Hub (`mcp-hub.lua`)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/mcp-hub.lua`

**Configuration**:
- Command: `MCPHubOpen`
- Keys removed from plugin spec (line 32 comment)
- Managed by which-key.lua

**Status**: ✓ Already centralized in which-key.lua

---

## Recommendations for Plan Revision

### 1. Current State Assessment

**FINDING**: The Neovim configuration is already well-organized with most AI keybindings centralized in which-key.lua. The original plan assumption that keybindings are scattered across plugin files is **incorrect**.

### 2. Recommended Actions

#### Option A: Minimal Changes (RECOMMENDED)

Since most AI keybindings are already centralized, the plan should focus on:

1. **Add goose.nvim mappings to which-key.lua**
   - Use available letters: `<leader>ag` for "goose" operations
   - Reserve multiple letters if needed (e.g., `g`, `o`, `i` for different goose commands)
   - Follow existing pattern with conditional visibility if needed

2. **Keep global toggles in keymaps.lua**
   - `<C-c>` (Claude Code) and `<C-g>` (Avante) are intentionally global
   - These provide quick access without leader key prefix
   - No migration needed

3. **Document the structure**
   - Update plan to reflect that AI keybindings are already centralized
   - Explain the two-tier structure: leader-based (which-key.lua) + global (keymaps.lua)

#### Option B: Full Consolidation (NOT RECOMMENDED)

Move global toggles (`<C-c>`, `<C-g>`) to which-key.lua as well:

**Pros**:
- All AI keybindings in one file
- Easier discovery

**Cons**:
- Loses quick-access convenience (requires leader key)
- Global control-key bindings are a standard pattern for frequently-used commands
- Would require adding `<C-*>` support to which-key.lua (not typical usage)

### 3. Suggested Mapping Allocation for goose.nvim

Based on the plan, goose.nvim will need multiple keybindings. Recommended allocation:

| Letter | Mapping | Description | Status |
|--------|---------|-------------|--------|
| `g` | `<leader>ag` | Toggle goose interface | Available |
| `i` | `<leader>ai` | Goose input/prompt | Available |
| `o` | `<leader>ao` | Goose output window | Available |
| `f` | `<leader>af` | Goose fullscreen | Available |
| `d` | `<leader>ad` | Goose diff view | Available |
| `q` | `<leader>aq` | Close goose | Available |

**Alternative**: Use a sub-group approach
- `<leader>ag` → goose group (displays sub-menu)
  - `<leader>agg` → toggle
  - `<leader>agi` → input
  - `<leader>ago` → output
  - etc.

### 4. Essential vs Clutter Prevention

To avoid clutter, focus on **essential operations only**:

**Essential (should be in which-key.lua)**:
- Toggle/open interface
- Focus input window
- View output/diff
- Close/quit
- Provider/model selection (if relevant)

**Non-Essential (document but don't map)**:
- Buffer-local keymaps (defined in goose buffer context)
- Rare operations (accessible via commands)
- Advanced features (documented for power users)

---

## Conflict Analysis

### No Conflicts Detected

The following letters are **available** for new goose.nvim mappings:
- **b, d, f, g, h, i, j, k, o, q, u, z**

### Existing Mappings to Preserve

Do NOT reassign these letters:
- `a` → Avante ask
- `c` → Claude commands
- `e` → Avante edit
- `l` → Lectic run
- `m` → Avante model
- `n` → New Lectic file
- `p` → Avante provider
- `P` → Lectic provider (capital)
- `r` → Restore worktree
- `s` → Claude sessions
- `t` → Toggle TTS
- `v` → View worktrees
- `w` → Create worktree
- `x` → MCP Hub
- `y` → Yolo mode

---

## Implementation Guidance

### Step 1: Update goose.nvim Configuration

**Location**: Create `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`

**Key Changes**:
```lua
return {
  "azorng/goose.nvim",
  -- ... other config ...
  opts = {
    -- Disable default keymaps
    default_global_keymaps = false,
  },
  -- Empty keys table (managed by which-key.lua)
  keys = {},
}
```

### Step 2: Add Mappings to which-key.lua

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`

**Add after line 265** (after `<leader>ax` MCP Hub mapping):

```lua
-- Goose AI commands
{ "<leader>ag", "<cmd>GooseToggle<CR>", desc = "goose toggle", icon = "󰚩" },
{ "<leader>ai", "<cmd>GooseOpenInput<CR>", desc = "goose input", icon = "󰭹" },
{ "<leader>ao", "<cmd>GooseOpenOutput<CR>", desc = "goose output", icon = "󰆍" },
{ "<leader>af", "<cmd>GooseToggleFullscreen<CR>", desc = "goose fullscreen", icon = "󰊓" },
{ "<leader>ad", "<cmd>GooseDiffOpen<CR>", desc = "goose diff", icon = "󰦓" },
{ "<leader>aq", "<cmd>GooseClose<CR>", desc = "goose close", icon = "󰅖" },
```

### Step 3: Document the Structure

Add comments to which-key.lua explaining the organization:

```lua
-- ============================================================================
-- <leader>a - AI/ASSISTANT GROUP
-- ============================================================================
-- ORGANIZATIONAL NOTES:
-- - All leader-based AI keybindings are centralized here
-- - Global toggles (<C-c>, <C-g>) remain in keymaps.lua for quick access
-- - Plugin specs should have empty keys = {} tables
-- - Conditional mappings use cond = function() for filetype-specific features
-- ============================================================================
```

---

## Testing Checklist

After implementing changes:

- [ ] All existing `<leader>a*` mappings still work
- [ ] New goose.nvim mappings work correctly
- [ ] No keybinding conflicts reported by which-key
- [ ] `:verbose map <leader>a` shows all mappings
- [ ] Global toggles (`<C-c>`, `<C-g>`) still work
- [ ] Conditional mappings (Lectic) only appear in correct filetypes
- [ ] Goose plugin loads lazily (no startup impact)
- [ ] which-key menu displays correct icons and descriptions

---

## References

### Files Analyzed

1. `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (Lines 244-361)
2. `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua` (Lines 290-317)
3. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`
4. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua`
5. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/lectic.lua`
6. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/mcp-hub.lua`

### Existing Plan Reference

- [001-nvim-ai-agent-plugin-integration-plan.md](../plans/001-nvim-ai-agent-plugin-integration-plan.md)

---

## Appendix: Complete `<leader>a` Mapping Table

### Normal Mode Mappings

| Key | Description | Plugin | Mode | Conditional |
|-----|-------------|--------|------|-------------|
| `<leader>aa` | Avante ask | Avante | n | - |
| `<leader>ac` | Claude commands | Claude Code | n | - |
| `<leader>ae` | Avante edit | Avante | v | - |
| `<leader>al` | Lectic run | Lectic | n | is_lectic |
| `<leader>am` | Avante model | Avante | n | - |
| `<leader>an` | New Lectic file | Lectic | n | is_lectic |
| `<leader>ap` | Avante provider | Avante | n | - |
| `<leader>aP` | Lectic provider | Lectic | n | is_lectic |
| `<leader>ar` | Restore worktree | Claude Code | n | - |
| `<leader>as` | Claude sessions | Claude Code | n | - |
| `<leader>at` | Toggle TTS | Custom | n | - |
| `<leader>av` | View worktrees | Claude Code | n | - |
| `<leader>aw` | Create worktree | Claude Code | n | - |
| `<leader>ax` | MCP Hub | MCP-Hub | n | - |
| `<leader>ay` | Yolo mode | Custom | n | - |

### Visual Mode Mappings

| Key | Description | Plugin | Mode | Conditional |
|-----|-------------|--------|------|-------------|
| `<leader>ac` | Send to Claude with prompt | Claude Code | v | - |
| `<leader>ae` | Avante edit | Avante | v | - |
| `<leader>al` | Lectic selection | Lectic | v | is_lectic |

### Available for New Mappings

**b, d, f, g, h, i, j, k, o, q, u, z** (12 letters available)

---

## Conclusion

The current Neovim AI keybinding structure is **already well-organized** with most mappings centralized in which-key.lua. The plan should be revised to:

1. Focus on adding goose.nvim mappings using available letters (`g`, `i`, `o`, `f`, `d`, `q`)
2. Preserve existing structure (leader-based in which-key.lua, global toggles in keymaps.lua)
3. Keep only essential mappings to avoid clutter
4. Document the two-tier organizational pattern

**REPORT CREATED**: /home/benjamin/.config/.claude/specs/992_nvim_ai_agent_plugin_integration/reports/002-which-key-ai-mapping-consolidation.md
