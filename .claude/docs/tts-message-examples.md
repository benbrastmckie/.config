# TTS Message Examples

Complete reference of TTS message templates for all categories.

## Message Format

**Simplified format for completion notifications:**
```
[directory], [branch]
```

The comma provides a natural pause between directory and branch name.

**Examples:**
```
"config, master"
"neovim, feature-refactor"
"api-server, develop"
"dotfiles, main"
```

## Completion Messages

### All Commands

**Pattern**: `"[directory], [branch]"`

Completion messages are now minimal - just announcing the directory and branch to help identify which session is ready for input.

#### Examples
```
"config, master"           # Working in .config directory on master branch
"neovim, feature-vim"      # Working in neovim directory on feature-vim branch
"backend, develop"         # Working in backend directory on develop branch
"ModelChecker, main"       # Working in ModelChecker directory on main branch
```

### Purpose

The simplified message format:
- **Identifies the session**: Know which Claude Code window is ready
- **Minimal interruption**: Quick, non-verbose announcement
- **Branch awareness**: Instantly know which branch you're on
- **Directory context**: Root directory name (not full path)

### State File Support (Currently Unused)

State file support (`.claude/state/last-completion.json`) is still available for detailed summaries but not used in the default completion messages. If you want more detailed messages, you can customize `generate_completion_message()` in `.claude/lib/tts-messages.sh`.

## Permission Messages

**Pattern**: `"Permission needed. [Tool]. [Context]."`

### Common Tools

```
"Permission needed. Bash. Git commit for Phase 2."
"Permission needed. Web search. Research authentication patterns."
"Permission needed. Edit. Update configuration file."
"Permission needed. Task. Launch research agent."
```

## Progress Messages

**Pattern**: `"Progress update. [Agent] complete. [Result]."`

### Subagent Types

```
"Progress update. Research specialist complete. Found 3 patterns."
"Progress update. Plan architect complete. Generated 5 phase plan."
"Progress update. Code writer complete. Implemented authentication."
"Progress update. Test specialist complete. 15 tests passed, 2 failed."
"Progress update. Debug specialist complete. Root cause identified."
"Progress update. Doc writer complete. Updated 3 documentation files."
```

## Error Messages

**Pattern**: `"Error in [command]. [Error type]. Review output."`

### Error Types

```
"Error in implement. Tests failed in Phase 2. Review output."
"Error in test. Linting errors found. Review output."
"Error in orchestrate. Planning phase timeout. Review output."
"Error in debug. Investigation incomplete. Review output."
"Error in build. Compilation failed. Review output."
```

## Idle Messages

**Pattern**: `"Still waiting for input. Last action: [command]. [Duration]."`

### Duration Formatting

```
"Still waiting for input. Last action: implement. Waiting 1 minute."
"Still waiting for input. Last action: test. Waiting 2 minutes."
"Still waiting for input. Last action: debug. Waiting 5 minutes."
```

## Session Messages

### Session Start

**Pattern**: `"Session started. Directory [name]. Branch [branch]."`

```
"Session started. Directory config. Branch master."
"Session started. Directory api-server. Branch feature-auth."
```

### Session End

**Pattern**: `"Session ended. [Reason]. [Pending info]."`

```
"Session ended. Logged out. No pending workflows."
"Session ended. Session cleared. 1 workflow in progress saved."
"Session ended. Timeout. All work saved."
```

## Tool Messages

### Pre-Tool Use

**Pattern**: `"[Tool] starting. [Context]."`

```
"Bash starting. Running test suite."
"Task starting. Research specialist."
"Web search starting. Authentication patterns."
```

### Post-Tool Use

**Pattern**: `"[Tool] complete."`

```
"Bash complete."
"Task complete."
"Web search complete."
```

## Prompt Acknowledgment Messages

**Pattern**: `"Prompt received. [Brief]."`

```
"Prompt received. Implement command."
"Prompt received. Debug investigation."
"Prompt received. Test execution."
```

## Compact Messages

**Pattern**: `"Compacting context. [Trigger]. Workflow may pause."`

```
"Compacting context. Manual compact. Workflow may pause."
"Compacting context. Auto compact. Workflow may pause."
```

## Customizing Messages

### Method 1: State Files

Write detailed state to `.claude/state/last-completion.json`:

```json
{
  "command": "/implement",
  "phase": "Phase 3",
  "summary": "Implemented hooks infrastructure",
  "status": "success",
  "next_steps": "Ready for Phase 4",
  "duration_ms": 45000
}
```

Result:
```
"Directory config. Branch master. Implemented hooks infrastructure. Ready for Phase 4."
```

### Method 2: Edit Message Generator

Edit `.claude/lib/tts-messages.sh` to customize templates:

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

Use the test utility to hear all message types:

```bash
# Test all categories
./.claude/bin/test-tts.sh

# Test specific category
./.claude/bin/test-tts.sh completion
./.claude/bin/test-tts.sh error

# Test without audio (see messages only)
./.claude/bin/test-tts.sh --silent
```
