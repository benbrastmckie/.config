-- Himalaya Email Client Utilities
-- Utility functions for CLI integration and email operations

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Truncate string to specified length
function M.truncate_string(str, max_length)
  if not str then return '' end
  
  -- Handle vim.NIL specifically
  if str == vim.NIL then return '' end
  
  -- Convert to string
  local str_value = tostring(str)
  
  if #str_value <= max_length then
    return str_value
  end
  return str_value:sub(1, max_length - 3) .. '...'
end

-- Cache for all emails to support pagination without repeatedly fetching
local email_cache = {}
local cache_timestamp = 0
local cache_timeout = 30000 -- 30 seconds

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

-- Execute himalaya command and return output
function M.execute_himalaya(args, opts)
  opts = opts or {}
  
  -- Get the executable path
  local executable = 'himalaya'
  if config and config.config and config.config.binaries and config.config.binaries.himalaya then
    executable = config.config.binaries.himalaya
  end
  
  local cmd = { executable }
  
  -- Separate query from other args
  local query = nil
  local clean_args = {}
  
  for i, arg in ipairs(args) do
    if arg:match('^order by') then
      query = arg
    else
      table.insert(clean_args, arg)
    end
  end
  
  -- Add the main arguments first (command and subcommand)
  vim.list_extend(cmd, clean_args)
  
  -- Add account specification if provided
  if opts.account then
    table.insert(cmd, '-a')
    table.insert(cmd, opts.account)
  end
  
  -- Add folder specification if provided
  if opts.folder and opts.folder ~= '' then
    table.insert(cmd, '-f')
    table.insert(cmd, opts.folder)
  end
  
  -- Add output format
  table.insert(cmd, '-o')
  table.insert(cmd, 'json')
  
  -- Add query last if present
  if query then
    table.insert(cmd, query)
  end
  
  -- Execute command
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  -- Debug logging for move commands
  if args[1] == 'message' and args[2] == 'move' then
    logger.debug('Move command: ' .. table.concat(cmd, ' '))
    logger.debug('Move result: ' .. (result or 'nil'))
    logger.debug('Move exit code: ' .. exit_code)
  end
  
  if exit_code ~= 0 then
    -- Check if this is the "cannot list maildir entries" error for empty maildir
    if result and result:match('cannot list maildir entries') then
      -- This is expected for empty maildirs, return empty list
      return {}, 0
    end
    notify.himalaya('Himalaya command failed: ' .. (result or 'unknown error'), notify.categories.ERROR)
    return nil
  end
  
  -- For some commands (like move), success is indicated by exit code 0 even without JSON output
  if args[1] == 'message' and (args[2] == 'move' or args[2] == 'delete') then
    -- These commands may not return JSON, just check exit code
    return exit_code == 0
  end
  
  -- Parse JSON output for other commands
  local success, data = pcall(vim.json.decode, result)
  if not success then
    -- Log the raw output for debugging
    logger.error('Failed to parse Himalaya JSON output', {
      command = table.concat(cmd, ' '),
      raw_output = result and result:sub(1, 500) or 'nil', -- First 500 chars for debugging
      error = data
    })
    notify.himalaya('Failed to parse Himalaya output - check :messages for details', notify.categories.ERROR)
    return nil
  end
  
  return data
end

