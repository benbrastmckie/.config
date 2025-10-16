# Event-Driven Claude Code Command Insertion Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases successfully implemented and committed:
- Phase 1: Channel Validation Infrastructure ✓
- Phase 2: Remove Time-Based Detection ✓
- Phase 3: Enhanced Fallback Detection ✓
- Phase 4: Cleanup and Optimization ✓

Implementation Date: 2025-09-30
Total Commits: 4
Primary File Modified: lua/neotex/plugins/ai/claude/core/terminal-monitor.lua

## Metadata
- **Date**: 2025-09-30
- **Plan Number**: 012
- **Feature**: Event-driven autocommand architecture for Claude Code command insertion
- **Scope**: Refactor terminal-monitor.lua, command-queue.lua, and picker.lua to use channel validation instead of time-based delays
- **Estimated Phases**: 4
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/nvim/specs/reports/020_command_insertion_autocommand_architecture.md

## Overview

### Problem Statement
Current implementation uses a fixed 3-second delay to detect Claude Code readiness, causing poor UX when commands are selected before Claude Code starts:
- Commands from `<leader>ac` picker get queued but don't execute when Claude opens
- Arbitrary 3-second wait is too slow on fast systems, potentially too fast on slow systems
- Time-based approach is inelegant and unreliable

### Solution
Replace time-based delays with event-driven channel validation:
- Use TermOpen autocommand to detect Claude Code terminal creation immediately
- Validate terminal readiness via channel communication (no pattern matching)
- Signal command queue when channel is confirmed responsive
- Remove all arbitrary delays in favor of Neovim's event system

### Expected Benefits
- **10x faster execution**: 100-300ms vs 3000ms for command insertion
- **More reliable**: Channel validation more robust than pattern matching or timeouts
- **Better UX**: Near-instant command execution when Claude Code opens
- **Cleaner code**: Standard autocommand patterns, no polling timers
- **Maintainable**: Well-documented Neovim primitives

## Success Criteria
- [ ] Commands selected before Claude Code starts execute within 500ms of terminal opening
- [ ] Commands selected with Claude Code already open execute immediately (<50ms)
- [ ] No "time_based_detection" messages in debug logs (replaced with "channel_validated")
- [ ] All existing command queue functionality preserved
- [ ] No regressions in non-Claude terminal monitoring
- [ ] Debug mode shows clear event flow: TermOpen → channel_validated → on_claude_ready → queue_processed

## Technical Design

### Architecture Changes

#### Before (Time-Based)
```
Command selected → Queue → Claude opens → Wait 3000ms → Check patterns → Ready
```

#### After (Event-Driven)
```
Command selected → Queue → Claude opens → TermOpen fires → Channel validated → Ready
```

### Component Modifications

**1. terminal-monitor.lua**
- Remove time-based detection (line 268-284)
- Add TermOpen autocommand with channel validation
- Keep BufEnter/WinEnter fallback for existing terminals
- Remove periodic timer for Claude terminals

**2. command-queue.lua**
- No changes needed (already has on_claude_ready callback)
- State machine already transitions READY → process queue
- Verify transition_state properly processes pending commands

**3. picker.lua (optional enhancement)**
- Already calls command_queue.send_command
- Already opens Claude Code if not running
- No changes strictly required, works with new monitor

### Channel Validation Function

Core readiness detection:
```lua
local function validate_channel_ready(buf)
  local channel = vim.api.nvim_buf_get_option(buf, 'channel')
  if not channel or channel == 0 then
    return false
  end

  -- Channel is ready if we can send empty string without error
  local success = pcall(vim.api.nvim_chan_send, channel, "")
  return success
end
```

### Event Flow

**Scenario 1: Command before Claude exists**
```
User: <leader>ac → select command
  ↓
picker.lua: send_command_to_terminal()
  ↓
command-queue.lua: queue_command() + open Claude
  ↓
[TermOpen event fires]
  ↓
terminal-monitor.lua: validate channel → on_claude_ready()
  ↓
command-queue.lua: transition_state(READY) → process_pending_commands()
  ↓
Result: Command executes ~100-300ms after Claude opens
```

**Scenario 2: Command with Claude already open**
```
User: <leader>ac → select command
  ↓
picker.lua: send_command_to_terminal()
  ↓
command-queue.lua: find_claude_terminal() [found] → execute immediately
  ↓
Result: Command executes immediately (<50ms)
```

## Implementation Phases

### Phase 1: Channel Validation Infrastructure [COMPLETED]
**Objective**: Replace time-based detection with channel validation in terminal-monitor.lua
**Complexity**: Low
**Risk**: Low (isolated change, existing fallbacks remain)

