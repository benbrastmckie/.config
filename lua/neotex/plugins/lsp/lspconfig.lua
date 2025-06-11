return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" }, -- Only load when a file is opened
  dependencies = {
    { "antosha417/nvim-lsp-file-operations", event = "VeryLazy" }, -- Load file operations later
  },
  config = function()
    -- Import lspconfig plugin (only loaded when the event triggers)
    local lspconfig = require("lspconfig")

    -- Define diagnostics configuration before anything else
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
      -- Optimize diagnostic updates - don't update in insert mode
      update_in_insert = false,
      -- Reduce diagnostic severity for better UX
      severity_sort = true,
    })

    -- On-attach function to set up keymaps when an LSP connects
    local on_attach = function(client, bufnr)
      -- Your existing on_attach code can go here
    end

    -- Map of commonly used filetypes to their LSP servers
    local filetype_servers = {
      lua = "lua_ls",
      python = "pyright", 
      tex = "texlab",
      latex = "texlab",
    }

    -- Minimal capabilities for LSP
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Lazy-load LSP servers based on filetype
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"lua", "python", "tex", "latex"},
      callback = function()
        -- Get current filetype
        local ft = vim.bo.filetype
        local server = filetype_servers[ft]
        
        -- Skip if no server mapped or already set up
        if not server or not lspconfig[server] then return end

        -- Get enhanced capabilities for completion (only load when needed)
        local ok, blink = pcall(require, "blink.cmp")
        if ok then
          capabilities = blink.get_lsp_capabilities(capabilities)
        end
        
        -- Configure specific LSP servers
        if server == "lua_ls" then
          lspconfig.lua_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              Lua = {
                diagnostics = { globals = { "vim" } },
                workspace = {
                  library = {
                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    [vim.fn.stdpath("config") .. "/lua"] = true,
                  },
                },
              },
            },
          })
        elseif server == "pyright" then
          lspconfig.pyright.setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        elseif server == "texlab" then
          lspconfig.texlab.setup({
            capabilities = capabilities,
            on_attach = on_attach,
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
        end
      end,
      desc = "Set up LSP for detected filetypes",
    })
  end,
}