# Coordinator Return Signals Standard

**Purpose**: Define standardized return signal contracts for all coordinator agents to enable consistent parsing and error handling by orchestrator commands.

**Status**: Production-ready (implemented in 5+ coordinators)

**Applies To**: All coordinator/supervisor agents in `.claude/agents/`

**Related Documentation**:
- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Five core patterns
- [Three-Tier Coordination Pattern](../../concepts/three-tier-coordination-pattern.md) - Communication protocols

---

## Overview

Coordinator agents return structured signals to orchestrators indicating completion status, metadata summaries, and continuation requirements. Standardized signal formats enable consistent parsing logic across all commands.

**Signal Components**:
1. **Completion Signal** - Primary status indicator (SUCCESS, PARTIAL_SUCCESS, ERROR)
2. **Metadata Fields** - coordinator_type, summary_brief, phases_completed, etc.
3. **Continuation Fields** - requires_continuation, work_remaining, context_exhausted
4. **Error Fields** - ERROR_CONTEXT JSON, TASK_ERROR signal

---

## research-coordinator

### Signal Format

```yaml
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
coordinator_type: research
topics_planned: 4
topics_completed: 4
invocation_plan_path: /abs/path/.invocation-plan.txt
context_usage_percent: 8

INVOCATION_PLAN_READY: 4
invocations: [
  {"topic": "Topic 1", "report_path": "/path/001.md"},
  {"topic": "Topic 2", "report_path": "/path/002.md"},
  {"topic": "Topic 3", "report_path": "/path/003.md"},
  {"topic": "Topic 4", "report_path": "/path/004.md"}
]
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `coordinator_type` | string | Yes | Always "research" |
| `topics_planned` | integer | Yes | Total topics in invocation plan |
| `topics_completed` | integer | Partial | Number of successfully completed topics (100% or partial success) |
| `invocation_plan_path` | string | Yes | Absolute path to .invocation-plan.txt |
| `context_usage_percent` | integer | Yes | Coordinator context usage (5-10% for planning-only) |

### Parsing Example

```bash
# Extract coordinator type
COORDINATOR_TYPE=$(grep "^coordinator_type:" "$OUTPUT" | sed 's/^coordinator_type:[[:space:]]*//')

# Extract topics count
TOPICS_PLANNED=$(grep "^topics_planned:" "$OUTPUT" | sed 's/^topics_planned:[[:space:]]*//')

# Parse invocation plan
INVOCATION_PLAN_PATH=$(grep "^invocation_plan_path:" "$OUTPUT" | sed 's/^invocation_plan_path:[[:space:]]*//')

# Parse invocations JSON array
INVOCATIONS=$(sed -n '/^INVOCATION_PLAN_READY:/,/^\]/p' "$OUTPUT" | grep -A 100 "^invocations:" | sed '1d')
```

---

## implementer-coordinator

### Signal Format

```yaml
IMPLEMENTATION_COMPLETE: SUCCESS
coordinator_type: software
summary_path: /abs/path/summaries/001_summary.md
summary_brief: "Completed Wave 1-2 (Phase 3,4) with 25 tasks. Context: 65%. Next: Continue Wave 3."
phases_completed: [3, 4]
phase_count: 2
git_commits: [abc123, def456]
plan_file: /abs/path/plans/001_plan.md
work_remaining: Phase_5 Phase_6
context_exhausted: false
context_usage_percent: 65
requires_continuation: true
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `coordinator_type` | string | Yes | "software", "lean", or "hybrid" |
| `summary_path` | string | Yes | Absolute path to implementation summary file |
| `summary_brief` | string | Yes | 80-token brief summary for iteration context reduction |
| `phases_completed` | array | Yes | List of completed phase numbers |
| `phase_count` | integer | Yes | Count of phases completed in this iteration |
| `git_commits` | array | Optional | List of git commit hashes created |
| `plan_file` | string | Yes | Absolute path to implementation plan |
| `work_remaining` | string | Yes | Space-separated list of remaining phases or "0" |
| `context_exhausted` | boolean | Yes | true if context ≥90%, false otherwise |
| `context_usage_percent` | integer | Yes | Estimated context usage percentage |
| `requires_continuation` | boolean | Yes | true if work_remaining > 0, false if complete |

### Parsing Example

