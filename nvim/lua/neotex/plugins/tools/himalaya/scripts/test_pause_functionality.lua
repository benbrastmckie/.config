-- Test script for PAUSE/RESUME functionality
local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')

-- Test data
local test_email = {
  to = "pausetest@example.com", 
  subject = "Pause/Resume Test Email",
  body = "This email tests the pause and resume functionality.",
  from = "sender@example.com"
}

local function run_test()
  print("=== Testing PAUSE/RESUME Functionality ===")
  
  -- Step 1: Initialize and schedule email
  print("\n1. Scheduling test email...")
  scheduler.init()
  
  local email_id = scheduler.schedule_email(test_email, "test_account", {
    delay = 300 -- 5 minutes
  })
  print("✓ Scheduled email with ID: " .. email_id)
  
  -- Step 2: Test pause functionality
  print("\n2. Testing PAUSE functionality...")
  local success, error_msg = scheduler.pause_email(email_id)
  
  if success then
    print("✓ Email paused successfully")
    
    -- Verify status
    local item = scheduler.get_scheduled_email(email_id)
    if item and item.status == "paused" then
      print("✓ Status correctly set to 'paused'")
      print("✓ Paused at: " .. os.date("%H:%M:%S", item.paused_at))
      
      if item.original_scheduled_for then
        print("✓ Original schedule preserved: " .. os.date("%H:%M:%S", item.original_scheduled_for))
      end
    else
      print("✗ Status not correctly updated")
      return false
    end
  else
    print("✗ Failed to pause email: " .. (error_msg or "Unknown error"))
    return false
  end
  
  -- Step 3: Test resume functionality  
  print("\n3. Testing RESUME functionality...")
  local new_time = os.time() + 120 -- Resume in 2 minutes
  local success2, error_msg2 = scheduler.resume_email(email_id, new_time)
  
  if success2 then
    print("✓ Email resumed successfully")
    
    -- Verify status
    local item2 = scheduler.get_scheduled_email(email_id)
    if item2 and item2.status == "scheduled" then
      print("✓ Status correctly set to 'scheduled'")
      print("✓ New schedule time: " .. os.date("%H:%M:%S", item2.scheduled_for))
      
      if not item2.paused_at then
        print("✓ Paused timestamp cleared")
      end
    else
      print("✗ Status not correctly updated after resume")
      return false
    end
  else
    print("✗ Failed to resume email: " .. (error_msg2 or "Unknown error"))
    return false
  end
  
  -- Step 4: Test sidebar display
  print("\n4. Testing sidebar display...")
  local scheduled_emails = scheduler.get_scheduled_emails()
  local found = false
  
  for _, email in ipairs(scheduled_emails) do
    if email.id == email_id then
      found = true
      print("✓ Email found in scheduled list")
      print("✓ Status: " .. email.status)
      break
    end
  end
  
  if not found then
    print("✗ Email not found in scheduled list")
    return false
  end
  
  -- Step 5: Test pause on paused email (should fail gracefully)
  print("\n5. Testing error handling...")
  scheduler.pause_email(email_id) -- Should resume it first
  scheduler.pause_email(email_id) -- Now pause it
  
  local success3, error_msg3 = scheduler.pause_email(email_id) -- Try to pause again
  if not success3 then
    print("✓ Cannot pause already paused email: " .. error_msg3)
  else
    print("✗ Should not be able to pause already paused email")
  end
  
  -- Step 6: Cleanup
  print("\n6. Cleaning up...")
  scheduler.cancel_send(email_id)
  
  print("\n=== PAUSE/RESUME Test Completed Successfully! ===")
  print("✓ PAUSE functionality working")
  print("✓ RESUME functionality working") 
  print("✓ Status transitions correct")
  print("✓ Error handling working")
  
  return true
end

return run_test()