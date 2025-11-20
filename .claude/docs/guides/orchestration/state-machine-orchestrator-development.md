# State Machine Orchestrator Development Guide

## Metadata
- **Date**: 2025-11-08
- **Audience**: Developers creating new orchestration commands
- **Prerequisites**: Familiarity with bash, Claude Code orchestration patterns
- **Difficulty**: Intermediate
- **Estimated Reading Time**: 45 minutes

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start: Your First State-Based Orchestrator](#quick-start-your-first-state-based-orchestrator)
3. [State Machine Fundamentals](#state-machine-fundamentals)
4. [Creating Custom States](#creating-custom-states)
5. [Implementing State Handlers](#implementing-state-handlers)
6. [Using Selective State Persistence](#using-selective-state-persistence)
7. [Integrating Hierarchical Supervisors](#integrating-hierarchical-supervisors)
8. [Error Handling and Recovery](#error-handling-and-recovery)
9. [Testing Your Orchestrator](#testing-your-orchestrator)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)
12. [Examples](#examples)

## Introduction

This guide teaches you how to create new orchestration commands using the state machine architecture. You'll learn how to define states, implement transitions, handle errors, and integrate hierarchical supervisors for scalable multi-agent workflows.

### What You'll Build

By the end of this guide, you'll be able to create orchestrators like:

- **Data Processing Pipeline**: Extract → Transform → Load → Validate
- **CI/CD Orchestrator**: Build → Test → Deploy → Monitor
- **Content Workflow**: Research → Draft → Review → Publish
- **Analysis Pipeline**: Collect → Analyze → Visualize → Report

### When to Use State-Based Orchestration

**Use state-based orchestration when:**
- Workflow has multiple distinct phases (3+ states)
- Conditional transitions exist (test → debug vs test → document)
- Checkpoint resume is required (long-running workflows)
- Multiple orchestrators share similar patterns
- Context reduction through hierarchical supervision needed

**Use simpler approaches when:**
- Workflow is linear with no branches (A → B → C only)
- Single-purpose command with no state coordination
- Workflow completes in <5 minutes (no resume needed)
- State overhead exceeds benefits (<3 phases total)

## Quick Start: Your First State-Based Orchestrator

Let's create a simple orchestrator for a research-and-report workflow.

### Step 1: Create Command File

Create `.claude/commands/research.md`:

```markdown
# Research and Report Workflow

Execute research-and-report workflow with state machine coordination.

**STEP 1: Initialize State Machine**

```bash
# Source libraries
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Initialize workflow state
STATE_FILE=$(init_workflow_state "research_report_$$")

# Initialize state machine
WORKFLOW_DESCRIPTION="$1"  # User's workflow description
sm_init "$WORKFLOW_DESCRIPTION" "research-report"

# Detect workflow scope
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Configure terminal state based on scope
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"
    ;;
  *)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
esac

# Save initial state
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"

echo "Workflow initialized: $WORKFLOW_SCOPE"
echo "Terminal state: $TERMINAL_STATE"
```

**STEP 2: Execute Research Phase**

```bash
# Load workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "research_report_$$"

# Execute research phase
if [ "$CURRENT_STATE" == "initialize" ] || [ "$CURRENT_STATE" == "research" ]; then
  echo "=== Research Phase ==="

  # Invoke research agent (behavioral injection pattern)
  # **EXECUTE NOW**: USE the Task tool to invoke research-specialist agent

  # Transition to next state
  if [ "$WORKFLOW_SCOPE" == "research-only" ]; then
    sm_transition "complete"
  else
    sm_transition "report"
  fi
fi
```

**STEP 3: Execute Report Phase**

```bash
# Load workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "research_report_$$"

# Execute report phase
if [ "$CURRENT_STATE" == "report" ]; then
  echo "=== Report Phase ==="

  # Generate report from research findings
  # **EXECUTE NOW**: USE the Task tool to invoke report-generator agent

  # Transition to complete
  sm_transition "complete"
fi
```

**STEP 4: Completion**

```bash
# Load workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "research_report_$$"

if [ "$CURRENT_STATE" == "complete" ]; then
  echo "=== Workflow Complete ==="
  echo "Research and report workflow finished successfully"

  # Cleanup state file
  rm -f "$STATE_FILE"
fi
```
```

### Step 2: Define State Machine

In `workflow-state-machine.sh`, add custom states:

```bash
# Custom states for research-report workflow
STATE_RESEARCH="research"
STATE_REPORT="report"
STATE_COMPLETE="complete"

# Custom transition table
declare -A RESEARCH_REPORT_TRANSITIONS=(
  [initialize]="research"
  [research]="report,complete"
  [report]="complete"
  [complete]=""
)
```

### Step 3: Test Your Orchestrator

Create `.claude/tests/test_research_report.sh`:

```bash
#!/usr/bin/env bash

# Test 1: State initialization
sm_init "Research authentication patterns" "research-report"
[ "$CURRENT_STATE" == "initialize" ] && echo "✓ State initialized"

# Test 2: Research-only scope
sm_init "Research authentication patterns" "research-report"
[ "$TERMINAL_STATE" == "research" ] && echo "✓ Research-only scope detected"

# Test 3: Full workflow scope
sm_init "Research and report on authentication" "research-report"
[ "$TERMINAL_STATE" == "complete" ] && echo "✓ Full workflow scope detected"

# Test 4: State transitions
sm_transition "research" && echo "✓ Transition to research"
sm_transition "report" && echo "✓ Transition to report"
sm_transition "complete" && echo "✓ Transition to complete"
```

### Step 4: Run Your Orchestrator

```bash
# Research-only workflow
/research "Research authentication patterns"

# Full workflow
/research "Research and report on authentication"
```

Congratulations! You've created your first state-based orchestrator.

## State Machine Fundamentals

### State Definition

States represent discrete phases in your workflow lifecycle.

**Good State Names** (explicit, self-documenting):
```bash
STATE_INITIALIZE="initialize"
STATE_ANALYZE="analyze"
STATE_PROCESS="process"
STATE_VALIDATE="validate"
STATE_COMPLETE="complete"
```

**Bad State Names** (vague, unclear):
```bash
STATE_INIT="init"       # Too abbreviated
STATE_STEP1="step1"     # What does step1 do?
STATE_DO_STUFF="stuff"  # Not descriptive
```

**Naming Conventions**:
- Use present tense verbs: "analyze" not "analyzing" or "analyzed"
- Be specific: "validate_schema" not "check"
- Avoid numbers: "research" not "phase1"
- Keep consistent: All STATE_* constants

### Transition Table

The transition table defines **all valid state changes**.

**Example: Data Processing Pipeline**
```bash
declare -A DATA_PIPELINE_TRANSITIONS=(
  [initialize]="extract"
  [extract]="transform,complete"      # Can skip to complete if extraction-only
  [transform]="load,complete"         # Can skip to complete if transform-only
  [load]="validate"
  [validate]="report,retry_load"      # Conditional: retry if validation fails
  [retry_load]="validate,complete"    # Retry or give up
  [report]="complete"
  [complete]=""
)
```

**Transition Validation**:
- Each state must have entry in transition table
- Terminal states have empty transition list ("")
- Multiple transitions separated by commas
- Invalid transitions rejected at runtime

### State Lifecycle

**State Operations**:

1. **Initialize** (`sm_init`): Create initial state machine
2. **Transition** (`sm_transition`): Move to next state with validation
3. **Execute** (`sm_execute`): Run current state handler
4. **Query** (`sm_current_state`): Get current state
5. **Check** (`sm_is_complete`): Test if workflow complete

**Lifecycle Flow**:
```
sm_init("workflow description", "command_name")
    ↓
CURRENT_STATE = "initialize"
    ↓
sm_execute() → execute_initialize_phase()
    ↓
sm_transition("next_state")
    ↓
[validate transition allowed]
    ↓
[save checkpoint]
    ↓
CURRENT_STATE = "next_state"
    ↓
sm_execute() → execute_next_state_phase()
    ↓
... repeat until CURRENT_STATE == TERMINAL_STATE
    ↓
sm_is_complete() → true
```

## Creating Custom States

### Step 1: Define State Constants

Add your custom states to `workflow-state-machine.sh` or define them in your command:

```bash
# Custom states for CI/CD pipeline
STATE_INITIALIZE="initialize"
STATE_BUILD="build"
STATE_TEST="test"
STATE_DEPLOY="deploy"
STATE_MONITOR="monitor"
STATE_COMPLETE="complete"
```

### Step 2: Create Transition Table

Define valid transitions between states:

```bash
declare -A CICD_PIPELINE_TRANSITIONS=(
  [initialize]="build"
  [build]="test,complete"           # Can skip to complete if build-only
  [test]="deploy,debug"             # Conditional: deploy if pass, debug if fail
  [debug]="test,complete"           # Retry test or give up
  [deploy]="monitor,complete"       # Conditional: monitor if enabled
  [monitor]="complete"
  [complete]=""
)
```

### Step 3: Register Transition Table

Make the transition table available to the state machine:

```bash
# In sm_init function
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Select transition table based on command
  case "$command_name" in
    cicd-pipeline)
      STATE_TRANSITIONS=("${CICD_PIPELINE_TRANSITIONS[@]}")
      ;;
    research-report)
      STATE_TRANSITIONS=("${RESEARCH_REPORT_TRANSITIONS[@]}")
      ;;
    *)
      # Default workflow transitions
      STATE_TRANSITIONS=("${DEFAULT_TRANSITIONS[@]}")
      ;;
  esac

  # Initialize current state
  CURRENT_STATE="$STATE_INITIALIZE"

  # Save state machine checkpoint
  save_state_machine_checkpoint
}
```

### Step 4: Implement State Handlers

Create handler function for each state:

```bash
execute_build_phase() {
  echo "=== Build Phase ==="

  # Pre-execution setup
  BUILD_START=$(date +%s)

  # Execute build logic
  run_build_commands

  # Post-execution transition
  BUILD_END=$(date +%s)
  BUILD_DURATION=$((BUILD_END - BUILD_START))

  if [ "$WORKFLOW_SCOPE" == "build-only" ]; then
    sm_transition "complete"
  else
    sm_transition "test"
  fi
}

execute_test_phase() {
  echo "=== Test Phase ==="

  # Run tests
  run_test_suite

  # Conditional transition based on results
  if [ "$TESTS_PASSED" == "true" ]; then
    sm_transition "deploy"
  else
    sm_transition "debug"
  fi
}

execute_deploy_phase() {
  echo "=== Deploy Phase ==="

  # Deploy to target environment
  deploy_to_environment "$TARGET_ENV"

  # Conditional transition based on monitoring config
  if [ "$ENABLE_MONITORING" == "true" ]; then
    sm_transition "monitor"
  else
    sm_transition "complete"
  fi
}
```

### Step 5: Register State Handlers

Add handlers to `sm_execute` dispatcher:

```bash
sm_execute() {
  local state="$CURRENT_STATE"

  # Delegate to state-specific handler
  case "$state" in
    initialize)  execute_initialize_phase ;;
    build)       execute_build_phase ;;
    test)        execute_test_phase ;;
    deploy)      execute_deploy_phase ;;
    monitor)     execute_monitor_phase ;;
    complete)    execute_complete_phase ;;
    *)
      echo "ERROR: Unknown state: $state" >&2
      return 1
      ;;
  esac
}
```

## Implementing State Handlers

### State Handler Pattern

Every state handler follows this pattern:

```bash
execute_<state>_phase() {
  # 1. Pre-execution setup
  echo "=== <State> Phase ==="
  PHASE_START=$(date +%s)

  # 2. Load required state
  load_workflow_state "$WORKFLOW_ID"

  # 3. Execute phase logic
  # ... state-specific implementation

  # 4. Save phase results
  append_workflow_state "PHASE_RESULT" "$RESULT"

  # 5. Post-execution transition
  PHASE_END=$(date +%s)
  PHASE_DURATION=$((PHASE_END - PHASE_START))

  # 6. Determine next state (conditional logic)
  if [ "$CONDITION" == "true" ]; then
    sm_transition "success_state"
  else
    sm_transition "failure_state"
  fi
}
```

### Example: Analysis State Handler

```bash
execute_analyze_phase() {
  # 1. Pre-execution setup
  echo "=== Analysis Phase ==="
  ANALYZE_START=$(date +%s)

  # 2. Load workflow state
  load_workflow_state "data_pipeline_$$"

  # 3. Execute analysis logic
  echo "Analyzing data from $DATA_SOURCE..."

  # Invoke analysis agent via Task tool
  # **EXECUTE NOW**: USE the Task tool to invoke data-analyzer agent

  # Parse results
  ANALYSIS_RESULT=$(cat "/path/to/analysis_result.json")
  COMPLEXITY_SCORE=$(echo "$ANALYSIS_RESULT" | jq -r '.complexity_score')

  # 4. Save phase results
  append_workflow_state "ANALYSIS_RESULT" "$ANALYSIS_RESULT"
  append_workflow_state "COMPLEXITY_SCORE" "$COMPLEXITY_SCORE"

  # 5. Post-execution metrics
  ANALYZE_END=$(date +%s)
  ANALYZE_DURATION=$((ANALYZE_END - ANALYZE_START))
  echo "Analysis completed in ${ANALYZE_DURATION}s"

  # 6. Conditional transition based on complexity
  if [ "$COMPLEXITY_SCORE" -gt 8 ]; then
    echo "High complexity detected, invoking advanced processing"
    sm_transition "advanced_process"
  elif [ "$WORKFLOW_SCOPE" == "analyze-only" ]; then
    sm_transition "complete"
  else
    sm_transition "process"
  fi
}
```

### State Handler Best Practices

1. **Always echo phase name**: Helps debugging and user visibility
2. **Load workflow state first**: Ensure all variables available
3. **Save results to state file**: Enable access in later phases
4. **Conditional transitions**: Use workflow scope and phase results
5. **Error handling**: Wrap critical operations in error checks
6. **Metrics tracking**: Record phase duration, token usage, etc.

### Error Handling in State Handlers

```bash
execute_process_phase() {
  echo "=== Process Phase ==="

  # Error tracking
  ERROR_COUNT=0
  MAX_RETRIES=3

  # Load workflow state
  load_workflow_state "workflow_$$" || {
    echo "ERROR: Failed to load workflow state" >&2
    sm_transition "error"
    return 1
  }

  # Execute processing with retry logic
  for attempt in $(seq 1 $MAX_RETRIES); do
    echo "Processing attempt $attempt/$MAX_RETRIES..."

    if process_data "$INPUT_FILE"; then
      echo "Processing succeeded"
      append_workflow_state "PROCESS_RESULT" "success"
      sm_transition "validate"
      return 0
    else
      echo "Processing failed (attempt $attempt)" >&2
      ((ERROR_COUNT++))
      sleep 2  # Backoff before retry
    fi
  done

  # All retries failed
  echo "ERROR: Processing failed after $MAX_RETRIES attempts" >&2
  append_workflow_state "PROCESS_RESULT" "failure"
  append_workflow_state "ERROR_COUNT" "$ERROR_COUNT"
  sm_transition "error"
  return 1
}
```

## Using Selective State Persistence

### Decision Criteria

Use the decision matrix to determine file-based vs stateless:

```bash
# Decision flowchart
is_expensive_to_recalculate() {
  local operation="$1"
  local time_ms=$(measure_operation_time "$operation")

  if [ "$time_ms" -gt 30 ]; then
    echo "file-based"  # >30ms = expensive
  else
    echo "stateless"   # <30ms = cheap
  fi
}

is_non_deterministic() {
  local operation="$1"

  case "$operation" in
    user_survey|research_findings|timestamp)
      echo "file-based"  # Non-deterministic
      ;;
    scope_detection|phase_mapping)
      echo "stateless"   # Deterministic
      ;;
  esac
}

select_state_pattern() {
  local operation="$1"

  # Apply decision criteria
  local expense=$(is_expensive_to_recalculate "$operation")
  local determinism=$(is_non_deterministic "$operation")

  if [ "$expense" == "file-based" ] || [ "$determinism" == "file-based" ]; then
    echo "file-based"
  else
    echo "stateless"
  fi
}
```

### File-Based State Example

**Use Case**: Expensive git operations cached across blocks

```bash
# Block 1: Initialize and cache
STATE_FILE=$(init_workflow_state "workflow_$$")

# Expensive operation (6ms)
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
REPOSITORY_HASH="$(git rev-parse HEAD)"
BRANCH_NAME="$(git branch --show-current)"

# Cache in state file
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "REPOSITORY_HASH" "$REPOSITORY_HASH"
append_workflow_state "BRANCH_NAME" "$BRANCH_NAME"

# Block 2+: Load cached values (2ms vs 6ms)
load_workflow_state "workflow_$$"

# Use cached values
echo "Project: $CLAUDE_PROJECT_DIR"
echo "Commit: $REPOSITORY_HASH"
echo "Branch: $BRANCH_NAME"

# 4ms saved per block × 5 blocks = 20ms total savings
```

### Stateless Recalculation Example

**Use Case**: Fast deterministic calculations

```bash
# Every block recalculates (fast, simple)

# Detect workflow scope (<1ms)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Map scope to phases (<0.1ms)
case "$WORKFLOW_SCOPE" in
  research-only)      PHASES="0,1" ;;
  research-and-plan)  PHASES="0,1,2" ;;
  full)               PHASES="0,1,2,3,4,5,6,7" ;;
esac

# Total recalculation overhead: ~1ms (negligible)
```

### Hybrid Approach Example

**Use Case**: Mix file-based and stateless based on operation cost

```bash
# Block 1: Initialize
STATE_FILE=$(init_workflow_state "workflow_$$")

# Expensive operations → file-based
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"  # 6ms
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"

SUPERVISOR_METADATA=$(extract_supervisor_metadata)  # 50ms
append_workflow_state "SUPERVISOR_METADATA" "$SUPERVISOR_METADATA"

# Cheap operations → stateless (recalculate every block)
# WORKFLOW_SCOPE - not saved (recalculated <1ms)
# PHASES_TO_EXECUTE - not saved (recalculated <0.1ms)

# Block 2+: Load expensive, recalculate cheap
load_workflow_state "workflow_$$"

# Expensive values loaded from state file
echo "Project: $CLAUDE_PROJECT_DIR"  # Loaded
echo "Supervisor: $SUPERVISOR_METADATA"  # Loaded

# Cheap values recalculated
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")  # <1ms
PHASES_TO_EXECUTE=$(map_scope_to_phases "$WORKFLOW_SCOPE")  # <0.1ms
```

## Integrating Hierarchical Supervisors

### When to Use Hierarchical Supervision

**Use hierarchical supervision when:**
- 4+ parallel workers needed
- Worker outputs are large (>1,000 tokens each)
- Context reduction critical (avoid overflow)
- Metadata aggregation provides value (95% reduction)

**Example Calculation**:
```
4 Workers × 2,500 tokens/worker = 10,000 tokens (exceeds practical limit)
Supervisor aggregates → 440 tokens (95.6% reduction)
Orchestrator context usage: Manageable
```

### Supervisor Integration Pattern

**Step 1: Conditional invocation check**

```bash
execute_research_phase() {
  # Count research topics
  TOPIC_COUNT=$(echo "$RESEARCH_TOPICS" | tr ',' '\n' | wc -l)

  # Decide: hierarchical vs flat coordination
  if [ "$TOPIC_COUNT" -ge 4 ]; then
    # Use hierarchical supervisor (95% context reduction)
    invoke_research_supervisor
  else
    # Use flat coordination (invoke workers directly)
    invoke_research_workers_directly
  fi
}
```

**Step 2: Supervisor invocation**

```bash
invoke_research_supervisor() {
  echo "Invoking research supervisor for $TOPIC_COUNT topics..."

  # **EXECUTE NOW**: USE the Task tool to invoke research-sub-supervisor

  # Supervisor behavioral file:
  # /path/to/.claude/agents/research-sub-supervisor.md
  #
  # Supervisor will:
  # 1. Coordinate 4 research-specialist workers in parallel
  # 2. Extract metadata from each worker output
  # 3. Aggregate into single summary
  # 4. Return aggregated metadata to orchestrator

  # Wait for supervisor completion signal
  # Expected: SUPERVISOR_COMPLETE: {metadata_json}
}
```

**Step 3: Load supervisor metadata**

```bash
# After supervisor completes
SUPERVISOR_METADATA=$(load_json_checkpoint "supervisor_metadata")

# Extract aggregated fields
TOPICS_RESEARCHED=$(echo "$SUPERVISOR_METADATA" | jq -r '.topics_researched')
REPORTS_CREATED=$(echo "$SUPERVISOR_METADATA" | jq -r '.reports_created[]')
SUMMARY=$(echo "$SUPERVISOR_METADATA" | jq -r '.summary')
KEY_FINDINGS=$(echo "$SUPERVISOR_METADATA" | jq -r '.key_findings[]')

# Use metadata (440 tokens vs 10,000 tokens full output)
echo "Researched $TOPICS_RESEARCHED topics"
echo "Summary: $SUMMARY"

# Save to workflow state
append_workflow_state "RESEARCH_SUMMARY" "$SUMMARY"
append_workflow_state "REPORTS_CREATED" "$REPORTS_CREATED"
```

### Creating Custom Supervisors

**Step 1: Copy supervisor template**

```bash
cp .claude/agents/templates/sub-supervisor-template.md \
   .claude/agents/my-custom-supervisor.md
```

**Step 2: Customize supervisor metadata**

```markdown
# My Custom Supervisor

## Metadata
- **Supervisor Name**: my-custom-supervisor
- **Worker Type**: custom-worker
- **Worker Count**: 4
- **Coordination Pattern**: Parallel
- **Context Reduction**: 95%+
```

**Step 3: Implement worker invocation**

```markdown
**STEP 3: Invoke Workers in Parallel**

USE the Task tool to invoke 4 custom-worker agents simultaneously:

**Worker 1 - Task A**:
Task {
  subagent_type: "general-purpose"
  description: "Execute task A"
  prompt: |
    Read and follow behavioral guidelines from:
    /path/to/.claude/agents/custom-worker.md

    Execute: Task A
    Output: /path/to/output_a.json

    Return: TASK_COMPLETE: /path/to/output_a.json
}

**Workers 2-4**: Similar pattern for tasks B, C, D
```

**Step 4: Implement metadata aggregation**

```markdown
**STEP 4: Aggregate Worker Metadata**

After all workers complete:

1. Extract metadata from each worker output
2. Aggregate into supervisor summary
3. Save to checkpoint
4. Return aggregated metadata ONLY (not full outputs)

```bash
# Extract metadata from each worker
WORKER_1_METADATA=$(jq -r '.metadata' /path/to/output_a.json)
WORKER_2_METADATA=$(jq -r '.metadata' /path/to/output_b.json)
WORKER_3_METADATA=$(jq -r '.metadata' /path/to/output_c.json)
WORKER_4_METADATA=$(jq -r '.metadata' /path/to/output_d.json)

# Aggregate
AGGREGATED=$(jq -n \
  --argjson w1 "$WORKER_1_METADATA" \
  --argjson w2 "$WORKER_2_METADATA" \
  --argjson w3 "$WORKER_3_METADATA" \
  --argjson w4 "$WORKER_4_METADATA" \
  '{
    tasks_completed: 4,
    outputs: [$w1, $w2, $w3, $w4],
    summary: "All 4 tasks completed successfully",
    combined_metrics: ...
  }')

# Save to checkpoint
save_json_checkpoint "supervisor_metadata" "$AGGREGATED"
```
```

## Error Handling and Recovery

### Error State Tracking

Use checkpoint error state for consistent error handling:

```bash
handle_state_error() {
  local error_message="$1"
  local failed_state="$CURRENT_STATE"

  # Load error state from checkpoint
  ERROR_STATE=$(load_json_checkpoint "error_state")
  RETRY_COUNT=$(echo "$ERROR_STATE" | jq -r '.retry_count // 0')

  # Increment retry count
  ((RETRY_COUNT++))

  # Update error state
  ERROR_STATE=$(jq -n \
    --arg error "$error_message" \
    --arg failed_state "$failed_state" \
    --arg retry_count "$RETRY_COUNT" \
    '{
      last_error: $error,
      failed_state: $failed_state,
      retry_count: ($retry_count | tonumber)
    }')

  save_json_checkpoint "error_state" "$ERROR_STATE"

  # Decide: retry or escalate
  if [ "$RETRY_COUNT" -lt 3 ]; then
    echo "Retrying $failed_state (attempt $((RETRY_COUNT + 1)))"
    return 0  # Retry
  else
    echo "ERROR: Max retries exceeded for $failed_state" >&2
    return 1  # Escalate
  fi
}
```

### Retry Logic Pattern

```bash
execute_flaky_phase() {
  MAX_RETRIES=3

  for attempt in $(seq 1 $MAX_RETRIES); do
    echo "Executing phase (attempt $attempt/$MAX_RETRIES)..."

    if execute_phase_logic; then
      # Success
      echo "Phase succeeded"
      sm_transition "next_state"
      return 0
    else
      # Failure
      if [ "$attempt" -lt "$MAX_RETRIES" ]; then
        echo "Retrying after backoff..."
        sleep $((attempt * 2))  # Exponential backoff
      fi
    fi
  done

  # All retries failed
  handle_state_error "Phase failed after $MAX_RETRIES attempts"
  sm_transition "error"
  return 1
}
```

### Checkpoint Resume

Enable resume from interrupted workflows:

```bash
# Check for existing checkpoint
CHECKPOINT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_checkpoint.json"

if [ -f "$CHECKPOINT_FILE" ]; then
  echo "Found existing checkpoint, resuming..."

  # Load checkpoint
  CHECKPOINT=$(cat "$CHECKPOINT_FILE")
  CURRENT_STATE=$(echo "$CHECKPOINT" | jq -r '.state_machine.current_state')

  echo "Resuming from state: $CURRENT_STATE"

  # Continue execution from current state
  sm_execute
else
  echo "No checkpoint found, starting fresh..."

  # Initialize new workflow
  sm_init "$WORKFLOW_DESCRIPTION" "orchestrator"
fi
```

## Testing Your Orchestrator

### Test Structure

Create comprehensive test suite:

```bash
#!/usr/bin/env bash
# test_my_orchestrator.sh

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/workflow/workflow-state-machine.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

# Test 1: State initialization
test_state_initialization() {
  ((TESTS_RUN++))

  sm_init "Test workflow" "my-orchestrator"

  if [ "$CURRENT_STATE" == "initialize" ]; then
    echo "✓ State initialized correctly"
    ((TESTS_PASSED++))
  else
    echo "✗ State initialization failed"
  fi
}

# Test 2: State transitions
test_state_transitions() {
  ((TESTS_RUN++))

  sm_init "Test workflow" "my-orchestrator"
  sm_transition "analyze"

  if [ "$CURRENT_STATE" == "analyze" ]; then
    echo "✓ State transition successful"
    ((TESTS_PASSED++))
  else
    echo "✗ State transition failed"
  fi
}

# Test 3: Invalid transition rejection
test_invalid_transition() {
  ((TESTS_RUN++))

  sm_init "Test workflow" "my-orchestrator"

  if ! sm_transition "complete"; then
    echo "✓ Invalid transition rejected"
    ((TESTS_PASSED++))
  else
    echo "✗ Invalid transition allowed"
  fi
}

# Run tests
test_state_initialization
test_state_transitions
test_invalid_transition

# Summary
echo ""
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"

[ "$TESTS_PASSED" -eq "$TESTS_RUN" ] && exit 0 || exit 1
```

### Integration Testing

Test complete workflow execution:

```bash
test_full_workflow() {
  # Initialize workflow
  sm_init "Full workflow test" "my-orchestrator"

  # Execute all phases
  sm_execute  # initialize
  sm_transition "analyze"

  sm_execute  # analyze
  sm_transition "process"

  sm_execute  # process
  sm_transition "complete"

  # Verify completion
  if [ "$CURRENT_STATE" == "complete" ]; then
    echo "✓ Full workflow completed"
  else
    echo "✗ Workflow incomplete: $CURRENT_STATE"
  fi
}
```

## Best Practices

### 1. State Naming

**Good**:
```bash
STATE_EXTRACT="extract"
STATE_TRANSFORM="transform"
STATE_LOAD="load"
STATE_VALIDATE="validate"
```

**Bad**:
```bash
STATE_STEP1="step1"    # Not descriptive
STATE_PROC="proc"      # Too abbreviated
STATE_DO="do"          # Too vague
```

### 2. Transition Validation

Always define transitions explicitly:

```bash
# Good: Explicit transitions
declare -A MY_TRANSITIONS=(
  [initialize]="extract"
  [extract]="transform,complete"
  [transform]="load"
  [load]="validate"
  [validate]="complete"
  [complete]=""
)

# Bad: Missing transitions (runtime errors)
declare -A MY_TRANSITIONS=(
  [initialize]="extract"
  # Missing other states!
)
```

### 3. Error Handling

Wrap critical operations:

```bash
# Good: Error handling
execute_critical_phase() {
  if ! critical_operation; then
    handle_state_error "Critical operation failed"
    sm_transition "error"
    return 1
  fi

  sm_transition "next_state"
}

# Bad: No error handling
execute_critical_phase() {
  critical_operation  # What if this fails?
  sm_transition "next_state"
}
```

### 4. State Persistence

Use decision criteria systematically:

```bash
# Good: Selective persistence
# Expensive operation → file-based
EXPENSIVE_RESULT=$(run_expensive_analysis)  # 100ms
append_workflow_state "EXPENSIVE_RESULT" "$EXPENSIVE_RESULT"

# Cheap operation → stateless recalculation
WORKFLOW_SCOPE=$(detect_scope "$DESCRIPTION")  # <1ms
# Not saved, recalculated every block

# Bad: Blanket file-based for everything
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"  # Unnecessary overhead
```

### 5. Documentation

Document state purpose and transitions:

```bash
# Good: Documented states
# STATE_ANALYZE: Analyze input data for patterns and anomalies
# Transitions: analyze → process (if valid), analyze → error (if invalid)
execute_analyze_phase() {
  # ...
}

# Bad: Undocumented
execute_analyze_phase() {
  # What does this do? When does it transition?
}
```

## Troubleshooting

### Common Issues

**Issue 1: "Invalid transition" error**

```
ERROR: Invalid transition: initialize → process
Valid transitions from initialize: analyze
```

**Cause**: Skipping required intermediate states

**Solution**: Transition through valid states
```bash
# Wrong
sm_transition "process"

# Right
sm_transition "analyze"
# ... execute analyze phase
sm_transition "process"
```

**Issue 2: State file not found**

```
Warning: State file not found, recalculating...
```

**Cause**: load_workflow_state called before init_workflow_state

**Solution**: Initialize in first block
```bash
# Block 1
STATE_FILE=$(init_workflow_state "workflow_$$")

# Block 2+
load_workflow_state "workflow_$$"
```

**Issue 3: Context overflow despite supervisor**

```
ERROR: Context limit exceeded
```

**Cause**: Loading full worker outputs instead of metadata

**Solution**: Use metadata-only pattern
```bash
# Wrong
WORKER_OUTPUT=$(cat /path/to/output.md)  # Full content

# Right
WORKER_METADATA=$(extract_metadata /path/to/output.md)  # Summary only
```

## Examples

### Example 1: CI/CD Pipeline

Complete CI/CD orchestrator with build, test, deploy phases:

See `.claude/examples/cicd-pipeline.md` for full implementation.

### Example 2: Data Processing Workflow

ETL pipeline with extract, transform, load, validate phases:

See `.claude/examples/data-pipeline.md` for full implementation.

### Example 3: Content Publishing Workflow

Research → Draft → Review → Publish workflow:

See `.claude/examples/content-workflow.md` for full implementation.

## Related Documentation

- [State-Based Orchestration Overview](../architecture/state-based-orchestration-overview.md) - Complete architecture reference
- [State Machine Migration Guide](./state-machine-migration-guide.md) - Migrating existing orchestrators
- [Hierarchical Supervisor Guide](./hierarchical-supervisor-guide.md) - Advanced supervisor patterns
- [Workflow State Machine](../architecture/workflow-state-machine.md) - State machine library reference

---

**Guide Version**: 1.0
**Last Updated**: 2025-11-08
**Next Review**: After Phase 7 completion
