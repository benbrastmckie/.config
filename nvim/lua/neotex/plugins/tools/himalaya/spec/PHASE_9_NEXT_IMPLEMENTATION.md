# Phase 9 Next Implementation Features - Unified Email Scheduling System

**Status**: Ready for Implementation  
**Created**: 2025-07-07  
**Updated**: 2025-07-07 - Revised to integrate undo send with scheduling
**Priority**: High - Core Phase 9 Features

This specification outlines a unified email scheduling system that consolidates the existing undo send feature with comprehensive scheduling capabilities.

## Overview

### Design Philosophy
This implementation prioritizes a clean, unified scheduling system over backward compatibility. Breaking changes are acceptable to achieve a better architecture.

### Core Principles
1. **No Immediate Send**: ALL emails must be scheduled (minimum 60 seconds)
2. **Single System**: One scheduler handles all email sending
3. **Clean Architecture**: No legacy compatibility layers
4. **Safety First**: No bypasses or workarounds for immediate sending

### Key Changes (Breaking)
- Remove `send_queue.lua` entirely (replaced by `scheduler.lua`)
- Remove "Send Now" option from composer
- Remove old commands (`:HimalayaSendQueue`, `:HimalayaUndoSend`)
- Require explicit scheduling for all emails
- No compatibility aliases or migration paths

### New Architecture
A unified scheduling system where:
- **Every email is scheduled** with a minimum 60-second delay
- Users can modify scheduled times before sending
- Full scheduling UI with preset and custom times
- Clean command structure without legacy baggage
- Consistent behavior across all email operations

## Implementation Plan

### Phase 0: Remove Legacy Code

#### 0.1 Files to Remove
```bash
# Remove old send queue implementation
rm lua/neotex/plugins/tools/himalaya/core/send_queue.lua

# Remove any test files for old implementation
rm lua/neotex/plugins/tools/himalaya/scripts/test_send_queue.lua
```

#### 0.2 Functions to Remove from Composer
```lua
-- In ui/email_composer.lua, remove:
-- M.send_immediate()
-- M.send_with_undo() 
-- The entire "Send Now" option from send dialog
```

#### 0.3 Commands to Remove
```lua
-- Remove from core/commands/email.lua:
-- commands.HimalayaSendQueue
-- commands.HimalayaUndoSend
-- Any aliases or compatibility layers
```

### Phase 1: Create Unified Scheduler Module

#### 1.1 New Scheduler Module
Create `core/scheduler.lua` as a clean implementation:

```lua
-- Himalaya Unified Email Scheduling System
-- Manages all outgoing emails with configurable delays
-- Default 60-second delay provides undo capability for all sends

local M = {}

-- Enhanced configuration
M.config = {
  default_delay = 60,          -- 60 seconds for undo capability
  min_delay = 5,               -- Minimum 5 seconds (prevents accidental immediate send)
  check_interval = 5,          -- Check queue every 5 seconds
  max_retries = 3,             -- Maximum retry attempts
  retry_backoff = 60,          -- Base retry delay in seconds
  allow_immediate = false      -- No bypass allowed (safety feature)
}

-- Enhanced queue item structure
local scheduled_email_schema = {
  id = "",
  email_data = {},
  account_id = "",
  created_at = 0,
  scheduled_for = 0,        -- Renamed from 'send_at' for clarity
  original_delay = 0,       -- Store original delay for reference
  status = "scheduled",     -- scheduled, sending, sent, cancelled, failed
  retries = 0,
  error = nil,
  modified = false,         -- Track if user modified the time
  recurring = nil,          -- For future: recurring schedule info
  notification_window = nil,
  metadata = {}            -- Additional data (composer info, etc.)
}
```

#### 1.2 Enhanced Scheduling Functions

