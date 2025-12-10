# Mapping Renaming Strategy Research Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Mapping Renaming Strategy for `<leader>a` AI/Assistant Group
- **Report Type**: codebase analysis

## Executive Summary

The `<leader>a` AI/Assistant group currently contains 4 capital letter mappings (aP, aA, aC, aR) that violate the lowercase naming convention. Analysis reveals 5 available lowercase letters (h, j, k, u, z) for remapping. A mnemonic-based renaming strategy is proposed that preserves semantic meaning while adhering to consistent naming patterns.

## Findings

### Finding 1: Capital Letter Mappings Identified
- **Description**: Found 4 mappings in `<leader>a` group using capital letters, violating the lowercase convention
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 271, 369-373)
- **Evidence**:
  ```lua
  { "<leader>aP", "<cmd>LecticSelectProvider<CR>", desc = "provider select", icon = "󰚩", cond = is_lectic },
  { "<leader>aA", "<cmd>GooseModeAuto<CR>", desc = "goose auto mode", icon = "󰒓" },
  { "<leader>aC", "<cmd>GooseModeChat<CR>", desc = "goose chat mode", icon = "󰭹" },
  { "<leader>aR", function() require("neotex.plugins.ai.goose.picker").show_recipe_picker() end, desc = "goose run recipe (sidebar)", icon = "󰑮" },
  ```
- **Impact**: Inconsistent naming creates cognitive friction and violates established project standards for lowercase-only mappings

### Finding 2: Available Lowercase Letters
- **Description**: Systematic analysis reveals 5 unused lowercase letters available for remapping
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 244-417, `<leader>a` group)
- **Evidence**: Currently used lowercase letters: a, b, c, d, e, f, g, i, l, m, n, o, p, q, r, s, t, v, w, x, y. Available letters: h, j, k, u, z
- **Impact**: Limited options require careful mnemonic selection to avoid confusion with existing mappings

### Finding 3: Mnemonic Naming Best Practices
- **Description**: Industry best practices emphasize mnemonic consistency over strict alphabetical ordering
- **Location**: External research from Neovim community standards (SpaceVim, which-key.nvim documentation)
- **Evidence**: Common patterns include `g` for "goto", `f` for "find", `b` for "buffer". Some configs explicitly trade mnemonic purity for ergonomic convenience, acknowledging "few of these one-letter remaps have mnemonic meaning"
- **Impact**: Provides framework for balancing memorability with available letter constraints

## Recommendations

### 1. **Adopt Mnemonic-Based Renaming Strategy**
**Priority**: HIGH | **Rationale**: Preserves muscle memory and semantic clarity

Proposed mapping transitions:
- `<leader>aP` → `<leader>ak` ("provider select" → "k" for "konfig/config provider")
- `<leader>aA` → `<leader>au` ("goose auto mode" → "u" for "auto/unassisted")
- `<leader>aC` → `<leader>ah` ("goose chat mode" → "h" for "human/chat")
- `<leader>aR` → `<leader>aj` ("goose run recipe" → "j" for "job/recipe runner")

**Alternative consideration**: If mnemonic clarity is more important than preserving all 4 mappings:
- `<leader>aA` → `<leader>au` ("auto" mnemonic - STRONG)
- `<leader>aC` → `<leader>ah` ("human/chat" mnemonic - MODERATE, could also be "help")
- `<leader>aR` → `<leader>aj` ("job/run" mnemonic - WEAK, but distinct)
- `<leader>aP` → `<leader>ak` ("konfig" mnemonic - WEAK, consider reassigning to more critical command)

### 2. **Create Before/After Mapping Table for Implementation**

| Current Mapping | Command | Description | Proposed Mapping | Mnemonic Justification |
|-----------------|---------|-------------|------------------|------------------------|
| `<leader>aP` | `LecticSelectProvider` | provider select | `<leader>ak` | **K**onfig provider (weak, but distinct) |
| `<leader>aA` | `GooseModeAuto` | goose auto mode | `<leader>au` | **A**uto/unassisted mode (strong) |
| `<leader>aC` | `GooseModeChat` | goose chat mode | `<leader>ah` | **H**uman/chat interaction (moderate) |
| `<leader>aR` | `show_recipe_picker()` | goose run recipe | `<leader>aj` | **J**ob/recipe runner (weak) |

**Implementation notes**:
- Update which-key.lua lines 271, 369-373
- Search codebase for any documentation referencing old mappings
- Add deprecation notice in commit message
- Consider creating migration guide in CHANGELOG or documentation

### 3. **Establish Naming Convention Documentation**
**Priority**: MEDIUM | **Rationale**: Prevent future capital letter creep

Create explicit documentation in `nvim/CLAUDE.md` or `nvim/docs/KEYBINDINGS.md`:
- **Rule**: All `<leader>` mappings MUST use lowercase letters only
- **Rationale**: Consistency, muscle memory, avoiding Shift key overhead
- **Exception handling**: If capital letter is semantically critical (rare), document why lowercase alternative was rejected
- **Enforcement**: Add linting check or code review checklist item

### 4. **Consider Semantic Grouping for Future Mappings**
**Priority**: LOW | **Rationale**: Long-term maintainability

Available letters (h, j, k, u, z) analysis:
- **h**: Could also mean "help" or "history" (conflicts with `<leader>h` group)
- **j**: Commonly used for "down" motion in Vim, but context-dependent
- **k**: Commonly used for "up" motion in Vim, but context-dependent
- **u**: Strong mnemonic potential for "undo" (though `<leader>u` already taken for Telescope undo)
- **z**: Often associated with folding in Vim, available for unique functions

**Recommendation**: Document reserved mnemonics to guide future mapping decisions and avoid conflicts.

## References

### Codebase Files Analyzed
- /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 244-417) - Complete `<leader>a` AI/Assistant group mappings
- /home/benjamin/.config/.claude/specs/061_leader_a_mapping_rename/reports/003-unmapped-commands-inventory.md (lines 1-21) - Related goose.nvim command mapping research

### External Documentation
- [GitHub - folke/which-key.nvim](https://github.com/folke/which-key.nvim) - Official which-key.nvim documentation
- [Neovim for Beginners — Key Mappings and WhichKey | Medium](https://alpha2phi.medium.com/neovim-for-beginners-key-mappings-and-whichkey-31dbf58f9f87) - Key mapping best practices
- [Mnemonic key bindings navigation | SpaceVim](https://spacevim.org/mnemonic-key-bindings-navigation/) - Industry standard mnemonic patterns
- [NeoVim Cheat Sheet | GitHub Gist](https://gist.github.com/NMNMCC/f845b25d67be15a6f2fc99dc8bb7af08) - Common keybinding conventions

### Methodology
1. Grep pattern analysis to identify capital letter mappings: `<leader>a[A-Z]`
2. Systematic letter availability check: compared {a..z} against used lowercase letters
3. Web research on Neovim mnemonic naming conventions (2025 best practices)
4. Semantic analysis of command descriptions to propose mnemonic-preserving alternatives
