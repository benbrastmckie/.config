-- Enhanced Email Preview with New Draft System
-- Integrates with draft_manager_v2 and local_storage

local M = {}

-- Dependencies
local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
local draft_notifications = require('neotex.plugins.tools.himalaya.core.draft_notifications')
local state = require('neotex.plugins.tools.himalaya.core.state')
local utils = require('neotex.plugins.tools.himalaya.utils')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local email_cache = require("neotex.plugins.tools.himalaya.data.cache")

-- Preview interaction state enum (3-state progressive model)
-- OFF: No preview shown, sidebar is in normal navigation mode
-- SWITCH: Preview is shown, j/k in sidebar switches between emails
-- FOCUS: Preview is focused, j/k scrolls preview content
-- BUFFER_OPEN: Email is opened in a full buffer
M.PREVIEW_STATE = {
  OFF = 'off',
  SWITCH = 'switch',
  FOCUS = 'focus',
  BUFFER_OPEN = 'buffer_open',
}

-- Module state
local preview_state = {
  win = nil,
  buf = nil,
  email_id = nil,
  email_type = nil,  -- 'draft', 'regular', 'scheduled' - preserved during mode transitions
  local_id = nil,  -- Local draft identifier for filesystem lookup
  preview_mode = false,  -- Legacy: kept for backward compatibility
  mode = 'off',  -- New: PREVIEW_STATE enum value
  sidebar_cursor_line = nil,  -- Track cursor position when entering focus mode
  autocmd_id = nil,  -- Track sidebar autocmd for cleanup
  preview_autocmd_id = nil,  -- Track preview window autocmd for cleanup
  focus_keymaps_set = false,  -- Track if focus mode keymaps are set
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
  
  -- Check if content has MML tags (Message Markup Language)
  if content:match('<#part') then
    -- Extract text from MML format
    local body = content
    
    -- Remove MML part tags
    body = body:gsub('<#part[^>]*>', '')
    body = body:gsub('<#/part>', '')
    
    -- Clean up extra whitespace
    body = body:gsub('^%s+', '')
    body = body:gsub('%s+$', '')
    
    return body
  end
  
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
  
  -- With Maildir, local_id is the filename - find draft by it
  local drafts = draft_manager.list(account)
  local found_draft = nil
  
  for _, draft in ipairs(drafts) do
    if draft.filename == local_id then
      found_draft = draft
      break
    end
  end
  
  if found_draft and found_draft.filepath then
    -- Read the draft file directly
    local file = io.open(found_draft.filepath, 'r')
    if file then
      local content = file:read('*a')
      file:close()
      
      logger.debug('Found local draft', { 
        local_id = local_id, 
        has_content = content ~= nil,
        content_length = #content 
      })
      
      -- Extract body from content
      local body = extract_body_from_content(content)
      
      return {
        id = local_id,
        subject = found_draft.subject or '',
        from = found_draft.from or '',
        to = found_draft.to or '',
        cc = found_draft.cc or '',
        bcc = found_draft.bcc or '',
        body = body,
        _is_draft = true,
        _is_local = true
      }
    end
  end
  
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

-- Load draft content with new system
local function load_draft_content(account, folder, draft_id)
  -- With Maildir, drafts are just emails - load them from cache or async
  logger.debug('Loading draft from Maildir', { draft_id = draft_id, account = account })
  
  -- First try cache (drafts are cached like regular emails)
  local cached_email = email_cache.get_email(account, folder, draft_id)
  if cached_email then
    -- Check for cached body
    local cached_body = email_cache.get_email_body(account, folder, draft_id)
    if cached_body then
      cached_email.body = cached_body
    end
    -- Mark as draft
    cached_email._is_draft = true
    return cached_email
  end
  
  -- If not in cache, check if it's a local-only draft by filename
  local drafts = draft_manager.list(account)
    for _, draft in ipairs(drafts) do
      if draft.filename == draft_id or tostring(draft.timestamp) == draft_id then
        -- Read directly from file
        local file = io.open(draft.filepath, 'r')
        if file then
          local content = file:read('*a')
          file:close()
          
          local body = extract_body_from_content(content)
          
          return {
            id = draft_id,
            subject = draft.subject or '',
            from = draft.from or '',
            to = draft.to or '',
            cc = draft.cc or '',
            bcc = draft.bcc or '',
            body = body,
            _is_draft = true,
            _is_local = true
          }
        end
      end
    end
  
  -- Not in cache and not a local draft - return minimal structure
  -- Full content will be loaded async (same as regular emails)
  return {
    id = draft_id,
    subject = 'Loading...',
    from = '',
    to = '',
    date = '',
    body = nil, -- Will trigger async load
    _is_draft = true,
    _loading = true
  }
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
  -- Store the email_id in preview state so commands can access it
  preview_state.email_id = email_id
  
  -- The keymaps are now handled by config.setup_buffer_keymaps
  -- which is called when creating the buffer
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
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-email')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Set up Himalaya keymaps for this buffer
  local config = require('neotex.plugins.tools.himalaya.core.config')
  config.setup_buffer_keymaps(buf)

  -- Register email preview keymaps with which-key for menu visibility
  -- These use buffer-local registration to appear only in himalaya-email buffers
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { "<leader>mr", function()
        local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
        if ok and main.reply_current_email then main.reply_current_email() end
      end, desc = "reply", icon = "󰇮", buffer = buf },
      { "<leader>mR", function()
        local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
        if ok and main.reply_all_current_email then main.reply_all_current_email() end
      end, desc = "reply all", icon = "󰇮", buffer = buf },
      { "<leader>mf", function()
        local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
        if ok and main.forward_current_email then main.forward_current_email() end
      end, desc = "forward", icon = "󰇮", buffer = buf },
      { "<leader>md", function()
        local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
        if ok and main.delete_current_email then main.delete_current_email() end
      end, desc = "delete", icon = "󰩺", buffer = buf },
      { "<leader>ma", function()
        local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
        if ok and main.archive_current_email then main.archive_current_email() end
      end, desc = "archive", icon = "󰉋", buffer = buf },
      { "<leader>mn", function()
        local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
        if ok and main.compose_email then main.compose_email() end
      end, desc = "new email", icon = "󰝒", buffer = buf },
      { "<leader>m/", function()
        local ok, search = pcall(require, 'neotex.plugins.tools.himalaya.data.search')
        if ok and search.show_search_ui then search.show_search_ui() end
      end, desc = "search", icon = "󰍉", buffer = buf },
    })
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
      local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
      local time_left = email._scheduled_for - os.time()
      table.insert(lines, "Status:  Scheduled")
      table.insert(lines, "Send in: " .. scheduler.format_countdown(time_left))
      table.insert(lines, "Send at: " .. os.date("%Y-%m-%d %H:%M", email._scheduled_for))
      table.insert(lines, string.rep("-", M.config.width - 2))
      table.insert(lines, "")
    end
    
    -- Add draft state indicator if applicable
    if email._is_draft then
      local state_line = 'Status:  📝 Draft'
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
        -- Clean MML tags if present
        local clean_body = email.body
        if clean_body:match('<#part') then
          clean_body = clean_body:gsub('<#part[^>]*>', '')
          clean_body = clean_body:gsub('<#/part>', '')
          clean_body = clean_body:gsub('^%s+', '')
          clean_body = clean_body:gsub('%s+$', '')
        end
        
        -- Split body into lines and add spacing between emails in reply chains
        local body_lines = vim.split(clean_body, '\n', { plain = true })
        local in_email_body = false
        local in_header_block = false
        local last_was_header = false
        
        for i, line in ipairs(body_lines) do
          local is_header_line = line:match('^From:%s+') or
                                 line:match('^To:%s+') or
                                 line:match('^Subject:%s+') or
                                 line:match('^Date:%s+') or
                                 line:match('^Cc:%s+') or
                                 line:match('^Bcc:%s+')
          
          -- Check if this line starts a new email in the chain
          if in_email_body and line:match('^From:%s+') then
            -- Add two blank lines and a horizontal bar before the new email
            table.insert(lines, "")
            table.insert(lines, "")
            table.insert(lines, string.rep("─", M.config.width - 2))
            in_header_block = true
            in_email_body = false
          elseif is_header_line then
            in_header_block = true
          end
          
          -- Add blank line after header block ends
          if in_header_block and last_was_header and not is_header_line and not line:match('^%s*$') then
            table.insert(lines, "")
            in_header_block = false
          end
          
          table.insert(lines, line)
          
          -- Track if we've seen non-header content (actual email body)
          if not line:match('^%s*$') and not is_header_line then
            in_email_body = true
            in_header_block = false
          end
          
          last_was_header = is_header_line
        end
      else
        table.insert(lines, "Loading email content...")
      end
    else
      -- Non-draft email body
      if email.body then
        -- Clean MML tags if present
        local clean_body = email.body
        if clean_body:match('<#part') then
          clean_body = clean_body:gsub('<#part[^>]*>', '')
          clean_body = clean_body:gsub('<#/part>', '')
          clean_body = clean_body:gsub('^%s+', '')
          clean_body = clean_body:gsub('%s+$', '')
        end
        
        -- Since we use --no-headers, the body is clean without headers
        -- Split body into lines and add spacing between emails in reply chains
        local body_lines = vim.split(clean_body, '\n', { plain = true })
        local in_email_body = false
        local in_header_block = false
        local last_was_header = false
        
        for i, line in ipairs(body_lines) do
          local is_header_line = line:match('^From:%s+') or
                                 line:match('^To:%s+') or
                                 line:match('^Subject:%s+') or
                                 line:match('^Date:%s+') or
                                 line:match('^Cc:%s+') or
                                 line:match('^Bcc:%s+')
          
          -- Check if this line starts a new email in the chain
          if in_email_body and line:match('^From:%s+') then
            -- Add two blank lines and a horizontal bar before the new email
            table.insert(lines, "")
            table.insert(lines, "")
            table.insert(lines, string.rep("─", M.config.width - 2))
            in_header_block = true
            in_email_body = false
          elseif is_header_line then
            in_header_block = true
          end
          
          -- Add blank line after header block ends
          if in_header_block and last_was_header and not is_header_line and not line:match('^%s*$') then
            table.insert(lines, "")
            in_header_block = false
          end
          
          table.insert(lines, line)
          
          -- Track if we've seen non-header content (actual email body)
          if not line:match('^%s*$') and not is_header_line then
            in_email_body = true
            in_header_block = false
          end
          
          last_was_header = is_header_line
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

    -- WinClosed handler for preview window - reset state when closed externally
    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(preview_state.win),
      once = true,
      callback = function()
        M.on_preview_window_closed()
      end,
      desc = 'Reset preview state when window closed'
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
  -- Store email_type and local_id for draft context preservation during mode transitions
  preview_state.email_type = is_draft and 'draft' or 'regular'
  preview_state.local_id = local_id

  -- Render content
  M.render_preview(email_content, preview_state.buf)
  
  -- Load full content async if needed
  if not email_content.body then
    if is_draft then
      -- For drafts, try to load from filesystem since they might not be synced yet
      M.load_draft_content_async(email_id, account, folder)
    else
      -- For regular emails, use himalaya
      M.load_full_content_async(email_id, account, folder)
    end
  end
