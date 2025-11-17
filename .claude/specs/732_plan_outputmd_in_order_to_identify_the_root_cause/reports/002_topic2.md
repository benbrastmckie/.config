# State-Based Orchestration Architecture Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: State-Based Orchestration Architecture
- **Report Type**: codebase analysis
- **Focus Areas**: State machine patterns, state persistence, library dependencies, path detection

## Executive Summary

The state-based orchestration architecture in `.claude/` uses a formal state machine pattern with selective file-based state persistence. The system consists of two primary libraries: `workflow-state-machine.sh` (state lifecycle management) and `state-persistence.sh` (GitHub Actions-style state files). Path detection relies on `unified-location-detection.sh` with a well-defined precedence order. The architecture achieves 48.9% code reduction and 67% performance improvement through stateless recalculation for fast operations and file-based persistence for critical state items.

## Findings

### 1. State Machine Architecture

**Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (lines 1-100)

**Core Components**:

1. **State Enumeration** (8 explicit states):
   - `initialize` (Phase 0): Setup, scope detection
   - `research` (Phase 1): Research via specialist agents
   - `plan` (Phase 2): Create implementation plans
   - `implement` (Phase 3): Execute implementation
   - `test` (Phase 4): Run test suite
   - `debug` (Phase 5): Debug failures (conditional)
   - `document` (Phase 6): Update documentation (conditional)
   - `complete` (Phase 7): Finalization, cleanup

2. **State Transition Table** (lines 51-60):
   ```bash
   STATE_TRANSITIONS=(
     [initialize]="research"
     [research]="plan,complete"        # Can skip for research-only
     [plan]="implement,complete"       # Can skip for research-and-plan
     [implement]="test"
     [test]="debug,document"           # Conditional: debug if failed
     [debug]="test,complete"           # Retry or give up
     [document]="complete"
     [complete]=""                     # Terminal state
   )
   ```

3. **Key Functions**:
   - `sm_init()` (line 388): Initialize state machine with workflow classification
   - `sm_transition()` (line 602): Validate and execute state transitions
   - `sm_execute()` (line 652): Execute handler for current state
   - `sm_current_state()` (line 596): Query current state
   - `sm_save()`: Save state machine to checkpoint
   - `sm_load()`: Load state machine from checkpoint

**Dependencies** (lines 15-18):
- `workflow-scope-detection.sh`: `detect_workflow_scope()` (primary)
- `workflow-detection.sh`: `detect_workflow_scope()` (fallback)
- `checkpoint-utils.sh`: `save_checkpoint()`, `restore_checkpoint()`
- `detect-project-dir.sh`: Project root detection (line 30)

### 2. State Persistence Patterns

