# Research Report: State System and Observability Infrastructure

## Report Metadata
- **Date**: 2025-12-10
- **Researcher**: research-specialist
- **Topic**: State persistence patterns, workflow state machines, error logging standards, and distributed state management for hierarchical agents
- **Status**: COMPLETE

## Executive Summary

The .claude/ system implements a comprehensive state management and observability infrastructure designed for multi-agent hierarchical workflows with bash subprocess isolation. The architecture consists of three core components:

1. **State Persistence Library** (`state-persistence.sh`): GitHub Actions-style file-based persistence with 70% performance improvement (50ms → 15ms for CLAUDE_PROJECT_DIR detection)
2. **Workflow State Machine** (`workflow-state-machine.sh`): Formal 8-state FSM with atomic transitions, complexity normalization, and idempotent transition handling
3. **Error Handling System** (`error-handling.sh`): Centralized JSONL logging with environment-based routing, dual trap setup, and structured query interface

**Key Findings**:
- State persistence uses selective file-based storage for 7 critical items with graceful degradation
- Workflow state machine provides explicit state validation with transition table and retry tracking
- Error logging achieves 100% coverage through early/late trap setup with test/production log separation
- Distributed state management handles concurrent execution via nanosecond-precision WORKFLOW_IDs
- Debugging capabilities include errors.jsonl query interface, /errors command, and /repair workflow integration

**Performance Characteristics**:
- State persistence: 15ms (cached CLAUDE_PROJECT_DIR), 5-10ms JSON checkpoints
- Error logging: <10ms per entry, <100ms queries, 10MB rotation threshold
- Workflow transitions: Atomic two-phase commit with pre/post checkpoints
- Concurrent execution: ~0% collision probability for human-triggered commands

## Research Findings

### 1. State Persistence Libraries

**File**: `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`

**Architecture Pattern**: GitHub Actions-style state persistence ($GITHUB_OUTPUT, $GITHUB_STATE)

**Core Functions**:

1. **init_workflow_state(workflow_id)**: Initialize state file in .claude/tmp/
   - Creates workflow-specific state file: `workflow_${WORKFLOW_ID}.sh`
   - Exports CLAUDE_PROJECT_DIR (70% performance improvement via caching)
   - Returns STATE_FILE path for caller to set EXIT trap
   - Performance: One-time 50ms detection → 15ms cached reads

2. **load_workflow_state(workflow_id, is_first_block, required_vars)**: Restore state across bash blocks
   - Two-phase validation: File integrity (size, readability) → Variable presence
   - Fail-fast mode for Block 2+ (is_first_block=false)
   - Graceful initialization for Block 1 (is_first_block=true)
   - Variable validation with detailed diagnostics on missing vars

3. **append_workflow_state(key, value)**: GitHub Actions-style state accumulation
   - Scalar-only values (JSON arrays rejected with type validation error)
   - Space-separated strings for array-like data
   - JSON allowlist for complex metadata (WORK_REMAINING, ERROR_FILTERS, etc.)
   - ERR trap suppression for validation failures (SUPPRESS_ERR_TRAP=1)

4. **save_json_checkpoint(name, json_data)**: Atomic JSON persistence
   - Temp file + mv for atomicity (no partial writes on crash)
   - 5-10ms write performance
   - Used for supervisor metadata, benchmark datasets, implementation tracking

