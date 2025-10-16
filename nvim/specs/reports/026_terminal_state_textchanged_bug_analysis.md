# Terminal State TextChanged Bug Analysis

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 026
- **Scope**: Debug why unified terminal state management isn't working
- **Primary Directory**: `/home/benjamin/.config/nvim`
- **Files Analyzed**:
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/visual.lua`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
- **Related Reports**: 025_claude_code_terminal_timing_synchronization.md
- **Context**: Implementation from plan 015 not working in practice

## Executive Summary

The event-driven terminal state management implementation (Plan 015) has a critical flaw: **TextChanged autocommand doesn't fire in terminal buffers unless the cursor is in that buffer**. This was mentioned in Report 025 but not adequately addressed in the implementation.

### Two Failure Scenarios

1. **Claude not yet started**: TermOpen fires, TextChanged autocommand is created, but never triggers because cursor remains in source buffer
2. **Claude already open**: `is_terminal_ready()` check might pass or fail depending on how much time has elapsed since Claude opened

## Problem Analysis

### Root Cause: TextChanged Autocommand Bug

From Report 025 (lines 212-213):
> **Note**: TextChanged autocmd has a documented bug in terminal buffers - it only fires when the cursor is in the buffer, which is why the timer-based `wait_for_ready()` approach is more reliable.

**We removed the timer-based approach but didn't add an alternative!**

### Current Implementation Flow

```
User Action (<leader>ac or visual selection)
  ↓
find_claude_terminal() → Not found
  ↓
vim.cmd('ClaudeCode')
  ↓
queue_command(text)
  ↓
TermOpen autocommand fires
  ↓
State = OPENING
  ↓
TextChanged autocommand created
  ↓
[STUCK HERE - TextChanged NEVER fires because cursor not in terminal]
  ↓
Command never sent, queue never flushed
```

### Code Evidence

**terminal-state.lua:233-247** (the problematic autocommand):
```lua
-- Monitor terminal content changes for readiness
vim.api.nvim_create_autocmd("TextChanged", {
  group = ready_check_group,
  buffer = args.buf,
  callback = function()
    if M.is_terminal_ready(args.buf) then
      state = M.State.READY
      M.flush_queue(args.buf)
      vim.api.nvim_del_augroup_by_id(ready_check_group)
    end
  end
})
```

**This autocommand only fires when**:
- Cursor is in the terminal buffer
- Buffer content changes
- User is in insert or normal mode in that buffer

**It does NOT fire when**:
- Terminal opens in background
- User remains in source buffer
- Terminal updates while user is elsewhere

## Why Report 025 Warned Against This

Report 025, line 212:
> **Note**: TextChanged autocmd has a documented bug in terminal buffers - it only fires when the cursor is in the buffer, which is why the timer-based `wait_for_ready()` approach is more reliable.

But then the report still recommended using TextChanged (lines 184-207) without addressing this caveat. The implementation followed the example code but didn't include a fallback.

## Why Timer-Based Approach Was Actually Needed

The old `wait_for_ready()` function in visual.lua (lines 240-289) used:
```lua
local timer = vim.loop.new_timer()
timer:start(100, 100, vim.schedule_wrap(function()
  local claude_buf = find_claude_terminal()
  if not claude_buf then
    -- Check timeout
    return
  end

  -- Check if terminal is ready by looking for prompt
  local lines = vim.api.nvim_buf_get_lines(claude_buf, -10, -1, false)
  -- Pattern matching here...

  if is_ready then
    timer:stop()
    callback(claude_buf)
  end
end))
```

**This worked because**: Timer polling checks terminal state regardless of cursor position!

## Test Case Reproduction

### Test 1: Claude Not Started
```bash
# Start fresh nvim session
nvim test.lua

# In visual mode, select text
# Press <leader>as (or use command picker)

# Expected: Command sent to Claude
# Actual: Command queued but never sent (TextChanged never fires)
```

### Test 2: Claude Already Open
```bash
# Open Claude first
:ClaudeCode

# Wait for welcome screen
# Switch back to source buffer

# Select text, press <leader>as

# Expected: Command sent immediately
# Actual: May or may not work depending on timing of is_terminal_ready() check
```

## Solutions

### Solution 1: Hybrid Timer + Autocommand (Recommended)

Keep the event-driven architecture but add a timer fallback:

```lua
function M.setup()
  vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*claude*",
    callback = function(args)
      state = M.State.OPENING
      local buf = args.buf

      -- Strategy 1: Try TextChanged autocommand (works if user enters terminal)
      local ready_check_group = vim.api.nvim_create_augroup(
        "ClaudeReadyCheck_" .. buf,
        { clear = true }
      )

      vim.api.nvim_create_autocmd("TextChanged", {
        group = ready_check_group,
        buffer = buf,
        callback = function()
          if M.is_terminal_ready(buf) then
            state = M.State.READY
            M.flush_queue(buf)
            vim.api.nvim_del_augroup_by_id(ready_check_group)
          end
        end
      })

      -- Strategy 2: Timer fallback (works regardless of cursor position)
      local timer = vim.loop.new_timer()
      local start_time = vim.loop.now()
      local timeout = 3000  -- 3 seconds

      timer:start(100, 100, vim.schedule_wrap(function()
        -- Stop if TextChanged already handled it
        if state == M.State.READY or state == M.State.CLOSED then
          timer:stop()
          return
        end

        -- Check if terminal is ready
        if M.is_terminal_ready(buf) then
          timer:stop()
          state = M.State.READY
          M.flush_queue(buf)
          -- Clean up TextChanged autocommand
          pcall(vim.api.nvim_del_augroup_by_id, ready_check_group)
        elseif vim.loop.now() - start_time > timeout then
          -- Timeout - try sending anyway
          timer:stop()
          M.flush_queue(buf)
        end
      end))
    end
  })

  -- Monitor terminal close
  vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*claude*",
    callback = function()
      state = M.State.CLOSED
      pending_commands = {}
    end
  })
