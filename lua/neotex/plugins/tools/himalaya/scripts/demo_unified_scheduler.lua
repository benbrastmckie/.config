#!/usr/bin/env nvim -l

-- Himalaya Phase 9 Demo Script - Unified Email Scheduling System
-- Demonstrates the integration of undo send with full scheduling capabilities

local himalaya_path = vim.fn.expand('~/.config/nvim/lua/neotex/plugins/tools/himalaya')
package.path = package.path .. ';' .. himalaya_path .. '/?.lua'

-- Mock vim environment
_G.vim = _G.vim or {
  fn = {
    expand = function(path) 
      if path:match('^~') then
        return os.getenv('HOME') .. path:sub(2)
      end
      return path
    end,
    tempname = function() return '/tmp/himalaya_' .. os.time() end,
    readfile = function() return {} end,
    mkdir = function() return true end,
    delete = function() return true end,
    json_encode = function(t) return require('neotex.util.json').encode(t) end,
    json_decode = function(s) return require('neotex.util.json').decode(s) end,
  },
  api = {
    nvim_echo = function(msg, _, _) print(msg[1][1]) end,
    nvim_create_buf = function() return 1 end,
    nvim_buf_is_valid = function() return true end,
    nvim_buf_set_lines = function() end,
    nvim_buf_get_lines = function() return {} end,
    nvim_win_is_valid = function() return false end,
    nvim_win_close = function() end,
    nvim_open_win = function() return 1 end,
    nvim_exec_autocmds = function() end,
    nvim_get_current_win = function() return 1 end,
    nvim_win_set_buf = function() end,
    nvim_buf_set_name = function() end,
    nvim_buf_set_option = function() end,
    nvim_buf_call = function(_, fn) fn() end,
    nvim_buf_set_keymap = function() end,
    nvim_create_autocmd = function() end,
  },
  log = {
    levels = { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 },
  },
  lsp = { log_levels = { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 } },
  loop = {
    new_timer = function() 
      return { 
        start = function() end, 
        stop = function() end 
      } 
    end,
    timer_start = function() end,
    timer_stop = function() end,
  },
  o = { columns = 100, lines = 40 },
  cmd = function() end,
  defer_fn = function(fn) fn() end,
  schedule_wrap = function(fn) return fn end,
  deepcopy = function(t) 
    local copy = {}
    for k, v in pairs(t) do
      if type(v) == 'table' then
        copy[k] = vim.deepcopy(v)
      else
        copy[k] = v
      end
    end
    return copy
  end,
  tbl_extend = function(mode, ...)
    local result = {}
    for _, tbl in ipairs({...}) do
      for k, v in pairs(tbl) do
        result[k] = v
      end
    end
    return result
  end,
  tbl_count = function(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
  end,
  tbl_keys = function(t)
    local keys = {}
    for k in pairs(t) do
      table.insert(keys, k)
    end
    return keys
  end,
  ui = {
    select = function(items, opts, callback)
      print("\nSelect " .. (opts.prompt or "item") .. ":")
      for i, item in ipairs(items) do
        local formatted = item
        if opts.format_item then
          formatted = opts.format_item(item)
        end
        print(string.format("  %d. %s", i, formatted))
      end
      -- Simulate selection
      callback(items[1], 1)
    end,
    input = function(opts, callback)
      print("\nInput " .. (opts.prompt or "value") .. ":")
      callback(opts.default or "test input")
    end,
  },
}

-- Create mock directories
os.execute('mkdir -p /tmp/himalaya/logs')
os.execute('mkdir -p /tmp/himalaya/state')

print("=" .. string.rep("=", 59))
print("Himalaya Phase 9: Unified Email Scheduling System Demo")
print("=" .. string.rep("=", 59))
print("\nThis demo showcases the integration of undo send with full")
print("scheduling capabilities, where ALL emails go through the")
print("scheduler with a minimum 60-second safety delay.")

-- Demo helper functions
local function section(title)
  print("\n" .. string.rep("-", 60))
  print(title)
  print(string.rep("-", 60))
end

local function demo_feature(name, fn)
  print("\n🔸 " .. name)
  local ok, err = pcall(fn)
  if ok then
    print("   ✅ Success")
  else
    print("   ❌ Error: " .. tostring(err))
  end
end

-- 1. Unified Scheduler Demo (Enhanced Send Queue)
section("1. UNIFIED EMAIL SCHEDULER (ENHANCED SEND QUEUE)")

demo_feature("Initialize unified scheduler", function()
  -- Note: In the real implementation, send_queue.lua would be renamed to scheduler.lua
  local scheduler = require('neotex.plugins.tools.himalaya.core.send_queue')
  scheduler.init()
  
  -- Show enhanced configuration
  print("   Default delay: " .. scheduler.config.delay_seconds .. "s (safety delay)")
  print("   Min delay: 5s (prevents accidental immediate send)")
  print("   Check interval: " .. scheduler.config.check_interval .. "s")
  
  local status = scheduler.get_status()
  print("   Scheduler initialized: " .. tostring(status.initialized))
  print("   Timer running: " .. tostring(status.timer_running))
end)

demo_feature("Schedule email with default 60s delay", function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.send_queue')
  
  local email = {
    to = "user@example.com",
    subject = "Default safety delay (60s)",
    body = "This email demonstrates the default 60-second safety delay."
  }
  
  -- Using existing queue_email which defaults to 60s
  local id = scheduler.queue_email(email, "personal")
  print("   Email scheduled with ID: " .. id)
  print("   Send time: in 60 seconds (default safety delay)")
  print("   Status: Shows undo notification window")
end)

demo_feature("Schedule email for 5 minutes", function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.send_queue')
  
  local email = {
    to = "team@example.com",
    subject = "Team update - scheduled send",
    body = "This email is scheduled to send in 5 minutes."
  }
  
  -- Using delay_override parameter (300 seconds = 5 minutes)
  local id = scheduler.queue_email(email, "personal", 300)
  print("   Email scheduled with ID: " .. id)
  print("   Send time: in 5 minutes")
  print("   Status: Shows scheduled notification (not countdown)")
end)

demo_feature("Reschedule a pending email", function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.send_queue')
  
  -- First schedule an email
  local email = {
    to = "boss@example.com",
    subject = "Quarterly report",
    body = "Please find attached the Q4 report."
  }
  
  local id = scheduler.queue_email(email, "work", 300) -- 5 minutes
  print("   Initial schedule: 5 minutes")
  
  -- Simulate rescheduling (in real implementation, this would be a new function)
  local item = scheduler.get_item(id)
  if item then
    item.send_at = os.time() + 7200 -- Reschedule to 2 hours
    item.modified = true
    scheduler.save_queue()
    print("   Rescheduled to: 2 hours from now")
    print("   Modified flag: true (user changed time)")
  end
end)

demo_feature("Show queue with categories", function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.send_queue')
  
  -- Add emails with different delays to show categorization
  scheduler.queue_email({to = "immediate@test.com", subject = "Urgent"}, "personal", 60)
  scheduler.queue_email({to = "today@test.com", subject = "Today's task"}, "personal", 3600)
  scheduler.queue_email({to = "tomorrow@test.com", subject = "Tomorrow's meeting"}, "work", 86400)
  
  local stats = scheduler.get_stats()
  print("\n   Queue Categories:")
  print("   ⚡ Sending Soon (< 5 min): Would show emails < 5 minutes")
  print("   📅 Today: Would show emails for today")
  print("   📆 Tomorrow: Would show emails for tomorrow")
  print("   🗓️ Future: Would show emails beyond tomorrow")
  print("   ✅ Completed: " .. (stats.sent + stats.cancelled) .. " emails")
  print("\n   Total in queue: " .. stats.total)
end)

-- 2. Composer Integration Demo
section("2. COMPOSER INTEGRATION WITH UNIFIED SCHEDULER")

demo_feature("New send options in composer", function()
  print("\n   When sending an email, users now see:")
  print("   ⏰ Send in 1 minute (with undo) - default")
  print("   📅 Send in 5 minutes")
  print("   📅 Send in 30 minutes")
  print("   📅 Send in 1 hour")
  print("   📅 Schedule for specific time...")
  print("   ❌ Cancel")
  print("\n   Note: 'Send Now' option has been removed for safety")
end)

demo_feature("Default send behavior", function()
  print("\n   User selects: 'Send in 1 minute (with undo)'")
  print("   - Email is queued with 60-second delay")
  print("   - Undo notification appears with countdown")
  print("   - User can press 'u' to cancel")
  print("   - User can press 'e' to edit send time")
  print("   - User can press 's' to send immediately")
end)

demo_feature("Custom schedule picker", function()
  print("\n   User selects: 'Schedule for specific time...'")
  print("   Quick options appear:")
  print("   - In 5 minutes")
  print("   - In 30 minutes")
  print("   - In 1 hour")
  print("   - In 2 hours")
  print("   - Tomorrow morning (9 AM)")
  print("   - Tomorrow afternoon (2 PM)")
  print("   - Next Monday (9 AM)")
  print("   - Custom time...")
end)

demo_feature("Edit scheduled time", function()
  print("\n   While email is scheduled, user can:")
  print("   1. Open scheduled emails view (:HimalayaSchedule)")
  print("   2. See email in appropriate category")
  print("   3. Press 'e' to edit time")
  print("   4. Enter new time or use quick picker")
  print("   5. Email is rescheduled with notification")
end)

-- 3. Enhanced Notification System Demo
section("3. ENHANCED NOTIFICATION SYSTEM")

demo_feature("Near-term vs scheduled notifications", function()
  print("\n   Near-term emails (≤ 5 minutes):")
  print("   - Show countdown timer")
  print("   - Compact 6-line notification")
  print("   - Focus on quick undo action")
  print("   - Auto-refresh every second")
  
  print("\n   Scheduled emails (> 5 minutes):")
  print("   - Show scheduled date/time")
  print("   - Larger 8-line notification")
  print("   - Full action menu")
  print("   - No auto-refresh needed")
end)

demo_feature("Interactive notification actions", function()
  print("\n   Available actions in notification window:")
  print("   [u] Undo/Cancel - Cancel the scheduled send")
  print("   [e] Edit time   - Modify when email will be sent")
  print("   [s] Send now    - Override schedule and send immediately")
  print("   [d] Details     - View full email content")
  print("   [ESC] Dismiss   - Close notification (email still scheduled)")
end)

demo_feature("Notification state management", function()
  print("\n   Notification behavior:")
  print("   - Persists across window switches")
  print("   - Updates if user modifies schedule")
  print("   - Auto-closes when email is sent")
  print("   - Cleans up on plugin reload")
  print("   - Multiple notifications can coexist")
end)

-- 4. Advanced Queue Management Demo
section("4. ADVANCED QUEUE MANAGEMENT")

demo_feature("Enhanced queue viewer", function()
  print("\n   :HimalayaSchedule shows emails in categories:")
  print("\n   ⚡ Sending Soon (5)")
  print("      📨 Meeting notes - sends in 45s")
  print("      📨 Quick reply - sends in 2m 30s")
  print("\n   📅 Today (3)")
  print("      📨 Project update - sends at 14:30")
  print("      📨 Daily summary - sends at 17:00")
  print("\n   📆 Tomorrow (2)")
  print("      📨 Weekly report - sends at 09:00")
  print("\n   ✅ Completed (10)")
  print("      ✅ Budget proposal - sent at 10:15")
  print("      🚫 Test email - cancelled")
end)

demo_feature("Queue management keymaps", function()
  print("\n   In queue viewer:")
  print("   - Position cursor on any email")
  print("   - Press 'e' to edit scheduled time")
  print("   - Press 'c' to cancel scheduled send")
  print("   - Press 's' to send immediately")
  print("   - Press 'd' to view email details")
  print("   - Press 'r' to refresh queue")
  print("   - Press 'C' to clear completed items")
end)

demo_feature("Batch operations", function()
  print("\n   Future enhancement ideas:")
  print("   - Select multiple emails with visual mode")
  print("   - Reschedule selected emails together")
  print("   - Cancel multiple scheduled sends")
  print("   - Export scheduled emails list")
end)

-- 5. Migration and Compatibility
section("5. MIGRATION AND COMPATIBILITY")

demo_feature("Backward compatibility", function()
  print("\n   Existing commands still work:")
  print("   :HimalayaSendQueue → :HimalayaSchedule")
  print("   :HimalayaUndoSend → :HimalayaScheduleCancel")
  
  print("\n   Existing functions enhanced:")
  print("   - queue_email() now supports delay_override")
  print("   - Send queue continues to work as before")
  print("   - All existing undo functionality preserved")
end)

demo_feature("New commands available", function()
  print("\n   New scheduler commands:")
  print("   :HimalayaSchedule - View all scheduled emails")
  print("   :HimalayaScheduleCancel [id] - Cancel scheduled email")
  print("   :HimalayaScheduleEdit [id] - Edit scheduled time")
  print("   :HimalayaScheduleSendNow [id] - Send immediately")
  
  print("\n   Aliases for compatibility:")
  print("   :HimalayaSendQueue → :HimalayaSchedule")
  print("   :HimalayaUndoSend → :HimalayaScheduleCancel")
end)

demo_feature("Configuration options", function()
  print("\n   Scheduler configuration:")
  print("   default_delay = 60 (safety delay in seconds)")
  print("   min_delay = 5 (minimum allowed delay)")
  print("   allow_immediate = false (disable Send Now)")
  print("   notification_style = 'float' or 'inline'")
  print("   check_interval = 5 (queue check frequency)")
end)

-- Summary
section("UNIFIED SCHEDULING SYSTEM SUMMARY")

print("\n🎯 Key Benefits:")
print("   ✅ ALL emails have safety delay (no accidental sends)")
print("   ✅ Unified system (undo + scheduling in one)")
print("   ✅ Flexible timing (60s to any future date)")
print("   ✅ Interactive notifications with actions")
print("   ✅ Backward compatible with existing code")

print("\n🔧 Implementation Approach:")
print("   1. Enhance existing send_queue.lua → scheduler.lua")
print("   2. Add variable timing to existing queue system")
print("   3. Upgrade notifications with edit/reschedule options")
print("   4. Update composer to remove 'Send Now' option")
print("   5. Maintain all existing undo functionality")

print("\n📊 Timeline:")
print("   Week 1: Core scheduler enhancement (3 days)")
print("   Week 1-2: UI and integration (2 days)")
print("   Testing: 2 days")

print("\n💡 Next Steps:")
print("   1. Rename send_queue.lua to scheduler.lua")
print("   2. Add schedule_email() with flexible timing")
print("   3. Implement reschedule_email() function")
print("   4. Update notification system")
print("   5. Integrate with composer")

print("\n" .. string.rep("=", 60))
print("Unified Email Scheduling System Demo Complete!")
print(string.rep("=", 60))