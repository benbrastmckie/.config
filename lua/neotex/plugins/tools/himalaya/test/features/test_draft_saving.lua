-- Draft Saving Feature Test
-- Tests the complete draft saving workflow for email composition

local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')

-- Test metadata
local test_metadata = {
  name = "Draft Saving Feature Tests",
  description = "Tests the complete draft saving workflow for email composition",
  count = 5,
  category = "feature",
  tags = {"drafts", "saving", "workflow", "composer"},
  estimated_duration_ms = 2000
}
local assert = framework.assert
local notify = require('neotex.util.notifications')

-- Test configuration
local TEST_EMAIL = {
  from = 'test@example.com',
  to = 'recipient@example.com', 
  subject = 'Draft Test Email',
  body = 'This is a test draft created by the automated test.'
}

-- Test suite
local tests = {}

-- Initialize config before tests
local config = require('neotex.plugins.tools.himalaya.core.config')
if not config.initialized then
  -- Set test mode before config setup
  _G.HIMALAYA_TEST_MODE = true
  config.setup({
    binaries = {
      himalaya = 'himalaya'
    },
    accounts = {
      gmail = {
        email = 'test@gmail.com',
        folder_map = {
          ["[Gmail]/Drafts"] = "Drafts"
        }
      }
    }
  })
end

-- Test 1: Draft folder detection
table.insert(tests, framework.create_test('draft_folder_detection', function()
  -- Ensure config is initialized for this test
  local config = require('neotex.plugins.tools.himalaya.core.config')
  if not config.config.accounts or not config.config.accounts.gmail then
    config.setup({
      binaries = {
        himalaya = 'himalaya'
      },
      accounts = {
        gmail = {
          email = 'test@gmail.com',
          folder_map = {
            ["[Gmail]/Drafts"] = "Drafts"
          }
        }
      }
    })
  end
  
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  local folder = utils.find_draft_folder('gmail')
  
  assert.truthy(folder, "Draft folder should be detected")
  assert.equals(folder, 'Drafts', "Draft folder should be 'Drafts' for gmail")
end))

-- Test 2: Direct save_draft function
table.insert(tests, framework.create_test('save_draft_function', function()
  -- Ensure config is initialized for this test
  local config = require('neotex.plugins.tools.himalaya.core.config')
  if not config.config.binaries then
    config.setup({
      binaries = {
        himalaya = 'himalaya'
      },
      accounts = {
        gmail = {
          email = 'test@gmail.com',
          folder_map = {
            ["[Gmail]/Drafts"] = "Drafts"
          }
        }
      }
    })
  end
  
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  local result, err = utils.save_draft('gmail', 'Drafts', TEST_EMAIL)
  
  assert.truthy(result, "save_draft should return a result: " .. tostring(err))
  assert.truthy(result.id, "save_draft should return a draft ID")
end))

-- Test 3: Composer workflow
table.insert(tests, framework.create_test('composer_draft_saving', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
  
  -- Setup composer
  composer.setup()
  
  -- Create compose buffer
  local opts = {
    to = TEST_EMAIL.to,
    subject = TEST_EMAIL.subject,
    body = TEST_EMAIL.body
  }
  
  local buf = composer.create_compose_buffer(opts)
  assert.truthy(buf, "Compose buffer should be created")
  assert.truthy(vim.api.nvim_buf_is_valid(buf), "Buffer should be valid")
  
  -- Mark as modified and save
  vim.api.nvim_buf_set_option(buf, 'modified', true)
  composer.save_draft(buf)
  
  -- Wait a moment for async operations
  vim.wait(2000, function() return false end)
  
  -- Check if buffer is tracked as a compose buffer
  assert.truthy(composer.is_compose_buffer(buf), "Buffer should be tracked as compose buffer")
  
  -- Save the buffer before cleanup to ensure draft is persisted
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent write!')
  end)
  
  -- Clean up using the proper cleanup method to prevent sidebar expansion
  if vim.api.nvim_buf_is_valid(buf) then
    -- Use the close method to cleanup
    composer.close_compose_buffer(buf)
    
    -- Force buffer deletion if it still exists (test cleanup)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
      
      -- Also cleanup any buffers with test email content
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(b) then
          local lines = vim.api.nvim_buf_get_lines(b, 0, 5, false)
          local content = table.concat(lines, '\n')
          if content:match('From: test@example%.com') and 
             content:match('Subject: Draft Test Email') then
            pcall(vim.api.nvim_buf_delete, b, { force = true })
          end
        end
      end
    end)
  end
