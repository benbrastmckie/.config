-- Himalaya Performance Optimizations
-- Improve email client responsiveness and user experience

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
local notifications = require('neotex.plugins.tools.himalaya.notifications')

-- Debounce refresh operations
M.refresh_timer = nil
M.pending_refreshes = {}

-- Local email state for instant updates
M.local_email_state = {
  deleted_emails = {},
  moved_emails = {},
  flagged_emails = {}
}

-- Fast local email removal without full refresh
function M.remove_email_locally(email_id)
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  local emails = vim.b[buf].himalaya_emails
  if not emails then
    return false
  end
  
  -- Find and remove email from local state
  local removed_index = nil
  local removed_email = nil
  for i, email in ipairs(emails) do
    if email.id == email_id then
      removed_index = i
      removed_email = vim.deepcopy(email) -- Store for potential restoration
      break
    end
  end
  
  if not removed_index then
    return false
  end
  
  -- Store removed email for potential restoration
  M.local_email_state.deleted_emails[email_id] = {
    index = removed_index,
    email = removed_email
  }
  
  -- Remove from local email list
  table.remove(emails, removed_index)
  vim.api.nvim_buf_set_var(buf, 'himalaya_emails', emails)
  
  -- Update the display immediately
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local lines = ui.format_email_list(emails)
  sidebar.update_content(lines)
  
  -- Adjust cursor position if needed
  local current_line = vim.fn.line('.')
  local email_start_line = 5 -- Headers take 4 lines, emails start at line 5
  
  if current_line >= email_start_line + removed_index then
    -- Move cursor up if we're below the deleted email
    local new_line = math.max(email_start_line, current_line - 1)
    vim.api.nvim_win_set_cursor(sidebar.get_win(), {new_line, 0})
  end
  
  return true
end

-- Add email back locally (for undo/restore operations)
function M.add_email_locally(email_data)
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  local emails = vim.b[buf].himalaya_emails
  if not emails then
    return false
  end
  
  -- Determine insertion position
  local insert_pos = email_data.index or email_data.position or #emails + 1
  
  -- Insert email at position
  if type(email_data.email) == 'table' then
    table.insert(emails, insert_pos, email_data.email)
  else
    -- email_data might be the email itself
    table.insert(emails, insert_pos, email_data)
  end
  
  vim.api.nvim_buf_set_var(buf, 'himalaya_emails', emails)
  
  -- Update display
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local lines = ui.format_email_list(emails)
  sidebar.update_content(lines)
  
  -- Position cursor on restored email
  local email_line = insert_pos + 4 -- Account for header lines
  local win = sidebar.get_win()
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_set_cursor, win, {email_line, 0})
  end
  
  return true
end

-- Update email status locally (for flags, read status, etc.)
function M.update_email_locally(email_id, updates)
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  local emails = vim.b[buf].himalaya_emails
  if not emails then
    return false
  end
  
  -- Find and update email
  local updated = false
  for i, email in ipairs(emails) do
    if email.id == email_id then
      for key, value in pairs(updates) do
        email[key] = value
      end
      updated = true
      break
    end
  end
  
  if updated then
    vim.api.nvim_buf_set_var(buf, 'himalaya_emails', emails)
    
    -- Update display
    local ui = require('neotex.plugins.tools.himalaya.ui')
    local lines = ui.format_email_list(emails)
    sidebar.update_content(lines)
    
    return true
  end
  
  return false
end

-- Debounced refresh that batches multiple refresh requests
function M.schedule_refresh(delay)
  delay = delay or 1000 -- 1 second default delay
  
  -- Cancel existing timer
  if M.refresh_timer then
    M.refresh_timer:stop()
    M.refresh_timer:close()
  end
  
  -- Schedule new refresh
  M.refresh_timer = vim.loop.new_timer()
  M.refresh_timer:start(delay, 0, vim.schedule_wrap(function()
    M.perform_refresh()
    M.refresh_timer:close()
    M.refresh_timer = nil
  end))
end

-- Perform the actual refresh
function M.perform_refresh()
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  -- Only refresh if sidebar is still open and visible
  if sidebar.is_open() then
    ui.refresh_email_list()
  end
  
  -- Clear local state after refresh
  M.local_email_state.deleted_emails = {}
  M.local_email_state.moved_emails = {}
  M.local_email_state.flagged_emails = {}
end

