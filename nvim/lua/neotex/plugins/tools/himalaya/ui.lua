-- Himalaya Email Client UI
-- Buffer and window management for email interface

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local window_stack = require('neotex.plugins.tools.himalaya.window_stack')
local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
local state = require('neotex.plugins.tools.himalaya.state')

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
  
  -- Sync state with sidebar configuration (non-intrusive)
  state.sync_with_sidebar()
  
  -- Note: Session restoration is now manual only
  -- Call M.restore_session() explicitly if needed
end

-- Show email list in sidebar
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
  elseif account and account ~= config.state.current_account then
    M.reset_pagination()  -- Reset pagination when changing accounts
  end
  
  -- Switch folder if different (only reset pagination if actually changing folders)
  if folder ~= config.state.current_folder then
    config.state.current_folder = folder  -- Set folder directly without resetting page
    M.reset_pagination()  -- Reset pagination when changing folders
  end
  
  -- Update state
  state.set_current_account(config.state.current_account)
  state.set_current_folder(folder)
  
  -- Get email list with pagination
  local emails = utils.get_email_list(config.state.current_account, folder, config.state.current_page, config.state.page_size)
  if not emails then
    vim.notify('Failed to get email list', vim.log.levels.ERROR)
    return
  end
  
  -- Store total count if available
  if emails and #emails > 0 then
    config.state.total_emails = #emails
  end
  
  -- Open sidebar (this creates the buffer if needed)
  local win = sidebar.open()
  local buf = sidebar.get_buf()
  
  -- Update buffer tracking
  M.buffers.email_list = buf
  
  -- Format email list content
  local lines = M.format_email_list(emails)
  sidebar.update_content(lines)
  
  -- Store email data for reference in sidebar buffer
  vim.api.nvim_buf_set_var(buf, 'himalaya_emails', emails)
  vim.api.nvim_buf_set_var(buf, 'himalaya_account', config.state.current_account)
  vim.api.nvim_buf_set_var(buf, 'himalaya_folder', folder)
  
  -- Save current view to state
  state.save()
  
  -- Focus the sidebar
  sidebar.focus()
  
  vim.notify('Email list loaded in sidebar', vim.log.levels.INFO)
  return win
end

