-- Test script for scheduled email persistence
-- This script tests Phase 1 implementation

local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
local persistence = require('neotex.plugins.tools.himalaya.core.persistence')

-- Test data
local test_email = {
  to = "test@example.com",
  subject = "Test Persistence Email",
  body = "This email tests the persistence functionality.",
  from = "sender@example.com"
}

local function run_test()
  print("=== Testing Scheduled Email Persistence ===")
  
  -- Test 1: Initialize scheduler
  print("\n1. Initializing scheduler...")
  scheduler.init()
  print("✓ Scheduler initialized")
  
  -- Test 2: Check if queue is empty initially or has previous items
  local initial_emails = scheduler.get_scheduled_emails()
  print("✓ Initial queue has " .. #initial_emails .. " emails")
  
  -- Test 3: Schedule a test email
  print("\n2. Scheduling test email...")
  local email_id = scheduler.schedule_email(test_email, "test_account", {
    delay = 120 -- 2 minutes
  })
  print("✓ Scheduled email with ID: " .. email_id)
  
  -- Test 4: Verify email is in queue
  local scheduled_emails = scheduler.get_scheduled_emails()
  local found = false
  for _, email in ipairs(scheduled_emails) do
    if email.id == email_id then
      found = true
      print("✓ Email found in queue: " .. email.email_data.subject)
      print("  Scheduled for: " .. os.date("%Y-%m-%d %H:%M:%S", email.scheduled_for))
      break
    end
  end
  
  if not found then
    print("✗ Email not found in queue")
    return false
  end
  
  -- Test 5: Check file persistence
  print("\n3. Checking file persistence...")
  local health = persistence.health_check()
  print("✓ Queue file exists: " .. tostring(health.queue_file_exists))
  print("✓ Queue file writable: " .. tostring(health.queue_file_writable))
  print("✓ Queue file size: " .. (health.queue_file_size or 0) .. " bytes")
  print("✓ Backup count: " .. health.backup_count)
  
  -- Test 6: Simulate restart by creating new scheduler instance
  print("\n4. Simulating restart...")
  
  -- Clear current instance
  local old_queue = scheduler.queue
  scheduler.queue = {}
  scheduler.initialized = false
  
  -- Re-initialize (should load from disk)
  scheduler.init()
  
  -- Check if email is still there
  local restored_emails = scheduler.get_scheduled_emails()
  local restored = false
  for _, email in ipairs(restored_emails) do
    if email.id == email_id then
      restored = true
      print("✓ Email restored after restart: " .. email.email_data.subject)
      break
    end
  end
  
  if not restored then
    print("✗ Email not restored after restart")
    return false
  end
  
  -- Test 7: Clean up test email
  print("\n5. Cleaning up...")
  scheduler.cancel_send(email_id)
  
  local final_emails = scheduler.get_scheduled_emails()
  local still_there = false
  for _, email in ipairs(final_emails) do
    if email.id == email_id then
      still_there = true
      break
    end
  end
  
  if still_there then
    print("✗ Email still in queue after cancellation")
    return false
  else
    print("✓ Email successfully cancelled and removed")
  end
  
  print("\n=== All tests passed! ===")
  print("Persistence is working correctly.")
  return true
end

-- Run the test
return run_test()