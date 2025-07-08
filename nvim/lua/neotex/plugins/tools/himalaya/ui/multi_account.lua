-- Multi-Account View Management
-- Provides unified, split, and tabbed views for multiple email accounts

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local notify = require('neotex.util.notifications')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
local utils = require('neotex.plugins.tools.himalaya.utils')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- View modes
M.modes = {
  UNIFIED = "unified",
  SPLIT = "split",
  TABBED = "tabbed",
  FOCUSED = "focused"
}

-- Current state
M.state = {
  mode = M.modes.FOCUSED, -- Default to single account view
  active_accounts = {},
  window_layout = {},
  refresh_interval = 60, -- seconds
  sync_in_progress = false,
  account_colors = {},
  unified_emails = {},
  current_tab = 1
}

-- Initialize multi-account view
function M.setup()
  -- Get all configured accounts
  local accounts = config.get('accounts', {})
  
  -- Filter active accounts
  M.state.active_accounts = {}
  for name, account in pairs(accounts) do
    if account.email then
      M.state.active_accounts[name] = account
    end
  end
  
  -- Generate account colors
  M.state.account_colors = M.generate_account_colors()
  
  -- Set default mode from config
  M.state.mode = config.get('ui.multi_account.default_mode', M.modes.FOCUSED)
  
  logger.debug('Multi-account setup complete with ' .. vim.tbl_count(M.state.active_accounts) .. ' accounts')
end

-- Generate unique colors for each account
function M.generate_account_colors()
  local colors = {
    'HimalayaAccountRed',
    'HimalayaAccountGreen',
    'HimalayaAccountYellow',
    'HimalayaAccountBlue',
    'HimalayaAccountMagenta',
    'HimalayaAccountCyan',
    'HimalayaAccountOrange',
    'HimalayaAccountPurple'
  }
  
  local account_colors = {}
  local i = 1
  
  for account_name, _ in pairs(M.state.active_accounts) do
    account_colors[account_name] = colors[i] or 'Normal'
    i = i + 1
    if i > #colors then i = 1 end
  end
  
  return account_colors
end

-- Create view based on mode
function M.create_view(mode)
  mode = mode or M.state.mode
  M.state.mode = mode
  
  logger.debug('Creating ' .. mode .. ' view')
  
  if mode == M.modes.UNIFIED then
    M.create_unified_view()
  elseif mode == M.modes.SPLIT then
    M.create_split_view()
  elseif mode == M.modes.TABBED then
    M.create_tabbed_view()
  elseif mode == M.modes.FOCUSED then
    M.create_focused_view()
  end
  
  -- Save current mode to state
  state.set('ui.multi_account_mode', mode)
  
  -- Notify user
  if mode ~= M.modes.FOCUSED then
    notify.himalaya('Switched to ' .. mode .. ' account view', notify.categories.STATUS)
  end
end

-- Create unified inbox view
function M.create_unified_view()
  -- Close existing windows
  M.close_all_account_windows()
  
  -- Collect emails from all accounts
  M.state.unified_emails = {}
  local total_count = 0
  
  for account_name, account in pairs(M.state.active_accounts) do
    -- Fetch emails for this account
    local emails = M.fetch_account_emails(account_name, 'INBOX')
    
    -- Add account info to each email
    for _, email in ipairs(emails) do
      email._account = account_name
      email._account_color = M.state.account_colors[account_name]
      table.insert(M.state.unified_emails, email)
    end
    
    total_count = total_count + #emails
  end
  
  -- Sort by date (newest first)
  table.sort(M.state.unified_emails, function(a, b)
    return (a.date or '') > (b.date or '')
  end)
  
  -- Create unified sidebar
  local sidebar_items = {
    {
      text = '📧 Unified Inbox (' .. total_count .. ')',
      type = 'header',
      expanded = true
    }
  }
  
  -- Add account breakdown
  for account_name, _ in pairs(M.state.active_accounts) do
    local account_emails = vim.tbl_filter(function(e) 
      return e._account == account_name 
    end, M.state.unified_emails)
    
    table.insert(sidebar_items, {
      text = '  ' .. account_name .. ' (' .. #account_emails .. ')',
      type = 'account',
      account = account_name,
      color = M.state.account_colors[account_name]
    })
  end
  
  -- Update sidebar if function is available
  if sidebar.update_items then
    sidebar.update_items(sidebar_items)
  else
    -- For now, just log that sidebar update is not available
    logger.debug('Sidebar update_items not available')
  end
  
  -- Display unified email list
  M.display_unified_emails()
