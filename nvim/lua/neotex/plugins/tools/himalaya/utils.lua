-- Himalaya Email Client Utilities
-- Utility functions for CLI integration and email operations

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')

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
    vim.notify('Himalaya command failed: ' .. result, vim.log.levels.ERROR)
    return nil
  end
  
  -- Parse JSON output
  local success, data = pcall(vim.json.decode, result)
  if not success then
    vim.notify('Failed to parse Himalaya output', vim.log.levels.ERROR)
    return nil
  end
  
  return data
end

-- Get email list for account and folder
function M.get_email_list(account, folder, page)
  folder = folder or 'INBOX'
  page = page or 1
  
  local args = { 'envelope', 'list' }
  if page > 1 then
    table.insert(args, '--page')
    table.insert(args, tostring(page))
  end
  
  local result = M.execute_himalaya(args, { account = account, folder = folder })
  
  -- If we get an error, try to provide helpful information
  if not result then
    -- Try to diagnose the issue
    local account_test = M.execute_himalaya({ 'account', 'list' })
    if not account_test then
      vim.notify('Himalaya: Account configuration issue. Try running: himalaya account configure', vim.log.levels.ERROR)
    else
      vim.notify('Himalaya: Cannot access maildir. Check your mail sync status.', vim.log.levels.ERROR)
      vim.notify('Try running: mbsync -a', vim.log.levels.INFO)
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
    vim.notify('Failed to create temporary file', vim.log.levels.ERROR)
    return false
  end
  
  file:write(content)
  file:close()
  
  -- Send email using himalaya
  local args = { 'message', 'send', '--stdin' }
  local cmd = { config.config.executable }
  
  vim.list_extend(cmd, args)
  
  if account then
    table.insert(cmd, '-a')
    table.insert(cmd, account)
  end
  
  -- Execute with file input
  local result = vim.fn.system(table.concat(cmd, ' ') .. ' < ' .. temp_file)
  local exit_code = vim.v.shell_error
  
  -- Clean up temporary file
  os.remove(temp_file)
  
  if exit_code ~= 0 then
    vim.notify('Failed to send email: ' .. result, vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- Format email data for sending
function M.format_email_for_sending(email_data)
  local lines = {}
  
  -- Headers
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
      if header == 'to' then
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
  return result ~= nil
end

-- Move email to folder
function M.move_email(email_id, target_folder)
  local args = { 'message', 'move', tostring(email_id), target_folder }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    vim.notify(string.format('Email moved to %s', target_folder), vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to move email', vim.log.levels.ERROR)
    return false
  end
end

-- Copy email to folder
function M.copy_email(email_id, target_folder)
  local args = { 'message', 'copy', tostring(email_id), target_folder }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    vim.notify(string.format('Email copied to %s', target_folder), vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to copy email', vim.log.levels.ERROR)
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
    vim.notify(string.format('Flag %s %s', flag, action == 'add' and 'added' or 'removed'), vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to manage flag', vim.log.levels.ERROR)
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
    vim.notify(string.format('Attachment downloaded to %s', download_dir), vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to download attachment', vim.log.levels.ERROR)
    return false
  end
end

-- Sync mail using mbsync
function M.sync_mail(force)
  local cmd = { 'mbsync', '-a' }
  if force then
    table.insert(cmd, '--force')
  end
  
  vim.notify('Syncing mail...', vim.log.levels.INFO)
  
  -- Run sync in background
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify('Mail sync completed', vim.log.levels.INFO)
        -- Trigger sync complete event
        vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaSyncComplete' })
      else
        vim.notify('Mail sync failed', vim.log.levels.ERROR)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.notify('Sync error: ' .. table.concat(data, '\n'), vim.log.levels.WARN)
      end
    end,
  })
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
    vim.notify('Himalaya CLI not found. Please install it first.', vim.log.levels.ERROR)
    return false
  end
  
  -- Check if mbsync is available
  local mbsync_result = vim.fn.system('mbsync --version')
  if vim.v.shell_error ~= 0 then
    vim.notify('mbsync not found. Email sync will not work.', vim.log.levels.WARN)
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
  local args = { 'folder', 'expunge' }
  local result = M.execute_himalaya(args, { account = config.state.current_account })
  
  if result then
    vim.notify('Expunged deleted emails', vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to expunge emails', vim.log.levels.ERROR)
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
    vim.notify(string.format('%s tag: %s', action == 'add' and 'Added' or 'Removed', tag), vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to manage tag', vim.log.levels.ERROR)
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

return M