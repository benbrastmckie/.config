# Himalaya Development Guidelines

This document provides reusable guidelines extracted from the successful draft system refactoring. These principles and processes should be applied to all Himalaya development work.

## Design Principles

### Core Principles
1. **Single Source of Truth**: One authoritative module for each domain
2. **Explicit State Transitions**: Clear lifecycle with defined states
3. **Defensive Persistence**: Always save locally before remote operations
4. **Progressive Enhancement**: Core functionality works without external dependencies
5. **User Feedback**: Clear indicators of state and operation status
6. **Immediate Persistence**: Save on creation, not just on first user action
7. **No Backwards Compatibility**: Focus on clean, maintainable architecture
8. **Test-Driven Development**: Implement → Test → Document → Commit each phase
9. **Clear Configuration**: Well-documented, consistent configuration structure

### Architecture Patterns

#### Component Organization
```lua
-- Single responsibility modules
Module = {
  -- Internal state
  state = {},
  
  -- Configuration
  config = {},
  
  -- Core operations (public API)
  function Module:operation() end
  
  -- Internal helpers (private)
  function Module._helper() end
}
```

#### State Management
```lua
-- Clear state definitions
State = {
  -- Explicit states with transitions
  states = {
    'new',      -- Initial state
    'active',   -- Processing state
    'complete', -- Success state
    'error'     -- Failure state
  },
  
  -- Metadata for debugging
  metadata = {
    created_at = timestamp,
    updated_at = timestamp,
    error_message = string
  }
}
```

## Development Process

### Phase-Based Development
Each feature should be developed in phases, with each phase being:
1. **Implement**: Write clean code without backwards compatibility
2. **Test**: Run comprehensive tests
3. **Document**: Update spec files and inline documentation
4. **Commit**: Commit changes with clear message
5. **Proceed**: Move to next phase only after tests pass

### Phase Structure Template
```markdown
### Phase X: [Name] (Timeline)
1. **Component/Task**:
   - [ ] Subtask 1
   - [ ] Subtask 2

2. **Testing**:
   - [ ] Create test file
   - [ ] Write unit tests
   - [ ] Run integration tests
   - [ ] Verify user experience

3. **Documentation**:
   - [ ] Update API docs
   - [ ] Add usage examples
   - [ ] Update troubleshooting guide
```

## Testing Guidelines

### Test Structure
```
/scripts/features/
├── test_[feature]_foundation.lua    # Core infrastructure tests
├── test_[feature]_operations.lua    # Operation workflow tests
├── test_[feature]_ui.lua           # UI integration tests
└── test_[feature]_integration.lua  # Full workflow tests
```

### Test Principles
1. **Keep tests focused**: Each test should verify one specific behavior
2. **Clean up after tests**: Delete any test data created
3. **Use test framework**: Leverage existing test infrastructure
4. **Avoid real operations**: Mock external calls where possible
5. **Document failures**: Include clear error messages

### Test Template
```lua
describe("[Feature] Component", function()
  before_each(function()
    -- Setup clean state
  end)
  
  after_each(function()
    -- Cleanup
  end)
  
  describe("Operation", function()
    it("should perform expected behavior", function()
      -- Arrange
      local input = setup_test_data()
      
      -- Act
      local result = component.operation(input)
      
      -- Assert
      assert.is_not_nil(result)
      assert.equals(expected, result)
    end)
  end)
end)
```

### Running Tests
```vim
" Run all tests for a feature
:HimalayaTest features

" Run specific test file
:HimalayaTest test_[feature]_foundation

" Run with debug output
:NotifyDebug himalaya
:HimalayaTest features
```

## Notification System Integration

### Categories and Usage

#### User-Facing Notifications (Always Shown)
Use for operations initiated by the user:
```lua
notify.himalaya(
  "Operation completed successfully",
  notify.categories.USER_ACTION,
  { context_data = value }
)
```

Examples:
- File saved
- Email sent
- Draft deleted
- Operation failed

#### Status Updates (Debug Mode Only)
Use for progress indicators:
```lua
notify.himalaya(
  "Processing item...",
  notify.categories.STATUS,
  { item_id = id }
)
```

