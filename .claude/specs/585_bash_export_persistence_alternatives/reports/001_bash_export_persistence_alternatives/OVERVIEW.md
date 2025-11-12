# Research Overview: Bash Export Persistence Alternatives

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-synthesizer
- **Topic Number**: 585
- **Individual Reports**: 4 reports synthesized
- **Reports Directory**: /home/benjamin/.config/.claude/specs/585_bash_export_persistence_alternatives/reports/001_bash_export_persistence_alternatives/
- **Context**: Alternatives to current export persistence fix plan at /home/benjamin/.config/.claude/specs/584_fix_coordinate_export_persistence/plans/001_fix_export_persistence.md

## Executive Summary

This research synthesizes findings on alternatives to bash export persistence for the /coordinate command, which faces a fundamental architectural constraint: bash exports do not persist between separate Bash tool invocations in Claude Code. The investigation reveals that the stateless recalculation pattern (already proposed in Plan 584) represents the optimal solution, balancing reliability, simplicity, and performance. File-based state persistence offers superior performance (80% faster) but adds complexity appropriate only for complex state or workflow resume scenarios. The research identifies three architectural patterns (single large block, multiple blocks with recalculation, multiple blocks with file-based state) and provides a decision matrix based on state complexity and performance requirements.

## Research Structure

This overview synthesizes findings from four subtopic reports:

1. **[Bash Session Persistence Patterns](001_bash_session_persistence_patterns.md)** - Industry best practices for bash state serialization including declare -p, JSON checkpoints, terminal multiplexers, and project-specific environment managers like direnv
2. **[State Management Across Tool Invocations](002_state_management_across_tool_invocations.md)** - Comprehensive analysis of how CLI tools (kubectl, docker, terraform, git, AWS CLI) implement persistent state across invocations using file-based contexts, hierarchical configuration, and XDG Base Directory compliance
3. **[Alternative Bash Tool Architectures](003_alternative_bash_tool_architectures.md)** - Deep dive into bash block architecture constraints, transformation errors above 400 lines, and three architectural patterns with trade-off analysis based on Plan 584 implementation experience
4. **[Inter-Process Communication Lightweight Methods](004_inter_process_communication_lightweight_methods.md)** - Technical evaluation of IPC mechanisms (named pipes, shared memory, temporary files, dot-sourcing) for bash block state transfer with performance benchmarks and security considerations

## Cross-Report Findings

### Pattern 1: Stateless Recalculation is Optimal for Simple State

All four reports converge on the conclusion that the stateless recalculation pattern (Plan 584 solution) is the most pragmatic approach for the /coordinate use case. As noted in [Alternative Bash Tool Architectures](./003_alternative_bash_tool_architectures.md), recalculation offers:

- **Zero inter-block coordination required**: Each block self-sufficient
- **150ms total overhead**: Acceptable within Phase 0 <500ms budget
- **Avoids transformation errors**: Each block <200 lines
- **Simple implementation**: 5-10 lines per block

The [IPC Methods](./004_inter_process_communication_lightweight_methods.md) report confirms this pattern as superior to complex IPC workarounds: "Rather than fighting the tool's limitations with complex IPC workarounds, embrace stateless bash blocks."

### Pattern 2: File-Based Persistence for Complex State Only

The [Bash Session Persistence](./001_bash_session_persistence_patterns.md) and [Tool Architectures](./003_alternative_bash_tool_architectures.md) reports both identify file-based state persistence as optimal for complex scenarios:

- **JSON checkpoints**: Used successfully in checkpoint-utils.sh for workflow resume
- **80% performance improvement**: 30ms file I/O vs 150ms recalculation
- **Supports complex state**: Arrays, associative arrays, large data structures
- **Schema versioning**: Enables migration (currently v1.3 in codebase)

However, both reports emphasize this adds complexity appropriate only when recalculation is expensive (>100ms) or impossible.

### Pattern 3: Configuration Hierarchy Best Practices