end

-- Load draft content asynchronously from filesystem
function M.load_draft_content_async(draft_id, account, folder)
  if not draft_id or not account then
    return
  end
  
  vim.schedule(function()
    -- Try to find draft in filesystem
    local drafts = draft_manager.list(account)
    local found_draft = nil
    
    for _, draft in ipairs(drafts) do
      if draft.filename == draft_id or tostring(draft.timestamp) == draft_id then
        found_draft = draft
        break
      end
    end
    
    if found_draft and found_draft.filepath then
      -- Read the draft file directly
      local file = io.open(found_draft.filepath, 'r')
      if file then
        local content = file:read('*a')
        file:close()
        
        -- Extract body from content
        local body = extract_body_from_content(content)
        
        -- If this is still the current draft being previewed, update the preview
        if preview_state.email_id == draft_id and preview_state.win and 
           vim.api.nvim_win_is_valid(preview_state.win) then
          
          -- Create full draft structure
          local draft_email = {
            id = draft_id,
            subject = found_draft.subject or '',
            from = found_draft.from or '',
            to = found_draft.to or '',
            cc = found_draft.cc or '',
            bcc = found_draft.bcc or '',
            body = body,
            _is_draft = true,
            _is_local = true
          }
          
          -- Re-render the preview with full content
          if preview_state.buf and vim.api.nvim_buf_is_valid(preview_state.buf) then
            M.render_preview(draft_email, preview_state.buf)
          end
        end
      else
        logger.error('Failed to read draft file', { filepath = found_draft.filepath })
      end
    else
      -- Draft not found locally, try himalaya as fallback
      logger.debug('Draft not found locally, trying himalaya', { draft_id = draft_id })
      M.load_full_content_async(draft_id, account, folder)
    end
  end)
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
  preview_state.email_type = nil
  preview_state.local_id = nil

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

