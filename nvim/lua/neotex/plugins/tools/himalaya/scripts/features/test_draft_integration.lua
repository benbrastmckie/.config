-- Integration Test Suite for Draft System (Phase 7)
-- Comprehensive tests for the entire draft system integration

local Test = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local events = require('neotex.plugins.tools.himalaya.core.events')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')

local M = {}

-- Setup test environment
local function setup_test_env()
  -- Reset all state
  state.reset()
  draft_manager.drafts = {}
  window_stack.clear()
  
  -- Setup minimal config
  local cfg = config.config or {}
  if not cfg.draft then cfg.draft = {} end
  if not cfg.draft.storage then cfg.draft.storage = {} end
  if not cfg.draft.integration then cfg.draft.integration = {} end
  
  cfg.draft.storage.base_dir = vim.fn.stdpath('data') .. '/himalaya/drafts'
  cfg.draft.integration.use_window_stack = true
  cfg.draft.integration.emit_events = true
  cfg.draft.integration.use_notifications = true
  
  -- Update config
  config.config = cfg
  
  -- Ensure storage directory exists
  vim.fn.mkdir(cfg.draft.storage.base_dir, 'p')
end

-- Cleanup test environment
local function cleanup_test_env()
  -- Remove test files
  local test_dir = vim.fn.stdpath('data') .. '/himalaya/drafts'
  if vim.fn.isdirectory(test_dir) == 1 then
    vim.fn.delete(test_dir, 'rf')
  end
end

