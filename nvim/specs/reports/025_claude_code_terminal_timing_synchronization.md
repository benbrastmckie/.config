# Claude Code Terminal Timing and Synchronization Research Report

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 025
- **Scope**: Research Claude Code hooks and Neovim autocommands for synchronized terminal input
- **Primary Directory**: `/home/benjamin/.config/nvim`
- **Files Analyzed**:
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/visual.lua`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`
- **Research Focus**: Fixing the timing issue where `<leader>ac` command selection prints to terminal before Claude Code opens

## Executive Summary

The current `<leader>ac` implementation experiences a race condition: when Claude Code is not already open, selecting a command from the picker prints it to the underlying terminal window. The command appears briefly before being covered by the Claude Code terminal once it opens. This report investigates two complementary solutions:

1. **Claude Code Hooks** - Using SessionStart or UserPromptSubmit hooks to inject commands when Claude is ready
2. **Neovim Autocommands** - Using TermOpen callbacks with pattern matching to detect terminal readiness

**Key Finding**: The best solution combines Neovim's TermOpen autocommand with pattern-based readiness detection (already partially implemented in `visual.lua:519-561`) rather than relying on Claude Code hooks, which are designed for different use cases.

## Problem Analysis

### Current Workflow (visual.lua:596-659 and picker.lua:277-414)

1. User presses `<leader>ac` in visual mode
2. Telescope picker opens with available commands
3. User selects a command
4. Code checks if Claude Code terminal exists
5. **If not open**: Opens Claude Code with `vim.cmd('ClaudeCode')` or `claude_code.toggle()`
6. **Race condition occurs**: Command is sent via `chansend()` or `feedkeys()` before terminal is ready
7. Command briefly appears in wrong terminal, then gets covered when Claude opens

### Current Partial Solution (visual.lua:240-289)

The `wait_for_ready()` function already implements a timer-based approach:
- Polls every 100ms for terminal readiness
- Looks for Claude prompt patterns: `^>`, `────────`, "Welcome to Claude Code", "? for shortcuts"
- Has configurable timeout (default 5000ms)
- Uses `vim.schedule_wrap()` for safe async execution

**Problem**: This solution is used in `visual.lua` but NOT in `picker.lua:329-384`, where the command picker implements its own ad-hoc retry logic with hardcoded delays.

## Research Findings

### 1. Claude Code Hooks System

#### Available Hook Events
Claude Code provides 8 lifecycle hooks:

1. **UserPromptSubmit** - Fires when user submits a prompt (before Claude processes it)
   - Use case: Validate prompts, add context, block dangerous requests
   - Receives: `{session_id, transcript_path, cwd, prompt_text}`
   - Can output JSON to modify or block the prompt

2. **SessionStart** - Fires when Claude Code starts or resumes a session
   - Use case: Load development context (issues, recent changes)
   - Can inject additional context via JSON output
   - Timing: Runs at session initialization

3. **PreToolUse/PostToolUse** - Before/after tool execution
4. **Stop/SubagentStop** - When Claude finishes responding
5. **PreCompact** - Before compact operations
6. **SessionEnd** - When session ends

#### Hook Execution Model
- Written as shell scripts in `.claude/hooks/` directory
- Receive data via stdin (JSON payload)
- Output via stdout (plain text or JSON)
- Exit codes control behavior:
  - `0`: Success, continue
  - `2`: Block operation, show error
  - Other: Non-blocking error
- 60-second timeout per hook (configurable)
- Multiple hooks run in parallel
- Automatic deduplication

#### Why Hooks Don't Solve Our Problem

**SessionStart hook** runs too early - it's for loading context at session initialization, not for command insertion after the terminal is visually ready.

**UserPromptSubmit hook** only fires when the user submits a prompt - it doesn't help us inject a command when Claude first opens.

**Conclusion**: Claude Code hooks are designed for workflow automation and context injection, NOT for solving terminal timing synchronization issues.

### 2. Neovim Terminal Autocommands

#### Available Events

**TermOpen**
- Fires when terminal buffer is created
- Channel is available immediately via `vim.api.nvim_buf_get_var(buf, 'terminal_job_id')`
- Perfect for initial setup and monitoring

