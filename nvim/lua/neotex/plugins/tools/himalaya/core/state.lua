-- State management module
-- Centralized state tracking for the Himalaya plugin

local M = {}

-- State storage
M.state = {
  -- Sync state
  sync = {
    status = "idle", -- idle, running, error
    last_sync = nil,
    last_error = nil,
    start_time = nil,
    current_channel = nil,
  },
  
  -- OAuth state
  oauth = {
    last_refresh = 0,
    refresh_in_progress = false,
    last_check = 0,
  },
  
  -- UI state
  ui = {
    sidebar_open = false,
    reader_open = false,
    current_folder = "INBOX",
    current_email_id = nil,
    selected_emails = {},
  },
  
  -- Email cache
  cache = {
    folders = {},
    emails = {},
    last_update = {},
  },
  
  -- Process state
  processes = {
    sync_job_id = nil,
    reader_job_id = nil,
  },
}

-- Get a state value by path (e.g., "sync.status")
function M.get(path, default)
  local value = M.state
  for part in path:gmatch("[^.]+") do
    if type(value) ~= "table" then
      return default
    end
    value = value[part]
  end
  return value ~= nil and value or default
end

-- Set a state value by path
function M.set(path, value)
  local state = M.state
  local parts = {}
  for part in path:gmatch("[^.]+") do
    table.insert(parts, part)
  end
  
  -- Navigate to parent
  for i = 1, #parts - 1 do
    local part = parts[i]
    if type(state[part]) ~= "table" then
      state[part] = {}
    end
    state = state[part]
  end
  
  -- Set the value
  state[parts[#parts]] = value
end

-- Update multiple state values at once
function M.update(updates)
  for path, value in pairs(updates) do
    M.set(path, value)
  end
end

-- Clear a state section
function M.clear(path)
  M.set(path, {})
end

-- Reset all state
function M.reset()
  M.state = {
    sync = {
      status = "idle",
      last_sync = nil,
      last_error = nil,
      start_time = nil,
      current_channel = nil,
    },
    oauth = {
      last_refresh = 0,
      refresh_in_progress = false,
      last_check = 0,
    },
    ui = {
      sidebar_open = false,
      reader_open = false,
      current_folder = "INBOX",
      current_email_id = nil,
      selected_emails = {},
    },
    cache = {
      folders = {},
      emails = {},
      last_update = {},
    },
    processes = {
      sync_job_id = nil,
      reader_job_id = nil,
    },
  }
end

-- Sync-specific helpers
function M.is_syncing()
  return M.get("sync.status") == "running"
end

function M.set_sync_running(channel)
  M.update({
    ["sync.status"] = "running",
    ["sync.start_time"] = os.time(),
    ["sync.current_channel"] = channel,
  })
end

function M.set_sync_complete(success, error_msg)
  M.update({
    ["sync.status"] = success and "idle" or "error",
    ["sync.last_sync"] = os.time(),
    ["sync.last_error"] = error_msg,
    ["sync.current_channel"] = nil,
  })
end

-- UI-specific helpers
function M.set_current_folder(folder)
  M.set("ui.current_folder", folder)
end

function M.get_current_folder()
  return M.get("ui.current_folder", "INBOX")
end

function M.set_current_email(email_id)
  M.set("ui.current_email_id", email_id)
end

function M.get_current_email()
  return M.get("ui.current_email_id")
end

-- Cache helpers
function M.cache_emails(folder, emails)
  M.set("cache.emails." .. folder, emails)
  M.set("cache.last_update." .. folder, os.time())
end

function M.get_cached_emails(folder)
  return M.get("cache.emails." .. folder, {})
end

function M.is_cache_fresh(folder, max_age)
  max_age = max_age or 300 -- 5 minutes default
  local last_update = M.get("cache.last_update." .. folder, 0)
  return (os.time() - last_update) < max_age
end

-- Debug helper
function M.dump()
  return vim.inspect(M.state)
end

return M