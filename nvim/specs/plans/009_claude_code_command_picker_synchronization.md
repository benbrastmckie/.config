# Claude Code Command Picker Synchronization Implementation Plan

## Metadata
- **Date**: 2025-09-30
- **Feature**: Claude Code command picker synchronization using autocommands
- **Scope**: Fix timing issues where command picker fails before Claude Code opens
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/specs/reports/017_claude_code_command_picker_synchronization.md

## Overview

This implementation plan addresses the critical timing synchronization issue where the `<leader>ac` command picker fails when Claude Code hasn't opened yet. The solution implements an event-driven command queue system using Neovim autocommands to provide robust functionality independent of Claude Code's startup state.

The approach leverages existing autocommand patterns in the codebase and extends them with sophisticated command synchronization capabilities while maintaining the existing user interface.

## Success Criteria

- [ ] Commands from picker work reliably before Claude Code opens
- [ ] Commands are queued and executed automatically when Claude Code becomes available
- [ ] User receives immediate feedback about command status
- [ ] No breaking changes to existing command picker interface
- [ ] Enhanced error handling and recovery mechanisms
- [ ] Performance optimizations for autocommand overhead
- [ ] Comprehensive test coverage for all scenarios

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Command Picker UI                        │
│              (picker.lua - existing interface)              │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│                Command Queue Manager                        │
│         (new: command-queue.lua module)                     │
│  ┌─────────────────┬─────────────────┬─────────────────┐    │
│  │   Queue State   │  Event Handler  │  Command Exec   │    │
│  │   Management    │   System        │   Strategies    │    │
│  └─────────────────┴─────────────────┴─────────────────┘    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│              Autocommand Event System                       │
│           (enhanced autocmds.lua integration)               │
│    TermOpen → Claude Detection → Queue Processing           │
└─────────────────────────────────────────────────────────────┘
```

### State Machine Design

```
┌─────────────┐    Claude Code    ┌──────────────┐
│   WAITING   │ ───detected────→  │    READY     │
│ (queue cmds)│                   │ (exec direct)│
└─────────────┘                   └──────────────┘
       │                                 │
       │ command                         │ command
       │ request                         │ request
       ↓                                 ↓
┌─────────────┐                   ┌──────────────┐
│   QUEUED    │ ←─Claude restart─ │   EXECUTING  │
│(pending exec)│                  │ (processing) │
└─────────────┘                   └──────────────┘
```

### Key Components

1. **Command Queue Manager** - New module for command lifecycle management
2. **Enhanced Terminal Detection** - Improved Claude Code readiness validation
3. **Autocommand Integration** - Event-driven command processing
4. **Robust Execution System** - Multiple fallback strategies for command delivery

## Implementation Phases

### Phase 1: Core Infrastructure [COMPLETED]
**Objective**: Establish command queue system and enhanced terminal detection
**Complexity**: Medium

Tasks:
- [x] Create command queue module at `lua/neotex/plugins/ai/claude/core/command-queue.lua`
- [x] Implement queue state management with command metadata tracking
- [x] Add enhanced Claude terminal validation logic with multiple checks
- [x] Create command execution strategies with fallback mechanisms
- [x] Implement basic queue size limits and memory management
- [x] Add debug logging and error tracking capabilities

Testing:
```bash
# Test command queue creation and basic operations
nvim --headless -c "lua require('neotex.plugins.ai.claude.core.command-queue').test_queue_operations()" -c "qa!"

# Test terminal detection without Claude Code running
nvim --headless -c "lua require('neotex.plugins.ai.claude.core.command-queue').test_terminal_detection()" -c "qa!"
```

### Phase 2: Autocommand Integration [COMPLETED]
**Objective**: Integrate event-driven command processing with existing autocommand system
**Complexity**: High

Tasks:
- [x] Extend `lua/neotex/config/autocmds.lua` with Claude Code readiness detection
- [x] Add TermOpen autocommand for Claude Code terminal creation events
- [x] Implement BufEnter autocommand for existing Claude Code instance detection
- [x] Create command queue processing triggers on Claude readiness events
- [x] Add autocommand error handling and recovery mechanisms
- [x] Implement debouncing to prevent excessive autocommand firing

Testing:
```bash
# Test autocommand registration and event handling
nvim --headless -c "lua vim.print(vim.api.nvim_get_autocmds({group = 'ClaudeCommandQueue'}))" -c "qa!"

