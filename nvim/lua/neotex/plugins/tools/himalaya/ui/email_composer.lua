-- Himalaya Email Composer UI Module
-- Handles composing, sending, and saving draft emails

local M = {}

-- Dependencies
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')

-- Module state
local buffers = nil  -- Reference to main module's buffers
local main = nil     -- Reference to main module for window functions
local window_stack = nil  -- Reference to window stack from main module

-- Initialize module
function M.init(main_buffers, main_module, main_window_stack)
  buffers = main_buffers
  main = main_module
  window_stack = main_window_stack
end

-- Compose new email
function M.compose_email(to_address)
  -- Capture parent window before creating compose buffer
  local parent_win = vim.api.nvim_get_current_win()
  local parent_buf = vim.api.nvim_win_get_buf(parent_win)
  
  -- Create compose buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Email template
  local account = config.get_current_account()
  
  -- Get email address using auto-detection
  local from_email = config.get_account_email()
  
  -- Error if no email address found
  if not from_email then
    notifications.show('Cannot compose email: No email address configured for account', 'error')
    return
  end
  
  local lines = {
    'From: ' .. from_email,
    'To: ' .. (to_address or ''),
    'Subject: ',
    '',
    '',
    '',
    '--',
    account.name or from_email,
    '',
    string.rep('─', 70),
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Store compose data
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = state.get_current_account()
  
  -- Store parent window info for restoration
  vim.b[buf].himalaya_parent_win = parent_win
  vim.b[buf].himalaya_parent_buf = parent_buf
  
  -- Set up autocommand to handle window close and focus restoration
  vim.api.nvim_create_autocmd({'BufWipeout', 'BufDelete'}, {
    buffer = buf,
    once = true,
    callback = function()
      -- Restore focus to parent window if it's still valid
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(parent_win) then
          vim.api.nvim_set_current_win(parent_win)
        elseif vim.api.nvim_buf_is_valid(parent_buf) then
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
  })
  
  -- Set up buffer keymaps
  config.setup_buffer_keymaps(buf)
  
  -- Open in window
  main.open_email_window(buf, 'Compose Email', parent_win)
  
  -- Position cursor on To: line after "To: "
  vim.api.nvim_win_set_cursor(0, {2, 4})
  -- Start in insert mode
  vim.cmd('startinsert!')
end

-- Send current email (from compose buffer)
function M.send_current_email()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.b[buf].himalaya_compose then
    notifications.show('Not in compose buffer', 'warn')
    return
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Parse email headers and body
  local headers = {}
  local body_start = nil
  
  for i, line in ipairs(lines) do
    if line == '' and not body_start then
      body_start = i + 1
      break
    elseif line:match('^[%w-]+:') then
      local header, value = line:match('^([%w-]+):%s*(.*)$')
      if header then
        headers[header:lower()] = value
      end
    end
  end
  
  -- Validate required fields
  if not headers.to or headers.to == '' then
    notifications.show('To: field is required', 'error')
    return
  end
  
  if not headers.subject or headers.subject == '' then
    notifications.show('Subject: field is required', 'error')
    return
  end
  
  -- Get body content (skip footer)
  local body_lines = {}
  for i = body_start or 1, #lines do
    if lines[i]:match('^─+$') then
      break
    end
    table.insert(body_lines, lines[i])
  end
  
  local body = table.concat(body_lines, '\n')
  
  -- Send email
  local email_data = {
    from = headers.from,
    to = headers.to,
    subject = headers.subject,
    body = body
  }
  local result = utils.send_email(state.get_current_account(), email_data)
  
  if result then
    notifications.show('Email sent successfully', 'info', { user_action = true })
    
    -- Get parent window info from buffer variables
    local parent_win = vim.b[buf].himalaya_parent_win
    local parent_buf = vim.b[buf].himalaya_parent_buf
    
    -- Close the compose window first
    local current_win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(current_win) then
      vim.api.nvim_win_close(current_win, true)
    end
    
    -- Then delete the buffer
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    
    -- Explicitly restore focus to email reading window
    vim.defer_fn(function()
      -- First try the stored email reading window (most reliable for replies)
      if main._email_reading_win and vim.api.nvim_win_is_valid(main._email_reading_win) then
        vim.api.nvim_set_current_win(main._email_reading_win)
        main._email_reading_win = nil  -- Clear it after use
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
  else
    notifications.show('Failed to send email', 'error', { user_action = true })
  end
end

-- Navigate to next field in compose buffer
function M.compose_next_field()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]
  
  -- Field positions:
  -- Line 2: To:
  -- Line 3: Subject:
  -- Line 5+: Body (first empty line after headers)
  
  if row < 2 then
    -- Move to To: field
    vim.api.nvim_win_set_cursor(0, {2, 4})
    vim.cmd('startinsert!')
  elseif row == 2 then
    -- Move to Subject: field
    vim.api.nvim_win_set_cursor(0, {3, 9})
    vim.cmd('startinsert!')
  elseif row == 3 then
    -- Move to body (first empty line after subject)
    vim.api.nvim_win_set_cursor(0, {5, 0})
    vim.cmd('startinsert')
  else
    -- In body, go back to To:
    vim.api.nvim_win_set_cursor(0, {2, 4})
    vim.cmd('startinsert!')
  end
end

-- Navigate to previous field in compose buffer
function M.compose_prev_field()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  
  if row <= 2 then
    -- At To: or above, go to body
    vim.api.nvim_win_set_cursor(0, {5, 0})
    vim.cmd('startinsert')
  elseif row == 3 then
    -- At Subject:, go to To:
    vim.api.nvim_win_set_cursor(0, {2, 4})
    vim.cmd('startinsert!')
  else
    -- In body, go to Subject:
    vim.api.nvim_win_set_cursor(0, {3, 9})
    vim.cmd('startinsert!')
  end
end

-- Close compose buffer and save as draft
function M.close_and_save_draft()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.b[buf].himalaya_compose then
    notifications.show('Not in compose buffer', 'warn')
    return
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Parse email content
  local email_data = utils.parse_email_content(lines)
  
  -- Save to drafts folder
  local account = state.get_current_account()
  local drafts_folders = {'Drafts', 'DRAFTS', '[Gmail]/Drafts', 'Draft'}
  local folders = utils.get_folders(account)
  local drafts_folder = nil
  
  if folders then
    for _, folder in ipairs(folders) do
      for _, draft_name in ipairs(drafts_folders) do
        if folder == draft_name or folder:lower() == draft_name:lower() then
          drafts_folder = folder
          break
        end
      end
      if drafts_folder then break end
    end
  end
  
  if not drafts_folder then
    drafts_folder = 'Drafts' -- Default fallback
  end
  
  -- Save draft using utility function
  local success = utils.save_draft(account, email_data, drafts_folder)
  
  if success then
    notifications.show('Draft saved to ' .. drafts_folder, 'info')
    main.close_current_view()
  else
    notifications.show('Failed to save draft', 'error')
  end
end

-- Reply to current email
function M.reply_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    -- Store the current window (email reading window) globally for restoration
    main._email_reading_win = vim.api.nvim_get_current_win()
    M.reply_email(email_id, false)
  else
    notifications.show('No email to reply to', 'warn')
  end
end

-- Reply all to current email
function M.reply_all_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    -- Store the current window (email reading window) globally for restoration
    main._email_reading_win = vim.api.nvim_get_current_win()
    M.reply_email(email_id, true)
  else
    notifications.show('No email to reply to', 'warn')
  end
end

-- Reply to email
function M.reply_email(email_id, reply_all)
  -- Capture parent window before creating new window
  local parent_win = vim.api.nvim_get_current_win()
  
  -- Store the parent window in a more reliable way
  local parent_buf = vim.api.nvim_win_get_buf(parent_win)
  local is_email_reading_buffer = vim.b[parent_buf].himalaya_email_id ~= nil
  
  local email_content = utils.get_email_content(state.get_current_account(), email_id)
  if not email_content then
    notifications.show('Failed to get email for reply', 'error')
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
  
  -- Get email address using auto-detection
  local from_email = config.get_account_email()
  
  -- Error if no email address found
  if not from_email then
    notifications.show('Cannot reply: No email address configured for account', 'error')
    return
  end
  
  local to_field = parsed_email.from or ''
  if reply_all then
    local cc_field = parsed_email.cc or ''
    if cc_field ~= '' then
      to_field = to_field .. ', ' .. cc_field
    end
    -- Also include other recipients from To field if reply_all
    local original_to = parsed_email.to or ''
    if original_to ~= '' and original_to ~= from_email then
      to_field = to_field .. ', ' .. original_to
    end
  end
  
  local subject = parsed_email.subject or ''
  if not subject:match('^Re:%s') then
    subject = 'Re: ' .. subject
  end
  
  local lines = {
    'From: ' .. from_email,
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
  table.insert(lines, account.name or from_email)
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Store compose data
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = state.get_current_account()
  vim.b[buf].himalaya_reply_to = email_id
  
  -- Store parent window info in compose buffer for reliable restoration
  vim.b[buf].himalaya_parent_win = parent_win
  vim.b[buf].himalaya_parent_buf = parent_buf
  vim.b[buf].himalaya_parent_is_email = is_email_reading_buffer
  
  -- Set up autocommand to handle window close and focus restoration
  vim.api.nvim_create_autocmd({'BufWipeout', 'BufDelete'}, {
    buffer = buf,
    once = true,
    callback = function()
      -- Restore focus to parent window if it's still valid
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(parent_win) then
          vim.api.nvim_set_current_win(parent_win)
        elseif vim.api.nvim_buf_is_valid(parent_buf) then
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
  })
  
  -- Open in window with proper parent tracking
  main.open_email_window(buf, 'Reply - ' .. subject, parent_win)
  
  -- Position cursor before quoted content
  vim.api.nvim_win_set_cursor(0, {5, 0})
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

-- Forward current email
function M.forward_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    -- Store the current window (email reading window) globally for restoration
    main._email_reading_win = vim.api.nvim_get_current_win()
    M.forward_email(email_id)
  else
    notifications.show('No email to forward', 'warn')
  end
end

-- Forward email
function M.forward_email(email_id)
  -- Capture parent window before creating new window
  local parent_win = vim.api.nvim_get_current_win()
  
  -- Store the parent window in a more reliable way
  local parent_buf = vim.api.nvim_win_get_buf(parent_win)
  local is_email_reading_buffer = vim.b[parent_buf].himalaya_email_id ~= nil
  
  local email_content = utils.get_email_content(state.get_current_account(), email_id)
  if not email_content then
    notifications.show('Failed to get email for forwarding', 'error')
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
  
  -- Get email address using auto-detection
  local from_email = config.get_account_email()
  
  -- Error if no email address found
  if not from_email then
    notifications.show('Cannot forward: No email address configured for account', 'error')
    return
  end
  
  local lines = {
    'From: ' .. from_email,
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
  table.insert(lines, account.name or from_email)
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = state.get_current_account()
  vim.b[buf].himalaya_forward = email_id
  
  -- Store parent window info in compose buffer for reliable restoration
  vim.b[buf].himalaya_parent_win = parent_win
  vim.b[buf].himalaya_parent_buf = parent_buf
  vim.b[buf].himalaya_parent_is_email = is_email_reading_buffer
  
  -- Set up autocommand to handle window close and focus restoration
  vim.api.nvim_create_autocmd({'BufWipeout', 'BufDelete'}, {
    buffer = buf,
    once = true,
    callback = function()
      -- Restore focus to parent window if it's still valid
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(parent_win) then
          vim.api.nvim_set_current_win(parent_win)
        elseif vim.api.nvim_buf_is_valid(parent_buf) then
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
  })
  
  main.open_email_window(buf, 'Forward - ' .. subject, parent_win)
  
  -- Position cursor on To: line
  vim.api.nvim_win_set_cursor(0, {2, #lines[2]})
  vim.cmd('startinsert!')
end

-- Close compose buffer without saving
function M.close_without_saving()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.b[buf].himalaya_compose then
    notifications.show('Not in compose buffer', 'warn')
    return
  end
  
  -- Check if buffer has been modified
  if vim.bo[buf].modified then
    vim.ui.input({
      prompt = 'Discard unsaved changes? (y/n): '
    }, function(input)
      if input and input:lower() == 'y' then
        -- Force close without saving
        vim.bo[buf].modified = false
        main.close_current_view()
        notifications.show('Email discarded', 'info')
      end
    end)
  else
    main.close_current_view()
    notifications.show('Email discarded', 'info')
  end
end

return M