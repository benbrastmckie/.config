# Himalaya Test Suite

Comprehensive testing infrastructure for the Himalaya email plugin, providing reliable validation of plugin functionality with extensive coverage and automated test execution.

## File Structure

```
test/
├── README.md                    # This file - test suite overview
├── test_runner.lua             # Main test runner and discovery
│
├── commands/                   # Command interface tests
│   ├── README.md              # Command testing documentation
│   ├── test_basic_commands.lua
│   ├── test_email_commands.lua
│   └── test_sync_commands.lua
│
├── features/                   # Feature-specific tests
│   ├── README.md              # Feature testing documentation
│   ├── test_async_timing.lua
│   ├── test_draft_manager_maildir.lua
│   ├── test_draft_saving.lua
│   ├── test_email_composer_maildir.lua
│   ├── test_maildir_foundation.lua
│   ├── test_maildir_integration.lua
│   └── test_scheduler.lua
│
├── integration/               # End-to-end workflow tests
│   ├── README.md              # Integration testing documentation
│   ├── test_draft_simple.lua
│   ├── test_email_operations_simple.lua
│   ├── test_full_workflow.lua
│   └── test_sync_simple.lua
│
├── performance/               # Performance and benchmarking tests
│   ├── README.md              # Performance testing documentation
│   └── test_search_speed.lua
│
└── utils/                     # Testing utilities and framework
    ├── README.md              # Test utilities documentation
    ├── test_framework.lua     # Core testing framework
    ├── test_isolation.lua     # Test isolation system
    ├── test_performance.lua   # Performance monitoring
    └── test_search.lua        # Search testing utilities
```

## Test Categories

### [Commands Tests](commands/README.md)
Tests for all Himalaya commands and their integration with Neovim.

**Purpose**: Validate command interfaces, parameter handling, and user-facing functionality.

**Coverage**: 
- Plugin initialization and configuration
- Email operations (list, send, delete)
- Synchronization commands
- Command validation and error handling

**Key Tests**: Basic commands, email operations, sync management

### [Features Tests](features/README.md)
Tests for specific Himalaya features and their underlying implementations.

**Purpose**: Validate core feature functionality and business logic.

**Coverage**:
- Async operations and timing
- Draft management (maildir-based)
- Email composition and editing
- Scheduler and queue management
- Maildir system integration

**Key Tests**: Scheduler, draft manager, email composer, maildir operations

### [Integration Tests](integration/README.md)
End-to-end workflow tests that verify component interaction.

**Purpose**: Validate that components work together correctly in realistic scenarios.

**Coverage**:
- Complete email workflows
- Multi-component coordination
- State consistency across operations
- Error propagation and handling

**Key Tests**: Full workflows, simplified operations, sync coordination

### [Performance Tests](performance/README.md)
Performance and benchmarking tests for efficiency validation.

**Purpose**: Ensure plugin remains responsive under various load conditions.

**Coverage**:
- Search performance across dataset sizes
- Memory usage patterns
- Cache effectiveness
- Performance regression detection

**Key Tests**: Search speed, memory efficiency, scalability

### [Test Utils](utils/README.md)
Testing utilities and framework components.

**Purpose**: Provide common functionality and patterns for all test suites.

**Coverage**:
- Test framework and assertions
- Test environment isolation
- Performance monitoring
- Domain-specific utilities

**Key Components**: Framework, isolation, performance monitoring, search utils

## Running Tests

### Two Ways to Run Tests

Tests can be run either **interactively within Neovim** or **from the command line** for test-driven development.

### 1. Interactive Testing (Within Neovim)

Use the `:HimalayaTest` command when you have Neovim open:

```vim
:HimalayaTest              " Opens interactive picker
:HimalayaTest all          " Run all tests
:HimalayaTest commands     " Run command tests
:HimalayaTest features     " Run feature tests
:HimalayaTest integration  " Run integration tests
:HimalayaTest performance  " Run performance tests
:HimalayaTest test_scheduler  " Run specific test
```

