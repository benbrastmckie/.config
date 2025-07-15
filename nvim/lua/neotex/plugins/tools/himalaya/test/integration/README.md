# Integration Tests

This directory contains integration tests that verify how different Himalaya components work together in realistic workflows.

## Purpose

Integration tests validate that the entire Himalaya system works cohesively. These tests simulate real user workflows and verify that all components integrate correctly, from UI interactions to backend operations.

## Test Files

### test_draft_simple.lua
Tests simplified draft management integration.

**What it tests:**
- Draft manager initialization and setup
- Draft listing across the system
- Draft buffer validation and checking
- Draft retrieval through `get_all()` operations
- Integration between draft storage and UI

**Key integration points:**
- Draft manager ↔ Storage system
- Draft manager ↔ UI components
- Draft manager ↔ State management

### test_email_operations_simple.lua
Tests simplified email operation workflows.

**What it tests:**
- Email list initialization and display
- Email list UI rendering
- Email formatting and presentation
- Email search functionality integration
- Email operations coordination

**Key integration points:**
- Email list ↔ UI rendering
- Email list ↔ State management
- Email list ↔ Search system
- Email operations ↔ Notification system

### test_full_workflow.lua
Tests comprehensive end-to-end workflows.

**What it tests:**
- Complete email workflow from start to finish
- Multi-account workflow coordination
- Notification system integration
- Error handling across components
- Sync system integration

**Key workflows tested:**
- Email composition → Scheduling → Queue management
- Account switching → State updates → UI refresh
- Error occurrence → Error handling → User notification
- Sync coordination → Primary detection → Sync execution

**Key integration points:**
- All major components working together
- State consistency across operations
- Event propagation through the system
- Error handling across component boundaries

### test_sync_simple.lua
Tests simplified synchronization workflows.

**What it tests:**
- Sync coordinator initialization
- Primary status detection and management
- Sync heartbeat operations
- Sync state consistency

**Key integration points:**
- Sync coordinator ↔ Manager
- Sync system ↔ State management
- Sync operations ↔ UI updates

## System Under Test

Integration tests verify the entire Himalaya ecosystem:

### Architecture Components
- **UI Layer**: User interface components and interactions
- **Command Layer**: Command processing and validation
- **Core Layer**: Business logic and feature implementation
- **Storage Layer**: Persistent data storage and retrieval
- **Sync Layer**: Synchronization and coordination

### Integration Points
- **UI ↔ Commands**: User actions trigger command execution
- **Commands ↔ Core**: Commands invoke core functionality
- **Core ↔ Storage**: Features persist and retrieve data
- **Core ↔ Sync**: Operations coordinate with sync system
- **State ↔ All**: Global state management across components

## Test Patterns

### End-to-End Workflows
```lua
-- Test complete workflow
local result = perform_complete_workflow()
assert.truthy(result.success, "Workflow should complete successfully")
assert.truthy(result.data, "Workflow should produce data")
```

### Component Integration
```lua
-- Test component coordination
component_a.setup()
component_b.setup()
local result = component_a.interact_with(component_b)
assert.truthy(result, "Components should work together")
```

### State Consistency
```lua
-- Test state synchronization
local initial_state = state.get('key')
perform_multi_component_operation()
local final_state = state.get('key')
assert.consistent(initial_state, final_state, "State should be consistent")
```

### Error Propagation
```lua
-- Test error handling across components
local ok, result = pcall(multi_component_operation)
if not ok then
  assert.error_handled(result, "Errors should be handled gracefully")
end
```

## Running Tests

### Run all integration tests:
```vim
:HimalayaTest integration
```

### Run specific test file:
```vim
:HimalayaTest test_full_workflow
:HimalayaTest test_email_operations_simple
:HimalayaTest test_draft_simple
:HimalayaTest test_sync_simple
```

## Test Environment

Integration tests run with:
- Multiple components initialized and configured
- Realistic data flows between components
- Proper state management across operations
- Error handling verification across boundaries
- Performance considerations for multi-component operations

## Test Scenarios

### Happy Path Testing
- All components work together successfully
- Data flows correctly between components
- State remains consistent throughout operations
- UI updates reflect backend changes

### Error Condition Testing
- Component failures are handled gracefully
- Errors propagate appropriately
- System remains stable during failures
- Recovery procedures work correctly

### Performance Testing
- Multi-component operations complete in reasonable time
- Memory usage remains stable during complex workflows
- UI remains responsive during background operations

## Contributing

When adding new integration tests:

1. **Test real workflows**: Simulate actual user interactions
2. **Verify component interaction**: Ensure components work together
3. **Test error scenarios**: Include failure cases and recovery
4. **Use realistic data**: Test with representative data sets
5. **Document integration points**: Clearly identify what's being integrated

## Navigation

- [← Test Overview](../README.md)
- [← Features Tests](../features/README.md)
- [Performance Tests →](../performance/README.md)
- [Test Utils →](../utils/README.md)