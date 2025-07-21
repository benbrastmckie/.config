-- Unit tests for data/scheduler.lua module  
-- Tests email scheduling with delays and retry handling

local M = {}

-- Test metadata
M.test_metadata = {
  name = "Email Scheduler Tests",
  description = "Tests for email scheduling and delayed sending",
  count = 10,
  category = "unit",
  tags = {"scheduler", "async", "timing"},
  estimated_duration_ms = 1000
}

-- Load test framework
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"
local framework = require("neotex.plugins.tools.himalaya.test.utils.test_framework")
local test = framework.test
local assert = framework.assert

-- Module under test
local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")

-- Mock dependencies
local utils = require("neotex.plugins.tools.himalaya.utils")
local persistence = require("neotex.plugins.tools.himalaya.core.persistence")

-- Test setup
local function setup()
  -- Reset scheduler state BEFORE mocking
  scheduler.queue = {}
  scheduler.running = false
  scheduler.initialized = false
  scheduler.timer = nil
  
  -- Clear module cache to ensure clean state
  package.loaded['neotex.plugins.tools.himalaya.core.persistence'] = nil
  local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
  
  -- Mock persistence to avoid disk I/O
  persistence.save_queue = function() return true end
  persistence.load_queue = function() return {} end
  persistence.cleanup_expired_emails = function(queue) return queue end
  
  -- Mock utils.send_email
  utils.send_email = function(account, email_data)
    -- Track calls for testing
    utils._last_send = {
      account = account,
      email_data = email_data
    }
    return true
  end
  
  -- Initialize scheduler with clean state
  scheduler.init()
  
  -- Double-check queue is empty after init
  scheduler.queue = {}
end

local function teardown()
  -- Stop any running timers
  scheduler.stop_processing()
  
  -- Clear state
  scheduler.queue = {}
  scheduler.initialized = false
end

