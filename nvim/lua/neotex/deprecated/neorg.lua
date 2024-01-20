return {
  "nvim-neorg/neorg",
  event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
  build = ":Neorg sync-parsers",
  tag = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("neorg").setup {
      load = {
        ["core.defaults"] = {}, -- Loads default behaviour
        ["core.concealer"] = {}, -- Adds pretty icons to your documents
        ["core.dirman"] = { -- Manages Neorg workspaces
          config = {
            workspaces = {
              notes = "~/Documents/Notes",
            },
          },
        },
      },
    }
  end,
  run = ":Neorg sync-parsers", -- This is the important bit!
}
