return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "antosha417/nvim-lsp-file-operations", event = "BufReadPost" },
  },
  config = function()
    -- Neovim 0.11+ uses native vim.lsp.config API instead of lspconfig framework
    -- See :help lspconfig-nvim-0.11 for migration details

    -- Define diagnostics configuration
    local signs = { Error = "", Warn = "", Hint = "󰠠", Info = "" }
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = signs.Error,
          [vim.diagnostic.severity.WARN] = signs.Warn,
          [vim.diagnostic.severity.HINT] = signs.Hint,
          [vim.diagnostic.severity.INFO] = signs.Info,
        },
      },
      update_in_insert = false,
      severity_sort = true,
    })

    -- Get capabilities (with blink.cmp enhancement if available)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
      capabilities = blink.get_lsp_capabilities(capabilities)
    end

    -- Configure LSP servers using vim.lsp.config (Neovim 0.11+ native API)
    vim.lsp.config("lua_ls", {
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = {
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.stdpath("config") .. "/lua"] = true,
            },
            checkThirdParty = false,
          },
          telemetry = { enable = false },
        },
      },
    })

    vim.lsp.config("pyright", {
      cmd = { "pyright-langserver", "--stdio" },
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" },
      capabilities = capabilities,
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = "openFilesOnly",
          },
        },
      },
    })

    vim.lsp.config("texlab", {
      cmd = { "texlab" },
      filetypes = { "tex", "plaintex", "bib" },
      root_markers = { ".latexmkrc", ".texlabroot", "texlabroot", "Tectonic.toml", ".git" },
      capabilities = capabilities,
      settings = {
        texlab = {
          build = { onSave = true },
          chktex = {
            onEdit = false,
            onOpenAndSave = false,
          },
          diagnosticsDelay = 300,
        },
      },
    })

    vim.lsp.config("tinymist", {
      cmd = { "tinymist" },
      filetypes = { "typst" },
      root_markers = { "typst.toml", ".git" },
      capabilities = capabilities,
      settings = {
        formatterMode = "typstyle",  -- Use typstyle for formatting (bundled with tinymist)
        exportPdf = "onSave",        -- Export PDF when file is saved
        semanticTokens = "enable",   -- Enable semantic highlighting
      },
    })

    -- Enable configured servers
    vim.lsp.enable({ "lua_ls", "pyright", "texlab", "tinymist" })
  end,
}