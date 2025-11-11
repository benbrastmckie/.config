# State Persistence Patterns for Multi-Bash-Block Workflows

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: State persistence patterns for multi-bash-block workflows
- **Report Type**: Codebase analysis and best practices
- **Complexity Level**: 2

## Executive Summary

The .claude/ codebase implements a sophisticated state management architecture for multi-bash-block workflows using GitHub Actions-style file-based persistence. The architecture achieves 70% performance improvement (50ms → 15ms for CLAUDE_PROJECT_DIR detection) through selective persistence of 7 critical state items while using stateless recalculation for 3 low-cost items. Core patterns include atomic JSON checkpoints, EXIT trap cleanup, graceful degradation to recalculation, and explicit state machine abstractions with validated transitions. The system successfully eliminates bash history expansion errors and maintains state reliability across subprocess boundaries.

## Findings

### 1. File-Based State Persistence Pattern (GitHub Actions Style)

The codebase implements a GitHub Actions-inspired pattern using state files with bash export statements.

**Implementation**: `.claude/lib/state-persistence.sh`

**Core Functions**:
- `init_workflow_state()` - Creates state file once in Block 1 (lines 115-142)
- `load_workflow_state()` - Sources state file in Blocks 2+ (lines 168-182)
- `append_workflow_state()` - Appends key-value pairs using `export KEY="value"` format (lines 207-217)

**Pattern Structure**:
```bash
# Block 1: Initialize state file
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Block 2+: Load state file
load_workflow_state "coordinate_$$"
# Variables restored: CLAUDE_PROJECT_DIR, WORKFLOW_ID, STATE_FILE

# Append state across blocks
append_workflow_state "RESEARCH_COMPLETE" "true"
append_workflow_state "REPORTS_CREATED" "4"
```

**Performance Characteristics** (lines 20, 42-45, 98-99):
- CLAUDE_PROJECT_DIR detection: 50ms (git rev-parse) → 15ms (file read) = 70% improvement
- State file append: <1ms (simple echo >> redirect)
- Graceful degradation overhead: <1ms (file existence check)

**Key Innovation**: State file cached in Block 1, sourced in subsequent blocks - eliminates repeated expensive operations like `git rev-parse`.

### 2. Selective State Persistence Decision Criteria

The library uses explicit criteria to determine which state items warrant file-based persistence versus stateless recalculation.

**Decision Criteria** (lines 61-68):
1. State accumulates across subprocess boundaries
2. Context reduction requires metadata aggregation (95% reduction)
3. Success criteria validation needs objective evidence
4. Resumability is valuable (multi-hour migrations)
5. State is non-deterministic (user surveys, research findings)
6. Recalculation is expensive (>30ms) or impossible
7. Phase dependencies require prior phase outputs

**File-Based Persistence (7 items, lines 47-54)**:
1. **Supervisor metadata (P0)**: 95% context reduction, non-deterministic research findings
2. **Benchmark dataset (P0)**: Phase 3 accumulation across 10 subprocess invocations
3. **Implementation supervisor state (P0)**: 40-60% time savings via parallel execution tracking
4. **Testing supervisor state (P0)**: Lifecycle coordination across sequential stages
5. **Migration progress (P1)**: Resumable, audit trail for multi-hour migrations
6. **Performance benchmarks (P1)**: Phase 3 dependency on Phase 2 data
7. **POC metrics (P1)**: Success criterion validation (timestamped phase breakdown)

**Stateless Recalculation (3 items, lines 56-59)**:
1. **File verification cache**: Recalculation 10x faster than file I/O
2. **Track detection results**: Deterministic, <1ms recalculation
3. **Guide completeness checklist**: Markdown checklist sufficient

**Takeaway**: Only persist state when recalculation is expensive, impossible, or non-deterministic. Otherwise, recalculate for simplicity.

### 3. Atomic JSON Checkpoint Writes

For structured data (arrays, objects), the library uses atomic JSON checkpoints with temp file + mv pattern.