**Location**: `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 1-393)

**Pattern**: GitHub Actions-style state files (inspired by `$GITHUB_OUTPUT`)

**Core Functions**:

1. **`init_workflow_state(workflow_id)`** (lines 117-144):
   - Creates state file at `.claude/tmp/workflow_${workflow_id}.sh`
   - Caches `CLAUDE_PROJECT_DIR` detection (67% performance improvement: 6ms → 2ms)
   - Returns state file path
   - Caller must set EXIT trap for cleanup

2. **`load_workflow_state(workflow_id, is_first_block)`** (lines 187-229):
   - Sources state file to restore variables
   - Two modes (Spec 672 Phase 3):
     - `is_first_block=true`: Graceful initialization if missing
     - `is_first_block=false`: Fail-fast if missing (expose bugs)
   - Performance: ~2ms file read vs ~6ms git command

3. **`append_workflow_state(key, value)`** (lines 254-269):
   - Appends export statement to state file
   - Format: `export KEY="value"`
   - Performance: <1ms per append

4. **`save_json_checkpoint(name, json_data)`** (lines 292-310):
   - Atomic write using temp file + mv
   - Creates `.claude/tmp/${name}.json`
   - Performance: 5-10ms

5. **`load_json_checkpoint(name)`** (lines 331-347):
   - Returns `{}` if missing (graceful degradation)
   - Performance: 2-5ms

**Critical State Items Using File-Based Persistence** (7 items, lines 49-57):
1. Supervisor metadata (95% context reduction)
2. Benchmark dataset (accumulation across 10 subprocess invocations)
3. Implementation supervisor state (40-60% time savings)
4. Testing supervisor state (lifecycle coordination)
5. Migration progress (resumable workflows)
6. Performance benchmarks (phase dependencies)
7. POC metrics (success criteria validation)

**Stateless Recalculation Items** (3 items, lines 58-61):
1. File verification cache (recalculation 10x faster than file I/O)
2. Track detection results (deterministic, <1ms)
3. Guide completeness checklist (no cross-invocation state)

**Decision Criteria** (lines 63-71):
- State accumulates across subprocess boundaries
- Context reduction requires metadata aggregation
- Success criteria validation needs objective evidence
- Resumability is valuable
- State is non-deterministic
- Recalculation is expensive (>30ms)
- Phase dependencies require prior outputs

### 3. Path Detection Mechanism

**Location**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (lines 1-150)

**Core Functions**:

1. **`detect_project_root()`** (lines 88-106):
   - Precedence order:
     1. `CLAUDE_PROJECT_DIR` env var (manual override)
     2. Git repository root (`git rev-parse --show-toplevel`)
     3. Current directory (fallback)
   - Always succeeds (uses fallback)

2. **`detect_specs_directory(project_root)`** (lines 125-150):
   - Precedence order:
     1. `CLAUDE_SPECS_ROOT` env var (test isolation override)
     2. `${project_root}/.claude/specs` (modern convention)
     3. `${project_root}/specs` (legacy convention)
     4. Create `.claude/specs` (default for new projects)
   - Creates directory if needed

**Test Isolation Pattern** (lines 44-69):
```bash
# Required test pattern
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"
trap 'rm -rf /tmp/test_specs_$$ /tmp/test_project_$$' EXIT
```

**Lazy Directory Creation** (lines 11-14):
- Creates artifact directories only when files are written
- Eliminates empty subdirectories (reduced from 400-500 to 0)
- 80% reduction in mkdir calls during location detection

**Concurrency Guarantees** (lines 15-34):
- Atomic topic allocation via file locks
- Eliminates race conditions (40-60% collision rate → 0%)
- Lock hold time: ~2ms increase (acceptable)
- Stress tested: 1000 parallel allocations, 0% collision rate

### 4. Library Loading Order and Dependencies

**Standard Loading Pattern** (from `workflow-state-machine.sh`):

1. **Source Guard** (lines 20-24):
   ```bash
   if [ -n "${WORKFLOW_STATE_MACHINE_SOURCED:-}" ]; then
     return 0
   fi
   export WORKFLOW_STATE_MACHINE_SOURCED=1
   ```
   - Prevents multiple sourcing within same process
   - Each bash block is separate process, needs independent sourcing

2. **Project Directory Detection** (line 30):
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/detect-project-dir.sh"
   ```

3. **Library Dependencies**:
   - `detect-project-dir.sh`: Must load before any path-dependent operations
   - `workflow-scope-detection.sh`: Required for `sm_init()`
   - `checkpoint-utils.sh`: Required for checkpoint operations
   - `state-persistence.sh`: Required for state file operations

**Sourcing Pattern in Commands** (typical coordinate.md pattern):
```bash
# Block 1 (initialization)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

STATE_FILE=$(init_workflow_state "coordinate_$$")

# Block 2+ (subsequent blocks)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
load_workflow_state "coordinate_$$"
```

### 5. Subprocess Isolation Constraint

**Source**: `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (lines 38-108)

**Key Constraint**: Claude Code's Bash tool executes each bash block in a **separate subprocess**, not a subshell.

**Implications**:
- Exports don't persist between bash blocks
- Variables must be recalculated or loaded from state files
- Each block needs independent library sourcing

**Validation Test** (lines 85-94):
```bash
# Block 1
export TEST_VAR="value"
echo "Block 1 PID: $$"  # PID: 1234

