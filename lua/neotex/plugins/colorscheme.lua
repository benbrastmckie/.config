return {
  "ellisonleao/gruvbox.nvim",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require("gruvbox").setup({
      -- overrides = {
      --   SignColumn = {bg = "#282828"}
      -- }
    })
    vim.cmd("colorscheme gruvbox")
  end,
}


-- -- Nightfly
-- return {
--   "bluz71/vim-nightfly-guicolors",
--   priority = 1000, -- make sure to load this before all the other start plugins
--   config = function()
--     -- load the colorscheme here
--     vim.cmd([[colorscheme nightfly]])
--   end,
-- }


-- Other
-- "luisiacc/gruvbox-baby"
-- "folke/tokyonight.nvim"
-- "lunarvim/darkplus.nvim"
-- "navarasu/onedark.nvim"
-- "savq/melange"
-- "EdenEast/nightfox.nvim"
-- "navarasu/onedark.nvim"
