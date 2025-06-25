return {
  "coder/claudecode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- Port range for WebSocket connection
    port_range = { min = 10000, max = 65535 },
    auto_start = true,     -- Automatically start Claude Code
    log_level = "info",    -- Logging level
    
    -- Terminal configuration
    terminal = {
      split_side = "right",  -- Open terminal on right side (matches your preference)
      provider = "native",   -- Use native terminal (or "snacks" if you have it)
      auto_close = true,     -- Auto-close terminal when Claude Code exits
    },
  },
  
  -- NOTE: Key mappings are now defined in which-key.lua under the AI HELP group
  -- to avoid conflicts with other leader mappings
  keys = {},
  
  config = function(_, opts)
    require("claudecode").setup(opts)
    
    -- Create additional commands for convenience (maintaining compatibility)
    vim.api.nvim_create_user_command("ClaudeCodeToggle", function()
      vim.cmd("ClaudeCode")
    end, { desc = "Toggle Claude Code terminal" })
    
    -- Command to add current buffer to Claude context
    vim.api.nvim_create_user_command("ClaudeCodeAddBuffer", function()
      local file = vim.fn.expand("%:p")
      if file ~= "" then
        vim.cmd("ClaudeCodeAdd " .. file)
      else
        require('neotex.util.notifications').ai('No file to add to Claude context', require('neotex.util.notifications').categories.WARNING)
      end
    end, { desc = "Add current buffer to Claude Code context" })
    
    -- Command to add current directory to Claude context
    vim.api.nvim_create_user_command("ClaudeCodeAddDir", function()
      local cwd = vim.fn.getcwd()
      vim.cmd("ClaudeCodeAdd " .. cwd)
    end, { desc = "Add current directory to Claude Code context" })
  end,
}