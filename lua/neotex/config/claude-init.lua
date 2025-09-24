-----------------------------------------------------------
-- Claude-Worktree Integration Initialization
--
-- Sets up the Claude Code + Git Worktree integration
-- for managing multiple parallel development sessions
-----------------------------------------------------------

local M = {}

function M.setup()
  -- Load claude AI module
  local ok, claude_ai = pcall(require, "neotex.ai-claude")
  
  if not ok then
    vim.notify("Failed to load claude AI module", vim.log.levels.ERROR)
    return
  end

  claude_ai.setup({
    -- Customize options
    max_sessions = 4,
    auto_switch_tab = true,
    create_context_file = true,
    
    -- Customize types if needed
    types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
    default_type = "feature",
  })
  
  -- Visual selection support is now loaded through the main module
  -- No need to load it separately
  -- Visual setup is handled in the main module
  
  -- Clean up stale sessions on startup (silently - only notify if cleaning occurs)
  vim.defer_fn(function()
    if claude_ai.cleanup_sessions then
      claude_ai.cleanup_sessions(true)  -- true = silent mode
    end
  end, 1000)
end

return M