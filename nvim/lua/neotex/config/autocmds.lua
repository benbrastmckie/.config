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

  -- Setup terminal keymaps
  api.nvim_create_autocmd({ "TermOpen" }, {
    pattern = { "term://*" }, -- use term://*toggleterm#* for only ToggleTerm
    command = "lua set_terminal_keymaps()",
  })

  -- Setup markdown keymaps
  api.nvim_create_autocmd({ "BufEnter", "BufReadPre", "BufNewFile" }, {
    pattern = { "*.md" },
    command = "lua set_markdown_keymaps()",
  })

  return true
end

return M

