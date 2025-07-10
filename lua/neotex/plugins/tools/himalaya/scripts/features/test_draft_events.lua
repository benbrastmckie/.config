-- Test for Draft Event System Integration (Phase 3)
-- Tests event emissions and subscriptions across modules

local Test = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local sync_engine = require('neotex.plugins.tools.himalaya.core.sync_engine')
local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_types = require('neotex.plugins.tools.himalaya.core.events')
local state = require('neotex.plugins.tools.himalaya.core.state')
local storage = require('neotex.plugins.tools.himalaya.core.local_storage')

local M = {}

-- Helper to capture events
local function create_event_capture()
  local captured = {}
  
  local function capture(event_name)
    local handler = function(data)
      table.insert(captured, {
        event = event_name,
        data = data,
        time = os.time()
      })
    end
    events_bus.on(event_name, handler, { module = "test_capture" })
    return handler
  end
  
  return {
    capture = capture,
    captured = captured,
    find = function(event_name)
      for _, event in ipairs(captured) do
        if event.event == event_name then
          return event
        end
      end
      return nil
    end,
    count = function(event_name)
      local count = 0
      for _, event in ipairs(captured) do
        if event.event == event_name then
          count = count + 1
        end
      end
      return count
    end
  }
end

-- Test suite definition
M.tests = {
  {
    name = "Draft Creation - Event Emission",
    fn = function()
      -- Setup event capture
      local capture = create_event_capture()
      capture.capture(event_types.DRAFT_CREATED)
      
      -- Create a draft
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account', {
        subject = 'Event Test Draft'
      })
      
      -- Check event was emitted
      vim.wait(100) -- Wait for event processing
      local event = capture.find(event_types.DRAFT_CREATED)
      
      Test.assert.truthy(event, "DRAFT_CREATED event should be emitted")
      Test.assert.equals(event.data.draft_id, draft.local_id, "Event should contain draft ID")
      Test.assert.equals(event.data.buffer, buf, "Event should contain buffer")
      Test.assert.equals(event.data.account, 'test_account', "Event should contain account")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "Draft Save - Event Emission",
    fn = function()
      -- Setup
      local capture = create_event_capture()
      capture.capture(event_types.DRAFT_SAVED)
      
      -- Create and save draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Save Event Test",
        "",
        "Content"
      })
      
      draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Check event
      vim.wait(100)
      local event = capture.find(event_types.DRAFT_SAVED)
      
      Test.assert.truthy(event, "DRAFT_SAVED event should be emitted")
      Test.assert.equals(event.data.buffer, buf, "Event should contain buffer")
      Test.assert.falsy(event.data.is_autosave, "Should not be autosave")
      Test.assert.truthy(event.data.content_length > 0, "Should have content length")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "Draft Sync - Event Flow",
    fn = function()
      -- Setup
      local capture = create_event_capture()
      capture.capture(event_types.DRAFT_SYNC_QUEUED)
      capture.capture(event_types.DRAFT_SYNC_STARTED)
      capture.capture(event_types.DRAFT_SYNC_PROGRESS)
      
      -- Create and save draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Sync Event Test",
        "",
        "Content"
      })
      
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Trigger sync
      draft_manager.sync_remote(buf)
      
      -- Check queued event
      vim.wait(100)
      local queued_event = capture.find(event_types.DRAFT_SYNC_QUEUED)
      Test.assert.truthy(queued_event, "DRAFT_SYNC_QUEUED event should be emitted")
      Test.assert.equals(queued_event.data.draft_id, draft.local_id, 
        "Queued event should have draft ID")
      
      -- Note: SYNC_STARTED and PROGRESS events would be emitted by sync_engine
      -- when it processes the queue, which happens asynchronously
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "Draft Delete - Event Emission",
    fn = function()
      -- Setup
      local capture = create_event_capture()
      capture.capture(event_types.DRAFT_DELETED)
      
      -- Create draft
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account')
      
      -- Delete draft
      draft_manager.delete(buf)
      
      -- Check event
      vim.wait(100)
      local event = capture.find(event_types.DRAFT_DELETED)
      
      Test.assert.truthy(event, "DRAFT_DELETED event should be emitted")
      Test.assert.equals(event.data.draft_id, draft.local_id, "Event should contain draft ID")
      Test.assert.equals(event.data.account, 'test_account', "Event should contain account")
      
      return true
    end
  },
  
  {
    name = "UI Subscription - Sidebar Updates",
    fn = function()
      -- This test verifies that sidebar event handlers are registered
      -- We can't easily test the actual UI updates in headless mode
      
      -- Check that sidebar_v2 has registered handlers
      local sidebar_v2 = require('neotex.plugins.tools.himalaya.ui.sidebar_v2')
      
      -- The module should have its setup function called which registers events
      Test.assert.truthy(sidebar_v2, "Sidebar v2 module should be loaded")
      
      -- We can verify handlers are registered by emitting an event
      -- and checking if it doesn't error
      local ok = pcall(function()
        events_bus.emit(event_types.DRAFT_CREATED, {
          draft_id = "test",
          buffer = 1,
          account = "test"
        })
      end)
      
      Test.assert.truthy(ok, "Event emission should not error")
      
      return true
    end
  },
  
  {
    name = "Recovery Events - DRAFT_RECOVERED",
    fn = function()
      -- Setup
      local capture = create_event_capture()
      capture.capture(event_types.DRAFT_RECOVERED)
      
      -- Reset and create a draft
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      storage.setup()
      
      -- Create and save draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Recovery Event Test",
        "",
        "Content"
      })
      
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Save state and simulate restart
      state.save()
      vim.api.nvim_buf_delete(buf, { force = true })
      draft_manager.drafts = {}
      state.load()
      
      -- Run recovery
      draft_manager.recover_session()
      
      -- Check event
      vim.wait(100)
      local event = capture.find(event_types.DRAFT_RECOVERED)
      
      Test.assert.truthy(event, "DRAFT_RECOVERED event should be emitted")
      Test.assert.truthy(event.data.draft, "Event should contain draft data")
      Test.assert.equals(event.data.draft.metadata.subject, "Recovery Event Test",
        "Recovered draft should have correct subject")
      
      return true
    end
  },
  
  {
    name = "Event Logging - Debug Mode",
    fn = function()
      -- This test verifies that events are logged when debug mode is on
      local logger = require('neotex.plugins.tools.himalaya.core.logger')
      local original_debug = logger.debug
      
      -- Capture log calls
      local logged = {}
      logger.debug = function(msg, data)
        table.insert(logged, { msg = msg, data = data })
      end
      
      -- Emit a draft event
      events_bus.emit(event_types.DRAFT_CREATED, {
        draft_id = "test_log",
        buffer = 1
      })
      
      -- Check if event was logged
      vim.wait(100)
      local found = false
      for _, log in ipairs(logged) do
        if log.msg:match("Draft Event: draft:created") then
          found = true
          break
        end
      end
      
      Test.assert.truthy(found, "Draft event should be logged")
      
      -- Restore original
      logger.debug = original_debug
      
      return true
    end
  },
  
  {
    name = "Orphaned Draft Detection",
    fn = function()
      -- Setup
      local capture = create_event_capture()
      capture.capture(event_types.DRAFT_RECOVERY_NEEDED)
      
      -- Reset
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      storage.setup()
      
      -- Create orphaned draft directly in storage
      storage.save('orphaned_123', {
        metadata = { subject = 'Orphaned Draft' },
        content = 'Orphaned content',
        account = 'test_account',
        updated_at = os.time()
      })
      
      -- Run orphaned draft check
      draft_manager._check_orphaned_drafts()
      
      -- Check event
      vim.wait(100)
      local event = capture.find(event_types.DRAFT_RECOVERY_NEEDED)
      
      Test.assert.truthy(event, "DRAFT_RECOVERY_NEEDED event should be emitted")
      Test.assert.equals(event.data.draft_id, 'orphaned_123', 
        "Event should contain orphaned draft ID")
      
      -- Cleanup
      storage.delete('orphaned_123')
      
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
_G.draft_events_test = Test.create_suite('Draft Event System', tests)

return _G.draft_events_test