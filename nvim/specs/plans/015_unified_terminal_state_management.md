# Unified Terminal State Management Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases successfully implemented. See [Implementation Summary](../summaries/015_unified_terminal_state_management_summary.md) for details.

## Metadata
- **Date**: 2025-09-30
- **Plan Number**: 015
- **Feature**: Unified terminal state management with event-driven readiness detection
- **Scope**: Replace timer-based terminal synchronization with autocommand-driven pattern matching
- **Estimated Phases**: 4
- **Complexity**: Medium-High
- **Standards File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Research Reports**:
  - `/home/benjamin/.config/nvim/specs/reports/025_claude_code_terminal_timing_synchronization.md`

## Overview

This plan implements the recommended solution from report 025: extract terminal state management from `visual.lua` into a shared module that uses TermOpen autocommands with pattern-based readiness detection instead of timer polling. This eliminates the race condition where `<leader>ac` command selection prints to the terminal before Claude Code is ready.

### Key Changes
1. **New shared module**: `terminal-state.lua` with centralized state management
2. **Event-driven detection**: Use TermOpen + TextChanged autocommands instead of timers
3. **Command queueing**: Automatic queue flush when terminal becomes ready
4. **Standardize on chansend()**: Replace all feedkeys() usage with reliable chansend()
5. **Remove timer-based polling**: Rely solely on autocommand events

## Success Criteria
- [x] Terminal state management extracted to shared module
- [x] Both `visual.lua` and `picker.lua` use unified state module
- [x] No timer-based polling (only event-driven detection)
- [x] Commands sent via autocommand callbacks, not deferred timers
- [x] Race condition eliminated (commands never appear in wrong terminal)
- [x] All existing functionality preserved (visual selection, command picker)
- [x] Terminal state lifecycle properly tracked (CLOSED -> OPENING -> READY -> BUSY)

## Technical Design

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           terminal-state.lua (Shared Module)                │
│  - State tracking (CLOSED, OPENING, READY, BUSY)            │
│  - Command queue management                                 │
│  - Pattern-based readiness detection                        │
│  - TermOpen/TermClose autocommand setup                     │
└────────────────────┬────────────────────────────────────────┘
                     │
      ┌──────────────┴──────────────┐
      │                             │
      v                             v
┌─────────────┐              ┌──────────────┐
│ visual.lua  │              │ picker.lua   │
│ - Uses      │              │ - Uses       │
│   queue_cmd │              │   queue_cmd  │
│ - Removed   │              │ - Removed    │
│   timers    │              │   timers     │
└─────────────┘              └──────────────┘
```

### Event Flow (No Timers)

```
User Action (visual selection or command picker)
  |
  v
queue_command(text) → adds to pending_commands queue
  |
  v
Is terminal already READY?
  |
  ├─ YES → flush_queue() immediately via chansend()
  |
  └─ NO → Wait for TermOpen autocommand
            |
            v
          TermOpen fires
            |
            v
          Set state = OPENING
            |
            v
          Create TextChanged autocommand
            |
            v
          TextChanged fires on each buffer update
            |
            v
          Pattern check: is_terminal_ready()?
            |
            ├─ NO → Continue monitoring
            |
            └─ YES → Set state = READY
                      |
                      v
                    flush_queue() automatically
                      |
                      v
                    Remove TextChanged autocommand
```

### State Transitions

```
CLOSED
  |
  | (vim.cmd('ClaudeCode') called)
  v
OPENING
  |
  | (TermOpen autocommand fires)
  v
OPENING (TextChanged monitoring active)
  |
  | (Pattern detected: "^>" or "Welcome to Claude Code")
  v
READY
  |
  | (Command sent, still processing)
  v
BUSY (optional, for future use)
  |
  | (Ready for next command)
  v
READY

(TermClose fires at any time)
  |
  v
