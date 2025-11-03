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

**DOCUMENTATION**: For complete usage guide, see [/supervise Usage Guide](../docs/guides/supervise-guide.md)

**PHASE REFERENCE**: For detailed phase documentation, see [/supervise Phase Reference](../docs/reference/supervise-phases.md)

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

**For workflow scope types, performance targets, and usage examples, see the guides referenced above.**

## Fail-Fast Error Handling

This command implements fail-fast pattern with structured diagnostics for immediate error detection.

**Key Behaviors**:
- Verification failures: Immediate error with 5-section diagnostic template
- File creation errors: Structured diagnostics (Expected/Found/Diagnostic/Commands/Causes)
- Partial research failure: Continue if ≥50% agents succeed
- No retry overhead: Errors detected and reported immediately

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

## Fail-Fast Error Handling

**Design Philosophy**: All library dependencies are required - no fallback mechanisms.

**Required Libraries** (hard exit on missing):
- workflow-detection.sh - Workflow scope detection and phase execution control
- error-handling.sh - Error classification and recovery
- checkpoint-utils.sh - Workflow resume capability
- unified-logger.sh - Progress tracking
- unified-location-detection.sh - Project structure location detection
- metadata-extraction.sh - Artifact metadata extraction
- context-pruning.sh - Context management

**Rationale**: Fallback mechanisms hide configuration errors and make debugging harder. Explicit errors force proper setup and enable consistent behavior across environments.

**Error Handling**:
- Clear, actionable error messages showing which library failed
- Diagnostic commands included in error output
- Function-to-library mapping shown when functions missing
- Immediate exit (no silent degradation)

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

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load required libraries using consolidated function
echo "Loading required libraries..."

# Source library-sourcing utilities first
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo ""
  echo "Expected location: $SCRIPT_DIR/../lib/library-sourcing.sh"
  echo ""
  echo "This library provides consolidated library sourcing functions."
  echo ""
  echo "Diagnostic commands:"
  echo "  ls -la $SCRIPT_DIR/../lib/ | grep library-sourcing"
  echo "  cat $SCRIPT_DIR/../lib/library-sourcing.sh"
  echo ""
  echo "Please ensure the library file exists and is readable."
  exit 1
fi

# Source all required libraries using consolidated function
if ! source_required_libraries; then
  # Error already reported by source_required_libraries()
  exit 1
fi

# Source verification helpers for concise checkpoint verification
if [ -f "$SCRIPT_DIR/../lib/verification-helpers.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/../lib/verification-helpers.sh"
else
  echo "ERROR: Required library not found: verification-helpers.sh"
  echo "Expected location: $SCRIPT_DIR/../lib/verification-helpers.sh"
  exit 1
fi

echo "✓ All libraries loaded successfully"

# Define display_brief_summary function inline
# (Must be defined before function verification checks below)
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
      echo "→ Run: /implement $PLAN_PATH"
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

# Verify critical functions are defined after library sourcing
# This prevents "command not found" errors at runtime
REQUIRED_FUNCTIONS=(
  "detect_workflow_scope"
  "should_run_phase"
  "emit_progress"
  "save_checkpoint"
  "restore_checkpoint"
  "verify_file_created"
)

MISSING_FUNCTIONS=()
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done

if [ ${#MISSING_FUNCTIONS[@]} -gt 0 ]; then
  echo "ERROR: Required functions not defined after library sourcing:"
  echo ""
  for func in "${MISSING_FUNCTIONS[@]}"; do
    echo "  - $func()"
    # Show which library should provide this function
    case "$func" in
      detect_workflow_scope|should_run_phase)
        echo "    → Should be provided by: workflow-detection.sh"
        ;;
      classify_error|suggest_recovery|detect_error_type|extract_location|generate_suggestions)
        echo "    → Should be provided by: error-handling.sh"
        ;;
      save_checkpoint|restore_checkpoint|checkpoint_get_field|checkpoint_set_field)
        echo "    → Should be provided by: checkpoint-utils.sh"
        ;;
      emit_progress)
        echo "    → Should be provided by: unified-logger.sh"
        ;;
      verify_file_created)
        echo "    → Should be provided by: verification-helpers.sh"
        ;;
      *)
        echo "    → Library unknown - check documentation"
        ;;
    esac
  done
  echo ""
  echo "Diagnostic commands to investigate:"
  echo "  # Check if library files exist"
  echo "  ls -la $SCRIPT_DIR/../lib/"
  echo ""
  echo "  # Check if functions are defined in current shell"
  echo "  declare -F | grep -E '(${MISSING_FUNCTIONS[0]})'"
  echo ""
  echo "  # Verify library can be sourced manually"
  echo "  bash -c 'source $SCRIPT_DIR/../lib/workflow-detection.sh && declare -F'"
  echo ""
  echo "This indicates a library configuration issue. Please verify:"
  echo "  1. All required library files exist in $SCRIPT_DIR/../lib/"
  echo "  2. Library files are readable (check permissions)"
  echo "  3. Library files contain the expected function definitions"
  exit 1