# Test Claude Code detection autocommands
nvim -c "terminal claude" -c "sleep 1" -c "lua require('neotex.plugins.ai.claude.core.command-queue').test_autocommand_detection()" -c "qa!"
```

### Phase 3: Picker Integration [COMPLETED]
**Objective**: Modify command picker to use new queue system while maintaining existing interface
**Complexity**: Medium

Tasks:
- [x] Update `send_command_to_terminal()` function in `lua/neotex/plugins/ai/claude/commands/picker.lua`
- [x] Replace polling logic with event-driven queue submission
- [x] Add immediate user feedback for queued commands via notification system
- [x] Implement queue status display in picker preview pane
- [x] Add keyboard shortcuts for queue management (view/clear pending commands)
- [x] Preserve all existing picker functionality and keyboard shortcuts

Testing:
```bash
# Test command picker with queue integration
nvim -c "lua require('neotex.plugins.ai.claude').show_commands_picker()" -c "sleep 2" -c "qa!"

# Test command queueing before Claude Code opens
nvim --headless -c "lua require('neotex.plugins.ai.claude.core.command-queue').queue_test_command('/test')" -c "qa!"
```

### Phase 4: Enhancement and Optimization [COMPLETED]
**Objective**: Add advanced features, performance optimizations, and comprehensive error handling
**Complexity**: Low

Tasks:
- [x] Implement command queue persistence across Neovim restarts
- [x] Add configuration options for queue behavior (size limits, timeout values)
- [x] Optimize autocommand performance with vim.schedule_wrap for heavy operations
- [x] Add comprehensive error recovery for Claude Code crashes and restarts
- [x] Implement command priority system for critical vs. standard commands
- [x] Add telemetry and usage metrics for queue system performance

Testing:
```bash
# Test configuration options
nvim --headless -c "lua require('neotex.plugins.ai.claude.core.command-queue').test_configuration()" -c "qa!"

# Test performance with multiple queued commands
nvim --headless -c "lua require('neotex.plugins.ai.claude.core.command-queue').performance_test()" -c "qa!"

# Test error recovery scenarios
nvim --headless -c "lua require('neotex.plugins.ai.claude.core.command-queue').test_error_recovery()" -c "qa!"
```

## Testing Strategy

### Unit Testing
```bash
# Test individual command queue operations
:lua require('neotex.plugins.ai.claude.core.command-queue').run_unit_tests()

# Test terminal detection logic
:lua require('neotex.plugins.ai.claude.core.command-queue').test_terminal_validation()

# Test command execution strategies
:lua require('neotex.plugins.ai.claude.core.command-queue').test_execution_strategies()
```

### Integration Testing
```bash
# Full picker workflow test
:TestFile lua/neotex/plugins/ai/claude/commands/picker.lua

# Autocommand integration test
:TestNearest # when in autocmds.lua

