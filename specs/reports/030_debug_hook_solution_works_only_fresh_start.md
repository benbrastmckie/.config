# Debug Report: Hook Solution Works Only on Fresh Start

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 030
- **Issue**: SessionStart hook works on fresh start but not when Claude already open or toggled closed
- **Severity**: High
- **Type**: Debugging investigation
- **Related Reports**:
  - 028_claude_code_hooks_for_terminal_readiness.md
- **Related Plans**:
  - 018_refactor_to_hook_based_readiness_detection.md
- **Affected Files**:
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`

## Problem Statement

Plan 018 implemented a hook-based solution that successfully works when Claude Code is not yet open. However, it **fails in two scenarios**:

1. **Claude already open**: When Claude Code is running and user selects command from `<leader>ac` picker, command is not inserted
2. **Claude toggled closed**: When Claude started then closed with toggle, command selection doesn't reopen and insert

### User Report

> "That worked when claude code was not yet opened, but it doesn't work when claude code is already open, nor when claude code has been started and then toggled closed."

## Investigation Process

### Step 1: Understand SessionStart Hook

**When SessionStart fires**:
- When a **NEW** Claude Code session starts
- When **resuming** an existing session (e.g., `--resume`)

**When SessionStart does NOT fire**:
- When terminal buffer already exists
- When window is closed but session still running
- When user just uses picker with existing session

### Step 2: Trace Code Execution Paths

**Scenario 1: Fresh start (WORKS)**
```
<leader>ac → queue_command()
  ↓
find_claude_terminal() → nil (no terminal)
  ↓
opts.ensure_open → vim.cmd('ClaudeCode')
  ↓
return (queue stays pending)
  ↓
TermOpen fires → SessionStart hook fires → on_claude_ready()
  ↓
flush_queue() → command sent ✓
```

**Scenario 2: Claude already open (FAILS)**
```
<leader>ac → queue_command()
  ↓
find_claude_terminal() → finds buffer
  ↓
is_terminal_ready(claude_buf) → TRUE (has prompt)
  ↓
Lines 137-139: focus_terminal(), flush_queue()
  ↓
Should work! ✓
```

Wait - if `is_terminal_ready()` returns true, it should work! Let me check if there's a different issue...

**Scenario 3: Claude already open but busy (ACTUAL FAILURE)**
```
<leader>ac → queue_command()
  ↓
find_claude_terminal() → finds buffer
  ↓
is_terminal_ready(claude_buf) → FALSE (no prompt visible)
  ↓
Line 141: "If not ready, hook or TextChanged will handle it"
  ↓
NOTHING HAPPENS! ✗
```

**Scenario 4: Claude toggled closed (COMPLEX)**
```
<leader>ac → queue_command()
  ↓
find_claude_terminal() → finds buffer (hidden)
  ↓
is_terminal_ready(claude_buf) → TRUE/FALSE?
  ↓
If TRUE: focus_terminal() called
  ↓
focus_terminal() sees no window → calls ClaudeCode (toggle)
  ↓
But toggle CLOSES if it was open! ✗
```

### Step 3: Identify Root Causes

## Findings

### Root Cause 1: Missing Flush Mechanism for "Exists But Not Ready"

**Problem location**: `queue_command()` lines 136-142

```lua
if M.is_terminal_ready(claude_buf) then
  state = M.State.READY
  M.focus_terminal(claude_buf)
  M.flush_queue(claude_buf)
end
-- If not ready, SessionStart hook or TextChanged will handle it
```

**The bug**: Comment says "hook or TextChanged will handle it" but:
- **SessionStart hook**: Only fires on NEW sessions, not existing ones
- **TextChanged**: Only fires if buffer content changes AND cursor is in buffer

**Result**: If Claude exists but isn't ready (no prompt visible yet), **nothing triggers the flush**.

**Why this happens**:
- Claude might be loading/busy
- User might have scrolled up in terminal
- Terminal might be in the middle of rendering

### Root Cause 2: ClaudeCode is a Toggle, Not an Open

**Problem location**: `focus_terminal()` line 239

```lua
elseif state ~= M.State.OPENING then
  vim.cmd('ClaudeCode')  -- This TOGGLES, doesn't guarantee open!