end))

-- Test 4: Verify drafts are saved to maildir (run after draft creation)
table.insert(tests, framework.create_test('drafts_in_maildir', function()
  -- Skip this test if we're in a test environment without real himalaya access
  local test_cmd = 'himalaya --version'
  local test_output = vim.fn.system(test_cmd)
  local test_exit = vim.v.shell_error
  
  if test_exit ~= 0 then
    return { skipped = true, reason = "Himalaya CLI not available in test environment" }
  end
  
  -- Wait a moment for any pending async operations
  vim.wait(1000, function() return false end)
  
  -- Use himalaya CLI to check drafts folder
  local cmd = 'himalaya envelope list --account gmail --folder "Drafts" --output json 2>/dev/null'
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 then
    return { skipped = true, reason = "Gmail account not configured in test environment" }
  end
  
  local ok, drafts = pcall(vim.fn.json_decode, output)
  assert.truthy(ok, "Should be able to parse drafts JSON")
  assert.truthy(type(drafts) == 'table', "Drafts should be a table")
  
  -- Count test drafts (subject contains "Draft Test" or "Test Draft")
  local test_draft_count = 0
  for _, draft in ipairs(drafts) do
    if draft.subject and (draft.subject:match('Draft Test') or draft.subject:match('Test Draft')) then
      test_draft_count = test_draft_count + 1
    end
  end
  
  -- Should find at least 1 draft from the previous tests
  assert.truthy(test_draft_count >= 1, 
    string.format("Should find at least 1 test draft, found %d", test_draft_count))
  
  -- Store count for cleanup test
  _G.test_draft_count = test_draft_count
end))

-- Test 5: Clean up test drafts (always runs last)
table.insert(tests, framework.create_test('cleanup_drafts', function()
  -- List and delete test drafts
  local cmd = 'himalaya envelope list --account gmail --folder "Drafts" --output json'
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 then
    return -- Skip cleanup if can't list
  end
  
  local ok, drafts = pcall(vim.fn.json_decode, output)
  if not ok or type(drafts) ~= 'table' then
    return -- Skip cleanup if can't parse
  end
  
  local draft_ids = {}
  for _, draft in ipairs(drafts) do
    if draft.subject and (draft.subject:match('Draft Test') or draft.subject:match('Test Draft')) then
      table.insert(draft_ids, draft.id)
    end
  end
  
  if #draft_ids > 0 then
    local delete_cmd = string.format(
      'himalaya message delete %s --account gmail --folder "Drafts"',
      table.concat(draft_ids, ' ')
    )
    local delete_output = vim.fn.system(delete_cmd)
    local delete_exit = vim.v.shell_error
    
    -- Verify cleanup worked
    assert.equals(delete_exit, 0, "Should be able to delete test drafts: " .. delete_output)
  end
end))

-- Export test suite with metadata
_G.himalaya_test = framework.create_suite('Draft Saving Feature', tests)
_G.himalaya_test.test_metadata = test_metadata
_G.himalaya_test.get_test_count = function() return test_metadata.count end
_G.himalaya_test.get_test_list = function()
  return {
    "Draft folder detection",
    "Save draft function",
    "Composer draft saving",
    "Drafts in maildir",
    "Cleanup drafts"
  }
end

return _G.himalaya_test
