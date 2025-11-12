# Bash Block Execution Model and Function Persistence Research Report

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Bash Block Execution Model and Function Persistence
- **Report Type**: codebase analysis
- **Complexity Level**: 2

## Executive Summary

Each bash block in Claude Code commands executes as a separate subprocess (not subshell), causing complete memory isolation between blocks. Functions defined in one bash block are lost in the next, requiring libraries to be re-sourced in every block. Source guards in libraries make multiple sourcing safe and efficient by preventing redundant execution. State persistence across bash blocks requires explicit file-based mechanisms (workflow state files, state persistence library) since environment variables and exports do not survive subprocess boundaries. The bash block execution model is a foundational constraint that shaped the entire state-based orchestration architecture.

## Findings

### 1. Subprocess Isolation Architecture

**Process Architecture** (.claude/docs/concepts/bash-block-execution-model.md:10-33):

Each bash block runs as a completely separate process with a new Process ID ($$):

```
Claude Code Session
    ↓
Command Execution (coordinate.md)
    ↓
┌────────── Bash Block 1 ──────────┐
│ PID: 12345                       │
│ - Source libraries               │
│ - Initialize state               │
│ - Save to files                  │
│ - Exit subprocess                │
└──────────────────────────────────┘
    ↓ (subprocess terminates)
┌────────── Bash Block 2 ──────────┐
│ PID: 12346 (NEW PROCESS)        │
│ - Re-source libraries            │
│ - Load state from files          │
│ - Process data                   │
│ - Exit subprocess                │
└──────────────────────────────────┘
```

**Key Characteristics** (.claude/docs/concepts/bash-block-execution-model.md:36-48):
- Process ID (`$$`) changes between blocks
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Trap handlers fire at block exit, not workflow exit
- Only files written to disk persist across blocks

**Validation Evidence** (.claude/docs/concepts/bash-block-execution-model.md:72-159):

The documentation includes a comprehensive validation test demonstrating:
1. Process IDs differ between blocks
2. Environment variables lost despite export
3. Files are the ONLY reliable cross-block communication channel

Expected output confirms subprocess isolation:
```
✓ CONFIRMED: Process IDs differ (12345 vs 12346)
  Each bash block runs as separate subprocess

Block 1: TEST_VAR=set_in_block_1
Block 2: TEST_VAR=unset

Block 1: Wrote to file
Block 2: Read from file: data_from_block_1

✓ Files are the ONLY reliable cross-block communication channel
```

### 2. Function Persistence and Re-Sourcing Requirements

**Functions Do NOT Persist** (.claude/docs/concepts/bash-block-execution-model.md:60-68):

| Item | Reason | Consequence |
|------|--------|-------------|
| Bash functions | Not inherited | Must re-source library files |
| Environment variables | New process | `export VAR=value` lost |
| Process ID (`$$`) | New PID per block | Cannot use `$$` for cross-block IDs |

**Library Re-Sourcing Pattern** (.claude/docs/concepts/bash-block-execution-model.md:250-286):

Every bash block MUST re-source all required libraries:

```bash
# At start of EVERY bash block:
set +H  # CRITICAL: Disable history expansion

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

**Critical Requirements**:
1. MUST include `set +H` to prevent history expansion errors
2. MUST include unified-logger.sh for emit_progress and display_brief_summary
3. Source guards make multiple sourcing safe and efficient

### 3. Source Guards and Library Protection

**Source Guard Pattern** (.claude/lib/workflow-state-machine.sh:20-24):

```bash
# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_STATE_MACHINE_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_STATE_MACHINE_SOURCED=1
```

**Purpose of Source Guards**:
1. Prevent duplicate execution of initialization code
2. Make multiple sourcing safe across bash blocks
3. Improve performance (skip redundant operations)
4. Protect against infinite recursion in library dependencies

**Source Guards in Critical Libraries**:

- **workflow-state-machine.sh:20-24**: `WORKFLOW_STATE_MACHINE_SOURCED` guard
- **state-persistence.sh:9-12**: `STATE_PERSISTENCE_SOURCED` guard

Both libraries use identical source guard pattern to prevent multiple execution while allowing safe re-sourcing across subprocess boundaries.

### 4. State Persistence Across Bash Blocks

**State Persistence Mechanisms** (.claude/docs/concepts/bash-block-execution-model.md:49-68):

| Persists Across Blocks ✓ | Persistence Method | Example |
|------|-------------------|---------|
| Files | Written to filesystem | `echo "data" > /tmp/state.txt` |
| State files | Via state-persistence.sh | `append_workflow_state "KEY" "value"` |
| Workflow ID | Fixed location file | `${HOME}/.claude/tmp/coordinate_state_id.txt` |

**GitHub Actions-Style State Persistence** (.claude/lib/state-persistence.sh:1-80):

The state-persistence.sh library implements a GitHub Actions pattern (`$GITHUB_OUTPUT`, `$GITHUB_STATE`):

```bash
# Initialize workflow state (Block 1 only)
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Load workflow state (Blocks 2+)
load_workflow_state "coordinate_$$"

