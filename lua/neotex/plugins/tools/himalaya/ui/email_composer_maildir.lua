-- Email Composer Maildir - Simplified composition with Maildir storage
-- Direct file operations without JSON/EML complexity

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
local notify = require('neotex.util.notifications')
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_types = require('neotex.plugins.tools.himalaya.core.events')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local autosave_timers = {}

-- Configuration
M.config = {
  use_tab = true,
  auto_save_interval = 5,
  delete_draft_on_send = true,
  syntax_highlighting = true,
}

-- Initialize module
function M.setup(cfg)
  if cfg and cfg.compose then
    M.config = vim.tbl_extend('force', M.config, cfg.compose)
  end
  
  -- Initialize draft manager
  draft_manager.setup()
end

-- Create email template
local function create_email_template(opts)
  opts = opts or {}
  
  local account_name = opts.account or state.get_current_account()
  local from = opts.from or config.get_formatted_from(account_name) or ''
  
  local headers = {
    'From: ' .. from,
    'To: ' .. (opts.to or ''),
    'Cc: ' .. (opts.cc or ''),
    'Bcc: ' .. (opts.bcc or ''),
    'Subject: ' .. (opts.subject or ''),
    'Reply-To: ' .. (opts.reply_to or ''),
    'In-Reply-To: ' .. (opts.in_reply_to or ''),
    'References: ' .. (opts.references or '')
  }
  
  -- Filter out empty optional headers
  local filtered = {}
  for _, header in ipairs(headers) do
    local name, value = header:match('^([^:]+):%s*(.*)$')
    if name and value and value ~= '' then
      table.insert(filtered, header)
    end
  end
  
  -- Add empty line to separate headers from body
  table.insert(filtered, '')
  
  -- Add body if provided
  if opts.body then
    table.insert(filtered, opts.body)
  end
  
  return table.concat(filtered, '\n')
end

-- Create a new compose buffer
function M.create_compose_buffer(opts)
  opts = opts or {}
  local account = opts.account or state.get_current_account()
  
  -- Generate template content
  local template = create_email_template(opts)
  
  -- Create draft through Maildir manager
  local metadata = {
    from = opts.from or config.get_formatted_from(account),
    to = opts.to or '',
    cc = opts.cc or '',
    bcc = opts.bcc or '',
    subject = opts.subject or '',
    body = opts.body or ''
  }
  
  local buf, err = draft_manager.create(account, metadata)
  if not buf then
    notify.himalaya(
      'Failed to create draft: ' .. (err or 'unknown error'),
      notify.categories.ERROR
    )
    return nil
  end
  
  -- Setup buffer-local keymaps
  M.setup_compose_keymaps(buf)
  
  -- Setup autosave
  if M.config.auto_save_interval > 0 then
    M.setup_autosave(buf)
  end
  
  -- Apply syntax highlighting
  if M.config.syntax_highlighting then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  end
  
  -- Track in window stack
  window_stack.push({
    type = 'compose',
    buffer = buf,
    window = vim.api.nvim_get_current_win()
  })
  
  -- Position cursor
  M.position_cursor_on_empty_field(buf)
  
  logger.info('Created compose buffer', {
    buffer = buf,
    account = account
  })
  
  return buf
end

