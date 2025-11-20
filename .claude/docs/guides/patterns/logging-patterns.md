# Logging Patterns Reference

This file contains standardized logging patterns for agents and commands to ensure consistent, parseable output.

## Table of Contents

1. [Progress Markers](#progress-markers)
2. [Structured Logging Format](#structured-logging-format)
3. [Error Logging Patterns](#error-logging-patterns)
4. [Summary Report Format](#summary-report-format)
5. [File Path Output Format](#file-path-output-format)

---

## Progress Markers

### Overview

Progress markers provide real-time visibility into long-running operations. They are designed to be:
- **Parse-friendly**: Use consistent `PROGRESS:` prefix
- **Informative**: Include phase/action context
- **Actionable**: Show what's happening now

### Format

```
PROGRESS: [phase/context] - [action_description]
```

### Phase Transition Markers

**Workflow Phase Transitions**:
```
PROGRESS: Starting Research Phase (parallel execution)
PROGRESS: Research Phase complete - 3 reports created
PROGRESS: Starting Planning Phase (sequential execution)
PROGRESS: Planning Phase complete - plan created
PROGRESS: Starting Implementation Phase (adaptive execution)
PROGRESS: Implementation Phase complete - tests passing
PROGRESS: Starting Debugging Phase (conditional execution)
PROGRESS: Debugging Phase complete - all issues resolved
PROGRESS: Starting Documentation Phase (sequential execution)
PROGRESS: Documentation Phase complete - workflow summary generated
```

**Implementation Phase Transitions**:
```
PROGRESS: Starting Phase 1 - Database Schema
PROGRESS: Phase 1 complete - tests passing
PROGRESS: Starting Phase 2 - Authentication Service
PROGRESS: Phase 2 complete - tests passing
PROGRESS: Starting Phase 3 - API Endpoints
PROGRESS: Phase 3 complete - tests passing
```

### Agent Invocation Markers

**Context-Efficient Logging** (see [Command Architecture Standards - Standard 6](../reference/architecture/overview.md#standard-6)):

When logging artifact references, use **metadata-only** format to minimize context usage:

```bash
# Instead of logging full content (5000 tokens)
PROGRESS: Report created with content: [entire report content...]

# Log metadata only (250 tokens) - 95% reduction
PROGRESS: Report created: specs/042_auth/reports/001_jwt_patterns.md
PROGRESS: Report metadata: {path, 50-word summary, key_findings}
```

**Research Agents (Parallel)**:
```
PROGRESS: Invoking 3 research-specialist agents in parallel...
PROGRESS: Research agent 1/3 started (existing_patterns)
PROGRESS: Research agent 1/3 completed (existing_patterns) - 3m 12s
PROGRESS: Research agent 2/3 started (security_practices)
PROGRESS: Research agent 2/3 completed (security_practices) - 3m 45s
PROGRESS: Research agent 3/3 started (framework_implementations)
PROGRESS: Research agent 3/3 completed (framework_implementations) - 2m 58s
PROGRESS: All research agents complete - parallelization saved 4m 23s
```

**Planning Agent (Sequential)**:
```
PROGRESS: Invoking plan-architect agent...
PROGRESS: Plan architect analyzing research reports...
PROGRESS: Plan architect synthesizing implementation plan...
PROGRESS: Plan created: specs/plans/042_user_authentication.md
```

**Implementation Agent (Adaptive)**:
```
PROGRESS: Invoking code-writer agent with /implement...
PROGRESS: Implementation Phase 1/5 started
PROGRESS: Implementation Phase 1/5 complete - tests passing
PROGRESS: Implementation Phase 2/5 started
PROGRESS: Implementation Phase 2/5 in progress (7/12 tasks)
PROGRESS: Implementation Phase 2/5 complete - tests passing
```

**Debug Agent (Conditional)**:
```
PROGRESS: Entering debugging loop (iteration 1/3)
PROGRESS: Invoking debug-specialist agent...
PROGRESS: Debug specialist analyzing test failures...
PROGRESS: Debug report created: debug/test_failures/001_auth_timeout.md
PROGRESS: Applying recommended fix via code-writer agent...
PROGRESS: Fix applied - running tests...
PROGRESS: Tests passing ✓ - debugging complete
```

### File Operation Markers

**Creating Files**:
```
PROGRESS: Creating report file...
PROGRESS: Report created: specs/reports/existing_patterns/001_auth_patterns.md
PROGRESS: Creating plan file...
PROGRESS: Plan created: specs/plans/042_user_authentication.md
PROGRESS: Creating debug report...
PROGRESS: Debug report created: debug/test_failures/001_timeout.md
```

**Verifying Files**:
```
PROGRESS: Verifying report files created...
PROGRESS: Verified 1/3: specs/reports/topic1/001_report.md ✓
PROGRESS: Verified 2/3: specs/reports/topic2/002_report.md ✓
PROGRESS: Verified 3/3: specs/reports/topic3/003_report.md ✓
PROGRESS: All 3 reports verified and readable
```

**Checkpoint Operations**:
```
PROGRESS: Saving workflow checkpoint...
PROGRESS: Checkpoint saved: .claude/checkpoints/orchestrate_auth_20251012_143022.json
PROGRESS: Loading checkpoint from previous session...
PROGRESS: Checkpoint loaded - resuming from Phase 3
```

### Test Execution Markers

```
PROGRESS: Running tests for Phase 2...
PROGRESS: Executing: lua tests/test_auth_service.lua
PROGRESS: Test suite running (18 tests)...
PROGRESS: Tests complete - 18/18 passed ✓
PROGRESS: Running full test suite...
PROGRESS: Test progress: 45/120 tests (37%)
PROGRESS: Test suite complete - 115/120 passed (95%)
```

### Marker Density Guidelines

**Appropriate Frequency**:
- Phase transitions: Always
- Agent invocations: Start and completion
- Long-running operations: Every 10-30 seconds or significant progress
- File operations: Creation and verification
- Test execution: Start, progress (if >30s), completion

**Avoid Over-Logging**:
```
✗ PROGRESS: Reading file...
✗ PROGRESS: Parsing JSON...
✗ PROGRESS: Iterating array...
✗ PROGRESS: Processing item 1/100
✗ PROGRESS: Processing item 2/100
  (This is too granular - emit progress every 10% instead)

✓ PROGRESS: Processing 100 items...
✓ PROGRESS: Progress: 10/100 (10%)
✓ PROGRESS: Progress: 50/100 (50%)
✓ PROGRESS: Progress: 100/100 (100%)
✓ PROGRESS: Processing complete
```

---

## Structured Logging Format

### Overview

Structured logging enables programmatic parsing of agent output.

### Log Entry Format

**Standard Log Entry**:
```
[TIMESTAMP] [LEVEL] [COMPONENT] - Message
```

**Example**:
```
[2025-10-12T14:30:22] [INFO] [research-agent-1] - Starting research on existing_patterns
[2025-10-12T14:31:45] [INFO] [research-agent-1] - Found 12 relevant code files
[2025-10-12T14:33:12] [INFO] [research-agent-1] - Report created successfully
```

### Log Levels

```
DEBUG:   Detailed diagnostic information (verbose mode only)
INFO:    General informational messages (default)
WARNING: Warning messages for non-critical issues
ERROR:   Error messages for failures
CRITICAL: Critical failures requiring immediate attention
```

### Component Identifiers

```
orchestrator:        Main orchestration logic
research-agent-N:    Research specialist agents (N = 1, 2, 3...)
plan-architect:      Planning agent
code-writer:         Implementation agent
debug-specialist:    Debug agent
doc-writer:          Documentation agent
checkpoint-manager:  Checkpoint operations
test-runner:         Test execution
```

### Structured JSON Logging (Optional)

For programmatic parsing:
```json
{
  "timestamp": "2025-10-12T14:30:22.123Z",
  "level": "INFO",
  "component": "research-agent-1",
  "phase": "research",
  "action": "file_search",
  "message": "Found 12 relevant code files",
  "metadata": {
    "search_pattern": "auth*",
    "files_found": 12,
    "search_duration_ms": 234
  }
}
```

---

## Error Logging Patterns

### Overview

Error logging must provide actionable information for debugging and recovery.

### Error Format

**Standard Error**:
```
ERROR: [Component] - [Error Type]: [Error Message]

Context:
  - [Context Key 1]: [Context Value 1]
  - [Context Key 2]: [Context Value 2]

Stack Trace: (if available)
  [Stack trace details]

Recovery Suggestion:
  [Actionable recovery steps]
```

### Agent Invocation Errors

**Error Example**:
```
ERROR: [orchestrator] - Agent Invocation Failed: Task tool timeout

Context:
  - Agent Type: research-specialist
  - Topic: existing_patterns
  - Timeout Duration: 600s
  - Retry Attempt: 2/3

Recovery Suggestion:
  - Check agent prompt for excessive complexity
  - Consider splitting research topic into smaller scopes
  - Retry with reduced scope or extended timeout
```

### File Operation Errors

**Error Example**:
```
ERROR: [research-agent-1] - File Creation Failed: Permission denied

Context:
  - Target Path: /home/benjamin/.config/.claude/specs/reports/topic/001_report.md
  - Operation: Write
  - User: benjamin
  - Directory Permissions: drwxr-xr-x

Recovery Suggestion:
  - Verify write permissions on specs/reports/ directory
  - Check directory exists: mkdir -p .claude/specs/reports/topic/
  - Retry operation after fixing permissions
```

### Test Failure Errors

**Error Example**:
```
ERROR: [code-writer] - Test Execution Failed: 5 tests failed

Context:
  - Test Suite: tests/test_auth_service.lua
  - Tests Run: 18
  - Tests Passed: 13
  - Tests Failed: 5
  - Phase: Phase 2 (Authentication Service)

Failed Tests:
  1. test_jwt_token_expiry - Expected 3600s TTL, got 7200s
  2. test_invalid_credentials - Expected 401 status, got 500
  3. test_refresh_token_rotation - Token not rotated after refresh
  4. test_concurrent_login - Race condition detected
  5. test_password_hashing - Bcrypt rounds mismatch

Recovery Suggestion:
  - Enter debugging loop to investigate failures
  - Focus on test_jwt_token_expiry first (configuration issue)
  - Check auth service configuration for TTL settings
```

### Critical Errors

**Error Example**:
```
CRITICAL: [orchestrator] - Workflow Checkpoint Save Failed: Disk full

Context:
  - Checkpoint File: .claude/checkpoints/orchestrate_auth_latest.json
  - Disk Usage: 100% (0 bytes free)
  - Mount Point: /home
  - Phase: Implementation (Phase 3/5)
  - Retry Attempts: 3/3 (all failed)

Impact:
  - Workflow cannot be resumed if interrupted
  - Progress will be lost if session ends
  - Recommendation: Free disk space immediately

Recovery Suggestion:
  - Free disk space: df -h to check usage
  - Remove unnecessary files or expand disk
  - Manually save checkpoint to alternative location
  - Consider aborting workflow to prevent data loss
```

### Error Classification

**Error Types**:
```
transient:     Temporary failures (network timeout, rate limit)
recoverable:   Failures that can be fixed (permission, missing file)
configuration: Configuration errors (invalid settings)
system:        System-level failures (disk full, out of memory)
critical:      Unrecoverable failures requiring user intervention
```

### Error Recovery Logging

**Recovery Attempt**:
```
WARNING: [orchestrator] - Agent invocation failed (transient error)
INFO: [orchestrator] - Attempting retry 1/3 with 2s backoff...
INFO: [orchestrator] - Retry successful - agent invocation completed
```

**Recovery Failed**:
```
ERROR: [orchestrator] - Agent invocation failed after 3 retry attempts
ERROR: [orchestrator] - Error Type: timeout
ERROR: [orchestrator] - Escalating to user for manual intervention

User Action Required:
  1. Review agent prompt for complexity issues
  2. Consider splitting task into smaller units
  3. Manually retry agent invocation
  4. Or abort workflow and investigate root cause
```

---

## Summary Report Format

### Overview

Summary reports provide high-level overviews of completed workflows.

### Workflow Summary Format

**Implementation Summary**:
```markdown
# Implementation Summary: [Feature Name]

## Metadata
- **Date Completed**: 2025-10-12
- **Plan**: specs/plans/042_user_authentication.md
- **Research Reports**: 3 reports
  - specs/reports/jwt_patterns/001_existing_patterns.md
  - specs/reports/security/001_best_practices.md
  - specs/reports/token_refresh/001_alternatives.md
- **Phases Completed**: 5/5

## Implementation Overview

Implemented user authentication system with JWT tokens, refresh token rotation, and comprehensive security measures following industry best practices.

## Workflow Execution

### Research Phase
- **Duration**: 8 minutes
- **Agents Invoked**: 3 (parallel execution)
- **Parallelization Savings**: 4m 23s
- **Reports Created**: 3

### Planning Phase
- **Duration**: 5 minutes
- **Plan Created**: specs/plans/042_user_authentication.md
- **Phases Defined**: 5
- **Estimated Time**: 8-12 hours

### Implementation Phase
- **Duration**: 9 hours 15 minutes
- **Phases Completed**: 5/5
- **Tests Status**: All passing (42 tests, 100% coverage)
- **Files Modified**: 18
- **Commits Created**: 5

### Debugging Phase
- **Iterations**: 1/3
- **Issues Resolved**: JWT token expiry configuration
- **Debug Reports**: 1
  - debug/test_failures/001_jwt_expiry.md

### Documentation Phase
- **Duration**: 3 minutes
- **Documentation Updated**: README.md, API.md, CHANGELOG.md
- **Workflow Summary**: specs/summaries/042_implementation_summary.md

## Key Changes

- Implemented user database schema with migrations
- Created JWT authentication service with bcrypt password hashing
- Built authentication API endpoints (/auth/login, /auth/logout, /auth/refresh)
- Implemented automatic token refresh mechanism
- Added comprehensive integration tests covering full auth flow

## Test Results

- **Total Tests**: 42
- **Passed**: 42 (100%)
- **Failed**: 0
- **Coverage**: 100% (all auth code paths covered)
- **Test Duration**: 12.3s

## Performance Metrics

- **Total Duration**: 9 hours 31 minutes
- **Research Parallelization Savings**: 4 minutes 23 seconds
- **Debug Iterations**: 1 (resolved in first iteration)
- **Agents Invoked**: 6
  - 3 research-specialist agents
  - 1 plan-architect agent
  - 1 code-writer agent
  - 1 debug-specialist agent
  - 1 doc-writer agent
- **Files Created**: 18
- **Git Commits**: 5

## Cross-References

- **Research Reports**:
  - specs/reports/jwt_patterns/001_existing_patterns.md
  - specs/reports/security/001_best_practices.md
  - specs/reports/token_refresh/001_alternatives.md
- **Implementation Plan**: specs/plans/042_user_authentication.md
- **Debug Reports**: debug/test_failures/001_jwt_expiry.md
- **Code Changes**: Commits a3f8c2e, b7d4e1f, c8e2f3d, d9f4a5b, e1g5b6c

## Lessons Learned

- JWT token expiry configuration requires explicit setting (default differs by framework)
- Parallel research phase execution provides significant time savings (33% reduction)
- Comprehensive test coverage prevented regressions during debugging
- Clear separation of authentication service from API layer improved testability
```

### Phase Summary Format

**Phase Completion Summary**:
```
═══════════════════════════════════════════════════════════
Phase 2 Complete: Authentication Service
═══════════════════════════════════════════════════════════
Duration: 3h 12m
Tasks Completed: 12/12
Tests: All passing (test_auth_service.lua, test_jwt_middleware.lua)
Files Modified:
  - services/auth.lua (created)
  - middleware/jwt.lua (created)
  - tests/test_auth_service.lua (created)
  - tests/test_jwt_middleware.lua (created)
Commit: b7d4e1f "feat: implement JWT auth service"
═══════════════════════════════════════════════════════════
```

### Agent Summary Format

**Research Agent Summary**:
```
═══════════════════════════════════════════════════════════
Research Agent Summary: existing_patterns
═══════════════════════════════════════════════════════════
Duration: 3m 12s
Topic: JWT authentication patterns in existing codebase
Report: specs/reports/jwt_patterns/001_existing_patterns.md

Key Findings:
- Current auth uses session-based approach with Redis
- JWT pattern found in experimental branch (not production)
- Middleware architecture compatible with JWT integration

Primary Recommendation:
Extend existing auth service with JWT module while maintaining
session-based auth for backward compatibility.
═══════════════════════════════════════════════════════════
```

---

## File Path Output Format

### Overview

Consistent file path output enables programmatic parsing of created artifacts.

### Format

**Pattern**:
```
[FILE_TYPE]_PATH: [ABSOLUTE_PATH]
```

**File Types**:
```
REPORT_PATH:   Research report file
PLAN_PATH:     Implementation plan file
DEBUG_PATH:    Debug report file
SUMMARY_PATH:  Workflow summary file
COMMIT_HASH:   Git commit hash
```

### Examples

**Research Agent Output**:
```
REPORT_PATH: /home/benjamin/.config/.claude/specs/reports/jwt_patterns/001_existing_patterns.md

Research investigated current authentication patterns in the codebase.
Found session-based auth with Redis. Recommended extending with JWT module.
```

**Planning Agent Output**:
```
PLAN_PATH: /home/benjamin/.config/.claude/specs/plans/042_user_authentication.md

Plan created with 5 phases covering database schema, auth service, API endpoints,
token refresh, and integration testing. Estimated 8-12 hours total.
```

**Debug Agent Output**:
```
DEBUG_PATH: /home/benjamin/.config/debug/test_failures/001_jwt_expiry.md

Debug investigation identified JWT token expiry configuration issue.
Recommended setting explicit TTL in auth service config.
```

**Documentation Agent Output**:
```
SUMMARY_PATH: /home/benjamin/.config/.claude/specs/summaries/042_implementation_summary.md

Workflow summary generated covering all 5 phases with performance metrics
and cross-references to all artifacts created.
```

**Implementation Phase Output**:
```
COMMIT_HASH: b7d4e1f

Phase 2 implementation complete. Created JWT auth service and middleware
with comprehensive test coverage. All tests passing.
```

### Path Parsing Pattern

**Bash Parsing**:
```bash
# Parse report path from agent output
REPORT_PATH=$(grep "^REPORT_PATH:" agent_output.txt | cut -d: -f2- | tr -d ' ')

# Verify file exists
if [ -f "$REPORT_PATH" ]; then
  echo "✓ Report verified: $REPORT_PATH"
else
  echo "✗ Report missing: $REPORT_PATH"
fi
```

**Python Parsing**:
```python
import re

# Parse all file paths from output
def parse_file_paths(output):
    pattern = r'(\w+)_PATH:\s*(.+)'
    matches = re.findall(pattern, output)

    paths = {}
    for file_type, path in matches:
        paths[file_type.lower()] = path.strip()

    return paths

# Usage
output = agent_output_string
paths = parse_file_paths(output)
print(f"Report: {paths.get('report')}")
print(f"Plan: {paths.get('plan')}")
```

### Multiple Path Output

When multiple files are created:
```
REPORT_PATH_1: /home/benjamin/.config/.claude/specs/reports/topic1/001_report.md
REPORT_PATH_2: /home/benjamin/.config/.claude/specs/reports/topic2/002_report.md
REPORT_PATH_3: /home/benjamin/.config/.claude/specs/reports/topic3/003_report.md

All 3 research reports created successfully.
```

---

## Output vs Error Distinction

### Overview

Output suppression patterns reduce visual noise in Claude Code display while preserving critical error visibility. This section clarifies what to suppress vs preserve.

### What to Suppress

| Category | Examples | Action |
|----------|----------|--------|
| Success messages | "File created", "Operation complete" | Suppress with `>/dev/null` |
| Progress indicators | "Processing...", "Loading..." | Remove entirely |
| Intermediate state | "Setting X to Y", "Validated Z" | Suppress |
| Library initialization | Function definitions, module loads | Suppress with `2>/dev/null` |

**Pattern**:
```bash
# Suppress verbose library output
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source library" >&2
  exit 1
}

# Suppress directory operations
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
```

### What to Preserve

| Category | Examples | Action |
|----------|----------|--------|
| Errors | "ERROR: File not found" | Print to stderr |
| Warnings | "WARN: Deprecated pattern" | Print to stderr |
| Final summaries | "Setup complete: workflow_123" | Single line per block |
| User-needed data | File paths, URLs, identifiers | Print explicitly |

**Pattern**:
```bash
# Errors to stderr (always visible)
echo "ERROR: Configuration invalid" >&2

# Final summary to stdout (minimal)
echo "Setup complete: $WORKFLOW_ID"
```

### Single Summary Line per Block

Each bash block should output a single summary line instead of multiple progress messages:

```bash
# ❌ ANTI-PATTERN: Multiple verbose messages
echo "Starting initialization..."
echo "Loading libraries..."
echo "Validating configuration..."
echo "Creating directories..."
echo "Initialization complete"

# ✓ CORRECT: Single summary
# Perform all operations silently
source "$LIB" 2>/dev/null || exit 1
validate_config || exit 1
mkdir -p "$DIR" 2>/dev/null

echo "Setup complete: $WORKFLOW_ID"
```

### Relationship to Error Enhancement

Output suppression applies to **success and progress output only**. Errors remain verbose per [Error Enhancement Guide](error-enhancement-guide.md) standards:

- Errors use WHICH/WHAT/WHERE structure
- Errors include resolution guidance
- Errors are not suppressed

### Related Documentation

See [Output Formatting Standards](../reference/standards/output-formatting.md) for:
- Complete output suppression patterns
- Block consolidation rules
- Comment standards (WHAT not WHY)

---

## Usage Notes

### Referencing This File

From agents and commands:
```markdown
For standardized logging patterns, see:
`.claude/docs/logging-patterns.md`
```

### Section-Specific References

**Progress Markers**:
```markdown
Use progress markers as defined in:
`.claude/docs/logging-patterns.md#progress-markers`
```

**Error Logging**:
```markdown
Follow error logging format from:
`.claude/docs/logging-patterns.md#error-logging-patterns`
```

**File Path Output**:
```markdown
Output file paths using format from:
`.claude/docs/logging-patterns.md#file-path-output-format`
```

### Updating Patterns

When updating logging patterns:
1. Update this file with new pattern specifications
2. Update affected agents to use new patterns
3. Update parsing utilities to handle new formats
4. Test with real agent executions
5. Document changes in git commit message

### Best Practices

**DO**:
- Use consistent `PROGRESS:` prefix for progress markers
- Include context in error messages (file paths, retry counts)
- Provide actionable recovery suggestions for errors
- Output file paths in parseable format (`FILE_TYPE_PATH: /absolute/path`)
- Include timestamps for log entries
- Structure summaries with clear sections and metrics

**DON'T**:
- Over-log granular operations (avoid marker spam)
- Use relative file paths in output (always absolute)
- Mix logging formats (choose structured or unstructured, be consistent)
- Omit recovery suggestions from error messages
- Log sensitive information (passwords, tokens, API keys)

---

**Last Updated**: 2025-10-13
**Used By**: /orchestrate, /report, /plan, /implement, /debug, /document
**Related Files**:
- `.claude/agents/research-specialist.md`
- `.claude/agents/plan-architect.md`
- `.claude/agents/doc-converter.md`
- `.claude/docs/reference/workflows/orchestration-reference.md`
