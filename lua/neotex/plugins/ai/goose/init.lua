return {
  "azorng/goose.nvim",
  branch = "main",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
      },
    },
  },
  config = function()
    require("goose").setup({
      -- Picker (auto-detect telescope if available)
      prefered_picker = "telescope", -- or 'fzf', 'mini.pick', 'snacks'

      -- CRITICAL: Disable default keymaps (managed by which-key.lua)
      default_global_keymaps = false,

      -- UI Settings
      ui = {
        window_width = 0.35, -- 35% of screen width
        input_height = 0.15, -- 15% for input area
        fullscreen = false,
        layout = "right", -- Sidebar on right
        floating_height = 0.8,
        display_model = true, -- Show model in winbar
        display_goose_mode = true, -- Show mode in winbar
      },

      -- Provider shortcuts
      providers = {
        google = { "gemini-2.0-flash-exp" },
      },
    })
  end,
  cmd = { "Goose", "GooseOpenInput", "GooseClose" },
  -- Keybindings managed by which-key.lua (Phase 3)
  -- Empty keys table to prevent plugin-defined keybindings
  keys = {},
}
