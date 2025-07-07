# Himalaya Advanced Features Specification

**Implementation Phase: Phase 9 - Advanced Features & UI Evolution** - IN PROGRESS  
*Timeline: Weeks 5-6 of implementation*

This specification details the implementation plan for advanced features that extend the Himalaya email client beyond basic email management, providing power-user functionality and integration capabilities.

## Implementation Status

✅ **Phase 9 In Progress** - Implemented features:
- ✓ Undo Send System (#2) - Send queue with 60-second cancellation
- ✓ Advanced Search (#3) - 23+ search operators and filters
- ✓ Email Templates (#4) - Variable substitution and conditionals
- ✓ Notification System Integration - Full debug mode support

❌ **Not Yet Implemented**:
- Multiple Account Views (#1) - Unified inbox, split, tabbed views
- Email Scheduling (#5) - Future send capability
- Window Management Improvements - Enhanced UI coordination
- Email Rules and Filters (#7)
- Integration Features (#8)

## Overview

The advanced features transform Himalaya from a basic email client into a comprehensive email productivity suite, including delayed sending, advanced search, templates, scheduling, encryption, filtering, and integration with external tools. Most features are targeted for Phase 9, with PGP/GPG encryption (#6) deferred to Phase 10 security work.

## Feature Implementation Details

### 1. Multiple Account Views ❌ NOT IMPLEMENTED

**Priority**: Medium  
**Estimated Effort**: 1 week

#### 1.1 Unified Inbox

Create `ui/unified_inbox.lua`:

```lua
local M = {}
local accounts = require('neotex.plugins.tools.himalaya.core.accounts')
local email_service = require('neotex.plugins.tools.himalaya.service.email')
local notify = require('neotex.util.notifications')

-- Unified inbox state
M.state = {
  mode = "unified", -- unified, split, tabbed
  accounts = {},
  emails = {},
  sort_order = "date_desc",
  filters = {}
}

-- Fetch emails from all accounts
function M.fetch_unified_emails(options)
  options = options or {}
  local all_emails = {}
  local active_accounts = accounts.get_active_accounts()
  
  -- Fetch from each account in parallel
  local completed = 0
  local total = vim.tbl_count(active_accounts)
  
  for id, account in pairs(active_accounts) do
    vim.schedule(function()
      local emails = email_service.list(account, options.folder or "INBOX", options.page or 1)
      
      -- Add account info to each email
      for _, email in ipairs(emails) do
        email.account_id = id
        email.account_email = account.email
        email.account_color = M.get_account_color(id)
        table.insert(all_emails, email)
      end
      
      completed = completed + 1
      
      if completed == total then
        M.on_fetch_complete(all_emails)
      end
    end)
  end
end

-- Handle fetch completion
function M.on_fetch_complete(emails)
  -- Sort emails by date
  table.sort(emails, function(a, b)
    if M.state.sort_order == "date_desc" then
      return a.date > b.date
    else
      return a.date < b.date
    end
  end)
  
  M.state.emails = emails
  M.render()
end

-- Render unified view
function M.render()
  local buf = M.get_or_create_buffer()
  local lines = {}
  
  -- Header
  table.insert(lines, "Unified Inbox - " .. #M.state.emails .. " emails")
  table.insert(lines, string.rep("─", 80))
  
  -- Email list with account indicators
  for i, email in ipairs(M.state.emails) do
    local account_indicator = string.format("[%s]", email.account_email:sub(1, 10))
    local date = os.date("%m/%d %H:%M", email.date)
    local from = email.from and email.from:sub(1, 20) or "Unknown"
    local subject = email.subject or "No subject"
    
    local line = string.format(
      "%s %s %s %s - %s",
      email.account_color,
      account_indicator,
      date,
      from,
      subject
    )
    
    table.insert(lines, line)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  M.setup_keymaps(buf)
end

-- Account color assignment
function M.get_account_color(account_id)
  local colors = {
    "%1", "%2", "%3", "%4", "%5", "%6", "%7", "%8"
  }
  
  local index = 1
  for id, _ in pairs(accounts.get_active_accounts()) do
    if id == account_id then
      break
    end
    index = index + 1
  end
  
  return colors[(index - 1) % #colors + 1]
end

-- Split view mode
function M.create_split_view()
  local active_accounts = accounts.get_active_accounts()
  local account_count = vim.tbl_count(active_accounts)
  
  if account_count < 2 then
    notify.himalaya(
      "Need at least 2 accounts for split view",
      notify.categories.WARNING
    )
    return
  end
  
  -- Calculate split layout
  local cols = math.ceil(math.sqrt(account_count))
  local rows = math.ceil(account_count / cols)
  
  -- Create splits
  local windows = {}
  for i = 1, account_count do
    if i > 1 then
      if i % cols == 1 then
        vim.cmd('split')
      else
        vim.cmd('vsplit')
      end
    end
    
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    
    table.insert(windows, {
      win = win,
      buf = buf,
      account = nil
    })
  end
  
  -- Assign accounts to windows
  local i = 1
  for id, account in pairs(active_accounts) do
    windows[i].account = account
    M.render_account_view(windows[i].buf, account)
    i = i + 1
  end
  
  M.state.mode = "split"
  M.state.windows = windows
end

-- Tabbed view mode
function M.create_tabbed_view()
  local active_accounts = accounts.get_active_accounts()
  
  -- Create tabs
  for id, account in pairs(active_accounts) do
    vim.cmd('tabnew')
    local buf = vim.api.nvim_get_current_buf()
    
    M.render_account_view(buf, account)
    
    -- Set tab label
    vim.api.nvim_tabpage_set_var(0, 'tablabel', account.email)
  end
  
  -- Go to first tab
  vim.cmd('tabfirst')
  
  M.state.mode = "tabbed"
end

-- Render single account view
function M.render_account_view(buf, account)
  local emails = email_service.list(account, "INBOX", 1)
  local lines = {}
  
  -- Header
  table.insert(lines, account.email .. " - " .. #emails .. " emails")
  table.insert(lines, string.rep("─", 60))
  
  -- Email list
  for _, email in ipairs(emails) do
    local date = os.date("%m/%d %H:%M", email.date)
    local from = email.from and email.from:sub(1, 20) or "Unknown"
    local subject = email.subject or "No subject"
    
    local line = string.format("%s %s - %s", date, from, subject)
    table.insert(lines, line)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

-- Mode switching
function M.switch_mode(mode)
  if mode == M.state.mode then
    return
  end
  
  -- Clean up current mode
  if M.state.mode == "split" and M.state.windows then
    for _, win_info in ipairs(M.state.windows) do
      if vim.api.nvim_win_is_valid(win_info.win) then
        vim.api.nvim_win_close(win_info.win, true)
      end
    end
  elseif M.state.mode == "tabbed" then
    vim.cmd('tabonly')
  end
  
  -- Switch to new mode
  if mode == "unified" then
    M.fetch_unified_emails()
  elseif mode == "split" then
    M.create_split_view()
  elseif mode == "tabbed" then
    M.create_tabbed_view()
  end
  
  M.state.mode = mode
end

return M
```

### 2. Undo Send Email System ✅ IMPLEMENTED

**Priority**: High  
**Estimated Effort**: 4-5 days

#### 2.1 Delayed Send Queue

Create `core/send_queue.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')
local email_service = require('neotex.plugins.tools.himalaya.service.email')

-- Queue configuration
M.config = {
  delay_seconds = 60, -- 1 minute default delay
  check_interval = 5, -- Check queue every 5 seconds
  max_retries = 3
}

-- Queue state
M.queue = {}
M.timer = nil

-- Queue item structure
local queue_item_schema = {
  id = "",
  email_data = {},
  account_id = "",
  queued_at = 0,
  send_at = 0,
  status = "pending", -- pending, sending, sent, cancelled, failed
  retries = 0,
  error = nil
}

-- Initialize queue
function M.init()
  -- Load queue from state
  M.queue = state.get('send_queue') or {}
  
  -- Start queue processor
  M.start_processor()
  
  -- Clean old items
  M.cleanup_old_items()
end

-- Add email to queue
function M.queue_email(email_data, account_id)
  local id = vim.fn.tempname():match("([^/]+)$")
  local now = os.time()
  
  local item = {
    id = id,
    email_data = email_data,
    account_id = account_id,
    queued_at = now,
    send_at = now + M.config.delay_seconds,
    status = "pending",
    retries = 0
  }
  
  M.queue[id] = item
  M.save_queue()
  
  notify.himalaya(
    string.format("Email queued. Will send in %d seconds", M.config.delay_seconds),
    notify.categories.USER_ACTION,
    { 
      id = id,
      subject = email_data.subject,
      can_undo = true
    }
  )
  
  -- Show undo notification
  M.show_undo_notification(id)
  
  return id
end

-- Cancel queued email
function M.cancel_send(id)
  local item = M.queue[id]
  
  if not item then
    notify.himalaya(
      "Email not found in queue",
      notify.categories.ERROR
    )
    return false
  end
  
  if item.status ~= "pending" then
    notify.himalaya(
      "Cannot cancel - email already " .. item.status,
      notify.categories.WARNING
    )
    return false
  end
  
  item.status = "cancelled"
  M.save_queue()
  
  notify.himalaya(
    "Email send cancelled",
    notify.categories.USER_ACTION,
    { subject = item.email_data.subject }
  )
  
  return true
end

-- Show undo notification with timer
function M.show_undo_notification(id)
  local item = M.queue[id]
  if not item then return end
  
  -- Create floating window for undo
  local remaining = item.send_at - os.time()
  local buf = vim.api.nvim_create_buf(false, true)
  
  local width = 50
  local height = 4
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    col = vim.o.columns - width - 2,
    row = vim.o.lines - height - 2,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Update countdown
  local update_timer
  update_timer = vim.loop.new_timer()
  
  local function update_display()
    local now = os.time()
    local remaining = item.send_at - now
    
    if remaining <= 0 or item.status ~= "pending" then
      update_timer:stop()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      return
    end
    
    local lines = {
      "Sending email in " .. remaining .. " seconds",
      "Subject: " .. (item.email_data.subject or "No subject"),
      "",
      "Press 'u' to undo, ESC to dismiss"
    }
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  
  update_display()
  update_timer:start(0, 1000, vim.schedule_wrap(update_display))
  
  -- Set up keymaps
  vim.api.nvim_buf_set_keymap(buf, 'n', 'u', '', {
    callback = function()
      M.cancel_send(id)
      update_timer:stop()
      vim.api.nvim_win_close(win, true)
    end
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
    callback = function()
      update_timer:stop()
      vim.api.nvim_win_close(win, true)
    end
  })
end

-- Queue processor
function M.start_processor()
  if M.timer then
    M.timer:stop()
  end
  
  M.timer = vim.loop.new_timer()
  M.timer:start(
    M.config.check_interval * 1000,
    M.config.check_interval * 1000,
    vim.schedule_wrap(function()
      M.process_queue()
    end)
  )
end

-- Process pending emails
function M.process_queue()
  local now = os.time()
  
  for id, item in pairs(M.queue) do
    if item.status == "pending" and now >= item.send_at then
      M.send_queued_email(id)
    end
  end
end

-- Send queued email
function M.send_queued_email(id)
  local item = M.queue[id]
  if not item then return end
  
  item.status = "sending"
  M.save_queue()
  
  -- Get account
  local account = require('neotex.plugins.tools.himalaya.core.accounts')
    .get_account(item.account_id)
  
  if not account then
    item.status = "failed"
    item.error = "Account not found"
    M.save_queue()
    return
  end
  
  -- Send email
  local result = email_service.send(account, item.email_data)
  
  if result.success then
    item.status = "sent"
    notify.himalaya(
      "Email sent successfully",
      notify.categories.USER_ACTION,
      { subject = item.email_data.subject }
    )
  else
    item.retries = item.retries + 1
    
    if item.retries < M.config.max_retries then
      item.status = "pending"
      item.send_at = os.time() + (60 * item.retries) -- Exponential backoff
      
      notify.himalaya(
        "Send failed, will retry",
        notify.categories.WARNING,
        { 
          subject = item.email_data.subject,
          error = result.error,
          retry_in = 60 * item.retries
        }
      )
    else
      item.status = "failed"
      item.error = result.error
      
      notify.himalaya(
        "Email send failed permanently",
        notify.categories.ERROR,
        { 
          subject = item.email_data.subject,
          error = result.error
        }
      )
    end
  end
  
  M.save_queue()
end

-- Show queue status
function M.show_queue()
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {"Send Queue Status", ""}
  
  local pending = 0
  local sent = 0
  local failed = 0
  
  for id, item in pairs(M.queue) do
    if item.status == "pending" then
      pending = pending + 1
      local remaining = item.send_at - os.time()
      table.insert(lines, string.format(
        "⏱  %s - sends in %ds",
        item.email_data.subject or "No subject",
        math.max(0, remaining)
      ))
    elseif item.status == "sent" then
      sent = sent + 1
    elseif item.status == "failed" then
      failed = failed + 1
      table.insert(lines, string.format(
        "✗ %s - %s",
        item.email_data.subject or "No subject",
        item.error or "Unknown error"
      ))
    end
  end
  
  table.insert(lines, 2, string.format(
    "Pending: %d | Sent: %d | Failed: %d",
    pending, sent, failed
  ))
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open in split
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "Email Send Queue")
end

-- Save queue state
function M.save_queue()
  state.set('send_queue', M.queue)
end

-- Cleanup old items
function M.cleanup_old_items()
  local cutoff = os.time() - (24 * 60 * 60) -- 24 hours
  local cleaned = 0
  
  for id, item in pairs(M.queue) do
    if item.status == "sent" and item.queued_at < cutoff then
      M.queue[id] = nil
      cleaned = cleaned + 1
    end
  end
  
  if cleaned > 0 then
    M.save_queue()
    notify.himalaya(
      string.format("Cleaned %d old queue items", cleaned),
      notify.categories.BACKGROUND
    )
  end
end

return M
```

### 3. Advanced Search ✅ IMPLEMENTED

**Priority**: High  
**Estimated Effort**: 1 week

#### 3.1 Search Engine

Create `core/search.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Search operators
M.operators = {
  from = { field = "from", type = "text" },
  to = { field = "to", type = "text" },
  subject = { field = "subject", type = "text" },
  body = { field = "body", type = "text" },
  date = { field = "date", type = "date" },
  before = { field = "date", type = "date", op = "<" },
  after = { field = "date", type = "date", op = ">" },
  has = { field = "flags", type = "flag" },
  is = { field = "status", type = "status" },
  folder = { field = "folder", type = "text" },
  size = { field = "size", type = "size" },
  attachment = { field = "has_attachment", type = "boolean" }
}

-- Parse search query
function M.parse_query(query)
  local tokens = {}
  local current = ""
  local in_quotes = false
  
  -- Tokenize query
  for char in query:gmatch(".") do
    if char == '"' then
      in_quotes = not in_quotes
    elseif char == ' ' and not in_quotes then
      if current ~= "" then
        table.insert(tokens, current)
        current = ""
      end
    else
      current = current .. char
    end
  end
  
  if current ~= "" then
    table.insert(tokens, current)
  end
  
  -- Parse tokens into search criteria
  local criteria = {
    operators = {},
    text = {}
  }
  
  local i = 1
  while i <= #tokens do
    local token = tokens[i]
    local operator, value = token:match("^(%w+):(.+)$")
    
    if operator and M.operators[operator] then
      -- Remove quotes if present
      value = value:gsub('^"', ''):gsub('"$', '')
      
      table.insert(criteria.operators, {
        operator = operator,
        value = value,
        config = M.operators[operator]
      })
    else
      -- Plain text search
      table.insert(criteria.text, token)
    end
    
    i = i + 1
  end
  
  return criteria
end

-- Execute search
function M.search(query, options)
  options = options or {}
  local criteria = M.parse_query(query)
  
  -- Get emails to search
  local emails = M.get_searchable_emails(options)
  local results = {}
  
  -- Apply search criteria
  for _, email in ipairs(emails) do
    if M.match_email(email, criteria) then
      table.insert(results, email)
    end
  end
  
  -- Sort results
  M.sort_results(results, options.sort or "relevance")
  
  return results
end

-- Match email against criteria
function M.match_email(email, criteria)
  -- Check operator criteria
  for _, op in ipairs(criteria.operators) do
    if not M.match_operator(email, op) then
      return false
    end
  end
  
  -- Check text search
  if #criteria.text > 0 then
    local text_query = table.concat(criteria.text, " "):lower()
    local searchable_text = M.get_searchable_text(email):lower()
    
    if not searchable_text:find(text_query, 1, true) then
      return false
    end
  end
  
  return true
end

-- Match specific operator
function M.match_operator(email, op)
  local config = op.config
  local email_value = email[config.field]
  
  if config.type == "text" then
    if type(email_value) == "table" then
      -- Search in array fields (to, cc, etc)
      for _, val in ipairs(email_value) do
        if val:lower():find(op.value:lower(), 1, true) then
          return true
        end
      end
      return false
    else
      return email_value and email_value:lower():find(op.value:lower(), 1, true)
    end
    
  elseif config.type == "date" then
    local op_date = M.parse_date(op.value)
    if not op_date then return false end
    
    if config.op == "<" then
      return email.date < op_date
    elseif config.op == ">" then
      return email.date > op_date
    else
      -- Same day comparison
      local email_day = os.date("%Y-%m-%d", email.date)
      local op_day = os.date("%Y-%m-%d", op_date)
      return email_day == op_day
    end
    
  elseif config.type == "flag" then
    return email.flags and vim.tbl_contains(email.flags, op.value)
    
  elseif config.type == "status" then
    if op.value == "unread" then
      return not email.read
    elseif op.value == "read" then
      return email.read
    elseif op.value == "starred" then
      return email.starred
    end
    
  elseif config.type == "size" then
    local size = M.parse_size(op.value)
    return email.size and email.size >= size
    
  elseif config.type == "boolean" then
    if config.field == "has_attachment" then
      return email.attachments and #email.attachments > 0
    end
  end
  
  return false
end

-- Get searchable text from email
function M.get_searchable_text(email)
  local parts = {
    email.from or "",
    table.concat(email.to or {}, " "),
    email.subject or "",
    email.body or email.preview or ""
  }
  
  return table.concat(parts, " ")
end

-- Parse date string
function M.parse_date(date_str)
  -- Support various formats
  local patterns = {
    "(%d+)/(%d+)/(%d+)", -- MM/DD/YYYY
    "(%d+)-(%d+)-(%d+)", -- YYYY-MM-DD
    "today",
    "yesterday",
    "(%d+)d", -- X days ago
    "(%d+)w", -- X weeks ago
    "(%d+)m", -- X months ago
  }
  
  if date_str == "today" then
    return os.time({
      year = os.date("%Y"),
      month = os.date("%m"),
      day = os.date("%d"),
      hour = 0, min = 0, sec = 0
    })
  elseif date_str == "yesterday" then
    return os.time() - (24 * 60 * 60)
  end
  
  -- Parse relative dates
  local num, unit = date_str:match("(%d+)([dwm])")
  if num and unit then
    local multiplier = {
      d = 24 * 60 * 60,
      w = 7 * 24 * 60 * 60,
      m = 30 * 24 * 60 * 60
    }
    return os.time() - (tonumber(num) * multiplier[unit])
  end
  
  -- Parse absolute dates
  -- Add more parsing logic as needed
  
  return nil
end

-- Parse size string
function M.parse_size(size_str)
  local num, unit = size_str:match("(%d+)([KMG]?B?)")
  if not num then return 0 end
  
  local multipliers = {
    [""] = 1,
    ["B"] = 1,
    ["K"] = 1024,
    ["KB"] = 1024,
    ["M"] = 1024 * 1024,
    ["MB"] = 1024 * 1024,
    ["G"] = 1024 * 1024 * 1024,
    ["GB"] = 1024 * 1024 * 1024
  }
  
  return tonumber(num) * (multipliers[unit] or 1)
end

-- Sort search results
function M.sort_results(results, sort_by)
  if sort_by == "date" then
    table.sort(results, function(a, b) return a.date > b.date end)
  elseif sort_by == "relevance" then
    -- Implement relevance scoring
    -- For now, just sort by date
    table.sort(results, function(a, b) return a.date > b.date end)
  elseif sort_by == "sender" then
    table.sort(results, function(a, b) 
      return (a.from or "") < (b.from or "")
    end)
  end
end

-- Search UI
function M.show_search_ui()
  -- Create search input buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = 3
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = 5,
    style = 'minimal',
    border = 'rounded',
    title = 'Email Search',
    title_pos = 'center'
  })
  
  -- Add search hints
  local hints = {
    "Search: from:john subject:\"meeting notes\" after:2024-01-01 has:attachment",
    "Operators: from: to: subject: body: date: before: after: has: is: folder: size:",
    ""
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, hints)
  vim.api.nvim_win_set_cursor(win, {3, 0})
  
  -- Set up search execution
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
    callback = function()
      local query = vim.api.nvim_get_current_line()
      vim.api.nvim_win_close(win, true)
      M.execute_search(query)
    end
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
    callback = function()
      local query = vim.api.nvim_get_current_line()
      vim.api.nvim_win_close(win, true)
      M.execute_search(query)
    end
  })
  
  -- Start insert mode
  vim.cmd('startinsert')
end

-- Execute search and show results
function M.execute_search(query)
  if query == "" then return end
  
  notify.himalaya(
    "Searching: " .. query,
    notify.categories.STATUS
  )
  
  local results = M.search(query)
  
  if #results == 0 then
    notify.himalaya(
      "No results found",
      notify.categories.STATUS
    )
    return
  end
  
  -- Show results in email list
  require('neotex.plugins.tools.himalaya.ui.email_list')
    .show_search_results(results, query)
end

return M
```

### 4. Email Templates ✅ IMPLEMENTED

**Priority**: Medium  
**Estimated Effort**: 3-4 days

#### 4.1 Template Management

Create `core/templates.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Template structure
local template_schema = {
  id = "",
  name = "",
  description = "",
  subject = "",
  body = "",
  variables = {}, -- {name, description, default}
  attachments = {}, -- Default attachments
  headers = {}, -- Custom headers
  created_at = 0,
  updated_at = 0,
  used_count = 0
}

-- Get all templates
function M.get_templates()
  return state.get('email_templates') or {}
end

-- Get template by ID
function M.get_template(id)
  local templates = M.get_templates()
  return templates[id]
end

-- Create new template
function M.create_template(template_data)
  local templates = M.get_templates()
  
  -- Generate ID
  local id = template_data.name:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
  
  -- Check for duplicate
  if templates[id] then
    local i = 2
    while templates[id .. "_" .. i] do
      i = i + 1
    end
    id = id .. "_" .. i
  end
  
  -- Create template
  local template = vim.tbl_extend('force', {
    id = id,
    created_at = os.time(),
    updated_at = os.time(),
    used_count = 0,
    variables = {},
    attachments = {},
    headers = {}
  }, template_data)
  
  -- Extract variables from template
  template.variables = M.extract_variables(template.body)
  
  templates[id] = template
  state.set('email_templates', templates)
  
  notify.himalaya(
    "Template created: " .. template.name,
    notify.categories.USER_ACTION
  )
  
  return template
end

-- Extract template variables
function M.extract_variables(text)
  local variables = {}
  local seen = {}
  
  -- Find {{variable}} patterns
  for var in text:gmatch("{{%s*([%w_]+)%s*}}") do
    if not seen[var] then
      seen[var] = true
      table.insert(variables, {
        name = var,
        description = "",
        default = ""
      })
    end
  end
  
  return variables
end

-- Apply template
function M.apply_template(template_id, variables)
  local template = M.get_template(template_id)
  if not template then
    return nil, "Template not found"
  end
  
  -- Update usage count
  template.used_count = template.used_count + 1
  local templates = M.get_templates()
  templates[template_id] = template
  state.set('email_templates', templates)
  
  -- Process template
  local result = {
    subject = template.subject,
    body = template.body,
    headers = vim.deepcopy(template.headers),
    attachments = vim.deepcopy(template.attachments)
  }
  
  -- Replace variables
  for var_name, var_value in pairs(variables) do
    local pattern = "{{%s*" .. var_name .. "%s*}}"
    result.subject = result.subject:gsub(pattern, var_value)
    result.body = result.body:gsub(pattern, var_value)
  end
  
  -- Apply defaults for missing variables
  for _, var in ipairs(template.variables) do
    if not variables[var.name] and var.default ~= "" then
      local pattern = "{{%s*" .. var.name .. "%s*}}"
      result.subject = result.subject:gsub(pattern, var.default)
      result.body = result.body:gsub(pattern, var.default)
    end
  end
  
  return result
end

-- Template editor UI
function M.edit_template(template_id)
  local template = template_id and M.get_template(template_id) or {
    name = "",
    description = "",
    subject = "",
    body = "",
    headers = {}
  }
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Email Template Editor")
  
  -- Template content
  local lines = {
    "# Email Template",
    "",
    "Name: " .. template.name,
    "Description: " .. template.description,
    "",
    "## Subject",
    template.subject,
    "",
    "## Body",
  }
  
  -- Add body lines
  for line in template.body:gmatch("[^\n]+") do
    table.insert(lines, line)
  end
  
  -- Add variables section
  table.insert(lines, "")
  table.insert(lines, "## Variables")
  table.insert(lines, "# Use {{variable_name}} in subject or body")
  
  if template.variables and #template.variables > 0 then
    for _, var in ipairs(template.variables) do
      table.insert(lines, string.format("# %s: %s", var.name, var.description))
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set filetype for syntax highlighting
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  
  -- Open in split
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Save template on write
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      M.save_template_from_buffer(buf, template_id)
    end
  })
end

-- Save template from buffer
function M.save_template_from_buffer(buf, template_id)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Parse buffer content
  local template = {
    name = "",
    description = "",
    subject = "",
    body = "",
    headers = {}
  }
  
  local section = nil
  local body_lines = {}
  
  for _, line in ipairs(lines) do
    if line:match("^Name: ") then
      template.name = line:match("^Name: (.+)$")
    elseif line:match("^Description: ") then
      template.description = line:match("^Description: (.+)$")
    elseif line == "## Subject" then
      section = "subject"
    elseif line == "## Body" then
      section = "body"
    elseif line == "## Variables" then
      section = "variables"
    elseif section == "subject" and not line:match("^#") then
      template.subject = line
    elseif section == "body" and not line:match("^#") then
      table.insert(body_lines, line)
    end
  end
  
  template.body = table.concat(body_lines, "\n")
  
  -- Save template
  if template_id then
    -- Update existing
    local templates = M.get_templates()
    templates[template_id] = vim.tbl_extend('force', templates[template_id], template)
    templates[template_id].updated_at = os.time()
    state.set('email_templates', templates)
  else
    -- Create new
    M.create_template(template)
  end
  
  notify.himalaya(
    "Template saved: " .. template.name,
    notify.categories.USER_ACTION
  )
  
  -- Mark buffer as saved
  vim.api.nvim_buf_set_option(buf, 'modified', false)
end

-- Template picker UI
function M.pick_template(callback)
  local templates = M.get_templates()
  local items = {}
  
  for id, template in pairs(templates) do
    table.insert(items, {
      id = id,
      label = string.format("%s - %s", template.name, template.description),
      template = template
    })
  end
  
  -- Sort by usage
  table.sort(items, function(a, b)
    return a.template.used_count > b.template.used_count
  end)
  
  local labels = vim.tbl_map(function(item) return item.label end, items)
  
  vim.ui.select(labels, {
    prompt = "Select template:",
    format_item = function(item) return item end
  }, function(choice, idx)
    if choice and callback then
      local selected = items[idx]
      
      -- Get variables if needed
      if #selected.template.variables > 0 then
        M.get_template_variables(selected.template, function(variables)
          callback(selected.id, variables)
        end)
      else
        callback(selected.id, {})
      end
    end
  end)
end

-- Get template variables from user
function M.get_template_variables(template, callback)
  local variables = {}
  local var_index = 1
  
  local function get_next_variable()
    if var_index > #template.variables then
      callback(variables)
      return
    end
    
    local var = template.variables[var_index]
    
    vim.ui.input({
      prompt = string.format("%s: ", var.name),
      default = var.default
    }, function(value)
      if value then
        variables[var.name] = value
        var_index = var_index + 1
        get_next_variable()
      else
        callback(nil) -- Cancelled
      end
    end)
  end
  
  get_next_variable()
end

return M
```

### 5. Email Scheduling ❌ NOT IMPLEMENTED

**Priority**: Medium  
**Estimated Effort**: 3-4 days

#### 5.1 Schedule Management

Create `core/scheduler.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')
local send_queue = require('neotex.plugins.tools.himalaya.core.send_queue')

-- Scheduled email structure
local scheduled_email_schema = {
  id = "",
  email_data = {},
  account_id = "",
  scheduled_for = 0, -- Unix timestamp
  created_at = 0,
  status = "scheduled", -- scheduled, sent, cancelled, failed
  recurrence = nil, -- {type = "daily|weekly|monthly", interval = 1}
  timezone = "UTC"
}

-- Get scheduled emails
function M.get_scheduled_emails()
  return state.get('scheduled_emails') or {}
end

-- Schedule email
function M.schedule_email(email_data, account_id, schedule_time, recurrence)
  local scheduled = M.get_scheduled_emails()
  local id = vim.fn.tempname():match("([^/]+)$")
  
  local item = {
    id = id,
    email_data = email_data,
    account_id = account_id,
    scheduled_for = schedule_time,
    created_at = os.time(),
    status = "scheduled",
    recurrence = recurrence,
    timezone = os.date("%z")
  }
  
  scheduled[id] = item
  state.set('scheduled_emails', scheduled)
  
  notify.himalaya(
    string.format("Email scheduled for %s", os.date("%Y-%m-%d %H:%M", schedule_time)),
    notify.categories.USER_ACTION,
    { subject = email_data.subject }
  )
  
  return id
end

-- Cancel scheduled email
function M.cancel_scheduled(id)
  local scheduled = M.get_scheduled_emails()
  local item = scheduled[id]
  
  if not item then
    return false, "Scheduled email not found"
  end
  
  if item.status ~= "scheduled" then
    return false, "Cannot cancel - already " .. item.status
  end
  
  item.status = "cancelled"
  state.set('scheduled_emails', scheduled)
  
  notify.himalaya(
    "Scheduled email cancelled",
    notify.categories.USER_ACTION,
    { subject = item.email_data.subject }
  )
  
  return true
end

-- Process scheduled emails
function M.process_scheduled()
  local scheduled = M.get_scheduled_emails()
  local now = os.time()
  
  for id, item in pairs(scheduled) do
    if item.status == "scheduled" and now >= item.scheduled_for then
      -- Add to send queue
      send_queue.queue_email(item.email_data, item.account_id)
      
      -- Update status
      item.status = "sent"
      
      -- Handle recurrence
      if item.recurrence then
        M.create_next_recurrence(item)
      end
    end
  end
  
  state.set('scheduled_emails', scheduled)
end

-- Create next recurrence
function M.create_next_recurrence(item)
  local next_time = item.scheduled_for
  
  if item.recurrence.type == "daily" then
    next_time = next_time + (24 * 60 * 60 * item.recurrence.interval)
  elseif item.recurrence.type == "weekly" then
    next_time = next_time + (7 * 24 * 60 * 60 * item.recurrence.interval)
  elseif item.recurrence.type == "monthly" then
    -- Add months (approximate)
    next_time = next_time + (30 * 24 * 60 * 60 * item.recurrence.interval)
  end
  
  -- Create new scheduled item
  M.schedule_email(
    item.email_data,
    item.account_id,
    next_time,
    item.recurrence
  )
end

-- Schedule UI
function M.show_schedule_ui(email_data, account_id)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "Schedule Email",
    "",
    "Subject: " .. (email_data.subject or "No subject"),
    "",
    "When to send:",
    "1. In 1 hour",
    "2. In 4 hours",
    "3. Tomorrow morning (9 AM)",
    "4. Tomorrow afternoon (2 PM)",
    "5. Next Monday (9 AM)",
    "6. Custom date/time",
    "",
    "Press number to select, or 'c' to cancel"
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  local width = 50
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Handle selection
  for i = 1, 6 do
    vim.api.nvim_buf_set_keymap(buf, 'n', tostring(i), '', {
      callback = function()
        vim.api.nvim_win_close(win, true)
        M.handle_schedule_selection(i, email_data, account_id)
      end
    })
  end
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 'c', ':close<CR>', { buffer = buf })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { buffer = buf })
end

-- Handle schedule selection
function M.handle_schedule_selection(choice, email_data, account_id)
  local schedule_time
  
  if choice == 1 then
    schedule_time = os.time() + (60 * 60) -- 1 hour
  elseif choice == 2 then
    schedule_time = os.time() + (4 * 60 * 60) -- 4 hours
  elseif choice == 3 then
    -- Tomorrow 9 AM
    local tomorrow = os.date("*t", os.time() + (24 * 60 * 60))
    tomorrow.hour = 9
    tomorrow.min = 0
    tomorrow.sec = 0
    schedule_time = os.time(tomorrow)
  elseif choice == 4 then
    -- Tomorrow 2 PM
    local tomorrow = os.date("*t", os.time() + (24 * 60 * 60))
    tomorrow.hour = 14
    tomorrow.min = 0
    tomorrow.sec = 0
    schedule_time = os.time(tomorrow)
  elseif choice == 5 then
    -- Next Monday 9 AM
    local days_until_monday = (8 - os.date("*t").wday) % 7
    if days_until_monday == 0 then days_until_monday = 7 end
    
    local next_monday = os.date("*t", os.time() + (days_until_monday * 24 * 60 * 60))
    next_monday.hour = 9
    next_monday.min = 0
    next_monday.sec = 0
    schedule_time = os.time(next_monday)
  elseif choice == 6 then
    -- Custom date/time
    M.get_custom_schedule_time(function(custom_time)
      if custom_time then
        M.schedule_email(email_data, account_id, custom_time)
      end
    end)
    return
  end
  
  if schedule_time then
    M.schedule_email(email_data, account_id, schedule_time)
  end
end

-- Get custom schedule time
function M.get_custom_schedule_time(callback)
  vim.ui.input({
    prompt = "Enter date and time (YYYY-MM-DD HH:MM): "
  }, function(input)
    if not input then
      callback(nil)
      return
    end
    
    -- Parse date/time
    local year, month, day, hour, min = input:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    
    if year and month and day and hour and min then
      local time = os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = 0
      })
      
      callback(time)
    else
      notify.himalaya(
        "Invalid date format. Use YYYY-MM-DD HH:MM",
        notify.categories.ERROR
      )
      callback(nil)
    end
  end)
end

-- Show scheduled emails
function M.show_scheduled()
  local scheduled = M.get_scheduled_emails()
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {"Scheduled Emails", ""}
  
  -- Group by status
  local by_status = {}
  for id, item in pairs(scheduled) do
    by_status[item.status] = by_status[item.status] or {}
    table.insert(by_status[item.status], item)
  end
  
  -- Show scheduled emails
  if by_status.scheduled then
    table.insert(lines, "Scheduled:")
    for _, item in ipairs(by_status.scheduled) do
      local when = os.date("%Y-%m-%d %H:%M", item.scheduled_for)
      local recur = item.recurrence and " (recurring)" or ""
      table.insert(lines, string.format(
        "  %s - %s%s",
        when,
        item.email_data.subject or "No subject",
        recur
      ))
    end
    table.insert(lines, "")
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open in split
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "Scheduled Emails")
end

-- Initialize scheduler
function M.init()
  -- Start scheduler timer
  local timer = vim.loop.new_timer()
  timer:start(
    60000, -- Check every minute
    60000,
    vim.schedule_wrap(function()
      M.process_scheduled()
    end)
  )
end

return M
```

### 6. PGP/GPG Encryption ❌ NOT IMPLEMENTED (Phase 10)

**Priority**: Low  
**Estimated Effort**: 1 week

#### 6.1 Encryption Module

Create `core/encryption.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')

-- Check GPG availability
function M.check_gpg()
  return vim.fn.executable('gpg') == 1
end

-- Get GPG keys
function M.get_keys(key_type)
  if not M.check_gpg() then
    return {}
  end
  
  local cmd = key_type == "secret" and "gpg --list-secret-keys" or "gpg --list-public-keys"
  local output = vim.fn.system(cmd)
  
  local keys = {}
  local current_key = nil
  
  for line in output:gmatch("[^\n]+") do
    local key_id = line:match("^%s+([A-F0-9]+)$")
    if key_id and #key_id >= 16 then
      current_key = {
        id = key_id,
        emails = {}
      }
      table.insert(keys, current_key)
    elseif current_key then
      local email = line:match("<([^>]+)>")
      if email then
        table.insert(current_key.emails, email)
      end
    end
  end
  
  return keys
end

-- Encrypt email
function M.encrypt_email(email_data, recipient_keys)
  if not M.check_gpg() then
    return nil, "GPG not available"
  end
  
  -- Create temporary file for encryption
  local temp_file = vim.fn.tempname()
  vim.fn.writefile(vim.split(email_data.body, '\n'), temp_file)
  
  -- Build GPG command
  local cmd = {"gpg", "--armor", "--encrypt"}
  
  -- Add recipients
  for _, key in ipairs(recipient_keys) do
    table.insert(cmd, "--recipient")
    table.insert(cmd, key)
  end
  
  table.insert(cmd, temp_file)
  
  -- Execute encryption
  local result = vim.fn.system(cmd)
  local encrypted_file = temp_file .. ".asc"
  
  if vim.fn.filereadable(encrypted_file) == 1 then
    local encrypted_body = table.concat(vim.fn.readfile(encrypted_file), '\n')
    
    -- Clean up
    vim.fn.delete(temp_file)
    vim.fn.delete(encrypted_file)
    
    -- Update email data
    email_data.body = encrypted_body
    email_data.headers = email_data.headers or {}
    email_data.headers["Content-Type"] = "multipart/encrypted; protocol=\"application/pgp-encrypted\""
    
    return email_data
  else
    vim.fn.delete(temp_file)
    return nil, "Encryption failed"
  end
end

-- Sign email
function M.sign_email(email_data, signing_key)
  if not M.check_gpg() then
    return nil, "GPG not available"
  end
  
  -- Create temporary file
  local temp_file = vim.fn.tempname()
  vim.fn.writefile(vim.split(email_data.body, '\n'), temp_file)
  
  -- Sign
  local cmd = string.format(
    "gpg --armor --detach-sign --default-key %s %s",
    signing_key, temp_file
  )
  
  vim.fn.system(cmd)
  local sig_file = temp_file .. ".asc"
  
  if vim.fn.filereadable(sig_file) == 1 then
    local signature = table.concat(vim.fn.readfile(sig_file), '\n')
    
    -- Clean up
    vim.fn.delete(temp_file)
    vim.fn.delete(sig_file)
    
    -- Create multipart/signed message
    email_data.signature = signature
    email_data.headers = email_data.headers or {}
    email_data.headers["Content-Type"] = "multipart/signed; protocol=\"application/pgp-signature\""
    
    return email_data
  else
    vim.fn.delete(temp_file)
    return nil, "Signing failed"
  end
end

-- Decrypt email
function M.decrypt_email(encrypted_body)
  if not M.check_gpg() then
    return nil, "GPG not available"
  end
  
  -- Create temporary file
  local temp_file = vim.fn.tempname()
  vim.fn.writefile(vim.split(encrypted_body, '\n'), temp_file)
  
  -- Decrypt
  local cmd = string.format("gpg --decrypt %s", temp_file)
  local decrypted = vim.fn.system(cmd)
  
  vim.fn.delete(temp_file)
  
  if vim.v.shell_error == 0 then
    return decrypted
  else
    return nil, "Decryption failed"
  end
end

-- Verify signature
function M.verify_signature(email_body, signature)
  if not M.check_gpg() then
    return false, "GPG not available"
  end
  
  -- Create temporary files
  local body_file = vim.fn.tempname()
  local sig_file = vim.fn.tempname()
  
  vim.fn.writefile(vim.split(email_body, '\n'), body_file)
  vim.fn.writefile(vim.split(signature, '\n'), sig_file)
  
  -- Verify
  local cmd = string.format("gpg --verify %s %s", sig_file, body_file)
  local output = vim.fn.system(cmd)
  
  vim.fn.delete(body_file)
  vim.fn.delete(sig_file)
  
  if vim.v.shell_error == 0 then
    -- Parse signer info
    local signer = output:match("Good signature from \"([^\"]+)\"")
    return true, signer
  else
    return false, "Invalid signature"
  end
end

-- Encryption UI
function M.show_encryption_ui(callback)
  local public_keys = M.get_keys("public")
  local secret_keys = M.get_keys("secret")
  
  if #public_keys == 0 and #secret_keys == 0 then
    notify.himalaya(
      "No GPG keys found. Import or generate keys first.",
      notify.categories.WARNING
    )
    return
  end
  
  -- Create selection buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "Email Encryption Options",
    "",
    "Select recipients to encrypt for:",
  }
  
  local key_map = {}
  local line_num = 4
  
  for _, key in ipairs(public_keys) do
    for _, email in ipairs(key.emails) do
      table.insert(lines, string.format("[ ] %s (%s)", email, key.id:sub(-8)))
      key_map[line_num] = key.id
      line_num = line_num + 1
    end
  end
  
  table.insert(lines, "")
  table.insert(lines, "Sign with:")
  line_num = line_num + 2
  
  local sign_line = line_num
  for _, key in ipairs(secret_keys) do
    for _, email in ipairs(key.emails) do
      table.insert(lines, string.format("( ) %s (%s)", email, key.id:sub(-8)))
      key_map[line_num] = {signing = true, id = key.id}
      line_num = line_num + 1
    end
  end
  
  table.insert(lines, "")
  table.insert(lines, "Press SPACE to toggle, ENTER to confirm, ESC to cancel")
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open window
  local width = 60
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Track selections
  local selections = {
    recipients = {},
    signing_key = nil
  }
  
  -- Toggle selection
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Space>', '', {
    callback = function()
      local line = vim.api.nvim_win_get_cursor(win)[1]
      local key_info = key_map[line]
      
      if key_info then
        if type(key_info) == "string" then
          -- Recipient key
          local line_text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
          if line_text:match("^%[X%]") then
            -- Uncheck
            line_text = line_text:gsub("^%[X%]", "[ ]")
            selections.recipients[key_info] = nil
          else
            -- Check
            line_text = line_text:gsub("^%[ %]", "[X]")
            selections.recipients[key_info] = true
          end
          vim.api.nvim_buf_set_lines(buf, line - 1, line, false, {line_text})
          
        elseif key_info.signing then
          -- Signing key - radio button behavior
          for i = sign_line, line_num - 1 do
            local text = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
            if text and text:match("^%(") then
              text = text:gsub("^%(X%)", "( )")
              vim.api.nvim_buf_set_lines(buf, i - 1, i, false, {text})
            end
          end
          
          -- Select this one
          local line_text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
          line_text = line_text:gsub("^%( %)", "(X)")
          vim.api.nvim_buf_set_lines(buf, line - 1, line, false, {line_text})
          selections.signing_key = key_info.id
        end
      end
    end
  })
  
  -- Confirm selection
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
      
      local recipients = {}
      for key_id, _ in pairs(selections.recipients) do
        table.insert(recipients, key_id)
      end
      
      callback({
        encrypt = #recipients > 0,
        recipients = recipients,
        sign = selections.signing_key ~= nil,
        signing_key = selections.signing_key
      })
    end
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
      callback(nil)
    end
  })
end

return M
```

### 7. Email Rules and Filters ❌ NOT IMPLEMENTED

**Priority**: Medium  
**Estimated Effort**: 4-5 days

#### 7.1 Rules Engine

Create `core/rules.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Rule structure
local rule_schema = {
  id = "",
  name = "",
  description = "",
  enabled = true,
  conditions = {}, -- Array of conditions
  actions = {}, -- Array of actions
  priority = 0, -- Higher priority rules run first
  created_at = 0,
  updated_at = 0,
  matched_count = 0
}

-- Condition types
M.condition_types = {
  from = { field = "from", operators = {"contains", "equals", "matches"} },
  to = { field = "to", operators = {"contains", "equals", "matches"} },
  subject = { field = "subject", operators = {"contains", "equals", "matches"} },
  body = { field = "body", operators = {"contains", "matches"} },
  size = { field = "size", operators = {"greater", "less"} },
  has_attachment = { field = "has_attachment", operators = {"is"} },
  folder = { field = "folder", operators = {"equals"} },
  date = { field = "date", operators = {"before", "after"} }
}

-- Action types
M.action_types = {
  move_to_folder = { params = {"folder"} },
  mark_as_read = { params = {} },
  mark_as_unread = { params = {} },
  star = { params = {} },
  unstar = { params = {} },
  add_label = { params = {"label"} },
  delete = { params = {} },
  forward_to = { params = {"email"} },
  auto_reply = { params = {"template_id"} },
  notify = { params = {"message"} }
}

-- Get all rules
function M.get_rules()
  return state.get('email_rules') or {}
end

-- Create rule
function M.create_rule(rule_data)
  local rules = M.get_rules()
  local id = vim.fn.tempname():match("([^/]+)$")
  
  local rule = vim.tbl_extend('force', {
    id = id,
    created_at = os.time(),
    updated_at = os.time(),
    matched_count = 0,
    priority = 0,
    enabled = true
  }, rule_data)
  
  rules[id] = rule
  state.set('email_rules', rules)
  
  notify.himalaya(
    "Rule created: " .. rule.name,
    notify.categories.USER_ACTION
  )
  
  return rule
end

-- Apply rules to email
function M.apply_rules(email, account)
  local rules = M.get_rules()
  local applied_rules = {}
  
  -- Sort by priority
  local sorted_rules = {}
  for id, rule in pairs(rules) do
    if rule.enabled then
      table.insert(sorted_rules, rule)
    end
  end
  
  table.sort(sorted_rules, function(a, b)
    return a.priority > b.priority
  end)
  
  -- Apply each rule
  for _, rule in ipairs(sorted_rules) do
    if M.match_conditions(email, rule.conditions) then
      M.execute_actions(email, account, rule.actions)
      
      -- Update match count
      rule.matched_count = rule.matched_count + 1
      rules[rule.id] = rule
      
      table.insert(applied_rules, rule)
      
      -- Stop if rule has stop_processing flag
      if rule.stop_processing then
        break
      end
    end
  end
  
  if #applied_rules > 0 then
    state.set('email_rules', rules)
  end
  
  return applied_rules
end

-- Match conditions
function M.match_conditions(email, conditions)
  if #conditions == 0 then
    return false
  end
  
  -- Default to AND logic
  for _, condition in ipairs(conditions) do
    if not M.match_condition(email, condition) then
      return false
    end
  end
  
  return true
end

-- Match single condition
function M.match_condition(email, condition)
  local field_value = email[condition.field]
  local test_value = condition.value
  
  if condition.operator == "contains" then
    if type(field_value) == "table" then
      for _, val in ipairs(field_value) do
        if val:lower():find(test_value:lower(), 1, true) then
          return true
        end
      end
      return false
    else
      return field_value and field_value:lower():find(test_value:lower(), 1, true)
    end
    
  elseif condition.operator == "equals" then
    if type(field_value) == "table" then
      return vim.tbl_contains(field_value, test_value)
    else
      return field_value == test_value
    end
    
  elseif condition.operator == "matches" then
    -- Regex match
    if type(field_value) == "table" then
      for _, val in ipairs(field_value) do
        if val:match(test_value) then
          return true
        end
      end
      return false
    else
      return field_value and field_value:match(test_value)
    end
    
  elseif condition.operator == "greater" then
    return tonumber(field_value) and tonumber(field_value) > tonumber(test_value)
    
  elseif condition.operator == "less" then
    return tonumber(field_value) and tonumber(field_value) < tonumber(test_value)
    
  elseif condition.operator == "is" then
    return field_value == (test_value == "true")
    
  elseif condition.operator == "before" then
    local test_date = require('neotex.plugins.tools.himalaya.core.search').parse_date(test_value)
    return field_value and field_value < test_date
    
  elseif condition.operator == "after" then
    local test_date = require('neotex.plugins.tools.himalaya.core.search').parse_date(test_value)
    return field_value and field_value > test_date
  end
  
  return false
end

-- Execute actions
function M.execute_actions(email, account, actions)
  local email_service = require('neotex.plugins.tools.himalaya.service.email')
  
  for _, action in ipairs(actions) do
    if action.type == "move_to_folder" then
      email_service.move_email(account, email.id, action.folder)
      
    elseif action.type == "mark_as_read" then
      email_service.mark_as_read(account, email.id)
      
    elseif action.type == "mark_as_unread" then
      email_service.mark_as_unread(account, email.id)
      
    elseif action.type == "star" then
      email_service.star_email(account, email.id)
      
    elseif action.type == "unstar" then
      email_service.unstar_email(account, email.id)
      
    elseif action.type == "add_label" then
      email_service.add_label(account, email.id, action.label)
      
    elseif action.type == "delete" then
      require('neotex.plugins.tools.himalaya.core.trash')
        .move_to_trash(email.id, email.folder)
      
    elseif action.type == "forward_to" then
      -- Create forward email
      local forward_data = {
        to = {action.email},
        subject = "Fwd: " .. (email.subject or ""),
        body = "--- Forwarded message ---\n" .. (email.body or "")
      }
      email_service.send(account, forward_data)
      
    elseif action.type == "auto_reply" then
      -- Use template for auto-reply
      local templates = require('neotex.plugins.tools.himalaya.core.templates')
      local template_result = templates.apply_template(action.template_id, {
        sender_name = email.from,
        subject = email.subject
      })
      
      if template_result then
        local reply_data = {
          to = {email.from},
          subject = "Re: " .. (email.subject or ""),
          body = template_result.body
        }
        email_service.send(account, reply_data)
      end
      
    elseif action.type == "notify" then
      notify.himalaya(
        action.message:gsub("{subject}", email.subject or ""),
        notify.categories.USER_ACTION,
        { rule_match = true }
      )
    end
  end
end

-- Rule builder UI
function M.show_rule_builder()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Email Rule Builder")
  
  local lines = {
    "# Email Rule Builder",
    "",
    "Name: New Rule",
    "Description: ",
    "Priority: 0",
    "Enabled: true",
    "",
    "## Conditions (all must match)",
    "# Example: from:contains:newsletter@example.com",
    "# Format: field:operator:value",
    "",
    "## Actions",
    "# Example: move_to_folder:Newsletters",
    "# Example: mark_as_read",
    "# Format: action_type:param1:param2",
    "",
    "## Available Conditions",
    "# from, to, subject, body, size, has_attachment, folder, date",
    "# Operators: contains, equals, matches, greater, less, is, before, after",
    "",
    "## Available Actions", 
    "# move_to_folder, mark_as_read, mark_as_unread, star, unstar",
    "# add_label, delete, forward_to, auto_reply, notify"
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  
  -- Open in split
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Save rule on write
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      M.save_rule_from_buffer(buf)
    end
  })
end

-- Save rule from buffer
function M.save_rule_from_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  local rule = {
    name = "",
    description = "",
    priority = 0,
    enabled = true,
    conditions = {},
    actions = {}
  }
  
  local section = nil
  
  for _, line in ipairs(lines) do
    if line:match("^Name: ") then
      rule.name = line:match("^Name: (.+)$")
    elseif line:match("^Description: ") then
      rule.description = line:match("^Description: (.*)$")
    elseif line:match("^Priority: ") then
      rule.priority = tonumber(line:match("^Priority: (%d+)$")) or 0
    elseif line:match("^Enabled: ") then
      rule.enabled = line:match("^Enabled: (.+)$") == "true"
    elseif line:match("^## Conditions") then
      section = "conditions"
    elseif line:match("^## Actions") then
      section = "actions"
    elseif line:match("^## ") then
      section = nil
    elseif section == "conditions" and not line:match("^#") and line ~= "" then
      local field, op, value = line:match("^(%w+):(%w+):(.+)$")
      if field and op and value then
        table.insert(rule.conditions, {
          field = field,
          operator = op,
          value = value
        })
      end
    elseif section == "actions" and not line:match("^#") and line ~= "" then
      local parts = vim.split(line, ":")
      if #parts >= 1 then
        local action = {
          type = parts[1]
        }
        
        -- Add parameters based on action type
        if M.action_types[action.type] then
          local params = M.action_types[action.type].params
          for i, param in ipairs(params) do
            if parts[i + 1] then
              action[param] = parts[i + 1]
            end
          end
        end
        
        table.insert(rule.actions, action)
      end
    end
  end
  
  -- Validate and save
  if rule.name ~= "" and #rule.conditions > 0 and #rule.actions > 0 then
    M.create_rule(rule)
    vim.api.nvim_buf_set_option(buf, 'modified', false)
  else
    notify.himalaya(
      "Rule must have name, at least one condition, and one action",
      notify.categories.ERROR
    )
  end
end

return M
```

### 8. Integration Features ❌ NOT IMPLEMENTED

**Priority**: Low  
**Estimated Effort**: 2-3 weeks (various integrations)

#### 8.1 Calendar Integration

Create `integrations/calendar.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')

-- Parse calendar invite from email
function M.parse_calendar_invite(email)
  -- Look for ics attachment or inline calendar data
  local ics_content = nil
  
  if email.attachments then
    for _, att in ipairs(email.attachments) do
      if att.content_type == "text/calendar" or att.filename:match("%.ics$") then
        -- Download and parse ics file
        local attachments = require('neotex.plugins.tools.himalaya.core.attachments')
        local path = attachments.download_attachment(email.id, att.id)
        if path then
          ics_content = table.concat(vim.fn.readfile(path), '\n')
        end
        break
      end
    end
  end
  
  if not ics_content then
    -- Check for inline calendar data
    if email.body and email.body:match("BEGIN:VCALENDAR") then
      ics_content = email.body
    end
  end
  
  if ics_content then
    return M.parse_ics(ics_content)
  end
  
  return nil
end

-- Parse ICS content
function M.parse_ics(content)
  local event = {
    summary = "",
    description = "",
    location = "",
    start_time = nil,
    end_time = nil,
    organizer = "",
    attendees = {},
    uid = ""
  }
  
  -- Basic ICS parsing
  for line in content:gmatch("[^\r\n]+") do
    local key, value = line:match("^([^:]+):(.+)$")
    if key then
      if key == "SUMMARY" then
        event.summary = value
      elseif key == "DESCRIPTION" then
        event.description = value:gsub("\\n", "\n")
      elseif key == "LOCATION" then
        event.location = value
      elseif key == "DTSTART" then
        event.start_time = M.parse_ical_date(value)
      elseif key == "DTEND" then
        event.end_time = M.parse_ical_date(value)
      elseif key == "ORGANIZER" then
        event.organizer = value:match("mailto:([^;]+)") or value
      elseif key == "ATTENDEE" then
        local email = value:match("mailto:([^;]+)")
        if email then
          table.insert(event.attendees, email)
        end
      elseif key == "UID" then
        event.uid = value
      end
    end
  end
  
  return event
end

-- Show calendar invite UI
function M.show_calendar_invite(event, email)
  local buf = vim.api.nvim_create_buf(false, true)
  
  local lines = {
    "Calendar Invitation",
    "",
    "Event: " .. event.summary,
    "When: " .. os.date("%Y-%m-%d %H:%M", event.start_time),
    "Duration: " .. M.format_duration(event.start_time, event.end_time),
    "Location: " .. (event.location ~= "" and event.location or "Not specified"),
    "Organizer: " .. event.organizer,
    "",
    "Description:",
  }
  
  -- Add description lines
  for line in event.description:gmatch("[^\n]+") do
    table.insert(lines, "  " .. line)
  end
  
  table.insert(lines, "")
  table.insert(lines, "Actions:")
  table.insert(lines, "  [A]ccept  [T]entative  [D]ecline  [C]ancel")
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open window
  local width = 60
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Set up response handlers
  local function respond(response)
    vim.api.nvim_win_close(win, true)
    M.send_calendar_response(event, email, response)
  end
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 'a', '', {
    callback = function() respond("ACCEPTED") end
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 't', '', {
    callback = function() respond("TENTATIVE") end
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 'd', '', {
    callback = function() respond("DECLINED") end
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 'c', ':close<CR>', { buffer = buf })
end

-- Send calendar response
function M.send_calendar_response(event, original_email, response)
  -- Create response email
  local response_subject = string.format(
    "%s: %s",
    response:sub(1, 1) .. response:sub(2):lower(),
    event.summary
  )
  
  local response_body = string.format(
    "Your invitation response (%s) has been sent to the organizer.",
    response
  )
  
  -- Create iCal response
  local ical_response = M.create_ical_response(event, response)
  
  -- Send email with calendar response
  local email_data = {
    to = {event.organizer},
    subject = response_subject,
    body = response_body,
    attachments = {
      {
        filename = "response.ics",
        content_type = "text/calendar",
        content = ical_response
      }
    }
  }
  
  local email_service = require('neotex.plugins.tools.himalaya.service.email')
  local account = require('neotex.plugins.tools.himalaya.core.accounts').get_default_account()
  
  email_service.send(account, email_data)
  
  notify.himalaya(
    string.format("Calendar response sent: %s", response),
    notify.categories.USER_ACTION
  )
end

return M
```

#### 8.2 Task Integration

Create `integrations/tasks.lua`:

```lua
local M = {}
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Task structure
local task_schema = {
  id = "",
  title = "",
  description = "",
  due_date = nil,
  priority = "normal", -- low, normal, high, urgent
  status = "todo", -- todo, in_progress, done
  email_ref = nil, -- Reference to source email
  created_at = 0,
  updated_at = 0
}

-- Convert email to task
function M.email_to_task(email)
  local task = {
    id = vim.fn.tempname():match("([^/]+)$"),
    title = email.subject or "Email Task",
    description = M.extract_task_description(email),
    due_date = M.extract_due_date(email),
    priority = M.detect_priority(email),
    status = "todo",
    email_ref = {
      id = email.id,
      from = email.from,
      date = email.date
    },
    created_at = os.time(),
    updated_at = os.time()
  }
  
  -- Save task
  local tasks = state.get('email_tasks') or {}
  tasks[task.id] = task
  state.set('email_tasks', tasks)
  
  notify.himalaya(
    "Task created from email",
    notify.categories.USER_ACTION,
    { title = task.title }
  )
  
  return task
end

-- Extract task description from email
function M.extract_task_description(email)
  local desc = string.format(
    "From: %s\nDate: %s\n\n%s",
    email.from or "Unknown",
    os.date("%Y-%m-%d %H:%M", email.date),
    email.body or email.preview or ""
  )
  
  -- Limit description length
  if #desc > 500 then
    desc = desc:sub(1, 497) .. "..."
  end
  
  return desc
end

-- Extract due date from email
function M.extract_due_date(email)
  local body = (email.body or ""):lower()
  local subject = (email.subject or ""):lower()
  local text = subject .. " " .. body
  
  -- Look for date patterns
  local patterns = {
    "due%s+(%d+/%d+/%d+)",
    "by%s+(%d+/%d+/%d+)",
    "deadline%s+(%d+/%d+/%d+)",
    "due%s+(%w+%s+%d+)",
    "by%s+(%w+%s+%d+)"
  }
  
  for _, pattern in ipairs(patterns) do
    local date_str = text:match(pattern)
    if date_str then
      -- Parse date (simplified)
      return os.time() + (7 * 24 * 60 * 60) -- Default to 1 week
    end
  end
  
  return nil
end

-- Detect priority from email
function M.detect_priority(email)
  local markers = {
    urgent = {"urgent", "asap", "immediately", "critical"},
    high = {"important", "high priority", "priority"},
    low = {"whenever", "no rush", "low priority"}
  }
  
  local text = (email.subject or ""):lower() .. " " .. (email.body or ""):lower()
  
  for priority, keywords in pairs(markers) do
    for _, keyword in ipairs(keywords) do
      if text:find(keyword, 1, true) then
        return priority
      end
    end
  end
  
  return "normal"
end

-- Show tasks UI
function M.show_tasks()
  local tasks = state.get('email_tasks') or {}
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Group tasks by status
  local by_status = {
    todo = {},
    in_progress = {},
    done = {}
  }
  
  for id, task in pairs(tasks) do
    table.insert(by_status[task.status], task)
  end
  
  -- Sort by priority and due date
  for status, task_list in pairs(by_status) do
    table.sort(task_list, function(a, b)
      if a.priority ~= b.priority then
        local priority_order = {urgent = 1, high = 2, normal = 3, low = 4}
        return priority_order[a.priority] < priority_order[b.priority]
      end
      return (a.due_date or math.huge) < (b.due_date or math.huge)
    end)
  end
  
  -- Render tasks
  local lines = {"Email Tasks", ""}
  
  for _, status in ipairs({"todo", "in_progress", "done"}) do
    if #by_status[status] > 0 then
      table.insert(lines, string.format("## %s (%d)", 
        status:gsub("_", " "):gsub("^%l", string.upper),
        #by_status[status]
      ))
      
      for _, task in ipairs(by_status[status]) do
        local priority_marker = ({
          urgent = "🔴",
          high = "🟡",
          normal = "🟢",
          low = "⚪"
        })[task.priority]
        
        local due = task.due_date and os.date(" (Due: %m/%d)", task.due_date) or ""
        
        table.insert(lines, string.format(
          "%s %s%s",
          priority_marker,
          task.title,
          due
        ))
      end
      
      table.insert(lines, "")
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open in split
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "Email Tasks")
end

return M
```

## Implementation Priorities

### Phase 1: Core Advanced Features (Week 1-2)
1. Undo send system (delayed queue)
2. Advanced search with operators
3. Email templates
4. Basic scheduling

### Phase 2: Productivity Features (Week 3-4)
1. Multiple account views
2. Email rules and filters
3. Task integration
4. Calendar integration basics

### Phase 3: Security & Integration (Week 5-6)
1. PGP/GPG encryption
2. Contact management
3. Note taking
4. External tool integration

## Testing Strategy

### Unit Tests
- Test search query parsing
- Test rule condition matching
- Test template variable replacement
- Test encryption/decryption

### Integration Tests
- Test delayed send queue processing
- Test scheduled email execution
- Test calendar invite parsing
- Test task creation from emails

### User Acceptance Tests
- Send and undo an email
- Create and apply email rules
- Schedule recurring emails
- Search with complex queries

## Success Metrics

1. **Undo Send**: 60-second delay with reliable cancellation
2. **Search Performance**: < 500ms for complex queries on 10k emails
3. **Template Usage**: < 3 seconds to apply template
4. **Schedule Accuracy**: Emails sent within 1 minute of scheduled time
5. **Encryption**: Support GPG encryption/signing
6. **Rules Engine**: Process 100 rules in < 100ms per email
7. **Integration**: Seamless calendar and task conversion

## Risk Mitigation

1. **Performance**: Index emails for fast searching
2. **Reliability**: Persistent queue for scheduled/delayed emails
3. **Security**: Validate all encryption operations
4. **Compatibility**: Graceful degradation for missing features
5. **Data Integrity**: Backup before applying rules