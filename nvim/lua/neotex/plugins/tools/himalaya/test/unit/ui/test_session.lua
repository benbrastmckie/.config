-- Unit tests for session management module

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = test_framework.assert

local M = {}

-- Test metadata
M.test_metadata = {
  name = "Session Management Tests",
  description = "Tests for session management and state handling",
  count = 10,
  category = "unit",
  tags = {"ui", "session", "state-management"},
  estimated_duration_ms = 300
}

function M.test_session_init()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  
  -- Test initialization
  local success = pcall(session.init)
  assert.truthy(success, 'Session should initialize without error')
end

function M.test_session_init_with_config()
  _G.HIMALAYA_TEST_MODE = true
  
  -- Clear any existing module state
  package.loaded['neotex.plugins.tools.himalaya.ui.session'] = nil
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  
  local test_config = {
    session = {
      auto_restore = true,
      file = '/tmp/test_session.json'
    }
  }
  
  local success = pcall(session.init, test_config)
  assert.truthy(success, 'Session should initialize with config')
  
  assert.truthy(session.is_auto_restore_enabled(), 'Auto restore should be enabled')
end

function M.test_auto_restore_toggle()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  session.init()
  
  -- Test default state
  assert.falsy(session.is_auto_restore_enabled(), 'Auto restore should be disabled by default')
  
  -- Test enabling
  session.set_auto_restore(true)
  assert.truthy(session.is_auto_restore_enabled(), 'Auto restore should be enabled')
  
  -- Test disabling
  session.set_auto_restore(false)
  assert.falsy(session.is_auto_restore_enabled(), 'Auto restore should be disabled')
end

function M.test_save_session()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  local state = require('neotex.plugins.tools.himalaya.core.state')
  
  -- Initialize with test session file
  session.init({
    session = {
      file = '/tmp/test_himalaya_session.json'
    }
  })
  
  -- Set up some test state
  state.init()
  state.set_current_account('test@example.com')
  state.set_current_folder('INBOX')
  state.set_current_page(2)
  
  -- Test saving session
  local success = session.save_session()
  assert.truthy(success, 'Session should save successfully')
  
  -- Verify file was created
  local file_exists = vim.fn.filereadable('/tmp/test_himalaya_session.json') == 1
  assert.truthy(file_exists, 'Session file should be created')
  
  -- Clean up
  vim.fn.delete('/tmp/test_himalaya_session.json')
end

function M.test_restore_session_disabled()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  session.init()
  
  -- Auto-restore is disabled by default
  local restored = session.restore_session()
  assert.falsy(restored, 'Should not restore when auto-restore is disabled')
end

function M.test_restore_session_no_file()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  
  session.init({
    session = {
      auto_restore = true,
      file = '/tmp/nonexistent_session.json'
    }
  })
  
  local restored = session.restore_session()
  assert.falsy(restored, 'Should not restore when session file does not exist')
end

function M.test_session_info_no_file()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  session.init({
    session = {
      file = '/tmp/nonexistent_session.json'
    }
  })
  
  local info = session.get_session_info()
  assert.is_table(info, 'Should return table')
  assert.falsy(info.exists, 'Should indicate file does not exist')
end

function M.test_session_save_and_info()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  local state = require('neotex.plugins.tools.himalaya.core.state')
  
  session.init({
    session = {
      file = '/tmp/test_session_info.json'
    }
  })
  
  -- Set up test state
  state.init()
  state.set_current_account('test@example.com')
  state.set_current_folder('INBOX')
  
  -- Save session
  session.save_session()
  
  -- Get session info
  local info = session.get_session_info()
  assert.is_table(info, 'Should return session info')
  assert.truthy(info.exists, 'Should indicate file exists')
  assert.equals(info.account, 'test@example.com', 'Should contain account info')
  assert.equals(info.folder, 'INBOX', 'Should contain folder info')
  assert.is_number(info.timestamp, 'Should have timestamp')
  assert.is_number(info.age_hours, 'Should calculate age')
  
  -- Clean up
  vim.fn.delete('/tmp/test_session_info.json')
end

function M.test_clear_session()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  
  session.init({
    session = {
      file = '/tmp/test_clear_session.json'
    }
  })
  
  -- Create a test session file
  local file = io.open('/tmp/test_clear_session.json', 'w')
  file:write('{"test": "data"}')
  file:close()
  
  -- Clear session
  local success = session.clear_session()
  assert.truthy(success, 'Should clear session successfully')
  
  -- Verify file was deleted
  local file_exists = vim.fn.filereadable('/tmp/test_clear_session.json') == 1
  assert.falsy(file_exists, 'Session file should be deleted')
end

function M.test_clear_nonexistent_session()
  _G.HIMALAYA_TEST_MODE = true
  
  local session = require('neotex.plugins.tools.himalaya.ui.session')
  
  session.init({
    session = {
      file = '/tmp/nonexistent_clear_session.json'
    }
  })
  
  -- Clear non-existent session should succeed
  local success = session.clear_session()
  assert.truthy(success, 'Should handle clearing non-existent session')
end

-- Add standardized interface

return M