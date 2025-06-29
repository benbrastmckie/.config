-- Simplified sidebar display module
-- Provides clean, simple progress display

local M = {}

-- Dependencies
local config = require("neotex.plugins.tools.himalaya.core.config")
local state = require("neotex.plugins.tools.himalaya.core.state")
local logger = require("neotex.plugins.tools.himalaya.core.logger")

-- Format time ago
local function format_time_ago(timestamp)
  if not timestamp then return "never" end
  
  local now = os.time()
  local diff = now - timestamp
  
  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. "m ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. "h ago"
  else
    local days = math.floor(diff / 86400)
    return days .. "d ago"
  end
end

-- Get simple sync status
function M.get_sync_status()
  local mbsync = require("neotex.plugins.tools.himalaya.sync.mbsync")
  local status = mbsync.get_status()
  
  if status.running then
    -- Simple, honest progress
    return "🔄 Syncing email..."
  elseif status.last_error then
    return "⚠️  Sync failed (see :messages)"
  elseif status.last_sync then
    return "✓ Synced " .. format_time_ago(status.last_sync)
  else
    return "○ Not synced yet"
  end
end

-- Format email list header with simple sync status
function M.format_header(folder, email_count)
  local lines = {}
  local account = config.get_current_account_name()
  
  -- Account and folder
  table.insert(lines, string.format("📧 %s / %s", account, folder))
  
  -- Email count
  table.insert(lines, string.format("   %d emails", email_count or 0))
  
  -- Sync status
  local sync_status = M.get_sync_status()
  table.insert(lines, "   " .. sync_status)
  
  -- Separator
  table.insert(lines, string.rep("─", 50))
  table.insert(lines, "")
  
  return lines
end

-- Format email list entry
function M.format_email_entry(email)
  -- Parse flags
  local seen = false
  if email.flags and type(email.flags) == "table" then
    for _, flag in ipairs(email.flags) do
      if flag == "Seen" then
        seen = true
        break
      end
    end
  end
  
  local status = seen and " " or "●"
  
  -- Parse from field
  local from = "Unknown"
  if email.from then
    if type(email.from) == "table" then
      from = email.from.name or email.from.addr or "Unknown"
    else
      from = tostring(email.from)
    end
  end
  
  -- Truncate fields
  from = from:sub(1, 20)
  local subject = (email.subject or "(No subject)"):sub(1, 40)
  local date = email.date or ""
  
  -- Simple format
  return string.format("[%s] %-20s  %-40s  %s", status, from, subject, date)
end

-- Format footer with keybindings
function M.format_footer()
  return {
    "",
    string.rep("─", 50),
    "r:refresh  n/p:page  <CR>:read  d:delete",
    "c:compose  s:sync  q:quit",
  }
end

-- Update sidebar content
function M.update_content(buf, emails, folder)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local lines = {}
  
  -- Header
  vim.list_extend(lines, M.format_header(folder, #emails))
  
  -- Email list
  if #emails == 0 then
    table.insert(lines, "  No emails in this folder")
  else
    for _, email in ipairs(emails) do
      table.insert(lines, M.format_email_entry(email))
    end
  end
  
  -- Footer
  vim.list_extend(lines, M.format_footer())
  
  -- Update buffer
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Timer for status updates
local status_timer = nil

-- Start periodic sync status updates
function M.start_status_updates()
  M.stop_status_updates()
  
  -- Update every 2 seconds when syncing
  status_timer = vim.fn.timer_start(2000, function()
    local mbsync = require("neotex.plugins.tools.himalaya.sync.mbsync")
    if not mbsync.is_running() then
      M.stop_status_updates()
    end
    
    -- Trigger header refresh
    vim.cmd("doautocmd User HimalayaStatusUpdate")
  end, { ["repeat"] = -1 })
end

-- Stop status updates
function M.stop_status_updates()
  if status_timer then
    vim.fn.timer_stop(status_timer)
    status_timer = nil
  end
end

return M