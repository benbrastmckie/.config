-- Test Framework Utilities for Himalaya Plugin
-- Provides assertions, helpers, and mock utilities for tests

local M = {}

-- Load performance monitoring
local performance = require('neotex.plugins.tools.himalaya.test.utils.test_performance')

-- Test assertions
M.assert = {
  equals = function(actual, expected, message)
    if actual ~= expected then
      error(string.format(
        "%s\nExpected: %s\nActual: %s",
        message or "Values not equal",
        vim.inspect(expected),
        vim.inspect(actual)
      ))
    end
  end,
  
  truthy = function(value, message)
    if not value then
      error(message or "Expected truthy value")
    end
  end,
  
  falsy = function(value, message)
    if value then
      error(message or "Expected falsy value")
    end
  end,
  
  contains = function(table, value, message)
    for _, v in ipairs(table) do
      if v == value then
        return
      end
    end
    error(string.format(
      "%s\nTable does not contain: %s",
      message or "Value not found in table",
      vim.inspect(value)
    ))
  end,
  
  matches = function(str, pattern, message)
    if not str:match(pattern) then
      error(string.format(
        "%s\nString: %s\nDoes not match pattern: %s",
        message or "Pattern match failed",
        str,
        pattern
      ))
    end
  end,
  
  no_error = function(fn, message)
    local ok, err = pcall(fn)
    if not ok then
      error(string.format(
        "%s\nUnexpected error: %s",
        message or "Function raised an error",
        err
      ))
    end
  end,
  
  error = function(fn, expected_error, message)
    local ok, err = pcall(fn)
    if ok then
      error(message or "Expected function to raise an error")
    end
    if expected_error and not string.find(err, expected_error) then
      error(string.format(
        "%s\nExpected error containing: %s\nGot: %s",
        message or "Wrong error message",
        expected_error,
        err
      ))
    end
  end,
  
  -- Email-specific assertions
  email_headers = function(content, expected_headers, message)
    local headers = {}
    local in_headers = true
    
    for line in content:gmatch("[^\n]+") do
      if line == "" then
        in_headers = false
      elseif in_headers then
        local key, value = line:match("^([^:]+):%s*(.+)$")
        if key then
          headers[key:lower()] = value
        end
      end
    end
    
    for key, expected in pairs(expected_headers) do
      local actual = headers[key:lower()]
      if actual ~= expected then
        error(string.format(
          "%s\nEmail header mismatch for '%s'\nExpected: %s\nActual: %s\nAll headers: %s",
          message or "Email header validation failed",
          key, expected, actual or "nil", vim.inspect(headers)
        ))
      end
    end
  end,
  
  maildir_structure = function(path, message)
    local required_dirs = {'new', 'cur', 'tmp'}
    for _, dir in ipairs(required_dirs) do
      local dir_path = path .. '/' .. dir
      if vim.fn.isdirectory(dir_path) ~= 1 then
        error(string.format(
          "%s\nMissing maildir directory: %s",
          message or "Invalid maildir structure",
          dir_path
        ))
      end
    end
  end,
  
  buffer_valid = function(buf, message)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      error(string.format(
        "%s\nInvalid buffer: %s",
        message or "Buffer validation failed",
        tostring(buf)
      ))
    end
  end,
  
  file_exists = function(path, message)
    if vim.fn.filereadable(path) ~= 1 then
      error(string.format(
        "%s\nFile does not exist: %s",
        message or "File existence check failed",
        path
      ))
    end
  end,
  
  file_not_exists = function(path, message)
    if vim.fn.filereadable(path) == 1 then
      error(string.format(
        "%s\nFile unexpectedly exists: %s",
        message or "File non-existence check failed",
        path
      ))
    end
  end,
  
  performance = function(fn, max_duration_ms, message)
    local start = vim.loop.hrtime()
    local result = fn()
    local duration = (vim.loop.hrtime() - start) / 1e6
    
    if duration > max_duration_ms then
      error(string.format(
        "%s\nPerformance test failed: %.2fms (max: %dms)",
        message or "Performance assertion failed",
        duration, max_duration_ms
      ))
    end
    
    return result
  end
}