end

-- Display unified email list with account indicators
function M.display_unified_emails()
  local main = require('neotex.plugins.tools.himalaya.ui.main')
  local bufnr = main.get_or_create_email_buffer()
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
  
  local lines = {}
  local highlights = {}
  
  -- Add header
  table.insert(lines, '=== Unified Inbox ===')
  table.insert(lines, '')
  
  -- Add emails with account indicators
  for i, email in ipairs(M.state.unified_emails) do
    local line = email_list.format_email_line(email)
    
    -- Prepend account indicator
    local account_abbr = string.sub(email._account, 1, 3):upper()
    line = '[' .. account_abbr .. '] ' .. line
    
    table.insert(lines, line)
    
    -- Store highlight info
    table.insert(highlights, {
      line = #lines - 1,
      col = 1,
      col_end = 5,
      hl_group = email._account_color
    })
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  -- Apply highlights
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      hl.hl_group,
      hl.line,
      hl.col,
      hl.col_end
    )
  end
  
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

-- Create split view (multiple accounts side by side)
function M.create_split_view()
  -- Close existing windows
  M.close_all_account_windows()
  
  local account_count = vim.tbl_count(M.state.active_accounts)
  if account_count == 0 then
    notify.himalaya('No accounts configured', notify.categories.WARNING)
    return
  end
  
  -- Calculate window dimensions
  local total_width = vim.o.columns
  local sidebar_width = sidebar.is_open() and 40 or 0
  local available_width = total_width - sidebar_width
  local window_width = math.floor(available_width / account_count)
  
  -- Create windows for each account
  local windows = {}
  local i = 0
  
  for account_name, _ in pairs(M.state.active_accounts) do
    if i > 0 then
      vim.cmd('vsplit')
    end
    
    -- Get current window
    local win = vim.api.nvim_get_current_win()
    windows[account_name] = win
    
    -- Set window width
    vim.api.nvim_win_set_width(win, window_width)
    
    -- Create buffer for this account
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, bufnr)
    
    -- Display account emails
    M.display_account_emails(account_name, bufnr)
    
    i = i + 1
  end
  
  -- Store window layout
  M.state.window_layout = windows
  
  -- Focus first window
  local first_win = vim.tbl_values(windows)[1]
  if first_win then
    vim.api.nvim_set_current_win(first_win)
  end
end

-- Create tabbed view
function M.create_tabbed_view()
  -- Close existing windows
  M.close_all_account_windows()
  
  -- Create tab pages for each account
  local tabs = {}
  local i = 0
  
  for account_name, _ in pairs(M.state.active_accounts) do
    if i > 0 then
      vim.cmd('tabnew')
    end
    
    -- Get current tab
    local tab = vim.api.nvim_get_current_tabpage()
    tabs[account_name] = tab
    
    -- Set tab label
    vim.cmd('TabLineSet ' .. account_name)
    
    -- Display account emails
    local bufnr = vim.api.nvim_get_current_buf()
    M.display_account_emails(account_name, bufnr)
    
    i = i + 1
  end
  
  -- Store tab layout
  M.state.window_layout = tabs
  
  -- Go to first tab
  vim.cmd('tabfirst')
end

-- Create focused view (single account)
function M.create_focused_view()
  -- This is the default single-account view
  -- Just ensure we're showing the current account
  local current_account = state.get('ui.current_account')
  
  if current_account then
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.refresh_email_list()
  end
end