-- Get current preview interaction mode
function M.get_mode()
  return preview_state.mode or M.PREVIEW_STATE.OFF
end

-- Check if current mode matches the given mode
function M.is_mode(mode)
  return M.get_mode() == mode
end

-- Set preview interaction mode
function M.set_mode(mode)
  -- Validate mode
  local valid_modes = { 'off', 'switch', 'focus', 'buffer_open' }
  local is_valid = false
  for _, v in ipairs(valid_modes) do
    if v == mode then
      is_valid = true
      break
    end
  end

  if not is_valid then
    logger.warn('Invalid preview mode', { mode = mode })
    return false
  end

  local old_mode = preview_state.mode
  preview_state.mode = mode

  -- Sync legacy preview_mode with new state
  preview_state.preview_mode = (mode == M.PREVIEW_STATE.SWITCH or mode == M.PREVIEW_STATE.FOCUS)

  logger.debug('Preview mode changed', { from = old_mode, to = mode })
  return true
end

-- State Transition Functions (Phase 2)

-- Enter SWITCH mode: Show preview, j/k switches between emails
function M.enter_switch_mode(email_id, parent_win, email_type, local_id)
  -- If already in SWITCH mode with same email, do nothing
  if M.is_mode(M.PREVIEW_STATE.SWITCH) and preview_state.email_id == email_id then
    return true
  end

  -- Show the preview
  M.show_preview(email_id, parent_win, email_type, local_id)

  -- Set mode to SWITCH
  M.set_mode(M.PREVIEW_STATE.SWITCH)

  logger.debug('Entered SWITCH mode', { email_id = email_id })
  return true
