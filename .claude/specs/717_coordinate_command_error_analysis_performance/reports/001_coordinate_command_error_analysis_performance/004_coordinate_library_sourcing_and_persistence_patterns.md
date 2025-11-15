# Coordinate Library Sourcing and Persistence Patterns

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Library sourcing patterns and state persistence across Task tool boundaries in /coordinate command
- **Report Type**: codebase analysis
- **Overview Report**: [Coordinate Command Error Analysis and Performance Improvement](./OVERVIEW.md)

## Executive Summary

The /coordinate command implements a sophisticated state persistence architecture to maintain workflow state across Task tool invocations and bash block boundaries. The core pattern uses file-based state persistence (GitHub Actions model) combined with systematic library re-sourcing in every bash block, achieving reliable state management despite subprocess isolation. The comment "Re-load workflow state (needed after Task invocation)" reflects a validated architectural pattern where each bash block executes as a separate subprocess, requiring explicit state file loading and library re-sourcing to restore functions and variables.

## Findings

### 1. Bash Block Execution Model: Subprocess Isolation

**Core Architecture** (from `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`):

Each bash block in Claude Code command files runs as a **separate subprocess**, not a subshell. This has critical implications:

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
┌────────── Task Tool Invocation ──┐
│ Agent executes in separate       │
│ context - NO access to parent    │
│ subprocess variables/functions   │
└──────────────────────────────────┘
    ↓
┌────────── Bash Block 2 ──────────┐
│ PID: 12346 (NEW PROCESS)        │
│ - Re-source libraries            │
│ - Load state from files          │
│ - Process data                   │
│ - Exit subprocess                │
└──────────────────────────────────┘
```

**What Does NOT Persist Across Blocks**:
- Environment variables (exports lost)
- Bash functions (must re-source libraries)
- Process ID (`$$`) changes between blocks
- Trap handlers (fire at block exit, not workflow exit)
- Current directory (may reset)

**What DOES Persist**:
- Files written to filesystem
- State files (via state-persistence.sh)
- Workflow ID (saved to fixed location file)
- Directories (created with `mkdir -p`)

### 2. State Persistence Library Architecture

**File-Based Persistence** (`/home/benjamin/.config/.claude/lib/state-persistence.sh`):

The state-persistence.sh library implements the GitHub Actions pattern (`$GITHUB_OUTPUT`, `$GITHUB_STATE`) for selective file-based state management:

```bash
# Initialize workflow state (Block 1 only)
STATE_FILE=$(init_workflow_state "coordinate_$$")
# Creates: /path/.claude/tmp/workflow_12345.sh

# Append state (GitHub Actions pattern)
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
# Appends: export WORKFLOW_ID="value"
#          export WORKFLOW_SCOPE="value"

# Load workflow state (Blocks 2+)
load_workflow_state "coordinate_$$"
# Sources state file to restore exported variables
```

**Performance Characteristics** (from state-persistence.sh:43-47):
- CLAUDE_PROJECT_DIR detection: 50ms (git rev-parse) → 15ms (file read) = 70% improvement
- JSON checkpoint write: 5-10ms (atomic write with temp file + mv)
- JSON checkpoint read: 2-5ms (cat + jq validation)
- Graceful degradation overhead: <1ms (file existence check)

**Critical State Items Using File-Based Persistence** (lines 49-56):
1. Supervisor metadata (P0): 95% context reduction
2. Benchmark dataset (P0): Phase 3 accumulation across 10 subprocess invocations
3. Implementation supervisor state (P0): 40-60% time savings via parallel execution tracking
4. Testing supervisor state (P0): Lifecycle coordination across sequential stages
5. Migration progress (P1): Resumable, audit trail for multi-hour migrations
6. Performance benchmarks (P1): Phase 3 dependency on Phase 2 data
7. POC metrics (P1): Success criterion validation

### 3. Coordinate Command State Management Pattern

**Initialization Block** (`/home/benjamin/.config/.claude/commands/coordinate.md:99-183`):

```bash
# Source state machine and state persistence libraries
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Save workflow ID and description to state
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "WORKFLOW_DESCRIPTION" "$SAVED_WORKFLOW_DESC"

# CRITICAL: Save state ID file path for bash block persistence
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
append_workflow_state "COORDINATE_STATE_ID_FILE" "$COORDINATE_STATE_ID_FILE"

# Save state machine configuration to workflow state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

**State Reloading Pattern** (`coordinate.md:216-240`):

