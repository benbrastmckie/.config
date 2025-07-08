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
  
  -- Save original state
  local original_queue = vim.deepcopy(scheduler.queue)
  
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
  
  -- Clean up - cancel the scheduled email
  scheduler.cancel_send(result.id)
  
  -- Restore original queue state
  scheduler.queue = original_queue
end))

-- Test scheduling with custom time
table.insert(tests, framework.create_test('schedule_email_custom_time', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Save original state
  local original_queue = vim.deepcopy(scheduler.queue)
  
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
  
  -- Clean up
  scheduler.cancel_send(result.id)
  scheduler.queue = original_queue
end))

-- Test cancel scheduled email
table.insert(tests, framework.create_test('cancel_scheduled_email', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Save original state
  local original_queue = vim.deepcopy(scheduler.queue)
  
  -- Schedule email
  local email = helpers.create_test_email()
  local result = scheduler.schedule_email(email, 300)
  assert.truthy(result.success)
  
  -- Cancel it using the correct function name
  local cancel_result = scheduler.cancel_send(result.id)
  assert.truthy(cancel_result, "Cancel should succeed")
  
  -- Verify it's gone
  local queue = scheduler.get_scheduled_emails()
  for _, item in ipairs(queue) do
    assert.falsy(item.id == result.id, "Cancelled email should not be in queue")
  end
  
  -- Restore original state
  scheduler.queue = original_queue
end))

-- Test edit scheduled email
table.insert(tests, framework.create_test('edit_scheduled_email', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Save original state
  local original_queue = vim.deepcopy(scheduler.queue)
  
  -- Schedule email
  local email = helpers.create_test_email()
  local result = scheduler.schedule_email(email, 300)
  assert.truthy(result.success)
  
  -- Edit it
  local new_time = os.time() + 600
  local edit_result = scheduler.edit_scheduled_send_time(result.id, new_time)
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
  
  -- Clean up
  scheduler.cancel_send(result.id)
  scheduler.queue = original_queue
end))

-- Test scheduler persistence
table.insert(tests, framework.create_test('scheduler_persistence', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
  
  -- Save original state
  local original_queue = vim.deepcopy(scheduler.queue)
  
  -- Create test emails (but don't actually schedule them)
  local test_queue = {}
  for i = 1, 3 do
    local email = helpers.create_test_email({ subject = "Persistent " .. i })
    local id = "test-" .. os.time() .. "-" .. i
    test_queue[id] = {
      id = id,
      email = email,
      send_time = os.time() + 300 + i * 60,
      attempts = 0
    }
  end
  
  -- Test persistence functions directly
  -- Save test queue
  local save_result = persistence.save_queue(test_queue)
  assert.truthy(save_result, "Save should succeed")
  
  -- Load queue
  local loaded_queue = persistence.load_queue()
  assert.truthy(loaded_queue, "Load should succeed")
  
  -- Verify all test emails are in loaded queue
  for id, _ in pairs(test_queue) do
    assert.truthy(loaded_queue[id], "Email " .. id .. " should be persisted")
  end
  
  -- Clean up - restore original state
  persistence.save_queue(original_queue)
  scheduler.queue = original_queue
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Scheduler Feature', tests)

return _G.himalaya_test