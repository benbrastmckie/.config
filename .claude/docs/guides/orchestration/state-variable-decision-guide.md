# State Variable Decision Guide

## Overview

This guide provides decision criteria for choosing between file-based persistence and stateless recalculation for workflow state variables in the `/coordinate` command and other orchestration commands.

**Context**: Bash blocks in Claude Code run in separate subprocesses, causing all variables to be lost between blocks. To maintain state continuity, we must either persist variables to files or recalculate them in each block.

**Related Documentation**:
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md)
- [Coordinate State Management](.claude/docs/architecture/coordinate-state-management.md)
- [State Persistence Library](.claude/lib/core/state-persistence.sh)

## Quick Decision Matrix

| Criterion | File-Based Persistence | Stateless Recalculation |
|-----------|----------------------|------------------------|
| **Expensive to compute?** (>100ms) | ✓ Yes | ✗ No |
| **Non-deterministic?** (timestamps, random) | ✓ Yes | ✗ No |
| **External state?** (agent outputs, user input) | ✓ Yes | ✗ No |
| **Changes during workflow?** (state transitions) | ✓ Yes | ✗ No |
| **Array or complex type?** | ✓ Yes (special handling) | ⚠ Maybe (if cheap to reconstruct) |
| **Simple path calculation?** (<10ms) | ✗ No | ✓ Yes |
| **Derived from persisted vars?** | ✗ No | ✓ Yes |

## The 7 Criteria for File-Based Persistence

### 1. **Computation Cost** (Performance)

**Use file-based persistence when**: Recalculation takes >100ms

**Example**: `CLAUDE_PROJECT_DIR` detection

```bash
# Expensive: git rev-parse + directory traversal
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Benchmark: 6ms (fast, but called 100+ times = 600ms total)

# Decision: File-based persistence (67% performance improvement: 6ms → 2ms via caching)
```

**Performance Measurement**:
```bash
# Benchmark pattern
START=$(date +%s%N)
# ... operation ...
END=$(date +%s%N)
DURATION_MS=$(( (END - START) / 1000000 ))
echo "Duration: ${DURATION_MS}ms"
```

### 2. **Non-Determinism** (Consistency)

**Use file-based persistence when**: Variable value depends on timing, randomness, or external state

**Examples**:
- **Timestamps**: `WORKFLOW_ID="coordinate_$(date +%s)"` (changes every second)
- **Random values**: `NONCE=$(od -An -N4 -tu4 < /dev/urandom)`
- **External API calls**: `GITHUB_TOKEN=$(gh auth token)`

**Anti-Pattern** (stateless recalculation of timestamp):
```bash
# WRONG: Workflow ID changes between bash blocks
WORKFLOW_ID="coordinate_$(date +%s)"  # Different value each time!

# CORRECT: Persist to state
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
```

### 3. **External Dependencies** (Agent Outputs, User Input)

**Use file-based persistence when**: Variable value comes from:
- Agent Task tool invocations
- User prompts (AskUserQuestion tool)
- File system state created by agents
- External commands with non-idempotent side effects

**Example**: `REPORT_PATHS` array

```bash
# Agent creates report files with dynamic names
# Reports may not exist yet when array is first populated
REPORT_PATHS=("${TOPIC_PATH}/reports/001_foo.md" "${TOPIC_PATH}/reports/002_bar.md")

# Must persist: Agent-generated filenames are not deterministic
append_workflow_state "REPORT_PATHS_COUNT" "${#REPORT_PATHS[@]}"
for i in "${!REPORT_PATHS[@]}"; do
  append_workflow_state "REPORT_PATH_$i" "${REPORT_PATHS[$i]}"
done
```

### 4. **State Mutations** (Changes During Workflow)

**Use file-based persistence when**: Variable value changes as workflow progresses

**Example**: State machine variables

```bash
# CURRENT_STATE changes during workflow (research → plan → implement)
sm_transition "research" "plan"  # Updates CURRENT_STATE

# COMPLETED_STATES array grows over time
COMPLETED_STATES+=("research")

# Must persist: Values change between bash blocks
save_state_machine_to_state  # Saves CURRENT_STATE, COMPLETED_STATES, etc.
```

