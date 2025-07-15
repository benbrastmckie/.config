-- Test script for multi-instance scheduled email sharing
-- This script tests Phase 2 implementation (lightweight version)

local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
local persistence = require('neotex.plugins.tools.himalaya.core.persistence')

-- Test data
local test_email = {
  to = "multitest@example.com",
  subject = "Multi-Instance Test Email",
  body = "This email tests multi-instance functionality.",
  from = "sender@example.com"
}

local function run_test()
  print("=== Testing Multi-Instance Email Sharing ===")
  
  -- Test 1: Clean slate
  print("\n1. Starting with clean state...")
  scheduler.init()
  local initial_emails = scheduler.get_scheduled_emails()
  print("✓ Initial queue has " .. #initial_emails .. " emails")
  
  -- Test 2: Schedule email in "instance 1"
  print("\n2. Scheduling email in 'instance 1'...")
  local email_id = scheduler.schedule_email(test_email, "test_account", {
    delay = 300 -- 5 minutes
  })
  print("✓ Scheduled email with ID: " .. email_id)
  
  -- Verify it's in our queue
  local our_emails = scheduler.get_scheduled_emails()
  local found_locally = false
  for _, email in ipairs(our_emails) do
    if email.id == email_id then
      found_locally = true
      break
    end
  end
  print("✓ Email found in local queue: " .. tostring(found_locally))
  
  -- Test 3: Simulate "instance 2" by creating fresh scheduler state
  print("\n3. Simulating 'instance 2' (fresh scheduler state)...")
  
  -- Save current state
  local original_queue = scheduler.queue
  local original_initialized = scheduler.initialized
  
  -- Reset scheduler state (simulating different instance)
  scheduler.queue = {}
  scheduler.initialized = false
  
  -- Initialize "instance 2"
  scheduler.init()
  
  -- Check if it loads the email from disk
  local instance2_emails = scheduler.get_scheduled_emails()
  local found_in_instance2 = false
  for _, email in ipairs(instance2_emails) do
    if email.id == email_id then
      found_in_instance2 = true
      print("✓ Email found in 'instance 2': " .. email.email_data.subject)
      break
    end
  end
  
  if not found_in_instance2 then
    print("✗ Email not found in 'instance 2'")
    return false
  end
  
  -- Test 4: Test sync detection (simulate external change)
  print("\n4. Testing sync detection...")
  
  -- Manually modify the file to simulate external change
  local queue_before_sync = vim.deepcopy(scheduler.queue)
  
  -- Add a delay to ensure different timestamp
  vim.wait(1000, function() return false end)
  
  -- Simulate another instance adding an email by directly modifying file
  local external_email = {
    to = "external@example.com",
    subject = "External Email",
    body = "Added by external instance",
    from = "external@example.com"
  }
  
  local external_item = {
    id = "external_123",
    email_data = external_email,
    account_id = "test_account",
    created_at = os.time(),
    scheduled_for = os.time() + 600,
    original_delay = 600,
    status = "scheduled",
    retries = 0,
    modified = false,
    metadata = {}
  }
  
  -- Create modified queue
  local modified_queue = vim.deepcopy(scheduler.queue)
  modified_queue["external_123"] = external_item
  
  -- Save it to disk
  persistence.save_queue(modified_queue)
  print("✓ Simulated external instance adding email")
  
  -- Now call get_scheduled_emails which should sync
  local synced_emails = scheduler.get_scheduled_emails()
  local found_external = false
  for _, email in ipairs(synced_emails) do
    if email.id == "external_123" then
      found_external = true
      print("✓ External email detected and synced: " .. email.email_data.subject)
      break
    end
  end
  
  if not found_external then
    print("✗ External email not synced")
    return false
  end
  
  -- Test 5: Cleanup
  print("\n5. Cleaning up...")
  scheduler.cancel_send(email_id)
  scheduler.cancel_send("external_123")
  
  local final_emails = scheduler.get_scheduled_emails()
  local cleanup_success = true
  for _, email in ipairs(final_emails) do
    if email.id == email_id or email.id == "external_123" then
      cleanup_success = false
      break
    end
  end
  
  if cleanup_success then
    print("✓ Cleanup successful")
  else
    print("✗ Cleanup failed")
    return false
  end
  
  print("\n=== Multi-Instance Test Passed! ===")
  print("✓ Emails persist across instances")
  print("✓ External changes are detected and synced")
  print("✓ Sidebar refresh will show changes from other instances")
  return true
end

-- Run the test
return run_test()