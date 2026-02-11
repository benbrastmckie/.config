# Research Report: Task #57

**Task**: 57 - Fix leader-ls keybinding not working in LaTeX files
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:45:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: VimTeX documentation, local Neovim configuration files, web search
**Artifacts**: - This report
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- The `<leader>ls` keybinding IS correctly defined and working
- The issue is that `VimtexToggleMain` does nothing when invoked from the main file (LogosReference.tex)
- The mapping exists in `after/ftplugin/tex.lua` but is missing from the main `which-key.lua` configuration
- User likely expected visual feedback when the command has no effect

## Context and Scope

The user reported that `<leader>ls` "does nothing" when triggered in `/home/benjamin/Projects/Logos/Theory/latex/LogosReference.tex`. This investigation checked:
1. Whether the keybinding is defined
2. Whether the command exists
3. Whether the command executes
4. Why there's no visible effect

## Findings

### Existing Configuration

**Keybinding Location**: `after/ftplugin/tex.lua:108`
```lua
{ "<leader>ls", "<cmd>VimtexToggleMain<CR>", desc = "subfile toggle", icon = "...", buffer = 0 },
```

**VimTeX Configuration**: `lua/neotex/plugins/text/vimtex.lua`
- VimTeX is properly configured with `vimtex_mappings_enabled = false` (custom mappings)
- Compiler is set to latexmk with xelatex
- Build directory is set to 'build'

### Verification Results

1. **Command Existence**: `VimtexToggleMain` command exists (verified: `:VimtexToggleMain` returns code 2)
2. **Mapping Registration**: The `<leader>ls` mapping is registered and has description "subfile toggle"
3. **Command Execution**: The command executes successfully without errors

### Root Cause Analysis

The `VimtexToggleMain` command is designed for **subfile workflows**. According to [VimTeX documentation](https://github.com/lervag/vimtex):

> "If one uses the `subfiles` package, the |:VimtexToggleMain| command is particularly useful."

The command toggles between:
- Treating the current file as a **subfile** (compiles standalone)
- Treating the current file as part of the **main project** (compiles via main document)

**When invoked from the MAIN file (LogosReference.tex)**:
- There is no toggle to perform
- The command executes but has no effect
- No notification or feedback is provided

**When invoked from a SUBFILE (e.g., 01-Introduction.tex)**:
- Toggles compilation target between subfile and main document
- Provides meaningful behavior

### Missing from which-key.lua

The main `which-key.lua` configuration (lines 506-523) defines LaTeX mappings but **does NOT include `<leader>ls`**:

| In ftplugin/tex.lua | In which-key.lua |
|---------------------|------------------|
| `<leader>la` | `<leader>la` |
| `<leader>lb` | `<leader>lb` |
| `<leader>lc` | `<leader>lc` |
| `<leader>ld` | NOT PRESENT |
| `<leader>le` | `<leader>le` |
| `<leader>lf` | `<leader>lf` |
| `<leader>lg` | `<leader>lg` |
| `<leader>lh` | NOT PRESENT |
| `<leader>li` | `<leader>li` |
| `<leader>lk` | `<leader>lk` |
| `<leader>lm` | `<leader>lm` |
| `<leader>ls` | NOT PRESENT |
| `<leader>lv` | `<leader>lv` |
| `<leader>lw` | `<leader>lw` |
| `<leader>lx` | `<leader>lx` |

The duplication creates potential confusion:
- Both files register the same `<leader>l` group
- ftplugin uses `buffer = 0` (buffer-local)
- which-key.lua uses `cond = is_latex` (global with condition)

### Documentation Reference

From [MAPPINGS.md](file:///home/benjamin/.config/nvim/docs/MAPPINGS.md), there's a documentation mismatch:
- Line 272 shows `<leader>ls` as "Sync cursor (web)" - this is for **Typst**, not LaTeX
- The LaTeX section doesn't document `<leader>ls`

## Recommendations

### Option A: Add Notification Feedback (Preferred)
Modify the keybinding to provide feedback when there's no toggle to perform:

```lua
{ "<leader>ls", function()
  local ok, err = pcall(vim.cmd, 'VimtexToggleMain')
  if not ok then
    vim.notify("VimtexToggleMain failed: " .. tostring(err), vim.log.levels.ERROR)
  else
    -- Check if we're in main file
    local vimtex = vim.b.vimtex
    if vimtex and vimtex.tex == vim.fn.expand('%:p') then
      vim.notify("Already in main file - open a subfile to toggle", vim.log.levels.INFO)
    else
      vim.notify("Toggled to: " .. (vimtex and vimtex.tex or "unknown"), vim.log.levels.INFO)
    end
  end
end, desc = "subfile toggle", icon = "...", buffer = 0 },
```

### Option B: Consolidate Keymaps
Move all LaTeX keymaps to one location (either ftplugin or which-key.lua) to avoid duplication and ensure consistency.

### Option C: Add to which-key.lua
Add the missing `<leader>ls` mapping to `which-key.lua` to ensure it appears in the which-key popup:

```lua
{ "<leader>ls", "<cmd>VimtexToggleMain<CR>", desc = "subfile toggle", icon = "...", cond = is_latex },
```

### Update Documentation
Update `docs/MAPPINGS.md` to:
1. Add `<leader>ls` to the LaTeX section with description "Toggle main/subfile compilation target"
2. Clarify that this is for subfile workflows

## Decisions

1. The keymap IS working correctly - this is not a bug
2. User expectation management is the issue - command has no visible effect on main file
3. Adding notification feedback would improve UX

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| User confusion about when to use command | Add notification explaining context |
| Duplicate keymap definitions | Consolidate to single location |
| Missing from which-key popup | Add to which-key.lua or document behavior |

## Appendix

### Search Queries Used
- "VimtexToggleMain command vimtex neovim 2025"
- Pattern searches: `<leader>ls`, `VimtexToggleMain`, `group = "latex"`

### References
- [VimTeX Documentation](https://github.com/lervag/vimtex/blob/master/doc/vimtex.txt)
- [VimTeX GitHub Issues #1461](https://github.com/lervag/vimtex/issues/1461) - Related toggle behavior
- Local files: `after/ftplugin/tex.lua`, `lua/neotex/plugins/text/vimtex.lua`, `lua/neotex/plugins/editor/which-key.lua`

### Verified Test Results
```
VimtexToggleMain command exists: 2
Found mapping: lhs= ls desc=subfile toggle
Before toggle:
  main file: /home/benjamin/Projects/Logos/Theory/latex/LogosReference.tex
  root: /home/benjamin/Projects/Logos/Theory/latex
VimtexToggleMain executed successfully
After toggle:
  main file: /home/benjamin/Projects/Logos/Theory/latex/LogosReference.tex
  root: /home/benjamin/Projects/Logos/Theory/latex
```

The command executed but produced no change because we were already in the main file.