end

-- Enter FOCUS mode: Focus preview window, j/k scrolls content
function M.enter_focus_mode()
  -- Must be in SWITCH mode to enter FOCUS
  if not M.is_mode(M.PREVIEW_STATE.SWITCH) then
    logger.warn('Cannot enter FOCUS mode: not in SWITCH mode')
    return false
  end

  -- Ensure preview window exists
  if not preview_state.win or not vim.api.nvim_win_is_valid(preview_state.win) then
    logger.warn('Cannot enter FOCUS mode: no valid preview window')
    return false
  end

  -- Store current cursor position in sidebar for restoration
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    preview_state.sidebar_cursor_line = vim.api.nvim_win_get_cursor(sidebar_win)[1]
  end

  -- Focus the preview window
  vim.api.nvim_set_current_win(preview_state.win)

  -- Set mode to FOCUS
  M.set_mode(M.PREVIEW_STATE.FOCUS)

  -- Setup focus mode keymaps
  M.setup_focus_keymaps(preview_state.buf)

  logger.debug('Entered FOCUS mode', { cursor_line = preview_state.sidebar_cursor_line })
  return true
end

-- Exit FOCUS mode: Return focus to sidebar, restore cursor position
function M.exit_focus_mode()
  -- Must be in FOCUS mode
  if not M.is_mode(M.PREVIEW_STATE.FOCUS) then
    return false
  end

  -- Get sidebar window
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()

  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    -- Return focus to sidebar
    vim.api.nvim_set_current_win(sidebar_win)

    -- Restore cursor position
    if preview_state.sidebar_cursor_line then
      local buf = sidebar.get_buf()
      local line_count = vim.api.nvim_buf_line_count(buf)
      local target_line = math.min(preview_state.sidebar_cursor_line, line_count)
      vim.api.nvim_win_set_cursor(sidebar_win, { target_line, 0 })
    end
  end

  -- Clear focus mode keymaps
  M.clear_focus_keymaps(preview_state.buf)

  -- Set mode back to SWITCH
  M.set_mode(M.PREVIEW_STATE.SWITCH)

  logger.debug('Exited FOCUS mode, returned to SWITCH')
  return true
