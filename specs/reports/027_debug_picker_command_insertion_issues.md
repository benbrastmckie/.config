# Debug Report: Picker Command Insertion Issues

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 027
- **Issue**: Three problems with <leader>ac picker command insertion
- **Severity**: High
- **Type**: Debugging investigation
- **Related Reports**:
  - 026_terminal_state_textchanged_bug_analysis.md
  - 016_fix_terminal_focus_for_textchanged_summary.md
- **Affected Files**:
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`

## Problem Statement

User reports three distinct issues when using `<leader>ac` picker to insert Claude Code commands:

### Issue 1: Command Inserted Too Early (Before Claude Code Opens)
**Scenario**: Fresh nvim session, Claude Code not started
**Expected**: Command queued until Claude opens, then inserted
**Actual**: Command inserted immediately in wrong terminal, then inserted again when Claude opens

### Issue 2: No Space After Command
**Scenario**: Any command insertion
**Expected**: Command inserted with trailing space for arguments (e.g., `/plan `)
**Actual**: Command inserted without space (e.g., `/plan`)

### Issue 3: Sidebar Not Reopening After C-c Close
**Scenario**: Claude Code running but sidebar closed with `<C-c>`
**Expected**: Sidebar reopens when command queued
**Actual**: Command inserted but sidebar stays closed

## Investigation Process

### Step 1: Code Flow Analysis

Traced execution from `<leader>ac` through:
1. `picker.lua:send_command_to_terminal()` (line 277)
2. `vim.cmd('ClaudeCode')` if terminal not found
3. `terminal_state.queue_command()` (line 114)
4. Decision tree based on terminal state

### Step 2: Issue 1 Root Cause - Race Condition

**Code Evidence** (picker.lua:296-304):
```lua
local claude_buf = terminal_state.find_claude_terminal()
if not claude_buf then
  notify.editor("Opening Claude Code...", ...)
  vim.cmd('ClaudeCode')  -- Asynchronous!
end

-- Immediately after, without waiting
terminal_state.queue_command(command_text, {...})
```

**Problem**: `vim.cmd('ClaudeCode')` is **asynchronous**. It triggers window/buffer creation but returns immediately. The very next line calls `queue_command()`, which checks `find_claude_terminal()` again.

**Race condition timeline**:
1. `find_claude_terminal()` → nil (no terminal)
2. `vim.cmd('ClaudeCode')` → starts opening process
3. `queue_command()` called immediately
4. `find_claude_terminal()` called again
5. **Sometimes finds partially-opened buffer** (if fast enough)
6. Tries to send to not-yet-ready terminal
7. Command goes to wrong place or fails

**Why it manifests**:
- Buffer creation might complete before terminal is ready
- `find_claude_terminal()` just checks for terminal buftype
- Doesn't verify terminal is actually Claude Code's UI

### Step 3: Issue 2 Root Cause - Missing Space

**Code Evidence** (picker.lua:282):
```lua
local command_text = "/" .. command.name
```

**Problem**: Commands like `/plan`, `/report`, `/implement` need a trailing space for user to type arguments. The code only adds the command name without a space.

**Why this matters**:
- `/plan` → cursor at end, user must manually add space
- `/plan ` → cursor ready for typing arguments

**Current behavior**: `/plan|` (cursor here)
**Expected behavior**: `/plan |` (cursor here, space before it)

### Step 3: Issue 3 Root Cause - No Window Reopening Logic

**Code Evidence** (terminal-state.lua:218-231 focus_terminal):
```lua
function M.focus_terminal(claude_buf)
  if not vim.api.nvim_buf_is_valid(claude_buf) then
    return
  end

  local wins = vim.fn.win_findbuf(claude_buf)
  if #wins > 0 then
    -- Window exists, focus it
    vim.api.nvim_set_current_win(wins[1])
    if vim.api.nvim_get_mode().mode == 'n' then
      vim.cmd('startinsert!')
    end
  end
  -- BUT: If #wins == 0, does nothing!
