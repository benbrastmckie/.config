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
  
  -- Load visual selection support for Claude
  local visual_ok, claude_visual = pcall(require, "neotex.core.claude-visual")
  if not visual_ok then
    vim.notify("Failed to load Claude Visual module", vim.log.levels.WARN)
  else
    -- Initialize the visual selection handling
    claude_visual.setup()
  end
  
  -- Clean up stale sessions on startup (silently - only notify if cleaning occurs)
  vim.defer_fn(function()
    claude_worktree.cleanup_sessions(true)  -- true = silent mode
  end, 1000)
end

return M