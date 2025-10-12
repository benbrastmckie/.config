# TTS Message Examples

Complete reference of TTS message templates for the simplified 2-category system.

## Uniform Message Format

**All TTS notifications use the same format:**
```
[directory], [branch]
```

The comma provides a natural pause between directory and branch name.

**Examples:**
```
"config, master"
"neovim, feature-refactor"
"nice_connectives, main"
"dotfiles, master"
```

This uniform format applies to **both** completion and permission notifications.

## Completion Messages

**Trigger**: Stop hook when Claude completes a task

**Format**: `"directory, branch"`

**Examples**:
```
"config, master"           # .config directory on master branch
"neovim, feature-vim"      # neovim directory on feature-vim branch
"backend, develop"         # backend directory on develop branch
"nice_connectives, main"   # nice_connectives directory on main branch
```

**Purpose**:
- Identifies which session is ready for input
- Minimal, non-verbose announcement
- Instant branch awareness
- Uses root directory name (not full path)

## Permission Messages

**Trigger**: Notification hook when tool permission needed

**Format**: `"directory, branch"` (identical to completion)

**Examples**:
```
"config, master"           # Permission needed in .config on master
"neovim, feature-vim"      # Permission needed in neovim on feature-vim
"backend, develop"         # Permission needed in backend on develop
"nice_connectives, main"   # Permission needed in nice_connectives on main
```

**Purpose**:
- Same minimal format as completion messages
- Know which directory/branch needs attention
- No verbose "Permission needed. Tool." messages
- Consistent, predictable notifications

## Removed Categories

The following message categories were removed in the simplified TTS system:

- **Progress Updates** - No longer supported
- **Error Notifications** - No longer supported
- **Idle Reminders** - No longer supported
- **Session Messages** - No longer supported
- **Tool Execution** - No longer supported
- **Prompt Acknowledgment** - No longer supported
- **Compact Operations** - No longer supported

Only Stop (completion) and Notification (permission) events generate TTS messages.

## Customizing Messages

### Method: Edit Message Generator

Edit `.claude/tts/tts-messages.sh` to customize templates:

```bash
# Find the generate_completion_message function
# Add custom logic for your command:

case "$command" in
  *mycustom*)
    message="$message My custom completion message."
    ;;
esac
```

## Voice Characteristics Reference

Different categories have distinct voices to help identify notification type without listening to full message:

| Category | Pitch | Speed | Character |
|----------|-------|-------|-----------|
| Completion | 50 | 160 | Normal, clear |
| Permission | 60 | 180 | Urgent, higher |
| Progress | 40 | 180 | Background, quick |
| Error | 35 | 140 | Alert, slower |
| Idle | 50 | 140 | Gentle, calm |
| Session | 50 | 160 | Normal, clear |
| Tool | 30 | 200 | Minimal, very quick |
| Prompt Ack | 70 | 220 | Quick confirm |
| Compact | 50 | 160 | Normal, clear |

## Testing Messages

Test messages by sending JSON to the dispatcher:

```bash
# Test completion notification
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh

# Test permission request
echo '{"hook_event_name":"Notification","message":"Permission needed"}' | bash .claude/hooks/tts-dispatcher.sh

# Test error notification
echo '{"hook_event_name":"Stop","status":"error","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh

# Test session start
echo '{"hook_event_name":"SessionStart","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
```
