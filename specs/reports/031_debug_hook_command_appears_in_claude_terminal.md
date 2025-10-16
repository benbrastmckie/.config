# Debug Report: Hook Command Appears in Claude Terminal

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 031
- **Issue**: SessionStart hook command appears as text in Claude terminal instead of executing in Neovim
- **Severity**: High
- **Type**: Debugging investigation
- **Related Reports**:
  - 028_claude_code_hooks_for_terminal_readiness.md
- **Related Plans**:
  - 018_refactor_to_hook_based_readiness_detection.md
- **Affected Files**:
  - `/home/benjamin/.config/nvim/scripts/claude-ready-signal.sh`

## Problem Statement

When Claude Code starts or resumes a session, the SessionStart hook fires and attempts to signal Neovim. However, instead of executing the Lua command in Neovim, the command appears as literal text in the Claude terminal:

```
> :lua require("neotex.plugins.ai.claude.utils.terminal-state").on_claude_ready()
```

This happens because `nvim --remote-send` sends keystrokes to the **active window**, which is the Claude terminal (since that's where the cursor is when the hook fires).

## Investigation Process

### Step 1: Understand --remote-send Behavior

`nvim --remote-send` sends keystrokes to the **currently focused window** in the target Neovim instance.

**When SessionStart hook fires**:
- User has just opened/resumed Claude
- Focus is in the Claude terminal window
- Terminal is in insert/terminal mode
- Keystrokes go to the terminal, not Neovim command mode

**Result**: The `:lua ...` command is typed as text into Claude's input prompt.

### Step 2: Check Hook Script

**File**: `~/.config/nvim/scripts/claude-ready-signal.sh`

```bash
#!/usr/bin/env bash
if [ -n "$NVIM" ]; then
  nvim --server "$NVIM" --remote-send \
    ':lua require("neotex.plugins.ai.claude.utils.terminal-state").on_claude_ready()<CR>'
fi
```

**Problem**: `--remote-send` sends raw keystrokes. If the active window is a terminal in insert mode, those keystrokes are sent to the terminal process, not to Neovim.

### Step 3: Understand Neovim Remote APIs

Neovim provides several remote command options:

1. **`--remote-send`**: Sends raw keystrokes to active window
   - Affected by window focus
   - Affected by current mode (insert/normal/terminal)
   - Goes to terminal if that's the focused window

2. **`--remote-expr`**: Evaluates Vimscript expression
   - Returns result to stdout
   - Not affected by window focus
   - Can't call Lua directly (needs vim.fn wrapper)

3. **`--remote`**: Opens file in existing instance
   - Not useful for our case

4. **`nvim --server $NVIM`**: Can be combined with RPC calls
   - More complex but more reliable

## Findings

### Root Cause

`--remote-send` sends keystrokes to wherever focus is. When SessionStart hook fires:

1. Claude terminal just opened/resumed
2. Focus is in terminal window
3. Terminal is in terminal-mode or insert-mode
4. `:lua ...` keystrokes go to Claude's input
5. User sees the command as text in Claude

### Why This Wasn't Caught in Testing

The SessionStart hook fires **during** Claude startup, when the terminal is still initializing. In testing:
- Fresh start: Terminal might not have captured focus yet, so command worked
- But when resuming sessions, terminal is already focused, command goes to wrong place

### Evidence

User reports:
> "Whenever I restore a claude session, I see '> :lua require(...)' "

This confirms:
- Happens on **session restore** (resume)
- Command appears as literal text with `> ` prompt
- Hook is firing, but command going to wrong place

## Proposed Solutions

### Solution 1: Escape Terminal Mode First (RECOMMENDED)

Send escape sequence before the command to ensure we're not in terminal mode:

```bash
#!/usr/bin/env bash
if [ -n "$NVIM" ]; then
  # Escape terminal mode, then execute command
  nvim --server "$NVIM" --remote-send \
    '<C-\\><C-n>:lua require("neotex.plugins.ai.claude.utils.terminal-state").on_claude_ready()<CR>'
fi
```

**How it works**:
- `<C-\><C-n>` escapes terminal mode to normal mode
- Then `:lua ...` executes in command mode
- Works regardless of which window has focus

**Pros**:
- Simple fix (add escape sequence)
- Works in all modes
- No API changes needed

**Cons**:
- Briefly flashes to normal mode (usually unnoticeable)
- Still sends to active window (but now we control the mode)

### Solution 2: Use --remote-expr with nvim_exec

Use `--remote-expr` to evaluate a Vimscript expression that calls Lua:

```bash
#!/usr/bin/env bash
if [ -n "$NVIM" ]; then
  nvim --server "$NVIM" --remote-expr \
    "luaeval('require(\"neotex.plugins.ai.claude.utils.terminal-state\").on_claude_ready()')"
fi
```

**Pros**:
- Not affected by window focus
- Executes in Neovim context, not terminal

**Cons**:
- More complex escaping
- `--remote-expr` expects return value (we don't have one)
- Might show error about nil return

### Solution 3: Use nvim RPC API

Call Neovim's RPC API directly using `nvim --server`:

```bash
#!/usr/bin/env bash
if [ -n "$NVIM" ]; then
  # This would require nvim to be in PATH and proper RPC setup
  # More complex, skip for now
fi
```

**Pros**:
- Most robust
- Proper API usage

**Cons**:
- Complex
- Overkill for this use case

### Solution 4: Use :call Instead of :lua

Send a Vimscript command instead:

```bash
#!/usr/bin/env bash
if [ -n "$NVIM" ]; then
  nvim --server "$NVIM" --remote-send \
    '<C-\\><C-n>:call luaeval("require(\"neotex.plugins.ai.claude.utils.terminal-state\").on_claude_ready()")<CR>'
fi
```

**Pros**:
- Works with `--remote-send`
- Escapes terminal mode first

**Cons**:
- More verbose than Solution 1
- Double escaping needed

## Recommendations

### Priority 1: Use Solution 1 (Escape Terminal Mode)

Simplest and most reliable fix:

1. Add `<C-\><C-n>` before the command
2. This escapes terminal mode to normal mode
3. Then `:lua` command executes in command line
4. Works regardless of focus

**Implementation**:
```bash
#!/usr/bin/env bash
if [ -n "$NVIM" ]; then
  nvim --server "$NVIM" --remote-send \
    '<C-\\><C-n>:lua require("neotex.plugins.ai.claude.utils.terminal-state").on_claude_ready()<CR>'
fi
```

**Note**: Backslash escaping - `<C-\\>` is needed because bash interprets `\` as escape character.

### Why This Works

**The escape sequence**:
- `<C-\>` + `<C-n>` is Neovim's terminal-mode escape
- Moves from terminal mode to normal mode
- Does nothing if already in normal mode (safe)
- Then `:lua` executes in command mode

**No matter what state**:
- Terminal mode → escape to normal → execute ✓
- Insert mode → `<C-\><C-n>` goes to normal → execute ✓
- Normal mode → already normal → execute ✓

## Implementation Steps

### Phase 1: Fix Hook Script

1. Edit `~/.config/nvim/scripts/claude-ready-signal.sh`
2. Add `<C-\\><C-n>` before `:lua` command
3. Test with session resume
4. Verify command no longer appears in terminal

### Phase 2: Test All Scenarios

1. Fresh start (new session)
2. Resume existing session
3. Multiple rapid commands
4. Verify no text appears in Claude terminal

## Testing Plan

### Test Scenario 1: Resume Session

```bash
# Start Claude, create some history
:ClaudeCode
# Type some commands
/plan test
# Exit Neovim
:qa

# Restart Neovim
nvim
# Resume session
:ClaudeCode
# Use --resume or let it restore automatically
```

**Before fix**: See `> :lua require(...)` in Claude terminal
**After fix**: No Lua command visible, hook executes silently

### Test Scenario 2: Fresh Start (Regression)

```bash
nvim
<leader>ac
# Select command
```

**Expected**: Still works, no visible command in Claude

### Test Scenario 3: Rapid Commands

```bash
:ClaudeCode
<leader>ac  # Command 1
<leader>ac  # Command 2
<leader>ac  # Command 3
```

**Expected**: No Lua commands visible, all commands inserted

## Alternative Approaches Considered

### Why Not Use vim.schedule?

Could we use `vim.schedule()` to defer execution? No, because the issue is in the **hook script**, not in Lua code. The script is executed by Claude Code, not Neovim.

### Why Not Change When Hook Fires?

Could we change the hook matcher to avoid firing during resume? No, because we **want** it to fire on resume - we just need it to execute correctly.

### Why Not Use Different Hook Type?

Could we use a different hook (like `Stop` or `UserPromptSubmit`)? No, because SessionStart is the correct time - we need to know when Claude is ready.

## Edge Cases

### Edge Case 1: User in Normal Mode

If user happens to be in normal mode when hook fires:
- `<C-\><C-n>` is a no-op (already in normal)
- `:lua` executes normally
- Works ✓

### Edge Case 2: User in Insert Mode

If user in insert mode in a different buffer:
- `<C-\><C-n>` goes to normal mode
- `:lua` executes
- User might notice brief mode change
- Acceptable ✓

### Edge Case 3: User in Visual Mode

If user in visual mode:
- `<C-\><C-n>` exits to normal mode
- Selection lost (minor inconvenience)
- Command executes ✓

### Edge Case 4: Hook Fires Multiple Times

If SessionStart fires multiple times (rapid restarts):
- `on_claude_ready()` flushes queue each time
- Empty queue = no-op
- Safe ✓

## Next Steps

1. **Implement Solution 1**: Add `<C-\\><C-n>` to hook script
2. **Test thoroughly**: All scenarios above
3. **Update Plan 018 summary**: Document this fix
4. **Consider**: Add comment in script explaining the escape sequence

## References

### Neovim Documentation
- `:help --remote-send` - Sends keystrokes to active window
- `:help --remote-expr` - Evaluates expression
- `:help terminal-mode` - Terminal mode escape sequence `<C-\><C-n>`

### Hook Script
- `/home/benjamin/.config/nvim/scripts/claude-ready-signal.sh` - Needs fix

### Code Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/utils/terminal-state.lua` - Callback function

### Related Reports
- [028_claude_code_hooks_for_terminal_readiness.md](../reports/028_claude_code_hooks_for_terminal_readiness.md) - Hook research

### Related Plans
- [018_refactor_to_hook_based_readiness_detection.md](../plans/018_refactor_to_hook_based_readiness_detection.md) - Hook implementation

## Conclusion

The issue is straightforward: `--remote-send` sends keystrokes to the active window, which is the Claude terminal. The Lua command appears as text in Claude instead of executing in Neovim.

**The fix is simple**: Add `<C-\\><C-n>` before the command to escape terminal mode first. This ensures the command executes in Neovim's command line, not in the terminal.

```bash
# Before (broken):
nvim --server "$NVIM" --remote-send ':lua ...<CR>'

# After (fixed):
nvim --server "$NVIM" --remote-send '<C-\\><C-n>:lua ...<CR>'
```

One character sequence fixes the entire issue!
