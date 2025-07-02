-- Buffer-based email viewer for Himalaya
local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local utils = require('neotex.plugins.tools.himalaya.utils')
local notify = require('neotex.util.notifications')
local confirm = require('neotex.plugins.tools.himalaya.ui.confirm')

-- Configuration
M.config = {
  use_tab = true,  -- Match composer default
  syntax_highlighting = true,
  show_headers = true,
  wrap_text = true,
}

-- Initialize module
function M.setup(cfg)
  if cfg and cfg.view then
    M.config = vim.tbl_extend('force', M.config, cfg.view)
  end
end

-- Format email address (handle string or table)
local function format_address(addr)
  if not addr then
    return "Unknown"
  end
  
  if type(addr) == "table" then
    if addr.name and addr.addr then
      return string.format("%s <%s>", addr.name, addr.addr)
    elseif addr.addr then
      return addr.addr
    elseif addr.name then
      return addr.name
    end
  end
  
  return tostring(addr)
end

-- Format file size
local function format_size(size)
  if not size then return "unknown size" end
  
  if size < 1024 then
    return string.format("%d B", size)
  elseif size < 1024 * 1024 then
    return string.format("%.1f KB", size / 1024)
  else
    return string.format("%.1f MB", size / (1024 * 1024))
  end
end

-- Process email body (handle plain text and HTML)
local function process_email_body(body)
  if not body then
    return { "No content available" }
  end
  
  local lines = {}
  
  -- Simple line splitting for now
  -- TODO: Add HTML to text conversion
  for line in body:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  if #lines == 0 then
    table.insert(lines, body)
  end
  
  return lines
end

-- Render email content to buffer
function M.render_email(buf, email)
  local lines = {}
  
  -- Headers section
  if M.config.show_headers then
    local from = format_address(email.from)
    local to = format_address(email.to)
    
    table.insert(lines, 'From: ' .. from)
    table.insert(lines, 'To: ' .. to)
    
    if email.cc then
      table.insert(lines, 'Cc: ' .. format_address(email.cc))
    end
    
    table.insert(lines, 'Subject: ' .. (email.subject or 'No Subject'))
    table.insert(lines, 'Date: ' .. (email.date or 'Unknown'))
    table.insert(lines, string.rep('─', 80))
    table.insert(lines, '')
  end
  
  -- Email body
  if email.body then
    -- Process email body (handle plain text and HTML)
    local body_lines = process_email_body(email.body)
    vim.list_extend(lines, body_lines)
  else
    table.insert(lines, "Loading email content...")
  end
  
  -- Attachments section
  if email.attachments and #email.attachments > 0 then
    table.insert(lines, '')
    table.insert(lines, string.rep('─', 80))
    table.insert(lines, 'Attachments:')
    for i, attachment in ipairs(email.attachments) do
      table.insert(lines, string.format('  [%d] %s (%s)', 
        i, attachment.name, format_size(attachment.size)))
    end
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

