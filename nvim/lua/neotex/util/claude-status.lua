-- Claude Worktree Session Statusline Component
local M = {}

function M.get_session_status()
  local ok, claude = pcall(require, "neotex.plugins.ai.claude")
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
      local ok, claude = pcall(require, "neotex.plugins.ai.claude")
      return ok and claude.current_session ~= nil
    end,
    color = { fg = "#61afef", gui = "bold" },
    on_click = function()
      -- Open the session browser on click
      vim.cmd("ClaudeSessions")
    end,
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
  local ok, claude = pcall(require, "neotex.plugins.ai.claude")
  if not ok or not claude.current_session then
    return nil
  end
  
  local session = claude.sessions[claude.current_session]
  return session and session.type or nil
end

-- Get full session info for detailed display
function M.get_session_info()
  local ok, claude = pcall(require, "neotex.plugins.ai.claude")
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

-- Get color based on session type
function M.get_type_color(type)
  local colors = {
    feature = "#61afef",   -- Blue
    bugfix = "#e06c75",    -- Red
    refactor = "#d19a66",  -- Orange
    experiment = "#c678dd", -- Purple
    hotfix = "#e5c07b",    -- Yellow
  }
  return colors[type] or "#98c379"  -- Default green
end

-- Lualine component with dynamic color based on type
function M.lualine_colored()
  return {
    M.get_session_status,
    cond = function()
      local ok, claude = pcall(require, "neotex.plugins.ai.claude")
      return ok and claude.current_session ~= nil
    end,
    color = function()
      local ok, claude = pcall(require, "neotex.plugins.ai.claude")
      if not ok or not claude.current_session then
        return { fg = "#98c379", gui = "bold" }
      end
      
      local session = claude.sessions[claude.current_session]
      if not session then
        return { fg = "#98c379", gui = "bold" }
      end
      
      return { fg = M.get_type_color(session.type), gui = "bold" }
    end,
    on_click = function()
      vim.cmd("ClaudeSessions")
    end,
  }
end

return M