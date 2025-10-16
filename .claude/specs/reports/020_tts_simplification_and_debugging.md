# TTS Simplification and Debugging Report

## Metadata
- **Date**: 2025-10-02
- **Scope**: TTS notification system analysis and simplification recommendations
- **Primary Directory**: `/home/benjamin/.config/.claude/tts/`
- **Files Analyzed**:
  - `.claude/tts/tts-config.sh` (165 lines)
  - `.claude/tts/tts-messages.sh` (278 lines)
  - `.claude/hooks/tts-dispatcher.sh` (381 lines)
  - `.claude/settings.local.json` (hook registrations)

## Executive Summary

The TTS system is functional but overly complex for the user's stated needs. The user wants a single, uniform message format `"directory, branch"` for all TTS notifications (completion and permission requests). The current implementation has 9 distinct categories with different voice characteristics and message formats, creating unnecessary complexity.

**Key Findings**:
1. **Over-engineered**: 9 categories when user wants 1 uniform message
2. **No logging**: Debug mode enabled but logs never created (directory creation issue)
3. **Duplicate logic**: Category detection and message generation more complex than needed
4. **Unused features**: State file support, verbosity toggles, voice customization per category

**Recommendations**:
1. Simplify to single message format: `"directory, branch"`
2. Use same voice parameters for all notifications
3. Fix logging (create logs directory proactively)
4. Consolidate enabled categories to just completion and permission
5. Remove unused message generation complexity

## Current State Analysis

### Configuration Complexity

**tts-config.sh** has 165 lines managing:
- 9 separate category enable/disable flags
- 9 separate voice parameter configurations (pitch:speed)
- Verbosity options (directory, branch, duration)
- Silent command list
- State file support
- Debug logging

**User's actual needs**:
- Enable: Completion and permission only
- Message: Always `"directory, branch"`
- Voice: Same for both categories

### Message Generation Complexity

