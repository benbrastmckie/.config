# Autocommand-Driven Claude Code Command Execution

## ✅ IMPLEMENTATION COMPLETE

## Metadata
- **Date**: 2025-09-30
- **Feature**: Replace delay-based command execution with autocommand-driven detection
- **Scope**: Claude Code command queue and autocommand integration
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: None (based on immediate user feedback)

## Overview

Currently, the Claude Code command execution system relies on arbitrary delays (2000ms, 1000ms) to determine when Claude Code is ready to accept commands. This approach is unreliable and causes commands to be executed too early, before Claude Code displays its prompt.

This plan replaces the delay-based approach with a robust autocommand-driven system that detects Claude Code's actual readiness state through terminal output monitoring and cursor position tracking.

## Success Criteria

- [x] Commands execute only after Claude Code displays its prompt
- [x] No arbitrary delays used anywhere in the system
- [x] Autocommands reliably detect Claude Code readiness
- [x] Commands execute immediately when Claude Code is ready
- [x] System works consistently across all Claude Code startup scenarios
- [x] Terminal remains in insert mode after command execution
- [x] No duplicate command executions

## Technical Design

### Current Problems

1. **Arbitrary Delays**: System uses hardcoded delays (2000ms) that don't match actual Claude Code readiness
2. **Early Execution**: Commands execute during startup sequence before prompt appears
3. **Unreliable Timing**: Delays don't account for varying Claude Code startup times
4. **Poor User Experience**: Commands appear in terminal output instead of at prompt

### Proposed Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                Terminal Output Monitor                      │
│          Watches for Claude Code prompt patterns           │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│                Claude State Machine                         │
│    STARTING → READY → EXECUTING → READY                    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│              Command Queue Processor                        │
│        Executes commands only when READY state             │
└─────────────────────────────────────────────────────────────┘
```

### Detection Strategy

1. **Terminal Output Monitoring**: Use `TermEnter` and buffer change events to monitor Claude output
2. **Prompt Pattern Detection**: Look for Claude Code's specific prompt patterns:
   - ">" prompt indicator
   - "? for shortcuts" text
   - Cursor position at input line
3. **State Machine**: Track Claude Code states without delays
4. **Event-Driven Execution**: Execute commands immediately upon true readiness

## Implementation Phases

### Phase 1: Terminal Output Monitor [COMPLETED]
**Objective**: Create a system to monitor Claude Code terminal output for readiness indicators
**Complexity**: Medium

Tasks:
- [x] Create terminal output monitoring module in `lua/neotex/plugins/ai/claude/core/terminal-monitor.lua`
- [x] Implement `TermEnter` autocommand for Claude Code terminals
- [x] Add buffer content monitoring with `TextChanged` in terminal mode
- [x] Create prompt pattern detection functions
- [x] Add cursor position tracking for input readiness
- [x] Implement safe buffer content reading with error handling

Testing:
```bash
# Test terminal output detection
:lua require('neotex.plugins.ai.claude.core.terminal-monitor').test_prompt_detection()
```

### Phase 2: Claude State Machine [COMPLETED]
**Objective**: Replace delay-based readiness with proper state tracking
**Complexity**: Medium

Tasks:
- [x] Remove all `vim.defer_fn` delays from `lua/neotex/config/autocmds.lua`
- [x] Remove delays from `lua/neotex/plugins/ai/claude/core/command-queue.lua`
- [x] Implement Claude state machine with states: STARTING, READY, EXECUTING
- [x] Add state transition functions based on terminal monitoring
- [x] Update `on_claude_ready` to use state machine instead of delays
- [x] Add state persistence for session recovery

Testing:
```bash
# Test state machine transitions
:lua require('neotex.plugins.ai.claude.core.command-queue').test_state_machine()
```

### Phase 3: Event-Driven Command Execution [COMPLETED]
**Objective**: Execute commands immediately when Claude Code reaches READY state
**Complexity**: Medium

Tasks:
- [x] Modify `process_pending_commands` to trigger on state change events
- [x] Remove artificial delays from command execution strategies
- [x] Add immediate execution when Claude transitions to READY state
- [x] Implement proper command queuing during STARTING and EXECUTING states
- [x] Add command execution confirmation through terminal monitoring
- [x] Ensure single command execution (no queue processing loops)

Testing:
```bash
# Test immediate command execution
<leader>ac  # Select command, should execute when Claude shows prompt
```

### Phase 4: Integration and Optimization [COMPLETED]
**Objective**: Integrate all components and optimize for reliability
**Complexity**: High

Tasks:
- [x] Update autocommand system in `lua/neotex/config/autocmds.lua` to use new monitoring
- [x] Remove all delay-based debouncing logic
- [x] Add comprehensive error handling for terminal monitoring failures
- [x] Implement fallback detection methods for edge cases
- [x] Add configuration options for prompt patterns and detection sensitivity
- [x] Update picker integration to work with new immediate execution
- [x] Add debug logging for state transitions and detection events
- [x] Optimize performance for high-frequency terminal updates

Testing:
```bash
# Full integration test
:TestSuite  # Run all tests
# Manual testing scenarios:
# 1. Fresh Claude Code startup with queued command
# 2. Existing Claude Code with new command
# 3. Multiple rapid command selections
# 4. Claude Code restart scenarios
```

## Technical Implementation Details

### Terminal Output Monitoring

```lua
-- Pattern matching for Claude Code readiness
local CLAUDE_READY_PATTERNS = {
  prompt_indicator = ">%s*$",  -- Line ending with ">" and optional whitespace
  shortcuts_text = "?%s+for%s+shortcuts",  -- "? for shortcuts" indicator
  welcome_complete = "cwd:%s+/.+$",  -- Current working directory shown
}

