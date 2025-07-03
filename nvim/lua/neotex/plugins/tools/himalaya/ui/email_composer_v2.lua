-- Buffer-based email composition with auto-save
local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local notify = require('neotex.util.notifications')

-- Module state
local composer_buffers = {}
local autosave_timers = {}

-- Configuration
M.config = {
  use_tab = true,  -- Open in current window (false = vsplit)
  auto_save_interval = 30,
  delete_draft_on_send = true,
  syntax_highlighting = true,
  draft_dir = vim.fn.expand('~/.local/share/himalaya/drafts/'),
}

-- Initialize module
function M.setup(cfg)
  if cfg and cfg.compose then
    M.config = vim.tbl_extend('force', M.config, cfg.compose)
  end
  
  -- Ensure draft directory exists
  vim.fn.mkdir(M.config.draft_dir, 'p')
  
  logger.debug('Email composer v2 initialized', { config = M.config })
end

-- Parse email buffer content
local function parse_email_buffer(lines)
  local email = {
    headers = {},
    body = '',
  }
  
  local in_body = false
  local body_lines = {}
  
  for _, line in ipairs(lines) do
    if in_body then
      table.insert(body_lines, line)
    elseif line == '' then
      -- Empty line marks end of headers
      in_body = true
    else
      -- Parse header
      local header, value = line:match('^([^:]+):%s*(.*)$')
      if header and value then
        email.headers[header:lower()] = value
      end
    end
  end
  
  email.body = table.concat(body_lines, '\n')
  
  -- Map common headers (handle vim.NIL)
  local function safe_value(val)
    if val == vim.NIL or val == 'vim.NIL' then
      return nil
    end
    return val
  end
  
  email.from = safe_value(email.headers.from)
  email.to = safe_value(email.headers.to)
  email.cc = safe_value(email.headers.cc)
  email.bcc = safe_value(email.headers.bcc)
  email.subject = safe_value(email.headers.subject)
  
  return email
end

-- Format email for display in buffer
local function format_email_template(opts)
  opts = opts or {}
  
  local account_name = state.get_current_account()
  local from = opts.from or config.get_account_email(account_name) or ''
  
  local lines = {
    'From: ' .. from,
    'To: ' .. (opts.to or ''),
    'Cc: ' .. (opts.cc or ''),
    'Bcc: ' .. (opts.bcc or ''),
    'Subject: ' .. (opts.subject or ''),
    'Date: ' .. os.date('%a, %d %b %Y %H:%M:%S %z'),
    '',  -- Empty line to separate headers from body
  }
  
  -- Add body content
  if opts.body then
    for line in opts.body:gmatch('[^\r\n]+') do
      table.insert(lines, line)
    end
  else
    -- Add signature if configured
    local signature = config.get('compose.signature')
    if signature then
      table.insert(lines, '')
      table.insert(lines, '--')
      for line in signature:gmatch('[^\r\n]+') do
        table.insert(lines, line)
      end
    end
  end
  
  return lines
end

-- Sync draft to maildir
local function sync_draft_to_maildir(draft_file)
  local account = state.get_current_account()
  local draft_folder = utils.find_draft_folder(account)
  
  if not draft_folder then
    logger.warn('No draft folder found for account', { account = account })
    return nil
  end
  
  -- Read draft content
  local content = vim.fn.readfile(draft_file)
  local email = parse_email_buffer(content)
  
  -- Save to maildir using himalaya
  local ok, result = pcall(utils.save_draft, account, draft_folder, email)
  if ok and result then
    logger.debug('Draft synced to maildir', { 
      file = draft_file,
      draft_id = result.id 
    })
    -- Show success notification in debug mode
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya('Draft synced to ' .. draft_folder, notify.categories.BACKGROUND)
    end
    return result.id
  else
    logger.error('Failed to sync draft', { 
      file = draft_file,
      error = result 
    })
    -- Show user-friendly notification about draft sync failure
    if not email.from or email.from == '' then
      notify.himalaya('Draft saved locally but not synced: Missing From address', notify.categories.WARNING)
    else
      notify.himalaya('Draft saved locally but sync failed: ' .. tostring(result), notify.categories.WARNING)
    end
    return nil
  end
end

-- Delete draft from maildir
local function delete_draft_from_maildir(account, draft_id)
  if not draft_id then return end
  
  local draft_folder = utils.find_draft_folder(account)
  if not draft_folder then return end
  
  local ok, err = pcall(utils.delete_email, account, draft_folder, draft_id)
  if not ok then
    logger.error('Failed to delete draft from maildir', {
      draft_id = draft_id,
      error = err
    })
  end
end

