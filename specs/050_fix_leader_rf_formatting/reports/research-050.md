# Research Report: Task #50

## Executive Summary

- **Primary Issue**: The `<leader>rf` formatting keymap is defined in `which-key.lua` but lacks proper filetype support for `.astro`, markdown, and other filetypes
- **Root Cause**: Missing `astro` filetype in `formatters_by_ft` configuration; keymap defined outside conform.nvim plugin spec
- **Key Finding**: The keymap calls `conform.format()` correctly, but formatters aren't configured for all filetypes
- **Recommended Approach**: Add missing filetypes to `formatters_by_ft`, ensure formatters are installed via Mason, and consider moving keymap to conform.nvim spec

## Existing Configuration

### Current Keymap Location
The `<leader>rf` keymap is defined in `lua/neotex/plugins/editor/which-key.lua` (line 592):

```lua
{ "<leader>rf", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "format", icon = "󰉣", mode = { "n", "v" } },
```

### Conform.nvim Configuration
Located in `lua/neotex/plugins/editor/formatting.lua`:

**Current `formatters_by_ft`:**
```lua
formatters_by_ft = {
  -- Lua
  lua = { "stylua" },
  
  -- Web development
  javascript = { "prettier" },
  typescript = { "prettier" },
  javascriptreact = { "prettier" },
  typescriptreact = { "prettier" },
  vue = { "prettier" },
  css = { "prettier" },
  html = { "prettier" },
  json = { "jq" },
  yaml = { "prettier" },
  markdown = { "prettier" },
  
  -- Python
  python = { "isort", "black" },
  
  -- C/C++
  c = { "clang_format" },
  cpp = { "clang_format" },
  
  -- Shell scripting
  sh = { "shfmt" },
  
  -- LaTeX
  tex = { "latexindent" },
  
  -- Special case: any filetype can use the defaults
  ["*"] = { "trim_whitespace", "trim_newlines" },
  
  -- Special filetype for when no filetype is detected
  ["_"] = { "trim_whitespace" },
}
```

**Missing Filetypes:**
- `astro` - Not configured (needed for .astro files)
- `svelte` - Not configured (though svelte files may use typescriptreact)
- `graphql` - Not configured
- `handlebars` - Not configured

### Mason Tool Installation
Located in `lua/neotex/plugins/lsp/mason.lua`:

Currently only installs:
- `isort` (Python)
- `black` (Python)
- `pylint` (Python)

**Missing formatter installations:**
- `prettier` or `prettierd` - For web development
- `jq` - For JSON formatting
- `shfmt` - For shell scripts
- `clang_format` - For C/C++
- `latexindent` - For LaTeX

### LSP Configuration
Located in `lua/neotex/plugins/lsp/lspconfig.lua`:

Currently configured LSP servers:
- `lua_ls` (Lua)
- `pyright` (Python)
- `texlab` (LaTeX)
- `tinymist` (Typst)

**Missing LSP servers for formatting fallback:**
- No Astro LSP configured (could use `astro-ls` or rely on TypeScript LSP)

## Plugin Analysis

### Conform.nvim Behavior

**How `conform.format()` works:**
1. Detects current buffer's filetype
2. Looks up formatters in `formatters_by_ft` for that filetype
3. If no formatters found, uses `lsp_fallback` option
4. If `lsp_fallback = true`, attempts to use LSP formatting
5. If no LSP available or LSP doesn't support formatting, fails silently

**Current Issues:**

1. **Astro files**: Filetype `astro` is not in `formatters_by_ft`, so conform doesn't know which formatter to use. Prettier supports Astro but needs to be configured.

2. **Markdown files**: Uses `prettier`, but prettier may not be installed via Mason. Also, markdown formatting can be tricky with embedded code blocks.

3. **Keymap Location**: The keymap is defined in `which-key.lua` rather than in the conform.nvim plugin spec. This works but is less maintainable.

