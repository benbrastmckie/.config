return {
  "nvim-lualine/lualine.nvim",
  event = "BufReadPost", -- Only load when an actual file is read
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()

    -- Initial minimal setup
    require('lualine').setup({
      options = {
        icons_enabled = false, -- Disable icons initially for faster load
        theme = 'gruvbox',
        component_separators = '',
        section_separators = '',
        refresh = {
          statusline = 2000, -- Reduce refresh frequency
          tabline = 2000,
          winbar = 2000,
        }
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'filetype' },
        lualine_y = {},
        lualine_z = { 'location' }
      },
    })

    require('lualine').setup({
      options = {
        icons_enabled = true,
        theme = 'gruvbox',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          statusline = {
            "Avante",
            "AvanteInput",
            "AvanteAsk",
            "AvanteEdit"
          },
          winbar = {
            "Avante",
            "AvanteInput",
            "AvanteAsk",
            "AvanteEdit"
          },
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        }
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = {
          -- { require('mcphub.extensions.lualine') },
          -- 'encoding',
          -- 'fileformat',
          'filetype'
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {}
    })
  end,
}
