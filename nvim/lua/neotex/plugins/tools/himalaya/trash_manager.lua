-- Local Trash Directory Management
-- Core infrastructure for local email trash with metadata tracking

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')

-- Default trash configuration
M.default_config = {
  enabled = true,
  directory = "~/Mail/Gmail/.trash",
  retention_days = 30,
  max_size_mb = 1000,
  organization = "daily", -- "daily", "monthly", "flat"
  metadata_storage = "json", -- "sqlite", "json" 
  auto_cleanup = true,
  cleanup_interval_hours = 24
}

-- Initialize trash system
function M.init()
  local trash_config = config.config.trash or M.default_config
  
  -- Expand path
  local trash_dir = vim.fn.expand(trash_config.directory)
  
  -- Create directory structure
  local success = M.create_directory_structure(trash_dir)
  if not success then
    vim.notify('Failed to create trash directory structure', vim.log.levels.ERROR)
    return false
  end
  
  -- Initialize metadata storage
  local metadata_success = M.init_metadata_storage(trash_dir, trash_config.metadata_storage)
  if not metadata_success then
    vim.notify('Failed to initialize trash metadata storage', vim.log.levels.WARN)
  end
  
  vim.notify('Local trash system initialized at: ' .. trash_dir, vim.log.levels.INFO)
  return true
end

-- Create trash directory structure
function M.create_directory_structure(trash_dir)
  local dirs_to_create = {
    trash_dir,
    trash_dir .. '/restore_info',
    trash_dir .. '/2024' -- Current year, will be dynamic
  }
  
  for _, dir in ipairs(dirs_to_create) do
    local success = vim.fn.mkdir(dir, 'p')
    if success == 0 then
      vim.notify('Failed to create directory: ' .. dir, vim.log.levels.ERROR)
      return false
    end
  end
  
  return true
end

-- Initialize metadata storage system
function M.init_metadata_storage(trash_dir, storage_type)
  if storage_type == "json" then
    -- Create metadata index file
    local metadata_file = trash_dir .. '/metadata.json'
    if vim.fn.filereadable(metadata_file) == 0 then
      local initial_data = {
        version = "1.0",
        created = os.date("%Y-%m-%dT%H:%M:%SZ"),
        items = {}
      }
      return M.write_json_metadata(metadata_file, initial_data)
    end
    return true
  elseif storage_type == "sqlite" then
    -- TODO: Implement SQLite support
    vim.notify('SQLite metadata storage not yet implemented, using JSON', vim.log.levels.WARN)
    return M.init_metadata_storage(trash_dir, "json")
  end
  
  return false
end

-- Get trash directory path
function M.get_trash_directory()
  local trash_config = config.config.trash or M.default_config
  return vim.fn.expand(trash_config.directory)
end

-- Get date-based subdirectory path
function M.get_date_path(date)
  date = date or os.date("*t")
  local trash_config = config.config.trash or M.default_config
  
  if trash_config.organization == "daily" then
    return string.format("%04d/%02d/%02d", date.year, date.month, date.day)
  elseif trash_config.organization == "monthly" then
    return string.format("%04d/%02d", date.year, date.month)
  else -- flat
    return ""
  end
end

-- Create date subdirectory if needed
function M.ensure_date_directory(date)
  local trash_dir = M.get_trash_directory()
  local date_path = M.get_date_path(date)
  
  if date_path ~= "" then
    local full_path = trash_dir .. '/' .. date_path
    local success = vim.fn.mkdir(full_path, 'p')
    if success == 0 then
      vim.notify('Failed to create date directory: ' .. full_path, vim.log.levels.ERROR)
      return nil
    end
    return full_path
  end
  
  return trash_dir
end

-- Generate unique trash filename
function M.generate_trash_filename(email_id, original_folder, date)
  date = date or os.date("*t")
  local timestamp = os.time(date)
  local folder_safe = original_folder:gsub("[^%w]", "_") -- sanitize folder name
  return string.format("%s_%s_%d.eml", email_id, folder_safe, timestamp)
end

-- Read JSON metadata
function M.read_json_metadata(metadata_file)
  if vim.fn.filereadable(metadata_file) == 0 then
    return nil
  end
  
  local content = vim.fn.readfile(metadata_file)
  if not content or #content == 0 then
    return nil
  end
  
  local success, data = pcall(vim.json.decode, table.concat(content, '\n'))
  if not success then
    vim.notify('Failed to parse metadata JSON: ' .. data, vim.log.levels.ERROR)
    return nil
  end
  
  return data
end