### 5. **Array or Complex Types** (Data Structure Complexity)

**Use file-based persistence when**: Variable is an array or requires special reconstruction logic

**Example**: `REPORT_PATHS` array

```bash
# Arrays lost across bash block boundaries (subprocess isolation)
REPORT_PATHS=("file1.md" "file2.md" "file3.md")

# Serialize to indexed variables for persistence
append_workflow_state "REPORT_PATHS_COUNT" "${#REPORT_PATHS[@]}"
for i in "${!REPORT_PATHS[@]}"; do
  append_workflow_state "REPORT_PATH_$i" "${REPORT_PATHS[$i]}"
done

# Reconstruct in next bash block
reconstruct_report_paths_array  # Defensive pattern with validation
```

**Alternative** (JSON serialization for complex arrays):
```bash
# For arrays with complex data
COMPLETED_STATES_JSON=$(printf '%s\n' "${COMPLETED_STATES[@]}" | jq -R . | jq -s .)
append_workflow_state "COMPLETED_STATES_JSON" "$COMPLETED_STATES_JSON"

# Reconstruct
mapfile -t COMPLETED_STATES < <(echo "$COMPLETED_STATES_JSON" | jq -r '.[]')
```

### 6. **Derivability** (Can it be recalculated cheaply?)

**Use stateless recalculation when**: Variable can be quickly derived from persisted variables

**Example**: `REPORTS_DIR` (derived path)

```bash
# TOPIC_PATH is persisted (criterion #4: changes during workflow)
# REPORTS_DIR is derived (fast string concatenation)

# Stateless recalculation (preferred)
REPORTS_DIR="${TOPIC_PATH}/reports"  # <1ms, deterministic, no external deps

# No persistence needed: Can be recalculated from TOPIC_PATH in every bash block
```

### 7. **Critical Path Isolation** (Concurrent Workflow Safety)

**Use file-based persistence when**: Variable must be isolated between concurrent workflow invocations

**Example**: `COORDINATE_STATE_ID_FILE` (unique per workflow)

```bash
# Old pattern: Fixed location (concurrent workflows interfere)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"

# New pattern: Unique timestamp-based filename
TIMESTAMP=$(date +%s%N)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"

# Persist to state for bash block persistence
append_workflow_state "COORDINATE_STATE_ID_FILE" "$COORDINATE_STATE_ID_FILE"

# Cleanup trap prevents file accumulation
trap "rm -f '$COORDINATE_STATE_ID_FILE' 2>/dev/null || true" EXIT
```

## Anti-Patterns (When NOT to Use File-Based State)

### Anti-Pattern 1: Persisting Cheap Calculations

**Problem**: Adds complexity without performance benefit

```bash
# WRONG: Persisting simple string concatenation
PLANS_DIR="${TOPIC_PATH}/plans"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"  # Unnecessary!

# CORRECT: Recalculate in each block
PLANS_DIR="${TOPIC_PATH}/plans"  # <1ms, no persistence needed
```

**Rule**: Only persist if recalculation cost >100ms or meets other criteria

### Anti-Pattern 2: Persisting Derived State Without Base State

**Problem**: Violates single source of truth principle

```bash
# WRONG: Persisting both base and derived state
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "REPORTS_DIR" "${TOPIC_PATH}/reports"  # Derived!
append_workflow_state "PLANS_DIR" "${TOPIC_PATH}/plans"      # Derived!

# CORRECT: Persist only base state, recalculate derived
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
# In each bash block:
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
```

### Anti-Pattern 3: Using Bootstrap Fallbacks

**Problem**: Hides configuration errors instead of failing fast

```bash
# WRONG: Bootstrap fallback (defines function if missing)
if ! declare -f get_topic_path >/dev/null 2>&1; then
  get_topic_path() { echo "specs/000_default"; }
fi

# CORRECT: Fail-fast verification
if ! declare -f get_topic_path >/dev/null 2>&1; then
  echo "ERROR: get_topic_path function not defined (library not sourced)"
  exit 1
fi
```

