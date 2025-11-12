# Infrastructure Integration Patterns Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Infrastructure integration patterns for coordinate improvements
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The .claude/ infrastructure provides a comprehensive library ecosystem (42 modules) organized into 9 functional domains with clear dependency hierarchies and standardized sourcing patterns. Coordinate improvements leverage three foundational libraries (workflow-state-machine.sh, state-persistence.sh, library-sourcing.sh) that implement state-based orchestration with 48.9% code reduction and 67% performance improvements. These patterns are reusable across all orchestration commands through Standard 13 (CLAUDE_PROJECT_DIR detection), Standard 0 (execution enforcement with verification checkpoints), and the bash block execution model requiring explicit state persistence between subprocess boundaries.

## Findings

### Current State Analysis

#### Library Infrastructure Organization

The `.claude/lib/` directory contains **42 modular utility libraries** organized into 9 functional domains (line 3, /home/benjamin/.config/.claude/lib/README.md):

1. **Parsing & Plans** (3 modules): plan-core-bundle.sh consolidates parse-plan-core.sh, plan-structure-utils.sh, plan-metadata-utils.sh
2. **Artifact Management** (2 modules): artifact-creation.sh, artifact-registry.sh
3. **Error Handling & Validation** (1 module): error-handling.sh with transient/permanent/fatal classification
4. **Document Conversion** (5 modules): convert-core.sh with DOCX/PDF/Markdown bidirectional conversion
5. **Adaptive Planning** (3 modules): checkpoint-utils.sh, complexity-utils.sh, unified-logger.sh
6. **Agent Coordination** (3 modules): agent-registry-utils.sh, agent-invocation.sh, workflow-detection.sh
7. **Analysis & Metrics** (2 modules): analysis-pattern.sh, analyze-metrics.sh
8. **Template System** (3 modules): parse-template.sh, substitute-variables.sh, template-integration.sh
9. **Infrastructure** (6 modules): progress-dashboard.sh, auto-analysis-utils.sh, json-utils.sh, timestamp-utils.sh

**Library Classification System** (lines 44-105, /home/benjamin/.config/.claude/lib/README.md):

- **Core Libraries** (7 modules): Automatically sourced by orchestration commands via library-sourcing.sh
  - unified-location-detection.sh: 85% token reduction, 25x speedup vs agent-based detection
  - error-handling.sh: Fail-fast error handling with retry logic
  - checkpoint-utils.sh: State preservation for resumable workflows
  - unified-logger.sh: Structured logging with rotation (10MB max, 5 files)
  - workflow-detection.sh: Workflow scope detection (research-only, research-and-plan, full-implementation, debug-only)
  - metadata-extraction.sh: 99% context reduction through metadata-only passing
  - context-pruning.sh: Context management for budget control

- **Workflow Libraries** (6 modules): Used by /orchestrate, /coordinate, /supervise, /implement
- **Specialized Libraries** (13 modules): Single-command use cases
- **Optional Libraries** (3 modules): Can be disabled without breaking core functionality

**Recent Consolidation** (Stage 3 - October 2025, lines 187-263):

- **plan-core-bundle.sh** (1,159 lines): Consolidates 3 modules, reduces sourcing overhead (3 files → 1)
- **unified-logger.sh** (717 lines): Consolidates adaptive-planning-logger.sh + conversion-logger.sh
- **base-utils.sh** (~100 lines): Eliminates 4 duplicate `error()` function implementations, breaks circular dependencies

#### State-Based Orchestration Architecture

Three foundational libraries implement coordinate improvements (lines 36-100, /home/benjamin/.config/.claude/lib/workflow-state-machine.sh):

**1. workflow-state-machine.sh** (17,326 bytes):
- **Purpose**: Formal state machine abstraction replacing implicit phase numbers with explicit states
- **Core States** (8 states): initialize, research, plan, implement, test, debug, document, complete
- **State Transition Table**: Validates allowed transitions (e.g., test → debug OR document, prevents invalid state changes)
- **API Functions** (lines 82-100):
  - `sm_init()`: Initialize from workflow description
  - `sm_transition()`: Atomic state transition with validation
  - `sm_is_terminal()`: Check if workflow complete
  - `sm_get_state()`: Query current state
