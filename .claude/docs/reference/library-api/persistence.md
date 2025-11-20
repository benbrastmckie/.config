# Library API Reference - Persistence

State persistence and checkpoint utilities for workflows.

## Navigation

This document is part of a multi-part reference:
- [Overview](overview.md) - Purpose, quick index, core utilities
- [State Machine](library-api-state-machine.md) - Workflow classification and scope detection
- **Persistence** (this file) - State persistence and checkpoint utilities
- [Utilities](library-api-utilities.md) - Agent support, workflow support, analysis, and complete library list

---

## checkpoint-utils.sh

Checkpoint-based state management for resumable workflows. Enables `/implement` to resume after failures.

**Performance**: <50ms checkpoint save/load

### Core Functions

##### `save_checkpoint(checkpoint_name, state_data)`

Save workflow state to checkpoint file.

**Arguments**:
- `checkpoint_name` (string): Unique checkpoint identifier
- `state_data` (string): JSON state data

**Returns**: Nothing

**Exit Codes**:
- `0`: Success
- `1`: Failure (write failed)

##### `load_checkpoint(checkpoint_name)`

Load workflow state from checkpoint file.

**Arguments**:
- `checkpoint_name` (string): Unique checkpoint identifier

**Returns**: JSON state data (printed to stdout)

**Exit Codes**:
- `0`: Success
- `1`: Failure (checkpoint not found)

##### `list_checkpoints(pattern)`

List available checkpoints matching pattern.

**Arguments**:
- `pattern` (optional, string): Glob pattern to filter checkpoints

**Returns**: Newline-separated list of checkpoint names

**Exit Codes**: `0` (always succeeds)

---

## state-persistence.sh

GitHub Actions-style state persistence for selective file-based state management. Implements hybrid approach combining stateless recalculation for fast operations with file-based state for critical items.

**Pattern**: Selective state persistence (GitHub Actions `$GITHUB_OUTPUT` model)
**Performance**: 67% improvement (6ms init → 2ms load for CLAUDE_PROJECT_DIR)
**Test Coverage**: 18 tests, 100% pass rate
**Dependencies**: `jq` (JSON parsing), `mktemp` (atomic writes)

**When to Use**:
- State accumulates across subprocess boundaries
- Context reduction requires metadata aggregation (95% reduction)
- Success criteria validation needs objective evidence
- Resumability valuable for multi-hour workflows
- State is non-deterministic (research findings, user surveys)
- Recalculation is expensive (>30ms)
- Phase dependencies require prior phase outputs

**When NOT to Use**:
- Fast recalculation (<10ms and deterministic)
- State is ephemeral (temporary variables)
- No subprocess boundaries (single bash block)
- Canonical source exists elsewhere (library-api.md)
- File-based overhead exceeds recalculation cost