-- Optimized delete operation
function M.delete_email_optimized(email_id)
  if not email_id then
    vim.notify('No email to delete', vim.log.levels.WARN)
    return
  end
  
  -- Check if we're in sidebar or email view
  local current_filetype = vim.bo.filetype
  local is_in_sidebar = current_filetype == 'himalaya-list'
  
  -- Only do local update if we're in sidebar (don't close email view)
  local local_success = false
  if is_in_sidebar then
    local_success = M.remove_email_locally(email_id)
    if local_success then
      notifications.notify_status('Email deleted', vim.log.levels.INFO)
    end
  end
  
  -- Perform actual delete in background
  vim.defer_fn(function()
    local success, error_type, extra = utils.smart_delete_email(config.state.current_account, email_id)
    
    if not success then
      if error_type == 'missing_trash' then
        -- Revert local changes first
        if local_success then
          M.schedule_refresh(100) -- Restore email to list
        end
        
        -- Show trash folder picker (this should NOT trigger permanent delete in headless mode)
        local ui = require('neotex.plugins.tools.himalaya.ui')
        
        -- Override headless detection to always show picker when in interactive mode
        if vim.fn.has('gui_running') == 1 or vim.env.DISPLAY or vim.env.TERM then
          -- We're in interactive mode, show picker
          local folders = utils.get_folders(config.state.current_account)
          if folders and #folders > 0 then
            -- Show folder picker for manual selection
            vim.ui.select(folders, {
              prompt = 'No trash folder found. Select folder to move email to:',
            }, function(choice)
              if choice then
                local move_success = utils.move_email(email_id, choice)
                if move_success then
                  vim.notify('Email moved to ' .. choice, vim.log.levels.INFO)
                  if is_in_sidebar then
                    M.remove_email_locally(email_id)
                  end
                  M.schedule_refresh(1000)
                else
                  vim.notify('Failed to move email to ' .. choice, vim.log.levels.ERROR)
                end
              else
                vim.notify('Delete operation cancelled', vim.log.levels.INFO)
              end
            end)
          else
            vim.notify('No folders available', vim.log.levels.ERROR)
          end
        else
          -- Actually in headless mode, allow permanent delete
          ui.handle_missing_trash_folder(email_id, extra)
        end
      elseif error_type == 'delete_failed' then
        -- Regular delete failure
        local error_msg = type(extra) == 'string' and extra or 'Delete command failed'
        if local_success then
          vim.notify('Delete failed, reverting: ' .. error_msg, vim.log.levels.ERROR)
          M.schedule_refresh(100)
        else
          vim.notify('Failed to delete email: ' .. error_msg, vim.log.levels.ERROR)
        end
      end
    else
      -- Success - only close email view if we're reading an email, not in sidebar
      if not is_in_sidebar then
        local ui = require('neotex.plugins.tools.himalaya.ui')
        ui.close_current_view()
      end
      
      -- Schedule background refresh for server sync
      M.schedule_refresh(2000) -- Reduced from 3000ms to 2000ms
    end
  end, 50)
end

-- Optimized spam operation
function M.spam_email_optimized(email_id, target_folder)
  if not email_id then
    vim.notify('No email selected', vim.log.levels.WARN)
    return
  end
  
  -- Immediately update UI locally
  local local_success = M.remove_email_locally(email_id)
  if local_success then
    vim.notify('Email moved to ' .. target_folder, vim.log.levels.INFO)
  end
  
  -- Perform actual move in background
  vim.defer_fn(function()
    local success = utils.move_email(email_id, target_folder)
    
    if not success then
      -- Revert local changes on failure
      if local_success then
        vim.notify('Move failed, reverting', vim.log.levels.ERROR)
        M.schedule_refresh(100) -- Quick refresh to restore
      else
        vim.notify('Failed to move email', vim.log.levels.ERROR)
      end
    else
      -- Success - schedule background refresh
      M.schedule_refresh(3000)
    end
  end, 50)
end

-- Get optimized refresh function that replaces the original
function M.get_optimized_refresh()
  return function()
    -- Instead of immediate refresh, schedule a debounced refresh
    M.schedule_refresh(500) -- 500ms delay to batch operations
  end
end

-- Quiet refresh function for background operations
function M.get_quiet_refresh()
  return function()
    -- Schedule refresh without notifications
    M.schedule_refresh(1000) -- Longer delay for background operations
  end
end