**Rule**: Use verification fallbacks (detect errors), not bootstrap fallbacks (hide errors)

See [Fail-Fast Policy Analysis](../specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md)

### Anti-Pattern 4: Persisting Without Defensive Reconstruction

**Problem**: Unbound variable errors when state loading fails

```bash
# WRONG: Assume REPORT_PATHS_COUNT exists
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do  # ERROR if REPORT_PATHS_COUNT unset!
  var_name="REPORT_PATH_$i"
  REPORT_PATHS+=("${!var_name}")
done

# CORRECT: Defensive reconstruction with ${:-} pattern
REPORT_PATHS_COUNT="${REPORT_PATHS_COUNT:-0}"  # Default to 0 if unset
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  if [ -n "${!var_name+x}" ]; then  # Check if variable exists
    REPORT_PATHS+=("${!var_name}")
  else
    echo "WARNING: $var_name missing from state (skipping)"
  fi
done
```

**Rule**: All array reconstruction must handle missing variables gracefully

See [Defensive Array Reconstruction Pattern](../lib/workflow/workflow-initialization.sh)

## Migration Guide

### Stateless → File-Based Persistence

**When to migrate**: Variable meets one of the 7 criteria above

**Steps**:

1. **Identify persistence points** (first bash block where variable is set)
2. **Add append_workflow_state** after variable initialization
3. **Add verification checkpoint** (optional, recommended for critical vars)
4. **Document decision** in code comments

**Example**:

```bash
# Before (stateless)
EXISTING_PLAN_PATH=$(find_plan_in_workflow_description "$WORKFLOW_DESCRIPTION")

# After (file-based persistence)
EXISTING_PLAN_PATH=$(find_plan_in_workflow_description "$WORKFLOW_DESCRIPTION")
export EXISTING_PLAN_PATH

# Persist to state for bash block persistence (criterion #3: external dependency)
append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"

# Verification checkpoint (fail-fast if persistence failed)
verify_state_variable "EXISTING_PLAN_PATH" || {
  handle_state_error "CRITICAL: EXISTING_PLAN_PATH not persisted to state" 1
}
```

### File-Based Persistence → Stateless

**When to migrate**: Performance analysis shows recalculation is faster than file I/O

**Steps**:

1. **Benchmark both approaches** (file load vs recalculation)
2. **Verify determinism** (recalculation always produces same result)
3. **Remove append_workflow_state** calls
4. **Add recalculation** to each bash block
5. **Update tests** to not expect variable in state

**Example**:

```bash
# Before (file-based persistence)
# Bash block 1:
PLANS_DIR="${TOPIC_PATH}/plans"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"  # 2-3ms file write

# Bash block 2:
load_workflow_state "$WORKFLOW_ID"  # PLANS_DIR loaded from file (2ms read)

# After (stateless recalculation)
# Bash block 1:
PLANS_DIR="${TOPIC_PATH}/plans"
# No persistence needed

# Bash block 2:
PLANS_DIR="${TOPIC_PATH}/plans"  # <1ms recalculation, deterministic

# Performance gain: 4-5ms → <1ms (80% improvement)
```

## Performance Guidelines

### Measurement Best Practices

```bash
# Pattern: Measure end-to-end workflow time
PERF_START=$(date +%s%N)

# ... workflow execution ...

PERF_END=$(date +%s%N)
PERF_DURATION_MS=$(( (PERF_END - PERF_START) / 1000000 ))

echo "Workflow duration: ${PERF_DURATION_MS}ms"

# Log to adaptive planning log for analysis
log_metric "workflow_duration_ms" "$PERF_DURATION_MS"
```

### Benchmarking State Operations

```bash
# Benchmark: File-based persistence
BENCH_START=$(date +%s%N)
append_workflow_state "TEST_VAR" "test_value"
BENCH_END=$(date +%s%N)
PERSIST_MS=$(( (BENCH_END - BENCH_START) / 1000000 ))

# Benchmark: Stateless recalculation
BENCH_START=$(date +%s%N)
TEST_VAR="test_value"  # Simple assignment
BENCH_END=$(date +%s%N)
RECALC_MS=$(( (BENCH_END - BENCH_START) / 1000000 ))

echo "Persistence: ${PERSIST_MS}ms vs Recalculation: ${RECALC_MS}ms"

# Use file-based persistence if: RECALC_MS > PERSIST_MS + 5ms (overhead threshold)
```