The [State Management Across Tool Invocations](./002_state_management_across_tool_invocations.md) report provides comprehensive precedence patterns from industry tools:

**Standard Precedence Order** (Git, AWS CLI, Docker, Kubectl):
1. Command-line flags
2. Environment variables
3. Context-specific config
4. Global config file
5. Default values

This hierarchy appears in all surveyed tools and should guide future /coordinate enhancements if persistent context switching becomes a requirement.

### Pattern 4: XDG Base Directory Compliance

The [State Management](./002_state_management_across_tool_invocations.md) report identifies XDG compliance as modern best practice for CLI tools, organizing files as:

- `$XDG_CONFIG_HOME/tool/` - Configuration files
- `$XDG_STATE_HOME/tool/` - State data (current context, history)
- `$XDG_CACHE_HOME/tool/` - Cache data
- `$XDG_RUNTIME_DIR/tool/` - Runtime files

The codebase already partially follows this pattern (`.claude/data/checkpoints/`), but future enhancements could improve XDG alignment.

### Anti-Pattern: Complex IPC for Simple Use Cases

The [IPC Methods](./004_inter_process_communication_lightweight_methods.md) report definitively rejects named pipes and shared memory for /coordinate:

- **Named Pipes (FIFOs)**: Require 30-50 lines synchronization code, risk deadlocks, no reliability advantage
- **Shared Memory (/dev/shm)**: <1ms performance gain for <1KB state files, requires explicit cleanup, no functional advantage over /tmp with filesystem caching

This finding is critical: the recalculation pattern's simplicity outweighs theoretical performance optimizations that add complexity.

### Constraint: Bash Tool Architectural Limitation

Three reports ([Tool Architectures](./003_alternative_bash_tool_architectures.md), [IPC Methods](./004_inter_process_communication_lightweight_methods.md), [Session Persistence](./001_bash_session_persistence_patterns.md)) independently confirm the root cause:

**Export Non-Persistence**: Bash tool runs each invocation in a separate shell session despite documentation suggesting persistence. GitHub Issues #334 (March 2025) and #2508 (June 2025) remain unresolved as of 2025-11-04.

This constraint eliminates any solution relying on shell environment propagation via `export` or `export -f`.

## Detailed Findings by Topic

### Bash Session Persistence Patterns

**Key Finding**: Industry uses diverse persistence mechanisms optimized for different state complexity levels—from simple `declare -p` serialization for cron job counters to sophisticated JSON checkpoints with schema versioning for complex workflows.

**Codebase Pattern**: The project's checkpoint-utils.sh demonstrates mature JSON checkpoint implementation with:
- Schema version 1.3 tracking
- Plan modification time for staleness detection
- Atomic writes using temp files
- Graceful jq fallback

**Critical Limitation**: `declare -p` only works within same bash version, same locale, same system, and variables become function-scoped if sourcing occurs within a function.

**Recommendation Synthesis**: Use JSON checkpoints for multi-phase workflows (like /implement), use `declare -p` for simple single-script state, use direnv for project-specific environments.

[Full Report](001_bash_session_persistence_patterns.md)

### State Management Across Tool Invocations

**Key Finding**: Modern CLI tools (kubectl, docker, terraform, git, AWS CLI) universally favor file-based state with explicit switching commands over relying on shell environment variables. All implement similar configuration hierarchies with flags > env vars > config files > defaults.

**Best Practice Patterns**:
- **Explicit context switching**: `kubectl config use-context`, `docker context use`
- **XDG compliance**: Clean home directory with standardized paths
- **File locking**: Terraform state locking prevents concurrent modification corruption
- **Hierarchical config**: Git's local > global > system precedence model

**Anti-Pattern Identified**: Relying on `export VAR=value` for cross-invocation state—lost on shell exit, not available to other terminals, difficult to debug, no validation.

**Recommendation**: If /coordinate needs persistent context in future, implement kubectl-style context file pattern with explicit switching commands, not environment variable exports.

[Full Report](002_state_management_across_tool_invocations.md)

### Alternative Bash Tool Architectures