fi

# Note: display_brief_summary is defined inline (not in a library)
# Verify it exists
if ! command -v display_brief_summary >/dev/null 2>&1; then
  echo "ERROR: display_brief_summary() function not defined"
  echo "This is a critical bug in the /supervise command."
  echo "Please report this issue at: https://github.com/anthropics/claude-code/issues"
  exit 1
fi

**Verification**: All required functions available via sourced libraries.

**Note on Design Decisions** (Phase 1B):
- **Metadata extraction** not implemented: supervise uses path-based context passing (not full content), so the 95% context reduction claim doesn't apply
- **Context pruning** implemented: Explicit pruning calls after each phase (Phases 1-6) to achieve <30% context usage target
- **Fail-fast error handling** implemented: All 7 verification points use immediate error detection with structured diagnostics (no retry overhead)

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
- **Error Handling**: 5 functions (classification, recovery, suggestions)
- **Checkpoint Management**: 4 functions (save, restore, get/set fields)
- **Progress Logging**: 1 function (progress markers)

**Total Functions Available**: 12 core utilities

## Documentation References

**For Usage Examples and Common Patterns**: See [/supervise Usage Guide](../docs/guides/supervise-guide.md)

**For Detailed Phase Documentation**: See [/supervise Phase Reference](../docs/reference/supervise-phases.md)


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
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "DIAGNOSTIC INFO: Missing Workflow Description"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "ERROR: Workflow description required"
  echo ""
  echo "Usage: /supervise \"<workflow description>\""
  echo ""
  echo "Examples:"
  echo "  /supervise \"research API authentication patterns\""
  echo "  /supervise \"plan user profile feature\""
  echo "  /supervise \"implement and test authentication system\""
  echo "  /supervise \"debug login failure issue\""
  echo ""
  exit 1
fi

# Check for existing checkpoint (auto-resume capability)
RESUME_DATA=$(restore_checkpoint "supervise" 2>/dev/null || echo "")
if [ -n "$RESUME_DATA" ]; then
  RESUME_PHASE=$(echo "$RESUME_DATA" | jq -r '.current_phase // empty')
else
  RESUME_PHASE=""
fi

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

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Workflow Scope Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Description: \"$WORKFLOW_DESCRIPTION\""
echo "Detected Scope: $WORKFLOW_SCOPE"
echo ""
echo "Phase Execution Plan:"
echo "  Execute: Phases $PHASES_TO_EXECUTE"
if [ -n "$SKIP_PHASES" ]; then
  echo "  Skip: Phases $SKIP_PHASES"
fi
echo ""
echo "Scope Behavior:"
case "$WORKFLOW_SCOPE" in
  research-only)
    echo "  - Research topic in parallel (2-4 agents)"
    echo "  - Create overview document"
    echo "  - Exit after Phase 1"
    ;;
  research-and-plan)
    echo "  - Research topic in parallel (2-4 agents)"
    echo "  - Generate implementation plan"
    echo "  - Exit after Phase 2"
    ;;
  full-implementation)
    echo "  - Research → Plan → Implement → Test → Document"
    echo "  - Full end-to-end workflow"
    ;;
  debug-only)
    echo "  - Research root cause"
    echo "  - Generate debug report"
    echo "  - Exit after Phase 5"
    ;;
esac
echo ""
```

STEP 3: Initialize workflow paths using consolidated function

Use the workflow-initialization.sh library for unified path calculation and directory creation.

```bash
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

# Call unified initialization function
# This consolidates STEPS 3-7 (225+ lines → ~10 lines)
# Implements 3-step pattern: scope detection → path pre-calculation → directory creation
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

# Reconstruct REPORT_PATHS array from exported variables
# (Bash arrays cannot be directly exported, so we use a helper function)
reconstruct_report_paths_array

# Emit dual-mode progress reporting after Phase 0
emit_progress "0" "Phase 0 complete - paths calculated"
echo "✓ Phase 0 complete: Paths calculated, directory structure ready"
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
  display_brief_summary
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