# End-to-end command flow test
:lua require('neotex.plugins.ai.claude.core.command-queue').integration_test()
```

### Scenario Testing
1. **Before Claude Code opens**: Command picker → queue → auto-execution when ready
2. **After Claude Code opens**: Command picker → immediate execution
3. **Multiple queued commands**: Batch processing and notification
4. **Claude Code restart**: Queue persistence and recovery
5. **Plugin reload**: State preservation and recovery

## File Modifications

### New Files
- `lua/neotex/plugins/ai/claude/core/command-queue.lua` - Command queue management system
- `lua/neotex/plugins/ai/claude/core/terminal-detection.lua` - Enhanced terminal validation

### Modified Files
- `lua/neotex/plugins/ai/claude/commands/picker.lua` - Integration with queue system
- `lua/neotex/config/autocmds.lua` - Claude Code autocommand enhancements
- `lua/neotex/plugins/ai/claude/init.lua` - Queue system initialization

## Configuration Options

### Command Queue Settings
```lua
-- Configuration in claude config
queue = {
  max_size = 10,              -- Maximum queued commands
  timeout_ms = 30000,         -- Command timeout (30 seconds)
  auto_open_claude = true,    -- Auto-open Claude when commands queued
  persistence = true,         -- Persist queue across restarts
  debug_logging = false,      -- Enable debug output
}
```

### Autocommand Performance Settings
```lua
autocommands = {
  debounce_ms = 100,          -- Debounce rapid events
  max_detection_attempts = 5, -- Terminal detection retry limit
  use_schedule_wrap = true,   -- Use vim.schedule_wrap for heavy ops
}
```

## Dependencies

### Internal Dependencies
- Existing notification system (`neotex.util.notifications`)
- Claude Code plugin integration (`claude-code.nvim`)
- Telescope picker infrastructure
- Terminal management system

### External Dependencies
- `vim.api.nvim_create_autocmd` - Autocommand system
- `vim.defer_fn` - Delayed execution
- `vim.schedule_wrap` - Performance optimization

## Error Handling Strategy

### Queue Errors
- Command timeout handling with user notification
- Queue overflow protection with oldest command removal
- Invalid command detection and filtering

### Terminal Errors
- Claude Code crash detection and recovery
- Terminal buffer recreation handling
- Channel communication failure recovery

### Autocommand Errors
- Event handler exception catching with pcall
- Autocommand registration failure handling
- Performance degradation monitoring

## Performance Considerations

### Memory Management
- Implement rolling queue with automatic cleanup
- Monitor autocommand memory overhead
- Add queue size limits and warnings

### Responsiveness
- Use vim.schedule_wrap for non-critical operations
- Implement event debouncing for rapid terminal events
- Optimize terminal detection with caching

## Documentation Requirements

### User Documentation
- Update README.md with new command picker behavior
- Add troubleshooting guide for queue-related issues
- Document new configuration options

### Developer Documentation
- Add inline documentation for all new functions
- Create architecture diagrams for queue system
- Document autocommand event flow

## Migration Strategy

### Backward Compatibility
- Maintain existing command picker interface
- Preserve all current keyboard shortcuts
- Keep configuration options optional with sensible defaults

### Rollback Plan
- Feature flag for queue system enablement
- Graceful degradation to original polling logic
- Configuration option to disable autocommand integration

## ✅ IMPLEMENTATION COMPLETE

All phases have been successfully implemented and tested. The Claude Code command picker synchronization system is now fully operational with:

- **Event-driven architecture** replacing polling-based detection
- **Robust command queueing** with automatic execution when Claude Code becomes available
- **Comprehensive error handling** with crash recovery and fallback mechanisms
- **Performance optimizations** using vim.schedule_wrap and debouncing
- **Advanced features** including persistence, telemetry, and configuration options

### Implementation Results
- **Phase 1**: Core infrastructure with command queue and terminal detection ✅
- **Phase 2**: Autocommand integration with event-driven processing ✅
- **Phase 3**: Picker integration maintaining existing interface ✅
- **Phase 4**: Enhanced features and optimization ✅

### Success Criteria Achieved
- [x] Commands from picker work reliably before Claude Code opens
- [x] Commands are queued and executed automatically when Claude Code becomes available
- [x] User receives immediate feedback about command status
- [x] No breaking changes to existing command picker interface
- [x] Enhanced error handling and recovery mechanisms
- [x] Performance optimizations for autocommand overhead
- [x] Comprehensive test coverage for all scenarios

## Notes

### Design Decisions
- Event-driven architecture chosen over polling for better performance
- Command queue implemented as separate module for maintainability
- Autocommand integration leverages existing patterns in codebase

### Future Enhancements
- Command history and analytics
- Smart command grouping and batching
- Integration with other Claude Code features
- Advanced notification and status reporting

### Risk Mitigation
- Comprehensive error handling prevents system crashes
- Performance monitoring prevents autocommand overhead
- Fallback mechanisms ensure continued functionality