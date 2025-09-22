-- Claude Worktree Session Statusline Component
local M = {}

function M.get_session_status()
  local ok, claude = pcall(require, "neotex.core.claude-worktree")
  if not ok or not claude.current_session then
    return ""
  end
  
  local session = claude.sessions[claude.current_session]
  if not session then
    return ""
  end
  
  -- Icon based on session type
  local icon = ({
    feature = "󰊕",
    bugfix = "󰁨",
    refactor = "󰌵",
    experiment = "󰙨",
    hotfix = "󰈸"
  })[session.type] or "󰚩"
  
  return string.format("%s %s:%s", 
    icon,
    session.type and session.type:sub(1,3) or "ses",
    claude.current_session
  )
end

-- For lualine users
function M.lualine_component()
  return {
    M.get_session_status,
    cond = function()
      local ok, claude = pcall(require, "neotex.core.claude-worktree")
      return ok and claude.current_session ~= nil
    end,
    color = { fg = "#61afef", gui = "bold" },
  }
end

-- For use in custom statusline
function M.statusline()
  local status = M.get_session_status()
  if status ~= "" then
    return " " .. status .. " "
  end
  return ""
end

-- Get session type for conditional formatting
function M.get_session_type()
  local ok, claude = pcall(require, "neotex.core.claude-worktree")
  if not ok or not claude.current_session then
    return nil
  end
  
  local session = claude.sessions[claude.current_session]
  return session and session.type or nil
end

-- Get full session info for detailed display
function M.get_session_info()
  local ok, claude = pcall(require, "neotex.core.claude-worktree")
  if not ok or not claude.current_session then
    return nil
  end
  
  local session = claude.sessions[claude.current_session]
  if not session then
    return nil
  end
  
  return {
    name = claude.current_session,
    type = session.type,
    branch = session.branch,
    worktree = session.worktree_path,
    created = session.created
  }
end

return M