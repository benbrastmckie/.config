-- Local Trash System
-- Manages deleted emails with recovery capabilities

local M = {}

local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local api = require('neotex.plugins.tools.himalaya.core.api')
local events = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_constants = require('neotex.plugins.tools.himalaya.core.events')

-- Trash item schema
local trash_item_schema = {
  email_id = "",          -- Original email ID
  account = "",           -- Account it came from
  folder = "",            -- Original folder
  subject = "",           -- Email subject for display
  from = "",              -- Sender
  date = 0,               -- Original date
  deleted_at = 0,         -- When it was deleted
  size = 0,               -- Email size
  metadata = {}           -- Additional metadata
}

-- Trash storage directory
M.trash_dir = vim.fn.stdpath('data') .. '/himalaya/trash/'

-- Initialize trash system
function M.setup()
  -- Create trash directory
  vim.fn.mkdir(M.trash_dir, 'p')
  
  -- Load trash index
  M.load_index()
  
  -- Clean old items (>30 days by default)
  local retention_days = config.get('trash.retention_days', 30)
  M.cleanup_old_items(retention_days * 24 * 60 * 60)
end

-- Move email to trash
function M.delete_email(email_id, email_info)
  email_info = email_info or {}
  
  -- Get current account and folder
  local account = config.get_current_account_name()
  local folder = state.get('current_folder', 'INBOX')
  
  -- Create trash item
  local trash_item = {
    email_id = email_id,
    account = account,
    folder = folder,
    subject = email_info.subject or "No subject",
    from = email_info.from or "Unknown",
    date = email_info.date or os.time(),
    deleted_at = os.time(),
    size = email_info.size or 0,
    metadata = email_info.metadata or {}
  }
  
  -- Save email content to trash
  local content_path = M.get_content_path(email_id)
  local save_result = M.save_email_content(email_id, content_path)
  
  if not save_result.success then
    return save_result
  end
  
  -- Delete from server
  local cmd_args = {'message', 'delete', email_id}
  local result = utils.execute_himalaya(cmd_args, { 
    account = account, 
    folder = folder 
  })
  
  if not result.success then
    -- Clean up saved content
    vim.fn.delete(content_path)
    return api.error("Failed to delete email: " .. result.error, "DELETE_FAILED")
  end
  
  -- Add to trash index
  M.add_to_index(trash_item)
  
  -- Emit event
  events.emit(event_constants.EMAIL_DELETED, {
    email_id = email_id,
    moved_to_trash = true,
    trash_item = trash_item
  })
  
  logger.info("Moved email to trash: " .. email_id)
  
  return api.success(trash_item)
end

-- Recover email from trash
function M.recover_email(trash_id)
  local trash_item = M.get_trash_item(trash_id)
  
  if not trash_item then
    return api.error("Trash item not found", "TRASH_ITEM_NOT_FOUND")
  end
  
  -- Get email content
  local content_path = M.get_content_path(trash_item.email_id)
  
  if vim.fn.filereadable(content_path) == 0 then
    return api.error("Email content not found in trash", "CONTENT_NOT_FOUND")
  end
  
  -- Read email content
  local content = vim.fn.readfile(content_path)
  content = table.concat(content, "\n")
  
  -- Import back to original folder
  local cmd_args = {'message', 'import', trash_item.folder}
  local result = utils.execute_himalaya(cmd_args, {
    account = trash_item.account,
    input = content
  })
  
  if not result.success then
    return api.error("Failed to recover email: " .. result.error, "RECOVER_FAILED")
  end
  
  -- Remove from trash
  M.remove_from_trash(trash_id)
  
  logger.info("Recovered email from trash: " .. trash_item.email_id)
  
  return api.success({
    email_id = result.data.id or trash_item.email_id,
    folder = trash_item.folder,
    account = trash_item.account
  })
end

-- Permanently delete from trash
function M.delete_permanently(trash_id)
  local trash_item = M.get_trash_item(trash_id)
  
  if not trash_item then
    return api.error("Trash item not found", "TRASH_ITEM_NOT_FOUND")
  end
  
  -- Remove from trash
  M.remove_from_trash(trash_id)
  
  logger.info("Permanently deleted from trash: " .. trash_item.email_id)
  
  return api.success({ deleted = trash_id })
end

-- Empty trash
function M.empty_trash(options)
  options = options or {}
  local index = M.load_index()
  local deleted_count = 0
  
  for trash_id, item in pairs(index) do
    if not options.account or item.account == options.account then
      M.remove_from_trash(trash_id)
      deleted_count = deleted_count + 1
    end
  end
  
  logger.info("Emptied trash: " .. deleted_count .. " items deleted")
  
  return api.success({ deleted_count = deleted_count })
end

