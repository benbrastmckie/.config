-- Email composition UI module
-- Handles creating and sending emails

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')

-- Buffer tracking
local compose_buf = nil
local compose_win = nil

-- Create new email composition window
function M.new(args)
  args = args or {}
  
  -- Get current account
  local account = config.get_current_account()
  
  -- Create composition buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_name(buf, 'Himalaya Compose')
  
  compose_buf = buf
  
  -- Set initial template
  local template = M.get_email_template(account, args)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, template)
  
  -- Open in a window
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.7)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Compose Email ',
    title_pos = 'center'
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  compose_win = win
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'linebreak', true)
  
  -- Setup keymaps
  M.setup_keymaps(buf)
  
  -- Position cursor
  vim.api.nvim_win_set_cursor(win, {1, 4}) -- After "To: "
  
  logger.info('Email composition window opened')
end

-- Get email template
function M.get_email_template(account, args)
  local template = {}
  
  -- Headers
  table.insert(template, 'To: ' .. (args.to or ''))
  table.insert(template, 'Cc: ' .. (args.cc or ''))
  table.insert(template, 'Bcc: ' .. (args.bcc or ''))
  table.insert(template, 'Subject: ' .. (args.subject or ''))
  table.insert(template, 'From: ' .. (account.email or 'user@example.com'))
  table.insert(template, '---')
  table.insert(template, '')
  
  -- Body
  if args.body then
    for line in args.body:gmatch('[^\n]+') do
      table.insert(template, line)
    end
  else
    table.insert(template, '-- Write your message here --')
    table.insert(template, '')
  end
  
  -- Signature
  if account.signature then
    table.insert(template, '')
    table.insert(template, '--')
    for line in account.signature:gmatch('[^\n]+') do
      table.insert(template, line)
    end
  end
  
  return template
end

-- Setup keymaps for compose buffer
function M.setup_keymaps(buf)
  local opts = { noremap = true, silent = true }
  
  -- Send email
  vim.api.nvim_buf_set_keymap(buf, 'n', '<C-s>', 
    ':lua require("neotex.plugins.tools.himalaya.ui.compose").send()<CR>', opts)
  
  -- Cancel composition
  vim.api.nvim_buf_set_keymap(buf, 'n', '<C-c>', 
    ':lua require("neotex.plugins.tools.himalaya.ui.compose").cancel()<CR>', opts)
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', 
    ':lua require("neotex.plugins.tools.himalaya.ui.compose").cancel()<CR>', opts)
  
  -- Save draft
  vim.api.nvim_buf_set_keymap(buf, 'n', '<C-d>', 
    ':lua require("neotex.plugins.tools.himalaya.ui.compose").save_draft()<CR>', opts)
  
  -- Add help text at bottom
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      local line_count = vim.api.nvim_buf_line_count(buf)
      local help_lines = {
        '',
        '-- Commands: <C-s> Send | <C-c> Cancel | <C-d> Save Draft --'
      }
      vim.api.nvim_buf_set_lines(buf, line_count, -1, false, help_lines)
    end
  end, 100)
end

-- Send email
function M.send()
  if not compose_buf or not vim.api.nvim_buf_is_valid(compose_buf) then
    return
  end
  
  local lines = vim.api.nvim_buf_get_lines(compose_buf, 0, -1, false)
  local email_data = M.parse_email_buffer(lines)
  
  -- Validate email
  if not email_data.to or email_data.to == '' then
    notifications.show('Please specify a recipient in the To: field', 'error')
    return
  end
  
  if not email_data.subject or email_data.subject == '' then
    local confirm = vim.fn.confirm('Send without subject?', '&Yes\n&No', 2)
    if confirm ~= 1 then
      return
    end
  end
  
  -- TODO: Implement actual email sending via himalaya CLI
  notifications.show('Email sending not yet implemented in v2.0', 'info')
  logger.info('Would send email:', vim.inspect(email_data))
  
  -- For now, just close the window
  M.close()
end

-- Parse email buffer into structured data
function M.parse_email_buffer(lines)
  local email = {
    headers = {},
    body = {}
  }
  
  local in_body = false
  local skip_help = false
  
  for _, line in ipairs(lines) do
    if line == '---' then
      in_body = true
    elseif line:match('^-- Commands:') then
      skip_help = true
    elseif not skip_help then
      if in_body then
        table.insert(email.body, line)
      else
        -- Parse header
        local header, value = line:match('^([^:]+):%s*(.*)$')
        if header then
          email[header:lower()] = value
          email.headers[header] = value
        end
      end
    end
  end
  
  -- Clean up body
  email.body_text = table.concat(email.body, '\n'):gsub('^%s*-- Write your message here --%s*\n?', '')
  
  return email
end

-- Save draft
function M.save_draft()
  notifications.show('Draft saving not yet implemented in v2.0', 'info')
  logger.info('save_draft called')
end

-- Cancel composition
function M.cancel()
  local confirm = vim.fn.confirm('Discard this email?', '&Yes\n&No', 2)
  if confirm == 1 then
    M.close()
  end
end

-- Close composition window
function M.close()
  if compose_win and vim.api.nvim_win_is_valid(compose_win) then
    vim.api.nvim_win_close(compose_win, true)
  end
  compose_buf = nil
  compose_win = nil
  logger.info('Composition window closed')
end

-- Reply to email
function M.reply(email_id, reply_all)
  -- TODO: Implement reply functionality
  notifications.show('Reply functionality not yet implemented in v2.0', 'info')
  logger.info('reply called with email_id:', email_id, 'reply_all:', reply_all)
end

-- Forward email
function M.forward(email_id)
  -- TODO: Implement forward functionality
  notifications.show('Forward functionality not yet implemented in v2.0', 'info')
  logger.info('forward called with email_id:', email_id)
end

return M