- **Workflow Scope Integration**: Maps scope (research-only, research-and-plan, full-implementation, debug-only) to terminal state

**2. state-persistence.sh** (11,889 bytes):
- **Purpose**: GitHub Actions-style state persistence (selective file-based persistence, lines 1-75)
- **Performance**: 67% improvement for CLAUDE_PROJECT_DIR detection (50ms git rev-parse → 15ms file read, line 20)
- **API Functions** (lines 115-150):
  - `init_workflow_state()`: Create state file with environment variables (Block 1 only)
  - `load_workflow_state()`: Restore state with graceful degradation (Blocks 2+)
  - `append_workflow_state()`: GitHub Actions $GITHUB_OUTPUT pattern
  - `save_json_checkpoint()`: Atomic JSON writes with temp file + mv
- **Critical State Items** (7 items using file-based persistence, lines 47-55):
  - Supervisor metadata: 95% context reduction
  - Benchmark dataset: Phase 3 accumulation across 10 subprocess invocations
  - Implementation supervisor state: 40-60% time savings via parallel execution tracking
- **Decision Criteria** (lines 61-68): Use file-based state when accumulates across subprocess boundaries, non-deterministic, or recalculation expensive (>30ms)

**3. library-sourcing.sh** (2,142 bytes):
- **Purpose**: Unified library sourcing with deduplication (lines 1-122)
- **Deduplication Algorithm** (lines 63-80): O(n²) string matching removes duplicate library names (20 lines, 93% less code than memoization approach)
- **Performance Fix**: Solves /coordinate timeout caused by 6 duplicate library names passed to `source_required_libraries()` (line 109)
- **Core Libraries Sourced** (lines 48-56): workflow-detection.sh, error-handling.sh, checkpoint-utils.sh, unified-logger.sh, unified-location-detection.sh, metadata-extraction.sh, context-pruning.sh
- **Optional Libraries** (lines 58-61): Additional libraries passed as function arguments based on workflow scope

#### Bash Block Execution Model

**Subprocess Isolation Constraint** (lines 1-100, /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md):

Each bash block runs as **separate subprocess** (not subshell):
- Process ID (`$$`) changes between blocks → Cannot use `$$` for cross-block identifiers
- All environment variables reset → `export VAR=value` lost
- All bash functions lost → Must re-source libraries in each block
- Trap handlers fire at block exit → Cleanup traps fail in early blocks
- Current directory may reset → Use absolute paths always

**File System as Communication Channel** (lines 48-68):
- Only files written to disk persist across blocks
- State persistence requires explicit file writes
- Fixed semantic filenames required (not `$$`-based which changes per block)
- Libraries must be re-sourced in each block

**Validated Patterns** (lines 72-100):
- **Fixed semantic filenames**: `${HOME}/.claude/tmp/coordinate_workflow_desc.txt` instead of `workflow_$$_desc.txt`
- **Save-before-source pattern**: Save critical values (WORKFLOW_DESCRIPTION) to file BEFORE sourcing libraries that may overwrite variables
- **Library re-sourcing**: Each block sources libraries independently (no persistence of bash functions)
- **Explicit trap cleanup**: `trap "rm -f '$STATE_FILE'" EXIT` pattern, but aware trap fires at block exit not workflow exit

### Integration Points

#### Library Sourcing Patterns Across Commands

**Analysis of command library usage** (grep results, /home/benjamin/.config/.claude/commands/):

**Pattern 1: Direct sourcing for specialized commands** (lines 242, convert-docs.md):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert-core.sh" || {
  echo "ERROR: Failed to source convert-core.sh"
  exit 1
}
```
- Used when: Command needs 1-2 specific libraries
- Benefits: Avoids loading unnecessary core libraries
- Examples: /convert-docs (convert-core.sh), /analyze (analyze-metrics.sh), /plan (complexity-utils.sh line 30)

**Pattern 2: library-sourcing.sh for orchestration commands** (lines 132-150, coordinate.md):
```bash
source "${LIB_DIR}/library-sourcing.sh"

