---
paths: .claude/**/*
---

# Error Handling Rules

## Error Categories

### Operational Errors
Errors during command execution:
- `delegation_hang` - Subagent not responding
- `timeout` - Operation exceeded time limit
- `validation_failed` - Input validation failure

### State Errors
Errors in state management:
- `status_sync_failure` - TODO.md/state.json desync
- `file_not_found` - Expected file missing
- `parse_error` - JSON/YAML parse failure

### External Errors
Errors from external systems:
- `git_commit_failure` - Git operation failed
- `build_error` - Lean/lake build failed
- `tool_unavailable` - MCP tool not responding

## Error Response Pattern

When an error occurs:

### 1. Log the Error
Record in errors.json:
```json
{
  "id": "err_{timestamp}",
  "timestamp": "ISO_DATE",
  "type": "error_type",
  "severity": "critical|high|medium|low",
  "message": "Error description",
  "context": {
    "command": "/implement",
    "task": 259,
    "phase": 2
  },
  "fix_status": "unfixed"
}
```

### 2. Preserve Progress
- Never lose completed work
- Keep partial results
- Mark phases as [PARTIAL] not failed

### 3. Enable Resume
- Store resume point information
- Next invocation continues from failure point

### 4. Report Clearly
Return structured error:
```json
{
  "status": "failed|partial",
  "error": {
    "type": "error_type",
    "message": "What happened",
    "recovery": "How to fix"
  },
  "progress": {
    "completed": ["phase1", "phase2"],
    "failed_at": "phase3"
  }
}
```

## Severity Levels

| Severity | Description | Response |
|----------|-------------|----------|
| critical | System unusable | Stop, alert, require manual fix |
| high | Feature broken | Log, attempt recovery |
| medium | Degraded function | Log, continue with workaround |
| low | Minor issue | Log, ignore |

## Recovery Strategies

### Timeout Recovery
```
1. Save partial progress
2. Mark current phase [PARTIAL]
3. Git commit progress
4. Next /implement resumes
```

### State Sync Recovery
```
1. Read both files
2. Use git blame for latest
3. Sync to latest version
4. Log resolution
```

### Build Error Recovery
```
1. Capture error output
2. Log to errors.json
3. Keep source unchanged
4. Report error with context
```

## Non-Blocking Errors

These should not stop execution:
- Git commit failures
- Metric collection failures
- Non-critical logging failures

Log and continue, report at end.
