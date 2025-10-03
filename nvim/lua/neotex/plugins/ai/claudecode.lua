return {
  "greggh/claude-code.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- Window configuration
    window = {
      split_ratio = 0.40,        -- 40% width, matching old config
      position = "vertical",     -- Vertical split (sidebar)
      enter_insert = true,       -- Auto-enter insert mode
      hide_numbers = true,       -- Clean terminal appearance
      hide_signcolumn = true,
    },

    -- File refresh detection
    refresh = {
      enable = true,             -- Enable file change detection
      updatetime = 100,
      timer_interval = 1000,
      show_notifications = true, -- Show when files are refreshed
    },

    -- Git configuration
    git = {
      use_git_root = true,       -- Set working directory to git root
    },

    -- Shell configuration to suppress pushd output
    shell = {
      separator = "&&",
      pushd_cmd = "pushd >/dev/null 2>&1",  -- Suppress pushd output
      popd_cmd = "popd >/dev/null 2>&1",    -- Suppress popd output
    },

    -- Base command
    command = "claude",

    -- Command variants for different modes
    command_variants = {
      continue = "--continue",
      resume = "--resume",
      verbose = "--verbose",
    },

    -- Keymaps configuration - disabled here as we define them in keys
    keymaps = {
      toggle = {
        normal = false,          -- Disable default keymaps
        terminal = false,
      },
      window_navigation = true,  -- Keep window navigation enabled
      scrolling = true,          -- Keep scrolling enabled
    },
  },

  -- Keys are defined in keymaps.lua for centralized management
  keys = {},

  config = function(_, opts)
    require("claude-code").setup(opts)

    -- Setup session management with proper initialization order
    vim.defer_fn(function()
      -- Initialize session manager first
      local session_manager = require("neotex.plugins.ai.claude.core.session-manager")
      session_manager.setup()

      -- Then setup the main AI claude module
      local ok, claude_module = pcall(require, "neotex.plugins.ai.claude")
      if ok and claude_module and claude_module.setup then
        claude_module.setup()
      end
    end, 100)

    -- Configure terminal behavior to match old setup
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*claude*",
      callback = function()
        -- Make buffer unlisted to prevent it from appearing in tabs/bufferline
        vim.bo.buflisted = false
        -- Set buffer type to prevent it from being considered a normal buffer
        vim.bo.buftype = "terminal"
        -- Hide from buffer lists
        vim.bo.bufhidden = "hide"

        -- Note: <C-c> mapping for Claude Code toggle is defined in keymaps.lua
      end,
    })

    -- Additional autocmd to catch any Claude Code terminal buffers that might get listed later
    -- IMPORTANT: Check buftype == "terminal" FIRST to avoid catching .claude/ directory files
    vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
      pattern = "*",
      callback = function()
        local bufname = vim.api.nvim_buf_get_name(0)
        -- Only unlist Claude Code terminal buffers, not .claude/ directory files
        if vim.bo.buftype == "terminal" and (bufname:match("claude") or bufname:match("ClaudeCode")) then
          vim.bo.buflisted = false
          vim.bo.bufhidden = "hide"
        end
      end,
    })
  end,
}
