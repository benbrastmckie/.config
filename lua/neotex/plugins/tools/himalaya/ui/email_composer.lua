-- Email Composer Maildir - Simplified composition with Maildir storage
-- Direct file operations without JSON/EML complexity

local M = {}

-- Dependencies
local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
local notify = require('neotex.util.notifications')
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local events_bus = require('neotex.plugins.tools.himalaya.commands.orchestrator')
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
  
  -- Keep all headers but filter out truly optional ones (Reply-To, In-Reply-To, References)
  local filtered = {}
  for _, header in ipairs(headers) do
    local name, value = header:match('^([^:]+):%s*(.*)$')
    if name then
      -- Always include From, To, Cc, Bcc, Subject
      if name:match('^(From|To|Cc|Bcc|Subject)$') then
        table.insert(filtered, header)
      -- Only include optional headers if they have values
      elseif value and value ~= '' then
        table.insert(filtered, header)
      end
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
  
  -- Don't manage windows here - let the caller handle it
  -- The main.compose_email function will handle window placement
  
  logger.info('Created compose buffer', {
    buffer = buf,
    account = account
  })
  
  return buf
end

-- Setup buffer-local keymaps
function M.setup_compose_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Register compose-specific keymaps with which-key for menu visibility
  -- These use buffer-local registration to appear only in compose buffers
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰇮", buffer = buf },
      { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "󰆓", buffer = buf },
      { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "󰚌", buffer = buf },
    })
  end

  -- Override write behavior to use draft save
  -- This hooks into your existing <leader>w save workflow
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      M.save_draft(buf, 'manual')
      return true  -- Prevent default write behavior
    end,
    desc = 'Save draft when using :w or <leader>w'
  })
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
        M.save_draft(buf, 'auto')
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
  
  local ok, err = draft_manager.save(buf, trigger == 'auto')
  
  if not ok then
    notify.himalaya(
      'Failed to save draft: ' .. (err or 'unknown error'),
      notify.categories.ERROR
    )
    return false
  end
  
  -- Notification is handled by draft_manager.save() when silent=false
  -- No need to duplicate notification here
  
  return true
end

-- Send email
function M.send_email(buf)
  -- Stop autosave timer to prevent duplicate saves
  if autosave_timers[buf] then
    vim.fn.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  -- Save draft first (manual save, no notification)
  M.save_draft(buf, 'auto')
  
  -- Get draft info
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    notify.himalaya(
      'Failed to send email: No draft associated with buffer',
      notify.categories.ERROR
    )
    return false
  end
  
  -- Read the draft file to get the email content
  local file = io.open(draft.filepath, 'r')
  if not file then
    notify.himalaya(
      'Failed to send email: Cannot read draft file',
      notify.categories.ERROR
    )
    return false
  end
  
  local content = file:read('*all')
  file:close()
  
  -- Parse email headers and body
  local headers = {}
  local body = ''
  local in_body = false
  
  -- Split content into lines, preserving empty lines
  local lines = vim.split(content, '\n', { plain = true })
  
  for _, line in ipairs(lines) do
    if in_body then
      body = body .. line .. '\n'
    elseif line == '' then
      in_body = true
    else
      local key, value = line:match('^([^:]+):%s*(.*)$')
      if key then
        headers[key:lower()] = value
      end
    end
  end
  
  -- Prepare email data for scheduler
  local email_data = {
    from = headers.from or '',
    to = headers.to or '',
    cc = headers.cc,
    bcc = headers.bcc,
    subject = headers.subject or '',
    body = body:gsub('\n$', '') -- Remove trailing newline
  }
  
  -- Schedule email with 60 second delay (same as old composer)
  local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
  local scheduled_id = scheduler.schedule_email(
    email_data,
    draft.account,
    {
      delay = 60, -- 1 minute delay
      metadata = {
        draft_filepath = draft.filepath,
        draft_buffer = buf
      }
    }
  )
  
  if not scheduled_id then
    notify.himalaya(
      'Failed to schedule email',
      notify.categories.ERROR
    )
    -- Restart autosave if send failed
    M.setup_autosave(buf)
    return false
  end
  
  -- Store draft info for cleanup after actual send (not just scheduling)
  if M.config.delete_draft_on_send then
    local draft = draft_manager.get_by_buffer(buf)
    if draft then
      -- Store the draft path with the scheduled email for later cleanup
      local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
      scheduler.register_draft_for_cleanup(scheduled_id, draft.filepath)
    end
  end
  
  -- Email scheduled successfully, close compose window
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
  
  -- Check if buffer is still valid
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Store the current window before closing
  local current_win = vim.api.nvim_get_current_win()
  local compose_win = nil
  
  -- Find the window containing this buffer
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      compose_win = win
      break
    end
  end
  
  -- Check if modified
  local is_modified = false
  local ok, modified = pcall(vim.api.nvim_buf_get_option, buf, 'modified')
  if ok then
    is_modified = modified
  end
  
  if is_modified then
    vim.ui.select({'Save and close', 'Discard changes', 'Cancel'}, {
      prompt = 'Draft has unsaved changes:'
    }, function(choice)
      if choice == 'Save and close' then
        M.save_draft(buf)
        M._do_close_buffer(buf, compose_win)
      elseif choice == 'Discard changes' then
        M._do_close_buffer(buf, compose_win)
      end
      -- Cancel does nothing
    end)
  else
    M._do_close_buffer(buf, compose_win)
  end