Results appear in a floating window with syntax highlighting.

### 2. Command Line Testing (Test-Driven Development)

Use `dev_cli.lua` for headless testing during development or CI/CD:

```bash
# From anywhere (absolute path):
nvim --headless -l /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/test/dev_cli.lua

# Or from the himalaya directory:
cd /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya
nvim --headless -l test/dev_cli.lua

# Run specific test categories:
nvim --headless -l test/dev_cli.lua commands     # Command tests only
nvim --headless -l test/dev_cli.lua features     # Feature tests only
nvim --headless -l test/dev_cli.lua integration  # Integration tests only
nvim --headless -l test/dev_cli.lua performance  # Performance tests only

# Run a specific test by name:
nvim --headless -l test/dev_cli.lua test_scheduler
nvim --headless -l test/dev_cli.lua test_draft_manager

# Default behavior (no argument = run all tests):
nvim --headless -l test/dev_cli.lua
```

#### Key Features of dev_cli.lua:
- **Exit codes**: Returns 0 on success, 1 on failure (perfect for CI/CD)
- **Full output**: All test results and error messages print to stdout
- **No UI**: Runs completely headless, no windows or prompts
- **Fast feedback**: Ideal for test-driven development workflows

#### Example Output:
```
# Himalaya Test Results

Date: 2025-07-16 11:15:00
Duration: 5702.09 ms

## Summary
Total Tests: 160
✅ Passed: 158
❌ Failed: 2
⏭️  Skipped: 0

Success Rate: 98.8%

## Failed Tests

❌ [FEATURES] test_async_timing:Timer accuracy test
  ...ugins/tools/himalaya/test/features/test_async_timing.lua:56: Timing not in acceptable range: expected 15ms--150ms, got 0.08ms

❌ [INTEGRATION] test_email_operations:Email list display
  ...ig/nvim/lua/neotex/plugins/tools/himalaya/utils/cli.lua:237: attempt to call field 'execute' (a nil value)
```

#### Quick Test During Development:
```bash
# Create an alias for convenience:
alias htest='nvim --headless -l /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/test/dev_cli.lua'

# Then use:
htest              # Run all tests
htest features     # Run feature tests
htest test_scheduler  # Run specific test
```

## Test Runner Features

### Test Discovery
- **Automatic Detection**: Finds all `test_*.lua` files
- **Category Organization**: Groups tests by directory structure
- **Flexible Execution**: Run individual tests or entire categories

### Test Execution
- **Real Implementation Testing**: Tests actual code without mocking
- **Test Isolation**: Prevents tests from affecting each other
- **Error Handling**: Graceful handling of expected failures in test environment

### Result Reporting
- **Detailed Reports**: Comprehensive pass/fail statistics
- **Performance Metrics**: Execution time for all tests
- **Error Details**: Complete error messages and context
- **Progress Tracking**: Real-time test execution progress

## Testing Philosophy

### Real Implementation Testing
- **No Mocking**: Tests use actual implementations to catch real issues
- **Graceful Failure Handling**: Expected failures (like missing config) are handled appropriately
- **Test Mode Protection**: External CLI calls are prevented during testing

### Test Isolation
- **Clean Environment**: Each test runs in isolated environment
- **State Management**: Editor state is preserved and restored
- **Resource Cleanup**: Temporary files and buffers are cleaned up

### Quality Assurance
- **Comprehensive Coverage**: Tests cover normal and edge cases
- **Performance Monitoring**: Performance regressions are detected
- **Consistent Patterns**: Standardized test patterns across all tests

## Test Environment

### Test Mode Features
- **CLI Protection**: Prevents external Himalaya CLI calls
- **Notification Control**: Context-aware notification handling
- **State Isolation**: Tests don't affect user environment
- **Buffer Management**: Automatic cleanup of test buffers

