# Optimize-Claude Command Success Patterns Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Optimize-Claude command success patterns
- **Report Type**: codebase analysis

## Executive Summary

The optimize-claude command succeeds consistently because it uses explicit Task tool invocations with concrete behavioral agent references, has mandatory verification checkpoints after each agent completes, and pre-calculates all artifact paths before any agent execution. In contrast, the plan command has imperative markers ("EXECUTE NOW: USE the Task tool") but no actual Task invocations in the markdown, creates placeholder fallbacks that mask agent failures, and relies on complex library sourcing that may not execute in the LLM context.

## Findings

### 1. Execution Model Differences

**Optimize-Claude Command** (lines 71-113, 147-201, 235-270):
- **Explicit Task Invocations**: Contains 5 concrete Task blocks embedded directly in markdown
- **Parallel Execution**: Invokes 2 agents in parallel (Phase 2), then 2 more in parallel (Phase 4), then 1 sequential (Phase 6)
- **Agent References**: Each Task block explicitly references behavioral agent files:
  - `claude-md-analyzer.md` (line 79)
  - `docs-structure-analyzer.md` (line 99)
  - `docs-bloat-analyzer.md` (line 155)
  - `docs-accuracy-analyzer.md` (line 181)
  - `cleanup-plan-architect.md` (line 243)

**Plan Command** (lines 381-382, 594-595):
- **No Task Invocations**: Contains only imperative comments suggesting Task usage
- **Example Comment**: "# EXECUTE NOW: USE the Task tool with subagent_type=general-purpose for research agents" (line 381)
- **Agent References**: References behavioral files in comments but never invokes them
- **Execution Gap**: The markdown expects Claude to interpret comments as execution instructions, which doesn't happen

### 2. Dependency Management Strategies

**Optimize-Claude Command** (lines 20-65):
- **Simple Library Sourcing**: Sources only 1 library (`unified-location-detection.sh`, line 25)
- **Path Pre-Calculation**: All paths calculated in bash BEFORE agent invocation
  - `REPORT_PATH_1` through `REPORT_PATH_2` (lines 47-48)
  - `BLOAT_REPORT_PATH`, `ACCURACY_REPORT_PATH` (lines 49-50)
  - `PLAN_PATH` (line 51)
- **Absolute Paths**: Uses `${TOPIC_PATH}/reports/001_file.md` pattern
- **Lazy Directory Creation**: Agents create parent directories as needed (documented line 322)

**Plan Command** (lines 23-85):
- **Complex Library Chain**: Sources 7 libraries in dependency order
  - `detect-project-dir.sh` (line 28)
  - `workflow-state-machine.sh` (line 38)
  - `state-persistence.sh` (line 45)
  - `error-handling.sh` (line 52)
  - `verification-helpers.sh` (line 59)
  - `unified-location-detection.sh` (line 66)
  - `complexity-utils.sh` (line 73)
  - `metadata-extraction.sh` (line 80)
- **State Management**: Initializes workflow state file (line 87) and uses append_workflow_state throughout
- **Dynamic Path Calculation**: Paths calculated through function calls that may not execute in LLM context

### 3. Verification and Fail-Fast Patterns

**Optimize-Claude Command** (lines 119-138, 207-226, 277-287):
- **Mandatory Verification Checkpoints**: 3 explicit checkpoints marked "VERIFICATION CHECKPOINT (MANDATORY)"
- **After Each Wave**: Verification immediately follows each parallel agent wave
  - Phase 3: Verify REPORT_PATH_1 and REPORT_PATH_2 (lines 124-134)
  - Phase 5: Verify BLOAT_REPORT_PATH and ACCURACY_REPORT_PATH (lines 212-222)
  - Phase 7: Verify PLAN_PATH (lines 282-286)
- **Fail-Fast Behavior**: `exit 1` on missing files with diagnostic messages
- **No Fallbacks**: If agent fails, workflow terminates with clear error

