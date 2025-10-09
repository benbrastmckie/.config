# TTS Directory

Text-to-speech notification system for Claude Code workflows. Provides voice feedback for command completion and permission requests with uniform "directory, branch" messages.

## Purpose

The TTS system enables:

- **Voice notifications** for completion and permission events
- **Uniform messages** - all notifications say "directory, branch" (e.g., "config, master")
- **Single voice configuration** - consistent voice across all notifications
- **Non-intrusive operation** that never blocks workflow
- **Simple, predictable notifications** without verbose messages

## TTS Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Event                                           │
│ (Stop or Notification only)                                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Dispatcher Hook                                         │
│ (.claude/hooks/tts-dispatcher.sh)                          │
├─────────────────────────────────────────────────────────────┤
│ • Parses event JSON from stdin                              │
│ • Detects category (completion or permission)               │
│ • Checks if category enabled                                │
│ • Uses single unified voice parameters                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Message Generator                                           │
│ (.claude/tts/tts-messages.sh)                              │
├─────────────────────────────────────────────────────────────┤
│ • Extracts context (directory, branch)                      │
│ • Returns uniform "directory, branch" message               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Engine (espeak-ng)                                      │
├─────────────────────────────────────────────────────────────┤
│ • Speaks message asynchronously                             │
│ • Uses unified voice parameters (pitch:50 speed:160)        │
│ • Non-blocking execution                                    │
└─────────────────────────────────────────────────────────────┘
```

## Files

### tts-config.sh
**Purpose**: Configuration for all TTS settings

**Sections**:
- Global Settings (enabled, engine, voice)
- Category Enablement (2 categories: completion and permission)
- Voice Configuration (single unified voice parameters)
- Advanced Options (silent commands, debug)

**Key Variables**:
```bash
TTS_ENABLED=true                     # Master enable/disable
TTS_ENGINE="espeak-ng"               # TTS engine to use
TTS_VOICE="en-us+f3"                 # Default voice

# Category enable/disable (simplified to 2 categories)
TTS_COMPLETION_ENABLED=true          # Stop hook notifications
TTS_PERMISSION_ENABLED=true          # Notification hook (permission requests)

# Voice configuration (unified for all notifications)
TTS_VOICE_PARAMS="50:160"            # pitch:speed for all categories

# Silent commands (no TTS)
TTS_SILENT_COMMANDS="/clear /help /version /status /list /list-plans /list-reports /list-summaries"

# Debug logging
TTS_DEBUG=true
```

**Voice Parameters**:
- **Pitch**: 0-99 (0=lowest, 50=normal, 99=highest)
- **Speed**: Words per minute (120-220 typical range)

**Voice Selection**: Run `espeak-ng --voices` to see available voices
- `en-us+f3`: Female voice
- `en-us+m3`: Male voice

---

### tts-messages.sh
**Purpose**: Message generation library for all TTS categories

**Functions**:

#### Context Extraction
```bash
get_context_prefix()
# Returns: "[directory], [branch]"
# Example: "config, master"
```

#### Message Generators
```bash
generate_completion_message()
# Format: "[directory], [branch]"
# Example: "config, master"

generate_permission_message()
# Format: "[directory], [branch]" (identical to completion)
# Example: "config, master"
```

**Note**: All other message generators were removed in the simplified TTS system. Only completion and permission messages are supported.

#### Message Routing
```bash
generate_message() {
  local category="$1"
  case "$category" in
    completion) generate_completion_message ;;
    permission) generate_permission_message ;;
    *) echo "Notification." ;;
  esac
}
```

**Environment Variables Used**:
- `CLAUDE_PROJECT_DIR`: Project directory (from hook JSON)
- `HOOK_EVENT`: Hook event type (Stop or Notification)
- `CLAUDE_COMMAND`: Command being executed (optional)
- `CLAUDE_STATUS`: Command status (optional)

## Notification Categories

The simplified TTS system supports only 2 categories:

### 1. Completion
**Triggered By**: Stop hook when command completes

**Message**: `"directory, branch"` (e.g., "config, master")

**Voice**: Normal pitch and speed (50:160)

**Use Case**: Know when Claude is ready for next input

**Configuration**: `TTS_COMPLETION_ENABLED=true`

---

### 2. Permission
**Triggered By**: Notification hook when tool permission needed

**Message**: `"directory, branch"` (identical to completion)

**Voice**: Same as completion (50:160)

**Use Case**: Know when tool permission needed without verbose messages

**Configuration**: `TTS_PERMISSION_ENABLED=true`

---

## Removed Categories

The following categories were removed in the simplified TTS system:

- **Progress** (SubagentStop) - No longer supported
- **Error** - No longer supported (all Stop events use same message)
- **Idle** - No longer supported
- **Session** - No longer supported
- **Tool** - No longer supported
- **Prompt Acknowledgment** - No longer supported
- **Compact** - No longer supported

All events that aren't Stop or Notification are ignored by the TTS dispatcher.

## Configuration Guide

### Enable TTS
```bash
# Edit configuration
nvim .claude/tts/tts-config.sh

