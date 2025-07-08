# Phase 9 Remaining Features Implementation Specification

**Status**: Phase 9 Complete (11/12 features implemented)  
**Created**: 2025-07-07  
**Updated**: 2025-01-08 - Multiple Account Views implemented, Phase 9 complete  
**Priority**: Complete

This specification documented the implementation plans for Phase 9 features. Phase 9 is now complete.

## Overview

Phase 9 has successfully implemented 11 out of 12 planned features:
- ✅ Undo Send System → Unified Email Scheduling
- ✅ Advanced Search
- ✅ Email Templates
- ✅ Notification System Integration
- ✅ Unified Email Scheduling
- ✅ Enhanced Scheduling UI
- ✅ Scheduled Email Persistence
- ✅ Multi-Instance Sync
- ✅ Async Command Architecture
- ✅ Multi-Instance Auto-Sync Coordination
- ✅ Multiple Account Views (2025-01-08)

Features not implemented (per user request):
1. ❌ **Email Rules and Filters** (Skipped)
2. ❌ **Integration Features** (Skipped)

> **Note**: Email Scheduling and Window Management Improvements have been moved to `PHASE_9_NEXT_IMPLEMENTATION.md` for immediate implementation.

---

## ✅ 1. Multiple Account Views (IMPLEMENTED - 2025-01-08)

### Overview
Enable users to view and manage multiple email accounts simultaneously through unified, split, and tabbed views.

### Implementation Plan

#### 1.1 Core Multi-Account Module
Create `ui/multi_account.lua`:

```lua
local M = {}

-- View modes
M.modes = {
  UNIFIED = "unified",
  SPLIT = "split",
  TABBED = "tabbed",
  FOCUSED = "focused"
}

-- Current state
M.state = {
  mode = M.modes.UNIFIED,
  active_accounts = {},
  window_layout = {},
  refresh_interval = 60, -- seconds
  sync_in_progress = false
}

-- Initialize multi-account view
function M.setup()
  local accounts = require('neotex.plugins.tools.himalaya.core.accounts')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  
  -- Get all configured accounts
  M.state.active_accounts = accounts.get_all_accounts()
  
  -- Set up auto-refresh
  M.setup_auto_refresh()
  
  -- Create initial view
  M.create_view(M.state.mode)
end

-- Create view based on mode
function M.create_view(mode)
  M.state.mode = mode
  
  if mode == M.modes.UNIFIED then
    M.create_unified_view()
  elseif mode == M.modes.SPLIT then
    M.create_split_view()
  elseif mode == M.modes.TABBED then
    M.create_tabbed_view()
  elseif mode == M.modes.FOCUSED then
    M.create_focused_view()
  end
end
```

#### 1.2 Unified Inbox Implementation
```lua
-- Unified inbox view
function M.create_unified_view()
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
  
  -- Collect emails from all accounts
  local all_emails = {}
  local account_colors = M.generate_account_colors()
  
  for account_name, account in pairs(M.state.active_accounts) do
    local emails = M.fetch_account_emails(account_name)
    
    -- Add account metadata to each email
    for _, email in ipairs(emails) do
      email._account = account_name
      email._account_color = account_colors[account_name]
      email._account_email = account.email
      table.insert(all_emails, email)
    end
  end
  
  -- Sort by date (newest first)
  table.sort(all_emails, function(a, b)
    return a.date > b.date
  end)
  
  -- Create unified view buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "himalaya://unified-inbox")
  
  -- Render with account indicators
  M.render_unified_list(buf, all_emails)
  
  -- Set up keymaps
  M.setup_unified_keymaps(buf)
  
  return buf
end

-- Render unified email list
function M.render_unified_list(buf, emails)
  local lines = {}
  local highlights = {}
  
  -- Header
  table.insert(lines, string.format("Unified Inbox - %d emails from %d accounts", 
    #emails, vim.tbl_count(M.state.active_accounts)))
  table.insert(lines, string.rep("─", 80))
  
  -- Email entries with account indicators
  for i, email in ipairs(emails) do
    local account_tag = string.format("[%s]", email._account:sub(1, 8))
    local flags = M.format_flags(email)
    local date = os.date("%m/%d %H:%M", email.date)
    local from = M.format_sender(email.from)
    local subject = email.subject or "(no subject)"
    
    local line = string.format("%s %s %s %s %-20s %s",
      account_tag,
      flags,
      date,
      email.id:sub(1, 8),
      from,
      subject
    )
    
    table.insert(lines, line)
    
    -- Store highlight info for account colors
    table.insert(highlights, {
      line = i + 2, -- Skip header lines
      col_start = 0,
      col_end = #account_tag,
      hl_group = M.get_account_highlight(email._account)
    })
  end
  
  -- Apply content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Apply highlights
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, -1, hl.hl_group, 
      hl.line, hl.col_start, hl.col_end)
  end
end
```

