# Debug Report: --remote-expr Hook and Normal Mode Issues

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 032
- **Issue**: Multiple issues after implementing --remote-expr fix
- **Severity**: High
- **Type**: Debugging investigation
- **Related Reports**:
  - 031_debug_hook_command_appears_in_claude_terminal.md
  - 030_debug_hook_solution_works_only_fresh_start.md
- **Related Plans**:
  - 020_fix_command_insertion_for_existing_claude.md
- **Affected Files**:
  - `/home/benjamin/.config/nvim/scripts/claude-ready-signal.sh`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`

## Problem Statement

After implementing the `--remote-expr` fix (commit 5526ee6) to prevent Lua commands from appearing as text in Claude's terminal, THREE issues remain:

1. **Commands still not working when Claude already open** (scenario 2 from testing)
2. **Commands still not working when Claude toggled closed** (scenario 3 from testing)
3. **NEW ISSUE**: Picker leaves user in normal mode instead of insert mode after inserting command

### User Report

> "when I make a selection from the <leader>ac picker, it opens claude code, inserts the command, but leaves me in normal mode"
>
> "Also the other issues were not fixed either"

This means scenarios 2 and 3 are still failing after the `--remote-expr` fix.

## Investigation Process

### Step 1: Understand the Code Flow

**Picker Command Flow** (`picker.lua:811`):
```
send_command_to_terminal(command)
  ↓
terminal_state.queue_command(command_text, {
  ensure_open: true,
  auto_focus: true,
  notification: function()
})
  ↓
queue_command() implementation (terminal-state.lua:114-150)
```

**queue_command() Current Implementation**:
```lua
-- Line 124-133: Handle no terminal case
if not claude_buf then
  if opts.ensure_open then
    vim.cmd('ClaudeCode')  -- Opens Claude
  end
  return  -- Queue will be flushed by SessionStart hook
end

-- Line 135-149: Handle terminal exists case
M.focus_terminal(claude_buf)

local wins = vim.fn.win_findbuf(claude_buf)
if #wins > 0 then
  -- Window already visible
  M.flush_queue(claude_buf)
else
  -- Window needs reopening, wait for it
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 100)
end
```

### Step 2: Trace Mode Handling

**focus_terminal() Mode Logic** (terminal-state.lua:231-261):
```lua
local wins = vim.fn.win_findbuf(claude_buf)
if #wins > 0 then
  vim.api.nvim_set_current_win(wins[1])
  if vim.api.nvim_get_mode().mode == 'n' then
    vim.cmd('startinsert!')  -- Enter insert mode
  end
elseif state ~= M.State.OPENING then
  vim.cmd('ClaudeCode')  -- Toggle to reopen
  vim.defer_fn(function()
    local new_wins = vim.fn.win_findbuf(claude_buf)
    if #new_wins > 0 then
      vim.api.nvim_set_current_win(new_wins[1])
      if vim.api.nvim_get_mode().mode == 'n' then
        vim.cmd('startinsert!')  -- Enter insert mode after delay
      end
    end
  end, 50)
end
```

**send_to_terminal() Mode Logic** (terminal-state.lua:208-223):
```lua
vim.fn.chansend(job_id, command_text)

if opts.auto_focus then
  M.focus_terminal(claude_buf)  -- Called AFTER sending
end
```

### Step 3: Identify the Problems

## Findings

### Root Cause 1: --remote-expr Doesn't Preserve Context

**Problem**: `nvim --remote-expr 'luaeval(...)'` executes the Lua code but returns control to the original context.

**Evidence**:
```bash
nvim --server "$NVIM" --remote-expr \
  'luaeval("require(\"neotex.plugins.ai.claude.utils.terminal-state\").on_claude_ready()")' \
  >/dev/null 2>&1
```

**What happens**:
1. Hook script calls `--remote-expr`
2. `luaeval()` executes `on_claude_ready()`
3. `on_claude_ready()` calls `focus_terminal()` which does `vim.cmd('startinsert!')`
4. Control returns to `--remote-expr` which completes
5. **But then** control might return to wherever the user was before, potentially back to normal mode

**Why normal mode**:
- The `--remote-expr` evaluation completes
- Neovim returns focus to the original window/mode context
- Any mode changes made during the eval might get overridden

### Root Cause 2: Conditional Delay Logic is Flawed

**Problem Location**: `queue_command()` lines 140-149

```lua
local wins = vim.fn.win_findbuf(claude_buf)
if #wins > 0 then
  M.flush_queue(claude_buf)
