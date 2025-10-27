# Standard Output Patterns

This template defines consistent output patterns for all commands and agents to minimize console noise and maintain context usage below 30%.

## Minimal Success Pattern

For successful operations, use this concise format:

```
✓ [Operation] Complete
Artifact: [absolute-path]
Summary: [1-2 line description]
```

### Examples

```
✓ Report Complete
Artifact: /home/benjamin/.config/specs/042_auth/reports/001_patterns.md
Summary: Analyzed authentication patterns, identified 3 security best practices
```

```
✓ Plan Complete
Artifact: /home/benjamin/.config/specs/042_auth/plans/001_implementation.md
Summary: 5-phase implementation plan with 23 tasks
```

```
✓ Implementation Complete
Artifact: /home/benjamin/.config/specs/042_auth/summaries/001_summary.md
Summary: All 5 phases completed successfully, 18 files modified
```

## Minimal Error Pattern

For failed operations, use this concise format:

```
✗ [Operation] Failed
Error: [brief error message]
Details: [path-to-log or additional-context]
```

### Examples

```
✗ Implementation Failed
Error: Phase 3 tests failed (2 failures)
Details: See .claude/data/logs/implement-20251016.log
```

```
✗ Report Creation Failed
Error: Unable to determine topic directory
Details: No matching topic found for "user authentication"
```

## Progress Markers

For long-running operations, emit progress markers at key stages:

```
PROGRESS: [Stage] - [Brief status]
```

### Examples

```
PROGRESS: Research - Analyzing codebase patterns
PROGRESS: Research - Searching external best practices
PROGRESS: Report - Synthesizing findings
PROGRESS: Report - Writing recommendations
```

```
PROGRESS: Phase 1/5 - Template extraction
PROGRESS: Phase 2/5 - Agent optimization
PROGRESS: Phase 3/5 - Standards compliance
```

## Context Optimization Principles

### 1. Progressive Disclosure

Default to minimal output with details available via file links:
- Console: Summary + file path only
- Files: Complete details, logs, traces
- Verbose mode: Optional future enhancement

### 2. External Memory Pattern

Store detailed information in files, not console output:
- Logs: `.claude/data/logs/`
- Reports: `specs/{topic}/reports/`
- Artifacts: `specs/{topic}/artifacts/`

### 3. Standardized Formatting

Use consistent formatting across all commands:
- Success: Checkmark (✓) prefix
- Failure: Cross (✗) prefix
- Progress: "PROGRESS:" prefix
- Always include absolute paths
- Keep summaries to 1-2 lines

### 4. Stream Separation (Future)

Reserved for future implementation:
- `stdout`: Results and file paths only
- `stderr`: Progress messages and status updates
- Enables filtering for scripting

## Command-Specific Patterns

### /report Command

```
PROGRESS: Research - Analyzing topic
PROGRESS: Report - Creating structure
✓ Report Complete
Artifact: /path/to/specs/{topic}/reports/NNN_report.md
Summary: [Key findings in 1-2 lines]
```

### /debug Command

```
PROGRESS: Investigation - Gathering evidence
PROGRESS: Investigation - Root cause analysis
✓ Debug Report Complete
Artifact: /path/to/specs/{topic}/debug/NNN_debug.md
Summary: [Root cause in 1 line]
```

### /plan Command

```
PROGRESS: Planning - Analyzing requirements
PROGRESS: Planning - Structuring phases
✓ Plan Complete
Artifact: /path/to/specs/{topic}/plans/NNN_plan.md
Summary: [N phases, M tasks]
```

### /implement Command

```
PROGRESS: Phase 1/N - [Phase name]
PROGRESS: Testing - Running phase 1 tests
PROGRESS: Phase 2/N - [Phase name]
...
✓ Implementation Complete
Artifact: /path/to/specs/{topic}/summaries/NNN_summary.md
Summary: All N phases completed, M files modified
```

### /orchestrate Command

```
PROGRESS: Research Phase - [N agents executing]
PROGRESS: Planning Phase - Synthesizing findings
PROGRESS: Implementation Phase - Wave 1 (M phases)
PROGRESS: Documentation Phase - Updating docs
✓ Workflow Complete
Artifact: /path/to/specs/{topic}/summaries/NNN_summary.md
Summary: [Feature implemented, key changes]
```

## Agent Response Patterns

Agents should return minimal responses summarizing their work:

### Successful Agent Response

```
✓ [Agent Task] Complete
Files Modified: N
Key Changes:
- [Change 1]
- [Change 2]
Details: [path-to-agent-artifact]
```

### Failed Agent Response

```
✗ [Agent Task] Failed
Error: [Brief description]
Recovery: [Suggested next steps]
Details: [path-to-error-log]
```

## Testing Output

Test commands should show only essential information:

### Test Success

```
✓ Tests Passed (N/N)
Coverage: XX%
Duration: Xs
```

### Test Failure

```
✗ Tests Failed (N/M passed)
Failures:
- test_name_1: [brief reason]
- test_name_2: [brief reason]
Details: [path-to-test-log]
```

## Benefits

1. **Reduced Token Usage**: 70-80% reduction in console output
2. **Better Context Management**: Details stored externally, not in conversation
3. **Consistent User Experience**: Same pattern across all commands
4. **Scriptable**: Easy to parse success/failure programmatically
5. **Progressive Disclosure**: Users can dig deeper via file links when needed

## Implementation Guidelines

### For Commands

1. Replace verbose output with progress markers
2. Write detailed logs to files
3. Use standardized success/error patterns
4. Always provide absolute paths
5. Keep summaries to 1-2 lines

### For Agents

1. Return structured responses with key changes
2. Store detailed work in artifacts
3. Minimize response token count
4. Focus on actionable information
5. Link to artifacts for details

### For Tests

1. Show pass/fail counts and coverage
2. List only failed test names (not full traces)
3. Link to detailed test logs
4. Keep duration visible for performance tracking

## Migration Notes

When updating existing commands to use these patterns:

1. Identify current verbose output sections
2. Move detailed output to log files
3. Replace with progress markers + minimal summary
4. Update agent invocations to expect minimal responses
5. Test that all essential information is still accessible
6. Verify context usage reduction

## References

- CLAUDE.md: Development Philosophy → Context Optimization
- `.claude/lib/context-monitor.sh`: Context usage tracking
- Orchestration patterns: `.claude/templates/orchestration-patterns.md`