**State File Path Pattern**:
```bash
# CORRECT: Use CLAUDE_PROJECT_DIR (supports HOME != PROJECT_DIR)
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

# INCORRECT: Using HOME causes PATH MISMATCH errors
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

**Selective State Persistence** (7 critical items use file-based storage):
1. Supervisor metadata (P0): 95% context reduction for metadata-only passing
2. Benchmark dataset (P0): Phase 3 accumulation across 10 subprocess invocations
3. Implementation supervisor state (P0): 40-60% time savings via parallel tracking
4. Testing supervisor state (P0): Lifecycle coordination across sequential stages
5. Migration progress (P1): Resumable audit trail for multi-hour migrations
6. Performance benchmarks (P1): Phase 3 dependency on Phase 2 data
7. POC metrics (P1): Success criterion validation with timestamped breakdown

**Decision Criteria for File-Based State**:
- State accumulates across subprocess boundaries
- Context reduction requires metadata aggregation (95% reduction)
- Recalculation is expensive (>30ms) or impossible
- Phase dependencies require prior phase outputs
- Non-deterministic state (user surveys, research findings)

**Concurrent Execution Safety** (Spec 012):
- Nanosecond-precision WORKFLOW_IDs eliminate collisions: `plan_$(date +%s%N)`
- State file discovery via `discover_latest_state_file(command_prefix)`
- NO shared state ID files (eliminates race conditions)
- Collision probability: ~0% for human-triggered concurrent commands

**Key Anti-Pattern**: Shared state ID files cause race conditions in concurrent execution. Use nanosecond timestamps + discovery pattern instead.

### 2. Workflow State Machine Patterns

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Architecture**: Formal finite state machine with 8 core states and explicit transition table

**8 Core States**:
```
initialize → research → plan → implement → test → debug → document → complete
```

**State Transition Table**:
```bash
STATE_TRANSITIONS=(
  [initialize]="research,implement"        # Can skip research for /build
  [research]="plan,complete"               # Research-only workflows
  [plan]="implement,complete,debug"        # Plan-only or debug-only
  [implement]="test,complete"              # Implement-only workflows
  [test]="debug,document,complete"         # Conditional: debug if failed
  [debug]="test,document,complete"         # Retry testing or complete
  [document]="complete"
  [complete]=""                            # Terminal state
)
```

**Core Functions**:

1. **sm_init(workflow_desc, command_name, workflow_type, complexity, topics_json)**: Initialize state machine
   - Accepts pre-computed classification (no internal classification)
   - Normalizes complexity to 1-4 range (handles legacy scores like 78.5)
   - Maps workflow_type to terminal state
   - Exports WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
   - Persists classification to state file
   - Returns normalized complexity for dynamic path allocation

2. **sm_transition(next_state, transition_reason)**: Validate and execute state transition
   - **Idempotent**: Same-state transitions succeed immediately (early-exit optimization)
   - **Terminal protection**: Prevents transitions from terminal states (complete, abandoned)
   - **Validation**: Checks transition table for allowed transitions
   - **Auto-initialization**: Attempts load_workflow_state if STATE_FILE not set (defensive recovery)
   - **Atomic commit**: Pre-transition + post-transition checkpoints
   - **History tracking**: Updates COMPLETED_STATES array (with deduplication)
   - **Error logging**: Logs invalid transitions with full context

3. **sm_validate_state()**: Validate state machine properly initialized
   - Checks STATE_FILE exists and is readable
   - Validates CURRENT_STATE is set
   - Warns if WORKFLOW_SCOPE missing

4. **sm_save(checkpoint_file)**: Serialize state machine to JSON checkpoint
   - v2.0 schema with state_machine section
   - Includes current_state, completed_states, transition_table, workflow_config
   - Atomic write with temp file + mv

5. **sm_load(checkpoint_file)**: Restore state machine from checkpoint
   - Detects v2.0, v1.3, or direct state machine format
   - Migrates phase-based (v1.3) to state-based (v2.0)
   - Restores CURRENT_STATE, WORKFLOW_SCOPE, COMPLETED_STATES

**Complexity Normalization**:
```bash
normalize_complexity() {
  # Valid 1-4 values pass through unchanged
  # Legacy scores mapped: <30→1, 30-49→2, 50-69→3, ≥70→4
  # Invalid inputs default to 2 with WARNING
}
```

**COMPLETED_STATES Array Persistence** (Spec 672 Phase 2):
- Serialized to indexed variables: COMPLETED_STATES_COUNT, COMPLETED_STATE_0, COMPLETED_STATE_1...
- Loaded via `load_completed_states_from_state()` after bash block boundaries
- Saved via `save_completed_states_to_state()` after state transitions

**Integration with Error Handling**:
```bash
# handle_state_error() from error-handling.sh
# Increments retry counters per state
# Logs to centralized error log with state context
# Max 2 retries per state before escalation
```

**Key Insight**: Idempotent transitions enable safe retry/resume scenarios without state transition errors.

### 3. Error Logging Standards

**File**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh`

**Architecture**: Centralized JSONL-based error logging with environment-based routing

**Error Log Locations**:
1. **Production**: `.claude/data/logs/errors.jsonl` (all non-test errors)
2. **Test**: `.claude/tests/logs/test-errors.jsonl` (test framework errors)