```lua
-- Schedule email with flexible timing
function M.schedule_email(email_data, account_id, options)
  options = options or {}
  local delay = options.delay or M.config.default_delay
  
  -- Enforce minimum delay for safety
  if delay < M.config.min_delay then
    delay = M.config.min_delay
  end
  
  local id = M.generate_id()
  local now = os.time()
  
  local item = {
    id = id,
    email_data = vim.deepcopy(email_data),
    account_id = account_id,
    created_at = now,
    scheduled_for = now + delay,
    original_delay = delay,
    status = "scheduled",
    retries = 0,
    error = nil,
    modified = false,
    metadata = options.metadata or {}
  }
  
  M.queue[id] = item
  M.save_queue()
  
  -- Show appropriate notification based on delay
  if delay <= 300 then -- 5 minutes or less
    M.show_undo_notification(id)
  else
    M.show_scheduled_notification(id)
  end
  
  -- Use existing notification system
  local notify = require('neotex.util.notifications')
  
  -- User action notification for scheduling
  notify.himalaya(
    string.format("📨 Email scheduled for %s", 
      delay <= 300 and M.format_duration(delay) or os.date("%Y-%m-%d %H:%M", item.scheduled_for)),
    notify.categories.USER_ACTION,
    {
      id = id,
      delay = delay,
      scheduled_for = item.scheduled_for,
      subject = email_data.subject,
      can_undo = true
    }
  )
  
  -- Log to system (debug mode only)
  logger.info("Email scheduled", {
    id = id,
    delay = delay,
    scheduled_for = os.date("%Y-%m-%d %H:%M", item.scheduled_for),
    subject = email_data.subject
  })
  
  return id
end

-- Modify scheduled time for an email
function M.reschedule_email(id, new_time)
  local item = M.queue[id]
  
  if not item then
    return false, "Email not found"
  end
  
  if item.status ~= "scheduled" then
    return false, "Can only reschedule pending emails"
  end
  
  -- Validate new time
  local now = os.time()
  if new_time <= now then
    return false, "Scheduled time must be in the future"
  end
  
  -- Update schedule
  item.scheduled_for = new_time
  item.modified = true
  M.save_queue()
  
  -- Update notification if visible
  if item.notification_window then
    M.refresh_notification(id)
  end
  
  -- Use unified notification system
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    string.format("✅ Email rescheduled for %s", 
      os.date("%Y-%m-%d %H:%M", new_time)),
    notify.categories.USER_ACTION,
    {
      id = id,
      old_time = item.scheduled_for,
      new_time = new_time,
      subject = item.email_data.subject
    }
  )
  
  return true
end
```

### Phase 2: Enhanced Interactive Windows

#### 2.1 Interactive Scheduling Window
Enhance the current undo notification window to support scheduling interactions while using the existing notification system for status updates:

```lua
-- Show interactive notification for scheduled email
function M.show_notification(id)
  local item = M.queue[id]
  if not item then return end
  
  local buf = vim.api.nvim_create_buf(false, true)
  local is_near_term = (item.scheduled_for - os.time()) <= 300
  
  -- Determine window size based on content
  local width = 60
  local height = is_near_term and 6 or 8
  
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    col = vim.o.columns - width - 2,
    row = vim.o.lines - height - 3,
    style = 'minimal',
    border = 'rounded',
    title = is_near_term and ' Sending Soon ' or ' Scheduled Email ',
    title_pos = 'center'
  })
  
  item.notification_window = win
  
  -- Set up keymaps
  local keymaps = {
    u = function() M.cancel_send(id) end,
    e = function() M.edit_scheduled_time(id) end,
    s = function() M.send_now(id) end,
    d = function() M.show_email_details(id) end,
    ['<Esc>'] = function() vim.api.nvim_win_close(win, true) end
  }
  
  for key, fn in pairs(keymaps) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, '', {
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          fn()
        end
      end
    })
  end
  
  -- Update display
  M.update_notification_display(id, buf)
  
  -- Set up auto-refresh
  if is_near_term then
    M.start_countdown_timer(id, buf)
  end
end

-- Update notification display
function M.update_notification_display(id, buf)
  local item = M.queue[id]
  if not item then return end
  
  local now = os.time()
  local scheduled_time = item.scheduled_for
  local time_until = scheduled_time - now
  
  local lines = {}
  
  -- Header with time info
  if time_until <= 300 then -- Near-term (5 minutes or less)
    table.insert(lines, string.format("📨 Sending in %s", M.format_duration(time_until)))
  else
    table.insert(lines, string.format("📅 Scheduled for %s", 
      os.date("%Y-%m-%d %H:%M", scheduled_time)))
    table.insert(lines, string.format("   (%s from now)", M.format_duration(time_until)))
  end
  
  -- Email info
  local subject = item.email_data.subject or "No subject"
  if #subject > 45 then
    subject = subject:sub(1, 42) .. "..."
  end
  
  table.insert(lines, "")
  table.insert(lines, "Subject: " .. subject)
  table.insert(lines, "To: " .. M.format_recipients(item.email_data.to))
  
  -- Actions
  table.insert(lines, "")
  table.insert(lines, "Actions:")
  table.insert(lines, "  [u] Undo/Cancel   [e] Edit time")
  table.insert(lines, "  [s] Send now      [d] Details")
  table.insert(lines, "  [ESC] Dismiss")
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end
```

