-- Himalaya Email Client UI
-- Buffer and window management for email interface

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local state = require('neotex.plugins.tools.himalaya.core.state')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
local email_viewer = require('neotex.plugins.tools.himalaya.ui.email_viewer')
local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')

-- Buffer tracking
M.buffers = {
  email_list = nil,
  email_read = nil,
  email_compose = nil,
}

-- Initialize UI components
function M.init()
  -- Initialize state management first
  state.init()
  
  -- Initialize sidebar with state
  sidebar.init()
  
  -- Initialize email list module with buffer reference
  email_list.init(M.buffers)
  
  -- Initialize email viewer module with buffer reference and main module
  email_viewer.init(M.buffers, M)
  
  -- Initialize email composer module with buffer reference, main module, and window stack
  email_composer.init(M.buffers, M, window_stack)
  
  -- Sync state with sidebar configuration (non-intrusive)
  state.sync_with_sidebar()
  
  -- Note: Session restoration is now manual only
  -- Call M.restore_session() explicitly if needed
end

-- Toggle email sidebar
function M.toggle_email_sidebar()
  return email_list.toggle_email_sidebar()
end

function M.show_email_list(args)
  return email_list.show_email_list(args)
end

-- Format email list for display (matching old UI exactly)
function M.format_email_list(emails)
  return email_list.format_email_list(emails)
end

-- Get sync status line for header
function M.get_sync_status_line()
  return email_list.get_sync_status_line()
end

-- Get sync status line for header with enhanced progress information (from old UI)
function M.get_sync_status_line_detailed()
  return email_list.get_sync_status_line_detailed()
end
-- Start sync status updates
function M.start_sync_status_updates()
  return email_list.start_sync_status_updates()
end

-- Stop sync status updates
function M.stop_sync_status_updates()
  return email_list.stop_sync_status_updates()
end

-- Update sidebar with current sync status
function M.update_sidebar_sync_status()
  return email_list.update_sidebar_sync_status()
end

-- Refresh just the sidebar header (without refetching emails)
function M.refresh_sidebar_header()
  return email_list.refresh_sidebar_header()
end

-- Read specific email
function M.read_email(email_id)
  return email_viewer.read_email(email_id)
end

-- Format email content for display
function M.format_email_content(email_content)
  return email_viewer.format_email_content(email_content)
end

-- Process email body text and extract URLs
function M.process_email_body(body_lines, urls)
  return email_viewer.process_email_body(body_lines, urls)
end

-- Compose new email
function M.compose_email(to_address)
  return email_composer.compose_email(to_address)
end

-- Open email window (floating)
function M.open_email_window(buf, title, parent_win)
  -- Calculate window size
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  
  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })
  
  -- Window settings
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'linebreak', true)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  -- Track window in stack for proper focus restoration
  -- Use provided parent window or current window as fallback
  window_stack.push(win, parent_win or vim.api.nvim_get_current_win())
  
  return win
end

-- Pagination functions
function M.reset_pagination()
  state.set_current_page(1)
end

function M.next_page()
  return email_list.next_page()
end

function M.prev_page()
  return email_list.prev_page()
end

-- Refresh current email list
function M.refresh_email_list()
  return email_list.refresh_email_list()
end

-- Send current email (from compose buffer)
function M.send_current_email()
  return email_composer.send_current_email()
end

-- Check if email buffer is open (for backward compatibility)
function M.is_email_buffer_open()
  return sidebar.is_open()
end

-- Close without saving (discard)
-- Close compose buffer without saving (delegation to appropriate module)
function M.close_without_saving()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].himalaya_compose then
    return email_composer.close_without_saving()
  else
    -- Original implementation for non-compose buffers
    local parent_win = vim.b[buf].himalaya_parent_win
    local parent_buf = vim.b[buf].himalaya_parent_buf
    
    -- Close the current window
    local current_win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(current_win) then
      vim.api.nvim_win_close(current_win, true)
    end
    
    -- Delete the buffer
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    
    -- Explicitly restore focus to email reading window
    vim.defer_fn(function()
      -- First try the stored email reading window (most reliable for replies)
      if M._email_reading_win and vim.api.nvim_win_is_valid(M._email_reading_win) then
        vim.api.nvim_set_current_win(M._email_reading_win)
        M._email_reading_win = nil  -- Clear it after use
      elseif parent_win and vim.api.nvim_win_is_valid(parent_win) then
        vim.api.nvim_set_current_win(parent_win)
      elseif parent_buf and vim.api.nvim_buf_is_valid(parent_buf) then
        -- Parent window was closed, try to find a window showing the parent buffer
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == parent_buf then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
      end
    end, 50)
    
    notifications.show('Draft discarded', 'info')
  end
