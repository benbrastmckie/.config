-- Buffer-based email composition with auto-save
-- TODO: Add attachment support for composition
-- TODO: Implement address book integration and auto-completion
-- TODO: Add email templates and signatures management
-- TODO: Implement spell checking and grammar checking integration
-- TODO: Add email encryption support (PGP/GPG)

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
  
  for i, line in ipairs(lines) do
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
      else
        -- If we encounter a line that's not a header and we haven't found empty line yet,
        -- this might be a malformed email - start body here
        logger.debug('Non-header line found before empty line', { 
          line_num = i, 
          line = line 
        })
        in_body = true
        table.insert(body_lines, line)
      end
    end
  end
  
  email.body = table.concat(body_lines, '\n')
  
  -- Debug what we parsed
  logger.debug('Parsed email buffer', {
    header_count = vim.tbl_count(email.headers),
    headers = email.headers,
    body_length = #email.body,
    body_preview = email.body:sub(1, 100)
  })
  
  -- Map common headers (handle vim.NIL but keep empty strings)
  local function safe_value(val)
    if val == vim.NIL or val == 'vim.NIL' then
      return ''
    end
    return val or ''
  end
  
  email.from = safe_value(email.headers.from)
  email.to = safe_value(email.headers.to)
  email.cc = safe_value(email.headers.cc)
  email.bcc = safe_value(email.headers.bcc)
  email.subject = safe_value(email.headers.subject)
  
  -- Ensure body is not nil
  if not email.body then
    email.body = ''
  end
  
  return email
end

