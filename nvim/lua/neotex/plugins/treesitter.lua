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
        disable = { "css", "latex", "cls" }, -- list of language that will be disabled
        -- Note: we keep markdown parser enabled for lectic.markdown files
        additional_vim_regex_highlighting = { "markdown", "python" }, -- for jupyter notebooks
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
        "json",
        "yaml",
        "html",
        "bash",
        "lua",
        "vim",
        "gitignore",
        "query",
        "python",
        "c",
        "haskell",
        "bibtex",
        "vimdoc",
        "norg",
        "markdown",       -- Enable for lectic.markdown support
        "markdown_inline", -- Enable for lectic.markdown support
        -- "latex",
        -- "javascript",
        -- "typescript",
        -- "tsx",
        -- "css",
        -- "prisma",
        -- "svelte",
        -- "graphql",
        -- "dockerfile",
        -- "perl",
      },
      auto_install = true,
      ignore_install = { "latex" }, -- List of parsers to ignore installing
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