end

-- Navigate to next field in compose buffer
function M.compose_next_field()
  return email_composer.compose_next_field()
end

-- Navigate to previous field in compose buffer
function M.compose_prev_field()
  return email_composer.compose_prev_field()
end

-- Close and save as draft (delegation to appropriate module)
function M.close_and_save_draft()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].himalaya_compose then
    return email_composer.close_and_save_draft()
  else
    -- Original implementation for non-compose buffers
    local parent_win = vim.b[buf].himalaya_parent_win
    local parent_buf = vim.b[buf].himalaya_parent_buf
    
    -- Close the current window
    local current_win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(current_win) then
      vim.api.nvim_win_close(current_win, true)
    end
    
    -- Explicitly restore focus to email reading window
    vim.defer_fn(function()
      -- First try the stored email reading window (most reliable for replies)
      if M._email_reading_win and vim.api.nvim_win_is_valid(M._email_reading_win) then
        vim.api.nvim_set_current_win(M._email_reading_win)
        M._email_reading_win = nil  -- Clear it after use
      elseif parent_win and vim.api.nvim_win_is_valid(parent_win) then
        vim.api.nvim_set_current_win(parent_win)
      elseif parent_buf and vim.api.nvim_buf_is_valid(parent_buf) then
        -- Parent window was closed, try to find a window showing the parent buffer
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == parent_buf then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
      end
    end, 50)
  end
end

-- Read current email (from email list buffer)
function M.read_current_email()
  return email_viewer.read_current_email()
end

-- Helper function to get current email ID
function M.get_current_email_id()
  if vim.bo.filetype ~= 'himalaya-list' then
    return nil
  end
  
  local line_num = vim.fn.line('.')
  local emails = vim.b.himalaya_emails
  local email_start_line = vim.b.himalaya_email_start_line
  
  if not emails or #emails == 0 then
    return nil
  end
  
  -- Use stored email start line if available
  if not email_start_line then
    -- Fallback: Find where emails actually start by looking for the pattern of the first email
    email_start_line = 0
    for i = 1, 15 do  -- Check first 15 lines
      local line = vim.fn.getline(i)
      -- Look for email lines which have the status indicator pattern [*] or [ ]
      -- In selection mode, lines start with checkbox [ ] or [x] followed by status [*] or [ ]
      -- Without selection mode, lines start directly with status [*] or [ ]
      if line and (line:match('^%[[ *]%] [^ ]') or line:match('^%[[ x]%] %[[ *]%]')) then
        email_start_line = i
        break
      end
    end
    
    -- Fallback: count header lines by finding the separator line
    if email_start_line == 0 then
      for i = 1, 10 do  -- Check first 10 lines
        local line = vim.fn.getline(i)
        if line and line:match('^[─]+$') then  -- Found separator line
          email_start_line = i + 2  -- Emails start after separator + empty line
          break
        end
      end
    end
    
    -- Final fallback if nothing found
    if email_start_line == 0 then
      email_start_line = 6 -- Default
    end
  end
  
  local email_index = line_num - email_start_line + 1
  
  if email_index > 0 and email_index <= #emails and emails[email_index] then
    return emails[email_index].id
  end
  
  return nil
end

-- Close current view using window stack
function M.close_current_view()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Check if we're closing an email reading buffer
  local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
  
  -- Try to close using window stack first
  if not window_stack.close_current() then
    -- If not in stack, close normally
    vim.cmd('close')
  end
  
  -- Refresh email list after closing email reading view
  if is_email_buffer then
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  end
end