**Environment Detection Methods**:
1. Explicit: `export CLAUDE_TEST_MODE=1` (recommended for test suites)
2. Automatic: Script path matches `/tests/` pattern
3. Workflow ID: `WORKFLOW_ID=test_*` pattern

**Error Type Constants**:
```bash
# Standard workflow errors
ERROR_TYPE_STATE="state_error"               # State persistence issues
ERROR_TYPE_VALIDATION="validation_error"     # Input validation + contract violations
ERROR_TYPE_AGENT="agent_error"               # Subagent execution failures
ERROR_TYPE_PARSE="parse_error"               # Output parsing failures
ERROR_TYPE_FILE="file_error"                 # File system operations
ERROR_TYPE_TIMEOUT_ERR="timeout_error"       # Operation timeouts
ERROR_TYPE_EXECUTION="execution_error"       # General execution failures

# Recovery classification
ERROR_TYPE_TRANSIENT="transient"             # Retry recommended
ERROR_TYPE_PERMANENT="permanent"             # Code fix required
ERROR_TYPE_FATAL="fatal"                     # User intervention required
```

**JSONL Schema**:
```json
{
  "timestamp": "2025-10-19T15:30:45Z",
  "environment": "production",
  "command": "/implement",
  "workflow_id": "build_20251019_153045",
  "user_args": "plan.md 3",
  "error_type": "state_error",
  "error_message": "State file not found",
  "source": "bash_block",
  "stack": ["line1", "line2"],
  "context": {"expected_path": "/path", "phase": 3},
  "status": "ERROR",
  "status_updated_at": null,
  "repair_plan_path": null
}
```

**Error Lifecycle Status**:
- `ERROR`: New error (default)
- `FIX_PLANNED`: Set by `/repair` when plan created
- `RESOLVED`: Set when repair plan completes successfully

**Core Functions**:

1. **log_command_error(command, workflow_id, user_args, error_type, message, source, context_json)**
   - Appends to environment-specific JSONL log (production or test)
   - Validates context_json is valid JSON
   - Enhances context with environment paths for state/file errors
   - Calls rotate_error_log() before write
   - <10ms performance (atomic append)

2. **parse_subagent_error(output)**: Parse TASK_ERROR signal from agent output
   - Returns JSON: `{error_type, message, context, found}`
   - Extracts ERROR_CONTEXT JSON if present
   - Used for hierarchical agent error propagation

3. **query_errors(--command CMD --since TIME --type TYPE --limit N --workflow-id ID --log-file PATH)**
   - Filters JSONL entries with jq
   - Supports both production and test logs via --log-file
   - <100ms for 50 results

4. **recent_errors(count)**: Display last N errors in human-readable format
   - <50ms performance (tail + jq)
   - Shows timestamp, command, type, message, workflow ID, status, repair plan

5. **error_summary()**: Aggregate statistics
   - Counts by command and error type
   - Shows time range (first/last error)
   - <200ms performance (full file scan)

**Dual Trap Setup Pattern** (100% Error Coverage):
```bash
# EARLY TRAP: Capture errors during initialization
setup_bash_error_trap "/implement" "implement_early_$(date +%s)" "early_init"

# Flush pre-trap buffered errors
_flush_early_errors

# Validate trap is active
trap -p ERR | grep -q "_log_bash_error" || exit 1

# ... initialization code with full error coverage ...

# LATE TRAP: Update with actual workflow context
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**ERR Trap Suppression Pattern** (Prevent Duplicate Logging):
```bash
# In library validation functions
if validation_fails; then
  SUPPRESS_ERR_TRAP=1  # Prevent cascading execution_error log entry
  log_command_error ... "validation_error" ...
  return 1  # ERR trap sees flag and skips logging
fi
```

**Log Rotation Policy**:
- Threshold: 10MB file size (~10,000 errors)
- Retention: 5 backup files (.1 through .5)
- Automatic: Called on every log_command_error()

**Key Anti-Pattern**: Logging errors without dual trap setup creates 50-80 line coverage gaps where errors go unlogged.

### 4. Cross-Block State Maintenance

**Pattern**: GitHub Actions-style state persistence across bash subprocess boundaries

**Block 1 (Initialization)**:
```bash
# Initialize workflow state
WORKFLOW_ID="command_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
trap "rm -f '$STATE_FILE'" EXIT

# Set workflow context
COMMAND_NAME="/command"
USER_ARGS="$*"