end
```

**Advantages**:
- Best of both worlds: Fast when TextChanged works, reliable fallback when it doesn't
- Still event-driven for the happy path
- Timer only runs for 3 seconds max
- No infinite polling

### Solution 2: Focus Terminal Then Send (Alternative)

Force cursor into terminal before queuing command:

```lua
function M.queue_command(command_text, opts)
  opts = opts or {}

  table.insert(pending_commands, {
    text = command_text,
    timestamp = os.time(),
    opts = opts
  })

  local claude_buf = M.find_claude_terminal()
  if claude_buf then
    if M.is_terminal_ready(claude_buf) then
      -- Already ready, send immediately
      M.flush_queue(claude_buf)
    else
      -- Focus terminal to trigger TextChanged
      M.focus_terminal(claude_buf)

      -- Small delay for terminal to render, then check
      vim.defer_fn(function()
        if M.is_terminal_ready(claude_buf) then
          M.flush_queue(claude_buf)
        end
      end, 500)
    end
  end
end
```

**Disadvantages**:
- Forces focus change (user experience issue)
- Still has a delay
- Doesn't fully solve the problem

### Solution 3: Use TermEnter Instead (Problematic)

```lua
vim.api.nvim_create_autocmd("TermEnter", {
  group = ready_check_group,
  buffer = buf,
  callback = function()
    -- Check readiness when user enters terminal
    if M.is_terminal_ready(buf) then
      state = M.State.READY
      M.flush_queue(buf)
      vim.api.nvim_del_augroup_by_id(ready_check_group)
    end
  end
})
```

**Problem**: Requires user to manually enter terminal - defeats the purpose of automation.

### Solution 4: Immediate Send with Retry (Simplest)

Just send commands immediately with a small buffer:

```lua
function M.queue_command(command_text, opts)
  opts = opts or {}

  local claude_buf = M.find_claude_terminal()
  if not claude_buf then
    -- No terminal, queue for later
    table.insert(pending_commands, {
      text = command_text,
      timestamp = os.time(),
      opts = opts
    })
    return
  end

  -- Terminal exists - try sending with small delay
  vim.defer_fn(function()
    M.send_to_terminal(claude_buf, command_text, opts)
    if opts.notification then
      opts.notification()
    end
  end, 800)  -- 800ms should be enough for Claude to render
end
```

**Advantages**:
- Simple
- Works most of the time
- No complex state management

**Disadvantages**:
- Fixed delay (not truly event-driven)
- Might fail if Claude takes longer than 800ms

## Recommended Implementation: Solution 1 (Hybrid)

The hybrid approach gives us:
1. **Event-driven when possible** (TextChanged fires if user focuses terminal)
2. **Timer fallback for reliability** (works when TextChanged doesn't fire)
3. **Short timeout** (3 seconds max, not infinite polling)
4. **Automatic cleanup** (timer stops when done)

This addresses the limitations of pure event-driven while avoiding the problems of pure timer-based.

## Implementation Steps

1. Modify `terminal-state.lua` setup() function
2. Add timer fallback after TextChanged autocommand
3. Add state check to prevent double execution
4. Add timeout handling
5. Test both scenarios (Claude open and not open)

## Lessons Learned

1. **Read warnings carefully**: Report 025 warned about TextChanged bug but we didn't act on it
2. **Test edge cases**: Should have tested before committing
3. **Pure event-driven isn't always feasible**: Neovim's terminal handling has quirks
4. **Timers aren't always bad**: Used sparingly, they solve real problems

## Why Report 025 Recommended This Approach

Report 025 recommended event-driven despite the warning because:
- It focused on eliminating timer *polling* (100ms continuous checks)
- It assumed TextChanged would fire reliably enough
- The example code didn't show the fallback mechanism

The report was correct that continuous polling is inefficient, but wrong that we could rely solely on TextChanged.

## Conclusion

The implementation from Plan 015 has a critical bug: TextChanged doesn't fire when cursor isn't in the terminal buffer. We need to add a timer fallback (Solution 1) to make it work reliably while still maintaining the event-driven architecture for the happy path.

**Recommendation**: Implement Solution 1 (Hybrid Timer + Autocommand) in a follow-up plan.

## References

### Code Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua:220-261` - Current broken implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/visual.lua:181-203` - Calling code

### Related Reports
- `025_claude_code_terminal_timing_synchronization.md` - Original research (warned about this)

### Implementation Plan
- `015_unified_terminal_state_management.md` - Plan that didn't account for TextChanged bug

### Neovim Documentation
- `:help TextChanged` - Documents the cursor requirement
- `:help TermOpen` - Terminal opening event
- `:help vim.loop.new_timer()` - Timer API
