return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" }, -- Only load when a file is opened
  dependencies = {
    { "antosha417/nvim-lsp-file-operations", event = "VeryLazy" }, -- Load file operations later
  },
  config = function()
    -- Suppress the deprecation warning from nvim-lspconfig
    -- This warning is about the plugin transitioning to vim.lsp.config in the future
    -- We'll continue using nvim-lspconfig until the new API is stable and feature-complete
    local original_notify = vim.notify
    vim.notify = function(msg, ...)
      if msg:match("framework.*deprecated") or msg:match("vim.lsp.config") then
        return  -- Suppress this specific deprecation warning
      end
      return original_notify(msg, ...)
    end

    -- Import lspconfig plugin (only loaded when the event triggers)
    -- Using vim.lsp.config API as recommended in nvim 0.11+
    local lspconfig = vim.F.npcall(require, "lspconfig")
    if not lspconfig then
      vim.notify("Failed to load lspconfig", vim.log.levels.ERROR)
      return
    end

    -- Restore original notify function
    vim.notify = original_notify

    -- Disable stylua LSP setup (using formatter instead via conform.nvim)
    -- This prevents the "Client stylua quit with exit code 2" error
    if vim.lsp.handlers and vim.lsp.handlers["textDocument/didOpen"] then
      local original_handler = vim.lsp.handlers["textDocument/didOpen"]
      vim.lsp.handlers["textDocument/didOpen"] = function(err, result, ctx, config)
        -- Skip stylua LSP client
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if client and client.name == "stylua" then
          return
        end
        return original_handler(err, result, ctx, config)
      end
    end

    -- Prevent stylua from being started as an LSP server
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "stylua" then
          vim.lsp.stop_client(client.id)
        end
      end,
      desc = "Stop stylua LSP client (using formatter instead)"
    })

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