-- Display emails for a specific account
function M.display_account_emails(account_name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_name(bufnr, 'himalaya-' .. account_name)
  
  -- Fetch emails
  local emails = M.fetch_account_emails(account_name, 'INBOX')
  
  local lines = {}
  
  -- Add header
  table.insert(lines, '=== ' .. account_name .. ' - INBOX ===')
  table.insert(lines, 'Emails: ' .. #emails)
  table.insert(lines, '')
  
  -- Add email lines
  for _, email in ipairs(emails) do
    table.insert(lines, email_list.format_email_line(email))
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  
  -- Set buffer filetype
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'himalaya-email-list')
end

-- Fetch emails for a specific account
function M.fetch_account_emails(account_name, folder)
  folder = folder or 'INBOX'
  
  -- Use cached emails if available and recent
  local cache_key = 'emails.' .. account_name .. '.' .. folder
  local cached = state.get(cache_key)
  
  if cached and cached.timestamp and (os.time() - cached.timestamp) < 60 then
    return cached.emails or {}
  end
  
  -- Fetch fresh emails
  local args = {
    'envelope', 'list',
    '--account', account_name,
    '--folder', folder,
    '--page-size', '50'
  }
  
  local result = utils.execute_himalaya(args)
  
  if result.error then
    logger.error('Failed to fetch emails for ' .. account_name .. ': ' .. result.error)
    return {}
  end
  
  local emails = result.emails or {}
  
  -- Cache the results
  state.set(cache_key, {
    emails = emails,
    timestamp = os.time()
  })
  
  return emails
end

-- Close all multi-account windows
function M.close_all_account_windows()
  -- Close any extra windows/tabs created for multi-account view
  if M.state.window_layout then
    for _, win_or_tab in pairs(M.state.window_layout) do
      pcall(function()
        if type(win_or_tab) == 'number' then
          -- It's a window
          if vim.api.nvim_win_is_valid(win_or_tab) then
            vim.api.nvim_win_close(win_or_tab, true)
          end
        end
      end)
    end
  end
  
  M.state.window_layout = {}
end

-- Switch to next account (for tabbed/focused modes)
function M.next_account()
  if M.state.mode == M.modes.TABBED then
    vim.cmd('tabnext')
  elseif M.state.mode == M.modes.FOCUSED then
    -- Cycle through accounts
    local accounts = vim.tbl_keys(M.state.active_accounts)
    local current = state.get('ui.current_account')
    local current_idx = 1
    
    for i, account in ipairs(accounts) do
      if account == current then
        current_idx = i
        break
      end
    end
    
    local next_idx = (current_idx % #accounts) + 1
    local next_account = accounts[next_idx]
    
    -- Switch to next account
    state.set('ui.current_account', next_account)
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.refresh_email_list()
    
    notify.himalaya('Switched to ' .. next_account, notify.categories.STATUS)
  end
end

-- Switch to previous account
function M.previous_account()
  if M.state.mode == M.modes.TABBED then
    vim.cmd('tabprevious')
  elseif M.state.mode == M.modes.FOCUSED then
    -- Cycle through accounts (reverse)
    local accounts = vim.tbl_keys(M.state.active_accounts)
    local current = state.get('ui.current_account')
    local current_idx = 1
    
    for i, account in ipairs(accounts) do
      if account == current then
        current_idx = i
        break
      end
    end
    
    local prev_idx = current_idx - 1
    if prev_idx < 1 then prev_idx = #accounts end
    local prev_account = accounts[prev_idx]
    
    -- Switch to previous account
    state.set('ui.current_account', prev_account)
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.refresh_email_list()
    
    notify.himalaya('Switched to ' .. prev_account, notify.categories.STATUS)
  end
end

-- Toggle between view modes
function M.toggle_mode()
  local modes = {M.modes.FOCUSED, M.modes.UNIFIED, M.modes.SPLIT, M.modes.TABBED}
  local current_idx = 1
  
  for i, mode in ipairs(modes) do
    if mode == M.state.mode then
      current_idx = i
      break
    end
  end
  
  local next_idx = (current_idx % #modes) + 1
  local next_mode = modes[next_idx]
  
  M.create_view(next_mode)
end

-- Refresh all account views
function M.refresh_all()
  if M.state.mode == M.modes.UNIFIED then
    M.create_unified_view()
  elseif M.state.mode == M.modes.SPLIT then
    -- Refresh each window
    for account_name, win in pairs(M.state.window_layout) do
      if vim.api.nvim_win_is_valid(win) then
        local bufnr = vim.api.nvim_win_get_buf(win)
        M.display_account_emails(account_name, bufnr)
      end
    end
  elseif M.state.mode == M.modes.TABBED then
    -- Refresh current tab
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local account_name = buf_name:match('himalaya%-(.+)')
    
    if account_name then
      M.display_account_emails(account_name, bufnr)
    end
  else
    -- Focused mode - use normal refresh
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.refresh_email_list()
  end
end

-- Get current view mode
function M.get_current_mode()
  return M.state.mode
end

-- Check if multi-account view is active
function M.is_multi_account_active()
  return M.state.mode ~= M.modes.FOCUSED
end

return M