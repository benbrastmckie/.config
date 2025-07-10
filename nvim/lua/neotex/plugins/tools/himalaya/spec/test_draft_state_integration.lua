-- Test for Draft System State Integration (Phase 1)
-- Tests the integration of draft system with centralized state management

local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local state = require('neotex.plugins.tools.himalaya.core.state')

describe("Draft State Integration", function()
  before_each(function()
    -- Reset state
    state.reset()
    draft_manager.drafts = {}
    
    -- Initialize draft manager
    draft_manager.setup()
  end)
  
  after_each(function()
    -- Clean up any test buffers
    for buf, _ in pairs(draft_manager.drafts) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end)
  
  describe("State Management", function()
    it("should add draft to centralized state when created", function()
      -- Create a buffer
      local buf = vim.api.nvim_create_buf(false, true)
      
      -- Create a draft
      local draft = draft_manager.create(buf, 'test_account', {
        compose_type = 'new'
      })
      
      -- Check that draft is in centralized state
      local state_draft = state.get_draft_by_buffer(buf)
      assert.is_not_nil(state_draft)
      assert.equals(draft.local_id, state_draft.local_id)
      assert.equals(draft.account, state_draft.account)
      
      -- Check draft count
      assert.equals(1, state.get_draft_count())
    end)
    
    it("should update centralized state when draft is saved", function()
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
      assert.is_true(success)
      
      -- Check state was updated
      local state_draft = state.get_draft_by_buffer(buf)
      assert.is_not_nil(state_draft)
      assert.is_true(state_draft.modified)
      assert.is_false(state_draft.synced)
      
      -- Check unsaved drafts tracking
      local unsaved = state.get_unsaved_drafts()
      assert.is_not_nil(unsaved[tostring(buf)])
    end)
    
    it("should update sync status in centralized state", function()
      -- Create a buffer
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account')
      
      -- Start sync
      draft_manager.sync_remote(buf)
      
      -- Check sync status
      assert.is_true(state.is_draft_syncing())
      
      -- Simulate sync completion
      draft_manager.handle_sync_completion(draft.local_id, "12345", true, nil)
      
      -- Check sync status cleared
      assert.is_false(state.is_draft_syncing())
      
      -- Check draft state updated
      local state_draft = state.get_draft_by_buffer(buf)
      assert.equals("12345", state_draft.remote_id)
      assert.equals(draft_manager.states.SYNCED, state_draft.state)
    end)
    
    it("should remove draft from state when deleted", function()
      -- Create a buffer
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account')
      
      -- Verify draft exists
      assert.equals(1, state.get_draft_count())
      
      -- Delete draft
      draft_manager.delete(buf)
      
      -- Check removed from state
      assert.is_nil(state.get_draft_by_buffer(buf))
      assert.equals(0, state.get_draft_count())
    end)
  end)
  
  describe("State Persistence", function()
    it("should persist draft metadata in state save", function()
      -- Create drafts
      local buf1 = vim.api.nvim_create_buf(false, true)
      local buf2 = vim.api.nvim_create_buf(false, true)
      
      draft_manager.create(buf1, 'test_account', {
        compose_type = 'new'
      })
      draft_manager.create(buf2, 'test_account', {
        compose_type = 'reply'
      })
      
      -- Set some metadata
      local draft1 = draft_manager.get_by_buffer(buf1)
      draft1.metadata.subject = "Test Draft 1"
      draft1.remote_id = "remote1"
      state.set_draft(buf1, draft1)
      
      -- Simulate state save (would normally write to disk)
      local persist_state = {
        draft = {
          metadata = state.state.draft.metadata,
          recovery = state.state.draft.recovery,
          drafts = vim.tbl_map(function(draft)
            return {
              id = draft.id,
              local_id = draft.local_id,
              remote_id = draft.remote_id,
              subject = draft.metadata and draft.metadata.subject or nil,
              account = draft.account,
            }
          end, state.state.draft.drafts or {})
        }
      }
      
      -- Check persisted data
      assert.equals(2, vim.tbl_count(persist_state.draft.drafts))
      assert.is_not_nil(persist_state.draft.drafts[tostring(buf1)])
      assert.equals("Test Draft 1", persist_state.draft.drafts[tostring(buf1)].subject)
      assert.equals("remote1", persist_state.draft.drafts[tostring(buf1)].remote_id)
    end)
  end)
  
  describe("Recovery Tracking", function()
    it("should track unsaved drafts for recovery", function()
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
      assert.equals(1, vim.tbl_count(unsaved))
      assert.is_not_nil(unsaved[tostring(buf)])
      assert.equals("Important Draft", unsaved[tostring(buf)].subject)
      
      -- Simulate successful sync
      draft_manager.handle_sync_completion(draft.local_id, "12345", true, nil)
      
      -- Check removed from unsaved
      unsaved = state.get_unsaved_drafts()
      assert.equals(0, vim.tbl_count(unsaved))
    end)
    
    it("should track pending syncs", function()
      -- Add pending sync
      state.add_pending_sync({
        local_id = "test123",
        account = "test_account",
        subject = "Pending Draft"
      })
      
      -- Check pending syncs
      local pending = state.get_pending_syncs()
      assert.equals(1, #pending)
      assert.equals("test123", pending[1].local_id)
      
      -- Clear pending syncs
      state.clear_pending_syncs()
      pending = state.get_pending_syncs()
      assert.equals(0, #pending)
    end)
  end)
  
  describe("State Sync on Startup", function()
    it("should sync draft manager with centralized state", function()
      -- Manually add draft to state (simulating loaded from disk)
      local test_draft = {
        local_id = "loaded123",
        account = "test_account",
        metadata = { subject = "Loaded Draft" },
        state = draft_manager.states.SYNCED,
        remote_id = "remote123"
      }
      state.set_draft(1000, test_draft)
      
      -- Clear local cache and sync
      draft_manager.drafts = {}
      draft_manager._sync_with_state()
      
      -- Check if valid buffers are synced
      -- Note: buffer 1000 is not valid, so it won't be synced
      assert.equals(0, vim.tbl_count(draft_manager.drafts))
      
      -- Create a valid buffer and add to state
      local buf = vim.api.nvim_create_buf(false, true)
      state.set_draft(buf, test_draft)
      
      -- Sync again
      draft_manager._sync_with_state()
      
      -- Now it should be synced
      assert.equals(1, vim.tbl_count(draft_manager.drafts))
      assert.is_not_nil(draft_manager.drafts[buf])
      assert.equals("loaded123", draft_manager.drafts[buf].local_id)
    end)
  end)
  
  describe("Fallback to State", function()
    it("should fall back to state when draft not in local cache", function()
      -- Add draft only to state
      local test_draft = {
        local_id = "state_only",
        account = "test_account",
        metadata = { subject = "State Only Draft" }
      }
      state.set_draft(2000, test_draft)
      
      -- Get by buffer should find it
      local draft = draft_manager.get_by_buffer(2000)
      assert.is_not_nil(draft)
      assert.equals("state_only", draft.local_id)
      
      -- Has draft should return true
      assert.is_true(draft_manager.has_draft(2000))
    end)
    
    it("should check state when getting by remote ID", function()
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
      assert.is_not_nil(draft)
      assert.equals("state_remote", draft.local_id)
    end)
    
    it("should include state drafts in get_all", function()
      -- Create one draft normally
      local buf1 = vim.api.nvim_create_buf(false, true)
      draft_manager.create(buf1, 'test_account')
      
      -- Add another only to state
      local test_draft = {
        local_id = "state_all",
        account = "test_account",
        metadata = { subject = "State Draft" }
      }
      state.set_draft(4000, test_draft)
      
      -- Get all should include both
      local all_drafts = draft_manager.get_all()
      assert.equals(2, #all_drafts)
    end)
  end)
end)

-- Run the tests
if vim.fn.has('nvim-0.9') == 1 then
  -- Use built-in test runner if available
  return true
else
  -- Run tests immediately for older versions
  local success = pcall(function()
    local busted = require('plenary.busted')
    busted.run()
  end)
  
  if not success then
    print("Tests require plenary.nvim to be installed")
  end
end