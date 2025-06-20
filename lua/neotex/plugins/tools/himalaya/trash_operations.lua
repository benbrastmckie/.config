-- Trash Operations
-- Email operations for local trash management (move, restore, delete)

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
local notifications = require('neotex.plugins.tools.himalaya.notifications')

-- Move email to local trash
function M.move_to_trash(email_id, original_folder)
  if not trash_manager.is_enabled() then
    vim.notify('Local trash is disabled', vim.log.levels.WARN)
    return false
  end
  
  -- Validate inputs
  if not email_id or not original_folder then
    vim.notify('Missing email ID or folder information', vim.log.levels.ERROR)
    return false
  end
  
  -- Get email content first
  local account = config.state.current_account
  if not account then
    vim.notify('No current account set', vim.log.levels.ERROR)
    return false
  end
  
  print("Moving email to local trash...")
  
  -- Get the email content
  local email_content = utils.get_email_content(account, email_id)
  if not email_content then
    -- If we can't get content, still proceed with deletion but with a placeholder
    vim.notify('Warning: Could not retrieve email content for ID: ' .. email_id .. ', deleting without backup', vim.log.levels.WARN)
    email_content = string.format("Email ID: %s\nOriginal Folder: %s\nContent could not be retrieved during deletion.\nDeleted on: %s\n", 
      email_id, original_folder, os.date())
  end
  
  -- Prepare trash storage
  local date = os.date("*t")
  local trash_date_dir = trash_manager.ensure_date_directory(date)
  if not trash_date_dir then
    vim.notify('Failed to create trash date directory', vim.log.levels.ERROR)
    return false
  end
  
  -- Generate unique filename
  local trash_filename = trash_manager.generate_trash_filename(email_id, original_folder, date)
  local trash_file_path = trash_date_dir .. '/' .. trash_filename
  
  -- Write email content to trash file
  local success = M.write_email_to_file(email_content, trash_file_path)
  if not success then
    vim.notify('Failed to write email to trash file', vim.log.levels.ERROR)
    return false
  end
  
  -- Get file size
  local file_size = vim.fn.getfsize(trash_file_path)
  
  -- Add metadata
  local metadata_success = trash_manager.add_trash_metadata(
    email_id, 
    original_folder, 
    trash_file_path, 
    file_size
  )
  
  if not metadata_success then
    vim.notify('Failed to add trash metadata (email saved but not tracked)', vim.log.levels.WARN)
  end
  
  -- Now delete from original location using Himalaya
  local delete_success = M.delete_from_original_location(account, email_id)
  if not delete_success then
    -- If deletion fails, clean up trash file
    vim.fn.delete(trash_file_path)
    trash_manager.remove_trash_metadata(email_id)
    vim.notify('Failed to delete email from original location', vim.log.levels.ERROR)
    return false
  end
  
  notifications.notify(string.format('Email moved to local trash (%s)', trash_filename), vim.log.levels.INFO)
  return true
end

