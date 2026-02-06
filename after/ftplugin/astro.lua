-- Astro ftplugin configuration
-- Provides indentation and formatting settings for .astro files

-- Set 2-space indentation (standard for Astro/HTML)
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.expandtab = true

-- Enable treesitter indentation with pcall fallback
local ok, _ = pcall(function()
  vim.opt_local.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)

-- Disable smartindent to prevent HTML-like syntax issues
vim.opt_local.smartindent = false
vim.opt_local.autoindent = true

-- Enable breakindent for wrapped lines
vim.opt_local.breakindent = true
vim.opt_local.breakindentopt = "shift:2"

-- Enable treesitter-based folding
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldlevel = 99
