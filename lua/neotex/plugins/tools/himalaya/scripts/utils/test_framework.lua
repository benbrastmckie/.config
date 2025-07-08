-- Test Framework Utilities for Himalaya Plugin
-- Provides assertions, helpers, and mock utilities for tests

local M = {}

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
  
  -- Create test email data
  create_test_email = function(overrides)
    local email = {
      id = "test-" .. os.time(),
      subject = "Test Email",
      from = { name = "Test Sender", email = "sender@test.com" },
      to = { { name = "Test Recipient", email = "recipient@test.com" } },
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

-- Test runner helper
M.create_test = function(name, fn)
  return {
    name = name,
    run = function()
      local start = vim.loop.hrtime()
      local ok, err = pcall(fn)
      local duration = (vim.loop.hrtime() - start) / 1e6
      
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

-- Export for test files
_G.himalaya_test_framework = M

return M