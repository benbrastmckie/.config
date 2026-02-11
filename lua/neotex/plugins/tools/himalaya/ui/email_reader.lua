-- Email Reader Buffer Module
-- Provides a full buffer view for reading emails (BUFFER_OPEN state)

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local email_cache = require('neotex.plugins.tools.himalaya.data.cache')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local reader_state = {
  buf = nil,
  win = nil,
  email_id = nil,
  email_type = nil,
}

-- Configuration
M.config = {
  width_ratio = 0.6,  -- Percentage of editor width
  position = 'right',  -- 'right' or 'center'
  border = 'rounded',
  show_headers = true,
  syntax_highlight = true,
}

-- Create or get reader buffer
local function get_or_create_buffer()
  if reader_state.buf and vim.api.nvim_buf_is_valid(reader_state.buf) then
    return reader_state.buf
  end

  local buf = vim.api.nvim_create_buf(false, true)

  -- Buffer settings
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'undolevels', -1)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-email')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  reader_state.buf = buf
  return buf
end

-- Setup reader keymaps
-- Per task 56: NO single-letter action mappings in email reader
-- Actions should be accessed via which-key <leader>m menu
local function setup_reader_keymaps(buf)
  local opts = { buffer = buf, silent = true, nowait = true }

  -- Close reader and return to sidebar
  vim.keymap.set('n', 'q', function()
    M.close()
  end, vim.tbl_extend('force', opts, { desc = 'Close email reader' }))

  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, vim.tbl_extend('force', opts, { desc = 'Close email reader' }))

  -- Help - show which-key hint
  vim.keymap.set('n', '?', function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Actions: <leader>m for mail menu | q to close', notify.categories.STATUS)
  end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
end

-- Render email content in reader buffer
local function render_email(email, buf)
  local lines = {}
  local width = 80  -- Fixed width for email display

  -- Safe string conversion
  local function safe_tostring(val, default)
    if val == vim.NIL or val == nil then
      return default or ""
    end
    return tostring(val)
  end

  -- Header section
  if M.config.show_headers then
    local from = safe_tostring(email.from, "Unknown")
    local to = safe_tostring(email.to, "")
    local subject = safe_tostring(email.subject, "No subject")
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
    table.insert(lines, "Subject: " .. subject)
    table.insert(lines, "Date: " .. date)
    table.insert(lines, string.rep("-", width))
    table.insert(lines, "")
  end

  -- Body
  if email.body then
    local body_lines = vim.split(email.body, '\n', { plain = true })
    for _, line in ipairs(body_lines) do
      table.insert(lines, line)
    end
  else
    table.insert(lines, "Loading email content...")
  end

  -- Footer
  table.insert(lines, "")
  table.insert(lines, string.rep("-", width))
  table.insert(lines, "q:close | <leader>m for actions | ?:help")

  -- Update buffer
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Apply syntax highlighting
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

-- Open email in a full buffer (not a split)
-- Per task 56: Email opens in full buffer, not split
function M.open_email_buffer(email_id, email_type)
  if not email_id then
    logger.warn('Cannot open email buffer: no email_id provided')
    return false
  end

  email_type = email_type or 'regular'
  reader_state.email_id = email_id
  reader_state.email_type = email_type

  -- Get email content from cache
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local email = email_cache.get_email(account, folder, email_id)

  if not email then
    -- Try to load it
    email = {
      id = email_id,
      subject = 'Loading...',
      from = '',
      to = '',
      date = '',
      body = nil,
    }
  end

  -- Get cached body if available
  local cached_body = email_cache.get_email_body(account, folder, email_id)
  if cached_body then
    email.body = cached_body
  end

  -- Create buffer
  local buf = get_or_create_buffer()

  -- Close preview window if open
  local ok, email_preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
  if ok and email_preview.close then
    email_preview.close()
  end

  -- Get sidebar to hide it temporarily
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  local had_sidebar = sidebar_win and vim.api.nvim_win_is_valid(sidebar_win)

  -- Store sidebar state for restoration
  reader_state.had_sidebar = had_sidebar

  -- Hide sidebar temporarily for full-screen email view
  if had_sidebar then
    vim.api.nvim_win_hide(sidebar_win)
  end

  -- Use the current window for full buffer display
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'linebreak', true)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  vim.api.nvim_win_set_option(win, 'signcolumn', 'no')

  reader_state.win = win

  -- Setup keymaps
  setup_reader_keymaps(buf)

  -- Render email content
  render_email(email, buf)

  -- Load full content async if needed
  if not email.body then
    M.load_content_async(email_id, account, folder, buf)
  end

  -- Setup autocmd for cleanup when window is closed or buffer is wiped
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      M.on_window_closed()
    end,
  })

  logger.debug('Opened email reader in full buffer', { email_id = email_id })
  return true
end

-- Load email content asynchronously
function M.load_content_async(email_id, account, folder, buf)
  local cmd = {
    'himalaya',
    'message', 'read',
    '-a', account,
    '-f', folder,
    '--no-headers',
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
    on_exit = function(_, exit_code, _)
      if exit_code == 0 and #stdout_buffer > 0 then
        local body = table.concat(stdout_buffer, '\n')

        -- Update cache
        email_cache.store_email_body(account, folder, email_id, body)

        -- Update display if still showing this email
        if reader_state.email_id == email_id and buf and vim.api.nvim_buf_is_valid(buf) then
          vim.schedule(function()
            local email = email_cache.get_email(account, folder, email_id)
            if email then
              email.body = body
              render_email(email, buf)
            end
          end)
        end
      end
    end
  })
end

-- Close reader and return to sidebar
function M.close()
  -- Store whether we had a sidebar before closing
  local had_sidebar = reader_state.had_sidebar

  -- Wipe buffer (this triggers BufWipeout autocmd)
  if reader_state.buf and vim.api.nvim_buf_is_valid(reader_state.buf) then
    vim.api.nvim_buf_delete(reader_state.buf, { force = true })
  end

  -- Reset state
  reader_state.win = nil
  reader_state.buf = nil
  reader_state.email_id = nil
  reader_state.email_type = nil
  reader_state.had_sidebar = nil

  -- Reset preview state to OFF
  local ok, email_preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
  if ok then
    email_preview.set_mode(email_preview.PREVIEW_STATE.OFF)
  end

  -- Restore and focus sidebar if it was open before
  if had_sidebar then
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    -- Re-open sidebar (this will restore its state)
    sidebar.open()
    local sidebar_win = sidebar.get_win()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
      vim.api.nvim_set_current_win(sidebar_win)
    end
  end

  logger.debug('Closed email reader')
end

-- Handler for when window is closed externally
function M.on_window_closed()
  local had_sidebar = reader_state.had_sidebar

  reader_state.win = nil
  reader_state.buf = nil
  reader_state.email_id = nil
  reader_state.email_type = nil
  reader_state.had_sidebar = nil

  -- Reset preview state to OFF
  local ok, email_preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
  if ok then
    email_preview.set_mode(email_preview.PREVIEW_STATE.OFF)
  end

  -- Restore and focus sidebar if it was open before
  if had_sidebar then
    vim.schedule(function()
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      sidebar.open()
      local sidebar_win = sidebar.get_win()
      if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
        vim.api.nvim_set_current_win(sidebar_win)
      end
    end)
  end
end

-- Check if reader is open
function M.is_open()
  return reader_state.win and vim.api.nvim_win_is_valid(reader_state.win)
end

-- Get current email ID being read
function M.get_current_email_id()
  return reader_state.email_id
end

return M