-- Close Himalaya entirely (all buffers and sidebar)
function M.close_himalaya()
  -- Save state before closing
  state.save()
  
  -- Close and cleanup sidebar (including buffer)
  sidebar.close_and_cleanup()
  
  -- Close all tracked Himalaya buffers
  local closed_buffers = 0
  for name, buf in pairs(M.buffers) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
      closed_buffers = closed_buffers + 1
    end
  end
  
  -- Find and close any remaining Himalaya buffers by filetype
  local all_buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(all_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ok, filetype = pcall(vim.api.nvim_buf_get_option, buf, 'filetype')
      if ok and filetype and filetype:match('^himalaya%-') then
        vim.api.nvim_buf_delete(buf, { force = true })
        closed_buffers = closed_buffers + 1
      end
    end
  end
  
  -- Clear window stack
  window_stack.clear()
  
  -- Reset buffer tracking
  M.buffers = {
    email_list = nil,
    email_read = nil,
    email_compose = nil,
  }
  
  notifications.show('Himalaya closed', 'info', { buffers_cleaned = closed_buffers })
end

-- Update email display without resetting pagination
function M.update_email_display()
  return email_list.update_email_display()
end

-- Refresh current view
function M.refresh_current_view()
  return email_list.refresh_current_view()
end

-- Reply to current email
function M.reply_current_email()
  return email_composer.reply_current_email()
end

-- Reply all to current email
function M.reply_all_current_email()
  return email_composer.reply_all_current_email()
end

-- Reply to email
function M.reply_email(email_id, reply_all)
  return email_composer.reply_email(email_id, reply_all)
end

-- Parse email content for reply operations
function M.parse_email_for_reply(email_content)
  return email_composer.parse_email_for_reply(email_content)
end

-- Forward current email
function M.forward_current_email()
  return email_composer.forward_current_email()
end

-- Forward email
function M.forward_email(email_id)
  return email_composer.forward_email(email_id)
end

-- Delete current email
function M.delete_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  
  -- If no email_id in buffer variable, try to get it from cursor position (sidebar)
  if not email_id then
    email_id = M.get_current_email_id()
  end
  
  if not email_id then
    notifications.show('No email to delete', 'warn')
    return
  end
  
  local success, error_type, extra = utils.smart_delete_email(state.get_current_account(), email_id)
  
  if success then
    notifications.show('Email deleted successfully', 'info')
    
    -- Only close view if we're in an email reading buffer, not the sidebar
    local current_buf = vim.api.nvim_get_current_buf()
    local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
    local is_sidebar = vim.bo[current_buf].filetype == 'himalaya-list'
    
    if is_email_buffer and not is_sidebar then
      M.close_current_view()
    end
    
    -- Always refresh the list to show the deletion
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  elseif error_type == 'missing_trash' then
    -- Trash folder doesn't exist, offer alternatives
    M.handle_missing_trash_folder(email_id, extra)
  else
    notifications.show('Failed to delete email', 'error', { error = extra or 'Unknown error' })
  end
end

-- Handle missing trash folder scenario
function M.handle_missing_trash_folder(email_id, suggested_folders)
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just permanently delete
    notifications.show('Permanently deleting email (trash folder not found)', 'info')
    M.permanent_delete_email(email_id)
    return
  end
  
  local options = {'Permanently delete (cannot be undone)'}
  
  -- Add suggested trash folders
  if suggested_folders and #suggested_folders > 0 then
    for _, folder in ipairs(suggested_folders) do
      table.insert(options, 'Move to ' .. folder)
    end
  end
  
  -- Add option to move to a custom folder
  table.insert(options, 'Move to custom folder...')
  table.insert(options, 'Cancel')
  
  vim.ui.select(options, {
    prompt = 'Trash folder not found. How would you like to delete this email?',
  }, function(choice)
    if not choice or choice == 'Cancel' then
      return
    end
    
    if choice == 'Permanently delete (cannot be undone)' then
      M.permanent_delete_email(email_id)
    elseif choice:match('^Move to ') then
      local folder = choice:gsub('^Move to ', '')
      M.move_email_to_folder(email_id, folder)
    elseif choice == 'Move to custom folder...' then
      M.prompt_custom_folder_move(email_id)
    end
  end)
end

-- Permanently delete email
function M.permanent_delete_email(email_id)
  local success = utils.delete_email(state.get_current_account(), email_id, state.get_current_folder())
  if success then
    notifications.show('Email permanently deleted', 'info')
    M.close_current_view()
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  else
    notifications.show('Failed to permanently delete email', 'error')
  end
end

-- Move email to specific folder
function M.move_email_to_folder(email_id, folder)
  local success = utils.move_email(email_id, folder)
  if success then
    M.close_current_view()
    -- Refresh is handled by the autocmd from utils.move_email
  end
end

-- Prompt for custom folder name
function M.prompt_custom_folder_move(email_id)
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, use a default folder
    notifications.show('Moving email to Archive folder', 'info')
    M.move_email_to_folder(email_id, 'Archive')
    return
  end
  
  vim.ui.input({
    prompt = 'Enter folder name: ',
    completion = 'custom,folder',
  }, function(folder)
    if folder and folder ~= '' then
      M.move_email_to_folder(email_id, folder)
    end
  end)
end

-- Archive current email (from email list)
function M.archive_current_email()
  local email_id = nil
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Try to get email ID based on current buffer type
  if vim.bo[current_buf].filetype == 'himalaya-list' then
    email_id = M.get_current_email_id()
  elseif vim.b[current_buf].himalaya_email_id then
    -- We're in email reading buffer
    email_id = vim.b[current_buf].himalaya_email_id
  end
  
  if email_id then
    -- Try different archive folder names that might exist
    local archive_folders = {'All_Mail', 'Archive', 'All Mail', 'ARCHIVE', 'Archived'}
    local folders = utils.get_folders(state.get_current_account())
    local archive_folder = nil
    
    if folders then
      -- Find the first existing archive folder
      for _, folder in ipairs(folders) do
        for _, archive_name in ipairs(archive_folders) do
          -- Check exact match first, then case-insensitive match
          if folder == archive_name or folder:lower() == archive_name:lower() then
            archive_folder = folder
            break
          end
        end
        if archive_folder then break end
      end
    end
    
    if archive_folder then
      local success = utils.move_email(email_id, archive_folder)
      if success then
        notifications.show('Email archived', 'info', { folder = archive_folder })
        
        -- Close email view if we're reading the email
        local current_buf = vim.api.nvim_get_current_buf()
        local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
        local is_sidebar = vim.bo[current_buf].filetype == 'himalaya-list'
        
        if is_email_buffer and not is_sidebar then
          M.close_current_view()
        end
        
        -- Always refresh the sidebar to show the change
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 100)
      end
    else
      -- If no archive folder found, offer alternatives
      vim.ui.select({
        'Move to All_Mail',
        'Create Archive folder',
        'Move to custom folder...',
        'Cancel'
      }, {
        prompt = 'No archive folder found. How would you like to archive this email?',
      }, function(choice)
        if choice == 'Move to All_Mail' then
          utils.move_email(email_id, 'All_Mail')
        elseif choice == 'Create Archive folder' then
          utils.move_email(email_id, '[Gmail].All Mail')
        elseif choice == 'Move to custom folder...' then
          vim.ui.input({
            prompt = 'Enter folder name: ',
          }, function(folder)
            if folder and folder ~= '' then
              utils.move_email(email_id, folder)
            end
          end)
        end
      end)
    end
  else
    notifications.show('No email selected', 'warn')
  end