end
```

**Problem**: When Claude sidebar closed with `<C-c>`:
- Buffer still exists (hidden, not deleted)
- But no window displaying it
- `win_findbuf()` returns empty list
- `focus_terminal()` does nothing
- Command queued but never shows up

**Why `<C-c>` matters**:
- `<C-c>` likely calls `:close` or `:hide`
- Buffer remains loaded (buftype = terminal)
- `find_claude_terminal()` finds the buffer
- But there's no window to focus
- And no logic to reopen the window

## Findings

### Root Cause Analysis

#### Issue 1: Race Between Open and Queue

**Primary cause**: Synchronous assumption about asynchronous operation

`vim.cmd('ClaudeCode')` triggers async window opening, but code immediately proceeds to `queue_command()`. If buffer appears quickly (but isn't ready), we try to send too early.

**Contributing factors**:
1. No waiting for `ClaudeCode` to complete
2. `find_claude_terminal()` checks buffer existence, not readiness
3. Queue logic assumes terminal either exists+ready or doesn't exist

#### Issue 2: Hardcoded Command Format

**Primary cause**: Missing UX consideration

Commands were formatted without trailing space. This is a simple oversight - slash commands typically need arguments.

#### Issue 3: Window vs Buffer Confusion

**Primary cause**: `focus_terminal()` assumes window exists

The function only focuses existing windows. It has no fallback to **reopen** a window when buffer exists but is hidden.

**Contributing factors**:
1. `<C-c>` closes window but keeps buffer
2. `find_claude_terminal()` finds buffer (correct)
3. `focus_terminal()` fails silently when no window
4. No API call to reopen Claude Code sidebar

### Evidence

#### Issue 1 Evidence: Async Timing

```lua
-- picker.lua:296-307
local claude_buf = terminal_state.find_claude_terminal()
if not claude_buf then
  vim.cmd('ClaudeCode')  -- Returns immediately, doesn't wait
end
terminal_state.queue_command(...)  -- Runs RIGHT AWAY

-- terminal-state.lua:124
local claude_buf = M.find_claude_terminal()  -- Might now find the half-opened buffer!
```

**Test**: Add print statements, you'll see queue_command called before TermOpen fires.

#### Issue 2 Evidence: String Concatenation

```lua
-- picker.lua:282
local command_text = "/" .. command.name  -- Just name, no space
-- Result: "/plan" instead of "/plan "
```

#### Issue 3 Evidence: Window Check

```lua
-- terminal-state.lua:223-230
local wins = vim.fn.win_findbuf(claude_buf)
if #wins > 0 then
  -- Focus window
else
  -- DO NOTHING - this is the bug
end
```

**Test**: Close Claude with `:close`, then try picker. Buffer exists, no window, nothing happens.

## Proposed Solutions

### Solution 1: Fix Race Condition (Issue 1)

**Option A: Wait for TermOpen (Recommended)**

Don't queue immediately after `vim.cmd('ClaudeCode')`. Instead, rely on TermOpen autocommand to flush queue:

```lua
-- In picker.lua:send_command_to_terminal()
local claude_buf = terminal_state.find_claude_terminal()

if not claude_buf then
  notify.editor("Opening Claude Code...", ...)
  vim.cmd('ClaudeCode')
  -- DON'T queue here - wait for TermOpen
end

-- ALWAYS queue, even if we just opened
terminal_state.queue_command(command_text, {...})
```

**Why this works**:
- If terminal doesn't exist: queue, `ClaudeCode` opens, TermOpen fires, queue flushes
- If terminal exists: queue, immediate check, flush if ready
- No race condition - queue always happens after any opening completes

**Option B: Explicit Wait**

Add small delay after `ClaudeCode`:

```lua
if not claude_buf then
  vim.cmd('ClaudeCode')
  vim.defer_fn(function()
    terminal_state.queue_command(command_text, {...})
  end, 100)  -- Wait for buffer creation
else
  terminal_state.queue_command(command_text, {...})
end
```

**Problem**: Still a race, just less likely. Not recommended.

### Solution 2: Add Trailing Space (Issue 2)

**Simple fix** in picker.lua:

```lua
-- OLD
local command_text = "/" .. command.name

-- NEW
local command_text = "/" .. command.name .. " "
```

**Handles edge cases**: Commands that don't need arguments (rare) still work fine with trailing space.

### Solution 3: Reopen Window When Hidden (Issue 3)

**Option A: Enhance focus_terminal (Recommended)**

```lua
function M.focus_terminal(claude_buf)
  if not vim.api.nvim_buf_is_valid(claude_buf) then
    return
  end

  local wins = vim.fn.win_findbuf(claude_buf)

  if #wins > 0 then
    -- Window exists, focus it
    vim.api.nvim_set_current_win(wins[1])
    if vim.api.nvim_get_mode().mode == 'n' then
      vim.cmd('startinsert!')
    end
  else
    -- Window doesn't exist, reopen Claude Code sidebar
    -- This will create a new window for the existing buffer
    vim.cmd('ClaudeCode')  -- Toggle will open it

    -- Wait a moment for window to appear, then focus
    vim.defer_fn(function()
      local new_wins = vim.fn.win_findbuf(claude_buf)
      if #new_wins > 0 then
        vim.api.nvim_set_current_win(new_wins[1])
        if vim.api.nvim_get_mode().mode == 'n' then
          vim.cmd('startinsert!')
        end
      end
    end, 50)
  end
