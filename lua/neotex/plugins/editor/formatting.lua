-----------------------------------------------------------
-- Conform.nvim Integration
-- 
-- This module configures conform.nvim for code formatting:
-- - Provides filetype-specific formatters
-- - Configures key mappings for formatting
-- - Supports format-on-save functionality
-- - Respects .editorconfig settings
--
-- Conform.nvim is a lightweight formatter plugin that utilizes
-- a wide variety of formatters to maintain consistent code style.
-----------------------------------------------------------

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre", "BufNewFile" },
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      -- Define formatters for different file types
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
        astro = { "prettier" },
        svelte = { "prettier" },
        graphql = { "prettier" },
        handlebars = { "prettier" },
        
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
      },
      
      -- Formatter options
      formatters = {
        -- Python formatters
        black = {
          args = { "--quiet", "--line-length", "88", "-" },
          stdin = true,
        },
        isort = {
          args = { "--profile", "black", "-" },
          stdin = true,
        },
        
        -- Lua formatter
        stylua = {
          args = { "--indent-type", "Spaces", "--indent-width", "2", "--quote-style", "AutoPreferDouble", "-" },
          stdin = true,
        },
        
        -- LaTeX formatter
        latexindent = {
          args = { "-m", "-l" },
          stdin = false,
        },
        
        -- Shell formatter
        shfmt = {
          args = { "-i", "2", "-ci", "-bn" },
          stdin = true,
        },
        
        -- Prettier formatter - explicitly configure
        prettier = {
          args = { "--stdin-filepath", "$FILENAME" },
          stdin = true,
        },
        
        -- jq formatter for JSON
        jq = {
          args = { "." },
          stdin = true,
        },
      },
      
      -- Format on save behavior (disabled by default, use <leader>mp to format manually)
      format_on_save = function(bufnr)
        -- Customize which filetypes to format on save
        local auto_format_filetypes = {
          -- Add filetypes that should be auto-formatted
          -- Example: "lua", "python", "javascript"
        }
        
        -- Check if the current buffer's filetype should be auto-formatted
        local filetype = vim.bo[bufnr].filetype
        if vim.tbl_contains(auto_format_filetypes, filetype) then
          return { timeout_ms = 500, lsp_fallback = true }
        end
        
        -- Don't auto-format by default
        return false
      end,
      
      -- Set up formatting options
      format_after_save = false,
      log_level = vim.log.levels.ERROR,  -- Only show errors, not debug info
      notify_on_error = false,  -- Disable default notifications, we'll handle them
      
      -- Don't respect gitignore to format all files
      respect_gitignore = false,
    })

    -- Suppress stylua errors (NixOS/Mason compatibility and LSP misconfigurations)
    -- This handles both LSP and formatter error messages
    vim.api.nvim_create_autocmd({"VimEnter", "BufEnter"}, {
      pattern = "*.lua",
      callback = function()
        local original_notify = vim.notify
        vim.notify = function(msg, ...)
          if msg and type(msg) == "string" and
             (msg:match("stylua.*exit code") or
              msg:match("Client stylua quit") or
              msg:match("stylua.*stderr")) then
            return  -- Suppress stylua LSP/execution errors
          end
          return original_notify(msg, ...)
        end
        -- Restore after a short delay to not interfere with other messages
        vim.defer_fn(function()
          vim.notify = original_notify
        end, 100)
      end,
      desc = "Suppress stylua error messages"
    })

    -- Add commands for showing/toggling format-on-save
    vim.api.nvim_create_user_command("FormatToggle", function(args)
      local is_enabled = false
      if args.args == "buffer" then
        -- Toggle for current buffer
        if vim.b.disable_autoformat == true then
          vim.b.disable_autoformat = false
          is_enabled = true
        else
          vim.b.disable_autoformat = true
          is_enabled = false
        end
        
        require('neotex.util.notifications').lsp('Format on save ' .. (is_enabled and 'enabled' or 'disabled') .. ' for this buffer', require('neotex.util.notifications').categories.USER_ACTION)
      else
        -- Toggle globally
        if vim.g.disable_autoformat == true then
          vim.g.disable_autoformat = false
          is_enabled = true
        else
          vim.g.disable_autoformat = true
          is_enabled = false
        end
        
        require('neotex.util.notifications').lsp('Format on save ' .. (is_enabled and 'enabled' or 'disabled') .. ' globally', require('neotex.util.notifications').categories.USER_ACTION)
      end
    end, {
      nargs = "?",
      complete = function()
        return { "buffer" }
      end,
      desc = "Toggle format on save",
    })
  end,
}