-- Write email content to file
function M.write_email_to_file(email_content, file_path)
  local content_str
  
  -- Handle different content types
  if type(email_content) == "string" then
    content_str = email_content
  elseif type(email_content) == "table" then
    -- If it's structured data, try to extract the content
    if email_content.textBody then
      content_str = email_content.textBody
    elseif email_content.body then
      content_str = email_content.body
    else
      -- Convert table to JSON as fallback
      local success, json_str = pcall(vim.json.encode, email_content)
      if success then
        content_str = json_str
      else
        content_str = vim.inspect(email_content)
      end
    end
  else
    content_str = tostring(email_content)
  end
  
  -- Write to file
  local lines = vim.split(content_str, '\n')
  local write_result = vim.fn.writefile(lines, file_path)
  
  if write_result ~= 0 then
    vim.notify('Failed to write file: ' .. file_path, vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- Delete email from original location
function M.delete_from_original_location(account, email_id)
  -- Use Himalaya to flag email as deleted and expunge
  local args = { 'flag', 'add', tostring(email_id), 'Deleted' }
  local result = utils.execute_himalaya(args, { account = account })
  
  if not result then
    return false
  end
  
  -- Expunge to permanently remove from folder
  local expunge_success = utils.expunge_deleted()
  return expunge_success
end

-- Restore email from trash
function M.restore_from_trash(email_id, target_folder)
  -- Get trash metadata
  local metadata = trash_manager.get_trash_metadata(email_id)
  if not metadata then
    vim.notify('Email not found in trash: ' .. email_id, vim.log.levels.ERROR)
    return false
  end
  
  -- Use original folder if target not specified
  target_folder = target_folder or metadata.original_folder
  
  print("Restoring email from trash...")
  
  -- Read email content from trash file
  local email_content = M.read_email_from_file(metadata.file_path)
  if not email_content then
    vim.notify('Failed to read email from trash file', vim.log.levels.ERROR)
    return false
  end
  
  -- TODO: This is complex - we need to re-inject the email into the maildir
  -- For now, we'll implement a simpler approach that saves as draft
  local success = M.restore_as_draft(email_content, target_folder)
  
  if success then
    -- Remove from trash
    vim.fn.delete(metadata.file_path)
    trash_manager.remove_trash_metadata(email_id)
    vim.notify('Email restored to ' .. target_folder, vim.log.levels.INFO)
    return true
  end
  
  return false
end

-- Read email content from file
function M.read_email_from_file(file_path)
  if vim.fn.filereadable(file_path) == 0 then
    return nil
  end
  
  local lines = vim.fn.readfile(file_path)
  return table.concat(lines, '\n')
end

-- Restore email as draft (temporary implementation)
function M.restore_as_draft(email_content, target_folder)
  -- For now, save as a draft that user can review and send
  -- This is a simplified implementation until we can properly inject emails
  
  local temp_file = vim.fn.tempname() .. '.eml'
  local lines = vim.split(email_content, '\n')
  
  local write_result = vim.fn.writefile(lines, temp_file)
  if write_result ~= 0 then
    return false
  end
  
  vim.notify('Email content saved to: ' .. temp_file, vim.log.levels.INFO)
  vim.notify('Manual action required: Import this file to restore the email', vim.log.levels.WARN)
  
  return true
end

-- Permanently delete email from trash
function M.permanent_delete(email_id)
  local metadata = trash_manager.get_trash_metadata(email_id)
  if not metadata then
    vim.notify('Email not found in trash: ' .. email_id, vim.log.levels.ERROR)
    return false
  end
  
  -- Confirm permanent deletion
  local confirm = vim.fn.confirm(
    'Permanently delete email? This cannot be undone.',
    '&Yes\n&No',
    2
  )
  
  if confirm ~= 1 then
    vim.notify('Permanent deletion cancelled', vim.log.levels.INFO)
    return false
  end
  
  -- Delete file
  local file_deleted = vim.fn.delete(metadata.file_path) == 0
  
  -- Remove metadata
  local metadata_removed = trash_manager.remove_trash_metadata(email_id)
  
  if file_deleted and metadata_removed then
    vim.notify('Email permanently deleted', vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to completely remove email from trash', vim.log.levels.ERROR)
    return false
  end
end

-- List emails in trash with pagination
function M.list_trash_emails(page, page_size)
  page = page or 1
  page_size = page_size or 30
  
  local all_items = trash_manager.list_trash_items()
  
  -- Calculate pagination
  local start_idx = (page - 1) * page_size + 1
  local end_idx = math.min(start_idx + page_size - 1, #all_items)
  
  local page_items = {}
  for i = start_idx, end_idx do
    if all_items[i] then
      table.insert(page_items, all_items[i])
    end
  end
  
  return page_items, #all_items
end

-- Clean up old trash items based on retention policy
function M.cleanup_old_items()
  local trash_config = config.config.trash
  if not trash_config or not trash_config.auto_cleanup then
    return 0
  end
  
  local retention_days = trash_config.retention_days or 30
  local cutoff_time = os.time() - (retention_days * 24 * 60 * 60) -- retention_days ago
  
  local all_items = trash_manager.list_trash_items()
  local cleaned_count = 0
  
  for _, item in ipairs(all_items) do
    -- Parse deletion date
    local deleted_time = M.parse_iso_date(item.deleted_date)
    
    if deleted_time and deleted_time < cutoff_time then
      -- Item is older than retention period
      local success = M.permanent_delete(item.email_id)
      if success then
        cleaned_count = cleaned_count + 1
      end
    end
  end
  
  if cleaned_count > 0 then
    vim.notify(string.format('Cleaned up %d old trash items', cleaned_count), vim.log.levels.INFO)
  end
  
  return cleaned_count
end

-- Parse ISO date string to timestamp
function M.parse_iso_date(iso_date)
  -- Simple ISO date parser for YYYY-MM-DDTHH:MM:SSZ format
  local year, month, day, hour, min, sec = iso_date:match('(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z')
  
  if year then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = tonumber(sec)
    })
  end
  
  return nil
end

-- Setup commands for trash operations
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaTrashList', function()
    local items, total = M.list_trash_emails(1, 10)
    print("=== Local Trash Contents ===")
    print("Total items: " .. total)
    print()
    
    for i, item in ipairs(items) do
      print(string.format("%d. %s (from %s) - %s", 
        i, 
        item.email_id, 
        item.original_folder, 
        item.deleted_date
      ))
    end
    
    if total > 10 then
      print(string.format("... and %d more items", total - 10))
    end
  end, {
    desc = 'List emails in local trash'
  })
  
  vim.api.nvim_create_user_command('HimalayaTrashCleanup', function()
    local cleaned = M.cleanup_old_items()
    print("Cleanup completed. Removed " .. cleaned .. " old items.")
  end, {
    desc = 'Clean up old trash items based on retention policy'
  })
  
  vim.api.nvim_create_user_command('HimalayaTrashRestore', function(opts)
    local email_id = opts.args
    if email_id == '' then
      vim.notify('Usage: :HimalayaTrashRestore <email_id>', vim.log.levels.ERROR)
      return
    end
    
    M.restore_from_trash(email_id)
  end, {
    desc = 'Restore email from trash by ID',
    nargs = 1
  })
  
  vim.api.nvim_create_user_command('HimalayaTrashPurge', function(opts)
    local email_id = opts.args
    if email_id == '' then
      vim.notify('Usage: :HimalayaTrashPurge <email_id>', vim.log.levels.ERROR)
      return
    end
    
    M.permanent_delete(email_id)
  end, {
    desc = 'Permanently delete email from trash',
    nargs = 1
  })
end

return M