end

-- Exit SWITCH mode: Hide preview, return to OFF mode
function M.exit_switch_mode()
  -- Must be in SWITCH mode
  if not M.is_mode(M.PREVIEW_STATE.SWITCH) then
    return false
  end

  -- Hide the preview
  M.hide_preview()

  -- Set mode to OFF
  M.set_mode(M.PREVIEW_STATE.OFF)

  logger.debug('Exited SWITCH mode, returned to OFF')
  return true
end

-- Open email in full buffer (terminal state)
function M.open_email_in_buffer()
  -- Get current email ID and draft context (capture before hide_preview resets them)
  local email_id = preview_state.email_id
  local email_type = preview_state.email_type
  local local_id = preview_state.local_id

  if not email_id then
    logger.warn('Cannot open email: no email selected')
    return false
  end

  -- Set mode to BUFFER_OPEN
  M.set_mode(M.PREVIEW_STATE.BUFFER_OPEN)

  -- Handle drafts: route to draft_manager.open() for editing
  if email_type == 'draft' then
    logger.debug('Opening draft for editing', { email_id = email_id, local_id = local_id })

    -- Hide the preview window
    M.hide_preview()

    -- Find draft filepath
    local account = state.get_current_account()
    local drafts = draft_manager.list(account)
    local draft_filepath = nil

    -- Search by local_id (filename) or email_id
    local search_id = local_id or email_id
    for _, draft in ipairs(drafts) do
      if draft.filename == search_id or tostring(draft.timestamp) == search_id then
        draft_filepath = draft.filepath
        break
      end
    end

    if draft_filepath then
      -- Open draft for editing via email_composer (ensures keymaps are set up)
      local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      email_composer.open_draft(draft_filepath)
      logger.debug('Opened draft via email_composer', { filepath = draft_filepath })
    else
      -- Draft not found - show error notification
      local notify = require('neotex.util.notifications')
      notify.himalaya('Draft file not found', notify.categories.ERROR)
      logger.error('Draft file not found', { email_id = email_id, local_id = local_id })
      M.set_mode(M.PREVIEW_STATE.OFF)
      return false
    end

    return true
  end

  -- Regular email: hide preview and delegate to email_reader module
  M.hide_preview()

  local ok, email_reader = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_reader')
  if ok and email_reader.open_email_buffer then
    email_reader.open_email_buffer(email_id)
  else
    -- Fallback: just log and reset mode
    logger.warn('email_reader module not available, falling back')
    M.set_mode(M.PREVIEW_STATE.OFF)
  end

  logger.debug('Opened email in buffer', { email_id = email_id })
  return true
