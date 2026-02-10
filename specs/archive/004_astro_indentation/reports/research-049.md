# Research Report: Task #49 - Fix Astro Indentation on CR in Middle of Line

## Executive Summary

- **Issue**: When pressing `<CR>` (Enter) in the middle of a line in `.astro` files, text loses proper indentation
- **Root Cause**: The combination of `map_cr = false` in nvim-autopairs and missing treesitter configuration for astro files
- **Recommended Approach**: 
  1. Add `astro` to treesitter parsers list
  2. Create `after/ftplugin/astro.lua` with proper indentation settings
  3. Consider adjusting autopairs CR handling for astro files

## Existing Configuration

### Treesitter Setup (`lua/neotex/plugins/editor/treesitter.lua`)

Current parsers list (line 9-14):
```lua
local parsers = {
  "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
  "python", "bash", "nix", "json", "yaml", "toml", "gitignore",
  "c", "haskell", "css", "html", "javascript", "scss", "regex",
  "typst",
}
```

**Missing**: `astro` parser is not included in the auto-install list.

Treesitter indentation is enabled globally via autocmd (lines 36-39):
```lua
pcall(function()
  vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
```

### Autopairs Configuration (`lua/neotex/plugins/tools/autopairs.lua`)

Critical setting (line 24):
```lua
map_cr = false,  -- Don't map CR automatically (handled by blink.cmp integration)
```

The CR key is manually mapped (lines 106-117) to handle both completion and autopairs:
```lua
vim.keymap.set('i', '<CR>', function()
  if blink.is_visible() then
    blink.accept()
    return ''
  else
    local npairs = require('nvim-autopairs')
    return npairs.autopairs_cr()
  end
end, { expr = true, silent = true, noremap = true, replace_keycodes = false })
```

### Filetype Plugins (`after/ftplugin/`)

Current ftplugin files:
- `tex.lua` - LaTeX settings
- `markdown.lua` - Markdown settings
- `python.lua` - Python settings
- `lean.lua` - Lean settings
- `typst.lua` - Typst settings
- `lectic.markdown.lua` - Academic markdown

**Missing**: No `astro.lua` file exists.

## Plugin Analysis

### nvim-autopairs CR Behavior

According to nvim-autopairs documentation:
- `map_cr = true` (default): Automatically maps `<CR>` to handle line breaks between pairs
- `map_cr = false`: User must manually handle CR mapping
- `autopairs_cr()`: Returns the proper key sequence for breaking lines with indentation

The current setup uses `map_cr = false` with manual blink.cmp integration, which should work correctly. However, the issue likely stems from:
1. Missing astro treesitter parser causing incorrect indentexpr
2. No filetype-specific indentation settings for astro

### Treesitter Indentation for Astro

Astro files combine multiple languages:
- Frontmatter (TypeScript/JavaScript between `---` fences)
- HTML/JSX-like template syntax
- CSS in `<style>` tags

The treesitter astro parser provides indentation queries for these mixed contexts. Without the parser installed, nvim-treesitter cannot provide proper indentation.

### nvim-ts-autotag

Current configuration (`lua/neotex/plugins/editor/treesitter.lua`, lines 72-84):
```lua
{
  "windwp/nvim-ts-autotag",
  lazy = true,
  ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "markdown" },
  -- ...
}
```

**Missing**: `astro` is not in the filetype list for nvim-ts-autotag.

## Recommendations

### 1. Add Astro to Treesitter Parsers

Update `lua/neotex/plugins/editor/treesitter.lua`:
```lua
local parsers = {
  "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
  "python", "bash", "nix", "json", "yaml", "toml", "gitignore",
  "c", "haskell", "css", "html", "javascript", "scss", "regex",
  "typst", "astro",  -- Add astro parser
}
```

### 2. Create Astro Filetype Plugin

Create `after/ftplugin/astro.lua`:
```lua
-- Astro filetype settings
-- Fix indentation issues when pressing CR in middle of line

-- Use 2 spaces for indentation (consistent with project standards)
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.expandtab = true

-- Enable treesitter indentation if available
local ok, _ = pcall(function()
  vim.opt_local.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)

-- Fallback indentation settings if treesitter not available
if not ok then
  vim.opt_local.autoindent = true
  vim.opt_local.smartindent = false  -- smartindent can cause issues with HTML-like syntax
end

-- Disable smartindent which can cause un-indenting issues in HTML-like files
vim.opt_local.smartindent = false

-- Enable breakindent for better wrapped line display
vim.opt_local.breakindent = true
```

### 3. Add Astro to nvim-ts-autotag

Update `lua/neotex/plugins/editor/treesitter.lua`:
```lua
ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "markdown", "astro" },
```

### 4. Alternative: Check Autopairs CR Mapping

If issues persist after adding treesitter support, verify the autopairs CR mapping is working correctly for astro files. The current integration should work, but filetype-specific debugging may be needed.

## Dependencies

No additional plugins required. The fix uses existing infrastructure:
- nvim-treesitter (already installed)
- nvim-autopairs (already installed)
- nvim-ts-autotag (already installed)

## Implementation Steps

1. Add `astro` to treesitter parsers list
2. Create `after/ftplugin/astro.lua` with proper settings
3. Add `astro` to nvim-ts-autotag filetypes
4. Test in an .astro file by pressing Enter mid-line
5. Verify indentation is preserved correctly

## References

- [nvim-treesitter astro support](https://github.com/nvim-treesitter/nvim-treesitter/issues/1763)
- [nvim-autopairs CR mapping documentation](https://github.com/windwp/nvim-autopairs/wiki/Rules-API)
- [Astro indentation issues with treesitter](https://github.com/nvim-treesitter/nvim-treesitter/issues/7840)
