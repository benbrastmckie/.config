-- neotex.config.autocmds
-- Autocommand configuration

local M = {}

function M.setup()
  local api = vim.api

  -- Set special buffers as fixed and map 'q' to close
  api.nvim_create_autocmd(
    "FileType",
    {
      pattern = { "man", "help", "qf", "lspinfo", "infoview", "NvimTree" }, -- "startuptime",
      callback = function(ev)
        -- Set the window as fixed
        vim.wo.winfixbuf = true
        -- Map q to close
        vim.keymap.set("n", "q", ":close<CR>", { buffer = ev.buf, silent = true })
      end,
    }
  )

  -- Handle Avante help markdown file specifically
  api.nvim_create_autocmd(
    "BufEnter",
    {
      pattern = "*/avante.nvim.md",
      callback = function(ev)
        vim.bo[ev.buf].filetype = "help" -- Set filetype to help
        vim.wo.winfixbuf = true          -- Set as fixed buffer
        vim.keymap.set("n", "q", ":close<CR>", { buffer = ev.buf, silent = true })
      end,
    }
  )

  -- Pre-emptively suppress terminal messages
  api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    pattern = { "term://*" },
    callback = function()
      vim.opt_local.shortmess:append("I")
      vim.cmd([[silent! echo ""]])
    end,
  })
  
  -- Setup terminal keymaps and suppress native terminal message
  api.nvim_create_autocmd({ "TermOpen" }, {
    pattern = { "term://*" }, -- use term://*toggleterm#* for only ToggleTerm
    callback = function(ev)
      set_terminal_keymaps()
      
      -- Aggressive suppression of the native terminal message
      local bufname = vim.api.nvim_buf_get_name(ev.buf)
      
      -- Set buffer-local option to suppress messages
      vim.bo[ev.buf].modifiable = true
      
      -- Multiple approaches to clear the message
      vim.cmd([[silent! echo ""]])
      vim.cmd([[silent! redraw!]])
      
      -- For Claude Code, use additional suppression
      if bufname:match("claude%-code") or bufname:match("ClaudeCode") then
        -- Clear any messages immediately and after a short delay
        vim.defer_fn(function()
          vim.cmd([[silent! echo ""]])
          vim.cmd([[silent! redraw!]])
        end, 1)
        
        -- Also try clearing with messages command
        vim.defer_fn(function()
          vim.cmd([[silent! messages clear]])
        end, 10)
      end
      
      -- Final clear for all terminals
      vim.defer_fn(function()
        vim.cmd([[silent! echo ""]])
      end, 50)
    end,
  })

  -- Setup markdown keymaps
  api.nvim_create_autocmd({ "BufEnter", "BufReadPre", "BufNewFile" }, {
    pattern = { "*.md" },
    command = "lua set_markdown_keymaps()",
  })

  return true
end

return M