CLOSED
```

### Readiness Detection Patterns

Priority order (check in sequence):
1. `^>` - Main prompt (highest reliability)
2. `Welcome to Claude Code!` - Initial welcome complete
3. `────────` - Separator line
4. `? for shortcuts` - Help footer
5. `Try.*────.*?.*shortcuts` - Combined multi-line pattern

## Implementation Phases

### Phase 1: Create Shared Terminal State Module [COMPLETED]
**Objective**: Extract and centralize terminal state management without timers
**Complexity**: Medium

Tasks:
- [x] Create `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`
- [x] Implement state enum (CLOSED, OPENING, READY, BUSY)
- [x] Implement `find_claude_terminal()` to locate Claude buffer
- [x] Implement `is_terminal_ready(buf)` with pattern matching (no timers)
- [x] Implement `queue_command(text, opts)` for command queuing
- [x] Implement `flush_queue(buf)` to send all pending commands via chansend()
- [x] Implement `send_to_terminal(buf, text, opts)` as chansend() wrapper
- [x] Implement `focus_terminal(buf)` for window management
- [x] Add state getters: `get_state()`, `is_ready()`

Testing:
```bash
# Manual test in Neovim
:lua local ts = require('neotex.plugins.ai.claude.utils.terminal-state')
:lua print(vim.inspect(ts.State))
:lua print(ts.find_claude_terminal())
```

**Expected**: Module loads without errors, state enum available

---

### Phase 2: Implement Event-Driven Autocommand Setup [COMPLETED]
**Objective**: Setup TermOpen/TermClose autocommands without timer polling
**Complexity**: Medium-High

Tasks:
- [x] Implement `setup()` function in terminal-state.lua
- [x] Create TermOpen autocommand with pattern `*claude*`
- [x] In TermOpen callback: set state = OPENING
- [x] Create per-buffer TextChanged autocommand for readiness detection
- [x] In TextChanged callback: check `is_terminal_ready(buf)`
- [x] When ready detected: set state = READY, call `flush_queue(buf)`
- [x] When ready detected: delete TextChanged autocommand (use augroup cleanup)
- [x] Create TermClose autocommand to reset state and clear queue
- [x] Add augroup naming: `ClaudeReadyCheck_{buf_id}` for cleanup

Implementation detail for TextChanged autocommand:
```lua
-- In setup() -> TermOpen callback
local ready_check_group = vim.api.nvim_create_augroup(
  "ClaudeReadyCheck_" .. args.buf,
  { clear = true }
)

vim.api.nvim_create_autocmd("TextChanged", {
  group = ready_check_group,
  buffer = args.buf,
  callback = function()
    if M.is_terminal_ready(args.buf) then
      state = M.State.READY
      M.flush_queue(args.buf)
      -- Clean up this autocommand
      vim.api.nvim_del_augroup_by_id(ready_check_group)
    end
  end
})
```

Testing:
```bash
# Open Neovim and check autocommands
:lua require('neotex.plugins.ai.claude.utils.terminal-state').setup()
:au TermOpen
:au TermClose
# Should show new autocommands for *claude* pattern
```

**Expected**: Autocommands registered, no errors

---

### Phase 3: Refactor visual.lua to Use Shared Module [COMPLETED]
**Objective**: Remove timer-based logic from visual.lua, use event-driven state module
**Complexity**: Medium

Tasks:
- [x] Add `local terminal_state = require('neotex.plugins.ai.claude.utils.terminal-state')` to visual.lua
- [x] Remove local `ClaudeTerminalState` enum (use `terminal_state.State`)
- [x] Remove local `terminal_state` variable (use `terminal_state.get_state()`)
- [x] Remove local `pending_message` variable (use `terminal_state.queue_command()`)
- [x] Remove `wait_for_ready()` function (replaced by autocommands in shared module)
- [x] Update `ensure_claude_open()` to check `terminal_state.find_claude_terminal()`
- [x] Update `send_to_claude(text, prompt)` to use `terminal_state.queue_command()`
- [x] Remove timer creation (`vim.loop.new_timer()`) - no longer needed
- [x] Remove `setup_terminal_monitor()` function (handled by shared module)
- [x] Update `setup()` to call `terminal_state.setup()` instead
- [x] Remove TermOpen/TermClose autocommands from visual.lua (duplicated in shared module)
- [x] Update `submit_message()` to use `terminal_state.send_to_terminal()`

Key changes:
```lua
-- OLD (timer-based):
function M.send_to_claude(text, prompt)
  pending_message = { text = text, prompt = prompt, timestamp = os.time() }
  local claude_buf, was_open = M.ensure_claude_open()

  if was_open and claude_buf then
    return M.submit_message(claude_buf, text, prompt)
  else
    M.wait_for_ready(function(buf)  -- TIMER POLLING
      if buf then
        M.submit_message(buf, text, prompt)
      end
    end)
    return true
  end
end

-- NEW (event-driven):
function M.send_to_claude(text, prompt)
  local message = M.format_message(text, prompt)

  local claude_buf = terminal_state.find_claude_terminal()
  if not claude_buf then
    vim.cmd('ClaudeCode')  -- Opens terminal, triggers TermOpen
  end

  -- Queue command - will auto-send when ready via autocommand
  terminal_state.queue_command(message, {
    auto_focus = M.config.auto_focus,
    notification = function()
      if M.config.show_progress then
        vim.notify("Selection sent to Claude", vim.log.levels.INFO)
      end
    end
  })
