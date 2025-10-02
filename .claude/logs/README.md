# Logs Directory

Runtime logs and debug output for Claude Code hooks and TTS system. Used for troubleshooting, monitoring, and understanding system behavior.

## Purpose

The logs directory provides:

- **Hook execution traces** for debugging hook behavior
- **TTS invocation history** for notification troubleshooting
- **Error diagnostics** for system issues
- **Audit trail** of automated operations

## Log Files

### hook-debug.log
**Purpose**: Trace hook execution with event details

**Written By**: `hooks/tts-dispatcher.sh` and other hooks

**Format**:
```
[2025-10-01T12:34:56+00:00] Hook called: EVENT=Stop CMD=/implement STATUS=success
[2025-10-01T12:35:23+00:00] Hook called: EVENT=Stop CMD=/test STATUS=success
[2025-10-01T12:36:44+00:00] Hook called: EVENT=SubagentStop CMD=/implement STATUS=success
[2025-10-01T12:37:15+00:00] Hook called: EVENT=Notification CMD= STATUS=success
```

**Fields**:
- **Timestamp**: ISO 8601 with timezone
- **EVENT**: Hook event name (Stop, SessionStart, etc.)
- **CMD**: Command being executed (if applicable)
- **STATUS**: Execution status (success/error)

**Use Cases**:
- Verify hooks are being triggered
- Check event type detection
- Debug hook registration issues
- Trace execution flow

**Viewing**:
```bash
# Show recent hook calls
tail .claude/logs/hook-debug.log

# Follow in real-time
tail -f .claude/logs/hook-debug.log

# Filter by event type
grep "EVENT=Stop" .claude/logs/hook-debug.log

# Count events by type
grep -o "EVENT=[^ ]*" .claude/logs/hook-debug.log | sort | uniq -c
```

---

### tts.log
**Purpose**: TTS invocation history for notification troubleshooting

**Written By**: `hooks/tts-dispatcher.sh`

**Enabled**: When `TTS_DEBUG=true` in `tts/tts-config.sh`

**Format**:
```
[2025-10-01T12:34:56+00:00] [Stop] config, master (pitch:50 speed:160)
[2025-10-01T12:35:23+00:00] [Stop] config, master (pitch:50 speed:160)
[2025-10-01T12:36:44+00:00] [SubagentStop] Progress update. code writer complete. (pitch:40 speed:180)
[2025-10-01T12:37:15+00:00] [Notification] Permission needed. Bash. (pitch:60 speed:180)
```

**Fields**:
- **Timestamp**: ISO 8601 with timezone
- **Event**: Hook event type in brackets
- **Message**: TTS message that was spoken
- **Voice params**: Pitch and speed used

**Use Cases**:
- Verify TTS is being invoked
- Check message content
- Debug voice parameter issues
- Monitor notification frequency

**Viewing**:
```bash
# Show recent TTS messages
tail .claude/logs/tts.log

# Follow in real-time
tail -f .claude/logs/tts.log

# Filter by event
grep "\[Stop\]" .claude/logs/tts.log

# See only error notifications
grep "\[Stop\].*Error" .claude/logs/tts.log

# Count notifications by type
grep -o "\[[^]]*\]" .claude/logs/tts.log | sort | uniq -c
```

## Log Management

### Automatic Creation
Logs are created automatically when needed:
- Hooks create `.claude/logs/` directory if missing
- Log files are created on first write
- No manual initialization required

### Log Rotation
Logs do NOT auto-rotate. Manual cleanup recommended:

```bash
# Archive old logs monthly
mkdir -p .claude/logs/archive
mv .claude/logs/hook-debug.log .claude/logs/archive/hook-debug-$(date +%Y-%m).log
mv .claude/logs/tts.log .claude/logs/archive/tts-$(date +%Y-%m).log

# Recreate fresh logs (hooks will create on next write)
```

### Log Cleanup
```bash
# Clear logs (keeps files)
> .claude/logs/hook-debug.log
> .claude/logs/tts.log

# Remove old archived logs
find .claude/logs/archive -name "*.log" -mtime +180 -delete

# Keep only last 1000 lines
tail -1000 .claude/logs/hook-debug.log > .claude/logs/hook-debug.log.tmp
mv .claude/logs/hook-debug.log.tmp .claude/logs/hook-debug.log
```

## Debugging Workflows

### Hook Not Running
**Symptoms**: No entries in hook-debug.log for expected events

**Steps**:
1. Check hook registration:
   ```bash
   cat .claude/settings.local.json | jq '.hooks'
   ```

2. Verify hook executable:
   ```bash
   ls -l .claude/hooks/*.sh
   ```

3. Test hook manually:
   ```bash
   echo '{"hook_event_name":"Stop","command":"/test","status":"success"}' | .claude/hooks/your-hook.sh
   ```

4. Check for errors:
   ```bash
   bash -x .claude/hooks/your-hook.sh < test-input.json
   ```

---

### TTS Not Working
**Symptoms**: No entries in tts.log or hooks firing but no audio

**Steps**:
1. Enable TTS debug:
   ```bash
   grep "TTS_DEBUG" .claude/tts/tts-config.sh
   # Should be: TTS_DEBUG=true
   ```

2. Check TTS enabled:
   ```bash
   grep "TTS_ENABLED" .claude/tts/tts-config.sh
   # Should be: TTS_ENABLED=true
   ```

3. Verify category enabled:
   ```bash
   grep "TTS_COMPLETION_ENABLED" .claude/tts/tts-config.sh
   ```

4. Check hook-debug.log for event:
   ```bash
   grep "EVENT=Stop" .claude/logs/hook-debug.log
   ```

