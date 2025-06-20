-- Test file for notification filtering
-- Run with :luafile %

local notifications = require('neotex.plugins.tools.himalaya.notifications')
local config = require('neotex.plugins.tools.himalaya.config')

-- Test function
local function test_notifications()
  print("Testing Himalaya notification filtering...")
  print("Current debug mode:", config.config.debug_mode)
  
  -- Test various notification types
  local test_messages = {
    { msg = "Email deleted successfully", desc = "Important - should always show" },
    { msg = "Email sent successfully", desc = "Important - should always show" },
    { msg = "Error: Failed to connect", desc = "Error - should always show" },
    { msg = "Warning: Large attachment", desc = "Warning - should always show" },
    { msg = "Cached 200 emails for gmail/INBOX", desc = "Debug only - cache operation" },
    { msg = "Fetching emails from Himalaya (cache refresh)", desc = "Debug only - fetch operation" },
    { msg = "Page 1: showing emails 1-30 of 200 total", desc = "Debug only - page load" },
    { msg = "Local trash system initialized at: /path", desc = "Debug only - init operation" },
    { msg = "Himalaya closed (0 buffers cleaned up)", desc = "Debug only - cleanup" },
    { msg = "Email list loaded in sidebar", desc = "Debug only - UI operation" },
  }
  
  print("\nSending test notifications...\n")
  
  for _, test in ipairs(test_messages) do
    print(string.format("Testing: %s", test.desc))
    notifications.notify(test.msg, vim.log.levels.INFO)
    vim.wait(100) -- Small delay to see notifications
  end
  
  print("\nTest complete! Check which notifications appeared.")
  print("Use :HimalayaDebug to toggle debug mode and run again.")
end

-- Run the test
test_notifications()

return {
  test = test_notifications
}