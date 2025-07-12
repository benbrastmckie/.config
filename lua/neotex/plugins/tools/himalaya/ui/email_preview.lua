-- Enhanced Email Preview with New Draft System
-- Integrates with draft_manager_v2 and local_storage

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
local draft_notifications = require('neotex.plugins.tools.himalaya.core.draft_notifications')
local state = require('neotex.plugins.tools.himalaya.core.state')
local utils = require('neotex.plugins.tools.himalaya.utils')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')

-- Module state
local preview_state = {
  win = nil,
  buf = nil,
  email_id = nil,
  preview_mode = false,
  autocmd_id = nil,  -- Track sidebar autocmd for cleanup
  preview_autocmd_id = nil,  -- Track preview window autocmd for cleanup
}

-- Configuration
M.config = {
  enabled = true,
  keyboard_delay = 100,
  mouse_delay = 1000,  -- From old version
  width = 80,  -- Fixed 80 character width as in old version
  max_height = 30,  -- Original height
  position = 'smart',  -- 'right', 'bottom', or 'smart'
  border = 'single',
  show_headers = true,
  syntax_highlight = true,
  auto_close = true,
  focusable = false,  -- Can be toggled with double-press
}

-- Initialize module
function M.setup(cfg)
  if cfg and cfg.preview then
    M.config = vim.tbl_extend('force', M.config, cfg.preview)
  end
end

-- Extract body from draft content that includes headers
local function extract_body_from_content(content)
  if not content then return '' end
  
  -- Find the empty line that separates headers from body
  local lines = vim.split(content, '\n', { plain = true })
  local body_start = 0
  
  for i, line in ipairs(lines) do
    if line:match('^%s*$') then
      body_start = i + 1
      break
    end
  end
  
  if body_start > 0 and body_start <= #lines then
    -- Join the body lines
    local body_lines = {}
    for i = body_start, #lines do
      table.insert(body_lines, lines[i])
    end
    return table.concat(body_lines, '\n')
  end
  
  return content
end

-- Load local draft content by local_id
local function load_local_draft_content(account, local_id)
  logger.debug('Loading local draft by local_id', { local_id = local_id, account = account })
  local stored = local_storage.load(local_id)
  
  if stored and stored.content then
    logger.debug('Found local draft', { 
      local_id = local_id, 
      has_content = stored.content ~= nil,
      content_length = #stored.content 
    })
    
    -- Parse content for display
    local metadata = stored.metadata or {}
    local body = extract_body_from_content(stored.content)
    
    return {
      id = local_id,
      subject = metadata.subject or '',
      from = metadata.from or '',
      to = metadata.to or '',
      cc = metadata.cc or '',
      bcc = metadata.bcc or '',
      body = body,
      _is_draft = true,
      _is_local = true
    }
  else
    logger.warn('Local draft not found', { local_id = local_id })
    return {
      id = local_id,
      subject = '(Local draft not found)',
      from = '',
      to = '',
      body = 'Failed to load local draft content',
      _is_draft = true,
      _is_local = true,
      _error = true
    }
  end
end