# Append state (GitHub Actions pattern)
append_workflow_state "RESEARCH_COMPLETE" "true"
```

**Performance Characteristics** (.claude/lib/state-persistence.sh:41-44):
- CLAUDE_PROJECT_DIR detection: 50ms (git rev-parse) → 15ms (file read) = 70% improvement
- JSON checkpoint write: 5-10ms (atomic write)
- JSON checkpoint read: 2-5ms
- Graceful degradation overhead: <1ms

**Critical State Items Using File-Based Persistence** (.claude/lib/state-persistence.sh:47-55):
1. Supervisor metadata (P0): 95% context reduction
2. Benchmark dataset (P0): Phase 3 accumulation across subprocesses
3. Implementation supervisor state (P0): Parallel execution tracking
4. Testing supervisor state (P0): Lifecycle coordination
5. Migration progress (P1): Resumable workflows
6. Performance benchmarks (P1): Phase dependencies
7. POC metrics (P1): Success criterion validation

### 5. Conditional Variable Initialization Pattern

**Problem Statement** (.claude/docs/concepts/bash-block-execution-model.md:287-295):

Library variables are reset when re-sourced across subprocess boundaries, even when values are loaded from state files.

**Solution: Conditional Initialization** (.claude/docs/concepts/bash-block-execution-model.md:295-315):

Use bash parameter expansion `${VAR:-default}` to preserve existing values:

```bash
# ❌ ANTI-PATTERN: Direct initialization (overwrites loaded values)
WORKFLOW_SCOPE=""
WORKFLOW_DESCRIPTION=""
CURRENT_STATE="initialize"

# ✓ RECOMMENDED: Conditional initialization (preserves loaded values)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
CURRENT_STATE="${CURRENT_STATE:-initialize}"
```

**When to Use** (.claude/docs/concepts/bash-block-execution-model.md:317-327):
- Variables that persist across bash block boundaries
- Integration with state persistence library
- State variables loaded before library re-sourcing
- Variables needing different values in different contexts

**When NOT to Use** (.claude/docs/concepts/bash-block-execution-model.md:328-333):
- Constants (use `readonly` instead)
- Arrays (parameter expansion not supported: `declare -ga ARRAY=()`)
- One-time initialization inside source guards
- Variables that should always reset

**Real Implementation** (.claude/lib/workflow-state-machine.sh:66-79):

```bash
# Current state (with default fallback)
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"

# Terminal state (with default fallback)
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"

# Workflow configuration (preserve if set, initialize to empty if unset)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"

# Arrays cannot use conditional initialization
declare -ga COMPLETED_STATES=()
```

**Real-World Use Case** (.claude/docs/concepts/bash-block-execution-model.md:352-369):

```bash
# Bash Block 1: Initialize workflow
source .claude/lib/workflow-state-machine.sh  # WORKFLOW_SCOPE="" (or "${WORKFLOW_SCOPE:-}")
sm_init "Research authentication" "coordinate"  # Sets WORKFLOW_SCOPE="research-and-plan"
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"

# Bash Block 2: Research phase (NEW SUBPROCESS)
load_workflow_state "$WORKFLOW_ID"  # Restores WORKFLOW_SCOPE="research-and-plan"
source .claude/lib/workflow-state-machine.sh  # With conditional init: WORKFLOW_SCOPE preserved!
                                               # Without: WORKFLOW_SCOPE="" (BUG!)
