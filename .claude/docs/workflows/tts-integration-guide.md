# TTS Integration Guide

Comprehensive guide for Claude Code text-to-speech notification system.

## Overview

The TTS integration provides voice feedback for Claude Code workflow events. The system uses a simplified 2-category approach with uniform "directory, branch" messages, allowing you to stay informed about workflow progress without constantly monitoring the terminal.

### Key Features

- **2 Notification Categories**: Completion and permission requests only
- **Uniform Messages**: All notifications say "directory, branch" (e.g., "config, master")
- **Single Voice Configuration**: Consistent voice across all notifications
- **Configurable**: Enable/disable categories individually
- **Non-intrusive**: Async execution, never blocks workflow
- **Minimal**: Simple, predictable notifications without verbose messages

### Design Philosophy

1. **Non-intrusive**: TTS runs asynchronously, never blocking workflow
2. **Minimal**: Simple "directory, branch" format, no verbose messages
3. **Uniform**: Same message and voice for all notification types
4. **Configurable**: Enable/disable categories independently
5. **Context-aware**: Messages identify which directory/branch is ready
6. **Predictable**: Consistent behavior across all events

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Hook Events                                     │
├─────────────────────────────────────────────────────────────┤
│  Stop, SessionStart/End, SubagentStop, Notification         │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Dispatcher (.claude/hooks/tts-dispatcher.sh)            │
├─────────────────────────────────────────────────────────────┤
│  • Event categorization                                     │
│  • Category enable/disable check                            │
│  • Message generation routing                               │
│  • Voice parameter selection                                │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│ Message Generator (.claude/tts/tts-messages.sh)             │
├─────────────────────────────────────────────────────────────┤
│  • Context extraction (directory, branch)                   │
│  • Command-specific message templates                       │
│  • State file reading (optional)                            │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Engine (espeak-ng)                                      │
├─────────────────────────────────────────────────────────────┤
│  • Speech synthesis with voice parameters                   │
│  • Async audio output                                       │
└─────────────────────────────────────────────────────────────┘
```

## Notification Categories

### 1. Completion Notifications

**Trigger**: Stop hook when command completes

**Voice**: Normal pitch (50), moderate speed (160 wpm)

**Message Format**: `"directory, branch"`

**Examples**:
- "config, master"
- "neovim, feature-refactor"
- "nice_connectives, main"

**Purpose**: Minimal announcement identifying which session is ready for input. The comma provides a natural pause between directory and branch name.

**Configuration**:
```bash
TTS_COMPLETION_ENABLED=true
```

### 2. Permission Requests

**Trigger**: Notification hook when tool permission needed

**Voice**: Normal pitch (50), moderate speed (160 wpm) - same as completion

**Message Format**: `"directory, branch"` (identical to completion)

**Examples**:
- "config, master"
- "neovim, feature-refactor"
- "nice_connectives, main"

**Purpose**: Same minimal format as completion. You hear which directory/branch needs attention without verbose "Permission needed" messages.

**Configuration**:
```bash
TTS_PERMISSION_ENABLED=true
```

## Unsupported Categories

The following categories are not supported:

- **Progress Updates** (SubagentStop) - Not supported
- **Error Notifications** - Not supported (all Stop events use same message)
- **Idle Reminders** - Not supported
- **Session Lifecycle** - Not supported
- **Tool Execution** - Not supported
- **Prompt Acknowledgment** - Not supported
- **Compact Operations** - Not supported

All events that aren't Stop or Notification are ignored by the TTS dispatcher.

## Configuration

All configuration is in `.claude/tts/tts-config.sh`.

### Quick Start

```bash
# Enable/disable TTS globally
TTS_ENABLED=true

# Enable/disable specific categories
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true

# Customize voice for all notifications
TTS_VOICE_PARAMS="50:160"  # pitch:speed
```

### Global Settings

```bash
# Master enable/disable
TTS_ENABLED=true

# TTS engine (default: espeak-ng)
TTS_ENGINE="espeak-ng"

# Default voice (en-us+f3=female, en-us+m3=male)
TTS_VOICE="en-us+f3"
```

### Voice Customization

Voice parameters format: `"pitch:speed"` (unified for all categories)
- **Pitch**: 0-99 (0=lowest, 50=normal, 99=highest)
- **Speed**: Words per minute (typical range: 120-220)

Example customizations:

```bash
# Softer, slower voice
TTS_VOICE_PARAMS="35:140"