**TermEnter/TermLeave**
- Fire when cursor enters/leaves terminal window
- Useful for mode switching

**TermClose**
- Fires when terminal exits
- Useful for cleanup

**TextChanged/TextChangedI**
- Fire when terminal buffer content changes
- **BUG**: `TextChangedI` doesn't work in terminal buffers (documented Neovim bug)
- `TextChanged` only fires when cursor is in the terminal buffer

#### Terminal Readiness Detection Patterns

The visual.lua implementation (lines 258-276) already demonstrates the correct pattern:

```lua
-- Look for the characteristic Claude Code prompt pattern
for _, line in ipairs(lines) do
  if line:match("^>") or                           -- Main prompt
     line:match("────────") or                      -- Separator line
     line:match("Welcome to Claude Code!") or      -- Welcome completed
     line:match("? for shortcuts") then            -- Ready for input
    is_ready = true
    break
  end
end
```

**Additional robust pattern** (line 275):
```lua
local text = table.concat(lines, "\n")
if text:match("Try.*%s*────.*%s*%?.*shortcuts") then
  is_ready = true
end
```

#### Job Control and Channel Communication

**chansend() behavior**:
- Sends data to terminal job via channel ID
- Returns immediately (async)
- Data may be buffered - not guaranteed to appear instantly
- No confirmation of delivery

**Job event handlers**:
- `on_stdout/on_stderr` callbacks are asynchronous
- May receive partial (incomplete) lines
- Data not guaranteed to end with newline
- Can be used with `termopen()` to monitor output

**Best practice** from research:
```lua
-- Use termopen() with on_stdout to monitor terminal readiness
local job_id = vim.fn.termopen('claude', {
  on_stdout = function(_, data, _)
    -- Check for readiness patterns in data
    for _, line in ipairs(data) do
      if line:match("^>") or line:match("Welcome to Claude Code") then
        -- Terminal is ready, safe to send commands
      end
    end
  end
})
```

### 3. Current Implementation Analysis

#### visual.lua Implementation (Strong Foundation)

**Strengths**:
- Comprehensive state tracking (ClaudeTerminalState: CLOSED, OPENING, READY, BUSY)
- Robust terminal monitoring with TermOpen/TermClose autocmds (lines 519-561)
- Pattern-based readiness detection with timeout
- Pending message queue for retry logic
- Automatic message sending when terminal becomes ready (lines 538-542)

**Implementation**:
```lua
-- Lines 519-551: Terminal monitoring setup
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*claude*",
  callback = function(args)
    local buf = args.buf
    terminal_state = ClaudeTerminalState.OPENING

    -- Monitor for ready state with TextChanged
    vim.api.nvim_create_autocmd("TextChanged", {
      buffer = buf,
      callback = function()
        if terminal_state == ClaudeTerminalState.OPENING then
          local lines = vim.api.nvim_buf_get_lines(buf, -3, -1, false)
          for _, line in ipairs(lines) do
            if line:match("Welcome to Claude Code") or
               line:match("^>") or
               line:match("──────") then
              terminal_state = ClaudeTerminalState.READY

              -- Auto-send pending message
              if pending_message and
                 (os.time() - pending_message.timestamp < 30) then
                vim.defer_fn(function()
                  M.submit_message(buf, pending_message.text, pending_message.prompt)
                end, 500)
              end
              break
            end
          end
        end
      end
    })
  end
})
```

**Note**: TextChanged autocmd has a documented bug in terminal buffers - it only fires when the cursor is in the buffer, which is why the timer-based `wait_for_ready()` approach is more reliable.

#### picker.lua Implementation (Needs Improvement)

**Current approach** (lines 329-384):
```lua
local function wait_for_claude_and_send_command(attempt)
  attempt = attempt or 1
  local max_attempts = 10
  local base_delay = 500

  vim.defer_fn(function()
    -- Search for terminal buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf_name:lower():match("claude") or buf_name:match("ClaudeCode") then
        -- Found terminal, focus and send command
        vim.api.nvim_feedkeys('cc', 'n', false)
        vim.defer_fn(function()
          vim.api.nvim_feedkeys(command_text, 'n', false)
        end, 200)
        return
      end
    end

    -- Retry with exponential backoff
    if attempt < max_attempts then
      wait_for_claude_and_send_command(attempt + 1)
    end
  end, base_delay * attempt)  -- 500ms, 1000ms, 1500ms...
end
```