-- Enhanced move operation with local updates
function M.move_email_optimized(email_id, target_folder)
  if not email_id or not target_folder then
    return false
  end
  
  -- Update locally first
  local local_success = M.remove_email_locally(email_id)
  if local_success then
    vim.notify('Email moved to ' .. target_folder, vim.log.levels.INFO)
  end
  
  -- Perform move in background
  vim.defer_fn(function()
    local success = utils.move_email(email_id, target_folder)
    
    if not success then
      if local_success then
        vim.notify('Move failed, reverting', vim.log.levels.ERROR)
        M.schedule_refresh(100)
      end
    else
      M.schedule_refresh(3000)
    end
  end, 50)
  
  return true
end

-- Disable problematic auto-refresh events
function M.disable_auto_refresh_events()
  -- Clear the Himalaya autocommand group to stop auto-refreshes
  local success, _ = pcall(function()
    vim.api.nvim_del_augroup_by_name('Himalaya')
  end)
  
  if success then
    -- Recreate the group but only with essential autocmds (not refresh ones)
    local augroup = vim.api.nvim_create_augroup('Himalaya', { clear = true })
    
    -- Keep the buffer-specific keymap setup
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'himalaya-*',
      group = augroup,
      callback = function(args)
        local config = require('neotex.plugins.tools.himalaya.config')
        config.setup_buffer_keymaps(args.buf)
      end,
    })
  end
end

-- Re-enable auto-refresh events
function M.enable_auto_refresh_events()
  local config = require('neotex.plugins.tools.himalaya.config')
  config.setup_autocmds() -- This will recreate all the original autocmds
end

-- Apply performance optimizations
function M.apply_optimizations()
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local fixes = require('neotex.plugins.tools.himalaya.fixes')
  
  -- Setup notification management
  notifications.setup_notification_override()
  
  -- Disable auto-refresh autocmds to prevent spam
  M.disable_auto_refresh_events()
  
  -- Override refresh function with debounced version
  ui.refresh_email_list_original = ui.refresh_email_list
  ui.refresh_email_list = M.get_optimized_refresh()
  
  -- Override delete function with optimized version - prevent double execution
  -- Check if local trash is enabled - if so, don't override delete function
  local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
  if not trash_manager.is_enabled() then
    ui.delete_current_email_original = ui.delete_current_email
    ui.delete_current_email = function()
      local email_id = ui.get_current_email_id()
      if not email_id then
        notifications.notify('No email to delete', vim.log.levels.WARN)
        return
      end
      
      -- Call our optimized version ONLY
      M.delete_email_optimized(email_id)
    end
  end
  
  -- Override spam function with optimized version
  ui.spam_current_email_original = ui.spam_current_email
  ui.spam_current_email = function()
    local email_id = ui.get_current_email_id()
    if not email_id then
      vim.notify('No email selected', vim.log.levels.WARN)
      return
    end
    
    local folders = utils.get_folders(config.state.current_account)
    if not folders then
      vim.notify('Could not get folder list', vim.log.levels.ERROR)
      return
    end
    
    local spam_folder = fixes.find_spam_folder(folders)
    
    if spam_folder then
      M.spam_email_optimized(email_id, spam_folder)
    else
      -- Use the improved folder picker from fixes
      fixes.spam_current_email_fixed()
    end
  end
  
  vim.notify('Performance optimizations applied', vim.log.levels.INFO)
end

-- Revert optimizations if needed
function M.revert_optimizations()
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  if ui.refresh_email_list_original then
    ui.refresh_email_list = ui.refresh_email_list_original
  end
  
  if ui.delete_current_email_original then
    ui.delete_current_email = ui.delete_current_email_original
  end
  
  if ui.spam_current_email_original then
    ui.spam_current_email = ui.spam_current_email_original
  end
  
  -- Cancel any pending refreshes
  if M.refresh_timer then
    M.refresh_timer:stop()
    M.refresh_timer:close()
    M.refresh_timer = nil
  end
  
  -- Restore original notifications
  notifications.restore_notification_override()
  
  -- Re-enable auto-refresh events
  M.enable_auto_refresh_events()
  
  notifications.notify_force('Performance optimizations reverted', vim.log.levels.INFO)
end

-- Create commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaOptimize', M.apply_optimizations, {
    desc = 'Apply performance optimizations'
  })
  
  vim.api.nvim_create_user_command('HimalayaRevert', M.revert_optimizations, {
    desc = 'Revert performance optimizations'
  })
  
  vim.api.nvim_create_user_command('HimalayaForceRefresh', function()
    if M.refresh_timer then
      M.refresh_timer:stop()
      M.refresh_timer:close()
      M.refresh_timer = nil
    end
    M.perform_refresh()
  end, {
    desc = 'Force immediate refresh (bypass debouncing)'
  })
end

return M