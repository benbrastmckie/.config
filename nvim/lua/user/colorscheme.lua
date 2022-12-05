-- OTHER ---

-- local colorscheme = "duskfox"
-- local colorscheme = "melange"
-- local colorscheme = "tokyonight-night"

-- local colorscheme = "onedark"
--   -- style options: dark, darker, cool, deep, warm, warmer, light
--   require('onedark').setup {
--       style = 'dark'
--   }
--   require('onedark').load()


-- GRUVBOX --

-- -- setup must be called before loading the colorscheme
-- -- Default options:
-- require("gruvbox").setup({
--   gruvbox_guisp_fallback = "bold",
--   undercurl = true,
--   underline = true,
--   bold = true,
--   italic = true,
--   strikethrough = false,
--   invert_selection = false,
--   invert_signs = false,
--   invert_tabline = false,
--   invert_intend_guides = false,
--   inverse = true, -- invert background for search, diffs, statuslines and errors
--   contrast = "", -- can be "hard", "soft" or empty string
--   -- overrides = {
--   --   SignColumn = {bg = "#ff9900"},
--   -- },
--   dim_inactive = false,
--   transparent_mode = false,
--   -- palette_overrides = {
--   --     bright_green = "#990000",
--   -- }
-- })

-- vim.g['gruvbox_guisp_fallback'] = "bg"
-- avoids underlining spelling errors

local colorscheme = "gruvbox"
-- local colorscheme = "gruvbox-baby"

-- vim.g['gruvbox_guisp'] = "bg"
-- GRUVBOX --

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  return
end