**tts-messages.sh** has 8 separate message generator functions:
- `generate_completion_message()` - Returns `"directory, branch"` ✓ (matches user need)
- `generate_permission_message()` - Returns `"Permission needed. Tool."` ✗ (doesn't match)
- `generate_progress_message()` - Not needed by user
- `generate_error_message()` - Not needed by user
- `generate_idle_message()` - Not needed by user (disabled)
- `generate_session_message()` - Not needed by user (disabled)
- `generate_tool_message()` - Not needed by user (disabled)
- `generate_prompt_ack_message()` - Not needed by user (disabled)
- `generate_compact_message()` - Not needed by user (disabled)

**Current permission message**: `"Permission needed. Tool."`
**User wants**: `"directory, branch"`

The permission message generator completely ignores the `get_context_prefix()` function which already returns exactly what the user wants.

### Dispatcher Logic Complexity

**tts-dispatcher.sh** has 381 lines implementing:
- JSON parsing (with jq fallback) ✓ (necessary)
- Category detection based on hook event ✓ (necessary)
- Per-category enable/disable checking ✓ (necessary)
- Per-category voice parameter extraction ✗ (not needed if all use same voice)
- Silent command filtering ✓ (useful feature)
- State file reading support ✗ (not used)

### Hook Registration

Settings registered for 5 hook types:
1. **Stop** - Completion/error notifications ✓ (user wants)
2. **SessionStart** - Session lifecycle ✗ (user has disabled)
3. **SessionEnd** - Session lifecycle ✗ (user has disabled)
4. **SubagentStop** - Progress updates ✗ (not mentioned by user)
5. **Notification** - Permission requests ✓ (user wants)

**Issue**: SessionStart and SessionEnd hooks registered but TTS_SESSION_ENABLED=false in config, so dispatcher exits early. Unnecessary hook executions.

## Critical Issue: No Logging

The user reported TTS not working in `nice_connectives` repo. Investigation reveals:

**In nice_connectives repo:**
```
.claude/hooks/      ✓ Present with tts-dispatcher.sh
.claude/tts/        ✓ Present with config and messages
.claude/data/logs/       ✗ MISSING
```

**Problem in tts-dispatcher.sh line 81**:
```bash
mkdir -p "$CLAUDE_DIR/logs"
echo "[$(date -Iseconds)] Hook called: EVENT=${HOOK_EVENT} ..." >> "$CLAUDE_DIR/logs/hook-debug.log"
```

**Issue**: `mkdir -p` succeeds but subsequent logging fails silently if:
1. Directory permissions prevent writes
2. Script runs in restricted context
3. `$CLAUDE_DIR` evaluates incorrectly

**Evidence**: No logs exist in nice_connectives despite TTS_DEBUG=true and hooks being called (settings.local.json properly configured).

### Logging Flow Analysis

```
┌─────────────────────────────────────────┐
│ Hook triggered by Claude Code           │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│ tts-dispatcher.sh line 37: Read JSON    │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│ Line 81: mkdir -p logs (succeeds)       │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│ Line 81: echo >> hook-debug.log         │
│ FAILS SILENTLY (likely permissions)     │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│ Line 84-86: Check TTS_ENABLED           │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│ Lines 293-294: TTS_DEBUG logging        │
│ FAILS SILENTLY (same permission issue)  │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│ Line 297: espeak-ng (should work)       │
└─────────────────────────────────────────┘
```

**Why this matters**: Without logs, debugging TTS issues is impossible. User can't tell if:
- Hooks are firing
- Configuration is being read
- Messages are being generated
- espeak-ng is being invoked

## Technical Deep Dive

### Permission Message Issue

**Current implementation** (tts-messages.sh:103-114):
```bash
generate_permission_message() {
  local tool="${TOOL_NAME:-Tool}"
  local context="${PERMISSION_CONTEXT:-}"

  local message="Permission needed. $tool."

  if [[ -n "$context" ]]; then
    message="$message $context."
  fi

  echo "$message"
}
```

**Problem**: This function:
1. Expects `TOOL_NAME` environment variable (not provided by JSON input)
2. Completely ignores `get_context_prefix()` function
3. Returns verbose message user doesn't want

**What user wants** (same as completion):
```bash
generate_permission_message() {
  get_context_prefix
}
```

### Voice Parameter Redundancy

**Current**: Each category has separate voice config
```bash
TTS_COMPLETION_VOICE="50:160"
TTS_PERMISSION_VOICE="60:180"
TTS_PROGRESS_VOICE="40:180"
TTS_ERROR_VOICE="35:140"
# ... 5 more
```

**User needs**: Same voice for everything
```bash
TTS_VOICE_PARAMS="50:160"  # Single voice config
```

**Impact**:
- Dispatcher line 215-254 (`get_voice_params()`) can be reduced to single line
- Configuration reduced by 8 lines
- No mental overhead choosing pitch/speed per category

### Category Detection Overhead

**Current**: 53 lines of case statement logic (dispatcher.sh:101-153)

**User needs**: Only 2 categories matter
```bash
detect_category() {
  case "$HOOK_EVENT" in
    Stop)
      echo "completion"
      ;;
    Notification)
      echo "permission"
      ;;
    *)
      return 1  # Exit for all other events
      ;;
  esac
}
```

**Reduction**: 53 lines → 12 lines

### Silent Commands Feature

**Current implementation** (dispatcher.sh:306-332): 27 lines

**Configured silent commands** (config.sh:53):
```bash
TTS_SILENT_COMMANDS="/clear /help /version /status /list /list-plans /list-reports /list-summaries"
```

**Value**: High - prevents TTS spam for informational commands

**Verdict**: Keep this feature

## Detailed Recommendations

### Recommendation 1: Unify Message Format

**Change tts-messages.sh lines 103-114**:

**Before**:
```bash
generate_permission_message() {
  local tool="${TOOL_NAME:-Tool}"
  local context="${PERMISSION_CONTEXT:-}"

  local message="Permission needed. $tool."

  if [[ -n "$context" ]]; then
    message="$message $context."
  fi

  echo "$message"
}
```

**After**:
```bash
generate_permission_message() {
  get_context_prefix
}
```

**Benefit**: User gets uniform `"directory, branch"` for both completion and permission.

### Recommendation 2: Simplify Voice Configuration

**Change tts-config.sh lines 100-125**:

**Before**:
```bash
TTS_COMPLETION_VOICE="50:160"
TTS_PERMISSION_VOICE="60:180"
TTS_PROGRESS_VOICE="40:180"
TTS_ERROR_VOICE="35:140"
TTS_IDLE_VOICE="50:140"
TTS_SESSION_VOICE="50:160"
TTS_TOOL_VOICE="30:200"
TTS_PROMPT_ACK_VOICE="70:220"
TTS_COMPACT_VOICE="50:160"
```

**After**:
```bash
# Unified voice parameters for all notifications
# Format: "pitch:speed"
#   pitch: 0-99 (0=lowest, 50=normal, 99=highest)
#   speed: words per minute
TTS_VOICE_PARAMS="50:160"
```

**Change tts-dispatcher.sh lines 215-254** (`get_voice_params()`):

**Before**: 40 lines of case statement

**After**:
```bash
get_voice_params() {
  echo "${TTS_VOICE_PARAMS:-50:160}"
}
```

**Benefit**: Single source of truth for voice, much simpler configuration.

### Recommendation 3: Fix Logging Immediately

**Change tts-dispatcher.sh lines 79-82**:

**Before**:
```bash
# Debug: Log that hook was called with parsed data
mkdir -p "$CLAUDE_DIR/logs"
echo "[$(date -Iseconds)] Hook called: EVENT=${HOOK_EVENT} CMD=${CLAUDE_COMMAND} STATUS=${CLAUDE_STATUS}" >> "$CLAUDE_DIR/logs/hook-debug.log"
```

**After**:
```bash
# Debug: Log that hook was called with parsed data
# Create logs directory with explicit permissions
LOG_DIR="$CLAUDE_DIR/logs"
if [[ ! -d "$LOG_DIR" ]]; then
  mkdir -p "$LOG_DIR" 2>/dev/null || {
    # If mkdir fails, try to create in temp
    LOG_DIR="/tmp/claude-tts-logs-$$"
    mkdir -p "$LOG_DIR"
  }
fi

# Always log to verify hooks are firing
echo "[$(date -Iseconds)] Hook called: EVENT=${HOOK_EVENT} CMD=${CLAUDE_COMMAND} STATUS=${CLAUDE_STATUS} DIR=${CLAUDE_PROJECT_DIR}" >> "$LOG_DIR/hook-debug.log" 2>&1
```

**Also change lines 290-294** (TTS debug logging):

**Before**:
```bash
if [[ "${TTS_DEBUG:-false}" == "true" ]]; then
  local log_dir="$CLAUDE_DIR/logs"
  mkdir -p "$log_dir"
  echo "[$(date -Iseconds)] [$HOOK_EVENT] $message (pitch:$pitch speed:$speed)" >> "$log_dir/tts.log"
fi
```

**After**:
```bash
if [[ "${TTS_DEBUG:-false}" == "true" ]] && [[ -d "$LOG_DIR" ]]; then
  echo "[$(date -Iseconds)] [$HOOK_EVENT] $message (pitch:$pitch speed:$speed)" >> "$LOG_DIR/tts.log" 2>&1
fi
```

**Benefit**: Guaranteed logging for debugging, fallback to /tmp if needed.

### Recommendation 4: Remove Unused Hook Registrations

**Change settings.local.json**:

**Before**: 5 hook types registered

**After**: 2 hook types registered
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

**Remove**: SessionStart, SessionEnd, SubagentStop hook registrations

**Benefit**:
- Fewer hook executions (performance)
- Clearer configuration (only what's used)
- No wasted dispatcher invocations that immediately exit

### Recommendation 5: Simplify Category Detection

**Change tts-dispatcher.sh lines 101-153**:

**Before**: 53 lines handling 9 event types

**After**:
```bash
detect_category() {
  local event="${HOOK_EVENT:-unknown}"

  case "$event" in
    Stop)
      # All Stop events are completion (user doesn't want error distinction)
      echo "completion"
      ;;
    Notification)
      # All Notification events are permission (user doesn't want idle distinction)
      echo "permission"
      ;;
    *)
      # Unknown/unsupported events
      return 1
      ;;
  esac
}
```

**Also change main() lines 339-360** to handle failed category detection:

**After detect_category call**:
```bash
local category
category=$(detect_category) || exit 0  # Exit if unsupported event
```

**Benefit**:
- Much simpler logic
- Clear intent (only 2 categories matter)
- Fast exit for unsupported events

### Recommendation 6: Consolidate Category Checks

**Change tts-dispatcher.sh lines 162-206**:

**Before**: 40 lines of case statement

**After**:
```bash
is_category_enabled() {
  local category="$1"

  case "$category" in
    completion)
      [[ "${TTS_COMPLETION_ENABLED:-false}" == "true" ]]
      ;;
    permission)
      [[ "${TTS_PERMISSION_ENABLED:-false}" == "true" ]]
      ;;
    *)
      return 1  # Unknown categories disabled
      ;;
  esac
}
```

**Benefit**: Reduced from 45 lines to 12 lines

### Recommendation 7: Update Configuration Defaults

**Change tts-config.sh lines 47-88**:

**Before**: 9 category enable flags

**After**:
```bash
# ============================================================================
# Category Enablement
# ============================================================================
# Only two categories are used: completion and permission
# All others are disabled and removed from the system

# Completion Notifications (Stop hook)
# Triggered when Claude completes a response and is ready for input
TTS_COMPLETION_ENABLED=true

# Permission Requests (Notification hook)
# Triggered when Claude needs permission to use a tool
TTS_PERMISSION_ENABLED=true

# Commands that don't require TTS notifications (space-separated list)
TTS_SILENT_COMMANDS="/clear /help /version /status /list /list-plans /list-reports /list-summaries"
```

**Remove these lines entirely**:
- TTS_PROGRESS_ENABLED
- TTS_ERROR_ENABLED
- TTS_IDLE_ENABLED
- TTS_SESSION_ENABLED
- TTS_TOOL_ENABLED
- TTS_PROMPT_ACK_ENABLED
- TTS_COMPACT_ENABLED

**Benefit**: Configuration file reduced from 165 lines to ~110 lines

## Implementation Priority

### High Priority (Immediate)

1. **Fix logging** (Recommendation 3)
   - Critical for debugging user's issue
   - Should be done first
   - Files: tts-dispatcher.sh

2. **Unify message format** (Recommendation 1)
   - User's primary request
   - Simple 1-line change
   - Files: tts-messages.sh

3. **Remove unused hooks** (Recommendation 4)
   - Performance improvement
   - Files: settings.local.json (requires /setup or manual edit)

### Medium Priority (Soon)

4. **Simplify voice config** (Recommendation 2)
   - Reduces configuration complexity
   - Files: tts-config.sh, tts-dispatcher.sh

5. **Simplify category detection** (Recommendation 5)
   - Code maintainability
   - Files: tts-dispatcher.sh

### Low Priority (When Time Permits)

6. **Consolidate category checks** (Recommendation 6)
   - Code cleanup
   - Files: tts-dispatcher.sh

7. **Update config defaults** (Recommendation 7)
   - Documentation clarity
   - Files: tts-config.sh

## Testing Strategy

After implementing changes:

### Test 1: Completion Message
```bash
cd /home/benjamin/Documents/Philosophy/Projects/Z3/nice_connectives
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
```

**Expected**: Hear "nice_connectives, [branch]"

### Test 2: Permission Message
```bash
echo '{"hook_event_name":"Notification","message":"Permission needed"}' | bash .claude/hooks/tts-dispatcher.sh
```

**Expected**: Hear "nice_connectives, [branch]" (same as completion)

### Test 3: Logging Verification
```bash
ls -la .claude/data/logs/
cat .claude/data/logs/hook-debug.log
cat .claude/data/logs/tts.log
```

**Expected**: Both log files exist with recent entries

### Test 4: Silent Commands
```bash
echo '{"hook_event_name":"Stop","command":"/help","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
```

**Expected**: No TTS (silent command)

### Test 5: Unsupported Events
```bash
echo '{"hook_event_name":"PreCompact","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
```

**Expected**: No TTS, early exit

## Risk Analysis

### Risk: Breaking Existing Functionality

**Likelihood**: Low
**Impact**: Medium
**Mitigation**:
- User explicitly wants simplified behavior
- Changes are reductive (removing unused features)
- Testing strategy covers all active use cases

### Risk: Logging Permission Issues

**Likelihood**: Medium
**Impact**: High (can't debug if logging fails)
**Mitigation**:
- Fallback to /tmp if .claude/logs fails
- Always attempt logging regardless of TTS_DEBUG flag
- Explicit error handling around mkdir and echo

### Risk: Load All Artifacts Not Syncing Updates

**Likelihood**: Medium
**Impact**: Medium
**Mitigation**:
- Document that users must run Load All again after updates
- Consider adding version checking to files
- Add note in settings.local.json about needing Claude Code restart

## Appendix A: File Size Impact

**Current**:
- tts-config.sh: 165 lines
- tts-messages.sh: 278 lines
- tts-dispatcher.sh: 381 lines
- **Total**: 824 lines

**After recommendations**:
- tts-config.sh: ~110 lines (-55)
- tts-messages.sh: ~260 lines (-18, mostly comments)
- tts-dispatcher.sh: ~320 lines (-61)
- **Total**: ~690 lines (-134, 16% reduction)

## Appendix B: Configuration Comparison

### Current Configuration
```bash
TTS_ENABLED=true
TTS_ENGINE="espeak-ng"
TTS_VOICE="en-us+f3"
TTS_DEFAULT_SPEED=160

TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_PROGRESS_ENABLED=true
TTS_ERROR_ENABLED=true
TTS_IDLE_ENABLED=false
TTS_SESSION_ENABLED=false
TTS_TOOL_ENABLED=false
TTS_PROMPT_ACK_ENABLED=false
TTS_COMPACT_ENABLED=false

TTS_COMPLETION_VOICE="50:160"
TTS_PERMISSION_VOICE="60:180"
TTS_PROGRESS_VOICE="40:180"
TTS_ERROR_VOICE="35:140"
TTS_IDLE_VOICE="50:140"
TTS_SESSION_VOICE="50:160"
TTS_TOOL_VOICE="30:200"
TTS_PROMPT_ACK_VOICE="70:220"
TTS_COMPACT_VOICE="50:160"

TTS_SILENT_COMMANDS="/clear /help /version ..."
TTS_DEBUG=true
```

### Simplified Configuration
```bash
TTS_ENABLED=true
TTS_ENGINE="espeak-ng"
TTS_VOICE="en-us+f3"

TTS_COMPLETION_ENABLED=true
TTS_PERMISSION_ENABLED=true
TTS_VOICE_PARAMS="50:160"

TTS_SILENT_COMMANDS="/clear /help /version ..."
TTS_DEBUG=true
```

**Lines reduced**: 27 → 9 (67% reduction)

## Appendix C: Debugging Nice Connectives Issue

Based on investigation, TTS should work in nice_connectives because:

✓ settings.local.json has correct hook registrations
✓ .claude/hooks/tts-dispatcher.sh exists
✓ .claude/tts/ directory exists with config and messages
✓ Hook registration shows proper tts-dispatcher.sh path

**Likely issue**: Logging failure prevents seeing what's happening

**Action items**:
1. Implement logging fixes from Recommendation 3
2. Test manually with echo piping JSON
3. Check espeak-ng works: `espeak-ng "test"`
4. Verify TTS_ENABLED=true in nice_connectives/.claude/tts/tts-config.sh

## References

### Files Analyzed
- [.claude/tts/tts-config.sh](../../tts/tts-config.sh) - Main configuration
- [.claude/tts/tts-messages.sh](../../tts/tts-messages.sh) - Message generation
- [.claude/hooks/tts-dispatcher.sh](../../hooks/tts-dispatcher.sh) - Hook dispatcher
- [.claude/settings.local.json](../../settings.local.json) - Hook registrations

### Related Documentation
- [TTS Integration Guide](../../docs/tts-integration-guide.md)
- [TTS Message Examples](../../docs/tts-message-examples.md)
- [TTS README](../../tts/README.md)
- [Hooks README](../../hooks/README.md)

### Claude Code Documentation
- Hook Input Format: JSON via stdin
- Hook Events: Stop, Notification, SessionStart, SessionEnd, SubagentStop
- Hook Execution: Asynchronous, non-blocking
