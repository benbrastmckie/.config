-- Test Draft Saving Functionality
-- This script tests the complete draft saving workflow

local M = {}

local function test_save_draft_function()
  print("=== Testing save_draft function directly ===")
  
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  local test_email = {
    from = 'test@example.com',
    to = 'recipient@example.com',
    subject = 'Test Draft from Script',
    body = 'This is a test draft created by the test script.'
  }
  
  local result, err = utils.save_draft('gmail', 'Drafts', test_email)
  
  if result then
    print("✅ save_draft function works - Draft ID:", result.id)
    return result.id
  else
    print("❌ save_draft function failed:", err)
    return nil
  end
end

local function test_find_draft_folder()
  print("=== Testing find_draft_folder function ===")
  
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local folder = utils.find_draft_folder('gmail')
  
  print("Draft folder for gmail:", folder)
  return folder
end

local function test_composer_autosave()
  print("=== Testing composer auto-save ===")
  
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
  
  -- Setup composer
  composer.setup()
  
  -- Create a compose buffer
  local opts = {
    to = "test@example.com",
    subject = "Auto-save Test",
    body = "This tests the auto-save functionality."
  }
  
  local buf = composer.create_compose_buffer(opts)
  print("Created compose buffer:", buf)
  
  -- Mark as modified to trigger autosave
  vim.api.nvim_buf_set_option(buf, 'modified', true)
  
  -- Manually trigger save
  print("Triggering manual save...")
  composer.save_draft(buf)
  
  return buf
end

local function check_drafts_folder()
  print("=== Checking drafts folder ===")
  
  -- Use himalaya CLI to check drafts
  local cmd = 'himalaya envelope list --account gmail --folder "Drafts"'
  local output = vim.fn.system(cmd)
  
  print("Drafts folder contents:")
  print(output)
end

function M.run_all_tests()
  local notify = require('neotex.util.notifications')
  
  -- Enable debug mode
  notify.config.modules.himalaya.debug_mode = true
  
  print("Starting comprehensive draft saving tests...")
  print()
  
  -- Test 1: Draft folder detection
  test_find_draft_folder()
  print()
  
  -- Test 2: Direct save_draft function
  local draft_id = test_save_draft_function()
  print()
  
  -- Test 3: Check drafts folder
  check_drafts_folder()
  print()
  
  -- Test 4: Composer workflow
  test_composer_autosave()
  
  print()
  print("=== Test Summary ===")
  print("All tests completed. Check the output above for any failures.")
  
  return true
end

-- Run tests if called directly
if ... == nil then
  M.run_all_tests()
end

return M