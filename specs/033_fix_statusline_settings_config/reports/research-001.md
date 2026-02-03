# Research Report: Task #33

**Task**: 33 - Fix Claude Code settings.json statusLine configuration
**Date**: 2026-02-03
**Focus**: Claude Code settings.json schema for statusLine configuration
**Effort**: 1-2 hours (simple configuration fix)
**Dependencies**: None
**Sources/Inputs**: Official Claude Code documentation, GitHub issues
**Artifacts**: specs/033_fix_statusline_settings_config/reports/research-001.md
**Standards**: report-format.md, artifact-formats.md

## Summary

The statusLine configuration was incorrectly nested inside the `hooks` object, but `statusLine` is a top-level field in settings.json - it is NOT a hook event. The fix is to move `statusLine` out of `hooks` to the top level. However, there is a known bug (GitHub #13517) where external script paths may not be invoked; inline commands may work as a workaround.

## Findings

### 1. Root Cause: Incorrect Schema Structure

**Current (incorrect) configuration:**
```json
{
  "model": "sonnet",
  "hooks": {
    "statusLine": [...]  // WRONG! statusLine is not a hook event
  }
}
```

**Correct configuration:**
```json
{
  "model": "sonnet",
  "statusLine": {         // TOP-LEVEL field, not inside hooks
    "type": "command",
    "command": "~/.claude/hooks/statusline-push.sh",
    "padding": 0
  }
}
```

The error message "statusLine: Invalid key in record" occurs because Claude Code's hooks schema only accepts valid hook event names as keys:
- SessionStart, UserPromptSubmit, PreToolUse, PermissionRequest
- PostToolUse, PostToolUseFailure, Notification, SubagentStart
- SubagentStop, Stop, PreCompact, SessionEnd

`statusLine` is NOT a hook event - it is a separate top-level configuration field.

### 2. statusLine Configuration Schema

From official documentation at https://code.claude.com/docs/en/statusline:

**Configuration format:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0  // Optional: set to 0 to let status line go to edge
  }
}
```

**Behavior:**
- Status line updates when conversation messages update
- Updates run at most every 300ms
- First line of stdout becomes the status line text
- ANSI color codes supported
- Receives JSON context data via stdin

**JSON Input Structure (received by command):**
```json
{
  "hook_event_name": "Status",
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.json",
  "cwd": "/current/working/directory",
  "model": {
    "id": "claude-opus-4-1",
    "display_name": "Opus"
  },
  "workspace": {
    "current_dir": "/current/working/directory",
    "project_dir": "/original/project/directory"
  },
  "version": "1.0.80",
  "cost": {
    "total_cost_usd": 0.01234,
    "total_duration_ms": 45000,
    "total_api_duration_ms": 2300
  },
  "context_window": {
    "total_input_tokens": 15234,
    "total_output_tokens": 4521,
    "context_window_size": 200000,
    "used_percentage": 42.5,
    "remaining_percentage": 57.5,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  }
}
```

### 3. Known Bug: External Script Not Invoked

**GitHub Issue #13517** (OPEN as of January 2026):

The statusLine command configured with external script paths may not execute in certain Claude Code versions (2.0.62 through 2.1.12+).

**Symptoms:**
- Script never called
- No status line appears
- Debug log files not created when configured

**Workaround from community:**
Use inline commands instead of external script paths:
```json
{
  "statusLine": {
    "type": "command",
    "command": "ccusage"  // Inline command works
  }
}
```

**Alternative workaround - inline the full script logic:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); MODEL=$(echo \"$input\" | jq -r '.model.display_name // \"Claude\"'); PERCENT=$(echo \"$input\" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1); printf \"%s | %d%%\" \"$MODEL\" \"$PERCENT\""
  }
}
```

### 4. Correct Hooks Schema

If we also want to use hooks (separately from statusLine), the hooks schema is:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/stop-hook.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/on-write.sh"
          }
        ]
      }
    ]
  }
}
```

Note: Each hook event has an array of matcher groups, and each matcher group has a `hooks` array.

### 5. Existing statusline-push.sh Analysis

The existing script at `~/.claude/hooks/statusline-push.sh` is correctly implemented:
- Reads JSON from stdin
- Extracts context_window data with jq
- Writes atomically to /tmp/claude-context.json
- Outputs formatted statusline text

The script follows the patterns documented in task 32's research-003.md.

**Note about JSON fields:** The script uses some field names that don't match the official schema:
- Script uses: `context_window.context_used`, `context_window.context_limit`
- Official schema: `context_window.used_percentage`, `context_window.context_window_size`

The script should be updated to use official field names, but this is a separate issue from the configuration error.

## Recommendations

### Immediate Fix

1. **Move statusLine to top-level** in `~/.claude/settings.json`:

```json
{
  "model": "sonnet",
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/statusline-push.sh",
    "padding": 0
  }
}
```

### If External Script Still Doesn't Work

2. **Try inline command as workaround**:

```json
{
  "model": "sonnet",
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); echo \"$input\" > /tmp/claude-context.json; MODEL=$(echo \"$input\" | jq -r '.model.display_name // \"Claude\"'); PERCENT=$(echo \"$input\" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1); printf \"%s | %d%%\" \"$MODEL\" \"$PERCENT\"",
    "padding": 0
  }
}
```

### Script Field Name Update (Low Priority)

3. If fixing the script, update field names to match official schema:
   - `context_window.context_used` -> calculate from `current_usage` fields
   - `context_window.context_limit` -> `context_window.context_window_size`
   - Or simply use `context_window.used_percentage` directly (pre-calculated)

## References

- [Claude Code Statusline Documentation](https://code.claude.com/docs/en/statusline) - Official statusLine schema and examples
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) - Valid hook event names and schema
- [GitHub Issue #5404](https://github.com/anthropics/claude-code/issues/5404) - statusLine documentation request (now documented)
- [GitHub Issue #13517](https://github.com/anthropics/claude-code/issues/13517) - External script invocation bug (OPEN)
- [GitHub Issue #17020](https://github.com/anthropics/claude-code/issues/17020) - statusLine not working in 2.1.1 (duplicate of #13517)

## Next Steps

1. Fix `~/.claude/settings.json` by moving statusLine to top-level
2. Test if external script is invoked
3. If script not invoked, apply inline command workaround
4. Verify /tmp/claude-context.json is being created/updated
5. Test Neovim lualine integration (depends on task 32 implementation)
