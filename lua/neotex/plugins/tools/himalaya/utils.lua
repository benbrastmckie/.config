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

-- Get email content by ID
function M.get_email_content(account, email_id)
  local args = { 'message', 'read', tostring(email_id) }
  return M.execute_himalaya(args, { account = account })
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
function M.delete_email(account, email_id)
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

-- Smart delete email with trash folder detection
function M.smart_delete_email(account, email_id)
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
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
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
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  -- Convert result to string if it's a table
  if type(result) == 'table' then
    return vim.inspect(result)
  end
  
  return result
end

return M