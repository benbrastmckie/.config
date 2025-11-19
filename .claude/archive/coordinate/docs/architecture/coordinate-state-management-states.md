# /coordinate State Management - States & Decisions

## Navigation

This document is part of a multi-part guide:
- [Overview](coordinate-state-management-overview.md) - Introduction, subprocess isolation, and stateless recalculation pattern
- **States & Decisions** (this file) - Rejected alternatives, decision matrix, and selective state persistence
- [Transitions](coordinate-state-management-transitions.md) - Verification checkpoints and troubleshooting guide
- [Examples](coordinate-state-management-examples.md) - FAQ, historical context, and references

---

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
| Library extraction | <1ms | Low | None (same as stateless) | **Implemented (Phase 1)** |
| Checkpoint pattern | 50-100ms | Medium | I/O, serialization | Different use case |
| **Stateless recalc** | **<1ms** | **Low** | **None** | **ACCEPTED** |

---

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

**Pattern 1: Stateless Recalculation** (/coordinate)
- Use when: <10 variables, <100ms recalculation cost
- Example: CLAUDE_PROJECT_DIR, WORKFLOW_SCOPE, PHASES_TO_EXECUTE
- Commands: /coordinate, /orchestrate, /supervise
- Don't use when: Computation >1 second, state persists cross-invocation

**Pattern 2: Checkpoint Files** (/implement)
- Use when: Multi-phase workflows, resumable, complex state
- Example: Implementation progress tracking, test results
- Commands: /implement, long-running workflows
- Don't use when: Single invocation, simple state, fast recalculation

**Pattern 3: File-based State** (rare)
- Use when: Heavy computation (>1s), state persists across invocations
- Example: Codebase analysis cache, dependency graphs
- Don't use when: Fast recalculation available (<100ms)

**Pattern 4: Single Large Block** (simple commands)
- Use when: <300 lines total, no Task tool calls, simple logic
- Example: Utility scripts, formatters, validators
- Don't use when: Need subagent delegation, >300 lines

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

---

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

---

## Related Documentation

- [Overview](coordinate-state-management-overview.md) - Introduction and stateless recalculation pattern
- [Transitions](coordinate-state-management-transitions.md) - Verification checkpoints and troubleshooting
- [Examples](coordinate-state-management-examples.md) - FAQ, historical context, and references
- [Library API Reference](../reference/library-api.md#state-persistencesh) - State persistence library documentation