-- Setup auto-save for a buffer
local function setup_autosave(buf, draft_file)
  -- Clear any existing timer
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  local timer = vim.loop.new_timer()
  autosave_timers[buf] = timer
  
  -- Auto-save every N seconds
  timer:start(M.config.auto_save_interval * 1000, M.config.auto_save_interval * 1000, 
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        autosave_timers[buf] = nil
        return
      end
      
      if vim.api.nvim_buf_get_option(buf, 'modified') then
        -- Save to file
        vim.api.nvim_buf_call(buf, function()
          vim.cmd('silent write!')
        end)
        
        -- Sync to maildir
        local draft_info = composer_buffers[buf]
        if draft_info then
          draft_info.draft_id = sync_draft_to_maildir(draft_file)
          
          -- Update state
          state.set('compose.drafts.' .. buf, draft_info)
        end
        
        -- Notify in debug mode
        if notify.config.modules.himalaya.debug_mode then
          notify.himalaya('Draft auto-saved', notify.categories.BACKGROUND)
        end
      end
    end)
  )
end

-- Setup buffer keymaps and autocmds
local function setup_buffer_mappings(buf)
  local opts = { buffer = buf, noremap = true, silent = true }
  
  -- Only set up Tab navigation helper, other keymaps are in which-key
  vim.keymap.set('n', '<Tab>', function()
    -- Jump to next header field or body
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Find next field
    for i = line + 1, #lines do
      if lines[i] == '' then
        -- Jump to body
        vim.api.nvim_win_set_cursor(0, { i + 1, 0 })
        return
      elseif lines[i]:match('^[^:]+:%s*$') or lines[i]:match('^[^:]+:%s*$') then
        -- Jump to end of header line
        vim.api.nvim_win_set_cursor(0, { i, #lines[i] })
        return
      end
    end
  end, opts)
  
  -- Cleanup on buffer unload
  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = buf,
    callback = function()
      -- Stop autosave timer
      if autosave_timers[buf] then
        vim.loop.timer_stop(autosave_timers[buf])
        autosave_timers[buf] = nil
      end
      
      -- Cleanup state
      composer_buffers[buf] = nil
      state.set('compose.drafts.' .. buf, nil)
    end,
  })
end

-- Create email composition buffer
function M.compose_email(opts)
  opts = opts or {}
  
  -- Generate draft filename
  local timestamp = os.date('%Y%m%d_%H%M%S')
  local draft_file = M.config.draft_dir .. 'draft_' .. timestamp .. '.eml'
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, draft_file)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  
  -- Open buffer in appropriate window
  if M.config.use_tab then
    -- Check if we're in the sidebar
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local sidebar_win = sidebar.get_win()
    local current_win = vim.api.nvim_get_current_win()
    
    -- If in sidebar, move to next window (neo-tree style)
    if sidebar_win and current_win == sidebar_win then
      vim.cmd('wincmd w')
    end
    
    -- Now edit the buffer in the current window
    vim.cmd('buffer ' .. buf)
  else
    -- Use vertical split for wider editing area
    vim.cmd('vsplit')
    vim.api.nvim_win_set_buf(0, buf)
  end
  
  -- Initialize content
  local lines = format_email_template(opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Position cursor in To: field if empty
  if not opts.to then
    vim.api.nvim_win_set_cursor(0, { 2, 4 })  -- After "To: "
  elseif not opts.subject then
    vim.api.nvim_win_set_cursor(0, { 5, 9 })  -- After "Subject: "
  else
    -- Position in body
    vim.api.nvim_win_set_cursor(0, { 8, 0 })
  end
  
  -- Setup syntax highlighting
  if M.config.syntax_highlighting then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('syntax match mailHeader "^\\(From\\|To\\|Cc\\|Bcc\\|Subject\\|Date\\|Reply-To\\):"')
      vim.cmd('syntax match mailEmail "<[^>]\\+@[^>]\\+>"')
      vim.cmd('syntax match mailEmail "[a-zA-Z0-9._%+-]\\+@[a-zA-Z0-9.-]\\+\\.[a-zA-Z]\\{2,}"')
      vim.cmd('syntax region mailQuoted start="^>" end="$" contains=mailQuoted')
      vim.cmd('hi link mailHeader Keyword')
      vim.cmd('hi link mailEmail Underlined')
      vim.cmd('hi link mailQuoted Comment')
    end)
  end
  
  -- Store buffer info
  local draft_info = {
    file = draft_file,
    created = os.time(),
    account = state.get_current_account(),
    reply_to = opts.reply_to,
    forward_from = opts.forward_from,
  }
  
  composer_buffers[buf] = draft_info
  state.set('compose.drafts.' .. buf, draft_info)
  
  -- Setup mappings and auto-save
  setup_buffer_mappings(buf)
  setup_autosave(buf, draft_file)
  
  -- Initial save
  vim.cmd('silent write!')
  
  notify.himalaya('Composing email (auto-save enabled)', notify.categories.STATUS)
  
  return buf
end

-- Reply to email
function M.reply_email(email, reply_all)
  -- Format the quoted body
  local quoted_body = ''
  if email.body then
    -- Split body into lines and prefix each with "> "
    for line in email.body:gmatch("[^\r\n]*") do
      quoted_body = quoted_body .. '> ' .. line .. '\n'
    end
  else
    quoted_body = '> [No content]\n'
  end
  
  local opts = {
    to = email.from,
    subject = 'Re: ' .. (email.subject or ''),
    body = '\n\n' .. string.rep('-', 40) .. '\n' ..
           'On ' .. (email.date or 'Unknown date') .. ', ' .. 
           (email.from or 'Unknown') .. ' wrote:\n\n' ..
           quoted_body,
    reply_to = email.id,
  }
  
  if reply_all and email.cc then
    opts.cc = email.cc
  end
  
  return M.compose_email(opts)
