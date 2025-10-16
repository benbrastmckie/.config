# Claude Keymaps Restoration Analysis

## Metadata
- **Date**: 2025-09-30
- **Scope**: Analysis of current Claude Code keymaps and restoration requirements
- **Primary Directory**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/`
- **Files Analyzed**: 8 core files including keymaps, which-key, and Claude modules
- **Reference Report**: `007_original_claude_functionality_vs_current_analysis.md`

## Executive Summary

The Claude Code `<leader>a` keymaps are partially configured in which-key but several referenced commands are not being created due to incomplete module initialization. The original three-option menu functionality documented in report 007 is missing, and some commands reference functions that don't exist or aren't properly exposed.

**Current Status:**
- ✅ Which-key configuration exists for `<leader>a` Claude mappings
- ❌ Several commands (`ClaudeSessions`, `ClaudeWorktree`, `ClaudeRestoreWorktree`) not available
- ❌ Three-option smart toggle menu missing
- ❌ Visual selection with prompt function missing
- ✅ `ClaudeCommands` working (basic command picker)

## Current Which-Key Configuration Analysis

### Existing `<leader>a` Claude Mappings

From `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:154-169`:

```lua
-- Claude AI commands
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
{ "<leader>ac",
  function() require("neotex.plugins.ai.claude.core.visual").send_visual_to_claude_with_prompt() end,
  desc = "send selection to claude with prompt",
  mode = { "v" },
  icon = "󰘳"
},
{ "<leader>as", function() require("neotex.plugins.ai.claude").resume_session() end, desc = "claude sessions", icon = "󰑐" },
{ "<leader>av", "<cmd>ClaudeSessions<CR>", desc = "view worktrees", icon = "󰔡" },
{ "<leader>aw", "<cmd>ClaudeWorktree<CR>", desc = "create worktree", icon = "󰘬" },
{ "<leader>ar", "<cmd>ClaudeRestoreWorktree<CR>", desc = "restore closed worktree", icon = "󰑐" },
```

### Issues Identified

#### 1. Missing Commands
The following commands are referenced but not available:
- `ClaudeSessions` - Should open session browser
- `ClaudeWorktree` - Should create new worktree with Claude session
- `ClaudeRestoreWorktree` - Should restore closed worktree

**Root Cause**: These commands are defined in `ui_handlers.create_commands()` but this function is only called during worktree module setup, which may not be happening properly.

#### 2. Missing Function
```lua
require("neotex.plugins.ai.claude.core.visual").send_visual_to_claude_with_prompt()
```

**Root Cause**: This function doesn't exist in the current visual.lua module. Available functions are:
- `send_visual_to_claude()`
- `send_visual_with_prompt()`
- `send_buffer_to_claude()`

#### 3. Duplicate `<leader>ac` Mapping
The normal mode and visual mode mappings both use `<leader>ac`, which will conflict.

## Detailed Analysis

### Available Commands Status

| Command | Status | Location | Issue |
|---------|--------|----------|-------|
| `ClaudeCommands` | ✅ Working | `claude/init.lua:162` | None |
| `ClaudeSessions` | ❌ Missing | `worktree/ui_handlers.lua:274` | Not created - module not initialized |
| `ClaudeWorktree` | ❌ Missing | `worktree/ui_handlers.lua:246` | Not created - module not initialized |
| `ClaudeRestoreWorktree` | ❌ Missing | `worktree/ui_handlers.lua:286` | Not created - module not initialized |
| `ClaudeSendVisual` | ✅ Working | `core/visual.lua:194` | Available but not used in keymaps |
| `ClaudeSendVisualPrompt` | ✅ Working | `core/visual.lua:200` | Available but not used in keymaps |
| `ClaudeSendBuffer` | ✅ Working | `core/visual.lua:206` | Available but not used in keymaps |

### Module Initialization Analysis

The worktree module should be initialized in `claude/init.lua:149-151`:

```lua
if claude_worktree.setup then
  claude_worktree.setup(opts and opts.worktree or {})
