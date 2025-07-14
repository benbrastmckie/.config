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
local id_validator = require('neotex.plugins.tools.himalaya.core.id_validator')

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

-- Format email flags
function M.format_flags(flags)
  if not flags then return '  ' end
  
  local flag_chars = ''
  if flags.seen then flag_chars = flag_chars .. 'R' else flag_chars = flag_chars .. ' ' end
  if flags.answered then flag_chars = flag_chars .. 'A' else flag_chars = flag_chars .. ' ' end
  if flags.flagged then flag_chars = flag_chars .. '*' else flag_chars = flag_chars .. ' ' end
  if flags.draft then flag_chars = flag_chars .. 'D' else flag_chars = flag_chars .. ' ' end
  
  return flag_chars
end

-- Format date for display
function M.format_date(date)
  if not date then return 'Unknown' end
  
  -- If date is already a string, return it
  if type(date) == 'string' then
    -- Try to parse common date formats
    local month, day = date:match('(%a+) (%d+)')
    if month and day then
      return month:sub(1, 3) .. ' ' .. string.format('%2s', day)
    end
    return date:sub(1, 10)
  end
  
  -- If date is a timestamp
  if type(date) == 'number' then
    return os.date('%b %d', date)
  end
  
  return 'Unknown'
end

-- Format from field
function M.format_from(from)
  if not from then return 'Unknown' end
  
  -- Extract name or email
  local name = from:match('^"?([^"<]+)"?%s*<') or from:match('^([^@]+)@') or from
  
  -- Clean up and truncate
  name = name:gsub('^%s+', ''):gsub('%s+$', '')
  return M.truncate_string(name, 20)
end

