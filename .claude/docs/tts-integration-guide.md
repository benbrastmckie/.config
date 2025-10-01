# TTS Integration Guide

Comprehensive guide for Claude Code text-to-speech notification system.

## Overview

The TTS integration provides voice feedback for all significant Claude Code workflow events. The system categorizes notifications into 9 distinct types with different voice characteristics, allowing you to stay informed about workflow progress without constantly monitoring the terminal.

### Key Features

- **9 Notification Categories**: Completion, permission, progress, error, idle, session, tool, prompt acknowledgment, compact operations
- **Voice Customization**: Each category has distinct pitch/speed characteristics
- **Configurable**: Enable/disable categories individually
- **Non-intrusive**: Async execution, never blocks workflow
- **Context-aware**: Messages include directory, branch, and task-specific information
- **Extensible**: Easy to add new categories or customize messages

### Design Philosophy

1. **Non-intrusive**: TTS runs asynchronously, never blocking workflow
2. **Context-aware**: Messages include relevant location and state information
3. **Categorized**: Different voice characteristics for different event types
4. **Configurable**: User can enable/disable categories and customize voices
5. **Intelligent**: Message generation based on command type and execution context
6. **Extensible**: Easy to add new categories or customize existing ones

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
│ Message Generator (.claude/lib/tts-messages.sh)             │
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

**Trigger**: Stop hook when command completes successfully

**Voice**: Normal pitch (50), moderate speed (160 wpm)

**Message Pattern**: `"Directory [name]. Branch [branch]. [Summary]. Ready for input."`

**Examples**:
- "Directory config. Branch master. Implementation complete. Ready for input."
- "Directory api-server. Branch feature-auth. Tests passed. Ready for input."

**Configuration**:
```bash
TTS_COMPLETION_ENABLED=true
TTS_COMPLETION_VOICE="50:160"
```

### 2. Permission Requests

**Trigger**: Notification hook when tool permission needed

**Voice**: Higher pitch (60), faster speed (180 wpm) - urgency

**Message Pattern**: `"Permission needed. [Tool name]. [Context]."`

**Examples**:
- "Permission needed. Bash. Git commit for Phase 2."
- "Permission needed. Web search. Research authentication patterns."

**Configuration**:
```bash
TTS_PERMISSION_ENABLED=true
TTS_PERMISSION_VOICE="60:180"
```

### 3. Progress Updates

**Trigger**: SubagentStop hook when subagent completes

**Voice**: Lower pitch (40), faster speed (180 wpm) - background info

**Message Pattern**: `"Progress update. [Agent] complete. [Result]."`

**Examples**:
- "Progress update. Research specialist complete. Found 3 patterns."
- "Progress update. Test specialist complete. 15 tests passed."

**Configuration**:
```bash
TTS_PROGRESS_ENABLED=true
TTS_PROGRESS_VOICE="40:180"
```

### 4. Error Notifications

**Trigger**: Stop hook when command fails

**Voice**: Low pitch (35), slower speed (140 wpm) - alert

**Message Pattern**: `"Error in [command]. [Error type]. Review output."`

**Examples**:
- "Error in implement. Tests failed in Phase 2. Review output."
- "Error in orchestrate. Planning phase timeout. Review output."

**Configuration**:
```bash
TTS_ERROR_ENABLED=true
TTS_ERROR_VOICE="35:140"
```

### 5. Idle Reminders

**Trigger**: Notification hook after 60+ seconds idle

**Voice**: Normal pitch (50), slower speed (140 wpm) - gentle

**Message Pattern**: `"Still waiting for input. Last action: [command]. [Duration]."`

**Examples**:
- "Still waiting for input. Last action: implement. Waiting 2 minutes."

**Configuration**:
```bash
TTS_IDLE_ENABLED=true
TTS_IDLE_VOICE="50:140"
```

### 6. Session Lifecycle

**Trigger**: SessionStart/SessionEnd hooks

**Voice**: Normal pitch (50), moderate speed (160 wpm)

**Message Patterns**:
- Start: `"Session started. Directory [name]. Branch [branch]."`
- End: `"Session ended. [Reason]."`

**Configuration**:
```bash
TTS_SESSION_ENABLED=true
TTS_SESSION_VOICE="50:160"
```

### 7. Tool Execution (Optional)

**Trigger**: PreToolUse/PostToolUse hooks

**Voice**: Very low pitch (30), very fast (200 wpm) - minimal intrusion

**Message Patterns**:
- Pre: `"[Tool] starting. [Context]."`
- Post: `"[Tool] complete."`

**Configuration** (disabled by default):
```bash
TTS_TOOL_ENABLED=false  # Set to true to enable
TTS_TOOL_VOICE="30:200"
```

**Note**: Disabled by default as it can be verbose.