# Persist automatically via init_workflow_state
# STATE_FILE contains: CLAUDE_PROJECT_DIR, WORKFLOW_ID, STATE_FILE
```

**Block 2+ (Restoration)**:
```bash
# Load workflow state
load_workflow_state "$WORKFLOW_ID" false

# Variables automatically restored:
# - COMMAND_NAME
# - USER_ARGS
# - WORKFLOW_ID
# - CLAUDE_PROJECT_DIR
# - STATE_FILE

# Validate critical variables restored
validate_state_restoration "COMMAND_NAME" "WORKFLOW_ID" || exit 1
```

**State Persistence for Error Context**:
```bash
# Block 1: Export and persist
export COMMAND_NAME USER_ARGS
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"

# Block 2+: Automatic restoration via load_workflow_state
# Variables available for log_command_error()
```

**Common Pitfall**: Forgetting to persist error logging variables (COMMAND_NAME, USER_ARGS) in Block 1 causes incomplete error context in later blocks.

**Performance Impact**:
- State persistence overhead: <1ms per append
- State restoration overhead: 15ms (file read + variable export)
- Total cross-block overhead: ~20ms (acceptable for 100% state consistency)

### 5. Error Return Protocols

**Agent Error Signal Format** (Hard Barrier Pattern):

**Signal Components**:
1. **ERROR_CONTEXT** (JSON block with structured details)
2. **TASK_ERROR** (one-line signal with error_type and message)

**Example Agent Error Return**:
```markdown
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Schema mismatch in user_id field",
  "details": {
    "field": "user_id",
    "expected": "string",
    "actual": "integer"
  }
}

TASK_ERROR: validation_error - Schema mismatch in user_id field
```

**Parent Command Processing**:
```bash
# Invoke agent and capture output
output=$(invoke_agent "research-specialist" "Research auth patterns")

# Parse error signal
error_json=$(parse_subagent_error "$output")

if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  error_type=$(echo "$error_json" | jq -r '.error_type')
  message=$(echo "$error_json" | jq -r '.message')
  context=$(echo "$error_json" | jq -c '.context')

  # Log with subagent attribution
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$error_type" \
    "Agent research-specialist failed: $message" \
    "subagent_research-specialist" \
    "$context"

  # Retry logic based on error type
  if [ "$error_type" = "timeout_error" ]; then
    retry_metadata=$(retry_with_timeout "research-specialist" 1)
    new_timeout=$(echo "$retry_metadata" | jq -r '.new_timeout')
    # ... retry with increased timeout
  else
    exit 1  # Permanent error - escalate
  fi
fi
```

**Contract Violation Example** (validation_error):
```json
{
  "timestamp": "2025-12-05T10:30:45Z",
  "command": "/implement",
  "workflow_id": "implement_20251205_103040",
  "error_type": "validation_error",
  "error_message": "Agent contract violation: requires_continuation=false with work_remaining non-empty",
  "source": "bash_block_1c_defensive_validation",
  "context": {
    "work_remaining": "Phase_4 Phase_5 Phase_6",
    "requires_continuation": "false",
    "override": "forced_true"
  }
}
```

**Recovery Patterns by Error Type**:

1. **Transient (timeout_error, llm_timeout)**: Retry with exponential backoff + increased timeout
2. **Permanent (parse_error, validation_error)**: Log error, suggest code fix, exit
3. **Fatal (state_error, file_error)**: Log error, provide system diagnostics, exit

**Retry Metadata Generation**:
```bash
# retry_with_timeout() - Exponential timeout increase
retry_metadata=$(retry_with_timeout "Agent invocation" 0)
new_timeout=$(echo "$retry_metadata" | jq -r '.new_timeout')
# Base: 120s, Attempt 1: 180s, Attempt 2: 270s, Attempt 3: 405s

