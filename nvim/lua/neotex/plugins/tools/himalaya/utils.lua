-- Himalaya Email Client Utilities
-- Utility functions for CLI integration and email operations
--
-- Email Count Architecture:
-- 1. Counts are fetched from himalaya using fetch_folder_count() with binary search
-- 2. Counts are stored in state module using state.set_folder_count()
-- 3. Counts are automatically updated after sync by sync/manager.lua
-- 4. UI displays counts from state.get_folder_count() with age indicator

-- TODO: Add email caching with TTL and LRU eviction
-- TODO: Implement parallel email fetching for better performance
-- TODO: Add email search and filtering utilities
-- TODO: Implement email attachment handling utilities
-- TODO: Add email validation and sanitization functions

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local state = require('neotex.plugins.tools.himalaya.core.state')

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
    -- Check if this is an "out of bounds" error - expected during binary search
    if result and result:match('out of bounds') then
      -- This is expected during pagination search, return nil silently
      return nil
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
  
  -- Fetch only the requested page
  local args = { 'envelope', 'list' }
  
  -- Add pagination flags
  table.insert(args, '--page')
  table.insert(args, tostring(page))
  table.insert(args, '--page-size')
  table.insert(args, tostring(page_size))
  
  -- Add sorting query as a single argument
  table.insert(args, 'order by date desc')
  
  local result = M.execute_himalaya(args, { account = account, folder = folder })
  
  if not result then
    return {}, 0
  end
  
  -- Get stored count from state (from sync operations)
  local stored_count = state.get_folder_count(account, folder)
  
  -- If we have a stored count, use it
  if stored_count and stored_count > 0 then
    return result, stored_count
  end
  
  -- Otherwise, estimate based on the page results
  -- If we got a full page, there might be more emails
  local estimated_count = #result
  if #result >= page_size then
    -- We don't know the exact count, but there are at least page * page_size emails
    estimated_count = page * page_size
  end
  
  return result, estimated_count
end

-- Get email list with smart page filling (ensures full pages when possible)
function M.get_email_list_smart_fill(account, folder, page, page_size)
  folder = folder or 'INBOX'
  page = page or 1
  page_size = page_size or 25
  
  -- Get the initial page
  local emails, total_count = M.get_email_list(account, folder, page, page_size)
  
  -- If we got fewer emails than page_size and we're not on page 1, 
  -- try to get a full page by adjusting the page number
  if #emails < page_size and page > 1 and total_count and total_count > 0 then
    -- Calculate what page would give us a full page of emails
    local total_pages = math.ceil(total_count / page_size)
    local emails_before_current_page = (page - 1) * page_size
    local remaining_emails = total_count - emails_before_current_page
    
    -- If there are fewer remaining emails than page_size, try to go back to get a full page
    if remaining_emails < page_size and remaining_emails > 0 then
      local target_page = math.max(1, math.ceil((total_count - page_size + 1) / page_size))
      if target_page < page then
        -- Get the emails from the adjusted page
        local adjusted_emails, adjusted_count = M.get_email_list(account, folder, target_page, page_size)
        if #adjusted_emails >= #emails then
          -- Update the current page in state to reflect the change
          local state = require('neotex.plugins.tools.himalaya.core.state')
          state.set_current_page(target_page)
          
          -- Provide feedback about page adjustment (only in debug mode to avoid noise)
          local notify = require('neotex.util.notifications')
          if notify.config.modules.himalaya.debug_mode then
            notify.himalaya(string.format('Page adjusted from %d to %d for full page view', page, target_page), notify.categories.BACKGROUND)
          end
          
          return adjusted_emails, adjusted_count, target_page
        end
      end
    end
  end
  
  return emails, total_count, page
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