else
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 100)
end
```

**Why this doesn't work for scenarios 2 & 3**:

**Scenario 2: Claude already open**
- `claude_buf` exists
- BUT `focus_terminal()` was just called (line 136)
- If `focus_terminal()` triggered a window reopen, `win_findbuf()` on line 140 might not see it yet
- The check happens IMMEDIATELY after `focus_terminal()` call
- Timing issue: window hasn't opened yet when we check

**Scenario 3: Claude toggled closed**
- `claude_buf` exists (buffer still valid)
- Window doesn't exist
- `focus_terminal()` calls `ClaudeCode` to toggle (line 247)
- Then immediately check `win_findbuf()` (line 140)
- Window hasn't appeared yet → takes else branch → 100ms delay
- But 100ms might not be enough if Claude is starting up

### Root Cause 3: focus_terminal() Has Its Own Delay

**Problem**: `focus_terminal()` already has a delay for the reopen case (50ms at line 250).

**Timing cascade**:
```
queue_command() calls focus_terminal()  @ T+0ms
  ↓
focus_terminal() calls ClaudeCode      @ T+0ms
  ↓
focus_terminal() schedules focus       @ T+50ms (its internal delay)
  ↓
queue_command() schedules flush        @ T+100ms (our delay)
  ↓
flush happens                          @ T+100ms
```

**But**: The focus at T+50ms might enter insert mode, then flush at T+100ms might somehow lose it.

### Root Cause 4: Double focus_terminal() Calls

**Problem**: Multiple code paths call `focus_terminal()`, potentially conflicting.

**Call chain**:
1. `queue_command()` calls `focus_terminal()` (line 136)
2. `queue_command()` calls `flush_queue()` (lines 143 or 147)
3. `flush_queue()` calls `send_to_terminal()` (line 153)
4. `send_to_terminal()` calls `focus_terminal()` again if `auto_focus` set (line 222)

**Result**: Two calls to `focus_terminal()`:
- First call: from `queue_command()` - sets up focus and mode
- Second call: from `send_to_terminal()` with `auto_focus: true` - might re-check mode and overwrite

### Root Cause 5: SessionStart Hook Timing

**Problem**: When does the SessionStart hook actually fire?

**For fresh start** (scenario 1 - WORKS):
```
<leader>ac pressed
  ↓
queue_command() called
  ↓
no claude_buf → calls ClaudeCode
  ↓
returns (command stays queued)
  ↓
TermOpen event fires
  ↓
Claude starts up
  ↓
SessionStart hook fires
  ↓
on_claude_ready() called
  ↓
flush_queue() sends command ✓
```

**For Claude already open** (scenario 2 - FAILS):
```
<leader>ac pressed
  ↓
queue_command() called
  ↓
claude_buf exists → calls focus_terminal()
  ↓
window exists → sets current window, enters insert mode
  ↓
checks win_findbuf → finds window
  ↓
calls flush_queue() immediately
  ↓
flush_queue() calls send_to_terminal()
  ↓
send_to_terminal() calls focus_terminal() AGAIN with auto_focus
  ↓
focus_terminal() checks mode, might re-enter insert or stay normal
  ↓
Command sent BUT mode might be wrong ✗
```

The hook DOESN'T fire for scenario 2 because Claude is already started - no new session.

**For Claude toggled closed** (scenario 3 - FAILS):
```
<leader>ac pressed
  ↓
queue_command() called
  ↓
claude_buf exists → calls focus_terminal()
  ↓
no window → calls ClaudeCode (toggle)
  ↓
ClaudeCode toggles window open
  ↓
focus_terminal() schedules focus in 50ms
  ↓
queue_command() checks win_findbuf() IMMEDIATELY
  ↓
