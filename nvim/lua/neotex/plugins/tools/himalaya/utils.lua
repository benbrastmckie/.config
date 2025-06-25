-- Himalaya Email Client Utilities
-- Utility functions for CLI integration and email operations

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local notify = require('neotex.util.notifications')

-- Execute himalaya command and return output
function M.execute_himalaya(args, opts)
  opts = opts or {}
  local cmd = { config.config.executable }
  
  -- Add the main arguments first (command and subcommand)
  vim.list_extend(cmd, args)
  
  -- Add account specification if provided
  if opts.account then
    table.insert(cmd, '-a')
    table.insert(cmd, opts.account)
  end
  
  -- Add folder specification if provided
  if opts.folder then
    table.insert(cmd, '-f')
    table.insert(cmd, opts.folder)
  end
  
  -- Add output format
  table.insert(cmd, '-o')
  table.insert(cmd, 'json')
  
  -- Execute command
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 then
    notify.himalaya('Himalaya command failed: ' .. (result or 'unknown error'), notify.categories.ERROR)
    return nil
  end
  
  -- Parse JSON output
  local success, data = pcall(vim.json.decode, result)
  if not success then
    notify.himalaya('Failed to parse Himalaya output', notify.categories.ERROR)
    return nil
  end
  
  return data
end

-- Cache for all emails to support pagination without repeatedly fetching
local email_cache = {}
local cache_timestamp = 0
local cache_timeout = 30000 -- 30 seconds