-- Format email for display in buffer
local function format_email_template(opts)
  opts = opts or {}
  
  local account_name = state.get_current_account()
  local from = opts.from or config.get_formatted_from(account_name) or ''
  
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
    -- Handle body content line by line, preserving empty lines
    -- Use a different pattern that correctly handles empty lines
    local body_lines = vim.split(opts.body, '\n', { plain = true })
    for _, line in ipairs(body_lines) do
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
local function sync_draft_to_maildir(draft_file, account)
  -- Use provided account or fallback to current account
  account = account or state.get_current_account()
  
  if not account then
    logger.warn('No account specified for draft sync')
    return nil
  end
  
  local draft_folder = utils.find_draft_folder(account)
  
  if not draft_folder then
    logger.warn('No draft folder found for account', { account = account })
    return nil
  end
  
  -- Read draft content
  local content = vim.fn.readfile(draft_file)
  
  -- Debug: log raw file content
  logger.debug('Draft file raw content', {
    file = draft_file,
    line_count = #content,
    first_lines = vim.list_slice(content, 1, 10)
  })
  
  local email = parse_email_buffer(content)
  
  -- Make sure we have all the required fields
  if not email.from or email.from == '' then
    -- Try to get from account config
    email.from = config.get_formatted_from(account)
  end
  
  -- Debug logging
  logger.debug('Syncing draft to maildir', {
    file = draft_file,
    account = account,
    folder = draft_folder,
    has_body = email.body ~= nil and email.body ~= '',
    body_length = email.body and #email.body or 0,
    subject = email.subject,
    from = email.from,
    to = email.to
  })
  
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
        if draft_info and draft_info.file then
          -- If we have an existing draft ID, delete the old one first
          if draft_info.draft_id then
            delete_draft_from_maildir(draft_info.account, draft_info.draft_id)
          end
          
          -- Create new draft
          draft_info.draft_id = sync_draft_to_maildir(draft_info.file, draft_info.account)
          
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
  
  -- Only set up Tab navigation helper for insert mode, other keymaps are in which-key
  vim.keymap.set('i', '<Tab>', function()
    -- Jump to next header field or body
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Find next field
    for i = line + 1, #lines do
      if lines[i] == '' then
        -- Jump to body and stay in insert mode
        vim.api.nvim_win_set_cursor(0, { i + 1, 0 })
        return
      elseif lines[i]:match('^[^:]+:%s*$') or lines[i]:match('^[^:]+:%s*$') then
        -- Jump to end of header line and stay in insert mode
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
  
  -- If no template specified and no content, offer template selection
  if not opts.template_id and not opts.to and not opts.subject and not opts.body then
    local templates = require('neotex.plugins.tools.himalaya.core.templates')
    local template_list = templates.get_templates()
    
    if vim.tbl_count(template_list) > 0 then
      vim.ui.select({"Start from template", "Start blank"}, {
        prompt = "How would you like to compose this email?",
        format_item = function(item)
          if item == "Start from template" then
            return "📧 " .. item
          else
            return "📝 " .. item
          end
        end
      }, function(choice)
        if choice == "Start from template" then
          templates.pick_template(function(template_id, variables)
            local result = templates.apply_template(template_id, variables)
            if result then
              opts.to = result.to
              opts.cc = result.cc
              opts.bcc = result.bcc
              opts.subject = result.subject
              opts.body = result.body
              opts.template_id = template_id
              M.create_compose_buffer(opts)
            end
          end)
          return
        else
          M.create_compose_buffer(opts)
        end
      end)
      return
    end
  end
  
  M.create_compose_buffer(opts)
end

-- Create email composition buffer (internal function)
function M.create_compose_buffer(opts)
  opts = opts or {}
  
  -- Use existing draft file if reopening, otherwise create new
  local draft_file
  if opts.is_draft_reopen and opts.existing_draft_file then
    draft_file = opts.existing_draft_file
  else
    -- Generate new draft filename
    local timestamp = os.date('%Y%m%d_%H%M%S')
    draft_file = M.config.draft_dir .. 'draft_' .. timestamp .. '.eml'
  end
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, draft_file)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  
  -- Open buffer in appropriate window
  if M.config.use_tab then
    -- Check if we're in the sidebar or preview
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
    local sidebar_win = sidebar.get_win()
    local current_win = vim.api.nvim_get_current_win()
    
    -- Store if we're in preview to maintain it
    local preview_win = preview.ensure_preview_window()
    local in_preview = preview_win and current_win == preview_win
    
    -- If in sidebar or preview, move to main window
    if sidebar_win and (current_win == sidebar_win or in_preview) then
      -- Find a non-sidebar, non-preview window
      local found_main = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= sidebar_win and win ~= preview_win then
          vim.api.nvim_set_current_win(win)
          found_main = true
          break
        end
      end
      
      -- If no main window found, create one
      if not found_main then
        vim.cmd('wincmd w')
      end
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
  
  -- Ensure buffer always has the empty line separator
  -- This is critical for proper email format
  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local has_separator = false
  for i, line in ipairs(buf_lines) do
    if line == '' then
      has_separator = true
      break
    end
  end
  if not has_separator then
    -- Add empty line after headers if missing
    table.insert(buf_lines, 6, '')  -- After the 5 header lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
  end
  
  -- Position cursor in To: field if empty
  local line_count = vim.api.nvim_buf_line_count(buf)
  if not opts.to or opts.to == '' then
    vim.api.nvim_win_set_cursor(0, { math.min(2, line_count), 4 })  -- After "To: "
  elseif not opts.subject or opts.subject == '' then
    vim.api.nvim_win_set_cursor(0, { math.min(5, line_count), 9 })  -- After "Subject: "
  else
    -- Position cursor at beginning of body (after empty line)
    -- Find the empty line that separates headers from body
    local body_line = 7  -- Default position
    for i = 1, line_count do
      if lines[i] == '' then
        body_line = i + 1
        break
      end
    end
    vim.api.nvim_win_set_cursor(0, { math.min(body_line, line_count), 0 })
  end
  
  -- Setup syntax highlighting
  if M.config.syntax_highlighting then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('syntax match mailHeader "^\\\\(From\\\\|To\\\\|Cc\\\\|Bcc\\\\|Subject\\\\|Date\\\\|Reply-To\\\\):"')
      vim.cmd('syntax match mailEmail "<[^>]\\\\+@[^>]\\\\+>"')
      vim.cmd('syntax match mailEmail "[a-zA-Z0-9._%+-]\\\\+@[a-zA-Z0-9.-]\\\\+\\\\.[a-zA-Z]\\\\{2,}"')
      vim.cmd('syntax region mailQuoted start="^>" end="$" contains=mailQuoted')
      vim.cmd('hi link mailHeader Keyword')
      vim.cmd('hi link mailEmail Underlined')
      vim.cmd('hi link mailQuoted Comment')
    end)
  end
  
  -- Store buffer info
  local current_account = state.get_current_account() or config.get_current_account_name() or 'gmail'
  local draft_info = {
    file = draft_file,
    created = os.time(),
    account = current_account,
    reply_to = opts.reply_to,
    forward_from = opts.forward_from,
    template_id = opts.template_id,
  }
  
  composer_buffers[buf] = draft_info
  state.set('compose.drafts.' .. buf, draft_info)
  
  -- Setup mappings and auto-save
  setup_buffer_mappings(buf)
  setup_autosave(buf, draft_file)
  
  -- Initial save
  vim.cmd('silent write!')
  
  -- Initial sync to maildir
  draft_info.draft_id = sync_draft_to_maildir(draft_file, draft_info.account)
  if draft_info.draft_id then
    state.set('compose.drafts.' .. buf, draft_info)
  end
  
  local message = 'Composing email (auto-save enabled)'
  if opts.template_id then
    local templates = require('neotex.plugins.tools.himalaya.core.templates')
    local template = templates.get_template(opts.template_id)
    if template then
      message = string.format('Composing from template: %s', template.name)
    end
  end
  
  notify.himalaya(message, notify.categories.STATUS)
  
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
  
  -- Start with empty lines for user to type their reply
  local reply_body = '\n\n\n' .. string.rep('-', 40) .. '\n' ..
                     'On ' .. (email.date or 'Unknown date') .. ', ' .. 
                     (email.from or 'Unknown') .. ' wrote:\n\n' ..
                     quoted_body
  
  local opts = {
    to = email.from,
    subject = 'Re: ' .. (email.subject or ''),
    body = reply_body,
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
  
  -- Force save to file to ensure latest content is written
  vim.api.nvim_buf_call(buf, function()
    -- Mark as modified to force write even if vim thinks it's not
    vim.bo.modified = true
    vim.cmd('write!')
  end)
  
  -- Wait a moment to ensure file is written
  vim.wait(100)
  
  -- Debug: Check what was actually saved
  local saved_content = vim.fn.readfile(draft_info.file)
  logger.debug('Draft file content after save', {
    file = draft_info.file,
    line_count = #saved_content,
    first_10_lines = vim.list_slice(saved_content, 1, 10),
    has_empty_line = vim.tbl_contains(saved_content, ''),
    empty_line_position = vim.fn.index(saved_content, '')
  })
  
  -- If we have an existing draft ID, we need to update it instead of creating a new one
  if draft_info.draft_id then
    -- Delete the old draft from maildir first
    delete_draft_from_maildir(draft_info.account, draft_info.draft_id)
  end
  
  -- Sync to maildir (this creates a new draft)
  draft_info.draft_id = sync_draft_to_maildir(draft_info.file, draft_info.account)
  
  -- Update stored draft info
  if draft_info.draft_id then
    composer_buffers[buf] = draft_info
    state.set('compose.drafts.' .. buf, draft_info)
  end
  
  notify.himalaya('Draft saved', notify.categories.USER_ACTION)
end

-- Send email with scheduling (no immediate send)
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
  
  -- Show scheduling options (no immediate send)
  M.show_scheduling_options(buf, draft_info, email)
end

-- Send email immediately (original behavior)
function M.send_immediate(buf, draft_info, email)
  notify.himalaya('Sending email...', notify.categories.STATUS)
  
  local ok, result = pcall(utils.send_email, draft_info.account, email)
  
  if ok and result then
    notify.himalaya('✅ Email sent immediately', notify.categories.USER_ACTION)
    M.cleanup_after_send(buf, draft_info)
  else
    notify.himalaya('❌ Failed to send email: ' .. tostring(result), notify.categories.ERROR)
  end
end

-- Send email with undo capability (60-second delay)
function M.send_with_undo(buf, draft_info, email)
  local send_queue = require('neotex.plugins.tools.himalaya.core.send_queue')
  
  -- Queue email for delayed send
  local queue_id = send_queue.queue_email(email, draft_info.account)
  
  if queue_id then
    -- Set up callback for successful send
    local original_queue = send_queue.queue[queue_id]
    if original_queue then
      -- Store cleanup info for when email is actually sent
      original_queue.composer_cleanup = {
        buf = buf,
        draft_info = draft_info
      }
    end
    
    -- Show queue status option
    notify.himalaya(
      "📨 Email queued with undo option. Use :HimalayaSendQueue to manage",
      notify.categories.USER_ACTION
    )
    
    -- Close composition buffer after queuing
    M.cleanup_after_send(buf, draft_info)
  else
    notify.himalaya('❌ Failed to queue email', notify.categories.ERROR)
  end
end

-- Scheduling options (no immediate send)
function M.show_scheduling_options(buf, draft_info, email)
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  local options = {
    "1 minute (default)",
    "5 minutes",
    "30 minutes",
    "1 hour",
    "2 hours",
    "Tomorrow morning (9 AM)",
    "Custom time...",
    "Cancel"
  }
  
  vim.ui.select(options, {
    prompt = " When to send?",
    format_item = function(item)
      if item:match("Cancel") then
        return " " .. item
      else
        return " " .. item
      end
    end
  }, function(choice, idx)
    if not choice or choice == "Cancel" then
      return
    end
    
    local delay
    if idx == 1 then
      delay = 60        -- 1 minute
    elseif idx == 2 then
      delay = 300       -- 5 minutes
    elseif idx == 3 then
      delay = 1800      -- 30 minutes
    elseif idx == 4 then
      delay = 3600      -- 1 hour
    elseif idx == 5 then
      delay = 7200      -- 2 hours
    elseif idx == 6 then
      -- Tomorrow morning
      delay = M.calculate_delay_until_tomorrow(9, 0)
    elseif idx == 7 then
      -- Custom time picker
      M.show_custom_schedule_picker(buf, draft_info, email)
      return
    end
    
    -- Schedule the email
    local queue_id = scheduler.schedule_email(email, draft_info.account, {
      delay = delay,
      metadata = {
        draft_file = draft_info.file,
        draft_id = draft_info.draft_id,
        draft_account = draft_info.account
      }
    })
    
    if queue_id then
      -- Clean up composer (notification is handled by scheduler)
      M.cleanup_after_queue(buf, draft_info)
    end
  end)
end

-- Calculate delay until tomorrow at specific time
function M.calculate_delay_until_tomorrow(hour, minute)
  local now = os.time()
  local tomorrow = now + 86400
  local date = os.date("*t", tomorrow)
  date.hour = hour
  date.min = minute
  date.sec = 0
  
  local target = os.time(date)
  return target - now
end

-- Custom time picker (placeholder for Phase 2)
function M.show_custom_schedule_picker(buf, draft_info, email)
  local current = os.date("%Y-%m-%d %H:%M", os.time() + 3600) -- Default to 1 hour from now
  
  vim.ui.input({
    prompt = "Send time (YYYY-MM-DD HH:MM): ",
    default = current,
  }, function(input)
    if not input then return end
    
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    local new_time = M.parse_time_input(input)
    if new_time then
      local delay = new_time - os.time()
      if delay > 0 then
        local queue_id = scheduler.schedule_email(email, draft_info.account, {
          delay = delay,
          metadata = {
            composer_cleanup = {
              buf = buf,
              draft_info = draft_info
            }
          }
        })
        
        if queue_id then
          M.cleanup_after_queue(buf, draft_info)
        end
      else
        notify.himalaya("Time must be in the future", notify.categories.ERROR)
      end
    else
      notify.himalaya("Invalid time format", notify.categories.ERROR, {
        input = input,
        expected_format = "YYYY-MM-DD HH:MM"
      })
    end
  end)
end

-- Parse time input
function M.parse_time_input(input)
  local year, month, day, hour, min = input:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
  if year and month and day and hour and min then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = 0
    })
  end
  return nil