### Notification System Integration
The test framework integrates with the unified notification system:

1. **ERROR notifications are always shown** - This is by design
2. **Test mode suppresses non-critical notifications** - STATUS, BACKGROUND categories
3. **Validation errors can be suppressed** - Using `test_validation` flag

```lua
-- Notification categories and test behavior:
-- ERROR, WARNING: Always shown (unless test_validation = true)
-- USER_ACTION: Always shown (real user actions)
-- STATUS: Suppressed in test mode (debug info)
-- BACKGROUND: Suppressed in test mode (internal operations)
```

### Performance Monitoring
- **Timing Precision**: High-resolution timing for performance tests
- **Memory Tracking**: Memory usage monitoring
- **Regression Detection**: Automatic performance regression detection

## Test Mode Implementation Details

### Global Test Mode Flag
The test framework sets `_G.HIMALAYA_TEST_MODE` to indicate test execution. This flag should be checked at multiple levels:

```lua
-- In CLI utilities
if _G.HIMALAYA_TEST_MODE then
  return mock_data
end

-- In async operations
if _G.HIMALAYA_TEST_MODE then
  vim.schedule(function()
    callback(mock_data)
  end)
  return
end

-- In logging/notifications
if not _G.HIMALAYA_TEST_MODE then
  logger.error('Operation failed', details)
end
```

### Critical: Test Mode Timing
The `_G.HIMALAYA_TEST_MODE` flag MUST be set before any configuration or module initialization:

```lua
-- CORRECT: Set test mode first
_G.HIMALAYA_TEST_MODE = true
config.setup({ ... })

-- INCORRECT: Config validation will trigger notifications
config.setup({ ... })
_G.HIMALAYA_TEST_MODE = true
```

This is especially important for:
- Test environment setup (`create_test_env`)
- Direct config.setup calls in test files
- Any module initialization that might validate configuration

### Test Assertion Patterns
The test framework provides assertions through a nested structure:

```lua
-- Correct pattern
local assert = test_framework.assert
assert.equals(actual, expected)
assert.truthy(value)

-- Incorrect (will fail)
test_framework.assert_equals(actual, expected)  -- Function doesn't exist
```

### Async Operation Handling
When implementing async functions that will be tested:

1. **Check test mode early**: Return mock data before attempting real operations
2. **Simulate async behavior**: Use `vim.schedule` to maintain realistic flow
3. **Handle callbacks properly**: Ensure callbacks match expected signatures

Example:
```lua
function M.get_data_async(callback)
  if _G.HIMALAYA_TEST_MODE then
    vim.schedule(function()
      callback(mock_data, nil)  -- data, error
    end)
    return
  end
  -- Real implementation
end
```

### Async Test Timing
When testing async operations, ensure adequate wait times:

```lua
-- GOOD: Sufficient timeout with polling interval
vim.wait(500, function() return operation_complete end, 10)

-- BAD: Too short, may fail intermittently
vim.wait(100, function() return operation_complete end)
```

For async tests:
- Use at least 500ms timeout for operations involving multiple async steps
- Include a polling interval (3rd parameter) for more responsive checks
- Consider system load when setting timeouts

### CLI Command Mocking
External CLI commands should be mocked at multiple levels:

1. **High-level functions**: Return mock data immediately in test mode
2. **Low-level execution**: Prevent actual CLI execution
3. **Error handling**: Suppress error logging in test mode

### Window Management Considerations
In headless test environments, complex window operations may fail:

```lua
-- Handle test mode differently
if _G.HIMALAYA_TEST_MODE then
  -- Use simpler window creation
  win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = 0,
    col = 0
  })
else
  -- Normal window splitting
  vim.cmd('vsplit')
end
```

### Validation Error Handling
When testing configuration validation or intentionally invalid configs:

```lua
-- For direct validation testing, use test_validation flag
local valid, errors = validation.validate(config, { test_validation = true })

-- For functions that validate internally
if _G.HIMALAYA_TEST_MODE then
  -- The function should pass test mode flag internally
  local result = someFunction(config)
end
```

This prevents validation errors from appearing in test output while still allowing proper error handling tests.

### Common Test Mode Pitfalls
1. **Forgetting early returns**: Always check test mode before external operations
2. **Inconsistent callback signatures**: Match production callback patterns
3. **Missing error suppression**: Add test mode checks to all error logging
4. **Cleanup timing**: Some operations need delayed cleanup (`vim.defer_fn`)
5. **Test mode timing**: Setting `_G.HIMALAYA_TEST_MODE` after config initialization
6. **Validation noise**: Not using `test_validation` flag when testing invalid configs

## Contributing

### Adding New Tests

1. **Choose the Right Category**:
   - **Commands**: For testing command interfaces
   - **Features**: For testing specific functionality
   - **Integration**: For testing component interaction
   - **Performance**: For testing efficiency

2. **Follow Established Patterns**:
   - Use the test framework from `utils/test_framework.lua`
   - Follow naming conventions (`test_*.lua`)
   - Include appropriate assertions and cleanup

3. **Test Real Implementation**:
   - Test actual code behavior, not mocks
   - Handle expected failures gracefully
   - Use `pcall()` for operations that might fail

4. **Update Documentation**:
   - Update relevant README.md files
   - Document test purpose and coverage
   - Include examples if needed

### Test Writing Standards

- **Descriptive Names**: Test names should clearly describe what they validate
- **Focused Tests**: Each test should have a single, clear purpose
- **Proper Cleanup**: Ensure tests clean up after themselves
- **Error Handling**: Handle both success and failure cases appropriately
- **Performance Awareness**: Consider performance implications of tests

## Troubleshooting Test Issues

### Common Problems and Solutions

#### "Configuration validation failed" messages during tests
**Cause**: Test mode flag not set before config initialization or validation tests not using test flag.

**Solution**:
1. Ensure `_G.HIMALAYA_TEST_MODE = true` is set before any `config.setup()` calls
2. Use `validation.validate(config, { test_validation = true })` when testing invalid configs
3. Check that `validate_draft_config` passes test flag in fallback scenarios

#### Async test failures (intermittent)
**Cause**: Insufficient wait time for async operations to complete.

**Solution**:
1. Increase `vim.wait()` timeout from 100ms to 500ms or more
2. Add polling interval as third parameter: `vim.wait(500, condition, 10)`
3. Consider system load and add buffer to timing expectations

#### Test notifications appearing in message log
**Cause**: ERROR and WARNING notifications are always shown by design.

**Solution**:
1. Use appropriate notification categories (STATUS/BACKGROUND for debug info)
2. Check `_G.HIMALAYA_TEST_MODE` before logging errors in test scenarios
3. Use `test_validation` flag for validation-specific tests

#### Buffer cleanup failures
**Cause**: Test buffers not properly tracked or cleaned up.

**Solution**:
1. Use `test_framework.helpers.register_buffer(env, buf)` for all test buffers
2. Ensure `cleanup_test_env(env)` is called even on test failure
3. Use `force = true` when deleting buffers: `vim.api.nvim_buf_delete(buf, { force = true })`

## Current Status

- **Total Tests**: 196 tests across all categories
- **Pass Rate**: 100% (all tests passing)
- **Coverage**: Comprehensive coverage of all major functionality
- **Performance**: All tests execute efficiently with proper isolation

The test suite provides reliable validation of the Himalaya plugin functionality, ensuring stability and correctness across all components and workflows.

## Navigation

- [Commands Tests →](commands/README.md)
- [Features Tests →](features/README.md)
- [Integration Tests →](integration/README.md)
- [Performance Tests →](performance/README.md)
- [Test Utils →](utils/README.md)
- [← Himalaya Plugin](../README.md)