-- Write JSON metadata
function M.write_json_metadata(metadata_file, data)
  local success, json_str = pcall(vim.json.encode, data)
  if not success then
    vim.notify('Failed to encode metadata JSON: ' .. json_str, vim.log.levels.ERROR)
    return false
  end
  
  local write_success = vim.fn.writefile({json_str}, metadata_file)
  if write_success ~= 0 then
    vim.notify('Failed to write metadata file: ' .. metadata_file, vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- Add email to trash metadata
function M.add_trash_metadata(email_id, original_folder, trash_file_path, size_bytes)
  local trash_dir = M.get_trash_directory()
  local metadata_file = trash_dir .. '/metadata.json'
  
  local metadata = M.read_json_metadata(metadata_file)
  if not metadata then
    metadata = {
      version = "1.0",
      created = os.date("%Y-%m-%dT%H:%M:%SZ"),
      items = {}
    }
  end
  
  local trash_item = {
    email_id = email_id,
    original_folder = original_folder,
    deleted_date = os.date("%Y-%m-%dT%H:%M:%SZ"),
    deleted_by = "user",
    file_path = trash_file_path,
    size_bytes = size_bytes or 0,
    restore_info = {
      original_folder = original_folder,
      can_restore = true
    }
  }
  
  -- Add to items (use email_id as key for easy lookup)
  metadata.items[email_id] = trash_item
  
  return M.write_json_metadata(metadata_file, metadata)
end

-- Get trash metadata for email
function M.get_trash_metadata(email_id)
  local trash_dir = M.get_trash_directory()
  local metadata_file = trash_dir .. '/metadata.json'
  
  local metadata = M.read_json_metadata(metadata_file)
  if not metadata or not metadata.items then
    return nil
  end
  
  return metadata.items[email_id]
end

-- Remove email from trash metadata
function M.remove_trash_metadata(email_id)
  local trash_dir = M.get_trash_directory()
  local metadata_file = trash_dir .. '/metadata.json'
  
  local metadata = M.read_json_metadata(metadata_file)
  if not metadata or not metadata.items then
    return true -- Nothing to remove
  end
  
  metadata.items[email_id] = nil
  return M.write_json_metadata(metadata_file, metadata)
end

-- List all trash items
function M.list_trash_items()
  local trash_dir = M.get_trash_directory()
  local metadata_file = trash_dir .. '/metadata.json'
  
  local metadata = M.read_json_metadata(metadata_file)
  if not metadata or not metadata.items then
    return {}
  end
  
  local items = {}
  for email_id, item in pairs(metadata.items) do
    table.insert(items, item)
  end
  
  -- Sort by deletion date (newest first)
  table.sort(items, function(a, b)
    return a.deleted_date > b.deleted_date
  end)
  
  return items
end

-- Get trash statistics
function M.get_trash_stats()
  local trash_dir = M.get_trash_directory()
  local items = M.list_trash_items()
  
  local stats = {
    total_items = #items,
    total_size_bytes = 0,
    oldest_item = nil,
    newest_item = nil,
    directory = trash_dir
  }
  
  for _, item in ipairs(items) do
    stats.total_size_bytes = stats.total_size_bytes + (item.size_bytes or 0)
    
    if not stats.oldest_item or item.deleted_date < stats.oldest_item then
      stats.oldest_item = item.deleted_date
    end
    
    if not stats.newest_item or item.deleted_date > stats.newest_item then
      stats.newest_item = item.deleted_date
    end
  end
  
  -- Convert bytes to MB
  stats.total_size_mb = math.floor(stats.total_size_bytes / 1024 / 1024 * 100) / 100
  
  return stats
end

-- Check if trash system is enabled
function M.is_enabled()
  local trash_config = config.config.trash or M.default_config
  return trash_config.enabled
end

-- Validate trash configuration
function M.validate_config()
  local trash_config = config.config.trash or M.default_config
  local issues = {}
  
  -- Check directory accessibility
  local trash_dir = vim.fn.expand(trash_config.directory)
  if vim.fn.isdirectory(trash_dir) == 0 then
    table.insert(issues, "Trash directory does not exist: " .. trash_dir)
  end
  
  -- Check retention days
  if trash_config.retention_days < 1 then
    table.insert(issues, "Retention days must be at least 1")
  end
  
  -- Check max size
  if trash_config.max_size_mb < 1 then
    table.insert(issues, "Max size must be at least 1 MB")
  end
  
  return #issues == 0, issues
end

-- Setup commands for trash management
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaTrashInit', M.init, {
    desc = 'Initialize local trash system'
  })
  
  vim.api.nvim_create_user_command('HimalayaTrashStats', function()
    local stats = M.get_trash_stats()
    print("=== Himalaya Trash Statistics ===")
    print("Directory: " .. stats.directory)
    print("Total items: " .. stats.total_items)
    print("Total size: " .. stats.total_size_mb .. " MB")
    if stats.oldest_item then
      print("Oldest item: " .. stats.oldest_item)
    end
    if stats.newest_item then
      print("Newest item: " .. stats.newest_item)
    end
  end, {
    desc = 'Show trash statistics'
  })
  
  vim.api.nvim_create_user_command('HimalayaTrashValidate', function()
    local valid, issues = M.validate_config()
    if valid then
      print("✅ Trash configuration is valid")
    else
      print("❌ Trash configuration issues:")
      for _, issue in ipairs(issues) do
        print("  • " .. issue)
      end
    end
  end, {
    desc = 'Validate trash configuration'
  })
end

return M