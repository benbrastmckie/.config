# Claude Code Command Picker Synchronization Research Report

## Metadata
- **Date**: 2025-09-30
- **Scope**: Command picker timing synchronization and autocommand patterns
- **Primary Directory**: /home/benjamin/.config/nvim/specs/reports/
- **Files Analyzed**: 28 files across AI/Claude integration modules
- **Issue**: Command picker fails when Claude Code hasn't opened yet

## Executive Summary

The current `<leader>ac` command picker implementation in the Claude AI integration system has a critical timing synchronization issue. When users select commands from the picker before Claude Code has been opened, they receive a welcome message instead of proper command insertion. This report analyzes the current architecture and identifies solutions for robust command picker functionality independent of Claude Code's startup state.

## Problem Analysis

### Current Behavior
When `<leader>ac` is invoked before Claude Code has opened:
```
/cleanup╭───────────────────────────────────────────────────╮
│ ✻ Welcome to Claude Code!                         │
│                                                   │
│   /help for help, /status for your current setup  │
│                                                   │
│   cwd: /home/benjamin/.config                     │
╰───────────────────────────────────────────────────╯
```

### Root Cause
The command picker's `send_command_to_terminal()` function in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:277` has insufficient waiting logic for Claude Code initialization.

## Current Architecture Analysis

### Command Flow
```
<leader>ac (which-key.lua:L1)
    ↓
ClaudeCommands (init.lua:146)
    ↓
show_commands_picker() (picker.lua:860)
    ↓
send_command_to_terminal() (picker.lua:277)
```

### Key Components

#### 1. Command Registration
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:146`
```lua
vim.api.nvim_create_user_command("ClaudeCommands", M.show_commands_picker, {
  desc = "Browse Claude commands in hierarchical picker",
  nargs = 0,
})
```

#### 2. Keymap Definition
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
```lua
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
```

#### 3. Terminal Detection Logic
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:297-308`
```lua
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_valid(buf) and
     vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name:lower():match("claude") or buf_name:match("ClaudeCode") then
      claude_buf = buf
      claude_channel = vim.api.nvim_buf_get_option(buf, "channel")
      break
    end
  end
end
```

### Current Waiting Logic Limitations

The existing implementation has a basic retry mechanism but with several issues:

1. **Fixed retry count**: Limited to 10 attempts (picker.lua:331)
2. **Linear backoff**: Uses simple multiplication instead of exponential backoff
3. **No event-based waiting**: Relies on polling instead of responding to events
4. **Race conditions**: Terminal may exist but not be ready for input

## Autocommand Patterns in Codebase

### Terminal-Specific Autocommands
**File**: `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua:46-80`

The codebase already has sophisticated terminal handling:
```lua
api.nvim_create_autocmd({ "TermOpen" }, {
  pattern = { "term://*" },
  callback = function(ev)
    set_terminal_keymaps()

    local bufname = vim.api.nvim_buf_get_name(ev.buf)

    -- For Claude Code, use additional suppression
    if bufname:match("claude%-code") or bufname:match("ClaudeCode") then
      -- Clear any messages immediately and after a short delay
      vim.defer_fn(function()
        vim.cmd([[silent! echo ""]])
        vim.cmd([[silent! redraw!]])
      end, 1)
    end
  end,
})
```

This demonstrates the pattern for Claude Code-specific terminal detection and handling.

## Recommended Solution Architecture

### 1. Event-Driven Command Queue

Implement an autocommand-based system that:
- Queues commands when Claude Code isn't ready
- Automatically executes queued commands when Claude Code becomes available
- Provides immediate feedback to users about command status

### 2. Autocommand Implementation Pattern

```lua
-- Global command queue
local pending_commands = {}

-- AutoCommand to detect Claude Code readiness
vim.api.nvim_create_autocmd({ "TermOpen" }, {
  pattern = "term://*",
  callback = function(ev)
    local bufname = vim.api.nvim_buf_get_name(ev.buf)
    if bufname:match("claude%-code") or bufname:match("ClaudeCode") then
      -- Claude Code opened - process pending commands
      process_pending_commands(ev.buf)
    end
  end,
})

-- Enhanced buffer detection for existing Claude Code instances
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "term://*",
  callback = function(ev)
    if is_claude_code_buffer(ev.buf) and #pending_commands > 0 then
      process_pending_commands(ev.buf)
    end
  end,
})
```