-- Test helpers
M.helpers = {
  -- Create temporary test directory
  create_temp_dir = function()
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, 'p')
    return temp_dir
  end,
  
  -- Create standardized test environment
  create_test_env = function(config_overrides)
    local env = {
      temp_dir = vim.fn.tempname() .. '_test',
      buffers = {},
      original_config = nil,
      cleanup_needed = true
    }
    
    -- Create test directory
    vim.fn.mkdir(env.temp_dir, 'p')
    
    -- Stop auto-sync timer to prevent background sync attempts during tests
    local manager = require('neotex.plugins.tools.himalaya.sync.manager')
    if manager.stop_auto_sync then
      pcall(manager.stop_auto_sync)
    end
    
    -- Also mock the auto-sync functions to prevent them from starting
    env.original_start_auto_sync = manager.start_auto_sync
    manager.start_auto_sync = function()
      -- Don't actually start auto-sync during tests
      return false
    end
    
    -- Disable notifications during tests
    env.original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      -- Silently ignore all notifications during tests
      -- This prevents the verbose test output
    end
    
    -- Also disable himalaya-specific notifications
    local notify = require('neotex.util.notifications')
    env.original_himalaya_notify = notify.himalaya
    notify.himalaya = function(msg, category, context)
      -- Silently ignore all himalaya notifications during tests
      -- This prevents "Draft saved", "Email cancelled" etc. messages
    end
    
    -- Mock himalaya command execution during tests
    local utils = require('neotex.plugins.tools.himalaya.utils')
    env.original_execute_himalaya = utils.execute_himalaya
    utils.execute_himalaya = function(args, opts)
      -- Return mock data for common commands to prevent actual CLI calls
      if args[1] == 'envelope' and args[2] == 'list' then
        return {} -- Empty email list
      elseif args[1] == 'folder' and args[2] == 'list' then
        return {} -- Empty folder list
      elseif args[1] == 'message' and args[2] == 'read' then
        return "Subject: Test\nFrom: test@example.com\n\nTest content"
      elseif args[1] == 'message' and args[2] == 'send' then
        return true -- Simulate successful send
      else
        return nil -- Other commands fail silently
      end
    end
    
    -- Instead of mocking scheduler, just prevent actual external commands
    -- The scheduler should work normally but not send real emails
    -- This way tests verify the actual implementation behavior
    
    -- Don't mock draft manager as it needs to work normally for tests
    -- Just ensure it uses the test directory
    
    -- Setup config (always provide default config)
    local config = require('neotex.plugins.tools.himalaya.core.config')
    if config.config then
      env.original_config = vim.deepcopy(config.config)
    end
    
    config.setup(vim.tbl_deep_extend('force', {
      sync = {
        maildir_root = env.temp_dir
      },
      ui = {
        auto_sync_enabled = false -- Disable auto-sync during tests
      },
      accounts = {
        TestAccount = {
          name = 'TestAccount',
          email = 'test@example.com',
          display_name = 'Test User'
        }
      },
      test_mode = true -- Global test mode flag
    }, config_overrides or {}))
    
    -- Set global test mode flag
    _G.HIMALAYA_TEST_MODE = true
    
    return env
  end,
  
  -- Cleanup standardized test environment
  cleanup_test_env = function(env)
    if not env or not env.cleanup_needed then
      return
    end
    
    -- Stop auto-sync timer to prevent background sync attempts
    local manager = require('neotex.plugins.tools.himalaya.sync.manager')
    if manager.stop_auto_sync then
      pcall(manager.stop_auto_sync)
    end
    
    -- Delete test buffers with simple cleanup
    for _, buf in ipairs(env.buffers or {}) do
      if vim.api.nvim_buf_is_valid(buf) then
        -- Try to delete the buffer directly (force = true handles displayed buffers)
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
    
    -- Also cleanup any remaining compose buffers that might have been missed
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name and name:match('compose') then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
    
    -- Close sidebar if it's open
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    if sidebar and sidebar.close then
      pcall(sidebar.close)
    end
    
    -- Restore original notification function
    if env.original_notify then
      vim.notify = env.original_notify
    end
    
    -- Restore original himalaya notification function
    if env.original_himalaya_notify then
      local notify = require('neotex.util.notifications')
      notify.himalaya = env.original_himalaya_notify
    end
    
    -- Restore original execute_himalaya function
    if env.original_execute_himalaya then
      local utils = require('neotex.plugins.tools.himalaya.utils')
      utils.execute_himalaya = env.original_execute_himalaya
    end
    
    -- No scheduler function restoration needed since we're not mocking them
    
    -- Restore original auto-sync function
    if env.original_start_auto_sync then
      local manager = require('neotex.plugins.tools.himalaya.sync.manager')
      manager.start_auto_sync = env.original_start_auto_sync
    end
    
    -- Draft manager functions not mocked, no need to restore
    
    -- Clear test mode flag
    _G.HIMALAYA_TEST_MODE = nil
    
    -- Restore original config
    if env.original_config then
      local config = require('neotex.plugins.tools.himalaya.core.config')
      config.config = env.original_config
    end
    
    -- Delete test directory
    if env.temp_dir and vim.fn.isdirectory(env.temp_dir) == 1 then
      vim.fn.delete(env.temp_dir, 'rf')
    end
    
    env.cleanup_needed = false
  end,
  
  -- Register buffer for cleanup
  register_buffer = function(env, buf)
    if env and env.buffers then
      table.insert(env.buffers, buf)
    end
    return buf
  end,
  
  -- Create test maildir structure
  create_maildir = function(path, account_name)
    local maildir_path = path .. '/' .. account_name .. '/.Drafts'
    vim.fn.mkdir(maildir_path .. '/new', 'p')
    vim.fn.mkdir(maildir_path .. '/cur', 'p')
    vim.fn.mkdir(maildir_path .. '/tmp', 'p')
    return maildir_path
  end,
  
  -- Create test email data
  create_test_email = function(overrides)
    local email = {
      id = "test-" .. os.time(),
      subject = "Test Email",
      from = "sender@test.com",  -- String format for scheduler
      to = { "recipient@test.com" },  -- Array of strings for scheduler
      date = os.date("%Y-%m-%d %H:%M:%S"),
      body = "This is a test email body.",
      folder = "INBOX",
      flags = { read = false, flagged = false }
    }
    
    if overrides then
      for k, v in pairs(overrides) do
        email[k] = v
      end
    end
    
    return email
  end,
  
  -- Create test folder structure
  create_test_folders = function()
    return {
      { name = "INBOX", messages = 10 },
      { name = "Sent", messages = 5 },
      { name = "Drafts", messages = 2 },
      { name = "Trash", messages = 0 }
    }
  end,
  
  -- Wait for async operation
  wait_for = function(condition, timeout_ms)
    timeout_ms = timeout_ms or 5000
    local start = vim.loop.hrtime()
    
    while not condition() do
      if (vim.loop.hrtime() - start) / 1e6 > timeout_ms then
        error("Timeout waiting for condition")
      end
      vim.wait(10)
    end
  end,
  
  -- Capture notifications
  capture_notifications = function(fn)
    local notifications = {}
    local original_notify = vim.notify
    
    vim.notify = function(msg, level, opts)
      table.insert(notifications, {
        message = msg,
        level = level,
        opts = opts
      })
    end
    
    local ok, result = pcall(fn)
    
    vim.notify = original_notify
    
    if not ok then
      error(result)
    end
    
    return notifications
  end
}