**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert workflow description for this topic]
    - Report Path: [insert absolute path from REPORT_PATHS array]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Before writing report file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "[insert report path]")"

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [insert exact absolute path]

```bash
# Emit progress marker after agent invocations complete
emit_progress "1" "All research agents invoked - awaiting completion"
echo ""
```

### Mandatory Verification - Research Reports (Fail-Fast)

**VERIFICATION REQUIRED**: All research report files must exist before continuing to Phase 2

STEP 3: Verify ALL research reports created successfully (fail-fast, no retries)

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

  # Use concise verification helper (90% token reduction)
  echo -n "  "
  if verify_file_created "$REPORT_PATH" "Research report $i" "Phase 1"; then
    # Success - add quality checks and metadata
    FILE_SIZE=$(wc -c < "$REPORT_PATH")
    FILE_SIZE_KB=$(awk "BEGIN {printf \"%.1f\", $FILE_SIZE/1024}")
    LINE_COUNT=$(wc -l < "$REPORT_PATH")

    # Quality warnings (silent unless needed)
    WARNINGS=""
    if [ "$FILE_SIZE" -lt 200 ]; then
      WARNINGS=" ⚠️  very small"
    fi
    if ! grep -q "^# " "$REPORT_PATH"; then
      WARNINGS="${WARNINGS}${WARNINGS:+ |}  ⚠️  missing header"
    fi

    echo " Report $i verified (${FILE_SIZE_KB} KB, ${LINE_COUNT} lines)${WARNINGS}"
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    # Failure - verify_file_created already printed diagnostics
    FAILED_AGENTS+=("agent_$i")
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
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
echo "Verification checkpoint passed"
echo ""

# Extract metadata for context reduction (95% reduction: 5,000 → 250 tokens)
echo "Extracting metadata for context reduction..."
declare -A REPORT_METADATA

for report_path in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  METADATA=$(extract_report_metadata "$report_path")
  REPORT_METADATA["$(basename "$report_path")"]="$METADATA"
  echo "  ✓ Metadata extracted: $(basename "$report_path")"
done

echo "✓ All metadata extracted - context usage reduced 95%"
echo ""

# Log context reduction metrics
if [ "${#SUCCESSFUL_REPORT_PATHS[@]}" -gt 0 ]; then
  # Estimate token counts (rough: 1 token ≈ 4 chars)
  FULL_REPORT_SIZE=$(wc -c < "${SUCCESSFUL_REPORT_PATHS[0]}" 2>/dev/null || echo "5000")
  FULL_TOKENS=$((FULL_REPORT_SIZE / 4))
  METADATA_TOKENS=250  # Approximate metadata size in tokens
  TOTAL_FULL_TOKENS=$((FULL_TOKENS * SUCCESSFUL_REPORT_COUNT))
  TOTAL_METADATA_TOKENS=$((METADATA_TOKENS * SUCCESSFUL_REPORT_COUNT))
  REDUCTION_PERCENT=$(( (TOTAL_FULL_TOKENS - TOTAL_METADATA_TOKENS) * 100 / TOTAL_FULL_TOKENS ))

  echo "Context reduction metrics:"
  echo "  Full reports: ~$TOTAL_FULL_TOKENS tokens"
  echo "  Metadata only: ~$TOTAL_METADATA_TOKENS tokens"
  echo "  Reduction: ${REDUCTION_PERCENT}%"
  echo ""
fi

echo "Proceeding to research overview"
echo ""
```

### Research Overview (Conditional Synthesis)

STEP 4: Conditionally create overview report based on workflow scope

**DECISION LOGIC**: Overview synthesis only occurs for research-only workflows.
When planning follows (research-and-plan, full-implementation), the plan-architect
agent will synthesize research reports, making OVERVIEW.md redundant.

```bash
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
else
  # Overview synthesis skipped - plan-architect will synthesize reports
  SKIP_REASON=$(get_synthesis_skip_reason "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT")
  echo "⏭️  Skipping overview synthesis"
  echo "  Reason: $SKIP_REASON"
  echo ""
fi

echo "Phase 1 Complete: Research artifacts verified"
echo ""

# Save checkpoint after Phase 1
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'"' || echo '')
}
EOF
)
save_checkpoint "supervise" "phase_1" "$ARTIFACT_PATHS_JSON"

