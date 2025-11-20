# Error Handling Guidelines

This document defines standard error handling patterns for all agents.

## Purpose

Consistent error handling across agents ensures:
- Predictable behavior during failures
- Appropriate retry strategies
- Clear error reporting to users
- Graceful degradation when possible

## Error Classification

### Transient Errors (Retryable)

Errors that may succeed on retry:

**File System**:
- Temporary file locks
- NFS mount delays
- Disk quota near limit (retry after cleanup)
- Permission issues (may resolve)

**External Commands**:
- Flaky tests (race conditions, timing issues)
- Network timeouts (external services)
- Resource temporarily unavailable

**Detection**: Error message contains keywords like "locked", "busy", "timeout", "temporary"

**Retry Strategy**: 2-3 retries with exponential backoff

### Permanent Errors (Non-Retryable)

Errors that won't succeed on retry:

**Syntax/Compilation**:
- Code syntax errors
- Type errors
- Import/require failures

**Logic Errors**:
- Test failures due to bugs
- Validation failures
- Assertion errors

**Configuration**:
- Missing required files
- Invalid configuration values
- Incompatible versions

**Detection**: Error message indicates code-level issues

**Strategy**: Analyze error, attempt fix, then retry

### Fatal Errors (Abort)

Errors that require user intervention:

**Environment**:
- Out of disk space
- Insufficient permissions (cannot be fixed)
- Missing required tools

**Invariant Violations**:
- Corrupted data structures
- Unexpected state transitions
- Critical file missing (not recoverable)

**Detection**: System-level errors, corrupted state

**Strategy**: Report to user, suggest resolution, abort operation

## Retry Strategies

### Exponential Backoff

For transient errors, use exponential backoff:

```
Attempt 1: Immediate
Attempt 2: 500ms delay
Attempt 3: 1000ms delay
Attempt 4: 2000ms delay
```

**Maximum Retries**: 3-4 attempts total
**Maximum Delay**: 5 seconds between attempts

### Retry Policy by Operation

#### File Writes
- **Retries**: 2
- **Delay**: 500ms
- **Pre-Retry Check**: Verify disk space, check permissions
- **Example**: Temporary file locks, NFS delays

#### Test Execution
- **Retries**: 2 (for test command failures only)
- **Delay**: 1 second
- **Pre-Retry Check**: None
- **Example**: Flaky tests, race conditions

**Note**: Test _failures_ (tests that run but fail) are not retried - they indicate bugs

#### External API Calls
- **Retries**: 3
- **Delay**: Exponential (500ms, 1s, 2s)
- **Pre-Retry Check**: Verify network connectivity
- **Example**: GitHub API rate limits, network timeouts

#### Tool Invocations
- **Retries**: 1
- **Delay**: None
- **Pre-Retry Check**: Verify tool exists
- **Example**: Tool temporarily busy

## Fallback Strategies

When initial approach fails, try alternative approaches:

### 1. Complex Edit → Simpler Edit

If large string replacement fails:

```
Primary: Edit(file, large_multi_line_replacement)
  ↓ (fails)
Fallback 1: Break into smaller Edits
  Edit(file, section1)
  Edit(file, section2)
  Edit(file, section3)
  ↓ (fails)
Fallback 2: Write entire file
  Write(file, complete_content)
```

### 2. Unknown Test Command → Language Defaults

If configured test command fails:

```
Primary: Run command from CLAUDE.md
  ↓ (not found/fails)
Fallback: Try language-specific defaults
  - Lua: :TestNearest or busted
  - Python: pytest or python -m unittest
  - JavaScript: npm test or jest
  - Shell: bats or manual execution
```

### 3. Missing Standards → Sensible Defaults

If CLAUDE.md not found:

```
Primary: Read CLAUDE.md for standards
  ↓ (not found)
Fallback: Use language-specific conventions
  - Lua: 2 spaces, snake_case, pcall
  - Python: 4 spaces, snake_case, try-except
  - JavaScript: 2 spaces, camelCase, try-catch

Action: Document assumption, suggest running /setup
```

## Graceful Degradation

When full operation cannot be completed:

### Partial Implementation

```
Goal: Implement 5 functions
Problem: Function 3 requires external API (not available)
Solution:
  - Implement functions 1, 2, 4, 5
  - Stub function 3 with TODO and explanation
  - Document what's missing
  - Report 80% completion
```

### Reduced Functionality

```
Goal: Generate comprehensive report
Problem: Some data sources unavailable
Solution:
  - Generate report with available data
  - Note missing sections clearly
  - Explain limitations
  - Suggest manual completion steps
```