# Set master enable
TTS_ENABLED=true

# Enable categories (both default to true)
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
```

### Customize Voice
```bash
# Unified voice configuration (applies to all notifications)
TTS_VOICE_PARAMS="50:160"  # pitch:speed

# Examples:
TTS_VOICE_PARAMS="35:140"  # Lower, slower (calmer)
TTS_VOICE_PARAMS="60:180"  # Higher, faster (more urgent)

# Change voice gender
TTS_VOICE="en-us+m3"  # Male voice
TTS_VOICE="en-us+f3"  # Female voice (default)
```

### Add Silent Commands
```bash
# Commands that don't need TTS notifications
TTS_SILENT_COMMANDS="/clear /help /version /status /list"
```

### Enable Debug Logging
```bash
TTS_DEBUG=true
# Logs to .claude/data/logs/tts.log and .claude/data/logs/hook-debug.log
```

## Testing TTS

### Test TTS Engine
```bash
# Check if espeak-ng installed
command -v espeak-ng

# Test basic speech
espeak-ng "Hello world"

# Test with voice parameters
espeak-ng -v en-us+f3 -s 160 -p 50 "Claude ready"
```

### Test Message Generation
```bash
# Source message library
source .claude/tts/tts-messages.sh

# Set environment variables
export CLAUDE_PROJECT_DIR="/home/user/project"
export CLAUDE_COMMAND="/implement"
export CLAUDE_STATUS="success"
export HOOK_EVENT="Stop"

# Generate message
generate_message "completion"
```

### Test Full TTS Flow
```bash
# Simulate Stop event
echo '{"hook_event_name":"Stop","command":"/test","status":"success","cwd":"'$(pwd)'"}' | \
  .claude/hooks/tts-dispatcher.sh

# Check TTS log
tail .claude/data/logs/tts.log
```

### Monitor TTS Activity
```bash
# Watch TTS log in real-time
tail -f .claude/data/logs/tts.log

# Watch hook debug log
tail -f .claude/data/logs/hook-debug.log
```

## Extending TTS

The simplified TTS system uses a uniform approach. To add custom behavior:

### Customize Messages

Edit `.claude/tts/tts-messages.sh` to modify the `get_context_prefix()` function:

```bash
get_context_prefix() {
  local dir_name=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
  local branch=$(git -C "${CLAUDE_PROJECT_DIR:-$(pwd)}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-branch")

  # Add custom logic here
  echo "$dir_name, $branch"
}
```

### Add New Hook Event

If you want to support additional hook events (beyond Stop and Notification):

1. **Update dispatcher** - Edit `.claude/hooks/tts-dispatcher.sh`:
   ```bash
   detect_category() {
     case "$event" in
       Stop) echo "completion" ;;
       Notification) echo "permission" ;;
       MyEvent) echo "completion" ;;  # Use existing category
       *) return 1 ;;
     esac
   }
   ```

2. **Register hook** - Edit `.claude/settings.local.json`:
   ```json
   {
     "hooks": {
       "MyEvent": [{
         "matcher": ".*",
         "hooks": [{"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"}]
       }]
     }
   }
   ```

**Note**: The simplified system uses the same message and voice for all events. If you need different messages or voices, consider using the original multi-category system.

## Troubleshooting

### No TTS Output

**Check 1: TTS Enabled**
```bash
grep "TTS_ENABLED" .claude/tts/tts-config.sh
# Should be: TTS_ENABLED=true
```

**Check 2: Category Enabled**
```bash
grep "TTS_COMPLETION_ENABLED" .claude/tts/tts-config.sh
# Should be: TTS_COMPLETION_ENABLED=true
```

**Check 3: espeak-ng Installed**
```bash
command -v espeak-ng || echo "Not installed"
```

**Check 4: Hook Registered**
```bash
cat .claude/settings.local.json | jq '.hooks.Stop'
# Should show tts-dispatcher.sh
```

### TTS Not Working for Specific Events

**Check Event Parsing**
```bash
tail .claude/data/logs/hook-debug.log
# Look for: EVENT=Stop CMD=/implement STATUS=success
```

**Check Category Detection**
```bash
# Add debug to detect_category() in tts-dispatcher.sh
echo "[DEBUG] Detected category: $category" >> "$CLAUDE_DIR/logs/tts.log"
```

### Voice Sounds Wrong

**Check Voice Parameters**
```bash
grep "TTS_COMPLETION_VOICE" .claude/tts/tts-config.sh
```

**Test Voice Manually**
```bash
espeak-ng -v en-us+f3 -s 160 -p 50 "Test message"
```

**Try Different Voice**
```bash
espeak-ng --voices  # List available voices
TTS_VOICE="en-us+m3"  # Try male voice
```

## Performance

### TTS Overhead
- **Async execution**: No workflow blocking
- **Typical latency**: < 100ms to start speaking
- **Resource usage**: Minimal CPU/memory

### Optimization
- **Silent commands**: Skip TTS for fast, frequent commands
- **Category selection**: Disable verbose categories
- **Message length**: Keep messages concise

## Neovim Integration

TTS system files are integrated with the Neovim artifact picker for easy access and editing.

### Accessing TTS Files via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [TTS Files] section in picker

### Picker Features for TTS Files

**Visual Display**:
- TTS configuration and scripts organized by role
- Local files marked with `*` prefix
- File descriptions from script headers
- Role indicators ([config], [dispatcher], etc.)

**Display Format**:
```
[TTS Files]                   Text-to-speech system files

