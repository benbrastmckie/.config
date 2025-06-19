-- Test script for Himalaya state management
-- Run with: nvim --headless -l scripts/test_state.lua

local state = require('neotex.plugins.tools.himalaya.state')

print("Testing Himalaya State Management...")

-- Test 1: Initial state
local initial_state = state.get_state()
assert(initial_state.current_folder == 'INBOX', "Default folder should be INBOX")
assert(initial_state.sidebar_width == 50, "Default sidebar width should be 50")
print("✓ Initial state test passed")

-- Test 2: Setting and getting values
state.set_current_account('test@example.com')
assert(state.get_current_account() == 'test@example.com', "Current account should be set")

state.set_current_folder('Sent')
assert(state.get_current_folder() == 'Sent', "Current folder should be set")

state.set_selected_email('email123')
assert(state.get_selected_email() == 'email123', "Selected email should be set")

state.set_sidebar_width(60)
assert(state.get_sidebar_width() == 60, "Sidebar width should be updated")

assert(state.set_sidebar_position('right'), "Setting sidebar position should succeed")
assert(state.get_sidebar_position() == 'right', "Sidebar position should be right")

print("✓ State setting/getting test passed")

-- Test 3: Search state
state.set_last_query('test query')
assert(state.get_last_query() == 'test query', "Last query should be set")

local test_results = {
  {id = '1', subject = 'Test Email'},
  {id = '2', subject = 'Another Test'}
}
state.set_search_results(test_results)
local retrieved_results = state.get_search_results()
assert(#retrieved_results == 2, "Search results should have 2 items")
assert(retrieved_results[1].subject == 'Test Email', "First result should match")

print("✓ Search state test passed")

-- Test 4: Window positions
state.set_window_position('email123', {row = 10, col = 20})
local position = state.get_window_position('email123')
assert(position.row == 10, "Window row position should be saved")
assert(position.col == 20, "Window col position should be saved")

print("✓ Window position test passed")

-- Test 5: Save and load state
local save_success = state.save()
assert(save_success, "State save should succeed")

-- Reset state and reload
state.reset()
assert(state.get_current_account() == nil, "State should be reset")

local load_success = state.load()
assert(load_success, "State load should succeed")
assert(state.get_current_account() == 'test@example.com', "Loaded account should match saved")
assert(state.get_current_folder() == 'Sent', "Loaded folder should match saved")

print("✓ Save/load state test passed")

-- Test 6: Session age calculation
-- Set a timestamp from 1 hour ago
local one_hour_ago = os.time() - 3600
state.state.session_timestamp = one_hour_ago
local age = state.get_session_age()
assert(age >= 60 and age <= 61, "Session age should be approximately 60 minutes")

-- Test fresh state (should be false for 1-hour-old state)
assert(state.is_state_fresh(), "1-hour-old state should still be considered fresh")

print("✓ Session age test passed")

-- Test 7: State export/import
local exported_state = state.export_state()
assert(type(exported_state) == 'table', "Exported state should be a table")
assert(exported_state.current_account == 'test@example.com', "Exported state should contain current data")

-- Test import
local new_state = {current_folder = 'Archive', sidebar_width = 70}
assert(state.import_state(new_state), "State import should succeed")
assert(state.get_current_folder() == 'Archive', "Imported folder should be set")
assert(state.get_sidebar_width() == 70, "Imported width should be set")

print("✓ State export/import test passed")

-- Test 8: Init function (should not error)
state.init()
print("✓ State initialization test passed")

-- Test 9: Clear functions
state.clear_window_positions()
assert(next(state.state.window_positions) == nil, "Window positions should be cleared")

print("✓ Clear functions test passed")

-- Cleanup: reset state to defaults
state.reset()

print("\nAll state management tests passed! ✅")
print("Phase 3 state persistence implementation is ready.")