### Conservative Approach

```
Goal: Refactor complex code
Problem: Uncertain about side effects
Solution:
  - Apply only safe refactorings
  - Mark risky changes with TODO
  - Document uncertainty
  - Request user review for complex changes
```

## Error Reporting

### Error Message Structure

```
[Error Type]: [Specific Error]

Context:
- Operation: [what was being attempted]
- File/Location: [where it failed]
- Attempt: [which retry attempt]

Attempted Resolution:
- [what recovery was tried]
- [result of recovery attempt]

Next Steps:
- [what user should do OR what agent will try next]
```

### Example Error Report

```
File Write Error: Permission denied

Context:
- Operation: Writing test file
- File: /protected/dir/test.lua
- Attempt: 3 of 3 (all failed)

Attempted Resolution:
- Checked disk space: OK (15GB free)
- Verified file path: OK
- Retried with delays: Failed

Next Steps:
User action required:
1. Check permissions on /protected/dir/
2. Run: chmod u+w /protected/dir/
3. Re-run this operation
```

## Error Handling Patterns

### Pattern 1: Retry with Backoff

```bash
max_attempts=3
attempt=1
delay=500  # milliseconds

while [ $attempt -le $max_attempts ]; do
  if perform_operation; then
    success=true
    break
  else
    if [ $attempt -lt $max_attempts ]; then
      sleep $(($delay / 1000))
      delay=$(($delay * 2))  # Exponential backoff
      attempt=$(($attempt + 1))
    fi
  fi
done

if [ ! $success ]; then
  report_error_and_abort
fi
```

### Pattern 2: Fallback Chain

```bash
# Try primary approach
if ! primary_approach; then
  # Try fallback 1
  if ! fallback_1; then
    # Try fallback 2
    if ! fallback_2; then
      # All approaches failed
      report_error_and_abort
    fi
  fi
fi
```

### Pattern 3: Partial Success

```bash
total_tasks=10
completed=0
failed=()

for task in $tasks; do
  if perform_task $task; then
    completed=$(($completed + 1))
  else
    failed+=($task)
  fi
done

if [ $completed -eq $total_tasks ]; then
  report_complete_success
elif [ $completed -gt 0 ]; then
  report_partial_success $completed $total_tasks "${failed[@]}"
else
  report_complete_failure
fi
```

## Agent-Specific Error Handling

### Code Writer

**Syntax Errors**: Parse error message, identify issue, fix code, retry
**Test Failures**: Analyze failure, determine if bug or flaky test, fix or retry
**File Conflicts**: Detect concurrent modifications, merge or abort

### Test Specialist

**Test Discovery Failures**: Fall back to file pattern matching
**Test Execution Timeouts**: Increase timeout, retry once
**Flaky Tests**: Run 2-3 times, report intermittent failures

### Research Specialist

**Search Failures**: Try alternative search patterns
**Missing Documentation**: Note limitation in report
**API Rate Limits**: Wait and retry with exponential backoff

### Debug Specialist

**Cannot Reproduce**: Note in report, provide debugging steps for user
**Ambiguous Root Cause**: Document multiple possibilities
**Missing Debug Info**: Request additional context from user

## Best Practices

### Do

