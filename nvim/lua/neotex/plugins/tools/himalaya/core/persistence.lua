-- Scheduled Email Persistence Module
-- Phase 1: Basic file-based persistence with atomic writes

local M = {}

local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Configuration (dynamically check test mode)
function M.get_config()
  return {
    queue_file = _G.HIMALAYA_TEST_MODE and '/tmp/himalaya_test_scheduled_emails.json' 
      or vim.fn.expand('~/.config/himalaya/scheduled_emails.json'),
    backup_dir = _G.HIMALAYA_TEST_MODE and '/tmp/himalaya_test_backups/' 
      or vim.fn.expand('~/.config/himalaya/backups/'),
    max_backups = 5,
    version = "1.0",
  }
end

-- For backward compatibility
M.config = M.get_config()

-- Ensure required directories exist
function M.ensure_directories()
  local config = M.get_config()
  local queue_dir = vim.fn.fnamemodify(config.queue_file, ':h')
  if vim.fn.isdirectory(queue_dir) == 0 then
    vim.fn.mkdir(queue_dir, 'p')
  end
  
  if vim.fn.isdirectory(config.backup_dir) == 0 then
    vim.fn.mkdir(config.backup_dir, 'p')
  end
end

-- Generate unique instance ID for this Neovim session
function M.get_instance_id()
  if not M._instance_id then
    M._instance_id = 'nvim_' .. os.time() .. '_' .. math.random(1000, 9999)
  end
  return M._instance_id
end

-- Validate queue data structure
function M.validate_queue_data(data)
  if type(data) ~= 'table' then
    return false, "Queue data must be a table"
  end
  
  if not data.version then
    return false, "Missing version field"
  end
  
  if not data.queue or type(data.queue) ~= 'table' then
    return false, "Missing or invalid queue field"
  end
  
  -- Validate each email item
  for id, item in pairs(data.queue) do
    if type(item) ~= 'table' then
      return false, "Invalid email item: " .. id
    end
    
    if not item.id or not item.scheduled_for or not item.email_data then
      return false, "Missing required fields in email: " .. id
    end
    
    if type(item.scheduled_for) ~= 'number' then
      return false, "Invalid scheduled_for timestamp in email: " .. id
    end
    
    if type(item.email_data) ~= 'table' then
      return false, "Invalid email_data in email: " .. id
    end
  end
  
  return true, "Valid queue data"
end

-- Create backup of current queue file
function M.backup_queue_file()
  if vim.fn.filereadable(M.get_config().queue_file) == 0 then
    return true -- No file to backup
  end
  
  M.ensure_directories()
  
  local timestamp = os.date('%Y%m%d_%H%M%S')
  local backup_file = M.get_config().backup_dir .. 'scheduled_emails_' .. timestamp .. '.json'
  
  -- Copy file to backup location
  local success = vim.fn.writefile(
    vim.fn.readfile(M.get_config().queue_file),
    backup_file
  )
  
  if success == 0 then
    logger.debug('Created backup: ' .. backup_file)
    M.cleanup_old_backups()
    return true
  else
    logger.warn('Failed to create backup: ' .. backup_file)
    return false
  end
end

-- Remove old backup files, keeping only max_backups
function M.cleanup_old_backups()
  local backups = {}
  
  -- Get all backup files
  local files = vim.fn.glob(M.get_config().backup_dir .. 'scheduled_emails_*.json', 0, 1)
  
  for _, file in ipairs(files) do
    local stat = vim.loop.fs_stat(file)
    if stat then
      table.insert(backups, {
        file = file,
        mtime = stat.mtime.sec
      })
    end
  end
  
  -- Sort by modification time (newest first)
  table.sort(backups, function(a, b) return a.mtime > b.mtime end)
  
  -- Remove old backups beyond max_backups
  for i = M.get_config().max_backups + 1, #backups do
    vim.fn.delete(backups[i].file)
    logger.debug('Removed old backup: ' .. backups[i].file)
  end
end

