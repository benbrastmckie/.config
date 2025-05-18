return {
  {
    "nvim-treesitter/nvim-treesitter", 
    event = { "BufReadPost", "BufNewFile" }, -- Load when a buffer is read, not before
    build = ":TSUpdate",
    config = function() 
      -- Load only essential modules initially
      require("nvim-treesitter.configs").setup({
        -- Only enable minimal highlighting at startup
        highlight = {
          enable = true,
          disable = { "css", "cls", "latex" },
          additional_vim_regex_highlighting = false, -- Disable additional regex highlighting initially
        },
        
        -- Disable more complex features at startup
        indent = { enable = false },
        
        -- Don't install parsers at startup
        ensure_installed = {},
        auto_install = false,
        ignore_install = { "latex" },
      })
      
      -- Defer full configuration to happen after initial file is loaded
      vim.defer_fn(function()
        -- Now load the full configuration
        require("nvim-treesitter.configs").setup({
          -- Enable full syntax highlighting
          highlight = {
            enable = true,
            disable = { "css", "cls", "latex" },
            additional_vim_regex_highlighting = { "python" }, -- for jupyter notebooks
          },
          
          -- Enable indentation
          indent = { enable = true, disable = { "latex" } },
          
          -- Define injection queries
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
          
          -- Install only most essential parsers immediately
          ensure_installed = {
            "lua",           -- For Neovim configuration
            "vim",           -- For Vim script
            "markdown",      -- For documentation
            "python",        -- For Python scripts
          },
          
          auto_install = true,
          ignore_install = { "latex" },
          
          -- Enable more advanced features
          autopairs = { enable = true },
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
        
        -- Install remaining parsers in the background without prompting
        vim.defer_fn(function()
          local additional_parsers = {
            "vimdoc", "query", "markdown_inline", "bash", 
            "bibtex", "nix", "json", "yaml", "toml", 
            "gitignore", "c", "haskell", "norg"
          }
          
          -- Get list of installed parsers to avoid reinstall prompts
          local installed = {}
          pcall(function()
            local parsers = require("nvim-treesitter.parsers")
            for lang, _ in pairs(parsers.get_parser_configs()) do
              if parsers.has_parser(lang) then
                installed[lang] = true
              end
            end
          end)
          
          -- Only install parsers that aren't already installed
          for _, parser in ipairs(additional_parsers) do
            if not installed[parser] then
              vim.cmd("TSInstall! " .. parser) -- Use ! to skip prompts
            end
          end
        end, 1000) -- Delay by 1 second to avoid impacting startup
      end, 100) -- Delay the full setup by 100ms
      
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
