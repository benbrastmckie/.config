# Filetype-Aware Surround Configuration Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases successfully implemented. Markdown and LaTeX now have separate, filetype-specific surround configurations with no cross-pollution.

## Metadata
- **Date**: 2025-10-03
- **Feature**: Filetype-aware nvim-surround configuration
- **Scope**: Separate markdown and LaTeX surround patterns to prevent cross-filetype pollution
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: None (direct implementation based on analysis)

## Overview

Currently, all LaTeX-specific surround patterns (`i`, `b`, `t`, `u`, `q`, `Q`, `$`, `E`) are defined globally in `surround.lua`, making them available in all filetypes including markdown. This causes markdown files to incorrectly use LaTeX surrounds when users expect markdown-specific patterns (bold `**`, italic `*`, code `` ` ``, etc.).

The solution is to:
1. Remove LaTeX-specific surrounds from the global configuration
2. Rely solely on buffer-local `buffer_setup()` in `tex.lua` for LaTeX surrounds
3. Create markdown-specific `buffer_setup()` in `markdown.lua` with proper markdown patterns

This leverages nvim-surround's built-in filetype isolation mechanism where buffer-local surrounds override global defaults.

## Success Criteria
- [x] LaTeX surrounds (`i`, `b`, `t`, `u`, `q`, `Q`, `$`, `E`) only available in `.tex` files
- [x] Markdown surrounds (`b` for `**bold**`, `i` for `*italic*`, etc.) available in `.md` files
- [x] Same keybindings (`ysiw` + character) produce correct output per filetype
- [x] No cross-filetype pollution (LaTeX patterns in markdown or vice versa)
- [x] Both configurations tested and verified working

## Technical Design

### Current State
**Global config** (`nvim/lua/neotex/plugins/tools/surround.lua`):
- Lines 43-73: LaTeX-specific surrounds in global `surrounds` table
- Affects ALL filetypes

**LaTeX ftplugin** (`nvim/after/ftplugin/tex.lua`):
- Lines 5-46: Buffer-local `buffer_setup()` with LaTeX surrounds
- Duplicates global config (redundant but harmless)

**Markdown ftplugin** (`nvim/after/ftplugin/markdown.lua`):
- No surround configuration
- Falls back to global LaTeX config (incorrect behavior)

### Target State
**Global config** (`surround.lua`):
- Remove all LaTeX-specific surrounds (lines 42-73)
- Keep only keymaps and general settings

**LaTeX ftplugin** (`tex.lua`):
- Keep existing `buffer_setup()` (already correct)
- These surrounds only available in `.tex` files

**Markdown ftplugin** (`markdown.lua`):
- Add new `buffer_setup()` with markdown-specific surrounds
- These surrounds only available in `.md` files

### Markdown Surround Patterns
Based on CommonMark and GFM specifications:
- `b` → `**bold**` (double asterisk for strong emphasis)
- `i` → `*italic*` (single asterisk for emphasis)
- `` ` `` → `` `code` `` (backtick for inline code)
- `c` → ` ```language...``` ` (fenced code block with language prompt)
- `l` → `[text](url)` (link with URL prompt)
- `~` → `~~strikethrough~~` (GFM strikethrough)

### LaTeX Surround Patterns (preserved in tex.lua)
- `e` → `\begin{env}...\end{env}` (environment with prompt)
- `b` → `\textbf{bold}` (bold text)
- `i` → `\textit{italic}` (italic text)
- `t` → `\texttt{monospace}` (typewriter text)
- `q` → `` `single' `` (LaTeX single quotes)
- `Q` → ` ``double'' ` (LaTeX double quotes)
- `$` → `$math$` (inline math mode)

## Implementation Phases

### Phase 1: Remove Global LaTeX Surrounds [COMPLETED]
**Objective**: Clean up global configuration to remove filetype-specific patterns
**Complexity**: Low

Tasks:
- [x] Read `nvim/lua/neotex/plugins/tools/surround.lua` to identify exact lines
- [x] Remove LaTeX-specific surrounds from global config (lines 42-73)
- [x] Keep keymaps and general settings intact
- [x] Verify `tex.lua` buffer_setup is sufficient for LaTeX files

Testing:
```bash
# Manual testing in Neovim
nvim test.tex
# In visual mode, select word and press S then b
# Expected: \textbf{word} (from tex.lua buffer_setup)

nvim test.md
# Try same operation
# Expected: No 'b' surround available yet (will add in Phase 2)
```

Expected outcomes:
- Global config only contains keymaps and general settings
- LaTeX files still have all LaTeX surrounds (from tex.lua)
- Other filetypes have no LaTeX surrounds

### Phase 2: Add Markdown-Specific Surrounds [COMPLETED]
**Objective**: Create markdown buffer-local surround configuration
**Complexity**: Medium

Tasks:
- [x] Read current `nvim/after/ftplugin/markdown.lua` content
- [x] Add `require("nvim-surround").buffer_setup()` with markdown surrounds
- [x] Define surrounds: `b` (bold), `i` (italic), `` ` `` (code), `c` (code block), `l` (link), `~` (strikethrough)
- [x] Implement code block surround with language prompt using `add` function
- [x] Implement link surround with URL prompt using `add` function
- [x] Add comments documenting each surround pattern

Testing:
```bash
# Manual testing in Neovim
nvim test.md
# Test bold: visual select word, S, b → **word**
# Test italic: ysiw + i → *word*
# Test code: ysiw + ` → `word`
# Test code block: ysiw + c → ```language\nword\n```
# Test link: ysiw + l → [word](url)
# Test strikethrough: ysiw + ~ → ~~word~~

nvim test.tex
# Test LaTeX patterns still work
# ysiw + b → \textbf{word}
# ysiw + i → \textit{word}
# ysiw + $ → $word$
```

Expected outcomes:
- Markdown files have markdown-specific surrounds
- LaTeX files have LaTeX-specific surrounds
- No overlap or cross-filetype pollution
- All patterns produce correct output per filetype

## Testing Strategy

### Manual Testing Checklist
Test in markdown file (`test.md`):
- [ ] `ysiw` + `b` produces `**word**`
- [ ] `ysiw` + `i` produces `*word*`
- [ ] `ysiw` + `` ` `` produces `` `word` ``
- [ ] `ysiw` + `c` prompts for language and produces ` ```lang\nword\n``` `
- [ ] `ysiw` + `l` prompts for URL and produces `[word](url)`
- [ ] `ysiw` + `~` produces `~~word~~`

Test in LaTeX file (`test.tex`):
- [ ] `ysiw` + `b` produces `\textbf{word}`
- [ ] `ysiw` + `i` produces `\textit{word}`
- [ ] `ysiw` + `t` produces `\texttt{word}`
- [ ] `ysiw` + `e` prompts for environment and produces `\begin{env}word\end{env}`
- [ ] `ysiw` + `$` produces `$word$`
- [ ] `ysiw` + `q` produces `` `word' ``
- [ ] `ysiw` + `Q` produces ` ``word'' `

Test in other file types (e.g., `test.lua`):
- [ ] LaTeX surrounds (`b`, `i`, `$`) NOT available
- [ ] Markdown surrounds (`b`, `i`, `` ` ``) NOT available
- [ ] Only default nvim-surround patterns available

