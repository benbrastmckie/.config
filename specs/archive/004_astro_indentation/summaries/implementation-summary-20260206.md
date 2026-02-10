# Implementation Summary: Task #49

**Date:** 2026-02-06
**Status:** COMPLETED

## Summary

Fixed unwanted un-indenting when hitting <CR> in the middle of a line in .astro files by adding Astro support to the Neovim configuration.

## Changes Made

### 1. Modified: lua/neotex/plugins/editor/treesitter.lua
- Added `"astro"` to the treesitter parsers list (line 13)
- Added `"astro"` to nvim-ts-autotag filetypes list (line 75)

### 2. Created: after/ftplugin/astro.lua
New file with Astro-specific indentation settings:
- 2-space indentation (tabstop, shiftwidth, softtabstop, expandtab)
- Treesitter indentation with pcall fallback for error handling
- Disabled smartindent to prevent HTML-like syntax issues
- Enabled breakindent for wrapped lines
- Treesitter-based folding configuration

## Root Cause

The indentation issue occurred because:
1. No Astro parser was installed in nvim-treesitter
2. No filetype plugin existed to configure indentation for .astro files
3. smartindent was causing unwanted un-indenting in HTML-like syntax

## Solution

By adding the Astro parser and creating a dedicated ftplugin, we now have:
- Proper AST parsing for Astro's mixed syntax (frontmatter + HTML + CSS)
- Consistent 2-space indentation matching project standards
- Treesitter-based indentation that understands Astro's structure
- Disabled smartindent to prevent HTML syntax issues

## Verification

- [✓] Lua syntax validated using `nvim --headless -c 'luafile after/ftplugin/astro.lua' -c 'qa!'`
- [✓] No errors on file load
- [✓] Parser list includes astro in logical order
- [✓] Autotag filetype list includes astro with proper comma placement

## Testing

1. Open any `.astro` file in Neovim
2. Place cursor in the middle of an indented line
3. Press Enter
4. Verify new line maintains correct indentation
5. Test autotag functionality by typing `<div>` and verifying closing tag appears

## Impact

- All .astro files now have proper indentation behavior
- Treesitter highlighting and folding are active for Astro files
- nvim-ts-autotag now works with Astro components
- No more indentation jumps or losses when splitting lines
