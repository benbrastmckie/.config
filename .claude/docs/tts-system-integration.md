# TTS (Text-to-Speech) System Integration

## Overview

The TTS system provides real-time audio notifications during Claude Code workflows, improving awareness of long-running operations and command completions.

## Components

**Core TTS Engine** (`.claude/tts/`):
- `tts-dispatcher.sh` - Main TTS engine, handles text-to-speech conversion
- `voice-config.sh` - Voice and rate configuration
- `notification-formatter.sh` - Formats notifications for speech

**Integration Hooks** (`.claude/hooks/`):
- `post-command-metrics.sh` - Command completion notifications
- `post-subagent-metrics.sh` - Agent completion notifications
- `tts-dispatcher.sh` - Hook dispatcher integration

## Configuration

### Enable TTS System

TTS is configured via Claude Code settings (not .claude/ directory).

**To enable TTS notifications:**
1. Open Claude Code settings
2. Navigate to Hooks configuration
3. Enable the following hooks:
   - `post-command` → Notifies when commands complete
   - `post-subagent` → Notifies when agents finish
4. Set TTS voice preferences in hooks configuration

### Voice Settings

**Supported Voices** (system-dependent):
- macOS: Uses `say` command with system voices
- Linux: Uses `espeak` or `festival`
- Windows: Uses PowerShell TTS

**Configuration Options**:
- Speech rate (words per minute)
- Voice gender/style
- Volume level
- Notification verbosity (brief vs detailed)

## Usage

### Automatic Notifications

**Command Completions**:
```bash
# Long-running commands automatically trigger TTS notifications
/implement long-plan.md
# → Audio notification when implementation completes
#    "Implementation complete. 5 phases executed. All tests passing."
```

**Agent Completions**:
```bash
# Orchestration with multiple agents provides progress updates
/orchestrate "Implement authentication system"
# → Audio notifications as each agent completes:
#    "Research agent 1 complete. Existing patterns analyzed."
#    "Research agent 2 complete. Security best practices documented."
#    "Planning complete. Implementation plan generated."
```

**Error Notifications**:
```bash
# Errors are announced for immediate awareness
/implement plan.md
# → If test failures occur:
#    "Phase 3 tests failed. 4 errors detected. Review required."
```

### Notification Types

**Brief Mode** (default):
- Command name + status (success/failure)
- Example: "Implement command complete. Success."

**Detailed Mode**:
- Command name + key metrics + status
- Example: "Implementation complete. 5 phases executed, 23 tasks completed, all tests passing."

**Error Mode**:
- Error type + count + action needed
- Example: "Test failures detected. 4 errors in phase 3. Manual review required."

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

## Troubleshooting

### TTS Not Working

**Check hook activation**:
```bash
# Verify hooks are enabled in Claude Code settings
# Settings → Hooks → Ensure post-command and post-subagent enabled
```

**Check TTS availability**:
```bash
# macOS
which say

# Linux
which espeak || which festival

# Test TTS engine directly
.claude/tts/tts-dispatcher.sh "Test notification"
```

### Unwanted Notifications

**Disable specific hooks**:
- Disable `post-command` to stop command completion notifications
- Disable `post-subagent` to stop agent completion notifications

**Adjust verbosity**:
- Set notification mode to "brief" in TTS configuration
- Filter by command type (e.g., only notify on long-running commands)

### Voice Quality Issues

**Change voice**:
```bash
# macOS - list available voices
say -v ?

# Set preferred voice in voice-config.sh
VOICE="Samantha"  # or "Alex", "Victoria", etc.
```

**Adjust speech rate**:
```bash
# Edit voice-config.sh
SPEECH_RATE=200  # words per minute (default: 175)
```

## Technical Details

### Hook Execution Flow

1. Command executes (e.g., `/implement`)
2. Command completes or reaches notification point
3. Hook triggers: `post-command` hook executes
4. Hook script extracts metrics (duration, status, errors)
5. Hook formats notification message
6. TTS dispatcher converts text to speech
7. Audio plays through system speakers

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
- Use "brief" mode
- Enable only `post-command` (not `post-subagent`)
- Set lower volume

**For maximum awareness**:
- Use "detailed" mode
- Enable both `post-command` and `post-subagent`
- Configure distinct voices for different notification types

## See Also

- `.claude/tts/README.md` - TTS system implementation details
- `.claude/hooks/README.md` - Hook system documentation
- Claude Code Settings → Hooks - Configuration interface

## Notes

The TTS system is fully optional. All functionality works identically whether TTS is enabled or disabled. TTS provides awareness but is not required for any operations.