end
```

**Why this works**:
- If window open: focus it (current behavior)
- If window closed but buffer exists: reopen with `ClaudeCode`, then focus

**Option B: Use claude-code.nvim API**

If claude-code.nvim has an `open()` or `show()` function (vs toggle):

```lua
local claude_code = require("claude-code")
if claude_code.open then
  claude_code.open()  -- Explicitly open, don't toggle
else
  vim.cmd('ClaudeCode')  -- Fallback to toggle
end
```

**Need to check**: claude-code.nvim plugin API documentation

## Recommendations

### Priority 1: Fix Issue 1 (Race Condition) - Critical

Implement **Solution 1, Option A**: Remove duplicate `queue_command()` call, always queue after the if/else block. This ensures:
- No race condition
- Queue always happens
- TermOpen handles flushing for new terminals
- Existing terminals flush immediately

### Priority 2: Fix Issue 2 (No Space) - Easy Win

Add trailing space to command text in picker.lua line 282. One-line fix, big UX improvement.

### Priority 3: Fix Issue 3 (Window Reopening) - Medium

Implement **Solution 3, Option A**: Enhance `focus_terminal()` to reopen window if closed. Requires small delay but solves the problem.

## Implementation Steps

### Phase 1: Fix Race Condition

**File**: `picker.lua`

```lua
-- Around line 296-307, change to:
local claude_buf = terminal_state.find_claude_terminal()
if not claude_buf then
  notify.editor("Opening Claude Code...", ...)
  vim.cmd('ClaudeCode')
end

-- Always queue (removed from inside if block)
terminal_state.queue_command(command_text, {
  auto_focus = true,
  notification = function()
    notify.editor(...)
  end
})
```

### Phase 2: Add Trailing Space

**File**: `picker.lua`

```lua
-- Line 282, change to:
local command_text = "/" .. command.name .. " "
```

### Phase 3: Enhance focus_terminal

**File**: `terminal-state.lua`

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
  else
    -- NEW: Reopen window if it was closed
    vim.cmd('ClaudeCode')
    vim.defer_fn(function()
      local new_wins = vim.fn.win_findbuf(claude_buf)
      if #new_wins > 0 then
        vim.api.nvim_set_current_win(new_wins[1])
        if vim.api.nvim_get_mode().mode == 'n' then
          vim.cmd('startinsert!')
        end
      end
    end, 50)
  end
end
```

## Testing Plan

### Test Scenario 1: Fresh Start (Issue 1)
1. Open fresh nvim
2. Press `<leader>ac`
3. Select a command
4. **Expected**: Command appears ONLY in Claude terminal, not elsewhere
5. **Expected**: No duplicate command

### Test Scenario 2: Trailing Space (Issue 2)
1. Use `<leader>ac` to insert `/plan`
2. **Expected**: Cursor positioned AFTER space: `/plan |`
3. User can immediately type arguments

### Test Scenario 3: Reopen Window (Issue 3)
1. Start Claude Code
2. Close sidebar with `<C-c>`
3. Use `<leader>ac` to insert command
4. **Expected**: Sidebar reopens automatically
5. **Expected**: Command visible in Claude terminal

### Test Scenario 4: Already Open
1. Claude Code already running
2. Use `<leader>ac`
3. **Expected**: Command inserted immediately
4. **Expected**: No delay, no flicker

## Next Steps

1. **Implement Phase 1** (race condition fix) - highest priority
2. **Implement Phase 2** (trailing space) - quick win
3. **Test Scenarios 1 & 2** - verify first two fixes
4. **Implement Phase 3** (window reopening) - complete solution
5. **Test Scenario 3** - verify window reopening
6. **Create follow-up plan** if needed

## References

### Code Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:296-307` - Race condition location
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:282` - Missing space
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua:218-231` - focus_terminal() needs enhancement

### Related Reports
- `026_terminal_state_textchanged_bug_analysis.md` - TextChanged bug background
- `016_fix_terminal_focus_for_textchanged_summary.md` - Recent implementation

### Neovim Documentation
- `:help nvim_win_findbuf()` - Find windows for buffer
- `:help chansend()` - Send to terminal
- `:help vim.schedule()` - Deferred execution

## Appendix: Why These Bugs Weren't Caught

### Issue 1
- Async behavior of `vim.cmd('ClaudeCode')` not obvious
- Race condition timing-dependent (might work sometimes)
- Original implementation assumed synchronous operation

### Issue 2
- UX detail, not a functional bug
- Easy to miss in implementation focus
- Only annoying in practice, doesn't break functionality

### Issue 3
- Edge case: most users don't close sidebar with `<C-c>`
- Common path: open Claude, use it, don't close
- Window vs buffer distinction subtle

All three are fixable with targeted changes. No architectural issues.
