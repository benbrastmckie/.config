-----------------------------------------------------------
-- Claude-Worktree Integration Initialization
--
-- Sets up the Claude Code + Git Worktree integration
-- for managing multiple parallel development sessions
-----------------------------------------------------------

local M = {}

function M.setup()
  -- Load claude-worktree module
  local ok, claude_worktree = pcall(require, "neotex.core.claude-worktree")
  
  if not ok then
    vim.notify("Failed to load claude-worktree module", vim.log.levels.ERROR)
    return
  end
  
  claude_worktree.setup({
    -- Customize options
    max_sessions = 4,
    auto_switch_tab = true,
    create_context_file = true,
    
    -- Customize types if needed
    types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
    default_type = "feature",
  })
  
  -- Optional: Clean up stale sessions on startup
  vim.defer_fn(function()
    claude_worktree.cleanup_sessions()
  end, 1000)
end

-- Auto-initialize if in a git repository
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      if vim.fn.isdirectory(".git") == 1 then
        M.setup()
      end
    end, 100)
  end,
})

return M