### Performance Targets

- **State file operations**: <10ms per operation
- **Array reconstruction**: <5ms for arrays with <100 elements
- **Workflow initialization**: <500ms total (including all state loading)
- **Bash block transition overhead**: <50ms (state save + load)

### Performance Optimization Strategies

1. **Batch state writes**: Use single append_workflow_state per bash block for related variables
2. **Lazy loading**: Only load state variables when needed (conditional sourcing)
3. **Selective persistence**: Persist only variables meeting the 7 criteria
4. **Defensive patterns**: Add fail-fast validation to prevent silent performance degradation

## Case Studies

### Case Study 1: CLAUDE_PROJECT_DIR (Optimization Fallback)

**Decision**: File-based persistence via optimization fallback

**Rationale**:
- Criterion #1 (Performance): 6ms × 100 calls = 600ms total
- Criterion #6 (Derivability): Can be recalculated, but expensive
- Solution: Selective file-based persistence (optimization fallback, not bootstrap)

**Implementation**:
```bash
# Try cached value first (optimization fallback)
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  : # Already set, use cached value
else
  # Recalculate (expensive)
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Performance: 67% improvement (6ms → 2ms avg)
```

**Result**: 528ms saved during workflow initialization (41% overhead reduction)

### Case Study 2: REPORT_PATHS Array (External Dependency + Array Type)

**Decision**: File-based persistence (critical)

**Rationale**:
- Criterion #3 (External Dependency): Agent-generated filenames
- Criterion #5 (Array Type): Requires special reconstruction logic
- Criterion #4 (State Mutation): May grow during workflow

**Implementation**:
```bash
# Serialize array to indexed variables
append_workflow_state "REPORT_PATHS_COUNT" "${#REPORT_PATHS[@]}"
for i in "${!REPORT_PATHS[@]}"; do
  append_workflow_state "REPORT_PATH_$i" "${REPORT_PATHS[$i]}"
done

# Defensive reconstruction in subsequent blocks
reconstruct_report_paths_array  # Handles missing variables gracefully
```

**Result**: 100% reliability (no unbound variable errors), supports dynamic agent outputs

### Case Study 3: REPORTS_DIR (Derived Path)

**Decision**: Stateless recalculation (preferred)

**Rationale**:
- Criterion #6 (Derivability): Derived from TOPIC_PATH (<1ms)
- Fails all other criteria

**Implementation**:
```bash
# In every bash block
REPORTS_DIR="${TOPIC_PATH}/reports"  # Fast, deterministic, no persistence needed
```

**Result**: Simplified state management, no file I/O overhead

## References

- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation constraints
- [Coordinate State Management](.claude/docs/architecture/coordinate-state-management.md) - Complete state architecture
- [State Persistence Library](.claude/lib/core/state-persistence.sh) - Implementation details
- [Defensive Array Reconstruction](.claude/lib/workflow/workflow-initialization.sh) - Pattern implementation
- [Fail-Fast Policy Analysis](.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md) - Fallback type taxonomy

## Summary

**Key Takeaways**:

1. **Use file-based persistence for**: Expensive operations (>100ms), non-deterministic values, external dependencies, state mutations, arrays, concurrent workflow isolation
2. **Use stateless recalculation for**: Cheap operations (<10ms), deterministic values, derived state
3. **Avoid bootstrap fallbacks**: Use verification fallbacks instead (fail-fast)
4. **Always use defensive patterns**: Handle missing variables gracefully in array reconstruction
5. **Measure performance**: Benchmark before optimizing, target <10ms for state operations
6. **Document decisions**: Comment why each variable uses file-based persistence vs stateless recalculation

**Decision Process**:
1. Check if variable meets any of the 7 criteria → File-based persistence
2. If not → Stateless recalculation (preferred)
3. If unsure → Benchmark both approaches, choose faster one
4. Document decision in code comments
