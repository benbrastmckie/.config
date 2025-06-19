-- Himalaya Email Client UI
-- Buffer and window management for email interface

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Buffer tracking
M.buffers = {
  email_list = nil,
  email_read = nil,
  email_compose = nil,
}

-- Show email list
function M.show_email_list(args)
  args = args or {}
  
  -- Parse arguments
  local folder = args[1] or config.state.current_folder
  local account = nil
  for i, arg in ipairs(args) do
    if arg:match('^--account=') then
      account = arg:gsub('^--account=', '')
    end
  end
  
  -- Switch account if specified
  if account and not config.switch_account(account) then
    vim.notify('Unknown account: ' .. account, vim.log.levels.ERROR)
    return
  end
  
  -- Switch folder if different
  if folder ~= config.state.current_folder then
    config.switch_folder(folder)
  end
  
  -- Get email list
  local emails = utils.get_email_list(config.state.current_account, folder)
  if not emails then
    vim.notify('Failed to get email list', vim.log.levels.ERROR)
    return
  end
  
  -- Create or reuse buffer
  local buf = M.buffers.email_list
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    M.buffers.email_list = buf
  end
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-list')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Format email list content
  local lines = M.format_email_list(emails)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Store email data for reference
  vim.b[buf].himalaya_emails = emails
  vim.b[buf].himalaya_account = config.state.current_account
  vim.b[buf].himalaya_folder = folder
  
  -- Open in window
  M.open_email_window(buf, 'Email List - ' .. config.get_current_account().name .. ' - ' .. folder)
end

