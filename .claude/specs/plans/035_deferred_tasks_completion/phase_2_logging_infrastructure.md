# Phase 2: Adaptive Planning Logging Infrastructure

## Phase Metadata
- **Phase Number**: 2
- **Parent Plan**: 035_deferred_tasks_completion.md
- **Objective**: Activate comprehensive logging for adaptive planning detection and operations
- **Complexity**: High (7/10)
- **Estimated Time**: 3-4 hours
- **Status**: PENDING

## Overview

This phase implements comprehensive logging infrastructure for adaptive planning by integrating the existing adaptive-planning-logger.sh library into the /implement command workflow. The logging system provides structured, queryable records of all adaptive planning decisions including trigger evaluations, replan invocations, and loop prevention enforcement.

### Goals
1. Enable observability into adaptive planning behavior
2. Provide audit trail for automatic replanning decisions
3. Support debugging of complex adaptive planning scenarios
4. Establish foundation for future adaptive planning analytics

### Non-Goals
- Logging for commands other than /implement (future work)
- Performance metrics collection (separate concern)
- Log aggregation or centralized logging (not needed for local CLI tool)

---

## Architecture Overview

### Logging Infrastructure Design

The adaptive planning logging system consists of three layers:

**Layer 1: Logger Library (adaptive-planning-logger.sh)**
- Provides structured logging API with 10 functions
- Handles log rotation (10MB max, 5 files retained)
- Formats entries with ISO8601 timestamps and JSON data
- Location: .claude/lib/adaptive-planning-logger.sh (297 lines, already implemented)

**Layer 2: Integration Points (/implement command)**
- Command sources logger library at initialization
- Invokes logging functions at 5 critical workflow points
- Passes context-specific data (complexity scores, replan counts, etc.)
- Location: .claude/commands/implement.md (1554 lines, needs modification)

**Layer 3: Query Utilities**
- Functions for reading and analyzing log data
- Statistical summaries of adaptive planning activity
- Filtered queries by event type
- Already implemented in logger library, needs documentation

### Integration Points in /implement Workflow

The /implement command has 5 distinct points where adaptive planning decisions occur. Each requires specific logging calls:

**Point 1: Complexity Check (Step 3.4)**
- Location: After phase implementation, during complexity evaluation
- Trigger: `calculate_phase_complexity()` returns score
- Log Function: `log_complexity_check()`
- Data: phase_number, complexity_score, threshold (8), task_count

**Point 2: Test Failure Pattern Detection (Step 3.4)**
- Location: After test execution, when tracking consecutive failures
- Trigger: Test fails for 2nd consecutive time in same phase
- Log Function: `log_test_failure_pattern()`
- Data: phase_number, consecutive_failures, failure_log excerpt

**Point 3: Scope Drift Detection (Step 3.4)**
- Location: When --report-scope-drift flag processed
- Trigger: Manual flag or "out of scope" task annotation detected
- Log Function: `log_scope_drift()`
- Data: phase_number, drift_description from flag or task

**Point 4: Replan Invocation (Step 3.4)**
- Location: Before invoking /revise --auto-mode
- Trigger: Any trigger detected and replan limit not exceeded
- Log Function: `log_replan_invocation()`
- Data: revision_type, status (success/failure), result (plan path or error), context JSON

**Point 5: Loop Prevention (Step 3.4)**
- Location: Before trigger detection, when checking replan count
- Trigger: Every phase entry (log allowed/blocked decision)
- Log Function: `log_loop_prevention()`
- Data: phase_number, replan_count, action (allowed/blocked)

### Log Event Types and Purposes

**trigger_eval Events**
- Purpose: Record each trigger evaluation (complexity, test_failure, scope_drift)
- Result: "triggered" or "not_triggered"
- Used for: Understanding which triggers activate most frequently

**replan Events**
- Purpose: Record each /revise --auto-mode invocation
- Status: "success" or "failure"
- Used for: Tracking replanning effectiveness and failure rates

**loop_prevention Events**
- Purpose: Record replan count checks and blocking decisions
- Action: "allowed" or "blocked"
- Used for: Monitoring loop prevention enforcement

### Log Format and Structure

All log entries follow this structured format:

```
[timestamp] LEVEL event_type: message | data=JSON
```

**Components:**
- `timestamp`: ISO8601 UTC format (2025-10-09T14:23:45Z)
- `LEVEL`: INFO, WARN, or ERROR
- `event_type`: trigger_eval, replan, loop_prevention
- `message`: Human-readable description
- `data`: JSON object with structured context

**Example Entries:**

```
[2025-10-09T14:23:45Z] INFO trigger_eval: Trigger evaluation: complexity -> triggered | data={"phase": 3, "score": 9.2, "threshold": 8, "tasks": 12}

[2025-10-09T14:23:46Z] INFO replan: Replanning invoked: expand_phase -> success | data={"revision_type": "expand_phase", "result": "specs/plans/025_plan/phase_3_refactor.md", "context": {"reason": "Phase complexity score 9.2 exceeds threshold 8"}}

[2025-10-09T14:24:12Z] WARN loop_prevention: Loop prevention: phase 3 replan count 2 -> blocked | data={"phase": 3, "replan_count": 2, "max_allowed": 2}
```

### Performance Considerations

**Log Write Performance:**
- Each log write is a single append operation (O(1))
- No synchronous I/O blocking (file writes buffered by OS)
- Rotation check on every write (stat syscall, ~0.1ms)
- Expected overhead per log call: <1ms

**Disk Space Management:**
- Maximum disk usage: 50MB (10MB × 5 files)
- Rotation triggers automatically at 10MB
- Oldest file deleted when exceeding 5 file limit
- Typical log size: ~500 bytes per entry

**Impact on /implement:**
- 5-10 log calls per phase execution
- Total logging overhead per phase: <10ms (negligible)
- No user-visible latency impact

---

## Implementation Details

### Task 2.1: Understand Logging API

**Objective:** Comprehensively understand the adaptive-planning-logger.sh API to enable correct integration.

**Step 1.1: Read Complete Logger Library**

File: .claude/lib/adaptive-planning-logger.sh (297 lines)

Read entire file to understand:
- Configuration constants (lines 13-16)
- Log rotation mechanism (lines 24-48)
- Core logging functions (lines 58-220)
- Query utilities (lines 228-284)

**Step 1.2: Document Available Logging Functions**

The logger provides 10 public functions:

**1. `log_trigger_evaluation(trigger_type, result, metrics)`**
- Purpose: Log generic trigger evaluation with custom metrics
- Parameters:
  - `trigger_type`: "complexity" | "test_failure" | "scope_drift"
  - `result`: "triggered" | "not_triggered"
  - `metrics`: JSON string with trigger-specific data
- Example:
  ```bash
  log_trigger_evaluation "complexity" "triggered" '{"phase": 3, "score": 9.2}'
  ```

**2. `log_complexity_check(phase_number, complexity_score, threshold, task_count)`**
- Purpose: Log complexity score evaluation with automatic trigger detection
- Parameters:
  - `phase_number`: Integer phase number
  - `complexity_score`: Float complexity score (0-10+)
  - `threshold`: Integer threshold for triggering (typically 8)
  - `task_count`: Integer number of tasks in phase
- Automatically determines "triggered" vs "not_triggered" based on score > threshold OR task_count > 10
- Example:
  ```bash
  log_complexity_check "3" "9.2" "8" "12"
  ```

**3. `log_test_failure_pattern(phase_number, consecutive_failures, failure_log)`**
- Purpose: Log test failure pattern detection
- Parameters:
  - `phase_number`: Integer phase number
  - `consecutive_failures`: Integer count of consecutive failures
  - `failure_log`: String excerpt from test failure output (escaped)
- Automatically determines "triggered" if consecutive_failures >= 2
- Example:
  ```bash
  log_test_failure_pattern "2" "2" "Error: Module not found: crypto-utils"
  ```

**4. `log_scope_drift(phase_number, drift_description)`**
- Purpose: Log scope drift detection (always triggered)
- Parameters:
  - `phase_number`: Integer phase number
  - `drift_description`: String describing the out-of-scope work discovered
- Always logs with result="triggered" (scope drift is binary)
- Example:
  ```bash
  log_scope_drift "3" "Database migration required before schema changes"
  ```

**5. `log_replan_invocation(revision_type, status, result, context)`**
- Purpose: Log /revise --auto-mode invocation and outcome
- Parameters:
  - `revision_type`: "expand_phase" | "add_phase" | "split_phase" | "update_tasks"
  - `status`: "success" | "failure"
  - `result`: Plan path on success, error message on failure
  - `context`: Optional JSON string with additional context
- Uses INFO level for success, ERROR level for failure
- Example:
  ```bash
  log_replan_invocation "expand_phase" "success" \
    "specs/plans/025_plan/phase_3_refactor.md" \
    '{"reason": "Complexity threshold exceeded"}'
  ```

**6. `log_loop_prevention(phase_number, replan_count, action)`**
- Purpose: Log loop prevention check and decision
- Parameters:
  - `phase_number`: Integer phase number
  - `replan_count`: Integer current replan count for phase
  - `action`: "allowed" | "blocked"
- Uses INFO level for allowed, WARN level for blocked
- Example:
  ```bash
  log_loop_prevention "3" "2" "blocked"
  ```

**7. `query_adaptive_log(event_type, limit)`**
- Purpose: Query log for recent events, optionally filtered by type
- Parameters:
  - `event_type`: Optional filter ("trigger_eval", "replan", "loop_prevention")
  - `limit`: Number of entries to return (default 10)
- Returns: Filtered log entries (most recent first)
- Example:
  ```bash
  query_adaptive_log "replan" 5
  ```

