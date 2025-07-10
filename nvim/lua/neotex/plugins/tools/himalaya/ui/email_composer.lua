-- Email Composer v2 - Refactored with new draft system
-- Simplified composition with unified draft management

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local draft_notifications = require('neotex.plugins.tools.himalaya.core.draft_notifications')
local draft_parser = require('neotex.plugins.tools.himalaya.core.draft_parser')
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack') -- Phase 6

-- Module state
local autosave_timers = {}

-- Configuration
M.config = {
  use_tab = true,
  auto_save_interval = 30,
  delete_draft_on_send = true,
  syntax_highlighting = true,
}

-- Initialize module
function M.setup(cfg)
  if cfg and cfg.compose then
    M.config = vim.tbl_extend('force', M.config, cfg.compose)
  end
  
  -- Initialize draft manager and local storage
  draft_manager.setup()
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  storage.setup()
end

-- Create email template lines
local function format_email_template(opts)
  opts = opts or {}
  
  local account_name = opts.account or state.get_current_account()
  local from = opts.from or config.get_formatted_from(account_name) or 
               draft_manager._get_default_from(account_name)
  
  local lines = {
    'From: ' .. from,
    'To: ' .. (opts.to or ''),
    'Cc: ' .. (opts.cc or ''),
    'Bcc: ' .. (opts.bcc or ''),
    'Subject: ' .. (opts.subject or ''),
    '',  -- Empty line to separate headers from body
  }
  
  -- Add body content
  if opts.body and opts.body ~= '' then
    local body_lines = vim.split(opts.body, '\n', { plain = true })
    vim.list_extend(lines, body_lines)
  end
  
  return lines
end

-- Setup autosave for a buffer
local function setup_autosave(buf)
  -- Clear any existing timer
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  local timer = vim.loop.new_timer()
  autosave_timers[buf] = timer
  
  -- Auto-save every N seconds
  timer:start(
    M.config.auto_save_interval * 1000,
    M.config.auto_save_interval * 1000,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        autosave_timers[buf] = nil
        return
      end
      
      -- Check if buffer is modified
      if vim.api.nvim_buf_get_option(buf, 'modified') then
        M.save_draft(buf, 'autosave')
      end
    end)
  )
end

-- Save draft (manual or auto)
function M.save_draft(buf, trigger)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return false, "No draft associated with buffer"
  end
  
  -- Debug notification for autosave
  if trigger == 'autosave' then
    draft_notifications.draft_autosave(draft.local_id, trigger)
  end
  
  -- Save to local storage first
  local ok, err = draft_manager.save_local(buf)
  if not ok then
    draft_notifications.draft_save_failed(draft.local_id, err)
    return false, err
  end
  
  -- Save buffer to file
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent write!')
  end)
  
  -- Mark buffer as unmodified
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  
  -- Queue remote sync
  vim.defer_fn(function()
    draft_manager.sync_remote(buf)
  end, 100)
  
  return true
end

-- Setup buffer keymaps and autocmds
local function setup_buffer_mappings(buf)
  local opts = { buffer = buf, noremap = true, silent = true }
  
  -- Tab navigation in insert mode
  vim.keymap.set('i', '<Tab>', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Find next field
    for i = line + 1, #lines do
      if lines[i] == '' then
        -- Jump to body
        vim.api.nvim_win_set_cursor(0, { i + 1, 0 })
        return
      elseif lines[i]:match('^[^:]+:%s*$') then
        -- Jump to end of header line
        vim.api.nvim_win_set_cursor(0, { i, #lines[i] })
        return
      end
    end
  end, opts)
  
  -- Manual save
  vim.keymap.set('n', '<C-s>', function()
    M.save_draft(buf, 'manual')
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
      
      -- Draft manager handles cleanup automatically via autocmd
    end
  })
  
  -- Handle window close for window stack (Phase 6)
  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = buf,
    once = true,
    callback = function()
      local current_config = config.get()
      if current_config.draft and current_config.draft.integration and 
         current_config.draft.integration.use_window_stack then
        window_stack.close_current()
      end
    end
  })
  
  -- Set filetype for syntax highlighting
  if M.config.syntax_highlighting then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  end
  
  -- Setup status line
  local compose_status = require('neotex.plugins.tools.himalaya.ui.compose_status')
  compose_status.setup_statusline(buf)
end

-- Export this function so compose_status can hook into it
M.setup_buffer_mappings = setup_buffer_mappings

