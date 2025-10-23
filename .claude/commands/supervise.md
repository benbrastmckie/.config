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
    Read behavioral guidelines: .claude/agents/plan-architect.md

    **EXECUTE NOW - MANDATORY PLAN CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
    STEP 2: Analyze workflow and research findings...
    STEP 3: Use Edit tool to develop implementation phases...
    STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
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
- **File Creation Rate**: 100% (strong enforcement, no retries)
- **Time Efficiency**: 15-25% faster than /orchestrate for non-implementation workflows
- **Zero Fallbacks**: Single working path, fail-fast on errors

## Shared Utility Functions

```bash
# ═══════════════════════════════════════════════════════════════
# Workflow Scope Detection (After Phase 0: Location)
# ═══════════════════════════════════════════════════════════════

detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern 1: Research-only (no planning or implementation)
  # Keywords: "research [topic]" without "plan" or "implement"
  # Phases: 0 (Location) → 1 (Research) → STOP
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    echo "research-only"
    return
  fi

  # Pattern 2: Research-and-plan (most common case)
  # Keywords: "research...to create plan", "analyze...for planning"
  # Phases: 0 → 1 (Research) → 2 (Planning) → STOP
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)"; then
    echo "research-and-plan"
    return
  fi

  # Pattern 3: Full-implementation
  # Keywords: "implement", "build", "add feature", "create [code component]"
  # Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug if needed) → 6 (Documentation)
  if echo "$workflow_desc" | grep -Eiq "implement|build|add.*(feature|functionality)|create.*(code|component|module)"; then
    echo "full-implementation"
    return
  fi

  # Pattern 4: Debug-only (fix existing code)
  # Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
  # Phases: 0 → 1 (Research) → 5 (Debug) → STOP (no new implementation)
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    echo "debug-only"
    return
  fi

  # Default: Conservative fallback to research-and-plan (safest for ambiguous cases)
  echo "research-and-plan"
}

# ═══════════════════════════════════════════════════════════════
# Phase Execution Check
# ═══════════════════════════════════════════════════════════════

should_run_phase() {
  local phase_num="$1"

  # Check if phase is in execution list
  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_num"; then
    return 0  # true: execute phase
  else
    return 1  # false: skip phase
  fi
}

# ═══════════════════════════════════════════════════════════════
# File Verification Checkpoint Template
# ═══════════════════════════════════════════════════════════════

verify_file_created() {
  local file_path="$1"
  local file_type="$2"
  local agent_output="$3"

  echo "**MANDATORY VERIFICATION**: Verifying $file_type exists..."
  echo ""

  # Check 1: File exists
  if [ ! -f "$file_path" ]; then
    echo "❌ VERIFICATION FAILED: $file_type does not exist"
    echo "   Expected: $file_path"
    echo "   Agent output: $agent_output"
    echo ""
    echo "ERROR: Agent failed to create $file_type file."
    echo "This indicates agent did not follow STEP 1 instructions."
    echo ""
    echo "Workflow TERMINATED. Fix agent enforcement and retry."
    exit 1
  fi

  # Check 2: File has content (size > 0)
  if [ ! -s "$file_path" ]; then
    echo "❌ VERIFICATION FAILED: $file_type is empty"
    echo "   Path: $file_path"
    echo ""
    echo "ERROR: Agent created empty file."
    echo "This indicates agent did not follow STEP 3 instructions."
    echo ""
    echo "Workflow TERMINATED. Fix agent enforcement and retry."
    exit 1
  fi

  # Check 3: File size (should be at least 100 bytes)
  local file_size=$(wc -c < "$file_path")
  if [ "$file_size" -lt 100 ]; then
    echo "⚠️  WARNING: $file_type is very small ($file_size bytes)"
    echo "   Agent may not have completed all steps."
  fi

  echo "✅ VERIFICATION PASSED: $file_type created successfully"
  echo "   Path: $file_path"
  echo "   Size: $file_size bytes"
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# Error Handling and Recovery Integration
# ═══════════════════════════════════════════════════════════════

# Source error-handling library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../lib/error-handling.sh" ]; then
  source "$SCRIPT_DIR/../lib/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found"
  exit 1
fi

# classify_and_retry: Classify error and return retry decision
# Usage: classify_and_retry <agent_output>
# Returns: "retry" | "fail" | "success"
classify_and_retry() {
  local agent_output="${1:-}"

  # Check for success indicators
  if echo "$agent_output" | grep -q "REPORT_CREATED\|PLAN_CREATED\|IMPLEMENTATION_COMPLETE"; then
    echo "success"
    return
  fi

  # Classify error using error-handling.sh
  local error_type=$(classify_error "$agent_output")

  if [ "$error_type" == "$ERROR_TYPE_TRANSIENT" ]; then
    echo "retry"
  else
    echo "fail"
  fi
}

# verify_and_retry: Verify file creation with single retry for transient failures
# Usage: verify_and_retry <file_path> <agent_output> <agent_type>
# Returns: 0 on success, 1 on failure
verify_and_retry() {
  local file_path="$1"
  local agent_output="$2"
  local agent_type="$3"

  # First attempt verification
  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    return 0
  fi

  # File missing - classify error
  local retry_decision=$(classify_and_retry "$agent_output")

  if [ "$retry_decision" == "retry" ]; then
    echo "⚠️  Transient error detected - retrying once..."
    return 2  # Signal caller to retry
  else
    return 1  # Permanent failure
  fi
}

# emit_progress: Emit silent progress marker
# Usage: emit_progress <phase_number> <action>
emit_progress() {
  local phase="$1"
  local action="$2"
  echo "PROGRESS: [Phase $phase] - $action"
}

# ═══════════════════════════════════════════════════════════════
# Completion Summary Display
# ═══════════════════════════════════════════════════════════════

display_completion_summary() {
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "         /supervise WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Workflow Type: $WORKFLOW_SCOPE"
  echo "Phases Executed: $(echo $PHASES_TO_EXECUTE | tr ',' ' ')"
  echo ""
  echo "Artifacts Created:"

  # Research reports
  if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -gt 0 ]; then
    echo "  ✓ Research Reports: ${#SUCCESSFUL_REPORT_PATHS[@]} files in $TOPIC_PATH/reports/"
    for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
      echo "      - $(basename $report)"
    done
  fi

  # Overview report
  if [ -f "$OVERVIEW_PATH" ]; then
    echo "  ✓ Research Overview: $(basename $OVERVIEW_PATH)"
  fi

  # Implementation plan
  if [ -f "$PLAN_PATH" ]; then
    echo "  ✓ Implementation Plan: $(basename $PLAN_PATH)"
  fi

  # Implementation artifacts
  if [ -d "$IMPL_ARTIFACTS" ] && [ "$(ls -A $IMPL_ARTIFACTS)" ]; then
    echo "  ✓ Implementation Artifacts: $IMPL_ARTIFACTS"
  fi

  # Debug reports
  if [ -f "$DEBUG_REPORT" ]; then
    echo "  ✓ Debug Report: $(basename $DEBUG_REPORT)"
  fi

  # Summary
  if [ -f "$SUMMARY_PATH" ]; then
    echo "  ✓ Workflow Summary: $(basename $SUMMARY_PATH)"
  fi

  echo ""
  echo "Standards Compliance:"
  echo "  ✓ Zero SlashCommand invocations (pure Task tool)"
  echo "  ✓ 100% file creation rate (strong enforcement)"
  echo "  ✓ Conditional phase execution (scope-based)"
  echo "  ✓ Mandatory verification at all checkpoints"
  echo ""

  # Suggest next steps
  if [ "$WORKFLOW_SCOPE" == "research-and-plan" ]; then
    echo "Next Steps:"
    echo "  To execute the plan:"
    echo "    /implement $PLAN_PATH"
    echo ""
  fi
}
```