-- Load draft content with new system
local function load_draft_content(account, folder, draft_id)
  -- Try local storage first
  logger.debug('Looking for draft in local storage', { remote_id = draft_id, account = account })
  local stored = local_storage.find_by_remote_id(draft_id, account)
  
  if stored and stored.content then
    logger.debug('Found draft in local storage', { 
      remote_id = draft_id, 
      has_content = stored.content ~= nil,
      content_length = #stored.content 
    })
    
    -- Parse content for display
    local lines = vim.split(stored.content, '\n')
    local metadata = stored.metadata or {}
    local body = extract_body_from_content(stored.content)
    
    return {
      id = draft_id,
      subject = metadata.subject or '',
      from = metadata.from or '',
      to = metadata.to or '',
      cc = metadata.cc or '',
      bcc = metadata.bcc or '',
      body = body,
      _is_draft = true
    }
  end
  
  -- Try to load from himalaya
  draft_notifications.draft_loading(draft_id, 'himalaya')
  
  local draft_data, err = draft_manager.load(draft_id, account)
  if draft_data and draft_data.content then
    -- Parse the raw content for preview
    local lines = vim.split(draft_data.content, '\n')
    local headers = {}
    local body_start = 1
    
    -- Quick header parse for preview
    for i, line in ipairs(lines) do
      if line == '' then
        body_start = i + 1
        break
      end
      local key, value = line:match('^([^:]+):%s*(.*)$')
      if key then
        headers[key:lower()] = value
      end
    end
    
    -- Extract body
    local body = ''
    if body_start <= #lines then
      local body_lines = {}
      for i = body_start, #lines do
        table.insert(body_lines, lines[i])
      end
      body = table.concat(body_lines, '\n')
    end
    
    return {
      id = draft_id,
      subject = headers.subject or '',
      from = headers.from or '',
      to = headers.to or '',
      cc = headers.cc or '',
      bcc = headers.bcc or '',
      body = body,
      _is_draft = true
    }
  else
    draft_notifications.draft_load_failed(draft_id, err)
    
    -- Return error placeholder
    return {
      id = draft_id,
      subject = '(Unable to load draft)',
      from = '',
      to = '',
      body = 'Failed to load draft content: ' .. (err or 'Unknown error'),
      _is_draft = true,
      _error = true
    }
  end
end

-- Calculate preview window position
function M.calculate_preview_position(parent_win)
  local sidebar_width = vim.api.nvim_win_get_width(parent_win)
  local win_height = vim.api.nvim_win_get_height(parent_win)
  local win_pos = vim.api.nvim_win_get_position(parent_win)
  
  -- Always position to the right of sidebar
  -- Adjust height and position to avoid buffer line and status bar
  return {
    relative = 'editor',
    width = 80,  -- Fixed 80 character width
    height = win_height - 2,  -- Reduce height by 2 (top and bottom)
    row = win_pos[1],     -- Match sidebar position
    col = win_pos[2] + sidebar_width + 1,  -- Position after sidebar + 1 for border
    style = 'minimal',
    border = M.config.border,
    title = ' Email Preview ',
    title_pos = 'center',
    focusable = true,  -- Make it focusable so we can enter it with mouse
    zindex = 50,
    noautocmd = false,  -- Ensure autocmds fire for proper event handling
  }
end

-- Setup keymaps for preview buffer
local function setup_preview_keymaps(buf, email_id, email_type)
  local opts = { buffer = buf, noremap = true, silent = true }
  
  -- ESC to return to sidebar
  vim.keymap.set('n', '<Esc>', function()
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local sidebar_win = sidebar.get_win()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
      vim.api.nvim_set_current_win(sidebar_win)
    end
  end, opts)
  
  -- q to exit preview mode and return to sidebar
  vim.keymap.set('n', 'q', function()
    M.disable_preview_mode()
    M.hide_preview()
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local sidebar_win = sidebar.get_win()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
      vim.api.nvim_set_current_win(sidebar_win)
    end
  end, opts)
end

-- Get or create preview buffer
function M.get_or_create_preview_buffer()
  -- Create new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Buffer settings (matching old version)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')  -- Keep in memory
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'undolevels', -1)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  return buf
end