Examples:
- Sync progress
- Loading states
- Processing queues

#### Background Operations (Debug Mode Only)
Use for automatic operations:
```lua
notify.himalaya(
  "Auto-save triggered",
  notify.categories.BACKGROUND,
  { trigger = "timer" }
)
```

Examples:
- Auto-save
- Cache updates
- Cleanup operations

#### Error Notifications (Always Shown)
Use for failures requiring user attention:
```lua
notify.himalaya(
  "Operation failed: " .. error_message,
  notify.categories.ERROR,
  { error = error_details }
)
```

### Notification Best Practices

1. **Always include context**:
```lua
notify.himalaya(message, category, {
  operation = "save_draft",
  item_id = draft_id,
  duration = elapsed_time
})
```

2. **Use debug helpers for tracing**:
```lua
-- Create feature-specific debug helper
local function debug_trace(event, details)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("[Feature] %s", event),
      notify.categories.BACKGROUND,
      details
    )
  end
end

-- Use throughout code
debug_trace("state_transition", {
  from = old_state,
  to = new_state,
  trigger = trigger_event
})
```

3. **Batch related notifications**:
```lua
-- Allow batching for rapid operations
notify.himalaya(
  "Processing items...",
  notify.categories.STATUS,
  { allow_batching = true }
)
```

## Event System Integration

### Event Emission Pattern
```lua
-- At top of module
local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_types = require('neotex.plugins.tools.himalaya.core.events')

-- Emit at key points
function Module:operation()
  -- Start of operation
  events_bus.emit(event_types.OPERATION_STARTED, {
    id = self.id,
    timestamp = os.time()
  })
  
  -- Perform operation
  local success, result = pcall(self._do_operation, self)
  
  -- Emit result
  if success then
    events_bus.emit(event_types.OPERATION_COMPLETED, {
      id = self.id,
      result = result
    })
  else
    events_bus.emit(event_types.OPERATION_FAILED, {
      id = self.id,
      error = result
    })
  end
end
```

### Event Subscription Pattern
```lua
-- In UI components
function UI:setup()
  -- Subscribe to relevant events
  events_bus.on(event_types.DATA_CHANGED, function(data)
    vim.schedule(function()
      self:refresh_display(data)
    end)
  end)
  
  -- Clean up on destroy
  self.cleanup = function()
    events_bus.off(event_types.DATA_CHANGED)
  end
end
```

## Configuration Guidelines

### Configuration Structure
```lua
-- In config.lua
M.defaults = {
  feature_name = {
    -- Group related settings
    behavior = {
      setting1 = default_value,
      setting2 = default_value,
    },
    
    -- Performance settings
    performance = {
      cache_ttl = 300,
      batch_size = 50,
    },
    
    -- UI settings
    ui = {
      show_indicators = true,
      update_interval = 1000,
    },
    
    -- Feature flags
    features = {
      experimental_feature = false,
      legacy_mode = false,
    }
  }
}
```

### Configuration Validation
```lua
function M.validate_feature_config(config)
  local feature = config.feature_name or {}
  
  -- Type validation
  assert(type(feature.behavior) == 'table', "behavior must be a table")
  
  -- Value validation
  if feature.performance then
    local perf = feature.performance
    assert(perf.cache_ttl > 0, "cache_ttl must be positive")
    assert(perf.batch_size > 0 and perf.batch_size <= 1000, 
           "batch_size must be between 1 and 1000")
  end
  
  return true
end
```

## Error Handling Guidelines

### Error Handling Pattern
```lua
function Module:safe_operation(input)
  -- Input validation
  if not self:validate_input(input) then
    local error_msg = "Invalid input: " .. vim.inspect(input)
    logger.error(error_msg)
    notify.himalaya(error_msg, notify.categories.ERROR)
    return false, error_msg
  end
  
  -- Protected call
  local ok, result = pcall(function()
    return self:_perform_operation(input)
  end)
  
  if not ok then
    -- Log error
    logger.error("Operation failed", { error = result, input = input })
    
    -- Notify user
    notify.himalaya(
      "Operation failed. Check logs for details.",
      notify.categories.ERROR
    )
    
    -- Attempt recovery
    self:_attempt_recovery(input, result)
    
    return false, result
  end
  
  return true, result
end
```