#### 2.2 Schedule Modification UI

```lua
-- Interactive time editor
function M.edit_scheduled_time(id)
  local item = M.queue[id]
  if not item then return end
  
  local current = os.date("%Y-%m-%d %H:%M", item.scheduled_for)
  
  vim.ui.input({
    prompt = "New send time (YYYY-MM-DD HH:MM): ",
    default = current,
    completion = "customlist,v:lua.require'neotex.plugins.tools.himalaya.core.scheduler'.complete_time"
  }, function(input)
    if not input then return end
    
    local new_time = M.parse_time_input(input)
    if new_time then
      M.reschedule_email(id, new_time)
    else
      local notify = require('neotex.util.notifications')
      notify.himalaya("Invalid time format", notify.categories.ERROR, {
        input = input,
        expected_format = "YYYY-MM-DD HH:MM"
      })
    end
  end)
end

-- Quick reschedule picker
function M.show_reschedule_picker(id)
  local item = M.queue[id]
  if not item then return end
  
  local options = {
    "In 5 minutes",
    "In 30 minutes", 
    "In 1 hour",
    "In 2 hours",
    "Tomorrow morning (9 AM)",
    "Tomorrow afternoon (2 PM)",
    "Next Monday (9 AM)",
    "Custom time..."
  }
  
  vim.ui.select(options, {
    prompt = "Reschedule email to:"
  }, function(choice, idx)
    if not choice then return end
    
    local new_time
    local now = os.time()
    
    if idx == 1 then
      new_time = now + 300
    elseif idx == 2 then
      new_time = now + 1800
    elseif idx == 3 then
      new_time = now + 3600
    elseif idx == 4 then
      new_time = now + 7200
    elseif idx == 5 then
      new_time = M.get_next_time(9, 0)
    elseif idx == 6 then
      new_time = M.get_next_time(14, 0)
    elseif idx == 7 then
      new_time = M.get_next_monday(9, 0)
    elseif idx == 8 then
      M.edit_scheduled_time(id)
      return
    end
    
    if new_time then
      M.reschedule_email(id, new_time)
    end
  end)
end
```

### Phase 3: Enhanced Queue Management

#### 3.1 Improved Queue Viewer

```lua
-- Enhanced queue display with categories
function M.show_queue()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Himalaya Scheduled Emails")
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-scheduler')
  
  -- Categorize emails
  local categories = {
    immediate = {}, -- Next 5 minutes
    today = {},     -- Today after 5 minutes
    tomorrow = {},  -- Tomorrow
    future = {},    -- Beyond tomorrow
    completed = {}  -- Sent/cancelled/failed
  }
  
  local now = os.time()
  local today_end = M.get_end_of_day(now)
  local tomorrow_end = today_end + 86400
  
  for id, item in pairs(M.queue) do
    if item.status == "scheduled" then
      if item.scheduled_for - now <= 300 then
        table.insert(categories.immediate, item)
      elseif item.scheduled_for <= today_end then
        table.insert(categories.today, item)
      elseif item.scheduled_for <= tomorrow_end then
        table.insert(categories.tomorrow, item)
      else
        table.insert(categories.future, item)
      end
    else
      table.insert(categories.completed, item)
    end
  end
  
  -- Render categories
  local lines = {}
  table.insert(lines, "📨 Scheduled Emails")
  table.insert(lines, string.rep("─", 70))
  
  M.render_category(lines, "⚡ Sending Soon", categories.immediate)
  M.render_category(lines, "📅 Today", categories.today)
  M.render_category(lines, "📆 Tomorrow", categories.tomorrow)
  M.render_category(lines, "🗓️ Future", categories.future)
  M.render_category(lines, "✅ Completed", categories.completed)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set up keymaps for queue management
  M.setup_queue_keymaps(buf)
  
  -- Open in split
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
end
```

### Phase 4: Composer Integration

#### 4.1 Update Email Composer
Modify `ui/email_composer.lua` to use the unified scheduler:

```lua
-- Replace current send_email function
function M.send_email(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    local notify = require('neotex.util.notifications')
    notify.himalaya('Not a compose buffer', notify.categories.ERROR)
    return
  end
  
  -- Parse and validate email
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local email = parse_email_buffer(lines)
  
  if not email.to or email.to == '' then
    local notify = require('neotex.util.notifications')
    notify.himalaya('Please specify a recipient', notify.categories.ERROR)
    return
  end
  
  -- Show scheduling options (no immediate send)
  M.show_scheduling_options(buf, draft_info, email)
end

-- Scheduling options (no immediate send)
function M.show_scheduling_options(buf, draft_info, email)
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  local options = {
    "1 minute (default)",
    "5 minutes",
    "30 minutes",
    "1 hour",
    "2 hours",
    "Tomorrow morning (9 AM)",
    "Custom time...",
    "Cancel"
  }
  
  vim.ui.select(options, {
    prompt = " When to send?",
    format_item = function(item)
      if item:match("1 minute") then
        return "⏰ " .. item .. " (default)"
      elseif item:match("Cancel") then
        return "❌ " .. item
      else
        return "📅 " .. item
      end
    end
  }, function(choice, idx)
    if not choice or choice == "Cancel" then
      return
    end
    
    local delay
    if idx == 1 then
      delay = 60        -- 1 minute
    elseif idx == 2 then
      delay = 300       -- 5 minutes
    elseif idx == 3 then
      delay = 1800      -- 30 minutes
    elseif idx == 4 then
      delay = 3600      -- 1 hour
    elseif idx == 5 then
      delay = 7200      -- 2 hours
    elseif idx == 6 then
      -- Tomorrow morning
      delay = M.calculate_delay_until_tomorrow(9, 0)
    elseif idx == 7 then
      -- Custom time picker
      M.show_custom_schedule_picker(buf, draft_info, email)
      return
    end
    
    -- Schedule the email
    local queue_id = scheduler.schedule_email(email, draft_info.account, {
      delay = delay,
      metadata = {
        draft_file = draft_info.file,
        draft_id = draft_info.draft_id
      }
    })
    
    if queue_id then
      local notify = require('neotex.util.notifications')
      notify.himalaya(
        string.format("✅ Email scheduled to send in %s", 
          scheduler.format_duration(delay)),
        notify.categories.USER_ACTION,
        {
          queue_id = queue_id,
          delay = delay,
          subject = email.subject
        }
      )
      
      -- Clean up composer
      M.cleanup_after_queue(buf, draft_info)
    end
  end)
end
```

### Phase 5: Clean Command Structure

#### 5.1 Commands

```lua
-- In core/commands/email.lua
commands.HimalayaSchedule = {
  fn = function()
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    scheduler.show_queue()
  end,
  opts = { desc = 'Show scheduled emails' }
}

commands.HimalayaScheduleCancel = {
  fn = function(opts)
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    if opts.args and opts.args ~= '' then
      scheduler.cancel_send(opts.args)
    else
      scheduler.cancel_from_queue_view()
    end
  end,
  opts = { 
    nargs = '?',
    desc = 'Cancel scheduled email' 
  }
}

commands.HimalayaScheduleEdit = {
  fn = function(opts)
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    if opts.args and opts.args ~= '' then
      scheduler.edit_scheduled_time(opts.args)
    else
      scheduler.edit_from_queue_view()
    end
  end,
  opts = {
    nargs = '?',
    desc = 'Edit scheduled time'
  }
}

-- No backward compatibility - users should update to new commands
```

## Notification System Integration

### Proper Usage of Existing Notifications

The scheduler integrates with the existing unified notification system rather than creating its own:

```lua
local notify = require('neotex.util.notifications')

-- User actions (always shown)
notify.himalaya("Email scheduled", notify.categories.USER_ACTION, {
  subject = email.subject,
  scheduled_time = scheduled_time
})

-- Status updates (debug mode only)
notify.himalaya("Processing scheduled emails", notify.categories.STATUS, {
  count = queue_count
})

-- Background operations (debug mode only)
notify.himalaya("Queue check completed", notify.categories.BACKGROUND, {
  processed = processed_count
})

-- Errors (always shown)
notify.himalaya("Failed to send scheduled email", notify.categories.ERROR, {
  error = error_message,
  email_id = id
})
```

### Interactive Windows vs Notifications

- **Interactive Windows**: Used for the scheduling interface (floating windows with keymaps)
- **Status Notifications**: Use the existing notification system for all status updates
- **No Duplicate Systems**: Don't recreate notification functionality

