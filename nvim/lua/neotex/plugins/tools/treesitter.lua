return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    -- "nvim-treesitter/nvim-treesitter-textobjects",
    "JoosepAlviste/nvim-ts-context-commentstring",
    "windwp/nvim-ts-autotag",
  },
  config = function()
    require("nvim-treesitter.configs").setup({
      -- enable syntax highlighting
      highlight = {
        enable = true,
        disable = { "css", "cls" }, -- list of language that will be disabled
        -- Note: we keep markdown parser enabled for lectic.markdown files
        -- Note: we now allow latex highlighting with treesitter
        additional_vim_regex_highlighting = { "python", "latex" }, -- for jupyter notebooks and latex (fallback)
      },
      -- enable indentation
      indent = { enable = true },
      -- enable autotagging (w/ nvim-ts-autotag plugin)
      autotag = {
        enable = false,
      },
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
        "latex",         -- For LaTeX files
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
      ignore_install = { }, -- No parsers to ignore anymore
      autopairs = {
        enable = true,
      },
      -- indent = { enable = false, disable = { "latex", "python", "css" } },
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

    -- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
    require("ts_context_commentstring").setup({})
  end,
}
