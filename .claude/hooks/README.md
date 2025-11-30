# Hooks Directory

Event-driven scripts that execute automatically during Claude Code lifecycle events. Hooks enable automation for metrics collection, notifications, state management, and custom workflow extensions.

## Purpose

Hooks provide automated responses to Claude Code events:

- **Metrics collection** on command completion
- **TTS notifications** for workflow events
- **State restoration** on session start
- **Custom automation** for project-specific needs

## Hook Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Event (Stop, SessionStart, etc.)               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ settings.local.json Hook Registry                          │
│ Matches event to registered hooks                          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Hook Script Execution                                       │
├─────────────────────────────────────────────────────────────┤
│ • Receives JSON input via stdin                             │
│ • Parses event data (event name, command, status, etc.)     │
│ • Performs action (log, notify, restore, etc.)             │
│ • Exits 0 (non-blocking)                                    │
└─────────────────────────────────────────────────────────────┘
```

## Available Hook Events

### Stop
Triggered when Claude completes a response and is ready for input.

**Use Cases**:
- Collect command execution metrics
- Send completion notifications
- Save command state
- Cleanup temporary resources

**Example Hooks**:
- `post-command-metrics.sh`
- `tts-dispatcher.sh`
- `post-buffer-opener.sh`

---

### SessionStart
Triggered when a Claude session begins (startup or resume).

**Use Cases**:
- Restore interrupted workflows
- Check for pending state
- Initialize session resources
- Welcome notifications

**Example Hooks**:
- `tts-dispatcher.sh`

---

### SessionEnd
Triggered when a Claude session terminates.

**Use Cases**:
- Save session state
- Cleanup resources
- Goodbye notifications
- Backup important data

**Example Hooks**:
- `tts-dispatcher.sh`

---

### SubagentStop
Triggered when a subagent completes a task within a larger workflow.

**Use Cases**:
- Progress notifications
- Subagent metrics
- Intermediate state saves
- Workflow coordination

**Example Hooks**:
- `tts-dispatcher.sh`

---

### Notification
Triggered for permission requests and idle alerts.

**Use Cases**:
- Permission request notifications
- Idle reminders
- Attention alerts
- User interaction prompts

**Example Hooks**:
- `tts-dispatcher.sh`

---

### PreToolUse (Optional)
Triggered before significant tool usage.

**Use Cases**:
- Tool execution logging
- Pre-execution setup
- Resource allocation
- Permission verification

**Status**: Not currently registered by default

---

### PostToolUse (Optional)
Triggered after significant tool usage.

**Use Cases**:
- Tool execution metrics
- Cleanup after tool use
- Result logging
- Error handling

**Status**: Not currently registered by default

---

### UserPromptSubmit (Optional)
Triggered when user submits a prompt.

**Use Cases**:
- Prompt acknowledgment
- Input logging
- Quick confirmations
- User activity tracking

**Status**: Not currently registered by default

---

### PreCompact (Optional)
Triggered before context compaction.

**Use Cases**:
- Compaction warnings
- State preservation
- Resource optimization
- User notification

**Status**: Not currently registered by default

## Hook Scripts

### post-command-metrics.sh
**Purpose**: Collect command execution metrics for performance analysis

**Triggered By**: Stop event

**Input** (via JSON stdin):
- `hook_event_name`: "Stop"
- `command`: Command that was executed
- `duration_ms`: Execution duration in milliseconds
- `status`: "success" or "error"
- `cwd`: Working directory

**Output**: Appends JSONL entry to `.claude/data/metrics/YYYY-MM.jsonl`

**Format**:
```json
{"timestamp":"2025-10-01T12:34:56Z","operation":"implement","duration_ms":15234,"status":"success"}
```

**Features**:
- Monthly log rotation
- JSONL format for easy parsing
- Minimal overhead
- Non-blocking execution

---

### tts-dispatcher.sh
**Purpose**: Central dispatcher for all TTS notifications

**Triggered By**: Stop, SessionStart, SessionEnd, SubagentStop, Notification

**Input** (via JSON stdin):
- `hook_event_name`: Event type
- `command`: Command name (if applicable)
- `status`: Status (success/error)
- `cwd`: Working directory
- `message`: Notification message (for Notification events)

**Actions**:
1. Parse JSON input from stdin
2. Detect notification category from event
3. Check if category enabled in config
4. Generate context-aware message
5. Speak message with category-specific voice

**Features**:
- 9 notification categories
- Voice customization per category
- Silent command support
- Async execution (non-blocking)
- Debug logging

**Configuration**: See [../tts/README.md](../tts/README.md)

---

### post-buffer-opener.sh
**Purpose**: Automatically open workflow artifacts in Neovim after command completion

**Triggered By**: Stop event

**Design Philosophy**: Zero overhead outside Neovim. The hook checks `$NVIM` as its first operation
and exits immediately (< 1ms) if not in a Neovim terminal. No JSON parsing, no file operations,
no side effects. Claude Code works identically whether this hook is present or not.

**Graceful Degradation**: All failure modes result in silent exit 0. Running outside Neovim,
RPC failures, missing completion signals - all handled silently with no user-visible errors.

**Zero Undo Impact**: Buffer opening creates a new buffer; it does not modify any existing
buffer's undo tree or create undo entries in any buffer.

**One-File Guarantee**: Opens at most one file per command execution, selecting the primary
artifact via priority logic (plans > summaries > debug reports > research reports).

**Input** (via JSON stdin, only parsed if $NVIM is set):
- `hook_event_name`: "Stop"
- `command`: Command that was executed
- `status`: "success" or "error"
- `cwd`: Working directory

**Actions** (only when inside Neovim terminal):
1. Check `$NVIM` - exit 0 immediately if unset (FIRST CHECK)
2. Check `BUFFER_OPENER_ENABLED` - exit 0 if disabled
3. Access terminal buffer output via RPC
4. Extract ALL completion signals (may be multiple)
5. Select PRIMARY artifact only (one file) using priority logic
6. Open selected artifact in Neovim with context-aware behavior

**Priority Logic**:
| Priority | Signal Type | Commands |
|----------|-------------|----------|
| 1 (Highest) | PLAN_CREATED, PLAN_REVISED | /plan, /repair, /optimize-claude, /revise |
| 2 | IMPLEMENTATION_COMPLETE (summary_path) | /build |
| 3 | DEBUG_REPORT_CREATED | /debug |
| 4 (Lowest) | REPORT_CREATED | /research, /errors |

**Example**: When /optimize-claude creates 4 research reports + 1 plan, hook opens only the plan.

**Requirements** (only when inside Neovim):
- `$NVIM` environment variable (set automatically by Neovim terminal)
- Commands that output completion signals

**Configuration**:
- `BUFFER_OPENER_ENABLED`: Enable/disable feature (default: true)
- `BUFFER_OPENER_DEBUG`: Enable debug logging (default: false)
- `BUFFER_OPENER_DELAY`: Delay before reading terminal buffer in seconds (default: 0.3)

**Buffer Opening Configuration**

The buffer opening feature uses a configurable delay to handle timing issues with multi-block bash commands. When Claude finishes responding, the Stop hook fires, but subsequent bash blocks may still be executing. The delay ensures completion signals are present in the terminal buffer before the hook reads it.

**Timing Architecture**:
```
1. Command starts (Block 1: setup and Task tool delegation)
2. Claude finishes responding → Stop hook fires
3. [Delay period] Hook waits for remaining blocks to execute
4. Hook reads terminal buffer (now includes Block 2 output)
5. Hook finds completion signal and opens buffer
```

**Configuration Variables**:

| Variable | Default | Description |
|----------|---------|-------------|
| `BUFFER_OPENER_ENABLED` | `true` | Enable/disable automatic buffer opening |
| `BUFFER_OPENER_DEBUG` | `false` | Enable diagnostic logging to `.claude/tmp/buffer-opener-debug.log` |
| `BUFFER_OPENER_DELAY` | `0.3` | Delay in seconds before reading terminal buffer |

**Tuning Guide** (adjust `BUFFER_OPENER_DELAY` for your system):

| System Type | Recommended Delay | Notes |
|-------------|-------------------|-------|
| Fast local system | `0.2` | Modern hardware with fast I/O |
| Normal system | `0.3` | Default - works for most systems |
| Slow/loaded system | `0.5` | Heavy CPU load or slow I/O |
| Remote/SSH connection | `0.8` | Network latency compensation |
| Diagnostic mode | `0` | Disable delay to test timing issues |

**Usage Examples**:

```bash
# Default configuration (300ms delay)
export BUFFER_OPENER_DEBUG=false
export BUFFER_OPENER_DELAY=0.3

