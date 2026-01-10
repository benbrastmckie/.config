# LSP Integration in Neovim

## Overview
Neovim's built-in LSP client provides IDE-like features through the Language Server Protocol. The ecosystem uses several plugins to configure and manage language servers.

## Core Components

### nvim-lspconfig
Standard configurations for language servers.

```lua
-- Basic server setup
require("lspconfig").lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

-- With custom capabilities (for completion)
local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("lspconfig").pyright.setup({
  capabilities = capabilities,
})
```

### mason.nvim
Package manager for LSP servers, DAP adapters, linters, and formatters.

```lua
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "pyright",
    "rust_analyzer",
  },
  automatic_installation = true,
})
```

### Common LSP Keymaps
```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local opts = { buffer = bufnr }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
  end,
})
```

## Completion Engines

### blink.cmp (Modern)
High-performance completion with fuzzy matching.

```lua
return {
  "saghen/blink.cmp",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    keymap = { preset = "default" },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
```

### nvim-cmp (Traditional)
Extensible completion framework.

```lua
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
  },
})
```

## LSP Features

### Diagnostics
```lua
-- Configure diagnostics display
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Navigate diagnostics
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
```

### Formatting
```lua
-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Or use conform.nvim for more control
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "black" },
  },
})
```

### Inlay Hints (Neovim 0.10+)
```lua
-- Enable inlay hints
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})
```

## Server-Specific Configurations

### lua_ls (Lua)
```lua
require("lspconfig").lua_ls.setup({
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})
```

### pyright (Python)
```lua
require("lspconfig").pyright.setup({
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
      },
    },
  },
})
```

### rust_analyzer (Rust)
```lua
require("lspconfig").rust_analyzer.setup({
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = {
        command = "clippy",
      },
    },
  },
})
```

### tsserver (TypeScript)
```lua
require("lspconfig").tsserver.setup({
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionParameterTypeHints = true,
      },
    },
  },
})
```

## Troubleshooting

### Debug LSP
```lua
-- Enable logging
vim.lsp.set_log_level("debug")

-- View log
:LspLog

-- Check active clients
:LspInfo
```

### Common Issues
1. **Server not starting** - Check :LspLog for errors, verify executable in PATH
2. **No completions** - Verify capabilities are passed to server
3. **Slow performance** - Consider workspace size, exclude patterns
4. **Missing diagnostics** - Check server supports diagnostic capability

### Health Check
```vim
:checkhealth lsp
:checkhealth mason
```