-- List trash items
function M.list_trash(options)
  options = options or {}
  local index = M.load_index()
  local items = {}
  
  for trash_id, item in pairs(index) do
    if not options.account or item.account == options.account then
      item.trash_id = trash_id
      item.age_days = math.floor((os.time() - item.deleted_at) / 86400)
      item.human_size = utils.string.human_size(item.size)
      table.insert(items, item)
    end
  end
  
  -- Sort by deletion date (newest first)
  table.sort(items, function(a, b)
    return a.deleted_at > b.deleted_at
  end)
  
  -- Apply pagination
  if options.limit then
    local start_idx = ((options.page or 1) - 1) * options.limit + 1
    local end_idx = start_idx + options.limit - 1
    local paginated = {}
    
    for i = start_idx, math.min(end_idx, #items) do
      table.insert(paginated, items[i])
    end
    
    return api.success({
      items = paginated,
      total = #items,
      page = options.page or 1,
      pages = math.ceil(#items / options.limit)
    })
  end
  
  return api.success({ items = items, total = #items })
end

-- Get trash statistics
function M.get_stats()
  local index = M.load_index()
  local stats = {
    total = 0,
    by_account = {},
    total_size = 0,
    oldest_date = nil,
    newest_date = nil
  }
  
  for _, item in pairs(index) do
    stats.total = stats.total + 1
    stats.total_size = stats.total_size + (item.size or 0)
    
    -- By account
    stats.by_account[item.account] = (stats.by_account[item.account] or 0) + 1
    
    -- Date range
    if not stats.oldest_date or item.deleted_at < stats.oldest_date then
      stats.oldest_date = item.deleted_at
    end
    if not stats.newest_date or item.deleted_at > stats.newest_date then
      stats.newest_date = item.deleted_at
    end
  end
  
  stats.human_size = utils.format_size(stats.total_size)
  stats.recoverable = stats.total
  stats.deleted = 0 -- Track permanently deleted separately if needed
  
  return stats
end

-- Helper functions

-- Get content path for email
function M.get_content_path(email_id)
  return M.trash_dir .. email_id .. '.eml'
end

-- Save email content
function M.save_email_content(email_id, path)
  -- Export email to file
  local cmd_args = {'message', 'export', email_id}
  local result = utils.execute_himalaya(cmd_args)
  
  if not result.success then
    return api.error("Failed to export email: " .. result.error, "EXPORT_FAILED")
  end
  
  -- Write to file
  local ok, err = pcall(function()
    local file = io.open(path, 'w')
    if file then
      file:write(result.output)
      file:close()
    else
      error("Failed to open file for writing")
    end
  end)
  
  if not ok then
    return api.error("Failed to save email content: " .. tostring(err), "SAVE_FAILED")
  end
  
  return api.success({ path = path })
end

-- Load trash index
function M.load_index()
  local index_path = M.trash_dir .. 'index.json'
  
  if vim.fn.filereadable(index_path) == 0 then
    return {}
  end
  
  local content = vim.fn.readfile(index_path)
  content = table.concat(content, "\n")
  
  local ok, index = pcall(vim.json.decode, content)
  if not ok then
    logger.error("Failed to load trash index: " .. tostring(index))
    return {}
  end
  
  return index
end

-- Save trash index
function M.save_index(index)
  local index_path = M.trash_dir .. 'index.json'
  
  local ok, json = pcall(vim.json.encode, index)
  if not ok then
    logger.error("Failed to encode trash index: " .. tostring(json))
    return false
  end
  
  local file = io.open(index_path, 'w')
  if file then
    file:write(json)
    file:close()
    return true
  end
  
  return false
end

-- Add to trash index
function M.add_to_index(trash_item)
  local index = M.load_index()
  local trash_id = trash_item.email_id .. '_' .. trash_item.deleted_at
  
  index[trash_id] = trash_item
  M.save_index(index)
  
  return trash_id
end

-- Get trash item
function M.get_trash_item(trash_id)
  local index = M.load_index()
  return index[trash_id]
end

-- Remove from trash
function M.remove_from_trash(trash_id)
  local trash_item = M.get_trash_item(trash_id)
  
  if not trash_item then
    return false
  end
  
  -- Delete content file
  local content_path = M.get_content_path(trash_item.email_id)
  vim.fn.delete(content_path)
  
  -- Remove from index
  local index = M.load_index()
  index[trash_id] = nil
  M.save_index(index)
  
  return true
end

-- Clean up old items
function M.cleanup_old_items(max_age_seconds)
  local index = M.load_index()
  local now = os.time()
  local cleaned = 0
  
  for trash_id, item in pairs(index) do
    if now - item.deleted_at > max_age_seconds then
      M.remove_from_trash(trash_id)
      cleaned = cleaned + 1
    end
  end
  
  if cleaned > 0 then
    logger.info("Cleaned " .. cleaned .. " old items from trash")
  end
  
  return cleaned
end

return M