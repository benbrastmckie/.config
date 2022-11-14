local colorscheme = "gruvbox"
-- local colorscheme = "tokyonight"
-- local colorscheme = "onedark"
--   -- style options: dark, darker, cool, deep, warm, warmer, light
--   require('onedark').setup {
--       style = 'warmer'
--   }
--   require('onedark').load()

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  return
end