## Benefits of This Approach

1. **Safety by Default**: All emails have at least a 60-second delay
2. **Unified System**: One queue handles both undo and scheduling
3. **Flexibility**: Users can modify send times before emails go out
4. **Minimal Changes**: Builds on existing, working code
5. **Better UX**: More options without complexity
6. **Consistent Notifications**: Uses existing notification system
7. **Clean Codebase**: No legacy compatibility layers

## Implementation Timeline

### Week 1: Core Implementation (3 days)
1. Create new `scheduler.lua` module
2. Remove old `send_queue.lua`
2. Add variable scheduling times
3. Enhance notification system
4. Update queue viewer

### Week 1-2: UI and Polish (2 days)
5. Integrate with composer
6. Add schedule modification UI
7. Implement custom time picker
8. Update all commands

### Testing (2 days)
- Test migration from existing queue
- Verify all scheduling scenarios
- Test notification updates
- Performance testing with many scheduled emails

## Success Criteria

1. ✅ All emails go through the scheduler (no bypass)
2. ✅ Default 60-second delay preserved
3. ✅ Can modify scheduled time before send
4. ✅ Clear visual feedback for all states
5. ✅ Existing undo functionality intact
6. ✅ Performance remains good with many scheduled emails

## Window Management Improvements (Separate Feature)

### Overview
Enhance window coordination, layouts, and navigation for better multi-window email management.

### Implementation Plan

#### 1. Window Manager Module
Create `ui/window_manager.lua`:

```lua
local M = {}

-- Window layouts
M.layouts = {
  CLASSIC = "classic",      -- List | Preview
  VERTICAL = "vertical",    -- List on top, Preview below
  THREEPANE = "threepane",  -- Folders | List | Preview
  FOCUSED = "focused",      -- Single window focus mode
  CUSTOM = "custom"         -- User-defined layout
}

-- Window state
M.state = {
  layout = M.layouts.CLASSIC,
  windows = {},
  last_focused = nil,
  resize_mode = false
}

-- Window types
M.window_types = {
  FOLDER_TREE = "folder_tree",
  EMAIL_LIST = "email_list",
  EMAIL_PREVIEW = "email_preview",
  COMPOSER = "composer",
  SEARCH = "search",
  SETTINGS = "settings"
}

-- Initialize window manager
function M.setup()
  -- Set up autocmds for window coordination
  M.setup_autocmds()
  
  -- Load saved layout preferences
  M.load_preferences()
end

-- Create layout
function M.create_layout(layout_name)
  layout_name = layout_name or M.state.layout
  M.state.layout = layout_name
  
  -- Close existing windows
  M.close_all_windows()
  
  if layout_name == M.layouts.CLASSIC then
    M.create_classic_layout()
  elseif layout_name == M.layouts.VERTICAL then
    M.create_vertical_layout()
  elseif layout_name == M.layouts.THREEPANE then
    M.create_threepane_layout()
  elseif layout_name == M.layouts.FOCUSED then
    M.create_focused_layout()
  end
  
  -- Save layout preference
  M.save_preferences()
end

-- Classic layout: List | Preview
function M.create_classic_layout()
  -- Create email list window (left)
  vim.cmd('vsplit')
  local list_win = vim.api.nvim_get_current_win()
  local list_buf = M.create_email_list_buffer()
  vim.api.nvim_win_set_buf(list_win, list_buf)
  vim.api.nvim_win_set_width(list_win, math.floor(vim.o.columns * 0.4))
  
  -- Create preview window (right)
  vim.cmd('wincmd l')
  local preview_win = vim.api.nvim_get_current_win()
  local preview_buf = M.create_preview_buffer()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  
  -- Store window references
  M.state.windows = {
    [M.window_types.EMAIL_LIST] = {
      win = list_win,
      buf = list_buf
    },
    [M.window_types.EMAIL_PREVIEW] = {
      win = preview_win,
      buf = preview_buf
    }
  }
  
  -- Focus on list
  vim.api.nvim_set_current_win(list_win)
end

-- Three-pane layout: Folders | List | Preview
function M.create_threepane_layout()
  -- Create folder tree window (left)
  vim.cmd('vsplit')
  vim.cmd('vsplit')
  
  local folder_win = vim.api.nvim_get_current_win()
  local folder_buf = M.create_folder_tree_buffer()
  vim.api.nvim_win_set_buf(folder_win, folder_buf)
  vim.api.nvim_win_set_width(folder_win, 20)
  
  -- Create email list window (middle)
  vim.cmd('wincmd l')
  local list_win = vim.api.nvim_get_current_win()
  local list_buf = M.create_email_list_buffer()
  vim.api.nvim_win_set_buf(list_win, list_buf)
  vim.api.nvim_win_set_width(list_win, math.floor((vim.o.columns - 20) * 0.4))
  
  -- Create preview window (right)
  vim.cmd('wincmd l')
  local preview_win = vim.api.nvim_get_current_win()
  local preview_buf = M.create_preview_buffer()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  
  -- Store window references
  M.state.windows = {
    [M.window_types.FOLDER_TREE] = {
      win = folder_win,
      buf = folder_buf
    },
    [M.window_types.EMAIL_LIST] = {
      win = list_win,
      buf = list_buf
    },
    [M.window_types.EMAIL_PREVIEW] = {
      win = preview_win,
      buf = preview_buf
    }
  }
  
  -- Focus on list
  vim.api.nvim_set_current_win(list_win)
end
```