-- Monitor terminal buffer changes
local function monitor_claude_output(buf)
  -- Read last few lines of terminal buffer
  -- Check for readiness patterns
  -- Trigger state transition when ready
end
```

### State Machine Implementation

```lua
local CLAUDE_STATES = {
  STARTING = "starting",    -- Claude Code initializing
  READY = "ready",         -- Ready for commands
  EXECUTING = "executing", -- Processing command
}

local function transition_to_ready(buf)
  -- Update state
  -- Process pending commands immediately
  -- No delays used
end
```

### Autocommand Integration

```lua
-- Replace delay-based detection
api.nvim_create_autocmd("TermEnter", {
  pattern = "term://*claude*",
  callback = function(ev)
    -- Start monitoring this terminal
    -- No delays - immediate monitoring setup
  end
})

api.nvim_create_autocmd("TextChanged", {
  pattern = "term://*claude*",
  callback = function(ev)
    -- Check if Claude became ready
    -- Trigger immediate command execution if ready
  end
})
```

## Testing Strategy

### Unit Tests
- Terminal output pattern detection
- State machine transitions
- Command execution without delays
- Error handling for invalid terminals

### Integration Tests
- Full picker-to-execution workflow
- Claude Code restart scenarios
- Multiple command handling
- Terminal focus and insert mode

### Performance Tests
- High-frequency terminal updates
- Multiple Claude Code instances
- Memory usage during monitoring
- CPU usage optimization

## Migration Strategy

1. **Phase 1**: Add new monitoring alongside existing delays
2. **Phase 2**: Gradually replace delays with state machine
3. **Phase 3**: Remove all delay-based code
4. **Phase 4**: Optimize and cleanup

## Dependencies

- Existing command queue system (enhanced, not replaced)
- Terminal detection utilities (enhanced)
- Autocommand infrastructure (modified)
- Notification system (unchanged)

## Risk Mitigation

### High Frequency Terminal Updates
- **Risk**: TextChanged events firing too frequently
- **Mitigation**: Debounce pattern detection, not command execution

### Pattern Detection Failures
- **Risk**: Claude Code output variations not detected
- **Mitigation**: Multiple detection patterns, fallback methods

### State Synchronization Issues
- **Risk**: State machine out of sync with actual Claude state
- **Mitigation**: Recovery mechanisms, periodic state validation

## Configuration Options

```lua
claude_monitor = {
  prompt_patterns = CLAUDE_READY_PATTERNS,  -- Customizable patterns
  detection_sensitivity = "normal",         -- "low", "normal", "high"
  fallback_enabled = true,                  -- Enable fallback detection
  debug_monitoring = false,                 -- Debug terminal monitoring
}
```

## Notes

### Design Principles
- **No Arbitrary Delays**: All timing based on actual Claude Code state
- **Event-Driven**: React to Claude changes, don't poll or guess
- **Reliable Detection**: Multiple indicators ensure robust readiness detection
- **Immediate Execution**: Commands execute as soon as Claude is ready
- **Graceful Degradation**: Fallbacks handle edge cases

### Performance Considerations
- Terminal monitoring adds event listeners but with minimal overhead
- Pattern detection is O(1) string matching on small terminal output
- State machine transitions are instant
- No polling or continuous delays

### Backward Compatibility
- Command queue API unchanged
- Picker integration unchanged
- User experience improved (faster, more reliable)
- Configuration maintains existing options