# Fast system optimization (200ms delay)
export BUFFER_OPENER_DELAY=0.2

# Slow system tuning (500ms delay)
export BUFFER_OPENER_DELAY=0.5

# Enable diagnostic mode (immediate read - expect failures)
export BUFFER_OPENER_DEBUG=true
export BUFFER_OPENER_DELAY=0

# Disable feature entirely
export BUFFER_OPENER_ENABLED=false
```

**Troubleshooting**

**Buffers not opening automatically**:
1. Enable debug logging: `export BUFFER_OPENER_DEBUG=true`
2. Run a workflow command (e.g., `/research "test topic"`)
3. Check debug log: `cat ~/.config/.claude/tmp/buffer-opener-debug.log`
4. Look for:
   - "Block 2 ABSENT" message - confirms timing race
   - "REPORT_CREATED signal ABSENT" - signal not found
5. If timing race confirmed, increase delay: `export BUFFER_OPENER_DELAY=0.5`
6. Test again and examine debug log
7. If Block 2 now present and signal found, buffer should open

**Debug log shows "Failed to get terminal output"**:
- Verify running inside Neovim terminal (check `$NVIM` is set)
- Verify `nvim` command available in PATH
- Check Neovim RPC is functional: `nvim --server $NVIM --remote-expr '1+1'`

**Buffers open but at wrong file**:
- Check priority logic (plans > summaries > debug reports > research reports)
- Multiple signals may be present, hook selects highest priority
- Example: `/optimize-claude` creates 4 research reports + 1 plan → opens plan only

**High latency (>500ms) to buffer open**:
- Reduce delay if system is fast: `export BUFFER_OPENER_DELAY=0.2`
- Balance reliability vs latency based on success rate
- Target: ≥95% success rate with <500ms latency

**Signal extraction fails (debug log shows signal present but "No completion signal found")**:
- Terminal buffer may contain ANSI escape codes that break pattern matching
- The hook automatically strips ANSI codes before extraction (Plan 978 fix)
- Debug log shows "removed X ANSI bytes" - if X is large, this was the issue
- Fallback sed-based extraction activates if primary grep fails (logged as "Used sed fallback")
- If still failing, check for unusual terminal formatting

---

### pre-commit-library-sourcing.sh
**Purpose**: Validate library sourcing patterns in staged command files

**Triggered By**: Git pre-commit (manual installation required)

**Input**: None (reads git staged files)

**Actions**:
1. Detect staged .claude/commands/*.md files
2. Run library sourcing linter on staged files
3. Block commit if violations found
4. Output clear error messages with remediation steps

**Features**:
- Validates three-tier sourcing pattern
- Detects bare error suppression on critical libraries
- Warns on missing defensive function checks
- Supports bypass with --no-verify

**Installation**:
```bash
ln -sf ../../.claude/hooks/pre-commit-library-sourcing.sh .git/hooks/pre-commit
```

**Documentation**: See [Pre-Commit Hooks Guide](../docs/guides/development/pre-commit-hooks.md)

## Hook Input Format

Claude Code passes hook data as JSON via stdin:

```json
{
  "hook_event_name": "Stop",
  "command": "/implement",
  "status": "success",
  "duration_ms": 15234,
  "cwd": "/home/user/project",
  "message": "Additional context for some events"
}
```

### Parsing Hook Input

Hooks must read and parse JSON from stdin:

```bash
#!/usr/bin/env bash
# Read JSON input
HOOK_INPUT=$(cat)

