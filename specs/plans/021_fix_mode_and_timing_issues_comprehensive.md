# Fix Mode and Timing Issues - Comprehensive Solution

## Metadata
- **Date**: 2025-09-30
- **Plan Number**: 021
- **Feature**: Fix normal mode issue and timing problems for command insertion
- **Scope**: Three interconnected fixes for picker mode handling and queue timing
- **Estimated Phases**: 3
- **Complexity**: Medium
- **Standards File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Research Reports**:
  - `/home/benjamin/.config/nvim/specs/reports/032_debug_remote_expr_and_mode_issues.md`
  - `/home/benjamin/.config/nvim/specs/reports/031_debug_hook_command_appears_in_claude_terminal.md`
  - `/home/benjamin/.config/nvim/specs/reports/030_debug_hook_solution_works_only_fresh_start.md`

## Overview

After implementing the hook-based solution (Plan 018) and simplification (Plan 020), THREE issues remain:

1. **Normal mode issue**: After selecting command from `<leader>ac` picker, user ends in normal mode instead of insert mode
2. **Scenario 2 failure**: Commands don't work when Claude already open
3. **Scenario 3 failure**: Commands don't work when Claude toggled closed

Report 032 identified the root causes:
- Double `focus_terminal()` calls from `auto_focus` flag interfering with mode
- Timing issue: checking window state immediately after async `focus_terminal()` call
- Need to check window state BEFORE focusing, not after

## Success Criteria

- [x] Debug report created (032)
- [ ] Scenario 1 (fresh start): Still works, insert mode ✓
- [ ] Scenario 2 (already open): Command inserted immediately, insert mode ✓
- [ ] Scenario 3 (toggled closed): Reopens, command inserted, insert mode ✓
- [ ] Scenario 4 (resume session): No Lua command visible ✓
- [ ] User always ends in insert mode in Claude terminal
- [ ] No double focus calls
- [ ] Minimal delay for already-open case

## Technical Design

### Root Cause Analysis

**Issue 1: Double focus_terminal() Call**

Current flow:
```
picker calls queue_command(auto_focus: true)
  ↓
queue_command() calls focus_terminal()  [First call]
  ↓
queue_command() calls flush_queue()
  ↓
flush_queue() calls send_to_terminal(auto_focus: true)
  ↓
send_to_terminal() calls focus_terminal()  [Second call - CONFLICT!]
```

**Fix**: Remove `auto_focus` from picker since `queue_command()` already handles focusing.

**Issue 2: Timing - Checking Too Early**

Current code (broken):
```lua
M.focus_terminal(claude_buf)  -- Might trigger async window open

local wins = vim.fn.win_findbuf(claude_buf)  -- Checks IMMEDIATELY
if #wins > 0 then
  M.flush_queue(claude_buf)  -- Window hasn't opened yet!
```

**Fix**: Check window state BEFORE calling `focus_terminal()`, not after.

**Issue 3: Need Different Delays**

- **Window already open**: Use `vim.schedule()` (next event loop, ~0ms delay)
- **Window needs opening**: Use `vim.defer_fn()` (150ms delay for reopen)

### Solution Architecture

```lua
-- Phase 1: Check state FIRST
local wins = vim.fn.win_findbuf(claude_buf)
local needs_reopen = (#wins == 0)

-- Phase 2: Focus terminal
M.focus_terminal(claude_buf)

-- Phase 3: Smart delay based on state
if needs_reopen then
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 150)
else
  vim.schedule(function()
    M.flush_queue(claude_buf)
  end)
end
```

## Implementation Phases

### Phase 1: Remove auto_focus from Picker

**Objective**: Eliminate double `focus_terminal()` call that interferes with mode
**Complexity**: Low
**Files**: `lua/neotex/plugins/ai/claude/commands/picker.lua`

Tasks:
- [ ] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
- [ ] Locate `send_command_to_terminal()` function (line ~277)
- [ ] Find `terminal_state.queue_command()` call (line ~296)
- [ ] Remove `auto_focus = true` from options table
- [ ] Verify `ensure_open = true` remains (needed for fresh start)
- [ ] Test scenarios 1-3 to see if mode issue is resolved

**Before** (line 296):
```lua
terminal_state.queue_command(command_text, {
  ensure_open = true,
  auto_focus = true,  -- REMOVE THIS
  notification = function()
    notify.editor(
      string.format("Inserted '%s' into Claude Code", command_text),
      notify.categories.USER_ACTION,
      { command = command_text, hint = command.argument_hint or "none" }
    )
  end
})
```

**After**:
```lua
terminal_state.queue_command(command_text, {
  ensure_open = true,
  -- Removed auto_focus - queue_command() already calls focus_terminal()
  notification = function()
    notify.editor(
      string.format("Inserted '%s' into Claude Code", command_text),
      notify.categories.USER_ACTION,
      { command = command_text, hint = command.argument_hint or "none" }
    )
  end
})
```