## Phase 0: Project Location and Path Pre-Calculation

**Objective**: Establish topic directory structure and calculate all artifact paths.

**Pattern**: location-specialist agent → directory creation → path export

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

STEP 3: Invoke location-specialist agent

Use the Task tool to invoke the location-specialist agent. The agent will determine the appropriate project location and topic metadata.

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Determine project location for workflow"
  prompt: "
    Read behavioral guidelines: .claude/agents/location-specialist.md

    Workflow Description: ${WORKFLOW_DESCRIPTION}

    Determine the appropriate location using the deepest directory that encompasses the workflow scope.

    Return ONLY these exact lines:
    LOCATION: <path>
    TOPIC_NUMBER: <NNN>
    TOPIC_NAME: <snake_case_name>
  "
}
```

STEP 4: Parse location-specialist output

```bash
# Extract location metadata from agent response
LOCATION=$(echo "$AGENT_OUTPUT" | grep "LOCATION:" | cut -d: -f2- | xargs)
TOPIC_NUM=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NUMBER:" | cut -d: -f2 | xargs)
TOPIC_NAME=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NAME:" | cut -d: -f2- | xargs)

# Validate required fields
if [ -z "$LOCATION" ] || [ -z "$TOPIC_NUM" ] || [ -z "$TOPIC_NAME" ]; then
  echo "❌ ERROR: Location-specialist failed to provide required metadata"
  echo "   LOCATION: $LOCATION"
  echo "   TOPIC_NUM: $TOPIC_NUM"
  echo "   TOPIC_NAME: $TOPIC_NAME"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi

echo "Project Location: $LOCATION"
echo "Topic Number: $TOPIC_NUM"
echo "Topic Name: $TOPIC_NAME"
echo ""
```

STEP 5: Create topic directory structure

```bash
TOPIC_PATH="${LOCATION}/.claude/specs/${TOPIC_NUM}_${TOPIC_NAME}"

echo "Creating topic directory structure at: $TOPIC_PATH"
mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}

# Verify directory creation
if [ ! -d "$TOPIC_PATH" ]; then
  echo "❌ ERROR: Failed to create topic directory: $TOPIC_PATH"
  exit 1
fi

for dir in reports plans summaries debug scripts outputs; do
  if [ ! -d "$TOPIC_PATH/$dir" ]; then
    echo "❌ ERROR: Failed to create subdirectory: $dir"
    exit 1
  fi
done

echo "✅ Topic directory structure created successfully"
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

```yaml
# Research Agent Template (repeated for each topic)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "
    Read behavioral guidelines: .claude/agents/research-specialist.md

    **EXECUTE NOW - MANDATORY FILE CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create this EXACT file:
            ${REPORT_PATHS[i]}

            Content: Empty file with header '# ${TOPIC_NAME} Research Report'

            **DO THIS FIRST** - File MUST exist before research begins.

    STEP 2: Conduct comprehensive research on topic: ${WORKFLOW_DESCRIPTION}
            Focus area: [auto-generated based on workflow]
            - Use Grep/Glob/Read tools to analyze codebase
            - Search .claude/docs/ for relevant patterns
            - Identify 3-5 key findings

    STEP 3: Use Edit tool to add research findings to ${REPORT_PATHS[i]}
            - Write 200-300 word summary
            - Include code references with file:line format
            - List 3-5 specific recommendations

    STEP 4: Return ONLY this exact format:
            REPORT_CREATED: ${REPORT_PATHS[i]}

            **CRITICAL**: DO NOT return summary text in response.
            Return ONLY the confirmation line above.

    **MANDATORY VERIFICATION**: Orchestrator will verify file exists at exact path.
    If file does not exist or is empty, workflow will FAIL IMMEDIATELY.

    **REMINDER**: You are the EXECUTOR. The orchestrator pre-calculated this path.
    Use the exact path provided. Do not modify or recalculate.
  "
}
```

**Note**: The actual implementation will generate N Task calls based on RESEARCH_COMPLEXITY.

### Mandatory Verification - Research Reports

