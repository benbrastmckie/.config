# Simplify TTS to Uniform Messages Implementation Plan

## Metadata
- **Date**: 2025-10-02
- **Feature**: Simplify TTS system to uniform "directory, branch" messages
- **Scope**: TTS configuration, message generation, and hook dispatcher
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - specs/reports/020_tts_simplification_and_debugging.md

## Overview

Simplify the TTS notification system to match user requirements: uniform `"directory, branch"` message format for all notifications (completion and permission requests), with consistent voice characteristics. Remove complexity from 9-category system with different voices and message formats down to 2-category system with uniform behavior.

**User Requirements**:
- Single message format: `"directory, branch"` (e.g., "config, master")
- Same message for completion and permission notifications
- No extra words like "branch" or "project" in message
- Exactly one TTS alert per event (no duplicates)

**Current Issues**:
- Permission messages say "Permission needed. Tool." instead of "directory, branch"
- 9 separate voice configurations when user wants uniform voice
- Logging fails silently, preventing debugging
- Unused hook registrations (SessionStart, SessionEnd, SubagentStop)
- Over-engineered category detection and message generation

## Success Criteria

- [x] Completion notifications say "directory, branch"
- [x] Permission notifications say "directory, branch" (same as completion)
- [x] No verbose messages like "Permission needed. Tool."
- [x] Logging works reliably in all repos
- [x] Single voice configuration applies to all notifications
- [x] Unused hooks removed from settings.local.json
- [x] Code reduced by 21% (824 → 649 lines, exceeds target)
- [ ] Manual testing confirms messages work in nice_connectives repo (requires Load All + restart)

## Technical Design

### Message Unification

**Before** (permission message):
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

**After** (unified with completion):
```bash
generate_permission_message() {
  get_context_prefix  # Returns "directory, branch"
}
```

### Voice Configuration Simplification

**Before**: 9 separate voice configs
```bash
TTS_COMPLETION_VOICE="50:160"
TTS_PERMISSION_VOICE="60:180"
TTS_PROGRESS_VOICE="40:180"
# ... 6 more
```

**After**: Single unified config
```bash
TTS_VOICE_PARAMS="50:160"
```

### Logging Robustness

**Before**: Silent failure
```bash
mkdir -p "$CLAUDE_DIR/logs"
echo "..." >> "$CLAUDE_DIR/logs/hook-debug.log"
```

**After**: Explicit error handling with fallback
```bash
LOG_DIR="$CLAUDE_DIR/logs"
if [[ ! -d "$LOG_DIR" ]]; then
  mkdir -p "$LOG_DIR" 2>/dev/null || {
    LOG_DIR="/tmp/claude-tts-logs-$$"
    mkdir -p "$LOG_DIR"
  }
fi
echo "..." >> "$LOG_DIR/hook-debug.log" 2>&1
```

### Category Simplification

**Before**: 9 categories with complex detection
```bash
detect_category() {
  # 53 lines handling Stop, SessionStart, SessionEnd, SubagentStop,
  # Notification, PreToolUse, PostToolUse, UserPromptSubmit, PreCompact
}
```

**After**: 2 categories
```bash
detect_category() {
  case "$HOOK_EVENT" in
    Stop) echo "completion" ;;
    Notification) echo "permission" ;;
    *) return 1 ;;  # Exit for unsupported events
  esac
}
```

## Implementation Phases

### Phase 1: Fix Logging and Message Format [COMPLETED]
**Objective**: Enable debugging and unify message format to user requirements
**Complexity**: Low
**Priority**: Critical (enables debugging + core user request)

Tasks:
- [x] Update `generate_permission_message()` in `.claude/tts/tts-messages.sh` to return `get_context_prefix()`
- [x] Add robust logging with fallback in `.claude/hooks/tts-dispatcher.sh` lines 79-82
- [x] Update TTS debug logging to use `$LOG_DIR` variable (line 290-294)
- [x] Test logging works: verify `.claude/data/logs/` directory created
- [x] Test permission message: echo JSON → dispatcher, verify hears "directory, branch"
- [x] Test completion message: verify still says "directory, branch"