# retry_with_fallback() - Reduced toolset recommendation
fallback_metadata=$(retry_with_fallback "expand_phase" 1)
reduced_toolset=$(echo "$fallback_metadata" | jq -r '.reduced_toolset')
# Full: Read,Write,Edit,Bash → Reduced: Read,Write
```

**Key Insight**: parse_subagent_error() returns `{found: false}` for successful agent executions, enabling clean if/else branching.

### 6. Debugging Patterns and Maintenance Workflows

**Error Consumption Workflow**:

1. **Query Errors**: `/errors [--command CMD] [--since TIME] [--type TYPE]`
   - View logged errors with filters
   - Example: `/errors --command /implement --limit 10`

2. **Analyze Patterns**: `/repair [--since TIME] [--type TYPE]`
   - Groups errors by pattern and root cause
   - Creates error analysis report
   - Generates implementation plan with fix phases
   - Updates error status to FIX_PLANNED

3. **Implement Fixes**: `/implement [plan-file]`
   - Executes repair plan
   - Updates error status to RESOLVED on success

**Debugging Commands**:

1. **recent_errors(count)**: Quick error overview
   ```bash
   recent_errors 5
   # Shows last 5 errors with timestamp, command, type, message
   ```

2. **error_summary()**: Aggregate statistics
   ```bash
   error_summary
   # Shows total errors, counts by command/type, time range
   ```

3. **query_errors()**: Advanced filtering
   ```bash
   query_errors --type state_error --since "2025-10-19T14:00:00Z"
   # Returns JSONL entries for programmatic analysis
   ```

**State Machine Debugging**:
```bash
# Print state machine status
sm_print_status
# Output:
# Current State: implement
# Workflow Scope: full-implementation
# Terminal State: complete
# Completed States: initialize research plan implement
# Completed Count: 4
# Is Terminal: no

# Validate state machine integrity
sm_validate_state || exit 1
# Checks STATE_FILE exists, CURRENT_STATE set, WORKFLOW_SCOPE set
```

**State File Diagnostics**:
```bash
# View state file contents
cat "$STATE_FILE"

# Check state file path consistency
validate_state_file_path "$WORKFLOW_ID" || exit 1
# Detects HOME vs CLAUDE_PROJECT_DIR mismatch

# Check completed states persistence
load_completed_states_from_state
echo "Completed states: ${COMPLETED_STATES[@]}"
```

**Error Status Updates** (Repair Workflow Integration):
```bash
# Mark errors as fix planned (bulk update)
updated_count=$(mark_errors_fix_planned "$plan_path" --command /implement --since 1h)
echo "Updated $updated_count errors to FIX_PLANNED status"

# Mark errors as resolved after plan completion
updated_count=$(mark_errors_resolved_for_plan "$plan_path")
echo "Updated $updated_count errors to RESOLVED status"

# Query errors by status
query_errors --status ERROR --limit 10        # Unresolved errors
query_errors --status FIX_PLANNED --limit 10  # Errors with repair plan
query_errors --status RESOLVED --limit 10     # Fixed errors
```

**Pre-Trap Error Buffering** (Early Initialization Errors):
```bash
# Buffer error before error-handling.sh is sourced
_buffer_early_error "$LINENO" "$?" "Failed to source library"

# Flush buffered errors after setup_bash_error_trap
_flush_early_errors
# Errors logged with initialization_error type
```

**Test Context Detection** (Prevent Test Pollution):
```bash
# Check if execution is in test framework
if is_test_context; then
  skip_error_logging
