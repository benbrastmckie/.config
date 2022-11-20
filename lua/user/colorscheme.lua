-- OTHER ---

-- local colorscheme = "melange"
-- local colorscheme = "tokyonight"
-- local colorscheme = "onedark"
--   -- style options: dark, darker, cool, deep, warm, warmer, light
--   require('onedark').setup {
--       style = 'warmer'
--   }
--   require('onedark').load()


-- GRUVBOX --

-- setup must be called before loading the colorscheme
-- Default options:
require("gruvbox").setup({
  undercurl = true,
  underline = true,
  bold = true,
  italic = true,
  strikethrough = true,
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  invert_intend_guides = false,
  inverse = true, -- invert background for search, diffs, statuslines and errors
  contrast = "", -- can be "hard", "soft" or empty string
  -- overrides = {
  --   SignColumn = {bg = "#ff9900"},
  -- },
  dim_inactive = false,
  transparent_mode = false,
  -- palette_overrides = {
  --     bright_green = "#990000",
  -- }
})
vim.cmd("colorscheme gruvbox")

local colorscheme = "gruvbox"

-- GRUVBOX --

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  return
end