Testing:
```bash
nvim test.lua
:ClaudeCode  # Start Claude
# Wait for ready
<leader>ac   # Use picker
# Select command

# Expected: Insert mode in Claude terminal after command inserted
```

**Why this helps**:
- `queue_command()` already calls `focus_terminal()` at line 136
- `send_to_terminal()` won't call `focus_terminal()` again
- Mode set by first `focus_terminal()` call is preserved

---

### Phase 2: Fix Timing with Check-Before-Focus

**Objective**: Check window state BEFORE focusing to determine correct delay strategy
**Complexity**: Medium
**Files**: `lua/neotex/plugins/ai/claude/utils/terminal-state.lua`

Tasks:
- [ ] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`
- [ ] Locate `queue_command()` function (line ~114)
- [ ] Find terminal exists branch (line ~135)
- [ ] Replace immediate check with check-before-focus pattern
- [ ] Use `vim.schedule()` for already-open case
- [ ] Use `vim.defer_fn(150ms)` for needs-reopen case
- [ ] Test scenarios 2 & 3

**Before** (lines 135-149, BROKEN):
```lua
-- Terminal exists - ensure visible and flush immediately
M.focus_terminal(claude_buf)

-- If window had to be reopened, wait briefly before flushing
-- Otherwise flush immediately
local wins = vim.fn.win_findbuf(claude_buf)
if #wins > 0 then
  -- Window already visible, flush now
  M.flush_queue(claude_buf)
