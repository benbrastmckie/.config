# Phase 9 Enhanced Scheduling UI

**Status**: ✅ COMPLETED  
**Created**: 2025-07-07  
**Completed**: 2025-07-07  
**Priority**: Medium - Enhanced User Experience Features

This specification details the remaining Phase 9 features for enhanced scheduling UI, including interactive windows and advanced queue management.

## Overview

Building on the core unified scheduling system already implemented, these enhancements focus on improving the user experience with interactive scheduling windows and comprehensive queue management.

### User Experience Vision

The enhanced scheduling UI seamlessly integrates scheduled emails into the existing Himalaya sidebar, providing a unified view of both inbox emails and outgoing scheduled emails with live countdowns and quick actions.

#### Key UI Components

1. **Integrated Sidebar Schedule Section**
   - Scheduled emails appear at the bottom of the Himalaya sidebar
   - Live countdown timers update in real-time for each scheduled email
   - Visual separation from inbox emails with a clear divider
   - Consistent navigation with existing email list (j/k movement)

2. **Unified Preview Mode**
   - Preview mode works for both inbox and scheduled emails
   - Shows full email content and metadata when selected
   - For scheduled emails, displays send time and current status
   - Seamless switching between previewing inbox and scheduled emails

3. **Telescope Integration**
   - Reschedule uses telescope picker matching email send interface
   - Quick preset options (5min, 30min, 1hr, tomorrow morning, etc.)
   - Natural language time input ("2h", "tomorrow 9am", "next monday")
   - Consistent UI experience across all email operations

### Workflow Enhancements

#### Scheduling Workflow
1. User composes email and presses `<leader>me` to send
2. Selects from scheduling options (1 min default, 5 min, 30 min, etc.)
3. **NEW**: Scheduled email appears at bottom of sidebar with countdown
4. **NEW**: User can navigate to it like any other email in the list
5. **NEW**: Live countdown updates every second for imminent sends

#### Sidebar Navigation Workflow
1. User navigates email list with j/k as normal
2. **NEW**: Seamlessly moves between inbox emails and scheduled section
3. **NEW**: Press `<CR>` on scheduled email to preview (if preview mode on)
4. **NEW**: Press `gD` to cancel scheduled email (consistent with delete)
5. **NEW**: Press `e` to open reschedule floating window

#### Rescheduling Workflow
1. Navigate to scheduled email in sidebar and press `e`
2. **NEW**: Telescope picker appears with smart time options
3. **NEW**: Select preset or choose "Custom time..." for input
4. **NEW**: Natural language parsing ("2h", "tomorrow 9am")
5. **NEW**: Picker closes and sidebar updates immediately

#### Preview Integration
1. Enable preview mode with `<CR>` on any email
2. **NEW**: Works identically for inbox and scheduled emails  
3. **NEW**: Scheduled emails show countdown and send time in preview
4. **NEW**: Preview updates live as countdown progresses
5. **NEW**: Switch between inbox/scheduled emails maintains preview mode

### Visual Design Principles

- **Unified Interface**: Scheduled emails live in the main sidebar, not separate windows
- **Consistent Navigation**: Same keybindings work across inbox and scheduled emails  
- **Live Updates**: Countdown timers refresh in-place without flicker
- **Clear Separation**: Visual divider between inbox and scheduled sections
- **Contextual Actions**: Actions appear based on email type (inbox vs scheduled)
- **Consistent Interface**: Telescope pickers for all selection dialogs

### Integration Benefits

These enhancements deeply integrate with existing Himalaya systems:
- Scheduled emails use the same sidebar infrastructure
- Preview mode extended to handle scheduled emails naturally
- Delete action (`gD`) works consistently across email types
- Navigation (j/k) seamlessly moves through all emails
- Telescope pickers maintain UI consistency

### Visual Mockups

#### Enhanced Sidebar with Scheduled Emails
```
Himalaya - Gmail - INBOX                                    
Page 1 / 3 | 47 emails                                     

   1   Today      John Doe         Project Update          
   2   Today      Alice Smith      Meeting Notes           
   3   Yesterday  Bob Wilson       Re: Proposal            
   4   Yesterday  Carol Brown      Quick Question          
   5   Monday     David Lee        Team Sync               

────────────────────────── Scheduled (3) ──────────────────────────

   6    00:58   Weekly Report to team@company.com       
   7    04:32   Meeting follow-up to client@external.com
   8    29:15   Design feedback to design@company.com   

[j/k navigate, <CR> preview, gD delete, e reschedule]
```

