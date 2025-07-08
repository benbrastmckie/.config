-- Test Scheduler Feature for Himalaya Plugin

local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert
local helpers = framework.helpers
local mock = framework.mock

-- Test suite
local tests = {}

-- Test email scheduling
table.insert(tests, framework.create_test('schedule_email_basic', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Create test email
  local email = {
    to = { "test@example.com" },
    subject = "Scheduled Test",
    body = "This is a scheduled email"
  }
  
  -- Schedule email
  local result = scheduler.schedule_email(email, 60)
  
  -- Verify scheduling
  assert.truthy(result.success, "Scheduling should succeed")
  assert.truthy(result.id, "Should return scheduled ID")
  
  -- Check scheduled queue
  local queue = scheduler.get_scheduled_emails()
  assert.truthy(#queue > 0, "Queue should not be empty")
  
  -- Find our email
  local found = false
  for _, item in ipairs(queue) do
    if item.id == result.id then
      found = true
      assert.equals(item.email.subject, "Scheduled Test")
      break
    end
  end
  assert.truthy(found, "Scheduled email should be in queue")
end))

-- Test scheduling with custom time
table.insert(tests, framework.create_test('schedule_email_custom_time', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Schedule for specific time
  local email = helpers.create_test_email()
  local send_time = os.time() + 3600 -- 1 hour from now
  
  local result = scheduler.schedule_email(email, nil, send_time)
  
  assert.truthy(result.success, "Scheduling should succeed")
  
  -- Verify scheduled time
  local queue = scheduler.get_scheduled_emails()
  local scheduled = nil
  for _, item in ipairs(queue) do
    if item.id == result.id then
      scheduled = item
      break
    end
  end
  
  assert.truthy(scheduled, "Email should be scheduled")
  assert.equals(scheduled.send_time, send_time, "Send time should match")
end))

-- Test cancel scheduled email
table.insert(tests, framework.create_test('cancel_scheduled_email', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Schedule email
  local email = helpers.create_test_email()
  local result = scheduler.schedule_email(email, 300)
  assert.truthy(result.success)
  
  -- Cancel it
  local cancel_result = scheduler.cancel_scheduled_email(result.id)
  assert.truthy(cancel_result.success, "Cancel should succeed")
  
  -- Verify it's gone
  local queue = scheduler.get_scheduled_emails()
  for _, item in ipairs(queue) do
    assert.falsy(item.id == result.id, "Cancelled email should not be in queue")
  end
end))

-- Test edit scheduled email
table.insert(tests, framework.create_test('edit_scheduled_email', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Schedule email
  local email = helpers.create_test_email()
  local result = scheduler.schedule_email(email, 300)
  assert.truthy(result.success)
  
  -- Edit it
  local new_time = os.time() + 600
  local edit_result = scheduler.edit_scheduled_time(result.id, new_time)
  assert.truthy(edit_result.success, "Edit should succeed")
  
  -- Verify changes
  local queue = scheduler.get_scheduled_emails()
  local edited = nil
  for _, item in ipairs(queue) do
    if item.id == result.id then
      edited = item
      break
    end
  end
  
  assert.truthy(edited, "Email should still be scheduled")
  assert.equals(edited.send_time, new_time, "Send time should be updated")
end))

-- Test scheduler persistence
table.insert(tests, framework.create_test('scheduler_persistence', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Schedule multiple emails
  local ids = {}
  for i = 1, 3 do
    local email = helpers.create_test_email({ subject = "Persistent " .. i })
    local result = scheduler.schedule_email(email, 300 + i * 60)
    assert.truthy(result.success)
    table.insert(ids, result.id)
  end
  
  -- Save state
  scheduler.save_state()
  
  -- Clear in-memory queue
  scheduler._test_clear_queue()
  
  -- Load state
  scheduler.load_state()
  
  -- Verify all emails are restored
  local queue = scheduler.get_scheduled_emails()
  for _, id in ipairs(ids) do
    local found = false
    for _, item in ipairs(queue) do
      if item.id == id then
        found = true
        break
      end
    end
    assert.truthy(found, "Email " .. id .. " should be restored")
  end
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Scheduler Feature', tests)

return _G.himalaya_test