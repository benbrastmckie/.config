# Draft System Health & Testing API Documentation (Phase 7)

This document describes the health check and testing infrastructure implemented in Phase 7 of the draft system integration.

## Overview

Phase 7 added comprehensive health checks and testing infrastructure to ensure the draft system is robust, reliable, and properly integrated with all Himalaya components.

## Health Check System

### Core Health Module

**File: `core/health/draft.lua`**

The draft health module provides comprehensive health checks for all aspects of the draft system.

#### Main Functions

##### `draft_health.check()`

Runs a complete health check of the draft system.

**Checks performed:**
- Draft storage directory existence and permissions
- Active draft count and buffer validity
- Unsaved drafts detection
- Sync status and timing
- Pending syncs and recovery data
- Draft manager/state synchronization
- Configuration validity
- Event system integration
- Notification system availability
- Window stack integration
- Orphaned file detection
- Performance benchmarks

**Example:**
```lua
local draft_health = require('neotex.plugins.tools.himalaya.core.health.draft')
draft_health.check()
-- Outputs health information using vim.health.report_*
```

##### `draft_health.check_storage_integrity()`

Performs detailed checks on draft storage files.

**Checks performed:**
- File format validation
- JSON parsing verification
- Data structure integrity
- Corruption detection

**Example:**
```lua
draft_health.check_storage_integrity()
-- Outputs storage integrity report
```

##### `draft_health.quick_check()`

Performs a minimal health check for basic functionality.

**Example:**
```lua
draft_health.quick_check()
-- Quick verification of core functionality
```

### Integration with Main Health System

The draft health checks are automatically integrated into Himalaya's main health system:

**File: `setup/health.lua`**

```lua
-- Health check automatically includes draft system
:checkhealth himalaya
```

The integration captures draft health output and formats it consistently with other health checks.

## Testing Infrastructure

### Test Suite Structure

#### Core Test Runner

**File: `scripts/test_all_drafts.lua`**

Comprehensive test runner for all draft system components.

**Functions:**

##### `run_all_draft_tests()`

Runs all draft-related test modules and provides consolidated results.

**Features:**
- Colored output with success/failure indicators
- Detailed error reporting
- Performance metrics
- Module-by-module breakdown
- Overall success rate calculation

**Example:**
```vim
:lua _G.run_all_draft_tests()
```

##### `run_draft_test(module_name)`

Runs a specific test module.

**Example:**
```lua
local test_runner = require('neotex.plugins.tools.himalaya.scripts.test_all_drafts')
test_runner.run_module('test_draft_state_integration')
```

##### `draft_health_check()`

Runs critical tests to verify system health.

**Example:**
```vim
:lua _G.draft_health_check()
```

### Individual Test Modules

#### State Integration Tests
**File: `scripts/features/test_draft_state_integration.lua`**
- Centralized state management
- State persistence
- Helper function validation

#### Recovery Tests
**File: `scripts/features/test_draft_recovery.lua`**
- Session recovery
- Draft persistence
- Recovery command functionality

#### Event System Tests
**File: `scripts/features/test_draft_events.lua`**
- Event emissions
- Event subscriptions
- Event flow validation

#### Notification Tests
**File: `scripts/features/test_draft_notifications.lua`**
- Notification integration
- Message formatting
- Category classification

#### Command & Configuration Tests
**File: `scripts/features/test_draft_commands_config.lua`**
- Command registration
- Configuration validation
- Parameter handling

#### Window Management Tests
**File: `scripts/features/test_draft_window_management.lua`**
- Window stack integration
- Draft window tracking
- Focus management

#### Integration Tests
**File: `scripts/features/test_draft_integration.lua`**
- End-to-end workflow testing
- Multi-component integration
- Performance validation

#### Health Check Tests
**File: `scripts/features/test_draft_health.lua`**
- Health system validation
- Basic functionality verification
- Module loading tests

## Usage

### Running Health Checks

#### Via Vim Health Command
```vim
:checkhealth himalaya
```

#### Programmatically
```lua
local draft_health = require('neotex.plugins.tools.himalaya.core.health.draft')
draft_health.check()
```

#### Quick Health Check
```lua
local draft_health = require('neotex.plugins.tools.himalaya.core.health.draft')
draft_health.quick_check()
```

### Running Tests

