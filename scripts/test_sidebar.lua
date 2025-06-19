-- Test script for Himalaya sidebar functionality
-- Run with: nvim --headless -l scripts/test_sidebar.lua

local sidebar = require('neotex.plugins.tools.himalaya.sidebar')

print("Testing Himalaya Sidebar...")

-- Test 1: Initial state
assert(not sidebar.is_open(), "Sidebar should be closed initially")
print("✓ Initial state test passed")

-- Test 2: Configuration
assert(sidebar.get_width() == 50, "Default width should be 50")
print("✓ Configuration test passed")

-- Test 3: Width setting
sidebar.set_width(60)
assert(sidebar.get_width() == 60, "Width should be updated to 60")
print("✓ Width setting test passed")

-- Test 4: Buffer creation (headless mode)
local buf = sidebar.create_buffer()
assert(buf ~= nil, "Buffer should be created")
print("✓ Buffer creation test passed")

-- Test 5: Update content
local test_lines = {"Line 1", "Line 2", "Line 3"}
local success = sidebar.update_content(test_lines)
assert(success, "Content update should succeed")
print("✓ Content update test passed")

-- Test 6: Init function (should not error)
sidebar.init()
print("✓ Initialization test passed")

-- Test 7: Position setting
sidebar.set_position('right')
print("✓ Position setting test passed")

-- Reset to left for consistency
sidebar.set_position('left')

-- Test 8: Current window check (should be false in headless)
assert(not sidebar.is_current_window(), "Should not be current window in headless mode")
print("✓ Current window test passed")

print("\nAll sidebar tests passed! ✅")
print("Phase 2 sidebar implementation is ready.")