-- Create compose buffer
function M.create_compose_buffer(opts)
  opts = opts or {}
  
  -- Generate unique filename with microsecond precision
  local timestamp = os.date('%Y%m%d_%H%M%S')
  local unique_id = vim.loop.hrtime()
  local draft_file = string.format('%s/draft_%s_%s.eml', 
    vim.fn.stdpath('data') .. '/himalaya/drafts', timestamp, unique_id)
  
  -- Ensure directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(draft_file, ':h'), 'p')
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, draft_file)
  
  -- Set initial content
  local lines = format_email_template(opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Create draft in manager
  local account = opts.account or state.get_current_account()
  local draft = draft_manager.create(buf, account, {
    subject = opts.subject,
    to = opts.to,
    from = opts.from,
    cc = opts.cc,
    bcc = opts.bcc,
    reply_to = opts.reply_to,
    compose_type = opts.compose_type or 'new'
  })
  
  -- Debug notification
  draft_notifications.debug_lifecycle('compose_buffer_created', draft.local_id, {
    buffer = buf,
    compose_type = opts.compose_type,
    account = account
  })
  
  -- Setup buffer
  setup_buffer_mappings(buf)
  setup_autosave(buf)
  
  -- Open buffer in window
  local parent_win = vim.api.nvim_get_current_win()
  
  if M.config.use_tab then
    vim.cmd('tabnew')
  else
    vim.cmd('vsplit')
  end
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Track window in stack if enabled (Phase 6)
  local current_config = config.get()
  if current_config.draft and current_config.draft.integration and 
     current_config.draft.integration.use_window_stack then
    local win_id = vim.api.nvim_get_current_win()
    window_stack.push_draft(win_id, draft.local_id, parent_win)
  end
  
  -- Position cursor on To: field if empty
  if not opts.to or opts.to == '' then
    vim.api.nvim_win_set_cursor(0, { 2, 4 })
  else
    -- Position at end of headers
    vim.api.nvim_win_set_cursor(0, { 6, 0 })
  end
  
  -- Start in insert mode
  vim.cmd('startinsert!')
  
  -- Save immediately to create draft
  vim.defer_fn(function()
    M.save_draft(buf, 'initial')
  end, 100)
  
  return buf
end

-- Open existing draft
function M.open_draft(draft_id, account)
  -- Load draft data
  local draft_data, err = draft_manager.load(draft_id, account)
  if not draft_data then
    draft_notifications.draft_load_failed(draft_id, err)
    return nil
  end
  
  -- Create buffer with draft content
  local lines = format_email_template({
    to = draft_data.metadata.to,
    from = draft_data.metadata.from,
    cc = draft_data.metadata.cc,
    bcc = draft_data.metadata.bcc,
    subject = draft_data.metadata.subject,
    body = draft_data.content
  })
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  local draft_file = string.format('%s/draft_%s.eml',
    vim.fn.stdpath('data') .. '/himalaya/drafts', draft_id)
  vim.api.nvim_buf_set_name(buf, draft_file)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Create draft in manager
  local draft = draft_manager.create(buf, account, {
    subject = draft_data.metadata.subject,
    to = draft_data.metadata.to,
    from = draft_data.metadata.from,
    cc = draft_data.metadata.cc,
    bcc = draft_data.metadata.bcc,
    compose_type = 'edit'
  })
  
  -- Set remote ID
  draft.remote_id = tostring(draft_id)
  draft.state = draft_manager.states.SYNCED
  
  -- Debug notification
  draft_notifications.debug_lifecycle('draft_opened', draft.local_id, {
    remote_id = draft_id,
    buffer = buf
  })
  
  -- Setup buffer
  setup_buffer_mappings(buf)
  setup_autosave(buf)
  
  -- Open buffer
  local parent_win = vim.api.nvim_get_current_win()
  
  if M.config.use_tab then
    vim.cmd('tabnew')
  else
    vim.cmd('vsplit')
  end
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Track window in stack if enabled (Phase 6)
  local current_config = config.get()
  if current_config.draft and current_config.draft.integration and 
     current_config.draft.integration.use_window_stack then
    local win_id = vim.api.nvim_get_current_win()
    window_stack.push_draft(win_id, draft.local_id, parent_win)
  end
  
  return buf
end

-- Send email and close buffer
function M.send_and_close(buf)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return false, "No draft associated with buffer"
  end
  
  -- Parse current buffer content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local email = draft_parser.parse_email(lines)
  
  -- Schedule email
  local schedule_time = os.time() + 60 -- 1 minute from now
  local scheduled_id = scheduler.schedule_email({
    account = draft.account,
    email = {
      to = email.to,
      from = email.from,
      cc = email.cc,
      bcc = email.bcc,
      subject = email.subject,
      body = email.body
    }
  }, schedule_time)
  
  if scheduled_id then
    -- Delete draft if configured
    if M.config.delete_draft_on_send and draft.remote_id then
      draft_manager.delete(buf)
    end
    
    -- User notification
    draft_notifications.draft_sent(email.subject, email.to)
    
    -- Close buffer
    M.close_compose_buffer(buf)
    
    return true
  else
    return false, "Failed to schedule email"
  end
end

-- Close compose buffer
function M.close_compose_buffer(buf)
  -- Stop autosave
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  -- Close window and buffer
  local wins = vim.fn.win_findbuf(buf)
  for _, win in ipairs(wins) do
    vim.api.nvim_win_close(win, true)
  end
  
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Check if buffer is a compose buffer
function M.is_compose_buffer(buf)
  return draft_manager.has_draft(buf)
end

-- Get all compose buffers
function M.get_compose_buffers()
  local buffers = {}
  local all_drafts = draft_manager.get_all()
  
  for _, draft in ipairs(all_drafts) do
    if vim.api.nvim_buf_is_valid(draft.buffer) then
      table.insert(buffers, draft.buffer)
    end
  end
  
  return buffers
end

-- Force cleanup (for testing)
function M.force_cleanup_compose_buffer(buf)
  -- First switch to a different buffer
  local buffers = vim.api.nvim_list_bufs()
  for _, b in ipairs(buffers) do
    if b ~= buf and vim.api.nvim_buf_is_valid(b) and
       vim.api.nvim_buf_get_option(b, 'buflisted') then
      -- Switch to this buffer in all windows showing the compose buffer
      local wins = vim.fn.win_findbuf(buf)
      for _, win in ipairs(wins) do
        vim.api.nvim_win_set_buf(win, b)
      end
      break
    end
  end
  
  -- Now close the compose buffer
  M.close_compose_buffer(buf)
end

return M