case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" ...)
    ;;
  full-implementation)
    REQUIRED_LIBS=("... dependency-analyzer.sh" "context-pruning.sh" ...)
    ;;
esac

if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success
else
  echo "ERROR: Failed to source required libraries"
  exit 1
fi
```
- Used when: Orchestration commands need core + workflow libraries
- Benefits: Automatic deduplication, consistent error handling
- Examples: /coordinate (line 132), /orchestrate (line 93), /supervise (line 68)

**Pattern 3: Conditional library sourcing based on workflow scope** (lines 134-147, coordinate.md):
- research-only: 6 libraries (no implementation/dependency libraries)
- research-and-plan: 8 libraries (adds metadata-extraction.sh, checkpoint-utils.sh)
- full-implementation: 10 libraries (adds dependency-analyzer.sh, context-pruning.sh)
- debug-only: 8 libraries (includes checkpoint-utils.sh for state management)

#### Architectural Standards Integration

**Standard 0: Execution Enforcement** (lines 51-463, /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md):

**Verification and Fallback Pattern** (lines 103-133):
```markdown
**MANDATORY VERIFICATION - Report File Existence**

After agents complete, YOU MUST execute this verification:

```bash
for topic in "${!REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${REPORT_PATHS[$topic]}"

  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "CRITICAL: Report missing at $EXPECTED_PATH"
    # Fallback: Create from agent output
    cat > "$EXPECTED_PATH" <<EOF
# ${topic}
## Findings
${AGENT_OUTPUT[$topic]}
EOF
  fi
done
```
```

**Critical Distinction** (lines 418-462):
- **Verification fallbacks**: REQUIRED (detect errors immediately, fail-fast with diagnostics)
- **Bootstrap fallbacks**: PROHIBITED (hide configuration errors through silent function definitions)
- **Optimization fallbacks**: ACCEPTABLE (performance caches only, graceful degradation for non-critical features)

**Standard 11: Imperative Agent Invocation Pattern** (lines 1173-1296):
- All Task invocations MUST use imperative instructions ("EXECUTE NOW", "USE the Task tool")
- NO code block wrappers around Task invocations (documentation-only YAML blocks are anti-pattern)
- Direct reference to agent behavioral files (.claude/agents/*.md)
- Explicit completion signals (e.g., REPORT_CREATED:)

**Standard 13: Project Directory Detection** (lines 1457-1532):
```bash
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```
- MUST be at top of command file (lines 56-60, coordinate.md)
- Provides git worktree support
- Used by all library paths: `source "${CLAUDE_PROJECT_DIR}/.claude/lib/..."`

**Standard 14: Executable/Documentation Separation** (lines 1535-1680):
- Executable files (<250 lines for commands, <400 for agents): Lean execution scripts with bash blocks, phase markers, minimal inline comments
- Guide files (unlimited length): Comprehensive documentation with architecture, examples, troubleshooting
- Templates: _template-executable-command.md (56 lines), _template-command-guide.md
- Benefits: 70% average reduction in executable file size, zero meta-confusion incidents

#### Dependency Management

**Module Dependency Graph** (lines 1364-1421, /home/benjamin/.config/.claude/lib/README.md):

**Layer 1 - Core Infrastructure** (no dependencies):
- timestamp-utils.sh
- deps-utils.sh
- detect-project-dir.sh

**Layer 2 - JSON & Validation**:
- json-utils.sh → deps-utils.sh
- validation-utils.sh (no dependencies)

**Layer 3 - Parsing & Structure**:
- parse-plan-core.sh (no dependencies)
- plan-structure-utils.sh (no dependencies)
- plan-metadata-utils.sh → parse-plan-core.sh, plan-structure-utils.sh

**Layer 4 - Error & Artifacts**:
- error-handling.sh → timestamp-utils.sh
- artifact-creation.sh → json-utils.sh, timestamp-utils.sh
- artifact-registry.sh → json-utils.sh, timestamp-utils.sh

**Layer 5 - Analysis**:
- analysis-pattern.sh (no dependencies)
- complexity-utils.sh → analysis-pattern.sh

**Layer 6 - Adaptive Planning**:
- checkpoint-utils.sh → json-utils.sh, timestamp-utils.sh
- complexity-utils.sh → analysis-pattern.sh

**Layer 7 - High-Level**:
- auto-analysis-utils.sh → complexity-utils.sh, artifact-creation.sh, artifact-registry.sh, error-handling.sh

**Sourcing Order Best Practice** (lines 1423-1434):
1. Infrastructure: timestamp-utils.sh, deps-utils.sh, detect-project-dir.sh
2. JSON & Validation: json-utils.sh, validation-utils.sh
3. Parsing: parse-plan-core.sh, plan-structure-utils.sh, plan-metadata-utils.sh
4. Error & Artifacts: error-handling.sh, artifact-creation.sh, artifact-registry.sh
5. Analysis: analysis-pattern.sh, complexity-utils.sh
6. Specialized: checkpoint-utils.sh, agents, conversion, templates
7. High-level: auto-analysis-utils.sh, progress-dashboard.sh

### Architectural Patterns

#### Pattern 1: State Machine Initialization (Two-Part Pattern)

**Coordinate implementation** (lines 17-150, /home/benjamin/.config/.claude/commands/coordinate.md):

**Part 1: Capture workflow description to file** (lines 23-38):
- Avoids positional parameter issues with bash block subprocess isolation
- Fixed filename: `${HOME}/.claude/tmp/coordinate_workflow_desc.txt`
- Prevents history expansion errors: `set +H` at top of bash block

**Part 2: Initialize state machine** (lines 46-150):
- Read workflow description from file (not from parameters which don't persist)
- Save critical values BEFORE sourcing libraries: `SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"` (line 84)
- Source state machine libraries: workflow-state-machine.sh, state-persistence.sh (lines 88-104)
- Initialize workflow state: `STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")` (line 110)
- Save workflow ID to fixed location: `${HOME}/.claude/tmp/coordinate_state_id.txt` (line 114)
- Initialize state machine: `sm_init "$SAVED_WORKFLOW_DESC" "coordinate"` (line 124)
- Source required libraries based on workflow scope (lines 132-150)