-- Setup email-specific keymaps
function M.setup_email_keymaps(buf, email)
  local opts = { buffer = buf, silent = true }
  
  -- Navigation
  vim.keymap.set('n', 'q', function()
    -- Close tab or buffer
    if vim.fn.tabpagenr('$') > 1 then
      vim.cmd('tabclose')
    else
      vim.cmd('bdelete')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Close email' }))
  
  -- Actions
  vim.keymap.set('n', 'r', function()
    -- Close current view first
    if vim.fn.tabpagenr('$') > 1 then
      vim.cmd('tabclose')
    else
      vim.cmd('bdelete')
    end
    -- Reply to email
    local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
    composer.reply_email(email, false)
  end, vim.tbl_extend('force', opts, { desc = 'Reply to email' }))
  
  vim.keymap.set('n', 'R', function()
    if vim.fn.tabpagenr('$') > 1 then
      vim.cmd('tabclose')
    else
      vim.cmd('bdelete')
    end
    local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
    composer.reply_email(email, true)
  end, vim.tbl_extend('force', opts, { desc = 'Reply all' }))
  
  vim.keymap.set('n', 'f', function()
    if vim.fn.tabpagenr('$') > 1 then
      vim.cmd('tabclose')
    else
      vim.cmd('bdelete')
    end
    local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
    composer.forward_email(email)
  end, vim.tbl_extend('force', opts, { desc = 'Forward email' }))
  
  vim.keymap.set('n', 'd', function()
    local choice = confirm.show({
      title = 'Delete Email',
      message = 'Move this email to trash?',
      options = { 'Delete', 'Cancel' },
      default = 2,
    })
    
    if choice == 1 then
      if vim.fn.tabpagenr('$') > 1 then
        vim.cmd('tabclose')
      else
        vim.cmd('bdelete')
      end
      -- Delete email and refresh list
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local account = state.get_current_account()
      local folder = state.get_current_folder()
      utils.delete_email(account, folder, email.id)
      
      -- Refresh email list
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.refresh_email_list()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Delete email' }))
  
  -- Navigation between emails
  vim.keymap.set('n', ']e', function()
    M.view_next_email()
  end, vim.tbl_extend('force', opts, { desc = 'Next email' }))
  
  vim.keymap.set('n', '[e', function()
    M.view_previous_email()
  end, vim.tbl_extend('force', opts, { desc = 'Previous email' }))
  
  -- Mark as read/unread
  vim.keymap.set('n', 'u', function()
    -- Toggle seen flag
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local account = state.get_current_account()
    local folder = state.get_current_folder()
    
    -- Check current state
    local is_seen = false
    if email.flags then
      for _, flag in ipairs(email.flags) do
        if flag == 'Seen' then
          is_seen = true
          break
        end
      end
    end
    
    -- Toggle the flag using himalaya commands
    local args
    if is_seen then
      args = { 'flag', 'remove', tostring(email.id), 'Seen' }
    else
      args = { 'flag', 'add', tostring(email.id), 'Seen' }
    end
    
    utils.execute_himalaya(args, { account = account, folder = folder })
    
    -- Refresh display
    M.refresh_current_email()
  end, vim.tbl_extend('force', opts, { desc = 'Toggle read/unread' }))
  
  -- Refresh
  vim.keymap.set('n', 'gr', function()
    M.refresh_current_email()
  end, vim.tbl_extend('force', opts, { desc = 'Refresh email' }))
end

-- View email in buffer
function M.view_email(email_id)
  -- Get email content
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  
  -- Show loading message
  notify.himalaya('Loading email...', notify.categories.STATUS)
  
  local email = utils.get_email_by_id(account, folder, email_id)
  
  if not email then
    notify.himalaya('Failed to load email', notify.categories.ERROR)
    return
  end
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nowrite')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Name the buffer
  local buf_name = string.format('[Email] %s', email.subject or 'No Subject')
  vim.api.nvim_buf_set_name(buf, buf_name)
  
  -- Open in tab or split
  if M.config.use_tab then
    vim.cmd('tabnew')
  else
    vim.cmd('vsplit')
  end
  
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Window options
  vim.wo.wrap = M.config.wrap_text
  vim.wo.linebreak = true
  vim.wo.breakindent = true
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  
  -- Render email content
  M.render_email(buf, email)
  
  -- Setup buffer-local keymaps
  M.setup_email_keymaps(buf, email)
  
  -- Track in state for navigation
  state.set('viewing_email', {
    id = email_id,
    buf = buf,
    account = account,
    folder = folder
  })
  
  -- Apply syntax highlighting if enabled
  if M.config.syntax_highlighting then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('syntax match mailHeader "^\\(From\\|To\\|Cc\\|Subject\\|Date\\):"')
      vim.cmd('syntax match mailEmail "<[^>]\\+@[^>]\\+>"')
      vim.cmd('syntax match mailEmail "[a-zA-Z0-9._%+-]\\+@[a-zA-Z0-9.-]\\+\\.[a-zA-Z]\\{2,}"')
      vim.cmd('syntax match mailQuoted "^>.*$"')
      vim.cmd('hi link mailHeader Keyword')
      vim.cmd('hi link mailEmail Underlined') 
      vim.cmd('hi link mailQuoted Comment')
    end)
  end
  
  -- Position cursor at top
  vim.api.nvim_win_set_cursor(0, {1, 0})
  
  return buf
end

-- View next email in list
function M.view_next_email()
  local current = state.get('viewing_email')
  if not current then return end
  
  -- Get email list from sidebar
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_buf = sidebar.get_buf()
  if not sidebar_buf or not vim.api.nvim_buf_is_valid(sidebar_buf) then
    notify.himalaya('Email list not available', notify.categories.ERROR)
    return
  end
  
  local emails = state.get('email_list.emails')
  if not emails or #emails == 0 then return end
  
  -- Find current email index
  local current_idx = nil
  for i, email in ipairs(emails) do
    if tostring(email.id) == tostring(current.id) then
      current_idx = i
      break
    end
  end
  
  if current_idx and current_idx < #emails then
    -- View next email
    local next_email = emails[current_idx + 1]
    if next_email and next_email.id then
      -- Close current
      if vim.api.nvim_buf_is_valid(current.buf) then
        vim.api.nvim_buf_delete(current.buf, { force = true })
      end
      -- Open next
      M.view_email(next_email.id)
    end
  else
    notify.himalaya('No more emails', notify.categories.INFO)
  end
end

-- View previous email in list
function M.view_previous_email()
  local current = state.get('viewing_email')
  if not current then return end
  
  -- Get email list from sidebar
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_buf = sidebar.get_buf()
  if not sidebar_buf or not vim.api.nvim_buf_is_valid(sidebar_buf) then
    notify.himalaya('Email list not available', notify.categories.ERROR)
    return
  end
  
  local emails = state.get('email_list.emails')
  if not emails or #emails == 0 then return end
  
  -- Find current email index
  local current_idx = nil
  for i, email in ipairs(emails) do
    if tostring(email.id) == tostring(current.id) then
      current_idx = i
      break
    end
  end
  
  if current_idx and current_idx > 1 then
    -- View previous email
    local prev_email = emails[current_idx - 1]
    if prev_email and prev_email.id then
      -- Close current
      if vim.api.nvim_buf_is_valid(current.buf) then
        vim.api.nvim_buf_delete(current.buf, { force = true })
      end
      -- Open previous
      M.view_email(prev_email.id)
    end
  else
    notify.himalaya('No previous emails', notify.categories.INFO)
  end
end

-- Refresh current email
function M.refresh_current_email()
  local current = state.get('viewing_email')
  if not current then return end
  
  -- Reload email
  local email = utils.get_email_by_id(current.account, current.folder, current.id)
  if email and vim.api.nvim_buf_is_valid(current.buf) then
    M.render_email(current.buf, email)
    notify.himalaya('Email refreshed', notify.categories.INFO)
  end
end

-- Check if buffer is an email viewer buffer
function M.is_email_buffer(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  local name = vim.api.nvim_buf_get_name(buf)
  return name:match("^%[Email%]")
end

return M