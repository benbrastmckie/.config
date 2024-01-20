local config = require("nvim-surround.config")

require("nvim-surround").buffer_setup({
  surrounds = {
    -- ["e"] = {
    --   add = function()
    --     local env = require("nvim-surround.config").get_input ("Environment: ")
    --     return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
    --   end,
    -- },
    ["b"] = {
      add = { "**", "**" },
      find = "**.-**",
      delete = "^(**)().-(**)()$",
    },
    ["i"] = {
      add = { "*", "*" },
      find = "*.-*",
      delete = "^(*)().-(*)()$",
    },
  },
})

-- local options = {
--   tabstop = 2,                             -- insert 2 spaces for a tab
--   shiftwidth = 2,                          -- the number of spaces inserted for each indentation
--   softtabstop = 2,                         -- insert 2 spaces for a tab
--   expandtab = true,                        -- convert tabs to spaces
-- }