**Problems**:
1. No pattern-based readiness detection - assumes terminal is ready if buffer exists
2. Uses hardcoded delays instead of actual state checking
3. Duplicates logic that exists in visual.lua
4. Uses `feedkeys()` instead of `chansend()` (less reliable)
5. No integration with existing terminal state management

## Recommended Solutions

### Solution 1: Unify Terminal State Management (Recommended)

Extract the terminal state management from `visual.lua` into a shared module that both `visual.lua` and `picker.lua` can use.

**New module**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua`

```lua
local M = {}

-- Terminal state enum
M.State = {
  CLOSED = 0,
  OPENING = 1,
  READY = 2,
  BUSY = 3
}

local state = M.State.CLOSED
local pending_commands = {}
local ready_callbacks = {}

-- Check if terminal is ready by pattern matching
function M.is_terminal_ready(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, -10, -1, false)

  -- Check individual patterns
  for _, line in ipairs(lines) do
    if line:match("^>") or
       line:match("────────") or
       line:match("Welcome to Claude Code!") or
       line:match("? for shortcuts") then
      return true
    end
  end

  -- Check combined pattern
  local text = table.concat(lines, "\n")
  return text:match("Try.*%s*────.*%s*%?.*shortcuts") ~= nil
end

-- Wait for terminal to be ready, then execute callback
function M.when_ready(callback, timeout)
  timeout = timeout or 5000
  local start_time = vim.loop.now()

  local timer = vim.loop.new_timer()
  timer:start(100, 100, vim.schedule_wrap(function()
    local claude_buf = M.find_claude_terminal()

    if not claude_buf then
      if vim.loop.now() - start_time > timeout then
        timer:stop()
        callback(nil, "timeout")
        return
      end
      return
    end

    if M.is_terminal_ready(claude_buf) then
      timer:stop()
      state = M.State.READY
      callback(claude_buf, nil)
    elseif vim.loop.now() - start_time > timeout then
      timer:stop()
      callback(claude_buf, "not_ready")
    end
  end))
end

-- Queue command to be sent when terminal is ready
function M.queue_command(command_text, opts)
  opts = opts or {}

  table.insert(pending_commands, {
    text = command_text,
    timestamp = os.time(),
    opts = opts
  })

  -- Try to send immediately if ready
  local claude_buf = M.find_claude_terminal()
  if claude_buf and M.is_terminal_ready(claude_buf) then
    M.flush_queue(claude_buf)
  else
    -- Wait for ready state
    M.when_ready(function(buf, err)
      if buf and not err then
        M.flush_queue(buf)
      end
    end)
  end
end

-- Send all queued commands
function M.flush_queue(claude_buf)
  while #pending_commands > 0 do
    local cmd = table.remove(pending_commands, 1)

    -- Check if command is still fresh (< 30 seconds old)
    if os.time() - cmd.timestamp < 30 then
      M.send_to_terminal(claude_buf, cmd.text, cmd.opts)
    end
  end
end

-- Send command to terminal (safe wrapper around chansend)
function M.send_to_terminal(claude_buf, command_text, opts)
  opts = opts or {}

  local ok, job_id = pcall(vim.api.nvim_buf_get_var, claude_buf, 'terminal_job_id')
  if not ok or not job_id then
    return false, "no_job_id"
  end

  -- Send command (without newline unless explicitly requested)
  vim.fn.chansend(job_id, command_text)

  -- Optionally focus terminal and enter insert mode
  if opts.auto_focus then
    M.focus_terminal(claude_buf)
  end

  return true
end

-- Focus Claude terminal window
function M.focus_terminal(claude_buf)
  local wins = vim.fn.win_findbuf(claude_buf)
  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
    if vim.api.nvim_get_mode().mode == 'n' then
      vim.cmd('startinsert!')
    end
  end
end

-- Find Claude terminal buffer
function M.find_claude_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      local buftype = vim.bo[buf].buftype
      if buftype == "terminal" and (bufname:match("claude") or bufname:match("ClaudeCode")) then
        return buf
      end
    end
  end
  return nil
