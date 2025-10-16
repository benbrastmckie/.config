# Claude Command Timing Synchronization Research Report

## Metadata
- **Date**: 2025-09-29
- **Scope**: Command execution timing issues when Claude Code terminal is not ready
- **Primary Directory**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude`
- **Files Analyzed**: picker.lua, claudecode.lua, claude-code.lua, terminal detection modules
- **Specific Issue**: Commands being typed before Claude Code welcome message completes

## Executive Summary

When executing commands through the Claude commands picker (`<leader>ac`) before Claude Code has opened, the command text appears before the welcome message, resulting in the command being displayed but not executed. This occurs because the current implementation uses fixed timing delays rather than detecting when Claude Code is actually ready to receive input. The issue manifests as:

```
/cleanup╭───────────────────────────────────────────────────╮
│ ✻ Welcome to Claude Code!                         │
│                                                   │
│   /help for help, /status for your current setup  │
│                                                   │
│   cwd: /home/benjamin/.dotfiles                   │
╰───────────────────────────────────────────────────╯
```

## Background

The Claude commands picker integration needs to handle three distinct states:
1. **Claude Code Already Open and Ready**: Direct command execution
2. **Claude Code Opening**: Must wait for initialization
3. **Claude Code Not Started**: Must start, then wait for initialization

The current implementation attempts to handle these states but relies on timing-based approaches that fail to account for the Claude Code CLI's initialization sequence.

## Current State Analysis

### Command Execution Flow

The `send_command_to_terminal()` function in `picker.lua` follows this flow:

1. **Checks for existing Claude terminal** (lines 297-308)
   - Looks for buffers with "claude" in the name
   - Retrieves buffer and channel if found

2. **If terminal not found** (lines 310-385)
   - Opens Claude Code via `claude_code.toggle()`
   - Uses `wait_for_claude_and_send_command()` with exponential backoff
   - Attempts to find terminal buffer up to 10 times
   - Uses `vim.api.nvim_feedkeys()` to send command

3. **If terminal exists** (lines 388-399)
   - Sends command directly via `vim.api.nvim_chan_send()`
   - Focuses the terminal window
   - Enters insert mode

### The Timing Problem

The critical issue occurs in the deferred execution path (lines 349-363):

```lua
vim.defer_fn(function()
  -- Clear any existing input and enter insert mode
  vim.api.nvim_feedkeys('cc', 'n', false)  -- Line 352
  vim.defer_fn(function()
    -- Type the command
    vim.api.nvim_feedkeys(command_text, 'n', false)  -- Line 355
  end, 200)  -- 200ms delay
end, 300)  -- 300ms delay
```

This uses fixed delays (300ms + 200ms = 500ms total) which:
- May be too short if Claude Code takes longer to initialize
- May be too long for quick systems, causing unnecessary wait
- Doesn't account for the welcome message display time
- Doesn't verify Claude Code is actually ready

## Key Findings

### 1. No Ready-State Detection

The current implementation lacks any mechanism to detect when Claude Code has:
- Finished displaying the welcome message
- Completed initialization
- Become ready to accept commands

### 2. Race Condition with Welcome Message

The Claude Code CLI displays a welcome box immediately upon startup:
```
╭───────────────────────────────────────────────────╮
│ ✻ Welcome to Claude Code!                         │
│                                                   │
│   /help for help, /status for your current setup  │
│                                                   │
│   cwd: /home/benjamin/.dotfiles                   │
╰───────────────────────────────────────────────────╯
```

Commands sent during this display get prepended to the terminal output, appearing before the welcome message.

### 3. Inconsistent Behavior Patterns

The issue manifests differently based on:
- **System speed**: Faster systems may initialize before the 500ms timeout
- **Terminal emulator**: Different terminals have varying startup times
- **Claude Code state**: First startup vs. subsequent opens
- **System load**: High CPU usage delays initialization

### 4. Missing Terminal APIs

The `claude-code.nvim` plugin doesn't provide:
- Ready-state callbacks
- Initialization complete events
- APIs to check if welcome message has finished
- Methods to queue commands for post-initialization execution

## Technical Details

### Current Implementation Weaknesses

1. **Fixed Timing Assumptions**
   - 300ms initial delay (line 363)
   - 200ms command insertion delay (line 362)
   - 500ms base retry delay (line 381)
   - Exponential backoff without ready detection

2. **Feedkeys Approach**
   - Uses `vim.api.nvim_feedkeys('cc', 'n', false)` to clear
   - Assumes 'cc' will clear any partial input
   - No verification that clearing succeeded

3. **No Welcome Message Detection**
   - Doesn't check buffer content for welcome box
   - Can't detect when welcome message completes
   - No way to wait for prompt appearance

### Alternative Approaches Considered

1. **Buffer Content Monitoring**
   - Watch for specific strings in terminal buffer
   - Detect welcome box completion (closing box character `╯`)
   - Wait for prompt or empty line after welcome

2. **Channel Communication**
   - Use `vim.api.nvim_chan_send()` with newline
   - Problem: Still sends before ready if terminal not initialized

3. **Terminal Job Control**
   - Use Neovim's job control APIs
   - Problem: `claude-code.nvim` manages the terminal

## Recommendations

### Short-term Solutions

1. **Increase Initial Delay**
   ```lua
   -- Increase from 300ms to 1000ms for initial wait
   vim.defer_fn(function()
     -- Wait longer for Claude Code to initialize
   end, 1000)
   ```

2. **Add Buffer Content Detection**
   ```lua
   local function is_claude_ready(buf)
     local lines = vim.api.nvim_buf_get_lines(buf, -10, -1, false)
     for _, line in ipairs(lines) do
       -- Check for welcome box completion
       if line:match("╯") or line:match("^%s*$") then
         return true
       end
     end
     return false
   end
   ```

3. **Implement Retry with Ready Check**
   ```lua
   local function wait_and_send(buf, channel, command, attempts)
     if is_claude_ready(buf) then
       vim.api.nvim_chan_send(channel, command .. "\n")
     elseif attempts < 20 then
       vim.defer_fn(function()
         wait_and_send(buf, channel, command, attempts + 1)
       end, 250)
     end
   end
   ```

### Long-term Solutions

1. **Enhance claude-code.nvim Plugin**
   - Add ready-state API
   - Provide initialization complete callback
   - Queue commands during startup

2. **Create Integration Module**
   - Centralized Claude Code interaction
   - State management for terminal readiness
   - Command queueing system

3. **Use Terminal Protocol**
   - Send escape sequences to detect prompt
   - Monitor for specific response patterns
   - Implement handshake mechanism

### Recommended Implementation Strategy

1. **Phase 1: Immediate Fix**
   - Increase delays to 1-2 seconds
   - Add simple buffer content checking
   - Test across different systems

2. **Phase 2: Smart Detection**
   - Implement welcome message detection
   - Add ready-state monitoring
   - Create retry mechanism with backoff

3. **Phase 3: Robust Integration**
   - Build dedicated integration module
   - Implement command queueing
   - Add comprehensive error handling

## Implementation Example

Here's a robust solution that could replace the current implementation:

```lua
local function send_command_when_ready(command_text)
  local max_wait = 10000  -- 10 seconds max
  local check_interval = 100  -- Check every 100ms
  local start_time = vim.loop.now()

  local function check_and_send()
    local elapsed = vim.loop.now() - start_time
    if elapsed > max_wait then
      vim.notify("Claude Code did not become ready", vim.log.levels.ERROR)
      return
    end

    -- Find Claude terminal
    local buf, channel = find_claude_terminal()
    if not buf then
      -- Terminal not yet created, check again
      vim.defer_fn(check_and_send, check_interval)
      return
    end

    -- Check if ready by examining buffer content
    local lines = vim.api.nvim_buf_get_lines(buf, -20, -1, false)
    local ready = false

    for i = #lines, 1, -1 do
      local line = lines[i]
      -- Look for indicators that welcome is complete
      if line:match("╯") then  -- End of welcome box
        -- Check if there's content after the box
        for j = i + 1, #lines do
          if lines[j]:match("^%s*$") or lines[j]:match("^>") then
            ready = true
            break
          end
        end
        if ready then break end
      end
    end

    if ready then
      -- Send command with newline to execute
      vim.api.nvim_chan_send(channel, command_text .. "\n")

      -- Focus terminal
      local wins = vim.fn.win_findbuf(buf)
      if #wins > 0 then
        vim.api.nvim_set_current_win(wins[1])
        vim.cmd('startinsert!')
      end
    else
      -- Not ready yet, check again
      vim.defer_fn(check_and_send, check_interval)
    end
  end

  -- Start checking
  check_and_send()
end
```

## Testing Scenarios

To ensure consistent behavior, test these scenarios:

1. **Cold Start**: Claude Code not running
2. **Warm Start**: Claude Code recently closed
3. **Already Open**: Claude Code running and idle
4. **Busy Terminal**: Claude Code processing another command
5. **Slow System**: High CPU load during startup
6. **Fast System**: Instant initialization
7. **Network Delays**: If Claude Code needs network access

## Conclusion

The current timing-based approach is fundamentally fragile and cannot provide consistent behavior across different environments and states. The solution requires detecting when Claude Code is actually ready to receive commands rather than assuming fixed delays will work. This can be achieved through buffer content monitoring in the short term, with a longer-term goal of enhancing the plugin integration to provide proper ready-state APIs.

## References

### Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` - Command execution logic
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua` - Plugin configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/claude-code.lua` - Utility functions
- `https://github.com/greggh/claude-code.nvim` - Plugin source and documentation

### Related Issues
- Race condition between command insertion and terminal initialization
- Fixed timing delays not accounting for system variations
- No ready-state detection mechanism
- Missing APIs for terminal state management

---

**Research Duration**: ~25 minutes
**Complexity**: High - requires understanding terminal lifecycle and timing issues
**Priority**: High - affects user experience and command reliability