**Plan Command** (lines 411-464, 619-696):
- **Placeholder Fallbacks**: Creates placeholder files if agents don't execute (lines 411-449, 619-696)
- **Graceful Degradation**: Sets `RESEARCH_SUCCESSFUL=false` but continues (line 460)
- **Masks Failures**: Verification happens AFTER placeholder creation, so files always exist
- **Example**: "Temporary: Create placeholder report (agent not yet available)" (line 411)

### 4. Agent Behavioral Injection Patterns

**Optimize-Claude Command** (lines 77-90):
```
Task {
  subagent_type: "general-purpose"
  description: "Analyze CLAUDE.md structure"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/claude-md-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_PATH: ${CLAUDE_MD_PATH}
    - REPORT_PATH: ${REPORT_PATH_1}
    - THRESHOLD: balanced

    **CRITICAL**: Create report file at EXACT path provided above.
```
- **Complete Task Block**: Contains all parameters needed for execution
- **Explicit Agent Reference**: Points to specific behavioral file
- **Pre-Calculated Paths**: All variables already resolved by bash
- **Clear Contract**: Agent receives absolute paths and expected output location

**Plan Command** (lines 592-617):
```bash
# STANDARD 12: Reference agent behavioral file ONLY - no inline duplication
# STANDARD 11: Imperative invocation marker
# EXECUTE NOW: USE the Task tool with subagent_type=general-purpose

CONTEXT_JSON=$(jq -n \
  --arg feature "$FEATURE_DESCRIPTION" \
  --arg output_path "$PLAN_PATH" \
  ...
  '{...}')

echo "AGENT_INVOCATION_MARKER: plan-architect"
echo "AGENT_CONTEXT_FILE: $CONTEXT_FILE"
echo "EXPECTED_OUTPUT: $PLAN_PATH"
```
- **No Task Block**: Only bash code that creates context JSON
- **Echo Statements**: Prints markers but doesn't invoke agents
- **Execution Assumption**: Assumes Claude will see "EXECUTE NOW" comment and invoke Task tool
- **Context File**: Creates JSON file but never passes it to an agent

### 5. Workflow Orchestration Architecture

**Optimize-Claude Command**:
- **Phase-Based Structure**: 8 clearly numbered phases
- **Wave Execution**: Phase 2 (parallel), Phase 3 (verify), Phase 4 (parallel), Phase 5 (verify), Phase 6 (sequential), Phase 7 (verify)
- **Synchronization Points**: Verification checkpoints ensure previous wave completed
- **Simple State**: No state machine - just sequential bash + agent invocations

**Plan Command**:
- **Complex State Machine**: Uses workflow-state-machine.sh and state-persistence.sh
- **State File**: Creates temporary state file with workflow tracking (line 87)
- **State Caching**: Calls `append_workflow_state` for all variables (lines 168-180)
- **Trap Handler**: Sets up EXIT trap to clean state file (line 92)
- **Over-Engineering**: State management overhead for what could be simple bash variables

### 6. Library Dependency Fragility

**Optimize-Claude Command**:
- **Single Library**: Only `unified-location-detection.sh`
- **Single Failure Point**: If library fails to source, command exits immediately (lines 25-27)
- **Fail-Fast**: No attempt to continue without library
- **Simple Recovery**: User can fix one library and retry

**Plan Command**:
- **Chain of 7 Libraries**: Each library sourcing can fail independently
- **Cascading Failures**: Later libraries depend on earlier ones
- **Silent Failures**: Uses `2>&1` redirection which may hide errors
- **Complex Recovery**: User must diagnose which of 7 libraries failed
- **State Management Dependency**: If workflow-state-machine.sh fails, all state operations fail

### 7. Path Calculation Reliability

**Optimize-Claude Command** (lines 34-51):
```bash
LOCATION_JSON=$(perform_location_detection "optimize CLAUDE.md structure")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
SPECS_DIR=$(echo "$LOCATION_JSON" | jq -r '.specs_dir')
PROJECT_ROOT=$(echo "$LOCATION_JSON" | jq -r '.project_root')

REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
REPORT_PATH_1="${REPORTS_DIR}/001_claude_md_analysis.md"
```
- **Bash Execution**: Path calculation happens in bash context
- **Variable Expansion**: Simple string concatenation
- **Guaranteed Values**: If bash runs, paths are calculated
- **LLM Context**: When LLM reads this, it sees resolved absolute paths in Task blocks