-- Get email list for account and folder
function M.get_email_list(account, folder, page, page_size)
  folder = folder or 'INBOX'
  page = page or 1
  page_size = page_size or 30  -- Default to 30 emails per page
  
  local cache_key = account .. '|' .. folder
  local current_time = vim.loop.now()
  
  -- Check if we need to refresh the cache
  local need_refresh = not email_cache[cache_key] or 
                      (current_time - cache_timestamp) > cache_timeout
  
  if need_refresh then
    notify.himalaya('Fetching emails from Himalaya', notify.categories.BACKGROUND, { cache_refresh = true })
    
    local args = { 'envelope', 'list' }
    
    -- Try to fetch a large number of emails to support pagination
    -- If Himalaya doesn't support --page-size, this will just return all available
    table.insert(args, '--page-size')
    table.insert(args, '200')  -- Fetch up to 200 emails
    
    local result = M.execute_himalaya(args, { account = account, folder = folder })
    
    if result then
      email_cache[cache_key] = result
      cache_timestamp = current_time
      notify.himalaya('Cached emails', notify.categories.BACKGROUND, { count = #result, account = account, folder = folder })
    else
      -- If cache exists, use it; otherwise return nil
      if email_cache[cache_key] then
        notify.himalaya('Using cached emails (fetch failed)', notify.categories.BACKGROUND)
      else
        return nil
      end
    end
  end
  
  local all_emails = email_cache[cache_key] or {}
  
  if #all_emails > 0 then
    -- Calculate the start and end indices for the requested page
    local start_idx = (page - 1) * page_size + 1
    local end_idx = math.min(start_idx + page_size - 1, #all_emails)
    
    -- Return only the emails for this page
    if start_idx <= #all_emails then
      local page_emails = {}
      for i = start_idx, end_idx do
        table.insert(page_emails, all_emails[i])
      end
      notify.himalaya('Email list pagination', notify.categories.STATUS, { page = page, start_idx = start_idx, end_idx = end_idx, total = #all_emails })
      return page_emails
    else
      -- No emails for this page
      notify.himalaya('No emails for page', notify.categories.STATUS, { page = page, total = #all_emails })
      return {}
    end
  end
  
  return all_emails
end

-- Clear email cache (call when emails are modified)
function M.clear_email_cache(account, folder)
  if account and folder then
    local cache_key = account .. '|' .. folder
    email_cache[cache_key] = nil
  else
    -- Clear entire cache
    email_cache = {}
  end
  cache_timestamp = 0
end

-- Legacy error handling (keeping for compatibility)
local function handle_email_list_error(result)
  -- If we get an error, try to provide helpful information
  if not result then
    -- Try to diagnose the issue
    local account_test = M.execute_himalaya({ 'account', 'list' })
    if not account_test then
      notify.himalaya('Account configuration issue', notify.categories.ERROR, { suggestion = 'Try running: himalaya account configure' })
    else
      notify.himalaya('Cannot access maildir', notify.categories.ERROR, { suggestion = 'Check your mail sync status' })
      notify.himalaya('Sync suggestion', notify.categories.STATUS, { command = 'mbsync -a' })
    end
  end
  
  return result
end

-- Get email content by ID
function M.get_email_content(account, email_id)
  local args = { 'message', 'read', tostring(email_id) }
  return M.execute_himalaya(args, { account = account })
end

-- Get folder list for account
function M.get_folders(account)
  local args = { 'folder', 'list' }
  local result = M.execute_himalaya(args, { account = account })
  
  if result and type(result) == 'table' then
    -- Extract folder names from result
    local folders = {}
    for _, folder_data in ipairs(result) do
      if type(folder_data) == 'string' then
        table.insert(folders, folder_data)
      elseif type(folder_data) == 'table' and folder_data.name then
        table.insert(folders, folder_data.name)
      end
    end
    return folders
  end
  
  return nil
end

-- Create a new folder
function M.create_folder(folder_name, account)
  account = account or config.state.current_account
  local args = { 'folder', 'create', folder_name }
  local result = M.execute_himalaya(args, { account = account })
  
  if result then
    notify.himalaya('Folder created', notify.categories.USER_ACTION, { folder = folder_name })
    -- Trigger refresh after folder creation
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaFolderCreated' })
    end, 100)
    return true
  else
    notify.himalaya('Failed to create folder', notify.categories.ERROR, { folder = folder_name })
    return false
  end
end

-- Get unread email count for folder
function M.get_unread_count(account, folder)
  folder = folder or 'INBOX'
  
  -- This is a simplified implementation
  -- You might want to enhance this to get actual unread counts
  local emails = M.get_email_list(account, folder)
  if emails then
    local count = 0
    for _, email in ipairs(emails) do
      if not (email.flags and email.flags.seen) then
        count = count + 1
      end
    end
    return count
  end
  
  return 0
end

-- Get total email count for folder
function M.get_email_count(account, folder)
  folder = folder or 'INBOX'
  
  local emails = M.get_email_list(account, folder)
  return emails and #emails or 0
end

-- Send email
function M.send_email(account, email_data)
  -- Create temporary file with email content
  local temp_file = vim.fn.tempname()
  local content = M.format_email_for_sending(email_data)
  
  local file = io.open(temp_file, 'w')
  if not file then
    notify.himalaya('Failed to create temporary file', notify.categories.ERROR)
    return false
  end
  
  file:write(content)
  file:close()
  
  -- Send email using himalaya
  local cmd = { config.config.executable, 'message', 'send' }
  
  if account then
    table.insert(cmd, '-a')
    table.insert(cmd, account)
  end
  
  -- Execute with stdin
  local full_cmd = table.concat(cmd, ' ')
  notify.himalaya('Executing send command', notify.categories.BACKGROUND, { command = full_cmd })
  notify.himalaya('Email content prepared', notify.categories.BACKGROUND)
  
  -- Use jobstart for better stdin handling
  local result_lines = {}
  local job_id = vim.fn.jobstart(cmd, {
    stdin = 'pipe',
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      vim.list_extend(result_lines, data)
    end,
    on_stderr = function(_, data)
      vim.list_extend(result_lines, data)
    end,
  })
  
  if job_id <= 0 then
    notify.himalaya('Failed to start send job', notify.categories.ERROR)
    os.remove(temp_file)
    return false
  end
  
  -- Send the email content
  local file = io.open(temp_file, 'r')
  local content = file:read('*all')
  file:close()
  
  vim.fn.chansend(job_id, content)
  vim.fn.chanclose(job_id, 'stdin')
  
  -- Wait for completion
  local exit_code = vim.fn.jobwait({job_id}, 5000)[1]
  
  local result = table.concat(result_lines, '\n')
  
  notify.himalaya('Send command result', notify.categories.BACKGROUND, { result = tostring(result) })
  notify.himalaya('Send command exit code', notify.categories.BACKGROUND, { exit_code = exit_code })
  
  -- Clean up temporary file
  os.remove(temp_file)
  
  if exit_code ~= 0 then
    notify.himalaya('Failed to send email', notify.categories.ERROR, { result = result })
    return false
  end
  
  -- Trigger refresh after successful send
  vim.defer_fn(function()
    vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailSent' })
  end, 100)
  
  return true
end

-- Format email data for sending
function M.format_email_for_sending(email_data)
  local lines = {}
  
  -- Headers
  if email_data.from then
    table.insert(lines, 'From: ' .. email_data.from)
  end
  if email_data.to then
    table.insert(lines, 'To: ' .. email_data.to)
  end
  if email_data.cc then
    table.insert(lines, 'Cc: ' .. email_data.cc)
  end
  if email_data.bcc then
    table.insert(lines, 'Bcc: ' .. email_data.bcc)
  end
  if email_data.subject then
    table.insert(lines, 'Subject: ' .. email_data.subject)
  end
  
  -- Empty line between headers and body
  table.insert(lines, '')
  
  -- Body
  if email_data.body then
    table.insert(lines, email_data.body)
  end
  
  return table.concat(lines, '\n')
end

-- Parse email content from buffer lines
function M.parse_email_content(lines)
  local email_data = {}
  local body_start = nil
  
  -- Parse headers
  for i, line in ipairs(lines) do
    if line == '' then
      body_start = i + 1
      break
    end
    
    local header, value = line:match('^([^:]+):%s*(.*)$')
    if header then
      header = header:lower()
      if header == 'from' then
        email_data.from = value
      elseif header == 'to' then
        email_data.to = value
      elseif header == 'cc' then
        email_data.cc = value
      elseif header == 'bcc' then
        email_data.bcc = value
      elseif header == 'subject' then
        email_data.subject = value
      end
    end
  end
  
  -- Parse body
  if body_start then
    local body_lines = {}
    for i = body_start, #lines do
      table.insert(body_lines, lines[i])
    end
    email_data.body = table.concat(body_lines, '\n')
  end
  
  return email_data
end

-- Delete email with improved error handling
function M.delete_email(account, email_id, permanent)
  if permanent then
    -- Permanently delete (flag as deleted + expunge)
    local args = { 'flag', 'add', tostring(email_id), 'Deleted' }
    local result = M.execute_himalaya(args, { account = account })
    if result then
      -- Expunge to permanently remove
      local expunge_success = M.expunge_deleted()
      if expunge_success then
        -- Trigger refresh after permanent deletion
        vim.defer_fn(function()
          vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailDeleted' })
        end, 100)
      end
      return expunge_success
    end
    return false
  else
    -- Try to move to trash first
    local args = { 'message', 'delete', tostring(email_id) }
    local result = M.execute_himalaya(args, { account = account })
    if result then
      -- Trigger refresh after deletion
      vim.defer_fn(function()
        vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailDeleted' })
      end, 100)
    end
    return result ~= nil
  end
end

-- Enhanced delete with local trash support
function M.smart_delete_email(account, email_id)
  -- Check if local trash is enabled
  local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
  local trash_operations = require('neotex.plugins.tools.himalaya.trash_operations')
  
  if trash_manager.is_enabled() then
    -- Use local trash system
    local current_folder = config.state.current_folder or 'INBOX'
    local success = trash_operations.move_to_trash(email_id, current_folder)
    
    if success then
      -- Trigger refresh after successful local trash
      vim.defer_fn(function()
        vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailDeleted' })
      end, 100)
      return true, 'moved_to_local_trash', 'Email moved to local trash'
    else
      return false, 'local_trash_failed', 'Failed to move email to local trash'
    end
  end
  
  -- Fallback to IMAP trash (original behavior)
  local args = { 'message', 'delete', tostring(email_id) }
  local cmd = { config.config.executable }
  vim.list_extend(cmd, args)
  
  if account then
    table.insert(cmd, '-a')
    table.insert(cmd, account)
  end
  
  table.insert(cmd, '-o')
  table.insert(cmd, 'json')
  
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code == 0 then
    return true, 'moved_to_imap_trash', 'Email moved to IMAP trash'
  end
  
  -- If normal delete failed, check if it's a missing trash folder issue
  if result:match('cannot find maildir matching name Trash') then
    -- Get available folders to suggest alternatives
    local folders = M.get_folders(account)
    local suggestions = {}
    
    if folders then
      -- Look for common trash folder names
      local trash_patterns = { 'Trash', 'TRASH', 'Deleted', 'DELETED', 'Junk', 'JUNK' }
      for _, folder in ipairs(folders) do
        for _, pattern in ipairs(trash_patterns) do
          if folder:lower():match(pattern:lower()) then
            table.insert(suggestions, folder)
          end
        end
      end
    end
    
    return false, 'missing_trash', suggestions
  else
    return false, 'delete_failed', result
  end
end

-- Move email to folder
function M.move_email(email_id, target_folder)
  local args = { 'message', 'move', target_folder, tostring(email_id) }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    notify.himalaya('Email moved', notify.categories.USER_ACTION, { folder = target_folder })
    -- Trigger refresh after successful move
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailMoved' })
    end, 100)
    return true
  else
    notify.himalaya('Failed to move email', notify.categories.ERROR)
    return false
  end
end

-- Copy email to folder
function M.copy_email(email_id, target_folder)
  local args = { 'message', 'copy', target_folder, tostring(email_id) }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    notify.himalaya('Email copied', notify.categories.USER_ACTION, { folder = target_folder })
    -- Trigger refresh after successful copy
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailCopied' })
    end, 100)
    return true
  else
    notify.himalaya('Failed to copy email', notify.categories.ERROR)
    return false
  end
end

-- Search emails
function M.search_emails(account, query)
  -- Note: This depends on Himalaya search capabilities
  -- Implementation may vary based on Himalaya version
  local args = { 'envelope', 'list', '--query', query }
  return M.execute_himalaya(args, { account = account })
end

-- Manage email flags
function M.manage_flag(email_id, flag, action)
  local args = { 'flag', action, tostring(email_id), flag }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    notify.himalaya('Flag updated', notify.categories.USER_ACTION, { flag = flag, action = action })
    -- Trigger refresh after flag change
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaFlagChanged' })
    end, 100)
    return true
  else
    notify.himalaya('Failed to manage flag', notify.categories.ERROR)
    return false
  end
end

-- Get email attachments
function M.get_email_attachments(account, email_id)
  local args = { 'attachment', 'list', tostring(email_id) }
  return M.execute_himalaya(args, { account = account })
end

-- Download attachment
function M.download_attachment(email_id, attachment_name)
  local download_dir = config.config.downloads_dir or vim.fn.expand('~/Downloads')
  local args = { 'attachment', 'download', tostring(email_id), attachment_name }
  
  -- Ensure download directory exists
  vim.fn.mkdir(download_dir, 'p')
  
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    notify.himalaya('Attachment downloaded', notify.categories.USER_ACTION, { directory = download_dir })
    return true
  else
    notify.himalaya('Failed to download attachment', notify.categories.ERROR)
    return false
  end
end

-- Validate mbsync configuration
function M.validate_mbsync_config()
  -- Check if mbsync is available
  local mbsync_check = vim.fn.system('which mbsync')
  if vim.v.shell_error ~= 0 then
    return false, 'mbsync not found in PATH'
  end
  
  -- Check if config file exists
  local config_file = vim.fn.expand('~/.mbsyncrc')
  if vim.fn.filereadable(config_file) == 0 then
    return false, 'mbsync configuration file not found at ~/.mbsyncrc'
  end
  
  -- Read and analyze config for common issues
  local config_content = vim.fn.readfile(config_file)
  local content_str = table.concat(config_content, '\n')
  
  -- Check for the specific Path + SubFolders Maildir++ conflict
  local stores = {}
  local current_store = nil
  local issues = {}
  
  for _, line in ipairs(config_content) do
    local store_match = line:match('^MaildirStore%s+(.+)')
    if store_match then
      current_store = store_match
      stores[current_store] = { path = false, subfolders = false, line_num = _ }
    elseif current_store and line:match('^Path%s+') then
      stores[current_store].path = true
    elseif current_store and line:match('^SubFolders%s+Maildir%+%+') then
      stores[current_store].subfolders = true
    end
  end
  
  -- Check for conflicts
  for store_name, store_config in pairs(stores) do
    if store_config.path and store_config.subfolders then
      table.insert(issues, {
        type = 'path_subfolder_conflict',
        store = store_name,
        message = string.format('Store "%s" has both Path and SubFolders Maildir++ (incompatible)', store_name)
      })
    end
  end
  
  if #issues > 0 then
    return false, 'Configuration conflicts detected', issues
  end
  
  return true, 'Configuration appears valid'
end

-- Sync mail using streamlined sync system
function M.sync_mail(force)
  local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  if force then
    return streamlined_sync.sync_full()
  else
    return streamlined_sync.sync_inbox()
  end
end

-- Handle mbsync configuration issues with helpful suggestions
function M.handle_mbsync_config_issues(issues)
  local message_parts = {'Mail sync configuration issues detected:', ''}
  
  for _, issue in ipairs(issues) do
    if issue.type == 'path_subfolder_conflict' then
      table.insert(message_parts, string.format('• %s', issue.message))
      table.insert(message_parts, '  Fix: Choose either "Path" OR "SubFolders Maildir++" (not both)')
      table.insert(message_parts, '  Recommended: Remove "Path" line, keep "SubFolders Maildir++"')
      table.insert(message_parts, '')
    end
  end
  
  table.insert(message_parts, 'To fix: Edit your Nix configuration and rebuild')
  table.insert(message_parts, 'Until fixed, try: :HimalayaAlternativeSync for folder-specific sync')
  
  notify.himalaya('Mail sync error', notify.categories.ERROR, { details = table.concat(message_parts, '\n') })
end

-- Handle sync failure with intelligent error analysis
function M.handle_sync_failure(exit_code, error_output)
  local error_text = table.concat(error_output, '\n')
  
  -- Analyze common error patterns
  if error_text:match('Setting Path is incompatible with .*SubFolders Maildir%+%+') then
    notify.himalaya('Mail sync failed: configuration conflict', notify.categories.ERROR, {
      suggestion = 'Edit ~/.mbsyncrc - use either Path OR SubFolders Maildir++ (not both)'
    })
  elseif error_text:match('No configuration file found') then
    notify.himalaya('Mail sync failed: no configuration found', notify.categories.ERROR, {
      suggestion = 'Run: mbsync --help or check your mail setup'
    })
  elseif error_text:match('authentication') or error_text:match('password') then
    notify.himalaya('Mail sync failed: authentication error', notify.categories.ERROR, {
      suggestion = 'Check your email credentials and oauth tokens'
    })
  elseif error_text:match('network') or error_text:match('connection') then
    notify.himalaya('Mail sync failed: network error', notify.categories.ERROR, {
      suggestion = 'Check your internet connection and email server settings'
    })
  else
    notify.himalaya('Mail sync failed', notify.categories.ERROR, {
      exit_code = exit_code,
      error = error_text ~= '' and error_text or 'Unknown error'
    })
  end
  
  -- Offer alternative sync methods
  M.offer_alternative_sync()
end

-- Offer alternative sync methods when main sync fails
function M.offer_alternative_sync()
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    notify.himalaya('Alternative sync available', notify.categories.STATUS, { command = ':HimalayaAlternativeSync' })
    return
  end
  
  vim.defer_fn(function()
    vim.ui.select({
      'Try alternative sync method',
      'Open mbsync configuration help',
      'Manual terminal sync (mbsync -a)',
      'Cancel'
    }, {
      prompt = 'Mail sync failed. What would you like to do?',
    }, function(choice)
      if choice == 'Try alternative sync method' then
        M.alternative_sync()
      elseif choice == 'Open mbsync configuration help' then
        M.show_config_help()
      elseif choice == 'Manual terminal sync (mbsync -a)' then
        vim.cmd('terminal mbsync -a')
      end
    end)
  end, 1000)
end

-- Alternative sync method using Himalaya directly
function M.alternative_sync()
  notify.himalaya('Trying alternative sync using Himalaya', notify.categories.STATUS)
  
  -- Try to sync specific folders using Himalaya instead of mbsync
  local folders = M.get_folders(config.state.current_account)
  if folders then
    notify.himalaya('Alternative sync completed (using Himalaya folder refresh)', notify.categories.USER_ACTION)
    
    -- Refresh current view if we're in Himalaya
    local current_buf = vim.api.nvim_get_current_buf()
    if vim.bo[current_buf].filetype == 'himalaya-list' then
      vim.defer_fn(function()
        vim.cmd('HimalayaRefresh')
      end, 1000)
    end
  else
    notify.himalaya('Alternative sync failed: Could not access folders', notify.categories.ERROR)
  end
end

-- Enhanced sync with automatic OAuth refresh
function M.smart_sync(force)
  notify.himalaya('Starting smart sync with auto OAuth refresh', notify.categories.STATUS)
  
  -- First try to refresh OAuth tokens using the existing command
  local oauth_cmd = '/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2'
  
  -- Check if refresh script exists
  if vim.fn.executable(oauth_cmd) == 0 then
    notify.himalaya('OAuth refresh script not found, using alternative sync', notify.categories.WARNING)
    M.alternative_sync()
    return
  end
  
  -- Run OAuth refresh in background
  notify.himalaya('Refreshing OAuth tokens...', notify.categories.STATUS)
  
  vim.fn.jobstart(oauth_cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          notify.himalaya('OAuth refresh successful, syncing mail...', notify.categories.STATUS)
          
          -- Wait a moment for OAuth refresh to take effect
          vim.defer_fn(function()
            -- Try mbsync first
            local sync_ok = M.sync_mail(force)
            if not sync_ok then
              notify.himalaya('mbsync failed, using alternative method', notify.categories.STATUS)
              M.alternative_sync()
            end
          end, 1500)
        else
          notify.himalaya('OAuth refresh failed, using alternative sync', notify.categories.WARNING)
          M.alternative_sync()
        end
      end)
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n'):gsub('^%s*(.-)%s*$', '%1')
        if error_msg ~= '' then
          vim.schedule(function()
            notify.himalaya('OAuth refresh error: ' .. error_msg, notify.categories.WARNING)
          end)
        end
      end
    end
  })
end

-- Show configuration help
function M.show_config_help()
  local help_content = {
    'Himalaya Email Configuration Help',
    '====================================',
    '',
    'Common mbsync configuration issues:',
    '',
    '1. Path + SubFolders Maildir++ Conflict',
    '   Problem: Both "Path" and "SubFolders Maildir++" in same store',
    '   Solution: Choose one:',
    '   • Remove "Path" line (recommended)',
    '   • OR remove "SubFolders Maildir++" line',
    '',
    '2. Example working configuration:',
    '   MaildirStore account-local',
    '   Inbox ~/Mail/Account/',
    '   SubFolders Maildir++',
    '   # Path line removed',
    '',
    '3. Alternative working configuration:',
    '   MaildirStore account-local',
    '   Path ~/Mail/Account/',
    '   Inbox ~/Mail/Account/',
    '   # SubFolders line removed',
    '',
    'For Nix users: Update your home-manager mail configuration',
    'and run: home-manager switch',
    '',
    'Commands available:',
    '• :HimalayaAlternativeSync - Try alternative sync method',
    '• :HimalayaConfigValidate - Check configuration',
  }
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.open_email_window(buf, 'Himalaya Configuration Help')
end

-- Configure account
function M.configure_account(account)
  local cmd = { config.config.executable, 'account', 'configure' }
  if account then
    table.insert(cmd, account)
  end
  
  -- Run configuration in terminal
  vim.cmd('terminal ' .. table.concat(cmd, ' '))
end

-- Truncate string to specified length
function M.truncate_string(str, max_length)
  if not str then
    return ''
  end
  
  -- Convert to string if it's not already (handles userdata from JSON)
  str = tostring(str)
  
  if #str <= max_length then
    return str
  end
  
  return str:sub(1, max_length - 3) .. '...'
end

-- Format date for display
function M.format_date(date_str)
  if not date_str then
    return ''
  end
  
  -- Simple date formatting - can be enhanced
  return date_str:gsub('T.*', '') -- Remove time portion
end

-- Check if himalaya is available
function M.check_himalaya_available()
  local result = vim.fn.system(config.config.executable .. ' --version')
  return vim.v.shell_error == 0
end

-- Get account status
function M.get_account_status(account)
  local args = { 'account', 'list' }
  local result = M.execute_himalaya(args)
  
  if result then
    for _, acc in ipairs(result) do
      if acc.name == account then
        return acc
      end
    end
  end
  
  return nil
end

-- Initialize plugin (check dependencies, etc.)
function M.init()
  -- Check if himalaya is available
  if not M.check_himalaya_available() then
    notify.himalaya('Himalaya CLI not found. Please install it first.', notify.categories.ERROR)
    return false
  end
  
  -- Check if mbsync is available
  local mbsync_result = vim.fn.system('mbsync --version')
  if vim.v.shell_error ~= 0 then
    notify.himalaya('mbsync not found. Email sync will not work.', notify.categories.WARNING)
  end
  
  return true
end

-- Auto-sync timer functionality
local sync_timer = nil

function M.start_auto_sync()
  if sync_timer then
    M.stop_auto_sync()
  end
  
  if not config.config.auto_sync then
    return
  end
  
  sync_timer = vim.loop.new_timer()
  sync_timer:start(
    config.config.sync_interval * 1000, -- Convert to milliseconds
    config.config.sync_interval * 1000, -- Repeat interval
    vim.schedule_wrap(function()
      M.sync_mail(false)
    end)
  )
end

function M.stop_auto_sync()
  if sync_timer then
    sync_timer:stop()
    sync_timer:close()
    sync_timer = nil
  end
end

-- Cleanup function
function M.cleanup()
  M.stop_auto_sync()
end

-- Expunge deleted emails
function M.expunge_deleted()
  local config = require('neotex.plugins.tools.himalaya.config')
  local current_folder = config.state.current_folder or 'INBOX'
  local args = { 'folder', 'expunge', current_folder }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    notify.himalaya('Expunged deleted emails', notify.categories.USER_ACTION)
    -- Trigger refresh after expunge
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaExpunged' })
    end, 100)
    return true
  else
    notify.himalaya('Failed to expunge emails', notify.categories.ERROR)
    return false
  end