**8. `get_adaptive_stats()`**
- Purpose: Generate statistical summary of adaptive planning activity
- Parameters: None
- Returns: Multi-line formatted report with counts by trigger type
- Example output:
  ```
  Adaptive Planning Statistics
  ============================
  Total Trigger Evaluations: 45
    - Complexity Triggers: 12
    - Test Failure Triggers: 3
    - Scope Drift Triggers: 2

  Total Replans: 15
    - Successful: 14
    - Failed: 1

  Log File: .claude/logs/adaptive-planning.log
  Log Size: 2.3M
  ```

**9. `rotate_log_if_needed()`**
- Purpose: Check log size and rotate if exceeding 10MB
- Parameters: None
- Called automatically by `write_log_entry()`, rarely called directly
- Rotation logic:
  - .log → .log.1
  - .log.1 → .log.2
  - .log.2 → .log.3
  - .log.3 → .log.4
  - .log.4 → .log.5
  - .log.5 → deleted

**10. `write_log_entry(log_level, event_type, message, data)`**
- Purpose: Core logging function (called by other functions)
- Parameters:
  - `log_level`: "INFO" | "WARN" | "ERROR"
  - `event_type`: Event type identifier
  - `message`: Human-readable message
  - `data`: Optional JSON string
- Rarely called directly; use specialized functions instead

**Step 1.3: Understand Log Rotation Mechanism**

The rotation mechanism (lines 24-48) ensures bounded disk usage:

**Trigger Condition:**
- Log file size >= 10MB (10,485,760 bytes)

**Rotation Process:**
1. Check current file size using `stat` command
2. If size >= threshold:
   - Iterate backwards from .log.4 to .log.1
   - Rename each file to next number (.log.1 → .log.2)
   - Rename current .log to .log.1
   - Remove .log.6 if it exists (should not happen)

**Platform Compatibility:**
- Uses `stat -f%z` on macOS/BSD
- Falls back to `stat -c%s` on Linux
- Returns 0 if stat fails (creates new log)

**Concurrency:**
- No file locking (assumes single /implement process per project)
- Rotation is atomic (mv operations)
- Safe for concurrent reads during rotation

**Step 1.4: Identify Query Utilities**

Two query utilities available:

**`query_adaptive_log()`** - Flexible event filtering
- Use case: "Show me the last 5 replan events"
- Implementation: Uses `tail -n 100` then `grep` for event type
- Limitation: Only searches last 100 entries
- Performance: Fast (<10ms for typical log size)

**`get_adaptive_stats()`** - Statistical summary
- Use case: "How many complexity triggers in total?"
- Implementation: Uses `grep -c` for pattern counting
- Coverage: Scans entire log file
- Performance: Acceptable (<100ms for 10MB log)

**Step 1.5: Verify Logger Configuration**

Configuration constants (lines 13-16):

```bash
readonly AP_LOG_FILE="${CLAUDE_LOGS_DIR:-.claude/logs}/adaptive-planning.log"
readonly AP_LOG_MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
readonly AP_LOG_MAX_FILES=5
```

**Key points:**
- `CLAUDE_LOGS_DIR` environment variable optional (defaults to .claude/logs)
- Log file name is hardcoded: adaptive-planning.log
- Max size and file count are constants (not configurable)

**Task 2.1 Deliverables:**
- [x] Complete understanding of all 10 logging functions
- [x] Documentation of function signatures and usage
- [x] Understanding of log rotation behavior
- [x] Knowledge of query utilities and limitations

---

### Task 2.2: Map /implement Workflow

**Objective:** Identify exact locations in /implement command where each logging call should be added.

**Step 2.1: Read Implement Command Structure**

File: .claude/commands/implement.md (1554 lines, command documentation)

**Note:** The implement command is documented in markdown format (command definition). The actual implementation logic is embedded in Claude's behavior when following this command. Integration points are described procedurally.

Key sections for logging integration:
- Lines 614-752: Step 3.4 "Adaptive Planning Detection"
- This section describes the complete trigger detection and replanning flow

**Step 2.2: Identify Complexity Check Logging Location**

**Context:** Step 3.4, Trigger 1 (lines 634-647)

**Workflow Description:**
```markdown
**Trigger 1: Complexity Threshold Exceeded**

Detection after successful phase completion:
```bash
# Calculate phase complexity score
COMPLEXITY_RESULT=$(.claude/lib/analyze-phase-complexity.sh "$PHASE_NAME" "$TASK_LIST")
COMPLEXITY_SCORE=$(echo "$COMPLEXITY_RESULT" | jq -r '.complexity_score')

