-- Main plugin file for Jupyter notebook functionality and styling
return {
  -- Jupytext for notebook conversion
  {
    "GCBallesteros/jupytext.nvim",
    version = "*", -- Use latest stable version
    dependencies = {
      "GCBallesteros/NotebookNavigator.nvim",
      "echasnovski/mini.comment",
    },
    config = function()
      require("jupytext").setup({
        style = "markdown",      -- or "python"
        output_extension = "md", -- or "py"
        -- Command to use for converting (defaults to jupytext in PATH)
        command = "jupytext",
      })
    end,
  },

  -- NotebookNavigator for cell navigation and execution
  {
    "GCBallesteros/NotebookNavigator.nvim",
    version = "*", -- Use latest stable version
    dependencies = {
      "echasnovski/mini.comment",
      "hkupty/iron.nvim",
      "echasnovski/mini.hipatterns", -- For cell highlighting
    },
    config = function()
      local nn = require("notebook-navigator")

      -- Basic NotebookNavigator setup
      nn.setup({
        -- No mappings here - all defined in which-key.lua
        activate_mapping = "",

        -- Cell markers define how cells are identified in different file types
        cell_markers = {
          -- Default Python marker
          python = "# %%",
          -- For markdown: using the most common code block marker
          markdown = "```",
        },

        -- Use syntax highlighting (a simpler option that works without mini.hipatterns)
        syntax_highlight = true,

        -- Highlight group for cell markers
        cell_highlight_group = "JupyterCellBorder",

        -- Use Iron.nvim as the REPL provider
        repl_provider = "iron",

        -- No mappings here - all defined in which-key.lua
        mappings = {},
      })

      -- Load our custom jupyter styling module
      vim.defer_fn(function()
        local ok, styling = pcall(require, "neotex.plugins.jupyter.styling")
        if ok and type(styling) == "table" and styling.setup then
          styling.setup()
        end
      end, 100)
    end,
  },

  -- Iron.nvim for REPL integration
  {
    "Vigemus/iron.nvim", -- Use the correct GitHub repository name
    version = "*",
    lazy = true,
    main = "iron.core",
    -- No keys defined here - all mappings in which-key.lua
    ft = { "python", "julia", "r", "lua" },
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")

      -- Use pcall to handle iron.nvim setup safely
      local success, err = pcall(function()
        iron.setup({
          config = {
            -- Enable scratch REPL for better cell handling
            scratch_repl = true,
            -- Configure language-specific REPL commands and behavior
            repl_definition = {
              python = {
                command = { "ipython" },
                -- Support for Jupyter-style code blocks
                block_dividers = { "# %%", "#%%" }
              },
            },
            -- REPL window appears as a vertical split on the right
            repl_open_cmd = "vertical botright split",
            -- Use escape to exit REPL insert mode
            close_on_exit = true,
            -- Disable highlight_last to avoid the nvim__set_hl_ns error
            highlight_last = false,
            -- Don't map plug keys to prevent table.insert errors
            should_map_plug = false,
          },
          -- Keymaps are defined in which-key.lua
          keymaps = {},
        })
      end)

      if not success then
        vim.notify("Error setting up iron.nvim: " .. tostring(err), vim.log.levels.WARN)
      end
    end,
  },

  -- Add dependency for mini.hipatterns for cell styling
  {
    "echasnovski/mini.hipatterns",
    version = "*",
    lazy = true,
  }
}

