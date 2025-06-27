-- Progress File Validation Module
-- Ensures progress files are valid and not corrupted

local M = {}

local notify = require('neotex.util.notifications')

-- Validate progress data structure
function M.validate_progress_data(data)
  if type(data) ~= 'table' then
    return false, "Progress data must be a table"
  end
  
  -- Required fields
  local required = {'pid', 'last_update'}
  for _, field in ipairs(required) do
    if not data[field] then
      return false, "Missing required field: " .. field
    end
  end
  
  -- Validate PID
  if type(data.pid) ~= 'number' or data.pid <= 0 then
    return false, "Invalid PID"
  end
  
  -- Validate timestamp
  if type(data.last_update) ~= 'number' then
    return false, "Invalid last_update timestamp"
  end
  
  -- Check if data is stale (>60 seconds old)
  local age = os.time() - data.last_update
  if age > 60 then
    return false, string.format("Progress data is stale (%d seconds old)", age)
  end
  
  -- Validate progress structure if present
  if data.progress then
    if type(data.progress) ~= 'table' then
      return false, "Progress field must be a table"
    end
    
    -- Validate numeric fields
    local numeric_fields = {
      'channels_done', 'channels_total',
      'messages_added', 'messages_added_total',
      'messages_updated', 'messages_updated_total',
      'current_message', 'total_messages'
    }
    
    for _, field in ipairs(numeric_fields) do
      local value = data.progress[field]
      if value ~= nil and (type(value) ~= 'number' or value < 0) then
        return false, string.format("Invalid progress.%s: must be non-negative number", field)
      end
    end
    
    -- Validate logical constraints
    if data.progress.current_message and data.progress.total_messages then
      if data.progress.current_message > data.progress.total_messages then
        return false, "current_message cannot exceed total_messages"
      end
    end
  end
  
  return true, nil
end

-- Read and validate progress file
function M.read_validated_progress(account)
  account = account or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  
  local file = io.open(progress_file, 'r')
  if not file then
    return nil, "No progress file found"
  end
  
  local content = file:read('*a')
  file:close()
  
  -- Try to parse JSON
  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    return nil, "Failed to parse progress file: " .. tostring(data)
  end
  
  -- Validate the data
  local valid, err = M.validate_progress_data(data)
  if not valid then
    return nil, "Invalid progress data: " .. err
  end
  
  -- Check if PID is still running
  if data.pid then
    local check = os.execute('kill -0 ' .. data.pid .. ' 2>/dev/null')
    if check ~= 0 then
      return nil, "Sync process no longer running"
    end
  end
  
  return data, nil
end

-- Clean up stale progress files
function M.cleanup_stale_progress_files()
  local cleaned = 0
  
  -- Check common account names
  local accounts = {'gmail', 'work', 'personal'}
  
  for _, account in ipairs(accounts) do
    local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
    local file = io.open(progress_file, 'r')
    
    if file then
      local content = file:read('*a')
      file:close()
      
      local ok, data = pcall(vim.json.decode, content)
      if ok and data.last_update then
        local age = os.time() - data.last_update
        
        -- Remove if older than 5 minutes
        if age > 300 then
          os.remove(progress_file)
          cleaned = cleaned + 1
        end
      end
    end
  end
  
  if cleaned > 0 then
    notify.himalaya(string.format('Cleaned %d stale progress files', cleaned), notify.categories.STATUS)
  end
end

-- Monitor progress file for changes
function M.monitor_progress_file(account, callback)
  account = account or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  local last_mtime = 0
  
  local timer = vim.fn.timer_start(1000, function()
    -- Get file modification time
    local stat = vim.loop.fs_stat(progress_file)
    if not stat then
      return
    end
    
    if stat.mtime.sec > last_mtime then
      last_mtime = stat.mtime.sec
      
      -- File changed, read new data
      local data, err = M.read_validated_progress(account)
      if data then
        callback(data)
      end
    end
  end, { ['repeat'] = -1 })
  
  return timer
end

-- Debug progress file
function M.debug_progress_file(account)
  account = account or 'gmail'
  
  notify.himalaya('=== Progress File Debug ===', notify.categories.USER_ACTION)
  
  local data, err = M.read_validated_progress(account)
  if not data then
    notify.himalaya('Error: ' .. err, notify.categories.ERROR)
    return
  end
  
  notify.himalaya('Progress file valid!', notify.categories.STATUS)
  notify.himalaya('PID: ' .. data.pid, notify.categories.STATUS)
  notify.himalaya('Age: ' .. (os.time() - data.last_update) .. ' seconds', notify.categories.STATUS)
  
  if data.progress then
    local p = data.progress
    if p.current_message and p.total_messages then
      notify.himalaya(string.format('Messages: %d/%d', p.current_message, p.total_messages), notify.categories.STATUS)
    end
    if p.current_operation then
      notify.himalaya('Operation: ' .. p.current_operation, notify.categories.STATUS)
    end
  end
end

-- Setup commands
vim.api.nvim_create_user_command('HimalayaDebugProgress', function()
  M.debug_progress_file()
end, { desc = 'Debug Himalaya progress file' })

vim.api.nvim_create_user_command('HimalayaCleanupProgress', function()
  M.cleanup_stale_progress_files()
end, { desc = 'Clean up stale progress files' })

return M