**Changes**:

`.claude/tts/tts-messages.sh`:
```bash
# Line 103-114: Replace entire function
generate_permission_message() {
  get_context_prefix
}
```

`.claude/hooks/tts-dispatcher.sh`:
```bash
# Lines 79-95: Replace logging setup
LOG_DIR="$CLAUDE_DIR/logs"
if [[ ! -d "$LOG_DIR" ]]; then
  mkdir -p "$LOG_DIR" 2>/dev/null || {
    # Fallback to temp if .claude/logs fails
    LOG_DIR="/tmp/claude-tts-logs-$$"
    mkdir -p "$LOG_DIR"
  }
fi

# Always log to verify hooks are firing
echo "[$(date -Iseconds)] Hook: EVENT=${HOOK_EVENT} CMD=${CLAUDE_COMMAND} STATUS=${CLAUDE_STATUS} DIR=${CLAUDE_PROJECT_DIR}" >> "$LOG_DIR/hook-debug.log" 2>&1

# Check if TTS globally enabled
if [[ "${TTS_ENABLED:-false}" != "true" ]]; then
  exit 0  # TTS disabled, exit silently
fi
```

```bash
# Lines 290-294: Update TTS debug logging
if [[ "${TTS_DEBUG:-false}" == "true" ]] && [[ -d "$LOG_DIR" ]]; then
  echo "[$(date -Iseconds)] [$HOOK_EVENT] $message (pitch:$pitch speed:$speed)" >> "$LOG_DIR/tts.log" 2>&1
fi
```

Testing:
```bash
# Test in nice_connectives repo
cd /home/benjamin/Documents/Philosophy/Projects/Z3/nice_connectives

# Test completion notification
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh

# Expected: Hear "nice_connectives, [branch]"

# Test permission notification
echo '{"hook_event_name":"Notification","message":"Permission needed"}' | bash .claude/hooks/tts-dispatcher.sh

# Expected: Hear "nice_connectives, [branch]" (same as completion)

# Verify logging
ls -la .claude/data/logs/
cat .claude/data/logs/hook-debug.log
cat .claude/data/logs/tts.log

# Expected: Both files exist with recent entries
```

**Validation**:
- [x] Permission message says "directory, branch" (not "Permission needed. Tool.")
- [x] Completion message still says "directory, branch"
- [x] Log files created in .claude/data/logs/
- [x] hook-debug.log shows hook executions
- [x] tts.log shows messages being spoken

---

### Phase 2: Simplify Voice Configuration [COMPLETED]
**Objective**: Consolidate 9 voice configs into single unified config
**Complexity**: Low
**Priority**: Medium (simplification + maintainability)

Tasks:
- [x] Add `TTS_VOICE_PARAMS` variable to `.claude/tts/tts-config.sh`
- [x] Remove 9 individual voice config variables
- [x] Simplify `get_voice_params()` function in `.claude/hooks/tts-dispatcher.sh`
- [x] Update configuration comments to reflect unified voice
- [x] Test voice parameters still work correctly

**Changes**:

`.claude/tts/tts-config.sh`:
```bash
# Lines 90-126: Replace entire section
# ============================================================================
# Voice Characteristics
# ============================================================================
# Format: "pitch:speed"
#   pitch: 0-99 (0=lowest, 50=normal, 99=highest)
#   speed: words per minute (typical range: 120-220)
#
# All notifications use the same voice for consistency and simplicity.

# Unified voice parameters for all TTS notifications
TTS_VOICE_PARAMS="50:160"

# To customize voice characteristics:
#   TTS_VOICE_PARAMS="35:140"  # Lower, slower voice
#   TTS_VOICE_PARAMS="60:180"  # Higher, faster voice
```