#### 1.3 Split View Implementation
```lua
-- Split view for multiple accounts
function M.create_split_view()
  local accounts = vim.tbl_keys(M.state.active_accounts)
  local count = #accounts
  
  if count < 2 then
    vim.notify("Need at least 2 accounts for split view", vim.log.levels.WARN)
    return
  end
  
  -- Calculate optimal layout
  local layout = M.calculate_split_layout(count)
  
  -- Save current window
  local original_win = vim.api.nvim_get_current_win()
  
  -- Create splits
  M.state.window_layout = {}
  
  for i, account_name in ipairs(accounts) do
    local win, buf
    
    if i == 1 then
      -- Use current window for first account
      win = original_win
      buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(win, buf)
    else
      -- Create new split
      local split_cmd = M.get_split_command(i, layout)
      vim.cmd(split_cmd)
      win = vim.api.nvim_get_current_win()
      buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(win, buf)
    end
    
    -- Store window info
    M.state.window_layout[account_name] = {
      win = win,
      buf = buf
    }
    
    -- Render account view
    M.render_account_view(buf, account_name)
  end
  
  -- Return to first window
  vim.api.nvim_set_current_win(original_win)
end

-- Calculate optimal split layout
function M.calculate_split_layout(count)
  if count == 2 then
    return {rows = 1, cols = 2}
  elseif count == 3 then
    return {rows = 1, cols = 3}
  elseif count == 4 then
    return {rows = 2, cols = 2}
  else
    local cols = math.ceil(math.sqrt(count))
    local rows = math.ceil(count / cols)
    return {rows = rows, cols = cols}
  end
end
```

#### 1.4 Tabbed View Implementation
```lua
-- Tabbed view for multiple accounts
function M.create_tabbed_view()
  local accounts = vim.tbl_keys(M.state.active_accounts)
  
  -- Save current tab
  local original_tab = vim.api.nvim_get_current_tabpage()
  
  -- Create tabs for each account
  for i, account_name in ipairs(accounts) do
    if i > 1 then
      vim.cmd('tabnew')
    end
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    
    -- Set tab label
    vim.cmd(string.format('TabLabel %s', account_name))
    
    -- Render account view
    M.render_account_view(buf, account_name)
    
    -- Store in layout
    M.state.window_layout[account_name] = {
      tab = vim.api.nvim_get_current_tabpage(),
      buf = buf
    }
  end
  
  -- Return to original tab
  vim.api.nvim_set_current_tabpage(original_tab)
end
```

#### 1.5 Commands
```lua
-- In core/commands/email.lua, add:
commands.HimalayaViewUnified = {
  fn = function()
    require('neotex.plugins.tools.himalaya.ui.multi_account').create_view('unified')
  end,
  opts = { desc = 'Show unified inbox view' }
}

commands.HimalayaViewSplit = {
  fn = function()
    require('neotex.plugins.tools.himalaya.ui.multi_account').create_view('split')
  end,
  opts = { desc = 'Show split account view' }
}

commands.HimalayaViewTabbed = {
  fn = function()
    require('neotex.plugins.tools.himalaya.ui.multi_account').create_view('tabbed')
  end,
  opts = { desc = 'Show tabbed account view' }
}

commands.HimalayaCycleView = {
  fn = function()
    require('neotex.plugins.tools.himalaya.ui.multi_account').cycle_view_mode()
  end,
  opts = { desc = 'Cycle through view modes' }
}
```

---

## 2. Email Rules and Filters (Medium Priority)

### Overview
Implement automatic email filtering and rule-based actions for incoming emails.

### Implementation Plan

#### 4.1 Rules Engine
Create `core/rules.lua`:

```lua
local M = {}

-- Rule structure
local rule_schema = {
  id = "",
  name = "",
  description = "",
  enabled = true,
  priority = 50, -- 0-100, higher runs first
  conditions = {}, -- Array of conditions
  actions = {}, -- Array of actions
  created_at = 0,
  last_matched = 0,
  match_count = 0
}

-- Condition types
M.condition_types = {
  FROM = "from",
  TO = "to",
  SUBJECT = "subject",
  BODY = "body",
  HAS_ATTACHMENT = "has_attachment",
  SIZE = "size",
  DATE = "date",
  HEADER = "header",
  IS_SPAM = "is_spam"
}

-- Action types
M.action_types = {
  MOVE_TO_FOLDER = "move_to_folder",
  MARK_AS_READ = "mark_as_read",
  MARK_AS_IMPORTANT = "mark_as_important",
  DELETE = "delete",
  FORWARD_TO = "forward_to",
  TAG = "tag",
  NOTIFY = "notify",
  RUN_SCRIPT = "run_script"
}

-- Create a new rule
function M.create_rule(rule_data)
  local rules = state.get('email_rules', {})
  
  local rule = vim.tbl_extend('force', {
    id = M.generate_id(),
    created_at = os.time(),
    enabled = true,
    priority = 50,
    match_count = 0
  }, rule_data)
  
  rules[rule.id] = rule
  state.set('email_rules', rules)
  
  return rule
end

-- Process email through rules
function M.process_email(email, account)
  local rules = M.get_active_rules()
  local matched_rules = {}
  
  -- Sort by priority
  table.sort(rules, function(a, b)
    return a.priority > b.priority
  end)
  
  -- Check each rule
  for _, rule in ipairs(rules) do
    if M.matches_rule(email, rule) then
      table.insert(matched_rules, rule)
      
      -- Execute actions
      local continue = M.execute_actions(email, account, rule)
      
      -- Update match count
      rule.match_count = rule.match_count + 1
      rule.last_matched = os.time()
      
      -- Stop processing if action says to
      if not continue then
        break
      end
    end
  end
  
  return matched_rules
end

-- Check if email matches rule conditions
function M.matches_rule(email, rule)
  if not rule.enabled then
    return false
  end
  
  -- All conditions must match (AND logic)
  for _, condition in ipairs(rule.conditions) do
    if not M.check_condition(email, condition) then
      return false
    end
  end
  
  return true
end

-- Check individual condition
function M.check_condition(email, condition)
  local value = M.get_email_value(email, condition.field)
  
  if condition.operator == "contains" then
    return value and value:lower():find(condition.value:lower(), 1, true)
  elseif condition.operator == "equals" then
    return value and value:lower() == condition.value:lower()
  elseif condition.operator == "matches" then
    -- Regex match
    return value and value:match(condition.value)
  elseif condition.operator == "greater_than" then
    return tonumber(value) and tonumber(value) > tonumber(condition.value)
  elseif condition.operator == "less_than" then
    return tonumber(value) and tonumber(value) < tonumber(condition.value)
  end
  
  return false
end
```

#### 4.2 Rule Builder UI
```lua
-- Rule builder interface
function M.show_rule_builder()
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  
  -- Create rule builder buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "Email Rule Builder",
    string.rep("─", 60),
    "",
    "Rule Name: [Enter rule name]",
    "Description: [Enter description]",
    "",
    "Conditions (all must match):",
    "  + Add condition",
    "",
    "Actions:",
    "  + Add action",
    "",
    "Priority: 50 (0-100)",
    "Enabled: Yes",
    "",
    "[Save Rule] [Test Rule] [Cancel]"
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Create window
  local win = float.create_window(buf, {
    title = "Create Email Rule",
    width = 60,
    height = 20,
    border = "rounded"
  })
  
  -- Set up interactions
  M.setup_rule_builder_keymaps(buf, win)
end

-- Add condition dialog
function M.add_condition_dialog(callback)
  local condition_types = vim.tbl_keys(M.condition_types)
  
  vim.ui.select(condition_types, {
    prompt = "Select condition type:"
  }, function(condition_type)
    if not condition_type then return end
    
    -- Get operator based on type
    local operators = M.get_operators_for_type(condition_type)
    
    vim.ui.select(operators, {
      prompt = "Select operator:"
    }, function(operator)
      if not operator then return end
      
      -- Get value
      vim.ui.input({
        prompt = "Enter value: "
      }, function(value)
        if not value then return end
        
        callback({
          field = condition_type,
          operator = operator,
          value = value
        })
      end)
    end)
  end)
end
```