Tasks:
- [x] Add `validate_channel_ready(buf)` helper function to terminal-monitor.lua
- [x] Create new TermOpen autocommand handler for channel validation
- [x] Test TermOpen fires when Claude Code opens
- [x] Verify channel validation correctly detects ready state
- [x] Confirm on_claude_ready callback is invoked with "channel_validated" reason

Testing:
```bash
# Enable debug mode in terminal-monitor
:lua require('neotex.plugins.ai.claude.core.terminal-monitor')._debug_enabled = true

# Test flow:
# 1. Select command with <leader>ac (Claude not running)
# 2. Observe logs for TermOpen event
# 3. Verify "channel_validated" detection
# 4. Confirm command executes within 500ms
```

Expected output in logs:
```
[DEBUG] TerminalMonitor: Detected Claude terminal by name
[DEBUG] TerminalMonitor: Channel validation successful
[DEBUG] TerminalMonitor: Claude Code detected as ready (reason: channel_validated)
[DEBUG] CommandQueue: State transition: WAITING → READY
[DEBUG] CommandQueue: Processing queued commands
```

Files modified:
- lua/neotex/plugins/ai/claude/core/terminal-monitor.lua

### Phase 2: Remove Time-Based Detection [COMPLETED]
**Objective**: Remove old 3-second delay logic and rely on event-driven detection
**Complexity**: Low
**Risk**: Low (Phase 1 already provides replacement)

Tasks:
- [x] Remove vim.defer_fn 3-second delay from monitor_claude_output (line 275-284)
- [x] Update monitor_claude_output to rely solely on autocommands
- [x] Keep monitored_terminals tracking structure (used by autocommands)
- [x] Test command execution timing improved (no 3-second wait)
- [x] Verify no regressions in existing terminal detection

Testing:
```bash
# Timing test
:lua local start = vim.loop.hrtime()
# Select command from <leader>ac
# Measure time until execution
:lua print("Execution time: " .. (vim.loop.hrtime() - start) / 1e6 .. "ms")

# Expected: <500ms (vs 3000ms+ before)
```

Files modified:
- lua/neotex/plugins/ai/claude/core/terminal-monitor.lua