The comment "Re-load workflow state (needed after Task invocation)" appears before this critical section:

```bash
# Re-load workflow state (needed after Task invocation)
COORDINATE_DESC_PATH_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"
if [ -f "$COORDINATE_DESC_PATH_FILE" ]; then
  COORDINATE_DESC_FILE=$(cat "$COORDINATE_DESC_PATH_FILE")
  SAVED_WORKFLOW_DESC=$(cat "$COORDINATE_DESC_FILE" 2>/dev/null || echo "")
fi

# Re-source required libraries
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"
```

**Why This Pattern Exists**:

1. **Task Tool Creates New Subprocess**: When the Task tool invokes an agent, it runs in a separate context with no access to parent process variables or functions

2. **Bash Block After Task Tool = New Subprocess**: The bash block following a Task invocation runs as a brand new subprocess (different PID)

3. **Everything Must Be Restored**:
   - Functions lost → Re-source libraries
   - Variables lost → Load state file
   - State ID needed → Read from fixed location file

### 4. Library Sourcing Order and Dependency Management

**Standard 15: Library Sourcing Order** (`coordinate.md:531-564`):

Every bash block in coordinate follows this precise order:

```bash
set +H  # CRITICAL: Disable history expansion

# Step 1: Re-detect CLAUDE_PROJECT_DIR (if needed)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Step 2: Source state machine and persistence FIRST
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 3: Load workflow state BEFORE other libraries
# CRITICAL: This must happen BEFORE other library sourcing to prevent
# variables like WORKFLOW_SCOPE from being reset to defaults
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 4: Source error handling and verification libraries
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 5: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/context-pruning.sh"
source "${LIB_DIR}/dependency-analyzer.sh"
```

**Why Order Matters** (from `bash-block-execution-model.md:287-320`):

The ordering prevents a critical bug where library variables are reset when re-sourced:

- **Problem**: Libraries that define `WORKFLOW_SCOPE=""` directly will overwrite values loaded from state file
- **Solution**: Pattern 5 (Conditional Variable Initialization) uses `${VAR:-default}` syntax to preserve loaded values

Example from workflow-state-machine.sh:
```bash
# ✓ RECOMMENDED: Conditional initialization (preserves loaded values)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
CURRENT_STATE="${CURRENT_STATE:-initialize}"
```

If state is loaded BEFORE library sourcing, and libraries use conditional initialization, the loaded values are preserved.

### 5. Fixed Semantic Filenames Pattern

**Pattern 1: Fixed Semantic Filenames** (`bash-block-execution-model.md:163-191`):

The coordinate command uses fixed semantic filenames instead of PID-based filenames:

```bash
# ❌ ANTI-PATTERN: PID-based filename
STATE_FILE="/tmp/workflow_$$.sh"  # $$ changes across blocks

# ✓ COORDINATE PATTERN: Fixed semantic filename
WORKFLOW_ID="coordinate_$(date +%s)"  # Timestamp-based ID
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"  # Save ID to fixed location

# In subsequent blocks:
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")  # Read from fixed location
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

**Benefits**:
- State file is discoverable across subprocess boundaries
- Workflow ID persists in predictable location
- Multiple workflows can run concurrently (timestamp-based IDs)
- No race conditions or file collision

### 6. Verification Checkpoints for State Persistence

**Standard 0: Execution Enforcement** (`coordinate.md:161-180`):

Coordinate implements fail-fast verification after every critical state operation:

```bash
# VERIFICATION CHECKPOINT: Verify state ID file created successfully
verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created" 1
}

# Verify state variable persisted
verify_state_variable "WORKFLOW_ID" || {
  handle_state_error "CRITICAL: WORKFLOW_ID not persisted to state" 1
}

verify_state_variable "WORKFLOW_DESCRIPTION" || {
  handle_state_error "CRITICAL: WORKFLOW_DESCRIPTION not persisted to state" 1
}

