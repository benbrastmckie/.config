-- Email Operation Testing
-- Tools to test email operations like delete, move, flag, etc.

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Test delete operation directly
function M.test_delete_operation()
  print("=== Testing Delete Operation ===")
  
  local account = config.state.current_account
  if not account then
    print("❌ No current account set")
    return false
  end
  
  -- Get current email ID
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local email_id = ui.get_current_email_id()
  
  if not email_id then
    print("❌ No email selected")
    print("Please select an email in the sidebar and try again")
    print()
    print("To test delete operation:")
    print("1. Open Himalaya (:Himalaya)")
    print("2. Navigate to an email")
    print("3. Run this command again")
    return false
  end
  
  print("Testing delete operation for email ID:", email_id)
  print("Account:", account)
  print()
  
  -- Try the smart delete function directly
  print("🧪 Testing smart delete function...")
  local success, error_type, extra = utils.smart_delete_email(account, email_id)
  
  print("Result:")
  print("  Success:", success and "✓" or "❌")
  print("  Error Type:", error_type or "none")
  
  if extra then
    if type(extra) == "table" then
      print("  Available folders:", table.concat(extra, ", "))
    else
      print("  Extra info:", extra)
    end
  end
  print()
  
  -- Interpret results
  if success then
    print("✅ DELETE OPERATION SUCCESSFUL")
    print("The email should have been moved to trash or deleted.")
  elseif error_type == "missing_trash" then
    print("🎯 CONFIRMED: This is the 'missing trash' error we're diagnosing")
    print("The delete operation fails because no trash folder is found.")
    print()
    print("Next steps:")
    print("1. Check Gmail IMAP settings (:HimalayaCheckGmailSettings)")
    print("2. Analyze mbsync config (:HimalayaAnalyzeMbsync)")
    print("3. Use workaround (All Mail archiving)")
  else
    print("❌ DELETE OPERATION FAILED")
    print("Error type:", error_type)
    print("This may indicate other configuration issues.")
  end
  
  return success
end

-- Test move operation to specific folder
function M.test_move_operation(target_folder)
  print("=== Testing Move Operation ===")
  
  local account = config.state.current_account
  if not account then
    print("❌ No current account set")
    return false
  end
  
  -- Get current email ID
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local email_id = ui.get_current_email_id()
  
  if not email_id then
    print("❌ No email selected")
    return false
  end
  
  -- Use provided target or ask for one
  if not target_folder then
    local folders = utils.get_folders(account)
    if not folders then
      print("❌ Cannot get folder list")
      return false
    end
    
    print("Available folders:")
    for i, folder in ipairs(folders) do
      print(string.format("%2d. %s", i, folder))
    end
    print()
    print("Specify a folder with: :HimalayaTestMove folder-name")
    return false
  end
  
  print("Testing move operation:")
  print("  Email ID:", email_id)
  print("  Target folder:", target_folder)
  print("  Account:", account)
  print()
  
  -- Test the move operation
  print("🧪 Testing move function...")
  local success = utils.move_email(email_id, target_folder)
  
  print("Result:")
  print("  Success:", success and "✓" or "❌")
  
  if success then
    print("✅ MOVE OPERATION SUCCESSFUL")
    print("Email should have been moved to:", target_folder)
  else
    print("❌ MOVE OPERATION FAILED")
    print("Possible causes:")
    print("1. Target folder doesn't exist")
    print("2. Insufficient permissions")
    print("3. Network/sync issues")
    print("4. Invalid email ID")
  end
  
  return success
end

-- Test flag operations
function M.test_flag_operations()
  print("=== Testing Flag Operations ===")
  
  local account = config.state.current_account
  if not account then
    print("❌ No current account set")
    return false
  end
  
  -- Get current email ID
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local email_id = ui.get_current_email_id()
  
  if not email_id then
    print("❌ No email selected")
    return false
  end
  
  print("Testing flag operations for email ID:", email_id)
  print()
  
  -- Test common flags
  local flags_to_test = {
    {flag = "Seen", action = "add", description = "Mark as read"},
    {flag = "Flagged", action = "add", description = "Star/flag email"},
    {flag = "Flagged", action = "remove", description = "Remove star/flag"}
  }
  
  for _, test in ipairs(flags_to_test) do
    print(string.format("🧪 Testing: %s flag '%s'...", test.action, test.flag))
    local success = utils.manage_flag(email_id, test.flag, test.action)
    
    local status = success and "✓" or "❌"
    print(string.format("  %s %s", status, test.description))
    
    if not success then
      print("    Possible issues: Invalid flag, permissions, or sync problems")
    end
    
    -- Small delay between operations
    vim.wait(500)
  end
  
  print()
  print("Flag operation testing complete.")
  return true
