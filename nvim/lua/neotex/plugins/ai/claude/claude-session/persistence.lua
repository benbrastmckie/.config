-- Session persistence utilities for Claude AI integration
local M = {}
local Path = require("plenary.path")

-- Session state file location
M.state_dir = vim.fn.stdpath("data") .. "/claude"
M.state_file = M.state_dir .. "/last_session.json"
M.sessions_dir = M.state_dir .. "/sessions"

-- Ensure state directory exists
function M.ensure_state_dir()
  local dir = Path:new(M.state_dir)
  if not dir:exists() then
    dir:mkdir({ parents = true })
  end
end

-- Ensure sessions directory exists
function M.ensure_sessions_dir()
  local dir = Path:new(M.sessions_dir)
  if not dir:exists() then
    dir:mkdir({ parents = true })
  end
end

-- Save data to JSON file
function M.save_json(filepath, data)
  M.ensure_state_dir()
  local file = io.open(filepath, "w")
  if file then
    file:write(vim.fn.json_encode(data))
    file:close()
    return true
  end
  return false
end

-- Load data from JSON file
function M.load_json(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  if content == "" then
    return nil
  end

  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil
  end

  return data
end

-- Get session file path
function M.get_session_file(session_id)
  M.ensure_sessions_dir()
  return M.sessions_dir .. "/" .. session_id .. ".json"
end

-- List all session files
function M.list_session_files()
  M.ensure_sessions_dir()
  local files = vim.fn.glob(M.sessions_dir .. "/*.json", false, true)
  return files
end

return M