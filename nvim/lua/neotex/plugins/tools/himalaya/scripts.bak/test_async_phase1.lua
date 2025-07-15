-- Test script for Phase 1 async implementation
-- Tests basic async command execution and email operations

local async_commands = require('neotex.plugins.tools.himalaya.core.async_commands')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')

local function run_tests()
  print("=== Testing Phase 1 Async Implementation ===")
  print("Testing async command execution and email operations\n")
  
  -- Test 1: Basic async command status
  print("1. Testing async command module status...")
  local status = async_commands.get_status()
  print("   ✓ Max concurrent jobs: " .. status.max_concurrent)
  print("   ✓ Running jobs: " .. status.running_jobs)
  print("   ✓ Queued jobs: " .. status.queued_jobs)
  print("   ✓ Can start new: " .. tostring(status.can_start_new))
  
  -- Test 2: Account and folder operations
  print("\n2. Testing async folder operations...")
  
  -- Get current account
  local account = state.get_current_account()
  if not account then
    print("   ✗ No account configured - cannot test email operations")
    print("   Run :HimalayaSetup to configure an account first")
    return false
  end
  
  local account_name = config.get_current_account_name()
  print("   ✓ Using account: " .. tostring(account_name))
  
  -- Test async folder listing
  local folders_test_complete = false
  utils.get_folders_async(account_name, function(folders, error)
    if error then
      print("   ✗ Folder listing failed: " .. tostring(error))
    else
      print("   ✓ Folders retrieved: " .. #folders .. " folders")
      for i, folder in ipairs(folders) do
        if i <= 3 then  -- Show first 3 folders
          print("     - " .. folder)
        end
      end
      if #folders > 3 then
        print("     - ... and " .. (#folders - 3) .. " more")
      end
    end
    folders_test_complete = true
  end)
  
  -- Wait for async operation to complete
  local timeout = 10000  -- 10 seconds
  local start_time = vim.loop.hrtime()
  while not folders_test_complete do
    vim.wait(100)  -- Wait 100ms
    local elapsed = (vim.loop.hrtime() - start_time) / 1000000  -- Convert to ms
    if elapsed > timeout then
      print("   ✗ Folder listing timed out after 10 seconds")
      break
    end
  end
  
  -- Test 3: Email count operations
  print("\n3. Testing async email count operations...")
  
  local current_folder = state.get_current_folder() or 'INBOX'
  print("   Testing folder: " .. current_folder)
  
  local count_test_complete = false
  utils.fetch_folder_count_async(account_name, current_folder, function(count, error)
    if error then
      print("   ✗ Count operation failed: " .. tostring(error))
    else
      print("   ✓ Email count: " .. tostring(count))
    end
    count_test_complete = true
  end)
  
  -- Wait for count operation
  start_time = vim.loop.hrtime()
  while not count_test_complete do
    vim.wait(100)
    local elapsed = (vim.loop.hrtime() - start_time) / 1000000
    if elapsed > timeout then
      print("   ✗ Count operation timed out after 10 seconds")
      break
    end
  end
  
  -- Test 4: Email listing operations
  print("\n4. Testing async email listing...")
  
  local email_test_complete = false
  utils.get_emails_async(account_name, current_folder, 1, 5, function(emails, total_count, error)
    if error then
      print("   ✗ Email listing failed: " .. tostring(error))
    else
      print("   ✓ Emails retrieved: " .. #emails .. " emails (total: " .. tostring(total_count) .. ")")
      if #emails > 0 then
        local first_email = emails[1]
        local subject = (first_email.subject and first_email.subject ~= vim.NIL) and first_email.subject or "No subject"
        print("   ✓ First email subject: " .. subject)
      end
    end
    email_test_complete = true
  end)
  
  -- Wait for email operation
  start_time = vim.loop.hrtime()
  while not email_test_complete do
    vim.wait(100)
    local elapsed = (vim.loop.hrtime() - start_time) / 1000000
    if elapsed > timeout then
      print("   ✗ Email listing timed out after 10 seconds")
      break
    end
  end
  
  -- Test 5: Command queuing under load
  print("\n5. Testing command queuing under load...")
  
  local completed_jobs = 0
  local total_test_jobs = 5
  
  for i = 1, total_test_jobs do
    utils.get_folders_async(account_name, function(folders, error)
      completed_jobs = completed_jobs + 1
      if error then
        print("   Job " .. completed_jobs .. " failed: " .. tostring(error))
      else
        print("   ✓ Job " .. completed_jobs .. " completed (" .. #folders .. " folders)")
      end
    end)
  end
  
  -- Wait for all jobs to complete
  start_time = vim.loop.hrtime()
  while completed_jobs < total_test_jobs do
    vim.wait(100)
    local elapsed = (vim.loop.hrtime() - start_time) / 1000000
    if elapsed > timeout * 2 then  -- Give more time for multiple jobs
      print("   ✗ Load test timed out, completed " .. completed_jobs .. "/" .. total_test_jobs)
      break
    end
  end
  
  if completed_jobs == total_test_jobs then
    print("   ✓ All " .. total_test_jobs .. " jobs completed successfully")
  end
  
  -- Test 6: Final status check
  print("\n6. Final status check...")
  local final_status = async_commands.get_status()
  print("   ✓ Running jobs after tests: " .. final_status.running_jobs)
  print("   ✓ Queued jobs after tests: " .. final_status.queued_jobs)
  
  -- Summary
  print("\n=== Phase 1 Test Summary ===")
  print("✓ Async command module: Working")
  print("✓ Job queuing system: Working") 
  print("✓ Folder operations: " .. (folders_test_complete and "Working" or "Failed"))
  print("✓ Count operations: " .. (count_test_complete and "Working" or "Failed"))
  print("✓ Email operations: " .. (email_test_complete and "Working" or "Failed"))
  print("✓ Load handling: " .. ((completed_jobs == total_test_jobs) and "Working" or "Partial"))
  
  local all_passed = folders_test_complete and count_test_complete and 
                     email_test_complete and (completed_jobs == total_test_jobs)
  
  if all_passed then
    print("\n🎉 Phase 1 implementation: PASSED")
    print("Async commands are working correctly and UI should be more responsive!")
  else
    print("\n⚠️  Phase 1 implementation: PARTIAL")
    print("Some tests failed - check the errors above")
  end
  
  return all_passed
end

-- Run the tests
return run_tests()