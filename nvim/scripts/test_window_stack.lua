-- Test script for Himalaya window stack functionality
-- Run with: nvim --headless -l scripts/test_window_stack.lua

local window_stack = require('neotex.plugins.tools.himalaya.window_stack')

print("Testing Himalaya Window Stack...")

-- Test 1: Initial state
assert(window_stack.depth() == 0, "Initial stack should be empty")
print("✓ Initial state test passed")

-- Test 2: Push window (simulate with dummy data since we're headless)
local dummy_win = 1001
local dummy_parent = 1000
window_stack.push(dummy_win, dummy_parent)
assert(window_stack.depth() == 1, "Stack should have 1 item after push")
print("✓ Push test passed")

-- Test 3: Contains check
assert(window_stack.contains(dummy_win), "Stack should contain pushed window")
print("✓ Contains test passed")

-- Test 4: Peek functionality
local top = window_stack.peek()
assert(top.window == dummy_win, "Peek should return top window")
assert(top.parent == dummy_parent, "Peek should return correct parent")
print("✓ Peek test passed")

-- Test 5: Clear functionality
window_stack.clear()
assert(window_stack.depth() == 0, "Stack should be empty after clear")
print("✓ Clear test passed")

-- Test 6: Multiple windows
window_stack.push(1001, 1000)
window_stack.push(1002, 1001)
window_stack.push(1003, 1002)
assert(window_stack.depth() == 3, "Stack should have 3 items")
print("✓ Multiple windows test passed")

-- Test 7: Debug output (should not crash)
window_stack.debug()
print("✓ Debug output test passed")

print("\nAll window stack tests passed! ✅")
print("Phase 1 implementation is ready.")