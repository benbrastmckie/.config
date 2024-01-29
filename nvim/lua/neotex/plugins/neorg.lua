return {
  "nvim-neorg/neorg",
  filetype = {
    "markdown",
    "norg",
  },
  -- event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
  build = ":Neorg sync-parsers",
  tag = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  run = ":Neorg sync-parsers", -- This is the important bit!
  config = function()
    require("neorg").setup {
      load = {
        ["core.keybinds"] = {
          config = {
            keybind_preset = 'none'
          }
        },
        ["core.defaults"] = {},  -- Loads default behaviour
        ["core.concealer"] = {
          config = {
            icons = {
              todo = {
                undone = {
                  icon = " "
                },
                urgent = {
                  icon = "󰈸"
                },
              },
            },
            folds = false,
            icon_preset = "diamond",
            init_open_folds = "always",
          },
        }, -- Adds pretty icons to your documents
        ["core.highlights"] = {
          config = {
            highlights = {
              todo_items = {
                urgent = "+@repeat",
                recurring = "+@attribute"
              },
            },
          },
        },
        ["core.dirman"] = {      -- Manages Neorg workspaces
          config = {
            workspaces = {
              notes = "~/Documents/Notes",
            },
          },
        },
      },
    }
  end,
}