end

-- Manage email tags
function M.manage_tag(email_id, tag, action)
  local config = require('neotex.plugins.tools.himalaya.config')
  local flag_action = action == 'add' and 'add' or 'remove'
  local args = { 'flag', flag_action, email_id, tag }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    notify.himalaya('Tag updated', notify.categories.USER_ACTION, { action = action, tag = tag })
    -- Trigger refresh after tag change
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaTagChanged' })
    end, 100)
    return true
  else
    notify.himalaya('Failed to manage tag', notify.categories.ERROR)
    return false
  end
end

-- Get email info
function M.get_email_info(email_id)
  local config = require('neotex.plugins.tools.himalaya.config')
  local args = { 'message', 'read', email_id }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  -- Convert result to string if it's a table
  if type(result) == 'table' then
    return vim.inspect(result)
  end
  
  return result
end

-- Diagnose OAuth authentication issues
function M.diagnose_oauth_auth()
  local issues = {}
  local suggestions = {}
  
  -- Check if refresh script exists
  local refresh_script = '/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2'
  if vim.fn.filereadable(refresh_script) == 0 then
    table.insert(issues, 'OAuth refresh script not found at: ' .. refresh_script)
    table.insert(suggestions, 'Ensure gmail OAuth is configured in your Nix/home-manager setup')
  else
    table.insert(issues, 'OAuth refresh script found ✓')
  end
  
  -- Check systemd timer
  local timer_active = vim.fn.system('systemctl --user is-active gmail-oauth2-refresh.timer'):gsub('%s+$', '')
  if timer_active == 'active' then
    table.insert(issues, 'OAuth refresh timer is active ✓')
  else
    table.insert(issues, 'OAuth refresh timer is not active: ' .. timer_active)
    table.insert(suggestions, 'Run: systemctl --user start gmail-oauth2-refresh.timer')
  end
  
  -- Check for stored tokens
  local has_refresh_token = vim.fn.system('secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-refresh-token 2>/dev/null')
  if has_refresh_token and has_refresh_token ~= '' then
    table.insert(issues, 'OAuth refresh token found in keyring ✓')
  else
    table.insert(issues, 'No OAuth refresh token found in keyring')
    table.insert(suggestions, 'Run: himalaya account configure gmail')
  end
  
  -- Check recent refresh attempts
  local recent_logs = vim.fn.system('journalctl --user -u gmail-oauth2-refresh.service -n 3 --no-pager --output=cat 2>/dev/null')
  if recent_logs:match('invalid_client') then
    table.insert(issues, 'OAuth client ID appears to be invalid')
    table.insert(suggestions, 'Check your GMAIL_CLIENT_ID environment variable')
    table.insert(suggestions, 'You may need to create a new OAuth app in Google Cloud Console')
  elseif recent_logs:match('Failed to refresh') then
    table.insert(issues, 'Recent OAuth refresh attempts have failed')
    table.insert(suggestions, 'Try manual refresh: :HimalayaRefreshOAuth')
  end
  
  -- Check mbsync config for OAuth
  local mbsync_config = vim.fn.readfile(vim.fn.expand('~/.mbsyncrc'))
  local has_oauth = false
  for _, line in ipairs(mbsync_config) do
    if line:match('AuthMechs%s+XOAUTH2') then
      has_oauth = true
      break
    end
  end
  
  if has_oauth then
    table.insert(issues, 'mbsync configured for OAuth2 ✓')
  else
    table.insert(issues, 'mbsync not configured for OAuth2')
    table.insert(suggestions, 'Check AuthMechs setting in ~/.mbsyncrc')
  end
  
  return issues, suggestions
end

-- Manual OAuth token refresh
function M.manual_oauth_refresh()
  local refresh_script = '/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2'
  
  if vim.fn.filereadable(refresh_script) == 0 then
    return false, 'OAuth refresh script not found'
  end
  
  local result = vim.fn.system(refresh_script)
  local exit_code = vim.v.shell_error
  
  if exit_code == 0 then
    return true, 'OAuth token refreshed successfully'
  else
    -- Parse error from output
    if result:match('invalid_client') then
      return false, 'Invalid OAuth client ID - check GMAIL_CLIENT_ID environment variable'
    elseif result:match('Missing OAuth2 credentials') then
      return false, 'Missing OAuth credentials - run: himalaya account configure gmail'
    else
      return false, 'OAuth refresh failed: ' .. (result or 'unknown error')
    end
  end
end

return M