-- Mock utilities
M.mock = {
  -- Create a mock function
  fn = function(return_value)
    local mock = {
      calls = {},
      return_value = return_value
    }
    
    setmetatable(mock, {
      __call = function(self, ...)
        table.insert(self.calls, {...})
        if type(self.return_value) == 'function' then
          return self.return_value(...)
        else
          return self.return_value
        end
      end
    })
    
    mock.called = function(self)
      return #self.calls > 0
    end
    
    mock.call_count = function(self)
      return #self.calls
    end
    
    mock.called_with = function(self, ...)
      local args = {...}
      for _, call in ipairs(self.calls) do
        local match = true
        for i, arg in ipairs(args) do
          if call[i] ~= arg then
            match = false
            break
          end
        end
        if match then
          return true
        end
      end
      return false
    end
    
    return mock
  end,
  
  -- Mock himalaya CLI
  himalaya_cli = function(responses)
    local mock = {}
    mock.responses = responses or {}
    mock.calls = {}
    
    mock.execute = function(cmd, args)
      table.insert(mock.calls, { cmd = cmd, args = args })
      
      local key = cmd
      if args and #args > 0 then
        key = key .. " " .. table.concat(args, " ")
      end
      
      local response = mock.responses[key] or mock.responses[cmd]
      if response then
        if type(response) == 'function' then
          return response(cmd, args)
        else
          return response
        end
      end
      
      return { success = false, error = "No mock response for: " .. key }
    end
    
    return mock
  end
}

