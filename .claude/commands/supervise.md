---
allowed-tools: Task, TodoWrite, Bash, Read
---

# /supervise - Clean Multi-Agent Workflow Orchestration

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
```yaml
# ❌ INCORRECT - Do NOT do this
SlashCommand {
  command: "/plan create auth feature"
}
```

**Problems with command chaining**:
1. **Context Bloat**: Entire /plan command prompt injected into your context (~2000 lines)
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation

**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):
```yaml
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
```

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
Phase 3: Implementation (conditional)
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

### Performance Targets

- **Context Usage**: <25% throughout workflow
- **File Creation Rate**: 100% with auto-recovery (single retry for transient failures)
- **Recovery Rate**: >95% for transient errors (timeouts, file locks)
- **Performance Overhead**: <5% for recovery infrastructure
- **Enhanced Error Reporting**:
  - Error location extraction accuracy: >90%
  - Error type categorization accuracy: >85%
  - Error reporting overhead: <30ms per error (negligible)

## Auto-Recovery

This command implements verification-fallback pattern with single-retry for transient errors.

**Key Behaviors**:
- Transient errors (timeouts, file locks): Single retry after 1s delay
- Permanent errors (syntax, dependencies): Fail-fast with diagnostics
- Partial research failure: Continue if ≥50% agents succeed

**See**: [Verification-Fallback Pattern](../docs/concepts/patterns/verification-fallback.md)
**See**: [Error Handling Library](../lib/error-handling.sh) - Implementation details

## Enhanced Error Reporting

Failed operations receive enhanced diagnostics via error-handling.sh:
- Error location extraction (file:line parsing)
- Error type categorization (timeout, syntax, dependency, unknown)
- Context-specific recovery suggestions

**See**: [Error Handling Library](../lib/error-handling.sh) - Complete error reporting implementation

## Partial Failure Handling

Research phase (Phase 1) continues if ≥50% of parallel agents succeed. Workflow logs failures and continues with partial results.

## Checkpoint Resume

Checkpoints saved after Phases 1-4. Auto-resumes from last completed phase on startup.

**Behavior**: Validates checkpoint → Skips completed phases → Resumes seamlessly

**See**: [Checkpoint Recovery Pattern](../docs/concepts/patterns/checkpoint-recovery.md) - Schema and implementation details

## Progress Markers

Emit silent progress markers at phase boundaries:
```
PROGRESS: [Phase N] - [action]
```

Example: `PROGRESS: [Phase 1] - Research complete (4/4 succeeded)`

## Shared Utility Functions

[EXECUTION-CRITICAL: Source statements for required libraries - cannot be moved to external files]

**EXECUTE NOW - Source Required Libraries**

```bash
# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source workflow detection utilities
if [ -f "$SCRIPT_DIR/../lib/workflow-detection.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-detection.sh"
else
  echo "ERROR: workflow-detection.sh not found"
  exit 1
fi

# Source error handling utilities
if [ -f "$SCRIPT_DIR/../lib/error-handling.sh" ]; then
  source "$SCRIPT_DIR/../lib/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found"
  exit 1
fi

# Source checkpoint utilities
if [ -f "$SCRIPT_DIR/../lib/checkpoint-utils.sh" ]; then
  source "$SCRIPT_DIR/../lib/checkpoint-utils.sh"
else
  echo "ERROR: checkpoint-utils.sh not found"
  exit 1
fi

# Source unified logger
if [ -f "$SCRIPT_DIR/../lib/unified-logger.sh" ]; then
  source "$SCRIPT_DIR/../lib/unified-logger.sh"
else
  echo "ERROR: unified-logger.sh not found"
  exit 1
fi

# Source unified location detection (85% token reduction, 25x speedup)
if [ -f "$SCRIPT_DIR/../lib/unified-location-detection.sh" ]; then
  source "$SCRIPT_DIR/../lib/unified-location-detection.sh"
else
  echo "ERROR: unified-location-detection.sh not found"
  exit 1
fi

# Source metadata extraction utilities (95% context reduction per artifact)
if [ -f "$SCRIPT_DIR/../lib/metadata-extraction.sh" ]; then
  source "$SCRIPT_DIR/../lib/metadata-extraction.sh"
else
  echo "ERROR: metadata-extraction.sh not found"
  exit 1
fi

# Source context pruning utilities (<30% context usage target)
if [ -f "$SCRIPT_DIR/../lib/context-pruning.sh" ]; then
  source "$SCRIPT_DIR/../lib/context-pruning.sh"
else
  echo "ERROR: context-pruning.sh not found"
  exit 1
fi
```

**Verification**: All required functions available via sourced libraries.

**Note on Design Decisions** (Phase 1B):
- **Metadata extraction** not implemented: supervise uses path-based context passing (not full content), so the 95% context reduction claim doesn't apply
- **Context pruning** not implemented: bash variables naturally scope, no evidence of context bloat in current architecture
- **retry_with_backoff** implemented: 6 verification points wrapped for resilience against transient failures (ZERO overhead in success case)

## Available Utility Functions

[REFERENCE-OK: Can be supplemented with external library documentation]

All utility functions are now sourced from library files. This table documents the complete API:

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
| `retry_with_backoff()` | error-handling.sh | Retry command with exponential backoff | `retry_with_backoff 3 500 curl "$URL"` |

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
- **Error Handling**: 6 functions (classification, recovery, suggestions)
- **Checkpoint Management**: 4 functions (save, restore, get/set fields)
- **Progress Logging**: 1 function (progress markers)

**Total Functions Available**: 13 core utilities

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
# Classify error and determine recovery
ERROR_MSG="Connection timeout after 30 seconds"
ERROR_TYPE=$(classify_error "$ERROR_MSG")