-- Render email content in preview buffer
function M.render_preview(email, buf)
  local lines = {}
  
  -- Protected render function
  local function do_render()
    -- Safe string conversion for all fields with vim.NIL handling
    local function safe_tostring(val, default)
      if val == vim.NIL or val == nil then
        return default or ""
      end
      return tostring(val)
    end
    
    -- Add scheduled email header if applicable
    if email._is_scheduled and email._scheduled_for then
      local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
      local time_left = email._scheduled_for - os.time()
      table.insert(lines, "Status:  Scheduled")
      table.insert(lines, "Send in: " .. scheduler.format_countdown(time_left))
      table.insert(lines, "Send at: " .. os.date("%Y-%m-%d %H:%M", email._scheduled_for))
      table.insert(lines, string.rep("-", M.config.width - 2))
      table.insert(lines, "")
    end
    
    -- Add draft state indicator if applicable
    if email._is_draft and email._draft_state then
      local state_line = 'Status:  '
      if email._draft_state == draft_manager.states.NEW then
        state_line = state_line .. '📝 New (not synced)'
      elseif email._draft_state == draft_manager.states.SYNCING then
        state_line = state_line .. '🔄 Syncing...'
      elseif email._draft_state == draft_manager.states.SYNCED then
        state_line = state_line .. '✅ Synced'
      elseif email._draft_state == draft_manager.states.ERROR then
        state_line = state_line .. '❌ Sync Error: ' .. (email._sync_error or 'Unknown')
      end
      table.insert(lines, state_line)
      table.insert(lines, string.rep("-", M.config.width - 2))
      table.insert(lines, "")
    end
    
    -- Always show headers from cache (since we use --no-headers for body)
    if M.config.show_headers then
      local from = safe_tostring(email.from, "Unknown")
      local to = safe_tostring(email.to, "")
      local subject = safe_tostring(email.subject, "")
      local date = safe_tostring(email.date, "Unknown")
      
      table.insert(lines, "From: " .. from)
      if to ~= "" and to ~= "vim.NIL" then
        table.insert(lines, "To: " .. to)
      end
      if email.cc and email.cc ~= vim.NIL then
        local cc = safe_tostring(email.cc, "")
        if cc ~= "" then
          table.insert(lines, "Cc: " .. cc)
        end
      end
      if email.bcc and email.bcc ~= vim.NIL then
        local bcc = safe_tostring(email.bcc, "")
        if bcc ~= "" then
          table.insert(lines, "Bcc: " .. bcc)
        end
      end
      table.insert(lines, "Subject: " .. subject)
      table.insert(lines, "Date: " .. date)
      table.insert(lines, string.rep("─", M.config.width - 2))
      table.insert(lines, "")
    end
    
    -- Check for empty drafts
    if email._is_draft then
      local is_empty = (
        (not email.to or email.to == '') and
        (not email.subject or email.subject == '') and
        (not email.body or email.body:match('^%s*$'))
      )
      
      if is_empty then
        table.insert(lines, "[Empty draft - add content to see preview]")
        table.insert(lines, "")
        table.insert(lines, "Tip: Start by filling in:")
        table.insert(lines, "  • To: recipient email")
        table.insert(lines, "  • Subject: email subject")
        table.insert(lines, "  • Body: your message")
      elseif email.body then
        -- Split body into lines
        local body_lines = vim.split(email.body, '\n', { plain = true })
        for _, line in ipairs(body_lines) do
          table.insert(lines, line)
        end
      else
        table.insert(lines, "Loading email content...")
      end
    else
      -- Non-draft email body
      if email.body then
        -- Since we use --no-headers, the body is clean without headers
        -- Just add it line by line
        local body_lines = vim.split(email.body, '\n', { plain = true })
        for _, line in ipairs(body_lines) do
          table.insert(lines, line)
        end
      elseif email._error then
        table.insert(lines, '(No content available)')
      else
        table.insert(lines, 'Loading email content...')
      end
    end
    
    -- Add footer with keymaps
    table.insert(lines, "")
    table.insert(lines, string.rep("─", M.config.width - 2))
    if email._is_scheduled then
      table.insert(lines, "esc:sidebar gD:cancel")
      table.insert(lines, "q:exit")
    elseif email._is_draft then
      -- Draft-specific footer
      table.insert(lines, "esc:sidebar return:edit gD:delete")
      table.insert(lines, "q:exit")
    else
      table.insert(lines, "esc:sidebar gr:reply gR:reply-all gf:forward")
      table.insert(lines, "q:exit gD:delete gA:archive gS:spam")
    end
  end
  
  -- Execute render with error protection
  local ok, err = pcall(do_render)
  if not ok then
    lines = {"Error rendering preview:", tostring(err)}
  end
  
  -- Update buffer
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Apply syntax highlighting if enabled
  if M.config.syntax_highlight then
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
end

