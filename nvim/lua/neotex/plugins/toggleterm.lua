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
      -- on_create = fun(t: Terminal), -- function to run when the terminal is first created
      -- on_open = fun(t: Terminal), -- function to run when the terminal opens
      -- on_close = fun(t: Terminal), -- function to run when the terminal closes
      -- on_stdout = fun(t: Terminal, job: number, data: string[], name: string) -- callback for processing output on stdout
      -- on_stderr = fun(t: Terminal, job: number, data: string[], name: string) -- callback for processing output on stderr
      -- on_exit = fun(t: Terminal, job: number, exit_code: number, name: string) -- function to run when terminal process exits
      -- shade_filetypes = {},
      -- autochdir = false, -- when neovim changes it current directory the terminal will change it's own when next it's opened
      -- highlights = {
      --   -- highlights which map to a highlight group name and a table of it's values
      --   -- NOTE: this is only a subset of values, any group placed here will be set for the terminal window split
      --   Normal = {
      --     guibg = "<VALUE-HERE>",
      --   },
      --   NormalFloat = {
      --     link = 'Normal'
      --   },
      --   FloatBorder = {
      --     guifg = "<VALUE-HERE>",
      --     guibg = "<VALUE-HERE>",
      --   },
      -- },
      terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
      persist_mode = false,     -- if set to true (default) the previous terminal mode will be remembered
      auto_scroll = true,       -- automatically scroll to the bottom on terminal output
      -- This field is only relevant if direction is set to 'float'
      -- winbar = {
      --   enabled = false,
      --   name_formatter = function(term) --  term: Terminal
      --     return term.name
      --   end
      -- },
    }
  end
}
