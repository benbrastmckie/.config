-- Test for Draft Notification System Integration (Phase 4)
-- Tests notification behavior in different modes

local Test = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local notify = require('neotex.util.notifications')
local state = require('neotex.plugins.tools.himalaya.core.state')

local M = {}

-- Helper to capture notifications
local function capture_notifications()
  local captured = {}
  local original_himalaya = notify.himalaya
  
  -- Override himalaya notification function
  notify.himalaya = function(message, category, context)
    table.insert(captured, {
      message = message,
      category = category,
      context = context
    })
    -- Still call the original to maintain normal behavior
    return original_himalaya(message, category, context)
  end
  
  return {
    captured = captured,
    restore = function()
      notify.himalaya = original_himalaya
    end
  }
end

-- Test suite definition
M.tests = {
  {
    name = "Create Draft - Normal Mode",
    fn = function()
      local capture = capture_notifications()
      
      -- Ensure we're in normal mode (not debug)
      local original_debug = notify.config.modules.himalaya.debug_mode
      notify.config.modules.himalaya.debug_mode = false
      
      -- Create a draft
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account', {
        subject = 'Test Notification'
      })
      
      -- Check notifications
      vim.wait(100)
      
      -- In normal mode, should only see BACKGROUND notifications in debug mode
      local found_create = false
      for _, notif in ipairs(capture.captured) do
        if notif.message == "New draft created" then
          found_create = true
          -- Should be BACKGROUND category (only shown in debug mode)
          Test.assert.equals(notif.category, notify.categories.BACKGROUND,
            "Create notification should be BACKGROUND category")
        end
      end
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      notify.config.modules.himalaya.debug_mode = original_debug
      capture.restore()
      
      return true
    end
  },
  
  {
    name = "Save Draft - User Action",
    fn = function()
      local capture = capture_notifications()
      
      -- Create and save draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Important Draft",
        "",
        "Content"
      })
      
      draft_manager.create(buf, 'test_account')
      draft_manager.save(buf)
      
      -- Check notifications
      vim.wait(100)
      
      -- Should see USER_ACTION notification for save
      local found_save = false
      for _, notif in ipairs(capture.captured) do
        if notif.message:match("Draft saved:") then
          found_save = true
          Test.assert.equals(notif.category, notify.categories.USER_ACTION,
            "Save notification should be USER_ACTION category")
          Test.assert.truthy(notif.message:match("Important Draft"),
            "Save notification should include subject")
        end
      end
      
      Test.assert.truthy(found_save, "Should have save notification")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      capture.restore()
      
      return true
    end
  },
  
  {
    name = "Sync Draft - Status and Result",
    fn = function()
      local capture = capture_notifications()
      
      -- Create and save draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Sync Test Draft",
        "",
        "Content"
      })
      
      draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Trigger sync
      draft_manager.sync_remote(buf)
      
      -- Check notifications
      vim.wait(100)
      
      -- Should see STATUS notification for sync start
      local found_syncing = false
      for _, notif in ipairs(capture.captured) do
        if notif.message == "Syncing draft..." then
          found_syncing = true
          Test.assert.equals(notif.category, notify.categories.STATUS,
            "Sync start should be STATUS category")
          Test.assert.truthy(notif.context.allow_batching,
            "Sync notification should allow batching")
        end
      end
      
      Test.assert.truthy(found_syncing, "Should have syncing notification")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      capture.restore()
      
      return true
    end
  },
  
  {
    name = "Delete Draft - User Action",
    fn = function()
      local capture = capture_notifications()
      
      -- Create draft
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account', {
        subject = 'Delete Test'
      })
      
      -- Delete draft
      draft_manager.delete(buf)
      
      -- Check notifications
      vim.wait(100)
      
      -- Should see USER_ACTION notification for delete
      local found_delete = false
      for _, notif in ipairs(capture.captured) do
        if notif.message == "Draft deleted" then
          found_delete = true
          Test.assert.equals(notif.category, notify.categories.USER_ACTION,
            "Delete notification should be USER_ACTION category")
        end
      end
      
      Test.assert.truthy(found_delete, "Should have delete notification")
      
      -- Buffer should already be deleted
      capture.restore()
      
      return true
    end
  },
  
  {
    name = "Error Notifications",
    fn = function()
      local capture = capture_notifications()
      
      -- Try to save non-existent draft
      local buf = vim.api.nvim_create_buf(false, true)
      draft_manager.save(buf) -- No draft created
      
      -- Check notifications
      vim.wait(100)
      
      -- Should see WARNING notification
      local found_warning = false
      for _, notif in ipairs(capture.captured) do
        if notif.message == "No draft associated with this buffer" then
          found_warning = true
          Test.assert.equals(notif.category, notify.categories.WARNING,
            "No draft warning should be WARNING category")
        end
      end
      
      Test.assert.truthy(found_warning, "Should have warning notification")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      capture.restore()
      
      return true
    end
  },
  
  {
    name = "Debug Mode - Background Notifications",
    fn = function()
      local capture = capture_notifications()
      
      -- Enable debug mode
      local original_debug = notify.config.modules.himalaya.debug_mode
      notify.config.modules.himalaya.debug_mode = true
      
      -- Create a draft
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account')
      
      -- Close buffer (triggers cleanup)
      draft_manager.cleanup_draft(buf)
      
      -- Check notifications
      vim.wait(100)
      
      -- In debug mode, should see STATUS notifications
      local found_cleanup = false
      for _, notif in ipairs(capture.captured) do
        if notif.message == "Draft buffer closed" then
          found_cleanup = true
          Test.assert.equals(notif.category, notify.categories.STATUS,
            "Cleanup notification should be STATUS category")
        end
      end
      
      Test.assert.truthy(found_cleanup, "Should have cleanup notification in debug mode")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      notify.config.modules.himalaya.debug_mode = original_debug
      capture.restore()
      
      return true
    end
  },
  
  {
    name = "Recovery Notifications",
    fn = function()
      local capture = capture_notifications()
      
      -- Reset state
      state.reset()
      draft_manager.drafts = {}
      
      -- Create and save draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Recovery Test",
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
      
      -- Check notifications
      vim.wait(100)
      
      -- Should see USER_ACTION notification for recovery
      local found_recovery = false
      for _, notif in ipairs(capture.captured) do
        if notif.message:match("Recovered %d+ draft") then
          found_recovery = true
          Test.assert.equals(notif.category, notify.categories.USER_ACTION,
            "Recovery notification should be USER_ACTION category")
        end
      end
      
      Test.assert.truthy(found_recovery, "Should have recovery notification")
      
      -- Cleanup
      capture.restore()
      
      return true
    end
  },
  
  {
    name = "Notification Context",
    fn = function()
      local capture = capture_notifications()
      
      -- Create and save draft with specific details
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Context Test",
        "To: test@example.com",
        "",
        "Content"
      })
      
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save(buf)
      
      -- Check notification context
      vim.wait(100)
      
      local save_notif = nil
      for _, notif in ipairs(capture.captured) do
        if notif.message:match("Draft saved:") then
          save_notif = notif
          break
        end
      end
      
      Test.assert.truthy(save_notif, "Should have save notification")
      Test.assert.truthy(save_notif.context, "Should have context")
      Test.assert.equals(save_notif.context.module, 'himalaya', "Should have himalaya module")
      Test.assert.equals(save_notif.context.feature, 'drafts', "Should have drafts feature")
      Test.assert.truthy(save_notif.context.draft_id, "Should have draft_id in context")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      capture.restore()
      
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
_G.draft_notifications_test = Test.create_suite('Draft Notification System', tests)

return _G.draft_notifications_test