fi
# Detection: WORKFLOW_ID=test_*, /tmp/test_*.sh, SUPPRESS_ERR_LOGGING=1
```

**Key Maintenance Workflows**:
1. **Error trend analysis**: `error_summary` → Identify recurring patterns
2. **Post-mortem debugging**: `query_errors --workflow-id X` → Full workflow error history
3. **Systematic repair**: `/repair --type state_error` → Generate fix plan for pattern
4. **Error lifecycle tracking**: Status updates (ERROR → FIX_PLANNED → RESOLVED)

### 7. Centralized Error Log (errors.jsonl)

**File Locations**:
- Production: `/home/benjamin/.config/.claude/data/logs/errors.jsonl`
- Test: `/home/benjamin/.config/.claude/tests/logs/test-errors.jsonl`

**Log Structure**: JSONL (JSON Lines) format - one JSON object per line

**Schema Fields**:
```json
{
  "timestamp": "ISO 8601 timestamp",
  "environment": "production|test",
  "command": "Command name (e.g., /implement)",
  "workflow_id": "Unique workflow identifier",
  "user_args": "User-provided command arguments",
  "error_type": "Error type constant",
  "error_message": "Human-readable error description",
  "source": "Error source (bash_block, subagent, validation)",
  "stack": ["Array of stack trace lines"],
  "context": {"Additional context as JSON object"},
  "status": "ERROR|FIX_PLANNED|RESOLVED",
  "status_updated_at": "ISO 8601 timestamp or null",
  "repair_plan_path": "Path to repair plan or null"
}
```

**Sample Production Log Entry**:
```json
{
  "timestamp": "2025-11-21T06:04:06Z",
  "environment": "production",
  "command": "/build",
  "workflow_id": "build_1763704851",
  "user_args": ".claude/specs/868_directory_has_become_bloated/plans/001_directory_has_become_bloated_plan.md",
  "error_type": "execution_error",
  "error_message": "Bash error at line 398: exit code 127",
  "source": "bash_trap",
  "stack": ["398 _log_bash_error /home/benjamin/.config/.claude/lib/core/error-handling.sh"],
  "context": {
    "line": 398,
    "exit_code": 127,
    "command": "save_completed_states_to_state"
  },
  "status": "RESOLVED",
  "status_updated_at": "2025-11-29T21:31:59Z",
  "repair_plan_path": null
}
```

**Log Rotation Mechanism**:
- Threshold: 10MB file size
- Retention: 5 backup files (errors.jsonl.1 through errors.jsonl.5)
- Automatic: rotate_error_log() called before each log_command_error()
- Oldest backup (.5) deleted on next rotation

**Query Performance**:
- Recent errors (tail + jq): <50ms
- Filtered queries (jq): <100ms for 50 results
- Full aggregation (error_summary): <200ms

**Benefits**:
1. **Centralized**: Single source of truth for all production errors
2. **Structured**: JSONL enables programmatic queries and analysis
3. **Context-rich**: Full workflow context (command, workflow ID, args, stack)
4. **Test-isolated**: Separate test log prevents production pollution
5. **Queryable**: Fast filtering by command, type, time, workflow ID, status
6. **Repairable**: Status tracking integrates with /repair workflow

**Common Query Patterns**:
```bash
# Recent errors for specific command
query_errors --command /implement --limit 10

# Errors in time window
query_errors --since "2025-12-10T00:00:00Z"

# Specific error type pattern
query_errors --type state_error

# Workflow-specific debugging
query_errors --workflow-id "build_1763704851"

# Unresolved errors only
query_errors --status ERROR

# Test errors (separate log)
query_errors --log-file .claude/tests/logs/test-errors.jsonl
```

**Integration Points**:
- `/errors` command: Primary query interface
- `/repair` command: Error pattern analysis and fix plan generation
- State machine: handle_state_error() logs state transition failures
- Hierarchical agents: parse_subagent_error() logs agent failures
- Bash error trap: setup_bash_error_trap() logs execution errors

## Recommendations

### 1. State Persistence Best Practices

**Recommendation**: Use selective state persistence for critical items only
- **Apply file-based persistence for**: Non-deterministic state, cross-subprocess accumulation, >30ms recalculation cost
- **Use stateless recalculation for**: Deterministic values, <10ms recalculation cost
- **Rationale**: Reduces I/O overhead while maintaining 100% state consistency

**Recommendation**: Always use CLAUDE_PROJECT_DIR for state file paths
- **Pattern**: `STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"`
- **Anti-pattern**: Using `${HOME}` causes PATH MISMATCH errors when HOME != PROJECT_DIR
- **Enforcement**: Use validate_state_file_path() or inline conditional pattern

**Recommendation**: Implement concurrent execution safety via nanosecond-precision WORKFLOW_IDs
- **Pattern**: `WORKFLOW_ID="command_$(date +%s%N)"` + discover_latest_state_file()
- **Anti-pattern**: Shared state ID files cause race conditions
- **Performance**: ~0% collision probability, 5-10ms discovery overhead

### 2. Workflow State Machine Best Practices

**Recommendation**: Initialize state machine with pre-computed classification
- **Pattern**: Invoke workflow-classifier agent BEFORE sm_init()
- **Rationale**: Separation of concerns, consistent classification, testable
- **Anti-pattern**: Internal classification in sm_init() violates single responsibility

**Recommendation**: Use idempotent transitions for safe retry/resume
- **Pattern**: sm_transition("$STATE_RESEARCH", "retry after timeout")
- **Behavior**: Same-state transitions succeed immediately (early-exit)
- **Benefit**: Enables safe retry without "already in state" errors

**Recommendation**: Leverage complexity normalization for legacy score migration
- **Pattern**: normalize_complexity() handles 1-4 and legacy scores (e.g., 78.5)
- **Graceful degradation**: Invalid inputs default to 2 with WARNING
- **Benefit**: Ensures initialization always succeeds, no breaking changes