# Block 2
echo "Block 2 PID: $$"  # PID: 5678 (different!)
echo "TEST_VAR: ${TEST_VAR:-EMPTY}"  # Output: EMPTY
```

**GitHub Issues**:
- #334: Export persistence limitation first identified
- #2508: Confirmed subprocess model (not subshell)

### 6. Performance Characteristics

**From**: `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` (lines 1013-1098)

**Code Reduction**: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- `/coordinate`: 1,084 → 800 lines (26.2% reduction)
- `/orchestrate`: 557 → 551 lines (1.1% reduction)
- `/supervise`: 1,779 → 397 lines (77.7% reduction)

**State Operation Performance**:
- `CLAUDE_PROJECT_DIR` detection: 6ms (git) → 2ms (file read) = 67% faster
- `init_workflow_state()`: ~6ms (includes git rev-parse)
- `load_workflow_state()`: ~2ms (file read + source)
- `save_json_checkpoint()`: 5-10ms (atomic write)
- `load_json_checkpoint()`: 2-5ms (cat + jq validation)
- `append_workflow_state()`: <1ms (echo redirect)

**Stateless Recalculation Performance**:
- CLAUDE_PROJECT_DIR detection: <1ms (git command cached)
- Scope detection: <1ms (string pattern matching)
- PHASES_TO_EXECUTE mapping: <0.1ms (case statement)
- Total per-block overhead: ~2ms (negligible)

**Context Reduction** (via hierarchical supervisors):
- Research supervisor (4 workers): 95.6% reduction
- Implementation supervisor (3 tracks): 93.3% reduction
- Testing supervisor (sequential): 93.3% reduction
- Average across all types: 94.1% reduction

## Recommendations

### 1. Understand Library Loading Order

**Action**: Always source libraries in correct dependency order:
1. `CLAUDE_PROJECT_DIR` detection (via git or env var)
2. `state-persistence.sh` (provides state file functions)
3. `workflow-state-machine.sh` (depends on state persistence)
4. `workflow-scope-detection.sh` (used by sm_init)

**Rationale**: Incorrect loading order causes "command not found" errors or unbound variable errors.

**Reference**: `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (lines 829-880)

### 2. Use Selective State Persistence Decision Criteria

**Action**: For each state variable, apply the 7 decision criteria to choose file-based vs stateless:
- Is recalculation expensive (>30ms)?
- Is state non-deterministic?
- Does state accumulate across subprocess boundaries?
- Is cross-invocation persistence needed?
- Do phase dependencies require prior outputs?
- Is context reduction via metadata aggregation needed?
- Is resumability valuable?

**Rationale**: Systematic criteria prevent both over-persistence (unnecessary I/O) and under-persistence (expensive recalculation).

**Reference**: `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 63-71)

### 3. Follow Fail-Fast Validation Pattern

**Action**: Use `load_workflow_state(workflow_id, false)` in subsequent blocks to expose missing state files immediately.

**Rationale**: Spec 672 Phase 3 added fail-fast mode to distinguish expected vs unexpected missing state files, reducing debugging time from hours to minutes.

**Reference**: `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 149-229)

### 4. Respect Test Isolation Overrides

**Action**: In tests, always set `CLAUDE_SPECS_ROOT` and `CLAUDE_PROJECT_DIR` environment variables to prevent production directory pollution.

**Rationale**: Without overrides, tests create empty topic directories in production specs/, defeating lazy directory creation benefits.

**Reference**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (lines 44-69)

### 5. Use State File Verification Pattern

**Action**: When verifying state file contents, include `export` prefix in grep patterns:
```bash
# Correct
grep -q "^export VARIABLE_NAME=" "$STATE_FILE"

# Incorrect (will not match)
grep -q "^VARIABLE_NAME=" "$STATE_FILE"
```

**Rationale**: `append_workflow_state()` writes in export format (line 268). Missing prefix causes false negatives.

**Reference**: `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (lines 722-812)

## References

### Core Architecture Documentation
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` (1,748 lines)
  - Complete architecture overview
  - Performance characteristics (lines 1013-1142)
  - Migration guide (lines 1143-1290)

- `/home/benjamin/.config/.claude/docs/architecture/workflow-state-machine.md` (995 lines)
  - State machine design and implementation
  - State enumeration (lines 17-26)
  - Transition table (lines 38-60)
  - API reference (lines 119-364)

- `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (1,485 lines)
  - Subprocess isolation constraint (lines 38-108)
  - Stateless recalculation pattern (lines 110-207)
  - Selective state persistence (lines 534-676)
  - Verification checkpoint pattern (lines 722-824)

### Library Implementations
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (887 lines exported)
  - State machine implementation
  - Dependencies: lines 15-18
  - Core functions: sm_init (line 388), sm_transition (line 602), sm_execute (line 652)

- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (393 lines)
  - GitHub Actions-style state files
  - Critical state items: lines 49-57
  - Decision criteria: lines 63-71
  - Core functions: init_workflow_state (line 117), load_workflow_state (line 187)

- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (150+ lines)
  - Path detection precedence order
  - detect_project_root: lines 88-106
  - detect_specs_directory: lines 125-150
  - Test isolation pattern: lines 44-69

### Related Files Analyzed
- `/home/benjamin/.config/.claude/lib/detect-project-dir.sh` (sourced by workflow-state-machine.sh:30)
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (dependency of sm_init)
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (dependency for checkpoint operations)

### GitHub Issues
- #334: Export persistence limitation
- #2508: Subprocess model confirmation