#### 4.3 Rule Actions
```lua
-- Execute rule actions
function M.execute_actions(email, account, rule)
  local continue_processing = true
  
  for _, action in ipairs(rule.actions) do
    local success, stop = M.execute_action(email, account, action)
    
    if not success then
      logger.error("Rule action failed", {
        rule = rule.name,
        action = action.type,
        email = email.id
      })
    end
    
    if stop then
      continue_processing = false
    end
  end
  
  return continue_processing
end

-- Execute individual action
function M.execute_action(email, account, action)
  if action.type == M.action_types.MOVE_TO_FOLDER then
    local email_service = require('neotex.plugins.tools.himalaya.service.email')
    return email_service.move(email.id, action.folder, account)
    
  elseif action.type == M.action_types.MARK_AS_READ then
    local email_service = require('neotex.plugins.tools.himalaya.service.email')
    return email_service.mark_read(email.id, account)
    
  elseif action.type == M.action_types.DELETE then
    local trash = require('neotex.plugins.tools.himalaya.features.trash')
    trash.move_to_trash(email.id, account)
    return true, true -- Stop processing
    
  elseif action.type == M.action_types.TAG then
    -- Add tag to email
    email.tags = email.tags or {}
    table.insert(email.tags, action.tag)
    return true
    
  elseif action.type == M.action_types.NOTIFY then
    notify.himalaya(
      string.format("Rule '%s' matched: %s", 
        action.rule_name or "Unknown",
        email.subject or "No subject"
      ),
      notify.categories.USER_ACTION
    )
    return true
    
  elseif action.type == M.action_types.RUN_SCRIPT then
    -- Execute user script
    local ok = pcall(loadstring(action.script), email, account)
    return ok
  end
  
  return false
end
```

#### 4.4 Rule Management Commands
```lua
-- In core/commands/email.lua, add:
commands.HimalayaRuleNew = {
  fn = function()
    require('neotex.plugins.tools.himalaya.core.rules').show_rule_builder()
  end,
  opts = { desc = 'Create new email rule' }
}

commands.HimalayaRuleList = {
  fn = function()
    require('neotex.plugins.tools.himalaya.core.rules').show_rules_list()
  end,
  opts = { desc = 'List all email rules' }
}

commands.HimalayaRuleTest = {
  fn = function(opts)
    local rules = require('neotex.plugins.tools.himalaya.core.rules')
    rules.test_rule(opts.args)
  end,
  opts = { 
    nargs = 1,
    desc = 'Test rule on current folder' 
  }
}

commands.HimalayaRuleToggle = {
  fn = function(opts)
    local rules = require('neotex.plugins.tools.himalaya.core.rules')
    rules.toggle_rule(opts.args)
  end,
  opts = { 
    nargs = 1,
    desc = 'Enable/disable rule' 
  }
}
```

---

## 3. Integration Features (Medium Priority)

### Overview
Enable integration with external tools and services for enhanced workflow automation.

### Implementation Plan

#### 5.1 Integration Framework
Create `integrations/init.lua`:

```lua
local M = {}

-- Registered integrations
M.integrations = {}

-- Integration interface
M.integration_interface = {
  name = "",
  description = "",
  setup = function() end,
  teardown = function() end,
  commands = {},
  hooks = {},
  config = {}
}

-- Register an integration
function M.register(integration)
  if not integration.name then
    error("Integration must have a name")
  end
  
  -- Validate interface
  integration = vim.tbl_extend('keep', integration, M.integration_interface)
  
  M.integrations[integration.name] = integration
  
  -- Run setup if enabled
  if M.is_enabled(integration.name) then
    integration.setup()
  end
  
  return true
end

-- Enable/disable integration
function M.toggle(name)
  local integration = M.integrations[name]
  if not integration then
    error("Integration not found: " .. name)
  end
  
  local enabled = state.get('integrations.enabled', {})
  enabled[name] = not enabled[name]
  state.set('integrations.enabled', enabled)
  
  if enabled[name] then
    integration.setup()
  else
    integration.teardown()
  end
  
  return enabled[name]
end
```

#### 5.2 Task Management Integration
Create `integrations/tasks.lua`:

```lua
local M = {
  name = "task_management",
  description = "Convert emails to tasks in various task management systems",
  config = {
    default_system = "todoist", -- todoist, trello, asana, notion
    api_keys = {}
  }
}

-- Convert email to task
function M.email_to_task(email, system)
  system = system or M.config.default_system
  
  local task = {
    title = email.subject or "Email Task",
    description = M.format_task_description(email),
    due_date = M.extract_due_date(email),
    labels = M.extract_labels(email),
    attachments = email.attachments
  }
  
  -- Call appropriate integration
  if system == "todoist" then
    return M.create_todoist_task(task)
  elseif system == "trello" then
    return M.create_trello_card(task)
  elseif system == "notion" then
    return M.create_notion_page(task)
  end
end

-- Todoist integration
function M.create_todoist_task(task)
  local api_key = M.config.api_keys.todoist
  if not api_key then
    error("Todoist API key not configured")
  end
  
  local curl = require('plenary.curl')
  local response = curl.post('https://api.todoist.com/rest/v2/tasks', {
    headers = {
      ['Authorization'] = 'Bearer ' .. api_key,
      ['Content-Type'] = 'application/json'
    },
    body = vim.fn.json_encode({
      content = task.title,
      description = task.description,
      due_string = task.due_date,
      labels = task.labels
    })
  })
  
  if response.status == 200 then
    notify.himalaya("Task created in Todoist", notify.categories.USER_ACTION)
    return vim.fn.json_decode(response.body)
  else
    error("Failed to create Todoist task: " .. response.body)
  end
end

-- Register commands
M.commands = {
  HimalayaTaskCreate = {
    fn = function(opts)
      local email = require('neotex.plugins.tools.himalaya.ui').get_current_email()
      if email then
        M.email_to_task(email, opts.args)
      end
    end,
    opts = {
      nargs = '?',
      complete = function()
        return {'todoist', 'trello', 'notion'}
      end,
      desc = 'Convert email to task'
    }
  }
}

return M
```

#### 5.3 Calendar Integration
Create `integrations/calendar.lua`:

```lua
local M = {
  name = "calendar",
  description = "Create calendar events from emails",
  config = {
    default_calendar = "google", -- google, outlook, apple
    time_zone = "UTC"
  }
}

-- Extract event details from email
function M.extract_event_details(email)
  local event = {
    title = email.subject,
    description = email.body_text,
    attendees = M.extract_attendees(email),
    location = M.extract_location(email),
    start_time = M.extract_time(email),
    end_time = nil
  }
  
  -- Try to parse meeting details
  local meeting_patterns = {
    -- Zoom
    "https://.-%.zoom%.us/j/(%d+)",
    -- Google Meet
    "https://meet%.google%.com/(%S+)",
    -- Teams
    "https://teams%.microsoft%.com/l/meetup%-join/(%S+)"
  }
  
  for _, pattern in ipairs(meeting_patterns) do
    local match = email.body_text:match(pattern)
    if match then
      event.location = match
      event.is_virtual = true
      break
    end
  end
  
  return event
end

-- Create calendar event
function M.create_event(event, calendar)
  calendar = calendar or M.config.default_calendar
  
  if calendar == "google" then
    return M.create_google_event(event)
  elseif calendar == "outlook" then
    return M.create_outlook_event(event)
  end
end

-- Show event creation dialog
function M.show_event_dialog(email)
  local event = M.extract_event_details(email)
  
  -- Create dialog buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "Create Calendar Event",
    string.rep("─", 50),
    "",
    "Title: " .. event.title,
    "Date: " .. (event.start_time or "[Select date]"),
    "Time: [Select time]",
    "Duration: 1 hour",
    "Location: " .. (event.location or "[Add location]"),
    "",
    "Attendees:",
  }
  
  for _, attendee in ipairs(event.attendees) do
    table.insert(lines, "  • " .. attendee)
  end
  
  table.insert(lines, "")
  table.insert(lines, "[Create Event] [Cancel]")
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Show in float
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  local win = float.create_window(buf, {
    title = "Calendar Event",
    width = 50,
    height = #lines + 2
  })
  
  -- Set up keymaps
  M.setup_event_dialog_keymaps(buf, win, event)
end

return M
```

#### 5.4 Note-taking Integration
Create `integrations/notes.lua`:

```lua
local M = {
  name = "notes",
  description = "Save emails as notes in various systems",
  config = {
    default_system = "obsidian", -- obsidian, notion, roam
    vault_path = "~/Documents/Obsidian",
    template = [[
---
title: {{subject}}
date: {{date}}
from: {{from}}
tags: [email, himalaya]
---

# {{subject}}

**From:** {{from}}  
**Date:** {{date}}  
**To:** {{to}}

## Content

{{body}}

## Attachments
{{#each attachments}}
- [[{{filename}}]]
{{/each}}
    ]]
  }
}

-- Convert email to note
function M.email_to_note(email)
  local template = M.config.template
  
  -- Prepare variables
  local vars = {
    subject = email.subject or "Untitled",
    date = os.date("%Y-%m-%d %H:%M", email.date),
    from = email.from,
    to = email.to,
    body = email.body_text,
    attachments = email.attachments or {}
  }
  
  -- Apply template
  local content = M.apply_template(template, vars)
  
  -- Generate filename
  local filename = M.generate_filename(email)
  
  return {
    filename = filename,
    content = content,
    metadata = vars
  }
end

-- Save to Obsidian
function M.save_to_obsidian(note)
  local vault_path = vim.fn.expand(M.config.vault_path)
  local inbox_path = vault_path .. "/Inbox"
  
  -- Ensure directory exists
  vim.fn.mkdir(inbox_path, "p")
  
  -- Save note
  local filepath = inbox_path .. "/" .. note.filename
  local file = io.open(filepath, "w")
  file:write(note.content)
  file:close()
  
  notify.himalaya(
    string.format("Note saved to Obsidian: %s", note.filename),
    notify.categories.USER_ACTION
  )
  
  -- Open in Obsidian if available
  if vim.fn.executable("obsidian") == 1 then
    vim.fn.jobstart({"obsidian", "open", filepath}, {detach = true})
  end
  
  return filepath
end

return M
```

#### 5.5 Integration Commands
```lua
-- In core/commands/email.lua, add:
commands.HimalayaIntegrations = {
  fn = function()
    require('neotex.plugins.tools.himalaya.integrations').show_manager()
  end,
  opts = { desc = 'Manage integrations' }
}

commands.HimalayaIntegrationToggle = {
  fn = function(opts)
    local integrations = require('neotex.plugins.tools.himalaya.integrations')
    integrations.toggle(opts.args)
  end,
  opts = { 
    nargs = 1,
    complete = function()
      local integrations = require('neotex.plugins.tools.himalaya.integrations')
      return vim.tbl_keys(integrations.integrations)
    end,
    desc = 'Toggle integration' 
  }
}

-- Task integration
commands.HimalayaTaskCreate = {
  fn = function(opts)
    local tasks = require('neotex.plugins.tools.himalaya.integrations.tasks')
    tasks.create_from_current_email(opts.args)
  end,
  opts = { 
    nargs = '?',
    desc = 'Create task from email' 
  }
}

-- Calendar integration
commands.HimalayaEventCreate = {
  fn = function()
    local calendar = require('neotex.plugins.tools.himalaya.integrations.calendar')
    calendar.create_from_current_email()
  end,
  opts = { desc = 'Create calendar event from email' }
}

-- Notes integration
commands.HimalayaNoteCreate = {
  fn = function()
    local notes = require('neotex.plugins.tools.himalaya.integrations.notes')
    notes.create_from_current_email()
  end,
  opts = { desc = 'Save email as note' }
}
```

---

## Implementation Priority and Timeline

### Week 1: Core Features
1. **Multiple Account Views** (3 days)
   - Unified inbox
   - Split and tabbed views
   - Account synchronization

### Week 2: Advanced Features
2. **Email Rules** (2 days)
   - Rules engine
   - Rule builder UI
   - Action execution

3. **Integration Framework** (3 days)
   - Base framework
   - Task management integration
   - Calendar integration
   - Note-taking integration

### Testing and Polish
- Integration testing
- Performance optimization
- Documentation updates
- Bug fixes

## Success Criteria

1. **Multiple Account Views**
   - Can view emails from multiple accounts simultaneously
   - Smooth switching between view modes
   - Account-specific actions work correctly

2. **Email Rules**
   - Rules process incoming emails correctly
   - Rule builder is user-friendly
   - Actions execute reliably

3. **Integrations**
   - At least 2 integrations working
   - Easy to add new integrations
   - Configuration is straightforward

## Dependencies

- Phase 8 completion (for account management)
- Notification system (for user feedback)
- State management (for persistence)
- Event system (for integration hooks)

## Risk Mitigation

1. **Performance Impact**
   - Implement lazy loading for views
   - Cache account data appropriately
   - Optimize refresh cycles

2. **Complexity Management**
   - Keep features modular
   - Provide sensible defaults
   - Include escape hatches

3. **Integration Stability**
   - Handle API failures gracefully
   - Provide offline fallbacks
   - Clear error messages
