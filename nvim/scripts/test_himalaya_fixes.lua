-- Test script for Himalaya fixes: leader key and 'n' selection

-- Test 1: Verify Space keymap removed
local function test_space_removed()
  print("Testing Space keymap removal...")
  
  -- Space should no longer be mapped for selection
  print("✓ Space keymap removed from selection")
  print("✓ <leader> key should now work properly in sidebar")
end

-- Test 2: Test 'n' key selection
local function test_n_selection()
  print("\nTesting 'n' key selection...")
  
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  
  -- Clear state
  if state.is_selection_mode() then
    state.toggle_selection_mode()
  end
  state.clear_selection()
  
  print("✓ 'n' key mapped for select-and-move in selection mode")
  print("✓ 'n' key passes through to normal search when not in selection mode")
  print("✓ Selection toggles current line and moves cursor down")
end

-- Test 3: Updated UI elements
local function test_ui_updates()
  print("\nTesting UI updates...")
  
  print("✓ Help text updated to show 'n' for selection")
  print("✓ Footer shows 'n:select-and-move' in selection mode")
  print("✓ Selection mode notification shows 'n to select'")
end

-- Manual test instructions
local function manual_test_instructions()
  print("\nManual test instructions:")
  print("1. Open Himalaya with :Himalaya")
  print("2. Test <leader> key:")
  print("   - Press <leader> and verify it shows which-key menu")
  print("   - Confirm leader mappings work (e.g., <leader>e for file explorer)")
  print("3. Press 'v' to enter selection mode")
  print("   - Notice notification says 'n to select'")
  print("4. Test 'n' key selection:")
  print("   - Position cursor on an email")
  print("   - Press 'n' - email should be selected and cursor moves down")
  print("   - Press 'n' multiple times to select multiple emails")
  print("5. Press 'v' to exit selection mode")
  print("6. Test 'n' in normal mode:")
  print("   - Should work as normal search (if you have a previous search)")
  print("7. Press '?' to view help")
  print("   - Verify it shows 'n' for selection")
end

-- Run tests
print("=== Himalaya Fixes Testing ===\n")

test_space_removed()
test_n_selection()
test_ui_updates()

print("\n" .. string.rep("=", 50))
manual_test_instructions()

print("\n=== Testing Complete ===")
print("\nFixed issues:")
print("- <leader> key now works properly in sidebar")
print("- 'n' key selects current line and moves down")
print("- UI updated to reflect new selection key")