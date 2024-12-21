return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup{
      size = 80,
      open_mapping = "<c-t>",
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = false,
      persist_size = true,
      direction = "vertical", -- direction = 'vertical' | 'horizontal' | 'tab' | 'float',
      close_on_exit = true,
      shell = 'fish',           -- Change the default shell. Can be a string or a function returning a string
      float_opts = {
        border = "curved",      -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
      terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
      persist_mode = true,     -- if set to true (default) the previous terminal mode will be remembered
      auto_scroll = true,       -- automatically scroll to the bottom on terminal output
    }
  end
}