end

-- Mark current email as spam and move to spam folder
function M.spam_current_email()
  local email_id = M.get_current_email_id()
  if email_id then
    -- Try different spam folder names that might exist
    local spam_folders = {'Spam', 'Junk', 'SPAM', 'JUNK'}
    local folders = utils.get_folders(state.get_current_account())
    local spam_folder = nil
    
    if folders then
      -- Find the first existing spam folder
      for _, folder in ipairs(folders) do
        for _, spam_name in ipairs(spam_folders) do
          -- Check exact match first, then case-insensitive match
          if folder == spam_name or folder:lower() == spam_name:lower() then
            spam_folder = folder
            break
          end
        end
        if spam_folder then break end
      end
    end
    
    if spam_folder then
      local success = utils.move_email(email_id, spam_folder)
      if success then
        notifications.show('Email marked as spam', 'info', { folder = spam_folder })
        
        -- Close email view if we're reading the email
        local current_buf = vim.api.nvim_get_current_buf()
        local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
        local is_sidebar = vim.bo[current_buf].filetype == 'himalaya-list'
        
        if is_email_buffer and not is_sidebar then
          M.close_current_view()
        end
        
        -- Always refresh the sidebar to show the change
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 100)
      end
    else
      -- If no spam folder found, ask user what to do
      vim.ui.select({
        'Move to Junk folder',
        'Move to Spam folder', 
        'Delete permanently',
        'Cancel'
      }, {
        prompt = 'No spam folder found. How would you like to handle this email?',
      }, function(choice)
        if choice == 'Move to Junk folder' then
          utils.move_email(email_id, 'Junk')
        elseif choice == 'Move to Spam folder' then
          utils.move_email(email_id, 'Spam')
        elseif choice == 'Delete permanently' then
          M.delete_current_email()
        end
      end)
    end
  else
    notifications.show('No email selected', 'warn')
  end