```

Conditional initialization fixes the bug where WORKFLOW_SCOPE was reset to empty string after being loaded from state file, causing workflows to incorrectly proceed to unintended phases (Spec 653).

### 6. Critical Libraries for Re-Sourcing

**Core State Management Libraries** (.claude/docs/concepts/bash-block-execution-model.md:406-417):

1. **workflow-state-machine.sh**: State machine operations (sm_init, sm_transition, sm_get_state)
2. **state-persistence.sh**: GitHub Actions-style state file operations
3. **workflow-initialization.sh**: Path detection and initialization

**Error Handling and Logging Libraries** (.claude/docs/concepts/bash-block-execution-model.md:417-422):

4. **error-handling.sh**: Fail-fast error handling
5. **unified-logger.sh**: Progress markers and completion summaries (emit_progress, display_brief_summary)
6. **verification-helpers.sh**: File creation verification

**Library Requirements by Command Type** (.claude/docs/concepts/bash-block-execution-model.md:424-433):

- **Orchestration Commands** (/coordinate, /orchestrate, /supervise): ALL six libraries required
- **Simple Commands** (single bash block): Only libraries needed for specific operations
- **State-Based Commands**: workflow-state-machine.sh + state-persistence.sh + workflow-initialization.sh + unified-logger.sh

**Common Errors from Missing Libraries** (.claude/docs/concepts/bash-block-execution-model.md:435-444):

| Missing Library | Error Symptom | Impact |
|---|---|---|
| unified-logger.sh | `emit_progress: command not found` | Missing progress markers (degraded UX) |
| unified-logger.sh | `display_brief_summary: command not found` | Missing completion summary (degraded UX) |
| error-handling.sh | `handle_state_error: command not found` | Unhandled errors, unclear failure messages |
| workflow-state-machine.sh | `sm_transition: command not found` | State transitions fail, workflow halts |
| state-persistence.sh | `load_workflow_state: command not found` | Cannot restore state across blocks |

### 7. COMPLETED_STATES Array Persistence

**Array Persistence Challenge** (.claude/lib/workflow-state-machine.sh:88-148):

The `COMPLETED_STATES` array (state machine history) must persist across bash blocks. Arrays cannot use standard exports, requiring JSON serialization.

**Save Function** (.claude/lib/workflow-state-machine.sh:122-148):

```bash
save_completed_states_to_state() {
  # Serialize array to JSON (handle empty array explicitly)
  local completed_states_json
  if [ "${#COMPLETED_STATES[@]}" -eq 0 ]; then
    completed_states_json="[]"
  else
    completed_states_json=$(printf '%s\n' "${COMPLETED_STATES[@]}" | jq -R . | jq -s .)
  fi

  # Save to workflow state
  append_workflow_state "COMPLETED_STATES_JSON" "$completed_states_json"
  append_workflow_state "COMPLETED_STATES_COUNT" "${#COMPLETED_STATES[@]}"
}
```

**Load Function** (.claude/lib/workflow-state-machine.sh:179-212):

```bash
load_completed_states_from_state() {
  # Defensive: Initialize empty array first
  COMPLETED_STATES=()

  # Check if COMPLETED_STATES_JSON exists in state
  if [ -z "${COMPLETED_STATES_JSON:-}" ]; then
    return 0  # Not an error - initial workflow won't have completed states
  fi

  # Reconstruct array from JSON
  mapfile -t COMPLETED_STATES < <(echo "$COMPLETED_STATES_JSON" | jq -r '.[]' 2>/dev/null || true)

  # Validate against count
  if [ -n "${COMPLETED_STATES_COUNT:-}" ]; then
    if [ "${#COMPLETED_STATES[@]}" -ne "$COMPLETED_STATES_COUNT" ]; then
      echo "WARNING: COMPLETED_STATES count mismatch" >&2
    fi
  fi
}
```

**Automatic Loading** (.claude/lib/workflow-state-machine.sh:664-667):

Library automatically restores COMPLETED_STATES on re-sourcing:

```bash
# Conditionally load COMPLETED_STATES from state on library re-sourcing
if [ "${#COMPLETED_STATES[@]}" -eq 0 ] && [ -n "${COMPLETED_STATES_JSON:-}" ]; then
  load_completed_states_from_state
fi
```

This enables seamless state history tracking across bash subprocess boundaries.

### 8. Anti-Patterns to Avoid

**Anti-Pattern 1: Using `$$` for Cross-Block State** (.claude/docs/concepts/bash-block-execution-model.md:457-472):

Process ID changes per block, making `$$`-based filenames inaccessible:

```bash
# Block 1
STATE_FILE="/tmp/workflow_$$.sh"
echo "export VAR=value" > "$STATE_FILE"
# Creates: /tmp/workflow_12345.sh