### Phase 3: Enhanced Fallback Detection [COMPLETED]
**Objective**: Add BufEnter/WinEnter fallback for existing Claude terminals
**Complexity**: Low
**Risk**: Low (adds safety net, doesn't replace primary detection)

Tasks:
- [x] Add BufEnter/WinEnter autocommands for Claude terminals
- [x] Check if terminal already marked ready before re-validating
- [x] Test entering existing Claude terminal triggers fallback if needed
- [x] Verify fallback doesn't duplicate readiness signals
- [x] Confirm monitored_terminals state properly tracked

Testing:
```bash
# Test fallback scenario:
# 1. Open Claude Code manually with <C-c>
# 2. Wait for it to fully initialize
# 3. Switch to another window
# 4. Select command from <leader>ac
# 5. Switch back to Claude window
# 6. Verify command executes immediately

# Expected: BufEnter detects existing terminal and validates channel
```

Files modified:
- lua/neotex/plugins/ai/claude/core/terminal-monitor.lua

### Phase 4: Cleanup and Optimization [COMPLETED]
**Objective**: Remove unused code and optimize monitoring
**Complexity**: Low
**Risk**: Very Low (removing unused code)

Tasks:
- [x] Keep pattern-based detection code (still used for non-Claude terminals)
- [x] Update periodic timer comments (clarify it's for non-Claude only)
- [x] TextChanged already skips Claude terminals (verified)
- [x] Update debug logging messages for clarity
- [x] Add comprehensive architecture documentation at file top

Testing:
```bash
# Verify cleanup successful:
# 1. Search codebase for removed functions (should not be referenced)
# 2. Test all command execution scenarios still work
# 3. Verify debug logs are clear and helpful
# 4. Check no orphaned timer/autocommand handlers

# Manual inspection
:lua require('neotex.plugins.ai.claude.core.terminal-monitor').get_status()
```

Expected status output:
```lua
{
  monitored_count = 1,
  terminals = {
    [bufnr] = {
      buffer = bufnr,
      started_at = timestamp,
      ready_detected = true,
      detection_method = "channel_validated",
      monitoring_duration = elapsed_seconds
    }
  }
}
```

Files modified:
- lua/neotex/plugins/ai/claude/core/terminal-monitor.lua

## Testing Strategy

### Unit Tests

**Test 1: Channel Validation**
```lua
function test_channel_validation()
  local monitor = require('neotex.plugins.ai.claude.core.terminal-monitor')

  -- Test invalid buffer
  assert(not monitor.validate_channel_ready(99999), "Invalid buffer should return false")

  -- Test buffer without channel
  local buf = vim.api.nvim_create_buf(false, true)
  assert(not monitor.validate_channel_ready(buf), "Buffer without channel should return false")

  print("Channel validation tests passed")
end
```

**Test 2: TermOpen Detection**
```lua
function test_termopen_detection()
  local monitor = require('neotex.plugins.ai.claude.core.terminal-monitor')

  -- Clear monitoring state
  monitor._test_reset_state()

  -- Open terminal
  vim.cmd('terminal')
  local buf = vim.api.nvim_get_current_buf()

  -- Wait for TermOpen to fire
  vim.wait(1000, function()
    local status = monitor.get_status()
    return status.monitored_count > 0
  end)

  local status = monitor.get_status()
  assert(status.monitored_count == 1, "Terminal should be monitored")

  print("TermOpen detection tests passed")
end
```

### Integration Tests

**Test 1: Command Before Claude Exists**
```lua
function test_command_before_claude()
  -- 1. Ensure Claude Code not running
  vim.cmd('bufdo if &buftype == "terminal" | bd! | endif')

  -- 2. Queue a test command
  local queue = require('neotex.plugins.ai.claude.core.command-queue')
  queue.send_command("/test-command", "integration_test", 1)

  -- 3. Open Claude Code
  local start_time = vim.loop.hrtime()
  require('claude-code').toggle()

  -- 4. Wait for command execution
  local executed = vim.wait(1000, function()
    local state = queue.get_state()
    return state.queue_size == 0  -- Command was processed
  end)

  local elapsed = (vim.loop.hrtime() - start_time) / 1e6

  assert(executed, "Command should execute within 1000ms")
  assert(elapsed < 500, "Command should execute in <500ms, got " .. elapsed .. "ms")

  print("Integration test passed: " .. elapsed .. "ms execution time")
end
```

**Test 2: Command With Claude Already Open**
```lua
function test_command_with_claude_open()
  -- 1. Ensure Claude Code is running
  require('claude-code').toggle()
  vim.wait(2000)  -- Let it fully initialize

  -- 2. Send command
  local queue = require('neotex.plugins.ai.claude.core.command-queue')
  local start_time = vim.loop.hrtime()
  queue.send_command("/test-command-2", "integration_test", 1)

  -- 3. Verify immediate execution
  local state = queue.get_state()
  local elapsed = (vim.loop.hrtime() - start_time) / 1e6

  assert(state.queue_size == 0, "Command should execute immediately")
  assert(elapsed < 100, "Command should execute in <100ms, got " .. elapsed .. "ms")

  print("Immediate execution test passed: " .. elapsed .. "ms")
end
```

### Manual Testing Checklist

- [ ] Select command from `<leader>ac` with Claude Code closed → opens and executes quickly
- [ ] Select command from `<leader>ac` with Claude Code open → executes immediately
- [ ] Multiple commands queued before Claude opens → all execute in sequence
- [ ] Claude Code terminal closed while command queued → graceful failure message
- [ ] Switch between buffers with Claude open → no duplicate readiness signals
- [ ] Enable debug mode → clear event flow visible in logs
- [ ] Restart Neovim with pending commands → persistent queue restored and processed

## Performance Benchmarks

### Success Metrics
- Command insertion latency: <500ms (target: <200ms) vs 3000ms+ currently
- Immediate execution: <100ms when Claude already open
- Memory usage: No increase (same monitoring structure)
- CPU usage: Reduced (no periodic polling)

### Measurement Commands
```lua
-- Enable telemetry
require('neotex.plugins.ai.claude.core.command-queue')._telemetry_enabled = true

-- Run benchmark
local function benchmark_command_insertion()
  local times = {}
  for i = 1, 10 do
    -- Close Claude
    vim.cmd('bufdo if &buftype == "terminal" | bd! | endif')

    -- Measure command execution
    local start = vim.loop.hrtime()
    require('neotex.plugins.ai.claude.core.command-queue').send_command("/test", "benchmark", 1)
    require('claude-code').toggle()

    vim.wait(2000, function()
      return require('neotex.plugins.ai.claude.core.command-queue').get_state().queue_size == 0
    end)

    local elapsed = (vim.loop.hrtime() - start) / 1e6
    table.insert(times, elapsed)

    vim.wait(1000)  -- Cool down between tests
  end

  local avg = 0
  for _, t in ipairs(times) do avg = avg + t end
  avg = avg / #times

  print(string.format("Average execution time: %.2fms", avg))
  print(string.format("Min: %.2fms, Max: %.2fms", math.min(unpack(times)), math.max(unpack(times))))
end
```

## Documentation Requirements

### Code Documentation
- [ ] Add docstring to validate_channel_ready explaining channel validation approach
- [ ] Document TermOpen autocommand handler purpose and event flow
- [ ] Add comments explaining why channel validation preferred over pattern matching
- [ ] Update terminal-monitor.lua module documentation with new architecture

### User Documentation
- [ ] Update debugging guide with new event flow
- [ ] Add troubleshooting section for command execution timing
- [ ] Document configuration options (if any added)
- [ ] Create migration notes for users with custom terminal monitoring

### Technical Documentation
- [ ] Update architecture diagrams in research report with final implementation
- [ ] Document performance improvements in CHANGELOG.md
- [ ] Add examples of event-driven pattern for future features
- [ ] Create summary document linking plan → implementation → results

## Risk Mitigation

### Risk 1: Channel available but Claude not accepting commands
**Likelihood**: Low
**Mitigation**:
- Add 10-50ms vim.schedule delay after channel validation
- Test with Claude Code debug mode to verify initialization timing
- Implement retry logic in command execution (already exists)

### Risk 2: TermOpen doesn't fire in edge cases
**Likelihood**: Very Low
**Mitigation**:
- Keep BufEnter/WinEnter fallback detection (Phase 3)
- Monitor error reports after deployment
- User can manually trigger with <leader>ac queue view

### Risk 3: Breaking non-Claude terminal monitoring
**Likelihood**: Very Low
**Mitigation**:
- Scope all changes to Claude-specific code paths
- Keep pattern-based detection for non-Claude terminals
- Comprehensive testing of vim-test, toggleterm integration
- Verify periodic timer still works for other terminals if needed

## Dependencies

### Internal Dependencies
- claude-code.nvim plugin (already installed)
- neotex.plugins.ai.claude.core.command-queue
- neotex.plugins.ai.claude.core.terminal-detection
- neotex.util.notifications

### External Dependencies
None (uses standard Neovim APIs)

### Configuration Dependencies
- Debug logging: `terminal_monitor.debug_enabled` config option
- Existing autocommand group: "ClaudeTerminalMonitor"

## Rollback Plan

If critical issues discovered:

1. **Immediate Rollback** (Phase 1-2):
   - Restore time-based detection with vim.defer_fn
   - Keep new autocommands as supplementary detection
   - Revert to 3-second timeout as primary method

2. **Partial Rollback** (Phase 3-4):
   - Keep channel validation for new terminals (TermOpen)
   - Restore time-based detection for existing terminals
   - Remove cleanup changes that caused issues

3. **Git Revert**:
   ```bash
   git revert <commit-hash>
   git commit -m "Revert event-driven command insertion due to <issue>"
   ```

## Post-Implementation Tasks

- [ ] Monitor user feedback for timing issues
- [ ] Collect telemetry data on execution times
- [ ] Update related features to use event-driven pattern
- [ ] Consider applying pattern to other terminal integrations
- [ ] Document learnings for future autocommand-based features

## Notes

### Design Decisions

**Why channel validation over pattern matching?**
- Terminal buffer content reading is asynchronous and unreliable
- Patterns can change with Claude Code updates
- Channel validation is implementation-agnostic
- Simpler and faster than parsing terminal output

**Why TermOpen over other events?**
- TermOpen fires immediately when terminal created
- Channel guaranteed available at TermOpen time
- Earlier than TermEnter (which requires terminal mode)
- More reliable than BufWinEnter (which has timing issues)

**Why keep BufEnter fallback?**
- Handles edge case of entering existing terminal
- Safety net if TermOpen missed (shouldn't happen, but defensive)
- Minimal performance cost (event-driven, not polling)
- Follows best practice of multiple event listeners

### Future Enhancements

1. **Command Batching**: Execute multiple queued commands in single batch
2. **Priority Queue Visualization**: Show queued commands in picker preview
3. **Execution Confirmation**: Visual feedback when command successfully inserted
4. **Retry Configuration**: User-configurable retry count and delay
5. **Telemetry Dashboard**: Display execution time statistics

---

**Plan Status**: Ready for implementation
**Estimated Duration**: 2-4 hours (all phases)
**Next Step**: Begin Phase 1 - Channel Validation Infrastructure