verify_state_variable "COORDINATE_STATE_ID_FILE" || {
  handle_state_error "CRITICAL: COORDINATE_STATE_ID_FILE not persisted to state" 1
}
```

**verify_state_variable Implementation** (`/home/benjamin/.config/.claude/lib/verification-helpers.sh:223-280`):

```bash
verify_state_variable() {
  local var_name="$1"

  # Defensive check: STATE_FILE must be set
  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR [verify_state_variable]: STATE_FILE not set"
    return 1
  fi

  # Main verification: Check for variable in state file with correct export format
  if grep -q "^export ${var_name}=" "$STATE_FILE" 2>/dev/null; then
    return 0  # Success
  else
    # Comprehensive diagnostic output on failure
    echo "ERROR [verify_state_variable]: Variable not found in state file"
    echo "  Variable name: $var_name"
    echo "  State file: $STATE_FILE"
    echo ""
    echo "EXPECTED FORMAT:"
    echo "  export ${var_name}=\"value\""
    return 1
  fi
}
```

This ensures that state persistence succeeds before proceeding to the next phase.

### 7. Comparison with /orchestrate Command

**Orchestrate State Pattern** (`/home/benjamin/.config/.claude/commands/orchestrate.md:86-116`):

The /orchestrate command uses a similar but simpler pattern:

```bash
# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "orchestrate_$$")
trap "rm -f '$STATE_FILE'" EXIT  # Cleanup trap

# Save workflow ID
append_workflow_state "WORKFLOW_ID" "orchestrate_$$"

# In subsequent blocks:
load_workflow_state "orchestrate_$$"
```

**Key Differences**:

| Feature | /coordinate | /orchestrate |
|---------|-------------|--------------|
| **State ID Persistence** | Fixed location file + timestamp ID | Uses $$ (PID-based) |
| **Workflow ID File** | `coordinate_state_id.txt` | Not used (relies on consistent `$$` usage) |
| **Verification Checkpoints** | Extensive (verify_state_variable after each append) | Basic (single check after sm_init) |
| **Library Sourcing Order** | Strict 5-step order documented | Similar but less formalized |
| **Cleanup Trap** | Only in completion function | Set in initialization (may fire early) |

**Why Coordinate's Pattern is More Robust**:

1. **State ID File**: Guarantees workflow ID availability across all subprocess boundaries
2. **Verification Checkpoints**: Catches state persistence failures immediately with diagnostics
3. **Documented Ordering**: Prevents subtle bugs from library variable resets
4. **Delayed Cleanup Trap**: Avoids premature state file deletion

### 8. Best Practices from Infrastructure

**Orchestration Best Practices** (`/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:1-27`):

The guide recommends /coordinate as the production-ready orchestration command due to these architectural strengths:

- **Wave-Based Parallel Execution**: 40-60% time savings
- **Workflow Scope Auto-Detection**: 4 workflow types
- **Concise Verification Formatting**: 90% token reduction at checkpoints
- **Pure Orchestration Architecture**: No command chaining, only agent delegation

**Context Budget** (lines 165-171):
```
Phase 0: 500-1,000 tokens (4%)
Phase 1: 600-1,200 tokens (6%)
Phase 2: 800-1,200 tokens (5%)
Phase 3: 1,500-2,000 tokens (8%)
Phase 4-7: 200-500 tokens each (2% each)
Total: 21% context usage target
```

State persistence enables this efficient context budget by avoiding redundant recalculation and passing only metadata between phases.

## Recommendations

### 1. Document the State Reloading Pattern Explicitly

**Current State**: The comment "Re-load workflow state (needed after Task invocation)" is accurate but terse.

**Recommendation**: Add a comprehensive comment block explaining the subprocess isolation pattern:

```bash
# ============================================================================
# CRITICAL: State Reloading After Task Tool Invocation
# ============================================================================
# WHY THIS IS NEEDED:
#   1. Each bash block runs as a separate subprocess (new PID)
#   2. Task tool invocations run in separate context
#   3. ALL environment variables and bash functions are lost across blocks
#   4. State must be explicitly restored from persistent files
#
# WHAT GETS RESTORED:
#   - Workflow variables (WORKFLOW_ID, WORKFLOW_SCOPE, etc.)
#   - Bash functions (via library re-sourcing)
#   - State machine configuration (CURRENT_STATE, TERMINAL_STATE)
#
# ORDERING REQUIREMENTS:
#   1. Re-source state-persistence.sh FIRST (provides load_workflow_state)
#   2. Load state from file BEFORE other library sourcing
#   3. Source other libraries (preserves loaded state via conditional init)
#
# See: .claude/docs/concepts/bash-block-execution-model.md
# ============================================================================
```

This would help future maintainers understand why this pattern exists and prevent accidental removal.

### 2. Standardize State ID File Pattern Across All Orchestrators

**Current Variance**:
- `/coordinate`: Uses `coordinate_state_id.txt` with timestamp-based workflow IDs
- `/orchestrate`: Uses PID-based IDs without persistent state ID file
- `/supervise`: Pattern varies

**Recommendation**: Standardize all orchestrators to use the coordinate pattern:

```bash
# Standard pattern for all orchestrators
COMMAND_NAME="coordinate"  # or "orchestrate", "supervise"
WORKFLOW_ID="${COMMAND_NAME}_$(date +%s)"
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/${COMMAND_NAME}_state_id.txt"