#### Preview Mode for Scheduled Email
```
Himalaya - Gmail - INBOX                    │ Preview: Weekly Report
Page 1 / 3 | 47 emails                     │ 
                                           │ Status:  Scheduled
   1   Today      John Doe      Project... │ Send in: 00:58
   2   Today      Alice Smith    Meeting... │ Send at: 14:30 today
   3   Yesterday  Bob Wilson     Re: Pro... │ 
   4   Yesterday  Carol Brown    Quick Q... │ From: me@company.com
   5   Monday     David Lee      Team Sy... │ To: team@company.com
                                           │ Subject: Weekly Report
──────────────── Scheduled (3) ────────────│ 
                                           │ Hi team,
 ▸ 6    00:58   Weekly Report to team@... │ 
   7    04:32   Meeting follow-up to c... │ Here's our weekly progress update:
   8    29:15   Design feedback to des... │ 
                                           │ 1. Completed features:
                                           │    - User authentication
                                           │    - Dashboard redesign
```

#### Reschedule Telescope Picker
```
╭─ Reschedule email ──────────────────────────────────────╮
│ > In 5 minutes                                          │
│   In 30 minutes                                         │
│   In 1 hour                                             │
│   In 2 hours                                            │
│   Tomorrow morning (9 AM)                               │
│   Tomorrow afternoon (2 PM)                             │
│   Next Monday (9 AM)                                    │
│   Custom time...                                        │
╰─────────────────────────────────────────────────────────╯
```

## Phase 2: Sidebar Integration with Live Updates ✅ COMPLETED

### 2.1 Scheduled Email Section in Sidebar ✅

Extend the existing Himalaya sidebar to include a dedicated section for scheduled emails with live countdown timers and integrated actions.

#### Implementation Details

```lua
-- In ui/email_list.lua - Extend format_email_list to include scheduled emails

function M.format_email_list(emails)
  local lines = {}
  local metadata = {}
  
  -- Existing email list formatting...
  -- [current implementation]
  
  -- Add scheduled emails section
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  local scheduled_items = scheduler.get_scheduled_emails()
  
  if #scheduled_items > 0 then
    -- Add visual separator
    table.insert(lines, "")
    table.insert(lines, string.rep("─", 30) .. " Scheduled (" .. #scheduled_items .. ") " .. string.rep("─", 30))
    table.insert(lines, "")
    
    -- Add each scheduled email with countdown
    for i, item in ipairs(scheduled_items) do
      local line_num = #lines + 1
      local time_left = item.scheduled_for - os.time()
      local countdown = M.format_countdown(time_left)
      
      -- Store metadata for navigation
      metadata[line_num] = {
        type = 'scheduled',
        id = item.id,
        email_data = item.email_data,
        scheduled_for = item.scheduled_for
      }
      
      -- Format: [countdown] [subject] to [recipient]
      local subject = item.email_data.subject or "No subject"
      if #subject > 30 then
        subject = subject:sub(1, 27) .. "..."
      end
      
      local to = item.email_data.to or ""
      if #to > 25 then
        to = to:sub(1, 22) .. "..."
      end
      
      table.insert(lines, string.format(" %s   %s to %s", 
        countdown, subject, to))
    end
  end
  
  return {
    lines = lines,
    metadata = metadata,
    scheduled_start_line = scheduled_start_line
  }
end

-- Format countdown timer
function M.format_countdown(seconds)
  if seconds <= 0 then
    return " SENDING"
  elseif seconds < 60 then
    return string.format(" %02d:%02d", 0, seconds)
  elseif seconds < 3600 then
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format(" %02d:%02d", mins, secs)
  else
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    return string.format("%3d:%02d", hours, mins)
  end
end
```

### 2.2 Live Countdown Updates ✅

Implement efficient sidebar updates for countdown timers:

```lua
-- In ui/email_list.lua - Setup timer for live updates

function M.start_scheduled_updates()
  -- Stop existing timer if any
  if M.scheduled_timer then
    M.scheduled_timer:stop()
    M.scheduled_timer:close()
  end
  
  M.scheduled_timer = vim.loop.new_timer()
  
  -- Update every second for smooth countdown
  M.scheduled_timer:start(0, 1000, vim.schedule_wrap(function()
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    
    -- Only update if sidebar is open and has scheduled emails
    if not sidebar.is_open() then
      return
    end
    
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    local scheduled_items = scheduler.get_scheduled_emails()
    
    if #scheduled_items == 0 then
      -- No scheduled emails, stop timer
      M.scheduled_timer:stop()
      return
    end
    
    -- Update only the scheduled section lines
    M.update_scheduled_section()
  end))
end

-- Efficient update of just the scheduled section
function M.update_scheduled_section()
  local buf = vim.api.nvim_get_current_buf()
  local metadata = vim.b[buf].email_metadata or {}
  
  -- Find where scheduled section starts
  local scheduled_start = nil
  for line, data in pairs(metadata) do
    if data.type == 'scheduled' then
      scheduled_start = line
      break
    end
  end
  
  if not scheduled_start then return end
  
  -- Update only the countdown timers in place
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  local scheduled_items = scheduler.get_scheduled_emails()
  
  for i, item in ipairs(scheduled_items) do
    local line_idx = scheduled_start + i - 1
    local time_left = item.scheduled_for - os.time()
    local countdown = M.format_countdown(time_left)
    
    -- Get current line and update just the countdown
    local current_line = vim.api.nvim_buf_get_lines(buf, line_idx - 1, line_idx, false)[1]
    if current_line then
      -- Replace the countdown portion (first 8 characters)
      local updated_line = countdown .. current_line:sub(9)
      vim.api.nvim_buf_set_lines(buf, line_idx - 1, line_idx, false, {updated_line})
    end
  end
end
```

### 2.3 Telescope Reschedule Picker ✅

Provide a telescope picker interface for rescheduling emails when user presses 'e' on a scheduled email:

```lua
-- Telescope reschedule picker with presets
function M.show_reschedule_picker(id)
  local item = M.queue[id]
  if not item then return end
  
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  local options = {
    { text = "In 5 minutes", value = 300 },
    { text = "In 30 minutes", value = 1800 },
    { text = "In 1 hour", value = 3600 },
    { text = "In 2 hours", value = 7200 },
    { text = "Tomorrow morning (9 AM)", value = "tomorrow_9am" },
    { text = "Tomorrow afternoon (2 PM)", value = "tomorrow_2pm" },
    { text = "Next Monday (9 AM)", value = "next_monday_9am" },
    { text = "Custom time...", value = "custom" }
  }
  
  pickers.new({}, {
    prompt_title = "Reschedule Email",
    finder = finders.new_table {
      results = options,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.text,
          ordinal = entry.text,
        }
      end
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end
        
        local value = selection.value
        local new_time
        local now = os.time()
        
        if type(value) == "number" then
          new_time = now + value
        elseif value == "tomorrow_9am" then
          new_time = M.get_next_time(9, 0)
        elseif value == "tomorrow_2pm" then
          new_time = M.get_next_time(14, 0)
        elseif value == "next_monday_9am" then
          new_time = M.get_next_monday(9, 0)
        elseif value == "custom" then
          M.show_custom_time_picker(id)
          return
        end
        
        if new_time then
          M.reschedule_email(id, new_time)
        end
      end)
      return true
    end,
  }):find()
end
```

### 2.4 Custom Time Picker ✅

Advanced time selection with validation:

```lua
-- Custom time picker with smart parsing
function M.show_custom_time_picker(id)
  local item = M.queue[id]
  if not item then return end
  
  local current = os.date("%Y-%m-%d %H:%M", item.scheduled_for)
  
  vim.ui.input({
    prompt = " New send time: ",
    default = current,
    completion = "customlist,v:lua.require'neotex.plugins.tools.himalaya.core.scheduler'.complete_time"
  }, function(input)
    if not input then return end
    
    -- Parse various time formats
    local new_time = M.parse_time_input(input)
    
    if new_time then
      -- Validate time is in future
      if new_time > os.time() then
        M.reschedule_email(id, new_time)
      else
        local notify = require('neotex.util.notifications')
        notify.himalaya(" Time must be in the future", notify.categories.ERROR)
      end
    else
      local notify = require('neotex.util.notifications')
      notify.himalaya(" Invalid time format. Try: YYYY-MM-DD HH:MM or '2h', 'tomorrow 9am'", 
        notify.categories.ERROR)
    end
  end)
end

-- Parse flexible time inputs
function M.parse_time_input(input)
  -- Support various formats:
  -- "2025-12-25 14:30" - Standard format
  -- "2h" or "2 hours" - Relative time
  -- "tomorrow 9am" - Natural language
  -- "next monday" - Day references
  
  local now = os.time()
  
  -- Standard datetime format
  local year, month, day, hour, min = input:match("(%d+)-(%d+)-(%d+)%s+(%d+):(%d+)")
  if year then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = 0
    })
  end
  
  -- Relative time (e.g., "2h", "30m", "1d")
  local amount, unit = input:match("^(%d+)%s*([hmd])$")
  if amount then
    amount = tonumber(amount)
    if unit == 'h' then
      return now + (amount * 3600)
    elseif unit == 'm' then
      return now + (amount * 60)
    elseif unit == 'd' then
      return now + (amount * 86400)
    end
  end
  
  -- Natural language parsing
  if input:match("tomorrow") then
    local hour = input:match("(%d+)[ap]m") or input:match("(%d+)")
    hour = tonumber(hour) or 9
    if input:match("pm") and hour < 12 then
      hour = hour + 12
    end
    return M.get_next_time(hour, 0)
  end
  
  return nil
end
```