end

-- Search emails
function M.search_emails(query)
  return email_list.search_emails(query)
end

-- Show attachments
function M.show_attachments(email_id)
  return email_viewer.show_attachments(email_id)
end

-- Open link under cursor
function M.open_link_under_cursor()
  return email_viewer.open_link_under_cursor()
end

-- Open URL using system default browser
function M.open_url(url)
  return email_viewer.open_url(url)
end

-- Session restoration functions
function M.can_restore_session()
  if not state.is_state_fresh() then
    return false, "No recent session found (older than 24 hours)"
  end
  
  local current_account = state.get_current_account()
  local current_folder = state.get_current_folder()
  
  if not current_account or not current_folder then
    return false, "No previous email session found"
  end
  
  return true, string.format("Session available: %s/%s", current_account, current_folder)
end

-- Restore session from state (manual only)
function M.restore_session()
  local can_restore, message = M.can_restore_session()
  
  if not can_restore then
    notifications.show('Cannot restore session', 'warn', { error = message })
    return false
  end
  
  local current_account = state.get_current_account()
  local current_folder = state.get_current_folder()
  local selected_email = state.get_selected_email()
  
  vim.defer_fn(function()
    -- Show the email list for the saved folder/account
    M.show_email_list({current_folder, '--account=' .. current_account})
    
    -- Check if we're in headless mode
    local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
    
    -- Ask user if they want to restore the selected email (skip in headless)
    if selected_email and not is_headless then
      vim.ui.select({'Open previous email', 'Just show email list'}, {
        prompt = 'Restore previous email session:',
      }, function(choice)
        if choice == 'Open previous email' then
          vim.defer_fn(function()
            M.read_email(selected_email)
          end, 200)
        end
      end)
    elseif selected_email and is_headless then
      -- In headless mode, just restore the email directly
      vim.defer_fn(function()
        M.read_email(selected_email)
      end, 200)
    end
    
    -- Restore search results if available
    local last_query = state.get_last_query()
    local search_results = state.get_search_results()
    if last_query and search_results then
      notifications.show('Previous search available', 'info', { query = last_query })
    end
    
    notifications.show('Email session restored', 'info')
  end, 100)
  
  return true
end

-- Show session restoration prompt (called manually)
function M.prompt_session_restore()
  local can_restore, message = M.can_restore_session()
  
  if not can_restore then
    notifications.show(message, 'info')
    return
  end
  
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just restore directly
    notifications.show(message, 'info')
    M.restore_session()
  else
    vim.ui.select({'Restore previous session', 'Start fresh'}, {
      prompt = message .. ' - Restore?',
    }, function(choice)
      if choice == 'Restore previous session' then
        M.restore_session()
      end
    end)
  end
end

-- Show folder picker
function M.pick_folder()
  return email_list.pick_folder()
end

-- Show account picker
function M.pick_account()
  return email_list.pick_account()
end

-- Batch Operations