**Implementation** (lines 240-258):
```bash
save_json_checkpoint() {
  local checkpoint_name="$1"
  local json_data="$2"

  local checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/${checkpoint_name}.json"

  # Atomic write: temp file + mv
  local temp_file=$(mktemp "${checkpoint_file}.XXXXXX")
  echo "$json_data" > "$temp_file"
  mv "$temp_file" "$checkpoint_file"
}
```

**Performance** (lines 223-226):
- Write operation: 5-10ms (temp file + mv + fsync)
- Atomic guarantee: No partial writes on crash (mv is atomic)

**Load with Graceful Degradation** (lines 279-295):
```bash
load_json_checkpoint() {
  local checkpoint_name="$1"
  local checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/${checkpoint_name}.json"

  if [ -f "$checkpoint_file" ]; then
    cat "$checkpoint_file"
  else
    # Graceful degradation: return empty JSON object if missing
    echo "{}"
  fi
}
```

**Use Cases**:
- Supervisor metadata aggregation (95.6% context reduction)
- Benchmark dataset accumulation
- Complex state objects requiring structured storage

### 4. EXIT Trap Cleanup Pattern

The codebase consistently uses EXIT traps for automatic state file cleanup.

**Pattern Discovery** (65+ instances found via grep):
```bash
# Caller sets trap after initializing state
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT
```

**Critical Design Decision** (lines 137-139):
```bash
# Note: EXIT trap should be set by caller, not here
# Setting trap in subshell (when called via $(...)) causes immediate cleanup
# Caller should add: trap "rm -f '$STATE_FILE'" EXIT
```

**Why Caller Sets Trap**:
- `init_workflow_state` returns path via `$(...)` command substitution (subshell)
- Trap set inside function executes on subshell exit (immediate cleanup)
- Caller sets trap after capturing return value (cleanup on workflow exit)

**Cleanup Pattern Variations** (from grep analysis):
```bash
# Single state file
trap "rm -f '$STATE_FILE'" EXIT

# Multiple temp files (/coordinate pattern)
trap "rm -f '$COORDINATE_DESC_FILE' '$COORDINATE_STATE_ID_FILE'" EXIT

# Directory cleanup (test suites)
trap "rm -rf $TEST_DIR" EXIT

# Function-based cleanup (complex teardown)
trap cleanup EXIT
```

**Files Using Pattern**: 65+ files including:
- `.claude/commands/orchestrate.md:103`
- `.claude/commands/coordinate.md:113`
- `.claude/commands/supervise.md:73`
- `.claude/lib/substitute-variables.sh:19`
- All test files in `.claude/tests/`

**Reliability**: EXIT trap ensures cleanup even on errors, signals (SIGINT), or early returns.

### 5. State Machine Abstraction with Validated Transitions

The workflow-state-machine.sh library provides explicit state machine abstraction replacing implicit phase numbers.

**Implementation**: `.claude/lib/workflow-state-machine.sh`

**8 Core States** (lines 36-43):
```bash
readonly STATE_INITIALIZE="initialize"       # Phase 0
readonly STATE_RESEARCH="research"           # Phase 1
readonly STATE_PLAN="plan"                   # Phase 2
readonly STATE_IMPLEMENT="implement"         # Phase 3
readonly STATE_TEST="test"                   # Phase 4
readonly STATE_DEBUG="debug"                 # Phase 5
readonly STATE_DOCUMENT="document"           # Phase 6
readonly STATE_COMPLETE="complete"           # Phase 7
```

**Transition Table** (lines 50-59):
```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research"
  [research]="plan,complete"        # Can skip to complete for research-only
  [plan]="implement,complete"       # Can skip to complete for research-and-plan
  [implement]="test"
  [test]="debug,document"           # Conditional: debug if failed, document if passed
  [debug]="test,complete"           # Retry testing or complete if unfixable
  [document]="complete"
  [complete]=""                     # Terminal state
)
```