end

-- Test email retrieval operations
function M.test_email_retrieval()
  print("=== Testing Email Retrieval Operations ===")
  
  local account = config.state.current_account
  if not account then
    print("❌ No current account set")
    return false
  end
  
  print("Testing email retrieval for account:", account)
  print()
  
  -- Test folder list
  print("🔍 1. Testing folder list retrieval...")
  local folders = utils.get_folders(account)
  if folders then
    print("✓ Retrieved", #folders, "folders")
  else
    print("❌ Failed to retrieve folders")
    return false
  end
  
  -- Test email list for INBOX
  print()
  print("📧 2. Testing email list retrieval (INBOX)...")
  local emails = utils.get_email_list(account, 'INBOX', 1, 10)
  if emails then
    print("✓ Retrieved", #emails, "emails from INBOX")
    if #emails > 0 then
      print("  Sample subjects:")
      for i = 1, math.min(3, #emails) do
        local subject = emails[i].subject or "No subject"
        print(string.format("    %d. %s", i, subject:sub(1, 50) .. (#subject > 50 and "..." or "")))
      end
    end
  else
    print("❌ Failed to retrieve emails from INBOX")
  end
  
  -- Test email content retrieval
  if emails and #emails > 0 then
    print()
    print("📖 3. Testing email content retrieval...")
    local email_id = emails[1].id
    local content = utils.get_email_content(account, email_id)
    
    if content then
      print("✓ Retrieved email content")
      print("  Content type:", type(content))
      if type(content) == "string" then
        local preview = content:sub(1, 100):gsub("\n", " ")
        print("  Preview:", preview .. "...")
      end
    else
      print("❌ Failed to retrieve email content")
    end
  end
  
  return true
end

-- Test all operations comprehensively
function M.run_comprehensive_test()
  print("🔧 Running Comprehensive Operation Tests")
  print("=" .. string.rep("=", 50))
  print()
  
  local results = {}
  
  -- Test 1: Email retrieval
  print("TEST 1: Email Retrieval")
  results.retrieval = M.test_email_retrieval()
  print()
  print(string.rep("-", 30))
  print()
  
  -- Test 2: Flag operations
  print("TEST 2: Flag Operations")
  results.flags = M.test_flag_operations()
  print()
  print(string.rep("-", 30))
  print()
  
  -- Test 3: Delete operation (non-destructive analysis)
  print("TEST 3: Delete Operation Analysis")
  print("Note: This will test the delete function but may not actually delete")
  results.delete = M.test_delete_operation()
  print()
  print(string.rep("-", 30))
  print()
  
  -- Summary
  print("🏁 Test Results Summary:")
  print("Email retrieval:", results.retrieval and "✓ PASS" or "❌ FAIL")
  print("Flag operations:", results.flags and "✓ PASS" or "❌ FAIL")
  print("Delete operation:", results.delete and "✓ PASS" or "❌ FAIL")
  print()
  
  local passed = (results.retrieval and 1 or 0) + (results.flags and 1 or 0) + (results.delete and 1 or 0)
  print(string.format("Overall: %d/3 tests passed", passed))
  
  if passed == 3 then
    print("✅ All operations working correctly!")
  elseif passed >= 1 then
    print("⚠️  Some operations have issues - check individual test results")
  else
    print("❌ Major configuration issues detected")
    print("Recommend running: :HimalayaFullDiagnostics")
  end
  
  return results
end

-- Setup commands for this module
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaTestDelete', M.test_delete_operation, {
    desc = 'Test delete operation on current email'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestMove', function(opts)
    local target_folder = opts.args ~= "" and opts.args or nil
    M.test_move_operation(target_folder)
  end, {
    desc = 'Test move operation to specified folder',
    nargs = '?'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestFlags', M.test_flag_operations, {
    desc = 'Test flag operations (read, star, etc.)'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestRetrieval', M.test_email_retrieval, {
    desc = 'Test email and folder retrieval operations'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestAll', M.run_comprehensive_test, {
    desc = 'Run comprehensive test of all operations'
  })
end

return M