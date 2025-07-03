-- Email preview functionality with async loading
-- Based on HOVER.md specification
local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local notify = require('neotex.util.notifications')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
local config = require('neotex.plugins.tools.himalaya.core.config')

-- Module state
-- Store preview state in a table to prevent corruption
local preview_state = {
  win = nil,
  buf = nil,
  email_id = nil,
  is_focusing = false,  -- Flag to prevent hiding during focus
  preview_mode = false, -- Whether preview mode is active
  is_mouse_clicking = false, -- Flag to prevent closing during mouse clicks
}
local hover_timer = nil
local preview_generation = 0  -- Track preview requests
local preview_buffers = {}  -- Buffer pool for performance

-- Configuration (incorporating best practices)
M.config = {
  enabled = true,
  keyboard_delay = 100,   -- From Trouble.nvim
  mouse_delay = 1000,     -- From hover.nvim
  width = 80,
  max_height = 30,
  position = 'smart',     -- 'right', 'bottom', or 'smart'
  border = 'single',      -- From LSP best practices
  focusable = false,      -- Can be toggled with double-press
  show_headers = true,
  syntax_highlight = true,
  auto_close = true,
  max_file_size = 204800, -- 200KB limit for performance
  cache_ttl = 300,        -- 5 minutes
}

-- Initialize the module with config
function M.setup(cfg)
  if cfg and cfg.preview then
    M.config = vim.tbl_extend('force', M.config, cfg.preview)
  end
  logger.debug('Email preview v2 initialized', { config = M.config })
  
  -- Set up autocmd for preview window keymaps only
  local himalaya_group = vim.api.nvim_create_augroup('HimalayaPreview', { clear = true })
  
  vim.api.nvim_create_autocmd('WinEnter', {
    group = himalaya_group,
    callback = function()
      local current_win = vim.api.nvim_get_current_win()
      -- If entering the preview window, set up keymaps
      if preview_state.win and current_win == preview_state.win then
        M.setup_preview_keymaps(preview_state.buf)
      end
    end
  })
  
  -- Global handler for when preview mode is active - only close on non-Himalaya windows
  vim.api.nvim_create_autocmd('WinEnter', {
    group = himalaya_group,
    callback = function()
      if not preview_state.preview_mode then
        return
      end
      
      local current_win = vim.api.nvim_get_current_win()
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      local sidebar_win = sidebar.get_win()
      
      -- Only close preview if entering a window that's not preview, sidebar, or Himalaya-related
      if preview_state.win and current_win ~= preview_state.win and current_win ~= sidebar_win then
        -- Check if the new window is Himalaya-related
        local buf = vim.api.nvim_win_get_buf(current_win)
        local filetype = vim.api.nvim_buf_get_option(buf, 'filetype')
        
        -- Don't close preview for Himalaya windows
        if not filetype:match('^himalaya') then
          local notify = require('neotex.util.notifications')
          notify.himalaya("Closing preview - entered non-Himalaya window", notify.categories.STATUS, {
            filetype = filetype,
            window = current_win
          })
          M.disable_preview_mode()
        end
      end
    end
  })
end

-- Get or create preview buffer from pool
function M.get_or_create_preview_buffer()
  -- Find an unused buffer or create new one
  for buf, in_use in pairs(preview_buffers) do
    if not in_use and vim.api.nvim_buf_is_valid(buf) then
      preview_buffers[buf] = true
      return buf
    end
  end
  
  -- Create new buffer with proper options
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')  -- Keep in memory
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'undolevels', -1)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  preview_buffers[buf] = true
  return buf
end