-- Test suite definition
M.tests = {
  {
    name = "Draft System - Full Lifecycle Integration",
    fn = function()
      setup_test_env()
      
      -- Test event tracking
      local events_received = {}
      
      local event_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
      
      -- Subscribe to draft events
      local event_types = {
        events.DRAFT_CREATED,
        events.DRAFT_SAVED,
        events.DRAFT_SYNCED,
        events.DRAFT_DELETED
      }
      
      for _, event_type in ipairs(event_types) do
        event_bus.on(event_type, function(data)
          events_received[event_type] = (events_received[event_type] or 0) + 1
        end)
      end
      
      -- 1. Create draft
      local draft = draft_manager.create(1000, 'test_account', {
        subject = 'Integration Test',
        to = 'test@example.com'
      })
      
      Test.assert.truthy(draft, "Draft should be created")
      Test.assert.truthy(draft.local_id, "Draft should have local ID")
      
      -- Check state integration
      local state_draft = state.get_draft_by_buffer(1000)
      Test.assert.truthy(state_draft, "Draft should be in state")
      Test.assert.equals(state_draft.local_id, draft.local_id, "State and manager should sync")
      
      -- Check draft count
      Test.assert.equals(state.get_draft_count(), 1, "Draft count should be 1")
      
      -- 2. Save draft
      local ok, err = draft_manager.save_local(1000)
      Test.assert.truthy(ok, "Save should succeed: " .. (err or "no error"))
      
      -- 3. Sync draft (mock successful sync)
      draft.remote_id = "remote_123"
      draft.state = draft_manager.states.SYNCED
      state.set_draft(1000, draft)
      
      -- Emit sync event manually since we're mocking
      event_bus.emit(events.DRAFT_SYNCED, {
        draft_id = draft.local_id,
        remote_id = draft.remote_id
      })
      
      -- 4. Delete draft
      draft_manager.delete(1000)
      
      -- Check final state
      Test.assert.equals(state.get_draft_count(), 0, "Draft count should be 0")
      Test.assert.falsy(state.get_draft_by_buffer(1000), "Draft should be removed from state")
      
      -- Verify events were emitted
      Test.assert.truthy(events_received[events.DRAFT_CREATED], "DRAFT_CREATED should be emitted")
      Test.assert.truthy(events_received[events.DRAFT_SAVED], "DRAFT_SAVED should be emitted")
      Test.assert.truthy(events_received[events.DRAFT_SYNCED], "DRAFT_SYNCED should be emitted")
      Test.assert.truthy(events_received[events.DRAFT_DELETED], "DRAFT_DELETED should be emitted")
      
      cleanup_test_env()
      return true
    end
  },
  
  {
    name = "Draft System - Recovery Integration",
    fn = function()
      setup_test_env()
      
      -- Create and save draft
      local draft = draft_manager.create(2000, 'test_account', {
        subject = 'Recovery Test',
        to = 'recover@example.com'
      })
      
      -- Save to storage
      local ok, err = draft_manager.save_local(2000)
      Test.assert.truthy(ok, "Initial save should succeed")
      
      -- Save state
      state.save()
      
      -- Simulate restart - clear in-memory state
      local original_local_id = draft.local_id
      draft_manager.drafts = {}
      state.reset()
      state.load()
      
      -- Test recovery
      local recovered = draft_manager.recover_session()
      Test.assert.equals(recovered, 1, "Should recover 1 draft")
      
      -- Check recovered draft
      local recovered_draft = draft_manager.get_by_local_id(original_local_id)
      Test.assert.truthy(recovered_draft, "Draft should be recovered")
      Test.assert.equals(recovered_draft.metadata.subject, 'Recovery Test', "Subject should match")
      
      cleanup_test_env()
      return true
    end
  },
  
  {
    name = "Draft System - Window Stack Integration",
    fn = function()
      setup_test_env()
      
      -- Create draft
      local draft = draft_manager.create(3000, 'test_account', {
        subject = 'Window Test'
      })
      
      -- Test window tracking
      local win_id = 1001
      local parent_win = 1000
      
      local ok = window_stack.push_draft(win_id, draft.local_id, parent_win)
      Test.assert.truthy(ok, "Should track draft window")
      
      -- Verify window tracking
      Test.assert.truthy(window_stack.has_draft_window(draft.local_id), 
        "Should find draft window")
      
      local draft_windows = window_stack.get_draft_windows()
      Test.assert.equals(#draft_windows, 1, "Should have 1 draft window")
      Test.assert.equals(draft_windows[1].draft_id, draft.local_id, "Draft ID should match")
      
      -- Test window retrieval
      local window_entry = window_stack.get_draft_window(draft.local_id)
      Test.assert.truthy(window_entry, "Should get draft window")
      Test.assert.equals(window_entry.window, win_id, "Window ID should match")
      Test.assert.equals(window_entry.type, 'draft', "Type should be draft")
      
      cleanup_test_env()
      return true
    end
  },
  
  {
    name = "Draft System - Configuration Integration",
    fn = function()
      setup_test_env()
      
      -- Test configuration validation
      local cfg = config.config
      
      -- Test valid configuration
      local ok, err = pcall(config.validate_draft_config, cfg)
      Test.assert.truthy(ok, "Valid config should pass validation: " .. (err or ""))
      
      -- Test invalid configuration
      local invalid_cfg = vim.deepcopy(cfg)
      invalid_cfg.draft.storage.format = 'invalid_format'
      
      local invalid_ok, invalid_err = pcall(config.validate_draft_config, invalid_cfg)
      Test.assert.falsy(invalid_ok, "Invalid config should fail validation")
      
      cleanup_test_env()
      return true
    end
  },
  
  {
    name = "Draft System - Multi-Buffer Operations",
    fn = function()
      setup_test_env()
      
      -- Create multiple drafts
      local draft1 = draft_manager.create(4001, 'account1', {subject = 'Draft 1'})
      local draft2 = draft_manager.create(4002, 'account2', {subject = 'Draft 2'})
      local draft3 = draft_manager.create(4003, 'account1', {subject = 'Draft 3'})
      
      -- Verify state tracking
      Test.assert.equals(state.get_draft_count(), 3, "Should have 3 drafts")
      
      -- Test get_all
      local all_drafts = draft_manager.get_all()
      Test.assert.equals(#all_drafts, 3, "Should get all 3 drafts")
      
      -- Test buffer lookup
      Test.assert.equals(draft_manager.get_by_buffer(4001).local_id, draft1.local_id)
      Test.assert.equals(draft_manager.get_by_buffer(4002).local_id, draft2.local_id)
      Test.assert.equals(draft_manager.get_by_buffer(4003).local_id, draft3.local_id)
      
      -- Test account-specific operations
      local account1_drafts = {}
      for _, draft in ipairs(all_drafts) do
        if draft.account == 'account1' then
          table.insert(account1_drafts, draft)
        end
      end
      Test.assert.equals(#account1_drafts, 2, "Should have 2 drafts for account1")
      
      -- Test deletion
      draft_manager.delete(4002)
      Test.assert.equals(state.get_draft_count(), 2, "Should have 2 drafts after deletion")
      Test.assert.falsy(draft_manager.get_by_buffer(4002), "Deleted draft should not exist")
      
      cleanup_test_env()
      return true
    end
  },
  
  {
    name = "Draft System - State Persistence Integration",
    fn = function()
      setup_test_env()
      
      -- Create drafts with different states
      local draft1 = draft_manager.create(5001, 'test_account', {subject = 'Draft 1'})
      local draft2 = draft_manager.create(5002, 'test_account', {subject = 'Draft 2'})
      
      -- Save one draft
      draft_manager.save_local(5001)
      
      -- Mark one as synced
      draft2.remote_id = "remote_456"
      draft2.state = draft_manager.states.SYNCED
      state.set_draft(5002, draft2)
      
      -- Set metadata
      state.set("draft.metadata.last_sync", os.time())
      state.set("draft.recovery.last_recovery", os.time() - 3600)
      
      -- Save state
      state.save()
      
      -- Reset and reload
      local original_count = state.get_draft_count()
      state.reset()
      state.load()
      
      -- Verify persistence
      Test.assert.equals(state.get_draft_count(), original_count, "Draft count should persist")
      
      local persisted_draft1 = state.get_draft_by_buffer(5001)
      Test.assert.truthy(persisted_draft1, "Draft 1 should persist")
      Test.assert.equals(persisted_draft1.metadata.subject, 'Draft 1', "Subject should persist")
      
      local persisted_draft2 = state.get_draft_by_buffer(5002)
      Test.assert.truthy(persisted_draft2, "Draft 2 should persist")
      Test.assert.equals(persisted_draft2.remote_id, "remote_456", "Remote ID should persist")
      
      -- Check metadata persistence
      Test.assert.truthy(state.get("draft.metadata.last_sync"), "Last sync should persist")
      Test.assert.truthy(state.get("draft.recovery.last_recovery"), "Last recovery should persist")
      
      cleanup_test_env()
      return true
    end
  },
  
  {
    name = "Draft System - Error Handling Integration",
    fn = function()
      setup_test_env()
      
      -- Test creating draft with invalid buffer
      local invalid_draft = draft_manager.create(-1, 'test_account', {})
      Test.assert.falsy(invalid_draft, "Should not create draft with invalid buffer")
      
      -- Test operations on non-existent drafts
      local no_draft = draft_manager.get_by_buffer(9999)
      Test.assert.falsy(no_draft, "Should not find non-existent draft")
      
      local save_ok, save_err = draft_manager.save_local(9999)
      Test.assert.falsy(save_ok, "Save should fail for non-existent draft")
      Test.assert.truthy(save_err, "Should return error message")
      
      -- Test state consistency after errors
      Test.assert.equals(state.get_draft_count(), 0, "Error should not affect draft count")
      
      cleanup_test_env()
      return true
    end
  },
  
  {
    name = "Draft System - Performance Integration",
    fn = function()
      setup_test_env()
      
      -- Create many drafts to test performance
      local start_time = vim.loop.hrtime()
      
      for i = 1, 50 do
        local buffer_id = 6000 + i
        draft_manager.create(buffer_id, 'test_account', {
          subject = 'Performance Test ' .. i,
          to = 'test' .. i .. '@example.com'
        })
      end
      
      local create_time = vim.loop.hrtime()
      local create_duration = (create_time - start_time) / 1000000 -- Convert to ms
      
      -- Test state access performance
      local access_start = vim.loop.hrtime()
      for i = 1, 50 do
        local buffer_id = 6000 + i
        state.get_draft_by_buffer(buffer_id)
      end
      local access_end = vim.loop.hrtime()
      local access_duration = (access_end - access_start) / 1000000
      
      -- Performance assertions
      Test.assert.truthy(create_duration < 1000, 
        string.format("Creating 50 drafts should take less than 1000ms (took %.2fms)", create_duration))
      Test.assert.truthy(access_duration < 100, 
        string.format("50 state accesses should take less than 100ms (took %.2fms)", access_duration))
      
      -- Test bulk operations
      local bulk_start = vim.loop.hrtime()
      local all_drafts = draft_manager.get_all()
      local bulk_end = vim.loop.hrtime()
      local bulk_duration = (bulk_end - bulk_start) / 1000000
      
      Test.assert.equals(#all_drafts, 50, "Should retrieve all 50 drafts")
      Test.assert.truthy(bulk_duration < 50, 
        string.format("Bulk retrieval should take less than 50ms (took %.2fms)", bulk_duration))
      
      cleanup_test_env()
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
_G.draft_integration_test = Test.create_suite('Draft System Integration', tests)

return _G.draft_integration_test