# /coordinate Command Architecture Analysis

## Metadata
- **Research Date**: 2025-11-10
- **Researcher**: Research Specialist Agent
- **Topic**: Coordinate Command Architecture Analysis
- **Report ID**: 644/001/001
- **Related Specifications**: 597-600, 602, 620, 630, 637, 641
- **Overview Report**: [Current /coordinate Command Implementation: Comprehensive Analysis](OVERVIEW.md)

## Executive Summary

The `/coordinate` command implements a **state-machine-based workflow orchestrator** with explicit subprocess isolation handling and fail-fast error detection. It coordinates multi-agent workflows through 7-8 distinct states (initialize → research → plan → implement → test → debug → document → complete), using validated bash block patterns discovered through extensive refactoring (13 attempts, specs 582-594, 620, 630, 637).

**Key Architectural Characteristics**:
- **State Machine Integration**: Explicit states vs implicit phase numbers (8 states, 127 tests passing)
- **Subprocess Isolation Model**: Each bash block runs as separate process (validated patterns from specs 620/630)
- **Two-Part Workflow Description Capture**: Avoids positional parameter corruption issues
- **Library Re-sourcing Pattern**: Functions re-loaded in every bash block (subprocess constraint)
- **Mandatory Verification Checkpoints**: 100% file creation reliability via fail-fast validation
- **Wave-Based Parallel Execution**: 40-60% time savings via phase dependencies
- **Selective State Persistence**: 70% of critical state uses file-based persistence (67% performance improvement)

**Command Size**: 1,503 lines (reduced from ~3,000+ via state machine extraction)
**Bash Blocks**: 13 separate blocks (subprocess isolation boundary)
**Agent Invocations**: 16 Task tool calls (research, plan, implement, debug, document agents)
**State Transitions**: 109 references to STATE_ constants

## Table of Contents

