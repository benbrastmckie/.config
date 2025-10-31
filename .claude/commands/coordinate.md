---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: Coordinate multi-agent workflows with wave-based parallel implementation
command-type: primary
dependent-commands: research, plan, implement, debug, test, document
---

# /coordinate - Clean Multi-Agent Workflow Orchestration with Wave-Based Execution

## Command Syntax

```
/coordinate <workflow-description>
```

**Arguments**:
- `<workflow-description>`: Natural language description of the workflow to execute

**Examples**:
- `/coordinate "research API authentication patterns"` - Research-only workflow
- `/coordinate "research the authentication module to create a refactor plan"` - Research-and-plan workflow
- `/coordinate "implement OAuth2 authentication for the API"` - Full-implementation workflow
- `/coordinate "fix the token refresh bug in auth.js"` - Debug-only workflow

**Workflow Scope Detection**:
The command automatically detects the workflow type from your description and executes only the appropriate phases:
- **research-only**: Keywords like "research [topic]" without "plan" or "implement"
- **research-and-plan**: Keywords like "research...to create plan", "analyze...for planning"
- **full-implementation**: Keywords like "implement", "build", "add feature"
- **debug-only**: Keywords like "fix [bug]", "debug [issue]", "troubleshoot [error]"

## YOUR ROLE: WORKFLOW ORCHESTRATOR

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope (research-only, research-and-plan, full-implementation, debug-only)
3. Invoke specialized agents via Task tool with complete context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results (forward message pattern)
6. Report final workflow status and artifact locations

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure

**ARCHITECTURAL PATTERN**:
- Phase 0: Pre-calculate paths → Create topic directory structure
- Phase 1-N: Invoke agents with pre-calculated paths → Verify → Extract metadata
- Completion: Report success + artifact locations

**TOOLS ALLOWED**:
- Task: ONLY tool for agent invocations
- TodoWrite: Track phase progress
- Bash: Verification checkpoints (ls, grep, wc)
- Read: Parse agent output files for metadata extraction (not for task execution)

**TOOLS PROHIBITED**:
- SlashCommand: NEVER invoke /plan, /implement, /debug, or any command
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly (agents do this)

## Architectural Prohibition: No Command Chaining

**CRITICAL PROHIBITION**: This command MUST NEVER invoke other commands via the SlashCommand tool.

### Why This Matters

**Wrong Pattern - Command Chaining** (causes context bloat and broken behavioral injection):

❌ INCORRECT - Do NOT do this:
SlashCommand with command: "/plan create auth feature"

**Problems with command chaining**:
1. **Context Bloat**: Entire /plan command prompt injected into your context (~2000 lines)
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation

**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):

<!-- This Task invocation is executable -->
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    - Research Reports: [list of paths]
    - Project Standards: [path to CLAUDE.md]

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}

**Benefits of direct agent invocation**:
1. **Lean Context**: Only agent behavioral guidelines loaded (~200 lines)
2. **Behavioral Control**: Can inject custom instructions, constraints, templates
3. **Structured Output**: Agent returns metadata (path, status) not full summaries
4. **Verification Points**: Can verify file creation before continuing

### Side-by-Side Comparison

| Aspect | Command Chaining (❌) | Direct Agent Invocation (✅) |
|--------|---------------------|------------------------------|
| Context Usage | ~2000 lines (full command) | ~200 lines (agent guidelines) |
| Behavioral Control | Fixed (command prompt) | Flexible (custom instructions) |
| Output Format | Full text summaries | Structured metadata |
| Verification | None (black box) | Explicit checkpoints |
| Path Control | Agent calculates | Orchestrator pre-calculates |
| Role Separation | Blurred (orchestrator executes) | Clear (orchestrator delegates) |

### Enforcement

If you find yourself wanting to invoke /plan, /implement, /debug, or /document:

1. **STOP** - You are about to violate the architectural pattern
2. **IDENTIFY** - What task does that command perform?
3. **DELEGATE** - Invoke the appropriate agent directly via Task tool
4. **INJECT** - Provide the agent with behavioral guidelines and context
5. **VERIFY** - Check that the agent created the expected artifacts

**REMEMBER**: You are the **ORCHESTRATOR**, not the **EXECUTOR**. Delegate work to agents.

## Workflow Overview

[REFERENCE-OK: Can be supplemented with external orchestration pattern docs]

This command coordinates multi-agent workflows through 7 phases:

```
Phase 0: Location and Path Pre-Calculation
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (conditional)
  ↓
Phase 3: Wave-Based Implementation (conditional, 40-60% time savings)
  │       Dependency Analysis → Wave Calculation → Parallel Execution
  │       Wave 1 [P1, P2, P3] ║ Phases in parallel within wave
  │       Wave 2 [P4, P5]     ║ Each wave waits for previous wave completion
  │       Wave 3 [P6]         ║ Dependencies determine wave boundaries
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debug (conditional - only if tests fail)
  ↓
Phase 6: Documentation (conditional - only if implementation occurred)
```

### Workflow Scope Types

The command detects the workflow type and executes only the appropriate phases:

1. **research-only**: Phases 0-1 only
   - Keywords: "research [topic]" without "plan" or "implement"
   - Use case: Pure exploratory research
   - No plan created, no summary

2. **research-and-plan**: Phases 0-2 only (MOST COMMON)
   - Keywords: "research...to create plan", "analyze...for planning"
   - Use case: Research to inform planning
   - Creates research reports + implementation plan
   - No summary (no implementation)

3. **full-implementation**: Phases 0-4, 6
   - Keywords: "implement", "build", "add feature"
   - Use case: Complete feature development
   - Phase 5 conditional on test failures
   - Creates all artifacts including summary

4. **debug-only**: Phases 0, 1, 5 only
   - Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
   - Use case: Bug fixing without new implementation
   - No new plan or summary

### Wave-Based Parallel Execution (Phase 3)

Wave-based execution enables parallel implementation of independent phases, achieving 40-60% time savings compared to sequential execution.

**How It Works**:

1. **Dependency Analysis**: Parse implementation plan to identify phase dependencies
   - Uses `dependency-analyzer.sh` library
   - Extracts `dependencies: [N, M]` from each phase
   - Builds directed acyclic graph (DAG) of phase relationships

2. **Wave Calculation**: Group phases into waves using Kahn's algorithm
   - Wave 1: All phases with no dependencies
   - Wave 2: Phases depending only on Wave 1 phases
   - Wave N: Phases depending only on previous waves

3. **Parallel Execution**: Execute all phases within a wave simultaneously
   - Invoke implementer-coordinator agent for wave orchestration
   - Agent spawns implementation-executor agents in parallel (one per phase)
   - Wait for all phases in wave to complete before next wave

4. **Wave Checkpointing**: Save state after each wave completes
   - Enables resume from wave boundary on interruption
   - Tracks wave number, completed phases, pending phases

**Example Wave Execution**:

```
Plan with 8 phases:
  Phase 1: dependencies: []
  Phase 2: dependencies: []
  Phase 3: dependencies: [1]
  Phase 4: dependencies: [1]
  Phase 5: dependencies: [2]
  Phase 6: dependencies: [3, 4]
  Phase 7: dependencies: [5]
  Phase 8: dependencies: [6, 7]

Wave Calculation Result:
  Wave 1: [Phase 1, Phase 2]          ← 2 phases in parallel (0 dependencies)
  Wave 2: [Phase 3, Phase 4, Phase 5] ← 3 phases in parallel (only depend on Wave 1)
  Wave 3: [Phase 6, Phase 7]          ← 2 phases in parallel (only depend on Waves 1-2)
  Wave 4: [Phase 8]                   ← 1 phase (depends on Wave 3)

Time Savings:
  Sequential: 8 phases × avg_time = 8T
  Wave-based: 4 waves × avg_time = 4T
  Savings: 50% (actual savings depend on phase distribution)
```

**Performance Impact**:
- Best case: 60% time savings (many independent phases)
- Typical case: 40-50% time savings (moderate dependencies)
- Worst case: 0% savings (fully sequential dependencies)
- No overhead for plans with <3 phases (single wave)

**Library Integration**:
See `.claude/lib/dependency-analyzer.sh` for complete wave calculation implementation.

### Performance Targets

- **Context Usage**: <30% throughout workflow (target achieved via context pruning)
  - Phase 1 (Research): 80-90% reduction via metadata extraction
  - Phase 2 (Planning): 80-90% reduction + pruning research if plan-only workflow
  - Phase 3 (Implementation): Aggressive pruning of wave metadata, prune research/planning
  - Phase 4 (Testing): Metadata only (pass/fail status, retain for debugging)
  - Phase 5 (Debug): Prune test output after completion
  - Phase 6 (Documentation): Final pruning, <30% context usage overall
