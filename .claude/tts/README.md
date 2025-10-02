# TTS Directory

Text-to-speech notification system for Claude Code workflows. Provides voice feedback for events like command completion, permission requests, progress updates, and errors with customizable voice characteristics.

## Purpose

The TTS system enables:

- **Voice notifications** for workflow events
- **Categorized messages** with distinct voice characteristics
- **Context-aware feedback** including directory and branch
- **Non-intrusive operation** that never blocks workflow
- **Customizable configuration** per category

## TTS Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Event                                           │
│ (Stop, SessionStart, Notification, etc.)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Dispatcher Hook                                         │
│ (.claude/hooks/tts-dispatcher.sh)                          │
├─────────────────────────────────────────────────────────────┤
│ • Parses event JSON                                         │
│ • Detects notification category                             │
│ • Checks if category enabled                                │
│ • Gets voice parameters                                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Message Generator                                           │
│ (.claude/tts/tts-messages.sh)                              │
├─────────────────────────────────────────────────────────────┤
│ • Extracts context (directory, branch)                      │
│ • Generates category-specific message                       │
│ • Returns formatted message                                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ TTS Engine (espeak-ng)                                      │
├─────────────────────────────────────────────────────────────┤
│ • Speaks message asynchronously                             │
│ • Uses category voice parameters                            │
│ • Non-blocking execution                                    │
└─────────────────────────────────────────────────────────────┘
```

## Files

### tts-config.sh
**Purpose**: Configuration for all TTS settings

**Sections**:
- Global Settings (enabled, engine, voice, speed)
- Category Enablement (9 categories)
- Voice Characteristics (pitch:speed per category)
- Message Verbosity (context options)
- Advanced Options (min duration, state files, debug)

**Key Variables**:
```bash
TTS_ENABLED=false                    # Master enable/disable
TTS_ENGINE="espeak-ng"               # TTS engine to use
TTS_VOICE="en-us+f3"                 # Default voice
TTS_DEFAULT_SPEED=160                # Words per minute

# Category enable/disable
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_PROGRESS_ENABLED=true
TTS_ERROR_ENABLED=true
TTS_IDLE_ENABLED=false
TTS_SESSION_ENABLED=false
TTS_TOOL_ENABLED=false
TTS_PROMPT_ACK_ENABLED=false
TTS_COMPACT_ENABLED=false

# Voice characteristics (pitch:speed)
TTS_COMPLETION_VOICE="50:160"        # Normal
TTS_PERMISSION_VOICE="60:180"        # Higher, faster (urgent)
TTS_PROGRESS_VOICE="40:180"          # Lower, faster (background)
TTS_ERROR_VOICE="35:140"             # Low, slow (alert)
TTS_IDLE_VOICE="50:140"              # Normal, slow (gentle)

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
# Format: "Permission needed. [Tool name]. [Context]."
# Example: "Permission needed. Bash. Git commit required."

generate_progress_message()
# Format: "Progress update. [Agent name] complete. [Result]."
# Example: "Progress update. code writer complete. Feature implemented."

generate_error_message()
# Format: "Error in [command]. [Error type]. Review output."
# Example: "Error in implement. Test failures. Review output."

generate_idle_message()
# Format: "Still waiting for input. Last action: [command]. [Duration]."
# Example: "Still waiting for input. Last action: plan. Waiting 2 minutes."

generate_session_message()
# Format: "Session started. [directory], [branch]" (or SessionEnd variant)
# Example: "Session started. config, master"

generate_tool_message()
# Format: "[Tool name] starting/complete."
# Example: "Grep starting. Searching codebase."

generate_prompt_ack_message()
# Format: "Prompt received."
# Example: "Prompt received."