4. **Formatter Availability**: Many formatters listed in `formatters_by_ft` are not auto-installed via Mason, leading to "formatter not found" errors.

### Prettier Configuration for Astro

Prettier supports Astro files with the following configuration:
```lua
astro = { "prettier" }
```

Prettier will automatically detect and format `.astro` files when the Astro plugin is available.

## Recommendations

### 1. Add Missing Filetypes to formatters_by_ft

Update `lua/neotex/plugins/editor/formatting.lua`:

```lua
formatters_by_ft = {
  -- Existing entries...
  
  -- Add astro support
  astro = { "prettier" },
  
  -- Add other missing web filetypes
  svelte = { "prettier" },
  graphql = { "prettier" },
  handlebars = { "prettier" },
  
  -- Ensure markdown uses prettier with proper settings
  markdown = { "prettier" },
  
  -- Add more filetypes as needed
  xml = { "prettier" },
}
```

### 2. Install Formatters via Mason

Update `lua/neotex/plugins/lsp/mason.lua` to include formatters:

```lua
ensure_installed = {
  -- Python (existing)
  "isort",
  "black",
  "pylint",
  
  -- Web development formatters
  "prettier",        -- or "prettierd" for better performance
  "jq",              -- JSON formatter
  "shfmt",           -- Shell formatter
  "clang-format",    -- C/C++ formatter
  "latexindent",     -- LaTeX formatter
  "stylua",          -- Lua formatter (if not using system version)
}
```

### 3. Consider Moving Keymap to Conform.nvim Spec

For better maintainability, move the keymap from `which-key.lua` to the conform.nvim plugin spec:

```lua
-- In lua/neotex/plugins/editor/formatting.lua
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre", "BufNewFile" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>rf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "Format buffer or selection"
    },
  },
  config = function()
    -- existing config...
  end,
}
```

### 4. Add LSP Fallback Configuration

For filetypes without formatters, ensure LSP formatting is available:

```lua
-- In lspconfig.lua, add astro LSP if needed
vim.lsp.config("astro", {
  cmd = { "astro-ls", "--stdio" },
  filetypes = { "astro" },
  root_markers = { "astro.config.mjs", "astro.config.js", ".git" },
  capabilities = capabilities,
})

vim.lsp.enable({ "lua_ls", "pyright", "texlab", "tinymist", "astro" })
```

### 5. Add Format-on-Save Toggle

The existing `FormatToggle` command is good, but consider adding it to which-key for discoverability:

```lua
{ "<leader>rF", "<cmd>FormatToggle<CR>", desc = "toggle format on save" }
```

## Dependencies

### Required Mason Packages

Add these to `ensure_installed` in mason.lua:

| Package | Purpose | Filetypes |
|---------|---------|-----------|
| `prettier` | Code formatting | js, ts, jsx, tsx, vue, css, html, json, yaml, md, astro |
| `jq` | JSON formatting | json |
| `shfmt` | Shell formatting | sh, bash |
| `clang-format` | C/C++ formatting | c, cpp |
| `latexindent` | LaTeX formatting | tex |

### Optional: Prettierd

Consider using `prettierd` instead of `prettier` for better performance:
```lua
javascript = { "prettierd", "prettier", stop_after_first = true }
```

## Testing Checklist

After implementation, test the `<leader>rf` keymap in:

- [ ] `.astro` files - Should format with prettier
- [ ] `.md` files - Should format with prettier
- [ ] `.lua` files - Should format with stylua
- [ ] `.py` files - Should format with isort + black
- [ ] `.js/.ts` files - Should format with prettier
- [ ] `.json` files - Should format with jq
- [ ] Files without formatters - Should fall back to LSP if available

## References

- [conform.nvim documentation](https://github.com/stevearc/conform.nvim)
- [conform.nvim formatters list](https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters)
- [LazyVim Astro extra](https://lazyvim.github.io/extras/lang/astro)
- [Prettier Astro plugin](https://prettier.io/docs/en/plugins.html#community-plugins)