-- Format email list for display
function M.format_email_list(emails)
  local lines = {}
  
  -- Header with pagination info
  local account = config.get_current_account()
  local header = string.format('Himalaya - %s - %s', account.email, config.state.current_folder)
  local pagination_info = string.format('Page %d | %d emails (page size: %d)', 
    config.state.current_page, #emails, config.state.page_size)
  
  table.insert(lines, header)
  table.insert(lines, pagination_info)
  table.insert(lines, string.rep('─', math.max(#header, #pagination_info)))
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
  table.insert(lines, 'r:refresh gn:next-page gp:prev-page')
  table.insert(lines, 'gm:folder ga:account gw:write gr:reply gf:forward')
  table.insert(lines, 'gD:delete gA:archive gS:spam')
  
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
  
  -- Update selected email in state
  state.set_selected_email(email_id)
  
  -- Open in window
  M.open_email_window(buf, 'Email - ' .. (email_content.subject or 'No Subject'))
end

-- Read current email from list

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

-- Parse email content for reply operations
function M.parse_email_for_reply(email_content)
  local parsed = {}
  
  if type(email_content) == 'string' then
    -- Parse raw email string
    local email_lines = vim.split(email_content, '\n')
    local in_headers = true
    local body_lines = {}
    
    for _, line in ipairs(email_lines) do
      if in_headers then
        if line == '' or line:match('^──+$') then
          in_headers = false
        elseif line:match('^From:%s*(.+)') then
          parsed.from = line:match('^From:%s*(.+)')
        elseif line:match('^To:%s*(.+)') then
          parsed.to = line:match('^To:%s*(.+)')
        elseif line:match('^CC:%s*(.+)') then
          parsed.cc = line:match('^CC:%s*(.+)')
        elseif line:match('^Subject:%s*(.+)') then
          parsed.subject = line:match('^Subject:%s*(.+)')
        elseif line:match('^Date:%s*(.+)') then
          parsed.date = line:match('^Date:%s*(.+)')
        end
      else
        -- Skip separator lines
        if not line:match('^──+$') then
          table.insert(body_lines, line)
        end
      end
    end
    
    parsed.body = table.concat(body_lines, '\n')
  else
    -- Already structured data
    parsed = email_content
  end
  
  return parsed
end

-- Reply to email
function M.reply_email(email_id, reply_all)
  local email_content = utils.get_email_content(config.state.current_account, email_id)
  if not email_content then
    vim.notify('Failed to get email for reply', vim.log.levels.ERROR)
    return
  end
  
  -- Parse email content if it's raw text
  local parsed_email = M.parse_email_for_reply(email_content)
  
  -- Create compose buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Reply template
  local account = config.get_current_account()
  local to_field = parsed_email.from or ''
  if reply_all then
    local cc_field = parsed_email.cc or ''
    if cc_field ~= '' then
      to_field = to_field .. ', ' .. cc_field
    end
    -- Also include other recipients from To field if reply_all
    local original_to = parsed_email.to or ''
    if original_to ~= '' and original_to ~= account.email then
      to_field = to_field .. ', ' .. original_to
    end
  end
  
  local subject = parsed_email.subject or ''
  if not subject:match('^Re:%s') then
    subject = 'Re: ' .. subject
  end
  
  local lines = {
    'From: ' .. account.email,
    'To: ' .. to_field,
    'Subject: ' .. subject,
    '',
    '',
    '> ' .. (parsed_email.from or 'Unknown') .. ' wrote:',
  }
  
  -- Add quoted original content
  if parsed_email.body then
    local original_lines = vim.split(parsed_email.body, '\n')
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
  
  -- Parse email content
  local parsed_email = M.parse_email_for_reply(email_content)
  
  -- Create compose buffer similar to reply but with forward template
  local buf = vim.api.nvim_create_buf(false, true)
  
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  local account = config.get_current_account()
  local subject = parsed_email.subject or ''
  if not subject:match('^Fwd:%s') then
    subject = 'Fwd: ' .. subject
  end
  
  local lines = {
    'From: ' .. account.email,
    'To: ',
    'Subject: ' .. subject,
    '',
    '---------- Forwarded message ---------',
    'From: ' .. (parsed_email.from or 'Unknown'),
    'Date: ' .. (parsed_email.date or 'Unknown'),
    'Subject: ' .. (parsed_email.subject or '(No subject)'),
    'To: ' .. (parsed_email.to or 'Unknown'),
    '',
  }
  
  -- Add CC if present
  if parsed_email.cc then
    table.insert(lines, 10, 'CC: ' .. parsed_email.cc)
    table.insert(lines, 11, '')
  end
  
  -- Add original content
  if parsed_email.body then
    local original_lines = vim.split(parsed_email.body, '\n')
    vim.list_extend(lines, original_lines)
  end
  
  table.insert(lines, '')
  table.insert(lines, '--')
  table.insert(lines, account.name or account.email)
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  table.insert(lines, 'ZZ:send q:save-draft Q:discard')
  
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
    -- Refresh email list after sending
    M.refresh_email_list()
  else
    vim.notify('Failed to send email', vim.log.levels.ERROR)
  end
end

-- Delete email with smart error handling
function M.delete_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  
  if not email_id then
    vim.notify('No email to delete', vim.log.levels.WARN)
    return
  end
  
  local success, error_type, extra = utils.smart_delete_email(config.state.current_account, email_id)
  
  if success then
    vim.notify('Email deleted', vim.log.levels.INFO)
    M.close_current_view()
    M.refresh_email_list()
  elseif error_type == 'missing_trash' then
    -- Trash folder doesn't exist, offer alternatives
    M.handle_missing_trash_folder(email_id, extra)
  else
    vim.notify('Failed to delete email: ' .. (extra or 'Unknown error'), vim.log.levels.ERROR)
  end
end

-- Handle missing trash folder scenario
function M.handle_missing_trash_folder(email_id, suggested_folders)
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just permanently delete
    vim.notify('Headless mode: Permanently deleting email (trash folder not found)', vim.log.levels.INFO)
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

-- Permanently delete email (flag + expunge)
function M.permanent_delete_email(email_id)
  local success = utils.delete_email(config.state.current_account, email_id, true)
  if success then
    vim.notify('Email permanently deleted', vim.log.levels.INFO)
    M.close_current_view()
    -- Trigger manual refresh for permanent deletion
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  else
    vim.notify('Failed to permanently delete email', vim.log.levels.ERROR)
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
    vim.notify('Headless mode: Moving email to Archive folder', vim.log.levels.INFO)
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

-- Open email window
function M.open_email_window(buf, title)
  local ui_config = config.config.ui.email_list
  
  -- Calculate window size accounting for sidebar that now shifts content
  local sidebar_width = sidebar.is_open() and sidebar.get_width() or 0
  -- Since sidebar now shifts content, we use the remaining available space
  local available_width = vim.o.columns - sidebar_width
  local width = math.min(math.floor(available_width * 0.8), math.floor(vim.o.columns * ui_config.width))
  local height = math.floor(vim.o.lines * ui_config.height)
  
  -- Position in the main content area (shifted by sidebar)
  local row = math.floor((vim.o.lines - height) / 2)
  local col
  if sidebar.is_open() then
    -- Position in the main content area (after sidebar shift)
    -- Center within the available space after sidebar
    col = sidebar_width + math.floor((available_width - width) / 2)
  else
    -- Center if no sidebar
    col = math.floor((vim.o.columns - width) / 2)
  end
  
  -- Get sidebar window as parent if it's open, otherwise current window
  local parent_win = sidebar.is_open() and sidebar.get_win() or vim.api.nvim_get_current_win()
  
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
  
  -- Add to window stack with sidebar as parent
  window_stack.push(win, parent_win)
  
  -- Store window ID in buffer for reference
  vim.api.nvim_buf_set_var(buf, 'himalaya_window_id', win)
  
  return win
end

-- Refresh current email list
function M.refresh_email_list()
  local buf = M.buffers.email_list
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local account = vim.b[buf].himalaya_account
    local folder = vim.b[buf].himalaya_folder
    if account and folder then
      -- Clear cache to force refresh
      utils.clear_email_cache(account, folder)
      M.show_email_list({folder, '--account=' .. account})
    end
  end
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
  
  vim.notify(string.format('Himalaya closed (%d buffers cleaned up)', closed_buffers), vim.log.levels.INFO)
end

-- Debug function to list Himalaya buffers
function M.debug_buffers()
  print("Himalaya Buffers Debug:")
  print("Tracked buffers:")
  for name, buf in pairs(M.buffers) do
    local status = buf and vim.api.nvim_buf_is_valid(buf) and "valid" or "invalid/nil"
    print(string.format("  %s: %s (%s)", name, buf or "nil", status))
  end
  
  print("All Himalaya buffers by filetype:")
  local all_buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(all_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ok, filetype = pcall(vim.api.nvim_buf_get_option, buf, 'filetype')
      if ok and filetype and filetype:match('^himalaya%-') then
        local name = vim.api.nvim_buf_get_name(buf)
        print(string.format("  Buffer %d: %s (name: %s)", buf, filetype, name))
      end
    end
  end
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
  -- Update search state
  state.set_last_query(query)
  
  local results = utils.search_emails(config.state.current_account, query)
  if results then
    -- Save search results to state
    state.set_search_results(results)
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
  
  local line_num = vim.fn.line('.')
  local email_index = line_num - 4 -- Account for header lines (header + pagination + separator + empty = 4 lines)
  local emails = vim.b.himalaya_emails
  
  if emails and email_index > 0 and emails[email_index] then
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

-- Check if session restoration is available
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
    vim.notify('Cannot restore session: ' .. message, vim.log.levels.WARN)
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
      vim.notify('Previous search: "' .. last_query .. '" available', vim.log.levels.INFO)
    end
    
    vim.notify('Email session restored', vim.log.levels.INFO)
  end, 100)
  
  return true
end

-- Show session restoration prompt (called manually)
function M.prompt_session_restore()
  local can_restore, message = M.can_restore_session()
  
  if not can_restore then
    vim.notify(message, vim.log.levels.INFO)
    return
  end
  
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just restore directly
    vim.notify('Headless mode: ' .. message, vim.log.levels.INFO)
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

-- Update sidebar configuration from state
function M.sync_sidebar_config()
  local sidebar_width = state.get_sidebar_width()
  local sidebar_position = state.get_sidebar_position()
  
  if sidebar_width and sidebar_width ~= sidebar.get_width() then
    sidebar.set_width(sidebar_width)
  end
  
  if sidebar_position and sidebar_position ~= sidebar.config.position then
    sidebar.set_position(sidebar_position)
  end
end

-- Save current sidebar configuration to state
function M.save_sidebar_config()
  state.set_sidebar_width(sidebar.get_width())
  state.set_sidebar_position(sidebar.config.position)
  state.save()
end

-- Update email list display without resetting pagination
function M.update_email_display()
  -- Get email list with current pagination settings
  local emails = utils.get_email_list(config.state.current_account, config.state.current_folder, config.state.current_page, config.state.page_size)
  if not emails then
    vim.notify('Failed to get email list', vim.log.levels.ERROR)
    return
  end
  
  -- Get existing sidebar buffer or create new one
  local win = sidebar.open()
  local buf = sidebar.get_buf()
  
  -- Update buffer tracking
  M.buffers.email_list = buf
  
  -- Format email list content
  local lines = M.format_email_list(emails)
  sidebar.update_content(lines)
  
  -- Store email data for reference in sidebar buffer
  vim.api.nvim_buf_set_var(buf, 'himalaya_emails', emails)
  vim.api.nvim_buf_set_var(buf, 'himalaya_account', config.state.current_account)
  vim.api.nvim_buf_set_var(buf, 'himalaya_folder', config.state.current_folder)
  
  -- Save current view to state
  state.save()
  
  -- Focus the sidebar
  sidebar.focus()
end

-- Next page of emails
function M.next_page()
  config.state.current_page = config.state.current_page + 1
  
  -- Check if there are emails for this page
  local emails = utils.get_email_list(config.state.current_account, config.state.current_folder, config.state.current_page, config.state.page_size)
  if not emails or #emails == 0 then
    -- No more emails, go back to previous page
    config.state.current_page = config.state.current_page - 1
    vim.notify('No more emails on next page', vim.log.levels.INFO)
    return
  end
  
  -- Update the display without going through show_email_list
  M.update_email_display()
end

-- Previous page of emails
function M.prev_page()
  if config.state.current_page > 1 then
    config.state.current_page = config.state.current_page - 1
    M.update_email_display()
  else
    vim.notify('Already on first page', vim.log.levels.INFO)
  end
end


-- Archive current email (from email list)
function M.archive_current_email()
  local email_id = M.get_current_email_id()
  if email_id then
    -- Try different archive folder names that might exist
    local archive_folders = {'Archive', 'All Mail', '[Gmail]/All Mail', '[Gmail].All Mail', 'ARCHIVE', 'Archived'}
    local folders = utils.get_folders(config.state.current_account)
    local archive_folder = nil
    
    if folders then
      -- Find the first existing archive folder
      for _, folder in ipairs(folders) do
        for _, archive_name in ipairs(archive_folders) do
          if folder:lower():match(archive_name:lower()) or folder == archive_name then
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
        vim.notify('Email archived to ' .. archive_folder, vim.log.levels.INFO)
        -- Refresh is handled by auto-refresh system via HimalayaEmailMoved event
      end
    else
      -- If no archive folder found, offer alternatives
      vim.ui.select({
        'Move to All Mail',
        'Move to [Gmail].All Mail', 
        'Move to custom folder...',
        'Cancel'
      }, {
        prompt = 'No archive folder found. How would you like to archive this email?',
      }, function(choice)
        if choice == 'Move to All Mail' then
          utils.move_email(email_id, 'All Mail')
        elseif choice == 'Move to [Gmail].All Mail' then
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
    vim.notify('No email selected', vim.log.levels.WARN)
  end
end

-- Mark current email as spam and move to spam folder
function M.spam_current_email()
  local email_id = M.get_current_email_id()
  if email_id then
    -- Try different spam folder names that might exist
    local spam_folders = {'Spam', 'Junk', '[Gmail].Spam', '[Gmail]/Spam', 'SPAM', 'JUNK'}
    local folders = utils.get_folders(config.state.current_account)
    local spam_folder = nil
    
    if folders then
      -- Find the first existing spam folder
      for _, folder in ipairs(folders) do
        for _, spam_name in ipairs(spam_folders) do
          if folder:lower():match(spam_name:lower()) then
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
        vim.notify('Email marked as spam and moved to ' .. spam_folder, vim.log.levels.INFO)
        -- Refresh is handled by auto-refresh system via HimalayaEmailMoved event
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
    vim.notify('No email selected', vim.log.levels.WARN)
  end
end

-- Reset pagination when switching folders/accounts
function M.reset_pagination()
  config.state.current_page = 1
  config.state.page_size = 30  -- Reset to default
end

return M