-- Enhanced test result reporting
M.create_test_result = function(name, success, error_info, context)
  local result = {
    name = name,
    success = success,
    timestamp = os.date('%Y-%m-%d %H:%M:%S'),
    context = context or {}
  }
  
  if not success then
    if type(error_info) == 'string' then
      result.error = error_info
    elseif type(error_info) == 'table' then
      result.error = error_info.message or error_info.error or 'Unknown error'
      result.error_context = error_info.context
      result.expected = error_info.expected
      result.actual = error_info.actual
    end
  end
  
  return result
end

-- Test runner helper
M.create_test = function(name, fn)
  return {
    name = name,
    run = function()
      -- Set test mode flag for all tests using create_test
      local original_test_mode = _G.HIMALAYA_TEST_MODE
      _G.HIMALAYA_TEST_MODE = true
      
      local start = vim.loop.hrtime()
      local ok, err = pcall(fn)
      local duration = (vim.loop.hrtime() - start) / 1e6
      
      -- Restore original test mode
      _G.HIMALAYA_TEST_MODE = original_test_mode
      
      if ok then
        return {
          passed = true,
          duration = duration
        }
      else
        return {
          passed = false,
          error = err,
          duration = duration
        }
      end
    end
  }
end

-- Enhanced test runner with environment management
M.create_managed_test = function(name, test_fn, config_overrides)
  return {
    name = name,
    run = function()
      local env = M.helpers.create_test_env(config_overrides)
      local monitor = performance.start_monitoring(name)
      
      local ok, result = pcall(test_fn, env)
      local perf_result = performance.end_monitoring(monitor)
      
      -- Always cleanup
      M.helpers.cleanup_test_env(env)
      
      if ok then
        return {
          passed = true,
          duration = perf_result.duration_ms,
          result = result,
          performance = perf_result
        }
      else
        return {
          passed = false,
          error = result,
          duration = perf_result.duration_ms,
          performance = perf_result
        }
      end
    end
  }
end

-- Performance-aware test function
M.create_performance_test = function(name, test_fn, performance_options)
  performance_options = performance_options or {}
  
  return {
    name = name,
    run = function()
      local success, result = performance.performance_test(name, test_fn, performance_options)
      
      if success then
        return {
          passed = true,
          duration = result.performance.duration_ms,
          result = result.result,
          performance = result.performance
        }
      else
        return {
          passed = false,
          error = result.error,
          duration = result.performance and result.performance.duration_ms or 0,
          performance = result.performance,
          performance_issues = result.issues
        }
      end
    end
  }
end

-- Test suite helper
M.create_suite = function(name, tests)
  return {
    name = name,
    run = function()
      local results = {
        total = #tests,
        passed = 0,
        failed = 0,
        errors = {}
      }
      
      for _, test in ipairs(tests) do
        local result = test.run()
        if result.passed then
          results.passed = results.passed + 1
        else
          results.failed = results.failed + 1
          table.insert(results.errors, {
            test = test.name,
            error = result.error
          })
        end
      end
      
      return results
    end
  }
end

-- Export performance utilities
M.performance = performance

-- Export for test files
_G.himalaya_test_framework = M

return M