#### 2. Window Coordination
```lua
-- Coordinate window updates
function M.update_preview(email_id)
  local preview = M.state.windows[M.window_types.EMAIL_PREVIEW]
  if not preview or not vim.api.nvim_win_is_valid(preview.win) then
    return
  end
  
  -- Update preview content
  local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
  email_preview.show_email_in_buffer(email_id, preview.buf)
  
  -- Ensure window is visible
  if M.state.layout == M.layouts.FOCUSED then
    M.focus_window(M.window_types.EMAIL_PREVIEW)
  end
end

-- Smart window focusing
function M.focus_window(window_type)
  local window = M.state.windows[window_type]
  if not window or not vim.api.nvim_win_is_valid(window.win) then
    return
  end
  
  -- Store last focused
  M.state.last_focused = window_type
  
  if M.state.layout == M.layouts.FOCUSED then
    -- In focused mode, maximize the window
    M.maximize_window(window.win)
  else
    -- Just focus the window
    vim.api.nvim_set_current_win(window.win)
  end
end

-- Window navigation
function M.navigate(direction)
  if M.state.layout == M.layouts.FOCUSED then
    -- In focused mode, cycle through windows
    M.cycle_focused_window(direction)
  else
    -- Normal vim window navigation
    vim.cmd('wincmd ' .. direction)
  end
end

-- Resize windows
function M.resize_window(window_type, size)
  local window = M.state.windows[window_type]
  if not window or not vim.api.nvim_win_is_valid(window.win) then
    return
  end
  
  if type(size) == "string" then
    -- Relative resize
    if size:match("^[+-]") then
      local delta = tonumber(size)
      local current = vim.api.nvim_win_get_width(window.win)
      vim.api.nvim_win_set_width(window.win, current + delta)
    end
  else
    -- Absolute size
    vim.api.nvim_win_set_width(window.win, size)
  end
end

-- Interactive resize mode
function M.enter_resize_mode()
  M.state.resize_mode = true
  local notify = require('neotex.util.notifications')
  
  notify.himalaya(
    "Resize mode: h/l to resize horizontally, j/k vertically, q to quit",
    notify.categories.STATUS
  )
  
  -- Set up temporary keymaps
  local current_win = vim.api.nvim_get_current_win()
  local resize_keymaps = {
    h = function() vim.cmd('vertical resize -2') end,
    l = function() vim.cmd('vertical resize +2') end,
    j = function() vim.cmd('resize -2') end,
    k = function() vim.cmd('resize +2') end,
    H = function() vim.cmd('vertical resize -10') end,
    L = function() vim.cmd('vertical resize +10') end,
    J = function() vim.cmd('resize -10') end,
    K = function() vim.cmd('resize +10') end,
    q = function() M.exit_resize_mode() end,
    ['<Esc>'] = function() M.exit_resize_mode() end
  }
  
  for key, fn in pairs(resize_keymaps) do
    vim.keymap.set('n', key, fn, { 
      buffer = 0, 
      desc = "Resize window" 
    })
  end
end
```

