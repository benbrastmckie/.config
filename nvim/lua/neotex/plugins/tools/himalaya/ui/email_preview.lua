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
}

-- Configuration
M.config = {
  enabled = true,
  keyboard_delay = 100,
  width = 80,
  max_height = 30,
  position = 'smart',
  border = 'single',
  show_headers = true,
  syntax_highlight = true,
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

-- Load draft content with new system
local function load_draft_content(account, folder, draft_id)
  -- First check if this is an active draft in editor
  local active_draft = draft_manager.get_by_remote_id(draft_id)
  
  if active_draft then
    -- Get latest content from local storage
    local stored = local_storage.load(active_draft.local_id)
    if stored then
      draft_notifications.debug_lifecycle('preview_from_active', active_draft.local_id, {
        remote_id = draft_id,
        has_content = stored.content ~= nil
      })
      
      return {
        id = draft_id,
        subject = stored.metadata.subject or active_draft.metadata.subject,
        from = stored.metadata.from or active_draft.metadata.from,
        to = stored.metadata.to or active_draft.metadata.to,
        cc = stored.metadata.cc or active_draft.metadata.cc,
        bcc = stored.metadata.bcc or active_draft.metadata.bcc,
        body = extract_body_from_content(stored.content or ''),
        _is_draft = true,
        _draft_state = active_draft.state,
        _sync_error = active_draft.sync_error
      }
    end
  end
  
  -- Not an active draft, try to load from himalaya
  draft_notifications.draft_loading(draft_id, 'himalaya')
  
  local draft_data, err = draft_manager.load(draft_id, account)
  if draft_data then
    return {
      id = draft_id,
      subject = draft_data.metadata.subject,
      from = draft_data.metadata.from,
      to = draft_data.metadata.to,
      cc = draft_data.metadata.cc,
      bcc = draft_data.metadata.bcc,
      body = extract_body_from_content(draft_data.content or ''),
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
  local width = vim.api.nvim_win_get_width(parent_win)
  local height = vim.api.nvim_win_get_height(parent_win)
  local row = 0
  local col = width + 1
  
  -- Smart positioning
  if M.config.position == 'smart' then
    if width > 120 then
      -- Wide screen: show on right
      col = width + 1
    else
      -- Narrow screen: show at bottom
      row = height + 1
      col = 0
    end
  elseif M.config.position == 'bottom' then
    row = height + 1
    col = 0
  end
  
  return {
    relative = 'win',
    win = parent_win,
    width = math.min(M.config.width, vim.o.columns - col - 2),
    height = math.min(M.config.max_height, vim.o.lines - row - 4),
    row = row,
    col = col,
    border = M.config.border,
    style = 'minimal',
    focusable = true,
  }
end

-- Get or create preview buffer
function M.get_or_create_preview_buffer()
  -- Create new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Buffer settings
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  if M.config.syntax_highlight then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  end
  
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
    
    -- Headers
    if M.config.show_headers then
      local from = safe_tostring(email.from, "Unknown")
      local to = safe_tostring(email.to, "")
      local subject = safe_tostring(email.subject, "")
      local date = safe_tostring(email.date, "Unknown")
      
      table.insert(lines, "From: " .. from)
      table.insert(lines, "To: " .. to)
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
      table.insert(lines, string.rep("-", M.config.width - 2))
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
      end
    else
      -- Non-draft email body
      if email.body then
        -- Split body into lines
        local body_lines = vim.split(email.body, '\n', { plain = true })
        for _, line in ipairs(body_lines) do
          table.insert(lines, line)
        end
      elseif email._error then
        table.insert(lines, '(No content available)')
      else
        table.insert(lines, '(Loading...)')
      end
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
end

-- Show preview for an email
function M.show_preview(email_id, parent_win, email_type)
  if not M.config.enabled then
    return
  end
  
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
    email_content = load_draft_content(account, folder, email_id)
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
  -- Implementation would go here for loading regular emails
  -- For now, this is a placeholder
end

-- Hide preview window
function M.hide_preview()
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_close(preview_state.win, true)
  end
  preview_state.win = nil
  preview_state.email_id = nil
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