```

**The bug**: `ClaudeCode` command toggles the window:
- If window is open → closes it
- If window is closed → opens it

**Problem scenario**:
1. Claude running, window visible
2. User closes window with `<C-c>` (buffer still exists)
3. User uses `<leader>ac` picker
4. `focus_terminal()` called
5. Finds buffer exists but no window
6. Calls `ClaudeCode` to "reopen"
7. **But if the buffer was actually visible elsewhere, this might close it!**

### Root Cause 3: State Tracking Might Be Stale

**Problem location**: Global `state` variable

The `state` variable is set in various places:
- `TermOpen` → OPENING
- `on_claude_ready()` → READY
- `TextChanged` → READY
- `TermClose` → CLOSED

**Possible issue**: State might not reflect actual terminal readiness if:
- Terminal scrolled up (no prompt visible)
- Terminal showing error/loading message
- User cleared terminal

## Evidence

### Code Analysis: queue_command()

Current implementation:
```lua
local claude_buf = M.find_claude_terminal()

if not claude_buf then
  -- Handles fresh start ✓
  if opts.ensure_open then
    vim.cmd('ClaudeCode')
  end
  return
end

-- Terminal exists
if M.is_terminal_ready(claude_buf) then
  -- Handles "ready" case ✓
  M.focus_terminal(claude_buf)
  M.flush_queue(claude_buf)
end
-- Handles "not ready" case ✗ - NOTHING HAPPENS
```

**Missing**: Logic for "terminal exists but not ready" case

### Code Analysis: focus_terminal()

```lua
local wins = vim.fn.win_findbuf(claude_buf)
if #wins > 0 then
  -- Window exists - focus it ✓
else
  -- Window doesn't exist - TOGGLE (might close!) ✗
  vim.cmd('ClaudeCode')
end
```

**Problem**: Can't distinguish between:
- "Reopen closed window" (want to open)
- "Window exists elsewhere" (toggle would close)

### Pattern Matching Limitations

`is_terminal_ready()` checks for patterns:
- `^>` - Main prompt
- `Welcome to Claude Code!`
- `────────` - Separator
- `? for shortcuts`

**Issue**: These might not be visible if:
- Terminal scrolled up
- Loading screen shown
- Error message displayed
- User cleared screen

## Proposed Solutions

### Solution 1: Add Delayed Check for "Not Ready" Case

**Location**: `queue_command()` after line 140

```lua
if M.is_terminal_ready(claude_buf) then
  state = M.State.READY
  M.focus_terminal(claude_buf)
  M.flush_queue(claude_buf)
else
  -- NEW: Terminal exists but not ready
  -- Focus and wait for TextChanged
  M.focus_terminal(claude_buf)

  -- Fallback: check again after short delay
  vim.defer_fn(function()
    if M.is_terminal_ready(claude_buf) then
      state = M.State.READY
      M.flush_queue(claude_buf)
    end
  end, 200)
end
```

**Pros**:
- Simple fix
- Handles "not ready" case
- Uses TextChanged as primary, delay as fallback

**Cons**:
- Reintroduces delay-based logic (what we tried to remove)
- Not as clean as hook-based approach

### Solution 2: Force Readiness Check on Focus

**Location**: `focus_terminal()` - add readiness check after focusing

```lua
function M.focus_terminal(claude_buf)
  if not vim.api.nvim_buf_is_valid(claude_buf) then
    return
  end

  local wins = vim.fn.win_findbuf(claude_buf)
  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
    if vim.api.nvim_get_mode().mode == 'n' then
      vim.cmd('startinsert!')
    end

    -- NEW: Check if ready and flush if needed
    vim.schedule(function()
      if M.is_terminal_ready(claude_buf) and #pending_commands > 0 then
        state = M.State.READY
        M.flush_queue(claude_buf)
      end
    end)
  else
    -- Window doesn't exist, reopen logic...
  end
end
```

**Pros**:
- Focus already happens, just adds check
- No extra delay
- Uses vim.schedule for safety

**Cons**:
- Makes focus_terminal() do more than one thing
- Still might miss if terminal not ready

### Solution 3: Use ClaudeCodeOpen Instead of Toggle

**Problem**: `ClaudeCode` command toggles. We need explicit open/close.

**Research needed**: Check if claude-code.nvim provides:
- `ClaudeCodeOpen` command (open only, no toggle)
- API function to open without toggling

**Implementation**: Replace `vim.cmd('ClaudeCode')` with explicit open command

**Pros**:
- Fixes toggle-closed scenario
- More explicit intent

**Cons**:
- Might not exist in claude-code.nvim API

### Solution 4: Hybrid Approach (RECOMMENDED)

Combine multiple mechanisms for reliability:

1. **SessionStart hook** - Fresh start (already works)
2. **Immediate flush** - Terminal ready (already works)
3. **Focus + TextChanged** - Terminal not ready (needs fix)
4. **Fallback delay** - Safety net (200ms, not 3 seconds)

**Implementation**:
```lua
-- Terminal exists but might not be ready
if M.is_terminal_ready(claude_buf) then
  -- Ready now, send immediately
  state = M.State.READY
  M.focus_terminal(claude_buf)
  M.flush_queue(claude_buf)