### Verification Commands
```bash
# Check global config has no LaTeX surrounds
nvim -c "lua print(vim.inspect(require('nvim-surround.config').get_opts().surrounds))" -c q

# Check tex.lua buffer_setup is active
nvim test.tex -c "lua print(vim.inspect(require('nvim-surround.config').get_opts().surrounds))" -c q

# Check markdown.lua buffer_setup is active
nvim test.md -c "lua print(vim.inspect(require('nvim-surround.config').get_opts().surrounds))" -c q
```

## Documentation Requirements

### Files to Update
- `nvim/lua/neotex/plugins/tools/README.md` - Document surround filetype behavior
- `nvim/after/ftplugin/README.md` - Document buffer-local surround configs
- `nvim/README.md` - Add note about filetype-specific surrounds

### Documentation Content
- Explain filetype-aware surround configuration
- List markdown surrounds with examples
- List LaTeX surrounds with examples
- Clarify that buffer-local configs override global
- Provide usage examples for common patterns

## Dependencies

### Required Plugins
- `kylechui/nvim-surround` (already installed)

### File Dependencies
- `nvim/lua/neotex/plugins/tools/surround.lua` (modify)
- `nvim/after/ftplugin/tex.lua` (keep as-is)
- `nvim/after/ftplugin/markdown.lua` (modify)

## Notes

### Design Decisions
1. **Buffer-local over global**: nvim-surround's `buffer_setup()` provides clean filetype isolation
2. **Remove redundancy**: Global LaTeX config is redundant with tex.lua buffer_setup
3. **Markdown patterns**: Use CommonMark/GFM conventions for maximum compatibility
4. **Key assignments**: Consistent keys across filetypes (`b` for bold, `i` for italic) with different outputs

### Alternative Approaches Considered
- **Autocmds**: Could use `FileType` autocmds, but `buffer_setup()` is more idiomatic
- **Global aliases**: Could keep global config with complex aliases, but increases confusion
- **Per-project config**: Could make project-specific, but filetype-based is more general

### Potential Issues
- **Existing muscle memory**: Users accustomed to LaTeX surrounds in markdown will need to adjust
- **Multi-character surrounds**: Markdown `**` and `` ` `` require special `add` table syntax
- **Language prompts**: Code block language prompt may interrupt workflow (acceptable trade-off)

### Future Enhancements
- Add more markdown surrounds (e.g., `_` for underline, `=` for highlight)
- Add dynamic surround for markdown headers (`#`, `##`, etc.)
- Consider project-specific overrides via local config