end

-- Setup terminal monitoring (call once during initialization)
function M.setup()
  -- Monitor terminal open
  vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*claude*",
    callback = function(args)
      state = M.State.OPENING

      -- Create one-time autocmd to detect readiness
      local ready_check_group = vim.api.nvim_create_augroup("ClaudeReadyCheck_" .. args.buf, { clear = true })

      vim.api.nvim_create_autocmd("TextChanged", {
        group = ready_check_group,
        buffer = args.buf,
        callback = function()
          if M.is_terminal_ready(args.buf) then
            state = M.State.READY
            -- Flush any pending commands
            M.flush_queue(args.buf)
            -- Remove this autocmd
            vim.api.nvim_del_augroup_by_id(ready_check_group)
          end
        end
      })
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

return M
```

**Then refactor picker.lua** to use this module:

```lua
-- In picker.lua:277-414, replace wait_for_claude_and_send_command with:
local terminal_state = require('neotex.plugins.ai.claude.utils.terminal-state')

local function send_command_to_terminal(command)
  local command_text = "/" .. command.name

  -- Check if Claude Code is available
  local has_claude_code = pcall(require, "claude-code")
  if not has_claude_code then
    notify.editor("Claude Code plugin not found", notify.categories.ERROR)
    return
  end

  -- Find or open Claude terminal
  local claude_buf = terminal_state.find_claude_terminal()

  if not claude_buf then
    -- Open Claude Code
    notify.editor("Opening Claude Code...", notify.categories.WARNING)
    vim.cmd('ClaudeCode')

    -- Queue command to be sent when ready
    terminal_state.queue_command(command_text, {
      auto_focus = true,
      notification = function()
        notify.editor(
          string.format("Sent command '%s' to Claude Code", command_text),
          notify.categories.USER_ACTION
        )
      end
    })
  else
    -- Terminal exists, check if ready
    terminal_state.when_ready(function(buf, err)
      if buf and not err then
        local success = terminal_state.send_to_terminal(buf, command_text, { auto_focus = true })
        if success then
          notify.editor(
            string.format("Inserted '%s' into Claude Code terminal", command_text),
            notify.categories.USER_ACTION
          )
        end
      else
        notify.editor("Claude Code terminal not ready", notify.categories.ERROR)
      end
    end, 3000)  -- 3 second timeout
  end
end
```

### Solution 2: Use TermRequest for More Precise Detection (Advanced)

For even more precise detection, Neovim's `TermRequest` autocmd can detect OSC sequences that mark prompt boundaries:

```lua
vim.api.nvim_create_autocmd("TermRequest", {
  pattern = "*claude*",
  callback = function(args)
    -- OSC 133;A marks prompt start
    if string.match(args.data.sequence, '^\027]133;A') then
      -- Terminal is at a prompt, definitely ready
      state = M.State.READY
      M.flush_queue(args.buf)
    end
  end
})
```

**Note**: This requires Claude Code to emit OSC 133 sequences, which may not be guaranteed.

### Solution 3: Leverage SessionStart Hook (Supplementary)

While hooks don't directly solve the timing issue, a SessionStart hook can help by ensuring all sessions start with known context:

**File**: `.claude/hooks/user-prompt-submit`
```bash
#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Parse session info
session_id=$(echo "$input" | jq -r '.session_id')
cwd=$(echo "$input" | jq -r '.cwd')

# Output additional context for new sessions
# This doesn't help with command timing but ensures consistent context
echo "{
  \"hookSpecificOutput\": {
    \"hookEventName\": \"SessionStart\",
    \"additionalContext\": \"Working directory: $cwd\"
  }
}"
```

This is supplementary and doesn't replace the Neovim-side timing solution.

## Implementation Roadmap

### Phase 1: Extract Shared Terminal State Module (Priority: High)
1. Create `terminal-state.lua` with unified state management
2. Implement pattern-based readiness detection
3. Add command queue with automatic flushing
4. Setup TermOpen/TermClose monitoring

### Phase 2: Refactor Existing Code (Priority: High)
1. Update `visual.lua` to use shared terminal state module
2. Refactor `picker.lua` to use shared terminal state module
3. Remove duplicated timing/retry logic
4. Standardize on `chansend()` over `feedkeys()`

### Phase 3: Enhanced Detection (Priority: Medium)
1. Add TermRequest autocmd for OSC 133 sequence detection
2. Implement more robust pattern matching
3. Add telemetry for timing issues
4. Fine-tune timeout values based on real usage

### Phase 4: Polish (Priority: Low)
1. Add user configuration for timeout values
2. Implement retry strategies
3. Add debug mode for troubleshooting
4. Document the terminal state lifecycle

## Technical Specifications

### Terminal State Lifecycle

```
CLOSED
  |
  | (ClaudeCode command issued)
  v
