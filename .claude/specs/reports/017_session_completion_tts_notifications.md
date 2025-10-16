# Session Completion TTS Notifications Research Report

## Metadata
- **Date**: 2025-10-01
- **Scope**: Voice notification system for Claude Code session completion events
- **Primary Directory**: /home/benjamin/.config/.claude
- **Files Analyzed**: settings.local.json, hooks/*, Claude Code documentation
- **Research Focus**: Hook events, TTS integration, notification format design

## Executive Summary

Claude Code v2.0.1 provides a **Stop hook event** that fires when the main agent finishes responding and needs user input. This can be combined with **SessionEnd** and **UserPromptSubmit** hooks to create a comprehensive voice notification system using NixOS text-to-speech utilities (espeak-ng, festival, or pico-tts).

**Key Findings**:
1. **Stop hook** is the primary event for "session completed, needs input"
2. **SessionEnd** provides session termination notifications
3. **Notification hook** triggers when Claude has been waiting for input
4. NixOS supports multiple TTS options with espeak-ng being most widely available
5. Context can include: working directory, git branch, task summary, next steps

## Available Hook Events for Session Completion

### 1. Stop Hook (Primary Event)
**Trigger**: When main Claude Code agent finishes responding
**Environment Variables Available**:
- `$CLAUDE_PROJECT_DIR` - Working directory
- `$CLAUDE_COMMAND` - Last command executed (e.g., "/implement")
- `$CLAUDE_DURATION_MS` - Execution duration
- `$CLAUDE_STATUS` - Status (success/failure)

**Use Case**: "I've completed [task], ready for next input"

### 2. SessionEnd Hook
**Trigger**: When session ends
**Reasons**:
- `clear` - Session cleared
- `logout` - User logged out
- `prompt_input_exit` - Exited during prompt input
- `other` - Other termination reasons

**Use Case**: "Session ended: [reason]"

### 3. Notification Hook
**Trigger**: When Claude needs permission or has been waiting for input
**Use Case**: Reminder that Claude is waiting

### 4. UserPromptSubmit Hook
**Trigger**: When user submits a prompt
**Use Case**: Acknowledge prompt received (optional)

## Text-to-Speech Options on NixOS

### Option 1: espeak-ng (Recommended for Simplicity)
**Package**: `espeak-ng` or `espeak`
**Pros**:
- Widely available in nixpkgs
- Simple command-line interface
- Fast, low latency
- Supports 40+ languages
- Lightweight

**Cons**:
- Robotic voice quality
- Less natural sounding

**Usage**:
```bash
espeak-ng "Session completed. Implemented Phase 3. Ready for next task."
```

**Installation**:
```nix
environment.systemPackages = [ pkgs.espeak-ng ];
```

### Option 2: festival
**Package**: `festival`
**Pros**:
- Better voice quality with CMU voices
- Configurable voices (e.g., cmu_us_slt_arctic_hts)
- More natural than espeak

**Cons**:
- Larger installation
- Slower than espeak
- Requires voice data packages

**Usage**:
```bash
echo "Session completed" | festival --tts
```

### Option 3: pico-tts
**Package**: `svox` (pico2wave)
**Pros**:
- Less robotic than espeak
- Good quality for size
- Supports English, German, French, Italian, Spanish

**Cons**:
- Requires WAV file generation then playback
- Two-step process

**Usage**:
```bash
pico2wave -w /tmp/speech.wav "Session completed" && aplay /tmp/speech.wav
```

## Proposed Implementation Design

### Hook: session-completion-notify.sh

**Location**: `.claude/hooks/session-completion-notify.sh`

**Trigger Events**:
1. **Stop** (primary) - Claude completed response, needs input
2. **SessionEnd** (secondary) - Session terminated

**Information to Include**:
1. **Context Prefix**: Directory and branch
2. **Completion Summary**: What was done (1 sentence)
3. **Next Steps**: What's needed next (if anything)

### Voice Report Format

**Structure**:
```
[Directory: <basename>] [Branch: <branch>]. <Completion summary>. <Next steps or "Ready for input">.
```

**Examples**:
```
Directory config. Branch master. Implemented Phase 3 hooks. Ready for input.

Directory neovim. Branch feature-auth. All tests passing. Ready to commit.

Directory config. Branch master. Session ended. Logged out.

Directory api-server. Branch fix-cache. Debug investigation complete. Review report in specs/reports/018.
```

### Implementation Approach

#### 1. Extract Last Response Context

The hook needs to capture what Claude just completed. Options:

**A. Parse Command Output** (Simple)
- Use `$CLAUDE_COMMAND` to know what was running
- Generic message based on command type
- No detailed task info

**B. State File Approach** (Detailed)
- Claude writes completion summary to `.claude/state/last-completion.txt` before responding
- Hook reads this file for TTS
- Provides specific task details

**C. Log Analysis** (Complex)
- Parse recent command output/logs
- Extract key completion details
- More fragile, harder to maintain

**Recommendation**: Start with **Approach A** (simple), optionally enhance with **Approach B** if detailed summaries are needed.

### Hook Implementation (Approach A - Simple)

```bash
#!/run/current-system/sw/bin/bash
# Session Completion TTS Notification Hook
# Trigger: Stop event

# TTS command (configurable)
TTS_CMD="${TTS_CMD:-espeak-ng}"

# Get context
DIR_NAME=$(basename "$CLAUDE_PROJECT_DIR")
BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null || echo "no-branch")
COMMAND="${CLAUDE_COMMAND:-unknown}"
STATUS="${CLAUDE_STATUS:-unknown}"

# Build message based on command
case "$COMMAND" in
  /implement*)
    MESSAGE="Implemented plan phase. Check for test results."
    ;;
  /orchestrate*)
    MESSAGE="Workflow step complete. Review output."
    ;;
  /debug*)
    MESSAGE="Debug investigation complete. Review report."
    ;;
  /test*)
    MESSAGE="Tests executed. Check results."
    ;;
  /document*)
    MESSAGE="Documentation updated. Review changes."
    ;;
  *)
    if [ "$STATUS" = "success" ]; then
      MESSAGE="Task complete. Ready for input."
    else
      MESSAGE="Task complete with errors. Review output."
    fi
    ;;
esac

# Construct full report
REPORT="Directory ${DIR_NAME}. Branch ${BRANCH}. ${MESSAGE}"

# Speak it
$TTS_CMD "$REPORT" 2>/dev/null &

exit 0
```

### Hook Implementation (Approach B - Detailed with State File)

**Modified Hook**:
```bash
#!/run/current-system/sw/bin/bash
# Session Completion TTS Notification Hook

TTS_CMD="${TTS_CMD:-espeak-ng}"
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/state/last-completion.txt"

# Get context
DIR_NAME=$(basename "$CLAUDE_PROJECT_DIR")
BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null || echo "no-branch")

# Read completion summary from state file
if [ -f "$STATE_FILE" ]; then
  TASK_SUMMARY=$(cat "$STATE_FILE")
  rm "$STATE_FILE"  # Clean up after reading
else
  TASK_SUMMARY="Task complete. Ready for input."
fi

# Construct report
REPORT="Directory ${DIR_NAME}. Branch ${BRANCH}. ${TASK_SUMMARY}"

# Speak it
$TTS_CMD "$REPORT" 2>/dev/null &

exit 0
```

**Claude's Responsibility** (would need to be added to commands):
Before completing a response, write summary to state file:
```bash
echo "Implemented Phase 3 hooks. All tests passing." > .claude/state/last-completion.txt
```

### SessionEnd Hook

**Location**: `.claude/hooks/session-end-notify.sh`

```bash
#!/run/current-system/sw/bin/bash
# Session End TTS Notification

TTS_CMD="${TTS_CMD:-espeak-ng}"
DIR_NAME=$(basename "$CLAUDE_PROJECT_DIR")
REASON="${CLAUDE_SESSION_END_REASON:-unknown}"

case "$REASON" in
  clear)
    MESSAGE="Session cleared."
    ;;
  logout)
    MESSAGE="Logged out."
    ;;
  prompt_input_exit)
    MESSAGE="Session exited during prompt."
    ;;
  *)
    MESSAGE="Session ended."
    ;;
esac

REPORT="Directory ${DIR_NAME}. ${MESSAGE}"
$TTS_CMD "$REPORT" 2>/dev/null &

exit 0
```

## Configuration in settings.local.json

### Add Stop Hook for Completion Notifications

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-command-metrics.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-completion-notify.sh"
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
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-end-notify.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start-restore.sh"
          }
        ]
      }
    ]
  }
}
```

## TTS Voice Customization

### espeak-ng Voice Options

```bash
# List available voices
espeak-ng --voices

# Use specific voice (e.g., US English female)
espeak-ng -v en-us+f3 "Message"

# Adjust speed (words per minute, default 175)
espeak-ng -s 150 "Slower speech"

# Adjust pitch (0-99, default 50)
espeak-ng -p 40 "Lower pitch"
```

### festival Voice Options

```bash
# Install better voice
nix-env -iA nixpkgs.festival-freebsoft-utils
nix-env -iA nixpkgs.festvox-kallpc16k

# Use in hook
echo "$REPORT" | festival --tts
```

## NixOS System Configuration

### Declarative Installation

Add to `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    espeak-ng          # Primary TTS
    # festival         # Alternative TTS
    # alsa-utils       # For aplay if using pico-tts
  ];

  # Optional: Configure default TTS in environment
  environment.variables = {
    TTS_CMD = "espeak-ng -v en-us+f3 -s 160";
  };
}
```

### User-level Installation

```bash
nix-env -iA nixpkgs.espeak-ng
```

## Implementation Recommendations

### Tier 1: Minimal Implementation (Recommended Start)

1. **Create session-completion-notify.sh** (Approach A - Simple)
   - Use `$CLAUDE_COMMAND` for generic messages
   - Include directory and branch context
   - Use espeak-ng for TTS

2. **Add Stop hook to settings.local.json**
   - Trigger TTS on every completion

3. **Install espeak-ng on NixOS**
   - Simple, lightweight, reliable

**Effort**: ~30 minutes
**Value**: Immediate audio feedback when Claude completes

### Tier 2: Enhanced Implementation

1. **Add SessionEnd hook** for termination notifications
2. **Customize espeak-ng voice** for better quality
3. **Add conditional TTS** (only speak if waiting >30 seconds)

**Effort**: +1 hour
**Value**: More comprehensive notification coverage

### Tier 3: Advanced Implementation

1. **Implement Approach B** (state file with detailed summaries)
2. **Modify commands** to write completion summaries
3. **Use festival** with better voices
4. **Add Notification hook** for idle reminders
5. **Configure per-command messages** in hook

**Effort**: +3-4 hours
**Value**: Highly detailed, context-aware notifications

## Testing Approach

### Test Hook Directly

```bash
# Test TTS
espeak-ng "Test message from Claude Code"

# Test hook with environment variables
export CLAUDE_PROJECT_DIR="$PWD"
export CLAUDE_COMMAND="/implement"
export CLAUDE_STATUS="success"
./.claude/hooks/session-completion-notify.sh
```

### Test in Claude Code

1. Run a simple command: `/test`
2. Wait for completion
3. Verify TTS notification is spoken
4. Check hook execution in background

### Debug Issues

```bash
# Check TTS is installed
which espeak-ng

# Test TTS directly
espeak-ng "Hello world"

# Check hook is executable
ls -la .claude/hooks/session-completion-notify.sh

# View hook output
# (hooks run in background, errors to /dev/null in examples above)
# Remove 2>/dev/null to see errors
```

## Potential Issues and Solutions

### Issue 1: Hook Not Triggering
**Cause**: Hook configuration error or file permissions
**Solution**:
- Verify hook in settings.local.json
- Check hook file is executable: `chmod +x`
- Verify path uses `$CLAUDE_PROJECT_DIR`

### Issue 2: No Audio Output
**Cause**: TTS not installed or audio system issue
**Solution**:
- Install espeak-ng: `nix-env -iA nixpkgs.espeak-ng`
- Test audio system: `speaker-test`
- Check PulseAudio/PipeWire is running

### Issue 3: Garbled or Missing Context
**Cause**: Environment variables not set
**Solution**:
- Check `$CLAUDE_PROJECT_DIR` is set
- Verify git command works in project directory
- Add fallbacks in hook script

### Issue 4: TTS Too Fast/Slow/Robotic
**Cause**: Default espeak settings
**Solution**:
- Adjust speed: `-s 140` (slower) to `-s 200` (faster)
- Change voice: `-v en-us+f3` (female) or `-v en-us+m3` (male)
- Try festival for better quality

## Alternative: Visual Notifications

If audio notifications are problematic, consider:

### notify-send (Desktop Notifications)

```bash
#!/run/current-system/sw/bin/bash
# Visual notification alternative

DIR_NAME=$(basename "$CLAUDE_PROJECT_DIR")
BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null || echo "no-branch")
MESSAGE="Task complete. Ready for input."

notify-send "Claude Code - $DIR_NAME" "Branch: $BRANCH\n$MESSAGE" -u normal

exit 0
```

**Requires**: `libnotify` package in NixOS

## Future Enhancements

1. **Configurable TTS Engine**: Allow user to choose espeak/festival/pico in config
2. **Volume Control**: Adjust TTS volume based on time of day
3. **Summary Extraction**: Parse command output for automatic summary generation
4. **Multi-language Support**: Detect project language, speak in that language
5. **Error-specific Messages**: Different TTS for errors vs success
6. **Integration with Notification Daemon**: Combine TTS with visual notifications

## References

### Claude Code Documentation
- [Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks)
- Hook events: Stop, SessionStart, SessionEnd, UserPromptSubmit, Notification

### Files in This Project
- `.claude/settings.local.json` - Hook configuration
- `.claude/hooks/post-command-metrics.sh` - Existing Stop hook example
- `.claude/hooks/session-start-restore.sh` - Existing SessionStart hook example

### NixOS TTS Resources
- [espeak-ng package](https://search.nixos.org/packages?query=espeak)
- [festival package](https://search.nixos.org/packages?query=festival)
- [TTS on Linux Guide](https://linuxvox.com/blog/tts-linux/)

### Environment Variables Available in Hooks
- `$CLAUDE_PROJECT_DIR` - Working directory
- `$CLAUDE_COMMAND` - Last command executed
- `$CLAUDE_DURATION_MS` - Execution duration
- `$CLAUDE_STATUS` - success/failure
- `$CLAUDE_SESSION_END_REASON` - Reason for session end (SessionEnd hook only)

## Conclusion

Implementing TTS notifications for Claude Code session completion is straightforward using the **Stop hook event** combined with NixOS text-to-speech utilities. The recommended approach:

1. Start with **espeak-ng** for simplicity and reliability
2. Use **Approach A (Simple)** for generic command-based messages
3. Include **directory and branch context** for orientation
4. Optionally add **SessionEnd hook** for termination notifications
5. Enhance with **Approach B (State file)** if detailed task summaries are desired

**Estimated Implementation Time**: 30 minutes - 4 hours depending on tier
**Immediate Value**: Audio confirmation when Claude completes tasks and needs input
**Future Potential**: Rich, context-aware voice notifications for comprehensive workflow awareness