✅ **Classify errors accurately** (transient vs permanent vs fatal)
✅ **Use appropriate retry strategies** (exponential backoff for transient)
✅ **Provide clear error messages** (what failed, why, what's next)
✅ **Log all retry attempts** (helps with debugging)
✅ **Degrade gracefully** (partial success better than complete failure)

### Don't

❌ **Retry permanent errors** (won't help, wastes time)
❌ **Infinite retry loops** (set max attempts)
❌ **Silent failures** (always report what went wrong)
❌ **Vague error messages** ("something failed")
❌ **Give up too early** (try fallbacks when reasonable)

## Integration with Progress Streaming

Coordinate error handling with progress updates:

```
PROGRESS: Writing configuration file...
[Write fails]
PROGRESS: Write failed, retrying (attempt 2 of 3)...
[Retry succeeds]
PROGRESS: Configuration file written successfully.
```

Or on failure:

```
PROGRESS: Running test suite...
[Tests fail]
PROGRESS: Tests failed (3 of 45 tests failing).

Error: Test Failures

[Detailed error report]
```

## Recovery Strategies

### Self-Healing

When possible, automatically recover:
- Fix simple syntax errors
- Adjust formatting
- Update imports
- Resolve minor conflicts

### User Escalation

When recovery not possible:
- Provide clear error description
- Explain what was attempted
- Suggest specific user actions
- Offer to retry after user fixes issue

### Checkpoint and Resume

For long operations:
- Save progress before risky operations
- Enable resume from checkpoint on failure
- Document partial completion state

## Error Return Protocol

When agents encounter unrecoverable errors, they must return structured error signals for parent command parsing and centralized logging.

### Error Signal Format

Agents must output both `ERROR_CONTEXT` (JSON) and `TASK_ERROR` (human-readable) signals:

```bash
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Invalid complexity score",
  "details": {"score": 150, "max": 100}
}

TASK_ERROR: validation_error - Invalid complexity score: 150 exceeds maximum 100
```

### Standardized Error Types

Use these error types consistently across all agents:

| Error Type | Usage | Example |
|------------|-------|---------|
| `validation_error` | Input validation failures | Invalid argument value, missing required field |
| `file_error` | File system operations failures | File not found, permission denied, corrupted file |
| `parse_error` | Output parsing failures | Invalid JSON, malformed data structure |
| `execution_error` | General execution failures | Command failed, operation timeout |
| `timeout_error` | Operation timeout errors | Network request timeout, process timeout |
| `state_error` | Workflow state issues | State file missing, invalid state transition |
| `dependency_error` | Missing or invalid dependencies | Required tool not installed, library not found |
| `agent_error` | Subagent failures | Nested agent returned error |

### When to Return Error Signals

Return error signals when:
- ✅ All retry attempts exhausted
- ✅ Fatal error encountered (cannot continue)
- ✅ Required dependency missing
- ✅ Invalid input that cannot be recovered
- ✅ Workflow state corruption detected

Do NOT return error signals for:
- ❌ Transient errors (retry instead)
- ❌ Warnings or non-fatal issues
- ❌ Partial success (report partial completion instead)
- ❌ Recoverable errors (attempt recovery first)

### Parent Command Integration

Parent commands parse agent error signals using `parse_subagent_error()`:

```bash
# In parent command
agent_output=$(Task {
  subagent_type: "general-purpose"
  prompt: "Execute research task..."
})

# Parse agent error signals
if echo "$agent_output" | grep -q "TASK_ERROR:"; then
  parse_subagent_error "$agent_output" "research-specialist"
  exit 1
fi
```

The `parse_subagent_error()` function:
1. Extracts ERROR_CONTEXT JSON from agent output
2. Extracts TASK_ERROR signal for user display
3. Logs error to centralized log with full workflow context
4. Preserves workflow_id, user_args, command_name from parent

### Example Error Return Flow

**Agent Output**:
```
Research analysis complete for 3 of 5 topics.

ERROR_CONTEXT: {
  "error_type": "timeout_error",
  "message": "Network request timeout for topic: advanced-patterns",
  "details": {
    "url": "https://docs.example.com/advanced",
    "timeout_seconds": 30,
    "attempt": 3
  }
}

TASK_ERROR: timeout_error - Network request timeout after 3 attempts (30s each)
```

**Parent Command Handling**:
```bash
parse_subagent_error "$agent_output" "research-specialist"
# Logs to .claude/data/errors.jsonl:
# {
#   "timestamp": "2025-11-19T10:30:45Z",
#   "error_type": "timeout_error",
#   "command_name": "/research",
#   "workflow_id": "research_1732017045",
#   "user_args": "advanced-patterns security-best-practices",
#   "agent_name": "research-specialist",
#   "message": "Network request timeout after 3 attempts (30s each)",
#   "details": "{\"url\":\"https://docs.example.com/advanced\",...}"
# }
exit 1
```

### Best Practices

**Do**:
- ✅ Always include both ERROR_CONTEXT (JSON) and TASK_ERROR (human-readable)
- ✅ Use standardized error types from the table above
- ✅ Include specific details in ERROR_CONTEXT.details field
- ✅ Make TASK_ERROR message clear and actionable
- ✅ Return error signals only after all recovery attempts

**Don't**:
- ❌ Return partial ERROR_CONTEXT (missing fields)
- ❌ Use custom error types not in standard list
- ❌ Include sensitive information in error messages
- ❌ Return error signals for warnings or partial success
- ❌ Omit critical context (what operation failed, where, why)

### References

- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) - Complete pattern documentation
- [Error Handling API Reference](.claude/docs/reference/library-api/error-handling.md) - Function signatures
- [Architecture Standard 17](.claude/docs/reference/architecture/error-handling.md#standard-17-centralized-error-logging-integration) - Centralized logging requirement

---

## See Also

- [Progress Streaming Protocol](progress-streaming-protocol.md) - How to report progress
- [Agent README](../README.md) - Overview of agent architecture