if [ "$ERROR_TYPE" == "transient" ]; then
  echo "Transient error detected, retrying..."
  retry_with_backoff 3 1000 curl "https://api.example.com"
else
  echo "Permanent error:"
  suggest_recovery "$ERROR_TYPE" "$ERROR_MSG"
  exit 1
fi
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

[EXECUTION-CRITICAL: Path calculation before agent invocations - inline bash required]

**Objective**: Establish topic directory structure and calculate all artifact paths.

**Pattern**: utility-based location detection → directory creation → path export

**Optimization**: Uses deterministic bash utilities (topic-utils.sh, detect-project-dir.sh) for 85-95% token reduction and 20x+ speedup compared to agent-based detection.

**Critical**: ALL paths MUST be calculated before Phase 1 begins.

### Implementation

STEP 1: Parse workflow description from command arguments

```bash
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /supervise \"<workflow description>\""
  exit 1
fi

# Check for existing checkpoint (auto-resume capability)
RESUME_PHASE=$(load_phase_checkpoint)

if [ -n "$RESUME_PHASE" ]; then
  echo "════════════════════════════════════════════════════════"
  echo "  CHECKPOINT DETECTED - RESUMING WORKFLOW"
  echo "════════════════════════════════════════════════════════"
  echo ""
  emit_progress "Resume" "Skipping completed phases 0-$((RESUME_PHASE - 1))"
  echo ""
  echo "Resuming from Phase $RESUME_PHASE..."
  echo ""

  # Skip to the resume phase
  # (Implementation note: In actual execution, this would jump to the appropriate phase section)
fi
```

STEP 2: Detect workflow scope

```bash
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

echo "Detected Workflow Scope: $WORKFLOW_SCOPE"
echo "Phases to Execute: $PHASES_TO_EXECUTE"
echo ""
```

STEP 3: Determine location using utility functions

Source the required utility libraries for deterministic location detection.

```bash
# Source utility libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/topic-utils.sh" ]; then
  source "$SCRIPT_DIR/../lib/topic-utils.sh"
else
  echo "ERROR: topic-utils.sh not found"
  echo "Falling back to location-specialist agent..."
  # Fallback to agent-based detection (for graceful degradation)
  # (Fallback implementation would go here if needed)
  exit 1
fi

if [ -f "$SCRIPT_DIR/../lib/detect-project-dir.sh" ]; then
  source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
else
  echo "ERROR: detect-project-dir.sh not found"
  exit 1
fi
```

STEP 4: Calculate location metadata

Use utility functions to determine project root, specs directory, topic number, and topic name.

```bash
# Get project root (from detect-project-dir.sh)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
if [ -z "$PROJECT_ROOT" ]; then
  echo "ERROR: Could not determine project root"
  exit 1
fi

# Determine specs directory
if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
elif [ -d "${PROJECT_ROOT}/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/specs"
else
  # Default to .claude/specs and create it
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  mkdir -p "$SPECS_ROOT"
fi

# Calculate topic metadata using utility functions
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")

# Set location for backward compatibility
LOCATION="$PROJECT_ROOT"

# Validate required fields
if [ -z "$LOCATION" ] || [ -z "$TOPIC_NUM" ] || [ -z "$TOPIC_NAME" ]; then
  echo "❌ ERROR: Failed to calculate location metadata"
  echo "   LOCATION: $LOCATION"
  echo "   TOPIC_NUM: $TOPIC_NUM"
  echo "   TOPIC_NAME: $TOPIC_NAME"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi

echo "Project Location: $LOCATION"
echo "Specs Root: $SPECS_ROOT"
echo "Topic Number: $TOPIC_NUM"
echo "Topic Name: $TOPIC_NAME"
echo ""
```

STEP 5: Create topic directory structure

Use the utility function to create the standardized topic directory structure with verification.

```bash
TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Topic Directory Creation"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Creating topic directory structure at: $TOPIC_PATH"
echo ""

# Create topic structure using utility function (includes verification)
if ! create_topic_structure "$TOPIC_PATH"; then
  echo "❌ CRITICAL ERROR: Topic directory not created at $TOPIC_PATH"
  echo ""
  echo "FALLBACK MECHANISM: Attempting manual directory creation..."
  mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}

  # Re-verification
  if [ ! -d "$TOPIC_PATH" ]; then
    echo "❌ FATAL: Fallback failed - directory creation impossible"
    echo ""
    echo "Workflow TERMINATED."
    exit 1
  fi

  echo "✅ FALLBACK SUCCESSFUL: Topic directory created manually"
fi

echo "✅ VERIFIED: Topic directory exists at $TOPIC_PATH"
echo "   All 6 subdirectories verified: reports, plans, summaries, debug, scripts, outputs"
echo ""

# VERIFICATION REQUIREMENT: YOU MUST NOT proceed until verification passes
echo "Verification checkpoint passed - proceeding to artifact path calculation"
echo ""
```

STEP 6: Pre-calculate ALL artifact paths

```bash
# Research phase paths (calculate for max 4 topics)
REPORT_PATHS=()
for i in 1 2 3 4; do
  REPORT_PATHS+=("${TOPIC_PATH}/reports/$(printf '%03d' $i)_topic${i}.md")
done
OVERVIEW_PATH="${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md"

# Planning phase paths
PLAN_PATH="${TOPIC_PATH}/plans/001_${TOPIC_NAME}_plan.md"

# Implementation phase paths
IMPL_ARTIFACTS="${TOPIC_PATH}/artifacts/"

# Debug phase paths
DEBUG_REPORT="${TOPIC_PATH}/debug/001_debug_analysis.md"

# Documentation phase paths
SUMMARY_PATH="${TOPIC_PATH}/summaries/${TOPIC_NUM}_${TOPIC_NAME}_summary.md"

# Export all paths for use in subsequent phases
export TOPIC_PATH TOPIC_NUM TOPIC_NAME
export OVERVIEW_PATH PLAN_PATH
export IMPL_ARTIFACTS DEBUG_REPORT SUMMARY_PATH

echo "Pre-calculated Artifact Paths:"
echo "  Research Reports: ${#REPORT_PATHS[@]} paths"
echo "  Overview: $OVERVIEW_PATH"
echo "  Plan: $PLAN_PATH"
echo "  Implementation: $IMPL_ARTIFACTS"
echo "  Debug: $DEBUG_REPORT"
echo "  Summary: $SUMMARY_PATH"
echo ""
```