### 3. State Machine Approach

Implement a three-state system:
1. **WAITING**: Claude Code not detected, queue commands
2. **READY**: Claude Code available, execute immediately
3. **BUSY**: Claude Code processing, queue additional commands

### 4. User Feedback Integration

Enhance the notification system to provide:
- Immediate feedback when commands are queued
- Status updates when Claude Code opens
- Confirmation when queued commands execute

## Technical Implementation Details

### Enhanced Detection Logic

Improve terminal detection with multiple validation layers:

```lua
local function validate_claude_terminal(buf)
  -- Check buffer validity
  if not vim.api.nvim_buf_is_valid(buf) then return false end

  -- Check buffer type
  if vim.api.nvim_buf_get_option(buf, "buftype") ~= "terminal" then return false end

  -- Check buffer name patterns
  local bufname = vim.api.nvim_buf_get_name(buf)
  if not (bufname:match("claude%-code") or bufname:match("ClaudeCode")) then return false end

  -- Check if terminal is responsive
  local channel = vim.api.nvim_buf_get_option(buf, "channel")
  if not channel or channel == 0 then return false end

  return true, channel
end
```

### Command Queue Management

```lua
local function queue_command(command_text)
  table.insert(pending_commands, {
    command = command_text,
    timestamp = os.time(),
    source = "picker"
  })

  notify.editor(
    string.format("Queued command '%s' - Claude Code will open automatically", command_text),
    notify.categories.STATUS,
    { command = command_text, queued = true }
  )
end
```

### Robust Command Execution

```lua
local function execute_command_safely(command_text, channel)
  -- Multiple execution strategies
  local strategies = {
    function() vim.api.nvim_chan_send(channel, command_text) end,
    function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("i" .. command_text, true, false, true),
        'n', false
      )
    end
  }

  for _, strategy in ipairs(strategies) do
    local success = pcall(strategy)
    if success then return true end
  end

  return false
end
```

## Integration Points

### 1. Modify Command Picker
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
- Replace polling logic with event-driven approach
- Add command queueing capabilities
- Enhance user feedback

### 2. Extend Autocommands
**File**: `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua`
- Add Claude Code readiness detection
- Implement command queue processing

### 3. Update Initialization
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua`
- Initialize command queue system
- Set up autocommand handlers

## Testing Strategy

### 1. Scenario Testing
- Command picker before Claude Code opens
- Command picker after Claude Code opens
- Multiple queued commands
- Claude Code restart scenarios

### 2. Edge Cases
- Claude Code crashes during command execution
- Multiple Claude Code instances
- Terminal buffer recreation
- Plugin reload scenarios

## Performance Considerations

### 1. Memory Management
- Implement command queue size limits
- Add automatic cleanup of old queued commands
- Monitor autocommand overhead

### 2. Responsiveness
- Minimize autocommand execution time
- Use vim.schedule_wrap for heavy operations
- Implement debouncing for rapid events

## Migration Path

### Phase 1: Core Infrastructure
1. Implement command queue system
2. Add basic autocommand handlers
3. Enhance terminal detection logic

### Phase 2: Integration
1. Modify picker.lua to use new system
2. Update user feedback mechanisms
3. Add configuration options

### Phase 3: Enhancement
1. Implement advanced queueing features
2. Add comprehensive error handling
3. Optimize performance

## Conclusion

The current command picker timing issue can be resolved through an event-driven architecture using Neovim's autocommand system. The proposed solution provides robust functionality independent of Claude Code's startup state while maintaining the existing user interface and improving the overall user experience.

The implementation leverages existing patterns in the codebase (particularly the terminal handling in autocmds.lua) and extends them to provide sophisticated command synchronization capabilities.

## References

### Primary Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` - Command picker implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua` - Main integration module
- `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua` - Autocommand patterns
- `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua` - Keymap definitions
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - Which-key integration

### Related Systems
- Terminal management and detection
- Notification system integration
- Session state synchronization
- Plugin initialization lifecycle