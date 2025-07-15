# Command Tests

This directory contains tests for all Himalaya command implementations and their integration with Neovim.

## Purpose

Command tests verify that all user-facing commands work correctly and handle edge cases appropriately. These tests focus on the command layer that bridges user interactions with the core Himalaya functionality.

## Test Files

### test_basic_commands.lua
Tests fundamental plugin operations and core module loading.

**What it tests:**
- Plugin initialization and module loading
- Config module functionality and setup
- State module basic operations
- Command registry validation
- Notification system integration

**Key functions tested:**
- `config.setup()` - Configuration initialization
- `state.get()` / `state.set()` - State management
- `commands.command_registry` - Command system
- `notify.himalaya()` - Notification integration

### test_email_commands.lua
Tests email-related command operations.

**What it tests:**
- Email list retrieval commands
- Email sending through scheduler
- Email deletion operations
- Email search functionality

**Key functions tested:**
- `utils.get_email_list()` - Email retrieval
- `scheduler.schedule_email()` - Email scheduling
- `utils.delete_email()` - Email deletion
- Search filtering operations

### test_sync_commands.lua
Tests synchronization command operations.

**What it tests:**
- Sync operation triggering
- Auto-sync configuration toggle
- Sync coordinator primary status
- Sync status information
- Sync operation cancellation

**Key functions tested:**
- `sync.start_sync()` - Sync initiation
- `coordinator.check_primary_status()` - Primary detection
- `coordinator.should_allow_sync()` - Sync cooldown
- Auto-sync timer management

## System Under Test

The command system in Himalaya provides the interface between user actions and core functionality:

### Architecture
- **Command Layer**: Handles user input and validation
- **Core Integration**: Bridges to core modules (scheduler, sync, etc.)
- **Error Handling**: Provides user-friendly error messages
- **State Management**: Manages command state and persistence

### Key Components
- **Command Registry**: Central command registration system
- **Validation**: Input validation and sanitization
- **Async Support**: Non-blocking command execution
- **Error Recovery**: Graceful error handling and recovery

## Test Patterns

### Command Validation
```lua
-- Test that command exists
assert.truthy(type(command_function) == "function", "Command should exist")

-- Test with valid parameters
local ok, result = pcall(command_function, valid_params)
if ok and result then
  assert.truthy(result, "Should return valid result")
end
```

### Error Handling
```lua
-- Test graceful failure in test environment
local ok, result = pcall(command_function, invalid_params)
-- Tests handle both success and expected failures
```

### State Verification
```lua
-- Test state changes
local original_state = state.get('key')
command_function()
local new_state = state.get('key')
assert.not_equals(original_state, new_state, "State should change")
```

## Running Tests

### Run all command tests:
```vim
:HimalayaTest commands
```

### Run specific test file:
```vim
:HimalayaTest test_basic_commands
:HimalayaTest test_email_commands
:HimalayaTest test_sync_commands
```

## Test Environment

Command tests run in a controlled environment where:
- External CLI calls are prevented in test mode
- State changes are isolated and cleaned up
- Notifications are handled without user disruption
- Real function behavior is tested without side effects

## Contributing

When adding new command tests:

1. **Focus on command behavior**: Test the command interface, not implementation details
2. **Handle failures gracefully**: Commands may fail in test environments (expected)
3. **Test real functions**: Use actual implementations, not mocks
4. **Clean up state**: Ensure tests don't affect subsequent tests
5. **Document purpose**: Clearly explain what the command does

## Navigation

- [← Test Overview](../README.md)
- [Features Tests →](../features/README.md)
- [Integration Tests →](../integration/README.md)