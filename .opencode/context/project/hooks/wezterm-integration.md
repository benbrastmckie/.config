# WezTerm Tab Integration

This document describes the WezTerm terminal integration for Claude Code, providing tab title updates and visual notifications.

## Overview

The integration enables:
- Task number display in WezTerm tab titles (e.g., `ProofChecker #792`)
- Amber highlighting for tabs awaiting Claude Code input
- Automatic notification clearing when the user views or responds

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ WezTerm Tab Title                                               │
│ "1 ProofChecker #792"                                           │
└─────────────────────────────────────────────────────────────────┘
                    ▲                           ▲
                    │                           │
         ┌─────────┴─────────┐       ┌─────────┴─────────┐
         │ OSC 7             │       │ OSC 1337          │
         │ file://host/path  │       │ SetUserVar=...    │
         └─────────┬─────────┘       └─────────┬─────────┘
                   │                           │
    ┌──────────────┴──────────┐    ┌──────────┴──────────────┐
    │ Shell / Neovim          │    │ Claude Code Hooks        │
    │                         │    │                          │
    │ Directory updates from  │    │ wezterm-task-number.sh   │
    │ shells and Neovim       │    │ wezterm-notify.sh        │
    │ autocmds                │    │ wezterm-clear-status.sh  │
    └─────────────────────────┘    └──────────────────────────┘
```

## Hook Files

### wezterm-notify.sh

**Path**: `.opencode/hooks/wezterm-notify.sh`
**Hook Event**: `Stop`
**Purpose**: Set amber tab notification when Claude awaits input

Sets `CLAUDE_STATUS=needs_input` via OSC 1337 to the pane TTY. The WezTerm `format-tab-title` handler reads this variable and applies amber background (#e5b566) to inactive tabs.

### wezterm-clear-status.sh

**Path**: `.opencode/hooks/wezterm-clear-status.sh`
**Hook Event**: `UserPromptSubmit`
**Purpose**: Clear notification when user submits a prompt

Clears `CLAUDE_STATUS` by setting it to an empty value, restoring normal tab appearance.

### wezterm-task-number.sh

**Path**: `.opencode/hooks/wezterm-task-number.sh`
**Hook Event**: `UserPromptSubmit`
**Purpose**: Extract and display task number in tab title

Parses `CLAUDE_USER_PROMPT` environment variable for workflow patterns:
- `/research N`
- `/plan N`
- `/implement N`
- `/revise N`

**Behavior** (task 795):
- **Workflow command**: Sets `TASK_NUMBER` user variable to N
- **Non-workflow command**: Clears `TASK_NUMBER` user variable
- **Claude output**: No change (preserves current state - no hook fires)

This ensures task numbers persist correctly during Claude's responses and tool executions, only changing when the user submits a new prompt.

## User Variables

| Variable | Purpose | Values |
|----------|---------|--------|
| `TASK_NUMBER` | Task number for tab title | Numeric string (e.g., "792") |
| `CLAUDE_STATUS` | Notification state | "needs_input" or empty |

## Configuration

### Disabling Notifications

Set environment variable before starting Claude Code:

```bash
export WEZTERM_NOTIFY_ENABLED=0
```

### Hook Registration

Hooks are registered in `.opencode/settings.json`:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .opencode/hooks/wezterm-notify.sh 2>/dev/null || echo '{}'"
      }]
    }],
    "UserPromptSubmit": [{
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "bash .opencode/hooks/wezterm-task-number.sh 2>/dev/null || echo '{}'"
        },
        {
          "type": "command",
          "command": "bash .opencode/hooks/wezterm-clear-status.sh 2>/dev/null || echo '{}'"
        }
      ]
    }]
  }
}
```

## Technical Details

### TTY Access Pattern

Claude Code hooks run with redirected stdio (stdout is a socket to Claude). To emit OSC sequences visible to WezTerm, hooks must write directly to the pane's TTY:

```bash
# Get TTY path via WezTerm CLI
PANE_TTY=$(wezterm cli list --format=json | \
  jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tty_name")

# Write escape sequence to TTY
printf '\033]1337;SetUserVar=NAME=base64value\007' > "$PANE_TTY"
```

### OSC Escape Sequence Format

| Sequence | Format | Purpose |
|----------|--------|---------|
| OSC 7 | `ESC ] 7 ; file://hostname/path BEL` | Directory update |
| OSC 1337 | `ESC ] 1337 ; SetUserVar=name=base64value BEL` | User variable |

Values are base64-encoded in OSC 1337 to handle special characters safely.

### WezTerm Handler Location

The `format-tab-title` and `update-status` handlers that consume these variables are in `~/.dotfiles/config/wezterm.lua`.

## Integration with Neovim

When Claude Code runs inside Neovim (via claude-code.nvim), the Neovim autocmds in `~/.config/nvim/lua/neotex/config/autocmds.lua` provide complementary integration:

- **OSC 7**: Neovim emits directory updates on DirChanged, VimEnter, BufEnter
- **Task Number**:
  - **Shell hook**: Handles set/clear logic on `UserPromptSubmit` (workflow vs non-workflow)
  - **Neovim monitor**: Only clears TASK_NUMBER when Claude terminal closes

This separation (task 795) ensures:
1. Task numbers persist during Claude's responses (no buffer monitoring)
2. Task numbers clear correctly on non-workflow commands (shell hook handles)
3. Task numbers clear when terminal closes (Neovim autocmd handles)

## Related Documentation

- **WezTerm configuration**: `~/.dotfiles/docs/terminal.md`
- **Neovim integration**: `~/.config/nvim/lua/neotex/config/README.md`
- **Hook source files**: `.opencode/hooks/wezterm-*.sh`