# Block 2 (different PID)
STATE_FILE="/tmp/workflow_$$.sh"  # Now /tmp/workflow_12346.sh
source "$STATE_FILE"  # ✗ File not found
```

**Fix**: Use Pattern 1 (Fixed Semantic Filenames) from documentation.

**Anti-Pattern 2: Assuming Exports Work Across Blocks** (.claude/docs/concepts/bash-block-execution-model.md:474-489):

Environment variables don't persist across subprocess boundaries:

```bash
# Block 1
export WORKFLOW_ID="coord_123"
export CURRENT_STATE="research"

# Block 2
echo "State: $CURRENT_STATE"  # ✗ Empty (export lost)
```

**Fix**: Use state persistence library or write to files.

**Anti-Pattern 3: Premature Trap Handlers** (.claude/docs/concepts/bash-block-execution-model.md:491-505):

Traps fire at block exit, not workflow exit:

```bash
# Block 1 (early in workflow)
trap 'cleanup_temp_files' EXIT

# Block 2 needs temp files
# ✗ Files already deleted by Block 1's EXIT trap
```

**Fix**: Only set cleanup traps in final completion function.

**Anti-Pattern 4: Code Review Without Runtime Testing** (.claude/docs/concepts/bash-block-execution-model.md:507-523):

Subprocess isolation issues only appear at runtime:

```bash
# Looks correct in code review:
export REPORT_PATHS=("report1.md" "report2.md")

# Next block attempts to use it
for report in "${REPORT_PATHS[@]}"; do  # ✗ Array empty at runtime
  echo "$report"
done
```

**Fix**: Always test bash block sequences with actual subprocess execution.

### 9. Integration with State-Based Orchestration

**Foundational Constraint** (.claude/docs/concepts/bash-block-execution-model.md:599-602):

The bash block execution model is a foundational constraint for the state-based orchestration architecture. State transitions must be persisted to files because bash blocks cannot share memory.

**State Machine Coordination** (.claude/docs/concepts/bash-block-execution-model.md:604-618):

```bash
# Block 1: Transition from research to plan
sm_transition "$STATE_PLAN"
append_workflow_state "CURRENT_STATE" "$STATE_PLAN"

# Block 2: Load current state
load_workflow_state "$WORKFLOW_ID"
if [ "$CURRENT_STATE" = "$STATE_PLAN" ]; then
  echo "Executing planning phase"
fi
```

**Checkpoint Recovery** (.claude/docs/concepts/bash-block-execution-model.md:620-637):

Checkpoint files enable workflow resume across bash block boundaries:

```bash
# Block N-1: Save checkpoint before complex operation
save_checkpoint "research" "phase_complete" '{
  "reports_created": 3,
  "verification_status": "success"
}'

# Block N: Resume from checkpoint if operation failed
CHECKPOINT=$(load_checkpoint "research" "phase_complete")
if [ -n "$CHECKPOINT" ]; then
  REPORTS_CREATED=$(echo "$CHECKPOINT" | jq -r '.reports_created')
  echo "Resuming: $REPORTS_CREATED reports already created"
fi
```

### 10. Historical Context and Validation

**Discovery History** (.claude/docs/concepts/bash-block-execution-model.md:710-717):

These patterns were discovered and validated through:

- **Spec 620**: Six fixes for bash history expansion errors, leading to discovery of subprocess isolation (100% test pass rate achieved)
- **Spec 630**: State persistence architecture, fixing report path loss across blocks (40+ fixes applied)

**Key Lesson Learned** (.claude/docs/concepts/bash-block-execution-model.md:717-719):

Code review alone is insufficient for bash block sequences. Runtime testing with actual subprocess execution is mandatory to catch subprocess isolation issues.

## Recommendations

### 1. Library Re-Sourcing Standard Practice

**Recommendation**: Enforce library re-sourcing pattern in all multi-block commands.

**Rationale**: Functions are lost across bash block boundaries due to subprocess isolation. Re-sourcing all critical libraries in every bash block is not optional - it is a mandatory requirement for function availability.

**Implementation**:
- Add library re-sourcing template to command development documentation
- Require `set +H` at start of every bash block
- Include all six critical libraries in orchestration commands
- Use source guards in all library files to make multiple sourcing safe

**Verification**:
- Manual testing across multiple bash blocks
- Check for "command not found" errors in workflows
- Validate source guards in all libraries

### 2. State Persistence as Default Pattern

**Recommendation**: Use state persistence library (state-persistence.sh) as default for cross-block state management.

**Rationale**: Exports and environment variables do not persist across subprocess boundaries. File-based state persistence is the ONLY reliable mechanism for state sharing between bash blocks.

**Implementation**:
- Initialize workflow state in first bash block via `init_workflow_state()`
- Load workflow state in subsequent blocks via `load_workflow_state()`
- Append state variables via `append_workflow_state()` instead of export
- Use JSON checkpoints for structured data (supervisor metadata, benchmark datasets)

**Benefits**:
- 70% performance improvement for CLAUDE_PROJECT_DIR detection
- Reliable state sharing across subprocess boundaries
- Graceful degradation when state files missing
- GitHub Actions pattern familiarity

### 3. Conditional Variable Initialization in Libraries

**Recommendation**: Apply conditional initialization pattern (`${VAR:-default}`) to all state variables in library files.

**Rationale**: Direct initialization in libraries overwrites values loaded from state files before library re-sourcing. Conditional initialization preserves loaded values while allowing default initialization for unset variables.

**Implementation**:
- Review all state variables in workflow-state-machine.sh
- Convert direct initialization to conditional pattern
- Document pattern in library development guidelines
- Add regression tests for state preservation across blocks

**Exceptions**:
- Constants (use `readonly` instead)
- Arrays (parameter expansion not supported)
- Variables inside source guards (already protected)

**Example**:
```bash
# Instead of:
WORKFLOW_SCOPE=""