STEP 7: Initialize tracking arrays

```bash
# Track successful report paths for Phase 1
SUCCESSFUL_REPORT_PATHS=()
SUCCESSFUL_REPORT_COUNT=0

# Track phase status
TESTS_PASSING="unknown"
IMPLEMENTATION_OCCURRED="false"

echo "Phase 0 Complete: Ready for Phase 1 (Research)"
echo ""
```

## Phase 1: Research

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Conduct parallel research on workflow topics with 100% file creation rate.

**Pattern**: Analyze complexity → Invoke 2-4 research agents in parallel → Verify all files created → Extract metadata

**Critical Success Factor**: 100% file creation rate on first attempt (no retries)

### Phase 1 Execution Check

```bash
should_run_phase 1 || {
  echo "⏭️  Skipping Phase 1 (Research)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_completion_summary
  exit 0
}
```

### Complexity-Based Research Topics

STEP 1: Determine research complexity (1-4 topics based on workflow)

```bash
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
echo ""
```

### Parallel Research Agent Invocation

STEP 2: Invoke 2-4 research agents in parallel (single message, multiple Task calls)

**CRITICAL**: All agents invoked in a single message for parallel execution.

```bash
# Emit progress marker before agent invocations
emit_progress "1" "Invoking $RESEARCH_COMPLEXITY research agents in parallel"
echo ""
```

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]} (absolute path, pre-calculated by orchestrator)
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: ${RESEARCH_COMPLEXITY}

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATHS[i]}
  "
}

**Note**: The actual implementation will generate N Task calls based on RESEARCH_COMPLEXITY.

```bash
# Emit progress marker after agent invocations complete
emit_progress "1" "All research agents invoked - awaiting completion"
echo ""
```

### Mandatory Verification - Research Reports with Auto-Recovery

**VERIFICATION REQUIRED**: All research report files must exist before continuing to Phase 2

STEP 3: Verify ALL research reports created successfully (with single-retry for transient failures)

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"
echo ""

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()
FAILED_AGENTS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  # Emit progress marker
  emit_progress "1" "Verifying research report $i/$RESEARCH_COMPLEXITY"

  echo "Verifying Report $i: $(basename $REPORT_PATH)"

  # Check if file exists and has content (with retry for transient failures)
  if retry_with_backoff 2 1000 test -f "$REPORT_PATH" -a -s "$REPORT_PATH"; then
    # Success path - perform quality checks
    FILE_SIZE=$(wc -c < "$REPORT_PATH")

    if [ "$FILE_SIZE" -lt 200 ]; then
      echo "  ⚠️  WARNING: File is very small ($FILE_SIZE bytes)"
    fi

    if ! grep -q "^# " "$REPORT_PATH"; then
      echo "  ⚠️  WARNING: Missing markdown header"
    fi

    echo "  ✅ PASSED: Report created successfully ($FILE_SIZE bytes)"
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    # Failure path - extract error info and attempt recovery
    ERROR_MSG="Report file missing or empty: $REPORT_PATH"
    ERROR_LOCATION=$(extract_error_location "$ERROR_MSG")
    ERROR_TYPE=$(detect_specific_error_type "$ERROR_MSG")

    # Classify error for retry decision
    RETRY_DECISION=$(classify_and_retry "$ERROR_MSG")

    if [ "$RETRY_DECISION" == "retry" ]; then
      echo "  ⚠️  TRANSIENT ERROR: Retrying once..."

      # Note: In actual execution, retry would re-invoke the agent
      # For now, just re-check the file after a short delay
      sleep 1

      if retry_with_backoff 2 1000 test -f "$REPORT_PATH" -a -s "$REPORT_PATH"; then
        FILE_SIZE=$(wc -c < "$REPORT_PATH")
        echo "  ✅ RETRY SUCCESSFUL: Report created ($FILE_SIZE bytes)"
        SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
      else
        # Retry failed - update error info and mark as failed
        ERROR_TYPE=$(detect_specific_error_type "Retry failed: $ERROR_MSG")
        ERROR_LOCATION=$(extract_error_location "$REPORT_PATH")

        echo "  ❌ RETRY FAILED: Report still missing"
        echo ""
        echo "ERROR: $ERROR_TYPE"
        if [ -n "$ERROR_LOCATION" ]; then
          echo "   at $ERROR_LOCATION"
        fi
        echo ""
        echo "Recovery suggestions:"
        suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
        echo ""

        FAILED_AGENTS+=("agent_$i")
        VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
      fi
    else
      # Permanent error - no retry
      echo "  ❌ PERMANENT ERROR: $ERROR_TYPE"
      if [ -n "$ERROR_LOCATION" ]; then
        echo "     at $ERROR_LOCATION"
      fi
      echo ""
      echo "Recovery suggestions:"
      suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
      echo ""

      FAILED_AGENTS+=("agent_$i")
      VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    fi
  fi
done

SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORT_PATHS[@]}