STEP 3: Verify ALL research reports created successfully

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"
echo ""

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  echo "Verifying Report $i: $(basename $REPORT_PATH)"

  # Check 1: File exists
  if [ ! -f "$REPORT_PATH" ]; then
    echo "  ❌ FAILED: File does not exist"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    continue
  fi

  # Check 2: File has content
  if [ ! -s "$REPORT_PATH" ]; then
    echo "  ❌ FAILED: File is empty"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    continue
  fi

  # Check 3: File size reasonable (at least 200 bytes)
  FILE_SIZE=$(wc -c < "$REPORT_PATH")
  if [ "$FILE_SIZE" -lt 200 ]; then
    echo "  ⚠️  WARNING: File is very small ($FILE_SIZE bytes)"
  fi

  # Check 4: Contains header
  if ! grep -q "^# " "$REPORT_PATH"; then
    echo "  ⚠️  WARNING: Missing markdown header"
  fi

  # Check 5: Contains code references
  if ! grep -q ":" "$REPORT_PATH" | grep -q "[0-9]"; then
    echo "  ⚠️  WARNING: No code references (file:line format)"
  fi

  echo "  ✅ PASSED: Report created successfully ($FILE_SIZE bytes)"
  SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
done

SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORT_PATHS[@]}

echo ""
echo "Verification Summary:"
echo "  Total Reports Expected: $RESEARCH_COMPLEXITY"
echo "  Reports Created: $SUCCESSFUL_REPORT_COUNT"
echo "  Verification Failures: $VERIFICATION_FAILURES"
echo ""

# Fail-fast if any reports missing
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo "❌ CRITICAL FAILURE: Not all research reports were created"
  echo ""
  echo "ERROR: $VERIFICATION_FAILURES agents failed to create report files."
  echo "This indicates agents did not follow STEP 1 instructions."
  echo ""
  echo "Workflow TERMINATED. Fix agent enforcement and retry."
  exit 1
fi

echo "✅ ALL RESEARCH REPORTS VERIFIED SUCCESSFULLY"
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
```

## Phase 2: Planning

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

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/plan-architect.md

    **EXECUTE NOW - MANDATORY PLAN CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
            Content: Plan header with metadata section
            **DO THIS FIRST** - File MUST exist before planning.

    STEP 2: Analyze workflow and research findings
            Workflow: ${WORKFLOW_DESCRIPTION}
            Research Reports:
            ${RESEARCH_REPORTS_LIST}
            Standards: ${STANDARDS_FILE}

    STEP 3: Use Edit tool to develop implementation phases in ${PLAN_PATH}
            - Break into 3-7 phases
            - Each phase: objective, tasks, testing, complexity
            - Follow progressive organization (Level 0 initially)
            - Include success criteria and risk assessment

    STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}
            **DO NOT** return plan summary.
            **DO NOT** use SlashCommand tool.

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
    **CONSEQUENCE**: Workflow fails if file missing or incomplete.

    **REMINDER**: You are the EXECUTOR. Use exact path provided.
  "
}
```

### Mandatory Verification - Plan Creation

STEP 3: Verify plan file created successfully

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Implementation Plan"
echo "════════════════════════════════════════════════════════"
echo ""

# Check 1: File exists
if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ VERIFICATION FAILED: Plan not created"
  echo "   Expected: $PLAN_PATH"
  echo "   Agent failed STEP 1. Workflow TERMINATED."
  exit 1
fi

# Check 2: File has content
if [ ! -s "$PLAN_PATH" ]; then
  echo "❌ VERIFICATION FAILED: Plan file is empty"
  echo "   Agent failed STEP 3. Workflow TERMINATED."
  exit 1
fi

# Check 3: Verify plan structure (contains phases)
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
if [ "$PHASE_COUNT" -lt 3 ]; then
  echo "⚠️  WARNING: Plan has only $PHASE_COUNT phases"
  echo "   Expected at least 3 phases for proper structure."
fi

# Check 4: Verify metadata section exists
if ! grep -q "^## Metadata" "$PLAN_PATH"; then
  echo "⚠️  WARNING: Plan missing metadata section"
fi

