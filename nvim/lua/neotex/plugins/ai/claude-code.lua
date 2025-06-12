return {
  "greggh/claude-code.nvim",
  cmd = { "ClaudeCode" },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- Keys defined in which-key.lua for consistency
  opts = {
    -- Window configuration for horizontal bottom split (default)
    split_ratio = 0.3,     -- Use 30% of screen height
    position = "botright", -- Bottom horizontal split (default)
    enter_insert = true,   -- Enter insert mode when opening
    hide_numbers = true,   -- Hide line numbers in terminal
    hide_signcolumn = true, -- Hide sign column in terminal
    
    -- File refresh options
    file_refresh = {
      enabled = true,      -- Auto-reload files modified by Claude Code
      poll_interval = 1000, -- Check for file changes every 1000ms
    },
    
    -- Git project detection
    git = {
      enabled = true,      -- Use git root as working directory when available
      fallback_to_cwd = true, -- Fallback to current directory if not in git repo
    },
  },
  config = function(_, opts)
    require("claude-code").setup(opts)
    
    -- Create additional commands for convenience
    vim.api.nvim_create_user_command("ClaudeCodeToggle", function()
      vim.cmd("ClaudeCode")
    end, { desc = "Toggle Claude Code terminal" })
    
    vim.api.nvim_create_user_command("ClaudeCodeReload", function()
      require("claude-code").reload_all_files()
    end, { desc = "Reload all files modified by Claude Code" })
  end,
}