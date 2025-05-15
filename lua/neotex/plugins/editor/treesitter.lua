return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        -- enable syntax highlighting
        highlight = {
          enable = true,
          disable = { "css", "cls", "latex" }, -- list of language that will be disabled
          -- Note: we keep markdown parser enabled for lectic.markdown files
          -- Note: using vim's regex highlighting for latex instead of treesitter
          additional_vim_regex_highlighting = { "python" }, -- for jupyter notebooks
        },
        -- enable indentation
        indent = { enable = true, disable = { "latex" } },
        -- Define .ipynb injection queries to properly highlight code in markdown files
        injections = {
          {
            filetype = "markdown",
            query = [[
              (fenced_code_block
                language: (info_string) @language
                content: (code_fence_content) @content)
            ]],
          }
        },
        -- ensure these language parsers are installed
        ensure_installed = {
          -- Essential languages
          "lua",           -- For Neovim configuration
          "vim",           -- For Vim script
          "vimdoc",        -- For Neovim help docs
          "query",         -- For treesitter queries
          "markdown",      -- For documentation and Lectic support
          "markdown_inline", -- For inline markdown syntax
          "python",        -- For Python scripts
          "bash",          -- For shell scripts
          -- "latex" removed as requested - will be handled separately
          "bibtex",        -- For bibliography files
          "nix",           -- For NixOS configuration
          
          -- Utility formats
          "json",
          "yaml",
          "toml",
          "gitignore",
          
          -- Additional languages
          "c",
          "haskell",
          "norg",
        },
        auto_install = true,
        ignore_install = { "latex" }, -- Ignore latex to avoid installation issues
        autopairs = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-n>",
            node_incremental = "<C-n>",
            scope_incremental = false,
            node_decremental = "<C-p>",
          },
        },
      })
      
      -- Set up filetype detection for LaTeX files to ensure proper syntax highlighting
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {"tex", "latex"},
        callback = function()
          -- Enable Vim's built-in syntax highlighting for LaTeX
          vim.opt_local.syntax = "tex"
          -- Disable treesitter for LaTeX files
          vim.cmd[[TSBufDisable highlight]]
        end
      })
    end,
  },
  
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("ts_context_commentstring").setup({})
    end,
  },
  
  {
    "windwp/nvim-ts-autotag",
    lazy = true,
    ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        autotag = {
          enable = true,
        },
      })
    end,
  }
}