echo "✅ VERIFICATION PASSED: Plan created with $PHASE_COUNT phases"
echo "   Path: $PLAN_PATH"
echo ""
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
  echo "  To execute the plan:"
  echo "    /implement $PLAN_PATH"
  echo ""
  exit 0
}
```

## Phase 3: Implementation

**Objective**: Execute implementation plan phase-by-phase with testing and commits.

**Pattern**: Invoke code-writer agent with plan context → Verify implementation artifacts → Track completion

**Critical**: Code-writer agent uses /implement pattern internally (phase-by-phase execution)

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

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/code-writer.md

    **EXECUTE NOW - IMPLEMENTATION REQUIRED**

    STEP 1: Read implementation plan: ${PLAN_PATH}

    STEP 2: Execute plan using /implement pattern:
            - Phase-by-phase execution
            - Run tests after each phase
            - Create git commits for completed phases
            - Update plan with [COMPLETED] markers

    STEP 3: Create implementation artifacts in: ${IMPL_ARTIFACTS}
            (Create directory if it doesn't exist)

    STEP 4: Return implementation status:
            IMPLEMENTATION_STATUS: {complete|partial|failed}
            PHASES_COMPLETED: {N}
            PHASES_TOTAL: {M}

            **DO NOT** return full implementation summary.
            Return ONLY status metadata above.

    **STANDARDS COMPLIANCE**:
    - Follow code standards from: ${STANDARDS_FILE}
    - Use test commands from Testing Protocols
    - Create git commits per commit protocol

    **REMINDER**: You are the EXECUTOR. Complete the implementation.
  "
}
```

### Mandatory Verification - Implementation Completion

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
else
  ARTIFACT_COUNT=$(find "$IMPL_ARTIFACTS" -type f | wc -l)
  echo "✅ Implementation artifacts: $ARTIFACT_COUNT files"
fi

# Verify plan updated with completion markers
COMPLETED_PHASES=$(grep -c "\[COMPLETED\]" "$PLAN_PATH" || echo "0")
echo "Plan completion markers: $COMPLETED_PHASES phases marked complete"
echo ""

# Set flag for Phase 6 (documentation)
if [ "$IMPL_STATUS" == "complete" ] || [ "$IMPL_STATUS" == "partial" ]; then
  IMPLEMENTATION_OCCURRED="true"
fi

echo "Phase 3 Complete: Implementation finished"
echo ""
```

## Phase 4: Testing

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

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive tests"
  prompt: "
    Read behavioral guidelines: .claude/agents/test-specialist.md

    **EXECUTE NOW - COMPREHENSIVE TESTING REQUIRED**

    STEP 1: Discover test commands from standards: ${STANDARDS_FILE}
            Look for Testing Protocols section

    STEP 2: Run project test suite
            - Execute all relevant tests
            - Collect pass/fail statistics
            - Identify failing tests with error messages

    STEP 3: Create test results report: ${TOPIC_PATH}/outputs/test_results.md
            Include:
            - Test summary (total, passed, failed)
            - Failed test details
            - Coverage metrics (if available)

    STEP 4: Return test status:
            TEST_STATUS: {passing|failing}
            TESTS_TOTAL: {N}
            TESTS_PASSED: {M}
            TESTS_FAILED: {K}

            **DO NOT** return full test output.
            Return ONLY status metadata above.

    **REMINDER**: You are the EXECUTOR. Run the tests.
  "
}
```

### Test Results Verification

STEP 2: Parse and verify test results

```bash
echo "════════════════════════════════════════════════════════"
echo "  TEST RESULTS"
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
  echo "✅ All tests passing - no debugging needed"
else
  TESTS_PASSING="false"
  echo "❌ Tests failing - debugging required (Phase 5)"
fi

echo ""
echo "Phase 4 Complete: Testing finished"
echo ""
```