end
```

Testing:
```bash
# Test visual selection workflow
:TestFile lua/neotex/plugins/ai/claude/core/visual.lua
# Or manual test:
# 1. Select text in visual mode
# 2. Press <leader>as (or visual send command)
# 3. Verify command appears in Claude Code, not underlying terminal
```

**Expected**: Visual selection workflow works without race condition

---

### Phase 4: Refactor picker.lua to Use Shared Module [COMPLETED]
**Objective**: Remove ad-hoc retry logic from picker.lua, use event-driven state module
**Complexity**: Medium

Tasks:
- [x] Add `local terminal_state = require('neotex.plugins.ai.claude.utils.terminal-state')` to picker.lua
- [x] Locate `send_command_to_terminal()` function (around line 277)
- [x] Remove `wait_for_claude_and_send_command()` function entirely
- [x] Remove all `vim.defer_fn()` timer usage from command sending
- [x] Remove exponential backoff retry logic
- [x] Replace buffer search loop with `terminal_state.find_claude_terminal()`
- [x] Replace `feedkeys()` with `terminal_state.queue_command()`
- [x] Remove hardcoded delays (200ms, 300ms, 500ms, 1000ms)
- [x] Simplify logic: check if terminal exists, if not open it, then queue command

Key changes:
```lua
-- OLD (timer-based with exponential backoff):
local function send_command_to_terminal(command)
  local command_text = "/" .. command.name
  -- ... 100+ lines of retry logic with timers ...

  local function wait_for_claude_and_send_command(attempt)
    attempt = attempt or 1
    local max_attempts = 10
    local base_delay = 500

    vim.defer_fn(function()
      -- Search for terminal, retry with backoff
      -- ...
    end, base_delay * attempt)
  end

  wait_for_claude_and_send_command()
end

-- NEW (event-driven):
local function send_command_to_terminal(command)
  local notify = require('neotex.util.notifications')
  local terminal_state = require('neotex.plugins.ai.claude.utils.terminal-state')
  local command_text = "/" .. command.name

  -- Check if Claude Code plugin is available
  local has_claude_code = pcall(require, "claude-code")
  if not has_claude_code then
    notify.editor("Claude Code plugin not found", notify.categories.ERROR)
    return
  end

  -- Find or open terminal
  local claude_buf = terminal_state.find_claude_terminal()
  if not claude_buf then
    notify.editor("Opening Claude Code...", notify.categories.WARNING)
    vim.cmd('ClaudeCode')  -- Triggers TermOpen autocommand
  end

  -- Queue command - autocommand will send when ready
  terminal_state.queue_command(command_text, {
    auto_focus = true,
    notification = function()
      notify.editor(
        string.format("Inserted '%s' into Claude Code", command_text),
        notify.categories.USER_ACTION
      )
    end
  })
end
```

Testing:
```bash
# Test command picker workflow
# 1. Press <leader>ac
# 2. Select a command
# 3. Verify command appears in Claude Code terminal, not underlying terminal
# 4. Test with Claude closed (should open and send)
# 5. Test with Claude already open (should send immediately)
```

**Expected**: Command picker works without race condition, commands always appear in Claude terminal

---

### Phase 5: Cleanup and Polish [COMPLETED]
**Objective**: Remove all timer-based code, verify no regressions
**Complexity**: Low

Tasks:
- [x] Search codebase for `vim.loop.new_timer()` in Claude-related files - verified clean (only in unrelated files)
- [x] Search for `vim.defer_fn()` in picker.lua and visual.lua - verified all terminal timing removed
- [x] Verify no `wait_for_ready` functions remain - confirmed removed
- [x] Check for any remaining exponential backoff logic - confirmed removed
- [x] Add module documentation to terminal-state.lua header - comprehensive header added
- [x] Update visual.lua comments to reference shared module - updated header
- [x] Update picker.lua comments to reference shared module - updated function docs
- [x] Verify TermOpen/TermClose autocommands only exist in terminal-state.lua - verified (session.lua has separate one for sessions)

Code audit checklist:
```bash
# Search for timer usage
rg "vim\.loop\.new_timer" lua/neotex/plugins/ai/claude/
rg "vim\.defer_fn" lua/neotex/plugins/ai/claude/
rg "wait_for_ready" lua/neotex/plugins/ai/claude/