# Save to fixed location
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"

# Load in subsequent blocks
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
```

**Benefits**:
- Consistent pattern across all orchestration commands
- More robust than PID-based IDs (survives subprocess transitions)
- Enables multiple concurrent workflows
- Predictable cleanup and debugging

### 3. Create Library Sourcing Order Standard Documentation

**Current State**: Standard 15 exists in coordinate.md but isn't extracted to standalone documentation.

**Recommendation**: Create `.claude/docs/reference/library-sourcing-order.md` documenting:

1. **Why Order Matters**: Prevent variable reset bugs
2. **Standard 5-Step Pattern**: State persistence → Load state → Error handling → Additional libraries
3. **Verification Requirements**: Check critical functions after sourcing
4. **Anti-Patterns to Avoid**: Direct variable initialization in libraries

Reference this from all orchestration commands and the bash block execution model guide.

### 4. Add Fail-Fast Validation to load_workflow_state

**Current Implementation** (state-persistence.sh:187-229):

The function has two modes:
- `is_first_block=true`: Graceful initialization if missing
- `is_first_block=false`: Fail-fast with diagnostic (Spec 672 Phase 3)

**Recommendation**: Coordinate should explicitly use fail-fast mode in all blocks after initialization:

```bash
# Block 1: Initialization
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Blocks 2+: Fail-fast mode (expose bugs immediately)
load_workflow_state "$WORKFLOW_ID" false || {
  echo "CRITICAL: State persistence failure detected"
  echo "Cannot proceed without workflow state"
  exit 2  # Exit code 2 = configuration error
}
```

**Benefits**:
- Exposes state persistence bugs immediately
- Prevents silent degradation from missing state
- Clear diagnostic output for troubleshooting
- Distinguishes expected vs unexpected missing state files

### 5. Document Source Guards Pattern for Library Authors

**Current State**: Libraries implement source guards but pattern isn't documented for library authors.

**Recommendation**: Add to library development guide:

```bash
# Standard source guard pattern for all libraries
# Prevents duplicate execution when library is sourced multiple times

if [ -n "${LIBRARY_NAME_SOURCED:-}" ]; then
  return 0  # Already sourced, skip re-execution
fi
export LIBRARY_NAME_SOURCED=1

# Library initialization code follows...
```

**Benefits**:
- Efficient re-sourcing (guards prevent redundant execution)
- Safe to source multiple times
- Standard pattern for all .claude/lib/*.sh files

### 6. Add Performance Monitoring for State Operations

**Current State**: state-persistence.sh documents performance characteristics but doesn't measure them in production.

**Recommendation**: Add optional performance monitoring:

```bash
# Enable with DEBUG_PERFORMANCE=1
if [[ "${DEBUG_PERFORMANCE:-0}" == "1" ]]; then
  START_TIME=$(date +%s%N)
  load_workflow_state "$WORKFLOW_ID"
  END_TIME=$(date +%s%N)
  DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
  echo "PERF: State loading: ${DURATION_MS}ms" >&2
fi
```

This would help validate the documented 70% performance improvement claims and identify performance regressions.

## References

### Primary Sources
- `/home/benjamin/.config/.claude/commands/coordinate.md:99-183` - State initialization pattern
- `/home/benjamin/.config/.claude/commands/coordinate.md:216-240` - State reloading after Task tool
- `/home/benjamin/.config/.claude/commands/coordinate.md:531-564` - Library sourcing order
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:1-393` - State persistence library implementation
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh:223-280` - State variable verification
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:24-825` - State machine variables and exports

### Documentation
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-400` - Subprocess isolation patterns
- `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:1-300` - Production orchestration patterns
- `/home/benjamin/.config/.claude/docs/guides/state-machine-migration-guide.md:33-1002` - State machine migration patterns

### Comparison Sources
- `/home/benjamin/.config/.claude/commands/orchestrate.md:1-300` - Alternative state pattern (PID-based)
- `/home/benjamin/.config/.claude/lib/library-sourcing.sh:1-122` - Unified library sourcing helper