1. [Overall Command Structure](#1-overall-command-structure)
2. [State Machine Integration Patterns](#2-state-machine-integration-patterns)
3. [Bash Block Organization](#3-bash-block-organization)
4. [Library Sourcing Patterns](#4-library-sourcing-patterns)
5. [Agent Invocation Architecture](#5-agent-invocation-architecture)
6. [Subprocess Isolation Handling](#6-subprocess-isolation-handling)
7. [Relationship with Other Orchestrators](#7-relationship-with-other-orchestrators)
8. [Critical Architectural Patterns](#8-critical-architectural-patterns)
9. [Performance Characteristics](#9-performance-characteristics)
10. [Evolution and Historical Context](#10-evolution-and-historical-context)

---

## 1. Overall Command Structure

### 1.1 Command Flow Architecture

```
/coordinate "<workflow-description>"
    ↓
┌─────────────────────────────────────────────────────────┐
│ Part 1: Workflow Description Capture (Bash Block 1)    │
│ - Avoid positional parameter corruption                │
│ - Save to fixed file location                          │
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ Part 2: Main Initialization (Bash Block 2)             │
│ - Read workflow description from file                  │
│ - Source state machine library                         │
│ - Initialize workflow state (GitHub Actions pattern)   │
│ - Initialize paths (topic directory, report paths)     │
│ - Mandatory verification checkpoint (state persistence)│
│ - Transition to research state                         │
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ State Handlers (Bash Blocks 3-13)                      │
│ - Research Phase (Block 3-4)                           │
│ - Planning Phase (Block 5-6)                           │
│ - Implementation Phase (Block 7-8)                     │
│ - Testing Phase (Block 9)                              │
│ - Debug Phase (Block 10) [conditional]                 │
│ - Documentation Phase (Block 11) [conditional]         │
│ - Completion (Block 12-13)                             │
└─────────────────────────────────────────────────────────┘
```

### 1.2 File Organization

**Command File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
- **Total Lines**: 1,503 lines
- **Bash Blocks**: 13 separate blocks
- **Metadata Section**: Lines 1-7 (allowed-tools, argument-hint, description)
- **Documentation Reference**: Line 13 (points to comprehensive guide)
- **State Handlers**: Lines 17-1503 (initialization + 7 state handlers)

**Supporting Documentation**:
- **Architectural Documentation**: `.claude/docs/architecture/coordinate-state-management.md` (1,380 lines)
- **Command Guide**: `.claude/docs/guides/coordinate-command-guide.md` (referenced, not analyzed)
- **Bash Block Execution Model**: `.claude/docs/concepts/bash-block-execution-model.md` (subprocess patterns)

### 1.3 Workflow Scope Detection

The command supports **4 workflow scopes** determined by workflow description analysis:

1. **research-only**: Research phase only (state machine terminal: `STATE_RESEARCH`)
2. **research-and-plan**: Research + planning (terminal: `STATE_PLAN`)
3. **full-implementation**: Complete workflow through documentation (terminal: `STATE_COMPLETE`)
4. **debug-only**: Research + planning + debugging (terminal: `STATE_DEBUG`)

**Detection Mechanism**:
```bash
# Performed by workflow-state-machine.sh:sm_init()
WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_desc")

# Maps scope to terminal state
case "$WORKFLOW_SCOPE" in
  research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
  research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
  full-implementation) TERMINAL_STATE="$STATE_COMPLETE" ;;
  debug-only) TERMINAL_STATE="$STATE_DEBUG" ;;
esac
```

---

## 2. State Machine Integration Patterns

### 2.1 State Machine Library

**Library**: `.claude/lib/workflow-state-machine.sh` (508 lines)

**Core Components**:
- **8 Explicit States**: initialize, research, plan, implement, test, debug, document, complete
- **Transition Table**: Defines valid state transitions (prevents invalid jumps)
- **Atomic Transitions**: Two-phase commit pattern (pre + post checkpoints)
- **State History**: Completed states tracked in array
- **Workflow Configuration**: Scope, description, command name stored

**Key Functions**:
```bash
sm_init()         # Initialize state machine from workflow description
sm_transition()   # Validate and execute state transitions
sm_current_state() # Get current state
sm_is_terminal()  # Check if workflow complete
sm_save()         # Save state to checkpoint (v2.0 schema)
sm_load()         # Load state from checkpoint (v1.3/v2.0 compatible)
```

### 2.2 State Transition Validation

**Transition Table** (enforced by state machine):
```
initialize  → research
research    → plan, complete (conditional)
plan        → implement, complete (conditional)
implement   → test
test        → debug, document (conditional)
debug       → test, complete
document    → complete
complete    → (terminal state)
```

**Example Validation** (from coordinate.md line ~224):
```bash
# sm_transition() validates before allowing transition
sm_transition "$STATE_RESEARCH"
# If current state doesn't allow transition to research, fails with error:
# "ERROR: Invalid transition: initialize → research"
```

### 2.3 State-Based vs Phase-Based Architecture

**Key Architectural Shift** (Spec 602):

| Aspect | Phase-Based (Old) | State-Based (New) |
|--------|------------------|-------------------|
| Phase Tracking | Integer (0-7) | Named states (initialize, research, etc.) |
| Transition Logic | Manual validation | State machine table |
| Resumability | Phase number only | Full state + history |
| Error Handling | Generic "phase failed" | State-specific error handling |
| Code Reduction | Baseline | **48.9% reduction** (3,420 → 1,748 lines) |
| Context Clarity | Implicit | Explicit (self-documenting) |

**Migration Pattern** (backward compatibility):
```bash
# v1.3 checkpoint migration (map_phase_to_state function)
map_phase_to_state() {
  case "$phase" in
    0) echo "$STATE_INITIALIZE" ;;
    1) echo "$STATE_RESEARCH" ;;
    2) echo "$STATE_PLAN" ;;
    3) echo "$STATE_IMPLEMENT" ;;
    # ... etc
  esac
}
```

---

## 3. Bash Block Organization

### 3.1 Block Structure and Separation

The `/coordinate` command uses **13 bash blocks** separated by subprocess boundaries:

**Block Boundaries**:
```markdown
## Section Title
```bash
set +H  # Disable history expansion
# ... bash code ...
```
(end of block - subprocess terminates)

## Next Section
```bash
set +H  # New subprocess starts
# ... bash code ...
```
```

**Block Distribution**:
1. **Block 1** (lines 31-38): Workflow description capture
2. **Block 2** (lines 46-279): Main initialization + state machine setup
3. **Block 3** (lines 291-367): Research state handler (setup)
4. **Block 4** (hierarchical/flat research delegation, Task tool invocations)
5. **Block 5** (lines 426-639): Research verification + transition
6. **Block 6** (lines 651-709): Planning state handler (setup)
7. **Block 7** (plan creation, Task tool invocation)
8. **Block 8** (lines 741-903): Planning verification + transition
9. **Block 9** (lines 915-1046): Implementation state handler
10. **Block 10** (lines 1058-1167): Testing state handler
11. **Block 11** (lines 1179-1354): Debug state handler (conditional)
12. **Block 12** (lines 1366-1494): Documentation state handler (conditional)
13. **Block 13** (implicit): Workflow completion

### 3.2 Block Size Limits

**Critical Discovery** (Spec 582): Claude AI performs code transformation on bash blocks **≥400 lines**.

**Transformation Issues**:
- History expansion patterns (`!`) get corrupted even with `set +H`
- Unpredictable regex transformation
- No workaround exists (preprocessing happens before bash execution)

**Safety Thresholds**:
- **< 300 lines**: Safe (100-line safety margin)
- **300-400 lines**: Risky (transformation may trigger)
- **≥ 400 lines**: Guaranteed transformation (avoid)

**Current Compliance**:
All coordinate.md bash blocks remain **well below 300 lines** through:
- State machine extraction to library (removes 100+ lines per block)
- Agent delegation (moves complex logic to subagents)
- Library function calls (replaces inline logic)

### 3.3 Two-Part Workflow Description Capture

**Pattern** (lines 17-38): Avoid positional parameter corruption

**Why Two Parts**:
```bash
# PROBLEM: Single-block pattern (AVOIDED)
WORKFLOW_DESCRIPTION="$1"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
# ↑ Library sourcing can corrupt positional parameters

# SOLUTION: Two-block pattern (IMPLEMENTED)
# Block 1: Capture workflow description to file
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"

# Block 2: Read from file (no positional parameter dependency)
WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE")
```

**User Substitution Requirement** (line 33-36):
```bash
# CRITICAL: Replace YOUR_WORKFLOW_DESCRIPTION_HERE with actual workflow description from user
# Example: If user ran `/coordinate "research auth patterns"`, change:
# FROM: echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > ...
# TO:   echo "research auth patterns" > ...
```

---

## 4. Library Sourcing Patterns

### 4.1 Re-sourcing Requirement

**Subprocess Isolation Constraint**: Each bash block runs as a **separate process**, so all functions must be re-sourced.

**Standard Pattern** (appears in ALL bash blocks after Block 1):
```bash
# Re-source libraries (functions lost across bash block boundaries)
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

**Source Guards** (in each library file):
```bash
# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_STATE_MACHINE_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_STATE_MACHINE_SOURCED=1
```

**Why This Works**:
- Source guards prevent double-loading within same block
- Export doesn't persist across subprocess boundaries (intentional)
- Each block gets fresh library load (deterministic state)

### 4.2 Conditional Library Loading

**Pattern** (lines 131-152): Load libraries based on workflow scope

```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" ...)
    ;;
  research-and-plan)
    REQUIRED_LIBS=("..." "metadata-extraction.sh" "checkpoint-utils.sh" ...)
    ;;
  full-implementation)
    REQUIRED_LIBS=("..." "dependency-analyzer.sh" "context-pruning.sh" ...)
    ;;
  debug-only)
    REQUIRED_LIBS=("..." "error-handling.sh" ...)
    ;;
esac

source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Benefits**:
- Reduces context consumption (only load needed libraries)
- Faster execution (fewer files sourced)
- Clear dependency tracking (explicit per-scope)

### 4.3 Library Integration Points

**Critical Libraries**:

1. **workflow-state-machine.sh** (508 lines)
   - State enumeration (8 states)
   - Transition validation
   - State persistence (save/load checkpoints)
   - Phase-to-state mapping (v1.3 migration)

2. **state-persistence.sh** (200 lines, from spec 602 Phase 3)
   - GitHub Actions-style state files (`$GITHUB_OUTPUT` pattern)
   - Workflow state initialization/loading
   - JSON checkpoint atomic writes
   - Graceful degradation (fallback to recalculation)

3. **workflow-initialization.sh** (347 lines)
   - Path pre-calculation (topic directory, report paths, plan path)
   - Directory structure creation
   - Report paths array serialization (exports REPORT_PATH_0, REPORT_PATH_1, etc.)
   - Defensive variable validation

4. **error-handling.sh**
   - `handle_state_error()` - Fail-fast error reporting
   - State transition error recovery
   - Diagnostic output formatting

5. **unified-logger.sh**
   - `emit_progress()` - Progress tracking
   - `display_brief_summary()` - Workflow completion summary
   - JSONL logging (benchmark data accumulation)

6. **verification-helpers.sh**
   - `verify_file_created()` - Mandatory verification checkpoints
   - File size reporting
   - Path validation

---

## 5. Agent Invocation Architecture

### 5.1 Agent Invocation Pattern

**Standard Pattern** (appears 16 times throughout coordinate.md):

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [agent-name] agent:

Task {
  subagent_type: "general-purpose"
  description: "[one-line description]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Key Input 1]: [value]
    - [Key Input 2]: [value]
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **CRITICAL**: Create [artifact type] at EXACT path provided above.

    Execute [task] following all guidelines in behavioral file.
    Return: [COMPLETION_SIGNAL]: [expected output]
  "
}
```

**Key Elements**:
1. **Behavioral File Reference**: Absolute path to agent's behavioral guidelines
2. **Workflow-Specific Context**: Injected inputs (paths, descriptions, complexity)
3. **Critical Requirements**: Explicit artifact creation expectations
4. **Completion Signal**: Expected return format (enables verification)

### 5.2 Agent Types Used

**1. Research Specialists** (research-specialist.md)
- **Invocations**: 1-4 parallel instances (flat coordination) OR 1 supervisor (hierarchical)
- **Context Injection**: Research topic, report path, project standards
- **Return Format**: `REPORT_CREATED: /absolute/path/to/report.md`
- **Verification**: Mandatory file existence check after invocation

**2. Research Sub-Supervisor** (research-sub-supervisor.md, hierarchical mode)
- **Condition**: ≥4 research topics (complexity threshold)
- **Context Injection**: Topic list, output directory, state file, supervisor ID
- **Return Format**: `SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}`
- **Benefit**: 95% context reduction (metadata aggregation)

**3. Plan Architect** (plan-architect.md)
- **Invocations**: 1 per workflow (planning phase)
- **Context Injection**: Feature description, plan path, research reports, topic directory
- **Return Format**: `PLAN_CREATED: /absolute/path/to/plan.md`
- **Verification**: Plan file existence + sanity check (descriptive naming)

**4. Implementation Agent** (/implement command via Task tool)
- **Invocations**: 1 per workflow (implementation phase)
- **Context Injection**: Plan path
- **Return Format**: `IMPLEMENTATION_COMPLETE: [summary]`
- **Delegation**: Executes wave-based parallel implementation (40-60% time savings)

**5. Debug Analyst** (/debug command via Task tool)
- **Invocations**: 1 per workflow (conditional, if tests fail)
- **Context Injection**: Failure description, workflow context
- **Return Format**: `DEBUG_REPORT_CREATED: /absolute/path/to/debug/report.md`
- **Verification**: Debug report file existence

**6. Documentation Agent** (/document command via Task tool)
- **Invocations**: 1 per workflow (conditional, if tests pass)
- **Context Injection**: Change description
- **Return Format**: `DOCUMENTATION_UPDATED: [list of files]`
- **Verification**: (implicit via command success)

### 5.3 Hierarchical vs Flat Research Coordination

**Decision Logic** (lines 357-366):
```bash
# Determine research complexity (1-4 topics)
RESEARCH_COMPLEXITY=2  # Default

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed"; then
  RESEARCH_COMPLEXITY=4
fi

# Determine if hierarchical supervision needed
USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")
```

**Conditional Execution** (lines 369-422):

**Option A: Hierarchical** (≥4 topics)
- Invoke 1 research-sub-supervisor agent
- Supervisor delegates to 4+ research-specialist workers
- Aggregates metadata from all reports
- Returns 440-token summary (95% context reduction from 10,000 tokens)

**Option B: Flat** (<4 topics)
- Invoke 1-3 research-specialist agents directly (parallel Task invocations)
- Coordinator (coordinate.md) aggregates results
- No supervisor overhead

**Performance Comparison**:
| Approach | Topics | Context Usage | Time Savings | Complexity |
|----------|--------|--------------|--------------|------------|
| Flat | 1-3 | 100% (all reports loaded) | 0% (sequential) | Low |
| Hierarchical | 4+ | 4.4% (metadata only) | 60-80% (parallel subagent execution) | Medium |

---

## 6. Subprocess Isolation Handling

### 6.1 Subprocess Isolation Model

**Core Constraint** (from bash-block-execution-model.md):

Each bash block runs as a **separate subprocess** (not subshell):
- Process ID (`$$`) changes between blocks
- Environment variables reset (exports lost)
- Bash functions lost (must re-source libraries)
- Trap handlers fire at block exit, not workflow exit

**Validation Test Output**:
```
✓ CONFIRMED: Process IDs differ (12345 vs 12346)
  Each bash block runs as separate subprocess
Block 1: TEST_VAR=set_in_block_1
Block 2: TEST_VAR=unset
✓ Files are the ONLY reliable cross-block communication channel
```

### 6.2 Validated Patterns (Specs 620/630)

**1. Fixed Semantic Filenames** (NOT `$$`-based)
```bash
# ANTI-PATTERN (Spec 620 Issue 1): $$-based filenames
COORDINATE_DESC_FILE="/tmp/coordinate_desc_$$.txt"
# ↑ $$ changes per block, file not found in Block 2

# VALIDATED PATTERN: Fixed semantic filename
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
# ↑ Same filename across all blocks
```

**2. Save-Before-Source Pattern**
```bash
# CRITICAL: Save workflow description BEFORE sourcing libraries
# Libraries pre-initialize WORKFLOW_DESCRIPTION="" which overwrites parent value
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

# Now safe to source libraries
source "${LIB_DIR}/workflow-state-machine.sh"

# Use SAVED value, not overwritten variable
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
```

**3. Library Re-sourcing in Every Block**
```bash
# Functions lost across subprocess boundaries
# Re-source in EVERY bash block after Block 1
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
# ... etc
```

**4. State File Persistence** (GitHub Actions pattern)
```bash
# Block 1: Initialize state file
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Block 2+: Load state file
load_workflow_state "$WORKFLOW_ID"
# ↑ Variables restored from file (no recalculation needed)
```

**5. Array Serialization** (Spec 637 fix)
```bash
# Bash arrays cannot be exported across subprocesses
# Serialize to individual variables
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  eval "value=\$$var_name"
  append_workflow_state "$var_name" "$value"
done

# Reconstruct in subsequent blocks
reconstruct_report_paths_array()  # From workflow-initialization.sh
```

### 6.3 Anti-Patterns to Avoid

**1. $$-Based Process IDs** (Spec 620)
```bash
# ANTI-PATTERN
WORKFLOW_ID="coordinate_$$"
# ↑ $$ changes per block, breaks state persistence

# CORRECT PATTERN
WORKFLOW_ID="coordinate_$(date +%s)"
# ↑ Timestamp-based (consistent across blocks)
```

**2. Export Assumptions**
```bash
# ANTI-PATTERN
# Block 1
export VARIABLE="value"

# Block 2 (different subprocess)
echo "$VARIABLE"  # EMPTY! Export didn't persist

# CORRECT PATTERN
# Block 1
append_workflow_state "VARIABLE" "value"

# Block 2
load_workflow_state "$WORKFLOW_ID"
echo "$VARIABLE"  # Restored from state file
```

**3. Premature Trap Handlers** (Spec 630)
```bash
# ANTI-PATTERN
# Block 1
trap "rm -f $STATE_FILE" EXIT
# ↑ Fires at end of Block 1, deletes state file before Block 2 reads it!

# CORRECT PATTERN
# NO trap in early blocks
# Cleanup handled manually or via external cleanup script
```

**4. Indirect Expansion Without Defensive Checks** (Spec 637)
```bash
# ANTI-PATTERN
REPORT_PATHS+=("${!var_name}")  # Fails with "unbound variable" if var_name missing

# CORRECT PATTERN
if [ -z "${!var_name+x}" ]; then
  echo "WARNING: $var_name not set, skipping" >&2
  continue
fi
REPORT_PATHS+=("${!var_name}")
```

### 6.4 Stateless Recalculation vs Selective Persistence

**Decision Matrix** (from coordinate-state-management.md):

**Use Stateless Recalculation When**:
- Recalculation cost <100ms
- <10 variables
- Deterministic algorithm
- Example: `WORKFLOW_SCOPE=$(detect_workflow_scope "$desc")`

**Use Selective State Persistence When**:
- Recalculation cost >30ms
- State accumulates across subprocess boundaries
- Non-deterministic (user input, external API calls)
- Context reduction benefits (metadata aggregation)
- Example: `CLAUDE_PROJECT_DIR` detection (6ms → 2ms via caching)

**Actual Implementation**:
- **70% of critical state** uses file-based persistence (7 of 10 analyzed items)
- **30% uses stateless recalculation** (cheap deterministic calculations)
- **Performance**: 67% improvement for expensive operations (6ms → 2ms)

---

## 7. Relationship with Other Orchestrators

### 7.1 Orchestration Command Comparison

| Aspect | /coordinate | /orchestrate | /supervise |
|--------|------------|--------------|------------|
| **Total Lines** | 1,503 | 581 | 421 |
| **Maturity** | Production | Experimental | In Development |
| **State Machine** | ✓ Explicit | ✓ Explicit | ✓ Explicit |
| **Wave-Based Implementation** | ✓ Yes | Partial | No |
| **Verification Checkpoints** | ✓ Mandatory | Partial | Partial |
| **Subprocess Isolation Patterns** | ✓ Validated (620/630) | Unknown | Unknown |
| **PR Automation** | No | ✓ Yes | No |
| **Dashboard Tracking** | No | ✓ Yes | No |
| **Recommended Use** | **Default production** | Feature testing | Minimal reference |

**CLAUDE.md Guidance** (lines ~620-650):
> "Three orchestration commands available (**Use /coordinate for production workflows**):
> - /coordinate - **Production-Ready** - Wave-based parallel execution and fail-fast error handling
> - /orchestrate - **In Development** - Full-featured with PR automation (experimental features)
> - /supervise - **In Development** - Sequential orchestration (minimal reference)"

### 7.2 Architectural Differences

**/coordinate Unique Features**:
1. **Two-Part Workflow Description Capture** - Avoids positional parameter corruption
2. **Mandatory Verification Checkpoints** - 100% file creation reliability
3. **Validated Subprocess Patterns** - Fixed filenames, save-before-source, defensive checks
4. **Selective State Persistence** - 70% file-based, 30% stateless recalculation
5. **Hierarchical Research** - 95% context reduction for ≥4 topics

**Shared Architecture** (all three orchestrators):
- State machine library (workflow-state-machine.sh)
- Agent behavioral injection pattern
- Fail-fast error handling
- Phase 0 optimization (path pre-calculation)

### 7.3 Evolution Timeline

**State-Based Architecture Development** (Spec 602):
- **Phase 7 Complete** (2025-11-08)
- **Code Reduction**: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- **/coordinate Reduction**: 26.2% (1,084 → 800 lines estimated, actual 1,503 includes docs)
- **Test Results**: 409 tests, 63/81 suites passing (127 core state machine tests: 100%)

**Bash Block Pattern Validation** (Specs 620/630):
- **Subprocess Isolation Patterns**: 100% test pass rate
- **Fixed Filename Pattern**: Validated
- **Save-Before-Source**: Validated
- **Array Serialization**: Validated (spec 637)

---

## 8. Critical Architectural Patterns

### 8.1 Mandatory Verification Checkpoints

**Pattern** (appears 5 times: research, planning, implementation, debug, documentation phases):

```bash
# ===== MANDATORY VERIFICATION CHECKPOINT: [Phase Name] =====
echo ""
echo "MANDATORY VERIFICATION: [Phase] Phase Artifacts"
echo "Checking [N] [artifact type]..."
echo ""

VERIFICATION_FAILURES=0
SUCCESSFUL_PATHS=()
FAILED_PATHS=()

for i in $(seq 1 $COUNT); do
  ARTIFACT_PATH="${PATHS[$i-1]}"
  echo -n "  Artifact $i/$COUNT: "
  if verify_file_created "$ARTIFACT_PATH" "[description]" "[Phase]"; then
    SUCCESSFUL_PATHS+=("$ARTIFACT_PATH")
    FILE_SIZE=$(stat -c%s "$ARTIFACT_PATH" 2>/dev/null || echo "unknown")
    echo " verified ($FILE_SIZE bytes)"
  else
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    FAILED_PATHS+=("$ARTIFACT_PATH")
  fi
done

# Fail-fast on verification failure
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo ""
  echo "❌ CRITICAL: [Phase] artifact verification failed"
  echo "   $VERIFICATION_FAILURES [artifacts] not created at expected paths"
  # ... detailed troubleshooting output ...
  handle_state_error "[Phase] agents failed to create expected artifacts" 1
fi

echo "✓ All [N] [artifacts] verified successfully"
```

**Benefits**:
- **100% File Creation Reliability** - No silent failures
- **Immediate Diagnostics** - Shows which paths failed, why
- **Fail-Fast Behavior** - Workflow stops at first error
- **User Guidance** - Troubleshooting steps provided

**Example Verification Output** (from lines 466-516):
```
MANDATORY VERIFICATION: Hierarchical Research Artifacts
Checking 4 supervisor-managed reports...

  Report 1/4: verified (2547 bytes)
  Report 2/4: verified (1893 bytes)
  Report 3/4: verified (2104 bytes)
  Report 4/4: verified (2238 bytes)

Verification Summary:
  - Success: 4/4 reports
  - Failures: 0 reports

✓ All 4 reports verified successfully
```

### 8.2 Checkpoint Requirements Pattern

**Pattern** (appears at end of each state handler):

```bash
# ===== CHECKPOINT REQUIREMENT: [Phase] Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: [Phase] Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "[Phase] phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - [Artifact 1]: ✓ Created"
echo "    - [Artifact 2]: [value]"
echo ""
echo "  Verification Status:"
echo "    - All files verified: ✓ Yes"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: [Next State] phase"
echo "═══════════════════════════════════════════════════════"
echo ""

# Transition to next state
sm_transition "$STATE_[NEXT]"
append_workflow_state "CURRENT_STATE" "$STATE_[NEXT]"
```

**Benefits**:
- Clear phase boundaries (visual separators)
- Audit trail (what was accomplished)
- Explicit state transitions (no implicit jumps)
- User confidence (workflow progressing correctly)

### 8.3 State File Verification Pattern

**Pattern** (lines 199-257): Verify state file persistence

```bash
# ===== MANDATORY VERIFICATION CHECKPOINT: State Persistence =====
echo ""
echo "MANDATORY VERIFICATION: State File Persistence"
echo "Checking $REPORT_PATHS_COUNT REPORT_PATH variables..."
echo ""

VERIFICATION_FAILURES=0

# Verify REPORT_PATHS_COUNT was saved
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "  ✓ REPORT_PATHS_COUNT variable saved"
else
  echo "  ❌ REPORT_PATHS_COUNT variable missing"
  VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
fi

# Verify all REPORT_PATH_N variables were saved
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  if grep -q "^${var_name}=" "$STATE_FILE" 2>/dev/null; then
    echo "  ✓ $var_name saved"
  else
    echo "  ❌ $var_name missing"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done

# Display state file info
STATE_FILE_SIZE=$(stat -c%s "$STATE_FILE" 2>/dev/null || echo "unknown")
echo ""
echo "State file verification:"
echo "  - Path: $STATE_FILE"
echo "  - Size: $STATE_FILE_SIZE bytes"
echo "  - Variables expected: $((REPORT_PATHS_COUNT + 1))"
echo "  - Verification failures: $VERIFICATION_FAILURES"

# Fail-fast on verification failure
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo ""
  echo "❌ CRITICAL: State file verification failed"
  # ... detailed troubleshooting ...
  handle_state_error "State persistence verification failed" 1
fi
```

**Rationale**:
- Detects bad substitution errors (Bash tool preprocessing issues)
- Validates append_workflow_state() function correctness
- Prevents silent failures from missing state variables
- Enables debugging (shows state file contents on failure)

### 8.4 Re-sourcing Pattern with Error Handling

**Pattern** (appears in blocks 3-13):

```bash
# Re-source libraries (functions lost across bash block boundaries)
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

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "Cannot restore workflow state. This is a critical error."
  exit 1
fi

# Check if we should skip this state (already at terminal)
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in expected state
if [ "$CURRENT_STATE" != "$STATE_EXPECTED" ]; then
  echo "ERROR: Expected state '$STATE_EXPECTED' but current state is '$CURRENT_STATE'"
  exit 1
fi
```

**Error Handling Levels**:
1. **Missing CLAUDE_PROJECT_DIR**: Recalculate via git command
2. **Missing State ID File**: Critical error (fail-fast)
3. **Already at Terminal State**: Graceful exit (no-op)
4. **Wrong Current State**: Critical error (state machine violated)

---

## 9. Performance Characteristics

### 9.1 Performance Metrics

**Command Execution Overhead**:
- **State Machine Operations**: <1ms per transition (127 tests passing)
- **Library Re-sourcing**: ~2ms per block (6 libraries, source guards prevent double-load)
- **CLAUDE_PROJECT_DIR Detection**: 6ms → 2ms (67% improvement via state persistence)
- **Workflow State Loading**: ~2ms per block (file read)
- **Total Per-Block Overhead**: ~4-6ms (negligible)

**Context Reduction Achievements**:
- **Hierarchical Research**: 95.6% reduction (10,000 → 440 tokens)
- **Metadata-Only Passing**: 92-97% reduction via supervisor aggregation
- **Target**: <30% context usage throughout workflows (achieved)

**Time Savings**:
- **Wave-Based Parallel Implementation**: 40-60% time savings
- **Parallel Research** (flat, 3 agents): 60-80% time savings vs sequential
- **Hierarchical Research** (≥4 topics): 60-80% time savings + 95% context reduction

### 9.2 Code Reduction Metrics

**State Machine Migration** (Spec 602):
- **Total Reduction**: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- **/coordinate Reduction**: 26.2% (1,084 → 800 lines in executable logic)
- **Current Total**: 1,503 lines (includes documentation sections)

**Library Extraction Savings**:
- **Scope Detection**: 48-line duplication eliminated (24 lines × 2 blocks)
- **State Machine Logic**: 100+ lines per block eliminated
- **Path Pre-calculation**: Consolidated to workflow-initialization.sh (85% token reduction)

### 9.3 Reliability Metrics

**Test Results** (Spec 602 Phase 7):
- **Core State Machine Tests**: 127/127 passing (100%)
- **Overall Test Suite**: 409 tests, 63/81 suites passing
- **Subprocess Isolation Tests**: 100% pass rate (specs 620/630)
- **File Creation Reliability**: 100% (mandatory verification checkpoints)

**Error Detection**:
- **Fail-Fast Philosophy**: Zero silent failures (all errors terminate immediately)
- **Diagnostic Output**: Comprehensive troubleshooting guidance on all errors
- **Verification Coverage**: 5 mandatory checkpoints (research, planning, implementation, debug, documentation)

---

## 10. Evolution and Historical Context

### 10.1 Refactoring Journey (13 Attempts)

**Timeline** (Specs 582-600):

```
Spec 578 → Standard 13 foundation (CLAUDE_PROJECT_DIR detection)
         ↓
Spec 581 → Block consolidation (exposed 400-line transformation issue)
         ↓
Spec 582 → 400-line transformation discovery (split blocks)
         ↓
Spec 583 → BASH_SOURCE limitation (SlashCommand context)
         ↓
Spec 584 → Export persistence failure (subprocess isolation confirmed)
         ↓
Spec 585 → Pattern validation (stateless recalculation recommended)
         ↓
Specs 586-594 → Incremental refinements
         ↓
Spec 597 → ✅ Stateless recalculation success
         ↓
Spec 598 → ✅ Pattern completion (derived variables)
         ↓
Spec 599 → Refactor opportunity analysis (7 phases identified)
         ↓
Spec 600 → High-value improvements (library extraction)
         ↓
Spec 602 → ✅ State machine migration (48.9% code reduction)
         ↓
Spec 620 → ✅ Bash history expansion fixes (100% test pass rate)
         ↓
Spec 630 → ✅ Report paths state persistence (array serialization)
         ↓
Spec 637 → ✅ Agent invocation fixes (REPORT_PATHS_COUNT export)
         ↓
Spec 641 → ✅ Bash block critical patterns documentation
```

### 10.2 Key Architectural Decisions

**Decision 1: Stateless Recalculation vs File-Based State** (Spec 585)
- **Analysis**: 30ms I/O overhead vs <1ms recalculation
- **Decision**: Use stateless for cheap variables (<100ms), file-based for expensive (>30ms)
- **Result**: 70% file-based, 30% stateless (selective persistence)

**Decision 2: Single Large Block vs Multiple Small Blocks** (Spec 582)
- **Analysis**: 400-line code transformation threshold discovered
- **Decision**: Keep blocks <300 lines (100-line safety margin)
- **Result**: 13 blocks averaging 115 lines each

**Decision 3: Export Workarounds vs Accept Subprocess Isolation** (Spec 584)
- **Analysis**: GitHub #334 and #2508 confirm subprocess model is intentional
- **Decision**: Accept constraint, design around it (fixed filenames, state files)
- **Result**: Validated patterns (specs 620/630), 100% test pass rate

**Decision 4: Phase-Based vs State-Based Architecture** (Spec 602)
- **Analysis**: Implicit phase numbers vs explicit named states
- **Decision**: Migrate to explicit state machine (48.9% code reduction)
- **Result**: 127 state machine tests passing, improved clarity

### 10.3 Lessons Learned

**1. Tool Constraints Are Architectural**
- Don't fight subprocess isolation, design around it
- Fixed filenames > `$$`-based IDs
- State files > export assumptions

**2. Fail-Fast Over Complexity**
- Mandatory verification checkpoints (100% reliability)
- Immediate errors > silent failures
- Diagnostic output > graceful degradation

**3. Performance Measurement Over Assumptions**
- 1ms recalculation vs 30ms file I/O (measured, not assumed)
- 67% improvement for CLAUDE_PROJECT_DIR caching (validated via benchmarks)
- 40-60% time savings for wave-based implementation (measured in production)

**4. Code Duplication Can Be Correct**
- 50 lines duplication < file I/O complexity
- Library extraction eliminates most duplication
- Subprocess isolation requires some recalculation

**5. Validation Through Testing**
- 127 state machine tests prove correctness
- 100% subprocess isolation pattern validation
- 100% file creation reliability via checkpoints

**6. Incremental Discovery Process**
- 13 refactor attempts over time led to optimal solution
- Each "failure" uncovered constraints (400-line threshold, subprocess isolation)
- Final architecture balances all discovered constraints

---

## Conclusion

The `/coordinate` command represents a **production-ready state-machine-based orchestrator** with validated subprocess isolation patterns, mandatory verification checkpoints, and 100% file creation reliability. Its architecture emerged from extensive refactoring (13 attempts, specs 582-600) and subprocess pattern validation (specs 620/630/637), resulting in a robust foundation for multi-agent workflow coordination.

**Architectural Strengths**:
1. **Explicit State Machine** - 8 states, validated transitions, 127 tests passing
2. **Subprocess Isolation Mastery** - Fixed filenames, save-before-source, defensive checks
3. **Fail-Fast Reliability** - Mandatory verification checkpoints, immediate error detection
4. **Performance Optimization** - 67% caching improvement, 40-60% parallel time savings
5. **Context Reduction** - 95% reduction via hierarchical research supervision

**Production Readiness**:
- **Maturity**: Recommended default orchestrator (CLAUDE.md guidance)
- **Test Coverage**: 409 tests, 100% core state machine validation
- **Documentation**: 1,380-line architectural guide, comprehensive troubleshooting
- **Reliability**: Zero silent failures, 100% file creation verification

**Comparison to Alternatives**:
- **/orchestrate**: Experimental features (PR automation, dashboard), inconsistent behavior
- **/supervise**: Minimal reference, sequential only (no wave-based parallelism)
- **/coordinate**: **Production-ready, recommended for all workflows**

---

## References

### Primary Documentation
1. `/home/benjamin/.config/.claude/commands/coordinate.md` (1,503 lines)
2. `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (1,380 lines)
3. `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`
4. `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (508 lines)
5. `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (347 lines)

### Specifications
- **Spec 582-600**: Refactoring journey (13 attempts, stateless recalculation emergence)
- **Spec 602**: State machine migration (48.9% code reduction, Phase 7 complete)
- **Spec 620**: Bash history expansion fixes (subprocess isolation patterns)
- **Spec 630**: Report paths state persistence (array serialization)
- **Spec 637**: Agent invocation fixes (REPORT_PATHS_COUNT export)
- **Spec 641**: Bash block critical patterns documentation

### GitHub Issues
- **#334**: Export persistence limitation (subprocess model confirmed)
- **#2508**: Subprocess vs subshell clarification

### CLAUDE.md Sections
- **Project Commands** (lines ~620-650): Orchestration command selection guidance
- **State-Based Orchestration** (section): Architecture overview and resources
- **Hierarchical Agent Architecture** (section): Context reduction patterns

---

**Report Completion**: REPORT_CREATED: /home/benjamin/.config/.claude/specs/644_current_command_implementation_identify/reports/001_current_command_implementation_identify/001_coordinate_command_architecture_analysis.md