-- Format email list for display
function M.format_email_list(emails)
  local lines = {}
  
  -- Header
  local account = config.get_current_account()
  local header = string.format('Himalaya - %s - %s', account.email, config.state.current_folder)
  table.insert(lines, header)
  table.insert(lines, string.rep('─', #header))
  table.insert(lines, '')
  
  -- Email entries
  for _, email in ipairs(emails) do
    -- Parse flags (they're in an array)
    local seen = false
    if email.flags and type(email.flags) == 'table' then
      for _, flag in ipairs(email.flags) do
        if flag == 'Seen' then
          seen = true
          break
        end
      end
    end
    local status = seen and ' ' or '*'
    
    -- Parse from field (it's an object with name and addr)
    local from = 'Unknown'
    if email.from then
      if type(email.from) == 'table' then
        from = email.from.name or email.from.addr or 'Unknown'
      else
        from = tostring(email.from)
      end
    end
    
    local subject = email.subject or '(No subject)'
    local date = email.date or ''
    
    -- Truncate long fields
    from = utils.truncate_string(from, 25)
    subject = utils.truncate_string(subject, 50)
    
    local line = string.format('[%s] %s  %s  %s', status, from, subject, date)
    table.insert(lines, line)
  end
  
  -- Footer with keymaps
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  table.insert(lines, 'gm:folder ga:account gw:write gr:reply gf:forward gD:delete')
  
  return lines
end

-- Read specific email
function M.read_email(email_id)
  local email_content = utils.get_email_content(config.state.current_account, email_id)
  if not email_content then
    vim.notify('Failed to read email', vim.log.levels.ERROR)
    return
  end
  
  -- Create or reuse buffer
  local buf = M.buffers.email_read
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    M.buffers.email_read = buf
  end
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-email')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Format email content
  local lines, urls = M.format_email_content(email_content)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Store email data
  vim.b[buf].himalaya_email_id = email_id
  vim.b[buf].himalaya_email = email_content
  vim.b[buf].himalaya_urls = urls
  
  -- Open in window
  M.open_email_window(buf, 'Email - ' .. (email_content.subject or 'No Subject'))
end

-- Read current email from list
function M.read_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local emails = vim.b[buf].himalaya_emails
  if not emails then
    vim.notify('No emails available', vim.log.levels.WARN)
    return
  end
  
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  
  -- Find email index (accounting for header lines)
  local email_index = line_num - 3 -- Skip header lines
  if email_index <= 0 or email_index > #emails then
    vim.notify('No email selected', vim.log.levels.WARN)
    return
  end
  
  local email = emails[email_index]
  if email and email.id then
    M.read_email(email.id)
  end
end

-- Format email content for display
function M.format_email_content(email_content)
  local lines = {}
  local urls = {}  -- Track URLs for easy access
  
  -- Parse the raw email content if it's a string
  if type(email_content) == 'string' then
    local email_lines = vim.split(email_content, '\n')
    local in_headers = true
    local headers = {}
    local body_lines = {}
    
    for _, line in ipairs(email_lines) do
      if in_headers then
        if line == '' then
          in_headers = false
        elseif line:match('^[%w-]+:') then
          local header, value = line:match('^([%w-]+):%s*(.*)$')
          if header then
            headers[header:lower()] = value
          end
        end
      else
        table.insert(body_lines, line)
      end
    end
    
    -- Format headers
    table.insert(lines, 'From: ' .. (headers.from or 'Unknown'))
    table.insert(lines, 'To: ' .. (headers.to or 'Unknown'))
    if headers.cc then
      table.insert(lines, 'CC: ' .. headers.cc)
    end
    table.insert(lines, 'Subject: ' .. (headers.subject or '(No subject)'))
    table.insert(lines, 'Date: ' .. (headers.date or 'Unknown'))
    
    table.insert(lines, string.rep('─', 70))
    table.insert(lines, '')
    
    -- Process body and extract URLs
    local processed_body = M.process_email_body(body_lines, urls)
    vim.list_extend(lines, processed_body)
  else
    -- Fallback for structured data (shouldn't happen with current Himalaya)
    table.insert(lines, 'From: ' .. (email_content.from or 'Unknown'))
    table.insert(lines, 'To: ' .. (email_content.to or 'Unknown'))
    if email_content.cc then
      table.insert(lines, 'CC: ' .. email_content.cc)
    end
    table.insert(lines, 'Subject: ' .. (email_content.subject or '(No subject)'))
    table.insert(lines, 'Date: ' .. (email_content.date or 'Unknown'))
    
    table.insert(lines, string.rep('─', 70))
    table.insert(lines, '')
    
    -- Body
    if email_content.body then
      local body_lines = vim.split(email_content.body, '\n')
      local processed_body = M.process_email_body(body_lines, urls)
      vim.list_extend(lines, processed_body)
    end
  end
  
  -- Add URLs section if any were found
  if #urls > 0 then
    table.insert(lines, '')
    table.insert(lines, string.rep('─', 70))
    table.insert(lines, 'LINKS:')
    for i, url in ipairs(urls) do
      -- Truncate long URLs for display but keep them ctrl+clickable
      local display_url = utils.truncate_string(url, 60)
      table.insert(lines, string.format('[%d] %s', i, display_url))
    end
  end
  
  -- Footer
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  if #urls > 0 then
    table.insert(lines, 'gl:go-to-link gr:reply gR:reply-all gf:forward gD:delete q:back')
  else
    table.insert(lines, 'gr:reply gR:reply-all gf:forward gD:delete q:back')
  end
  
  return lines, urls
end

-- Process email body text and extract URLs
function M.process_email_body(body_lines, urls)
  local processed_lines = {}
  
  for _, line in ipairs(body_lines) do
    -- Extract URLs from angle brackets and replace with numbered references
    local processed_line = line:gsub('<(https?://[^>]+)>', function(url)
      table.insert(urls, url)
      return string.format('[%d]', #urls)
    end)
    
    -- Also extract bare URLs (not in angle brackets)
    processed_line = processed_line:gsub('(https?://[%S]+)', function(url)
      -- Don't double-process URLs that were already in angle brackets
      if not line:match('<' .. url:gsub('[%(%)%.%+%-%*%?%[%]%^%$%%]', '%%%1') .. '>') then
        table.insert(urls, url)
        return string.format('[%d]', #urls)
      end
      return url
    end)
    
    table.insert(processed_lines, processed_line)
  end
  
  return processed_lines
end

-- Compose new email
function M.compose_email(to_address)
  -- Create compose buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Email template
  local account = config.get_current_account()
  local lines = {
    'From: ' .. account.email,
    'To: ' .. (to_address or ''),
    'Subject: ',
    '',
    '',
    '',
    '--',
    account.name or account.email,
    '',
    string.rep('─', 70),
    'ZZ:send q:save-draft Q:discard',
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Store compose data
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = config.state.current_account
  
  -- Open in window
  M.open_email_window(buf, 'Compose Email')
  
  -- Position cursor on To: line if empty, otherwise Subject line
  if not to_address then
    vim.api.nvim_win_set_cursor(0, {2, #lines[2]})
  else
    vim.api.nvim_win_set_cursor(0, {3, #lines[3]})
  end
  
  -- Enter insert mode
  vim.cmd('startinsert!')
end

-- Reply to email
function M.reply_email(email_id, reply_all)
  local email_content = utils.get_email_content(config.state.current_account, email_id)
  if not email_content then
    vim.notify('Failed to get email for reply', vim.log.levels.ERROR)
    return
  end
  
  -- Create compose buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Reply template
  local account = config.get_current_account()
  local to_field = email_content.from or ''
  if reply_all and email_content.cc then
    to_field = to_field .. ', ' .. email_content.cc
  end
  
  local subject = email_content.subject or ''
  if not subject:match('^Re:') then
    subject = 'Re: ' .. subject
  end
  
  local lines = {
    'From: ' .. account.email,
    'To: ' .. to_field,
    'Subject: ' .. subject,
    '',
    '',
    '> ' .. (email_content.from or 'Unknown') .. ' wrote:',
  }
  
  -- Add quoted original content
  if email_content.body then
    local original_lines = vim.split(email_content.body, '\n')
    for _, line in ipairs(original_lines) do
      table.insert(lines, '> ' .. line)
    end
  end
  
  table.insert(lines, '')
  table.insert(lines, '--')
  table.insert(lines, account.name or account.email)
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  table.insert(lines, 'ZZ:send q:save-draft Q:discard')
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Store compose data
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = config.state.current_account
  vim.b[buf].himalaya_reply_to = email_id
  
  -- Open in window
  M.open_email_window(buf, 'Reply - ' .. subject)
  
  -- Position cursor before quoted content
  vim.api.nvim_win_set_cursor(0, {5, 0})
  vim.cmd('startinsert!')
end

-- Reply to current email
function M.reply_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    M.reply_email(email_id, false)
  else
    vim.notify('No email to reply to', vim.log.levels.WARN)
  end
end

-- Reply all to current email
function M.reply_all_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    M.reply_email(email_id, true)
  else
    vim.notify('No email to reply to', vim.log.levels.WARN)
  end
end

-- Forward email
function M.forward_email(email_id)
  local email_content = utils.get_email_content(config.state.current_account, email_id)
  if not email_content then
    vim.notify('Failed to get email for forwarding', vim.log.levels.ERROR)
    return
  end
  
  -- Create compose buffer similar to reply but with forward template
  local buf = vim.api.nvim_create_buf(false, true)
  
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  local account = config.get_current_account()
  local subject = email_content.subject or ''
  if not subject:match('^Fwd:') then
    subject = 'Fwd: ' .. subject
  end
  
  local lines = {
    'From: ' .. account.email,
    'To: ',
    'Subject: ' .. subject,
    '',
    '---------- Forwarded message ---------',
    'From: ' .. (email_content.from or 'Unknown'),
    'Date: ' .. (email_content.date or 'Unknown'),
    'Subject: ' .. (email_content.subject or '(No subject)'),
    'To: ' .. (email_content.to or 'Unknown'),
    '',
  }
  
  -- Add original content
  if email_content.body then
    local original_lines = vim.split(email_content.body, '\n')
    vim.list_extend(lines, original_lines)
  end
  
  table.insert(lines, '')
  table.insert(lines, '--')
  table.insert(lines, account.name or account.email)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = config.state.current_account
  vim.b[buf].himalaya_forward = email_id
  
  M.open_email_window(buf, 'Forward - ' .. subject)
  
  -- Position cursor on To: line
  vim.api.nvim_win_set_cursor(0, {2, #lines[2]})
  vim.cmd('startinsert!')
end

-- Forward current email
function M.forward_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    M.forward_email(email_id)
  else
    vim.notify('No email to forward', vim.log.levels.WARN)
  end
end

-- Send current email
function M.send_current_email()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.b[buf].himalaya_compose then
    vim.notify('Not in compose buffer', vim.log.levels.ERROR)
    return
  end
  
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local email_data = utils.parse_email_content(lines)
  
  if not email_data.to or email_data.to == '' then
    vim.notify('To field is required', vim.log.levels.ERROR)
    return
  end
  
  -- Send email
  local success = utils.send_email(config.state.current_account, email_data)
  if success then
    vim.notify('Email sent successfully', vim.log.levels.INFO)
    vim.api.nvim_buf_delete(buf, { force = true })
  else
    vim.notify('Failed to send email', vim.log.levels.ERROR)
  end
end

-- Delete email
function M.delete_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  
  if email_id then
    local success = utils.delete_email(config.state.current_account, email_id)
    if success then
      vim.notify('Email deleted', vim.log.levels.INFO)
      M.close_current_view()
      M.refresh_email_list()
    else
      vim.notify('Failed to delete email', vim.log.levels.ERROR)
    end
  else
    vim.notify('No email to delete', vim.log.levels.WARN)
  end
end

-- Open email window
function M.open_email_window(buf, title)
  local ui_config = config.config.ui.email_list
  
  -- Calculate window size
  local width = math.floor(vim.o.columns * ui_config.width)
  local height = math.floor(vim.o.lines * ui_config.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Open floating window
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
  
  -- Window options
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  return win
end

-- Refresh current email list
function M.refresh_email_list()
  local buf = M.buffers.email_list
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local account = vim.b[buf].himalaya_account
    local folder = vim.b[buf].himalaya_folder
    if account and folder then
      M.show_email_list({folder, '--account=' .. account})
    end
  end
end

-- Close current view
function M.close_current_view()
  vim.cmd('close')
end

-- Close without saving (discard)
function M.close_without_saving()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_delete(buf, { force = true })
  vim.notify('Draft discarded', vim.log.levels.INFO)
end

-- Close and save as draft
function M.close_and_save_draft()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].himalaya_compose then
    -- TODO: Implement draft saving with Himalaya CLI
    -- For now, just close and notify
    vim.notify('Draft saved (not yet implemented)', vim.log.levels.WARN)
    vim.cmd('close')
  else
    vim.cmd('close')
  end
end

-- Close Himalaya entirely (all buffers)
function M.close_himalaya()
  -- Close all Himalaya buffers
  for _, buf in pairs(M.buffers) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  
  -- Reset buffer tracking
  M.buffers = {
    email_list = nil,
    email_read = nil,
    email_compose = nil,
  }
  
  vim.notify('Himalaya closed', vim.log.levels.INFO)
end

-- Check if email buffer is open
function M.is_email_buffer_open()
  return M.buffers.email_list and vim.api.nvim_buf_is_valid(M.buffers.email_list)
end

-- Refresh current view
function M.refresh_current_view()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].himalaya_emails then
    M.refresh_email_list()
  end
end

-- Search emails
function M.search_emails(query)
  local results = utils.search_emails(config.state.current_account, query)
  if results then
    -- Display search results in email list format
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-list')
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    
    local lines = M.format_email_list(results)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    vim.b[buf].himalaya_emails = results
    vim.b[buf].himalaya_account = config.state.current_account
    vim.b[buf].himalaya_search = query
    
    M.open_email_window(buf, 'Search Results: ' .. query)
  else
    vim.notify('Search failed', vim.log.levels.ERROR)
  end
end

-- Show attachments
function M.show_attachments(email_id)
  local attachments = utils.get_email_attachments(config.state.current_account, email_id)
  if not attachments or #attachments == 0 then
    vim.notify('No attachments found', vim.log.levels.INFO)
    return
  end
  
  -- Create attachment list buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-attachments')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  local lines = {'Email Attachments', string.rep('─', 50), ''}
  for i, attachment in ipairs(attachments) do
    table.insert(lines, string.format('%d. %s (%s)', i, attachment.name, attachment.size or 'unknown size'))
  end
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 50))
  table.insert(lines, '<CR>:download  q:close')
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  vim.b[buf].himalaya_attachments = attachments
  vim.b[buf].himalaya_email_id = email_id
  
  M.open_email_window(buf, 'Attachments')
end

-- Read current email (from email list buffer)
function M.read_current_email()
  local email_id = M.get_current_email_id()
  if email_id then
    M.read_email(email_id)
  else
    vim.notify('No email selected', vim.log.levels.WARN)
  end
end

-- Attach file to current composition
function M.attach_file()
  if vim.bo.filetype ~= 'himalaya-compose' then
    vim.notify('Can only attach files in composition mode', vim.log.levels.ERROR)
    return
  end
  
  -- Use native file picker
  local file = vim.fn.input('File to attach: ', '', 'file')
  if file and file ~= '' then
    local attachments = vim.b.himalaya_attachments or {}
    table.insert(attachments, file)
    vim.b.himalaya_attachments = attachments
    vim.notify('Attached: ' .. file, vim.log.levels.INFO)
  end
end

-- Compose draft email
function M.compose_draft()
  M.compose_email(nil, true) -- true = draft mode
end

-- Manage email tags
function M.manage_tags()
  local email_id = M.get_current_email_id()
  if not email_id then
    vim.notify('No email selected', vim.log.levels.WARN)
    return
  end
  
  -- Simple tag input
  local tag = vim.fn.input('Tag to add/remove (prefix with - to remove): ')
  if tag and tag ~= '' then
    local action = tag:sub(1, 1) == '-' and 'remove' or 'add'
    local tag_name = action == 'remove' and tag:sub(2) or tag
    utils.manage_tag(email_id, tag_name, action)
  end
end

-- Show email info
function M.show_email_info()
  local email_id = M.get_current_email_id()
  if not email_id then
    vim.notify('No email selected', vim.log.levels.WARN)
    return
  end
  
  local info = utils.get_email_info(email_id)
  if info then
    -- Create info buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-info')
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(info, '\n'))
    
    M.open_email_window(buf, 'Email Info', { width = 0.6, height = 0.5 })
  end
end

-- Helper function to get current email ID
function M.get_current_email_id()
  if vim.bo.filetype ~= 'himalaya-list' then
    return nil
  end
  
  local line = vim.api.nvim_get_current_line()
  local email_index = vim.fn.line('.') - 3 -- Account for header lines
  local emails = vim.b.himalaya_emails
  
  if emails and emails[email_index] then
    return emails[email_index].id
  end
  
  return nil
end

-- Open link under cursor
function M.open_link_under_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local urls = vim.b[buf].himalaya_urls
  
  if not urls or #urls == 0 then
    vim.notify('No links found in this email', vim.log.levels.INFO)
    return
  end
  
  -- Get current line
  local line = vim.api.nvim_get_current_line()
  
  -- Check if cursor is on a link line
  local link_number = line:match('^%[(%d+)%]')
  if link_number then
    local index = tonumber(link_number)
    if index and urls[index] then
      M.open_url(urls[index])
      return
    end
  end
  
  -- If not on a link line, show picker
  if #urls == 1 then
    M.open_url(urls[1])
  else
    local choices = {}
    for i, url in ipairs(urls) do
      table.insert(choices, string.format('%d. %s', i, url))
    end
    
    vim.ui.select(choices, {
      prompt = 'Select link to open:',
      format_item = function(item)
        return item
      end,
    }, function(choice)
      if choice then
        local index = tonumber(choice:match('^(%d+)%.'))
        if index and urls[index] then
          M.open_url(urls[index])
        end
      end
    end)
  end
end

-- Open URL using system default browser
function M.open_url(url)
  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = { 'open', url }
  elseif vim.fn.has('unix') == 1 then
    cmd = { 'xdg-open', url }
  elseif vim.fn.has('win32') == 1 then
    cmd = { 'cmd', '/c', 'start', url }
  else
    vim.notify('Unsupported platform for opening URLs', vim.log.levels.ERROR)
    return
  end
  
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify('Opened: ' .. url, vim.log.levels.INFO)
      else
        vim.notify('Failed to open URL', vim.log.levels.ERROR)
      end
    end
  })
end

return M