# Parse with jq (preferred)
if command -v jq &>/dev/null; then
  HOOK_EVENT=$(echo "$HOOK_INPUT" | jq -r '.hook_event_name // "unknown"')
  CLAUDE_COMMAND=$(echo "$HOOK_INPUT" | jq -r '.command // ""')
  CLAUDE_STATUS=$(echo "$HOOK_INPUT" | jq -r '.status // "success"')
else
  # Fallback parsing without jq
  HOOK_EVENT=$(echo "$HOOK_INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
fi

# Export for use in hook logic
export HOOK_EVENT CLAUDE_COMMAND CLAUDE_STATUS
```

## Hook Registration

Hooks are registered in `.claude/settings.local.json`:

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
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": []
      }
    ]
  }
}
```

### Registration Fields

- **matcher**: Regex pattern to match event details (use ".*" for all)
- **type**: Always "command" for script hooks
- **command**: Absolute path to hook script (use $CLAUDE_PROJECT_DIR)

## Creating Custom Hooks

### Step 1: Create Hook Script
```bash
#!/usr/bin/env bash
# Your custom hook
# Purpose: Describe what this hook does

set -eo pipefail

# Read JSON input
HOOK_INPUT=$(cat)

# Parse required fields
# ... parsing logic ...

# Perform hook action
# ... your logic here ...

# Always exit successfully (non-blocking)
exit 0
```

### Step 2: Make Executable
```bash
chmod +x .claude/hooks/your-hook.sh
```

### Step 3: Register in settings.local.json
```json
{
  "hooks": {
    "YourEvent": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/your-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### Step 4: Test
Trigger the event and check hook execution:
```bash
tail -f .claude/data/logs/your-hook.log
```

## Best Practices

### Non-Blocking Execution
- **Always exit 0**: Never fail and block workflow
- **Async operations**: Use background processes (&) for slow operations
- **Quick execution**: Keep hooks fast (< 100ms ideal)
- **Timeout protection**: Don't wait indefinitely for resources

### Error Handling
```bash
# Check for required tools
if ! command -v jq &>/dev/null; then
  exit 0  # Fail silently if dependency missing
fi

# Graceful degradation
if [[ ! -f "$REQUIRED_FILE" ]]; then
  exit 0  # Don't block on missing files
fi
```

### Logging
```bash
# Create log directory
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"

# Log with timestamp
echo "[$(date -Iseconds)] Hook executed: $HOOK_EVENT" >> "$LOG_DIR/hook.log"
```

## Debugging Hooks

### Enable Debug Logging
```bash
# Add to your hook
DEBUG=true

if [[ "$DEBUG" == "true" ]]; then
  echo "[DEBUG] Event: $HOOK_EVENT" >> "$LOG_DIR/debug.log"
  echo "[DEBUG] Input: $HOOK_INPUT" >> "$LOG_DIR/debug.log"
fi
```

### Test Manually
```bash
# Simulate hook input
echo '{"hook_event_name":"Stop","command":"/test","status":"success"}' | \
  .claude/hooks/your-hook.sh
```

### Monitor Execution
```bash
# Watch hook debug log
tail -f .claude/data/logs/hook-debug.log

# Check TTS log
tail -f .claude/data/logs/tts.log
```

### Verify Registration
```bash
# Check settings
cat .claude/settings.local.json | jq '.hooks'

# List all registered hooks
cat .claude/settings.local.json | jq -r '.hooks | to_entries[] | "\(.key): \(.value[0].hooks[].command)"'
```

## Security Considerations

### Path Validation
```bash
# Always use $CLAUDE_PROJECT_DIR for paths
SAFE_PATH="$CLAUDE_PROJECT_DIR/.claude/data/logs/data.log"

# Validate before using
if [[ ! "$SAFE_PATH" =~ ^"$CLAUDE_PROJECT_DIR" ]]; then
  exit 0  # Path outside project, reject
fi
```

### Input Sanitization
```bash
# Don't execute arbitrary input
# Parse and validate before use
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.command')

# Validate against whitelist
case "$COMMAND" in
  /implement|/test|/plan)
    # Safe commands
    ;;
  *)
    # Unknown command, log but don't fail
    exit 0
    ;;
