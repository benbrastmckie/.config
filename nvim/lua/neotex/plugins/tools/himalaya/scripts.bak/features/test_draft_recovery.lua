-- Test for Draft System Persistence & Recovery (Phase 2)
-- Tests draft recovery across Neovim sessions

local Test = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local state = require('neotex.plugins.tools.himalaya.core.state')
local storage = require('neotex.plugins.tools.himalaya.core.local_storage')

local M = {}

-- Test suite definition
M.tests = {
  {
    name = "State Persistence - Draft Metadata",
    fn = function()
      -- Reset everything
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      
      -- Create a draft with metadata
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Recovery Test Draft",
        "To: test@example.com",
        "",
        "This draft should be recoverable"
      })
      
      -- Create and save draft
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Get draft info before save
      local draft_id = draft.local_id
      local draft_path = draft.local_path
      
      -- Save state to disk
      local save_ok = state.save()
      Test.assert.truthy(save_ok, "State save should succeed")
      
      -- Simulate restart - reset everything
      state.reset()
      draft_manager.drafts = {}
      
      -- Load state from disk
      local load_ok = state.load()
      Test.assert.truthy(load_ok, "State load should succeed")
      
      -- Check draft metadata was persisted
      local saved_drafts = state.get_all_drafts()
      Test.assert.truthy(saved_drafts[tostring(buf)], "Draft should be in saved state")
      Test.assert.equals(saved_drafts[tostring(buf)].local_id, draft_id, "Local ID should match")
      Test.assert.equals(saved_drafts[tostring(buf)].subject, "Recovery Test Draft", "Subject should be persisted")
      Test.assert.equals(saved_drafts[tostring(buf)].local_path, draft_path, "Path should be persisted")
      
      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "Recovery Process - Basic Recovery",
    fn = function()
      -- Reset and setup
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      storage.setup()
      
      -- Create a draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Basic Recovery Test",
        "To: recover@example.com",
        "",
        "Content to recover"
      })
      
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Save state
      state.save()
      
      -- Simulate restart
      local draft_id = draft.local_id
      vim.api.nvim_buf_delete(buf, { force = true })
      draft_manager.drafts = {}
      
      -- Reload state
      state.load()
      
      -- Run recovery
      local recovered = draft_manager.recover_session()
      Test.assert.equals(recovered, 1, "Should recover 1 draft")
      
      -- Check draft was recovered
      Test.assert.truthy(draft_manager.drafts[draft_id], "Draft should be in cache by ID")
      Test.assert.truthy(draft_manager.drafts[draft_id].recovered, "Draft should be marked as recovered")
      Test.assert.equals(draft_manager.drafts[draft_id].metadata.subject, "Basic Recovery Test", 
        "Recovered draft should have correct subject")
      
      return true
    end
  },
  
  {
    name = "Recovery Process - Multiple Drafts",
    fn = function()
      -- Reset
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      storage.setup()
      
      -- Create multiple drafts
      local draft_ids = {}
      for i = 1, 3 do
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "Subject: Recovery Test " .. i,
          "To: test" .. i .. "@example.com",
          "",
          "Draft content " .. i
        })
        
        local draft = draft_manager.create(buf, 'test_account')
        draft_manager.save_local(buf)
        table.insert(draft_ids, draft.local_id)
        
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      
      -- Save state
      state.save()
      
      -- Simulate restart
      draft_manager.drafts = {}
      state.load()
      
      -- Recover
      local recovered = draft_manager.recover_session()
      Test.assert.equals(recovered, 3, "Should recover all 3 drafts")
      
      -- Check all drafts were recovered
      for i, draft_id in ipairs(draft_ids) do
        Test.assert.truthy(draft_manager.drafts[draft_id], "Draft " .. i .. " should be recovered")
        Test.assert.equals(draft_manager.drafts[draft_id].metadata.subject, 
          "Recovery Test " .. i, "Subject should match")
      end
      
      return true
    end
  },
  
  {
    name = "Recovery Process - Missing Files",
    fn = function()
      -- Reset
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      
      -- Manually add draft metadata to state without creating file
      state.set_draft(999, {
        local_id = "missing_draft",
        local_path = "/tmp/nonexistent_draft.json",
        subject = "Missing Draft",
        account = "test_account"
      })
      
      -- Save state
      state.save()
      
      -- Reload and recover
      state.load()
      local recovered = draft_manager.recover_session()
      
      Test.assert.equals(recovered, 0, "Should not recover missing drafts")
      Test.assert.falsy(draft_manager.drafts["missing_draft"], "Missing draft should not be in cache")
      Test.assert.falsy(state.get_draft_by_buffer(999), "Missing draft should be removed from state")
      
      return true
    end
  },
  
  {
    name = "Recovery Tracking - Unsaved Drafts",
    fn = function()
      -- Reset
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      storage.setup()
      
      -- Create a modified draft
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Subject: Unsaved Changes",
        "",
        "Modified content"
      })
      
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Mark as modified but not synced
      draft.modified = true
      draft.synced = false
      state.set_draft(buf, draft)
      
      -- Save state
      state.save()
      
      -- Simulate restart
      vim.api.nvim_buf_delete(buf, { force = true })
      draft_manager.drafts = {}
      state.load()
      
      -- Recover
      draft_manager.recover_session()
      
      -- Check pending syncs were tracked
      local pending = state.get_pending_syncs()
      Test.assert.equals(#pending, 1, "Should have 1 pending sync")
      Test.assert.equals(pending[1].subject, "Unsaved Changes", "Pending sync should have correct subject")
      
      return true
    end
  },
  
  {
    name = "Recovery Commands - List Recovered",
    fn = function()
      -- Reset and create recovered drafts
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      storage.setup()
      
      -- Create test drafts
      for i = 1, 2 do
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "Subject: Test Draft " .. i,
          "",
          "Content"
        })
        
        local draft = draft_manager.create(buf, 'test_account')
        draft_manager.save_local(buf)
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      
      -- Save, restart, recover
      state.save()
      draft_manager.drafts = {}
      state.load()
      draft_manager.recover_session()
      
      -- Get recovered drafts
      local recovered = draft_manager.get_recovered_drafts()
      Test.assert.equals(#recovered, 2, "Should list 2 recovered drafts")
      Test.assert.truthy(recovered[1].subject:match("Test Draft"), "Should have correct subject")
      
      return true
    end
  },
  
  {
    name = "Recovery Commands - Open Recovered Draft",
    fn = function()
      -- Reset
      state.reset()
      draft_manager.drafts = {}
      storage._clear_all()
      storage.setup()
      
      -- Create a draft
      local buf = vim.api.nvim_create_buf(false, true)
      local content = {
        "Subject: Open Me",
        "To: open@test.com",
        "",
        "This content should be restored"
      }
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      local draft_id = draft.local_id
      
      -- Save and restart
      state.save()
      vim.api.nvim_buf_delete(buf, { force = true })
      draft_manager.drafts = {}
      state.load()
      draft_manager.recover_session()
      
      -- Open recovered draft
      local new_buf = draft_manager.open_recovered_draft(draft_id)
      Test.assert.truthy(new_buf, "Should create new buffer")
      Test.assert.truthy(vim.api.nvim_buf_is_valid(new_buf), "Buffer should be valid")
      
      -- Check content was restored
      local restored_content = vim.api.nvim_buf_get_lines(new_buf, 0, -1, false)
      Test.assert.equals(#restored_content, #content, "Should restore all lines")
      Test.assert.equals(restored_content[1], "Subject: Open Me", "Should restore content correctly")
      
      -- Check draft is now associated with buffer
      Test.assert.truthy(draft_manager.drafts[new_buf], "Draft should be associated with new buffer")
      Test.assert.falsy(draft_manager.drafts[new_buf].recovered, "Recovered flag should be cleared")
      
      -- Cleanup
      vim.api.nvim_buf_delete(new_buf, { force = true })
      
      return true
    end
  },
  
  {
    name = "Recovery Timestamp Tracking",
    fn = function()
      -- Reset
      state.reset()
      
      -- Check no recovery timestamp initially
      local recovery_data = state.get("draft.recovery")
      Test.assert.falsy(recovery_data.last_recovery, "Should have no recovery timestamp initially")
      
      -- Create and save a draft
      storage._clear_all()
      storage.setup()
      local buf = vim.api.nvim_create_buf(false, true)
      local draft = draft_manager.create(buf, 'test_account')
      draft_manager.save_local(buf)
      
      -- Save state and simulate restart
      state.save()
      vim.api.nvim_buf_delete(buf, { force = true })
      draft_manager.drafts = {}
      state.load()
      
      -- Run recovery
      draft_manager.recover_session()
      
      -- Check recovery timestamp was set
      recovery_data = state.get("draft.recovery")
      Test.assert.truthy(recovery_data.last_recovery, "Should set recovery timestamp")
      Test.assert.truthy(recovery_data.last_recovery > 0, "Timestamp should be valid")
      
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
_G.draft_recovery_test = Test.create_suite('Draft Persistence & Recovery', tests)

return _G.draft_recovery_test