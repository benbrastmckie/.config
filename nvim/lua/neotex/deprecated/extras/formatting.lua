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
  keys = {
    {
      "<leader>mp", 
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "Format buffer or selection"
    },
  },
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
        json = { "prettier" },
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
      },
      
      -- Formatter options
      formatters = {
        -- Python formatters
        black = {
          args = { "--quiet", "--line-length", "88", "-" },
        },
        isort = {
          args = { "--profile", "black", "-" },
        },
        
        -- Lua formatter
        stylua = {
          args = { "--indent-type", "Spaces", "--indent-width", "2", "--quote-style", "AutoPreferDouble", "-" },
        },
        
        -- LaTeX formatter
        latexindent = {
          args = { "-m", "-l" },
        },
        
        -- Shell formatter
        shfmt = {
          args = { "-i", "2", "-ci", "-bn" },
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
        local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
        if vim.tbl_contains(auto_format_filetypes, filetype) then
          return { timeout_ms = 500, lsp_fallback = true }
        end
        
        -- Don't auto-format by default
        return false
      end,
      
      -- Set up formatting options
      format_after_save = false,
      log_level = vim.log.levels.ERROR,
      notify_on_error = true,
      
      -- Respect .editorconfig when present
      respect_gitignore = true,
    })

    -- Add which-key integration if available
    local has_which_key, which_key = pcall(require, "which-key")
    if has_which_key then
      which_key.register({
        m = {
          p = { 
            function() require("conform").format({ async = true, lsp_fallback = true }) end, 
            "Format code" 
          },
        },
      }, { prefix = "<leader>" })
    end
    
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
        
        vim.notify(
          string.format("Format on save %s for this buffer", is_enabled and "enabled" or "disabled"),
          vim.log.levels.INFO
        )
      else
        -- Toggle globally
        if vim.g.disable_autoformat == true then
          vim.g.disable_autoformat = false
          is_enabled = true
        else
          vim.g.disable_autoformat = true
          is_enabled = false
        end
        
        vim.notify(
          string.format("Format on save %s globally", is_enabled and "enabled" or "disabled"),
          vim.log.levels.INFO
        )
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