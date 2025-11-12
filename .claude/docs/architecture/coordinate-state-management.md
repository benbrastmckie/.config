# /coordinate State Management Architecture

## Metadata
- **Date**: 2025-11-06
- **Command**: /coordinate
- **Pattern**: Stateless Recalculation
- **GitHub Issues**: #334, #2508
- **Related Specs**: 597, 598, 582-594, 599, 600

## Table of Contents
1. [Overview](#overview)
2. [Subprocess Isolation Constraint](#subprocess-isolation-constraint)
3. [Stateless Recalculation Pattern](#stateless-recalculation-pattern)
4. [Rejected Alternatives](#rejected-alternatives)
5. [Decision Matrix](#decision-matrix)
6. [Selective State Persistence](#selective-state-persistence)
7. [Verification Checkpoint Pattern](#verification-checkpoint-pattern)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [FAQ](#faq)
10. [Historical Context](#historical-context)
11. [References](#references)

## Overview

This document explains the state management architecture for the `/coordinate` command, documenting the subprocess isolation constraint, the stateless recalculation pattern, rejected alternatives, and decision frameworks for state management.

The `/coordinate` command uses **stateless recalculation**: every bash block independently recalculates all variables it needs, without relying on state from previous blocks. This pattern emerged after 13 refactor attempts (specs 582-594) and provides the optimal balance of simplicity, performance, and reliability within the constraints of Claude Code's Bash tool execution model.

**Key Architectural Principles**:
- Work with subprocess isolation, not against it
- Fail-fast over hidden complexity
- Performance measured, not assumed
- Code duplication accepted when alternatives add complexity

**Target Audience**: Developers maintaining `/coordinate` or implementing similar bash-based commands.

## Subprocess Isolation Constraint

### The Fundamental Limitation

Claude Code's Bash tool executes each bash block in a **separate subprocess**, not a subshell. This architectural constraint has critical implications for variable persistence.

**GitHub Issues**:
- **#334**: Export persistence limitation first identified
- **#2508**: Confirmed subprocess model (not subshell)

### Technical Explanation

**What Happens** (process isolation):
```bash
# Block 1 (subprocess PID 1234)
export VAR="value"
export CLAUDE_PROJECT_DIR="/path/to/project"

# Block 2 (subprocess PID 5678 - DIFFERENT PROCESS)
echo "$VAR"  # Empty! Export didn't persist
echo "$CLAUDE_PROJECT_DIR"  # Empty! Export didn't persist
```

**Why It Happens**:
1. Bash tool launches new process for each block (not fork/subshell)
2. Separate process spaces = separate environment tables
3. Exports only persist within same process and child processes
4. Sequential bash blocks are **sibling processes**, not parent-child

**Subprocess vs Subshell**:
```bash
# Subshell (would work, but not how Bash tool operates)
(
  export VAR="value"
)
echo "$VAR"  # Would be empty (subshell boundary)

# Subprocess (how Bash tool actually works)
bash -c 'export VAR="value"'  # Process 1
bash -c 'echo "$VAR"'         # Process 2 (sibling to Process 1)
# Output: (empty - processes don't share environment)
```

### Validation Test

Proof of subprocess isolation:
```bash
# Test 1: Verify export failure
# Block 1
export TEST_VAR="coordinate-test-$$"
echo "Block 1 PID: $$"

# Block 2
echo "Block 2 PID: $$"  # Different PID = different process
echo "TEST_VAR: ${TEST_VAR:-EMPTY}"  # Will show EMPTY
```

Expected output shows different PIDs, confirming subprocess isolation.

### Implications

**Cannot Rely On**:
- Export between bash blocks
- Variable assignments persisting
- Function definitions persisting
- Working directory persisting (without re-establishing)

**Must Recalculate**:
- All variables needed in each block
- All function definitions (via library sourcing)
- Working directory (via CLAUDE_PROJECT_DIR detection)
- All derived state (WORKFLOW_SCOPE, PHASES_TO_EXECUTE, etc.)

## Stateless Recalculation Pattern

### Definition

**Stateless Recalculation**: Every bash block independently recalculates all variables it needs, without relying on state from previous blocks.

**Core Principle**: Treat each bash block as if it's the first and only block executing.

### Pattern Implementation

**Standard 13 - CLAUDE_PROJECT_DIR Detection**:
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection for SlashCommand context
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Usage Frequency**: Applied in 6+ locations across coordinate.md (all bash blocks).

**Scope Detection Recalculation** (using library function after Phase 1):
```bash
# Source library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

# Parse workflow description from command argument
WORKFLOW_DESCRIPTION="$1"

# Call library function
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Derived Variable Recalculation** (PHASES_TO_EXECUTE mapping):
```bash
# Map workflow scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    ;;
esac
```

### Pattern Benefits

**Correctness**:
- No dependency on subprocess behavior
- Deterministic results (same inputs → same outputs)
- No hidden state or race conditions

**Performance**:
- CLAUDE_PROJECT_DIR detection: <1ms (git command cached)
- Scope detection: <1ms (string pattern matching)
- PHASES_TO_EXECUTE mapping: <0.1ms (case statement)
- **Total per-block overhead**: ~2ms
- **Total workflow overhead**: ~12ms for 6 blocks

**Simplicity**:
- No I/O operations (no file reads/writes)
- No cleanup logic required
- No synchronization primitives needed
- Clear, readable code (pattern repeats consistently)

### Pattern Trade-offs

**Accepted**:
- Code duplication: Some variables recalculated in multiple blocks
- Synchronization requirement: Library sourcing must be consistent
- Cognitive overhead: Pattern must be understood by maintainers

**Rejected Alternatives** (see next section):
- File-based state: 30ms I/O overhead (30x slower)
- Single large block: >400 lines triggers code transformation bugs
- Fighting tool constraints: Fragile workarounds violate fail-fast principle

### Validation

**Test Results** (from spec 597, 598):
- Research-only workflow: ✓
- Research-and-plan workflow: ✓
- Full-implementation workflow: ✓
- Debug-only workflow: ✓

**Performance Measurement**:
- Recalculation overhead: <1ms per variable
- Total workflow overhead: ~12ms (negligible)
- No I/O operations required

## Rejected Alternatives

### Overview

Between specs 582-594, 13 different approaches were attempted before arriving at stateless recalculation (spec 597). This section documents the rejected alternatives and their failure modes.

### Alternative 1: Fight Subprocess Isolation with Exports

**Specs**: 582, 583, 584
**Approach**: Attempt to make exports persist between blocks
**Duration**: 3 attempts over ~2 hours

**What Was Tried**:
```bash
# Attempt 1: Use export with explicit subprocess chaining
export VAR="value"
# Expected: VAR available in next block
# Actual: VAR undefined (subprocess boundary)

# Attempt 2: Use BASH_SOURCE for relative paths
source "$(dirname "${BASH_SOURCE[0]}")/../lib/library.sh"
# Expected: BASH_SOURCE populated in SlashCommand context
# Actual: BASH_SOURCE empty array (GitHub #334)

# Attempt 3: Source libraries in each block from exported path
export CLAUDE_PROJECT_DIR="/path/to/project"
# Block 2: source "${CLAUDE_PROJECT_DIR}/.claude/lib/library.sh"
# Expected: CLAUDE_PROJECT_DIR exported value available
# Actual: CLAUDE_PROJECT_DIR undefined in Block 2
```

**Why It Failed**:
- Subprocess isolation is fundamental to Bash tool architecture
- GitHub issues #334 and #2508 confirm this is intentional behavior
- No workaround exists without fighting the tool itself

**Lesson Learned**: Don't fight the tool's execution model. Work with it.

---

### Alternative 2: File-based State Persistence

**Specs**: 585 (evaluated), 593 (rejected)
**Approach**: Write variables to temporary file, read in each block
**Status**: Evaluated but rejected

**What Would Be Required**:
```bash
# Block 1: Write state
STATE_FILE="/tmp/coordinate-state-$$.json"
cat > "$STATE_FILE" <<EOF
{
  "WORKFLOW_SCOPE": "$WORKFLOW_SCOPE",
  "PHASES_TO_EXECUTE": "$PHASES_TO_EXECUTE",
  "CLAUDE_PROJECT_DIR": "$CLAUDE_PROJECT_DIR"
}
EOF

# Block 2: Read state
if [ -f "$STATE_FILE" ]; then
  WORKFLOW_SCOPE=$(jq -r '.WORKFLOW_SCOPE' "$STATE_FILE")
  PHASES_TO_EXECUTE=$(jq -r '.PHASES_TO_EXECUTE' "$STATE_FILE")
  CLAUDE_PROJECT_DIR=$(jq -r '.CLAUDE_PROJECT_DIR' "$STATE_FILE")
fi

# Cleanup (adds complexity)
trap 'rm -f "$STATE_FILE"' EXIT
```

**Performance Analysis** (Spec 585):
- File write: ~15ms per operation
- File read: ~15ms per operation
- Total overhead: ~30ms per workflow
- **30x slower** than stateless recalculation (<1ms)

**Complexity Analysis**:
- **New failure modes**: File system permissions, disk space, concurrent access
- **Cleanup logic**: Trap handlers, error recovery, orphaned files
- **Synchronization**: JSON parsing, serialization, schema validation
- **Debugging**: State hidden in external file (not visible in code)

**Why It Was Rejected**:
- 30ms overhead vs <1ms overhead (performance)
- Added complexity (file I/O, cleanup, error handling)
- New failure modes (file system issues)
- Only <10 variables need persistence (low value)

**When It Would Be Appropriate**:
- Computation cost >1 second (30ms I/O becomes acceptable)
- State must persist across /coordinate invocations (not just blocks)
- Heavy data structures (arrays with 100+ elements)

---

### Alternative 3: Single Large Bash Block

**Specs**: 581 (completed), 582 (discovered limitation)
**Approach**: Consolidate all logic into one bash block to avoid subprocess boundaries
**Status**: Partially successful, then hit hard limit

**What Was Tried** (Spec 581):
```bash
# Consolidate Phase 0 from 3 blocks → 1 block
# Original: Block 1 (176 lines) + Block 2 (168 lines) + Block 3 (77 lines) = 421 lines
# Consolidated: Single block (403 lines)
# Result: 250-400ms performance improvement
```

**Success**: Spec 581 successfully consolidated Phase 0, reducing subprocess overhead by 60%.

**Hard Limit Discovered** (Spec 582):
- Claude AI performs code transformation on bash blocks **>400 lines**
- Transformation converts `!` patterns unpredictably
- Example: `grep -E "!(pattern)"` → malformed regex
- **No workaround exists**: Transformation happens during parsing (before `set +H`)

**Why 400-Line Threshold Matters**:
```
< 400 lines: No transformation, safe to consolidate
≥ 400 lines: Transformation triggers, code breaks unpredictably
```

**Trade-off Analysis**:
- **Benefit**: Eliminates subprocess overhead (~150ms per boundary)
- **Cost**: Risk of code transformation bugs (hard to debug)
- **Decision**: Use this pattern for blocks <300 lines (safety margin)

**Current Application**:
- Phase 0 Block 1: 176 lines (safe)
- Phase 0 Block 2: 168 lines (safe)
- Phase 0 Block 3: 77 lines (safe)
- **Total**: 421 lines across 3 blocks (safe threshold)

**Why Not Consolidate Further**:
- 421 lines in single block would exceed 400-line threshold
- Risk of code transformation outweighs performance benefit
- Current structure balances performance and safety

---

### Alternative 4: Library Extraction (Accepted)

**Specs**: 599 (evaluated as Phase 1), 600 (implemented)
**Approach**: Move scope detection logic to shared library
**Status**: **Implemented in Phase 1 of spec 600**

**What Changed**:
```bash
# Before (24 lines duplicated in Block 1 and Block 3):
WORKFLOW_SCOPE="research-and-plan"
if echo "$WORKFLOW_DESCRIPTION" | grep -qiE '^research.*'; then
  # ... 20+ lines of scope detection ...
fi

# After (library function):
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Benefits**:
- Eliminates 48-line duplication (24 lines × 2 blocks)
- Single source of truth for scope detection
- Easier to test (unit test the library function)

**Trade-offs**:
- Still requires library sourcing in each block (subprocess isolation)
- Still requires CLAUDE_PROJECT_DIR recalculation (4 lines per block)
- **Net win**: 48 lines → 8 lines (40-line reduction)

**Why This Works**:
- Doesn't fight subprocess isolation (library sourced in each block)
- Reduces duplication without adding I/O overhead
- Maintains fail-fast behavior (missing library = immediate error)

---

### Alternative 5: Checkpoint Pattern (Multi-phase Workflows)

**Specs**: Used by /implement command
**Approach**: Persist state between workflow phases (not bash blocks)
**Status**: Appropriate for different use case

**Pattern**:
```bash
# Phase 1 completion
echo "$STATE" > "${CHECKPOINT_DIR}/phase1.json"

# Phase 2 (later invocation, possibly hours later)
STATE=$(cat "${CHECKPOINT_DIR}/phase1.json")
```

**When Appropriate**:
- Multi-phase workflows (>5 phases)
- Resumable workflows (user can pause and resume)
- State must persist across /command invocations
- Complex state (nested structures, large arrays)

**When NOT Appropriate** (/coordinate case):
- Single invocation workflow (no pause/resume)
- Simple state (<10 variables)
- Fast recalculation (<100ms)

**Key Distinction**:
- Checkpoints: Cross-invocation persistence (hours/days)
- Stateless recalculation: Within-invocation variables (milliseconds)

**Example Command**: `/implement` uses checkpoints for phase resumption

---

### Summary Table

| Alternative | Performance | Complexity | Failure Modes | Status |
|-------------|-------------|------------|---------------|---------|
| Export persistence | N/A (doesn't work) | Low | Subprocess isolation | Rejected |
| File-based state | 30ms overhead | High | I/O, permissions, cleanup | Rejected |
| Single large block | 0ms (no subprocess) | Medium | Code transformation >400 lines | Limited use |
| Library extraction | <1ms | Low | None (same as stateless) | **✓ Implemented (Phase 1)** |
| Checkpoint pattern | 50-100ms | Medium | I/O, serialization | Different use case |
| **Stateless recalc** | **<1ms** | **Low** | **None** | **✓ ACCEPTED** |

## Decision Matrix

### Pattern Selection Framework

Use this decision tree to choose the appropriate state management pattern for bash-based commands:

```
START
  │
  ├─ Is computation cost >1 second?
  │    YES → File-based State (Pattern 3)
  │    NO  ↓
  │
  ├─ Is workflow multi-phase with pause/resume?
  │    YES → Checkpoint Files (Pattern 2)
  │    NO  ↓
  │
  ├─ Is command <300 lines total with no subagents?
  │    YES → Single Large Block (Pattern 4)
  │    NO  ↓
  │
  └─ Use Stateless Recalculation (Pattern 1) ← /coordinate uses this
```

### Decision Criteria Table

| Criteria | Stateless Recalc | Checkpoints | File State | Single Block |
|----------|------------------|-------------|------------|--------------|
| **Variable count** | <10 | Any | Any | <10 |
| **Recalc cost** | <100ms | Any | >1s | N/A |
| **Command size** | Any | Any | Any | <300 lines |
| **Subagent calls** | Yes | Yes | Yes | No |
| **Cross-invocation** | No | Yes | Yes | No |
| **Overhead** | <1ms | 50-100ms | 30ms I/O | 0ms |
| **Complexity** | Low | Medium | High | Very Low |
| **Failure modes** | None | I/O, cleanup | I/O, permissions | Transformation >400 lines |

### Pattern Applicability

**Pattern 1: Stateless Recalculation** (✓ /coordinate)
- ✓ Use when: <10 variables, <100ms recalculation cost
- ✓ Example: CLAUDE_PROJECT_DIR, WORKFLOW_SCOPE, PHASES_TO_EXECUTE
- ✓ Commands: /coordinate, /orchestrate, /supervise
- ✗ Don't use when: Computation >1 second, state persists cross-invocation

**Pattern 2: Checkpoint Files** (/implement)
- ✓ Use when: Multi-phase workflows, resumable, complex state
- ✓ Example: Implementation progress tracking, test results
- ✓ Commands: /implement, long-running workflows
- ✗ Don't use when: Single invocation, simple state, fast recalculation

**Pattern 3: File-based State** (rare)
- ✓ Use when: Heavy computation (>1s), state persists across invocations
- ✓ Example: Codebase analysis cache, dependency graphs
- ✗ Don't use when: Fast recalculation available (<100ms)

**Pattern 4: Single Large Block** (simple commands)
- ✓ Use when: <300 lines total, no Task tool calls, simple logic
- ✓ Example: Utility scripts, formatters, validators
- ✗ Don't use when: Need subagent delegation, >300 lines

### Real-World Examples

**Example 1: /coordinate** (Stateless Recalculation)
- Variables: CLAUDE_PROJECT_DIR, WORKFLOW_SCOPE, PHASES_TO_EXECUTE, WORKFLOW_DESCRIPTION
- Count: 4 core variables
- Recalculation cost: <2ms total
- Pattern: Stateless recalculation (Pattern 1)
- Rationale: Fast recalculation, simple state, no cross-invocation persistence

**Example 2: /implement** (Checkpoints)
- Variables: Current phase, test results, file modifications, error history
- Count: 20+ variables
- Pattern: Checkpoint files (Pattern 2)
- Rationale: Resumable workflow, complex state, cross-invocation persistence required

**Example 3: Hypothetical Analytics Command** (File-based State)
- Variables: Codebase dependency graph (10,000+ nodes)
- Computation cost: 30+ seconds to build graph
- Pattern: File-based state (Pattern 3)
- Rationale: Expensive computation, cache across invocations

### Migration Guide

**From File-based State → Stateless Recalculation**:
1. Measure actual recalculation cost (may be faster than file I/O)
2. If <100ms, remove file I/O and recalculate
3. Remove cleanup logic (trap handlers, temporary files)
4. Simplify error handling (no I/O failure modes)

**From Single Block → Stateless Recalculation**:
1. Split block at logical boundaries (phases, subagent calls)
2. Add Standard 13 to each new block
3. Identify variables needed in each block
4. Add recalculation logic to each block
5. Test subprocess isolation (verify no export dependencies)

### Performance Comparison

| Pattern | Overhead | When Cost is Acceptable |
|---------|----------|-------------------------|
| Stateless recalculation | <1ms | Always (negligible) |
| Checkpoint files | 50-100ms | Multi-phase workflows (amortized) |
| File-based state | 30ms I/O | Computation >1s (net savings) |
| Single large block | 0ms | <300 lines, no subagents |

## Selective State Persistence

### Overview

As of Phase 3 (2025-11-07), the `.claude/` system implements **selective state persistence** - a hybrid approach that combines stateless recalculation for fast operations with file-based state for critical items where persistence provides measurable benefits.

This pattern follows the **GitHub Actions model** (`$GITHUB_OUTPUT`, `$GITHUB_STATE`) and is implemented in `.claude/lib/state-persistence.sh` (200 lines).

### When to Use Selective State Persistence

File-based state is justified when **one or more** of these criteria apply:

1. **State accumulates across subprocess boundaries** - Phase 3 benchmark accumulation across 10 invocations
2. **Context reduction requires metadata aggregation** - 95% reduction via supervisor metadata
3. **Success criteria validation needs objective evidence** - Timestamped metrics for performance validation
4. **Resumability is valuable** - Multi-hour migrations that should survive interruptions
5. **State is non-deterministic** - User survey results, research findings from external APIs
6. **Recalculation is expensive** - Operations taking >30ms that would be repeated
7. **Phase dependencies require prior phase outputs** - Phase 3 depends on Phase 2 benchmark data

### Critical State Items Using File-Based Persistence

Based on systematic analysis, **7 of 10** analyzed state items (70%) justify file-based persistence:

**Priority 0 (Performance-Critical)**:
1. **Supervisor metadata** - 95% context reduction, non-deterministic research findings
2. **Benchmark dataset** - Phase 3 accumulation across 10 subprocess invocations
3. **Implementation supervisor state** - 40-60% time savings via parallel execution tracking
4. **Testing supervisor state** - Lifecycle coordination across sequential stages

**Priority 1 (Enhancement)**:
5. **Migration progress** - Resumable, audit trail for multi-hour migrations
6. **Performance benchmarks** - Phase 3 dependency on Phase 2 data
7. **POC metrics** - Success criterion validation (timestamped phase breakdown)

### State Items Using Stateless Recalculation

**3 of 10** analyzed state items (30%) use stateless recalculation:

1. **File verification cache** - Recalculation 10x faster than file I/O (<1ms vs 10ms)
2. **Track detection results** - Deterministic algorithm, <1ms recalculation
3. **Guide completeness checklist** - Markdown checklist sufficient (no cross-invocation state)

This 30% rejection rate demonstrates systematic evaluation, not blanket advocacy for file-based state.

### Implementation Pattern (GitHub Actions Style)

```bash
# Block 1: Initialize workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT  # Cleanup on exit

# Expensive operation - detect CLAUDE_PROJECT_DIR ONCE
# Cached in state file for subsequent blocks (6ms → 2ms)

# Block 2+: Load workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
load_workflow_state "coordinate_$$"

# Variables restored from state file (no recalculation needed)
echo "$CLAUDE_PROJECT_DIR"  # Available immediately

# Append new state (GitHub Actions $GITHUB_OUTPUT pattern)
append_workflow_state "RESEARCH_COMPLETE" "true"
append_workflow_state "REPORTS_CREATED" "4"

# Save complex state as JSON checkpoint
SUPERVISOR_METADATA='{"topics": 4, "reports": ["r1.md", "r2.md"]}'
save_json_checkpoint "supervisor_metadata" "$SUPERVISOR_METADATA"

# Append benchmark log (JSONL format)
BENCHMARK='{"phase": "research", "duration_ms": 12500, "timestamp": "2025-11-07T14:30:00Z"}'
append_jsonl_log "benchmarks" "$BENCHMARK"
```

### Performance Characteristics

**Measured Performance** (from test suite):
- `init_workflow_state()` (includes git rev-parse): ~6ms
- `load_workflow_state()` (file read): ~2ms
- **Improvement**: 67% faster (6ms → 2ms)
- `save_json_checkpoint()`: 5-10ms (atomic write)
- `load_json_checkpoint()`: 2-5ms (cat + jq validation)
- `append_workflow_state()`: <1ms (echo redirect)
- `append_jsonl_log()`: <1ms (echo redirect)

**Graceful Degradation**:
- Missing state file → automatic recalculation (fallback)
- Missing JSON checkpoint → returns `{}` (empty object)
- Overhead for degradation check: <1ms

### Library API Reference

**Core Functions**:
- `init_workflow_state(workflow_id)` - Initialize state file, return path
- `load_workflow_state(workflow_id)` - Load state file, fallback if missing
- `append_workflow_state(key, value)` - Append variable (GitHub Actions pattern)
- `save_json_checkpoint(name, json_data)` - Atomic JSON checkpoint write
- `load_json_checkpoint(name)` - Load JSON checkpoint with validation
- `append_jsonl_log(log_name, json_entry)` - Append JSON line for benchmarks

**Location**: `.claude/lib/state-persistence.sh` (200 lines)
**Tests**: `.claude/tests/test_state_persistence.sh` (18 tests, 100% pass rate)
**Dependencies**: `jq` (JSON parsing), `mktemp` (atomic writes)

### Comparison with Pure Stateless Recalculation

| Aspect | Pure Stateless | Selective Persistence |
|--------|----------------|----------------------|
| **Code complexity** | Lower (no file I/O) | Medium (file I/O + fallback) |
| **Performance (expensive ops)** | Slower (recalculate every time) | Faster (cache once, reuse) |
| **Performance (cheap ops)** | Faster (no I/O overhead) | Use stateless (selective) |
| **Failure modes** | None | I/O errors (mitigated by fallback) |
| **Context reduction** | Limited | 95% via metadata aggregation |
| **Cross-invocation state** | Not possible | Supported (migrations, POCs) |
| **Resumability** | Not possible | Supported (checkpoint files) |

**Recommendation**: Use selective persistence pattern when >50% of state items meet file-based criteria. Continue pure stateless recalculation for simple commands with only fast, deterministic variables.

### Decision Tree for State Items

```
For each state variable:
  │
  ├─ Is recalculation expensive (>30ms)?
  │    YES → File-based state
  │    NO  ↓
  │
  ├─ Is state non-deterministic?
  │    YES → File-based state
  │    NO  ↓
  │
  ├─ Does state accumulate across subprocess boundaries?
  │    YES → File-based state
  │    NO  ↓
  │
  ├─ Is cross-invocation persistence needed?
  │    YES → File-based state (checkpoint)
  │    NO  ↓
  │
  └─ Use stateless recalculation ← Most variables
```

### Migration from Pure Stateless to Selective Persistence

**Step 1: Identify Critical State Items**
- Run workflow with timing instrumentation
- Identify variables recalculated >5 times per workflow
- Measure recalculation cost for each variable
- Apply decision criteria (7 criteria above)

**Step 2: Implement Selective Persistence**
- Add `state-persistence.sh` to REQUIRED_LIBS
- Initialize state file in Block 1
- Migrate expensive variables to file-based state
- Keep cheap variables as stateless recalculation
- Add graceful degradation (fallback)

**Step 3: Validate Performance**
- Run test suite (ensure 100% pass rate)
- Measure performance improvement (before/after)
- Validate graceful degradation (delete state file mid-workflow)
- Confirm no regressions on existing functionality

**Step 4: Update Documentation**
- Document which variables use file-based state (rationale)
- Update architectural documentation
- Add troubleshooting guide for new failure modes

### Testing Selective State Persistence

The test suite (`.claude/tests/test_state_persistence.sh`) validates:

1. State file initialization (CLAUDE_PROJECT_DIR cached)
2. State file loading (variables restored correctly)
3. Graceful degradation (missing file fallback)
4. GitHub Actions pattern (append_workflow_state accumulation)
5. JSON checkpoint atomic writes (no partial writes)
6. JSON checkpoint loading (validation, missing file handling)
7. JSONL log appending (benchmark accumulation)
8. Subprocess boundary persistence (state survives new bash processes)
9. Multi-workflow isolation (workflows don't interfere)
10. Error handling (missing STATE_FILE, missing CLAUDE_PROJECT_DIR)
11. Performance characteristics (file read faster than git command)

**Test Results**: 18/18 tests passing (100% pass rate)

## Verification Checkpoint Pattern

State file verification must account for export format used by `state-persistence.sh`.

### State File Format

The `append_workflow_state()` function writes variables in export format for proper bash sourcing:

```bash
# From .claude/lib/state-persistence.sh:216
echo "export ${key}=\"${value}\"" >> "$STATE_FILE"
```

**Example state file**:
```bash
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_ID="coordinate_1762816945"
export REPORT_PATHS_COUNT="4"
export REPORT_PATH_0="/path/to/report1.md"
```

### Verification Pattern (Correct)

Grep patterns must include the `export` prefix:

```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
if grep -q "^export VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ Variable verified"
else
  echo "✗ Variable missing"
  exit 1
fi
```

### Anti-Pattern (Incorrect)

This pattern will NOT match the export format, causing false negatives:

```bash
# DON'T: This pattern won't match export format
if grep -q "^VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ Variable verified"  # Will never execute
fi
```

**Why it fails**:
- Pattern expects: `VARIABLE_NAME="value"`
- Actual format: `export VARIABLE_NAME="value"`
- The `^` anchor requires match at start of line
- `export ` prefix prevents match

### Historical Bug

**Spec 644** (2025-11-10): Fixed verification checkpoint in coordinate.md using incorrect pattern.

**Issue**: Grep patterns searched for `^REPORT_PATHS_COUNT=` but state file contained `export REPORT_PATHS_COUNT="4"`, causing verification to fail despite variables being correctly written.

**Impact**: Critical (blocked all coordinate workflows during initialization)

**Fix**: Added `export ` prefix to grep patterns (2 locations in coordinate.md)

**Test Coverage**: Added `.claude/tests/test_coordinate_verification.sh` with 3 unit tests to prevent regression.

### Best Practices

1. **Always include export prefix** in grep patterns when verifying state file variables
2. **Add clarifying comments** documenting expected format (reference state-persistence.sh)
3. **Test verification logic** to catch false negatives/positives
4. **Check actual state file** during debugging (don't trust error messages blindly)

### Example Usage

**Verifying single variable**:
```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
if grep -q "^export WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ WORKFLOW_ID verified"
fi
```

**Verifying array of variables**:
```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
for ((i=0; i<COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  if grep -q "^export ${var_name}=" "$STATE_FILE" 2>/dev/null; then
    echo "✓ $var_name verified"
  fi
done
```

### Test Suite

Verification checkpoint logic is tested in `.claude/tests/test_coordinate_verification.sh`:

1. **Test 1**: State file format matches `append_workflow_state` output
2. **Test 2**: Verification pattern matches actual state file
3. **Test 3**: False negative prevention (regression test for Spec 644 bug)
4. **Test 4**: Integration test (manual, requires full coordinate workflow)

**Test Results**: 3/3 automated tests passing (100% pass rate)

## Troubleshooting Guide

### Common Issues and Solutions

---

#### Issue 1: "command not found" for Library Functions

**Symptom**:
```bash
.claude/commands/coordinate.md: line 1234: should_synthesize_overview: command not found
# Exit code 127
```

**Root Cause**: Library not included in REQUIRED_LIBS array for current workflow scope.

**Diagnostic Procedure**:
1. Identify the missing function name (e.g., `should_synthesize_overview`)
2. Find which library defines it:
   ```bash
   grep -r "should_synthesize_overview()" .claude/lib/
   # Result: .claude/lib/overview-synthesis.sh
   ```
3. Check if library is in REQUIRED_LIBS for current scope:
   ```bash
   grep -A10 "research-only)" .claude/commands/coordinate.md | grep "overview-synthesis.sh"
   # If no match: Library is missing
   ```

**Solution**: Add missing library to appropriate REQUIRED_LIBS arrays.

**Example** (Spec 598, Issue 1):
```bash
# Before (missing library):
research-only)
  REQUIRED_LIBS=(
    "workflow-detection.sh"
    "unified-logger.sh"
    # Missing: overview-synthesis.sh
  )
  ;;

# After (library added):
research-only)
  REQUIRED_LIBS=(
    "workflow-detection.sh"
    "unified-logger.sh"
    "overview-synthesis.sh"  # ← Added
  )
  ;;
```

**Prevention**: When adding function calls, verify library is sourced in ALL workflow scopes that use it.

**Reference**: Spec 598, Issue 1 (overview-synthesis.sh missing)

---

#### Issue 2: "unbound variable" Errors

**Symptom**:
```bash
.claude/lib/workflow-detection.sh: line 182: PHASES_TO_EXECUTE: unbound variable
```

**Root Cause**: Variable calculated in one bash block but not recalculated in subsequent blocks (subprocess isolation).

**Diagnostic Procedure**:
1. Identify the undefined variable (e.g., `PHASES_TO_EXECUTE`)
2. Find where it's first calculated:
   ```bash
   grep -n "PHASES_TO_EXECUTE=" .claude/commands/coordinate.md | head -5
   # Shows line numbers of all assignments
   ```
3. Find where error occurs:
   ```bash
   # Error message shows: workflow-detection.sh:182
   sed -n '182p' .claude/lib/workflow-detection.sh
   # Shows: [[ ",$PHASES_TO_EXECUTE," == *",$phase,"* ]]
   ```
4. Check if variable is recalculated before use:
   ```bash
   # Find bash block boundaries before error location
   grep -n "^[\`]{3}bash" .claude/commands/coordinate.md
   # Verify PHASES_TO_EXECUTE assigned in that block
   ```

**Solution**: Add stateless recalculation of the variable in the bash block where it's used.

**Example** (Spec 598, Issue 2):
```bash
# Block 1 (lines 607-626): PHASES_TO_EXECUTE calculated
case "$WORKFLOW_SCOPE" in
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    ;;
esac

# Block 3 (lines 904-936): MISSING - needs recalculation
# Add:
case "$WORKFLOW_SCOPE" in
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    ;;
esac
```

**Prevention**:
- Follow stateless recalculation pattern: every block calculates what it needs
- Don't rely on exports from previous blocks
- Add defensive validation after recalculation

**Reference**: Spec 598, Issue 2 (PHASES_TO_EXECUTE unbound)

---

#### Issue 3: Workflow Stops Prematurely

**Symptom**:
- Workflow executes Phase 0, 1, 2
- Phase 3 skipped unexpectedly
- No error message, just stops

**Root Cause**: Incorrect phase list in PHASES_TO_EXECUTE (missing phases).

**Diagnostic Procedure**:
1. Check expected phases for workflow scope (documentation):
   ```bash
   grep -A3 "full-implementation)" .claude/commands/coordinate.md | grep "Phases:"
   # Expected: Phases: 0, 1, 2, 3, 4, 6
   ```
2. Check actual PHASES_TO_EXECUTE value:
   ```bash
   grep "full-implementation)" -A2 .claude/commands/coordinate.md | grep "PHASES_TO_EXECUTE"
   # Actual: PHASES_TO_EXECUTE="0,1,2,3,4"
   ```
3. Compare expected vs actual:
   ```
   Expected: 0,1,2,3,4,6
   Actual:   0,1,2,3,4
   Missing:  6
   ```

**Solution**: Update PHASES_TO_EXECUTE to match documentation.

**Example** (Spec 598, Issue 3):
```bash
# Before (missing phase 6):
full-implementation)
  PHASES_TO_EXECUTE="0,1,2,3,4"  # Missing phase 6
  SKIP_PHASES="5"
  ;;

# After (phase 6 included):
full-implementation)
  PHASES_TO_EXECUTE="0,1,2,3,4,6"  # Now includes phase 6
  SKIP_PHASES="5"
  ;;
```

**Prevention**:
- Verify PHASES_TO_EXECUTE matches documentation
- Add synchronization tests (Phase 3 of refactor)
- Document phase list in comments

**Reference**: Spec 598, Issue 3 (full-implementation missing phase 6)

---

#### Issue 4: REPORT_PATHS_COUNT Unbound Variable

**Symptom**:
```bash
/run/current-system/sw/bin/bash: line 337: REPORT_PATHS_COUNT: unbound variable
Exit code 127
```

**Root Cause**: `workflow-initialization.sh` creates individual `REPORT_PATH_0`, `REPORT_PATH_1`, etc. variables but never exports `REPORT_PATHS_COUNT`. The coordinate command tries to use this variable to serialize the array to state, causing an "unbound variable" error with `set -u`.

**Diagnostic Procedure**:
1. Check if REPORT_PATHS_COUNT is exported in workflow-initialization.sh:
   ```bash
   grep "REPORT_PATHS_COUNT" .claude/lib/workflow-initialization.sh
   # Should show: export REPORT_PATHS_COUNT=4
   ```
2. Verify the report paths array initialization (lines 236-249):
   ```bash
   sed -n '236,249p' .claude/lib/workflow-initialization.sh
   # Should export REPORT_PATH_0 through REPORT_PATH_3 AND REPORT_PATHS_COUNT
   ```
3. Check coordinate.md usage of REPORT_PATHS_COUNT:
   ```bash
   grep -n "REPORT_PATHS_COUNT" .claude/commands/coordinate.md
   # Shows all locations where variable is used
   ```

**Solution**: Export REPORT_PATHS_COUNT in `workflow-initialization.sh` along with individual report path variables.

**Example** (Spec 637, Phase 2):
```bash
# Before (missing REPORT_PATHS_COUNT export):
local -a report_paths
for i in 1 2 3 4; do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done

# After (with REPORT_PATHS_COUNT export):
local -a report_paths
for i in 1 2 3 4; do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done

# Export individual report path variables for bash block persistence
export REPORT_PATH_0="${report_paths[0]}"
export REPORT_PATH_1="${report_paths[1]}"
export REPORT_PATH_2="${report_paths[2]}"
export REPORT_PATH_3="${report_paths[3]}"
export REPORT_PATHS_COUNT=4
```

**Additional Defensive Pattern**: Add existence check in `reconstruct_report_paths_array()`:
```bash
reconstruct_report_paths_array() {
  REPORT_PATHS=()

  # Defensive check: ensure REPORT_PATHS_COUNT is set
  if [ -z "${REPORT_PATHS_COUNT:-}" ]; then
    echo "WARNING: REPORT_PATHS_COUNT not set, defaulting to 0" >&2
    REPORT_PATHS_COUNT=0
    return 0
  fi

  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    local var_name="REPORT_PATH_$i"

    # Defensive check: verify variable exists before accessing
    # ${!var_name+x} returns "x" if variable exists, empty if undefined
    if [ -z "${!var_name+x}" ]; then
      echo "WARNING: $var_name not set, skipping" >&2
      continue
    fi

    # Safe to use indirect expansion now
    REPORT_PATHS+=("${!var_name}")
  done
}
```

**Prevention**:
- Always export array count along with individual array elements
- Add defensive checks before using indirect expansion (`${!var_name}`)
- Use `${var:-}` pattern to prevent unbound variable errors with `set -u`
- Test with `set -u` enabled to catch missing exports early

**Reference**: Spec 637 (Fix Coordinate Agent Invocation and Bash Variable Error)

---

#### Issue 5: Code Transformation in Large Blocks

**Symptom**:
```bash
# Bash code with ! pattern gets transformed unpredictably
grep -E "!(pattern)"  # Intended
grep -E "1(pattern)"  # What gets executed (broken)
```

**Root Cause**: Claude AI performs code transformation on bash blocks ≥400 lines.

**Diagnostic Procedure**:
1. Measure bash block size:
   ```bash
   # Find block boundaries
   awk '/^[\`]{3}bash$/,/^[\`]{3}$/ {print NR": "$0}' .claude/commands/coordinate.md
   # Count lines between boundaries
   ```
2. If block ≥400 lines: Transformation likely occurred
3. Check for `!` patterns in transformed output

**Solution**: Split large bash blocks into multiple smaller blocks (<300 lines for safety margin).

**Example** (Spec 582):
```bash
# Before: Single 403-line block
# Triggers transformation at 400-line threshold

# After: Three blocks (176 + 168 + 77 = 421 lines total)
# Each block <300 lines (safe threshold)
```

**Prevention**:
- Keep bash blocks <300 lines (100-line safety margin under 400-line threshold)
- Monitor block size during development
- Split at logical boundaries (phase transitions, subagent calls)

**Reference**: Spec 582 (large block transformation discovery)

---

#### Issue 5: BASH_SOURCE Empty in SlashCommand Context

**Symptom**:
```bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/library.sh"
# Error: No such file or directory (BASH_SOURCE[0] is empty)
```

**Root Cause**: BASH_SOURCE array not populated in SlashCommand execution context.

**Diagnostic Procedure**:
1. Verify execution context:
   ```bash
   echo "BASH_SOURCE: ${BASH_SOURCE[@]}"
   # In SlashCommand: (empty)
   # In script file: /path/to/script.sh
   ```
2. Check if code is in `.claude/commands/*.md` (SlashCommand)

**Solution**: Use CLAUDE_PROJECT_DIR instead of BASH_SOURCE for path resolution.

**Example** (Spec 583):
```bash
# Before (doesn't work in SlashCommand):
source "$(dirname "${BASH_SOURCE[0]}")/../lib/library.sh"

# After (works in SlashCommand):
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library.sh"
```

**Prevention**:
- Always use CLAUDE_PROJECT_DIR in SlashCommand context
- Apply Standard 13 pattern in every bash block
- Avoid BASH_SOURCE in `.claude/commands/*.md` files

**Reference**: Spec 583 (BASH_SOURCE limitation)

---

### Diagnostic Commands Reference

**Check library definitions**:
```bash
grep -r "function_name()" .claude/lib/
```

**Find variable assignments**:
```bash
grep -n "VARIABLE_NAME=" .claude/commands/coordinate.md
```

**Measure bash block size**:
```bash
awk '/^[\`]{3}bash$/,/^[\`]{3}$/ {count++} /^[\`]{3}$/ && count>0 {print "Block "block": "count" lines"; count=0; block++}' file.md
```

**Verify library sourcing**:
```bash
grep "REQUIRED_LIBS=" .claude/commands/coordinate.md -A20
```

**Check phase execution list**:
```bash
grep "PHASES_TO_EXECUTE=" .claude/commands/coordinate.md
```

## FAQ

### Q1: Why is code duplicated across bash blocks?

**A**: Bash tool subprocess isolation (GitHub #334, #2508) means exports don't persist between blocks. Each block must recalculate variables it needs. The alternative (file-based state) is 30x slower and adds complexity.

**Details**: See [Subprocess Isolation Constraint](#subprocess-isolation-constraint) and [Rejected Alternatives](#rejected-alternatives) sections.

---

### Q2: Can we use `export` to share variables between blocks?

**A**: No. Each bash block runs in a separate subprocess (not subshell), so exports don't persist. This is a fundamental limitation of the Bash tool architecture.

**Proof**:
```bash
# Block 1
export VAR="value"
echo "Block 1 PID: $$"  # PID: 1234

# Block 2
echo "Block 2 PID: $$"  # PID: 5678 (different process!)
echo "VAR: ${VAR:-EMPTY}"  # Output: EMPTY
```

**Reference**: GitHub issues #334 and #2508

---

### Q3: Should we refactor to eliminate code duplication?

**A**: Only if extraction to library functions (Phase 1 of current refactor). Do NOT attempt:
- File-based state (30x slower)
- Single large block (transformation bugs at >400 lines)
- Fighting subprocess isolation (fragile, violates fail-fast)

**Decision Matrix**: See [Decision Matrix](#decision-matrix) section for when to use each pattern.

---

### Q4: When should we use file-based state instead?

**A**: Only when computation cost >1 second OR state must persist across /coordinate invocations (not just between bash blocks).

**Example Use Case**:
```bash
# Expensive computation (30+ seconds)
if [ ! -f "${CACHE_FILE}" ]; then
  build_dependency_graph > "${CACHE_FILE}"  # 30 seconds
fi
GRAPH=$(cat "${CACHE_FILE}")  # 30ms
# Net savings: 30s - 30ms = 29.97s (worthwhile)
```

**Non-Example** (/coordinate case):
```bash
# Fast recalculation (<1ms)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
# File I/O would cost 30ms (30x slower than recalculation)
```

---

### Q5: What's the performance impact of stateless recalculation?

**A**: Negligible. Measured overhead:
- CLAUDE_PROJECT_DIR detection: <1ms (git command cached)
- Scope detection: <1ms (string pattern matching)
- PHASES_TO_EXECUTE mapping: <0.1ms (case statement)
- **Total per-block**: ~2ms
- **Total workflow**: ~12ms for 6 blocks

**Context**: File I/O would cost 30ms per operation, 15-30x slower.

---

### Q6: Why not consolidate bash blocks to reduce duplication?

**A**: We do, up to 300-line safe threshold. But code transformation occurs at 400+ lines:
- <300 lines: Safe to consolidate
- 300-400 lines: Risky (100-line safety margin)
- ≥400 lines: Code transformation bugs (unpredictable failures)

**Current Structure**:
- Block 1: 176 lines (safe)
- Block 2: 168 lines (safe)
- Block 3: 77 lines (safe)
- **Total**: 421 lines across 3 blocks

**Why Not Single Block**: 421 lines would exceed 400-line threshold, triggering transformation.

**Reference**: Spec 582 discovered 400-line threshold

---

### Q7: How do we prevent synchronization bugs when duplicating code?

**A**: Three strategies:
1. **Extract to libraries** (Phase 1): Reduce duplication to library calls
2. **Synchronization tests** (Phase 3): Automated detection of drift
3. **Clear comments**: Document why duplication exists and where

**Example** (Phase 3 synchronization tests):
```bash
# Test: Verify scope detection uses library
grep "detect_workflow_scope" coordinate.md Block1
grep "detect_workflow_scope" coordinate.md Block3
# If inline logic found: FAIL
```

---

### Q8: Is this pattern used by other commands?

**A**: Yes. Stateless recalculation is the standard pattern for all bash-based commands:
- `/coordinate`: 6 blocks, 4 recalculated variables
- `/orchestrate`: Similar pattern
- `/supervise`: Similar pattern

**Alternative patterns**:
- `/implement`: Uses checkpoint files (multi-phase resumable workflow)
- Simple utilities: Single bash block (<300 lines, no subagents)

---

### Q9: What happens if we miss recalculating a variable?

**A**: Immediate failure with "unbound variable" error (fail-fast behavior).

**Example** (Spec 598, Issue 2):
```bash
# Block 1: Calculate variable
PHASES_TO_EXECUTE="0,1,2,3,4,6"

# Block 3: Forget to recalculate
# (missing PHASES_TO_EXECUTE calculation)

# Later in Block 3:
should_run_phase 3  # Calls workflow-detection.sh:182
# Error: PHASES_TO_EXECUTE: unbound variable
```

**Why This Is Good**: Fail-fast prevents silent failures and hidden bugs.

---

### Q10: Where can I learn more about bash subprocess vs subshell?

**A**: See [Subprocess Isolation Constraint](#subprocess-isolation-constraint) section for technical details.

**Quick Summary**:
- **Subshell**: `( command )` - Forked from parent, shares some state
- **Subprocess**: `bash -c 'command'` - Independent process, no shared state
- **Bash tool**: Uses subprocess model (each block = independent process)

**Implication**: No shared state between blocks (must recalculate everything).

## Historical Context

### Evolution of /coordinate State Management

The stateless recalculation pattern emerged after 13 refactor attempts across specs 582-594. This section documents the journey to understand why this pattern is correct.

### Key Milestones

**Spec 578: Foundation (Nov 4, 2025)**
- **Problem**: `${BASH_SOURCE[0]}` undefined in SlashCommand context
- **Solution**: Replace with `CLAUDE_PROJECT_DIR` detection
- **Status**: Complete (8-line fix, 1.5 hours)
- **Impact**: Established Standard 13 as foundation for all subsequent work

**Spec 581: Performance Optimization (Nov 4, 2025)**
- **Problem**: Redundant library sourcing
- **Solution**: Consolidate bash blocks, conditional library loading
- **Status**: Complete (4 hours)
- **Innovation**: Merged 3 Phase 0 blocks → 1 block (saved 250-400ms per workflow)
- **Unintended Consequence**: Created 403-line single block (exceeded transformation threshold)

**Spec 582: Code Transformation Discovery (Nov 4, 2025)**
- **Problem**: Bash code transformation in large (403-line) blocks
- **Solution**: Split large block → 3 smaller blocks
- **Status**: Complete (1-2 hours)
- **Critical Discovery**: Claude AI performs code transformation at 400-line threshold
- **Unintended Consequence**: Splitting blocks exposed export persistence limitation

**Spec 583: BASH_SOURCE Limitation (Nov 4, 2025)**
- **Problem**: BASH_SOURCE empty after block split
- **Solution**: Use CLAUDE_PROJECT_DIR from Block 1
- **Status**: Complete (10 minutes)
- **Assumption**: Exports from Block 1 persist to Block 2
- **Actual Result**: Exposed deeper issue - exports don't persist

**Spec 584: Export Persistence Failure (Nov 4, 2025)**
- **Problem**: Exports from Block 1 don't reach Block 2-3
- **Status**: Complete (confirmed limitation, no workaround)
- **Root Cause**: Bash tool subprocess isolation (GitHub #334, #2508)
- **Impact**: Forced acceptance of subprocess isolation as architectural constraint

**Spec 585: Pattern Validation (Nov 4, 2025)**
- **Problem**: Evaluate state management alternatives
- **Research**: File-based state (30x slower), single large block (transformation risk), stateless recalculation (<1ms overhead)
- **Recommendation**: Use stateless recalculation for /coordinate
- **Impact**: Validated stateless recalculation as correct approach

**Specs 586-594: Incremental Refinements (Nov 4-5, 2025)**
- **Activities**: Library organization, error handling improvements, documentation
- **Contribution**: Refined understanding of subprocess isolation, Standard 13 application

**Spec 597: Stateless Recalculation Breakthrough (Nov 5, 2025)**
- **Problem**: Unbound variable errors in Block 3
- **Solution**: Apply stateless recalculation pattern
- **Status**: Complete (~15 minutes)
- **Test Results**: 16/16 tests passing
- **Performance**: <1ms overhead per recalculation
- **Impact**: First successful implementation of stateless recalculation

**Spec 598: Extend to Derived Variables (Nov 5, 2025)**
- **Problem**: PHASES_TO_EXECUTE not recalculated
- **Solution**: Extend stateless recalculation to all derived variables
- **Status**: Complete (30-45 minutes)
- **Issues Fixed**: 3 critical issues (library sourcing, PHASES_TO_EXECUTE, phase list)
- **Impact**: Completed stateless recalculation pattern

**Spec 599: Comprehensive Refactor Analysis (Nov 5, 2025)**
- **Problem**: Identify remaining improvement opportunities
- **Analysis**: 7 potential refactor phases identified
- **Impact**: Identified high-value improvements while accepting core stateless pattern

**Spec 600: High-Value Refactoring (Nov 5-6, 2025)**
- **Problem**: Execute highest-value improvements from spec 599
- **Phases**: Extract scope detection to library, add synchronization tests, document architecture
- **Status**: Phase 4 in progress (this document)
- **Impact**: Reduces duplication while maintaining stateless recalculation foundation

### Summary Timeline

```
Spec 578 (Nov 4) → Standard 13 foundation
         ↓
Spec 581 (Nov 4) → Block consolidation (exposed issues)
         ↓
Spec 582 (Nov 4) → 400-line transformation discovery
         ↓
Spec 583 (Nov 4) → BASH_SOURCE limitation
         ↓
Spec 584 (Nov 4) → Export persistence failure (root cause)
         ↓
Spec 585 (Nov 4) → Pattern validation (stateless recommended)
         ↓
Specs 586-594    → Incremental refinements
         ↓
Spec 597 (Nov 5) → ✅ Stateless recalculation success
         ↓
Spec 598 (Nov 5) → ✅ Pattern completion (derived variables)
         ↓
Spec 599 (Nov 5) → Refactor opportunity analysis
         ↓
Spec 600 (Nov 6) → High-value improvements (current)
```

### Key Lessons

1. **Tool Constraints Are Architectural**: Don't fight subprocess isolation, design around it
2. **Fail-Fast Over Complexity**: Immediate errors better than hidden bugs
3. **Performance Measurement**: 1ms recalculation vs 30ms file I/O (30x difference)
4. **Code Duplication Can Be Correct**: 50 lines duplication < file I/O complexity
5. **Validation Through Testing**: 16 tests prove pattern works in production
6. **Incremental Discovery**: 13 attempts over time led to correct solution

## References

- **GitHub Issues**:
  - [#334](https://github.com/anthropics/claude-code/issues/334) - Export persistence limitation first identified
  - [#2508](https://github.com/anthropics/claude-code/issues/2508) - Confirmed subprocess model (not subshell)

- **Specifications**:
  - Spec 578: Fix Library Sourcing Error (BASH_SOURCE limitation)
  - Spec 581: Performance Optimization (block consolidation)
  - Spec 582: Code Transformation Discovery (400-line threshold)
  - Spec 583: BASH_SOURCE Limitation (SlashCommand context)
  - Spec 584: Export Persistence Failure (root cause identification)
  - Spec 585: Pattern Validation (stateless recommended)
  - Specs 586-594: Incremental refinements
  - Spec 597: Stateless Recalculation Breakthrough (first success)
  - Spec 598: Extend to Derived Variables (pattern completion)
  - Spec 599: Comprehensive Refactor Analysis (7 opportunities)
  - Spec 600: High-Value Refactoring (current implementation)

- **Related Documentation**:
  - [Command Development Guide](./../guides/command-development-guide.md)
  - [Orchestration Best Practices](./../guides/orchestration-best-practices.md)
  - [CLAUDE.md](../../CLAUDE.md) - Project configuration and standards