# Faster, higher voice
TTS_VOICE_PARAMS="60:180"

# Male voice instead of female
TTS_VOICE="en-us+m3"
```

### Advanced Options

```bash
# Commands that don't require TTS (space-separated list)
TTS_SILENT_COMMANDS="/clear /help /version /status /list /list-plans /list-reports /list-summaries"

# Debug mode: log to .claude/data/logs/tts.log
TTS_DEBUG=true
```

**Note**: Message verbosity settings and state file support are not available. All messages use the uniform "directory, branch" format.

## Installation

### 1. System Requirements

```bash
# Install espeak-ng
nix-env -iA nixpkgs.espeak-ng

# Verify installation
which espeak-ng
espeak-ng "Test message"
```

### 2. Hook Configuration

The TTS hooks should already be configured in `.claude/settings.local.json`. If you need to add them manually:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. Testing

```bash
# Test manually by sending JSON to dispatcher
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh

# Test specific categories by changing hook_event_name
echo '{"hook_event_name":"Notification","message":"Test message"}' | bash .claude/hooks/tts-dispatcher.sh
```

## Usage

### Basic Usage

TTS notifications work automatically once configured. No user action required.

### Enabling/Disabling

```bash
# Disable TTS temporarily
# Edit .claude/tts/tts-config.sh:
TTS_ENABLED=false

# Disable specific category
TTS_COMPLETION_ENABLED=false  # Disable completion notifications
TTS_PERMISSION_ENABLED=false  # Disable permission notifications
```

## Message Format Reference

### Uniform Message Format

All TTS notifications use the same format:
```
[directory], [branch]
```

The comma provides a natural pause between directory and branch name.

### Completion Message Examples

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

### Permission Message Examples

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

## Troubleshooting

### No Audio Output

**Problem**: TTS hook runs but no sound

**Solutions**:
1. Check espeak-ng installed: `which espeak-ng`
2. Test espeak-ng directly: `espeak-ng "test"`
3. Check audio system (PulseAudio/PipeWire)
4. Enable debug logging: `TTS_DEBUG=true`

### TTS Too Verbose

**Problem**: Too many notifications

**Solutions**:
1. Disable specific categories:
   ```bash
   TTS_COMPLETION_ENABLED=false  # Only permission notifications
   ```
2. Add commands to silent list:
   ```bash
   TTS_SILENT_COMMANDS="/clear /help /your-command-here"
   ```

### Voice Quality Poor

**Problem**: espeak-ng voice sounds robotic

**Solutions**:
1. Adjust voice parameters: slower = clearer
   ```bash
   TTS_VOICE_PARAMS="50:140"  # Slower speed
   ```
2. Try different voice:
   ```bash
   TTS_VOICE="en-us+m3"  # Male voice
   ```

### Hooks Not Firing

**Problem**: No TTS notifications at all

**Solutions**:
1. Check hooks configured: `cat .claude/settings.local.json | jq '.hooks'`
2. Check TTS enabled: `grep TTS_ENABLED .claude/tts/tts-config.sh`
3. Test dispatcher directly:
   ```bash
   echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
   ```

## Customization Examples

### Example 1: Both Categories Enabled (Default)

```bash
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_VOICE_PARAMS="50:160"
```

### Example 2: Only Completion Notifications

```bash
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=false  # No permission notifications
TTS_VOICE_PARAMS="50:160"
```

### Example 3: Only Permission Requests

```bash
TTS_COMPLETION_ENABLED=false  # No completion notifications
TTS_PERMISSION_ENABLED=true
TTS_VOICE_PARAMS="50:160"
```

### Example 4: Custom Voice

```bash
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_VOICE_PARAMS="35:140"  # Lower, slower voice
TTS_VOICE="en-us+m3"  # Male voice
```

## Advanced Features

### Silent Commands

Add commands that shouldn't trigger TTS:

```bash
# In .claude/tts/tts-config.sh
TTS_SILENT_COMMANDS="/clear /help /version /status /list /your-command"
```

Commands in this list won't generate TTS notifications even if completion is enabled.

### Custom Voice for All Notifications

Adjust the unified voice parameters:

```bash
# Lower pitch, slower speed (calmer)
TTS_VOICE_PARAMS="35:140"

# Higher pitch, faster speed (more urgent)
TTS_VOICE_PARAMS="65:190"

# Very slow for clarity
TTS_VOICE_PARAMS="50:120"
```

### Customizing Messages

Edit `.claude/tts/tts-messages.sh` to customize message templates:

```bash
# Find the generate_completion_message function
# Add custom logic for your command:

case "$command" in
  *mycustom*)
    message="$message My custom completion message."
    ;;
esac
```

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

## Integration with Commands

### Commands with TTS Support

All commands support TTS notifications via hooks:
- `/implement` - Phase completions, test results, final status
- `/orchestrate` - Agent completions, phase transitions
- `/test` - Test suite results, pass/fail counts
- `/plan` - Plan generation completion
- `/revise` - Revision completion

### Custom Notifications

Commands can emit custom TTS notifications via:
```bash
# From command scripts
echo "TTS: Custom notification message" >&2
```

The TTS dispatcher monitors stderr for `TTS:` prefixed messages and converts them to speech.

## Accessibility Considerations

TTS significantly enhances accessibility:

- **Vision-impaired developers**: Audio feedback for all workflow stages
- **Multitasking**: Audio cues allow working in other applications
- **Remote work**: Know when long-running operations complete
- **Background awareness**: Stay informed without constant monitoring

## Best Practices

### When to Use TTS

**Recommended for**:
- Long-running operations (>2 minutes)
- Background workflows (orchestration, implementation)
- Operations you want to monitor while multitasking
- Error detection during unattended execution

**Not recommended for**:
- Quick commands (<30 seconds)
- Interactive commands requiring immediate attention
- Noisy environments (notifications may be disruptive)
- Shared workspaces (may disturb others)

### Configuration Tips

**For minimal distraction**:
- Use completion notifications only
- Set lower volume
- Add frequently-used commands to silent list

**For maximum awareness**:
- Enable both completion and permission notifications
- Use clearer voice settings (slower speed)
- Enable debug logging for troubleshooting

## Uninstallation

### Temporary Disable

```bash
# Edit .claude/tts/tts-config.sh
TTS_ENABLED=false
```

### Remove Hooks

Edit `.claude/settings.local.json` and remove tts-dispatcher.sh entries from all hooks.

### Complete Removal

```bash
# Remove TTS files
rm .claude/tts/tts-config.sh
rm .claude/tts/tts-messages.sh
rm .claude/hooks/tts-dispatcher.sh
```

## Reference

### File Locations

- **Configuration**: `.claude/tts/tts-config.sh`
- **Message Generator**: `.claude/tts/tts-messages.sh`
- **Dispatcher Hook**: `.claude/hooks/tts-dispatcher.sh`
- **Debug Logs**: `.claude/data/logs/tts.log` and `.claude/data/logs/hook-debug.log`

### Hook Input Format

TTS hooks receive JSON via stdin with these fields:

- `hook_event_name` - Hook event type (Stop or Notification supported)
- `cwd` - Project directory path
- `command` - Command being executed (optional)
- `status` - Command status (success, error, etc.)
- `message` - Notification message content (for Notification events)

**Supported Events**:
- `Stop` - Task completion (generates TTS)
- `Notification` - Permission requests (generates TTS)
- All other events are ignored (no TTS)

The dispatcher parses this JSON and exports values as environment variables for message generation.

### Voice Options

espeak-ng voices (run `espeak-ng --voices` for full list):

- `en-us+f3` - US English, female, variant 3
- `en-us+m3` - US English, male, variant 3
- `en-gb+f1` - British English, female
- `en-gb+m1` - British English, male

### System Requirements

**Linux**:
- espeak-ng (recommended) or festival
- PulseAudio or PipeWire for audio

**macOS**:
- Uses system `say` command (built-in)
- No additional installation required

**Windows**:
- Uses PowerShell TTS (built-in)
- No additional installation required

### Performance Impact

**Minimal overhead**:
- Hooks execute asynchronously (non-blocking)
- TTS generation happens in background
- No impact on command execution time
- Audio playback concurrent with continued work

### Privacy Considerations

**No external services**:
- All TTS processing local (system TTS engines)
- No data sent to external services
- No logging of notification content
- User can disable at any time

## Related Topics

- [Orchestration Guide](orchestration-guide.md) - Multi-agent workflows with TTS notifications
- [Efficiency Guide](../guides/patterns/performance-optimization.md) - Performance optimization including TTS configuration

## Resources

- **espeak-ng Documentation**: https://github.com/espeak-ng/espeak-ng
- **Claude Code Hooks**: https://docs.claude.com/en/docs/claude-code/hooks
- **NixOS Packages**: https://search.nixos.org/packages?query=espeak