### Recovery Strategies
```lua
-- Exponential backoff for retries
function Module:retry_with_backoff(operation, max_attempts)
  max_attempts = max_attempts or 3
  local delay = 1000 -- Start with 1 second
  
  for attempt = 1, max_attempts do
    local ok, result = pcall(operation)
    if ok then
      return true, result
    end
    
    if attempt < max_attempts then
      vim.defer_fn(function() end, delay)
      delay = delay * 2 -- Exponential backoff
    end
  end
  
  return false, "Max retry attempts exceeded"
end
```

## Performance Guidelines

### Async Operations
```lua
-- Use async for I/O operations
function Module:async_operation(callback)
  vim.schedule(function()
    -- Perform operation in scheduled callback
    local result = self:_heavy_operation()
    
    -- Call user callback with result
    if callback then
      callback(result)
    end
  end)
end
```

### Caching Strategy
```lua
-- Implement smart caching
Cache = {
  memory = {},
  ttl = 300, -- 5 minutes
  
  get = function(self, key)
    local entry = self.memory[key]
    if not entry then return nil end
    
    -- Check TTL
    if os.time() - entry.timestamp > self.ttl then
      self.memory[key] = nil
      return nil
    end
    
    return entry.value
  end,
  
  set = function(self, key, value)
    self.memory[key] = {
      value = value,
      timestamp = os.time()
    }
  end
}
```

## Documentation Standards

### Inline Documentation
```lua
--- Brief description of the module
--- @module module_name
local M = {}

--- Perform an operation on the given input
--- @param input table The input data with fields:
---   - field1: string Description of field1
---   - field2: number Description of field2
--- @return boolean success Whether the operation succeeded
--- @return string|table result The result or error message
function M.operation(input)
  -- Implementation
end
```

### README Structure
```markdown
# Feature Name

Brief description of the feature.

## Usage

### Basic Usage
```lua
local feature = require('feature')
feature.operation({ param = value })
```

### Advanced Usage
[Examples of advanced usage]

## Configuration

```lua
-- In your config
feature = {
  setting1 = value,
  setting2 = value
}
```

## API Reference

### Functions
- `operation(input)` - Description

### Events
- `feature:event_name` - When this event is emitted

## Troubleshooting

### Common Issues
1. **Issue**: Description
   **Solution**: How to fix
```

## Migration Guidelines

### Creating Migration Scripts
```lua
-- migrations/feature_migration.lua
local M = {}

function M.migrate(dry_run)
  dry_run = dry_run or false
  local migrated = 0
  
  -- Find old data
  local old_data = find_old_data()
  
  for _, item in ipairs(old_data) do
    if dry_run then
      print("Would migrate: " .. item.id)
    else
      -- Perform migration
      local success = migrate_item(item)
      if success then
        migrated = migrated + 1
      end
    end
  end
  
  return {
    total = #old_data,
    migrated = migrated,
    dry_run = dry_run
  }
end

return M
```

### Migration Commands
```lua
-- In commands module
commands.register("Migrate[Feature]", function(opts)
  local migration = require('migrations.feature_migration')
  local dry_run = opts.args == "preview"
  
  local result = migration.migrate(dry_run)
  
  print(string.format(
    "%s: %d/%d items",
    dry_run and "Would migrate" or "Migrated",
    result.migrated,
    result.total
  ))
end, {
  nargs = "?",
  complete = function() return { "preview", "run" } end
})
```

## Summary

These guidelines provide a framework for consistent, maintainable development in the Himalaya project. Following these patterns ensures:

1. **Consistency**: All features follow the same patterns
2. **Maintainability**: Code is easy to understand and modify
3. **Reliability**: Proper error handling and recovery
4. **User Experience**: Clear feedback and notifications
5. **Testability**: Comprehensive test coverage
6. **Performance**: Efficient async operations and caching

Always refer back to these guidelines when implementing new features or refactoring existing code.