-- Release preview buffer back to pool
function M.release_preview_buffer(buf)
  if preview_buffers[buf] then
    preview_buffers[buf] = false
    -- Clear content but keep buffer for reuse
    if vim.api.nvim_buf_is_valid(buf) then
      local modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')
      vim.api.nvim_buf_set_option(buf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
      vim.api.nvim_buf_set_option(buf, 'modifiable', modifiable)
    end
  end
end

-- Calculate smart preview position
function M.calculate_preview_position(parent_win)
  local sidebar_width = vim.api.nvim_win_get_width(parent_win)
  local win_height = vim.api.nvim_win_get_height(parent_win)
  local win_pos = vim.api.nvim_win_get_position(parent_win)
  
  -- Always position to the right of sidebar
  -- Use editor positioning to place it beside the sidebar
  return {
    relative = 'editor',
    width = 80,  -- Fixed 80 character width as requested
    height = win_height,
    row = win_pos[1],
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

-- Safe preview wrapper with error handling
function M.safe_preview(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    logger.error('Preview error', { error = result })
    -- Show error in preview if window exists
    if preview_win and vim.api.nvim_win_is_valid(preview_win) then
      local error_lines = {
        "Preview Error",
        string.rep("-", 40),
        "Failed to load email preview.",
        "",
        "Error: " .. tostring(result):match("^[^\n]+"),
        "",
        "Press 'q' to close this window."
      }
      if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
        vim.api.nvim_buf_set_option(preview_buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, error_lines)
        vim.api.nvim_buf_set_option(preview_buf, 'modifiable', false)
      end
    end
    return nil
  end
  return result
end

-- Process email body
local function process_email_body(body)
  if not body then
    return { "No content available" }
  end
  
  local lines = {}
  
  -- Split body into lines
  for line in body:gmatch("([^\r\n]*)\r?\n?") do
    if line ~= "" or #lines > 0 then  -- Skip leading empty lines
      -- Don't wrap lines - let the window handle it
      table.insert(lines, line)
    end
  end
  
  -- Limit lines
  if #lines > M.config.max_height - 10 then
    local truncated = {}
    for i = 1, M.config.max_height - 12 do
      table.insert(truncated, lines[i])
    end
    table.insert(truncated, "")
    table.insert(truncated, "... (" .. (#lines - (M.config.max_height - 12)) .. " more lines)")
    return truncated
  end
  
  return lines
end

-- Render email content in preview buffer
function M.render_preview(email, buf)
  local lines = {}
  
  -- Protected render function
  local function do_render()
    if M.config.show_headers then
      -- Safe string conversion for all fields
      local from = tostring(email.from or "Unknown")
      local to = tostring(email.to or "Unknown")
      local subject = tostring(email.subject or "No Subject")
      local date = tostring(email.date or "Unknown")
      
      table.insert(lines, "From: " .. from)
      table.insert(lines, "To: " .. to)
      if email.cc then
        local cc = tostring(email.cc)
        table.insert(lines, "Cc: " .. cc)
      end
      table.insert(lines, "Subject: " .. subject)
      table.insert(lines, "Date: " .. date)
      table.insert(lines, string.rep("-", M.config.width - 2))
      table.insert(lines, "")
    end
    
    -- Body handling
    if email.body then
      local body_lines = process_email_body(email.body)
      vim.list_extend(lines, body_lines)
    else
      table.insert(lines, "Loading email content...")
    end
    
    -- Add footer with keymaps
    table.insert(lines, "")
    table.insert(lines, string.rep("─", M.config.width - 2))
    table.insert(lines, "esc:sidebar gr:reply gR:reply-all gf:forward")
    table.insert(lines, "q:exit gD:delete gA:archive gS:spam")
    
    -- Update buffer with validation
    if buf and vim.api.nvim_buf_is_valid(buf) then
      -- Use modifiable pattern for safety
      local modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')
      vim.api.nvim_buf_set_option(buf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, 'modifiable', modifiable)
      
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
  end
  
  -- Execute with protection
  M.safe_preview(do_render)
end

-- Hide the preview window
function M.hide_preview()
  -- Don't hide if we're in the process of focusing or updating
  if preview_state.is_focusing or preview_state.is_updating then
    return
  end
  
  -- Cancel any pending preview
  if hover_timer then
    vim.loop.timer_stop(hover_timer)
    hover_timer = nil
  end
  
  -- Close preview window if it exists
  if preview_state.win then
    if type(preview_state.win) == "number" and vim.api.nvim_win_is_valid(preview_state.win) then
      local ok, err = pcall(vim.api.nvim_win_close, preview_state.win, true)
      if not ok then
        logger.warn("Failed to close preview window", { error = err })
      end
    end
    preview_state.win = nil
  end
  
  -- Release preview buffer back to pool
  if preview_state.buf then
    M.release_preview_buffer(preview_state.buf)
    preview_state.buf = nil
  end
  
  preview_state.email_id = nil
end

-- Queue preview with debouncing
function M.queue_preview(email_id, parent_win, trigger)
  -- Cancel pending previews
  preview_generation = preview_generation + 1
  local current_gen = preview_generation
  
  if hover_timer then
    vim.loop.timer_stop(hover_timer)
  end
  
  -- Use different delays based on trigger
  local delay = trigger == 'mouse' and M.config.mouse_delay or M.config.keyboard_delay
  
  hover_timer = vim.loop.new_timer()
  hover_timer:start(delay, 0, vim.schedule_wrap(function()
    -- Check if this preview is still relevant
    if current_gen == preview_generation then
      M.show_preview(email_id, parent_win)
    end
  end))
end

-- Show preview for an email (two-stage loading)
function M.show_preview(email_id, parent_win)
  -- Log who called show_preview
  local trace = debug.traceback("", 2)
  notify.himalaya("show_preview called", notify.categories.BACKGROUND, {
    email_id = email_id,
    current_preview_id = preview_state.email_id,
    has_window = preview_state.win ~= nil,
    caller = trace:match("([^\n]+)\n[^\n]+\n([^\n]+)")
  })
  
  if not M.config.enabled then
    return
  end
  
  -- If showing the same email, just ensure window is visible
  if email_id == preview_state.email_id and preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    notify.himalaya("Preview already showing this email", notify.categories.STATUS, {
      email_id = email_id,
      window = preview_state.win
    })
    return
  end
  
  -- Store the previous email_id to detect if we're updating an existing preview
  local is_update = preview_state.win and vim.api.nvim_win_is_valid(preview_state.win)
  
  -- No longer need updating flag since we removed WinLeave autocmd
  
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  
  -- Stage 1: Show immediate preview with cached data
  local cached_email = email_cache.get_email(account, folder, email_id)
  
  if not cached_email then
    logger.warn('Email not found in cache', { id = email_id })
    return
  end
  
  -- Check for cached body
  local cached_body = email_cache.get_email_body(account, folder, email_id)
  if cached_body then
    cached_email.body = cached_body
  end
  
  -- Create or reuse preview window
  if not preview_state.win or not vim.api.nvim_win_is_valid(preview_state.win) then
    preview_state.buf = M.get_or_create_preview_buffer()
    
    -- Get parent window
    local parent = parent_win or vim.api.nvim_get_current_win()
    local win_config = M.calculate_preview_position(parent)
    
    -- Create window with pcall for safety
    local ok, win_or_err = pcall(vim.api.nvim_open_win, preview_state.buf, false, win_config)
    if not ok then
      logger.error("Failed to create preview window", { error = win_or_err })
      return
    end
    
    preview_state.win = win_or_err
    
    -- DIAGNOSTIC: Log window creation
    logger.debug("Preview window created", { 
      win_id = preview_state.win, 
      focusable = win_config.focusable,
      position = { row = win_config.row, col = win_config.col }
    })
    
    -- Notify about window creation for debugging
    notify.himalaya("Preview window created", notify.categories.STATUS, {
      window_id = preview_state.win,
      focusable = win_config.focusable,
      position = string.format("row=%d, col=%d", win_config.row, win_config.col),
      size = string.format("%dx%d", win_config.width, win_config.height)
    })
    
    -- Validate window was created
    if not preview_state.win or type(preview_state.win) ~= "number" then
      logger.error("Failed to create preview window", { win = preview_state.win, type = type(preview_state.win) })
      preview_state.win = nil
      return
    end
    
    -- Double-check validity
    if not vim.api.nvim_win_is_valid(preview_state.win) then
      logger.error("Preview window created but not valid", { win = preview_state.win })
      preview_state.win = nil
      return
    end
    
    -- Set window options with error handling
    local function safe_set_win_option(win, option, value)
      local ok, err = pcall(vim.api.nvim_win_set_option, win, option, value)
      if not ok then
        logger.warn("Failed to set window option", { option = option, error = err })
      end
    end
    
    safe_set_win_option(preview_state.win, 'wrap', true)
    safe_set_win_option(preview_state.win, 'linebreak', true)
    safe_set_win_option(preview_state.win, 'cursorline', false)
    safe_set_win_option(preview_state.win, 'mouse', 'a')  -- Ensure mouse is enabled for this window
    
    -- Set up window-specific autocmd for mouse clicks
    local win_id = preview_state.win
    vim.api.nvim_create_autocmd('WinEnter', {
      callback = function()
        local current_win = vim.api.nvim_get_current_win()
        if current_win == win_id then
          notify.himalaya("Preview window entered", notify.categories.STATUS, {
            method = "WinEnter",
            window = current_win
          })
        end
      end,
      desc = 'Track preview window entry'
    })
  else
    -- Window exists, just get or create a buffer for the new content
    if not preview_state.buf or not vim.api.nvim_buf_is_valid(preview_state.buf) then
      preview_state.buf = M.get_or_create_preview_buffer()
      vim.api.nvim_win_set_buf(preview_state.win, preview_state.buf)
    end
  end
  
  -- Update email_id first to prevent re-triggering
  local old_email_id = preview_state.email_id
  preview_state.email_id = email_id
  
  -- Render cached content immediately
  M.render_preview(cached_email, preview_state.buf)
  
  -- No cleanup needed anymore
  
  -- Stage 2: Load full content asynchronously if not cached
  if not cached_body then
    local account_cfg = config.get_current_account()
    if not account_cfg then
      return
    end
    
    -- Build himalaya command (message read returns plain text, not JSON)
    local cmd = {
      'himalaya',
      'message', 'read',
      '-a', account,
      '-f', folder,
      '--preview',  -- Don't mark as read when previewing
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
          
          -- Parse plain text output
          local body = output
          
          -- Try to extract body after headers
          local header_end = output:find("\n\n")
          if header_end then
            body = output:sub(header_end + 2)
          end
          
          -- Remove HTML wrapper if present
          body = body:gsub("<#part type=text/html>", "")
          body = body:gsub("<#/part>", "")
          body = body:gsub("\r\n", "\n")
          
          -- Update preview with full content if still showing
          if preview_state.email_id == email_id and preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
            local cached = email_cache.get_email(account, folder, email_id)
            if cached then
              -- Cache the body
              email_cache.store_email_body(account, folder, email_id, body)
              -- Update the preview
              cached.body = body
              M.render_preview(cached, preview_state.buf)
            else
              -- Create minimal email object from output
              local email = {
                id = email_id,
                subject = "Unknown",
                from = "Unknown",
                to = "Unknown",
                date = "Unknown",
                body = body
              }
              
              -- Try to parse headers from output
              local headers_text = header_end and output:sub(1, header_end) or ""
              for line in headers_text:gmatch("[^\n]+") do
                local header, value = line:match("^([^:]+):%s*(.*)$")
                if header and value then
                  local lower_header = header:lower()
                  if lower_header == "from" then
                    email.from = value
                  elseif lower_header == "to" then
                    email.to = value
                  elseif lower_header == "subject" then
                    email.subject = value
                  end
                end
              end
              
              M.render_preview(email, preview_state.buf)
            end
          end
        elseif exit_code ~= 0 then
          logger.error('Failed to load email for preview', { id = email_id, exit_code = exit_code })
        end
      end
    })
  end
  
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('Showing preview for email: ' .. (cached_email.subject or 'No Subject'), notify.categories.BACKGROUND)
  end
end

-- Check if preview is currently shown
function M.is_preview_shown()
  return preview_state.win and vim.api.nvim_win_is_valid(preview_state.win)
end

-- Get current preview email ID
function M.get_current_preview_id()
  return preview_state.email_id
end

-- Return focus to sidebar without hiding preview
function M.return_to_sidebar()
  -- Set focusing flag to prevent hiding
  preview_state.is_focusing = true
  
  -- Find the sidebar window
  local sidebar_win = sidebar.get_win()
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_set_current_win(sidebar_win)
  end
  
  -- Clear the flag after a short delay
  vim.defer_fn(function()
    preview_state.is_focusing = false
  end, 50)
end

-- Focus the preview window
function M.focus_preview()
  -- Set focusing flag to prevent hiding
  preview_state.is_focusing = true
  
  -- Schedule clearing the flag after focus operation
  vim.schedule(function()
    preview_state.is_focusing = false
  end)
  
  -- Simple validation - check if we have a window
  if not preview_state.win or not preview_state.buf then
    logger.debug("No preview window or buffer to focus")
    preview_state.is_focusing = false
    return false
  end
  
  -- Single validation check with pcall
  local valid_ok, is_valid = pcall(vim.api.nvim_win_is_valid, preview_state.win)
  if not valid_ok or not is_valid then
    logger.debug("Preview window is not valid", { win = preview_state.win, valid_ok = valid_ok, is_valid = is_valid })
    preview_state.win = nil
    preview_state.buf = nil
    preview_state.is_focusing = false
    return false
  end
  
  -- Try to focus the window
  local focus_ok, focus_err = pcall(vim.api.nvim_set_current_win, preview_state.win)
  if not focus_ok then
    logger.debug("Failed to focus preview window", { error = focus_err })
    preview_state.win = nil
    preview_state.buf = nil
    preview_state.is_focusing = false
    return false
  end
  
  -- Use stored buffer - we know it exists from the check above
  local buf = preview_state.buf
  
  -- Set up keymaps
  M.setup_preview_keymaps(buf)
  
  -- Standard vim navigation should work for scrolling
  return true
end

-- Set up keymaps for preview buffer
function M.setup_preview_keymaps(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local opts = { buffer = buf, silent = true }
  
  -- Mouse click handler for preview window - handle clicks outside
  vim.keymap.set('n', '<LeftMouse>', function()
    local mouse_pos = vim.fn.getmousepos()
    local preview_win = preview_state.win
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local sidebar_win = sidebar.get_win()
    
    -- Check where we clicked
    if mouse_pos.winid == preview_win then
      -- Clicked within preview - let vim handle cursor movement naturally
      return '<LeftMouse>'
    elseif sidebar_win and mouse_pos.winid == sidebar_win then
      -- Clicked on sidebar - return focus to sidebar and process the click
      vim.schedule(function()
        vim.api.nvim_set_current_win(sidebar_win)
        
        -- Move cursor to clicked position
        local sidebar_buf = sidebar.get_buf()
        if sidebar_buf and vim.api.nvim_buf_is_valid(sidebar_buf) then
          local line_count = vim.api.nvim_buf_line_count(sidebar_buf)
          if mouse_pos.line > 0 and mouse_pos.line <= line_count then
            vim.api.nvim_win_set_cursor(sidebar_win, {mouse_pos.line, math.max(0, mouse_pos.column - 1)})
          end
          
          -- Update preview for the clicked email
          if M.is_preview_mode() then
            local main = require('neotex.plugins.tools.himalaya.ui.main')
            local email_id = main.get_current_email_id()
            local current_preview_id = M.get_current_preview_id()
            
            if email_id and email_id ~= current_preview_id then
              M.show_preview(email_id, sidebar_win)
            end
          end
        end
      end)
      return ''  -- Consume event
    else
      -- Clicked on a normal buffer - close preview and exit preview mode
      vim.schedule(function()
        M.disable_preview_mode()
        -- Focus the clicked window
        if mouse_pos.winid > 0 and vim.api.nvim_win_is_valid(mouse_pos.winid) then
          vim.api.nvim_set_current_win(mouse_pos.winid)
        end
      end)
      return ''  -- Consume event
    end
  end, vim.tbl_extend('force', opts, { desc = 'Handle mouse clicks in preview', expr = true }))
  
  -- q to close preview and exit preview mode
  vim.keymap.set('n', 'q', function()
    M.disable_preview_mode()
    M.return_to_sidebar()
  end, vim.tbl_extend('force', opts, { desc = 'Close preview and exit preview mode' }))
  
  -- Esc to return to sidebar
  vim.keymap.set('n', '<Esc>', function()
    M.return_to_sidebar()
  end, vim.tbl_extend('force', opts, { desc = 'Return to sidebar' }))
  
  -- Enter does nothing in preview (as requested)
  vim.keymap.set('n', '<CR>', '<Nop>', vim.tbl_extend('force', opts, { desc = 'Disabled in preview' }))
  
  -- Note: Mouse handling is done globally in preview mode, not buffer-locally
  
  -- Override 'g' to handle our custom g-commands (same pattern as email list)
  vim.keymap.set('n', 'g', function()
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    
    if key == 'r' then
      -- Reply to email
      if preview_state.email_id then
        local email_id = preview_state.email_id
        -- Close preview first
        M.hide_preview()
        -- Use main module's reply function
        local main = require('neotex.plugins.tools.himalaya.ui.main')
        -- Set the current email ID in state so reply_current_email can find it
        state.set('preview_email_id', email_id)
        main.reply_current_email()
      end
    elseif key == 'R' then
      -- Reply all
      if preview_state.email_id then
        local email_id = preview_state.email_id
        -- Close preview first
        M.hide_preview()
        -- Use main module's reply all function
        local main = require('neotex.plugins.tools.himalaya.ui.main')
        state.set('preview_email_id', email_id)
        main.reply_all_current_email()
      end
    elseif key == 'f' then
      -- Forward email
      if preview_state.email_id then
        local email_id = preview_state.email_id
        -- Close preview first
        M.hide_preview()
        -- Use main module's forward function
        local main = require('neotex.plugins.tools.himalaya.ui.main')
        state.set('preview_email_id', email_id)
        main.forward_current_email()
      end
    elseif key == 'D' then
      -- Delete email
      if preview_state.email_id then
        local email_id = preview_state.email_id
        -- Set the current email ID in state
        state.set('preview_email_id', email_id)
        -- Use main module's delete function
        local main = require('neotex.plugins.tools.himalaya.ui.main')
        main.delete_current_email()
        -- The delete function will handle closing views and refreshing
        M.hide_preview()
      end
    elseif key == 'A' then
      -- Archive email
      if preview_state.email_id then
        local email_id = preview_state.email_id
        -- Set the current email ID in state
        state.set('preview_email_id', email_id)
        -- Use main module's archive function
        local main = require('neotex.plugins.tools.himalaya.ui.main')
        main.archive_current_email()
        -- The archive function will handle closing views and refreshing
        M.hide_preview()
      end
    elseif key == 'S' then
      -- Mark as spam
      if preview_state.email_id then
        local email_id = preview_state.email_id
        -- Set the current email ID in state
        state.set('preview_email_id', email_id)
        -- Use main module's spam function
        local main = require('neotex.plugins.tools.himalaya.ui.main')
        main.spam_current_email()
        -- The spam function will handle closing views and refreshing
        M.hide_preview()
      end
    else
      -- Pass through to built-in g commands
      vim.api.nvim_feedkeys('g' .. key, 'n', false)
    end
  end, vim.tbl_extend('force', opts, { desc = 'Himalaya g-commands' }))
end

-- Update config
function M.update_config(cfg)
  M.config = vim.tbl_extend('force', M.config, cfg or {})
end

-- Cleanup function for buffer management
function M.cleanup_preview_buffers()
  for buf, _ in pairs(preview_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  preview_buffers = {}
end

-- Get preview state (for debugging)
function M.get_preview_state()
  return preview_state
end

-- Ensure preview window exists and is valid
function M.ensure_preview_window()
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    return preview_state.win
  end
  return nil
end

-- Set up global mouse handler for preview mode
local function setup_global_mouse_handler()
  -- Nothing needed here anymore, we'll use autocmds
end

-- Remove global mouse handler
local function remove_global_mouse_handler()
  -- Nothing to remove
end

-- Enable preview mode
function M.enable_preview_mode()
  preview_state.preview_mode = true
  logger.debug("Preview mode enabled")
  notify.himalaya("Preview mode enabled", notify.categories.STATUS)
  
  -- Don't use a global handler - we'll set window-specific handlers instead
end

-- Disable preview mode
function M.disable_preview_mode()
  preview_state.preview_mode = false
  M.hide_preview()
  logger.debug("Preview mode disabled")
  
  -- Debug: show who called disable_preview_mode
  local trace = debug.traceback("", 2)
  notify.himalaya("Preview mode disabled", notify.categories.STATUS, {
    caller = trace:match("([^\\n]+)")
  })
end

-- Check if preview mode is enabled
function M.is_preview_mode()
  return preview_state.preview_mode
end

-- Toggle preview mode
function M.toggle_preview_mode()
  if preview_state.preview_mode then
    M.disable_preview_mode()
  else
    M.enable_preview_mode()
  end
end

return M