## Phase 3: Enhanced Preview and Keybindings ✅ COMPLETED

### 3.1 Extended Preview Mode for Scheduled Emails ✅

Extend the existing preview mode to handle scheduled emails seamlessly:

```lua
-- In ui/email_preview.lua - Extend show_preview to handle scheduled emails

function M.show_preview(email_id, parent_win)
  local metadata = vim.b[vim.api.nvim_win_get_buf(parent_win)].email_metadata or {}
  local email_data = nil
  local is_scheduled = false
  
  -- Check if this is a scheduled email
  for _, data in pairs(metadata) do
    if data.type == 'scheduled' and data.id == email_id then
      email_data = data.email_data
      is_scheduled = true
      break
    end
  end
  
  -- Fall back to regular email if not scheduled
  if not email_data then
    email_data = M.get_email_content(email_id)
  end
  
  -- Format preview content based on email type
  local content = {}
  
  if is_scheduled then
    -- Add scheduled email header
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    local item = scheduler.get_scheduled_email(email_id)
    
    if item then
      local time_left = item.scheduled_for - os.time()
      table.insert(content, "Status:  Scheduled")
      table.insert(content, "Send in: " .. M.format_countdown(time_left))
      table.insert(content, "Send at: " .. os.date("%Y-%m-%d %H:%M", item.scheduled_for))
      table.insert(content, "")
    end
  end
  
  -- Add standard email headers
  table.insert(content, "From: " .. (email_data.from or ""))
  table.insert(content, "To: " .. (email_data.to or ""))
  if email_data.cc then
    table.insert(content, "Cc: " .. email_data.cc)
  end
  table.insert(content, "Subject: " .. (email_data.subject or ""))
  table.insert(content, "")
  
  -- Add body
  local body_lines = vim.split(email_data.body or "", "\n")
  for _, line in ipairs(body_lines) do
    table.insert(content, line)
  end
  
  -- Display in preview window
  M.update_preview_window(content)
end
```

### 3.2 Keybinding Extensions for Scheduled Emails ✅

Add context-aware keybindings for scheduled emails in the sidebar:

```lua
-- In core/config.lua - Extend setup_buffer_keymaps for scheduled emails

function M.setup_buffer_keymaps(buf)
  -- Existing keymaps...
  
  -- Add scheduled email specific keymaps
  local keymap = function(mode, key, action, opts)
    opts = opts or {}
    opts.buffer = buf
    opts.silent = true
    vim.keymap.set(mode, key, action, opts)
  end
  
  -- Context-aware delete (cancel for scheduled emails)
  keymap('n', 'gD', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local metadata = vim.b[buf].email_metadata or {}
    local email_data = metadata[line]
    
    if email_data and email_data.type == 'scheduled' then
      -- Cancel scheduled email
      local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
      scheduler.cancel_send(email_data.id)
    else
      -- Regular delete for inbox emails
      M.delete_email()
    end
  end, { desc = 'Delete/Cancel email' })
  
  -- Reschedule action (only works on scheduled emails)
  keymap('n', 'e', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local metadata = vim.b[buf].email_metadata or {}
    local email_data = metadata[line]
    
    if email_data and email_data.type == 'scheduled' then
      local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
      scheduler.show_reschedule_picker(email_data.id)
    else
      local notify = require('neotex.util.notifications')
      notify.himalaya(" Can only reschedule scheduled emails", notify.categories.STATUS)
    end
  end, { desc = 'Edit scheduled time' })
  
  -- Context-aware enter (preview works for both types)
  keymap('n', '<CR>', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local metadata = vim.b[buf].email_metadata or {}
    local email_data = metadata[line]
    
    if email_data then
      local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
      if email_data.type == 'scheduled' then
        preview.show_preview(email_data.id, vim.api.nvim_get_current_win())
      else
        -- Regular email preview
        preview.show_preview(email_data.id, vim.api.nvim_get_current_win())
      end
    end
  end, { desc = 'Preview email' })
end
```