### 8. Prompt Acknowledgment (Optional)

**Trigger**: UserPromptSubmit hook

**Voice**: High pitch (70), very fast (220 wpm) - quick confirmation

**Message Pattern**: `"Prompt received. [Brief]."`

**Configuration** (disabled by default):
```bash
TTS_PROMPT_ACK_ENABLED=false  # Set to true to enable
TTS_PROMPT_ACK_VOICE="70:220"
```

**Note**: Useful when multitasking to confirm input received.

### 9. Compact Operations (Optional)

**Trigger**: PreCompact hook

**Voice**: Normal pitch (50), moderate speed (160 wpm)

**Message Pattern**: `"Compacting context. [Trigger]. Workflow may pause."`

**Configuration** (disabled by default):
```bash
TTS_COMPACT_ENABLED=false  # Set to true to enable
TTS_COMPACT_VOICE="50:160"
```

## Configuration

All configuration is in `.claude/config/tts-config.sh`.

### Quick Start

```bash
# Enable/disable TTS globally
TTS_ENABLED=true

# Enable/disable specific categories
TTS_COMPLETION_ENABLED=true
TTS_PROGRESS_ENABLED=false  # Disable if too verbose

# Customize voice characteristics
TTS_ERROR_VOICE="20:120"  # Very low, very slow for errors
```

### Global Settings

```bash
# Master enable/disable
TTS_ENABLED=true

# TTS engine (default: espeak-ng)
TTS_ENGINE="espeak-ng"

# Default voice (en-us+f3=female, en-us+m3=male)
TTS_VOICE="en-us+f3"

# Default speech speed (words per minute)
TTS_DEFAULT_SPEED=160
```

### Voice Customization

Voice parameters format: `"pitch:speed"`
- **Pitch**: 0-99 (0=lowest, 50=normal, 99=highest)
- **Speed**: Words per minute (typical range: 120-220)

Example customizations:

```bash
# Softer, slower voice for all categories
TTS_DEFAULT_SPEED=140

# Male voice instead of female
TTS_VOICE="en-us+m3"

# More distinct error alerts
TTS_ERROR_VOICE="20:120"  # Very low, very slow

# Faster background notifications
TTS_PROGRESS_VOICE="35:200"
```

### Message Verbosity

```bash
# Include directory name in messages
TTS_INCLUDE_DIRECTORY=true

# Include git branch in messages
TTS_INCLUDE_BRANCH=true

# Include operation duration (only for long ops)
TTS_INCLUDE_DURATION=false
```

### Advanced Options

```bash
# Minimum duration (ms) to trigger TTS
TTS_MIN_DURATION_MS=1000  # Skip operations <1 second

# Enable state file support for detailed summaries
TTS_STATE_FILE_ENABLED=false

# Debug mode: log to .claude/logs/tts.log
TTS_DEBUG=false
```

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
# Run comprehensive test suite
./.claude/bin/test-tts.sh

# Test specific category
./.claude/bin/test-tts.sh completion

# Test without audio (message generation only)
./.claude/bin/test-tts.sh --silent
```

## Usage

### Basic Usage

TTS notifications work automatically once configured. No user action required.

### Enabling/Disabling

```bash
# Disable TTS temporarily
# Edit .claude/config/tts-config.sh:
TTS_ENABLED=false

# Disable specific category
TTS_PROGRESS_ENABLED=false  # Too verbose
```

### State File Support

For richer notifications, commands can write state files:

```bash
# Create state file
mkdir -p .claude/state
cat > .claude/state/last-completion.json <<EOF
{
  "command": "/implement",
  "phase": "Phase 3",
  "summary": "Implemented hooks infrastructure",
  "status": "success",
  "next_steps": "Ready for Phase 4",
  "duration_ms": 45000
}
EOF

# TTS will use this for detailed completion message
```

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
1. Disable verbose categories:
   ```bash
   TTS_PROGRESS_ENABLED=false
   TTS_TOOL_ENABLED=false
   ```
2. Increase minimum duration:
   ```bash
   TTS_MIN_DURATION_MS=2000  # Only announce >2 second ops
   ```

### Voice Quality Poor

**Problem**: espeak-ng voice sounds robotic

**Solutions**:
1. Adjust speed: slower = clearer
   ```bash
   TTS_DEFAULT_SPEED=140
   ```
2. Consider alternative TTS engines:
   ```bash
   TTS_ENGINE="festival"  # Requires configuration changes
   ```

### Hooks Not Firing

**Problem**: No TTS notifications at all

**Solutions**:
1. Check hooks configured: `cat .claude/settings.local.json | jq '.hooks'`
2. Check TTS enabled: `grep TTS_ENABLED .claude/config/tts-config.sh`
3. Test dispatcher directly:
   ```bash
   export HOOK_EVENT="Stop"
   export CLAUDE_PROJECT_DIR="$PWD"
   ./.claude/hooks/tts-dispatcher.sh
   ```

## Customization Examples

### Example 1: Minimal Setup

Only essential notifications:

```bash
TTS_COMPLETION_ENABLED=true
TTS_ERROR_ENABLED=true
TTS_SESSION_ENABLED=true