end

-- Setup focus mode keymaps for preview buffer
function M.setup_focus_keymaps(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if preview_state.focus_keymaps_set then
    return
  end

  local opts = { buffer = buf, silent = true, nowait = true }

  -- j/k for scrolling in focus mode
  vim.keymap.set('n', 'j', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      vim.cmd('normal! j')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Scroll down in preview' }))

  vim.keymap.set('n', 'k', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      vim.cmd('normal! k')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Scroll up in preview' }))

  -- Page scrolling
  vim.keymap.set('n', '<C-d>', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      vim.cmd('normal! <C-d>')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Half-page down' }))

  vim.keymap.set('n', '<C-u>', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      vim.cmd('normal! <C-u>')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Half-page up' }))

  vim.keymap.set('n', '<C-f>', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      vim.cmd('normal! <C-f>')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Page down' }))

  vim.keymap.set('n', '<C-b>', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      vim.cmd('normal! <C-b>')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Page up' }))

  -- Enter to open in full buffer
  vim.keymap.set('n', '<CR>', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      M.open_email_in_buffer()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Open email in buffer' }))

  -- ESC and q to return to SWITCH mode
  vim.keymap.set('n', '<Esc>', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      M.exit_focus_mode()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Return to sidebar' }))

  vim.keymap.set('n', 'q', function()
    if M.is_mode(M.PREVIEW_STATE.FOCUS) then
      M.exit_focus_mode()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Return to sidebar' }))

  preview_state.focus_keymaps_set = true
end

-- Clear focus mode keymaps (restore normal preview keymaps)
function M.clear_focus_keymaps(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Delete buffer-local keymaps
  pcall(vim.keymap.del, 'n', 'j', { buffer = buf })
  pcall(vim.keymap.del, 'n', 'k', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<C-d>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<C-u>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<C-f>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<C-b>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<CR>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<Esc>', { buffer = buf })
  pcall(vim.keymap.del, 'n', 'q', { buffer = buf })

  preview_state.focus_keymaps_set = false
end

-- Handler for when preview window is closed externally
function M.on_preview_window_closed()
  logger.debug('Preview window closed externally, resetting state')

  -- Reset window reference
  preview_state.win = nil
  preview_state.email_id = nil
  preview_state.email_type = nil
  preview_state.local_id = nil

  -- Reset mode to OFF
  M.set_mode(M.PREVIEW_STATE.OFF)

  -- Clean up autocmds
  if preview_state.autocmd_id then
    pcall(vim.api.nvim_del_autocmd, preview_state.autocmd_id)
    preview_state.autocmd_id = nil
  end
  if preview_state.preview_autocmd_id then
    pcall(vim.api.nvim_del_autocmd, preview_state.preview_autocmd_id)
    preview_state.preview_autocmd_id = nil
  end

  preview_state.focus_keymaps_set = false
end

-- Handler for when sidebar is closed - cleanup all preview state
function M.on_sidebar_closed()
  logger.debug('Sidebar closed, cleaning up all preview state')

  -- Hide preview window if open
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    pcall(vim.api.nvim_win_close, preview_state.win, true)
  end

  -- Reset all state
  preview_state.win = nil
  preview_state.buf = nil
  preview_state.email_id = nil
  preview_state.email_type = nil
  preview_state.local_id = nil
  preview_state.sidebar_cursor_line = nil
  preview_state.focus_keymaps_set = false

  -- Reset mode to OFF
  M.set_mode(M.PREVIEW_STATE.OFF)

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

-- Setup sidebar close handler (called from sidebar module)
function M.setup_sidebar_close_handler(sidebar_win)
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(sidebar_win),
      once = true,
      callback = function()
        M.on_sidebar_closed()
      end,
      desc = 'Clean up preview state when sidebar closed'
    })
  end
end

return M