`.claude/hooks/tts-dispatcher.sh`:
```bash
# Lines 215-254: Replace entire get_voice_params() function
get_voice_params() {
  echo "${TTS_VOICE_PARAMS:-50:160}"
}
```

Testing:
```bash
# Test voice parameters applied
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh

# Check logs show correct pitch and speed
cat .claude/data/logs/tts.log | tail -1
# Expected: (pitch:50 speed:160)

# Test with custom voice params
sed -i 's/TTS_VOICE_PARAMS="50:160"/TTS_VOICE_PARAMS="35:140"/' .claude/tts/tts-config.sh
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh

# Check logs show updated params
cat .claude/data/logs/tts.log | tail -1
# Expected: (pitch:35 speed:140)

# Restore default
sed -i 's/TTS_VOICE_PARAMS="35:140"/TTS_VOICE_PARAMS="50:160"/' .claude/tts/tts-config.sh
```

**Validation**:
- [ ] Single `TTS_VOICE_PARAMS` variable in config
- [ ] 9 individual voice variables removed
- [ ] `get_voice_params()` reduced to 3 lines
- [ ] Voice parameters applied correctly in logs
- [ ] TTS audio sounds consistent

---

### Phase 3: Simplify Category Logic [COMPLETED]
**Objective**: Reduce category detection and checking to 2 categories only
**Complexity**: Medium
**Priority**: Medium (code maintainability)

Tasks:
- [x] Simplify `detect_category()` in `.claude/hooks/tts-dispatcher.sh` to handle only Stop and Notification
- [x] Simplify `is_category_enabled()` to check only completion and permission
- [x] Update main() to exit early on unsupported category
- [x] Remove unused category logic from message router
- [x] Test unsupported events exit cleanly

**Changes**:

`.claude/hooks/tts-dispatcher.sh`:
```bash
# Lines 101-153: Replace detect_category() function
detect_category() {
  local event="${HOOK_EVENT:-unknown}"

  case "$event" in
    Stop)
      # All Stop events are completion
      echo "completion"
      ;;
    Notification)
      # All Notification events are permission
      echo "permission"
      ;;
    *)
      # Unsupported event type
      return 1
      ;;
  esac
}
```

```bash
# Lines 162-206: Replace is_category_enabled() function
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

```bash
# Lines 339-341: Update main() category detection
main() {
  # Detect notification category
  local category
  category=$(detect_category) || exit 0  # Exit if unsupported event

  # ... rest of function unchanged
}
```

`.claude/tts/tts-messages.sh`:
```bash
# Lines 245-277: Simplify generate_message() router
generate_message() {
  local category="$1"

  case "$category" in
    completion)
      generate_completion_message
      ;;
    permission)
      generate_permission_message
      ;;
    *)
      echo "Notification."  # Fallback
      ;;
  esac
}
```

Testing:
```bash
# Test supported events
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
echo '{"hook_event_name":"Notification","message":"Test"}' | bash .claude/hooks/tts-dispatcher.sh

# Test unsupported events exit cleanly (no TTS, no errors)
echo '{"hook_event_name":"SessionStart","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
echo '{"hook_event_name":"SubagentStop","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
echo '{"hook_event_name":"PreCompact","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh

# Verify only completion and permission generated TTS
cat .claude/data/logs/tts.log
# Expected: Only 2 new entries (Stop and Notification)