-- Get email by ID
function M.get_email_by_id(account, folder, email_id)
  -- Use execute_himalaya for consistent command construction
  local args = { 'message', 'read', tostring(email_id) }
  local opts = { account = account, folder = folder }
  
  local output = M.execute_himalaya(args, opts)
  if not output then
    return nil, 'Failed to read email'
  end
  
  -- If output is a table (JSON), it's already parsed
  if type(output) == 'table' then
    return output
  end
  
  -- Otherwise parse the text output
  local email = {
    id = email_id,
    body = output,
  }
  
  -- Extract headers from the output
  local in_headers = true
  local body_lines = {}
  local lines = vim.split(output, '\n', { plain = true })
  
  for _, line in ipairs(lines) do
    if in_headers and line == "" then
      in_headers = false
    elseif in_headers then
      local header, value = line:match("^([^:]+):%s*(.*)$")
      if header then
        email[header:lower():gsub("-", "_")] = value
      end
    else
      table.insert(body_lines, line)
    end
  end
  
  email.body = table.concat(body_lines, "\n")
  
  return email
end

-- Find draft folder for account
function M.find_draft_folder(account)
  local account_config = config.get_account(account)
  if not account_config then
    return nil
  end
  
  -- Check folder map for draft folder
  if account_config.folder_map then
    for imap, local_folder in pairs(account_config.folder_map) do
      if imap:lower():match('draft') then
        -- For maildir, we need the IMAP name, not the local folder name
        return imap
      end
    end
  end
  
  -- Check common draft folder names
  local draft_folders = { '[Gmail]/Drafts', 'Drafts', 'DRAFTS', 'Draft', '.Drafts' }
  
  -- For Gmail specifically, use [Gmail]/Drafts
  if account:lower() == 'gmail' then
    return '[Gmail]/Drafts'
  end
  
  -- Default to 'Drafts'
  return 'Drafts'
end

-- Save draft to maildir
function M.save_draft(account, folder, email_data)
  -- Build himalaya command with correct v1.1.0 syntax
  local cmd_parts = {
    config.config.binaries.himalaya or 'himalaya',
    'message', 'save',
    '-a', account,
    '-f', folder,
  }
  
  -- Create email content
  local content = M.format_email_for_sending(email_data)
  
  -- Log the command and content for debugging
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  logger.debug('Saving draft', {
    account = account,
    folder = folder,
    cmd = table.concat(cmd_parts, ' '),
    has_content = content ~= nil,
    content_length = content and #content or 0,
    from = email_data.from,
    to = email_data.to,
    subject = email_data.subject
  })
  
  -- Write content to temporary file instead of using echo
  local temp_file = vim.fn.tempname()
  local file = io.open(temp_file, 'w')
  if not file then
    logger.error('Failed to create temp file for draft')
    return nil, 'Failed to create temporary file'
  end
  file:write(content)
  file:close()
  
  -- Use cat to pipe content (more reliable than echo)
  local full_cmd = string.format(
    'cat %s | %s',
    vim.fn.shellescape(temp_file),
    table.concat(cmd_parts, ' ')
  )
  
  local output = vim.fn.system(full_cmd)
  local exit_code = vim.v.shell_error
  
  -- Clean up temp file
  os.remove(temp_file)
  
  if exit_code ~= 0 then
    logger.error('Draft save failed', {
      exit_code = exit_code,
      output = output,
      cmd = full_cmd
    })
    return nil, 'Failed to save draft: ' .. output
  end
  
  logger.debug('Draft save output', { output = output })
  
  -- Extract draft ID from output if possible
  local draft_id = output:match('Message saved with ID: (%S+)') or 
                   output:match('id: (%S+)') or
                   'draft_' .. os.time()
  
  return { id = draft_id }
end

-- Delete email (for draft cleanup)
function M.delete_email(account, folder, email_id)
  local cmd = string.format(
    '%s -a %s message delete -f %s %s',
    config.config.binaries.himalaya or 'himalaya',
    vim.fn.shellescape(account),
    vim.fn.shellescape(folder),
    vim.fn.shellescape(email_id)
  )
  
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    error('Failed to delete email: ' .. output)
  end
  
  return true
end

-- Map logical folder names to maildir paths
local function get_maildir_folder_path(account, folder)
  -- Special mappings for Gmail
  if account == 'gmail' then
    -- INBOX is at the root
    if folder:upper() == 'INBOX' then
      return ''  -- Empty string means root of maildir
    end
    
    -- Some folders have dots in front
    local dotted_folders = {
      ['Sent'] = '.Sent',
      ['Drafts'] = '.Drafts',
      ['Spam'] = '.Spam',
      ['All_Mail'] = '.All_Mail',
      ['Starred'] = '.Starred',
      ['Important'] = '.Important'
    }
    
    return dotted_folders[folder] or folder
  end
  
  -- Default: use folder name as-is
  return folder
