return {
  "gbprod/yanky.nvim",
  opts = {
    ring = {
      history_length = 100,
      storage = "shada",
      sync_with_numbered_registers = true,
      cancel_event = "update",
      ignore_registers = { "_" },
      update_register_on_cycle = true,
    },
    picker = {
      telescope = {
        use_default_mappings = true,
      },
    },
    system_clipboard = {
      sync_with_ring = true,
    },
    highlight = {
      on_put = true,
      on_yank = true,
      timer = 200,
    },
    preserve_cursor_position = {
      enabled = true,
    },
  },
  dependencies = {
    "kkharji/sqlite.lua",
    {
      "nvim-telescope/telescope.nvim",
      optional = true,
      opts = function()
        require("telescope").load_extension("yank_history")
      end,
    },
  },
}