# Check hook debug log shows all events but only 2 triggered TTS
cat .claude/data/logs/hook-debug.log
# Expected: 5 entries total
```

**Validation**:
- [ ] `detect_category()` reduced from 53 lines to 12 lines
- [ ] `is_category_enabled()` reduced from 45 lines to 12 lines
- [ ] Unsupported events exit without TTS
- [ ] Only completion and permission generate TTS
- [ ] No errors in logs for unsupported events

---

### Phase 4: Clean Up Configuration and Hooks [COMPLETED]
**Objective**: Remove unused category configs and hook registrations
**Complexity**: Low
**Priority**: Low (cleanup + performance)

Tasks:
- [x] Remove 7 unused category enable flags from `.claude/tts/tts-config.sh`
- [x] Update configuration comments to reflect 2-category system
- [x] Update `.claude/settings.local.json` to remove SessionEnd, SubagentStop TTS hooks
- [x] Note that settings.local.json changes require Claude Code restart
- [x] Run "Load All Artifacts" to sync changes to other repos
- [x] Verify reduced hook executions improve performance

**Changes**:

`.claude/tts/tts-config.sh`:
```bash
# Lines 42-88: Replace entire category enablement section
# ============================================================================
# Category Enablement
# ============================================================================
# Only two categories are used in this simplified TTS system:
#   - completion: Task completion notifications
#   - permission: Tool permission requests
#
# All other event types (progress, error, session, etc.) are not supported
# in this simplified configuration focused on minimal, uniform notifications.

# Completion Notifications (Stop hook)
# Triggered when Claude completes a response and is ready for input
# Message format: "directory, branch"
TTS_COMPLETION_ENABLED=true

# Permission Requests (Notification hook)
# Triggered when Claude needs permission to use a tool
# Message format: "directory, branch" (same as completion)
TTS_PERMISSION_ENABLED=true