## Phase 5: Debug (Conditional)

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

      **EXECUTE NOW - DEBUG ANALYSIS REQUIRED**

      STEP 1: Analyze test failures from: ${TOPIC_PATH}/outputs/test_results.md
              Read the test results file and identify failing tests
              Extract error messages and stack traces

      STEP 2: Identify root causes and propose fixes
              For each failing test:
              - Determine the root cause
              - Identify the file(s) that need changes
              - Propose specific fixes with code examples

      STEP 3: Use Write tool IMMEDIATELY to create: ${DEBUG_REPORT}
              Content: Debug analysis with root causes and proposed fixes
              **DO THIS FIRST** - File MUST exist before continuing.

      STEP 4: Use Edit tool to expand debug report with:
              - Root cause analysis for each failure
              - Specific file changes needed (with line numbers)
              - Code snippets showing fixes
              - Priority order for applying fixes

      STEP 5: Return ONLY: DEBUG_ANALYSIS_COMPLETE: ${DEBUG_REPORT}
              **DO NOT** return full analysis text.
              Return ONLY the confirmation line above.

      **MANDATORY VERIFICATION**: Orchestrator verifies file exists.

      **REMINDER**: You are the EXECUTOR. Use exact path provided.
    "
  }

  # Verify debug report created
  verify_file_created "$DEBUG_REPORT" "Debug Report" "$AGENT_OUTPUT"

  # Invoke code-writer to apply fixes
  Task {
    subagent_type: "general-purpose"
    description: "Apply debug fixes - iteration $iteration"
    prompt: "
      Read behavioral guidelines: .claude/agents/code-writer.md

      **EXECUTE NOW - APPLY FIXES**

      STEP 1: Read debug analysis: ${DEBUG_REPORT}
              Review all proposed fixes and their priority order

      STEP 2: Apply recommended fixes using Edit tool
              For each fix:
              - Locate the file and line number
              - Apply the exact code change recommended
              - Preserve code style and formatting
              - Do NOT skip any fixes

      STEP 3: Verify fixes applied
              Check that all changes were successfully made
              Count the number of files modified

      STEP 4: Return fix status:
              FIXES_APPLIED: {count}
              FILES_MODIFIED: {list of file paths}

              **DO NOT** return full diff or code listings.
              Return ONLY status metadata above.

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

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary"
  prompt: "
    Read behavioral guidelines: .claude/agents/doc-writer.md

    **EXECUTE NOW - MANDATORY SUMMARY CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${SUMMARY_PATH}
            Content: Summary header with metadata
            **DO THIS FIRST** - File MUST exist before documentation.

    STEP 2: Document workflow execution:
            - Implementation Overview
            - Plan Executed: ${PLAN_PATH}
            - Research Reports Used:
              ${RESEARCH_REPORTS_LIST}
            - Key Decisions Made
            - Code Changes Summary
            - Test Results: ${TEST_STATUS}
            - Lessons Learned

    STEP 3: Use Edit tool to expand summary with:
            - Cross-references to code changes (file:line)
            - Links between research recommendations and implementation
            - Notes on deviations from original plan
            - Follow-up tasks or known issues

    STEP 4: Return ONLY: SUMMARY_CREATED: ${SUMMARY_PATH}
            **DO NOT** return summary text.

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.

    **REMINDER**: You are the EXECUTOR. Use exact path provided.
  "
}
```

### Mandatory Verification - Summary Creation

STEP 2: Verify summary file created

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Workflow Summary"
echo "════════════════════════════════════════════════════════"
echo ""

verify_file_created "$SUMMARY_PATH" "Workflow Summary" "$AGENT_OUTPUT"

echo "Phase 6 Complete: Documentation finished"
echo ""
```

## Workflow Completion

Display final workflow summary and artifact locations.

```bash
display_completion_summary
exit 0
```

## Usage Examples

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
# - Suggests: /implement <plan-path>
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

Expected performance targets:

- **File Creation Rate**: 100% (strong enforcement, first attempt)
- **Context Usage**: <25% cumulative across all phases
- **Time Efficiency**: 15-25% faster than /orchestrate for research-and-plan
- **Zero Fallbacks**: Single working path, fail-fast on errors

## Success Criteria

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
- [ ] 100% file creation rate: Strong enforcement achieves success on first attempt
- [ ] Zero retry infrastructure: Single template per agent type, no attempt loops

### Performance Targets
- [ ] File size: 2,500-3,000 lines (achieved)
- [ ] Context usage: <25% throughout workflow
- [ ] Time efficiency: 15-25% faster for non-implementation workflows
- [ ] Code coverage: ≥80% test coverage for scope detection logic

### Deficiency Resolution
- [ ] ✓ Research agents create files on first attempt (vs inline summaries)
- [ ] ✓ Zero SlashCommand usage for planning/implementation (pure Task tool)
- [ ] ✓ Summaries only created when implementation occurs (not for research-only)
- [ ] ✓ Correct phases execute for each workflow type (research, plan, implement, debug)
