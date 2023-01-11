-- vim.opt.runtimepath:prepend "PATH/nvim-lua/plenary.nvim"
-- vim.opt.runtimepath:prepend "PATH/hrsh7th/nvim-cmp"
-- vim.opt.runtimepath:prepend "PATH/hrsh7th/cmp-nvim-lsp"
-- vim.opt.runtimepath:prepend "PATH/hrsh7th/cmp-buffer"
-- vim.opt.runtimepath:prepend "PATH/hrsh7th/cmp-omni"
-- vim.opt.runtimepath:prepend "PATH/neovim/nvim-lspconfig"
-- vim.opt.runtimepath:prepend "PATH/williamboman/mason.nvim"
-- vim.opt.runtimepath:prepend "PATH/williamboman/mason-lspconfig.nvim"
vim.opt.runtimepath:prepend "/home/benjamin/.local/share/nvim/site/pack/packer/start/cmp-omni"
vim.opt.runtimepath:append  "/home/benjamin/.local/share/nvim/site/pack/packer/start/cmp-omni/after"
vim.opt.runtimepath:prepend "/home/benjamin/.local/share/nvim/site/pack/packer/start/nvim-cmp"
vim.opt.runtimepath:append  "/home/benjamin/.local/share/nvim/site/pack/packer/start/nvim-cmp/after"
vim.opt.runtimepath:prepend "/home/benjamin/.local/share/nvim/site/pack/packer/start/vimtex"
vim.opt.runtimepath:append  "/home/benjamin/.local/share/nvim/site/pack/packer/start/vimtex/after"

vim.cmd[[filetype plugin indent on]]

local cmp = require("cmp")

cmp.setup({
  sources = cmp.config.sources({
    { name = "omni" },
    { name = "nvim_lsp" },
    { name = "buffer", keyword_length = 3 },
  }),
})

vim.g.vimtex_view_method = "zathura"