end

-- Common cleanup after queuing
function M.cleanup_after_queue(buf, draft_info)
  -- Delete draft if configured
  if M.config.delete_draft_on_send then
    -- Delete file
    vim.fn.delete(draft_info.file)
    
    -- Delete from maildir
    if draft_info.draft_id then
      delete_draft_from_maildir(draft_info.account, draft_info.draft_id)
    end
  end
  
  -- Switch to alternate buffer before deleting (like :bd behavior)
  -- This prevents the sidebar from going full screen
  M.switch_to_normal_buffer(buf)
  
  -- Close compose buffer safely
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
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
  
  -- Use async confirmation prompt
  local modified = vim.api.nvim_buf_get_option(buf, 'modified')
  local message = modified and 'unsaved email draft' or 'email draft'
  local prompt = string.format(" Discard %s?", message)
  
  vim.ui.select({"No", "Yes"}, {
    prompt = prompt,
    kind = "confirmation",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice ~= "Yes" then
      -- User cancelled
      return
    end
    
    -- User selected Yes, proceed with discard
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
    M.switch_to_normal_buffer(buf)
    
    -- Now delete the draft buffer
    vim.api.nvim_buf_delete(buf, { force = true })
  
    notify.himalaya('Email discarded', notify.categories.STATUS)
  end)
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

-- Force cleanup a compose buffer (for tests and edge cases)
-- This bypasses confirmation but uses proper buffer switching
function M.force_cleanup_compose_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    -- Not a compose buffer, just delete it
    vim.api.nvim_buf_delete(buf, { force = true })
    return
  end
  
  -- Stop autosave
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  -- Switch to normal buffer before cleanup
  M.switch_to_normal_buffer(buf)
  
  -- Clean up state
  composer_buffers[buf] = nil
  state.set('compose.drafts.' .. buf, nil)
  
  -- Delete the buffer
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_set_option(buf, 'modified', false)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Close compose buffer properly
function M.close_compose_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Switch to a normal buffer first
  M.switch_to_normal_buffer(buf)
  
  -- Clean up the compose buffer
  local draft_info = composer_buffers[buf]
  if draft_info then
    -- Stop autosave timer
    if autosave_timers[buf] then
      vim.loop.timer_stop(autosave_timers[buf])
      autosave_timers[buf] = nil
    end
    
    -- Clean up state
    composer_buffers[buf] = nil
    state.set('compose.drafts.' .. buf, nil)
  end
  
  -- Delete the buffer
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_option(buf, 'modified', false)
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
end

-- Switch to a normal buffer before closing a compose buffer
-- This prevents the sidebar from expanding to full screen
function M.switch_to_normal_buffer(closing_buf)
  local current_win = vim.api.nvim_get_current_win()
  
  -- Debug logging
  logger.debug('switch_to_normal_buffer called', {
    closing_buf = closing_buf,
    current_win = current_win,
    win_count = #vim.api.nvim_list_wins()
  })
  
  -- Check if we're in a special window (sidebar, preview, etc.)
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  
  if sidebar_win and current_win == sidebar_win then
    -- If we're in the sidebar, don't switch - let it handle itself
    logger.debug('Currently in sidebar window, skipping switch')
    return
  end
  
  -- Get list of all buffers and find a suitable normal buffer
  local buffers = vim.api.nvim_list_bufs()
  local alternate_buf = nil
  
  -- First pass: look for existing normal buffers
  for _, b in ipairs(buffers) do
    if b ~= closing_buf and vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
      local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
      local filetype = vim.api.nvim_buf_get_option(b, 'filetype')
      local name = vim.api.nvim_buf_get_name(b)
      
      -- Look for normal file buffers (not special buffers)
      if buftype == '' and 
         not filetype:match('^himalaya%-') and
         not name:match('draft_.*%.eml$') and  -- Skip other draft files
         not name:match('^%[.*%]$') then       -- Skip [No Name] type buffers
        alternate_buf = b
        break
      end
    end
  end
  
  -- Second pass: look for any non-special buffer
  if not alternate_buf then
    for _, b in ipairs(buffers) do
      if b ~= closing_buf and vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
        local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
        local filetype = vim.api.nvim_buf_get_option(b, 'filetype')
        
        -- Any normal buffer will do
        if buftype == '' and not filetype:match('^himalaya%-') then
          alternate_buf = b
          break
        end
      end
    end
  end
  
  -- If still no suitable buffer found, create a new scratch buffer
  if not alternate_buf then
    alternate_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(alternate_buf, '[Scratch]')
    -- Set some basic options
    vim.api.nvim_buf_set_option(alternate_buf, 'buftype', '')
    vim.api.nvim_buf_set_option(alternate_buf, 'filetype', 'text')
  end
  
  -- Switch to the alternate buffer
  if vim.api.nvim_win_is_valid(current_win) and alternate_buf then
    logger.debug('Switching to alternate buffer', {
      current_win = current_win,
      alternate_buf = alternate_buf,
      buf_name = vim.api.nvim_buf_get_name(alternate_buf)
    })
    vim.api.nvim_win_set_buf(current_win, alternate_buf)
  else
    logger.warn('Could not switch to alternate buffer', {
      win_valid = vim.api.nvim_win_is_valid(current_win),
      alternate_buf = alternate_buf
    })
  end
end

-- Reopen existing draft for editing
function M.reopen_draft()
  local main = require('neotex.plugins.tools.himalaya.ui.main')
  local email_id = main.get_current_email_id()
  
  -- Debug: Log what email_id we got
  logger.debug('reopen_draft: email_id from get_current_email_id', {
    email_id = email_id,
    email_id_type = type(email_id),
    current_line = vim.fn.getline('.'),
    line_num = vim.fn.line('.'),
    current_folder = state.get_current_folder()
  })
  
  if not email_id then
    notify.himalaya('No draft selected', notify.categories.ERROR)
    return
  end
  
  -- Extra validation to catch the "Drafts" issue
  if type(email_id) == 'string' and email_id == state.get_current_folder() then
    logger.error('Email ID is same as folder name - this is a bug!', {
      email_id = email_id,
      folder = state.get_current_folder()
    })
    notify.himalaya('Error: Invalid draft selection (got folder name instead of ID)', notify.categories.ERROR)
    return
  end
  
  -- Validate email_id is a number or numeric string
  local numeric_id = tonumber(email_id)
  if not numeric_id then
    logger.error('Invalid email ID for draft', {
      email_id = email_id,
      type = type(email_id)
    })
    notify.himalaya('Invalid draft ID: ' .. tostring(email_id), notify.categories.ERROR)
    return
  end
  
  -- Fetch draft content from current folder (we're already in drafts)
  local account = state.get_current_account()
  local current_folder = state.get_current_folder()
  
  if not current_folder then
    notify.himalaya('No current folder', notify.categories.ERROR)
    return
  end
  
  -- Debug: Log the email ID we're trying to read
  logger.debug('Reopening draft', {
    email_id = email_id,
    account = account,
    folder = current_folder
  })
  
  -- Use utils.execute_himalaya for consistent command execution
  local args = { 'message', 'read', tostring(numeric_id), '--preview' }
  local result = utils.execute_himalaya(args, { 
    account = account, 
    folder = current_folder 
  })
  
  if not result then
    notify.himalaya('Failed to load draft content', notify.categories.ERROR)
    return
  end
  
  -- Handle both string output (plain text) and table output (JSON)
  local output
  if type(result) == 'string' then
    output = result
  elseif type(result) == 'table' then
    -- If it's JSON, we need to extract the body
    output = result.body or vim.json.encode(result)
  else
    output = tostring(result)
  end
  
  local exit_code = 0  -- execute_himalaya returns nil on error
  
  -- Parse draft content
  -- Himalaya returns the draft with display headers, then our saved content
  local lines = vim.split(output, '\n')
  local email = {}
  
  -- For JSON results, use the data directly
  if type(result) == 'table' then
    email = {
      from = result.from,
      to = result.to,
      cc = result.cc,
      bcc = result.bcc,
      subject = result.subject,
      body = result.body or ''
    }
  else
    -- For text output, parse it
    -- First, look for the divider line that himalaya adds after its display headers
    local divider_line = nil
    for i, line in ipairs(lines) do
      if line:match('^%-+$') then  -- Line of dashes
        divider_line = i
        break
      end
    end
    
    -- If we found a divider, everything after it is our actual saved email
    if divider_line then
      -- Skip himalaya's display headers and parse our actual email
      local actual_content = {}
      for i = divider_line + 2, #lines do  -- +2 to skip divider and empty line
        table.insert(actual_content, lines[i])
      end
      
      -- Now parse our actual email content
      email = utils.parse_email_content(actual_content)
      
      -- Check if body contains our headers (duplicate headers issue)
      if email.body and email.body:match('^From:') then
        -- The body contains another set of headers, parse it again
        local body_lines = vim.split(email.body, '\n')
        local inner_email = utils.parse_email_content(body_lines)
        if inner_email.body then
          email = inner_email
        end
      end
    else
      -- Fallback to original parsing
      email = parse_email_buffer(lines)
      if (not email.body or email.body == '') and #lines > 0 then
        local raw_email = utils.parse_email_content(lines)
        if raw_email then
          email = raw_email
        end
      end
    end
  end
  
  -- Check for multipart markers and extract content
  if email.body then
    -- Handle <#part type=application/octet-stream> markers
    local content_match = email.body:match('<#part type=application/octet%-stream>\n?(.-)\n?<#')
    if content_match then
      email.body = content_match
      logger.debug('Extracted content from multipart markers', { 
        extracted_length = #content_match 
      })
    end
    
    -- Also handle the case where the markers are at the beginning/end
    email.body = email.body:gsub('^<#part type=application/octet%-stream>\n?', '')
    email.body = email.body:gsub('\n?<#!part.->\n?<#!/part>\n?$', '')
    email.body = email.body:gsub('<#!/part>\n?$', '')  -- Sometimes just the end marker
  end
  
  -- If we still have no body, log what we got
  if not email.body or email.body == '' then
    logger.warn('Draft appears to have no body content', {
      email_id = email_id,
      parsed_headers = {
        from = email.from,
        to = email.to,
        subject = email.subject
      },
      raw_output_length = #output,
      raw_output_preview = output:sub(1, 200)
    })
  end
  
  -- Create compose buffer with existing content
  -- For reopened drafts, we should create a new local file since we don't know
  -- which local file corresponds to this maildir draft
  local opts = {
    to = email.to,
    cc = email.cc,
    bcc = email.bcc,
    subject = email.subject,
    body = email.body,
    is_draft_reopen = true,
    original_draft_id = email_id,
    -- Don't pass existing_draft_file - let it create a new local file
  }
  
  local buf = M.create_compose_buffer(opts)
  
  -- Important: Delete the original draft from maildir to avoid duplicates
  vim.defer_fn(function()
    local draft_info = composer_buffers[buf]
    if draft_info then
      delete_draft_from_maildir(account, email_id)
      -- Update the draft info to track this as the new draft
      draft_info.original_draft_id = email_id
      composer_buffers[buf] = draft_info
    end
  end, 100)
  
  -- Position cursor appropriately
  -- Note: cursor positioning is already handled in create_compose_buffer
  -- based on the opts we passed, so we don't need to do it again here
  
  notify.himalaya('Draft reopened for editing', notify.categories.STATUS)
  
  return buf
end

return M