# Use:
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
```

### 4. Mandatory Runtime Testing for Bash Block Sequences

**Recommendation**: Require actual subprocess execution testing for all commands with multiple bash blocks.

**Rationale**: Code review cannot detect subprocess isolation issues. Runtime testing is the only way to validate cross-block communication, state persistence, and function availability.

**Implementation**:
- Add runtime testing requirement to command development process
- Create test harness that simulates subprocess execution
- Validate state persistence, library re-sourcing, and function calls
- Document testing procedures in command development guide

**Test Checklist**:
- [ ] State variables persist across blocks
- [ ] Library functions available in all blocks
- [ ] Arrays reconstructed correctly
- [ ] Trap handlers fire at correct time
- [ ] File-based state accessible

### 5. Documentation of Bash Block Execution Model

**Recommendation**: Maintain comprehensive documentation of subprocess isolation patterns as authoritative reference.

**Rationale**: The bash block execution model is a foundational constraint that shaped the entire state-based orchestration architecture. Comprehensive documentation prevents rediscovery of known issues and guides new command development.

**Current Documentation**:
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md (737 lines)
- Validation tests included
- Real-world examples from production commands
- Anti-pattern documentation

**Maintenance**:
- Update documentation when new patterns discovered
- Add validation tests for new patterns
- Cross-reference with state-based orchestration documentation
- Include lessons learned from production issues

## References

### Documentation Files
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-737 - Complete bash block execution model documentation
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md - State-based orchestration architecture built on subprocess isolation

### Library Files
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:20-24 - Source guard pattern
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:66-79 - Conditional variable initialization
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:122-148 - COMPLETED_STATES array save function
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:179-212 - COMPLETED_STATES array load function
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:664-667 - Automatic state loading on re-sourcing
- /home/benjamin/.config/.claude/lib/state-persistence.sh:9-12 - Source guard pattern
- /home/benjamin/.config/.claude/lib/state-persistence.sh:115-142 - init_workflow_state() function
- /home/benjamin/.config/.claude/lib/state-persistence.sh:185-227 - load_workflow_state() with fail-fast validation
- /home/benjamin/.config/.claude/lib/state-persistence.sh:252-262 - append_workflow_state() function
- /home/benjamin/.config/.claude/lib/state-persistence.sh:285-303 - save_json_checkpoint() function
- /home/benjamin/.config/.claude/lib/state-persistence.sh:324-340 - load_json_checkpoint() function

### Command Files
- /home/benjamin/.config/.claude/commands/coordinate.md - Production orchestration command using multi-block pattern

### Related Specifications
- Spec 620: Bash history expansion fixes, subprocess isolation discovery
- Spec 630: State persistence architecture, 40+ fixes for cross-block state
- Spec 653: WORKFLOW_SCOPE reset bug fixed by conditional initialization
- Spec 672: COMPLETED_STATES array persistence implementation

### Key Concepts
- Subprocess isolation (not subshell)
- Source guards for safe re-sourcing
- Conditional variable initialization
- GitHub Actions-style state persistence
- File-based cross-block communication
- Library re-sourcing requirements