end
```

However, the worktree setup function in `core/worktree/index.lua:115-124` calls `ui_handlers.create_commands()` which should create the missing commands.

**Investigation needed**: Check if the Claude module setup is actually being called during Neovim initialization.

### Missing Three-Option Menu

The original functionality (from report 007) included a three-option menu for `<C-c>`:
1. "Restore previous session (X ago)"
2. "Create new session"
3. "Browse all sessions"

**Current behavior**: Only focuses existing Claude Code window or shows simple session picker.

**Required restoration**: Implement the original `show_session_picker()` function with Telescope-based three-option interface.

## Recommendations

### Priority 1: Fix Missing Commands (High Impact, Low Effort)

#### 1.1 Verify Module Initialization
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua`

Ensure the Claude module is being properly initialized during Neovim startup. Check:
- Is `setup()` being called from the plugin configuration?
- Are there any errors during worktree module initialization?

**Test**: Run `:lua require('neotex.plugins.ai.claude').setup()` manually and check if commands appear.

#### 1.2 Fix Function Name Mismatch
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:157`

**Current (broken)**:
```lua
require("neotex.plugins.ai.claude.core.visual").send_visual_to_claude_with_prompt()
```

**Fix to**:
```lua
require("neotex.plugins.ai.claude.core.visual").send_visual_with_prompt()
```

#### 1.3 Resolve Keymap Conflict
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:154-162`

**Current (conflicting)**:
```lua
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
{ "<leader>ac", function() ... end, desc = "send selection to claude with prompt", mode = { "v" }, icon = "󰘳" },
```

**Proposed solution**:
```lua
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
{ "<leader>aC", function() require("neotex.plugins.ai.claude.core.visual").send_visual_with_prompt() end, desc = "send selection to claude with prompt", mode = { "v" }, icon = "󰘳" },
```

### Priority 2: Restore Three-Option Menu (High Impact, Medium Effort)

#### 2.1 Implement Original `show_session_picker()`
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/session_manager.lua`

Add the three-option Telescope picker from the original implementation:

```lua
function M.show_three_option_picker()
  local has_recent_session = M.check_for_recent_session()
  local all_sessions = session_picker.get_sessions()
  local has_any_sessions = all_sessions and #all_sessions > 0

  local options = {
    {
      display = "Restore previous session" .. (age_text ~= "" and " (" .. age_text .. ")" or ""),
      value = "continue",
      icon = "󰊢",
      desc = "Resume your most recent Claude conversation"
    },
    {
      display = "Create new session",
      value = "new",
      icon = "󰈔",
      desc = "Begin a fresh Claude conversation"
    },
    {
      display = "Browse all sessions",
      value = "browse",
      icon = "󰑐",
      desc = "Open the full session browser"
    },
  }

  -- Implement Telescope picker with actions...
end
```

#### 2.2 Update `smart_toggle()` Logic
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/session_manager.lua:228-268`

**Current logic**: Simple session counting without user choice
**Required logic**: Three-option menu when sessions exist, proper toggle when Claude Code is open

```lua
function M.smart_toggle()
  local claude_buf = M.find_claude_terminal_buffer()

  if claude_buf then
    -- ACTUAL TOGGLE (not just focus)
    vim.cmd("ClaudeCode")  -- This should toggle closed
    return
  end

  -- Show three-option menu if sessions exist
  local has_recent_session = M.check_for_recent_session()
  local all_sessions = session_picker.get_sessions()
  local has_any_sessions = all_sessions and #all_sessions > 0

  if has_recent_session or has_any_sessions then
    M.show_three_option_picker()
  else
    -- No sessions, just start new
    vim.cmd("ClaudeCode")
    M.save_session_state()
  end
end
```

### Priority 3: Add Missing Keymaps (Medium Impact, Low Effort)

#### 3.1 Add Missing Session Management Keymaps
Based on the original functionality, consider adding:

```lua
-- Additional useful mappings
{ "<leader>at", function() require("neotex.plugins.ai.claude").smart_toggle() end, desc = "toggle claude", icon = "󰔡" },
{ "<leader>an", "<cmd>ClaudeSendBuffer<CR>", desc = "send buffer to claude", icon = "󰈙" },
{ "<leader>aS", "<cmd>ClaudeSessionCleanup<CR>", desc = "cleanup sessions", icon = "󰩺" },
```

