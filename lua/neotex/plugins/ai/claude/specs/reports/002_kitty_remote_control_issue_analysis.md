# Kitty Terminal Remote Control Issue Analysis

## Metadata
- **Date**: 2025-09-29
- **Scope**: Kitty terminal tab management failure analysis
- **Primary Directory**: /home/benjamin/.config/nvim/lua/neotex/ai-claude
- **Files Analyzed**: terminal-detection.lua, terminal-commands.lua, worktree.lua
- **Environment**: Kitty 0.37.0 on NixOS

## Executive Summary
The worktree system is correctly detecting Kitty terminal via environment variables but cannot create new tabs because Kitty's remote control feature is not enabled. The issue is that `allow_remote_control` is not set in the Kitty configuration, preventing the `kitten @` commands from working.

## Problem Analysis

### Current Behavior
1. **Detection Working**: Terminal detection correctly identifies Kitty via `KITTY_PID` and `KITTY_WINDOW_ID`
2. **Remote Control Disabled**: No `KITTY_LISTEN_ON` environment variable set
3. **Tab Creation Failing**: `kitten @ launch` commands fail silently
4. **Fallback Working**: Creates worktree but falls back to current window instead of new tab

### Environment Analysis
Current environment variables show Kitty is running but remote control is disabled:
```bash
KITTY_PID=53518
KITTY_WINDOW_ID=1
KITTY_SHELL_INTEGRATION=no-rc enabled
TERM=xterm-256color
KITTY_LISTEN_ON=''  # ← Missing/empty
```

## Root Cause Investigation

### 1. Missing Kitty Configuration
**Issue**: `/home/benjamin/.config/kitty/kitty.conf` lacks remote control configuration
**Required**: `allow_remote_control yes` directive

### 2. Detection Module Behavior
The terminal detection module at `terminal-detection.lua:22` correctly detects Kitty:
```lua
if vim.env.KITTY_LISTEN_ON or vim.env.KITTY_PID or vim.env.KITTY_WINDOW_ID then
  detected_terminal = 'kitty'
  return detected_terminal
end
```

### 3. Command Generation Working
The terminal commands module generates correct `kitten @` syntax:
```lua
function M.spawn_tab(worktree_path, command)
  -- ...
  elseif terminal == 'kitty' then
    return string.format(
      "kitten @ launch --type=tab --cwd='%s' --title='%s' %s",
      worktree_path,
      vim.fn.fnamemodify(worktree_path, ':t'),
      command or 'nvim CLAUDE.md'
    )
  end
```

## Technical Details

### Kitty Remote Control Requirements
Based on Kitty documentation research:

1. **Configuration Required**: `allow_remote_control yes` in `kitty.conf`
2. **Socket Creation**: Kitty creates listening socket when remote control enabled
3. **Environment Variable**: `KITTY_LISTEN_ON` set to socket path
4. **Security Model**: Socket-based authentication for remote commands

### Alternative Configuration Methods
1. **Persistent**: Add `allow_remote_control yes` to `kitty.conf`
2. **Temporary**: Start Kitty with `kitty -o allow_remote_control=yes`
3. **Socket-based**: Use `--listen-on unix:/tmp/kitty_socket` for specific socket
4. **Selective**: Enable per-window with shortcuts

### Current Command Flow
1. User presses `<leader>aw`
2. Worktree module calls `_spawn_terminal_tab()`
3. Terminal detection returns 'kitty'
4. Command generation creates `kitten @ launch --type=tab ...`
5. **Command fails** (remote control disabled)
6. System falls back to current window
7. Worktree created successfully but no new tab

## Impact Assessment

### What's Working
- ✅ Terminal detection (correctly identifies Kitty)
- ✅ Command generation (creates valid `kitten @` syntax)
- ✅ Fallback mechanism (creates worktree in current window)
- ✅ Error handling (graceful degradation)

### What's Broken
- ❌ Tab creation (remote control disabled)
- ❌ Tab switching (requires remote control)
- ❌ Tab management (close, activate, title setting)

### User Experience Impact
- **Moderate**: Core functionality works (worktree creation) but UX degraded
- **Misleading**: Success message implies tab creation when it didn't happen
- **Workflow**: Users must manually create tabs or switch configuration

## Recommendations

### Immediate Fix (User Action Required)
Add to `/home/benjamin/.config/kitty/kitty.conf`:
```conf
allow_remote_control yes
```

Then restart Kitty or reload configuration.

### Enhanced Detection (Code Improvement)
Update `terminal-detection.lua` to check for remote control capability:
```lua
function M.supports_tabs()
  local terminal = M.detect()
  if terminal == 'kitty' then
    -- Check if remote control is actually enabled
    return vim.env.KITTY_LISTEN_ON and vim.env.KITTY_LISTEN_ON ~= ''
  elseif terminal == 'wezterm' then
    return true  -- WezTerm doesn't require special config
  end
  return false
end
```

### Better User Feedback
Update error messages to be more specific:
```lua
if terminal == 'kitty' and not vim.env.KITTY_LISTEN_ON then
  notify.editor(
    "Kitty remote control disabled. Add 'allow_remote_control yes' to kitty.conf",
    notify.categories.ERROR,
    {
      solution = "Edit ~/.config/kitty/kitty.conf",
      required_setting = "allow_remote_control yes"
    }
  )
```

### Documentation Update
Update implementation plan and README to document Kitty configuration requirements.

## Testing Protocol

### Verification Steps
1. **Check config**: `grep allow_remote_control ~/.config/kitty/kitty.conf`
2. **Check environment**: `echo $KITTY_LISTEN_ON`
3. **Test command**: `kitten @ ls` (should list windows/tabs)
4. **Test tab creation**: `kitten @ launch --type=tab`

### Expected Results After Fix
- `KITTY_LISTEN_ON` should be set to socket path
- `kitten @ ls` should return JSON data
- `<leader>aw` should create new tab with worktree

## References

### Files Examined
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/utils/terminal-detection.lua:22`
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/utils/terminal-commands.lua:162`
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/core/worktree.lua:252`

### External Documentation
- [Kitty Remote Control Documentation](https://sw.kovidgoyal.net/kitty/remote-control/)
- [Launch Command Reference](https://sw.kovidgoyal.net/kitty/launch/)
- [Configuration Options](https://sw.kovidgoyal.net/kitty/conf/)

### Related Implementation
- Terminal compatibility implementation: commit 44a2b59
- Implementation plan: `specs/plans/terminal-compatibility-worktree.md`
- Implementation summary: `specs/summaries/001_terminal_compatibility_implementation.md`