end

-- Fetch actual email count from himalaya
-- This is the unified count function that should be used everywhere
function M.fetch_folder_count(account, folder)
  folder = folder or 'INBOX'
  
  -- For small folders, just get the exact count quickly
  local args = { 'envelope', 'list' }
  table.insert(args, '--page')
  table.insert(args, '1')
  table.insert(args, '--page-size')
  table.insert(args, '1000')
  table.insert(args, 'order by date desc')
  
  local result = M.execute_himalaya(args, { account = account, folder = folder })
  if not result then
    return 0
  end
  
  -- If we got less than 1000, that's the exact count
  if type(result) == 'table' and #result < 1000 then
    return #result
  end
  
  -- For larger folders, use binary search
  local page_size = 100
  local low = 1
  local high = 50  -- Start with assumption of max 5000 emails
  local last_valid_page = 1
  local last_page_count = 0
  
  -- First, find a page that's out of bounds
  args = { 'envelope', 'list' }
  table.insert(args, '--page')
  table.insert(args, tostring(high))
  table.insert(args, '--page-size') 
  table.insert(args, tostring(page_size))
  table.insert(args, 'order by date desc')
  
  result = M.execute_himalaya(args, { account = account, folder = folder })
  if result and type(result) == 'table' and #result > 0 then
    -- Need to search higher
    high = 100
  end
  
  -- Binary search for the last valid page
  while low <= high do
    local mid = math.floor((low + high) / 2)
    
    args = { 'envelope', 'list' }
    table.insert(args, '--page')
    table.insert(args, tostring(mid))
    table.insert(args, '--page-size')
    table.insert(args, tostring(page_size))
    table.insert(args, 'order by date desc')
    
    -- Suppress error output for out of bounds pages
    local save_notify = vim.notify
    vim.notify = function() end
    result = M.execute_himalaya(args, { account = account, folder = folder })
    vim.notify = save_notify
    
    if result and type(result) == 'table' and #result > 0 then
      -- This page has emails
      last_valid_page = mid
      last_page_count = #result
      
      -- If this page is not full, it's the last page
      if #result < page_size then
        break
      end
      
      low = mid + 1
    else
      -- This page is invalid/empty, search lower
      high = mid - 1
    end
  end
  
  -- Calculate total count
  local total = (last_valid_page - 1) * page_size + last_page_count
  
  -- Log final count
  logger.debug(string.format('Count for %s: %d emails (pages: %d, last page: %d emails)', 
    folder, total, last_valid_page, last_page_count))
  
  return total
end

-- DEPRECATED: Use M.send_email(account, email_data) defined above
-- This function is kept for backward compatibility only
function M.send_email_raw(email_data, account)
  error("send_email_raw is deprecated. Use M.send_email(account, email_data) instead")
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
  -- Get current folder BEFORE building the command
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local folder = state.get_current_folder()
  
  -- If no folder, default to INBOX
  if not folder or folder == '' then
    folder = 'INBOX'
  end
  
  -- Build command with proper order: himalaya message delete <ID> [OPTIONS]
  local cmd = { config.config.binaries.himalaya or 'himalaya' }
  
  -- Add the subcommand first
  table.insert(cmd, 'message')
  table.insert(cmd, 'delete')
  table.insert(cmd, tostring(email_id))
  
  -- Add options after the command
  if account then
    table.insert(cmd, '-a')
    table.insert(cmd, account)
  end
  
  -- Add folder
  table.insert(cmd, '-f')
  table.insert(cmd, folder)
  
  -- Add output format
  table.insert(cmd, '-o')
  table.insert(cmd, 'json')
  
  -- Debug: show the exact command
  notify.himalaya('Delete command: ' .. table.concat(cmd, ' '), notify.categories.BACKGROUND)
  
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  -- Debug: log the deletion attempt if it fails
  if exit_code ~= 0 then
    notify.himalaya('Delete failed: ' .. (result or 'no error message'), notify.categories.ERROR)
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
  local state = require('neotex.plugins.tools.himalaya.core.state')
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