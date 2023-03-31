local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and reopen Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- Packer 
return packer.startup(function(use)
  -- Have packer manage itself
  use { "wbthomason/packer.nvim" }
  -- Useful lua functions used by lots of plugins
  use { "nvim-lua/plenary.nvim" }

-- General
  use { "windwp/nvim-autopairs" }
  use { "numToStr/Comment.nvim" }
  use { "lewis6991/impatient.nvim" }
  use { "kylechui/nvim-surround" }
  use { "mbbill/undotree" } -- Vimscript
  -- use { "mg979/vim-visual-multi" } -- Vimscript
  use { "glacambre/firenvim" } -- Vimscript
  use { "gbprod/yanky.nvim" }

-- Mappings
	use { "folke/which-key.nvim" }

-- Terminal
  use { "akinsho/toggleterm.nvim" }

-- File Management
  use { "kyazdani42/nvim-tree.lua" }
  use { "kyazdani42/nvim-web-devicons" }
	use { "Shatur/neovim-session-manager" }

-- Appearance
  use { "akinsho/bufferline.nvim" }
  use { "nvim-lualine/lualine.nvim" }
  use { "lukas-reineke/indent-blankline.nvim" }
  use { "goolord/alpha-nvim" }
  use { "RRethy/vim-illuminate" }

-- Colorschemes
  use { "ellisonleao/gruvbox.nvim" }
  -- use { "luisiacc/gruvbox-baby" }
  -- use { "folke/tokyonight.nvim" }
  -- use { "lunarvim/darkplus.nvim" }
  -- use { "navarasu/onedark.nvim" }
  -- use { "savq/melange" }
  -- use { "EdenEast/nightfox.nvim" }
  -- use { "navarasu/onedark.nvim" }

-- Cmp 
  use { "hrsh7th/nvim-cmp" }
	use { "hrsh7th/cmp-nvim-lsp" }
  -- buffer completions
  use { "hrsh7th/cmp-buffer" }
  -- path completions
  use { "hrsh7th/cmp-path" }
  -- snippet completions
	use { "saadparwaiz1/cmp_luasnip" }
  -- command completions
  use { "hrsh7th/cmp-cmdline" }
  -- spelling completions
  use { "f3fora/cmp-spell" }
  -- helps Vimtex completions
  use { "hrsh7th/cmp-omni" }
  -- use { "aspeddro/cmp-pandoc.nvim" }

-- LSP
  -- enable LSP
	use { "neovim/nvim-lspconfig" }
  -- simple to use language server installer
  use { "williamboman/mason.nvim" }
  use { "williamboman/mason-lspconfig.nvim" }
  -- for formatters and linters
	use { "jose-elias-alvarez/null-ls.nvim" }

-- LaTeX
  use { "lervag/vimtex" } -- essential for LaTeX; Vimscript
  use { "kdheepak/cmp-latex-symbols" }
  use { "jbyuki/nabla.nvim" } -- show symbols in editor

-- Markdown
  use({
    "gaoDean/autolist.nvim",
    ft = {
      "markdown",
      "text",
      "tex",
      "plaintex",
    },
    config = function()
      local autolist = require("autolist")
      autolist.setup()
      autolist.create_mapping_hook("i", "<CR>", autolist.new)
      autolist.create_mapping_hook("i", "<Tab>", autolist.indent)
      autolist.create_mapping_hook("i", "<S-Tab>", autolist.indent, "<C-D>")
      autolist.create_mapping_hook("n", "o", autolist.new)
      autolist.create_mapping_hook("n", "O", autolist.new_before)
      -- autolist.create_mapping_hook("n", ">>", autolist.indent)
      -- autolist.create_mapping_hook("n", "<<", autolist.indent)
      autolist.create_mapping_hook("n", "<leader>r", autolist.force_recalculate)
      autolist.create_mapping_hook("n", "<leader>x", autolist.invert_entry, "")
        vim.api.nvim_create_autocmd("TextChanged", {
          pattern = "-",
          callback = function()
            vim.cmd.normal({autolist.force_recalculate(nil, nil), bang = false})
          end
        })
    end,
  })

-- Snippets
  --snippet engine
  use { "L3MON4D3/LuaSnip" }
  -- a bunch of snippets to use
  -- use { "garbas/vim-snipmate" }
  -- use { "rafamadriz/friendly-snippets" }

-- Telescope
	use { "nvim-telescope/telescope.nvim" }
    -- , commit = "76ea9a898d3307244dce3573392dcf2cc38f340f" 
	use { "stevearc/dressing.nvim" }
  use { "nvim-telescope/telescope-bibtex.nvim",
    config = function ()
      require"telescope".load_extension("bibtex")
    end,
  }

-- Treesitter
	use { "nvim-treesitter/nvim-treesitter" }
-- , commit = "8e763332b7bf7b3a426fd8707b7f5aa85823a5ac" 

-- Git
	use { "lewis6991/gitsigns.nvim" }

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