* ├─ [config] tts-config.sh    (tts) 15L
  └─ [dispatcher] tts-dispatcher.sh (hooks) 42L
```

**Quick Actions**:
- `<CR>` - Open TTS file for editing
- `<C-l>` - Load TTS file locally to project
- `<C-g>` - Update from global version
- `<C-s>` - Save local file to global
- `<C-e>` - Edit file in buffer
- `<C-u>`/`<C-d>` - Scroll preview up/down

**Example Workflow**:
```vim
" Open picker
:ClaudeCommands

" Navigate to [TTS Files] category
" Select tts-config.sh
" Press <C-e> to edit configuration
" Modify TTS_ENABLED or voice settings
```

### TTS File Organization

The picker displays TTS files from two locations:

1. **`tts/` directory**: Core TTS configuration
   - `tts-config.sh` - Master configuration
   - `tts-messages.sh` - Message generators

2. **`hooks/` directory**: TTS integration scripts
   - `tts-dispatcher.sh` - Hook dispatcher

All TTS-related files appear together in the [TTS Files] category for convenient access.

### Quick Configuration Toggle

For quick TTS toggling in Neovim:

```vim
" Toggle TTS (project-specific)
<leader>at

" This edits .claude/tts/tts-config.sh
" Use picker for detailed configuration
```

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Documentation Standards

All TTS documentation follows standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

## Navigation

### TTS Files
- [tts-config.sh](tts-config.sh) - Configuration
- [tts-messages.sh](tts-messages.sh) - Message generators

### Related
- [← Parent Directory](../README.md)
- [hooks/](../hooks/README.md) - TTS dispatcher hook
- [docs/tts-integration-guide.md](../docs/tts-integration-guide.md) - Integration guide
- [docs/tts-message-examples.md](../docs/tts-message-examples.md) - Message examples
- [logs/](../logs/README.md) - TTS logs

### Configuration
- [settings.local.json](../settings.local.json) - Hook registration

## Quick Reference

### Essential Settings
```bash
# Enable TTS
TTS_ENABLED=true

# Categories (simplified to 2)
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true

# Voice customization (unified)
TTS_VOICE="en-us+f3"
TTS_VOICE_PARAMS="50:160"
```

### Debug Commands
```bash
# Test TTS
espeak-ng "Test message"

# Check TTS log
tail -f .claude/data/logs/tts.log

# Manual message test
source .claude/tts/tts-messages.sh && generate_completion_message
```

### Common Configurations

**Both Categories (Default)**:
```bash
TTS_ENABLED=true
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_VOICE_PARAMS="50:160"
```

**Only Completion**:
```bash
TTS_ENABLED=true
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=false
TTS_VOICE_PARAMS="50:160"
```

**Only Permission Requests**:
```bash
TTS_ENABLED=true
TTS_COMPLETION_ENABLED=false
TTS_PERMISSION_ENABLED=true
TTS_VOICE_PARAMS="50:160"
```