-- Test suite
M.tests = {
  test_schedule_email = function()
    setup()
    
    local email_data = {
      from = "test@example.com",
      to = "recipient@example.com",
      subject = "Test Email",
      body = "Test body"
    }
    
    -- Schedule email with correct API (email_data, account_id, options)
    local scheduled_id = scheduler.schedule_email(email_data, "test-account", {})
    assert.equals(type(scheduled_id), "string", "Should return scheduled ID")
    
    -- Check email is in queue
    local scheduled = scheduler.queue[scheduled_id]
    assert.is_table(scheduled, "Email should be in queue")
    assert.equals(scheduled.account_id, "test-account", "Account should match")
    assert.equals(scheduled.email_data.subject, "Test Email", "Subject should match")
    
    teardown()
  end,
  
  test_schedule_with_custom_delay = function()
    setup()
    
    local email_data = { subject = "Custom Delay" }
    local delay = 120 -- 2 minutes
    
    -- Use correct API with options table
    local scheduled_id = scheduler.schedule_email(email_data, "test", { delay = delay })
    
    local scheduled = scheduler.queue[scheduled_id]
    local expected_time = os.time() + delay
    
    -- Allow 1 second tolerance
    assert.truthy(math.abs(scheduled.scheduled_for - expected_time) <= 1, 
                   "Scheduled time should be ~120 seconds from now")
    
    teardown()
  end,
  
  test_cancel_send = function()
    setup()
    
    local email_data = { subject = "To Cancel" }
    local id = scheduler.schedule_email(email_data, "test", {})
    
    -- Use correct function name
    local success = scheduler.cancel_send(id)
    assert.truthy(success, "Cancel should succeed")
    
    -- Check it's marked as cancelled (not removed)
    assert.equals(scheduler.queue[id].status, "cancelled", "Status should be cancelled")
    
    teardown()
  end,
  
  test_get_scheduled_emails = function()
    setup()
    
    -- Schedule multiple emails
    scheduler.schedule_email({ subject = "Email 1" }, "test", {})
    scheduler.schedule_email({ subject = "Email 2" }, "test", {})
    scheduler.schedule_email({ subject = "Email 3" }, "other", {})
    
    -- Get all scheduled (no function to filter by account)
    local count = 0
    for _, item in pairs(scheduler.queue) do
      if item.status == "scheduled" then
        count = count + 1
      end
    end
    assert.equals(count, 3, "Should have 3 scheduled emails")
    
    teardown()
  end,
  
  test_pause_and_resume = function()
    setup()
    
    local id = scheduler.schedule_email({ subject = "Pausable" }, "test", {})
    
    -- Use correct function names
    local success = scheduler.pause_email(id)
    assert.truthy(success, "Pause should succeed")
    assert.equals(scheduler.queue[id].status, "paused", "Status should be paused")
    
    -- Resume
    success = scheduler.resume_email(id)
    assert.truthy(success, "Resume should succeed")
    assert.equals(scheduler.queue[id].status, "scheduled", "Status should be scheduled")
    
    teardown()
  end,
  
  test_reschedule_email = function()
    setup()
    
    local id = scheduler.schedule_email({ subject = "Reschedule" }, "test", {})
    local original_time = scheduler.queue[id].scheduled_for
    
    -- Reschedule to specific time (5 minutes from now)
    local new_time = os.time() + 300
    local success = scheduler.reschedule_email(id, new_time)
    assert.truthy(success, "Reschedule should succeed")
    
    assert.equals(scheduler.queue[id].scheduled_for, new_time, "Should be rescheduled to new time")
    
    teardown()
  end,
  
  test_format_countdown = function()
    -- Test various time formats - scheduler uses MM:SS format
    assert.equals(scheduler.format_countdown(30), " 00:30", "Should format seconds")
    assert.equals(scheduler.format_countdown(90), " 01:30", "Should format minutes and seconds")
    assert.equals(scheduler.format_countdown(3661), "  1:01", "Should format hours and minutes")
    assert.equals(scheduler.format_countdown(0), " SENDING", "Should show SENDING for 0")
  end,
  
  test_format_duration = function()
    -- Test duration formatting
    assert.equals(scheduler.format_duration(30), "30 seconds", "Should format seconds")
    assert.equals(scheduler.format_duration(90), "2 minutes", "Should format minutes")
    assert.equals(scheduler.format_duration(3600), "1 hour", "Should format hour")
  end,
  
  test_immediate_send_blocked = function()
    setup()
    
    -- Try to schedule with 0 delay
    local id = scheduler.schedule_email({ subject = "Immediate" }, "test", { delay = 0 })
    
    -- Should still have minimum delay
    local scheduled = scheduler.queue[id]
    local delay = scheduled.scheduled_for - os.time()
    assert.truthy(delay >= scheduler.config.min_delay, "Should enforce minimum delay")
    
    teardown()
  end
}

-- Run all tests
function M.run()
  local test_results = {
    name = "test_scheduler",
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
  }
  
  for test_name, test_fn in pairs(M.tests) do
    test_results.total = test_results.total + 1
    
    -- Set test mode
    _G.HIMALAYA_TEST_MODE = true
    
    local ok, err = pcall(test_fn)
    
    if ok then
      test_results.passed = test_results.passed + 1
      -- Suppress print output when run from test runner
      if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
        print("✓ " .. test_name)
      end
    else
      test_results.failed = test_results.failed + 1
      table.insert(test_results.errors, {
        test = test_name,
        error = tostring(err)
      })
      -- Suppress print output when run from test runner
      if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
        print("✗ " .. test_name .. ": " .. tostring(err))
      end
    end
  end
  
  -- Print summary only when not run from test runner
  if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
    print(string.format("\n%s: %d/%d tests passed (%.1f%%)",
      test_results.name,
      test_results.passed,
      test_results.total,
      (test_results.passed / test_results.total) * 100
    ))
  end
  
  return test_results
end

-- Execute if running directly
if vim.fn.expand('%:t') == 'test_scheduler.lua' then
  M.run()
end

-- Add standardized interface

return M