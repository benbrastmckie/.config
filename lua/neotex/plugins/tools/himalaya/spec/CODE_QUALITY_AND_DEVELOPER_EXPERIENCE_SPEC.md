# Himalaya Code Quality and Developer Experience Specification

**Cross-Phase Implementation**  
*These improvements span multiple phases (6-10) of the implementation plan*

This specification details the implementation plan for code quality improvements and developer experience enhancements identified in the technical debt analysis and features specification.

## Phase Mapping

- **Phase 6**: Enhanced Error Handling (#1) - Core error module
- **Phase 7**: API Consistency (#2), Observability/Logging (#5)  
- **Phase 8**: Performance Optimizations (#3) - Applied during feature work
- **Phase 10**: Testing Infrastructure (#4), Further Modularization (#6)

## Overview

The code quality and developer experience improvements focus on establishing robust development practices, improving code maintainability, and providing better tools for debugging and performance analysis.

## Implementation Details

### 1. Enhanced Error Handling Module

**Priority**: High  
**Estimated Effort**: 3-4 days

#### 1.1 Centralized Error System

Create `core/errors.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Error type definitions
M.types = {
  -- Network errors
  NETWORK_ERROR = 'network_error',
  CONNECTION_TIMEOUT = 'connection_timeout',
  DNS_RESOLUTION_FAILED = 'dns_resolution_failed',
  
  -- Authentication errors  
  AUTH_FAILED = 'auth_failed',
  OAUTH_EXPIRED = 'oauth_expired',
  OAUTH_REFRESH_FAILED = 'oauth_refresh_failed',
  INVALID_CREDENTIALS = 'invalid_credentials',
  TWO_FACTOR_REQUIRED = 'two_factor_required',
  
  -- Command execution errors
  COMMAND_NOT_FOUND = 'command_not_found',
  COMMAND_FAILED = 'command_failed',
  INVALID_ARGUMENTS = 'invalid_arguments',
  
  -- Email operation errors
  EMAIL_NOT_FOUND = 'email_not_found',
  EMAIL_SEND_FAILED = 'email_send_failed',
  EMAIL_PARSE_ERROR = 'email_parse_error',
  ATTACHMENT_TOO_LARGE = 'attachment_too_large',
  
  -- Sync errors
  SYNC_FAILED = 'sync_failed',
  SYNC_CONFLICT = 'sync_conflict',
  SYNC_IN_PROGRESS = 'sync_in_progress',
  
  -- UI errors
  WINDOW_CREATION_FAILED = 'window_creation_failed',
  INVALID_BUFFER = 'invalid_buffer',
  UI_RENDER_ERROR = 'ui_render_error',
  
  -- Configuration errors
  CONFIG_INVALID = 'config_invalid',
  CONFIG_MISSING = 'config_missing',
  ACCOUNT_NOT_FOUND = 'account_not_found',
  
  -- State errors
  STATE_CORRUPTED = 'state_corrupted',
  STATE_VERSION_MISMATCH = 'state_version_mismatch',
  
  -- System errors
  PERMISSION_DENIED = 'permission_denied',
  DISK_FULL = 'disk_full',
  OUT_OF_MEMORY = 'out_of_memory'
}

-- Error severity levels
M.severity = {
  FATAL = 'fatal',      -- Unrecoverable, requires restart
  ERROR = 'error',      -- Recoverable with user intervention  
  WARNING = 'warning',  -- Degraded functionality
  INFO = 'info'        -- Informational only
}

-- Error context structure
local error_schema = {
  type = "",           -- Error type from M.types
  message = "",        -- User-friendly message
  details = "",        -- Technical details
  severity = "",       -- Severity level
  context = {},        -- Additional context data
  timestamp = 0,       -- When error occurred
  stack = "",         -- Stack trace
  recoverable = true,  -- Whether error is recoverable
  retry_count = 0,    -- Number of retry attempts
  suggestions = {}     -- Suggested fixes
}

-- Create standardized error
function M.create_error(error_type, message, context)
  local error_info = {
    type = error_type,
    message = message,
    details = context.details or "",
    severity = context.severity or M.severity.ERROR,
    context = context,
    timestamp = os.time(),
    stack = debug.traceback("", 2),
    recoverable = context.recoverable ~= false,
    retry_count = context.retry_count or 0,
    suggestions = context.suggestions or {}
  }
  
  -- Add default suggestions based on error type
  if #error_info.suggestions == 0 then
    error_info.suggestions = M.get_default_suggestions(error_type)
  end
  
  return error_info
end

-- Get default suggestions for error types
function M.get_default_suggestions(error_type)
  local suggestions = {
    [M.types.OAUTH_EXPIRED] = {
      "Run :HimalayaSetup to refresh OAuth token",
      "Check if refresh token is still valid"
    },
    [M.types.CONNECTION_TIMEOUT] = {
      "Check your internet connection",
      "Verify firewall settings",
      "Try again in a few moments"
    },
    [M.types.CONFIG_INVALID] = {
      "Run :HimalayaSetup to reconfigure",
      "Check ~/.config/himalaya/config.toml"
    },
    [M.types.COMMAND_NOT_FOUND] = {
      "Install himalaya: cargo install himalaya",
      "Check if himalaya is in your PATH"
    }
  }
  
  return suggestions[error_type] or {}
end

-- Error recovery strategies
local recovery_strategies = {
  [M.types.OAUTH_EXPIRED] = function(error)
    logger.info("Attempting OAuth token refresh")
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    local success = oauth.refresh_token()
    
    if success then
      notify.himalaya(
        "OAuth token refreshed successfully",
        notify.categories.STATUS
      )
      return true
    end
    return false
  end,
  
  [M.types.CONNECTION_TIMEOUT] = function(error)
    if error.retry_count < 3 then
      local delay = math.pow(2, error.retry_count) * 1000
      logger.info(string.format("Retrying after %dms", delay))
      
      vim.defer_fn(function()
        if error.context.retry_callback then
          error.context.retry_callback()
        end
      end, delay)
      return true
    end
    return false
  end,
  
  [M.types.STATE_CORRUPTED] = function(error)
    logger.warn("Attempting to recover from corrupted state")
    local state = require('neotex.plugins.tools.himalaya.core.state')
    return state.reset_to_defaults()
  end
}

-- Handle error with recovery
function M.handle_error(error, custom_recovery)
  -- Log error
  logger.error(
    string.format("[%s] %s", error.type, error.message),
    error.context
  )
  
  -- Notify user based on severity
  local notify_category = ({
    [M.severity.FATAL] = notify.categories.ERROR,
    [M.severity.ERROR] = notify.categories.ERROR,
    [M.severity.WARNING] = notify.categories.WARNING,
    [M.severity.INFO] = notify.categories.STATUS
  })[error.severity]
  
  -- Build notification message with suggestions
  local notify_msg = error.message
  if #error.suggestions > 0 then
    notify_msg = notify_msg .. "\n\nSuggestions:\n" .. 
      table.concat(error.suggestions, "\n")
  end
  
  notify.himalaya(notify_msg, notify_category, {
    error_type = error.type,
    details = error.details
  })
  
  -- Attempt recovery
  if error.recoverable then
    local recovery = custom_recovery or recovery_strategies[error.type]
    if recovery then
      local recovered = recovery(error)
      if recovered then
        notify.himalaya(
          "Error recovered successfully",
          notify.categories.STATUS
        )
        return true
      end
    end
  end
  
  -- Fatal errors should stop execution
  if error.severity == M.severity.FATAL then
    error(error.message)
  end
  
  return false
end

-- Wrap function with error handling
function M.wrap(fn, error_type, context)
  return function(...)
    local args = {...}
    local success, result = pcall(fn, unpack(args))
    
    if not success then
      local error_info = M.create_error(
        error_type or M.types.COMMAND_FAILED,
        result,
        vim.tbl_extend('force', context or {}, {
          details = result,
          recoverable = true
        })
      )
      
      M.handle_error(error_info)
      return nil, error_info
    end
    
    return result
  end
end

-- Batch error reporting
local error_batch = {}
local batch_timer = nil

function M.batch_error(error_info)
  table.insert(error_batch, error_info)
  
  if batch_timer then
    batch_timer:stop()
  end
  
  batch_timer = vim.defer_fn(function()
    if #error_batch > 0 then
      M.report_batch_errors()
    end
  end, 1000)
end

function M.report_batch_errors()
  if #error_batch == 0 then
    return
  end
  
  -- Group errors by type
  local grouped = {}
  for _, error in ipairs(error_batch) do
    grouped[error.type] = grouped[error.type] or {}
    table.insert(grouped[error.type], error)
  end
  
  -- Report grouped errors
  for error_type, errors in pairs(grouped) do
    notify.himalaya(
      string.format("%d %s errors occurred", #errors, error_type),
      notify.categories.ERROR,
      { 
        count = #errors,
        first_error = errors[1].message
      }
    )
  end
  
  -- Clear batch
  error_batch = {}
end

return M
```

### 2. API Consistency Layer

**Priority**: High  
**Estimated Effort**: 1 week

#### 2.1 Standardized API Module

Create `core/api.lua`:

```lua
local M = {}
local errors = require('neotex.plugins.tools.himalaya.core.errors')

-- Standard API response format
local response_schema = {
  success = false,
  data = nil,
  error = nil,
  metadata = {}
}

-- Create standardized response
function M.response(success, data, error)
  return {
    success = success,
    data = data,
    error = error,
    metadata = {
      timestamp = os.time(),
      version = M.get_api_version()
    }
  }
end

-- Success response helper
function M.success(data, metadata)
  local response = M.response(true, data, nil)
  if metadata then
    response.metadata = vim.tbl_extend('force', response.metadata, metadata)
  end
  return response
end

-- Error response helper  
function M.error(error_type, message, context)
  local error_info = errors.create_error(error_type, message, context)
  return M.response(false, nil, error_info)
end

-- Parameter validation
function M.validate_params(params, schema)
  local validated = {}
  local errors_found = {}
  
  for field, rules in pairs(schema) do
    local value = params[field]
    
    -- Check required fields
    if rules.required and value == nil then
      table.insert(errors_found, 
        string.format("Missing required parameter: %s", field))
    end
    
    -- Check type
    if value ~= nil and rules.type then
      local value_type = type(value)
      if value_type ~= rules.type then
        table.insert(errors_found,
          string.format("Invalid type for %s: expected %s, got %s",
            field, rules.type, value_type))
      end
    end
    
    -- Check enum values
    if value ~= nil and rules.enum then
      if not vim.tbl_contains(rules.enum, value) then
        table.insert(errors_found,
          string.format("Invalid value for %s: must be one of %s",
            field, table.concat(rules.enum, ", ")))
      end
    end
    
    -- Custom validation
    if value ~= nil and rules.validate then
      local valid, err = rules.validate(value)
      if not valid then
        table.insert(errors_found,
          string.format("Validation failed for %s: %s", field, err))
      end
    end
    
    -- Set default if missing
    if value == nil and rules.default ~= nil then
      value = rules.default
    end
    
    validated[field] = value
  end
  
  if #errors_found > 0 then
    return nil, errors_found
  end
  
  return validated, nil
end

-- Create API method with validation
function M.create_method(name, schema, handler)
  return function(params)
    -- Validate parameters
    local validated, validation_errors = M.validate_params(params or {}, schema)
    
    if validation_errors then
      return M.error(
        errors.types.INVALID_ARGUMENTS,
        "Parameter validation failed",
        { errors = validation_errors }
      )
    end
    
    -- Execute handler with error handling
    local success, result = pcall(handler, validated)
    
    if success then
      return result
    else
      return M.error(
        errors.types.COMMAND_FAILED,
        string.format("%s failed: %s", name, result),
        { method = name }
      )
    end
  end
end

-- Module facade creator
function M.create_facade(module_name, methods)
  local facade = {
    _module = module_name,
    _version = "1.0.0"
  }
  
  -- Add standardized methods
  for method_name, definition in pairs(methods) do
    facade[method_name] = M.create_method(
      method_name,
      definition.params or {},
      definition.handler
    )
  end
  
  -- Add metadata methods
  function facade:get_info()
    return {
      module = self._module,
      version = self._version,
      methods = vim.tbl_keys(methods)
    }
  end
  
  return facade
end

-- Type annotations helper
function M.annotate(fn, input_types, output_type)
  -- This is mainly for documentation and IDE support
  fn._himalaya_types = {
    input = input_types,
    output = output_type
  }
  return fn
end

return M
```

#### 2.2 Module Facades

Create standardized facades for each module:

```lua
-- core/facades/email.lua
local api = require('neotex.plugins.tools.himalaya.core.api')
local email_core = require('neotex.plugins.tools.himalaya.core.commands.email')

return api.create_facade('email', {
  list = {
    params = {
      folder = { type = "string", required = true },
      page = { type = "number", default = 1 },
      limit = { type = "number", default = 50 }
    },
    handler = function(params)
      local emails = email_core.list_emails(
        params.folder, 
        params.page, 
        params.limit
      )
      return api.success(emails)
    end
  },
  
  send = {
    params = {
      to = { type = "table", required = true },
      subject = { type = "string", required = true },
      body = { type = "string", required = true },
      cc = { type = "table", default = {} },
      bcc = { type = "table", default = {} },
      attachments = { type = "table", default = {} }
    },
    handler = function(params)
      local result = email_core.send_email(params)
      if result.success then
        return api.success({ message_id = result.message_id })
      else
        return api.error(
          errors.types.EMAIL_SEND_FAILED,
          result.error
        )
      end
    end
  }
})
```

### 3. Performance Optimizations

**Priority**: Medium  
**Estimated Effort**: 1 week

#### 3.1 Performance Module

Create `core/performance.lua`:

```lua
local M = {}
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Performance tracking
local metrics = {}
local timers = {}

-- Start timing an operation
function M.start_timer(operation_name)
  timers[operation_name] = vim.loop.hrtime()
end

-- Stop timer and record metric
function M.stop_timer(operation_name)
  if not timers[operation_name] then
    return
  end
  
  local duration = (vim.loop.hrtime() - timers[operation_name]) / 1e6
  timers[operation_name] = nil
  
  -- Record metric
  metrics[operation_name] = metrics[operation_name] or {
    count = 0,
    total_ms = 0,
    min_ms = math.huge,
    max_ms = 0,
    samples = {}
  }
  
  local metric = metrics[operation_name]
  metric.count = metric.count + 1
  metric.total_ms = metric.total_ms + duration
  metric.min_ms = math.min(metric.min_ms, duration)
  metric.max_ms = math.max(metric.max_ms, duration)
  
  -- Keep last 100 samples for percentile calculations
  table.insert(metric.samples, duration)
  if #metric.samples > 100 then
    table.remove(metric.samples, 1)
  end
  
  -- Log slow operations
  if duration > 1000 then
    logger.warn(string.format(
      "Slow operation: %s took %.2fms",
      operation_name, duration
    ))
  end
  
  return duration
end

-- Measure function performance
function M.measure(name, fn)
  return function(...)
    M.start_timer(name)
    local results = {pcall(fn, ...)}
    local duration = M.stop_timer(name)
    
    if not results[1] then
      error(results[2])
    end
    
    return unpack(results, 2)
  end
end

-- Get performance statistics
function M.get_stats(operation_name)
  local metric = metrics[operation_name]
  if not metric or metric.count == 0 then
    return nil
  end
  
  -- Calculate percentiles
  local sorted = vim.deepcopy(metric.samples)
  table.sort(sorted)
  
  local p50_idx = math.floor(#sorted * 0.5)
  local p95_idx = math.floor(#sorted * 0.95)
  local p99_idx = math.floor(#sorted * 0.99)
  
  return {
    count = metric.count,
    avg_ms = metric.total_ms / metric.count,
    min_ms = metric.min_ms,
    max_ms = metric.max_ms,
    p50_ms = sorted[p50_idx] or 0,
    p95_ms = sorted[p95_idx] or 0,
    p99_ms = sorted[p99_idx] or 0
  }
end

-- Performance report
function M.generate_report()
  local report = {
    "Performance Report",
    "==================",
    ""
  }
  
  for op_name, _ in pairs(metrics) do
    local stats = M.get_stats(op_name)
    if stats then
      table.insert(report, string.format(
        "%s:",
        op_name
      ))
      table.insert(report, string.format(
        "  Calls: %d | Avg: %.2fms | P95: %.2fms | Max: %.2fms",
        stats.count, stats.avg_ms, stats.p95_ms, stats.max_ms
      ))
    end
  end
  
  return table.concat(report, "\n")
end

-- Cache implementation with TTL
local cache = {}

function M.cache(key, ttl_seconds, generator)
  local cached = cache[key]
  
  if cached and os.time() - cached.timestamp < ttl_seconds then
    return cached.value
  end
  
  local value = generator()
  cache[key] = {
    value = value,
    timestamp = os.time()
  }
  
  return value
end

-- Lazy loading helper
function M.lazy_require(module_name)
  local module = nil
  return setmetatable({}, {
    __index = function(_, key)
      if not module then
        M.start_timer("lazy_load_" .. module_name)
        module = require(module_name)
        M.stop_timer("lazy_load_" .. module_name)
      end
      return module[key]
    end
  })
end

-- Memory profiling
function M.memory_usage()
  collectgarbage("collect")
  local memory_kb = collectgarbage("count")
  return {
    total_kb = memory_kb,
    total_mb = memory_kb / 1024,
    lua_objects = collectgarbage("count")
  }
end

-- Optimization suggestions
function M.analyze_performance()
  local suggestions = {}
  
  -- Check for slow operations
  for op_name, _ in pairs(metrics) do
    local stats = M.get_stats(op_name)
    if stats and stats.avg_ms > 100 then
      table.insert(suggestions, {
        operation = op_name,
        issue = "Slow average time",
        suggestion = string.format(
          "Consider optimizing %s (avg: %.2fms)",
          op_name, stats.avg_ms
        )
      })
    end
  end
  
  -- Check memory usage
  local memory = M.memory_usage()
  if memory.total_mb > 50 then
    table.insert(suggestions, {
      operation = "memory",
      issue = "High memory usage",
      suggestion = string.format(
        "Memory usage is %.2fMB, consider cleanup",
        memory.total_mb
      )
    })
  end
  
  return suggestions
end

return M
```

### 4. Testing Infrastructure

**Priority**: High  
**Estimated Effort**: 1 week

#### 4.1 Test Framework

Create `test/framework.lua`:

```lua
local M = {}

-- Test state
local tests = {}
local results = {
  passed = 0,
  failed = 0,
  skipped = 0,
  errors = {}
}

-- Test definition
function M.describe(suite_name, suite_fn)
  tests[suite_name] = tests[suite_name] or {}
  local current_suite = tests[suite_name]
  
  -- Test case definition
  local function it(test_name, test_fn)
    current_suite[test_name] = test_fn
  end
  
  -- Skip test
  local function skip(test_name, test_fn)
    current_suite[test_name] = {
      fn = test_fn,
      skip = true
    }
  end
  
  -- Run suite definition
  suite_fn(it, skip)
end

-- Assertions
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
  
  deep_equals = function(actual, expected, message)
    if not vim.deep_equal(actual, expected) then
      error(string.format(
        "%s\nExpected: %s\nActual: %s",
        message or "Tables not equal",
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
    if not vim.tbl_contains(table, value) then
      error(string.format(
        "%s\nTable does not contain: %s",
        message or "Value not found",
        vim.inspect(value)
      ))
    end
  end,
  
  matches = function(str, pattern, message)
    if not str:match(pattern) then
      error(string.format(
        "%s\nString '%s' does not match pattern '%s'",
        message or "Pattern not matched",
        str, pattern
      ))
    end
  end
}

-- Mock creation
function M.mock(module_name)
  local mock = {
    _calls = {},
    _module = module_name
  }
  
  return setmetatable(mock, {
    __index = function(t, key)
      return function(...)
        table.insert(t._calls, {
          method = key,
          args = {...},
          timestamp = os.time()
        })
        
        -- Return mock response if defined
        if t._responses and t._responses[key] then
          return t._responses[key](...)
        end
      end
    end
  })
end

-- Spy on existing function
function M.spy(obj, method_name)
  local original = obj[method_name]
  local calls = {}
  
  obj[method_name] = function(...)
    table.insert(calls, {args = {...}})
    return original(...)
  end
  
  return {
    calls = calls,
    restore = function()
      obj[method_name] = original
    end
  }
end

-- Run tests
function M.run(pattern)
  results = { passed = 0, failed = 0, skipped = 0, errors = {} }
  
  for suite_name, suite in pairs(tests) do
    if not pattern or suite_name:match(pattern) then
      print(string.format("\n%s", suite_name))
      
      for test_name, test_info in pairs(suite) do
        local test_fn = type(test_info) == "function" and test_info or test_info.fn
        local skip = type(test_info) == "table" and test_info.skip
        
        if skip then
          results.skipped = results.skipped + 1
          print(string.format("  ⊘ %s (skipped)", test_name))
        else
          local success, err = pcall(test_fn)
          
          if success then
            results.passed = results.passed + 1
            print(string.format("  ✓ %s", test_name))
          else
            results.failed = results.failed + 1
            table.insert(results.errors, {
              suite = suite_name,
              test = test_name,
              error = err
            })
            print(string.format("  ✗ %s", test_name))
            print(string.format("    %s", err))
          end
        end
      end
    end
  end
  
  -- Print summary
  print(string.format(
    "\nTests: %d passed, %d failed, %d skipped",
    results.passed, results.failed, results.skipped
  ))
  
  return results
end

-- Integration with vim-test
function M.setup_vim_test()
  vim.g["test#custom_runners"] = {
    lua = {"himalaya"}
  }
  
  vim.g["test#lua#himalaya#executable"] = "nvim -c 'lua require(\"test.runner\").run()'"
end

return M
```

#### 4.2 Example Tests

Create `test/unit/email_test.lua`:

```lua
local test = require('test.framework')
local mock = test.mock

test.describe("Email Operations", function(it, skip)
  
  it("should parse email addresses correctly", function()
    local email = require('neotex.plugins.tools.himalaya.core.commands.email')
    
    local cases = {
      {
        input = "user@example.com",
        expected = { email = "user@example.com" }
      },
      {
        input = '"John Doe" <john@example.com>',
        expected = { name = "John Doe", email = "john@example.com" }
      }
    }
    
    for _, case in ipairs(cases) do
      local result = email.parse_address(case.input)
      test.assert.deep_equals(result, case.expected)
    end
  end)
  
  it("should validate email format", function()
    local validator = require('neotex.plugins.tools.himalaya.utils')
    
    test.assert.truthy(validator.is_valid_email("user@example.com"))
    test.assert.truthy(validator.is_valid_email("user.name+tag@example.co.uk"))
    test.assert.falsy(validator.is_valid_email("invalid.email"))
    test.assert.falsy(validator.is_valid_email("@example.com"))
  end)
  
  it("should handle email send errors gracefully", function()
    local email = require('neotex.plugins.tools.himalaya.core.commands.email')
    local utils_mock = mock('utils')
    
    -- Mock failed command
    utils_mock._responses.execute_command = function()
      return { success = false, error = "SMTP connection failed" }
    end
    
    local result = email.send({
      to = {"test@example.com"},
      subject = "Test",
      body = "Test email"
    })
    
    test.assert.falsy(result.success)
    test.assert.matches(result.error, "SMTP")
  end)
  
end)
```

### 5. Observability

**Priority**: Medium  
**Estimated Effort**: 3-4 days

#### 5.1 Enhanced Logging

Update `core/logger.lua`:

```lua
local M = {}
local notify = require('neotex.util.notifications')

-- Logger configuration
M.config = {
  level = vim.log.levels.DEBUG,
  file = vim.fn.stdpath('data') .. '/himalaya/himalaya.log',
  max_file_size = 10 * 1024 * 1024, -- 10MB
  max_files = 5,
  format = "[%s] [%s] %s", -- timestamp, level, message
  enable_performance = true,
  enable_trace = false,
  filters = {
    debug = true,
    sync = true,
    ui = true,
    email = true,
    performance = true
  }
}

-- Log levels
local levels = {
  TRACE = { value = 0, name = "TRACE" },
  DEBUG = { value = 1, name = "DEBUG" },
  INFO = { value = 2, name = "INFO" },
  WARN = { value = 3, name = "WARN" },
  ERROR = { value = 4, name = "ERROR" }
}

-- Initialize logger
function M.init()
  -- Create log directory
  vim.fn.mkdir(vim.fn.fnamemodify(M.config.file, ':h'), 'p')
  
  -- Set up log rotation
  M.setup_rotation()
  
  -- Set up performance tracking
  if M.config.enable_performance then
    M.setup_performance_tracking()
  end
end

-- Log rotation
function M.rotate_logs()
  local size = vim.fn.getfsize(M.config.file)
  
  if size > M.config.max_file_size then
    -- Rotate existing logs
    for i = M.config.max_files - 1, 1, -1 do
      local old = string.format("%s.%d", M.config.file, i)
      local new = string.format("%s.%d", M.config.file, i + 1)
      if vim.fn.filereadable(old) == 1 then
        vim.fn.rename(old, new)
      end
    end
    
    -- Move current to .1
    vim.fn.rename(M.config.file, M.config.file .. ".1")
    
    -- Notify about rotation
    notify.himalaya(
      "Log file rotated",
      notify.categories.BACKGROUND,
      { size_mb = size / (1024 * 1024) }
    )
  end
end

-- Core logging function
function M.log(level, message, context, category)
  -- Check if should log
  if level.value < M.config.level then
    return
  end
  
  -- Check category filter
  if category and not M.config.filters[category] then
    return
  end
  
  -- Format message
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_entry = string.format(
    M.config.format,
    timestamp,
    level.name,
    message
  )
  
  -- Add context if provided
  if context then
    log_entry = log_entry .. " | " .. vim.inspect(context)
  end
  
  -- Add trace if enabled
  if M.config.enable_trace and level.value >= levels.WARN.value then
    log_entry = log_entry .. "\n" .. debug.traceback("", 2)
  end
  
  -- Write to file
  local file = io.open(M.config.file, "a")
  if file then
    file:write(log_entry .. "\n")
    file:close()
  end
  
  -- Check rotation
  M.rotate_logs()
end

-- Convenience methods
function M.trace(message, context, category)
  M.log(levels.TRACE, message, context, category)
end

function M.debug(message, context, category)
  M.log(levels.DEBUG, message, context, category)
end

function M.info(message, context, category)
  M.log(levels.INFO, message, context, category)
end

function M.warn(message, context, category)
  M.log(levels.WARN, message, context, category)
end

function M.error(message, context, category)
  M.log(levels.ERROR, message, context, category)
end

-- Performance tracking
function M.setup_performance_tracking()
  local performance = require('neotex.plugins.tools.himalaya.core.performance')
  
  -- Log slow operations automatically
  local original_stop = performance.stop_timer
  performance.stop_timer = function(operation_name)
    local duration = original_stop(operation_name)
    
    if duration and duration > 100 then
      M.debug(
        string.format("Operation '%s' took %.2fms", operation_name, duration),
        { duration_ms = duration },
        'performance'
      )
    end
    
    return duration
  end
end

-- Debug mode toggle
function M.toggle_debug_mode()
  if M.config.level == levels.DEBUG.value then
    M.config.level = levels.INFO.value
    notify.himalaya("Debug logging disabled", notify.categories.STATUS)
  else
    M.config.level = levels.DEBUG.value
    notify.himalaya("Debug logging enabled", notify.categories.STATUS)
  end
end

-- Get recent log entries
function M.get_recent_logs(count, filter)
  count = count or 50
  local logs = {}
  
  local file = io.open(M.config.file, "r")
  if not file then
    return logs
  end
  
  -- Read file backwards for efficiency
  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  
  -- Get last N lines matching filter
  for i = #lines, math.max(1, #lines - count * 2), -1 do
    local line = lines[i]
    if not filter or line:match(filter) then
      table.insert(logs, 1, line)
      if #logs >= count then
        break
      end
    end
  end
  
  return logs
end

-- Log viewer command
function M.show_logs(filter)
  local logs = M.get_recent_logs(100, filter)
  
  -- Create log viewer buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, logs)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalayalog')
  
  -- Open in split
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "Himalaya Logs")
  
  -- Add keymaps
  vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf })
  vim.keymap.set('n', 'R', function()
    local new_logs = M.get_recent_logs(100, filter)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_logs)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end, { buffer = buf })
end

return M
```

### 6. Further Modularization

**Priority**: High  
**Estimated Effort**: 1 week

#### 6.1 Commands Modularization

Split the monolithic `commands.lua` into focused modules as outlined in the cleanup spec.

#### 6.2 UI Main Modularization

Split `ui/main.lua` into:

```lua
-- ui/main.lua (orchestrator only)
local M = {}

-- Lazy load UI components
M.components = {
  sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar'),
  email_list = require('neotex.plugins.tools.himalaya.ui.email_list'),
  email_viewer = require('neotex.plugins.tools.himalaya.ui.email_viewer'),
  email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer'),
  email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview'),
  window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager'),
  state_manager = require('neotex.plugins.tools.himalaya.ui.state_manager')
}

function M.setup()
  -- Initialize window manager
  M.components.window_manager.init()
  
  -- Set up state management
  M.components.state_manager.init()
  
  -- Register UI commands
  M.register_commands()
end

function M.open(folder)
  -- Delegate to appropriate component
  M.components.sidebar.open()
  
  if folder then
    M.components.email_list.show_folder(folder)
  end
end

return M
```

## Implementation Schedule

### Week 1: Foundation
- Enhanced error handling module
- API consistency layer
- Basic testing framework

### Week 2: Performance & Observability
- Performance optimizations
- Enhanced logging system
- Debug mode implementation

### Week 3: Testing & Modularization
- Complete test suite
- Modularize commands.lua
- Modularize ui/main.lua

### Week 4: Integration & Polish
- Integration testing
- Performance profiling
- Documentation updates

## Success Metrics

1. **Error Handling**: 100% of operations wrapped with error handling
2. **API Consistency**: All public APIs follow standard format
3. **Performance**: < 100ms for common operations
4. **Test Coverage**: > 80% code coverage
5. **Logging**: Comprehensive debug information available
6. **Modularity**: No module > 500 lines

## Deliverables

1. Centralized error handling system
2. Standardized API layer
3. Performance monitoring tools
4. Comprehensive test suite
5. Enhanced logging with rotation
6. Modularized codebase
7. Developer documentation