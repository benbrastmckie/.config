-- Draft System Health Test (Phase 7)
-- Tests the health check system and basic functionality

local Test = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')

local M = {}

-- Test suite definition
M.tests = {
  {
    name = "Draft Health Check - Configuration",
    fn = function()
      -- Test configuration structure
      local cfg = config.config or config.defaults or {}
      
      Test.assert.truthy(cfg, "Config should exist")
      
      -- Check for draft config section
      if cfg.draft then
        Test.assert.truthy(cfg.draft.storage, "Draft storage config should exist")
        Test.assert.truthy(cfg.draft.integration, "Draft integration config should exist")
      end
      
      -- Test configuration validation if available
      local ok, err = pcall(function()
        return config.validate_draft_config and config.validate_draft_config(cfg)
      end)
      
      if config.validate_draft_config then
        Test.assert.truthy(ok, "Configuration validation should pass")
      end
      
      return true
    end
  },
  
  {
    name = "Draft Health Check - State Management",
    fn = function()
      -- Reset state for clean test
      state.reset()
      
      -- Test basic state operations
      Test.assert.equals(state.get_draft_count(), 0, "Initial draft count should be 0")
      
      -- Test state structure
      local draft_state = state.get("draft", {})
      Test.assert.truthy(type(draft_state) == 'table', "Draft state should be a table")
      
      -- Test state helpers exist
      Test.assert.truthy(type(state.get_draft_count) == 'function', "get_draft_count should exist")
      Test.assert.truthy(type(state.get_unsaved_drafts) == 'function', "get_unsaved_drafts should exist")
      Test.assert.truthy(type(state.is_draft_syncing) == 'function', "is_draft_syncing should exist")
      
      return true
    end
  },
  
  {
    name = "Draft Health Check - Module Loading",
    fn = function()
      -- Test that all draft modules can be loaded
      local modules = {
        'neotex.plugins.tools.himalaya.core.draft_manager_v2',
        'neotex.plugins.tools.himalaya.core.events',
        'neotex.plugins.tools.himalaya.ui.window_stack'
      }
      
      for _, module_name in ipairs(modules) do
        local ok, module = pcall(require, module_name)
        Test.assert.truthy(ok, string.format("Should be able to load %s: %s", module_name, module))
        Test.assert.truthy(module, string.format("Module %s should not be nil", module_name))
      end
      
      return true
    end
  },
  
  {
    name = "Draft Health Check - Events System",
    fn = function()
      local events = require('neotex.plugins.tools.himalaya.core.events')
      
      -- Check that draft events are defined
      local draft_events = {
        'DRAFT_CREATED',
        'DRAFT_SAVED',
        'DRAFT_DELETED',
        'DRAFT_SYNCED',
        'DRAFT_SYNC_FAILED'
      }
      
      for _, event_name in ipairs(draft_events) do
        Test.assert.truthy(events[event_name], string.format("Event %s should be defined", event_name))
        Test.assert.truthy(type(events[event_name]) == 'string', string.format("Event %s should be a string", event_name))
      end
      
      return true
    end
  },
  
  {
    name = "Draft Health Check - Storage Directory",
    fn = function()
      -- Test storage directory creation
      local draft_dir = vim.fn.stdpath('data') .. '/himalaya/drafts'
      
      -- Create directory if it doesn't exist
      vim.fn.mkdir(draft_dir, 'p')
      
      Test.assert.truthy(vim.fn.isdirectory(draft_dir) == 1, "Draft directory should exist")
      Test.assert.truthy(vim.fn.filewritable(draft_dir) == 2, "Draft directory should be writable")
      
      -- Clean up
      vim.fn.delete(draft_dir, 'rf')
      
      return true
    end
  },
  
  {
    name = "Draft Health Check - Window Stack Integration",
    fn = function()
      local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
      
      -- Test that draft-specific functions exist
      Test.assert.truthy(type(window_stack.push_draft) == 'function', "push_draft should exist")
      Test.assert.truthy(type(window_stack.get_draft_windows) == 'function', "get_draft_windows should exist")
      Test.assert.truthy(type(window_stack.has_draft_window) == 'function', "has_draft_window should exist")
      Test.assert.truthy(type(window_stack.close_all_drafts) == 'function', "close_all_drafts should exist")
      
      -- Test basic window stack operations (without real windows)
      window_stack.clear()
      local draft_windows = window_stack.get_draft_windows()
      Test.assert.equals(#draft_windows, 0, "Should have no draft windows initially")
      
      return true
    end
  },
  
  {
    name = "Draft Health Check - Performance",
    fn = function()
      -- Test state access performance
      local start_time = vim.loop.hrtime()
      
      for i = 1, 100 do
        state.get_draft_count()
      end
      
      local end_time = vim.loop.hrtime()
      local duration = (end_time - start_time) / 1000000 -- Convert to ms
      
      Test.assert.truthy(duration < 100, string.format("100 state calls should take < 100ms (took %.2fms)", duration))
      
      return true
    end
  },
  
  {
    name = "Draft Health Check - Commands",
    fn = function()
      -- Test that draft commands can be loaded
      local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.core.commands.draft')
      
      if ok then
        Test.assert.truthy(commands, "Draft commands module should load")
        Test.assert.truthy(type(commands.setup) == 'function', "Commands should have setup function")
      end
      
      -- This is optional, so don't fail if it doesn't exist
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
_G.draft_health_test = Test.create_suite('Draft System Health Check', tests)

return _G.draft_health_test