```bash
# Extract brief summary (80 tokens vs 2,000 full file)
SUMMARY_BRIEF=$(grep "^summary_brief:" "$OUTPUT" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"')

# Parse phases completed array
PHASES_COMPLETED=$(grep "^phases_completed:" "$OUTPUT" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[]," ')

# Extract continuation requirement
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$OUTPUT" | sed 's/^requires_continuation:[[:space:]]*//')

# Check if more work needed
if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  echo "Continuing to next wave..."
else
  echo "Implementation complete"
fi
```

---

## testing-coordinator

### Signal Format

```yaml
TESTING_COMPLETE: SUCCESS
coordinator_type: testing
summary_path: /abs/path/summaries/001_test_summary.md
summary_brief: "Completed 4 test suites. Tests: 152 passed, 3 failed. Coverage: 87%."
test_suites_completed: [unit, integration, e2e, performance]
suite_count: 4
total_tests: 155
tests_passed: 152
tests_failed: 3
coverage_percent: 87
plan_file: /abs/path/plans/001_plan.md
work_remaining: 0
context_exhausted: false
requires_continuation: false
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `coordinator_type` | string | Yes | Always "testing" |
| `summary_path` | string | Yes | Absolute path to test summary file |
| `summary_brief` | string | Yes | Brief test results summary |
| `test_suites_completed` | array | Yes | List of completed test suite names |
| `suite_count` | integer | Yes | Number of test suites executed |
| `total_tests` | integer | Yes | Total test count across all suites |
| `tests_passed` | integer | Yes | Number of passing tests |
| `tests_failed` | integer | Yes | Number of failing tests |
| `coverage_percent` | integer | Yes | Code coverage percentage |
| `plan_file` | string | Yes | Absolute path to test plan |
| `work_remaining` | string | Yes | Remaining test suites or "0" |
| `context_exhausted` | boolean | Yes | Context usage indicator |
| `requires_continuation` | boolean | Yes | More testing needed indicator |

---

## debug-coordinator

### Signal Format

```yaml
DEBUG_COMPLETE: SUCCESS
coordinator_type: debug
summary_path: /abs/path/summaries/001_debug_summary.md
summary_brief: "Analyzed 3 investigation vectors. Root cause: Auth token expiration. Fix: Extend TTL."
vectors_completed: [codebase_analysis, error_logs, dependency_check]
vector_count: 3
root_causes_identified: 1
fix_recommendations: 3
plan_file: /abs/path/plans/001_debug_plan.md
work_remaining: 0
context_exhausted: false
requires_continuation: false
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `coordinator_type` | string | Yes | Always "debug" |
| `summary_path` | string | Yes | Absolute path to debug summary file |
| `summary_brief` | string | Yes | Brief root cause and fix summary |
| `vectors_completed` | array | Yes | List of investigation vectors executed |
| `vector_count` | integer | Yes | Number of vectors investigated |
| `root_causes_identified` | integer | Yes | Number of root causes found |
| `fix_recommendations` | integer | Yes | Number of fix recommendations |
| `plan_file` | string | Yes | Absolute path to debug plan |
| `work_remaining` | string | Yes | Remaining vectors or "0" |

---

## repair-coordinator

### Signal Format

```yaml
REPAIR_COMPLETE: SUCCESS
coordinator_type: repair
summary_path: /abs/path/summaries/001_repair_summary.md
summary_brief: "Analyzed 5 error dimensions. Pattern: Missing null checks. Fix plan: 8 phases."
dimensions_completed: [error_types, frequency, severity, recency, patterns]
dimension_count: 5
error_patterns_identified: 3
fix_plan_path: /abs/path/plans/001_fix_plan.md
estimated_fix_hours: 8-12
plan_file: /abs/path/plans/001_repair_plan.md
work_remaining: 0
context_exhausted: false
requires_continuation: false
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `coordinator_type` | string | Yes | Always "repair" |
| `summary_path` | string | Yes | Absolute path to repair summary file |
| `summary_brief` | string | Yes | Brief error pattern and fix summary |
| `dimensions_completed` | array | Yes | List of error dimensions analyzed |
| `dimension_count` | integer | Yes | Number of dimensions analyzed |
| `error_patterns_identified` | integer | Yes | Number of error patterns found |
| `fix_plan_path` | string | Yes | Absolute path to generated fix plan |
| `estimated_fix_hours` | string | Yes | Time estimate range (e.g., "8-12") |
| `plan_file` | string | Yes | Absolute path to repair plan |

---

## Error Signals (All Coordinators)

### Format

```
ERROR_CONTEXT: {"error_type":"validation_error","message":"Missing report_paths array","details":{"required_fields":["topics","report_paths"]}}