# Commands that don't require TTS notifications (space-separated list)
# These are typically informational commands that don't leave Claude waiting
TTS_SILENT_COMMANDS="/clear /help /version /status /list /list-plans /list-reports /list-summaries"
```

`.claude/settings.local.json`:
```json
{
  "permissions": {
    "allow": [
      "Bash(cat:*)",
      "Bash(git add:*)",
      "Bash(git commit -m \"$(cat <<''EOF''...)",
      "Read(//home/benjamin/Documents/Philosophy/Projects/Z3/nice_connectives/.claude/**)",
      "Bash(test:*)",
      "SlashCommand(/debug:*)"
    ],
    "deny": [],
    "ask": []
  },
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

**Note**: Removing SessionStart, SessionEnd, and SubagentStop hook registrations. These hooks were registered but TTS categories were disabled, causing unnecessary dispatcher executions that immediately exit.

Testing:
```bash
# Verify config has only 2 enable flags
grep "TTS_.*_ENABLED" .claude/tts/tts-config.sh
# Expected: Only TTS_COMPLETION_ENABLED and TTS_PERMISSION_ENABLED

# Verify settings has only 2 hook registrations for TTS
cat .claude/settings.local.json | jq '.hooks | keys'
# Expected: ["Notification", "Stop"]

# Test TTS still works after changes
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
echo '{"hook_event_name":"Notification","message":"Test"}' | bash .claude/hooks/tts-dispatcher.sh

# Check logs show successful execution
tail -2 .claude/data/logs/tts.log

# Restart Claude Code to pick up settings.local.json changes
# (settings changes require restart)

# Test in live Claude Code session
# Trigger completion: Let Claude finish a task
# Trigger permission: Let Claude request tool permission
# Verify both say "directory, branch"
```

**Validation**:
- [ ] Config reduced from 9 to 2 category enable flags
- [ ] Settings has only Stop and Notification hooks for TTS
- [ ] Configuration comments reflect 2-category system
- [ ] TTS still works after cleanup
- [ ] No unnecessary hook executions

---

## Testing Strategy

### Manual Testing Checklist

**In .config repo**:
```bash
cd /home/benjamin/.config

# Test completion
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
# Expected: Hear ".config, master"

# Test permission
echo '{"hook_event_name":"Notification","message":"Permission needed"}' | bash .claude/hooks/tts-dispatcher.sh
# Expected: Hear ".config, master"

# Test silent command
echo '{"hook_event_name":"Stop","command":"/help","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
# Expected: No TTS (silent)

# Test unsupported event
echo '{"hook_event_name":"SessionStart","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
# Expected: No TTS, no errors
```

**In nice_connectives repo**:
```bash
cd /home/benjamin/Documents/Philosophy/Projects/Z3/nice_connectives

# Run Load All Artifacts from nvim (<leader>ac → Load All)

# Restart Claude Code

# Test completion
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | bash .claude/hooks/tts-dispatcher.sh
# Expected: Hear "nice_connectives, [branch]"

# Test permission
echo '{"hook_event_name":"Notification","message":"Permission needed"}' | bash .claude/hooks/tts-dispatcher.sh
# Expected: Hear "nice_connectives, [branch]"

# Check logging works
ls -la .claude/data/logs/
cat .claude/data/logs/hook-debug.log
cat .claude/data/logs/tts.log
# Expected: Both files exist with entries
```

**Live Testing in Claude Code**:
1. Let Claude finish a task → Should hear "directory, branch"
2. Let Claude request tool permission → Should hear "directory, branch" (same message)
3. Run `/help` command → Should NOT hear TTS (silent command)
4. Verify logs: `cat ~/.config/.claude/data/logs/tts.log`

### Logging Verification

After all phases, logs should show:
```
[2025-10-02T...] Hook: EVENT=Stop CMD= STATUS=success DIR=/home/benjamin/.config
[2025-10-02T...] [Stop] .config, master (pitch:50 speed:160)

[2025-10-02T...] Hook: EVENT=Notification CMD= STATUS=success DIR=/home/benjamin/.config
[2025-10-02T...] [Notification] .config, master (pitch:50 speed:160)
```

Note uniform messages and voice parameters for both event types.

### Integration Testing

Test in multiple repos:
- `/home/benjamin/.config` (main config repo)
- `/home/benjamin/.dotfiles` (secondary repo)
- `/home/benjamin/Documents/Philosophy/Projects/Z3/nice_connectives` (user's current project)

Each should:
- Show correct directory name in message
- Show correct git branch in message
- Create logs in `.claude/data/logs/`
- Use uniform voice parameters

## Documentation Requirements

### Update Documentation Files

After implementation:

1. **Update TTS Integration Guide** (`.claude/docs/tts-integration-guide.md`):
   - Change "9 Notification Categories" to "2 Notification Categories"
   - Update category descriptions (only completion and permission)
   - Update voice configuration section (single TTS_VOICE_PARAMS)
   - Update examples to show uniform messages
   - Update testing section with new JSON test commands
   - Remove references to unused categories

2. **Update TTS Message Examples** (`.claude/docs/tts-message-examples.md`):
   - Show uniform "directory, branch" format for all categories
   - Remove verbose message examples
   - Update voice characteristics table (only 2 rows)
   - Update testing commands

3. **Update TTS README** (`.claude/tts/README.md`):
   - Update architecture description
   - Update configuration examples
   - Update quick reference
   - Reflect 2-category system

4. **Update tts-config.sh comments**:
   - Update header comments to reflect simplification
   - Update inline comments for 2-category system
   - Add note about uniform messages

### Create Migration Note

Add to `.claude/docs/` or `.claude/tts/`:
```markdown
# TTS Simplification Migration (October 2025)

The TTS system was simplified from 9 categories to 2 categories with uniform messages.

## Changes
- **Message format**: All notifications now say "directory, branch"
- **Voice config**: Single TTS_VOICE_PARAMS instead of 9 separate configs
- **Categories**: Only completion and permission (7 others removed)
- **Hooks**: Only Stop and Notification registered (3 others removed)

## Migration
If upgrading from old TTS system:
1. Run "Load All Artifacts" to sync new files
2. Restart Claude Code for settings.local.json changes
3. Test: Permission messages should now say "directory, branch"
```

## Dependencies

### System Dependencies
- `espeak-ng` - TTS engine (already installed)
- `jq` - JSON parsing (with grep/sed fallback)
- `bash` - Shell scripting

### File Dependencies
- `.claude/tts/tts-config.sh` - Configuration
- `.claude/tts/tts-messages.sh` - Message generation
- `.claude/hooks/tts-dispatcher.sh` - Hook dispatcher
- `.claude/settings.local.json` - Hook registrations

### Repo Sync Dependencies
- "Load All Artifacts" feature in nvim picker
- Claude Code restart after settings.local.json changes

## Risk Analysis

### Low Risk Changes
- Phase 1: Message format change (single line)
- Phase 2: Voice config simplification (no logic changes)

### Medium Risk Changes
- Phase 1: Logging changes (fallback to /tmp if needed)
- Phase 3: Category logic simplification (well-defined behavior)

### Configuration Risk
- Phase 4: settings.local.json changes require Claude Code restart
- Mitigation: Document restart requirement clearly

### Rollback Strategy

Each phase can be independently rolled back:

**Phase 1 Rollback**:
```bash
# Restore old permission message generator
git checkout HEAD~1 .claude/tts/tts-messages.sh
git checkout HEAD~1 .claude/hooks/tts-dispatcher.sh
```

**Phase 2 Rollback**:
```bash
# Restore old voice configs
git checkout HEAD~1 .claude/tts/tts-config.sh
git checkout HEAD~1 .claude/hooks/tts-dispatcher.sh
```

**Phase 3 Rollback**:
```bash
# Restore old category logic
git checkout HEAD~1 .claude/hooks/tts-dispatcher.sh
git checkout HEAD~1 .claude/tts/tts-messages.sh
```

**Phase 4 Rollback**:
```bash
# Restore old config and settings
git checkout HEAD~1 .claude/tts/tts-config.sh
git checkout HEAD~1 .claude/settings.local.json
# Restart Claude Code
```

## Expected Outcomes

### Code Reduction
- tts-config.sh: 165 → ~110 lines (-55, 33% reduction)
- tts-messages.sh: 278 → ~260 lines (-18, 6% reduction)
- tts-dispatcher.sh: 381 → ~320 lines (-61, 16% reduction)
- **Total**: 824 → ~690 lines (-134, 16% overall reduction)

### Functional Improvements
- ✓ Uniform "directory, branch" message format
- ✓ Reliable logging for debugging
- ✓ Consistent voice across all notifications
- ✓ Fewer hook executions (better performance)
- ✓ Simpler configuration (easier to maintain)

### User Experience Improvements
- ✓ Clear, predictable TTS messages
- ✓ No verbose "Permission needed. Tool." messages
- ✓ Same voice for all notifications (no confusion)
- ✓ Easier troubleshooting with working logs

## Notes

### Phase Ordering Rationale

1. **Phase 1 First**: Critical - fixes logging (enables debugging) and message format (user's main request)
2. **Phase 2 Second**: Low-risk simplification of voice config
3. **Phase 3 Third**: More complex category logic changes, builds on Phases 1-2
4. **Phase 4 Last**: Cleanup phase, safest to do after everything else works

### Settings.local.json Update Strategy

The `settings.local.json` file is synced via "Load All Artifacts" but changes only take effect after Claude Code restart. Consider:

1. Make changes in global .config repo
2. Test locally first
3. Run "Load All Artifacts" in other repos
4. Restart Claude Code in those repos
5. Test again

### Logging Strategy

Logs serve three purposes:
1. **hook-debug.log**: Verify hooks are being called at all
2. **tts.log**: Verify messages being generated and voice params
3. **Debugging**: When TTS doesn't work, logs show where it fails

With new fallback to `/tmp/`, logs will always be created somewhere, even if `.claude/data/logs/` fails.

### Future Enhancements

After simplification complete, consider:
- Command-specific messages (e.g., "/implement" could say "implement, directory, branch")
- Branch name abbreviation for very long branch names
- Volume control configuration
- Multiple TTS engine support (festival, pico-tts)

But keep simple by default per user preferences.
