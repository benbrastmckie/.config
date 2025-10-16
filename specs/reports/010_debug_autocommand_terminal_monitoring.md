# Debug Report: Autocommand Terminal Monitoring Failure

## Metadata
- **Date**: 2025-09-29
- **Issue**: Event-driven Claude command execution not detecting ready state
- **Severity**: High
- **Type**: Debugging investigation
- **Related Reports**:
  - `/home/benjamin/.config/nvim/specs/reports/009_claude_command_timing_synchronization.md`
  - `/home/benjamin/.config/nvim/specs/plans/003_claude_command_timing_synchronization.md`

## Problem Statement

The implemented event-driven solution for Claude Code command execution is failing to detect when Claude Code becomes ready. Commands are only executing after the 10-second fallback timeout, not when Claude actually becomes ready. The system shows three notifications:
1. "Claude Code did not become ready in 10 seconds"
2. "Command '/cleanup' sent to Claude Code"
3. "Command queued, will execute when Claude is ready"

This indicates the autocommand-based monitoring is not working as intended.

## Investigation Process

### 1. Reviewed Implementation
- Examined `terminal_monitor.lua` using TextChangedT autocommand
- Checked `command_queue.lua` for User event handling
- Analyzed `terminal_integration.lua` coordination logic

### 2. Neovim Documentation Research
- Researched available terminal buffer autocommands
- Investigated TextChangedT behavior with terminal buffers
- Explored alternative events for terminal monitoring

### 3. Event Compatibility Analysis
- Tested which autocommands fire for terminal buffers
- Identified fundamental limitation with TextChangedT

## Findings

### Root Cause Analysis

**PRIMARY ISSUE: TextChangedT does not fire for terminal buffers**

The TextChangedT autocommand is designed for regular text buffers in Terminal mode (t mode), NOT for terminal buffers (buftype=terminal). This is a fundamental misunderstanding of Neovim's event system.

#### Evidence from Neovim Documentation

Terminal buffers have these specific events:
- `TermOpen` - When terminal job starts
- `TermClose` - When terminal job ends
- `TermEnter` - After entering Terminal-mode
- `TermLeave` - After leaving Terminal-mode
- `TermRequest` - When terminal emits OSC/DCS/APC sequences
- `TermResponse` - When Neovim receives terminal responses

**Critical Gap**: No built-in event fires when terminal buffer content changes.

### Contributing Factors

1. **Event Misconception**: The plan assumed TextChangedT would work for terminal buffers
2. **No Content Change Event**: Neovim lacks a native event for terminal output changes
3. **Buffer Type Difference**: Terminal buffers (buftype=terminal) are fundamentally different from text buffers

### Evidence

From `terminal_monitor.lua` line 174-178:
```lua
-- Create buffer-specific autocommand for TextChangedT
vim.api.nvim_create_autocmd("TextChangedT", {
  group = au_group,
  buffer = buf,
  desc = "Monitor Claude terminal for ready state",
```

This autocommand never fires because:
- Terminal buffers don't trigger TextChangedT
- TextChangedT is for text buffers in terminal mode, not terminal buffers

### Test Results

When testing the implementation:
1. Claude Code opens successfully
2. Terminal buffer is created and found
3. Monitor is setup with TextChangedT autocommand
4. **TextChangedT never fires** (root problem)
5. Ready detection never runs via event
6. 10-second fallback timeout triggers
7. Command executes via fallback mechanism

## Proposed Solutions

### Option 1: Timer-Based Polling (Recommended)

Replace autocommand approach with intelligent timer-based monitoring:

```lua
function M.setup_monitoring(buf, on_ready)
  local timer = vim.loop.new_timer()
  local check_count = 0
  local max_checks = 100  -- 10 seconds at 100ms intervals

  timer:start(100, 100, vim.schedule_wrap(function()
    check_count = check_count + 1

    if M.is_ready(buf) then
      timer:stop()
      timer:close()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "ClaudeCodeReady",
        data = { buffer = buf }
      })
      if on_ready then on_ready(buf) end
    elseif check_count >= max_checks then
      timer:stop()
      timer:close()
      -- Timeout handling
    end
  end))
end
```

**Pros:**
- Actually works with terminal buffers
- Predictable and reliable
- Can adjust polling frequency
- Clean lifecycle management

**Cons:**
- Uses minimal CPU for polling
- Not "pure" event-driven

### Option 2: TermRequest with Prompt Detection

If Claude Code emits OSC sequences for prompts, use TermRequest:

```lua
vim.api.nvim_create_autocmd('TermRequest', {
  buffer = buf,
  callback = function(args)
    local seq = args.data.sequence
    if seq:match('prompt_ready') then  -- If Claude emits this
      -- Fire ready event
    end
  end
})
```

**Pros:**
- True event-driven if Claude supports it
- No polling needed

**Cons:**
- Requires Claude Code to emit specific sequences
- May not be supported

### Option 3: Hybrid Approach with TermEnter

Use TermEnter as a trigger to start checking:

```lua
vim.api.nvim_create_autocmd('TermEnter', {
  buffer = buf,
  callback = function()
    -- Start timer-based checking when user enters terminal
    -- Stop after ready or timeout
  end
})
```

**Pros:**
- Reduces unnecessary polling
- User-action triggered

**Cons:**
- Still requires polling
- May miss auto-execution scenarios

## Recommendations

1. **Immediate Fix**: Implement timer-based polling (Option 1)
2. **Remove TextChangedT**: It will never work for terminal buffers
3. **Optimize Polling**: Start with 50ms intervals, increase to 200ms after 2 seconds
4. **Add Manual Trigger**: Keep debug command for manual ready triggering
5. **Document Limitation**: Note that true event-driven isn't possible with current Neovim

## Next Steps

1. Replace TextChangedT implementation with timer-based approach
2. Test with various Claude Code startup speeds
3. Optimize polling intervals for responsiveness vs CPU usage
4. Consider contributing to Neovim for terminal content change events
5. Update plan documentation to reflect technical constraints

## Technical Implementation Notes

### Timer Management
```lua
local active_timers = {}  -- Track timers for cleanup

function M.cleanup_timer(buf)
  if active_timers[buf] then
    active_timers[buf]:stop()
    active_timers[buf]:close()
    active_timers[buf] = nil
  end
end
```

### Polling Optimization
```lua
local poll_intervals = {
  {duration = 2000, interval = 50},   -- First 2s: check every 50ms
  {duration = 5000, interval = 100},  -- Next 3s: check every 100ms
  {duration = 10000, interval = 200}, -- Last 5s: check every 200ms
}
```

### Ready Detection Improvements
- Check for ANSI escape sequences that clear screen
- Detect cursor position stabilization
- Monitor for specific Claude Code ready indicators

## References

- Neovim Terminal Documentation: `:help terminal`
- Neovim Autocommand Documentation: `:help autocmd-events`
- Terminal Buffer Implementation: `runtime/doc/terminal.txt`
- Related GitHub Issues:
  - [neovim/neovim#8428](https://github.com/neovim/neovim/issues/8428) - Terminal events discussion
  - [neovim/neovim#25856](https://github.com/neovim/neovim/issues/25856) - TermResponse implementation

## Conclusion

The autocommand-based approach failed due to a fundamental misunderstanding: TextChangedT doesn't work with terminal buffers. The only reliable solution is timer-based polling with intelligent optimization. While this isn't as elegant as pure event-driven, it's the only approach that will work with Neovim's current terminal buffer implementation.

---

**Debug Duration**: ~20 minutes
**Root Cause**: TextChangedT incompatible with terminal buffers
**Solution Complexity**: Medium - requires replacing event system with timers