-- Get folder list for account
function M.get_folders(account)
  local args = { 'folder', 'list' }
  local result = M.execute_himalaya(args, { account = account })
  
  local folders = {}
  
  -- Always include INBOX as first folder (it's the special default folder)
  table.insert(folders, 'INBOX')
  
  if result and type(result) == 'table' then
    -- Extract folder names from result
    for _, folder_data in ipairs(result) do
      local folder_name = nil
      if type(folder_data) == 'string' then
        folder_name = folder_data
      elseif type(folder_data) == 'table' and folder_data.name then
        folder_name = folder_data.name
      end
      
      -- Add folder if it's not INBOX (to avoid duplicates)
      if folder_name and folder_name ~= 'INBOX' then
        table.insert(folders, folder_name)
      end
    end
  end
  
  return #folders > 0 and folders or nil
end

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
    -- Remove fetching message - too noisy
    
    local args = { 'envelope', 'list' }
    
    -- Add page size flag first
    table.insert(args, '--page-size')
    table.insert(args, '200')  -- Fetch up to 200 emails
    
    -- Add sorting query as a single argument
    table.insert(args, 'order by date desc')
    
    local result = M.execute_himalaya(args, { account = account, folder = folder })
    
    if result then
      email_cache[cache_key] = result
      cache_timestamp = current_time
      -- Remove cached message - too noisy
    else
      -- If cache exists, use it; otherwise return empty list
      if email_cache[cache_key] then
        -- Remove message - too noisy
      else
        -- Return empty list with count 0 instead of nil
        return {}, 0
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
      -- Remove pagination message - too noisy
      -- Return page emails and total count
      return page_emails, #all_emails
    else
      -- No emails for this page
      notify.himalaya('No emails for page', notify.categories.STATUS, { page = page, total = #all_emails })
      return {}, #all_emails
    end
  end
  
  -- When no pagination is requested, return all emails and count
  return all_emails, #all_emails
end

-- Get email content by ID
function M.get_email_content(account, email_id, folder)
  local args = { 'message', 'read', tostring(email_id) }
  local opts = { account = account }
  if folder then
    opts.folder = folder
  end
  return M.execute_himalaya(args, opts)
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
  local cmd = { config.config.binaries.himalaya or 'himalaya', 'message', 'send' }
  
  if account then
    table.insert(cmd, '-a')
    table.insert(cmd, account)
  end
  
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
  
  -- Clean up temporary file
  os.remove(temp_file)
  
  if exit_code ~= 0 then
    local result = table.concat(result_lines, '\n')
    notify.himalaya('Failed to send email', notify.categories.ERROR, { result = result })
    return false
  end
  
  -- Trigger refresh after successful send
  vim.defer_fn(function()
    vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailSent' })
  end, 100)
  
  return true
end

-- Save email as draft
function M.save_draft(account, email_data, folder)
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
  
  -- Save draft using himalaya
  local cmd = { config.config.binaries.himalaya or 'himalaya', 'message', 'save' }
  
  if account then
    table.insert(cmd, '-a')
    table.insert(cmd, account)
  end
  
  if folder then
    table.insert(cmd, '-f')
    table.insert(cmd, folder)
  end
  
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
    notify.himalaya('Failed to start save job', notify.categories.ERROR)
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
  
  -- Clean up temporary file
  os.remove(temp_file)
  
  if exit_code ~= 0 then
    local result = table.concat(result_lines, '\n')
    notify.himalaya('Failed to save draft', notify.categories.ERROR, { result = result })
    return false
  end
  
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

-- Delete email
function M.delete_email(account, email_id, folder)
  local args = { 'message', 'delete', tostring(email_id) }
  local opts = { account = account }
  if folder then
    opts.folder = folder
  end
  local result = M.execute_himalaya(args, opts)
  if result then
    -- Clear entire cache after successful deletion (we don't know which folder)
    M.clear_email_cache()
    
    -- Trigger refresh after deletion
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailDeleted' })
    end, 100)
  end
  return result ~= nil
end

-- Smart delete email with trash folder detection
function M.smart_delete_email(account, email_id)
  local args = { 'message', 'delete', tostring(email_id) }
  local cmd = { config.config.binaries.himalaya or 'himalaya' }
  vim.list_extend(cmd, args)
  
  if account then
    table.insert(cmd, '-a')
    table.insert(cmd, account)
  end
  
  -- Add current folder
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  local folder = state.get_current_folder()
  if folder then
    table.insert(cmd, '-f')
    table.insert(cmd, folder)
  end
  
  table.insert(cmd, '-o')
  table.insert(cmd, 'json')
  
  -- Debug: show the exact command
  notify.himalaya('Delete command: ' .. table.concat(cmd, ' '), notify.categories.BACKGROUND)
  
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  -- Debug: log the deletion attempt
  if exit_code ~= 0 then
    notify.himalaya('Delete failed: ' .. (result or 'no error message'), notify.categories.ERROR)
  else
    notify.himalaya('Delete result: ' .. (result or 'success'), notify.categories.BACKGROUND)
  end
  
  if exit_code == 0 then
    -- Clear entire cache after successful deletion
    M.clear_email_cache()
    
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailDeleted' })
    end, 100)
    return true, 'moved_to_trash', 'Email moved to trash'
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
  -- Get current folder from UI state
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  local current_folder = state.get_current_folder() or 'INBOX'
  
  local result = M.execute_himalaya(args, { 
    account = config.get_current_account_name(),
    folder = current_folder  -- Add source folder
  })
  
  if result then
    notify.himalaya('Email moved', notify.categories.USER_ACTION, { folder = target_folder })
    -- Clear cache after move
    M.clear_email_cache(config.get_current_account_name(), current_folder)
    M.clear_email_cache(config.get_current_account_name(), target_folder)
    
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

-- Search emails
function M.search_emails(account, query)
  local args = { 'envelope', 'list', '--query', query }
  return M.execute_himalaya(args, { account = account })
end

-- Get email attachments
function M.get_email_attachments(account, email_id)
  local args = { 'attachment', 'list', tostring(email_id) }
  return M.execute_himalaya(args, { account = account })
end

-- Manage email tags/flags
function M.manage_tag(email_id, tag, action)
  local flag_action = action == 'add' and 'add' or 'remove'
  local args = { 'flag', flag_action, email_id, tag }
  local result = M.execute_himalaya(args, { account = config.get_current_account_name() })
  
  if result then
    notify.himalaya('Tag updated', notify.categories.USER_ACTION, { action = action, tag = tag })
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
  local args = { 'message', 'read', email_id }
  local result = M.execute_himalaya(args, { account = config.get_current_account_name() })
  
  -- Convert result to string if it's a table
  if type(result) == 'table' then
    return vim.inspect(result)
  end
  
  return result
end

return M