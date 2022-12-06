-- PLUGINS --

vim.cmd [[packadd packer.nvim]]

-- Packer 
require('packer').startup(function(use)
  -- Have packer manage itself
  use { "wbthomason/packer.nvim" }
  -- Useful lua functions used by lots of plugins
  use { "nvim-lua/plenary.nvim" }


-- Cmp 
  use { "hrsh7th/nvim-cmp" }
	use { "hrsh7th/cmp-nvim-lsp" }
  -- buffer completions
  use { "hrsh7th/cmp-buffer" }
  -- helps Vimtex completions
  use { "hrsh7th/cmp-omni" }


-- LSP
  -- enable LSP
	use { "neovim/nvim-lspconfig" }
  -- simple to use language server installer
  use { "williamboman/mason.nvim" }
  use { "williamboman/mason-lspconfig.nvim" }


-- LaTeX
  -- Vimscript
  use { "lervag/vimtex" } -- Vimscript


-- Treesitter
	use { "nvim-treesitter/nvim-treesitter", commit = "8e763332b7bf7b3a426fd8707b7f5aa85823a5ac" }

end)


-- CMP -----------------------------------------------------------

local cmp = require("cmp")

cmp.setup {
  sources = {
    { name = "omni" },
    { name = "nvim_lsp" },
    { name = "buffer", keyword_length = 3 },
  },
}

-- VimTeX -----------------------------------------------------------

vim.g.vimtex_view_method = "zathura"
vim.g.vimtex_syntax_enabled = 0
vim.g.vimtex_quickfix_enabled = 0


