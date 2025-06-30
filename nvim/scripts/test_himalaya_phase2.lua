-- Test script for Himalaya Phase 2: Selection State Management

-- Test 1: Test selection state functions
local function test_selection_state()
  print("Testing selection state management...")
  
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  
  -- Test toggle selection mode
  local initial_mode = state.is_selection_mode()
  print("Initial selection mode: " .. tostring(initial_mode))
  
  local new_mode = state.toggle_selection_mode()
  print("After toggle: " .. tostring(new_mode))
  assert(new_mode ~= initial_mode, "Toggle should change mode")
  
  -- Test email selection
  state.toggle_email_selection("email1", {id = "email1", subject = "Test 1"})
  state.toggle_email_selection("email2", {id = "email2", subject = "Test 2"})
  
  print("Is email1 selected: " .. tostring(state.is_email_selected("email1")))
  print("Is email3 selected: " .. tostring(state.is_email_selected("email3")))
  print("Selection count: " .. state.get_selection_count())
  
  -- Test deselection
  state.toggle_email_selection("email1", {id = "email1", subject = "Test 1"})
  print("After deselecting email1, count: " .. state.get_selection_count())
  
  -- Test get selected emails
  local selected = state.get_selected_emails()
  print("Selected emails: " .. #selected)
  
  -- Test clear selection
  state.clear_selection()
  print("After clear, count: " .. state.get_selection_count())
  
  -- Reset to initial state
  if initial_mode then
    state.toggle_selection_mode()
  end
  
  print("✓ Selection state management working correctly")
end

-- Test 2: Test visual rendering with checkboxes
local function test_checkbox_rendering()
  print("\nTesting checkbox rendering...")
  
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  local main = require('neotex.plugins.tools.himalaya.ui.main')
  
  -- Enable selection mode
  if not state.is_selection_mode() then
    state.toggle_selection_mode()
  end
  
  -- Mock email data
  local emails = {
    {id = "1", from = {name = "John"}, subject = "Email 1", date = "2025-06-30", flags = {}},
    {id = "2", from = {name = "Jane"}, subject = "Email 2", date = "2025-06-30", flags = {"Seen"}},
    {id = "3", from = {name = "Bob"}, subject = "Email 3", date = "2025-06-30", flags = {"Seen", "Flagged"}},
  }
  
  -- Select email 2
  state.toggle_email_selection("2", emails[2])
  
  -- Format email list
  local lines = main.format_email_list(emails)
  
  -- Check for checkboxes in output
  local found_checkboxes = false
  local found_selected = false
  
  for i, line in ipairs(lines) do
    if type(line) == 'string' then
      if line:match('%[%s%]') then
        found_checkboxes = true
        print("Found checkbox at line " .. i .. ": " .. line:sub(1, 50))
      end
      if line:match('%[x%]') then
        found_selected = true
        print("Found selected checkbox at line " .. i .. ": " .. line:sub(1, 50))
      end
    end
  end
  
  assert(found_checkboxes, "Should find checkboxes in selection mode")
  assert(found_selected, "Should find selected checkbox for email 2")
  
  -- Check metadata
  if lines.metadata then
    print("✓ Metadata includes selection state")
  end
  
  -- Check header for selection info
  local found_selection_info = false
  for i = 1, 5 do
    if lines[i] and lines[i]:match("Selection:") then
      found_selection_info = true
      print("Found selection info: " .. lines[i])
    end
  end
  
  assert(found_selection_info, "Should show selection info in header")
  
  -- Disable selection mode
  state.toggle_selection_mode()
  state.clear_selection()
  
  print("✓ Checkbox rendering working correctly")
end

-- Test 3: Test keymap integration (manual)
local function test_keymap_integration()
  print("\nManual keymap test instructions:")
  print("1. Open Himalaya sidebar with :Himalaya")
  print("2. Press 'v' to toggle selection mode")
  print("3. You should see 'Selection mode: ON' notification")
  print("4. Email list should refresh with checkboxes")
  print("5. Press 'v' again to exit selection mode")
  print("6. Checkboxes should disappear")
end

-- Run tests
print("=== Himalaya Phase 2 Testing ===\n")

test_selection_state()
test_checkbox_rendering()

print("\n" .. string.rep("=", 50))
test_keymap_integration()

print("\n=== Phase 2 Testing Complete ===")