-- Test script for Himalaya Phase 3: Selection Interaction

-- Test 1: Test space bar selection interaction
local function test_space_selection()
  print("Testing space bar selection...")
  
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  local main = require('neotex.plugins.tools.himalaya.ui.main')
  
  -- Clear any existing state
  state.clear_selection()
  if state.is_selection_mode() then
    state.toggle_selection_mode()
  end
  
  -- Enable selection mode
  state.toggle_selection_mode()
  print("Selection mode enabled: " .. tostring(state.is_selection_mode()))
  
  -- Mock some emails
  local emails = {
    {id = "email1", from = {name = "Alice"}, subject = "Test 1", date = "2025-06-30", flags = {}},
    {id = "email2", from = {name = "Bob"}, subject = "Test 2", date = "2025-06-30", flags = {"Seen"}},
    {id = "email3", from = {name = "Charlie"}, subject = "Test 3", date = "2025-06-30", flags = {"Seen", "Flagged"}},
  }
  
  -- Test selection
  state.toggle_email_selection("email1", emails[1])
  state.toggle_email_selection("email3", emails[3])
  
  print("Selected count: " .. state.get_selection_count())
  print("Email1 selected: " .. tostring(state.is_email_selected("email1")))
  print("Email2 selected: " .. tostring(state.is_email_selected("email2")))
  print("Email3 selected: " .. tostring(state.is_email_selected("email3")))
  
  -- Format and check output
  local lines = main.format_email_list(emails)
  
  -- Count checkboxes
  local selected_count = 0
  local unselected_count = 0
  
  for i, line in ipairs(lines) do
    if type(line) == 'string' then
      if line:match('%[x%]') then
        selected_count = selected_count + 1
      elseif line:match('%[%s%]') then
        unselected_count = unselected_count + 1
      end
    end
  end
  
  print("Found " .. selected_count .. " selected checkboxes")
  print("Found " .. unselected_count .. " unselected checkboxes")
  
  assert(selected_count == 2, "Should have 2 selected emails")
  assert(unselected_count == 1, "Should have 1 unselected email")
  
  -- Cleanup
  state.toggle_selection_mode()
  state.clear_selection()
  
  print("✓ Space selection logic working correctly")
end

-- Test 2: Test visual feedback
local function test_visual_feedback()
  print("\nTesting visual feedback...")
  
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  
  -- Enable selection mode
  if not state.is_selection_mode() then
    state.toggle_selection_mode()
  end
  
  -- Create mock metadata with selection info
  local metadata = {
    [7] = {seen = false, starred = false, selected = false},
    [8] = {seen = true, starred = false, selected = true},
    [9] = {seen = true, starred = true, selected = false},
    [10] = {seen = false, starred = false, selected = true},
  }
  
  -- Test that highlighting function handles selection state
  local success = pcall(function()
    sidebar.apply_email_highlighting(metadata)
  end)
  
  assert(success, "apply_email_highlighting should handle selection metadata")
  
  print("✓ Visual feedback functions updated correctly")
  
  -- Cleanup
  state.toggle_selection_mode()
  state.clear_selection()
end

-- Test 3: Manual interaction test
local function test_manual_interaction()
  print("\nManual interaction test instructions:")
  print("1. Open Himalaya with :Himalaya")
  print("2. Press 'v' to enter selection mode")
  print("3. Use j/k to move to different emails")
  print("4. Press Space to toggle selection on current email")
  print("5. Watch for:")
  print("   - Checkbox changes from [ ] to [x]")
  print("   - Selection count notification updates")
  print("   - Selected lines get highlighted background")
  print("   - Green checkbox color for selected items")
  print("6. Press 'v' again to exit selection mode")
end

-- Run tests
print("=== Himalaya Phase 3 Testing ===\n")

test_space_selection()
test_visual_feedback()

print("\n" .. string.rep("=", 50))
test_manual_interaction()

print("\n=== Phase 3 Testing Complete ===")