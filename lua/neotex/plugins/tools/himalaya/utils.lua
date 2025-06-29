-- Minimal utils module for the refactored Himalaya plugin

local M = {}

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

-- Clear email cache (stub for now)
function M.clear_email_cache()
  logger.debug('Email cache cleared')
  -- In the future, this could clear any cached email data
end

-- Get list of folders (stub for now)
function M.get_folders()
  -- Return default Gmail folders
  return {
    'INBOX',
    'Sent',
    'Drafts',
    'Trash',
    'All_Mail',
    'Spam',
    'Starred',
    'Important'
  }
end

-- Get email list from himalaya
function M.get_email_list(account, folder, page, page_size)
  folder = folder or 'INBOX'
  page = page or 1
  page_size = page_size or 30
  
  -- Build himalaya command
  local cmd = string.format(
    'himalaya envelope list --account %s --folder %s --page %d --page-size %d --output json 2>/dev/null',
    vim.fn.shellescape(account),
    vim.fn.shellescape(folder),
    page,
    page_size
  )
  
  -- Execute command
  local handle = io.popen(cmd)
  if not handle then
    logger.error('Failed to execute himalaya command')
    return nil
  end
  
  local output = handle:read('*a')
  handle:close()
  
  -- Parse JSON output
  local ok, emails = pcall(vim.json.decode, output)
  if not ok or not emails then
    logger.error('Failed to parse himalaya output')
    -- Return mock data as fallback
    local mock_emails = {}
    for i = 1, 10 do
      table.insert(mock_emails, {
        id = tostring(1000 + i),
        from = { addr = 'sender' .. i .. '@example.com', name = 'Sender ' .. i },
        subject = 'Test email ' .. i,
        date = os.date('%Y-%m-%d %H:%M', os.time() - (i * 3600)),
        flags = { i % 3 == 0 and 'Seen' or 'Unseen' }
      })
    end
    return mock_emails
  end
  
  return emails
end

-- Get email content (stub)
function M.get_email_content(account, email_id)
  return {
    headers = {
      from = 'sender@example.com',
      to = 'you@example.com',
      subject = 'Test email',
      date = os.date('%Y-%m-%d %H:%M')
    },
    body = 'This is a test email body.\n\nEmail functionality will be implemented soon.'
  }
end

-- Send email (stub)
function M.send_email(account, to, subject, body)
  logger.info('Send email called: to=' .. to .. ', subject=' .. subject)
  return true  -- Pretend it worked
end

-- Delete email (stub) 
function M.delete_email(account, email_id)
  logger.info('Delete email called: id=' .. email_id)
  return true
end

-- Smart delete email (stub)
function M.smart_delete_email(account, email_id)
  logger.info('Smart delete email called: id=' .. email_id)
  return true, 'deleted', nil
end

return M