-- Batch delete operation
function M.delete_selected_emails()
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notifications.show('No emails selected', 'warn')
    return
  end
  
  -- Confirm batch operation
  vim.ui.input({
    prompt = string.format('Delete %d selected emails? (y/n): ', #selected)
  }, function(input)
    if input and input:lower() == 'y' then
      local success_count = 0
      local error_count = 0
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notifications.show(string.format('Deleting %d emails...', #selected), 'info')
      end
      
      for i, email in ipairs(selected) do
        local success, error_type = utils.smart_delete_email(state.get_current_account(), email.id)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
          -- Log specific error for debugging
          notifications.show(string.format('Failed to delete email %s: %s', 
            email.subject or email.id, error_type or 'unknown error'), 'error')
        end
        
        -- Update progress for large batches
        if #selected > 10 and i % 10 == 0 then
          notifications.show(string.format('Progress: %d/%d', i, #selected), 'info')
        end
      end
      
      state.clear_selection()
      state.toggle_selection_mode() -- Exit selection mode
      
      notifications.show(
        string.format('Deleted %d emails (%d errors)', success_count, error_count),
        error_count > 0 and 'warn' or 'success'
      )
      
      M.refresh_email_list()
    end
  end)
end

-- Batch archive operation
function M.archive_selected_emails()
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notifications.show('No emails selected', 'warn')
    return
  end
  
  vim.ui.input({
    prompt = string.format('Archive %d selected emails? (y/n): ', #selected)
  }, function(input)
    if input and input:lower() == 'y' then
      local success_count = 0
      local error_count = 0
      
      -- Find archive folder
      local archive_folders = {'Archive', 'All Mail', 'All_Mail', '[Gmail]/All Mail'}
      local folders = utils.get_folders(state.get_current_account())
      local archive_folder = nil
      
      if folders then
        for _, folder in ipairs(folders) do
          for _, archive_name in ipairs(archive_folders) do
            if folder == archive_name or folder:match(archive_name) then
              archive_folder = folder
              break
            end
          end
          if archive_folder then break end
        end
      end
      
      if not archive_folder then
        archive_folder = 'All_Mail' -- Default fallback
      end
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notifications.show(string.format('Archiving %d emails to %s...', #selected, archive_folder), 'info')
      end
      
      for i, email in ipairs(selected) do
        local success = utils.move_email(email.id, archive_folder)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
          notify.himalaya(string.format('Failed to archive email %s', 
            email.subject or email.id), notify.categories.BACKGROUND)
        end
        
        -- Update progress for large batches
        if #selected > 10 and i % 10 == 0 then
          notifications.show(string.format('Progress: %d/%d', i, #selected), 'info')
        end
      end
      
      state.clear_selection()
      state.toggle_selection_mode()
      
      notifications.show(
        string.format('Archived %d emails (%d errors)', success_count, error_count),
        error_count > 0 and 'warn' or 'success'
      )
      
      M.refresh_email_list()
    end
  end)
end

-- Batch spam operation
function M.spam_selected_emails()
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notifications.show('No emails selected', 'warn')
    return
  end
  
  vim.ui.input({
    prompt = string.format('Mark %d selected emails as spam? (y/n): ', #selected)
  }, function(input)
    if input and input:lower() == 'y' then
      local success_count = 0
      local error_count = 0
      
      -- Find spam folder
      local spam_folders = {'Spam', 'Junk', 'SPAM', 'JUNK', '[Gmail]/Spam'}
      local folders = utils.get_folders(state.get_current_account())
      local spam_folder = nil
      
      if folders then
        for _, folder in ipairs(folders) do
          for _, spam_name in ipairs(spam_folders) do
            if folder == spam_name or folder:lower() == spam_name:lower() then
              spam_folder = folder
              break
            end
          end
          if spam_folder then break end
        end
      end
      
      if not spam_folder then
        spam_folder = 'Spam' -- Default fallback
      end
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notifications.show(string.format('Moving %d emails to spam...', #selected), 'info')
      end
      
      for i, email in ipairs(selected) do
        local success = utils.move_email(email.id, spam_folder)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
          notify.himalaya(string.format('Failed to mark email as spam: %s', 
            email.subject or email.id), notify.categories.BACKGROUND)
        end
        
        -- Update progress for large batches
        if #selected > 10 and i % 10 == 0 then
          notifications.show(string.format('Progress: %d/%d', i, #selected), 'info')
        end
      end
      
      state.clear_selection()
      state.toggle_selection_mode()
      
      notifications.show(
        string.format('Marked %d emails as spam (%d errors)', success_count, error_count),
        error_count > 0 and 'warn' or 'success'
      )
      
      M.refresh_email_list()
    end
  end)
end


return M