**Plan Command** (lines 134-180):
```bash
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_' | sed 's/[^a-z0-9_]//g' | cut -c1-50)
TOPIC_DIR=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
TOPIC_NUMBER=$(basename "$TOPIC_DIR" | grep -oE '^[0-9]+')
PLAN_PATH="$TOPIC_DIR/plans/${TOPIC_NUMBER}_implementation_plan.md"
```
- **Function Calls**: Depends on `allocate_and_create_topic` executing
- **Complex Pipeline**: Multiple piped commands for topic slug generation
- **Execution Context**: May not execute if LLM interprets markdown directly
- **State Caching**: Attempts to cache paths to state file (lines 168-173)

### 8. Agent Behavioral File Analysis

**Cleanup-Plan-Architect.md** (optimize-claude uses):
- **STEP-Based Process**: 5 numbered steps (STEP 1, STEP 1.5, STEP 2, STEP 3, STEP 4, STEP 5)
- **File Creation First**: STEP 2 explicitly creates file BEFORE reading reports (line 128)
- **Mandatory Verification**: After Write tool, must verify file exists (line 168)
- **Completion Criteria**: 42 criteria that must ALL be met (referenced in metadata)
- **Path Injection**: Expects PLAN_PATH in prompt (line 25)

**Plan-Architect.md** (plan command references but doesn't invoke):
- **Similar Structure**: Also uses STEP-based process
- **Complexity Calculation**: More complex scoring algorithm (lines 43-50)
- **Tier Selection**: Chooses plan structure tier based on complexity
- **Same Core Pattern**: Create file first, then populate

Both agents follow same "create file first" pattern, but only cleanup-plan-architect is actually invoked by optimize-claude.

### 9. Execution Context Mismatch

**Key Insight**: The plan command's architecture assumes it's executed as a bash script, but it's actually a markdown file interpreted by an LLM:

1. **Bash Context Assumption**:
   - Libraries sourced and functions available
   - Variables calculated and exported
   - State persisted to files
   - Bash execution continues sequentially

2. **LLM Context Reality**:
   - LLM reads markdown sequentially
   - Bash blocks are instructions, not executed code
   - "EXECUTE NOW" comments are just text
   - No state persistence between blocks
   - No guarantee bash runs before agent invocation

3. **Optimize-Claude Adaptation**:
   - Embeds Task blocks directly in markdown
   - Uses simple variable substitution patterns
   - Relies on LLM interpreting Task blocks as tool calls
   - Verification is explicit bash that can be shown to user

## Recommendations

### 1. Replace Imperative Comments with Explicit Task Invocations

**Problem**: Plan command has comments like "# EXECUTE NOW: USE the Task tool" but no actual Task blocks.

**Solution**: Replace comments with embedded Task blocks like optimize-claude does:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke research agents in parallel

Task {
  subagent_type: "general-purpose"
  description: "Research feature patterns"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Input Paths** (ABSOLUTE):
    - REPORT_PATH: ${RESEARCH_REPORT_PATH}
    - TOPIC: ${RESEARCH_TOPIC}

    **CRITICAL**: Create report file at EXACT path provided above.
  "
}
```

**Impact**: Ensures agents are actually invoked when LLM interprets the command.

### 2. Remove Placeholder Fallbacks

**Problem**: Plan command creates placeholder files that mask agent failures (lines 411-449, 619-696).

**Solution**: Remove all "Temporary: Create placeholder" blocks. Let verification checkpoints fail fast.

**Rationale**:
- Placeholders hide real failures
- User gets invalid artifacts instead of clear error messages
- Harder to debug when agents silently fail

**Impact**: Clear failure modes, easier debugging, forces agent invocation to work correctly.

### 3. Simplify Library Dependencies

**Problem**: Plan command sources 7 libraries in dependency chain, creating fragility.

**Solution**: Reduce to minimal essential libraries like optimize-claude (1 library):

```bash
# Source unified location detection library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh" || {
  echo "ERROR: Failed to source unified-location-detection.sh"
  exit 1
}
```

**Alternative**: Inline critical functions directly in command file to eliminate external dependencies.

**Impact**: Reduces failure points from 7 to 1, simpler debugging, more reliable execution.

### 4. Pre-Calculate All Paths in Bash Before Agent Invocation

**Problem**: Plan command uses complex function calls for path calculation that may not execute in LLM context.

**Solution**: Use simple bash string concatenation like optimize-claude:

```bash
REPORTS_DIR="${TOPIC_PATH}/reports"
PLAN_DIR="${TOPIC_PATH}/plans"
REPORT_PATH="${REPORTS_DIR}/001_research.md"
PLAN_PATH="${PLAN_DIR}/001_implementation_plan.md"
```

**Impact**: Guarantees paths are calculated correctly, works in both bash and LLM contexts.

### 5. Add Mandatory Verification Checkpoints

**Problem**: Plan command verification happens after placeholder creation, masking failures.

**Solution**: Add explicit checkpoints like optimize-claude after each agent wave:

```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying research report..."