### 3. Error Logging Best Practices

**Recommendation**: Implement dual trap setup for 100% error coverage
- **Pattern**: Early trap (placeholder values) → Late trap (actual workflow context)
- **Coverage**: Eliminates 50-80 line initialization gaps
- **Enforcement**: Validate trap is active before continuing: `trap -p ERR | grep -q "_log_bash_error" || exit 1`

**Recommendation**: Use environment-based routing for test/production log separation
- **Test mode**: `export CLAUDE_TEST_MODE=1` in test script initialization
- **Automatic detection**: Script path matches `/tests/` pattern
- **Benefit**: Clean test isolation, no production log pollution

**Recommendation**: Suppress ERR trap for expected validation failures
- **Pattern**: `SUPPRESS_ERR_TRAP=1` before return in library validation functions
- **Rationale**: Prevents duplicate execution_error entries for validation_error already logged
- **Impact**: 20-30% reduction in error log noise

**Recommendation**: Parse subagent errors for hierarchical workflows
- **Pattern**: parse_subagent_error() → log_command_error() with subagent attribution
- **Context**: Includes agent name in source field for debugging
- **Benefit**: Complete error chain visibility across agent hierarchy

### 4. Debugging and Maintenance Workflows

**Recommendation**: Use /errors → /repair → /implement workflow for systematic error resolution
- **Step 1**: `/errors --type state_error --limit 10` (identify pattern)
- **Step 2**: `/repair --type state_error --complexity 2` (generate fix plan)
- **Step 3**: `/implement [plan-file]` (execute fixes)
- **Step 4**: `/errors --status RESOLVED` (verify resolution)

**Recommendation**: Leverage error status tracking for lifecycle management
- **States**: ERROR → FIX_PLANNED → RESOLVED
- **Commands**: mark_errors_fix_planned(), mark_errors_resolved_for_plan()
- **Benefit**: Queryable repair progress, avoids duplicate fix plans

**Recommendation**: Use sm_print_status() for state machine debugging
- **Output**: Current state, workflow scope, terminal state, completed states
- **Use case**: Diagnose invalid state transitions, verify state machine integrity
- **Validation**: Combine with sm_validate_state() for comprehensive checks

**Recommendation**: Pre-trap error buffering for early initialization diagnostics
- **Pattern**: _buffer_early_error() → _flush_early_errors() after trap setup
- **Captures**: Errors before error-handling.sh is sourced (library sourcing failures)
- **Benefit**: 100% error capture from script start to exit

### 5. Performance Optimization Recommendations

**Recommendation**: Cache CLAUDE_PROJECT_DIR detection for 70% performance improvement
- **Pattern**: Detect once in init_workflow_state(), read from state file in load_workflow_state()
- **Performance**: 50ms git rev-parse → 15ms file read
- **Cumulative**: Saves ~35ms per workflow (3-5 blocks)

**Recommendation**: Use atomic JSON checkpoints for large metadata structures
- **Pattern**: save_json_checkpoint() with temp file + mv
- **Atomicity**: No partial writes on crash
- **Performance**: 5-10ms vs 50ms+ for bash array serialization

**Recommendation**: Optimize error queries with head_limit parameter
- **Pattern**: query_errors --limit 10 (vs scanning entire log)
- **Performance**: <50ms for tail queries vs <200ms for full scans
- **Trade-off**: Acceptable for most debugging workflows

## References

### Core Libraries
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` - GitHub Actions-style state persistence
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Centralized JSONL error logging
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` - Formal FSM with 8 states

### Documentation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` - Error handling pattern architecture
- `/home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md` - Error handling API reference
- `/home/benjamin/.config/.claude/docs/reference/library-api/persistence.md` - State persistence API reference
- `/home/benjamin/.config/.claude/docs/architecture/workflow-state-machine.md` - State machine architecture

### Error Logs
- `/home/benjamin/.config/.claude/data/logs/errors.jsonl` - Production error log
- `/home/benjamin/.config/.claude/tests/logs/test-errors.jsonl` - Test error log

### Related Standards
- Concurrent Execution Safety Standard - Nanosecond-precision WORKFLOW_IDs
- Idempotent State Transitions Standard - Same-state transition handling
- Error Logging Pattern - Dual trap setup, environment routing
- Hard Barrier Subagent Delegation - Agent error return protocol
