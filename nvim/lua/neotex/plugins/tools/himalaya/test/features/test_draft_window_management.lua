-- Test for Draft Window Management Integration (Phase 6)
-- Tests window stack integration with draft windows

local Test = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local config = require('neotex.plugins.tools.himalaya.core.config')

local M = {}

-- Helper to enable window stack integration
local function enable_window_stack()
  local cfg = config.get()
  if not cfg.draft then cfg.draft = {} end
  if not cfg.draft.integration then cfg.draft.integration = {} end
  cfg.draft.integration.use_window_stack = true
end

-- Helper to disable window stack integration
local function disable_window_stack()
  local cfg = config.get()
  if cfg.draft and cfg.draft.integration then
    cfg.draft.integration.use_window_stack = false
  end
end

-- Test suite definition
M.tests = {
  {
    name = "Window Stack - Draft-specific Functions",
    fn = function()
      -- Clear stack
      window_stack.clear()
      
      -- Test push_draft
      local win_id = 1000
      local draft_id = "test_draft_123"
      local parent_win = 999
      
      local ok = window_stack.push_draft(win_id, draft_id, parent_win)
      Test.assert.truthy(ok, "push_draft should succeed")
      
      -- Test get_draft_window
      local entry = window_stack.get_draft_window(draft_id)
      Test.assert.truthy(entry, "Should find draft window")
      Test.assert.equals(entry.window, win_id, "Window ID should match")
      Test.assert.equals(entry.draft_id, draft_id, "Draft ID should match")
      Test.assert.equals(entry.type, 'draft', "Type should be draft")
      
      -- Test has_draft_window
      Test.assert.truthy(window_stack.has_draft_window(draft_id), 
        "Should have draft window")
      Test.assert.falsy(window_stack.has_draft_window("non_existent"), 
        "Should not have non-existent draft")
      
      -- Test get_draft_windows
      local draft_windows = window_stack.get_draft_windows()
      Test.assert.equals(#draft_windows, 1, "Should have one draft window")
      Test.assert.equals(draft_windows[1].draft_id, draft_id, 
        "Draft ID should match in list")
      
      return true
    end
  },
  
  {
    name = "Window Stack - Multiple Draft Windows",
    fn = function()
      -- Clear stack
      window_stack.clear()
      
      -- Add multiple draft windows
      window_stack.push_draft(1001, "draft_1", 1000)
      window_stack.push_draft(1002, "draft_2", 1001)
      window_stack.push_draft(1003, "draft_3", 1002)
      
      -- Add a non-draft window
      window_stack.push(1004, 1003)
      
      -- Test get_draft_windows
      local draft_windows = window_stack.get_draft_windows()
      Test.assert.equals(#draft_windows, 3, "Should have three draft windows")
      
      -- Verify all draft IDs
      local draft_ids = {}
      for _, entry in ipairs(draft_windows) do
        draft_ids[entry.draft_id] = true
      end
      
      Test.assert.truthy(draft_ids["draft_1"], "Should have draft_1")
      Test.assert.truthy(draft_ids["draft_2"], "Should have draft_2")
      Test.assert.truthy(draft_ids["draft_3"], "Should have draft_3")
      
      -- Test total stack depth
      Test.assert.equals(window_stack.depth(), 4, "Total stack should have 4 windows")
      
      return true
    end
  },
  
  {
    name = "Window Stack - Close All Drafts",
    fn = function()
      -- Clear stack
      window_stack.clear()
      
      -- Add mixed windows
      window_stack.push(1000, nil) -- Generic window
      window_stack.push_draft(1001, "draft_1", 1000)
      window_stack.push(1002, 1001) -- Generic window
      window_stack.push_draft(1003, "draft_2", 1002)
      window_stack.push_draft(1004, "draft_3", 1003)
      
      Test.assert.equals(window_stack.depth(), 5, "Should have 5 windows total")
      
      -- Close all drafts
      local closed = window_stack.close_all_drafts()
      -- Note: In test environment, windows aren't valid, so nothing is actually closed
      
      -- Check remaining windows
      local remaining = window_stack.depth()
      Test.assert.equals(remaining, 2, "Should have 2 non-draft windows remaining")
      
      -- Verify no draft windows remain
      local draft_windows = window_stack.get_draft_windows()
      Test.assert.equals(#draft_windows, 0, "Should have no draft windows")
      
      return true
    end
  },
  
  {
    name = "Email Composer - Window Stack Integration",
    fn = function()
      -- Enable window stack integration
      enable_window_stack()
      
      -- Clear stack
      window_stack.clear()
      
      -- Note: In headless mode, we can't actually create windows,
      -- but we can verify the integration is set up
      
      -- Check that configuration is enabled
      local cfg = config.get()
      Test.assert.truthy(cfg.draft.integration.use_window_stack, 
        "Window stack integration should be enabled")
      
      -- The actual window creation would happen in create_compose_buffer
      -- which we can't fully test in headless mode
      
      return true
    end
  },
  
  {
    name = "Window Stack - Debug Output",
    fn = function()
      -- Clear stack
      window_stack.clear()
      
      -- Add various windows
      window_stack.push(1000, nil)
      window_stack.push_draft(1001, "test_draft", 1000)
      window_stack.push(1002, 1001)
      
      -- Capture debug output
      local original_print = print
      local output = {}
      print = function(msg)
        table.insert(output, msg)
      end
      
      -- Call debug
      window_stack.debug()
      
      -- Restore print
      print = original_print
      
      -- Verify output
      Test.assert.truthy(#output > 0, "Debug should produce output")
      Test.assert.truthy(output[1]:match("Window Stack"), "Should show stack header")
      
      -- Look for draft info in output
      local found_draft = false
      for _, line in ipairs(output) do
        if line:match("draft%[test_draft%]") then
          found_draft = true
          break
        end
      end
      Test.assert.truthy(found_draft, "Debug output should show draft info")
      
      return true
    end
  },
  
  {
    name = "Configuration - Window Stack Setting",
    fn = function()
      -- Test default configuration
      local defaults = config.defaults
      Test.assert.truthy(defaults.draft, "Draft config should exist")
      Test.assert.truthy(defaults.draft.integration, "Integration config should exist")
      Test.assert.equals(defaults.draft.integration.use_window_stack, true, 
        "Window stack should be enabled by default")
      
      -- Test disabling
      disable_window_stack()
      local cfg = config.get()
      Test.assert.equals(cfg.draft.integration.use_window_stack, false, 
        "Should be able to disable window stack")
      
      -- Re-enable for other tests
      enable_window_stack()
      
      return true
    end
  },
  
  {
    name = "Window Stack - Parent-Child Relationships",
    fn = function()
      -- Clear stack
      window_stack.clear()
      
      -- Create a hierarchy
      local main_win = 1000
      local draft1_win = 1001
      local draft2_win = 1002
      local preview_win = 1003
      
      -- Main window -> Draft 1
      window_stack.push_draft(draft1_win, "draft_1", main_win)
      
      -- Draft 1 -> Draft 2
      window_stack.push_draft(draft2_win, "draft_2", draft1_win)
      
      -- Draft 2 -> Preview (non-draft)
      window_stack.push(preview_win, draft2_win)
      
      -- Verify relationships
      local draft1 = window_stack.get_draft_window("draft_1")
      Test.assert.equals(draft1.parent, main_win, "Draft 1 parent should be main")
      
      local draft2 = window_stack.get_draft_window("draft_2")
      Test.assert.equals(draft2.parent, draft1_win, "Draft 2 parent should be draft 1")
      
      local preview = window_stack.peek()
      Test.assert.equals(preview.parent, draft2_win, "Preview parent should be draft 2")
      Test.assert.equals(preview.type, 'generic', "Preview should be generic type")
      
      return true
    end
  }
}

-- Create test instances
local tests = {}
for _, test_def in ipairs(M.tests) do
  table.insert(tests, Test.create_test(test_def.name, test_def.fn))
end

-- Export test suite
_G.draft_window_management_test = Test.create_suite('Draft Window Management', tests)

return _G.draft_window_management_test