# Check threshold
if [ "$COMPLEXITY_SCORE" -gt 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
  TRIGGER_TYPE="expand_phase"
  TRIGGER_REASON="Phase complexity score $COMPLEXITY_SCORE exceeds threshold 8 ($TASK_COUNT tasks)"
fi
```
```

**Integration Point:**

After complexity calculation, before trigger decision:

```bash
# Calculate phase complexity score
COMPLEXITY_RESULT=$(.claude/lib/analyze-phase-complexity.sh "$PHASE_NAME" "$TASK_LIST")
COMPLEXITY_SCORE=$(echo "$COMPLEXITY_RESULT" | jq -r '.complexity_score')

# LOG: Complexity check
log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "8" "$TASK_COUNT"

# Check threshold
if [ "$COMPLEXITY_SCORE" -gt 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
  TRIGGER_TYPE="expand_phase"
  TRIGGER_REASON="Phase complexity score $COMPLEXITY_SCORE exceeds threshold 8 ($TASK_COUNT tasks)"
fi
```

**Variables Available at This Point:**
- `$CURRENT_PHASE`: Integer phase number being evaluated
- `$COMPLEXITY_SCORE`: Float score from analyzer (0-10+)
- `$TASK_COUNT`: Integer count of tasks in phase
- `$PHASE_NAME`: String name of phase (for context, not logged)

**Step 2.3: Identify Test Failure Pattern Logging Location**

**Context:** Step 3.4, Trigger 2 (lines 649-664)

**Workflow Description:**
```markdown
**Trigger 2: Test Failure Pattern**

Detection after test failures (2+ consecutive failures in same phase):
```bash
# Track failure count in checkpoint
if [ "$TEST_RESULT" = "failed" ]; then
  PHASE_FAILURE_COUNT=$((PHASE_FAILURE_COUNT + 1))

  if [ "$PHASE_FAILURE_COUNT" -ge 2 ]; then
    TRIGGER_TYPE="add_phase"
    TRIGGER_REASON="Two consecutive test failures in phase $CURRENT_PHASE"
    # Analyze failure logs for missing dependencies
    FAILURE_ANALYSIS=$(.claude/lib/analyze-error.sh "$ERROR_OUTPUT")
  fi
fi
```
```

**Integration Point:**

After incrementing failure count, log regardless of threshold:

```bash
# Track failure count in checkpoint
if [ "$TEST_RESULT" = "failed" ]; then
  PHASE_FAILURE_COUNT=$((PHASE_FAILURE_COUNT + 1))

  # Extract failure log excerpt (first 200 chars)
  FAILURE_EXCERPT=$(echo "$ERROR_OUTPUT" | head -c 200 | tr '\n' ' ')

  # LOG: Test failure pattern
  log_test_failure_pattern "$CURRENT_PHASE" "$PHASE_FAILURE_COUNT" "$FAILURE_EXCERPT"

  if [ "$PHASE_FAILURE_COUNT" -ge 2 ]; then
    TRIGGER_TYPE="add_phase"
    TRIGGER_REASON="Two consecutive test failures in phase $CURRENT_PHASE"
    # Analyze failure logs for missing dependencies
    FAILURE_ANALYSIS=$(.claude/lib/analyze-error.sh "$ERROR_OUTPUT")
  fi
fi
```

**Variables Available at This Point:**
- `$CURRENT_PHASE`: Integer phase number
- `$PHASE_FAILURE_COUNT`: Integer consecutive failure count
- `$ERROR_OUTPUT`: String containing test failure output
- `$TEST_RESULT`: "passed" or "failed"

**Important:** Log even when count < 2 to show pattern building up.

**Step 2.4: Identify Scope Drift Logging Location**

**Context:** Step 3.4, Trigger 3 (lines 666-675)

**Workflow Description:**
```markdown
**Trigger 3: Scope Drift Detection**

Detection via manual flag or "out of scope" annotations:
```bash
# Manual trigger via flag
if [ "$REPORT_SCOPE_DRIFT" = "true" ]; then
  TRIGGER_TYPE="update_tasks"
  TRIGGER_REASON="$SCOPE_DRIFT_DESCRIPTION"
fi
```
```

**Integration Point:**

Immediately when scope drift flag detected:

```bash
# Manual trigger via flag
if [ "$REPORT_SCOPE_DRIFT" = "true" ]; then
  # LOG: Scope drift detection
  log_scope_drift "$CURRENT_PHASE" "$SCOPE_DRIFT_DESCRIPTION"

  TRIGGER_TYPE="update_tasks"
  TRIGGER_REASON="$SCOPE_DRIFT_DESCRIPTION"
fi
```

**Variables Available at This Point:**
- `$CURRENT_PHASE`: Integer phase number
- `$REPORT_SCOPE_DRIFT`: Boolean flag ("true" or "false")
- `$SCOPE_DRIFT_DESCRIPTION`: String from --report-scope-drift argument

**Alternative Detection (Future):**
Task annotations like `- [ ] [OUT OF SCOPE] Add OAuth provider` could also trigger this log call. For now, only manual flag supported.

**Step 2.5: Identify Replan Invocation Logging Location**

**Context:** Step 3.4, Step 3 (lines 679-752)

**Workflow Description:**
```bash
# Invoke /revise with auto-mode
REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")

# Check revision status
REVISION_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

if [ "$REVISION_STATUS" = "success" ]; then
  # Update checkpoint with replan metadata
  UPDATED_PLAN=$(echo "$REVISE_RESULT" | jq -r '.plan_file')
  ACTION_TAKEN=$(echo "$REVISE_RESULT" | jq -r '.action_taken')

  # ... checkpoint update logic ...
else
  # Revision failed, log error and ask user
  echo "Warning: Adaptive planning revision failed"
  echo "Error: $(echo "$REVISE_RESULT" | jq -r '.error_message')"
fi
```

**Integration Points (Two Locations):**

**Before /revise invocation:**
```bash
# Build revision context JSON
REVISION_CONTEXT=$(jq -n \
  --arg type "$TRIGGER_TYPE" \
  --argjson phase "$CURRENT_PHASE" \
  --arg reason "$TRIGGER_REASON" \
  '{
    revision_type: $type,
    current_phase: $phase,
    reason: $reason
  }')

# Invoke /revise with auto-mode
REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")
```

**After /revise completion (success case):**
```bash
if [ "$REVISION_STATUS" = "success" ]; then
  UPDATED_PLAN=$(echo "$REVISE_RESULT" | jq -r '.plan_file')
  ACTION_TAKEN=$(echo "$REVISE_RESULT" | jq -r '.action_taken')

  # LOG: Successful replan
  log_replan_invocation "$TRIGGER_TYPE" "success" "$UPDATED_PLAN" "$REVISION_CONTEXT"

  # ... checkpoint update logic ...
else
  ERROR_MESSAGE=$(echo "$REVISE_RESULT" | jq -r '.error_message')

  # LOG: Failed replan
  log_replan_invocation "$TRIGGER_TYPE" "failure" "$ERROR_MESSAGE" "$REVISION_CONTEXT"

  echo "Warning: Adaptive planning revision failed"
  echo "Error: $ERROR_MESSAGE"
fi
```

**Variables Available at This Point:**
- `$TRIGGER_TYPE`: "expand_phase" | "add_phase" | "split_phase" | "update_tasks"
- `$REVISION_STATUS`: "success" | "failure"
- `$UPDATED_PLAN`: Path to updated plan (success case)
- `$ERROR_MESSAGE`: Error description (failure case)
- `$REVISION_CONTEXT`: JSON context passed to /revise

**Step 2.6: Identify Loop Prevention Logging Location**

**Context:** Step 3.4, Step 1 (lines 617-628) and Step 5 (lines 754-776)

**Workflow Description (Step 1):**
```bash
# Load current checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement "$PROJECT_NAME")
REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r '.replanning_count // 0')
PHASE_REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r ".replan_phase_counts.phase_${CURRENT_PHASE} // 0")

# Replan Limit Check:
# - If PHASE_REPLAN_COUNT >= 2: Skip detection, log warning, escalate to user
# - Otherwise: Proceed with trigger detection
```

**Workflow Description (Step 5):**
```bash
if [ "$PHASE_REPLAN_COUNT" -ge 2 ]; then
  echo "=========================================="
  echo "Warning: Replanning Limit Reached"
  echo "=========================================="
  # ... detailed output ...

  # Skip further replanning for this phase
  SKIP_REPLAN=true
fi
```

**Integration Points:**

**After loading checkpoint (Step 1):**
```bash
# Load current checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement "$PROJECT_NAME")
REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r '.replanning_count // 0')
PHASE_REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r ".replan_phase_counts.phase_${CURRENT_PHASE} // 0")

# Determine action
if [ "$PHASE_REPLAN_COUNT" -ge 2 ]; then
  ACTION="blocked"
else
  ACTION="allowed"
fi

# LOG: Loop prevention check
log_loop_prevention "$CURRENT_PHASE" "$PHASE_REPLAN_COUNT" "$ACTION"

# Replan Limit Check
if [ "$PHASE_REPLAN_COUNT" -ge 2 ]; then
  # Skip detection, log warning, escalate to user
  SKIP_REPLAN=true
else
  # Proceed with trigger detection
  SKIP_REPLAN=false
fi
```

**Variables Available at This Point:**
- `$CURRENT_PHASE`: Integer phase number
- `$PHASE_REPLAN_COUNT`: Integer replan count for current phase
- `$ACTION`: "allowed" | "blocked"

**Task 2.2 Deliverables:**
- [x] Identified 5 integration points in /implement workflow
- [x] Documented exact workflow context for each log call
- [x] Specified variable names available at each point
- [x] Defined code snippets for each integration

---

### Task 2.3: Implement Logging Integration

**Objective:** Add logging calls to /implement command at identified integration points.

**Step 3.1: Source Logger Library at Command Initialization**

**Location:** Beginning of /implement command execution

Add sourcing statement:

```bash
# Source adaptive planning logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/adaptive-planning-logger.sh"
```

**Error Handling:**

```bash
if [ ! -f "$SCRIPT_DIR/../lib/adaptive-planning-logger.sh" ]; then
  echo "Warning: Adaptive planning logger not found. Logging disabled."
  # Define no-op functions so logging calls don't fail
  log_complexity_check() { :; }
  log_test_failure_pattern() { :; }
  log_scope_drift() { :; }
  log_replan_invocation() { :; }
  log_loop_prevention() { :; }
fi
```

**Step 3.2: Add Complexity Check Logging**

**Integration Code:**

```bash
# Calculate phase complexity score
COMPLEXITY_RESULT=$(.claude/lib/analyze-phase-complexity.sh "$PHASE_NAME" "$TASK_LIST")
COMPLEXITY_SCORE=$(echo "$COMPLEXITY_RESULT" | jq -r '.complexity_score')

# Extract task count from task list
TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")

# Log complexity check (always, even if not triggered)
log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "8" "$TASK_COUNT"

# Check threshold for triggering
if [ "$COMPLEXITY_SCORE" -gt 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
  TRIGGER_TYPE="expand_phase"
  TRIGGER_REASON="Phase complexity score $COMPLEXITY_SCORE exceeds threshold 8 ($TASK_COUNT tasks)"
fi
```

**JSON Data Structure:**

```json
{
  "phase": 3,
  "score": 9.2,
  "threshold": 8,
  "tasks": 12
}
```

**Error Handling:**

```bash
# Validate complexity score is numeric
if ! [[ "$COMPLEXITY_SCORE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Warning: Invalid complexity score: $COMPLEXITY_SCORE. Defaulting to 0."
  COMPLEXITY_SCORE="0"
fi

# Validate task count is numeric
if ! [[ "$TASK_COUNT" =~ ^[0-9]+$ ]]; then
  echo "Warning: Invalid task count: $TASK_COUNT. Defaulting to 0."
  TASK_COUNT="0"
fi

# Log even with invalid values (for debugging)
log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "8" "$TASK_COUNT"
```

**Step 3.3: Add Test Failure Pattern Logging**

**Integration Code:**

```bash
# Track failure count in checkpoint
if [ "$TEST_RESULT" = "failed" ]; then
  PHASE_FAILURE_COUNT=$((PHASE_FAILURE_COUNT + 1))

  # Extract failure log excerpt (first 200 chars, escape quotes)
  if [ -n "$ERROR_OUTPUT" ]; then
    FAILURE_EXCERPT=$(echo "$ERROR_OUTPUT" | head -c 200 | tr '\n' ' ' | sed 's/"/\\"/g')
  else
    FAILURE_EXCERPT="No error output captured"
  fi

  # Log test failure pattern
  log_test_failure_pattern "$CURRENT_PHASE" "$PHASE_FAILURE_COUNT" "$FAILURE_EXCERPT"

  # Check if threshold reached
  if [ "$PHASE_FAILURE_COUNT" -ge 2 ]; then
    TRIGGER_TYPE="add_phase"
    TRIGGER_REASON="Two consecutive test failures in phase $CURRENT_PHASE"
    # Analyze failure logs for missing dependencies
    FAILURE_ANALYSIS=$(.claude/lib/analyze-error.sh "$ERROR_OUTPUT")
  fi
fi
```

**JSON Data Structure:**

```json
{
  "phase": 2,
  "consecutive_failures": 2,
  "log": "Error: Module not found: crypto-utils at line 42 in auth.js"
}
```

**Error Handling:**

```bash
# Validate failure count is numeric
if ! [[ "$PHASE_FAILURE_COUNT" =~ ^[0-9]+$ ]]; then
  echo "Warning: Invalid failure count. Resetting to 0."
  PHASE_FAILURE_COUNT="0"
fi

# Handle missing error output
if [ -z "$ERROR_OUTPUT" ]; then
  FAILURE_EXCERPT="Error output not available"
fi

# Log even with empty/invalid data
log_test_failure_pattern "$CURRENT_PHASE" "$PHASE_FAILURE_COUNT" "$FAILURE_EXCERPT"
```

**Step 3.4: Add Scope Drift Logging**

**Integration Code:**

```bash
# Manual trigger via flag
if [ "$REPORT_SCOPE_DRIFT" = "true" ]; then
  # Validate scope drift description provided
  if [ -z "$SCOPE_DRIFT_DESCRIPTION" ]; then
    echo "Error: --report-scope-drift requires description argument"
    exit 1
  fi

  # Escape quotes in description
  ESCAPED_DESCRIPTION=$(echo "$SCOPE_DRIFT_DESCRIPTION" | sed 's/"/\\"/g')

  # Log scope drift detection
  log_scope_drift "$CURRENT_PHASE" "$ESCAPED_DESCRIPTION"

  TRIGGER_TYPE="update_tasks"
  TRIGGER_REASON="$SCOPE_DRIFT_DESCRIPTION"
fi
```

**JSON Data Structure:**

```json
{
  "phase": 3,
  "description": "Database migration required before schema changes"
}
```

**Error Handling:**

```bash
# Validate description not empty
if [ -z "$SCOPE_DRIFT_DESCRIPTION" ]; then
  echo "Error: Scope drift description cannot be empty"
  # Don't trigger replanning without valid description
  REPORT_SCOPE_DRIFT="false"
else
  log_scope_drift "$CURRENT_PHASE" "$SCOPE_DRIFT_DESCRIPTION"
fi
```

**Step 3.5: Add Replan Invocation Logging**

**Integration Code (Success Case):**

```bash
if [ "$REVISION_STATUS" = "success" ]; then
  UPDATED_PLAN=$(echo "$REVISE_RESULT" | jq -r '.plan_file')
  ACTION_TAKEN=$(echo "$REVISE_RESULT" | jq -r '.action_taken')

  # Build context JSON for logging
  REPLAN_CONTEXT=$(jq -n \
    --arg reason "$TRIGGER_REASON" \
    --argjson phase "$CURRENT_PHASE" \
    '{
      reason: $reason,
      phase: $phase,
      trigger_metrics: {}
    }')

  # Log successful replan
  log_replan_invocation "$TRIGGER_TYPE" "success" "$UPDATED_PLAN" "$REPLAN_CONTEXT"

  # Increment replan counters
  REPLAN_COUNT=$((REPLAN_COUNT + 1))
  PHASE_REPLAN_COUNT=$((PHASE_REPLAN_COUNT + 1))

  # ... rest of checkpoint update logic ...
fi
```

**Integration Code (Failure Case):**

```bash
else
  ERROR_MESSAGE=$(echo "$REVISE_RESULT" | jq -r '.error_message // "Unknown error"')

  # Build context JSON for logging
  REPLAN_CONTEXT=$(jq -n \
    --arg reason "$TRIGGER_REASON" \
    --argjson phase "$CURRENT_PHASE" \
    --arg error "$ERROR_MESSAGE" \
    '{
      reason: $reason,
      phase: $phase,
      error_details: $error
    }')

  # Log failed replan
  log_replan_invocation "$TRIGGER_TYPE" "failure" "$ERROR_MESSAGE" "$REPLAN_CONTEXT"

  echo "Warning: Adaptive planning revision failed"
  echo "Error: $ERROR_MESSAGE"
  echo "Continuing with original plan"
fi
```

**JSON Data Structure (Success):**

```json
{
  "revision_type": "expand_phase",
  "result": "specs/plans/025_plan/phase_3_refactor.md",
  "context": {
    "reason": "Phase complexity score 9.2 exceeds threshold 8",
    "phase": 3,
    "trigger_metrics": {}
  }
}
```

**JSON Data Structure (Failure):**

```json
{
  "revision_type": "expand_phase",
  "result": "Failed to parse plan structure",
  "context": {
    "reason": "Phase complexity score 9.2 exceeds threshold 8",
    "phase": 3,
    "error_details": "Failed to parse plan structure"
  }
}
```

**Error Handling:**

```bash
# Validate revision status
if [ "$REVISION_STATUS" != "success" ] && [ "$REVISION_STATUS" != "failure" ]; then
  echo "Warning: Invalid revision status: $REVISION_STATUS. Treating as failure."
  REVISION_STATUS="failure"
  ERROR_MESSAGE="Invalid revision response format"
fi

# Always log replan invocation (even if status unclear)
log_replan_invocation "$TRIGGER_TYPE" "$REVISION_STATUS" \
  "${UPDATED_PLAN:-$ERROR_MESSAGE}" "$REPLAN_CONTEXT"
```

**Step 3.6: Add Loop Prevention Logging**

**Integration Code:**

```bash
# Load current checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement "$PROJECT_NAME")
REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r '.replanning_count // 0')
PHASE_REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r ".replan_phase_counts.phase_${CURRENT_PHASE} // 0")

# Determine action based on count
if [ "$PHASE_REPLAN_COUNT" -ge 2 ]; then
  ACTION="blocked"
  SKIP_REPLAN=true
else
  ACTION="allowed"
  SKIP_REPLAN=false
fi

# Log loop prevention check
log_loop_prevention "$CURRENT_PHASE" "$PHASE_REPLAN_COUNT" "$ACTION"

# Display warning if blocked
if [ "$ACTION" = "blocked" ]; then
  echo "=========================================="
  echo "Warning: Replanning Limit Reached"
  echo "=========================================="
  echo "Phase: $CURRENT_PHASE"
  echo "Replans: $PHASE_REPLAN_COUNT (max 2)"
  echo ""
  echo "Replan History for Phase $CURRENT_PHASE:"
  echo "$CHECKPOINT" | jq -r ".replan_history[] | select(.phase == $CURRENT_PHASE) | \
    \"  - [\(.timestamp)] \(.type): \(.reason)\""
  echo ""
  echo "Recommendation: Manual review required"
  echo "Consider using /revise interactively to adjust plan structure"
  echo "=========================================="
fi
```

**JSON Data Structure:**

```json
{
  "phase": 3,
  "replan_count": 2,
  "max_allowed": 2
}
```

**Error Handling:**

```bash
# Validate replan count is numeric
if ! [[ "$PHASE_REPLAN_COUNT" =~ ^[0-9]+$ ]]; then
  echo "Warning: Invalid replan count in checkpoint. Defaulting to 0."
  PHASE_REPLAN_COUNT="0"
fi

# Log even if count invalid (for debugging)
log_loop_prevention "$CURRENT_PHASE" "${PHASE_REPLAN_COUNT:-0}" "$ACTION"
```

**Step 3.7: Create .claude/logs/ Directory**

**Integration Code (Initialization):**

```bash
# Create logs directory if not exists
LOGS_DIR="${CLAUDE_LOGS_DIR:-.claude/logs}"
if [ ! -d "$LOGS_DIR" ]; then
  mkdir -p "$LOGS_DIR"
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to create logs directory: $LOGS_DIR"
    echo "Logging may not work correctly."
  fi
fi

# Set permissions (readable/writable by user only)
chmod 700 "$LOGS_DIR" 2>/dev/null || true
```

**Task 2.3 Deliverables:**
- [x] Logger library sourced at command initialization
- [x] Complexity check logging integrated with error handling
- [x] Test failure pattern logging integrated with error handling
- [x] Scope drift logging integrated with validation
- [x] Replan invocation logging integrated (success and failure cases)
- [x] Loop prevention logging integrated with checkpoint loading
- [x] .claude/logs/ directory creation logic added
- [x] All error handling implemented for logging failures

---

### Task 2.4: Verify Log Format and Rotation

**Objective:** Test log file creation, structured format, rotation mechanism, and concurrent logging scenarios.

**Step 4.1: Test Log File Creation**

**Test Plan:**

```bash
# Test 1: Verify log file created on first write
rm -f .claude/logs/adaptive-planning.log*
log_complexity_check "1" "5.2" "8" "7"
test -f .claude/logs/adaptive-planning.log && echo "PASS: Log file created" || echo "FAIL"

# Test 2: Verify log directory created if missing
rm -rf .claude/logs
log_complexity_check "1" "5.2" "8" "7"
test -d .claude/logs && echo "PASS: Log directory created" || echo "FAIL"

# Test 3: Verify file permissions (700 for directory)
PERMS=$(stat -c %a .claude/logs 2>/dev/null || stat -f %A .claude/logs 2>/dev/null)
[[ "$PERMS" == "700" ]] && echo "PASS: Directory permissions" || echo "WARN: Unexpected permissions $PERMS"
```

**Expected Results:**
- Log file created: .claude/logs/adaptive-planning.log
- Directory permissions: 700 (drwx------)
- File permissions: 644 (default, writable by user)

**Step 4.2: Verify Structured Format**

**Test Plan:**

```bash
# Test 4: Verify log entry format
rm -f .claude/logs/adaptive-planning.log
log_complexity_check "3" "9.2" "8" "12"

# Read log entry
LOG_ENTRY=$(cat .claude/logs/adaptive-planning.log)

# Verify timestamp format (ISO8601)
echo "$LOG_ENTRY" | grep -qE '^\[2[0-9]{3}-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z\]' \
  && echo "PASS: Timestamp format" || echo "FAIL"

# Verify log level
echo "$LOG_ENTRY" | grep -q "INFO" \
  && echo "PASS: Log level INFO" || echo "FAIL"

# Verify event type
echo "$LOG_ENTRY" | grep -q "trigger_eval" \
  && echo "PASS: Event type" || echo "FAIL"

# Verify message
echo "$LOG_ENTRY" | grep -q "complexity.*triggered" \
  && echo "PASS: Message present" || echo "FAIL"

# Verify JSON data
echo "$LOG_ENTRY" | grep -q 'data={"phase":' \
  && echo "PASS: JSON data present" || echo "FAIL"

# Verify JSON is valid
JSON_DATA=$(echo "$LOG_ENTRY" | sed 's/.*data=//')
echo "$JSON_DATA" | jq empty 2>/dev/null \
  && echo "PASS: Valid JSON" || echo "FAIL"
```

**Expected Format:**

```
[2025-10-09T14:23:45Z] INFO trigger_eval: Trigger evaluation: complexity -> triggered | data={"phase": 3, "score": 9.2, "threshold": 8, "tasks": 12}
```

**Step 4.3: Test Log Rotation**

**Test Plan:**

```bash
# Test 5: Create log file near 10MB and trigger rotation
rm -f .claude/logs/adaptive-planning.log*

# Generate ~9.9MB of log entries
for i in {1..20000}; do
  log_complexity_check "$((i % 10 + 1))" "7.5" "8" "8"
done

# Check initial file size
SIZE1=$(stat -c%s .claude/logs/adaptive-planning.log 2>/dev/null || stat -f%z .claude/logs/adaptive-planning.log)
echo "Initial size: $SIZE1 bytes"

# Add more entries to trigger rotation
for i in {1..5000}; do
  log_complexity_check "$((i % 10 + 1))" "7.5" "8" "8"
done

# Verify rotation occurred
test -f .claude/logs/adaptive-planning.log.1 \
  && echo "PASS: Rotation created .log.1" || echo "FAIL"

# Verify new log file is smaller than 10MB
SIZE2=$(stat -c%s .claude/logs/adaptive-planning.log 2>/dev/null || stat -f%z .claude/logs/adaptive-planning.log)
[[ $SIZE2 -lt $SIZE1 ]] \
  && echo "PASS: New log file smaller after rotation" || echo "FAIL"

# Test 6: Verify 5-file rotation limit
# Continue adding entries to trigger multiple rotations
for round in {1..5}; do
  for i in {1..20000}; do
    log_complexity_check "$((i % 10 + 1))" "7.5" "8" "8"
  done
done

# Count rotated log files
ROTATED_COUNT=$(ls -1 .claude/logs/adaptive-planning.log.* 2>/dev/null | wc -l)
[[ $ROTATED_COUNT -le 5 ]] \
  && echo "PASS: Maximum 5 rotated files ($ROTATED_COUNT found)" \
  || echo "FAIL: Too many rotated files ($ROTATED_COUNT > 5)"

# Verify .log.6 does not exist
test ! -f .claude/logs/adaptive-planning.log.6 \
  && echo "PASS: .log.6 does not exist" || echo "FAIL"
```

**Expected Behavior:**
- Log file rotates when reaching 10MB
- Old log renamed to .log.1
- Maximum 5 rotated files retained (.log.1 through .log.5)
- Oldest file (.log.5) deleted when 6th rotation occurs

**Step 4.4: Test Concurrent Logging**

**Test Plan:**

```bash
# Test 7: Multiple processes logging simultaneously
rm -f .claude/logs/adaptive-planning.log*

# Function to simulate logging from multiple processes
simulate_concurrent_logging() {
  for i in {1..100}; do
    log_complexity_check "$1" "7.5" "8" "8"
  done
}

# Run 3 concurrent processes
simulate_concurrent_logging 1 &
simulate_concurrent_logging 2 &
simulate_concurrent_logging 3 &

# Wait for all processes to complete
wait

# Verify log file not corrupted
LOG_LINES=$(wc -l < .claude/logs/adaptive-planning.log)
echo "Total log entries: $LOG_LINES"

# Should be exactly 300 lines (100 per process × 3)
[[ $LOG_LINES -eq 300 ]] \
  && echo "PASS: Concurrent logging works (300 entries)" \
  || echo "WARN: Unexpected entry count ($LOG_LINES, expected 300)"

# Verify no partial lines (all entries complete)
VALID_LINES=$(grep -cE '^\[2[0-9]{3}' .claude/logs/adaptive-planning.log)
[[ $VALID_LINES -eq $LOG_LINES ]] \
  && echo "PASS: No corrupted entries" \
  || echo "FAIL: Found $((LOG_LINES - VALID_LINES)) corrupted entries"
```

**Expected Behavior:**
- All log entries written successfully
- No interleaved or corrupted entries
- Total entry count matches expected (300)

**Note:** The logger does not use file locking, so some interleaving is theoretically possible under heavy concurrent load. However, for typical /implement usage (single process), this is not a concern.

**Task 2.4 Deliverables:**
- [x] Log file creation tested
- [x] Structured format verified (timestamp, level, event, message, JSON)
- [x] Log rotation tested (10MB threshold, 5-file limit)
- [x] Concurrent logging tested (3 parallel processes)
- [x] Test scripts documented for future validation

---

### Task 2.5: Documentation and Query Examples

**Objective:** Document logging integration and provide query examples for troubleshooting and analysis.

**Step 5.1: Update DEFERRED_TASKS.md**

**Section to Add:**

```markdown
## Task 6: Adaptive Planning Logging and Observability [COMPLETED]

**Status**: ✅ Completed (2025-10-09)
**Implementation**: Phase 2 of Plan 035

### Overview
Integrated adaptive planning logger into /implement command to provide observability into automatic replanning decisions.

### Integration Points
Logging added at 5 critical points in /implement workflow:
1. **Complexity check** (Step 3.4, Trigger 1): Logs after phase complexity calculation
2. **Test failure pattern** (Step 3.4, Trigger 2): Logs after test failure count increment
3. **Scope drift detection** (Step 3.4, Trigger 3): Logs when --report-scope-drift flag used
4. **Replan invocation** (Step 3.4, Step 3): Logs before and after /revise --auto-mode call
5. **Loop prevention** (Step 3.4, Step 1): Logs replan count check and blocking decision

### Log File
- **Location**: `.claude/logs/adaptive-planning.log`
- **Format**: `[timestamp] LEVEL event_type: message | data=JSON`
- **Rotation**: 10MB max size, 5 files retained
- **Created**: Automatically on first log write

### Query Examples

**View recent adaptive planning events:**
```bash
# Show last 20 entries (all types)
tail -n 20 .claude/logs/adaptive-planning.log

# Show recent complexity checks only
source .claude/lib/adaptive-planning-logger.sh
query_adaptive_log "trigger_eval.*complexity" 10

# Show recent replanning operations
query_adaptive_log "replan" 5

# Show loop prevention blocks
query_adaptive_log "loop_prevention.*blocked" 10
```

**Get statistical summary:**
```bash
# Show counts by trigger type and replan success/failure
source .claude/lib/adaptive-planning-logger.sh
get_adaptive_stats
```

**Analyze specific phase:**
```bash
# Show all events for Phase 3
grep "\"phase\": 3" .claude/logs/adaptive-planning.log

# Count how many times Phase 3 triggered complexity expansion
grep "\"phase\": 3" .claude/logs/adaptive-planning.log | \
  grep "complexity.*triggered" | wc -l
```

**Debug failed replanning:**
```bash
# Show all failed replan attempts
grep "replan.*failure" .claude/logs/adaptive-planning.log

# Extract error messages
grep "replan.*failure" .claude/logs/adaptive-planning.log | \
  sed 's/.*data=//' | jq -r '.context.error_details'
```

### Testing
Integration tested with:
- Log file creation and format validation
- Rotation mechanism (10MB threshold, 5-file limit)
- Concurrent logging (3 parallel processes)
- Query utilities (event filtering, statistics)

### Files Modified
- `.claude/commands/implement.md`: Added logger sourcing and 5 logging calls
- `.claude/lib/adaptive-planning-logger.sh`: Already implemented (297 lines)
- `.claude/logs/`: Created automatically on first log write

### Performance Impact
- Logging overhead: <1ms per call
- Total per-phase overhead: <10ms (5-10 log calls)
- No user-visible latency impact
- Disk space: Maximum 50MB (10MB × 5 files)
```

**Step 5.2: Create Query Examples Documentation**

**File**: `.claude/docs/adaptive-planning-logging.md` (New file)

```markdown
# Adaptive Planning Logging Guide

## Overview

The adaptive planning logger provides structured, queryable logs of all automatic replanning decisions made by the `/implement` command.

## Log File Location

```
.claude/logs/adaptive-planning.log
```

**Rotation**: Log rotates at 10MB, keeping 5 files (.log.1 through .log.5)

## Log Entry Format

```
[timestamp] LEVEL event_type: message | data=JSON
```

**Components:**
- `timestamp`: ISO8601 UTC (e.g., 2025-10-09T14:23:45Z)
- `LEVEL`: INFO, WARN, ERROR
- `event_type`: trigger_eval, replan, loop_prevention
- `message`: Human-readable description
- `data`: JSON object with structured context

## Event Types

### 1. trigger_eval (Trigger Evaluation)

Records complexity checks, test failure pattern detection, and scope drift detection.

**Example:**
```
[2025-10-09T14:23:45Z] INFO trigger_eval: Trigger evaluation: complexity -> triggered | data={"phase": 3, "score": 9.2, "threshold": 8, "tasks": 12}
```

**Data Fields:**
- `phase`: Integer phase number
- `score`: Float complexity score (for complexity triggers)
- `threshold`: Threshold value used
- `tasks`: Task count (for complexity triggers)
- `consecutive_failures`: Failure count (for test failure triggers)
- `log`: Error excerpt (for test failure triggers)
- `description`: Drift description (for scope drift triggers)

### 2. replan (Replanning Invocation)

Records /revise --auto-mode invocations and outcomes.

**Example (Success):**
```
[2025-10-09T14:23:46Z] INFO replan: Replanning invoked: expand_phase -> success | data={"revision_type": "expand_phase", "result": "specs/plans/025_plan/phase_3_refactor.md", "context": {"reason": "Phase complexity score 9.2 exceeds threshold 8"}}
```

**Example (Failure):**
```
[2025-10-09T14:23:46Z] ERROR replan: Replanning invoked: expand_phase -> failure | data={"revision_type": "expand_phase", "result": "Failed to parse plan structure", "context": {"reason": "Phase complexity score 9.2 exceeds threshold 8"}}
```

**Data Fields:**
- `revision_type`: expand_phase, add_phase, split_phase, update_tasks
- `result`: Plan path (success) or error message (failure)
- `context`: JSON with reason, phase, and trigger-specific data

### 3. loop_prevention (Loop Prevention Check)

Records replan count checks and blocking decisions.

**Example (Allowed):**
```
[2025-10-09T14:23:44Z] INFO loop_prevention: Loop prevention: phase 3 replan count 1 -> allowed | data={"phase": 3, "replan_count": 1, "max_allowed": 2}
```

**Example (Blocked):**
```
[2025-10-09T14:24:12Z] WARN loop_prevention: Loop prevention: phase 3 replan count 2 -> blocked | data={"phase": 3, "replan_count": 2, "max_allowed": 2}
```

**Data Fields:**
- `phase`: Integer phase number
- `replan_count`: Current replan count for phase
- `max_allowed`: Maximum replans allowed (always 2)

## Query Examples

### Using Built-In Query Functions

```bash
# Source the logger to access query functions
source .claude/lib/adaptive-planning-logger.sh

# Show last 10 events (all types)
query_adaptive_log "" 10

# Show last 5 complexity checks
query_adaptive_log "trigger_eval.*complexity" 5

# Show last 3 replan operations
query_adaptive_log "replan" 3

# Get statistical summary
get_adaptive_stats
```

### Using Standard Unix Tools

**View recent entries:**
```bash
# Last 20 lines
tail -n 20 .claude/logs/adaptive-planning.log

# Follow in real-time
tail -f .claude/logs/adaptive-planning.log
```

**Filter by event type:**
```bash
# All trigger evaluations
grep "trigger_eval" .claude/logs/adaptive-planning.log

# Only triggered (not not_triggered)
grep "trigger_eval.*triggered" .claude/logs/adaptive-planning.log | \
  grep -v "not_triggered"

# All replanning operations
grep "replan" .claude/logs/adaptive-planning.log

# Only failed replans
grep "replan.*failure" .claude/logs/adaptive-planning.log

# Loop prevention blocks
grep "loop_prevention.*blocked" .claude/logs/adaptive-planning.log
```

**Filter by phase:**
```bash
# All events for Phase 3
grep "\"phase\": 3" .claude/logs/adaptive-planning.log

# Complexity checks for Phase 3
grep "\"phase\": 3" .claude/logs/adaptive-planning.log | \
  grep "complexity"
```

**Extract JSON data:**
```bash
# Extract all complexity scores
grep "trigger_eval.*complexity" .claude/logs/adaptive-planning.log | \
  sed 's/.*data=//' | jq -r '.score'

# Extract all error messages from failed replans
grep "replan.*failure" .claude/logs/adaptive-planning.log | \
  sed 's/.*data=//' | jq -r '.result'

# List all phases that hit loop prevention
grep "loop_prevention.*blocked" .claude/logs/adaptive-planning.log | \
  sed 's/.*data=//' | jq -r '.phase' | sort -u
```

**Count events:**
```bash
# Total trigger evaluations
grep -c "trigger_eval" .claude/logs/adaptive-planning.log

# Complexity triggers (triggered, not not_triggered)
grep "trigger_eval.*complexity.*triggered" .claude/logs/adaptive-planning.log | \
  grep -vc "not_triggered"

# Total replanning operations
grep -c "replan" .claude/logs/adaptive-planning.log

# Failed replans
grep -c "replan.*failure" .claude/logs/adaptive-planning.log

# Loop prevention blocks
grep -c "loop_prevention.*blocked" .claude/logs/adaptive-planning.log
```

**Time-based queries:**
```bash
# Events from today (2025-10-09)
grep "2025-10-09" .claude/logs/adaptive-planning.log

# Events from last hour (requires date calculation)
HOUR_AGO=$(date -u -d '1 hour ago' +%Y-%m-%dT%H 2>/dev/null || \
           date -u -v-1H +%Y-%m-%dT%H 2>/dev/null)
grep "$HOUR_AGO" .claude/logs/adaptive-planning.log
```

## Troubleshooting Scenarios

### Scenario 1: Understanding Why a Phase Was Expanded

**Question:** "Why did /implement automatically expand Phase 3?"

```bash
# Find complexity check for Phase 3
grep "\"phase\": 3" .claude/logs/adaptive-planning.log | \
  grep "complexity"

# Expected output:
# [2025-10-09T14:23:45Z] INFO trigger_eval: Trigger evaluation: complexity -> triggered | data={"phase": 3, "score": 9.2, "threshold": 8, "tasks": 12}

# Extract score
grep "\"phase\": 3" .claude/logs/adaptive-planning.log | \
  grep "complexity" | sed 's/.*data=//' | jq -r '.score'
# Output: 9.2

# Conclusion: Phase 3 expanded because complexity score (9.2) > threshold (8)
```

### Scenario 2: Investigating Failed Replanning

**Question:** "Why did automatic replanning fail?"

```bash
# Find all failed replan attempts
grep "replan.*failure" .claude/logs/adaptive-planning.log

# Extract error messages
grep "replan.*failure" .claude/logs/adaptive-planning.log | \
  sed 's/.*data=//' | jq -r '.result'

# Example output: "Failed to parse plan structure"

# Find context (what triggered the replan)
grep "replan.*failure" .claude/logs/adaptive-planning.log | \
  sed 's/.*data=//' | jq -r '.context.reason'

# Example output: "Phase complexity score 9.2 exceeds threshold 8"
```

### Scenario 3: Checking Loop Prevention History

**Question:** "How many times has Phase 3 been replanned?"

```bash
# Find all loop prevention checks for Phase 3
grep "\"phase\": 3" .claude/logs/adaptive-planning.log | \
  grep "loop_prevention"

# Extract replan counts
grep "\"phase\": 3" .claude/logs/adaptive-planning.log | \
  grep "loop_prevention" | sed 's/.*data=//' | jq -r '.replan_count'

# Check if blocked
grep "\"phase\": 3" .claude/logs/adaptive-planning.log | \
  grep "loop_prevention.*blocked"

# If found: Phase 3 hit replan limit (2)
# If not found: Phase 3 still under limit
```

### Scenario 4: Analyzing Trigger Patterns

**Question:** "Which trigger type activates most frequently?"

```bash
# Count by trigger type
echo "Complexity triggers:"
grep "trigger_eval.*complexity.*triggered" .claude/logs/adaptive-planning.log | \
  grep -vc "not_triggered"

echo "Test failure triggers:"
grep "trigger_eval.*test_failure.*triggered" .claude/logs/adaptive-planning.log | \
  grep -vc "not_triggered"

echo "Scope drift triggers:"
grep "trigger_eval.*scope_drift.*triggered" .claude/logs/adaptive-planning.log | \
  grep -vc "not_triggered"

# Or use get_adaptive_stats for formatted output
source .claude/lib/adaptive-planning-logger.sh
get_adaptive_stats
```

## Performance Impact

- **Logging overhead**: <1ms per log call
- **Disk I/O**: Append-only writes (buffered by OS)
- **Disk space**: Maximum 50MB (10MB × 5 files)
- **Rotation overhead**: ~0.1ms stat check per write

## Maintenance

**Viewing log size:**
```bash
du -h .claude/logs/adaptive-planning.log*
```

**Manual rotation:**
```bash
# Move current log to .log.1
mv .claude/logs/adaptive-planning.log .claude/logs/adaptive-planning.log.1

# New log will be created on next write
```

**Clearing old logs:**
```bash
# Remove all rotated logs (keep current)
rm -f .claude/logs/adaptive-planning.log.[1-5]

# Remove all logs (reset)
rm -f .claude/logs/adaptive-planning.log*
```

## See Also

- [Adaptive Planning Documentation](../CLAUDE.md#adaptive-planning)
- [Logger API Documentation](../lib/adaptive-planning-logger.sh)
- [Implementation Command](../commands/implement.md)
```

**Step 5.3: Add Troubleshooting Guide**

Already included in query examples documentation above (Troubleshooting Scenarios section).

**Task 2.5 Deliverables:**
- [x] DEFERRED_TASKS.md updated with completion status and query examples
- [x] Created adaptive-planning-logging.md with comprehensive documentation
- [x] Documented all event types with examples
- [x] Provided 15+ query examples for common scenarios
- [x] Included troubleshooting guide for 4 common issues
- [x] Documented performance impact and maintenance procedures

---

## Testing Specifications

### Test Plan Overview

Testing will validate:
1. Log file creation and directory setup
2. Structured format for all event types
3. Log rotation mechanism
4. Query utilities functionality
5. Concurrent logging safety
6. Performance impact measurement

### Integration Test Suite

**File**: `.claude/tests/test_adaptive_logging.sh` (New test file)

```bash
#!/usr/bin/env bash
#
# Integration tests for adaptive planning logging
#
# Tests the logging integration in /implement command and verifies
# structured log format, rotation, and query utilities.

set -euo pipefail

# Test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

# Source logger
source "$SCRIPT_DIR/../lib/adaptive-planning-logger.sh"

# Setup
setup_test_env() {
  TEST_LOGS_DIR="$(mktemp -d)"
  export CLAUDE_LOGS_DIR="$TEST_LOGS_DIR"
  export AP_LOG_FILE="$TEST_LOGS_DIR/adaptive-planning.log"
}

# Teardown
teardown_test_env() {
  rm -rf "$TEST_LOGS_DIR"
}

# Test 1: Log file creation
test_log_file_creation() {
  setup_test_env

  log_complexity_check "1" "5.2" "8" "7"

  assert_file_exists "$AP_LOG_FILE" "Log file created"

  teardown_test_env
}

# Test 2: Complexity check logging
test_complexity_check_logging() {
  setup_test_env

  log_complexity_check "3" "9.2" "8" "12"

  assert_file_contains "$AP_LOG_FILE" "trigger_eval" "Event type"
  assert_file_contains "$AP_LOG_FILE" "complexity" "Trigger type"
  assert_file_contains "$AP_LOG_FILE" "triggered" "Result"
  assert_file_contains "$AP_LOG_FILE" '"phase": 3' "Phase number"
  assert_file_contains "$AP_LOG_FILE" '"score": 9.2' "Complexity score"

  teardown_test_env
}

# Test 3: Test failure pattern logging
test_failure_pattern_logging() {
  setup_test_env

  log_test_failure_pattern "2" "2" "Error: Module not found"

  assert_file_contains "$AP_LOG_FILE" "test_failure" "Trigger type"
  assert_file_contains "$AP_LOG_FILE" "triggered" "Result"
  assert_file_contains "$AP_LOG_FILE" '"consecutive_failures": 2' "Failure count"
  assert_file_contains "$AP_LOG_FILE" "Module not found" "Error excerpt"

  teardown_test_env
}

# Test 4: Scope drift logging
test_scope_drift_logging() {
  setup_test_env

  log_scope_drift "3" "Database migration required"

  assert_file_contains "$AP_LOG_FILE" "scope_drift" "Trigger type"
  assert_file_contains "$AP_LOG_FILE" "triggered" "Result"
  assert_file_contains "$AP_LOG_FILE" "Database migration required" "Description"

  teardown_test_env
}

# Test 5: Replan invocation logging (success)
test_replan_success_logging() {
  setup_test_env

  log_replan_invocation "expand_phase" "success" \
    "specs/plans/025_plan/phase_3.md" \
    '{"reason": "Complexity threshold"}'

  assert_file_contains "$AP_LOG_FILE" "replan" "Event type"
  assert_file_contains "$AP_LOG_FILE" "expand_phase" "Revision type"
  assert_file_contains "$AP_LOG_FILE" "success" "Status"
  assert_file_contains "$AP_LOG_FILE" "phase_3.md" "Result"

  teardown_test_env
}

# Test 6: Replan invocation logging (failure)
test_replan_failure_logging() {
  setup_test_env

  log_replan_invocation "expand_phase" "failure" \
    "Parse error" \
    '{"reason": "Complexity threshold"}'

  assert_file_contains "$AP_LOG_FILE" "ERROR" "Error level"
  assert_file_contains "$AP_LOG_FILE" "failure" "Status"
  assert_file_contains "$AP_LOG_FILE" "Parse error" "Error message"

  teardown_test_env
}

# Test 7: Loop prevention logging
test_loop_prevention_logging() {
  setup_test_env

  log_loop_prevention "3" "2" "blocked"

  assert_file_contains "$AP_LOG_FILE" "WARN" "Warning level"
  assert_file_contains "$AP_LOG_FILE" "loop_prevention" "Event type"
  assert_file_contains "$AP_LOG_FILE" "blocked" "Action"
  assert_file_contains "$AP_LOG_FILE" '"replan_count": 2' "Count"

  teardown_test_env
}

# Test 8: Log format validation
test_log_format_validation() {
  setup_test_env

  log_complexity_check "1" "5.2" "8" "7"

  LOG_ENTRY=$(cat "$AP_LOG_FILE")

  # Verify timestamp
  echo "$LOG_ENTRY" | grep -qE '^\[2[0-9]{3}-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z\]' \
    || fail "Invalid timestamp format"

  # Verify JSON is valid
  JSON_DATA=$(echo "$LOG_ENTRY" | sed 's/.*data=//')
  echo "$JSON_DATA" | jq empty 2>/dev/null \
    || fail "Invalid JSON data"

  pass "Log format valid"

  teardown_test_env
}

# Test 9: Log rotation
test_log_rotation() {
  setup_test_env

  # Generate ~11MB of logs
  for i in {1..22000}; do
    log_complexity_check "$((i % 10 + 1))" "7.5" "8" "8"
  done

  # Verify rotation occurred
  assert_file_exists "$AP_LOG_FILE.1" "Rotated log created"

  # Verify new log is smaller
  SIZE_CURRENT=$(stat -c%s "$AP_LOG_FILE" 2>/dev/null || stat -f%z "$AP_LOG_FILE")
  [[ $SIZE_CURRENT -lt 10485760 ]] \
    || fail "New log file should be < 10MB, got $SIZE_CURRENT"

  pass "Log rotation works"

  teardown_test_env
}

# Test 10: Query utilities
test_query_utilities() {
  setup_test_env

  # Generate mixed events
  log_complexity_check "1" "9.2" "8" "12"
  log_test_failure_pattern "2" "2" "Error"
  log_replan_invocation "expand_phase" "success" "plan.md" '{}'
  log_loop_prevention "3" "1" "allowed"

  # Test query_adaptive_log
  RESULT=$(query_adaptive_log "replan" 10)
  echo "$RESULT" | grep -q "replan" \
    || fail "Query should find replan events"

  # Test get_adaptive_stats
  STATS=$(get_adaptive_stats)
  echo "$STATS" | grep -q "Total Trigger Evaluations" \
    || fail "Stats should show trigger count"

  pass "Query utilities work"

  teardown_test_env
}

# Run all tests
run_tests() {
  echo "Running adaptive planning logging tests..."
  echo

  test_log_file_creation
  test_complexity_check_logging
  test_failure_pattern_logging
  test_scope_drift_logging
  test_replan_success_logging
  test_replan_failure_logging
  test_loop_prevention_logging
  test_log_format_validation
  test_log_rotation
  test_query_utilities

  echo
  report_results
}

# Execute
run_tests
```

### Performance Testing

**Test**: Measure logging overhead per call

```bash
# Benchmark script
#!/usr/bin/env bash

source .claude/lib/adaptive-planning-logger.sh

# Benchmark 1000 log calls
START=$(date +%s%N)
for i in {1..1000}; do
  log_complexity_check "$((i % 10 + 1))" "7.5" "8" "8"
done
END=$(date +%s%N)

DURATION_NS=$((END - START))
DURATION_MS=$((DURATION_NS / 1000000))
AVG_MS=$(echo "scale=3; $DURATION_MS / 1000" | bc)

echo "1000 log calls: ${DURATION_MS}ms"
echo "Average per call: ${AVG_MS}ms"
```

**Expected Results:**
- Total time for 1000 calls: <1000ms
- Average per call: <1ms

### Error Handling Tests

**Test**: Logger gracefully handles invalid inputs

```bash
# Test invalid complexity score
log_complexity_check "1" "invalid" "8" "7"
# Should log with score "0" (fallback)

# Test missing phase number
log_complexity_check "" "7.5" "8" "7"
# Should log with phase "0" (fallback)

# Test empty failure log
log_test_failure_pattern "2" "2" ""
# Should log with "No error output captured"

# Test missing context JSON
log_replan_invocation "expand_phase" "success" "plan.md" ""
# Should log without context field
```

---

## Error Handling

### Logging Failure Scenarios

**Scenario 1: Logger Library Not Found**

**Detection:**
```bash
if [ ! -f "$SCRIPT_DIR/../lib/adaptive-planning-logger.sh" ]; then
  echo "Warning: Adaptive planning logger not found. Logging disabled."
fi
```

**Fallback:**
Define no-op functions so logging calls don't cause command failure:
```bash
log_complexity_check() { :; }
log_test_failure_pattern() { :; }
log_scope_drift() { :; }
log_replan_invocation() { :; }
log_loop_prevention() { :; }
```

**Impact:** /implement continues without logging. User sees warning once.

**Scenario 2: Log Directory Not Writable**

**Detection:**
```bash
if [ ! -w "$LOGS_DIR" ]; then
  echo "Warning: Log directory not writable: $LOGS_DIR"
fi
```

**Fallback:**
Logger library handles this internally by checking `mkdir -p` and `chmod` return codes. Logs warning but doesn't fail.

**Impact:** Logging disabled. User sees warning. /implement continues.

**Scenario 3: Disk Full**

**Detection:**
```bash
# Write operation fails
if ! echo "$entry" >> "$AP_LOG_FILE" 2>/dev/null; then
  echo "Warning: Failed to write log entry (disk full?)" >&2
fi
```

**Fallback:**
Silent failure. Log entry dropped. No command failure.

**Impact:** Some log entries lost. /implement continues.

**Scenario 4: Invalid JSON in Log Data**

**Detection:**
Validate JSON before logging:
```bash
if ! echo "$REVISION_CONTEXT" | jq empty 2>/dev/null; then
  echo "Warning: Invalid JSON context. Logging with empty context."
  REVISION_CONTEXT="{}"
fi
```

**Fallback:**
Log with empty or sanitized JSON. No command failure.

**Impact:** Reduced log quality but /implement continues.

### Fallback Behavior

**Principle:** Logging must never block or fail /implement execution.

**Implementation:**
- All log functions return 0 (success) even if write fails
- Errors printed to stderr (visible but non-blocking)
- No exception throwing or exit calls in logger
- /implement checks logger availability, uses no-ops if missing

### Disk Space Handling

**Prevention:**
- Log rotation at 10MB ensures bounded growth
- Maximum 50MB total disk usage (10MB × 5 files)
- Rotation deletes oldest file automatically

**Detection:**
```bash
# Check available disk space before writing
AVAILABLE=$(df "$LOGS_DIR" | tail -1 | awk '{print $4}')
if [ "$AVAILABLE" -lt 10485760 ]; then
  echo "Warning: Low disk space. Logging may fail." >&2
fi
```

**Note:** This check not implemented (overhead not justified for CLI tool). Rely on rotation limits and OS-level disk management.

### Permission Errors

**Scenario:** Log file created by different user/process with restrictive permissions

**Detection:**
```bash
if [ ! -w "$AP_LOG_FILE" ]; then
  echo "Warning: Log file not writable: $AP_LOG_FILE" >&2
  return 1
fi
```

**Fallback:**
Skip logging for this call. User sees warning. /implement continues.

### Log Rotation Failures

**Scenario:** File move/delete operations fail during rotation

**Detection:**
```bash
if ! mv "$AP_LOG_FILE" "${AP_LOG_FILE}.1" 2>/dev/null; then
  echo "Warning: Log rotation failed" >&2
  # Continue without rotation (file will grow beyond 10MB)
fi
```

**Fallback:**
Skip rotation. Log file grows beyond 10MB. User sees warning. Logging continues.

**Recovery:**
Manual intervention: Delete old rotated logs or current log to reset.

---

## Code Examples

### Complete Logging Integration Example

**Context:** /implement Step 3.4 with all 5 logging calls

```bash
# Step 3.4: Adaptive Planning Detection
# =======================================================================

# Source logger (once at command start)
source "$SCRIPT_DIR/../lib/adaptive-planning-logger.sh" || {
  echo "Warning: Logger not found. Logging disabled."
  log_complexity_check() { :; }
  log_test_failure_pattern() { :; }
  log_scope_drift() { :; }
  log_replan_invocation() { :; }
  log_loop_prevention() { :; }
}

# -----------------------------------------------------------------------
# POINT 5: Loop Prevention (before trigger detection)
# -----------------------------------------------------------------------

# Load checkpoint
CHECKPOINT=$(.claude/lib/checkpoint-utils.sh restore_checkpoint implement "$PROJECT_NAME")
PHASE_REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r ".replan_phase_counts.phase_${CURRENT_PHASE} // 0")

# Determine action
if [ "$PHASE_REPLAN_COUNT" -ge 2 ]; then
  ACTION="blocked"
else
  ACTION="allowed"
fi

# LOG: Loop prevention check
log_loop_prevention "$CURRENT_PHASE" "$PHASE_REPLAN_COUNT" "$ACTION"

if [ "$ACTION" = "blocked" ]; then
  echo "Warning: Replanning limit reached for Phase $CURRENT_PHASE"
  SKIP_REPLAN=true
fi

# -----------------------------------------------------------------------
# POINT 1: Complexity Check
# -----------------------------------------------------------------------

if [ "$SKIP_REPLAN" != "true" ]; then
  # Calculate complexity
  COMPLEXITY_RESULT=$(.claude/lib/complexity-utils.sh generate_complexity_report "$PHASE_NAME" "$TASK_LIST")
  COMPLEXITY_SCORE=$(echo "$COMPLEXITY_RESULT" | jq -r '.complexity_score')
  TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")

  # LOG: Complexity check
  log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "8" "$TASK_COUNT"

  # Check threshold
  if [ "$COMPLEXITY_SCORE" -gt 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
    TRIGGER_TYPE="expand_phase"
    TRIGGER_REASON="Phase complexity score $COMPLEXITY_SCORE exceeds threshold 8"
  fi
fi

# -----------------------------------------------------------------------
# POINT 2: Test Failure Pattern
# -----------------------------------------------------------------------

if [ "$SKIP_REPLAN" != "true" ] && [ "$TEST_RESULT" = "failed" ]; then
  PHASE_FAILURE_COUNT=$((PHASE_FAILURE_COUNT + 1))
  FAILURE_EXCERPT=$(echo "$ERROR_OUTPUT" | head -c 200 | tr '\n' ' ' | sed 's/"/\\"/g')

  # LOG: Test failure pattern
  log_test_failure_pattern "$CURRENT_PHASE" "$PHASE_FAILURE_COUNT" "$FAILURE_EXCERPT"

  # Check threshold
  if [ "$PHASE_FAILURE_COUNT" -ge 2 ]; then
    TRIGGER_TYPE="add_phase"
    TRIGGER_REASON="Two consecutive test failures in phase $CURRENT_PHASE"
  fi
fi

# -----------------------------------------------------------------------
# POINT 3: Scope Drift
# -----------------------------------------------------------------------

if [ "$SKIP_REPLAN" != "true" ] && [ "$REPORT_SCOPE_DRIFT" = "true" ]; then
  # LOG: Scope drift detection
  log_scope_drift "$CURRENT_PHASE" "$SCOPE_DRIFT_DESCRIPTION"

  TRIGGER_TYPE="update_tasks"
  TRIGGER_REASON="$SCOPE_DRIFT_DESCRIPTION"
fi

# -----------------------------------------------------------------------
# POINT 4: Replan Invocation (if any trigger detected)
# -----------------------------------------------------------------------

if [ -n "$TRIGGER_TYPE" ]; then
  # Build revision context
  REVISION_CONTEXT=$(jq -n \
    --arg type "$TRIGGER_TYPE" \
    --argjson phase "$CURRENT_PHASE" \
    --arg reason "$TRIGGER_REASON" \
    '{
      revision_type: $type,
      current_phase: $phase,
      reason: $reason
    }')

  # Invoke /revise --auto-mode
  REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")
  REVISION_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

  if [ "$REVISION_STATUS" = "success" ]; then
    UPDATED_PLAN=$(echo "$REVISE_RESULT" | jq -r '.plan_file')

    # LOG: Successful replan
    log_replan_invocation "$TRIGGER_TYPE" "success" "$UPDATED_PLAN" "$REVISION_CONTEXT"

    # Update checkpoint with replan metadata
    REPLAN_COUNT=$((REPLAN_COUNT + 1))
    PHASE_REPLAN_COUNT=$((PHASE_REPLAN_COUNT + 1))
    # ... checkpoint save logic ...

    # Continue with updated plan
    PLAN_PATH="$UPDATED_PLAN"
  else
    ERROR_MESSAGE=$(echo "$REVISE_RESULT" | jq -r '.error_message')

    # LOG: Failed replan
    log_replan_invocation "$TRIGGER_TYPE" "failure" "$ERROR_MESSAGE" "$REVISION_CONTEXT"

    echo "Warning: Adaptive planning revision failed: $ERROR_MESSAGE"
    echo "Continuing with original plan"
  fi
fi
```

### Example Log Entries

**Complexity Check (Triggered):**
```
[2025-10-09T14:23:45Z] INFO trigger_eval: Trigger evaluation: complexity -> triggered | data={"phase": 3, "score": 9.2, "threshold": 8, "tasks": 12}
```

**Test Failure Pattern (Not Yet Triggered):**
```
[2025-10-09T14:24:03Z] INFO trigger_eval: Trigger evaluation: test_failure -> not_triggered | data={"phase": 2, "consecutive_failures": 1, "log": "Error: Expected 5 tests to pass but got 4"}
```

**Scope Drift (Triggered):**
```
[2025-10-09T14:25:12Z] INFO trigger_eval: Trigger evaluation: scope_drift -> triggered | data={"phase": 3, "description": "Database migration script needed before schema changes"}
```

**Replan Success:**
```
[2025-10-09T14:25:14Z] INFO replan: Replanning invoked: expand_phase -> success | data={"revision_type": "expand_phase", "result": "specs/plans/025_plan/phase_3_refactor.md", "context": {"revision_type": "expand_phase", "current_phase": 3, "reason": "Phase complexity score 9.2 exceeds threshold 8"}}
```

**Loop Prevention Blocked:**
```
[2025-10-09T14:27:45Z] WARN loop_prevention: Loop prevention: phase 3 replan count 2 -> blocked | data={"phase": 3, "replan_count": 2, "max_allowed": 2}
```

### Example Query Commands

**Show all complexity triggers:**
```bash
source .claude/lib/adaptive-planning-logger.sh
query_adaptive_log "trigger_eval.*complexity.*triggered" 20
```

**Get statistics:**
```bash
source .claude/lib/adaptive-planning-logger.sh
get_adaptive_stats

# Output:
# Adaptive Planning Statistics
# ============================
# Total Trigger Evaluations: 45
#   - Complexity Triggers: 12
#   - Test Failure Triggers: 3
#   - Scope Drift Triggers: 2
#
# Total Replans: 15
#   - Successful: 14
#   - Failed: 1
#
# Log File: .claude/logs/adaptive-planning.log
# Log Size: 2.3M
```

---

## Deliverables

### Code Integration
- [x] Logger library sourced in /implement command initialization
- [x] 5 logging calls integrated at correct workflow points
- [x] Error handling for all logging failures
- [x] .claude/logs/ directory creation logic

### Testing
- [x] 10 integration tests in test_adaptive_logging.sh
- [x] Format validation test
- [x] Rotation mechanism test
- [x] Query utilities test
- [x] Performance benchmark script

### Documentation
- [x] DEFERRED_TASKS.md updated with Task 6 completion
- [x] adaptive-planning-logging.md created with comprehensive guide
- [x] 15+ query examples documented
- [x] Troubleshooting guide for 4 common scenarios

### Verification
- [x] All tests passing
- [x] Log format validated (timestamp, level, event, JSON)
- [x] Rotation working (10MB max, 5 files)
- [x] Query utilities functional
- [x] Performance impact <10ms per phase

---

## Success Criteria

- [ ] Logger library successfully sourced in /implement command
- [ ] Complexity check logging integrated and tested
- [ ] Test failure pattern logging integrated and tested
- [ ] Scope drift logging integrated and tested
- [ ] Replan invocation logging integrated (success and failure paths)
- [ ] Loop prevention logging integrated and tested
- [ ] .claude/logs/ directory created automatically
- [ ] Log file format validated (ISO8601 timestamp, level, event, JSON)
- [ ] Log rotation tested (10MB threshold, 5-file limit)
- [ ] Query utilities tested (event filtering, statistics)
- [ ] Performance impact verified (<10ms per phase)
- [ ] Documentation complete (DEFERRED_TASKS.md, logging guide)
- [ ] 15+ query examples documented with expected outputs
- [ ] Troubleshooting guide created for common scenarios
- [ ] All integration tests passing (10/10)

---

## Notes

### Dependencies
- Requires adaptive-planning-logger.sh (already implemented)
- Requires checkpoint-utils.sh for replan count tracking
- Requires complexity-utils.sh for complexity scoring
- Requires jq for JSON parsing

### Future Enhancements
- Add logging to other commands (/revise, /expand, /collapse)
- Implement log aggregation for multi-project analysis
- Add performance metrics (execution time, memory usage)
- Create visualization tool for log data (graphs, charts)
- Add log export to CSV/JSON for external analysis

### Known Limitations
- No file locking (assumes single /implement process)
- Query functions only search last 100 entries (limitation in query_adaptive_log)
- No structured query language (rely on grep + jq)
- No log compression (rotated files remain uncompressed)

---

**Phase Status**: Ready for Implementation
**Estimated Completion**: 3-4 hours
**Complexity**: High (7/10)
**Priority**: High (blocks observability for adaptive planning debugging)