#### 3. Window Persistence
```lua
-- Save window layout
function M.save_layout(name)
  local layout = {
    name = name or "custom",
    windows = {},
    layout_type = M.state.layout
  }
  
  -- Capture window dimensions and positions
  for win_type, window in pairs(M.state.windows) do
    if vim.api.nvim_win_is_valid(window.win) then
      layout.windows[win_type] = {
        width = vim.api.nvim_win_get_width(window.win),
        height = vim.api.nvim_win_get_height(window.win),
        position = vim.api.nvim_win_get_position(window.win)
      }
    end
  end
  
  -- Save to state
  local saved_layouts = state.get('window_layouts', {})
  saved_layouts[name] = layout
  state.set('window_layouts', saved_layouts)
  
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    string.format("Layout '%s' saved", name),
    notify.categories.USER_ACTION,
    {
      layout_name = name,
      layout_type = layout.layout_type
    }
  )
end

-- Load saved layout
function M.load_layout(name)
  local saved_layouts = state.get('window_layouts', {})
  local layout = saved_layouts[name]
  
  if not layout then
    local notify = require('neotex.util.notifications')
    notify.himalaya(
      string.format("Layout '%s' not found", name),
      notify.categories.ERROR,
      {
        requested_layout = name,
        available_layouts = vim.tbl_keys(saved_layouts)
      }
    )
    return
  end
  
  -- Recreate layout
  M.create_layout(layout.layout_type)
  
  -- Restore window dimensions
  for win_type, dimensions in pairs(layout.windows) do
    local window = M.state.windows[win_type]
    if window and vim.api.nvim_win_is_valid(window.win) then
      vim.api.nvim_win_set_width(window.win, dimensions.width)
      vim.api.nvim_win_set_height(window.win, dimensions.height)
    end
  end
end
```

#### 4. Window Commands
```lua
-- In core/commands/ui.lua, add:
commands.HimalayaLayout = {
  fn = function(opts)
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.create_layout(opts.args)
  end,
  opts = { 
    nargs = '?',
    complete = function()
      return {'classic', 'vertical', 'threepane', 'focused'}
    end,
    desc = 'Change window layout' 
  }
}

commands.HimalayaWindowResize = {
  fn = function()
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.enter_resize_mode()
  end,
  opts = { desc = 'Enter window resize mode' }
}

commands.HimalayaWindowSave = {
  fn = function(opts)
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.save_layout(opts.args)
  end,
  opts = { 
    nargs = 1,
    desc = 'Save current window layout' 
  }
}

commands.HimalayaWindowLoad = {
  fn = function(opts)
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.load_layout(opts.args)
  end,
  opts = { 
    nargs = 1,
    complete = function()
      local saved = state.get('window_layouts', {})
      return vim.tbl_keys(saved)
    end,
    desc = 'Load saved window layout' 
  }
}
```

## Combined Implementation Timeline

### Week 1: Clean Implementation
1. **Day 1**: Remove legacy code
   - Delete send_queue.lua and related files
   - Remove immediate send functions from composer
   - Clean up old commands

2. **Days 2-3**: Core scheduler implementation
   - Create new scheduler.lua from scratch
   - Implement variable timing support
   - Add reschedule functionality

2. **Day 3**: Notification system
   - Enhanced notification windows
   - Schedule modification UI
   - Quick reschedule options

3. **Days 4-5**: Integration & Testing
   - Update composer for scheduling-only
   - Implement new command structure
   - Test all scheduling scenarios

### Week 2: Window Management
4. **Days 6-7**: Layout system
   - Basic layouts implementation
   - Window coordination
   - State management

5. **Day 8**: Advanced features
   - Interactive resize mode
   - Layout persistence
   - Smart navigation

6. **Days 9-10**: Polish & Testing
   - Integration testing
   - Performance optimization
   - Documentation

## Risk Mitigation

### Scheduler Risks
1. **User Adjustment**: Clear documentation about breaking changes
2. **Performance**: Use efficient timer management
3. **State Corruption**: Validate all state transitions

### Window Management Risks
1. **Layout Conflicts**: Validate window state before operations
2. **Performance**: Lazy load content, debounce updates
3. **Compatibility**: Test with various terminal sizes

## Conclusion

This clean implementation approach creates a better system by:
- **Removing complexity**: No legacy code or compatibility layers
- **Enforcing safety**: All emails must be scheduled
- **Improving maintainability**: Single, unified codebase
- **Enhancing UX**: Consistent behavior without exceptions

Breaking changes are worth it for:
- Cleaner architecture
- Easier maintenance
- Better user experience
- Reduced bugs from edge cases

The window management improvements remain separate but complementary, enhancing the overall email management experience.