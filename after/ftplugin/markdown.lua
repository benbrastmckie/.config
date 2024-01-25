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

-- -- Autolist markdown mappings
--
-- -- vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
-- -- vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
-- vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
-- vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
-- vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
--
-- -- functions to recalculate list on edit
-- vim.keymap.set("i", "<tab>", "<Esc>>lla<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("i", "<s-tab>", "<Esc><<cmd>AutolistRecalculate<cr>a")
-- vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("n", ">", "><cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("n", "<", "<<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("n", "<C-c>", "<cmd>AutolistRecalculate<cr>")
--
-- -- toggle checkbox
-- -- vim.keymap.set({ "n", "i", "v", "x" }, "<C-x>", "<cmd>lua handle_checkbox()<CR>")
-- -- vim.keymap.set({ "n", "i", "v", "x" }, "<C-x>", "<cmd>AutolistToggleCheckbox<cr>")
--
-- -- cycle list types with dot-repeat
-- -- vim.keymap.set("n", "<leader>cn", require("autolist").cycle_next_dr, { expr = true })
-- -- vim.keymap.set("n", "<leader>cp", require("autolist").cycle_prev_dr, { expr = true })
