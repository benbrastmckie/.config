# Feature Tests

This directory contains tests for specific Himalaya features and their underlying implementations.

## Purpose

Feature tests validate core functionality and business logic of individual Himalaya features. These tests focus on the behavior of specific features rather than their command interfaces, providing comprehensive coverage of the plugin's capabilities.

## Test Files

### test_async_timing.lua
Tests asynchronous operations and timing functionality.

**What it tests:**
- Timer accuracy and scheduling
- Concurrent async operations
- Event timing and ordering
- Callback chain execution
- Timer management and cleanup
- Debounced operations
- Promise-like async patterns
- Rate limiting mechanisms

**Key patterns tested:**
- `vim.defer_fn()` timing accuracy
- Event bus timing with `events_bus.emit()`
- Async callback chains
- Timer lifecycle management

### test_draft_commands_config.lua
Tests draft command configuration and setup.

**What it tests:**
- Draft command initialization
- Configuration validation
- Command registration
- Error handling for invalid configurations

### test_draft_manager_maildir.lua
Tests maildir-based draft management system.

**What it tests:**
- Draft creation and persistence
- Maildir file structure validation
- Draft metadata handling
- Draft listing and enumeration
- Draft editing and updates
- Draft deletion and cleanup

**Key functions tested:**
- `draft_manager.create_draft()` - Draft creation
- `draft_manager.list_drafts()` - Draft enumeration
- `draft_manager.save_draft()` - Draft persistence
- `draft_manager.delete_draft()` - Draft cleanup

### test_draft_saving.lua
Tests draft saving functionality and workflows.

**What it tests:**
- Draft folder detection and creation
- Draft saving operations
- Composer integration with draft saving
- Maildir draft persistence
- Draft cleanup procedures

### test_email_composer_maildir.lua
Tests email composition with maildir integration.

**What it tests:**
- Compose buffer creation and management
- Email template handling
- Draft auto-saving during composition
- Maildir-based storage integration
- Compose workflow validation

**Key functions tested:**
- `composer.create_compose_buffer()` - Buffer creation
- `composer.setup_compose_environment()` - Environment setup
- Draft integration during composition

### test_maildir_foundation.lua
Tests core maildir functionality and utilities.

**What it tests:**
- Maildir filename generation
- Maildir file parsing
- Directory structure creation
- Atomic write operations
- Header parsing and validation
- Message listing and filtering

**Key functions tested:**
- `maildir.generate_filename()` - Filename creation
- `maildir.parse_filename()` - Filename parsing
- `maildir.create_maildir()` - Directory setup
- `maildir.atomic_write()` - Safe file operations

### test_maildir_integration.lua
Tests comprehensive maildir system integration.

**What it tests:**
- End-to-end maildir workflows
- Draft manager integration
- Email composer integration
- Migration procedures
- Performance under load

### test_scheduler.lua
Tests email scheduling and queue management.

**What it tests:**
- Email scheduling with custom delays
- Scheduled email queue management
- Schedule editing and rescheduling
- Schedule cancellation
- Scheduler persistence and recovery
- Queue cleanup and maintenance

**Key functions tested:**
- `scheduler.schedule_email()` - Email scheduling
- `scheduler.get_scheduled_emails()` - Queue retrieval
- `scheduler.cancel_send()` - Schedule cancellation
- `scheduler.edit_scheduled_time()` - Schedule modification

## System Under Test

The feature layer in Himalaya implements core business logic:

### Architecture
- **Feature Modules**: Self-contained feature implementations
- **State Management**: Feature-specific state handling
- **Event Integration**: Feature events and notifications
- **Storage Layer**: Persistent storage for feature data

### Key Components
- **Draft System**: Maildir-based draft management
- **Scheduler**: Email scheduling and queue management
- **Composer**: Email composition and editing
- **Async Operations**: Non-blocking feature operations

## Test Patterns

### Feature Initialization
```lua
-- Test feature setup
local feature = require('feature.module')
feature.setup()
assert.truthy(feature.initialized, "Feature should initialize")
```

### State Validation
```lua
-- Test state changes
local original_state = feature.get_state()
feature.perform_operation()
local new_state = feature.get_state()
assert.not_equals(original_state, new_state, "State should change")
```

### Async Operation Testing
```lua
-- Test async operations
local completed = false
feature.async_operation(function()
  completed = true
end)
helpers.wait_for(function() return completed end, 1000)
assert.truthy(completed, "Async operation should complete")
```

### File System Operations
```lua
-- Test file operations
local temp_dir = helpers.create_temp_dir()
feature.create_file(temp_dir .. '/test.txt')
assert.file_exists(temp_dir .. '/test.txt')
vim.fn.delete(temp_dir, 'rf')
```

## Running Tests

### Run all feature tests:
```vim
:HimalayaTest features
```

### Run specific test file:
```vim
:HimalayaTest test_scheduler
:HimalayaTest test_draft_manager_maildir
:HimalayaTest test_email_composer_maildir
```

## Test Environment

Feature tests run with:
- Temporary directories for file operations
- Controlled timing for async operations
- Event isolation to prevent interference
- Real feature implementations without external dependencies

## Contributing

When adding new feature tests:

1. **Test feature behavior**: Focus on what the feature does, not how
2. **Use real implementations**: Test actual feature code
3. **Handle async properly**: Use appropriate timing and wait patterns
4. **Clean up resources**: Ensure temporary files and state are cleaned up
5. **Test edge cases**: Include error conditions and boundary cases

## Navigation

- [← Test Overview](../README.md)
- [← Commands Tests](../commands/README.md)
- [Integration Tests →](../integration/README.md)
- [Performance Tests →](../performance/README.md)