OPENING
  |
  | (TermOpen fires)
  v
OPENING (monitoring for readiness patterns)
  |
  | (Pattern detected: "^>" or "Welcome to Claude Code")
  v
READY
  |
  | (Command sent via chansend)
  v
BUSY
  |
  | (Command completed or error)
  v
READY (or CLOSED if terminal closed)
```

### Readiness Detection Patterns (Priority Order)

1. **Main prompt**: `^>` - Highest priority, most reliable
2. **Welcome completion**: `Welcome to Claude Code!` - Initial session ready
3. **Separator**: `────────` - Visual separator indicating UI ready
4. **Help text**: `? for shortcuts` - Footer indicates complete render
5. **Combined pattern**: `Try.*────.*?.*shortcuts` - Multi-line match for robustness

### Timing Characteristics

**Observed timing** (from research and code analysis):
- Terminal buffer creation (TermOpen): ~50-100ms
- Terminal content rendering: ~200-500ms
- Full UI ready (prompt visible): ~500-1000ms
- Safe command insertion window: >500ms after TermOpen

**Current implementation timing**:
- visual.lua: 100ms poll interval, 5000ms timeout
- picker.lua: 500ms base delay with exponential backoff (500, 1000, 1500...)

**Recommended timing**:
- Poll interval: 100ms (current is good)
- Initial delay: 0ms (start checking immediately)
- Timeout: 3000ms (reduce from 5000ms - Claude should be ready within 3s)
- Retry delay after error: 500ms

### Error Handling Strategy

**Error types**:
1. `timeout` - Terminal opened but never became ready
2. `no_terminal` - Terminal never opened
3. `no_job_id` - Terminal exists but job channel unavailable
4. `command_stale` - Queued command expired (>30s old)

**Recovery actions**:
1. `timeout` - Send command anyway, notify user
2. `no_terminal` - Retry opening Claude Code once
3. `no_job_id` - Wait 100ms and retry getting job_id
4. `command_stale` - Discard command, notify user

## Conclusion

The timing issue with `<leader>ac` is NOT solvable with Claude Code hooks, which are designed for workflow automation, not terminal synchronization. The solution lies in improving the existing Neovim autocommand infrastructure.

**Best approach**: Extract the robust terminal state management from `visual.lua` into a shared module, then refactor both `visual.lua` and `picker.lua` to use it. This eliminates the race condition by ensuring commands are only sent after pattern-based readiness detection confirms the terminal is ready.

**Key insight**: The current `visual.lua` implementation already has most of the pieces needed - they just need to be extracted, generalized, and reused in `picker.lua`.

## References

### Code Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/visual.lua:519-561` - Terminal monitoring implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/visual.lua:240-289` - wait_for_ready() implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:277-414` - Command sending with timing issues

### Documentation
- Claude Code Hooks Reference: https://docs.claude.com/en/docs/claude-code/hooks
- Neovim Terminal Documentation: http://neovim.io/doc/user/nvim_terminal_emulator.html
- Neovim Autocmd Documentation: https://neovim.io/doc/user/autocmd.html
- Neovim Job Control: https://neovim.io/doc/user/job_control.html

### Related Reports
- `009_claude_command_timing_synchronization.md` - Earlier analysis of timing issues
- `017_claude_code_command_picker_synchronization.md` - Command picker specific timing
- `018_claude_code_command_execution_fix.md` - Command execution improvements
- `023_autocommand_claude_readiness_detection.md` - Autocommand-based detection strategies