-- Load queue from disk
function M.load_queue()
  M.ensure_directories()
  
  if vim.fn.filereadable(M.get_config().queue_file) == 0 then
    logger.debug('No queue file found, starting with empty queue')
    M._last_load_time = os.time()
    return {}
  end
  
  local content = vim.fn.readfile(M.get_config().queue_file)
  if not content or #content == 0 then
    logger.debug('Empty queue file, starting with empty queue')
    M._last_load_time = os.time()
    return {}
  end
  
  local json_str = table.concat(content, '\n')
  local success, data = pcall(vim.json.decode, json_str)
  
  if not success then
    logger.error('Failed to parse queue file JSON: ' .. tostring(data))
    M.recover_from_corruption()
    M._last_load_time = os.time()
    return {}
  end
  
  local valid, error_msg = M.validate_queue_data(data)
  if not valid then
    logger.error('Invalid queue data: ' .. error_msg)
    M.recover_from_corruption()
    M._last_load_time = os.time()
    return {}
  end
  
  -- Track when we loaded this
  M._last_load_time = os.time()
  
  logger.debug('Loaded queue with ' .. vim.tbl_count(data.queue) .. ' emails')
  return data.queue or {}
end

-- Recover from corrupted queue file
function M.recover_from_corruption()
  logger.warn("Queue file corrupted, attempting recovery from backups")
  
  -- Get backup files sorted by newest first
  local files = vim.fn.glob(M.get_config().backup_dir .. 'scheduled_emails_*.json', 0, 1)
  local backups = {}
  
  for _, file in ipairs(files) do
    local stat = vim.loop.fs_stat(file)
    if stat then
      table.insert(backups, {
        file = file,
        mtime = stat.mtime.sec
      })
    end
  end
  
  table.sort(backups, function(a, b) return a.mtime > b.mtime end)
  
  -- Try each backup file
  for _, backup in ipairs(backups) do
    local queue = M.load_queue_from_file(backup.file)
    if queue then
      logger.info("Recovered queue from backup: " .. backup.file)
      -- Copy the good backup to main location
      vim.fn.writefile(
        vim.fn.readfile(backup.file),
        M.get_config().queue_file
      )
      return queue
    end
  end
  
  logger.warn("All recovery attempts failed, queue will start empty")
  return {}
end

-- Load queue from specific file (for backup recovery)
function M.load_queue_from_file(file_path)
  if vim.fn.filereadable(file_path) == 0 then
    return nil
  end
  
  local content = vim.fn.readfile(file_path)
  if not content or #content == 0 then
    return nil
  end
  
  local json_str = table.concat(content, '\n')
  local success, data = pcall(vim.json.decode, json_str)
  
  if not success then
    logger.debug('Failed to parse backup file: ' .. file_path)
    return nil
  end
  
  local valid, _ = M.validate_queue_data(data)
  if not valid then
    logger.debug('Invalid data in backup file: ' .. file_path)
    return nil
  end
  
  return data.queue or {}
end

-- Save queue to disk with atomic write
function M.save_queue(queue)
  M.ensure_directories()
  
  -- Create backup before saving
  M.backup_queue_file()
  
  -- Prepare data structure
  local data = {
    version = M.get_config().version,
    created = os.date('%Y-%m-%dT%H:%M:%SZ'),
    last_modified = os.date('%Y-%m-%dT%H:%M:%SZ'),
    queue = queue or {},
    statistics = {
      total_scheduled = 0,
      total_pending = 0,
    }
  }
  
  -- Calculate statistics
  for _, item in pairs(queue or {}) do
    data.statistics.total_scheduled = data.statistics.total_scheduled + 1
    if item.status == 'pending' then
      data.statistics.total_pending = data.statistics.total_pending + 1
    end
  end
  
  -- Validate before saving
  local valid, error_msg = M.validate_queue_data(data)
  if not valid then
    logger.error('Cannot save invalid queue data: ' .. error_msg)
    return false
  end
  
  -- Convert to JSON
  local success, json_str = pcall(vim.json.encode, data)
  if not success then
    logger.error('Failed to encode queue to JSON: ' .. tostring(json_str))
    return false
  end
  
  -- Debug in test mode
  if _G.HIMALAYA_TEST_MODE then
    local config = M.get_config()
    -- print("DEBUG: Saving to file: " .. config.queue_file)
  end
  
  -- Atomic write: write to temp file first
  local temp_file = M.get_config().queue_file .. '.tmp'
  local write_result = vim.fn.writefile(vim.split(json_str, '\n'), temp_file)
  
  if write_result ~= 0 then
    logger.error('Failed to write temporary queue file: ' .. temp_file)
    return false
  end
  
  -- Move temp file to final location (atomic on most filesystems)
  local move_success = vim.fn.rename(temp_file, M.get_config().queue_file)
  
  if move_success ~= 0 then
    logger.error('Failed to move temporary file to final location')
    -- Clean up temp file
    vim.fn.delete(temp_file)
    return false
  end
  
  logger.debug('Saved queue with ' .. vim.tbl_count(queue or {}) .. ' emails')
  
  -- Update our load time to reflect this save
  M._last_load_time = os.time()
  
  return true