if [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: Agent research-specialist failed to create report: $REPORT_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ Research report created: $REPORT_PATH"
```

**Impact**: Fail-fast on agent failures, clear error messages, prevents downstream issues.

### 6. Eliminate State Machine Overhead

**Problem**: Plan command uses workflow-state-machine.sh and state-persistence.sh for what are essentially bash variables.

**Solution**: Use simple bash variables for orchestrator state:

```bash
# Simple state variables (no external dependencies)
FEATURE_DESCRIPTION="$1"
TOPIC_DIR=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
PLAN_PATH="$TOPIC_DIR/plans/${TOPIC_NUMBER}_implementation_plan.md"
```

**Impact**: Removes 2 library dependencies, simpler code, easier to understand and debug.

### 7. Standardize Agent Invocation Pattern

**Problem**: Inconsistent patterns between optimize-claude and plan commands.

**Solution**: Create standard agent invocation template:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke [agent-name]

Task {
  subagent_type: "general-purpose"
  description: "[clear 1-line description]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **Input Paths** (ABSOLUTE):
    - INPUT_PATH: ${INPUT_PATH}
    - OUTPUT_PATH: ${OUTPUT_PATH}

    **CRITICAL**: Create output file at EXACT path provided above.

    Expected Output:
    - [Description of expected artifact]
    - Completion signal: [TYPE]_CREATED: [exact absolute path]
  "
}
```

**Impact**: Consistent invocation across all commands, easier to maintain, clearer contracts.

## References

### Commands Analyzed
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (326 lines)
  - Lines 20-65: Path allocation and library sourcing
  - Lines 71-113: Phase 2 parallel research invocation (Task blocks)
  - Lines 119-138: Phase 3 research verification checkpoint
  - Lines 147-201: Phase 4 parallel analysis invocation (Task blocks)
  - Lines 207-226: Phase 5 analysis verification checkpoint
  - Lines 235-270: Phase 6 sequential planning invocation (Task block)
  - Lines 277-287: Phase 7 plan verification checkpoint

- `/home/benjamin/.config/.claude/commands/plan.md` (947 lines)
  - Lines 23-85: Phase 0 complex library sourcing (7 libraries)
  - Lines 134-180: Path pre-calculation with function calls
  - Lines 381-382: Comment about agent invocation (NO Task block)
  - Lines 411-449: Placeholder report creation fallback
  - Lines 592-617: Comment about plan-architect invocation (NO Task block)
  - Lines 619-696: Placeholder plan creation fallback
  - Lines 699-734: Plan verification (after placeholder)

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md`
  - Line 128: STEP 2 - Create plan file FIRST
  - Line 168: Mandatory verification after Write tool

- `/home/benjamin/.config/.claude/agents/plan-architect.md`
  - Lines 43-50: Complexity calculation algorithm
  - Similar STEP-based structure to cleanup-plan-architect

### Library Files Referenced
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (used by both)
- `/home/benjamin/.config/.claude/lib/detect-project-dir.sh` (plan only)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (plan only)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (plan only)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (plan only)
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (plan only)
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh` (plan only)
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` (plan only)