# Should return NO results or only results in terminal-state.lua setup
```

Testing:
```bash
# Full integration test
:TestSuite
# Manual test sequence:
# 1. Restart Neovim
# 2. Test visual selection send (<leader>as)
# 3. Test command picker (<leader>ac)
# 4. Test with Claude already open
# 5. Test with Claude closed (fresh start)
# 6. Verify no commands appear in wrong terminal
```

**Expected**: All tests pass, no timer-based code remains except in shared module setup

---

### Phase 6: Enhanced Readiness Detection (Optional)
**Objective**: Add TermRequest autocommand for OSC 133 sequence detection
**Complexity**: Low
**Priority**: Optional Enhancement

Tasks:
- [ ] Research if Claude Code emits OSC 133 sequences
- [ ] Add TermRequest autocommand to terminal-state.lua setup()
- [ ] Detect OSC 133;A sequence (marks prompt start)
- [ ] Set state = READY when sequence detected
- [ ] Flush queue on sequence detection
- [ ] Test with actual Claude Code terminal

Implementation:
```lua
-- In setup() function
vim.api.nvim_create_autocmd("TermRequest", {
  pattern = "*claude*",
  callback = function(args)
    -- OSC 133;A marks prompt start (shell integration)
    if string.match(args.data.sequence or "", '^\027]133;A') then
      state = M.State.READY
      M.flush_queue(args.buf)
    end
  end
})
```

Testing:
```bash
# Check if Claude emits OSC sequences
:au TermRequest
# Send a command and check autocmd log
```

**Expected**: More precise detection if OSC sequences available, graceful fallback if not

## Testing Strategy

### Unit Testing
- Test `is_terminal_ready()` with sample buffer content
- Test `queue_command()` and `flush_queue()` logic
- Test state transitions

### Integration Testing
1. **Visual selection workflow**
   - Select text, send to Claude (Claude closed)
   - Select text, send to Claude (Claude open)
   - Verify command appears in correct terminal

2. **Command picker workflow**
   - Pick command with Claude closed
   - Pick command with Claude open
   - Verify no race condition

3. **State lifecycle**
   - Open Claude → verify TermOpen fires
   - Wait for ready → verify TextChanged detects pattern
   - Close Claude → verify TermClose fires, queue cleared

### Regression Testing
- Ensure all existing visual.lua functionality works
- Ensure all existing picker.lua functionality works
- Verify no performance degradation

## Error Handling

### Error Types and Recovery
1. **Terminal not found** (`no_terminal`)
   - Action: Open Claude Code via `vim.cmd('ClaudeCode')`
   - Retry: Automatic via TermOpen autocommand

2. **Job ID unavailable** (`no_job_id`)
   - Action: Wait for next TextChanged event
   - Fallback: Warn user if persistent

3. **Stale command** (`command_stale`)
   - Detection: Command older than 30 seconds
   - Action: Discard command, notify user

4. **Pattern never matched** (implicitly handled)
   - Detection: TextChanged fires but pattern not found
   - Action: Continue monitoring until TermClose or pattern found

## Documentation Requirements

### Code Documentation
- [ ] Add module header to terminal-state.lua explaining purpose
- [ ] Document each public function with @param and @return annotations
- [ ] Add state lifecycle diagram in comments
- [ ] Document readiness patterns and priority

### User Documentation
- No user-facing documentation needed (internal refactor)
- Update CHANGELOG.md if applicable

## Dependencies

### Internal Dependencies
- Existing `visual.lua` module
- Existing `picker.lua` module
- Neovim autocommand system
- Claude Code terminal integration

### External Dependencies
- Neovim >= 0.7 (for autocommand APIs)
- claude-code.nvim plugin

## Notes

### Design Decisions
1. **Why event-driven over timers?**
   - More reliable: responds to actual terminal state changes
   - More efficient: no polling overhead
   - More predictable: deterministic based on events

2. **Why TextChanged autocommand?**
   - Fires when terminal buffer content updates
   - Allows pattern matching on actual terminal output
   - Can be cleaned up after readiness detected

3. **Why per-buffer autocommand group?**
   - Allows cleanup when readiness detected
   - Prevents memory leaks from stale autocommands
   - Isolates monitoring per terminal instance

4. **Why command queue?**
   - Handles case where terminal not yet ready
   - Automatic flush when ready (no manual retry)
   - Supports multiple pending commands

### Known Limitations
- TextChanged autocmd bug: only fires when cursor in buffer
  - Mitigation: Terminal usually has focus when opening
  - Fallback: Pattern check runs on each content update regardless
- Pattern matching reliability: depends on Claude Code output format
  - Mitigation: Multiple pattern checks with priority order
  - Future: Add OSC 133 sequence detection (Phase 6)

### Migration Path
1. Phase 1-2: Create new module (no breaking changes)
2. Phase 3: Refactor visual.lua (existing functionality preserved)
3. Phase 4: Refactor picker.lua (existing functionality preserved)
4. Phase 5: Cleanup (verify no regressions)

### Performance Considerations
- Event-driven approach reduces CPU usage (no polling)
- Per-buffer autocommands cleaned up after use (no memory leak)
- Pattern matching on last 10 lines only (efficient)
- Command queue bounded by 30-second freshness check

## References

### Research Report
- `/home/benjamin/.config/nvim/specs/reports/025_claude_code_terminal_timing_synchronization.md`

### Code Files to Modify
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/visual.lua` (lines 240-289, 519-561)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` (lines 277-414)

### Code Files to Create
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`

### Neovim Documentation
- `:help autocmd-events` (TermOpen, TermClose, TextChanged)
- `:help nvim_create_autocmd()`
- `:help nvim_create_augroup()`
- `:help chansend()`
