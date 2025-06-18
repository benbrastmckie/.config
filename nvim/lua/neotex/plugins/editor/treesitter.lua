return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" }, -- Load when a buffer is read, not before
    build = ":TSUpdate",
    config = function()
      -- Remove any existing problematic parsers that cause ABI version conflicts
      local problematic_parsers = { "latex", "tex", "bibtex", "plaintex", "context" }
      for _, parser in ipairs(problematic_parsers) do
        local parser_path = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser/" .. parser .. ".so"
        if vim.fn.filereadable(parser_path) == 1 then
          vim.fn.delete(parser_path)
        end
        
        -- Also remove any source directories in multiple locations
        local source_paths = {
          vim.fn.stdpath("data") .. "/tree-sitter-" .. parser,
          vim.fn.expand("~/.local/share/nvim/tree-sitter-" .. parser),
          vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/tree-sitter-" .. parser,
        }
        
        for _, source_path in ipairs(source_paths) do
          if vim.fn.isdirectory(source_path) == 1 then
            vim.fn.delete(source_path, "rf")
          end
        end
      end
      
      -- Override LaTeX parser configs to prevent installation
      vim.defer_fn(function()
        pcall(function()
          local configs = require("nvim-treesitter.parsers").get_parser_configs()
          local blocked_parsers = { "latex", "tex", "bibtex", "plaintex", "context" }
          for _, parser in ipairs(blocked_parsers) do
            if configs[parser] then
              configs[parser] = nil
            end
          end
        end)
      end, 50)
      
      
      -- Load only essential modules initially
      require("nvim-treesitter.configs").setup({
        -- Only enable minimal highlighting at startup
        highlight = {
          enable = true,
          disable = { "css", "cls", "latex", "tex", "plaintex", "context", "bibtex" },
          additional_vim_regex_highlighting = false, -- Disable additional regex highlighting initially
        },

        -- Disable more complex features at startup
        indent = { enable = false },

        -- Don't install parsers at startup
        ensure_installed = {},
        auto_install = false,
        ignore_install = { "latex", "tex", "bibtex", "plaintex", "context" },
      })

      -- Defer full configuration to happen after initial file is loaded
      vim.defer_fn(function()
        -- Now load the full configuration
        require("nvim-treesitter.configs").setup({
          -- Enable full syntax highlighting
          highlight = {
            enable = true,
            disable = { "css", "cls", "latex", "tex", "plaintex", "context", "bibtex" },
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
            "lua",      -- For Neovim configuration
            "vim",      -- For Vim script
            "markdown", -- For documentation
            "python",   -- For Python scripts
          },

          auto_install = true,
          ignore_install = { "latex", "tex", "bibtex", "plaintex", "context" },

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
            "nix", "json", "yaml", "toml",
            "gitignore", "c", "haskell",
            "css", "html", "javascript", "scss", "regex"
            -- Removed: "bibtex", "norg", "latex" due to potential ABI version conflicts
            -- Removed: "tsx", "svelte", "vue", "typst" - less commonly used
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
              -- Use pcall to handle any ABI version errors gracefully
              pcall(function()
                vim.cmd("TSInstall! " .. parser) -- Use ! to skip prompts
              end)
            end
          end
        end, 1000) -- Delay by 1 second to avoid impacting startup
      end, 100)    -- Delay the full setup by 100ms

      -- Set up filetype detection for LaTeX files to ensure proper syntax highlighting
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tex", "latex" },
        callback = function()
          -- Enable Vim's built-in syntax highlighting for LaTeX
          vim.opt_local.syntax = "tex"
          -- Disable treesitter for LaTeX files
          vim.cmd [[TSBufDisable highlight]]
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