**Reusable across commands**: Template pattern documented in /home/benjamin/.config/.claude/docs/guides/state-machine-orchestrator-development.md (lines 54-100)

#### Pattern 2: Selective State Persistence

**Decision Matrix** (lines 47-68, /home/benjamin/.config/.claude/lib/state-persistence.sh):

**Use file-based persistence when**:
- State accumulates across subprocess boundaries (benchmark dataset across 10 invocations)
- Context reduction requires metadata aggregation (95% reduction via supervisor metadata)
- Success criteria validation needs objective evidence (POC metrics, timestamped phase breakdown)
- Resumability is valuable (multi-hour migrations)
- State is non-deterministic (user surveys, research findings)
- Recalculation is expensive (>30ms) or impossible (research findings not reproducible)
- Phase dependencies require prior phase outputs (Phase 3 depends on Phase 2 data)

**Use stateless recalculation when**:
- State is deterministic (file existence checks)
- Recalculation is fast (<1ms for track detection)
- Recalculation is 10x faster than file I/O (file verification cache)
- State is inherently single-block (guide completeness checklist in markdown)

**Implementation pattern**:
```bash
# Block 1: Initialize and save expensive computation
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"  # 50ms operation
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"

# Block 2+: Load cached value
load_workflow_state "$WORKFLOW_ID"
# CLAUDE_PROJECT_DIR now available (15ms read vs 50ms recalculation = 70% improvement)
```

#### Pattern 3: Verification Checkpoint with Fallback

**Implementation in coordinate** (line 103-133, command_architecture_standards.md):

**Structure**:
1. **Pre-calculate artifact paths** before agent invocation
2. **Invoke agents** with explicit file paths in prompts
3. **Mandatory verification** after agent completion
4. **Fallback creation** if agent failed to create file
5. **Continue workflow** only after verification success