TASK_ERROR: validation_error - report_paths array not provided in input contract
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `error_type` | string | Yes | One of: validation_error, agent_error, parse_error, file_error, timeout_error, execution_error, dependency_error, state_error |
| `message` | string | Yes | Human-readable error description |
| `details` | object | Optional | Additional error context (missing fields, paths, etc.) |

### Parsing Example

```bash
# Check for error signal
if echo "$COORDINATOR_OUTPUT" | grep -q "^TASK_ERROR:"; then
  # Extract error type
  ERROR_TYPE=$(echo "$COORDINATOR_OUTPUT" | grep "^TASK_ERROR:" | sed 's/^TASK_ERROR: \([a-z_]*\) -.*/\1/')

  # Extract error message
  ERROR_MESSAGE=$(echo "$COORDINATOR_OUTPUT" | grep "^TASK_ERROR:" | sed 's/^TASK_ERROR: [a-z_]* - //')

  # Extract error context JSON
  ERROR_CONTEXT=$(echo "$COORDINATOR_OUTPUT" | grep "^ERROR_CONTEXT:" | sed 's/^ERROR_CONTEXT: //')

  # Log to centralized error log
  log_command_error "$ERROR_TYPE" "$ERROR_MESSAGE" "$ERROR_CONTEXT"

  # Display to user
  echo "ERROR: Coordinator failed - $ERROR_MESSAGE"
  exit 1
fi
```

---

## Common Fields Across All Coordinators

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `coordinator_type` | string | Coordinator category (research, software, lean, testing, debug, repair) |
| `summary_path` | string | Absolute path to coordinator-generated summary file |
| `plan_file` | string | Absolute path to associated plan or trace file |
| `work_remaining` | string | Remaining work items or "0" if complete |
| `context_exhausted` | boolean | true if context ≥90%, false otherwise |
| `requires_continuation` | boolean | true if work_remaining > 0, false if complete |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `summary_brief` | string | 80-token brief summary (recommended for iteration efficiency) |
| `context_usage_percent` | integer | Estimated context usage percentage |
| `git_commits` | array | Git commit hashes created during execution |

---

## Validation

### Signal Completeness Checklist

- [ ] Completion signal present (e.g., RESEARCH_COORDINATOR_COMPLETE: SUCCESS)
- [ ] coordinator_type field specified
- [ ] summary_path is absolute path
- [ ] plan_file is absolute path
- [ ] work_remaining field present ("0" or list of items)
- [ ] context_exhausted field present (true/false)
- [ ] requires_continuation field present (true/false)

### Error Signal Checklist

- [ ] ERROR_CONTEXT is valid JSON
- [ ] error_type is one of standardized types
- [ ] message field is descriptive
- [ ] TASK_ERROR signal includes error_type prefix
- [ ] Coordinator exits with code 1 (not 0)

---

## Summary

Coordinator return signals provide structured communication between coordinators and orchestrators, enabling consistent parsing logic, error handling, and continuation decisions. All coordinators must include `coordinator_type`, `summary_path`, `plan_file`, `work_remaining`, `context_exhausted`, and `requires_continuation` fields in return signals.

**Key Benefits**:
- **Consistency**: Standard field names across all coordinator types
- **Parsability**: Simple grep/sed parsing for orchestrator commands
- **Error Handling**: Structured ERROR_CONTEXT + TASK_ERROR protocol
- **Continuation**: Clear signal for multi-iteration workflows
- **Debugging**: Comprehensive error details with recovery hints

---

## References

### Coordinator Implementations
- `.claude/agents/research-coordinator.md` - Planning-only mode
- `.claude/agents/implementer-coordinator.md` - Supervisor mode (brief summaries)
- `.claude/agents/testing-coordinator.md` - Test execution coordination
- `.claude/agents/debug-coordinator.md` - Investigation vector coordination
- `.claude/agents/repair-coordinator.md` - Error dimension analysis

### Related Standards
- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Five core patterns
- [Brief Summary Format](brief-summary-format.md) - 80-token summary specification
- [Error Logging Standard](error-logging-standard.md) - Centralized error tracking

### Command Examples
- `.claude/agents/research-coordinator.md` - research-coordinator signal parsing
- `.claude/commands/implement.md` - implementer-coordinator signal parsing
- `.claude/commands/test.md` - testing-coordinator signal parsing