-- Format file size
function M.format_size(size)
  if not size or size == 0 then return '0B' end
  
  local units = {'B', 'KB', 'MB', 'GB'}
  local unit_index = 1
  local formatted_size = tonumber(size) or 0
  
  while formatted_size >= 1024 and unit_index < #units do
    formatted_size = formatted_size / 1024
    unit_index = unit_index + 1
  end
  
  if unit_index == 1 then
    return string.format('%d%s', formatted_size, units[unit_index])
  else
    return string.format('%.1f%s', formatted_size, units[unit_index])
  end
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
  
  -- Use flock to prevent concurrent Himalaya CLI access to ID mapper database
  local cmd = {
    'flock',
    '-w', '30',  -- Wait up to 30 seconds for lock
    '-x',        -- Exclusive lock
    '/tmp/himalaya-cli-global.lock',
    executable
  }
  
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
  
  -- Validate command arguments to prevent folder names as IDs
  local valid, error_msg = id_validator.validate_command_args(args[2], args)
  if not valid then
    logger.error('Command validation failed', {
      command = args[2],
      args = args,
      error = error_msg
    })
    notify.himalaya(error_msg, notify.categories.ERROR)
    return nil
  end
  
  -- Additional validation for message commands with IDs
  if args[1] == 'message' and (args[2] == 'read' or args[2] == 'delete') and args[3] then
    local id_arg = args[3]
    
    -- Skip himalaya for local draft IDs
    if id_arg and id_arg:match('^draft_') then
      logger.info('Skipping himalaya for local draft ID', { id = id_arg })
      return nil, 'Local draft operation'
    end
    
    if id_arg and not id_validator.is_valid_id(id_arg) then
      logger.error('Invalid ID for message command', {
        id_arg = id_arg,
        command = 'message ' .. args[2],
        is_folder_name = id_validator.is_folder_name(id_arg)
      })
      notify.himalaya('Invalid email ID: ' .. tostring(id_arg), notify.categories.ERROR)
      return nil
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
  -- Special case: for draft reading, use plain format as JSON seems broken
  if args[1] == 'message' and args[2] == 'read' and opts.folder and 
     (opts.folder == 'Drafts' or opts.folder:match('[Dd]raft')) then
    table.insert(cmd, '-o')
    table.insert(cmd, 'plain')
  else
    table.insert(cmd, '-o')
    table.insert(cmd, 'json')
  end
  
  -- Debug: Log the full command for message read
  if args[1] == 'message' and args[2] == 'read' then
    logger.debug('Full himalaya command', {
      cmd = table.concat(cmd, ' '),
      args = args,
      opts = opts
    })
  end
  
  -- Add query last if present
  if query then
    table.insert(cmd, query)
  end
  
  -- Debug log for envelope list commands
  if args[1] == 'envelope' and args[2] == 'list' then
    logger.debug('Himalaya envelope list command', {
      full_cmd = table.concat(cmd, ' '),
      has_query = query ~= nil,
      query = query,
      folder = opts.folder
    })
  end
  
  -- Execute command
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  -- Debug logging for move commands and read commands
  if args[1] == 'message' and (args[2] == 'move' or args[2] == 'read') then
    logger.debug(args[2] .. ' command: ' .. table.concat(cmd, ' '))
    logger.debug(args[2] .. ' result: ' .. (result or 'nil'))
    logger.debug(args[2] .. ' exit code: ' .. exit_code)
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
    -- Check for ID mapper database lock conflicts
    if result and (result:match('cannot open id mapper database') or 
                   result:match('could not acquire lock') or 
                   result:match('Resource temporarily unavailable')) then
      logger.warn('ID mapper lock conflict in synchronous command')
      -- Don't show error notification for lock conflicts, they're transient
      return nil
    end
    
    -- Special error logging for invalid ID issues
    if result and result:match("invalid value '([^']+)'") then
      local invalid_id = result:match("invalid value '([^']+)'")
      logger.error('Invalid ID passed to himalaya', {
        invalid_id = invalid_id,
        is_folder_name = id_validator.is_folder_name(invalid_id),
        command = table.concat(cmd, ' '),
        args = args,
        opts = opts,
        result = result
      })
    end
    
    notify.himalaya('Himalaya command failed: ' .. (result or 'unknown error'), notify.categories.ERROR)
    return nil
  end
  
  -- For some commands (like move), success is indicated by exit code 0 even without JSON output
  if args[1] == 'message' and (args[2] == 'move' or args[2] == 'delete') then
    -- These commands may not return JSON, just check exit code
    return exit_code == 0
  end
  
  -- Special handling for draft reads in plain format
  if args[1] == 'message' and args[2] == 'read' and opts.folder and 
     (opts.folder == 'Drafts' or opts.folder:match('[Dd]raft')) then
    -- Return plain text result for drafts
    return result
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
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account_config = config.get_account(account)
  local folders = {}
  local folder_set = {}  -- To avoid duplicates
  
  -- Always include INBOX as first folder (it's the special default folder)
  table.insert(folders, 'INBOX')
  folder_set['INBOX'] = true
  
  -- First, add all configured folders from config
  if account_config and account_config.folder_map then
    for _, local_name in pairs(account_config.folder_map) do
      if not folder_set[local_name] then
        table.insert(folders, local_name)
        folder_set[local_name] = true
      end
    end
  end
  
  -- Then check what folders actually exist via himalaya
  local args = { 'folder', 'list' }
  local result = M.execute_himalaya(args, { account = account })
  
  if result and type(result) == 'table' then
    -- Extract folder names from result
    for _, folder_data in ipairs(result) do
      local folder_name = nil
      if type(folder_data) == 'string' then
        folder_name = folder_data
      elseif type(folder_data) == 'table' and folder_data.name then
        folder_name = folder_data.name
      end
      
      -- Add folder if we haven't seen it yet
      if folder_name and not folder_set[folder_name] then
        table.insert(folders, folder_name)
        folder_set[folder_name] = true
      end
    end
  end
  
  -- Sort folders with INBOX first
  table.sort(folders, function(a, b)
    if a == 'INBOX' then return true end
    if b == 'INBOX' then return false end
    return a < b
  end)
  
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
  
  -- Debug logging for Drafts folder
  if folder == 'Drafts' or folder:lower():match('draft') then
    logger.debug('Drafts folder email list result', {
      folder = folder,
      result_type = type(result),
      result_count = type(result) == 'table' and #result or 0,
      first_email = type(result) == 'table' and result[1] or nil
    })
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
  
  -- Save copy to Sent folder
  local sent_folder = M.find_sent_folder(account)
  if sent_folder then
    -- Save the sent email to the Sent folder
    local save_ok, save_err = pcall(M.save_draft, account, sent_folder, email_data)
    if not save_ok then
      local logger = require('neotex.plugins.tools.himalaya.core.logger')
      logger.warn('Failed to save copy to Sent folder', {
        error = save_err,
        folder = sent_folder
      })
    end
  end
  
  -- Trigger refresh after successful send
  vim.defer_fn(function()
    vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailSent' })
  end, 100)
  
  return true
end


-- Get email by ID
function M.get_email_by_id(account, folder, email_id)
  -- Check if this is a local draft ID
  if email_id and tostring(email_id):match('^draft_%d+_') then
    logger.info('Loading local draft from Maildir', { id = email_id })
    local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2_maildir')
    local draft_data, err = draft_manager.load(tostring(email_id), account)
    if draft_data and draft_data.content then
      -- Parse the content to extract headers and body
      local lines = vim.split(draft_data.content, '\n')
      local email = {
        id = email_id,
        subject = draft_data.metadata and draft_data.metadata.subject or '',
        from = draft_data.metadata and draft_data.metadata.from or '',
        to = draft_data.metadata and draft_data.metadata.to or '',
        body = draft_data.content
      }
      return email
    else
      return nil, err or 'Local draft not found'
    end
  end
  
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
  
  -- Debug log for drafts
  if folder and (folder == 'Drafts' or folder:match('[Dd]raft')) then
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    logger.debug('Draft raw output from himalaya', {
      email_id = email_id,
      output_length = #output,
      output_preview = output:sub(1, 200),
      output_lines = #vim.split(output, '\n')
    })
  end
  
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
  
  -- WORKAROUND: If this is a draft and we only got headers, try to read from maildir directly
  if folder and (folder == 'Drafts' or folder:match('[Dd]raft')) and 
     (not email.body or email.body == '' or email.body == '\n' or email.body:match('^%s*$')) then
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    logger.debug('Draft has empty body, attempting maildir read workaround', {
      email_id = email_id,
      folder = folder,
      body = email.body,
      body_length = email.body and #email.body or 0,
      parsed_headers = {
        from = email.from,
        to = email.to,
        subject = email.subject
      }
    })
    
    -- Try to find and read the draft file directly from maildir
    local maildir_email = M.read_draft_from_maildir(account, email_id)
    if maildir_email then
      -- Merge the maildir content with what we got from himalaya
      for k, v in pairs(maildir_email) do
        if k ~= 'id' then  -- Don't override the ID
          email[k] = v
        end
      end
      logger.debug('Successfully read draft from maildir', {
        has_body = email.body ~= nil and email.body ~= '',
        body_length = email.body and #email.body or 0
      })
    end
  end
  
  return email
end

-- Read draft directly from maildir (workaround for himalaya bug)
function M.read_draft_from_maildir(account, email_id)
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  
  -- Get maildir path
  local maildir_path = config.get_maildir_path(account)
  if not maildir_path then
    logger.debug('No maildir path configured for account', { account = account })
    return nil
  end
  
  -- Look for the draft file in maildir
  local draft_folder_path = maildir_path .. '.Drafts/cur'
  if vim.fn.isdirectory(draft_folder_path) == 0 then
    -- Try without dot prefix
    draft_folder_path = maildir_path .. 'Drafts/cur'
    if vim.fn.isdirectory(draft_folder_path) == 0 then
      logger.debug('Draft folder not found in maildir', { 
        tried = { maildir_path .. '.Drafts/cur', maildir_path .. 'Drafts/cur' }
      })
      return nil
    end
  end
  
  -- Find the most recent draft file (since we don't have the exact filename)
  -- This is a heuristic - in production you'd want to map IDs to filenames
  local cmd = string.format('ls -t %s 2>/dev/null | head -20', vim.fn.shellescape(draft_folder_path))
  local files = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 or not files or files == '' then
    logger.debug('No draft files found in maildir', { 
      folder = draft_folder_path,
      cmd = cmd,
      error = vim.v.shell_error
    })
    return nil
  end
  
  logger.debug('Found draft files in maildir', {
    folder = draft_folder_path,
    file_count = #vim.split(files, '\n'),
    first_files = vim.split(files, '\n')[1]
  })
  
  -- Try to read the most recent files until we find one that matches
  local file_list = vim.split(files, '\n', { plain = true })
  for _, filename in ipairs(file_list) do
    if filename and filename ~= '' then
      local filepath = draft_folder_path .. '/' .. filename
      local content = vim.fn.readfile(filepath)
      if content and #content > 0 then
        -- Parse the email content
        local email = M.parse_email_content(content)
        
        -- If we have content, return it
        if email and (email.body and email.body ~= '') then
          logger.debug('Found draft in maildir', { 
            file = filename,
            has_body = true,
            subject = email.subject
          })
          return email
        end
      end
    end
  end
  
  logger.debug('No matching draft found in maildir')
  return nil
end

-- Find draft folder for account
function M.find_draft_folder(account)
  local account_config = config.get_account(account)
  if not account_config then
    return nil
  end
  
  -- Check folder map for draft folder (look for local folder name)
  if account_config.folder_map then
    for imap, local_folder in pairs(account_config.folder_map) do
      if imap:lower():match('draft') then
        -- Return the local folder name (what himalaya CLI expects)
        return local_folder
      end
    end
  end
  
  -- For most setups, 'Drafts' is the correct folder name
  -- This was confirmed to work with: himalaya message save --account gmail --folder "Drafts"
  return 'Drafts'
end

-- Find sent folder for account
function M.find_sent_folder(account)
  local account_config = config.get_account(account)
  if not account_config then
    return nil
  end
  
  -- Check folder map for sent folder (look for local folder name)
  if account_config.folder_map then
    for imap, local_folder in pairs(account_config.folder_map) do
      if imap:lower():match('sent') then
        -- Return the local folder name (what himalaya CLI expects)
        return local_folder
      end
    end
  end
  
  -- Common sent folder names
  local common_sent_folders = { 'Sent', 'Sent Mail', 'Sent Messages', 'SENT' }
  
  -- Try to find one that exists
  local folders = M.get_folders(account)
  if folders then
    for _, folder_name in ipairs(common_sent_folders) do
      for _, folder in ipairs(folders) do
        if folder == folder_name then
          return folder_name
        end
      end
    end
  end
  
  -- Default to 'Sent' - most common
  return 'Sent'
end

-- Save draft to maildir
function M.save_draft(account, folder, email_data)
  -- Build himalaya command with correct CLI syntax
  local cmd_parts = {
    config.config.binaries.himalaya or 'himalaya',
    'message', 'save',
    '--account', account,
    '--folder', folder,
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
    subject = email_data.subject,
    has_body = email_data.body ~= nil and email_data.body ~= '',
    body_length = email_data.body and #email_data.body or 0,
    body_preview = email_data.body and email_data.body:sub(1, 100) or 'no body',
    full_content_preview = content and content:sub(1, 200) or 'no content'
  })
  
  -- Write content to temporary file instead of using echo
  local temp_file = vim.fn.tempname()
  local file = io.open(temp_file, 'wb')  -- Use binary mode to preserve line endings
  if not file then
    logger.error('Failed to create temp file for draft')
    return nil, 'Failed to create temporary file'
  end
  file:write(content)
  file:close()
  
  -- Debug: log the content being saved
  logger.debug('Saving draft content to temp file', {
    temp_file = temp_file,
    content_length = #content,
    first_200_chars = content:sub(1, 200),
    has_crlf = content:find('\r\n') ~= nil
  })
  
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
  
  -- If we got a success message, the draft was saved successfully
  if output:match('Message successfully saved') then
    -- Since himalaya doesn't return the draft ID, we need to find it
    -- by listing drafts and finding the most recent one
    logger.debug('Draft successfully saved, fetching draft ID')
    
    -- Wait a moment to ensure the draft is indexed
    vim.wait(100)
    
    -- Get the most recent draft to find its ID
    local list_args = { 'envelope', 'list', '--page', '1', '--page-size', '10', 'order by date desc' }
    local list_result = M.execute_himalaya(list_args, { account = account, folder = folder })
    
    if list_result and type(list_result) == 'table' and #list_result > 0 then
      -- Find the draft that matches our subject
      local draft_id = nil
      local matched_draft = nil
      
      -- First, try to find exact subject match
      for i, draft in ipairs(list_result) do
        if draft.id and draft.id ~= '' and draft.id ~= 'Drafts' and
           draft.subject == email_data.subject then
          draft_id = draft.id
          matched_draft = draft
          logger.info('Found draft by exact subject match', { 
            index = i,
            draft_id = draft_id,
            subject = draft.subject
          })
          break
        end
      end
      
      -- If no exact match, take the most recent valid draft
      if not draft_id then
        for i, draft in ipairs(list_result) do
          if draft.id and draft.id ~= '' and draft.id ~= 'Drafts' then
            draft_id = draft.id
            matched_draft = draft
            logger.info('Using most recent draft (no exact match)', { 
              index = i,
              draft_id = draft_id,
              subject = draft.subject,
              expected_subject = email_data.subject
            })
            break
          end
        end
      end
      
      if draft_id then
        logger.info('Found draft ID from listing', { 
          draft_id = draft_id,
          draft_subject = matched_draft and matched_draft.subject,
          email_subject = email_data.subject,
          all_drafts = list_result
        })
        -- Only show notification if this is actually a draft folder
        if folder and (folder == 'Drafts' or folder:match('[Dd]raft')) then
          local notify = require('neotex.util.notifications')
          notify.himalaya(string.format('Draft saved with ID: %s, Subject: %s', 
            tostring(draft_id), tostring(email_data.subject or '(No subject)')), notify.categories.INFO)
        end
        return { id = draft_id }
      else
        logger.error('No valid draft ID found in listing', {
          list_result = list_result
        })
        return nil, 'Could not find draft ID after save'
      end
    else
      -- Fallback: generate a temporary ID
      local temp_id = 'draft_' .. os.time()
      logger.warn('Could not find draft ID, using temporary', { 
        temp_id = temp_id,
        list_result = list_result,
        list_result_type = type(list_result)
      })
      return { id = temp_id }
    end
  else
    logger.error('Unexpected save output format', { output = output })
    return nil, 'Unexpected output: ' .. output
  end
end

-- Delete email (for draft cleanup)
function M.delete_email(account, folder, email_id)
  -- Validate email_id
  if not email_id or email_id == '' then
    logger.error('Invalid email_id for delete', { email_id = email_id })
    error('Invalid email ID')
  end
  
  -- Use execute_himalaya for consistent command construction and validation
  local args = { 'message', 'delete', tostring(email_id) }
  local opts = { account = account, folder = folder }
  
  local output = M.execute_himalaya(args, opts)
  if not output then
    error('Failed to delete email')
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


-- Format email data for sending
function M.format_email_for_sending(email_data)
  local lines = {}
  
  -- Always include From header (required)
  if email_data.from and email_data.from ~= '' then
    table.insert(lines, 'From: ' .. email_data.from)
  else
    -- This should not happen, but add a placeholder if needed
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    logger.warn('Missing From address in draft')
    table.insert(lines, 'From: ')
  end
  
  -- Always include To header (even if empty)
  table.insert(lines, 'To: ' .. (email_data.to or ''))
  
  -- Optional headers
  if email_data.cc and email_data.cc ~= '' then
    table.insert(lines, 'Cc: ' .. email_data.cc)
  end
  if email_data.bcc and email_data.bcc ~= '' then
    table.insert(lines, 'Bcc: ' .. email_data.bcc)
  end
  
  -- Always include Subject (even if empty)
  local subject = email_data.subject or ''
  -- Don't add "(No subject)" as part of the actual email header
  -- This is just for display purposes
  table.insert(lines, 'Subject: ' .. subject)
  
  -- Add Date header (required for proper email format)
  table.insert(lines, 'Date: ' .. os.date('!%a, %d %b %Y %H:%M:%S +0000'))
  
  -- Add Message-ID header for RFC compliance
  local hostname = vim.fn.hostname() or 'localhost'
  local timestamp = os.time()
  local random = math.random(10000, 99999)
  table.insert(lines, 'Message-ID: <' .. timestamp .. '.' .. random .. '@' .. hostname .. '>')
  
  -- Add MIME headers for plain text
  table.insert(lines, 'MIME-Version: 1.0')
  table.insert(lines, 'Content-Type: text/plain; charset=UTF-8')
  table.insert(lines, 'Content-Transfer-Encoding: 8bit')
  
  -- Empty line between headers and body
  table.insert(lines, '')
  
  -- Body
  if email_data.body and email_data.body ~= '' then
    table.insert(lines, email_data.body)
  else
    -- Always add at least a space for the body to ensure proper format
    table.insert(lines, ' ')
  end
  
  -- Debug what we're formatting
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  logger.debug('format_email_for_sending', {
    has_body = email_data.body ~= nil and email_data.body ~= '',
    body_length = email_data.body and #email_data.body or 0,
    body_preview = email_data.body and email_data.body:sub(1, 100) or 'no body',
    total_lines = #lines,
    formatted_preview = table.concat(lines, '\n'):sub(1, 300)
  })
  
  -- Use CRLF line endings for RFC compliance as required by himalaya
  return table.concat(lines, '\r\n')
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
  -- Check if this is a local draft ID
  if email_id and tostring(email_id):match('^draft_') then
    logger.info('Cannot use smart_delete_email for local draft', { id = email_id })
    return false, 'local_draft', 'Use local draft deletion instead'
  end
  
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

-- Import enhanced utilities
-- TODO: REMOVE BACKWARDS COMPATIBILITY - Import enhanced utilities directly instead of optional merge
local ok, enhanced = pcall(require, 'neotex.plugins.tools.himalaya.utils.enhanced')
if ok then
  -- Merge enhanced utilities into main module
  for category, utils in pairs(enhanced) do
    if type(utils) == "table" and category ~= "validate" then
      M[category] = utils
    end
  end
  
  -- Add validate as top-level
  M.validate = enhanced.validate
end

-- ==============================================
-- ASYNC COMMAND IMPLEMENTATION (Phase 1)
-- ==============================================

-- Core async command executor
function M.execute_himalaya_async(args, opts, callback)
  local async_commands = require('neotex.plugins.tools.himalaya.core.async_commands')
  return async_commands.execute_async(args, opts, callback)
end

-- Async email operations
function M.get_emails_async(account, folder, page, page_size, callback)
  local args = { 'envelope', 'list' }
  table.insert(args, '--page')
  table.insert(args, tostring(page))
  table.insert(args, '--page-size')
  table.insert(args, tostring(page_size))
  -- Add the query as a single string that will be recognized by build_command
  table.insert(args, 'order by date desc')
  
  M.execute_himalaya_async(args, { 
    account = account, 
    folder = folder,
    priority = M.async_commands and M.async_commands.priorities.ui or 2
  }, function(result, error)
    if error then
      callback({}, 0, error)
      return
    end
    
    if not result then
      callback({}, 0, nil)
      return
    end
    
    -- Get stored count from state (from sync operations)
    local state = require('neotex.plugins.tools.himalaya.core.state')
    local stored_count = state.get_folder_count(account, folder)
    
    -- If we have a stored count, use it
    if stored_count and stored_count > 0 then
      callback(result, stored_count, nil)
      return
    end
    
    -- Otherwise, estimate based on the page results
    local estimated_count = #result
    if #result >= page_size then
      estimated_count = page * page_size
    end
    
    callback(result, estimated_count, nil)
  end)
end

-- Async email reading
function M.get_email_by_id_async(account, folder, email_id, callback)
  local args = { 'message', 'read', tostring(email_id) }
  local opts = { 
    account = account,
    priority = 1  -- user priority
  }
  if folder then
    opts.folder = folder
  end
  
  M.execute_himalaya_async(args, opts, callback)
end

-- Async folder operations
function M.get_folders_async(account, callback)
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account_config = config.get_account(account)
  local folders = {}
  local folder_set = {}  -- To avoid duplicates
  
  -- Always include INBOX as first folder
  table.insert(folders, 'INBOX')
  folder_set['INBOX'] = true
  
  -- First, add all configured folders from config
  if account_config and account_config.folder_map then
    for _, local_name in pairs(account_config.folder_map) do
      if not folder_set[local_name] then
        table.insert(folders, local_name)
        folder_set[local_name] = true
      end
    end
  end
  
  -- Then check what folders actually exist via himalaya
  local args = { 'folder', 'list' }
  M.execute_himalaya_async(args, { 
    account = account,
    priority = M.async_commands and M.async_commands.priorities.ui or 2
  }, function(result, error)
    if error then
      -- Return configured folders even if himalaya fails
      table.sort(folders, function(a, b)
        if a == 'INBOX' then return true end
        if b == 'INBOX' then return false end
        return a < b
      end)
      callback(folders, nil)
      return
    end
    
    if result and type(result) == 'table' then
      for _, folder_data in ipairs(result) do
        local folder_name = nil
        if type(folder_data) == 'string' then
          folder_name = folder_data
        elseif type(folder_data) == 'table' and folder_data.name then
          folder_name = folder_data.name
        end
        
        -- Add folder if we haven't seen it yet
        if folder_name and not folder_set[folder_name] then
          table.insert(folders, folder_name)
          folder_set[folder_name] = true
        end
      end
    end
    
    -- Sort folders with INBOX first
    table.sort(folders, function(a, b)
      if a == 'INBOX' then return true end
      if b == 'INBOX' then return false end
      return a < b
    end)
    
    callback(folders, nil)
  end)
end

-- Async count operations
function M.fetch_folder_count_async(account, folder, callback)
  -- Try quick method first - get first page with large page size
  local args = { 'envelope', 'list' }
  table.insert(args, '--page')
  table.insert(args, '1')
  table.insert(args, '--page-size')
  table.insert(args, '1000')
  table.insert(args, 'order by date desc')
  
  M.execute_himalaya_async(args, { 
    account = account, 
    folder = folder,
    priority = 3  -- background priority
  }, function(result, error)
    if error then
      callback(0, error)
      return
    end
    
    if not result then
      callback(0, nil)
      return
    end
    
    -- If we got less than 1000, that's the exact count
    if type(result) == 'table' and #result < 1000 then
      callback(#result, nil)
      return
    end
    
    -- For larger folders, we need to do binary search
    -- This will be implemented in a follow-up if needed
    -- For now, return the estimate
    callback(1000, nil)
  end)
end

-- Async delete operations
function M.delete_email_async(account, folder, email_id, callback)
  local args = { 'message', 'delete', tostring(email_id) }
  local opts = { 
    account = account,
    priority = 1  -- user priority
  }
  if folder then
    opts.folder = folder
  end
  
  M.execute_himalaya_async(args, opts, function(result, error)
    if not error and result then
      -- Clear cache after successful deletion
      M.clear_email_cache()
      
      -- Trigger refresh after deletion
      vim.defer_fn(function()
        vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailDeleted' })
      end, 100)
    end
    
    callback(result ~= nil, error)
  end)
end

-- Async move operations
function M.move_email_async(account, folder, email_id, target_folder, callback)
  local args = { 'message', 'move', target_folder, tostring(email_id) }
  
  M.execute_himalaya_async(args, { 
    account = account,
    folder = folder,
    priority = 1  -- user priority
  }, function(result, error)
    if not error and result then
      local notify = require('neotex.util.notifications')
      notify.himalaya('Email moved', notify.categories.USER_ACTION, { folder = target_folder })
      
      -- Clear cache after move
      M.clear_email_cache(account, folder)
      M.clear_email_cache(account, target_folder)
      
      -- Trigger refresh after successful move
      vim.defer_fn(function()
        vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailMoved' })
      end, 100)
    end
    
    callback(result ~= nil, error)
  end)
end

-- Initialize async commands reference
M.async_commands = nil
vim.defer_fn(function()
  local ok, async_commands = pcall(require, 'neotex.plugins.tools.himalaya.core.async_commands')
  if ok then
    M.async_commands = async_commands
  end
end, 100)

return M