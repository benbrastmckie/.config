-- Fix for delete operation issues
-- Handles: missing trash folder, cancelled operations, refresh problems

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
local notifications = require('neotex.plugins.tools.himalaya.notifications')
local performance = require('neotex.plugins.tools.himalaya.performance')

-- Store email data before removal for restoration
M.pending_delete = nil

-- Fixed delete operation that only removes locally after confirming operation
function M.delete_email_fixed(email_id)
  if not email_id then
    notifications.notify('No email to delete', vim.log.levels.WARN)
    return
  end
  
  -- Check if we're in sidebar or email view
  local current_filetype = vim.bo.filetype
  local is_in_sidebar = current_filetype == 'himalaya-list'
  
  -- First, get email data for potential restoration
  local email_data = nil
  if is_in_sidebar then
    email_data = M.get_email_data_for_restoration(email_id)
  end
  
  -- Try to delete on server FIRST
  local success, error_type, extra = utils.smart_delete_email(config.state.current_account, email_id)
  
  if success then
    -- Server delete succeeded, now remove locally
    if is_in_sidebar then
      performance.remove_email_locally(email_id)
      notifications.notify_status('Email deleted', vim.log.levels.INFO)
    else
      -- Close email view if not in sidebar
      local ui = require('neotex.plugins.tools.himalaya.ui')
      ui.close_current_view()
    end
    
    -- Schedule background refresh for sync
    performance.schedule_refresh(2000)
  else
    -- Handle different failure types
    if error_type == 'missing_trash' then
      -- No trash folder found, show picker
      M.handle_missing_trash_with_restore(email_id, email_data, is_in_sidebar)
    elseif error_type == 'delete_failed' then
      -- Regular delete failure
      local error_msg = type(extra) == 'string' and extra or 'Delete command failed'
      notifications.notify('Failed to delete email: ' .. error_msg, vim.log.levels.ERROR)
    end
  end
end

-- Handle missing trash folder with proper restoration on cancel
function M.handle_missing_trash_with_restore(email_id, email_data, is_in_sidebar)
  local folders = utils.get_folders(config.state.current_account)
  
  if not folders or #folders == 0 then
    notifications.notify('No folders available', vim.log.levels.ERROR)
    return
  end
  
  -- Store pending delete info in case of cancel
  M.pending_delete = {
    email_id = email_id,
    email_data = email_data,
    was_removed = false
  }
  
  -- Show folder picker
  vim.ui.select(folders, {
    prompt = 'No trash folder found. Select folder to move email to:',
  }, function(choice)
    if choice then
      -- User selected a folder, try to move
      local move_success = utils.move_email(email_id, choice)
      
      if move_success then
        notifications.notify('Email moved to ' .. choice, vim.log.levels.INFO)
        
        -- Now remove locally since move succeeded
        if is_in_sidebar and not M.pending_delete.was_removed then
          performance.remove_email_locally(email_id)
          M.pending_delete.was_removed = true
        end
        
        performance.schedule_refresh(1000)
      else
        notifications.notify('Failed to move email to ' .. choice, vim.log.levels.ERROR)
      end
    else
      -- User cancelled - no need to do anything since we didn't remove locally yet
      notifications.notify('Delete operation cancelled', vim.log.levels.INFO)
    end
    
    -- Clear pending delete
    M.pending_delete = nil
  end)
end

-- Get email data for potential restoration
function M.get_email_data_for_restoration(email_id)
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  
  local emails = vim.b[buf].himalaya_emails
  if not emails then
    return nil
  end
  
  for i, email in ipairs(emails) do
    if email.id == email_id then
      return {
        index = i,
        email = vim.deepcopy(email)
      }
    end
  end
  
  return nil
end

-- Fixed refresh that bypasses debouncing
function M.force_immediate_refresh()
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  -- Call the original refresh function directly, bypassing optimization
  if ui.refresh_email_list_original then
    ui.refresh_email_list_original()
  else
    -- Fallback to current refresh
    local buf = ui.buffers.email_list
    if buf and vim.api.nvim_buf_is_valid(buf) then
      local account = vim.b[buf].himalaya_account
      local folder = vim.b[buf].himalaya_folder
      if account and folder then
        -- Clear cache to force refresh
        utils.clear_email_cache(account, folder)
        ui.show_email_list({folder, '--account=' .. account})
      end
    end
  end
end

-- Apply the fixes
function M.apply_fixes()
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local performance = require('neotex.plugins.tools.himalaya.performance')
  
  -- Replace the optimized delete with our fixed version
  ui.delete_current_email = function()
    local email_id = ui.get_current_email_id()
    if email_id then
      M.delete_email_fixed(email_id)
    else
      notifications.notify('No email to delete', vim.log.levels.WARN)
    end
  end
  
  -- Fix the 'r' refresh to bypass debouncing
  local config = require('neotex.plugins.tools.himalaya.config')
  local original_setup = config.setup_buffer_keymaps
  
  config.setup_buffer_keymaps = function(bufnr)
    -- Call original setup first
    original_setup(bufnr)
    
    -- Override 'r' to force immediate refresh
    if vim.bo[bufnr].filetype == 'himalaya-list' then
      vim.keymap.set('n', 'r', function()
        M.force_immediate_refresh()
      end, { 
        buffer = bufnr, 
        silent = true,
        desc = 'Refresh email list (immediate)'
      })
    end
  end
  
  notifications.notify_force('Delete operation fixes applied', vim.log.levels.INFO)
end

-- Create commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaFixDelete', M.apply_fixes, {
    desc = 'Apply delete operation fixes'
  })
  
  vim.api.nvim_create_user_command('HimalayaForceRefresh', M.force_immediate_refresh, {
    desc = 'Force immediate email list refresh'
  })
end

return M