# Disable all others
TTS_PERMISSION_ENABLED=false
TTS_PROGRESS_ENABLED=false
TTS_IDLE_ENABLED=false
TTS_TOOL_ENABLED=false
TTS_PROMPT_ACK_ENABLED=false
TTS_COMPACT_ENABLED=false
```

### Example 2: Verbose Setup

All notifications enabled:

```bash
# Enable everything
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_PROGRESS_ENABLED=true
TTS_ERROR_ENABLED=true
TTS_IDLE_ENABLED=true
TTS_SESSION_ENABLED=true
TTS_TOOL_ENABLED=true
TTS_PROMPT_ACK_ENABLED=true
TTS_COMPACT_ENABLED=true
```

### Example 3: Custom Voices

Distinct voice characteristics:

```bash
# Normal for completion
TTS_COMPLETION_VOICE="50:160"

# Very urgent for permission
TTS_PERMISSION_VOICE="70:200"

# Very low and slow for errors (alarming)
TTS_ERROR_VOICE="20:100"

# Fast background for progress
TTS_PROGRESS_VOICE="35:220"
```

## Advanced Features

### Multi-Command State Tracking

Commands can write state for detailed TTS messages:

```lua
-- In a Claude Code command
local state = {
  command = "/implement",
  phase = "Phase 3",
  summary = "All tests passed",
  status = "success",
  next_steps = "Review and commit",
  duration_ms = 45000
}

local state_file = ".claude/state/last-completion.json"
local f = io.open(state_file, "w")
f:write(vim.json.encode(state))
f:close()
```

### Custom Message Templates

Add new message templates by editing `.claude/lib/tts-messages.sh`:

```bash
# Add custom generator
generate_custom_message() {
  local context=$(get_context_prefix)
  echo "$context Your custom message."
}

# Update routing
case "$category" in
  ...
  custom)
    generate_custom_message
    ;;
esac
```

### Integration with Agents

TTS automatically announces subagent progress via SubagentStop hook. No additional configuration needed.

## Accessibility Considerations

TTS significantly enhances accessibility:

- **Vision-impaired developers**: Audio feedback for all workflow stages
- **Multitasking**: Audio cues allow working in other applications
- **Remote work**: Know when long-running operations complete
- **Background awareness**: Stay informed without constant monitoring

## Uninstallation

To disable TTS completely:

### Temporary Disable

```bash
# Edit .claude/config/tts-config.sh
TTS_ENABLED=false
```

### Remove Hooks

Edit `.claude/settings.local.json` and remove tts-dispatcher.sh entries from all hooks.

### Complete Removal

```bash
# Remove TTS files
rm .claude/config/tts-config.sh
rm .claude/lib/tts-messages.sh
rm .claude/hooks/tts-dispatcher.sh
rm .claude/bin/test-tts.sh
rm -rf .claude/state/
```

## Reference

### File Locations

- **Configuration**: `.claude/config/tts-config.sh`
- **Message Generator**: `.claude/lib/tts-messages.sh`
- **Dispatcher Hook**: `.claude/hooks/tts-dispatcher.sh`
- **Test Utility**: `.claude/bin/test-tts.sh`
- **State Files**: `.claude/state/*.json`
- **Debug Log**: `.claude/logs/tts.log` (if enabled)

### Environment Variables

TTS hooks receive these environment variables:

- `HOOK_EVENT` - Hook event type (Stop, SessionStart, etc.)
- `CLAUDE_PROJECT_DIR` - Project directory
- `CLAUDE_COMMAND` - Command being executed
- `CLAUDE_STATUS` - Command status (success, error, etc.)
- `SUBAGENT_TYPE` - Subagent type (for SubagentStop)
- `TOOL_NAME` - Tool name (for tool hooks)
- `NOTIFICATION_TYPE` - Notification type (permission, idle)

### Voice Options

espeak-ng voices (run `espeak-ng --voices` for full list):

- `en-us+f3` - US English, female, variant 3
- `en-us+m3` - US English, male, variant 3
- `en-gb+f1` - British English, female
- `en-gb+m1` - British English, male

### Resources

- **espeak-ng Documentation**: https://github.com/espeak-ng/espeak-ng
- **Claude Code Hooks**: https://docs.claude.com/en/docs/claude-code/hooks
- **NixOS Packages**: https://search.nixos.org/packages?query=espeak