**Error handling**:
- Detection over hiding: Fallback creates diagnostic content showing agent output
- User visibility: "CRITICAL: Report missing at $EXPECTED_PATH" message
- Audit trail: Fallback-created files include agent output for debugging
- Fail-fast continuation: Verification MUST succeed before next phase

**Reusable pattern** documented in Standard 0 (lines 51-463, command_architecture_standards.md)

#### Pattern 4: Conditional Library Loading

**Workflow scope determines library requirements** (lines 134-147, /home/benjamin/.config/.claude/commands/coordinate.md):

```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh"
                   "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")
    ;;
  research-and-plan)
    REQUIRED_LIBS=("... metadata-extraction.sh" "checkpoint-utils.sh" ...)
    ;;
  full-implementation)
    REQUIRED_LIBS=("... dependency-analyzer.sh" "context-pruning.sh" ...)
    ;;
esac

if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success
else
  exit 1
fi
```

**Benefits**:
- Reduces memory footprint for simpler workflows (research-only loads 6 vs 10 libraries)
- Faster initialization (40% fewer libraries to source for research-only)
- Clear scope-to-library mapping (dependency-analyzer.sh only for full-implementation)

#### Pattern 5: Library Re-Sourcing Between Blocks

**Bash block execution model requires explicit re-sourcing** (lines 1-68, bash-block-execution-model.md):

**Coordinate implementation** (lines 324-325, /home/benjamin/.config/.claude/commands/coordinate.md):
```bash
# Each subsequent bash block must re-source libraries
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
```

**Pattern**:
1. Block 1: Source libraries, initialize state, save to files
2. Block 2+: Re-source libraries (functions not persisted), load state from files
3. All blocks: Use fixed semantic filenames (not $$-based)

**Rationale**: Subprocess isolation means bash functions don't persist, but files do

## Recommendations

### 1. Apply State Machine Pattern to /orchestrate and /supervise

**Current Status**: /coordinate uses workflow-state-machine.sh (lines 88-124, coordinate.md), /orchestrate and /supervise use legacy phase-based tracking

**Action**: Migrate /orchestrate and /supervise to state machine pattern following state-machine-migration-guide.md

**Benefits**:
- 48.9% code reduction achieved in coordinate (3,420 → 1,748 lines across 3 orchestrators target)
- Explicit state transitions replace implicit phase numbers
- Validated transitions prevent invalid state changes
- Consistent API across all orchestration commands

**Implementation Guide**: /home/benjamin/.config/.claude/docs/guides/state-machine-migration-guide.md (1,000+ lines)

### 2. Apply Selective State Persistence to Commands with Expensive Recalculation

**Current Status**: coordinate uses state-persistence.sh for 67% performance improvement (50ms → 15ms for CLAUDE_PROJECT_DIR detection, line 20 state-persistence.sh)

**Action**: Audit /orchestrate, /supervise, /implement for expensive operations that benefit from file-based caching

**Decision Criteria** (lines 61-68, state-persistence.sh):
- Operation takes >30ms
- Operation result is deterministic but expensive (git operations, large file scans)
- Operation result is non-deterministic (research findings, user input)
- Operation accumulates across subprocess boundaries

**Implementation Pattern**:
```bash
# Block 1
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
EXPENSIVE_RESULT=$(expensive_operation)  # 50ms
append_workflow_state "EXPENSIVE_RESULT" "$EXPENSIVE_RESULT"

# Block 2+
load_workflow_state "$WORKFLOW_ID"  # 15ms read
# Use $EXPENSIVE_RESULT cached value
```

### 3. Apply Library Deduplication to All Orchestration Commands

**Current Status**: coordinate uses library-sourcing.sh with deduplication (lines 63-80, library-sourcing.sh), solving 120s+ timeout caused by duplicate library names

**Action**: Ensure /orchestrate, /supervise, /implement use `source_required_libraries()` with deduplication

**Verification**:
```bash
# Check if command uses library-sourcing.sh
grep -l "source_required_libraries" .claude/commands/*.md

# Validate no manual library sourcing that bypasses deduplication
grep -E "source.*\.sh$" .claude/commands/{orchestrate,supervise,implement}.md | grep -v library-sourcing
```

