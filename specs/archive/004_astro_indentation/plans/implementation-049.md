# Implementation Plan: Task #49

## Overview

This plan addresses the Astro indentation issue when pressing `<CR>` (Enter) in the middle of a line in `.astro` files. The root cause is missing treesitter support for Astro files combined with the absence of filetype-specific indentation settings. The implementation adds the astro parser to treesitter, creates a dedicated ftplugin configuration, and enables autotag support for Astro files.

## Goals & Non-Goals

**Goals:**
- Add `astro` parser to nvim-treesitter auto-install list
- Create `after/ftplugin/astro.lua` with proper indentation settings
- Add `astro` to nvim-ts-autotag filetype list
- Ensure proper indentation behavior when pressing Enter mid-line in .astro files

**Non-Goals:**
- No changes to autopairs CR mapping (current setup is correct)
- No new plugin installations (uses existing infrastructure)
- No changes to other filetype configurations

## Implementation Phases

### Phase 1: Add Astro to Treesitter Parsers [NOT STARTED]

- **Goal:** Enable treesitter parsing and indentation for Astro files
- **Tasks:**
  - [ ] Edit `lua/neotex/plugins/editor/treesitter.lua`
  - [ ] Add `"astro"` to the parsers list (line 13, after `"typst"`)
- **Verification:**
  - [ ] File syntax is valid Lua
  - [ ] Parser list includes astro in alphabetical/logical order
- **Timing:** 5 minutes

### Phase 2: Create Astro Filetype Plugin [NOT STARTED]

- **Goal:** Provide filetype-specific indentation and formatting settings for Astro
- **Tasks:**
  - [ ] Create `after/ftplugin/astro.lua`
  - [ ] Set 2-space indentation (tabstop, shiftwidth, softtabstop, expandtab)
  - [ ] Enable treesitter indentation with pcall fallback
  - [ ] Disable smartindent to prevent HTML-like syntax issues
  - [ ] Enable breakindent for wrapped lines
- **Verification:**
  - [ ] File follows existing ftplugin patterns (see typst.lua, python.lua)
  - [ ] Uses vim.opt_local for buffer-local settings
  - [ ] Includes descriptive header comment
- **Timing:** 15 minutes

### Phase 3: Add Astro to nvim-ts-autotag [NOT STARTED]

- **Goal:** Enable automatic tag closing/renaming for Astro files
- **Tasks:**
  - [ ] Edit `lua/neotex/plugins/editor/treesitter.lua`
  - [ ] Add `"astro"` to nvim-ts-autotag ft list (line 75)
- **Verification:**
  - [ ] Filetype list includes astro
  - [ ] Syntax is valid (comma placement)
- **Timing:** 5 minutes

### Phase 4: Testing & Validation [NOT STARTED]

- **Goal:** Verify the fix works correctly in real Astro files
- **Tasks:**
  - [ ] Open an `.astro` file in Neovim
  - [ ] Press Enter in the middle of a line with indentation
  - [ ] Verify new line maintains proper indentation
  - [ ] Test in different contexts (frontmatter, HTML, style tags)
  - [ ] Verify treesitter highlighting is active (`:TSBufEnable highlight`)
- **Verification:**
  - [ ] Indentation preserved when splitting lines
  - [ ] No error messages on file open
  - [ ] Autotag functionality works (type `<div>` and verify closing tag)
- **Timing:** 10 minutes

## Testing & Validation

### Build Checks
- [ ] No Lua syntax errors in modified files
- [ ] Lazy.nvim loads without errors

### Manual Testing Steps
1. Open any `.astro` file (or create test file)
2. Place cursor in middle of an indented line (e.g., inside a component)
3. Press Enter
4. Verify new line has correct indentation level
5. Test in frontmatter section (between `---` fences)
6. Test in HTML template section
7. Test in `<style>` tags

### Expected Behavior
- New lines maintain proper indentation level
- Treesitter highlighting is active
- No indentation jumps or losses when pressing Enter

## Artifacts & Outputs

### Files to Modify
1. `lua/neotex/plugins/editor/treesitter.lua` - Add astro parser and autotag support

### Files to Create
1. `after/ftplugin/astro.lua` - Astro-specific settings

### Directory Structure
```
after/ftplugin/
├── astro.lua          [NEW]
├── lean.lua
├── lectic.markdown.lua
├── markdown.lua
├── python.lua
├── tex.lua
└── typst.lua
```

## Dependencies & Risks

**Dependencies:**
- nvim-treesitter (already installed)
- nvim-autopairs (already installed)
- nvim-ts-autotag (already installed)

**Risks:**
- **Low Risk:** Astro parser may not be available in older nvim-treesitter versions
  - Mitigation: pcall wrapping in ftplugin handles this gracefully
- **Low Risk:** Conflicts with existing HTML indentation settings
  - Mitigation: Filetype-specific settings override global defaults

## Rollback Plan

If issues occur:
1. Remove `after/ftplugin/astro.lua`
2. Revert changes to `lua/neotex/plugins/editor/treesitter.lua`
3. Restart Neovim

## References

- Research Report: `specs/049_astro_indentation/reports/research-049.md`
- nvim-treesitter astro support: https://github.com/nvim-treesitter/nvim-treesitter/issues/1763
- nvim-autopairs CR mapping: https://github.com/windwp/nvim-autopairs/wiki/Rules-API