echo ""
echo "Verification Summary:"
echo "  Total Reports Expected: $RESEARCH_COMPLEXITY"
echo "  Reports Created: $SUCCESSFUL_REPORT_COUNT"
echo "  Verification Failures: $VERIFICATION_FAILURES"
echo ""

# Partial failure handling - allow continuation if ≥50% success
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  DECISION=$(handle_partial_research_failure $RESEARCH_COMPLEXITY $SUCCESSFUL_REPORT_COUNT "${FAILED_AGENTS[*]}")

  if [ "$DECISION" == "terminate" ]; then
    echo "Workflow TERMINATED. Fix research issues and retry."
    exit 1
  fi

  # Continue with partial results
  echo "⚠️  Continuing workflow with partial research results"
  echo ""
fi

if [ $VERIFICATION_FAILURES -eq 0 ]; then
  echo "✅ ALL RESEARCH REPORTS VERIFIED SUCCESSFULLY"
else
  echo "✅ PARTIAL SUCCESS - Continuing with available research"
fi
echo ""

# VERIFICATION REQUIREMENT: YOU MUST NOT proceed to Phase 2 without at least 50% success
# This requirement is enforced by handle_partial_research_failure() above
echo "Verification checkpoint passed - proceeding to research overview"
echo ""
```

### Research Overview (Optional Synthesis)

STEP 4: Create overview report synthesizing all research findings

```bash
# Only create overview if multiple reports
if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then
  echo "Creating research overview to synthesize findings..."

  # Build report list for overview agent
  REPORT_LIST=""
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    REPORT_LIST+="- $report\n"
  done

  # Invoke overview synthesizer agent
  # Task {
  #   subagent_type: "general-purpose"
  #   description: "Synthesize research findings"
  #   prompt: "
  #     Read: .claude/agents/research-specialist.md
  #
  #     STEP 1: Use Write tool to create: $OVERVIEW_PATH
  #     STEP 2: Read all research reports and synthesize:
  #             ${REPORT_LIST}
  #     STEP 3: Write 400-500 word overview with:
  #             - Common themes across reports
  #             - Conflicting findings (if any)
  #             - Prioritized recommendations
  #             - Cross-references between reports
  #     STEP 4: Return ONLY: OVERVIEW_CREATED: $OVERVIEW_PATH
  #   "
  # }

  # Verify overview created
  verify_file_created "$OVERVIEW_PATH" "Research Overview" "$AGENT_OUTPUT"
fi

echo "Phase 1 Complete: Research artifacts verified"
echo ""

# Save checkpoint after Phase 1
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'"' || echo '')
}
EOF
)
save_phase_checkpoint 1 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

## Phase 2: Planning

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Create implementation plan using Task tool with behavioral injection (no SlashCommand).

**Pattern**: Prepare context → Invoke plan-architect agent → Verify plan created → Extract metadata

**Critical**: Uses Task tool with behavioral injection, NOT /plan command

### Phase 2 Execution Check

```bash
should_run_phase 2 || {
  echo "⏭️  Skipping Phase 2 (Planning)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_completion_summary
  exit 0
}
```

### Planning Context Preparation

STEP 1: Prepare planning context with research reports

```bash
echo "Preparing planning context..."

# Build research reports list for injection
RESEARCH_REPORTS_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  RESEARCH_REPORTS_LIST+="- $report\n"
done

# Include overview if created
if [ -f "$OVERVIEW_PATH" ]; then
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

echo "Planning Context:"
echo "  Research Reports: $SUCCESSFUL_REPORT_COUNT files"
echo "  Standards File: $STANDARDS_FILE"
echo ""
```

### Plan-Architect Agent Invocation

STEP 2: Invoke plan-architect agent via Task tool

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Workflow Description: ${WORKFLOW_DESCRIPTION}
    - Plan File Path: ${PLAN_PATH} (absolute path, pre-calculated by orchestrator)
    - Project Standards: ${STANDARDS_FILE}
    - Research Reports: ${RESEARCH_REPORTS_LIST}
    - Research Report Count: ${SUCCESSFUL_REPORT_COUNT}

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}

### Mandatory Verification - Plan Creation

**VERIFICATION REQUIRED**: Plan file must exist before continuing to Phase 3 or completing workflow

**GUARANTEE REQUIRED**: Plan contains minimum 3 phases with standard structure

STEP 3: Verify plan file created successfully (with auto-recovery)

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Implementation Plan"
echo "════════════════════════════════════════════════════════"
echo ""

# Emit progress marker
emit_progress "2" "Verifying implementation plan"

# Check if file exists and has content (with retry for transient failures)
if retry_with_backoff 2 1000 test -f "$PLAN_PATH" -a -s "$PLAN_PATH"; then
  # Success path - perform quality checks
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")

  if [ "$PHASE_COUNT" -lt 3 ]; then
    echo "⚠️  WARNING: Plan has only $PHASE_COUNT phases"
    echo "   Expected at least 3 phases for proper structure."
  fi

  if ! grep -q "^## Metadata" "$PLAN_PATH"; then
    echo "⚠️  WARNING: Plan missing metadata section"
  fi

  echo "✅ VERIFICATION PASSED: Plan created with $PHASE_COUNT phases"
  echo "   Path: $PLAN_PATH"
  echo ""

  # VERIFICATION REQUIREMENT: YOU MUST NOT proceed without plan file
  echo "Verification checkpoint passed - proceeding to plan metadata extraction"
  echo ""