# Emit dual-mode progress reporting after Phase 1
emit_progress "1" "Phase 1 complete - research finished"
echo "✓ Phase 1 complete: Research finished ($SUCCESSFUL_REPORT_COUNT reports)"
echo ""

# Store Phase 1 metadata for context management (fail-fast)
PHASE_1_ARTIFACTS="${SUCCESSFUL_REPORT_PATHS[@]:-}"
store_phase_metadata "phase_1" "complete" "$PHASE_1_ARTIFACTS"
echo "  Context: Phase 1 metadata stored for planning phase"
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
  display_brief_summary
  exit 0
}
```

### Planning Context Preparation

STEP 1: Prepare planning context with research metadata (95% context reduction)

```bash
echo "Preparing planning context with metadata..."

# Build research metadata list for injection (using extracted metadata)
RESEARCH_METADATA_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  report_basename="$(basename "$report")"
  # Get metadata from previously extracted REPORT_METADATA array
  metadata="${REPORT_METADATA[$report_basename]}"
  RESEARCH_METADATA_LIST+="- Path: $report\n"
  RESEARCH_METADATA_LIST+="  Metadata: $metadata\n"
done

# Include overview if created (only for research-only workflows)
if [ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ]; then
  RESEARCH_METADATA_LIST+="- Path: $OVERVIEW_PATH (synthesis)\n"
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
echo "  Research Reports: $SUCCESSFUL_REPORT_COUNT files (metadata only)"
echo "  Context Reduction: 95% (metadata instead of full reports)"
echo "  Standards File: $STANDARDS_FILE"
echo ""
```

### Plan-Architect Agent Invocation

STEP 2: Invoke plan-architect agent via Task tool

**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Create implementation plan with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Workflow Description: $WORKFLOW_DESCRIPTION
    - Plan File Path: $PLAN_PATH (absolute path, pre-calculated by orchestrator)
    - Project Standards: $STANDARDS_FILE
    - Research Reports (metadata only, 95% context reduction): $RESEARCH_METADATA_LIST
    - Research Report Count: $SUCCESSFUL_REPORT_COUNT

    **IMPORTANT**: Research reports provided as metadata only for context efficiency.
    Full reports are available at the paths listed if detailed review is needed.

    **CRITICAL**: Before writing plan file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "$PLAN_PATH")"

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: $PLAN_PATH

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

# Use concise verification helper (90% token reduction)
if verify_file_created "$PLAN_PATH" "Implementation plan" "Phase 2"; then
  # Success - add quality checks and metadata
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
  FILE_SIZE=$(wc -c < "$PLAN_PATH")
  FILE_SIZE_KB=$(awk "BEGIN {printf \"%.1f\", $FILE_SIZE/1024}")
  LINE_COUNT=$(wc -l < "$PLAN_PATH")

  # Quality warnings (silent unless needed)
  WARNINGS=""
  if [ "$PHASE_COUNT" -lt 3 ]; then
    WARNINGS=" ⚠️  only $PHASE_COUNT phases"
  fi
  if ! grep -q "^## Metadata" "$PLAN_PATH"; then
    WARNINGS="${WARNINGS}${WARNINGS:+ |}  ⚠️  missing metadata"
  fi

  echo " Plan verified (${FILE_SIZE_KB} KB, ${LINE_COUNT} lines, $PHASE_COUNT phases)${WARNINGS}"
  echo ""
else
  # Failure - verify_file_created already printed diagnostics
  echo "Workflow TERMINATED."
  exit 1
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
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH"
}
EOF
)
save_checkpoint "supervise" "phase_2" "$ARTIFACT_PATHS_JSON"
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
  if [ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ]; then
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
  # Emit dual-mode progress reporting for research-and-plan completion
  emit_progress "2" "Phase 2 complete - planning finished (research-and-plan workflow)"
  echo "✓ Phase 2 complete: Planning finished"
  echo ""
  exit 0
}

# Emit dual-mode progress reporting after Phase 2 (for full-implementation workflow)
emit_progress "2" "Phase 2 complete - planning finished"
echo "✓ Phase 2 complete: Planning finished"
echo ""

# Apply context pruning after Phase 2 (planning complete, fail-fast)
BEFORE_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
apply_pruning_policy "planning" "$WORKFLOW_SCOPE"
AFTER_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
if [ "$BEFORE_SIZE" != "0" ] && [ "$AFTER_SIZE" != "0" ]; then
  REDUCTION=$(( (BEFORE_SIZE - AFTER_SIZE) * 100 / BEFORE_SIZE ))
  echo "  Context: Pruned planning phase ($REDUCTION% reduction)"
fi
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

**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Execute implementation plan with mandatory artifact creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/code-writer.md

    **Workflow-Specific Context**:
    - Plan File Path: $PLAN_PATH (absolute path, pre-calculated by orchestrator)
    - Implementation Artifacts Directory: $IMPL_ARTIFACTS
    - Project Standards: $STANDARDS_FILE
    - Workflow Type: $WORKFLOW_SCOPE

    **CRITICAL**: Before writing any artifact files, ensure parent directories exist:
    Use Bash tool: mkdir -p "$(dirname "<file_path>")" before each file creation

    Execute implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_STATUS: {complete|partial|failed}
    PHASES_COMPLETED: {N}
    PHASES_TOTAL: {M}
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
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CRITICAL ERROR: Implementation artifacts directory not created"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Expected directory: $IMPL_ARTIFACTS"
  echo ""
  echo "This directory should have been created by the implementer-coordinator agent"
  echo "during Phase 3 execution."
  echo ""
  echo "Diagnostic commands:"
  echo "  # Check if parent directory exists"
  echo "  ls -ld \"$(dirname "$IMPL_ARTIFACTS")\""
  echo ""
  echo "  # Check what was created in topic directory"
  echo "  find \"$TOPIC_PATH\" -type d"
  echo ""
  echo "Possible causes:"
  echo "  - Agent did not execute successfully"
  echo "  - Agent output did not create expected directory structure"
  echo "  - Path mismatch between orchestrator and agent"
  echo ""
  echo "Workflow TERMINATED (fail-fast: agent must create required directories)"
  exit 1
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
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS"
}
EOF
)
save_checkpoint "supervise" "phase_3" "$ARTIFACT_PATHS_JSON"

# Emit dual-mode progress reporting after Phase 3
emit_progress "3" "Phase 3 complete - implementation finished"
echo "✓ Phase 3 complete: Implementation finished (status: $IMPL_STATUS)"
echo ""

# Apply context pruning after Phase 3 (implementation complete, fail-fast)
BEFORE_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
apply_pruning_policy "implementation" "supervise"
AFTER_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
if [ "$BEFORE_SIZE" != "0" ] && [ "$AFTER_SIZE" != "0" ]; then
  REDUCTION=$(( (BEFORE_SIZE - AFTER_SIZE) * 100 / BEFORE_SIZE ))
  echo "  Context: Pruned implementation phase ($REDUCTION% reduction)"
fi
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

**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Execute comprehensive tests with mandatory results file"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: $TOPIC_PATH/outputs/test_results.md (absolute path, pre-calculated)
    - Project Standards: $STANDARDS_FILE
    - Plan File: $PLAN_PATH
    - Implementation Artifacts: $IMPL_ARTIFACTS

    **CRITICAL**: Before writing test results file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$TOPIC_PATH/outputs"

    Execute testing following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    TESTS_TOTAL: {N}
    TESTS_PASSED: {M}
    TESTS_FAILED: {K}

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
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS",
  "test_status": "$TEST_STATUS"
}
EOF
)
save_checkpoint "supervise" "phase_4" "$ARTIFACT_PATHS_JSON"

# Emit dual-mode progress reporting after Phase 4
emit_progress "4" "Phase 4 complete - testing finished"
echo "✓ Phase 4 complete: Testing finished (status: $TEST_STATUS)"
echo ""

# Store Phase 4 metadata (test results) for potential debugging (fail-fast)
PHASE_4_ARTIFACTS="$TEST_RESULTS_PATH"
store_phase_metadata "phase_4" "complete" "$PHASE_4_ARTIFACTS"
echo "  Context: Phase 4 test metadata stored"
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
  **EXECUTE NOW**: USE the Task tool with these parameters:

  - subagent_type: "general-purpose"
  - description: "Analyze test failures - iteration $iteration"
  - prompt: |
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

      First, ensure parent directory exists:
      ```bash
      mkdir -p "$(dirname "${DEBUG_REPORT}")"
      ```

      Then create: ${DEBUG_REPORT}

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

  # Verify debug report created
  echo "════════════════════════════════════════════════════════"
  echo "  MANDATORY VERIFICATION - Debug Report"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # VERIFICATION REQUIRED: Debug report must exist before applying fixes (fail-fast)
  if verify_file_created "$DEBUG_REPORT" "Debug report (iteration $iteration)" "Phase 5"; then
    echo " Debug report verified - proceeding to fix application"
    echo ""
  else
    # Failure - verify_file_created already printed diagnostics
    echo "Workflow TERMINATED."
    exit 1
  fi

  # Invoke code-writer to apply fixes
  **EXECUTE NOW**: USE the Task tool with these parameters:

  - subagent_type: "general-purpose"
  - description: "Apply debug fixes - iteration $iteration"
  - prompt: |
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

  # Parse fixes applied
  FIXES_APPLIED=$(echo "$AGENT_OUTPUT" | grep "FIXES_APPLIED:" | cut -d: -f2 | xargs)
  echo "Fixes Applied: $FIXES_APPLIED"
  echo ""

  # Re-run tests (invoke test-specialist again)
  echo "Re-running tests to verify fixes..."
  echo ""

  **EXECUTE NOW**: USE the Task tool with these parameters:

  - subagent_type: "general-purpose"
  - description: "Re-run tests after fixes"
  - prompt: |
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

# Emit dual-mode progress reporting after Phase 5
emit_progress "5" "Phase 5 complete - debugging finished"
echo "✓ Phase 5 complete: Debugging finished"
echo ""

# Apply context pruning after Phase 5 (debugging complete, fail-fast)
BEFORE_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
apply_pruning_policy "debug" "supervise"
AFTER_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
if [ "$BEFORE_SIZE" != "0" ] && [ "$AFTER_SIZE" != "0" ]; then
  REDUCTION=$(( (BEFORE_SIZE - AFTER_SIZE) * 100 / BEFORE_SIZE ))
  echo "  Context: Pruned debug phase ($REDUCTION% reduction)"
fi
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
  display_brief_summary
  exit 0
fi
```

