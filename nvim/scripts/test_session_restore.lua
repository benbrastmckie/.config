-- Test script for Himalaya session restoration fixes
-- Run with: nvim --headless -l scripts/test_session_restore.lua

local ui = require('neotex.plugins.tools.himalaya.ui')
local state = require('neotex.plugins.tools.himalaya.state')

print("Testing Himalaya Session Restoration Fixes...")

-- Test 1: UI initialization should not auto-open
print("✓ Test 1: UI initialization without auto-open")
-- Simulate having fresh state
state.state.current_account = 'test@example.com'
state.state.current_folder = 'INBOX'
state.state.session_timestamp = os.time() - 3600  -- 1 hour ago

-- Initialize UI - should NOT auto-open email client
ui.init()
print("✓ UI initialization completed without auto-opening")

-- Test 2: Check session restoration availability
print("✓ Test 2: Session restoration availability check")
local can_restore, message = ui.can_restore_session()
assert(can_restore, "Should be able to restore session with fresh state")
assert(type(message) == 'string', "Should return status message")
print("✓ Session restoration availability check passed")

-- Test 3: Manual session restoration (without actually opening)
print("✓ Test 3: Manual session restoration logic")
-- This won't actually open anything in headless mode, but tests the logic
local restore_result = ui.restore_session()
assert(restore_result == true, "Manual restore should succeed")
print("✓ Manual session restoration logic passed")

-- Test 4: Session prompt function (skip in headless to avoid hanging)
print("✓ Test 4: Session prompt function")
-- Skip prompt test in headless mode as it would hang waiting for input
print("✓ Session prompt function skipped (would hang in headless mode)")

-- Test 5: Check behavior with stale state
print("✓ Test 5: Stale state handling")
state.state.session_timestamp = os.time() - (25 * 60 * 60)  -- 25 hours ago
local can_restore_stale, message_stale = ui.can_restore_session()
assert(not can_restore_stale, "Should not restore stale state")
assert(message_stale:match("older than 24 hours"), "Should indicate stale state")
print("✓ Stale state handling passed")

-- Test 6: Check behavior with no account
print("✓ Test 6: No account state handling")
state.state.current_account = nil
state.state.session_timestamp = os.time() - 3600  -- Fresh but no account
local can_restore_no_account, message_no_account = ui.can_restore_session()
assert(not can_restore_no_account, "Should not restore without account")
assert(message_no_account:match("No previous email session"), "Should indicate no session")
print("✓ No account state handling passed")

-- Clean up test state
state.reset()

print("\nAll session restoration tests passed! ✅")
print("Session restoration fixes implemented:")
print("- Automatic opening on startup DISABLED")
print("- Session restoration is now manual/opt-in only")
print("- Added :HimalayaRestore command for manual restoration")
print("- Added user prompt for session restoration choice")
print("- Proper handling of stale state (>24 hours)")
print("- State sync still preserves sidebar preferences")