**Validated Transition Function** (lines 224-263):
```bash
sm_transition() {
  local next_state="$1"

  # Phase 1: Validate transition is allowed
  local valid_transitions="${STATE_TRANSITIONS[$CURRENT_STATE]}"

  if ! echo ",$valid_transitions," | grep -q ",$next_state,"; then
    echo "ERROR: Invalid transition: $CURRENT_STATE → $next_state" >&2
    echo "Valid transitions from $CURRENT_STATE: $valid_transitions" >&2
    return 1
  fi

  # Phase 2: Update state
  CURRENT_STATE="$next_state"
  COMPLETED_STATES+=("$next_state")

  return 0
}
```

**Benefits**:
- **Fail-fast validation**: Invalid transitions caught immediately (not at runtime)
- **Clear workflow paths**: Explicit state graph replaces implicit phase numbers
- **Conditional branching**: test → debug vs test → document based on results
- **State history**: COMPLETED_STATES array tracks workflow path

**Checkpoint Integration** (lines 149-213):
- Loads from v2.0 checkpoint schema with `.state_machine` wrapper
- Auto-migrates from v1.3 phase-based checkpoints
- Saves state machine section to checkpoint files (lines 349-416)

### 6. Variable Export and Environment Variable Patterns

The codebase uses explicit export patterns for cross-subprocess state sharing.

**Grep Analysis**: 207+ export statements found in `.claude/lib/`

**Source Guard Pattern** (used in all libraries):
```bash
# Prevent multiple sourcing
if [ -n "${STATE_PERSISTENCE_SOURCED:-}" ]; then
  return 0
fi
export STATE_PERSISTENCE_SOURCED=1
```

**Critical Path Variables** (`.claude/lib/detect-project-dir.sh:24,37,48`):
```bash
# Detect once, export for all subprocesses
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Workflow Initialization Exports** (`.claude/lib/workflow-initialization.sh:280-307`):
```bash
export LOCATION="$project_root"
export PROJECT_ROOT="$project_root"
export SPECS_ROOT="$specs_root"
export TOPIC_NUM="$topic_num"
export TOPIC_NAME="$topic_name"
export TOPIC_PATH="$topic_path"
# ... 11 total exports
```

**Array Export Pattern** (requires bash 4.2+):
```bash
# Export arrays (requires bash 4.2+ for declare -g)
declare -ga REPORT_PATHS=("${report_paths[@]}")
export REPORT_PATHS_COUNT="${#report_paths[@]}"
# Note: Array itself not exported, only count
# Workaround: Pass via state file or JSON checkpoint
```

**Associative Array Pattern** (workflow-state-machine.sh:50):
```bash
# Global associative array (not exportable)
declare -gA STATE_TRANSITIONS=(...)
# Note: Associative arrays cannot be exported
# Workaround: Source library in each subprocess
```

**Key Constraint**: Bash cannot export arrays or associative arrays. Solutions:
1. **State file pattern**: Save array to file, source in subprocess
2. **JSON checkpoint**: Serialize array to JSON, deserialize in subprocess
3. **Count + indexed access**: Export count, reconstruct array elements

### 7. State Reconstruction Techniques

The codebase employs multiple techniques for reconstructing complex state across subprocess boundaries.

**Array Reconstruction via JSONL** (state-persistence.sh:325-340):
```bash
append_jsonl_log() {
  local log_name="$1"
  local json_entry="$2"

  local log_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/${log_name}.jsonl"
  echo "$json_entry" >> "$log_file"
}