5. Check tts.log for invocation:
   ```bash
   tail .claude/logs/tts.log
   ```

6. Test espeak-ng:
   ```bash
   espeak-ng "Test message"
   ```

---

### Wrong TTS Message
**Symptoms**: TTS speaking but message incorrect

**Steps**:
1. Check tts.log for actual message:
   ```bash
   tail .claude/logs/tts.log
   ```

2. Test message generation:
   ```bash
   source .claude/tts/tts-messages.sh
   export CLAUDE_PROJECT_DIR=$(pwd)
   export HOOK_EVENT="Stop"
   generate_message "completion"
   ```

3. Check environment variables in hook:
   ```bash
   # Add debug to tts-dispatcher.sh
   echo "HOOK_EVENT=$HOOK_EVENT CMD=$CLAUDE_COMMAND" >> .claude/logs/debug.log
   ```

---

### Performance Issues
**Symptoms**: Hooks running slow or blocking workflow

**Steps**:
1. Time hook execution:
   ```bash
   time (echo '{"hook_event_name":"Stop"}' | .claude/hooks/your-hook.sh)
   ```

2. Profile hook script:
   ```bash
   bash -x .claude/hooks/your-hook.sh < test-input.json 2>&1 | grep "^+"
   ```

3. Check for synchronous operations:
   ```bash
   grep -v "&" .claude/hooks/your-hook.sh | grep -E "espeak|curl|wget"
   ```

## Custom Logging

### Add Logging to Hooks
```bash
#!/usr/bin/env bash
# Your hook script

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
LOG_FILE="$LOG_DIR/my-hook.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log with timestamp
log_message() {
  echo "[$(date -Iseconds)] $1" >> "$LOG_FILE"
}

# Example usage
log_message "Hook started: $HOOK_EVENT"
# ... your hook logic ...
log_message "Hook completed"
```

### Structured Logging
```bash
# Log as JSON for easy parsing
log_json() {
  local level="$1"
  local message="$2"
  echo "{\"timestamp\":\"$(date -Iseconds)\",\"level\":\"$level\",\"message\":\"$message\"}" >> "$LOG_FILE"
}

log_json "info" "Processing event: $HOOK_EVENT"
log_json "error" "Failed to process: $ERROR_MSG"
```

### Conditional Logging
```bash
# Only log if debug enabled
DEBUG="${DEBUG:-false}"

debug_log() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "[DEBUG] $1" >> "$LOG_FILE"
  fi
}

debug_log "Parsed input: $HOOK_INPUT"
```

## Log Analysis

### Event Frequency
```bash
# Events per hour
cat .claude/logs/hook-debug.log | cut -d']' -f1 | cut -d'T' -f2 | cut -d':' -f1 | sort | uniq -c

# Events per day
cat .claude/logs/hook-debug.log | cut -d'T' -f1 | tr -d '[' | sort | uniq -c
```

### TTS Statistics
```bash
# Notifications per category
grep -o "\[[^]]*\]" .claude/logs/tts.log | sort | uniq -c

# Average messages per day
DAYS=$(( ($(date +%s) - $(stat -c %Y .claude/logs/tts.log)) / 86400 + 1 ))
TOTAL=$(wc -l < .claude/logs/tts.log)
echo "Average: $(( $TOTAL / $DAYS )) messages/day"
```

### Error Detection
```bash
# Find error patterns
grep -i "error\|fail\|exception" .claude/logs/*.log

# Hook failures (non-zero exit)
# (Note: Hooks should always exit 0, but check implementation)
```

## Best Practices

### Log Levels
Use consistent log levels in custom hooks:
- **DEBUG**: Detailed diagnostic information
- **INFO**: General informational messages
- **WARN**: Warning messages
- **ERROR**: Error messages

### Log Privacy
Avoid logging sensitive information:
- No passwords or secrets
- No file contents
- No user input verbatim
- Sanitize file paths if sensitive

### Log Retention
```bash
# Keep logs for reasonable time
# 30 days for debug logs
# 90 days for error logs
# Archive important events
```

### Log Size
Monitor log file sizes:
```bash
# Check log sizes
du -h .claude/logs/*.log

# Alert if too large
MAX_SIZE_MB=10
SIZE_MB=$(du -m .claude/logs/hook-debug.log | cut -f1)
if [[ $SIZE_MB -gt $MAX_SIZE_MB ]]; then
  echo "Log file too large: ${SIZE_MB}MB"
fi
```

## Documentation Standards

All logs documentation follows standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md) for complete standards.

## Navigation

### Related
- [← Parent Directory](../README.md)
- [hooks/](../hooks/README.md) - Hooks that write logs
- [tts/](../tts/README.md) - TTS system logging

## Quick Reference

### Viewing Logs
```bash
# Recent hook events
tail .claude/logs/hook-debug.log

# Recent TTS messages
tail .claude/logs/tts.log

# Follow logs live
tail -f .claude/logs/hook-debug.log

# Search logs
grep "ERROR" .claude/logs/*.log
```

### Log Cleanup
```bash
# Clear all logs
> .claude/logs/hook-debug.log
> .claude/logs/tts.log

# Archive logs
mkdir -p .claude/logs/archive
mv .claude/logs/*.log .claude/logs/archive/
```

### Analysis
```bash
# Event counts
grep -o "EVENT=[^ ]*" .claude/logs/hook-debug.log | sort | uniq -c

# TTS category counts
grep -o "\[[^]]*\]" .claude/logs/tts.log | sort | uniq -c

# Errors
grep -i error .claude/logs/*.log
```