**Key Finding**: Analysis of Plan 584 and /coordinate evolution reveals fundamental tension between bash block size limits (400 lines trigger transformation errors) and export persistence limitations, yielding three viable architectural patterns with clear decision criteria.

**Architectural Trade-Offs Matrix**:

| Pattern | Transformation Risk | Performance | Code Duplication | Complexity | Complex State Support |
|---------|-------------------|-------------|------------------|------------|---------------------|
| Single Block | High (>400 lines) | Optimal (0ms) | None | Low | Full |
| Recalculation | None (<200 lines) | Good (150ms) | High | Low | Limited |
| File-based | None (<200 lines) | Best (30ms) | Minimal | Medium | Full |

**Real-World Evolution**: /coordinate went through 4 phases:
1. Single 402-line block → transformation errors
2. Split to 3 blocks with exports → export persistence failure
3. Manual workaround discovery → Plan 584 stateless recalculation
4. Future option: File-based state if workflow resume needed

**Critical Decision Criteria**: Choose recalculation when state is simple and calculation <100ms. Choose file-based when recalculation >100ms or impossible (arrays, user input, API tokens).

[Full Report](003_alternative_bash_tool_architectures.md)

### Inter-Process Communication Lightweight Methods

**Key Finding**: Technical evaluation of IPC mechanisms (FIFOs, shared memory, temporary files, dot-sourcing) confirms that for /coordinate's use case, recalculation pattern avoids complexity while temporary files with predictable names provide viable fallback if actual state transfer becomes necessary.

**Performance Benchmarks**:
- Named Pipes (FIFOs): Zero disk I/O but requires 30-50 lines synchronization, risk of deadlock
- Shared Memory (/dev/shm): <1ms gain for <1KB state vs /tmp with filesystem caching
- Temporary Files: ~30ms total (write + 2 reads), 80% faster than recalculation
- Recalculation: ~150ms total (3 blocks × 50ms git detection)

**Security Finding**: Both `source` and `eval` execute arbitrary code, requiring secure file handling. State files generated by Block 1 are safe to source in Block 3, but must use restrictive permissions (chmod 600) if containing sensitive data.

**Bootstrap Problem**: All file-based approaches face chicken-egg problem—Block 3 needs CLAUDE_PROJECT_DIR to construct state file path, but that's the variable we're trying to transfer. Solution: recalculate once for path construction, then read all other state from file.

[Full Report](004_inter_process_communication_lightweight_methods.md)

## Recommended Approach

### Primary Recommendation: Implement Stateless Recalculation (Plan 584)

**Pattern**: Each bash block independently recalculates needed state using conditional checks and fast operations.

**Implementation**:
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
- /coordinate Blocks 2-3 (Plan 584 scope)
- Functions: Source libraries instead of inline definitions + export -f
- Derived paths: Recalculate from CLAUDE_PROJECT_DIR in each block

**Rationale**:
- Optimal balance: reliability + simplicity + acceptable performance
- Aligns with Claude Code Bash tool constraints
- 150ms overhead within Phase 0 <500ms budget
- Each block self-sufficient and independently testable
- No file I/O complexity or race conditions
- Proven reliable (manual workaround succeeded)

### Secondary Recommendation: Reserve File-Based State for Future Complex Scenarios

**When to Use**: If /coordinate evolves to need:
- Workflow resume capability (like /implement checkpoint system)
- Complex state: arrays, associative arrays, large data structures
- Expensive calculations (>100ms) that cannot be recalculated
- State that's non-deterministic (user input, API responses)

**Implementation Pattern**:
```bash
# Block 1: Calculate once and persist
STATEFILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_$$"
mkdir -p "$(dirname "$STATEFILE")"
declare -p CLAUDE_PROJECT_DIR WORKFLOW_SCOPE REPORT_PATHS > "$STATEFILE"
trap "rm -f '$STATEFILE'" EXIT

# Block 2-N: Load state
source "$STATEFILE" || { echo "ERROR: State file missing" >&2; exit 1; }
```