end

-- Forward email
function M.forward_email(email)
  local opts = {
    subject = 'Fwd: ' .. (email.subject or ''),
    body = '\n\n' .. string.rep('-', 40) .. '\n' ..
           '---------- Forwarded message ----------\n' ..
           'From: ' .. (email.from or 'Unknown') .. '\n' ..
           'Date: ' .. (email.date or 'Unknown date') .. '\n' ..
           'Subject: ' .. (email.subject or '') .. '\n' ..
           'To: ' .. (email.to or '') .. '\n\n' ..
           (email.body or ''),
    forward_from = email.id,
  }
  
  return M.compose_email(opts)
end

-- Save draft manually
function M.save_draft(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    notify.himalaya('Not a compose buffer', notify.categories.ERROR)
    return
  end
  
  -- Save to file
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('write!')
  end)
  
  -- Sync to maildir
  draft_info.draft_id = sync_draft_to_maildir(draft_info.file)
  
  notify.himalaya('Draft saved', notify.categories.USER_ACTION)
end

-- Send email
function M.send_email(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    notify.himalaya('Not a compose buffer', notify.categories.ERROR)
    return
  end
  
  -- Save current content
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('write!')
  end)
  
  -- Parse email
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local email = parse_email_buffer(lines)
  
  -- Validate required fields
  if not email.to or email.to == '' then
    notify.himalaya('Please specify a recipient', notify.categories.ERROR)
    return
  end
  
  -- Show confirmation
  local misc = require('neotex.util.misc')
  if not misc.confirm('Send email to ' .. email.to .. '?', false) then
    return
  end
  
  -- Send email
  notify.himalaya('Sending email...', notify.categories.STATUS)
  
  local ok, result = pcall(utils.send_email, draft_info.account, email)
  
  if ok and result then
    notify.himalaya('Email sent successfully', notify.categories.USER_ACTION)
    
    -- Delete draft if configured
    if M.config.delete_draft_on_send then
      -- Delete file
      vim.fn.delete(draft_info.file)
      
      -- Delete from maildir
      if draft_info.draft_id then
        delete_draft_from_maildir(draft_info.account, draft_info.draft_id)
      end
    end
    
    -- Close buffer
    vim.api.nvim_buf_delete(buf, { force = true })
  else
    notify.himalaya('Failed to send email: ' .. tostring(result), notify.categories.ERROR)
  end
end

-- Discard email with modern confirmation dialog
function M.discard_email(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    notify.himalaya('Not a compose buffer', notify.categories.ERROR)
    return
  end
  
  -- Use simple confirmation prompt
  local misc = require('neotex.util.misc')
  local modified = vim.api.nvim_buf_get_option(buf, 'modified')
  local message = modified and 'Discard unsaved email draft?' or 'Discard email draft?'
  
  if not misc.confirm(message, true) then
    -- User cancelled or pressed Escape
    return
  end
  
  -- User pressed 'y', proceed with discard
  -- Stop autosave
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  -- Delete draft file
  vim.fn.delete(draft_info.file)
  
  -- Delete from maildir
  if draft_info.draft_id then
    delete_draft_from_maildir(draft_info.account, draft_info.draft_id)
  end
  
  -- Switch to alternate buffer before deleting (like :bd behavior)
  -- This prevents the sidebar from going full screen
  local current_win = vim.api.nvim_get_current_win()
  
  -- Get list of all buffers
  local buffers = vim.api.nvim_list_bufs()
  local alternate_buf = nil
  
  -- Find a suitable buffer to switch to
  for _, b in ipairs(buffers) do
    if b ~= buf and vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
      local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
      local filetype = vim.api.nvim_buf_get_option(b, 'filetype')
      -- Skip special buffers like the sidebar
      if buftype == '' and not filetype:match('^himalaya%-') then
        alternate_buf = b
        break
      end
    end
  end
  
  -- If no alternate buffer found, create a new empty one
  if not alternate_buf then
    alternate_buf = vim.api.nvim_create_buf(true, false)
  end
  
  -- Switch to the alternate buffer first
  vim.api.nvim_win_set_buf(current_win, alternate_buf)
  
  -- Now delete the draft buffer
  vim.api.nvim_buf_delete(buf, { force = true })
  
  notify.himalaya('Email discarded', notify.categories.STATUS)
end

-- Check if buffer is a compose buffer
function M.is_compose_buffer(buf)
  return composer_buffers[buf] ~= nil
end

-- Get all active compose buffers
function M.get_compose_buffers()
  local buffers = {}
  for buf, info in pairs(composer_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      table.insert(buffers, { buffer = buf, info = info })
    else
      -- Cleanup invalid buffer
      composer_buffers[buf] = nil
      if autosave_timers[buf] then
        vim.loop.timer_stop(autosave_timers[buf])
        autosave_timers[buf] = nil
      end
    end
  end
  return buffers
end

return M