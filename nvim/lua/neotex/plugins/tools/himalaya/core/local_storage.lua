-- Local Storage Module
-- Handles all local persistence for drafts with robust error handling

local M = {}

-- Dependencies
local notify = require('neotex.util.notifications')

-- Configuration
M.config = {
  base_dir = vim.fn.stdpath('data') .. '/himalaya/drafts/',
  index_file = vim.fn.stdpath('data') .. '/himalaya/drafts/.index.json'
}

-- Initialize storage
function M.setup()
  -- Ensure directories exist
  vim.fn.mkdir(M.config.base_dir, 'p')
  
  -- Initialize index if not already done
  if M.index == nil then
    M.index = {}
  end
  
  -- Load or create index
  M._load_index()
end

-- Storage index for quick lookups (initialized in setup)
M.index = nil

-- Save draft data
-- @param local_id string Unique local identifier
-- @param data table Draft data to save
-- @return boolean success
-- @return string|nil error
function M.save(local_id, data)
  if not local_id or not data then
    return false, "Invalid parameters"
  end
  
  -- Prepare file path
  local file_path = M.config.base_dir .. local_id .. '.json'
  
  -- Serialize data
  local ok, json = pcall(vim.fn.json_encode, data)
  if not ok then
    return false, "Failed to serialize data: " .. json
  end
  
  -- Write to file
  local write_ok = pcall(vim.fn.writefile, {json}, file_path)
  if not write_ok then
    return false, "Failed to write file"
  end
  
  -- Update index
  M.index[local_id] = {
    remote_id = data.remote_id,
    account = data.account,
    subject = data.metadata and data.metadata.subject or '',
    modified = os.time(),
    created_at = data.created_at,
    updated_at = data.updated_at or os.time()
  }
  M._save_index()
  
  -- Debug notification
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      "[Storage] Saved draft locally",
      notify.categories.BACKGROUND,
      {
        local_id = local_id,
        size = #json,
        path = file_path
      }
    )
  end
  
  return true
end

-- Load draft data
-- @param local_id string Unique local identifier
-- @return table|nil Draft data
function M.load(local_id)
  if not local_id then
    return nil
  end
  
  local file_path = M.config.base_dir .. local_id .. '.json'
  
  -- Check if file exists
  if vim.fn.filereadable(file_path) == 0 then
    return nil
  end
  
  -- Read file
  local ok, content = pcall(vim.fn.readfile, file_path)
  if not ok or #content == 0 then
    return nil
  end
  
  -- Parse JSON
  local parse_ok, data = pcall(vim.fn.json_decode, table.concat(content))
  if not parse_ok then
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya(
        "[Storage] Failed to parse draft file",
        notify.categories.ERROR,
        { local_id = local_id, error = data }
      )
    end
    return nil
  end
  
  return data
end

-- Delete draft data
-- @param local_id string Unique local identifier
-- @return boolean success
function M.delete(local_id)
  if not local_id then
    return false
  end
  
  local json_path = M.config.base_dir .. local_id .. '.json'
  local eml_path = M.config.base_dir .. local_id .. '.eml'
  
  -- Delete both JSON and EML files
  local json_ok = pcall(vim.fn.delete, json_path)
  local eml_ok = pcall(vim.fn.delete, eml_path)
  
  -- Remove from index
  M.index[local_id] = nil
  M._save_index()
  
  -- Debug notification
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      "[Storage] Deleted draft files",
      notify.categories.BACKGROUND,
      { 
        local_id = local_id, 
        json_deleted = json_ok,
        eml_deleted = eml_ok
      }
    )
  end
  
  return json_ok or eml_ok
end

-- List all stored drafts
-- @return table List of draft info
function M.list()
  local drafts = {}
  
  -- Ensure index is loaded
  if M.index == nil then
    M.setup()
  end
  
  for local_id, info in pairs(M.index) do
    table.insert(drafts, vim.tbl_extend('force', info, { local_id = local_id }))
  end
  
  -- Sort by modified time (newest first)
  table.sort(drafts, function(a, b)
    return (a.modified or 0) > (b.modified or 0)
  end)
  
  return drafts
end

-- Find draft by remote ID
-- @param remote_id string Remote draft ID
-- @param account string Account name
-- @return table|nil Draft data
function M.find_by_remote_id(remote_id, account)
  -- Search index first
  for local_id, info in pairs(M.index) do
    if info.remote_id == tostring(remote_id) and info.account == account then
      return M.load(local_id)
    end
  end
  
  return nil
end

-- Clean up orphaned files
-- @return number Number of files cleaned
function M.cleanup_orphaned()
  local count = 0
  
  -- Get all files in directory
  local files = vim.fn.glob(M.config.base_dir .. '*.json', false, true)
  
  for _, file in ipairs(files) do
    local filename = vim.fn.fnamemodify(file, ':t:r')
    
    -- Skip index file
    if filename ~= '.index' and not M.index[filename] then
      -- Orphaned file, delete it
      local ok = pcall(vim.fn.delete, file)
      if ok then
        count = count + 1
      end
    end
  end
  
  if count > 0 and notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      "[Storage] Cleaned up orphaned files",
      notify.categories.BACKGROUND,
      { count = count }
    )
  end
  
  return count
end

-- Get storage statistics
-- @return table Statistics
function M.get_stats()
  local stats = {
    total_drafts = vim.tbl_count(M.index),
    total_size = 0,
    by_account = {}
  }
  
  -- Calculate sizes and group by account
  for local_id, info in pairs(M.index) do
    local file_path = M.config.base_dir .. local_id .. '.json'
    local size = vim.fn.getfsize(file_path)
    if size > 0 then
      stats.total_size = stats.total_size + size
    end
    
    -- Group by account
    local account = info.account or 'unknown'
    stats.by_account[account] = (stats.by_account[account] or 0) + 1
  end
  
  return stats
end

-- Load index from disk
function M._load_index()
  if vim.fn.filereadable(M.config.index_file) == 0 then
    M.index = {}
    return
  end
  
  local ok, content = pcall(vim.fn.readfile, M.config.index_file)
  if not ok or #content == 0 then
    M.index = {}
    return
  end
  
  local parse_ok, data = pcall(vim.fn.json_decode, table.concat(content))
  if parse_ok and type(data) == 'table' then
    M.index = data
  else
    M.index = {}
  end
end

-- Save index to disk
function M._save_index()
  local ok, json = pcall(vim.fn.json_encode, M.index)
  if ok then
    pcall(vim.fn.writefile, {json}, M.config.index_file)
  end
end

-- Clear all storage (for testing)
function M._clear_all()
  -- Delete all files
  local files = vim.fn.glob(M.config.base_dir .. '*.json', false, true)
  for _, file in ipairs(files) do
    pcall(vim.fn.delete, file)
  end
  
  -- Clear index
  M.index = {}
  M._save_index()
end

return M