-- Show preview for an email
function M.show_preview(email_id, parent_win, email_type, local_id)
  if not M.config.enabled then
    return
  end
  
  -- Ensure email_id is a string
  email_id = tostring(email_id)
  
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  
  -- Check if this is a draft
  local is_draft = email_type == 'draft' or (folder and folder:lower():match('draft'))
  
  -- Always refresh drafts to show latest content
  if email_id == preview_state.email_id and preview_state.win and 
     vim.api.nvim_win_is_valid(preview_state.win) and not is_draft then
    return
  end
  
  -- Clear stale state
  if email_id ~= preview_state.email_id then
    preview_state.email_id = nil
  end
  
  local email_content = nil
  
  if is_draft then
    -- Load draft using new system
    if local_id then
      -- Load local draft by local_id
      email_content = load_local_draft_content(account, local_id)
    else
      email_content = load_draft_content(account, folder, email_id)
    end
  else
    -- Load regular email from cache
    email_content = email_cache.get_email(account, folder, email_id)
    if email_content then
      -- Check for cached body
      local cached_body = email_cache.get_email_body(account, folder, email_id)
      if cached_body then
        email_content.body = cached_body
      end
    end
  end
  
  if not email_content then
    logger.warn('Email not found', { id = email_id, type = email_type })
    return
  end
  
  -- Create or reuse preview window
  if not preview_state.win or not vim.api.nvim_win_is_valid(preview_state.win) then
    preview_state.buf = M.get_or_create_preview_buffer()
    
    local parent = parent_win or vim.api.nvim_get_current_win()
    local win_config = M.calculate_preview_position(parent)
    
    local ok, win = pcall(vim.api.nvim_open_win, preview_state.buf, false, win_config)
    if not ok then
      logger.error("Failed to create preview window", { error = win })
      return
    end
    
    preview_state.win = win
    
    -- Set window options
    vim.api.nvim_win_set_option(preview_state.win, 'wrap', true)
    vim.api.nvim_win_set_option(preview_state.win, 'linebreak', true)
    vim.api.nvim_win_set_option(preview_state.win, 'cursorline', false)
    vim.api.nvim_win_set_option(preview_state.win, 'mouse', 'a')  -- Ensure mouse is enabled for this window
    
    -- Setup keymaps for preview buffer
    setup_preview_keymaps(preview_state.buf, email_id, email_type)
    
    -- Setup auto-close when leaving sidebar or preview (but keep preview mode enabled)
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local sidebar_buf = sidebar.get_buf()
    
    -- Clear any existing autocmds
    if preview_state.autocmd_id then
      pcall(vim.api.nvim_del_autocmd, preview_state.autocmd_id)
      preview_state.autocmd_id = nil
    end
    if preview_state.preview_autocmd_id then
      pcall(vim.api.nvim_del_autocmd, preview_state.preview_autocmd_id)
      preview_state.preview_autocmd_id = nil
    end
    
    -- Function to check if we should hide preview
    local function check_hide_preview()
      vim.schedule(function()
        if not preview_state.win or not vim.api.nvim_win_is_valid(preview_state.win) then
          return
        end
        
        local current_win = vim.api.nvim_get_current_win()
        local current_buf = vim.api.nvim_win_get_buf(current_win)
        
        -- Check if we moved to a non-himalaya buffer
        if current_buf ~= preview_state.buf and current_buf ~= sidebar_buf then
          -- Hide preview but keep preview mode enabled
          M.hide_preview()
        end
      end)
    end
    
    -- Autocmd for leaving sidebar
    if sidebar_buf and vim.api.nvim_buf_is_valid(sidebar_buf) then
      preview_state.autocmd_id = vim.api.nvim_create_autocmd('WinLeave', {
        buffer = sidebar_buf,
        callback = check_hide_preview,
        desc = 'Hide preview when leaving sidebar'
      })
    end
    
    -- Autocmd for leaving preview window
    preview_state.preview_autocmd_id = vim.api.nvim_create_autocmd('WinLeave', {
      buffer = preview_state.buf,
      callback = check_hide_preview,
      desc = 'Hide preview when leaving preview window'
    })
  else
    -- Reuse existing window
    if not preview_state.buf or not vim.api.nvim_buf_is_valid(preview_state.buf) then
      preview_state.buf = M.get_or_create_preview_buffer()
      vim.api.nvim_win_set_buf(preview_state.win, preview_state.buf)
    end
  end
  
  -- Update state
  preview_state.email_id = email_id
  
  -- Render content
  M.render_preview(email_content, preview_state.buf)
  
  -- For non-drafts, load full content async if needed
  if not is_draft and not email_content.body then
    M.load_full_content_async(email_id, account, folder)
  end
end

