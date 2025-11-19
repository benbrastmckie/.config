# /coordinate Command - Troubleshooting

**Part 3 of 3** | [Index](coordinate-command-index.md)

This document covers state transitions, performance optimization, and common issues.

---

```

---

#### Issue 2b: Revision Workflow Fails with "EXISTING_PLAN_PATH not set"

**Symptoms**:
- Error: "ERROR: research-and-revise workflow requires existing plan path"
- Error: "Workflow description: [your description]"
- Error: "Check workflow description contains full plan path"

**Root Cause**:
Workflow description doesn't contain a recognizable plan path for scope detection to extract.

**Solution**:
Include the complete plan path in your workflow description:
```bash
# ✓ CORRECT - Full absolute path
/coordinate "Revise the plan /home/user/.claude/specs/657_topic/plans/001_plan.md to add caching"

# ✗ WRONG - No path
/coordinate "Revise the implementation plan to add caching"

# ✗ WRONG - Relative path without context
/coordinate "Revise plans/001_plan.md to add caching"
```

**Verification**:
Test if scope detection can extract the path:
```bash
source .claude/lib/workflow-scope-detection.sh
WORKFLOW_DESCRIPTION="Revise the plan /path/to/specs/657_topic/plans/001_plan.md"
detect_workflow_scope "$WORKFLOW_DESCRIPTION"
# Should output: research-and-revise
echo $EXISTING_PLAN_PATH
# Should output: /path/to/specs/657_topic/plans/001_plan.md
```

---

#### Issue 2c: Revision Workflow Fails with "Plan file does not exist"

**Symptoms**:
- Error: "ERROR: Specified plan file does not exist"
- Error: "Plan path: /path/to/plan.md"
- Error: "Verify file path is correct: test -f ..."

**Root Cause**:
The path provided in workflow description points to a non-existent file.

**Solution**:
```bash
# Verify the plan file exists
ls -la /home/user/.claude/specs/657_topic/plans/001_plan.md

# Check for typos in path
# Common issues:
#   - Wrong topic number (657 vs 658)
#   - Wrong plan number (001 vs 002)
#   - .md extension missing or wrong