generate_compact_message()
# Format: "Compacting context. [trigger]. Workflow may pause."
# Example: "Compacting context. manual compact. Workflow may pause."
```

#### Message Routing
```bash
generate_message() {
  local category="$1"
  # Routes to appropriate generator based on category
}
```

**Environment Variables Used**:
- `CLAUDE_PROJECT_DIR`: Project directory
- `CLAUDE_COMMAND`: Command being executed
- `CLAUDE_STATUS`: Command status
- `HOOK_EVENT`: Hook event type
- `NOTIFICATION_MESSAGE`: Additional context
- Category-specific variables (SUBAGENT_TYPE, ERROR_TYPE, etc.)

## Notification Categories

### 1. Completion
**Triggered By**: Stop hook when command completes successfully

**Message**: Directory and branch context

**Voice**: Normal pitch and speed (50:160)

**Use Case**: Know when Claude is ready for next input

**Example**: "config, master"

---

### 2. Permission
**Triggered By**: Notification hook for tool permissions

**Message**: Tool name and context

**Voice**: Higher pitch, faster (60:180) for urgency

**Use Case**: Immediate notification when approval needed

**Example**: "Permission needed. Bash. Git operations."

---

### 3. Progress
**Triggered By**: SubagentStop hook

**Message**: Agent name and result

**Voice**: Lower pitch, faster (40:180) for background info

**Use Case**: Track subagent completion in long workflows

**Example**: "Progress update. test specialist complete. All tests passed."

---

### 4. Error
**Triggered By**: Stop hook with error status

**Message**: Command and error type

**Voice**: Low pitch, slow (35:140) for alert

**Use Case**: Immediate attention to failures

**Example**: "Error in implement. Test failures. Review output."

---

### 5. Idle
**Triggered By**: Notification hook after 60+ seconds idle

**Message**: Last command and wait duration

**Voice**: Normal pitch, slow (50:140) for gentle reminder

**Use Case**: Reminder if you stepped away

**Example**: "Still waiting for input. Last action: plan. Waiting 2 minutes."

**Note**: Disabled by default (can be verbose)

---

### 6. Session
**Triggered By**: SessionStart or SessionEnd hooks

**Message**: Session state and context

**Voice**: Normal pitch and speed (50:160)

**Use Case**: Session lifecycle awareness

**Example**: "Session started. config, master"

**Note**: Disabled by default

---

### 7. Tool
**Triggered By**: PreToolUse or PostToolUse hooks (optional)

**Message**: Tool name and phase

**Voice**: Very low, very fast (30:200) for minimal intrusion

**Use Case**: Tool execution awareness

**Example**: "Grep starting. Searching codebase."

**Note**: Disabled by default (very verbose)

---

### 8. Prompt Acknowledgment
**Triggered By**: UserPromptSubmit hook (optional)

**Message**: Quick confirmation

**Voice**: High pitch, very fast (70:220)

**Use Case**: Immediate feedback that input received

**Example**: "Prompt received."

**Note**: Disabled by default

---

### 9. Compact
**Triggered By**: PreCompact hook (optional)

**Message**: Compaction warning

**Voice**: Normal pitch and speed (50:160)

**Use Case**: Warning before workflow pause

**Example**: "Compacting context. auto compact. Workflow may pause."

**Note**: Disabled by default

## Configuration Guide

### Enable TTS
```bash
# Edit configuration
nvim .claude/tts/tts-config.sh

# Set master enable
TTS_ENABLED=true

# Enable desired categories
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_ERROR_ENABLED=true
```

### Customize Voice Characteristics
```bash
# Make errors more alerting
TTS_ERROR_VOICE="20:120"  # Very low pitch, slow speed

# Make completion less intrusive
TTS_COMPLETION_VOICE="45:180"  # Slightly lower, faster

# Change default voice
TTS_VOICE="en-us+m3"  # Male voice
```

### Add Silent Commands
```bash
# Commands that don't need TTS notifications
TTS_SILENT_COMMANDS="/clear /help /version /status /list"
```

### Enable Debug Logging
```bash
TTS_DEBUG=true
# Logs to .claude/logs/tts.log
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
tail .claude/logs/tts.log
```

### Monitor TTS Activity
```bash
# Watch TTS log in real-time
tail -f .claude/logs/tts.log

# Watch hook debug log
tail -f .claude/logs/hook-debug.log
```

## Extending TTS

### Add New Category

#### Step 1: Add Configuration
Edit `tts-config.sh`:
```bash
# Enable/disable
TTS_MYCATEGORY_ENABLED=true

# Voice characteristics
TTS_MYCATEGORY_VOICE="55:170"
```

#### Step 2: Add Message Generator
Edit `tts-messages.sh`:
```bash
generate_mycategory_message() {
  local context=$(get_context_prefix)
  echo "$context. Custom message."
}

# Add to message routing
generate_message() {
  case "$category" in
    # ... existing cases ...
    mycategory)
      generate_mycategory_message
      ;;
  esac
}
```

#### Step 3: Update Dispatcher
Edit `hooks/tts-dispatcher.sh`:
```bash
# Add category detection
detect_category() {
  case "$event" in
    # ... existing cases ...
    MyEvent)
      echo "mycategory"
      ;;
  esac
}

# Add enablement check
is_category_enabled() {
  case "$category" in
    # ... existing cases ...
    mycategory)
      var_name="TTS_MYCATEGORY_ENABLED"
      ;;
  esac
}

# Add voice parameters
get_voice_params() {
  case "$category" in
    # ... existing cases ...
    mycategory)
      var_name="TTS_MYCATEGORY_VOICE"
      ;;
  esac
}
```

#### Step 4: Register Hook
Edit `settings.local.json`:
```json
{
  "hooks": {
    "MyEvent": [
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
tail .claude/logs/hook-debug.log
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

## Documentation Standards

All TTS documentation follows standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md) for complete standards.

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

# Essential categories
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_ERROR_ENABLED=true

# Voice customization
TTS_VOICE="en-us+f3"
TTS_ERROR_VOICE="35:140"  # Low and slow for alerts
```

### Debug Commands
```bash
# Test TTS
espeak-ng "Test message"

# Check TTS log
tail -f .claude/logs/tts.log

# Manual message test
source .claude/tts/tts-messages.sh && generate_completion_message
```

### Common Configurations

**Minimal (Only Errors)**:
```bash
TTS_ENABLED=true
TTS_COMPLETION_ENABLED=false
TTS_PERMISSION_ENABLED=false
TTS_PROGRESS_ENABLED=false
TTS_ERROR_ENABLED=true
```

**Standard (Common Events)**:
```bash
TTS_ENABLED=true
TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_PROGRESS_ENABLED=true
TTS_ERROR_ENABLED=true
```

**Verbose (All Events)**:
```bash
TTS_ENABLED=true
# All categories enabled=true
```