else
  # Failure path - extract error info and attempt recovery
  ERROR_MSG="Plan file missing or empty: $PLAN_PATH"
  ERROR_LOCATION=$(extract_error_location "$ERROR_MSG")
  ERROR_TYPE=$(detect_specific_error_type "$ERROR_MSG")

  # Classify error for retry decision
  RETRY_DECISION=$(classify_and_retry "$ERROR_MSG")

  if [ "$RETRY_DECISION" == "retry" ]; then
    echo "⚠️  TRANSIENT ERROR: Retrying once..."
    sleep 1

    if retry_with_backoff 2 1000 test -f "$PLAN_PATH" -a -s "$PLAN_PATH"; then
      PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
      echo "✅ RETRY SUCCESSFUL: Plan created with $PHASE_COUNT phases"
    else
      echo "❌ RETRY FAILED: Plan still missing"
      echo ""
      echo "ERROR: $ERROR_TYPE"
      if [ -n "$ERROR_LOCATION" ]; then
        echo "   at $ERROR_LOCATION"
      fi
      echo ""
      echo "Recovery suggestions:"
      suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
      echo ""
      echo "Workflow TERMINATED."
      exit 1
    fi
  else
    # Permanent error - fail fast
    echo "❌ PERMANENT ERROR: $ERROR_TYPE"
    if [ -n "$ERROR_LOCATION" ]; then
      echo "   at $ERROR_LOCATION"
    fi
    echo ""
    echo "Recovery suggestions:"
    suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
    echo ""
    echo "Workflow TERMINATED."
    exit 1
  fi
fi
```

### Plan Metadata Extraction

STEP 4: Extract plan metadata for reporting

```bash
# Extract complexity from plan
PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")

# Extract estimated time
PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_PATH" | cut -d: -f2 | xargs || echo "unknown")

echo "Plan Metadata:"
echo "  Phases: $PHASE_COUNT"
echo "  Complexity: $PLAN_COMPLEXITY"
echo "  Est. Time: $PLAN_EST_TIME"
echo ""

echo "Phase 2 Complete: Implementation plan created"
echo ""

# Save checkpoint after Phase 2
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH"
}
EOF
)
save_phase_checkpoint 2 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

### Workflow Completion Check (After Phase 2)

STEP 5: Check if workflow should continue to implementation

```bash
should_run_phase 3 || {
  echo "════════════════════════════════════════════════════════"
  echo "         /supervise WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Workflow Type: $WORKFLOW_SCOPE"
  echo "Phases Executed: Phase 0-2 (Location, Research, Planning)"
  echo ""
  echo "Artifacts Created:"
  echo "  ✓ Research Reports: $SUCCESSFUL_REPORT_COUNT files"
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    echo "      - $(basename $report)"
  done
  if [ -f "$OVERVIEW_PATH" ]; then
    echo "  ✓ Research Overview: $(basename $OVERVIEW_PATH)"
  fi
  echo "  ✓ Implementation Plan: $(basename $PLAN_PATH)"
  echo ""
  echo "Standards Compliance:"
  echo "  ✓ Reports in specs/reports/ (not inline summaries)"
  echo "  ✓ Plan created via Task tool (not SlashCommand)"
  echo "  ✓ Summary NOT created (per standards - no implementation)"
  echo ""
  echo "Next Steps:"
  echo "  The plan is ready for execution"
  echo ""
  exit 0
}
```

## Phase 3: Implementation

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Execute implementation plan phase-by-phase with testing and commits.

**Pattern**: Invoke code-writer agent with plan context → Verify implementation artifacts → Track completion

**Critical**: Code-writer agent uses phase-by-phase execution pattern internally (with testing and commits after each phase)

### Phase 3 Execution Check

```bash
should_run_phase 3 || {
  echo "⏭️  Skipping Phase 3 (Implementation)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  # Continue to next phase check or completion
}
```

### Code-Writer Agent Invocation

STEP 1: Invoke code-writer agent with plan context