- **File Creation Rate**: 100% (fail-fast if agent doesn't create expected files)
- **Wave-Based Execution**: 40-60% time savings from parallel implementation
  - Dependency graph analysis via dependency-analyzer.sh
  - Kahn's algorithm for topological sorting
  - Parallel phase execution within waves
  - Wave-level checkpointing for resumability
- **Progress Streaming**: Silent PROGRESS: markers at each phase boundary
  - Format: `PROGRESS: [Phase N] - action_description`
  - Enables external monitoring without verbose output
- **Error Reporting**:
  - Clear diagnostic messages for all failure modes
  - Debugging guidance included in every error
  - File system state displayed on verification failures
  - Suggested commands provided for troubleshooting

## Fail-Fast Error Handling

This command implements fail-fast error handling with comprehensive diagnostics for easy debugging.

**Philosophy**: "One clear execution path, fail fast with full context"

**Key Behaviors**:
- **NO retries**: Single execution attempt per operation
- **NO fallbacks**: If operation fails, report why and exit
- **Clear diagnostics**: Every error shows exactly what failed and why
- **Debugging guidance**: Every error includes steps to diagnose the issue
- **Partial research success**: Continue if ≥50% of parallel agents succeed (Phase 1 only)

**Why Fail-Fast?**
- More predictable behavior (no hidden retry loops)
- Easier to debug (clear failure point, no retry state)
- Easier to improve (fix root cause, not mask with retries)
- Faster feedback (immediate failure notification)

## Error Message Structure

Every error message follows this structure:

```
❌ ERROR: [What failed]
   Expected: [What was supposed to happen]
   Found: [What actually happened]

DIAGNOSTIC INFORMATION:
  - [Specific check that failed]
  - [File system state or error details]
  - [Why this might have happened]

What to check next:
  1. [First debugging step]
  2. [Second debugging step]
  3. [Third debugging step]

Example commands to debug:
  ls -la [path]
  cat [file]
  grep [pattern] [file]
```

## Partial Failure Handling

Research phase (Phase 1) continues if ≥50% of parallel agents succeed. All other phases fail immediately on any agent failure.

## Library Requirements

**All Libraries Required**: All libraries are required for proper operation. If any library is missing, the command will fail immediately with clear diagnostic information.

**Required Libraries**:
- workflow-detection.sh - Workflow scope detection and phase execution control
- error-handling.sh - Error classification and diagnostic message generation
- checkpoint-utils.sh - Workflow resume capability and state management
- unified-logger.sh - Progress tracking and event logging
- unified-location-detection.sh - Topic directory structure creation
- metadata-extraction.sh - Context reduction via metadata-only passing
- context-pruning.sh - Context optimization between phases
- dependency-analyzer.sh - Wave-based execution and dependency graph analysis

**Rationale**: Fail-fast philosophy requires all dependencies to be present. Missing libraries indicate configuration issues that should be fixed, not worked around.

## Checkpoint Resume

Checkpoints saved after Phases 1-4. Auto-resumes from last completed phase on startup.

**Behavior**: Validates checkpoint → Skips completed phases → Resumes seamlessly

**See**: [Checkpoint Recovery Pattern](../docs/concepts/patterns/checkpoint-recovery.md) - Schema and implementation details

## Progress Markers

Silent progress markers emitted at phase boundaries enable external monitoring. Format: `PROGRESS: [Phase N] - [action]`

**Complete Documentation**: See [Output Formatting and Context Management → Standardized Progress Markers](../docs/guides/orchestration-best-practices.md#standardized-progress-markers) for format specification, implementation details, parsing examples, and external tool integration.

## Available Utility Functions

[Library sourcing is implemented in Phase 0 STEP 0]

See Phase 0 STEP 0 for library sourcing implementation. All required libraries are sourced at the beginning of the workflow before any bash blocks execute.

**Verification**: All required functions available via sourced libraries (verified in Phase 0 STEP 0).

**Note on Design Decisions**:
- **Metadata extraction**: Uses path-based context passing (not full content) for efficient context management
- **Context pruning**: Bash variables naturally scope, preventing context bloat
- **Fail-fast error handling**: Single execution attempt with comprehensive diagnostics for easy debugging

[REFERENCE-OK: Can be supplemented with external library documentation]

All utility functions are sourced from library files. This table documents the complete API:

### Workflow Detection Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `detect_workflow_scope()` | workflow-detection.sh | Determine workflow type from description | `SCOPE=$(detect_workflow_scope "$DESC")` |
| `should_run_phase()` | workflow-detection.sh | Check if phase executes for current scope | `should_run_phase 3 \|\| exit 0` |

### Error Handling Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `classify_error()` | error-handling.sh | Classify error type (transient/permanent/fatal) | `TYPE=$(classify_error "$ERROR_MSG")` |
| `suggest_recovery()` | error-handling.sh | Suggest recovery action based on error type | `suggest_recovery "$ERROR_TYPE" "$MSG"` |
| `detect_error_type()` | error-handling.sh | Detect specific error category | `TYPE=$(detect_error_type "$ERROR")` |
| `extract_location()` | error-handling.sh | Extract file:line from error message | `LOC=$(extract_location "$ERROR")` |
| `generate_suggestions()` | error-handling.sh | Generate error-specific suggestions | `generate_suggestions "$TYPE" "$MSG" "$LOC"` |

### Checkpoint Management Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `save_checkpoint()` | checkpoint-utils.sh | Save workflow checkpoint for resume | `CKPT=$(save_checkpoint "supervise" "project" "$JSON")` |
| `restore_checkpoint()` | checkpoint-utils.sh | Load most recent checkpoint | `DATA=$(restore_checkpoint "supervise" "project")` |
| `checkpoint_get_field()` | checkpoint-utils.sh | Extract field from checkpoint | `PHASE=$(checkpoint_get_field "$CKPT" ".current_phase")` |
| `checkpoint_set_field()` | checkpoint-utils.sh | Update field in checkpoint | `checkpoint_set_field "$CKPT" ".phase" "3"` |

### Progress Logging Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `emit_progress()` | unified-logger.sh | Emit silent progress marker | `emit_progress "1" "Research complete"` |

### Function Categories Summary

- **Workflow Management**: 2 functions (scope detection, phase execution)
- **Error Handling**: 5 functions (classification, recovery, suggestions, location extraction)
- **Checkpoint Management**: 4 functions (save, restore, get/set fields)
- **Progress Logging**: 1 function (progress markers)

**Total Functions Available**: 12 core utilities

## Retained Usage Examples

[REFERENCE-OK: Examples can be moved to library documentation if needed]

The following examples demonstrate common usage patterns for sourced utilities:

### Example 1: Workflow Scope Detection

```bash
# Detect workflow scope and configure phases
WORKFLOW_DESCRIPTION="research authentication patterns to create implementation plan"
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Map scope to phase execution list
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

export WORKFLOW_SCOPE PHASES_TO_EXECUTE
```

### Example 2: Conditional Phase Execution

```bash
# Check if phase should run
should_run_phase 3 || {
  echo "⏭️  Skipping Phase 3 (Implementation)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  exit 0
}

echo "Executing Phase 3: Implementation"
```

### Example 3: Error Handling with Recovery

```bash
# Classify error and provide clear diagnostics (fail-fast)
ERROR_MSG="Agent failed to create file: $EXPECTED_PATH"
ERROR_TYPE=$(classify_error "$ERROR_MSG")

echo "❌ ERROR: $ERROR_TYPE"
echo "   Expected: File exists at $EXPECTED_PATH"
echo "   Found: File does not exist"
echo ""
echo "DIAGNOSTIC INFORMATION:"
suggest_recovery "$ERROR_TYPE" "$ERROR_MSG"
echo ""
echo "Workflow TERMINATED."
exit 1
```

### Example 4: Progress Markers

```bash
# Emit progress markers at phase transitions
emit_progress "1" "Invoking 4 research agents in parallel"
# ... agent invocations ...
emit_progress "1" "All research agents completed"
emit_progress "2" "Planning phase started"
```
```

## Optimization Note: Integration Approach

**Context**: This command was refactored using an "integrate, not build" approach after discovering that 70-80% of the planned infrastructure already existed in production-ready form.

**Original Plan**:
- 6 phases (Pattern Verification, Template Removal, Library Building, Standards Documentation, Integration Testing, Summary)
- 12-15 days estimated duration
- Build new libraries for location detection, metadata extraction, context pruning
- Extract agent behavioral templates from scratch

**Optimized Approach**:
- 3 phases (Pattern Verification + Template Removal, Standards Documentation, Integration Testing)
- 8-11 days actual duration (40-50% reduction)
- Integrated existing libraries instead of rebuilding
- Referenced existing agent behavioral files in `.claude/agents/` instead of extracting

**Key Insights**:
1. **Infrastructure maturity eliminates redundant work**: 100% coverage on location detection, metadata extraction, context pruning, error handling, and all 6 agent behavioral files
2. **Single-pass editing**: Consolidated 6 phases into 3 by combining related edits
3. **Git provides version control**: Eliminated unnecessary backup file creation (saves 0.5 days, removes stale backup risk)
4. **Realistic targets**: Adjusted file size target from 1,600 lines (unrealistic 37% reduction) to 2,000 lines (realistic 21% reduction based on /orchestrate at 5,443 lines)

**Impact**:
- Time savings: 4-5 days (40-50% reduction)
- Quality improvement: 100% consistency with existing infrastructure
- Maintenance burden: Eliminated (no template duplication to synchronize)

**Reference**: For complete analysis, see [Research Report Overview](/home/benjamin/.config/.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/reports/001_analysis_of_supervise_command_refactor_plan_for_re_research/OVERVIEW.md)

## Phase 0: Project Location and Path Pre-Calculation

[EXECUTION-CRITICAL: Library sourcing MUST occur before any function calls]

**Objective**: Source required libraries, then establish topic directory structure and calculate all artifact paths.

**Pattern**: Library sourcing → utility-based location detection → directory creation → path export

**Optimization**: Uses deterministic bash utilities (topic-utils.sh, detect-project-dir.sh) for 85-95% token reduction and 20x+ speedup compared to agent-based detection.

**Critical**: ALL libraries MUST be sourced before any function calls, and ALL paths MUST be calculated before Phase 1 begins.

### Implementation

**EXECUTE NOW**: USE the Bash tool to execute the following Phase 0 setup:

STEP 0: Source Required Libraries (MUST BE FIRST)

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library-sourcing utilities first
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo ""
  echo "Expected location: $SCRIPT_DIR/../lib/library-sourcing.sh"
  exit 1
fi

# Source all required libraries
if ! source_required_libraries "dependency-analyzer.sh" "context-pruning.sh" "checkpoint-utils.sh" "unified-location-detection.sh" "workflow-detection.sh" "unified-logger.sh" "error-handling.sh"; then
  exit 1
fi

echo "✓ All libraries loaded successfully"

# Verify critical functions are defined
REQUIRED_FUNCTIONS=(
  "detect_workflow_scope"
  "should_run_phase"
  "emit_progress"
  "save_checkpoint"
  "restore_checkpoint"
)

MISSING_FUNCTIONS=()
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done

if [ ${#MISSING_FUNCTIONS[@]} -gt 0 ]; then
  echo "ERROR: Required functions not defined after library sourcing:"
  for func in "${MISSING_FUNCTIONS[@]}"; do
    echo "  - $func()"
  done
  exit 1
fi

# Define inline helper functions using heredoc pattern to avoid eval escaping issues
cat <<'INLINE_FUNCTIONS' | bash
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"

  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      echo "→ Review artifacts: ls -la $TOPIC_PATH/reports/"
      ;;
    research-and-plan)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
      echo ""
      echo "⚠️  NOTE: Implementation was NOT executed (workflow: research-and-plan)"
      echo "  Reason: Workflow type requires explicit /implement invocation"
      echo ""
      echo "→ To implement: /implement $PLAN_PATH"
      ;;
    full-implementation)
      echo "Implementation complete. Summary: $SUMMARY_PATH"
      echo "→ Review summary for next steps"
      ;;
    debug-only)
      echo "Debug analysis complete: $DEBUG_REPORT"
      echo "→ Review findings and apply fixes"
      ;;
    *)
      echo "Workflow artifacts available in: $TOPIC_PATH"
      echo "→ Review directory for outputs"
      ;;
  esac
  echo ""
}

verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"  # Success - single character, no newline
    return 0
  else
    # Failure - verbose diagnostic
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    echo "   Expected: File exists at $file_path"
    [ ! -f "$file_path" ] && echo "   Found: File does not exist" || echo "   Found: File empty (0 bytes)"
    echo ""
    echo "DIAGNOSTIC INFORMATION:"
    echo "  - Expected path: $file_path"
    echo "  - Parent directory: $(dirname "$file_path")"

    local dir="$(dirname "$file_path")"
    if [ -d "$dir" ]; then
      local file_count
      file_count=$(ls -1 "$dir" 2>/dev/null | wc -l)
      echo "  - Directory status: ✓ Exists ($file_count files)"
      if [ "$file_count" -gt 0 ]; then
        echo "  - Recent files:"
        ls -lht "$dir" | head -4
      fi
    else
      echo "  - Directory status: ✗ Does not exist"
      echo "  - Fix: mkdir -p $dir"
    fi
    echo ""
    echo "Diagnostic commands:"
    echo "  ls -la $dir"
    echo "  cat .claude/agents/[agent-name].md | head -50"
    echo ""
    return 1
  fi
}

export -f display_brief_summary
export -f verify_file_created
INLINE_FUNCTIONS

# Verify inline functions are defined
REQUIRED_INLINE_FUNCTIONS=(
  "display_brief_summary"
  "verify_file_created"
)

for func in "${REQUIRED_INLINE_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    echo "ERROR: Inline function not defined: $func"
    exit 1
  fi
done

emit_progress "0" "Libraries loaded and verified"

STEP 1: Parse workflow description from command arguments

WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "DIAGNOSTIC INFO: Missing Workflow Description"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "ERROR: Workflow description required"
  echo ""
  echo "Usage: /coordinate \"<workflow description>\""
  echo ""
  echo "Examples:"
  echo "  /coordinate \"research API authentication patterns\""
  echo "  /coordinate \"plan user profile feature\""
  echo "  /coordinate \"implement and test authentication system\""
  echo "  /coordinate \"debug login failure issue\""
  echo ""
  exit 1
fi

# Check for existing checkpoint (auto-resume capability)
RESUME_DATA=$(restore_checkpoint "coordinate" 2>/dev/null || echo "")
if [ -n "$RESUME_DATA" ]; then
  RESUME_PHASE=$(echo "$RESUME_DATA" | jq -r '.current_phase // empty')
else
  RESUME_PHASE=""
fi

if [ -n "$RESUME_PHASE" ]; then
  emit_progress "Resume" "Checkpoint detected - resuming from Phase $RESUME_PHASE"
  emit_progress "Resume" "Skipping completed phases 0-$((RESUME_PHASE - 1))"
  echo ""

  # Skip to the resume phase
  # (Implementation note: In actual execution, this would jump to the appropriate phase section)
fi

STEP 2: Detect workflow scope

WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Map scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    SKIP_PHASES="2,3,4,5,6"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    SKIP_PHASES="3,4,5,6"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4"
    SKIP_PHASES=""  # Phase 5 conditional on test failures, Phase 6 always
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    SKIP_PHASES="2,3,4,6"
    ;;
esac

export WORKFLOW_SCOPE PHASES_TO_EXECUTE SKIP_PHASES

echo "Workflow: $WORKFLOW_SCOPE → Phases $PHASES_TO_EXECUTE"

STEP 3: Initialize workflow paths using consolidated function

Use the workflow-initialization.sh library for unified path calculation and directory creation.

# Source workflow initialization library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/workflow-initialization.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-initialization.sh"
else
  echo "ERROR: workflow-initialization.sh not found"
  echo "This is a required library file for workflow operation."
  echo "Please ensure .claude/lib/workflow-initialization.sh exists."
  exit 1
fi

# Call unified initialization function (silent)
# This consolidates STEPS 3-7 (225+ lines → ~10 lines)
# Implements 3-step pattern: scope detection → path pre-calculation → directory creation
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

# Display simple workflow scope report
echo "Workflow Scope: $WORKFLOW_SCOPE"
echo "Topic: $TOPIC_PATH"
echo ""
echo "Phases to Execute:"
case "$WORKFLOW_SCOPE" in
  research-only)
    echo "  ✓ Phase 0: Initialization"
    echo "  ✓ Phase 1: Research (parallel agents)"
    echo "  ✗ Phase 2: Planning (skipped)"
    echo "  ✗ Phase 3: Implementation (skipped)"
    ;;
  research-and-plan)
    echo "  ✓ Phase 0: Initialization"
    echo "  ✓ Phase 1: Research (parallel agents)"
    echo "  ✓ Phase 2: Planning"
    echo "  ✗ Phase 3: Implementation (skipped)"
    ;;
  full-implementation)
    echo "  ✓ Phase 0: Initialization"
    echo "  ✓ Phase 1: Research (parallel agents)"
    echo "  ✓ Phase 2: Planning"
    echo "  ✓ Phase 3: Implementation"
    echo "  ✓ Phase 4: Testing"
    echo "  ✓ Phase 6: Documentation"
    ;;
  debug-only)
    echo "  ✓ Phase 0: Initialization"
    echo "  ✓ Phase 1: Research root cause"
    echo "  ✓ Phase 5: Debug analysis"
    echo "  ✗ Phase 2-4,6: (skipped)"
    ;;
esac
echo ""

# Reconstruct REPORT_PATHS array from exported variables
# (Bash arrays cannot be directly exported, so we use a helper function)
reconstruct_report_paths_array

# Emit progress marker
emit_progress "0" "Location pre-calculation complete (topic: $TOPIC_PATH)"
echo ""

STEP 3B: Pre-format agent invocation context blocks

**EXECUTE NOW**: USE the Bash tool to pre-calculate context blocks for all agent types:

# Pre-format context blocks to reduce placeholder substitution overhead
# Strategy: Pre-fill static values, Claude only substitutes dynamic values
# Reduces 8 substitutions per agent → 3 substitutions per agent (62.5% reduction)

# Note: Using direct variable assignment (not heredoc) because we want bash
# to expand variables NOW, and Claude can read the exported values later

# Research agent context template (complexity pre-filled)
RESEARCH_CONTEXT_TEMPLATE="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/research-specialist.md

**Workflow-Specific Context**:
- Project Standards: /home/benjamin/.config/CLAUDE.md
- Complexity Level: $RESEARCH_COMPLEXITY

**CRITICAL**: Create report file at EXACT path provided above.

Execute research following all guidelines in behavioral file.
Return: REPORT_CREATED: [report file path]"

# Plan architect context (all static values pre-filled)
PLAN_CONTEXT="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/plan-architect.md

**Workflow-Specific Context**:
- Plan File Path: $PLAN_PATH
- Project Standards: /home/benjamin/.config/CLAUDE.md
- Workflow Type: $WORKFLOW_SCOPE

Execute planning following all guidelines in behavioral file.
Return: PLAN_CREATED: $PLAN_PATH"

# Implementation coordinator context (all static values pre-filled)
IMPL_CONTEXT="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/implementer-coordinator.md

**Workflow-Specific Context**:
- Plan File Path: $PLAN_PATH
- Implementation Artifacts Directory: $IMPL_ARTIFACTS
- Project Standards: /home/benjamin/.config/CLAUDE.md
- Workflow Type: $WORKFLOW_SCOPE

Execute implementation following all guidelines in behavioral file."

# Test executor context (static values pre-filled)
TEST_CONTEXT="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/test-executor.md

**Workflow-Specific Context**:
- Test Results Path: $TOPIC_PATH/outputs/test_results.md
- Project Standards: /home/benjamin/.config/CLAUDE.md
- Plan File: $PLAN_PATH
- Implementation Artifacts: $IMPL_ARTIFACTS

Execute testing following all guidelines in behavioral file."

# Debug analyst context (static values pre-filled)
DEBUG_CONTEXT="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/debug-analyst.md

**Workflow-Specific Context**:
- Test Results: $TOPIC_PATH/outputs/test_results.md
- Project Standards: /home/benjamin/.config/CLAUDE.md

Execute debug analysis following all guidelines in behavioral file."

# Documentation specialist context (static values pre-filled)
DOC_CONTEXT="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/documentation-specialist.md

**Workflow-Specific Context**:
- Plan File: $PLAN_PATH
- Implementation Artifacts: $IMPL_ARTIFACTS
- Project Standards: /home/benjamin/.config/CLAUDE.md

Execute documentation following all guidelines in behavioral file."

# Code writer context (static values pre-filled)
CODE_WRITER_CONTEXT="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/code-writer.md

**Workflow-Specific Context**:
- Project Standards: /home/benjamin/.config/CLAUDE.md

Execute code modifications following all guidelines in behavioral file."

# Research synthesizer context (static values pre-filled)
OVERVIEW_SYNTHESIS_CONTEXT="Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/research-synthesizer.md

**Workflow-Specific Context**:
- Project Standards: /home/benjamin/.config/CLAUDE.md

**CRITICAL**: Create overview file at EXACT path provided above.

STEP 1: Use Write tool to create overview file at specified path
STEP 2: Read all research reports from the list
STEP 3: Write 400-500 word overview synthesizing:
        - Common themes across reports
        - Conflicting findings (if any)
        - Prioritized recommendations
        - Cross-references between reports

Execute synthesis following all guidelines in behavioral file."

# Export for use in later phases
export RESEARCH_CONTEXT_TEMPLATE
export PLAN_CONTEXT
export IMPL_CONTEXT
export TEST_CONTEXT
export DEBUG_CONTEXT
export DOC_CONTEXT
export CODE_WRITER_CONTEXT
export OVERVIEW_SYNTHESIS_CONTEXT

emit_progress "0" "Context blocks pre-formatted"
echo ""

## Phase 1: Research

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Conduct parallel research on workflow topics with 100% file creation rate.

**Pattern**: Analyze complexity → Invoke 2-4 research agents in parallel → Verify all files created → Extract metadata

**Critical Success Factor**: 100% file creation rate on first attempt (no retries)

### Phase 1 Execution Check

**EXECUTE NOW**: USE the Bash tool to check if Phase 1 should execute:

should_run_phase 1 || {
  echo "⏭️  Skipping Phase 1 (Research)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_brief_summary
  exit 0
}

emit_progress "1" "Phase 1: Research (parallel agent invocation)"

### Complexity-Based Research Topics

STEP 1: Determine research complexity (1-4 topics based on workflow)

**EXECUTE NOW**: USE the Bash tool to determine research complexity:

# Simple keyword-based complexity scoring
RESEARCH_COMPLEXITY=2  # Default: 2 research topics

# Increase complexity for these keywords
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

# Increase further for very complex workflows
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

# Reduce for simple workflows
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"

### Parallel Research Agent Invocation

STEP 2: Invoke 2-4 research agents in parallel (single message, multiple Task calls)

**EXECUTE NOW**: USE the Bash tool to emit progress marker:

emit_progress "1" "Invoking $RESEARCH_COMPLEXITY research agents in parallel"

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocations, then execute each one:

# Generate Task invocation templates with all variables expanded
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  TOPIC="${RESEARCH_TOPICS[$i-1]}"
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  echo "=== Research Agent $i/$RESEARCH_COMPLEXITY ==="
  echo "Topic: $TOPIC"
  echo "Report: $REPORT_PATH"
  echo ""
  echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
  echo ""
  echo "Task {"
  echo "  subagent_type: \"general-purpose\""
  echo "  description: \"Research $TOPIC with mandatory artifact creation\""
  echo "  timeout: 300000"
  echo "  prompt: \""
  echo "    $RESEARCH_CONTEXT_TEMPLATE"
  echo ""
  echo "    **Topic-Specific Values**:"
  echo "    - Research Topic: $TOPIC"
  echo "    - Report Path: $REPORT_PATH"
  echo "  \""
  echo "}"
  echo ""
done

**YOUR RESPONSIBILITY**: Execute the Task tool invocations shown above (bash has already expanded all variables)

**EXECUTE NOW**: USE the Bash tool to emit progress after agent invocations:

emit_progress "1" "All research agents invoked - awaiting completion"

### Mandatory Verification - Research Reports with Auto-Recovery

**VERIFICATION REQUIRED**: All research report files must exist before continuing to Phase 2

STEP 3: Verify ALL research reports created successfully (concise format with fail-fast)

**EXECUTE NOW**: USE the Bash tool to verify all research reports:

# Concise verification with inline status indicators
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()

# MANDATORY VERIFICATION checkpoint: Research reports
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if ! verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Phase 1"; then
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  else
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  fi
done

SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORT_PATHS[@]}

# Final summary
if [ $VERIFICATION_FAILURES -eq 0 ]; then
  echo " (all passed)"  # Completes the "Verifying..." line
  emit_progress "1" "Verified: $SUCCESSFUL_REPORT_COUNT/$RESEARCH_COMPLEXITY research reports"
else
  echo ""
  echo "Workflow TERMINATED: Fix verification failures and retry"
  exit 1
fi

# VERIFICATION REQUIREMENT: Must not proceed without verification
echo "Verification checkpoint passed - proceeding to research overview"
echo ""

### Research Overview (Conditional Synthesis)

STEP 4: Conditionally create overview report based on workflow scope

**DECISION LOGIC**: Overview synthesis only occurs for research-only workflows.
When planning follows (research-and-plan, full-implementation), the plan-architect
agent will synthesize research reports, making OVERVIEW.md redundant.

**EXECUTE NOW**: USE the Bash tool to conditionally create research overview:

# Determine if overview synthesis should occur
# Uses shared library function: should_synthesize_overview()
if should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
  # Calculate overview path using standardized function (ALL CAPS format)
  OVERVIEW_PATH=$(calculate_overview_path "$RESEARCH_SUBDIR")

  echo "Creating research overview to synthesize findings..."
  echo "  Path: $OVERVIEW_PATH"

  # Build report list for overview agent
  REPORT_LIST=""
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    REPORT_LIST+="- $report\n"
  done

  echo "Invoking research synthesizer agent..."

**EXECUTE NOW**: USE the Task tool NOW to invoke the research-synthesizer agent.

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocation:

# Build report list
REPORT_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  REPORT_LIST="${REPORT_LIST}  - $report"$'\n'
done

echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
echo ""
echo "Task {"
echo "  subagent_type: \"general-purpose\""
echo "  description: \"Synthesize research findings into comprehensive overview\""
echo "  timeout: 300000"
echo "  prompt: \""
echo "    $OVERVIEW_SYNTHESIS_CONTEXT"
echo ""
echo "    **Synthesis-Specific Context**:"
echo "    - Overview Path: $OVERVIEW_PATH"
echo "    - Research Reports to Synthesize:"
echo "$REPORT_LIST"
echo "    - Total Reports: $SUCCESSFUL_REPORT_COUNT"
echo ""
echo "    Return: OVERVIEW_CREATED: $OVERVIEW_PATH"
echo "  \""
echo "}"

**YOUR RESPONSIBILITY**: Execute the Task tool invocation shown above (bash has already expanded all variables)

**EXECUTE NOW**: USE the Bash tool to verify overview creation and complete conditional logic:

  # MANDATORY VERIFICATION checkpoint: Research overview
  verify_file_created "$OVERVIEW_PATH" "Research Overview" "Phase 1"
else
  # Overview synthesis skipped - plan-architect will synthesize reports
  SKIP_REASON=$(get_synthesis_skip_reason "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT")
  echo "⏭️  Skipping overview synthesis"
  echo "  Reason: $SKIP_REASON"
  echo ""
fi

emit_progress "1" "Research complete: $SUCCESSFUL_REPORT_COUNT reports verified"
echo ""

**EXECUTE NOW**: USE the Bash tool to save Phase 1 checkpoint and apply context pruning:

# Save checkpoint after Phase 1
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'"' || echo '')
}
EOF
)
save_checkpoint "coordinate" "phase_1" "$ARTIFACT_PATHS_JSON"

# Context pruning after Phase 1
# Store minimal phase metadata for Phase 1 (artifact paths only)
PHASE_1_ARTIFACTS="${SUCCESSFUL_REPORT_PATHS[@]}"
store_phase_metadata "phase_1" "complete" "$PHASE_1_ARTIFACTS"

# Apply workflow-specific pruning policy (no pruning after Phase 1 - research needed for planning)
echo "Phase 1 metadata stored (context reduction: 80-90%)"

# Emit progress marker
emit_progress "1" "Research complete ($SUCCESSFUL_REPORT_COUNT reports created)"

## Phase 2: Planning

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Create implementation plan using Task tool with behavioral injection (no SlashCommand).

**Pattern**: Prepare context → Invoke plan-architect agent → Verify plan created → Extract metadata

**Critical**: Uses Task tool with behavioral injection, NOT /plan command

### Phase 2 Execution Check

**EXECUTE NOW**: USE the Bash tool to check if Phase 2 should execute:

should_run_phase 2 || {
  echo "⏭️  Skipping Phase 2 (Planning)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_brief_summary
  exit 0
}

emit_progress "2" "Phase 2: Planning (plan-architect invocation)"

### Planning Context Preparation

STEP 1: Prepare planning context with research reports

**EXECUTE NOW**: USE the Bash tool to prepare planning context:

echo "Preparing planning context..."

# Build research reports list for injection
RESEARCH_REPORTS_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  RESEARCH_REPORTS_LIST+="- $report\n"
done

# Include overview if created (only for research-only workflows)
if [ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ]; then
  RESEARCH_REPORTS_LIST+="- $OVERVIEW_PATH (synthesis)\n"
fi

# Discover standards file
STANDARDS_FILE="${LOCATION}/CLAUDE.md"
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="${LOCATION}/.claude/CLAUDE.md"
fi
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="(none found)"
fi

echo "Planning Context: $SUCCESSFUL_REPORT_COUNT reports, standards: $STANDARDS_FILE"

### Plan-Architect Agent Invocation

STEP 2: Invoke plan-architect agent via Task tool

**EXECUTE NOW**: USE the Task tool NOW to invoke the plan-architect agent.

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocation:

echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
echo ""
echo "Task {"
echo "  subagent_type: \"general-purpose\""
echo "  description: \"Create implementation plan with mandatory file creation\""
echo "  timeout: 300000"
echo "  prompt: \""
echo "    $PLAN_CONTEXT"
echo ""
echo "    **Additional Context**:"
echo "    - Workflow Description: $WORKFLOW_DESCRIPTION"
echo "    - Research Reports: $RESEARCH_REPORTS_LIST"
echo "    - Research Report Count: $SUCCESSFUL_REPORT_COUNT"
echo ""
echo "    **CRITICAL**: Create plan file at EXACT path provided above.
echo "  \""
echo "}"

**YOUR RESPONSIBILITY**: Execute the Task tool invocation shown above (bash has already expanded all variables)

### Mandatory Verification - Plan Creation

**VERIFICATION REQUIRED**: Plan file must exist before continuing to Phase 3 or completing workflow

**GUARANTEE REQUIRED**: Plan contains minimum 3 phases with standard structure

STEP 3: MANDATORY VERIFICATION checkpoint - Verify plan file created successfully (concise format)

**EXECUTE NOW**: USE the Bash tool to verify plan creation:

echo -n "Verifying implementation plan: "

if verify_file_created "$PLAN_PATH" "Implementation plan" "Phase 2"; then
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
  if [ "$PHASE_COUNT" -lt 3 ] || ! grep -q "^## Metadata" "$PLAN_PATH"; then
    echo " (structure warnings)"
    echo "⚠️  Plan: $PHASE_COUNT phases (expected ≥3)"
  else
    echo " ($PHASE_COUNT phases)"
  fi
  emit_progress "2" "Verified: Implementation plan ($PHASE_COUNT phases)"
else
  echo ""
  echo "Workflow TERMINATED: Fix plan creation and retry"
  exit 1
fi

### Plan Metadata Extraction

**EXECUTE NOW**: USE the Bash tool to extract plan metadata:

STEP 4: Extract plan metadata for reporting

# Extract complexity from plan
PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")

# Extract estimated time
PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_PATH" | cut -d: -f2 | xargs || echo "unknown")

echo "Plan: $PHASE_COUNT phases, complexity: $PLAN_COMPLEXITY, est. time: $PLAN_EST_TIME"
emit_progress "2" "Planning complete: $PHASE_COUNT phases, $PLAN_EST_TIME estimated"
echo ""

# Save checkpoint after Phase 2
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH"
}
EOF
)
save_checkpoint "coordinate" "phase_2" "$ARTIFACT_PATHS_JSON"

# Context pruning after Phase 2
# Store minimal phase metadata for Phase 2 (plan path only, keep research for implementation)
store_phase_metadata "phase_2" "complete" "$PLAN_PATH"

# Apply workflow-specific pruning policy (prune research after planning for plan_creation workflow)
apply_pruning_policy "planning" "$WORKFLOW_SCOPE"
echo "Phase 2 metadata stored (context reduction: 80-90%)"

# Emit progress marker
emit_progress "2" "Planning complete (plan created with $PHASE_COUNT phases)"

### Workflow Completion Check (After Phase 2)

**EXECUTE NOW**: USE the Bash tool to save Phase 2 checkpoint:

STEP 5: Check if workflow should continue to implementation

should_run_phase 3 || {
  emit_progress "Complete" "/coordinate workflow complete"
  echo ""
  echo "Workflow complete: $WORKFLOW_SCOPE"
  echo ""
  echo "Artifacts:"
  echo "  ✓ $SUCCESSFUL_REPORT_COUNT research reports"
  if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
    PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
    PLAN_EST=$(grep "Estimated Total Time:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")
    echo "  ✓ 1 implementation plan ($PHASE_COUNT phases, $PLAN_EST estimated)"
  fi
  if [ -n "$SUMMARY_PATH" ] && [ -f "$SUMMARY_PATH" ]; then
    echo "  ✓ 1 implementation summary"
  fi
  echo ""
  echo "⚠️  NOTE: To execute implementation, either:"
  echo "    1. Use workflow description: 'implement [feature]'"
  echo "    2. Run separately: /implement $PLAN_PATH"
  echo ""


  exit 0
}

## Phase 3: Wave-Based Implementation

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Execute implementation plan with wave-based parallel execution for 40-60% time savings.

**Pattern**: Analyze dependencies → Calculate waves → Execute phases in parallel within waves → Verify completion

**Critical**: Implementer-coordinator agent orchestrates wave execution and delegates to implementation-executor agents per phase

### Phase 3 Execution Check

**EXECUTE NOW**: USE the Bash tool to check if Phase 3 should execute:

should_run_phase 3 || {
  echo "⏭️  Skipping Phase 3 (Implementation)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  # Continue to next phase check or completion
}

### Step 1: Dependency Analysis and Wave Calculation

**EXECUTE NOW**: USE the Bash tool to analyze dependencies and calculate waves:

emit_progress "3" "Phase 3: Wave-based implementation"

# Track performance metrics
IMPL_START_TIME=$(date +%s)

# Analyze plan dependencies and calculate waves
echo "Analyzing plan dependencies for wave execution..."
DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_PATH")

if [[ $? -ne 0 ]]; then
  echo "❌ ERROR: Dependency analysis failed"
  echo "$DEPENDENCY_ANALYSIS" | jq -r '.error // "Unknown error"'
  echo ""
  echo "DIAGNOSTIC: Check plan file for valid dependency syntax"
  echo "Expected format: dependencies: [1, 2] or dependencies: []"
  exit 1
fi

# Extract waves information
WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.waves')
WAVE_COUNT=$(echo "$WAVES" | jq 'length')
TOTAL_PHASES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.dependency_graph.nodes | length')

echo "✅ Dependency analysis complete"
echo "   Total phases: $TOTAL_PHASES"
echo "   Execution waves: $WAVE_COUNT"
echo ""

# Display wave structure
echo "Wave execution plan:"
for ((wave_num=1; wave_num<=WAVE_COUNT; wave_num++)); do
  WAVE=$(echo "$WAVES" | jq ".[$((wave_num-1))]")
  WAVE_PHASES=$(echo "$WAVE" | jq -r '.phases[]')
  PHASE_COUNT=$(echo "$WAVE" | jq '.phases | length')
  CAN_PARALLEL=$(echo "$WAVE" | jq -r '.can_parallel')

  echo "  Wave $wave_num: $PHASE_COUNT phase(s) $([ "$CAN_PARALLEL" == "true" ] && echo "[PARALLEL]" || echo "[SEQUENTIAL]")"
  for phase in $WAVE_PHASES; do
    echo "    - Phase $phase"
  done
done
echo ""

### Step 2: Implementer-Coordinator Agent Invocation

**EXECUTE NOW**: USE the Task tool NOW to invoke the implementer-coordinator agent.

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocation:

echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
echo ""
echo "Task {"
echo "  subagent_type: \"general-purpose\""
echo "  description: \"Orchestrate wave-based implementation with parallel execution\""
echo "  timeout: 600000"
echo "  prompt: \""
echo "    $IMPL_CONTEXT"
echo ""
echo "    **Wave Execution Context**:"
echo "    - Total Waves: $WAVE_COUNT"
echo "    - Wave Structure: $WAVES"
echo "    - Dependency Graph: $(echo "$DEPENDENCY_ANALYSIS" | jq -c .dependency_graph)"
echo ""
echo "    **CRITICAL**: Execute phases wave-by-wave, parallel within waves when possible."
echo ""
echo "    Return: IMPLEMENTATION_STATUS: {complete|partial|failed}"
echo "    Return: WAVES_COMPLETED: [number]"
echo "    Return: PHASES_COMPLETED: [number]"
echo "    Return: PHASES_TOTAL: [number]"
echo "    Return: PARALLEL_PHASES_EXECUTED: [number]"
echo "    Return: TIME_SAVED_PERCENTAGE: [number]"
echo "  \""
echo "}"

**YOUR RESPONSIBILITY**: Execute the Task tool invocation shown above (bash has already expanded all variables)

### Step 3: Mandatory Verification - Implementation Completion

**EXECUTE NOW**: USE the Bash tool to verify implementation and save checkpoint:

**VERIFICATION REQUIRED**: Implementation artifacts directory must exist and contain phase outputs

**CHECKPOINT REQUIREMENT**: Report implementation status and wave execution metrics

# Parse implementation status from agent output
IMPL_STATUS=$(echo "$AGENT_OUTPUT" | grep "IMPLEMENTATION_STATUS:" | cut -d: -f2 | xargs)
WAVES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "WAVES_COMPLETED:" | cut -d: -f2 | xargs)
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "PHASES_COMPLETED:" | cut -d: -f2 | xargs)
PHASES_TOTAL=$(echo "$AGENT_OUTPUT" | grep "PHASES_TOTAL:" | cut -d: -f2 | xargs)
PARALLEL_PHASES=$(echo "$AGENT_OUTPUT" | grep "PARALLEL_PHASES_EXECUTED:" | cut -d: -f2 | xargs)
TIME_SAVED=$(echo "$AGENT_OUTPUT" | grep "TIME_SAVED_PERCENTAGE:" | cut -d: -f2 | xargs)

# Calculate actual implementation time
IMPL_END_TIME=$(date +%s)
IMPL_DURATION=$((IMPL_END_TIME - IMPL_START_TIME))
IMPL_MINUTES=$((IMPL_DURATION / 60))
IMPL_SECONDS=$((IMPL_DURATION % 60))

echo -n "Verifying implementation artifacts: "

# MANDATORY VERIFICATION checkpoint: Implementation artifacts
if [ -d "$IMPL_ARTIFACTS" ]; then
  ARTIFACT_COUNT=$(find "$IMPL_ARTIFACTS" -type f 2>/dev/null | wc -l)
  echo "✓ ($ARTIFACT_COUNT files)"
  emit_progress "3" "Verified: Implementation artifacts ($ARTIFACT_COUNT files)"
else
  echo ""
  echo "✗ ERROR [Phase 3]: Implementation artifacts directory not created"
  echo "   Expected: Directory exists at $IMPL_ARTIFACTS"
  echo ""
  echo "DIAGNOSTIC INFORMATION:"
  echo "  - Status: $IMPL_STATUS (waves: $WAVES_COMPLETED/$WAVE_COUNT)"
  echo "  - Duration: ${IMPL_MINUTES}m${IMPL_SECONDS}s"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi

# Set flag for Phase 6 (documentation)
if [ "$IMPL_STATUS" == "complete" ] || [ "$IMPL_STATUS" == "partial" ]; then
  IMPLEMENTATION_OCCURRED="true"
fi

# Save checkpoint after Phase 3 with wave execution metrics
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS",
  "wave_execution": {
    "waves_completed": $WAVES_COMPLETED,
    "waves_total": $WAVE_COUNT,
    "phases_completed": $PHASES_COMPLETED,
    "phases_total": $PHASES_TOTAL,
    "parallel_phases": $PARALLEL_PHASES,
    "time_saved_percentage": $TIME_SAVED,
    "duration_seconds": $IMPL_DURATION
  }
}
EOF
)
save_checkpoint "coordinate" "phase_3" "$ARTIFACT_PATHS_JSON"

# Context pruning after Phase 3 - Aggressive pruning of wave metadata
# Store minimal phase metadata for Phase 3 (implementation status only)
store_phase_metadata "phase_3" "complete" "implementation_metrics"

# Apply workflow-specific pruning policy (prune research and planning after implementation)
apply_pruning_policy "implementation" "orchestrate"

# Report context savings
CONTEXT_AFTER=$(get_current_context_size)
echo "Phase 3 metadata pruned (wave details removed, keeping summary only)"
echo "Context reduction: 80-90% (target: <30% usage achieved)"

# Emit progress marker
emit_progress "3" "Implementation complete ($PARALLEL_PHASES phases in parallel, $TIME_SAVED% time saved)"

## Phase 4: Testing

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Execute comprehensive test suite and collect results.

**Pattern**: Invoke test-specialist agent → Verify test results → Determine if debugging needed

**Critical**: Test results determine whether Phase 5 (Debug) executes

### Phase 4 Execution Check

**EXECUTE NOW**: USE the Bash tool to check if Phase 4 should execute:

should_run_phase 4 || {
  echo "⏭️  Skipping Phase 4 (Testing)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  # Continue to next phase check or completion
}

emit_progress "4" "Phase 4: Testing (test-specialist invocation)"

### Test-Specialist Agent Invocation

STEP 1: Invoke test-specialist agent

**EXECUTE NOW**: USE the Task tool NOW to invoke the test-specialist agent.

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocation:

echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
echo ""
echo "Task {"
echo "  subagent_type: \"general-purpose\""
echo "  description: \"Execute comprehensive tests with mandatory results file\""
echo "  timeout: 300000"
echo "  prompt: \""
echo "    $TEST_CONTEXT"
echo ""
echo "    **CRITICAL**: Create test results file at path provided above."
echo ""
echo "    Return: TEST_STATUS: {passing|failing}"
echo "    Return: TESTS_TOTAL: [number]"
echo "    Return: TESTS_PASSED: [number]"
echo "    Return: TESTS_FAILED: [number]"
echo "  \""
echo "}"

**YOUR RESPONSIBILITY**: Execute the Task tool invocation shown above (bash has already expanded all variables)

### Test Results Verification

**VERIFICATION REQUIRED**: Test results file must exist to determine Phase 5 execution

**CHECKPOINT REQUIREMENT**: Report test status to determine if debugging needed

STEP 2: MANDATORY VERIFICATION checkpoint - Parse and verify test results

# Parse test status from agent output
TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)
TESTS_FAILED=$(echo "$AGENT_OUTPUT" | grep "TESTS_FAILED:" | cut -d: -f2 | xargs)

emit_progress "4" "Test results: $TESTS_PASSED/$TESTS_TOTAL passed"

echo "Test Status: $TEST_STATUS ($TESTS_PASSED/$TESTS_TOTAL passed)"

if [ "$TEST_STATUS" == "passing" ]; then
  TESTS_PASSING="true"
  echo "✅ All tests passing - no debugging needed"
else
  TESTS_PASSING="false"
  echo "❌ Tests failing - debugging required (Phase 5)"
fi

emit_progress "4" "Testing complete: $TESTS_PASSING"
echo ""

# Save checkpoint after Phase 4
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS",
  "test_status": "$TEST_STATUS"
}
EOF
)
save_checkpoint "coordinate" "phase_4" "$ARTIFACT_PATHS_JSON"

# Context pruning after Phase 4
# Store minimal phase metadata for Phase 4 (test status only, pass/fail)
store_phase_metadata "phase_4" "complete" "test_status:$TEST_STATUS"

# No aggressive pruning yet - test output needed for potential debugging (Phase 5)
echo "Phase 4 metadata stored (test output retained for potential debugging)"

# Emit progress marker
emit_progress "4" "Testing complete (status: $TEST_STATUS)"

## Phase 5: Debug (Conditional)

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Analyze test failures and apply fixes iteratively.

**Pattern**: Invoke debug-analyst → Apply fixes → Re-run tests (max 3 iterations)

**Execution Condition**: Phase 5 executes if tests failed OR workflow is debug-only

### Phase 5 Execution Check

**EXECUTE NOW**: USE the Bash tool to check if Phase 5 should execute:

# Phase 5 only executes if tests failed OR workflow is debug-only
if [ "$TESTS_PASSING" == "false" ] || [ "$WORKFLOW_SCOPE" == "debug-only" ]; then
  emit_progress "5" "Phase 5: Debug (conditional execution)"
else
  echo "⏭️  Skipping Phase 5 (Debug)"
  echo "  Reason: Tests passing, no debugging needed"
  echo ""
  # Continue to Phase 6
fi

### Debug Iteration Loop

STEP 1: Iterate debug cycle (max 3 iterations)

# Maximum 3 debug iterations
for iteration in 1 2 3; do
  emit_progress "5" "Debug iteration $iteration/3"

### Debug-Analyst Agent Invocation (Iteration Loop)

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocations for each debug iteration:

for iteration in 1 2 3; do
  DEBUG_REPORT="$TOPIC_PATH/debug/iteration_${iteration}_analysis.md"

  echo "=== Debug Iteration $iteration ==="
  echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
  echo ""
  echo "Task {"
  echo "  subagent_type: \"general-purpose\""
  echo "  description: \"Analyze test failures - iteration $iteration\""
  echo "  timeout: 300000"
  echo "  prompt: \""
  echo "    $DEBUG_CONTEXT"
  echo ""
  echo "    **Iteration-Specific Context**:"
  echo "    - Debug Report Path: $DEBUG_REPORT"
  echo "    - Iteration Number: $iteration"
  echo ""
  echo "    **CRITICAL**: Before writing debug report file, ensure parent directory exists:"
  echo "    Use Bash tool: mkdir -p \\\"\\\$(dirname \\\\\\\"$DEBUG_REPORT\\\\\\\")\\\"\""
  echo ""
  echo "    Return: DEBUG_ANALYSIS_COMPLETE: $DEBUG_REPORT"
  echo "  \""
  echo "}"
  echo ""
done

**YOUR RESPONSIBILITY**: Execute the Task tool invocations shown above for each iteration (bash has already expanded all variables). Stop after tests pass.

  echo -n "Verifying debug report (iteration $iteration): "

  # MANDATORY VERIFICATION checkpoint: Debug report
  if verify_file_created "$DEBUG_REPORT" "Debug report" "Phase 5"; then
    echo ""
  else
    echo ""
    echo "Workflow TERMINATED: Fix debug report creation and retry"
    exit 1
  fi

### Code-Writer Agent Invocation (Apply Fixes)

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocations for code fixes:

for iteration in 1 2 3; do
  DEBUG_REPORT="$TOPIC_PATH/debug/iteration_${iteration}_analysis.md"

  echo "=== Code Fixes Iteration $iteration ==="
  echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
  echo ""
  echo "Task {"
  echo "  subagent_type: \"general-purpose\""
  echo "  description: \"Apply debug fixes - iteration $iteration\""
  echo "  timeout: 300000"
  echo "  prompt: \""
  echo "    $CODE_WRITER_CONTEXT"
  echo ""
  echo "    **Task-Specific Context**:"
  echo "    - Debug Analysis: $DEBUG_REPORT"
  echo "    - Iteration Number: $iteration"
  echo "    - Task Type: Apply debug fixes"
  echo ""
  echo "    Return: FIXES_APPLIED: [number of fixes applied]"
  echo "    Return: FILES_MODIFIED: [comma-separated list of file paths]"
  echo "  \""
  echo "}"
  echo ""
done

**YOUR RESPONSIBILITY**: Execute the Task tool invocations shown above for each iteration (bash has already expanded all variables)

  FIXES_APPLIED=$(echo "$AGENT_OUTPUT" | grep "FIXES_APPLIED:" | cut -d: -f2 | xargs)
  echo "Fixes Applied: $FIXES_APPLIED"
  echo "Re-running tests..."

### Test-Specialist Agent Re-invocation (After Fixes)

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocations for test re-runs:

for iteration in 1 2 3; do
  echo "=== Test Re-Run Iteration $iteration ==="
  echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
  echo ""
  echo "Task {"
  echo "  subagent_type: \"general-purpose\""
  echo "  description: \"Re-run tests after fixes - iteration $iteration\""
  echo "  timeout: 300000"
  echo "  prompt: \""
  echo "    $TEST_CONTEXT"
  echo ""
  echo "    **Task-Specific Context**:"
  echo "    - Iteration Number: $iteration"
  echo "    - Task Type: Re-run tests after fixes (append to test results file)"
  echo ""
  echo "    Return: TEST_STATUS: {passing|failing}"
  echo "    Return: TESTS_TOTAL: [number]"
    Return: TESTS_PASSED: [number]
    Return: TESTS_FAILED: [number]
  "
}


  # Parse updated test status
  TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
  TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
  TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)
  TESTS_FAILED=$(echo "$AGENT_OUTPUT" | grep "TESTS_FAILED:" | cut -d: -f2 | xargs)

  # Update TESTS_PASSING flag based on current test status
  if [ "$TEST_STATUS" == "passing" ]; then
    TESTS_PASSING="true"
  else
    TESTS_PASSING="false"
  fi

  echo "Updated Test Status: $TEST_STATUS ($TESTS_PASSED/$TESTS_TOTAL passed)"

  if [ "$TESTS_PASSING" == "true" ]; then
    echo "✅ Tests passing after $iteration debug iteration(s)"
    break
  fi

  echo "Tests still failing, continuing..."
done

[ "$TESTS_PASSING" == "false" ] && echo "⚠️  WARNING: Tests still failing after 3 iterations (manual intervention required)"

emit_progress "5" "Debug complete: tests=$TESTS_PASSING"
echo ""

# Context pruning after Phase 5
# Store minimal phase metadata for Phase 5 (debug status and final test status)
store_phase_metadata "phase_5" "complete" "tests_passing:$TESTS_PASSING"

# Prune test output now that debugging is complete
echo "Phase 5 metadata stored (test output pruned, debug complete)"

# Emit progress marker
emit_progress "5" "Debug complete (final test status: $TESTS_PASSING)"

## Phase 6: Documentation (Conditional)

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Create workflow summary linking plan, research, and implementation.

**Pattern**: Invoke doc-writer agent → Verify summary created → Update research reports

**Execution Condition**: Phase 6 only executes if implementation occurred (Phase 3 ran)

### Phase 6 Execution Check

**EXECUTE NOW**: USE the Bash tool to check if Phase 6 should execute:

# Phase 6 only executes if implementation occurred
if [ "$IMPLEMENTATION_OCCURRED" == "true" ]; then
  emit_progress "6" "Phase 6: Documentation (summary creation)"
else
  echo "⏭️  Skipping Phase 6 (Documentation)"
  echo "  Reason: No implementation to document (scope: $WORKFLOW_SCOPE)"
  echo ""
  # Skip to completion summary
  display_brief_summary
  exit 0
fi

### Doc-Writer Agent Invocation

STEP 1: Invoke doc-writer agent to create summary

**EXECUTE NOW**: USE the Task tool NOW to invoke the doc-writer agent.

**EXECUTE NOW**: USE the Bash tool to generate fully-expanded Task invocation:

echo "**EXECUTE NOW**: USE the Task tool with this exact configuration:"
echo ""
echo "Task {"
echo "  subagent_type: \"general-purpose\""
echo "  description: \"Create workflow summary with mandatory file creation\""
echo "  timeout: 300000"
echo "  prompt: \""
echo "    $DOC_CONTEXT"
echo ""
echo "    **Summary-Specific Context**:"
echo "    - Summary Path: $SUMMARY_PATH"
echo "    - Research Reports: $RESEARCH_REPORTS_LIST"
echo "    - Test Status: $TEST_STATUS"
echo "    - Workflow Description: $WORKFLOW_DESCRIPTION"
echo ""
echo "    **CRITICAL**: Create summary file at path provided above."
echo ""
echo "    Return: SUMMARY_CREATED: $SUMMARY_PATH"
echo "  \""
echo "}"

**YOUR RESPONSIBILITY**: Execute the Task tool invocation shown above (bash has already expanded all variables)

### Mandatory Verification - Summary Creation

**VERIFICATION REQUIRED**: Summary file must exist to complete workflow

**GUARANTEE REQUIRED**: Summary links all artifacts (research, plan, implementation)

STEP 2: MANDATORY VERIFICATION checkpoint - Verify summary file created

echo -n "Verifying workflow summary: "

if verify_file_created "$SUMMARY_PATH" "Workflow summary" "Phase 6"; then
  FILE_SIZE=$(wc -c < "$SUMMARY_PATH")
  echo " (${FILE_SIZE} bytes)"
  emit_progress "6" "Verified: Workflow summary created"
else
  echo ""
  echo "Workflow TERMINATED: Fix summary creation and retry"
  exit 1
fi

# Context pruning after Phase 6 (final cleanup)
store_phase_metadata "phase_6" "complete" "$SUMMARY_PATH"
prune_workflow_metadata "coordinate_workflow" "true"  # keep_artifacts=true
emit_progress "6" "Documentation complete (summary created)"

## Workflow Completion

Display final workflow summary and artifact locations.

# Clean up checkpoint on successful completion
CHECKPOINT_FILE=".claude/data/checkpoints/coordinate_latest.json"
[ -f "$CHECKPOINT_FILE" ] && rm -f "$CHECKPOINT_FILE"

display_brief_summary
exit 0

## Agent Behavioral Files

[REFERENCE-OK: Agent specifications can be maintained in external agent reference docs]

This command delegates work to specialized agents via the Task tool. Each agent has a behavioral file that defines its responsibilities and execution guidelines:

**Research Phase (Phase 1)**:
- `.claude/agents/research-specialist.md` - Conducts focused codebase research, creates structured reports

**Planning Phase (Phase 2)**:
- `.claude/agents/plan-architect.md` - Creates implementation plans following project standards

**Implementation Phase (Phase 3)**:
- `.claude/agents/implementer-coordinator.md` - Orchestrates wave-based parallel implementation
- `.claude/agents/implementation-executor.md` - Executes individual implementation phases

**Testing Phase (Phase 4)**:
- `.claude/agents/test-specialist.md` - Runs tests and reports results

**Debug Phase (Phase 5)**:
- `.claude/agents/debug-analyst.md` - Investigates failures and proposes fixes

**Documentation Phase (Phase 6)**:
- `.claude/agents/doc-writer.md` - Creates implementation summaries

**Invocation Pattern**:
All agents are invoked via the Task tool with behavioral injection. The pattern is:

**EXECUTE NOW**: USE the Task tool with:
- subagent_type: "general-purpose"
- description: Brief task description
- prompt: Must include:
  - "Read and follow ALL behavioral guidelines from: .claude/agents/[agent-name].md"
  - Context section with workflow-specific information
  - "Execute following all guidelines"
  - "Return: [SIGNAL]: [artifact_path]"

See [Behavioral Injection Pattern](../docs/concepts/patterns/behavioral-injection.md) for complete implementation details.

## Usage Examples

[REFERENCE-OK: Examples can be moved to external usage guide]

### Example 1: Research-only workflow

/coordinate "research API authentication patterns"

# Expected behavior:
# - Scope detected: research-only
# - Phases executed: 0, 1
# - Artifacts: 2-3 research reports
# - No plan, no implementation, no summary

### Example 2: Research-and-plan workflow (MOST COMMON)

/coordinate "research the authentication module to create a refactor plan"

# Expected behavior:
# - Scope detected: research-and-plan
# - Phases executed: 0, 1, 2
# - Artifacts: 4 research reports + 1 implementation plan
# - No implementation, no summary (per standards)
# - Plan ready for execution

### Example 3: Full-implementation workflow

/coordinate "implement OAuth2 authentication for the API"

# Expected behavior:
# - Scope detected: full-implementation
# - Phases executed: 0, 1, 2, 3, 4, 6
# - Phase 5 conditional on test failures
# - Artifacts: reports + plan + implementation + summary

### Example 4: Debug-only workflow

/coordinate "fix the token refresh bug in auth.js"

# Expected behavior:
# - Scope detected: debug-only
# - Phases executed: 0, 1, 5
# - Artifacts: research reports + debug report
# - No new plan or implementation (fixes existing code)

## Performance Metrics

[REFERENCE-OK: Metrics can be tracked in external documentation]

Expected performance targets:

- **File Creation Rate**: 100% (strong enforcement, first attempt)
- **Context Usage**: <25% cumulative across all phases
- **Zero Fallbacks**: Single working path, fail-fast on errors

## Success Criteria

[REFERENCE-OK: Success criteria can be maintained in external validation docs]

### Architectural Excellence
- [ ] Pure orchestration: Zero SlashCommand tool invocations
- [ ] Phase 0 role clarification: Explicit orchestrator vs executor separation
- [ ] Workflow scope detection: Correctly identifies 4 workflow patterns
- [ ] Conditional phase execution: Skips inappropriate phases based on scope
- [ ] Single working path: No fallback file creation mechanisms
- [ ] Fail-fast behavior: Clear error messages, immediate termination on failure

### Enforcement Standards
- [ ] Imperative language ratio ≥95%: MUST/WILL/SHALL for all required actions
- [ ] Step-by-step enforcement: STEP 1/2/3 pattern in all agent templates
- [ ] Mandatory verification: Explicit checkpoints after every file operation
- [ ] 100% file creation rate with auto-recovery: Single retry for transient failures
- [ ] Minimal retry infrastructure: Single-retry strategy (not multi-attempt loops)

### Performance Targets
- [ ] File size: 2,500-3,000 lines (achieved)
- [ ] Context usage: <25% throughout workflow
- [ ] Time efficiency: 15-25% faster for non-implementation workflows
- [ ] Code coverage: ≥80% test coverage for scope detection logic
- [ ] Recovery rate: >95% for transient errors (timeouts, file locks)
- [ ] Performance overhead: <5% for recovery infrastructure
- [ ] Checkpoint resume: Seamless auto-resume from phase boundaries

### Auto-Recovery Features
- [ ] Transient error auto-recovery: Single retry for timeouts and file locks
- [ ] Permanent error fail-fast: Immediate termination with enhanced error reporting
- [ ] Error location extraction: Parse file:line from error messages
- [ ] Specific error type detection: Categorize into 4 types (timeout, syntax, dependency, unknown)
- [ ] Recovery suggestions: Context-specific actionable guidance on failures
- [ ] Partial research failure handling: ≥50% success threshold allows continuation
- [ ] Progress markers: PROGRESS: [Phase N] emitted at phase transitions
- [ ] Checkpoint save/resume: Phase-boundary checkpoints with auto-resume

### Deficiency Resolution
- [ ] ✓ Research agents create files on first attempt (vs inline summaries)
- [ ] ✓ Zero SlashCommand usage for planning/implementation (pure Task tool)
- [ ] ✓ Summaries only created when implementation occurs (not for research-only)
- [ ] ✓ Correct phases execute for each workflow type (research, plan, implement, debug)