-- Setup buffer-local keymaps
function M.setup_compose_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }
  
  -- Save draft
  vim.keymap.set('n', '<C-s>', function()
    M.save_draft(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Save draft' }))
  
  -- Send email
  vim.keymap.set('n', '<leader>ms', function()
    M.send_email(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
  
  -- Cancel/close
  vim.keymap.set('n', '<leader>mc', function()
    M.close_compose_buffer(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Cancel compose' }))
  
  -- Delete draft
  vim.keymap.set('n', '<leader>md', function()
    M.delete_draft(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Delete draft' }))
end

-- Setup autosave for a buffer
function M.setup_autosave(buf)
  -- Clear any existing timer
  if autosave_timers[buf] then
    vim.fn.timer_stop(autosave_timers[buf])
  end
  
  -- Create new timer
  autosave_timers[buf] = vim.fn.timer_start(
    M.config.auto_save_interval * 1000,
    function()
      if vim.api.nvim_buf_is_valid(buf) and 
         vim.api.nvim_buf_get_option(buf, 'modified') then
        M.save_draft(buf, 'autosave')
      end
    end,
    { ['repeat'] = -1 }
  )
  
  -- Cleanup timer on buffer delete
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = buf,
    once = true,
    callback = function()
      if autosave_timers[buf] then
        vim.fn.timer_stop(autosave_timers[buf])
        autosave_timers[buf] = nil
      end
    end
  })
end

-- Save draft
function M.save_draft(buf, trigger)
  trigger = trigger or 'manual'
  
  local ok, err = draft_manager.save(buf)
  
  if not ok then
    notify.himalaya(
      'Failed to save draft: ' .. (err or 'unknown error'),
      notify.categories.ERROR
    )
    return false
  end
  
  -- Show notification for manual saves only
  if trigger == 'manual' then
    notify.himalaya(
      'Draft saved',
      notify.categories.USER_ACTION
    )
  end
  
  return true
end

-- Send email
function M.send_email(buf)
  -- Save draft first
  M.save_draft(buf)
  
  -- Send through draft manager
  local ok, err = draft_manager.send(buf)
  
  if not ok then
    notify.himalaya(
      'Failed to send email: ' .. (err or 'unknown error'),
      notify.categories.ERROR
    )
    return false
  end
  
  -- Close compose window
  M.close_compose_buffer(buf)
  
  return true
end

-- Close compose buffer
function M.close_compose_buffer(buf)
  -- Stop autosave timer
  if autosave_timers[buf] then
    vim.fn.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  -- Check if modified
  if vim.api.nvim_buf_get_option(buf, 'modified') then
    vim.ui.select({'Save and close', 'Discard changes', 'Cancel'}, {
      prompt = 'Draft has unsaved changes:'
    }, function(choice)
      if choice == 'Save and close' then
        M.save_draft(buf)
        vim.api.nvim_buf_delete(buf, { force = true })
      elseif choice == 'Discard changes' then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      -- Cancel does nothing
    end)
  else
    vim.api.nvim_buf_delete(buf, { force = false })
  end
end

-- Delete draft
function M.delete_draft(buf)
  vim.ui.select({'Yes', 'No'}, {
    prompt = 'Delete this draft?'
  }, function(choice)
    if choice == 'Yes' then
      draft_manager.delete(buf)
    end
  end)
end

-- Position cursor on first empty field
function M.position_cursor_on_empty_field(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Check To field
  for i, line in ipairs(lines) do
    if line:match('^To:%s*$') then
      vim.api.nvim_win_set_cursor(0, {i, vim.fn.col('$')})
      return
    end
  end
  
  -- Check Subject field
  for i, line in ipairs(lines) do
    if line:match('^Subject:%s*$') then
      vim.api.nvim_win_set_cursor(0, {i, vim.fn.col('$')})
      return
    end
  end
  
  -- Default to body (after empty line)
  for i, line in ipairs(lines) do
    if line == '' then
      vim.api.nvim_win_set_cursor(0, {i + 1, 0})
      return
    end
  end
end

-- Open existing draft for editing
function M.open_draft(filepath)
  local buf, err = draft_manager.open(filepath)
  
  if not buf then
    notify.himalaya(
      'Failed to open draft: ' .. (err or 'unknown error'),
      notify.categories.ERROR
    )
    return nil
  end
  
  -- Setup compose environment
  M.setup_compose_keymaps(buf)
  
  if M.config.auto_save_interval > 0 then
    M.setup_autosave(buf)
  end
  
  -- Track in window stack
  window_stack.push({
    type = 'compose',
    buffer = buf,
    window = vim.api.nvim_get_current_win()
  })
  
  return buf
end

-- Reply to email
function M.reply_to_email(original_email, reply_all)
  local opts = {}
  
  -- Set reply headers
  opts.to = original_email.from or original_email.sender
  
  if reply_all and original_email.to then
    -- Parse recipients and add to Cc
    local cc_list = {}
    
    -- Add original To recipients
    if original_email.to then
      table.insert(cc_list, original_email.to)
    end
    
    -- Add original Cc recipients
    if original_email.cc then
      table.insert(cc_list, original_email.cc)
    end
    
    opts.cc = table.concat(cc_list, ', ')
  end
  
  -- Set subject with Re: prefix
  local subject = original_email.subject or ''
  if not subject:match('^Re:%s') then
    subject = 'Re: ' .. subject
  end
  opts.subject = subject
  
  -- Set In-Reply-To and References
  opts.in_reply_to = original_email.message_id
  opts.references = original_email.references or ''
  if opts.references ~= '' then
    opts.references = opts.references .. ' '
  end
  opts.references = opts.references .. original_email.message_id
  
  -- Quote original message
  local quoted_body = M.quote_email_body(original_email)
  opts.body = '\n\n' .. quoted_body
  
  return M.create_compose_buffer(opts)
end

-- Quote email body for replies
function M.quote_email_body(email)
  local lines = {}
  
  -- Add attribution line
  local date = email.date or os.date('%a, %d %b %Y %H:%M:%S')
  local from = email.from or 'Unknown'
  table.insert(lines, string.format('On %s, %s wrote:', date, from))
  
  -- Quote body lines
  if email.body then
    for line in email.body:gmatch('[^\n]*') do
      table.insert(lines, '> ' .. line)
    end
  end
  
  return table.concat(lines, '\n')
end

-- Forward email
function M.forward_email(original_email)
  local opts = {}
  
  -- Set subject with Fwd: prefix
  local subject = original_email.subject or ''
  if not subject:match('^Fwd:%s') then
    subject = 'Fwd: ' .. subject
  end
  opts.subject = subject
  
  -- Create forwarded message body
  local fwd_lines = {
    '',
    '',
    '---------- Forwarded message ---------',
    'From: ' .. (original_email.from or 'Unknown'),
    'Date: ' .. (original_email.date or ''),
    'Subject: ' .. (original_email.subject or ''),
    'To: ' .. (original_email.to or ''),
    '',
    original_email.body or ''
  }
  
  opts.body = table.concat(fwd_lines, '\n')
  
  return M.create_compose_buffer(opts)
end

-- Get draft info for display
function M.get_draft_display_info(buf)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return nil
  end
  
  return {
    subject = draft.subject or 'Untitled',
    to = draft.to,
    from = draft.from,
    modified = vim.api.nvim_buf_get_option(buf, 'modified'),
    account = draft.account
  }
end

return M