no windows found yet (toggle hasn't completed)
  ↓
schedules flush_queue() in 100ms
  ↓
At T+50ms: focus_terminal() deferred focus executes, enters insert mode
  ↓
At T+100ms: flush_queue() executes
  ↓
flush calls send_to_terminal() with auto_focus
  ↓
send_to_terminal() calls focus_terminal() AGAIN
  ↓
focus_terminal() might mess up the mode ✗
```

The hook DOESN'T fire because this isn't a new session, just reopening the window.

## Evidence

### Test Results

From user:
1. ✅ **Scenario 1 (fresh start)**: Works
2. ✗ **Scenario 2 (already open)**: Doesn't work
3. ✗ **Scenario 3 (toggled closed)**: Doesn't work
4. ✗ **Scenario 4 (resume)**: Now shows `^N:lua require(...)` instead of the full command

### Code Analysis: The Conditional Check is Wrong

```lua
-- Line 140-149: This check is IMMEDIATELY after focus_terminal()
local wins = vim.fn.win_findbuf(claude_buf)
if #wins > 0 then
  M.flush_queue(claude_buf)
else
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 100)
end
```

**Problem**: This checks for windows IMMEDIATELY after calling `focus_terminal()`, but `focus_terminal()` might have just triggered an async window open (via `ClaudeCode` toggle or deferred focus).

### Code Analysis: auto_focus Creates Double Call

```lua
-- picker.lua:296
terminal_state.queue_command(command_text, {
  ensure_open = true,
  auto_focus = true,  -- This causes send_to_terminal() to call focus_terminal() again
  notification = function() ... end
})
```

**Problem**: The `auto_focus` flag causes `send_to_terminal()` to call `focus_terminal()` AFTER the command is sent, which might interfere with the mode set by the earlier `focus_terminal()` call from `queue_command()`.

## Proposed Solutions

### Solution 1: Remove auto_focus from Picker (SIMPLE)

**Change**: Don't pass `auto_focus` in picker, since `queue_command()` already handles focusing.

```lua
-- picker.lua:296
terminal_state.queue_command(command_text, {
  ensure_open = true,
  -- REMOVE: auto_focus = true
  notification = function() ... end
})
```

**Pros**:
- Simple one-line change
- Eliminates double `focus_terminal()` call
- `queue_command()` already calls `focus_terminal()` at line 136

**Cons**:
- Doesn't fix the fundamental timing issues in scenarios 2 & 3

### Solution 2: Always Use Delay After focus_terminal()

**Change**: Always wait after calling `focus_terminal()` before flushing.

```lua
-- terminal-state.lua:135-149
M.focus_terminal(claude_buf)

-- Always wait to ensure window is focused and mode is set
vim.defer_fn(function()
  M.flush_queue(claude_buf)
end, 150)  -- Longer delay to ensure everything settles
```

**Pros**:
- Simpler logic (no conditional)
- Gives time for both window opening and mode setting

**Cons**:
- Reintroduces unconditional delay
- User wanted to avoid delays

### Solution 3: Check if Window Needs Opening BEFORE focus_terminal()

**Change**: Decide on delay based on window state BEFORE calling `focus_terminal()`.

```lua
-- terminal-state.lua:135-149
local wins = vim.fn.win_findbuf(claude_buf)
local needs_reopen = (#wins == 0)

M.focus_terminal(claude_buf)

if needs_reopen then
  -- Window was closed, wait for it to open
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 150)  -- Need longer delay for reopen
else
  -- Window was already open, flush immediately
  M.flush_queue(claude_buf)
end
```

**Pros**:
- Checks window state BEFORE focusing
- Only delays when actually needed
- Immediate flush when window already visible

**Cons**:
- Still has delay for reopen case

### Solution 4: Use vim.schedule() for Mode Setting

**Change**: Wrap the flush in `vim.schedule()` to ensure it happens after all mode changes settle.

```lua
-- terminal-state.lua:135-149
M.focus_terminal(claude_buf)

vim.schedule(function()
  M.flush_queue(claude_buf)
end)
```

**Pros**:
- No arbitrary delays
- Waits for Neovim event loop to settle
- Ensures mode changes complete

**Cons**:
- Might still be too fast if window needs reopening

### Solution 5: Hybrid - schedule + conditional delay (RECOMMENDED)

**Change**: Use `vim.schedule()` for immediate case, delay for reopen case.

```lua
-- terminal-state.lua:135-149
local wins = vim.fn.win_findbuf(claude_buf)
local needs_reopen = (#wins == 0)

M.focus_terminal(claude_buf)

if needs_reopen then
  -- Window needs reopening, wait longer
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 150)
else
  -- Window already visible, schedule after current event loop
  vim.schedule(function()
    M.flush_queue(claude_buf)
  end)