**Benefits**:
- Prevents duplicate sourcing (6 duplicates caused 120s timeout in coordinate)
- <0.01ms overhead for O(n²) deduplication with n≈10 libraries
- Consistent error handling across commands

### 4. Apply Verification Checkpoint Pattern to All Agent Invocations

**Current Status**: coordinate implements mandatory verification checkpoints (Standard 0, lines 103-133, command_architecture_standards.md)

**Action**: Audit all commands that invoke agents and add verification checkpoints with fallback file creation

**Pattern**:
```markdown
**MANDATORY VERIFICATION - Agent File Creation**

```bash
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Agent failed to create file at $EXPECTED_PATH"
  # Fallback: Create from agent output
  cat > "$EXPECTED_PATH" <<EOF
# Fallback content
${AGENT_OUTPUT}
EOF
fi
```

**REQUIREMENT**: This verification is NOT optional.
```

**Benefits**:
- 100% file creation reliability (agents that fail still produce diagnostic artifacts)
- Fail-fast error detection (missing files caught immediately)
- Audit trail (fallback-created files include agent output for debugging)

### 5. Apply Conditional Library Loading to Reduce Memory Footprint

**Current Status**: coordinate loads 6-10 libraries based on workflow scope (lines 134-147, coordinate.md)

**Action**: Implement conditional library loading in /orchestrate and /supervise based on workflow scope detection

**Pattern**:
```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=(minimal_set)  # 6 libraries
    ;;
  full-implementation)
    REQUIRED_LIBS=(full_set)     # 10 libraries
    ;;
esac

source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Benefits**:
- 40% fewer libraries for research-only workflows (6 vs 10)
- Faster initialization (less sourcing time)
- Lower memory footprint for simpler workflows

### 6. Document Library Usage Patterns in Command Guides

**Current Status**: coordinate-command-guide.md documents library dependencies (line 18, coordinate-command-guide.md), but pattern not standardized across all commands

**Action**: Add "Library Dependencies" section to all command guides following Standard 14 (executable/documentation separation)

**Template** (add to _template-command-guide.md):
```markdown
## Library Dependencies

### Core Libraries
- unified-location-detection.sh: Project root detection
- error-handling.sh: Fail-fast error handling
- checkpoint-utils.sh: State preservation

### Workflow Libraries
- workflow-state-machine.sh: State machine coordination
- dependency-analyzer.sh: Wave-based parallel execution

### Loading Pattern
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries "dependency-analyzer.sh"
```
```

**Benefits**:
- Clear library requirements for each command
- Easier debugging of missing library errors
- Standardized documentation pattern

## References

**Primary Sources**:
- /home/benjamin/.config/.claude/lib/README.md (lines 1-1637): Complete library catalog with dependencies and usage examples
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh (lines 1-100): State machine implementation with 8 core states
- /home/benjamin/.config/.claude/lib/state-persistence.sh (lines 1-150): Selective state persistence with GitHub Actions pattern
- /home/benjamin/.config/.claude/lib/library-sourcing.sh (lines 1-122): Unified library sourcing with deduplication
- /home/benjamin/.config/.claude/lib/error-handling.sh (lines 1-100): Error classification and retry logic

**Architecture Documentation**:
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md (lines 1-1680): Standards 0, 11, 13, 14 with examples
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md (lines 1-100): Subprocess isolation patterns and validated approaches

**Command Implementations**:
- /home/benjamin/.config/.claude/commands/coordinate.md (lines 17-325): Two-part initialization, conditional library loading
- /home/benjamin/.config/.claude/commands/orchestrate.md (lines 93-121): State machine usage in orchestrate command
- /home/benjamin/.config/.claude/commands/supervise.md (lines 68-85): State machine usage in supervise command

**Development Guides**:
- /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md (lines 1-100): Complete coordinate architecture and usage
- /home/benjamin/.config/.claude/docs/guides/state-machine-orchestrator-development.md (lines 1-100): Creating new state-based orchestrators
- /home/benjamin/.config/.claude/docs/guides/state-machine-migration-guide.md: Phase-based to state-based migration (referenced but not read in detail)