else
  -- Not ready - focus and rely on TextChanged
  M.focus_terminal(claude_buf)

  -- Safety fallback: check again after brief delay
  vim.defer_fn(function()
    if #pending_commands > 0 then
      -- Either send if ready, or just send anyway
      if M.is_terminal_ready(claude_buf) then
        state = M.State.READY
      end
      M.flush_queue(claude_buf)
    end
  end, 200)
end
```

**Pros**:
- Multiple mechanisms = higher reliability
- Short delay (200ms) not too bad
- Still leverages hook for best case
- Handles all scenarios

**Cons**:
- Reintroduces delay (but much shorter than before)
- Slightly more complex

## Recommendations

### Priority 1: Add "Not Ready" Handling (Critical)

Implement Solution 4 (Hybrid Approach) to handle the "terminal exists but not ready" case.

**Why**: This is the root cause of scenarios 2 and 3 failures.

### Priority 2: Fix Toggle Issue (Medium)

Research claude-code.nvim API for explicit open command, or detect window state before toggling.

**Why**: Prevents potential issues with toggle closing when we want to open.

### Priority 3: Improve State Tracking (Low)

Consider checking actual terminal state instead of relying on cached `state` variable.

**Why**: Defensive programming against state desync.

## Implementation Steps

### Phase 1: Add Not-Ready Handler

1. Open `terminal-state.lua`
2. Locate `queue_command()` function (line ~114)
3. Add else branch to handle "terminal exists but not ready"
4. Implement focus + fallback delay (200ms)
5. Test all scenarios

### Phase 2: Test Edge Cases

1. Test when Claude open and showing prompt
2. Test when Claude open but busy (no prompt)
3. Test when Claude window closed but session running
4. Test rapid command sequences

### Phase 3: Consider API Improvements

1. Research claude-code.nvim for `open()` function
2. If exists, replace `ClaudeCode` toggle with explicit open
3. Test window reopening scenarios

## Testing Plan

### Test Scenario 1: Claude Already Open and Ready
```bash
# Start Claude
:ClaudeCode
# Wait for prompt to appear
# Use picker
<leader>ac
# Select command
# Expected: Immediate insertion
```

### Test Scenario 2: Claude Already Open But Busy
```bash
# Start Claude, then make it busy
:ClaudeCode
# Type something to make prompt disappear
# Quickly use picker
<leader>ac
# Select command
# Expected: Command appears when ready (within 200ms)
```

### Test Scenario 3: Claude Toggled Closed
```bash
# Start Claude
:ClaudeCode
# Close with toggle
<C-c>  # or :ClaudeCode again
# Use picker
<leader>ac
# Select command
# Expected: Sidebar reopens, command appears
```

### Test Scenario 4: Fresh Start (Regression)
```bash
# No Claude running
<leader>ac
# Select command
# Expected: Still works via SessionStart hook
```

## Next Steps

1. **Create Plan 019**: Implement hybrid approach for "not ready" case
2. **Research**: Check claude-code.nvim API for explicit open command
3. **Test**: Verify all four scenarios after implementation

## References

### Research Reports
- [028_claude_code_hooks_for_terminal_readiness.md](../reports/028_claude_code_hooks_for_terminal_readiness.md) - Hook research

### Implementation Plans
- [018_refactor_to_hook_based_readiness_detection.md](../plans/018_refactor_to_hook_based_readiness_detection.md) - Current implementation

### Code Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua:114-142` - queue_command() needs fix
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua:222-253` - focus_terminal() toggle issue

### Claude Code Documentation
- SessionStart hook only fires on new sessions
- Need to check API for explicit open/close commands

## Conclusion

The SessionStart hook successfully handles the fresh start case but **lacks a mechanism for the "terminal exists but not ready" scenario**. The hook doesn't fire for existing sessions, and TextChanged doesn't reliably trigger without the cursor being in the buffer.

**Solution**: Add a hybrid approach with:
1. Hook for fresh start (works) ✓
2. Immediate flush if ready (works) ✓
3. Focus + TextChanged for not ready (needs implementation)
4. Fallback delay as safety net (200ms)

This combines the best of both approaches: event-driven when possible, delayed fallback when needed. The delay is short enough (200ms vs 3 seconds) to be acceptable while providing reliability.
