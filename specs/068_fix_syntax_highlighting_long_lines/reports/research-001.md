# Research Report: Task #68

**Task**: 68 - fix_syntax_highlighting_long_lines
**Started**: 2026-02-11T00:00:00Z
**Completed**: 2026-02-11T00:15:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: Neovim documentation, GitHub issues, local configuration analysis
**Artifacts**: - specs/068_fix_syntax_highlighting_long_lines/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- The syntax highlighting issue on long lines is caused by `synmaxcol=200` in the configuration, which limits highlighting to the first 200 columns
- Treesitter highlighting is designed to work around this limitation but may fall back to regex syntax when treesitter parsing fails
- The fix involves increasing `synmaxcol` for affected filetypes (like TypeScript) and ensuring treesitter is properly active
- The configuration already has a pattern for this in `after/ftplugin/tex.lua` where `synmaxcol=0` is set for LaTeX files

## Context and Scope

The user reports that syntax highlighting gets interrupted on long lines in Neovim, particularly visible in TypeScript files where string highlighting cuts off partway through wrapped lines. The configuration uses:
- `synmaxcol=200` as a global performance optimization
- nvim-treesitter for syntax highlighting (which should bypass `synmaxcol`)
- snacks.nvim bigfile module (currently disabled)

## Findings

### Existing Configuration

**Current synmaxcol setting** (`lua/neotex/config/options.lua:161`):
```lua
vim.opt.synmaxcol = 200
```

This setting limits traditional regex-based syntax highlighting to the first 200 columns of each line. This is a performance optimization to prevent slowdowns on files with very long lines.

**Existing workaround pattern** (`after/ftplugin/tex.lua:74`):
```lua
vim.opt_local.synmaxcol = 0  -- 0 means no limit
```

LaTeX files already have an override that sets `synmaxcol=0` (no limit) for better syntax highlighting in that filetype.

**Related performance settings** (`lua/neotex/config/options.lua:164`):
```lua
vim.opt.redrawtime = 1500
```

This limits the time spent on syntax highlighting per redraw to 1500ms.

### Treesitter Configuration

The treesitter configuration (`lua/neotex/plugins/editor/treesitter.lua`) properly enables treesitter highlighting via `vim.treesitter.start(args.buf)`. The TypeScript parser is not explicitly listed in the auto-install parsers list, which may cause it to use regex-based syntax instead.

Current parsers list does NOT include TypeScript:
```lua
local parsers = {
  "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
  "python", "bash", "nix", "json", "yaml", "toml", "gitignore",
  "c", "haskell", "css", "html", "javascript", "scss", "regex",
  "typst", "astro",
}
```

### Root Cause Analysis

The issue occurs because:

1. **synmaxcol limitation**: The global `synmaxcol=200` limits regex-based syntax highlighting to 200 columns
2. **Treesitter fallback**: When treesitter highlighting is not active (e.g., parser not installed), Neovim uses regex-based syntax which respects `synmaxcol`
3. **Missing TypeScript parser**: The TypeScript parser is not in the auto-install list, potentially causing fallback to regex syntax

According to [Neovim Issue #26306](https://github.com/neovim/neovim/issues/26306), this is a known limitation: "When a line has length > synmaxcol, and it's set to nowrap, the syntax highlighting of the next lines becomes wrong." The Neovim maintainer's recommended solution is to use treesitter: "our answer to this is to outsource this problem to treesitter."

### Community Patterns

**snacks.nvim bigfile module** (already in config but disabled):
The configuration has `snacks.nvim` with a bigfile module that can automatically disable treesitter for large files to prevent performance issues:
```lua
bigfile = {
  enabled = false,  -- Currently disabled
  notify = true,
  size = 100 * 1024,   -- 100 KB
},
```

**Bigfile plugins** like `nvim-bigfile` and `bigfile.nvim` can automatically disable treesitter highlighting for files above a certain size threshold.

### Recommendations

1. **Add TypeScript/TSX parsers to treesitter config**:
   Add `"typescript"` and `"tsx"` to the parsers list in `lua/neotex/plugins/editor/treesitter.lua`

2. **Create ftplugin override for TypeScript**:
   Following the pattern from `after/ftplugin/tex.lua`, create `after/ftplugin/typescript.lua` with:
   ```lua
   vim.opt_local.synmaxcol = 0  -- No limit for TypeScript files
   ```

3. **Consider increasing global synmaxcol**:
   Alternatively, increase the global `synmaxcol` to a higher value like 500 or 1000 (balance between performance and functionality)

4. **Enable snacks.nvim bigfile module**:
   Enable the bigfile module to automatically handle performance for very large files while allowing full highlighting for normal files:
   ```lua
   bigfile = {
     enabled = true,
     size = 100 * 1024,
     line_length = 1000,
   },
   ```

5. **Verify treesitter is active**:
   Check if treesitter highlighting is actually being used for TypeScript files with `:InspectTree` or by checking for treesitter captures at cursor position

## Decisions

- Primary solution: Add TypeScript parsers to treesitter and create ftplugin override for TypeScript files
- Secondary solution: Increase global `synmaxcol` if treesitter solution is insufficient
- Optional: Enable snacks.nvim bigfile module for performance protection on very large files

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Performance degradation with synmaxcol=0 | Use ftplugin to limit scope to specific filetypes |
| Large TypeScript files may cause slowdown | Enable snacks.nvim bigfile module as fallback |
| Treesitter parser installation may fail | Keep regex syntax as automatic fallback |

## Appendix

### Search Queries Used
- "Neovim synmaxcol syntax highlighting stops long lines treesitter 2025"
- "Neovim treesitter disable highlighting long lines slow performance"
- "nvim-treesitter disable for large files bigfile performance 2024"

### References
- [Neovim Issue #26306: Vim syntax highlighting broken after long line](https://github.com/neovim/neovim/issues/26306)
- [nvim-treesitter Issue #1708: disable treesitter on bigfile](https://github.com/nvim-treesitter/nvim-treesitter/issues/1708)
- [snacks.nvim bigfile documentation](https://github.com/folke/snacks.nvim/blob/main/docs/bigfile.md)
- [Neovim Treesitter Documentation](https://neovim.io/doc/user/treesitter.html)
- [Neovim Syntax Documentation (synmaxcol)](https://neovim.io/doc/user/syntax.html)

### Relevant Configuration Files
- `/home/benjamin/.config/nvim/lua/neotex/config/options.lua` - Global options including synmaxcol
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/treesitter.lua` - Treesitter configuration
- `/home/benjamin/.config/nvim/after/ftplugin/tex.lua` - Example of synmaxcol override pattern
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/snacks/init.lua` - snacks.nvim configuration with bigfile module