**Race Condition Mitigation**: Use process-specific filenames ($$) or workflow-specific identifiers, implement cleanup with trap handlers.

### Tertiary Recommendation: Document Bash Tool Limitations

**Action**: Add export persistence limitation to bash-tool-limitations.md and command development guides.

**Content**:
1. Export non-persistence explanation with GitHub issue references (#334, #2508)
2. Three architectural patterns (single block, recalculation, file-based)
3. Decision matrix based on state complexity and performance requirements
4. Real-world examples from Plan 584 and coordinate.md evolution
5. Performance guidelines within Phase 0 budget context

**Location**: Add after "Large Bash Block Transformation" section in bash-tool-limitations.md

## Constraints and Trade-offs

### Constraint 1: Claude Code Bash Tool Export Non-Persistence

**Impact**: Eliminates any solution relying on shell environment propagation between separate Bash tool invocations.

**Evidence**: GitHub Issues #334 (March 2025), #2508 (June 2025), unresolved as of 2025-11-04. Confirmed through /coordinate testing where all 11 export statements in Block 1 failed to reach Block 3.

**Mitigation**: Embrace stateless bash blocks or implement explicit file-based state transfer.

### Constraint 2: Bash Block Size Limit (400 Lines)

**Impact**: Blocks exceeding ~400 lines undergo character escaping during markdown extraction, causing syntax errors like `bash: ${\\!varname}: bad substitution`.

**Evidence**: /coordinate Phase 0 had 402-line block causing 3-5 transformation errors per run. Splitting to 3 blocks (176 + 168 + 77 lines) eliminated all errors.

**Mitigation**: Keep blocks <200 lines (recommended) or <400 lines (maximum).

### Trade-off 1: Code Duplication vs Reliability

**Recalculation Pattern**: Duplicates git detection logic across multiple blocks.

**Alternatives**:
- Single large block: No duplication but transformation errors (not viable)
- File-based state: Minimal duplication but added complexity

**Decision**: Accept duplication for simple, fast operations (<100ms). Use file-based state for complex scenarios.

### Trade-off 2: Performance vs Simplicity

**Recalculation**: 150ms overhead (3 blocks × 50ms git detection)
**File-based**: 30ms overhead (1 write + 2 reads), 80% faster

**150ms savings**: Not significant within multi-second agent invocation workflows.

**Decision**: Prioritize simplicity (recalculation) over marginal performance gain (file-based) for /coordinate's current use case.

### Trade-off 3: Library Sourcing Overhead vs Inline Functions

**Library Sourcing**: ~10ms per block, centralized maintenance
**Inline Functions**: 0ms overhead but 57 lines duplicated code (Plan 584 evidence)

**Decision**: Accept 10ms sourcing overhead for maintainability gain. Libraries provide single source of truth, testability, and reusability across commands.

### Trade-off 4: XDG Compliance vs Legacy Paths

**XDG-Compliant**: `~/.config/tool/`, `~/.local/state/tool/`, cleaner home directory
**Current Pattern**: `.claude/data/checkpoints/`, works but non-standard

**Decision**: Current pattern functional. XDG migration is low-priority enhancement, consider for future major refactoring.

## Integration with Existing Systems

### Checkpoint Recovery Pattern

The codebase already implements sophisticated file-based state persistence in checkpoint-utils.sh for /implement command workflow resume. This pattern should be extended to /coordinate only if workflow resume becomes a requirement.

**Current Usage**: /implement saves phase number, plan path, task status, test results to `.claude/data/checkpoints/{workflow}_{project}_{timestamp}.json`

**Potential /coordinate Extension**: Could save research report paths, workflow scope, complexity metadata for resume capability after failures.

### Phase 0 Optimization Context

The recalculation pattern fits within Phase 0 performance budget (<500ms target). Historical context from phase-0-optimization.md:

- Agent-based detection: 75,600 tokens, 25.2 seconds
- Library-based detection: 11,000 tokens, <1 second (25x faster)
- Recalculation overhead: 150ms (15% of 1s Phase 0, acceptable)

### Library Sourcing Pattern

The library-sourcing.sh demonstrates consolidated sourcing with deduplication, providing a model for /coordinate Block 4-5 function propagation:

**Load Order**: workflow-detection.sh → error-handling.sh → checkpoint-utils.sh → unified-logger.sh → unified-location-detection.sh → metadata-extraction.sh → context-pruning.sh

**Deduplication**: O(n²) algorithm acceptable for ~10 libraries, prevents duplicate sourcing.

### Lazy Directory Creation

The unified-location-detection.sh implements lazy directory creation (80% reduction in mkdir calls, eliminated 400-500 empty directories), aligning with recalculation pattern's "fail fast, clean state" philosophy.

## Future Considerations

### If Persistent Context Switching Required

Should /coordinate need persistent context switching (e.g., user working on multiple workflows, switching between them across terminal sessions):

**Pattern**: Implement kubectl-style context management
- Context definitions: `~/.config/claude/contexts.json`
- Current context: `~/.local/state/claude/current-context`
- Switching: `/coordinate context use <name>`
- Override: `CLAUDE_CONTEXT=<name> /coordinate <workflow>`

**Precedence**: Flags > env vars > current context > defaults (standard hierarchy from State Management report)

### If Workflow Resume Becomes Priority

**Pattern**: Extend checkpoint-utils.sh pattern to /coordinate
- Checkpoint location: `.claude/data/checkpoints/coordinate_{workflow}_{timestamp}.json`
- Schema: Phase number, research report paths, workflow scope, complexity metadata
- Resume: `/coordinate resume [checkpoint-path]`

**Performance**: File-based state (30ms) superior to recalculation (150ms), justifies complexity.

### If Complex State Required

**Trigger Scenarios**:
- User input collected in Phase 0, needed in Phase 7
- API responses from research phase, needed in planning phase
- Large arrays of file paths (>100 files)

**Pattern**: Temporary file with predictable name
```bash
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_${TOPIC_NUM}_state.sh"
```

**Cleanup**: Trap handler for reliability: `trap "rm -f '$STATE_FILE'" EXIT`

## References

### Codebase Files

- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - JSON checkpoint implementation (schema v1.3)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Git-based project detection, lazy directory creation
- `/home/benjamin/.config/.claude/lib/library-sourcing.sh` - Consolidated library sourcing with deduplication
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` - Workflow path initialization, export pattern
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Multi-block bash architecture (3 blocks: 176 + 168 + 77 lines)
- `/home/benjamin/.config/.claude/docs/guides/phase-0-optimization.md` - Performance budget context (<500ms target)
- `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md` - Transformation errors, export limitations

### External Sources

- GitHub Issues: #334 (Environment Variables Not Persisting, March 2025), #2508 (Bash Commands Export Limitation, June 2025)
- Stack Overflow #63084354: "How to store state between two consecutive runs of a bash script"
- Stack Overflow #20701757: "TMUX setting environment variables for sessions"
- Kubernetes Kubectl Documentation: Context management patterns
- Docker Context Management: Explicit context switching mechanisms
- Terraform Workspaces: State isolation and locking patterns
- Git Config Documentation: Hierarchical configuration (local > global > system)
- AWS CLI Configuration: Precedence order, SSO session management
- XDG Base Directory Specification: freedesktop.org standard for CLI tool organization
- direnv Documentation: Automatic project-specific environment activation
- tmux Manual: Session persistence, environment variable update-environment

### Research Reports

1. [Bash Session Persistence Patterns](001_bash_session_persistence_patterns.md) - 393 lines
2. [State Management Across Tool Invocations](002_state_management_across_tool_invocations.md) - 531 lines
3. [Alternative Bash Tool Architectures](003_alternative_bash_tool_architectures.md) - 649 lines
4. [Inter-Process Communication Lightweight Methods](004_inter_process_communication_lightweight_methods.md) - 339 lines

**Total Research**: 1,912 lines across 4 comprehensive reports
