-- Manual test script for draft recovery functionality
-- Run this to manually verify recovery works

local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local state = require('neotex.plugins.tools.himalaya.core.state')
local storage = require('neotex.plugins.tools.himalaya.core.local_storage')

print("=== Draft Recovery Manual Test ===")

-- Step 1: Create a test draft
print("\n1. Creating test draft...")
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "Subject: Manual Recovery Test",
  "To: test@example.com",
  "",
  "This is a test draft that should be recoverable.",
  "Created at: " .. os.date("%Y-%m-%d %H:%M:%S")
})

local draft = draft_manager.create(buf, 'test_account')
print("   Draft created with ID: " .. draft.local_id)

-- Step 2: Save the draft
print("\n2. Saving draft locally...")
local save_ok = draft_manager.save_local(buf)
print("   Save result: " .. tostring(save_ok))

-- Step 3: Save state
print("\n3. Saving state to disk...")
local state_save_ok = state.save()
print("   State save result: " .. tostring(state_save_ok))

-- Step 4: Simulate restart
print("\n4. Simulating Neovim restart...")
local draft_id = draft.local_id
print("   Cleaning up buffer...")
vim.api.nvim_buf_delete(buf, { force = true })
print("   Clearing draft manager cache...")
draft_manager.drafts = {}

-- Step 5: Load state
print("\n5. Loading state from disk...")
local state_load_ok = state.load()
print("   State load result: " .. tostring(state_load_ok))

-- Step 6: Check saved drafts
print("\n6. Checking saved draft metadata...")
local saved_drafts = state.get_all_drafts()
local count = 0
for _, d in pairs(saved_drafts) do
  count = count + 1
  print("   Found draft: " .. (d.subject or "Untitled"))
end
print("   Total drafts in state: " .. count)

-- Step 7: Run recovery
print("\n7. Running recovery process...")
local recovered = draft_manager.recover_session()
print("   Recovered drafts: " .. recovered)

-- Step 8: Verify recovery
print("\n8. Verifying recovery...")
local recovered_draft = draft_manager.drafts[draft_id]
if recovered_draft then
  print("   ✓ Draft recovered successfully!")
  print("   Subject: " .. (recovered_draft.metadata.subject or "Untitled"))
  print("   Account: " .. recovered_draft.account)
  print("   Recovered flag: " .. tostring(recovered_draft.recovered))
else
  print("   ✗ Draft not found in cache!")
end

-- Step 9: List recovered drafts
print("\n9. Listing all recovered drafts...")
local recovered_list = draft_manager.get_recovered_drafts()
for i, d in ipairs(recovered_list) do
  print(string.format("   %d. %s (modified: %s)", 
    i, 
    d.subject,
    os.date("%Y-%m-%d %H:%M", d.modified_at or 0)
  ))
end

-- Step 10: Test opening recovered draft
print("\n10. Testing open recovered draft...")
if recovered_draft then
  local new_buf = draft_manager.open_recovered_draft(draft_id)
  if new_buf then
    print("   ✓ Draft opened in buffer: " .. new_buf)
    local lines = vim.api.nvim_buf_get_lines(new_buf, 0, 5, false)
    print("   First line: " .. (lines[1] or ""))
    vim.api.nvim_buf_delete(new_buf, { force = true })
  else
    print("   ✗ Failed to open draft")
  end
end

print("\n=== Test Complete ===")

-- Cleanup
print("\nCleaning up test data...")
if recovered_draft and recovered_draft.local_path then
  storage.delete(draft_id)
end
state.remove_draft(999) -- Remove any test state

print("Done!")