See [Selective State Persistence](../architecture/coordinate-state-management-states.md#selective-state-persistence) for complete decision criteria and patterns.

### Core Functions

##### `init_workflow_state(workflow_id)`

Initialize workflow state file with initial environment variables. Call once per workflow invocation (Block 1 only).

**Arguments**:
- `workflow_id` (string, optional): Unique identifier for workflow (default: `$$`)

**Returns**: Absolute path to created state file (printed to stdout)

**Side Effects**:
- Creates state file in `.claude/tmp/workflow_${workflow_id}.sh`
- Detects and caches CLAUDE_PROJECT_DIR (70% performance improvement)
- Exports CLAUDE_PROJECT_DIR, WORKFLOW_ID, STATE_FILE

**Performance**: ~6ms (includes git rev-parse)

**Exit Codes**:
- `0`: Success

**Usage**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT  # Cleanup on exit
```

**Note**: Caller must set EXIT trap for cleanup (not set inside function to avoid subshell cleanup issues).

##### `load_workflow_state(workflow_id)`

Load workflow state file to restore exported variables. Call in subsequent bash blocks (Blocks 2+).

**Arguments**:
- `workflow_id` (string, optional): Unique identifier for workflow (default: `$$`)

**Returns**: Nothing (sources state file, exports variables)

**Side Effects**:
- Sources state file (exports all variables from init and appends)
- If missing, falls back to `init_workflow_state` (graceful degradation)

**Performance**: ~2ms (file read only)

**Exit Codes**:
- `0`: State file loaded successfully
- `1`: State file missing (fallback executed)

**Usage**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "coordinate_$$"
echo "$CLAUDE_PROJECT_DIR"  # Variable restored from state file
```

**Graceful Degradation**: If state file deleted mid-workflow, automatically recalculates (no crash).

##### `append_workflow_state(key, value)`

Append new key-value pair to workflow state file. Follows GitHub Actions `$GITHUB_OUTPUT` pattern.

**Arguments**:
- `key` (string): Variable name to export
- `value` (string): Variable value

**Returns**: Nothing

**Side Effects**:
- Appends `export KEY="value"` to state file
- Variable available in subsequent `load_workflow_state` calls

**Performance**: <1ms (simple echo redirect)

**Exit Codes**:
- `0`: Success
- `1`: Failure (STATE_FILE not set - call `init_workflow_state` first)

**Usage**:
```bash
append_workflow_state "RESEARCH_COMPLETE" "true"
append_workflow_state "REPORTS_CREATED" "4"
# Subsequent blocks see: RESEARCH_COMPLETE="true", REPORTS_CREATED="4"
```

##### `save_json_checkpoint(checkpoint_name, json_data)`

Save structured data as JSON checkpoint file with atomic write semantics.

**Arguments**:
- `checkpoint_name` (string): Name of checkpoint (without .json extension)
- `json_data` (string): JSON string to save

**Returns**: Nothing

**Side Effects**:
- Creates `.claude/tmp/${checkpoint_name}.json`
- Uses atomic write (temp file + mv) to prevent partial writes

**Performance**: 5-10ms (atomic write with temp file + mv + fsync)

**Exit Codes**:
- `0`: Success
- `1`: Failure (CLAUDE_PROJECT_DIR not set)

**Usage**:
```bash
SUPERVISOR_METADATA='{"topics": 4, "reports": ["r1.md", "r2.md"]}'
save_json_checkpoint "supervisor_metadata" "$SUPERVISOR_METADATA"
# File created: .claude/tmp/supervisor_metadata.json
```

**Atomicity Guarantee**: Uses temp file + mv to ensure no partial writes on crash.

##### `load_json_checkpoint(checkpoint_name)`

Load JSON checkpoint file created by `save_json_checkpoint`.

**Arguments**:
- `checkpoint_name` (string): Name of checkpoint (without .json extension)

**Returns**: JSON content if file exists, or `{}` if missing (printed to stdout)

**Performance**: 2-5ms (cat + optional jq validation)

**Exit Codes**:
- `0`: Success (file exists or graceful degradation)
- `1`: Failure (CLAUDE_PROJECT_DIR not set)

**Usage**:
```bash
METADATA=$(load_json_checkpoint "supervisor_metadata")
echo "$METADATA" | jq -r '.topics'
# Output: 4
```

**Graceful Degradation**: Returns empty JSON object `{}` if file missing (no error).

##### `append_jsonl_log(log_name, json_entry)`

Append JSON entry to JSONL (JSON Lines) log file. Each line is a complete JSON object.

**Arguments**:
- `log_name` (string): Name of log file (without .jsonl extension)
- `json_entry` (string): JSON object to append (single line)

**Returns**: Nothing

**Side Effects**:
- Appends JSON line to `.claude/tmp/${log_name}.jsonl`
- Creates file if it doesn't exist

**Performance**: <1ms (echo redirect)

**Exit Codes**:
- `0`: Success
- `1`: Failure (CLAUDE_PROJECT_DIR not set)

**Usage**:
```bash
BENCHMARK='{"phase": "research", "duration_ms": 12500, "timestamp": "2025-11-07T14:30:00Z"}'
append_jsonl_log "benchmarks" "$BENCHMARK"
# File contains newline-separated JSON objects:
# {"phase": "research", "duration_ms": 12500, "timestamp": "2025-11-07T14:30:00Z"}
# {"phase": "plan", "duration_ms": 8500, "timestamp": "2025-11-07T14:32:00Z"}
```

**Use Cases**:
- Benchmark dataset accumulation across subprocess invocations
- Performance metrics logging (timestamped phase durations)
- POC metrics tracking (success criterion validation)

### Complete Workflow Example

```bash
# Block 1: Initialize workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT

# CLAUDE_PROJECT_DIR detected once and cached (6ms)

# Block 2: Research phase
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "coordinate_$$"  # Fast load (2ms)

# Invoke research supervisor (returns aggregated metadata)
SUPERVISOR_RESULT='{"topics": 4, "reports": ["r1.md", "r2.md"], "summary": "..."}'
save_json_checkpoint "supervisor_metadata" "$SUPERVISOR_RESULT"
append_workflow_state "RESEARCH_COMPLETE" "true"

# Block 3: Plan phase
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "coordinate_$$"

# Load research metadata (95% context reduction vs full outputs)
METADATA=$(load_json_checkpoint "supervisor_metadata")
REPORTS=$(echo "$METADATA" | jq -r '.reports[]')

# Log phase benchmark
BENCHMARK='{"phase": "research", "duration_ms": 12500, "context_tokens": 1000}'
append_jsonl_log "workflow_benchmarks" "$BENCHMARK"

# Check accumulated state
echo "Research complete: ${RESEARCH_COMPLETE}"  # Output: true
```

### Decision Criteria Reference

**Use File-Based State When**:
1. Recalculation cost >30ms (measured performance improvement)
2. State is non-deterministic (research findings, user input)
3. State accumulates across subprocess boundaries (Phase 3 benchmarks)
4. Context reduction requires metadata aggregation (supervisor outputs)
5. Cross-invocation persistence needed (resumable workflows)
6. Phase dependencies require prior outputs (Phase 3 depends on Phase 2)
7. Success criteria validation needs evidence (timestamped metrics)

**Use Stateless Recalculation When**:
1. Recalculation is fast (<10ms) and deterministic
2. State is ephemeral (temporary variables)
3. No subprocess boundaries (single bash block)
4. Canonical source exists elsewhere (library-api.md)
5. File-based overhead exceeds recalculation cost

**Critical State Items** (7/10 analyzed items use file-based state):
- Supervisor metadata (95% context reduction)
- Benchmark datasets (accumulation across 10 invocations)
- Implementation supervisor state (40-60% time savings tracking)
- Testing supervisor state (lifecycle coordination)
- Migration progress (resumable, audit trail)
- Performance benchmarks (phase dependencies)
- POC metrics (timestamped validation)

**Performance Comparison**:
- `init_workflow_state`: 6ms (includes git rev-parse)
- `load_workflow_state`: 2ms (file read) = **67% faster than init**
- `save_json_checkpoint`: 5-10ms (atomic write)
- `load_json_checkpoint`: 2-5ms (cat + validation)
- `append_workflow_state`: <1ms (echo)
- `append_jsonl_log`: <1ms (echo)

---

## Related Documentation

- [Overview](overview.md) - Purpose, quick index, core utilities
- [State Machine](library-api-state-machine.md) - Workflow classification and scope detection
- [Utilities](library-api-utilities.md) - Agent support, workflow support, analysis, and complete library list
- [Coordinate State Management](../architecture/coordinate-state-management-overview.md) - State management architecture
