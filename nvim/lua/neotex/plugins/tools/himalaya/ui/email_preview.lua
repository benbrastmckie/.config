-- Email preview functionality for hover display
local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local notify = require('neotex.util.notifications')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')

-- Module state
local preview_win = nil
local preview_buf = nil
local hover_timer = nil
local current_preview_id = nil
local email_body_cache = {} -- Cache email bodies to avoid repeated fetches

-- Configuration
M.config = {
  enabled = true,
  delay_ms = 500,
  width = 80,
  position = 'right', -- 'right' or 'bottom'
  show_headers = true,
  max_lines = 50,
}

-- Initialize the module with config
function M.setup(config)
  if config and config.preview then
    M.config = vim.tbl_extend('force', M.config, config.preview)
  end
  logger.debug('Email preview initialized', { config = M.config })
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
  
  -- Clear preview buffer
  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    vim.api.nvim_buf_delete(preview_buf, { force = true })
    preview_buf = nil
  end
  
  current_preview_id = nil
end

-- Render email content in preview buffer
local function render_preview(email)
  if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
    return
  end
  
  local lines = {}
  
  -- Add headers if enabled
  if M.config.show_headers then
    -- Handle from field (can be string or table)
    local from = "Unknown"
    if email.from then
      if type(email.from) == "table" then
        from = email.from.name or email.from.addr or "Unknown"
      else
        from = tostring(email.from)
      end
    end
    
    -- Handle to field (can be string or table)
    local to = "Unknown"
    if email.to then
      if type(email.to) == "table" then
        to = email.to.name or email.to.addr or "Unknown"
      else
        to = tostring(email.to)
      end
    end
    
    table.insert(lines, "From: " .. from)
    table.insert(lines, "To: " .. to)
    table.insert(lines, "Subject: " .. (email.subject or "No Subject"))
    table.insert(lines, "Date: " .. (email.date or "Unknown"))
    table.insert(lines, string.rep("─", M.config.width - 2))
    table.insert(lines, "")
  end
  
  -- Get email body
  local body_lines = {}
  if email.body then
    -- Split body into lines
    for line in email.body:gmatch("[^\r\n]+") do
      -- Wrap long lines
      if #line > M.config.width - 4 then
        local pos = 1
        while pos <= #line do
          table.insert(body_lines, line:sub(pos, pos + M.config.width - 5))
          pos = pos + M.config.width - 4
        end
      else
        table.insert(body_lines, line)
      end
    end
  else
    table.insert(body_lines, "Loading email content...")
  end
  
  -- Limit body lines
  for i = 1, math.min(#body_lines, M.config.max_lines) do
    table.insert(lines, body_lines[i])
  end
  
  if #body_lines > M.config.max_lines then
    table.insert(lines, "")
    table.insert(lines, "... (" .. (#body_lines - M.config.max_lines) .. " more lines)")
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_option(preview_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(preview_buf, 'modifiable', false)
  
  -- Set buffer options for better display
  vim.api.nvim_buf_set_option(preview_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(preview_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(preview_buf, 'filetype', 'mail')
  
  -- Apply syntax highlighting
  vim.api.nvim_buf_call(preview_buf, function()
    vim.cmd('syntax match mailHeader "^\\(From\\|To\\|Subject\\|Date\\):"')
    vim.cmd('syntax match mailEmail "<[^>]\\+@[^>]\\+>"')
    vim.cmd('syntax match mailQuoted "^>.*$"')
    vim.cmd('hi link mailHeader Keyword')
    vim.cmd('hi link mailEmail Underlined')
    vim.cmd('hi link mailQuoted Comment')
  end)
end

-- Show preview for an email
function M.show_preview(email_id, parent_win)
  if not M.config.enabled then
    return
  end
  
  -- Don't show preview for the same email
  if email_id == current_preview_id and preview_win and vim.api.nvim_win_is_valid(preview_win) then
    return
  end
  
  -- Cancel any pending preview
  if hover_timer then
    vim.loop.timer_stop(hover_timer)
  end
  
  hover_timer = vim.loop.new_timer()
  hover_timer:start(M.config.delay_ms, 0, vim.schedule_wrap(function()
    -- Get email content
    local account = state.get_current_account()
    local folder = state.get_current_folder()
    
    -- First, try to get email from the sidebar buffer (fast)
    local email = nil
    local sidebar_buf = sidebar.get_buf()
    if sidebar_buf and vim.api.nvim_buf_is_valid(sidebar_buf) then
      local emails = vim.b[sidebar_buf].himalaya_emails
      if emails then
        for _, e in ipairs(emails) do
          if tostring(e.id) == tostring(email_id) then
            email = vim.tbl_deep_extend("force", {}, e) -- Copy the email
            break
          end
        end
      end
    end
    
    if not email then
      logger.warn('Email not found in list', { id = email_id })
      return
    end
    
    -- Check if we have cached body
    local cache_key = account .. ":" .. folder .. ":" .. email_id
    if email_body_cache[cache_key] then
      email.body = email_body_cache[cache_key]
    else
      -- Show preview with loading message first
      email.body = "Loading email content..."
    end
    
    -- Create or reuse preview window
    if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
      preview_buf = vim.api.nvim_create_buf(false, true)
      
      -- Get parent window dimensions
      local parent = parent_win or vim.api.nvim_get_current_win()
      local width = M.config.width
      local height = vim.api.nvim_win_get_height(parent)
      local row = 0
      local col = vim.api.nvim_win_get_width(parent) + 1
      
      -- Adjust position based on config
      if M.config.position == 'bottom' then
        height = math.floor(height / 3)
        row = vim.api.nvim_win_get_height(parent) - height
        col = 0
        width = vim.api.nvim_win_get_width(parent)
      end
      
      preview_win = vim.api.nvim_open_win(preview_buf, false, {
        relative = 'win',
        win = parent,
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'single',
        title = ' Preview ',
        title_pos = 'center',
        focusable = false,
      })
      
      -- Set window options
      vim.api.nvim_win_set_option(preview_win, 'wrap', true)
      vim.api.nvim_win_set_option(preview_win, 'linebreak', true)
      vim.api.nvim_win_set_option(preview_win, 'cursorline', false)
    end
    
    -- Render email content
    render_preview(email)
    current_preview_id = email_id
    
    -- Async load full email body if not cached
    if not email_body_cache[cache_key] then
      vim.defer_fn(function()
        -- Only load if preview is still showing same email
        if current_preview_id == email_id then
          local full_email = utils.get_email_by_id(account, folder, email_id)
          if full_email and full_email.body then
            -- Cache the body
            email_body_cache[cache_key] = full_email.body
            
            -- Update the preview if still showing
            if current_preview_id == email_id and preview_win and vim.api.nvim_win_is_valid(preview_win) then
              email.body = full_email.body
              render_preview(email)
            end
          end
        end
      end, 100) -- Small delay to let preview show first
    end
    
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya('Showing preview for email: ' .. (email.subject or 'No Subject'), notify.categories.BACKGROUND)
    end
  end))
end

-- Check if preview is currently shown
function M.is_preview_shown()
  return preview_win and vim.api.nvim_win_is_valid(preview_win)
end

-- Get current preview email ID
function M.get_current_preview_id()
  return current_preview_id
end

-- Update config
function M.update_config(config)
  M.config = vim.tbl_extend('force', M.config, config or {})
end

return M