esac
```

### Resource Limits
```bash
# Timeout for long operations
timeout 5s long_operation || true

# Limit file sizes
head -n 1000 large_file.log > processed.log
```

## Neovim Integration

Hooks in this directory are integrated with the Neovim artifact picker, organized by hook events.

### Accessing Hooks via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [Hook Events] section in picker

### Picker Features for Hooks

**Visual Display**:
- Hooks grouped by event (Stop, SessionStart, Notification, etc.)
- Event headers show `*` if ANY associated hook is local
- Individual hooks shown with local/global indicators
- Event descriptions displayed (e.g., "After command completion")

**Display Format**:
```
* [Hook Event] Stop            After command completion
  ├─ post-command-metrics.sh   Collect command metrics
  └─ tts-dispatcher.sh         Voice notification
```

**Quick Actions**:
- `<CR>` - Open hook script for editing
- `<C-l>` - Load hook locally to project
- `<C-g>` - Update from global version
- `<C-s>` - Save local hook to global
- `<C-e>` - Edit hook file in buffer
- `<C-u>`/`<C-d>` - Scroll preview up/down

**Example Workflow**:
```vim
" Open picker
:ClaudeCommands

" Navigate to [Hook Event] Stop
" See all hooks registered for Stop event
" Press j to select post-command-metrics.sh
" Press <C-e> to edit hook script
```

### Hook Event Organization

The picker displays hooks organized by event type:

- **Stop** - After command completion
- **SessionStart** - When session begins
- **SessionEnd** - When session ends
- **SubagentStop** - After subagent completes
- **Notification** - Permission/idle events
- **PreToolUse** - Before tool execution
- **PostToolUse** - After tool execution
- **UserPromptSubmit** - When prompt submitted
- **PreCompact** - Before context compaction

Events only appear if they have registered hooks in `settings.local.json`.

### Local Indicator Behavior

Hook events show `*` prefix when ANY hook associated with that event is local, indicating the event has local customization even if not all hooks are local.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Documentation Standards

All hooks follow documentation standards:

- **NO emojis** in file content or output
- **Unicode box-drawing** for terminal displays
- **Clear comments** explaining purpose and logic
- **Examples** in this README

See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

## Navigation

### Hook Scripts
- [post-command-metrics.sh](post-command-metrics.sh) - Metrics collection
- [tts-dispatcher.sh](tts-dispatcher.sh) - TTS notifications
- [post-buffer-opener.sh](post-buffer-opener.sh) - Automatic artifact opening in Neovim
- [pre-commit-library-sourcing.sh](pre-commit-library-sourcing.sh) - Library sourcing validation (git pre-commit)

### Related
- [← Parent Directory](../README.md)
- [tts/](../tts/README.md) - TTS configuration and messages
- [data/metrics/](../data/metrics/README.md) - Metrics output
- [data/logs/](../data/logs/README.md) - Hook logs

### Configuration
- [settings.local.json](../settings.local.json) - Hook registration

## Examples

### Simple Logging Hook
```bash
#!/usr/bin/env bash
# Simple hook that logs events

HOOK_INPUT=$(cat)
HOOK_EVENT=$(echo "$HOOK_INPUT" | jq -r '.hook_event_name')

LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/data/logs/events.log"
echo "[$(date -Iseconds)] $HOOK_EVENT" >> "$LOG_FILE"

exit 0
```

### Conditional Action Hook
```bash
#!/usr/bin/env bash
# Hook that acts only on specific commands

HOOK_INPUT=$(cat)
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.command')

# Only act on /implement
if [[ "$COMMAND" == "/implement" ]]; then
  # Log implementation event
  echo "[$(date -Iseconds)] Implement command executed" >> "$CLAUDE_PROJECT_DIR/.claude/data/logs/commands.log"
fi

exit 0
```

### Notification Hook
```bash
#!/usr/bin/env bash
# Hook that sends desktop notification

HOOK_INPUT=$(cat)
STATUS=$(echo "$HOOK_INPUT" | jq -r '.status')

if command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "Task completed: $STATUS"
fi

exit 0
```
