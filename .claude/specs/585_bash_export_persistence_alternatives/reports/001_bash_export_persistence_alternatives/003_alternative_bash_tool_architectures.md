# Alternative Bash Tool Architectures Research Report

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: Alternative Bash Tool Architectures
- **Report Type**: Architectural Analysis
- **Context Plan**: /home/benjamin/.config/.claude/specs/584_fix_coordinate_export_persistence/plans/001_fix_export_persistence.md
- **Overview Report**: [Bash Export Persistence Alternatives](OVERVIEW.md)
- **Related Reports**: [Bash Session Persistence Patterns](001_bash_session_persistence_patterns.md), [State Management Across Tool Invocations](002_state_management_across_tool_invocations.md), [Inter-Process Communication Lightweight Methods](004_inter_process_communication_lightweight_methods.md)

## Executive Summary

Analysis of Plan 584 reveals fundamental tension between bash block size limits (400 lines trigger transformation errors) and export persistence limitations (exports don't persist between separate Bash tool invocations). Three architectural patterns emerge: (1) Single large block with all commands accepting transformation risk, (2) Multiple small blocks with stateless recalculation (current solution), (3) Multiple blocks with file-based state persistence. The stateless recalculation pattern chosen in Plan 584 optimizes for reliability and simplicity with acceptable 150ms overhead, while file-based persistence offers robustness at cost of complexity and I/O overhead.

## Findings

### Finding 1: Bash Tool Architecture Constraints

**Source**: `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md` (lines 137-296)

The Bash tool exhibits two critical architectural limitations that constrain command design:

**Limitation 1: Large Block Transformation** (lines 137-289)
- Bash blocks exceeding ~400 lines undergo character escaping during markdown extraction
- Special characters like `!` in `${!var}` patterns get backslash-escaped: `${\\!var}`
- Results in syntax errors: `bash: ${\\!varname}: bad substitution`
- Root cause: Claude AI's markdown processing pipeline transforms large blocks
- Detection threshold: Errors appear consistently above 400 lines, reliable below 200 lines

**Real-World Evidence** (lines 254-266):
- `/coordinate` command had 402-line Phase 0 block causing 3-5 transformation errors per run
- Solution: Split into 3 blocks (176 + 168 + 77 lines)
- Result: Zero transformation errors, all 47 tests pass
- Commit: `3d8e49df` - "fix(coordinate): split Phase 0 into smaller bash blocks"

**Limitation 2: Export Non-Persistence** (Plan 584 discovery)
- Environment variables exported in one Bash invocation don't persist to next invocation
- Documented as "persistent shell session" but behaves as isolated invocations
- Affects both variable exports (`export VAR`) and function exports (`export -f func`)
- GitHub Issues: #334 (March 2025), #2508 (June 2025) - still unresolved

**Evidence from coordinate_output.md** (Plan 584, lines 659-719):
```
Line 29-46: CLAUDE_PROJECT_DIR empty in Block 3 (export from Block 1 lost)
Line 92-95: verify_file_created: command not found (export -f from Block 4 lost)
Line 57-58: Claude AI manually re-exported CLAUDE_PROJECT_DIR as workaround
```

**Architectural Implication**: Cannot have both large blocks (>400 lines) AND state propagation via exports. Must choose: single large block OR multiple small blocks with alternative state mechanism.

### Finding 2: Single Bash Block Architecture

**Pattern**: Execute all commands in one bash block to preserve shell state naturally.

**Advantages**:
1. **Natural state propagation**: Variables and functions available throughout execution
2. **Simple mental model**: Linear execution flow, no state synchronization needed
3. **No I/O overhead**: State lives in memory, no file reads/writes
4. **Zero performance penalty**: Single shell session, no recalculation

**Disadvantages**:
1. **Transformation errors**: Blocks >400 lines trigger character escaping (Finding 1)
2. **Readability issues**: Large blocks harder to navigate and maintain
3. **Error recovery**: Failure in middle of block loses all progress
4. **Testing complexity**: Cannot test individual sections in isolation

**Real-World Example** (before Plan 583):
- `/coordinate` Phase 0: 402 lines in single block
- Used indirect variable expansion: `result="${!WORKFLOW_SCOPE}"`
- Errors: 3-5 transformation errors per run
- Symptom: `bash: ${\\!varname}: bad substitution`

**Viability Assessment**: **Not viable** for commands requiring >400 lines of sequential bash logic due to transformation errors. Only suitable for simple commands with <200 lines bash.

### Finding 3: Multiple Blocks with Stateless Recalculation (Plan 584 Solution)

**Pattern**: Split bash into <200 line blocks, each independently recalculates needed state.

**Implementation** (Plan 584, lines 78-154):
```bash
# Block 1: Initial calculation and export
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
export CLAUDE_PROJECT_DIR  # Note: Does not persist to Block 2

# Block 2: Recalculate (same pattern)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
# Use CLAUDE_PROJECT_DIR...

# Block 3: Recalculate again (same pattern)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
# Use CLAUDE_PROJECT_DIR for library sourcing...
```

**Advantages**:
1. **Avoids transformation errors**: Each block <200 lines, well below 400-line threshold
2. **Self-sufficient blocks**: No dependencies on previous block state
3. **Fast recalculation**: Git detection ~50ms per block, 150ms total for 3 blocks
4. **Idempotent**: Check `[ -z "${VAR:-}" ]` before calculating, safe to run multiple times
5. **No file I/O**: Pure computation, no disk reads/writes
6. **Simple implementation**: Copy-paste same detection pattern to each block

**Disadvantages**:
1. **Code duplication**: Same calculation logic appears in multiple blocks
2. **Maintenance burden**: Changes to detection logic must be replicated across blocks
3. **Limited to cheap operations**: Only viable for fast calculations (<100ms)
4. **Cannot handle complex state**: Arrays, associative arrays, or large data structures expensive to recalculate
5. **Conceptual redundancy**: Calculating same value multiple times feels wasteful

**Performance Analysis** (Plan 584, lines 639-655):
```
Recalculation overhead per block:
- Git command: 45-55ms (measured)
- Pwd fallback: 0.5-1ms
- Conditional check: <0.1ms

Total per workflow:
- 3 blocks × ~50ms = ~150ms
- Phase 0 target: <500ms
- Remaining budget: 350ms for other operations
- Verdict: Acceptable (well under budget)
```

**Viability Assessment**: **Optimal for simple state** (single variables, project paths) where calculation is fast (<100ms) and deterministic. Current implementation in Plan 584 demonstrates this pattern successfully.

**Limitations for Complex State**:
- **Functions**: Cannot recalculate, must source from library (Plan 584 Change 3-4)
- **Arrays**: Expensive to reconstruct, consider file-based persistence
- **Session data**: User input, API tokens, etc. cannot be recalculated

### Finding 4: Multiple Blocks with File-Based State Persistence

**Pattern**: Write state to file after Block 1, read from file in subsequent blocks.

**Implementation Pattern** (from web research and checkpoint-utils.sh):
```bash
# Block 1: Calculate and persist
STATEFILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_state.sh"
mkdir -p "$(dirname "$STATEFILE")"

CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
WORKFLOW_SCOPE="full-implementation"
RESEARCH_COMPLEXITY="high"

# Persist using declare -p for type safety
declare -p CLAUDE_PROJECT_DIR WORKFLOW_SCOPE RESEARCH_COMPLEXITY > "$STATEFILE"

# Block 2: Load and use
STATEFILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_state.sh"
if [ -f "$STATEFILE" ]; then
  source "$STATEFILE"
else
  echo "ERROR: State file missing" >&2
  exit 1
fi

# CLAUDE_PROJECT_DIR now available without recalculation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
```

**Advantages**:
1. **Handles complex state**: Arrays, functions (via declare -fp), associative arrays
2. **Single source of truth**: State calculated once, used multiple times
3. **No recalculation overhead**: Read from file instead of recomputing
4. **Type safety**: `declare -p` preserves variable types and attributes
5. **Audit trail**: State file documents what was calculated in Block 1
6. **Supports rollback**: Can inspect state file if workflow fails

**Disadvantages**:
1. **File I/O overhead**: Read/write operations add 10-20ms per block
2. **Race conditions**: Multiple workflows running concurrently may conflict
3. **Cleanup complexity**: When to delete temp files? What if workflow crashes?
4. **Error handling**: Must handle missing/corrupted state files
5. **Security considerations**: Sensitive data (tokens, passwords) in temp files
6. **Path bootstrap**: Must know CLAUDE_PROJECT_DIR to construct statefile path (chicken-egg problem)

**Performance Analysis**:
```
File-based overhead per workflow:
- Write state (Block 1): 5-10ms
- Read state (Block 2-N): 3-5ms per block
- Total for 3 blocks: ~20ms write + 6-10ms reads = 26-30ms

Comparison to recalculation:
- Recalculation: 150ms (3 × 50ms)
- File-based: 30ms (1 write + 2 reads)
- Savings: 120ms (80% faster)
```

**Viability Assessment**: **Optimal for complex state** (arrays, functions, large data structures) where recalculation is expensive (>100ms) or impossible. Trade-off: adds complexity and I/O overhead for 80% performance gain over recalculation.

**Real-World Usage** (checkpoint-utils.sh:58-100):
- `/implement` command uses checkpoint system for workflow resume
- Saves: phase number, plan path, task status, test results
- Schema versioned: Currently v1.3
- Location: `.claude/data/checkpoints/{workflow}_{project}_{timestamp}.json`
- Demonstrates mature file-based state pattern

**Bootstrap Pattern for State Files**:
```bash
# Solution to chicken-egg problem: Use same detection for statefile path
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
STATEFILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_state.sh"
```

This pattern recalculates CLAUDE_PROJECT_DIR just once (in state file path construction), then all subsequent blocks read from file.

### Finding 5: Architectural Trade-Offs Matrix

| Dimension | Single Block | Multiple Blocks + Recalculation | Multiple Blocks + File State |
|-----------|--------------|--------------------------------|------------------------------|
| **Transformation Risk** | High (>400 lines) | None (<200 lines per block) | None (<200 lines per block) |
| **State Propagation** | Natural (same shell) | Manual (recalculate) | Automatic (read file) |
| **Performance** | Optimal (0ms overhead) | Good (150ms recalc) | Best (30ms I/O) |
| **Code Duplication** | None | High (same calc in each block) | Minimal (calc once, read many) |
| **Complexity** | Low (linear flow) | Low (simple pattern) | Medium (file management) |
| **Complex State Support** | Full (arrays, functions) | Limited (simple values only) | Full (arrays, functions) |
| **Error Recovery** | Poor (lose all progress) | Good (independent blocks) | Excellent (state persisted) |
| **Maintainability** | Medium (large blocks hard to read) | Medium (duplication burden) | High (single calc, typed state) |
| **Race Condition Risk** | None | None | Possible (concurrent workflows) |
| **Bootstrap Complexity** | None | None | Medium (path to statefile) |

**Decision Factors**:

**Choose Single Block When**:
- Total bash <200 lines (well below transformation threshold)
- Simple, linear workflow
- No need for error recovery

**Choose Recalculation When** (Plan 584 choice):
- State is simple (single variables, paths)
- Recalculation is fast (<100ms per block)
- No complex data structures (arrays, functions)
- Want to avoid file I/O complexity

**Choose File-Based State When**:
- State is complex (arrays, functions, large data)
- Recalculation is expensive (>100ms) or impossible
- Need workflow resume capability
- Multiple blocks need same complex state

### Finding 6: Library Sourcing as Function State Alternative

**Problem**: Functions cannot be recalculated (no deterministic way to recreate function definition from name alone) and `export -f` doesn't persist between Bash invocations.

**Solution** (Plan 584, Changes 3-4): Source function library in each block that needs functions.

**Implementation** (Plan 584, lines 175-200):
```bash
# Block 4: Source library instead of inline definition + export -f
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi

# Source verification helpers library (provides verify_file_created function)
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found"
  exit 1
fi

# No export -f needed - Phase 1 will source the library itself
```

**Advantages**:
1. **Centralized functions**: One source of truth in library file
2. **No export needed**: Each block sources independently
3. **Maintainable**: Changes to function apply to all blocks
4. **Reusable**: Library can be used by multiple commands
5. **Testable**: Library functions can be tested in isolation

**Disadvantages**:
1. **Sourcing overhead**: ~5-10ms per source operation
2. **Path dependency**: Requires CLAUDE_PROJECT_DIR to construct library path
3. **Error handling**: Must handle missing library files

**Performance** (Plan 584 context):
- Library sourcing: ~10ms per block
- Alternative (inline definition): 0ms, but 57 lines of duplicated code
- Trade-off: Acceptable overhead for maintainability gain

**Pattern Generalization**:
- **Recalculation** works for simple values (strings, numbers)
- **Library sourcing** works for functions
- **File-based state** works for complex data structures (arrays)

This creates a three-tier strategy based on state complexity.

### Finding 7: Real-World Architectural Evolution

**Timeline of /coordinate Command Architecture**:

**Phase 1: Original Design** (pre-Plan 583)
- Single 402-line bash block for Phase 0
- Used indirect variable expansion: `${!WORKFLOW_SCOPE}`
- Error rate: 3-5 transformation errors per run
- Symptom: `bash: ${\\!varname}: bad substitution`

**Phase 2: Split Blocks to Fix Transformation** (Plan 583, commit 3d8e49df)
- Split into 3 blocks: 176 + 168 + 77 lines
- Exported CLAUDE_PROJECT_DIR in Block 1
- Relied on export to propagate to Blocks 2-3
- Result: Transformation errors eliminated, BUT export didn't work

**Phase 3: Discovery of Export Limitation** (Plan 583 execution)
- Block 3 received empty CLAUDE_PROJECT_DIR despite Block 1 export
- Error: `/.claude/lib/: No such file or directory` (line 550 reference in Plan 584)
- Claude AI manually re-exported as workaround (coordinate_output.md line 57-58)
- Root cause: Bash tool limitation (GitHub #334, #2508)

**Phase 4: Stateless Recalculation Solution** (Plan 584, proposed)
- Add CLAUDE_PROJECT_DIR recalculation to Blocks 2-3
- Replace inline function definition with library sourcing (Blocks 4-5)
- Performance: 150ms recalculation overhead (acceptable for <500ms Phase 0 target)
- Trade-off: Code duplication vs reliability

**Key Insight**: Architecture evolved through iterative problem-solving:
1. Large block problem → Split blocks solution
2. Split blocks created export problem → Recalculation solution
3. Function export problem → Library sourcing solution

Each solution optimal for its specific constraint (transformation limit, export limitation, function propagation).

### Finding 8: Phase 0 Optimization Context

**Source**: `/home/benjamin/.config/.claude/docs/guides/phase-0-optimization.md` (lines 1-100)

Phase 0 (Location Detection) has strict performance requirements that constrain architectural choices:

**Performance Budget**:
- Target: <500ms for entire Phase 0
- Includes: Project detection, library loading, path calculation, scope detection
- Historical performance: 25.2 seconds with agent-based detection (75,600 tokens)
- Current performance with library: <1 second (11,000 tokens)

**Optimization Priorities** (lines 10-18):
1. **Token Reduction**: 85% savings (75,600 → 11,000 tokens)
2. **Speed Improvement**: 25x faster (25.2s → <1s)
3. **Directory Pollution**: Eliminated (400-500 empty dirs → 0 with lazy creation)
4. **Context Before Research**: Zero tokens (paths calculated, not created)

**Implication for Plan 584**:
- 150ms recalculation overhead = 15% of 1000ms Phase 0 budget
- Still leaves 850ms for other Phase 0 operations
- Well within acceptable range given reliability improvement

**Lazy Creation Pattern** (lines 57-76):
```bash
# Don't create directories in Phase 0
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"

# Create only when artifact written (agent responsibility)
echo "Report content" > "${REPORTS_DIR}/001_report.md"  # mkdir -p in agent
```

This pattern avoids directory pollution from failed workflows, aligning with "fail fast, clean state" philosophy.

**Connection to Bash Architecture**: Phase 0 must complete quickly and cleanly. File-based state persistence (30ms overhead) would be even better performance-wise than recalculation (150ms), but recalculation chosen for simplicity and avoiding file management complexity.

## Recommendations

### Recommendation 1: Adopt Stateless Recalculation for Simple State (Implement Plan 584)

**For**: Commands with simple state (project paths, single variables) that can be recalculated quickly (<100ms per block).

**Rationale**:
- Optimal balance of reliability, simplicity, and performance
- Avoids file I/O complexity and race conditions
- 150ms overhead acceptable within Phase 0 budget (<500ms target)
- Idempotent pattern is defensive and safe
- Proven pattern: git-based detection used successfully in Block 1

**Implementation** (from Plan 584):
```bash
# Standard pattern for all blocks needing CLAUDE_PROJECT_DIR
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
```

**Apply to**:
- `/coordinate` (Plan 584 implementation)
- `/orchestrate` (if Phase 0 bash blocks added)
- Any command with multiple bash blocks needing project directory

**Do NOT apply to**:
- Complex state (arrays, user input, API responses) - use file-based instead
- Expensive calculations (>100ms) - use file-based instead
- State that cannot be recalculated deterministically - use file-based instead

### Recommendation 2: Use Library Sourcing for Function Propagation

**For**: Functions that need to be available across multiple bash blocks.

**Rationale**:
- Functions cannot be recalculated (no deterministic way to recreate from name)
- `export -f` doesn't persist between Bash invocations (confirmed in Plan 584)
- Library sourcing centralizes function definitions (single source of truth)
- ~10ms sourcing overhead negligible compared to 57 lines of inline duplication

**Implementation** (from Plan 584, Changes 3-4):
```bash
# Each block that needs functions: source the library
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found" >&2
  exit 1
fi

# Functions now available: verify_file_created, etc.
```

**Create libraries for**:
- Verification functions (verify_file_created, verify_directory, etc.)
- Formatting functions (format_status, format_progress, etc.)
- Workflow utilities (detect_scope, calculate_complexity, etc.)

**Benefits**:
- Eliminates code duplication (Plan 584: removes 57 lines from coordinate.md)
- Centralized maintenance (one place to update function)
- Testable in isolation (library can have unit tests)

### Recommendation 3: Reserve File-Based State for Complex State and Workflow Resume

**For**: Commands that need workflow resume capability OR complex state that's expensive to recalculate.

**Rationale**:
- 80% performance improvement over recalculation (30ms vs 150ms)
- Enables workflow resume after failure (critical for long-running operations)
- Supports complex data structures (arrays, associative arrays)
- Proven pattern: checkpoint-utils.sh demonstrates mature implementation

**Implementation Pattern**:
```bash
# Block 1: Calculate and persist
STATEFILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_$$.sh"
mkdir -p "$(dirname "$STATEFILE")"

# Calculate state once
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
declare -A REPORT_PATHS=(
  ["auth"]="/path/to/auth_report.md"
  ["api"]="/path/to/api_report.md"
)
RESEARCH_COMPLEXITY="high"

# Persist with type safety
{
  declare -p CLAUDE_PROJECT_DIR
  declare -p REPORT_PATHS
  declare -p RESEARCH_COMPLEXITY
} > "$STATEFILE"

# Cleanup trap
trap "rm -f '$STATEFILE'" EXIT

# Block 2-N: Load state
STATEFILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_$$.sh"
if [ -f "$STATEFILE" ]; then
  source "$STATEFILE"
else
  echo "ERROR: State file missing at $STATEFILE" >&2
  exit 1
fi

# State available: REPORT_PATHS["auth"], etc.
```

**Apply to**:
- `/implement` - Already uses checkpoint system for phase resume
- `/orchestrate` - Could use for multi-phase state (research → plan → implement)
- `/coordinate` - Only if workflow resume needed (not in Plan 584 scope)

**Race Condition Mitigation**:
- Use process-specific filenames: `workflow_state_$$.sh` (includes PID)
- Or use workflow-specific: `coordinate_${TOPIC_NUMBER}_state.sh`
- Cleanup with trap: `trap "rm -f '$STATEFILE'" EXIT`

**Security Considerations**:
- Don't write sensitive data (tokens, passwords) to state files
- Use restrictive permissions: `chmod 600 "$STATEFILE"`
- Store in `.claude/tmp/` (gitignored by default)

### Recommendation 4: Document Architectural Decision in bash-tool-limitations.md

**Action**: Add comprehensive section to bash-tool-limitations.md explaining architectural trade-offs and patterns.

**Content** (structure):
1. **Export Persistence Limitation**: Document GitHub #334, #2508 with examples
2. **Architectural Patterns**: Three patterns (single block, recalculation, file-based)
3. **Decision Matrix**: When to use each pattern (Finding 5 table)
4. **Real-World Examples**: Link to Plan 584, coordinate.md evolution
5. **Performance Guidelines**: Phase 0 budget context (Finding 8)
6. **Implementation Snippets**: Copy-paste ready code for each pattern

**Rationale**:
- Prevent future developers from rediscovering these issues
- Provide clear decision framework for architectural choices
- Establish documented patterns for bash block design
- Support onboarding and maintenance

**Location**: Add after "Large Bash Block Transformation" section (line 296 in bash-tool-limitations.md)

### Recommendation 5: Create Bash Block Architecture Standards

**Action**: Add new section to command_architecture_standards.md for bash block design.

**Content**:
1. **Block Size Limit**: 200 lines recommended, 400 lines maximum
2. **State Propagation**: Three patterns with decision criteria
3. **Function Propagation**: Library sourcing required (no export -f)
4. **Performance Budgets**: Phase 0 <500ms, per-block recalculation <100ms
5. **Error Handling**: Each block must handle missing state
6. **Testing**: Blocks should be testable independently

**Example Standard**:
```markdown
## Standard 14: Bash Block Architecture

**Principle**: Bash blocks in command files must balance size constraints, state propagation needs, and performance requirements.

**Block Size Requirements**:
- RECOMMENDED: <200 lines per block
- MAXIMUM: 400 lines per block (transformation threshold)
- RATIONALE: Blocks >400 lines trigger character escaping in markdown extraction

**State Propagation Patterns** (choose based on state complexity):

1. **Stateless Recalculation** (simple values, fast computation):
   - Each block independently calculates state
   - Example: `CLAUDE_PROJECT_DIR=$(git rev-parse --show-toplevel)`
   - Performance: <100ms per block
   - Use when: Recalculation cheap and deterministic

2. **Library Sourcing** (functions):
   - Source library in each block needing functions
   - Example: `source "${CLAUDE_PROJECT_DIR}/.claude/lib/utils.sh"`
   - Performance: ~10ms per source
   - Use when: Functions need to be available

3. **File-Based State** (complex data, expensive calculation):
   - Write state to file in Block 1, read in subsequent blocks
   - Example: `declare -p COMPLEX_ARRAY > "$STATEFILE"`
   - Performance: ~30ms total I/O
   - Use when: Recalculation >100ms or impossible

**Decision Criteria**: See bash-tool-limitations.md "Architectural Patterns" section.
```

**Enforcement**:
- Add validation to test suite (check block sizes in coordinate.md, orchestrate.md)
- Code review checklist item for new commands

## References

### Primary Research Sources

- `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md` (lines 1-297)
  - Bash tool escaping behavior and large block transformation issues
  - Export persistence limitation context
  - Real-world examples from /coordinate evolution

- `/home/benjamin/.config/.claude/specs/584_fix_coordinate_export_persistence/plans/001_fix_export_persistence.md` (lines 1-836)
  - Complete implementation plan for stateless recalculation pattern
  - Performance analysis and trade-offs (lines 639-655)
  - Four detailed changes with rationale (lines 78-257)
  - Evidence from coordinate_output.md (lines 659-719)

- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-200)
  - Command architecture principles and execution enforcement
  - Standard 0: Imperative language patterns
  - Inline template requirements vs external references

- `/home/benjamin/.config/.claude/docs/guides/phase-0-optimization.md` (lines 1-100)
  - Performance budget context for Phase 0
  - Historical performance: 75,600 tokens, 25.2s (agent-based)
  - Current performance: 11,000 tokens, <1s (library-based)
  - Target: <500ms for Phase 0 operations

- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (lines 1-100)
  - Mature implementation of file-based state persistence
  - Checkpoint schema v1.3 with wave tracking support
  - Real-world usage in /implement command for workflow resume

### Web Research Sources

- Stack Overflow: "How to store state between two consecutive runs of a bash script"
  - URL: https://stackoverflow.com/questions/63084354
  - File-based storage patterns using declare -p
  - Trade-offs: simplicity vs type safety
  - Multi-variable persistence with trap EXIT

- GitHub Issues:
  - #334: Environment Variables and Shell Functions Not Persisting (March 2025)
  - #2508: [DOCS] Environment variables don't persist between bash commands (June 2025)
  - Status: Unresolved as of November 2025

### Codebase Evidence

- `/home/benjamin/.config/.claude/commands/coordinate.md`
  - Line 550: `export CLAUDE_PROJECT_DIR` (Block 1)
  - Line 887: Comment referencing Block 1 export (Block 3)
  - Lines 537-850: Three-block Phase 0 structure (176 + 168 + 77 lines)
  - Evidence of architectural evolution through Plans 583-584

- `/home/benjamin/.config/.claude/specs/coordinate_output.md` (referenced in Plan 584)
  - Lines 29-46: Empty CLAUDE_PROJECT_DIR in Block 3
  - Lines 57-62: Manual workaround by Claude AI
  - Lines 90-104: Function export failure (verify_file_created)

### Related Documentation

- `.claude/docs/concepts/patterns/checkpoint-recovery.md` - State preservation patterns
- `.claude/docs/guides/command-development-guide.md` - Command development best practices
- `.claude/docs/reference/library-api.md` - Library function documentation