# List available plans
ls -la .claude/specs/*/plans/*.md

# Copy exact path to avoid typos
realpath .claude/specs/657_topic/plans/001_plan.md
# Then paste into workflow description
```

---

#### Issue 2d: Revision Workflow Fails with "Topic directory does not exist"

**Symptoms**:
- Error: "ERROR: Extracted topic directory does not exist"
- Error: "Topic directory: /path/to/specs/NNN_topic"
- Error: "Extracted from: /path/to/plan.md"

**Root Cause**:
Plan path format is malformed or topic directory was deleted.

**Solution**:
```bash
# Verify topic directory exists
ls -la .claude/specs/657_topic/

# Check path format matches expected structure
# Expected: /path/to/specs/NNN_topic/plans/NNN_plan.md
#                         └────────┘ └───┘
#                         topic dir   plans subdir

# If topic directory doesn't exist, this may not be a revision workflow
# Create a new plan instead:
/coordinate "research topic and create new plan"
```

---

#### Issue 2e: EXISTING_PLAN_PATH Not Persisting Across Bash Blocks

**Symptom**: Error "EXISTING_PLAN_PATH not restored from workflow state" during planning phase

**Root Cause**: Subprocess isolation - `export` in library function doesn't persist to parent bash block

**Technical Details**:
- Each bash block in coordinate.md runs as separate subprocess
- `export EXISTING_PLAN_PATH` in workflow-scope-detection.sh creates subprocess variable
- Variable lost when subprocess exits (before next bash block executes)
- **Solution**: Save to workflow state file immediately after extraction

**How It Was Fixed (Spec 665)**:

In coordinate.md (after sm_init, lines 127-153):
```bash
# ADDED: Extract and save EXISTING_PLAN_PATH for research-and-revise workflows
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Extract plan path from workflow description
  if echo "$SAVED_WORKFLOW_DESC" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
    EXISTING_PLAN_PATH=$(echo "$SAVED_WORKFLOW_DESC" | grep -oE "/[^ ]+\.md" | head -1)
    export EXISTING_PLAN_PATH

    # CRITICAL: Verify file exists before proceeding
    if [ ! -f "$EXISTING_PLAN_PATH" ]; then
      handle_state_error "Extracted plan path does not exist: $EXISTING_PLAN_PATH" 1
    fi

    echo "✓ Extracted existing plan path: $EXISTING_PLAN_PATH"
  else
    handle_state_error "research-and-revise workflow requires plan path in description" 1
  fi
fi

# ADDED: Save EXISTING_PLAN_PATH to state for bash block persistence
if [ -n "${EXISTING_PLAN_PATH:-}" ]; then
  append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"
fi
```

**Verification**:
```bash
# Check workflow state file contains EXISTING_PLAN_PATH
cat "${HOME}/.claude/tmp/workflow_coordinate_*.sh" | grep EXISTING_PLAN_PATH

# Expected: export EXISTING_PLAN_PATH="/absolute/path/to/plan.md"
```

**See Also**:
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md)
- [State Persistence Pattern](.claude/docs/concepts/patterns/state-persistence.md)
- [Spec 665 Implementation Plan](../specs/665_research_the_output_homebenjaminconfigclaudespecs/plans/001_coordinate_fixes_implementation_plan.md)

---

#### Issue 3: JQ Parse Errors (Empty Report Arrays)

**Symptom**: `jq: parse error: Invalid numeric literal at line 1, column...`

**Cause**: Empty or malformed `REPORT_PATHS_JSON` variable when parsing report paths from state

**When It Occurs**:
- Research phase produces no reports (edge case)
- REPORT_PATHS_JSON not initialized
- Malformed JSON from previous phase

**Solution**: Fixed in Spec 652 (coordinate.md lines 605-611, 727-739)

The coordinate command now:
- Explicitly handles empty arrays: `REPORT_PATHS_JSON="[]"`
- Validates JSON before parsing: `jq empty 2>/dev/null`
- Falls back to empty array on malformed JSON
- Logs success: "Loaded N report paths from state"

**Verification**:
```bash
# Test empty array handling
SUCCESSFUL_REPORT_PATHS=()
if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -eq 0 ]; then
  REPORT_PATHS_JSON="[]"
fi
echo "$REPORT_PATHS_JSON" | jq empty && echo "✓ Valid JSON"

# Test malformed JSON recovery
REPORT_PATHS_JSON="invalid json"
if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
  echo "Valid JSON"
else
  echo "✓ Fallback to empty array triggered"
  REPORT_PATHS=()
fi
```

**Related Tests**: `.claude/tests/test_coordinate_error_fixes.sh` - Tests 1, 2, 4

---

#### Issue 4: Missing State File Errors

**Symptom**: `grep: /path/to/state: No such file or directory`

**Cause**: State file accessed before creation or after premature deletion

**When It Occurs**:
- State file not initialized in first bash block
- Workflow ID file missing or corrupted
- Premature EXIT trap cleanup
- File system issues

**Solution**: Fixed in Spec 652 (verification-helpers.sh lines 155-167)

The `verify_state_variables()` function now:
- Checks file existence BEFORE grep operations
- Provides clear diagnostic error messages
- Lists expected file path
- Suggests troubleshooting steps

**Error Message**:
```
✗ ERROR: State file does not exist
   Expected path: /path/to/state/file

TROUBLESHOOTING:
  1. Verify init_workflow_state() was called in first bash block
  2. Check STATE_FILE variable was saved to state correctly
  3. Verify workflow ID file exists and contains valid ID
  4. Ensure no premature cleanup of state files
```

**Verification**:
```bash
# Test missing file detection
STATE_FILE="/tmp/nonexistent.state"
VARS=("VAR1" "VAR2")
if verify_state_variables "$STATE_FILE" "${VARS[@]}" 2>/dev/null; then
  echo "ERROR: Should have failed"
else
  echo "✓ Missing file detected correctly"
fi
```

**Related Tests**: `.claude/tests/test_coordinate_error_fixes.sh` - Test 4

---

#### Issue 5: State Transition Validation Failures

**Symptom**: `ERROR: Expected state 'plan' but current state is 'implement'`

**Cause**: State validation logic out of sync with state machine transitions

**When It Occurs**:
- sm_transition not called before validation
- State not persisted to workflow state
- Subprocess state restoration failure
- State machine transition error

**Solution**: Fixed in Spec 652 (coordinate.md lines 221-224, 660-663, 1002-1005)

The coordinate command now:
- Logs state transitions with timestamps
- Calls `sm_transition()` BEFORE validation
- Persists state immediately after transition
- Provides enhanced error diagnostics

**Transition Logging**:
```bash
Transitioning from research to plan
sm_transition "$STATE_PLAN"
append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
State transition complete: 2025-11-10 14:30:45
```

**Enhanced Error Message**:
```
ERROR: State transition validation failed
  Expected: plan
  Actual: implement

TROUBLESHOOTING:
  1. Verify sm_transition was called in previous bash block
  2. Check workflow state file for CURRENT_STATE value
  3. Verify workflow scope: full-implementation
  4. Review state machine transition logs above
```

**Verification**:
```bash
# Test state transitions
source .claude/lib/workflow-state-machine.sh
sm_init "Test" "coordinate"
sm_transition "$STATE_RESEARCH"
[ "$CURRENT_STATE" = "$STATE_RESEARCH" ] && echo "✓ Transition works"
```

**Related Tests**: `.claude/tests/test_coordinate_error_fixes.sh` - Test 5

---

#### Issue 6: Context Budget Exceeded

**Symptoms**:
- Token limit warnings
- Performance degradation
- Out of memory errors

**Cause**:
- Metadata extraction failed
- Context pruning not applied
- Large artifact files retained in context

**Solution**:
```bash
# Check context pruning library
cat .claude/lib/context-pruning.sh

# Verify metadata extraction
cat .claude/lib/metadata-extraction.sh

# Review artifact sizes
du -sh specs/042_*/reports/*
```

#### Issue 4: Wave Execution Hangs

**Symptoms**:
- Implementation phase stuck
- No progress for extended period
- Partial wave completion

**Cause**:
- Circular dependencies in plan
- Agent failure mid-wave
- Dependency analyzer error

**Solution**:
```bash
# Check plan dependencies for cycles
grep -A 5 "dependencies:" specs/*/plans/*.md

# Verify dependency analyzer
cat .claude/lib/dependency-analyzer.sh

# Check agent logs for failures
cat .claude/data/logs/coordinate-*.log

# Resume from checkpoint
# (automatic on next /coordinate invocation)
```

#### Issue 5: Variables Not Exported from Functions (Subshell Export Bug)

**Symptom**: Variables set by function not available after call

**Error Examples**:
```
ERROR: initialize_workflow_paths() requires WORKFLOW_SCOPE as second argument
WORKFLOW_SCOPE: <not set>
```

**Cause**: Command substitution creates subshell (see [Bash Block Execution Model](../concepts/bash-block-execution-model.md))

**Example**:
```bash
# WRONG - creates subshell:
RESULT=$(my_function)  # Subshell - exports don't propagate

# CORRECT - parent shell:
my_function >/dev/null  # Parent shell - exports available
RESULT="$EXPORTED_VAR"  # Use exported variable
```

**Fixed In**: Spec 683 - coordinate.md line 165 (sm_init call pattern)

**Root Cause Details**:
- Command substitution `$(...)` creates subprocess
- `export` statements in subprocess don't affect parent shell
- Parent shell never sees the exported variables
- Functions must be called directly (not via command substitution) to export to parent

**Solution**:
```bash
# Incorrect pattern (don't use):
COMPLEXITY=$(sm_init "$workflow_desc" "coordinate")

# Correct pattern (use this):
sm_init "$workflow_desc" "coordinate" >/dev/null
# Variables now available: $WORKFLOW_SCOPE, $RESEARCH_COMPLEXITY, $RESEARCH_TOPICS_JSON
```

**See Also**:
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md#subprocess-isolation) - Complete subprocess patterns
- [Spec 683 Bug #1 Fix](../../specs/683_coordinate_critical_bug_fixes/plans/001_coordinate_bug_fixes.md#bug-1-subshell-export-fix-completed) - Complete root cause analysis

#### Issue 6: Verification Mismatch Between Allocated and Invoked Agents

**Symptom**: Research phase fails with verification error showing mismatch between expected and actual report counts

**Error Examples**:
```
Dynamic path discovery complete: 0/2 files discovered
MANDATORY VERIFICATION: Research Phase Artifacts
Checking 2 research reports...

  Report 1/2: ✗ ERROR [Research]: Research report 1/2 verification failed

❌ CRITICAL: Research artifact verification failed
   2 reports not created at expected paths
```

**Yet**:
- 3 research agents were actually invoked (Task 1, 2, 3 all completed)
- 3 report files were created (001, 002, 003 all exist)
- Verification expects 2 but finds 3

**Root Cause**: RESEARCH_COMPLEXITY was calculated correctly by `sm_init()` in Phase 0 (initialize), but then immediately recalculated using hardcoded regex patterns in Phase 1 (research). This created a mismatch between:
- **Allocated paths**: Based on sm_init complexity (e.g., 2)
- **Invoked agents**: Based on recalculated complexity (e.g., 3 due to "integrate" keyword match)
- **Verification loops**: Based on recalculated complexity (checking for 2 or 3, inconsistent)

**Impact**: ~40-50% of workflows containing keywords like "integrate", "migration", "refactor", "architecture" experienced verification failures despite successful research completion.

**Fixed In**: Spec 687 (2025-11-12) - Removed hardcoded recalculation entirely

**Solution Applied**:
1. **Phase 1 (Research Handler)**: Removed lines 419-432 (hardcoded pattern matching), replaced with state load validation and fallback warning
2. **Dynamic Discovery Loop**: Changed from `$RESEARCH_COMPLEXITY` to `$REPORT_PATHS_COUNT` (line 691)
3. **Verification Loop**: Changed from `$RESEARCH_COMPLEXITY` to `$REPORT_PATHS_COUNT` (line 797)
4. **State Machine Library**: Added critical comments documenting that RESEARCH_COMPLEXITY must never be recalculated after sm_init()

**Verification**:
```bash
# Verify hardcoded recalculation removed
grep -n "RESEARCH_COMPLEXITY=[0-9]" .claude/commands/coordinate.md
# Should only show fallback at line ~427, not multiple assignments

# Verify loops use REPORT_PATHS_COUNT
grep -n "seq 1.*REPORT_PATHS_COUNT" .claude/commands/coordinate.md
# Should show lines 691 (discovery) and 797 (verification)

# Test with "integrate" keyword (previously triggered bug)
/coordinate "Research how to integrate authentication patterns"
# Should succeed with consistency: N agents invoked, N reports verified
```

**Fallback Behavior**: If RESEARCH_COMPLEXITY is not loaded from state (defensive check), command falls back to complexity=2 with a warning to stderr.

**See Also**:
- [Root Cause Analysis Report](../../specs/coordinate_command_error/reports/001_root_cause_analysis.md) - Complete 484-line analysis
- [Bug Fix Implementation Plan](../../specs/coordinate_command_error/plans/001_fix_research_complexity_bug.md) - 5-phase fix plan
- [Spec 678](../../specs/678_coordinate_haiku_classification/) - Comprehensive classification integration

### Debug Mode

**Enable verbose logging**:
```bash
export COORDINATE_DEBUG=1
/coordinate "your workflow"
```

**Output**: Detailed logging of:
- Library function calls
- Path calculations
- Agent invocations
- Verification checkpoints
- Context pruning operations

### Getting Help

- Check [Orchestration Best Practices Guide](./orchestration-best-practices.md) for patterns
- Review [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md)
- See [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md)
- Consult [Command Reference](../reference/command-reference.md) for quick syntax

---

## Phase 4 Improvements: State Variable Verification and Concurrent Workflow Isolation

This section documents improvements implemented in Spec 672 Phase 4 to enhance state management reliability and concurrent workflow support.

### State Variable Verification Checkpoints

**Purpose**: Prevent unbound variable errors by verifying state persistence immediately after critical operations.

**Pattern**: Use `verify_state_variable()` function from `verification-helpers.sh` after state writes.

**Example**:
```bash
# After sm_init
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"

# Verification checkpoint (fail-fast if persistence failed)
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**Verification Points in /coordinate**:
1. **WORKFLOW_SCOPE** - After sm_init (line 151)
2. **REPORT_PATHS_COUNT** - After array export (line 233)
3. **EXISTING_PLAN_PATH** - For research-and-revise workflows (line 160)

**Benefits**:
- Fail-fast error detection (catches state persistence failures immediately)
- Comprehensive diagnostics (shows expected format, state file path, troubleshooting steps)
- Prevents cascading errors (stops workflow before unbound variable errors occur)

**Reference**: See [verify_state_variable() documentation](../lib/verification-helpers.sh)

### Concurrent Workflow Isolation

**Purpose**: Allow multiple `/coordinate` workflows to run simultaneously without state file interference.

**Problem**: Old pattern used fixed location for state ID file, causing concurrent workflows to overwrite each other's state.

**Solution**: Unique timestamp-based state ID files per workflow.

**Old Pattern** (concurrent workflows interfere):
```bash
# Fixed location - all workflows use same file
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
```

**New Pattern** (concurrent workflows isolated):
```bash
# Block 1: Create unique state ID file
TIMESTAMP=$(date +%s%N)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Persist path to workflow state
append_workflow_state "COORDINATE_STATE_ID_FILE" "$COORDINATE_STATE_ID_FILE"

# Cleanup trap (removes file after workflow completes)
trap "rm -f '$COORDINATE_STATE_ID_FILE' 2>/dev/null || true" EXIT

# Block 2+: Load with backward compatibility
COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  load_workflow_state "$WORKFLOW_ID"

  # Check if workflow uses new unique pattern
  if [ -n "${COORDINATE_STATE_ID_FILE:-}" ] && [ "$COORDINATE_STATE_ID_FILE" != "$COORDINATE_STATE_ID_FILE_OLD" ]; then
    # New pattern: COORDINATE_STATE_ID_FILE from workflow state
    : # Already set
  else
    # Old pattern: Use fixed location (backward compatibility)
    COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
  fi
fi
```

**Benefits**:
- Concurrent workflow support (2+ workflows can run simultaneously)
- Backward compatibility (old workflows using fixed location still work)
- Automatic cleanup (trap removes state ID file when workflow exits)
- No race conditions (each workflow has isolated state)

**Testing**: See `.claude/tests/test_concurrent_workflows.sh` (5 tests, 100% pass rate)

### Defensive Array Reconstruction Pattern

**Purpose**: Prevent unbound variable errors when reconstructing arrays from workflow state.

**Problem**: Array variables are lost across bash block boundaries (subprocess isolation). When reconstructing arrays from indexed variables, missing variables cause unbound variable errors.

**Solution**: Generic `reconstruct_array_from_indexed_vars()` function with defensive checks.

**Pattern**:
```bash
# Generic reconstruction with defensive handling
reconstruct_array_from_indexed_vars() {
  local array_name="$1"
  local count_var_name="$2"
  local var_prefix="${3:-${array_name%S}}"  # Default: remove trailing 'S'

  # Defensive: Default to 0 if count variable unset
  local count="${!count_var_name:-0}"

  # Clear target array
  eval "${array_name}=()"

  # Reconstruct with defensive checks
  for ((i=0; i<count; i++)); do
    local var_name="${var_prefix}_${i}"

    # Defensive: Check if indexed variable exists
    if [ -n "${!var_name+x}" ]; then
      eval "${array_name}+=(\"${!var_name}\")"
    else
      echo "WARNING: $var_name missing from state (expected $count elements, skipping)" >&2
    fi
  done
}

# Usage
reconstruct_array_from_indexed_vars "REPORT_PATHS" "REPORT_PATHS_COUNT" "REPORT_PATH"
```

**Key Features**:
- **Defensive count check**: `${!count_var_name:-0}` prevents errors if count unset
- **Variable existence check**: `${!var_name+x}` tests if indexed variable exists
- **Graceful degradation**: Warns about missing variables instead of crashing
- **Reusable**: Works for any array type (reports, plans, artifacts)

**Reference**: See [workflow-initialization.sh](../lib/workflow-initialization.sh)

### Fail-Fast State Validation

**Purpose**: Distinguish expected vs unexpected missing state files for better error detection.

**Problem**: Missing state files can be expected (first bash block) or unexpected (subsequent blocks after state corruption). Old pattern treated both cases the same.

**Solution**: `is_first_block` parameter to `load_workflow_state()`.

**Pattern**:
```bash
# Block 1: Initialize state (missing state file is expected)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Block 2+: Load state (missing state file is critical error)
load_workflow_state "$WORKFLOW_ID" false  # is_first_block=false

# Inside load_workflow_state():
load_workflow_state() {
  local workflow_id="$1"
  local is_first_block="${2:-false}"

  if [ ! -f "$STATE_FILE" ]; then
    if [ "$is_first_block" = "true" ]; then
      # Expected: Initialize new state
      init_workflow_state "$workflow_id"
      return 0
    else
      # Unexpected: Critical error
      echo "CRITICAL ERROR: Workflow state file missing" >&2
      echo "  Expected: $STATE_FILE" >&2
      echo "  Workflow ID: $workflow_id" >&2
      echo "  This indicates state corruption or premature cleanup" >&2
      return 2  # Distinct error code for fail-fast errors
    fi
  fi

  # Load state
  source "$STATE_FILE"
}
```

**Benefits**:
- Fail-fast error detection (unexpected missing files cause immediate failure)
- Clear diagnostics (distinguishes initialization vs corruption)
- Distinct error codes (0=success, 1=expected init, 2=critical error)

**Reference**: See [state-persistence.sh](../lib/state-persistence.sh)

### Decision Guide for State Variables

When implementing new state variables, use the [State Variable Decision Guide](./state-variable-decision-guide.md) to choose between file-based persistence and stateless recalculation.

**Quick decision**:
- **File-based persistence**: Expensive to compute (>100ms), non-deterministic, external dependencies, state mutations, arrays
- **Stateless recalculation**: Cheap (<10ms), deterministic, derived from persisted variables

**Examples**:
- ✓ Persist: `WORKFLOW_ID`, `REPORT_PATHS`, `COMPLETED_STATES`, `COORDINATE_STATE_ID_FILE`
- ✗ Don't persist: `REPORTS_DIR="${TOPIC_PATH}/reports"` (derived, <1ms)

---

## See Also

- [Orchestration Best Practices Guide](./orchestration-best-practices.md) - Unified framework for all orchestration commands
- [Orchestration Troubleshooting Guide](./orchestration-troubleshooting.md) - Debugging procedures
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State preservation
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based execution details
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Context optimization
- [Context Management Pattern](../concepts/patterns/context-management.md) - Pruning techniques
- [Command Reference](../reference/command-reference.md) - Quick syntax reference
- [State Management Documentation](../architecture/coordinate-state-management.md) - Subprocess isolation patterns