### 3.3 Email Details View ✅

Provide a detailed view of scheduled emails (could be telescope preview or dedicated buffer):

**Note**: This functionality is provided through the enhanced preview mode (3.1) which shows all scheduled email details including countdown, send time, and full email content. A separate details view would be redundant.

```lua
-- Show detailed email information in floating window
function M.show_email_details_window(id)
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  local item = scheduler.get_scheduled_email(id)
  if not item then return end
  
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  
  -- Header
  table.insert(lines, " Email Details")
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "")
  
  -- Scheduling info
  local time_left = item.scheduled_for - os.time()
  table.insert(lines, string.format(" Status: %s", item.status))
  table.insert(lines, string.format(" Send in: %s", M.format_countdown(time_left)))
  table.insert(lines, string.format(" Send at: %s", 
    os.date("%Y-%m-%d %H:%M:%S", item.scheduled_for)))
  
  if item.modified then
    table.insert(lines, " Status: Rescheduled")
  end
  
  table.insert(lines, "")
  table.insert(lines, " Email Content")
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "")
  
  -- Email details
  table.insert(lines, string.format("From: %s", item.email_data.from or ""))
  table.insert(lines, string.format("To: %s", item.email_data.to or ""))
  if item.email_data.cc then
    table.insert(lines, string.format("Cc: %s", item.email_data.cc))
  end
  if item.email_data.bcc then
    table.insert(lines, string.format("Bcc: %s", item.email_data.bcc))
  end
  table.insert(lines, string.format("Subject: %s", item.email_data.subject or ""))
  table.insert(lines, "")
  table.insert(lines, "Body:")
  table.insert(lines, string.rep("-", 60))
  
  -- Add body content
  local body_lines = vim.split(item.email_data.body or "", "\n")
  for _, line in ipairs(body_lines) do
    table.insert(lines, line)
  end
  
  -- Show in floating window
  local width = 65
  local height = math.min(#lines + 2, 30)
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = '  Email Details ',
    title_pos = 'center'
  })
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<CR>', { silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<CR>', { silent = true })
end
```

## Integration Points

### With Sidebar System
- Extend existing `format_email_list` to include scheduled emails section
- Add countdown timer updates to sidebar refresh logic
- Integrate with existing line metadata system for navigation
- Use telescope pickers for all selection dialogs

### With Preview Mode
- Extend `show_preview` to handle scheduled email type
- Add countdown and scheduling info to preview header
- Ensure preview updates when switching between inbox and scheduled emails

### With Keybinding System  
- Add context-aware actions based on email type (inbox vs scheduled)
- `gD` cancels scheduled emails instead of deleting
- `e` opens reschedule window for scheduled emails only
- `<CR>` preview works seamlessly for both email types

### With Scheduler Module
- Add `get_scheduled_emails()` function to retrieve active scheduled items
- Add `get_scheduled_email(id)` for individual email lookup
- Ensure state changes trigger sidebar updates

## Testing Strategy

### Phase 2 Testing
1. Test sidebar integration with scheduled emails
2. Verify countdown timers update correctly
3. Test telescope picker for all reschedule options
4. Ensure proper cleanup and state management

### Phase 3 Testing
1. Test queue display with 0, 1, 10, 100+ emails
2. Verify category sorting logic
3. Test all keyboard shortcuts
4. Ensure auto-refresh doesn't cause flicker
5. Test concurrent operations

## Performance Considerations

### Memory Management
- Reuse buffers where possible
- Clean up timers when windows close
- Limit queue display to most recent 100 items

### Timer Optimization
- Use single timer for multiple countdown windows
- Batch queue refreshes
- Debounce rapid state changes

## Future Enhancements

### Potential Phase 4 Features
1. **Recurring Schedules**: Send weekly reports, daily summaries
2. **Send Windows**: Only send during business hours
3. **Recipient Time Zones**: Schedule in recipient's local time
4. **Template Scheduling**: Schedule template-based emails
5. **Batch Operations**: Cancel/reschedule multiple emails with telescope multi-select

### Integration Ideas
1. **Calendar Integration**: Show scheduled emails in calendar view
2. **Conflict Detection**: Warn about scheduling during meetings
3. **Smart Suggestions**: Learn optimal send times
4. **Delivery Tracking**: Show when emails were actually delivered

## Conclusion

These enhancements transform the basic scheduling system into a comprehensive email management solution. The sidebar integration provides immediate visibility and control, while telescope pickers maintain UI consistency across all operations. Together, they create a professional-grade email scheduling experience within Neovim that feels native to the existing Himalaya interface.