end

-- Helper to actually close the buffer and manage window focus
function M._do_close_buffer(buf, compose_win)
  -- Find the sidebar window
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  
  -- Find a suitable buffer to show instead of compose buffer
  local function find_alternate_buffer()
    local bufs = vim.api.nvim_list_bufs()
    for _, b in ipairs(bufs) do
      if b ~= buf and vim.api.nvim_buf_is_valid(b) and
         vim.api.nvim_buf_get_option(b, 'buflisted') and
         vim.api.nvim_buf_get_option(b, 'buftype') == '' then
        -- Skip the sidebar buffer
        local is_sidebar = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == b and win == sidebar_win then
            is_sidebar = true
            break
          end
        end
        if not is_sidebar then
          return b
        end
      end
    end
    -- If no suitable buffer found, create a new one
    return vim.api.nvim_create_buf(true, false)
  end
  
  -- If compose_win exists and is valid, replace its buffer before deleting
  if compose_win and vim.api.nvim_win_is_valid(compose_win) then
    local alt_buf = find_alternate_buffer()
    vim.api.nvim_win_set_buf(compose_win, alt_buf)
    
    -- Ensure we're focused on the compose window (not sidebar)
    if vim.api.nvim_get_current_win() == sidebar_win then
      vim.api.nvim_set_current_win(compose_win)
    end
  end
  
  -- Now safely delete the compose buffer
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  
  -- Final check: ensure we're not focused on the sidebar
  local current_win = vim.api.nvim_get_current_win()
  if current_win == sidebar_win then
    -- Find a non-sidebar window to focus
    local found_window = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win ~= sidebar_win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        found_window = true
        break
      end
    end
    
    -- If no other window exists, create a new window to the right of sidebar
    if not found_window then
      -- Focus the sidebar first to ensure proper split behavior
      vim.api.nvim_set_current_win(sidebar_win)
      
      -- Create a vertical split to the right of the sidebar
      vim.cmd('rightbelow vertical new')
      
      -- The new window should now be focused automatically
    end
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

-- Position cursor in email body (for replies)
function M.position_cursor_in_body(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Find empty line that separates headers from body
  for i, line in ipairs(lines) do
    if line == '' then
      -- Position cursor at the start of body (line after empty line)
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
  if original_email.message_id then
    opts.in_reply_to = original_email.message_id
    opts.references = original_email.references or ''
    if opts.references ~= '' then
      opts.references = opts.references .. ' '
    end
    opts.references = opts.references .. original_email.message_id
  end
  
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

-- Check if buffer is a compose buffer
function M.is_compose_buffer(buf)
  return draft_manager.is_draft(buf)
end

return M