### Doc-Writer Agent Invocation

STEP 1: Invoke doc-writer agent to create summary

**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Create workflow summary with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/doc-writer.md

    **Workflow-Specific Context**:
    - Summary Path: $SUMMARY_PATH (absolute path, pre-calculated)
    - Plan File: $PLAN_PATH
    - Research Reports: $RESEARCH_REPORTS_LIST
    - Implementation Artifacts: $IMPL_ARTIFACTS
    - Test Status: $TEST_STATUS
    - Workflow Description: $WORKFLOW_DESCRIPTION

    **CRITICAL**: Before writing summary file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "$SUMMARY_PATH")"

    Execute documentation following all guidelines in behavioral file.
    Return: SUMMARY_CREATED: $SUMMARY_PATH

### Mandatory Verification - Summary Creation

**VERIFICATION REQUIRED**: Summary file must exist to complete workflow

**GUARANTEE REQUIRED**: Summary links all artifacts (research, plan, implementation)

STEP 2: Verify summary file created

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Workflow Summary"
echo "════════════════════════════════════════════════════════"
echo ""

# Check if summary file exists and has content (fail-fast, no retries)
if verify_file_created "$SUMMARY_PATH" "Workflow summary" "Phase 6"; then
  FILE_SIZE=$(wc -c < "$SUMMARY_PATH")
  FILE_SIZE_KB=$(awk "BEGIN {printf \"%.1f\", $FILE_SIZE/1024}")
  LINE_COUNT=$(wc -l < "$SUMMARY_PATH")
  echo " Summary verified (${FILE_SIZE_KB} KB, ${LINE_COUNT} lines)"
  echo ""
else
  # Failure - verify_file_created already printed diagnostics
  echo "Workflow TERMINATED."
  exit 1
fi

echo "Phase 6 Complete: Documentation finished"
echo ""

# Emit dual-mode progress reporting after Phase 6
emit_progress "6" "Phase 6 complete - documentation finished"
echo "✓ Phase 6 complete: Documentation finished"
echo ""

# Apply final context pruning after Phase 6 (workflow complete, fail-fast)
BEFORE_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
apply_pruning_policy "final" "$WORKFLOW_SCOPE"
AFTER_SIZE=$(get_current_context_size 2>/dev/null || echo "0")
if [ "$BEFORE_SIZE" != "0" ] && [ "$AFTER_SIZE" != "0" ]; then
  REDUCTION=$(( (BEFORE_SIZE - AFTER_SIZE) * 100 / BEFORE_SIZE ))
  echo "  Context: Final pruning complete ($REDUCTION% reduction)"
fi
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

display_brief_summary
exit 0
```

**For Usage Examples**: See [/supervise Usage Guide](../docs/guides/supervise-guide.md)

**For Performance Metrics and Success Criteria**: See [/supervise Phase Reference](../docs/reference/supervise-phases.md)