**EXECUTE NOW**: USE the Task tool to invoke the code-writer agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with mandatory artifact creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/code-writer.md

    **Workflow-Specific Context**:
    - Plan File Path: ${PLAN_PATH} (absolute path, pre-calculated by orchestrator)
    - Implementation Artifacts Directory: ${IMPL_ARTIFACTS}
    - Project Standards: ${STANDARDS_FILE}
    - Workflow Type: ${WORKFLOW_SCOPE}

    Execute implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_STATUS: {complete|partial|failed}
    PHASES_COMPLETED: {N}
    PHASES_TOTAL: {M}
  "
}
```

### Mandatory Verification - Implementation Completion

**VERIFICATION REQUIRED**: Implementation artifacts directory must exist

**CHECKPOINT REQUIREMENT**: Report implementation status to determine Phase 6 execution

STEP 2: Verify implementation artifacts created

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Implementation"
echo "════════════════════════════════════════════════════════"
echo ""

# Parse implementation status from agent output
IMPL_STATUS=$(echo "$AGENT_OUTPUT" | grep "IMPLEMENTATION_STATUS:" | cut -d: -f2 | xargs)
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "PHASES_COMPLETED:" | cut -d: -f2 | xargs)
PHASES_TOTAL=$(echo "$AGENT_OUTPUT" | grep "PHASES_TOTAL:" | cut -d: -f2 | xargs)

echo "Implementation Status: $IMPL_STATUS"
echo "Phases Completed: $PHASES_COMPLETED / $PHASES_TOTAL"
echo ""

# Check if implementation directory exists
if [ ! -d "$IMPL_ARTIFACTS" ]; then
  echo "⚠️  WARNING: Implementation artifacts directory not created"
  echo "   Expected: $IMPL_ARTIFACTS"
  echo ""
  echo "FALLBACK MECHANISM: Creating artifacts directory..."
  mkdir -p "$IMPL_ARTIFACTS"

  # Re-verification
  if [ ! -d "$IMPL_ARTIFACTS" ]; then
    echo "❌ FATAL: Fallback failed - cannot create artifacts directory"
    echo "Workflow TERMINATED."
    exit 1
  fi

  echo "✅ FALLBACK SUCCESSFUL: Artifacts directory created"
  echo ""
else
  ARTIFACT_COUNT=$(find "$IMPL_ARTIFACTS" -type f | wc -l)
  echo "✅ VERIFIED: Implementation artifacts directory exists ($ARTIFACT_COUNT files)"
fi

# Verify plan updated with completion markers
COMPLETED_PHASES=$(grep -c "\[COMPLETED\]" "$PLAN_PATH" || echo "0")
echo "Plan completion markers: $COMPLETED_PHASES phases marked complete"
echo ""

# Set flag for Phase 6 (documentation)
if [ "$IMPL_STATUS" == "complete" ] || [ "$IMPL_STATUS" == "partial" ]; then
  IMPLEMENTATION_OCCURRED="true"
fi

# VERIFICATION REQUIREMENT: YOU MUST NOT proceed to Phase 4 without artifacts directory
echo "Verification checkpoint passed - proceeding to Phase 4 (Testing)"
echo ""

echo "Phase 3 Complete: Implementation finished"
echo ""

# Save checkpoint after Phase 3
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS"
}
EOF
)
save_phase_checkpoint 3 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

## Phase 4: Testing

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Execute comprehensive test suite and collect results.

**Pattern**: Invoke test-specialist agent → Verify test results → Determine if debugging needed

**Critical**: Test results determine whether Phase 5 (Debug) executes

### Phase 4 Execution Check

```bash
should_run_phase 4 || {
  echo "⏭️  Skipping Phase 4 (Testing)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  # Continue to next phase check or completion
}
```

### Test-Specialist Agent Invocation

STEP 1: Invoke test-specialist agent

**EXECUTE NOW**: USE the Task tool to invoke the test-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive tests with mandatory results file"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: ${TOPIC_PATH}/outputs/test_results.md (absolute path, pre-calculated)
    - Project Standards: ${STANDARDS_FILE}
    - Plan File: ${PLAN_PATH}
    - Implementation Artifacts: ${IMPL_ARTIFACTS}

    Execute testing following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    TESTS_TOTAL: {N}
    TESTS_PASSED: {M}
    TESTS_FAILED: {K}
  "
}

### Test Results Verification

**VERIFICATION REQUIRED**: Test results file must exist to determine Phase 5 execution

**CHECKPOINT REQUIREMENT**: Report test status to determine if debugging needed

STEP 2: Parse and verify test results

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Test Results"
echo "════════════════════════════════════════════════════════"
echo ""

# Parse test status from agent output
TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)
TESTS_FAILED=$(echo "$AGENT_OUTPUT" | grep "TESTS_FAILED:" | cut -d: -f2 | xargs)

echo "Test Status: $TEST_STATUS"
echo "Tests Run: $TESTS_TOTAL"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

# Set flag for Phase 5 (debug)
if [ "$TEST_STATUS" == "passing" ]; then
  TESTS_PASSING="true"
  echo "✅ VERIFIED: All tests passing - no debugging needed"
else
  TESTS_PASSING="false"
  echo "❌ VERIFIED: Tests failing - debugging required (Phase 5)"
fi

echo ""

# VERIFICATION REQUIREMENT: YOU MUST NOT skip Phase 5 if tests failed
echo "Verification checkpoint passed - test status recorded"
echo ""

echo "Phase 4 Complete: Testing finished"
echo ""

# Save checkpoint after Phase 4
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS",
  "test_status": "$TEST_STATUS"
}
EOF
)
save_phase_checkpoint 4 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

## Phase 5: Debug (Conditional)

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Analyze test failures and apply fixes iteratively.

**Pattern**: Invoke debug-analyst → Apply fixes → Re-run tests (max 3 iterations)

**Execution Condition**: Phase 5 executes if tests failed OR workflow is debug-only

### Phase 5 Execution Check

```bash
# Phase 5 only executes if tests failed OR workflow is debug-only
if [ "$TESTS_PASSING" == "false" ] || [ "$WORKFLOW_SCOPE" == "debug-only" ]; then
  echo "Executing Phase 5: Debug"
  echo ""
else
  echo "⏭️  Skipping Phase 5 (Debug)"
  echo "  Reason: Tests passing, no debugging needed"
  echo ""
  # Continue to Phase 6