# Reconstruction in next subprocess
BENCHMARKS=$(cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/benchmarks.jsonl")
```

**State History Array** (workflow-state-machine.sh:202-208):
```bash
# v1.3 migration: Reconstruct completed_states from completed_phases
local completed_phases
mapfile -t completed_phases < <(jq -r '.workflow_state.completed_phases[]?' "$checkpoint_file")
COMPLETED_STATES=()
for phase in "${completed_phases[@]}"; do
  COMPLETED_STATES+=("$(map_phase_to_state "$phase")")
done
```

**jq Array Loading** (workflow-state-machine.sh:158):
```bash
# Load array from JSON checkpoint
mapfile -t COMPLETED_STATES < <(jq -r '.state_machine.completed_states[]' "$checkpoint_file")
```

**Graceful Degradation Pattern** (state-persistence.sh:176-181):
```bash
if [ -f "$state_file" ]; then
  source "$state_file"
  return 0
else
  # Fallback: recalculate if state file missing
  init_workflow_state "$workflow_id" >/dev/null
  return 1
fi
```

**Two-Phase Reconstruction**:
1. **Load from checkpoint** (if available)
2. **Recalculate from first principles** (if checkpoint missing)

This pattern enables resumability while maintaining reliability when state files are deleted.

### 8. Cleanup and Lifecycle Management

The codebase implements comprehensive lifecycle management for temporary state.

**Temporary File Locations**:
- State files: `.claude/tmp/workflow_${workflow_id}.sh`
- JSON checkpoints: `.claude/tmp/${checkpoint_name}.json`
- JSONL logs: `.claude/tmp/${log_name}.jsonl`

**Lifecycle Phases**:
1. **Creation**: `init_workflow_state()` or `save_json_checkpoint()`
2. **Usage**: `load_workflow_state()` or `load_json_checkpoint()`
3. **Cleanup**: EXIT trap removes files on workflow completion

**Directory Creation** (lazy pattern, lines 126, 250, 335):
```bash
# Create .claude/tmp if it doesn't exist
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp"
```

**Cleanup Patterns**:

**Single File**:
```bash
trap "rm -f '$STATE_FILE'" EXIT
```

**Multiple Files**:
```bash
trap "rm -f '$COORDINATE_DESC_FILE' '$COORDINATE_STATE_ID_FILE'" EXIT
```

**Directory Cleanup**:
```bash
trap "rm -rf $TEST_DIR" EXIT
```

**Function-Based Cleanup** (complex teardown):
```bash
cleanup() {
  rm -rf "$TEST_DIR"
  kill $BACKGROUND_PID 2>/dev/null
  # ... additional cleanup
}
trap cleanup EXIT
```

**Edge Cases Handled**:
- State file deleted mid-workflow: Graceful degradation to recalculation
- Subprocess crash: EXIT trap still executes (signal handlers)
- Command substitution: Caller sets trap (not function)
- Parallel execution: Unique workflow IDs prevent collision

### 9. Subprocess Isolation Patterns

The /coordinate command uses a sophisticated subprocess isolation pattern to prevent bash history expansion errors.

**Problem Context** (`.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md:246`):
```bash
# Original pattern (FAILS with history expansion):
bash -c "$BLOCK_CONTENT"
# Error: "!1" triggers history expansion even with set +H
```

**Solution** (`.claude/commands/coordinate.md:113`, `coordinate_output.md:207`):
```bash
# Two-step execution with file-based state
COORDINATE_DESC_FILE=$(mktemp)
COORDINATE_STATE_ID_FILE=$(mktemp)
trap "rm -f '$COORDINATE_DESC_FILE' '$COORDINATE_STATE_ID_FILE'" EXIT

# Step 1: Write workflow description to file
echo "$WORKFLOW_DESCRIPTION" > "$COORDINATE_DESC_FILE"

# Step 2: Pass file path (not content) to subprocess
bash <<'EXECUTE_BLOCK_1'
  WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE")
  # ... workflow execution
EXECUTE_BLOCK_1
```

**Key Insight**: File-based argument passing eliminates history expansion issues:
- Variables never passed via `-c` flag (no `bash -c "..."`)
- Content read from file inside subprocess (no shell interpretation)
- Heredoc with single quotes prevents premature expansion

**State Persistence Across Blocks**:
```bash
# Block 1: Initialize state
STATE_FILE=$(init_workflow_state "coordinate_$$")

# Block 2+: Load state
source "$COORDINATE_STATE_ID_FILE"  # Contains: export STATE_FILE="..."
load_workflow_state "$(cat "$COORDINATE_STATE_ID_FILE")"
```

**Benefits**:
- **100% reliability**: No bash history expansion errors
- **Clean isolation**: Each block runs in controlled environment
- **State continuity**: Workflow state persists across blocks
- **Error handling**: EXIT trap ensures cleanup

## Recommendations

### 1. Use Selective State Persistence

**Action**: Apply decision criteria from `.claude/lib/state-persistence.sh:61-68` to determine when file-based persistence is warranted.

**Guidelines**:
- **File-based persistence**: Non-deterministic state, expensive recalculation (>30ms), cross-subprocess accumulation
- **Stateless recalculation**: Deterministic state, cheap recalculation (<1ms), single-block scope

**Benefits**: 70% performance improvement for expensive operations while maintaining simplicity for cheap operations.

### 2. Adopt GitHub Actions State File Pattern

**Action**: Use `init_workflow_state()` / `load_workflow_state()` / `append_workflow_state()` for multi-block workflows.

**Pattern**:
```bash
# Block 1
STATE_FILE=$(init_workflow_state "workflow_$$")
trap "rm -f '$STATE_FILE'" EXIT
append_workflow_state "VAR1" "value1"

# Block 2+
load_workflow_state "workflow_$$"
echo "$VAR1"  # Restored from state file
```

**Benefits**:
- Simple API (3 functions)
- Automatic variable export/source
- Graceful degradation if state file deleted
- EXIT trap cleanup prevents leakage

### 3. Implement Atomic JSON Checkpoints for Structured Data

**Action**: Use `save_json_checkpoint()` / `load_json_checkpoint()` for arrays, objects, and complex state.

**When to Use**:
- Arrays (bash cannot export arrays)
- Associative arrays (cannot be exported)
- Nested structures (supervisor metadata, benchmark datasets)
- State requiring schema validation

**Pattern**:
```bash
# Save structured data
METADATA='{"topics": 4, "reports": ["r1.md", "r2.md"]}'
save_json_checkpoint "supervisor_metadata" "$METADATA"

# Load in next subprocess
METADATA=$(load_json_checkpoint "supervisor_metadata")
TOPIC_COUNT=$(echo "$METADATA" | jq -r '.topics')
```

**Benefits**:
- Atomic writes (temp file + mv)
- Graceful degradation (returns {} if missing)
- jq validation ensures valid JSON
- 5-10ms overhead (acceptable for critical state)

### 4. Always Use EXIT Trap Cleanup

**Action**: Set EXIT trap immediately after creating temporary files.

**Pattern**:
```bash
STATE_FILE=$(init_workflow_state "workflow_$$")
trap "rm -f '$STATE_FILE'" EXIT  # Set immediately

# Multiple files
TEMP1=$(mktemp)
TEMP2=$(mktemp)
trap "rm -f '$TEMP1' '$TEMP2'" EXIT  # Single trap for all
```

**Critical Rules**:
- **Caller sets trap**: Don't set trap inside function called via `$(...)`
- **Set immediately**: Before any potential errors or early returns
- **Single trap**: Combine multiple files in one trap statement
- **Quote paths**: Handle spaces and special characters

**Benefits**: Guaranteed cleanup even on errors, signals, or early returns.

### 5. Use State Machine Abstraction for Multi-Phase Workflows

**Action**: Replace phase numbers with explicit state machine from `workflow-state-machine.sh`.

**Migration**:
```bash
# Before (implicit phases)
CURRENT_PHASE=1
if [ "$CURRENT_PHASE" -eq 1 ]; then
  # research
fi

# After (explicit states)
source .claude/lib/workflow-state-machine.sh
sm_init "Research patterns" "coordinate"
sm_transition "$STATE_RESEARCH"
sm_execute  # Delegates to execute_research_phase()
```

**Benefits**:
- Validated transitions (fail-fast on invalid state changes)
- Clear workflow graph (STATE_TRANSITIONS table)
- Conditional branching (test → debug vs document)
- State history tracking (COMPLETED_STATES array)
- Checkpoint integration (v2.0 schema)

### 6. Implement Graceful Degradation for All State Loads

**Action**: Always provide fallback when loading state files or checkpoints.

**Pattern**:
```bash
# State file loading
if [ -f "$state_file" ]; then
  source "$state_file"
else
  # Fallback: recalculate
  init_workflow_state "$workflow_id" >/dev/null
fi

# JSON checkpoint loading
METADATA=$(load_json_checkpoint "supervisor_metadata")
if [ "$METADATA" = "{}" ]; then
  # Empty object indicates missing checkpoint
  # Fallback: Use defaults or recalculate
  METADATA='{"topics": 0, "reports": []}'
fi
```

**Benefits**:
- Workflow continues even if state file deleted
- No hard dependency on previous executions
- Easier testing (no required setup state)
- Resilient to manual cleanup or filesystem issues

### 7. Use File-Based Argument Passing to Prevent Expansion Errors

**Action**: For complex multi-block workflows, pass arguments via temporary files instead of bash -c variables.

**Pattern** (from /coordinate):
```bash
# Create temp files for arguments
DESC_FILE=$(mktemp)
echo "$WORKFLOW_DESCRIPTION" > "$DESC_FILE"
trap "rm -f '$DESC_FILE'" EXIT

# Pass file path to subprocess (not content)
bash <<'EXECUTE_BLOCK'
  WORKFLOW_DESCRIPTION=$(cat "$DESC_FILE")
  # ... use $WORKFLOW_DESCRIPTION safely
EXECUTE_BLOCK
```

**Benefits**:
- No bash history expansion errors (! characters safe)
- No quote escaping issues
- No variable substitution conflicts
- Clean subprocess isolation

**When to Use**:
- Multi-line content with special characters
- Content containing !, $, `, or quotes
- Large argument strings (>1KB)
- Multiple bash blocks requiring same argument

## References

### Primary Implementation Files
- `.claude/lib/state-persistence.sh` - GitHub Actions-style state file pattern (341 lines)
- `.claude/lib/workflow-state-machine.sh` - Explicit state machine abstraction (508 lines)
- `.claude/commands/coordinate.md:113` - Subprocess isolation pattern with trap cleanup
- `.claude/commands/orchestrate.md:103` - State file initialization and cleanup
- `.claude/commands/supervise.md:73` - Simplified state management pattern

### Supporting Libraries
- `.claude/lib/workflow-initialization.sh:280-307` - Workflow variable exports
- `.claude/lib/detect-project-dir.sh:24,37,48` - CLAUDE_PROJECT_DIR caching pattern
- `.claude/lib/substitute-variables.sh:19` - EXIT trap for temp file cleanup
- `.claude/lib/error-handling.sh:9` - Source guard pattern

### Test Coverage
- `.claude/tests/test_state_machine.sh:218` - State machine validation tests
- `.claude/tests/test_parallel_waves.sh:16` - Parallel execution state isolation
- `.claude/tests/test_checkpoint_schema_v2.sh:82` - Checkpoint v2.0 schema tests
- `.claude/tests/test_unified_location_detection.sh:27` - Location detection caching

### Research Reports and Analysis
- `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md` - Bash history expansion error diagnosis
- `.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/002_state_management_synthesis.md` - State management synthesis
- `.claude/specs/585_bash_export_persistence_alternatives/reports/001_bash_export_persistence_alternatives/OVERVIEW.md` - Comprehensive bash persistence patterns
- `.claude/docs/architecture/state-based-orchestration-overview.md:406` - State-based orchestration architecture
- `.claude/docs/architecture/coordinate-state-management.md:271,583` - Coordinate subprocess isolation patterns

### Grep Analysis Results
- 65+ files using EXIT trap cleanup pattern
- 207+ export statements in `.claude/lib/` libraries
- Consistent source guard pattern across all libraries
- Atomic JSON checkpoint pattern in supervisor implementations
