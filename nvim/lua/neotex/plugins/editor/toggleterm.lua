return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup {
      size = 80,
      open_mapping = "<c-t>",
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = false, -- When true, the open mapping (<c-t>) works in insert mode
      persist_size = true,
      direction = "vertical",  -- direction = 'vertical' | 'horizontal' | 'tab' | 'float',
      close_on_exit = true,
      shell = 'fish',          -- Change the default shell. Can be a string or a function returning a string
      float_opts = {
        border = "curved",     -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
      terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
      persist_mode = false,     -- don't remember terminal mode between sessions
      persist_terminal = false, -- prevents terminals from persisting across sessions
      auto_scroll = false,      -- automatically scroll to the bottom on terminal output
    }

    -- Add an autocommand to ensure terminals aren't saved in session
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        -- Close all terminal buffers before exiting
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          local buftype = vim.bo[bufnr].buftype
          if buftype == "terminal" then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
        end
      end,
    })
  end
}
