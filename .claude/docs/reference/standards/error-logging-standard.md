# Error Logging Standard

## Overview

This standard defines centralized error logging requirements for hierarchical agent architectures. Error logging enables queryable error tracking, cross-workflow debugging, and automated error pattern analysis through `/errors` and `/repair` commands.

**Purpose**: Provide centralized, structured error logging for all commands, coordinators, and specialists.

**Scope**: All bash commands, coordinator agents, and specialist agents that can encounter errors.

**Related Standards**:
- [Error Handling Pattern](../../concepts/patterns/error-handling.md) - Detailed error handling integration
- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Pattern 4: Error Return Protocol
- [Coordinator Return Signals](coordinator-return-signals.md) - Error signal format
- [State System Patterns](../../concepts/state-system-patterns.md) - Error recovery patterns

---

## Centralized Error Log Format

### Error Log File: errors.jsonl

**Location**: `$HOME/.claude/data/errors.jsonl`

**Format**: JSON Lines (one JSON object per line)

**Schema**:
```json
{
  "timestamp": "2025-12-10T14:23:45-08:00",
  "command": "/implement",
  "workflow_id": "implement_workflow_1733846400",
  "error_type": "state_error",
  "error_message": "Failed to restore WORKFLOW_ID",
  "error_details": "State file: /path/to/state.txt | Missing WORKFLOW_ID variable",
  "user_args": "/implement /path/to/plan.md",
  "context": "iteration=2 phase=4"
}
```

**Field Specifications**:

| Field | Type | Description | Example | Required |
|-------|------|-------------|---------|----------|
| timestamp | string | ISO 8601 timestamp with timezone | 2025-12-10T14:23:45-08:00 | Yes |
| command | string | Command name with leading slash | /implement | Yes |
| workflow_id | string | Unique workflow identifier | implement_workflow_1733846400 | Yes |
| error_type | string | Error classification (see types below) | state_error | Yes |
| error_message | string | Human-readable error summary | Failed to restore WORKFLOW_ID | Yes |
| error_details | string | Detailed error context (pipe-separated) | State file: /path/to/state.txt \| Missing WORKFLOW_ID variable | Yes |
| user_args | string | Command arguments as provided by user | /implement /path/to/plan.md | No |
| context | string | Additional context (key=value pairs) | iteration=2 phase=4 | No |

---

## Error Types

### Standard Error Types

| Error Type | Description | Use Cases | Example |
|-----------|-------------|-----------|---------|
| state_error | State persistence failures | WORKFLOW_ID restoration, state file corruption | Failed to restore WORKFLOW_ID from state file |
| validation_error | Input or artifact validation failures | Missing plan file, invalid metadata | Plan file not found: /path/to/plan.md |
| agent_error | Agent delegation failures | Coordinator timeout, specialist error | research-coordinator returned TASK_ERROR signal |
| parse_error | Output parsing failures | Signal parsing, metadata extraction | Failed to parse coordinator return signal |
| file_error | File system operations failures | File not found, permission denied | Cannot read research report: /path/to/report.md |
| timeout_error | Operation timeout | Agent timeout, bash timeout | Coordinator timeout after 30 minutes |
| execution_error | Command or script execution failures | Bash command failure, test failure | pytest failed with exit code 1 |
| dependency_error | Missing dependencies or requirements | Missing library, missing tool | Cannot find research-specialist.md agent file |

---

## Error Logging Integration

### Commands Integration

All commands MUST integrate error logging in Block 1:

```bash
#!/bin/bash

# Three-tier library sourcing
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library"
  exit 1
}

source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library"
  exit 1
}

# Initialize error log
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/implement"
WORKFLOW_ID=$(generate_unique_workflow_id "implement")
USER_ARGS="$*"

# Log errors with workflow context
log_error() {
  local error_type="$1"
  local error_message="$2"
  local error_details="$3"

  log_command_error "$error_type" "$error_message" "$error_details"
}

# Example error logging
if [ ! -f "$plan_path" ]; then
  log_error "validation_error" "Plan file not found" "Path: $plan_path"
  echo "Error: Plan file not found: $plan_path"
  exit 1
fi
```

**Requirements**:
- [ ] Source error-handling.sh library in Block 1
- [ ] Call ensure_error_log_exists before first error log
- [ ] Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS before first error log
- [ ] Log all errors with appropriate error_type
- [ ] Include detailed error_details (file paths, variable values, context)

---

### Coordinator Agents Integration

Coordinators MUST log errors and return ERROR_CONTEXT signal:

```bash
# In coordinator agent

# Source error handling library
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "TASK_ERROR: Cannot load error-handling library"
  return 1
}

ensure_error_log_exists

# Set coordinator metadata
COMMAND_NAME="research-coordinator"
WORKFLOW_ID="<from input contract>"

# Log specialist errors
if echo "$specialist_output" | grep -q "TASK_ERROR"; then
  error_message=$(echo "$specialist_output" | grep "TASK_ERROR:" | sed 's/TASK_ERROR: //')

  log_command_error \
    "agent_error" \
    "research-specialist failed" \
    "Topic: $topic | Error: $error_message"

  # Return error context
  echo "ERROR_CONTEXT: research-specialist failed for topic: $topic"
  echo "TASK_ERROR: $error_message"
  return 1
fi

# Log coordinator errors
if [ "$successful_count" -lt "$partial_success_threshold" ]; then
  log_command_error \
    "agent_error" \
    "Partial success threshold not met" \
    "Successful: $successful_count | Required: $partial_success_threshold | Topics: ${topics[*]}"

  echo "ERROR_CONTEXT: Partial success threshold not met (${successful_count}/${partial_success_threshold})"
  echo "TASK_ERROR: Too many specialist failures"
  return 1
fi
```

**Requirements**:
- [ ] Source error-handling.sh library at top of agent
- [ ] Log all specialist errors with agent_error type
- [ ] Log coordinator errors with appropriate error type
- [ ] Return ERROR_CONTEXT + TASK_ERROR signal on failure
- [ ] Include topic/phase/artifact context in error_details

