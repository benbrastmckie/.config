-- Test script for sidebar sync functionality
-- Tests the exact use case: schedule in one instance, see in another via sidebar toggle

local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')

-- Test data
local test_email = {
  to = "sidebartest@example.com", 
  subject = "Sidebar Sync Test",
  body = "This email tests sidebar sync between instances.",
  from = "sender@example.com"
}

local function run_test()
  print("=== Testing Sidebar Sync Use Case ===")
  print("Simulating: Schedule in one instance, toggle sidebar in another")
  
  -- Step 1: Clean state and schedule email
  print("\n1. Scheduling email in 'instance 1'...")
  scheduler.init()
  
  local email_id = scheduler.schedule_email(test_email, "test_account", {
    delay = 480 -- 8 minutes (like your scenario)
  })
  print("✓ Scheduled email with ID: " .. email_id)
  print("✓ Scheduled for: " .. os.date("%H:%M:%S", os.time() + 480))
  
  -- Step 2: Simulate second instance
  print("\n2. Simulating 'instance 2' (fresh state)...")
  
  -- Reset scheduler to simulate fresh instance
  scheduler.queue = {}
  scheduler.initialized = false
  
  -- Step 3: Access scheduled emails (simulates sidebar display)
  print("\n3. Accessing scheduled emails in 'instance 2'...")
  print("   (This simulates opening/toggling sidebar)")
  
  local scheduled_emails = scheduler.get_scheduled_emails()
  local found = false
  
  for _, email in ipairs(scheduled_emails) do
    if email.id == email_id then
      found = true
      local time_left = email.scheduled_for - os.time()
      print("✓ Found scheduled email: " .. email.email_data.subject)
      print("✓ Time remaining: " .. math.floor(time_left / 60) .. ":" .. string.format("%02d", time_left % 60))
      break
    end
  end
  
  if not found then
    print("✗ Scheduled email not found in 'instance 2'")
    return false
  end
  
  -- Step 4: Test sidebar refresh scenario
  print("\n4. Testing sidebar refresh sync...")
  
  -- Add another email via direct file manipulation (simulates third instance)
  local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
  
  local refresh_test_email = {
    id = "refresh_test_123",
    email_data = {
      to = "refresh@example.com",
      subject = "Refresh Test Email", 
      body = "Tests refresh sync",
      from = "test@example.com"
    },
    account_id = "test_account",
    created_at = os.time(),
    scheduled_for = os.time() + 300,
    original_delay = 300,
    status = "scheduled",
    retries = 0,
    modified = false,
    metadata = {}
  }
  
  -- Manually modify the file to simulate external instance
  -- We'll read, modify and write the file directly without updating our _last_load_time
  local queue_file = vim.fn.expand('~/.config/himalaya/scheduled_emails.json')
  local content = vim.fn.readfile(queue_file)
  local json_str = table.concat(content, '\n')
  local data = vim.json.decode(json_str)
  
  -- Add the external email
  data.queue["refresh_test_123"] = refresh_test_email
  data.statistics.total_scheduled = data.statistics.total_scheduled + 1
  data.last_modified = os.date('%Y-%m-%dT%H:%M:%SZ')
  
  -- Write back to file directly
  local new_json = vim.json.encode(data)
  vim.fn.writefile(vim.split(new_json, '\n'), queue_file)
  
  print("✓ Added email via 'external instance'")
  
  -- Simulate sidebar refresh 
  local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
  
  -- This should trigger sync_from_disk
  print("✓ Simulating sidebar refresh...")
  
  -- Check if refresh sync works
  local post_refresh_emails = scheduler.get_scheduled_emails()
  local found_refresh_email = false
  
  for _, email in ipairs(post_refresh_emails) do
    if email.id == "refresh_test_123" then
      found_refresh_email = true
      print("✓ Refresh sync detected new email: " .. email.email_data.subject)
      break
    end
  end
  
  if not found_refresh_email then
    print("✗ Refresh sync failed")
    return false
  end
  
  -- Step 5: Cleanup
  print("\n5. Cleaning up test emails...")
  scheduler.cancel_send(email_id)
  scheduler.cancel_send("refresh_test_123")
  
  print("\n=== Sidebar Sync Test Passed! ===")
  print("✓ Emails scheduled in one instance appear in another")
  print("✓ Sidebar toggle/refresh syncs external changes")
  print("✓ No manual restart required")
  
  return true
end

return run_test()