### Priority 4: Simplification Opportunities (Low Impact, Medium Effort)

#### 4.1 Consolidate Visual Commands
The current visual.lua creates three separate commands, but only one is used in keymaps. Consider:
- Keep `ClaudeSendVisualPrompt` as the primary visual command
- Remove or deprecate the other two to reduce complexity

#### 4.2 Streamline Session Management
The worktree system has many commands that may not be necessary:
- `ClaudeSession` (switch) - could be integrated into `ClaudeSessions` browser
- `ClaudeSessionList` - redundant with `ClaudeSessions`
- `ClaudeSessionDelete` - could be integrated into browser

## Implementation Plan

### Phase 1: Quick Fixes (1-2 hours)
1. **Fix function name**: Change `send_visual_to_claude_with_prompt` to `send_visual_with_prompt`
2. **Fix keymap conflict**: Change visual mode mapping to `<leader>aC`
3. **Verify initialization**: Ensure Claude module setup is being called
4. **Test basic functionality**: Confirm `ClaudeCommands` works

### Phase 2: Command Restoration (2-3 hours)
1. **Debug worktree initialization**: Find why `ClaudeSessions`, `ClaudeWorktree`, `ClaudeRestoreWorktree` aren't created
2. **Fix module loading**: Ensure all command creation functions are called
3. **Test all commands**: Verify each `<leader>a` command works
4. **Update documentation**: Update which-key descriptions if needed

### Phase 3: Three-Option Menu (3-4 hours)
1. **Implement three-option picker**: Restore original Telescope-based menu
2. **Fix smart_toggle**: Implement proper toggle and menu logic
3. **Add session state persistence**: Restore automatic session saving
4. **Test complete workflow**: Verify `<C-c>` behavior matches original

### Phase 4: Optimization (1-2 hours)
1. **Remove redundant commands**: Consolidate session management
2. **Clean up visual commands**: Reduce to essential functions
3. **Update documentation**: Ensure README.md reflects current functionality

## Test Cases

### Critical Tests
1. **`<leader>ac`**: Opens Claude commands picker
2. **`<leader>aC`** (visual): Sends selection with prompt
3. **`<leader>as`**: Shows session picker
4. **`<leader>av`**: Opens session browser
5. **`<leader>aw`**: Creates new worktree
6. **`<leader>ar`**: Restores closed worktree
7. **`<C-c>` (no Claude)**: Shows three-option menu
8. **`<C-c>` (Claude open)**: Toggles Claude Code closed

### Regression Tests
1. **No sessions available**: Direct Claude Code opening
2. **Single session**: Appropriate restoration flow
3. **Multiple sessions**: Rich session browser
4. **Visual mode**: Proper text selection and sending

## Files Requiring Changes

### Required Changes
1. **`/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:157`** - Fix function name
2. **`/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:154-162`** - Resolve keymap conflict
3. **`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/session_manager.lua:228-268`** - Restore smart_toggle logic
4. **`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/session_manager.lua`** - Add three-option picker

### Investigation Required
1. **`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`** - Check if Claude module setup is called
2. **`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree/index.lua`** - Verify command creation

## References

### Key Files
- **Which-key config**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:154-169`
- **Claude init**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:149-151,162-165`
- **Session manager**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/session_manager.lua:228-268`
- **Visual module**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/visual.lua:194-212`
- **Worktree commands**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree/ui_handlers.lua:246-290`

### Related Documentation
- **Original functionality**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/specs/reports/007_original_claude_functionality_vs_current_analysis.md`
- **Keymaps reference**: `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua:297-313`

---

**Conclusion**: The Claude Code keymaps are mostly configured but missing critical command registration and the sophisticated three-option menu system. The fixes are straightforward for the basic functionality, but restoring the full original user experience will require implementing the three-option picker and proper session management flow that made the system intuitive and discoverable.
