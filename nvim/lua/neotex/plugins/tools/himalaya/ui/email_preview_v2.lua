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
local preview_win = nil
local preview_buf = nil
local hover_timer = nil
local current_preview_id = nil
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
    focusable = true,  -- Make it focusable so we can enter it
    zindex = 50,
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
      -- Wrap long lines
      if #line > M.config.width - 4 then
        local pos = 1
        while pos <= #line do
          table.insert(lines, line:sub(pos, pos + M.config.width - 5))
          pos = pos + M.config.width - 4
        end
      else
        table.insert(lines, line)
      end
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
  -- Cancel any pending preview
  if hover_timer then
    vim.loop.timer_stop(hover_timer)
    hover_timer = nil
  end
  
  -- Close preview window if it exists
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
    preview_win = nil
  end
  
  -- Release preview buffer back to pool
  if preview_buf then
    M.release_preview_buffer(preview_buf)
    preview_buf = nil
  end
  
  current_preview_id = nil
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
  if not M.config.enabled then
    return
  end
  
  -- Don't show preview for the same email
  if email_id == current_preview_id and preview_win and vim.api.nvim_win_is_valid(preview_win) then
    return
  end
  
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
  if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
    preview_buf = M.get_or_create_preview_buffer()
    
    -- Get parent window
    local parent = parent_win or vim.api.nvim_get_current_win()
    local win_config = M.calculate_preview_position(parent)
    
    preview_win = vim.api.nvim_open_win(preview_buf, false, win_config)
    
    -- Set window options
    vim.api.nvim_win_set_option(preview_win, 'wrap', true)
    vim.api.nvim_win_set_option(preview_win, 'linebreak', true)
    vim.api.nvim_win_set_option(preview_win, 'cursorline', false)
  end
  
  -- Render cached content immediately
  M.render_preview(cached_email, preview_buf)
  current_preview_id = email_id
  
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
          if current_preview_id == email_id and preview_win and vim.api.nvim_win_is_valid(preview_win) then
            local cached = email_cache.get_email(account, folder, email_id)
            if cached then
              -- Cache the body
              email_cache.store_email_body(account, folder, email_id, body)
              -- Update the preview
              cached.body = body
              M.render_preview(cached, preview_buf)
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
              
              M.render_preview(email, preview_buf)
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
  return preview_win and vim.api.nvim_win_is_valid(preview_win)
end

-- Get current preview email ID
function M.get_current_preview_id()
  return current_preview_id
end

-- Focus the preview window
function M.focus_preview()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_set_current_win(preview_win)
    
    -- Set up keymaps for preview window
    local buf = vim.api.nvim_win_get_buf(preview_win)
    local opts = { buffer = buf, silent = true }
    
    -- q to return to sidebar
    vim.keymap.set('n', 'q', function()
      -- Find the sidebar window
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      local sidebar_win = sidebar.get_win()
      if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
        vim.api.nvim_set_current_win(sidebar_win)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Return to sidebar' }))
    
    -- Enter to open in buffer
    vim.keymap.set('n', '<CR>', function()
      if current_preview_id then
        -- Close preview
        M.hide_preview()
        -- Open email in buffer
        local viewer = require('neotex.plugins.tools.himalaya.ui.email_viewer_v2')
        viewer.view_email(current_preview_id)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Open email in buffer' }))
    
    -- Standard vim navigation should work for scrolling
    return true
  end
  return false
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

return M