-- Test script for Himalaya buffer cleanup
-- Run with: nvim --headless -l scripts/test_buffer_cleanup.lua

local ui = require('neotex.plugins.tools.himalaya.ui')
local sidebar = require('neotex.plugins.tools.himalaya.sidebar')

print("Testing Himalaya Buffer Cleanup...")

-- Test 1: Initial buffer state
print("✓ Test 1: Initial buffer state")
local initial_buffers = vim.api.nvim_list_bufs()
print(string.format("Initial buffer count: %d", #initial_buffers))

-- Test 2: Create sidebar buffer
print("✓ Test 2: Create sidebar buffer")
local sidebar_buf = sidebar.create_buffer()
assert(sidebar_buf ~= nil, "Sidebar buffer should be created")
assert(vim.api.nvim_buf_is_valid(sidebar_buf), "Sidebar buffer should be valid")

local filetype = vim.api.nvim_buf_get_option(sidebar_buf, 'filetype')
assert(filetype == 'himalaya-list', "Sidebar buffer should have himalaya-list filetype")
print("✓ Sidebar buffer created with correct filetype")

-- Test 3: Track buffer in UI
print("✓ Test 3: Track buffer in UI")
ui.buffers.email_list = sidebar_buf
assert(ui.buffers.email_list == sidebar_buf, "Buffer should be tracked")
print("✓ Buffer tracked in UI")

-- Test 4: Create additional Himalaya buffers
print("✓ Test 4: Create additional Himalaya buffers")
local email_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_option(email_buf, 'filetype', 'himalaya-email')
ui.buffers.email_read = email_buf

local compose_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_option(compose_buf, 'filetype', 'himalaya-compose')
ui.buffers.email_compose = compose_buf

print("✓ Created additional test buffers")

-- Test 5: Debug buffer state before cleanup
print("✓ Test 5: Buffer state before cleanup")
ui.debug_buffers()

-- Test 6: Close Himalaya and cleanup buffers
print("✓ Test 6: Close Himalaya and cleanup")
ui.close_himalaya()

-- Test 7: Verify buffers are cleaned up
print("✓ Test 7: Verify cleanup")
for name, buf in pairs(ui.buffers) do
  assert(buf == nil, string.format("Buffer %s should be nil after cleanup", name))
end

-- Test 8: Check for remaining Himalaya buffers
print("✓ Test 8: Check for remaining Himalaya buffers")
local remaining_himalaya_buffers = {}
local all_buffers = vim.api.nvim_list_bufs()
for _, buf in ipairs(all_buffers) do
  if vim.api.nvim_buf_is_valid(buf) then
    local ok, ft = pcall(vim.api.nvim_buf_get_option, buf, 'filetype')
    if ok and ft and ft:match('^himalaya%-') then
      table.insert(remaining_himalaya_buffers, {buf = buf, filetype = ft})
    end
  end
end

assert(#remaining_himalaya_buffers == 0, 
  string.format("Should have no remaining Himalaya buffers, found %d", #remaining_himalaya_buffers))
print("✓ No remaining Himalaya buffers found")

-- Test 9: Test sidebar cleanup function specifically
print("✓ Test 9: Test sidebar cleanup function")
local test_buf = sidebar.create_buffer()
sidebar.close_and_cleanup()
assert(not vim.api.nvim_buf_is_valid(test_buf), "Sidebar buffer should be deleted after cleanup")
print("✓ Sidebar cleanup function works correctly")

-- Test 10: Final buffer count check
print("✓ Test 10: Final buffer count check")
local final_buffers = vim.api.nvim_list_bufs()
local valid_final_buffers = 0
for _, buf in ipairs(final_buffers) do
  if vim.api.nvim_buf_is_valid(buf) then
    valid_final_buffers = valid_final_buffers + 1
  end
end

print(string.format("Final valid buffer count: %d", valid_final_buffers))
-- We should have no more Himalaya buffers lingering

print("\nAll buffer cleanup tests passed! ✅")
print("Buffer cleanup improvements implemented:")
print("- Sidebar buffer properly deleted on close")
print("- All tracked Himalaya buffers cleaned up")
print("- Scanned and removed any remaining Himalaya buffers by filetype")
print("- Added debug function for buffer state inspection")
print("- Added :HimalayaClose command for explicit cleanup")
print("- Buffer cleanup should prevent 'No file name for buffer' errors")