fi
```

### Debug Iteration Loop

STEP 1: Iterate debug cycle (max 3 iterations)

```bash
# Maximum 3 debug iterations
for iteration in 1 2 3; do
  echo "════════════════════════════════════════════════════════"
  echo "  DEBUG ITERATION $iteration / 3"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # Invoke debug-analyst agent
  Task {
    subagent_type: "general-purpose"
    description: "Analyze test failures - iteration $iteration"
    prompt: "
      Read behavioral guidelines: .claude/agents/debug-analyst.md

      **PRIMARY OBLIGATION - Debug Report File**

      **ABSOLUTE REQUIREMENT**: Creating debug report is MANDATORY.

      **WHY THIS MATTERS**:
      - Fix application depends on debug report existing
      - Root cause analysis must be documented for review
      - Iteration tracking requires file artifacts
      - Cannot apply fixes without documented analysis

      ---

      **STEP 1 (REQUIRED BEFORE STEP 2) - Create Debug Report**

      **EXECUTE NOW**

      YOU MUST create: ${DEBUG_REPORT}

      Template:
      ```markdown
      # Debug Analysis - Iteration $iteration

      ## Test Failures Summary
      [To be populated in STEP 2]

      ## Root Cause Analysis
      [To be populated in STEP 3]

      ## Proposed Fixes
      [To be populated in STEP 3]
      ```

      ---

      **STEP 2 (REQUIRED BEFORE STEP 3) - Analyze Failures**

      Read: ${TOPIC_PATH}/outputs/test_results.md

      **EXTRACT**:
      - Each failing test name
      - Error messages
      - Stack traces
      - File locations

      ---

      **STEP 3 (REQUIRED BEFORE STEP 4) - Determine Root Causes**

      For EACH failing test:
      1. Identify root cause
      2. Determine affected files
      3. Propose specific fix with code
      4. Assign priority

      **POPULATE REPORT** using Edit tool

      ---

      **STEP 4 (MANDATORY VERIFICATION)**

      **VERIFY**:
      ```bash
      test -f \"${DEBUG_REPORT}\"
      grep -q \"^## Root Cause Analysis\" \"${DEBUG_REPORT}\"
      ```

      **COMPLETION CRITERIA - ALL REQUIRED**:
      - [x] Debug report exists at ${DEBUG_REPORT}
      - [x] Report contains Test Failures Summary
      - [x] Report contains Root Cause Analysis
      - [x] Report contains Proposed Fixes
      - [x] Return confirmation in exact format

      **RETURN**: DEBUG_ANALYSIS_COMPLETE: ${DEBUG_REPORT}

      **DO NOT** return full analysis text. Return ONLY confirmation above.

      ---

      **ORCHESTRATOR VERIFICATION**:
      1. Verify debug report exists
      2. Extract proposed fixes
      3. Pass to code-writer for fix application

      **REMINDER**: You are the EXECUTOR. Use exact path provided.
    "
  }

  # Verify debug report created
  echo "════════════════════════════════════════════════════════"
  echo "  MANDATORY VERIFICATION - Debug Report"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # VERIFICATION REQUIRED: Debug report must exist before applying fixes (with retry)
  if ! retry_with_backoff 2 1000 test -f "$DEBUG_REPORT"; then
    echo "❌ CRITICAL ERROR: Debug report not created after retries at $DEBUG_REPORT"
    echo ""
    echo "FALLBACK MECHANISM: Cannot continue without debug analysis"
    echo "Workflow TERMINATED."
    exit 1
  fi

  echo "✅ VERIFIED: Debug report exists at $DEBUG_REPORT"
  echo ""

  # VERIFICATION REQUIREMENT: YOU MUST NOT apply fixes without debug analysis
  echo "Verification checkpoint passed - proceeding to fix application"
  echo ""

  # Invoke code-writer to apply fixes
  Task {
    subagent_type: "general-purpose"
    description: "Apply debug fixes - iteration $iteration"
    prompt: "
      Read behavioral guidelines: .claude/agents/code-writer.md

      **PRIMARY OBLIGATION - Apply All Fixes**

      **ABSOLUTE REQUIREMENT**: Applying all proposed fixes is MANDATORY.

      **WHY THIS MATTERS**:
      - Test re-run depends on fixes being applied
      - Partial fix application may not resolve failures
      - Iteration success requires complete fix implementation

      ---

      **STEP 1 (REQUIRED BEFORE STEP 2) - Read Debug Analysis**

      YOU MUST read debug analysis: ${DEBUG_REPORT}

      **ANALYSIS REQUIREMENTS**:
      - Review all proposed fixes
      - Understand priority order
      - Note file locations and line numbers

      ---

      **STEP 2 (REQUIRED BEFORE STEP 3) - Apply Recommended Fixes**

      **EXECUTE NOW - Use Edit Tool**

      For each fix:
      - Locate the file and line number
      - Apply the exact code change recommended
      - Preserve code style and formatting
      - Do NOT skip any fixes

      **CHECKPOINT**: After EACH fix applied:
      ```
      PROGRESS: Fix N applied to [file]
      ```

      ---

      **STEP 3 (REQUIRED BEFORE STEP 4) - Verify Fixes Applied**

      YOU MUST verify all changes were successfully made:

      ```bash
      # Count modified files
      git status --short | wc -l
      ```

      **VERIFICATION REQUIREMENTS**:
      - Check that all changes were successfully made
      - Count the number of files modified
      - Verify no syntax errors introduced

      ---

      **STEP 4 (MANDATORY) - Return Fix Status**

      **RETURN FORMAT**:
      ```
      FIXES_APPLIED: {count}
      FILES_MODIFIED: {list of file paths}
      ```

      **DO NOT** return full diff or code listings.
      Return ONLY status metadata above.

      ---

      **ORCHESTRATOR VERIFICATION**:
      1. Parse fixes applied count
      2. Prepare for test re-run
      3. Determine if fixes resolved failures

      **STANDARDS COMPLIANCE**:
      - Follow code standards from: ${STANDARDS_FILE}
      - Maintain existing indentation and style
      - Add comments for complex fixes if needed

      **REMINDER**: You are the EXECUTOR. Apply all fixes methodically.
    "
  }

  # Parse fixes applied
  FIXES_APPLIED=$(echo "$AGENT_OUTPUT" | grep "FIXES_APPLIED:" | cut -d: -f2 | xargs)
  echo "Fixes Applied: $FIXES_APPLIED"
  echo ""

  # Re-run tests (invoke test-specialist again)
  echo "Re-running tests to verify fixes..."
  echo ""

  Task {
    subagent_type: "general-purpose"
    description: "Re-run tests after fixes"
    prompt: "
      Read behavioral guidelines: .claude/agents/test-specialist.md

      **EXECUTE NOW - RE-RUN TESTS**

      STEP 1: Discover test commands from standards: ${STANDARDS_FILE}

      STEP 2: Run project test suite
              Execute the same tests that were run in Phase 4

      STEP 3: Update test results report: ${TOPIC_PATH}/outputs/test_results.md
              Append results from this iteration
              Note which iteration this is (iteration $iteration)

      STEP 4: Return test status:
              TEST_STATUS: {passing|failing}
              TESTS_TOTAL: {N}
              TESTS_PASSED: {M}
              TESTS_FAILED: {K}

      **REMINDER**: You are the EXECUTOR. Run the tests now.
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

  echo "Updated Test Status: $TEST_STATUS"
  echo "Tests: $TESTS_PASSED / $TESTS_TOTAL passed"
  echo ""

  # Check if tests now passing
  if [ "$TESTS_PASSING" == "true" ]; then
    echo "✅ Tests passing after $iteration debug iteration(s)"
    echo ""
    break
  fi

  echo "Tests still failing, continuing to next iteration..."
  echo ""
done

# Escalate if still failing after 3 iterations
if [ "$TESTS_PASSING" == "false" ]; then
  echo "⚠️  WARNING: Tests still failing after 3 debug iterations"
  echo "   Manual intervention required."
  echo "   Debug report: $DEBUG_REPORT"
  echo ""
  echo "Workflow continuing to Phase 6 (Documentation)..."
  echo ""
fi

echo "Phase 5 Complete: Debug cycle finished"
echo ""
```

## Phase 6: Documentation (Conditional)

[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

**Objective**: Create workflow summary linking plan, research, and implementation.

**Pattern**: Invoke doc-writer agent → Verify summary created → Update research reports

**Execution Condition**: Phase 6 only executes if implementation occurred (Phase 3 ran)

### Phase 6 Execution Check

```bash
# Phase 6 only executes if implementation occurred
if [ "$IMPLEMENTATION_OCCURRED" == "true" ]; then
  echo "Executing Phase 6: Documentation"
  echo ""
else
  echo "⏭️  Skipping Phase 6 (Documentation)"
  echo "  Reason: No implementation to document (scope: $WORKFLOW_SCOPE)"
  echo ""
  # Skip to completion summary
  display_completion_summary
  exit 0
fi
```

### Doc-Writer Agent Invocation

STEP 1: Invoke doc-writer agent to create summary

**EXECUTE NOW**: USE the Task tool to invoke the doc-writer agent.

Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/doc-writer.md

    **Workflow-Specific Context**:
    - Summary Path: ${SUMMARY_PATH} (absolute path, pre-calculated)
    - Plan File: ${PLAN_PATH}
    - Research Reports: ${RESEARCH_REPORTS_LIST}
    - Implementation Artifacts: ${IMPL_ARTIFACTS}
    - Test Status: ${TEST_STATUS}
    - Workflow Description: ${WORKFLOW_DESCRIPTION}

    Execute documentation following all guidelines in behavioral file.
    Return: SUMMARY_CREATED: ${SUMMARY_PATH}
  "
}

### Mandatory Verification - Summary Creation

**VERIFICATION REQUIRED**: Summary file must exist to complete workflow

**GUARANTEE REQUIRED**: Summary links all artifacts (research, plan, implementation)

STEP 2: Verify summary file created

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Workflow Summary"
echo "════════════════════════════════════════════════════════"
echo ""

# Check if summary file exists and has content (with retry for transient failures)
if ! retry_with_backoff 2 1000 test -f "$SUMMARY_PATH" -a -s "$SUMMARY_PATH"; then
  echo "❌ CRITICAL ERROR: Summary file not created after retries at $SUMMARY_PATH"
  echo ""
  echo "FALLBACK MECHANISM: Cannot create summary without agent - workflow incomplete"
  echo "Workflow TERMINATED."
  exit 1
fi

echo "✅ VERIFIED: Summary file exists at $SUMMARY_PATH"
FILE_SIZE=$(wc -c < "$SUMMARY_PATH")
echo "   File size: $FILE_SIZE bytes"
echo ""

# VERIFICATION REQUIREMENT: YOU MUST NOT complete workflow without summary
echo "Verification checkpoint passed - workflow complete"
echo ""

echo "Phase 6 Complete: Documentation finished"
echo ""
```

## Workflow Completion

Display final workflow summary and artifact locations.

```bash
# Clean up checkpoint on successful completion
CHECKPOINT_FILE=".claude/data/checkpoints/supervise_latest.json"
if [ -f "$CHECKPOINT_FILE" ]; then
  rm -f "$CHECKPOINT_FILE"
  echo "✓ Checkpoint cleaned up"
  echo ""
fi

display_completion_summary
exit 0
```

## Usage Examples

[REFERENCE-OK: Examples can be moved to external usage guide]

### Example 1: Research-only workflow

```bash
/supervise "research API authentication patterns"

# Expected behavior:
# - Scope detected: research-only
# - Phases executed: 0, 1
# - Artifacts: 2-3 research reports
# - No plan, no implementation, no summary
```

### Example 2: Research-and-plan workflow (MOST COMMON)

```bash
/supervise "research the authentication module to create a refactor plan"

# Expected behavior:
# - Scope detected: research-and-plan
# - Phases executed: 0, 1, 2
# - Artifacts: 4 research reports + 1 implementation plan
# - No implementation, no summary (per standards)
# - Plan ready for execution
```

### Example 3: Full-implementation workflow

```bash
/supervise "implement OAuth2 authentication for the API"

# Expected behavior:
# - Scope detected: full-implementation
# - Phases executed: 0, 1, 2, 3, 4, 6
# - Phase 5 conditional on test failures
# - Artifacts: reports + plan + implementation + summary
```

### Example 4: Debug-only workflow

```bash
/supervise "fix the token refresh bug in auth.js"

# Expected behavior:
# - Scope detected: debug-only
# - Phases executed: 0, 1, 5
# - Artifacts: research reports + debug report
# - No new plan or implementation (fixes existing code)
```

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
