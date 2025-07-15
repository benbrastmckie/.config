-- Simple test to verify draft notifications are working
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local notify = require('neotex.util.notifications')

-- Test 1: Create draft
print("\n=== Test 1: Create Draft ===")
local buf = vim.api.nvim_create_buf(false, true)
local draft = draft_manager.create(buf, 'test_account', { subject = 'Test Draft' })
print("Draft created with ID:", draft.local_id)

-- Test 2: Save draft
print("\n=== Test 2: Save Draft ===")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "Subject: Test Draft",
  "",
  "This is a test"
})
local ok = draft_manager.save(buf)
print("Save result:", ok)

-- Test 3: Sync draft
print("\n=== Test 3: Sync Draft ===")
local sync_ok = draft_manager.sync_remote(buf)
print("Sync queued:", sync_ok)

-- Test 4: Delete draft
print("\n=== Test 4: Delete Draft ===")
local del_ok = draft_manager.delete(buf)
print("Delete result:", del_ok)

-- Test 5: Try operation on non-draft buffer
print("\n=== Test 5: Non-Draft Buffer ===")
local empty_buf = vim.api.nvim_create_buf(false, true)
local save_fail = draft_manager.save(empty_buf)
print("Save non-draft result:", save_fail)
vim.api.nvim_buf_delete(empty_buf, { force = true })

print("\n=== Tests Complete ===")
print("Check if notifications were displayed correctly")