#### All Draft Tests
```vim
:lua _G.run_all_draft_tests()
```

#### Health Check Only
```vim
:lua _G.draft_health_check()
```

#### Specific Module
```vim
:lua _G.run_draft_test('test_draft_state_integration')
```

#### Available Test Modules
```vim
:lua require('neotex.plugins.tools.himalaya.scripts.test_all_drafts').list_modules()
```

## Health Check Output

### Status Indicators

- ✓ **OK**: Component is functioning correctly
- ⚠ **WARN**: Component has issues but is functional
- ✗ **ERROR**: Component has serious issues
- ℹ **INFO**: Informational message

### Sample Output

```
Himalaya Health Check
════════════════════

✓ Draft System: OK
   START: Himalaya Draft System
   OK: Draft directory exists: /home/user/.local/share/nvim/himalaya/drafts
   OK: Draft directory is writable
   INFO: Active drafts: 2
   OK: All drafts have valid buffers
   OK: All drafts are saved
   OK: Last sync: 5 minutes ago
   OK: No pending syncs
   OK: Draft manager and state are synchronized
   OK: Draft configuration is valid
   OK: Draft events are defined
   OK: Notification system is available
   OK: Window stack integration is available
   INFO: 1 draft windows open
   OK: No orphaned draft files
   OK: State access performance: 2.45 ms (100 calls)
```

## Test Output

### Success Example

```
═══ Draft System Test Suite ═══

Running test_draft_state_integration tests...
  test_draft_state_integration: 8/8 passed

Running test_draft_health tests...
  test_draft_health: 8/8 passed

═══ Test Summary ═══

Overall: 16/16 tests passed (100.0%)

Module Results:
  test_draft_state_integration: 8/8 (100.0%)
  test_draft_health:            8/8 (100.0%)

✓ All tests passed! Draft system is ready for production.
```

### Failure Example

```
═══ Draft System Test Suite ═══

Running test_draft_integration tests...
  test_draft_integration: 5/8 passed
    ✗ Draft System - Recovery Integration: Draft recovery failed: file not found
    ✗ Draft System - Sync Integration: Sync timeout after 5 seconds
    ✗ Draft System - Performance Integration: State access too slow: 150ms

═══ Test Summary ═══

Overall: 13/16 tests passed (81.3%)

Module Results:
  test_draft_integration: 5/8 (62.5%)

⚠ Most tests passed. Review failing tests before deployment.
```

## Performance Benchmarks

The health system includes performance benchmarks:

- **State Access**: < 10ms for 100 operations
- **Draft Creation**: < 1000ms for 50 drafts
- **Bulk Retrieval**: < 50ms for all drafts
- **Recovery**: < 5000ms for session recovery

## Error Handling

### Common Issues

1. **Storage Directory Missing**: Automatically created on first use
2. **Invalid Configuration**: Detailed validation error messages
3. **Orphaned Files**: Detected and reported, manual cleanup suggested
4. **Performance Issues**: Thresholds defined with specific recommendations

### Automatic Fixes

Some issues can be automatically resolved:

```vim
:HimalayaFixCommonIssues
```

This command attempts to:
- Clean up orphaned files
- Fix directory permissions
- Clear stale locks
- Reset corrupted state

## Best Practices

### Running Health Checks

1. **Regular Checks**: Run health checks after configuration changes
2. **Before Deployment**: Always run full test suite before production use
3. **Performance Monitoring**: Use performance benchmarks to detect degradation
4. **Proactive Monitoring**: Set up automated health checks in CI/CD

### Test Development

1. **Isolation**: Each test should be independent and not affect others
2. **Cleanup**: Always clean up test artifacts
3. **Error Messages**: Provide descriptive error messages for failures
4. **Performance**: Include performance assertions for critical operations

### Debugging

1. **Health First**: Always run health check before debugging complex issues
2. **Module Testing**: Test individual modules to isolate problems
3. **State Inspection**: Use state debugging tools to understand current state
4. **Event Tracing**: Enable event logging for complex interaction debugging

## Future Enhancements

1. **Continuous Monitoring**: Real-time health monitoring dashboard
2. **Automated Recovery**: Self-healing for common issues
3. **Performance Profiling**: Detailed performance analysis tools
4. **Integration Testing**: Cross-system integration tests
5. **Load Testing**: High-volume draft operation testing