else
  -- Window needs reopening, wait for it
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 100)
end
```

**After** (FIXED):
```lua
-- Terminal exists - check window state BEFORE focusing
local wins = vim.fn.win_findbuf(claude_buf)
local needs_reopen = (#wins == 0)

-- Focus terminal (might trigger async window open)
M.focus_terminal(claude_buf)

-- Smart delay based on pre-check state
if needs_reopen then
  -- Window was closed, needs time to reopen and settle
  vim.defer_fn(function()
    M.flush_queue(claude_buf)
  end, 150)  -- Increased from 100ms for reliability
else
  -- Window already visible, flush after current event loop completes
  -- This ensures mode changes from focus_terminal() complete
  vim.schedule(function()
    M.flush_queue(claude_buf)
  end)
end
```

**Why this works**:

1. **Check BEFORE focus**: We capture window state before `focus_terminal()` potentially changes it
2. **needs_reopen flag**: Reliable indicator of whether async operations are happening
3. **vim.schedule()**: For already-open case, waits only for event loop (imperceptible delay)
4. **150ms delay**: For reopen case, gives time for:
   - `ClaudeCode` toggle command to execute
   - Window to appear
   - `focus_terminal()` deferred focus (50ms) to complete
   - Mode to settle

Testing:
```bash
# Test Scenario 2: Claude already open
nvim test.lua
:ClaudeCode
# Wait for ready
<leader>ac
# Select /plan command
# Expected: Immediate insertion (schedule delay ~0ms), insert mode

# Test Scenario 3: Claude toggled closed
:ClaudeCode  # Close it
<leader>ac
# Select /report command
# Expected: Reopens (150ms delay), command inserted, insert mode
```

**Lines changed**: ~7 lines modified, net +2 lines

---

### Phase 3: Test All Scenarios Comprehensively

**Objective**: Verify all four test scenarios work correctly
**Complexity**: Low

Tasks:
- [ ] Test scenario 1: Fresh start (should still work via hook)
- [ ] Test scenario 2: Claude already open (should work immediately)
- [ ] Test scenario 3: Claude toggled closed (should reopen and work)
- [ ] Test scenario 4: Resume session (check if `^N` still appears)
- [ ] Verify insert mode for ALL scenarios
- [ ] Test rapid command sequences
- [ ] Test edge case: Multiple windows with same buffer

**Scenario 1: Fresh Start** (regression test)
```bash
nvim test.lua
# Claude not running
<leader>ac
# Select /implement command

# Expected:
# - Claude opens (ClaudeCode called)
# - SessionStart hook fires
# - on_claude_ready() flushes queue
# - Command appears: /implement
# - User in insert mode in Claude terminal
```

**Scenario 2: Already Open**
```bash
nvim test.lua
:ClaudeCode
# Wait for > prompt
<leader>ac
# Select /plan command

# Expected:
# - needs_reopen = false (window exists)
# - focus_terminal() focuses existing window
# - vim.schedule() executes immediately
# - Command appears: /plan
# - User in insert mode in Claude terminal
```

**Scenario 3: Toggled Closed**
```bash
nvim test.lua
:ClaudeCode
# Wait for ready
:ClaudeCode  # Toggle close
<leader>ac
# Select /test command

# Expected:
# - needs_reopen = true (no window)
# - focus_terminal() calls ClaudeCode to toggle open
# - vim.defer_fn(150ms) waits for window
# - Command appears: /test
# - User in insert mode in Claude terminal
```

**Scenario 4: Resume Session**
```bash
# Start nvim
nvim
# Hit Ctrl-c to resume Claude session
<C-c>

# Expected:
# - SessionStart hook fires
# - No ^N or Lua command visible in terminal
# - Clean Claude startup

# Then test command insertion
<leader>ac
# Select /debug command
# Expected: Works, insert mode
```

**Rapid Commands Test**:
```bash
:ClaudeCode
<leader>ac  # /plan
<Esc>
<leader>ac  # /test
<Esc>
<leader>ac  # /report

# Expected:
# - All three queued
# - All three inserted in order
# - No duplicates
# - User in insert mode after last one
```

**Edge Case: Multiple Windows**:
```bash
:ClaudeCode
:vsplit
# Move to other split
<leader>ac
# Select command

# Expected:
# - Focuses first Claude window (win_findbuf returns first)
# - Command inserted there
# - Insert mode in that window
```

---

## Testing Strategy

### Unit-Level Verification

After each phase, verify:
1. Code compiles (no Lua syntax errors)
2. Functions are called correctly
3. No nil reference errors

### Integration Testing

Test the complete flow:
```
picker → queue_command → focus_terminal → flush_queue → send_to_terminal
```

### Scenario Coverage

| Scenario | Before (Broken) | After Phase 1 | After Phase 2 | Expected |
|----------|----------------|---------------|---------------|----------|
| 1. Fresh start | ✓ Works | ✓ Works | ✓ Works | ✓ Works |
| 2. Already open | ✗ Fails | ? Maybe | ✓ Works | ✓ Works |
| 3. Toggled closed | ✗ Fails | ? Maybe | ✓ Works | ✓ Works |
| 4. Resume session | ✗ Shows `^N` | ✓ Fixed | ✓ Fixed | ✓ Works |
| Insert mode | ✗ Normal | ✓ Insert | ✓ Insert | ✓ Insert |

### Regression Testing

Ensure existing functionality still works:
- [ ] `<leader>ac` picker opens correctly
- [ ] Command preview works
- [ ] Ctrl-n (new command) works
- [ ] Ctrl-l (load local) works
- [ ] All picker keyboard shortcuts work

## Edge Cases and Considerations

### Edge Case 1: Buffer Invalid After Check

**Scenario**: Buffer becomes invalid between check and focus

```lua
local wins = vim.fn.win_findbuf(claude_buf)  -- Valid
-- <-- Buffer deleted here somehow
M.focus_terminal(claude_buf)  -- Invalid buffer!
```

**Mitigation**: `focus_terminal()` already checks `nvim_buf_is_valid()` at line 232

### Edge Case 2: Window Appears During Check

**Scenario**: Window opens between check and focus (rare)

```lua
local wins = vim.fn.win_findbuf(claude_buf)  -- Empty
-- <-- Window opens here (user manually?)
local needs_reopen = (#wins == 0)  -- True
M.focus_terminal(claude_buf)  -- Window already exists!
```

**Impact**: Would use 150ms delay instead of schedule, but command still works (just slower)

**Acceptable**: Extremely unlikely race condition, no functional impact

### Edge Case 3: focus_terminal() Called from Elsewhere

**Scenario**: Another code path calls `focus_terminal()` during our delay

**Impact**: Multiple focus calls might compete

**Mitigation**: `focus_terminal()` is idempotent - safe to call multiple times

### Edge Case 4: Queue Has Multiple Commands

**Scenario**: User queues multiple commands rapidly

```lua
queue_command("/plan test")
queue_command("/test all")
queue_command("/report findings")
```

**Expected behavior**:
- All three queued
- Single `flush_queue()` sends all three
- Works correctly ✓

**Verified**: `flush_queue()` has while loop (line 148) that processes all pending

## Documentation Requirements

### Code Comments

Update function docstrings:

**queue_command()**:
```lua
--- Queue command to be sent when terminal is ready
--- Handles three cases:
--- 1. No terminal: Opens Claude, SessionStart hook flushes queue
--- 2. Terminal + window visible: Immediate flush via vim.schedule()
--- 3. Terminal + window hidden: Delayed flush (150ms) for reopen
--- @param command_text string Command to send
--- @param opts table Options: ensure_open, notification
```

**focus_terminal()**:
```lua
--- Focus Claude terminal window and enter insert mode
--- If window exists: Focus immediately and enter insert mode
--- If window hidden: Toggle ClaudeCode, schedule focus after 50ms
--- @param claude_buf number Terminal buffer handle
```

### No User Documentation Needed

These are internal bug fixes, not new features. Users don't need to know about timing changes.

## Rollback Plan

If Phase 2 doesn't work:
1. Revert commits
2. Go back to Plan 020 state
3. Consider Report 030's delay-based fallback approach
4. Or accept that scenarios 2 & 3 need manual workaround

If Phase 1 breaks things:
1. Revert just the picker.lua change
2. Keep `auto_focus = true`
3. Investigate alternative mode-setting approach

## Dependencies

### Internal Dependencies

- `focus_terminal()` - Must enter insert mode correctly
- `flush_queue()` - Must process all pending commands
- `send_to_terminal()` - Must not call focus_terminal if auto_focus removed
- SessionStart hook - Must still work for fresh start

### No External Dependencies

All changes are self-contained in existing modules.

## Notes

### Why This is Better Than Previous Attempts

**Plan 015-017** (failed attempts):
- Used complex polling and timers
- Arbitrary delays everywhere
- Didn't understand the root cause

**Plan 018** (hook-based):
- ✓ Works great for fresh start
- ✗ Doesn't handle existing terminal
- Removed too much (polling)

**Plan 020** (simplification):
- ✓ Right idea (just flush)
- ✗ Timing wrong (check after focus)
- ✗ Didn't address mode issue

**This Plan** (comprehensive fix):
- ✓ Addresses all three root causes
- ✓ Minimal delays (schedule when possible)
- ✓ Check before focus (correct timing)
- ✓ Remove auto_focus (mode fix)
- ✓ Based on detailed root cause analysis

### Why vim.schedule() is Better Than Immediate

Even when window is already visible, we should wait for the event loop:

**Reason**: `focus_terminal()` calls `vim.cmd('startinsert!')` which might not complete synchronously

**Solution**: `vim.schedule()` ensures mode change completes before flush

**Performance**: Schedule delay is imperceptible (next event loop iteration, <1ms)

### Why 150ms Instead of 100ms

The previous 100ms delay wasn't enough because:
1. `ClaudeCode` toggle command needs time to execute
2. Window creation takes time
3. `focus_terminal()` has internal 50ms delay for deferred focus
4. Mode settling needs time

150ms provides buffer:
- 0-20ms: ClaudeCode toggle executes
- 20-70ms: Window appears
- 50-100ms: focus_terminal deferred focus completes
- 100-150ms: Mode settles, buffer for slower systems

### User Expectation Alignment

User said: "I don't think delays are needed"

**Our response**:
- ✓ No delay for already-open case (vim.schedule is imperceptible)
- ✓ Minimal delay only when window needs reopening (unavoidable)
- ✓ Smart detection of when delay is actually needed

This aligns with user's intuition while handling the technical reality.

## Success Metrics

- [x] Plan created with clear phases
- [ ] Phase 1 implemented (remove auto_focus)
- [ ] Phase 2 implemented (check-before-focus)
- [ ] Phase 3 completed (all scenarios tested)
- [ ] All four test scenarios pass
- [ ] User always in insert mode after command insertion
- [ ] No more `^N` in terminal on resume

## References

### Debug Reports
- [032_debug_remote_expr_and_mode_issues.md](../reports/032_debug_remote_expr_and_mode_issues.md) - Root cause analysis
- [031_debug_hook_command_appears_in_claude_terminal.md](../reports/031_debug_hook_command_appears_in_claude_terminal.md) - Hook command issue
- [030_debug_hook_solution_works_only_fresh_start.md](../reports/030_debug_hook_solution_works_only_fresh_start.md) - Scenario failures

### Previous Plans
- [020_fix_command_insertion_for_existing_claude.md](./020_fix_command_insertion_for_existing_claude.md) - Simplification attempt
- [018_refactor_to_hook_based_readiness_detection.md](./018_refactor_to_hook_based_readiness_detection.md) - Hook implementation

### Code Files to Modify
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:296` - Remove auto_focus
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua:135-149` - Check-before-focus timing

### Neovim Documentation
- `:help vim.schedule()` - Event loop scheduling
- `:help vim.defer_fn()` - Deferred function execution
- `:help vim.fn.win_findbuf()` - Find windows by buffer

## Conclusion

This plan addresses all three root causes identified in Report 032:

1. **Remove auto_focus**: Eliminates double `focus_terminal()` call → fixes mode issue
2. **Check-before-focus**: Correct timing detection → fixes scenarios 2 & 3
3. **Smart delays**: Schedule for immediate, defer for reopen → optimal performance

The solution is elegant: check state first, focus second, delay appropriately. This aligns with user's expectation of "no unnecessary delays" while handling the technical requirements of async window operations.

**Expected result**: All four scenarios work, user always in insert mode, minimal delays.