-- Load full email content asynchronously
function M.load_full_content_async(email_id, account, folder)
  if not email_id or not account or not folder then
    return
  end
  
  -- Build himalaya command to read email
  local cmd = {
    'himalaya',
    'message', 'read',
    '-a', account,
    '-f', folder,
    '--preview',  -- Don't mark as read when previewing
    '--no-headers',  -- Get only the body, we'll use cached headers
    tostring(email_id)
  }
  
  local stdout_buffer = {}
  
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_buffer, line)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        if error_msg ~= "" then
          logger.error('Himalaya error loading email', { error = error_msg, id = email_id })
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code == 0 and #stdout_buffer > 0 then
        local output = table.concat(stdout_buffer, '\n')
        
        logger.debug('Himalaya body-only output received', { 
          email_id = email_id,
          output_length = #output,
          first_100_chars = output:sub(1, 100)
        })
        
        -- Since we used --no-headers, the output is just the body
        local body = output
        
        -- Update cache with full body
        email_cache.store_email_body(account, folder, email_id, body)
        
        -- If this is still the current email being previewed, update the preview
        if preview_state.email_id == email_id and preview_state.win and 
           vim.api.nvim_win_is_valid(preview_state.win) then
          -- Get the cached email and update with body
          local email = email_cache.get_email(account, folder, email_id)
          if email then
            email.body = body
            -- Re-render the preview with full content
            vim.schedule(function()
              if preview_state.buf and vim.api.nvim_buf_is_valid(preview_state.buf) then
                M.render_preview(email, preview_state.buf)
              end
            end)
          else
            -- If email not in cache, create a minimal structure
            logger.warn('Email not in cache, creating minimal structure', { email_id = email_id })
            local minimal_email = {
              id = email_id,
              body = body,
              subject = '(Email loaded directly)',
              from = '',
              to = '',
              date = ''
            }
            vim.schedule(function()
              if preview_state.buf and vim.api.nvim_buf_is_valid(preview_state.buf) then
                M.render_preview(minimal_email, preview_state.buf)
              end
            end)
          end
        end
      elseif exit_code ~= 0 then
        logger.error('Failed to load email content', { 
          email_id = email_id, 
          exit_code = exit_code,
          output = table.concat(stdout_buffer, '\n')
        })
      end
    end
  })
end

-- Hide preview window
function M.hide_preview()
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_close(preview_state.win, true)
  end
  preview_state.win = nil
  preview_state.email_id = nil
  
  -- Clean up autocmds
  if preview_state.autocmd_id then
    pcall(vim.api.nvim_del_autocmd, preview_state.autocmd_id)
    preview_state.autocmd_id = nil
  end
  if preview_state.preview_autocmd_id then
    pcall(vim.api.nvim_del_autocmd, preview_state.preview_autocmd_id)
    preview_state.preview_autocmd_id = nil
  end
end

-- Toggle preview mode
function M.toggle_preview_mode()
  preview_state.preview_mode = not preview_state.preview_mode
  return preview_state.preview_mode
end

-- Check if preview mode is enabled
function M.is_preview_mode()
  return preview_state.preview_mode
end

-- Enable preview mode
function M.enable_preview_mode()
  preview_state.preview_mode = true
  return true
end

-- Disable preview mode
function M.disable_preview_mode()
  preview_state.preview_mode = false
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_close(preview_state.win, true)
  end
  preview_state.win = nil
  preview_state.email_id = nil
  return true
end

-- Check if preview is visible
function M.is_preview_visible()
  return preview_state.win and vim.api.nvim_win_is_valid(preview_state.win)
end

-- Check if preview is shown (alias for is_preview_visible)
function M.is_preview_shown()
  return M.is_preview_visible()
end

-- Ensure preview window exists and is valid
function M.ensure_preview_window()
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    return preview_state.win
  end
  return nil
end

-- Focus the preview window
function M.focus_preview()
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_set_current_win(preview_state.win)
    return true
  end
  return false
end

-- Get current preview email ID
function M.get_current_preview_id()
  return preview_state.email_id
end

-- Get preview state
function M.get_state()
  return preview_state
end

-- Get preview state (alias for consistency)
function M.get_preview_state()
  return preview_state
end

return M