end

-- Clean up expired emails from queue
function M.cleanup_expired_emails(queue)
  if not queue then return queue end
  
  local current_time = os.time()
  local cleaned_queue = {}
  local removed_count = 0
  
  for id, item in pairs(queue) do
    -- Remove emails that were scheduled more than 1 hour ago and failed
    local is_expired = (current_time - item.scheduled_for) > 3600 and 
                      (item.status == 'failed' or item.status == 'sent')
    
    if not is_expired then
      cleaned_queue[id] = item
    else
      removed_count = removed_count + 1
      logger.debug('Removed expired email: ' .. id)
    end
  end
  
  if removed_count > 0 then
    logger.info('Cleaned up ' .. removed_count .. ' expired emails')
  end
  
  return cleaned_queue
end

-- Check if queue file has been modified since last load
function M.is_queue_file_newer(last_load_time)
  if vim.fn.filereadable(M.get_config().queue_file) == 0 then
    return false
  end
  
  local stat = vim.loop.fs_stat(M.get_config().queue_file)
  if not stat then
    return false
  end
  
  -- Compare modification time
  return stat.mtime.sec > (last_load_time or 0)
end

-- Get file modification time
function M.get_queue_file_mtime()
  if vim.fn.filereadable(M.get_config().queue_file) == 0 then
    return 0
  end
  
  local stat = vim.loop.fs_stat(M.get_config().queue_file)
  return stat and stat.mtime.sec or 0
end

-- Merge external queue changes with current queue
function M.merge_queue_changes(current_queue, disk_queue)
  if not disk_queue then
    return current_queue
  end
  
  local merged_queue = {}
  local changes_detected = false
  
  -- Add all disk items (external changes take precedence)
  for id, disk_item in pairs(disk_queue) do
    merged_queue[id] = disk_item
    
    -- Check if this is a new or changed item
    if not current_queue[id] or 
       (disk_item.status ~= current_queue[id].status) or
       (disk_item.scheduled_for ~= current_queue[id].scheduled_for) then
      changes_detected = true
      logger.debug('External change detected for email: ' .. id)
    end
  end
  
  -- Keep current items that aren't on disk (may be new local changes)
  for id, current_item in pairs(current_queue) do
    if not disk_queue[id] then
      merged_queue[id] = current_item
    end
  end
  
  return merged_queue, changes_detected
end

-- Get health information about persistence
function M.health_check()
  M.ensure_directories()
  
  return {
    queue_file_exists = vim.fn.filereadable(M.get_config().queue_file) == 1,
    queue_file_writable = vim.fn.filewritable(M.get_config().queue_file) ~= 0,
    backup_dir_exists = vim.fn.isdirectory(M.get_config().backup_dir) == 1,
    backup_count = #vim.fn.glob(M.get_config().backup_dir .. 'scheduled_emails_*.json', 0, 1),
    queue_file_size = vim.fn.getfsize(M.get_config().queue_file),
    instance_id = M.get_instance_id(),
    last_load_time = M._last_load_time,
    queue_file_mtime = M.get_queue_file_mtime(),
  }
end

return M