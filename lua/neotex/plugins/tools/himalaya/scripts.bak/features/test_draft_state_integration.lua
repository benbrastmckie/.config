-- Test for Draft System State Integration (Phase 1)
-- Tests the integration of draft system with centralized state management

local Test = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local state = require('neotex.plugins.tools.himalaya.core.state')

local M = {}

-- Test suite definition
M.tests = {
  {
    name = "State Management - Draft Creation",
    fn = function()
      -- Reset state
      state.reset()
      draft_manager.drafts = {}
      draft_manager.setup()
      
      -- Create a buffer
      local buf = vim.api.nvim_create_buf(false, true)
      
      -- Create a draft
      local draft = draft_manager.create(buf, 'test_account', {
        compose_type = 'new'
      })
      
      -- Check that draft is in centralized state
      local state_draft = state.get_draft_by_buffer(buf)
      Test.assert.truthy(state_draft, "Draft should exist in state")
      Test.assert.equals(state_draft.local_id, draft.local_id, "Local ID should match")
      Test.assert.equals(state_draft.account, draft.account, "Account should match")
      
      -- Check draft count
      Test.assert.equals(state.get_draft_count(), 1, "Draft count should be 1")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "State Management - Draft Saving",
    fn = function()
      -- Reset state
      state.reset()
      draft_manager.drafts = {}
      draft_manager.setup()
      
      -- Create a buffer with content
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Test Draft",
        "To: test@example.com",
        "",
        "Test content"
      })
      
      -- Create and save draft
      local draft = draft_manager.create(buf, 'test_account')
      local success = draft_manager.save_local(buf)
      Test.assert.truthy(success, "Save should succeed")
      
      -- Check state was updated
      local state_draft = state.get_draft_by_buffer(buf)
      Test.assert.truthy(state_draft, "Draft should exist in state")
      Test.assert.truthy(state_draft.modified, "Draft should be marked as modified")
      Test.assert.falsy(state_draft.synced, "Draft should not be marked as synced")
      
      -- Check unsaved drafts tracking
      local unsaved = state.get_unsaved_drafts()
      Test.assert.truthy(unsaved[tostring(buf)], "Draft should be in unsaved list")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "State Management - Sync Status",
    fn = function()
      -- Reset state
      state.reset()
      draft_manager.drafts = {}
      draft_manager.setup()
      
      -- Create a buffer
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account')
      
      -- Save draft first (required for sync)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Test Sync",
        "",
        "Content"
      })
      draft_manager.save_local(buf)
      
      -- Start sync
      draft_manager.sync_remote(buf)
      
      -- Check sync status
      Test.assert.truthy(state.is_draft_syncing(), "Should be syncing")
      
      -- Simulate sync completion
      draft_manager.handle_sync_completion(draft.local_id, "12345", true, nil)
      
      -- Check sync status cleared
      Test.assert.falsy(state.is_draft_syncing(), "Should not be syncing")
      
      -- Check draft state updated
      local state_draft = state.get_draft_by_buffer(buf)
      Test.assert.equals(state_draft.remote_id, "12345", "Remote ID should be set")
      Test.assert.equals(state_draft.state, draft_manager.states.SYNCED, "State should be SYNCED")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "State Management - Draft Deletion",
    fn = function()
      -- Reset state completely
      state.reset()
      draft_manager.drafts = {}
      -- Force clean start
      state.state.draft.drafts = {}
      state.state.draft.metadata.total_count = 0
      state.state.draft.recovery.unsaved_buffers = {}
      draft_manager.setup()
      
      -- Create a buffer
      local buf = vim.api.nvim_create_buf(false, true)
      draft_manager.create(buf, 'test_account')
      
      -- Verify draft exists
      Test.assert.equals(state.get_draft_count(), 1, "Draft count should be 1")
      
      -- Delete draft
      draft_manager.delete(buf)
      
      -- Check removed from state
      Test.assert.falsy(state.get_draft_by_buffer(buf), "Draft should not exist in state")
      Test.assert.equals(state.get_draft_count(), 0, "Draft count should be 0")
      
      return true
    end
  },
  
  {
    name = "Recovery Tracking - Unsaved Drafts",
    fn = function()
      -- Reset state completely
      state.reset()
      draft_manager.drafts = {}
      -- Force clean start
      state.state.draft.drafts = {}
      state.state.draft.metadata.total_count = 0
      state.state.draft.recovery.unsaved_buffers = {}
      draft_manager.setup()
      
      -- Create and modify draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Important Draft",
        "",
        "This needs to be saved"
      })
      
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Check tracked as unsaved
      local unsaved = state.get_unsaved_drafts()
      Test.assert.equals(vim.tbl_count(unsaved), 1, "Should have 1 unsaved draft")
      Test.assert.truthy(unsaved[tostring(buf)], "Draft should be in unsaved list")
      Test.assert.equals(unsaved[tostring(buf)].subject, "Important Draft", "Subject should match")
      
      -- Simulate successful sync
      draft_manager.handle_sync_completion(draft.local_id, "12345", true, nil)
      
      -- Check removed from unsaved
      unsaved = state.get_unsaved_drafts()
      Test.assert.equals(vim.tbl_count(unsaved), 0, "Should have no unsaved drafts")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "Recovery Tracking - Pending Syncs",
    fn = function()
      -- Reset state
      state.reset()
      
      -- Add pending sync
      state.add_pending_sync({
        local_id = "test123",
        account = "test_account",
        subject = "Pending Draft"
      })
      
      -- Check pending syncs
      local pending = state.get_pending_syncs()
      Test.assert.equals(#pending, 1, "Should have 1 pending sync")
      Test.assert.equals(pending[1].local_id, "test123", "Local ID should match")
      
      -- Clear pending syncs
      state.clear_pending_syncs()
      pending = state.get_pending_syncs()
      Test.assert.equals(#pending, 0, "Should have no pending syncs")
      
      return true
    end
  },
  
  {
    name = "Fallback to State - Get by Buffer",
    fn = function()
      -- Reset state
      state.reset()
      draft_manager.drafts = {}
      draft_manager.setup()
      
      -- Add draft only to state
      local test_draft = {
        local_id = "state_only",
        account = "test_account",
        metadata = { subject = "State Only Draft" }
      }
      state.set_draft(2000, test_draft)
      
      -- Get by buffer should find it
      local draft = draft_manager.get_by_buffer(2000)
      Test.assert.truthy(draft, "Should find draft in state")
      Test.assert.equals(draft.local_id, "state_only", "Local ID should match")
      
      -- Has draft should return true
      Test.assert.truthy(draft_manager.has_draft(2000), "has_draft should return true")
      
      return true
    end
  },
  
  {
    name = "Fallback to State - Get by Remote ID",
    fn = function()
      -- Reset state
      state.reset()
      draft_manager.drafts = {}
      draft_manager.setup()
      
      -- Add draft only to state
      local test_draft = {
        local_id = "state_remote",
        remote_id = "remote999",
        account = "test_account",
        metadata = { subject = "Remote Draft" }
      }
      state.set_draft(3000, test_draft)
      
      -- Get by remote ID should find it
      local draft = draft_manager.get_by_remote_id("remote999")
      Test.assert.truthy(draft, "Should find draft by remote ID")
      Test.assert.equals(draft.local_id, "state_remote", "Local ID should match")
      
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
_G.draft_state_integration_test = Test.create_suite('Draft State Integration', tests)

return _G.draft_state_integration_test