end
```

**Pros**:
- Minimal delay for already-open case (just next event loop)
- Appropriate delay for reopen case
- Combines best of both approaches

**Cons**:
- More complex than Solution 1

### Solution 6: Fix --remote-expr to Use Actual Key Codes

**For the `^N` issue in scenario 4**: The `--remote-expr` with `luaeval()` might not be working correctly.

**Alternative approach**: Use `nvim_exec_lua` through RPC or actual control characters.

```bash
# Option A: Use actual Ctrl-N character (might not work)
printf '\x0e'  # Ctrl-N in ASCII

# Option B: Use nvim_exec_lua via --remote-expr
nvim --server "$NVIM" --remote-expr \
  "nvim_exec_lua(\"require('neotex.plugins.ai.claude.utils.terminal-state').on_claude_ready()\", [])"
```

**Or**: Just accept that the hook works for fresh start and rely on the improved queue_command() logic for other cases.

## Recommendations

### Priority 1: Remove auto_focus from Picker

Simplest fix - eliminates double `focus_terminal()` call that might be causing mode issues.

**File**: `picker.lua:296`
**Change**: Remove `auto_focus = true` from `queue_command()` options

### Priority 2: Implement Solution 5 (Hybrid approach)

Fix timing issues for scenarios 2 & 3.

**File**: `terminal-state.lua:135-149`
**Change**: Check window state before focusing, use schedule for immediate case, delay for reopen

### Priority 3: Investigate --remote-expr Alternative

The `^N` in scenario 4 suggests `--remote-expr` isn't working as expected.

**File**: `claude-ready-signal.sh`
**Options**:
- Try `nvim_exec_lua` instead of `luaeval`
- Consider background process that doesn't use --remote at all
- Accept that hook only works for fresh start

## Implementation Steps

### Phase 1: Fix Picker auto_focus

1. Open `picker.lua`
2. Line 296: Remove `auto_focus = true`
3. Test scenarios 2 & 3

### Phase 2: Implement Hybrid Timing

1. Open `terminal-state.lua`
2. Lines 135-149: Implement Solution 5
3. Test all scenarios

### Phase 3: Address Hook Script

1. Research nvim_exec_lua vs luaeval
2. Test alternative approaches
3. Update `claude-ready-signal.sh` if better solution found

## Testing Plan

After implementing fixes, test:

1. **Fresh start**: No Claude → `<leader>ac` → command inserted, insert mode
2. **Already open**: Claude visible → `<leader>ac` → command inserted immediately, insert mode
3. **Toggled closed**: Claude hidden → `<leader>ac` → reopens, command inserted, insert mode
4. **Resume session**: Restart nvim, hit `<C-c>` → no Lua command visible
5. **Mode check**: For all scenarios, verify user ends in insert mode in Claude terminal

## Next Steps

1. **Implement Priority 1**: Remove auto_focus from picker
2. **Test**: Check if mode issue is resolved
3. **Implement Priority 2**: Hybrid timing approach
4. **Test**: Check if scenarios 2 & 3 work
5. **Address Priority 3** if needed: Fix hook script for resume case

## References

### Related Reports
- [031_debug_hook_command_appears_in_claude_terminal.md](./031_debug_hook_command_appears_in_claude_terminal.md)
- [030_debug_hook_solution_works_only_fresh_start.md](./030_debug_hook_solution_works_only_fresh_start.md)

### Code Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:296` - auto_focus flag
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua:135-149` - queue_command() timing
- `/home/benjamin/.config/nvim/scripts/claude-ready-signal.sh` - Hook script

### Neovim Documentation
- `:help vim.schedule()` - Event loop scheduling
- `:help --remote-expr` - Expression evaluation
- `:help luaeval()` - Lua evaluation in Vimscript
- `:help nvim_exec_lua()` - Direct Lua execution

## Conclusion

Three interconnected issues:

1. **Double focus_terminal() calls**: Caused by `auto_focus` flag in picker → FIX: Remove the flag
2. **Timing issues in scenarios 2 & 3**: Caused by checking window state too early → FIX: Check BEFORE focus, use schedule/delay appropriately
3. **Hook script showing `^N`**: Caused by `--remote-expr` not working as expected → INVESTIGATE: Alternative approaches

The fixes should be applied in order (Priority 1, then 2, then 3) with testing after each step.