See [Coordinator Patterns Standard - Pattern 4](coordinator-patterns-standard.md#pattern-4-error-return-protocol) for complete error return protocol.

---

### Specialist Agents Integration

Specialists MUST log errors and return TASK_ERROR signal:

```bash
# In specialist agent

# Source error handling library
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "TASK_ERROR: Cannot load error-handling library"
  return 1
}

ensure_error_log_exists

# Set specialist metadata
COMMAND_NAME="research-specialist"
WORKFLOW_ID="<from input contract or coordinator>"

# Log validation errors
if [ ! -d "$topic_path" ]; then
  log_command_error \
    "validation_error" \
    "Topic directory not found" \
    "Path: $topic_path"

  echo "TASK_ERROR: Topic directory not found: $topic_path"
  return 1
fi

# Log execution errors
if ! create_research_report; then
  log_command_error \
    "execution_error" \
    "Research report creation failed" \
    "Topic: $topic | Report path: $report_path"

  echo "TASK_ERROR: Failed to create research report for topic: $topic"
  return 1
fi
```

**Requirements**:
- [ ] Source error-handling.sh library at top of agent
- [ ] Log all errors with appropriate error type
- [ ] Return TASK_ERROR signal on failure
- [ ] Include artifact paths and topic context in error_details

---

## Error Logging Functions

### Function: log_command_error

**Signature**: `log_command_error <error_type> <error_message> <error_details>`

**Description**: Logs error to centralized errors.jsonl file with workflow context.

**Example**:
```bash
log_command_error \
  "state_error" \
  "Failed to restore WORKFLOW_ID" \
  "State file: $STATE_FILE | Missing WORKFLOW_ID variable"
```

**Implementation**:
```bash
log_command_error() {
  local error_type="$1"
  local error_message="$2"
  local error_details="$3"

  local timestamp=$(date -Iseconds)
  local error_log="${ERROR_LOG:-$HOME/.claude/data/errors.jsonl}"

  # Create error entry (JSON)
  local error_entry=$(cat <<EOF
{"timestamp": "$timestamp", "command": "$COMMAND_NAME", "workflow_id": "$WORKFLOW_ID", "error_type": "$error_type", "error_message": "$error_message", "error_details": "$error_details", "user_args": "$USER_ARGS", "context": ""}
EOF
)

  # Append to error log
  echo "$error_entry" >> "$error_log"
}
```

---

### Function: parse_subagent_error

**Signature**: `parse_subagent_error <agent_output> <agent_name>`

**Description**: Parses agent TASK_ERROR signal and logs to centralized error log.

**Example**:
```bash
if echo "$specialist_output" | grep -q "TASK_ERROR"; then
  parse_subagent_error "$specialist_output" "research-specialist"
fi
```

**Implementation**:
```bash
parse_subagent_error() {
  local agent_output="$1"
  local agent_name="$2"

  # Extract error message from TASK_ERROR signal
  local error_message=$(echo "$agent_output" | grep "TASK_ERROR:" | sed 's/TASK_ERROR: //')

  # Extract error context if present
  local error_context=$(echo "$agent_output" | grep "ERROR_CONTEXT:" | sed 's/ERROR_CONTEXT: //')

  # Log agent error
  log_command_error \
    "agent_error" \
    "$agent_name failed" \
    "Error: $error_message | Context: $error_context"
}
```

---

### Function: ensure_error_log_exists

**Signature**: `ensure_error_log_exists`

**Description**: Creates error log file if it doesn't exist.

**Example**:
```bash
ensure_error_log_exists
```

**Implementation**:
```bash
ensure_error_log_exists() {
  local error_log="${ERROR_LOG:-$HOME/.claude/data/errors.jsonl}"
  local error_dir=$(dirname "$error_log")

  # Create directory if needed
  if [ ! -d "$error_dir" ]; then
    mkdir -p "$error_dir"
  fi

  # Create file if needed
  if [ ! -f "$error_log" ]; then
    touch "$error_log"
  fi
}
```

---

## Error Consumption Workflows

### Workflow 1: Query Recent Errors

**Use Case**: View recent errors for debugging.

**Command**: `/errors [--command CMD] [--since TIME] [--type TYPE]`

**Example**:
```bash
# View all errors from last hour
/errors --since 1h

# View errors for specific command
/errors --command /implement --since 24h

# View errors of specific type
/errors --type state_error --limit 10

# View error summary
/errors --since 1h --summary
```

**Output**:
```
Recent Errors (Last 1 Hour)

1. [2025-12-10 14:23:45] /implement - state_error
   Message: Failed to restore WORKFLOW_ID
   Details: State file: /path/to/state.txt | Missing WORKFLOW_ID variable
   Workflow: implement_workflow_1733846400

2. [2025-12-10 14:18:32] /create-plan - agent_error
   Message: research-coordinator failed
   Details: Error: research-specialist timeout | Context: Topic authentication
   Workflow: create_plan_workflow_1733845112

Total errors: 2
```

See [Errors Command Guide](../../guides/commands/errors-command-guide.md) for complete command usage.

---

### Workflow 2: Analyze Error Patterns

**Use Case**: Group errors by pattern and create fix plan.

**Command**: `/repair [--since TIME] [--type TYPE] [--command CMD]`

**Example**:
```bash
# Analyze errors from last 24 hours
/repair --since 24h --complexity 2

# Analyze specific error type
/repair --type state_error --complexity 3

# Analyze errors for specific command
/repair --command /implement --complexity 2
```

**Output**: Creates repair plan in specs/ directory with error pattern analysis and fix phases.

**Repair Plan Structure**:
```markdown
# Repair Plan: State Error Pattern Fix

## Error Pattern Analysis

**Pattern**: Failed to restore WORKFLOW_ID (8 occurrences)
**Affected Commands**: /implement, /create-plan, /lean-plan
**Root Cause**: Shared state ID file anti-pattern

## Fix Phases

### Phase 1: Replace Shared State Files with State Discovery Pattern
[Implementation details...]
```

See [Repair Command Guide](../../guides/commands/repair-command-guide.md) for complete command usage.

---

### Workflow 3: Debug Workflow Failures

**Use Case**: Investigate specific workflow failure using error log.

**Process**:
1. Identify workflow_id from command output
2. Query errors for that workflow_id
3. Analyze error sequence and context
4. Fix root cause
5. Re-run workflow

**Example**:
```bash
# Step 1: Workflow fails
/implement /path/to/plan.md
# Output: Error: Failed to restore WORKFLOW_ID
# Workflow ID: implement_workflow_1733846400

# Step 2: Query errors for workflow
/errors --query "workflow_id=implement_workflow_1733846400"

# Step 3: Analyze error details
# Output shows: State file: /path/to/state.txt | Missing WORKFLOW_ID variable

# Step 4: Fix state file or re-initialize workflow
# Step 5: Re-run /implement with correct state
```

---

## Error Signal Format (Agent Integration)

### TASK_ERROR Signal

**Format**:
```
TASK_ERROR: <error_message>
```

**Requirements**:
- MUST be emitted by agents on failure
- MUST include human-readable error message
- SHOULD include specific context (file paths, variable values)

**Example**:
```
TASK_ERROR: Failed to create research report for topic: authentication
```

---

### ERROR_CONTEXT Signal

**Format**:
```
ERROR_CONTEXT: <context_description>
```

**Requirements**:
- MUST precede TASK_ERROR signal
- MUST include high-level context (topic, phase, iteration)
- SHOULD include recovery hints if applicable

**Example**:
```
ERROR_CONTEXT: research-specialist failed for topic: authentication (timeout after 30 minutes)
TASK_ERROR: Specialist timeout - consider reducing research scope
```

---

## Debugging Workflows

### Debugging Pattern 1: Trace Error Through Hierarchy

**Use Case**: Error in specialist propagates through coordinator to command.

**Trace Flow**:
```
Command (/implement)
  ↓ delegates to
Coordinator (implementer-coordinator)
  ↓ delegates to
Specialist (plan-architect)
  ↓ encounters error
  ↓ logs error + returns TASK_ERROR
Coordinator (detects TASK_ERROR)
  ↓ logs agent_error + returns ERROR_CONTEXT + TASK_ERROR
Command (detects TASK_ERROR)
  ↓ logs agent_error + exits with error
```

**Error Log Entries**:
```json
// Specialist error
{"timestamp": "...", "command": "plan-architect", "error_type": "file_error", "error_message": "Cannot read template file", ...}

// Coordinator error (logs specialist failure)
{"timestamp": "...", "command": "implementer-coordinator", "error_type": "agent_error", "error_message": "plan-architect failed", ...}

// Command error (logs coordinator failure)
{"timestamp": "...", "command": "/implement", "error_type": "agent_error", "error_message": "implementer-coordinator failed", ...}
```

**Query Command**:
```bash
# View all errors for workflow
/errors --query "workflow_id=implement_workflow_1733846400"

# Shows complete error trace from specialist → coordinator → command
```

---

### Debugging Pattern 2: Identify Recurring Error Patterns

**Use Case**: Same error occurring across multiple workflows.

**Query Commands**:
```bash
# Find all state_error occurrences
/errors --type state_error --limit 50

# Group by error message
/errors --type state_error --summary

# Analyze pattern with /repair
/repair --type state_error --complexity 3
```

**Example Output** (from `/errors --summary`):
```
Error Summary (state_error)

Pattern 1: Failed to restore WORKFLOW_ID (8 occurrences)
  Commands: /implement, /create-plan, /lean-plan
  Root Cause: Shared state ID file anti-pattern
  Fix: Replace with state discovery pattern

Pattern 2: State file corruption (3 occurrences)
  Commands: /lean-implement
  Root Cause: Concurrent writes to same state file
  Fix: Use unique workflow IDs per instance
```

---

### Debugging Pattern 3: Context-Based Error Analysis

**Use Case**: Errors occurring at specific iteration or phase.

**Query with Context Filter**:
```bash
# Find errors at iteration 2
/errors --query "context=iteration=2"

# Find errors at phase 4
/errors --query "context=phase=4"

# Combine filters
/errors --command /implement --query "context=iteration=2" --since 24h
```

**Error Context Format**:
```json
{
  "context": "iteration=2 phase=4 wave=1"
}
```

**Parsing Context**:
```bash
# Extract iteration from context
iteration=$(echo "$error_entry" | jq -r '.context' | grep -oP 'iteration=\K\d+')

# Extract phase from context
phase=$(echo "$error_entry" | jq -r '.context' | grep -oP 'phase=\K\d+')
```

---

## Anti-Patterns

### Anti-Pattern 1: Silently Swallowing Errors

**Problem**: Errors not logged, debugging impossible.

```bash
# WRONG: Error not logged
if [ ! -f "$plan_path" ]; then
  echo "Error: Plan file not found"
  exit 1
fi
```

**Solution**: Always log errors before exit.

```bash
# CORRECT: Error logged before exit
if [ ! -f "$plan_path" ]; then
  log_command_error "validation_error" "Plan file not found" "Path: $plan_path"
  echo "Error: Plan file not found: $plan_path"
  exit 1
fi
```

---

### Anti-Pattern 2: Generic Error Messages

**Problem**: Error message lacks context, hard to debug.

```bash
# WRONG: Generic error message
log_command_error "agent_error" "Agent failed" ""
```

**Solution**: Include specific context in error message and details.

```bash
# CORRECT: Specific error message with context
log_command_error \
  "agent_error" \
  "research-specialist failed for topic: authentication" \
  "Error: timeout after 30 minutes | Report path: $report_path"
```

---

### Anti-Pattern 3: Missing Error Propagation

**Problem**: Agent error not propagated to coordinator/command.

```bash
# WRONG: Agent error not propagated
if echo "$specialist_output" | grep -q "TASK_ERROR"; then
  echo "Specialist failed, continuing anyway..."
fi
```

**Solution**: Log and propagate all agent errors.

```bash
# CORRECT: Agent error logged and propagated
if echo "$specialist_output" | grep -q "TASK_ERROR"; then
  parse_subagent_error "$specialist_output" "research-specialist"

  echo "ERROR_CONTEXT: research-specialist failed for topic: $topic"
  echo "TASK_ERROR: Specialist error (see error log for details)"
  return 1
fi
```

---

### Anti-Pattern 4: Logging to Stdout Instead of Error Log

**Problem**: Errors only visible in command output, not queryable.

```bash
# WRONG: Error only in stdout
echo "Error: Failed to restore WORKFLOW_ID" >&2
exit 1
```

**Solution**: Log to centralized error log AND stdout.

```bash
# CORRECT: Log to error log and stdout
log_command_error "state_error" "Failed to restore WORKFLOW_ID" "State file: $STATE_FILE"
echo "Error: Failed to restore WORKFLOW_ID" >&2
exit 1
```

---

## Performance Considerations

### Error Log Size Management

**Typical Growth Rate**: ~100-200 errors/day (active development)

**File Size**: ~500 bytes/error × 200 errors = ~100 KB/day

**Recommendations**:
- Rotate error log monthly (errors-YYYY-MM.jsonl)
- Archive old error logs after 6 months
- Clean up error logs older than 1 year

**Rotation Script**:
```bash
#!/bin/bash
# Rotate error log monthly

current_month=$(date +%Y-%m)
error_log="$HOME/.claude/data/errors.jsonl"
archive_log="$HOME/.claude/data/archive/errors-${current_month}.jsonl"

if [ -f "$error_log" ]; then
  mv "$error_log" "$archive_log"
  touch "$error_log"
fi
```

---

### Error Query Performance

**Query Time**: <100ms for 10,000 error entries

**Optimization**:
```bash
# Fast: Use grep with --line-buffered for streaming
grep --line-buffered '"error_type": "state_error"' errors.jsonl

# Fast: Use jq with streaming parser
jq -c 'select(.error_type == "state_error")' errors.jsonl

# Slow: Load entire file into memory
cat errors.jsonl | jq 'select(.error_type == "state_error")'
```

**Recommendation**: Use streaming parsers (grep, jq -c) for large error logs.

---

## Standards Compliance Checklist

### Commands Compliance

- [ ] Source error-handling.sh library in Block 1
- [ ] Call ensure_error_log_exists before first error log
- [ ] Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS before logging
- [ ] Log all errors with appropriate error_type
- [ ] Include detailed error_details (file paths, context)
- [ ] Parse subagent errors with parse_subagent_error
- [ ] Propagate agent errors to user (exit with error)

### Coordinator Agents Compliance

- [ ] Source error-handling.sh library at top of agent
- [ ] Log all specialist errors with agent_error type
- [ ] Log coordinator errors with appropriate error type
- [ ] Return ERROR_CONTEXT + TASK_ERROR on failure
- [ ] Include topic/phase context in error_details
- [ ] Set WORKFLOW_ID from input contract
- [ ] Set COMMAND_NAME to coordinator agent name

### Specialist Agents Compliance

- [ ] Source error-handling.sh library at top of agent
- [ ] Log all errors with appropriate error type
- [ ] Return TASK_ERROR signal on failure
- [ ] Include artifact paths in error_details
- [ ] Include topic context in error_message
- [ ] Set WORKFLOW_ID from input contract or coordinator
- [ ] Set COMMAND_NAME to specialist agent name

---

## Related Documentation

- [Error Handling Pattern](../../concepts/patterns/error-handling.md) - Detailed error handling integration guide
- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Pattern 4: Error Return Protocol
- [Coordinator Return Signals](coordinator-return-signals.md) - Error signal format specifications
- [State System Patterns](../../concepts/state-system-patterns.md) - Error recovery patterns
- [Errors Command Guide](../../guides/commands/errors-command-guide.md) - Error query command usage
- [Repair Command Guide](../../guides/commands/repair-command-guide.md) - Error pattern analysis and fix workflow

---

## Revision History

- **2025-12-10**: Initial standard created (Phase 5 of hierarchical agent architecture documentation)
- Defines centralized error logging format (errors.jsonl)
- Specifies error types and integration requirements
- Documents error consumption workflows (/errors, /repair)
- Integrates with coordinator error return protocol
- Documents debugging workflows and anti-patterns
